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
	public partial class frmF : Form
	{
		public bool fma;
		public int floatsz;
		public string cap;
		public string capn;

		public frmF()
		{
			InitializeComponent();
			floatsz = 32;
		}

		private void SetChecks(Control gctrl)
		{
			if (cap is null)
				return;
			if (cap.Length < 1)
				return;
			foreach (Control ctrl in gctrl.Controls)
			{
				if (ctrl.Name.Length > 7)
				{
					if (ctrl.Name.Substring(0, 8) == "checkBox")
					{
						CheckBox cb = (CheckBox)ctrl;
						if (cap.Contains((string)cb.Tag))
							cb.Checked = true;
						else
							cb.Checked = false;
					}
				}
			}
		}

		private void checkBox1_CheckedChanged(object sender, EventArgs e)
		{
			fma = checkBox1.Checked;
		}

		private void numericUpDown1_ValueChanged(object sender, EventArgs e)
		{
			floatsz = Convert.ToInt32(numericUpDown1.Value);
		}

		private void ProcessGroupBox(Control gctrl)
		{
			foreach (Control ctrl in gctrl.Controls)
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
				}
			}
		}
		private void button1_Click(object sender, EventArgs e)
		{
			cap = "";
			capn = "";
			foreach (Control ctrl in this.Controls)
			{
				if (ctrl.Name.Length > 7)
				{
					if (ctrl.Name.Substring(0, 8) == "groupBox")
					{
						ProcessGroupBox(ctrl);
					}
				}
			}
		}

		private void frmF_Activated(object sender, EventArgs e)
		{
			foreach (Control ctrl in this.Controls)
			{
				if (ctrl.Name.Length > 7)
				{
					if (ctrl.Name.Substring(0, 8) == "groupBox")
					{
						SetChecks(ctrl);
					}
				}
			}
		}
	}
}
