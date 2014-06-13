' Contains Raptor64 specific routines

Module Raptor64

    Function ProcessRaptor64Op(ByVal s As String) As Boolean
        Select Case s
            Case "addi"
                ProcessRaptor64RIOp(s, 4)
            Case "addui"
                ProcessRaptor64RIOp(s, 5)
            Case "subi"
                ProcessRaptor64RIOp(s, 6)
            Case "subui"
                ProcessRaptor64RIOp(s, 7)
            Case "cmpi"
                ProcessRaptor64RIOp(s, 8)
            Case "cmpui"
                ProcessRaptor64RIOp(s, 9)
            Case "andi"
                ProcessRaptor64RIOp(s, 10)
            Case "ori"
                ProcessRaptor64RIOp(s, 11)
            Case "xori"
                ProcessRaptor64RIOp(s, 12)
            Case "mului"
                ProcessRaptor64RIOp(s, 13)
            Case "mulsi"
                ProcessRaptor64RIOp(s, 14)
            Case "divui"
                ProcessRaptor64RIOp(s, 15)
            Case "divsi"
                ProcessRaptor64RIOp(s, 16)
            Case "inb"
                ProcessRaptor64MemoryOp(s, 64)
            Case "inch"
                ProcessRaptor64MemoryOp(s, 65)
            Case "inh"
                ProcessRaptor64MemoryOp(s, 66)
            Case "inw"
                ProcessRaptor64MemoryOp(s, 67)
            Case "inbu"
                ProcessRaptor64MemoryOp(s, 68)
            Case "incu"
                ProcessRaptor64MemoryOp(s, 69)
            Case "inhu"
                ProcessRaptor64MemoryOp(s, 70)
            Case "outbc"
                ProcessRaptor64MemoryOp(s, 71)
            Case "outb"
                ProcessRaptor64MemoryOp(s, 72)
            Case "outc"
                ProcessRaptor64MemoryOp(s, 73)
            Case "outh"
                ProcessRaptor64MemoryOp(s, 74)
            Case "outw"
                ProcessRaptor64MemoryOp(s, 75)
            Case "lb"
                ProcessRaptor64MemoryOp(s, 32)
            Case "lbu"
                ProcessRaptor64MemoryOp(s, 37)
            Case "lc"
                ProcessRaptor64MemoryOp(s, 33)
            Case "lcu"
                ProcessRaptor64MemoryOp(s, 38)
            Case "lh"
                ProcessRaptor64MemoryOp(s, 34)
            Case "lhu"
                ProcessRaptor64MemoryOp(s, 39)
            Case "lw"
                ProcessRaptor64MemoryOp(s, 35)
            Case "lp"
                ProcessRaptor64MemoryOp(s, 36)
            Case "lwr"
                ProcessRaptor64MemoryOp(s, 46)
            Case "sb"
                ProcessRaptor64MemoryOp(s, 48)
            Case "sc"
                ProcessRaptor64MemoryOp(s, 49)
            Case "sh"
                ProcessRaptor64MemoryOp(s, 50)
            Case "sw"
                ProcessRaptor64MemoryOp(s, 51)
            Case "stp"
                ProcessRaptor64MemoryOp(s, 52)
            Case "swu"
                ProcessRaptor64MemoryOp(s, 55)
            Case "swc"
                ProcessRaptor64MemoryOp(s, 62)
            Case "lea"
                ProcessRaptor64MemoryOp(s, 77)
            Case "stbc"
                ProcessRaptor64MemoryOp(s, 54)
            Case "push"
                ProcessRaptor64Push(s, 55)

                ' RI branches
            Case "beqi"
                ProcessRaptor64RIBranch(s, 88)
            Case "bnei"
                ProcessRaptor64RIBranch(s, 89)
            Case "blti"
                ProcessRaptor64RIBranch(s, 80)
            Case "blei"
                ProcessRaptor64RIBranch(s, 82)
            Case "bgti"
                ProcessRaptor64RIBranch(s, 83)
            Case "bgei"
                ProcessRaptor64RIBranch(s, 81)
            Case "bltui"
                ProcessRaptor64RIBranch(s, 84)
            Case "bleui"
                ProcessRaptor64RIBranch(s, 86)
            Case "bgtui"
                ProcessRaptor64RIBranch(s, 87)
            Case "bgeui"
                ProcessRaptor64RIBranch(s, 85)
                ' RR branches
            Case "beq"
                ProcessRaptor64RRBranch(s, 8)
            Case "bne"
                ProcessRaptor64RRBranch(s, 9)
            Case "blt"
                ProcessRaptor64RRBranch(s, 0)
            Case "bge"
                ProcessRaptor64RRBranch(s, 1)
            Case "ble"
                ProcessRaptor64RRBranch(s, 2)
            Case "bgt"
                ProcessRaptor64RRBranch(s, 3)
            Case "bltu"
                ProcessRaptor64RRBranch(s, 4)
            Case "bgeu"
                ProcessRaptor64RRBranch(s, 5)
            Case "bleu"
                ProcessRaptor64RRBranch(s, 6)
            Case "bgtu"
                ProcessRaptor64RRBranch(s, 7)
            Case "bra"
                ProcessRaptor64Bra(s, 10)
            Case "br"
                ProcessRaptor64Bra(s, 10)
            Case "brn"
                ProcessRaptor64Bra(s, 11)
            Case "band"
                ProcessRaptor64RRBranch(s, 12)
            Case "bor"
                ProcessRaptor64RRBranch(s, 13)
            Case "bnr"
                ProcessRaptor64Bra(s, 14)
            Case "loop"
                ProcessRaptor64Loop(s, 15)

            Case "slti"
                ProcessRaptor64RIOp(s, 96)
            Case "slei"
                ProcessRaptor64RIOp(s, 97)
            Case "sgti"
                ProcessRaptor64RIOp(s, 98)
            Case "sgei"
                ProcessRaptor64RIOp(s, 99)
            Case "sltui"
                ProcessRaptor64RIOp(s, 100)
            Case "sleui"
                ProcessRaptor64RIOp(s, 101)
            Case "sgtui"
                ProcessRaptor64RIOp(s, 102)
            Case "sgeui"
                ProcessRaptor64RIOp(s, 103)
            Case "seqi"
                ProcessRaptor64RIOp(s, 104)
            Case "snei"
                ProcessRaptor64RIOp(s, 105)
                ' R
            Case "com"
                ProcessRaptor64ROp(s, 4)
            Case "not"
                ProcessRaptor64ROp(s, 5)
            Case "neg"
                ProcessRaptor64ROp(s, 6)
            Case "abs"
                ProcessRaptor64ROp(s, 7)
            Case "sgn"
                ProcessRaptor64ROp(s, 8)
            Case "mov"
                ProcessRaptor64ROp(s, 9)
            Case "swap"
                ProcessRaptor64ROp(s, 13)
            Case "ctlz"
                ProcessRaptor64ROp(s, 16)
            Case "ctlo"
                ProcessRaptor64ROp(s, 17)
            Case "ctpop"
                ProcessRaptor64ROp(s, 18)
            Case "sext8"
                ProcessRaptor64ROp(s, 20)
            Case "sext16"
                ProcessRaptor64ROp(s, 21)
            Case "sext32"
                ProcessRaptor64ROp(s, 22)
            Case "sqrt"
                ProcessRaptor64ROp(s, 24)

                ' RR
            Case "add"
                ProcessRaptor64RROp(s, 2)
            Case "addu"
                ProcessRaptor64RROp(s, 3)
            Case "sub"
                ProcessRaptor64RROp(s, 4)
            Case "subu"
                ProcessRaptor64RROp(s, 5)
            Case "cmp"
                ProcessRaptor64RROp(s, 6)
            Case "cmpu"
                ProcessRaptor64RROp(s, 7)
            Case "and"
                ProcessRaptor64RROp(s, 8)
            Case "or"
                ProcessRaptor64RROp(s, 9)
            Case "xor"
                ProcessRaptor64RROp(s, 10)
            Case "min"
                ProcessRaptor64RROp(s, 20)
            Case "max"
                ProcessRaptor64RROp(s, 21)
            Case "mulu"
                ProcessRaptor64RROp(s, 24)
            Case "muls"
                ProcessRaptor64RROp(s, 25)
            Case "divu"
                ProcessRaptor64RROp(s, 26)
            Case "divs"
                ProcessRaptor64RROp(s, 27)
            Case "modu"
                ProcessRaptor64RROp(s, 28)
            Case "mods"
                ProcessRaptor64RROp(s, 29)
            Case "mtep"
                ProcessRaptor64Mtep(s, 58)

            Case "slt"
                ProcessRaptor64RROp(s, 48)
            Case "sle"
                ProcessRaptor64RROp(s, 49)
            Case "sgt"
                ProcessRaptor64RROp(s, 50)
            Case "sge"
                ProcessRaptor64RROp(s, 51)
            Case "sltu"
                ProcessRaptor64RROp(s, 52)
            Case "sleu"
                ProcessRaptor64RROp(s, 53)
            Case "sgtu"
                ProcessRaptor64RROp(s, 54)
            Case "sgeu"
                ProcessRaptor64RROp(s, 55)
            Case "seq"
                ProcessRaptor64RROp(s, 56)
            Case "sne"
                ProcessRaptor64RROp(s, 57)

            Case "shli"
                ProcessRaptor64ShiftiOp(s, 0)
            Case "shlui"
                ProcessRaptor64ShiftiOp(s, 6)
            Case "shrui"
                ProcessRaptor64ShiftiOp(s, 1)
            Case "roli"
                ProcessRaptor64ShiftiOp(s, 2)
            Case "shri"
                ProcessRaptor64ShiftiOp(s, 3)
            Case "rori"
                ProcessRaptor64ShiftiOp(s, 4)

            Case "bfins"
                ProcessRaptor64BitfieldOp(s, 0)
            Case "bfset"
                ProcessRaptor64BitfieldOp(s, 1)
            Case "bfclr"
                ProcessRaptor64BitfieldOp(s, 2)
            Case "bfchg"
                ProcessRaptor64BitfieldOp(s, 3)
            Case "bfext"
                ProcessRaptor64BitfieldOp(s, 4)
            Case "bfextu"
                ProcessRaptor64BitfieldOp(s, 4)
            Case "bfexts"
                ProcessRaptor64BitfieldOp(s, 5)

            Case "jmp"
                ProcessRaptor64JOp(s, 25)
            Case "mjmp"
                ProcessRaptor64JOp(s, 25)
            Case "ljmp"
                ProcessRaptor64JOp(s, 25)
            Case "call"
                ProcessRaptor64JOp(s, 24)
            Case "mcall"
                ProcessRaptor64JOp(s, 24)
            Case "lcall"
                ProcessRaptor64JOp(s, 24)
            Case "ret"
                ProcessRaptor64RetOp(s, 27)
            Case "rtd"
                ProcessRaptor64RtdOp(s, 27)
            Case "jal"
                ProcessRaptor64JAL(s, 26)
            Case "syscall"
                ProcessRaptor64Syscall(s, 23)

            Case "nop"
                ProcessRaptor64Nop(s, 111)
            Case "iret"
                ProcessRaptor64IRet(&H1900020)
            Case "eret"
                ProcessRaptor64IRet(&H1800021)
            Case "lm"
                ProcessRaptor64Push("", 78)
            Case "sm"
                ProcessRaptor64Push("", 79)
            Case "mfspr"
                ProcessRaptor64Mfspr()
            Case "mtspr"
                ProcessRaptor64Mtspr()
            Case "mfseg"
                ProcessRaptor64Mfseg()
            Case "mtseg"
                ProcessRaptor64Mtseg()
            Case "mfsegi"
                ProcessRaptor64Mfsegi()
            Case "mtsegi"
                ProcessRaptor64Mtsegi()

            Case "omg"
                ProcessRaptor64OMG(50)
            Case "cmg"
                ProcessRaptor64CMG(51)
            Case "omgi"
                ProcessRaptor64OMG(52)
            Case "cmgi"
                ProcessRaptor64CMG(53)

            Case "setlo"
                ProcessRaptor64SETLO()
            Case "sethi"
                ProcessRaptor64SETHI()
            Case "gran"
                emit(80)
            Case "cli"
                processCLI(64)
            Case "sei"
                processCLI(65)
            Case "icache_on"
                processICacheOn(10)
            Case "icache_off"
                processICacheOn(11)
            Case "dcache_on"
                processICacheOn(12)
            Case "dcache_off"
                processICacheOn(13)
            Case "tlbp"
                ProcessRaptor64TLBWR(49)
            Case "tlbr"
                ProcessRaptor64TLBWR(50)
            Case "tlbwr"
                ProcessRaptor64TLBWR(52)
            Case "tlbwi"
                ProcessRaptor64TLBWR(51)
            Case "iepp"
                emit(15)
            Case "fip"
                emit(20)
            Case "wait"
                emit(40)
            Case Else
                Return False
        End Select
        Return True
    End Function

    '
    ' R-ops have the form:   sqrt Rt,Ra
    '
    Sub ProcessRaptor64ROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        opcode = 1L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 15)
        opcode = opcode Or fn
        emit(opcode)
    End Sub

    Sub ProcessRaptor64RIOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim func As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim msb As Int64
        Dim i2 As Int64
        Dim str As String

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        imm = eval(strs(3))

        If optr26 Then
            If (TestForPrefix15(imm) = True) Then
                ' convert RI op into RR op
                Select Case strs(0)
                    Case "addi"
                        func = 2
                    Case "add"
                        func = 2
                    Case "addui"
                        func = 3
                    Case "addu"
                        func = 3
                    Case "subi"
                        func = 4
                    Case "sub"
                        func = 4
                    Case "subui"
                        func = 5
                    Case "subu"
                        func = 5
                    Case "cmpi", "cmp"
                        func = 6
                    Case "cmpui", "cmpu"
                        func = 7
                    Case "andi", "and"
                        func = 8
                    Case "ori", "or"
                        func = 9
                    Case "xori", "xor"
                        func = 10
                    Case "mului", "mulu"
                        func = 24
                    Case "mulsi", "muls"
                        func = 25
                    Case "divui", "divu"
                        func = 26
                    Case "divsi", "divs"
                        func = 27
                End Select
                str = iline
                iline = "; SETLO"
                emitSETLO(imm)
                If TestForPrefix22(imm) Then
                    iline = "; SETMID"
                    emitSETMID(imm)
                    If TestForPrefix44(imm) Then
                        iline = "; SETHI"
                        emitSETHI(imm)
                    End If
                End If
                iline = str
                opcode = 2L << 25
                opcode = opcode Or (ra << 20)
                opcode = opcode Or (26 << 15)
                opcode = opcode Or (rt << 10)
                opcode = opcode Or func
                emit(opcode)
            Else
                opcode = oc << 25
                opcode = opcode Or (ra << 20)
                opcode = opcode Or (rt << 15)
                opcode = opcode Or (imm And &H7FFF)
                emit(opcode)
            End If
        Else
            If TestForPrefix50(imm) Then
                emitIMM(imm >> 50, 126L)
                emitIMM(imm >> 25, 125L)
                emitIMM(imm, 124L)
            ElseIf TestForPrefix25(imm) Then
                emitIMM(imm >> 25, 125L)
                emitIMM(imm, 124L)
            ElseIf TestForPrefix15(imm) Then
                emitIMM(imm, 124L)
            End If
            opcode = oc << 25
            opcode = opcode Or (ra << 20)
            opcode = opcode Or (rt << 15)
            opcode = opcode Or (imm And &H7FFF)
            emit(opcode)
        End If
        'End If
    End Sub

    Sub ProcessRaptor64SETLO()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 112L << 25
        Rt = GetRaptor64Register(strs(1))
        '        n = GetImmediate(strs(2), "setlo")
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &H3FFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64SETMID()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 116L << 25
        Rt = GetRaptor64Register(strs(1))
        '        n = GetImmediate(strs(2), "setlo")
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &H3FFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64SETHI()
        Dim opcode As Int64
        Dim n As Int64
        Dim Rt As Int64

        opcode = 120L << 25
        Rt = GetRaptor64Register(strs(1))
        n = eval(strs(2))
        opcode = opcode Or (Rt << 22)
        opcode = opcode Or (n And &HFFFFFL)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Mtseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSprRegister(strs(1))
        ra = GetRaptor64Register(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 43
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 6)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Mfseg()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetSprRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 42
        opcode = opcode Or (ra << 6)
        opcode = opcode Or (rt << 15)
        emit(opcode)

    End Sub

    Sub ProcessRaptor64Mfsegi()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 44
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 15)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Mtsegi()
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64

        ra = GetRaptor64Register(strs(1))
        rb = GetRaptor64Register(strs(2))
        opcode = 2L << 25
        opcode = opcode Or 35
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        emit(opcode)
    End Sub

    ' iret and eret
    Sub ProcessRaptor64IRet(ByVal oc As Int64)
        Dim opcode As Int64

        opcode = 0L << 25
        opcode = opcode Or oc
        emit(opcode)
    End Sub

    Sub emitRaptor64IMM(ByVal imm As Int64, ByVal oc As Int64)
        Dim opcode As Int64
        Dim str As String

        str = iline
        iline = "; imm "
        opcode = oc << 25     ' IMM1
        opcode = opcode Or (imm And &H1FFFFFFL)
        emit(opcode)
        iline = str
    End Sub

    Sub ProcessRaptor64OMG(ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        opcode = 1L << 25
        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
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

    Sub ProcessRaptor64CMG(ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        opcode = 1L << 25
        ra = GetRaptor64Register(strs(1))
        If ra = -1 Then
            imm = GetImmediate(strs(1), "omg")
            opcode = opcode Or ((imm And 63) << 6)
        Else
            opcode = opcode Or (ra << 20)
        End If
        opcode = opcode Or (fn And 63)
        emit(opcode)
    End Sub

    '
    ' J-ops have the form:   call   address
    '
    Sub ProcessRaptor64JOp(ByVal ops As String, ByVal oc As Int64)
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
    ' Rtd-ops have the form:   rtd  rt,ra,#immed
    '
    Sub ProcessRaptor64RtdOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        imm = GetImmediate(strs(3), "ret")

        opcode = oc << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (31L << 15)  ' link register
        opcode = opcode Or (rt << 10)
        opcode = opcode Or (imm And &H7FF8)
        emit(opcode)
    End Sub

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    '
    Sub ProcessRaptor64Mtep(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        ra = GetRaptor64Register(strs(1))
        rb = GetRaptor64Register(strs(2))
        opcode = 2L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        opcode = opcode Or fn
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Syscall(ByVal ops As String, ByVal oc As Int64)
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

    Sub ProcessRaptor64Brr(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim n As Integer

        ra = GetRaptor64Register(strs(1))
        rb = GetRaptor64Register(strs(2))
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

    Sub processRaptor64CLI(ByVal oc As Int64)
        emit(oc)
    End Sub

    Sub processRaptor64ICacheOn(ByVal n As Int64)
        Dim opcode As Int64

        opcode = 0L << 25
        opcode = opcode Or n
        emit(opcode)
    End Sub

    Sub ProcessRaptor64TLBWR(ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        opcode = 1L << 25
        opcode = opcode Or oc
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Mtspr()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetSprRegister(strs(1))
        ra = GetRaptor64Register(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 41
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 6)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Mfspr()
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetSprRegister(strs(2))
        opcode = 1L << 25
        opcode = opcode Or 40
        opcode = opcode Or (ra << 6)
        opcode = opcode Or (rt << 15)
        emit(opcode)

    End Sub

    Sub emitSETHI(ByVal imm As Int64)
        Dim opcode As Int64

        opcode = 120L << 25     ' SETHI
        opcode = opcode Or (26L << 22)  ' R30
        opcode = opcode Or ((imm >> 44L) And &HFFFFFL)
        emit(opcode)
    End Sub

    Sub emitSETLO(ByVal imm As Int64)
        Dim opcode As Int64

        opcode = 112L << 25     ' SETLO
        opcode = opcode Or (26L << 22)  ' R26
        opcode = opcode Or (imm And &H3FFFFFL)
        emit(opcode)
    End Sub

    Sub emitSETMID(ByVal imm As Int64)
        Dim opcode As Int64

        opcode = 116L << 25     ' SETLO
        opcode = opcode Or (26L << 22)  ' R26
        opcode = opcode Or ((imm >> 22L) And &H3FFFFFL)
        emit(opcode)
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

    '
    ' Ret-ops have the form:   ret
    '
    Sub ProcessRaptor64RetOp(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rt As Int64
        Dim imm As Int64

        ra = 30
        rt = 30
        imm = 0
        If Not strs(1) Is Nothing Then
            If Left(strs(1), 1) = "#" Then
                rt = 30
                imm = GetImmediate(strs(1), "ret")
            Else
                rt = GetRaptor64Register(strs(1))
                ra = GetRaptor64Register(strs(2))
                imm = GetImmediate(strs(3), "ret")
            End If
        End If
        opcode = oc << 25
        opcode = opcode Or (30L << 20)
        opcode = opcode Or (31L << 15)  ' link register
        opcode = opcode Or (imm And &H7FF8)
        emit(opcode)
    End Sub

    '
    ' Ret-ops have the form:   ret
    '
    Sub ProcessRaptor64Nop(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64

        opcode = oc << 25
        emit(opcode)
    End Sub

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    '
    Sub ProcessRaptor64RROp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        rb = GetRaptor64Register(strs(3))
        If rb = -1 Then
            Select Case (strs(0))
                Case "add"
                    ProcessRaptor64RIOp(ops, 4)
                Case "addu"
                    ProcessRaptor64RIOp(ops, 5)
                Case "sub"
                    ProcessRaptor64RIOp(ops, 6)
                Case "subu"
                    ProcessRaptor64RIOp(ops, 7)
                Case "and"
                    ProcessRaptor64RIOp(ops, 10)
                Case "or"
                    ProcessRaptor64RIOp(ops, 11)
                Case "xor"
                    ProcessRaptor64RIOp(ops, 12)
                Case "muls"
                    ProcessRaptor64RIOp(ops, 14)
                Case "mulu"
                    ProcessRaptor64RIOp(ops, 13)
                Case "divs"
                    ProcessRaptor64RIOp(ops, 16)
                Case "divu"
                    ProcessRaptor64RIOp(ops, 15)
            End Select
            Return
        End If
        opcode = 2L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        opcode = opcode Or (rt << 10)
        opcode = opcode Or fn
        emit(opcode)
    End Sub

    '
    ' -ops have the form: shrui Rt,Ra,#
    '
    Sub ProcessRaptor64ShiftiOp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        imm = eval(strs(3))
        opcode = 3L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 15)
        opcode = opcode Or ((imm And 63) << 9)
        opcode = opcode Or fn
        emit(opcode)
    End Sub

    '
    ' -ops have the form: bfext Rt,Ra,#me,#mb
    '
    Sub ProcessRaptor64BitfieldOp(ByVal ops As String, ByVal fn As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim maskend As Int64
        Dim maskbegin As Int64

        rt = GetRaptor64Register(strs(1))
        ra = GetRaptor64Register(strs(2))
        maskend = eval(strs(3))
        maskbegin = eval(strs(4))
        opcode = 21L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rt << 15)
        opcode = opcode Or ((maskend And 63) << 9)
        opcode = opcode Or ((maskbegin And 63) << 3)
        opcode = opcode Or fn
        emit(opcode)
    End Sub

    Sub ProcessRaptor64MemoryOp(ByVal ops As String, ByVal oc As Int64)
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
            rt = GetRaptor64Register(strs(1))
        End If
        ' Convert lw Rn,#n to ori Rn,R0,#n
        If ops = "lw" Then
            If (strs(2).StartsWith("#")) Then
                strs(0) = "ori"
                strs(3) = strs(2)
                strs(2) = "r0"
                ProcessRaptor64RIOp(ops, 11)
                Return
            End If
        End If
        ra = GetRaptor64Register(strs(2))
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
            ra = GetRaptor64Register(s1(0))
            If s1.Length > 1 Then
                s2 = s1(1).Split("*".ToCharArray)
                rb = GetRaptor64Register(s2(0))
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
                If TestForPrefix50(offset) Then
                    emitIMM(offset >> 50, 126L)
                    emitIMM(offset >> 25, 125L)
                    emitIMM(offset, 124L)
                ElseIf TestForPrefix25(offset) Then
                    emitIMM(offset >> 25, 125L)
                    emitIMM(offset, 124L)
                ElseIf TestForPrefix15(offset) Then
                    emitIMM(offset, 124L)
                End If
                If TestForPrefix12(offset) And (oc = 54 Or oc = 71) Then
                    Console.WriteLine("STBC/OUTBC: Offset too large.")
                End If
                opcode = oc << 25
                opcode = opcode + (ra << 20)
                opcode = opcode + (rt << 15)
                opcode = opcode + (offset And &H7FFFL)
                emit(opcode)
            Else
                If TestForPrefix15(offset) Then
                    str = iline
                    iline = "; SETLO"
                    emitSETLO(offset)
                    If TestForPrefix22(offset) Then
                        iline = "; SETMID"
                        emitSETMID(offset)
                        If TestForPrefix44(offset) Then
                            iline = "; SETHI"
                            emitSETHI(offset)
                        End If
                    End If
                    iline = str
                    opcode = 53L << 25
                    opcode = opcode + (ra << 20)
                    opcode = opcode + (26L << 15)
                    opcode = opcode + (rt << 10)
                    opcode = opcode + (0 << 8)     ' scale = 0 for now
                    opcode = opcode + ((0 And &H3) << 6)
                    opcode = opcode Or (oc - 32)    ' indexed op's are 32 less
                    emit(opcode)
                Else
                    If oc = 54 Or oc = 71 Then 'STBC/OUTBC
                        opcode = oc << 25
                        opcode = opcode + (ra << 20)
                        opcode = opcode + ((imm And &HFF) << 12)
                        opcode = opcode + (offset And &HFFFL)
                        emit(opcode)
                    Else
                        opcode = oc << 25
                        opcode = opcode + (ra << 20)
                        opcode = opcode + (rt << 15)
                        opcode = opcode + (offset And &H7FFFL)
                        emit(opcode)
                    End If
                End If
            End If
        Else
            If Not optr26 Then
                If offset > 3 Or offset < 0 Then
                    If TestForPrefix50(offset) Then
                        emitIMM(offset >> 50, 126L)
                        emitIMM(offset >> 25, 125L)
                        emitIMM(offset, 124L)
                    ElseIf TestForPrefix25(imm) Then
                        emitIMM(offset >> 25, 125L)
                        emitIMM(offset, 124L)
                    ElseIf offset > 3 Or offset < 0 Then
                        emitIMM(offset, 124L)
                    End If
                End If
            End If
            opcode = 53L << 25
            opcode = opcode + (ra << 20)
            opcode = opcode + (rb << 15)
            opcode = opcode + (rt << 10)
            opcode = opcode + (scale << 8)     ' scale = 0 for now
            opcode = opcode + ((offset And &H3) << 6)
            opcode = opcode Or (oc - 32)    ' indexed op's are 32 less
            emit(opcode)
        End If
    End Sub

    Sub ProcessRaptor64JAL(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim s() As String
        Dim s1() As String

        rb = -1
        rt = GetRaptor64Register(strs(1))
        s = strs(2).Split("[".ToCharArray)
        offset = eval(s(0)) ', "jal")
        If s.Length > 1 Then
            s(1) = s(1).TrimEnd("]".ToCharArray)
            s1 = s(1).Split("+".ToCharArray)
            ra = GetRaptor64Register(s1(0))
            If s1.Length > 1 Then
                rb = GetRaptor64Register(s1(1))
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

    Sub ProcessRaptor64RIBranch(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch
        Dim str As String

        ra = GetRaptor64Register(strs(1))
        imm = eval(strs(2)) 'GetImmediate(strs(2), "RIBranch")
        rb = GetRaptor64Register(strs(3))
        If optr26 Then
            If TestForPrefix8(imm) Then
                strs(2) = "r26"
                str = iline
                iline = "; SETLO"
                emitSETLO(imm)
                If TestForPrefix22(imm) Then
                    iline = "; SETMID"
                    emitSETMID(imm)
                    If TestForPrefix44(imm) Then
                        iline = "; SETHI"
                        emitSETHI(imm)
                    End If
                End If
                iline = str
                Select Case strs(0)
                    Case "blt", "blti"
                        oc = 0
                    Case "bge", "bgei"
                        oc = 1
                    Case "ble", "blei"
                        oc = 2
                    Case "bgt", "bgti"
                        oc = 3
                    Case "bltu", "bltui"
                        oc = 4
                    Case "bgeu", "bgeui"
                        oc = 5
                    Case "bleu", "bleui"
                        oc = 6
                    Case "bgtu", "bgtui"
                        oc = 7
                    Case "beq", "beqi"
                        oc = 8
                    Case "bne", "bnei"
                        oc = 9
                End Select
                ProcessRaptor64RRBranch(ops, oc)
                Return
            End If
        End If
        If rb = -1 Then
            L = GetSymbol(strs(3))
            'If slot = 2 Then
            '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
            'Else
            disp = (((L.address And &HFFFFFFFFFFFFFFFCL) - (address And &HFFFFFFFFFFFFFFFCL))) >> 2
            'End If
            'imm = (L.address + (L.slot << 2)) >> 2
            If Not optr26 Then
                If TestForPrefix50(imm) Then
                    emitIMM(imm >> 50, 126L)
                    emitIMM(imm >> 25, 125L)
                    emitIMM(imm, 124L)
                ElseIf TestForPrefix25(imm) Then
                    emitIMM(imm >> 25, 125L)
                    emitIMM(imm, 124L)
                ElseIf TestForPrefix8(imm) Then
                    emitIMM(imm, 124L)
                End If
            End If
            opcode = oc << 25
            opcode = opcode Or (ra << 20)
            opcode = opcode Or ((disp And &HFFF) << 8)
            opcode = opcode Or (imm And &HFF)
        Else
            opcode = 94L << 25
            opcode = opcode Or (ra << 20)
            opcode = opcode Or (rb << 15)
            Select Case (strs(0))
                Case "blt"
                    oc = 0
                Case "bge"
                    oc = 1
                Case "ble"
                    oc = 2
                Case "bgt"
                    oc = 3
                Case "bltu"
                    oc = 4
                Case "bgeu"
                    oc = 5
                Case "bleu"
                    oc = 6
                Case "bgtu"
                    oc = 7
                Case "beq"
                    oc = 8
                Case "bne"
                    oc = 9
                Case "bra"
                    oc = 10
                Case "brn"
                    oc = 11
                Case "band"
                    oc = 12
                Case "bor"
                    oc = 13
            End Select
            If Not optr26 Then
                If TestForPrefix50(imm) Then
                    emitIMM(imm >> 50, 126L)
                    emitIMM(imm >> 25, 125L)
                    emitIMM(imm, 124L)
                ElseIf TestForPrefix25(imm) Then
                    emitIMM(imm >> 25, 125L)
                    emitIMM(imm, 124L)
                ElseIf TestForPrefix11(imm) Then
                    emitIMM(imm, 124L)
                End If
            End If
            opcode = opcode Or (oc << 11)
            opcode = opcode Or (imm And &H7FF)
        End If
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Loop(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol

        ra = 0
        rb = GetRaptor64Register(strs(1))
        If rb = -1 Then
            Console.WriteLine("Error: Loop bad register " & strs(1))
            Return
        End If
        strs(2) = strs(2).Trim
        L = GetSymbol(strs(2))
        'If slot = 2 Then
        '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
        'Else
        disp = (((L.address And &HFFFFFFFFFFFFFFFCL) - (address And &HFFFFFFFFFFFFFFFCL))) >> 2
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        opcode = 95L << 25
        opcode = opcode Or (rb << 15)
        opcode = opcode Or ((disp And &H3FFL) << 5)
        opcode = opcode Or oc
        '            TestForPrefix(disp)
        emit(opcode)
    End Sub

    Sub ProcessRaptor64Bra(ByVal ops As String, ByVal oc As Int64)
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
        rc = GetRaptor64Register(strs(1))   ' branching to register ?
        If rc = -1 Then
            L = GetSymbol(strs(1))
            'If slot = 2 Then
            '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
            'Else
            disp = (((L.address And &HFFFFFFFFFFFFFFFCL) - (address And &HFFFFFFFFFFFFFFFCL))) >> 2
            'End If
            'imm = (L.address + (L.slot << 2)) >> 2
        End If
        opcode = 95L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        If rc = -1 Then
            opcode = opcode Or ((disp And &H3FF) << 5)
            opcode = opcode Or oc
            '            TestForPrefix(disp)
        Else
            opcode = opcode Or (rc << 10)
            opcode = opcode Or oc + 16
        End If
        emit(opcode)
    End Sub

    Sub ProcessRaptor64RRBranch(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim rc As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        ra = GetRaptor64Register(strs(1))
        rb = GetRaptor64Register(strs(2))
        If rb = -1 Then
            If Left(strs(2), 1) = "#" Then
                Select Case ops
                    ' RI branches
                Case "beq"
                        ProcessRaptor64RIBranch("beqi", 88)
                    Case "bne"
                        ProcessRaptor64RIBranch("bnei", 89)
                    Case "blt"
                        ProcessRaptor64RIBranch("blti", 80)
                    Case "ble"
                        ProcessRaptor64RIBranch("blei", 82)
                    Case "bgt"
                        ProcessRaptor64RIBranch("bgti", 83)
                    Case "bge"
                        ProcessRaptor64RIBranch("bgei", 81)
                    Case "bltu"
                        ProcessRaptor64RIBranch("bltui", 84)
                    Case "bleu"
                        ProcessRaptor64RIBranch("bleui", 86)
                    Case "bgtu"
                        ProcessRaptor64RIBranch("bgtui", 87)
                    Case "bgeu"
                        ProcessRaptor64RIBranch("bgeui", 85)
                End Select
                Return
            End If
        End If
        rc = GetRaptor64Register(strs(3))   ' branching to register ?
        If rc = -1 Then
            L = GetSymbol(strs(3))
            'If slot = 2 Then
            '    imm = ((L.address - address - 16) + (L.slot << 2)) >> 2
            'Else
            disp = (((L.address And &HFFFFFFFFFFFFFFFCL) - (address And &HFFFFFFFFFFFFFFFCL))) >> 2
            'End If
            'imm = (L.address + (L.slot << 2)) >> 2
        End If
        opcode = 95L << 25
        opcode = opcode Or (ra << 20)
        opcode = opcode Or (rb << 15)
        If rc = -1 Then
            opcode = opcode Or ((disp And &H3FF) << 5)
            opcode = opcode Or oc
            '            TestForPrefix(disp)
        Else
            opcode = opcode Or (rc << 10)
            opcode = opcode Or oc + 16
        End If
        emit(opcode)
    End Sub

    Function GetRaptor64Register(ByVal s As String) As Int64
        Dim r As Int16
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
            Return 27
        ElseIf s.ToLower = "xlr" Then
            Return 28
        ElseIf s.ToLower = "pc" Then
            Return 29
        ElseIf s.ToLower = "lr" Then
            Return 31
        ElseIf s.ToLower = "sp" Then
            Return 30
        ElseIf s.ToLower = "ssp" Then
            Return 25
        Else
            Return -1
        End If
    End Function

    Function GetRaptor64SPRRegister(ByVal s As String) As Int64

        Select Case (s)
            Case "TLBIndex"
                Return 1
            Case "TLBRandom"
                Return 2
            Case "PTA"
                Return 4
            Case "BadVAddr"
                Return 8
            Case "TLBVirtPage"
                Return 11
            Case "TLBPhysPage0"
                Return 10
            Case "TLBPhysPage1"
                Return 11
            Case "TLBPageMask"
                Return 13
            Case "TLBASID"
                Return 14
            Case "ASID"
                Return 15
            Case "EP0"
                Return 17
            Case "EP1"
                Return 18
            Case "EP2"
                Return 19
            Case "EP3"
                Return 20
            Case "AXC"
                Return 21
            Case "TICK"
                Return 22
            Case "EPC"
                Return 23
            Case "ERRADR"
                Return 24
            Case "CS"
                Return 15
            Case "DS"
                Return 12
            Case "SS"
                Return 14
            Case "ES"
                Return 13
            Case "IPC"
                Return 33
            Case "RAND"
                Return 34
            Case "rand"
                Return 34
            Case "SRAND1"
                Return 35
            Case "SRAND2"
                Return 36
            Case "PCHI"
                Return 62
            Case "PCHISTORIC"
                Return 63
            Case "seg0"
                Return 0
            Case "seg1"
                Return 1
            Case "seg2"
                Return 2
            Case "seg3"
                Return 3
            Case "seg4"
                Return 4
            Case "seg5"
                Return 5
            Case "seg6"
                Return 6
            Case "seg7"
                Return 7
            Case "seg8"
                Return 8
            Case "seg9"
                Return 9
            Case "seg10"
                Return 10
            Case "seg11"
                Return 11
            Case "seg12"
                Return 12
            Case "seg13"
                Return 13
            Case "seg14"
                Return 14
            Case "seg15"
                Return 15
        End Select
        Return -1
    End Function

    Sub ProcessRaptor64Push(ByVal s As String, ByVal oc As Int64)

    End Sub

End Module
