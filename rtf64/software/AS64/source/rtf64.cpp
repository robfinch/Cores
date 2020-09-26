// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AS64 - Assembler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"
#define I_RR	002
#define I_R1	0x8B
#define I_JRL	0xD3

#define I_MOVE	0x12
#define I_MOVO	0x13

// Root Level Opcodes
#define I_BRK		0x00
#define I_R3A		0x01
#define I_R2A		0x02
#define I_R3B		0x03
#define I_ADDI	0x04
#define I_SUBFI 0x05
#define I_MULI	0x06
#define I_CMPI	0x07
#define I_ANDI	0x08
#define I_ORI		0x09
#define I_EORI	0x0A
#define I_XORI	0x0A
#define I_BITI	0x0B
#define I_SHIFT	0x0C
#define I_SET		0x0D
#define I_MULUI	0x0E
#define I_CSR		0x0F
#define I_DIVI	0x10
#define I_DIVUI 0x11
#define I_DIVSUI 0x12
#define I_R2B		0x13
#define I_MULSUI	0x16
#define I_REMI	0x18
#define I_REMU	0x19
#define I_BYTNDX	0x1A
#define I_WYDNDX	0x1B
#define I_EXT		0x1C
#define I_DEP		0x1D
#define I_DEPI	0x1E
#define I_FFO		0x1F
#define I_REMSUI	0x20
#define I_DIVRI	0x21
#define I_SEQI	0x26
#define I_SNEI	0x27
#define I_SLTI	0x28
#define I_SGEI	0x29
#define I_SLEI  0x2A
#define I_SGTI  0x2B
#define I_SLTUI	0x2C
#define I_SGEUI	0x2D
#define I_SLEUI 0x2E
#define I_SGTUI 0x2F
#define I_JSR		0x30
#define I_JMP		0x31
#define I_JSRR	0x32
#define I_JMPR	0x33
#define I_RTS		0x34
#define I_RTE		0x35
#define I_BEQ		0x36
#define I_BNE		0x37
#define I_BLT		0x38
#define I_BGE		0x39
#define I_BLE		0x3A
#define I_BGT		0x3B
#define I_BLTU	0x3C
#define I_BGEU	0x3D
#define I_BLEU	0x3E
#define I_BGTU	0x3F
#define I_BVC		0x40
#define I_BVS		0x41
#define I_BOD		0x42
#define I_BPS		0x44
#define I_LMI		0x48
#define I_LUI		0x50
#define I_AMIIP	0x54
#define I_GCSUBI	0x75
#define I_OSR2	0x7A
#define I_CACHEI	0x7B
#define I_LDB		0x80
#define I_LDBU	0x81
#define I_LDW		0x82
#define I_LDWU	0x83
#define I_LDT		0x84
#define I_LDTU	0x85
#define I_LDO		0x86
#define I_LDOR	0x87
#define I_LDOT	0x88
#define I_LDX		0x8F
#define I_STB		0xA0
#define I_STW		0xA1
#define I_STT		0xA2
#define I_STO		0xA3
#define I_STOC	0xA4
#define I_STPTR	0xA5
#define I_STOT	0xA8
#define I_STX		0xAF

#define I_FLT2	0xF2
#define I_FMA		0xF4
#define I_FMS		0xF5
#define I_FNMA	0xF6
#define I_FNMS	0xF7

// 3r Operations
#define I_MIN		0x0
#define I_MAX		0x1
#define I_MAJ		0x2
#define I_MUX		0x3
#define I_ADD3	0x4
#define I_SUB3	0x5
#define I_FLIP	0x7
#define I_AND3	0x0
#define I_OR3		0x1
#define I_EOR3	0x2
#define I_DEP3	0x3
#define I_EXT3	0x4
#define I_EXTU3	0x5
#define I_BLEND	0x6

// 2r Operations
#define I_AND2	0x00
#define I_OR2		0x01
#define I_EOR2	0x02
#define I_XOR2	0x02
#define I_BMM		0x03
#define I_ADD2	0x04
#define I_SUB2	0x05
#define I_MUL		0x06
#define I_CMP		0x07
#define I_NAND	0x08
#define I_NOR		0x09
#define I_ENOR	0x0A
#define I_XNOR	0x0A
#define I_BIT		0x0B
#define I_R1		0x0C
#define I_MOV		0x0D
#define I_MULU	0x0E
#define I_MULH	0x0F
#define I_DIV		0x20
#define I_DIVU	0x21
#define I_DIVSU	0x22
#define I_REM		0x23
#define I_REMU	0x24
#define I_REMSU	0x25
#define I_MULSU	0x26
#define I_PERM	0x27
#define I_PTRDIF	0x28
#define I_DIF		0x29
#define I_BYTNDX2	0x2A
#define I_WYDNDX2	0x2B
#define I_MULSUH	0x2D
#define I_MULUH	0x2E

// Shift Operations
#define I_SHL		0x0
#define I_SHLI	0x8
#define I_ASL		0x0
#define I_ASLI	0x8
#define I_LSR		0x1
#define I_LSRI  0x9
#define I_SHR		0x1
#define I_SHRI	0x9
#define I_ASR		0x4
#define I_ASRI	0xC
#define I_ROL		0x2
#define I_ROLI	0xA
#define I_ROR		0x3
#define I_RORI	0xB

// 2r Set operations
#define I_SEQ		0x0
#define I_SNE		0x1
#define I_SLT		0x4
#define I_SLTU	0x5
#define I_SGE		0x6
#define I_SGEU	0x7

#define I_SLTI	0xC0
#define I_SGEI	0xC1
#define I_SLEI	0xC2
#define I_SGTI	0xC3
#define I_SLTUI	0xC4
#define I_SGEUI	0xC5
#define I_SLEUI	0xC6
#define I_SGTUI	0xC7

#define I_FLT1	0xE1
#define I_FLT2	0xE2

static void (*jumptbl[tk_last_token])();
static int64_t parm1[tk_last_token];
static int64_t parm2[tk_last_token];
static int64_t parm3[tk_last_token];

extern InsnStats insnStats;
static void ProcessEOL(int opt);
extern void process_message();
static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc, int *seg);

extern char *pif1;
extern int first_rodata;
extern int first_data;
extern int first_bss;
extern int htblmax;
extern int pass;
extern int num_cinsns;

static int64_t ca;
static int recflag;

extern int use_gp;

static int regSP = 31;
static int regFP = 30;
static int regGP = 29;
static int regTP = 28;
static int regArg = 20;
static int regTmp = 3;
static int regReg = 10;
static int regCB = 2;
static int regXL = 1;
static int regCnst;

#define OPT64     0
#define OPTX32    1
#define OPTLUI0   0
#define LB16	-31653LL

#define S_BYTE	0
#define S_WYDE	1
#define S_TETRA	2
#define S_OCTA	3
#define S_HEXI	4

#define RT(x)		((x) << 8LL)
#define RD(x)		((x) << 8LL)
#define RA(x)		((x) << 13LL)
#define RS1(x)	((x) << 13LL)
#define RB(x)		((x) << 18LL)
#define RS2(x)	((x) << 18LL)
#define RC(x)		((x) << 23LL)
#define RS3(x)	((x) << 23LL)
#define RCF(x)	((x) << 31LL)
#define FUNC5(x)	(((x) & 0x1fLL) << 26LL)
#define FUNC6(x)	(((x) & 0x3FLL) << 23LL)
#define FMT(x)	(((x) & 7LL) << 23LL)
#define IMM(x)	(((x) & 0x1fffLL) << 18LL)
#define SHI7(x)	((((x) & 0x60LL) << 29LL) | RB(((x) & 0x1fLL)))
#define STDISP(x)	((((x) & 0x1fLL) << 8LL) | (((x) & 0x1fE0LL) << 23LL))
#define LDDISP(x)	(((x) & 0x3ffffLL) << 13LL)
#define AM(x)		(((x) & 1LL << 38LL))
#define RETIMM(x)	(((x) & 0x1ffff0LL) << 18LL)
#define COND(x)		(((x) & 0x1fLL) << 13LL)
#define P2(x)			(((x) & 3LL) << 11LL)
#define BRDISP(x)	(((x) & 0x3fffffLL) << 18LL)

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void error(char *msg)
{
	printf("%s. (%d)\n", msg, /*mname.c_str(), */lineno);
}

// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// Parses pretty register names like SP or BP in addition to r1,r2,etc.
// ----------------------------------------------------------------------------

//static int getRegisterX()
//{
//    int reg;
//
//    while(isspace(*inptr)) inptr++;
//	if (*inptr == '$')
//		inptr++;
//    switch(*inptr) {
//    case 'r': case 'R':
//        if ((inptr[1]=='a' || inptr[1]=='A') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 29;
//        }
//         if (isdigit(inptr[1])) {
//             reg = inptr[1]-'0';
//             if (isdigit(inptr[2])) {
//                 reg = 10 * reg + (inptr[2]-'0');
//                 if (isdigit(inptr[3])) {
//                     reg = 10 * reg + (inptr[3]-'0');
//                     if (isIdentChar(inptr[4]))
//                         return -1;
//                     inptr += 4;
//                     NextToken();
//                     return reg;
//                 }
//                 else if (isIdentChar(inptr[3]))
//                     return -1;
//                 else {
//                     inptr += 3;
//                     NextToken();
//                     return reg;
//                 }
//             }
//             else if (isIdentChar(inptr[2]))
//                 return -1;
//             else {
//                 inptr += 2;
//                 NextToken();
//                 return reg;
//             }
//         }
//         else return -1;
//    case 'a': case 'A':
//         if (isdigit(inptr[1])) {
//             reg = inptr[1]-'0' + 18;
//             if (isIdentChar(inptr[2]))
//                 return -1;
//             else {
//                 inptr += 2;
//                 NextToken();
//                 return reg;
//             }
//         }
//         else return -1;
//    case 'b': case 'B':
//        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 30;
//        }
//        break;
//    case 'f': case 'F':
//        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 2;
//        }
//        break;
//    case 'g': case 'G':
//        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 26;
//        }
//        break;
//    case 'p': case 'P':
//        if ((inptr[1]=='C' || inptr[1]=='c') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 31;
//        }
//        break;
//    case 's': case 'S':
//        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 31;
//        }
//        break;
//    case 't': case 'T':
//         if (isdigit(inptr[1])) {
//             reg = inptr[1]-'0' + 26;
//             if (isIdentChar(inptr[2]))
//                 return -1;
//             else {
//                 inptr += 2;
//                 NextToken();
//                 return reg;
//             }
//         }
//        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 15;
//        }
//        /*
//        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 24;
//        }
//        */
//        break;
//	// lr
//    case 'l': case 'L':
//        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
//            inptr += 2;
//            NextToken();
//            return 29;
//        }
//        break;
//	// xlr
//    case 'x': case 'X':
//        if ((inptr[1]=='L' || inptr[1]=='l') && (inptr[2]=='R' || inptr[2]=='r') && 
//			!isIdentChar(inptr[3])) {
//            inptr += 3;
//            NextToken();
//            return 28;
//        }
//        break;
//    default:
//        return -1;
//    }
//    return -1;
//}
static int getRegisterX()
{
  int reg;
	char *p;

  while(isspace(*inptr))
		inptr++;
	if (*inptr == '$')
		inptr++;
  switch(*inptr) {
  case 'r': case 'R':
    if (inptr[1]=='a' || inptr[1]=='A') {
			if (isdigit(inptr[2])) {
				if (inptr[2] != '0' && inptr[2] != '1')
					return (-1);
				if (!isIdentChar(inptr[3])) {
					inptr += 3;
					NextToken();
					return (96+inptr[2]-'0');
				}
				return (-1);
			}
			return (-1);
    }
    if (isdigit(inptr[1])) {
      reg = inptr[1]-'0';
      if (isdigit(inptr[2])) {
        reg = 10 * reg + (inptr[2]-'0');
        if (isdigit(inptr[3])) {
          reg = 10 * reg + (inptr[3]-'0');
					if (isdigit(inptr[4])) {
						reg = 10 * reg + (inptr[4] - '0');
						if (isIdentChar(inptr[5]))
							return (-1);
						else {
							inptr += 5;
							NextToken();
							return (reg);
						}
					}
					else if (isIdentChar(inptr[4]))
						return (-1);
					else {
						inptr += 4;
						NextToken();
						return (reg);
					}
        }
        else if (isIdentChar(inptr[3]))
          return (-1);
        else {
          inptr += 3;
          NextToken();
          return (reg);
        }
      }
      else if (isIdentChar(inptr[2]))
        return (-1);
      else {
        inptr += 2;
        NextToken();
        return (reg);
      }
    }
		return (-1);

  case 'a': case 'A':
    if (isdigit(inptr[1])) {
      reg = inptr[1]-'0' + regArg;
      if (isIdentChar(inptr[2]))
        return (-1);
      inptr += 2;
      NextToken();
      return (reg);
    }
		return (-1);

  case 'f': case 'F':
		if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
			inptr += 2;
			NextToken();
			return (regFP);
		}
		if (isdigit(inptr[1])) {
			reg = 64 + inptr[1] - '0';
			if (isdigit(inptr[2])) {
				reg = reg * 10 + inptr[2] - '0';
				if (!isIdentChar(inptr[3])) {
					inptr += 3;
					NextToken();
					return (reg);
				}
			}
			if (!isIdentChar(inptr[2])) {
				inptr += 2;
				NextToken();
				return (reg);
			}
		}
		break;

  case 'g': case 'G':
    if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
      inptr += 2;
      NextToken();
      return (regGP);
    }
    break;

  case 's': case 'S':
    if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
      inptr += 2;
      NextToken();
      return (regSP);
    }
		if (isdigit(inptr[1])) {
			if (!isIdentChar(inptr[2])) {
				inptr += 2;
				NextToken();
				return (regReg + inptr[1] - '0');
			}
		}
    break;

    case 't': case 'T':
      if (isdigit(inptr[1])) {
        reg = inptr[1]-'0' + regTmp;
        if (isIdentChar(inptr[2]))
          return (-1);
        else {
          inptr += 2;
          NextToken();
          return (reg);
        }
      }
      if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
          inptr += 2;
          NextToken();
          return (regTP);
      }
      break;
	// lk0 to lk7
    case 'l': case 'L':
			if ((inptr[1] == 'R' || inptr[1] == 'r') && !isIdentChar(inptr[2])) {
				reg = 96;
					inptr += 2;
					NextToken();
					return (reg);
				}
        if (inptr[1]=='K' || inptr[1]=='k') {
					if (isdigit(inptr[1]) && !isIdentChar(inptr[2])) {
						reg = inptr[1] - '0' + 96;
						inptr += 3;
						NextToken();
						return (reg);
					}
        }
        break;
	// cr0 to cr7
		case 'c': case 'C':
			if (inptr[1] == 'R' || inptr[1] == 'r') {
				if (isdigit(inptr[2]) && !isIdentChar(inptr[3])) {
					reg = inptr[2] - '0' + 112;
					inptr += 3;
					NextToken();
					return (reg);
				}
			}
			break;
		// xlr
    case 'x': case 'X':
			if (isdigit(inptr[1])) {
				reg = inptr[1] - '0';
				if (isdigit(inptr[2])) {
					reg = reg * 10 + inptr[2] - '0';
					if (!isIdentChar(inptr[3])) {
						inptr += 3;
						NextToken();
						return (reg);
					}
					return (-1);
				}
				if (!isIdentChar(inptr[2])) {
					inptr += 2;
					NextToken();
					return (reg);
				}
				return (-1);
			}
        if ((inptr[1]=='L' || inptr[1]=='l') && (inptr[2]=='R' || inptr[2]=='r') && 
			!isIdentChar(inptr[3])) {
            inptr += 3;
            NextToken();
            return (regXL);
        }
        break;
	case 'v': case 'V':
		// vm0 to vm7
		if ((inptr[1] == 'M' || inptr[1] == 'm') && !isIdentChar(inptr[2])) {
			if (isdigit(inptr[1]) && !isIdentChar(inptr[2])) {
				reg = inptr[1] - '0' + 104;
				inptr += 3;
				NextToken();
				return (reg);
			}
		}
		// v0 to v31
		if (isdigit(inptr[1])) {
             reg = inptr[1]-'0' + 64;
             if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return (reg);
             }
         }
		 break;
	default:
        return -1;
    }
    return -1;
}

