Public Class MyCollection
    Public Size As Integer
    Dim objs(1000000) As Object
    Public Count As Integer

    Sub New()
        Size = 1000000
    End Sub

    Sub Add(ByVal ob As Object, ByVal ky As Integer)
        If ky < 0 Then Return
        Count = Count + 1
        objs(ky) = ob
    End Sub

    Function Find(ByVal ky As Integer)
        If ky < 0 Then Return Nothing
        Return objs(ky)
    End Function

    Sub Remove(ByVal ky As Integer)
        If ky < 0 Then Return
        If objs(ky) Is Nothing Then
        Else
            Count = Count - 1
        End If
        objs(ky) = Nothing
    End Sub

    Function Item(ByVal key As Integer) As Object
        If key < 0 Then Return Nothing
        Return objs(key)
    End Function

End Class
