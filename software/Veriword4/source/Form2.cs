using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Veriword4
{
	public partial class Form2 : Form
	{
		public Form2()
		{
			InitializeComponent();
		}

		private void openToolStripMenuItem_Click(object sender, EventArgs e)
		{
		}

		private void Form2_Load(object sender, EventArgs e)
		{
			Form1 frm1 = new Form1();
			frm1.MdiParent = this;
			frm1.Show();
		}

		private void newWindowToolStripMenuItem_Click(object sender, EventArgs e)
		{
			Form1 frm1 = new Form1();
			frm1.MdiParent = this;
			frm1.Show();
		}
	}
}
