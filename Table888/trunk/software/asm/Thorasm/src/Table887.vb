' Contains Table887 specific routines

Module Table887

    Function ProcessTable887Op(ByVal s As String) As Boolean
        Select Case LCase(s)
            Case "add"
                Process887RROp(s, &H2)
            Case "sub"
                Process887RROp(s, &H4002)
            Case "cmp"
                Process887RROp(s, &H8002)
            Case "cmpu"
                Process887RROp(s, &HC002)
            Case "and"
                Process887RROp(s, &H3)
            Case "or"
                Process887RROp(s, &H4003)
            Case "xor"
                Process887RROp(s, &H8003)
            Case "shl"
                Process887RROp(s, &HB)
            Case "shr"
                Process887RROp(s, &H400B)
            Case "addi"
                Process887RIOp(s, &H4)
            Case "subi"
                Process887RIOp(s, &H5)
            Case "cmpi"
                Process887RIOp(s, &H6)
            Case "cmpui"
                Process887RIOp(s, &H7)
            Case "andi"
                Process887RIOp(s, &H8)
            Case "ori"
                Process887RIOp(s, &H9)
            Case "xori"
                Process887RIOp(s, 10)
            Case "ldi"
                Process887LdiOp(s, 12)
            Case "shli"
                Process887RROp(s, &H800B)
            Case "shri"
                Process887RROp(s, &HC00B)
            Case "lw"
                Process887MemoryOp(s, 24)
            Case "ld"
                Process887MemoryOp(s, 24)
            Case "sw"
                Process887MemoryOp(s, 25)
            Case "st"
                Process887MemoryOp(s, 25)
            Case "bra"
                Process887Bra2(s, 16)
            Case Else
                Return False
        End Select
        Return True
    End Function

    '
    ' RR-ops have the form: add Rt,Ra,Rb
    ' For some ops translation to immediate form is present
    ' when not specified eg. add Rt,Ra,#1234 gets translated to addi Rt,Ra,#1234
    '
    Sub Process887RROp(ByVal ops As String, ByVal fn As Int64)
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
                    Process887RIOp(ops, &H4)
                Case "sub"
                    Process887RIOp(ops, &H5)
                Case "cmp"
                    Process887RIOp(ops, &H6)
                Case "cmpu"
                    Process887RIOp(ops, &H7)
                Case "and"
                    Process887RIOp(ops, &H8)
                Case "or"
                    Process887RIOp(ops, &H9)
                Case "xor"
                    Process887RIOp(ops, &H10)
                Case "shl"
                    Process887ShiftiOp(ops, &H800B)
                Case "shr"
                    Process887ShiftiOp(ops, &HC00B)
            End Select
            Return
        End If
        emit887AlignedCode(fn Or (ra << 5) Or (rb << 8) Or (rt << 11))
    End Sub

    Sub Process887RIOp(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim needPostfix As Boolean

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))

        needPostfix = imm > 15 Or imm < -15
        If needPostfix Then
            emit887AlignedCode(oc Or (ra << 5) Or (rt << 8) Or (&H10 << 11))
            emit887AlignedCode(imm)
        Else
            emit887AlignedCode(oc Or (ra << 5) Or (rt << 8) Or (imm << 11))
        End If
    End Sub

    Sub Process887LdiOp(ByVal ops As String, ByVal oc As Int64)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim needPostfix As Boolean

        rt = GetRegister(strs(1))
        imm = eval(strs(2))

        needPostfix = imm > 127 Or imm < -127
        If needPostfix Then
            emit887AlignedCode(oc Or (rt << 5) Or (&H80 << 8))
            emit887AlignedCode(imm)
        Else
            emit887AlignedCode(oc Or (rt << 5) Or ((imm And 255) << 8))
        End If
    End Sub

    Sub Process887ShiftiOp(ByVal s As String, ByVal oc As Integer)
        Dim rt As Int64
        Dim ra As Int64
        Dim imm As Int64

        rt = GetRegister(strs(1))
        ra = GetRegister(strs(2))
        imm = eval(strs(3))

        emit887AlignedCode(oc Or (ra << 5) Or (rt << 11) Or ((imm And 7) << 8))
    End Sub

    Sub Process887MemoryOp(ByVal ops As String, ByVal oc As Int64, Optional ByVal ndxOnly As Boolean = False)
        Dim opcode As Int64
        Dim rt As Int64
        Dim ra As Int64
        Dim rb As Int64
        Dim offset As Int64
        Dim s() As String
        Dim s1() As String
        Dim s2() As String
        Dim str As String
        Dim imm As Int64

        If (strs.Length < 2) Or strs(2) Is Nothing Then
            Console.WriteLine("Line:" & lineno & " Missing memory operand.")
            Return
        End If
        rb = -1
        rt = GetRegister(strs(1))
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
            End If
        Else
            ra = 0
        End If
        If rb = -1 Then rb = 0
        Select Case (strs(0))
            Case "ld"
                oc = 24
            Case "lw"
                oc = 24
            Case "sw"
                oc = 25
            Case "st"
                oc = 25
        End Select
        If offset > 15 Or offset < -15 Then
            emit887AlignedCode(oc Or (ra << 5) Or (rt << 8) Or (&H10 << 11))
            emit887AlignedCode(offset And 65535)
        Else
            emit887AlignedCode(oc Or (ra << 5) Or (rt << 8) Or ((offset And 31) << 11))
        End If
    End Sub

    Sub Process887Bra2(ByVal ops As String, ByVal oc As Int64)
        Dim opcode As Int64
        Dim ra As Int64
        Dim imm As Int64
        Dim disp As Int64
        Dim L As Symbol
        Dim P As LabelPatch

        ra = 0
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
        disp = (((L.address And &HFFFFFFFFFFFFFFFEL) - (address And &HFFFFFFFFFFFFFFFEL)))
        'End If
        'imm = (L.address + (L.slot << 2)) >> 2
        emit887AlignedCode(oc Or ((disp And 255) << 8))
    End Sub

    Sub emit887AlignedCode(ByVal n As Int64)
        Dim ad As Int64

        ad = (address And 1)
        While ad <> 0
            emitbyte(&H0, False, False)
            ad = (address And 1)
        End While
        emitbyte(n, False)
        emitbyte(n >> 8, False)
    End Sub

End Module