static int isdelim(char ch)
{
    return ch==',' || ch=='[' || ch=='(' || ch==']' || ch==')' || ch=='.';
}

// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// Parses pretty register names like SP or BP in addition to r1,r2,etc.
// ----------------------------------------------------------------------------

static int getVecRegister()
{
    int reg;

    while(isspace(*inptr)) inptr++;
	if (*inptr=='$')
		inptr++;
    switch(*inptr) {
    case 'v': case 'V':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0';
             if (isdigit(inptr[2])) {
                 reg = 10 * reg + (inptr[2]-'0');
                 if (isdigit(inptr[3])) {
                     reg = 10 * reg + (inptr[3]-'0');
                     if (isIdentChar(inptr[4]))
                         return -1;
                     inptr += 4;
                     NextToken();
                     return reg;
                 }
                 else if (isIdentChar(inptr[3]))
                     return -1;
                 else {
                     inptr += 3;
                     NextToken();
                     return reg;
                 }
             }
             else if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return reg;
             }
         }
		 else if (inptr[1]=='l' || inptr[1]=='L') {
			 if (!isIdentChar(inptr[2])) {
				 inptr += 2;
				 NextToken();
				 return 0x2F;
			 }
		 }
         else if (inptr[1]=='m' || inptr[1]=='M') {
			 if (isdigit(inptr[2])) {
				 if (inptr[2] >= '0' && inptr[2] <= '7') {
					 if (!isIdentChar(inptr[3])) {
						 reg = 0x20 | (inptr[2]-'0');
						 inptr += 3;
						 NextToken();
						 return (reg);
					 }
				 }
			 }
		 }
		 return -1;
	}
    return -1;
}

// ----------------------------------------------------------------------------
// Get the friendly name of a special purpose register.
// ----------------------------------------------------------------------------

static int DSD7_getSprRegister()
{
    int reg = -1;
    int pr;

    while(isspace(*inptr)) inptr++;
//    reg = getCodeareg();
    if (reg >= 0) {
       reg |= 0x10;
       return reg;
    }
    if (inptr[0]=='p' || inptr[0]=='P') {
         if (isdigit(inptr[1]) && isdigit(inptr[2])) {
              pr = ((inptr[1]-'0' * 10) + (inptr[2]-'0'));
              if (!isIdentChar(inptr[3])) {
                  inptr += 3;
                  NextToken();
                  return pr | 0x40;
              }
         }
         else if (isdigit(inptr[1])) {
              pr = (inptr[1]-'0');
              if (!isIdentChar(inptr[2])) {
                  inptr += 2;
                  NextToken();
                  return pr | 0x40;
              }
         }
     }

    while(isspace(*inptr)) inptr++;
    switch(*inptr) {

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
         NextToken();
         NextToken();
         return (int)ival.low & 0xFFF;

    // arg1
    case 'a': case 'A':
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='g' || inptr[2]=='G') &&
             (inptr[3]=='1' || inptr[3]=='1') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 58;
         }
         break;
    // bear
    case 'b': case 'B':
         if ((inptr[1]=='e' || inptr[1]=='E') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='r' || inptr[3]=='R') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 11;
         }
         break;
    // cas clk cr0 cr3 cs CPL
    case 'c': case 'C':
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='s' || inptr[2]=='S') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 44;
         }
         if ((inptr[1]=='l' || inptr[1]=='L') &&
             (inptr[2]=='k' || inptr[2]=='K') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x06;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='0') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x00;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='3') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x03;
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2F;
               }
            }
            inptr += 2;
            NextToken();
            return 0x27;
        }
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='l' || inptr[2]=='L') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 42;
         }
         break;

    // dbad0 dbad1 dbctrl dpc dsp ds
    case 'd': case 'D':
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='0' || inptr[4]=='0') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 50;
         }
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='1' || inptr[4]=='1') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 51;
         }
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='2' || inptr[4]=='2') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 52;
         }
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='3' || inptr[4]=='3') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 53;
         }
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             (inptr[3]=='t' || inptr[3]=='T') &&
             (inptr[4]=='r' || inptr[4]=='R') &&
             (inptr[5]=='l' || inptr[5]=='L') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 54;
         }
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 7;
         }
         if (
             (inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='p' || inptr[2]=='P') &&
             (inptr[3]=='c' || inptr[3]=='C') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 7;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             (inptr[2]=='p' || inptr[2]=='P') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 16;
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&         
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x29;
               }
            }
            inptr += 2;
            NextToken();
            return 0x21;
        }
         break;

    // ea epc esp es
    case 'e': case 'E':
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 40;
         }
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 9;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             (inptr[2]=='p' || inptr[2]=='P') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 17;
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&  
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2A;
               }
            }
            inptr += 2;
            NextToken();
            return 0x22;
        }
         break;

    // fault_pc fs
    case 'f': case 'F':
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='u' || inptr[2]=='U') &&
             (inptr[3]=='l' || inptr[3]=='L') &&
             (inptr[4]=='t' || inptr[4]=='T') &&
             (inptr[5]=='_' || inptr[5]=='_') &&
             (inptr[6]=='p' || inptr[6]=='P') &&
             (inptr[7]=='c' || inptr[7]=='C') &&
             !isIdentChar(inptr[8])) {
             inptr += 8;
             NextToken();
             return 0x08;
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2B;
               }
            }
            inptr += 2;
            NextToken();
            return 0x23;
        }
         break;

    // gs GDT
    case 'g': case 'G':
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') && 
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2C;
               }
            }
            inptr += 2;
            NextToken();
            return 0x24;
        }
        if ((inptr[1]=='d' || inptr[1]=='D') &&
           (inptr[2]=='t' || inptr[2]=='T') &&
            !isIdentChar(inptr[3])) {
            inptr += 3;
            NextToken();
            return 41;
        }
        break;

    // history
    case 'h': case 'H':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='s' || inptr[2]=='S') &&
             (inptr[3]=='t' || inptr[3]=='T') &&
             (inptr[4]=='o' || inptr[4]=='O') &&
             (inptr[5]=='r' || inptr[5]=='R') &&
             (inptr[6]=='y' || inptr[6]=='Y') &&
             !isIdentChar(inptr[7])) {
             inptr += 7;
             NextToken();
             return 0x0D;
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2D;
               }
            }
            inptr += 2;
            NextToken();
            return 0x25;
        }
         break;

    // ipc isp ivno
    case 'i': case 'I':
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 8;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             (inptr[2]=='p' || inptr[2]=='P') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 15;
         }
         if ((inptr[1]=='v' || inptr[1]=='V') &&
             (inptr[2]=='n' || inptr[2]=='N') &&
             (inptr[3]=='o' || inptr[3]=='O') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x0C;
         }
         break;


    // LC LDT
    case 'l': case 'L':
         if ((inptr[1]=='c' || inptr[1]=='C') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x33;
         }
         if ((inptr[1]=='d' || inptr[1]=='D') &&
            (inptr[2]=='t' || inptr[2]=='T') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 40;
         }
         break;

    // pregs
    case 'p': case 'P':
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='e' || inptr[2]=='E') &&
             (inptr[3]=='g' || inptr[3]=='G') &&
             (inptr[4]=='s' || inptr[4]=='S') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 52;
         }
         break;

    // rand
    case 'r': case 'R':
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='n' || inptr[2]=='N') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x12;
         }
         break;
    // ss_ll srand1 srand2 ss segsw segbase seglmt segacr
    case 's': case 'S':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             (inptr[2]=='_' || inptr[2]=='_') &&
             (inptr[3]=='l' || inptr[3]=='L') &&
             (inptr[4]=='l' || inptr[4]=='L') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 0x1A;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='n' || inptr[3]=='N') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='1') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 0x10;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='n' || inptr[3]=='N') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='2') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 0x11;
         }
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='r' || inptr[2]=='R') &&
             isdigit(inptr[3]) && isdigit(inptr[4]) &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return (inptr[3]-'0')*10 + (inptr[4]-'0');
         }
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x2E;
               }
            }
            inptr += 2;
            NextToken();
            return 0x26;
         }
         // segxxx
         if ((inptr[1]=='e' || inptr[1]=='E') &&
             (inptr[2]=='g' || inptr[2]=='G')) {
             // segsw
             if ((inptr[3]=='s' || inptr[3]=='S') &&
                  (inptr[4]=='w' || inptr[4]=='W') &&
                  !isIdentChar(inptr[5])) {
               inptr += 5;
               NextToken();
               return 43;
             }
             // segbase
             if ((inptr[3]=='b' || inptr[3]=='B') &&
                  (inptr[4]=='a' || inptr[4]=='A') &&
                  (inptr[5]=='s' || inptr[5]=='S') &&
                  (inptr[6]=='e' || inptr[6]=='E') &&
                  !isIdentChar(inptr[7])) {
               inptr += 7;
               NextToken();
               return 44;
             }
             // seglmt
             if ((inptr[3]=='l' || inptr[3]=='L') &&
                  (inptr[4]=='m' || inptr[4]=='M') &&
                  (inptr[5]=='t' || inptr[5]=='T') &&
                  !isIdentChar(inptr[6])) {
               inptr += 6;
               NextToken();
               return 45;
             }
             // segacr
             if ((inptr[3]=='a' || inptr[3]=='A') &&
                  (inptr[4]=='c' || inptr[4]=='C') &&
                  (inptr[5]=='r' || inptr[5]=='R') &&
                  !isIdentChar(inptr[6])) {
               inptr += 6;
               NextToken();
               return 47;
             }
         }
         break;

    // tag tick 
    case 't': case 'T':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             (inptr[3]=='k' || inptr[3]=='K') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x32;
         }
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='g' || inptr[2]=='G') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 41;
         }
         break;

    // vbr
    case 'v': case 'V':
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='r' || inptr[2]=='R') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 10;
         }
         break;
    case 'z': case 'Z':
        if ((inptr[1]=='s' || inptr[1]=='S') &&
            !isIdentChar(inptr[2])) {
            if (inptr[2]=='.') {
               if ((inptr[3]=='l' || inptr[3]=='L') &&
                   (inptr[4]=='m' || inptr[4]=='M') &&
                   (inptr[5]=='t' || inptr[5]=='T') &&
                   !isIdentChar(inptr[6])) {
                       inptr += 6;
                       NextToken();
                       return 0x28;
               }
            }
            inptr += 2;
            NextToken();
            return 0x20;
        }
        break;
    }
    return -1;
}

