// ============================================================================
//        __
//   \\__/ o\    (C) 2015-2016  Robert Finch, Stratford
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
//#include <futs.h>

#define BCC(x)       (((x) << 12)|0x38)

// Fixup types
#define FUT_C15       1
#define FUT_C40       2
#define FUT_C64       3
#define FUT_R27       4

extern int isIdentChar(char);
static void emitAlignedCode(int cd);
static void process_shifti(int oc, int fn);
static void ProcessEOL(int opt);
static void mem_operand(int64_t *disp, int *regA, int *regB, int *sc, int *md);
static void getSzDir(int *, int *);

extern int first_rodata;
extern int first_data;
extern int first_bss;
static int64_t ca;
extern int isInitializationData;
extern int use_gp;
extern int pass;
extern char first_org;
extern int htblmax;

int predicate;
int seg;

// This structure not used.
typedef struct tagInsn
{
    union {
        struct {
            unsigned int opcode : 7;
            unsigned int Ra : 5;
            unsigned int Rt : 5;
            unsigned int imm : 15;
        } ri;
        struct {
            unsigned int opcode : 7;
            unsigned int Ra : 5;
            unsigned int Rt : 5;
            unsigned int Rb : 5;
            unsigned int resv : 3;
            unsigned int funct : 7;
        } rr;
    };
};

static int isdelim(char ch)
{
    return ch==',' || ch=='[' || ch=='(' || ch==']' || ch==')' || ch=='.';
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static int getPredreg()
{
    int pr;
    
    NextToken();
    if (token != tk_pred) {
        printf("%d expecting predicate register %d.\r\n", lineno, token);
        return -1;
    }
     if (isdigit(inptr[0]) && isdigit(inptr[1])) {
          pr = ((inptr[0]-'0' * 10) + (inptr[1]-'0'));
          inptr += 2;
     }
     else if (isdigit(inptr[0])) {
          pr = (inptr[0]-'0');
          inptr += 1;
     }
     NextToken();
     return pr;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static int getCodeareg()
{
    int pr;

    SkipSpaces();
    if (inptr[0]=='c' || inptr[0]=='C') {
         if (isdigit(inptr[1]) && (inptr[2]==',' || isdelim(inptr[2]) || isspace(inptr[2]))) {
              pr = (inptr[1]-'0');
              inptr += 2;
         }
         else if (isdigit(inptr[1]) && isdigit(inptr[2]) && (inptr[3]==',' || isdelim(inptr[3]) || isspace(inptr[3]))) {
              pr = ((inptr[1]-'0') * 10) + (inptr[2]-'0');
              inptr += 3;
         }
         else
             return -1;
    }
    else
        return -1;
     NextToken();
     return pr;
}

static int getTlbReg()
{
   int Tn;
   
   Tn = -1;
   SkipSpaces();
   if ((inptr[0]=='a' || inptr[0]=='A') &&
       (inptr[1]=='s' || inptr[1]=='S') &&
       (inptr[2]=='i' || inptr[2]=='I') &&
       (inptr[3]=='d' || inptr[3]=='D') &&
       !isIdentChar(inptr[4])) {
       inptr += 4;
       NextToken();
       return 7;
   }
   if ((inptr[0]=='d' || inptr[0]=='D') &&
       (inptr[1]=='m' || inptr[1]=='M') &&
       (inptr[2]=='a' || inptr[2]=='A') &&
       !isIdentChar(inptr[3])) {
       inptr += 3;
       NextToken();
       return 8;
   }
   if ((inptr[0]=='i' || inptr[0]=='I') &&
       (inptr[1]=='m' || inptr[1]=='M') &&
       (inptr[2]=='a' || inptr[2]=='A') &&
       !isIdentChar(inptr[3])) {
       inptr += 3;
       NextToken();
       return 9;
   }
   if ((inptr[0]=='i' || inptr[0]=='I') &&
       (inptr[1]=='n' || inptr[1]=='N') &&
       (inptr[2]=='d' || inptr[2]=='D') &&
       (inptr[3]=='e' || inptr[3]=='E') &&
       (inptr[4]=='x' || inptr[4]=='X') &&
       !isIdentChar(inptr[5])) {
       inptr += 5;
       NextToken();
       return 2;
   }
   if ((inptr[0]=='p' || inptr[0]=='P') &&
       (inptr[1]=='a' || inptr[1]=='A') &&
       (inptr[2]=='g' || inptr[2]=='G') &&
       (inptr[3]=='e' || inptr[3]=='E') &&
       (inptr[4]=='s' || inptr[4]=='S') &&
       (inptr[5]=='i' || inptr[5]=='I') &&
       (inptr[6]=='z' || inptr[6]=='Z') &&
       (inptr[7]=='e' || inptr[7]=='E') &&
       !isIdentChar(inptr[8])) {
       inptr += 8;
       NextToken();
       return 3;
   }
   if ((inptr[0]=='p' || inptr[0]=='P') &&
       (inptr[1]=='h' || inptr[1]=='H') &&
       (inptr[2]=='y' || inptr[2]=='Y') &&
       (inptr[3]=='s' || inptr[3]=='S') &&
       (inptr[4]=='p' || inptr[4]=='P') &&
       (inptr[5]=='a' || inptr[5]=='A') &&
       (inptr[6]=='g' || inptr[6]=='G') &&
       (inptr[7]=='e' || inptr[7]=='E') &&
       !isIdentChar(inptr[8])) {
       inptr += 8;
       NextToken();
       return 5;
   }
   if ((inptr[0]=='p' || inptr[0]=='P') &&
       (inptr[1]=='t' || inptr[1]=='T') &&
       (inptr[2]=='a' || inptr[2]=='A') &&
       !isIdentChar(inptr[3])) {
       inptr += 3;
       NextToken();
       return 10;
   }
   if ((inptr[0]=='p' || inptr[0]=='P') &&
       (inptr[1]=='t' || inptr[1]=='T') &&
       (inptr[2]=='c' || inptr[2]=='C') &&
       !isIdentChar(inptr[3])) {
       inptr += 3;
       NextToken();
       return 11;
   }
   if ((inptr[0]=='r' || inptr[0]=='R') &&
       (inptr[1]=='a' || inptr[1]=='A') &&
       (inptr[2]=='n' || inptr[2]=='N') &&
       (inptr[3]=='d' || inptr[3]=='D') &&
       (inptr[4]=='o' || inptr[4]=='O') &&
       (inptr[5]=='m' || inptr[5]=='M') &&
       !isIdentChar(inptr[6])) {
       inptr += 6;
       NextToken();
       return 2;
   }
   if ((inptr[0]=='v' || inptr[0]=='V') &&
       (inptr[1]=='i' || inptr[1]=='I') &&
       (inptr[2]=='r' || inptr[2]=='R') &&
       (inptr[3]=='t' || inptr[3]=='T') &&
       (inptr[4]=='p' || inptr[4]=='P') &&
       (inptr[5]=='a' || inptr[5]=='A') &&
       (inptr[6]=='g' || inptr[6]=='G') &&
       (inptr[7]=='e' || inptr[7]=='E') &&
       !isIdentChar(inptr[8])) {
       inptr += 8;
       NextToken();
       return 4;
   }
   if ((inptr[0]=='w' || inptr[0]=='W') &&
       (inptr[1]=='i' || inptr[1]=='I') &&
       (inptr[2]=='r' || inptr[2]=='R') &&
       (inptr[3]=='e' || inptr[3]=='E') &&
       (inptr[4]=='d' || inptr[4]=='D') &&
       !isIdentChar(inptr[5])) {
       inptr += 5;
       NextToken();
       return 0;
   }
   return Tn;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
static int getBitno()
{
    int bit;

    bit = -1;
    while(isspace(*inptr)) inptr++;
    switch(*inptr) {
    case 'b': case 'B':
         if (isdigit(inptr[1])) {
             bit = inptr[1]-'0';
             if (isdigit(inptr[2])) {
                 bit = 10 * bit + (inptr[2]-'0');
                 if (isIdentChar(inptr[3]))
                     return -1;
                 else {
                     inptr += 3;
                     NextToken();
                     return bit;
                 }
             }
             else if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return bit;
             }
         }
         else return -1;
    }
    return bit;
}


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
    case 'b': case 'B':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 26;
        }
        break;
    case 'g': case 'G':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 25;
        }
        break;
    case 's': case 'S':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 27;
        }
        break;
    case 't': case 'T':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 24;
        }
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 31;
        }
        break;
    default:
        return -1;
    }
    return -1;
}


static int getBoundsRegister()
{
    int reg;

    while(isspace(*inptr)) inptr++;
    switch(*inptr) {
    case 'b': case 'B':
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
    }
    return -1;
}


// ----------------------------------------------------------------------------
// Get the friendly name of a special purpose register.
// ----------------------------------------------------------------------------

