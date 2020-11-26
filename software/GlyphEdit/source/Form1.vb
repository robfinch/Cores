Imports System.IO

Public Class Form1
    Inherits System.Windows.Forms.Form
    Dim gwidth As Integer
    Dim gheight As Integer
    Dim workingGlyph(32, 32) As Boolean
	Friend WithEvents CheckBox1 As CheckBox
	Dim workingSprite(2048) As Int16
#Region " Windows Form Designer generated code "

	Public Sub New()
        MyBase.New()

        'This call is required by the Windows Form Designer.
        InitializeComponent()

        'Add any initialization after the InitializeComponent() call
        Dim n As Integer
        For n = 0 To 511
            glyphs(n) = New Glyph
            glyphs(n).index = n
            glyphs(n).scanlines = 8
            glyphs(n).horizDots = 8
        Next
        For n = 0 To 16
            sprites(n) = New Sprite
            sprites(n).index = n
            sprites(n).scanlines = 48
            sprites(n).horizDots = 42
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
    Friend WithEvents OpenFileDialog1 As System.Windows.Forms.OpenFileDialog
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents txtInstName As System.Windows.Forms.TextBox
    Friend WithEvents Button3 As System.Windows.Forms.Button
    Friend WithEvents ListBox1 As System.Windows.Forms.ListBox
    Friend WithEvents PictureBox1 As System.Windows.Forms.PictureBox
    Friend WithEvents MainMenu1 As System.Windows.Forms.MainMenu
    Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuItem2 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuItem3 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuItem4 As System.Windows.Forms.MenuItem
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents lblHeight As System.Windows.Forms.Label
    Friend WithEvents ToolTip1 As System.Windows.Forms.ToolTip
    Friend WithEvents ToolTip2 As System.Windows.Forms.ToolTip
    Friend WithEvents NumericUpDown1 As System.Windows.Forms.NumericUpDown
    Friend WithEvents NumericUpDown2 As System.Windows.Forms.NumericUpDown
    Friend WithEvents PictureBox2 As System.Windows.Forms.PictureBox
    Friend WithEvents MenuItem5 As System.Windows.Forms.MenuItem
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents MenuItem6 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuItem7 As System.Windows.Forms.MenuItem
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
		Me.components = New System.ComponentModel.Container()
		Me.OpenFileDialog1 = New System.Windows.Forms.OpenFileDialog()
		Me.Label1 = New System.Windows.Forms.Label()
		Me.txtInstName = New System.Windows.Forms.TextBox()
		Me.Button3 = New System.Windows.Forms.Button()
		Me.ListBox1 = New System.Windows.Forms.ListBox()
		Me.PictureBox1 = New System.Windows.Forms.PictureBox()
		Me.MainMenu1 = New System.Windows.Forms.MainMenu(Me.components)
		Me.MenuItem1 = New System.Windows.Forms.MenuItem()
		Me.MenuItem2 = New System.Windows.Forms.MenuItem()
		Me.MenuItem3 = New System.Windows.Forms.MenuItem()
		Me.MenuItem5 = New System.Windows.Forms.MenuItem()
		Me.MenuItem6 = New System.Windows.Forms.MenuItem()
		Me.MenuItem7 = New System.Windows.Forms.MenuItem()
		Me.MenuItem4 = New System.Windows.Forms.MenuItem()
		Me.Label2 = New System.Windows.Forms.Label()
		Me.lblHeight = New System.Windows.Forms.Label()
		Me.ToolTip1 = New System.Windows.Forms.ToolTip(Me.components)
		Me.ToolTip2 = New System.Windows.Forms.ToolTip(Me.components)
		Me.NumericUpDown1 = New System.Windows.Forms.NumericUpDown()
		Me.NumericUpDown2 = New System.Windows.Forms.NumericUpDown()
		Me.PictureBox2 = New System.Windows.Forms.PictureBox()
		Me.Label3 = New System.Windows.Forms.Label()
		Me.CheckBox1 = New System.Windows.Forms.CheckBox()
		CType(Me.PictureBox1, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.NumericUpDown2, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.PictureBox2, System.ComponentModel.ISupportInitialize).BeginInit()
		Me.SuspendLayout()
		'
		'Label1
		'
		Me.Label1.Location = New System.Drawing.Point(33, 21)
		Me.Label1.Name = "Label1"
		Me.Label1.Size = New System.Drawing.Size(127, 20)
		Me.Label1.TabIndex = 165
		Me.Label1.Text = "ROM instance name"
		'
		'txtInstName
		'
		Me.txtInstName.Location = New System.Drawing.Point(33, 42)
		Me.txtInstName.Name = "txtInstName"
		Me.txtInstName.Size = New System.Drawing.Size(180, 20)
		Me.txtInstName.TabIndex = 166
		Me.txtInstName.Text = "charrom"
		'
		'Button3
		'
		Me.Button3.Location = New System.Drawing.Point(33, 83)
		Me.Button3.Name = "Button3"
		Me.Button3.Size = New System.Drawing.Size(127, 49)
		Me.Button3.TabIndex = 167
		Me.Button3.Text = "Flip bits horizontally"
		Me.ToolTip1.SetToolTip(Me.Button3, "Switch bits from left to right in the entire character set.")
		'
		'ListBox1
		'
		Me.ListBox1.Location = New System.Drawing.Point(240, 21)
		Me.ListBox1.Name = "ListBox1"
		Me.ListBox1.Size = New System.Drawing.Size(74, 251)
		Me.ListBox1.TabIndex = 168
		'
		'PictureBox1
		'
		Me.PictureBox1.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
		Me.PictureBox1.Location = New System.Drawing.Point(319, 21)
		Me.PictureBox1.Name = "PictureBox1"
		Me.PictureBox1.Size = New System.Drawing.Size(273, 277)
		Me.PictureBox1.TabIndex = 169
		Me.PictureBox1.TabStop = False
		'
		'MainMenu1
		'
		Me.MainMenu1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem1, Me.MenuItem6, Me.MenuItem4})
		'
		'MenuItem1
		'
		Me.MenuItem1.Index = 0
		Me.MenuItem1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem2, Me.MenuItem3, Me.MenuItem5})
		Me.MenuItem1.Text = "&File"
		'
		'MenuItem2
		'
		Me.MenuItem2.Index = 0
		Me.MenuItem2.Text = "&Open"
		'
		'MenuItem3
		'
		Me.MenuItem3.Index = 1
		Me.MenuItem3.Text = "&Save"
		'
		'MenuItem5
		'
		Me.MenuItem5.Index = 2
		Me.MenuItem5.Text = "E&xit"
		'
		'MenuItem6
		'
		Me.MenuItem6.Index = 1
		Me.MenuItem6.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem7})
		Me.MenuItem6.Text = "&Sprite"
		'
		'MenuItem7
		'
		Me.MenuItem7.Index = 0
		Me.MenuItem7.Text = "&Edit"
		'
		'MenuItem4
		'
		Me.MenuItem4.Index = 2
		Me.MenuItem4.Text = "&About"
		'
		'Label2
		'
		Me.Label2.Location = New System.Drawing.Point(33, 153)
		Me.Label2.Name = "Label2"
		Me.Label2.Size = New System.Drawing.Size(54, 19)
		Me.Label2.TabIndex = 171
		Me.Label2.Text = "Width"
		'
		'lblHeight
		'
		Me.lblHeight.Location = New System.Drawing.Point(33, 180)
		Me.lblHeight.Name = "lblHeight"
		Me.lblHeight.Size = New System.Drawing.Size(60, 20)
		Me.lblHeight.TabIndex = 173
		Me.lblHeight.Text = "Height"
		'
		'NumericUpDown1
		'
		Me.NumericUpDown1.Location = New System.Drawing.Point(107, 180)
		Me.NumericUpDown1.Maximum = New Decimal(New Integer() {32, 0, 0, 0})
		Me.NumericUpDown1.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
		Me.NumericUpDown1.Name = "NumericUpDown1"
		Me.NumericUpDown1.Size = New System.Drawing.Size(53, 20)
		Me.NumericUpDown1.TabIndex = 174
		Me.NumericUpDown1.TextAlign = System.Windows.Forms.HorizontalAlignment.Center
		Me.NumericUpDown1.Value = New Decimal(New Integer() {8, 0, 0, 0})
		'
		'NumericUpDown2
		'
		Me.NumericUpDown2.Location = New System.Drawing.Point(107, 153)
		Me.NumericUpDown2.Maximum = New Decimal(New Integer() {18, 0, 0, 0})
		Me.NumericUpDown2.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
		Me.NumericUpDown2.Name = "NumericUpDown2"
		Me.NumericUpDown2.Size = New System.Drawing.Size(53, 20)
		Me.NumericUpDown2.TabIndex = 175
		Me.NumericUpDown2.TextAlign = System.Windows.Forms.HorizontalAlignment.Center
		Me.NumericUpDown2.Value = New Decimal(New Integer() {8, 0, 0, 0})
		'
		'PictureBox2
		'
		Me.PictureBox2.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
		Me.PictureBox2.Location = New System.Drawing.Point(20, 312)
		Me.PictureBox2.Name = "PictureBox2"
		Me.PictureBox2.Size = New System.Drawing.Size(873, 451)
		Me.PictureBox2.TabIndex = 176
		Me.PictureBox2.TabStop = False
		'
		'Label3
		'
		Me.Label3.Location = New System.Drawing.Point(33, 208)
		Me.Label3.Name = "Label3"
		Me.Label3.Size = New System.Drawing.Size(174, 49)
		Me.Label3.TabIndex = 177
		Me.Label3.Text = "Width and height must be set appropriately before the file is loaded."
		'
		'CheckBox1
		'
		Me.CheckBox1.AutoSize = True
		Me.CheckBox1.Checked = True
		Me.CheckBox1.CheckState = System.Windows.Forms.CheckState.Checked
		Me.CheckBox1.Location = New System.Drawing.Point(33, 255)
		Me.CheckBox1.Name = "CheckBox1"
		Me.CheckBox1.Size = New System.Drawing.Size(72, 17)
		Me.CheckBox1.TabIndex = 178
		Me.CheckBox1.Text = "64-bit ram"
		Me.CheckBox1.UseVisualStyleBackColor = True
		'
		'Form1
		'
		Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
		Me.ClientSize = New System.Drawing.Size(992, 770)
		Me.Controls.Add(Me.CheckBox1)
		Me.Controls.Add(Me.Label3)
		Me.Controls.Add(Me.PictureBox2)
		Me.Controls.Add(Me.NumericUpDown2)
		Me.Controls.Add(Me.NumericUpDown1)
		Me.Controls.Add(Me.lblHeight)
		Me.Controls.Add(Me.Label2)
		Me.Controls.Add(Me.PictureBox1)
		Me.Controls.Add(Me.ListBox1)
		Me.Controls.Add(Me.Button3)
		Me.Controls.Add(Me.txtInstName)
		Me.Controls.Add(Me.Label1)
		Me.Menu = Me.MainMenu1
		Me.Name = "Form1"
		Me.Text = "8x8 Glyph Editor"
		Me.ToolTip1.SetToolTip(Me, "Number of scanlines for each glyph")
		CType(Me.PictureBox1, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.NumericUpDown2, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.PictureBox2, System.ComponentModel.ISupportInitialize).EndInit()
		Me.ResumeLayout(False)
		Me.PerformLayout()

	End Sub

