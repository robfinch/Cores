// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// A64 - Assembler
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
#include "DSD9.h"

static void process_shifti(int oc, int funct3, int funct7);
static void ProcessEOL(int opt);
extern void process_message();
static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc);

extern bool bGenListing;
extern int first_rodata;
extern int first_data;
extern int first_bss;
extern int htable[100000];
extern int htblcnt[100000];
extern int htblmax;
extern int pass;
__int8 bytebuf[80];	// size of a cache line

static int64_t ca;
static char *lptr;
DSD9_Section cs;

extern int use_gp;

#define OPT64     0
#define OPTX32    1
#define OPTLUI0   0
#define LB16	-31653LL
#define IMAX20	524287LL
#define IMIN20	-524288LL

// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// Parses pretty register names like SP or BP in addition to r1,r2,etc.
// ----------------------------------------------------------------------------

static int getRegisterX()
{
    int reg;

    while(isspace(*inptr)) inptr++;
    switch(*inptr) {
    case 'r': case 'R':
        if ((inptr[1]=='a' || inptr[1]=='A') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 29;
        }
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
         else return -1;
    case 'a': case 'A':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0' + 18;
             if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return reg;
             }
         }
         else return -1;
    case 'b': case 'B':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 59;
        }
        break;
    case 'f': case 'F':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 59;
        }
        break;
    case 'g': case 'G':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 57;
        }
        break;
    case 'p': case 'P':
        if ((inptr[1]=='C' || inptr[1]=='c') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 63;
        }
        break;
    case 's': case 'S':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 63;
        }
        break;
    case 't': case 'T':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0' + 26;
             if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return reg;
             }
         }
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 56;
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
            return 55;
        }
        break;
	// xlr
    case 'x': case 'X':
        if ((inptr[1]=='L' || inptr[1]=='l') && (inptr[2]=='R' || inptr[2]=='r') && 
			!isIdentChar(inptr[3])) {
            inptr += 3;
            NextToken();
            return 58;
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
// Get the friendly name of a special purpose register.
// ----------------------------------------------------------------------------

static int DSD9_getSprRegister()
{
    int reg;
    int pr;

    while(isspace(*inptr)) inptr++;
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

// ---------------------------------------------------------------------------
// Process the size specifier for a FP instruction.
// ---------------------------------------------------------------------------
static int GetFPSize()
{
	int sz;

    sz = 'q';
    if (*inptr=='.') {
        inptr++;
        if (strchr("sdtqSDTQ",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal float size.\r\n");
    }
	switch(sz) {
	case 's':	sz = 0; break;
	case 'd':	sz = 2; break;
	case 't':	sz = 2; break;
	case 'q':	sz = 3; break;
	default:	sz = 3; break;
	}
	return (sz);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int64_t oc, int can_compress, int sz)
{
    int ndx;
	static __int8 bbndx = 0;

    if (pass==3 && can_compress && gCanCompress) {
       for (ndx = 0; ndx < htblmax; ndx++) {
         if ((int)oc == hTable[ndx].opcode) {
           hTable[ndx].count++;
           return;
         }
       }
       if (htblmax < 100000) {
          hTable[htblmax].opcode = (int)oc;
          hTable[htblmax].count = 1;
          htblmax++;
          return;  
       }
       printf("Too many instructions.\r\n");
       return;
    }
    if (pass > 3) {
     if (can_compress && gCanCompress) {
       for (ndx = 0; ndx < htblmax; ndx++) {
         if ((int)oc == hTable[ndx].opcode) {
           emitCode((ndx << 6)|0x1F);
		   num_bytes += 2;
		   num_insns += 1;
           return;
         }
       }
     }
	}
	emitCode(oc&0xFF);
	if (sz>1)
		emitCode((oc >> 8) & 0xff);
	if (sz>2)
		emitCode((oc >> 16) & 0xff);
	if (sz>3)
		emitCode((oc >> 24) & 0xff);
	if (sz>4)
		emitCode((oc >> 32) & 0xff);
	if ((code_address & 15)==15)
		emitCode(0x00);

	//cs.Add(oc,sz,lptr);
	/*
	 if (bbndx > 80) {
		 for (nn = 0; nn < bbndx >> 1; nn++)
			 emitCode(bytebuf[nn]);
		 bbndx &= 1;
		 memmove(&bytebuf[0], &bytebuf[bbndx>>1], (bbndx>>1) + 1);
		 memset(&bytebuf[bbndx>>1],0,sizeof(bytebuf-(bbndx>>1)));
	 }
		if (bbndx & 1) {
			switch(sz) {
			case 1:
					bytebuf[bbndx>>2] |= ((oc & 0xF) << 4);
					bbndx += 1;
					bytebuf[bbndx>>2] = (oc >> 4);
					bbndx += 2;
					bytebuf[bbndx>>2] = (oc >> 12);
					bbndx += 2;
					break;
			case 2:
					bytebuf[bbndx>>2] |= ((oc & 0xF) << 4);
					bbndx += 1;
					bytebuf[bbndx>>2] = (oc >> 4);
					bbndx += 2;
					bytebuf[bbndx>>2] = (oc >> 12);
					bbndx += 2;
					bytebuf[bbndx>>2] = (oc >> 20);
					bbndx += 2;
					bytebuf[bbndx>>2] = (oc >> 28);
					bbndx += 2;
					bytebuf[bbndx>>2] = (oc >> 36);
					bbndx += 1;
					break;
			}
		}
		else {
			switch(sz) {
			case 1:
				bytebuf[bbndx>>2] = (oc & 0x255);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 8);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 16) & 0xF;
				bbndx += 1;
				break;
			case 2:
				bytebuf[bbndx>>2] = (oc & 0x255);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 8);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 16);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 24);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 32);
				bbndx += 2;
				bytebuf[bbndx>>2] = (oc >> 40);
				bbndx += 2;
				break;
			}
		}
		*/
	num_bytes += sz;
    num_insns += 1;
}
 
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit40(Int128 cd)
{
	emitChar(cd.low & 65535LL);
	emitChar((cd.low >> 16) & 65535LL);
	emitByte(cd.high & 255LL);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit80(Int128 cd)
{
	emitChar(cd.low & 65535LL);
	emitChar((cd.low >> 16) & 65535LL);
	emitChar((cd.low >> 32) & 65535LL);
	emitChar((cd.low >> 48) & 65535LL);
	emitChar(cd.high & 65535LL);
}

// ---------------------------------------------------------------------------
// Emit postfix constant extension for initial eight bit constant.
// ---------------------------------------------------------------------------

static void emit_postfix8(int64_t val)
{
	if (val < -127 || val > 127) {
		emit_insn(((val >> 12)<<8)|0xC0|((val >> 8)&0xF),0,5);
		return;
	}
	if (val < -0x7FFFFFFFFFFLL || val > 0x7FFFFFFFFFF) {
		emit_insn(((val >> 48)<<8)|0xC0|((val >> 44)&0xF),0,5);
		return;
	}
}

// ---------------------------------------------------------------------------
// Emit postfix constant extension for initial twenty bit constant.
// ---------------------------------------------------------------------------

static void emit_postfix20(int64_t val)
{
	if (val < IMIN20 || val > IMAX20) {
		emit_insn(((val >> 24)<<8)|0xC0|((val >> 20)&0xF),0,5);
		return;
	}
	if (val < -0x7FFFFFFFFFFFFFLL || val > 0x7FFFFFFFFFFFFFLL) {
		emit_insn(((val >> 60)<<8)|0xC0|((val >> 56)&0xF),0,5);
		return;
	}
}

// ---------------------------------------------------------------------------
// addi r1,r2,#1234
// ---------------------------------------------------------------------------

static void process_riop(int opcode6)
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
	if (opcode6==0x07)	{ // subi
		val = -val;
		opcode6 = 0x04;	// change to addi
	}
	/*
	if (opcode6==0x04) {
		if (Rt == Ra) {
			if (val > -512 && val < 511) {
				emit_insn(((val & 0x3FF) << 14)|(Rt<<8)|0x31,0,5);
				return;
			}
		}
	}
	*/
	emit_insn(((val & 0xFFFFFLL) << 20)|(Rt << 14)|(Ra << 8)|opcode6,0,5);
	emit_postfix20(val);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_rrop(int funct6)
{
    int Ra,Rb,Rt;
    char *p;

    p = inptr;
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    if (token=='#') {
        inptr = p;
        process_riop(funct6);
        return;
    }
    prevToken();
    Rb = getRegisterX();
    //prevToken();
    emit_insn(((__int64)funct6<<32)|(Rt<<20)|(Rb<<14)|(Ra<<8)|0x02,!expand_flag,5);
}
       
// ---------------------------------------------------------------------------
// jmp main
// jsr [r19]
// jmp (tbl,r2)
// jsr [gp+r20]
// ---------------------------------------------------------------------------

static void process_jal(int oc)
{
    int64_t addr;
    int Ra;
    int Rt;
    
	Ra = 0;
    Rt = 0;
    NextToken();
    if (token=='(' || token=='[') {
j1:
       Ra = getRegisterX();
       if (Ra==-1) {
           printf("Expecting a register\r\n");
           return;
       }
       // Simple jmp [Rn]
       else {
            if (token != ')' && token!=']')
                printf("Missing close bracket\r\n");
            emit_insn((Ra << 8)|(Rt<<14)|0x40,0,5);
            return;
       }
    }
    prevToken();
    Rt = getRegisterX();
    if (Rt >= 0) {
        need(',');
        NextToken();
        // jal Rt,[Ra]
        if (token=='(' || token=='[')
           goto j1;
    }
    else
        Rt = 0;
	addr = expr();
    // d(Rn)? 
    NextToken();
    if (token=='(' || token=='[') {
        Ra = getRegisterX();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
		if (Ra==31)	// program counter relative ?
			addr -= code_address;
	}

	emit_insn((addr << 20) | (Rt << 14) | (Ra << 8) | 0x40,0,5);
	emit_postfix20(addr);
}

// ---------------------------------------------------------------------------
// fabs.d fp1,fp2[,rm]
// ---------------------------------------------------------------------------

static void process_fprop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int fmt;
    int rm;

    rm = 0;
    fmt = GetFPSize();
    p = inptr;
    if (oc==0x06)        // fcmp
        Rt = getRegisterX();
    else
        Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    if (token==',')
       rm = getFPRoundMode();
    prevToken();
    emit_insn(
			(fmt << 35)|
			(rm << 32)|
			(Rt << 26)|
			(oc << 20)|
			(Ra << 8) |
			0xF1,!expand_flag,5
			);
}

// ---------------------------------------------------------------------------
// fadd.d fp1,fp2,fp12[,rm]
// fcmp.d r1,fp3,fp10[,rm]
// ---------------------------------------------------------------------------

static void process_fprrop(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    char *p;
    int fmt;
    int rm;

    rm = 0;
    fmt = GetFPSize();
    p = inptr;
    if (oc==0x06)        // fcmp
        Rt = getRegisterX();
    else
        Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    Rb = getRegisterX();
    if (token==',')
       rm = getFPRoundMode();
    prevToken();
    emit_insn(
			(fmt << 35)|
			(rm << 32)|
			(Rt << 26)|
			(oc << 20)|
			(Rb << 14)|
			(Ra << 8) |
			0xF1,!expand_flag,5
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
		((bits & 0x3F) << 20) |
		(oc << 14) |
		(Ra << 8) |
		0xF1,!expand_flag,5
		);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

static void process_rop(int oc)
{
    int Ra;
    int Rt;

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
	emit_insn(
		((__int64)oc << 32) |
		(Rt << 22) |
		(Ra << 8) |
		0x02,!expand_flag,5
		);
	prevToken();
}

// ---------------------------------------------------------------------------
// beq r1,r0,label
// beq r2,#1234,label
// ---------------------------------------------------------------------------

static void process_bcc(int opcode6)
{
    int Ra, Rb;
	int pred = 0;
    int64_t val, imm;
    int64_t disp;

    Ra = getRegisterX();
    need(',');
    NextToken();
    if (token=='#') {
        imm = expr();
		need(',');
		NextToken();
		val = expr();
		if (token==',') {
			inptr++;
			if (*inptr=='T' || *inptr=='t') {
				inptr++;
				pred = 3;
			}
			else if (*inptr=='N' || *inptr=='n') {
				inptr++;
				pred = 2;
			}
		}
		disp = val - code_address;
		emit_insn(((disp & 0xFFFF) << 24) |
			(pred << 22) |
			((imm & 0xff) << 14) |
			(Ra << 8) |
			opcode6+0x10,0,5
		);
		emit_postfix8(imm);
        return;
    }
	prevToken();
    Rb = getRegisterX();
    need(',');
    NextToken();

    val = expr();
	if (token==',') {
		inptr++;
		if (*inptr=='T' || *inptr=='t') {
			inptr++;
			pred = 3;
		}
		else if (*inptr=='N' || *inptr=='n') {
			inptr++;
			pred = 2;
		}
	}
    disp = val - code_address;
    emit_insn(((disp & 0xFFFF) << 24) |
		(pred << 22) |
        (Rb << 14) |
        (Ra << 8) |
        opcode6,0,5
    );
}

// ---------------------------------------------------------------------------
// beqi r1,r0,label
// beqi r2,#1234,label
// ---------------------------------------------------------------------------

static void process_bcci(int opcode6)
{
    int Ra;
	int pred = 0;
    int64_t val, imm;
    int64_t disp;

    Ra = getRegisterX();
    need(',');
    NextToken();
    imm = expr();
	need(',');
	NextToken();
	val = expr();
	if (token==',') {
		inptr++;
		if (*inptr=='T' || *inptr=='t') {
			inptr++;
			pred = 3;
		}
		else if (*inptr=='N' || *inptr=='n') {
			inptr++;
			pred = 2;
		}
	}
	disp = val - code_address;
	emit_insn(((disp & 0xFFFF) << 24) |
		(pred << 22) |
		((imm & 0xff) << 14) |
		(Ra << 8) |
		opcode6,0,5
	);
	emit_postfix8(imm);
    return;
}


// ---------------------------------------------------------------------------
// bfextu r1,r2,#1,#63
// ---------------------------------------------------------------------------

static void process_bitfield(int oc)
{
    int Ra;
    int Rt;
    int64_t mb;
    int64_t me;

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    mb = expr();
    need(',');
    NextToken();
    me = expr();
    emit_insn(
        ((int64_t)oc << 36) |
        (me << 28) |
        (mb << 20) |
        (Rt << 14) |
        (Ra << 8) |
        0x13,0,5	// bitfield
    );
}


// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int oc)
{
    int Ra = 0, Rb = 0;
    int64_t val;
    int64_t disp;

    NextToken();
    val = expr();
    disp = val - code_address;
    emit_insn(((disp & 0xFFFF) << 24) |
		(3 << 22) |
        (Rb << 14) |
        (Ra << 8) |
        0x46,0,5
    );
}

// ----------------------------------------------------------------------------
// chk r1,r2,#1234
// ----------------------------------------------------------------------------

static void process_chki(int opcode6)
{
	int Ra;
	int Rb;
	int64_t val; 
     
	Ra = getRegisterX();
	need(',');
	Rb = getRegisterX();
	need(',');
	NextToken();
	val = expr();
	emit_insn(((val & 0xFFFFF) << 20)|(Rb << 14)|(Ra << 8)|opcode6,!expand_flag,5);
	emit_postfix20(val);
}


// ---------------------------------------------------------------------------
// fbeq.q fp1,fp0,label
// ---------------------------------------------------------------------------

static void process_fbcc(int opcode)
{
    int Ra, Rb;
    int64_t val;
    int64_t disp;
	int sz;

    sz = GetFPSize();
    Ra = getRegisterX();
    need(',');
    Rb = getRegisterX();
    need(',');
    NextToken();

    val = expr();
    disp = val - code_address;
	if (disp < -131072 || disp > 131071) {
		// Flip the test
		switch(opcode) {
		case 0:	opcode = 1; break;
		case 1:	opcode = 0; break;
		case 2:	opcode = 3; break;
		case 3:	opcode = 2; break;
		case 4:	opcode = 5; break;
		case 5: opcode = 4; break;
		case 6:	opcode = 7; break;
		case 7:	opcode = 6; break;
		}
		emit_insn(
			(sz << 27) |
			(4 << 21) |
			(opcode << 18) |
			(Rb << 12) |
			(Ra << 6) |
			0x01,0,5
		);
		emit_insn((disp & 0x1FFF) << 19 |
			0x12,0,5
		);
		return;
	}
    emit_insn(
		((disp & 0x3FFFF) << 22) |
		(sz << 20) |
        (Rb << 14) |
        (Ra << 8) |
        0x01,0,5
    );
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_call()
{
	int64_t val;
	int Ra = 0;

    NextToken();
	val = expr();
	if (token=='[') {
		Ra = getRegisterX();
		need(']');
		if (Ra==63) {
			val -= code_address;
		}
	}
	if (val==0) {
		emit_insn(
			(Ra << 8) |
			0x50,0,5
		);
		return;
	}
	if (Ra==0 && val < 0xFFFFFFFFLL)
	{
		emit_insn(
			(val << 8) |
			0x44,0,5
		);
		return;
	}
	emit_insn(
		(val << 20) |
		(Ra << 8) |
		0x50,0,5
		);
	emit_postfix20(val);
	return;
}

static void process_ret()
{
	int64_t val = 10;

    NextToken();
	if (token=='#') {
		val = expr();
	}
	emit_insn(
		((val & 0xFFFFF) << 20) |
		0xEF,0,5
		);
	emit_postfix20(val);
}

// ----------------------------------------------------------------------------
// inc -8[bp],#1
// ----------------------------------------------------------------------------

static void process_inc(int oc)
{
    int Ra;
    int Rb;
    int64_t incamt;
    int64_t disp;
    char *p;
    int fixup = 5;
    int neg = 0;
	int Sc;

    NextToken();
    p = inptr;
    mem_operand(&disp, &Ra, &Rb, &Sc);
    incamt = 1;
    if (token==']')
       NextToken();
    if (token==',') {
        NextToken();
        incamt = expr();
        prevToken();
    }
    if (Rb >= 0) {
       if (disp != 0)
           printf("displacement not allowed with indexed addressing.\r\n");
       oc = 0x6F;  // INCX
	   // ToDo: fix this
       emit_insn(
           ((disp & 0xFF) << 24) |
           (Rb << 17) |
           ((incamt & 0x1F) << 12) |
           (Ra << 7) |
           oc,0,5
       );
       return;
    }
    if (oc==0x25) neg = 1;
    oc = 0x96;        // INC
    if (Ra < 0) Ra = 0;
    if (neg) incamt = -incamt;
	emit_insn(
		(disp << 20) |
		((incamt & 0x3f) << 14) |
		(Ra << 8) |
		oc,0,5);
	emit_postfix20(disp);
    ScanToEOL();
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_int()
{
	int64_t val;

    NextToken();
	val = expr();
	emit_insn(
		(1 << 23) |
		((val & 0x1FF) << 8) |
		0x1B,0,5
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
	  case 16: *sc = 4; break;
      default: printf("Illegal scaling factor.\r\n");
      }
}


// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// [Reg]
// [Reg+Reg]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA, int *regB, int *Sc)
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
	 *Sc = 0;
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

// ---------------------------------------------------------------------------
// sw disp[r1],r2
// sw [r1+r2],r3
// ----------------------------------------------------------------------------

static void process_store(int opcode6)
{
    int Ra,Rb;
    int Rs;
    int64_t disp,val;
	int Sc;

    Rs = getRegisterX();
    if (Rs < 0) {
        printf("Expecting a source register (%d).\r\n", lineno);
        printf("Line:%.60s\r\n",inptr);
        ScanToEOL();
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &Sc);
	if (Ra > 0 && Rb > 0) {
		if (disp < -1023LL || disp > 1023LL)
			printf("Index displacment (%I64d) too large (%d)\r\n", disp, lineno);
		emit_insn(
			(disp << 29) |
			(Sc << 26) |
			(Rs << 20) |
			(Rb << 14) |
			(Ra << 8) |
			opcode6 + 0x20,!expand_flag,5);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	emit_insn(
		(val << 20) |
		(Rs << 14) |
		(Ra << 8) |
		opcode6,!expand_flag,5);
	emit_postfix20(val);
    ScanToEOL();
}

// ---------------------------------------------------------------------------
// pea disp[r1]
// ----------------------------------------------------------------------------

static void process_pea(int opcode6)
{
    int Ra,Rb;
    int Rs=0;
    int64_t disp,val;
	int Sc;

    mem_operand(&disp, &Ra, &Rb, &Sc);
	if (Ra > 0 && Rb > 0) {
		if (disp < -1023LL || disp > 1023LL)
			printf("Index displacment (%I64d) too large (%d)\r\n", disp, lineno);
		emit_insn(
			(disp << 29) |
			(Sc << 26) |
			(Rs << 20) |
			(Rb << 14) |
			(Ra << 8) |
			opcode6 + 0x20,!expand_flag,5);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	emit_insn(
		(val << 20) |
		(Rs << 14) |
		(Ra << 8) |
		opcode6,!expand_flag,5);
	emit_postfix20(val);
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi()
{
    int Ra = 0;
    int Rt;
    int64_t val;
    int opcode6 = 0x09;  // ORI

    Rt = getRegisterX();
    expect(',');
    val = expr();
	emit_insn(
		(val << 20) |
		(Rt << 14) |
		opcode6,0,5
	);
	emit_postfix20(val);
}

// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// ----------------------------------------------------------------------------

static void process_load(int opcode6)
{
    int Ra,Rb;
    int Rt;
    char *p;
    int64_t disp;
    int64_t val;
    int fixup = 5;
	int Sc;

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
    mem_operand(&disp, &Ra, &Rb, &Sc);
	if (Ra > 0 && Rb > 0) {
		if (disp < -1023LL || disp > 1023LL)
			printf("Index displacment (%I64d) too large (%d)\r\n", disp, lineno);
		emit_insn(
			(disp << 29) |
			(Sc << 26) |
			(Rt << 20) |
			(Rb << 14) |
			(Ra << 8) |
			opcode6+(opcode6==0x26?0x01:0x20),!expand_flag,5);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	/*
	if (opcode6==0x86 && Ra==59 && val > -511 && val < 511) {
		emit_insn(
			((val & 0x3FF) << 14) |
			(Rt << 8) |
			0x72,0,5);
	}
	else if (opcode6==0x86 && val >- 2047 && val < 2047) {
		emit_insn(
			((val & 0xFFF) << 20) |
			(Rt << 14) |
			(Ra << 8) |
			0x73,!expand_flag,5);
	}
	else
	*/
	{
		emit_insn(
		(val << 20) |
		(Rt << 14) |
		(Ra << 8) |
		opcode6,0,5);
		emit_postfix20(val);
	}
    ScanToEOL();
}

static void process_lsfloat(int opcode6)
{
    int Ra,Rb;
    int Rt;
    char *p;
    int64_t disp;
    int64_t val;
    int fixup = 5;
	int Sc;
    int  sz;
    int rm;

    rm = 0;
    sz = GetFPSize();
    p = inptr;
    Rt = getFPRegister();
    if (Rt < 0) {
        printf("Expecting a target register (1:%d).\r\n", lineno);
        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &Sc);
	if (Ra > 0 && Rb > 0) {
		if (disp < -1023LL || disp > 1023LL)
			printf("Index displacment (%I64d) too large (%d)\r\n", disp, lineno);
		emit_insn(
			(disp << 29) |
			(Sc << 26) |
			(Rt << 20) |
			(Rb << 14) |
			(Ra << 8) |
			opcode6,!expand_flag,5);
		return;
	}
    if (Ra < 0) Ra = 0;
    val = disp;
	if (disp < -1023 || disp > 15LL) {
	}
	else {
		emit_insn(
			(sz << 27) |
			(Rt << 18) |
			((val & 0x1f) << 11) |
			(Ra << 6) |
			opcode6,!expand_flag,5);
    }
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
	process_load(0x86);
}

// ----------------------------------------------------------------------------
// mov r1,r2
// ----------------------------------------------------------------------------

static void process_mov(int oc)
{
     int Ra;
     int Rt;
	 char *p;

	 p = inptr;
	 Rt = getFPRegister();
	 if (Rt==-1) {
		 inptr = p;
 	     Rt = getRegisterX();
	 }
     need(',');
	 p = inptr;
	 Ra = getFPRegister();
	 if (Ra==-1) {
		 inptr = p;
 		 Ra = getRegisterX();
	 }
	 emit_insn(
		 (Rt << 14) |
		 (Ra << 8) |
		 oc,0,5
		 );
	prevToken();
}

// ----------------------------------------------------------------------------
// srli r1,r2,#5
// ----------------------------------------------------------------------------

static void process_shifti(int funct6)
{
     int Ra;
     int Rt;
     int64_t val;
     
     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     need(',');
     NextToken();
     val = expr();
     emit_insn(((__int64)funct6 << 32) | (Rt << 20)| ((val & 0x3F) << 14) | (Ra << 8) | 0x02,!expand_flag,5);
}

// ----------------------------------------------------------------------------
// shl r1,r2,r3
// ----------------------------------------------------------------------------

static void process_shift(int funct6)
{
     int Ra, Rb;
     int Rt;
     char *p;

	 p = inptr;
     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     need(',');
     NextToken();
	 if (token=='#') {
		 inptr = p;
		 process_shifti(funct6 + 0x10);
	 }
	 else {
		prevToken();
		Rb = getRegisterX();
		emit_insn(((__int64)funct6 << 32) | (Rt << 20)| (Rb << 14) | (Ra << 8) | 0x02,!expand_flag,5);
	 }
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
// fill.b 252,0x00
// ----------------------------------------------------------------------------

static void process_fill()
{
    char sz = 'b';
    int64_t count;
    Int128 val;
    int64_t nn;

    if (*inptr=='.') {
        inptr++;
        if (strchr("bwtpdBWTPD",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal fill size.\r\n");
    }
    SkipSpaces();
    NextToken();
    count = expr();
    prevToken();
    need(',');
    NextToken();
    val = expr128();
    prevToken();
    for (nn = 0; nn < count; nn++)
        switch(sz) {
        case 'b': emitByte(val.low); break;
        case 'w': emitChar(val.low); break;
        case 't': emitHalf(val.low); break;
        case 'p': emit40(val); break;
        case 'd': emit80(val); break;
        }
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

static void process_csrrw(int op)
{
	int Rd;
	int Rs;
	int Rc;
	int64_t val,val2;
	char *p;
  
	Rd = getRegisterX();
	need(',');
	p = inptr;
	NextToken();
	if (token=='#') {
		val = expr();
		need(',');
		NextToken();
		if (token=='#') {
			val2 = expr();
			emit_insn(
				((__int64)op << 38) |
				((val & 0x3FFF) << 22)|
				((val2 & 0xFF) << 14) |
				(Rd << 8) | 0x0F,0,5);
			emit_postfix8(val2);
			return;
		}
		prevToken();
		Rs = getRegisterX();
		emit_insn(
			((__int64)op << 38) | 
			(3LL << 36) |
			((val & 0x3FFF) << 22) |
			(Rd << 14) |
			(Rs << 8) |
			0x0F,!expand_flag,5);
		prevToken();
		return;
		}
	inptr = p;
	Rc = getRegisterX();
	need(',');
	NextToken();
	if (token=='#') {
		val2 = expr();
		emit_insn(
			((__int64)op << 38) | 
			(1LL << 36) |
			(Rd << 22) | ((val2 & 0xFF) << 14) | (Rc << 8) | 0x0F,!expand_flag,5);
		emit_postfix8(val2);
		return;
	}
	prevToken();
	Rs = getRegisterX();
	emit_insn(
		((__int64)op << 38) |
		(2LL << 36) |
		(Rd << 22) |
		(Rc << 14) |
		(Rs << 8) |
		0x0F,!expand_flag,5);
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

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
	emit_insn(
		(0xFFFFF << 20) |
		(Rt << 14) |
		(Ra << 8) |
		0x0A,!expand_flag,5
		);
	prevToken();
}

// ---------------------------------------------------------------------------
// com r3,r3
// - alternate mnemonic for xor Rn,Rn,#-1
// ---------------------------------------------------------------------------

static void process_neg()
{
    int Ra;
    int Rt;

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
	emit_insn(
		(0x07 << 26) |
		(Rt << 20) |
		(Ra << 14) |
		(0 << 8) |
		0x02,!expand_flag,5
		);
	prevToken();
}

// ----------------------------------------------------------------------------
// push r1
// push #123
// ----------------------------------------------------------------------------

static void process_push(int func)
{
    int Ra,Rb;
	int FRa;
	int sz;
    int64_t val;

    Ra = -1;
    Rb = -1;
    sz = GetFPSize();
    NextToken();
    if (token=='#') {  // Filter to PUSH
       val = expr();
	   /*
	    if (val >= -15LL && val < 16LL) {
			emit_insn(
				(4 << 11) |
				((val & 0x1f) << 6) |
				0x19,0,5
				);
			return;
		}
		*/
		emit_insn(
			((val & 0xFFFFFLL) << 20) |
			(0x00 << 14) |
			(0x00 << 8) |
			0x9C,  // PEA
			0,5
		);
		emit_postfix20(val);
        return;
    }
    prevToken();
	FRa = getFPRegister();
	if (FRa==-1) {
		prevToken();
		Ra = getRegisterX();
	}
	else {
		emit_insn(
			(FRa << 6) |
			func,0,5
			);
		prevToken();
		return;
	}
    if (Ra == -1) {
		Ra = 0;
        printf("%d: unknown register.\r\n");
    }
	if (func==0x71)	// POP
		emit_insn(
			(Ra << 14) |
			func,0,5);
	else
		emit_insn(
			(Ra << 8) |
			func,0,5);
    prevToken();
}

static void process_sync(int oc)
{
//    emit_insn(oc,!expand_flag);
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void ProcessEOL(int opt)
{
    int64_t nn,mm;
    int first;
    int cc;
    bool sp;

     //printf("Line: %d\r", lineno);
     expand_flag = 0;
     compress_flag = 0;
     segprefix = -1;
     if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
    nn = binstart;
    cc = 2;
    if (segment==codeseg) {
       cc = 5;
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
	sp = false;
    while (nn < sections[segment].index) {
		sp = ((ca & 15)==10);
		fprintf(ofp, "%06LLX ", ca);
        for (mm = nn; nn < mm + cc && nn < sections[segment].index; ) {
			switch(sections[segment].index-nn) {
			case 1:	/*fprintf(ofp, "        %02X ", sections[segment].bytes[nn]);*/ nn++; break;
			case 2: fprintf(ofp, "      %02X%02X ", sections[segment].bytes[nn+1], sections[segment].bytes[nn]); nn += 2; break;
			case 3: fprintf(ofp, "    %02X%02X%02X ",
						sections[segment].bytes[nn+2], 
						sections[segment].bytes[nn+1],
						sections[segment].bytes[nn]); nn += 3; break;
			case 4: fprintf(ofp, "  %02X%02X%02X%02X ",
						sections[segment].bytes[nn+3],
						sections[segment].bytes[nn+2],
						sections[segment].bytes[nn+1],
						sections[segment].bytes[nn]); nn += 4; break;
			case 5: fprintf(ofp, "%02X%02X%02X%02X%02X ",
						sections[segment].bytes[nn+4],
						sections[segment].bytes[nn+3],
						sections[segment].bytes[nn+2],
						sections[segment].bytes[nn+1],
						sections[segment].bytes[nn]); nn += 5; break;
			default: fprintf(ofp, "%02X%02X%02X%02X%02X ",
						sections[segment].bytes[nn+4],
						sections[segment].bytes[nn+3],
						sections[segment].bytes[nn+2],
						sections[segment].bytes[nn+1],
						sections[segment].bytes[nn]); nn += sp ? 6 : 5; break;
			}
        }
		for (; nn < mm + cc; nn++)
			fprintf(ofp, "  ");
		if (first & opt) {
			fprintf(ofp, "\t%.*s\n", inptr-stptr-1, stptr);
			first = 0;
		}
		else
			fprintf(ofp, opt ? "\n" : "; NOP Ramp\n");
		if (sp)
			cc = 6;
		else
			cc = 5;
        ca += cc;
		cc = 5;
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

void dsd9_GenerateListing()
{
	unsigned nn;
	int kk;
	char lnbuf[200];
	char *p = nullptr;

	for (nn = 0; nn < cs.bufndx; nn++) {
		fprintf(ofp, "[%08I64X] %08I64X ", ((cs.buf[nn].address * 5) >> 1), cs.buf[nn].address);
		if (cs.buf[nn].size==1)
			fprintf(ofp, "%05I64X          ", cs.buf[nn].opcode & 0xFFFFFLL);
		else
			fprintf(ofp, "%010I64X", cs.buf[nn].opcode & 0xFFFFFFFFFFLL);
		for (kk = 0; cs.buf[nn].source[kk] != '\r' && cs.buf[nn].source[kk] != '\n' && cs.buf[nn].source[kk] && kk < 198; kk++)
			lnbuf[kk] = cs.buf[nn].source[kk];
		lnbuf[kk] = '\0';
		if (cs.buf[nn].source!=p)
		{
			fprintf(ofp, lnbuf);
			p = cs.buf[nn].source;
		}
		fprintf(ofp, "\n");
	}
}

int dsd9_GetNextNybble(int *bndx, int *shft)
{
	int nyb;

	nyb = (cs.buf[*bndx].opcode >> *shft) & 0xF;
	*shft += 4;
	if (*shft >= cs.buf[*bndx].size * 20) {
		(*bndx)++;
		*shft = 0;
	}
	return nyb;
}

void dsd9_VerilogOut(FILE *fp)
{
	unsigned int nn;
	int bndx;
	int shft;
	int cnt;
	int nyb;
	int romndx = 0;
	char buf[40];

	shft = 0;
	cnt = 0;
	for (bndx = 0; bndx < cs.bufndx; ) {
		if (cnt==0)
			fprintf(fp, "rommem[%d] = 128'h", romndx);
		nyb = dsd9_GetNextNybble(&bndx, &shft);
		buf[cnt] = nyb;
		cnt++;
		if (cnt==32) {
			for (--cnt; cnt >= 0; --cnt)
				fprintf(fp, "%X", buf[cnt]);
			fprintf(fp, ";\n");
			romndx++;
			cnt = 0;
		}
	}
	if (cnt > 0 && cnt < 32) {
		for (; cnt < 32; cnt++)
			buf[cnt] = nyb;
		for (--cnt; cnt >= 0; --cnt)
			fprintf(fp, "%X", buf[cnt]);
		fprintf(fp, ";\n");
	}
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void dsd9_processMaster()
{
    int nn;
    int64_t bs1, bs2;
	/*
	if (bGenListing) {
		dsd9_GenerateListing();
		return;
	}
	*/
    lineno = 1;
    binndx = 0;
    binstart = 0;
    bs1 = 0;
    bs2 = 0;
    inptr = &masterFile[0];
    stptr = inptr;
	lptr = inptr;
    code_address = 0;
    bss_address = 0;
    start_address = 0;
    first_org = 1;
    first_rodata = 1;
    first_data = 1;
    first_bss = 1;
	expandedBlock = 1;
    if (pass<3) {
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
	memset(bytebuf,0,sizeof(bytebuf));
	cs.address = 0;
	cs.bufndx = 0;
	num_bytes = 0;
	num_insns = 0;
    NextToken();
    while (token != tk_eof) {
//        printf("\t%.*s\n", inptr-stptr-1, stptr);
//        printf("token=%d\r", token);
          if (expandedBlock)
             expand_flag = 1;
        switch(token) {
        case tk_eol:	ProcessEOL(1);
						lptr = inptr;
						break;
        case tk_add:  process_rrop(0x04); break;
        case tk_addi: process_riop(0x04); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(0x08); break;
        case tk_andi:  process_riop(0x08); break;
        case tk_asl: process_shift(0x32); break;
        case tk_asr: process_shift(0x33); break;
        case tk_bbc: process_bcci(0x54); break;
        case tk_bbs: process_bcci(0x55); break;
        case tk_begin_expand: expandedBlock = 1; break;
        case tk_beq: process_bcc(0x46); break;
        case tk_beqi: process_bcci(0x56); break;
        case tk_bfext: process_bitfield(5); break;
        case tk_bfextu: process_bitfield(6); break;
        case tk_bge: process_bcc(0x49); break;
        case tk_bgei: process_bcci(0x59); break;
        case tk_bgeu: process_bcc(0x4D); break;
        case tk_bgeui: process_bcci(0x5D); break;
        case tk_bgt: process_bcc(0x4B); break;
        case tk_bgti: process_bcci(0x5B); break;
        case tk_bgtu: process_bcc(0x4F); break;
        case tk_bgtui: process_bcci(0x5F); break;
        case tk_ble: process_bcc(0x4A); break;
        case tk_blei: process_bcci(0x5A); break;
        case tk_bleu: process_bcc(0x4E); break;
        case tk_bleui: process_bcci(0x5E); break;
        case tk_blt: process_bcc(0x48); break;
        case tk_blti: process_bcci(0x58); break;
        case tk_bltu: process_bcc(0x4C); break;
        case tk_bltui: process_bcci(0x5C); break;
        case tk_bne: process_bcc(0x47); break;
        case tk_bnei: process_bcci(0x57); break;
        case tk_bra: process_bra(0x46); break;
        //case tk_bsr: process_bra(0x56); break;
        case tk_bss:
            if (first_bss) {
                while(sections[segment].address & 15)
                    emitByte(0x00);
                sections[3].address = sections[segment].address;
                first_bss = 0;
                binstart = sections[3].index;
                ca = sections[3].address;
            }
            segment = bssseg;
            break;
		case tk_call:	process_call(); break;
		case tk_calltgt:	emit_insn(0x53,0,5); break;
		case tk_chki:  process_chki(0x0E); break;
        case tk_cli: emit_insn(0x00E8,0,5); break;
        case tk_code: process_code(); break;
        case tk_com: process_com(); break;
        case tk_cs:  segprefix = 15; break;
        case tk_csrrc: process_csrrw(0x2); break;
        case tk_csrrs: process_csrrw(0x1); break;
        case tk_csrrw: process_csrrw(0x0); break;
        case tk_data:
            if (first_data) {
                while(sections[segment].address & 15)
                    emitByte(0x00);
                sections[2].address = sections[segment].address;   // set starting address
                first_data = 0;
                binstart = sections[2].index;
                ca = sections[2].address;
            }
            process_data(dataseg);
            break;
		case tk_dec: process_inc(0x25); break;
		case tk_db: process_db(); break;
        case tk_dh_htbl:  process_dh_htbl(); break;
        case tk_div: process_rrop(0x18); break;
        case tk_divu: process_rrop(0x19); break;
		case tk_dd:	process_dd(); break;
        case tk_do:  process_dw(); break;
        case tk_dt:  process_dh(); break;
		case tk_dw:	 process_dc(); break;
        case tk_end: goto j1;
        case tk_end_expand: expandedBlock = 0; break;
        case tk_endpublic: break;
        case tk_eor: process_rrop(0x0A); break;
        case tk_eori: process_riop(0x0A); break;
        case tk_extern: process_extern(); break;
        case tk_fabs: process_fprop(0x15); break;
        case tk_fadd: process_fprrop(0x04); break;
        case tk_fbeq: process_fbcc(0x36); break;
        case tk_fbne: process_fbcc(0x37); break;
        case tk_fbun: process_fbcc(0x3D); break;
        case tk_fbor: process_fbcc(0x3C); break;
        case tk_fblt: process_fbcc(0x38); break;
        case tk_fbge: process_fbcc(0x39); break;
        case tk_fble: process_fbcc(0x3A); break;
        case tk_fbgt: process_fbcc(0x3B); break;
        case tk_fcmp: process_fprrop(0x06); break;
        case tk_fdiv: process_fprrop(0x09); break;
        case tk_fill: process_fill(); break;
        case tk_fix2flt: process_fprop(0x13); break;
        case tk_flt2fix: process_fprop(0x12); break;
        case tk_fmov: process_fprop(0x10); break;
        case tk_fmul: process_fprrop(0x08); break;
        case tk_fnabs: process_fprop(0x18); break;
        case tk_fneg: process_fprop(0x14); break;
        case tk_frm: process_fpstat(0x24); break;
//        case tk_fstat: process_fprdstat(0x86); break;
        case tk_fsub: process_fprrop(0x05); break;
		case tk_ftoi: process_fprop(0x12); break;
        case tk_ftx: process_fpstat(0x20); break;
        case tk_gran: process_gran(0x14); break;
		case tk_hint:	process_hint(); break;
		case tk_inc:	process_inc(0x96); break;
		case tk_int:	process_int(); break;
		case tk_iret:	emit_insn(0xE4,0,5); break;
		case tk_itof: process_fprop(0x13); break;
        case tk_jal: process_jal(0x15); break;
        case tk_jmp: process_jal(0x15); break;
		case tk_ld:	process_ld(); break;
        case tk_ldb: process_load(0x80); break;
        case tk_ldbu: process_load(0x81); break;
        case tk_ldw: process_load(0x82); break;
        case tk_ldwu: process_load(0x83); break;
        case tk_ldp: process_load(0x84); break;
        case tk_ldpu: process_load(0x85); break;
        case tk_ldd: process_load(0x86); break;
        case tk_ldi: process_ldi(); break;
		case tk_ldt: process_load(0x87); break;
		case tk_ldtu: process_load(0x88); break;
		case tk_ldvdar: process_load(0x8E); break;
        case tk_lea: process_load(0x26); break;
		case tk_lf:	 process_lsfloat(0x26); break;
        case tk_lh:  process_load(0x20); break;
        case tk_lhu: process_load(0x21); break;
//        case tk_lui: process_lui(); break;
        case tk_lw:  process_load(0x22); break;
        case tk_lwar:  process_load(0x23); break;
		case tk_mark1: emit_insn(0xF8,0,5); break;
		case tk_mark2: emit_insn(0xF9,0,5); break;
		case tk_message: process_message(); break;
        case tk_mod: process_rrop(0x1B); break;
        case tk_modu: process_rrop(0x1C); break;
        case tk_mov: process_mov(0x30); break;
        case tk_mul: process_rrop(0x10); break;
        case tk_muli: process_riop(0x10); break;
        case tk_mulu: process_rrop(0x11); break;
        case tk_mului: process_riop(0x11); break;
        case tk_neg: process_neg(); break;
        case tk_nop: emit_insn(0x1A,0,5); break;
//        case tk_not: process_rop(0x07); break;
        case tk_or:  process_rrop(0x09); break;
        case tk_ori: process_riop(0x09); break;
        case tk_org: process_org(); break;
        case tk_plus: expand_flag = 1; break;
		case tk_pea:	process_pea(0x9c); break;
		case tk_pop:	process_push(0x71); break;
        case tk_public: process_public(); break;
		case tk_push:	process_push(0x70); break;
        case tk_rodata:
            if (first_rodata) {
                while(sections[segment].address & 15)
                    emitByte(0x00);
                sections[1].address = sections[segment].address;
                first_rodata = 0;
                binstart = sections[1].index;
                ca = sections[1].address;
            }
            segment = rodataseg;
            break;
		case tk_ret: process_ret(); break;
		case tk_rol: process_shift(0x34); break;
		case tk_roli: process_shifti(0x44); break;
		case tk_ror: process_shift(0x35); break;
		case tk_rori: process_shifti(0x45); break;
        case tk_sei: emit_insn(0xE9,0,5); break;
		case tk_seq:	process_riop(0x76); break;
		case tk_sf:	 process_lsfloat(0x27); break;
		case tk_sge:	process_riop(0x79); break;
		case tk_sgeu:	process_riop(0x7D); break;
		case tk_sgt:	process_riop(0x7B); break;
		case tk_sgtu:	process_riop(0x7F); break;
        //case tk_slti:  process_riop(0x13,0x02); break;
        //case tk_sltui:  process_riop(0x13,0x03); break;
        case tk_shl: process_shift(0x30); break;
        case tk_shli: process_shifti(0x40); break;
		case tk_shr: process_shift(0x33); break;
		case tk_shru: process_shift(0x31); break;
		case tk_shrui: process_shifti(0x41); break;
        case tk_slli: process_shifti(0x40); break;
		case tk_sle:	process_riop(0x7A); break;
		case tk_sleu:	process_riop(0x7E); break;
		case tk_slt:	process_riop(0x78); break;
		case tk_sltu:	process_riop(0x7C); break;
		case tk_sne:	process_riop(0x77); break;
        case tk_srai: process_shifti(0x43); break;
        case tk_srli: process_shifti(0x41); break;
        case tk_stb: process_store(0x90); break;
        case tk_stw: process_store(0x91); break;
        case tk_stp: process_store(0x92); break;
        case tk_std: process_store(0x93); break;
        case tk_stdcr: process_store(0x95); break;
        case tk_stt: process_store(0x94); break;
        case tk_sub:  process_rrop(0x07); break;
        case tk_subi:  process_riop(0x07); break;
//        case tk_sub:  process_sub(); break;
        case tk_sxb: process_rop(0x16); break;
        case tk_sxc: process_rop(0x17); break;
        case tk_sxh: process_rop(0x17); break;
        case tk_swap: process_rop(0x03); break;
        case tk_sync: process_sync(0x77); break;
		case tk_tgt:	emit_insn(0x53,0,5); break;
        case tk_xor: process_rrop(0x0A); break;
        case tk_xori: process_riop(0x0A); break;
        case tk_id:  process_label(); break;
        case '-': compress_flag = 1; break;
        }
        NextToken();
    }
j1:
    ;
}

