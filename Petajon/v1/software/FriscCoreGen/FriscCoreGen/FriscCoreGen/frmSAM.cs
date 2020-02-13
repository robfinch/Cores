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
	public partial class frmSAM : Form
	{
		public frmSAM()
		{
			InitializeComponent();
		}

		private void numericUpDown3_ValueChanged(object sender, EventArgs e)
		{
			label5.Text = Convert.ToString(Math.Pow(2,Convert.ToDouble(numericUpDown3.Value)));
		}

		private void timer1_Tick(object sender, EventArgs e)
		{
			long mem = (long)(Math.Pow(2, Convert.ToDouble(numericUpDown3.Value)) *
								 Math.Pow(2, Convert.ToDouble(numericUpDown4.Value)));
			label7.Text = Convert.ToString(mem) + " Bytes";
		}
	}
}