#End Region


	Private Sub Button1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        Dim n As Integer
        Dim ofl As File
        Dim strm As Stream
        Dim ofs As TextWriter
        Dim path As String
        Dim fd As SaveFileDialog
        Dim s As String
        Dim gcnt As Integer
        Dim row As Integer
        Dim inst As Integer

        fd = New SaveFileDialog
		fd.Filter = "Verilog files (*.v)|*.v|UCF files (*.ucf)|*.ucf|COE files (*.coe)|*.coe|All files (*.*)|*.*"
		fd.FilterIndex = 1
		If fd.ShowDialog() = DialogResult.OK Then
			ofs = ofl.CreateText(fd.FileName)
			If fd.FileName.EndsWith(".coe") Then
				s = "memory_initialization_radix=10;" & vbLf
				ofs.Write(s)
				s = "memory_initialization_vector=" & vbLf
				ofs.Write(s)
				s = ""
				For n = 0 To 511
					s = glyphs(n).SerializeToCoe() & s
					If n = 511 Then
						s = s & ";" & vbLf
					Else
						s = s & "," & vbLf
					End If
				Next
			ElseIf fd.FileName.EndsWith(".ucf") Then
				gcnt = 0
				s = ""
				row = 0
				inst = 0
				For n = 0 To 511
					s = glyphs(n).SerializeToUCF() & s
					gcnt = gcnt + 1
					If gcnt = 4 Then
						gcnt = 0
						s = "INST " & txtInstName.Text & inst & " INIT_" & Hex(row).PadLeft(2, "0") & "=" & s & ";" & vbCrLf
						ofs.Write(s)
						s = ""
						row = row + 1
						If row = 64 Then
							row = 0
							inst = inst + 1
						End If
					End If
				Next
			Else
				ofs.WriteLine("always @(bmndx)")
                ofs.WriteLine("case(bmndx)")
                For n = 0 To 511
                    glyphs(n).SerializeToV(ofs)
                Next
                ofs.WriteLine("endcase")
            End If
            ofs.Close()
        End If
    End Sub


    Private Sub Button2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        OpenFile()
    End Sub

    Private Sub Button3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button3.Click
        Dim j As Integer

        For j = 0 To 511
            glyphs(j).FlipHoriz()
        Next

    End Sub


    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
		Dim j As Integer

		For j = 0 To 511
			'ListBox1.Items.Add(Hex(j) & " " & CStr(j))
			ListBox1.Items.Add(CStr(j))
		Next
	End Sub

    Private Sub PictureBox1_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles PictureBox1.Paint
        Dim n As Integer
        n = ListBox1.SelectedIndex()
        If n >= 0 Then
            glyphs(n).Draw(e)
        End If
    End Sub

    Private Sub ListBox1_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ListBox1.SelectedIndexChanged
        PictureBox1.Invalidate()
        PictureBox2.Invalidate()
    End Sub

    Private Sub PictureBox1_MouseDown(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles PictureBox1.MouseDown
        Dim wx As Integer
        Dim wy As Integer
		Dim n As Integer
		Dim sc As Integer

		If glyphs(0).horizDots < 9 And glyphs(0).scanlines < 9 Then
			sc = 20
		Else
			sc = 10
		End If
		wx = (e.X - 5) / sc
		wy = (e.Y - 5) / sc
		If (wx < 0 Or wx > glyphs(0).horizDots - 1) Or (wy < 0 Or wy > gheight) Then
		Else
			n = ListBox1.SelectedIndex()
            If n >= 0 Then
                glyphs(n).FlipBit(wx, wy)
                PictureBox1.Invalidate()
                PictureBox2.Invalidate()
            End If
        End If
    End Sub

    Private Sub MenuItem2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem2.Click
        OpenFile()
    End Sub

    Private Sub OpenFile()
        Dim n As Integer
        Dim ifl As File
        Dim strm As Stream
        Dim ifs As TextReader
        Dim path As String
        Dim fd As OpenFileDialog
        Dim text As String
        Dim lines() As String
        Dim line As String
        Dim strs() As String
        Dim data() As String
        Dim j As Integer
        Dim ch1 As Char
        Dim ch2 As Char
		Dim byt As String
		Dim s As String
		Dim bcnt As Integer
		Dim radix As Integer
		Dim gcnt As Integer
		Dim readingVector As Boolean
		fd = New OpenFileDialog
		fd.Filter = "Verilog files (*.v)|*.v|UCF files (*.ucf)|*.ucf|COE files (*.coe)|*.coe|All files (*.*)|*.*"
		fd.FilterIndex = 2
		If fd.ShowDialog() = DialogResult.OK Then
            ifs = ifl.OpenText(fd.FileName)
            text = ifs.ReadToEnd()
			lines = text.Split(vbLf)
			gcnt = 0
            bcnt = 0
			If fd.FileName.EndsWith(".coe") Then
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
							n = 0
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
							glyphs(gcnt).SetBitmap(bcnt, n)
							bcnt = bcnt + 1
							If bcnt = gheight Then
								bcnt = 0
								gcnt = gcnt + 1
								If gcnt = 512 Then GoTo x1
							End If
						End If
					End If
				Next
			Else
				For Each line In lines
					line = line.Trim
					If line.Length <> 0 Then
						If line.Chars(0) <> "#" Then    ' skip # lines
							If line.Length > 0 Then
								strs = line.Split(" ")
								If (strs(0) = "INST") Then
									data = strs(2).Split("=")
									data(1) = data(1).TrimEnd(";")
									For j = 63 To 0 Step -2
										byt = "&h" & data(1).Substring(j - 1, 2)
										n = CInt(byt)
										glyphs(gcnt).SetBitmap(bcnt, n)
										bcnt = bcnt + 1
										If bcnt = gheight Then
											bcnt = 0
											gcnt = gcnt + 1
											If gcnt = 512 Then GoTo x1
										End If
									Next
								End If
							End If
						End If
					End If
				Next
			End If
x1:
            For n = 0 To 511
                '                glyphs(n).SerializeTo(ofs)
            Next
            ifs.Close()
        End If
    End Sub

    Sub SaveFile()
        Dim n As Integer
        Dim ofl As File
        Dim strm As Stream
        Dim ofs As TextWriter
        Dim path As String
        Dim fd As SaveFileDialog
        Dim s As String
        Dim gcnt As Integer
        Dim row As Integer
        Dim inst As Integer
        Dim s1 As String
        Dim s2 As String
        Dim s3 As String

        fd = New SaveFileDialog
		fd.Filter = "Verilog files (*.v)|*.v|UCF files (*.ucf)|*.ucf|COE files (*.coe)|*.coe|All files (*.*)|*.*"
		fd.FilterIndex = 1
		If fd.ShowDialog() = DialogResult.OK Then
            ofs = ofl.CreateText(fd.FileName)
			If fd.FileName.EndsWith(".coe") Then
				s = "memory_initialization_radix=10;" & vbLf
				ofs.Write(s)
				s = "memory_initialization_vector=" & vbLf
				ofs.Write(s)
				s = ""
				For n = 0 To 511
					s1 = glyphs(n).SerializeToCoe()
					If n = 511 Then
						s = s1 & ";" & vbLf
					Else
						s = s1 & "," & vbLf
					End If
					ofs.Write(s)
				Next
			ElseIf fd.FileName.EndsWith(".ucf") Then
				gcnt = 0
                s = ""
                row = 0
                inst = 0
                For n = 0 To 511
                    s = glyphs(n).SerializeToUCF() & s
                    'gcnt = gcnt + 1
                    'If gcnt > 32 / gheight Then

                    'ElseIf gcnt >= 32 / gheight Then
                    '    gcnt = 0
                    '    s = "INST " & txtInstName.Text & inst & " INIT_" & Hex(row).PadLeft(2, "0") & "=" & s & ";" & vbCrLf
                    '    ofs.Write(s)
                    '    s = ""
                    '    row = row + 1
                    '    If row = 64 Then
                    '        row = 0
                    '        inst = inst + 1
                    '    End If
                    'End If
                Next
                s = "".PadLeft(64, "0") & s
                s2 = ""
                Do
                    If s.Length < 64 Then
                        s3 = s.PadLeft(64, "0")
                    Else
                        s3 = s.Substring(s.Length - 64)
                    End If
                    s1 = "INST " & txtInstName.Text & inst & " INIT_" & Hex(row).PadLeft(2, "0") & "=" & s3 & ";" & vbCrLf
                    s2 = s2 & s1
                    s = s.Substring(0, s.Length - 64)
                    row = row + 1
                    If row = 64 Then
                        row = 0
                        inst = inst + 1
                    End If
                Loop While s.Length > 0
                ofs.Write(s2)
            Else
				'ofs.WriteLine("always @(bmndx)")
				'ofs.WriteLine("case(bmndx)")
				For n = 0 To 511
					glyphs(n).index = n
					If n = 0 Then
						glyphs(n).Count = 0
					End If
					If CheckBox1.Checked Then
						glyphs(n).SerializeToV64(ofs)
					Else
						glyphs(n).SerializeToV(ofs)
					End If
					If n = 511 Then
						If CheckBox1.Checked Then
							glyphs(n).Flush(ofs)
						End If
					End If
				Next
				'ofs.WriteLine("endcase")
			End If
            ofs.Close()
        End If
    End Sub

    Private Sub MenuItem3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem3.Click
        SaveFile()
    End Sub

    Private Sub NumericUpDown2_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown2.ValueChanged
        Dim n As Integer
        gwidth = NumericUpDown2.Value
        For n = 0 To 511
            If Not glyphs(n) Is Nothing Then
                glyphs(n).horizDots = gwidth
            End If
        Next
        PictureBox1.Invalidate()
        PictureBox2.Invalidate()
    End Sub

    Private Sub NumericUpDown1_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown1.ValueChanged
        Dim n As Integer
        gheight = NumericUpDown1.Value
        For n = 0 To 511
            If Not glyphs(n) Is Nothing Then
                glyphs(n).scanlines = gheight
            End If
        Next
        PictureBox1.Invalidate()
        PictureBox2.Invalidate()
    End Sub

    Private Sub PictureBox1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PictureBox1.Click

    End Sub

    Private Sub PictureBox2_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles PictureBox2.Paint
        Dim n As Integer
        n = ListBox1.SelectedIndex()
        '        If n > 0 Then
        For n = 0 To 511
            glyphs(n).DrawSmall(e)
        Next n
        '        End If
    End Sub

    Private Sub MenuItem5_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem5.Click
        End
    End Sub

    Private Sub MenuItem4_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem4.Click
        Dim f As New frmAbout
        f.ShowDialog()
    End Sub

    Private Sub Button5_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        Dim dlgcolor As New ColorDialog
        dlgcolor.ShowDialog(Form1.ActiveForm)
        spriteColor = dlgcolor.Color
    End Sub

    Private Sub MenuItem7_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem7.Click
        frmSprite0 = New frmSprite
        frmSprite0.ShowDialog()
    End Sub
End Class
