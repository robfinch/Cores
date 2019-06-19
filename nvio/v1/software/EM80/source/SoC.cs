using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class SoC
	{
		public nvioCpu cpu;
		public Int128[] rom;
		public Int128[] mainmem;
		public int leds;
		public SoC()
		{
			int nn;

			cpu = new nvioCpu();
			rom = new Int128[16384];
			mainmem = new Int128[4194304];	// 64 MB
			for (nn = 0; nn < 16384; nn++)
			{
				rom[nn] = new Int128();
			}
			for (nn = 0; nn < 4194304; nn++)
			{
				mainmem[nn] = new Int128();
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
			if (1==1)
			{
				nn = ((ad - 0xFFFFFFFFFFC0000L) >> 4) & 0x3fff;
				j = rom[nn].Clone();
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
			Int128 m;

			if (ad < 0x20000000L)
			{
				switch(size)
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
				s = Int128.Add(adr, Int128.Convert(size));
				// Do we need to modify one or two memory bundles?
				if ((s.digits[0] & 0xfffffff0L) != (adr.digits[0] & 0xfffffff0L))
				{
					s = Int128.Shr(s, 4);
					j = mainmem[s.digits[0]].Clone();
					k = mainmem[s.digits[0]+1].Clone();
					v = val.Clone();
					v = Int128.Shl(v, (int)((adr.digits[0] & 0xfL) * 8));
					m = Int128.Shl(mask, (int)((adr.digits[0] & 0xfL) * 8),1);
					j = Int128.And(j, m);
					j = Int128.Or(j, v);
					m = Int128.Shr(mask, 128 - (int)((adr.digits[0] & 0xfL) * 8), 1);
					k = Int128.And(k, m);
					v = val.Clone();
					v = Int128.Shr(v, 128 - (int)((adr.digits[0] & 0xfL) * 8),0);
					k = Int128.Or(k, v);
					mainmem[s.digits[0]] = j;
					mainmem[s.digits[0] + 1] = k;
				}
				else
				{
					s = Int128.Shr(s, 4);
					j = mainmem[s.digits[0]].Clone();
					v = val.Clone();
					v = Int128.Shl(v, (int)((adr.digits[0] & 0xfL) * 8));
					m = Int128.Shl(mask, (int)((adr.digits[0] & 0xfL) * 8),1);
					j = Int128.And(j, m);
					j = Int128.Or(j, v);
					mainmem[s.digits[0]] = j;
				}
				return;
			}
			if (ad == 0xffffffffffdc0600L)
			{
				leds = (int)val.digits[0];
			}
		}
	}
}
