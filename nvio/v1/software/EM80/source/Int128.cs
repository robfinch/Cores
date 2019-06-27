using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	public class Int128
	{
		public UInt64[] digits;

		public Int128()
		{
			digits = new UInt64[4];
			digits[0] = 0;
			digits[1] = 0;
			digits[2] = 0;
			digits[3] = 0;
		}
		public static Int128 Convert(bool b)
		{
			Int128 a = new Int128();
			if (b)
				a.digits[0] = 1;
			else
				a.digits[0] = 0;
			return a;
		}
		public static Int128 Convert(long nn)
		{
			Int128 a = new Int128();

			a.digits[0] = (ulong)(nn & 0xffffffffL);
			a.digits[1] = (ulong)(nn >> 32);
			a.digits[2] = (ulong)(nn < 0 ? 0xffffffffL : 0L);
			a.digits[3] = (ulong)(nn < 0 ? 0xffffffffL : 0L);
			return a;
		}
		public static Int128 Convert(ulong nn)
		{
			Int128 a = new Int128();

			a.digits[0] = (nn & 0xffffffffL);
			a.digits[1] = (nn >> 32);
			a.digits[2] = 0;
			a.digits[3] = 0;
			return a;
		}
		public Int64 ToLong()
		{
			Int64 i;

			i = ((Int64)digits[1] << 32) | (Int64)digits[0];
			return i;
		}
		public Int128 ZX8()
		{
			digits[0] &= 0xffL;
			digits[1] = 0x0L;
			digits[2] = 0x0L;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 ZX16()
		{
			digits[0] &= 0xffffL;
			digits[1] = 0x0L;
			digits[2] = 0x0L;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 ZX32()
		{
			digits[1] = 0x0L;
			digits[2] = 0x0L;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 ZX40()
		{
			digits[1] &= 0xffL;
			digits[2] = 0x0L;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 ZX64()
		{
			digits[2] = 0x0L;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 ZX80()
		{
			digits[2] &= 0xffffL;
			digits[3] = 0x0L;
			return this;
		}
		public Int128 SX8()
		{
			if ((digits[0] & 0x80L) != 0)
			{
				digits[0] |= 0xffffff00L;
				digits[1] = 0xffffffffL;
				digits[2] = 0xffffffffL;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public Int128 SX16()
		{
			if ((digits[0] & 0x8000L) != 0)
			{
				digits[0] |= 0xffff0000L;
				digits[1] = 0xffffffffL;
				digits[2] = 0xffffffffL;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public Int128 SX32()
		{
			if ((digits[0] & 0x80000000L) != 0)
			{
				digits[1] = 0xffffffffL;
				digits[2] = 0xffffffffL;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public Int128 SX40()
		{
			if ((digits[1] & 0x80L) != 0)
			{
				digits[1] |= 0xffffff00L;
				digits[2] = 0xffffffffL;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public Int128 SX64()
		{
			if ((digits[1] & 0x80000000L) != 0)
			{
				digits[2] = 0xffffffffL;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public Int128 SX80()
		{
			if ((digits[2] & 0x8000L) != 0)
			{
				digits[2] |= 0xffff0000L;
				digits[3] = 0xffffffffL;
			}
			return this;
		}
		public void mask()
		{
			int nn;

			for (nn = 0; nn < 4; nn++)
				digits[nn] &= 0xffffffffL;
		}
		public UInt64 low()
		{
			UInt64 n;

			n = digits[0] | (digits[1] << 32);
			return n;
		}
		public UInt64 high()
		{
			UInt64 n;

			n = digits[2] | (digits[3] << 32);
			return n;
		}
		public Int128(string str)
		{
			int nn;
			Int128 a = FromHexString(str);
			digits = new ulong[4];
			for (nn = 0; nn < 4; nn++)
				digits[nn] = a.digits[nn];
			mask();
		}
		public Int128 Clone()
		{
			int nn;
			Int128 c;
			c = new Int128();
			for (nn = 0; nn < 4; nn++)
				c.digits[nn] = this.digits[nn];
			c.mask();
			return c;
		}
		public static bool EQ(Int128 a, Int128 b)
		{
			int nn;

			for (nn = 0; nn < 4; nn++)
				if (a.digits[nn] != b.digits[nn])
					return false;
			return true;
		}
		static bool AddCarry(Int64 s, Int64 a, Int64 b)
		{
			return (((a & b) | (a & ~s) | (b & ~s)) >> 63)==1;
		}
		static bool SubBorrow(Int64 d, Int64 a, Int64 b)
		{
			return (((~a & b) | (d & ~a) | (d & b)) >> 63)==1;
		}
		public static Int128 Add(Int128 a, Int128 b)
		{
			int nn;
			Int128 sum = new Int128();

			for (nn = 0; nn < 4; nn++)
			{
				sum.digits[nn] = a.digits[nn] + b.digits[nn];
			}
			for (nn = 0; nn < 3; nn++)
			{
				if (sum.digits[nn] > 0xffffffffL)
				{
					sum.digits[nn] &= 0xffffffffL;
					sum.digits[nn + 1]++;
				}
			}
			sum.mask();
			return sum;
		}
		public static Int128 Sub(Int128 a, Int128 b)
		{
			int nn;
			Int128 dif = new Int128();

			for (nn = 0; nn < 4; nn++)
			{
				dif.digits[nn] = a.digits[nn] - b.digits[nn];
			}
			for (nn = 0; nn < 3; nn++)
			{
				if (dif.digits[nn] < 0L)
				{
					dif.digits[nn] &= 0xffffffffL;
					dif.digits[nn + 1]--;
				}
			}
			dif.mask();
			return dif;
		}
		public static Int128 Mul(Int128 a, Int128 b)
		{
			Int128 aa = a.Clone();
			Int128 p = new Int128();
			int nn;

			for (nn = 0; nn < 128; nn++)
			{
				if (((aa.digits[3] >> 31) & 1) != 0)
					p = Add(p, b);
				p = Shl(p, 1);
				aa = Shl(aa, 1);
			}
			return p;
		}
		public static bool LT(Int128 a, Int128 b)
		{
			Int128 d;

			d = Sub(a, b);
			if (((d.digits[3] >> 31) & 1) != 0)
				return true;
			return false;
		}
		public static Int128 Shl(Int128 a, int amt, int lsb = 0)
		{
			int nn;
			Int128 aa = a.Clone();

			for (; amt > 0; amt--)
			{
				for (nn = 0; nn < 4; nn++)
				{
					aa.digits[nn] <<= 1;
				}
				for (nn = 0; nn < 3; nn++)
				{
					if (aa.digits[nn] > 0xffffffffL)
					{
						aa.digits[nn] &= 0xffffffffL;
						aa.digits[nn+1]++;
					}
				}
				aa.digits[0] |= (ulong)lsb;
				aa.digits[nn] &= 0xffffffffL;
			}
			aa.mask();
			return aa;
		}
		public static void ShlPair(Int128 a, ref Int128 aa, ref Int128 bb, int amt, int lsb = 0)
		{
			int nn;

			aa = a.Clone();
//			bb = Int128.Convert(lsb!=0 ? -1 : 0);

			for (; amt > 0; amt--)
			{
				for (nn = 0; nn < 4; nn++)
				{
					aa.digits[nn] <<= 1;
					bb.digits[nn] <<= 1;
				}
				for (nn = 0; nn < 3; nn++)
				{
					if (aa.digits[nn] > 0xffffffffL)
					{
						aa.digits[nn] &= 0xffffffffL;
						aa.digits[nn + 1]++;
					}
					if (bb.digits[nn] > 0xffffffffL)
					{
						bb.digits[nn] &= 0xffffffffL;
						bb.digits[nn + 1]++;
					}
				}
				if (aa.digits[nn] > 0xffffffffL)
					bb.digits[0]++;
				aa.digits[0] |= (ulong)lsb;
				aa.mask();
				bb.mask();
			}
		}
		public static Int128 Com(Int128 a)
		{
			int nn;
			Int128 aa = a.Clone();

			for (nn = 0; nn < 4; nn++)
				aa.digits[nn] = ~aa.digits[nn];
			return aa;
		}
		public static Int128 Rol(Int128 a, int amt)
		{
			int nn;
			Int128 aa = a.Clone();

			for (; amt > 0; amt--)
			{
				for (nn = 0; nn < 4; nn++)
				{
					aa.digits[nn] <<= 1;
				}
				for (nn = 0; nn < 3; nn++)
				{
					if (aa.digits[nn] > 0xffffffffL)
					{
						aa.digits[nn] &= 0xffffffffL;
						aa.digits[nn + 1]++;
					}
				}
				if (aa.digits[nn] > 0xffffffffL)
					aa.digits[0] |= 1;
				aa.digits[nn] &= 0xffffffffL;
			}
			aa.mask();
			return aa;
		}
		public static Int128 Shr(Int128 a, int amt, int fill = 0)
		{
			int nn;
			Int128 aa = a.Clone();

			for (; amt > 0; amt--)
			{
				for (nn = 3; nn > 0; nn--)
				{
					if ((aa.digits[nn] & 1L) != 0)
					{
						aa.digits[nn - 1] |= 0x100000000L;
					}
				}
				for (nn = 0; nn < 4; nn++)
				{
					aa.digits[nn] >>= 1;
				}
				aa.digits[nn-1] |= (ulong)fill << 31;
			}
			aa.mask();
			return aa;
		}
		public static Int128 Asr(Int128 a, int amt)
		{
			int nn;
			Int128 aa = a.Clone();

			for (; amt > 0; amt--)
			{
				for (nn = 3; nn > 0; nn--)
				{
					if ((aa.digits[nn] & 1L) != 0)
					{
						aa.digits[nn - 1] |= 0x100000000L;
					}
				}
				for (nn = 0; nn < 4; nn++)
				{
					aa.digits[nn] >>= 1;
				}
				aa.digits[nn - 1] |= (ulong)((aa.digits[nn-1] >> 30) & 1) << 31;
			}
			aa.mask();
			return aa;
		}
		public Int128 ShrPair(Int128 hi, Int128 lo, int amt)
		{
			int nn;
			UInt64[] digits;
			Int128 aa = new Int128();

			digits = new ulong[8];
			Int128 reslo = lo.Clone();
			Int128 reshi = hi.Clone();

			digits[0] = lo.digits[0];
			digits[1] = lo.digits[1];
			digits[2] = lo.digits[2];
			digits[3] = lo.digits[3];
			digits[4] = hi.digits[0];
			digits[5] = hi.digits[1];
			digits[6] = hi.digits[2];
			digits[7] = hi.digits[3];
			for (; amt > 0; amt--)
			{
				for (nn = 7; nn > 0; nn--)
				{
					if ((digits[nn] & 1L) != 0)
					{
						digits[nn - 1] |= 0x100000000L;
					}
				}
				for (nn = 0; nn < 8; nn++)
				{
					digits[nn] >>= 1;
				}
			}
			aa.digits[0] = digits[0];
			aa.digits[1] = digits[1];
			aa.digits[2] = digits[2];
			aa.digits[3] = digits[3];
			aa.mask();
			return aa;
		}
		public static Int128 Or(Int128 a, Int128 b)
		{
			int nn;
			Int128 sum = new Int128();

			for (nn = 0; nn < 4; nn++)
				sum.digits[nn] = a.digits[nn] | b.digits[nn];
			sum.mask();
			return sum;
		}
		public static Int128 And(Int128 a, Int128 b)
		{
			int nn;
			Int128 sum = new Int128();

			for (nn = 0; nn < 4; nn++)
				sum.digits[nn] = a.digits[nn] & b.digits[nn];
			sum.mask();
			return sum;
		}
		public static Int128 Xor(Int128 a, Int128 b)
		{
			int nn;
			Int128 sum = new Int128();

			for (nn = 0; nn < 4; nn++)
				sum.digits[nn] = a.digits[nn] ^ b.digits[nn];
			sum.mask();
			return sum;
		}
		public Int128 FromHexString(string str)
		{
			Int128 a = new Int128();
			int nn;

			for (nn = 0; nn < str.Length; nn++)
			{
				a = Shl(a, 4);
				a.digits[0] |= System.Convert.ToUInt64(str.Substring(nn, 1),16);
			}
			a.mask();
			return a;
		}
		public string ToString80()
		{
			string str;

			str = System.Convert.ToString((Int16)digits[2],16).PadLeft(4,'0') + System.Convert.ToString((Int32)digits[1], 16).PadLeft(8, '0') + System.Convert.ToString((Int32)digits[0], 16).PadLeft(8,'0');
			return str;
		}
		public string ToString128()
		{
			int nn;
			string str;

			str = "";
			for (nn = 3; nn >= 0; nn--)
				str = str + System.Convert.ToString((Int64)digits[nn], 16).PadLeft(8, '0');
			return str;
		}
	}
}
