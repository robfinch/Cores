using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FriscCoreGen
{
	public partial class Form1 : Form
	{
		string[] lines;
		string[] plines;
		bool fma;
		int floatsz;
		string MCap, MCapn;
		string Fcap, Fcapn;
		string MMcap, MMcapn;

		public Form1()
		{
			InitializeComponent();
			fma = true;
			MCap = "MUL,MULH,MULHSU,MULHU,DIV,DIVU,REM,REMU,";
			MCapn = "";
			Fcap = "FCLASS,FCVTXS,FCVTXS,FCVTSWU,FCVTSW,FCVTWUS,FCVTWS,FLT,FLE,FEQ,FMAX,FMIN,FSGNJX,FSGNJN,FSGNJ,FMUL,FDIV,FADD,FSQRT,FMA,";
			Fcapn = "FRES,FSQRTE,FSIGMOID,";
			MMcap = "PFI,WFI,EBREAK,";
			MMcapn = "";
			floatsz = 32;
		}

		private void FilterPos(string ext)
		{
			int n, k;
			int l = ext.Length + 3;

			for (k = n = 0; n < lines.Count(); n = n + 1)
			{
				if (lines[n].Length >= l)
				{
					if (lines[n].Substring(0, l) == "{+" + ext + "}" || lines[n].Substring(0, l) == "{-" + ext + "}")
					{
						lines[n] = "";
						continue;
					}
				}
				if (lines[n].Length >= l)
				{
					if (lines[n].Substring(0, l) == "{!" + ext + "}")
					{
						do
						{
							if (lines[n].Length >= l)
							{
								if (lines[n].Substring(0, l) == "{-" + ext + "}")
								{
									n++;
									break;
								}
							}
							n++;
						} while (n < lines.Count());
					}
				}
				lines[k] = lines[n];
				k++;
			}
			Array.Resize<string>(ref lines, k);
		}

		private void FilterNeg(string ext)
		{
			int n, k;
			int l = ext.Length + 3;

			for (k = n = 0; n < lines.Count(); n++)
			{
				if (lines[n].Length >= l)
				{
					if (lines[n].Substring(0, l) == "{!"+ext+"}")
					{
						n++;
						do
						{
							if (lines[n].Length >= l)
							{
								if (lines[n].Substring(0, l) == "{-"+ext+"}")
								{
									n++;
									break;
								}
							}
							lines[k] = lines[n];
							k++;
							n++;
						} while (n < lines.Count());
					}
					if (lines[n].Substring(0, l) == "{+"+ext+"}")
					{
						do
						{
							if (lines[n].Length >= l)
								if (lines[n].Substring(0, l) == "{-"+ext+"}")
									break;
							n++;
						} while (n < lines.Count());
					}
					else
					{
						lines[k] = lines[n];
						k++;
					}
				}
				else
				{
					lines[k] = lines[n];
					k++;
				}
			}
			Array.Resize<string>(ref lines, k);
		}

		private void button1_Click(object sender, EventArgs e)
		{
			string[] Mops;
			char[] cha;
			Cursor.Current = Cursors.WaitCursor;
			lines = System.IO.File.ReadAllLines("../../../../template/friscv_wb.sv");
			if (radioButton1.Checked)
				FilterPos("RV32I");
			else
				FilterNeg("RV32I");
			if (radioButton2.Checked)
				FilterPos("RV64I");
			else
				FilterNeg("RV64I");
			if (checkBox1.Checked)
				FilterPos("A");
			else
				FilterNeg("A");
			if (checkBox4.Checked)
				FilterPos("M");
			else
				FilterNeg("M");
			if (checkBox2.Checked)
				FilterPos("F");
			else
				FilterNeg("F");
			if (checkBox22.Checked)
				FilterPos("U");
			else
				FilterNeg("U");
			if (fma)
				FilterPos("FMA");
			else
				FilterNeg("FMA");
			if (checkBox23.Checked)
				FilterPos("PGMAP");
			else
				FilterNeg("PGMAP");
			if (checkBox24.Checked)
				FilterPos("NSIMM");
			else
				FilterNeg("NSIMM");
			if (checkBox25.Checked)
				FilterPos("PAM");
			else
				FilterNeg("PAM");
			if (checkBox26.Checked)
				FilterPos("SEG");
			else
				FilterNeg("SEG");
			cha = new char[1];
			cha[0] = ',';
			Mops = MCap.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterPos(op);
			}
			Mops = MCapn.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterNeg(op);
			}
			Mops = Fcap.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterPos(op);
			}
			Mops = Fcapn.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterNeg(op);
			}
			Mops = MMcap.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterPos(op);
			}
			Mops = MMcapn.Split(cha);
			foreach (string op in Mops)
			{
				if (op.Length > 0)
					FilterNeg(op);
			}
			System.IO.File.WriteAllLines("../../../../product/friscv.sv", lines);
			Cursor.Current = Cursors.Default;
		}

		private void linkLabel1_Click(object sender, EventArgs e)
		{
			frmF f = new frmF();
			f.fma = fma;
			f.floatsz = floatsz;
			f.cap = Fcap;
			f.capn = Fcapn;
			if (f.ShowDialog() == DialogResult.OK)
			{
				fma = f.fma;
				floatsz = f.floatsz;
				Fcap = f.cap;
				Fcapn = f.capn;
			}
		}

		private void checkBox2_CheckedChanged(object sender, EventArgs e)
		{
			linkLabel1.Enabled = checkBox2.Checked;
		}

		private void checkBox11_CheckedChanged(object sender, EventArgs e)
		{
			if (checkBox11.Checked)
			{
				frmBank fm = new frmBank();
				if (fm.ShowDialog() == DialogResult.OK) {

				}
			}
		}

		private void linkLabel2_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
		{
			if (checkBox4.Checked)
			{
				frmM fm = new frmM();
				fm.cap = MCap;
				fm.capn = MCapn;
				if (fm.ShowDialog() == DialogResult.OK)
				{
					MCap = fm.cap;
					MCapn = fm.capn;
				}
			}
		}

		private void linkLabel3_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
		{
			frmMM fm = new frmMM();
			fm.cap = MMcap;
			fm.capn = MMcapn;
			if (fm.ShowDialog()==DialogResult.OK)
			{
				MMcap = fm.cap;
				MMcapn = fm.capn;
			}
		}

		private void checkBox22_CheckedChanged(object sender, EventArgs e)
		{

		}

		private void checkBox19_CheckedChanged(object sender, EventArgs e)
		{
			if (checkBox19.Checked)
			{
				frmSAM fm = new frmSAM();
				if (fm.ShowDialog() == DialogResult.OK)
				{

				}
			}
		}

		private void radioButton11_CheckedChanged(object sender, EventArgs e)
		{

		}

		private void checkBox4_CheckedChanged(object sender, EventArgs e)
		{
			linkLabel2.Enabled = checkBox4.Checked;
		}
	}
}
