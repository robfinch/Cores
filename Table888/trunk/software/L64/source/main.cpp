#include <cstdlib>
#include <iostream>
#include <inttypes.h>
#include <stdio.h>
#include "NameTable.hpp"
#include "symbol.hpp"
#include "elf.h"

using namespace std;

int nFiles;
NameTable nmTable;
clsElf64File File[256];
clsElf64Section sections[12];
SymbolFactory symFactory;
SymbolWarehouse symWarehouse;
int debug = 1;

enum {
    codeseg = 0,
    rodataseg = 1,
    dataseg = 2,
    bssseg = 3,
    tlsseg = 4,
    constseg = 6,
};

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void DisplayHelp()
{
    printf("L64 [options] file1 file2 file3 ...\r\n");
}
 

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int options(int argc, char *argv[]) {
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

char *segname(int seg)
{
     switch(seg) {
     case codeseg: return "code";
     case dataseg: return "data";
     case bssseg: return "bss";
     case tlsseg: return "tls";
     case rodataseg: return "rodata";
     case constseg: return "const";
     default: return "???";
     }
}

// ----------------------------------------------------------------------------
// Lookup to symbol corresponding to the reloction record.
// ----------------------------------------------------------------------------

Symbol *Lookup(Elf64rel *p, int fn)
{
    int symndx;
    char *symname;
    Elf64Symbol *elfsym;
    Symbol *sym;

    symndx = p->r_info >> 32;
    elfsym = (Elf64Symbol *)File[fn].sections[6]->bytes;
    elfsym = &elfsym[symndx];
    symname = (char *)&File[fn].sections[5]->bytes[elfsym->st_name];
    sym = symWarehouse.FindSymbol(symname);
    return sym;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void LinkELFFile()
{
    int fn;           // file number
    int sn;           // section number
    int nn,mm;
    Elf64Symbol *elfsym;
    Symbol *sym;
    int symndx;
    char *symname;
    FILE *fp;
    int wd;
    uint8_t b0,b1,b2,b3,b4;

    for (nn = 0; nn < 12; nn++)
        sections[nn].Clear();

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Collect up all the ELF files
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    if (debug)
        printf("Collecting ELF file info.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        fp = fopen(File[fn].name, "rb");
        if (fp) {
            File[fn].hdr.Read(fp);
            int qq = File[fn].hdr.e_shnum;
            File[fn].hdr.e_shnum = 0;     // Add section will increment this
            for (nn = 0; nn < qq; nn++) {
                File[fn].AddSection(new clsElf64Section);
                // Seek to the section header and read it.
                fseek(fp, File[fn].hdr.e_shoff + File[fn].hdr.e_shentsize * nn, SEEK_SET);
                File[fn].sections[nn]->hdr.Read(fp);
                // Seek to the section data and read it.
                fseek(fp, File[fn].sections[nn]->hdr.sh_offset, SEEK_SET);
                File[fn].sections[nn]->Read(fp);
            }
            fclose(fp);
        }
        else {
            for (nn = 0; nn < 12; nn++) {
                File[fn].AddSection(new clsElf64Section);
                File[fn].sections[nn]->hdr.sh_size = 0;
                File[fn].sections[nn]->hdr.sh_entsize = 1;     // avoid /0 error
            }
            printf("Can't open <%s>\r\n", File[fn].name);
        }
    }
    
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Figure out the virtual addresses.
//
// Combine sections of the same type from all the files.
// Pad the section out to 4096 byte alignment.
// All section zero's go to master section zero
// All section one's go to master section one, etc.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    if (debug)
        printf("Figuring virtual addresses.\r\n");
    for (sn = 0; sn < 5; sn++) {
        for (fn = 0; fn < nFiles; fn++) {
            printf("File %d section %d\r\n", fn, sn);
            for (nn = 0; nn < File[fn].sections[sn]->hdr.sh_size; nn++) {
                sections[sn].AddByte(File[fn].sections[sn]->bytes[nn]);
            }
            // If the section doesn't end evenly on a page, pad it out to a page size.
            if (debug)
                printf("Padding section.\r\n");
            for (; nn & 4095; nn++)
                sections[sn].AddByte(0x00);
            if (fn > 0)
                File[fn].sections[sn]->hdr.sh_addr = File[fn-1].sections[sn]->hdr.sh_addr + nn;
        }
    }
    
    // Adjust the starting virtual address for all the sections.
    
    if (debug)
        printf("Adjusting section start addresses.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        for (sn = 1; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += sections[0].index;
        }
        for (sn = 2; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += sections[1].index;
        }
        for (sn = 3; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += sections[2].index;
        }
        for (sn = 4; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += sections[3].index;
        }
        File[fn].sections[5]->hdr.sh_addr += sections[4].index;
    }
    
    // Go through the symbols and adjust their addresses.
    if (debug)
        printf("Adjusting global symbol addresses.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        Elf64Symbol *p;
    
        p = (Elf64Symbol *)File[fn].sections[6]->bytes;    
        for (mm = 0; mm < File[fn].sections[6]->hdr.sh_size / File[fn].sections[6]->hdr.sh_entsize; mm++, p++) {
            p->st_value += File[fn].sections[p->st_shndx]->hdr.sh_addr;        
        }
    }
    
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Build a global symbol table by combining the symbol tables from all the
// files.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    if (debug)
        printf("Building global symbol table.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        Elf64Symbol *p;
        Symbol *sym;
        char *name;
    
        p = (Elf64Symbol *)File[fn].sections[6]->bytes;
        for (mm = 0; mm < File[fn].sections[6]->hdr.sh_size / File[fn].sections[6]->hdr.sh_entsize; mm++, p++) {
            if ((p->st_info >> 4) == 1) { // Is it a global symbol ?
                name = (char *)&File[fn].sections[5]->bytes[p->st_name];
                printf("symbol:<%s>\r\n", name);
                sym = symFactory.NewSymbol(name, 0, p->st_value);
                symWarehouse.StoreSymbol(sym);
            }
        }    
    }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Now that the starting virtual address is set, fixup all the relocations.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    if (debug)
        printf("Performing relocation fixups.\r\n");
    for (fn = 0; fn < nFiles; fn++) {      // for each file
        for (sn = 7; sn < 12; sn++) {      // for each rel section in each file
            Elf64rel *p = (Elf64rel *)File[fn].sections[sn]->bytes;
            for (mm = 0; mm < File[fn].sections[sn]->hdr.sh_size / sizeof(Elf64rel); mm++, p++) {
                switch(p->r_info & 15) {
                // 32 bit fixups
                case 1:
                     b0 = File[fn].sections[sn-7]->bytes[p->r_offset+0];
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+0] = wd & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+1] = (wd >> 8) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 16) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 24) & 255;
                     break;
                case 129:  // 32 bit fixup
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+0] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 24) & 255;
                     }
                     break;
    
                // 24 bit fixups
                case 2:          
                     b0 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset-5];
                     wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-5] = (wd >> 24) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-4] = 0;
                     File[fn].sections[sn-7]->bytes[p->r_offset-3] = 0;
                     File[fn].sections[sn-7]->bytes[p->r_offset-2] = 0;
                     break;
                case 130:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-5] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-4] = 0;
                         File[fn].sections[sn-7]->bytes[p->r_offset-3] = 0;
                         File[fn].sections[sn-7]->bytes[p->r_offset-2] = 0;
                     }
                     break;
                     
                // 16 bit fixups
                case 3:
                     b0 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset-5];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset-4];
                     wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-5] = (wd >> 16) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-4] = (wd >> 24) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-3] = 0;
                     File[fn].sections[sn-7]->bytes[p->r_offset-2] = 0;
                     break;
                case 131:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-5] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-4] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-3] = 0;
                         File[fn].sections[sn-7]->bytes[p->r_offset-2] = 0;
                     }
                     break;
    
                // 14 bit fixups
                case 4: 
                     b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+2] >> 2) & 63;
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset-5];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset-4];
                     b4 = File[fn].sections[sn-7]->bytes[p->r_offset-3];
                     wd = (b4 << 30) | (b3 << 22) | (b2 << 14) | (b1 << 6) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 63);
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-5] <= (wd >> 14) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-4] <= (wd >> 22) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-3] <= (wd >> 30) & 3;
                     File[fn].sections[sn-7]->bytes[p->r_offset-2] <= 0;
                     break;
                case 132:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 63);
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-5] <= (wd >> 14) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-4] <= (wd >> 22) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-3] <= (wd >> 30) & 3;
                         File[fn].sections[sn-7]->bytes[p->r_offset-2] <= 0;
                     }
                     break;
    
               // 4 bit fixups
                case 5:
                     b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+3] >> 4) & 15;
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset-5];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset-4];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset-3];
                     b4 = File[fn].sections[sn-7]->bytes[p->r_offset-2];
                     wd = (b4 << 28) | (b3 << 20) | (b2 << 12) | (b1 << 4) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x15) | ((wd << 4) & 15);
                     File[fn].sections[sn-7]->bytes[p->r_offset-5] <= (wd >> 4) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-4] <= (wd >> 12) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-3] <= (wd >> 20) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset-2] <= (wd >> 28) & 15;
                     break;
                case 133:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x15) | ((wd << 4) & 15);
                         File[fn].sections[sn-7]->bytes[p->r_offset-5] <= (wd >> 4) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-4] <= (wd >> 12) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-3] <= (wd >> 20) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset-2] <= (wd >> 28) & 15;
                     }
                     break;
                }
            }
        }
    }

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// Now recombine all the sections of the same type from all the files.
// The sections should now contain relocated symbols and any externals should
// have been resolved.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    if (debug)
        printf("Combining sections.\r\n");
    // Reset all the sections.
    for (sn = 0; sn < 5; sn++) {
        sections[sn].Clear();
    }
    
    // Combine sections of the same type from all the files.
    // Pad the section out to 4096 byte alignment.
    // All section zero's go to master section zero
    // All section one's go to master section one, etc.
    //
    for (sn = 0; sn < 5; sn++) {
        for (fn = 0; fn < nFiles; fn++) {
            for (nn = 0; nn < File[fn].sections[sn]->hdr.sh_size; nn++) {
                sections[sn].AddByte(File[fn].sections[sn]->bytes[nn]);
            }
            // If the section doesn't end evenly on a page, pad it out to a page size.
            for (; nn & 4095; nn++)
                sections[sn].AddByte(0x00);
        }
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int64_t Round512(int64_t n)
{
    return (n + 511LL) & 0xFFFFFFFFFFFFFE00LL;
}


// ----------------------------------------------------------------------------
// Write out the ELF file
// ----------------------------------------------------------------------------

void WriteELFFile(FILE *fp)
{
    int nn;
    Elf64Symbol elfsym;
    clsElf64File elf;

    if (debug)
        printf("Writing ELF file.\r\n");
    sections[0].hdr.sh_name = nmTable.AddName(".text");
    sections[0].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[0].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_EXECINSTR;
    sections[0].hdr.sh_offset = 512;  // offset in file
    sections[0].hdr.sh_size = sections[0].index;
    sections[0].hdr.sh_link = 0;
    sections[0].hdr.sh_info = 0;
    sections[0].hdr.sh_addralign = 1;
    sections[0].hdr.sh_entsize = 0;

    sections[1].hdr.sh_name = nmTable.AddName(".rodata");
    sections[1].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[1].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC;
    sections[1].hdr.sh_offset = 512 + sections[0].index; // offset in file
    sections[1].hdr.sh_size = sections[1].index;
    sections[1].hdr.sh_link = 0;
    sections[1].hdr.sh_info = 0;
    sections[1].hdr.sh_addralign = 1;
    sections[1].hdr.sh_entsize = 0;

    sections[2].hdr.sh_name = nmTable.AddName(".data");
    sections[2].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[2].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[2].hdr.sh_offset = 512 + sections[0].index + sections[1].index; // offset in file
    sections[2].hdr.sh_size = sections[2].index;
    sections[2].hdr.sh_link = 0;
    sections[2].hdr.sh_info = 0;
    sections[2].hdr.sh_addralign = 1;
    sections[2].hdr.sh_entsize = 0;

    sections[3].hdr.sh_name = nmTable.AddName(".bss");
    sections[3].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[3].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[3].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
    sections[3].hdr.sh_size = 0;
    sections[3].hdr.sh_link = 0;
    sections[3].hdr.sh_info = 0;
    sections[3].hdr.sh_addralign = 8;
    sections[3].hdr.sh_entsize = 0;

    sections[4].hdr.sh_name = nmTable.AddName(".tls");
    sections[4].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[4].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[4].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
    sections[4].hdr.sh_size = 0;
    sections[4].hdr.sh_link = 0;
    sections[4].hdr.sh_info = 0;
    sections[4].hdr.sh_addralign = 8;
    sections[4].hdr.sh_entsize = 0;

    // Unless debugging there is no real reason to output symbols to the final
    // executable image.
    if (0) {
        sections[5].hdr.sh_name = nmTable.AddName(".strtab");
        // The following line must be before the name table is copied to the section.
        sections[6].hdr.sh_name = nmTable.AddName(".symtab");
        sections[5].hdr.sh_type = clsElf64Shdr::SHT_STRTAB;
        sections[5].hdr.sh_flags = 0;
        sections[5].hdr.sh_addr = 0;
        sections[5].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
        sections[5].hdr.sh_size = nmTable.length;
        sections[5].hdr.sh_link = 0;
        sections[5].hdr.sh_info = 0;
        sections[5].hdr.sh_addralign = 1;
        sections[5].hdr.sh_entsize = 0;
        memcpy(sections[5].bytes, nmTable.text, nmTable.length);
    
        sections[6].hdr.sh_type = clsElf64Shdr::SHT_SYMTAB;
        sections[6].hdr.sh_flags = 0;
        sections[6].hdr.sh_addr = 0;
        sections[6].hdr.sh_offset = Round512(512 + sections[0].index + sections[1].index + sections[2].index) + nmTable.length; // offset in file
        sections[6].hdr.sh_size = (symWarehouse.numsym + 1) * 24;
        sections[6].hdr.sh_link = 5;
        sections[6].hdr.sh_info = 0;
        sections[6].hdr.sh_addralign = 1;
        sections[6].hdr.sh_entsize = 24;
    
        nn = 1;
        // The first entry is an NULL symbol
        elfsym.st_name = 0;
        elfsym.st_info = 0;
        elfsym.st_other = 0;
        elfsym.st_shndx = 0;
        elfsym.st_value = 0;
        elfsym.st_size = 0;
        sections[6].Add(&elfsym);
        for (nn = 0; nn < symWarehouse.numsym; nn++) {
            elfsym.st_name = symWarehouse.syms[nn]->name;
            elfsym.st_info = symWarehouse.syms[nn]->scope == 'P' ? STB_GLOBAL << 4 : 0;
            elfsym.st_other = 0;
            elfsym.st_shndx = symWarehouse.syms[nn]->segment;
            elfsym.st_value = symWarehouse.syms[nn]->value;
            elfsym.st_size = 8;
            sections[6].Add(&elfsym);
        }
    }

    elf.hdr.e_ident[0] = 127;
    elf.hdr.e_ident[1] = 'E';
    elf.hdr.e_ident[2] = 'L';
    elf.hdr.e_ident[3] = 'F';
    elf.hdr.e_ident[4] = clsElf64Header::ELFCLASS64;   // 64 bit file format
    elf.hdr.e_ident[5] = clsElf64Header::ELFDATA2LSB;  // little endian
    elf.hdr.e_ident[6] = 1;        // header version always 1
    elf.hdr.e_ident[7] = 255;      // OS/ABI indentification, 255 = standalone
    elf.hdr.e_ident[8] = 255;      // ABI version
    elf.hdr.e_ident[9] = 0;
    elf.hdr.e_ident[10] = 0;
    elf.hdr.e_ident[11] = 0;
    elf.hdr.e_ident[12] = 0;
    elf.hdr.e_ident[13] = 0;
    elf.hdr.e_ident[14] = 0;
    elf.hdr.e_ident[15] = 0;
    elf.hdr.e_type = 2;               // 2 = executable file
    elf.hdr.e_machine = 888;         // machine architecture
    elf.hdr.e_version = 1;
    elf.hdr.e_entry = 256;
    elf.hdr.e_phoff = 0;
    elf.hdr.e_shoff = sections[4].hdr.sh_offset + sections[4].index;
    elf.hdr.e_flags = 0;
    elf.hdr.e_ehsize = Elf64HdrSz;
    elf.hdr.e_phentsize = 0;
    elf.hdr.e_phnum = 0;
    elf.hdr.e_shentsize = Elf64ShdrSz;
    elf.hdr.e_shnum = 0;              // This will be incremented by AddSection()
    elf.hdr.e_shstrndx = 5;           // index into section table of string table header

    for (nn = 0; nn < 5; nn++)
        elf.AddSection(&sections[nn]);    
    elf.Write(fp);
}



// go back to section zero and update the relocation spots.


int main(int argc, char *argv[])
{
    FILE *fp;
    int nn;

    options(argc, argv);
    nFiles = argc - 1;

    if (nFiles > 0) {
       for (nn = 0; nn < nFiles; nn++) {
           strcpy(File[nn].name,argv[nn+1]);
       }
//	system("pause");
       LinkELFFile();
       fp = fopen("L64.elf","wb");
       WriteELFFile(fp);
       fclose(fp);
    }
    else
        DisplayHelp();
	return 0;
}
