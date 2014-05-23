Public Class clsNameTable
    Public text(100000) As Byte
    Public length As Integer

    Public Sub New()
        length = 1
        text(0) = 0
    End Sub

    Public Function FindName(ByVal s As String) As Integer
        Dim jj As Integer
        Dim kk As Integer
        Dim olen As Integer
        Dim nn As Integer

        For jj = 1 To text.Length - 1
            kk = 1
            If text(jj) = Asc(Mid(s, kk, 1)) Then
                For kk = 2 To s.Length
                    If text(jj + kk - 1) <> Asc(Mid(s, kk, 1)) Then
                        GoTo j1
                    End If
                Next
                If text(jj + s.Length) <> 0 Then
                    GoTo j1
                End If
                Return jj
            End If
j1:
        Next
j2:
        Return -1
    End Function

    Public Function AddName(ByVal s As String) As Integer
        Dim jj As Integer
        Dim kk As Integer
        Dim olen As Integer
        Dim nn As Integer

        nn = FindName(s)
        If nn > 0 Then Return nn
j1:
        olen = length
        For jj = 1 To s.Length
            text(length) = Asc(Mid(s, jj, 1))
            length = length + 1
        Next
        text(length) = 0
        length = length + 1
        Return olen
    End Function

    Function GetName(ByVal ndx As Integer) As String
        Dim str As String

        str = ""
        While text(ndx) <> 0
            str = str + Chr(text(ndx))
            ndx = ndx + 1
        End While
        Return str
    End Function

    Public Sub Write()
        'sectionNameTableOffset = efs.BaseStream.Position
        'efs.Write(text, 0, length)
    End Sub

End Class
