using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class SoC
	{
		public Int128[] rom;
		public SoC()
		{
			int nn;
			rom = new Int128[16384];
			for (nn = 0; nn < 16384; nn++)
			{
				rom[nn] = new Int128();
			}
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
			long nn;

			if (1==1)
			{
				nn = adr.low & 0xffff;	
				return rom[nn];
			}
		}
	}
}
