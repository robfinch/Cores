Public Class TextFile
    Inherits System.IO.StreamReader
    Public text As String
    Public lines() As String

    Overrides Function ReadToEnd() As String
        Dim str As String

        str = MyBase.ReadToEnd
        text = str.Replace(vbLf, " ")
        lines = text.Split(vbCr.ToCharArray())
        'While Me.Peek() <> -1
        '    str = str & Me.ReadLine & vbCr
        'End While
        Return str
    End Function

    Public Sub New(ByVal path As String)
        MyBase.New(path, New System.Text.ASCIIEncoding)
    End Sub
End Class
