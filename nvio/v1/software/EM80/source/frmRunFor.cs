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
	public partial class frmRunFor : Form
	{
		public int count;
		public frmRunFor()
		{
			InitializeComponent();
		}

		private void frmRunFor_Load(object sender, EventArgs e)
		{

		}

		private void numericUpDown1_ValueChanged(object sender, EventArgs e)
		{
			count = Convert.ToInt32(numericUpDown1.Value);
		}
	}
}
