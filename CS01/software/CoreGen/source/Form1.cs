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

		public Form1()
		{
			InitializeComponent();
		}

		private void FilterPos(string ext)
		{
			int n, k;

			for (k = n = 0; n < lines.Count(); n = n + 1)
			{
				if (lines[n].Length >= 4)
				{
					if (lines[n].Substring(0, 4) == "{+" + ext + "}" || lines[n].Substring(0, 4) == "{-" + ext + "}")
					{
						lines[n] = "";
						continue;
					}
				}
				if (lines[n].Length >= 4)
				{
					if (lines[n].Substring(0, 4) == "{!" + ext + "}")
					{
						do
						{
							if (lines[n].Length >= 4)
							{
								if (lines[n].Substring(0, 4) == "{-" + ext + "}")
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

			for (k = n = 0; n < lines.Count(); n++)
			{
				if (lines[n].Length >= 4)
				{
					if (lines[n].Substring(0, 4) == "{!"+ext+"}")
					{
						n++;
						do
						{
							if (lines[n].Length >= 4)
							{
								if (lines[n].Substring(0, 4) == "{-"+ext+"}")
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
					if (lines[n].Substring(0, 4) == "{+"+ext+"}")
					{
						do
						{
							if (lines[n].Length >= 4)
								if (lines[n].Substring(0, 4) == "{-"+ext+"}")
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
			Cursor.Current = Cursors.WaitCursor;
			lines = System.IO.File.ReadAllLines("../../../../template/friscv_p.sv");
			if (checkBox2.Checked)
				FilterPos("F");
			else
				FilterNeg("F");
			if (checkBox22.Checked)
				FilterPos("U");
			else
				FilterNeg("U");
			System.IO.File.WriteAllLines("../../../../product/friscv.sv", lines);
			Cursor.Current = Cursors.Default;
		}
	}
}
