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
	public partial class frmMemmgnt : Form
	{
		public string cap;
		public string capn;
		int lastval;
		int units;

		public frmMemmgnt()
		{
			InitializeComponent();
			units = 2;
			label7.Text = "MB";
			comboBox3.SelectedIndex = 0;
			comboBox4.SelectedIndex = 1;
		}

		private void button1_Click(object sender, EventArgs e)
		{
			cap = "";
			capn = "";
			foreach (Control ctrl in this.Controls)
			{
				if (ctrl.Name.Length > 7)
				{
					if (ctrl.Name.Substring(0, 8) == "checkBox")
					{
						CheckBox cb = (CheckBox)ctrl;
						if (cb.Checked)
							cap += cb.Tag + ",";
						else
							capn += cb.Tag + ",";
					}
					else if (ctrl.Name.Substring(0,8) == "comboBox")
					{
						ComboBox cb = (ComboBox)ctrl;
						cap += cb.Tag + "=" + '"' + cb.Text + '"'+",";
					}
					else if (ctrl.Name.Substring(0,8)=="numericU")
					{
						NumericUpDown nu = (NumericUpDown)ctrl;
						cap += nu.Tag + "=" + '"' + nu.Value + '"' + ",";
					}
				}
			}
		}

		private void checkBox1_CheckedChanged(object sender, EventArgs e)
		{
			if (checkBox1.Checked)
			{
				frmBank fm = new frmBank();
				if (fm.ShowDialog() == DialogResult.OK)
				{

				}
			}
		}

		private void UpdatePagesize()
		{
			Int64 memsize;
			Int64 pagesz;
			double n = Convert.ToDouble(numericUpDown2.Value);
			memsize = (Int64)(n * (Math.Pow(1024.0, units)));
			pagesz = memsize / Convert.ToInt64((comboBox3.Text));
			textBox1.Text = pagesz.ToString();
		}
		private void numericUpDown2_ValueChanged(object sender, EventArgs e)
		{
			int[] sz = { 0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024 };
			string[] uns = { "B", "kB", "MB", "GB", "TB", "XB" };
			int x;
			int newval;

			newval = Convert.ToInt16(numericUpDown2.Value);
			if (newval == 0)
			{
				if (units > 0)
				{
					units--;
					label7.Text = uns[units];
					numericUpDown2.Value = 512;
					lastval = 513;
				}
			}
			else if (newval == 513)
			{
				if (units < 5)
				{
					units++;
					label7.Text = uns[units];
					numericUpDown2.Value = 1;
					lastval = 0;
				}
				else
					numericUpDown2.Value = 512;
			}
			else
			{
				for (x = 1; x < 11; x++)
				{
					if (newval > sz[x] && newval <= sz[x + 1] && lastval < newval)
					{
						numericUpDown2.Value = sz[x + 1];
						break;
					}
					else if (newval < sz[x] && newval >= sz[x - 1] && lastval > newval)
					{
						numericUpDown2.Value = sz[x - 1];
						break;
					}
				}
				lastval = newval;
				UpdatePagesize();
			}
		}

		private void comboBox3_SelectedIndexChanged(object sender, EventArgs e)
		{
			UpdatePagesize();
		}
	}
}
