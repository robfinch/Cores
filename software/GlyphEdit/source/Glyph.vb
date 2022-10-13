Imports System.IO

Public Class Glyph
  Public Count As Integer
  Public index As Integer
  Public str As String
  Public scanlines As Integer
  Public horizDots As Integer
  Private bitmap(32, 32) As Boolean
  Public Sub Clone(g As Glyph)
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 1
      For k = 0 To horizDots / 2 - 1
        bitmap(j, k) = g.bitmap(j, k)
      Next
    Next
  End Sub
  Public Sub SetBitmap(ByVal r As Integer, ByVal b As Integer)
    Dim j As Integer
    For j = 0 To horizDots - 1
      bitmap(r, j) = (b >> j) And 1
    Next
  End Sub
  Public Sub FlipBit(ByVal x As Integer, ByVal y As Integer)
    bitmap(y, x) = Not bitmap(y, x)
  End Sub
  Public Sub SetBit(ByVal x As Integer, ByVal y As Integer)
    bitmap(y, x) = True
  End Sub
  Public Sub ClearBit(ByVal x As Integer, ByVal y As Integer)
    bitmap(y, x) = False
  End Sub


  Public Sub FlipHoriz()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 1
      For k = 0 To horizDots / 2 - 1
        b = bitmap(j, k)
        bitmap(j, k) = bitmap(j, horizDots - k - 1)
        bitmap(j, horizDots - k - 1) = b
      Next
    Next
  End Sub
  Public Sub ShiftLeft()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 1
      For k = horizDots - 1 To 1 Step -1
        bitmap(j, k) = bitmap(j, k - 1)
      Next
      bitmap(j, 0) = 0
    Next
  End Sub
  Public Sub ShiftRight()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 2
        bitmap(j, k) = bitmap(j, k + 1)
      Next
      bitmap(j, horizDots - 1) = 0
    Next
  End Sub
  Public Sub ShiftUp()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 2
      For k = 0 To horizDots - 1
        bitmap(j, k) = bitmap(j + 1, k)
      Next
    Next
    For k = 0 To horizDots - 1
      bitmap(scanlines - 1, k) = 0
    Next
  End Sub
  Public Sub ShiftDown()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = scanlines - 1 To 1 Step -1
      For k = 0 To horizDots - 1
        bitmap(j, k) = bitmap(j - 1, k)
      Next
    Next
    For k = 0 To horizDots - 1
      bitmap(0, k) = 0
    Next
  End Sub
  Public Function SerializeToUCF() As String
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim s As String
    Dim b As Integer

    s = ""
    For j = 0 To scanlines - 1
      n = 0
      For k = 0 To horizDots - 1
        b = bitmap(j, k) And 1
        n = n Or (b << k)
      Next
      If horizDots <= 4 Then
        s = Hex(n).PadLeft(1, "0") & s
      ElseIf horizDots <= 8 Then
        s = Hex(n).PadLeft(2, "0") & s
      ElseIf horizDots <= 12 Then
        s = Hex(n).PadLeft(3, "0") & s
      ElseIf horizDots <= 16 Then
        s = Hex(n).PadLeft(4, "0") & s
      ElseIf horizDots <= 20 Then
        s = Hex(n).PadLeft(5, "0") & s
      ElseIf horizDots <= 24 Then
        s = Hex(n).PadLeft(6, "0") & s
      ElseIf horizDots <= 28 Then
        s = Hex(n).PadLeft(7, "0") & s
      ElseIf horizDots <= 32 Then
        s = Hex(n).PadLeft(8, "0") & s
      End If
    Next
    Return s
  End Function
  Public Sub SerializeFromCoe(str As String)
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim scnlns() As String

    scnlns = Split(str, ",")
    For j = 0 To scanlines - 1
      n = Convert.ToUInt64(scnlns(j))
      For k = 0 To horizDots - 1
        bitmap(j, k) = n And 1
        n = n >> 1
      Next
    Next

  End Sub
  Public Sub SerializeFromMem(str As String, ByVal sz As Integer)
    Dim j As Integer
    Dim k As Integer
    Dim w As Integer
    Dim n As UInt64
    Dim shifts As Integer
    Dim scnlns() As String
    Dim m As Integer
    Dim sl(64) As UInt64
    Dim bits As UInt64
    Dim t As UInt64

    scnlns = Split(str, " ")
    w = 0
    shifts = sz
    bits = 0
    If sz = 64 Then
      For j = 0 To scnlns.Length - 1
        sl(j) = Convert.ToUInt64(scnlns(j), 16)
      Next
      For j = 0 To scanlines - 1
        For m = 0 To horizDots - 1 Step 8
          t = (sl(w) >> bits) And 255UL
          bits += 8
          n = n Or (t << m)
          If bits = 64 Then
            w += 1
            bits = 0
          End If
        Next
        For k = horizDots - 1 To 0 Step -1
          bitmap(j, k) = n And 1
          n = n >> 1
        Next
      Next
      Return
    End If
    For j = 0 To scanlines - 1
      ' Grab next data item if shifts done
      If shifts >= sz Then
        shifts = 0
        n = Convert.ToUInt64(scnlns(w), 16)
        w += 1
        If sz < horizDots Then
          For m = sz To horizDots Step sz
            n = n Or (Convert.ToUInt64(scnlns(w), 16) << m)
            w += 1
          Next
        End If
      End If
      For k = horizDots - 1 To 0 Step -1
        bitmap(j, k) = n And 1
        n = n >> 1
        shifts = shifts + 1
      Next
      ' Shift out the remainder of the byte
      If horizDots Mod 64 Then
        For k = 0 To 64 - (horizDots Mod 64)
          n = n >> 1
          shifts = shifts + 1
        Next
      End If
    Next
  End Sub
  Sub SerializeFromBin(ary As Array)
    Dim j As Integer
    Dim k As Integer
    Dim m As Integer
    Dim b As Byte

    m = 0
    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 1
        If k Mod 8 = 0 Then
          b = ary(m)
          m = m + 1
        End If
        bitmap(j, k) = (b And 128) <> 0
        b <<= 1
      Next
    Next
  End Sub
  Public Function SerializeToCoe() As String
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim s As String
    Dim b As Integer

    s = ""
    For j = 0 To scanlines - 1
      n = 0
      For k = 0 To horizDots - 1
        b = bitmap(j, k) And 1
        n = n Or (b << k)
      Next
      s = s & n
      If j <> scanlines - 1 Then
        s = s & "," & vbLf
      End If
    Next
    Return s

  End Function

  Public Function SerializeToMem(ByVal sz As Integer) As String
    Dim j As Integer
    Dim k As UInt64
    Dim w As Integer
    Dim n As UInt64
    Dim m As UInt64
    Dim s As String
    Dim b As Integer
    Dim ss As String
    Dim s1 As String
    Dim ts As String
    Dim sl(64) As UInt64
    Dim bits As UInt64

    s = ""
    If sz = 64 Then
      m = 0
      For j = 0 To scanlines - 1
        n = 0
        For k = 0 To horizDots - 1
          b = bitmap(j, k) And 1
          n = n Or (b << (horizDots - k - 1))
        Next
        sl(j) = n
      Next
      bits = 0
      For j = 0 To scanlines - 1
        For k = 0 To horizDots - 1 Step 8UL
          m = m Or (((sl(j) >> k) And 255UL) << bits)
          bits += 8
          If bits = 64 Then
            ss = Hex(m).PadLeft(16, "0")
            s = s & " " & ss
            m = 0
            bits = 0
          End If
        Next
      Next
      If bits <> 0 Then
        ss = Hex(m).PadLeft(16, "0")
        s = s & " " & ss
      End If
      Return s.Trim
    End If
    s1 = ""
    For j = 0 To scanlines - 1
      n = 0
      For k = 0 To horizDots - 1
        b = bitmap(j, k) And 1
        n = n Or (b << (horizDots - k - 1))
      Next
      If (horizDots < 9) Then
        ss = Hex(n).PadLeft(2, "0")
      ElseIf (horizDots < 17) Then
        ss = Hex(n).PadLeft(4, "0")
      ElseIf (horizDots < 25) Then
        ss = Hex(n).PadLeft(6, "0")
      Else
        ss = Hex(n).PadLeft(8, "0")
      End If
      If (sz = 8) Then
        ts = ""
        For w = 0 To ss.Length - 1 Step 2
          If w = 0 Then
            ts = ss.Substring(w, 2)
          Else
            ts = ss.Substring(w, 2) & " " & ts
          End If
        Next
      Else
        ts = ss
      End If
      If sz = 64 Then
        If s1.Length < 16 Then
          s1 = ts & s1
        Else
          s = s & " " & s1
          s1 = ""
        End If
      Else
        s = s & " " & s1
      End If
    Next
    If s1 <> "" Then
      s = s & " " & s1
    End If
    Return s
  End Function

  Function SerializeToBin() As Array
    Dim j As Integer
    Dim k As Integer
    Dim m As Integer
    Dim w As Double
    Dim h As Double
    Dim sz As Integer
    Dim ary() As Byte
    Dim b As Byte

    w = Math.Floor((horizDots + 7) / 8)
    h = scanlines
    sz = (w * h + 7) And Not 7
    ReDim ary(sz - 1)
    m = 0
    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 1
        If k Mod 8 = 0 And k > 0 Then
          ary(m) = b
          m += 1
        End If
        If k Mod 8 = 0 Then b = 0
        b = (b << 1) Or (bitmap(j, k) And 1)
      Next
      For k = k To w * 8 - 1
        b = b << 1
      Next
      If horizDots Mod 8 <> 0 Then
        ary(m) = b
        m += 1
      End If
    Next
    While m Mod 8 <> 0
      ary(m) = 0
      m += 1
    End While
    Return ary
  End Function

  Public Sub SerializeToV(ByVal ofs As TextWriter)
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim s As String

    s = "// Glpyh: " & index & vbCrLf
    For j = 0 To scanlines - 1
      s = s & "mem[" & index * scanlines + j & "] = "
      s = s & horizDots & "'b"
      For k = horizDots - 1 To 0 Step -1
        If bitmap(j, k) Then
          s = s & "1"
        Else
          s = s & "0"
        End If
      Next
      s = s & ";" & vbCrLf
    Next
    ofs.Write(s)
  End Sub


  ' ws = word size
  Public Sub WriteScanline(ByVal ofs As TextWriter, ByVal str As String, k As Integer, spw As Integer, ws As Integer)
    Count = (index * scanlines + k) * ws
    ofs.Write("mem[" & Count + spw & "] = 8'b")
    ofs.Write(str)
    ofs.Write(";" & vbCrLf)
  End Sub


  Public Sub Flush(ByVal ofs As TextWriter)
    If (Count And 7) <> 0 Then
      ofs.Write(";" & vbCrLf)
    End If
  End Sub

  Public Sub SerializeToV64(ByVal ofs As TextWriter)
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim s As String

    REM    s = "// Glpyh: " & index & vbCrLf
    If (horizDots < 9) Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To horizDots - 1
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        For k = horizDots To 7
          s = s & "0"
        Next
        WriteScanline(ofs, s, j, 1, 1)
      Next
    ElseIf horizDots < 17 Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To 7
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 0, 2)
        s = ""
        For k = 8 To 15
          If k < horizDots Then
            If bitmap(j, k) Then
              s = s & "1"
            Else
              s = s & "0"
            End If
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 1, 2)
      Next
    ElseIf horizDots < 33 Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To 7
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 0, 4)
        s = ""
        For k = 8 To 15
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 1, 4)
        For k = 16 To 23
          If k < horizDots Then
            If bitmap(j, k) Then
              s = s & "1"
            Else
              s = s & "0"
            End If
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 2, 4)
        For k = 24 To 31
          If k < horizDots Then
            If bitmap(j, k) Then
              s = s & "1"
            Else
              s = s & "0"
            End If
          Else
            s = s & "0"
          End If
        Next
        WriteScanline(ofs, s, j, 3, 4)
      Next
    End If
  End Sub
  Public Sub SerializeToV32(ByVal ofs As TextWriter)
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim s As String

    REM    s = "// Glpyh: " & index & vbCrLf
    If (horizDots < 9) Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To horizDots - 1
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        For k = horizDots To 7
          s = s & "0"
        Next
        WriteScanline(ofs, s, j, 4, 32)
      Next
    ElseIf horizDots < 17 Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To horizDots - 1
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        For k = horizDots To 15
          s = s & "0"
        Next
        WriteScanline(ofs, s, j, 2, 32)
      Next
    ElseIf horizDots < 33 Then
      For j = 0 To scanlines - 1
        s = ""
        For k = 0 To horizDots - 1
          If bitmap(j, k) Then
            s = s & "1"
          Else
            s = s & "0"
          End If
        Next
        For k = horizDots To 31
          s = s & "0"
        Next
        WriteScanline(ofs, s, j, 1, 32)
      Next
    End If
  End Sub

  Sub Draw(ByVal e As System.Windows.Forms.PaintEventArgs)
    Dim j As Integer
    Dim k As Integer
    Dim kk As Integer
    Dim sc As Integer
    Dim fnt As Font
    Dim pix As Integer
    Dim stp As Integer

    If aam Then stp = 2 Else stp = 1
    fnt = New Font("Courier New", 36)
    If horizDots < 9 And scanlines < 9 Then
      sc = 20
    ElseIf horizDots < 17 And scanlines < 25 Then
      sc = 10
    Else
      sc = 5
    End If
    For j = 0 To scanlines - 1
      kk = 0
      For k = 0 To horizDots - 1 Step stp
        If stp = 1 Then
          pix = ((bitmap(j, k) And 1) << 1) Or (bitmap(j, k) And 1)
        Else
          pix = ((bitmap(j, k) And 1) << 1) Or (bitmap(j, k + 1) And 1)
        End If
        Select Case pix
          Case 0
            e.Graphics.FillRectangle(Brushes.White, kk * sc, j * sc, sc, sc)
          Case 1
            e.Graphics.FillRectangle(Brushes.LightGray, kk * sc, j * sc, sc, sc)
          Case 2
            e.Graphics.FillRectangle(Brushes.DarkGray, kk * sc, j * sc, sc, sc)
          Case 3
            e.Graphics.FillRectangle(Brushes.Black, kk * sc, j * sc, sc, sc)
        End Select
        '        If bitmap(j, k) Then
        '       e.Graphics.FillRectangle(Brushes.Black, k * sc, j * sc, sc, sc)
        '      Else
        '     e.Graphics.FillRectangle(Brushes.White, k * sc, j * sc, sc, sc)
        '    End If
        kk += 1
      Next
    Next
    If index < 256 Then
      e.Graphics.DrawString(Chr(index), fnt, Brushes.Black, k * sc, j * sc)
    End If

  End Sub

  Sub DrawSmall(ByVal e As System.Windows.Forms.PaintEventArgs)
    Dim j As Integer
    Dim k As Integer
    Dim kk As Integer
    Dim x As Integer
    Dim y As Integer
    Dim w As Double
    Dim pix As Integer
    Dim stp As Integer

    If aam Then
      x = (index Mod mapWidth) * horizDots
      stp = 2
    Else
      x = (index Mod mapWidth) * horizDots * 2
      stp = 1
    End If
    w = Math.Floor(index / mapWidth)
    y = w * (scanlines * 2)

    For j = 0 To scanlines - 1
      kk = 0
      For k = 0 To horizDots - 1 Step stp
        If stp = 1 Then
          pix = ((bitmap(j, k) And 1) << 1) Or (bitmap(j, k) And 1)
        Else
          pix = ((bitmap(j, k) And 1) << 1) Or (bitmap(j, k + 1) And 1)
        End If
        If x < bmpGlyphs.Width - horizDots Then
          Select Case pix
            Case 3
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y, Color.Black)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y, Color.Black)
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y + 1, Color.Black)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y + 1, Color.Black)
              e.Graphics.FillRectangle(Brushes.Black, k * 2 + x, j * 2 + y, 2, 2)
            Case 2
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y, Color.DarkGray)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y, Color.DarkGray)
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y + 1, Color.DarkGray)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y + 1, Color.DarkGray)
              e.Graphics.FillRectangle(Brushes.DarkGray, k * 2 + x, j * 2 + y, 2, 2)
            Case 1
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y, Color.LightGray)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y, Color.LightGray)
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y + 1, Color.LightGray)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y + 1, Color.LightGray)
              e.Graphics.FillRectangle(Brushes.LightGray, k * 2 + x, j * 2 + y, 2, 2)
            Case 0
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y, Color.White)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y, Color.White)
              bmpGlyphs.SetPixel(kk * 2 + x, j * 2 + y + 1, Color.White)
              bmpGlyphs.SetPixel(kk * 2 + x + 1, j * 2 + y + 1, Color.White)
              e.Graphics.FillRectangle(Brushes.White, k * 2 + x, j * 2 + y, 2, 2)
          End Select
        End If

        'If bitmap(j, k) Then
        'Form1.DrawToBitmap(Form1.PictureBox2.Image, New Rectangle(k * 2 + x, j * 2 + y, 2, 2))
        'bmpGlyphs.SetPixel(k * 2 + x, j * 2 + y, Color.Black)
        'bmpGlyphs.SetPixel(k * 2 + x + 1, j * 2 + y, Color.Black)
        'bmpGlyphs.SetPixel(k * 2 + x, j * 2 + y + 1, Color.Black)
        'bmpGlyphs.SetPixel(k * 2 + x + 1, j * 2 + y + 1, Color.Black)
        'e.Graphics.FillRectangle(Brushes.Black, k * 2 + x, j * 2 + y, 2, 2)
        'Else
        'Form1.DrawToBitmap(Form1.PictureBox2.Image, New Rectangle(k * 2 + x, j * 2 + y, 2, 2))
        'bmpGlyphs.SetPixel(k * 2 + x, j * 2 + y, Color.White)
        'bmpGlyphs.SetPixel(k * 2 + x + 1, j * 2 + y, Color.White)
        'bmpGlyphs.SetPixel(k * 2 + x, j * 2 + y + 1, Color.White)
        'bmpGlyphs.SetPixel(k * 2 + x + 1, j * 2 + y + 1, Color.White)
        'e.Graphics.FillRectangle(Brushes.White, k * 2 + x, j * 2 + y, 2, 2)
        'End If
        kk += 1
      Next
    Next
  End Sub
  Sub UndrawSmall()
    Dim j As Integer
    Dim k As Integer
    Dim x As Integer
    Dim y As Integer
    Dim w As Double
    Dim bm As Bitmap

    bm = bmpGlyphs
    x = (index Mod mapWidth) * horizDots * 2
    w = Math.Floor(index / mapWidth)
    y = w * (scanlines * 2)

    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 1
        bitmap(j, k) = bm.GetPixel(k * 2 + x, j * 2 + y) <> bm.GetPixel(0, 0)
      Next
    Next
  End Sub

  Sub DrawSmall2(ByVal e As System.Windows.Forms.PaintEventArgs)
    Dim x As Integer
    Dim y As Integer
    Dim fnt As Font
    Dim c As Color

    fnt = New Font("Courier New", 24)
    x = (index Mod 32) * horizDots * 2
    y = (index >> 5)
    y = y * (scanlines * 2)
    e.Graphics.DrawString(Chr(index), fnt, Brushes.Black, x, y)

  End Sub

  Public Sub New()
    horizDots = 8
    scanlines = 8
  End Sub
End Class
