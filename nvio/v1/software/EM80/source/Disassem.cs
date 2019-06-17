using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class Disassem
	{
		static string Regstr(Int16 reg)
		{
			string str;

			str = "$R" + Convert.ToString(reg, 10);
			return str;
		}
		static string RII(UInt64 instr)
		{
			string str;

			Int128 rii = new Int128();

			rii.digits[0] = (instr >> 16) & 0x7fffL;
			rii.digits[0] |= ((instr >> 33) & 0x7fL) << 15;
			rii.digits[1] = 0;
			rii.digits[2] = 0;
			rii.digits[3] = 0;
			if ((rii.digits[0] & 0x200000L) != 0)
			{
				rii.digits[0] |= 0xffC00000L;
				rii.digits[1] = 0xffffffffL;
				rii.digits[2] = 0xffffffffL;
				rii.digits[3] = 0xffffffffL;
			}
			str = rii.ToString80();
			return str;
		}
		static string BranchTgt(Int64 instr, Int128 ip) {
			string str;
			Int64 tgt;

			tgt = ((instr >> 4) & 3) | (((instr >> 4) & 3) << 2) | ((instr >> 22) << 4);
			tgt = Int128.Add(ip, Int128.Convert(instr >> 22)).ToLong();
			tgt &= -16L;
			tgt |= ((instr >> 4) & 3) | (((instr >> 4) & 3) << 2);
			str = "$" + Convert.ToString(tgt, 16).PadLeft(10, '0');
			return str;
		}
		static string CallTgt(Int64 instr)
		{
			string str;

			Int64 tgt = (instr & 3) | ((instr & 63) << 2) | ((instr >> 10) << 8);
			str = Convert.ToString(tgt, 16).PadLeft(10, '0');
			return str;
		}
		public static string Disassemble(nvioCpu.e_unitTypes unit, Int64 instr, Int128 ip)
		{
			string str;
			UInt16 op4;
			UInt16 op6;
			UInt16 func5;
			Int16 Rd;
			Int16 Rs1;
			Int16 Rs2;
			Int16 Rs3;

			op4 = (UInt16)((instr >> 6) & 15L);
			func5 = (UInt16)((instr >> 35) & 31L);
			Rd = (Int16)(instr & 63);
			Rs1 = (Int16)((instr >> 10) & 63);
			Rs2 = (Int16)((instr >> 16) & 63);
			Rs3 = (Int16)((instr >> 22) & 63);
			str = "";
			str = ip.ToString80().Substring(14, 6) + " ";
			switch (unit)
			{
				case nvioCpu.e_unitTypes.B:
					switch((nvioCpu.e_bunit)op4)
					{
						case nvioCpu.e_bunit.CALL:
							str = str + "CALL   ";
							str = str + CallTgt(instr);
							break;
						case nvioCpu.e_bunit.RET:
							str = str + "RET";
							break;
						case nvioCpu.e_bunit.JMP:
							str = str + "JMP";
							str = str + CallTgt(instr);
							break;
						case nvioCpu.e_bunit.Bcc:
							switch((nvioCpu.e_bcond)(instr & 7))
							{
								case nvioCpu.e_bcond.BEQ:
									str = str + "BEQ    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + BranchTgt(instr,ip);
									break;
								case nvioCpu.e_bcond.BNE:
									str = str + "BNE    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + BranchTgt(instr, ip);
									break;
								case nvioCpu.e_bcond.BLT:
									str = str + "BLT    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + BranchTgt(instr, ip);
									break;
								default:
									str = str + "B??    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + BranchTgt(instr, ip);
									break;
							}
							break;
					}
					break;
				case nvioCpu.e_unitTypes.I:
					op6 = (UInt16)(((instr >> 6) & 15L) | (((instr >> 31) & 3L) << 4));
					switch((nvioCpu.e_iunit)op6)
					{
						case nvioCpu.e_iunit.R3E:
							return nvioCpu.DisProcessR3((UInt64)instr, Rd, Rs1, Rs2, Rs3);

						case nvioCpu.e_iunit.ADDI:
							str = str + "ADD    ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + "," + RII((UInt64)instr);
							break;
					}
					break;
				case nvioCpu.e_unitTypes.M:
					break;
			}
			return str;
		}
	}
}
