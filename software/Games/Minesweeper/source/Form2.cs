using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MineSweeper
{
	public class ButtonVars : System.Windows.Forms.Button
	{
		public int x;
		public int y;
		public int value;
		public int count;
		public char bomb;
	}
	public partial class Form2 : Form
	{
		ButtonVars[,] buttons;
		int count;
		int bcount;

		public Form2()
		{
			int n, m;
			System.Random rand = new System.Random();

			InitializeComponent();
			bcount = 0;
			buttons = new ButtonVars[9, 9];
			for (n = 0; n < 9; n++)
			{
				for (m = 0; m < 9; m++)
				{
					buttons[n, m] = new ButtonVars();
					buttons[n, m].x = m;
					buttons[n, m].y = n;
					buttons[n, m].Location = new Point(m * 20, n * 20);
					buttons[n, m].Width = 19;
					buttons[n, m].Height = 19;
					buttons[n, m].Visible = true;
					buttons[n, m].Name = "btn" + Convert.ToString(n) + Convert.ToString(m);
					buttons[n, m].Click += new System.EventHandler(this.btn_Click);
					this.Controls.Add(buttons[n, m]);
					if (rand.NextDouble() < 0.125)
					{
						buttons[n, m].bomb = 'B';
						bcount++;
					}
					else
						buttons[n, m].bomb = ' ';
				}
			}
			count = 0;
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
				if (x < 8)
					sum += buttons[y - 1, x + 1].bomb == 'B' ? 1 : 0;
			}
			if (x > 0)
			{
				sum += buttons[y, x - 1].bomb == 'B' ? 1 : 0;
			}
			if (x < 8)
				sum += buttons[y, x + 1].bomb == 'B' ? 1 : 0;
			if (y < 8)
			{
				if (x > 0)
					sum += buttons[y + 1, x - 1].bomb == 'B' ? 1 : 0;
				sum += buttons[y + 1, x].bomb == 'B' ? 1 : 0;
				if (x < 8)
					sum += buttons[y + 1, x + 1].bomb == 'B' ? 1 : 0;
			}
			return (sum);
		}
		private void btn_Click(object sender, EventArgs e)
		{
			ButtonVars btn = (ButtonVars)sender;
			int x = btn.x;
			int y = btn.y;

			if (btn.bomb == 'B')
			{
				btn.Text = "*";
				MessageBox.Show("Boom!", "MineSweeper", MessageBoxButtons.OK);
			}
			else
			{
				btn.Text = CountSurroundingBombs(buttons[y, x]).ToString();
				if (y > 0 & x > 0) { buttons[y - 1, x - 1].Text = CountSurroundingBombs(buttons[y - 1, x - 1]).ToString(); count++; }
				if (y > 0) { buttons[y - 1, x].Text = CountSurroundingBombs(buttons[y - 1, x]).ToString(); count++; }
				if (y > 0 & x < 8) { buttons[y - 1, x + 1].Text = CountSurroundingBombs(buttons[y - 1, x + 1]).ToString(); count++; }
				if (x > 0) { buttons[y, x - 1].Text = CountSurroundingBombs(buttons[y, x - 1]).ToString(); count++; }
				if (x < 8) { buttons[y, x + 1].Text = CountSurroundingBombs(buttons[y, x + 1]).ToString(); count++; }
				if (y < 8 & x > 0) { buttons[y + 1, x - 1].Text = CountSurroundingBombs(buttons[y + 1, x - 1]).ToString(); count++; }
				if (y < 8) { buttons[y + 1, x].Text = CountSurroundingBombs(buttons[y + 1, x]).ToString(); count++; }
				if (y < 8 & x < 8) { buttons[y + 1, x + 1].Text = CountSurroundingBombs(buttons[y + 1, x + 1]).ToString(); count++; }
				count++;
				if (bcount + count >= 81)
					MessageBox.Show("Complete!", "MineSweeper", MessageBoxButtons.OK);
			}
		}
	}
}
