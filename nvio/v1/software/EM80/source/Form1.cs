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
		public SoC soc = new SoC();
		TextBox[] registerBoxes;
		TextBox ipBox = new TextBox();
		TextBox iBundleBox = new TextBox();
		TextBox dumpBox = new TextBox();
		TextBox tbAddr = new TextBox();
		dump dmp = new dump();
		dump stk = new dump();
		LED[] leds;
		int regset;
		int count;
		bool BreakPressed;
		int dumpStride;
		int dumpType;
		bool trackIP;

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

			dumpStride = 16;
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
				dmp.Name = "dumpBox";
				dmp.Location = new Point(780, 60);
				dmp.Size = new System.Drawing.Size(330, 190);
				dmp.TabIndex = 67;
				//dmp.Multiline = true;
				//dmp.AcceptsReturn = true;
				//dumpBox.MaxLength = 10000000;
				dmp.Font = new Font("Courier New", 7.0f);
				dmp.Text = "0";
				//dumpBox.ScrollBars = ScrollBars.Vertical;
				this.Controls.Add(dmp);
				stk.Name = "stkBox";
				stk.Location = new Point(780, 280);
				stk.Size = new System.Drawing.Size(330, 190);
				stk.TabIndex = 68;
				//dmp.Multiline = true;
				//dmp.AcceptsReturn = true;
				//dumpBox.MaxLength = 10000000;
				stk.Font = new Font("Courier New", 7.0f);
				stk.Text = "0";
				//dumpBox.ScrollBars = ScrollBars.Vertical;
				this.Controls.Add(stk);
				/*
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
				*/
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
			label4.Text = Convert.ToString(soc.cpu.icount, 10);
			UpdateRegisters();
			Application.DoEvents();
		}

		private void rOMToolStripMenuItem_Click(object sender, EventArgs e)
		{
			timer1.Enabled = true;
		}

		private nvioCpu.e_unitTypes GetUnit(Int128 ad)
		{
			nvioCpu.e_unitTypes unit0;
			nvioCpu.e_unitTypes unit1;
			nvioCpu.e_unitTypes unit2;
			Int128 bund;
			int tmp;

			bund = soc.IFetch(ad);
			tmp = (int)(bund.digits[3] >> 24) & 0x7f;
			if (tmp == 0x7D)
			{
				unit0 = nvioCpu.e_unitTypes.I;
				unit1 = nvioCpu.e_unitTypes.N;
				unit2 = nvioCpu.e_unitTypes.N;
			}
			else if (tmp == 0x7E)
			{
				unit0 = nvioCpu.e_unitTypes.F;
				unit1 = nvioCpu.e_unitTypes.N;
				unit2 = nvioCpu.e_unitTypes.N;
			}
			else if (tmp == 0x7F)
			{
				unit0 = nvioCpu.e_unitTypes.M;
				unit1 = nvioCpu.e_unitTypes.N;
				unit2 = nvioCpu.e_unitTypes.N;
			}
			else
			{
				tmp &= 63;
				unit0 = nvioCpu.unitx[tmp, 0];
				unit1 = nvioCpu.unitx[tmp, 1];
				unit2 = nvioCpu.unitx[tmp, 2];
			}
			switch ((ad.digits[0] & 15))
			{
				case 0:
					return unit0;
				case 5:
					return unit1;
				case 10:
					return unit2;
				default:
					return unit0;
			}
		}
		private UInt64 GetInstr(Int128 ad)
		{
			Int128 ibundle;
			UInt64 insn0, insn1, insn2;

			ibundle = soc.IFetch(ad);
			insn0 = ibundle.digits[0];
			insn0 |= ((ibundle.digits[1] & 0xffL) << 32);
			insn1 = ibundle.digits[1] >> 8;
			insn1 |= (ibundle.digits[2] << 24) & 0xffff000000L;
			insn2 = ibundle.digits[2] >> 16;
			insn2 |= (ibundle.digits[3] << 16) & 0xffffff0000L;
			switch(ad.digits[0] & 15)
			{
				case 0: return insn0;
				case 5: return insn1;
				case 10: return insn2;
				default: return insn0;
			}
		}
		private void timer1_Tick(object sender, EventArgs e)
		{
			string str;
			int nn;
			Int128 ad = new Int128(textBox1.Text);
			Int128 dat;

			trackIP = checkBox1.Checked;
			if (trackIP)
				ad = Int128.Sub(soc.cpu.ip, Int128.Convert(0x20));
			//dumpBox.Clear();
			str = "";
			nn = 0;
			for (nn = 0; nn < 50; nn++)
			{
				dat = soc.Read(ad);
				switch (dumpType) {
					case 0:
						switch (dumpStride)
						{
							case 1:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80().Substring(18, 2) + "\r\n";
								break;
							case 2:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80().Substring(16, 4) + "\r\n";
								break;
							case 4:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80().Substring(12, 8) + "\r\n";
								break;
							case 5:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80().Substring(10, 10) + "\r\n";
								break;
							case 8:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80().Substring(4, 16) + "\r\n";
								break;
							case 10:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80() + "\r\n";
								break;
							case 16:
								str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString128() + "\r\n";
								break;
						}
						break;
					case 1:
						if (Int128.EQ(ad, soc.cpu.ip))
							str = str + "h";
						else
							str = str + " ";
						str = str + nvioCpu.Disassemble(soc.cpu.ibundle, GetUnit(ad), (Int64)GetInstr(ad), ad) + "\n";
						break;
				}
				if (trackIP)
					ad = nvioCpu.IncAd(ad, 5);
				else
					ad = Int128.Add(ad, Int128.Convert(dumpStride));
			}
			dmp.SetText(str);
			dmp.Invalidate();
			ad = Int128.Sub(soc.cpu.regfile[(soc.cpu.regset << 6)|63], Int128.Convert(40));
			str = "";
			for (nn = 0; nn < 25; nn++)
			{
				dat = soc.Read(ad);
				if (Int128.EQ(ad, soc.cpu.regfile[(soc.cpu.regset << 6) | 63]))
					str = str + "h";
				else
					str = str + " ";
				str = str + Convert.ToString((long)ad.digits[0], 16).PadLeft(6, '0') + ": " + dat.ToString80() + "\r\n";
				ad = Int128.Add(ad, Int128.Convert(10));
			}
			stk.SetText(str);
			stk.Invalidate();
			if (trackIP)
				timer1.Interval = 10;
			else
				timer1.Interval = 100;
			timer1.Enabled = trackIP;
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
				label4.Text = Convert.ToString(soc.cpu.icount, 10);
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

		private void checkBox1_CheckedChanged(object sender, EventArgs e)
		{
			dumpType = 1;
			timer1.Enabled = true;
		}

		private void radioButton4_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 16;
			timer1.Enabled = true;
		}

		private void radioButton1_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 10;
			timer1.Enabled = true;
		}

		private void radioButton3_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 8;
			timer1.Enabled = true;
		}

		private void radioButton2_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 5;
			timer1.Enabled = true;
		}

		private void radioButton5_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 4;
			timer1.Enabled = true;
		}

		private void radioButton7_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 1;
			timer1.Enabled = true;
		}

		private void radioButton6_CheckedChanged(object sender, EventArgs e)
		{
			dumpStride = 2;
			timer1.Enabled = true;
		}

		private void radioButton9_CheckedChanged(object sender, EventArgs e)
		{
			dumpType = 1;
			timer1.Enabled = true;
		}

		private void radioButton8_CheckedChanged(object sender, EventArgs e)
		{
			dumpType = 0;
			timer1.Enabled = true;
		}

		private void textScreenToolStripMenuItem_Click(object sender, EventArgs e)
		{
			frmTextController tc = new frmTextController();
			tc.form1 = this;
			tc.Show();
		}
	}
}
