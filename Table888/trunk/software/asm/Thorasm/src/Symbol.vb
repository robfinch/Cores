Public Class Symbol
    Public name As Integer
    Public value As Int64   ' could be an address    
    Public segment As String
    Public address As Int64
    Public defined As Boolean
    Public type As Char
    Public scope As String
    Public fileno As Integer
    Public PatchAddresses As Collection

    Public Sub New()
        PatchAddresses = New Collection
        scope = ""
    End Sub
    Public Overloads Overrides Function Equals(ByVal obj As Object) As Boolean
        If obj Is Nothing Or Not Me.GetType() Is obj.GetType Then
            Return False
        End If
        Dim i As Integer = CType(obj, Integer)
        Return Me.name = i
    End Function
    Public Overrides Function GetHashCode() As Integer
        Console.WriteLine("got hashcode")
        Return name
    End Function

End Class