static int Thor_getSprRegister()
{
    int reg;
    int pr;

    while(isspace(*inptr)) inptr++;
    reg = getCodeareg();
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
         return ival.low;

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

static int getPredcon()
{
    // longer match sequences must be first
    if ((inptr[0]=='l' || inptr[0]=='L') && (inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='u' || inptr[2]=='U')) {
        inptr += 3;
        return 8;
    }
    if ((inptr[0]=='g' || inptr[0]=='G') && (inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='u' || inptr[2]=='U')) {
        inptr += 3;
        return 9;
    }
    if ((inptr[0]=='g' || inptr[0]=='G') && (inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='u' || inptr[2]=='U')) {
        inptr += 3;
        return 10;
    }
    if ((inptr[0]=='l' || inptr[0]=='L') && (inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='u' || inptr[2]=='U')) {
        inptr += 3;
        return 11;
    }
    if (inptr[0]=='f' || inptr[0]=='F') {
        inptr += 1;
        return 0;
    }
    if (inptr[0]=='t' || inptr[0]=='T') {
        inptr += 1;
        return 1;
    }
    if ((inptr[0]=='e' || inptr[0]=='E') && (inptr[1]=='q' || inptr[1]=='Q')) {
        inptr += 2;
        return 2;
    }
    if ((inptr[0]=='n' || inptr[0]=='N') && (inptr[1]=='e' || inptr[1]=='E')) {
        inptr += 2;
        return 3;
    }
    if ((inptr[0]=='l' || inptr[0]=='L') && (inptr[1]=='e' || inptr[1]=='E')) {
        inptr += 2;
        return 4;
    }
    if ((inptr[0]=='g' || inptr[0]=='G') && (inptr[1]=='t' || inptr[1]=='T')) {
        inptr += 2;
        return 5;
    }
    if ((inptr[0]=='g' || inptr[0]=='G') && (inptr[1]=='e' || inptr[1]=='E')) {
        inptr += 2;
        return 6;
    }
    if ((inptr[0]=='l' || inptr[0]=='L') && (inptr[1]=='t' || inptr[1]=='T')) {
        inptr += 2;
        return 7;
    }
    return -1;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_first(int oc)
{
     emitCode(oc & 255);
     num_bytes ++;
     num_insns += 1;
}
 
static void emit_insn(int oc)
{
     emitCode(oc & 255);
     num_bytes ++;
}
 
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn4(int64_t oc)
{
    int ndx;

    //printf("<emit_insn4>");
    if (pass==3 && !expand_flag) {
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
       printf("Too many instructions.\r\n");
       return;
    }
    if (pass > 3) {
      if (!expand_flag) {
       for (ndx = 0; ndx < htblmax && ndx < 1024; ndx++) {
         if (oc == hTable[ndx].opcode) {
           emit_insn(0xE0|(ndx & 0xF));
           emit_insn(ndx >> 4);
           num_insns += 1;
           return;
         }
       }
     }
     emit_insn(oc & 255);
     emit_insn((oc >> 8) & 255);
     emit_insn((oc >> 16) & 255);
     emit_insn((oc >> 24) & 255);
     num_insns += 1;
   }
//    printf("</emit_insn4>\r\n");
}
 

static void emit_insn4a(int64_t oc)
{
     emit_insn(oc & 255);
     emit_insn((oc >> 8) & 255);
     emit_insn((oc >> 16) & 255);
     emit_insn((oc >> 24) & 255);
     num_insns += 1;
}
 

static void emit_insn3(int64_t oc)
{
    int ndx;
    if (pass==3 && !expand_flag) {
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
       printf("Too many instructions.\r\n");
       return;
    }
    if (pass > 3) {
      if (!expand_flag) {
       for (ndx = 0; ndx < htblmax && ndx < 1024; ndx++) {
         if (oc == hTable[ndx].opcode) {
           emit_insn(0xE0|(ndx & 0xF));
           emit_insn(ndx >> 4);
           num_insns += 1;
           return;
         }
       }
     }
     emit_insn(oc & 255);
     emit_insn((oc >> 8) & 255);
     emit_insn((oc >> 16) & 255);
     num_insns += 1;
   }
//     emit_insn(oc & 255);
//     emit_insn((oc >> 8) & 255);
//     emit_insn((oc >> 16) & 255);
//     num_bytes += 3;
//     num_insns += 1;
}
 

static void emit2(int64_t oc)
{
     emitAlignedCode(oc & 255);
     num_bytes += 1;
     emit_insn((oc >> 8) & 255);
     num_insns += 1;
}
 
static void emit6(int64_t oc)
{
     emitAlignedCode(oc & 255);
     num_bytes += 1;
     emit_insn((oc >> 8) & 255);
     emit_insn((oc >> 16) & 255);
     emit_insn((oc >> 24) & 255);
     emit_insn((oc >> 32) & 255);
     emit_insn((oc >> 40) & 255);
     num_insns += 1;
}
 
// ---------------------------------------------------------------------------
// Emit code aligned to a code address.
// ---------------------------------------------------------------------------

static void emitAlignedCode(int cd)
{
     int64_t ad;


     ad = code_address & 15;
     while (ad != 0 && ad != 2 && ad != 4 && ad != 6 &&
            ad != 8 && ad != 10 && ad != 12 && ad != 14) {
         emitByte(0x00);
         ad = code_address & 15;
     }

     emitByte(cd);
}


// ---------------------------------------------------------------------------
// Determine how big of a prefix is required.
// ---------------------------------------------------------------------------

static int fitsIn0(int64_t v)
{
    return (((v < 0) && ((v >> 14) == -1L)) || ((v >= 0) && ((v >> 14) == 0)));
}

static int fitsIn28(int64_t v)
{
    return (((v < 0) && ((v >> 42) == -1L)) || ((v >= 0) && ((v >> 42) == 0)));
}

static int fitsIn41(int64_t v)
{
    return (((v < 0) && ((v >> 55) == -1L)) || ((v >= 0) && ((v >> 55) == 0)));
}

static int fitsIn10(int64_t v)
{
    return ((v < 0) && ((v >> 9) == -1L)) || ((v >= 0) && ((v >> 9) == 0));
}

static int fitsIn8(int64_t v)
{
    return ((v < 0) && ((v >> 7) == -1L)) || ((v >= 0) && ((v >> 7) == 0));
}

static int fitsIn9(int64_t v)
{
    return ((v < 0) && ((v >> 8) == -1L)) || ((v >= 0) && ((v >> 8) == 0));
}

static int fitsIn12(int64_t v)
{
    return ((v < 0) && ((v >> 11) == -1L)) || ((v >= 0) && ((v >> 11) == 0));
}

static int fitsIn16(int64_t v)
{
    return ((v < 0) && ((v >> 15) == -1L)) || ((v >= 0) && ((v >> 15) == 0));
}

static int fitsIn24(int64_t v)
{
    return ((v < 0) && ((v >> 23) == -1L)) || ((v >= 0) && ((v >> 23) == 0));
}

static int fitsIn32(int64_t v)
{
    return ((v < 0) && ((v >> 31) == -1L)) || ((v >= 0) && ((v >> 31) == 0));
}

static int fitsIn40(int64_t v)
{
    return ((v < 0) && ((v >> 39) == -1L)) || ((v >= 0) && ((v >> 39) == 0));
}

static int fitsIn48(int64_t v)
{
    return ((v < 0) && ((v >> 47) == -1L)) || ((v >= 0) && ((v >> 47) == 0));
}

static int fitsIn56(int64_t v)
{
    return ((v < 0) && ((v >> 55) == -1L)) || ((v >= 0) && ((v >> 55) == 0));
}

static int emitImm8(int64_t v, int force)
{
     if (fitsIn8(v))
         return 0;
     num_insns++;
     if (fitsIn16(v)) {
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     if (fitsIn24(v)) {
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     if (fitsIn32(v)) {
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     if (fitsIn40(v)) {
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     if (fitsIn48(v)) {
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn56(v)) {
         emit_insn(0x70);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         emit_insn(v >> 48);
         return 1;
     }
     emit_insn(0x80);
     emit_insn(v >> 8);
     emit_insn(v >> 16);
     emit_insn(v >> 24);
     emit_insn(v >> 32);
     emit_insn(v >> 40);
     emit_insn(v >> 48);
     emit_insn(v >> 56);
     return 1;
}

static int emitImm9(int64_t v, int force)
{
     if (force > 0 && force < 16) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     else if (force >= 16 && force < 24) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     else if (force >= 24 && force < 32) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     else if (force >= 32 && force < 40) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     else if (force >= 40 && force < 48) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn9(v))
         return 0;
     if (fitsIn16(v)) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     if (fitsIn24(v)) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     if (fitsIn32(v)) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     if (fitsIn40(v)) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     if (fitsIn48(v)) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn56(v)) {
        num_insns++;
         emit_insn(0x70);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         emit_insn(v >> 48);
         return 1;
     }
        num_insns++;
     emit_insn(0x80);
     emit_insn(v >> 8);
     emit_insn(v >> 16);
     emit_insn(v >> 24);
     emit_insn(v >> 32);
     emit_insn(v >> 40);
     emit_insn(v >> 48);
     emit_insn(v >> 56);
     return 1;
}

static int emitImm10(int64_t v, int force)
{
    if (force > 0 && force < 16) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
    }
    else if (force >= 16 && force < 24) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
    }
    else if (force >= 24 && force < 32) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
    }
    else if (force >= 32 && force < 40) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
    }
    else if (force >= 40 && force < 48) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
    }
     if (fitsIn10(v))
         return 0;
     if (fitsIn16(v)) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     if (fitsIn24(v)) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     if (fitsIn32(v)) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     if (fitsIn40(v)) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     if (fitsIn48(v)) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn56(v)) {
        num_insns++;
         emit_insn(0x70);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         emit_insn(v >> 48);
         return 1;
     }
        num_insns++;
     emit_insn(0x80);
     emit_insn(v >> 8);
     emit_insn(v >> 16);
     emit_insn(v >> 24);
     emit_insn(v >> 32);
     emit_insn(v >> 40);
     emit_insn(v >> 48);
     emit_insn(v >> 56);
     return 1;
}

// Immediate constants RI instructions
static int emitImm12(int64_t v, int force)
{
     if (force > 0 && force < 16) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     else if (force >= 16 && force < 24) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     else if (force >= 24 && force < 32) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     else if (force >= 32 && force < 40) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     else if (force >= 40 && force < 48) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn12(v))
         return 0;
     if (fitsIn16(v)) {
        num_insns++;
         emit_insn(0x20);
         emit_insn(v >> 8);
         return 1;
     }
     if (fitsIn24(v)) {
        num_insns++;
         emit_insn(0x30);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         return 1;
     }
     if (fitsIn32(v)) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     if (fitsIn40(v)) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     if (fitsIn48(v)) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn56(v)) {
        num_insns++;
         emit_insn(0x70);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         emit_insn(v >> 48);
         return 1;
     }
        num_insns++;
     emit_insn(0x80);
     emit_insn(v >> 8);
     emit_insn(v >> 16);
     emit_insn(v >> 24);
     emit_insn(v >> 32);
     emit_insn(v >> 40);
     emit_insn(v >> 48);
     emit_insn(v >> 56);
     return 1;
}

