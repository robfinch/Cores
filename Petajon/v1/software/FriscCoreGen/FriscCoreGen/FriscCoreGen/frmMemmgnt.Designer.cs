namespace FriscCoreGen
{
	partial class frmMemmgnt
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
			this.comboBox1 = new System.Windows.Forms.ComboBox();
			this.label1 = new System.Windows.Forms.Label();
			this.label2 = new System.Windows.Forms.Label();
			this.comboBox2 = new System.Windows.Forms.ComboBox();
			this.label3 = new System.Windows.Forms.Label();
			this.button1 = new System.Windows.Forms.Button();
			this.button2 = new System.Windows.Forms.Button();
			this.checkBox1 = new System.Windows.Forms.CheckBox();
			this.checkBox12 = new System.Windows.Forms.CheckBox();
			this.checkBox13 = new System.Windows.Forms.CheckBox();
			this.checkBox19 = new System.Windows.Forms.CheckBox();
			this.comboBox3 = new System.Windows.Forms.ComboBox();
			this.label4 = new System.Windows.Forms.Label();
			this.label5 = new System.Windows.Forms.Label();
			this.comboBox4 = new System.Windows.Forms.ComboBox();
			this.checkBox16 = new System.Windows.Forms.CheckBox();
			this.checkBox17 = new System.Windows.Forms.CheckBox();
			this.checkBox18 = new System.Windows.Forms.CheckBox();
			this.checkBox2 = new System.Windows.Forms.CheckBox();
			this.checkBox14 = new System.Windows.Forms.CheckBox();
			this.checkBox15 = new System.Windows.Forms.CheckBox();
			this.bindingSource1 = new System.Windows.Forms.BindingSource(this.components);
			this.database3DataSet = new FriscCoreGen.Database3DataSet();
			this.label6 = new System.Windows.Forms.Label();
			this.numericUpDown1 = new System.Windows.Forms.NumericUpDown();
			this.numericUpDown2 = new System.Windows.Forms.NumericUpDown();
			this.label7 = new System.Windows.Forms.Label();
			this.label8 = new System.Windows.Forms.Label();
			this.label9 = new System.Windows.Forms.Label();
			this.textBox1 = new System.Windows.Forms.TextBox();
			((System.ComponentModel.ISupportInitialize)(this.bindingSource1)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.database3DataSet)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).BeginInit();
			this.SuspendLayout();
			// 
			// comboBox1
			// 
			this.comboBox1.FormattingEnabled = true;
			this.comboBox1.Items.AddRange(new object[] {
            "pc[31:24]==8\'hFF"});
			this.comboBox1.Location = new System.Drawing.Point(239, 69);
			this.comboBox1.Name = "comboBox1";
			this.comboBox1.Size = new System.Drawing.Size(204, 21);
			this.comboBox1.TabIndex = 0;
			this.comboBox1.Tag = "PCExclusion";
			this.comboBox1.Text = "pc[31:24]==8\'hFF";
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(236, 53);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(194, 13);
			this.label1.TabIndex = 1;
			this.label1.Text = "PC exclusion from memory management";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(236, 104);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(194, 13);
			this.label2.TabIndex = 2;
			this.label2.Text = "EA exclusion from memory management";
			// 
			// comboBox2
			// 
			this.comboBox2.FormattingEnabled = true;
			this.comboBox2.Items.AddRange(new object[] {
            "ea[31:24]==8\'hFF"});
			this.comboBox2.Location = new System.Drawing.Point(239, 120);
			this.comboBox2.Name = "comboBox2";
			this.comboBox2.Size = new System.Drawing.Size(204, 21);
			this.comboBox2.TabIndex = 3;
			this.comboBox2.Tag = "EAExclusion";
			this.comboBox2.Text = "ea[31:24]==8\'hFF";
			// 
			// label3
			// 
			this.label3.AutoSize = true;
			this.label3.Location = new System.Drawing.Point(8, 9);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(392, 26);
			this.label3.TabIndex = 4;
			this.label3.Text = "The following memory management features apply only at the user operating level.\r" +
    "\nOther levels of operation have unrestricted flat addressing.";
			// 
			// button1
			// 
			this.button1.DialogResult = System.Windows.Forms.DialogResult.OK;
			this.button1.Location = new System.Drawing.Point(378, 272);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(75, 23);
			this.button1.TabIndex = 5;
			this.button1.Text = "OK";
			this.button1.UseVisualStyleBackColor = true;
			this.button1.Click += new System.EventHandler(this.button1_Click);
			// 
			// button2
			// 
			this.button2.DialogResult = System.Windows.Forms.DialogResult.Cancel;
			this.button2.Location = new System.Drawing.Point(281, 272);
			this.button2.Name = "button2";
			this.button2.Size = new System.Drawing.Size(75, 23);
			this.button2.TabIndex = 6;
			this.button2.Text = "Cancel";
			this.button2.UseVisualStyleBackColor = true;
			// 
			// checkBox1
			// 
			this.checkBox1.AutoSize = true;
			this.checkBox1.Location = new System.Drawing.Point(11, 52);
			this.checkBox1.Name = "checkBox1";
			this.checkBox1.Size = new System.Drawing.Size(93, 17);
			this.checkBox1.TabIndex = 7;
			this.checkBox1.Tag = "BankSelector";
			this.checkBox1.Text = "Bank Selector";
			this.checkBox1.UseVisualStyleBackColor = true;
			this.checkBox1.CheckedChanged += new System.EventHandler(this.checkBox1_CheckedChanged);
			// 
			// checkBox12
			// 
			this.checkBox12.AutoSize = true;
			this.checkBox12.Location = new System.Drawing.Point(11, 75);
			this.checkBox12.Name = "checkBox12";
			this.checkBox12.Size = new System.Drawing.Size(137, 17);
			this.checkBox12.TabIndex = 39;
			this.checkBox12.Tag = "SingleBaseBound";
			this.checkBox12.Text = "Single Base and Bound";
			this.checkBox12.UseVisualStyleBackColor = true;
			// 
			// checkBox13
			// 
			this.checkBox13.AutoSize = true;
			this.checkBox13.Location = new System.Drawing.Point(11, 98);
			this.checkBox13.Name = "checkBox13";
			this.checkBox13.Size = new System.Drawing.Size(142, 17);
			this.checkBox13.TabIndex = 40;
			this.checkBox13.Tag = "DoubleBaseBound";
			this.checkBox13.Text = "Double Base and Bound";
			this.checkBox13.UseVisualStyleBackColor = true;
			// 
			// checkBox19
			// 
			this.checkBox19.AutoSize = true;
			this.checkBox19.Location = new System.Drawing.Point(11, 143);
			this.checkBox19.Name = "checkBox19";
			this.checkBox19.Size = new System.Drawing.Size(150, 17);
			this.checkBox19.TabIndex = 46;
			this.checkBox19.Tag = "SAM";
			this.checkBox19.Text = "Simplified Address Mapper";
			this.checkBox19.UseVisualStyleBackColor = true;
			// 
			// comboBox3
			// 
			this.comboBox3.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.comboBox3.FormattingEnabled = true;
			this.comboBox3.Items.AddRange(new object[] {
            "4096",
            "65536",
            "32768",
            "16384",
            "8192",
            "2048",
            "1024",
            "512",
            "256",
            "128",
            "64",
            "32",
            "16"});
			this.comboBox3.Location = new System.Drawing.Point(67, 179);
			this.comboBox3.Name = "comboBox3";
			this.comboBox3.Size = new System.Drawing.Size(86, 21);
			this.comboBox3.TabIndex = 47;
			this.comboBox3.Tag = "PagesPerAddressSpace";
			this.comboBox3.SelectedIndexChanged += new System.EventHandler(this.comboBox3_SelectedIndexChanged);
			// 
			// label4
			// 
			this.label4.AutoSize = true;
			this.label4.Location = new System.Drawing.Point(34, 163);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(168, 13);
			this.label4.TabIndex = 48;
			this.label4.Text = "Mapped pages per address space";
			// 
			// label5
			// 
			this.label5.AutoSize = true;
			this.label5.Location = new System.Drawing.Point(34, 203);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(133, 13);
			this.label5.TabIndex = 49;
			this.label5.Text = "Number of address spaces";
			// 
			// comboBox4
			// 
			this.comboBox4.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.comboBox4.FormattingEnabled = true;
			this.comboBox4.Items.AddRange(new object[] {
            "64",
            "32",
            "16",
            "256",
            "128",
            "8",
            "4",
            "2",
            "1"});
			this.comboBox4.Location = new System.Drawing.Point(88, 219);
			this.comboBox4.Name = "comboBox4";
			this.comboBox4.Size = new System.Drawing.Size(65, 21);
			this.comboBox4.TabIndex = 50;
			this.comboBox4.Tag = "AddressSpaces";
			// 
			// checkBox16
			// 
			this.checkBox16.AutoSize = true;
			this.checkBox16.Location = new System.Drawing.Point(11, 245);
			this.checkBox16.Name = "checkBox16";
			this.checkBox16.Size = new System.Drawing.Size(86, 17);
			this.checkBox16.TabIndex = 51;
			this.checkBox16.Tag = "Sv32";
			this.checkBox16.Text = "Sv32 paging";
			this.checkBox16.UseVisualStyleBackColor = true;
			// 
			// checkBox17
			// 
			this.checkBox17.AutoSize = true;
			this.checkBox17.Location = new System.Drawing.Point(11, 266);
			this.checkBox17.Name = "checkBox17";
			this.checkBox17.Size = new System.Drawing.Size(86, 17);
			this.checkBox17.TabIndex = 52;
			this.checkBox17.Tag = "Sv39";
			this.checkBox17.Text = "Sv39 paging";
			this.checkBox17.UseVisualStyleBackColor = true;
			// 
			// checkBox18
			// 
			this.checkBox18.AutoSize = true;
			this.checkBox18.Location = new System.Drawing.Point(11, 286);
			this.checkBox18.Name = "checkBox18";
			this.checkBox18.Size = new System.Drawing.Size(86, 17);
			this.checkBox18.TabIndex = 53;
			this.checkBox18.Tag = "Sv48";
			this.checkBox18.Text = "Sv48 paging";
			this.checkBox18.UseVisualStyleBackColor = true;
			// 
			// checkBox2
			// 
			this.checkBox2.AutoSize = true;
			this.checkBox2.Location = new System.Drawing.Point(11, 120);
			this.checkBox2.Name = "checkBox2";
			this.checkBox2.Size = new System.Drawing.Size(115, 17);
			this.checkBox2.TabIndex = 54;
			this.checkBox2.Tag = "SegmentRegisters";
			this.checkBox2.Text = "Segment Registers";
			this.checkBox2.UseVisualStyleBackColor = true;
			// 
			// checkBox14
			// 
			this.checkBox14.AutoSize = true;
			this.checkBox14.Location = new System.Drawing.Point(103, 249);
			this.checkBox14.Name = "checkBox14";
			this.checkBox14.Size = new System.Drawing.Size(138, 17);
			this.checkBox14.TabIndex = 55;
			this.checkBox14.Tag = "STLB";
			this.checkBox14.Text = "Software managed TLB";
			this.checkBox14.UseVisualStyleBackColor = true;
			// 
			// checkBox15
			// 
			this.checkBox15.AutoSize = true;
			this.checkBox15.Location = new System.Drawing.Point(103, 272);
			this.checkBox15.Name = "checkBox15";
			this.checkBox15.Size = new System.Drawing.Size(142, 17);
			this.checkBox15.TabIndex = 56;
			this.checkBox15.Tag = "HTLB";
			this.checkBox15.Text = "Hardware managed TLB";
			this.checkBox15.UseVisualStyleBackColor = true;
			// 
			// bindingSource1
			// 
			this.bindingSource1.DataSource = this.database3DataSet;
			this.bindingSource1.Position = 0;
			// 
			// database3DataSet
			// 
			this.database3DataSet.DataSetName = "Database3DataSet";
			this.database3DataSet.SchemaSerializationMode = System.Data.SchemaSerializationMode.IncludeSchema;
			// 
			// label6
			// 
			this.label6.AutoSize = true;
			this.label6.Location = new System.Drawing.Point(236, 163);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(97, 13);
			this.label6.TabIndex = 57;
			this.label6.Text = "Address Bus Width";
			// 
			// numericUpDown1
			// 
			this.numericUpDown1.Location = new System.Drawing.Point(339, 161);
			this.numericUpDown1.Maximum = new decimal(new int[] {
            64,
            0,
            0,
            0});
			this.numericUpDown1.Minimum = new decimal(new int[] {
            4,
            0,
            0,
            0});
			this.numericUpDown1.Name = "numericUpDown1";
			this.numericUpDown1.Size = new System.Drawing.Size(51, 20);
			this.numericUpDown1.TabIndex = 58;
			this.numericUpDown1.Tag = "ABWID";
			this.numericUpDown1.Value = new decimal(new int[] {
            32,
            0,
            0,
            0});
			// 
			// numericUpDown2
			// 
			this.numericUpDown2.ImeMode = System.Windows.Forms.ImeMode.NoControl;
			this.numericUpDown2.Location = new System.Drawing.Point(339, 187);
			this.numericUpDown2.Maximum = new decimal(new int[] {
            513,
            0,
            0,
            0});
			this.numericUpDown2.Name = "numericUpDown2";
			this.numericUpDown2.Size = new System.Drawing.Size(51, 20);
			this.numericUpDown2.TabIndex = 59;
			this.numericUpDown2.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
			this.numericUpDown2.ValueChanged += new System.EventHandler(this.numericUpDown2_ValueChanged);
			// 
			// label7
			// 
			this.label7.AutoSize = true;
			this.label7.Location = new System.Drawing.Point(396, 189);
			this.label7.Name = "label7";
			this.label7.Size = new System.Drawing.Size(20, 13);
			this.label7.TabIndex = 60;
			this.label7.Text = "kB";
			// 
			// label8
			// 
			this.label8.AutoSize = true;
			this.label8.Location = new System.Drawing.Point(236, 189);
			this.label8.Name = "label8";
			this.label8.Size = new System.Drawing.Size(67, 13);
			this.label8.TabIndex = 61;
			this.label8.Text = "Memory Size";
			// 
			// label9
			// 
			this.label9.AutoSize = true;
			this.label9.Location = new System.Drawing.Point(236, 219);
			this.label9.Name = "label9";
			this.label9.Size = new System.Drawing.Size(55, 13);
			this.label9.TabIndex = 62;
			this.label9.Text = "Page Size";
			// 
			// textBox1
			// 
			this.textBox1.Enabled = false;
			this.textBox1.Location = new System.Drawing.Point(309, 216);
			this.textBox1.Name = "textBox1";
			this.textBox1.Size = new System.Drawing.Size(81, 20);
			this.textBox1.TabIndex = 63;
			// 
			// frmMemmgnt
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(472, 320);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.label9);
			this.Controls.Add(this.label8);
			this.Controls.Add(this.label7);
			this.Controls.Add(this.numericUpDown2);
			this.Controls.Add(this.numericUpDown1);
			this.Controls.Add(this.label6);
			this.Controls.Add(this.checkBox15);
			this.Controls.Add(this.checkBox14);
			this.Controls.Add(this.checkBox2);
			this.Controls.Add(this.checkBox18);
			this.Controls.Add(this.checkBox17);
			this.Controls.Add(this.checkBox16);
			this.Controls.Add(this.comboBox4);
			this.Controls.Add(this.label5);
			this.Controls.Add(this.label4);
			this.Controls.Add(this.comboBox3);
			this.Controls.Add(this.checkBox19);
			this.Controls.Add(this.checkBox13);
			this.Controls.Add(this.checkBox12);
			this.Controls.Add(this.checkBox1);
			this.Controls.Add(this.button2);
			this.Controls.Add(this.button1);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.comboBox2);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.comboBox1);
			this.Name = "frmMemmgnt";
			this.Text = "Memory Management Features";
			((System.ComponentModel.ISupportInitialize)(this.bindingSource1)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.database3DataSet)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown2)).EndInit();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.ComboBox comboBox1;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.ComboBox comboBox2;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.Button button1;
		private System.Windows.Forms.Button button2;
		private System.Windows.Forms.CheckBox checkBox1;
		private System.Windows.Forms.CheckBox checkBox12;
		private System.Windows.Forms.CheckBox checkBox13;
		private System.Windows.Forms.CheckBox checkBox19;
		private System.Windows.Forms.ComboBox comboBox3;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.ComboBox comboBox4;
		private System.Windows.Forms.CheckBox checkBox16;
		private System.Windows.Forms.CheckBox checkBox17;
		private System.Windows.Forms.CheckBox checkBox18;
		private System.Windows.Forms.CheckBox checkBox2;
		private System.Windows.Forms.CheckBox checkBox14;
		private System.Windows.Forms.CheckBox checkBox15;
		private System.Windows.Forms.BindingSource bindingSource1;
		private Database3DataSet database3DataSet;
		private System.Windows.Forms.Label label6;
		private System.Windows.Forms.NumericUpDown numericUpDown1;
		private System.Windows.Forms.NumericUpDown numericUpDown2;
		private System.Windows.Forms.Label label7;
		private System.Windows.Forms.Label label8;
		private System.Windows.Forms.Label label9;
		private System.Windows.Forms.TextBox textBox1;
	}
}