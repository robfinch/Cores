namespace FriscCoreGen
{
	partial class Form1
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.components = new System.ComponentModel.Container();
			this.groupBox1 = new System.Windows.Forms.GroupBox();
			this.radioButton2 = new System.Windows.Forms.RadioButton();
			this.radioButton1 = new System.Windows.Forms.RadioButton();
			this.groupBox2 = new System.Windows.Forms.GroupBox();
			this.radioButton6 = new System.Windows.Forms.RadioButton();
			this.radioButton5 = new System.Windows.Forms.RadioButton();
			this.radioButton4 = new System.Windows.Forms.RadioButton();
			this.radioButton3 = new System.Windows.Forms.RadioButton();
			this.Caching = new System.Windows.Forms.GroupBox();
			this.checkBox21 = new System.Windows.Forms.CheckBox();
			this.radioButton11 = new System.Windows.Forms.RadioButton();
			this.radioButton10 = new System.Windows.Forms.RadioButton();
			this.radioButton9 = new System.Windows.Forms.RadioButton();
			this.radioButton8 = new System.Windows.Forms.RadioButton();
			this.radioButton7 = new System.Windows.Forms.RadioButton();
			this.groupBox4 = new System.Windows.Forms.GroupBox();
			this.linkLabel2 = new System.Windows.Forms.LinkLabel();
			this.linkLabel1 = new System.Windows.Forms.LinkLabel();
			this.checkBox10 = new System.Windows.Forms.CheckBox();
			this.checkBox9 = new System.Windows.Forms.CheckBox();
			this.checkBox8 = new System.Windows.Forms.CheckBox();
			this.checkBox7 = new System.Windows.Forms.CheckBox();
			this.checkBox6 = new System.Windows.Forms.CheckBox();
			this.checkBox5 = new System.Windows.Forms.CheckBox();
			this.checkBox4 = new System.Windows.Forms.CheckBox();
			this.checkBox3 = new System.Windows.Forms.CheckBox();
			this.checkBox2 = new System.Windows.Forms.CheckBox();
			this.checkBox1 = new System.Windows.Forms.CheckBox();
			this.button1 = new System.Windows.Forms.Button();
			this.menuStrip1 = new System.Windows.Forms.MenuStrip();
			this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.saveConfigToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.checkBox22 = new System.Windows.Forms.CheckBox();
			this.toolTip1 = new System.Windows.Forms.ToolTip(this.components);
			this.linkLabel3 = new System.Windows.Forms.LinkLabel();
			this.groupBox5 = new System.Windows.Forms.GroupBox();
			this.comboBox1 = new System.Windows.Forms.ComboBox();
			this.checkBox13 = new System.Windows.Forms.CheckBox();
			this.checkBox12 = new System.Windows.Forms.CheckBox();
			this.checkBox11 = new System.Windows.Forms.CheckBox();
			this.checkBox24 = new System.Windows.Forms.CheckBox();
			this.checkBox25 = new System.Windows.Forms.CheckBox();
			this.progressBar1 = new System.Windows.Forms.ProgressBar();
			this.checkBox23 = new System.Windows.Forms.CheckBox();
			this.button2 = new System.Windows.Forms.Button();
			this.label1 = new System.Windows.Forms.Label();
			this.textBox1 = new System.Windows.Forms.TextBox();
			this.label2 = new System.Windows.Forms.Label();
			this.textBox2 = new System.Windows.Forms.TextBox();
			this.button3 = new System.Windows.Forms.Button();
			this.groupBox1.SuspendLayout();
			this.groupBox2.SuspendLayout();
			this.Caching.SuspendLayout();
			this.groupBox4.SuspendLayout();
			this.menuStrip1.SuspendLayout();
			this.groupBox5.SuspendLayout();
			this.SuspendLayout();
			// 
			// groupBox1
			// 
			this.groupBox1.Controls.Add(this.radioButton2);
			this.groupBox1.Controls.Add(this.radioButton1);
			this.groupBox1.Location = new System.Drawing.Point(12, 39);
			this.groupBox1.Name = "groupBox1";
			this.groupBox1.Size = new System.Drawing.Size(141, 52);
			this.groupBox1.TabIndex = 24;
			this.groupBox1.TabStop = false;
			this.groupBox1.Text = "Base Instruction Set";
			// 
			// radioButton2
			// 
			this.radioButton2.AutoSize = true;
			this.radioButton2.Checked = true;
			this.radioButton2.Location = new System.Drawing.Point(75, 22);
			this.radioButton2.Name = "radioButton2";
			this.radioButton2.Size = new System.Drawing.Size(55, 17);
			this.radioButton2.TabIndex = 13;
			this.radioButton2.TabStop = true;
			this.radioButton2.Text = "RV64I";
			this.radioButton2.UseVisualStyleBackColor = true;
			// 
			// radioButton1
			// 
			this.radioButton1.AutoSize = true;
			this.radioButton1.Location = new System.Drawing.Point(21, 22);
			this.radioButton1.Name = "radioButton1";
			this.radioButton1.Size = new System.Drawing.Size(55, 17);
			this.radioButton1.TabIndex = 12;
			this.radioButton1.Text = "RV32I";
			this.radioButton1.UseVisualStyleBackColor = true;
			// 
			// groupBox2
			// 
			this.groupBox2.Controls.Add(this.radioButton6);
			this.groupBox2.Controls.Add(this.radioButton5);
			this.groupBox2.Controls.Add(this.radioButton4);
			this.groupBox2.Controls.Add(this.radioButton3);
			this.groupBox2.Location = new System.Drawing.Point(250, 39);
			this.groupBox2.Name = "groupBox2";
			this.groupBox2.Size = new System.Drawing.Size(203, 122);
			this.groupBox2.TabIndex = 25;
			this.groupBox2.TabStop = false;
			this.groupBox2.Text = "Pipelining";
			// 
			// radioButton6
			// 
			this.radioButton6.AutoSize = true;
			this.radioButton6.Enabled = false;
			this.radioButton6.Location = new System.Drawing.Point(30, 94);
			this.radioButton6.Name = "radioButton6";
			this.radioButton6.Size = new System.Drawing.Size(121, 17);
			this.radioButton6.TabIndex = 20;
			this.radioButton6.Text = "Superscalar Pipeline";
			this.radioButton6.UseVisualStyleBackColor = true;
			// 
			// radioButton5
			// 
			this.radioButton5.AutoSize = true;
			this.radioButton5.Location = new System.Drawing.Point(31, 71);
			this.radioButton5.Name = "radioButton5";
			this.radioButton5.Size = new System.Drawing.Size(120, 17);
			this.radioButton5.TabIndex = 19;
			this.radioButton5.Text = "Overlapped Pipeline";
			this.radioButton5.UseVisualStyleBackColor = true;
			// 
			// radioButton4
			// 
			this.radioButton4.AutoSize = true;
			this.radioButton4.Checked = true;
			this.radioButton4.Location = new System.Drawing.Point(30, 47);
			this.radioButton4.Name = "radioButton4";
			this.radioButton4.Size = new System.Drawing.Size(141, 17);
			this.radioButton4.TabIndex = 18;
			this.radioButton4.TabStop = true;
			this.radioButton4.Text = "Non-overlapped Pipeline";
			this.radioButton4.UseVisualStyleBackColor = true;
			// 
			// radioButton3
			// 
			this.radioButton3.AutoSize = true;
			this.radioButton3.Enabled = false;
			this.radioButton3.Location = new System.Drawing.Point(30, 24);
			this.radioButton3.Name = "radioButton3";
			this.radioButton3.Size = new System.Drawing.Size(90, 17);
			this.radioButton3.TabIndex = 17;
			this.radioButton3.Text = "Non-pipelined";
			this.radioButton3.UseVisualStyleBackColor = true;
			// 
			// Caching
			// 
			this.Caching.Controls.Add(this.checkBox21);
			this.Caching.Controls.Add(this.radioButton11);
			this.Caching.Controls.Add(this.radioButton10);
			this.Caching.Controls.Add(this.radioButton9);
			this.Caching.Controls.Add(this.radioButton8);
			this.Caching.Controls.Add(this.radioButton7);
			this.Caching.Location = new System.Drawing.Point(480, 114);
			this.Caching.Name = "Caching";
			this.Caching.Size = new System.Drawing.Size(203, 181);
			this.Caching.TabIndex = 26;
			this.Caching.TabStop = false;
			this.Caching.Text = "Caching";
			// 
			// checkBox21
			// 
			this.checkBox21.AutoSize = true;
			this.checkBox21.Location = new System.Drawing.Point(33, 147);
			this.checkBox21.Name = "checkBox21";
			this.checkBox21.Size = new System.Drawing.Size(77, 17);
			this.checkBox21.TabIndex = 29;
			this.checkBox21.Text = "L2 Caches";
			this.checkBox21.UseVisualStyleBackColor = true;
			// 
			// radioButton11
			// 
			this.radioButton11.AutoSize = true;
			this.radioButton11.Checked = true;
			this.radioButton11.Location = new System.Drawing.Point(32, 24);
			this.radioButton11.Name = "radioButton11";
			this.radioButton11.Size = new System.Drawing.Size(78, 17);
			this.radioButton11.TabIndex = 27;
			this.radioButton11.TabStop = true;
			this.radioButton11.Text = "No Caches";
			this.toolTip1.SetToolTip(this.radioButton11, "Many smaller systems lack caches to simplfiy the system and reduce hardware requi" +
        "rements.");
			this.radioButton11.UseVisualStyleBackColor = true;
			this.radioButton11.CheckedChanged += new System.EventHandler(this.radioButton11_CheckedChanged);
			// 
			// radioButton10
			// 
			this.radioButton10.AutoSize = true;
			this.radioButton10.Location = new System.Drawing.Point(32, 116);
			this.radioButton10.Name = "radioButton10";
			this.radioButton10.Size = new System.Drawing.Size(72, 17);
			this.radioButton10.TabIndex = 26;
			this.radioButton10.Text = "Data Only";
			this.radioButton10.UseVisualStyleBackColor = true;
			// 
			// radioButton9
			// 
			this.radioButton9.AutoSize = true;
			this.radioButton9.Location = new System.Drawing.Point(32, 93);
			this.radioButton9.Name = "radioButton9";
			this.radioButton9.Size = new System.Drawing.Size(98, 17);
			this.radioButton9.TabIndex = 25;
			this.radioButton9.Text = "Instruction Only";
			this.toolTip1.SetToolTip(this.radioButton9, "Some systems are required to not have data caching so that in the event of a fail" +
        "ure the scope of the data loss is limited.");
			this.radioButton9.UseVisualStyleBackColor = true;
			// 
			// radioButton8
			// 
			this.radioButton8.AutoSize = true;
			this.radioButton8.Location = new System.Drawing.Point(32, 70);
			this.radioButton8.Name = "radioButton8";
			this.radioButton8.Size = new System.Drawing.Size(157, 17);
			this.radioButton8.TabIndex = 24;
			this.radioButton8.Text = "Unified Instruction and Data";
			this.radioButton8.UseVisualStyleBackColor = true;
			// 
			// radioButton7
			// 
			this.radioButton7.AutoSize = true;
			this.radioButton7.Location = new System.Drawing.Point(32, 47);
			this.radioButton7.Name = "radioButton7";
			this.radioButton7.Size = new System.Drawing.Size(146, 17);
			this.radioButton7.TabIndex = 23;
			this.radioButton7.Text = "Both Instruction and Data";
			this.toolTip1.SetToolTip(this.radioButton7, "Having separate instruction and data caches can improve performance by allowing d" +
        "ata ot be accessed at the same time as an instruction.");
			this.radioButton7.UseVisualStyleBackColor = true;
			// 
			// groupBox4
			// 
			this.groupBox4.Controls.Add(this.linkLabel2);
			this.groupBox4.Controls.Add(this.linkLabel1);
			this.groupBox4.Controls.Add(this.checkBox10);
			this.groupBox4.Controls.Add(this.checkBox9);
			this.groupBox4.Controls.Add(this.checkBox8);
			this.groupBox4.Controls.Add(this.checkBox7);
			this.groupBox4.Controls.Add(this.checkBox6);
			this.groupBox4.Controls.Add(this.checkBox5);
			this.groupBox4.Controls.Add(this.checkBox4);
			this.groupBox4.Controls.Add(this.checkBox3);
			this.groupBox4.Controls.Add(this.checkBox2);
			this.groupBox4.Controls.Add(this.checkBox1);
			this.groupBox4.Location = new System.Drawing.Point(12, 135);
			this.groupBox4.Name = "groupBox4";
			this.groupBox4.Size = new System.Drawing.Size(232, 254);
			this.groupBox4.TabIndex = 38;
			this.groupBox4.TabStop = false;
			this.groupBox4.Text = "Instruction Set Extensions";
			// 
			// linkLabel2
			// 
			this.linkLabel2.AutoSize = true;
			this.linkLabel2.Enabled = false;
			this.linkLabel2.Location = new System.Drawing.Point(144, 158);
			this.linkLabel2.Name = "linkLabel2";
			this.linkLabel2.Size = new System.Drawing.Size(16, 13);
			this.linkLabel2.TabIndex = 21;
			this.linkLabel2.TabStop = true;
			this.linkLabel2.Text = "...";
			this.linkLabel2.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel2_LinkClicked);
			// 
			// linkLabel1
			// 
			this.linkLabel1.AutoSize = true;
			this.linkLabel1.Enabled = false;
			this.linkLabel1.Location = new System.Drawing.Point(197, 111);
			this.linkLabel1.Name = "linkLabel1";
			this.linkLabel1.Size = new System.Drawing.Size(16, 13);
			this.linkLabel1.TabIndex = 20;
			this.linkLabel1.TabStop = true;
			this.linkLabel1.Text = "...";
			this.linkLabel1.Click += new System.EventHandler(this.linkLabel1_Click);
			// 
			// checkBox10
			// 
			this.checkBox10.AutoSize = true;
			this.checkBox10.Enabled = false;
			this.checkBox10.Location = new System.Drawing.Point(24, 180);
			this.checkBox10.Name = "checkBox10";
			this.checkBox10.Size = new System.Drawing.Size(109, 17);
			this.checkBox10.TabIndex = 19;
			this.checkBox10.Text = "P - Packed SIMD";
			this.checkBox10.UseVisualStyleBackColor = true;
			// 
			// checkBox9
			// 
			this.checkBox9.AutoSize = true;
			this.checkBox9.Enabled = false;
			this.checkBox9.Location = new System.Drawing.Point(24, 226);
			this.checkBox9.Name = "checkBox9";
			this.checkBox9.Size = new System.Drawing.Size(141, 17);
			this.checkBox9.TabIndex = 18;
			this.checkBox9.Text = "T - transactional memory";
			this.checkBox9.UseVisualStyleBackColor = true;
			// 
			// checkBox8
			// 
			this.checkBox8.AutoSize = true;
			this.checkBox8.Enabled = false;
			this.checkBox8.Location = new System.Drawing.Point(24, 42);
			this.checkBox8.Name = "checkBox8";
			this.checkBox8.Size = new System.Drawing.Size(135, 17);
			this.checkBox8.TabIndex = 17;
			this.checkBox8.Text = "B - bit manipulation ops";
			this.checkBox8.UseVisualStyleBackColor = true;
			// 
			// checkBox7
			// 
			this.checkBox7.AutoSize = true;
			this.checkBox7.Location = new System.Drawing.Point(24, 65);
			this.checkBox7.Name = "checkBox7";
			this.checkBox7.Size = new System.Drawing.Size(155, 17);
			this.checkBox7.TabIndex = 16;
			this.checkBox7.Text = "C - compressed instructions";
			this.checkBox7.UseVisualStyleBackColor = true;
			// 
			// checkBox6
			// 
			this.checkBox6.AutoSize = true;
			this.checkBox6.Enabled = false;
			this.checkBox6.Location = new System.Drawing.Point(24, 134);
			this.checkBox6.Name = "checkBox6";
			this.checkBox6.Size = new System.Drawing.Size(140, 17);
			this.checkBox6.TabIndex = 15;
			this.checkBox6.Text = "L - decimal floating point";
			this.checkBox6.UseVisualStyleBackColor = true;
			// 
			// checkBox5
			// 
			this.checkBox5.AutoSize = true;
			this.checkBox5.Enabled = false;
			this.checkBox5.Location = new System.Drawing.Point(24, 203);
			this.checkBox5.Name = "checkBox5";
			this.checkBox5.Size = new System.Drawing.Size(175, 17);
			this.checkBox5.TabIndex = 14;
			this.checkBox5.Text = "Q - quad precision floating point";
			this.checkBox5.UseVisualStyleBackColor = true;
			// 
			// checkBox4
			// 
			this.checkBox4.AutoSize = true;
			this.checkBox4.Checked = true;
			this.checkBox4.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox4.Location = new System.Drawing.Point(24, 157);
			this.checkBox4.Name = "checkBox4";
			this.checkBox4.Size = new System.Drawing.Size(120, 17);
			this.checkBox4.TabIndex = 13;
			this.checkBox4.Text = "M - Multiply / Divide";
			this.checkBox4.UseVisualStyleBackColor = true;
			this.checkBox4.CheckedChanged += new System.EventHandler(this.checkBox4_CheckedChanged);
			// 
			// checkBox3
			// 
			this.checkBox3.AutoSize = true;
			this.checkBox3.Location = new System.Drawing.Point(24, 88);
			this.checkBox3.Name = "checkBox3";
			this.checkBox3.Size = new System.Drawing.Size(183, 17);
			this.checkBox3.TabIndex = 12;
			this.checkBox3.Text = "D - double precision floating point";
			this.checkBox3.UseVisualStyleBackColor = true;
			// 
			// checkBox2
			// 
			this.checkBox2.AutoSize = true;
			this.checkBox2.Checked = true;
			this.checkBox2.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox2.Location = new System.Drawing.Point(24, 111);
			this.checkBox2.Name = "checkBox2";
			this.checkBox2.Size = new System.Drawing.Size(176, 17);
			this.checkBox2.TabIndex = 11;
			this.checkBox2.Text = "F - single precision floating point";
			this.checkBox2.UseVisualStyleBackColor = true;
			this.checkBox2.CheckedChanged += new System.EventHandler(this.checkBox2_CheckedChanged);
			// 
			// checkBox1
			// 
			this.checkBox1.AutoSize = true;
			this.checkBox1.Location = new System.Drawing.Point(24, 19);
			this.checkBox1.Name = "checkBox1";
			this.checkBox1.Size = new System.Drawing.Size(132, 17);
			this.checkBox1.TabIndex = 10;
			this.checkBox1.Text = "A - atomic memory ops";
			this.checkBox1.UseVisualStyleBackColor = true;
			// 
			// button1
			// 
			this.button1.Location = new System.Drawing.Point(616, 407);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(75, 23);
			this.button1.TabIndex = 39;
			this.button1.Text = "Generate";
			this.button1.UseVisualStyleBackColor = true;
			this.button1.Click += new System.EventHandler(this.button1_Click);
			// 
			// menuStrip1
			// 
			this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem});
			this.menuStrip1.Location = new System.Drawing.Point(0, 0);
			this.menuStrip1.Name = "menuStrip1";
			this.menuStrip1.Size = new System.Drawing.Size(703, 24);
			this.menuStrip1.TabIndex = 40;
			this.menuStrip1.Text = "menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.saveConfigToolStripMenuItem});
			this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
			this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
			this.fileToolStripMenuItem.Text = "&File";
			// 
			// saveConfigToolStripMenuItem
			// 
			this.saveConfigToolStripMenuItem.Name = "saveConfigToolStripMenuItem";
			this.saveConfigToolStripMenuItem.Size = new System.Drawing.Size(137, 22);
			this.saveConfigToolStripMenuItem.Text = "Save Config";
			// 
			// checkBox22
			// 
			this.checkBox22.AutoSize = true;
			this.checkBox22.Checked = true;
			this.checkBox22.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox22.Location = new System.Drawing.Point(489, 330);
			this.checkBox22.Name = "checkBox22";
			this.checkBox22.Size = new System.Drawing.Size(123, 17);
			this.checkBox22.TabIndex = 41;
			this.checkBox22.Text = "Unaligned Accesses";
			this.toolTip1.SetToolTip(this.checkBox22, "Unaligned accesses generates code which runs two bus cycles if an access is unali" +
        "gned.");
			this.checkBox22.UseVisualStyleBackColor = true;
			// 
			// linkLabel3
			// 
			this.linkLabel3.AutoSize = true;
			this.linkLabel3.Location = new System.Drawing.Point(10, 114);
			this.linkLabel3.Name = "linkLabel3";
			this.linkLabel3.Size = new System.Drawing.Size(135, 13);
			this.linkLabel3.TabIndex = 42;
			this.linkLabel3.TabStop = true;
			this.linkLabel3.Text = "Machine Mode Instructions";
			this.linkLabel3.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel3_LinkClicked);
			// 
			// groupBox5
			// 
			this.groupBox5.Controls.Add(this.comboBox1);
			this.groupBox5.Controls.Add(this.checkBox13);
			this.groupBox5.Controls.Add(this.checkBox12);
			this.groupBox5.Controls.Add(this.checkBox11);
			this.groupBox5.Location = new System.Drawing.Point(250, 170);
			this.groupBox5.Name = "groupBox5";
			this.groupBox5.Size = new System.Drawing.Size(200, 108);
			this.groupBox5.TabIndex = 43;
			this.groupBox5.TabStop = false;
			this.groupBox5.Text = "Bus Standard";
			// 
			// comboBox1
			// 
			this.comboBox1.FormattingEnabled = true;
			this.comboBox1.Location = new System.Drawing.Point(110, 28);
			this.comboBox1.Name = "comboBox1";
			this.comboBox1.Size = new System.Drawing.Size(84, 21);
			this.comboBox1.TabIndex = 6;
			this.comboBox1.Text = "1";
			// 
			// checkBox13
			// 
			this.checkBox13.AutoSize = true;
			this.checkBox13.Location = new System.Drawing.Point(19, 76);
			this.checkBox13.Name = "checkBox13";
			this.checkBox13.Size = new System.Drawing.Size(51, 17);
			this.checkBox13.TabIndex = 5;
			this.checkBox13.Text = "S100";
			this.checkBox13.UseVisualStyleBackColor = true;
			// 
			// checkBox12
			// 
			this.checkBox12.AutoSize = true;
			this.checkBox12.Location = new System.Drawing.Point(19, 53);
			this.checkBox12.Name = "checkBox12";
			this.checkBox12.Size = new System.Drawing.Size(84, 17);
			this.checkBox12.TabIndex = 4;
			this.checkBox12.Text = "AMBA / AXI";
			this.checkBox12.UseVisualStyleBackColor = true;
			// 
			// checkBox11
			// 
			this.checkBox11.AutoSize = true;
			this.checkBox11.Checked = true;
			this.checkBox11.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox11.Location = new System.Drawing.Point(19, 30);
			this.checkBox11.Name = "checkBox11";
			this.checkBox11.Size = new System.Drawing.Size(85, 17);
			this.checkBox11.TabIndex = 3;
			this.checkBox11.Text = "WISHBONE";
			this.checkBox11.UseVisualStyleBackColor = true;
			// 
			// checkBox24
			// 
			this.checkBox24.AutoSize = true;
			this.checkBox24.Checked = true;
			this.checkBox24.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox24.Location = new System.Drawing.Point(489, 353);
			this.checkBox24.Name = "checkBox24";
			this.checkBox24.Size = new System.Drawing.Size(194, 17);
			this.checkBox24.TabIndex = 44;
			this.checkBox24.Text = "Check for load / store access faults";
			this.checkBox24.UseVisualStyleBackColor = true;
			this.checkBox24.CheckedChanged += new System.EventHandler(this.checkBox24_CheckedChanged);
			// 
			// checkBox25
			// 
			this.checkBox25.AutoSize = true;
			this.checkBox25.Checked = true;
			this.checkBox25.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox25.Location = new System.Drawing.Point(489, 376);
			this.checkBox25.Name = "checkBox25";
			this.checkBox25.Size = new System.Drawing.Size(188, 17);
			this.checkBox25.TabIndex = 45;
			this.checkBox25.Text = "Check for instruction access faults";
			this.checkBox25.UseVisualStyleBackColor = true;
			// 
			// progressBar1
			// 
			this.progressBar1.Location = new System.Drawing.Point(36, 451);
			this.progressBar1.Name = "progressBar1";
			this.progressBar1.Size = new System.Drawing.Size(576, 23);
			this.progressBar1.Step = 1;
			this.progressBar1.TabIndex = 46;
			// 
			// checkBox23
			// 
			this.checkBox23.AutoSize = true;
			this.checkBox23.Checked = true;
			this.checkBox23.CheckState = System.Windows.Forms.CheckState.Checked;
			this.checkBox23.Location = new System.Drawing.Point(489, 74);
			this.checkBox23.Name = "checkBox23";
			this.checkBox23.Size = new System.Drawing.Size(66, 17);
			this.checkBox23.TabIndex = 48;
			this.checkBox23.Text = "SSMMU";
			this.checkBox23.UseVisualStyleBackColor = true;
			this.checkBox23.CheckedChanged += new System.EventHandler(this.checkBox23_CheckedChanged);
			// 
			// button2
			// 
			this.button2.Location = new System.Drawing.Point(489, 39);
			this.button2.Name = "button2";
			this.button2.Size = new System.Drawing.Size(123, 23);
			this.button2.TabIndex = 49;
			this.button2.Text = "Memory Management";
			this.button2.UseVisualStyleBackColor = true;
			this.button2.Click += new System.EventHandler(this.button2_Click_1);
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(266, 293);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(76, 13);
			this.label1.TabIndex = 50;
			this.label1.Text = "Reset Address";
			// 
			// textBox1
			// 
			this.textBox1.Location = new System.Drawing.Point(353, 289);
			this.textBox1.Name = "textBox1";
			this.textBox1.Size = new System.Drawing.Size(100, 20);
			this.textBox1.TabIndex = 51;
			this.textBox1.Tag = "ResetAddress";
			this.textBox1.Text = "32\'hFFFC0100";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(266, 315);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(63, 13);
			this.label2.TabIndex = 52;
			this.label2.Text = "Trap Vector";
			// 
			// textBox2
			// 
			this.textBox2.Location = new System.Drawing.Point(353, 312);
			this.textBox2.Name = "textBox2";
			this.textBox2.Size = new System.Drawing.Size(100, 20);
			this.textBox2.TabIndex = 53;
			this.textBox2.Tag = "MTVEC";
			this.textBox2.Text = "32\'hFFFC0000";
			// 
			// button3
			// 
			this.button3.Location = new System.Drawing.Point(489, 97);
			this.button3.Name = "button3";
			this.button3.Size = new System.Drawing.Size(123, 23);
			this.button3.TabIndex = 54;
			this.button3.Text = "ICache";
			this.button3.UseVisualStyleBackColor = true;
			this.button3.Click += new System.EventHandler(this.button3_Click);
			// 
			// Form1
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(703, 477);
			this.Controls.Add(this.button3);
			this.Controls.Add(this.textBox2);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.button2);
			this.Controls.Add(this.checkBox23);
			this.Controls.Add(this.progressBar1);
			this.Controls.Add(this.checkBox25);
			this.Controls.Add(this.checkBox24);
			this.Controls.Add(this.groupBox5);
			this.Controls.Add(this.linkLabel3);
			this.Controls.Add(this.checkBox22);
			this.Controls.Add(this.button1);
			this.Controls.Add(this.groupBox4);
			this.Controls.Add(this.Caching);
			this.Controls.Add(this.groupBox2);
			this.Controls.Add(this.groupBox1);
			this.Controls.Add(this.menuStrip1);
			this.MainMenuStrip = this.menuStrip1;
			this.Name = "Form1";
			this.Text = "FRISCV - Main Config";
			this.groupBox1.ResumeLayout(false);
			this.groupBox1.PerformLayout();
			this.groupBox2.ResumeLayout(false);
			this.groupBox2.PerformLayout();
			this.Caching.ResumeLayout(false);
			this.Caching.PerformLayout();
			this.groupBox4.ResumeLayout(false);
			this.groupBox4.PerformLayout();
			this.menuStrip1.ResumeLayout(false);
			this.menuStrip1.PerformLayout();
			this.groupBox5.ResumeLayout(false);
			this.groupBox5.PerformLayout();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.RadioButton radioButton2;
		private System.Windows.Forms.RadioButton radioButton1;
		private System.Windows.Forms.GroupBox groupBox2;
		private System.Windows.Forms.RadioButton radioButton6;
		private System.Windows.Forms.RadioButton radioButton5;
		private System.Windows.Forms.RadioButton radioButton4;
		private System.Windows.Forms.RadioButton radioButton3;
		private System.Windows.Forms.GroupBox Caching;
		private System.Windows.Forms.RadioButton radioButton11;
		private System.Windows.Forms.RadioButton radioButton10;
		private System.Windows.Forms.RadioButton radioButton9;
		private System.Windows.Forms.RadioButton radioButton8;
		private System.Windows.Forms.RadioButton radioButton7;
		private System.Windows.Forms.GroupBox groupBox4;
		private System.Windows.Forms.CheckBox checkBox10;
		private System.Windows.Forms.CheckBox checkBox9;
		private System.Windows.Forms.CheckBox checkBox8;
		private System.Windows.Forms.CheckBox checkBox7;
		private System.Windows.Forms.CheckBox checkBox6;
		private System.Windows.Forms.CheckBox checkBox5;
		private System.Windows.Forms.CheckBox checkBox4;
		private System.Windows.Forms.CheckBox checkBox3;
		private System.Windows.Forms.CheckBox checkBox2;
		private System.Windows.Forms.CheckBox checkBox1;
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.CheckBox checkBox21;
		private System.Windows.Forms.MenuStrip menuStrip1;
		private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
		private System.Windows.Forms.ToolStripMenuItem saveConfigToolStripMenuItem;
		private System.Windows.Forms.CheckBox checkBox22;
		private System.Windows.Forms.ToolTip toolTip1;
		private System.Windows.Forms.LinkLabel linkLabel1;
		private System.Windows.Forms.LinkLabel linkLabel2;
		private System.Windows.Forms.LinkLabel linkLabel3;
		private System.Windows.Forms.GroupBox groupBox5;
		private System.Windows.Forms.CheckBox checkBox24;
		private System.Windows.Forms.CheckBox checkBox25;
		private System.Windows.Forms.ProgressBar progressBar1;
		private System.Windows.Forms.CheckBox checkBox23;
		private System.Windows.Forms.Button button2;
		private System.Windows.Forms.CheckBox checkBox13;
		private System.Windows.Forms.CheckBox checkBox12;
		private System.Windows.Forms.CheckBox checkBox11;
		private System.Windows.Forms.ComboBox comboBox1;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.TextBox textBox2;
		private System.Windows.Forms.Button button3;
	}
}

