// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// L64 - Linker
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include <cstdlib>
#include <iostream>
#include <inttypes.h>
#include <stdio.h>
#include "NameTable.hpp"
#include "symbol.hpp"
#include "elf.h"

#define TXTBASE      0x23F000
//#define TXTBASE      0xC00200

using namespace std;

int nFiles;
NameTable nmTable;
clsElf64File File[256];
clsElf64Section sections[12];
SymbolFactory symFactory;
SymbolWarehouse symWarehouse;
int debug = 1;
int trigger = 0;
int64_t textbase = TXTBASE;

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

int64_t Round4096(int64_t n)
{
    return (n + 4095LL) & 0xFFFFFFFFFFFFF000LL;
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
    int64_t wd;
    uint8_t b0,b1,b2,b3,b4,b5,b6,b7;
    int64_t offset;
    int64_t sz;
    int bits;

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
        sections[sn].hdr.sh_size = 0;
        for (fn = 0; fn < nFiles; fn++)
            sections[sn].hdr.sh_size += File[fn].sections[sn]->hdr.sh_size;
        // Round to page boundary
        sections[sn].hdr.sh_size = Round4096(sections[sn].hdr.sh_size);

        for (fn = 1; fn < nFiles; fn++)
            File[fn].sections[sn]->hdr.sh_addr = File[fn-1].sections[sn]->hdr.sh_addr + File[fn-1].sections[sn]->hdr.sh_size;
    }
    
    // Adjust the starting virtual address for all the sections.
    
    if (debug)
        printf("Adjusting section start addresses.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        for (sn = 1; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += sections[0].hdr.sh_size;
            //printf("File[%d].section[%d]->hdr.sh_addr=%llx\r\n",fn,sn,File[fn].sections[sn]->hdr.sh_addr);
        }
        for (sn = 2; sn < 5; sn++)
            File[fn].sections[sn]->hdr.sh_addr += sections[1].hdr.sh_size;
        for (sn = 3; sn < 5; sn++)
            File[fn].sections[sn]->hdr.sh_addr += sections[2].hdr.sh_size;
        for (sn = 4; sn < 5; sn++)
            File[fn].sections[sn]->hdr.sh_addr += sections[3].hdr.sh_size;
        File[fn].sections[5]->hdr.sh_addr += sections[4].hdr.sh_size;
    }
    if (debug)
        printf("Adding in textbase.\r\n");
    for (fn = 0; fn < nFiles; fn++) {
        for (sn = 0; sn < 5; sn++) {
            File[fn].sections[sn]->hdr.sh_addr += textbase;
            //printf("File[%d].section[%d]->hdr.sh_addr=%llx\r\n",fn,sn,File[fn].sections[sn]->hdr.sh_addr);
        }
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
            if (debug) printf("File %d section %d\r\n", fn, sn);
            Elf64rel *p = (Elf64rel *)File[fn].sections[sn]->bytes;
            for (mm = 0; mm < File[fn].sections[sn]->hdr.sh_size / File[fn].sections[sn]->hdr.sh_entsize; mm++, p++) {
                bits = (p->r_info >> 8) & 255;
                switch(p->r_info & 255) {
                // 32 bit fixups
                case 1:
                     b0 = File[fn].sections[sn-7]->bytes[p->r_offset+0];
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                     if (p->r_offset==0x20DB)
                        printf("20DB:%llx -> ", wd);
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     if (p->r_offset==0x20DB)
                        printf("%llx\r\n", wd);                     
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
                     if (bits <= 24) {
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b2 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = (b2 << 16) | (b1 << 8) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                     }
                     else if (bits <= 56) {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b2 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b3 = File[fn].sections[sn-7]->bytes[offset+0];
                         b4 = File[fn].sections[sn-7]->bytes[offset+1];
                         b5 = File[fn].sections[sn-7]->bytes[offset+2];
                         b6 = File[fn].sections[sn-7]->bytes[offset+3];
                         wd = (b6 << 48) | (b5 << 40) | (b4 << 32) |
                              (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 32) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 40) & 255;
                         File[fn].sections[sn-7]->bytes[offset+3] = (wd >> 48) & 255;
                     }
                     break;
                case 130:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 24) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                         }
                         else if (bits <= 56) {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] = wd & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 8) & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 16) & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 24) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 32) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 40) & 255;
                             File[fn].sections[sn-7]->bytes[offset+3] = (wd >> 48) & 255;
                         }
                     }
                     break;
                     
                // 16 bit fixups
                case 3:
                     if (bits <= 16) {
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = (b1 << 8) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                     }
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b2 = File[fn].sections[sn-7]->bytes[offset];
                         b3 = File[fn].sections[sn-7]->bytes[offset+1];
                         wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] = 0;
                         File[fn].sections[sn-7]->bytes[offset+3] = 0;
                     }
                     break;
                case 131:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 16) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                         }
                         else {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = wd & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 8) & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 16) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 24) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] = 0;
                             File[fn].sections[sn-7]->bytes[offset+3] = 0;
                         }
                     }
                     break;
    
                // 14 bit fixups
                case 4: 
                     if (bits <= 14) {
                         b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+2] >> 2) & 63;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = (b1 << 6) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 0xFC);
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                     }
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+2] >> 2) & 63;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b2 = File[fn].sections[sn-7]->bytes[offset+0];
                         b3 = File[fn].sections[sn-7]->bytes[offset+1];
                         b4 = File[fn].sections[sn-7]->bytes[offset+2];
                         wd = (b4 << 30) | (b3 << 22) | (b2 << 14) | (b1 << 6) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 0xFC);
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 14) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 22) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 30) & 3;
                         File[fn].sections[sn-7]->bytes[offset+3] <= 0;
                     }
                     break;
                case 132:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 14) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 0xFC);
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                         }
                         else {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0x3) | ((wd << 2) & 0xFC);
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 6) & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 14) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 22) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 30) & 3;
                             File[fn].sections[sn-7]->bytes[offset+3] <= 0;
                         }
                     }
                     break;
    
               // 4 bit fixups
               // For 4 bit fixups we just assume there will be a preceding constant
               // extension word. A code or data address space less than five bits
               // is bound to be a rare case.
                case 5:
                     offset = p->r_offset;
                     if ((offset & 15)==0)
                         offset -= 6;
                     else
                         offset -= 5;
                     b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+3] >> 4) & 15;
                     b1 = File[fn].sections[sn-7]->bytes[offset+0];
                     b2 = File[fn].sections[sn-7]->bytes[offset+1];
                     b3 = File[fn].sections[sn-7]->bytes[offset+2];
                     b4 = File[fn].sections[sn-7]->bytes[offset+3];
                     wd = (b4 << 28) | (b3 << 20) | (b2 << 12) | (b1 << 4) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x15) | (((wd & 15) << 4));
                     File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 4) & 255;
                     File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 12) & 255;
                     File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 20) & 255;
                     File[fn].sections[sn-7]->bytes[offset+3] <= (wd >> 28) & 15;
                     break;
                case 133:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x15) | (((wd & 15) << 4));
                         File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 4) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 12) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 20) & 255;
                         File[fn].sections[sn-7]->bytes[offset+3] <= (wd >> 28) & 15;
                     }
                     break;

                // Data fixup
                // 64 bit fixups
                case 6:
                     b0 = File[fn].sections[sn-7]->bytes[p->r_offset+0];
                     b1 = File[fn].sections[sn-7]->bytes[p->r_offset+1];
                     b2 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                     b3 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                     b4 = File[fn].sections[sn-7]->bytes[p->r_offset+4];
                     b5 = File[fn].sections[sn-7]->bytes[p->r_offset+5];
                     b6 = File[fn].sections[sn-7]->bytes[p->r_offset+6];
                     b7 = File[fn].sections[sn-7]->bytes[p->r_offset+7];
                     wd = (b7 << 56) |
                          (b6 << 48) | (b5 << 40) | (b4 << 32) |
                          (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+0] = wd & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+1] = (wd >> 8) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 16) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 24) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+4] = (wd >> 32) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+5] = (wd >> 40) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+6] = (wd >> 48) & 255;
                     File[fn].sections[sn-7]->bytes[p->r_offset+7] = (wd >> 56) & 255;
                     break;
                case 134:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+0] = wd & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+4] = (wd >> 32) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+5] = (wd >> 40) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+6] = (wd >> 48) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+7] = (wd >> 56) & 255;
                     }
                     break;
                // 8 bit fixups
                case 7:
                     if (bits <= 8) {
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = wd & 255;
                     }
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b1 = File[fn].sections[sn-7]->bytes[offset];
                         b2 = File[fn].sections[sn-7]->bytes[offset+1];
                         b3 = File[fn].sections[sn-7]->bytes[offset+2];
                         wd = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = wd & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 8) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 16) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 24) & 255;
                         File[fn].sections[sn-7]->bytes[offset+3] = 0;
                     }
                     break;
                case 135:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 8) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = wd & 255;
                         }
                         else {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = wd & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 8) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 16) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 24) & 255;
                             File[fn].sections[sn-7]->bytes[offset+3] = 0;
                         }
                     }
                     break;

                // 20 bit fixups
                case 8:
                     if (bits <= 20) {
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+1] >> 4;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b2 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = (b2 << 12) | (b1 << 4) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] &= 0x0F;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] |= ((wd & 15) << 4);
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 4) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 12) & 255;
                     }
                     else if (bits <= 52) {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = File[fn].sections[sn-7]->bytes[p->r_offset+1] >> 4;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+2];
                         b2 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b3 = File[fn].sections[sn-7]->bytes[offset+0];
                         b4 = File[fn].sections[sn-7]->bytes[offset+1];
                         b5 = File[fn].sections[sn-7]->bytes[offset+2];
                         b6 = File[fn].sections[sn-7]->bytes[offset+3];
                         wd = (b6 << 44) | (b5 << 36) | (b4 << 28) |
                              (b3 << 20) | (b2 << 12) | (b1 << 4) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] &= 0x0F;
                         File[fn].sections[sn-7]->bytes[p->r_offset+1] |= ((wd & 15) << 4);
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 4) & 255;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 12) & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 20) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 28) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 36) & 255;
                         File[fn].sections[sn-7]->bytes[offset+3] = (wd >> 44) & 255;
                     }
                     break;
                case 136:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 20) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] &= 0x0F;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] |= ((wd & 15) << 4);
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 4) & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 12) & 255;
                         }
                         else if (bits <= 52) {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] &= 0x0F;
                             File[fn].sections[sn-7]->bytes[p->r_offset+1] |= ((wd & 15) << 4);
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] = (wd >> 4) & 255;
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] = (wd >> 12) & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] = (wd >> 20) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] = (wd >> 28) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] = (wd >> 36) & 255;
                             File[fn].sections[sn-7]->bytes[offset+3] = (wd >> 44) & 255;
                         }
                     }
                     break;

                // 12 bit fixups
                case 10: 
                     if (bits <= 12) {
                         b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+2] >> 4) & 15;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         wd = (b1 << 4) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0xF) | (((wd & 15) << 4));
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 4) & 255;
                     }
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+2] >> 4) & 15;
                         b1 = File[fn].sections[sn-7]->bytes[p->r_offset+3];
                         b2 = File[fn].sections[sn-7]->bytes[offset+0];
                         b3 = File[fn].sections[sn-7]->bytes[offset+1];
                         b4 = File[fn].sections[sn-7]->bytes[offset+2];
                         wd = (b4 << 28) | (b3 << 20) | (b2 << 12) | (b1 << 4) | b0;
                         wd += File[fn].sections[sn-7]->hdr.sh_addr;
                         File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0xF) | (((wd & 15)<< 4));
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 4) & 255;
                         File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 12) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 20) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 28) & 15;
                         File[fn].sections[sn-7]->bytes[offset+3] <= 0;
                     }
                     break;
                case 138:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         if (bits <= 12) {
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0xF) | (((wd & 15) << 4));
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 4) & 255;
                         }
                         else {
                             offset = p->r_offset;
                             if ((offset & 15)==0)
                                 offset -= 6;
                             else
                                 offset -= 5;
                             wd = sym->value;
                             File[fn].sections[sn-7]->bytes[p->r_offset+2] <= (File[fn].sections[0]->bytes[p->r_offset+2] & 0xF) | (((wd & 15) << 4));
                             File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (wd >> 4) & 255;
                             File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 12) & 255;
                             File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 20) & 255;
                             File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 28) & 15;
                             File[fn].sections[sn-7]->bytes[offset+3] <= 0;
                         }
                     }
                     break;

               // 2 bit fixups
               // For 2 bit fixups we just assume there will be a preceding constant
               // extension word. A code or data address space less than three bits
               // is bound to be a rare case.
                case 11:
                     offset = p->r_offset;
                     if ((offset & 15)==0)
                         offset -= 6;
                     else
                         offset -= 5;
                     b0 = (File[fn].sections[sn-7]->bytes[p->r_offset+3] >> 6) & 3;
                     b1 = File[fn].sections[sn-7]->bytes[offset+0];
                     b2 = File[fn].sections[sn-7]->bytes[offset+1];
                     b3 = File[fn].sections[sn-7]->bytes[offset+2];
                     b4 = File[fn].sections[sn-7]->bytes[offset+3];
                     wd = (b4 << 26) | (b3 << 18) | (b2 << 10) | (b1 << 2) | b0;
                     wd += File[fn].sections[sn-7]->hdr.sh_addr;
                     File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x3F) | (((wd & 3) << 6));
                     File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 2) & 255;
                     File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 10) & 255;
                     File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 18) & 255;
                     File[fn].sections[sn-7]->bytes[offset+3] <= (wd >> 26) & 63;
                     break;
                case 139:
                     sym = Lookup(p, fn);
                     if (!sym)
                         printf("Unresolved external <%s>\r\n", nmTable.GetName(sym->name));
                     else {
                         offset = p->r_offset;
                         if ((offset & 15)==0)
                             offset -= 6;
                         else
                             offset -= 5;
                         wd = sym->value;
                         File[fn].sections[sn-7]->bytes[p->r_offset+3] <= (File[fn].sections[0]->bytes[p->r_offset+3] & 0x3F) | (((wd & 3)<< 6));
                         File[fn].sections[sn-7]->bytes[offset+0] <= (wd >> 2) & 255;
                         File[fn].sections[sn-7]->bytes[offset+1] <= (wd >> 10) & 255;
                         File[fn].sections[sn-7]->bytes[offset+2] <= (wd >> 18) & 255;
                         File[fn].sections[sn-7]->bytes[offset+3] <= (wd >> 26) & 63;
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
    for (sn = 0; sn < 5; sn++) {
        sections[sn].Clear();
    }
    
    // Combine sections of the same type from all the files.
    // Pad the section out to 4096 byte alignment.
    // All section zero's go to master section zero
    // All section one's go to master section one, etc.
    //
    for (sn = 0; sn < 5; sn++) {
        sections[sn].hdr.sh_addr = File[0].sections[sn]->hdr.sh_addr;
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
    clsElf64Phdr phdr[6];
    int64_t start;
    Symbol *sym;

    if (debug)
        printf("Writing ELF file.\r\n");
    // text
    sections[0].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[0].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_EXECINSTR;
    sections[0].hdr.sh_offset = 512;  // offset in file
    sections[0].hdr.sh_size = sections[0].index;
    sections[0].hdr.sh_link = 0;
    sections[0].hdr.sh_info = 0;
    sections[0].hdr.sh_addralign = 16;
    sections[0].hdr.sh_entsize = 0;
    phdr[0].p_type = clsElf64Phdr::PT_LOAD;
    phdr[0].p_flags = clsElf64Phdr::PF_X | clsElf64Phdr::PF_R;
    phdr[0].p_offset = 512;
    phdr[0].p_vaddr = sections[0].hdr.sh_addr;
    phdr[0].p_paddr = 0;   // reserved
    phdr[0].p_filesz = sections[0].index;
    phdr[0].p_memsz = sections[0].index;
    phdr[0].p_align = 4096;

    // rodata
    sections[1].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[1].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC;
    sections[1].hdr.sh_offset = 512 + sections[0].index; // offset in file
    sections[1].hdr.sh_size = sections[1].index;
    sections[1].hdr.sh_link = 0;
    sections[1].hdr.sh_info = 0;
    sections[1].hdr.sh_addralign = 8;
    sections[1].hdr.sh_entsize = 0;
    phdr[1].p_type = clsElf64Phdr::PT_LOAD;
    phdr[1].p_flags = clsElf64Phdr::PF_R;
    phdr[1].p_offset = sections[1].hdr.sh_offset;
    phdr[1].p_vaddr = sections[1].hdr.sh_addr;
    //printf("vaddr:%llx\r\n",sections[1].hdr.sh_addr);
    phdr[1].p_paddr = 0;   // reserved
    phdr[1].p_filesz = sections[1].index;
    phdr[1].p_memsz = sections[1].index;
    phdr[1].p_align = 4096;

    // data
    sections[2].hdr.sh_type = clsElf64Shdr::SHT_PROGBITS;
    sections[2].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[2].hdr.sh_offset = 512 + sections[0].index + sections[1].index; // offset in file
    sections[2].hdr.sh_size = sections[2].index;
    sections[2].hdr.sh_link = 0;
    sections[2].hdr.sh_info = 0;
    sections[2].hdr.sh_addralign = 8;
    sections[2].hdr.sh_entsize = 0;
    phdr[2].p_type = clsElf64Phdr::PT_LOAD;
    phdr[2].p_flags = clsElf64Phdr::PF_W | clsElf64Phdr::PF_R;
    phdr[2].p_offset = sections[2].hdr.sh_offset;
    phdr[2].p_vaddr = sections[2].hdr.sh_addr;
    phdr[2].p_paddr = 0;   // reserved
    phdr[2].p_filesz = sections[2].index;
    phdr[2].p_memsz = sections[2].index;
    phdr[2].p_align = 4096;

    // bss
    sections[3].hdr.sh_type = clsElf64Shdr::SHT_NOBITS;
    sections[3].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[3].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
    sections[3].hdr.sh_size = 0;
    sections[3].hdr.sh_link = 0;
    sections[3].hdr.sh_info = 0;
    sections[3].hdr.sh_addralign = 8;
    sections[3].hdr.sh_entsize = 0;
    phdr[3].p_type = clsElf64Phdr::PT_NULL;
    phdr[3].p_flags = clsElf64Phdr::PF_W | clsElf64Phdr::PF_R;
    phdr[3].p_offset = sections[3].hdr.sh_offset;
    phdr[3].p_vaddr = sections[3].hdr.sh_addr;
    phdr[3].p_paddr = 0;   // reserved
    phdr[3].p_filesz = 0;
    phdr[3].p_memsz = sections[3].index;
    phdr[3].p_align = 4096;

    // tls
    sections[4].hdr.sh_type = clsElf64Shdr::SHT_NOBITS;
    sections[4].hdr.sh_flags = clsElf64Shdr::SHF_ALLOC | clsElf64Shdr::SHF_WRITE;
    sections[4].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
    sections[4].hdr.sh_size = 0;
    sections[4].hdr.sh_link = 0;
    sections[4].hdr.sh_info = 0;
    sections[4].hdr.sh_addralign = 8;
    sections[4].hdr.sh_entsize = 0;
    phdr[4].p_type = clsElf64Phdr::PT_NULL;
    phdr[4].p_flags = clsElf64Phdr::PF_W | clsElf64Phdr::PF_R;
    phdr[4].p_offset = sections[4].hdr.sh_offset;
    phdr[4].p_vaddr = sections[4].hdr.sh_addr;
    phdr[4].p_paddr = 0;   // reserved
    phdr[4].p_filesz = 0;
    phdr[4].p_memsz = sections[4].index;
    phdr[4].p_align = 4096;

    // This bit must be before the name table is cleared.
    // Once the name table is cleared the symbol table is no longer valid.
    sym = symWarehouse.FindSymbol("start");
    if (sym) {
        if (debug) printf("Found start: %llx\r\n", sym->value);
        start = sym->value;
    }
    else
        start = TXTBASE;

    nmTable.Clear();
    sections[0].hdr.sh_name = nmTable.AddName(".text");
    sections[1].hdr.sh_name = nmTable.AddName(".rodata");
    sections[2].hdr.sh_name = nmTable.AddName(".data");
    sections[3].hdr.sh_name = nmTable.AddName(".bss");
    sections[4].hdr.sh_name = nmTable.AddName(".tls");
    sections[5].hdr.sh_name = nmTable.AddName(".strtab");
    sections[5].hdr.sh_type = clsElf64Shdr::SHT_STRTAB;
    sections[5].hdr.sh_flags = 0;
    sections[5].hdr.sh_addr = 0;
    sections[5].hdr.sh_offset = 512 + sections[0].index + sections[1].index + sections[2].index; // offset in file
    sections[5].hdr.sh_size = nmTable.length;
    sections[5].hdr.sh_link = 0;
    sections[5].hdr.sh_info = 0;
    sections[5].hdr.sh_addralign = 1;
    sections[5].hdr.sh_entsize = 0;
    for (nn = 0; nn < nmTable.length; nn++)
        sections[5].AddByte(nmTable.text[nn]);

    // Unless debugging there is no real reason to output symbols to the final
    // executable image.
    if (0) {
    
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
    elf.hdr.e_entry = start;
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
        elf.AddPhdr(&phdr[nn]);
    for (nn = 0; nn < 6; nn++)
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
       if (fp) {
           WriteELFFile(fp);
           fclose(fp);
       }
       else printf("Can't open L64.elf for output.\r\n");
    }
    else
        DisplayHelp();
	return 0;
}
