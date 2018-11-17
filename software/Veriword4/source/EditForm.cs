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
	public partial class EditForm : Form
	{
		String txt;

		public EditForm()
		{
			InitializeComponent();
		}

		private void pictureBox1_Paint(object sender, PaintEventArgs e)
		{
			using (Font myFont = new Font("Courier New", 8))
			{
				e.Graphics.DrawString("Hello .NET Guide!", myFont, Brushes.Green, new Point(2, 2));
			}
		}

		private void openToolStripMenuItem_Click(object sender, EventArgs e)
		{
			if (openFileDialog1.ShowDialog() == DialogResult.OK)
			{
				txt = System.IO.File.ReadAllText(openFileDialog1.FileName);

			}
		}
	}
}
