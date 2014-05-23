Public Class Elf64Header
    Public Const ELFCLASS32 = 1
    Public Const ELFCLASS64 = 2
    Public Const ELFDATA2LSB = 1
    Public Const ELFDATA2MSB = 2
    Public e_ident(16) As Byte
    Public e_type As Int16
    Public e_machine As Int16
    Public e_version As Int32
    Public e_entry As Int64     ' program entry point
    Public e_phoff As Int64     ' offset in file to program header
    Public e_shoff As Int64     ' offset in file to section header
    Public e_flags As Int32
    Public e_ehsize As Int16    ' size of ELF header
    Public e_phentsize As Int16 ' size of program header entry
    Public e_phnum As Int16     ' umber of program header entries
    Public e_shentsize As Int16 ' size of section header entry
    Public e_shnum As Int16     ' number of section header entries
    Public e_shstrndx As Int16  ' section name string table index
    Public Const Elf64HdrSz = 64

    Public Sub Write()
        Dim nn As Integer

        For nn = 0 To 15
            efs.Write(e_ident(nn))
        Next
        efs.Write(e_type)
        efs.Write(e_machine)
        efs.Write(e_version)
        efs.Write(e_entry)
        efs.Write(e_phoff)
        efs.Write(e_shoff)
        efs.Write(e_flags)
        efs.Write(e_ehsize)
        efs.Write(e_phentsize)
        efs.Write(e_phnum)
        efs.Write(e_shentsize)
        efs.Write(e_shnum)
        efs.Write(e_shstrndx)
    End Sub
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

    Public Sub Write()
        efs.Write(p_type)
        efs.Write(p_flags)
        efs.Write(p_offset)
        efs.Write(p_vaddr)
        efs.Write(p_paddr)
        efs.Write(p_filesz)
        efs.Write(p_memsz)
        efs.Write(p_align)
    End Sub

End Class

Public Class Elf64Shdr
    Public Const SHT_PROGBITS = 1
    Public Const SHT_SYMTAB = 2
    Public Const SHT_STRTAB = 3
    Public Const SHF_WRITE = 1
    Public Const SHF_ALLOC = 2
    Public Const SHF_EXECINSTR = 4
    Public sh_name As Int32
    Public sh_type As Int32
    Public sh_flags As Int64
    Public sh_addr As Int64
    Public sh_offset As Int64
    Public sh_size As Int64
    Public sh_link As Int32
    Public sh_info As Int32
    Public sh_addralign As Int64
    Public sh_entsize As Int64
    Public Const Elf64ShdrSz = 64

    Public Sub Write()
        efs.Write(sh_name)
        efs.Write(sh_type)
        efs.Write(sh_flags)
        efs.Write(sh_addr)
        efs.Write(sh_offset)
        efs.Write(sh_size)
        efs.Write(sh_link)
        efs.Write(sh_info)
        efs.Write(sh_addralign)
        efs.Write(sh_entsize)
    End Sub

End Class

Public Class Elf64Symbol
    Public Const STB_GLOBAL = 1
    Public st_name As Int32
    Public st_info As Byte
    Public st_other As Byte
    Public st_shndx As Int16
    Public st_value As Int64
    Public st_size As Int64
    Public Sub Write()
        efs.Write(st_name)
        efs.Write(st_info)
        efs.Write(st_other)
        efs.Write(st_shndx)
        efs.Write(st_value)
        efs.Write(st_size)
    End Sub
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

Public Class ELFSection
    Public hdr As Elf64Shdr
    Public length As Integer
    Public bytes(10000000) As Byte

    Public Sub New()
        hdr = New Elf64Shdr
        length = 0
    End Sub

    Public Sub Add(ByVal byt As Byte)
        bytes(length) = byt
        length = length + 1
        hdr.sh_size = length
    End Sub

    Public Sub Add(ByVal wd As Int16)
        bytes(length) = wd And &HFF
        length = length + 1
        bytes(length) = (wd >> 8) And 255
        length = length + 1
        hdr.sh_size = length
    End Sub

    Public Sub Add(ByVal wd As Int32)
        bytes(length) = wd And &HFF
        length = length + 1
        bytes(length) = (wd >> 8) And 255
        length = length + 1
        bytes(length) = (wd >> 16) And 255
        length = length + 1
        bytes(length) = (wd >> 24) And 255
        length = length + 1
        hdr.sh_size = length
    End Sub

    Public Sub Add(ByVal wd As Int64)
        bytes(length) = wd And &HFF
        length = length + 1
        bytes(length) = (wd >> 8) And 255
        length = length + 1
        bytes(length) = (wd >> 16) And 255
        length = length + 1
        bytes(length) = (wd >> 24) And 255
        length = length + 1
        bytes(length) = (wd >> 32) And 255
        length = length + 1
        bytes(length) = (wd >> 40) And 255
        length = length + 1
        bytes(length) = (wd >> 48) And 255
        length = length + 1
        bytes(length) = (wd >> 56) And 255
        length = length + 1
        hdr.sh_size = length
    End Sub

    Public Sub Add(ByVal sym As Elf64Symbol)
        Add(sym.st_name)
        Add(sym.st_info)
        Add(sym.st_other)
        Add(sym.st_shndx)
        Add(sym.st_value)
        Add(sym.st_size)
    End Sub

    Public Sub Write()
        Dim nn As Int64

        For nn = 0 To length - 1
            efs.Write(bytes(nn))
        Next
    End Sub

End Class
