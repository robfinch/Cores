namespace FriscCoreGen
{
	partial class frmCache
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
			this.groupBox2 = new System.Windows.Forms.GroupBox();
			this.label9 = new System.Windows.Forms.Label();
			this.groupBox1 = new System.Windows.Forms.GroupBox();
			this.comboBox4 = new System.Windows.Forms.ComboBox();
			this.label5 = new System.Windows.Forms.Label();
			this.radioButton2 = new System.Windows.Forms.RadioButton();
			this.radioButton1 = new System.Windows.Forms.RadioButton();
			this.label3 = new System.Windows.Forms.Label();
			this.comboBox3 = new System.Windows.Forms.ComboBox();
			this.label2 = new System.Windows.Forms.Label();
			this.comboBox2 = new System.Windows.Forms.ComboBox();
			this.comboBox1 = new System.Windows.Forms.ComboBox();
			this.label1 = new System.Windows.Forms.Label();
			this.groupBox3 = new System.Windows.Forms.GroupBox();
			this.label10 = new System.Windows.Forms.Label();
			this.comboBox8 = new System.Windows.Forms.ComboBox();
			this.label8 = new System.Windows.Forms.Label();
			this.comboBox7 = new System.Windows.Forms.ComboBox();
			this.label7 = new System.Windows.Forms.Label();
			this.comboBox6 = new System.Windows.Forms.ComboBox();
			this.label6 = new System.Windows.Forms.Label();
			this.comboBox5 = new System.Windows.Forms.ComboBox();
			this.label4 = new System.Windows.Forms.Label();
			this.button1 = new System.Windows.Forms.Button();
			this.button2 = new System.Windows.Forms.Button();
			this.button3 = new System.Windows.Forms.Button();
			this.groupBox4 = new System.Windows.Forms.GroupBox();
			this.radioButton3 = new System.Windows.Forms.RadioButton();
			this.radioButton4 = new System.Windows.Forms.RadioButton();
			this.groupBox5 = new System.Windows.Forms.GroupBox();
			this.radioButton5 = new System.Windows.Forms.RadioButton();
			this.radioButton6 = new System.Windows.Forms.RadioButton();
			this.radioButton7 = new System.Windows.Forms.RadioButton();
			this.label11 = new System.Windows.Forms.Label();
			this.numericUpDown1 = new System.Windows.Forms.NumericUpDown();
			this.textBox1 = new System.Windows.Forms.TextBox();
			this.numericUpDown2 = new System.Windows.Forms.NumericUpDown();
			this.label12 = new System.Windows.Forms.Label();
			this.groupBox2.SuspendLayout();
			this.groupBox1.SuspendLayout();
			this.groupBox3.SuspendLayout();
			this.groupBox4.SuspendLayout();
			this.groupBox5.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).BeginInit();
			this.SuspendLayout();
			// 
			// groupBox2
			// 
			this.groupBox2.Controls.Add(this.groupBox4);
			this.groupBox2.Controls.Add(this.label9);
			this.groupBox2.Controls.Add(this.groupBox1);
			this.groupBox2.Controls.Add(this.label3);
			this.groupBox2.Controls.Add(this.comboBox3);
			this.groupBox2.Controls.Add(this.label2);
			this.groupBox2.Controls.Add(this.comboBox2);
			this.groupBox2.Controls.Add(this.comboBox1);
			this.groupBox2.Controls.Add(this.label1);
			this.groupBox2.Location = new System.Drawing.Point(12, 104);
			this.groupBox2.Name = "groupBox2";
			this.groupBox2.Size = new System.Drawing.Size(239, 337);
			this.groupBox2.TabIndex = 12;
			this.groupBox2.TabStop = false;
			this.groupBox2.Text = "L1 Instruction Cache";
			// 
			// label9
			// 
			this.label9.AutoSize = true;
			this.label9.Location = new System.Drawing.Point(173, 26);
			this.label9.Name = "label9";
			this.label9.Size = new System.Drawing.Size(32, 13);
			this.label9.TabIndex = 19;
			this.label9.Text = "bytes";
			// 
			// groupBox1
			// 
			this.groupBox1.Controls.Add(this.comboBox4);
			this.groupBox1.Controls.Add(this.label5);
			this.groupBox1.Controls.Add(this.radioButton2);
			this.groupBox1.Controls.Add(this.radioButton1);
			this.groupBox1.Location = new System.Drawing.Point(16, 114);
			this.groupBox1.Name = "groupBox1";
			this.groupBox1.Size = new System.Drawing.Size(208, 100);
			this.groupBox1.TabIndex = 18;
			this.groupBox1.TabStop = false;
			this.groupBox1.Text = "Cache Load Port";
			// 
			// comboBox4
			// 
			this.comboBox4.FormattingEnabled = true;
			this.comboBox4.Items.AddRange(new object[] {
            "4",
            "8",
            "2",
            "1",
            "16"});
			this.comboBox4.Location = new System.Drawing.Point(116, 59);
			this.comboBox4.Name = "comboBox4";
			this.comboBox4.Size = new System.Drawing.Size(55, 21);
			this.comboBox4.TabIndex = 12;
			this.comboBox4.Tag = "L1IMemoryPortWidth";
			this.comboBox4.Text = "8";
			// 
			// label5
			// 
			this.label5.AutoSize = true;
			this.label5.Location = new System.Drawing.Point(17, 62);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(93, 13);
			this.label5.TabIndex = 11;
			this.label5.Text = "Memory port width";
			// 
			// radioButton2
			// 
			this.radioButton2.AutoSize = true;
			this.radioButton2.Checked = true;
			this.radioButton2.Location = new System.Drawing.Point(27, 42);
			this.radioButton2.Name = "radioButton2";
			this.radioButton2.Size = new System.Drawing.Size(107, 17);
			this.radioButton2.TabIndex = 9;
			this.radioButton2.TabStop = true;
			this.radioButton2.Tag = "L1ILoadFromMemory";
			this.radioButton2.Text = "load from memory";
			this.radioButton2.UseVisualStyleBackColor = true;
			// 
			// radioButton1
			// 
			this.radioButton1.AutoSize = true;
			this.radioButton1.Location = new System.Drawing.Point(27, 19);
			this.radioButton1.Name = "radioButton1";
			this.radioButton1.Size = new System.Drawing.Size(83, 17);
			this.radioButton1.TabIndex = 8;
			this.radioButton1.Tag = "L1ILoadFromL2";
			this.radioButton1.Text = "load from L2";
			this.radioButton1.UseVisualStyleBackColor = true;
			// 
			// label3
			// 
			this.label3.AutoSize = true;
			this.label3.Location = new System.Drawing.Point(21, 83);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(90, 13);
			this.label3.TabIndex = 17;
			this.label3.Text = "Ways associative";
			// 
			// comboBox3
			// 
			this.comboBox3.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.comboBox3.FormattingEnabled = true;
			this.comboBox3.Items.AddRange(new object[] {
            "4",
            "8",
            "2",
            "1",
            "16",
            "32"});
			this.comboBox3.Location = new System.Drawing.Point(111, 80);
			this.comboBox3.Name = "comboBox3";
			this.comboBox3.Size = new System.Drawing.Size(56, 21);
			this.comboBox3.TabIndex = 16;
			this.comboBox3.Tag = "L1IAssociativity";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(21, 53);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(80, 13);
			this.label2.TabIndex = 15;
			this.label2.Text = "Number of lines";
			// 
			// comboBox2
			// 
			this.comboBox2.FormatString = "N0";
			this.comboBox2.FormattingEnabled = true;
			this.comboBox2.Items.AddRange(new object[] {
            "64",
            "256",
            "128",
            "32",
            "16"});
			this.comboBox2.Location = new System.Drawing.Point(111, 50);
			this.comboBox2.Name = "comboBox2";
			this.comboBox2.Size = new System.Drawing.Size(56, 21);
			this.comboBox2.TabIndex = 14;
			this.comboBox2.Tag = "L1INumberOfLines";
			this.comboBox2.Text = "64";
			// 
			// comboBox1
			// 
			this.comboBox1.FormatString = "N0";
			this.comboBox1.FormattingEnabled = true;
			this.comboBox1.Items.AddRange(new object[] {
            "64",
            "32",
            "16",
            "128",
            "8"});
			this.comboBox1.Location = new System.Drawing.Point(111, 23);
			this.comboBox1.Name = "comboBox1";
			this.comboBox1.Size = new System.Drawing.Size(56, 21);
			this.comboBox1.TabIndex = 13;
			this.comboBox1.Tag = "L1ILineSize";
			this.comboBox1.Text = "64";
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(21, 26);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(84, 13);
			this.label1.TabIndex = 12;
			this.label1.Text = "Cache Line Size";
			// 
			// groupBox3
			// 
			this.groupBox3.Controls.Add(this.label10);
			this.groupBox3.Controls.Add(this.comboBox8);
			this.groupBox3.Controls.Add(this.label8);
			this.groupBox3.Controls.Add(this.comboBox7);
			this.groupBox3.Controls.Add(this.label7);
			this.groupBox3.Controls.Add(this.comboBox6);
			this.groupBox3.Controls.Add(this.label6);
			this.groupBox3.Controls.Add(this.comboBox5);
			this.groupBox3.Controls.Add(this.label4);
			this.groupBox3.Location = new System.Drawing.Point(281, 104);
			this.groupBox3.Name = "groupBox3";
			this.groupBox3.Size = new System.Drawing.Size(239, 147);
			this.groupBox3.TabIndex = 13;
			this.groupBox3.TabStop = false;
			this.groupBox3.Text = "L2 Instruction Cache";
			// 
			// label10
			// 
			this.label10.AutoSize = true;
			this.label10.Location = new System.Drawing.Point(169, 30);
			this.label10.Name = "label10";
			this.label10.Size = new System.Drawing.Size(32, 13);
			this.label10.TabIndex = 25;
			this.label10.Text = "bytes";
			// 
			// comboBox8
			// 
			this.comboBox8.FormattingEnabled = true;
			this.comboBox8.Items.AddRange(new object[] {
            "128",
            "32",
            "16",
            "8"});
			this.comboBox8.Location = new System.Drawing.Point(107, 111);
			this.comboBox8.Name = "comboBox8";
			this.comboBox8.Size = new System.Drawing.Size(55, 21);
			this.comboBox8.TabIndex = 24;
			this.comboBox8.Text = "64";
			// 
			// label8
			// 
			this.label8.AutoSize = true;
			this.label8.Location = new System.Drawing.Point(11, 114);
			this.label8.Name = "label8";
			this.label8.Size = new System.Drawing.Size(93, 13);
			this.label8.TabIndex = 23;
			this.label8.Text = "Memory port width";
			// 
			// comboBox7
			// 
			this.comboBox7.FormattingEnabled = true;
			this.comboBox7.Items.AddRange(new object[] {
            "4",
            "8",
            "2",
            "1"});
			this.comboBox7.Location = new System.Drawing.Point(107, 81);
			this.comboBox7.Name = "comboBox7";
			this.comboBox7.Size = new System.Drawing.Size(56, 21);
			this.comboBox7.TabIndex = 22;
			this.comboBox7.Text = "4";
			// 
			// label7
			// 
			this.label7.AutoSize = true;
			this.label7.Location = new System.Drawing.Point(11, 84);
			this.label7.Name = "label7";
			this.label7.Size = new System.Drawing.Size(90, 13);
			this.label7.TabIndex = 21;
			this.label7.Text = "Ways associative";
			// 
			// comboBox6
			// 
			this.comboBox6.FormatString = "N0";
			this.comboBox6.FormattingEnabled = true;
			this.comboBox6.Items.AddRange(new object[] {
            "512",
            "256",
            "128",
            "64",
            "32",
            "16"});
			this.comboBox6.Location = new System.Drawing.Point(107, 54);
			this.comboBox6.Name = "comboBox6";
			this.comboBox6.Size = new System.Drawing.Size(56, 21);
			this.comboBox6.TabIndex = 20;
			this.comboBox6.Text = "512";
			// 
			// label6
			// 
			this.label6.AutoSize = true;
			this.label6.Location = new System.Drawing.Point(17, 57);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(80, 13);
			this.label6.TabIndex = 19;
			this.label6.Text = "Number of lines";
			// 
			// comboBox5
			// 
			this.comboBox5.FormatString = "N0";
			this.comboBox5.FormattingEnabled = true;
			this.comboBox5.Items.AddRange(new object[] {
            "64",
            "32",
            "16",
            "128",
            "8"});
			this.comboBox5.Location = new System.Drawing.Point(107, 27);
			this.comboBox5.Name = "comboBox5";
			this.comboBox5.Size = new System.Drawing.Size(56, 21);
			this.comboBox5.TabIndex = 19;
			this.comboBox5.Text = "64";
			// 
			// label4
			// 
			this.label4.AutoSize = true;
			this.label4.Location = new System.Drawing.Point(17, 30);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(84, 13);
			this.label4.TabIndex = 13;
			this.label4.Text = "Cache Line Size";
			// 
			// button1
			// 
			this.button1.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.button1.Location = new System.Drawing.Point(352, 447);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(75, 23);
			this.button1.TabIndex = 14;
			this.button1.Text = "Cancel";
			this.button1.UseVisualStyleBackColor = true;
			// 
			// button2
			// 
			this.button2.DialogResult = System.Windows.Forms.DialogResult.OK;
			this.button2.Location = new System.Drawing.Point(445, 447);
			this.button2.Name = "button2";
			this.button2.Size = new System.Drawing.Size(75, 23);
			this.button2.TabIndex = 15;
			this.button2.Text = "OK";
			this.button2.UseVisualStyleBackColor = true;
			// 
			// button3
			// 
			this.button3.Location = new System.Drawing.Point(250, 447);
			this.button3.Name = "button3";
			this.button3.Size = new System.Drawing.Size(75, 23);
			this.button3.TabIndex = 16;
			this.button3.Text = "Generate";
			this.button3.UseVisualStyleBackColor = true;
			this.button3.Click += new System.EventHandler(this.button3_Click);
			// 
			// groupBox4
			// 
			this.groupBox4.Controls.Add(this.label12);
			this.groupBox4.Controls.Add(this.numericUpDown2);
			this.groupBox4.Controls.Add(this.radioButton4);
			this.groupBox4.Controls.Add(this.radioButton3);
			this.groupBox4.Location = new System.Drawing.Point(16, 220);
			this.groupBox4.Name = "groupBox4";
			this.groupBox4.Size = new System.Drawing.Size(208, 90);
			this.groupBox4.TabIndex = 20;
			this.groupBox4.TabStop = false;
			this.groupBox4.Text = "Output";
			// 
			// radioButton3
			// 
			this.radioButton3.AutoSize = true;
			this.radioButton3.Location = new System.Drawing.Point(27, 19);
			this.radioButton3.Name = "radioButton3";
			this.radioButton3.Size = new System.Drawing.Size(106, 17);
			this.radioButton3.TabIndex = 0;
			this.radioButton3.Text = "Current Line Only";
			this.radioButton3.UseVisualStyleBackColor = true;
			// 
			// radioButton4
			// 
			this.radioButton4.AutoSize = true;
			this.radioButton4.Checked = true;
			this.radioButton4.Location = new System.Drawing.Point(27, 38);
			this.radioButton4.Name = "radioButton4";
			this.radioButton4.Size = new System.Drawing.Size(128, 17);
			this.radioButton4.TabIndex = 1;
			this.radioButton4.TabStop = true;
			this.radioButton4.Text = "Current and Next Line";
			this.radioButton4.UseVisualStyleBackColor = true;
			// 
			// groupBox5
			// 
			this.groupBox5.Controls.Add(this.radioButton7);
			this.groupBox5.Controls.Add(this.radioButton6);
			this.groupBox5.Controls.Add(this.radioButton5);
			this.groupBox5.Location = new System.Drawing.Point(12, 5);
			this.groupBox5.Name = "groupBox5";
			this.groupBox5.Size = new System.Drawing.Size(200, 93);
			this.groupBox5.TabIndex = 17;
			this.groupBox5.TabStop = false;
			this.groupBox5.Text = "Levels";
			// 
			// radioButton5
			// 
			this.radioButton5.AutoSize = true;
			this.radioButton5.Checked = true;
			this.radioButton5.Location = new System.Drawing.Point(24, 19);
			this.radioButton5.Name = "radioButton5";
			this.radioButton5.Size = new System.Drawing.Size(51, 17);
			this.radioButton5.TabIndex = 0;
			this.radioButton5.TabStop = true;
			this.radioButton5.Text = "None";
			this.radioButton5.UseVisualStyleBackColor = true;
			// 
			// radioButton6
			// 
			this.radioButton6.AutoSize = true;
			this.radioButton6.Location = new System.Drawing.Point(24, 42);
			this.radioButton6.Name = "radioButton6";
			this.radioButton6.Size = new System.Drawing.Size(61, 17);
			this.radioButton6.TabIndex = 1;
			this.radioButton6.Text = "L1 Only";
			this.radioButton6.UseVisualStyleBackColor = true;
			// 
			// radioButton7
			// 
			this.radioButton7.AutoSize = true;
			this.radioButton7.Location = new System.Drawing.Point(24, 65);
			this.radioButton7.Name = "radioButton7";
			this.radioButton7.Size = new System.Drawing.Size(73, 17);
			this.radioButton7.TabIndex = 2;
			this.radioButton7.Text = "L1 and L2";
			this.radioButton7.UseVisualStyleBackColor = true;
			// 
			// label11
			// 
			this.label11.AutoSize = true;
			this.label11.Location = new System.Drawing.Point(218, 24);
			this.label11.Name = "label11";
			this.label11.Size = new System.Drawing.Size(81, 13);
			this.label11.TabIndex = 21;
			this.label11.Text = "Max address bit";
			// 
			// numericUpDown1
			// 
			this.numericUpDown1.Location = new System.Drawing.Point(305, 22);
			this.numericUpDown1.Maximum = new decimal(new int[] {
            128,
            0,
            0,
            0});
			this.numericUpDown1.Minimum = new decimal(new int[] {
            4,
            0,
            0,
            0});
			this.numericUpDown1.Name = "numericUpDown1";
			this.numericUpDown1.Size = new System.Drawing.Size(56, 20);
			this.numericUpDown1.TabIndex = 22;
			this.numericUpDown1.Value = new decimal(new int[] {
            31,
            0,
            0,
            0});
			// 
			// textBox1
			// 
			this.textBox1.Location = new System.Drawing.Point(280, 267);
			this.textBox1.Multiline = true;
			this.textBox1.Name = "textBox1";
			this.textBox1.ScrollBars = System.Windows.Forms.ScrollBars.Both;
			this.textBox1.Size = new System.Drawing.Size(240, 168);
			this.textBox1.TabIndex = 23;
			this.textBox1.WordWrap = false;
			// 
			// numericUpDown2
			// 
			this.numericUpDown2.Location = new System.Drawing.Point(139, 61);
			this.numericUpDown2.Maximum = new decimal(new int[] {
            16,
            0,
            0,
            0});
			this.numericUpDown2.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
			this.numericUpDown2.Name = "numericUpDown2";
			this.numericUpDown2.Size = new System.Drawing.Size(55, 20);
			this.numericUpDown2.TabIndex = 2;
			this.numericUpDown2.Value = new decimal(new int[] {
            4,
            0,
            0,
            0});
			// 
			// label12
			// 
			this.label12.AutoSize = true;
			this.label12.Location = new System.Drawing.Point(10, 63);
			this.label12.Name = "label12";
			this.label12.Size = new System.Drawing.Size(123, 13);
			this.label12.TabIndex = 3;
			this.label12.Text = "Max Instr. Length (bytes)";
			// 
			// frmCache
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(544, 482);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.numericUpDown1);
			this.Controls.Add(this.label11);
			this.Controls.Add(this.groupBox5);
			this.Controls.Add(this.button3);
			this.Controls.Add(this.button2);
			this.Controls.Add(this.button1);
			this.Controls.Add(this.groupBox3);
			this.Controls.Add(this.groupBox2);
			this.Name = "frmCache";
			this.Text = "Cache";
			this.groupBox2.ResumeLayout(false);
			this.groupBox2.PerformLayout();
			this.groupBox1.ResumeLayout(false);
			this.groupBox1.PerformLayout();
			this.groupBox3.ResumeLayout(false);
			this.groupBox3.PerformLayout();
			this.groupBox4.ResumeLayout(false);
			this.groupBox4.PerformLayout();
			this.groupBox5.ResumeLayout(false);
			this.groupBox5.PerformLayout();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).EndInit();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.GroupBox groupBox2;
		private System.Windows.Forms.Label label9;
		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.ComboBox comboBox4;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.RadioButton radioButton2;
		private System.Windows.Forms.RadioButton radioButton1;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.ComboBox comboBox3;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.ComboBox comboBox2;
		private System.Windows.Forms.ComboBox comboBox1;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.GroupBox groupBox3;
		private System.Windows.Forms.Label label10;
		private System.Windows.Forms.ComboBox comboBox8;
		private System.Windows.Forms.Label label8;
		private System.Windows.Forms.ComboBox comboBox7;
		private System.Windows.Forms.Label label7;
		private System.Windows.Forms.ComboBox comboBox6;
		private System.Windows.Forms.Label label6;
		private System.Windows.Forms.ComboBox comboBox5;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.Button button2;
		private System.Windows.Forms.Button button3;
		private System.Windows.Forms.GroupBox groupBox4;
		private System.Windows.Forms.RadioButton radioButton4;
		private System.Windows.Forms.RadioButton radioButton3;
		private System.Windows.Forms.GroupBox groupBox5;
		private System.Windows.Forms.RadioButton radioButton7;
		private System.Windows.Forms.RadioButton radioButton6;
		private System.Windows.Forms.RadioButton radioButton5;
		private System.Windows.Forms.Label label11;
		private System.Windows.Forms.NumericUpDown numericUpDown1;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.Label label12;
		private System.Windows.Forms.NumericUpDown numericUpDown2;
	}
}