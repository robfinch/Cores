// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
#define I_RR	0x02
#define I_MOVE	0x12
#define I_MOVO	0x13
#define I_ADD	0x04
#define I_OR	0x09
#define I_ORI	0x09
#define I_XOR		0x0A
#define I_XORI	0x0A
#define I_SHL		0x0
#define I_SHLI	0x8
#define I_ASL		0x2
#define I_ASLI	0xA
#define I_SLT		0x06
#define I_SLTU	0x07
#define I_SLTI	0x06
#define I_SLTUI	0x07
#define I_AND		0x08
#define I_ANDI	0x08
#define I_SEQ		0x0B
#define I_SEQI	0x0B
#define I_FLOAT	0x0F
#define I_FBcc	0x10
#define I_SHIFT31	0x0F
#define I_PTRDIF	0x1E
#define I_SHIFT63	0x1F
#define I_SHIFTR	0x2F
#define I_BNEI	0x12
#define I_LB	0x13
#define I_PUSHC	0x14
#define I_SB	0x15
#define I_MEMNDX	0x16
#define I_JAL		0x18
#define I_CALL	0x19
#define I_LFx		0x1B
#define I_SGTUI	0x1C
#define I_LC		0x20
#define I_LH		0x21
#define I_SGTI	0x2C
#define I_SLE		0x28
#define I_SLEU	0x29
#define I_SFx	0x2B
#define I_BBc	0x26
#define I_LUI	0x27
#define I_CMOVEZ	0x28
#define I_CMOVNZ	0x29
#define I_RET	0x29
#define I_Bcc	0x30
#define I_BEQI	0x32
#define I_LW	0x33
#define I_SH	0x35
#define I_LV	0x36
#define I_SV	0x37


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

extern int use_gp;

static int regSP = 31;
static int regFP = 30;
static int regLR = 29;
static int regXL = 28;
static int regGP = 27;
static int regTP = 26;
static int regCB = 23;
static int regCnst;

#define OPT64     0
#define OPTX32    1
#define OPTLUI0   0
#define LB16	-31653LL

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
int CmpReg(int reg)
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

static void emit_insn(int64_t oc, int can_compress, int sz)
{
	int ndx;
	int opmajor = oc & 0x3f;
	int ls;
	int cond;

	if (!iexpand(oc)) {
		switch (opmajor) {
		case I_RR:
			if ((oc >> 6) & 1) {
				switch ((oc >> 42LL) & 0x3fLL) {
				case I_CMOVNZ:
				case I_CMOVEZ:
					insnStats.cmoves++;
					break;
				}
			}
			switch ((oc >> 26LL) & 0x3fLL) {
			case I_ADD:
				insnStats.adds++;
				break;
			case I_AND:
				insnStats.ands++;
				break;
			case I_OR:
				insnStats.ors++;
				break;
			case I_XOR:
				insnStats.xors++;
				break;
			case I_MOVE:
			case I_MOVO:
				insnStats.moves++;
				break;
			case I_SLT:
			case I_SLTU:
			case I_SLE:
			case I_SLEU:
				insnStats.sets++;
				break;
			case I_SHIFT31:
			case I_SHIFT63:
			case I_SHIFTR:
				switch ((oc >> 23LL) & 7L) {
				case I_SHL:
				case I_SHLI:
				case I_ASL:
				case I_ASLI:
					insnStats.shls++;
					break;
				default:
					insnStats.shifts++;
					break;
				}
			case I_PTRDIF:
				insnStats.ptrdif++;
				break;
			}
			break;
		case I_ADD:
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
			insnStats.luis++;
			break;
		case I_SB:
		case I_SH:
		case I_SFx:
			insnStats.stores++;
			break;
		case I_LB:
		case I_LC:
		case I_LH:
		case I_LW:
		case I_LFx:
			insnStats.loads++;
			break;
		case I_PUSHC:
			insnStats.pushes++;
			break;
		case I_MEMNDX:
			ls = oc & 0x80000000LL;
			insnStats.indexed++;
			if (ls)
				insnStats.stores++;
			else
				insnStats.loads++;
			break;
		case I_BEQI:
			insnStats.beqi++;
			insnStats.branches++;
			if (sz == 6)
				num_lbranch++;
			break;
		case I_BBc:
			insnStats.bbc++;
			insnStats.branches++;
			if (sz == 6)
				num_lbranch++;
			break;
		case I_Bcc:
			cond = ((oc >> 13LL) & 7LL);
			if (cond == 4 || cond == 5)
				insnStats.logbr++;
			insnStats.branches++;
			if (sz == 6)
				num_lbranch++;
			break;
		case I_FBcc:
			cond = ((oc >> 13LL) & 7LL);
			if (cond==4 || cond==5)
				insnStats.logbr++;
			insnStats.branches++;
			if (sz == 6)
				num_lbranch++;
			break;
		case I_BNEI:
			insnStats.bnei++;
			insnStats.branches++;
			if (sz == 6)
				num_lbranch++;
			break;
		case I_CALL:
		case I_JAL:
			insnStats.calls++;
			break;
		case I_RET:
			insnStats.rets++;
			break;
		case I_SLTI:
		case I_SLTUI:
		case I_SGTI:
		case I_SGTUI:
		case I_SEQI:
			insnStats.sets++;
			break;
		case I_FLOAT:
			insnStats.floatops++;
			break;
		}
	}

	switch (sz) {
	case 6:	oc = oc & 0xffffffffffffLL;	break;// 48-bits max
	case 4:	oc = oc & 0xffffffffLL; break;
	default: oc = oc & 0xffffLL; break;
	}
	if (sz > 2) {
		if (pass == 3 && can_compress && gCanCompress) {
			for (ndx = 0; ndx < htblmax; ndx++) {
				if (oc == hTable[ndx].opcode) {
					hTable[ndx].count++;
					return;
				}
			}
			if (htblmax < 100000) {
				hTable[htblmax].opcode = oc;
				hTable[htblmax].count = 1;
				htblmax++;
				return;
			}
			error("Too many instructions");
			return;
		}
	}
	if (pass > 3) {
		if (can_compress && gCanCompress && sz > 2) {
			for (ndx = 0; ndx < min(256, htblmax); ndx++) {
				if (oc == hTable[ndx].opcode) {
					emitCode(0x2D);
					emitCode(ndx);
					num_bytes += 2;
					num_insns += 1;
					num_cinsns += 1;
					insnStats.total++;
					return;
				}
			}
		}
		if (sz==2) {
			emitCode(oc & 255);
			emitCode((oc >> 8) & 255);
			num_bytes += 2;
			num_insns += 1;
			num_cinsns += 1;
			insnStats.total++;
			return;
		}
		if (sz == 4) {
			emitCode(oc & 255);
			emitCode((oc >> 8) & 255);
			emitCode((oc >> 16) & 255);
			emitCode((oc >> 24) & 255);
			num_bytes += 4;
			num_insns += 1;
			insnStats.total++;
			return;
		}
		emitCode(oc & 255);
		emitCode((oc >> 8) & 255);
		emitCode((oc >> 16) & 255);
		emitCode((oc >> 24) & 255);
		emitCode((oc >> 32LL) & 255);
		emitCode((oc >> 40LL) & 255);
		num_bytes += 6;
		num_insns += 1;
		insnStats.total++;
	}
}
 
void LoadConstant(int64_t val, int rg)
{
	if (IsNBit(val, 13)) {
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(rg << 13) |
			0x04, !expand_flag, 4);	// ADDI (sign extends)
		return;
	}
	if (IsNBit(val, 29)) {
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(rg << 13) |
			(1 << 6) |
			0x04, !expand_flag, 6);	// ADDI
		return;
	}
	if (IsNBit(val, 48)) {
		emit_insn(
			((val >> 34LL) << 18LL) |
			(((val >> 29LL) & 0x1fLL) << 8LL) |
			(rg << 13) |
			0x27, !expand_flag, 4);	// LUI
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(rg << 13) |
			(rg << 8) |
			(1 << 6) |
			0x09, !expand_flag, 6);	// ORI (zero extends)
		return;
	}
	// Won't fit into 49 bits, assume 64 bit constant
	emit_insn(
		((val >> 34LL) << 18LL) |
		(((val >> 29LL) & 0x1fLL) << 8LL) |
		(rg << 13) |
		(1 << 6) |
		0x27, !expand_flag, 6);	// LUI
	emit_insn(
		((val >> 5LL) << 24LL) |
		((val & 0x1fLL) << 18LL) |
		(rg << 13) |
		(rg << 8) |
		(1 << 6) |
		0x09, !expand_flag, 6);	// ORI
	return;
}

static void Lui32(int64_t val, int rg)
{
	emit_insn(
		((val >> 18LL) << 18LL) |
		(((val >> 13LL) & 0x1fLL) << 8LL) |
		(rg << 13) |
		(0 << 6) |
		0x27, !expand_flag, 4
	);
}

