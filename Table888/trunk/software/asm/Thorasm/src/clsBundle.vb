Public Class clsBundle
    Dim cnt As Integer
    Public bundle(16) As Byte
    Sub New()
        cnt = 0
    End Sub
    Sub clear()
        cnt = 0
    End Sub
    Sub add(ByVal byt As Integer)
        If cnt = 15 Then
            bundle(cnt) = 0
            cnt = 0
        End If
        bundle(cnt) = byt
        cnt = cnt + 1
    End Sub
End Class
