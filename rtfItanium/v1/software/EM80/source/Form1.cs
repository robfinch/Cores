using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace EM80
{
	public partial class Form1 : Form
	{
		rtfItaniumCpu cpu = new rtfItaniumCpu();
		SoC soc = new SoC();
		TextBox[] registerBoxes;
		TextBox ipBox = new TextBox();
		TextBox iBundleBox = new TextBox();
		TextBox dumpBox = new TextBox();

		public void UpdateRegisters()
		{
			int nn;

			for (nn = 0; nn < 64; nn++)
			{
				registerBoxes[nn].Text = cpu.regfile[nn].ToString80();
			}
			ipBox.Text = cpu.ip.ToString80();
			iBundleBox.Text = cpu.ibundle.ToString80();
			ipBox.Refresh();
			iBundleBox.Refresh();
		}
		public Form1()
		{
			int nn;
			registerBoxes = new TextBox[64];

			InitializeComponent();

			for (nn = 0; nn < 64; nn++)
			{
				var tbox = new TextBox();
				var tlbl = new Label();
				tlbl.Name = "regLbl" + Convert.ToString(nn);
				tlbl.Location = new Point(46 + 180 * (nn >> 4), 32 + (nn % 16) * 24);
				tlbl.Size = new System.Drawing.Size(30, 20);
				tlbl.Text = "r" + Convert.ToString(nn);
				tlbl.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
				this.Controls.Add(tlbl);
				this.Controls.Add(tbox);
				registerBoxes[nn] = tbox;
				registerBoxes[nn].Location = new Point(76 + 180 * (nn >> 4), 32 + (nn % 16) * 24);
				registerBoxes[nn].Name = "regBox" + Convert.ToString(nn);
				registerBoxes[nn].Size = new System.Drawing.Size(150, 20);
				registerBoxes[nn].TabIndex = nn;
				registerBoxes[nn].Text = "0";
				registerBoxes[nn].TextAlign = HorizontalAlignment.Right;
				ipBox.Name = "ipBox";
				ipBox.Location = new Point(76, 432);
				ipBox.Size = new System.Drawing.Size(150, 20);
				ipBox.TabIndex = 64;
				ipBox.Text = "0";
				ipBox.TextAlign = HorizontalAlignment.Right;
				this.Controls.Add(ipBox);
				iBundleBox.Name = "iBundleBox";
				iBundleBox.Location = new Point(76+180, 432);
				iBundleBox.Size = new System.Drawing.Size(150, 20);
				iBundleBox.TabIndex = 65;
				iBundleBox.Text = "0";
				iBundleBox.TextAlign = HorizontalAlignment.Right;
				this.Controls.Add(iBundleBox);
				dumpBox.Name = "dumpBox";
				dumpBox.Location = new Point(800, 32);
				dumpBox.Size = new System.Drawing.Size(230, 400);
				dumpBox.TabIndex = 66;
				dumpBox.Multiline = true;
				dumpBox.AcceptsReturn = true;
				dumpBox.MaxLength = 10000000;
				dumpBox.Font = new Font("Courier New", 7.0f);
				dumpBox.Text = "0";
				dumpBox.ScrollBars = ScrollBars.Vertical;
				this.Controls.Add(dumpBox);
			}
		}

		private void Form1_Load(object sender, EventArgs e)
		{

		}

		private void resetToolStripMenuItem_Click(object sender, EventArgs e)
		{
			cpu.Reset();
			UpdateRegisters();
		}

		private void loadToolStripMenuItem_Click(object sender, EventArgs e)
		{
			if (openFileDialog1.ShowDialog() == DialogResult.OK)
			{
				soc.LoadROM(openFileDialog1.FileName);
			}
		}

		private void stepToolStripMenuItem_Click(object sender, EventArgs e)
		{
			cpu.Step(soc);
			UpdateRegisters();
		}

		private void rOMToolStripMenuItem_Click(object sender, EventArgs e)
		{
			timer1.Enabled = true;
		}

		private void timer1_Tick(object sender, EventArgs e)
		{
			string str;
			int nn;

			dumpBox.Clear();
			str = "";
			nn = 0;
			foreach (Int128 a in soc.rom)
			{
				str = str + Convert.ToString(nn,16).PadLeft(6,'0') + ": " + a.ToString128() + "\r\n";
				nn++;
			}
			dumpBox.Text = str;
			timer1.Enabled = false;
		}
	}
}