static void Lui34(int64_t val, int rg)
{
	if (IsNBit(val, 48)) {
		emit_insn(
			((val >> 34LL) << 18LL) |
			(((val >> 29LL) & 0x1fLL) << 8LL) |
			(rg << 13) |
			(0 << 6) |
			I_LUI, !expand_flag, 4
		);
		return;
	}
	emit_insn(
		((val >> 34LL) << 18LL) |
		(((val >> 29LL) & 0x1fLL) << 8LL) |
		(rg << 13) |
		(1 << 6) |
		I_LUI, !expand_flag, 6
	);
}
		
void LoadConstant12(int64_t val, int rg)
{
	if (val & 0x800) {
		emit_insn(
			(0 << 16) |
			(rg << 11) |
			(0 << 6) |
			0x09,!expand_flag,4);	// ORI
		emit_insn(
			(val << 16) |
			(rg << 11) |
			(0 << 6) |
			(0 << 6) |
			0x1A,!expand_flag,4);	// ORQ0
	}
	else {
		emit_insn(
			(val << 16) |
			(rg << 11) |
			(0 << 6) |
			0x09,!expand_flag,4);	// ORI
	}
	val >>= 16;
	emit_insn(
		(val << 16) |
		(rg << 11) |
		(0 << 6) |
		(1 << 6) |
		0x1A,!expand_flag,4);	// ORQ1
	val >>= 16;
	if (val != 0) {
		emit_insn(
			(val << 16) |
			(rg << 11) |
			(0 << 6) |
			(2 << 6) |
			0x1A,!expand_flag,4);	// ORQ2
	}
	val >>= 16;
	if (val != 0) {
		emit_insn(
			(val << 16) |
			(rg << 11) |
			(0 << 6) |
			(3 << 6) |
			0x1A,!expand_flag,4);	// ORQ3
	}
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
  int64_t val;
	int sz = 3;
    
  p = inptr;
	if (*p == '.')
		getSz(&sz);
	Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  val = expr();
	if (opcode6==-4LL)	{ // subi
		val = -val;
		opcode6 = I_ADD;	// change to addi
	}
	// ADDI
	if (opcode6 == I_ADD && !gpu) {
		if (Ra == Rt) {
			if (Rt == regSP) {
				if (val >= -128 && val < 128 && ((val & 7) == 0)) {
					emit_insn(
						(0 << 12) |
						(((val >> 4) & 0x0F) << 8) |
						(2 << 6) |
						(((val >> 3) & 0x1) << 5) |
						regSP, 0, 2);
					goto xit;
				}
			}
			else {
				if (val >= -16 && val < 16) {
					emit_insn(
						(0 << 12) |
						(((val >> 1) & 0x0F) << 8) |
						(2 << 6) |
						((val & 0x1) << 5) |
						Ra, 0, 2);
					goto xit;
				}
			}
		}
	}
	// Compress ANDI ?
	if (opcode6 == I_AND && Ra == Rt && Ra != 0 && !gpu) {
		if (val > -16 && val < 16) {
			emit_insn(
				(2 << 12) |
				(((val >> 1) & 0x0F) << 8) |
				(2 << 6) |
				((val & 0x1) << 5) |
				Rt, 0, 2
			);
			goto xit;
		}
	}
	// Compress ORI ?
	if (opcode6 == I_OR && Ra == Rt && (Rtp = CmpReg(Ra)) >= 0 && !gpu) {
		if (val > -16 && val < 16) {
			emit_insn(
				(4 << 12) |
				(((val >> 1) & 0x0f) << 8) |
				(2 << 6) |
				(2 << 4) |
				((val & 1) << 3) |
				Rtp, 0, 2
			);
			goto xit;
		}
	}
	if (!IsNBit(val, 13)) {
		if (gpu) {
			if ((val >> 12) & 1)
				Lui32(val + 0x1000, 23);
			else
				Lui32(val, 23);
			emit_insn(
				((val >> 5LL) << 24LL) |
				((val & 0x1f) << 18) |
				(23 << 13) |
				(23 << 8) |
				(0 << 6) |
				0x04, !expand_flag, 4	// ADDI
			);
			goto xit;
		}
		if (!IsNBit(val, 29)) {
			Lui34(val, 23);
			emit_insn(
				((val >> 5LL) << 24LL) |
				((val & 0x1fLL) << 18LL) |
				(23 << 13) |
				(23 << 8) |
				(1 << 6) |
				0x09, !expand_flag, 6	// ORI
			);
			emit_insn(
				(func6 << 26LL) |
				(sz << 23) |		// set size to word size op
				(23 << 18) |
				(Rt << 13) |
				(Ra << 8) |
				0x02, !expand_flag, 4);
			goto xit;
		}
		emit_insn(
			((val >> 5LL) << 24LL) |
			(bit23 << 23LL) |
			((val & 0x1fLL) << 18LL) |
			(Rt << 13) |
			(Ra << 8) |
			(1 << 6) |
			opcode6, !expand_flag, 6);
		goto xit;
	}
	emit_insn(
		((val >> 5LL) << 24LL) |
		(bit23 << 23LL) |
		((val & 0x1fLL) << 18LL) |
		(Rt << 13) |
		(Ra << 8) |
		opcode6,!expand_flag,4);
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
	int64_t val;

	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	if (!IsNBit(val, 29)) {
		LoadConstant(val, 23);
		switch (opcode6)
		{
		case I_SLTI:
		case I_SLTUI:
			emit_insn(
				(func6 << 26) |	// SLT / SLTU
				(3 << 23) |
				(Rt << 18) |
				(23 << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02, !expand_flag, 4);
			return;
		case I_SGTI:	// SGTI, SGEI
			emit_insn(
				((bit23 ? I_SLT : I_SLE) << 26) |	// SLE (0x28)
				(3 << 23) |
				(Rt << 18) |
				(23 << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02,!expand_flag,4)
				;
			emit_insn(
				(0x01 << 26) |
				(3 << 23) |
				(3 << 18) |		// COM
				(Rt << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02,!expand_flag,4
			);
			return;
		case I_SGTUI:	// SGTUI
			emit_insn(
				((bit23 ? I_SLTU : I_SLEU) << 26) |	// SLEU	0x29
				(3 << 23) |
				(Rt << 18) |
				(23 << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02, !expand_flag, 4)
				;
			emit_insn(
				(0x01 << 26) |
				(3 << 23) |
				(3 << 18) |		// COM
				(Rt << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02, !expand_flag, 4
			);
			return;
		}
		error("Illegal set immediate instruction");
		return;
	}
	if (!IsNBit(val, 13)) {
		emit_insn(
			((val >> 5LL) << 24LL) |
			(bit23 << 23LL) |
			((val & 0x1fLL) << 18) |
			(Rt << 13) | (Ra << 8) |
			(1 << 6) |
			opcode6, !expand_flag,6);
		return;
	}
	emit_insn(
		((val >> 5LL) << 24LL) |
		(bit23 << 23LL) |
		((val & 0x1fLL) << 18)|
		(Rt << 13)|
		(Ra << 8)|
		opcode6,!expand_flag,4);
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
		if (opcode6 < 0) {
			inptr = q;
			val = expr();
			LoadConstant(val, 23);
			emit_insn(
				(funct6 << 26) |
				(3 << 23) |
				(23 << 18) |
				(Rt << 13) |
				(Ra << 8) |
				(0 << 6) |
				0x02, !expand_flag, 4
			);
			return;
		}
		// The following ops will be complemented
		if (opcode6 == I_SGTI)
			funct6 = I_SLE;
		else if (opcode6 == I_SGTUI)
			funct6 = I_SLEU;
		process_setiop(opcode6, funct6, bit23);
		return;
	}
	switch (funct6)
	{
	case -I_SLT:	// SGE = !SLT
	case -I_SLTU:	// SGEU	= !SLTU
		emit_insn(
			(-funct6 << 26) |
			(sz << 23) |
			(Rb << 18) |
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		emit_insn(
			(1 << 26) |
			(sz << 23) |
			(3 << 18) |	// COM
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		return;
	case -I_SLE:	// SGT = !SLE
		emit_insn(
			(0x28 << 26) |
			(sz << 23) |
			(Rb << 18) |
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		emit_insn(
			(1 << 26) |
			(sz << 23) |
			(3 << 18) |	// COM
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		return;
	case -I_SLEU:	// SGTU	= !SLEU
		emit_insn(
			(0x29 << 26) |
			(sz << 23) |
			(Rb << 18) |
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		emit_insn(
			(1 << 26) |
			(sz << 23) |
			(3 << 18) |	// COM
			(Rt << 13) |
			(Ra << 8) |
			(0 << 6) |
			0x02, !expand_flag, 4
		);
		return;
	}
	emit_insn(
		(funct6 << 26) |
		(sz << 23) |
		(Rb << 18) |
		(Rt << 13) |
		(Ra << 8) |
		(0 << 6) |
		0x02, !expand_flag, 4
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

	instr = 0LL;
  p = inptr;
	// fxdiv, transform
	// - check for writeback indicator
	if (gpu && (funct6 == 0x2B || funct6 == 0x11)) {
		if (*p == '.') {
			if (p[1] == 'w' || p[1] == 'W') {	// .wr or .write
				instr = (1 << 25);
				p++;
				NextToken();
			}
			else if (p[1] == 's' || p[1] == 'S') {	// .st or .start
				p++;
				NextToken();
			}
		}
	}
	if (*p=='.')
		getSz(&sz);
  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  if (token=='#') {
	if (iop < 0 && iop!=-4)
		error("Immediate mode not supported");
		//printf("Insn:%d\n", token);
    inptr = p;
    process_riop(iop,funct6,bit23);
    return;
  }
  prevToken();
  Rb = getRegisterX();
	// Compress ADD
	if (funct6 == 0x04 && Ra == Rt && !gpu) {
		emit_insn(
			(1 << 12) |
			(((Ra >> 1) & 0xF) << 8) |
			(3 << 6) |
			((Ra & 1) << 5) |
			(Rt),
			0,2
		);
		goto xit;
	}
	// Compress SUB
	if (funct6 == 0x05 && Ra == Rt && (Rtp = CmpReg(Rt)) >= 0 && (Rbp = CmpReg(Rb)) >= 0 && !gpu) {
		emit_insn(
			(4 << 12) |
			(0 << 10) |
			(((Rbp >> 1) & 0x3) << 8) |
			(2 << 6) |
			(3 << 4) |
			((Rbp & 1) << 3) |
			(Rtp),
			0, 2
		);
		goto xit;
	}
	// Compress AND
	if (funct6 == 0x08 && Ra == Rt && (Rtp = CmpReg(Rt)) >= 0 && (Rbp = CmpReg(Rb)) >= 0 && !gpu) {
		emit_insn(
			(4 << 12) |
			(1 << 10) |
			(((Rbp >> 1) & 0x3) << 8) |
			(2 << 6) |
			(3 << 4) |
			((Rbp & 1) << 3) |
			(Rtp),
			0, 2
		);
		goto xit;
	}
	// Compress OR
	if (funct6 == 0x09 && Ra == Rt && (Rtp = CmpReg(Rt)) >= 0 && (Rbp = CmpReg(Rb)) >= 0 && !gpu) {
		emit_insn(
			(4 << 12) |
			(2 << 10) |
			(((Rbp >> 1) & 0x3) << 8) |
			(2 << 6) |
			(3 << 4) |
			((Rbp & 1) << 3) |
			(Rtp),
			0, 2
		);
		goto xit;
	}
	// Compress XOR
	if (funct6 == 0x0A && Ra == Rt && (Rtp = CmpReg(Rt)) >= 0 && (Rbp = CmpReg(Rb)) >= 0 && !gpu) {
		emit_insn(
			(4 << 12) |
			(3 << 10) |
			(((Rbp >> 1) & 0x3) << 8) |
			(2 << 6) |
			(3 << 4) |
			((Rbp & 1) << 3) |
			(Rtp),
			0, 2
		);
		goto xit;
	}
	//prevToken();
	//if (funct6==0x2E || funct6==0x2C || funct6==0x2D) {
	//	funct6 += 0x10;	// change to divmod
	//    emit_insn((funct6<<26LL)||(1<<23)||(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
	//	goto xit;
	//}
	if (funct6==0x3C || funct6==0x3D || funct6==0x3E) {
	    emit_insn((funct6<<26LL)||(0<<23)|(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
			goto xit;
	}
    emit_insn(instr | (funct6<<26LL)|(sz << 23)|(Rb<<18)|(Rt<<13)|(Ra<<8)|0x02,!expand_flag,4);
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
	emit_insn(instr | (funct6 << 26LL) | (sc << 23) | (Rb << 18) | (Rt << 13) | (Ra << 8) | 0x02, !expand_flag, 4);
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
	emit_insn((funct6 << 34LL) | (sz << 24) | (Rt << 27) | (Rc << 18) | (Rb << 12) | (Ra << 6) | 0x42, !expand_flag, 5);
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
				(23 << 23) |
				(Rb << 18) |
				(Rt << 13) |
				(Ra << 8) |
				(1 << 6) |
				0x02, !expand_flag, 6);
			return;
		}
		emit_insn(
			(funct6 << 42LL) |
			(4LL << 39LL) |
			((val & 0xffffLL) << 23LL) |
			(Rb << 18) |
			(Rt << 13) |
			(Ra << 8) |
			(1 << 6) |
			0x02, !expand_flag, 6);
		return;
	}
	prevToken();
	Rc = getRegisterX();
	emit_insn(
		(funct6 << 42LL) |
		(0LL << 39LL) |
		(Rc << 23) |
		(Rb << 18) |
		(Rt << 13) |
		(Ra << 8) |
		(1 << 6) |
		0x02, !expand_flag, 6);
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
	emit_insn((funct6 << 42LL) | (Rt << 23) | (Rc << 18) | (Rb << 13) | (Ra << 8) | (1 << 6) | 0x02, !expand_flag, 6);
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
		emit_insn((Ra << 8) | (Rt << 13) | 0x18, 0, 4);
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
	if (IsNBit(val, 14)) {
		emit_insn(
			(val << 18) |
			(Rt << 13) |
			(Ra << 8) |
			0x18, !expand_flag, 4);
		goto xit;
	}
	if (IsNBit(val, 30)) {
		emit_insn(
			(val << 18) |
			(Rt << 13) |
			(Ra << 8) |
			(1 << 6) |
			0x18, !expand_flag, 6);
		goto xit;
	}

	{
		LoadConstant(val, 23);
		if (Ra != 0) {
			// add r23,r23,Ra
			emit_insn(
				(0x04LL << 26LL) |
				(3 << 23) |
				(23 << 18) |
				(23 << 13) |
				(Ra << 8) |
				0x02, 0, 4
			);
			// jal Rt,r23
			emit_insn(
				(0 << 18) |
				(Rt << 12) |
				(23 << 8) | 0x18, !expand_flag, 4);
			goto xit;
		}
		emit_insn(
			(Rt << 12) |
			(23 << 8) | 0x18, !expand_flag, 4);
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
			(Rt << 23) |
			(0 << 13) |
			(Ra << 8) |
			0x0F, !expand_flag, 6
		);
		return;
	}
    emit_insn(
			(oc << 26LL) |
			(rm << 23) |
			(Rt << 18)|
			(0 << 13)|
			(Ra << 8) |
			0x0F,!expand_flag,4
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
			(Rt << 23) |
			(0 << 13) |
			(Ra << 8) |
			0x0F, !expand_flag, 6
		);
		return;
	}
  emit_insn(
		(oc << 26LL) |
		(rm << 23LL)|
		(Rt << 18)|
		(0 << 13)|
		(Ra << 8) |
		0x0F,!expand_flag,4
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
			(Rt << 23) |
			(0 << 13) |
			(Ra << 8) |
			0x0F, !expand_flag, 6
		);
		return;
	}
	emit_insn(
		(oc << 26LL) |
		(rm << 23LL) |
		(Rt << 18) |
		(0 << 13) |
		(Ra << 8) |
		0x0F, !expand_flag, 4
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
			(Rt << 23) |
			(Rb << 13) |
			(Ra << 8) |
			(1 << 6) |
			0x0F, !expand_flag, 6
		);
		return;
	}

    emit_insn(
			(oc << 26LL)|
			(rm << 23LL)|
			(Rt << 18)|
			(Rb << 13)|
			(Ra << 8) |
			0x0F,!expand_flag,4
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
		(oc << 12) |
		(Ra << 6) |
		0x36,!expand_flag,5
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
		(1LL << 26LL) |
		(sz << 23) |
		(oc << 18) |
		(Rt << 13) |
		(Ra << 8) |
		0x02,!expand_flag,4
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
		(Rt << 13) |
		(Ra << 8) |
		0x02, !expand_flag, 4
	);
	prevToken();
}

// ---------------------------------------------------------------------------
// beqi r2,#123,label
// ---------------------------------------------------------------------------

static void process_beqi(int64_t opcode6, int64_t opcode3)
{
  int Ra, pred = 0;
  int64_t val, imm;
  int64_t disp;
	int sz = 3;
	int ins48 = 0;
	char *p;

	p = inptr;
	if (*p == '.')
		getSz(&sz);

	Ra = getRegisterX();
	need(',');
	NextToken();
	imm = expr();
	need(',');
	NextToken();
	val = expr();
	if (!IsNBit(imm,8LL)) {
		//printf("Branch immediate too large: %d %I64d", lineno, imm);
		LoadConstant(imm, 23LL);
		disp = (val - code_address) >> 1LL;
		if (!IsNBit(disp, 11LL)) {
			ins48 = !gpu;
			if (!IsNBit(disp, 27LL) || gpu) {
				if (pass > 4)
					error("BEQI Branch target too far away");
			}
			return;
		}
		emit_insn(
			((disp >> 2) << 23LL) |
			((disp & 3LL) << 16LL) |
			(23 << 18) |
			(opcode3 << 14) |
			(Ra << 8) |
			(ins48 << 6) |
			0x30, !expand_flag, ins48 ? 6 : 4
		);
		return;
	}
	disp = (val - code_address) >> 1LL;
	if (!IsNBit(disp, 11LL)) {
		ins48 = !gpu;
		if (!IsNBit(disp, 27LL) || gpu) {
			if (pass > 4)
				error("BEQI Branch target too far away");
		}
		return;
	}
	emit_insn(
		((disp >> 2) << 23LL) |
		((disp & 3LL) << 16LL) |
		(((imm >> 3LL) & 0x1FLL) << 18LL) |
		((imm & 7LL) << 13LL) |
		(Ra << 8) |
		(ins48 << 6) |
		opcode6,!expand_flag,ins48 ? 6 : 4
	);
	return;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
int InvertBranchOpcode(int opcode4)
{
	switch (opcode4) {
	case 0:	return (1);	// BEQ to BNE
	case 1:	return (0);	// BNE to BEQ
	default:	return (opcode4);	// Otherwise operands are swapped.
	}
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
	int fmt;
	int64_t val, ca4, ca2;
	int64_t disp;
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
		process_beqi(0x32, 0);
		return;
	}
	inptr = p2;
	Rc = getRegisterX();
	if (Rc == -1) {
		inptr = p2;
		val = expr();
	}
	else
		val = 0;
	if (Rc == -1) {
		ca4 = (code_address + 4LL);
		ca2 = (code_address + 2LL);
		disp = (val - code_address) >> 1LL;
		if (!IsNBit(disp, 11LL)) {
			ins48 = !gpu;
			if (!IsNBit(disp, 27LL) || gpu) {
				if (pass > 4)
					error("Branch target too far away");
			}
		}
		encode = (val >> 7LL) == (ca2 >> 7LL);
		encode = 0;	// for now no compressed branches
		encode = IsNBit(disp, 7);
		// Check for compressed bnez
		if (opcode4 == 1 && Rb == 0 && encode && !gpu) {
			emit_insn(
				(3 << 14) |
				(((disp >> 1) & 0x3f) << 8) |
				(2 << 6) |
				((disp & 1) << 5) |
				Ra, 0, 2
			);
			return;
		}
		// compressed beqz
		if (opcode4 == 0 && Rb == 0 && encode && !gpu) {
			emit_insn(
				(2 << 14) |
				(((disp >> 1) & 0x3f) << 8) |
				(2 << 6) |
				((disp & 1) << 5) |
				Ra, 0, 2
			);
			return;
		}
	}
	// Negative opcode indicates to swap operands.
	if (opcode4 < 0) {
		opcode4 = -opcode4;
		if (Rc == -1) {
			emit_insn(
				((disp >> 2) << 23LL) |
				(Ra << 18) |
				((disp & 3LL) << 16LL) |
				(opcode4 << 13) |
				(Rb << 8) |
				(ins48 << 6) |
				opcode6, !expand_flag, ins48 ? 6 : 4
			);
			return;
		}
		emit_insn(
			(Rc << 23) |
			(Rb << 18) |
			(op4 << 13) |
			(Ra << 8) |
			0x11, !expand_flag, 4);
		return;
	}
	if (Rc < 0) {
		emit_insn(
			((disp >> 2) << 23LL) |
			(Rb << 18) |
			((disp & 3LL) << 16LL) |
			(opcode4 << 13) |
			(Ra << 8) |
			(ins48 << 6) |
			opcode6, !expand_flag, ins48 ? 6 : 4
		);
		return;
	}
	emit_insn(
		(Rc << 23) |
		(Rb << 18) |
		(op4 << 13) |
		(Ra << 8) |
		0x11, !expand_flag, 4);
	return;
}

// ---------------------------------------------------------------------------
// dbnz r1,label
//
// ---------------------------------------------------------------------------

static void process_dbnz(int opcode6, int opcode3)
{
  int Ra, Rc, pred;
  int64_t val;
  int64_t disp, offset;
	char *p1;
	int sz = 3;
	int ins48 = 0;
	char *p;

	p = inptr;
	if (*p == '.')
		getSz(&sz);

	pred = 3;		// default: statically predict as always taken
	p1 = inptr;
    Ra = getRegisterX();
    need(',');
	p = inptr;
	if (Rc==-1) {
		inptr = p;
	  NextToken();
		val = expr();
		disp = (val >> 8LL) - ((code_address) >> 8LL);
		offset = val & 0xffLL;
		if (!IsNBit(disp, 4LL)) {
			disp = (val >> 8LL) - ((code_address) >> 8LL);
			ins48 = 1;
			if (!IsNBit(disp, 20LL)) {
				printf("Branch displacement (%llX-%llX=%llX) too large %d.\n", val, code_address, disp, lineno);
			}
		}
		emit_insn(
			(disp << 28LL) |
			((offset >> 3LL) << 23LL) |
			(((offset >> 1LL) & 3LL) << 16LL) |
			((opcode3 & 3) << 13) |
			(Ra << 8) |
			(ins48 << 6) |
			opcode6, !expand_flag, ins48 ? 6 : 4
		);
		return;
	}
	error("dbnz: target must be a label");
	emit_insn(
		(opcode3 << 19) |
		(0 << 13) |
		(Ra << 8) |
		opcode6,!expand_flag,4
	);
}

// ---------------------------------------------------------------------------
// ibne r1,r2,label
//
// ---------------------------------------------------------------------------

static void process_bbc(int opcode6, int opcode3)
{
  int Ra, Rc, pred;
	int64_t bitno;
  int64_t val;
  int64_t disp;
	char *p1;
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
	if (Rc==-1) {
		inptr = p;
    NextToken();
		val = expr();
		disp = (val - code_address) >> 1;
		if (!IsNBit(disp, 11LL)) {
			isn48 = !gpu;
			if (!IsNBit(disp, 27LL) || gpu) {
				if (pass > 4)
					error("BBC/BBS Branch target too far away");
			}
		}
	  emit_insn(
			((disp >> 2) << 23LL) |
			((disp & 3LL) << 16LL) |
			((bitno >> 1) << 18) |
			((bitno & 1) << 15) |
			((opcode3 & 3) << 13) |
			(Ra << 8) |
			(isn48 << 6) |
			opcode6, !expand_flag, isn48 ? 6 : 4
		);
		return;
	}
	error("ibne: target must be a label");
	emit_insn(
		(opcode3 << 19) |
		(0 << 13) |
		(Ra << 8) |
		0x03,!expand_flag,4
	);
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
	if (op == 4) {
		need(',');
		NextToken();
		val = expr();
		gval = true;
	}
	if (op == 3) {
		need(',');
		Ra = getRegisterX();
	}
	op =
		(oc << 44LL) |
		((gval?1LL:0LL) << 43LL) |
		((gme?1LL:0LL) << 42LL) |
		((gmb?1:0) << 41LL) |
		(Rt << 18LL) |
		(1 << 6) |
		0x22;
	if (oc == 3) {
		op |= ((mb & 63LL) << 34LL);
		op |= (Ra << 8);
	}
	else if (gmb)
		op |= ((mb & 31LL) << 8LL) | (((mb >> 5LL) & 1LL) << 39LL);
	else
		op |= (Ra << 8);
	if (gme)
		op |= ((me & 31LL) << 18LL) | (((me >> 5LL) & 1LL) << 40LL);
	else
		op |= (Rb << 18);
	if (gval) {
		if (oc==4)
			op |= ((val & 0x7ffLL) << 28LL) | (Rc << 23LL);
		else
			op |= ((val & 0xffffLL) << 23LL);
	}
	else
		op |= (Rc << 23);

	emit_insn(op, 0, 6);
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
  disp = (val - code_address) >> 1LL;
	if (disp > -512 && disp < 512 && !gpu) {	// disp+1 accounts for instruction size of 2 not 4
		emit_insn(
			(7 << 12) |
			(((disp >> 6) & 0xf) << 8) |
			(2 << 6) |
			(disp & 0x3f), 0, 2
		);
		return;
	}
	if (!IsNBit(disp, 11LL)) {
		ins48 = !gpu;
		if (!IsNBit(disp, 27LL) || gpu) {
			if (pass > 4)
				error("Bra target too far away");
		}
	}
	emit_insn(
		((disp >> 2) << 23LL) |
		((disp & 3LL) << 16LL) |
		(ins48 << 6) |
    0x30,!expand_flag,ins48 ? 6 : 4
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
	emit_insn(((disp >> 3) & 0x3FF) << 22 |
		(Rc << 16) |
		(Rb << 11) |
		(Ra << 6) |
		((disp >> 2) & 1) |
		opcode6,!expand_flag,4
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
	if (val < LB16 || val > 32767LL) {
		emit_insn((0x8000 << 16)|(Rb << 11)|(Ra << 6)|opcode6,!expand_flag,2);
		emit_insn(val,!expand_flag,2);
		return;
	}
	emit_insn(((val & 0xFFFF) << 16)|(Rb << 11)|(Ra << 6)|opcode6,!expand_flag,2);
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
			((disp & 3LL) << 16LL) |
			(opcode3 << 13) |
			(Rb << 18) |
			(Ra << 8) |
			((ins48 ? 1 : 0) << 6) |
			0x05, !expand_flag, ins48 ? 6 : 4
		);
		return;
	}
	emit_insn(
		(Rc << 23) |
		(Rb << 18) |
		((opcode3 + 8) << 13) |
		(Ra << 8) |
	0x11,!expand_flag, 4);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_call(int opcode)
{
	int64_t val;
	int Ra = 0;

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
		if (opcode==0x28)	// JMP [Ra]
			// jal r0,[Ra]
			emit_insn(
				(Ra << 8) |
				0x18,!expand_flag,4
			);
		else {
			if (gpu) {
				emit_insn(
					(29 << 13) |
					(Ra << 8) |
					0x18,!expand_flag,4
				);
			}
			// jal lr,[Ra]	- call [Ra]
			//emit_insn(
			//	(29 << 13) |
			//	(Ra << 8) |
			//	0x18,!expand_flag,4
			//);
			else {
				emit_insn(
					(2 << 12) |
					(((29 >> 1) & 0xf) << 8) |
					(3 << 6) |
					((29 & 1) << 5) |
					Ra, 0, 2
				);
			}
		}
		return;
	}
	if (code_bits > 27 && !IsNBit(val,40)) {
		LoadConstant(val,23);
		if (Ra!=0) {
			// add r23,r23,Ra
			emit_insn(
				(0x04 << 26) |
				(23 << 18) |
				(23 << 13) |
				(Ra << 8) |
				0x02,!expand_flag,4
				);
		}
		if (opcode==0x28)	// JMP
			// jal r0,[r23]
			emit_insn(
				(23 << 8) |
				0x18,!expand_flag,4
				);
		else
			// jal lr,[r23]	- call [r23]
			emit_insn(
				(29 << 13) |
				(23 << 8) |
				0x18,!expand_flag,4
				);
		return;
	}
	if (!IsNBit(val, 23) & !gpu) {
		emit_insn(
			(((val & 0xFFFFFFFFFFLL)) << 8) |
			(1 << 6) |
			opcode, !expand_flag, 6
		);
		return;
	}
	emit_insn(
		(((val & 0xFFFFFFLL)) << 8) |
		opcode,!expand_flag,4
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
		(0 << 13) |
		(Ra << 8) |
		op,!expand_flag,4
	);
}

static void process_ret()
{
	int64_t val = 0;
	bool ins48 = false;

  NextToken();
	if (token=='#') {
		val = expr();
	}
	// Compress ?
	if (val >= 0 && val < 256 && !gpu) {
		emit_insn(
			(2 << 12) |
			(((val >> 4) & 0x0F) << 8) |
			(2 << 6) |
			(((val >> 3) & 1) << 5),
			0, 2
		);
		return;
	}
	// If too large a constant, do the SP adjustment directly.
	if (!IsNBit(val,28) && !gpu) {
		LoadConstant(val,23);
		// add.w r63,r63,r23
		emit_insn(
			(0x04LL << 26LL) |
			(3 << 23) |
			(regSP << 18) |
			(23 << 13) |
			(regSP << 8) |
			0x02,!expand_flag,4
			);
		val = 0;
	}
	ins48 = !IsNBit(val, 12) && !gpu;
	if (gpu && !IsNBit(val, 12))
		error("RET: stack pointer adjustment too large.");
	emit_insn(
		((val >> 3) << 23LL) |
		(regLR << 18) |
		(regSP << 13) |
		(regSP << 8) |
		(ins48 << 6) |
		0x29,!expand_flag, ins48 ? 6 : 4
	);
}

// ----------------------------------------------------------------------------
// inc -8[bp],#1
// ----------------------------------------------------------------------------

static void process_inc(int64_t oc)
{
    int Ra;
    int Rb;
	int Sc;
	int seg;
    int64_t incamt;
    int64_t disp;
    char *p;
    int fixup = 5;
    int neg = 0;

	if (oc == 0x25) neg = 1;
	NextToken();
    p = inptr;
    mem_operand(&disp, &Ra, &Rb, &Sc, &seg);
    incamt = 1;
	if (token==']')
       NextToken();
    if (token==',') {
        NextToken();
        incamt = expr();
        prevToken();
    }
	if (neg) incamt = -incamt;
	if (Rb >= 0) {
       if (disp != 0)
           error("displacement not allowed with indexed addressing");
       oc = 0x1A;  // INCX
	   // ToDo: fix this
       emit_insn(
		   (oc << 26LL) |
		   (0 << 23) |		// Sc = 0
		   (incamt << 18) |
		   (23 << 13) |
		   (Ra << 8) |
		   0x16, !expand_flag, 4
	   );
       return;
    }
    oc = 0x1A;        // INC
    if (Ra < 0) Ra = 0;
	incamt &= 31;
	if (!IsNBit(disp, 30)) {
		LoadConstant(disp, 23);
		// Change to indexed addressing
		emit_insn(
			(oc << 26LL) |
			(0 << 23) |		// Sc = 0
			(incamt << 18) |
			(23 << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);
		ScanToEOL();
		return;
	}
	if (!IsNBit(disp, 14)) {
		emit_insn(
			(disp << 18LL) |
			(incamt << 13) |
			(Ra << 8) |
			(1 << 6) |
			oc, !expand_flag, 6);
		ScanToEOL();
		return;
	}
	emit_insn(
		(disp << 18LL) |
		(incamt << 13) |
		(Ra << 8) |
		oc, !expand_flag, 4);
	ScanToEOL();
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
			0x00, !expand_flag, 4
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
	emit_insn(
		(user << 26) |
		((inc & 31) << 21) |
		(1 << 16) |
		((Ra & 0x1fLL) << 8) |
		0x00, !expand_flag, 4
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
  int64_t disp,val;
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
	else if (opcode6 == I_SFx)
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
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg);
	if (Ra >= 0 && Rc >= 0) {
		emit_insn(
//			((int64_t)seg << 45LL) |
			((funct6 >> 2) << 28) |
			((funct6 & 3) << 16) |
			(Sc << 13) |
			(Rc << 23) |
			(Rs << 18) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg == -1 ? 4 : 6);
		return;
	}
  if (Ra < 0) Ra = 0;
  val = disp;
	if (Ra == 55)
		val -= program_address;
	if (opcode6==I_SH && sz == 1 && Ra == regSP && !gpu) {
		if ((val & 7) == 0) {
			if (val >= -128 && val < 128) {
				emit_insn(
					(((val >> 4) & 0x0F) << 8) |
					(9 << 12) |
					(3 << 6) |
					(((val >> 3) & 0x1) << 5) |
					Rs, 0, 2
				);
				ScanToEOL();
				return;
			}
		}
	}
	if (opcode6==I_SH && sz == 1 && Ra == regFP && !gpu) {
		if ((val & 7) == 0) {
			if (val >= -128 && val < 128) {
				emit_insn(
					(((val >> 4) & 0x0F) << 8) |
					(11 << 12) |
					(3 << 6) |
					(((val >> 3) & 0x1) << 5) |
					Rs, 0, 2
				);
				ScanToEOL();
				return;
			}
		}
	}
	if (!IsNBit(val,29) && !gpu) {
		LoadConstant(val,23);
		// Change to indexed addressing
		emit_insn(
//			((int64_t)seg << 45LL) |
			((funct6 >> 2) << 28) |
			((funct6 & 3) << 16) |
			(23 << 23) |
			(0 << 13) |		// Sc
			(Rs << 18) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg == -1 ? 4 : 6);
		ScanToEOL();
		return;
	}
	if (!IsNBit(val, 13)) {
		if (gpu) {
			if (val & 0x1000)
				Lui32(val + 0x1000, 23);
			else
				Lui32(val, 23);
			emit_insn(
				(0x04 << 26) |
				(7 << 23) |
				(23 << 18) |
				(23 << 13) |
				(Ra << 8) |
				0x02, 0, 4
			);
			emit_insn(
				((val >> 5LL) << 24LL) |
				(sz << 23LL) |
				(Rs << 18) |
				((val & 0x1fLL) << 13LL) |
				(23 << 8) |
				opcode6, !expand_flag, 4);
			ScanToEOL();
			return;
		}
		else {
			if (seg == -1) {
				if (Ra >= 30)
					seg = 3;
				else
					seg = 1;
			}
			emit_insn(
//				((int64_t)seg << 45LL) |
				(((val >> 5LL)) << 24LL) |
				(sz << 23LL) |
				(Rs << 18) |
				((val & 0x1fLL) << 13LL) |
				(Ra << 8) |
				(1 << 6) |
				opcode6, !expand_flag, 6);
			ScanToEOL();
			return;
		}
	}
	emit_insn(
		((val >> 5LL) << 24LL) |
		(sz << 23LL) |
		(Rs << 18) |
		((val & 0x1fLL) << 13LL) |
		(Ra << 8) |
		opcode6,!expand_flag,4);
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
			0x02,!expand_flag,5);
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
		opcode6,!expand_flag,5);
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

  p = inptr;
	if (*p=='.')
		getSz(&sz);
	sz &= 3;
  Rt = getRegisterX();
  expect(',');
  val = expr();
	if (IsNBit(val, 5) && Rt != 0 && !gpu) {
		emit_insn(
			(1 << 12) |
			(((val >> 1) & 0x0f) << 8)|
			(2 << 6) |
			((val & 1) << 5) |
			Rt,
			!expand_flag,2
		);
		return;
	}
	if (IsNBit(val, 13)) {
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(Rt << 13) |
			(0 << 8) |		// ADDI
			I_ADD, !expand_flag, 4);
		return;
	}
	else if (gpu) {
		if ((val >> 12) & 1)
			Lui32(val + 0x1000, 23);
		else
			Lui32(val, 23);
		emit_insn(
			(val << 18) |
			(Rt << 13) |
			(23 << 8) |
			(0 << 6) |
			I_ADD, !expand_flag, 4	// ADDI
		);
		return;
	}
	if (IsNBit(val, 29)) {
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(Rt << 13) |
			(0 << 8) |		// ADDI
			(1 << 6) |
			I_ADD, !expand_flag, 6);
		return;
	}
	if (IsNBit(val, 48)) {
		emit_insn(
			((val >> 34LL) << 18LL) |
			(((val >> 29LL) & 0x1fLL) << 8LL) |
			(Rt << 13) |
			(0 << 6) |
			I_LUI, !expand_flag, 4
		);
		emit_insn(
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(Rt << 13) |
			(Rt << 8) |		// ORI
			(1 << 6) |
			I_ORI, !expand_flag, 6);
		return;
	}
	// 64 bit constant
	emit_insn(
		((val >> 34LL) << 18LL) |
		(((val >> 29LL) & 0x1fLL) << 8LL) |
		(Rt << 13) |
		(1 << 6) |
		I_LUI, !expand_flag, 6
	);
	emit_insn(
		((val >> 5LL) << 24LL) |
		((val & 0x1fLL) << 18LL) |
		(Rt << 13) |
		(Rt << 8) |		// ORI
		(1 << 6) |
		I_ORI, !expand_flag, 6);
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

	GetFPSize();
	GetArBits(&aq, &rl);
	ar = (int)((aq << 1LL) | rl);
	p = inptr;
	if (opcode6 == I_LV)
		Rt = getVecRegister();
	else if (opcode6 == I_LFx)
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
  mem_operand(&disp, &Ra, &Rc, &Sc, &seg);
	if (Ra >= 0 && Rc >= 0) {
		//if (gpu)
		//	error("Indexed addressing not supported on GPU");
		// Trap LEA, convert to LEAX opcode
		emit_insn(
//			((int64_t)seg << 45LL) |
			((funct6 >> 2) << 28LL) |
			(Rc << 23) |
			((funct6 & 3) << 21) |
			(Sc << 18) |
			(Rt << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg != -1 ? 6 : 4);
		return;
	}
  if (Ra < 0) Ra = 0;
    val = disp;
	if (Ra == 55)
		val -= program_address;
	if (opcode6==I_LW && sz == 0 && Ra == regSP && !gpu) {
		if ((val & 7) == 0) {
			if (val >= -128 && val < 128) {
				emit_insn(
					(((val >> 4) & 0x0F) << 8) |
					(5 << 12) |
					(3 << 6) |
					(((val >> 3) & 0x1) << 5) |
					Rt, 0, 2
				);
				ScanToEOL();
				return;
			}
		}
	}
	if (opcode6==I_LW && sz == 0 && Ra == regFP && !gpu) {
		if ((val & 7) == 0) {
			if (val >= -128 && val < 128) {
				emit_insn(
					(((val >> 4) & 0x0F) << 8) |
					(7 << 12) |
					(3 << 6) |
					(((val >> 3) & 0x1) << 5) |
					Rt, 0, 2
				);
				ScanToEOL();
				return;
			}
		}
	}
	if (!IsNBit(val, 29) && !gpu) {
		LoadConstant(val, 23);
		// Change to indexed addressing
		emit_insn(
//			((int64_t)seg << 45LL) |
			((funct6 >>2) << 28LL) |
			(23 << 23) |
			((funct6 & 3) << 21) |
			(0 << 18) |		// Sc = 0
			(Rt << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg == -1 ? 4 : 6);
		ScanToEOL();
		return;
	}
	if (opcode6 < 0)
		error("Load: displacement mode not supported");
	if (!IsNBit(val, 13)) {
		if (gpu) {
			if (val & 0x1000)
				Lui32(val + 0x1000, 23);
			else
				Lui32(val, 23);
			emit_insn(
				(0x04 << 26) |
				(23 << 18) |
				(23 << 13) |
				(Ra << 8) |
				0x02,0,4
			);
			emit_insn(
				((val | abs(sz)) << 18LL) |
				(Rt << 13) |
				(23 << 8) |
				opcode6, !expand_flag, 4);
			ScanToEOL();
			return;
		}
		else {
			if (seg == -1) {
				if (Ra >= 30)
					seg = 3;
				else
					seg = 1;
			}
			emit_insn(
//				((int64_t)seg << 45LL) |
				((val >> 5) << 24LL) |
				(sz << 23LL) |
				((val & 0x1fLL) << 18LL) |
				(Rt << 13) |
				(Ra << 8) |
				(1 << 6) |
				opcode6, !expand_flag, 6);
			ScanToEOL();
			return;
		}
	}
	emit_insn(
		((val >> 5) << 24LL) |
		(sz << 23LL) |
		((val & 0x1fLL) << 18LL) |
		(Rt << 13) |
		(Ra << 8) |
		opcode6,!expand_flag,4);
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
//			(((int64_t)seg) << 45LL) |
			((opcode6 >> 2) << 28) |
			(Rc << 23) |
			((opcode6 & 3) << 21) |
			(Sc << 18) |
			(cmd << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg == -1 ? 4 : 6);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	if (!IsNBit(val,29)) {
		LoadConstant(val,23);
		// Change to indexed addressing
		emit_insn(
//			(((int64_t)seg) << 45LL) |
			((opcode6 >> 2) << 26) |
			(23 << 23) |
			((opcode6 & 3) << 21) |
			(Sc << 18) |
			(cmd << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);// seg == -1 ? 4 : 6);
		ScanToEOL();
		return;
	}
	if (!IsNBit(val, 13)) {
		if (seg == -1) {
			if (Ra >= 30)
				seg = 3;
			else
				seg = 1;
		}
		emit_insn(
//			(((int64_t)seg) << 45LL) |
			((val >> 5LL) << 24LL) |
			((val & 0x1fLL) << 18LL) |
			(cmd << 13) |
			(Ra << 8) |
			(1 << 6) |
			opcode6, !expand_flag, 6);
		return;
	}
	emit_insn(
		((val >> 5LL) << 24LL) |
		((val & 0x1fLL) << 18LL) |
		(cmd << 13) |
		(Ra << 8) |
		opcode6,!expand_flag,4);
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
			0x02,!expand_flag,4);
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
			opcode6,!expand_flag,4);
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
			0x02,!expand_flag,4
		);
	emit_insn(
		(Vt << 11) |
		(23 << 6) |
		opcode6,!expand_flag,4);
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
			(Rb << 13) |
			(Ra << 8) |
			0x16,!expand_flag,4);
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
			(Ra << 8) |
			0x02, !expand_flag, 4);
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
			(Rt << 13) |
			(Ra << 8) |
			(1 << 6) |
			opcode6, !expand_flag, 6);
		ScanToEOL();
		return;
	}
	emit_insn(
		(val << 18LL) |
		(Rt << 13) |
		(Ra << 8) |
		opcode6, !expand_flag, 4);
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
			(Rb << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4);
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
			(Ra << 8) |
			0x02, !expand_flag, 4);
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
			(Rt << 13) |
			(Ra << 8) |
			(1 << 6) |
			opcode6, !expand_flag, 6);
		ScanToEOL();
		return;
	}
	emit_insn(
		(val << 18LL) |
		(Rt << 13) |
		(Ra << 8) |
		opcode6, !expand_flag, 4);
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
		0x19,0,1
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
			 (Rt << 12) |
			 (Ra << 6) |
			 0x01,!expand_flag,5
		 );
		 return;
	 }
	 else if (vec==2) {
		 emit_insn(
			 (0x33LL << 34LL) |
			 (0x01LL << 28LL) |
			 (Rt << 12) |
			 (Ra << 6) |
			 0x01,!expand_flag,5
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
			 (Ra),
		 0,2);
		 prevToken();
		 return;
	 }
	 emit_insn(
		 (fn << 26LL) |	// fn should be even
		 (((rgs >> 5) & 1) << 26) |
		 (d3 << 23LL) |
		 (rgs << 18) |
		 (Rt << 13) |
		 (Ra << 8) |
		 oc,!expand_flag,4
		 );
	prevToken();
}

