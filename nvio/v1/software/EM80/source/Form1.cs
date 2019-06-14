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
		SoC soc = new SoC();
		TextBox[] registerBoxes;
		TextBox ipBox = new TextBox();
		TextBox iBundleBox = new TextBox();
		TextBox dumpBox = new TextBox();
		TextBox tbAddr = new TextBox();
		LED[] leds;
		int regset;
		int count;
		bool BreakPressed;

		public void UpdateRegisters()
		{
			int nn;

			for (nn = 0; nn < 64; nn++)
			{
				registerBoxes[nn].Text = soc.cpu.regfile[nn+regset].ToString80();
			}
			ipBox.Text = soc.cpu.ip.ToString80();
			iBundleBox.Text = soc.cpu.ibundle.ToString80();
			ipBox.Refresh();
			leds[0].on = ((soc.leds & 0x80) != 0) ? true : false;
			leds[1].on = ((soc.leds & 0x40) != 0) ? true : false;
			leds[2].on = ((soc.leds & 0x20) != 0) ? true : false;
			leds[3].on = ((soc.leds & 0x10) != 0) ? true : false;
			leds[4].on = ((soc.leds & 0x08) != 0) ? true : false;
			leds[5].on = ((soc.leds & 0x04) != 0) ? true : false;
			leds[6].on = ((soc.leds & 0x02) != 0) ? true : false;
			leds[7].on = ((soc.leds & 0x01) != 0) ? true : false;
			for (nn = 0; nn < 8; nn++)
			{
				leds[nn].Refresh();
			}
			iBundleBox.Refresh();
		}
		public Form1()
		{
			int nn;
			registerBoxes = new TextBox[64];

			InitializeComponent();

			BreakPressed = false;
			leds = new LED[8];
			for (nn = 0; nn < 8; nn++)
			{
				leds[nn] = new LED();
				leds[nn].Size = new Size(20, 20);
				leds[nn].BackColor = Color.Transparent;
				leds[nn].Off();
				leds[nn].Location = new Point(ClientRectangle.Location.X + 30 + nn * 25, ClientRectangle.Size.Height - 30);
				this.Controls.Add(leds[nn]);
			}

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
				registerBoxes[nn].Font = new Font("Courier New", 8.0f);
				registerBoxes[nn].Text = "0";
				registerBoxes[nn].TextAlign = HorizontalAlignment.Right;
				tlbl = new Label();
				tlbl.Name = "ipLbl";
				tlbl.Location = new Point(46, 432);
				tlbl.Size = new System.Drawing.Size(30, 20);
				tlbl.Text = "ip";
				tlbl.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
				this.Controls.Add(tlbl);
				ipBox.Name = "ipBox";
				ipBox.Location = new Point(76, 432);
				ipBox.Size = new System.Drawing.Size(150, 20);
				ipBox.TabIndex = 64;
				ipBox.Font = new Font("Courier New", 8.0f);
				ipBox.Text = "0";
				ipBox.TextAlign = HorizontalAlignment.Right;
				this.Controls.Add(ipBox);
				tlbl = new Label();
				tlbl.Name = "bundleLbl";
				tlbl.Location = new Point(76 + 215, 414);
				tlbl.Size = new System.Drawing.Size(60, 17);
				tlbl.Text = "bundle";
				tlbl.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
				this.Controls.Add(tlbl);
				iBundleBox.Name = "iBundleBox";
				iBundleBox.Location = new Point(76+180, 432);
				iBundleBox.Size = new System.Drawing.Size(150, 20);
				iBundleBox.TabIndex = 65;
				iBundleBox.Font = new Font("Courier New", 8.0f);
				iBundleBox.Text = "0";
				iBundleBox.TextAlign = HorizontalAlignment.Right;
				this.Controls.Add(iBundleBox);
				//tbAddr.Name = "tbAddress";
				//tbAddr.Location = new Point(800, 32);
				//tbAddr.Size = new System.Drawing.Size(150, 20);
				//tbAddr.TabIndex = 66;
				//tbAddr.Font = new Font("Courier New", 8.0f);
				//tbAddr.Text = "0";
				//tbAddr.TextAlign = HorizontalAlignment.Right;
				//this.Controls.Add(tbAddr);
				dumpBox.Name = "dumpBox";
				dumpBox.Location = new Point(800, 60);
				dumpBox.Size = new System.Drawing.Size(250, 380);
				dumpBox.TabIndex = 67;
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
			soc.Reset();
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
			soc.Step();
			UpdateRegisters();
			Application.DoEvents();
		}

		private void rOMToolStripMenuItem_Click(object sender, EventArgs e)
		{
			timer1.Enabled = true;
		}

		private void timer1_Tick(object sender, EventArgs e)
		{
			string str;
			int nn;
			Int128 ad = new Int128(textBox1.Text);
			Int128 dat;

			dumpBox.Clear();
			str = "";
			nn = 0;
			for (nn = 0; nn < 50; nn++)
			{
				dat = soc.Read(ad);
				str = str + Convert.ToString((long)ad.digits[0],16).PadLeft(6,'0') + ": " + dat.ToString128() + "\r\n";
				ad = Int128.Add(ad, Int128.Convert(0x10));
			}
			dumpBox.Text = str;
			timer1.Enabled = false;
		}

		private void Form1_KeyDown(object sender, KeyEventArgs e)
		{
			if (e.Control && e.KeyCode == Keys.C)
			{
				BreakPressed = true;
				e.SuppressKeyPress = true;
			}
			else if (e.KeyCode == Keys.F10)
			{
				e.SuppressKeyPress = true;
				soc.Step();
				UpdateRegisters();
				//Application.DoEvents();
			}
		}

		private void menuStrip1_KeyDown(object sender, KeyEventArgs e)
		{
			Form1_KeyDown(sender, e);
		}

		private void textBox1_TextChanged(object sender, EventArgs e)
		{
			timer1.Enabled = true;
		}

		private void numericUpDown1_ValueChanged(object sender, EventArgs e)
		{
			regset = Convert.ToInt32(numericUpDown1.Value) * 64;
			UpdateRegisters();
		}

		private void runForToolStripMenuItem_Click(object sender, EventArgs e)
		{
			frmRunFor rf = new frmRunFor();
			if (rf.ShowDialog() == DialogResult.OK)
			{
				count = rf.count;
				BreakPressed = false;
				for (; count > 0; count--)
				{
					if (BreakPressed)
						count = 0;
					soc.Step();
					UpdateRegisters();
					if ((count & 63) == 0)
						Application.DoEvents();
				}
			}
		}
	}
}
