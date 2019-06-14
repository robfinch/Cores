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
	public partial class LED : UserControl
	{
		public Color darkColor;
		public Color lightColor;
		public Rectangle drawRectangle;
		public Rectangle whiteRectangle;
		public bool on;

		public LED()
		{
			InitializeComponent();
			SetStyle(ControlStyles.DoubleBuffer
			| ControlStyles.AllPaintingInWmPaint
			| ControlStyles.ResizeRedraw
			| ControlStyles.UserPaint
			| ControlStyles.SupportsTransparentBackColor, true
			);
			darkColor = Color.DarkGreen;
			lightColor = Color.Green;
			drawRectangle = new Rectangle(4, 4, 20, 20);
			whiteRectangle = new Rectangle(4, 4, 10, 10);
		}

		private void drawControl(Graphics g)
		{
			if (on)
			{
				darkColor = Color.Green;
				lightColor = Color.LightGreen;
			}
			else
			{
				darkColor = Color.DarkGreen;
				lightColor = Color.Green;
			}
			// Fill in the background circle 
			g.FillEllipse(new SolidBrush(darkColor), drawRectangle);

			// Draw the glow gradient
			GraphicsPath path = new GraphicsPath();
			path.AddEllipse(drawRectangle);
			PathGradientBrush pathBrush = new PathGradientBrush(path);
			pathBrush.CenterColor = lightColor;
			pathBrush.SurroundColors = new Color[] { Color.FromArgb(0, lightColor) };
			g.FillEllipse(pathBrush, drawRectangle);

			// Set the clip boundary to the edge of the ellipse
			GraphicsPath gp = new GraphicsPath();
			gp.AddEllipse(drawRectangle);
			g.SetClip(gp);

			// Draw the white reflection gradient
			GraphicsPath path1 = new GraphicsPath();
			path1.AddEllipse(whiteRectangle); // a smaller rectangle set to the top left
			PathGradientBrush pathBrush1 = new PathGradientBrush(path);
			pathBrush1.CenterColor = Color.FromArgb(180, 255, 255, 255);
			pathBrush1.SurroundColors = new Color[] { Color.FromArgb(0, 255, 255, 255) };
			g.FillEllipse(pathBrush1, whiteRectangle);
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

		private void LED_SizeChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
			whiteRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width / 2, this.ClientRectangle.Height / 2);
		}

		private void LED_LocationChanged(object sender, EventArgs e)
		{
			drawRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width, this.ClientRectangle.Height);
			whiteRectangle = new Rectangle(this.ClientRectangle.X, this.ClientRectangle.Y, this.ClientRectangle.Width / 2, this.ClientRectangle.Height / 2);
		}

		public void On()
		{
			darkColor = Color.Green;
			lightColor = Color.LightGreen;
		}

		public void Off()
		{
			darkColor = Color.DarkGreen;
			lightColor = Color.Green;
		}
	}
}
