' Contains Thor specific routines

Module Thor

    Sub processOp(ByVal s As String)
        Select Case s.ToLower
            ' RI ops
        Case "ldi"
                ProcessThorLdi(s, &H6F)
            Case "ldis"
                ProcessThorLdis(s, &H9D)
            Case "addi"
                ProcessThorRIOp(s, &H48)
            Case "addui"
                ProcessThorRIOp(s, &H4C)
            Case "subi"
                ProcessThorRIOp(s, &H49)
            Case "subui"
                ProcessThorRIOp(s, &H4D)
            Case "cmpi"
                ProcessThorCmpIOp(s, &H20)
            Case "andi"
                ProcessThorRIOp(s, &H53)
            Case "ori"
                ProcessThorRIOp(s, &H54)
            Case "eori"
                ProcessThorRIOp(s, &H55)
            Case "mului"
                ProcessThorRIOp(s, &H4E)
            Case "muli"
                ProcessThorRIOp(s, &H4A)
            Case "divui"
                ProcessThorRIOp(s, &H4F)
            Case "divi"
                ProcessThorRIOp(s, &H4B)

            Case "cas"
                ProcessThorCas(s, &H97)
            Case "lvb"
                ProcessThorMemoryOp(s, &HD0)
            Case "lvc"
                ProcessThorMemoryOp(s, &HD1)
            Case "lvh"
                ProcessThorMemoryOp(s, &HD2)
            Case "lww"
                ProcessThorMemoryOp(s, &HD3)

            Case "lb"
                ProcessThorMemoryOp(s, &H80)
            Case "lbu"
                ProcessThorMemoryOp(s, &H81)
            Case "lc"
                ProcessThorMemoryOp(s, &H82)
            Case "lcu"
                ProcessThorMemoryOp(s, &H83)
            Case "lh"
                ProcessThorMemoryOp(s, &H84)
            Case "lhu"
                ProcessThorMemoryOp(s, &H85)
            Case "lw"
                ProcessThorMemoryOp(s, &H86)
            Case "lws"
                ProcessThorLws(s, &H8E)
            Case "lwr"
                ProcessThorMemoryOp(s, 46)
            Case "sb"
                ProcessThorMemoryOp(s, &H90)
            Case "sc"
                ProcessThorMemoryOp(s, &H91)
            Case "sh"
                ProcessThorMemoryOp(s, &H92)
            Case "sw"
                ProcessThorMemoryOp(s, &H93)
            Case "sws"
                ProcessThorLws(s, &H9E)
            Case "stp"
                ProcessThorMemoryOp(s, 52)
            Case "swc"
                ProcessThorMemoryOp(s, 62)
            Case "lea"
                ProcessThorMemoryOp(s, &H4C)
            Case "stbc"
                ProcessThorMemoryOp(s, 54)
            Case "sti"
                ProcessThorSti(s, &H96)
            Case "memdb"
                emitOpcode(&HF9)
            Case "memsb"
                emitOpcode(&HF8)

                ' RR branches
            Case "bra"
                ProcessThorBra(s, &H30)
            Case "br"
                ProcessThorBra(s, &H30)
            Case "brn"
                ProcessThorBra(s, 11)
            Case "bnr"
                ProcessThorBra(s, 14)
            Case "loop"
                ProcessThorLoop(s, &HA4)

                ' R
            Case "com"
                ProcessThorROp(s, 4)
            Case "not"
                ProcessThorROp(s, &H71)
            Case "neg"
                ProcessThorROp(s, &H70)
            Case "abs"
                ProcessThorROp(s, 7)
            Case "sgn"
                ProcessThorROp(s, 8)
            Case "mov"
                ProcessThorROp(s, &HA7)
            Case "swap"
                ProcessThorROp(s, 13)
            Case "ctlz"
                ProcessThorROp(s, 16)
            Case "ctlo"
                ProcessThorROp(s, 17)
            Case "ctpop"
                ProcessThorROp(s, 18)
            Case "sext8"
                ProcessThorROp(s, 20)
            Case "sext16"
                ProcessThorROp(s, 21)
            Case "sext32"
                ProcessThorROp(s, 22)
            Case "sqrt"
                ProcessThorROp(s, 24)

                ' RR
            Case "add"
                ProcessThorRROp(s, &H40)
            Case "addu"
                ProcessThorRROp(s, &H44)
            Case "sub"
                ProcessThorRROp(s, &H41)
            Case "subu"
                ProcessThorRROp(s, &H45)
            Case "cmp"
                ProcessThorCmpRROp(s, &H10)
            Case "and"
                ProcessThorRROp(s, &H50)
            Case "nand"
                ProcessThorRROp(s, &H66)
            Case "or"
                ProcessThorRROp(s, &H51)
            Case "eor"
                ProcessThorRROp(s, &H52)
                'Case "min"
                '    ProcessRROp(s, 20)
                'Case "max"
                '    ProcessRROp(s, 21)
            Case "mulu"
                ProcessThorRROp(s, &H46)
            Case "mul"
                ProcessThorRROp(s, &H42)
            Case "divu"
                ProcessThorRROp(s, &H47)
            Case "div"
                ProcessThorRROp(s, &H43)
                'Case "modu"
                '    ProcessRROp(s, 28)
                'Case "mods"
                '    ProcessRROp(s, 29)
            Case "tst"
                ProcessThorTst(s, &H0)

            Case "shli"
                ProcessThorShiftiOp(s, &H5E)
            Case "shlui"
                ProcessThorShiftiOp(s, &H60)
            Case "shrui"
                ProcessThorShiftiOp(s, &H61)
            Case "roli"
                ProcessThorShiftiOp(s, &H62)
            Case "shri"
                ProcessThorShiftiOp(s, &H5F)
            Case "rori"
                ProcessThorShiftiOp(s, &H63)

            Case "bfins"
                ProcessThorBitfieldOp(s, &H0)
            Case "bfset"
                ProcessThorBitfieldOp(s, &H1)
            Case "bfclr"
                ProcessThorBitfieldOp(s, &H2)
            Case "bfchg"
                ProcessThorBitfieldOp(s, &H3)
            Case "bfext"
                ProcessThorBitfieldOp(s, &H5)
            Case "bfextu"
                ProcessThorBitfieldOp(s, &H4)
            Case "bfexts"
                ProcessThorBitfieldOp(s, &H5)

            Case "jmp"
                ProcessThorJmp(s, &HA2)
            Case "jsr"
                ProcessThorJsr(s, &HA2)
            Case "rts"
                ProcessThorRtsOp(s, &HA3)
            Case "sys"
                ProcessThorSys(s, &HA5)
            Case "rti"
                ProcessThorRti(&HF4)
            Case "rte"
                ProcessThorRti(&HF3)

            Case "nop"
                ProcessThorNop(s, &H10)
                'Case "lm"
                '    ProcessThorPush(78)
                'Case "sm"
                '    ProcessThorPush(79)
            Case "mfspr"
                ProcessThorMfspr()
            Case "mtspr"
                ProcessThorMtspr()
            Case "mfseg"
                ProcessThorMfseg()
            Case "mtseg"
                ProcessThorMtseg()
            Case "mfsegi"
                ProcessThorMfsegi()
            Case "mtsegi"
                ProcessThorMtsegi()

                'Case "omg"
                '    ProcessThorOMG(50)
                'Case "cmg"
                '    ProcessThorCMG(51)
                'Case "omgi"
                '    ProcessThorOMG(52)
                'Case "cmgi"
                '    ProcessThorCMG(53)

            Case "gran"
                emit(80)
                'Case "cli"
                '    processThorCLI(&HFA)
                'Case "sei"
                '    processThorCLI(&HFB)
                'Case "icache_on"
                '    processThorICacheOn(10)
                'Case "icache_off"
                '    processThorICacheOn(11)
                'Case "dcache_on"
                '    processThorICacheOn(12)
                'Case "dcache_off"
                '    processThorICacheOn(13)
            Case "tlbdis"
                ProcessThorTLBWR(&H6F0)
            Case "tlben"
                ProcessThorTLBWR(&H5F0)
            Case "tlbpb"
                ProcessThorTLBWR(&H1F0)
            Case "tlbrd"
                ProcessThorTLBWR(&H2F0)
            Case "tlbwr"
                ProcessThorTLBWR(&H3F0)
            Case "tlbwi"
                ProcessThorTLBWR(&H4F0)
            Case "tlbrdreg"
                ProcessThorTLBRDREG(&H7F0)
            Case "tlbwrreg"
                ProcessThorTLBWRREG(&H8F0)
            Case "sync"
                emitThorOpcode(&HF8)
            Case "iepp"
                emit(15)
            Case "fip"
                emit(20)
            Case "wait"
                emit(40)
        End Select
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

    '
    ' R-ops have the form:   sqrt Rt,Ra
    '
    Sub ProcessThorROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetThorRegister(strs(1))
        ra = GetThorRegister(strs(2))
        emitThorOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    Sub ProcessThorRIOp(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetThorRegister(strs(1))
        ra = GetThorRegister(strs(2))
        imm = eval(strs(3))

        If imm < -2048 Or imm > 2047 Then
            emitIMM2(imm)
        End If
        emitThorOpcode(oc)
        emitCode((ra And 63) Or (rt << 6))
        emitCode(((rt >> 2) And 15) Or (imm And 15))
        emitCode((imm >> 4) And 255)
    End Sub

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

    Function GetThorSPRRegister(ByVal s As String) As Int64

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

    Function GetThorTLBRegister(ByVal s As String) As Int64

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

    Sub ProcessThorTLBWR(ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        emitThorOpcode(oc)
        emitbyte(oc >> 8, False)
        emitbyte(0, False)
    End Sub

    Sub ProcessThorTLBRDREG(ByVal oc As Int64)
        Dim opcode As Int64
        Dim Rt As Int64
        Dim Tn As Int64

        Rt = GetThorRegister(strs(1))
        Tn = GetThorTLBRegister(strs(2))
        emitThorOpcode(oc)
        emitbyte((oc >> 8) Or (Tn << 4), False)
        emitbyte(Rt, False)
    End Sub

    Sub ProcessThorTLBWRREG(ByVal oc As Int64)
        Dim opcode As Int64
        Dim Rb As Int64
        Dim Tn As Int64

        Tn = GetThorTLBRegister(strs(1))
        Rb = GetThorRegister(strs(2))
        emitThorOpcode(oc)
        emitbyte((oc >> 8) Or (Tn << 4), False)
        emitbyte(Rb, False)
    End Sub

    Sub ProcessThorTst(ByVal s As String, ByVal oc As Int64)
        Dim pt As Integer
        Dim ra As Integer

        pt = GetPnRegister(strs(1))
        ra = GetThorRegister(strs(2))
        emitThorOpcode(oc Or pt)
        emitbyte(ra, False)
    End Sub

    Sub ProcessThorMtspr()
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSprRegister(strs(1))
        ra = GetThorRegister(strs(2))
        emitThorOpcode(&HA9)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    Sub ProcessThorMfspr()
        Dim rt As Int64
        Dim ra As Int64

        rt = GetThorRegister(strs(1))
        ra = GetSprRegister(strs(2))
        emitThorOpcode(&HA8)
        emitbyte(ra, False)
        emitbyte(rt, False)
    End Sub

    ' rti and rte
    Sub ProcessThorRti(ByVal oc As Int64)
        emitThorOpcode(oc)
    End Sub

    Sub ProcessThorCmpIOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim pt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        pt = GetPnRegister(strs(1))
        ra = GetThorRegister(strs(2))
        imm = eval(strs(3))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitThorOpcode(oc Or pt)
        emitbyte(ra, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub ProcessThorLdi(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetThorRegister(strs(1))
        imm = eval(strs(2))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitThorOpcode(oc)
        emitbyte(rt, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    Sub ProcessThorLdis(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetSprRegister(strs(1))
        imm = eval(strs(2))

        If imm < -128 Or imm > 127 Then
            emitIMM2(imm)
        End If
        emitThorOpcode(oc)
        emitbyte(rt, False)
        emitbyte(imm, False)
        str = iline
    End Sub

    '
    ' Ret-ops have the form:   rts or rts 12[r1]
    '
    Sub ProcessThorRtsOp(ByVal ops As String, ByVal oc As Int64)
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
                Br = GetThorBrRegister(s(1).TrimEnd("]"))
                emitThorOpcode(oc)
                emitbyte((Br << 4) Or (imm And 15), False)
                Return
            Else
                imm = 0
                Br = GetThorBrRegister(s(0).TrimEnd("]"))
                emitThorOpcode(oc)
                emitbyte((Br << 4) Or (imm And 15), False)
                Return
            End If
        Catch
            'Console.WriteLine("Error: bad string ")
            emitbyte(&H11, False)
        End Try
    End Sub

    '
    ' Ret-ops have the form:   ret
    '
    Sub ProcessThorNop(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64

        emitbyte(oc, False)
    End Sub

    '
    ' CMP RR-ops have the form: cmp Pt,Ra,Rb
    '
    Sub ProcessThorCmpRROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim pt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        pt = GetPnRegister(strs(1))
        ra = GetThorRegister(strs(2))
        rb = GetThorRegister(strs(3))
        If rb = -1 Then
            ProcessThorCmpIOp(ops, &H20)
            Return
        End If
        emitThorOpcode(fn Or pt)
        emitbyte(ra, False)
        emitbyte(rb, False)
    End Sub

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    ' For some ops translation to immediate form is present
    ' when not specified eg. add Rt,Ra,#1234 gets translated to addi Rt,Ra,#1234
    '
    Sub ProcessThorRROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        rt = GetThorRegister(strs(1))
        ra = GetThorRegister(strs(2))
        rb = GetThorRegister(strs(3))
        If rb = -1 Then
            Select Case (strs(0))
                Case "add"
                    ProcessThorRIOp(ops, &H48)
                Case "addu"
                    ProcessThorRIOp(ops, &H4C)
                Case "sub"
                    ProcessThorRIOp(ops, &H41)
                Case "subu"
                    ProcessThorRIOp(ops, &H45)
                Case "and"
                    ProcessThorRIOp(ops, &H53)
                Case "or"
                    ProcessThorRIOp(ops, &H54)
                Case "eor"
                    ProcessThorRIOp(ops, &H55)
                Case "mul"
                    ProcessThorRIOp(ops, &H4A)
                Case "mulu"
                    ProcessThorRIOp(ops, &H4E)
                Case "div"
                    ProcessThorRIOp(ops, &H4B)
                Case "divu"
                    ProcessThorRIOp(ops, &H4F)
            End Select
            Return
        End If
        emitThorOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rb, False)
        emitbyte(rt, False)
    End Sub

    '
    ' -ops have the form: shrui Rt,Ra,#
    '
    Sub ProcessThorShiftiOp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetThorRegister(strs(1))
        ra = GetThorRegister(strs(2))
        imm = eval(strs(3))
        emitThorOpcode(fn)
        emitbyte(ra, False)
        emitbyte(rt, False)
        emitbyte(imm, False)
    End Sub

    '
    ' -ops have the form: bfext Rt,Ra,#me,#mb
    '
    Sub ProcessThorBitfieldOp(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim maskend As Int64
        Dim maskbegin As Int64

        rt = GetThorRegister(strs(1))
        ra = GetThorRegister(strs(2))
        maskend = eval(strs(3))
        maskbegin = eval(strs(4))
        emitThorOpcode(&HAA)
        emitbyte(ra, False)
        emitbyte(rt, False)
        emitbyte(maskbegin Or ((maskend << 6) And 3), False)
        emitbyte((maskend And 15) Or (fn << 4), False)
    End Sub

    Sub ProcessThorJmp(ByVal ops As String, ByVal oc As Int64)
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        s = strs(1).Split("[".ToCharArray)
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            ra = GetThorBrRegister(s(1))
        End If
        If (offset < -128 Or offset > 127) Then
            emitIMM2(offset)
        End If
        emitThorOpcode(oc)
        emitbyte(ra << 4, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessThorJsr(ByVal ops As String, ByVal oc As Int64)
        Dim Bt As Int64
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        Bt = GetThorBrRegister(strs(1))
        If Bt = -1 Then
            Bt = 1
            s = strs(1).Split("[".ToCharArray)
        Else
            s = strs(2).Split("[".ToCharArray)
        End If
        offset = eval(s(0))
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            ra = GetThorBrRegister(s(1))
        End If
        If (offset < -8388608 Or offset > 8388607) Then
            emitIMM2(offset)
        End If
        emitThorOpcode(oc)
        emitbyte((ra << 4) Or Bt, False)
        emitbyte(offset, False)
        emitbyte(offset >> 8, False)
        emitbyte(offset >> 16, False)
    End Sub

    Sub ProcessThorSys(ByVal ops As String, ByVal oc As Int64)
        Dim Bt As Int64
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String

        ra = 12
        Bt = GetThorBrRegister(strs(1))
        If (Bt = -1) Then
            Bt = 13
            s = strs(1).Split("[".ToCharArray)
            offset = eval(s(0))
            If s.Length > 1 Then
                ra = GetThorBrRegister((s(1).TrimEnd("]".ToCharArray)))
            End If
            emitThorOpcode(oc)
            emitbyte((ra << 4) Or Bt, False)
            emitbyte(offset, False)
            Return
        End If
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0))
        If s.Length > 1 Then
            ra = GetThorBrRegister((s(1).TrimEnd("]".ToCharArray)))
        End If
        emitThorOpcode(oc)
        emitbyte((ra << 4) Or Bt, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessThorCas(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim s() As String
        Dim offset As Int64

        rt = GetThorRegister(strs(1))
        rb = GetThorRegister(strs(2))
        rc = GetThorRegister(strs(3))
        s = strs(4).Split("[".ToCharArray)
        ra = GetThorRegister(s(0))
        offset = 0
        If ra = -1 Then
            offset = eval(s(0))
        End If
        If s.Length > 1 Then
            ra = GetThorRegister(s(1).TrimEnd("]".ToCharArray))
        End If
        If ra = -1 Then ra = 0
        If (offset < -128 Or offset > 127) Then
            emitIMM2(offset)
        End If
        emitThorOpcode(oc)
        emitbyte(ra, False)
        emitbyte(rb, False)
        emitbyte(rc, False)
        emitbyte(rt, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessThorMemoryOp(ByVal ops As String, ByVal oc As Int64)
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
            rt = GetThorRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessThorRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetThorRegister(strs(2))
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
            ra = GetThorRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetThorRegister(s2(0))
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
                emitThorOpcode(oc)
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
            emitThorOpcode(oc)
            emitbyte(ra, False)
            emitbyte(rb, False)
            emitbyte(rt, False)
        End If
    End Sub

    Sub ProcessThorSti(ByVal ops As String, ByVal oc As Int64)
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
            ra = GetThorRegister(s1(0))
        Else
            ra = 0
        End If
        If offset < -128 Or offset > 127 Then
            emitIMM2(offset)
        End If
        emitThorOpcode(oc)
        emitbyte(ra, False)
        emitbyte(imm, False)
        emitbyte(offset, False)
    End Sub

    Sub ProcessThorLws(ByVal ops As String, ByVal oc As Int64)
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
            rt = GetSprRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessThorRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetThorRegister(strs(2))
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
            ra = GetThorRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetThorRegister(s2(0))
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
                emitThorOpcode(oc)
                emitbyte(ra, False)
                emitbyte(rt, False)
                emitbyte(offset, False)
            End If
        Else
        End If
    End Sub

    Sub ProcessThorSws(ByVal ops As String, ByVal oc As Int64)
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
            rt = GetThorRegister(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ldi"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessThorRIOp(ops, 11)
                Return
            End If
        End If
        ra = GetSprRegister(strs(2))
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
            ra = GetThorRegister(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetThorRegister(s2(0))
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
                emitThorOpcode(oc)
                emitbyte(ra, False)
                emitbyte(rt, False)
                emitbyte(offset, False)
            End If
        Else
        End If
    End Sub

    Sub ProcessThorJAL(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim s() As String
        Dim s1() As String

        rb = -1
        rt = GetThorRegister(strs(1))
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0)) ', "jal")
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetThorRegister(s1(0))
            If s1.Length > 1 Then
                rb = GetThorRegister(s1(1))
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

    Sub ProcessThorLoop(ByVal ops As String, ByVal oc As Int64)
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
        emitThorOpcode(oc)
        emitbyte(disp, False)
    End Sub

    Sub ProcessThorBra(ByVal ops As String, ByVal oc As Int64)
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
        rc = GetThorRegister(strs(1))   ' branching to register ?
        If rc = -1 Then
            L = GetSymbol(strs(1))
            'If slot = 2 Then
            '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
            'Else
            disp = (((L.address And &HFFFFFFFFFFFFFFFFL) - (address And &HFFFFFFFFFFFFFFFFL)))
            'End If
            'imm = (L.address + (L.slot << 2)) >> 2
        End If
        emitThorOpcode(oc Or ((disp >> 8) And &HF))
        emitbyte(disp And &HFF, False)
    End Sub

    Function GetThorRegister(ByVal s As String) As Int64
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

    Function GetThorBrRegister(ByVal s As String) As Int64
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

    Sub ProcessThorMtseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSprRegister(strs(1))
        ra = GetRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 43
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 6)
        emit(opcode)
    End Sub

    Sub ProcessThorMfseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetSprRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 42
        opcode = opcode Or (ra << 6)
        opcode = opcode Or (rt << 15)
        emit(opcode)

    End Sub

    Sub ProcessThorMfsegi()
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

    Sub ProcessThorMtsegi()
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

    Sub emitThorOpcode(ByVal oc As Int64)
        emitbyte(predicateByte, False)
        emitbyte(oc, False)
    End Sub

End Module
