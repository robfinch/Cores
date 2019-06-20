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
	public partial class frmTextController : Form
	{
		public Form1 form1;
		TextController tc = new TextController();

		public frmTextController()
		{
			InitializeComponent();
			tc.Name = "textController";
			tc.Location = new Point(4, 4);
			tc.Size = new System.Drawing.Size(700, 360);
			tc.TabIndex = 1;
			//dmp.Multiline = true;
			//dmp.AcceptsReturn = true;
			//dumpBox.MaxLength = 10000000;
			tc.Font = new Font("Courier New", 7.0f);
			tc.Text = "0";
			//dumpBox.ScrollBars = ScrollBars.Vertical;
			this.Controls.Add(tc);
		}

		private Color Convert444(int color444)
		{
			int R, G, B;
			R = ((color444 >> 8) & 0xf) << 4;
			G = ((color444 >> 4) & 0xf) << 4;
			B = (color444 & 0xf) << 4;
			Color clr = Color.FromArgb(R,G,B);
			return clr;
		}
		public void UpdateScreen()
		{
			int row, col;
			int ndx;

			for (ndx = 0; ndx < 1624; ndx++)
			{
				row = ndx / 56;
				col = ndx % 56;
				tc.mem[row, col] = (char)(form1.soc.textmem[ndx] & 0x7f);
				tc.bkcolor[row,col] = Convert444((int)((form1.soc.textmem[ndx] >> 16) & 0xfff));
				tc.fgcolor[row, col] = Convert444((int)((form1.soc.textmem[ndx] >> 32) & 0xfff));
				tc.Invalidate();
			}
		}

		private void frmTextController_Load(object sender, EventArgs e)
		{

		}

		private void timer1_Tick(object sender, EventArgs e)
		{
			UpdateScreen();
		}
	}
}
