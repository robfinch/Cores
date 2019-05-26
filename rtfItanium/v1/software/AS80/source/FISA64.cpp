// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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

#define BCC(x)       (((x) << 12)|0x38)

// Fixup types
#define FUT_C15       1
#define FUT_C40       2
#define FUT_C64       3
#define FUT_R27       4


static void emitAlignedCode(int cd);
static void process_shifti(int oc);
static void ProcessEOL(int opt);

extern int first_rodata;
extern int first_data;
extern int first_bss;
static int64_t ca;
extern int isInitializationData;
extern int use_gp;

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
            return 27;
        }
        break;
    case 'g': case 'G':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 26;
        }
        break;
    case 's': case 'S':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 30;
        }
        break;
    case 't': case 'T':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 25;
        }
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 24;
        }
        break;
    case 'p': case 'P':
        if ((inptr[1]=='c' || inptr[1]=='C') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 29;
        }
        break;
    case 'l': case 'L':
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 31;
        }
        break;
    case 'x': case 'X':
        if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='r' || inptr[2]=='R') &&
        !isIdentChar(inptr[3])) {
            inptr += 3;
            NextToken();
            return 28;
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

static int FISA64_getSprRegister()
{
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
         return (int)ival.low;

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
    // cas clk cr0 cr3
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
         break;

    // dbad0 dbad1 dbctrl dpc dsp
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
         break;

    // ea epc esp
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
         break;

    // fault_pc
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


    // LOTGRP
    case 'l': case 'L':
         if ((inptr[1]=='o' || inptr[1]=='O') &&
             (inptr[2]=='t' || inptr[2]=='T') &&
             (inptr[3]=='g' || inptr[3]=='G') &&
             (inptr[4]=='r' || inptr[4]=='R') &&
             (inptr[5]=='p' || inptr[5]=='P') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 42;
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
    // ss_ll srand1 srand2
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
         break;

    // tag tick 
    case 't': case 'T':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             (inptr[3]=='k' || inptr[3]=='K') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 4;
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
    }
    return -1;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int64_t oc)
{
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
     num_bytes += 4;
     num_insns += 1;
}
 
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn2(int64_t oc)
{
     emitCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
     num_bytes += 4;
     num_insns += 1;
}
 

static void emit2(int64_t oc)
{
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     num_bytes += 2;
     num_insns += 1;
}
 
static void emit6(int64_t oc)
{
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
     emitCode((oc >> 32) & 255);
     emitCode((oc >> 40) & 255);
     num_bytes += 6;
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

static int fitsIn10(int64_t v)
{
    return (((v < 0) && ((v >> 24) == -1L)) || ((v >= 0) && ((v >> 24) == 0)));
}

static int fitsIn28(int64_t v)
{
    return (((v < 0) && ((v >> 42) == -1L)) || ((v >= 0) && ((v >> 42) == 0)));
}

static int fitsIn41(int64_t v)
{
    return (((v < 0) && ((v >> 55) == -1L)) || ((v >= 0) && ((v >> 55) == 0)));
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
    sections[segment+7].AddRel(sections[segment].index,((int64_t)(lastsym->ord+1) << 32) | nn+1 | (lastsym->isExtern ? 128 : 0)|
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
    mb = (int)expr();
    need(',');
    NextToken();
    me = (int)expr();
    emit_insn(
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

static void process_brk(int oc)
{
    int val;

    NextToken();
    val = (int)expr();
    emit_insn(
        (oc << 30) |
        ((val & 0x1ff) << 17) |
        (30 << 7) |
        0x38
    );
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
     emit_insn(
         (oc << 25) |
         (Br << 17) |
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
     prevToken();
}

// ---------------------------------------------------------------------------
// COM is an alternate mnemonic for EOR Rt,Ra,#-1
// com r3,r3
// ---------------------------------------------------------------------------

static void process_com()
{
    int Ra;
    int Rt;

    Rt = getRegister();
    need(',');
    Ra = getRegister();
    prevToken();
    emit_insn(
        (0x7fff << 17) |
        (Rt << 12) |
        (Ra << 7) |
        0x0e           // EOR
    );
}

// ----------------------------------------------------------------------------
// cpuid r1,r2,#0
// ----------------------------------------------------------------------------

static void process_cpuid(int oc)
{
     int Ra;
     int Rt;
     int val;

     Rt = getRegisterX();
     need(',');
     Ra = getRegisterX();
     need(',');
     NextToken();
     val = (int)expr();
     emit_insn(
         (oc << 25) | 
         ((val & 15) << 17) |
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
     prevToken();
}

// ---------------------------------------------------------------------------
// JAL also processes JMP and JSR
// jal r0,main
// jal r0,[r19]
// jmp (tbl,r2)
// ---------------------------------------------------------------------------

static void process_jal(int oc, int Rt)
{
    int64_t addr;
    int Ra;
    
    // -1 indicates to parse a target register
    if (Rt == -1) {
        Rt = getRegisterX();
        if (Rt==-1) {
            printf("Expecting a target register.");
            return ;
        }
        need(',');
    }
    NextToken();
    // Memory indirect ?
    if (token=='(' || token=='[') {
       Ra = getRegisterX();
       if (Ra==-1) {
           Ra = 0;
           NextToken();
           addr = expr();
           prevToken();
           if (token==',') {
               NextToken();
               Ra = getRegisterX();
               if (Ra==-1) Ra = 0;
           }
           else if (token=='[') {
                NextToken();
               Ra = getRegisterX();
               if (Ra==-1) Ra = 0;
               need(']');
               NextToken();
           }
           if (token!=')' && token != ']')
               printf("Missing close bracket.\r\n");
           emitImm15(addr,lastsym!=(SYM*)NULL);
           emit_insn(
               ((addr & 0x7fffLL) << 17) |
               (Rt << 12) |
               (Ra << 7) | 
               0x3e
           );
           return;
       }
       // Simple [Rn]
       else {
            if (token != ')' && token!=']')
                printf("Missing close bracket\r\n");
            emit_insn(
                (Rt << 12) |
                (Ra << 7) |
                0x3C
            );
            return;
       }
    }
    addr = expr() >> 1;
    prevToken();
    // d(Rn)? 
    if (token=='(' || token=='[') {
        NextToken();
        Ra = getRegisterX();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
        emitImm15(addr,0);
        emit_insn(
            ((addr & 0x7fffLL) << 17) |
            (Rt << 12) |
            (Ra << 7) | 
            0x3C
        );
        return;
    }
    emitImm15(addr, code_bits > 32);
    emit_insn(
        ((addr & 0x7fffLL) << 17) |
        (Rt << 12) |
        0x3C
    );
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
    
    p = inptr;
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    NextToken();
    val = expr();
    emitImm15(val,lastsym!=(SYM*)NULL);
    if (oc == 0x14 && Ra==Rt && val >= 0 && val <= 15) {
        emit2(
            ((val & 15) << 12) |
            (Ra << 7) |
            0x22
        );
    }
    else if (oc==0x15 && Ra==30 && Rt==30 && val >=0 && val < 4096 && (val &7)==0) {
        emit2(
            (((val >> 3)&0x1ff) << 7) |
            0x25
        );
    }
    else
        emit_insn(
            ((val & 0x7fff) << 17) |
            (Rt << 12) |
            (Ra << 7) |
            oc
        );
}

// ---------------------------------------------------------------------------
// add r1,r2,r12
// ---------------------------------------------------------------------------

static void process_rrop(int oc)
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
        switch(oc & 0x7F) {
        case 4: process_riop(4); return;  // add
        case 5: process_riop(5); return;  // sub
        case 6: process_riop(6); return;  // cmp
        case 7: process_riop(7); return;  // mul
        case 8: process_riop(8); return;  // div
        case 9: process_riop(9); return;  // mod
        case 12: process_riop(12); return;  // and
        case 13: process_riop(13); return;  // or
        case 14: process_riop(14); return;  // eor
        case 0x14: process_riop(0x14); return;  // addu
        case 0x15: process_riop(0x15); return;  // subu
        case 0x16: process_riop(0x16); return;  // cmpu
        case 0x17: process_riop(0x17); return;  // mulu
        case 0x18: process_riop(0x18); return;  // divu
        case 0x19: process_riop(0x19); return;  // modu
        // Shift
        case 0x30:
        case 0x31:
        case 0x32:
        case 0x33:
        case 0x34:
             process_shifti((oc & 0x7F) + 8); return;
        default:    process_riop(oc); return;
        }
        return;
    }
    prevToken();
    Rb = getRegisterX();
    prevToken();
    emit_insn(
              ((oc & 0x7f) << 25) |
//              ((oc >> 6) << 31) | // for shifts
              (Rb << 17) |
              (Rt << 12) |
              (Ra << 7)|
              2
    );
}

// ---------------------------------------------------------------------------
// fabs.d fp1,fp2[,rm]
// ---------------------------------------------------------------------------

static void process_fprop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int  sz;
    int fmt;
    int rm;

    rm = 0;
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
    p = inptr;
    if (oc==0x65 || oc==0x66)  // mffp, mv2fix
        Rt = getRegister();
    else
        Rt = getFPRegister();
    need(',');
    if (oc==0x1C || oc==0x1D)  // mtfp, mv2flt
        Ra = getRegister();
    else     
        Ra = getFPRegister();
    if (token==',')
       rm = getFPRoundMode();
    prevToken();
    
    switch(sz) {
    case 's': fmt = 0; break;
    case 'd': fmt = 1; break;
    case 't': fmt = 2; break;
    case 'q': fmt = 3; break;
    }
    emit_insn(
        (oc << 25) |
        (fmt << 20) |
        (rm << 17) |
        (Rt << 12) |
        (Ra << 7) |
        0x02
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
    int  sz;
    int fmt;
    int rm;

    rm = 0;
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
    p = inptr;
    if (oc==0x2A)        // fcmp
        Rt = getRegister();
    else
        Rt = getFPRegister();
    need(',');
    Ra = getFPRegister();
    need(',');
    Rb = getFPRegister();
    if (token==',')
       rm = getFPRoundMode();
    prevToken();
    switch(sz) {
    case 's': fmt = 0; break;
    case 'd': fmt = 1; break;
    case 't': fmt = 2; break;
    case 'q': fmt = 3; break;
    }
    emit_insn(
        (fmt << 25) |
        (rm << 22) |
        (Rb << 17) |
        (Rt << 12) |
        (Ra << 7) |
        oc
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
    Ra = getRegister();
    if (token==',') {
       NextToken();
       bits = expr();
    }
    prevToken();
    emitAlignedCode(0x01);
    emitCode(Ra);
    emitCode(bits & 0xff);
    emitCode(0x00);
    emitCode(oc);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

static void process_rop(int oc)
{
    int Ra;
    int Rt;

    Rt = getRegister();
    need(',');
    Ra = getRegister();
    prevToken();
    emit_insn(
        (oc << 25) |
        (Rt << 12) |
        (Ra << 7) |
        0x02
    );
}

// ---------------------------------------------------------------------------
// beq r1,label
// ---------------------------------------------------------------------------

static void process_bcc(int oc)
{
    int Ra;
    int64_t val;
    int64_t disp,disp1;
    int64_t ad;

    val = 0;
    Ra = getRegisterX();
    need(',');
    NextToken();
    val = expr();
    ad = code_address;
    disp1 = ((val - ad) >> 1);
    disp = ((val - ad) >> 1) & 0x7fffLL;

    if ((oc == 0 || oc==1) && disp1 != 0 && disp1 >= -8 && disp1 <= 7) {
       emit2(
           ((disp & 15) << 12) |
           (Ra << 7) |
           (oc ? 0x33 : 0x32)
       );           
    }
    else

        emit_insn(
            (disp << 17) |
            (oc << 12) |
            (Ra << 7) |
            0x3D
        );
}

// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int oc)
{
    int64_t val;
    int64_t disp,disp1;
    int64_t ad;

    val = 0;
    NextToken();
    val = expr();
     // ToDo: modify the fixup record type based on the number of prefixes emitted.
    if (bGen && lastsym && (lastsym->isExtern || lastsym->defined==0))
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((int64_t)(lastsym->ord+1) << 32) | FUT_R27 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    ad = code_address;
    disp1 = ((val - ad) >> 1);
    disp = ((val - ad) >> 1) & 0x1ffffffLL;
    if (disp1 >= -256 && disp1 <= 255 && disp1 != 0 && oc==0x3A)
       emit2(
            ((disp1 & 0x1ff) << 7) |
            0x23
       );
    else
        emit_insn(
            (disp << 7) |
            (oc & 0x7f)
        );
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
    strcat_s(buf, sizeof(buf), "\r\n");
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

    if (oc==0x71)
        Rs = getFPRegister();
    else
        Rs = getRegisterX();
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    if (Rs < 0) {
        printf("Expecting a source register.\r\n");
        ScanToEOL();
        return;
    }
    if (Rb > 0) {
       if (disp < 0)
           printf("store offset must be greater than zero.\r\n");
       if (disp > 255LL)
           printf("store offset too large.\r\n");
        emit_insn(
            ((disp & 0xff) << 24) |
            (sc << 22) |
            (Rb << 17) |
            (Rs << 12) |
            (Ra << 7) |
            (oc==0x71 ? 0x75 : oc+8)
        );
       return;
    }
    emitImm15(disp,lastsym!=(SYM*)NULL);
    if (Ra < 0) Ra = 0;
    // Convert SW Rn,D[BP] to short form
    if (oc==0x63 && Ra==27 && ((disp & 0x7)==0) && ((disp >> 3) >= -8) && ((disp >> 3) <= 7)) {
        emit2(
           (((disp >> 3) & 0x0f) << 12) |
           (Rs << 7) |
           0x67
        );
    }
    else
        emit_insn(
            ((disp & 0x7fff) << 17) |
            (Rs << 12) |
            (Ra << 7) |
            oc
        );
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi(int oc)
{
    int Rt;
    int64_t val;

    Rt = getRegisterX();
    if (Rt==-1) {
        Rt = getFPRegister();
        oc = 0x1A;
    }
    expect(',');
    val = expr();
    emitImm15(val,lastsym!=(SYM*)NULL);

    if (val <= 7 && val >= -8)
       emit2(
           ((val & 15) << 12) |
           (Rt << 7) |
           0x34
       );
    else

        emit_insn(
            ((val & 0x7FFFLL) << 17) |
            (Rt << 12) |
            oc
        );
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

    sc = 0;
    p = inptr;
    if (oc==0x51)
       Rt = getFPRegister();
    else
        Rt = getRegisterX();
    if (Rt < 0) {
        printf("Expecting a target register.\r\n");
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &md);
    if (Rb >= 0) {
       if (disp < 0)
           printf("load offset must be greater than zero.\r\n");
       if (disp > 255LL)
           printf("load offset too large.\r\n");
       fixup = 11;
       if (oc==0x87 || oc==0x6c) {  //LWS CAS
          printf("Address mode not supported.\r\n");
          return;
       }
       if (oc==0x9F) oc = 0x8F;  // LEA
       else oc = oc + 8;
        emit_insn(
            ((disp & 0xff) << 24) |
            (sc << 22) |
            (Rb << 17) |
            (Rt << 12) |
            (Ra << 7) |
            oc
        );
       return;
    }
    emitImm15(disp,lastsym!=(SYM*)NULL);
    if (Ra < 0) Ra = 0;
    // Convert LW Rn,D[BP] to short form
    if (oc==0x46 && Ra==27 && ((disp & 0x7)==0) && ((disp >> 3) >= -8) && ((disp >> 3) <= 7)) {
        emit2(
           (((disp >> 3) & 0x0f) << 12) |
           (Rt << 7) |
           0x5F
        );
    }
    else
        emit_insn(
            ((disp & 0x7ffff) << 17) |
            (Rt << 12) |
            (Ra << 7) |
            oc
        );
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// inc -8[bp],#1
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

    NextToken();
    p = inptr;
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    incamt = 1;
    if (token==']')
       NextToken();
    if (token==',') {
        NextToken();
        incamt = expr();
        prevToken();
    }
    if (Rb >= 0) {
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
       return;
    }
    if (oc==0x65) neg = 1;
    oc = 0x64;        // INC
    emitImm15(disp,lastsym!=(SYM*)NULL);
    if (Ra < 0) Ra = 0;
    if (neg) incamt = -incamt;
    emit_insn(
        ((disp & 0x7FFF) << 17) |
        ((incamt & 0x1F) << 12) |
        (Ra << 7) |
        oc
    );
    ScanToEOL();
}
       
// ----------------------------------------------------------------------------
// pea disp[r2]
// pea [r2+r3]
// ----------------------------------------------------------------------------

static void process_pea()
{
    int oc;
    int Ra;
    int Rb;
    int sc;
    int sg;
    char *p;
    int64_t disp;
    int fixup = 5;

    p = inptr;
    NextToken();
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    if (Rb >= 0) {
       // For now PEAX isn't supported
       printf("PEA: Illegal address mode.\r\n");
       return;
       fixup = 11;
       oc = 0xB9;  // PEAX
        if (bGen && lastsym && Ra != 249 && !use_gp)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((int64_t)(lastsym->ord+1) << 32) | fixup | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
       emitCode(Ra);
       emitCode(Rb);
       emitCode(0x00);
       emitCode(sc | ((sg & 15) << 2));
       return;
    }
    oc = 0x65;        // PEA
    emitImm15(disp,lastsym!=(SYM*)NULL);
    if (Ra < 0) Ra = 0;
    emit_insn(
        ((disp & 0x7FFFLL) << 17) |
        (0x1E << 12) |
        (Ra << 7) |
        oc
    );
    ScanToEOL();
}


// ----------------------------------------------------------------------------
// push r1
// push #123
// push -8[BP]
// ----------------------------------------------------------------------------

static void process_pushpop(int oc)
{
    int Ra,Rb;
    int64_t val;
    int64_t disp;
    int sc;
    int sg;

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
        NextToken();
        mem_operand(&disp, &Ra, &Rb, &sc, &sg);
        emitImm15(disp,(code_bits > 32 || data_bits > 32) && lastsym!=(SYM *)NULL);
        if (Ra==-1) Ra = 0;
        emit_insn(
            ((disp & 0x7FFFLL) << 17) |
            (0x1E << 12) |
            (Ra << 7) |
            0x66
        );
        ScanToEOL();
        return;
    }
    if (oc==0x57) { // POP

        emit2(
           (2 << 12) |
           (Ra << 7) |
           0x31
        );
/*

        emit_insn(
            (8 << 17) |
            (Ra << 12) |
            (0x1E << 7) |
            oc
        );
*/
        prevToken();
        return;
    }
    //PUSH

    emit2(
       (Ra << 7) |
       0x31
    );
/*
    emit_insn(
        (0x1E << 12) |
        (Ra << 7)
        | oc
    );
*/
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
     emit2(
           ((Rt & 0xf) << 12) |
           (Ra << 7) |
           0x20 | ((Rt >> 4) & 1)
     );
/*
     emit_insn(
         (0x0D << 25) | // OR
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
*/
     prevToken();
}

// ----------------------------------------------------------------------------
// neg r1,r2
// ----------------------------------------------------------------------------

static void process_neg(int oc)
{
     int Ra;
     int Rb;
     int Rt;
     
     Ra = 0;
     Rt = getRegisterX();
     need(',');
     Rb = getRegisterX();
     emit_insn(
         (oc << 25) | // SUBU
         (Rb << 17) |
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
     prevToken();
}

// ----------------------------------------------------------------------------
// sei
// cli
// rtd
// rte
// rti
// ----------------------------------------------------------------------------

static void process_pctrl(int oc)
{
     int Rt;

     if (oc==29 || oc==30 || oc==31)
         Rt = 30;
     else
         Rt = 0;
     emit_insn(
         (0x37 << 25) |
         (oc << 17) |
         (Rt << 12) |
         0x02
     );
}

// ----------------------------------------------------------------------------
// rts
// rts #24
// rtl
// ----------------------------------------------------------------------------

static void process_rts(int oc)
{
     int64_t val;

     val = oc==0x3B ? 8 :0;
     NextToken();
     if (token=='#') {
        val = expr();
     }
     emitImm15(val,(code_bits > 32 || data_bits > 32) && lastsym!=(SYM *)NULL);
     if (val < 4096)
         emit2(
             (((val>>3) & 0x1FFLL) << 7) |
             ((oc==0x27) ? 0x37 : 0x30)
         );
     else
         emit_insn(
             ((val & 0x7FFFLL) << 17) |
             (0x1F << 12) |
             (0x1E << 7) |
             oc
         );
}

// ----------------------------------------------------------------------------
// asli r1,r2,#5
// ----------------------------------------------------------------------------

static void process_shifti(int oc)
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
     emit_insn(
         (oc << 25) |      
         ((val & 63) << 17) |
         (Rt << 12) |
         (Ra << 7) |
         0x02
     );
}

// ----------------------------------------------------------------------------
// gran r1
// ----------------------------------------------------------------------------

static void process_gran(int oc)
{
    int Rt;

    Rt = getRegisterX();
    emitAlignedCode(0x01);
    emitCode(0x00);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_mtspr(int oc)
{
    int spr;
    int Ra;
    int Rc;
    
    Rc = getRegisterX();
    if (Rc==-1) {
        Rc = 0;
        spr = FISA64_getSprRegister();
        if (spr==-1) {
            printf("Line %d: An SPR is needed.\r\n", lineno);
            return;
        }  
    }
    else
       spr = 0;
    need(',');
    Ra = getRegisterX();
    emit_insn(
        (oc << 25) |
        (spr << 17) |
        (Rc << 12) |
        (Ra << 7) |
        0x02
    );
    if (Ra >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_mtfp(int oc)
{
    int fpr;
    int Ra;
    
    fpr = getFPRegister();
    need(',');
    Ra = getRegisterX();
    emitAlignedCode(0x01);
    emitCode(Ra);
    emitCode(fpr);
    emitCode(0x00);
    emitCode(oc);
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
    Ra = getRegisterX();
    if (Ra==-1) {
        Ra = 0;
        spr = FISA64_getSprRegister();
        if (spr==-1) {
            printf("An SPR is needed.\r\n");
            return;
        }  
    }
    else
        spr = 0;
    emit_insn(
        (oc << 25) |
        (spr << 17) |
        (Rt << 12) |
        (Ra << 7) |
        0x02
    );
    if (spr >= 0)
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
    emitAlignedCode(0x01);
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
    emitAlignedCode(0x01);
    emitCode(0x00);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void ProcessEOL(int opt)
{
    int mm;
    int first;
    int cc;
	int64_t nn;
    
     //printf("Line: %d\r", lineno);
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

void FISA64_processMaster()
{
    int nn;
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
    NextToken();
    while (token != tk_eof) {
//        printf("\t%.*s\n", inptr-stptr-1, stptr);
//        printf("token=%d\r", token);
j_processToken:
        switch(token) {
        case tk_eol: ProcessEOL(1); break;
        case tk_add:  process_rrop(0x04); break;
        case tk_addi: process_riop(0x04); break;
        case tk_addu:  process_rrop(0x14); break;
        case tk_addui: process_riop(0x14); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(12); break;
        case tk_andi:  process_riop(12); break;
        case tk_asl:  process_rrop(0x30); break;
        case tk_asli: process_shifti(0x38); break;
        case tk_asr:  process_rrop(0x34); break;
        case tk_asri: process_shifti(0x3C); break;
        case tk_beq: process_bcc(0); break;
        case tk_bfextu: process_bitfield(6); break;
        case tk_bge: process_bcc(3); break;
        case tk_bgt: process_bcc(2); break;
        case tk_ble: process_bcc(5); break;
        case tk_blt: process_bcc(4); break;
        case tk_bmi: process_bcc(4); break;
        case tk_bne: process_bcc(1); break;
        case tk_bpl: process_bcc(3); break;
        case tk_bra: process_bra(0x3A); break;
        case tk_bsr: process_bra(0x39); break;
//        case tk_bsr: process_bra(0x56); break;
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
        case tk_chk: process_chk(0x1A); break;
        case tk_cli: process_pctrl(0); break;
        case tk_cmp: process_rrop(0x06); break;
        case tk_cmpu: process_rrop(0x16); break;
        case tk_code: process_code(); break;
        case tk_com: process_com(); break;
        case tk_cpuid: process_cpuid(0x36); break;
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
        case tk_dec: process_inc(0x65); break;
        case tk_dh:  process_dh(); break;
        case tk_div: process_rrop(0x08); break;
        case tk_divu: process_rrop(0x18); break;
        case tk_dw:  process_dw(); break;
        case tk_end: goto j1;
        case tk_endpublic: break;
        case tk_eor: process_rrop(0x0E); break;
        case tk_eori: process_riop(0x0E); break;
        case tk_extern: process_extern(); break;

        case tk_fabs: process_fprop(0x64); break;
        case tk_fadd: process_fprrop(0x28); break;
        case tk_fcmp: process_fprrop(0x2A); break;
        case tk_fdiv: process_fprrop(0x2C); break;
        case tk_mffp: process_fprop(0x65); break;
        case tk_mv2fix: process_fprop(0x66); break;
        case tk_mv2flt: process_fprop(0x1D); break;
        case tk_mtfp: process_fprop(0x1C); break;
/*
        case tk_fcx: process_fpstat(0x74); break;
        case tk_fdx: process_fpstat(0x77); break;
        case tk_fex: process_fpstat(0x76); break;
*/
        case tk_fill: process_fill(); break;
        case tk_fix2flt: process_fprop(0x60); break;
        case tk_flt2fix: process_fprop(0x61); break;
        case tk_fmov: process_fprop(0x62); break;
        case tk_fmul: process_fprrop(0x2B); break;
/*
        case tk_fnabs: process_fprop(0x89); break;
        case tk_frm: process_fpstat(0x78); break;
        case tk_fstat: process_fprdstat(0x86); break;
        case tk_ftx: process_fpstat(0x75); break;
*/
        case tk_fneg: process_fprop(0x63); break;
        case tk_fsub: process_fprrop(0x29); break;

        case tk_gran: process_gran(0x14); break;
        case tk_inc: process_inc(0x64); break;
        case tk_int: process_brk(2); break;
  
        case tk_jal: process_jal(0x3C,-1); break;
        case tk_jmp: process_jal(0x3C,0); break;
        case tk_jsr: process_jal(0x3C,31); break;

        case tk_lb:  process_load(0x40); break;
        case tk_lbu: process_load(0x41); break;
        case tk_lc:  process_load(0x42); break;
        case tk_lcu: process_load(0x43); break;
        case tk_ldi: process_ldi(0x0A); break;
        case tk_lea: process_load(0x47); break;
        case tk_lfd: process_load(0x51); break;
        case tk_lh:  process_load(0x44); break;
        case tk_lhu: process_load(0x45); break;
        case tk_lsr: process_rrop(0x31); break;
        case tk_lsri: process_shifti(0x39); break;
        case tk_lw:  process_load(0x46); break;
        case tk_lwar:  process_load(0x5C); break;
        case tk_message: process_message(); break;
        case tk_mfspr: process_mfspr(0x1F); break;
        case tk_mod: process_rrop(0x09); break;
        case tk_modu: process_rrop(0x19); break;
        case tk_mov: process_mov(); break;
        case tk_mtspr: process_mtspr(0x1E); break;
        case tk_mul: process_rrop(0x07); break;
        case tk_muli: process_riop(0x07); break;
        case tk_mulu: process_rrop(0x17); break;
        case tk_mului: process_riop(0x17); break;
        case tk_neg: process_neg(0x15); break;
        case tk_nop: emit_insn(0x0000003F); break;
        case tk_not: process_rop(0x0A); break;
        case tk_or:  process_rrop(0x0D); break;
        case tk_ori: process_riop(0x0D); break;
        case tk_org: process_org(); break;
        case tk_pea: process_pea(); break;
        case tk_pop:  process_pushpop(0x57); break;
        case tk_public: process_public(); break;
        case tk_push: process_pushpop(0x67); break;
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
        case tk_rol: process_rrop(0x32); break;
        case tk_ror: process_rrop(0x33); break;
        case tk_roli: process_shifti(0x3A); break;
        case tk_rori: process_shifti(0x3B); break;
        case tk_rtd: process_pctrl(29); break;
        case tk_rte: process_pctrl(30); break;
        case tk_rti: process_pctrl(31); break;
        case tk_rtl: process_rts(0x27); break;
        case tk_rts: process_rts(0x3B); break;
        case tk_sb:  process_store(0x60); break;
        case tk_sc:  process_store(0x61); break;
        case tk_sei: process_pctrl(1); break;
        case tk_seq:  process_rrop(0x20); break;
        case tk_sfd: process_store(0x71); break;
        case tk_sh:  process_store(0x62); break;
        case tk_shl:  process_rrop(0x30); break;
        case tk_shli: process_shifti(0x38); break;
        case tk_sne:  process_rrop(0x21); break;
        case tk_stp: process_pctrl(2); break;
        case tk_sub:  process_rrop(0x05); break;
        case tk_subi: process_riop(0x05); break;
        case tk_subu:  process_rrop(0x15); break;
        case tk_subui: process_riop(0x15); break;
        case tk_sxb: process_rop(0x10); break;
        case tk_sxc: process_rop(0x11); break;
        case tk_sxh: process_rop(0x12); break;
        case tk_sys: process_brk(0); break;
        case tk_sw:  process_store(0x63); break;
        case tk_swcr:  process_store(0x6E); break;
        case tk_xor: process_rrop(0x0E); break;
        case tk_xori: process_riop(0x0E); break;
        case tk_wai: process_pctrl(3); break;
        case tk_id:  process_label(); break;
        }
        NextToken();
    }
j1:
    ;
}

