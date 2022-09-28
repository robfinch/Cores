Module modGlobals
  Public glyphs(8192) As Glyph
  Public sprites(32) As Sprite
  Public spriteColor As New System.Drawing.Color
    Public frmSprite0 As frmSprite
    Public baseSpriteFileName As String

    Sub main()
        Dim frm As New Form1

        frm.ShowDialog()
    End Sub
End Module
