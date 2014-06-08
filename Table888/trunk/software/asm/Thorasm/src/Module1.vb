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
    Dim symbols As New MyCollection
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
    Dim processor As String
    Dim lastLabel As String
    Dim doingDB As Boolean
    Public lineno As Integer

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
    Dim insnBundle As New clsBundle
    Dim bundleCnt As Integer
    Dim sa As Int64
    Dim dsa As Int64
    Dim plbl As Boolean
    Public NumSections As Integer
    Public ELFSections(10) As ELFSection
    Public SearchList As Collection
    Public TextSnippets As Collection
    Public segreg As Integer
    Public binbuf As New binfile
    Public firstCodeOrg As Boolean

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
        Dim iter As Integer

        'textfile = fl.ReadToEnd()
        'fl.Close()
        'currentFl = fl
        processor = "Table888"
        bundleCnt = 0

        If args.Length < 1 Then
            Console.WriteLine("Thorasm v1.1")
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
            lineno = 1
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
            firstCodeOrg = True
            doingDB = False
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
            'While (address Mod 4)
            '    emitbyte(0, False)
            'End While
            emitbyte(0, False)
            emitbyte(0, False)
            emitbyte(0, False)
            emitbyte(0, False)
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
                For iter = 0 To 1000000
                    L = symbols.Find(iter)
                    If L Is Nothing Then GoTo j2

                    If L.defined = False Then
                        foundAllSyms = False
                        ' "Promote" an undefined symbol to the global level.
                        ' It's either an external reference or an error.
                        symbols.Remove(L.name)
                        snam = "0" & TrimLeadingDigits(NameTable.GetName(L.name))
                        Try
                            M = symbols.Item(NameTable.FindName(snam))
                        Catch
                            M = Nothing
                        End Try
                        If M Is Nothing Then
                            L.name = NameTable.AddName(snam)
                            symbols.Add(L, L.name)
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
j2:
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
        Dim sg As Integer
        Dim nn As Integer

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
            segreg = 1
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
                        nn = s.IndexOf(":")
                        If nn >= 0 Then
                            sg = GetSegRegister(s.Substring(0, nn))
                            If sg >= 0 Then
                                segreg = sg
                                s = s.Substring(nn + 1)
                                strs(0) = s
                            End If
                        End If
                        If Not processedPredicate Then
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
                            'emitbyte(0, True)
                        End If
                        If s <> "fill.c" And last_op = "fill.c" Then
                            'emitchar(0, True)
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
                                ProcessLdi(s, &H16)
                            Case "addi"
                                ProcessRIOp(s, &H4)
                            Case "addui"
                                ProcessRIOp(s, &H14)
                            Case "subi"
                                ProcessRIOp(s, &H5)
                            Case "subui"
                                ProcessRIOp(s, &H15)
                            Case "cmpi"
                                ProcessRIOp(s, &H6)
                            Case "andi"
                                ProcessRIOp(s, &HC)
                            Case "ori"
                                ProcessRIOp(s, &HD)
                            Case "eori"
                                ProcessRIOp(s, &HE)
                            Case "mului"
                                ProcessRIOp(s, &H17)
                            Case "muli"
                                ProcessRIOp(s, &H7)
                            Case "divui"
                                ProcessRIOp(s, &H18)
                            Case "divi"
                                ProcessRIOp(s, &H8)
                            Case "modi"
                                ProcessRIOp(s, &H9)
                            Case "modui"
                                ProcessRIOp(s, &H19)

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
                            Case "ld"
                                ProcessMemoryOp(s, &H86)
                            Case "bmld"
                                ProcessMemoryOp(s, &HB7, True)
                            Case "sb"
                                ProcessMemoryOp(s, &HA0)
                            Case "sc"
                                ProcessMemoryOp(s, &HA1)
                            Case "sh"
                                ProcessMemoryOp(s, &HA2)
                            Case "sw"
                                ProcessMemoryOp(s, &HA3)
                            Case "st"
                                ProcessMemoryOp(s, &HA3)
                            Case "bmst"
                                ProcessMemoryOp(s, &HB8, True)
                            Case "cinv"
                                ProcessMemoryOp(s, &HA4)
                            Case "lidt"
                                ProcessLidtOp(s, &H90)
                            Case "lgdt"
                                ProcessLidtOp(s, &H91)
                            Case "sidt"
                                ProcessLidtOp(s, &HB0)
                            Case "sgdt"
                                ProcessLidtOp(s, &HB1)
                            Case "lea"
                                ProcessMemoryOp(s, &H4C)
                            Case "stbc"
                                ProcessMemoryOp(s, 54)
                            Case "smr"
                                ProcessSmr(s, &H30)
                            Case "lmr"
                                ProcessSmr(s, &H31)
                            Case "bms"
                                ProcessBitmapOp(s, &HB4)
                            Case "bmc"
                                ProcessBitmapOp(s, &HB5)
                            Case "bmf"
                                ProcessBitmapOp(s, &HB6)

                            Case "push"
                                ProcessPush(&HA6)
                            Case "pop"
                                ProcessPush(&HA7)

                                ' branches
                            Case "brz"
                                ProcessBra(s, &H58)
                            Case "brnz"
                                ProcessBra(s, &H59)
                            Case "brmi"
                                ProcessBra(s, &H44)
                            Case "brpl"
                                ProcessBra(s, &H45)
                            Case "brodd"
                                ProcessBra(s, &H4E)
                            Case "brevn"
                                ProcessBra(s, &H4F)
                            Case "dbnz"
                                ProcessBra(s, &H5A)
                            Case "beq"
                                ProcessBra(s, &H40)
                            Case "bne"
                                ProcessBra(s, &H41)
                            Case "bvs"
                                ProcessBra(s, &H42)
                            Case "bvc"
                                ProcessBra(s, &H43)
                            Case "bmi"
                                ProcessBra(s, &H44)
                            Case "bpl"
                                ProcessBra(s, &H45)
                            Case "bra"
                                ProcessBra(s, &H46)
                            Case "br"
                                ProcessBra(s, &H46)
                            Case "brn"
                                ProcessBra(s, &H47)
                            Case "bgt"
                                ProcessBra(s, &H48)
                            Case "ble"
                                ProcessBra(s, &H49)
                            Case "bge"
                                ProcessBra(s, &H4A)
                            Case "blt"
                                ProcessBra(s, &H4B)
                            Case "bhi"
                                ProcessBra(s, &H4C)
                            Case "bls"
                                ProcessBra(s, &H4D)
                            Case "bhs"
                                ProcessBra(s, &H4E)
                            Case "blo"
                                ProcessBra(s, &H4F)
                            Case "bsr"
                                ProcessBsr(s, &H56)

                                ' R
                            Case "mov"
                                ProcessROp(s, 4)
                            Case "com"
                                ProcessROp(s, 6)
                            Case "not"
                                ProcessROp(s, &H7)
                            Case "neg"
                                ProcessROp(s, &H5)
                            Case "sxb"
                                ProcessROp(s, &H8)
                            Case "sxc"
                                ProcessROp(s, &H9)
                            Case "sxh"
                                ProcessROp(s, &HA)
                            Case "mtspr"
                                ProcessMtspr(s, &H48)
                            Case "mfspr"
                                ProcessMfspr(s, &H49)
                            Case "mtseg"
                                ProcessMtseg(s, &HC)
                            Case "mfseg"
                                ProcessMfseg(s, &HD)
                            Case "lsb"
                                ProcessMfseg(s, &H12)
                            Case "swap"
                                ProcessROp(s, 3)
                            Case "gran"
                                ProcessGran(s, &H14)

                                ' RR
                            Case "add"
                                ProcessRROp(s, &H4)
                            Case "addu"
                                ProcessRROp(s, &H14)
                            Case "sub"
                                ProcessRROp(s, &H5)
                            Case "subu"
                                ProcessRROp(s, &H15)
                            Case "cmp"
                                ProcessRROp(s, &H6)
                            Case "and"
                                ProcessRROp(s, &H20)
                            Case "nand"
                                ProcessRROp(s, &H24)
                            Case "or"
                                ProcessRROp(s, &H21)
                            Case "eor"
                                ProcessRROp(s, &H22)
                            Case "andn"
                                ProcessRROp(s, &H23)
                            Case "mulu"
                                ProcessRROp(s, &H17)
                            Case "mul"
                                ProcessRROp(s, &H7)
                            Case "divu"
                                ProcessRROp(s, &H18)
                            Case "div"
                                ProcessRROp(s, &H8)
                            Case "modu"
                                ProcessRROp(s, &H19)
                            Case "mod"
                                ProcessRROp(s, &H9)
                            Case "shl"
                                ProcessRROp(s, &H40)
                            Case "shr"
                                ProcessRROp(s, &H42)
                            Case "rol"
                                ProcessRROp(s, &H41)
                            Case "ror"
                                ProcessRROp(s, &H43)
                            Case "asr"
                                ProcessRROp(s, &H44)

                            Case "shli"
                                ProcessShiftiOp(s, &H50)
                            Case "shri"
                                ProcessShiftiOp(s, &H52)
                            Case "roli"
                                ProcessShiftiOp(s, &H51)
                            Case "asri"
                                ProcessShiftiOp(s, &H54)
                            Case "rori"
                                ProcessShiftiOp(s, &H53)

                            Case "jmp"
                                ProcessJmp(s, &H50)
                            Case "jsr"
                                ProcessJmp(s, &H51)
                            Case "jgr"
                                ProcessJgr(s, &H57)
                            Case "rts"
                                ProcessRtsOp(s, &H60)

                            Case "rti"
                                ProcessRti(&H40)
                            Case "brk"
                                ProcessBRK(s, &H0)

                            Case "nop"
                                ProcessNop(s, &HEA)

                            Case "cli"
                                processCLI(&H31)
                            Case "sei"
                                processCLI(&H30)
                            Case "php"
                                processCLI(&H32)
                            Case "plp"
                                processCLI(&H33)
                            Case "icache_on"
                                processCLI(&H34)
                            Case "icache_off"
                                processCLI(&H35)
                            Case "prot"
                                processCLI(&H36)
                            Case "segon"
                                processCLI(&H37)
                            Case "mrk1"
                                processCLI(&HF0)
                            Case "mrk2"
                                processCLI(&HF1)
                            Case "mrk3"
                                processCLI(&HF2)
                            Case "mrk4"
                                processCLI(&HF3)

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
                    'WriteListing()
                End If
