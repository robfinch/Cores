Imports System.IO

Public Class Glyph
  Public Count As Integer
  Public index As Integer
  Public str As String
  Public scanlines As Integer
  Public horizDots As Integer
  Private bitmap(32, 32) As Boolean

  Public Sub SetBitmap(ByVal r As Integer, ByVal b As Integer)
    Dim j As Integer
    For j = 0 To horizDots
      bitmap(r, j) = (b >> j) And 1
    Next
  End Sub
  Public Sub FlipBit(ByVal x As Integer, ByVal y As Integer)
    bitmap(y, x) = Not bitmap(y, x)
  End Sub

  Public Sub FlipHoriz()
    Dim j As Integer
    Dim b As Boolean
    Dim k As Integer

    For j = 0 To scanlines - 1
      For k = 0 To horizDots / 2
        b = bitmap(j, k)
        bitmap(j, k) = bitmap(j, horizDots - k - 1)
        bitmap(j, horizDots - k - 1) = b
      Next
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
  Public Function SerializeFromCoe(str As String)
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim scnlns() As String

    scnlns = Split(str, ",")
    For j = 0 To scanlines - 1
      n = Convert.ToUInt64(scnlns(j))
      For k = 0 To horizDots - 1
        bitmap(j, k) = n & 1
        n = n >> 1
      Next
    Next

  End Function
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

  Public Sub WriteByte(ByVal ofs As TextWriter, str As String, k As Integer)
    Count = index * scanlines + k
    If (Count Mod 8) = 0 Then
      If (Count > 0) Then
        ofs.Write(";" & vbCrLf)
      End If
      ofs.Write("mem[" & Count / 8 & "] = 64'b")
    End If
    ofs.Write(str)
    Count = Count + 1
  End Sub
  Public Sub WriteWyde(ByVal ofs As TextWriter, str As String, k As Integer)
    Count = index * scanlines + k
    If (Count Mod 4) = 0 Then
      If (Count > 0) Then
        ofs.Write(";" & vbCrLf)
      End If
      ofs.Write("mem[" & Count / 4 & "] = 64'b")
    End If
    ofs.Write(str)
    Count = Count + 1
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
        WriteByte(ofs, s, j)
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
        WriteWyde(ofs, s, j)
      Next
    End If
  End Sub

  Sub Draw(ByVal e As System.Windows.Forms.PaintEventArgs)
    Dim j As Integer
    Dim k As Integer
    Dim sc As Integer
    Dim fnt As Font

    fnt = New Font("Courier New", 36)
    If horizDots < 9 And scanlines < 9 Then
      sc = 20
    ElseIf horizDots < 17 And scanlines < 25 Then
      sc = 10
    End If
    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 1
        If bitmap(j, k) Then
          REM          e.Graphics.FillRectangle(Brushes.Black, k * sc, j * sc, sc, sc)
        Else
          e.Graphics.FillRectangle(Brushes.White, k * sc, j * sc, sc, sc)
        End If
      Next
    Next
    If index < 256 Then
      e.Graphics.DrawString(Chr(index), fnt, Brushes.Black, k * sc, j * sc)
    End If

  End Sub

  Sub DrawSmall(ByVal e As System.Windows.Forms.PaintEventArgs)
    Dim j As Integer
    Dim k As Integer
    Dim x As Integer
    Dim y As Integer

    x = (index Mod 32) * horizDots * 2
    y = (index >> 5)
    y = y * (scanlines * 2)

    For j = 0 To scanlines - 1
      For k = 0 To horizDots - 1
        If bitmap(j, k) Then
          e.Graphics.FillRectangle(Brushes.Black, k * 2 + x, j * 2 + y, 2, 2)
        Else
          e.Graphics.FillRectangle(Brushes.White, k * 2 + x, j * 2 + y, 2, 2)
        End If
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
