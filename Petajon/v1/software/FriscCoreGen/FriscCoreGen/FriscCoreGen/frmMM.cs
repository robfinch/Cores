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
	public partial class frmMM : Form
	{
		public string cap;
		public string capn;
	
		public frmMM()
		{
			InitializeComponent();
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
				}
			}
		}
	}
}
