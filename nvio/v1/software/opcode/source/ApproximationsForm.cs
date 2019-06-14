using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Opcode
{
	public partial class ApproximationsForm : Form
	{
		public ApproximationsForm()
		{
			InitializeComponent();
		}

		private void button1_Click(object sender, EventArgs e)
		{
			string str;
			double f, inv;
			Int64 bits;
			Int64 i64;
			Random random;

			random = new Random();
			str = "";
			for (int i = 0; i < 1024; i++)
			{
				double x0 = 1.0 + i / 1024.0;       // left endpoint of interval
				double x1 = 1.0 + (i + 1) / 1024.0;   // right endpoint of interval
				double f0 = 1.0 / x0;
				double f1 = 1.0 / x1;
				double df = f0 - f1;
				double sl = df * 1024.0;        // slope across interval
				double mp = (x0 + x1) / 2.0;  // midpoint of interval
				double fm = 1.0 / mp;
				double ic = fm + df / 2.0;    // intercept at start of interval

				str = str + "k01["+Convert.ToString(i) + "] = 32'h" + Convert.ToString((Int64)(ic * 65536.0 - 0.9999), 16).PadLeft(4,'0') + Convert.ToString((Int64)(sl * 65536.0 + 0.9999),16).PadLeft(4,'0') + ";\r\n";
//				printf("%5d     %04x  %04x\n",
//								i, (int)(ic * 65536.0 - 0.9999), (int)(sl * 65536.0 + 0.9999));
			}
			textBox1.Text = str;
			str = "";
			for (int i = 0; i < 8192; i++)
			{
				f = random.NextDouble() * (double)(random.Next() - random.Next());
				inv = 1.0 / f;
				bits = BitConverter.DoubleToInt64Bits(inv);
				str = str + Convert.ToString(bits, 16).PadLeft(8, '0');
				bits = BitConverter.DoubleToInt64Bits(f);
				str = str + Convert.ToString(bits, 16).PadLeft(8,'0');
				str = str + "\r\n";
			}
			textBox2.Text = str;
		}

		private void button2_Click(object sender, EventArgs e)
		{
			string[] lines;
			string s, rs;
			int nn;
			int j, k;
			string sinv, sest, sa;
			string iman, eman;
			Int64 im, em;
			Int64 inv, est, a;
			double dinv, dest, da, err, bits;

			lines = System.IO.File.ReadAllLines("d:\\cores6\\rtfItanium\\v1\\rtl\\fpUnit\\fpRes_tvo.txt");
			nn = 0;
			rs = "----- err % ------ bits -----\r\n";
			foreach (string str in lines)
			{
				sinv = str.Substring(0, 16);
				sest = str.Substring(16, 16);
				sa = str.Substring(32, 16);
				if (!(sinv.Substring(0, 1) == "x" || sinv.Substring(0, 1) == "X"))
				{
					iman = str.Substring(3, 13);
					eman = str.Substring(19, 13);
					inv = Convert.ToInt64(sinv, 16);
					est = Convert.ToInt64(sest, 16);
					a = Convert.ToInt64(sa, 16);
					im = Convert.ToInt64(iman, 16);
					em = Convert.ToInt64(eman, 16);
					dinv = BitConverter.Int64BitsToDouble(inv);
					dest = BitConverter.Int64BitsToDouble(est);
					da = BitConverter.Int64BitsToDouble(a);
					err = ((Math.Abs(dinv - dest)) / Math.Abs(dinv));
					bits = 52.0 - Math.Log(Math.Abs(im - em)) / Math.Log(2);
					err *= 100.0;
					rs = rs + Convert.ToString(err) + "% (" + Convert.ToString((int)bits) + " bits)\r\n";
				}
			}
			textBox2.Text = rs;
		}

		private void button3_Click(object sender, EventArgs e)
		{
			double rng;
			double sig, sigo;
			string str, str1;
			Int64 d;
			Int64 ex;
			Int64 sgn;
			Int64 man;

			str = "";
			str1 = "";
			//for (rng = 0.0f; rng < 8.0; rng += 8.0f / 512.0f)
			//{
			//	sig = (float)(1.0 / (1.0 + Math.Exp((double)-rng)));
			//	printf("sig(%f) = %f\r\n", rng, sig);
			//}
			sig = 0.0;
			for (rng = -8.0f; rng < 8.0f; rng += (16.0f / 1024.0f))
			{
				sigo = sig;
				sig = 1.0 / (1.0 + Math.Exp(-rng));
				d = BitConverter.DoubleToInt64Bits(sig);
				sgn = (d >> 63) & 1L;
				ex = (d >> 52) & 0x7ffL;
				man = d & 0xfffffffffffffL;
				man |= 0x10000000000000L;		// recover hidden bit
				// Denormalize exponent so we can remove it from the table.
				while (ex < 0x3ffL)
				{
					ex++;
					man >>= 1;
				}
				//d = sgn << 63;
				//d = d | (ex << 52);
				d = man & 0x1fffffffffffffL;
				//d &= 0xfffffffffffffL;
				d >>= 20;
				str = str + "SigmoidLUT[" + Convert.ToString((int)(rng * 64)+512) + "] = 32'h" + Convert.ToString(d,16).PadLeft(8,'0') + ";\r\n";
			}
			textBox2.Text = str;
			for (rng = -8.0f; rng < 8.0f; rng += (16.0f / 8192.0f))
			{
				d = BitConverter.DoubleToInt64Bits(rng);
				if (rng == 0.0)
				{
					sgn = 0;
					ex = 0;
					man = 0;
				}
				else
				{
					sgn = (d >> 63) & 1L;
					ex = (d >> 52) & 0x7ffL;
					man = d & 0xfffffffffffffL;
					ex = ex - 0x3ffL;
					ex = (ex + 0x7fL) & 0xffL;
				}
				d = sgn << 31;
				d = d | (ex << 23);
				d = d | ((man >> 29) & 0x7fffffL);
				str1 = str1 + "RngLUT[" + Convert.ToString((int)(rng * 512) + 4096) + "] = 32'h" + Convert.ToString(d, 16).PadLeft(8, '0') + ";\r\n";
			}
			textBox1.Text = str1;
		}

		private void button4_Click(object sender, EventArgs e)
		{
			double rng, rsqrt;
			string str;
			int cnt;
			Int64 d;
			Int64 sgn, ex, man;
			Random random = new Random();

			str = "";
			cnt = 0;
			//for (rng = 0.0; rng < 1.0; rng = rng + 1.0/1024.0)
			//{
			//	rsqrt = 1.0 / (Math.Sqrt(rng));
			//	d = BitConverter.DoubleToInt64Bits(rsqrt);
			//	sgn = (d >> 63) & 1L;
			//	ex = (d >> 52) & 0x7ffL;
			//	man = d & 0xfffffffffffffL;
			//	ex = ex - 0x3ffL;
			//	ex = (ex + 0x7fL) & 0xffL;
			//	d = sgn << 31;
			//	d = d | (ex << 23);
			//	d = d | ((man >> 29) & 0x7fffffL);
			//	str = str + "RsqrteLUT[" + Convert.ToString(cnt) + "] = 32'h" + Convert.ToString(d, 16).PadLeft(8, '0') + ";\r\n";
			//	cnt++;
			//}
			//textBox1.Text = str;
			str = "";
			for (cnt = 0; cnt < 8192; cnt++)
			{
				rng = random.NextDouble() * (random.Next() - random.Next());
				rsqrt = 1.0 / (Math.Sqrt(rng));
				d = BitConverter.DoubleToInt64Bits(rsqrt);
				sgn = (d >> 63) & 1L;
				ex = (d >> 52) & 0x7ffL;
				man = d & 0xfffffffffffffL;
				ex = ex - 0x3ffL;
				ex = (ex + 0x7fL) & 0xffL;
				d = sgn << 31;
				d = d | (ex << 23);
				d = d | ((man >> 29) & 0x7fffffL);
				str = str + Convert.ToString(d, 16).PadLeft(8, '0');
				d = BitConverter.DoubleToInt64Bits(rng);
				sgn = (d >> 63) & 1L;
				ex = (d >> 52) & 0x7ffL;
				man = d & 0xfffffffffffffL;
				ex = ex - 0x3ffL;
				ex = (ex + 0x7fL) & 0xffL;
				d = sgn << 31;
				d = d | (ex << 23);
				d = d | ((man >> 29) & 0x7fffffL);
				//str = str + "fpRsqrteRngLUT[" + Convert.ToString(cnt) + "] = 32'h" + Convert.ToString(d, 16).PadLeft(8, '0') + ";\r\n";
				str = str + Convert.ToString(d, 16).PadLeft(8, '0') + "\r\n";
			}
			str = "";
			for (cnt = 0; cnt < 16384; cnt++)
			{
				ex = (cnt >> 6) + 0x3fffL - 0x7fL;
				ex = ex & 0x7fffL;
				man = (cnt & 0x3fL) << 46;
				d = (ex << 52) | man;
				rng = BitConverter.Int64BitsToDouble(d);
				rsqrt = 1.0 / (Math.Sqrt(rng));
				d = BitConverter.DoubleToInt64Bits(rsqrt);
				ex = d >> 52;
				man = d & 0xfffffffffffffL;
				ex = ex - 0x3fffL + 0x7fL;
				man = man >> 29;
				d = ((ex & 0xffL) << 23);
				d = d | man;
				d >>= 14;
				if (cnt >= 8197)
					str = str + "RsqrteLUT[" + Convert.ToString(cnt - 8192) + "] = 16'h" + Convert.ToString(d, 16).PadLeft(4, '0') + ";\r\n";
				else if (cnt >= 8129)
				{
					d >>= 1;
					str = str + "RsqrteLUT2[" + Convert.ToString(cnt - 8129) + "] = 16'h" + Convert.ToString(d, 16).PadLeft(4, '0') + ";\r\n";
				}
			}
			textBox2.Text = str;
		}
	}
}
