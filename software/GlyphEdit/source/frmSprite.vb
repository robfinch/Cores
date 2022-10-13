Imports System.IO

Public Class frmSprite
  Inherits System.Windows.Forms.Form


  Dim gwidth As Integer
  Dim gheight As Integer
  Dim mouseDwn As Boolean
  Dim pt As System.Drawing.Point
  Friend WithEvents RadioButton3 As RadioButton
  Friend WithEvents Button1 As Button
  Friend WithEvents Button2 As Button
  Friend WithEvents Panel1 As Panel
  Friend WithEvents PictureBox3 As PictureBox
  Friend WithEvents Button3 As Button
  Friend WithEvents Button4 As Button
  Friend WithEvents TrackBar1 As TrackBar
  Friend WithEvents Button6 As Button
  Friend WithEvents Button7 As Button
  Friend WithEvents TrackBar2 As TrackBar
  Dim fillOverColor As System.Drawing.Color

#Region " Windows Form Designer generated code "

  Public Sub New()
    MyBase.New()
    Dim n As Integer

    'This call is required by the Windows Form Designer.
    InitializeComponent()

    'Add any initialization after the InitializeComponent() call
    sprIndex = 0
    sprScale = 10
    For n = 0 To 31
      sprites(n) = New Sprite
      sprites(n).index = n
      sprites(n).scanlines = 56
      sprites(n).horizDots = 36
    Next

  End Sub

  'Form overrides dispose to clean up the component list.
  Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
    If disposing Then
      If Not (components Is Nothing) Then
        components.Dispose()
      End If
    End If
    MyBase.Dispose(disposing)
  End Sub

  'Required by the Windows Form Designer
  Private components As System.ComponentModel.IContainer

  'NOTE: The following procedure is required by the Windows Form Designer
  'It can be modified using the Windows Form Designer.  
  'Do not modify it using the code editor.
  Friend WithEvents ListBox2 As System.Windows.Forms.ListBox
  Friend WithEvents Button5 As System.Windows.Forms.Button
  Friend WithEvents NumericUpDown4 As System.Windows.Forms.NumericUpDown
  Friend WithEvents Label5 As System.Windows.Forms.Label
  Friend WithEvents Label4 As System.Windows.Forms.Label
  Friend WithEvents NumericUpDown3 As System.Windows.Forms.NumericUpDown
  Friend WithEvents MainMenu1 As System.Windows.Forms.MainMenu
  Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
  Friend WithEvents MenuItem2 As System.Windows.Forms.MenuItem
  Friend WithEvents MenuItem3 As System.Windows.Forms.MenuItem
  Friend WithEvents RadioButton1 As System.Windows.Forms.RadioButton
  Friend WithEvents RadioButton2 As System.Windows.Forms.RadioButton
  Friend WithEvents MenuItem4 As System.Windows.Forms.MenuItem
  Friend WithEvents ContextMenu1 As System.Windows.Forms.ContextMenu
  Friend WithEvents ContextMenu2 As System.Windows.Forms.ContextMenu
  <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
    Me.components = New System.ComponentModel.Container()
    Me.ListBox2 = New System.Windows.Forms.ListBox()
    Me.ContextMenu1 = New System.Windows.Forms.ContextMenu()
    Me.Button5 = New System.Windows.Forms.Button()
    Me.NumericUpDown4 = New System.Windows.Forms.NumericUpDown()
    Me.Label5 = New System.Windows.Forms.Label()
    Me.Label4 = New System.Windows.Forms.Label()
    Me.NumericUpDown3 = New System.Windows.Forms.NumericUpDown()
    Me.MainMenu1 = New System.Windows.Forms.MainMenu(Me.components)
    Me.MenuItem1 = New System.Windows.Forms.MenuItem()
    Me.MenuItem3 = New System.Windows.Forms.MenuItem()
    Me.MenuItem2 = New System.Windows.Forms.MenuItem()
    Me.MenuItem4 = New System.Windows.Forms.MenuItem()
    Me.RadioButton1 = New System.Windows.Forms.RadioButton()
    Me.RadioButton2 = New System.Windows.Forms.RadioButton()
    Me.ContextMenu2 = New System.Windows.Forms.ContextMenu()
    Me.RadioButton3 = New System.Windows.Forms.RadioButton()
    Me.Button1 = New System.Windows.Forms.Button()
    Me.Button2 = New System.Windows.Forms.Button()
    Me.Panel1 = New System.Windows.Forms.Panel()
    Me.PictureBox3 = New System.Windows.Forms.PictureBox()
    Me.Button3 = New System.Windows.Forms.Button()
    Me.Button4 = New System.Windows.Forms.Button()
    Me.TrackBar1 = New System.Windows.Forms.TrackBar()
    Me.Button6 = New System.Windows.Forms.Button()
    Me.Button7 = New System.Windows.Forms.Button()
    Me.TrackBar2 = New System.Windows.Forms.TrackBar()
    CType(Me.NumericUpDown4, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.Panel1.SuspendLayout()
    CType(Me.PictureBox3, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.TrackBar1, System.ComponentModel.ISupportInitialize).BeginInit()
    CType(Me.TrackBar2, System.ComponentModel.ISupportInitialize).BeginInit()
    Me.SuspendLayout()
    '
    'ListBox2
    '
    Me.ListBox2.Location = New System.Drawing.Point(85, 16)
    Me.ListBox2.Name = "ListBox2"
    Me.ListBox2.Size = New System.Drawing.Size(51, 225)
    Me.ListBox2.TabIndex = 184
    '
    'ContextMenu1
    '
    '
    'Button5
    '
    Me.Button5.Location = New System.Drawing.Point(48, 312)
    Me.Button5.Name = "Button5"
    Me.Button5.Size = New System.Drawing.Size(75, 23)
    Me.Button5.TabIndex = 190
    Me.Button5.Text = "Color"
    '
    'NumericUpDown4
    '
    Me.NumericUpDown4.Location = New System.Drawing.Point(72, 288)
    Me.NumericUpDown4.Maximum = New Decimal(New Integer() {64, 0, 0, 0})
    Me.NumericUpDown4.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
    Me.NumericUpDown4.Name = "NumericUpDown4"
    Me.NumericUpDown4.Size = New System.Drawing.Size(53, 20)
    Me.NumericUpDown4.TabIndex = 189
    Me.NumericUpDown4.TextAlign = System.Windows.Forms.HorizontalAlignment.Center
    Me.NumericUpDown4.Value = New Decimal(New Integer() {36, 0, 0, 0})
    '
    'Label5
    '
    Me.Label5.Location = New System.Drawing.Point(8, 288)
    Me.Label5.Name = "Label5"
    Me.Label5.Size = New System.Drawing.Size(60, 20)
    Me.Label5.TabIndex = 188
    Me.Label5.Text = "Height"
    '
    'Label4
    '
    Me.Label4.Location = New System.Drawing.Point(16, 264)
    Me.Label4.Name = "Label4"
    Me.Label4.Size = New System.Drawing.Size(54, 19)
    Me.Label4.TabIndex = 187
    Me.Label4.Text = "Width"
    '
    'NumericUpDown3
    '
    Me.NumericUpDown3.Location = New System.Drawing.Point(72, 264)
    Me.NumericUpDown3.Maximum = New Decimal(New Integer() {64, 0, 0, 0})
    Me.NumericUpDown3.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
    Me.NumericUpDown3.Name = "NumericUpDown3"
    Me.NumericUpDown3.Size = New System.Drawing.Size(53, 20)
    Me.NumericUpDown3.TabIndex = 186
    Me.NumericUpDown3.TextAlign = System.Windows.Forms.HorizontalAlignment.Center
    Me.NumericUpDown3.Value = New Decimal(New Integer() {56, 0, 0, 0})
    '
    'MainMenu1
    '
    Me.MainMenu1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem1})
    '
    'MenuItem1
    '
    Me.MenuItem1.Index = 0
    Me.MenuItem1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem3, Me.MenuItem2, Me.MenuItem4})
    Me.MenuItem1.Text = "&File"
    '
    'MenuItem3
    '
    Me.MenuItem3.Index = 0
    Me.MenuItem3.Text = "&Open"
    '
    'MenuItem2
    '
    Me.MenuItem2.Index = 1
    Me.MenuItem2.Text = "&Save"
    '
    'MenuItem4
    '
    Me.MenuItem4.Index = 2
    Me.MenuItem4.Text = "Save &As"
    '
    'RadioButton1
    '
    Me.RadioButton1.Checked = True
    Me.RadioButton1.Location = New System.Drawing.Point(11, 385)
    Me.RadioButton1.Name = "RadioButton1"
    Me.RadioButton1.Size = New System.Drawing.Size(104, 24)
    Me.RadioButton1.TabIndex = 191
    Me.RadioButton1.TabStop = True
    Me.RadioButton1.Text = "16 bpp"
    '
    'RadioButton2
    '
    Me.RadioButton2.Location = New System.Drawing.Point(11, 415)
    Me.RadioButton2.Name = "RadioButton2"
    Me.RadioButton2.Size = New System.Drawing.Size(104, 24)
    Me.RadioButton2.TabIndex = 192
    Me.RadioButton2.Text = "8 bpp"
    '
    'RadioButton3
    '
    Me.RadioButton3.Location = New System.Drawing.Point(11, 439)
    Me.RadioButton3.Name = "RadioButton3"
    Me.RadioButton3.Size = New System.Drawing.Size(104, 24)
    Me.RadioButton3.TabIndex = 193
    Me.RadioButton3.Text = "32 bpp"
    '
    'Button1
    '
    Me.Button1.Location = New System.Drawing.Point(19, 16)
    Me.Button1.Name = "Button1"
    Me.Button1.Size = New System.Drawing.Size(60, 23)
    Me.Button1.TabIndex = 194
    Me.Button1.Text = "Copy"
    Me.Button1.UseVisualStyleBackColor = True
    '
    'Button2
    '
    Me.Button2.Location = New System.Drawing.Point(19, 45)
    Me.Button2.Name = "Button2"
    Me.Button2.Size = New System.Drawing.Size(60, 23)
    Me.Button2.TabIndex = 195
    Me.Button2.Text = "Paste"
    Me.Button2.UseVisualStyleBackColor = True
    '
    'Panel1
    '
    Me.Panel1.AutoScroll = True
    Me.Panel1.Controls.Add(Me.PictureBox3)
    Me.Panel1.Location = New System.Drawing.Point(209, 45)
    Me.Panel1.Name = "Panel1"
    Me.Panel1.Size = New System.Drawing.Size(592, 650)
    Me.Panel1.TabIndex = 196
    '
    'PictureBox3
    '
    Me.PictureBox3.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
    Me.PictureBox3.ContextMenu = Me.ContextMenu1
    Me.PictureBox3.Location = New System.Drawing.Point(3, 0)
    Me.PictureBox3.Name = "PictureBox3"
    Me.PictureBox3.Size = New System.Drawing.Size(589, 650)
    Me.PictureBox3.TabIndex = 187
    Me.PictureBox3.TabStop = False
    '
    'Button3
    '
    Me.Button3.Location = New System.Drawing.Point(26, 499)
    Me.Button3.Name = "Button3"
    Me.Button3.Size = New System.Drawing.Size(75, 23)
    Me.Button3.TabIndex = 197
    Me.Button3.Text = "Rotate Left"
    Me.Button3.UseVisualStyleBackColor = True
    '
    'Button4
    '
    Me.Button4.Location = New System.Drawing.Point(26, 528)
    Me.Button4.Name = "Button4"
    Me.Button4.Size = New System.Drawing.Size(75, 23)
    Me.Button4.TabIndex = 198
    Me.Button4.Text = "Rotate Right"
    Me.Button4.UseVisualStyleBackColor = True
    '
    'TrackBar1
    '
    Me.TrackBar1.Location = New System.Drawing.Point(151, -6)
    Me.TrackBar1.Maximum = 15
    Me.TrackBar1.Name = "TrackBar1"
    Me.TrackBar1.Size = New System.Drawing.Size(310, 45)
    Me.TrackBar1.TabIndex = 201
    '
    'Button6
    '
    Me.Button6.Location = New System.Drawing.Point(19, 74)
    Me.Button6.Name = "Button6"
    Me.Button6.Size = New System.Drawing.Size(60, 41)
    Me.Button6.TabIndex = 202
    Me.Button6.Text = "Image Copy"
    Me.Button6.UseVisualStyleBackColor = True
    '
    'Button7
    '
    Me.Button7.Location = New System.Drawing.Point(19, 121)
    Me.Button7.Name = "Button7"
    Me.Button7.Size = New System.Drawing.Size(60, 41)
    Me.Button7.TabIndex = 203
    Me.Button7.Text = "Image Paste"
    Me.Button7.UseVisualStyleBackColor = True
    '
    'TrackBar2
    '
    Me.TrackBar2.Location = New System.Drawing.Point(151, 45)
    Me.TrackBar2.Minimum = 1
    Me.TrackBar2.Name = "TrackBar2"
    Me.TrackBar2.Orientation = System.Windows.Forms.Orientation.Vertical
    Me.TrackBar2.Size = New System.Drawing.Size(45, 104)
    Me.TrackBar2.TabIndex = 204
    Me.TrackBar2.Value = 10
    '
    'frmSprite
    '
    Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
    Me.ClientSize = New System.Drawing.Size(824, 715)
    Me.Controls.Add(Me.TrackBar2)
    Me.Controls.Add(Me.Button7)
    Me.Controls.Add(Me.Button6)
    Me.Controls.Add(Me.TrackBar1)
    Me.Controls.Add(Me.Button4)
    Me.Controls.Add(Me.Button3)
    Me.Controls.Add(Me.Panel1)
    Me.Controls.Add(Me.Button2)
    Me.Controls.Add(Me.Button1)
    Me.Controls.Add(Me.RadioButton3)
    Me.Controls.Add(Me.RadioButton2)
    Me.Controls.Add(Me.RadioButton1)
    Me.Controls.Add(Me.Button5)
    Me.Controls.Add(Me.NumericUpDown4)
    Me.Controls.Add(Me.Label5)
    Me.Controls.Add(Me.Label4)
    Me.Controls.Add(Me.NumericUpDown3)
    Me.Controls.Add(Me.ListBox2)
    Me.Menu = Me.MainMenu1
    Me.Name = "frmSprite"
    Me.Text = "frmSprite"
    CType(Me.NumericUpDown4, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).EndInit()
    Me.Panel1.ResumeLayout(False)
    CType(Me.PictureBox3, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.TrackBar1, System.ComponentModel.ISupportInitialize).EndInit()
    CType(Me.TrackBar2, System.ComponentModel.ISupportInitialize).EndInit()
    Me.ResumeLayout(False)
    Me.PerformLayout()

  End Sub

