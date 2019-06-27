using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	public class SoC
	{
		public nvioCpu cpu;
		public Int128[] rom;
		public Int128[] mainmem;
		public Int64[] textmem;
		public Int128[] scratchmem;
		public int leds;
		public SoC()
		{
			int nn;

			cpu = new nvioCpu();
			rom = new Int128[16384];
			mainmem = new Int128[4194304];  // 64 MB
			textmem = new long[65536];
			scratchmem = new Int128[4096];

			for (nn = 0; nn < 16384; nn++)
			{
				rom[nn] = new Int128();
			}
			for (nn = 0; nn < 4194304; nn++)
			{
				mainmem[nn] = new Int128();
			}
			for (nn = 0; nn < 4096; nn++)
			{
				scratchmem[nn] = new Int128();
			}
		}
		public void Reset()
		{
			cpu.Reset();
		}
		public void Step()
		{
			cpu.Step(this);
		}
		public void LoadROM(string fname)
		{
			string[] lines;
			string s;
			int nn;
			int j, k, m;

			lines = System.IO.File.ReadAllLines(fname);
			nn = 0;
			foreach (string str in lines)
			{
				j = str.IndexOf('[');
				k = str.IndexOf(']');
				if (j >= 0 && k >= 0)
				{
					nn = Convert.ToInt32(str.Substring(j + 1, k - j - 1), 10);
					if (nn > 16383)
						continue;
					m = str.IndexOf("256'h");
					if (m >= 0)
					{
						j = m + 5;
						s = str.Substring(j, 32);
						rom[nn*2+1] = new Int128(s);
						s = str.Substring(j + 32, 32);
						rom[nn*2] = new Int128(s);
					}
					else
					{
						j = str.IndexOf('h');
						k = str.IndexOf(';');
						s = str.Substring(j + 1, k - j - 1);
						rom[nn] = new Int128(s);
					}
				}
			}
		}
		public Int128 IFetch(Int128 adr)
		{
			ulong nn;
			Int128 j, k;
			ulong ad = adr.low();

			if (1 == 1)
			{
				ad &= 0xfffffffffffffff0L;
				nn = ((ad - 0xFFFFFFFFFFC0000L) >> 4) & 0x3fffL;
				j = rom[nn].Clone();
				return j;
			}
		}
		public Int128 Read(Int128 adr)
		{
			ulong nn;
			Int128 j, k;
			ulong ad = adr.digits[0];

			if (ad < 0x20000000L)
			{
				nn = (ad >> 4) & 0xfffffL;
				j = mainmem[nn].Clone();
				k = mainmem[nn + 1].Clone();
				j = j.ShrPair(k, j, (int)((adr.digits[0] & 15L) << 3));
				return j;
			}
			else if ((ad & 0xffffffffL) >= 0xff400000L && ((ad & 0xffffffffL) < 0xff410000L))
			{
				nn = (ad >> 4) & 0xfffL;
				j = scratchmem[nn].Clone();
				k = scratchmem[(nn + 1) & 0xfffL].Clone();
				j = j.ShrPair(k, j, (int)((adr.digits[0] & 15L) << 3));
				return j;
			}
			else // ROM
			{
				nn = ((ad - 0xFFFFFFFFFFC0000L) >> 4) & 0x3fff;
				j = rom[nn].Clone();
				if (nn + 1 > 16383)
					k = Int128.Convert(0);
				else
					k = rom[nn + 1].Clone();
				j = j.ShrPair(k, j, (int)((ad & 15L) << 3));
				return j;
			}
		}
		public void Write(Int128 adr, Int128 val, int size)
		{
			ulong ad = adr.digits[0] | (adr.digits[1] << 32);
			Int128 j, k;
			Int128 s;
			Int128 mask = new Int128();
			Int128 v = new Int128();
			Int128 m, mlo, mhi;
			Int128 vlo, vhi;

			vlo = new Int128();
			vhi = new Int128();
			mlo = new Int128();
			mhi = new Int128();
			switch (size)
			{
				case 1:
					mask.digits[0] = 0xffffff00L;
					mask.digits[1] = 0xffffffffL;
					mask.digits[2] = 0xffffffffL;
					mask.digits[3] = 0xffffffffL;
					break;
				case 2:
					mask.digits[0] = 0xffff0000L;
					mask.digits[1] = 0xffffffffL;
					mask.digits[2] = 0xffffffffL;
					mask.digits[3] = 0xffffffffL;
					break;
				case 4:
					mask.digits[0] = 0x00000000L;
					mask.digits[1] = 0xffffffffL;
					mask.digits[2] = 0xffffffffL;
					mask.digits[3] = 0xffffffffL;
					break;
				case 5:
					mask.digits[0] = 0x00000000L;
					mask.digits[1] = 0xffffff00L;
					mask.digits[2] = 0xffffffffL;
					mask.digits[3] = 0xffffffffL;
					break;
				case 8:
					mask.digits[0] = 0x00000000L;
					mask.digits[1] = 0x00000000L;
					mask.digits[2] = 0xffffffffL;
					mask.digits[3] = 0xffffffffL;
					break;
				case 10:
					mask.digits[0] = 0x00000000L;
					mask.digits[1] = 0x00000000L;
					mask.digits[2] = 0xffff0000L;
					mask.digits[3] = 0xffffffffL;
					break;
			}
			if (ad < 0x20000000L)
			{
				s = Int128.Add(adr, Int128.Convert(size));
				// Do we need to modify one or two memory bundles?
				if ((s.digits[0] & 0xfffffff0L) != (adr.digits[0] & 0xfffffff0L))
				{
					s = Int128.Shr(adr, 4);
					j = mainmem[s.digits[0]].Clone();
					k = mainmem[s.digits[0]+1].Clone();
					val = val.ZX80();
					Int128.ShlPair(val, ref vlo, ref vhi, (int)((adr.digits[0] & 0xfL) * 8),0);
					mhi = Int128.Convert(-1);
					Int128.ShlPair(mask, ref mlo, ref mhi, (int)((adr.digits[0] & 0xfL) * 8),1);
					j = Int128.And(j, mlo);
					j = Int128.Or(j, vlo);
					k = Int128.And(k, mhi);
					k = Int128.Or(k, vhi);
					mainmem[s.digits[0]] = j;
					mainmem[s.digits[0] + 1] = k;
				}
				else
				{
					s = Int128.Shr(adr, 4);
					j = mainmem[s.digits[0]].Clone();
					val = val.ZX80();
					Int128.ShlPair(val, ref vlo, ref vhi, (int)((adr.digits[0] & 0xfL) * 8));
					j = Int128.And(j, mlo);
					j = Int128.Or(j, vlo);
					mainmem[s.digits[0]] = j;
				}
				return;
			}
			else if ((ad & 0xffffffffL) >=  0xff400000L && (ad & 0xffffffffL)< 0xff410000L)
			{
				s = Int128.Add(adr, Int128.Convert(size));
				// Do we need to modify one or two memory bundles?
				if ((s.digits[0] & 0xfffffff0L) != (adr.digits[0] & 0xfffffff0L))
				{
					s = Int128.Shr(adr, 4);
					ad = (ad >> 4) &0xfffL;
					j = scratchmem[ad].Clone();
					k = scratchmem[(ad + 1) & 0xfffL].Clone();
					val = val.ZX80();
					Int128.ShlPair(val, ref vlo, ref vhi, (int)((adr.digits[0] & 0xfL) * 8), 0);
					mhi = Int128.Convert(-1);
					Int128.ShlPair(mask, ref mlo, ref mhi, (int)((adr.digits[0] & 0xfL) * 8), 1);
					j = Int128.And(j, mlo);
					j = Int128.Or(j, vlo);
					k = Int128.And(k, mhi);
					k = Int128.Or(k, vhi);
					scratchmem[ad] = j;
					scratchmem[(ad + 1) & 0xfffL] = k;
				}
				else
				{
					s = Int128.Shr(adr, 4);
					ad = (ad >> 4) & 0xfffL;
					j = scratchmem[ad].Clone();
					val = val.ZX80();
					Int128.ShlPair(val, ref vlo, ref vhi, (int)((adr.digits[0] & 0xfL) * 8));
					j = Int128.And(j, mlo);
					j = Int128.Or(j, vlo);
					scratchmem[ad] = j;
				}
				return;
			}
			else if (ad >=  0xffffffffffd00000L && ad < 0xffffffffffd10000L)
			{
				textmem[(ad >> 3) & 0xffffL] = (long)(val.digits[0] | (val.digits[1] << 32));
			}
			else if (ad == 0xffffffffffdc0600L)
			{
				leds = (int)val.digits[0];
			}
		}
	}
}
