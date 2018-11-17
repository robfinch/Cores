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
		int txtSelRow, txtSelBegin, txtSelEnd;
		bool ShiftDown, CtrlDown;
		Brush txtBkColor;
		Brush txtSelColor;
		String CopyBuf;

		//System.Text.RegularExpressions.Regex rgx = new Regex(@"((//\*$)<comment>)|(\b(__int8|__int16|__int32|break|char|continue|extern|forever|for|while|do|if|else|until|static|void|return|case|switch|default|int|unsigned)<keyowrd>)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_cc64 = new Regex(@"\b(__int8|__int16|__int32|__asm|asm|break|char|continue|extern|forever|for|while|do|if|else|until|static|void|register|return|case|switch|default|int|unsigned)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_pp64 = new Regex(@"#\s*define|#\s*include|#\s*if|#\s*else|#\s*endif|#\s*ifdef|#\s*ifndef", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_v = new Regex(@"\b(always|assign|begin|break|endcase|endgenerate|endmodule|end[^.]|for|generate|while|do[^.]|if|input|integer|else|localparam|module|output|parameter|reg|wire|casez|casex|case|default)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_ppv = new Regex(@"\`\s*define|\`\s*include|\`\s*if|\`\s*else|\`\s*endif|\`\s*ifdef|\`\s*ifndef", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx_pp;
		System.Text.RegularExpressions.Regex rgx_comment = new Regex(@"\s*(//)", RegexOptions.Compiled);
		System.Text.RegularExpressions.Regex rgx;

		public Form1()
		{
			InitializeComponent();
			cursorRow = 0;
			cursorCol = 0;
			maxRow = maxCol = 1;
			txtSelBegin = -1;
			txtSelEnd = -1;
			txtSelRow = -1;
			ShiftDown = false;
			CtrlDown = false;
			top = 0;
			left = 0;
			txt = "Hello World\n";
			txta = txt.Split('\n');
			txtSelColor = new System.Drawing.SolidBrush(Color.FromArgb(255, 0, 32, 32));
			txtBkColor = new System.Drawing.SolidBrush(Color.FromArgb(255,0,64,64));
			rgx = rgx_cc64;
			rgx_pp = rgx_ppv;
		}

		private void vScrollBar1_Scroll(object sender, ScrollEventArgs e)
		{
			top = e.NewValue;
			pictureBox1.Refresh();
		}

		private void pictureBox1_PreviewKeyDown(object sender, PreviewKeyDownEventArgs e)
		{

		}

		
		private void saveToolStripMenuItem_Click(object sender, EventArgs e)
		{
			String txt;
			int n;
		
			if (saveFileDialog1.ShowDialog() == DialogResult.OK)
			{
				txt = "";
				for (n = 0; n < txta.Length; n++)
					txt = txt + txta[n] + '\n';
				System.IO.File.WriteAllText(saveFileDialog1.FileName,txt);
			}
		}

		private void CancelSelection()
		{
			txtSelBegin = -1;
			txtSelEnd = -1;
			txtSelRow = -1;
		}

		private void Form1_KeyDown(object sender, KeyEventArgs e)
		{
			int row, col;
			int n;
			String p1, p2;

			row = cursorRow + top;
			col = cursorCol + left;
			switch (e.KeyCode)
			{
				case Keys.Escape:
					CancelSelection();
					break;
				case Keys.Back:
					if (col > 0 && col <= txta[row].Length)
					{
						if (txtSelBegin >= 0)
						{
							p1 = txta[row].Substring(0, txtSelBegin);
							if (txtSelEnd >= txta[row].Length)
								p2 = "";
							else
								p2 = txta[row].Substring(txtSelEnd+1);
							txta[row] = p1 + p2;
							cursorCol = txtSelBegin - left;
							CancelSelection();
						}
						else
						{
							if (col > txta[row].Length)
							{
								if (cursorCol > 0)
									cursorCol--;
								break;
							}
							else if (col == txta[row].Length)
								txta[row] = txta[row].Substring(0, col - 1);
							else
								txta[row] = txta[row].Substring(0, col - 1) + txta[row].Substring(col, txta[row].Length - col - 1);
							if (cursorCol > 0)
								cursorCol--;
						}
					}
					break;
				case Keys.Delete:
					p2 = "";
					if (col > 0)
						p1 = txta[row].Substring(0, col);
					else
						p1 = "";
					if (txta[row].Length > 0 && col < txta[row].Length - 1)
						p2 = txta[row].Substring(col + 1);
					else
					{
						for (n = row; n < txta.Length-1; n++)
						{
							txta[n] = txta[n + 1];
						}
						txta[n] = "";
						break;
					}
					txta[row] = p1 + p2;
					break;
				case Keys.ShiftKey:
					ShiftDown = true;
					break;
				case Keys.ControlKey:
					CtrlDown = true;
					e.Handled = true;
					break;
				case Keys.Home:
					if (cursorCol == 0)
					{
						if (cursorRow == 0)
						{
							top = 0;
						}
						else
							cursorRow = 0;
					}
					else
						cursorCol = 0;
					break;
				case Keys.End:
					cursorCol = txta[cursorRow].Length - 1;
					if (cursorCol > maxCol)
					{
						left = cursorCol - maxCol;
					}
					break;
				case Keys.Left:
					if (ShiftDown)
					{
						if (txtSelBegin < 0)
						{
							txtSelRow = cursorRow + top;
							txtSelBegin = cursorCol + left;
							txtSelEnd = cursorCol + left;
						}
						else
						{
							txtSelEnd = cursorCol + left;
						}
					}
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
					if (ShiftDown)
					{
						if (txtSelBegin < 0)
						{
							txtSelRow = cursorRow + top;
							txtSelBegin = cursorCol + left;
							txtSelEnd = cursorCol + left;
						}
						else
						{
							txtSelEnd = cursorCol + left;
						}
					}
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
				case Keys.C:
					if (CtrlDown)
					{
						if (txtSelBegin >= 0)
						{
							CopyBuf = txta[row].Substring(txtSelBegin, txtSelEnd - txtSelBegin + 1);
							CancelSelection();
						}
						e.Handled = true;
						break;
					}
					goto default;
				case Keys.X:
					if (CtrlDown)
					{
						if (txtSelBegin >= 0)
						{
							CopyBuf = txta[row].Substring(txtSelBegin, txtSelEnd - txtSelBegin + 1);
							p1 = txta[row].Substring(0, txtSelBegin);
							p2 = txta[row].Substring(txtSelEnd+1);
							txta[row] = p1 + p2;
							cursorCol = txtSelBegin;
							CancelSelection();
							break;
						}
					}
					goto default;
				case Keys.V:
					if (CtrlDown)
					{
						p1 = txta[row].PadRight(col+1);
						p1 = p1.Substring(0, col);
						if (col >= txta[row].Length)
							p2 = "";
						else
							p2 = txta[row].Substring(col);
						txta[row] = p1 + CopyBuf + p2;
						cursorCol += p1.Length;
						if (cursorCol > maxCol)
						{
							hScrollBar1.Value += p1.Length;
							cursorCol -= p1.Length;
						}
						break;
					}
					goto default;
				default:
					row = cursorRow - top;
					col = cursorCol - left;
					CancelSelection();
					//txta[row] = txta[row].Substring(0, col) + textBox1.Text + txta[row].Substring(col,txta[row].Length-col-1);
					//if (cursorCol < maxCol)
					//	cursorCol++;
					break;
			}
			pictureBox1.Refresh();
		}

		private void Form1_KeyPress(object sender, KeyPressEventArgs e)
		{
			int row, col;
			String p1, p2;
			String[] txtb;
			int n;

			switch (e.KeyChar)
			{
				case (char)3:		// CTRL-C
				case (char)22:  // CTRL-V
				case (char)24:	// CTRL-X
				case (char)8:
					break;
				case (char)13:
					row = cursorRow + top;
					col = cursorCol + left;
					txtb = new String[txta.Length + 1];
					for (n = 0; n < row; n++)
						txtb[n] = txta[n];
					if (row < txta.Length)
					{
						txtb[row] = txta[row].Substring(0, col);
						txtb[row + 1] = txta[row].Substring(col);
						for (n = row + 1; n < txta.Length; n++)
							txtb[n + 1] = txta[n];
					}
					else
						txtb[row] = "";
					txta = new string[txtb.Length];
					txtb.CopyTo(txta, 0);
					cursorRow++;
					cursorCol = 0;
					break;
				case 'c':
				case 'v':
				case 'x':
					if (CtrlDown)
						break;
					else
						goto default;
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

		private void Form1_KeyUp(object sender, KeyEventArgs e)
		{
			switch (e.KeyCode)
			{
				case Keys.ShiftKey:
					ShiftDown = false;
					break;
				case Keys.ControlKey:
					CtrlDown = false;
					break;
			}
		}

		private void vScrollBar1_KeyDown(object sender, KeyEventArgs e)
		{
			Form1_KeyDown(sender, e);
			e.Handled = true;
		}

		private void vScrollBar1_KeyPress(object sender, KeyPressEventArgs e)
		{
			Form1_KeyPress(sender, e);
			e.Handled = true;
		}

		private void vScrollBar1_KeyUp(object sender, KeyEventArgs e)
		{
			Form1_KeyUp(sender, e);
			e.Handled = true;
		}

		//private void ActiveMdiChild_FormClosed(object sender,
		//																FormClosedEventArgs e)
		//{
		//	((sender as Form).Tag as TabPage).Dispose();
		//}

		//private void tabForms_SelectedIndexChanged(object sender,
		//																			 EventArgs e)
		//{
		//	if ((tabForms.SelectedTab != null) &&
		//			(tabForms.SelectedTab.Tag != null))
		//		(tabForms.SelectedTab.Tag as Form).Select();
		//}

		//private void Form1_MdiChildActivate(object sender, EventArgs e)
		//{
		//	if (this.ActiveMdiChild == null)
		//		tabForms.Visible = false;
		//	// If no any child form, hide tabControl 
		//	else
		//	{
		//		this.ActiveMdiChild.WindowState =
		//		FormWindowState.Maximized;
		//		// Child form always maximized 

		//		// If child form is new and no has tabPage, 
		//		// create new tabPage 
		//		if (this.ActiveMdiChild.Tag == null)
		//		{
		//			// Add a tabPage to tabControl with child 
		//			// form caption 
		//			TabPage tp = new TabPage(this.ActiveMdiChild
		//															 .Text);
		//			tp.Tag = this.ActiveMdiChild;
		//			tp.Parent = tabForms;
		//			tabForms.SelectedTab = tp;

		//			this.ActiveMdiChild.Tag = tp;
		//			this.ActiveMdiChild.FormClosed +=
		//					new FormClosedEventHandler(
		//													ActiveMdiChild_FormClosed);
		//		}

		//		if (!tabForms.Visible) tabForms.Visible = true;

		//	}
		//}

		private void pictureBox2_Paint(object sender, PaintEventArgs e)
		{
			e.Graphics.DrawRectangle(Pens.AntiqueWhite, 0, 0, 8, 10);
		}

		private void textBox1_KeyDown(object sender, KeyEventArgs e)
		{
		}

		private void openToolStripMenuItem_Click(object sender, EventArgs e)
		{
			int n;
	
			if (openFileDialog1.ShowDialog() == DialogResult.OK)
			{
				this.Text = openFileDialog1.FileName;
				txt = System.IO.File.ReadAllText(openFileDialog1.FileName);
				txta = txt.Split('\n');
				vScrollBar1.Minimum = 0;
				vScrollBar1.Maximum = txta.Length-1;
				pictureBox1.Refresh();
				this.Text = openFileDialog1.FileName;
				if (openFileDialog1.FileName.EndsWith(".v"))
				{
					rgx = rgx_v;
					rgx_pp = rgx_ppv;
				}
			}
		}

		private bool InTextSelection(int row, int col)
		{
			return (row == txtSelRow && col >= txtSelBegin && col <= txtSelEnd);
		}

		private void DrawText(PaintEventArgs e, int row, int col, int x, int y, Font myFont, Brush br)
		{
			if (InTextSelection(row, col))
				e.Graphics.FillRectangle(txtSelColor, x, y + 2, txtWidth, txtHeight);
			else
				e.Graphics.FillRectangle(txtBkColor, x, y + 2, txtWidth, txtHeight);
			e.Graphics.DrawString(txta[row].Substring(col, 1), myFont, br, new Point(x, y));
		}

		private void pictureBox1_Paint(object sender, PaintEventArgs e)
		{
			int n, m;
			int y;
			int x;
			int i;
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
					for (x = 0, m = left; m < left + maxCol; m++, x += txtWidth)
					{
						if (m < txta[n].Length)
						{
							DrawText(e, n, m, x, y, myFont, Brushes.White);
						}
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
							i = groups[0].Index;
							ln = groups[0].Length;
							for (x = 0, m = left; m < left + maxCol; m++, x += txtWidth)
								if (m >= i && m < i + ln && m < txta[n].Length)
									DrawText(e, n, m, x, y, myFont, Brushes.Orange);
						}
					}
					else
					{
						if (compos < 1000000)
						{
							for (x = 0, m = left; m < left + maxCol; m++, x += txtWidth)
								if (m >= compos)
							{
								if (m + left < txta[n].Length)
									DrawText(e, n, m, x, y, myFont, Brushes.Green);
							}
						}
						MatchCollection matches = rgx.Matches(txta[n]);
						foreach (Match match in matches)
						{
							GroupCollection groups = match.Groups;
							i = groups[0].Index;
							ln = groups[0].Length;
							if (i < compos)
							{
								for (x = 0, m = left; m < left + maxCol; m++, x += txtWidth)
									if (m >= i && m < i + ln && m < txta[n].Length)
										DrawText(e, n, m, x, y, myFont, Brushes.LightBlue);
							}
							else
							{
								for (x = 0, m = left; m < left + maxCol; m++, x += txtWidth)
									if (m >= i && m < i + ln && m < txta[n].Length)
										DrawText(e, n, m, x, y, myFont, Brushes.Green);
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
