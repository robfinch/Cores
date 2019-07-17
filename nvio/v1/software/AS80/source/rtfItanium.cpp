// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AS80 - Assembler
//  - 80 bit CPU
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
#define I_RR	0x02
#define I_MOV		0x10
#define I_ADDI	0x04
#define I_ADD		0x04
#define I_CSR		0x05
#define I_SUB		0x05
#define I_ADDS0	0x33
#define I_ADDS1	0x34
#define I_ADDS2	0x35
#define I_ADDS3	0x36
#define I_OR		0x09
#define I_ORI		0x09
#define I_ORS1	0x3C
#define I_ORS2	0x3D
#define I_ORS3	0x3E
#define I_ORS0	0x3F
#define I_XOR		0x0A
#define I_XORI	0x0A
#define I_DIV		0x22
#define I_DIVI	0x22
#define I_SHL		0x32
#define I_SHLI	0x38
#define I_ASL		0x33
#define I_ASLI	0x39
#define I_SHR		0x34
#define I_SHRI	0x3A
#define I_ASR		0x35
#define I_ASRI	0x3B
#define I_ROL		0x36
#define I_ROLI	0x3C
#define I_ROR		0x37
#define I_RORI	0x3D

#define I_SLT		0x10
#define I_SLTU	0x14
#define I_SLTI	0x10
#define I_SLTUI	0x14
#define I_SGE		0x11
#define I_SGEU	0x15
#define I_SGEI	0x11
#define I_SGEUI	0x15
#define I_SLE		0x12
#define I_SLEU	0x16
#define I_SLEI	0x12
#define I_SLEUI	0x16
#define I_SGT		0x13
#define I_SGTI	0x13
#define I_SGTU	0x17
#define I_SGTUI	0x17
#define I_SEQ		0x18
#define I_SEQI	0x18
#define I_SNE		0x19
#define I_SNEI	0x19

#define I_Bcc		0x0
#define I_BLcc	0x1
#define I_BRcc	0x2
#define I_NOP		0x3
#define I_FBcc	0x4
#define I_BBc		0x5
#define I_BEQI	0x6
#define I_BNEI	0x7
#define I_JAL		0x8
#define I_JMP		0x9
#define I_CALL	0xA
#define I_RET		0xB
#define I_CHKI	0xC
#define I_CHK		0xD
#define I_BMISC	0xE
#define I_BRK		0xF

#define I_BEQ		0x0
#define I_BNE		0x1
#define I_BLT		0x2
#define I_BGE		0x3
#define I_BLTU	0x6
#define I_BGEU	0x7
#define I_BEQR	0x0
#define I_BNER	0x1
#define I_BLTR	0x2
#define I_BGER	0x3
#define I_BNANDR	0x4
#define I_BNORR		0x5
#define I_BLTUR	0x6
#define I_BGEUR	0x7
#define I_FBEQR	0x8
#define I_FBNER	0x9
#define I_FBLTR	0xA
#define I_FBLER	0xB
#define I_BANDR	0xC
#define I_BORR	0xD
#define I_FBUN	0xE
#define I_FBEQ	0x0
#define I_FBNE	0x1
#define I_FBLT	0x2
#define I_FBLE	0x3
#define I_FBUN	0x6

#define I_BNAND	0x0
#define I_BNOR	0x1
#define I_BAND	0x4
#define I_BOR		0x5

#define I_SEI		0x3

#define I_MSX		0xF
#define I_MLX		0xF
#define I_PUSHC	0xB
#define I_TLB		0xC
#define I_PUSH	0xD
#define I_POP		0x1D

#define I_AND		0x08
#define I_ANDI	0x08
#define I_FLOAT	0x0F
#define I_SHIFT31	0x0F
#define I_PTRDIF	0x1E
#define I_SHIFT63	0x1F
#define I_SHIFTR	0x2F

#define I_LDB		0x00
#define I_LDW		0x01
#define I_LDP		0x02
#define I_LDD		0x03
#define I_LDBU	0x04
#define I_LDWU	0x05
#define I_LDPU	0x06
#define I_LDDR	0x07
#define I_LDT		0x08
#define I_LDO		0x09
#define I_AMO		0x0B
#define I_LDTU	0x0C
#define I_LDOU	0x0D
#define I_LEA		0x0E
#define I_MLX		0x0F
#define I_LDFS	0x10
#define I_LDFD	0x11
#define I_LDFDP	0x12
#define I_LDDP	0x13

#define I_STB		0x20
#define I_STW		0x21
#define I_STP		0x22
#define I_STD		0x23
#define I_STDC	0x27
#define I_STT		0x28
#define I_STO		0x29
#define I_CAS		0x2A
#define I_PUSHC	0x2B
#define I_TLB		0x2C
#define I_PUSH	0x2D
#define I_CACHE	0x2E
#define I_MSX		0x2F
#define I_STFS	0x30
#define I_STFD	0x31
#define I_STFDP	0x32
#define I_STDP	0x33

#define I_SB	0x15
#define I_MEMNDX	0x16
#define I_LFx		0x1B
#define I_LC		0x20
#define I_LH		0x21
#define I_SFx	0x2B
#define I_LUI	0x27
#define I_CMOVEZ	0x28
#define I_CMOVNZ	0x29
#define I_LW	0x33
#define I_SH	0x35
#define I_LV	0x36
#define I_SV	0x37

#define N		0
#define B		1
#define I		2
#define F		3
#define M		4

#define NOP_INSN	0x00000000C0

static void (*jumptbl[tk_last_token])();
static int64_t parm1[tk_last_token];
static int64_t parm2[tk_last_token];
static int64_t parm3[tk_last_token];

extern InsnStats insnStats;
static void ProcessEOL(int opt);
extern void process_message();
static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc, int *seg, int *pp);

extern char *pif1;
extern int first_rodata;
extern int first_data;
extern int first_bss;
extern int htblmax;
extern int pass;
extern int num_cinsns;

static int64_t ca;

extern int use_gp;

static int regSP = 63;
static int regFP = 62;
static int regLR = 61;
static int regXL = 60;
static int regGP = 59;
static int regTP = 58;
static int regCB = 57;
static int regCnst;

#define OPT64     0
#define OPTX32    1
#define OPTLUI0   0
#define LB16	-31653LL

#define OP2(x)	(((x) & 3LL) << 31LL)
#define OP4(x)	(((x) & 15LL) << 6LL)
#define OP6(x)	(OP4(x)|OP2((x) >> 4LL))
#define MOP(x)	(OP4(x)|(((x)>>4LL) & 3LL) << 33LL)
#define FN5(x)	(((x) & 0x1fLL) << 35LL)
#define FN6(x)	((FN5((x) >> 1)|(((x) & 1LL) << 6LL))|0x80LL)
#define FN2(x)	(((x) & 3LL)<<33LL)
#define SC(x)		(((x) & 7LL) << 28LL)
#define SZ(x)   (((x) & 7LL) << 28LL)
#define RT(x)		((x) & 63LL)
#define RA(x)		(((x) & 63LL) << 10LL)
#define RB(x)		(((x) & 63LL) << 16LL)
#define RC(x)		(((x) & 63LL) << 22LL)
#define RII(x)	((((x) & 0x7fffLL) << 16LL) | ((((x) >> 15LL) & 0x7fLL) << 33LL))
#define MLI(x)	((((x) & 0x7fffLL) << 16LL) | ((((x) >> 15LL) & 0x1fLL) << 35LL))
#define MSI(x)	(((x) & 0x3fLL) | ((((x) >> 6LL) & 0x1ffLL) << 22LL) | ((((x) >> 15LL) & 0x1fLL) << 35LL))
#define FMT(x)	(((x) & 15LL)<<31LL)
#define RM(x)		(((x) & 7LL) << 28LL)
#define FLT3(x)	(((x) & 0x3fLL) << 22LL)
#define BT(x)		((((x) >> 4LL) << 24LL)|((((x) & 15L)>>2LL)<<22LL))