#End Region

  Sub ResizePictureBox3()
    Dim n As Integer
    n = ListBox2.SelectedIndex
    If n >= 0 Then
      PictureBox3.Size = New Size(sprites(n).horizDots * sprites(n).nImages * sprScale, sprites(n).scanlines * sprScale)
      TrackBar1.Maximum = sprites(n).nImages - 1
    End If
  End Sub

  Private Sub Button5_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button5.Click
    Dim dlgcolor As New ColorDialog
    dlgcolor.ShowDialog(Form1.ActiveForm)
    spriteColor = dlgcolor.Color
  End Sub

  Private Sub NumericUpDown3_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown3.ValueChanged
    Dim n As Integer
    Dim newGwidth As Integer

    newGwidth = NumericUpDown3.Value
    If (newGwidth * gheight <= MaxPixels()) Then
      gwidth = newGwidth
    Else
      gwidth = MaxPixels() / gheight
      While gwidth * gheight > MaxPixels()
        gwidth = gwidth - 1
      End While
      NumericUpDown3.Value = gwidth
    End If
    For n = 0 To 31
      If Not sprites(n) Is Nothing Then
        sprites(n).horizDots = gwidth
      End If
    Next
    ResizePictureBox3()
    PictureBox3.Invalidate()
  End Sub

  Private Sub NumericUpDown4_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown4.ValueChanged
    Dim n As Integer
    Dim newGheight As Integer

    newGheight = NumericUpDown4.Value
    If (gwidth * newGheight <= MaxPixels()) Then
      gheight = newGheight
    Else
      gheight = MaxPixels() / gwidth
      While gwidth * gheight > MaxPixels()
        gheight = gheight - 1
      End While
      NumericUpDown4.Value = gheight
    End If
    For n = 0 To 31
      If Not sprites(n) Is Nothing Then
        sprites(n).scanlines = gheight
      End If
    Next
    ResizePictureBox3()
    PictureBox3.Invalidate()
  End Sub

  Private Sub PictureBox3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PictureBox3.Click

  End Sub

  Private Sub PictureBox3_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles PictureBox3.Paint
    Dim n As Integer
    n = ListBox2.SelectedIndex()
    If n >= 0 Then
      sprites(n).Draw(e, sprIndex)
    End If
  End Sub

  Private Sub PictureBox3_MouseDown(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles PictureBox3.MouseDown
    Dim wx As Integer
    Dim wy As Integer
    Dim n As Integer
    Dim ix As Integer
    Dim iy As Integer
    Dim nx As Double
    Dim ny As Double
    Dim wxm As Integer
    Dim wym As Integer

    mouseDwn = True
    If e.Button = MouseButtons.Right Then
      Return
    End If
    'nx = (PictureBox3.Size.Width / sprScale - sprites(n).horizDots / 2) / sprites(n).horizDots
    'ny = sprites(n).nImages / nx
    nx = sprites(n).nImages
    ny = 0
    wx = (e.X - sprScale / 2) / sprScale - sprIndex * sprites(n).horizDots
    wy = (e.Y - sprScale / 2) / sprScale
    wxm = wx Mod sprites(n).horizDots
    wym = wy Mod sprites(n).scanlines
    ix = (wx - sprites(n).horizDots / 2 + 1) / sprites(n).horizDots
    'iy = (wy - sprites(n).scanlines / 2 + 1) / sprites(n).scanlines
    iy = 0
    If ix < 0 Then ix = 0
    If iy < 0 Then iy = 0
    n = ListBox2.SelectedIndex()
    If n < 0 Then n = 0
    If (wxm < 0 Or ix > nx) Or (wym < 0 Or iy > ny Or iy * nx + ix > sprites(n).nImages()) Then
    Else
      If n >= 0 Then
        sprites(n).setcolor(wxm, wym, iy * nx + ix)
        PictureBox3.Invalidate()
      End If
    End If
  End Sub

  Private Sub frmSprite_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Load
    Dim j As Integer
    For j = 0 To 31
      ListBox2.Items.Add(CStr(j))
    Next
    ResizePictureBox3()
  End Sub

  Private Sub ListBox2_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ListBox2.SelectedIndexChanged
    PictureBox3.Invalidate()
  End Sub

  Private Sub MenuItem3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem3.Click
    Dim dlg As New OpenFileDialog
    Dim j As Integer
    Dim r As System.Windows.Forms.DialogResult
    Dim nm As String
    dlg.Title = "Open "
    dlg.Filter = "Bitmap (*.bmp)|*.bmp|Mem (*.mem)|*.mem|Coe (*.coe)|*.coe|C Files(*.c)|*.c|Binary Files(*.bin)|*.bin"
    dlg.FilterIndex = 2
    r = dlg.ShowDialog()
    If r = DialogResult.OK Then
      baseSpriteFileName = dlg.FileName
      For j = 0 To 31
        If baseSpriteFileName.EndsWith(".bmp") Then
          nm = baseSpriteFileName.Replace(".bmp", j & ".bmp")
          'nm = baseSpriteFileName
          sprites(j).SerializeFromBmp(nm)
        End If
        If baseSpriteFileName.EndsWith(".mem") Then
          nm = baseSpriteFileName.Replace(".mem", j & ".mem")
          'nm = baseSpriteFileName
          sprites(j).SerializeFromMem(nm)
        End If
        If baseSpriteFileName.EndsWith(".coe") Then
          nm = baseSpriteFileName.Replace(".coe", j & ".coe")
          'nm = baseSpriteFileName
          SerializeFromCoe(nm, j)
        End If
        If baseSpriteFileName.EndsWith(".bin") Then
          sprites(j).SerializeFromBin(j)
          'ElseIf baseSpriteFileName.EndsWith(".c") Then
          ' sprites(j).SerializeFromC(j)
        End If
      Next
      Refresh()
    End If
  End Sub

  Private Sub MenuItem2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem2.Click
    Dim j As Integer

    For j = 0 To 31
      sprites(j).SerializeToBin(j)
    Next
  End Sub

  Private Sub RadioButton1_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton1.CheckedChanged

  End Sub

  Public Function BPP() As Integer
    If RadioButton1.Checked Then
      Return 16
    ElseIf RadioButton3.Checked Then
      Return 32
    End If
    Return 8
  End Function

  Function MaxPixels() As Integer
    If BPP() = 8 Then
      Return 4096
    ElseIf BPP() = 16 Then
      Return 2048
    End If
    Return 1024
  End Function

  Private Sub frmSprite_MouseMove(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles MyBase.MouseMove
    'Dim wx As Integer
    'Dim wy As Integer
    'Dim n As Integer
    'Dim ix As Integer
    'Dim iy As Integer
    'Dim nx As Integer
    'Dim ny As Integer

    'nx = PictureBox3.Size.Width / sprites(n).horizDots
    'ny = PictureBox3.Size.Height / sprites(n).scanlines
    'wx = (e.X - 5) / 10
    'wy = (e.Y - 5) / 10
    'ix = wx / sprites(n).horizDots
    'iy = wy / sprites(n).scanlines
    'n = ListBox2.SelectedIndex()
    'If (wx < 0 Or ix > nx) Or (wy < 0 Or iy > ny) Then
    'Else
    '    If n >= 0 Then
    '        sprites(n).setcolor(wx, wy, iy * nx + ix)
    '        PictureBox3.Invalidate()
    '    End If
    'End If
  End Sub

  Private Sub frmSprite_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles MyBase.MouseUp
  End Sub

  Private Sub MenuItem4_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem4.Click
    Dim dlg As New SaveFileDialog
    Dim j As Integer
    Dim r As System.Windows.Forms.DialogResult
    Dim nm As String
    dlg.Title = "Save as"
    dlg.Filter = "Bitmap (*.bmp)|*.bmp|MEM (*.mem)|*.mem|Coe (*.coe)|*.coe|C Files(*.c)|*.c|Binary Files(*.bin)|*.bin"
    r = dlg.ShowDialog()
    If r = DialogResult.OK Then
      baseSpriteFileName = dlg.FileName
      For j = 0 To 31
        If baseSpriteFileName.EndsWith(".bmp") Then
          nm = baseSpriteFileName.Replace(".bmp", j & ".bmp")
          If Not bmpSprites(j) Is Nothing Then
            If j = 0 Then
              sprites(j).SerializeToBmp(baseSpriteFileName)
            End If
            sprites(j).SerializeToBmp(nm)
          End If
        End If
        If baseSpriteFileName.EndsWith(".mem") Then
          nm = baseSpriteFileName.Replace(".mem", j & ".mem")
          If Not bmpSprites(j) Is Nothing Then
            If j = 0 Then
              sprites(j).SerializeToMem(baseSpriteFileName)
            End If
            sprites(j).SerializeToMem(nm)
          End If
        End If
        If baseSpriteFileName.EndsWith(".coe") Then
          nm = baseSpriteFileName.Replace(".coe", j & ".coe")
          If Not bmpSprites(j) Is Nothing Then
            If j = 0 Then
              SerializeToCoe(baseSpriteFileName, j)
            End If
            SerializeToCoe(nm, j)
          End If
        End If
        If baseSpriteFileName.EndsWith(".bin") Then
          sprites(j).SerializeToBin(j)
        ElseIf baseSpriteFileName.EndsWith(".c") Then
          sprites(j).SerializeToC(j)
        End If
      Next
    End If
  End Sub

  Private Sub ContextMenu1_Popup(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ContextMenu1.Popup
  End Sub

  Private Sub PictureBox3_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles PictureBox3.MouseUp
    Dim mnu As New ContextMenu

    If e.Button = MouseButtons.Right Then
      pt.X = e.X
      pt.Y = e.Y
      Dim item1 = mnu.MenuItems.Add("Floodfill", FloodFillClick)
      mnu.Show(PictureBox3, pt)
      mouseDwn = False
    End If
  End Sub

  Private Function FloodFillClick() As System.EventHandler
    Dim wx As Integer
    Dim wy As Integer
    Dim n As Integer
    Dim ix As Integer
    Dim iy As Integer
    Dim nx As Double
    Dim ny As Double
    Dim wxm As Integer
    Dim wym As Integer
    Dim color As System.Drawing.Color

    nx = (PictureBox3.Size.Width / 10 - sprites(n).horizDots / 2) / sprites(n).horizDots
    ny = sprites(n).nImages / nx
    wx = (pt.X - 5) / 10
    wy = (pt.Y - 5) / 10
    wxm = wx Mod sprites(n).horizDots
    wym = wy Mod sprites(n).scanlines
    ix = (wx - sprites(n).horizDots / 2 + 1) / sprites(n).horizDots
    iy = (wy - sprites(n).scanlines / 2 + 1) / sprites(n).scanlines
    If ix < 0 Then ix = 0
    If iy < 0 Then iy = 0
    n = ListBox2.SelectedIndex()
    If (wxm < 0 Or ix > nx) Or (wym < 0 Or iy > ny Or iy * nx + ix > sprites(n).nImages()) Then
    Else
      If n >= 0 Then
        fillOverColor = sprites(n).getColor(wxm, wym, iy * nx + ix)
      End If
    End If
    FloodFill(wxm, wym, iy * nx + ix, n)
  End Function

  Private Sub FloodFill(ByVal x As Integer, ByVal y As Integer, ByVal i As Integer, ByVal n As Integer)
    Static count As Integer = 0

    count = count + 1
    If x < 0 Then Return
    If x >= sprites(n).horizDots Then Return
    If y < 0 Then Return
    If y >= sprites(n).scanlines Then Return
    If Not sprites(n).getColor(x, y, i).Equals(fillOverColor) Then Return
    sprites(n).setcolor(x, y, i)
    FloodFill(x - 1, y, i, n)
    FloodFill(x + 1, y, i, n)
    FloodFill(x, y - 1, i, n)
    FloodFill(x, y + 1, i, n)
  End Sub

  Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
    Dim n As Integer
    n = ListBox2.SelectedIndex
    Clipboard.SetText(sprites(n).ToString(-1))
  End Sub

  Private Sub Button2_Click(sender As Object, e As EventArgs) Handles Button2.Click
    Dim n As Integer
    n = ListBox2.SelectedIndex
    sprites(n).FromString(Clipboard.GetText(), -1)
  End Sub

  Private Sub Button3_Click(sender As Object, e As EventArgs) Handles Button3.Click
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim tmp As System.Drawing.Color

    n = ListBox2.SelectedIndex
    For j = 0 To sprites(n).scanlines - 1
      tmp = sprites(n).getColor(sprites(n).horizDots - 1, j, 0)
      For k = sprites(n).horizDots - 1 To 1 Step -1
        spriteColor = sprites(n).getColor(k - 1, j, 0)
        sprites(n).setcolor(k, j, 0)
      Next
      spriteColor = tmp
      sprites(n).setcolor(0, j, 0)
    Next
    Refresh()
  End Sub
  Sub SerializeToCoe(ByVal nm As String, ByVal gcnt As Integer)
    Dim n As Integer
    Dim nn As Integer
    Dim c As System.Drawing.Color
    Dim j As Integer
    Dim s As String
    Dim s1 As String
    Dim wcnt As Integer
    Dim bcnt As Integer
    Dim ofl As System.IO.File
    Dim ofs As System.IO.TextWriter

    wcnt = 1
    s1 = ""
    s = "memory_initialization_radix=16;" & vbLf
    s = s & "memory_initialization_vector=" & vbLf
    bcnt = 0
    While bcnt < sprites(gcnt).ImageSize()
      Select Case BPP()
        Case 8
          wcnt = 8
        Case 16
          wcnt = 4
        Case 32
          wcnt = 2
      End Select
      For nn = 0 To wcnt - 1
        c = sprites(gcnt).bitmap(bcnt)
        Select Case BPP()
          Case 8
            n = (((c.R >> 5) And 7) << 5) Or (((c.G >> 5) And 7) << 2) Or (((c.B >> 6) And 3))
            s1 = Hex(n).PadLeft(2, "0")
            wcnt = 8
          Case 16
            n = (((c.R >> 3) And 31) << 10) Or (((c.G >> 3) And 31) << 5) Or (((c.B >> 3) And 31))
            s1 = Hex(n).PadLeft(4, "0")
            wcnt = 4
          Case 32
            n = (c.R << 16) Or (c.G << 8) Or c.B
            s1 = Hex(n).PadLeft(8, "0")
            wcnt = 2
        End Select
        s = s & s1
        If nn = wcnt - 1 Then
          If (bcnt = sprites(gcnt).ImageSize - 1) Then
            s = s & ";"
          Else
            s = s & ","
          End If
          s = s & vbLf
        End If
        bcnt += 1
      Next
    End While
    ofs = ofl.CreateText(nm)
    ofs.Write(s)
    ofs.Close()
  End Sub
  Sub SerializeFromCoe(ByVal nm As String, ByVal gcnt As Integer)
    Dim n As Integer
    Dim nn As Integer
    Dim c As Integer
    Dim j As Integer
    Dim wcnt As Integer
    Dim vcnt As Integer
    Dim readingVector As Boolean
    Dim radix As Integer
    Dim txt As String
    Dim lines() As String
    Dim line As String
    Dim s As String
    Dim s1 As String
    Dim strs() As String
    Dim bcnt As Integer
    Dim ifs As TextReader
    Dim ifl As File

    bcnt = 0
    wcnt = 0
    ifs = ifl.OpenText(nm)
    txt = ifs.ReadToEnd()
    ifs.Close()
    lines = txt.Split(vbLf)
    readingVector = False
    radix = 16
    For Each line In lines
      s = line.Trim.Substring(0, 1)
      If (s <> ";") Then
        strs = line.Split("=")
        If (strs(0).Trim.ToLower = "memory_initialization_radix") Then
          radix = CInt(strs(1).Trim(";"))
        ElseIf (strs(0).Trim.ToLower = "memory_initialization_vector") Then
          readingVector = True
        ElseIf readingVector Then
          s = line.Trim
          s = s.Substring(0, s.Length - 1)
          Select Case BPP()
            Case 8
              wcnt = 8
              vcnt = 2
            Case 16
              wcnt = 4
              vcnt = 4
            Case 32
              wcnt = 2
              vcnt = 8
          End Select
          For nn = 0 To wcnt - 1
            n = 0
            s1 = s.Substring(vcnt * nn, vcnt)
            Select Case radix
              Case 2, 3, 4, 5, 6, 7, 8, 9
                For j = 0 To s.Length - 1
                  n = n * radix + CInt(s.Substring(j, 1))
                Next
              Case 10
                n = CInt(s)
              Case 16
                n = CInt("&h" & s)
            End Select
            Select Case BPP()
              Case 8
                c = ((n And 3) << 6) Or (((n >> 2) And 7) << 13) Or (((n >> 5) And 7) << 21)
              Case 16
                c = ((n And 31) << 3) Or (((n >> 5) And 31) << 11) Or (((n >> 10) And 31) << 19)
              Case 32
                c = n
            End Select
            sprites(gcnt).bitmap(bcnt) = System.Drawing.Color.FromArgb(c)
            bcnt = bcnt + 1
            If bcnt = sprites(gcnt).ImageSize Then
              Return
            End If
          Next
        End If
      End If
    Next
  End Sub

  Private Sub Button4_Click(sender As Object, e As EventArgs) Handles Button4.Click
    Dim j As Integer
    Dim k As Integer
    Dim n As Integer
    Dim tmp As System.Drawing.Color

    n = ListBox2.SelectedIndex
    For j = 0 To sprites(n).scanlines - 1
      tmp = sprites(n).getColor(0, j, 0)
      For k = 0 To sprites(n).horizDots - 2
        spriteColor = sprites(n).getColor(k + 1, j, 0)
        sprites(n).setcolor(k, j, 0)
      Next
      spriteColor = tmp
      sprites(n).setcolor(sprites(n).horizDots - 1, j, 0)
    Next
    Refresh()
  End Sub

  Private Sub Button6_Click(sender As Object, e As EventArgs) Handles Button6.Click

  End Sub

  Private Sub TrackBar1_ValueChanged(sender As Object, e As EventArgs) Handles TrackBar1.ValueChanged
    sprIndex = TrackBar1.Value
    Refresh()
  End Sub

  Private Sub Button6_Click_1(sender As Object, e As EventArgs) Handles Button6.Click
    Dim n As Integer
    n = ListBox2.SelectedIndex
    Clipboard.SetText(sprites(n).ToString(sprIndex))
  End Sub

  Private Sub Button7_Click(sender As Object, e As EventArgs) Handles Button7.Click
    Dim n As Integer
    n = ListBox2.SelectedIndex
    sprites(n).FromString(Clipboard.GetText(), sprIndex)
  End Sub

  Private Sub TrackBar2_Scroll(sender As Object, e As EventArgs) Handles TrackBar2.Scroll
    sprScale = TrackBar2.Value
    Refresh()
  End Sub
End Class
