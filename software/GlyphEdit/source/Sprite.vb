Public Class Sprite
    Public index As Integer
    Public scanlines As Integer
    Public horizDots As Integer
    Dim bitmap(2048) As System.Drawing.Color

    Function ImageSize() As Integer
        Return scanlines * horizDots
    End Function

    Function nImages() As Integer
        If frmSprite0.BPP() = 16 Then
            Return 1024 / ImageSize()
        Else
            Return 2048 / ImageSize()
        End If
    End Function

    Sub Draw(ByVal e As System.Windows.Forms.PaintEventArgs)
        Dim g As Integer
        Dim j As Integer
        Dim k As Integer
        Dim br As Brush
        Dim red As Integer
        Dim green As Integer
        Dim blue As Integer
        Dim gx As Integer
        Dim gy As Integer
        Dim szsp As Integer

        gx = 0
        gy = 0
        szsp = scanlines * horizDots
        For g = 0 To nImages() - 1
            For j = 0 To scanlines - 1
                For k = 0 To horizDots - 1
                    'red = ((bitmap(j * horizDots + k).R >> 3) And 31) << 3
                    'green = ((bitmap(j * horizDots + k).G >> 3) And 31) << 3
                    'blue = ((bitmap(j * horizDots + k).B >> 3) And 31) << 3
                    'br = New SolidBrush(System.Drawing.Color.FromArgb(red, green, blue))
                    br = New SolidBrush(bitmap(j * horizDots + k + g * szsp))
                    e.Graphics.FillRectangle(br, gx + k * 10, gy + j * 10, 10, 10)
                Next
            Next
            gx = gx + horizDots * 10
            If gx + horizDots * 10 > frmSprite0.PictureBox3.Size.Width Then
                gx = 0
                gy = gy + scanlines * 10
            End If
        Next
        gx = 0
        gy = 0
        For g = 0 To nImages() - 1
            e.Graphics.DrawRectangle(System.Drawing.Pens.Blue, gx, gy, gx + horizDots * 10, gy + scanlines * 10)
            gx = gx + horizDots * 10
            If gx + horizDots * 10 > frmSprite0.PictureBox3.Size.Width Then
                gx = 0
                gy = gy + scanlines * 10
            End If
        Next
    End Sub

    Sub setcolor(ByVal x As Integer, ByVal y As Integer, ByVal i As Integer)
        If i >= nImages() Then Return
        bitmap(y * horizDots + x + i * ImageSize()) = spriteColor
    End Sub

    Function getColor(ByVal x As Integer, ByVal y As Integer, ByVal i As Integer) As System.Drawing.Color
        If i >= nImages() Then Return System.Drawing.Color.Black
        Return bitmap(y * horizDots + x + i * ImageSize())
    End Function

    Sub SerializeToBin(ByVal n As Integer)
        Dim j As Integer
        Dim k As Integer
        Dim red As Integer
        Dim green As Integer
        Dim blue As Integer
        Dim c As Int16
        Dim c8 As Byte
        Dim bs As New System.IO.FileStream(baseSpriteFileName & n, IO.FileMode.Create)
        Dim bfs As New System.IO.BinaryWriter(bs)

        For j = 0 To scanlines - 1
            For k = 0 To horizDots - 1
                If frmSprite0.BPP() = 16 Then
                    red = ((bitmap(j * horizDots + k).R >> 3) And 31)
                    green = ((bitmap(j * horizDots + k).G >> 3) And 31)
                    blue = ((bitmap(j * horizDots + k).B >> 3) And 31)
                    c = (red << 10) Or (green << 5) Or blue
                    bfs.Write(c)
                Else
                    red = ((bitmap(j * horizDots + k).R >> 5) And 7)
                    green = ((bitmap(j * horizDots + k).G >> 5) And 7)
                    blue = ((bitmap(j * horizDots + k).B >> 6) And 3)
                    c8 = (red << 5) Or (green << 2) Or blue
                    bfs.Write(c8)
                End If
            Next
        Next
        bfs.Close()
    End Sub

    Sub SerializeToC(ByVal n As Integer)
        Dim j As Integer
        Dim nm As String
        Dim fl As System.IO.File
        nm = baseSpriteFileName.Replace(".c", n & ".c")
        Dim tfs As System.IO.TextWriter
        Dim c As Int16

        tfs = fl.CreateText(nm)
        If frmSprite0.BPP() = 16 Then
            tfs.WriteLine("char sprite" & n & "[1024] = {")
            For j = 0 To 1023
                If j Mod 16 = 0 Then
                    tfs.WriteLine("")
                End If
                c = ((bitmap(j).R >> 3) And 31) << 10
                c = c Or ((bitmap(j).G >> 3) And 31) << 5
                c = c Or ((bitmap(j).B >> 3) And 31)
                tfs.Write(c)
                If j <> 1023 Then
                    tfs.Write(",")
                End If
            Next
            tfs.WriteLine("};")
            tfs.Close()
        Else
            For j = 0 To 2047

            Next
        End If
    End Sub

    Sub SerializeFromBin(ByVal n As Integer)
        Dim j As Integer
        Dim k As Integer
        Dim red As Integer
        Dim green As Integer
        Dim blue As Integer
        Dim c0 As Int16
        Dim c1 As Int16
        Dim c As Integer
        Dim bs As New System.IO.FileStream("sprite" & n, IO.FileMode.Open)
        Dim bfs As New System.IO.BinaryReader(bs)
        Dim buffer(2048) As Byte

        bfs.Read(buffer, 0, 2048)
        If frmSprite0.BPP() = 16 Then
            For j = 0 To 1023
                c0 = buffer(j * 2)
                c1 = buffer(j * 2 + 1)
                If (c0 <> 0) Then
                    Console.WriteLine("non zoer")
                End If
                c = c0 + (c1 << 8)
                red = (c >> 10) And 31
                green = (c >> 5) And 31
                blue = c And 31
                bitmap(j) = bitmap(j).FromArgb(red << 3, green << 3, blue << 3)
            Next
        Else
            For j = 0 To 2048
                c = buffer(j)
                red = (c >> 5) And 7
                green = (c >> 2) And 7
                blue = c And 3
                bitmap(j) = bitmap(j).FromArgb(red << 5, green << 5, blue << 6)
            Next
        End If
        bfs.Close()
    End Sub

    Public Sub New()
        horizDots = 48
        scanlines = 42
    End Sub
End Class
