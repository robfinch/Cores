namespace FriscCoreGen
{
	partial class frmSAM
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
			System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(frmSAM));
			this.numericUpDown1 = new System.Windows.Forms.NumericUpDown();
			this.label1 = new System.Windows.Forms.Label();
			this.label2 = new System.Windows.Forms.Label();
			this.toolTip1 = new System.Windows.Forms.ToolTip(this.components);
			this.numericUpDown4 = new System.Windows.Forms.NumericUpDown();
			this.groupBox1 = new System.Windows.Forms.GroupBox();
			this.numericUpDown2 = new System.Windows.Forms.NumericUpDown();
			this.label8 = new System.Windows.Forms.Label();
			this.checkBox4 = new System.Windows.Forms.CheckBox();
			this.checkBox3 = new System.Windows.Forms.CheckBox();
			this.checkBox2 = new System.Windows.Forms.CheckBox();
			this.checkBox1 = new System.Windows.Forms.CheckBox();
			this.numericUpDown3 = new System.Windows.Forms.NumericUpDown();
			this.label3 = new System.Windows.Forms.Label();
			this.label4 = new System.Windows.Forms.Label();
			this.label5 = new System.Windows.Forms.Label();
			this.label6 = new System.Windows.Forms.Label();
			this.label7 = new System.Windows.Forms.Label();
			this.timer1 = new System.Windows.Forms.Timer(this.components);
			this.textBox1 = new System.Windows.Forms.TextBox();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown4)).BeginInit();
			this.groupBox1.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown3)).BeginInit();
			this.SuspendLayout();
			// 
			// numericUpDown1
			// 
			this.numericUpDown1.Location = new System.Drawing.Point(210, 158);
			this.numericUpDown1.Maximum = new decimal(new int[] {
            32,
            0,
            0,
            0});
			this.numericUpDown1.Minimum = new decimal(new int[] {
            2,
            0,
            0,
            0});
			this.numericUpDown1.Name = "numericUpDown1";
			this.numericUpDown1.Size = new System.Drawing.Size(42, 20);
			this.numericUpDown1.TabIndex = 0;
			this.numericUpDown1.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
			this.toolTip1.SetToolTip(this.numericUpDown1, "Usually each task has it\'s own address space; however in a small system multiple " +
        "task may share an address space.\r\nAddress spaces may also be shared to share dat" +
        "a between tasks.");
			this.numericUpDown1.Value = new decimal(new int[] {
            2,
            0,
            0,
            0});
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(12, 160);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(136, 13);
			this.label1.TabIndex = 1;
			this.label1.Text = "Number of Address Spaces";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(12, 215);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(174, 13);
			this.label2.TabIndex = 2;
			this.label2.Text = "Mapped Entries per Address Space";
			// 
			// numericUpDown4
			// 
			this.numericUpDown4.Location = new System.Drawing.Point(204, 238);
			this.numericUpDown4.Maximum = new decimal(new int[] {
            31,
            0,
            0,
            0});
			this.numericUpDown4.Minimum = new decimal(new int[] {
            8,
            0,
            0,
            0});
			this.numericUpDown4.Name = "numericUpDown4";
			this.numericUpDown4.Size = new System.Drawing.Size(48, 20);
			this.numericUpDown4.TabIndex = 7;
			this.numericUpDown4.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
			this.toolTip1.SetToolTip(this.numericUpDown4, resources.GetString("numericUpDown4.ToolTip"));
			this.numericUpDown4.Value = new decimal(new int[] {
            12,
            0,
            0,
            0});
			// 
			// groupBox1
			// 
			this.groupBox1.Controls.Add(this.numericUpDown2);
			this.groupBox1.Controls.Add(this.label8);
			this.groupBox1.Controls.Add(this.checkBox4);
			this.groupBox1.Controls.Add(this.checkBox3);
			this.groupBox1.Controls.Add(this.checkBox2);
			this.groupBox1.Controls.Add(this.checkBox1);
			this.groupBox1.Location = new System.Drawing.Point(15, 296);
			this.groupBox1.Name = "groupBox1";
			this.groupBox1.Size = new System.Drawing.Size(260, 100);
			this.groupBox1.TabIndex = 17;
			this.groupBox1.TabStop = false;
			this.groupBox1.Text = "Supported Attributes";
			this.toolTip1.SetToolTip(this.groupBox1, "Each mapped memory page may have additional attributes associated with it besides" +
        " just the address mapping.\r\nThese additional attributes require additional memor" +
        "y in the mapping table.");
			// 
			// numericUpDown2
			// 
			this.numericUpDown2.Location = new System.Drawing.Point(82, 42);
			this.numericUpDown2.Maximum = new decimal(new int[] {
            20,
            0,
            0,
            0});
			this.numericUpDown2.Minimum = new decimal(new int[] {
            3,
            0,
            0,
            0});
			this.numericUpDown2.Name = "numericUpDown2";
			this.numericUpDown2.Size = new System.Drawing.Size(41, 20);
			this.numericUpDown2.TabIndex = 19;
			this.numericUpDown2.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
			this.toolTip1.SetToolTip(this.numericUpDown2, resources.GetString("numericUpDown2.ToolTip"));
			this.numericUpDown2.Value = new decimal(new int[] {
            5,
            0,
            0,
            0});
			// 
			// label8
			// 
			this.label8.AutoSize = true;
			this.label8.Location = new System.Drawing.Point(3, 44);
			this.label8.Name = "label8";
			this.label8.Size = new System.Drawing.Size(73, 13);
			this.label8.TabIndex = 18;
			this.label8.Text = "Key Size (bits)";
			// 
			// checkBox4
			// 
			this.checkBox4.AutoSize = true;
			this.checkBox4.Location = new System.Drawing.Point(6, 20);
			this.checkBox4.Name = "checkBox4";
			this.checkBox4.Size = new System.Drawing.Size(44, 17);
			this.checkBox4.TabIndex = 17;
			this.checkBox4.Text = "Key";
			this.checkBox4.UseVisualStyleBackColor = true;
			// 
			// checkBox3
			// 
			this.checkBox3.AutoSize = true;
			this.checkBox3.Location = new System.Drawing.Point(151, 65);
			this.checkBox3.Name = "checkBox3";
			this.checkBox3.Size = new System.Drawing.Size(79, 17);
			this.checkBox3.TabIndex = 16;
			this.checkBox3.Text = "Executable";
			this.checkBox3.UseVisualStyleBackColor = true;
			// 
			// checkBox2
			// 
			this.checkBox2.AutoSize = true;
			this.checkBox2.Location = new System.Drawing.Point(151, 42);
			this.checkBox2.Name = "checkBox2";
			this.checkBox2.Size = new System.Drawing.Size(71, 17);
			this.checkBox2.TabIndex = 15;
			this.checkBox2.Text = "Writeable";
			this.checkBox2.UseVisualStyleBackColor = true;
			// 
			// checkBox1
			// 
			this.checkBox1.AutoSize = true;
			this.checkBox1.Location = new System.Drawing.Point(151, 20);
			this.checkBox1.Name = "checkBox1";
			this.checkBox1.Size = new System.Drawing.Size(72, 17);
			this.checkBox1.TabIndex = 14;
			this.checkBox1.Text = "Readable";
			this.checkBox1.UseVisualStyleBackColor = true;
			// 
			// numericUpDown3
			// 
			this.numericUpDown3.Location = new System.Drawing.Point(204, 188);
			this.numericUpDown3.Maximum = new decimal(new int[] {
            10,
            0,
            0,
            0});
			this.numericUpDown3.Minimum = new decimal(new int[] {
            3,
            0,
            0,
            0});
			this.numericUpDown3.Name = "numericUpDown3";
			this.numericUpDown3.Size = new System.Drawing.Size(48, 20);
			this.numericUpDown3.TabIndex = 4;
			this.numericUpDown3.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
			this.numericUpDown3.Value = new decimal(new int[] {
            3,
            0,
            0,
            0});
			this.numericUpDown3.ValueChanged += new System.EventHandler(this.numericUpDown3_ValueChanged);
			// 
			// label3
			// 
			this.label3.AutoSize = true;
			this.label3.Location = new System.Drawing.Point(12, 190);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(156, 13);
			this.label3.TabIndex = 5;
			this.label3.Text = "Number of mapped address bits";
			// 
			// label4
			// 
			this.label4.AutoSize = true;
			this.label4.Location = new System.Drawing.Point(12, 240);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(121, 13);
			this.label4.TabIndex = 6;
			this.label4.Text = "First mapped address bit";
			// 
			// label5
			// 
			this.label5.AutoSize = true;
			this.label5.Location = new System.Drawing.Point(239, 215);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(13, 13);
			this.label5.TabIndex = 8;
			this.label5.Text = "8";
			this.label5.TextAlign = System.Drawing.ContentAlignment.TopRight;
			// 
			// label6
			// 
			this.label6.AutoSize = true;
			this.label6.Location = new System.Drawing.Point(12, 267);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(132, 13);
			this.label6.TabIndex = 9;
			this.label6.Text = "Each address space maps";
			// 
			// label7
			// 
			this.label7.AutoSize = true;
			this.label7.Location = new System.Drawing.Point(151, 267);
			this.label7.Name = "label7";
			this.label7.Size = new System.Drawing.Size(13, 13);
			this.label7.TabIndex = 10;
			this.label7.Text = "0";
			// 
			// timer1
			// 
			this.timer1.Enabled = true;
			this.timer1.Tick += new System.EventHandler(this.timer1_Tick);
			// 
			// textBox1
			// 
			this.textBox1.Location = new System.Drawing.Point(15, 12);
			this.textBox1.Multiline = true;
			this.textBox1.Name = "textBox1";
			this.textBox1.ReadOnly = true;
			this.textBox1.Size = new System.Drawing.Size(310, 126);
			this.textBox1.TabIndex = 18;
			this.textBox1.Text = resources.GetString("textBox1.Text");
			// 
			// frmSAM
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(337, 420);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.groupBox1);
			this.Controls.Add(this.label7);
			this.Controls.Add(this.label6);
			this.Controls.Add(this.label5);
			this.Controls.Add(this.numericUpDown4);
			this.Controls.Add(this.label4);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.numericUpDown3);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.numericUpDown1);
			this.Name = "frmSAM";
			this.Text = "Simplified Address Mapper";
			this.toolTip1.SetToolTip(this, resources.GetString("$this.ToolTip"));
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown4)).EndInit();
			this.groupBox1.ResumeLayout(false);
			this.groupBox1.PerformLayout();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown3)).EndInit();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.NumericUpDown numericUpDown1;
		private System.Windows.Forms.ToolTip toolTip1;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.NumericUpDown numericUpDown3;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.NumericUpDown numericUpDown4;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.Label label6;
		private System.Windows.Forms.Label label7;
		private System.Windows.Forms.Timer timer1;
		private System.Windows.Forms.GroupBox groupBox1;
		private System.Windows.Forms.NumericUpDown numericUpDown2;
		private System.Windows.Forms.Label label8;
		private System.Windows.Forms.CheckBox checkBox4;
		private System.Windows.Forms.CheckBox checkBox3;
		private System.Windows.Forms.CheckBox checkBox2;
		private System.Windows.Forms.CheckBox checkBox1;
		private System.Windows.Forms.TextBox textBox1;
	}
}