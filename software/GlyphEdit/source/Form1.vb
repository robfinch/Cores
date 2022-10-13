Imports System.IO
Imports System.Reflection
Imports System.Windows.Forms.LinkLabel

Public Class Form1
	Inherits System.Windows.Forms.Form
	Dim gwidth As Integer
	Dim gheight As Integer
	Dim workingGlyph(32, 32) As Boolean
	Friend WithEvents CheckBox1 As CheckBox
	Friend WithEvents CheckBox2 As CheckBox
	Friend WithEvents Label4 As Label
	Friend WithEvents CheckBox3 As CheckBox
	Friend WithEvents Button1 As Button
	Friend WithEvents Button2 As Button
	Friend WithEvents Button4 As Button
	Friend WithEvents Panel2 As Panel
	Friend WithEvents PictureBox2 As PictureBox
	Friend WithEvents PictureBox1 As PictureBox
	Friend WithEvents CheckBox4 As CheckBox
	Friend WithEvents Label5 As Label
	Friend WithEvents Button5 As Button
	Friend WithEvents Button6 As Button
	Friend WithEvents NumericUpDown3 As NumericUpDown
	Friend WithEvents Label6 As Label
	Friend WithEvents Button7 As Button
	Friend WithEvents Button8 As Button
	Friend WithEvents Button9 As Button
	Friend WithEvents Button10 As Button
	Friend WithEvents Button11 As Button
	Friend WithEvents CheckBox5 As CheckBox
	Friend WithEvents CheckBox6 As CheckBox
	Friend WithEvents RadioButton1 As RadioButton
	Friend WithEvents RadioButton2 As RadioButton
	Friend WithEvents RadioButton3 As RadioButton
	Friend WithEvents RadioButton4 As RadioButton
	Friend WithEvents MenuItem8 As MenuItem
	Dim workingSprite(2048) As Int16