j3:
            End If
            lineno = lineno + 1
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
        Static lastIline As String

        If pass = maxpass And Not plbl Then
            If segment = "data" Then
                lfs.Write(Hex(dsa).PadLeft(8, "0") & vbTab)
            Else
                lfs.Write(Hex(sa).PadLeft(8, "0") & vbTab)
            End If
            For xx = 1 To bytn
                lfs.Write(Right(Hex(bytesbuf(xx - 1)).PadLeft(2, "0"), 2) & " ")
            Next
            If iline <> lastIline Then
                If bytn < 9 Then
                    lfs.WriteLine(Space(16 - bytn * 2) & iline)
                Else
                    lfs.WriteLine(Space(1) & iline)
                End If
            Else
                lfs.WriteLine("")
            End If
            sa = sa + bytn
            lastIline = iline
        End If
    End Sub

    Sub DumpSymbols()
        Dim sym As Symbol
        Dim ii As Integer
        Dim symseg As String

        lfs.WriteLine(" ")
        lfs.WriteLine(" ")
        lfs.WriteLine("Symbol Table:")
        lfs.WriteLine("================================================================")
        lfs.WriteLine("Name                   Typ  Segment     Scope   Address/Value")
        lfs.WriteLine("----------------------------------------------------------------")
        For ii = 0 To symbols.Size - 1
            sym = symbols.Item(ii)
            If sym Is Nothing Then GoTo j1
            If sym.segment Is Nothing Then
                symseg = "<nothing>"
            Else
                symseg = sym.segment
            End If
            If sym.type = "L" Then
                If symseg = "code" Then
                    lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & sym.segment.PadRight(8) & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                Else
                    If sym.defined Then
                        lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & symseg.PadRight(8) & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                    Else
                        lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & "undef" & vbTab & " " & sym.scope.PadRight(3, " ") & " " & vbTab & Hex(sym.address).PadLeft(16, "0"))
                    End If
                End If
            Else
                lfs.WriteLine(NameTable.GetName(sym.name).PadRight(20, " ") & vbTab & sym.type & vbTab & sym.segment.PadRight(8) & vbTab & "      " & vbTab & Hex(sym.value).PadLeft(16, "0"))
            End If