bool TmpUsed[125];
__int8 TmpTbl[125][3] =
{
{B,B,B},
{I,B,B},
{F,B,B},
{M,B,B},
{B,I,B},
{I,I,B},
{F,I,B},
{M,I,B},
{B,F,B},
{I,F,B},

{F,F,B},
{M,F,B},
{B,M,B},
{I,M,B},
{F,M,B},
{M,M,B},
{B,B,I},
{I,B,I},
{F,B,I},
{M,B,I},

{B,I,I},
{I,I,I},
{F,I,I},
{M,I,I},
{B,F,I},
{I,F,I},
{F,F,I},
{M,F,I},
{B,M,I},
{I,M,I},

{F,M,I},
{M,M,I},
{B,B,F},
{I,B,F},
{F,B,F},
{M,B,F},
{B,I,F},
{I,I,F},
{F,I,F},
{M,I,F},

{B,F,F},
{I,F,F},
{F,F,F},
{M,F,F},
{B,M,F},
{I,M,F},
{F,M,F},
{M,M,F},
{B,B,M},
{I,B,M},

{F,B,M},
{M,B,M},
{B,I,M},
{I,I,M},
{F,I,M},
{M,I,M},
{B,F,M},
{I,F,M},
{F,F,M},
{M,F,M},

{B,M,M},
{I,M,M},
{F,M,M},
{M,M,M},

/*
	// *****
	{I,I,I},
{L,I,I},
{I,L,I},
{L,L,I},
{I,I,L},
{L,I,L},
{I,L,L},
{L,L,L},

{B,I,I},
{I,B,I},
{B,B,I},
{I,I,B},
{B,I,B},
{I,B,B},
{B,B,B},

{F,I,I},
{I,F,I},
{F,F,I},
{I,I,F},
{F,I,F},
{I,F,F},
{F,F,F},

{B,L,L},
{L,B,L},
{B,B,L},
{L,L,B},
{B,L,B},
{L,B,B},

{B,F,F},
{F,B,F},
{B,B,F},
{F,F,B},
{B,F,B},
{F,B,B},

{L,F,F},
{F,L,F},
{L,L,F},
{F,F,L},
{L,F,L},
{F,L,L},

{S,L,L},
{L,S,L},
{S,S,L},
{L,L,S},
{S,L,S},
{L,S,S},

{L,S,I},
{S,L,I},
{I,L,S},
{I,S,L},
{L,I,S},
{S,I,L},

{B,L,S},
{B,S,L},
{L,B,S},
{S,B,L},
{L,S,B},
{S,L,B},

{F,L,S},
{F,S,L},
{L,F,S},
{S,F,L},
{L,S,F},
{S,L,F},

{N,N,N},
{S,I,I},
{I,S,I},
{S,S,I},
{I,I,S},
{S,I,S},
{I,S,S},
{S,S,S},

{S,F,F},
{F,S,F},
{S,S,F},
{F,F,S},
{S,F,S},
{F,S,S},

{B,I,L},
{B,I,S},
{B,I,F},
{F,I,B},
{B,L,I},
{L,B,I},
{I,B,L},
{I,L,B},

{B,S,S},
{S,B,S},
{B,B,S},
{S,S,B},
{B,S,B},
{S,B,B},


{B,S,I},
{I,B,S},
{S,B,I},
{S,I,B},

{I,S,B},
{L,I,B},
{F,S,I},

{L,F,I},
{ F,I,L },
{I,L,F},
{F,B,I},
{ I,F,B },
{B,L,F},
{ L,F,B },
{F,S,B },
{ F,B,L },
{S,F,I},
{F,L,I},

{S,B,F},
{B,F,I},
{I,F,L},
{F,L,B},

{F,I,S},
{I,B,F},
{ B,F,L },
*/
};

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
    if ((inptr[1]=='a' || inptr[1]=='A') && !isIdentChar(inptr[2])) {
      inptr += 2;
      NextToken();
      return (regLR);
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
      reg = inptr[1]-'0' + 18;
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
		break;

  case 'g': case 'G':
    if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
      inptr += 2;
      NextToken();
      return (regGP);
    }
    break;

	case 'p': case 'P':
        if ((inptr[1]=='C' || inptr[1]=='c') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 31;
        }
        break;

  case 's': case 'S':
    if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
      inptr += 2;
      NextToken();
      return (regSP);
    }
    break;

    case 't': case 'T':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0' + 3;
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
             if (isIdentChar(inptr[2]))
                 return -1;
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
        /*
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 24;
        }
        */
        break;
	// lr
    case 'l': case 'L':
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return (regLR);
        }
        break;
	// xlr
    case 'x': case 'X':
        if ((inptr[1]=='L' || inptr[1]=='l') && (inptr[2]=='R' || inptr[2]=='r') && 
			!isIdentChar(inptr[3])) {
            inptr += 3;
            NextToken();
            return (regXL);
        }
        break;
	case 'v': case 'V':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0' + 1;
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


static int GetTemplate(int units)
{
	int n;

	if (units == 0200)
		return (0x7D);
	if (units == 0300)
		return (0x7E);
	if (units == 0400)
		return (0x7F);
	for (n = 0; n < 64; n++) {
		if ((units & 7) == TmpTbl[n][2]) {
			if (((units >> 3) & 7) == TmpTbl[n][1]) {
				if (((units >> 6) & 7) == TmpTbl[n][0]) {
					TmpUsed[n] = true;
					return (n);
				}
			}
		}
	}
	printf("Template not found (%3o).\n", units);
	return (255);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int64_t oc, int unit)
{
	int ndx;
	int opmajor = oc & 0x3f;
	int ls;
	int cond;
	static int units = 0;
	int tmplt = 255;

	if ((code_address & 15) == 0)
		units = 0;
	num_insns += 1;
	emitByte(oc);
	emitByte(oc >> 8);
	emitByte(oc >> 16);
	emitByte(oc >> 24);
	emitByte(oc >> 32);
	num_bytes += 5;
	units = (units << 3) | (unit & 7);
	if ((code_address & 15) == 15) {
		emitByte(GetTemplate(units));
		num_bytes++;
	}
	return;
}
 