static void process_vmov(int opcode, int func)
{
	int Vt, Va;
	int Rt, Ra;

	Vt = getVecRegister();
	if (Vt < 0x20) {
		Rt = getRegisterX();
		if (Rt < 0) {
			printf("Illegal register in vmov (%d)\n", lineno);
			ScanToEOL();
			return;
		}
		Va = getVecRegister();
		if (Va < 0x20) {
			printf("Illegal register in vmov (%d)\n", lineno);
			ScanToEOL();
			return;
		}
		emit_insn(
			(func << 26) |
			(1 << 21) |
			((Rt & 0x1f) << 11) |
			((Va & 0x1F) << 6) |
			opcode,!expand_flag,4
			);
		return;
	}
	need(',');
	Ra = getRegisterX();
	if (Ra < 0) {
		printf("Illegal register in vmov (%d)\n", lineno);
		ScanToEOL();
		return;
	}
	emit_insn(
		(func << 26) |
		((Vt & 0x1f) << 11) |
		(Ra << 6) |
		opcode,!expand_flag,4
		);
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
	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	val &= 63;
	if (val < 32 && op4 == 0 && Rt==Ra && !gpu && op2==0 && sz==3) {
		emit_insn(
			(3 << 12) |
			(((val >> 1) & 0x0f) << 8) |
			(2 << 6) |
			((val & 1) << 5) |
			Rt,0,2
		);
		return;
	}
	if (val > 31)
		func6 += 0x10;
	if (sz != 3 || op2 != 0) {
		if (op2 != 0) {
			need(',');
			Rc = getRegisterX();
		}
		emit_insn(
			(0x2FLL << 42LL) |
			(op2 << 36LL) |
			(op4 << 33LL) |
			((int64_t)sz << 30LL) |
			(1LL << 29LL) |	// immediate
			(((val >> 5) & 1) << 28LL) |
			(Rc << 23LL) |
			((val & 0x1f) << 18LL) |
			(Rt << 13LL) |
			(Ra << 8LL) |
			(1LL << 6LL) |
			0x02, !expand_flag, 6
		);
		return;
	}
	emit_insn(
		(func6 << 26LL) |
		(op4 << 23LL) |
		((val & 0x1fLL) << 18LL) |
		(Rt << 13) |
		(Ra << 8) |
		0x02,!expand_flag,4);
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
			((val & 7) << 18) |
			(0 << 8),
			!expand_flag,4);
	}
	else {
		emit_insn(
			0xC0000002LL |
			(0 << 18) |
			(Ra << 8),
			!expand_flag,4);
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
	emit_insn(
		(im << 24) |
		(pl << 16) |
		(tgtol << 11) |
		(Ra << 6) |
		0x0D,!expand_flag,4
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
	int func6 = 0x2f;
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
		process_shifti(op4);
	}
	else {
		prevToken();
		Rb = getRegisterX();
		if (sz != 3 || op2 != 0x00) {
			if (op2 != 0x00) {
				need(',');
				Rc = getRegisterX();
			}
			emit_insn(
				(0x2FLL << 42LL) |
				(op2 << 36LL) |
				(op4 << 33LL) |
				((int64_t)sz << 30LL) |
				(0LL << 29LL) |	// register
				(0LL << 28LL) |
				(Rc << 23LL) |
				(Rb << 18LL) |
				(Rt << 13LL) |
				(Ra << 8LL) |
				(1LL << 6LL) |
				0x02, !expand_flag, 6
			);
			return;
		}
		emit_insn((func6 << 26) | (op4 << 23) | (Rt << 18)| (Rb << 12) | (Ra << 8) | 0x02,!expand_flag,4);
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
				emit_insn((val << 18) | (op << 16) | (0x10 << 6) | (Rd << 11) | 0x05,0,2);
				emit_insn(val2,0,2);
				return;
			}
			emit_insn((val << 18) | (op << 16) | ((val2 & 0x1f) << 6) | (Rd << 11) | 0x05,!expand_flag,2);
			return;
		}
		prevToken();
		Rs = getRegisterX();
		emit_insn(((val & 0x3FFLL) << 18LL) | (op << 30LL) | (Rs << 8) | (Rd << 13) | 0x05,!expand_flag,4);
		prevToken();
		return;
		}
	printf("Illegal CSR instruction.\r\n");
	return;
	inptr = p;
	Rc = getRegisterX();
	need(',');
	NextToken();
	if (token=='#') {
		val2 = expr();
		if (val2 < -15LL || val2 > 15LL) {
			emit_insn((0x0F << 26) | (op << 21) | (Rd << 16) | (0x10 << 6) | (Rc << 11) | 0x0C,0,2);
			emit_insn(val2,0,2);
			return;
		}
		emit_insn((0x0F << 26) | (op << 21) | (Rd << 16) | ((val2 & 0x1f) << 6) | (Rc << 11) | 0x0C,!expand_flag,2);
		return;
	}
	prevToken();
	Rs = getRegisterX();
	emit_insn((0x3F << 26) | (op << 21) | (Rd << 16) | (Rc << 11) | (Rs << 6) | 0x0C,!expand_flag,2);
	prevToken();
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
		(0xFFFFFLL << 20) |
		(sz << 18) |
		(Rt << 12) |
		(Ra << 6) |
		0x0A,!expand_flag,5
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
		(1 << 26) |
		(sz << 23) |
		(7 << 18) |
		(Rt << 13) |
		(Ra << 8) |
		(0 << 6) |
		0x02,!expand_flag,4
		);
	prevToken();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_push(int64_t fn4, int64_t op6)
{
	int Ra;
	int64_t val;

	SkipSpaces();
	if (*inptr == '#') {
		inptr++;
		NextToken();
		val = expr();
		if (!IsNBit(val, 14)) {
			if (!IsNBit(val, 30)) {
				Lui34(val, 23);
				emit_insn(
					(val << 18LL) |
					(23 << 13) |
					(23 << 8) |
					(1 << 6) |
					0x09, !expand_flag, 6	// ORI
				);
				emit_insn(
					(fn4 << 28LL) |
					(23 << 18) |
					(31 << 13) |
					(31 << 8) |
					0x16, !expand_flag, 4
				);
				return;
			}
			emit_insn(
				(val << 18LL) |
				(31 << 13) |
				(31 << 8) |
				(1 << 6) |
				op6, !expand_flag, 6
			);
			return;
		}
		emit_insn(
			(val << 18LL) |
			(31 << 13) |
			(31 << 8) |
			(0 << 6) |
			op6, !expand_flag, 4
		);
		return;
	}
	Ra = getRegisterX();
	if (gpu) {
		emit_insn(
			(fn4 << 28LL) |
			(31 << 18) |
			(31 << 13) |
			(Ra << 8) |
			0x16, !expand_flag, 4
		);
		prevToken();
		return;
	}
	emit_insn(
		(3 << 12) |
		(0 << 8) |
		(3 << 6) |
		Ra, !expand_flag, 2
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
		(Tn << 18) |
		(Rt << 13) |
		(Ra << 8) |
		0x02,!expand_flag,4
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
    emit_insn((funct6<<26)|(Vm<<23)|(sz << 21)|(Vt<<16)|(Vb<<11)|(Va<<6)|0x01,!expand_flag,4);
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
    emit_insn((funct6<<26)|(Vm<<23)|(sz << 21)|(Vt<<16)|(Rb<<11)|(Va<<6)|0x01,!expand_flag,4);
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

void process_default()
{
	switch (token) {
	case tk_eol: ProcessEOL(1); break;
		//        case tk_add:  process_add(); break;
		//		case tk_abs:  process_rop(0x04); break;
	case tk_abs: process_rop(0x01); break;
	case tk_addi: process_riop(0x04,0x04,0); break;
	case tk_align: process_align(); break;
	case tk_andi:  process_riop(0x08,0x08,0); break;
	case tk_asl: process_shift(0x2); break;
	case tk_asr: process_shift(0x3); break;
	case tk_bbc: process_bbc(0x26, 1); break;
	case tk_bbs: process_bbc(0x26, 0); break;
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
	case tk_call:  process_call(0x19); break;
	case tk_cli: emit_insn(0xC0000002, !expand_flag, 4); break;
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
	case tk_dec:	process_inc(0x25); break;
	case tk_dh:  process_dh(); break;
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
	case tk_inc:	process_inc(0x1A); break;
	case tk_if:		pif1 = inptr - 2; doif(); break;
	case tk_ifdef:		pif1 = inptr - 5; doifdef(); break;
	case tk_isnull: process_ptrop(0x06,0); break;
	case tk_itof: process_itof(0x15); break;
	case tk_iret:	process_iret(0xC8000002); break;
	case tk_isptr:  process_ptrop(0x06,1); break;
	case tk_jal: process_jal(0x18); break;
	case tk_jmp: process_call(0x28); break;
	case tk_ld:	process_ld(); break;
		//case tk_lui: process_lui(0x27); break;
	case tk_lv:  process_lv(0x36); break;
	case tk_macro:	process_macro(); break;
	case tk_memdb: emit_insn(0x04400002, !expand_flag, 4); break;
	case tk_memsb: emit_insn(0x04440002, !expand_flag, 4); break;
	case tk_message: process_message(); break;
	case tk_mov: process_mov(0x02, 0x22); break;
		//case tk_mulh: process_rrop(0x26, 0x3A); break;
		//case tk_muluh: process_rrop(0x24, 0x38); break;
	case tk_neg: process_neg(); break;
	case tk_nop: emit_insn(0x0080, !expand_flag, 2); break;
	case tk_not: process_rop(0x05); break;
		//        case tk_not: process_rop(0x07); break;
	case tk_ori: process_riop(0x09,0x09,0); break;
	case tk_org: process_org(); break;
	case tk_plus: compress_flag = 0;  expand_flag = 1; break;
	case tk_ptrdif: process_rrop(); break;
	case tk_public: process_public(); break;
	case tk_push: process_push(0x0c, 0x14); break;
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
	case tk_rol: process_shift(0x4); break;
	case tk_roli: process_shifti(0x4); break;
	case tk_ror: process_shift(0x5); break;
	case tk_rori: process_shifti(0x5); break;
	case tk_rti: process_iret(0xC8000002); break;
	case tk_sei: process_sei(); break;
	case tk_seq:	process_setop(I_SEQ, I_SEQ, 0x00); break;
	case tk_setwb: emit_insn(0x04580002, !expand_flag, 4); break;
		//case tk_seq:	process_riop(0x1B,2); break;
	case tk_sge:	process_setop(-I_SLT, I_SGTI, 0x01); break;
	case tk_sgeu:	process_setop(-I_SLTU, I_SGTUI, 0x01); break;
	case tk_sgt:	process_setop(-I_SLE, I_SGTI, 0x00); break;
	case tk_sgtu:	process_setop(-I_SLEU, I_SGTUI, 0x00); break;
	case tk_shl: process_shift(0x0); break;
	case tk_shli: process_shifti(0x0); break;
	case tk_shr: process_shift(0x1); break;
	case tk_shri: process_shifti(0x1); break;
	case tk_shru: process_shift(0x1); break;
	case tk_shrui: process_shifti(0x1); break;
	case tk_sle:	process_setop(I_SLE, I_SLTI, 0x01); break;
	case tk_sleu:	process_setop(I_SLEU, I_SLTUI, 0x01); break;
	case tk_slt:	process_setop(I_SLT, I_SLTI, 0x00); break;
	case tk_sltu:	process_setop(I_SLTU, I_SLTUI, 0x00); break;
	case tk_sne:	process_setop(-I_SEQ, I_SEQI, 0x01); break;
	case tk_slli: process_shifti(0x8); break;
	case tk_srai: process_shifti(0xB); break;
	case tk_srli: process_shifti(0x9); break;
	case tk_subi:  process_riop(0x05,0x05,0x00); break;
	case tk_sv:  process_sv(0x37); break;
	case tk_swap: process_rop(0x03); break;
		//case tk_swp:  process_storepair(0x27); break;
	case tk_sxb: process_rop(0x1A); break;
	case tk_sxc: process_rop(0x19); break;
	case tk_sxh: process_rop(0x18); break;
	case tk_sync: emit_insn(0x04480002, !expand_flag, 4); break;
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

void FT64_processMaster()
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
		parm1[tk_add] = 0x04LL;
		parm2[tk_add] = 0x04LL;
		jumptbl[tk_and] = &process_rrop;
		parm1[tk_and] = 0x08LL;
		parm2[tk_and] = 0x08LL;
		jumptbl[tk_or] = &process_rrop;
		parm1[tk_or] = 0x09LL;
		parm2[tk_or] = 0x09LL;
		jumptbl[tk_xor] = &process_rrop;
		parm1[tk_xor] = 0x0ALL;
		parm2[tk_xor] = 0x0ALL;
		jumptbl[tk_eor] = &process_rrop;
		parm1[tk_eor] = 0x0ALL;
		parm2[tk_eor] = 0x0ALL;
		jumptbl[tk_div] = &process_rrop;
		parm1[tk_div] = 0x3ELL;
		parm2[tk_div] = 0x3ELL;
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
		parm1[tk_mul] = 0x3ALL;
		parm2[tk_mul] = 0x3ALL;
		jumptbl[tk_mulf] = &process_rrop;
		parm1[tk_mulf] = 0x2ALL;
		parm2[tk_mulf] = 0x2ALL;
		jumptbl[tk_mulu] = &process_rrop;
		parm1[tk_mulu] = 0x38LL;
		parm2[tk_mulu] = 0x38LL;
		jumptbl[tk_sub] = &process_rrop;
		parm1[tk_sub] = 0x05LL;
		parm2[tk_sub] = -0x04LL;
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
		parm1[tk_band] = 0x10;
		parm2[tk_band] = 4;
		parm3[tk_band] = 12;
		jumptbl[tk_beq] = &process_bcc;
		parm1[tk_beq] = 0x30;
		parm2[tk_beq] = 0;
		parm3[tk_beq] = 0;
		jumptbl[tk_bge] = &process_bcc;
		parm1[tk_bge] = 0x30;
		parm2[tk_bge] = 3;
		parm3[tk_bge] = 3;
		jumptbl[tk_bgeu] = &process_bcc;
		parm1[tk_bgeu] = 0x30;
		parm2[tk_bgeu] = 7;
		parm3[tk_bgeu] = 7;
		jumptbl[tk_bgt] = &process_bcc;
		parm1[tk_bgt] = 0x30;
		parm2[tk_bgt] = -2;
		parm3[tk_bgt] = -2;
		jumptbl[tk_bgtu] = &process_bcc;
		parm1[tk_bgtu] = 0x30;
		parm2[tk_bgtu] = -6;
		parm3[tk_bgtu] = -6;
		jumptbl[tk_ble] = &process_bcc;
		parm1[tk_ble] = 0x30;
		parm2[tk_ble] = -3;
		parm3[tk_ble] = -3;
		jumptbl[tk_bleu] = &process_bcc;
		parm1[tk_bleu] = 0x30;
		parm2[tk_bleu] = -7;
		parm3[tk_bleu] = -7;
		jumptbl[tk_blt] = &process_bcc;
		parm1[tk_blt] = 0x30;
		parm2[tk_blt] = 2;
		parm3[tk_blt] = 2;
		jumptbl[tk_bltu] = &process_bcc;
		parm1[tk_bltu] = 0x30;
		parm2[tk_bltu] = 6;
		parm3[tk_bltu] = 6;
		jumptbl[tk_bnand] = &process_bcc;
		parm1[tk_bnand] = 0x30;
		parm2[tk_bnand] = 4;
		parm3[tk_bnand] = 4;
		jumptbl[tk_bne] = &process_bcc;
		parm1[tk_bne] = 0x30;
		parm2[tk_bne] = 1;
		parm3[tk_bne] = 1;
		jumptbl[tk_bnor] = &process_bcc;
		parm1[tk_bnor] = 0x30;
		parm2[tk_bnor] = 5;
		parm3[tk_bnor] = 5;
		jumptbl[tk_bor] = &process_bcc;
		parm1[tk_bor] = 0x10;
		parm2[tk_bor] = 5;
		parm3[tk_bor] = 13;
		jumptbl[tk_ldi] = &process_ldi;
		parm1[tk_ldi] = 0;
		parm2[tk_ldi] = 0;
		jumptbl[tk_sb] = &process_store;
		parm1[tk_sb] = 0x15;
		parm2[tk_sb] = 0x20;
		parm3[tk_sb] = 0x00;
		jumptbl[tk_sc] = &process_store;
		parm1[tk_sc] = 0x15;
		parm2[tk_sc] = 0x24;
		parm3[tk_sc] = 0x01;
		jumptbl[tk_sh] = &process_store;
		parm1[tk_sh] = 0x35;
		parm2[tk_sh] = 0x21;
		parm3[tk_sh] = 0x00;
		jumptbl[tk_sw] = &process_store;
		parm1[tk_sw] = 0x35;
		parm2[tk_sw] = 0x22;
		parm3[tk_sw] = 0x01;
		jumptbl[tk_swc] = &process_store;
		parm1[tk_swc] = 0x17;
		parm2[tk_swc] = 0x23;
		parm3[tk_swc] = 0x00;
		jumptbl[tk_lb] = &process_load;
		parm1[tk_lb] = 0x13;
		parm2[tk_lb] = 0x13;
		parm3[tk_lb] = 0x00;
		jumptbl[tk_lbu] = &process_load;
		parm1[tk_lbu] = 0x13;
		parm2[tk_lbu] = 0x0A;
		parm3[tk_lbu] = 0x01;
		jumptbl[tk_lc] = &process_load;
		parm1[tk_lc] = 0x20;
		parm2[tk_lc] = 0x08;
		parm3[tk_lc] = 0x00;
		jumptbl[tk_lcu] = &process_load;
		parm1[tk_lcu] = 0x20;
		parm2[tk_lcu] = 0x09;
		parm3[tk_lcu] = 0x01;
		jumptbl[tk_lea] = &process_load;
		parm1[tk_lea] = 0x0E;
		parm2[tk_lea] = 0x18;
		parm3[tk_lea] = 0x00;
		jumptbl[tk_lh] = &process_load;
		parm1[tk_lh] = 0x21;
		parm2[tk_lh] = 0x10;
		parm3[tk_lh] = 0x00;
		jumptbl[tk_lhu] = &process_load;
		parm1[tk_lhu] = 0x21;
		parm2[tk_lhu] = 0x11;
		parm3[tk_lhu] = 0x01;
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
		jumptbl[tk_lw] = &process_load;
		parm1[tk_lw] = 0x33;
		parm2[tk_lw] = 0x12;
		parm3[tk_lw] = 0x00;
		jumptbl[tk_lwr] = &process_load;
		parm1[tk_lwr] = 0x33;
		parm2[tk_lwr] = 0x14;
		parm3[tk_lwr] = 0x01;
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