static int emitImm24(int64_t v, int force)
{
     if (fitsIn24(v))
         return 0;
     if (fitsIn32(v)) {
        num_insns++;
         emit_insn(0x40);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         return 1;
     }
     if (fitsIn40(v)) {
        num_insns++;
         emit_insn(0x50);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         return 1;
     }
     if (fitsIn48(v)) {
        num_insns++;
         emit_insn(0x60);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         return 1;
     }
     if (fitsIn56(v)) {
        num_insns++;
         emit_insn(0x70);
         emit_insn(v >> 8);
         emit_insn(v >> 16);
         emit_insn(v >> 24);
         emit_insn(v >> 32);
         emit_insn(v >> 40);
         emit_insn(v >> 48);
         return 1;
     }
        num_insns++;
     emit_insn(0x80);
     emit_insn(v >> 8);
     emit_insn(v >> 16);
     emit_insn(v >> 24);
     emit_insn(v >> 32);
     emit_insn(v >> 40);
     emit_insn(v >> 48);
     emit_insn(v >> 56);
     return 1;
}

// ---------------------------------------------------------------------------
// Emit constant extension for 15-bit operands.
// Returns number of constant prefixes placed.
// ---------------------------------------------------------------------------

static int emitImm15(int64_t v, int force)
{
     int nn;
     
     if (fitsIn0(v))
        return 0;
     else if (fitsIn10(v)) {
         emit2(
            ((v >> 16) << 7) | ((v>>15) & 1) |
            0x10
         );
         return 1;
     }
     else if (fitsIn28(v)) {
         emit_insn(0x78|(((v >> 18)&0x1FFFFFFLL) << 7)|((v >> 15)&7));
         return 1;
     }
     else if (fitsIn41(v)) {
         emit6(0x13|((v >> 15)&0x1FFFFFFFFFFLL) << 7);
         return 1;
     }
     else {
         emit_insn(0x78|(((v >> 46)&0x3FFFFLL) << 7)|((v >> 43)&7));
         emit_insn(0x78|(((v >> 18)&0x1FFFFFFLL) << 7)|((v >> 15)&7));
         return 2;
     }

     // ToDo: modify the fixup record type based on the number of prefixes emitted.
    if (bGen && lastsym && !use_gp && (lastsym->isExtern || lastsym->defined==0))
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | nn+1 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
     return nn;
}

// ---------------------------------------------------------------------------
// bfextu r1,r2,#1,#63
// ---------------------------------------------------------------------------

static void process_bitfield(int oc)
{
    int Ra;
    int Rt;
    int mb;
    int me;

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    mb = expr();
    need(',');
    NextToken();
    me = expr();
    emit_insn(predicate);
    emit_insn(oc);
    emit_insn4a(
        (oc << 29) |
        (me << 23) |
        (mb << 17) |
        (Rt << 12) |
        (Ra << 7) |
        0x03          // bitfield
    );
}

// ---------------------------------------------------------------------------
// sys 4
// ---------------------------------------------------------------------------

static void process_sys(int oc)
{
     int64_t val;

     NextToken();
     val = expr();
     emit_insn(predicate);
     emit_insn3(
       ((val & 0xFF) << 16) |
       (0xCD << 8) |
       oc
     );
//     emit_insn(oc);
//     emit_insn(0xCD);
//     emit_insn(val);
}

// ----------------------------------------------------------------------------
// chk r1,r2,b32
// ----------------------------------------------------------------------------

