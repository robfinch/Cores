Imports System.IO

Public Class Sprite
  Public index As Integer
  Public scanlines As Integer
  Public horizDots As Integer
  Public bitmap(4096) As System.Drawing.Color
  Function ImageSize() As Integer
    Return scanlines * horizDots
  End Function

  Function nImages() As Integer
    Dim sz As Double

    If frmSprite0.BPP() = 8 Then
      sz = 4096.0 / ImageSize()
    ElseIf frmSprite0.BPP() = 16 Then
      sz = 2048.0 / ImageSize()
    Else ' 32 bpp
      sz = 1024.0 / ImageSize()
    End If
    sz = Math.Floor(sz)
    Return sz
  End Function

  Sub Draw(ByVal e As System.Windows.Forms.PaintEventArgs, ByVal si As Integer)
    Dim g As Integer
    Dim j As Integer
    Dim k As Integer
    Dim br As Brush
    Dim red As Integer
    Dim green As Integer
    Dim blue As Integer
    Dim gx As Integer
    Dim gy As Integer
    Dim gx1 As Integer
    Dim gy1 As Integer
    Dim szsp As Integer

    On Error GoTo xit
    If bmpSprites(index) Is Nothing Then
      bmpSprites(index) = New Bitmap(horizDots * nImages(), scanlines)
    End If
    gx = 0
    gy = 0
    gx1 = 0
    gy1 = 0
    szsp = scanlines * horizDots
    For g = 0 To nImages() - 1
      For j = 0 To scanlines - 1
        For k = 0 To horizDots - 1
          gx = g * horizDots * sprScale
          gy = 0
          gx1 = si * horizDots
          gy1 = 0
          'red = ((bitmap(j * horizDots + k).R >> 3) And 31) << 3
          'green = ((bitmap(j * horizDots + k).G >> 3) And 31) << 3
          'blue = ((bitmap(j * horizDots + k).B >> 3) And 31) << 3
          'br = New SolidBrush(System.Drawing.Color.FromArgb(red, green, blue))
          br = New SolidBrush(bitmap(j * horizDots + k + si * szsp))
          e.Graphics.FillRectangle(br, gx + k * sprScale, gy + j * sprScale, sprScale, sprScale)
          bmpSprites(index).SetPixel(gx1 + k, gy1 + j, bitmap(j * horizDots + k + si * szsp))
        Next
      Next
      si = si + 1
      If si >= nImages() Then
        si = 0
      End If
    Next
    gx = 0
    gy = 0
    For g = 0 To nImages() - 1
      gx = g * horizDots * sprScale
      e.Graphics.DrawRectangle(System.Drawing.Pens.Blue, gx, gy, gx + horizDots * sprScale, gy + scanlines * sprScale)
      'If gx + horizDots * 10 > frmSprite0.PictureBox3.Size.Width Then
      'gx = 0
      'gy = gy + scanlines * 10
      'End If
    Next
xit:
  End Sub

  Sub setcolor(ByVal x As Integer, ByVal y As Integer, ByVal i As Integer)
    If i >= nImages() Then Return
    bitmap(y * horizDots + x + i * ImageSize()) = spriteColor
  End Sub

  Function getColor(ByVal x As Integer, ByVal y As Integer, ByVal i As Integer) As System.Drawing.Color
    If i >= nImages() Then Return System.Drawing.Color.Black
    Return bitmap(y * horizDots + x + i * ImageSize())
  End Function

  Sub SerializeToBmp(ByVal fnm As String)
    bmpSprites(index).Save(fnm)
  End Sub
  Sub SerializeFromBmp(ByVal fnm As String)
    Dim g As Integer
    Dim j As Integer
    Dim k As Integer
    Dim c As System.Drawing.Color
    Dim gx As Integer
    Dim gy As Integer
    Dim gx1 As Integer
    Dim gy1 As Integer
    Dim szsp As Integer
    Dim bm As Bitmap

    On Error GoTo xit
    gx = 0
    gy = 0
    gx1 = 0
    gy1 = 0
    szsp = scanlines * horizDots
    bmpSprites(index) = New Bitmap(horizDots * nImages(), scanlines)
    bm = New Bitmap(fnm)
    For g = 0 To nImages() - 1
      For j = 0 To scanlines - 1
        For k = 0 To horizDots - 1
          gx = g * horizDots + k
          gy = j
          If gx < bm.Width And gy < bm.Height Then
            bmpSprites(index).SetPixel(gx, gy, bm.GetPixel(gx, gy))
          Else
            bmpSprites(index).SetPixel(gx, gy, System.Drawing.Color.LightGray)
          End If
          c = bmpSprites(index).GetPixel(gx, gy)
          bitmap(j * horizDots + k + g * szsp) = c
        Next
      Next
    Next
    bm.Dispose()