static void LoadConstant(Int128& val, int rg)
{
	Int128 tmp;

	if (IsNBit128(val, *Int128::MakeInt128(22LL))) {
		emit_insn(
			RII(val.low) |
			RT(rg) |
			RA(0) |
			OP6(I_ADDI), I);	// ADDI (sign extends)
		return;
	}
	if (IsNBit128(val, *Int128::MakeInt128(40LL))) {
		Int128::Shr(&tmp, &val, 20LL);
		emit_insn(
			RII(tmp.low) |
			RT(rg) |
			RA(0) |
			OP6(I_ADDS1), I);	// ADDDS (sign extends)
		emit_insn(
			RII(val.low & 0xfffffLL) |
			RA(rg) |
			RT(rg) |
			OP6(I_ORS0), I);	// ORS0 (zero extends)
		return;
	}
	if (IsNBit128(val, *Int128::MakeInt128(60LL))) {
		Int128::Shr(&tmp, &val, 40LL);
		emit_insn(
			RII(tmp.low) |
			RT(rg) |
			OP6(I_ADDS2), I);
		Int128::Shr(&tmp, &val, 20LL);
		emit_insn(
			RII(tmp.low & 0xfffffLL) |
			RA(rg) |
			RT(rg) |
			OP6(I_ORS1), I);	// ORS1 (zero extends)
		emit_insn(
			RII(val.low & 0xfffffLL) |
			RA(rg) |
			RT(rg) |
			OP6(I_ORS0), I);	// ORS0 (zero extends)
		return;
	}
	if ((code_address % 16) == 0x0A) {
		emit_insn(0x00C0, B);
		emit_insn(
			RII(0) |
			RA(0) |
			RT(rg) |
			OP6(I_ORI), I);	// ORI
		emit_insn(val.low, 0);
		emit_insn((val.high << 24LL) | ((unsigned int64_t)val.low >> 40LL), 0);
		return;
	}
	if ((code_address % 16) == 0x00) {
		emit_insn(
			RII(0) |
			RA(0) |
			RT(rg) |
			OP6(I_ORI), I);	// ORI (zero extends)
		emit_insn(val.low, 0);
		emit_insn((val.high << 24LL) | ((unsigned int64_t)val.low >> 40LL), 0);
		return;
	}
	// Won't fit into 66 bits, assume 80 bit constant
	Int128::Shr(&tmp, &val, 60LL);
	emit_insn(
		RII(tmp.low) |
		RT(rg) |
		OP6(I_ADDS3), I);
	Int128::Shr(&tmp, &val, 40LL);
	emit_insn(
		RII(tmp.low & 0xfffffLL) |
		RA(rg) |
		RT(rg) |
		OP6(I_ORS2), I);
	Int128::Shr(&tmp, &val, 20LL);
	emit_insn(
		RII(tmp.low & 0xfffffLL) |
		RA(rg) |
		RT(rg) |
		OP6(I_ORS1), I);
	emit_insn(
		RII(val.low & 0xfffffLL) |
		RA(rg) |
		RT(rg) |
		OP6(I_ORS0), I);
	return;
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
			*sz = 4;
		}
		else
			*sz = 0;
		break;
	case 'c': case 'C':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 5;
		}
		else
			*sz = 1;
		break;
    case 'h': case 'H':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 6;
		}
		else
			*sz = 2;
		break;
    case 'w': case 'W':
		if (inptr[1] == 'p' || inptr[1] == 'P') {
			inptr++;
			*sz = 7;
		}
		else
			*sz = 3;
		break;
	case 'd': case 'D': *sz = 0x83; break;
	case 'i': case 'I': *sz = 0x43; break;
  default: 
    error("Bad size");
    *sz = 3;
  }
  inptr += 1;
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
  Int128 val;
	int sz = 3;

  p = inptr;
	if (*p == '.')
		getSz(&sz);
	Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  val = expr128();
	if (opcode6 < 0) {
		if (opcode6 == -4LL) {	// subtract is an add
			opcode6 = 4LL;
			Int128::Sub(&val, Int128::Zero(), &val);	// make val -
		}
		else
			error("Immediate mode not supported.");
	}
	if (!IsNBit128(val, *Int128::MakeInt128(44LL)) && ((code_address % 16)==10 || (code_address % 16)==0)) {
		if ((code_address % 16) == 10)
				emit_insn(0x00000000C0,B);
		emit_insn(
			OP6(opcode6) |
			RII(0) |
			RT(Rt) |
			RA(Ra), I);
		emit_insn(val.low,0);
		emit_insn((val.high << 24LL) | ((unsigned int64_t)val.low >> 40LL), 0);
		goto xit;
	}
	if (!IsNBit128(val, *Int128::MakeInt128(21LL))) {
		LoadConstant(val, 54);
		emit_insn(
			FN6(func6) |
			RT(Rt) |
			RA(Ra) |
			RB(54), I);
		goto xit;
	}
	emit_insn(
		OP6(opcode6) |
		RII(val.low) |
		RT(Rt) |
		RA(Ra), I);
xit:
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// slti r1,r2,#1234
//
// A value that is too large has to be loaded into a register then the
// instruction converted to a registered form.
// ---------------------------------------------------------------------------

static void process_setiop(int64_t opcode6, int64_t func6, int64_t bit23)
{
	int Ra;
	int Rt;
	char *p;
	Int128 val;

	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr128();
	if (!IsNBit128(val, *Int128::MakeInt128(22LL))) {
		LoadConstant(val, 54);
		emit_insn(
			FN6(func6) |
			RT(Rt) |
			RB(54) |
			RA(Ra), I);
		return;
	}
	emit_insn(
		RII(val.low) |
		RT(Rt)|
		RA(Ra) |
		OP6(opcode6), I);
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

	p = inptr;
	if (*p == '.')
		getSz(&sz);
	sz &= 7;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	q = inptr;
	Rb = getRegisterX();
	if (Rb == -1) {
		inptr = p;
		process_riop(opcode6, funct6, bit23);
		return;
	}
	emit_insn(
		FN6(funct6) |
		RB(Rb) |
		RT(Rt) |
		RA(Ra),	I);
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

	instr = 0LL;
  p = inptr;
	if (*p=='.')
		getSz(&sz);
  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  if (token=='#') {
	if (iop < 0 && iop!=-4LL)
		error("Immediate mode not supported");
		//printf("Insn:%d\n", token);
    inptr = p;
    process_riop(iop,funct6,bit23);
    return;
  }
  prevToken();
  Rb = getRegisterX();
	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
  emit_insn(instr | FN6(funct6)|SZ(sz)|RB(Rb)|RT(Rt)|RA(Ra),I);
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
	need(',');
	NextToken();
	sc = expr();

	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
	emit_insn(instr | FN6(funct6) | (sc << 28) | RB(Rb) | RT(Rt) | RA(Ra), I);
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

	p = inptr;
	if (*p == '.')
		getSz(&sz);
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
		case 0x08:	Rc = Rb; break;	// and
		case 0x09:	Rc = 0; break;	// or
		case 0x0A:	Rc = 0; break;	// xor
		}
	}
	emit_insn(FN6(funct6) | RT(Rt) | RC(Rc) | RB(Rb) | RA(Ra), I);
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
	Rc = getRegisterX();
	emit_insn(
		FN6(funct6) |
		RC(Rc) |
		RB(Rb) |
		RT(Rt) |
		RA(Ra), I);
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
	emit_insn(FN6(funct6) | RT(Rt) | RC(Rc) | RB(Rb) | RA(Ra), I);
}

// ---------------------------------------------------------------------------
// jmp main
// jal [r19]
// ---------------------------------------------------------------------------

