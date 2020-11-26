Public Class frmSprite
    Inherits System.Windows.Forms.Form

    Dim gwidth As Integer
    Dim gheight As Integer
    Dim mouseDwn As Boolean
    Dim pt As System.Drawing.Point
    Dim fillOverColor As System.Drawing.Color

#Region " Windows Form Designer generated code "

    Public Sub New()
        MyBase.New()
        Dim n As Integer

        'This call is required by the Windows Form Designer.
        InitializeComponent()

        'Add any initialization after the InitializeComponent() call
        For n = 0 To 16
            sprites(n) = New Sprite
            sprites(n).index = n
            sprites(n).scanlines = 24
            sprites(n).horizDots = 21
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
    Friend WithEvents PictureBox3 As System.Windows.Forms.PictureBox
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
        Me.ListBox2 = New System.Windows.Forms.ListBox
        Me.PictureBox3 = New System.Windows.Forms.PictureBox
        Me.ContextMenu1 = New System.Windows.Forms.ContextMenu
        Me.Button5 = New System.Windows.Forms.Button
        Me.NumericUpDown4 = New System.Windows.Forms.NumericUpDown
        Me.Label5 = New System.Windows.Forms.Label
        Me.Label4 = New System.Windows.Forms.Label
        Me.NumericUpDown3 = New System.Windows.Forms.NumericUpDown
        Me.MainMenu1 = New System.Windows.Forms.MainMenu
        Me.MenuItem1 = New System.Windows.Forms.MenuItem
        Me.MenuItem3 = New System.Windows.Forms.MenuItem
        Me.MenuItem2 = New System.Windows.Forms.MenuItem
        Me.MenuItem4 = New System.Windows.Forms.MenuItem
        Me.RadioButton1 = New System.Windows.Forms.RadioButton
        Me.RadioButton2 = New System.Windows.Forms.RadioButton
        Me.ContextMenu2 = New System.Windows.Forms.ContextMenu
        CType(Me.NumericUpDown4, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        '
        'ListBox2
        '
        Me.ListBox2.Location = New System.Drawing.Point(104, 16)
        Me.ListBox2.Name = "ListBox2"
        Me.ListBox2.Size = New System.Drawing.Size(32, 225)
        Me.ListBox2.TabIndex = 184
        '
        'PictureBox3
        '
        Me.PictureBox3.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
        Me.PictureBox3.ContextMenu = Me.ContextMenu1
        Me.PictureBox3.Location = New System.Drawing.Point(144, 16)
        Me.PictureBox3.Name = "PictureBox3"
        Me.PictureBox3.Size = New System.Drawing.Size(650, 650)
        Me.PictureBox3.TabIndex = 185
        Me.PictureBox3.TabStop = False
        '
        'ContextMenu1
        '
        '
        'Button5
        '
        Me.Button5.Location = New System.Drawing.Point(48, 312)
        Me.Button5.Name = "Button5"
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
        Me.NumericUpDown4.Value = New Decimal(New Integer() {21, 0, 0, 0})
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
        Me.NumericUpDown3.Value = New Decimal(New Integer() {24, 0, 0, 0})
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
        Me.RadioButton1.Location = New System.Drawing.Point(16, 360)
        Me.RadioButton1.Name = "RadioButton1"
        Me.RadioButton1.TabIndex = 191
        Me.RadioButton1.TabStop = True
        Me.RadioButton1.Text = "16 bpp"
        '
        'RadioButton2
        '
        Me.RadioButton2.Location = New System.Drawing.Point(16, 384)
        Me.RadioButton2.Name = "RadioButton2"
        Me.RadioButton2.TabIndex = 192
        Me.RadioButton2.Text = "8 bpp"
        '
        'frmSprite
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(824, 673)
        Me.Controls.Add(Me.RadioButton2)
        Me.Controls.Add(Me.RadioButton1)
        Me.Controls.Add(Me.Button5)
        Me.Controls.Add(Me.NumericUpDown4)
        Me.Controls.Add(Me.Label5)
        Me.Controls.Add(Me.Label4)
        Me.Controls.Add(Me.NumericUpDown3)
        Me.Controls.Add(Me.PictureBox3)
        Me.Controls.Add(Me.ListBox2)
        Me.Menu = Me.MainMenu1
        Me.Name = "frmSprite"
        Me.Text = "frmSprite"
        CType(Me.NumericUpDown4, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)

    End Sub

#End Region

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
        For n = 0 To 15
            If Not sprites(n) Is Nothing Then
                sprites(n).horizDots = gwidth
            End If
        Next
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
        For n = 0 To 15
            If Not sprites(n) Is Nothing Then
                sprites(n).scanlines = gheight
            End If
        Next
        PictureBox3.Invalidate()
    End Sub

    Private Sub PictureBox3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PictureBox3.Click

    End Sub

    Private Sub PictureBox3_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles PictureBox3.Paint
        Dim n As Integer
        n = ListBox2.SelectedIndex()
        If n >= 0 Then
            sprites(n).Draw(e)
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
        nx = (PictureBox3.Size.Width / 10 - sprites(n).horizDots / 2) / sprites(n).horizDots
        ny = sprites(n).nImages / nx
        wx = (e.X - 5) / 10
        wy = (e.Y - 5) / 10
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
                sprites(n).setcolor(wxm, wym, iy * nx + ix)
                PictureBox3.Invalidate()
            End If
        End If
    End Sub

    Private Sub frmSprite_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Dim j As Integer
        For j = 0 To 15
            ListBox2.Items.Add(CStr(j))
        Next
    End Sub

    Private Sub ListBox2_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ListBox2.SelectedIndexChanged
        PictureBox3.Invalidate()
    End Sub

    Private Sub MenuItem3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem3.Click
        Dim j As Integer

        For j = 0 To 15
            sprites(j).SerializeFromBin(j)
        Next
    End Sub

    Private Sub MenuItem2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem2.Click
        Dim j As Integer

        For j = 0 To 15
            sprites(j).SerializeToBin(j)
        Next
    End Sub

    Private Sub RadioButton1_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RadioButton1.CheckedChanged

    End Sub

    Public Function BPP() As Integer
        If RadioButton1.Checked Then
            Return 16
        End If
        Return 8
    End Function

    Function MaxPixels() As Integer
        If BPP() = 8 Then
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
        dlg.Title = "Save as"
        dlg.Filter = "C Files(*.c)|*.c|Binary Files(*.bin)|*.bin"
        r = dlg.ShowDialog()
        If r = DialogResult.OK Then
            baseSpriteFileName = dlg.FileName
            For j = 0 To 15
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

End Class