// Detect if a register can be part of a compressed instruction
static int CmpReg(int reg)
{
	switch(reg) {
	case 1:	return(0);
	case 3: return(1);
	case 4: return(2);
	case 11: return(3);
	case 12: return(4);
	case 18: return(5);
	case 19: return(6);
	case 20: return(7);
	default:
		return(-1);
	}
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

int getMergeOp()
{
	char *p;

	p = inptr;
	NextToken();
	switch (token) {
	tk_and:	return (1);
	tk_or:	return (2);
	tk_andcm:	return (3);
	tk_orcm: return (4);
	default:
		inptr = p;
		return (0);
	}
}

// ---------------------------------------------------------------------------
// Process the size specifier for a FP instruction.
// h: half (16 bit)
// s: single (32 bit)
// d: double (64 bit)
// t: triple (96 bit)
// q: quad (128 bit)
// ---------------------------------------------------------------------------

static int GetFPSize()
{
	int sz;

  sz = 'd';
  if (*inptr=='.') {
    inptr++;
    if (strchr("hsdtqHSDTQ",*inptr)) {
      sz = tolower(*inptr);
      inptr++;
    }
    else
      error("Illegal float size");
  }
	switch(sz) {
	case 'h':	sz = 0; break;
	case 's':	sz = 1; break;
	case 'd':	sz = 2; break;
	case 't':	sz = 3; break;
	case 'q':	sz = 4; break;
	default:	sz = 3; break;
	}
	return (sz);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static bool iexpand(int64_t oc)
{
	if ((oc >> 7) & 1) {
		switch ((((oc >> 12) & 0x0F) << 1) | ((oc >> 6) & 1)) {
		case 0:
			insnStats.adds++;
			break;
		case 1:
			insnStats.moves++;
			break;
		case 2:
			if ((oc & 0x01f) != 0)
				insnStats.adds++;
			break;
		case 4:
			if ((oc & 0x1f) == 0)
				insnStats.rets++;
			else
				insnStats.ands++;
			break;
		case 5:	insnStats.calls++; break;
		case 6: insnStats.shls++; break;
		case 7:
			if (((oc >> 8) & 0xF) == 0)
				insnStats.pushes++;
			break;
		case 8:
			switch ((oc >> 4) & 3) {
			case 0:
			case 1:
				insnStats.shifts++;
				break;
			case 2:
				insnStats.ors++;
				break;
			case 3:
				switch ((oc >> 10) & 3) {
				case 1:
					insnStats.ands++;
					break;
				case 2:
					insnStats.ors++;
					break;
				case 3:
					insnStats.xors++;
					break;
				}
			}
		case 9:
		case 11:
		case 13:
		case 15:
		case 25:
		case 27:
			insnStats.loads++;
			break;
		case 17:
		case 19:
		case 21:
		case 23:
		case 29:
		case 31:
			insnStats.stores++;
			break;
		case 14:
		case 16:
		case 18:
		case 20:
		case 22:
		case 24:
		case 26:
		case 28:
		case 30:
			insnStats.branches++;
			break;
		}
		return true;
	}
	return false;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int64_t oc)
{
	int ndx;
	int opmajor = oc & 0xff;
	int ls;
	int cond;

	if (1) {
		switch (opmajor) {
		case I_R2A:
			if ((oc >> 6) & 1) {
				/*
				switch ((oc >> 42LL) & 0x3fLL) {
				case I_CMOVNZ:
				case I_CMOVEZ:
					insnStats.cmoves++;
					break;
				}
				*/
			}
			switch ((oc >> 23LL) & 0x3fLL) {
			case I_R1:
				switch ((oc >> 23LL) & 0x3fLL) {
				case I_MOVE:
				case I_MOVO:
					insnStats.moves++;
					break;
				}
				break;
			case I_ADD2:
				insnStats.adds++;
				break;
			case I_AND2:
				insnStats.ands++;
				break;
			case I_OR2:
				insnStats.ors++;
				break;
			case I_XOR2:
				insnStats.xors++;
				break;
			case I_PTRDIF:
				insnStats.ptrdif++;
				break;
			}
			break;
		case I_SET:
			switch ((oc >> 23) & 0x3fLL) {
			case I_SLT:
			case I_SLTU:
			case I_SGE:
			case I_SGEU:
			case I_SEQ:
			case I_SNE:
				insnStats.sets++;
				break;
			}
			break;
		case I_SHIFT:
			switch ((oc >> 23) & 0x3fLL) {
			case I_ASL:
			case I_ASLI:
				insnStats.shls++;
				insnStats.shifts++;
				break;
			case I_SHR:
			case I_SHRI:
			case I_ASR:
			case I_ASRI:
			case I_ROL:
			case I_ROLI:
			case I_ROR:
			case I_RORI:
				insnStats.shifts++;
				break;
			}
			break;
		case I_ADDI:
			insnStats.adds++;
			break;
		case I_ANDI:
			insnStats.ands++;
			break;
		case I_ORI:
			insnStats.ors++;
			break;
		case I_XORI:
			insnStats.xors++;
			break;
		case I_LUI:
		case I_LMI:
			insnStats.luis++;
			break;
		case I_STB:
		case I_STW:
		case I_STT:
		case I_STO:
			if (oc & 0x4000000000LL)
				insnStats.indexed++;
			insnStats.stores++;
			break;
		case I_LDB:
		case I_LDBU:
		case I_LDW:
		case I_LDWU:
		case I_LDT:
		case I_LDTU:
		case I_LDO:
			if (oc & 0x4000000000LL)
				insnStats.indexed++;
			insnStats.loads++;
			break;
		case I_JSR:
		case I_JSRR:
			insnStats.calls++;
			break;
		case I_RTS:
			insnStats.rets++;
			break;
		case I_SLTI:
		case I_SLTUI:
		case I_SLEI:
		case I_SLEUI:
		case I_SGTI:
		case I_SGTUI:
		case I_SGEI:
		case I_SGEUI:
		case I_SEQI:
		case I_SNEI:
			insnStats.sets++;
			break;
		case I_FLT1:
		case I_FLT2:
			insnStats.floatops++;
			break;
		}
	}

	oc = oc & 0xFFFFFFFFFFLL;
	if (pass > 3) {
		emitCode(oc & 255LL);
		emitCode((oc >> 8LL) & 255LL);
		emitCode((oc >> 16LL) & 255LL);
		emitCode((oc >> 24LL) & 255LL);
		num_bytes += 4;
		num_insns += 1;
		insnStats.total++;
		return;
	}
}

static void LoadConstant(int64_t val, int rg)
{
	if (IsNBit(val, 13)) {
		emit_insn(
			RCF(recflag) |
			((val & 0x1fffLL) << 18LL) |
			RD(rg) |
			I_ADDI);	// ADDI (sign extends)
		return;
	}
	if (IsNBit(val, 38)) {
		emit_insn(
			((val >> 13LL) << 9LL) |
			I_LMI
		);
		emit_insn(
			RCF(recflag) | 
			((val & 0x1fffLL) << 18LL)|
			RS1(2) |
			RD(rg) |
			I_ORI
		);
		return;
	}
	// Won't fit into 38 bits, assume 64 bit constant
	emit_insn(
		((val >> 13LL) << 9LL) |
		I_LMI
	);
	emit_insn(
		((val >> 38LL) << 9LL) |
		I_LUI
	);
	emit_insn(
		RCF(recflag) |
		((val & 0x1fffLL) << 18LL) |
		RS1(2) |
		RD(rg) |
		I_ORI
	);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
static void getSz(int *sz)
{
	if (*inptr=='.')
		inptr++;
    *sz = inptr[0];
    switch(*sz) {
    case 'b': case 'B':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 8;
		}
		else
			*sz = 0;
		break;
	case 'w': case 'W':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 9;
		}
		else
			*sz = 1;
		break;
    case 't': case 'T':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 10;
		}
		else
			*sz = 2;
		break;
    case 'o': case 'O':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 11;
		}
		else
			*sz = 3;
		break;
	case 'd': case 'D': *sz = 0x83; break;
	case 'i': case 'I': *sz = 0x43; break;
  default: 
    error("Bad size");
		inptr--;
    *sz = 0;
  }
}

// ---------------------------------------------------------------------------
// Get memory aquire and release bits.
// ---------------------------------------------------------------------------

static void GetArBits(int64_t *aq, int64_t *rl)
{
	*aq = *rl = 0;
	while (*inptr == '.') {
		inptr++;
		if (inptr[0] != 'a' && inptr[0] != 'A' && inptr[0] != 'r' && inptr[0] != 'R')
			break;
		if ((inptr[0] == 'a' || inptr[0] == 'A') && (inptr[1] == 'q' || inptr[1] == 'Q')) {
			inptr += 2;
			*aq = 1;
		}
		if ((inptr[0] == 'r' || inptr[0] == 'R') && (inptr[1] == 'l' || inptr[1] == 'L')) {
			inptr += 2;
			*rl = 1;
		}
	}
}

// ---------------------------------------------------------------------------
// addi r1,r2,#1234
//
// A value that is too large has to be loaded into a register then the
// instruction converted to a registered form.
// So
//		addi	r1,r2,#$12345678
// Becomes:
// ---------------------------------------------------------------------------

static void process_riop(int64_t opcode6, int64_t func6, int64_t bit23)
{
  int Ra;
  int Rt, Rtp;
  char *p;
  int64_t val;
	int sz = 3;
	bool li = false;
    
  p = inptr;
	if (*p == '.')
		getSz(&sz);
	if (*inptr == '.') {
		inptr++;
		recflag = TRUE;
	}
	Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  val = expr();
	if (opcode6==-I_ADDI)	{ // subi
		val = -val;
		opcode6 = I_ADDI;	// change to addi
	}
	if (!IsNBit(val, 13LL)) {
		if (!IsNBit(val, 38LL)) {
			emit_insn(((val >> 13LL) << 9LL) | I_LMI);
			emit_insn(((val >> 38LL) << 9LL) | I_LUI);
			emit_insn(RCF(recflag)|(func6 << 26LL)|RS2(2)|RS1(Ra)|RD(Rt)|I_R2A);
			goto xit;
		}
		emit_insn(((val >> 13LL) << 9LL) | I_LMI);
		emit_insn(RCF(recflag)|(func6 << 26LL) | RS2(2) | RS1(Ra) | RD(Rt) | I_R2A);
		goto xit;
	}
	emit_insn(
		RCF(recflag)|
		IMM(val) |
		RT(Rt) |
		RA(Ra) |
		opcode6);
xit:
	ScanToEOL();
}

