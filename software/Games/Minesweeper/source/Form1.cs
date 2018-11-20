using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MineSweeper
{
	public partial class Form1 : Form
	{
		ButtonVars[,] buttons;
		System.Random rand;
		int count;
		int bcount;
		int numx, numy;
		int onumx, onumy;
		Image imgExplosion;
		int tick;

		public Form1()
		{
			rand = new System.Random();

			InitializeComponent();
			numx = 9;
			numy = 9;
			onumx = 9;
			onumy = 9;
			bcount = 0;
			InitMap();
			//imgExplosion = System.Drawing.Image.FromFile("..\\graphics\\explosion.png");
			imgExplosion = ResizeImage(pictureBox1.Image, pictureBox1.Image.Width/9,pictureBox1.Image.Height/9);
			listBox1.SetSelected(1,true);
		}
		/// <summary>
		/// Resize the image to the specified width and height.
		/// </summary>
		/// <param name="image">The image to resize.</param>
		/// <param name="width">The width to resize to.</param>
		/// <param name="height">The height to resize to.</param>
		/// <returns>The resized image.</returns>
		public static Bitmap ResizeImage(Image image, int width, int height)
		{
			var destRect = new Rectangle(0, 0, width, height);
			var destImage = new Bitmap(width, height);

			destImage.SetResolution(image.HorizontalResolution, image.VerticalResolution);

			using (var graphics = Graphics.FromImage(destImage))
			{
				graphics.CompositingMode = CompositingMode.SourceCopy;
				graphics.CompositingQuality = CompositingQuality.HighQuality;
				graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
				graphics.SmoothingMode = SmoothingMode.HighQuality;
				graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
				using (var wrapMode = new ImageAttributes())
				{
					wrapMode.SetWrapMode(WrapMode.TileFlipXY);
					graphics.DrawImage(image, destRect, 0, 0, image.Width, image.Height, GraphicsUnit.Pixel, wrapMode);
				}
			}
			return destImage;
		}

		public void InitMap()
		{
			int n, m;
			double mFactor = 0.15;

			switch(listBox1.SelectedIndex)
			{
				case 0: mFactor = 0.08; break;
				case 1: mFactor = 0.166; break;
				case 2: mFactor = 0.333; break;
				case 3: mFactor = 0.666; break;
				default:	mFactor = 0.08; break;
			}
			bcount = 0;
			count = 0;
			if (!(buttons is null))
			{
				for (n = 0; n < onumy; n++)
				{
					for (m = 0; m < onumx; m++)
					{
						buttons[n, m].Visible = false;
						this.Controls.Remove(buttons[n, m]);
					}
				}
			}
			buttons = new ButtonVars[numy, numx];
			for (n = 0; n < numy; n++)
			{
				for (m = 0; m < numx; m++)
				{
					buttons[n, m] = new ButtonVars();
					buttons[n, m].x = m;
					buttons[n, m].y = n;
					buttons[n, m].Location = new Point(m * 20 + 20, n * 20 + 40);
					buttons[n, m].Width = 19;
					buttons[n, m].Height = 19;
					buttons[n, m].Visible = true;
					buttons[n, m].Name = "btn" + Convert.ToString(n) + Convert.ToString(m);
					buttons[n, m].Click += new System.EventHandler(this.btn_Click);
					buttons[n, m].Paint += new System.Windows.Forms.PaintEventHandler(this.btn_Paint);
					buttons[n, m].Text = " ";
					this.Controls.Add(buttons[n, m]);
					if (rand.NextDouble() < mFactor)
					{
						buttons[n, m].bomb = 'B';
						bcount++;
					}
					else
						buttons[n, m].bomb = ' ';
				}
			}
		}
		public int CountSurroundingBombs(ButtonVars btn)
		{
			int sum = 0;
			int y = btn.y;
			int x = btn.x;

			if (y > 0)
			{
				if (x > 0)
					sum += buttons[y - 1, x - 1].bomb == 'B' ? 1 : 0;
				sum += buttons[y - 1, x].bomb == 'B' ? 1 : 0;
				if (x < numx-1)
					sum += buttons[y - 1, x + 1].bomb == 'B' ? 1 : 0;
			}
			if (x > 0)
			{
				sum += buttons[y, x - 1].bomb == 'B' ? 1 : 0;
			}
			if (x < numx-1)
				sum += buttons[y, x + 1].bomb == 'B' ? 1 : 0;
			if (y < numy-1)
			{
				if (x > 0)
					sum += buttons[y + 1, x - 1].bomb == 'B' ? 1 : 0;
				sum += buttons[y + 1, x].bomb == 'B' ? 1 : 0;
				if (x < numx-1)
					sum += buttons[y + 1, x + 1].bomb == 'B' ? 1 : 0;
			}
			return (sum);
		}
		private void Score()
		{
			int x, y;
			int score;

			score = 0;
			for (y = 0; y < numy; y++)
			{
				for (x = 0; x < numx; x++)
				{
					if (buttons[y, x].Text != " ")
						score += listBox1.SelectedIndex + 1;
				}
			}
			label2.Text = "Score: " + score.ToString();
		}

		private void btn_Click(object sender, EventArgs e)
		{
			ButtonVars btn = (ButtonVars)sender;
			int x = btn.x;
			int y = btn.y;
				
			if (btn.bomb == 'B')
			{
				btn.Text = "*";
				tick = 0;
				timer1.Enabled = true;
				Score();
				//MessageBox.Show("Boom!", "MineSweeper", MessageBoxButtons.OK);
			}
			else
			{
				btn.Text = CountSurroundingBombs(buttons[y, x]).ToString();
				if (y > 0 & x > 0) { count += buttons[y - 1, x - 1].Text == " " ? 1 : 0; buttons[y - 1, x - 1].Text = CountSurroundingBombs(buttons[y - 1, x - 1]).ToString(); }
				if (y > 0) { count += buttons[y - 1, x].Text == " " ? 1 : 0; buttons[y - 1, x].Text = CountSurroundingBombs(buttons[y - 1, x]).ToString(); }
				if (y > 0 & x < numx-1) { count += buttons[y - 1, x + 1].Text == " " ? 1 : 0; buttons[y - 1, x + 1].Text = CountSurroundingBombs(buttons[y - 1, x + 1]).ToString(); }
				if (x > 0) { count += buttons[y, x - 1].Text == " " ? 1 : 0; buttons[y, x - 1].Text = CountSurroundingBombs(buttons[y, x - 1]).ToString(); }
				if (x < numx-1) { count += buttons[y, x + 1].Text == " " ? 1 : 0; buttons[y, x + 1].Text = CountSurroundingBombs(buttons[y, x + 1]).ToString(); }
				if (y < numy-1 & x > 0) { count += buttons[y + 1, x - 1].Text == " " ? 1 : 0; buttons[y + 1, x - 1].Text = CountSurroundingBombs(buttons[y + 1, x - 1]).ToString(); }
				if (y < numy-1) { count += buttons[y + 1, x].Text == " " ? 1 : 0; buttons[y + 1, x].Text = CountSurroundingBombs(buttons[y + 1, x]).ToString(); }
				if (y < numy-1 & x < numx-1) { count += buttons[y + 1, x + 1].Text == " " ? 1 : 0; buttons[y + 1, x + 1].Text = CountSurroundingBombs(buttons[y + 1, x + 1]).ToString(); }
				count++;
				if (bcount + count >= numx * numy)
				{
					for (y = 0; y < numy; y++)
					{
						for (x = 0; x < numx; x++)
						{
							if (buttons[y, x].bomb == 'B')
								buttons[y, x].Text = "*";
							else
							{
								buttons[y,x].count = CountSurroundingBombs(buttons[y, x]);
								buttons[y,x].Text = CountSurroundingBombs(buttons[y, x]).ToString();
							}
						}
					}
					MessageBox.Show("Complete!", "MineSweeper", MessageBoxButtons.OK);
					Score();
				}
			}
		}

		private void newGameToolStripMenuItem_Click(object sender, EventArgs e)
		{
			onumx = numx;
			onumy = numy;
			InitMap();
		}

		private void timer1_Tick(object sender, EventArgs e)
		{
			int x;
			int y;
			tick++;
			for (y = 0; y < numy; y++)
			{
				for (x = 0; x < numx; x++)
					buttons[y, x].Refresh();
			}
		}

		private void btn_Paint(object sender, PaintEventArgs e)
		{
			ButtonVars btn = (ButtonVars)sender;

			if (btn.Text == "*")
			{
				RectangleF destRect = new RectangleF(0, 0, 21, 21);
				RectangleF srcRect = new RectangleF(tick * imgExplosion.Width / 13.0f, 0f, imgExplosion.Width/13.0f, imgExplosion.Height);
				e.Graphics.DrawImage(imgExplosion, destRect, srcRect, GraphicsUnit.Pixel);
				if (tick > 11)
				{
					btn.Text = " ";
					timer1.Enabled = false;
				}
			}
			//else
			//{
			//	e.Graphics.DrawString(btn.Text, new Font("Courier New", 8), Brushes.Black, 0, 0);
			//}
		}
	
		private void button1_Paint(object sender, PaintEventArgs e)
		{

		}

		private void listBox1_SelectedIndexChanged(object sender, EventArgs e)
		{

		}

		private void numericUpDown2_ValueChanged(object sender, EventArgs e)
		{
			onumx = numx;
			onumy = numy;
			numx = Convert.ToInt32(numericUpDown2.Value);
			InitMap();
		}

		private void numericUpDown1_ValueChanged(object sender, EventArgs e)
		{
			onumy = numy;
			onumx = numx;
			numy = Convert.ToInt32(numericUpDown1.Value);
			InitMap();
		}
	}
}
