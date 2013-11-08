Public Class Elf64Header
    Public Const ELFCLASS32 = 1
    Public Const ELFCLASS64 = 2
    Public Const ELFDATA2LSB = 1
    Public Const ELFDATA2MSB = 2
    Public e_ident(16) As Char
    Public e_type As Int32
    Public e_machine As Int32
    Public e_version As Int64
    Public e_entry As Int64     ' program entry point
    Public e_phoff As Int64     ' offset in file to program header
    Public e_shoff As Int64     ' offset in file to section header
    Public e_flags As Int64
    Public e_ehsize As Int32    ' size of ELF header
    Public e_phentsize As Int32 ' size of program header entry
    Public e_phnum As Int32     ' umber of program header entries
    Public e_shentsize As Int32 ' size of section header entry
    Public e_shnum As Int32     ' number of section header entries
    Public e_shstrndx As Int32  ' section name string table index
    Public Const Elf64HdrSz = 128
End Class

Public Class Elf64Phdr
    Public p_type As Int64      ' type of segment
    Public p_flags As Int64     ' segment attributes
    Public p_offset As Int64    ' offset in file
    Public p_vaddr As Int64     ' virtual address
    Public p_paddr As Int64     ' reserved
    Public p_filesz As Int64    ' size of segment in file
    Public p_memsz As Int64     ' size of segment in memory
    Public p_align As Int64     ' alignment of segment
    Public Const Elf64pHdrSz = 64
End Class

Public Class Elf64Shdr
    Public sh_name As Int32
    Public sh_type As Int32
    Public sh_flags As Int64
    Public sh_addr As Int64
    Public sh_off As Int64
    Public sh_size As Int64
    Public sh_link As Int32
    Public sh_info As Int32
    Public sh_addralign As Int64
    Public sh_entsize As Int64
End Class

Public Class Elf64Symbol
    Public st_name As Int32
    Public st_info As Byte
    Public st_other As Byte
    Public st_shndx As Int16
    Public st_value As Int64
    Public st_size As Int64
End Class

Public Class Elf64rel
    Public r_offset As Int64
    Public r_info As Int64
End Class

Public Class Elf64rela
    Public r_offset As Int64
    Public r_info As Int64
    Public r_addend As Int64
End Class

Public Class ElfHeader
    Public magic(4) As Byte      ' \177ELF
    Public asize As Byte       ' 1=32 bit, 2=64 bit
    Public byteorder As Byte    ' 1=little endian, 2=big endian
    Public hversion As Byte    ' always 1
    Public pad(9) As Byte
    Public filetype As Int16   ' 1=relocatable, 2=executable, 3=shared object, 4=core image
    Public archtype As Int16   ' 2=SPARC, 3=x86 4=68k,
    Public fileversion As Int32    ' always 1
    Public entrypoint As Int32     ' entry point if executable
    Public phdrpos As Int32    ' file position of program header, or zero
    Public shdrpos As Int32    ' file position of section header, or zero
    Public flags As Int32      ' architecture specific flags, usually zero
    Public hdrsize As Int16    ' size of this ELF header
    Public phdrent As Int16    ' size of entry in program header
    Public phdrcnt As Int16    ' count of entries in program header or zero
    Public shdrent As Int16    ' size of entry in section header
    Public shdrcnt As Int16    ' count of entries in section header, or zero
    Public strsec As Int16     ' section number of section containing section name strings
End Class

Public Class ElfSectionHeader
    Public sh_name As Int32    ' name, index into string table
    Public sh_type As Int32
    Public sh_lfags As Int32
    Public sh_addr As Int32    ' base memory address if loadable, otherwise zero
    Public sh_offset As Int32  ' file position of beginning of section
    Public sh_size As Int32
    Public sh_link As Int32    ' section number with related info, or zero
    Public sh_info As Int32    ' more section specific info
    Public sh_align As Int32   ' alignment granularity if section is moved
    Public sh_entsize As Int32 ' size of entries if section is an array
End Class

Public Class ElfSymbol
    Public name As Int32       ' poistion of name in string table
    Public value As Int32
    Public size As Int32
    Public bindtype As Byte
    Public other As Byte
    Public sect As Int16       ' section number ABS, COMMON, or UNDEF
End Class

Public Class ElfProgramHeader
    Public type As Int32       ' loadable code or data, dynamic linking info, etc
    Public offset As Int32     ' file offset of segment
    Public virtaddr As Int32   ' virtual address to map segment
    Public physaddr As Int32   ' physical address (not used)
    Public filesize As Int32   ' size of segment in file
    Public memsize As Int32    ' size of segment in memory (bigger if it's BSS)
    Public flags As Int32      ' read/write/execute bits
    Public align As Int32      ' required alignment, invariably hardware page size
End Class
