using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Opcode
{
	enum e_memop : long {
		I_MLX = 0x0f,
		I_MSX = 0x2f,
	}
	enum e_memfn : long
	{
		I_STBX = 0x00,
		I_STWX = 0x01,
	}
	public partial class Form1 : Form
	{
		public Form1()
		{
			InitializeComponent();
		}

		private void button1_Click(object sender, EventArgs e)
		{
			Int64 n;
			Int64 imm;
			Int64 bt;

			n = Convert.ToInt64(textBox1.Text,16);
			label3.Text = Convert.ToString(n, 16);
			imm = ((n >> 16) & 0x7fffL) | (((n >> 33) & 0x7fL) << 15);
			label1.Text = Convert.ToString(imm,16);
			label5.Text = Convert.ToString((n >> 10) & 63L);
			label7.Text = Convert.ToString((n >> 16) & 63L);
			label9.Text = Convert.ToString((n >> 22) & 63L);
			label11.Text = Convert.ToString(n & 63L);
			bt = ((n >> 3) & 7L) | ((n >> 22) << 3);
			bt = (bt << 2) | (bt & 3L);
			label13.Text = Convert.ToString(bt, 16);
			label14.Text = MemOpcode(n);
		}

		private void button2_Click(object sender, EventArgs e)
		{
			Int64 n;
			Int64 imm;
			Int64 bt;

			n = Convert.ToInt64(textBox1.Text, 16);
			label3.Text = Convert.ToString(n, 16);
			imm = ((n >> 16) & 0x7fffL) | (((n >> 33) & 0x7fL) << 15);
			imm = imm << 22;
			label1.Text = Convert.ToString(imm, 16);
			label5.Text = Convert.ToString((n >> 10) & 63L);
			label7.Text = Convert.ToString((n >> 16) & 63L);
			label9.Text = Convert.ToString((n >> 22) & 63L);
			label11.Text = Convert.ToString(n & 63L);
			bt = ((n >> 3) & 7L) | ((n >> 22) << 3);
			bt = (bt << 2) | (bt & 3L);
			label13.Text = Convert.ToString(bt,16);
		}

		private string WhichUnit(long n)
		{
			switch(n)
			{
				case 0: return "`NUnit";
				case 1: return "`BUnit";
				case 2: return "`IUnit";
				case 3: return "`FUnit";
				case 4: return "`MUnit";
				default: return "`NUnit";
			}
		}

		private string WhichUnitChar(long n)
		{
			switch (n)
			{
				case 0: return "N";
				case 1: return "B";
				case 2: return "I";
				case 3: return "F";
				case 4: return "M";
				default: return "N";
			}
		}

		private string MemOpcode(long n)
		{
			long opcode;
			long func;

			opcode = (((n >> 33) & 3L) << 4) | ((n >> 6) & 15L);
			func = ((n >> 35) & 31);
			switch(opcode)
			{
				case (long)e_memop.I_MSX:
					switch(func)
					{
						case (long)e_memfn.I_STBX:	return "stbx";
						case (long)e_memfn.I_STWX: return "stwx";
					}
					break;
			}
			return "???";
		}

		private void button3_Click(object sender, EventArgs e)
		{
			long n;
			string str, str1, str2, str3;
			string c;

			str = "";
			c = "";
			for (n = 0; n < 64; n++)
			{
				str1 = Convert.ToString(n & 3, 16);
				str2 = Convert.ToString((n >> 2) & 3, 16);
				str3 = Convert.ToString((n >> 4) & 3, 16);
				//str = str + str1.PadLeft(2, '0') + str2.PadLeft(2, '0') + str3.PadLeft(2, '0') + "\r\n";
				str = str + "7'h" + Convert.ToString(n,16) + ": fnUnits = {" + WhichUnit((n & 3) + 1) + "," + WhichUnit(((n >> 2) & 3) + 1) + "," + WhichUnit(((n >> 4) & 3) + 1) + "};\r\n";
				c = c + "{" + WhichUnitChar((n & 3) + 1) + "," + WhichUnitChar(((n >> 2) & 3) + 1) + "," + WhichUnitChar(((n >> 4) & 3) + 1) + "},\r\n";
			}
			textBox2.Text = str;
			textBox3.Text = c;
		}

		private void approximationsToolStripMenuItem_Click(object sender, EventArgs e)
		{
			ApproximationsForm form = new ApproximationsForm();
			form.Show();
		}
	}
}
