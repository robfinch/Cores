using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace Veriword4
{
	public partial class Form1 : Form
	{
		String txt;
		String[] txta;
		int top, left;
		int cursorRow, cursorCol;
		int txtWidth, txtHeight;
		int maxRow, maxCol;

		//System.Text.RegularExpressions.Regex rgx = new Regex(@"((//\*$)<comment>)|(\b(__int8|__int16|__int32|break|char|continue|extern|forever|for|while|do|if|else|until|static|void|return|case|switch|default|int|unsigned)<keyowrd>)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx = new Regex(@"\b(__int8|__int16|__int32|break|char|continue|extern|forever|for|while|do|if|else|until|static|void|return|case|switch|default|int|unsigned)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_pp = new Regex(@"#\s*define|#\s*include|#\s*if|#\s*else|#\s*endif", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_comment = new Regex(@"\s*(//)", RegexOptions.Compiled);

		public Form1()
		{
			InitializeComponent();
			cursorRow = 0;
			cursorCol = 0;
			maxRow = maxCol = 1;
			top = 0;
			left = 0;
			txt = "Hello World\n";
			txta = txt.Split('\n');

		}

		private void vScrollBar1_Scroll(object sender, ScrollEventArgs e)
		{
			top = e.NewValue;
			pictureBox1.Refresh();
		}

		private void pictureBox1_PreviewKeyDown(object sender, PreviewKeyDownEventArgs e)
		{

		}

		private void textBox1_KeyPress(object sender, KeyPressEventArgs e)
		{
			int row, col;
			String p1, p2;
	
			switch(e.KeyChar)
			{
				case (char)8:
					row = cursorRow + top;
					col = cursorCol + left;
					if (col > 0 && col < txta[row].Length)
					{
						txta[row] = txta[row].Substring(0, col - 1) + txta[row].Substring(col, txta[row].Length - col - 1);
						if (cursorCol > 0)
							cursorCol--;
					}
					break;
				default:
					row = cursorRow + top;
					col = cursorCol + left;
					if (col == 0)
						p1 = "";
					else
						p1 = txta[row].Substring(0, col);
					if (col == 0 && txta[row].Length == 0)
						p2 = "";
					else
						p2 = txta[row].Substring(col);
					txta[row] = p1 + e.KeyChar + p2;
					if (cursorCol < maxCol)
						cursorCol++;
					break;
			}
			pictureBox1.Refresh();
		}

		private void saveToolStripMenuItem_Click(object sender, EventArgs e)
		{
			String txt;
			int n;
		
			if (saveFileDialog1.ShowDialog() == DialogResult.OK)
			{
				txt = "";
				for (n = 0; n < txta.Length; n++)
					txt = txt + txta[n];
				System.IO.File.WriteAllText(saveFileDialog1.FileName,txt);
			}
		}

		private void pictureBox2_Paint(object sender, PaintEventArgs e)
		{
			e.Graphics.DrawRectangle(Pens.AntiqueWhite, 0, 0, 8, 10);
		}

		private void textBox1_KeyDown(object sender, KeyEventArgs e)
		{
			int row, col;
			String ch;
		
			switch (e.KeyCode)
			{
				case Keys.Left:
					if (cursorCol > 0)
						cursorCol--;
					else
					{
						if (hScrollBar1.Value > 0)
							hScrollBar1.Value--;
						left = hScrollBar1.Value;
					}
					break;
				case Keys.Right:
					if (cursorCol < maxCol)
						cursorCol++;
					else
					{
						hScrollBar1.Value++;
						left = hScrollBar1.Value;
					}
					break;
				case Keys.Up:
					if (cursorRow > 0)
						cursorRow--;
					else
					{
						if (vScrollBar1.Value > 0)
							vScrollBar1.Value -= 1;
							top = vScrollBar1.Value;
					}
					break;
				case Keys.Down:
					if (cursorRow < maxRow)
						cursorRow++;
					else
					{
						if (vScrollBar1.Value < txta.Length - maxRow)
							vScrollBar1.Value += 1;
						top = vScrollBar1.Value;
					}
					break;
				case Keys.PageDown:
					if (vScrollBar1.Value + maxRow - 3 < txta.Length - maxRow)
						vScrollBar1.Value += maxRow - 3;
					else
						vScrollBar1.Value = txta.Length - maxRow;
					top = vScrollBar1.Value;
					break;
				case Keys.PageUp:
					if (vScrollBar1.Value > maxRow - 3)
						vScrollBar1.Value -= maxRow - 3;
					else
						vScrollBar1.Value = 0;
					if (vScrollBar1.Value < 0)
						vScrollBar1.Value = 0;
					top = vScrollBar1.Value;
					break;
				default:
					row = cursorRow - top;
					col = cursorCol - left;
					//txta[row] = txta[row].Substring(0, col) + textBox1.Text + txta[row].Substring(col,txta[row].Length-col-1);
					//if (cursorCol < maxCol)
					//	cursorCol++;
					break;
			}
			pictureBox1.Refresh();
		}

		private void openToolStripMenuItem_Click(object sender, EventArgs e)
		{
			int n;
	
			if (openFileDialog1.ShowDialog() == DialogResult.OK)
			{
				txt = System.IO.File.ReadAllText(openFileDialog1.FileName);
				txta = txt.Split('\n');
				vScrollBar1.Minimum = 0;
				vScrollBar1.Maximum = txta.Length-1;
				pictureBox1.Refresh();
			}
		}

		private void pictureBox1_Paint(object sender, PaintEventArgs e)
		{
			int n, m;
			int y;
			int x;
			int ln;
			int compos;

			using (Font myFont = new Font("Courier New", 8))
			{
				txtWidth = (int)System.Math.Ceiling((double)e.Graphics.MeasureString("W",myFont).Width);
				txtHeight = (int)System.Math.Ceiling((double)e.Graphics.MeasureString("W", myFont).Height);
				maxCol = pictureBox1.Width / txtWidth - 1;
				maxRow = pictureBox1.Height / txtHeight - 1;
				y = 2;
				for (n = top; n < (txta.Length-1 < top+20 ? txta.Length-1 : top+20); n++)
				{
					for (m = 0; m < maxCol; m++)
					{
						if (m + left < txta[n].Length)
							e.Graphics.DrawString(txta[n].Substring(m + left,1), myFont, Brushes.White, new Point(m * txtWidth, y));
					}
					compos = 1000000;
					MatchCollection comment_matches = rgx_comment.Matches(txta[n]);
					foreach(Match match in comment_matches)
					{
						GroupCollection groups = match.Groups;
						compos = compos < groups[0].Index ? compos : groups[0].Index;
					}
					MatchCollection pp_matches = rgx_pp.Matches(txta[n]);
					if (pp_matches.Count != 0)
					{
						foreach (Match match in pp_matches) {
							GroupCollection groups = match.Groups;
							x = groups[0].Index;
							ln = groups[0].Length;
							for (m = 0; m < maxCol; m++)
								if (m >= x && m < x + ln && m + left < txta[n].Length)
									e.Graphics.DrawString(txta[n].Substring(m + left, 1), myFont, Brushes.Orange, new Point(m * txtWidth, y));
						}
					}
					else
					{
						if (compos < 1000000)
						{
							for (m = 0; m < maxCol; m++)
							if (m >= compos)
							{
								if (m + left < txta[n].Length)
										e.Graphics.DrawString(txta[n].Substring(m + left, 1), myFont, Brushes.Green, new Point(m * txtWidth, y));
							}
						}
						MatchCollection matches = rgx.Matches(txta[n]);
						foreach (Match match in matches)
						{
							GroupCollection groups = match.Groups;
							x = groups[0].Index;
							ln = groups[0].Length;
							if (x < compos)
							{
								for (m = 0; m < maxCol; m++)
									if (m >= x && m < x + ln && m + left < txta[n].Length)
										e.Graphics.DrawString(txta[n].Substring(m + left, 1), myFont, Brushes.LightBlue, new Point(m * txtWidth, y));
							}
							else
							{
								for (m = 0; m < maxCol; m++)
									if (m >= x && m < x + ln && m + left < txta[n].Length)
										e.Graphics.DrawString(txta[n].Substring(m + left, 1), myFont, Brushes.Green, new Point(m * txtWidth, y));
							}
						}
					}
					y += txtHeight;
				}
				e.Graphics.DrawRectangle(Pens.AntiqueWhite, cursorCol * txtWidth, cursorRow * txtHeight + 1, txtWidth, txtHeight);
			}
		}
	}
}