#Region " Windows Form Designer generated code "

	Public Sub New()
		MyBase.New()

		'This call is required by the Windows Form Designer.
		InitializeComponent()

		'Add any initialization after the InitializeComponent() call
		Dim n As Integer
		For n = 0 To nGlyphs() - 1
			glyphs(n) = New Glyph
			glyphs(n).index = n
			glyphs(n).scanlines = 8
			glyphs(n).horizDots = 8
		Next
		For n = 0 To 31
			sprites(n) = New Sprite
			sprites(n).index = n
			sprites(n).scanlines = 48
			sprites(n).horizDots = 42
		Next
		aam = False
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
		Me.Button1 = New System.Windows.Forms.Button()
		Me.Button2 = New System.Windows.Forms.Button()
		Me.Button4 = New System.Windows.Forms.Button()
		Me.Button5 = New System.Windows.Forms.Button()
		Me.Button6 = New System.Windows.Forms.Button()
		Me.Button7 = New System.Windows.Forms.Button()
		Me.Button8 = New System.Windows.Forms.Button()
		Me.Button9 = New System.Windows.Forms.Button()
		Me.Button10 = New System.Windows.Forms.Button()
		Me.Button11 = New System.Windows.Forms.Button()
		Me.ToolTip2 = New System.Windows.Forms.ToolTip(Me.components)
		Me.NumericUpDown1 = New System.Windows.Forms.NumericUpDown()
		Me.NumericUpDown2 = New System.Windows.Forms.NumericUpDown()
		Me.Label3 = New System.Windows.Forms.Label()
		Me.CheckBox1 = New System.Windows.Forms.CheckBox()
		Me.CheckBox2 = New System.Windows.Forms.CheckBox()
		Me.Label4 = New System.Windows.Forms.Label()
		Me.CheckBox3 = New System.Windows.Forms.CheckBox()
		Me.Panel2 = New System.Windows.Forms.Panel()
		Me.PictureBox2 = New System.Windows.Forms.PictureBox()
		Me.PictureBox1 = New System.Windows.Forms.PictureBox()
		Me.CheckBox4 = New System.Windows.Forms.CheckBox()
		Me.Label5 = New System.Windows.Forms.Label()
		Me.NumericUpDown3 = New System.Windows.Forms.NumericUpDown()
		Me.Label6 = New System.Windows.Forms.Label()
		Me.CheckBox5 = New System.Windows.Forms.CheckBox()
		Me.CheckBox6 = New System.Windows.Forms.CheckBox()
		Me.RadioButton1 = New System.Windows.Forms.RadioButton()
		Me.RadioButton2 = New System.Windows.Forms.RadioButton()
		Me.RadioButton3 = New System.Windows.Forms.RadioButton()
		Me.RadioButton4 = New System.Windows.Forms.RadioButton()
		Me.MenuItem8 = New System.Windows.Forms.MenuItem()
		CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.NumericUpDown2, System.ComponentModel.ISupportInitialize).BeginInit()
		Me.Panel2.SuspendLayout()
		CType(Me.PictureBox2, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.PictureBox1, System.ComponentModel.ISupportInitialize).BeginInit()
		CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).BeginInit()
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
		Me.Button3.Location = New System.Drawing.Point(36, 68)
		Me.Button3.Name = "Button3"
		Me.Button3.Size = New System.Drawing.Size(127, 28)
		Me.Button3.TabIndex = 167
		Me.Button3.Text = "Flip bits horizontally"
		Me.ToolTip1.SetToolTip(Me.Button3, "Switch bits from left to right in the entire character set.")
		'
		'ListBox1
		'
		Me.ListBox1.Location = New System.Drawing.Point(256, 21)
		Me.ListBox1.Name = "ListBox1"
		Me.ListBox1.Size = New System.Drawing.Size(58, 251)
		Me.ListBox1.TabIndex = 168
		'
		'MainMenu1
		'
		Me.MainMenu1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem1, Me.MenuItem6, Me.MenuItem8, Me.MenuItem4})
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
		Me.MenuItem4.Index = 3
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
		'Button1
		'
		Me.Button1.Location = New System.Drawing.Point(747, 89)
		Me.Button1.Name = "Button1"
		Me.Button1.Size = New System.Drawing.Size(95, 28)
		Me.Button1.TabIndex = 182
		Me.Button1.Text = "Shift All Left"
		Me.ToolTip1.SetToolTip(Me.Button1, "Switch bits from left to right in the entire character set.")
		'
		'Button2
		'
		Me.Button2.Location = New System.Drawing.Point(169, 68)
		Me.Button2.Name = "Button2"
		Me.Button2.Size = New System.Drawing.Size(54, 28)
		Me.Button2.TabIndex = 183
		Me.Button2.Text = "Copy"
		Me.ToolTip1.SetToolTip(Me.Button2, "Switch bits from left to right in the entire character set.")
		'
		'Button4
		'
		Me.Button4.Location = New System.Drawing.Point(169, 102)
		Me.Button4.Name = "Button4"
		Me.Button4.Size = New System.Drawing.Size(54, 28)
		Me.Button4.TabIndex = 184
		Me.Button4.Text = "Paste"
		Me.ToolTip1.SetToolTip(Me.Button4, "Switch bits from left to right in the entire character set.")
		'
		'Button5
		'
		Me.Button5.Location = New System.Drawing.Point(747, 55)
		Me.Button5.Name = "Button5"
		Me.Button5.Size = New System.Drawing.Size(95, 28)
		Me.Button5.TabIndex = 193
		Me.Button5.Text = "Shift All Down"
		Me.ToolTip1.SetToolTip(Me.Button5, "Switch bits from left to right in the entire character set.")
		'
		'Button6
		'
		Me.Button6.Location = New System.Drawing.Point(747, 21)
		Me.Button6.Name = "Button6"
		Me.Button6.Size = New System.Drawing.Size(95, 28)
		Me.Button6.TabIndex = 194
		Me.Button6.Text = "Shift All Up"
		Me.ToolTip1.SetToolTip(Me.Button6, "Switch bits from left to right in the entire character set.")
		'
		'Button7
		'
		Me.Button7.Location = New System.Drawing.Point(747, 123)
		Me.Button7.Name = "Button7"
		Me.Button7.Size = New System.Drawing.Size(95, 28)
		Me.Button7.TabIndex = 197
		Me.Button7.Text = "Shift All Right"
		Me.ToolTip1.SetToolTip(Me.Button7, "Switch bits from left to right in the entire character set.")
		'
		'Button8
		'
		Me.Button8.Location = New System.Drawing.Point(618, 21)
		Me.Button8.Name = "Button8"
		Me.Button8.Size = New System.Drawing.Size(103, 28)
		Me.Button8.TabIndex = 198
		Me.Button8.Text = "Shift Glyph Up"
		Me.ToolTip1.SetToolTip(Me.Button8, "Switch bits from left to right in the entire character set.")
		'
		'Button9
		'
		Me.Button9.Location = New System.Drawing.Point(618, 55)
		Me.Button9.Name = "Button9"
		Me.Button9.Size = New System.Drawing.Size(103, 28)
		Me.Button9.TabIndex = 199
		Me.Button9.Text = "Shift Glyph Down"
		Me.ToolTip1.SetToolTip(Me.Button9, "Switch bits from left to right in the entire character set.")
		'
		'Button10
		'
		Me.Button10.Location = New System.Drawing.Point(618, 89)
		Me.Button10.Name = "Button10"
		Me.Button10.Size = New System.Drawing.Size(103, 28)
		Me.Button10.TabIndex = 200
		Me.Button10.Text = "Shift Glyph Left"
		Me.ToolTip1.SetToolTip(Me.Button10, "Switch bits from left to right in the entire character set.")
		'
		'Button11
		'
		Me.Button11.Location = New System.Drawing.Point(618, 123)
		Me.Button11.Name = "Button11"
		Me.Button11.Size = New System.Drawing.Size(103, 28)
		Me.Button11.TabIndex = 201
		Me.Button11.Text = "Shift Glyph Right"
		Me.ToolTip1.SetToolTip(Me.Button11, "Switch bits from left to right in the entire character set.")
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
		Me.NumericUpDown2.Increment = New Decimal(New Integer() {2, 0, 0, 0})
		Me.NumericUpDown2.Location = New System.Drawing.Point(107, 153)
		Me.NumericUpDown2.Maximum = New Decimal(New Integer() {32, 0, 0, 0})
		Me.NumericUpDown2.Minimum = New Decimal(New Integer() {6, 0, 0, 0})
		Me.NumericUpDown2.Name = "NumericUpDown2"
		Me.NumericUpDown2.Size = New System.Drawing.Size(53, 20)
		Me.NumericUpDown2.TabIndex = 175
		Me.NumericUpDown2.TextAlign = System.Windows.Forms.HorizontalAlignment.Center
		Me.NumericUpDown2.Value = New Decimal(New Integer() {8, 0, 0, 0})
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
		Me.CheckBox1.Location = New System.Drawing.Point(33, 266)
		Me.CheckBox1.Name = "CheckBox1"
		Me.CheckBox1.Size = New System.Drawing.Size(72, 17)
		Me.CheckBox1.TabIndex = 178
		Me.CheckBox1.Text = "64-bit ram"
		Me.CheckBox1.UseVisualStyleBackColor = True
		'
		'CheckBox2
		'
		Me.CheckBox2.AutoSize = True
		Me.CheckBox2.Location = New System.Drawing.Point(33, 289)
		Me.CheckBox2.Name = "CheckBox2"
		Me.CheckBox2.Size = New System.Drawing.Size(72, 17)
		Me.CheckBox2.TabIndex = 179
		Me.CheckBox2.Text = "32-bit ram"
		Me.CheckBox2.UseVisualStyleBackColor = True
		'
		'Label4
		'
		Me.Label4.AutoSize = True
		Me.Label4.Location = New System.Drawing.Point(33, 250)
		Me.Label4.Name = "Label4"
		Me.Label4.Size = New System.Drawing.Size(72, 13)
		Me.Label4.TabIndex = 180
		Me.Label4.Text = "Verilog output"
		'
		'CheckBox3
		'
		Me.CheckBox3.AutoSize = True
		Me.CheckBox3.Location = New System.Drawing.Point(132, 266)
		Me.CheckBox3.Name = "CheckBox3"
		Me.CheckBox3.Size = New System.Drawing.Size(71, 17)
		Me.CheckBox3.TabIndex = 181
		Me.CheckBox3.Text = "8-bit mem"
		Me.CheckBox3.UseVisualStyleBackColor = True
		'
		'Panel2
		'
		Me.Panel2.AutoScroll = True
		Me.Panel2.Controls.Add(Me.PictureBox2)
		Me.Panel2.Location = New System.Drawing.Point(24, 312)
		Me.Panel2.Name = "Panel2"
		Me.Panel2.Size = New System.Drawing.Size(869, 446)
		Me.Panel2.TabIndex = 188
		'
		'PictureBox2
		'
		Me.PictureBox2.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
		Me.PictureBox2.Location = New System.Drawing.Point(3, 3)
		Me.PictureBox2.Name = "PictureBox2"
		Me.PictureBox2.Size = New System.Drawing.Size(844, 970)
		Me.PictureBox2.TabIndex = 190
		Me.PictureBox2.TabStop = False
		'
		'PictureBox1
		'
		Me.PictureBox1.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle
		Me.PictureBox1.Location = New System.Drawing.Point(331, 21)
		Me.PictureBox1.Name = "PictureBox1"
		Me.PictureBox1.Size = New System.Drawing.Size(269, 251)
		Me.PictureBox1.TabIndex = 190
		Me.PictureBox1.TabStop = False
		'
		'CheckBox4
		'
		Me.CheckBox4.AutoSize = True
		Me.CheckBox4.Checked = True
		Me.CheckBox4.CheckState = System.Windows.Forms.CheckState.Checked
		Me.CheckBox4.Location = New System.Drawing.Point(132, 289)
		Me.CheckBox4.Name = "CheckBox4"
		Me.CheckBox4.Size = New System.Drawing.Size(77, 17)
		Me.CheckBox4.TabIndex = 191
		Me.CheckBox4.Text = "64-bit mem"
		Me.CheckBox4.UseVisualStyleBackColor = True
		'
		'Label5
		'
		Me.Label5.AutoSize = True
		Me.Label5.Location = New System.Drawing.Point(124, 250)
		Me.Label5.Name = "Label5"
		Me.Label5.Size = New System.Drawing.Size(50, 13)
		Me.Label5.TabIndex = 192
		Me.Label5.Text = ".mem out"
		'
		'NumericUpDown3
		'
		Me.NumericUpDown3.Location = New System.Drawing.Point(353, 286)
		Me.NumericUpDown3.Maximum = New Decimal(New Integer() {256, 0, 0, 0})
		Me.NumericUpDown3.Minimum = New Decimal(New Integer() {1, 0, 0, 0})
		Me.NumericUpDown3.Name = "NumericUpDown3"
		Me.NumericUpDown3.Size = New System.Drawing.Size(51, 20)
		Me.NumericUpDown3.TabIndex = 195
		Me.NumericUpDown3.Value = New Decimal(New Integer() {32, 0, 0, 0})
		'
		'Label6
		'
		Me.Label6.AutoSize = True
		Me.Label6.Location = New System.Drawing.Point(288, 290)
		Me.Label6.Name = "Label6"
		Me.Label6.Size = New System.Drawing.Size(59, 13)
		Me.Label6.TabIndex = 196
		Me.Label6.Text = "Map Width"
		'
		'CheckBox5
		'
		Me.CheckBox5.AutoSize = True
		Me.CheckBox5.Checked = True
		Me.CheckBox5.CheckState = System.Windows.Forms.CheckState.Checked
		Me.CheckBox5.Location = New System.Drawing.Point(618, 240)
		Me.CheckBox5.Name = "CheckBox5"
		Me.CheckBox5.Size = New System.Drawing.Size(81, 17)
		Me.CheckBox5.TabIndex = 202
		Me.CheckBox5.Text = "Add header"
		Me.CheckBox5.UseVisualStyleBackColor = True
		'
		'CheckBox6
		'
		Me.CheckBox6.AutoSize = True
		Me.CheckBox6.Enabled = False
		Me.CheckBox6.Location = New System.Drawing.Point(618, 217)
		Me.CheckBox6.Name = "CheckBox6"
		Me.CheckBox6.Size = New System.Drawing.Size(194, 17)
		Me.CheckBox6.TabIndex = 203
		Me.CheckBox6.Text = "Anit-alias mode (under construction)"
		Me.CheckBox6.UseVisualStyleBackColor = True
		'
		'RadioButton1
		'
		Me.RadioButton1.Appearance = System.Windows.Forms.Appearance.Button
		Me.RadioButton1.AutoSize = True
		Me.RadioButton1.BackColor = System.Drawing.Color.Black
		Me.RadioButton1.Enabled = False
		Me.RadioButton1.Location = New System.Drawing.Point(618, 177)
		Me.RadioButton1.Name = "RadioButton1"
		Me.RadioButton1.Size = New System.Drawing.Size(41, 23)
		Me.RadioButton1.TabIndex = 208
		Me.RadioButton1.TabStop = True
		Me.RadioButton1.Text = "        "
		Me.RadioButton1.UseVisualStyleBackColor = False
		'
		'RadioButton2
		'
		Me.RadioButton2.Appearance = System.Windows.Forms.Appearance.Button
		Me.RadioButton2.AutoSize = True
		Me.RadioButton2.BackColor = System.Drawing.SystemColors.ControlDark
		Me.RadioButton2.Enabled = False
		Me.RadioButton2.Location = New System.Drawing.Point(665, 177)
		Me.RadioButton2.Name = "RadioButton2"
		Me.RadioButton2.Size = New System.Drawing.Size(41, 23)
		Me.RadioButton2.TabIndex = 209
		Me.RadioButton2.TabStop = True
		Me.RadioButton2.Text = "        "
		Me.RadioButton2.UseVisualStyleBackColor = False
		'
		'RadioButton3
		'
		Me.RadioButton3.Appearance = System.Windows.Forms.Appearance.Button
		Me.RadioButton3.AutoSize = True
		Me.RadioButton3.BackColor = System.Drawing.SystemColors.ControlLight
		Me.RadioButton3.Enabled = False
		Me.RadioButton3.Location = New System.Drawing.Point(712, 177)
		Me.RadioButton3.Name = "RadioButton3"
		Me.RadioButton3.Size = New System.Drawing.Size(41, 23)
		Me.RadioButton3.TabIndex = 210
		Me.RadioButton3.TabStop = True
		Me.RadioButton3.Text = "        "
		Me.RadioButton3.UseVisualStyleBackColor = False
		'
		'RadioButton4
		'
		Me.RadioButton4.Appearance = System.Windows.Forms.Appearance.Button
		Me.RadioButton4.AutoSize = True
		Me.RadioButton4.BackColor = System.Drawing.SystemColors.ControlLightLight
		Me.RadioButton4.Enabled = False
		Me.RadioButton4.Location = New System.Drawing.Point(760, 177)
		Me.RadioButton4.Name = "RadioButton4"
		Me.RadioButton4.Size = New System.Drawing.Size(41, 23)
		Me.RadioButton4.TabIndex = 211
		Me.RadioButton4.TabStop = True
		Me.RadioButton4.Text = "        "
		Me.RadioButton4.UseVisualStyleBackColor = False
		'
		'MenuItem8
		'
		Me.MenuItem8.Index = 2
		Me.MenuItem8.Text = "Icon"
		'
		'Form1
		'
		Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
		Me.ClientSize = New System.Drawing.Size(992, 770)
		Me.Controls.Add(Me.RadioButton4)
		Me.Controls.Add(Me.RadioButton3)
		Me.Controls.Add(Me.RadioButton2)
		Me.Controls.Add(Me.RadioButton1)
		Me.Controls.Add(Me.CheckBox6)
		Me.Controls.Add(Me.CheckBox5)
		Me.Controls.Add(Me.Button11)
		Me.Controls.Add(Me.Button10)
		Me.Controls.Add(Me.Button9)
		Me.Controls.Add(Me.Button8)
		Me.Controls.Add(Me.Button7)
		Me.Controls.Add(Me.Label6)
		Me.Controls.Add(Me.NumericUpDown3)
		Me.Controls.Add(Me.Button6)
		Me.Controls.Add(Me.Button5)
		Me.Controls.Add(Me.Label5)
		Me.Controls.Add(Me.CheckBox4)
		Me.Controls.Add(Me.PictureBox1)
		Me.Controls.Add(Me.Panel2)
		Me.Controls.Add(Me.Button4)
		Me.Controls.Add(Me.Button2)
		Me.Controls.Add(Me.Button1)
		Me.Controls.Add(Me.CheckBox3)
		Me.Controls.Add(Me.Label4)
		Me.Controls.Add(Me.CheckBox2)
		Me.Controls.Add(Me.CheckBox1)
		Me.Controls.Add(Me.Label3)
		Me.Controls.Add(Me.NumericUpDown2)
		Me.Controls.Add(Me.NumericUpDown1)
		Me.Controls.Add(Me.lblHeight)
		Me.Controls.Add(Me.Label2)
		Me.Controls.Add(Me.ListBox1)
		Me.Controls.Add(Me.Button3)
		Me.Controls.Add(Me.txtInstName)
		Me.Controls.Add(Me.Label1)
		Me.Menu = Me.MainMenu1
		Me.Name = "Form1"
		Me.Text = "6x6 to 32x32 Glyph Editor"
		Me.ToolTip1.SetToolTip(Me, "Number of scanlines for each glyph")
		CType(Me.NumericUpDown1, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.NumericUpDown2, System.ComponentModel.ISupportInitialize).EndInit()
		Me.Panel2.ResumeLayout(False)
		CType(Me.PictureBox2, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.PictureBox1, System.ComponentModel.ISupportInitialize).EndInit()
		CType(Me.NumericUpDown3, System.ComponentModel.ISupportInitialize).EndInit()
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
				For n = 0 To nGlyphs() - 1
					s = glyphs(n).SerializeToCoe() & s
					If n = nGlyphs() - 1 Then
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
				For n = 0 To modGlobals.nGlyphs() - 1
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
				For n = 0 To nGlyphs() - 1
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

		For j = 0 To nGlyphs() - 1
			glyphs(j).FlipHoriz()
		Next

	End Sub


	Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
		Dim j As Integer

		For j = 0 To modGlobals.nGlyphs() - 1
			'ListBox1.Items.Add(Hex(j) & " " & CStr(j))
			ListBox1.Items.Add(CStr(j))
		Next
		ResizePictureBox2()
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
				If aam Then
					If RadioButton1.Checked Then
						glyphs(n).ClearBit(wx * 2, wy * 2)
						glyphs(n).ClearBit(wx * 2 + 1, wy * 2)
					End If
					If RadioButton2.Checked Then
						glyphs(n).ClearBit(wx * 2, wy * 2)
						glyphs(n).SetBit(wx * 2 + 1, wy * 2)
					End If
					If RadioButton3.Checked Then
						glyphs(n).SetBit(wx * 2, wy * 2)
						glyphs(n).ClearBit(wx * 2 + 1, wy * 2)
					End If
					If RadioButton4.Checked Then
						glyphs(n).SetBit(wx * 2, wy * 2)
						glyphs(n).SetBit(wx * 2 + 1, wy * 2)
					End If
				Else
					glyphs(n).FlipBit(wx, wy)
				End If
				PictureBox1.Invalidate()
				PictureBox2.Invalidate()
				Refresh()
			End If
		End If
	End Sub

	Private Sub MenuItem2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem2.Click
		OpenFile()
	End Sub

	Sub Undraw()
		Dim n As Integer
		For n = 0 To modGlobals.nGlyphs() - 1
			glyphs(n).UndrawSmall()
		Next
	End Sub
	Private Sub OpenBitmap(ByVal nm As String)
		Dim n As Integer
		bmpGlyphs = New Bitmap(nm)
		'				PictureBox2.Load(fd.FileName)
		For n = 0 To modGlobals.nGlyphs() - 1
			If Not glyphs(n) Is Nothing Then
				glyphs(n).index = n
				glyphs(n).scanlines = gheight
				glyphs(n).horizDots = gwidth
			End If
		Next
		Undraw()
		PictureBox2.Invalidate()
		Refresh()
	End Sub
	Sub SerializeFromCoe(ByVal nm As String)
		Dim n As Integer
		Dim j As Integer
		Dim readingVector As Boolean
		Dim radix As Integer
		Dim txt As String
		Dim lines() As String
		Dim line As String
		Dim s As String
		Dim strs() As String
		Dim gcnt As Integer
		Dim bcnt As Integer
		Dim ifs As TextReader
		Dim ifl As File

		gcnt = 0
		bcnt = 0
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
						If gcnt = nGlyphs() Then Return
					End If
				End If
			End If
		Next
	End Sub
	Sub SerializeFromMem(ByVal nm As String)
		Dim n As Integer
		Dim sz As Integer
		Dim txt As String
		Dim lines() As String
		Dim line As String
		Dim ifs As TextReader
		Dim ifl As File
		Dim s As String
		Dim hdr As String
		Dim gcnt As Integer

		sz = 0
		If CheckBox4.Checked Then
			sz = 64
		ElseIf CheckBox3.Checked Then
			sz = 8
		End If
		ifs = ifl.OpenText(nm)
		hdr = ifs.ReadLine()
		txt = ifs.ReadToEnd()
		ifs.Close()
		lines = txt.Split(vbLf)
		gwidth = Convert.ToInt32(hdr.Substring(12, 2), 16)
		gheight = Convert.ToInt32(hdr.Substring(14, 2), 16)
		NumericUpDown1.Value = gheight
		NumericUpDown2.Value = gwidth
		Refresh()
		For n = 0 To modGlobals.nGlyphs() - 1
			If Not glyphs(n) Is Nothing Then
				glyphs(n).scanlines = gheight
				glyphs(n).horizDots = gwidth
			End If
		Next
		For Each line In lines
			s = line.Trim
			If (s <> "") Then
				glyphs(gcnt).SerializeFromMem(s, sz)
				gcnt = gcnt + 1
				If gcnt = modGlobals.nGlyphs() Then Return
			End If
		Next
	End Sub
	Sub SerializeFromBin(ByVal nm As String)
		Dim n As Integer
		Dim ary() As Byte
		Dim jj As Integer
		Dim kk As Integer
		Dim mm As Integer
		Dim nn As Integer
		Dim ndx As Integer
		Dim siz As Integer
		Dim bwid As Integer
		Dim bary() As Byte
		ary = My.Computer.FileSystem.ReadAllBytes(nm)
		jj = 0
		mm = 0
		If CheckBox5.Checked Then
			gheight = ary(0)
			gwidth = ary(1)
			jj = 8
			mm = 8
		End If
		siz = (gwidth + 7) And Not 7 ' round to a byte size
		bwid = siz
		siz >>= 3
		siz *= gheight
		siz = (siz + 7) And Not 7     ' round to multiple of eight bytes
		ReDim bary(siz - 1)
		nn = 0
		For n = 0 To modGlobals.nGlyphs() - 1
			If Not glyphs(n) Is Nothing Then
				glyphs(n).scanlines = gheight
				glyphs(n).horizDots = gwidth
			End If
		Next
		While mm < ary.Length
			ndx = 0
			For jj = 0 To gheight - 1
				For kk = 0 To gwidth - 1 Step 8
					bary(ndx) = ary(mm)
					mm += 1
					If mm >= ary.Length Then Return
					ndx = ndx + 1
				Next
			Next
			While mm Mod 8 <> 0
				bary(ndx) = ary(mm)
				mm += 1
				If mm >= ary.Length Then Return
				ndx += 1
			End While
			glyphs(nn).SerializeFromBin(bary)
			nn = nn + 1
		End While
	End Sub
	Private Sub OpenFile()
		Dim n As Integer
		Dim ifl As File
		Dim ifs As TextReader
		Dim fd As OpenFileDialog
		Dim text As String
		Dim lines() As String
		Dim line As String
		Dim strs() As String
		Dim data() As String
		Dim j As Integer
		Dim byt As String
		Dim s As String
		Dim bcnt As Integer
		Dim gcnt As Integer
		fd = New OpenFileDialog
		s = "MEM files (*.mem)|*.mem|Raw Binary (*.bin)|*.bin|Bitmap (*.bmp)|*.bmp|Png (*.png)|*.png|Jpeg (*.jpg)|*.jpg|"
		fd.Filter = s & "Verilog files (*.v)|*.v|UCF files (*.ucf)|*.ucf|COE files (*.coe)|*.coe|All files (*.*)|*.*"
		fd.FilterIndex = 1
		If fd.ShowDialog() = DialogResult.OK Then
			If fd.FileName.EndsWith(".bmp") Then
				OpenBitmap(fd.FileName)
				GoTo x2
			End If
			If fd.FileName.EndsWith(".png") Then
				OpenBitmap(fd.FileName)
				GoTo x2
			End If
			If fd.FileName.EndsWith(".jpg") Then
				OpenBitmap(fd.FileName)
				GoTo x2
			End If
			If fd.FileName.EndsWith(".mem") Then
				SerializeFromMem(fd.FileName)
				GoTo x2
			End If
			If fd.FileName.EndsWith(".bin") Then
				SerializeFromBin(fd.FileName)
				GoTo x2
			End If
			If fd.FileName.EndsWith(".coe") Then
				SerializeFromCoe(fd.FileName)
				GoTo x2
			End If
			If Not fd.FileName.EndsWith(".bin") Then
				ifs = ifl.OpenText(fd.FileName)
			End If
			If Not fd.FileName.EndsWith(".bin") Then
				text = ifs.ReadToEnd()
				lines = text.Split(vbLf)
			End If
			gcnt = 0
			bcnt = 0
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
										If gcnt = nGlyphs() Then GoTo x1
									End If
								Next
							End If
						End If
					End If
				End If
			Next
			ifs.Close()
