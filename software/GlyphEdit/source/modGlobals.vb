Module modGlobals
  Public glyphs(8192) As Glyph
  Public sprites(32) As Sprite
  Public spriteColor As New System.Drawing.Color
  Public frmSprite0 As frmSprite
  Public sprIndex As Integer
  Public sprScale As Integer
  Public baseSpriteFileName As String
  Public mapWidth As Integer
  Public bmpGlyphs As Bitmap
  Public bmpSprites(32) As Bitmap
  Public dotColor As Color
  Public aam As Boolean

  Sub main()
    Dim frm As New Form1

    mapWidth = 32
    aam = False
    frm.ShowDialog()
  End Sub

  Public Function nGlyphs() As Integer
    Dim sz As Integer
    sz = 8
    If Not glyphs(0) Is Nothing Then
      sz = (glyphs(0).horizDots + 7) >> 3  ' multiple of eight bits
      sz = sz * glyphs(0).scanlines       ' times scan lines
      sz = (sz + 7) And Not 7             ' multiple of eight bytes
    End If
    Return 65536L / sz
  End Function
End Module
