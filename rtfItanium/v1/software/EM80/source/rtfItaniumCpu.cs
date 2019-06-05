using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class rtfItaniumCpu
	{
		public enum e_unitTypes { N=0, B=1, I=2, F=3, M=4 };
		static public e_unitTypes[,] unitx = new e_unitTypes[66,3] {
{e_unitTypes.B,e_unitTypes.B,e_unitTypes.B},
{e_unitTypes.I,e_unitTypes.B,e_unitTypes.B},
{e_unitTypes.F,e_unitTypes.B,e_unitTypes.B},
{e_unitTypes.M,e_unitTypes.B,e_unitTypes.B},
{e_unitTypes.B,e_unitTypes.I,e_unitTypes.B},
{e_unitTypes.I,e_unitTypes.I,e_unitTypes.B},
{e_unitTypes.F,e_unitTypes.I,e_unitTypes.B},
{e_unitTypes.M,e_unitTypes.I,e_unitTypes.B},
{e_unitTypes.B,e_unitTypes.F,e_unitTypes.B},
{e_unitTypes.I,e_unitTypes.F,e_unitTypes.B},
{e_unitTypes.F,e_unitTypes.F,e_unitTypes.B},
{e_unitTypes.M,e_unitTypes.F,e_unitTypes.B},
{e_unitTypes.B,e_unitTypes.M,e_unitTypes.B},
{e_unitTypes.I,e_unitTypes.M,e_unitTypes.B},
{e_unitTypes.F,e_unitTypes.M,e_unitTypes.B},
{e_unitTypes.M,e_unitTypes.M,e_unitTypes.B},
{e_unitTypes.B,e_unitTypes.B,e_unitTypes.I},
{e_unitTypes.I,e_unitTypes.B,e_unitTypes.I},
{e_unitTypes.F,e_unitTypes.B,e_unitTypes.I},
{e_unitTypes.M,e_unitTypes.B,e_unitTypes.I},
{e_unitTypes.B,e_unitTypes.I,e_unitTypes.I},
{e_unitTypes.I,e_unitTypes.I,e_unitTypes.I},
{e_unitTypes.F,e_unitTypes.I,e_unitTypes.I},
{e_unitTypes.M,e_unitTypes.I,e_unitTypes.I},
{e_unitTypes.B,e_unitTypes.F,e_unitTypes.I},
{e_unitTypes.I,e_unitTypes.F,e_unitTypes.I},
{e_unitTypes.F,e_unitTypes.F,e_unitTypes.I},
{e_unitTypes.M,e_unitTypes.F,e_unitTypes.I},
{e_unitTypes.B,e_unitTypes.M,e_unitTypes.I},
{e_unitTypes.I,e_unitTypes.M,e_unitTypes.I},
{e_unitTypes.F,e_unitTypes.M,e_unitTypes.I},
{e_unitTypes.M,e_unitTypes.M,e_unitTypes.I},
{e_unitTypes.B,e_unitTypes.B,e_unitTypes.F},
{e_unitTypes.I,e_unitTypes.B,e_unitTypes.F},
{e_unitTypes.F,e_unitTypes.B,e_unitTypes.F},
{e_unitTypes.M,e_unitTypes.B,e_unitTypes.F},
{e_unitTypes.B,e_unitTypes.I,e_unitTypes.F},
{e_unitTypes.I,e_unitTypes.I,e_unitTypes.F},
{e_unitTypes.F,e_unitTypes.I,e_unitTypes.F},
{e_unitTypes.M,e_unitTypes.I,e_unitTypes.F},
{e_unitTypes.B,e_unitTypes.F,e_unitTypes.F},
{e_unitTypes.I,e_unitTypes.F,e_unitTypes.F},
{e_unitTypes.F,e_unitTypes.F,e_unitTypes.F},
{e_unitTypes.M,e_unitTypes.F,e_unitTypes.F},
{e_unitTypes.B,e_unitTypes.M,e_unitTypes.F},
{e_unitTypes.I,e_unitTypes.M,e_unitTypes.F},
{e_unitTypes.F,e_unitTypes.M,e_unitTypes.F},
{e_unitTypes.M,e_unitTypes.M,e_unitTypes.F},
{e_unitTypes.B,e_unitTypes.B,e_unitTypes.M},
{e_unitTypes.I,e_unitTypes.B,e_unitTypes.M},
{e_unitTypes.F,e_unitTypes.B,e_unitTypes.M},
{e_unitTypes.M,e_unitTypes.B,e_unitTypes.M},
{e_unitTypes.B,e_unitTypes.I,e_unitTypes.M},
{e_unitTypes.I,e_unitTypes.I,e_unitTypes.M},
{e_unitTypes.F,e_unitTypes.I,e_unitTypes.M},
{e_unitTypes.M,e_unitTypes.I,e_unitTypes.M},
{e_unitTypes.B,e_unitTypes.F,e_unitTypes.M},
{e_unitTypes.I,e_unitTypes.F,e_unitTypes.M},
{e_unitTypes.F,e_unitTypes.F,e_unitTypes.M},
{e_unitTypes.M,e_unitTypes.F,e_unitTypes.M},
{e_unitTypes.B,e_unitTypes.M,e_unitTypes.M},
{e_unitTypes.I,e_unitTypes.M,e_unitTypes.M},
{e_unitTypes.F,e_unitTypes.M,e_unitTypes.M},
{e_unitTypes.M,e_unitTypes.M,e_unitTypes.M},
{e_unitTypes.I,e_unitTypes.N,e_unitTypes.N},
{e_unitTypes.F,e_unitTypes.N,e_unitTypes.N}
			};
		public enum e_bunit {
			Bcc = 0, BLcc=1, Brcc = 2, NOP = 3,
		FBcc = 4, BBc = 5, BEQI = 6, BNEI = 7,
		JAL = 8, JMP = 9, CALL = 10, RET = 11,
		CHK = 12, CHKI = 13, Misc=14, BRK = 15
		};
		public Int128[] regfile;
		public Int128 ip;
		public Int128 ibundle;
		public UInt64 insn0;
		public UInt64 insn1;
		public UInt64 insn2;
		public e_unitTypes unit0;
		public e_unitTypes unit1;
		public e_unitTypes unit2;
		public e_unitTypes unitn;
		public UInt64 insnn;
		public int template;
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
			ip.low = (Int64)0xFFFFFFFFFFFC010L;
			ip.low <<= 4;
			ip.low |= 0x0;
			ip.high = (Int64)0xFFFFFFFFFFFFFFFL;
			ip.high <<= 4;
			ip.high |= 0xF;
		}
		void IncIp(int amt)
		{
			switch(ip.low & 15L)
			{
				case 0:
					ip.low |= 5L;
					break;
				case 5:
					ip.low &= 0xfffffffffffffff0L;
					ip.low |= 10L;
					break;
				case 10:
					ip.low &= 0xfffffffffffffff0L;
					ip.low += 0x10L;
					break;
			}
		}
		public void Step(SoC soc)
		{
			ibundle = soc.Read(ip);
			insn0 = ibundle.low & (UInt64)0xffffffffffL;
			insn1 = (ibundle.low >> 40) & (UInt64)0xffffffL;
			insn1 |= ((UInt64)ibundle.high & 0xffffL) << 24;
			insn2 = ((UInt64)ibundle.high >> 16) & 0xffffffffffL;
			template = (int)(ibundle.high >> 56) & 0x7f;
			if (template == 0x7D)
			{
				unit0 = e_unitTypes.I;
				unit1 = e_unitTypes.N;
				unit2 = e_unitTypes.N;
			}
			else if (template == 0x7E)
			{
				unit0 = e_unitTypes.F;
				unit1 = e_unitTypes.N;
				unit2 = e_unitTypes.N;
			}
			else
			{
				template &= 63;
				unit0 = unitx[template, 0];
				unit1 = unitx[template, 1];
				unit2 = unitx[template, 2];
			}
			switch (ip.low & 0xFL)
			{
				case 0:
					insnn = insn0;
					unitn = unit0;
					break;
				case 5:
					insnn = insn1;
					unitn = unit1;
					break;
				case 10:
					insnn = insn2;
					unitn = unit2;
					break;
			}
			switch(unitn)
			{
				case e_unitTypes.N:
					IncIp(1);
					break;
				case e_unitTypes.B:
					switch((e_bunit)((insnn >> 6) & 15)) {
						case e_bunit.Bcc:
							break;
						case e_bunit.JMP:
							ip.low &= 0xffffff0000000000L;
							ip.low |= ((insnn & 0x3fL) << 2);
							ip.low |= (insnn & 3L);
							ip.low |= ((insnn >> 10)) << 8;
							break;
					}
					break;
				case e_unitTypes.I:
					IncIp(1);
					break;
				case e_unitTypes.F:
					IncIp(1);
					break;
				case e_unitTypes.M:
					IncIp(1);
					break;
			}
		}
	}
}