x1:
			For n = 0 To nGlyphs() - 1
				'                glyphs(n).SerializeTo(ofs)
			Next
		End If
x2:
		ListBox1.Items.Clear()
		For j = 0 To modGlobals.nGlyphs() - 1
			'ListBox1.Items.Add(Hex(j) & " " & CStr(j))
			ListBox1.Items.Add(CStr(j))
		Next
		Refresh()
	End Sub

	Sub SaveFile()
		Dim n As Integer
		Dim ofl As File
		Dim ofs As TextWriter
		Dim fd As SaveFileDialog
		Dim s As String
		Dim gcnt As Integer
		Dim row As Integer
		Dim inst As Integer
		Dim s1 As String
		Dim s2 As String
		Dim s3 As String
		Dim sz As Integer
		Dim hdr As String

		fd = New SaveFileDialog
		s1 = "MEM files (*.mem)|*.mem|Raw Binary (*.bin)|*.bin|Bitmap (*.bmp)|*.bmp|PGN (*.png)|*.png|Jpeg (*.jpg)|*.jpg|"
		fd.Filter = s1 & "Verilog files (*.v)|*.v|UCF files (*.ucf)|*.ucf|COE files (*.coe)|*.coe|All files (*.*)|*.*"
		fd.FilterIndex = 1
		If fd.ShowDialog() = DialogResult.OK Then
			If fd.FileName.EndsWith(".bin") Or fd.FileName.EndsWith(".bmp") Then
			Else
				ofs = ofl.CreateText(fd.FileName)
			End If
			If fd.FileName.EndsWith(".coe") Then
				s = "memory_initialization_radix=10;" & vbLf
				ofs.Write(s)
				s = "memory_initialization_vector=" & vbLf
				ofs.Write(s)
				s = ""
				For n = 0 To nGlyphs() - 1
					s1 = glyphs(n).SerializeToCoe()
					If n = nGlyphs() - 1 Then
						s = s1 & ";" & vbLf
					Else
						s = s1 & "," & vbLf
					End If
					ofs.Write(s)
				Next
				ofs.Close()
			ElseIf fd.FileName.EndsWith(".bmp") Then
				bmpGlyphs.Save(fd.FileName, Imaging.ImageFormat.Bmp)
				Return
			ElseIf fd.FileName.EndsWith(".jpg") Then
				bmpGlyphs.Save(fd.FileName, Imaging.ImageFormat.Jpeg)
				Return
			ElseIf fd.FileName.EndsWith(".png") Then
				bmpGlyphs.Save(fd.FileName, Imaging.ImageFormat.Png)
				Return
			ElseIf fd.FileName.EndsWith(".gif") Then
				bmpGlyphs.Save(fd.FileName, Imaging.ImageFormat.Gif)
				Return
			ElseIf fd.FileName.EndsWith(".ucf") Then
				gcnt = 0
				s = ""
				row = 0
				inst = 0
				For n = 0 To modGlobals.nGlyphs() - 1
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
				ofs.Close()
			ElseIf fd.FileName.EndsWith(".mem") Then
				s = ""
				sz = 0
				hdr = "000000000000"
				hdr = hdr & Hex(glyphs(0).horizDots).PadLeft(2, "0") & Hex(glyphs(0).scanlines).PadLeft(2, "0") & vbLf
				If CheckBox4.Checked Then
					sz = 64
					ofs.Write(hdr)
				ElseIf CheckBox3.Checked Then
					sz = 8
				End If
				For n = 0 To nGlyphs() - 1
					glyphs(n).index = n
					If (n = 0) Then
						s = glyphs(n).SerializeToMem(sz)
					Else
						s = vbLf & glyphs(n).SerializeToMem(sz)
					End If
					ofs.Write(s)
				Next
				ofs.Close()
				' Saving raw byte output
			ElseIf fd.FileName.EndsWith(".bin") Then
				Dim bhdr As UInt64
				Dim j As Integer
				Dim bythdr(7) As Byte
				Dim ary() As Byte
				bhdr = (glyphs(0).horizDots << 8) Or glyphs(0).scanlines
				If CheckBox5.Checked Then
					For j = 0 To 7
						bythdr(j) = bhdr And 255
						bhdr >>= 8
					Next
					My.Computer.FileSystem.WriteAllBytes(fd.FileName, bythdr, False)
				End If
				For n = 0 To nGlyphs() - 1
					glyphs(n).index = n
					ary = glyphs(n).SerializeToBin()
					My.Computer.FileSystem.WriteAllBytes(fd.FileName, ary, n <> 0 Or CheckBox5.Checked)
				Next
			Else
				'ofs.WriteLine("always @(bmndx)")
				'ofs.WriteLine("case(bmndx)")
				For n = 0 To modGlobals.nGlyphs() - 1
					glyphs(n).index = n
					If n = 0 Then
						glyphs(n).Count = 0
					End If
					If CheckBox1.Checked Then
						glyphs(n).SerializeToV64(ofs)
					ElseIf CheckBox2.Checked Then
						glyphs(n).SerializeToV32(ofs)
					Else
						glyphs(n).SerializeToV(ofs)
					End If
					If n = modGlobals.nGlyphs() Then
						If CheckBox1.Checked Then
							glyphs(n).Flush(ofs)
						End If
					End If
				Next
				'ofs.WriteLine("endcase")
				ofs.Close()
			End If
		End If
	End Sub

	Private Sub MenuItem3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuItem3.Click
		SaveFile()
	End Sub

	Private Sub NumericUpDown2_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown2.ValueChanged
		Dim n As Integer
		Dim j As Integer
		If aam Then
			gwidth = NumericUpDown2.Value * 2
		Else
			gwidth = NumericUpDown2.Value
		End If
		gwidth = NumericUpDown2.Value
		For n = 0 To nGlyphs() - 1
			If Not glyphs(n) Is Nothing Then
				glyphs(n).horizDots = gwidth
			End If
		Next
		ResizePictureBox2()
		ListBox1.Items.Clear()
		For j = 0 To modGlobals.nGlyphs() - 1
			'ListBox1.Items.Add(Hex(j) & " " & CStr(j))
			ListBox1.Items.Add(CStr(j))
		Next
		PictureBox1.Invalidate()
		PictureBox2.Invalidate()
	End Sub

	Private Sub NumericUpDown1_ValueChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles NumericUpDown1.ValueChanged
		Dim n As Integer
		Dim j As Integer
		gheight = NumericUpDown1.Value
		For n = 0 To nGlyphs() - 1
			If Not glyphs(n) Is Nothing Then
				glyphs(n).scanlines = gheight
			End If
		Next
		ResizePictureBox2()
		ListBox1.Items.Clear()
		For j = 0 To modGlobals.nGlyphs() - 1
			'ListBox1.Items.Add(Hex(j) & " " & CStr(j))
			ListBox1.Items.Add(CStr(j))
		Next
		PictureBox1.Invalidate()
		PictureBox2.Invalidate()
	End Sub

	Sub ResizePictureBox2()
		Dim w As Double
		Dim wi As Integer

		If Not glyphs(0) Is Nothing Then
			w = Math.Floor(modGlobals.nGlyphs() / mapWidth)
			wi = glyphs(0).scanlines * 2 * (w + 1)
			PictureBox2.Size = New Size(glyphs(0).horizDots * 2 * mapWidth, glyphs(0).scanlines * 2 * w)
			bmpGlyphs = New Bitmap(glyphs(0).horizDots * 2 * mapWidth, wi)
			PictureBox2.Image = bmpGlyphs
		End If
	End Sub
	Private Sub PictureBox1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PictureBox1.Click

	End Sub

	Private Sub PictureBox2_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles PictureBox2.Paint
		Dim n As Integer

		'		n = ListBox1.SelectedIndex()
		For n = 0 To modGlobals.nGlyphs() - 1
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

	Private Sub CheckBox3_CheckedChanged(sender As Object, e As EventArgs) Handles CheckBox3.CheckedChanged

	End Sub

	Private Sub Button1_Click_1(sender As Object, e As EventArgs) Handles Button1.Click
		Dim j As Integer

		For j = 0 To modGlobals.nGlyphs() - 1
			If aam Then
				glyphs(j).ShiftLeft()
			End If
			glyphs(j).ShiftLeft()
		Next
		Refresh()
	End Sub

	Private Sub Button2_Click_1(sender As Object, e As EventArgs) Handles Button2.Click
		Dim n As Integer
		Dim sz As Integer

		If CheckBox4.Checked Then
			sz = 64
		ElseIf CheckBox3.Checked Then
			sz = 8
		Else
			sz = 0
		End If
		n = ListBox1.SelectedIndex()
		Clipboard.SetText(glyphs(n).SerializeToMem(sz))
	End Sub

	Private Sub Button4_Click(sender As Object, e As EventArgs) Handles Button4.Click
		Dim n As Integer
		Dim sz As Integer

		If CheckBox4.Checked Then
			sz = 64
		ElseIf CheckBox3.Checked Then
			sz = 8
		Else
			sz = 0
		End If
		n = ListBox1.SelectedIndex()
		glyphs(n).SerializeFromMem(Clipboard.GetText(), sz)
		Refresh()
	End Sub

	Private Sub TrackBar1_ValueChanged(sender As Object, e As EventArgs)
		Refresh()
	End Sub

	Private Sub Button5_Click_1(sender As Object, e As EventArgs) Handles Button5.Click
		Dim j As Integer

		For j = 0 To modGlobals.nGlyphs() - 1
			glyphs(j).ShiftDown()
		Next
		Refresh()
	End Sub

	Private Sub Button6_Click(sender As Object, e As EventArgs) Handles Button6.Click
		Dim j As Integer

		For j = 0 To modGlobals.nGlyphs() - 1
			glyphs(j).ShiftUp()
		Next
		Refresh()
	End Sub

	Private Sub NumericUpDown3_ValueChanged(sender As Object, e As EventArgs) Handles NumericUpDown3.ValueChanged
		mapWidth = NumericUpDown3.Value
		ResizePictureBox2()
		PictureBox2.Invalidate()
	End Sub

	Private Sub Button7_Click(sender As Object, e As EventArgs) Handles Button7.Click
		Dim j As Integer

		For j = 0 To modGlobals.nGlyphs() - 1
			If aam Then
				glyphs(j).ShiftRight()
			End If
			glyphs(j).ShiftRight()
		Next
		Refresh()
	End Sub

	Private Sub Button8_Click(sender As Object, e As EventArgs) Handles Button8.Click
		Dim n As Integer
		n = ListBox1.SelectedIndex()
		glyphs(n).ShiftUp()
		Refresh()
	End Sub

	Private Sub Button9_Click(sender As Object, e As EventArgs) Handles Button9.Click
		Dim n As Integer
		n = ListBox1.SelectedIndex()
		glyphs(n).ShiftDown()
		Refresh()
	End Sub

	Private Sub Button10_Click(sender As Object, e As EventArgs) Handles Button10.Click
		Dim n As Integer
		n = ListBox1.SelectedIndex()
		If aam Then
			glyphs(n).ShiftLeft()
		End If
		glyphs(n).ShiftLeft()
		Refresh()
	End Sub

	Private Sub Button11_Click(sender As Object, e As EventArgs) Handles Button11.Click
		Dim n As Integer
		n = ListBox1.SelectedIndex()
		If aam Then
			glyphs(n).ShiftRight()
		End If
		glyphs(n).ShiftRight()
		Refresh()
	End Sub

	Private Sub CheckBox5_CheckedChanged(sender As Object, e As EventArgs) Handles CheckBox5.CheckedChanged
	End Sub

	Private Sub RadioButton1_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton1.CheckedChanged
		dotColor = Color.Black
	End Sub

	Private Sub RadioButton4_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton4.CheckedChanged
		dotColor = Color.White
	End Sub

	Private Sub RadioButton2_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton2.CheckedChanged
		dotColor = Color.DarkGray
	End Sub

	Private Sub RadioButton3_CheckedChanged(sender As Object, e As EventArgs) Handles RadioButton3.CheckedChanged
		dotColor = Color.LightGray
	End Sub

	Private Sub CheckBox6_CheckedChanged(sender As Object, e As EventArgs) Handles CheckBox6.CheckedChanged
		Dim j As Integer
		aam = CheckBox6.Checked
		If aam Then
			gwidth = NumericUpDown2.Value * 2
		Else
			gwidth = NumericUpDown2.Value
		End If
		For j = 0 To modGlobals.nGlyphs() - 1
			If Not glyphs(j) Is Nothing Then
				glyphs(j).horizDots = gwidth
			End If
		Next
		Refresh()
	End Sub
End Class
