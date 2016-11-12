// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// A64 - Assembler
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
#ifndef ELF_H
#define ELF_H

class clsElf64Header {
public:
    enum {
        ELFCLASS32 = 1,
        ELFCLASS64 = 2
    };
    enum {
        ELFDATA2LSB = 1,
        ELFDATA2MSB = 2
    };

    char e_ident[16];
    int16_t e_type;
    int16_t e_machine;
    int32_t e_version;
    int64_t e_entry;            // program entry point
    int64_t e_phoff;            // offset in file to program header
    int64_t e_shoff;            // offset in file to section header
    int32_t e_flags;            // 
    int16_t e_ehsize;           // size of ELF header
    int16_t e_phentsize;        // size of program header entry
    int16_t e_phnum;            // number of program header entries
    int16_t e_shentsize;        // size of section header entry
    int16_t e_shnum;            // number of section header entries
    int16_t e_shstrndx;         // section name string table index
    
    clsElf64Header() {
        memset((void*)e_ident,0,sizeof(e_ident));
        e_ident[0] = 127;
        e_ident[1] = 'E';
        e_ident[2] = 'L';
        e_ident[3] = 'F';
        e_type = 0;
        e_machine = 0;
        e_version = 1;
        e_entry = 0;
        e_phoff = 0;
        e_shoff = 0;
        e_flags = 0;
        e_ehsize = 0;
        e_phentsize = 0;
        e_phnum = 0;
        e_shentsize = 0;
        e_shnum = 0;
        e_shstrndx = 0;
    };

    void Write(FILE *fp) {
         fwrite((void *)e_ident,1,16,fp);
         fwrite((void *)&e_type,1,sizeof(e_type),fp);
         fwrite((void *)&e_machine,1,sizeof(e_machine),fp);
         fwrite((void *)&e_version,1,sizeof(e_version),fp);
         fwrite((void *)&e_entry,1,sizeof(e_entry),fp);
         fwrite((void *)&e_phoff,1,sizeof(e_phoff),fp);
         fwrite((void *)&e_shoff,1,sizeof(e_shoff),fp);
         fwrite((void *)&e_flags,1,sizeof(e_flags),fp);
         fwrite((void *)&e_ehsize,1,sizeof(e_ehsize),fp);
         fwrite((void *)&e_phentsize,1,sizeof(e_phentsize),fp);
         fwrite((void *)&e_phnum,1,sizeof(e_phnum),fp);
         fwrite((void *)&e_shentsize,1,sizeof(e_shentsize),fp);
         fwrite((void *)&e_shnum,1,sizeof(e_shnum),fp);
         fwrite((void *)&e_shstrndx,1,sizeof(e_shstrndx),fp);
    };
    
    void Read(FILE *fp) {
         fread((void *)e_ident,1,16,fp);
         fread((void *)&e_type,1,sizeof(e_type),fp);
         fread((void *)&e_machine,1,sizeof(e_machine),fp);
         fread((void *)&e_version,1,sizeof(e_version),fp);
         fread((void *)&e_entry,1,sizeof(e_entry),fp);
         fread((void *)&e_phoff,1,sizeof(e_phoff),fp);
         fread((void *)&e_shoff,1,sizeof(e_shoff),fp);
         fread((void *)&e_flags,1,sizeof(e_flags),fp);
         fread((void *)&e_ehsize,1,sizeof(e_ehsize),fp);
         fread((void *)&e_phentsize,1,sizeof(e_phentsize),fp);
         fread((void *)&e_phnum,1,sizeof(e_phnum),fp);
         fread((void *)&e_shentsize,1,sizeof(e_shentsize),fp);
         fread((void *)&e_shnum,1,sizeof(e_shnum),fp);
         fread((void *)&e_shstrndx,1,sizeof(e_shstrndx),fp);
    };
};

typedef struct {
    int64_t p_type;             // type of segment
    int64_t p_flags;            // segment attributes
    int64_t p_offset;           // offset in file
    int64_t p_vaddr;            // virtual address
    int64_t p_paddr;            // reserved
    int64_t p_filesz;           // size of segment in file
    int64_t p_memsz;            // size of segment in memory
    int64_t p_align;            // alignment of segment
} Elf64Phdr;

class clsElf64Shdr {
public:
    enum {
        SHT_PROGBITS = 1,
        SHT_SYMTAB = 2,
        SHT_STRTAB = 3,
        SHT_REL = 9,
    };
    enum {
        SHF_WRITE = 1,
        SHF_ALLOC = 2,
        SHF_EXECINSTR = 4
    };
    int32_t sh_name;
    int32_t sh_type;
    int64_t sh_flags;
    int64_t sh_addr;
    int64_t sh_offset;
    int64_t sh_size;
    int32_t sh_link;
    int32_t sh_info;
    int64_t sh_addralign;
    int64_t sh_entsize;

