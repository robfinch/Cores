using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class SoC
	{
		public rtfItaniumCpu cpu;
		public Int128[] rom;
		public Int128[] mainmem;
		public SoC()
		{
			int nn;

			cpu = new rtfItaniumCpu();
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
			int j, k;

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
					j = str.IndexOf('h');
					k = str.IndexOf(';');
					s = str.Substring(j + 1, k - j - 1);
					rom[nn] = new Int128(s);
				}
			}
		}
		public Int128 Read(Int128 adr)
		{
			ulong nn;
			Int128 j, k;

			if (adr.low < 0x20000000L)
			{
				nn = (adr.low >> 4) & 0x3fffffL;
				j = mainmem[nn];
				k = mainmem[nn + 1];
				j = j.ShrPair(k, j, (int)(adr.low & 15L));
				return j;
			}
			if (1==1)
			{
				nn = ((adr.low - 0xFFFFFFFFFFC0000L) >> 4) & 0xffff;
				j = rom[nn];
				k = rom[nn + 1];
				j = j.ShrPair(k, j, (int)(adr.low & 15L));
				return j;
			}
		}
	}
}
