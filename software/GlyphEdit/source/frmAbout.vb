Public Class frmAbout
    Inherits System.Windows.Forms.Form

#Region " Windows Form Designer generated code "

    Public Sub New()
        MyBase.New()

        'This call is required by the Windows Form Designer.
        InitializeComponent()

        'Add any initialization after the InitializeComponent() call

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
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents Button1 As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
		Me.Label1 = New System.Windows.Forms.Label()
		Me.Label2 = New System.Windows.Forms.Label()
		Me.Label3 = New System.Windows.Forms.Label()
		Me.Button1 = New System.Windows.Forms.Button()
		Me.SuspendLayout()
		'
		'Label1
		'
		Me.Label1.Location = New System.Drawing.Point(20, 14)
		Me.Label1.Name = "Label1"
		Me.Label1.Size = New System.Drawing.Size(100, 28)
		Me.Label1.TabIndex = 0
		Me.Label1.Text = "Text Glyph editor"
		'
		'Label2
		'
		Me.Label2.Location = New System.Drawing.Point(40, 42)
		Me.Label2.Name = "Label2"
		Me.Label2.Size = New System.Drawing.Size(313, 41)
		Me.Label2.TabIndex = 1
		Me.Label2.Text = "Allows editing of text glyphs stored in a UCF constraints file format." & Global.Microsoft.VisualBasic.ChrW(13) & Global.Microsoft.VisualBasic.ChrW(10) & "Formats s" &
		"upported: .mem, .coe, .ucf, .bmp, .jpg, .png, .bin"
		'
		'Label3
		'
		Me.Label3.Location = New System.Drawing.Point(40, 135)
		Me.Label3.Name = "Label3"
		Me.Label3.Size = New System.Drawing.Size(127, 20)
		Me.Label3.TabIndex = 2
		Me.Label3.Text = "2011-2022  Robert Finch"
		'
		'Button1
		'
		Me.Button1.Location = New System.Drawing.Point(199, 124)
		Me.Button1.Name = "Button1"
		Me.Button1.Size = New System.Drawing.Size(100, 35)
		Me.Button1.TabIndex = 3
		Me.Button1.Text = "Ok"
		'
		'frmAbout
		'
		Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
		Me.ClientSize = New System.Drawing.Size(438, 171)
		Me.Controls.Add(Me.Button1)
		Me.Controls.Add(Me.Label3)
		Me.Controls.Add(Me.Label2)
		Me.Controls.Add(Me.Label1)
		Me.Name = "frmAbout"
		Me.Text = "About"
		Me.ResumeLayout(False)

	End Sub

#End Region

	Private Sub Button1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button1.Click
		Me.Close()
	End Sub

	Private Sub Label2_Click(sender As Object, e As EventArgs) Handles Label2.Click

	End Sub
End Class
