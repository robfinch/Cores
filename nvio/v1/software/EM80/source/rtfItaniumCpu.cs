using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EM80
{
	class rtfItaniumCpu
	{
		public enum e_unitTypes { N = 0, B = 1, I = 2, F = 3, M = 4 };
		static public e_unitTypes[,] unitx = new e_unitTypes[66, 3] {
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
		public enum e_iunit
		{
			R1 = 1,
			R3E = 2,
			R3O = 3,
			ADDI = 4,
			ANDI = 8,
			ORI = 9,
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
			LDO = 0x09,
			LDOU = 0x0D,
			LDD = 0x03,
			LDT = 0x08,
			LDTU = 0x0C,
			MLX = 0x0F,
			LDFS = 0x10,
			LDFD = 0x11,
			STB = 0x20,
			STD = 0x23,
			STT = 0x28,
			STW = 0x21,
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
			STOX = 0x09,
			STDX = 0x03,
			LDBX = 0x00,
			LDBUX = 0x04,
			LDDX = 0x03,
			LDOX = 0x09,
			LDOUX = 0x0D,
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
			rii = new Int128();
			ma = new Int128();
			max = new Int128();
			brdisp = new Int128();
			res = new Int128();
			regset = 0;
		}
		public void Reset()
		{
			ip = Int128.Convert(0xfffffffffffC0100L);
			ip.digits[2] = 0xffffffffL;
			ip.digits[3] = 0xffffffffL;
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
		public void Step(SoC soc)
		{
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
					if (((uint)mopcode & 0x20) != 0)
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
						case e_munit.MSX:
							switch((e_munit5)funct5)
							{
								case e_munit5.STBX:
									soc.Write(max, opb, 1);
									break;
								case e_munit5.STOX:
									soc.Write(max, opb, 8);
									break;
							}
							break;
						case e_munit.LDB:
							res = soc.Read(ma);
							res.digits[0] &= 0xffL;
							res.digits[1] = 0;
							res.digits[2] = 0;
							res.digits[3] = 0;
							if ((res.digits[1] & 0x80L) != 0)
							{
								res.digits[0] |= 0xffffff00L;
								res.digits[1] = 0xffffffffL;
								res.digits[2] = 0xffffffffL;
								res.digits[3] = 0xffffffffL;
							}
							break;
						case e_munit.LDBU:
							res = soc.Read(ma);
							res.digits[0] &= 0xffL;
							res.digits[1] = 0;
							res.digits[2] = 0;
							res.digits[3] = 0;
							break;
						case e_munit.LDD:
							res = soc.Read(ma);
							if ((res.digits[2] & 0x8000L) != 0)
							{
								res.digits[2] |= 0xffff0000L;
								res.digits[3] = 0xffffffffL;
							}
							break;
						case e_munit.LDO:
							res = soc.Read(ma);
							if ((res.digits[1] & 0x80000000L) != 0)
							{
								res.digits[2] = 0xffffffffL;
								res.digits[3] = 0xffffffffL;
							}
							break;
						case e_munit.LDOU:
							res = soc.Read(ma);
							res.digits[2] = 0x00000000L;
							res.digits[3] = 0x00000000L;
							break;
						case e_munit.MLX:
							switch((e_munit5)funct5)
							{
								case e_munit5.LDBX:
									res = soc.Read(max);
									res.digits[0] &= 0xffL;
									res.digits[1] = 0;
									res.digits[2] = 0;
									res.digits[3] = 0;
									if ((res.digits[1] & 0x80L) != 0)
									{
										res.digits[0] |= 0xffffff00L;
										res.digits[1] = 0xffffffffL;
										res.digits[2] = 0xffffffffL;
										res.digits[3] = 0xffffffffL;
									}
									break;
								case e_munit5.LDDX:
									res = soc.Read(max);
									res.digits[2] &= 0xffffL;
									res.digits[3] = 0;
									if ((res.digits[2] & 0x8000L) != 0)
									{
										res.digits[2] |= 0xffff0000L;
										res.digits[3] = 0xffffffffL;
									}
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
		}
	}
}
