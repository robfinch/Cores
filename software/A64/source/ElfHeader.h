#ifndef ELF_H
#define ELF_H

enum {
    ELFCLASS32 = 1,
    ELFCLASS64 = 2
};
enum {
    ELFDATA2LSB = 1,
    ELFDATA2MSB = 2
};

typedef struct {
    char e_ident[16];
    int16_t e_type;
    int16_t e_machine;
    int32_t e_version;
    int64_t e_entry;            // program entry point
    int64_t e_phoff;            // offset in file to program header
    int64_t e_shoff;            // offset in gile to section header
    int32_t e_flags;            // 
    int16_t e_ehsize;           // size of ELF header
    int16_t e_phentsize;        // size of program header entry
    int16_t e_phnum;            // number of program header entries
    int16_t e_shentsize;        // size of section header entry
    int16_t e_shnum;            // number of section header entries
    int16_t e_shstrndx;         // section name string table index
} Elf64Header;

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

enum {
    SHT_PROGBITS = 1,
    SHT_SYMTAB = 2,
    SHT_STRTAB = 3,
};
enum {
    SHF_WRITE = 1,
    SHF_ALLOC = 2,
    SHF_EXECINSTR = 3
};

typedef struct {
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
} Elf64Shdr;

#define STB_GLOBAL     1

typedef struct {
    int32_t st_name;
    int8_t st_info;
    int8_t st_other;
    int16_t st_shndx;
    int64_t st_value;
    int64_t st_size;
} Elf64Symbol;

#define Elf64HdrSize 64
#define Elf64pHdrSz  64
#define Elf64ShdrSz  64


#endif