static void process_jal(int64_t oc)
{
  Int128 addr, val;
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
		emit_insn(RA(Ra) | RT(Rt) | OP4(I_JAL), B);
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
		addr = expr128();
    // d(Rn)? 
    //NextToken();
    if (token=='(' || token=='[') {
        Ra = getRegisterX();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
	}
	val = addr;
	if (IsNBit128(val, *Int128::MakeInt128(22LL))) {
		emit_insn(
			RII(val.low) |
			RT(Rt) |
			RA(Ra) |
			OP4(I_JAL), B);
		goto xit;
	}
	LoadConstant(val, 54);
		if (Ra != 0) {
			// add r54,r54,Ra
			emit_insn(
				FN6(I_ADD) |
				RB(54) |
				RT(54) |
				RA(Ra), I);
			// jal Rt,r54
			emit_insn(
				RT(Rt) |
				RA(54) | OP4(I_JAL), B);
			goto xit;
		}
		emit_insn(
			RT(Rt) |
			RA(54) | OP4(I_JAL), B);
		goto xit;
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
  emit_insn(
		FMT(fmt) |
		RM(rm) |
		FLT3(oc) |
		RT(Rt)|
		RB(0)|
		RA(Ra) |
		OP4(0x01), F
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
  emit_insn(
		FLT3(oc) |
		FMT(fmt) |
		RM(rm)|
		RT(Rt)|
		RB(0)|
		RA(Ra) |
		OP4(0x1), F
		);
}

static void process_itanium_align()
{
	int64_t val;

	NextToken();
	val = expr();
	if (segment == codeseg) {
		if ((code_address % val) != 0LL) {
			emit_insn(NOP_INSN, B);
			emit_insn(NOP_INSN, B);
			emit_insn(NOP_INSN, B);
		}
		if ((val % 16) != 0)
			error("Bad code alignment.");
		while (code_address % val)
			emitByte(00);
	}
	else
		process_align();
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
	emit_insn(
		FLT3(oc) |
		FMT(fmt) |
		RM(rm) |
		RT(Rt) |
		RB(0) |
		RA(Ra) |
		OP4(0x1)
		, F
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
  emit_insn(
		FLT3(oc)|
		FMT(fmt) |
		RM(rm)|
		RT(Rt)|
		RB(Rb)|
		RA(Ra) |
		OP4(0x1), F
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
		RB((bits & 0x3F)) |
		FLT3(oc) |
		RA(Ra) |
		OP4(1), F
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
	Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
	emit_insn(
		FN5(oc) |
		SZ(sz) |
		OP6(1) |
		RT(Rt) |
		RA(Ra)
		, I
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
		FN5(oc) |
		OP6(1) |
		RT(Rt) |
		RA(Ra)
		, I
	);
	prevToken();
}

// ---------------------------------------------------------------------------
// beqi r2,#123,label
// ---------------------------------------------------------------------------

static void process_beqi(int64_t opcode6, int64_t opcode3)
{
  int Ra, pred = 0;
  Int128 val, imm;
  Int128 disp;
	Int128 ca;
	int64_t s2;
	int sz = 3;
	int ins48 = 0;
	char *p;

	p = inptr;
	if (*p == '.')
		getSz(&sz);

	Ra = getRegisterX();
	need(',');
	NextToken();
	imm = expr128();
	need(',');
	NextToken();
	val = expr128();
	ca = Int128(code_address);
	if (!IsNBit128(imm, *Int128::MakeInt128(9LL))) {
		//printf("Branch immediate too large: %d %I64d", lineno, imm);
		LoadConstant(imm, 54LL);
		Int128::Assign(&disp, &val);
		emit_insn(
			BT(disp.low) |
			RB(54) |
			RA(Ra) |
			I_BEQ | (opcode6 & 1)
			, B
		);
		return;
	}
	s2 = val.low & 15L;
	val.low &= 0xfffffffffffffff0L;
	ca.low &= 0xfffffffffffffff0L;
	Int128::Sub(&disp, &val, &ca);
	emit_insn(
		BT((disp.low & 0xfffffffffffffff0L) | s2) |
		(((imm.low >> 3LL) & 0x3FLL) << 16LL) |
		(imm.low & 7LL) |
		RA(Ra) |
		OP4(I_BEQI) | (opcode6 & 1)
		,B
	);
	return;
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

static void process_bbc(int opcode6, int opcode2)
{
	int Ra, Rc, pred;
	int64_t bitno, s2;
	Int128 val;
	Int128 disp, ca;
	char *p1, *p2;
	int sz = 3;
	char *p;
	bool isn48 = false;

	p = inptr;
	if (*p == '.')
		getSz(&sz);

	pred = 3;		// default: statically predict as always taken
	p1 = inptr;
	Ra = getRegisterX();
	need(',');
	NextToken();
	bitno = expr();
	need(',');
	p = inptr;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p;
		val = expr128();
	}
	else
		Int128::Assign(&val, Int128::Zero());
	ca = Int128(code_address);
	s2 = val.low & 15L;
	val.low &= 0xfffffffffffffff0L;
	ca.low &= 0xfffffffffffffff0L;
	Int128::Sub(&disp, &val, &ca);
	if (Rc == -1) {
		if (!IsNBit128(val, *Int128::MakeInt128(20LL))) {
			if (pass > 4)
				error("Branch target too far away");
		}
		emit_insn(
			BT((disp.low & 0xfffffffffffffff0L) | s2) |
			RB((bitno >> 1L) & 63L) |
			((bitno & 1) << 2) |
			RA(Ra) | opcode6
			, B
		);
		return;
	}
	error("bbs/bbc: target must be a label");
}

// ---------------------------------------------------------------------------
// beq r1,r2,label
// bne r2,r3,r4
//
// When opcode4 is negative it indicates to swap the a and b registers. This
// allows source code to use alternate forms of branch conditions.
// ---------------------------------------------------------------------------

static void process_bcc()
{
	int Ra, Rb, Rc, pred;
	int swp;
	int fmt;
	Int128 val, ca4, ca2;
	Int128 disp, ca;
	int64_t s2;
	char *p1, *p2;
	int encode;
	int ins48 = 0;
	int64_t opcode6 = parm1[token];
	int64_t opcode4 = parm2[token];
	int64_t op4 = parm3[token];

	fmt = GetFPSize();
	pred = 0;
	p1 = inptr;
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	p2 = inptr;
	NextToken();
	if (token == '#' && opcode4 == 0) {
		inptr = p1;
		process_beqi(0x0, 0);
		return;
	}
	inptr = p2;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p2;
		val = expr128();
	}
	else
		Int128::Assign(&val, Int128::Zero());
	ca = Int128(code_address);
	s2 = val.low & 15L;
	val.low &= 0xfffffffffffffff0L;
	ca.low &= 0xfffffffffffffff0L;
	Int128::Sub(&disp, &val, &ca);
	if (Rc == -1) {
		if (!IsNBit128(val, *Int128::MakeInt128(20LL))) {
			if (pass > 4)
				error("Branch target too far away");
		}
	}
	if (opcode4 < 0) {
		opcode4 = -opcode4;
		swp = Ra;
		Ra = Rb;
		Rb = swp;
	}
	if (Rc < 0) {
		emit_insn(
			BT((disp.low & 0xfffffffffffffff0L) | s2) |
			RB(Rb) |
			RA(Ra) | opcode6
			, B
		);
		return;
	}
	emit_insn(
		RC(Rc) |
		RB(Rb) |
		RA(Ra) |
		OP4(I_BRcc) |
		opcode4 
		, B);
	return;
}

// ---------------------------------------------------------------------------
// bfextu r1,#1,#63,r2
// ---------------------------------------------------------------------------

static void process_bitfield(int64_t oc)
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

	Rt = getRegisterX();
	need(',');
	p = inptr;
	Ra = getRegisterX();
	if (Ra == -1) {
		inptr = p;
		NextToken();
		mb = expr();
		gmb = true;
	}
	else if (oc == 3)
		printf("Bitfield offset must be a constant for BFINS (%d)\r\n", lineno);
	need(',');
	p = inptr;
	Rb = getRegisterX();
	if (Rb == -1) {
		inptr = p;
		NextToken();
		me = expr();
		gme = true;
	}
	need(',');
	p = inptr;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p;
		NextToken();
		val = expr();
		gval = true;
	}
	if (oc == 4) {
		need(',');
		NextToken();
		val = expr();
		gval = true;
	}
	if (oc == 3) {
		need(',');
		Ra = getRegisterX();
	}
	op =
		(oc << 44LL) |
		((gval?1LL:0LL) << 43LL) |
		((gme?1LL:0LL) << 42LL) |
		((gmb?1LL:0LL) << 41LL) |
		RT(Rt) |
		(1 << 6) |
		0x22;
	if (oc == 3) {
		op |= ((mb & 63LL) << 34LL);
		op |= RA(Ra);
	}
	else if (gmb)
		op |= RA(mb & 31LL) | (((mb >> 5LL) & 1LL) << 39LL);
	else
		op |= RA(Ra);
	if (gme)
		op |= RB(me & 31LL) | (((me >> 5LL) & 1LL) << 40LL);
	else
		op |= RB(Rb);
	if (gval) {
		if (oc==4)
			op |= ((val & 0x7ffLL) << 28LL) | RC(Rc);
		else
			op |= ((val & 0xffffLL) << 23LL);
	}
	else
		op |= RC(Rc);

	emit_insn(op, I);
	ScanToEOL();
}


// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int oc)
{
  int Ra = 0, Rb = 0;
  int64_t val;
	int64_t disp;
	int ins48 = 0;

  NextToken();
  val = expr();
	disp = (val & 0xfffffffffffffff0L) - (code_address & 0xfffffffffffffff0L);
	if (!IsNBit(disp, 20LL)) {
		if (pass > 4)
			error("Bra target too far away");
	}
	emit_insn(
		BT((disp & 0xfffffffffffffff0L) | (val & 15L)) | 
		BT(disp) |
		OP4(I_Bcc)
    ,B
    );
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
	emit_insn(
		RC(Rc) |
		RB(Rb) |
		RA(Ra) |
		OP4(I_CHK), B
	);
}


static void process_chki(int opcode6)
{
	int Ra;
	int Rb;
	Int128 val, disp; 
     
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	NextToken();
	val = expr128();
	// ToDO: Fix
	if (!(IsNBit128(val, *Int128::MakeInt128(22LL)))) {
		LoadConstant(val, 54);
		emit_insn(
			RC(54) |
			RB(Rb) |
			RA(Ra) |
			OP4(I_CHK)
			, B
		);
		return;
	}
	emit_insn(
		MSI(val.low) |
		RB(Rb) |
		RA(Ra) |
		OP4(I_CHKI)
		, B
	);
}