    void Write(FILE *fp) {
         fwrite((void*)&sh_name,1,sizeof(sh_name),fp);
         fwrite((void*)&sh_type,1,sizeof(sh_type),fp);
         fwrite((void*)&sh_flags,1,sizeof(sh_flags),fp);
         fwrite((void*)&sh_addr,1,sizeof(sh_addr),fp);
         fwrite((void*)&sh_offset,1,sizeof(sh_offset),fp);
         fwrite((void*)&sh_size,1,sizeof(sh_size),fp);
         fwrite((void*)&sh_link,1,sizeof(sh_link),fp);
         fwrite((void*)&sh_info,1,sizeof(sh_info),fp);
         fwrite((void*)&sh_addralign,1,sizeof(sh_addralign),fp);
         fwrite((void*)&sh_entsize,1,sizeof(sh_entsize),fp);
    };
    void Read(FILE *fp) {
         fread((void*)&sh_name,1,sizeof(sh_name),fp);
         fread((void*)&sh_type,1,sizeof(sh_type),fp);
         fread((void*)&sh_flags,1,sizeof(sh_flags),fp);
         fread((void*)&sh_addr,1,sizeof(sh_addr),fp);
         fread((void*)&sh_offset,1,sizeof(sh_offset),fp);
         fread((void*)&sh_size,1,sizeof(sh_size),fp);
         fread((void*)&sh_link,1,sizeof(sh_link),fp);
         fread((void*)&sh_info,1,sizeof(sh_info),fp);
         fread((void*)&sh_addralign,1,sizeof(sh_addralign),fp);
         fread((void*)&sh_entsize,1,sizeof(sh_entsize),fp);
    };
};

#define STB_GLOBAL     1

typedef struct {
    int32_t st_name;
    int8_t st_info;
    int8_t st_other;
    int16_t st_shndx;
    int64_t st_value;
    int64_t st_size;
} Elf64Symbol;

typedef struct {
    int64_t r_offset;
    int64_t r_info;
} Elf64rel;

typedef struct {
    int64_t r_offset;
    int64_t r_info;
    int64_t r_addend;
} Elf64rela;

// My own constructions
typedef struct {
    clsElf64Shdr hdr;
    int64_t length;
    int64_t index;
    int64_t address;
    int64_t start;
    int64_t end;
    uint8_t bytes[10000000];
} Elf64Section;

class clsElf64Section {
public:
    clsElf64Shdr hdr;
    int64_t length;
    int64_t index;
    int64_t address;
    int64_t start;
    int64_t end;
    uint8_t bytes[10000000];
public:
    clsElf64Section() {
        length = 0;
        index = 0;
        start = 0;
        end = 0;
        address = 0;
        memset(bytes,0,sizeof(bytes));
    };
    void Clear() {
        length = 0;
        index = 0;
        start = 0;
        end = 0;
        address = 0;
        memset(bytes,0,sizeof(bytes));
    };
    void AddByte(int64_t byt) {
        bytes[index] = byt & 255LL;
        if (index==0)
            start = address;
        index++;
        address++;
        if (address > end)
            end = address;
    };
    void AddChar(int64_t chr) {
        AddByte(chr & 255LL);
        AddByte((chr >> 8) & 255LL);
    };
    void AddHalf(int64_t chr) {
        AddChar(chr & 0xFFFFLL);
        AddChar((chr >> 16) & 0xFFFFLL);
    };
    void AddWord(int64_t wd) {
        AddHalf(wd & 0xFFFFFFFFLL);
        AddHalf((wd >> 32) & 0xFFFFFFFFLL);
    };
    void Add(Elf64Symbol *sym) {
        AddHalf(sym->st_name);
        AddByte(sym->st_info);        
        AddByte(sym->st_other);
        AddChar(sym->st_shndx);
        AddWord(sym->st_value);
        AddWord(sym->st_size);
    };
    void AddRel(int64_t addr, int64_t info) {
        AddWord(addr);
        AddWord(info);
    };
    void Write(FILE *fp) {
        fwrite((void *)bytes,1,hdr.sh_size,fp);
    };
    void Read(FILE *fp) {
        fread((void *)bytes,1,hdr.sh_size,fp);
    };
};

class clsElf64File
{
public:
    clsElf64Header hdr;
    clsElf64Section *sections[256];

    void AddSection(clsElf64Section *sect) {
        sections[hdr.e_shnum] = sect;
        hdr.e_shnum++;
    };

    void WriteSectionHeaderTable(FILE *fp) {
        int nn;
        
        for (nn = 0; nn < hdr.e_shnum; nn++) {
            sections[nn]->hdr.Write(fp);
        }
    };

    void Write(FILE *fp) {
        int nn;

        hdr.Write(fp);        
        fseek(fp, 512, SEEK_SET);
        for (nn = 0; nn < hdr.e_shnum; nn++) {
            fseek(fp, sections[nn]->hdr.sh_offset, SEEK_SET);
            sections[nn]->Write(fp);
        }
        fseek(fp, hdr.e_shoff, SEEK_SET);
        WriteSectionHeaderTable(fp);
    };
};


#define Elf64HdrSz   64
#define Elf64pHdrSz  64
#define Elf64ShdrSz  64

#endif
