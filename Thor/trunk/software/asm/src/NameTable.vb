Public Class clsNameTable
    Public text(100000) As Byte
    Public length As Integer

    Public Sub New()
        length = 1
        text(0) = 0
    End Sub

    Public Function AddName(ByVal s As String) As Integer
        Dim jj As Integer
        Dim olen As Integer

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