static void process_chk(int oc)
{
     int Ra;
     int Br;
     int Rt;
     
     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     need(',');
     Br = getBoundsRegister();
     emit_insn4(
         (oc << 25) |
         (Br << 17) |
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
     prevToken();
}

// ----------------------------------------------------------------------------
// cpuid r1,r2
// ----------------------------------------------------------------------------

static void process_cpuid(int oc)
{
     int Ra;
     int Rt;

     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     emit_insn(predicate);
     emit_insn3(
                (Rt << 14) |
                (Ra << 8)|
                0x41
     );
//     emit_insn(0x41);
//     emit_insn(Ra|(Rt << 6));
//     emit_insn(Rt >> 4);
}

// ---------------------------------------------------------------------------
// JSR also processes JMP
// jmp label[c0]
// jsr c2,label[c0]
// ---------------------------------------------------------------------------

static void process_jsr(int oc)
{
    int64_t addr, disp;
    int Ca, Rb;
    int Ct;

	Ca = 0;
    Ct = getCodeareg();
    if (Ct==-1) {
       Ct = oc==1 ? 0 : 1;
    }
    else {
        need(',');
        NextToken();
    }
    if (oc==15) {
       Ca = 15;
    }
    else {
//         NextToken();
        // Simple [Rn] ?
        if (token=='(' || token=='[') {
           Ca = getCodeareg();
            if (token != ')' && token!=']')
                printf("Missing close bracket\r\n");
        num_insns++;
            emit_insn(predicate);
            emit_insn(0xA0);
            emit_insn((Ca<<4)|Ct);
            return;
        }
//        prevToken();
    }
    NextToken();
    addr = expr();
    prevToken();
    // d(Rn)? 
    if (token=='(' || token=='[' || oc==15) {
        if (oc != 15) {
            NextToken();
            Ca = getCodeareg();
            if (Ca==-1) {
                printf("Illegal jump address mode.\r\n");
                Ca = 0;
            }
        }
        if (Ca==15)
            disp = addr - code_address;            
        else
            disp = addr;
        if ((disp >= -32768 && disp < 32767) || code_bits < 16) {
            if (bGen)
                if (lastsym && !use_gp) {
                    if( lastsym->segment < 5)
                        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT1 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
                }
            num_insns++;
            emit_insn(predicate);
            emit_insn(0xA1);
            emit_insn((Ca<<4)|Ct);
            emit_insn(disp & 0xff);
            emit_insn(disp >> 8);
            return;                     
        }
        if ((disp >= -8388608 && disp < 8388607) || code_bits < 24) {
            if (bGen)
                if (lastsym && !use_gp) {
                    if( lastsym->segment < 5)
                        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT2 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
                }
        num_insns++;
            emit_insn(predicate);
            emit_insn(0xA2);
            emit_insn((Ca<<4)|Ct);
            emit_insn(disp & 0xff);
            emit_insn(disp >> 8);
            emit_insn(disp >> 16);
            return;                     
        }
        emitImm8(disp,code_bits);
        if (bGen)
            if (lastsym && !use_gp) {
                if( lastsym->segment < 5)
                    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT1 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
            }
        num_insns++;
        emit_insn(predicate);
        emit_insn(0xA1);
        emit_insn((Ca<<4)|Ct);
        emit_insn(disp & 0xff);
        emit_insn(disp >> 8);
        return;
    }
    if ((addr >= -32768 && addr < 32767)|| code_bits < 16) {
        if (bGen)
            if (lastsym && !use_gp) {
                if( lastsym->segment < 5)
                    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT1 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
            }
        num_insns++;
       emit_insn(predicate);
       emit_insn(0xA1);
       emit_insn((Ca<<4)|Ct);
       emit_insn(disp & 0xff);
       emit_insn(disp >> 8);
       return;
    }
    if ((addr >= -8388608 && addr < 8388607) || code_bits < 24) {
        if (bGen)
            if (lastsym && !use_gp) {
                if( lastsym->segment < 5)
                    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT2 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
            }
        num_insns++;
        emit_insn(predicate);
        emit_insn(0xA2);
        emit_insn((Ca<<4)|Ct);
        emit_insn(addr & 0xff);
        emit_insn(addr >> 8);
        emit_insn(addr >> 16);
        return;                     
    }
    emitImm8(addr,code_bits);
    if (bGen)
        if (lastsym && !use_gp) {
            if( lastsym->segment < 5)
                sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT1 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
        }
        num_insns++;
    emit_insn(predicate);
    emit_insn(0xA1);
    emit_insn((Ca<<4)|Ct);
    emit_insn(addr & 0xff);
    emit_insn(addr >> 8);
    return;
}

// ---------------------------------------------------------------------------
// subi r1,r2,#1234
// ---------------------------------------------------------------------------

static void process_riop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int64_t val;
    
//    printf("<process_riop>");
    p = inptr;
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    val = expr();
    if (oc==0x4C && Ra == Rt) {
        emitImm10(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    //    emitImm15(val,lastsym!=(SYM*)NULL);
        if (bGen && lastsym && !use_gp)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT4 | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
        emit_insn(predicate);
        emit_insn3(
                   ((val & 0x3ff) << 14)|
                   (Rt << 8)|
                   0x47
        );
//        emit_insn(0x47);
//        emit_insn(Rt|(val << 6));
//        emit_insn(val >> 2);
        return;
    }
    emitImm12(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
//    emitImm15(val,lastsym!=(SYM*)NULL);
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT6 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    emit_insn4((val << 20) | (Rt<<14)|(Ra<<8)|oc);
//    emit_insn(oc);
//    emit_insn(Ra|(Rt << 6));
//    emit_insn((Rt >> 2)|((val &15) << 4));
//    emit_insn(val >> 4);
//    printf("</process_riop>\r\n");
}

// ---------------------------------------------------------------------------
// add r1,r2,r12
// Translates mnemonics without the 'i' suffix that are really immediate.
// ---------------------------------------------------------------------------

static void process_rrop(int op, int func)
{
    int Ra;
    int Rb;
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
        if (op==0x40)
            switch(func) {
            case 0: process_riop(0x48); return;  // addi
            case 1: process_riop(0x49); return;  // subi
            case 2: process_riop(0x4A); return;  // muli
            case 3: process_riop(0x4B); return;  // divi
            case 4: process_riop(0x4C); return;  // addui
            case 5: process_riop(0x4D); return;  // subui
            case 6: process_riop(0x4E); return;  // mului
            case 7: process_riop(0x4F); return;  // divui
            case 8: process_riop(0x6B); return;  // 2addui
            case 9: process_riop(0x6C); return;  // 4addui
            case 10: process_riop(0x6D); return;  // 8addui
            case 11: process_riop(0x6E); return;  // 16addui
            case 0x13: process_riop(0x5B); return;	// modi
            case 0x14:	process_riop(0x5D); return;	// chki
            case 0x17:	process_riop(0x5F); return; // modui
            }
        else if (op==0x50)
            switch(func) {
            case 0:      process_riop(0x53); return; // andi
            case 1:      process_riop(0x54); return; // ori
            case 2:      process_riop(0x55); return; // eori
            }
        else if (op==0x58) {
             process_shifti(0x58,func + 0x10); return;
        }
        return;
    }
    prevToken();
    Rb = getRegisterX();
    prevToken();

    emit_insn(predicate);
    emit_insn4((func << 26)|(Rt << 20)|(Rb << 14)|(Ra << 8)|op);
//    emit_insn(op);
//    emit_insn(Ra|((Rb & 3 )<< 6));
//    emit_insn((Rb >> 2)|((Rt & 15)<<4));
//    emit_insn((func << 2)|(Rt >> 4));
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
static void process_stset(int oc)
{
    int Ra;
    int Rb, Rc;
    int64_t disp;
    int sc;
    int md;
    int sz,dir;

    getSzDir(&sz,&dir);
    seg = 1;
    Rb = getRegisterX();
    need(',');
    NextToken();
//       prevToken();
    mem_operand(&disp, &Ra, &Rc, &sc, &md);
    if (disp!=0 || Rc != -1 || sc != 0)
        printf("%d: illegal memory operand stset.\r\n", lineno);
    if (token==']')
       ;
    emit_insn(predicate);
    if (segmodel==2)
       emit_insn4(
                  (dir << 28) |
                  (sz << 26) |
                  (Rb << 14) |
                  (Ra << 8) |
                  oc
       );
    else
       emit_insn4(
                  (seg << 29) |
                  (dir << 28) |
                  (sz << 26) |
                  (Rb << 14) |
                  (Ra << 8) |
                  oc
       );
//    emit_insn(oc);
//    emit_insn(Ra|((Rb & 3)<<6));
//    emit_insn((Rb >> 2));
//    emit_insn((seg << 5)|(sz << 2)|(dir << 4));
}

// ---------------------------------------------------------------------------
// fabs.d r1,r2
// ---------------------------------------------------------------------------

static void process_fprop(int oc, int fn)
{
    int Ra;
    int Rt;
    char *p;
    int  sz;
    int fmt;

    sz = 'd';
    if (*inptr=='.') {
        inptr++;
        if (strchr("sdtqSDTQ",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal float size.\r\n");
    }
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    prevToken();

    if (sz=='s' || sz=='S')
       oc = 0x79;
    emit_insn(predicate);
    emit_insn3(
               (fn << 20) |
               (Rt << 14) |
               (Ra << 8)|
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ra | (Rt << 6));
//    emit_insn((Rt >> 2)|(fn << 4));
}

// ---------------------------------------------------------------------------
// fadd.d r1,r2,r12
// fdiv.s r1,r3,r10
// ---------------------------------------------------------------------------

static void process_fprrop(int oc, int fn)
{
    int Ra;
    int Rb;
    int Rt;
    int  sz;

    sz = 'd';
    if (*inptr=='.') {
        inptr++;
        if (strchr("sdtqSDTQ",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal float size.\r\n");
    }
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    Rb = getRegisterX();
//    if (token==',')
//       rm = getFPRoundMode();
    prevToken();
    if (sz=='s' || sz=='S')
       fn = fn + 0x10;
    emit_insn(predicate);
    emit_insn4(
               (fn << 26) |
               (Rt << 20) |
               (Rb << 14) |
               (Ra << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ra|(Rb << 6));
//    emit_insn((Rb >> 2)|(Rt << 4));
//    emit_insn((Rt >> 4)|(fn << 2));
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
    Ra = getRegister();
    if (token==',') {
       NextToken();
       bits = expr();
    }
    prevToken();
    emitAlignedCode(0x01);
    emit_insn4(
               ((bits & 0xFF) << 14)|
               (Ra << 8) |
               oc
    );
//    emit_insn(Ra);
//    emit_insn(bits & 0xff);
//    emit_insn(0x00);
//    emit_insn(oc);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

static void process_rop(int oc, int fn)
{
    int Ra;
    int Rt;

    Rt = getRegister();
    need(',');
    Ra = getRegister();
    prevToken();
    emit_insn(predicate);
    emit_insn3(
               (fn << 20) |
               (Rt << 14) |
               (Ra << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ra|(Rt << 6));
//    emit_insn((Rt >> 2)|(fn << 4));
}

// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_br(int oc)
{
    int64_t val;
    int64_t disp;
    int64_t ad;
    char *nm;

    val = 0;
    NextToken();
    val = expr();
     // ToDo: modify the fixup record type based on the number of prefixes emitted.
    if (bGen && lastsym && (lastsym->isExtern || lastsym->defined==0))
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | FUT_R27 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    ad = code_address + 3;
    disp = (val - ad);
    num_insns++;
    emit_insn(predicate);
    emit_insn(oc|((disp>>8)&15));
    emit_insn(disp & 0xff);
    if (disp >= -2048 && disp < 2047)
       ;
    else if (pass > 4) {
         nm = (char *)0;
         if (lastsym)
                  nm = nmTable.GetName(lastsym->name);
         printf("%d Branch out of range (%s).\r\n", lineno, nm ? nm : "");
         printf("%.300s\r\n", inptr-150);
    }
}


static void process_loop(int oc)
{
    int64_t val;
    int64_t disp;
    int64_t ad;

    val = 0;
    NextToken();
    val = expr();
     // ToDo: modify the fixup record type based on the number of prefixes emitted.
    if (bGen && lastsym && (lastsym->isExtern || lastsym->defined==0))
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | FUT_R27 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    ad = code_address + 3;
    disp = (val - ad);
    num_insns++;
    emit_insn(predicate);
    emit_insn(oc);
    emit_insn(disp & 0xff);
    if ((disp < -128 || disp > 127) && pass > 4)
       printf("%d: loop target too far away.\r\n");
}


// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void getIndexScale(int *sc)
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
// ---------------------------------------------------------------------------
static void process_message()
{
    char buf[200];
    int nn;

    while(*inptr != '"' && *inptr != '\n') inptr++;
    if (*inptr=='\n') { NextToken(); return; }
    nn = 0;
    inptr++;
    while (*inptr != '"' && *inptr != '\n' && nn < 197) {
        buf[nn] = *inptr;
        inptr++;
        nn++;
    }
    buf[nn] = '\0';
    strcat(buf, "\r\n");
    printf(buf);
    ScanToEOL();
}
       
// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// expr[Reg+Reg*sc]
// [Reg]
// [Reg+Reg*sc]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA, int *regB, int *sc, int *md)
{
     int64_t val;
     int8_t ind;

     ind = false;

     // chech params
     if (disp == (int64_t *)NULL)
         return;
     if (regA == (int *)NULL)
         return;
     if (regB == (int *)NULL)
         return;
     if (sc==(int *)NULL)
         return;
     if (md==(int *)NULL)
         return;

     *disp = 0;
     *regA = -1;
     *regB = -1;
     *sc = 0;
     if (token==tk_zs) {
        seg = 0;
        NextToken();
     }
     else if (token==tk_ds) {
         seg = 1;
         NextToken();
     }
     else if (token==tk_es) {
         seg = 2;
         NextToken();
     }
     else if (token==tk_fs) {
         seg = 3;
         NextToken();
     }
     else if (token==tk_gs) {
         seg = 4;
         NextToken();
     }
     else if (token==tk_hs) {
         seg = 5;
         NextToken();
     }
     else if (token==tk_ss) {
         seg = 6;
         NextToken();
     }
     else if (token==tk_cs) {
         seg = 7;
         NextToken();
     }
     if (token!='[') {;
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegisterX();
         // Memory indirect ?
         if (*regA == -1) {
             ind = true;
             prevToken();
             *disp = expr();
             if (token=='[') {
                 *regA = getRegisterX();
                 need(']');
                 if (*regA==-1)
                     printf("expecting a register\r\n");
                 NextToken();
             }
             else
                 *regA = 0;
             need(']');
             NextToken();
             if (token=='[') {
                 *regB = getRegisterX();
                 if (*regB==-1)
                     printf("expecting a register\r\n");
                 if (token=='*')
                     getIndexScale(sc);
                 need(']');
             }
             NextToken();
             if (token=='+') {
                 NextToken();
                 if (token=='+') {
                     *md = 7;
                     return;
                 }
             }
             else if (token=='-') {
                  NextToken();
                  if (token=='-') {
                      *md = 6;
                      return;
                  }
             }
             *md = 5;
             return;
         }
         if (token=='+') {
              *sc = 0;
              *regB = getRegisterX();
              if (*regB == -1) {
                  printf("expecting a register\r\n");
              }
              if (token=='*') {
                  getIndexScale(sc);
              }
         }
         need(']');
         if (token=='+') {
             NextToken();
             if (token=='+') {
                 *md = 3;
                 return;
             }
         }
         else if (token=='-') {
              NextToken();
              if (token=='-') {
                  *md = 2;
                  return;
              }
         }
         *md = 1;
     }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
static void setSegAssoc(int Ra)
{
   if (seg < 0) {
       if (Ra==26 || Ra==27)
          seg = 6;
       else if (Ra==31 || Ra==28)
          seg = 0;
       else
          seg = 1;
   }
}

// ---------------------------------------------------------------------------
// sws LC,disp[r1]
// ----------------------------------------------------------------------------

static void process_sws(int oc, int opt)
{
    int Ra;
    int Rb;
    int Rs;
    int sc;
    int md;
    int64_t disp;

    Rs = Thor_getSprRegister();
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    setSegAssoc(Ra);
    if (Rs < 0) {
        if (opt)
            printf("%d: Expecting a source register.\r\n", lineno);
        else
            printf("%d: Expecting a special purpose source register.\r\n", lineno);
        ScanToEOL();
        //inptr -= 2;
        return;
    }
    if (Rb >= 0) {
       printf("%d: unsupported address mode.\r\n", lineno);
        ScanToEOL();
       return;
    }
    Rs &= 0x3f;
    if (segmodel==2)
        emitImm12(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    else
        emitImm9(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (Ra < 0) Ra = 0;
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT5 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    if (segmodel==2)
       emit_insn4((disp << 20)|(Rs<<14)|(Ra << 8)|oc);
    else
       emit_insn4((seg << 29)|((disp & 0x1FF) << 20)|(Rs<<14)|(Ra << 8)|oc);
//    emit_insn(oc);
//    emit_insn(Ra | ((Rs & 3) << 6));
//    emit_insn((Rs >> 2)|((disp & 15) << 4));
//    if (segmodel==2)
//        emit_insn(disp >> 4);
//    else
//        emit_insn(((disp >> 4) & 31)|(seg << 5));
    ScanToEOL();
}

// ---------------------------------------------------------------------------
// sw disp[r1],r2
// sw [r1+r2],r3
// ----------------------------------------------------------------------------

static void process_store(int oc)
{
    int Ra;
    int Rb;
    int Rs;
    int sc;
    int md;
    int64_t disp;

    if (oc==0x94 || oc==0x95)
        Rs = getFPRegister();
    else
        Rs = getRegisterX();
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    setSegAssoc(Ra);
    if (Rs < 0) {
        if (oc==0x93) {
            process_sws(0x9E,1);
            return;
        }
        printf("Expecting a source register.\r\n");
        ScanToEOL();
        return;
    }
    if (Rb > 0) {
       if (disp != 0)
           printf("%d: displacement not supported with indexed mode.\r\n", lineno);
       emit_insn(predicate);
//       emit_insn(oc+0x30);
//       emit_insn(Ra|((Rb & 3)<<6));
//       emit_insn((Rb >> 2)|((Rs & 15) << 4));
//       emit_insn((Rs >> 4)|(sc << 2)|(seg << 5));
      if (segmodel==2)
         emit_insn4((sc<<26)|(Rs<<20)|(Rb<<14)|(Ra<<8)|(oc+0x30));
      else
         emit_insn4((seg << 29)|(sc<<26)|(Rs<<20)|(Rb<<14)|(Ra<<8)|(oc+0x30));
       ScanToEOL();
       return;
    }
    Rb = 0;
    if (segmodel==2)
        emitImm12(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    else
        emitImm9(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (Ra < 0) Ra = 0;
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT5 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    if (segmodel==2)
       emit_insn4((disp << 20)|(Rs<<14)|(Ra << 8)|oc);
    else
       emit_insn4((seg << 29)|((disp & 0x1FF) << 20)|(Rs<<14)|(Ra << 8)|oc);
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldis(int oc)
{
    int Rt;
    int64_t val;
    int nn;

    Rt = Thor_getSprRegister();
    Rt &= 0x3f;
    if (Rt==-1) {
        printf("%d: expecting a special purpose register.\r\n", lineno);
        return;
    }
    expect(',');
    val = expr();
    emitImm10(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT4 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    emit_insn3(
               ((val & 0x3FF) << 14) |
               (Rt << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(Rt|(val & 3) << 6);
//    emit_insn((val >> 2) & 0xff);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi(int oc)
{
    int Rt;
    int64_t val;
    int nn;

    Rt = getRegisterX();
    if (Rt==-1) {
        process_ldis(0x9D);
        return;
//        Rt = getFPRegister();
//        oc = 0x1A;
    }
    expect(',');
    val = expr();
    emitImm10(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
//    emitImm15(val,lastsym!=(SYM*)NULL);
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT4 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    emit_insn3(
               ((val & 0x3FF) << 14) |
               (Rt << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(Rt|(val & 3) << 6);
//    emit_insn((val >> 2) & 0xff);
}

// ----------------------------------------------------------------------------
// lws lc,disp[r2]
// ----------------------------------------------------------------------------

static void process_lws(int oc, int opt)
{
    int Ra;
    int Rb;
    int Spr;
    int sc;
    int md;
    char *p;
    int64_t disp;
    int fixup = 5;

    sc = 0;
    p = inptr;
    Spr = Thor_getSprRegister();
    if (Spr < 0) {
        if (opt)
            printf("%d: Expecting a target register %.60s.\r\n", lineno,inptr-30);
        else
            printf("%d: Expecting a special purpose target register.\r\n", lineno);
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        //inptr-=2;
        return;
    }
    Spr &= 0x3F;
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    setSegAssoc(Ra);
    if (Rb >= 0) {
          printf("%d: Address mode not supported.\r\n", lineno);
          return;
    }
    if (segmodel==2)
        emitImm12(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    else
        emitImm9(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (Ra < 0) Ra = 0;
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT5 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
//    emit_insn(oc);
    if (segmodel==2)
       emit_insn4((disp << 20)|(Spr<<14)|(Ra << 8)|oc);
    else
       emit_insn4((seg << 29)|((disp & 0x1FF) << 20)|(Spr<<14)|(Ra << 8)|oc);
//    emit_insn(Ra | ((Spr & 3) << 6));
//    emit_insn((Spr >> 2)|((disp & 15) << 4));
//    if (segmodel==2)
//        emit_insn(disp >> 4);
//    else
//        emit_insn(((disp >> 4) & 31)|(seg << 5));
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// cas r2,disp[r1]
// ----------------------------------------------------------------------------

static void process_load(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    int sc;
    int md;
    char *p;
    int64_t disp;
    int fixup = 5;
    int fn;

    sc = 0;
    p = inptr;
    if (oc==0x87 || oc==0x88)
       Rt = getFPRegister();
    else
        Rt = getRegisterX();
    if (Rt < 0) {
        if (oc==0x86) {     // LW
           process_lws(0x8E,1);
           return;
        }
        printf("Expecting a target register %.60s.\r\n", inptr-30);
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        //inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    setSegAssoc(Ra);
    if (Rb >= 0) {
       if (disp != 0)
           printf("%d: displacement not supported with indexed mode.\r\n", lineno);
       fixup = 11;
       if (oc==0x97 || oc==0x8E) {  //LWS CAS
          printf("%d: Address mode not supported.\r\n", lineno);
          return;
       }
//       if (oc==0x9F) oc = 0x8F;  // LEA
		if (oc==0x4c) {// LEA
			oc = 0x40;
			switch(sc) {
			case 0: fn = 4; break;
			case 1: fn = 8; break;
			case 2: fn = 9; break;
			case 3: fn = 10; break;
			}
			emit_insn(predicate);
			emit_insn4(
			           (fn << 26) |
			           (Rt << 20) |
			           (Rb << 14) |
			           (Ra << 8) |
			           oc
			);
//			emit_insn(oc);
//			emit_insn(Rb|((Ra &3)<<6));
//	        emit_insn((Ra >> 2)|((Rt & 15) << 4));
//           emit_insn((Rt >> 4)|(fn << 2));
	        ScanToEOL();
    	    return;
		}
       emit_insn(predicate);
      if (segmodel==2)
         emit_insn4((sc << 26)|(Rt << 20)|(Rb<<14)|(Ra << 8)|((oc==0x6A || oc==0x4C) ? 0xB8 : oc+0x30));
      else
         emit_insn4((seg << 29)|(sc << 26)|(Rt << 20)|(Rb<<14)|(Ra << 8)|((oc==0x6A || oc==0x4C) ? 0xB8 : oc+0x30));
//       emit_insn((oc==0x6A || oc==0x4C) ? 0xB8 : oc+0x30);
//       emit_insn(Ra|((Rb & 3)<<6));
//       emit_insn((Rb >> 2)|((Rt & 15) << 4));
//       emit_insn((Rt >> 4)|(sc << 2)|(seg << 5));
       ScanToEOL();
       return;
    }
    Rb = 0;
    if (segmodel==2)
       emitImm12(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    else
        emitImm9(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (Ra < 0) Ra = 0;
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT5 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emit_insn(predicate);
    if (segmodel==2)
       emit_insn4((disp << 20)|(Rt<<14)|(Ra << 8)|oc);
    else
       emit_insn4((seg << 29)|((disp & 0x1FF) << 20)|(Rt<<14)|(Ra << 8)|oc);
//    emit_insn(oc);
//    emit_insn(Ra | ((Rt & 3) << 6));
//    emit_insn((Rt >> 2)|((disp & 15) << 4));
//    if (segmodel==2)
//        emit_insn(disp >> 4);
//    else
//        emit_insn(((disp >> 4) & 31)|(seg << 5));
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// jci c1,disp[r2]
// jci c1,[r2+r3]
// ----------------------------------------------------------------------------

static void process_jmpi(int fn)
{
    int Ra;
    int Rb;
    int Rt;
    int sc;
    int md;
    char *p;
    int64_t disp;
    int fixup = 5;

    sc = 0;
    p = inptr;
    Rt = getCodeareg();
    if (Rt < 0) {
        printf("%d: Expecting a target register %.60s.\r\n", lineno, inptr-30);
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        //inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    setSegAssoc(Ra);
    if (Rb >= 0) {
       if (disp != 0)
           printf("%d: displacement not supported with indexed mode.\r\n", lineno);
       fixup = 11;
//       if (oc==0x9F) oc = 0x8F;  // LEA
        num_insns++;
       emit_insn(predicate);
       emit_insn(0xB7);
       emit_insn(Ra|((Rb & 3)<<6));
       emit_insn((Rb >> 2)|((Rt & 15) << 4));
       emit_insn((sc << 2)|(seg << 5)|fn);
       ScanToEOL();
       return;
    }
    Rb = 0;
    emitImm9(disp,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    if (Ra < 0) Ra = 0;
    if (bGen && lastsym && !use_gp)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT5 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
        num_insns++;
    emit_insn(predicate);
    emit_insn(0x8D);
    emit_insn(Ra | ((Rt & 3) << 6));
    emit_insn((Rt >> 2)|((disp & 15) << 4)|(fn<<2));
    emit_insn(((disp >> 4) & 31)|(seg << 5));
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// inc.b -8[bp],#1
// ----------------------------------------------------------------------------

static void process_inc(int oc)
{
    int Ra;
    int Rb;
    int sc;
    int sg;
    int64_t incamt;
    int64_t disp;
    char *p;
    int fixup = 5;
    int neg = 0;
    int  sz;

    sz = 'w';
    if (*inptr=='.') {
        inptr++;
        if (strchr("bchwBCHW",*inptr)) {
            sz = tolower(*inptr);
            inptr++;
        }
        else
            printf("Illegal increment size.\r\n");
    }
    switch(sz) {
    case 'b':  sz = 0; break;
    case 'c':  sz = 1; break;
    case 'h':  sz = 2; break;
    case 'w':  sz = 3; break;
    }
    NextToken();
    p = inptr;
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    setSegAssoc(Ra);
    incamt = 1;
    if (token==']')
       NextToken();
    if (token==',') {
        NextToken();
        incamt = expr();
        prevToken();
    }
    if (Rb >= 0) {
       printf("%d: Indexed mode not supported.\r\n", lineno);
/*
       if (disp < 0)
           printf("inc offset must be greater than zero.\r\n");
       if (disp > 255LL)
           printf("inc offset too large.\r\n");
       oc = 0x6F;  // INCX
       emit_insn(
           ((disp & 0xFF) << 24) |
           (sc << 22) |
           (Rb << 17) |
           ((incamt & 0x1F) << 12) |
           (Ra << 7) |
           oc
       );
*/
       return;
    }
    if (oc==0xC8) neg = 1;
    oc = 0xC7;        // INC
    if (segmodel==2)
       emitImm12(disp,lastsym!=(SYM*)NULL);
    else
       emitImm9(disp,lastsym!=(SYM*)NULL);
    if (Ra < 0) Ra = 0;
    if (neg) incamt = -incamt;
        num_insns++;
    emit_insn(predicate);
    emit_insn(oc);
    emit_insn(Ra | (sz<<6));
    emit_insn(disp << 4);
    if (segmodel==2)
        emit_insn(disp >> 4);
    else
        emit_insn(((disp >> 4) & 0x1f)|(seg << 5));
    emit_insn(incamt);
    ScanToEOL();
}
       
// ----------------------------------------------------------------------------
// push r1
// push #123
// push -8[BP]
// ----------------------------------------------------------------------------

static void process_push(int oc)
{
    int Ra,Rb;
    int64_t val;
    int64_t disp;
    int sc;
    int sg;
    int nn;

    printf("%d push not supported", lineno);
    Ra = -1;
    Rb = -1;
    NextToken();
    if (token=='#' && oc==0x67) {  // Filter to PUSH
       val = expr();
       emitImm15(val,(code_bits > 32 || data_bits > 32) && lastsym!=(SYM *)NULL);
        emit_insn(
            ((val & 0x7FFFLL) << 17) |
            (0x1E << 12) |
            (0x00 << 7) |
            0x65   // PEA
        );
        return;
    }
    prevToken();
    Ra = getRegisterX();
    if (Ra == -1) {
       Ra = Thor_getSprRegister();
       if (Ra==-1)
          printf("%d: unknown register.\r\n");
       Ra |= 0x40;
    }
        num_insns++;
    emit_insn(predicate);
    emit_insn(oc);
    emit_insn(Ra);
    prevToken();
}
 
// ----------------------------------------------------------------------------
// mov r1,r2
// ----------------------------------------------------------------------------

static void process_mov()
{
     int Ra;
     int Rt;
     
     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     emit_insn(predicate);
     emit_insn3(
                (Rt << 14) |
                (Ra << 8) |
                0xA7
     );
//     emit_insn(0xA7);
//     emit_insn(Ra|((Rt << 6)));
//     emit_insn(Rt >> 2);
     prevToken();
}

// ----------------------------------------------------------------------------
// rts
// rts #24
// rtl
// ----------------------------------------------------------------------------

static void process_rts(int oc)
{
     int64_t val,val1;

     val = 0;
     NextToken();
     if (token=='#') {
        val = expr();
     }
     if (val > 15 || val < 0) {
         printf("%d Return point too far.\r\n", lineno);
         return;
     }
     if (val > 0) {
        num_insns++;
        emit_insn(predicate);
        emit_insn(0xA3);
        emit_insn(0x10|val);
     }
     else {
        num_insns++;
         emit_insn(predicate);
         emit_insn(0xF2);
     }
}

// ----------------------------------------------------------------------------
// asli r1,r2,#5
// ----------------------------------------------------------------------------

static void process_shifti(int oc, int fn)
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
     emit_insn(predicate);
     emit_insn4((fn << 26)|
                (Rt << 20)|
                ((val & 0x3F) << 14)|
                (Ra << 8)|
                oc);
/*
     emit_insn(oc);
     emit_insn(Ra|(val << 6));
     emit_insn(((val & 0x3f) >> 2)|(Rt << 4));
     emit_insn((Rt >> 4)|(fn << 2));
*/
     ScanToEOL();
}

// ----------------------------------------------------------------------------
// gran r1
// ----------------------------------------------------------------------------

static void process_gran(int oc)
{
    int Rt;

    Rt = getRegisterX();
        num_insns++;
    emitAlignedCode(0x01);
    emit_insn(0x00);
    emit_insn(Rt);
    emit_insn(0x00);
    emit_insn(oc);
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_mtspr(int oc)
{
    int spr;
    int Ra;
    int Rc;
    int fn = 0;

    SkipSpaces();
    if (*inptr=='!') {
      fn = 0x10;
      inptr++;
    }
    Rc = getRegisterX();
    if (Rc==-1) {
        Rc = 0;
        spr = Thor_getSprRegister();
        spr &= 0x3f;
        if (spr==-1) {
            printf("Line %d: An SPR is needed.\r\n", lineno);
            return;
        }  
    }
    else
       spr = 0;
    need(',');
    Ra = getRegisterX();
    emit_insn(predicate);
    emit_insn3(
               (fn << 20) |
               (spr << 14) |
               (Ra << 8)|
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ra|((spr & 3)<<6));
//    emit_insn(fn | (spr >> 2));
    if (Ra >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_mfspr(int oc)
{
    int spr;
    int Rt;
    int Ra;
    
    Rt = getRegisterX();
    need(',');
    spr = Thor_getSprRegister();
    spr &= 0x3f;
    if (spr==-1) {
        printf("An SPR is needed.\r\n");
        return;
    }  
    emit_insn(predicate);
    emit_insn3(
               (Rt << 14) |
               (spr << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(spr|(Rt << 6));
//    emit_insn(Rt >> 2);
    if (spr >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
static void getSzDir(int *sz, int *dir)
{
    *sz = inptr[0];
    switch(*sz) {
    case 'b': case 'B': *sz = 0; break;
    case 'c': case 'C': *sz = 1; break;
    case 'h': case 'H': *sz = 2; break;
    case 'w': case 'W': *sz = 3; break;
    default: 
             printf("%d bad string size.\r\n", lineno);
             *sz = 0;
    }
    *dir = inptr[1];
    switch(*dir) {
    case 'i': case 'I': *dir = 0; break;
    case 'd': case 'D': *dir = 1; break;
    default:
              printf("%d bad inc/dec indicator.\r\n", lineno);
              *dir = 0;
    }
    inptr += 2;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_stcmp(int oc)
{
    int sz;
    int dir;
    int64_t disp;
    int Ra, Rb, Rc;
    int sc;
    int md;

    if (seg == -1)
       seg = 1;

    getSzDir(&sz,&dir);
    NextToken();
    mem_operand(&disp, &Ra, &Rc, &sc, &md);
    if (disp!=0 || Rc != -1 || sc != 0)
        printf("%d: illegal memory operand - 1.\r\n", lineno);
    if (token==']')
       NextToken();
    need(',');    
    NextToken();
    mem_operand(&disp, &Rb, &Rc, &sc, &md);
    if (disp!=0 || Rc != -1 || sc != 0)
        printf("%d: illegal memory operand - 2.\r\n", lineno);
    if (token==']')
       NextToken();
    need(',');    
    Rc = getRegisterX();
    if (Ra==-1 || Rb==-1 || Rc==-1)
       printf("%d bad register.\r\n");
    emit_insn(predicate);
    if (segmodel==2)
        emit_insn4(
               (dir << 28)|
               (sz << 26)|
               (Rc << 20)|
               (Rb << 14)|
               (Ra << 8)|
               oc
    );
    else
        emit_insn4(
               (seg << 29)|
               (dir << 28)|
               (sz << 26)|
               (Rc << 20)|
               (Rb << 14)|
               (Ra << 8)|
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ra|(Rb << 6));
//    emit_insn((Rb >> 2)|(Rc << 4));
//    emit_insn((Rc >> 4) | (sz << 2) | (dir << 4)|(seg << 5));
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_cmp()
{
    int Pt;
    int Ra;
    int Rb;
    int64_t val;

    Pt = getPredreg();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    if (token=='#') {
       val = expr();                    
        emitImm10(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    //    emitImm15(val,lastsym!=(SYM*)NULL);
        if (bGen && lastsym && !use_gp)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 4 | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
       emit_insn(predicate);
       emit_insn3(
                  ((val & 0x3FF) << 14)|
                  (Ra << 8)|
                  (Pt|0x20)
       );
//       emit_insn(Pt|0x20);
//       emit_insn(Ra|(val << 6));
//       emit_insn(val >> 2);
    }
    else {
        prevToken();
        Rb = getRegisterX();
        emit_insn(predicate);
        emit_insn3(
                   (Rb << 14) |
                   (Ra << 8) |
                   (Pt|0x10)
        );
//        emit_insn(Pt|0x10);
//        emit_insn(Ra|(Rb << 6));
//        emit_insn(Rb >> 2);
        prevToken();
    }
}

static void process_pand(int oc, int fn)
{
    int Bt;
    int Ba;
    int Bb;
    
    Bt = getBitno();
    need(',');
    Ba = getBitno();
    need(',');
    Bb = getBitno();
    if (Bt==-1 || Ba==-1 || Bb==-1)
       printf("%d expecting a bit number.\r\n", lineno);
    emit_insn(predicate);
    emit_insn4(
               (fn << 26) |
               (Bt << 20) |
               (Bb << 14) |
               (Ba << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(Ba|(Bb << 6));
//    emit_insn((Bb >> 2)|(Bt << 4));
//    emit_insn((Bt >> 4)|(fn << 2));
}

static void process_biti(int oc)
{
    int Pt;
    int Ra;
    int Rb;
    int64_t val;

    Pt = getPredreg();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    if (token=='#') {
       val = expr();                    
        emitImm12(val,lastsym!=(SYM*)NULL?(lastsym->segment==codeseg ? code_bits : data_bits):0);
    //    emitImm15(val,lastsym!=(SYM*)NULL);
        if (bGen && lastsym && !use_gp)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | THOR_FUT6 | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
       emit_insn(predicate);
       emit_insn4(
                  ((val & 0xFFF) << 20) |
                  (Pt << 14) |
                  (Ra << 8) |
                  oc
       );
//       emit_insn(oc);
//       emit_insn(Ra|(Pt << 6));
//       emit_insn((Pt>>2)|(val << 4));
//       emit_insn(val >> 4);
    }
    else {
         printf("%d: register mode not supported.\r\n");
        prevToken();
    }
}

static void process_stp(int oc)
{
    int64_t val;

    val = 0;
    NextToken();
    if (token=='#')
       val = expr();
    emit_insn(predicate);
    emit_insn3(
               ((val & 0xFFFF) << 8) |
               oc
    );
//    emit_insn(oc);
//    emit_insn(val);
//    emit_insn(val >> 8);
}

static void process_sync(int oc)
{
    num_insns++;
    emit_insn(predicate);
    emit_insn(oc);
}

static void process_tlb(int oc, int cmd)
{
    int Rb;
    int Tn;

    Rb = 0;
    Tn = 0;
    switch(cmd) {
    case 1:     Rb = getRegisterX(); prevToken(); break;  // TLBPB
    case 2:     Rb = getRegisterX(); prevToken(); break;  // TLBRD
    case 3:     break;       // TLBWR
    case 4:     break;       // TLBWI
    case 5:     break;       // TLBEN
    case 6:     break;       // TLBDIS
    case 7:     {            // TLBRDREG
                Rb = getRegisterX();
                need(',');
                Tn = getTlbReg();
                }
                break;
    case 8:     {            // TLBWRREG
                Tn = getTlbReg();
                need(',');
                Rb = getRegisterX();
                prevToken();
                }
                break;
    case 9:     break;
                                
    }
    emit_insn(predicate);
    emit_insn3(
        (Rb << 16) |
        (cmd << 8) | (Tn << 12) |
        oc
    );
//    emit_insn(oc);
//    emit_insn(cmd|(Tn << 4));
//    emit_insn(Rb);    
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_tst(int fn)
{
    int Pt;
    int Ra;

    if (inptr[0]=='.') {
        ++inptr;
        switch(inptr[0]) {
        case 's': case 'S': fn = 1; break;
        case 'd': case 'D': fn = 2; break;
        default: fn = 0; break;
        }
        inptr++;
    }
    Pt = getPredreg();
    need(',');
    Ra = getRegisterX();
    num_insns++;
    emit_insn(predicate);
    emit_insn(Pt);
    emit_insn(Ra|(fn << 6));    
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void ProcessEOL(int opt)
{
    int nn,mm;
    int first;
    int cc;
    
     //printf("Line: %d\r", lineno);
     expand_flag = 0;
     predicate = 0x01;
     seg = -1;
     segprefix = -1;
     if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
    nn = binstart;
    cc = 8;
    if (segment==codeseg) {
       cc = 12;
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
        fprintf(ofp, "%06LLX ", ca);
        for (mm = nn; nn < mm + cc && nn < sections[segment].index; nn++) {
            fprintf(ofp, "%02X ", sections[segment].bytes[nn]);
        }
        for (; nn < mm + cc; nn++)
            fprintf(ofp, "   ");
        if (first & opt) {
            fprintf(ofp, "\t%.*s\n", inptr-stptr-1, stptr);
            first = 0;
        }
        else
            fprintf(ofp, opt ? "\n" : "; NOP Ramp\n");
        ca += cc;
    }
    // empty (codeless) line
    if (binstart==sections[segment].index) {
        fprintf(ofp, "%41s\t%.*s", "", inptr-stptr, stptr);
    }
    } // bGen
    if (opt) {
       stptr = inptr;
       lineno++;
    }
//    printf("line:%d\r",lineno);
    binstart = sections[segment].index;
    ca = sections[segment].address;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void Thor_processMaster()
{
    int nn,mm;
    int64_t bs1, bs2;

    lineno = 1;
    binndx = 0;
    binstart = 0;
    bs1 = 0;
    bs2 = 0;
    inptr = &masterFile[0];
    stptr = inptr;
    code_address = 0;
    bss_address = 0;
    start_address = 0;
    data_address = 0;
    first_org = 1;
    first_rodata = 1;
    first_data = 1;
    first_bss = 1;
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
    predicate = 0x01;
    seg = -1;
    num_bytes = 0;
    num_insns = 0;
    expand_flag = 0;
    NextToken();
    while (token != tk_eof) {
/*    
    	if (pass > 1) {
    
        printf("\t%.*s\n", inptr-stptr-1, stptr);
        printf("fo:%d %d token=%d\r\n", first_org, lineno, token);
        if (first_org != 1) getchar();
    }
*/  
j_processToken:
//        printf("line: %d, token %d\r\n", lineno, token);
          if (expandedBlock)
             expand_flag = 1;
        switch(token) {
          case '+': expand_flag = 1; break;
        case tk_eol: ProcessEOL(1); break;
        case tk_add:  process_rrop(0x40,0x00); break;
        case tk_addi: process_riop(0x48); break;
        case tk_addu:  process_rrop(0x40,0x04); break;
        case tk_addui: process_riop(0x4C); break;
        case tk_2addu:  process_rrop(0x40,0x08); break;
        case tk_4addu:  process_rrop(0x40,0x09); break;
        case tk_8addu:  process_rrop(0x40,0x0A); break;
        case tk_16addu:  process_rrop(0x40,0x0B); break;
        case tk_2addui:  process_riop(0x6B); break;
        case tk_4addui:  process_riop(0x6C); break;
        case tk_8addui:  process_riop(0x6D); break;
        case tk_16addui:  process_riop(0x6E); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(0x50,0x00); break;
        case tk_andi:  process_riop(0x53); break;
        case tk_asl:  process_rrop(0x58,0x00); break;
        case tk_asli: process_shifti(0x58,0x10); break;
        case tk_asr:  process_rrop(0x58,0x01); break;
        case tk_asri: process_shifti(0x58,0x11); break;
        case tk_begin_expand: expandedBlock = 1; break;
//        case tk_bfextu: process_bitfield(6); break;
        case tk_biti: process_biti(0x46); break;
        case tk_br:  process_br(0x30); break;
        case tk_brk: emit_insn(0x00); break;
        case tk_bsr: process_jsr(15); break;
        case tk_bss:
            if (first_bss) {
                while(sections[segment].address & 4095)
                    emitByte(0x00);
                sections[3].address = sections[segment].address;
                first_bss = 0;
                binstart = sections[3].index;
                ca = sections[3].address;
            }
            segment = bssseg;
            break;
        case tk_byte:  process_db(); break;
        case tk_cas: process_load(0x6C); break;
        case tk_chk: process_rrop(0x40,0x14); break;
        case tk_chki: process_riop(0x5D); break;
        case tk_cli: emit_insn(predicate); emit_insn(0xFA); break;
        case tk_cmp: process_cmp(); break;
        case tk_cmpi: process_cmp(); break;
        case tk_code: process_code(); break;
        case tk_com: process_rop(0xA7,0x0B); break;
        case tk_cpuid: process_cpuid(0x36); break;
        case tk_cs: seg = 7; break;
        case tk_data:
             // Process data declarations as if we are in the rodata segment
             // for initialization data.
             if (isInitializationData) {
                 token = tk_rodata;
                 goto j_processToken;
             }
            if (first_data) {
                while(sections[segment].address & 4095)
                    emitByte(0x00);
                sections[2].address = sections[segment].address;   // set starting address
                first_data = 0;
                binstart = sections[2].index;
                ca = sections[2].address;
            }
            process_data(dataseg);
            break;
        case tk_db:  process_db(); break;
        case tk_dc:  process_dc(); break;
        case tk_dec: process_inc(0xC8); break;
        case tk_dh:  process_dh(); break;
        case tk_dh_htbl:  process_dh_htbl(); break;
        case tk_div: process_rrop(0x40,0x03); break;
        case tk_divi: process_riop(0x4B); break;
        case tk_divu: process_rrop(0x40,0x07); break;
        case tk_divui: process_riop(0x4F); break;
        case tk_ds: seg = 1; break;
        case tk_dw:  process_dw(); break;
        case tk_end: goto j1;
        case tk_end_expand: expandedBlock = 0; break;
        case tk_endpublic: break;
        case tk_enor:  process_rrop(0x50,0x05); break;
        case tk_eor: process_rrop(0x50,0x02); break;
        case tk_eori: process_riop(0x55); break;
        case tk_es: seg = 2; break;
        case tk_extern: process_extern(); break;

        case tk_fabs: process_fprop(0x77,0x05); break;
        case tk_fadd: process_fprrop(0x78,0x08); break;
//        case tk_fcmp: process_fprrop(0x2A); break;
        case tk_fdiv: process_fprrop(0x78,0x0C); break;
        case tk_ftst:   process_tst(2); break;
        case tk_fs: seg = 3; break;
        case tk_gs: seg = 4; break;
        case tk_hs: seg = 5; break;
/*
        case tk_fcx: process_fpstat(0x74); break;
        case tk_fdx: process_fpstat(0x77); break;
        case tk_fex: process_fpstat(0x76); break;
*/
        case tk_fill: process_fill(); break;
        case tk_fix2flt: process_fprop(0x77,0x03); break;
        case tk_flt2fix: process_fprop(0x77,0x02); break;
        case tk_fmov: process_fprop(0x77,0x00); break;
        case tk_fmul: process_fprrop(0x78,0x0A); break;
        case tk_fnabs: process_fprop(0x77,0x08); break;
/*
        case tk_frm: process_fpstat(0x78); break;
        case tk_fstat: process_fprdstat(0x86); break;
        case tk_ftx: process_fpstat(0x75); break;
*/
        case tk_fneg: process_fprop(0x77,0x04); break;
        case tk_fsub: process_fprrop(0x78,0x09); break;

        case tk_gran: process_gran(0x14); break;
        case tk_inc: process_inc(0xC7); break;
//        case tk_int: process_brk(2); break;
  
        case tk_jci:  process_jmpi(1); break;
        case tk_jhi:  process_jmpi(2); break;
        case tk_jmp: process_jsr(1); break;
        case tk_jsf: emit_insn(predicate); emit_insn(0xFE); break;
        case tk_jsr: process_jsr(0); break;

        case tk_lb:  process_load(0x80); break;
        case tk_lbu: process_load(0x81); break;
        case tk_lc:  process_load(0x82); break;
        case tk_lcu: process_load(0x83); break;
        case tk_ldi: process_ldi(0x6F); break;
        case tk_ldis: process_ldis(0x9D); break;

        case tk_lea: process_load(0x4C); break;
//        case tk_leax: process_load(0x4C); break;
        case tk_lfd: process_load(0x51); break;

        case tk_lh:  process_load(0x84); break;
        case tk_lhu: process_load(0x85); break;
        case tk_lla: process_load(0x6A); break;
//        case tk_llax: process_load(0xB8); break;
        case tk_loop: process_loop(0xA4); break;
        case tk_lsr: process_rrop(0x58,0x03); break;
        case tk_lsri: process_shifti(0x58,0x13); break;
        case tk_lvb: process_load(0xAC); break;
        case tk_lvc: process_load(0xAD); break;
        case tk_lvh: process_load(0xAE); break;
        case tk_lvw: process_load(0xAF); break;
        case tk_lw:  process_load(0x86); break;
        case tk_lws: process_lws(0x8E,0); break;
        case tk_lvwar:  process_load(0x8B); break;
        case tk_memdb: process_sync(0xF9); break;
        case tk_memsb: process_sync(0xF8); break;
        case tk_message: process_message(); break;
        case tk_mfspr: process_mfspr(0xA8); break;
        case tk_max: process_rrop(0x40,0x11); break;
        case tk_mod: process_rrop(0x40,0x13); break;
        case tk_modu: process_rrop(0x40,0x17); break;
        case tk_modi: process_riop(0x5B); break;
        case tk_modui: process_riop(0x5F); break;
        case tk_mov: process_mov(); break;
        case tk_mtspr: process_mtspr(0xA9); break;
        case tk_mul: process_rrop(0x40,0x02); break;
        case tk_muli: process_riop(0x4A); break;
        case tk_mulu: process_rrop(0x40,0x06); break;
        case tk_mului: process_riop(0x4E); break;
        case tk_nand:  process_rrop(0x50,0x03); break;
        case tk_neg: process_rop(0xA7,0x01); break;
        case tk_nop: emit_insn(0x10); break;
        case tk_nor:  process_rrop(0x50,0x04); break;
        case tk_not: process_rop(0xA7,0x02); break;
        case tk_or:  process_rrop(0x50,0x01); break;
        case tk_ori: process_riop(0x54); break;
        case tk_org: process_org(); break;
        case tk_pand: process_pand(0x42,0x00); break;
        case tk_por: process_pand(0x42,0x01); break;
        case tk_peor: process_pand(0x42,0x02); break;
        case tk_pnand: process_pand(0x42,0x03); break;
        case tk_pnor: process_pand(0x42,0x04); break;
        case tk_penor: process_pand(0x42,0x05); break;
        case tk_pandc: process_pand(0x42,0x06); break;
        case tk_porc: process_pand(0x42,0x07); break;
        case tk_pop: process_push(0xCA); break;
        case tk_pred:
             if (isdigit(inptr[0]) && isdigit(inptr[1])) {
                  predicate = ((inptr[0]-'0' * 10) + (inptr[1]-'0')) << 4;
                  inptr += 2;
                  if (inptr[0]=='.') inptr++;
                  nn = getPredcon();
                  if (nn >= 0)
                     predicate |= nn;
             }
             else if (isdigit(inptr[0])) {
                  predicate = (inptr[0]-'0') << 4;
                  inptr += 1;
                  if (inptr[0]=='.') inptr++;
                  nn = getPredcon();
                  if (nn >= 0)
                     predicate |= nn;
             }
             SkipSpaces();
             break;
        case tk_public: process_public(); break;
        case tk_push: process_push(0xC8); break;
        case tk_rodata:
            if (first_rodata) {
                while(sections[segment].address & 4095)
                    emitByte(0x00);
                sections[1].address = sections[segment].address;
                first_rodata = 0;
                binstart = sections[1].index;
                ca = sections[1].address;
            }
            segment = rodataseg;
            break;
        case tk_rol: process_rrop(0x58,0x04); break;
        case tk_ror: process_rrop(0x58,0x05); break;
        case tk_roli: process_shifti(0x58,0x14); break;
        case tk_rori: process_shifti(0x58,0x15); break;
        case tk_rte: emit_insn(predicate); emit_insn(0xF3); break;
        case tk_rtf: emit_insn(predicate); emit_insn(0xFD); break;
        case tk_rti: emit_insn(predicate); emit_insn(0xF4); break;
        case tk_rtl: process_rts(0x27); break;
        case tk_rts: process_rts(0x3B); break;
        case tk_sb:  process_store(0x90); break;
//        case tk_sbx:  process_store(0xC0); break;
        case tk_sc:  process_store(0x91); break;
//        case tk_scx:  process_store(0xC1); break;
        case tk_sei: emit_insn(predicate); emit_insn(0xFB); break;
        case tk_sfd: process_store(0x71); break;
        case tk_sh:  process_store(0x92); break;
        case tk_shl:  process_rrop(0x58,0x00); break;
        case tk_shli: process_shifti(0x58,0x10); break;
        case tk_shr:  process_rrop(0x58,0x01); break;
        case tk_shri: process_shifti(0x58,0x11); break;
        case tk_shru:  process_rrop(0x58,0x03); break;
        case tk_shrui: process_shifti(0x58,0x13); break;
//        case tk_shx:  process_store(0xC2); break;
        case tk_ss: seg = 6; break;
        case tk_stcmp: process_stcmp(0x9A); break;
        case tk_stmov: process_stcmp(0x99); break;
        case tk_stp: process_stp(0xF6); break;
        case tk_stset: process_stset(0x98); break;
//        case tk_stsb: process_sts(0x98,0); break;
//        case tk_stsc: process_sts(0x98,1); break;
//        case tk_stsh: process_sts(0x98,2); break;
//        case tk_stsw: process_sts(0x98,3); break;
        case tk_sub:  process_rrop(0x40,0x01); break;
        case tk_subi: process_riop(0x49); break;
        case tk_subu:  process_rrop(0x40,0x05); break;
        case tk_subui: process_riop(0x4D); break;
        case tk_sws: process_sws(0x9E,0); break;
        case tk_sxb: process_rop(0xA7,0x08); break;
        case tk_sxc: process_rop(0xA7,0x09); break;
        case tk_sxh: process_rop(0xA7,0x0A); break;
        case tk_sync: process_sync(0xF7); break;
        case tk_sys: process_sys(0xA5); break;
        case tk_sw:  process_store(0x93); break;
        case tk_swcr:  process_store(0x8C); break;
//        case tk_swx:  process_store(0xC3); break;
        case tk_tlbdis:  process_tlb(0xFFF6F0,6); break;
        case tk_tlben:   process_tlb(0xFFF5F0,5); break;
        case tk_tlbpb:   process_tlb(0x0001F0,1); break;
        case tk_tlbrd:   process_tlb(0x0002F0,2); break;
        case tk_tlbrdreg:   process_tlb(0x0007F0,7); break;
        case tk_tlbwi:   process_tlb(0x0004F0,4); break;
        case tk_tlbwr:   process_tlb(0x0003F0,3); break;
        case tk_tlbwrreg:   process_tlb(0x0008F0,8); break;
        case tk_tst:   process_tst(0); break;
        case tk_xor: process_rrop(0x40,0x02); break;
        case tk_xori: process_riop(0x55); break;
        case tk_id:  process_label(); break;
        case tk_zs:  seg = 0; break;
        case tk_zxb: process_rop(0xA7,0x0C); break;
        case tk_zxc: process_rop(0xA7,0x0D); break;
        case tk_zxh: process_rop(0xA7,0x0E); break;
        }
        NextToken();
    }
j1:
    ;
}