// ---------------------------------------------------------------------------
// fbeq.q fp1,fp0,label
// ---------------------------------------------------------------------------

static void process_fbcc(int64_t opcode3)
{
	int Ra, Rb, Rc;
	Int128 val;
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
		val = expr128();
	}
	if (Rc == -1) {
		if (!IsNBit128(val, *Int128::MakeInt128(22LL)))
			error("FBcc branch too far");
			emit_insn(
				BT(val.low) |
				(opcode3) |
				RB(Rb) |
				RA(Ra) |
				OP4(I_FBcc), B
			);
		return;
	}
	emit_insn(
		RC(Rc) |
		RB(Rb) |
		(opcode3 + 8) |
		RA(Ra) |
		OP4(I_BRcc), B
	);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_call()
{
	int64_t opcode;
	Int128 val;
	int Ra = 0;

	opcode = parm1[token];
  NextToken();
	if (token == '[')
		Int128::Assign(&val, Int128::Zero());
	else
		val = expr128();
	if (token=='[') {
		Ra = getRegisterX();
		need(']');
	}
	if (Int128::IsEqual(&val,Int128::Zero())) {
		if (opcode==I_JMP)	// JMP [Ra]
			// jal r0,[Ra]
			emit_insn(
				RA(Ra) |
				OP4(I_JAL)
				,B
			);
		else {
				emit_insn(
					RT(regLR) |
					RA(Ra) |
					OP4(I_JAL), B
				);
		}
		return;
	}
	emit_insn(
		((val.low >> 8LL) << 10LL) |
		((val.low>>2) & 0x3f) |
		OP4(opcode), B 
	);
	return;
}

static void process_iret(int64_t op)
{
	Int128 val;
	int Ra;
	char *p;

	p = inptr;
	Ra = getRegisterX();
	if (Ra == -1) {
		Ra = 0;
		NextToken();
		if (token == '#') {
			val = expr128();
		}
		else
			inptr = p;
	}
	emit_insn(
		((val.low & 0x3FLL) << 16LL) |
		RT(0) |
		RA(Ra) | OP4(I_BMISC), B
	);
}

static void process_ret()
{
	Int128 val;
	bool ins48 = false;

  NextToken();
	Int128::Assign(&val, Int128::Zero());
	if (token=='#') {
		val = expr128();
	}
	// If too large a constant, do the SP adjustment directly.
	if (!IsNBit128(val, *Int128::MakeInt128(18LL))) {
		LoadConstant(val,54);
		// add.w r63,r63,r23
		emit_insn(
			FN6(I_ADD) |
			RT(regSP) |
			RB(54) |
			RA(regSP)
			, B
			);
		Int128::Assign(&val, Int128::Zero());
	}
	emit_insn(
		(val.low << 22LL) |
		RB(regLR) |
		RT(regSP) |
		RA(regSP) |
		OP4(I_RET), B
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
			0x00, B
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
		0x00, B
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
	case 16:	*sc = 4; break;
	case 5:	*sc = 5; break;
	case 10:	*sc = 6; break;
	case 15:	*sc = 7; break;
  default: printf("Illegal scaling factor.\r\n");
  }
}


// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// [Reg]
// [Reg+Reg]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc, int *seg, int *pp)
{
  int64_t val;
	char *p;

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
	 if (pp == (int *)NULL)
		 return;

     *disp = 0;
     *regA = -1;
	 *regB = -1;
	 *Sc = 0;
	 *seg = -1;
	 *pp = 0;
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
			 p = inptr;
			 NextToken();
			 if (token == tk_minusminus)
				 *pp = 1;
			 else
				 inptr = p;
         *regA = getRegisterX();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
				 if (token == tk_plusplus) {
					 *pp = 2;
					 NextToken();
				 }
				 if (token=='+' || token==',') {
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
// If the displacement is too large the displacment is loaded into r23.
//
// So
//    sw    r2,$12345678[r2]
// Becomes:
//		lui		r23,#$12345
//    add   r23,r23,r2
//    sw    $678[r23]
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
	int pp;
  Int128 val;
	int64_t disp;
	int64_t aq = 0, rl = 0;
	int ar;
	int64_t opcode6 = parm1[token];
	int64_t funct6 = parm2[token];
	int64_t sz = parm3[token];

	GetFPSize();
	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	if (opcode6 == I_SV)
		Rs = getVecRegister();
	else if (opcode6 == I_STFD || opcode6==I_STFS)
		Rs = getFPRegister();
	else
		Rs = getRegisterX();
	if (Rs < 0) {
    printf("Expecting a source register (%d).\r\n", lineno);
    printf("Line:%.60s\r\n",inptr);
    ScanToEOL();
    return;
  }
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg, &pp);
	if (Ra >= 0 && (Rc >= 0 || pp)) {
		if (Rc == -1)
			Rc = 0;
		emit_insn(
			FN5(funct6) |
			SC((int64_t)Sc) |
			RC(Rc) |
			RB(Rs) |
			RA(Ra) |
			RT(((disp & 0xf) << 2)|pp)|
			MOP(I_MSX), M);
		return;
	}
  if (Ra < 0) Ra = 0;
  Int128::Assign(&val, Int128::MakeInt128(disp));
	if (!IsNBit128(val,*Int128::MakeInt128(20LL))) {
		LoadConstant(val,54);
		// Change to indexed addressing
		emit_insn(
			FN5(funct6) |
			SC(0LL) |
			RC(54) |
			RB(Rs) |
			RA(Ra) |
			MOP(I_MSX), M);
		ScanToEOL();
		return;
	}
	emit_insn(
		MSI(val.low) |
		RB(Rs) |
		RA(Ra) |
		MOP(opcode6), M);
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
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi()
{
  int Ra = 0;
  int Rt;
  Int128 val;
	char *p;
	int sz = 3;

  p = inptr;
	if (*p=='.')
		getSz(&sz);
	sz &= 3;
  Rt = getRegisterX();
  expect(',');
  val = expr128();
	if (!IsNBit128(val, *Int128::MakeInt128(44LL)) && ((code_address % 16LL) == 10LL || (code_address % 16LL) == 0LL)) {
		if ((code_address % 16) == 10)
			emit_insn(0x00000000C0, B);
		emit_insn(
			OP6(I_ADDI) |
			RII(0) |
			RT(Rt) |
			RA(0), I);
		emit_insn(val.low, 0);
		emit_insn((val.high << 24LL) | ((unsigned int64_t)val.low >> 40LL), 0);
		return;
	}
	if (!IsNBit128(val, *Int128::MakeInt128(21LL))) {
		LoadConstant(val, Rt);
		return;
	}
	emit_insn(
		RII(val.low) |
		RT(Rt) |
		RA(0) |
		OP6(I_ADDI)
		,I);
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
	int pp;
  char *p;
  int64_t disp;
  Int128 val;
	int64_t aq = 0, rl = 0;
	int ar;
  int fixup = 5;
	int64_t opcode6 = parm1[token];
	int64_t funct6 = parm2[token];
	int64_t sz = parm3[token];

	GetFPSize();
	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	p = inptr;
	if (opcode6 == I_LV)
		Rt = getVecRegister();
	else if (opcode6 == I_LDFD || opcode6==I_LDFS)
		Rt = getFPRegister();
	else
		Rt = getRegisterX();
  if (Rt < 0) {
      printf("Expecting a target register (%d).\r\n", lineno);
      printf("Line:%.60s\r\n",p);
      ScanToEOL();
      inptr-=2;
      return;
  }
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg, &pp);
	if (Ra >= 0 && (Rc >= 0 || pp)) {
		//if (gpu)
		//	error("Indexed addressing not supported on GPU");
		// Trap LEA, convert to LEAX opcode
		if (Rc < 0)
			Rc = 0;
		emit_insn(
			FN5(funct6) |
			RB(((disp & 0xfLL)<<2L)|pp) |
			RC(Rc) |
			RT(Rt) |
			RA(Ra) |
			MOP(I_MLX)
			,M
		);
		return;
	}
  if (Ra < 0) Ra = 0;
    val = Int128::Convert(disp);
	if (!IsNBit128(val, *Int128::MakeInt128(20LL))) {
		LoadConstant(val, 54);
		// Change to indexed addressing
		emit_insn(
			FN5(funct6) |
			RC(54) |
			RT(Rt) |
			RA(Ra) |
			MOP(I_MLX)
			, M);
		ScanToEOL();
		return;
	}
	emit_insn(
		MLI(val.low) |
		RT(Rt) |
		RA(Ra) |
		MOP(opcode6)
		, M);
    ScanToEOL();
}

