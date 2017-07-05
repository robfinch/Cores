#include "ELF.h"

unsigned long
elf64_hash(const unsigned char *name)
{
unsigned long h = 0, g;
while (*name) {
h = (h << 4) + *name++;
if (g = h & 0xf0000000)
h ^= g >> 24;
h &= 0x0fffffff ;
}
return h;
}

void elf64_BuildFileHeader(Elf64_Addr StartAddress)
{
	Elf64_Ehdr eh;

	eh.e_ident[EI_MAG0] = '\x7f';
	eh.e_ident[EI_MAG1] = 'E';
	eh.e_ident[EI_MAG2] = 'L';
	eh.e_ident[EI_MAG3] = 'F';
	eh.e_ident[EI_CLASS] = ELFCLASS32;
	eh.e_ident[EI_DATA] = ELFDATA2LSB;
	eh.e_ident[EI_OSABI] = ELFOSABI_STANDALONE;
	eh.e_entry = StartAddress;
	eh.e_ehsize = sizeof(eh);
	eh.e_phentsize = sizeof(Elf64_Phdr);
	eh.e_shentsize = sizeof(Elf64_Shdr);
	eh.e_type = ET_REL;	// relocatable object file (pre-linker)
}

void elf64_BuildSectionHeader(char *name)
{
	Elf64_Shdr sh;

	sh.sh_name = 0;
}

void elf64_BuildStringSectionHeader()
{
	Elf64_Shdr sh;

	sh.sh_type = SHT_STRTAB;
	sh.sh_offset = sizeof(Elf64_Ehdr);
}

//void elf64_outputFile()
//{
//	elf64_outputFileHeader();
//	elf64_outputStringSection();
//	elf64_outputStringSectionHeader();
//}
//
void elf64_outputFileHeader()
{
}