j1:
        Next
    End Sub

    Sub ProcessFill(ByVal s As String)
        Dim numbytes As Int64
        Dim FillByte As Int64
        Dim n As Int64

        Select Case s
            Case "fill.b"
                numbytes = eval(strs(1))
                FillByte = eval(strs(2))
                For n = 0 To numbytes - 1
                    emitbyte(FillByte, False)
                Next
                ' emitbyte(0, True)
            Case "fill.c"
                numbytes = eval(strs(1))
                FillByte = eval(strs(2))
                For n = 0 To numbytes - 1
                    emitchar(FillByte, False)
                Next
                'emitchar(0, True)
            Case "fill.w"
                numbytes = eval(strs(1))
                FillByte = eval(strs(2))
                For n = 0 To numbytes - 1
                    emitword(FillByte, False)
                Next
                'emitword(0, True)
        End Select
    End Sub

    Sub processCLI(ByVal oc As Int64)
        emitAlignedCode(1)
        emitCode(0)
        emitCode(0)
        emitCode(0)
        emitCode(oc)
    End Sub

    Sub ProcessPush(ByVal oc As Int64)
        Dim s As String()
        Dim n As Integer
        Dim ra As Int64
        Dim r As Int64
        Dim offset As Int64

        emitAlignedCode(oc)
        If strs(1).StartsWith("[") Then
            strs(1) = strs(1).TrimStart("[".ToCharArray)
            strs(1) = strs(1).TrimEnd("]".ToCharArray)
        End If
        s = Split(strs(1), "/")
        For n = 0 To s.Length - 1
            r = GetRegister(s(n))
            emitCode(r)
        Next
        While (n < 4)
            emitCode(0)
            n = n + 1
        End While
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
        Dim isLocal As Boolean

        s = s.TrimEnd(":")
        isLocal = s.Chars(0) = "."
        nm = s
        If isLocal Then
            nm = lastLabel & nm
        Else
            lastLabel = nm
        End If
        L.segment = segment
        L.fileno = fileno
        If publicFlag Then
            L.scope = "Pub"
            L.fileno = 0
        End If
        '        L.name = CStr(L.fileno) & L.name
        Select Case segment
            Case "code"
                While (address And 15) <> 0 And (address And 15) <> 5 And (address And 15) <> 10
                    emitCode(0)
                End While
                If ((address And 15) = 15) Then
                    L.address = address + 1
                Else
                    L.address = address
                End If
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
                M = symbols.Item(NameTable.FindName(fileno & nm))
            Catch
                Try
                    M = symbols.Item(NameTable.FindName("0" & nm))
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
            symbols.Add(L, L.name)
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

    Sub ProcessAlign()
        Dim n As Int64
        Dim na As Int64

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
                'While slot <> 0
                '                    slot = (slot + 1) Mod 3
                'emit(&H37800000000L)    ' nop
                'End While
                'End If
                na = address + n + n
                While address Mod n And address < na
                    emitbyte(&HEA, False)
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

    Sub ProcessDB()
        Dim n As Integer
        Dim m As Integer
        Dim k As Int64
        Dim ch As Char

        doingDB = True
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
        doingDB = False
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
                    emitword(eval(Mid(strs(m), n)), False)
                    Exit While
                End If
            End While
        Next
        'emitbyte(0, True)
    End Sub

    ' rti and rte
    Sub ProcessRti(ByVal oc As Int64)
        emitAlignedCode(1)
        emitCode(0)
        emitCode(0)
        emitCode(0)
        emitCode(oc)
    End Sub

    Function bit(ByVal v As Int64, ByVal b As Int64) As Integer
        Dim i As Int64

        i = (v >> b) And 1L
        Return i
    End Function

    Sub ProcessLdi(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        imm = eval(strs(2))

        If imm < &HFFFFFFFFFF800000L Or imm > &H7FFFFF Then
            emitImm24(imm)
        End If
        emitAlignedCode(oc)
        emitCode(rt)
        emitCode(imm)
        emitCode((imm >> 8) And 255)
        emitCode((imm >> 16) And 255)
    End Sub

    Sub ProcessRIOp(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
 
        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))

        If imm < -32768 Or imm > 32767 Then
            emitImm16(imm)
        End If
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(rt)
        emitCode(imm And 255)
        emitCode((imm >> 8) And 255)
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

    Sub emitImm14(ByVal imm As Int64)
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= &HFFFFFE0000000000L And imm < &H1FFFFFFFFFFL Then
            emitAlignedCode(&HFD)
            emitCode(imm >> 14)
            emitCode((imm >> 22) And 255)
            emitCode((imm >> 30) And 255)
            emitCode(((imm >> 38) And 15) Or (segreg << 4))
        Else
            emitAlignedCode(&HFD)
            emitCode(imm >> 14)
            emitCode((imm >> 22) And 255)
            emitCode((imm >> 30) And 255)
            emitCode((imm >> 38) And 255)
            emitAlignedCode(&HFE)
            emitCode(imm >> 46)
            emitCode((imm >> 54) And 255)
            emitCode((imm >> 62) And 255)
            emitCode(segreg << 4)
        End If
        iline = str
        bytn = 0
        sa = address
    End Sub

    Sub emitImm16(ByVal imm As Int64)
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= &HFFFF800000000000L And imm < &H7FFFFFFFFFFFL Then
            emitAlignedCode(&HFD)
            emitCode(imm >> 16)
            emitCode((imm >> 24) And 255)
            emitCode((imm >> 32) And 255)
            emitCode((imm >> 40) And 255)
        Else
            emitAlignedCode(&HFD)
            emitCode(imm >> 16)
            emitCode((imm >> 24) And 255)
            emitCode((imm >> 32) And 255)
            emitCode((imm >> 40) And 255)
            emitAlignedCode(&HFE)
            emitCode(imm >> 48)
            emitCode((imm >> 56) And 255)
            emitCode(0)
            emitCode(0)
        End If
        iline = str
        bytn = 0
        sa = address
    End Sub

    Sub emitImm4(ByVal imm As Int64)
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= &HFFFFFFF800000000L And imm < &H7FFFFFFFFL Then
            emitAlignedCode(&HFD)
            emitCode(imm >> 4)
            emitCode((imm >> 12) And 255)
            emitCode((imm >> 20) And 255)
            emitCode(((imm >> 28) And 15) Or (segreg << 4))
        Else
            emitAlignedCode(&HFD)
            emitCode(imm >> 4)
            emitCode((imm >> 12) And 255)
            emitCode((imm >> 20) And 255)
            emitCode((imm >> 28) And 255)
            emitAlignedCode(&HFE)
            emitCode(imm >> 36)
            emitCode((imm >> 44) And 255)
            emitCode((imm >> 52) And 255)
            emitCode(((imm >> 60) And 15) Or (segreg << 4))
        End If
        iline = str
        bytn = 0
        sa = address
    End Sub

    Sub emitImm6(ByVal imm As Int64)
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= &HFFFFFFE000000000L And imm < &H1FFFFFFFFFL Then
            emitAlignedCode(&HFD)
            emitCode(imm >> 6)
            emitCode((imm >> 14) And 255)
            emitCode((imm >> 22) And 255)
            emitCode((imm >> 30) And 255)
        Else
            emitAlignedCode(&HFD)
            emitCode(imm >> 6)
            emitCode((imm >> 14) And 255)
            emitCode((imm >> 22) And 255)
            emitCode((imm >> 30) And 255)
            emitAlignedCode(&HFE)
            emitCode(imm >> 38)
            emitCode((imm >> 46) And 255)
            emitCode((imm >> 54) And 255)
            emitCode((imm >> 62) And 255)
        End If
        iline = str
        bytn = 0
        sa = address
    End Sub
    Sub emitImm24(ByVal imm As Int64, Optional ByVal addseg As Boolean = False)
        Dim str As String

        If imm >= &HFFFFFFFFFF800000 And imm <= &H7FFFFF And Not addseg Then
            Return
        End If
        str = iline
        iline = "; imm "
        If addseg Then
            If imm >= &HFFF8000000000000L And imm < &H7FFFFFFFFFFFFL Then
                emitAlignedCode(&HFD)
                emitCode(imm >> 24)
                emitCode((imm >> 32) And 255)
                emitCode((imm >> 40) And 255)
                emitCode(((imm >> 48) And 15) Or (segreg << 4))
            Else
                emitAlignedCode(&HFD)
                emitCode(imm >> 24)
                emitCode((imm >> 32) And 255)
                emitCode((imm >> 40) And 255)
                emitCode((imm >> 48) And 255)
                emitAlignedCode(&HFE)
                emitCode(imm >> 56)
                emitCode(0)
                emitCode(0)
                emitCode(segreg << 4)
            End If
        Else
            If imm >= &HFF80000000000000L And imm < &H7FFFFFFFFFFFFFL Then
                emitAlignedCode(&HFD)
                emitCode(imm >> 24)
                emitCode((imm >> 32) And 255)
                emitCode((imm >> 40) And 255)
                emitCode((imm >> 48) And 255)
            Else
                emitAlignedCode(&HFD)
                emitCode(imm >> 24)
                emitCode((imm >> 32) And 255)
                emitCode((imm >> 40) And 255)
                emitCode((imm >> 48) And 255)
                emitAlignedCode(&HFE)
                emitCode(imm >> 56)
                emitCode(0)
                emitCode(0)
                emitCode(0)
            End If
        End If
        iline = str
        bytn = 0
        sa = address
    End Sub
    Sub emitImm32(ByVal imm As Int64)
        Dim str As String

        str = iline
        iline = "; imm "
        emitAlignedCode(&HFD)
        emitCode(imm >> 32)
        emitCode((imm >> 40) And 255)
        emitCode((imm >> 48) And 255)
        emitCode((imm >> 56) And 255)
        iline = str
        bytn = 0
        sa = address
    End Sub
    Sub emitIMM2(ByVal imm As Int64)
        Dim opcode As Int64
        Dim str As String

        str = iline
        iline = "; imm "
        If imm >= &HFFFF800000000000L And imm < &H7FFFFFFFFFFFL Then
            emitbyte(&HFD, False)
            emitbyte(imm >> 8, False)
            emitbyte((imm >> 16) And 255, False)
            emitbyte((imm >> 24) And 255, False)
            emitbyte((imm >> 32) And 255, False)
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
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub
    '
    '
    Sub ProcessMtspr(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSprRegister(strs(1))
        ra = GetRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub
    Sub ProcessMtseg(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSegRegister(strs(1))
        ra = GetRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub
    '
    '
    Sub ProcessMfspr(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetSprRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub
    Sub ProcessMfseg(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetSegRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub
    Sub ProcessGran(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        emitAlignedCode(1)
        emitCode(0)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
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

        imm = 0
        If strs.Length > 1 Then
            If strs(1) Is Nothing Then
            Else
                imm = GetImmediate(strs(1), "rts")
            End If
        End If
        emitAlignedCode(oc)
        emitCode(0)
        emitCode(imm And 255)
        emitCode((imm >> 8) And 255)
        emitCode(0)
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
        Dim na As Int64
        Dim s() As String
        Dim str As String

        ' dump any data left over in word buffers

        s = strs(1).Split(".".ToCharArray)
        imm = eval(s(0))
        slot = 0
        Select Case segment
            Case "tls"
                tls_address = imm
            Case "bss"
                bss_address = imm
            Case "code"
                na = address + 64
                'While address Mod 32 And address < na
                '    emitbyte(0, False)
                'End While
                'w0 = 0
                'w1 = 0
                'w2 = 0
                'w3 = 0
                If (imm And 15) <> 0 And (imm And 15) <> 5 And (imm And 15) <> 10 Then
                    Console.WriteLine("Bad origin for code.")
                End If
                If firstCodeOrg Then
                    firstCodeOrg = False
                    address = imm
                    bytn = 0
                    sa = imm
                Else
                    str = iline
                    While address < imm
                        bytn = 0
                        sa = address
                        emitCode(&H0)
                        iline = ""
                    End While
                    iline = str
                End If
            Case "data"
                data_address = imm
        End Select
        emitRaw("")
    End Sub
    '
    '
    Sub ProcessNop(ByVal ops As String, ByVal oc As Int64)
        emitAlignedCode(oc)
        emitCode(oc)
        emitCode(oc)
        emitCode(oc)
        emitCode(oc)
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
                    ProcessRIOp(ops, &H4)
                Case "addu"
                    ProcessRIOp(ops, &H14)
                Case "sub"
                    ProcessRIOp(ops, &H5)
                Case "subu"
                    ProcessRIOp(ops, &H15)
                Case "cmp"
                    ProcessRIOp(ops, &H6)
                Case "and"
                    ProcessRIOp(ops, &HC)
                Case "or"
                    ProcessRIOp(ops, &HD)
                Case "eor"
                    ProcessRIOp(ops, &HE)
                Case "mul"
                    ProcessRIOp(ops, &H7)
                Case "mulu"
                    ProcessRIOp(ops, &H17)
                Case "div"
                    ProcessRIOp(ops, &H8)
                Case "divu"
                    ProcessRIOp(ops, &H18)
                Case "mod"
                    ProcessRIOp(ops, &H9)
                Case "modu"
                    ProcessRIOp(ops, &H19)
                Case "shl"
                    ProcessShiftiOp(ops, &H50)
                Case "shr"
                    ProcessShiftiOp(ops, &H52)
                Case "rol"
                    ProcessShiftiOp(ops, &H51)
                Case "ror"
                    ProcessShiftiOp(ops, &H53)
                Case "asr"
                    ProcessShiftiOp(ops, &H54)
            End Select
            Return
        End If
        emitAlignedCode(2)
        emitCode(ra)
        emitCode(rb)
        emitCode(rt)
        emitCode(fn)
    End Sub
    '
    ' -ops have the form: shri Rt,Ra,#
    '
    Sub ProcessShiftiOp(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))
        emitAlignedCode(2)
        emitCode(ra)
        emitCode(imm And 63)
        emitCode(rt)
        emitCode(fn)
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
        Dim segbits As Int64
        Dim needSegPrefix As Boolean

        If segreg = 1 Then
            segbits = 0
        ElseIf segreg = 3 Then
            segbits = 1
        ElseIf segreg = 5 Then
            segbits = 2
        ElseIf segreg = 14 Then
            segbits = 3
        Else
            segbits = 0
            needSegPrefix = True
        End If

        ra = 0
        If strs(1).StartsWith("(") Then
            s = strs(1).Split(",".ToCharArray)
            If s.Length > 1 Then
                ra = GetRegister(s(1))
            End If
            offset = eval(s(0).Trim("()".ToCharArray))
            If (offset <= &HFFFFFFFFFF800000L Or offset > &H7FFFFF Or needSegPrefix) Then
                emitImm24(offset, True)
            End If
            emitAlignedCode(oc + 2)
            emitCode(ra)
            emitCode((offset And 248) Or segbits)
            emitCode((offset >> 8) And 255)
            emitCode((offset >> 16) And 255)
            Return
        End If
        's = strs(1).Split("(".ToCharArray)
        offset = eval(strs(1))
        ' If s.Length > 1 Then
        's(1) = s(1).TrimEnd(")".ToCharArray)
        'ra = GetBrRegister(s(1))
        'End If
        If (offset < &HFFFFFFFF00000000L Or offset > &HFFFFFFFF) Then
            emitImm32(offset)
        End If
        emitAlignedCode(oc)
        emitCode(offset And 255)
        emitCode((offset >> 8) And 255)
        emitCode((offset >> 16) And 255)
        emitCode((offset >> 24) And 255)
    End Sub

    Sub ProcessJgr(ByVal ops As String, ByVal oc As Int64)
        Dim ra As Int64
        Dim offset As Int64

        offset = eval(strs(1))
        emitAlignedCode(oc)
        emitCode(offset And 255)
        emitCode((offset >> 8) And 255)
        emitCode((offset >> 16) And 255)
        emitCode((offset >> 24) And 255)
    End Sub

    Sub ProcessMemoryOp(ByVal ops As String, ByVal oc As Int64, Optional ByVal ndxOnly As Boolean = False)
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
        Dim segbits As Int64
        Dim needSegPrefix = False

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        If segreg = 1 Then
            segbits = 0
        ElseIf segreg = 3 Then
            segbits = 1
        ElseIf segreg = 5 Then
            segbits = 2
        ElseIf segreg = 14 Then
            segbits = 3
        Else
            segbits = 0
            needSegPrefix = True
        End If


        If (strs.Length < 2) Or strs(2) Is Nothing Then
            Console.WriteLine("Line:" & lineno & " Missing memory operand.")
            Return
        End If
        scale = 1
        rb = -1
        If oc = 54 Or oc = 71 Then
            imm = eval(strs(1))
        Else
            rt = GetRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Or ops = "ld" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                'strs(3) = strs(2)
                'strs(2) = "r0"
                ProcessLdi(ops, &H16)
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
                If s2.Length > 1 Then
                    scale = eval(s2(1))
                End If
            End If
        Else
            ra = 0
        End If
        If rb = -1 And Not ndxOnly Then
            If Not optr26 Then
            Else
                If offset < -8192 Or offset > 8191 Or needSegPrefix Then
                    emitImm14(offset)
                End If
                emitAlignedCode(oc)
                emitCode(ra)
                emitCode(rt)
                emitCode(((offset And 63) << 2) Or segbits)
                emitCode((offset >> 6) And 255)
            End If
        Else
            If rb = -1 Then rb = 0
            Select Case (strs(0))
                Case "lb"
                    oc = &H88
                Case "lbu"
                    oc = &H89
                Case "lc"
                    oc = &H8A
                Case "lcu"
                    oc = &H8B
                Case "lh"
                    oc = &H8C
                Case "lhu"
                    oc = &H8D
                Case "lw"
                    oc = &H8E
                Case "sb"
                    oc = &HA8
                Case "sc"
                    oc = &HA9
                Case "sh"
                    oc = &HAA
                Case "sw"
                    oc = &HAB
                Case "st"
                    oc = &HAB
                Case "cinv"
                    oc = &HAC
                Case "lea"
                    oc = &H44
            End Select
            If offset > 15 Or offset < 0 Or needSegPrefix Then
                emitImm4(offset)
            End If
            emitAlignedCode(oc)
            emitCode(ra)
            emitCode(rb)
            emitCode(rt)
            Select Case scale
                Case 1 : scale = 0
                Case 2 : scale = 1
                Case 4 : scale = 2
                Case 8 : scale = 3
                Case Else : scale = 0
            End Select
            emitCode(scale Or (offset << 4) Or (segbits << 2))
        End If
    End Sub

    Sub ProcessBitmapOp(ByVal ops As String, ByVal oc As Int64, Optional ByVal ndxOnly As Boolean = True)
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
        Dim segbits As Int64
        Dim needSegPrefix = False

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        If segreg = 1 Then
            segbits = 0
        ElseIf segreg = 3 Then
            segbits = 1
        ElseIf segreg = 5 Then
            segbits = 2
        ElseIf segreg = 14 Then
            segbits = 3
        Else
            segbits = 0
            needSegPrefix = True
        End If


        If (strs.Length < 1) Or strs(1) Is Nothing Then
            Console.WriteLine("Line:" & lineno & " Missing memory operand.")
            Return
        End If
        scale = 1
        rb = -1
        rt = 0
        ra = GetRegister(strs(2))
        s = strs(1).Split("[".ToCharArray)
        'offset = GetImmediate(s(0), "memop")
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRegister(s2(0))
                If s2.Length > 1 Then
                    scale = eval(s2(1))
                End If
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then rb = 0
        If offset > 15 Or offset < 0 Or needSegPrefix Then
            emitImm4(offset)
        End If
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(rb)
        emitCode(rt)
        Select Case scale
            Case 1 : scale = 0
            Case 2 : scale = 1
            Case 4 : scale = 2
            Case 8 : scale = 3
            Case Else : scale = 0
        End Select
        emitCode(scale Or (offset << 4) Or (segbits << 2))
    End Sub

    Sub ProcessLidtOp(ByVal ops As String, ByVal oc As Int64)
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
        Dim segbits As Int64
        Dim needSegPrefix = False

        'If address = &HFFFFFFFFFFFFB96CL Then
        '    Console.WriteLine("Reached address B96C")
        'End If

        If segreg = 1 Then
            segbits = 0
        ElseIf segreg = 3 Then
            segbits = 1
        ElseIf segreg = 5 Then
            segbits = 2
        ElseIf segreg = 14 Then
            segbits = 3
        Else
            segbits = 0
            needSegPrefix = True
        End If


        If (strs.Length < 1) Or strs(1) Is Nothing Then
            Console.WriteLine("Line:" & lineno & " Missing memory operand.")
            Return
        End If
        scale = 1
        rb = -1
        ra = GetRegister(strs(1))
        s = strs(1).Split("[".ToCharArray)
        'offset = GetImmediate(s(0), "memop")
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRegister(s2(0))
                If s2.Length > 1 Then
                    scale = eval(s2(1))
                End If
            End If
        Else
            ra = 0
        End If
        If Not optr26 Then
        Else
            If offset < -8192 Or offset > 8191 Or needSegPrefix Then
                emitImm14(offset)
            End If
            emitAlignedCode(oc)
            emitCode(ra)
            emitCode(rt)
            emitCode(((offset And 63) << 2) Or segbits)
            emitCode((offset >> 6) And 255)
        End If
    End Sub

    Sub ProcessSmr(ByVal ops As String, ByVal oc As Int64)
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim str As String

        ra = GetRegister(strs(1))
        rb = GetRegister(strs(2))
        str = strs(3).TrimStart("[".ToCharArray)
        str = str.TrimEnd("]".ToCharArray)
        rc = GetRegister(str)
        emitAlignedCode(2)
        emitCode(ra)
        emitCode(rb)
        emitCode(rc)
        emitCode(oc)
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

    Sub ProcessBRK(ByVal ops As String, ByVal oc As Int64)
        Dim tgt As Int64
        Dim str As String

        str = strs(1).TrimStart("#".ToCharArray)
        tgt = eval(str)
        emitAlignedCode(oc)
        emitCode(tgt And 255)
        emitCode((tgt >> 8) And 31)
        emitCode(0)
        emitCode(0)
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

    Function FindKey(ByVal n As Integer) As Object

        Dim nn As Integer

        For nn = 1 To symbols.Count
            If n = symbols.Item(nn).key Then
                Return symbols.Item(nn)
            End If
        Next
        Return Nothing
    End Function

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
                    symbols = New MyCollection
                Else
                    Try
                        sym2 = symbols.Find(sym.name)
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

    Sub ProcessBra(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        ra = GetRegister(strs(1))    ' branching to register ?
        rb = 0
        rc = 0
        If strs(2) Is Nothing Then
            If oc = 46 Or oc = 47 Then
                ProcessBra2(ops, oc)
                Return
            Else
                Console.WriteLine("missing register in branch? line" & lineno)
                Return
                L = Nothing
            End If
        Else
            L = GetSymbol(strs(2))
        End If
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (address And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Sub ProcessBra2(ByVal ops As String, ByVal oc As Int64)
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
        rc = 0
        If strs(1) Is Nothing Then
            Console.WriteLine("missing target in branch? line" & lineno)
            Return
            L = Nothing
        Else
            L = GetSymbol(strs(1))
        End If
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (address And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Sub ProcessBsr(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        ra = 0    ' branching to register ?
        rb = 0
        rc = 0
        If strs(1) Is Nothing Then
            Console.WriteLine("missing target address for branch?")
            Return
            L = Nothing
        Else
            L = GetSymbol(strs(1))
        End If
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (address And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Function GetSymbol(ByVal nm As String) As Symbol
        Dim L As Symbol
        Dim P As LabelPatch
        Dim isLocal As Boolean

        nm = nm.Trim
        isLocal = nm.Chars(0) = "."
        If isLocal Then
            nm = lastLabel + nm
        End If
        Try
            L = symbols.Item(NameTable.FindName(fileno & nm))
        Catch
            Try
                L = symbols.Item(NameTable.FindName("0" & nm))
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
            symbols.Add(L, L.name)
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
            ElseIf s.ToLower().StartsWith("fl") Then
                s = s.TrimStart("Ff".ToCharArray)
                s = s.TrimStart("Ll".ToCharArray)
                Try
                    r = Int16.Parse(s) + 248
                Catch
                    r = -1
                End Try
                Return r
            ElseIf s.ToLower = "bp" Then
                Return 253
            ElseIf s.ToLower = "sp" Then
                Return 255
            ElseIf s.ToLower = "tr" Then
                Return 252
            ElseIf s.ToLower = "pc" Then
                Return 254
            Else
                Return -1
            End If
        Catch
            Return -1
        End Try
    End Function

    Function GetSprRegister(ByVal s As String) As Integer
        Try
            If s.ToLower = "tick" Then
                Return 0
            ElseIf s.ToLower = "vbr" Then
                Return 1
            ElseIf s.ToLower = "bear" Then
                Return 2
            ElseIf s.ToLower = "pta" Or s.ToLower = "cr3" Then
                Return 4
            ElseIf s.ToLower = "cr0" Then
                Return 5
            ElseIf s.ToLower = "fault_pc" Then
                Return 8
            ElseIf s.ToLower = "fault_cs" Then
                Return 9
            ElseIf s.ToLower = "fault_seg" Then
                Return 10
            ElseIf s.ToLower = "fault_st" Then
                Return 11
            ElseIf s.ToLower = "srand1" Then
                Return 16
            ElseIf s.ToLower = "srand2" Then
                Return 17
            ElseIf s.ToLower = "rand" Then
                Return 18
            Else
                Return -1
            End If
        Catch ex As Exception
            Return -1
        End Try
    End Function

    Function GetSegRegister(ByVal s As String) As Integer
        Dim nn As Integer
        Try
            If s.ToLower = "ns" Then
                Return 0
            ElseIf s.ToLower = "ds" Then
                Return 1
            ElseIf s.ToLower = "es" Then
                Return 5
            ElseIf s.ToLower = "bss" Then
                Return 3
            ElseIf s.ToLower = "ss" Then
                Return 14
            ElseIf s.ToLower = "cs" Then
                Return 15
            ElseIf s.ToLower = "tss" Then
                Return 12
            ElseIf s.ToLower = "seg1" Then
                Return 1
            ElseIf s.ToLower = "seg2" Then
                Return 2
            ElseIf s.ToLower = "seg3" Then
                Return 3
            ElseIf s.ToLower = "seg4" Then
                Return 4
            ElseIf s.ToLower = "seg5" Then
                Return 5
            ElseIf s.ToLower = "seg6" Then
                Return 6
            ElseIf s.ToLower = "seg7" Then
                Return 7
            ElseIf s.ToLower = "seg8" Then
                Return 8
            ElseIf s.ToLower = "seg9" Then
                Return 9
            ElseIf s.ToLower = "seg10" Then
                Return 10
            ElseIf s.ToLower = "seg11" Then
                Return 11
            ElseIf s.ToLower = "seg12" Then
                Return 12
            ElseIf s.ToLower = "seg13" Then
                Return 13
            ElseIf s.ToLower = "seg14" Then
                Return 14
            ElseIf s.ToLower = "seg15" Then
                Return 15
            Else
                Return -1
            End If
        Catch ex As Exception
            Return -1
        End Try
    End Function

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
        Dim ii As Integer
        Dim nm As String

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
        ElseIf s.Chars(0) = "%" Then
            s = s.Replace("_", "")
            s1 = "0b" & s.Substring(1)
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
            ElseIf s.Chars(1) = "b" Or s.Chars(1) = "B" Then
                If s.Length >= 66 Then
                    s = "0b" & Right(s, 64)    ' max that will fit into 64 bits
                End If
                n = 0
                s = s.Substring(2)
                For m = 0 To s.Length - 1
                    n = n << 1
                    s1 = s.Substring(m, 1)
                    If s1 = "1" Then
                        n = n Or 1
                    End If
                Next
                'If s.Substring(2, 1) = "0" And n < 0 Then
                '    n = -n
                'End If
            End If
        Else
            If s.Chars(0) > "9" Or s.Chars(0) = "." Then
                sym = Nothing
                If s.Chars(0) = "." Then
                    nm = lastLabel & s
                Else
                    nm = s
                End If

                Try
                    sym = symbols.Find(NameTable.FindName(fileno & nm))
                Catch
                    Try
                        sym = symbols.Find(NameTable.FindName("0" & nm))
                    Catch
                        sym = Nothing
                    End Try
                End Try
                If sym Is Nothing Then
                    sym = New Symbol
                    sym.name = NameTable.AddName(fileno & nm)
                    sym.defined = False
                    sym.type = "U"
                    sym.segment = "Unknown"
                    If CStr(fileno) & s = "0printf" Then
                        Console.WriteLine("L7")
                    End If
                    symbols.Add(sym, sym.name)
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
        Dim ad As Int64

        If pass = maxpass Then
            ad = address
            If address Mod 16 = 15 Then
                ad = address + 1
            End If
            s = Hex(ad).PadLeft(8, "0") & vbTab & "           " & vbTab & vbTab & iline
            lfs.WriteLine(s)
        End If
    End Sub

    Sub emitOpcode(ByVal oc As Int64)
        'emitbyte(predicateByte, False)
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

    Sub emitbyte2(ByVal n As Int64, ByVal flush As Boolean)
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64
        Dim hh As String
        Dim jj As Integer
        Dim lad As Int64

        insnBundle.add(n And 255)

        If segment = "code" Then
            If (address And 31) = 0 Then
                w0 = 0
                w1 = 0
                w2 = 0
                w3 = 0
            End If
            lad = address And 31
            If lad >= 24 Then
                w3 = w3 Or ((n And 255) << ((lad And 7) * 8))
            ElseIf lad >= 16 Then
                w2 = w2 Or ((n And 255) << ((lad And 7) * 8))
            ElseIf lad >= 8 Then
                w1 = w1 Or ((n And 255) << ((lad And 7) * 8))
            Else
                w0 = w0 Or ((n And 255) << ((lad And 7) * 8))
            End If
            'For jj = 0 To 31
            '    If (address And 31) = jj Then
            '        If jj >= 24 Then
            '            w3 = w3 Or ((n And 255) << ((jj And 7) * 8))
            '        ElseIf jj >= 16 Then
            '            w2 = w2 Or ((n And 255) << ((jj And 7) * 8))
            '        ElseIf jj >= 8 Then
            '            w1 = w1 Or ((n And 255) << ((jj And 7) * 8))
            '        Else
            '            w0 = w0 Or ((n And 255) << ((jj And 7) * 8))
            '        End If
            '    End If
            'Next
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

    Sub emitAlignedCode(ByVal n As Int64)
        Dim ad As Int64
        Static po As Int64 = 0

        ad = (address And 15)
        While ad <> 0 And ad <> 5 And ad <> 10
            emitbyte(&H0, False, False)
            ad = (address And 15)
        End While
        ad = (address And &HFFF)
        If ad > &HFF0 And (n = &HFD Or n = &H61) Then
            ProcessNop("", &HEA)
            ProcessNop("", &HEA)
        End If
        emitbyte(n, False)
        po = n
    End Sub
    Sub emitCode(ByVal n As Int64)
        emitbyte(n, False)
    End Sub

    Sub emitbyte(ByVal n As Int64, ByVal flush As Boolean, Optional ByVal abb As Boolean = True)
        Dim ad As Int64
        Dim nn As Int64

        ad = address And 15
        If (address And 15) = 15 Then
            binbuf.add(insnBundle)
            insnBundle.clear()
        End If

        If segment <> "bss" Then
            If abb Then
                bytesbuf(bytn) = n And 255
                bytn = bytn + 1
            Else
                sa = sa + 1
            End If

            nn = 4
            If bytn > nn Then
                WriteListing()
                bytn = 0
            End If
        End If

        'If (address And 15) > 14 And Not doingDB Then
        'emitbyte2(&H0, flush)
        'sa =' sa + 1
        'End If
        emitbyte2(n, flush)
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

    Sub emitword(ByVal n As Int64, ByVal flush As Boolean)
        Static word As Int64
        Dim cd As Int64
        Dim s As String
        Dim nn As Int64
        Dim ad As Int64

        emitbyte(n And 255, False)
        emitbyte((n >> 8) And 255, False)
        emitbyte((n >> 16) And 255, False)
        emitbyte((n >> 24) And 255, False)
        emitbyte((n >> 32) And 255, False)
        emitbyte((n >> 40) And 255, False)
        emitbyte((n >> 48) And 255, False)
        emitbyte((n >> 56) And 255, False)
        Return

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
        Dim ii As Integer

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
        For ii = 0 To symbols.Size - 1
            sym = symbols.Item(ii)
            If sym Is Nothing Then GoTo j1
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
j1:
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
        Elf.hdr.e_flags = 0
        Elf.hdr.e_ehsize = Elf.hdr.Elf64HdrSz
        Elf.hdr.e_phentsize = 0
        Elf.hdr.e_phnum = 0
        Elf.hdr.e_shentsize = Elf64Shdr.Elf64ShdrSz
        Elf.hdr.e_shnum = 6
        Elf.hdr.e_shstrndx = 4  ' index into section table of string table header

        Elf.Write()
        Return

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
