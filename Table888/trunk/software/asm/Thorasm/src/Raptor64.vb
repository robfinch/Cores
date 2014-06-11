' Contains Raptor64 specific routines

Module Raptor64

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

    Sub ProcessRaptor64Mtseg()
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

    Sub ProcessRaptor64Mfseg()
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

    Sub ProcessRaptor64Mfsegi()
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

    Sub ProcessRaptor64Mtsegi()
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

    Sub ProcessRaptor64CMG(ByVal fn As Int64)
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
    ' RR-ops have the form: add Rt,Ra,Rb
    '
    Sub ProcessRaptor64Mtep(ByVal ops As String, ByVal fn As Int64)
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

End Module
