#include "stdafx.h"

void Elf64File_WriteHeader(Elf64File *f, FILE *fp)
{
     f->hdr.e_ident[0] = 127;
     f->hdr.e_ident[1] = 'E';
     f->hdr.e_ident[2] = 'L';
     f->hdr.e_ident[3] = 'F';
     f->hdr.e_ident[4] = ELFCLASS64;
     f->hdr.e_ident[5] = ELFDATA2LSB;
     f->hdr.e_ident[6] = 1;          // header version, always 1
     f->hdr.e_ident[7] = 255;        // OS/ABI identification, 255 = standalone
     f->hdr.e_ident[8] = 255;        // OS/ABI version
     f->hdr.e_ident[9] = 0;          // reserved byte
     f->hdr.e_ident[10] = 0;          // reserved byte
     f->hdr.e_ident[11] = 0;          // reserved byte
     f->hdr.e_ident[12] = 0;          // reserved byte
     f->hdr.e_ident[13] = 0;          // reserved byte
     f->hdr.e_ident[14] = 0;          // reserved byte
     f->hdr.e_ident[15] = 0;          // reserved byte
     f->hdr.e_type = 2;
     f->hdr.e_machine = 888;
     f->hdr.e_version = 1;
     f->hdr.e_entry = 0;
     f->hdr.e_phoff = 160;
     f->hdr.e_shoff = 0;
     f->hdr.e_flags = 0;
     f->hdr.e_ehsize = Elf64HdrSize;  // 64
     f->hdr.e_phentsize = 64;
     f->hdr.e_phnum = 4;
     f->hdr.e_shentsize = 0;
     f->hdr.e_shnum = 0;
     f->hdr.e_shstrndx = 0;    
}

void Elf64File_WriteCodeSegmentHeader(FILE *fp)
{
     Elf64Phdr hdr;
     
     hdr.p_type = 1;          // loadable code
     hdr.p_flags = 1;         // execute only
     hdr.p_offset = 512;      // offset of segment in file
     hdr.p_vaddr = 4096;      // virtual address
     hdr.p_paddr = 0;         // physical address (not used)
     hdr.p_filesz = binndx;   // size of segment in file
     hdr.p_memsz == binndx;   // size of segment in memory
     hdr.p_align = 1;         // alignment of segment in memory
     Elf64Phdr_Write(&hdr, fp);
}

void Elf64File_WriteDataSegmentHeader(FILE *fp)
{
    Elf64Phdr hdr;
     
    hdr.p_type = 1;  // loadable code
    hdr.p_flags = 6; // read/write only
    hdr.p_offset = 512 + binndx;    // offset of segment in file
    hdr.p_vaddr = 4096;
    hdr.p_paddr = 0;
    hdr.p_filesz = sections[2].sect.index;
    hdr.p_memsz = sections[2].sect.index;
    hdr.p_align = 8;
    Elf64Phdr_Write(&hdr, fp);
}

void Elf64File_WriteBSSSegmentHeader(FILE *fp)
{
    Elf64Phdr hdr;
     
    hdr.p_type = 1;  // loadable code
    hdr.p_flags = 6; // read/write only
    hdr.p_offset = 512 + sections[0].sect.index + sections[1].sect.index + sections[2].sect.index;    // offset of segment in file
    hdr.p_vaddr = sections[3].sect.start;
    hdr.p_paddr = 0;
    hdr.p_filesz = 0;
    hdr.p_memsz = sections[3].sect.index;
    hdr.p_align = 8;
    Elf64Phdr_Write(&hdr, fp);
}

void Elf64File_WriteTLSSegmentHeader(FILE *fp)
{
    Elf64Phdr hdr;
     
    hdr.p_type = 1;  // loadable code
    hdr.p_flags = 6; // read/write only
    hdr.p_offset = 512 + sections[0].sect.index + sections[1].sect.index + sections[2].sect.index;    // offset of segment in file
    hdr.p_vaddr = 0;//tlsStart;
    hdr.p_paddr = 0;
    hdr.p_filesz = 0;
    hdr.p_memsz = sections[4].sect.index;
    hdr.p_align = 8;
    Elf64Phdr_Write(&hdr, fp);
}

void ElfSection_Write(Elf64Section *sect, FILE *fp)
{
     fwrite((void *)(&sect->bytes),1,sect->length,fp);
}

void Elf64File_Write(Elf64File *f, FILE *fp)
{
    int nn;

    Elf64File_WriteHeader(f, fp);
    fseek(fp, 512, SEEK_SET);
    for (nn = 0; nn < NumSections; nn++) {
        fseek(fp, sections[nn].sect.hdr.sh_offset, SEEK_SET);
        ElfSection_Write(&sections[nn].sect, fp);        
    }
    fseek(fp, f->hdr.e_shoff, SEEK_SET);
    Elf64File_WriteSectionHeaderTable(fp);
}

void Elf64File_WriteProgramHeaderTable(FILE *fp)
{
     fseek(fp, 160, SEEK_SET);
     Elf64File_WriteCodeSegmentHeader(fp);
     Elf64File_WriteDataSegmentHeader(fp);
     Elf64File_WriteBSSSegmentHeader(fp);
     Elf64File_WriteTLSSegmentHeader(fp);
}