xit:
  End Sub
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
  Public Function ToString(ByVal ndx As Integer) As String
    Dim j As Integer
    Dim s As String
    Dim c As Int16
    Dim lo As Integer
    Dim hi As Integer

    s = ""
    If ndx = -1 Then
      Select Case frmSprite0.BPP()
        Case 8
          lo = 0
          hi = 4095
        Case 16
          lo = 0
          hi = 2047
        Case 32
          lo = 0
          hi = 1023
      End Select
    Else
      Select Case frmSprite0.BPP()
        Case 8
          lo = 4096 * ndx / nImages()
          hi = 4096 * (ndx + 1) / nImages() - 1
        Case 16
          lo = 2048 * ndx / nImages()
          hi = 2048 * (ndx + 1) / nImages() - 1
        Case 32
          lo = 1024 * ndx / nImages()
          hi = 1024 * (ndx + 1) / nImages() - 1
      End Select
    End If
    If frmSprite0.BPP() = 8 Then
      For j = lo To hi
        If (j - lo) Mod 16 = 0 And j > 0 Then
          s = s & vbLf
        End If
        c = ((bitmap(j).R >> 5) And 7) << 5
        c = c Or ((bitmap(j).G >> 5) And 7) << 2
        c = c Or ((bitmap(j).B >> 6) And 3)
        s = s & Hex(c).PadLeft(2, "0")
        If (j - lo) Mod 4 = 0 And j < 2044 Then
          s = s & " "
        End If
      Next
    ElseIf frmSprite0.BPP() = 16 Then
      For j = lo To hi
        If (j - lo) Mod 16 = 0 And j > 0 Then
          s = s & vbLf
        ElseIf j > 0 And j < 2048 Then
          s = s & " "
        End If
        c = ((bitmap(j).R >> 3) And 31) << 10
        c = c Or ((bitmap(j).G >> 3) And 31) << 5
        c = c Or ((bitmap(j).B >> 3) And 31)
        s = s & Hex(c).PadLeft(4, "0")
      Next
    Else
      For j = lo To hi
        If (j - lo) Mod 16 = 0 And j > 0 Then
          s = s & vbLf
        End If
        c = (bitmap(j).R) << 16
        c = c Or (bitmap(j).G) << 8
        c = c Or bitmap(j).B
        s = s & Hex(c).PadLeft(8, "0")
        If j < 1023 Then
          s = s & " "
        End If
      Next
    End If
    Return s
  End Function
  Sub FromString(ByVal s As String, ByVal ndx As Integer)
    Dim j As Integer
    Dim vals() As String
    Dim chs(2) As Char
    Dim r As Int32
    Dim g As Int32
    Dim b As Int32
    Dim lo As Integer
    Dim hi As Integer

    On Error GoTo xit
    If ndx = -1 Then
      Select Case frmSprite0.BPP()
        Case 8
          lo = 0
          hi = 4095
        Case 16
          lo = 0
          hi = 2047
        Case 32
          lo = 0
          hi = 1023
      End Select
    Else
      Select Case frmSprite0.BPP()
        Case 8
          lo = 4096 * ndx / nImages()
          hi = 4096 * (ndx + 1) / nImages() - 1
        Case 16
          lo = 2048 * ndx / nImages()
          hi = 2048 * (ndx + 1) / nImages() - 1
        Case 32
          lo = 1024 * ndx / nImages()
          hi = 1024 * (ndx + 1) / nImages() - 1
      End Select
    End If

    chs(0) = " "
    chs(1) = vbLf
    vals = s.Split(chs)
    If frmSprite0.BPP() = 8 Then
      For j = lo To hi
        r = ((Convert.ToInt32(vals(j - lo), 16) >> 5) And 7) << 5
        g = ((Convert.ToInt32(vals(j - lo), 16) >> 2) And 7) << 5
        b = ((Convert.ToInt32(vals(j - lo), 16)) And 3) << 6
        bitmap(j) = System.Drawing.Color.FromArgb(r, g, b)
      Next
    ElseIf frmSprite0.BPP() = 16 Then
      For j = lo To hi
        r = ((Convert.ToInt32(vals(j - lo), 16) >> 10) And 31) << 3
        g = ((Convert.ToInt32(vals(j - lo), 16) >> 5) And 31) << 3
        b = ((Convert.ToInt32(vals(j - lo), 16)) And 31) << 3
        bitmap(j) = System.Drawing.Color.FromArgb(r, g, b)
      Next
    Else
      For j = lo To hi
        r = ((Convert.ToInt32(vals(j - lo), 16) >> 16) And 255)
        g = ((Convert.ToInt32(vals(j - lo), 16) >> 8) And 255)
        b = ((Convert.ToInt32(vals(j - lo), 16)) And 255)
        bitmap(j) = System.Drawing.Color.FromArgb(r, g, b)
      Next
    End If
xit:
  End Sub
  Sub SerializeToMem(ByVal nm As String)
    Dim fl As System.IO.File
    Dim tfs As System.IO.TextWriter

    tfs = fl.CreateText(nm)
    tfs.Write(ToString(-1))
    tfs.Close()
  End Sub
  Sub SerializeFromMem(ByVal nm As String)
    Dim fl As System.IO.File
    Dim tfs As System.IO.TextReader
    Dim s As String

    tfs = fl.OpenText(nm)
    s = tfs.ReadToEnd()
    tfs.Close()
    FromString(s, -1)
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
    horizDots = 56
    scanlines = 36
  End Sub
End Class
