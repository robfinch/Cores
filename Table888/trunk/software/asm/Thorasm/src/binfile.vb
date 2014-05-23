Public Class binfile
    Public bundleCnt As Int32
    Public bundleArray(1000000) As clsBundle
    Sub New()
        bundleCnt = 0
    End Sub
    Sub add(ByVal bndl As clsBundle)
        bundleArray(bundleCnt) = bndl
        bundleCnt = bundleCnt + 1
    End Sub
End Class
