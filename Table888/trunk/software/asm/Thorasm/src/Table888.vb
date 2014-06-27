' Contains Table888 specific routines

Module Table888

    Function IsTable888Mnemonic(ByVal s As String) As Boolean
        Static mnes As String = "ldi~addi~addui~subi~subui~add~addu~sub~subu~and~or~eor~andi~ori~eori~mul~mulu~muli~mului~"
        Static mne() As String
        Dim nn As Integer
        Dim str As String

        If mnes.Length > 0 Then
            mnes = mnes & "div~divu~divi~divui~mod~modu~modi~modui~cmp~cmpi~"
            mnes = mnes & "lb~lbu~lc~lcu~lh~lhu~lw~sb~sc~sh~sw~"
            mne = mnes.Split("~".ToCharArray)
            mnes = ""
        End If

        For Each str In mne
            If s = str Then Return True
        Next
        Return False

    End Function

    Function ProcessTable888Op(ByVal s As String) As Boolean
        Select Case LCase(s)
            ' RI ops
        Case "ldi"
                ProcessLdi(s, &H16)
            Case "addi"
                ProcessTable888RIOp(s, &H4)
            Case "addui"
                ProcessTable888RIOp(s, &H14)
            Case "subi"
                ProcessTable888RIOp(s, &H5)
            Case "subui"
                ProcessTable888RIOp(s, &H15)
            Case "cmpi"
                ProcessTable888RIOp(s, &H6)
            Case "andi"
                ProcessTable888RIOp(s, &HC)
            Case "ori"
                ProcessTable888RIOp(s, &HD)
            Case "eori"
                ProcessTable888RIOp(s, &HE)
            Case "mului"
                ProcessTable888RIOp(s, &H17)
            Case "muli"
                ProcessTable888RIOp(s, &H7)
            Case "divui"
                ProcessTable888RIOp(s, &H18)
            Case "divi"
                ProcessTable888RIOp(s, &H8)
            Case "modi"
                ProcessTable888RIOp(s, &H9)
            Case "modui"
                ProcessTable888RIOp(s, &H19)

            Case "lb"
                ProcessTable888MemoryOp(s, &H80)
            Case "lbu"
                ProcessTable888MemoryOp(s, &H81)
            Case "lc"
                ProcessTable888MemoryOp(s, &H82)
            Case "lcu"
                ProcessTable888MemoryOp(s, &H83)
            Case "lh"
                ProcessTable888MemoryOp(s, &H84)
            Case "lhu"
                ProcessTable888MemoryOp(s, &H85)
            Case "lw"
                ProcessTable888MemoryOp(s, &H86)
            Case "ld"
                ProcessTable888MemoryOp(s, &H86)
            Case "lea"
                ProcessTable888MemoryOp(s, &H92)
            Case "bmld"
                ProcessTable888MemoryOp(s, &HB7, True)
            Case "sb"
                ProcessTable888MemoryOp(s, &HA0)
            Case "sc"
                ProcessTable888MemoryOp(s, &HA1)
            Case "sh"
                ProcessTable888MemoryOp(s, &HA2)
            Case "sw"
                ProcessTable888MemoryOp(s, &HA3)
            Case "st"
                ProcessTable888MemoryOp(s, &HA3)
            Case "bmst"
                ProcessTable888MemoryOp(s, &HB8, True)
            Case "cinv"
                ProcessTable888MemoryOp(s, &HA4)
            Case "lidt"
                ProcessLidtOp(s, &H90)
            Case "lgdt"
                ProcessLidtOp(s, &H91)
            Case "sidt"
                ProcessLidtOp(s, &HB0)
            Case "sgdt"
                ProcessLidtOp(s, &HB1)
            Case "stbc"
                ProcessTable888MemoryOp(s, 54)
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
                ProcessTable888Bcc(s, &H58)
            Case "brnz"
                ProcessTable888Bcc(s, &H59)
            Case "brmi"
                ProcessTable888Bcc(s, &H44)
            Case "brpl"
                ProcessTable888Bcc(s, &H45)
            Case "brodd"
                ProcessTable888Bcc(s, &H4E)
            Case "brevn"
                ProcessTable888Bcc(s, &H4F)
            Case "dbnz"
                ProcessTable888Bcc(s, &H5A)
            Case "beq"
                ProcessTable888Bcc(s, &H40)
            Case "bne"
                ProcessTable888Bcc(s, &H41)
            Case "bvs"
                ProcessTable888Bcc(s, &H42)
            Case "bvc"
                ProcessTable888Bcc(s, &H43)
            Case "bmi"
                ProcessTable888Bcc(s, &H44)
            Case "bpl"
                ProcessTable888Bcc(s, &H45)
            Case "bra"
                ProcessTable888Bra(s, &H46)
            Case "br"
                ProcessTable888Bra(s, &H46)
            Case "brn"
                ProcessTable888Bcc(s, &H47)
            Case "bgt"
                ProcessTable888Bcc(s, &H48)
            Case "ble"
                ProcessTable888Bcc(s, &H49)
            Case "bge"
                ProcessTable888Bcc(s, &H4A)
            Case "blt"
                ProcessTable888Bcc(s, &H4B)
            Case "bhi"
                ProcessTable888Bcc(s, &H4C)
            Case "bls"
                ProcessTable888Bcc(s, &H4D)
            Case "bhs"
                ProcessTable888Bcc(s, &H4E)
            Case "blo"
                ProcessTable888Bcc(s, &H4F)
            Case "bgtu"
                ProcessTable888Bcc(s, &H4C)
            Case "bleu"
                ProcessTable888Bcc(s, &H4D)
            Case "bgeu"
                ProcessTable888Bcc(s, &H4E)
            Case "bltu"
                ProcessTable888Bcc(s, &H4F)
            Case "bsr"
                ProcessTable888Bsr(s, &H56)

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
                ProcessTable888Mtspr(s, &H48)
            Case "mfspr"
                ProcessTable888Mfspr(s, &H49)
            Case "lsb"
                ProcessMfseg(s, &H12)
            Case "swap"
                ProcessROp(s, 3)
            Case "gran"
                ProcessGran(s, &H14)

                ' RR
            Case "add"
                ProcessTable888RROp(s, &H4)
            Case "addu"
                ProcessTable888RROp(s, &H14)
            Case "sub"
                ProcessTable888RROp(s, &H5)
            Case "subu"
                ProcessTable888RROp(s, &H15)
            Case "cmp"
                ProcessTable888RROp(s, &H6)
            Case "and"
                ProcessTable888RROp(s, &H20)
            Case "nand"
                ProcessTable888RROp(s, &H24)
            Case "or"
                ProcessTable888RROp(s, &H21)
            Case "eor"
                ProcessTable888RROp(s, &H22)
            Case "andn"
                ProcessTable888RROp(s, &H23)
            Case "mulu"
                ProcessTable888RROp(s, &H17)
            Case "mul"
                ProcessTable888RROp(s, &H7)
            Case "divu"
                ProcessTable888RROp(s, &H18)
            Case "div"
                ProcessTable888RROp(s, &H8)
            Case "divs"
                ProcessTable888RROp(s, &H8)
            Case "modu"
                ProcessTable888RROp(s, &H19)
            Case "mod"
                ProcessTable888RROp(s, &H9)
            Case "shl"
                ProcessTable888RROp(s, &H40)
            Case "shlu"
                ProcessTable888RROp(s, &H40)
            Case "shr"
                ProcessTable888RROp(s, &H42)
            Case "shru"
                ProcessTable888RROp(s, &H42)
            Case "rol"
                ProcessTable888RROp(s, &H41)
            Case "ror"
                ProcessTable888RROp(s, &H43)
            Case "asr"
                ProcessTable888RROp(s, &H44)

            Case "shli"
                ProcessShiftiOp(s, &H50)
            Case "shlui"
                ProcessShiftiOp(s, &H50)
            Case "shri"
                ProcessShiftiOp(s, &H52)
            Case "shrui"
                ProcessShiftiOp(s, &H52)
            Case "roli"
                ProcessShiftiOp(s, &H51)
            Case "asri"
                ProcessShiftiOp(s, &H54)
            Case "rori"
                ProcessShiftiOp(s, &H53)

            Case "jmp"
                ProcessTable888Jmp(s, &H50)
            Case "jsr"
                ProcessTable888Jmp(s, &H51)
            Case "jgr"
                ProcessJgr(s, &H57)
            Case "rts"
                ProcessRtsOp(s, &H60)
            Case "jal"
                ProcessTable888JAL(s, &H5B)

            Case "rtd"
                ProcessTable888Link(s, &HFAFF63)
            Case "rti"
                ProcessTable888Rti(&H40)
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

            Case "link"
                ProcessTable888Link(s, &HFDFF62)
            Case "unlink"
                ProcessTable888Insn(&H4200FFFD01)
            Case "unlk"
                ProcessTable888Insn(&H4200FFFD01)
            Case Else
                Return False
        End Select
        Return True
    End Function

    Sub ProcessTable888RIOp(ByVal ops As String, ByVal oc As Int64)
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
    '
    ' RR-ops have the form: add Rt,Ra,Rb
    ' For some ops translation to immediate form is present
    ' when not specified eg. add Rt,Ra,#1234 gets translated to addi Rt,Ra,#1234
    '
    Sub ProcessTable888RROp(ByVal ops As String, ByVal fn As Int64)
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
                    ProcessTable888RIOp(ops, &H4)
                Case "addu"
                    ProcessTable888RIOp(ops, &H14)
                Case "sub"
                    ProcessTable888RIOp(ops, &H5)
                Case "subu"
                    ProcessTable888RIOp(ops, &H15)
                Case "cmp"
                    ProcessTable888RIOp(ops, &H6)
                Case "and"
                    ProcessTable888RIOp(ops, &HC)
                Case "or"
                    ProcessTable888RIOp(ops, &HD)
                Case "eor"
                    ProcessTable888RIOp(ops, &HE)
                Case "mul"
                    ProcessTable888RIOp(ops, &H7)
                Case "mulu"
                    ProcessTable888RIOp(ops, &H17)
                Case "div"
                    ProcessTable888RIOp(ops, &H8)
                Case "divs"
                    ProcessTable888RIOp(ops, &H8)
                Case "divu"
                    ProcessTable888RIOp(ops, &H18)
                Case "mod"
                    ProcessTable888RIOp(ops, &H9)
                Case "modu"
                    ProcessTable888RIOp(ops, &H19)
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

    Sub ProcessTable888Link(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        imm = eval(strs(1))

        If imm < -32768 Or imm > 32767 Then
            emitImm16(imm)
        End If
        emitAlignedCode(oc And 255)
        emitCode((oc >> 8) And 255)
        emitCode((oc >> 16) And 255)
        emitCode(imm And 255)
        emitCode((imm >> 8) And 255)
    End Sub

    Sub ProcessTable888JAL(ByVal ops As String, ByVal oc As Int64)
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
        If offset > 65535L Then
            emitImm16(offset)
        End If
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(rt)
        emitCode(offset And 255)
        emitCode((offset >> 8) And 255)
    End Sub

    Sub ProcessTable888MemoryOp(ByVal ops As String, ByVal oc As Int64, Optional ByVal ndxOnly As Boolean = False)
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
            segbits = 1
        ElseIf segreg = 14 Then
            segbits = 2
        ElseIf segreg = 15 Then
            segbits = 0
        Else
            segbits = 0
            'needSegPrefix = True
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
            If offset < -8192 Or offset > 8191 Or needSegPrefix Then
                emitImm14(offset)
            End If
            If segreg = 1 Then
                segbits = 1
            ElseIf segreg = 14 Then
                segbits = 2
            ElseIf segreg = 15 Then
                segbits = 0
            Else
                If (ra = 255 Or ra = 253) Then
                    segbits = 2
                ElseIf ra = 254 Then
                    segbits = 0
                Else
                    segbits = 1
                End If
            End If

            emitAlignedCode(oc)
            emitCode(ra)
            emitCode(rt)
            emitCode(((offset And 63) << 2) Or segbits)
            emitCode((offset >> 6) And 255)
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
                Case "ld"
                    oc = &H8E
                Case "lea"
                    oc = &H8F
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
            End Select
            If offset > 15 Or offset < 0 Or needSegPrefix Then
                emitImm4(offset)
            End If
            If segreg = 1 Then
                segbits = 1
            ElseIf segreg = 14 Then
                segbits = 2
            ElseIf segreg = 15 Then
                segbits = 0
            Else
                If (ra = 255 Or ra = 253) Then
                    segbits = 2
                ElseIf ra = 254 Then
                    segbits = 0
                Else
                    segbits = 1
                End If
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

    ' rti and rte
    Sub ProcessTable888Rti(ByVal oc As Int64)
        emitAlignedCode(1)
        emitCode(0)
        emitCode(0)
        emitCode(0)
        emitCode(oc)
    End Sub

    ' link
    Sub ProcessTable888Insn(ByVal oc As Int64)
        emitAlignedCode(oc And 255)
        emitCode((oc >> 8) And 255)
        emitCode((oc >> 16) And 255)
        emitCode((oc >> 24) And 255)
        emitCode((oc >> 32) And 255)
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

    Sub ProcessTable888Jmp(ByVal ops As String, ByVal oc As Int64)
        Dim ra As Int64
        Dim offset As Int64
        Dim s() As String
        Dim segbits As Int64
        Dim needSegPrefix As Boolean
        Dim rs As String

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
        If strs(1).StartsWith("(") Or strs(1).StartsWith("[") Then
            s = strs(1).Split(",".ToCharArray)
            If s.Length > 1 Then
                ra = GetRegister(s(1))
            Else
                ' test for simple register indirect - JSR [R5]
                rs = s(0).Trim("[()]".ToCharArray)
                ra = GetRegister(rs)
                If ra >= 0 Then
                    emitAlignedCode(oc + 4)
                    emitCode(ra)
                    emitCode(0)
                    emitCode(0)
                    emitCode(0)
                    Return
                End If
                ra = 0
            End If
            offset = eval(s(0).Trim("()[]".ToCharArray))
            If (offset <= &HFFFFFFFFFF800000L Or offset > &H7FFFFF) Then ' Or needSegPrefix) Then
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
        If (offset < &HFFFFFFFF00000000L Or offset > &HFFFFFFFFL) Then
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

    Sub ProcessTable888Bra(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim ad As Int64

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
        ad = address + 5
        If (ad And 15) = 15 Then ad = ad + 1
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (ad And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Sub ProcessTable888Bsr(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim ad As Int64

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
        ad = address + 5
        If (ad And 15) = 15 Then ad = ad + 1
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (ad And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Sub ProcessTable888Bcc(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim ad As Int64

        ra = GetRegister(strs(1))    ' branching to register ?
        rb = 0
        rc = 0
        If strs(2) Is Nothing Then
            If oc = 46 Or oc = 47 Then
                ProcessTable888Bra(ops, oc)
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
        ad = address + 5
        If (ad And 15) = 15 Then ad = ad + 1
        disp = (((L.address And &HFFFFFFFFFFFF0000L) - (ad And &HFFFFFFFFFFFF0000L)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emitAlignedCode(oc)
        emitCode(ra)
        emitCode(L.address And &HFF)
        emitCode((L.address >> 8) And &HFF)
        emitCode((disp >> 16) And &H1F)
    End Sub

    Function GetTable888SprRegister(ByVal s As String) As Integer
        Dim reg As Int64

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
            ElseIf s.ToLower = "clk" Then
                Return 6
            ElseIf s.ToLower = "fault_pc" Then
                Return 8
            ElseIf s.ToLower = "fault_cs" Then
                Return 9
            ElseIf s.ToLower = "fault_seg" Then
                Return 10
            ElseIf s.ToLower = "fault_st" Then
                Return 11
            ElseIf s.ToLower = "ivno" Then
                Return 12
            ElseIf s.ToLower = "history" Then
                Return 13
            ElseIf s.ToLower = "biterr" Then
                Return 14
            ElseIf s.ToLower = "bithist" Then
                Return 15
            ElseIf s.ToLower = "srand1" Then
                Return 16
            ElseIf s.ToLower = "srand2" Then
                Return 17
            ElseIf s.ToLower = "rand" Then
                Return 18
            ElseIf s.ToLower = "cs" Then
                Return 32
            ElseIf s.ToLower = "ds" Then
                Return 33
            ElseIf s.ToLower = "ss" Then
                Return 34
            Else
                reg = GetSegRegister(s)
                Return reg
            End If
        Catch ex As Exception
            Return -1
        End Try
    End Function

    '
    '
    Sub ProcessTable888Mtspr(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetTable888SprRegister(strs(1))
        ra = GetRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub

    '
    '
    Sub ProcessTable888Mfspr(ByVal ops As String, ByVal fn As Int64)
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRegister(strs(1))
        ra = GetTable888SprRegister(strs(2))
        emitAlignedCode(1)
        emitCode(ra)
        emitCode(rt)
        emitCode(0)
        emitCode(fn)
    End Sub

End Module
