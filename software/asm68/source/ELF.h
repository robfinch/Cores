#ifndef ELF_H
#define ELF_H

typedef unsigned __int64 Elf64_Addr;
typedef unsigned __int64 Elf64_Off;
typedef unsigned __int16 Elf64_Half;
typedef unsigned __int32 Elf64_Word;
typedef __int32 Elf64_Sword;
typedef unsigned __int64 Elf64_Xword;
typedef __int64 Elf64_Sxword;

typedef struct
{
	unsigned __int8 e_ident[16]; /* ELF identification */
	Elf64_Half e_type; /* Object file type */
	Elf64_Half e_machine; /* Machine type */
	Elf64_Word e_version; /* Object file version */
	Elf64_Addr e_entry; /* Entry point address */
	Elf64_Off e_phoff; /* Program header offset */
	Elf64_Off e_shoff; /* Section header offset */
	Elf64_Word e_flags; /* Processor-specific flags */
	Elf64_Half e_ehsize; /* ELF header size */
	Elf64_Half e_phentsize; /* Size of program header entry */
	Elf64_Half e_phnum; /* Number of program header entries */
	Elf64_Half e_shentsize; /* Size of section header entry */
	Elf64_Half e_shnum; /* Number of section header entries */
	Elf64_Half e_shstrndx; /* Section name string table index */
} Elf64_Ehdr;

enum {
	EI_MAG0=0,
	EI_MAG1,
	EI_MAG2,
	EI_MAG3,
	EI_CLASS,
	EI_DATA,
	EI_VERSION,
	EI_OSABI,
	EI_ABIVERSION,
	EI_PAD,
	EI_NIDENT=16
};

#define ELFCLASS32	1
#define ELFCLASS64	2
#define ELFDATA2LSB	1
#define ELFDATA2MSB	2
#define ELFOSABI_STANDALONE	255

enum {
	ET_NONE = 0,
	ET_REL,			// relocatable object file
	ET_EXEC,		// executable file
	ET_DYN,			// shared object file
	ET_CORE,		// Core file
	ET_LOOS=0xFE00,
	ET_HIOS=0xFEFF,
	ET_LOPROC=0xFF00,
	ET_HIPROC=0xFFFF
};

#define SHN_UNDEF	0
#define SHN_LOPROC	0xFF00
#define SHN_HIPROC	0xFF1F
#define SHN_LOOS	0xFF20
#define SHN_HIOS	0xFF3F
#define SHN_ABS		0xFFF1		// indicate that the corresponding reference is an absolute value
#define SHN_COMMON	0xFFF2

typedef struct
{
	Elf64_Word sh_name; /* Section name */
	Elf64_Word sh_type; /* Section type */
	Elf64_Xword sh_flags; /* Section attributes */
	Elf64_Addr sh_addr; /* Virtual address in memory */
	Elf64_Off sh_offset; /* Offset in file */
	Elf64_Xword sh_size; /* Size of section */
	Elf64_Word sh_link; /* Link to other section */
	Elf64_Word sh_info; /* Miscellaneous information */
	Elf64_Xword sh_addralign; /* Address alignment boundary */
	Elf64_Xword sh_entsize; /* Size of entries, if section has table */
} Elf64_Shdr;

typedef struct
{
	Elf64_Word st_name; /* Symbol name */
	unsigned char st_info; /* Type and Binding attributes */
	unsigned char st_other; /* Reserved */
	Elf64_Half st_shndx; /* Section table index */
	Elf64_Addr st_value; /* Symbol value */
	Elf64_Xword st_size; /* Size of object (e.g., common) */
} Elf64_Sym;

typedef struct
{
	Elf64_Addr r_offset; /* Address of reference */
	Elf64_Xword r_info; /* Symbol index and type of relocation */
} Elf64_Rel;

typedef struct
{
	Elf64_Addr r_offset; /* Address of reference */
	Elf64_Xword r_info; /* Symbol index and type of relocation */
	Elf64_Sxword r_addend; /* Constant part of expression */
} Elf64_Rela;

typedef struct
{
	Elf64_Word p_type; /* Type of segment */
	Elf64_Word p_flags; /* Segment attributes */
	Elf64_Off p_offset; /* Offset in file */
	Elf64_Addr p_vaddr; /* Virtual address in memory */
	Elf64_Addr p_paddr; /* Reserved */
	Elf64_Xword p_filesz; /* Size of segment in file */
	Elf64_Xword p_memsz; /* Size of segment in memory */
	Elf64_Xword p_align; /* Alignment of segment */
} Elf64_Phdr;

typedef struct
{
	Elf64_Sxword d_tag;
	union {
		Elf64_Xword d_val;
		Elf64_Addr d_ptr;
	} d_un;
} Elf64_Dyn;

#define SHT_STRTAB	3

#endif
