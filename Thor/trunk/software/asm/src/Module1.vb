Module Module1
    Dim textfile As String  ' the entire text of the file
    Dim segment As String
    Dim tls_address As Int64
    Dim bss_address As Int64
    Dim data_address As Int64
    Dim address As Int64    '
    Dim bytndx As Int64
    Dim slot As Integer
    Dim lines() As String   ' individual lines in the file
    Dim iline As String     ' copy of input line
    Dim line As String      ' line being worked on
    Dim strs() As String    ' parts of the line
    Dim operands() As String
    Dim lname As String
    Dim uname As String
    Dim bname As String
    Dim cname As String
    Dim dname As String
    Dim vname As String
    Dim elfname As String
    Dim ofl As System.IO.File
    Dim lfl As System.IO.File
    Dim ufl As System.IO.File
    Dim ofs As System.IO.TextWriter
    Dim lfs As System.IO.TextWriter
    Dim ufs As System.IO.TextWriter
    Dim bfs As System.IO.BinaryWriter
    Dim dfs As System.IO.BinaryWriter
    Dim cfs As System.IO.BinaryWriter
    Public efs As System.IO.BinaryWriter
    Dim opt64out As Boolean = False
    Dim opt32out As Boolean = True
    Dim pass As Integer
    Dim symbols As New Collection
    Dim localSymbols As New Collection
    Dim last_op As String
    Dim firstline As Boolean
    Dim estr As String
    Dim instname As String
    Dim w0 As Int64
    Dim w1 As Int64
    Dim w2 As Int64
    Dim w3 As Int64
    Dim dw0 As Int64
    Dim dw1 As Int64
    Dim dw2 As Int64
    Dim dw3 As Int64
    Dim optr26 As Boolean = True
    Dim maxpass As Integer = 10
    Dim dbi As Integer
    Dim cbi As Integer
    Dim fileno As Integer
    Dim nextFileno As Integer
    Dim isGlobal As Boolean

    Dim NameTable As New clsNameTable
    Dim sectionNameStringTable(1000) As Byte
    Dim sectionNameTableOffset As Int64
    Dim sectionNameTableSize As Int64
    Dim stringTable(1000000) As Byte
    Dim databytes(1000000) As Int64
    Public dbindex As Integer
    Dim codebytes(1000000) As Int64
    Public cbindex As Integer
    Dim bbindex As Integer
    Dim tbindex As Integer
    Dim codeStart As Int64
    Dim codeEnd As Int64
    Dim dataStart As Int64
    Dim dataEnd As Int64
    Public bssStart As Int64
    Public bssEnd As Int64
    Public tlsStart As Int64
    Public tlsEnd As Int64
    Dim publicFlag As Boolean
    Dim currentFl As textfile
    Dim predicateByte As Int64
    Dim processedPredicate As Boolean
    Dim processedEquate As Boolean
    Dim bytesbuf(10000000) As Int64
    Dim bytn As Int64
    Dim sa As Int64
    Dim dsa As Int64
    Dim plbl As Boolean
    Public NumSections As Integer
    Public ELFSections(10) As ELFSection
    Public SearchList As Collection
    Public TextSnippets As Collection

    Sub Main(ByVal args() As String)
        Dim s As String
        Dim rdr As System.IO.TextReader
        Dim L As Symbol
        Dim M As Symbol
        Dim Ptch As LabelPatch
        Dim delimiters As String = " ," & vbTab
        Dim p() As Char = delimiters.ToCharArray()
        Dim n As Integer
        Dim bfss As System.IO.FileStream
        Dim cfss As System.IO.FileStream
        Dim dfss As System.IO.FileStream
        Dim efss As System.io.FileStream
        Dim nm As String
        Dim sftext As String
        Dim sftext2 As String
        Dim nn As Integer
        Dim en As Integer
        Dim snam As String
        Dim foundAllSyms As Boolean
        Dim iteration As Integer

        'textfile = fl.ReadToEnd()
        'fl.Close()
        'currentFl = fl

        If args.Length < 1 Then
            Console.WriteLine("Thorasm v1.0")
            Console.WriteLine("Usage: Thorasm <input file> [<rom mem file>]")
            Return
        End If
        NumSections = 0

        SearchList = New Collection
        TextSnippets = New Collection
        Dim fl As New TextFile(args(0))
        instname = "ubr/ram"
        lname = args(0)
        If lname.EndsWith(".atf") Then
            lname = lname.Replace(".atf", ".lst")
        Else
            lname = lname.Replace(".s", ".lst")
        End If
        lname = lname.Replace(".asm", ".lst")
        uname = lname.Replace(".lst", ".ucf")
        bname = lname.Replace(".lst", ".bin")
        cname = lname.Replace(".lst", ".binc")
        dname = lname.Replace(".lst", ".bind")
        elfname = lname.Replace(".lst", ".elf")
        'textfile = textfile.Replace(vbLf, " ")
        'lines = textfile.Split(vbCr.ToCharArray())
        For pass = 0 To maxpass
            fileno = 0
            nextFileno = 0
            codeStart = 512
            dataStart = 512 + codeEnd
            tls_address = bss_address
            bss_address = data_address
            data_address = address
            tlsStart = bssEnd
            bssStart = dataEnd
            dbindex = 0
            cbindex = 0
            bbindex = 0
            address = 0
            slot = 0
            bytndx = 0
            last_op = ""
            If pass = maxpass Then
                If (args.Length > 1) Then
                    vname = args(1)
                Else
                    vname = lname.Replace(".lst", ".ver")
                End If
                ofs = ofl.CreateText(vname)
                lfs = lfl.CreateText(lname)
                ufs = ufl.CreateText(uname)
                bfss = New System.IO.FileStream(bname, IO.FileMode.Create)
                bfs = New System.IO.BinaryWriter(bfss)
                'cfss = New System.IO.FileStream(cname, IO.FileMode.Create)
                'cfs = New System.IO.BinaryWriter(cfss)
                'dfss = New System.IO.FileStream(dname, IO.FileMode.Create)
                'dfs = New System.IO.BinaryWriter(dfss)
                efss = New System.IO.FileStream(elfname, IO.FileMode.Create)
                efs = New System.IO.BinaryWriter(efss)
            End If
            ProcessFile(args(0))
            If pass > 1 Then
                For Each lines In TextSnippets
                    ProcessText()
                Next
            End If

            ' flush instruction holding bundle
            While (address Mod 4)
                emitbyte(0, False)
            End While
            emitbyte(0, False)
            emitbyte(0, False)
            emitbyte(0, False)
            emitbyte(0, False)
            If pass = maxpass Then
                DumpSymbols()
                ufs.Close()
                lfs.Close()
                ofs.Close()
                WriteELFFile()
                WriteBinaryFile()
            End If
            If pass = 1 Then
                ' Note that finding a symbol in the searched source code
                ' libraries may introduce new symbols that aren't defined
                ' yet. So we have to loop back and process for those as
                ' well. We keep looping until all the undefined references
                ' are defined, or we've looped too many times. (There could
                ' be a genuine missing symbol).
                iteration = 0
j1:
                foundAllSyms = True
                For Each L In symbols
                    If L.defined = False Then
                        foundAllSyms = False
                        ' "Promote" an undefined symbol to the global level.
                        ' It's either an external reference or an error.
                        symbols.Remove(NameTable.GetName(L.name))
                        snam = "0" & TrimLeadingDigits(NameTable.GetName(L.name))
                        Try
                            M = symbols.Item(snam)
                        Catch
                            M = Nothing
                        End Try
                        If M Is Nothing Then
                            L.name = NameTable.AddName(snam)
                            symbols.Add(L, snam)
                        End If
                        For Each nm In SearchList
                            Try
                                Dim sf As New TextFile(nm)
                                sftext = CompressSpaces(sf.ReadToEnd())
                                snam = NameTable.GetName(L.name)
                                snam = TrimLeadingDigits(NameTable.GetName(L.name))
                                nn = sftext.IndexOf("public code " & snam & ":")
                                If nn < 0 Then
                                    nn = sftext.IndexOf("public data " & snam & ":")
                                    If nn < 0 Then
                                        nn = sftext.IndexOf("public bss " & snam & ":")
                                        If nn < 0 Then
                                            nn = sftext.IndexOf("public tls " & snam & ":")
                                        End If
                                    End If
                                End If
                                If nn >= 0 Then
                                    en = sftext.IndexOf("endpublic", nn) + 9
                                    If en >= 9 Then
                                        sftext2 = sftext.Substring(nn, en - nn)
                                        sftext2 = sftext2.Replace(vbLf, "")
                                        lines = sftext2.Split(vbCr.ToCharArray())
                                        TextSnippets.Add(lines)
                                        ProcessText()
                                    End If
                                End If
                            Catch
                            End Try
                        Next
                    End If
                Next
                iteration = iteration + 1
                If Not foundAllSyms And iteration < 100 Then GoTo j1
            End If
            'For Each L In symbols
            '    If L.defined = False Then
            '        Console.WriteLine("Undefined label: |" & NameTable.GetName(L.name) & "|")
            '    End If
            'Next
        Next
    End Sub

    Function TrimLeadingDigits(ByVal str As String) As String
        Dim ch As String

        If str.Length > 0 Then
            ch = Left(str, 1)
            If ch >= "0" And ch <= "9" Then
                str = str.Substring(1)
                str = TrimLeadingDigits(str)
            End If
        End If
        Return str
    End Function

    Sub ProcessText()
        Dim s As String
        Dim n As Integer
        Dim bb1 As Int64
        Dim xx As Int64

        For Each iline In lines
            publicFlag = False
            firstline = True
            line = iline
            line = line.Replace(vbTab, " ")
            n = line.IndexOf(";")
            If n = 0 Then
                line = ""
            ElseIf n > 0 Then
                line = line.Substring(0, n)
            End If
            line = line.Trim()
            line = CompressSpaces(line)
            If line.Length = 0 Then
                emitEmptyLine(iline)
            End If
            processedPredicate = False
            processedEquate = False
            bytn = 0
            sa = address
            dsa = data_address
            plbl = False
            If line.Length <> 0 Then
                '                    strs = line.Split(p)
                strs = SplitLine(line)
                If True Then
j1:
                    s = strs(0)
                    s = s.Trim()
                    If s.EndsWith(":") Then
                        ProcessLabel(s)
                        plbl = True
                    Else
                        If Not processedPredicate Then
                            If GetPnRegister(s) >= 0 Then
                                predicateByte = GetPnRegister(s) << 4
                                processCond(s)
                                For n = 1 To strs.Length - 1
                                    strs(n - 1) = strs(n)
                                Next
                                strs(strs.Length - 1) = Nothing
                                processedPredicate = True
                                If Not strs(0) Is Nothing Then GoTo j1
                                GoTo j2
                            Else
                                predicateByte = 1
                            End If
                            processedPredicate = True
                        End If
                        ' flush constant buffers
                        If s <> "db" And last_op = "db" Then
                            'emitbyte(0, True)
                        End If
                        If s <> "dc" And last_op = "dc" Then
                            'emitchar(0, True)
                        End If
                        ' no need to flush word buffer
                        If s <> "fill.b" And last_op = "fill.b" Then
                            emitbyte(0, True)
                        End If
                        If s <> "fill.c" And last_op = "fill.c" Then
                            emitchar(0, True)
                        End If
                        If s <> "fill.h" And last_op = "fill.h" Then
                            '                                emithalf(0, True)
                        End If

                        Select Case LCase(s)
                            Case "code"
                                segment = "code"
                                emitRaw("")
                                GoTo j3
                            Case "bss"
                                segment = "bss"
                                emitRaw("")
                                GoTo j3
                            Case "tls"
                                segment = "tls"
                                emitRaw("")
                                GoTo j3
                            Case "data"
                                segment = "data"
                                emitRaw("")
                                GoTo j3
                            Case "org"
                                ProcessOrg()
                                GoTo j3

                                ' RI ops
                            Case "ldi"
                                ProcessLdi(s, &H6F)
                            Case "ldis"
                                ProcessLdis(s, &H9D)
                            Case "addi"
                                ProcessRIOp(s, &H48)
                            Case "addui"
                                ProcessRIOp(s, &H4C)
                            Case "subi"
                                ProcessRIOp(s, &H49)
                            Case "subui"
                                ProcessRIOp(s, &H4D)
                            Case "cmpi"
                                ProcessCmpIOp(s, &H20)
                            Case "andi"
                                ProcessRIOp(s, &H53)
                            Case "ori"
                                ProcessRIOp(s, &H54)
                            Case "eori"
                                ProcessRIOp(s, &H55)
                            Case "mului"
                                ProcessRIOp(s, &H4E)
                            Case "muli"
                                ProcessRIOp(s, &H4A)
                            Case "divui"
                                ProcessRIOp(s, &H4F)
                            Case "divi"
                                ProcessRIOp(s, &H4B)

                            Case "cas"
                                ProcessCas(s, &H97)
                            Case "lvb"
                                ProcessMemoryOp(s, &HD0)
                            Case "lvc"
                                ProcessMemoryOp(s, &HD1)
                            Case "lvh"
                                ProcessMemoryOp(s, &HD2)
                            Case "lww"
                                ProcessMemoryOp(s, &HD3)

                            Case "lb"
                                ProcessMemoryOp(s, &H80)
                            Case "lbu"
                                ProcessMemoryOp(s, &H81)
                            Case "lc"
                                ProcessMemoryOp(s, &H82)
                            Case "lcu"
                                ProcessMemoryOp(s, &H83)
                            Case "lh"
                                ProcessMemoryOp(s, &H84)
                            Case "lhu"
                                ProcessMemoryOp(s, &H85)
                            Case "lw"
                                ProcessMemoryOp(s, &H86)
                            Case "lws"
                                ProcessLws(s, &H8E)
                            Case "lwr"
                                ProcessMemoryOp(s, 46)
                            Case "sb"
                                ProcessMemoryOp(s, &H90)
                            Case "sc"
                                ProcessMemoryOp(s, &H91)
                            Case "sh"
                                ProcessMemoryOp(s, &H92)
                            Case "sw"
                                ProcessMemoryOp(s, &H93)
                            Case "sws"
                                ProcessLws(s, &H9E)
                            Case "stp"
                                ProcessMemoryOp(s, 52)
                            Case "swc"
                                ProcessMemoryOp(s, 62)
                            Case "lea"
                                ProcessMemoryOp(s, &H4C)
                            Case "stbc"
                                ProcessMemoryOp(s, 54)
                            Case "sti"
                                ProcessSti(s, &H96)
                            Case "memdb"
                                emitOpcode(&HF9)
                            Case "memsb"
                                emitOpcode(&HF8)

                                ' RR branches
                            Case "bra"
                                ProcessBra(s, &H30)
                            Case "br"
                                ProcessBra(s, &H30)
                            Case "brn"
                                ProcessBra(s, 11)
                            Case "bnr"
                                ProcessBra(s, 14)
                            Case "loop"
                                ProcessLoop(s, &HA4)

                                ' R
                            Case "com"
                                ProcessROp(s, 4)
                            Case "not"
                                ProcessROp(s, &H71)
                            Case "neg"
                                ProcessROp(s, &H70)
                            Case "abs"
                                ProcessROp(s, 7)
                            Case "sgn"
                                ProcessROp(s, 8)
                            Case "mov"
                                ProcessROp(s, &HA7)
                            Case "swap"
                                ProcessROp(s, 13)
                            Case "ctlz"
                                ProcessROp(s, 16)
                            Case "ctlo"
                                ProcessROp(s, 17)
                            Case "ctpop"
                                ProcessROp(s, 18)
                            Case "sext8"
                                ProcessROp(s, 20)
                            Case "sext16"
                                ProcessROp(s, 21)
                            Case "sext32"
                                ProcessROp(s, 22)
                            Case "sqrt"
                                ProcessROp(s, 24)

                                ' RR
                            Case "add"
                                ProcessRROp(s, &H40)
                            Case "addu"
                                ProcessRROp(s, &H44)
                            Case "sub"
                                ProcessRROp(s, &H41)
                            Case "subu"
                                ProcessRROp(s, &H45)
                            Case "cmp"
                                ProcessCmpRROp(s, &H10)
                            Case "and"
                                ProcessRROp(s, &H50)
                            Case "nand"
                                ProcessRROp(s, &H66)
                            Case "or"
                                ProcessRROp(s, &H51)
                            Case "eor"
                                ProcessRROp(s, &H52)
                                'Case "min"
                                '    ProcessRROp(s, 20)
                                'Case "max"
                                '    ProcessRROp(s, 21)
                            Case "mulu"
                                ProcessRROp(s, &H46)
                            Case "mul"
                                ProcessRROp(s, &H42)
                            Case "divu"
                                ProcessRROp(s, &H47)
                            Case "div"
                                ProcessRROp(s, &H43)
                                'Case "modu"
                                '    ProcessRROp(s, 28)
                                'Case "mods"
                                '    ProcessRROp(s, 29)
                            Case "tst"
                                ProcessTst(s, &H0)

                            Case "shli"
                                ProcessShiftiOp(s, &H5E)
                            Case "shlui"
                                ProcessShiftiOp(s, &H60)
                            Case "shrui"
                                ProcessShiftiOp(s, &H61)
                            Case "roli"
                                ProcessShiftiOp(s, &H62)
                            Case "shri"
                                ProcessShiftiOp(s, &H5F)
                            Case "rori"
                                ProcessShiftiOp(s, &H63)

                            Case "bfins"
                                ProcessBitfieldOp(s, &H0)
                            Case "bfset"
                                ProcessBitfieldOp(s, &H1)
                            Case "bfclr"
                                ProcessBitfieldOp(s, &H2)
                            Case "bfchg"
                                ProcessBitfieldOp(s, &H3)
                            Case "bfext"
                                ProcessBitfieldOp(s, &H5)
                            Case "bfextu"
                                ProcessBitfieldOp(s, &H4)
                            Case "bfexts"
                                ProcessBitfieldOp(s, &H5)

                            Case "jmp"
                                ProcessJmp(s, &HA2)
                            Case "jsr"
                                ProcessJsr(s, &HA2)
                            Case "rts"
                                ProcessRtsOp(s, &HA3)
                            Case "sys"
                                ProcessSys(s, &HA5)
                            Case "rti"
                                ProcessRti(&HF4)
                            Case "rte"
                                ProcessRti(&HF3)

                            Case "nop"
                                ProcessNop(s, &H10)
                            Case "lm"
                                ProcessPush(78)
                            Case "sm"
                                ProcessPush(79)
                            Case "mfspr"
                                ProcessMfspr()
                            Case "mtspr"
                                ProcessMtspr()
                            Case "mfseg"
                                ProcessMfseg()
                            Case "mtseg"
                                ProcessMtseg()
                            Case "mfsegi"
                                ProcessMfsegi()
                            Case "mtsegi"
                                ProcessMtsegi()

                            Case "omg"
                                ProcessOMG(50)
                            Case "cmg"
                                ProcessCMG(51)
                            Case "omgi"
                                ProcessOMG(52)
                            Case "cmgi"
                                ProcessCMG(53)

                            Case "gran"
                                emit(80)
                            Case "cli"
                                processCLI(&HFA)
                            Case "sei"
                                processCLI(&HFB)
                            Case "icache_on"
                                processICacheOn(10)
                            Case "icache_off"
                                processICacheOn(11)
                            Case "dcache_on"
                                processICacheOn(12)
                            Case "dcache_off"
                                processICacheOn(13)
                            Case "tlbdis"
                                ProcessTLBWR(&H6F0)
                            Case "tlben"
                                ProcessTLBWR(&H5F0)
                            Case "tlbpb"
                                ProcessTLBWR(&H1F0)
                            Case "tlbrd"
                                ProcessTLBWR(&H2F0)
                            Case "tlbwr"
                                ProcessTLBWR(&H3F0)
                            Case "tlbwi"
                                ProcessTLBWR(&H4F0)
                            Case "tlbrdreg"
                                ProcessTLBRDREG(&H7F0)
                            Case "tlbwrreg"
                                ProcessTLBWRREG(&H8F0)
                            Case "sync"
                                emitOpcode(&HF8)
                            Case "iepp"
                                emit(15)
                            Case "fip"
                                emit(20)
                            Case "wait"
                                emit(40)
                            Case "align"
                                ProcessAlign()
                            Case ".align"
                                ProcessAlign()
                            Case "db"
                                ProcessDB()
                            Case "dc"
                                ProcessDC()
                            Case "dh"
                                ProcessDH()
                            Case "dw"
                                ProcessDW()
                            Case "fill.b"
                                ProcessFill(s)
                            Case "dcb.b"
                                ProcessFill("fill.b")
                            Case "fill.c"
                                ProcessFill(s)
                            Case "fill.w"
                                ProcessFill(s)
                            Case "extern"
                                ' do nothing
                            Case "public"
                                publicFlag = True
                                If (strs.Length < 2) Then
                                    Console.WriteLine("Malformed public directive")
                                Else
                                    For n = 2 To strs.Length - 1
                                        strs(n - 2) = strs(n)
                                    Next
                                    strs(strs.Length - 1) = Nothing
                                    strs(strs.Length - 2) = Nothing
                                    If Not strs(0) Is Nothing Then GoTo j1
                                    segment = strs(1)
                                End If
                            Case "endpublic"
                                ' do nothing
                            Case "include", ".include"
                                isGlobal = False
                                nextFileno = nextFileno + 1
                                fileno = nextFileno
                                ProcessFile(strs(1))
                                isGlobal = True
                                fileno = 0
                            Case "search", ".search"
                                If pass = 1 Then
                                    SearchList.Add(strs(1).TrimEnd("""".ToCharArray).TrimStart("""".ToCharArray))
                                End If
                            Case Else
                                If Not ProcessEquate() Then
                                    ProcessLabel(s)
                                    plbl = True
                                    For n = 1 To strs.Length - 1
                                        strs(n - 1) = strs(n)
                                    Next
                                    strs(strs.Length - 1) = Nothing
                                    If Not strs(0) Is Nothing Then GoTo j1
                                    '                                        Console.WriteLine("Unknown instruction: " & s)
                                End If
                        End Select
                        last_op = s
                    End If
                End If
j2:
                If Not processedEquate Then
                    WriteListing()
                End If
j3:
            End If
        Next
    End Sub

    Sub ProcessFile(ByVal fname As String)
        fname = fname.Trim("""".ToCharArray)
        Dim fl As New TextFile(fname)

        fl.ReadToEnd()
        currentFl = fl
        lines = currentFl.lines
        ProcessText()
    End Sub

    Sub WriteListing()
        Dim xx As Integer

        If pass = maxpass And Not plbl Then
            If segment = "data" Then
                lfs.Write(Hex(dsa).PadLeft(8, "0") & vbTab)
            Else
                lfs.Write(Hex(sa).PadLeft(8, "0") & vbTab)
            End If
            For xx = 1 To bytn
                lfs.Write(Right(Hex(bytesbuf(xx - 1)).PadLeft(2, "0"), 2))
            Next
            If bytn < 9 Then
                lfs.WriteLine(Space(16 - bytn * 2) & iline)
            Else
                lfs.WriteLine(Space(1) & iline)
            End If
            sa = sa + bytn
        End If
    End Sub

    Sub DumpSymbols()
        Dim sym As Symbol

        lfs.WriteLine(" ")
        lfs.WriteLine(" ")
        lfs.WriteLine("Symbol Table:")
        lfs.WriteLine("================================================================")
        lfs.WriteLine("Name                   Typ  Segment     Scope   Address/Value")
        lfs.WriteLine("----------------------------------------------------------------")
        For Each sym In symbols
            If sym.type = "L" Then
                If sym.segment = "code" Then
                    lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & sym.segment.PadRight(8) & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                Else
                    If sym.defined Then
                        lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & sym.segment.PadRight(8) & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                    Else
                        lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & "undef" & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                    End If
                End If
            Else
                lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & sym.segment.PadRight(8) & vbTab & "      " & vbTab & Hex(sym.value).PadLeft(16, "0"))
            End If
        Next
    End Sub

    Sub ProcessFill(ByVal s As String)
        Dim numbytes As Int64
        Dim FillByte As Int64
        Dim n As Int64

        Select Case s
            Case "fill.b"
                numbytes = GetImmediate(strs(1), "fill.b")
                FillByte = GetImmediate(strs(2), "fill.b")
                For n = 0 To numbytes - 1
                    emitbyte(FillByte, False)
                Next
                ' emitbyte(0, True)
            Case "fill.c"
                numbytes = GetImmediate(strs(1), "fill.c")
                FillByte = GetImmediate(strs(2), "fill.c")
                For n = 0 To numbytes - 1
                    emitchar(FillByte, False)
                Next
                'emitchar(0, True)
            Case "fill.w"
                numbytes = GetImmediate(strs(1), "fill.w")
                FillByte = GetImmediate(strs(2), "fill.w")
                For n = 0 To numbytes - 1
                    emitword(FillByte, False)
                Next
                'emitword(0, True)
        End Select
    End Sub

    Sub processCLI(ByVal oc As Int64)
        emitOpcode(oc)
    End Sub

    Sub ProcessPush(ByVal s As String, ByVal oc As Int64)

    End Sub

    Sub ProcessPush(ByVal oc As Int64)
        Dim opcode As Int64
        Dim s As String()
        Dim n As Integer
        Dim ra As Int64
        Dim r As Int64
        Dim offset As Int64

        opcode = oc << 35
        If strs(1).StartsWith("[") Then
            strs(1) = strs(1).TrimStart("[".ToCharArray)
            strs(1) = strs(1).TrimEnd("]".ToCharArray)
        End If
        ra = GetRegister(strs(1))
        opcode = opcode Or ((ra And 15) << 31)
        s = Split(strs(2), "/")
        For n = 0 To s.Length - 1
            r = GetRegister(s(n))
            opcode = opcode Or (1L << (r - 1))
        Next
        emit(opcode)
    End Sub

    Function SplitLine(ByVal s As String) As String()
        Dim ss() As String
        Dim n As Integer
        Dim i As Integer
        Dim inQuote As Char


        i = 0
        If s = "TAB5_1" Then
            i = 0
        End If
        inQuote = "?"
        ReDim ss(1)
        For n = 1 To s.Length
            If inQuote <> "?" Then
                ss(i) = ss(i) & Mid(s, n, 1)
                If Mid(s, n, 1) = inQuote Then
                    inQuote = "?"
                End If
            ElseIf Mid(s, n, 1) = "," Then
                i = i + 1
                ReDim Preserve ss(ss.Length + 1)
            ElseIf Mid(s, n, 1) = " " Then
                i = i + 1
                ReDim Preserve ss(ss.Length + 1)
            ElseIf Mid(s, n, 1) = "'" Then
                ss(i) = ss(i) & Mid(s, n, 1)
                inQuote = Mid(s, n, 1)
            ElseIf Mid(s, n, 1) = Chr(34) Then
                ss(i) = ss(i) & Mid(s, n, 1)
                inQuote = Mid(s, n, 1)
            Else
                ss(i) = ss(i) & Mid(s, n, 1)
            End If
        Next
        Return ss
    End Function

    Sub ProcessLabel(ByVal s As String)
        Dim L As New Symbol
        Dim M As Symbol
        Dim nm As String

        s = s.TrimEnd(":")
        nm = s
        L.segment = segment
        L.fileno = fileno
        If publicFlag Then
            L.scope = "Pub"
            L.fileno = 0
        End If
        '        L.name = CStr(L.fileno) & L.name
        Select Case segment
            Case "code"
                L.address = address
                'L.address = (L.address And &HFFFFFFFFFFFFFFF0L) Or (slot << 2)
            Case "bss"
                L.address = bss_address
            Case "tls"
                L.address = tls_address
            Case "data"
                L.address = data_address
        End Select
        L.defined = True
        L.type = "L"
        If symbols.Count > 0 Then
            Try
                M = symbols.Item(fileno & s)
            Catch
                Try
                    M = symbols.Item("0" & s)
                Catch
                    M = Nothing
                End Try
            End Try
        Else
            M = Nothing
        End If
        If publicFlag Then
            nm = "0" & nm
        Else
            nm = fileno & nm
        End If
        If pass = 2 And M Is Nothing Then
            Console.WriteLine("missed symbol: " & nm)
        End If
        If M Is Nothing Then
            If nm = "0printf" Then
                Console.WriteLine("L7")
            End If
            L.name = NameTable.AddName(nm)
            symbols.Add(L, nm)
        Else
            M.defined = True
            M.type = "L"
            M.address = L.address
            M.segment = L.segment
        End If
        If strs(1) Is Nothing Then
            emitLabel(nm)
        End If
    End Sub

    Sub processICacheOn(ByVal n As Int64)
        Dim opcode As Int64

        opcode = 0L << 25
        opcode = opcode Or n
        emit(opcode)
    End Sub

    Sub ProcessSETLO()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 112L << 25
        Rt = GetRegister(strs(1))
        '        n = GetImmediate(strs(2), "setlo")
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &H3FFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessSETMID()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 116L << 25
        Rt = GetRegister(strs(1))
        '        n = GetImmediate(strs(2), "setlo")
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &H3FFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessSETHI()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 120L << 25
        Rt = GetRegister(strs(1))
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &HFFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessAlign()
        Dim n As Int64

        n = GetImmediate(strs(1), "align")
        If (n Mod 16 = 0) Then
            If segment = "tls" Then
                While tls_address Mod 16
                    tls_address = tls_address + 1
                End While
            ElseIf segment = "bss" Then
                While bss_address Mod 16
                    bss_address = bss_address + 1
                End While
            Else
                'If last_op = "db" Then
                '    emitbyte(0, True)
                'ElseIf last_op = "dc" Then
                '    emitchar(0, True)
                '    '                ElseIf last_op = "dh" Then
                '    '                   emithalf(0, True)
                'ElseIf last_op = "dw" Then
                '    emitword(0, True)
                'Else
                While slot <> 0
                    '                    slot = (slot + 1) Mod 3
                    emit(&H37800000000L)    ' nop
                End While
                'End If
                While address Mod n
                    emitbyte(&H10L, False)
                End While
                slot = 0
            End If
            bytndx = 0
        Else
            'FlushConstants()
            If segment = "tls" Then
                While tls_address Mod n
                    tls_address = tls_address + 1
                End While
            ElseIf segment = "bss" Then
                While bss_address Mod n
                    bss_address = bss_address + 1
                End While
            ElseIf segment = "code" Then
                'Console.WriteLine("Error: Code addresses can only be aligned on 16 byte boundaries.")
                While address Mod n
                    emitbyte(0, False)
                    'address = address + 1
                End While
            ElseIf segment = "data" Then
                While data_address Mod n
                    emitbyte(0, False)
                    'address = address + 1
                End While
            Else
                While address Mod n
                    emitbyte(0, False)
                    'address = address + 1
                End While
            End If
        End If
        emitRaw("")
    End Sub

    Sub ProcessTLBWR(ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        emitOpcode(oc)
        emitbyte(oc >> 8, False)
        emitbyte(0, False)
    End Sub

    Sub ProcessTLBRDREG(ByVal oc As Int64)
        Dim opcode As Int64
        Dim Rt As Int64
        Dim Tn As Int64

        Rt = GetRegister(strs(1))
        Tn = GetTLBRegister(strs(2))
        emitOpcode(oc)
        emitbyte((oc >> 8) Or (Tn << 4), False)
        emitbyte(Rt, False)
    End Sub

    Sub ProcessTLBWRREG(ByVal oc As Int64)
        Dim opcode As Int64
        Dim Rb As Int64
        Dim Tn As Int64

        Tn = GetTLBRegister(strs(1))
        Rb = GetRegister(strs(2))
        emitOpcode(oc)
        emitbyte((oc >> 8) Or (Tn << 4), False)
        emitbyte(Rb, False)
    End Sub

    Sub ProcessTst(ByVal s As String, ByVal oc As Int64)
        Dim pt As Integer
        Dim ra As Integer

        pt = GetPnRegister(strs(1))
        ra = GetRegister(strs(2))
        emitOpcode(oc Or pt)
        emitbyte(ra, False)
    End Sub

    Sub ProcessMtspr()
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSPRRegister(strs(1))
        ra = GetRegister(strs(2))
        emitOpcode(&HA9)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    Sub ProcessMfspr()
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetSPRRegister(strs(2))
        emitOpcode(&HA8)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    Sub ProcessMtseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSPRRegister(strs(1))
        ra = GetRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 43
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 6)
        emit(opcode)
    End Sub

    Sub ProcessMfseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetSPRRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 42
        opcode = opcode Or (ra << 6)
        opcode = opcode Or (rt << 15)
        emit(opcode)

    End Sub

    Sub ProcessMfsegi()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 44
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 15)
        emit(opcode)
    End Sub

    Sub ProcessMtsegi()
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64

        ra = GetRegister(strs(1))
        rb = GetRegister(strs(2))
        opcode = 2L << 25
        opcode = opcode Or 35
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        emit(opcode)
    End Sub

    Sub ProcessDB()
        Dim n As Integer
        Dim m As Integer
        Dim k As Int64
        Dim ch As Char

        For m = 1 To strs.Length - 1
            n = 1
            While n <= Len(strs(m))
                If Mid(strs(m), n, 1) = Chr(34) Then
                    n = n + 1
                    While Mid(strs(m), n, 1) <> Chr(34) And n <= Len(strs(m))
                        ch = Mid(strs(m), n, 1)
                        emitbyte(Asc(ch), False)
                        n = n + 1
                    End While
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "," Then
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "'" Then
                    k = eval(strs(m))
                    emitbyte(k, False)
                    '                    emitbyte(Asc(Mid(strs(m), n + 1)), False)
                    '                   n = n + 2
                    Exit While
                Else
                    emitbyte(GetImmediate(Mid(strs(m), n), "db"), False)
                    n = Len(strs(m))
                End If
                If n = Len(strs(m)) Then Exit While
            End While
        Next
        'emitbyte(0, True)
    End Sub

    Sub ProcessDC()
        Dim n As Integer
        Dim m As Integer
        Dim i As Int64

        For m = 1 To strs.Length - 1
            n = 1
            If Not strs(m) Is Nothing Then
                While n <= Len(strs(m))
                    If Mid(strs(m), n, 1) = Chr(34) Then
                        n = n + 1
                        While Mid(strs(m), n, 1) <> Chr(34) And n <= Len(strs(m))
                            '                            emitchar(Asc(Mid(strs(m), n, 1)), False)
                            emitbyte(Asc(Mid(strs(m), n, 1)), False)
                            emitbyte(0, False)
                            n = n + 1
                        End While
                        n = n + 1
                    ElseIf Mid(strs(m), n, 1) = "," Then
                        n = n + 1
                    ElseIf Mid(strs(m), n, 1) = "'" Then
                        'emitchar(Asc(Mid(strs(m), n + 1)), False)
                        emitbyte(Asc(Mid(strs(m), n + 1)), False)
                        emitbyte(0, False)
                        n = n + 2
                    Else
                        i = eval(strs(m))
                        emitbyte(i, False)
                        emitbyte(i >> 8, False)
                        'emitchar(GetImmediate(Mid(strs(m), n), "dc"), False)
                        n = Len(strs(m))
                    End If
                    If n = Len(strs(m)) Then Exit While
                End While
            End If
        Next
        'emitbyte(0, True)
    End Sub

    Sub ProcessDH()
        Dim n As Integer
        Dim m As Integer

        For m = 1 To strs.Length - 1
            n = 1
            While n <= Len(strs(m))
                If Mid(strs(m), n, 1) = Chr(34) Then
                    n = n + 1
                    While Mid(strs(m), n, 1) <> Chr(34) And n <= Len(strs(m))
                        emithalf(Asc(Mid(strs(m), n, 1)), False)
                        n = n + 1
                    End While
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "," Then
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "'" Then
                    emithalf(Asc(Mid(strs(m), n + 1)), False)
                    n = n + 2
                Else
                    emithalf(GetImmediate(Mid(strs(m), n), "dc"), False)
                    n = Len(strs(m))
                End If
                If n = Len(strs(m)) Then Exit While
            End While
        Next
        'emitbyte(0, True)
    End Sub

    Sub ProcessDW()
        Dim n As Integer
        Dim m As Integer

        For m = 1 To strs.Length - 1
            n = 1
            While n <= Len(strs(m))
                If Mid(strs(m), n, 1) = Chr(34) Then
                    n = n + 1
                    While Mid(strs(m), n, 1) <> Chr(34) And n <= Len(strs(m))
                        emitword(Asc(Mid(strs(m), n, 1)), False)
                        n = n + 1
                    End While
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "," Then
                    n = n + 1
                ElseIf Mid(strs(m), n, 1) = "'" Then
                    emitword(Asc(Mid(strs(m), n + 1)), False)
                    n = n + 2
                Else
                    emitword(GetImmediate(Mid(strs(m), n), "dw"), False)
                    Exit While
                End If
            End While
        Next
        'emitbyte(0, True)
    End Sub

    ' iret and eret
    Sub ProcessIRet(ByVal oc As Int64)
        Dim opcode As Int64

        opcode = 0L << 25
        opcode = opcode Or oc
        emit(opcode)
    End Sub

    ' rti and rte
    Sub ProcessRti(ByVal oc As Int64)
        emitOpcode(oc)
    End Sub

    Function bit(ByVal v As Int64, ByVal b As Int64) As Integer
        Dim i As Int64

        i = (v >> b) And 1L
        Return i
    End Function

    Sub ProcessCmpIOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim pt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        pt = GetPnRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitOpcode(oc Or pt)
        emitbyte(ra, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub ProcessLdi(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetRegister(strs(1))
        imm = eval(strs(2))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitOpcode(oc)
        emitbyte(rt, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub ProcessLdis(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetSPRRegister(strs(1))
        imm = eval(strs(2))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitOpcode(oc)
        emitbyte(rt, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub ProcessRIOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitOpcode(oc)
        emitbyte(ra, False)
        emitbyte(rt, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub emitIMM(ByVal imm As Int64, ByVal oc As Int64)
        Dim opcode As Int64
        Dim str As String

        str = iline
        iline = "; imm "
        opcode = oc << 25     ' IMM1
        opcode = opcode Or (imm And &H1FFFFFFL)
        emit(opcode)
        iline = str
    End Sub

    Sub emitIMM2(ByVal imm As Int64)
        Dim opcode As Int64
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= -32768L And imm < 32768L Then
            emitbyte(&H20, False)
            emitbyte(imm >> 8, False)
        ElseIf imm >= &HFFFFFFFFFF800000L And imm < &H7FFFFFL Then
            emitbyte(&H30, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
        ElseIf imm >= &HFFFFFFFF80000000L And imm <= &H7FFFFFFFL Then
            emitbyte(&H40, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
            emitbyte(imm >> 24, False)
        ElseIf imm >= &HFFFFFF8000000000L And imm <= &H7FFFFFFFFFL Then
            emitbyte(&H50, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
            emitbyte(imm >> 24, False)
            emitbyte(imm >> 32, False)
        ElseIf imm >= &HFFFF800000000000L And imm <= &H7FFFFFFFFFFFL Then
            emitbyte(&H60, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
            emitbyte(imm >> 24, False)
            emitbyte(imm >> 32, False)
            emitbyte(imm >> 40, False)
        ElseIf imm >= &HFF80000000000000L And imm <= &H7FFFFFFFFFFFFFL Then
            emitbyte(&H70, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
            emitbyte(imm >> 24, False)
            emitbyte(imm >> 32, False)
            emitbyte(imm >> 40, False)
            emitbyte(imm >> 48, False)
        Else
            emitbyte(&H80, False)
            emitbyte(imm >> 8, False)
            emitbyte(imm >> 16, False)
            emitbyte(imm >> 24, False)
            emitbyte(imm >> 32, False)
            emitbyte(imm >> 40, False)
            emitbyte(imm >> 48, False)
            emitbyte(imm >> 56, False)
        End If
        iline = ""
        WriteListing()
        bytn = 0
        iline = str
    End Sub

    Function TestForPrefix22(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > 2097151 Or imm < -2097152 Then
            Return True
        End If
        i2 = imm >> 22L
        If i2 = 0 And bit(imm, 22) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 22) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix25(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &HFFFFFFL Or imm < &HFFFFFFFFFF000000L Then
            Return True
        End If
        i2 = imm >> 25L
        If i2 = 0 And bit(imm, 25) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 25) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix27(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H3FFFFFF Or imm < &HFFFFFFFFFC000000 Then
            Return True
        End If
        i2 = imm >> 27L
        If i2 = 0 And bit(imm, 27) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 27) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix28(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H7FFFFFFL Or imm < &HFFFFFFFFF8000000L Then
            Return True
        End If
        i2 = imm >> 28L
        If i2 = 0 And bit(imm, 28) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 28) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix33(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &HFFFFFFFFL Or imm < &HFFFFFFFF00000000L Then
            Return True
        End If
        i2 = imm >> 33L
        If i2 = 0 And bit(imm, 33) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 33) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix36(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H7FFFFFFFFL Or imm < &HFFFFFFF800000000L Then
            Return True
        End If
        i2 = imm >> 36L
        If i2 = 0 And bit(imm, 36) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 36) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix40(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H7FFFFFFFFFL Or imm < &HFFFFFF8000000000L Then
            Return True
        End If
        i2 = imm >> 40L
        If i2 = 0 And bit(imm, 40) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 40) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix44(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > (2 ^ 43) - 1 Or imm < -(2 ^ 43) Then
            Return True
        End If
        i2 = imm >> 44L
        If i2 = 0 And bit(imm, 44) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 44) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix50(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H1FFFFFFFFFFFFL Or imm < &HFFFE000000000000L Then
            Return True
        End If
        i2 = imm >> 50L
        If i2 = 0 And bit(imm, 50) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 50) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix52(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H7FFFFFFFFFFFFL Or imm < &HFFF8000000000000L Then
            Return True
        End If
        i2 = imm >> 52L
        If i2 = 0 And bit(imm, 52) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 52) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix58(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &H1FFFFFFFFFFFFFFL Or imm < &HFE00000000000000L Then
            Return True
        End If
        i2 = imm >> 58L
        If i2 = 0 And bit(imm, 58) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 58) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix61(ByVal imm As Int64) As Boolean
        Dim i2 As Int64

        If imm > &HFFFFFFFFFFFFFFFL Or imm < &HF000000000000000L Then
            Return True
        End If
        i2 = imm >> 61L
        If i2 = 0 And bit(imm, 61) = 0 Then
            Return False
        ElseIf i2 = -1 And bit(imm, 61) = 1 Then
            Return False
        End If
        Return True
    End Function

    Function TestForPrefix11(ByVal imm As Int64) As Boolean
        Dim msb As Int64

        If imm > 1023 Or imm < -1024 Then
            Return True
        End If
        msb = (imm And &H400) >> 10
        imm = imm >> 11
        If imm = 0 And msb = 0 Then ' just a sign extension of positive number ?
            Return False
        ElseIf imm = -1 And msb <> 0 Then    ' just a sign extension of a negative number ?
            Return False
        Else
            Return True
        End If
    End Function

    Function TestForPrefix12(ByVal imm As Int64) As Boolean
        Dim msb As Int64

        If imm > 2047 Or imm < -2048 Then
            Return True
        End If
        msb = (imm And &H800) >> 11
        imm = imm >> 12
        If imm = 0 And msb = 0 Then ' just a sign extension of positive number ?
            Return False
        ElseIf imm = -1 And msb <> 0 Then    ' just a sign extension of a negative number ?
            Return False
        Else
            Return True
        End If
    End Function

    Function TestForPrefix15(ByVal imm As Int64) As Boolean
        Dim msb As Int64

        If imm > 16343 Or imm < -16384 Then
            Return True
        End If
        msb = (imm And &H4000) >> 14
        imm = imm >> 15
        If imm = 0 And msb = 0 Then ' just a sign extension of positive number ?
            Return False
        ElseIf imm = -1 And msb <> 0 Then    ' just a sign extension of a negative number ?
            Return False
        Else
            Return True
        End If
    End Function

    Function TestForPrefix8(ByVal imm As Int64) As Boolean
        Dim msb As Int64

        If imm > 127 Or imm < -128 Then
            Return True
        End If
        msb = (imm And &H80) >> 7
        imm = imm >> 8
        If imm = 0 And msb = 0 Then ' just a sign extension of positive number ?
            Return False
        ElseIf imm = -1 And msb <> 0 Then    ' just a sign extension of a negative number ?
            Return False
        Else
            Return True
        End If
    End Function

    Sub ProcessOMG(ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        opcode = 1L << 25
        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        opcode = opcode Or (rt << 15)
        If ra = -1 Then
            imm = GetImmediate(strs(2), "omg")
            opcode = opcode Or ((imm And 63) << 6)
        Else
            opcode = opcode Or (ra << 20)
        End If
        opcode = opcode Or (fn And 63)
        emit(opcode)
    End Sub
    Sub ProcessCMG(ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        opcode = 1L << 25
        ra = GetRegister(strs(1))
        If ra = -1 Then
            imm = GetImmediate(strs(1), "omg")
            opcode = opcode Or ((imm And 63) << 6)
        Else
            opcode = opcode Or (ra << 20)
        End If
        opcode = opcode Or (fn And 63)
        emit(opcode)
    End Sub

    Sub processCond(ByVal s As String)
        Dim t() As String

        t = s.Split(".".ToCharArray)
        Select Case (t(1).ToLower)
            Case "f", "F"
                predicateByte = predicateByte Or 0
            Case "t", "T"
                predicateByte = predicateByte Or 1
            Case "eq", "EQ"
                predicateByte = predicateByte Or 2
            Case "ne", "NE"
                predicateByte = predicateByte Or 3
            Case "le", "LE"
                predicateByte = predicateByte Or 4
            Case "gt", "GT"
                predicateByte = predicateByte Or 5
            Case "ge", "GE"
                predicateByte = predicateByte Or 6
            Case "lt", "LT"
                predicateByte = predicateByte Or 7
            Case "leu", "LEU"
                predicateByte = predicateByte Or 8
            Case "gtu", "GTU"
                predicateByte = predicateByte Or 9
            Case "geu", "GEU"
                predicateByte = predicateByte Or 10
            Case "ltu", "LTU"
                predicateByte = predicateByte Or 11
        End Select
    End Sub
    '
    ' R-ops have the form:   sqrt Rt,Ra
    '
    Sub ProcessROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        emitOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    '
    ' J-ops have the form:   call   address
    '
    Sub ProcessJOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim imm As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        strs(1) = strs(1).Trim
        imm = eval(strs(1))

        'Try
        '    L = symbols.Item(strs(1))
        'Catch
        '    L = Nothing
        'End Try
        'If L Is Nothing Then
        '    L = New Symbol
        '    L.name = strs(1)
        '    L.address = -1
        '    L.defined = False
        '    L.type = "L"
        '    symbols.Add(L, L.name)
        'End If
        'If Not L.defined Then
        '    P = New LabelPatch
        '    P.type = "B"
        '    P.address = address
        '    L.PatchAddresses.Add(P)
        'End If
        'If L.type = "C" Then
        '    imm = ((L.value And &HFFFFFFFFFFFFFFFCL)) >> 2
        'Else
        '    imm = ((L.address And &HFFFFFFFFFFFFFFFCL)) >> 2
        'End If
        If Not optr26 Then
            If Left(strs(0), 1) = "l" Then
                emitIMM(imm >> 48, 126L)
                emitIMM(imm >> 24, 125L)
                emitIMM(imm, 124L)
            ElseIf Left(strs(0), 1) = "m" Then
                emitIMM(imm >> 24, 125L)
                emitIMM(imm, 124L)
            End If
            imm = (imm And &HFFFFFFFFFFFFFFFCL) >> 2
            opcode = oc << 25
            opcode = opcode + (imm And &H1FFFFFF)
            emit(opcode)
        Else
            If Left(strs(0), 1) = "l" Then
                opcode = 26L << 25  ' JAL
                opcode = opcode Or (26L << 15)
                If strs(0) = "lcall" Then
                    opcode = opcode Or (31L << 20)
                End If
                emit(opcode)
            ElseIf Left(strs(0), 1) = "m" Then
                opcode = 26L << 25  ' JAL
                opcode = opcode Or (26L << 15)
                If strs(0) = "mcall" Then
                    opcode = opcode Or (31L << 20)
                End If
                emit(opcode)
            Else
                imm = (imm And &HFFFFFFFFFFFFFFFCL) >> 2
                opcode = oc << 25
                opcode = opcode + (imm And &H1FFFFFF)
                emit(opcode)
            End If
        End If
    End Sub

    '
    ' Ret-ops have the form:   rts or rts 12[r1]
    '
    Sub ProcessRtsOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim Br As Int64
        Dim rt As Int64
        Dim imm As Int64
        Dim s() As String

        If strs.Length = 1 Then     ' RTS short form
            emitbyte(&H11, False)
            Return
        End If
        Try
            s = strs(1).Split("[".ToCharArray)
            If s.Length > 1 Then
                imm = GetImmediate(s(0), "rts")
                Br = GetBrRegister(s(1).TrimEnd("]"))
                emitOpcode(oc)
                emitbyte((Br << 4) Or (imm And 15), False)
                Return
            Else
                imm = 0
                Br = GetBrRegister(s(0).TrimEnd("]"))
                emitOpcode(oc)
                emitbyte((Br << 4) Or (imm And 15), False)
                Return
            End If
        Catch
            'Console.WriteLine("Error: bad string ")
            emitbyte(&H11, False)
        End Try
    End Sub

    Sub FlushConstants()
        If last_op = "db" Then
            emitbyte(0, True)
        ElseIf last_op = "dc" Then
            emitchar(0, True)
        ElseIf last_op = "dh" Then
        ElseIf last_op = "dw" Then
            emitword(0, True)
        End If
    End Sub

    Sub ProcessOrg()
        Dim imm As Int64
        Dim s() As String

        ' dump any data left over in word buffers

        s = strs(1).Split(".".ToCharArray)
        imm = GetImmediate(s(0), "org")
        slot = 0
        Select Case segment
            Case "tls"
                tls_address = imm
            Case "bss"
                bss_address = imm
            Case "code"
                While address Mod 32
                    emitbyte(0, False)
                End While
                w0 = 0
                w1 = 0
                w2 = 0
                w3 = 0
                address = imm
            Case "data"
                data_address = imm
        End Select
        emitRaw("")
    End Sub

    '
    ' Rtd-ops have the form:   rtd  rt,ra,#immed
    '
    Sub ProcessRtdOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = GetImmediate(strs(3), "ret")

        opcode = oc << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (31L << 15)  ' link register
        opcode = opcode Or (rt << 10)
        opcode = opcode Or (imm And &H7FF8)
        emit(opcode)
    End Sub

    '
    ' Ret-ops have the form:   ret
    '
    Sub ProcessNop(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64

        emitbyte(oc, False)
    End Sub

    '
    ' CMP RR-ops have the form: cmp Pt,Ra,Rb
    '
    Sub ProcessCmpRROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim pt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        pt = GetPnRegister(strs(1))
        ra = GetRegister(strs(2))
        rb = GetRegister(strs(3))
        If rb = -1 Then
            ProcessCmpIOp(ops, &H20)
            Return
        End If
        emitOpcode(fn Or pt)
        emitbyte(ra, False)
        emitbyte(rb, False)
    End Sub

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    ' For some ops translation to immediate form is present
    ' when not specified eg. add Rt,Ra,#1234 gets translated to addi Rt,Ra,#1234
    '
    Sub ProcessRROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        rb = GetRegister(strs(3))
        If rb = -1 Then
            Select Case (strs(0))
                Case "add"
                    ProcessRIOp(ops, &H48)
                Case "addu"
                    ProcessRIOp(ops, &H4C)
                Case "sub"
                    ProcessRIOp(ops, &H41)
                Case "subu"
                    ProcessRIOp(ops, &H45)
                Case "and"
                    ProcessRIOp(ops, &H53)
                Case "or"
                    ProcessRIOp(ops, &H54)
                Case "eor"
                    ProcessRIOp(ops, &H55)
                Case "mul"
                    ProcessRIOp(ops, &H4A)
                Case "mulu"
                    ProcessRIOp(ops, &H4E)
                Case "div"
                    ProcessRIOp(ops, &H4B)
                Case "divu"
                    ProcessRIOp(ops, &H4F)
            End Select
            Return
        End If
        emitOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rb, False)
        emitbyte(rt, False)
    End Sub

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    '
    Sub ProcessMtep(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        ra = GetRegister(strs(1))
        rb = GetRegister(strs(2))
        opcode = 2L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        opcode = opcode Or fn
        emit(opcode)
    End Sub
    '
    ' -ops have the form: shrui Rt,Ra,#
    '
    Sub ProcessShiftiOp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))
        emitOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rt, False)
        emitbyte(imm, False)
    End Sub

    '
    ' -ops have the form: bfext Rt,Ra,#me,#mb
    '
    Sub ProcessBitfieldOp(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim maskend As Int64
        Dim maskbegin As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        maskend = eval(strs(3))
        maskbegin = eval(strs(4))
        emitOpcode(&HAA)
        emitbyte(ra, False)
        emitbyte(rt, False)
        emitbyte(maskbegin Or ((maskend << 6) And 3), False)
        emitbyte((maskend And 15) Or (fn << 4), False)
    End Sub

    Sub ProcessJmp(ByVal ops As String, ByVal oc As Int64)
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        s = strs(1).Split("[".ToCharArray)
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            ra = GetBrRegister(s(1))
        End If
        If (offset < -128 Or offset > 127) Then
            emitIMM2(offset)
        End If
        emitOpcode(oc)
        emitbyte(ra << 4, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessJsr(ByVal ops As String, ByVal oc As Int64)
        Dim Bt As Int64
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        Bt = GetBrRegister(strs(1))
        If Bt = -1 Then
            Bt = 1
            s = strs(1).Split("[".ToCharArray)
        Else
            s = strs(2).Split("[".ToCharArray)
        End If
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            ra = GetBrRegister(s(1))
        End If
        If (offset < -8388608 Or offset > 8388607) Then
            emitIMM2(offset)
        End If
        emitOpcode(oc)
        emitbyte((ra << 4) Or Bt, False)
        emitbyte(offset, False)
        emitbyte(offset >> 8, False)
        emitbyte(offset >> 16, False)
    End Sub

    Sub ProcessSys(ByVal ops As String, ByVal oc As Int64)
        Dim Bt As Int64
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        ra = 12
        Bt = GetBrRegister(strs(1))
        If (Bt = -1) Then
            Bt = 13
            s = strs(1).Split("[".ToCharArray)
            offset = eval(s(0))
            If s.Length > 1 Then
                ra = GetBrRegister((s(1).TrimEnd("]".ToCharArray)))
            End If
            emitOpcode(oc)
            emitbyte((ra << 4) Or Bt, False)
            emitbyte(offset, False)
            Return
        End If
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0))
        If s.Length > 1 Then
            ra = GetBrRegister((s(1).TrimEnd("]".ToCharArray)))
        End If
        emitOpcode(oc)
        emitbyte((ra << 4) Or Bt, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessCas(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim s() As String
        Dim offset As Int64

        rt = GetRegister(strs(1))
        rb = GetRegister(strs(2))
        rc = GetRegister(strs(3))
        s = strs(4).Split("[".ToCharArray)
        ra = GetRegister(s(0))
        offset = 0
        If ra = -1 Then
            offset = eval(s(0))
        End If
        If s.Length > 1 Then
            ra = GetRegister(s(1).TrimEnd("]".ToCharArray))
        End If
        If ra = -1 Then ra = 0
        If (offset < -128 Or offset > 127) Then
            emitIMM2(offset)
        End If
        emitOpcode(oc)
        emitbyte(ra, False)
        emitbyte(rb, False)
        emitbyte(rc, False)
        emitbyte(rt, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessMemoryOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim scale As Int64
        Dim s() As String
        Dim s1() As String
        Dim s2() As String
        Dim str As String
        Dim imm As Int64

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        scale = 0
        rb = -1
        If oc = 54 Or oc = 71 Then
            imm = eval(strs(1))
        Else
            rt = GetRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetRegister(strs(2))
        If ra <> -1 Then
            If strs(0).Chars(0) = "l" Then
                opcode = 2L << 25
                opcode = opcode + (ra << 20)
                opcode = opcode + (0L << 15)
                opcode = opcode + (rt << 10)
                opcode = opcode Or 9    ' or
                emit(opcode)
                Return
            End If
        End If
        s = strs(2).Split("[".ToCharArray)
        'offset = GetImmediate(s(0), "memop")
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRegister(s2(0))
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then
            If Not optr26 Then
            Else
                If offset < -128 Or offset > 127 Then
                    emitIMM2(offset)
                End If
                emitOpcode(oc)
                emitbyte(ra, False)
                emitbyte(rt, False)
                emitbyte(offset, False)
            End If
        Else
            Select Case (strs(0))
                Case "lb"
                    oc = &HB0
                Case "lbu"
                    oc = &HB1
                Case "lc"
                    oc = &HB2
                Case "lcu"
                    oc = &HB3
                Case "lh"
                    oc = &HB4
                Case "lhu"
                    oc = &HB5
                Case "lw"
                    oc = &HB6
                Case "sb"
                    oc = &HC0
                Case "sc"
                    oc = &HC1
                Case "sh"
                    oc = &HC2
                Case "sw"
                    oc = &HC3
                Case "lea"
                    oc = &H44
            End Select
            emitOpcode(oc)
            emitbyte(ra, False)
            emitbyte(rb, False)
            emitbyte(rt, False)
        End If
    End Sub

    Sub ProcessSti(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String
        Dim s1() As String
        Dim s2() As String
        Dim str As String
        Dim imm As Int64

        imm = eval(strs(1))
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
        Else
            ra = 0
        End If
        If offset < -128 Or offset > 127 Then
            emitIMM2(offset)
        End If
        emitOpcode(oc)
        emitbyte(ra, False)
        emitbyte(imm, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessLws(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim scale As Int64
        Dim s() As String
        Dim s1() As String
        Dim s2() As String
        Dim str As String
        Dim imm As Int64

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        scale = 0
        rb = -1
        If oc = 54 Or oc = 71 Then
            imm = eval(strs(1))
        Else
            rt = GetSPRRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetRegister(strs(2))
        If ra <> -1 Then
            If strs(0).Chars(0) = "l" Then
                opcode = 2L << 25
                opcode = opcode + (ra << 20)
                opcode = opcode + (0L << 15)
                opcode = opcode + (rt << 10)
                opcode = opcode Or 9    ' or
                emit(opcode)
                Return
            End If
        End If
        s = strs(2).Split("[".ToCharArray)
        'offset = GetImmediate(s(0), "memop")
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRegister(s2(0))
                If (s2.Length > 1) Then
                    scale = eval(s2(1))
                    If (scale = 8) Then
                        scale = 3
                    ElseIf (scale = 4) Then
                        scale = 2
                    ElseIf (scale = 2) Then
                        scale = 1
                    Else
                        scale = 0
                    End If
                End If
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then
            If Not optr26 Then
            Else
                If offset < -128 Or offset > 127 Then
                    emitIMM2(offset)
                End If
                emitOpcode(oc)
                emitbyte(ra, False)
                emitbyte(rt, False)
                emitbyte(offset, False)
            End If
        Else
        End If
    End Sub

    Sub ProcessSws(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim scale As Int64
        Dim s() As String
        Dim s1() As String
        Dim s2() As String
        Dim str As String
        Dim imm As Int64

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        scale = 0
        rb = -1
        If oc = 54 Or oc = 71 Then
            imm = eval(strs(1))
        Else
            rt = GetRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetSPRRegister(strs(2))
        If ra <> -1 Then
            If strs(0).Chars(0) = "l" Then
                opcode = 2L << 25
                opcode = opcode + (ra << 20)
                opcode = opcode + (0L << 15)
                opcode = opcode + (rt << 10)
                opcode = opcode Or 9    ' or
                emit(opcode)
                Return
            End If
        End If
        s = strs(2).Split("[".ToCharArray)
        'offset = GetImmediate(s(0), "memop")
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRegister(s2(0))
                If (s2.Length > 1) Then
                    scale = eval(s2(1))
                    If (scale = 8) Then
                        scale = 3
                    ElseIf (scale = 4) Then
                        scale = 2
                    ElseIf (scale = 2) Then
                        scale = 1
                    Else
                        scale = 0
                    End If
                End If
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then
            If Not optr26 Then
            Else
                If offset < -128 Or offset > 127 Then
                    emitIMM2(offset)
                End If
                emitOpcode(oc)
                emitbyte(ra, False)
                emitbyte(rt, False)
                emitbyte(offset, False)
            End If
        Else
        End If
    End Sub

    Sub ProcessJAL(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim s() As String
        Dim s1() As String

        rb = -1
        rt = GetRegister(strs(1))
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0)) ', "jal")
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                rb = GetRegister(s1(1))
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then
            opcode = oc << 25
            opcode = opcode + (ra << 20)
            opcode = opcode + (rt << 15)
            opcode = opcode + (offset And &H7FFF)
            '            TestForPrefix(offset)
            emit(opcode)
        Else
            'opcode = 53L << 35
            'opcode = opcode + (ra << 30)
            'opcode = opcode + (rb << 25)
            'opcode = opcode + (rt << 20)
            'opcode = opcode + ((offset And &H1FFF) << 7)
            'opcode = opcode Or oc
            'emit(opcode)
        End If
    End Sub

    Sub ProcessSyscall(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim imm As Int64
        opcode = 0L << 25
        opcode = opcode Or (24L << 20)
        opcode = opcode Or (1L << 16)
        imm = eval(strs(1))
        opcode = opcode Or ((imm And 511) << 7)
        opcode = opcode Or oc
        emit(opcode)
    End Sub

    Function ProcessEquate() As Boolean
        Dim sym As Symbol
        Dim sym2 As Symbol
        Dim n As Integer
        Dim s As String

        s = iline
        s = ""
        If Not strs(1) Is Nothing Then
            If strs(1).ToUpper = "EQU" Or strs(1) = "=" Then
                sym = New Symbol
                sym.name = NameTable.AddName(fileno & strs(0))
                n = 2
                While Not strs(n) Is Nothing
                    s = s & strs(n)
                    n = n + 1
                End While
                sym.value = eval(s) 'GetImmediate(strs(2), "equate")
                sym.type = "C"
                sym.segment = "constant"
                sym.defined = True
                If symbols Is Nothing Then
                    symbols = New Collection
                Else
                    Try
                        sym2 = symbols.Item(sym.name)
                    Catch
                        sym2 = Nothing
                    End Try
                End If
                If sym2 Is Nothing Then
                    symbols.Add(sym, sym.name)
                End If
                emitEmptyLine(iline)
                processedEquate = True
                Return True
            End If
        End If
        Return False
    End Function


    Sub ProcessLoop(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol

        L = GetSymbol(strs(1))
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        disp = (((L.address And &HFFFFFFFFFFFFFFFFL) - (address And &HFFFFFFFFFFFFFFFFL)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        If disp < -128 Or disp > 127 Then
            emitIMM2(disp)
        End If
        emitOpcode(oc)
        emitbyte(disp, False)
    End Sub

    Sub ProcessBra(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        ra = 0
        rb = 0
        rc = GetRegister(strs(1))   ' branching to register ?
        If rc = -1 Then
            L = GetSymbol(strs(1))
            'If slot = 2 Then
            '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
            'Else
            disp = (((L.address And &HFFFFFFFFFFFFFFFFL) - (address And &HFFFFFFFFFFFFFFFFL)))
            'End If
            'imm = (L.address + (L.slot << 2)) >> 2
        End If
        emitOpcode(oc Or ((disp >> 8) And &HF))
        emitbyte(disp And &HFF, False)
    End Sub

    Function GetSymbol(ByVal nm As String) As Symbol
        Dim L As Symbol
        Dim P As LabelPatch

        nm = nm.Trim
        Try
            L = symbols.Item(fileno & nm)
        Catch
            Try
                L = symbols.Item("0" & nm)
            Catch
                L = Nothing
            End Try
        End Try
        If L Is Nothing Then
            L = New Symbol
            L.fileno = fileno
            If publicFlag Then
                L.scope = "Pub"
                L.fileno = 0
            End If
            L.name = NameTable.AddName(L.fileno & nm)
            L.address = -1
            L.defined = False
            L.type = "L"
            If L.fileno & nm = "0printf" Then
                Console.WriteLine("L7")
            End If
            symbols.Add(L, L.fileno & nm)
        End If
        If Not L.defined Then
            P = New LabelPatch
            P.type = "RRBranch"
            P.address = address
            L.PatchAddresses.Add(P)
        End If
        Return L
    End Function

    Sub ProcessBrr(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim n As Integer

        ra = GetRegister(strs(1))
        rb = GetRegister(strs(2))
        If rb = -1 Then
            rb = 0
            n = 2
        Else
            n = 3
        End If
        strs(n) = strs(n).Trim
        Try
            L = symbols.Item(fileno & strs(n))
        Catch
            L = Nothing
        End Try
        L = GetSymbol(strs(n))
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        imm = (((L.address And &HFFFFFFFFFFFFFFFCL) - (address And &HFFFFFFFFFFFFFFFCL))) >> 2
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        opcode = 16L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (oc << 15)
        opcode = opcode Or (imm And &H1FFFFFF)
        '        TestForPrefix(imm)
        emit(opcode)
    End Sub

    Function GetRegister(ByVal s As String) As Int64
        Dim r As Int16
        Try
            If s.StartsWith("R") Or s.StartsWith("r") Then
                s = s.TrimStart("Rr".ToCharArray)
                Try
                    r = Int16.Parse(s)
                Catch
                    r = -1
                End Try
                Return r
                'r26 is the constant building register
            ElseIf s.ToLower = "bp" Then
                Return 254
            ElseIf s.ToLower = "sp" Then
                Return 255
            ElseIf s.ToLower = "ssp" Then
                Return 25
            Else
                Return -1
            End If
        Catch
            Return -1
        End Try
    End Function

    Function GetBrRegister(ByVal s As String) As Int64
        Dim r As Int16
        If s.StartsWith("B") Or s.StartsWith("b") Then
            s = s.TrimStart("Bb".ToCharArray)
            If s.StartsWith("R") Or s.StartsWith("r") Then
                s = s.TrimStart("Rr".ToCharArray)
            End If
            Try
                r = Int16.Parse(s)
            Catch
                r = -1
            End Try
            Return r
        ElseIf s.ToLower = "pc" Then
            Return 15
        ElseIf s.ToLower = "lr" Then
            Return 1
        ElseIf s.ToLower = "ipc" Then
            Return 14
        ElseIf s.ToLower = "epc" Then
            Return 13
        ElseIf s.ToLower = "vbr" Then
            Return 12
        ElseIf s.ToLower = "xlr" Then
            Return 11
        Else
            Return -1
        End If
    End Function

    Function GetPnRegister(ByVal s As String) As Int64
        Dim t() As String
        Dim r As Int16
        t = s.Split(".".ToCharArray)
        If t(0).StartsWith("P") Or t(0).StartsWith("p") Then
            t(0) = t(0).TrimStart("Pp".ToCharArray)
            Try
                r = Int16.Parse(t(0))
            Catch
                r = -1
            End Try
            Return r
        Else
            Return -1
        End If
    End Function

    Function GetSPRRegister(ByVal s As String) As Int64

        Select Case (s.ToLower)
            Case "tick"
                Return 2
            Case "lc"
                Return 3
            Case "pregs"
                Return 4
            Case "asid"
                Return 6
            Case "cs"
                Return 47
            Case "ss"
                Return 46
            Case "br0"
                Return 16
            Case "br1"
                Return 17
            Case "br2"
                Return 18
            Case "br3"
                Return 19
            Case "br4"
                Return 20
            Case "br5"
                Return 21
            Case "br6"
                Return 22
            Case "br7"
                Return 23
            Case "br8"
                Return 24
            Case "br9"
                Return 25
            Case "br10"
                Return 26
            Case "br11"
                Return 27
            Case "br12"
                Return 28
            Case "br13"
                Return 29
            Case "br14"
                Return 30
            Case "br15"
                Return 31
            Case "epc"
                Return 29
            Case "ipc"
                Return 30
            Case "pc"
                Return 31
            Case "seg0"
                Return 32
            Case "seg1"
                Return 33
            Case "seg2"
                Return 34
            Case "seg3"
                Return 35
            Case "seg4"
                Return 36
            Case "seg5"
                Return 37
            Case "seg6"
                Return 38
            Case "seg7"
                Return 39
            Case "seg8"
                Return 40
            Case "seg9"
                Return 41
            Case "seg10"
                Return 42
            Case "seg11"
                Return 43
            Case "seg12"
                Return 44
            Case "seg13"
                Return 45
            Case "seg14"
                Return 46
            Case "seg15"
                Return 47
        End Select
        Return -1
    End Function

    Function GetTLBRegister(ByVal s As String) As Int64

        Try
            Select Case (s.ToLower)
                Case "wired"
                    Return 0
                Case "index"
                    Return 1
                Case "random"
                    Return 2
                Case "pagesize"
                    Return 3
                Case "virtpage"
                    Return 4
                Case "physpage"
                    Return 5
                Case "asid"
                    Return 7
                Case "dma"
                    Return 8
                Case "ima"
                    Return 9
                Case "pagetbladdr"
                    Return 10
                Case "pagetblctrl"
                    Return 11
                Case Else
                    Return Int64.Parse(s)
            End Select
        Catch
            Return -1
        End Try
        Return -1
    End Function

    'Function GetImmediate(ByVal s As String) As Int64
    '    Dim s1 As String
    '    Dim s2 As String
    '    Dim s3 As String
    '    Dim n As Int64

    '    s = s.TrimStart("#".ToCharArray)
    '    s = s.Replace("_", "")
    '    If s.Length = 0 Then Return 0
    '    If s.Chars(0) = "0" Then
    '        If s.Length = 1 Then Return 0
    '        If s.Chars(1) = "x" Or s.Chars(1) = "X" Then
    '            If s.Length >= 18 Then
    '                s1 = "&H0000" & s.Substring(2, 6) & "&"
    '                s2 = "&H0000" & s.Substring(8, 6) & "&"
    '                s3 = "&H0000" & s.Substring(14) & "&"
    '                n = Val(s1) << 40
    '                n = n Or (Val(s2) << 16)
    '                n = n Or Val(s3)
    '            Else
    '                s1 = "&H" & s.Substring(2)
    '                n = Val(s1)
    '            End If
    '        End If
    '    Else
    '        n = Int64.Parse(s)
    '    End If
    '    Return n
    'End Function
    Function GetImmediate(ByVal s As String, ByVal patchtype As String) As Int64
        Dim s1 As String
        Dim s2 As String
        Dim s3 As String
        Dim n As Int64
        Dim q As Integer
        Dim m As Integer
        Dim sym As Symbol
        Dim L As Symbol
        Dim LP As LabelPatch
        Dim shr32 As Boolean
        Dim mask32 As Boolean

        shr32 = False
        mask32 = False
        s = s.TrimStart("#".ToCharArray)
        If s.Length = 0 Then Return 0
        If s.Chars(0) = ">" Then
            s = s.TrimStart(">".ToCharArray)
            shr32 = True
        End If
        If s.Chars(0) = "<" Then
            s = s.TrimStart("<".ToCharArray)
            mask32 = True
        End If
        If s.Chars(0) = "$" Then
            s = s.Replace("_", "")
            s1 = "0x" & s.Substring(1)
            n = GetImmediate(s1, patchtype)
        ElseIf s.Chars(0) = "'" Then
            If s.Chars(1) = "\" Then
                Select Case s.Chars(2)
                    Case "n"
                        n = Asc(vbLf)
                    Case "r"
                        n = Asc(vbCr)
                    Case Else
                        n = 0
                End Select
            Else
                n = Asc(s.Chars(1))
            End If
        ElseIf s.Chars(0) = "0" Then
            s = s.Replace("_", "")
            If s.Length = 1 Then Return 0
            If s.Chars(1) = "x" Or s.Chars(1) = "X" Then
                If s.Length >= 18 Then
                    s = Right(s, 16)    ' max that will fit into 64 bits
                    s1 = "&H0000" & s.Substring(0, 6) & "&"
                    s2 = "&H0000" & s.Substring(6, 6) & "&"
                    s3 = "&H0000" & s.Substring(12) & "&"
                    n = Val(s1) << 40
                    n = n Or (Val(s2) << 16)
                    n = n Or Val(s3)
                Else
                    n = 0
                    s = s.Substring(2)
                    For m = 0 To s.Length - 1
                        n = n << 4
                        s1 = "&H" & s.Substring(m, 1)
                        n = n Or Val(s1)
                    Next
                    'If s.Substring(2, 1) = "0" And n < 0 Then
                    '    n = -n
                    'End If
                End If
            End If
        Else
            If s.Chars(0) > "9" Then
                sym = Nothing
                Try
                    sym = symbols.Item(CStr(fileno) & s)
                Catch
                    Try
                        sym = symbols.Item("0" & s)
                    Catch
                        sym = Nothing
                    End Try
                End Try
                If sym Is Nothing Then
                    sym = New Symbol
                    sym.name = NameTable.AddName(CStr(fileno) & s)
                    sym.defined = False
                    sym.type = "U"
                    sym.segment = "Unknown"
                    If CStr(fileno) & s = "0printf" Then
                        Console.WriteLine("L7")
                    End If
                    symbols.Add(sym, CStr(fileno) & s)
                End If
                If sym.defined Then
                    If sym.type = "L" Then
                        n = sym.address
                    Else
                        n = sym.value
                    End If
                    GoTo j1
                End If
                LP = New LabelPatch
                LP.address = address
                LP.type = patchtype
                sym.PatchAddresses.Add(LP)
                Select Case patchtype
                    Case Else
                        Return 0
                End Select
                Return 0
            End If
            s = s.Replace("_", "")
            n = Int64.Parse(s)
        End If
j1:
        If shr32 Then
            n = n >> 32
        End If
        If mask32 Then
            n = n And &HFFFFFFFFL
        End If
        Return n
    End Function


    Function CompressSpaces(ByVal s As String) As String
        Dim plen As Integer
        Dim n As Integer
        Dim os As String
        Dim inQuote As Char

        os = ""
        inQuote = "?"
        plen = s.Length
        For n = 1 To plen
            If inQuote <> "?" Then
                os = os & Mid(s, n, 1)
                If inQuote = Mid(s, n, 1) Then
                    inQuote = "?"
                End If
            ElseIf Mid(s, n, 1) = " " Then
                os = os & Mid(s, n, 1)
                Do
                    n = n + 1
                Loop While Mid(s, n, 1) = " " And n <= plen
                n = n - 1
            ElseIf Mid(s, n, 1) = Chr(34) Then
                inQuote = Mid(s, n, 1)
                os = os & Mid(s, n, 1)
            ElseIf Mid(s, n, 1) = "'" Then
                inQuote = Mid(s, n, 1)
                os = os & Mid(s, n, 1)
            Else
                os = os & Mid(s, n, 1)
            End If
        Next
        Return os
    End Function

    Sub emitEmptyLine(ByVal ln As String)
        Dim s As String
        If pass = maxpass Then
            s = "                " & "  " & vbTab & "           " & vbTab & vbTab & ln
            lfs.WriteLine(s)
        End If
    End Sub

    Sub emitLabel(ByVal lbl As String)
        Dim s As String

        If pass = maxpass Then
            s = Hex(address).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
            lfs.WriteLine(s)
        End If
    End Sub

    Sub emitOpcode(ByVal oc As Int64)
        emitbyte(predicateByte, False)
        emitbyte(oc, False)
    End Sub

    Sub emitRaw(ByVal ss As String)
        Dim s As String
        If pass = maxpass Then
            If segment = "tls" Then
                s = Hex(tls_address).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
                lfs.WriteLine(s)
            ElseIf segment = "bss" Then
                s = Hex(bss_address).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
                lfs.WriteLine(s)
            ElseIf segment = "data" Then
                s = Hex(data_address).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
                lfs.WriteLine(s)
            Else
                s = Hex(address).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
                lfs.WriteLine(s)
            End If
        End If
    End Sub

    Sub emit(ByVal n As Int64)
        emitInsn(n, False)
    End Sub

    Sub emitbyte(ByVal n As Int64, ByVal flush As Boolean)
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64
        Dim hh As String
        Dim jj As Integer

        If bytn > 32 Then
            WriteListing()
            bytn = 0
        End If
        If n = &H38 Then
            bytesbuf(bytn) = n And 255
        End If
        bytesbuf(bytn) = n And 255
        bytn = bytn + 1

        'If flush Then
        '    If pass = 2 Then
        '        If bytndx = 0 Then Return
        '        Select Case segment
        '            Case "bss"
        '                ad = bss_address
        '            Case "code"
        '                ad = address
        '        End Select
        '        If segment = "bss" Then
        '            s = Hex(ad - bytndx) & " " & Right(Hex(cd).PadLeft(16, "0"), bytndx * 2)
        '            lfs.WriteLine(s)
        '        Else
        '            If opt64out Then
        '                hh = bytndx * 8 + 8 & "'h"
        '                cd = byts(0) + (byts(1) << 8) + (byts(2) << 16) + (byts(3) << 24) + (byts(4) << 32) + (byts(5) << 40) + (byts(6) << 48) + (byts(7) << 56)
        '                s = vbTab & "rommem[" & ((address >> 3) And 2047) & "] = 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
        '                '                        s = "16'h" & Right(Hex(ad - bytndx), 4) & ":" & vbTab & "romout <= 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
        '                ofs.WriteLine(s)
        '                s = Hex(ad - bytndx) & " " & Right(Hex(cd).PadLeft(16, "0"), bytndx * 2)
        '                lfs.WriteLine(s)
        '            Else
        '                cd = byts(0) + (byts(1) << 8) + (byts(2) << 16) + (byts(3) << 24)
        '                s = "64'h" & Hex(ad - bytndx) & ":" & vbTab & "romout <= 32'h" & Right(Hex(cd).PadLeft(8, "0"), 8) & ";"
        '                ofs.WriteLine(s)
        '                s = Hex(ad - bytndx) & " " & Right(Hex(cd).PadLeft(8, "0"), 8)
        '                lfs.WriteLine(s)
        '            End If
        '        End If
        '        bytndx = 0
        '    End If
        '    Return
        'End If
        If segment = "code" Then
            If (address And 31) = 0 Then
                w0 = 0
                w1 = 0
                w2 = 0
                w3 = 0
            End If
            For jj = 0 To 31
                If (address And 31) = jj Then
                    If jj >= 24 Then
                        w3 = w3 Or ((n And 255) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        w2 = w2 Or ((n And 255) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        w1 = w1 Or ((n And 255) << ((jj And 7) * 8))
                    Else
                        w0 = w0 Or ((n And 255) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (address And 31) = 7 Then
                    emitRom(w0)
                End If
                If (address And 31) = 15 Then
                    emitRom(w1)
                End If
                If (address And 31) = 23 Then
                    emitRom(w2)
                End If
                If (address And 31) = 31 Then
                    emitRom(w3)
                End If
                If (address And 31) = 31 Then
                    emitInstRow(w0, w1, w2, w3)
                End If
            End If
        End If
        If segment = "data" Then
            If (data_address And 31) = 0 Then
                dw0 = 0
                dw1 = 0
                dw2 = 0
                dw3 = 0
            End If
            For jj = 0 To 31
                If (data_address And 31) = jj Then
                    If jj >= 24 Then
                        dw3 = dw3 Or ((n And 255) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        dw2 = dw2 Or ((n And 255) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        dw1 = dw1 Or ((n And 255) << ((jj And 7) * 8))
                    Else
                        dw0 = dw0 Or ((n And 255) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (data_address And 31) = 7 Then
                    emitRom(dw0)
                End If
                If (data_address And 31) = 15 Then
                    emitRom(dw1)
                End If
                If (data_address And 31) = 23 Then
                    emitRom(dw2)
                End If
                If (data_address And 31) = 31 Then
                    emitRom(dw3)
                    bytn = 0
                End If
                If (data_address And 31) = 31 Then
                    emitInstRow(dw0, dw1, dw2, dw3)
                End If
            End If
        End If

        If pass = maxpass Then
            Select Case segment
                Case "tls"
                    ad = tls_address
                Case "bss"
                    ad = bss_address
                Case "code"
                    ad = address
                Case "data"
                    ad = data_address
            End Select
            If (ad And 7) = 7 Then
                nn = (ad >> 3) And 3
                Select Case nn
                    Case 0 : cd = w0
                    Case 1 : cd = w1
                    Case 2 : cd = w2
                    Case 3 : cd = w3
                End Select
                s = Hex(ad - 7) & " " & Right(Hex(cd).PadLeft(16, "0"), 16) & IIf(firstline, vbTab & iline, "")
                'lfs.WriteLine(s)
                firstline = False
            End If
        End If
        Select Case segment
            Case "tls"
                tls_address = tls_address + 1
                ad = tls_address
            Case "bss"
                bss_address = bss_address + 1
                ad = bss_address
            Case "code"
                address = address + 1
                ad = address
            Case "data"
                data_address = data_address + 1
                ad = data_address
        End Select
    End Sub

    Sub emitchar(ByVal n As Int64, ByVal flush As Boolean)
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64
        Dim hh As String
        Dim jj As Integer

        If segment = "code" Then
            If (address And 31) = 0 Then
                w0 = 0
                w1 = 0
                w2 = 0
                w3 = 0
            End If
            For jj = 0 To 31 Step 2
                If (address And 31) = jj Then
                    If jj >= 24 Then
                        w3 = w3 Or ((n And 65535) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        w2 = w2 Or ((n And 65535) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        w1 = w1 Or ((n And 65535) << ((jj And 7) * 8))
                    Else
                        w0 = w0 Or ((n And 65535) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (address And 31) = 6 Then
                    emitRom(w0)
                End If
                If (address And 31) = 14 Then
                    emitRom(w1)
                End If
                If (address And 31) = 22 Then
                    emitRom(w2)
                End If
                If (address And 31) = 30 Then
                    emitRom(w3)
                End If
                If (address And 31) = 30 Then
                    emitInstRow(w0, w1, w2, w3)
                End If
            End If
        ElseIf segment = "data" Then
            If (data_address And 31) = 0 Then
                dw0 = 0
                dw1 = 0
                dw2 = 0
                dw3 = 0
            End If
            For jj = 0 To 31 Step 2
                If (data_address And 31) = jj Then
                    If jj >= 24 Then
                        dw3 = dw3 Or ((n And 65535) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        dw2 = dw2 Or ((n And 65535) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        dw1 = dw1 Or ((n And 65535) << ((jj And 7) * 8))
                    Else
                        dw0 = dw0 Or ((n And 65535) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (data_address And 31) = 6 Then
                    emitRom(dw0)
                End If
                If (data_address And 31) = 14 Then
                    emitRom(dw1)
                End If
                If (data_address And 31) = 22 Then
                    emitRom(dw2)
                End If
                If (data_address And 31) = 30 Then
                    emitRom(dw3)
                End If
                If (data_address And 31) = 30 Then
                    emitInstRow(dw0, dw1, dw2, dw3)
                End If
            End If
        End If
        If pass = maxpass Then
            Select Case segment
                Case "tls"
                    ad = tls_address
                Case "bss"
                    ad = bss_address
                Case "code"
                    ad = address
                Case "data"
                    ad = data_address
            End Select
            If (ad And 6) = 6 Then
                nn = (ad >> 3) And 3
                If segment = "data" Then
                    Select Case nn
                        Case 0 : cd = dw0
                        Case 1 : cd = dw1
                        Case 2 : cd = dw2
                        Case 3 : cd = dw3
                    End Select
                Else
                    Select Case nn
                        Case 0 : cd = w0
                        Case 1 : cd = w1
                        Case 2 : cd = w2
                        Case 3 : cd = w3
                    End Select
                End If
                s = Hex(ad - 6) & " " & Right(Hex(cd).PadLeft(16, "0"), 16) & IIf(firstline, vbTab & iline, "")
                lfs.WriteLine(s)
                firstline = False
            End If
        End If
        Select Case segment
            Case "tls"
                tls_address = tls_address + 2
            Case "bss"
                bss_address = bss_address + 2
            Case "code"
                address = address + 2
            Case "data"
                data_address = data_address + 2
        End Select
    End Sub

    Sub emithalf(ByVal n As Int64, ByVal flush As Boolean)
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64
        Dim hh As String
        Dim jj As Integer

        If segment = "code" Then
            If (address And 31) = 0 Then
                w0 = 0
                w1 = 0
                w2 = 0
                w3 = 0
            End If
            For jj = 0 To 31 Step 4
                If (address And 31) = jj Then
                    If jj >= 24 Then
                        w3 = w3 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        w2 = w2 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        w1 = w1 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    Else
                        w0 = w0 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (address And 31) = 4 Then
                    emitRom(w0)
                End If
                If (address And 31) = 12 Then
                    emitRom(w1)
                End If
                If (address And 31) = 20 Then
                    emitRom(w2)
                End If
                If (address And 31) = 28 Then
                    emitRom(w3)
                End If
                If (address And 31) = 28 Then
                    emitInstRow(w0, w1, w2, w3)
                End If
            End If
        ElseIf segment = "data" Then
            If (data_address And 31) = 0 Then
                dw0 = 0
                dw1 = 0
                dw2 = 0
                dw3 = 0
            End If
            For jj = 0 To 31 Step 4
                If (data_address And 31) = jj Then
                    If jj >= 24 Then
                        dw3 = dw3 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    ElseIf jj >= 16 Then
                        dw2 = dw2 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    ElseIf jj >= 8 Then
                        dw1 = dw1 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    Else
                        dw0 = dw0 Or ((n And &HFFFFFFFFL) << ((jj And 7) * 8))
                    End If
                End If
            Next
            If pass = maxpass Then
                If (data_address And 31) = 4 Then
                    emitRom(dw0)
                End If
                If (data_address And 31) = 12 Then
                    emitRom(dw1)
                End If
                If (data_address And 31) = 20 Then
                    emitRom(dw2)
                End If
                If (data_address And 31) = 28 Then
                    emitRom(dw3)
                End If
                If (data_address And 31) = 28 Then
                    emitInstRow(dw0, dw1, dw2, dw3)
                End If
            End If
        End If

        If pass = maxpass Then
            Select Case segment
                Case "tls"
                    ad = tls_address
                Case "bss"
                    ad = bss_address
                Case "code"
                    ad = address
                Case "data"
                    ad = data_address
            End Select
            If (ad And 7) = 7 Then
                nn = (ad >> 3) And 3
                Select Case nn
                    Case 0 : cd = w0
                    Case 1 : cd = w1
                    Case 2 : cd = w2
                    Case 3 : cd = w3
                End Select
                s = Hex(ad - 6) & " " & Right(Hex(cd).PadLeft(16, "0"), 16) & IIf(firstline, vbTab & iline, "")
                lfs.WriteLine(s)
                firstline = False
            End If
        End If
        Select Case segment
            Case "tls"
                tls_address = tls_address + 4
            Case "bss"
                bss_address = bss_address + 4
            Case "code"
                address = address + 4
            Case "data"
                data_address = data_address + 4
        End Select
    End Sub

    Sub emitchar_old(ByVal n As Int64, ByVal flush As Boolean)
        Static chrs(4) As Int64
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64

        If opt32out = True Then
            nn = 2
        Else
            nn = 4
        End If
        If flush Then
            If pass = maxpass Then
                If opt64out Then
                    cd = chrs(0) + (chrs(1) << 16) + (chrs(2) << 32) + (chrs(3) << 48)
                    If segment <> "bss" Then
                        s = "64'h" & Hex(ad - bytndx) & ":" & vbTab & "romout <= 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
                        ofs.WriteLine(s)
                    End If
                    s = Hex(ad - bytndx) & " " & Right(Hex(cd).PadLeft(16, "0"), bytndx * 2) & IIf(firstline, vbTab & iline, "")
                    lfs.WriteLine(s)
                Else
                    cd = chrs(0) + (chrs(1) << 16)
                    If segment <> "bss" Then
                        s = "64'h" & Hex(ad - bytndx) & ":" & vbTab & "romout <= 32'h" & Right(Hex(cd).PadLeft(8, "0"), 8) & ";"
                        ofs.WriteLine(s)
                    End If
                    s = Hex(ad - bytndx) & " " & Right(Hex(cd).PadLeft(8, "0"), 8) & IIf(firstline, vbTab & iline, "")
                    lfs.WriteLine(s)
                End If
            End If
            Return
        End If
        chrs(bytndx) = n
        If pass = maxpass Then

        End If
        bytndx = bytndx + 1
        Select Case segment
            Case "bss"
                bss_address = bss_address + 2
                ad = bss_address
            Case "code"
                address = address + 2
                ad = address
        End Select
        If bytndx = nn Then
            bytndx = 0
            If pass = maxpass Then
                If opt64out Then
                    cd = chrs(0) + (chrs(1) << 16) + (chrs(2) << 32) + (chrs(3) << 48)
                    If segment <> "bss" Then
                        s = "64'h" & Hex(ad - 8) & ":" & vbTab & "romout <= 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
                        ofs.WriteLine(s)
                    End If
                    s = Hex(ad - 8) & " " & Right(Hex(cd).PadLeft(16, "0"), 16) & IIf(firstline, vbTab & iline, "")
                    lfs.WriteLine(s)
                    firstline = False
                Else
                    cd = chrs(0) + (chrs(1) << 16)
                    If segment <> "bss" Then
                        s = "64'h" & Hex(ad - 4) & ":" & vbTab & "romout <= 32'h" & Right(Hex(cd).PadLeft(8, "0"), 8) & ";"
                        ofs.WriteLine(s)
                    End If
                    s = Hex(ad - 4) & " " & Right(Hex(cd).PadLeft(8, "0"), 8) & IIf(firstline, vbTab & iline, "")
                    lfs.WriteLine(s)
                    firstline = False
                End If
            End If
            chrs(0) = 0
            chrs(1) = 0
            chrs(2) = 0
            chrs(3) = 0
        End If
    End Sub

    Sub emitword(ByVal n As Int64, ByVal flush As Boolean)
        Static word As Int64
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64

        word = n
        If pass = maxpass Then
            emitRom(n)
        End If
        If pass = maxpass Then
            If opt64out Then
                Select Case segment
                    Case "tls"
                        ad = tls_address
                    Case "bss"
                        ad = bss_address
                    Case "code"
                        ad = address
                    Case "data"
                        ad = data_address
                End Select
                cd = word
                'If segment <> "bss" Then
                '    s = vbTab & "rommem[" & ((address >> 3) And 2047) & "] = 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
                '    's = "16'h" & Right(Hex(ad - 8), 4) & ":" & vbTab & "romout <= 64'h" & Right(Hex(cd).PadLeft(16, "0"), 16) & ";"
                '    ofs.WriteLine(s)
                'End If
                s = Right(Hex(ad).PadLeft(16, "0"), 16) & " " & Right(Hex(cd).PadLeft(16, "0"), 16) & IIf(firstline, vbTab & iline, "")
                lfs.WriteLine(s)
                firstline = False
            End If
        End If
        Select Case segment
            Case "tls"
                tls_address = tls_address + 8
            Case "bss"
                bss_address = bss_address + 8
            Case "code"
                address = address + 8
            Case "data"
                data_address = data_address + 8
        End Select
        word = 0
    End Sub

    Sub emitInstRow(ByVal w0 As Int64, ByVal w1 As Int64, ByVal w2 As Int64, ByVal w3 As Int64)
        Static row As Integer
        Static inst As Integer
        Dim s As String

        row = (address >> 5) And 63
        s = "INST " & instname & inst & " INIT_" & Hex(row).PadLeft(2, "0") & "=" & Hex(w3).PadLeft(16, "0") & Hex(w2).PadLeft(16, "0") & Hex(w1).PadLeft(16, "0") & Hex(w0).PadLeft(16, "0") & ";"
        ufs.WriteLine(s)
        If row = 63 Then inst = inst + 1

    End Sub
    Function calcParity32(ByVal q As Int64) As Integer
        Dim p As Integer
        Dim x As Integer

        p = 0
        For x = 0 To 31
            p = p Xor ((q >> x) And 1)
        Next
        Return p
    End Function

    Sub emitRom(ByVal w As Int64)
        Dim s As String
        Dim bt(64) As Integer
        Dim nn As Integer
        Dim p As Integer
        Dim q As Int64
        Dim ad As Int64

        ad = address - 7
        If segment = "tls" Then
            tbindex = tbindex + 1
            tlsEnd = IIf(tlsEnd > tbindex * 8, tlsEnd, tbindex * 8)
        ElseIf segment = "bss" Then
            bbindex = bbindex + 1
            bssEnd = IIf(bssEnd > bbindex * 8, bssEnd, bbindex * 8)
        Else
            If opt32out Then
                p = 0
                For nn = 0 To 63
                    If bt(nn) Then
                        p = p + 1
                    End If
                Next
                s = vbTab & "rommem[" & ((ad >> 2) And 8191) & "] = 33'h" & calcParity32(w) & Hex(w And &HFFFFFFFFL).PadLeft(8, "0") & ";" ' & Hex(address)
                ofs.WriteLine(s)
                s = vbTab & "rommem[" & ((ad >> 2) And 8191) + 1 & "] = 33'h" & calcParity32(w >> 32) & Hex((w >> 32) And &HFFFFFFFFL).PadLeft(8, "0") & ";" ' & Hex(address)
                ofs.WriteLine(s)
                If segment = "code" Then
                    codebytes(cbindex) = w
                    cbindex = cbindex + 1
                    codeEnd = IIf(codeEnd > cbindex * 8, codeEnd, cbindex * 8)
                ElseIf segment = "data" Then
                    databytes(dbindex) = w
                    dbindex = dbindex + 1
                    dataEnd = IIf(dataEnd > dbindex * 8, dataEnd, dbindex * 8)
                End If
                '            bfs.Write(w)
            Else
                For nn = 0 To 63
                    bt(nn) = (w0 >> nn) And 1
                Next
                p = 0
                For nn = 0 To 63
                    If bt(nn) Then
                        p = p + 1
                    End If
                Next
                s = vbTab & "rommem[" & ((ad >> 3) And 8191) & "] = 65'h" & (p And 1) & Hex(w).PadLeft(16, "0") & ";" ' & Hex(address)
                ofs.WriteLine(s)
                If segment = "code" Then
                    codebytes(cbindex) = w
                    cbindex = cbindex + 1
                    codeEnd = IIf(codeEnd > cbindex * 8, codeEnd, cbindex * 8)
                ElseIf segment = "data" Then
                    databytes(dbindex) = w
                    dbindex = dbindex + 1
                    dataEnd = IIf(dataEnd > dbindex * 8, dataEnd, dbindex * 8)
                End If
                '            bfs.Write(w)
            End If
        End If
    End Sub

    Sub emitInsn(ByVal n As Int64, ByVal pfx As Boolean)
        Dim s As String
        Dim i As Integer
        Dim ad As Int64

        If pass = maxpass Then
            If pfx Then
                s = Hex(address).PadLeft(16, "0") & vbTab & Hex(n).PadLeft(8, "0") & vbTab
            Else
                s = Hex(address).PadLeft(16, "0") & vbTab & Hex(n).PadLeft(8, "0") & vbTab & vbTab & iline
            End If
            lfs.WriteLine(s)
        End If
        If pass = maxpass Then
            If address = &HFFFFFFFFFFFFFFF0L Then
                Console.WriteLine("hi")
            End If
            If (address And 28) = 0 Then
                w0 = n
                w1 = 0
                w2 = 0
                w3 = 0
            ElseIf (address And 28) = 4 Then
                w0 = w0 Or (n << 32)
                emitRom(w0)
            ElseIf (address And 28) = 8 Then
                w1 = n
            ElseIf (address And 28) = 12 Then
                w1 = w1 Or (n << 32)
                emitRom(w1)
            ElseIf (address And 28) = 16 Then
                w2 = n
            ElseIf (address And 28) = 20 Then
                w2 = w2 Or (n << 32)
                emitRom(w2)
            ElseIf (address And 28) = 24 Then
                w3 = n
            ElseIf (address And 28) = 28 Then
                w3 = w3 Or (n << 32)
                emitRom(w3)
                'ElseIf i = 5 Then
                '    w3 = w3 Or (n << 20)
                '    emitRom(w3)
                emitInstRow(w0, w1, w2, w3)
            End If
        End If
        address = address + 4
    End Sub

    Function nextTerm(ByRef n) As String
        Dim s As String
        Dim st As Integer
        Dim inQuote As Char

        s = ""
        inQuote = "?"
        While n < Len(estr)
            If estr.Chars(n) = "'" Then
                If inQuote = "'" Then
                    inQuote = "?"
                Else
                    inQuote = "'"
                End If
            End If
            If estr.Chars(n) = """" Then
                If inQuote = """" Then
                    inQuote = "?"
                Else
                    inQuote = """"
                End If
            End If
            If inQuote = "?" Then
                If estr.Chars(n) = "*" Or estr.Chars(n) = "/" Or estr.Chars(n) = "+" Or estr.Chars(n) = "-" Then Exit While
            End If
            s = s & estr.Chars(n)
            n = n + 1
        End While
        Return s
    End Function

    Function evalStar(ByRef n As Integer) As Int64
        Dim rv As Int64

        rv = GetImmediate(nextTerm(n), "")
        While n < Len(estr)
            If estr.Chars(n) <> "*" And estr.Chars(n) <> "/" And estr.Chars(n) <> " " And estr.Chars(n) <> vbTab Then Exit While
            If estr.Chars(n) = "*" Then
                n = n + 1
                rv = rv * GetImmediate(nextTerm(n), "")
            ElseIf estr.Chars(n) = "/" Then
                n = n + 1
                rv = rv / GetImmediate(nextTerm(n), "")
            Else
                n = n + 1
            End If
        End While
        Return rv
    End Function

    Function eval(ByVal s As String) As Int64
        Dim s1 As String
        Dim n As Integer
        Dim rv As Int64

        estr = s
        n = 0
        rv = 0
        rv = evalStar(n)
        While n < Len(estr)
            If estr.Chars(n) <> "+" And estr.Chars(n) <> "-" And estr.Chars(n) <> " " Then Exit While
            If estr.Chars(n) = "+" Then
                n = n + 1
                rv = rv + evalStar(n)
            ElseIf estr.Chars(n) = "-" Then
                n = n + 1
                rv = rv - evalStar(n)
            Else
                n = n + 1
            End If
        End While

        Return rv
    End Function

    Function Round512(ByVal n As Int64) As Int64

        Return (n + 511) And &HFFFFFFFFFFFFFE00L

    End Function

    Sub WriteELFFile()
        Dim eh As New Elf64Header
        Dim byt As Byte
        Dim ui32 As UInt32
        Dim ui64 As UInt64
        Dim i32 As Integer
        Dim nn As Integer
        Dim Elf As New ELFFile
        Dim sym As Symbol
        Dim elfsyms() As Elf64Symbol

        ELFSections(0) = New ELFSection
        ELFSections(1) = New ELFSection
        ELFSections(2) = New ELFSection
        ELFSections(3) = New ELFSection
        ELFSections(4) = New ELFSection
        ELFSections(5) = New ELFSection

        ELFSections(0).hdr.sh_name = NameTable.AddName(".text")
        ELFSections(0).hdr.sh_type = Elf64Shdr.SHT_PROGBITS
        ELFSections(0).hdr.sh_flags = Elf64Shdr.SHF_ALLOC Or Elf64Shdr.SHF_EXECINSTR
        ELFSections(0).hdr.sh_addr = 4096
        ELFSections(0).hdr.sh_offset = 512  ' offset in file
        ELFSections(0).hdr.sh_size = cbindex * 8
        ELFSections(0).hdr.sh_link = 0
        ELFSections(0).hdr.sh_info = 0
        ELFSections(0).hdr.sh_addralign = 1
        ELFSections(0).hdr.sh_entsize = 0
        For nn = 0 To cbindex - 1
            ELFSections(0).Add(codebytes(nn))
        Next

        ELFSections(1).hdr.sh_name = NameTable.AddName(".data")
        ELFSections(1).hdr.sh_type = Elf64Shdr.SHT_PROGBITS
        ELFSections(1).hdr.sh_flags = Elf64Shdr.SHF_ALLOC Or Elf64Shdr.SHF_WRITE
        ELFSections(1).hdr.sh_addr = 4096
        ELFSections(1).hdr.sh_offset = 512 + cbindex * 8  ' offset in file
        ELFSections(1).hdr.sh_size = dbindex * 8
        ELFSections(1).hdr.sh_link = 0
        ELFSections(1).hdr.sh_info = 0
        ELFSections(1).hdr.sh_addralign = 1
        ELFSections(1).hdr.sh_entsize = 0
        For nn = 0 To dbindex - 1
            ELFSections(0).Add(databytes(nn))
        Next

        ELFSections(2).hdr.sh_name = NameTable.AddName(".bss")
        ELFSections(2).hdr.sh_type = Elf64Shdr.SHT_PROGBITS
        ELFSections(2).hdr.sh_flags = Elf64Shdr.SHF_ALLOC Or Elf64Shdr.SHF_WRITE
        ELFSections(2).hdr.sh_addr = bssStart
        ELFSections(2).hdr.sh_offset = 512 + cbindex * 8 + dbindex * 8  ' offset in file
        ELFSections(2).hdr.sh_size = 0
        ELFSections(2).hdr.sh_link = 0
        ELFSections(2).hdr.sh_info = 0
        ELFSections(2).hdr.sh_addralign = 8
        ELFSections(2).hdr.sh_entsize = 0

        ELFSections(3).hdr.sh_name = NameTable.AddName(".tls")
        ELFSections(3).hdr.sh_type = Elf64Shdr.SHT_PROGBITS
        ELFSections(3).hdr.sh_flags = Elf64Shdr.SHF_ALLOC Or Elf64Shdr.SHF_WRITE
        ELFSections(3).hdr.sh_addr = tlsStart
        ELFSections(3).hdr.sh_offset = 512 + cbindex * 8 + dbindex * 8  ' offset in file
        ELFSections(3).hdr.sh_size = 0
        ELFSections(3).hdr.sh_link = 0
        ELFSections(3).hdr.sh_info = 0
        ELFSections(3).hdr.sh_addralign = 8
        ELFSections(3).hdr.sh_entsize = 0

        ELFSections(4).hdr.sh_name = NameTable.AddName(".strtab")
        ELFSections(4).hdr.sh_type = Elf64Shdr.SHT_STRTAB
        ELFSections(4).hdr.sh_flags = 0
        ELFSections(4).hdr.sh_addr = 0
        ELFSections(4).hdr.sh_offset = 512 + cbindex * 8 + dbindex * 8  ' offset in file
        ELFSections(4).hdr.sh_size = NameTable.length
        ELFSections(4).hdr.sh_link = 0
        ELFSections(4).hdr.sh_info = 0
        ELFSections(4).hdr.sh_addralign = 1
        ELFSections(4).hdr.sh_entsize = 0
        For nn = 0 To NameTable.length - 1
            ELFSections(4).Add(NameTable.text(nn))
        Next

        ELFSections(5).hdr.sh_name = NameTable.AddName(".symtab")
        ELFSections(5).hdr.sh_type = Elf64Shdr.SHT_SYMTAB
        ELFSections(5).hdr.sh_flags = 0
        ELFSections(5).hdr.sh_addr = 0
        ELFSections(5).hdr.sh_offset = Round512(512 + cbindex * 8 + dbindex * 8 + NameTable.length)  ' offset in file
        ELFSections(5).hdr.sh_size = (symbols.Count + 1) * 24
        ELFSections(5).hdr.sh_link = 4
        ELFSections(5).hdr.sh_info = 0
        ELFSections(5).hdr.sh_addralign = 1
        ELFSections(5).hdr.sh_entsize = 0


        ReDim elfsyms(symbols.Count)
        nn = 1
        ' The first entry is an NULL symbol
        elfsyms(0) = New Elf64Symbol
        elfsyms(0).st_name = 0
        elfsyms(0).st_info = 0
        elfsyms(0).st_other = 0
        elfsyms(0).st_shndx = 0
        elfsyms(0).st_value = 0
        elfsyms(0).st_size = 0
        ELFSections(5).Add(elfsyms(0))
        For Each sym In symbols
            elfsyms(nn) = New Elf64Symbol
            elfsyms(nn).st_name = sym.name
            If sym.scope = "Pub" Then
                elfsyms(nn).st_info = Elf64Symbol.STB_GLOBAL << 4
            Else
                elfsyms(nn).st_info = 0
            End If
            elfsyms(nn).st_other = 0    ' reserved
            Select Case sym.segment
                Case "code"
                    elfsyms(nn).st_shndx = 0
                Case "data"
                    elfsyms(nn).st_shndx = 1
                Case "bss"
                    elfsyms(nn).st_shndx = 2
                Case "tls"
                    elfsyms(nn).st_shndx = 3
                Case Else
                    elfsyms(nn).st_shndx = 0
            End Select
            If sym.type = "C" Then
                elfsyms(nn).st_value = sym.value
            Else
                elfsyms(nn).st_value = sym.address
            End If
            elfsyms(nn).st_size = 8
            ELFSections(5).Add(elfsyms(nn))
            nn = nn + 1
        Next
        If nn <> symbols.Count Then
            Console.WriteLine("Mismatch: " & nn & "vs " & symbols.Count)
        End If

        NumSections = 6
        Elf.hdr.e_ident(0) = 127
        Elf.hdr.e_ident(1) = Asc("E")
        Elf.hdr.e_ident(2) = Asc("L")
        Elf.hdr.e_ident(3) = Asc("F")
        Elf.hdr.e_ident(4) = eh.ELFCLASS64 ' 64 bit file format
        Elf.hdr.e_ident(5) = eh.ELFDATA2LSB   ' little endian
        Elf.hdr.e_ident(6) = 1      ' header version always 1
        Elf.hdr.e_ident(7) = 255    ' OS/ABI indentification, 255 = standalone
        Elf.hdr.e_ident(8) = 255    ' ABI version
        Elf.hdr.e_ident(9) = 0
        Elf.hdr.e_ident(10) = 0
        Elf.hdr.e_ident(11) = 0
        Elf.hdr.e_ident(12) = 0
        Elf.hdr.e_ident(13) = 0
        Elf.hdr.e_ident(14) = 0
        Elf.hdr.e_ident(15) = 0
        Elf.hdr.e_type = 2
        Elf.hdr.e_machine = 64      ' machine architecture
        Elf.hdr.e_version = 1
        Elf.hdr.e_entry = 4052
        Elf.hdr.e_phoff = 0
        Elf.hdr.e_shoff = Round512(512 + cbindex * 8 + dbindex * 8 + NameTable.length) + (symbols.Count + 1) * 24
        Console.WriteLine(Hex(Elf.hdr.e_shoff))
        Elf.hdr.e_flags = 0
        Elf.hdr.e_ehsize = Elf.hdr.Elf64HdrSz
        Elf.hdr.e_phentsize = 0
        Elf.hdr.e_phnum = 0
        Elf.hdr.e_shentsize = Elf64Shdr.Elf64ShdrSz
        Elf.hdr.e_shnum = 6
        Elf.hdr.e_shstrndx = 4  ' index into section table of string table header

        Elf.Write()
        Return

        ' Write ELF header
        'byt = 127
        'efs.Write(byt)
        'byt = Asc("E")
        'efs.Write(byt)
        'byt = Asc("L")
        'efs.Write(byt)
        'byt = Asc("F")
        'efs.Write(byt)
        'byt = eh.ELFCLASS64 ' 64 bit file format
        'efs.Write(byt)
        'byt = eh.ELFDATA2LSB    ' little endian
        'efs.Write(byt)
        'byt = 1             ' header version, always 1
        'efs.Write(byt)
        'byt = 255           ' OS/ABI identification, 255 = standalone
        'efs.Write(byt)
        'efs.Write(byt)      ' OS/ABI version
        'byt = 0
        'efs.Write(byt)  ' reserved bytes
        'efs.Write(byt)
        'efs.Write(byt)
        'efs.Write(byt)
        'efs.Write(byt)
        'efs.Write(byt)
        'efs.Write(byt)
        'efs.Write(System.UInt32.Parse("2"))     ' type
        'efs.Write(System.UInt32.Parse("64"))    ' machine architecture
        'efs.Write(UInt64.Parse("1"))        ' version
        'ui64 = UInt64.Parse("0")            ' progam entry point
        'efs.Write(ui64)
        'efs.Write(Convert.ToUInt64(160))
        'ui64 = UInt64.Parse(0)
        'efs.Write(ui64)
        'efs.Write(ui64)                     ' flags
        'ui32 = UInt32.Parse(Elf64Header.Elf64HdrSz.ToString())  ' ehsize
        'efs.Write(ui32)
        'ui32 = UInt32.Parse("64")           ' phentsize
        'efs.Write(ui32)
        'efs.Write(UInt32.Parse("4"))        ' number of program header entries
        'efs.Write(UInt32.Parse("0"))        ' shentsize
        'efs.Write(UInt32.Parse("0"))        ' number of section header entries
        'efs.Write(UInt32.Parse("0"))        ' section string table index

        '' write code segment header
        'efs.Seek(160, IO.SeekOrigin.Begin)
        'efs.Write(Convert.ToUInt64(1))        ' Loadable code
        'efs.Write(Convert.ToUInt64(1))        ' execute only
        'efs.Write(Convert.ToUInt64(512))      ' offset of segment in file
        'efs.Write(UInt64.Parse("4096"))     ' virtual address
        'efs.Write(Convert.ToUInt64(0))        ' physical address (not used)
        'i32 = cbindex * 8
        'efs.Write(UInt64.Parse(i32.ToString))   ' size of segment in file
        'efs.Write(UInt64.Parse(i32.ToString))   ' size of segment in memory
        'efs.Write(Convert.ToUInt64(4))     ' alignment of segment

        '' write data segment header
        'efs.Write(Convert.ToUInt64(1))        ' Loadable code
        'efs.Write(Convert.ToUInt64(6))        ' read/write only
        'i32 = 512 + cbindex * 8
        'efs.Write(UInt64.Parse(i32.ToString))      ' offset of segment in file
        'efs.Write(UInt64.Parse("4096"))     ' virtual address
        'efs.Write(Convert.ToUInt64(0))        ' physical address (not used)
        'i32 = dbindex * 8
        'efs.Write(UInt64.Parse(i32.ToString))   ' size of segment in file
        'efs.Write(UInt64.Parse(i32.ToString))   ' size of segment in memory
        'efs.Write(Convert.ToUInt64(8))     ' alignment of segment

        '' write bss segment header
        'efs.Write(Convert.ToUInt64(1))        ' Loadable code
        'efs.Write(Convert.ToUInt64(6))        ' read/write only
        'efs.Write(Convert.ToUInt64(512 + cbindex * 8 + dbindex * 8))      ' offset of segment in file
        'efs.Write(Convert.ToUInt64(bssStart))     ' virtual address
        'efs.Write(Convert.ToUInt64(0))        ' physical address (not used)
        'efs.Write(Convert.ToUInt64(0))   ' size of segment in file
        'efs.Write(Convert.ToUInt64(bssEnd - bssStart))   ' size of segment in memory
        'efs.Write(Convert.ToUInt64(8))     ' alignment of segment

        '' write tls segment header
        'efs.Write(Convert.ToUInt64(1))        ' Loadable code
        'efs.Write(Convert.ToUInt64(6))        ' read/write only
        'efs.Write(Convert.ToUInt64(512 + cbindex * 8 + dbindex * 8))      ' offset of segment in file
        'efs.Write(Convert.ToUInt64(tlsStart))     ' virtual address
        'efs.Write(Convert.ToUInt64(0))        ' physical address (not used)
        'efs.Write(Convert.ToUInt64(0))   ' size of segment in file
        'efs.Write(Convert.ToUInt64(tlsEnd - tlsStart))   ' size of segment in memory
        'efs.Write(Convert.ToUInt64(8))     ' alignment of segment

        'efs.Seek(512, IO.SeekOrigin.Begin)
        'For i32 = 0 To cbindex - 1
        '    efs.Write(codebytes(i32))
        'Next
        'For i32 = 0 To dbindex - 1
        '    efs.Write(databytes(i32))
        'Next
        'efs.Close()
        'eh.e_ident(0) = Chr(127)
        'eh.e_ident(1) = "E"
        'eh.e_ident(2) = "L"
        'eh.e_ident(3) = "F"
        'eh.e_ident(4) = Chr(eh.ELFCLASS64)  ' 64 bit file
        'eh.e_ident(5) = Chr(eh.ELFDATA2LSB) ' little endian
        'eh.e_ident(6) = Chr(1)              ' file version
        'eh.e_ident(7) = Chr(255)            ' standalone (embedded ABI/OS)
        'eh.e_ident(8) = Chr(0)              ' ABI version
        'eh.e_ident(9) = Chr(0)
        'eh.e_ident(10) = Chr(0)
        'eh.e_ident(11) = Chr(0)
        'eh.e_ident(12) = Chr(0)
        'eh.e_ident(13) = Chr(0)
        'eh.e_ident(14) = Chr(0)
        'eh.e_ident(15) = Chr(0)
        'eh.e_type = 2               ' executable file
        'eh.e_machine = 64           ' machine type (choosen at random)
        'eh.e_version = 1            ' object file format version
        'eh.e_entry = 0          ' code entry point - should get this from 'start'
        'eh.e_phoff = 160
        'eh.e_shoff = 0          ' no sections
        'eh.e_flags = 0          ' processor specific flags
        'eh.e_phentsize = Elf64Phdr.Elf64pHdrSz
        'eh.e_phnum = 3          ' 3 segments
        'eh.e_shentsize = 0      ' not used
        'eh.e_shnum = 0          ' not used
        'eh.e_shstrndx = 0       ' not used
    End Sub

    Sub WriteBinaryFile()
        Dim i32 As Int32

        For i32 = 0 To cbindex - 1
            bfs.Write(codebytes(i32))
        Next
        For i32 = 0 To dbindex - 1
            bfs.Write(databytes(i32))
        Next
        bfs.Close()
    End Sub

    Public Sub WriteSectionNameTable()
        sectionNameTableOffset = efs.BaseStream.Position
        efs.Write(sectionNameStringTable, 0, sectionNameTableSize)
    End Sub

    Public Sub WriteSectionNameHeader()
        efs.Write(Convert.ToUInt32(sectionNameTableOffset))   ' index to section name table
    End Sub

End Module