static void process_cache(int opcode6)
{
  int Ra,Rc;
	int Sc;
	int seg;
	int pp;
  char *p;
  int64_t disp;
  Int128 val;
  int fixup = 5;
	int cmd;

  p = inptr;
	NextToken();
	cmd = (int)expr() & 0x3f;
  expect(',');
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg, &pp);
	if (Ra > 0 && (Rc > 0 || pp)) {
		emit_insn(
			FN5(opcode6) |
			RC(Rc) |
			(cmd << 16) |
			RA(Ra) |
			((disp & 0xfL) << 2) | pp |
			MOP(I_MSX)
			,M);
		return;
	}
    if (Ra < 0) Ra = 0;
		Int128::Assign(&val, Int128::MakeInt128(disp));
	if (!IsNBit128(val,*Int128::MakeInt128(20LL))) {
		LoadConstant(val,54);
		// Change to indexed addressing
		emit_insn(
			FN5(opcode6) |
			RC(54) |
			(cmd << 16) |
			RA(Ra) |
			((disp & 0xfL) << 2) |
			MOP(I_MSX)
			, M);
		ScanToEOL();
		return;
	}
	emit_insn(
		MSI(val.low) |
		(cmd << 16) |
		RA(Ra) |
		MOP(opcode6), M);
    ScanToEOL();
}


static void process_lv(int opcode6)
{
}

static void process_lsfloat(int64_t opcode6, int64_t opcode3)
{
}

static void process_stfloat(int64_t opcode6, int64_t opcode3)
{
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
	Rt &= 63;
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
	Ra &= 63;
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
	 emit_insn(
		 FN5(I_MOV) |
		 OP6(1) |
		 RT(Rt) |
		 RA(Ra)
		 , I
		 );
	prevToken();
}

