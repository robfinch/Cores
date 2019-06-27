using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	public class nvioCpu
	{
		public enum e_unitTypes { N = 0, B = 1, I = 2, F = 3, M = 4 };
		static public e_unitTypes[,] unitx = new e_unitTypes[67, 3] {
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
{e_unitTypes.F,e_unitTypes.N,e_unitTypes.N},
{e_unitTypes.M,e_unitTypes.N,e_unitTypes.N},
			};
		public enum e_bunit {
			Bcc = 0, BLcc = 1, Brcc = 2, NOP = 3,
			FBcc = 4, BBc = 5, BEQI = 6, BNEI = 7,
			JAL = 8, JMP = 9, CALL = 10, RET = 11,
			CHK = 12, CHKI = 13, Misc = 14, BRK = 15,
			SEI = 3,
		};
		public enum e_bcond
		{
			BEQ = 0,
			BNE = 1,
			BLT = 2,
			BGE = 3,
			BLTU = 6,
			BGEU = 7,
		}
		public enum e_bmisc
		{
			RTI = 0,
			REX = 1,
			SYNC = 2,
			SEI = 3,
			WAIT = 4,
			EXEC = 5,
		}
		public enum e_iunit
		{
			R1 = 1,
			R3E = 2,
			R3O = 3,
			ADDI = 4,
			CSR = 5,
			ANDI = 8,
			ORI = 9,
			XORI = 0x0A,
			SLTI = 0x10,
			SGEI = 0x11,
			SEQI = 0x18,
			SNEI = 0x19,
			MUL = 0x20,
			ADDS0 = 0x33,
			ADDS1 = 0x34,
			ADDS2 = 0x35,
			ADDS3 = 0x36,
			ORS1 = 0x3c,
			ORS2 = 0x3d,
			ORS3 = 0x3e,
			ORS0 = 0x3f,
			ADD = 0x04,
			SUB = 0x05,
			AND = 0x08,
			OR = 0x09,
			XOR = 0x0A,
			SHLI = 0x38,
			SHRI = 0x3A,
		};
		public enum e_iunitR1
		{
			NOT = 0x05,
			MOV = 0x10,
		}
		public enum e_csrreg
		{
			TICK = 0x02,
			TVEC0 = 0x30,
			TVEC1 = 0x31,
			TVEC2 = 0x32,
			TVEC3 = 0x33,
		}
		public enum e_funit
		{
			FLT1 = 1,
		};
		public enum e_flt1
		{
			FTX = 0x10,
			FCX = 0x11,
			FEX = 0x12,
			FDX = 0x13,
			FRM = 0x14,
			FSYNC = 0x16,
		};
		public enum e_funit5 {
			FTOI = 2,
		};
		public enum e_munit
		{
			LDB = 0x00,
			LDBU = 0x04,
			LDW = 0x01,
			LDWU = 0x05,
			LDP = 0x02,
			LDPU = 0x06,
			LDO = 0x09,
			LDOU = 0x0D,
			LDD = 0x03,
			LDT = 0x08,
			LDTU = 0x0C,
			MLX = 0x0F,
			LDFS = 0x10,
			LDFD = 0x11,
			POP = 0x1D,
			STB = 0x20,
			STD = 0x23,
			STT = 0x28,
			STW = 0x21,
			STP = 0x22,
			STO = 0x29,
			PUSH = 0x2d,
			PUSHC0 = 0x0b,
			PUSHC1 = 0x1b,
			PUSHC2 = 0x2b,
			PUSHC3 = 0x3b,
			TLB = 0x2c,
			CAS = 0x2A,
			CASX = 0x0A,
			MSX = 0x2f,
		};
		public enum e_munit5
		{
			STBX = 0x00,
			STWX = 0x01,
			STPX = 0x02,
			STDX = 0x03,
			STTX = 0x08,
			STOX = 0x09,
			LDBX = 0x00,
			LDBUX = 0x04,
			LDWX = 0x01,
			LDWUX = 0x05,
			LDTX = 0x08,
			LDTUX = 0x0C,
			LDPX = 0x02,
			LDPUX = 0x06,
			LDDX = 0x03,
			LDOX = 0x09,
			LDOUX = 0x0D,
			MEMSB = 0x18,
			MEMDB = 0x19,
		};
		public int regset;
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
		public e_bunit bopcode;
		public uint aopcode;
		public e_funit fopcode;
		public e_munit mopcode;
		public UInt64 insnn;
		public int template;
		public uint funct5;
		public int Rd, Rs1, Rs2, Rs3;
		public Int128 opa, opb, opc;
		public Int128 rii;
		public Int128 res;
		public Int128 ma;
		public Int128 max;
		public Int128 brdisp;
		public bool rfw;
		public bool isLoad;
		public int icount;
		// CSRs
		public Int64 tick;
		public Int128[] tvec;

		public nvioCpu()
		{
			int nn;

			regfile = new Int128[1024];
			for (nn = 0; nn < 1024; nn++)
			{
				regfile[nn] = new Int128();
			}
			ip = new Int128();
			ibundle = new Int128();
			rii = new Int128();
			ma = new Int128();
			max = new Int128();
			brdisp = new Int128();
			res = new Int128();
			regset = 0;
			tvec = new Int128[4];
			for (nn = 0; nn < 4; nn++)
			{
				tvec[nn] = new Int128();
			}
		}
		public void Reset()
		{
			ip = Int128.Convert(0xfffffffffffC0100L);
			ip.digits[2] = 0xffffffffL;
			ip.digits[3] = 0xffffffffL;
			icount = 0;
			tick = 0;
		}
		void IncIp(int amt)
		{
			switch(ip.digits[0] & 15L)
			{
				case 0:
					ip.digits[0] |= 5L;
					break;
				case 5:
					ip.digits[0] &= 0xfffffff0L;
					ip.digits[0] |= 10L;
					break;
				case 10:
					ip.digits[0] &= 0xfffffff0L;
					ip = Int128.Add(ip, Int128.Convert(0x10));
					break;
			}
		}
		public static Int128 IncAd(Int128 ad, int amt)
		{
			Int128 a = new Int128();

			a = ad.Clone();
			switch (ad.digits[0] & 15L)
			{
				case 0:
					a.digits[0] |= 5L;
					break;
				case 5:
					a.digits[0] &= 0xfffffff0L;
					a.digits[0] |= 10L;
					break;
				case 10:
					a.digits[0] &= 0xfffffff0L;
					a = Int128.Add(a, Int128.Convert(0x10));
					break;
			}
			return a;
		}
		static string Regstr(int reg)
		{
			string str;

			str = "$R" + Convert.ToString(reg, 10);
			return str;
		}
		public void ProcessBcc()
		{
			e_bcond bcond;
			uint S2;

			bcond = (e_bcond)(insnn & 7L);
			S2 = (uint)((insnn >> 22) & 3);
			brdisp.digits[0] = (insnn >> 20) & 0xffff0L;
			brdisp.digits[1] = 0;
			brdisp.digits[2] = 0;
			brdisp.digits[3] = 0;
			if ((brdisp.digits[0] & 0x80000L) != 0)
			{
				brdisp.digits[0] |= 0xfff00000L;
				brdisp.digits[1] = 0xffffffffL;
				brdisp.digits[2] = 0xffffffffL;
				brdisp.digits[3] = 0xffffffffL;
			}
			switch(bcond)
			{
				case e_bcond.BEQ:
					if (Int128.EQ(opa, opb))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
				case e_bcond.BNE:
					if (!Int128.EQ(opa, opb))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
				case e_bcond.BLT:
					if (Int128.LT(opa, opb))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
				case e_bcond.BGE:
					if (Int128.LT(opb, opa) || Int128.EQ(opa, opb))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
			}
		}
		public void ProcessBEQI()
		{
			uint S2;
			ulong imm;

			S2 = (uint)((insnn >> 22) & 3);
			imm = (ulong)((insnn & 7) | (((insnn >> 16) & 0x3f) << 3));
			if ((imm & 0x100L) != 0)
				imm |= 0xfffffffffffffE00L;
			brdisp.digits[0] = (insnn >> 20) & 0xffff0L;
			brdisp.digits[1] = 0;
			brdisp.digits[2] = 0;
			brdisp.digits[3] = 0;
			if ((brdisp.digits[0] & 0x80000L) != 0)
			{
				brdisp.digits[0] |= 0xfff00000L;
				brdisp.digits[1] = 0xffffffffL;
				brdisp.digits[2] = 0xffffffffL;
				brdisp.digits[3] = 0xffffffffL;
			}
			switch ((e_bunit)((insnn >> 6) & 15))
			{
				case e_bunit.BEQI:
					if (Int128.EQ(opa, Int128.Convert(imm)))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
				case e_bunit.BNEI:
					if (!Int128.EQ(opa, Int128.Convert(imm)))
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
			}
		}
		public void ProcessBBc()
		{
			int bcond;
			uint S2;
			Int128 tmp;
			int shamt;

			bcond = (int)(insnn & 1L);
			S2 = (uint)((insnn >> 22) & 3);
			brdisp.digits[0] = (insnn >> 20) & 0xffff0L;
			brdisp.digits[1] = 0;
			brdisp.digits[2] = 0;
			brdisp.digits[3] = 0;
			if ((brdisp.digits[0] & 0x80000L) != 0)
			{
				brdisp.digits[0] |= 0xfff00000L;
				brdisp.digits[1] = 0xffffffffL;
				brdisp.digits[2] = 0xffffffffL;
				brdisp.digits[3] = 0xffffffffL;
			}
			switch (bcond)
			{
				case 0: // BBS
					tmp = Int128.And(opb, Int128.Convert(0x7fL));
					shamt = (int)tmp.digits[0];
					tmp = Int128.Shr(opa, shamt);
					if ((tmp.digits[0] & 1) != 0)
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
				case 1: // BBC
					tmp = Int128.And(opb, Int128.Convert(0x7fL));
					shamt = (int)tmp.digits[0];
					tmp = Int128.Shr(opa, shamt);
					if ((tmp.digits[0] & 1) == 0)
					{
						ip.digits[0] &= 0xfffffff0L;
						ip = Int128.Add(ip, brdisp);
						ip.digits[0] |= ((S2 << 2) | S2);
					}
					else
						IncIp(1);
					break;
			}
		}
		public Int128 ProcessR3(ulong insnn, Int128 opa, Int128 opb, Int128 opc)
		{
			e_iunit funct;

			funct = (e_iunit)(((insnn >> 34) & 0x3eL) | ((insnn >> 6) & 1L));
			switch(funct)
			{
				case e_iunit.ADD:
					res = Int128.Add(opa, opb);
					break;
				case e_iunit.AND:
					res = Int128.And(opa, opb);
					break;
				case e_iunit.MUL:
					res = Int128.Mul(opa, opb);
					break;
				case e_iunit.SHLI:
					res = Int128.Shl(opa, (int)((insnn >> 16) & 0x3FL));
					break;
				case e_iunit.SHRI:
					res = Int128.Shr(opa, (int)((insnn >> 16) & 0x3FL));
					break;
				default:
					res.digits[0] = 0xCCCCCCCCL;
					res.digits[1] = 0xCCCCCCCCL;
					res.digits[2] = 0xCCCCCCCCL;
					res.digits[3] = 0xCCCCCCCCL;
					break;
			}
			return res;
		}
		public static string ScaleStr(int Sc)
		{
			switch(Sc)
			{
				case 0:	return "";
				case 1: return "*2";
				case 2: return "*4";
				case 3: return "*8";
				case 4: return "*16";
				case 5: return "*5";
				case 6: return "*10";
				case 7: return "*15";
				default:	return "";
			}
		}
		public static string DisProcessR3(ulong insnn, int Rd, int Rs1, int Rs2, int Rs3)
		{
			string str;
			nvioCpu.e_iunit funct;

			funct = (nvioCpu.e_iunit)(((insnn >> 34) & 0x3eL) | ((insnn >> 6) & 1L));
			switch (funct)
			{
				case e_iunit.ADD:
					str = "ADD    " + Regstr(Rd) + "," + Regstr(Rs1) + "," + Regstr(Rs2);
					break;
				case e_iunit.AND:
					str = "AND    " + Regstr(Rd) + "," + Regstr(Rs1) + "," + Regstr(Rs2);
					break;
				case e_iunit.MUL:
					str = "MUL    " + Regstr(Rd) + "," + Regstr(Rs1) + "," + Regstr(Rs2);
					break;
				case e_iunit.SHLI:
					str = "SHL    " + Regstr(Rd) + "," + Regstr(Rs1) + ",#" + Convert.ToString(Rs2);
					break;
				case e_iunit.SHRI:
					str = "SHR    " + Regstr(Rd) + "," + Regstr(Rs1) + ",#" + Convert.ToString(Rs2);
					break;
				default:
					str = "???";
					break;
			}
			return str;
		}
		static string DisRII(UInt64 instr)
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
		static string DisBranchTgt(Int64 instr, Int128 ip)
		{
			string str;
			Int64 tgt;

			tgt = ((instr >> 22) & 3) | (((instr >> 22) & 3) << 2) | ((instr >> 24) << 4);
			tgt = Int128.Add(ip, Int128.Convert((instr >> 24)<<4)).ToLong();
			tgt &= -16L;
			tgt |= ((instr >> 22) & 3) | (((instr >> 22) & 3) << 2);
			str = "$" + Convert.ToString(tgt, 16).PadLeft(10, '0');
			return str;
		}
		static string DisCallTgt(Int64 instr)
		{
			string str;

			Int64 tgt = (instr & 3) | ((instr & 63) << 2) | ((instr >> 10) << 8);
			str = Convert.ToString(tgt, 16).PadLeft(10, '0');
			return str;
		}
		public static string Disassemble(Int128 bundle, nvioCpu.e_unitTypes unit, Int64 instr, Int128 ip)
		{
			string str;
			UInt16 op4;
			UInt16 op6;
			UInt16 func5;
			Int16 Rd;
			Int16 Rs1;
			Int16 Rs2;
			Int16 Rs3;
			Int16 template;
			Int128 imm;
			bool longimm;
			char[] cha = new char[1];

			cha[0] = '0';
			template = (Int16)((bundle.digits[3] >> 24) & 0x7fL);
			longimm = false;
			imm = new Int128();
			if (template == 0x7d || template == 0x7e || template == 0x7f)
			{
				longimm = true;
				imm = Int128.Shr(bundle, 40);
				if ((imm.digits[2] & 0x8000L) == 0x8000L) {
					imm.digits[2] |= 0xffff0000L;
					imm.digits[3] = 0xffffffffL;
				}
			}
			op4 = (UInt16)((instr >> 6) & 15L);
			func5 = (UInt16)((instr >> 35) & 31L);
			Rd = (Int16)(instr & 63);
			Rs1 = (Int16)((instr >> 10) & 63);
			Rs2 = (Int16)((instr >> 16) & 63);
			Rs3 = (Int16)((instr >> 22) & 63);
			str = "";
			str = ip.ToString80().Substring(14, 6) + " ";
			str = str + Convert.ToString(instr, 16).PadLeft(10, '0') + " ";
			switch (unit)
			{
				case e_unitTypes.N:
					str = str + "<skipped>";
					break;
				case e_unitTypes.B:
					switch ((e_bunit)op4)
					{
						case e_bunit.CALL:
							str = str + "CALL   ";
							str = str + DisCallTgt(instr).TrimStart(cha);
							break;
						case e_bunit.RET:
							ulong spinc = (ulong)((instr >> 22) &0x3ffffL);
							str = str + "RET    #$" + Convert.ToString((long)spinc,16);
							break;
						case e_bunit.JMP:
							str = str + "JMP    ";
							str = str + DisCallTgt(instr).TrimStart(cha);
							break;
						case e_bunit.Bcc:
							switch ((e_bcond)(instr & 7))
							{
								case e_bcond.BEQ:
									str = str + "BEQ    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
								case e_bcond.BNE:
									str = str + "BNE    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
								case e_bcond.BLT:
									str = str + "BLT    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
								case e_bcond.BGE:
									str = str + "BGE    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
								default:
									str = str + "B??    ";
									str = str + Regstr(Rs1) + "," + Regstr(Rs2) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
							}
							break;
						case e_bunit.BBc:
							switch(instr & 3)
							{
								case 0:
									str = str + "BBS    ";
									str = str + Regstr(Rs1) + ",#$" + Convert.ToString(((int)Rs2 << 1)|(((int)instr >> 2) & 1),16) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
								case 1:
									str = str + "BBC    ";
									str = str + Regstr(Rs1) + ",#$" + Convert.ToString(((int)Rs2 << 1) | (((int)instr >> 2) & 1), 16) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
									break;
							}
							break;
						case e_bunit.BEQI:
							str = str + "BEQI   " + Regstr(Rs1) + ",#$" + Convert.ToString((Rs2 << 3) | (instr & 7),16) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
							break;
						case e_bunit.BNEI:
							str = str + "BNEI   " + Regstr(Rs1) + ",#$" + Convert.ToString((Rs2 << 3) | (instr & 7), 16) + "," + DisBranchTgt(instr, ip).TrimStart(cha);
							break;
						case e_bunit.Misc:
							switch((e_bmisc)func5)
							{
								case e_bmisc.SYNC:
									str = str + "SYNC   ";
									break;
							}
							break;
						case e_bunit.NOP:
							str = str + "NOP    ";
							break;
					}
					break;
				case nvioCpu.e_unitTypes.I:
					op6 = (UInt16)(((instr >> 6) & 15L) | (((instr >> 31) & 3L) << 4));
					switch ((nvioCpu.e_iunit)op6)
					{
						case e_iunit.R1:
							switch ((e_iunitR1)func5)
							{
								case e_iunitR1.NOT:
									str = str + "NOT    " + Regstr(Rd) + "," + Regstr(Rs1);
									break;
								case e_iunitR1.MOV:
									str = str + "MOV    " + Regstr(Rd) + "," + Regstr(Rs1);
									break;
							}
							break;
						case nvioCpu.e_iunit.R3E:
							return str + DisProcessR3((UInt64)instr, Rd, Rs1, Rs2, Rs3);
						case nvioCpu.e_iunit.R3O:
							return str + DisProcessR3((UInt64)instr, Rd, Rs1, Rs2, Rs3);

						case nvioCpu.e_iunit.ADDI:
							if (Rs1 == 0)
							{
								str = str + "LDI    ";
								if (longimm)
									str = str + Regstr(Rd) + ",#$" + imm.ToString80().TrimStart(cha);
								else
									str = str + Regstr(Rd) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							}
							else
							{
								str = str + "ADD    ";
								if (longimm)
									str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + imm.ToString80().TrimStart(cha);
								else
									str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							}
							break;
						case e_iunit.ADDS0:
							str = str + "ADDS0  ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ADDS1:
							str = str + "ADDS1  ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ADDS2:
							str = str + "ADDS2  ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ADDS3:
							str = str + "ADDS3  ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ANDI:
							str = str + "AND    ";
							if (longimm)
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + imm.ToString80().TrimStart(cha);
							else
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ORI:
							str = str + "ORI    ";
							if (longimm)
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + imm.ToString80().TrimStart(cha);
							else
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ORS0:
							str = str + "ORS0   ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ORS1:
							str = str + "ORS1   ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ORS2:
							str = str + "ORS2   ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.ORS3:
							str = str + "ORS3   ";
							str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.XORI:
							str = str + "XORI   ";
							if (longimm)
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + imm.ToString80().TrimStart(cha);
							else
								str = str + Regstr(Rd) + "," + Regstr(Rs1) + ",#$" + DisRII((UInt64)instr).TrimStart(cha);
							break;
						case e_iunit.CSR:
							int csrop = (int)(instr >> 38) & 3;
							int csrreg = (int)(instr >> 16) & 0xfff;
							int csrol = (int)(instr >> 36) & 3;
							str = str + "CSR";
							switch(csrop)
							{
								case 0:	str = str + "RD"; break;
								case 1: str = str + "RW"; break;
								case 2: str = str + "RS"; break;
								case 3: str = str + "RC"; break;
							}
							str = str + "  " + Regstr(Rd) + "," + "#$" + Convert.ToString(csrreg) + "," + Regstr(Rs1) + "," + Convert.ToString(csrol);
							break;
					}
					break;
				case e_unitTypes.M:
					int Sc = 1;
					ulong insnn = (ulong)instr;
					e_munit mopcode;
					bool isLoad;
					Int128 ma = new Int128();
					mopcode = (e_munit)(((insnn >> 6) & 15L) | (((insnn >> 33) & 3L) << 4));
					isLoad = ((uint)mopcode & 0x20) == 0;
					if (!isLoad)
					{
						if (mopcode == e_munit.PUSH)
						{
							ma.digits[0] = (ulong)(-(long)(insnn >> 35));
							ma.digits[0] &= 0xffffffffL;
							ma.digits[1] = 0xffffffffL;
							ma.digits[2] = 0xffffffffL;
							ma.digits[3] = 0xffffffffL;
						}
						else
						{
							ma.digits[0] = (insnn & 0x3fL) | (((insnn >> 22) & 0x1ffL) << 6) | (((insnn >> 35) & 0x1fL) << 15);
							ma.digits[1] = 0;
							ma.digits[2] = 0;
							ma.digits[3] = 0;
						}
					}
					// Loads
					else
					{
						ma.digits[0] = ((insnn >> 16) & 0x7ffffL) | (((insnn >> 35) & 0x1fL) << 15);
						ma.digits[1] = 0;
						ma.digits[2] = 0;
						ma.digits[3] = 0;
					}
					if ((ma.digits[0] & 0x80000000L) != 0)
					{
						ma.digits[1] = 0xffffffffL;
						ma.digits[2] = 0xffffffffL;
						ma.digits[3] = 0xffffffffL;
					}
					Sc = (int)((insnn >> 28) & 7L);
					switch (mopcode)
					{
						case e_munit.STB:
							str = str + "STB    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.STW:
							str = str + "STW    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.STT:
							str = str + "STT    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.STP:
							str = str + "STP    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.STO:
							str = str + "STO    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.STD:
							str = str + "STD    " + Regstr(Rs2) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.PUSH:
							str = str + "PUSH   " + Regstr(Rs2);
							break;
						case e_munit.PUSHC0:
							str = str + "PUSH   #$" + DisRII(insnn).TrimStart(cha);
							break;
						case e_munit.PUSHC1:
							str = str + "PUSH   #$" + DisRII(insnn).TrimStart(cha);
							break;
						case e_munit.PUSHC2:
							str = str + "PUSH   #$" + DisRII(insnn).TrimStart(cha);
							break;
						case e_munit.PUSHC3:
							str = str + "PUSH   #$" + DisRII(insnn).TrimStart(cha);
							break;
						case e_munit.MSX:
							switch ((e_munit5)func5)
							{
								case e_munit5.STBX:
									str = str + "STB    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.STWX:
									str = str + "STW    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.STTX:
									str = str + "STT    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.STPX:
									str = str + "STP    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.STOX:
									str = str + "STD    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.STDX:
									str = str + "STD    " + Regstr(Rs2) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.MEMSB:
									str = str + "MEMSB  ";
									break;
								case e_munit5.MEMDB:
									str = str + "MEMDB  ";
									break;
							}
							break;
						case e_munit.LDB:
							str = str + "LDB    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDBU:
							str = str + "LDBU   " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDW:
							str = str + "LDW    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDWU:
							str = str + "LDWU   " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDT:
							str = str + "LDT    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDTU:
							str = str + "LDTU   " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDP:
							str = str + "LDP    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDPU:
							str = str + "LDPU   " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDD:
							str = str + "LDD    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDO:
							str = str + "LDO    " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.LDOU:
							str = str + "LDOU   " + Regstr(Rd) + "," + ma.ToString80().TrimStart(cha);
							if (Rs1 != 0)
								str = str + "[" + Regstr(Rs1) + "]";
							break;
						case e_munit.POP:
							str = str + "POP    " + Regstr(Rd);
							break;
						case e_munit.MLX:
							switch ((e_munit5)func5)
							{
								case e_munit5.LDBX:
									str = str + "LDB    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDBUX:
									str = str + "LDBU   " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDWX:
									str = str + "LDW    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDWUX:
									str = str + "LDWU   " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDTX:
									str = str + "LDT    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDTUX:
									str = str + "LDTU   " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDPX:
									str = str + "LDP    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDPUX:
									str = str + "LDPU   " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDDX:
									str = str + "LDD    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDOX:
									str = str + "LDO    " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
								case e_munit5.LDOUX:
									str = str + "LDOU   " + Regstr(Rd) + ",";
									str = str + "[" + Regstr(Rs1) + "+" + Regstr(Rs3) + ScaleStr(Sc) + "]";
									break;
							}
							break;
					}
					break;
			}
			return str;
		}
		public void Step(SoC soc)
		{
			tick++;
			ibundle = soc.IFetch(ip);
			insn0 = ibundle.digits[0];
			insn0 |= ((ibundle.digits[1] & 0xffL) << 32);
			insn1 = ibundle.digits[1] >> 8;
			insn1 |= (ibundle.digits[2] << 24) & 0xffff000000L;
			insn2 = ibundle.digits[2] >> 16;
			insn2 |= (ibundle.digits[3] << 16) & 0xffffff0000L;
			template = (int)(ibundle.digits[3] >> 24) & 0x7f;
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
			switch (ip.digits[0] & 0xFL)
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
			Rd = (int)(insnn & 0x3fL);
			Rs1 = (int)((insnn >> 10) & 0x3fL);
			Rs2 = (int)((insnn >> 16) & 0x3fL);
			Rs3 = (int)((insnn >> 22) & 0x3fL);
			funct5 = (uint)((insnn >> 35) & 0x1fL);
			rii.digits[0] = (insnn >> 16) & 0x7fffL;
			rii.digits[0] |= ((insnn >> 33) & 0x7fL) << 15;
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
			if (template == 0x7d || template == 0x7E)
			{
				rii.digits[0] = insn1 & 0xffffffffL;
				rii.digits[1] = (insn1 >> 32) | ((insn2 & 0xffffffL) << 8);
				rii.digits[2] = (insn2 >> 24) & 0xffffL;
				rii.digits[3] = 0;
				if (((insn2 >> 39) & 1) != 0) {
					rii.digits[2] |= 0xffff0000L;
					rii.digits[3] = 0xffffffffL;
				}
			}
			// Compute Rd
			switch (unitn)
			{
				case e_unitTypes.N:
					Rd = 0;
					break;
				case e_unitTypes.B:
					bopcode = (e_bunit)((insnn >> 6) & 0xFL);
					switch (bopcode)
					{
					case e_bunit.JAL:	break;
					case e_bunit.RET:	break;
					case e_bunit.CALL:
						Rd = 61;
						break;
					case e_bunit.Misc:
						if ((e_bunit)funct5 != e_bunit.SEI)
							Rd = 0;
						break;
					default:
						Rd = 0;
						break;
					}
					break;
				case e_unitTypes.I:
					break;
				case e_unitTypes.F:
					Rd += 64;
					fopcode = (e_funit)((insnn >> 6) & 0xfL);
					if (fopcode==e_funit.FLT1)
					{
						if ((e_funit5)funct5 == e_funit5.FTOI)
							Rd -= 64;
					}
					break;
				case e_unitTypes.M:
					mopcode = (e_munit)(((insnn >> 6) & 0xfL) | (((insnn >> 33) & 0x3L) << 4));
					switch(mopcode)
					{
						case e_munit.PUSH:	break;
						case e_munit.PUSHC0:	break;
						case e_munit.PUSHC1:	break;
						case e_munit.PUSHC2:	break;
						case e_munit.PUSHC3:	break;
						case e_munit.TLB: break;
						default:
							if ((((uint)mopcode >> 5) & 1) == 0)
							{ // LOAD?
								if (mopcode == e_munit.LDFS || mopcode == e_munit.LDFD)
									Rd += 64;
							}
							else  // STORE
							{
								Rd = 0;
							}
							break;
					}
					break;
			}
			// Compute Rs1
			switch(unitn)
			{
				case e_unitTypes.B:	break;
				case e_unitTypes.I: break;
				case e_unitTypes.F:
					break;
				case e_unitTypes.M:	break;
			}
			// Compute Rs2
			switch(unitn)
			{
				case e_unitTypes.F:
					Rs2 += 64;
					break;
			}
			// Compute Rs3
			switch(unitn)
			{
				case e_unitTypes.F:
					Rs3 += 64;
					break;
			}
			// RFW
			switch (unitn)
			{
				case e_unitTypes.B:
					switch (bopcode)
					{
						case e_bunit.Misc:
							switch ((e_bunit)funct5)
							{
								case e_bunit.SEI:
									rfw = true;
									break;
								default:
									rfw = false;
									break;
							}
							break;
						case e_bunit.JAL: rfw = true; break;
						case e_bunit.CALL: rfw = true; break;
						case e_bunit.RET: rfw = true; break;
						default: rfw = false; break;
					}
					break;
				case e_unitTypes.I:
					rfw = true;
					break;
				case e_unitTypes.F:
					switch (fopcode)
					{
						case e_funit.FLT1:
							switch ((e_flt1)funct5)
							{
								case e_flt1.FCX: rfw = false; break;
								case e_flt1.FDX: rfw = false; break;
								case e_flt1.FEX: rfw = false; break;
								case e_flt1.FRM: rfw = false; break;
								case e_flt1.FSYNC: rfw = false; break;
								case e_flt1.FTX: rfw = false; break;
								default:	rfw = true; break;
							}
							break;
						default: rfw = true; break;
					}
					break;
				case e_unitTypes.M:
					if (((uint)mopcode & 0x20) == 0)
						rfw = true;
					else
					{
						switch(mopcode)
						{
							case e_munit.PUSH:	rfw = true; break;
							case e_munit.PUSHC0: rfw = true; break;
							case e_munit.PUSHC1: rfw = true; break;
							case e_munit.PUSHC2: rfw = true; break;
							case e_munit.PUSHC3: rfw = true; break;
							case e_munit.TLB:	rfw = true; break;
							case e_munit.CAS: rfw = true; break;
							case e_munit.MSX:
								switch((e_munit)funct5)
								{
									case e_munit.CASX:	rfw = true; break;
									default: rfw = false; break;
								}
								break;
							default: rfw = false; break;
						}
					}
					break;
				default: rfw = false; break;
			}
			opa = regfile[Rs1+regset].Clone();
			opb = regfile[Rs2+regset].Clone();
			opc = regfile[Rs3+regset].Clone();
			switch (unitn)
			{
				case e_unitTypes.N:
					IncIp(1);
					break;
				case e_unitTypes.B:
					switch((e_bunit)((insnn >> 6) & 15)) {
						case e_bunit.Bcc:
							ProcessBcc();
							break;
						case e_bunit.BBc:
							ProcessBBc();
							break;
						case e_bunit.BEQI:
							ProcessBEQI();
							break;
						case e_bunit.BNEI:
							ProcessBEQI();
							break;
						case e_bunit.JMP:
							ip.digits[0] = 0;
							ip.digits[1] &= 0xffffff00L;
							ip.digits[0] |= ((insnn & 0x3fL) << 2);
							ip.digits[0] |= (insnn & 3L);
							ip.digits[0] |= (((insnn >> 10)) << 8) & 0xffffffffL;
							ip.digits[1] |= (insnn >> 32);
							break;
						case e_bunit.CALL:
							res = ip.Clone();
							switch (res.digits[0] & 15L)
							{
								case 0:
									res.digits[0] |= 5L;
									break;
								case 5:
									res.digits[0] &= 0xfffffff0L;
									res.digits[0] |= 10L;
									break;
								case 10:
									res.digits[0] &= 0xfffffff0L;
									res = Int128.Add(res, Int128.Convert(0x10));
									break;
							}
							ip.digits[0] = 0;
							ip.digits[1] &= 0xffffff00L;
							ip.digits[0] |= ((insnn & 0x3fL) << 2);
							ip.digits[0] |= (insnn & 3L);
							ip.digits[0] |= (((insnn >> 10)) << 8) & 0xffffffffL;
							ip.digits[1] |= (insnn >> 32);
							break;
						case e_bunit.RET:
							ip = opb.Clone();
							res = Int128.Add(opa, Int128.Convert((insnn >> 22)<<1));
							break;
						case e_bunit.Misc:
							switch ((e_bmisc)funct5) {
								case e_bmisc.SYNC:
									IncIp(1);
									break;
							}
							break;
					}
					break;
				case e_unitTypes.I:
					aopcode = (uint)(((insnn >> 6) & 15L) | (((insnn >> 31) & 3L) << 4));
					IncIp(1);
					if (template == 0x7d || template == 0x7e)
					{
						IncIp(1);
						IncIp(1);
					}
					switch ((e_iunit)aopcode)
					{
						case e_iunit.R1:
							switch((e_iunitR1)funct5)
							{
								case e_iunitR1.NOT:
									if (Int128.EQ(opa, Int128.Convert(0x00)))
										res = Int128.Convert(0x01);
									else
										res = Int128.Convert(0x00);
									break;
								case e_iunitR1.MOV:
									res = opa.Clone() ;
									break;
							}
							break;
						case e_iunit.R3E:
							res = ProcessR3(insnn, opa, opb, opc);
							break;
						case e_iunit.R3O:
							res = ProcessR3(insnn, opa, opb, opc);
							break;
						case e_iunit.SLTI:
							res = Int128.Convert(Int128.LT(opa, opb));
							break;
						case e_iunit.ADDI:
							res = Int128.Add(opa, rii);
							break;
						case e_iunit.ADDS0:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							if ((rii.digits[0] & 0x80000L) != 0)
							{
								rii.digits[0] |= 0xfff00000L;
								rii.digits[1] = 0xffffffffL;
								rii.digits[2] = 0xffffffffL;
								rii.digits[3] = 0xffffffffL;
							}
							res = Int128.Add(opa, rii);
							break;
						case e_iunit.ADDS1:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							if ((rii.digits[0] & 0x80000L) != 0)
							{
								rii.digits[0] |= 0xfff00000L;
								rii.digits[1] = 0xffffffffL;
								rii.digits[2] = 0xffffffffL;
								rii.digits[3] = 0xffffffffL;
							}
							res = Int128.Add(opa, Int128.Shl(rii,20));
							break;
						case e_iunit.ADDS2:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							if ((rii.digits[0] & 0x80000L) != 0)
							{
								rii.digits[0] |= 0xfff00000L;
								rii.digits[1] = 0xffffffffL;
								rii.digits[2] = 0xffffffffL;
								rii.digits[3] = 0xffffffffL;
							}
							res = Int128.Add(opa, Int128.Shl(rii, 40));
							break;
						case e_iunit.ADDS3:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							if ((rii.digits[0] & 0x80000L) != 0)
							{
								rii.digits[0] |= 0xfff00000L;
								rii.digits[1] = 0xffffffffL;
								rii.digits[2] = 0xffffffffL;
								rii.digits[3] = 0xffffffffL;
							}
							res = Int128.Add(opa, Int128.Shl(rii, 60));
							break;
						case e_iunit.ORI:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							res = Int128.Or(opa, rii);
							break;
						case e_iunit.ORS0:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							res = Int128.Or(opa, rii);
							break;
						case e_iunit.ORS1:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							res = Int128.Or(opa, Int128.Shl(rii, 20));
							break;
						case e_iunit.ORS2:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							res = Int128.Or(opa, Int128.Shl(rii, 40));
							break;
						case e_iunit.ORS3:
							rii.digits[0] &= 0xfffffL;
							rii.digits[1] = 0;
							rii.digits[2] = 0;
							rii.digits[3] = 0;
							res = Int128.Or(opa, Int128.Shl(rii, 60));
							break;
						case e_iunit.CSR:
							e_csrreg csrreg = (e_csrreg)((int)(insnn >> 16) & 0xfff);
							int csrop = (int)(insnn >> 38) & 3;
							switch(csrop)
							{
								case 0:
									switch(csrreg)
									{
										case e_csrreg.TICK:
											res = Int128.Convert(tick);
											break;
										case e_csrreg.TVEC0:
											res = tvec[0].Clone();
											break;
										case e_csrreg.TVEC1:
											res = tvec[1].Clone();
											break;
										case e_csrreg.TVEC2:
											res = tvec[2].Clone();
											break;
										case e_csrreg.TVEC3:
											res = tvec[3].Clone();
											break;
									}
									break;
								case 1:
									switch (csrreg)
									{
										case e_csrreg.TVEC0:
											res = tvec[0].Clone();
											tvec[0] = opa.Clone();
											break;
										case e_csrreg.TVEC1:
											res = tvec[1].Clone();
											tvec[1] = opa.Clone();
											break;
										case e_csrreg.TVEC2:
											res = tvec[2].Clone();
											tvec[2] = opa.Clone();
											break;
										case e_csrreg.TVEC3:
											res = tvec[3].Clone();
											tvec[3] = opa.Clone();
											break;
									}
									break;
							}
							break;
					}
					break;
				case e_unitTypes.F:
					IncIp(1);
					if (template==0x7d || template==0x7e)
					{
						IncIp(1);
						IncIp(1);
					}
					break;
				case e_unitTypes.M:
					ulong Sc = 1;
					mopcode = (e_munit)(((insnn >> 6) & 15L) | (((insnn >> 33) & 3L) << 4));
					isLoad = ((uint)mopcode & 0x20)== 0;
					if (mopcode == e_munit.PUSHC0 || mopcode == e_munit.PUSHC1 || mopcode == e_munit.PUSHC2 || mopcode == e_munit.PUSHC3)
					{
						ma.digits[0] = 0xfffffff6L; // -10
						ma.digits[1] = 0xffffffffL;
						ma.digits[2] = 0xffffffffL;
						ma.digits[3] = 0xffffffffL;
					}
					else if (!isLoad)
					{
						if (mopcode == e_munit.PUSH)
						{
							ma.digits[0] = (ulong)(-(long)(insnn >> 35));
							ma.digits[0] &= 0xffffffffL;
							ma.digits[1] = 0xffffffffL;
							ma.digits[2] = 0xffffffffL;
							ma.digits[3] = 0xffffffffL;
						}
						else
						{
							ma.digits[0] = (insnn & 0x3fL) | (((insnn >> 22) & 0x1ffL) << 6) | (((insnn >> 35) & 0x1fL) << 15);
							ma.digits[1] = 0;
							ma.digits[2] = 0;
							ma.digits[3] = 0;
						}
					}
					// Loads
					else
					{
						if (mopcode == e_munit.POP)
						{
							ma.digits[0] = (ulong)((long)(insnn >> 35));
							ma.digits[0] &= 0x1fL;
							ma.digits[1] = 0x0L;
							ma.digits[2] = 0x0L;
							ma.digits[3] = 0x0L;
						}
						else
						{
							ma.digits[0] = ((insnn >> 16) & 0x7ffffL) | (((insnn >> 35) & 0x1fL) << 15);
							ma.digits[1] = 0;
							ma.digits[2] = 0;
							ma.digits[3] = 0;
						}
					}
					if ((ma.digits[0] & 0x80000000L) != 0)
					{
						ma.digits[1] = 0xffffffffL;
						ma.digits[2] = 0xffffffffL;
						ma.digits[3] = 0xffffffffL;
					}
					ma = Int128.Add(ma, opa);
					switch ((insnn >> 28) & 7L)
					{
						case 0: Sc = 1; break;
						case 1: Sc = 2; break;
						case 2: Sc = 4; break;
						case 3: Sc = 8; break;
						case 4: Sc = 16; break;
						case 5: Sc = 5; break;
						case 6: Sc = 10; break;
						case 7: Sc = 15; break;
					}
					if (isLoad)
						max.digits[0] = opa.digits[0] + (opc.digits[0] * Sc) + ((insnn >> 16) & 0x3f);
					else
						max.digits[0] = opa.digits[0] + (opc.digits[0] * Sc) + (insnn & 0x3f);
					max.digits[1] = 0;
					max.digits[2] = 0;
					max.digits[3] = 0;
					if ((max.digits[0] & 0x80000000L) != 0)
					{
						max.digits[1] = 0xffffffffL;
						max.digits[2] = 0xffffffffL;
						max.digits[3] = 0xffffffffL;
					}
					switch (mopcode)
					{
						case e_munit.STB:
							soc.Write(ma, opb, 1);
							break;
						case e_munit.STW:
							soc.Write(ma, opb, 2);
							break;
						case e_munit.STT:
							soc.Write(ma, opb, 4);
							break;
						case e_munit.STP:
							soc.Write(ma, opb, 5);
							break;
						case e_munit.STO:
							soc.Write(ma, opb, 8);
							break;
						case e_munit.STD:
							soc.Write(ma, opb, 10);
							break;
						case e_munit.PUSH:
							soc.Write(ma, opb, 10);
							res = ma;
							break;
						case e_munit.PUSHC0:
							soc.Write(ma, rii, 10);
							res = ma;
							break;
						case e_munit.PUSHC1:
							soc.Write(ma, rii, 10);
							res = ma;
							break;
						case e_munit.PUSHC2:
							soc.Write(ma, rii, 10);
							res = ma;
							break;
						case e_munit.PUSHC3:
							soc.Write(ma, rii, 10);
							res = ma;
							break;
						case e_munit.MSX:
							switch((e_munit5)funct5)
							{
								case e_munit5.STBX:
									soc.Write(max, opb, 1);
									break;
								case e_munit5.STWX:
									soc.Write(max, opb, 2);
									break;
								case e_munit5.STTX:
									soc.Write(max, opb, 4);
									break;
								case e_munit5.STPX:
									soc.Write(max, opb, 5);
									break;
								case e_munit5.STOX:
									soc.Write(max, opb, 8);
									break;
								case e_munit5.STDX:
									soc.Write(max, opb, 10);
									break;
							}
							break;
						case e_munit.LDB:
							res = soc.Read(ma).SX8();
							break;
						case e_munit.LDBU:
							res = soc.Read(ma).ZX8();
							break;
						case e_munit.LDW:
							res = soc.Read(ma).SX16();
							break;
						case e_munit.LDWU:
							res = soc.Read(ma).ZX16();
							break;
						case e_munit.LDT:
							res = soc.Read(ma).SX32();
							break;
						case e_munit.LDTU:
							res = soc.Read(ma).ZX32();
							break;
						case e_munit.LDP:
							res = soc.Read(ma).SX40();
							break;
						case e_munit.LDPU:
							res = soc.Read(ma).ZX40();
							break;
						case e_munit.LDD:
							res = soc.Read(ma).SX80();
							break;
						case e_munit.LDO:
							res = soc.Read(ma).SX64();
							break;
						case e_munit.LDOU:
							res = soc.Read(ma).ZX64();
							break;
						case e_munit.POP:
							res = soc.Read(opa).SX80();
							regfile[Rs1+regset] = ma;
							break;
						case e_munit.MLX:
							switch((e_munit5)funct5)
							{
								case e_munit5.LDBX:
									res = soc.Read(max).SX8();
									break;
								case e_munit5.LDBUX:
									res = soc.Read(max).ZX8();
									break;
								case e_munit5.LDWX:
									res = soc.Read(max).SX16();
									break;
								case e_munit5.LDWUX:
									res = soc.Read(max).ZX16();
									break;
								case e_munit5.LDTX:
									res = soc.Read(max).SX32();
									break;
								case e_munit5.LDTUX:
									res = soc.Read(max).SX32();
									break;
								case e_munit5.LDPX:
									res = soc.Read(max).SX40();
									break;
								case e_munit5.LDPUX:
									res = soc.Read(max).ZX40();
									break;
								case e_munit5.LDOX:
									res = soc.Read(max).SX64();
									break;
								case e_munit5.LDOUX:
									res = soc.Read(max).ZX64();
									break;
								case e_munit5.LDDX:
									res = soc.Read(max).SX80();
									break;
							}
							break;
					}
					IncIp(1);
					break;
			}
			if (rfw)
				regfile[Rd+regset] = res.Clone();
			regfile[0+regset] = Int128.Convert(0);
			regfile[64+regset] = Int128.Convert(0);
			icount++;
		}
	}
}
