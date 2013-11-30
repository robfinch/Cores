
Public Class ELFFile
    Public hdr As Elf64Header

    Public Sub New()
        hdr = New Elf64Header
    End Sub

    Public Sub WriteHeader()
        Dim eh As New Elf64Header
        Dim byt As Byte
        Dim ui32 As UInt32
        Dim ui64 As UInt64
        Dim i32 As Integer

        ' Write ELF header
        byt = 127
        efs.Write(byt)
        byt = Asc("E")
        efs.Write(byt)
        byt = Asc("L")
        efs.Write(byt)
        byt = Asc("F")
        efs.Write(byt)
        byt = eh.ELFCLASS64 ' 64 bit file format
        efs.Write(byt)
        byt = eh.ELFDATA2LSB    ' little endian
        efs.Write(byt)
        byt = 1             ' header version, always 1
        efs.Write(byt)
        byt = 255           ' OS/ABI identification, 255 = standalone
        efs.Write(byt)
        efs.Write(byt)      ' OS/ABI version
        byt = 0
        efs.Write(byt)  ' reserved bytes
        efs.Write(byt)
        efs.Write(byt)
        efs.Write(byt)
        efs.Write(byt)
        efs.Write(byt)
        efs.Write(byt)
        efs.Write(Convert.ToUInt32(2))     ' type
        efs.Write(Convert.ToUInt32(64))    ' machine architecture
        efs.Write(UInt64.Parse("1"))        ' version
        ui64 = UInt64.Parse("0")            ' progam entry point
        efs.Write(ui64)
        efs.Write(Convert.ToUInt64(160))
        ui64 = UInt64.Parse(0)
        efs.Write(ui64)
        efs.Write(ui64)                     ' flags
        ui32 = UInt32.Parse(Elf64Header.Elf64HdrSz.ToString())  ' ehsize
        efs.Write(ui32)
        ui32 = UInt32.Parse("64")           ' phentsize
        efs.Write(ui32)
        efs.Write(Convert.ToUInt32(4))        ' number of program header entries
        efs.Write(UInt32.Parse("0"))        ' shentsize
        efs.Write(UInt32.Parse("0"))        ' number of section header entries
        efs.Write(UInt32.Parse("0"))        ' section string table index
    End Sub

    Sub WriteCodeSegmentHeader()
        Dim hdr As Elf64Phdr

        hdr.p_type = 1  ' Loadable Code
        hdr.p_flags = 1 ' execute only
        hdr.p_offset = 512  ' offset of segment in file
        hdr.p_vaddr = 4096  ' virtual address
        hdr.p_paddr = 0     ' physical address (not used)
        hdr.p_filesz = cbindex * 8  ' size of segment in file
        hdr.p_memsz = cbindex * 8   ' size of segment in memory
        hdr.p_align = 1     ' alignment of segment in memory
        hdr.Write()
    End Sub

    Sub WriteDataSegmentHeader()
        Dim hdr As Elf64Phdr

        hdr.p_type = 1  ' loadable code
        hdr.p_flags = 6 ' read/write only
        hdr.p_offset = 512 + cbindex * 8    ' offset of segment in file
        hdr.p_vaddr = 4096
        hdr.p_paddr = 0
        hdr.p_filesz = dbindex * 8
        hdr.p_memsz = dbindex * 8
        hdr.p_align = 8
        hdr.Write()
    End Sub

    Sub WriteBSSSegmentHeader()
        Dim hdr As Elf64Phdr

        hdr.p_type = 1
        hdr.p_flags = 6
        hdr.p_offset = 512 + cbindex * 8 + dbindex * 8
        hdr.p_vaddr = bssStart
        hdr.p_paddr = 0
        hdr.p_filesz = 0
        hdr.p_memsz = bssEnd - bssStart
        hdr.p_align = 8
        hdr.Write()
    End Sub

    Sub WriteTLSSegmentHeader()
        Dim hdr As Elf64Phdr

        hdr.p_type = 1
        hdr.p_flags = 6
        hdr.p_offset = 512 + cbindex * 8 + dbindex * 8
        hdr.p_vaddr = tlsStart
        hdr.p_paddr = 0
        hdr.p_filesz = 0
        hdr.p_memsz = tlsEnd - tlsStart
        hdr.p_align = 8
        hdr.Write()
    End Sub

    Sub WriteProgramHeaderTable()
        efs.Seek(160, IO.SeekOrigin.Begin)
        WriteCodeSegmentHeader()
        WriteDataSegmentHeader()
        WriteBSSSegmentHeader()
        WriteTLSSegmentHeader()
    End Sub

    Sub WriteSectionHeaderTable()
        Dim nn As Integer

        For nn = 0 To NumSections - 1
            ELFSections(nn).hdr.Write()
        Next
    End Sub

    Public Sub Write()
        Dim nn As Integer

        hdr.Write()
        'WriteProgramHeaderTable()
        efs.Seek(512, IO.SeekOrigin.Begin)
        For nn = 0 To NumSections - 1
            efs.Seek(ELFSections(nn).hdr.sh_offset, IO.SeekOrigin.Begin)
            ELFSections(nn).Write()
        Next
        efs.Seek(hdr.e_shoff, IO.SeekOrigin.Begin)
        WriteSectionHeaderTable()
    End Sub

End Class
