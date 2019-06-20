using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing.Drawing2D;

namespace EM80
{
	public partial class TextController : UserControl
	{
		public Rectangle drawRectangle;
		public SolidBrush textbr;
		public char[,] mem;
		public Color[,] bkcolor;
		public Color[,] fgcolor;

		public TextController()
		{
			int row, col;
			Random random = new Random();

			InitializeComponent();
			SetStyle(ControlStyles.DoubleBuffer
			| ControlStyles.AllPaintingInWmPaint
			| ControlStyles.ResizeRedraw
			| ControlStyles.UserPaint
			| ControlStyles.SupportsTransparentBackColor, true
			);
			mem = new char[29, 56];
			bkcolor = new Color[29, 56];
			fgcolor = new Color[29, 56];
			for (row = 0; row < 29; row++)
			{
				for (col = 0; col < 56; col++)
				{
					bkcolor[row, col] = Color.FromArgb(random.Next());
					fgcolor[row, col] = Color.FromArgb(random.Next());
					mem[row, col] = (char)(random.Next() & 0x7f);
				}
			}
			drawRectangle = new Rectangle(4, 4, 700, 360);
			textbr = new SolidBrush(Color.LightGray);
//			texthilite = new SolidBrush(Color.White);
//			backbr = new SolidBrush(Color.DarkGreen);
//			stra = new string[1];
//			stra[0] = " ";
		}
		private void drawControl(Graphics g)
		{
			int x, y, w, h;
			int row, col;
			string str;

			// Fill in the background circle 
			for (row = 0; row < 29; row++)
			{
				for (col = 0; col < 56; col++)
				{
					g.FillRectangle(new SolidBrush(bkcolor[row, col]), col * 12, row * 12, 12, 12);
					str = mem[row, col].ToString();
					g.DrawString(str.Substring(0, 1), this.Font, new SolidBrush(fgcolor[row, col]), new Point(col * 12, row * 12));
				}
			}
//			g.FillRectangle(new SolidBrush(this.BackColor), drawRectangle);

			//x = 4;
			//y = 4;
			//w = this.ClientRectangle.Width - 4;
			//h = this.FontHeight;
			//foreach (string str in stra)
			//{
			//	if (str.Substring(0, 1) == "h")
			//		g.DrawString(str.Substring(1), this.Font, texthilite, new Point(x, y));
			//	else
			//		g.DrawString(str.Substring(1), this.Font, textbr, new Point(x, y));
			//	y += h;
			//}
		}
		protected override void OnPaint(PaintEventArgs e)
		{
			// Create an offscreen graphics object for double buffering
			Bitmap offScreenBmp = new Bitmap(this.ClientRectangle.Width,
									this.ClientRectangle.Height);
			System.Drawing.Graphics g = Graphics.FromImage(offScreenBmp);
			g.SmoothingMode = SmoothingMode.HighQuality;

			// Render the control to the off-screen bitmap
			drawControl(g);

			// Draw the image to the screen
			e.Graphics.DrawImageUnscaled(offScreenBmp, 0, 0);
		}

		private void TextController_LocationChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
		}

		private void TextController_SizeChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
		}
	}
}
