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
	public partial class dump : UserControl
	{
		public Rectangle drawRectangle;
		public string[] stra;
		public SolidBrush textbr;
		public SolidBrush backbr;
		public SolidBrush texthilite;
	
		public dump()
		{
			InitializeComponent();
			SetStyle(ControlStyles.DoubleBuffer
			| ControlStyles.AllPaintingInWmPaint
			| ControlStyles.ResizeRedraw
			| ControlStyles.UserPaint
			| ControlStyles.SupportsTransparentBackColor, true
			);
			drawRectangle = new Rectangle(4, 4, 200, 400);
			textbr = new SolidBrush(Color.LightGray);
			texthilite = new SolidBrush(Color.White);
			backbr = new SolidBrush(Color.DarkGreen);
			stra = new string[1];
			stra[0] = " ";
		}
		public void SetText(string txt)
		{
			char[] cha = new char[1];
			cha[0] = '\n';
			stra = txt.Split(cha,25);
		}
		private void drawControl(Graphics g)
		{
			int x, y, w, h;

			// Fill in the background circle 
			g.FillRectangle(new SolidBrush(this.BackColor), drawRectangle);

			x = 4;
			y = 4;
			w = this.ClientRectangle.Width - 4;
			h = this.FontHeight;
			foreach (string str in stra)
			{
				if (str.Substring(0,1)=="h")
					g.DrawString(str.Substring(1), this.Font, texthilite, new Point(x, y));
				else
					g.DrawString(str.Substring(1), this.Font, textbr, new Point(x,y));
				y += h;
			}
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

		private void dump_LocationChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
		}

		private void dump_SizeChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
		}
	}
}