static void process_vmov(int opcode, int func)
{
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

static int64_t process_shop2()
{
	int64_t op2 = 0;

	inptr++;
	NextToken();
	switch (token) {
	case tk_nop:	op2 = 0x0LL; break;
	case tk_add:	op2 = 0x1LL;	break;
	case tk_and:	op2 = 0x2LL; break;
	default:	op2 = 0x0LL; break;
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
		op2 = process_shop2();
		q = inptr;
	}
	if (q[0]=='.')
		getSz(&sz);
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	val &= 63;
	if (op2) {
		need(',');
		Rc = getRegisterX();
	}
	emit_insn(
		FN6(op4) |
		FN2(op2) |
		SZ(sz) |
		RC(Rc) |
		RB(val & 0x3fLL) |
		RT(Rt) |
		RA(Ra)
		, I);
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
			FN5(I_SEI) |
			RB(val & 15) |
			RA(0) |
			OP4(I_BMISC),
			B);
	}
	else {
		emit_insn(
			FN5(I_SEI) |
			RB(0) |
			RA(Ra) |
			OP4(I_BMISC)
			, B);
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
		FN5(1) |
		(im << 16) |
		(pl << 22) |
		(tgtol << 18) |
		RA(Ra) |
		OP4(I_BMISC),
		B
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
	int sz = 3;
	int64_t op2 = 0x00LL;	// NOP

	q = p = inptr;
	SkipSpaces();
	if (p[0] == ':') {
		inptr++;
		op2 = process_op2();
		q = inptr;
	}
	if (q[0]=='.')
		getSz(&sz);
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	if (token=='#') {
		inptr = p;
		process_shifti(op4+6);
	}
	else {
		prevToken();
		Rb = getRegisterX();
		emit_insn(
			FN6(op4) | SZ(sz) |
			RT(Rt)| RB(Rb) | RA(Ra),I
		);
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
		}
		prevToken();
		Rs = getRegisterX();
		emit_insn(((val & 0xFFFLL) << 16LL) | (op << 38LL) | RA(Rs) | RT(Rd) | OP6(I_CSR),I);
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

static void process_com()
{
    int Ra;
    int Rt;
	char *p;
	int sz = 3;

	p = inptr;
	if (p[0] == '.')
		getSz(&sz);

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
	emit_insn(
		RII(-1) |
		RT(Rt) |
		RA(Ra) |
		OP6(I_XORI)
		, I
		);
	prevToken();
}

// ---------------------------------------------------------------------------
// neg r3,r3
// - alternate mnemonic for sub Rn,R0,Rn
// ---------------------------------------------------------------------------

static void process_neg()
{
  int Ra;
  int Rt;
	char *p;
	int sz = 3;

	p = inptr;
	if (p[0] == '.')
		getSz(&sz);

  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
	emit_insn(
		FN6(I_SUB) |
		RT(Rt) |
		RB(Ra) |
		RA(0)
		,I
		);
	prevToken();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_push(int64_t fn4, int64_t op6)
{
	int Ra;
	Int128 val;

	SkipSpaces();
	if (*inptr == '#') {
		inptr++;
		NextToken();
		val = expr128();
		if (!IsNBit128(val, *Int128::MakeInt128(40LL)) && ((code_address % 16LL) == 10LL || (code_address % 16LL) == 0LL)) {
			if ((code_address % 16) == 10)
				emit_insn(0x00000000C0, B);
			emit_insn(
				OP4(I_PUSHC) |
				RII(0) |
				RT(regSP) |
				RA(regSP), M);
			emit_insn(val.low, 0);
			emit_insn((val.high << 24LL) | ((unsigned int64_t)val.low >> 40LL), 0);
			return;
		}
		if (!IsNBit128(val, *Int128::MakeInt128(22LL))) {
			LoadConstant(val, 54);
			emit_insn(
				FN5(10) |
				RB(54) |
				RT(regSP) |
				RA(regSP) |
				MOP(I_PUSH)
				, M
			);
			return;
		}
		emit_insn(
			MLI(val.low) |
			RT(regSP) |
			RA(regSP) |
			OP4(I_PUSHC)
			,M
		);
		return;
	}
	Ra = getRegisterX();
	emit_insn(
		FN5(10) |
		RB(Ra) |
		RT(regSP) |
		RA(regSP) |
		MOP(I_PUSH)
		, M
	);
	prevToken();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_pop(int64_t fn4, int64_t op6)
{
	int Rd;
	Int128 val;

	SkipSpaces();
	Rd = getRegisterX();
	emit_insn(
		FN5(10) |
		RB(regSP) |
		RT(Rd) |
		RA(regSP) |
		MOP(I_POP)
		, M
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
		(cmd << 31LL) | 
		RB(Tn) |
		RT(Rt) |
		RA(Ra) |
		OP4(I_TLB)
		, B
	);
}


// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_vrrop(int funct6)
{
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_vsrrop(int funct6)
{
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
	case tk_align: process_itanium_align(); break;
	case tk_andi:  process_riop(0x08,0x08,0); break;
	case tk_asl: process_shift(I_ASL); break;
	case tk_asr: process_shift(I_ASR); break;
	case tk_bbc: process_bbc(0x141, 1); break;
	case tk_bbs: process_bbc(0x140, 0); break;
	case tk_begin_expand: expandedBlock = 1; break;
	case tk_beqi: process_beqi(0x32, 0); break;
	case tk_bfchg: process_bitfield(2); break;
	case tk_bfclr: process_bitfield(1); break;
	case tk_bfext: process_bitfield(5); break;
	case tk_bfextu: process_bitfield(6); break;
	case tk_bfins: process_bitfield(3); break;
	case tk_bfinsi: process_bitfield(4); break;
	case tk_bfset: process_bitfield(0); break;
	case tk_bnei: process_beqi(0x12, 1); break;
	case tk_bra: process_bra(0x01); break;
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
//	case tk_cli: emit_insn(0xC0000002, !expand_flag, 4); break;
	case tk_chk:  process_chk(0x34); break;
	case tk_cmovenz: process_cmove(0x29); break;
	case tk_cmovfnz: process_cmovf(0x27); break;
		//case tk_cmp:  process_rrop(0x06); break;
	//case tk_cmpi:  process_riop(0x06); break;
	//case tk_cmpu:  process_rrop(0x07); break;
	//case tk_cmpui:  process_riop(0x07); break;
	case tk_code: process_code(); break;
	case tk_com: process_com(); break;
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
//	case tk_dec:	process_inc(0x25); break;
	case tk_dh:  process_dh(); break;
	case tk_dcb:	process_db(); break;
	case tk_dct:	process_dh(); break;
	case tk_dcw:	process_dc(); break;
	case tk_dco:	process_dw(); break;
	case tk_dcp:	process_dcp(); break;
	case tk_dcd:	process_dcd(); break;
	case tk_dh_htbl:  process_dh_htbl(); break;
		//case tk_divsu:	process_rrop(0x3D, -1); break;
	case tk_divwait: process_rop(0x13); break;
	case tk_dw:  process_dw(); break;
//	case tk_end: goto j1;
	case tk_end_expand: expandedBlock = 0; break;
	case tk_endpublic: break;
	case tk_eori: process_riop(0x0A,0x0A,0); break;
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
//	case tk_inc:	process_inc(0x1A); break;
	case tk_if:		pif1 = inptr - 2; doif(); break;
	case tk_ifdef:		pif1 = inptr - 5; doifdef(); break;
	case tk_isnull: process_ptrop(0x06,0); break;
	case tk_itof: process_itof(0x15); break;
	case tk_iret:	process_iret(0xC8000002); break;
	case tk_isptr:  process_ptrop(0x06,1); break;
	case tk_jal: process_jal(I_JAL); break;
	case tk_ld:	process_ld(); break;
		//case tk_lui: process_lui(0x27); break;
	case tk_lv:  process_lv(0x36); break;
	case tk_macro:	process_macro(); break;
	case tk_memdb: emit_insn(0xCC000003C0LL, M); break;
	case tk_memsb: emit_insn(0xC4000003C0LL, M); break;
	case tk_message: process_message(); break;
	case tk_mov: process_mov(0x02, 0x22); break;
		//case tk_mulh: process_rrop(0x26, 0x3A); break;
		//case tk_muluh: process_rrop(0x24, 0x38); break;
	case tk_neg: process_neg(); break;
	case tk_nop: emit_insn(0xC0,B); break;
	case tk_not: process_rop(0x05); break;
		//        case tk_not: process_rop(0x07); break;
	case tk_ori: process_riop(0x09,0x09,0); break;
	case tk_org: 
		while (segment == codeseg && (code_address % 16) != 0) {
			emit_insn(NOP_INSN, B);
		}
		process_org();
		break;
	case tk_plus: compress_flag = 0;  expand_flag = 1; break;
	case tk_ptrdif: process_rrop(); break;
	case tk_public: process_public(); break;
	case tk_push: process_push(0x0c, 0x14); break;
	case tk_pop: process_pop(0x0c, 0x14); break;
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
//	case tk_setwb: emit_insn(0x04580002, !expand_flag, 4); break;
		//case tk_seq:	process_riop(0x1B,2); break;
	case tk_sge:	process_setop(-I_SLT, I_SGTI, 0x01); break;
	case tk_sgeu:	process_setop(-I_SLTU, I_SGTUI, 0x01); break;
	case tk_sgt:	process_setop(-I_SLE, I_SGTI, 0x00); break;
	case tk_sgtu:	process_setop(-I_SLEU, I_SGTUI, 0x00); break;
	case tk_shl: process_shift(I_SHL); break;
	case tk_shli: process_shifti(I_SHLI); break;
	case tk_shr: process_shift(I_SHR); break;
	case tk_shri: process_shifti(I_SHRI); break;
	case tk_shru: process_shift(I_SHR); break;
	case tk_shrui: process_shifti(I_SHRI); break;
	case tk_sle:	process_setop(I_SLE, I_SLTI, 0x01); break;
	case tk_sleu:	process_setop(I_SLEU, I_SLTUI, 0x01); break;
	case tk_slt:	process_setop(I_SLT, I_SLTI, 0x00); break;
	case tk_sltu:	process_setop(I_SLTU, I_SLTUI, 0x00); break;
	case tk_sne:	process_setop(I_SNE, I_SNEI, 0x01); break;
	case tk_slli: process_shifti(I_SHLI); break;
	case tk_srai: process_shifti(I_ASRI); break;
	case tk_srli: process_shifti(I_SHRI); break;
	case tk_subi:  process_riop(0x05,0x05,0x00); break;
//	case tk_sv:  process_sv(0x37); break;
	case tk_swap: process_rop(0x03); break;
		//case tk_swp:  process_storepair(0x27); break;
	case tk_sxb: process_rop(0x1A); break;
	case tk_sxc: process_rop(0x19); break;
	case tk_sxh: process_rop(0x18); break;
	case tk_sync: emit_insn(0x1000000380LL, B); break;
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
	case tk_vmov: process_vmov(0x02, 0x33); break;
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

void Itanium_processMaster()
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
		jumptbl[tk_call] = &process_call;
		parm1[tk_call] = I_CALL;
		jumptbl[tk_jmp] = &process_call;
		parm1[tk_jmp] = I_JMP;
		jumptbl[tk_add] = &process_rrop;
		parm1[tk_add] = I_ADD;
		parm2[tk_add] = I_ADDI;
		jumptbl[tk_and] = &process_rrop;
		parm1[tk_and] = I_AND;
		parm2[tk_and] = I_ANDI;
		jumptbl[tk_or] = &process_rrop;
		parm1[tk_or] = I_OR;
		parm2[tk_or] = I_ORI;
		jumptbl[tk_xor] = &process_rrop;
		parm1[tk_xor] = I_XOR;
		parm2[tk_xor] = I_XORI;
		jumptbl[tk_eor] = &process_rrop;
		parm1[tk_eor] = I_XOR;
		parm2[tk_eor] = I_XORI;
		jumptbl[tk_div] = &process_rrop;
		parm1[tk_div] = I_DIV;
		parm2[tk_div] = I_DIVI;
		parm3[tk_div] = 0x00;
		jumptbl[tk_divu] = &process_rrop;
		parm1[tk_divu] = 0x3CLL;
		parm2[tk_divu] = 0x3CLL;
		parm3[tk_divu] = 0x00;
		jumptbl[tk_fxdiv] = &process_rrop;
		parm1[tk_fxdiv] = 0x2BLL;
		parm2[tk_fxdiv] = -1LL;
		jumptbl[tk_fxmul] = &process_rrop;
		parm1[tk_fxmul] = 0x3BLL;
		parm2[tk_fxmul] = -1LL;
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
		parm1[tk_mul] = 0x20LL;
		parm2[tk_mul] = 0x20LL;
		jumptbl[tk_mulf] = &process_rrop;
		parm1[tk_mulf] = 0x0FLL;
		parm2[tk_mulf] = 0x0FLL;
		jumptbl[tk_mulu] = &process_rrop;
		parm1[tk_mulu] = 0x21LL;
		parm2[tk_mulu] = 0x21LL;
		jumptbl[tk_mulh] = &process_rrop;
		parm1[tk_mulh] = 0x00LL;
		parm2[tk_mulh] = -1LL;
		jumptbl[tk_sub] = &process_rrop;
		parm1[tk_sub] = I_SUB;
		parm2[tk_sub] = -I_ADDI;
		jumptbl[tk_ptrdif] = &process_ptrdif;
		parm1[tk_ptrdif] = 0x1ELL;
		parm2[tk_ptrdif] = -1LL;
		jumptbl[tk_transform] = &process_rrop;
		parm1[tk_transform] = 0x11LL;
		parm2[tk_transform] = -1LL;
		jumptbl[tk_xnor] = &process_rrop;
		parm1[tk_xnor] = 0x0ELL;
		parm2[tk_xnor] = -1LL;
		jumptbl[tk_band] = &process_bcc;
		parm1[tk_band] = OP4(I_BLcc) | I_BAND;
		parm2[tk_band] = I_BANDR;
		parm3[tk_band] = 12;
		jumptbl[tk_beq] = &process_bcc;
		parm1[tk_beq] = OP4(I_Bcc) | I_BEQ;
		parm2[tk_beq] = I_BEQR;
		parm3[tk_beq] = 0;
		jumptbl[tk_bge] = &process_bcc;
		parm1[tk_bge] = OP4(I_Bcc) | I_BGE;
		parm2[tk_bge] = I_BGER;
		parm3[tk_bge] = 3;
		jumptbl[tk_bgeu] = &process_bcc;
		parm1[tk_bgeu] = OP4(I_Bcc) | I_BGEU;
		parm2[tk_bgeu] = I_BGEUR;
		parm3[tk_bgeu] = 7;
		jumptbl[tk_bgt] = &process_bcc;
		parm1[tk_bgt] = OP4(I_Bcc) | I_BLT;
		parm2[tk_bgt] = -I_BLTR;
		parm3[tk_bgt] = -2;
		jumptbl[tk_bgtu] = &process_bcc;
		parm1[tk_bgtu] = OP4(I_Bcc) | I_BLTU;
		parm2[tk_bgtu] = -I_BLTUR;
		parm3[tk_bgtu] = -6;
		jumptbl[tk_ble] = &process_bcc;
		parm1[tk_ble] = OP4(I_Bcc) | I_BGE;
		parm2[tk_ble] = -I_BGER;
		parm3[tk_ble] = -3;
		jumptbl[tk_bleu] = &process_bcc;
		parm1[tk_bleu] = OP4(I_Bcc) | I_BGEU;
		parm2[tk_bleu] = -I_BGEUR;
		parm3[tk_bleu] = -7;
		jumptbl[tk_blt] = &process_bcc;
		parm1[tk_blt] = OP4(I_Bcc) | I_BLT;
		parm2[tk_blt] = I_BLTR;
		parm3[tk_blt] = 2;
		jumptbl[tk_bltu] = &process_bcc;
		parm1[tk_bltu] = OP4(I_Bcc) | I_BLTU;
		parm2[tk_bltu] = I_BLTUR;
		parm3[tk_bltu] = 6;
		jumptbl[tk_bnand] = &process_bcc;
		parm1[tk_bnand] = OP4(I_BLcc) | I_BNAND;
		parm2[tk_bnand] = I_BNANDR;
		parm3[tk_bnand] = 4;
		jumptbl[tk_bne] = &process_bcc;
		parm1[tk_bne] = OP4(I_Bcc)|I_BNE;
		parm2[tk_bne] = I_BNER;
		parm3[tk_bne] = 1;
		jumptbl[tk_bnor] = &process_bcc;
		parm1[tk_bnor] = OP4(I_BLcc) | I_BNOR;
		parm2[tk_bnor] = I_BNORR;
		parm3[tk_bnor] = 5;
		jumptbl[tk_bor] = &process_bcc;
		parm1[tk_bor] = OP4(I_BLcc) | I_BOR;
		parm2[tk_bor] = I_BORR;
		parm3[tk_bor] = 13;
		jumptbl[tk_ldi] = &process_ldi;
		parm1[tk_ldi] = 0;
		parm2[tk_ldi] = 0;
		jumptbl[tk_stb] = &process_store;
		parm1[tk_stb] = I_STB;
		parm2[tk_stb] = I_STB;
		parm3[tk_stb] = 0x0;
		jumptbl[tk_stw] = &process_store;
		parm1[tk_stw] = I_STW;
		parm2[tk_stw] = I_STW;
		parm3[tk_stw] = 0x0;
		jumptbl[tk_stp] = &process_store;
		parm1[tk_stp] = I_STP;
		parm2[tk_stp] = I_STP;
		parm3[tk_stp] = 0x0;
		jumptbl[tk_std] = &process_store;
		parm1[tk_std] = I_STD;
		parm2[tk_std] = I_STD;
		parm3[tk_std] = 0x0;
		jumptbl[tk_stt] = &process_store;
		parm1[tk_stt] = I_STT;
		parm2[tk_stt] = I_STT;
		parm3[tk_stt] = 0x0;
		jumptbl[tk_sto] = &process_store;
		parm1[tk_sto] = I_STO;
		parm2[tk_sto] = I_STO;
		parm3[tk_sto] = 0x0;
		//jumptbl[tk_stdc] = &process_store;
		//parm1[tk_stdc] = 0x17;
		//parm2[tk_stdc] = 0x23;
		//parm3[tk_stdc] = 0x00;
		jumptbl[tk_ldb] = &process_load;
		parm1[tk_ldb] = I_LDB;
		parm2[tk_ldb] = I_LDB;
		parm3[tk_ldb] = 0x0;
		jumptbl[tk_ldbu] = &process_load;
		parm1[tk_ldbu] = I_LDBU;
		parm2[tk_ldbu] = I_LDBU;
		parm3[tk_ldbu] = 0x0;
		jumptbl[tk_ldw] = &process_load;
		parm1[tk_ldw] = I_LDW;
		parm2[tk_ldw] = I_LDW;
		parm3[tk_ldw] = 0x0;
		jumptbl[tk_ldwu] = &process_load;
		parm1[tk_ldwu] = I_LDWU;
		parm2[tk_ldwu] = I_LDWU;
		parm3[tk_ldwu] = 0x0;
		jumptbl[tk_ldt] = &process_load;
		parm1[tk_ldt] = I_LDT;
		parm2[tk_ldt] = I_LDT;
		parm3[tk_ldt] = 0x0;
		jumptbl[tk_ldtu] = &process_load;
		parm1[tk_ldtu] = I_LDTU;
		parm2[tk_ldtu] = I_LDTU;
		parm3[tk_ldtu] = 0x0;
		jumptbl[tk_lea] = &process_load;
		parm1[tk_lea] = I_LEA;
		parm2[tk_lea] = I_LEA;
		parm3[tk_lea] = 0x00;
		jumptbl[tk_ldp] = &process_load;
		parm1[tk_ldp] = I_LDP;
		parm2[tk_ldp] = I_LDP;
		parm3[tk_ldp] = 0x0;
		jumptbl[tk_ldpu] = &process_load;
		parm1[tk_ldpu] = I_LDPU;
		parm2[tk_ldpu] = I_LDPU;
		parm3[tk_ldpu] = 0x0;
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
		jumptbl[tk_ldd] = &process_load;
		parm1[tk_ldd] = I_LDD;
		parm2[tk_ldd] = I_LDD;
		parm3[tk_ldd] = 0x0;
		jumptbl[tk_lddr] = &process_load;
		parm1[tk_lddr] = I_LDDR;
		parm2[tk_lddr] = I_LDDR;
		parm3[tk_lddr] = 0x0;
		jumptbl[tk_ldo] = &process_load;
		parm1[tk_ldo] = I_LDO;
		parm2[tk_ldo] = I_LDO;
		parm3[tk_ldo] = 0x0;
		jumptbl[tk_ldou] = &process_load;
		parm1[tk_ldou] = I_LDOU;
		parm2[tk_ldou] = I_LDOU;
		parm3[tk_ldou] = 0x0;
		jumptbl[tk_sf] = &process_store;
		parm1[tk_sf] = I_STFD;
		parm2[tk_sf] = I_STFD;
		parm3[tk_sf] = 0x01;
		jumptbl[tk_lf] = &process_load;
		parm1[tk_lf] = I_LDFD;
		parm2[tk_lf] = I_LDFD;
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
	ZeroMemory(&TmpUsed, sizeof(TmpUsed));
	num_lbranch = 0;
	num_insns = 0;
	num_cinsns = 0;
	num_bytes = 0;
  NextToken();
  while (token != tk_eof && token != tk_end) {
//        printf("\t%.*s\n", inptr-stptr-1, stptr);
//        printf("token=%d\r", token);
    if (expandedBlock)
      expand_flag = 1;
		(*jumptbl[token])();
    NextToken();
  }
j1:
  ;
	for (nn = 0; nn < 0x6e; nn++)
		if (!TmpUsed[nn])
			printf("%02X not used\r\n", nn);;
}