static void process_cmpi(int64_t opcode6, int64_t func6, int64_t bit23)
{
	int Ra;
	int Cr, Rtp;
	char *p;
	int64_t val;
	int sz = 3;
	bool li = false;
	int mop;

	p = inptr;
	if (*inptr == '.')
		mop = getMergeOp();
	if (*inptr == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = TRUE;
	Cr = getRegisterX();
	if (Cr < 112 || Cr > 115)
		error("Need condition register for compare");
	Cr &= 3;
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	if (!IsNBit(val, 13)) {
		if (!IsNBit(val, 38)) {
			LoadConstant(val, 2);
			emit_insn(RCF(recflag)|
				FUNC5(func6) | RS2(2) | RS1(Ra) | RD((mop << 3) | Cr) | I_R2A);
			return;
		}
		LoadConstant(val, 2);
		emit_insn(RCF(recflag) | FUNC5(func6) | RS2(2) | RS1(Ra) | RD((mop << 3) | Cr) | I_R2A);
		return;
	}
	emit_insn(
		RCF(recflag) |
		IMM(val) |
		RD((mop<<3)|Cr) |
		RS1(Ra) |
		opcode6);
xit:
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// slti cr1,r2,#1234
//
// A value that is too large has to be loaded into a register then the
// instruction converted to a registered form.
// ---------------------------------------------------------------------------

static void process_setiop(int64_t opcode6, int64_t func6, int64_t bit23)
{
	int Ra;
	int Rt;
	char *p;
	int64_t val;
	bool li = false;
	int mop;
	int sz = 0;

	p = inptr;
	if (inptr[0] == '.')
		mop = getMergeOp();
	if (inptr[0] == '.')
		getSz(&sz);
	Rt = getRegisterX();
	if (Rt >= 112 && Rt <= 115) {
		Rt &= 3;
	}
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	if (!IsNBit(val, 13)) {
		LoadConstant(val, 2);
		emit_insn((func6 << 28LL)|FMT(sz)|RS2(2)|RS1(Ra)|RD((mop<<3)|Rt)|I_SET);
		return;
	}
	emit_insn(
		IMM(val) |
		RD((mop << 3)|Rt) |
		RA(Ra) |
		opcode6
	);
	prevToken();
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// slt $t0,$t1,$r16
// ---------------------------------------------------------------------------

static void process_setop(int64_t funct6, int64_t opcode6, int64_t bit23)
{
	int Ra, Rb, Rt;
	char *p, *q;
	int sz = 3;
	int64_t val;
	int mop = 0;

	p = inptr;
	if (inptr[0] == '.')
		mop = getMergeOp();
	if (*inptr == '.')
		getSz(&sz);
	sz &= 7;
	Rt = getRegisterX();
	if (Rt >= 112 && Rt <= 115) {
		Rt &= 3;
	}
	else {
		Rt &= 3;
	}
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	q = inptr;
	Rb = getRegisterX();
	if (Rb == -1) {
		inptr = p;
		process_setiop(opcode6, funct6, bit23);
		return;
	}
	if (funct6 < 0)
		emit_insn(
			FUNC5(-funct6) |
			FMT(sz) |
			RS2(Ra) |
			RD((mop<<3)|Rt) |
			RS1(Rb) |
			I_SET
		);
	else
		emit_insn(
			FUNC5(funct6) |
			FMT(sz) |
			RS2(Rb) |
			RD((mop << 3)|Rt) |
			RS1(Ra) |
			I_SET
		);
	prevToken();
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// add r1,r2,r3
// ---------------------------------------------------------------------------

static void process_rrop()
{
  int Ra,Rb,Rt,Rbp,Rtp;
  char *p;
	int sz = 3;
	int64_t instr;
	int64_t funct6 = parm1[token];
	int64_t iop = parm2[token];
	int64_t bit23 = parm3[token];
	int opcode = I_R2A;

	instr = 0LL;
  p = inptr;
	if (*p=='.')
		getSz(&sz);
	if (*inptr == '.') {
		inptr++;
		recflag = TRUE;
	}
  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  if (token=='#') {
	if (iop < 0 && iop!=-I_ADDI)
		error("Immediate mode not supported");
		//printf("Insn:%d\n", token);
    inptr = p;
    process_riop(iop,funct6,bit23);
    return;
  }
  prevToken();
  Rb = getRegisterX();
	if (Rb >= 112 && Rb <= 115) {
		Rb &= 3;
		opcode = I_R2B;
	}
	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
	Ra = Ra & 0x1f;
	Rb = Rb & 0x1f;
	Rt = Rt & 0x1f;
	if (funct6==0x3C || funct6==0x3D || funct6==0x3E) {
	    emit_insn(RCF(recflag)|FUNC5(funct6)|FMT(sz)|RB(Rb)|RT(Rt)|RA(Ra)|opcode);
			goto xit;
	}
    emit_insn(RCF(recflag) | FUNC5(funct6)|FMT(sz)|RS2(Rb)|RD(Rt)|RS1(Ra)|opcode);
	xit:
		prevToken();
		ScanToEOL();
}
       
static void process_cmp()
{
	int Cr;
	int Ra, Rb, Rt, Rbp, Rtp;
	char *p;
	int sz = 3;
	int64_t instr;
	int64_t funct6 = parm1[token];
	int64_t iop = parm2[token];
	int64_t bit23 = parm3[token];
	int mop = 0;
	int opcode = I_R2A;

	instr = 0LL;
	p = inptr;
	// fxdiv, transform
	// - check for writeback indicator
	if (inptr[0] == '.')
		mop = getMergeOp();
	if (*inptr == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = TRUE;
	Cr = getRegisterX();
	if (Cr < 112 || Cr > 119)
		error("Need condition register for compare");
	Cr &= 7;
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	if (token == '#') {
		if (iop < 0 && iop != -0x84)
			error("Immediate mode not supported");
		//printf("Insn:%d\n", token);
		inptr = p;
		process_cmpi(iop, funct6, bit23);
		return;
	}
	prevToken();
	Rb = getRegisterX();
	if (Rb >= 112 && Rb <= 115) {
		Rb &= 3;
		opcode = I_R2B;
	}
	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
	Ra = Ra & 0x1f;
	Rb = Rb & 0x1f;
	Rt = Rt & 0x1f;
	emit_insn(RCF(recflag) | instr | FUNC6(funct6) | FMT(sz) | RS2(Rb) | RD((mop << 3) | Cr) | RS1(Ra) | opcode);
xit:
	prevToken();
	ScanToEOL();
}

static void process_ptrdif()
{
	int Ra, Rb, Rt, Rbp, Rtp;
	char *p;
	int sz = 3;
	int sc = 0;
	int64_t instr;
	int64_t funct6 = parm1[token];
	int64_t iop = parm2[token];
	int64_t bit23 = parm3[token];
	int opcode = I_R2A;

	instr = 0LL;
	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	if (token == '#') {
		if (iop < 0 && iop != -4)
			error("Immediate mode not supported");
		//printf("Insn:%d\n", token);
		inptr = p;
		process_riop(iop,funct6,bit23);
		return;
	}
	prevToken();
	Rb = getRegisterX();
	if (Rb >= 112 && Rb <= 115) {
		Rb &= 3;
		opcode = I_R2B;
	}
	need(',');
	NextToken();
	sc = expr();

	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
	emit_insn(instr | FUNC5(funct6) | (sc << 23) | RS2(Rb) | RD(Rt) | RS1(Ra) | opcode);
xit:
	prevToken();
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// or r1,r2,r3,r4
// ---------------------------------------------------------------------------

static void process_rrrop(int64_t funct6)
{
	int Ra, Rb, Rc = 0, Rt;
	char *p;
	int sz = 3;
	int opcode = I_R3A;

	if (funct6 > 7)
		opcode = I_R3B;
	p = inptr;
	if (*p == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = TRUE;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	if (token == '#') {
		inptr = p;
		process_riop(funct6,0,0);
		return;
	}
	prevToken();
	Rb = getRegisterX();
	if (token == ',') {
		NextToken();
		Rc = getRegisterX();
	}
	else {
		switch (funct6) {
		case I_AND3:	Rc = Rb; break;	// and
		case I_OR3:	Rc = 0; break;	// or
		case I_EOR3:	Rc = 0; break;	// xor
		}
	}
	emit_insn(RCF(recflag) | ((funct6 & 7LL) << 28LL) | RD(Rt) | RS3(Rc) | RS2(Rb) | RS1(Ra) | opcode);
}

static void process_cmove(int64_t funct6)
{
	int Ra, Rb, Rc = 0, Rt;
	char *p;
	int sz = 3;
	int64_t val;

	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	NextToken();
	if (token == '#') {
		val = expr();
		if (!IsNBit(val, 16)) {
			LoadConstant(val, 23);
			emit_insn(
				(funct6 << 42LL) |
				(0LL << 39LL) |
				RC(23) |
				RB(Rb) |
				RT(Rt) |
				RA(Ra) |
				(1 << 6) |
				0x02);
			return;
		}
		emit_insn(
			(funct6 << 42LL) |
			(4LL << 39LL) |
			((val & 0xffffLL) << 23LL) |
			RB(Rb) |
			RT(Rt) |
			RA(Ra) |
			(1 << 6) |
			0x02);
		return;
	}
	prevToken();
	Rc = getRegisterX();
	emit_insn(
		(funct6 << 42LL) |
		(0LL << 39LL) |
		RC(Rc) |
		RB(Rb) |
		RT(Rt) |
		RA(Ra) |
		(1 << 6) |
		0x02);
	prevToken();
	ScanToEOL();
}

static void process_cmovf(int64_t funct6)
{
	int Ra, Rb, Rc = 0, Rt;
	char *p;
	int sz = 3;

	p = inptr;
	Rt = getFPRegister();
	need(',');
	Ra = getRegisterX();
	need(',');
	Rb = getFPRegister();
	need(',');
	NextToken();
	Rc = getFPRegister();
	emit_insn((funct6 << 42LL) | RT(Rt) | RC(Rc) | RB(Rb) | RA(Ra) | (1 << 6) | 0x02);
}

// ---------------------------------------------------------------------------
// jmp main
// jal [r19]
// ---------------------------------------------------------------------------

static void process_jal(int64_t oc)
{
  int64_t addr, val;
  int Ra;
  int Rt;
	bool noRt;
	char *p;

	noRt = false;
	Ra = 0;
  Rt = 0;
	p = inptr;
  NextToken();
	if (token == '(' || token == '[') {
	j1:
		Ra = getRegisterX();
		if (Ra == -1) {
			printf("Expecting a register\r\n");
			goto xit;
		}
		// Simple jmp [Rn]
		if (token != ')' && token != ']')
			printf("Missing close bracket %d\n", lineno);
		emit_insn(RA(Ra) | RD(Rt) | I_JSRR);
		goto xit;
	}
	else
		inptr = p;
    Rt = getRegisterX();
    if (Rt >= 0) {
        need(',');
        NextToken();
        // jal Rt,[Ra]
        if (token=='(' || token=='[')
           goto j1;
    }
    else {
      Rt = 0;
			noRt = true;
		}
		addr = expr();
    // d(Rn)? 
    //NextToken();
    if (token=='(' || token=='[') {
        Ra = getRegisterX();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
		if (Ra==regSP)	// program counter relative ?
			addr -= code_address;
	}
	val = addr;
	if (IsNBit(val, 24)) {
		emit_insn(
			((val >> 2LL) << 10LL) |
			RT(Rt) |
			RA(Ra) |
			0x18);
		goto xit;
	}
	if (IsNBit(val, 30)) {
		emit_insn(
			(val << 18) |
			RT(Rt) |
			RA(Ra) |
			(1 << 6) |
			0x18);
		goto xit;
	}

	{
		LoadConstant(val, 23);
		if (Ra != 0) {
			// add r23,r23,Ra
			emit_insn(
				(0x04LL << 26LL) |
				(3 << 23) |
				RB(23) |
				RT(23) |
				RA(Ra) |
				0x02
			);
			// jal Rt,r23
			emit_insn(
				(0 << 18) |
				RT(Rt) |
				RA(23) | 0x18);
			goto xit;
		}
		emit_insn(
			RT(Rt) |
			RA(23) | 0x18);
		goto xit;
	}
xit:
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// subui r1,r2,#1234
// ---------------------------------------------------------------------------
/*
static void process_riop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int64_t val;
    
    p = inptr;
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    val = expr();

   if (lastsym != (SYM *)NULL)
       emitImm16(val,!lastsym->defined);
   else
       emitImm16(val,0);

    emitImm16(val,lastsym!=(SYM*)NULL);
    emitAlignedCode(oc);
    if (bGen)
    if (lastsym && !use_gp) {
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 3 | (lastsym->isExtern ? 128 : 0) |
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    }
    emitCode(Ra);
    emitCode(Rt);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
}
*/
// ---------------------------------------------------------------------------
// fabs.d r1,r2[,rm]
// ---------------------------------------------------------------------------

static void process_fprop(int64_t oc)
{
    int Ra;
    int Rt;
    char *p;
    int fmt;
    int64_t rm;

    rm = 0;
    fmt = GetFPSize();
    p = inptr;
    Rt = getFPRegister();
    need(',');
    Ra = getFPRegister();
    if (token==',')
       rm = getFPRoundMode();
//    prevToken();
	if (fmt != 2) {
		emit_insn(
			(oc << 42LL) |
			((int64_t)fmt << 31LL) |
			(rm << 28) |
			RT(Rt) |
			RB(0) |
			RA(Ra) |
			0x0F
		);
		return;
	}
  emit_insn(
		(oc << 26LL) |
		(rm << 23) |
		RT(Rt)|
		RB(0)|
		RA(Ra) |
		0x0F
	);
}

// ---------------------------------------------------------------------------
// itof.d $fp1,$r2[,rm]
// ---------------------------------------------------------------------------

static void process_itof(int64_t oc)
{
  int Ra;
  int Rt;
  char *p;
  int fmt;
  int64_t rm;

  rm = 0;
  fmt = GetFPSize();
  p = inptr;
  Rt = getFPRegister();
  need(',');
  Ra = getRegisterX();
  if (token==',')
    rm = getFPRoundMode();
//    prevToken();
	if (fmt != 2) {
		emit_insn(
			(oc << 42LL) |
			(fmt << 31LL) |
			(rm << 28LL) |
			RT(Rt) |
			RB(0) |
			RA(Ra) |
			I_FLT2
		);
		return;
	}
  emit_insn(
		(oc << 26LL) |
		(rm << 23LL)|
		RT(Rt)|
		RB(0)|
		RA(Ra) |
		I_FLT2
		);
}

static void process_ftoi(int64_t oc)
{
	int Ra;
	int Rt;
	char *p;
	int fmt;
	int64_t rm;

	rm = 0;
	fmt = GetFPSize();
	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getFPRegister();
	if (token == ',')
		rm = getFPRoundMode();
	//    prevToken();
	if (fmt != 2) {
		emit_insn(
			(oc << 42LL) |
			(fmt << 31LL) |
			(rm << 28LL) |
			RT(Rt) |
			RB(0) |
			RA(Ra) |
			I_FLT2
		);
		return;
	}
	emit_insn(
		(oc << 26LL) |
		(rm << 23LL) |
		RT(Rt) |
		RB(0) |
		RA(Ra) |
		I_FLT2
	);
}

// ---------------------------------------------------------------------------
// fadd.d r1,r2,r12[,rm]
// fcmp.d r1,r3,r10[,rm]
// ---------------------------------------------------------------------------

static void process_fprrop(int64_t oc)
{
    int Ra;
    int Rb;
    int Rt;
    char *p;
    int fmt;
    int64_t rm;

    rm = 0;
    fmt = GetFPSize();
    p = inptr;
    if (oc==0x01)        // fcmp
        Rt = getRegisterX();
    else
        Rt = getFPRegister();
    need(',');
    Ra = getFPRegister();
    need(',');
    Rb = getFPRegister();
    if (token==',')
       rm = getFPRoundMode();
//    prevToken();
	if (fmt != 2) {
		emit_insn(
			(oc << 42LL) |
			((int64_t)fmt << 31LL) |
			(rm << 28LL) |
			RT(Rt) |
			RB(Rb) |
			RA(Ra) |
			(1 << 6) |
			I_FLT2
		);
		return;
	}

  emit_insn(
		(oc << 26LL)|
		(rm << 23LL)|
		RT(Rt)|
		RB(Rb)|
		RA(Ra) |
		I_FLT2
	);
}

// ---------------------------------------------------------------------------
// fcx r0,#2
// fdx r1,#0
// ---------------------------------------------------------------------------

static void process_fpstat(int oc)
{
    int Ra;
    int64_t bits;
    char *p;

    p = inptr;
    bits = 0;
    Ra = getRegisterX();
    if (token==',') {
       NextToken();
       bits = expr();
    }
    prevToken();
	emit_insn(
		((bits & 0x3F) << 18) |
		(oc << 12) |	// ToDo Fix this
		RA(Ra) |
		I_FLT2
		);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

static void process_rop(int oc)
{
  int Ra;
  int Rt;
	int sz = 3;
	char *p;

	p = inptr;
	if (*p == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = TRUE;
	Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
	emit_insn(
		RCF(recflag)|
		(sz << 23) |
		FUNC5(I_R1) |
		RD(Rt) |
		RS1(Ra) |
		RS2(oc) |
		I_R2A
		);
	prevToken();
}

static void process_ptrop(int oc, int func)
{
	int Ra;
	int Rt;
	char *p;

	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	emit_insn(
		(1LL << 26LL) |
		(func << 23) |
		(oc << 18) |
		RT(Rt) |
		RA(Ra) |
		0x02
	);
	prevToken();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
static int InvertBranchOpcode(int opcode4)
{
	switch (opcode4) {
	case 0:	return (1);	// BEQ to BNE
	case 1:	return (0);	// BNE to BEQ
	default:	return (opcode4);	// Otherwise operands are swapped.
	}
}

// ---------------------------------------------------------------------------
// beq cr1,label
//
// ---------------------------------------------------------------------------

static void process_bcc()
{
	int Cr;
	int Ra, Rb, Rc;
	int64_t val;
	int64_t disp;
	int encode;
	int ins48 = 0;
	int64_t opcode6 = parm1[token];
	int64_t opcode4 = parm2[token];
	int64_t op4 = parm3[token];

	Cr = getRegisterX();
	if (Cr < 112 || Cr > 119)
		error("Need condition register for branch");
	need(',');
	NextToken();
	val = expr();
	emit_insn(
		((val >> 2LL) << 10LL) |
		((Cr & 7LL) << 8LL) |
		opcode6
	);
	return;
}

// ---------------------------------------------------------------------------
// bfextu r1,r2,#1,#63
// ---------------------------------------------------------------------------

static void process_bitfield(int64_t oc, int64_t fn)
{
	int Ra, Rb, Rc;
	int Rt;
	int64_t mb;
	int64_t me;
	int64_t val;
	int64_t op;
	int sz = 3;
	char *p;
	bool gmb, gme, gval;

	gmb = gme = gval = false;
	p = inptr;
	if (*p == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = TRUE;
	Rt = getRegisterX();
	need(',');
	p = inptr;
	Ra = getRegisterX();
	need(',');
	p = inptr;
	Rb = getRegisterX();
	if (Rb == -1) {
		inptr = p;
		NextToken();
		mb = expr();
		gmb = true;
	}
	need(',');
	p = inptr;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p;
		NextToken();
		me = expr();
		gme = true;
	}
	op =
		(fn << 30LL) |
		(gme ? (me << 24) : RS3(Rc)) |
		(gmb ? (mb << 18) : RS2(Rb)) |
		RS1(Ra) |
		RD(Rt) |
		(1 << 6) |
		oc;
	if (gme != gmb)
		error("Bitfield spec must be both register or both constant");
	emit_insn(op);
	ScanToEOL();
}


// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int oc, int cond)
{
  int Ra = 0, Rb = 0;
  int64_t val;
	int64_t disp;
	int ins48 = 0;

  NextToken();
  val = expr();
	emit_insn(((val >> 2) << 10LL) | I_JMP);
}

// ----------------------------------------------------------------------------
// chk r1,r2,r3,label
// ----------------------------------------------------------------------------

static void process_chk(int opcode6)
{
	int Ra;
	int Rb;
	int Rc;
	int64_t val, disp; 
     
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	Rc = getRegisterX();
	need(',');
	NextToken();
	val = expr();
    disp = val - code_address;
	// ToDo: Fix
	emit_insn(((disp >> 3) & 0x3FF) << 22 |
		RC(Rc) |
		RB(Rb) |
		RA(Ra) |
		((disp >> 2) & 1) |
		opcode6
	);
}


static void process_chki(int opcode6)
{
	int Ra;
	int Rb;
	int64_t val, disp; 
     
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	NextToken();
	val = expr();
    disp = val - code_address;
	// ToDO: Fix
	if (val < LB16 || val > 32767LL) {
		emit_insn((0x8000 << 16)|RB(Rb)|RA(Ra)|opcode6);
		emit_insn(val);
		return;
	}
	emit_insn(((val & 0xFFFF) << 16)|(Rb << 11)|(Ra << 6)|opcode6);
}


// ---------------------------------------------------------------------------
// fbeq.q fp1,fp0,label
// ---------------------------------------------------------------------------

static void process_fbcc(int64_t opcode3)
{
	int Ra, Rb, Rc;
	int64_t val;
	int64_t disp;
	int sz;
	bool ins48 = false;
	char *p;

	sz = GetFPSize();
	Ra = getFPRegister();
	need(',');
	Rb = getFPRegister();
	need(',');
	p = inptr;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p;
		NextToken();
		val = expr();
	}
	if (Rc == -1) {
		disp = (val - code_address) >> 1LL;
		if (!IsNBit(disp, 11)) {
			ins48 = true;
		}
		emit_insn(
			((disp >> 2) << 23LL) |
			((disp & 3LL) << 11LL) |
			(opcode3 << 8) |
			RB(Rb) |
			RA(Ra) |
			((ins48 ? 1 : 0) << 6) |
			0x05
		);
		return;
	}
	emit_insn(
		RC(Rc) |
		RB(Rb) |
		((opcode3 + 8) << 8) |
		RA(Ra) |
	0x11);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_call(int opcode, int opt)
{
	int64_t val;
	int Ra = 0;
	int lk = -1;

	lk = getRegisterX();
	if (lk < 0) {
		lk = opt ? 1 : 0;
	}
	else if (lk < 96 || lk > 97) {
		error("Link register must be specified.");
		lk = 1;
	}
	else
		lk = lk - 96;

  NextToken();
	if (token == tk_comma)
		NextToken();
	if (token == '[')
		val = 0;
	else
		val = expr();
	if (token=='[') {
		Ra = getRegisterX();
		need(']');
		if (Ra==31) {
			val -= code_address;
		}
	}
	if (val==0) {
			// JMP [Ra]
			// jrl r0,[Ra]
			emit_insn(
				RA(Ra) |
				RT(lk) |
				I_JSRR
			);
		return;
	}
	if (code_bits > 29 && !IsNBit(val,29)) {
		LoadConstant(val,23);
		if (Ra!=0) {
			// add r23,r23,Ra
			emit_insn(
				FUNC6(0x04) |
				FMT(S_HEXI) |
				RT(23) |
				RB(23) |
				RA(Ra) |
				0x8C
				);
		}
		// JMP or CALL
		// jal r0,[r23]
		emit_insn(
			RA(23) |
			RT(lk) |
			I_JSRR
			);
		return;
	}
	emit_insn(
		((val >> 2LL) << 10LL) |
		RD(lk) |
		opcode
		);
}

static void process_iret(int64_t op)
{
	int64_t val = 0;
	int Ra;
	char *p;

	p = inptr;
	Ra = getRegisterX();
	if (Ra == -1) {
		Ra = 0;
		NextToken();
		if (token == '#') {
			val = expr();
		}
		else
			inptr = p;
	}
	emit_insn(
		((val & 0x3FLL) << 18LL) |
		RT(0) |
		RA(Ra) |
		op
	);
}

static void process_ret()
{
	int64_t val = 0;
	bool ins48 = false;
	bool li = false;
	int lk = 1;

	lk = getRegisterX();
	if (lk < 0)
		lk = 1;
	else if (lk >= 96 && lk <= 97)
		lk -= 96;
	else
		lk = 0;
  NextToken();
	if (token=='#') {
		val = expr();
	}
	val &= 0xFFFFFFFFFFFFFFF0LL;
	if (!IsNBit(val, 16)) {
		LoadConstant(val, 2);
		emit_insn(RS2(2) | RS1(regSP) | RD(regSP) | I_ADDI);
		val = 0;
	}
	emit_insn(
		((val >> 3LL) << 18) |
		RD(lk) |
		RS1(regSP) |
		I_RTS
	);
}

// ---------------------------------------------------------------------------
// brk r1,2,0
// brk 240,2,0
// ---------------------------------------------------------------------------

static void process_brk()
{
	int64_t val;
	int inc = 1;
	int user = 0;
	int Ra = -1;

	Ra = getRegisterX();
	if (Ra == -1) {
		NextToken();
		val = expr();
		//NextToken();
		if (token == ',') {
			NextToken();
			inc = (int)expr();
			if (token == ',') {
				NextToken();
				user = (int)expr();
			}
			else
				prevToken();
		}
		else
			prevToken();
		emit_insn(
			(user << 26) |
			((inc & 31) << 21) |
			((val & 0xFFLL) << 8) |
			0x00
		);
		return;
	}
	NextToken();
	if (token == ',') {
		inc = (int)expr();
		NextToken();
		if (token == ',')
			user = (int)expr;
		else
			prevToken();
	}
	else
		prevToken();
	// ToDo: Fix this
	emit_insn(
		(user << 26) |
		((inc & 31) << 21) |
		(1 << 16) |
		RA(Ra & 0x1f) |
		0x00
	);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void GetIndexScale(int *sc)
{
	int64_t val;

	NextToken();
	val = expr();
	prevToken();
	switch(val) {
	case 0: *sc = 0; break;
	case 1: *sc = 0; break;
	case 2: *sc = 1; break;
	case 4: *sc = 2; break;
	case 8: *sc = 3; break;
	default: printf("Illegal scaling factor.\r\n");
	}
}


// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// [Reg]
// [Reg+Reg]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc, int *seg)
{
  int64_t val;

  // chech params
  if (disp == (int64_t *)NULL)
      return;
  if (regA == (int *)NULL)
      return;
	 if (regB == (int *)NULL)
		 return;
	 if (Sc == (int *)NULL)
		 return;
	 if (seg == (int *)NULL)
		 return;

     *disp = 0;
     *regA = -1;
	 *regB = -1;
	 *Sc = 0;
	 *seg = -1;
j1:
     if (token!='[') {
			 if (inptr[2] == ':') {
				 if (inptr[1] == 's' || inptr[1] == 'S') {
					 switch (inptr[0]) {
					 case 'C':
					 case 'c':
						 *seg = 0; inptr += 3; NextToken(); goto j1;
					 case 'D':
					 case 'd':
						 *seg = 1;
						 inptr += 3;
						 NextToken();
						 goto j1;
					 case 'E':
					 case 'e':
						 *seg = 2;
						 inptr += 3;
						 NextToken();
						 goto j1;
					 case 'S':
					 case 's':
						 *seg = 3;
						 inptr += 3;
						 NextToken();
						 goto j1;
					 case 'F':
					 case 'f':
						 *seg = 4;
						 inptr += 3;
						 NextToken();
						 goto j1;
					 case 'G':
					 case 'g':
						 *seg = 5;
						 inptr += 3;
						 NextToken();
						 goto j1;
					 }
				 }
			 }
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegisterX();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
		 if (token=='+') {
			 *regB = getRegisterX();
			 if (*regB == -1) {
				 printf("expecting a register\r\n");
			 }
              if (token=='*') {
                  GetIndexScale(Sc);
              }
		 }
         need(']');
     }
}

static void mem_voperand(int64_t *disp, int *regA, int *regB)
{
     int64_t val;

     // chech params
     if (disp == (int64_t *)NULL)
         return;
     if (regA == (int *)NULL)
         return;

     *disp = 0;
     *regA = -1;
	 *regB = -1;
     if (token!='[') {;
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegisterX();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
		 if (token=='+') {
			 *regB = getVecRegister();
			 if (*regB == -1) {
				 printf("expecting a vector register: %d\r\n", lineno);
			 }
		 }
         need(']');
     }
}

// ---------------------------------------------------------------------------
// If the displacement is too large the displacment is loaded into r2.
//
// So
//    sw    t2,$12345678[t2]
// Becomes:
//		lmi		r2,#$12345
//    add   x1,t2,r2
//    sw    $678[x1]
//
// sw disp[r1],r2
// sw [r1+r2],r3
// ----------------------------------------------------------------------------

static void process_store()
{
  int Ra,Rc;
  int Rs;
	int Sc;
	int seg;
  int64_t disp,val;
	int64_t aq = 0, rl = 0;
	int ar;
	int64_t opcode6 = parm1[token];
	int64_t funct6 = parm2[token];
	int64_t sz = parm3[token];
	bool li = false;

	GetFPSize();
	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	Rs = getRegisterX();
	if (Rs < 0) {
    printf("Expecting a source register (%d).\r\n", lineno);
    printf("Line:%.60s\r\n",inptr);
    ScanToEOL();
    return;
  }
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg);
	if (Ra >= 0 && Rc >= 0) {
		emit_insn(
//			((int64_t)seg << 45LL) |
			(Sc << 28LL) |
			RS3(Rc) |
			RS2(Rs) |
			RS1(Ra) |
			RD(opcode6)|
			I_STX);// seg == -1 ? 4 : 6);
		return;
	}
  if (Ra < 0) Ra = 0;
  val = disp;
	if (Ra == 55)
		val -= program_address;
	if (!IsNBit(val, 13)) {
		LoadConstant(val, 2);
		emit_insn(
			//			((int64_t)seg << 45LL) |
			RS3(2) |
			RS2(Rs) |
			RS1(Ra) |
			RD(opcode6) |
			I_STX);// seg == -1 ? 4 : 6);
		return;
	}
	emit_insn(
		STDISP(val) |
		RS2(Rs) |
		RS1(Ra) |
		opcode6);
    ScanToEOL();
}
/*
static void process_storepair(int64_t opcode6)
{
	int Ra, Rb;
	int Rs, Rs2;
	int Sc;
	int64_t disp, val;
	int64_t aq = 0, rl = 0;
	int ar;

	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	Rs = getRegisterX();
	if (Rs < 0) {
		printf("Expecting a source register (%d).\r\n", lineno);
		printf("Line:%.60s\r\n", inptr);
		ScanToEOL();
		return;
	}
	expect(',');
	Rs2 = getRegisterX();
	expect(',');
	mem_operand(&disp, &Ra, &Rb, &Sc);
	if (Ra > 0 && Rb > 0) {
		emit_insn(
			(opcode6 << 34LL) |
			(ar << 26) |
			(Sc << 24) |
			(Rs << 18) |
			(Rb << 12) |
			(Ra << 6) |
			0x02, !expand_flag, 5);
		return;
	}
	if (Ra < 0) Ra = 0;
	val = disp;
	if (Ra == 55)
		val -= program_address;
	if (!IsNBit(val, 14)) {
		LoadConstant(val, 52);
		// Change to indexed addressing
		emit_insn(
			(opcode6 << 34LL) |
			(ar << 26) |
			(0 << 24) |		// Sc
			(Rs << 18) |
			(52 << 12) |
			(Ra << 6) |
			0x02, !expand_flag, 5);
		ScanToEOL();
		return;
	}
	emit_insn(
		(val << 26LL) |
		(ar << 24) |
		(Rs2 << 18) |
		(Rs << 12) |
		(Ra << 6) |
		opcode6, !expand_flag, 5, true);
	ScanToEOL();
}
*/
static void process_sv(int64_t opcode6)
{
    int Ra,Vb;
    int Vs;
    int64_t disp,val;
	int64_t aq = 0, rl = 0;
	int ar = 0;

	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	Vs = getVecRegister();
    if (Vs < 0 || Vs > 63) {
        printf("Expecting a vector source register (%d).\r\n", lineno);
        printf("Line:%.60s\r\n",inptr);
        ScanToEOL();
        return;
    }
    expect(',');
    mem_voperand(&disp, &Ra, &Vb);
	if (Ra > 0 && Vb > 0) {
		emit_insn(
			(opcode6 << 34LL) |
			(ar << 26) |
			(Vs << 18) |
			(Vb << 12) |
			(Ra << 6) |
			0x02);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	//if (val < -32768 || val > 32767)
	//	printf("SV displacement too large: %d\r\n", lineno);
	if (!IsNBit(val, 20)) {
		LoadConstant(val, 52);
		// ToDo: store with indexed addressing
		return;
	}
	emit_insn(
		(val << 20) |
		(ar << 18) |
		(Vs << 12) |
		(Ra << 6) |
		opcode6);
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi()
{
  int Ra = 0;
  int Rt;
  int64_t val;
	char *p;
	int sz = 3;
	bool li = false;

  p = inptr;
	if (*p=='.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = true;
	sz &= 3;
  Rt = getRegisterX();
  expect(',');
  val = expr();
	LoadConstant(val, Rt);
	return;
}

// ----------------------------------------------------------------------------
// link #-40
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// ----------------------------------------------------------------------------

static void process_load()
{
  int Ra,Rc;
  int Rt;
	int Sc;
	int seg;
  char *p;
  int64_t disp;
  int64_t val;
	int64_t aq = 0, rl = 0;
	int ar;
  int fixup = 5;
	int64_t opcode6 = parm1[token];
	int64_t funct6 = parm2[token];
	int64_t sz = parm3[token];
	bool li = false;

	GetFPSize();
	GetArBits(&aq, &rl);
	if (*inptr == '.') {
		inptr++;
		recflag = true;
	}
	ar = (int)((aq << 1LL) | rl);
	p = inptr;
	Rt = getRegisterX();
  if (Rt < 0) {
      printf("Expecting a target register (%d).\r\n", lineno);
      printf("Line:%.60s\r\n",p);
      ScanToEOL();
      inptr-=2;
      return;
  }
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg);
	if (Ra >= 0 && Rc >= 0) {
		//if (gpu)
		//	error("Indexed addressing not supported on GPU");
		// Trap LEA, convert to LEAX opcode
		emit_insn(
			RS3(Rc) |
			(Sc << 28) |
			RD(Rt) |
			RS1(Ra) |
			RS2(opcode6) |
			I_LDX);// seg != -1 ? 6 : 4);
		return;
	}
  if (Ra < 0) Ra = 0;
    val = disp;
	if (Ra == 55)
		val -= program_address;
	if (!IsNBit(val, 13)) {
		LoadConstant(val, 2);
		emit_insn(
			RCF(recflag) |
			RS3(2) |
			RD(Rt) |
			RS1(Ra) |
			RS2(opcode6) |
			I_LDX);// seg != -1 ? 6 : 4);
		return;
	}
	emit_insn(
		RCF(recflag) |
		IMM(val) |
		RD(Rt) |
		RS1(Ra) |
		opcode6);
    ScanToEOL();
}

static void process_cache(int opcode6)
{
  int Ra,Rc;
	int Sc;
	int seg;
  char *p;
  int64_t disp;
  int64_t val;
  int fixup = 5;
	int cmd;

  p = inptr;
	NextToken();
	cmd = (int)expr() & 0x1f;
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg);
	if (Ra > 0 && Rc > 0) {
		emit_insn(
			RS3(Rc) |
			RS2(opcode6) |
			(Sc << 28) |
			(cmd << 8) |
			RS1(Ra) |
			I_OSR2);// seg == -1 ? 4 : 6);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	if (!IsNBit(val,13)) {
		LoadConstant(val,2);
		// Change to indexed addressing
		emit_insn(
			RS3(23) |
			RS2(opcode6 & 31LL) |
			(Sc << 28) |
			RD(cmd) |
			RS1(Ra) |
			I_OSR2);// seg == -1 ? 4 : 6);
		ScanToEOL();
		return;
	}
	if (!IsNBit(val, 13)) {
		LoadConstant(val, 2);
		emit_insn(
			RS3(2) |
			RD(cmd) |
			RS1(Ra) |
			RS2(opcode6) |
			I_OSR2);
		return;
	}
	emit_insn(
		IMM(val) |
		RD(cmd) |
		RS1(Ra) |
		opcode6);
    ScanToEOL();
}


static void process_lv(int opcode6)
{
    int Ra,Vb;
    int Vt;
    char *p;
    int64_t disp;
    int64_t val;
    int fixup = 5;

    p = inptr;
	Vt = getVecRegister();
    if (Vt < 0) {
        printf("Expecting a vector target register (%d).\r\n", lineno);
        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_voperand(&disp, &Ra, &Vb);
	if (Ra > 0 && Vb > 0) {
		if (opcode6 == 0x36)	// LV
			opcode6 = 0x19;		// LVX
		emit_insn(
			(opcode6 << 26) |
			(Vt << 16) |
			(Vb << 11) |
			(Ra << 6) |
			0x02);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	//if (val < -32768 || val > 32767)
	//	printf("LV displacement too large: %d\r\n", lineno);
	if (val >= -32768 && val < 32768) {
		emit_insn(
			(val << 16) |
			(Vt << 11) |
			(Ra << 6) |
			opcode6);
		ScanToEOL();
		return;
	}
	LoadConstant(val,23);
	// add r23,r23,ra
	if (Ra != 0)
		emit_insn(
			(0x04 << 26) |
			(3 << 21) |
			(23 << 16) |
			(23 << 11) |
			(Ra << 6) |
			0x02
		);
	emit_insn(
		(Vt << 11) |
		(23 << 6) |
		opcode6);
	ScanToEOL();
}

static void process_lsfloat(int64_t opcode6, int64_t opcode3)
{
  int Ra,Rb;
  int Rt;
	int Sc;
	int seg;
	char *p;
	int64_t disp;
	int64_t val;
	int fixup = 5;

  int  sz;
  int rm;
	//printf("Fix segment prefix\r\n");
  rm = 0;
  sz = GetFPSize();
  p = inptr;
  Rt = getFPRegister();
  if (Rt < 0) {
      printf("Expecting a float target register (1:%d).\r\n", lineno);
      printf("Line:%.60s\r\n",p);
      ScanToEOL();
      inptr-=2;
      return;
  }
  expect(',');
  mem_operand(&disp, &Ra, &Rb, &Sc, &seg);
	if (Ra > 0 && Rb > 0) {
		emit_insn(
			((opcode6+sz) << 26) |
			(Sc << 23) |
			(Rt << 18) |
			RB(Rb) |
			RA(Ra) |
			0x16);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	if (!IsNBit(val, 29)) {
		LoadConstant(val, 23);
		// Change to indexed addressing
		emit_insn(
			((opcode6+sz) << 26LL) |
			(0 << 23) |		// Sc = 0
			(Rt << 18) |
			(23 << 13) |
			RA(Ra) |
			0x02);
		ScanToEOL();
		return;
	}
	switch (sz) {
	case 0:	val &= 0xfffffffffffffffeLL; val |= 1; break;
	case 1: val &= 0xfffffffffffffffcLL; val |= 2; break;
	case 2: val &= 0xfffffffffffffff8LL; val |= 4; break;
	case 4: val &= 0xfffffffffffffff0LL; val |= 8; break;
	}
	if (!IsNBit(val, 13)) {
		emit_insn(
			(val << 18LL) |
			RT(Rt) |
			RA(Ra) |
			(1 << 6) |
			opcode6);
		ScanToEOL();
		return;
	}
	emit_insn(
		(val << 18LL) |
		RT(Rt) |
		RA(Ra) |
		opcode6);
	ScanToEOL();

}

static void process_stfloat(int64_t opcode6, int64_t opcode3)
{
	int Ra, Rb;
	int Rt;
	int Sc;
	int seg;
	char *p;
	int64_t disp;
	int64_t val;
	int fixup = 5;

	int  sz;
	int rm;
	//printf("Fix segment prefix\r\n");
	rm = 0;
	sz = GetFPSize();
	p = inptr;
	Rt = getFPRegister();
	if (Rt < 0) {
		printf("Expecting a float target register (1:%d).\r\n", lineno);
		printf("Line:%.60s\r\n", p);
		ScanToEOL();
		inptr -= 2;
		return;
	}
	expect(',');
	mem_operand(&disp, &Ra, &Rb, &Sc, &seg);
	if (Ra > 0 && Rb > 0) {
		emit_insn(
			((opcode6 + sz) << 26) |
			(Sc << 23) |
			(Rt << 18) |
			RB(Rb) |
			RA(Ra) |
			0x16);
		return;
	}
	if (Ra < 0) Ra = 0;
	val = disp;
	if (!IsNBit(val, 29)) {
		LoadConstant(val, 23);
		// Change to indexed addressing
		emit_insn(
			((opcode6 + sz) << 26LL) |
			(0 << 23) |		// Sc = 0
			(Rt << 18) |
			(23 << 13) |
			RA(Ra) |
			0x02);
		ScanToEOL();
		return;
	}
	switch (sz) {
	case 0:	val &= 0xfffffffffffffffeLL; val |= 1; break;
	case 1: val &= 0xfffffffffffffffcLL; val |= 2; break;
	case 2: val &= 0xfffffffffffffff8LL; val |= 4; break;
	case 4: val &= 0xfffffffffffffff0LL; val |= 8; break;
	}
	if (!IsNBit(val, 13)) {
		emit_insn(
			(val << 18LL) |
			RT(Rt) |
			RA(Ra) |
			(1 << 6) |
			opcode6);
		ScanToEOL();
		return;
	}
	emit_insn(
		(val << 18LL) |
		RT(Rt) |
		RA(Ra) |
		opcode6);
	ScanToEOL();

}

static void process_ld()
{
	int Rt;
	char *p;

	p = inptr;
	Rt = getRegisterX();
	expect(',');
//	NextToken();
	if (token == '#') {
		inptr = p;
		process_ldi();
		return;
	}
	// Else: do a word load
	inptr = p;
	(*jumptbl[tk_lw])();
	//process_load(0x20,0x12,4);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ltcb(int oc)
{
	int Rn;

	Rn = getRegisterX();
	emit_insn(
		(oc << 11) |
		(Rn << 6) |
		0x19
		);
	prevToken();
}

// ----------------------------------------------------------------------------
// mov r1,r2 -> translated to or Rt,Ra,#0
// ----------------------------------------------------------------------------

static void process_mov(int64_t oc, int64_t fn)
{
  int Ra;
  int Rt;
  char *p;
	int vec = 0;
	int fp = 0;
	int d3;
	int rgs = 8;
	int sz = 3;

	p = inptr;
	if (*p == '.')
		getSz(&sz);

	d3 = 7;	// current to current
	p = inptr;
  Rt = getRegisterX();
	if (Rt==-1) {
		inptr = p;
		Rt = getFPRegister();
		if (Rt == -1) {
			d3 = 4;
			inptr = p;
			vec = 1;
			Rt = getVecRegister();
		}
		else {
			d3 = 4;
			fp = 1;
		}
	}
	Rt &= 31;
	if (inptr[-1]==':') {
		if (*inptr=='x' || *inptr=='X') {
			d3 = 2;
			inptr++;
			NextToken();
		}
		else {
			rgs = (int)expr();
			d3 = 0;
		}
	}
  need(',');
	p = inptr;
  Ra = getRegisterX();
	if (Ra==-1) {
		inptr = p;
		Ra = getFPRegister();
		if (Ra == -1) {
			inptr = p;
			Ra = getVecRegister();
			vec |= 2;
		}
		else {
			if (fp == 1)
				d3 = 6;
			else
				d3 = 5;
			fp |= 2;
		}
	}
	Ra &= 31;
	if (inptr[-1]==':') {
		if (*inptr=='x' || *inptr=='X') {
			inptr++;
			d3 = 3;
			NextToken();
		}
		else {
			rgs = (int)expr();
			d3 = 1;
		}
	}
	 if (vec==1) {
		 emit_insn(
			 (0x33LL << 34LL) |
			 (0x00LL << 28LL) |
			 RT(Rt) |
			 RA(Ra) |
			 0x01
		 );
		 return;
	 }
	 else if (vec==2) {
		 emit_insn(
			 (0x33LL << 34LL) |
			 (0x01LL << 28LL) |
			 RT(Rt) |
			 RA(Ra) |
			 0x01
		 );
		 return;
	 }
	 else if (vec == 3) {
		 printf("Unsupported mov operation. %d\n", lineno);
		 return;
	 }
	 if (rgs < 0 || rgs > 63) {
		 printf("Illegal register set spec: %d\n", lineno);
		 return;
	 }
	 rgs &= 0x31;
	 if (d3 == 7) {
		 emit_insn(
			 (0 << 12) |
			 (3 << 6) |
			 ((Rt >> 1) << 8) |
			 ((Rt & 1) << 5) |
			 (Ra));
		 prevToken();
		 return;
	 }
	 emit_insn(
		 (fn << 26LL) |	// fn should be even
		 (((rgs >> 5) & 1) << 26) |
		 (d3 << 23LL) |
		 RB(rgs) |
		 RT(Rt) |
		 RA(Ra) |
		 oc
		 );
	prevToken();
}

static int64_t process_op2()
{
	int64_t op2 = 0;

	inptr++;
	NextToken();
	switch (token) {
	case tk_add:	op2 = 0x04LL;	break;
	case tk_sub:	op2 = 0x05LL;	break;
	case tk_and:	op2 = 0x08LL; break;
	case tk_or:		op2 = 0x09LL; break;
	case tk_xor:	op2 = 0x0ALL; break;
	case tk_nop:	op2 = 0x3DLL; break;
	default:	op2 = 0x3DLL; break;
	}
	return (op2);
}

// ----------------------------------------------------------------------------
// shr r1,r2,#5
// shr:sub r1,r2,#5,r3
// ----------------------------------------------------------------------------

static void process_shifti(int64_t op4)
{
	int Ra, Rc = 0;
	int Rt;
	int sz = 3;
	int64_t func6 = 0x0F;
	int64_t val;
	int64_t op2 = 0;
	char *p, *q;

	q = p = inptr;
	SkipSpaces();
	if (p[0] == ':') {
		inptr++;
		op2 = process_op2();
		q = inptr;
	}
	if (q[0]=='.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = true;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	val &= 63;
	emit_insn(
		RCF(recflag) |
		(op4 << 24) |
		((val & 0x3f) << 18) |
		RD(Rt) |
		RS1(Ra) |
		I_SHIFT);
}

// ----------------------------------------------------------------------------
// SEI R1
// SEI #5
// ----------------------------------------------------------------------------

static void process_sei()
{
	int64_t val = 7;
	int Ra = -1;
    char *p;

	p = inptr;
	NextToken();
	if (token=='#')
		val = expr();
	else {
		inptr = p;
	    Ra = getRegisterX();
	}
	if (Ra==-1) {
		emit_insn(
			0xC0000002LL |
			RB(val & 7) |
			RA(0)
			);
	}
	else {
		emit_insn(
			0xC0000002LL |
			RB(0) |
			RA(Ra)
			);
	}
}

// ----------------------------------------------------------------------------
// REX r0,6,6,1
// ----------------------------------------------------------------------------

static void process_rex()
{
	int64_t val = 7;
	int Ra = -1;
	int tgtol;
	int pl;
	int im;
    char *p;

	p = inptr;
    Ra = getRegisterX();
	need(',');
	NextToken();
	tgtol = (int)expr() & 7;
	if (tgtol==0)
		printf("REX: Illegal redirect to user level %d.\n", lineno);
	need(',');
	NextToken();
	pl = (int)expr() & 7;
	need(',');
	NextToken();
	im = (int)expr() & 7;
	//ToDO: Fix
	emit_insn(
		(im << 24) |
		(pl << 16) |
		(tgtol << 11) |
		RA(Ra) |
		0x0D
	);
}

// ----------------------------------------------------------------------------
// shl r1,r2,r3
// shl:add r1,r2,r3,r4
// ----------------------------------------------------------------------------

static void process_shift(int64_t op4)
{
	int64_t Ra, Rb, Rc = 0;
	int Rt;
	char *p, *q;
	int sz = S_HEXI;
	int func6 = 0x2f;
	int64_t op2 = 0x00LL;	// NOP
	int b23 = 0;

	q = p = inptr;
	SkipSpaces();
	if (p[0] == ':') {
		inptr++;
		op2 = process_op2();
		q = inptr;
	}
	if (q[0]=='.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = true;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	if (token=='#') {
		inptr = p;
		process_shifti(op4);
	}
	else {
		prevToken();
		Rb = getRegisterX();
		if (Rb >= 112 && Rb <= 115) {
			b23 = 1;
		}
		emit_insn((op4 << 24) | (b23 << 23) | RD(Rt)| RS2(Rb) | RS1(Ra) | I_SHIFT);
	 }
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static int getTlbReg()
{
	int Tn;

	Tn = -1;
	SkipSpaces();
	if ((inptr[0] == 'a' || inptr[0] == 'A') &&
		(inptr[1] == 's' || inptr[1] == 'S') &&
		(inptr[2] == 'i' || inptr[2] == 'I') &&
		(inptr[3] == 'd' || inptr[3] == 'D') &&
		!isIdentChar(inptr[4])) {
		inptr += 4;
		NextToken();
		return (7);
	}
	if ((inptr[0] == 'm' || inptr[0] == 'M') &&
		(inptr[1] == 'a' || inptr[1] == 'A') &&
		!isIdentChar(inptr[2])) {
		inptr += 2;
		NextToken();
		return (8);
	}
	if ((inptr[0] == 'i' || inptr[0] == 'I') &&
		(inptr[1] == 'n' || inptr[1] == 'N') &&
		(inptr[2] == 'd' || inptr[2] == 'D') &&
		(inptr[3] == 'e' || inptr[3] == 'E') &&
		(inptr[4] == 'x' || inptr[4] == 'X') &&
		!isIdentChar(inptr[5])) {
		inptr += 5;
		NextToken();
		return (1);
	}
	if ((inptr[0] == 'p' || inptr[0] == 'P') &&
		(inptr[1] == 'a' || inptr[1] == 'A') &&
		(inptr[2] == 'g' || inptr[2] == 'G') &&
		(inptr[3] == 'e' || inptr[3] == 'E') &&
		(inptr[4] == 's' || inptr[4] == 'S') &&
		(inptr[5] == 'i' || inptr[5] == 'I') &&
		(inptr[6] == 'z' || inptr[6] == 'Z') &&
		(inptr[7] == 'e' || inptr[7] == 'E') &&
		!isIdentChar(inptr[8])) {
		inptr += 8;
		NextToken();
		return (3);
	}
	if ((inptr[0] == 'p' || inptr[0] == 'P') &&
		(inptr[1] == 'h' || inptr[1] == 'H') &&
		(inptr[2] == 'y' || inptr[2] == 'Y') &&
		(inptr[3] == 's' || inptr[3] == 'S') &&
		(inptr[4] == 'p' || inptr[4] == 'P') &&
		(inptr[5] == 'a' || inptr[5] == 'A') &&
		(inptr[6] == 'g' || inptr[6] == 'G') &&
		(inptr[7] == 'e' || inptr[7] == 'E') &&
		!isIdentChar(inptr[8])) {
		inptr += 8;
		NextToken();
		return (5);
	}
	if ((inptr[0] == 'p' || inptr[0] == 'P') &&
		(inptr[1] == 't' || inptr[1] == 'T') &&
		(inptr[2] == 'a' || inptr[2] == 'A') &&
		!isIdentChar(inptr[3])) {
		inptr += 3;
		NextToken();
		return (10);
	}
	if ((inptr[0] == 'p' || inptr[0] == 'P') &&
		(inptr[1] == 't' || inptr[1] == 'T') &&
		(inptr[2] == 'c' || inptr[2] == 'C') &&
		!isIdentChar(inptr[3])) {
		inptr += 3;
		NextToken();
		return (11);
	}
	if ((inptr[0] == 'r' || inptr[0] == 'R') &&
		(inptr[1] == 'a' || inptr[1] == 'A') &&
		(inptr[2] == 'n' || inptr[2] == 'N') &&
		(inptr[3] == 'd' || inptr[3] == 'D') &&
		(inptr[4] == 'o' || inptr[4] == 'O') &&
		(inptr[5] == 'm' || inptr[5] == 'M') &&
		!isIdentChar(inptr[6])) {
		inptr += 6;
		NextToken();
		return (2);
	}
	if ((inptr[0] == 'v' || inptr[0] == 'V') &&
		(inptr[1] == 'i' || inptr[1] == 'I') &&
		(inptr[2] == 'r' || inptr[2] == 'R') &&
		(inptr[3] == 't' || inptr[3] == 'T') &&
		(inptr[4] == 'p' || inptr[4] == 'P') &&
		(inptr[5] == 'a' || inptr[5] == 'A') &&
		(inptr[6] == 'g' || inptr[6] == 'G') &&
		(inptr[7] == 'e' || inptr[7] == 'E') &&
		!isIdentChar(inptr[8])) {
		inptr += 8;
		NextToken();
		return (4);
	}
	if ((inptr[0] == 'w' || inptr[0] == 'W') &&
		(inptr[1] == 'i' || inptr[1] == 'I') &&
		(inptr[2] == 'r' || inptr[2] == 'R') &&
		(inptr[3] == 'e' || inptr[3] == 'E') &&
		(inptr[4] == 'd' || inptr[4] == 'D') &&
		!isIdentChar(inptr[5])) {
		inptr += 5;
		NextToken();
		return (0);
	}
	return (Tn);
}

// ----------------------------------------------------------------------------
// gran r1
// ----------------------------------------------------------------------------

static void process_gran(int oc)
{
    int Rt;

    Rt = getRegisterX();
//    emitAlignedCode(0x01);
    emitCode(0x00);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
    prevToken();
}

     
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_mffp(int oc)
{
    int fpr;
    int Rt;
    
    Rt = getRegisterX();
    need(',');
    fpr = getFPRegister();
    //emitAlignedCode(0x01);
    emitCode(fpr);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
    if (fpr >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_fprdstat(int oc)
{
    int Rt;
    
    Rt = getRegisterX();
    //emitAlignedCode(0x01);
    emitCode(0x00);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
}


// ----------------------------------------------------------------------------
// Four cases, two with extendable immediate constants
//
// csrrw	r2,#21,r3
// csrrw	r4,#34,#1234
// csrrw	r5,r4,#1234
// csrrw	r6,r4,r5
// ----------------------------------------------------------------------------

static void process_csrrw(int64_t op)
{
	int Rd;
	int Rs;
	int Rc;
	int64_t val,val2;
	char *p;
	int sz = 3;

	p = inptr;
	if (p[0] == '.')
		getSz(&sz);
	Rd = getRegisterX();
	need(',');
	p = inptr;
	NextToken();
	if (token=='#') {
		val = expr();
		need(',');
		NextToken();
		if (token=='#') {
			printf("Illegal CSR instruction.\r\n");
			return;
			val2 = expr();
			if (val2 < -15LL || val2 > 15LL) {
				LoadConstant(val2, 2);
				emit_insn(((val & 0x7ff) << 18) | (op << 29) | RS1(2) | RD(Rd) | I_CSR);
				return;
			}
			emit_insn(((val & 0x7ff) << 18) | (op << 29) | RS1(val2) | RD(Rd) | I_CSR);
			return;
		}
		prevToken();
		Rs = getRegisterX();
		emit_insn(((val & 0x7FFLL) << 18LL) | (op << 29LL) | RS1(Rs) | RD(Rd) | I_CSR);
		prevToken();
		return;
		}
	printf("Illegal CSR instruction.\r\n");
	return;
}

// ---------------------------------------------------------------------------
// com r3,r3
// - alternate mnemonic for xor Rn,Rn,#-1
// ---------------------------------------------------------------------------

static void process_com(int oc)
{
	int Ra;
	int Rt;
	char *p;
	int sz = 3;

	p = inptr;
	if (p[0] == '.')
		getSz(&sz);
	if (*inptr == '.')
		recflag = true;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	//TODo: Fix
	emit_insn(
		FUNC5(I_R1) |
		(sz << 18) |
		RD(Rt) |
		RS1(Ra) |
		RS2(oc) |
		I_R2A
		);
	prevToken();
}

static void process_sync(int oc)
{
//    emit_insn(oc,!expand_flag);
}

static void process_tlb(int cmd)
{
	int Ra,Rt;
	int Tn;

	Ra = 0;
	Rt = 0;
	Tn = 0;
	switch (cmd) {
	case 1:     Rt = getRegisterX(); prevToken(); break;  // TLBPB
	case 2:     Rt = getRegisterX(); prevToken(); break;  // TLBRD
	case 3:     break;       // TLBWR
	case 4:     break;       // TLBWI
	case 5:     break;       // TLBEN
	case 6:     break;       // TLBDIS
	case 7: {            // TLBRDREG
		Rt = getRegisterX();
		need(',');
		Tn = getTlbReg();
	}
					break;
	case 8: {            // TLBWRREG
		Tn = getTlbReg();
		need(',');
		Ra = getRegisterX();
		prevToken();
	}
					break;
	case 9:     break;

	}
	emit_insn(
		(0x3f << 26) |	// TLB
		(cmd << 22) | 
		RB(Tn) |
		RT(Rt) |
		RA(Ra) |
		0x02
	);
}


// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_vrrop(int funct6)
{
    int Va,Vb,Vt,Vm;
    char *p;
	int sz = 0x43;

    p = inptr;
	if (*p=='.')
		getSz(&sz);
	if (sz==0x43)
		sz = 0;
	else if (sz==0x83)
		sz = 1;
    Vt = getVecRegister();
    need(',');
    Va = getVecRegister();
    need(',');
    Vb = getVecRegister();
    need(',');
    Vm = getVecRegister();
	if (Vm < 0x20 || Vm > 0x23)
		printf("Illegal vector mask register: %d\r\n", lineno);
	Vm &= 0x7;
    //prevToken();
    emit_insn((funct6<<26)|(Vm<<23)|(sz << 21)|(Vt<<16)|(Vb<<11)|(Va<<6)|0x01);
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_vsrrop(int funct6)
{
    int Va,Rb,Vt,Vm;
    char *p;
	int sz = 0x43;

    p = inptr;
	if (*p=='.')
		getSz(&sz);
	if (sz==0x43)
		sz = 0;
	else if (sz==0x83)
		sz = 1;
    Vt = getVecRegister();
    need(',');
    Va = getVecRegister();
    need(',');
    Rb = getRegisterX();
    need(',');
    Vm = getVecRegister();
	if (Vm < 0x20 || Vm > 0x23)
		printf("Illegal vector mask register: %d\r\n", lineno);
	Vm &= 0x3;
    //prevToken();
    emit_insn((funct6<<26)|(Vm<<23)|(sz << 21)|(Vt<<16)|(Rb<<11)|(Va<<6)|0x01);
}
       
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void ProcessEOL(int opt)
{
    int64_t nn,mm,cai,caia;
    int first;
    int cc,jj;
		static char *wtcrsr = "|/-\\|/-\\";
		static int wtndx = 0;

		if ((lineno % 100) == 0) {
			printf("%c\r", wtcrsr[wtndx]);
			wtndx++;
			wtndx &= 7;
		}

     //printf("Line: %d: %.80s\r", lineno, inptr);
     expand_flag = 0;
     compress_flag = 0;
     segprefix = -1;
     if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
    nn = binstart;
    cc = 2;
    if (segment==codeseg) {
       cc = 4;
/*
        if (sections[segment].bytes[binstart]==0x61) {
            fprintf(ofp, "%06LLX ", ca);
            for (nn = binstart; nn < binstart + 5 && nn < sections[segment].index; nn++) {
                fprintf(ofp, "%02X ", sections[segment].bytes[nn]);
            }
            fprintf(ofp, "   ; imm\n");
             if (((ca+5) & 15)==15) {
                 ca+=6;
                 binstart+=6;
                 nn++;
             }
             else {
                  ca += 5;
                  binstart += 5;
             }
        }
*/
/*
        if (sections[segment].bytes[binstart]==0xfd) {
            fprintf(ofp, "%06LLX ", ca);
            for (nn = binstart; nn < binstart + 5 && nn < sections[segment].index; nn++) {
                fprintf(ofp, "%02X ", sections[segment].bytes[nn]);
            }
            fprintf(ofp, "   ; imm\n");
             if (((ca+5) & 15)==15) {
                 ca+=6;
                 binstart+=6;
                 nn++;
             }
             else {
                  ca += 5;
                  binstart += 5;
             }
        }
         if (sections[segment].bytes[binstart]==0xfe) {
            fprintf(ofp, "%06LLX ", ca);
            for (nn = binstart; nn < binstart + 5 && nn < sections[segment].index; nn++) {
                fprintf(ofp, "%02X ", sections[segment].bytes[nn]);
            }
            fprintf(ofp, "   ; imm\n");
             if (((ca+5) & 15)==15) {
                 ca+=6;
                 nn++;
             }
             else {
                  ca += 5;
             }
        }
*/
    }

    first = 1;
    while (nn < sections[segment].index) {
        fprintf(ofp, "%06I64X ", ca);
		caia = 0;
        for (mm = nn; nn < mm + cc && nn < sections[segment].index; ) {
			cai = sections[segment].index - nn;
			// Output for instructions with multiple words
			if ((cai % 4) == 0 && cai < 20 && segment==codeseg)
				cai = 4;
			// Otherwise a big stream of information was output, likely data
			if (cai > 8) cai = 8;
//			for (jj = (int)cai-1; jj >= 0; jj--)
//				fprintf(ofp, "%02X", sections[segment].bytes[nn+jj]);
			for (jj = 0; jj < (int) cai; jj++)
				fprintf(ofp, "%02X ", sections[segment].bytes[nn + jj]);
			fprintf(ofp, " ");
			nn += cai;
			caia += cai;
        }
		for (jj = 8 - (int)caia; jj >= 0; jj--)
			fprintf(ofp, "   ");
//        for (; nn < mm + caia; nn++)
//            fprintf(ofp, "  ");
        if (first & opt) {
			fprintf(ofp, "\t%.*s\n", inptr - stptr - 1, stptr);
			first = 0;
        }
        else
            fprintf(ofp, opt ? "\n" : "; NOP Ramp\n");
        ca += caia;
    }
    // empty (codeless) line
    if (binstart==sections[segment].index) {
        fprintf(ofp, "%24s\t%.*s", "", inptr-stptr, stptr);
    }
    } // bGen
    if (opt) {
       stptr = inptr;
       lineno++;
    }
    binstart = sections[segment].index;
    ca = sections[segment].address;
}

static void process_default()
{
	switch (token) {
	case tk_eol: ProcessEOL(1); break;
		//        case tk_add:  process_add(); break;
		//		case tk_abs:  process_rop(0x04); break;
	case tk_abs: process_rop(0x01); break;
	case tk_addi: process_riop(0x04,0x04,0); break;
	case tk_align: process_align(); break;
	case tk_andi:  process_riop(I_ANDI,I_AND2,0); break;
	case tk_asl: process_shift(I_ASL); break;
	case tk_asr: process_shift(I_ASR); break;
	//case tk_bbc: process_bbc(0x26, 1); break;
	//case tk_bbs: process_bbc(0x26, 0); break;
	case tk_begin_expand: expandedBlock = 1; break;
	//case tk_beqi: process_beqi(0x32, 0); break;
	case tk_bfchg: process_bitfield(I_FLIP,7); break;
	case tk_bfclr: process_bitfield(I_DEP,3); break;
	case tk_bfext: process_bitfield(I_EXT,0); break;
	case tk_bfextu: process_bitfield(I_EXT,1); break;
	case tk_bfins: process_bitfield(I_DEP,0); break;
	case tk_bfinsi: process_bitfield(I_DEPI,0); break;
	//case tk_bnei: process_beqi(0x12, 1); break;
	case tk_bra: process_bra(0xD4,0x0C); break;
	case tk_brk: process_brk(); break;
		//case tk_bsr: process_bra(0x56); break;
	case tk_bss:
		if (first_bss) {
			while (sections[segment].address & 4095)
				emitByte(0x00);
			sections[3].address = sections[segment].address;
			first_bss = 0;
			binstart = sections[3].index;
			ca = sections[3].address;
		}
		segment = bssseg;
		break;
	case tk_cache: process_cache(0x1E); break;
	case tk_call:  process_call(0xD0,1); break;
	case tk_cli: emit_insn(0xC0000002); break;
	case tk_chk:  process_chk(0x34); break;
	case tk_cmovenz: process_cmove(0x29); break;
	case tk_cmovfnz: process_cmovf(0x27); break;
		//case tk_cmp:  process_rrop(0x06); break;
	//case tk_cmpi:  process_riop(0x06); break;
	//case tk_cmpu:  process_rrop(0x07); break;
	//case tk_cmpui:  process_riop(0x07); break;
	case tk_code: process_code(); break;
	case tk_com: process_com(3); break;
	case tk_csrrc: process_csrrw(0x3); break;
	case tk_csrrs: process_csrrw(0x2); break;
	case tk_csrrw: process_csrrw(0x1); break;
	case tk_csrrd: process_csrrw(0x0); break;
	case tk_data:
		if (first_data) {
			while (sections[segment].address & 4095)
				emitByte(0x00);
			sections[2].address = sections[segment].address;   // set starting address
			first_data = 0;
			binstart = sections[2].index;
			ca = sections[2].address;
		}
		process_data(dataseg);
		break;
	case tk_db:  process_db(); break;
		//case tk_dbnz: process_dbnz(0x26,3); break;
	case tk_dc:  process_dc(); break;
	case tk_dh:  process_dh(); break;
	case tk_dh_htbl:  process_dh_htbl(); break;
		//case tk_divsu:	process_rrop(0x3D, -1); break;
	case tk_divwait: process_rop(0x13); break;
	case tk_dw:  process_dw(); break;
//	case tk_end: goto j1;
	case tk_end_expand: expandedBlock = 0; break;
	case tk_endpublic: break;
	case tk_eori: process_riop(I_EORI,I_EOR2,0); break;
	case tk_extern: process_extern(); break;
	case tk_file:
		NextToken();
		if (token == tk_strconst)
			mname = std::string(laststr);
		//NextToken();
		//if (token == ',') {
		//	NextToken();
		//	lineno = expr();
		//}
		break;
	case tk_ftoi:	process_ftoi(0x12); break;
	case tk_fadd:	process_fprrop(0x04); break;
	case tk_fbeq:	process_fbcc(0); break;
	case tk_fbge:	process_fbcc(3); break;
	case tk_fblt:	process_fbcc(2); break;
	case tk_fbne:	process_fbcc(1); break;
	case tk_fdiv:	process_fprrop(0x09); break;
	case tk_fill: process_fill(); break;
	case tk_fmov:	process_fprop(0x10); break;
	case tk_fmul:	process_fprrop(0x08); break;
	case tk_fneg:	process_fprop(0x14); break;
	case tk_fsub:	process_fprrop(0x05); break;
	case tk_fslt:	process_fprrop(0x38); break;
	case tk_hint:	process_hint(); break;
		//case tk_ibne: process_ibne(0x26,2); break;
	case tk_if:		pif1 = inptr - 2; doif(); break;
	case tk_ifdef:		pif1 = inptr - 5; doifdef(); break;
	case tk_isnull: process_ptrop(0x06,0); break;
	case tk_itof: process_itof(0x15); break;
	case tk_iret:	process_iret(0xC8000002); break;
	case tk_isptr:  process_ptrop(0x06,1); break;
	case tk_jal: process_jal(0x18); break;
	case tk_jmp: process_call(0xD0,0); break;
	case tk_ld:	process_ld(); break;
		//case tk_lui: process_lui(0x27); break;
	case tk_lv:  process_lv(0x36); break;
	case tk_macro:	process_macro(); break;
	case tk_memdb: emit_insn(0x04400002); break;
	case tk_memsb: emit_insn(0x04440002); break;
	case tk_message: process_message(); break;
	case tk_mov: process_mov(0x02, 0x22); break;
		//case tk_mulh: process_rrop(0x26, 0x3A); break;
		//case tk_muluh: process_rrop(0x24, 0x38); break;
	case tk_neg: process_com(5); break;
	case tk_nop: emit_insn(0x000000EA); break;
	case tk_not: process_com(4); break;
		//        case tk_not: process_rop(0x07); break;
	case tk_ori: process_riop(0x09,0x09,0); break;
	case tk_org: process_org(); break;
	case tk_plus: compress_flag = 0;  expand_flag = 1; break;
	case tk_ptrdif: process_rrop(); break;
	case tk_public: process_public(); break;
	case tk_rodata:
		if (first_rodata) {
			while (sections[segment].address & 4095)
				emitByte(0x00);
			sections[1].address = sections[segment].address;
			first_rodata = 0;
			binstart = sections[1].index;
			ca = sections[1].address;
		}
		segment = rodataseg;
		break;
	//case tk_redor: process_rop(0x06); break;
	case tk_ret: process_ret(); break;
	case tk_rex: process_rex(); break;
	case tk_rol: process_shift(I_ROL); break;
	case tk_roli: process_shifti(I_ROLI); break;
	case tk_ror: process_shift(I_ROR); break;
	case tk_rori: process_shifti(I_RORI); break;
	case tk_rti: process_iret(0xC8000002); break;
	case tk_sei: process_sei(); break;
	case tk_seq:	process_setop(I_SEQ, I_SEQ, 0x00); break;
	
	case tk_setwb: emit_insn(0x04580002); break;
		//case tk_seq:	process_riop(0x1B,2); break;
	case tk_sge:	process_setop(I_SGE, I_SGEI, 0x00); break;
	case tk_sgeu:	process_setop(I_SGEU, I_SGEUI, 0x00); break;
	case tk_sgt:	process_setop(-I_SLT, I_SGTI, 0x00); break;
	case tk_sgtu:	process_setop(-I_SLTU, I_SGTUI, 0x00); break;

	case tk_shl: process_shift(I_ASL); break;
	case tk_shli: process_shifti(I_ASLI); break;
	case tk_shr: process_shift(I_ASR); break;
	case tk_shri: process_shifti(I_ASRI); break;
	case tk_shru: process_shift(I_LSR); break;
	case tk_shrui: process_shifti(I_LSRI); break;

	case tk_sle:	process_setop(-I_SGE, I_SLEI, 0x00); break;
	case tk_sleu:	process_setop(-I_SGEU, I_SLEUI, 0x00); break;
	case tk_slt:	process_setop(I_SLT, I_SLTI, 0x00); break;
	case tk_sltu:	process_setop(I_SLTU, I_SLTUI, 0x00); break;
	case tk_sne:	process_setop(I_SNE, I_SNEI, 0x00); break;

	case tk_slli: process_shifti(I_ASLI); break;
	case tk_srai: process_shifti(I_ASRI); break;
	case tk_srli: process_shifti(I_LSRI); break;
	case tk_subf: process_riop(I_SUBFI, 0x00, 0x00); break;
	case tk_subi:  process_riop(0x05,0x05,0x00); break;
	case tk_sv:  process_sv(0x37); break;
	case tk_swap: process_rop(0x03); break;
		//case tk_swp:  process_storepair(0x27); break;
	case tk_sxb: process_rop(0x1A); break;
	case tk_sxc: process_rop(0x19); break;
	case tk_sxh: process_rop(0x18); break;
	case tk_sync: emit_insn(0x04480002); break;
	case tk_tlbdis:  process_tlb(6); break;
	case tk_tlben:   process_tlb(5); break;
	case tk_tlbpb:   process_tlb(1); break;
	case tk_tlbrd:   process_tlb(2); break;
	case tk_tlbrdreg:   process_tlb(7); break;
	case tk_tlbwi:   process_tlb(4); break;
	case tk_tlbwr:   process_tlb(3); break;
	case tk_tlbwrreg:   process_tlb(8); break;
		//case tk_unlink: emit_insn((0x1B << 26) | (0x1F << 16) | (30 << 11) | (0x1F << 6) | 0x02,0,4); break;
	case tk_vadd: process_vrrop(0x04); break;
	case tk_vadds: process_vsrrop(0x14); break;
	case tk_vand: process_vrrop(0x08); break;
	case tk_vands: process_vsrrop(0x18); break;
	case tk_vdiv: process_vrrop(0x3E); break;
	case tk_vdivs: process_vsrrop(0x2E); break;
	case tk_vmul: process_vrrop(0x3A); break;
	case tk_vmuls: process_vsrrop(0x2A); break;
	case tk_vor: process_vrrop(0x09); break;
	case tk_vors: process_vsrrop(0x19); break;
	case tk_vsub: process_vrrop(0x05); break;
	case tk_vsubs: process_vsrrop(0x15); break;
	case tk_vxor: process_vrrop(0x0A); break;
	case tk_vxors: process_vsrrop(0x1A); break;
	case tk_xori: process_riop(0x0A,0x0A,0x00); break;
	case tk_zxb: process_rop(0x0A); break;
	case tk_zxc: process_rop(0x09); break;
	case tk_zxh: process_rop(0x08); break;
	case tk_id:  process_label(); break;
	case '-': compress_flag = 1; expand_flag = 0; break;
	}
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void rtf64_processMaster()
{
    int nn;
    int64_t bs1, bs2;

    lineno = 1;
    binndx = 0;
    binstart = 0;
		num_lbranch = 0;
    bs1 = 0;
    bs2 = 0;
    inptr = &masterFile[0];
    stptr = inptr;
    code_address = 0;
    bss_address = 0;
    start_address = 0;
    first_org = 1;
    first_rodata = 1;
    first_data = 1;
    first_bss = 1;
	expandedBlock = 0;
	//if (pass == 1) 
	{
		for (nn = 0; nn < tk_last_token; nn++) {
			jumptbl[nn] = &process_default;
			parm1[nn] = 0;
			parm2[nn] = 0;
			parm3[nn] = 0;
		}
		jumptbl[tk_add] = &process_rrop;
		parm1[tk_add] = I_ADD2;
		parm2[tk_add] = I_ADDI;
		jumptbl[tk_cmp] = &process_cmp;
		parm1[tk_cmp] = I_CMP;
		parm2[tk_cmp] = I_CMPI;
		jumptbl[tk_and] = &process_rrop;
		parm1[tk_and] = I_AND2;
		parm2[tk_and] = I_ANDI;
		jumptbl[tk_or] = &process_rrop;
		parm1[tk_or] = I_OR2;
		parm2[tk_or] = I_ORI;
		jumptbl[tk_xor] = &process_rrop;
		parm1[tk_xor] = I_EOR2;
		parm2[tk_xor] = I_EORI;
		jumptbl[tk_eor] = &process_rrop;
		parm1[tk_eor] = I_EOR2;
		parm2[tk_eor] = I_EORI;

		jumptbl[tk_div] = &process_rrop;
		parm1[tk_div] = I_DIV;
		parm2[tk_div] = I_DIVI;
		parm3[tk_div] = 0x00;
		jumptbl[tk_divu] = &process_rrop;
		parm1[tk_divu] = I_DIVU;
		parm2[tk_divu] = I_DIVUI;
		parm3[tk_divu] = 0x00;
		jumptbl[tk_max] = &process_rrop;
		parm1[tk_max] = 0x2DLL;
		parm2[tk_max] = -1LL;
		jumptbl[tk_min] = &process_rrop;
		parm1[tk_min] = 0x2CLL;
		parm2[tk_min] = -1LL;
		jumptbl[tk_mod] = &process_rrop;
		parm1[tk_mod] = 0x16LL;
		parm2[tk_mod] = 0x3ELL;
		parm3[tk_mod] = 0x01LL;
		jumptbl[tk_modu] = &process_rrop;
		parm1[tk_modu] = 0x14LL;
		parm2[tk_modu] = 0x3CLL;
		parm3[tk_modu] = 0x01LL;
		jumptbl[tk_mul] = &process_rrop;
		parm1[tk_mul] = I_MUL;
		parm2[tk_mul] = I_MULI;
		jumptbl[tk_mulf] = &process_rrop;
		parm1[tk_mulf] = 0x2ALL;
		parm2[tk_mulf] = 0x2ALL;
		jumptbl[tk_mulu] = &process_rrop;
		parm1[tk_mulu] = I_MULU;
		parm2[tk_mulu] = I_MULUI;
		jumptbl[tk_sub] = &process_rrop;
		parm1[tk_sub] = I_SUB2;
		parm2[tk_sub] = -I_ADDI;
		jumptbl[tk_ptrdif] = &process_ptrdif;
		parm1[tk_ptrdif] = I_PTRDIF;
		parm2[tk_ptrdif] = -1LL;
		jumptbl[tk_transform] = &process_rrop;
		parm1[tk_transform] = 0x11LL;
		parm2[tk_transform] = -1LL;
		jumptbl[tk_xnor] = &process_rrop;
		parm1[tk_xnor] = I_XNOR;
		parm2[tk_xnor] = -1LL;
		jumptbl[tk_beq] = &process_bcc;
		parm1[tk_beq] = I_BEQ;
		parm2[tk_beq] = 0x04;
		parm3[tk_beq] = 0;
		jumptbl[tk_bge] = &process_bcc;
		parm1[tk_bge] = I_BGE;
		parm2[tk_bge] = 1;
		parm3[tk_bge] = 1;
		jumptbl[tk_bgt] = &process_bcc;
		parm1[tk_bgt] = I_BGT;
		parm2[tk_bgt] = 3;
		parm3[tk_bgt] = 0;
		jumptbl[tk_ble] = &process_bcc;
		parm1[tk_ble] = I_BLE;
		parm2[tk_ble] = 2;
		parm3[tk_ble] = 0;
		jumptbl[tk_blt] = &process_bcc;
		parm1[tk_blt] = I_BLT;
		parm2[tk_blt] = 0;
		parm3[tk_blt] = 0;
		jumptbl[tk_bne] = &process_bcc;
		parm1[tk_bne] = I_BNE;
		parm2[tk_bne] = 0x05;
		parm3[tk_bne] = 0x00;
		jumptbl[tk_ldi] = &process_ldi;
		parm1[tk_ldi] = 0;
		parm2[tk_ldi] = 0;
		// stores
		jumptbl[tk_stb] = &process_store;
		parm1[tk_stb] = I_STB;
		parm2[tk_stb] = I_STB;
		parm3[tk_stb] = 0x00;
		jumptbl[tk_stw] = &process_store;
		parm1[tk_stw] = I_STW;
		parm2[tk_stw] = I_STW;
		parm3[tk_stw] = 0x01;
		jumptbl[tk_stt] = &process_store;
		parm1[tk_stt] = I_STT;
		parm2[tk_stt] = I_STT;
		parm3[tk_stt] = 0x02;
		jumptbl[tk_sto] = &process_store;
		parm1[tk_sto] = I_STO;
		parm2[tk_sto] = I_STO;
		parm3[tk_sto] = 0x03;
		jumptbl[tk_sth] = &process_store;
		parm1[tk_sth] = 0x24;
		parm2[tk_sth] = 0x24;
		parm3[tk_sth] = 0x04;
		jumptbl[tk_swc] = &process_store;
		parm1[tk_swc] = 0x17;
		parm2[tk_swc] = 0x23;
		parm3[tk_swc] = 0x00;
		// loads
		jumptbl[tk_ldb] = &process_load;
		parm1[tk_ldb] = I_LDB;
		parm2[tk_ldb] = I_LDB;
		parm3[tk_ldb] = 0x00;
		jumptbl[tk_ldbu] = &process_load;
		parm1[tk_ldbu] = I_LDBU;
		parm2[tk_ldbu] = I_LDBU;
		parm3[tk_ldbu] = 0x00;
		jumptbl[tk_ldw] = &process_load;
		parm1[tk_ldw] = I_LDW;
		parm2[tk_ldw] = I_LDW;
		parm3[tk_ldw] = 0x01;
		jumptbl[tk_ldwu] = &process_load;
		parm1[tk_ldwu] = I_LDWU;
		parm2[tk_ldwu] = I_LDWU;
		parm3[tk_ldwu] = 0x01;
		jumptbl[tk_lea] = &process_load;
		parm1[tk_lea] = 0x0E;
		parm2[tk_lea] = 0x18;
		parm3[tk_lea] = 0x00;
		jumptbl[tk_ldt] = &process_load;
		parm1[tk_ldt] = I_LDT;
		parm2[tk_ldt] = I_LDT;
		parm3[tk_ldt] = 0x02;
		jumptbl[tk_ldtu] = &process_load;
		parm1[tk_ldtu] = I_LDTU;
		parm2[tk_ldtu] = I_LDTU;
		parm3[tk_ldtu] = 0x02;
		jumptbl[tk_ldo] = &process_load;
		parm1[tk_ldo] = I_LDO;
		parm2[tk_ldo] = I_LDO;
		parm3[tk_ldo] = 0x03;
		jumptbl[tk_ldor] = &process_load;
		parm1[tk_ldor] = I_LDOR;
		parm2[tk_ldor] = I_LDOR;
		parm3[tk_ldor] = 0x03;
		jumptbl[tk_ldh] = &process_load;
		parm1[tk_ldh] = 0x04;
		parm2[tk_ldh] = 0x04;
		parm3[tk_ldh] = 0x04;
/*
		jumptbl[tk_lvb] = &process_load;
		parm1[tk_lvb] = -1;
		parm2[tk_lvb] = 0x00;
		parm3[tk_lvb] = 0x00;
		jumptbl[tk_lvbu] = &process_load;
		parm1[tk_lvbu] = -1;
		parm2[tk_lvbu] = 0x01;
		parm3[tk_lvbu] = 0x00;
		jumptbl[tk_lvc] = &process_load;
		parm1[tk_lvc] = 0x3B;
		parm2[tk_lvc] = 0x02;
		parm3[tk_lvc] = 0x01;
		jumptbl[tk_lvcu] = &process_load;
		parm1[tk_lvcu] = 0x11;
		parm2[tk_lvcu] = 0x03;
		parm3[tk_lvcu] = -1;
		jumptbl[tk_lvh] = &process_load;
		parm1[tk_lvh] = 0x3B;
		parm2[tk_lvh] = 0x04;
		parm3[tk_lvh] = 0x02;
		jumptbl[tk_lvhu] = &process_load;
		parm1[tk_lvhu] = 0x11;
		parm2[tk_lvhu] = 0x05;
		parm3[tk_lvhu] = -2;
		jumptbl[tk_lvw] = &process_load;
		parm1[tk_lvw] = 0x3B;
		parm2[tk_lvw] = 0x06;
		parm3[tk_lvw] = 0x04;
*/
		jumptbl[tk_sf] = &process_store;
		parm1[tk_sf] = 0x2B;
		parm2[tk_sf] = 0x2D;
		parm3[tk_sf] = 0x01;
		jumptbl[tk_lf] = &process_load;
		parm1[tk_lf] = 0x1B;
		parm2[tk_lf] = 0x1D;
		parm3[tk_lf] = 0x01;
	}
	tbndx = 0;

	if (pass==3) {
    htblmax = 0;
    for (nn = 0; nn < 100000; nn++) {
      hTable[nn].count = 0;
      hTable[nn].opcode = 0;
    }
  }
  for (nn = 0; nn < 12; nn++) {
    sections[nn].index = 0;
    if (nn == 0)
    sections[nn].address = 0;
    else
    sections[nn].address = 0;
    sections[nn].start = 0;
    sections[nn].end = 0;
  }
  ca = code_address;
  segment = codeseg;
  memset(current_label,0,sizeof(current_label));
	ZeroMemory(&insnStats, sizeof(insnStats));
	num_lbranch = 0;
	num_insns = 0;
	num_cinsns = 0;
	num_bytes = 0;
  NextToken();
  while (token != tk_eof && token != tk_end) {
		recflag = FALSE;
//        printf("\t%.*s\n", inptr-stptr-1, stptr);
//        printf("token=%d\r", token);
    if (expandedBlock)
      expand_flag = 1;
		(*jumptbl[token])();
    NextToken();
  }
j1:
  ;
}

