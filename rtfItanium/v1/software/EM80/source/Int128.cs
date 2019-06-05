using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class Int128
	{
		public
				UInt64 low;
		public Int64 high;

		public Int128()
		{
			high = 0;
			low = 0;
		}
		public Int128(string str)
		{
			Int128 a = FromHexString(str);
			low = a.low;
			high = a.high;
		}
		bool AddCarry(Int64 s, Int64 a, Int64 b)
		{
			return (((a & b) | (a & ~s) | (b & ~s)) >> 63)==1;
		}
		bool SubBorrow(Int64 d, Int64 a, Int64 b)
		{
			return (((~a & b) | (d & ~a) | (d & b)) >> 63)==1;
		}
		public Int128 Add(Int128 a, Int128 b)
		{
			Int128 sum = new Int128();

			sum.low = a.low + b.low;
			sum.high = a.high + b.high;
			if (AddCarry((Int64)sum.low, (Int64)a.low, (Int64)b.low))
				sum.high++;
			return sum;
		}
		public Int128 Sub(Int128 a, Int128 b)
		{
			Int128 dif = new Int128();

			dif.low = a.low - b.low;
			dif.high = a.high - b.high;
			if (SubBorrow((Int64)dif.low, (Int64)a.low, (Int64)b.low))
				dif.high--;
			return dif;
		}
		public Int128 Shl(Int128 a, int amt)
		{
			for (; amt > 0; amt--)
			{
				a.high <<= 1;
				if (((a.low >> 63) & 1L) == 1)
					a.high |= 1;
				a.low <<= 1;
			}
			return a;
		}
		public Int128 Shr(Int128 a, int amt)
		{
			for (; amt > 0; amt--)
			{
				a.low = a.low >> 1;
				if ((a.high & 1L)==1)
					a.low |= (UInt64)1L << 63;
				a.high >>= 1;
			}
			return a;
		}
		public Int128 ShrPair(Int128 hi, Int128 lo, int amt)
		{
			for (; amt > 0; amt--)
			{
				lo.low >>= 1;
				lo.low &= 0x7fffffffffffffffL;
				if ((lo.high & 1L) == 1)
					lo.low |= (UInt64)1L << 63;
				lo.high >>= 1;
				lo.high &= 0x7fffffffffffffffL;
				if ((hi.low & 1L) == 1)
					lo.high |= 1L << 63;
				hi.low = hi.low >> 1;
				hi.low &= 0x7fffffffffffffffL;
				if ((hi.high & 1L) == 1)
					hi.low |= (UInt64)1L << 63;
				hi.high >>= 1;
			}
			return lo;
		}
		public Int128 FromHexString(string str)
		{
			Int128 a = new Int128();
			int nn;

			for (nn = 0; nn < str.Length; nn++)
			{
				a = Shl(a, 4);
				a.low |= Convert.ToUInt64(str.Substring(nn, 1),16);
			}
			return a;
		}
		public string ToString80()
		{
			string str;

			str = Convert.ToString(high,16).PadLeft(4,'0') + Convert.ToString((Int64)low, 16).PadLeft(16,'0');
			str = str.Substring(str.Length-20, 20);
			return str;
		}
		public string ToString128()
		{
			string str;

			str = Convert.ToString(high, 16).PadLeft(16, '0') + Convert.ToString((Int64)low, 16).PadLeft(16, '0');
			return str;
		}
	}
}
