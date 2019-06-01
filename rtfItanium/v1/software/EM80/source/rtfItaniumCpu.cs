using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class rtfItaniumCpu
	{
		public Int128[] regfile;
		public Int128 ip;
		public Int128 ibundle;
		public rtfItaniumCpu()
		{
			int nn;

			regfile = new Int128[1024];
			for (nn = 0; nn < 1024; nn++)
			{
				regfile[nn] = new Int128();
			}
			ip = new Int128();
			ibundle = new Int128();
		}
		public void Reset()
		{
			ip.low = (Int64)0xFFFFFFFFFFFF010L;
			ip.low <<= 4;
			ip.low |= 0xF;
			ip.high = (Int64)0xFFFFFFFFFFFFFFFL;
			ip.high <<= 4;
			ip.high |= 0xF;
		}
		public void Step(SoC soc)
		{
			ibundle = soc.Read(ip);
		}
	}
}
