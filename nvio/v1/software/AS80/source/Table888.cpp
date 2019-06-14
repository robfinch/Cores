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

static void emitAlignedCode(int cd);
static void process_shifti(int oc);

int first_rodata;
int first_data;
int first_bss;

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int64_t oc)
{
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
     emitCode((oc >> 32) & 255);
}
 

// ---------------------------------------------------------------------------
// Emit code aligned to a code address.
// ---------------------------------------------------------------------------

static void emitAlignedCode(int cd)
{
     int64_t ad;

     ad = code_address & 15;
     while (ad != 0 && ad != 5 && ad != 10) {
         emitByte(0x00);
         ad = code_address & 15;
     }
     ad = code_address & 0xfff;
     if ((ad > 0xFF0 && cd == 0xFD) || (ad > 0xFEA && cd == 0x61)) {
         emit_insn(0xEAEAEAEAEA);
         emit_insn(0xEAEAEAEAEA);
         if (cd==0x61)
             emit_insn(0xEAEAEAEAEA);
         ad = code_address & 0xfff;
         while (ad != 0 && ad != 5 && ad != 10) {
             emitByte(0x00);
             ad = code_address & 15;
         }
     }
     emitByte(cd);
}

// ----------------------------------------------------------------------------
// Bump up the address to the next aligned code address.
// ----------------------------------------------------------------------------

void Table888_bump_address()
{
//     if ((*address & 15)==15)
//         *address = *address + 1;
     if (segment==codeseg) {
         while ((sections[segment].address & 15) != 0 &&
                (sections[segment].address & 15) != 5 &&
                (sections[segment].address & 15) != 10) {
               emitByte(0x00);
         }
     }
}


// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm4(int64_t v, int force)
{
     if (v < -8L || v > 7L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 4) & 255);
          emitCode((v >> 12) & 255);
          emitCode((v >> 20) & 255);
          emitCode((v >> 28) & 255);
     }
     if (((v < 0) && ((v >> 36) != -1L)) || ((v > 0) && ((v >> 36) != 0L)) || (force && data_bits > 36)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 36) & 255);
          emitCode((v >> 44) & 255);
          emitCode((v >> 52) & 255);
          emitCode((v >> 60) & 255);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm8(int64_t v, int force)
{
     if (v < -128L || v > 127L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 8) & 255);
          emitCode((v >> 16) & 255);
          emitCode((v >> 24) & 255);
          emitCode((v >> 32) & 255);
     }
     if (((v < 0) && ((v >> 40) != -1L)) || ((v > 0) && ((v >> 40) != 0L)) || (force && data_bits > 40)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
          emitCode(0x00);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm14(int64_t v, int force)
{
     if (v < -8192L || v > 8191L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 14) & 255);
          emitCode((v >> 22) & 255);
          emitCode((v >> 30) & 255);
          emitCode((v >> 38) & 255);
     }
     if (((v < 0) && ((v >> 46) != -1L)) || ((v > 0) && ((v >> 46) != 0L)) || (force && data_bits > 46)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 46) & 255);
          emitCode((v >> 54) & 255);
          emitCode((v >> 62) & 255);
          emitCode(0x00);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for 16-bit operands.
// ---------------------------------------------------------------------------

static void emitImm16(int64_t v, int force)
{
     if (v < -32768L || v > 32767L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 16) & 255);
          emitCode((v >> 24) & 255);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
     }
     if (((v < 0) && ((v >> 48) != -1L)) || ((v > 0) && ((v >> 48) != 0L)) || (force && (code_bits > 48 || data_bits > 48))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
          emitCode(0x00);
          emitCode(0x00);
     }
}

// ---------------------------------------------------------------------------
// Emit constant extension for 24-bit operands.
// ---------------------------------------------------------------------------

static void emitImm24(int64_t v, int force)
{
     if (v < -8388608L || v > 8388607L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 24) & 255);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
     }
     if (((v < 0) && ((v >> 56) != -1L)) || ((v > 0) && ((v >> 56) != 0L)) || (force && (code_bits > 56 || data_bits > 56))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 56) & 255);
          emitCode(0x00);
          emitCode(0x00);
          emitCode(0x00);
     }
}

// ---------------------------------------------------------------------------
// Emit constant extension for 32-bit operands.
// ---------------------------------------------------------------------------

static void emitImm32(int64_t v, int force)
{
     if (v < -2147483648LL || v > 2147483647LL || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
     }
}

// ---------------------------------------------------------------------------
// jmp main
// jsr [r19]
// jmp (tbl,r2)
// ---------------------------------------------------------------------------

static void process_jmp(int oc)
{
    int64_t addr;
    int Ra;

    NextToken();
    // Memory indirect ?
    if (token=='(' || token=='[') {
       Ra = getRegister();
       if (Ra==-1) {
           Ra = 0;
           NextToken();
           addr = expr();
           prevToken();
           if (token==',') {
               Ra = getRegister();
               if (Ra==-1) Ra = 0;
           }
           if (token!=')' && token != ']')
               printf("Missing close bracket.\r\n");
           emitImm24(addr,lastsym!=(SYM*)NULL);
           emitAlignedCode(oc+2);
            if (bGen)
                if (lastsym) {
                    if( lastsym->segment < 5)
                        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 2 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
                }
           emitCode(Ra);
           emitCode(addr & 255);
           emitCode((addr >> 8) & 255);
           emitCode((addr >> 16) & 255);
           return;
       }
       // Simple [Rn]
       else {
            if (token != ')' && token!=']')
                printf("Missing close bracket\r\n");
            emitAlignedCode(oc + 4);
            emitCode(Ra);
            emitCode(0x00);
            emitCode(0x00);
            emitCode(0x00);
            return;
       }
    }
    addr = expr();
    prevToken();
    // d(Rn)? 
    if (token=='(' || token=='[') {
        Ra = getRegister();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
        emitImm24(addr,0);
        emitAlignedCode(oc+4);
        emitCode(Ra);
        emitCode(addr & 255);
        emitCode((addr >> 8) & 255);
        emitCode((addr >> 16) & 255);
        return;
    }

    emitImm32(addr, code_bits > 32);
    emitAlignedCode(oc);
    if (bGen)
       if (lastsym) {
            if( lastsym->segment < 5)
                sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 1 | (lastsym->isExtern ? 128 : 0) | (code_bits << 8));
        }
    emitCode(addr & 255);
    emitCode((addr >> 8) & 255);
    emitCode((addr >> 16) & 255);
    emitCode((addr >> 24) & 255);
}

// ---------------------------------------------------------------------------
// subui r1,r2,#1234
// ---------------------------------------------------------------------------

static void process_riop(int oc)
{
    int Ra;
    int Rt;
    char *p;
    int64_t val;
    
    p = inptr;
    Rt = getRegister();
    need(',');
    Ra = getRegister();
    need(',');
    NextToken();
    val = expr();
    emitImm16(val,lastsym!=(SYM*)NULL);
    emitAlignedCode(oc);
    if (bGen)
    if (lastsym) {
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 3 | (lastsym->isExtern ? 128 : 0) |
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    }
    emitCode(Ra);
    emitCode(Rt);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
}

// ---------------------------------------------------------------------------
// addu r1,r2,r12
// ---------------------------------------------------------------------------

static void process_rrop(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    char *p;

    p = inptr;
    Rt = getRegister();
    need(',');
    Ra = getRegister();
    need(',');
    NextToken();
    if (token=='#') {
        inptr = p;
        switch(oc) {
        case 0x04: process_riop(0x04); return;  // add
        case 0x14: process_riop(0x14); return;  // addu
        case 0x05: process_riop(0x05); return;  // sub
        case 0x15: process_riop(0x15); return;  // subu
        case 0x06: process_riop(0x06); return;  // cmp
        case 0x07: process_riop(0x07); return;  // mul
        case 0x08: process_riop(0x08); return;  // div
        case 0x09: process_riop(0x09); return;  // mod
        case 0x17: process_riop(0x17); return;  // mulu
        case 0x18: process_riop(0x18); return;  // divu
        case 0x19: process_riop(0x19); return;  // modu
        case 0x20: process_riop(0x0C); return;  // and
        case 0x21: process_riop(0x0D); return;  // or
        case 0x22: process_riop(0x0E); return;  // eor
        // Sxx
        case 0x60: process_riop(0x30); return;
        case 0x61: process_riop(0x31); return;
        case 0x68: process_riop(0x38); return;
        case 0x69: process_riop(0x39); return;
        case 0x6A: process_riop(0x3A); return;
        case 0x6B: process_riop(0x3B); return;
        case 0x6C: process_riop(0x3C); return;
        case 0x6D: process_riop(0x3D); return;
        case 0x6E: process_riop(0x3E); return;
        case 0x6F: process_riop(0x3F); return;
        // Shift
        case 0x40: process_shifti(0x50); return;
        case 0x41: process_shifti(0x51); return;
        case 0x42: process_shifti(0x52); return;
        case 0x43: process_shifti(0x53); return;
        case 0x44: process_shifti(0x54); return;
        }
        return;
    }
    prevToken();
    Rb = getRegister();
    prevToken();
    emitAlignedCode(2);
    emitCode(Ra);
    emitCode(Rb);
    emitCode(Rt);
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
    emitAlignedCode(1);
    emitCode(Ra);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
}

// ---------------------------------------------------------------------------
// brnz r1,label
// ---------------------------------------------------------------------------

static void process_bcc(int oc)
{
    int Ra;
    int64_t val;
    int64_t disp;
    int64_t ad;

    Ra = getRegister();
    need(',');
    NextToken();
    val = expr();
    ad = code_address + 5;
    if ((ad & 15)==15)
       ad++;
    disp = (val & 0xFFFFFFFFFFFF0000L) - (ad & 0xFFFFFFFFFFFF0000L); 
    emitAlignedCode(oc);
    emitCode(Ra);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((disp >> 16) & 31);
}

// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int oc)
{
    int64_t val;
    int64_t disp;
    int64_t ad;

    NextToken();
    val = expr();
    ad = code_address + 5;
    if ((ad & 15)==15)
       ad++;
    disp = (val & 0xFFFFFFFFFFFF0000L) - (ad & 0xFFFFFFFFFFFF0000L); 
    emitAlignedCode(oc);
    emitCode(0x00);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((disp >> 16) & 31);
}

// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// expr[Reg+Reg*sc]
// [Reg]
// [Reg+Reg*sc]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA, int *regB, int *sc, int *sg)
{
     int64_t val;

     // chech params
     if (disp == (int64_t *)NULL)
         return;
     if (regA == (int *)NULL)
         return;
     if (regB == (int *)NULL)
         return;
     if (sc==(int *)NULL)
         return;
     if (sg==(int *)NULL)
         return;

     *disp = 0;
     *regA = -1;
     *regB = -1;
     *sc = 0;
     *sg = 1;
     if (token!='[') {;
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegister();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
         if (*regA==255 || *regA==253)
            *sg = 2;
         else if (*regA==254 || *regA==252)
            *sg = 0;
//         NextToken();
         if (token=='+') {
              *sc = 0;
              *regB = getRegister();
              if (*regB == -1) {
                  printf("expecting a register\r\n");
              }
              if (token=='*' && !fSeg)
                  printf("Index scaling not supported.\r\n");
              if (token=='*') {
                  NextToken();
                  val = expr();
                  prevToken();
//                  if (token!=tk_icon) {
//                      printf("expecting a scaling factor.\r\n");
//                      printf("token %d %c\r\n", token, token);
//                  }
                  switch(val) {
                  case 0: *sc = 0; break;
                  case 1: *sc = 0; break;
                  case 2: *sc = 1; break;
                  case 4: *sc = 2; break;
                  case 8: *sc = 3; break;
                  default: printf("Illegal scaling factor.\r\n");
                  }
              }
         }
         need(']');
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
    int sg;
    int fixup;
    int64_t disp;

    Rs = getRegister();
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    if (segprefix >= 0)
       sg = segprefix;
    if (Rs < 0) {
        printf("Expecting a source register.\r\n");
        ScanToEOL();
        return;
    }
    if (Rb > 0) {
       if (fSeg) {
           fixup = 5;
           emitImm4(disp,lastsym!=(SYM*)NULL);
       }
       else {
           fixup = 7;
           emitImm8(disp,lastsym!=(SYM*)NULL);
       }
       emitAlignedCode(oc + 8);
        if (bGen)
        if (lastsym) {
        if( lastsym->segment < 5)
            sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | fixup | (lastsym->isExtern ? 128 : 0)|
            (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
        }
       emitCode(Ra);
       emitCode(Rb);
       emitCode(Rs);
       if (fSeg)
            emitCode((disp << 4) | sc | ((sg & 3) << 2));
       else
            emitCode(disp & 255);
       return;
    }
    if (fSeg) {
        fixup = 4;
        if (disp < 0xFFFFFFFFFFFFE000LL || disp > 0x1FFFLL)
           emitImm14(disp,lastsym!=(SYM*)NULL);
    }
    else {
        fixup = 3;
        if (disp < 0xFFFFFFFFFFFF8000LL || disp > 0x7FFFLL)
           emitImm16(disp,lastsym!=(SYM*)NULL);
    }
    emitAlignedCode(oc);
    if (bGen && lastsym)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | fixup | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    if (Ra < 0) Ra = 0;
    emitCode(Ra);
    emitCode(Rs);
    if (fSeg) {
        emitCode(((disp << 2) & 0xFC) | (sg & 3));
        emitCode((disp >> 6) & 255);
    }
    else {
        emitCode(disp & 0xFF);
        emitCode((disp >> 8) & 255);
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi(int oc)
{
    int Rt;
    int64_t val;

    Rt = getRegister();
    expect(',');
    val = expr();
    emitImm24(val,lastsym!=(SYM*)NULL);
    emitAlignedCode(oc);
    if (bGen && lastsym)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 2 | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    emitCode(Rt);
    emitCode(val & 255);
    emitCode((val >> 8) & 255);
    emitCode((val >> 16) & 255);
}

// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// ----------------------------------------------------------------------------

static void process_load(int oc)
{
    int Ra;
    int Rb;
    int Rt;
    int sc;
    int sg;
    char *p;
    int64_t disp;
    int fixup = 5;

    p = inptr;
    Rt = getRegister();
    if (Rt < 0) {
        printf("Expecting a target register.\r\n");
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra, &Rb, &sc, &sg);
    if (segprefix >= 0)
        sg = segprefix;
    if (Rb >= 0) {
       if (fSeg) {
           emitImm4(disp,lastsym!=(SYM*)NULL);
           fixup = 5;
       }
       else {
           emitImm8(disp,lastsym!=(SYM*)NULL);
           fixup = 7;
       }
       if (oc==0x87) {
          printf("Address mode not supported.\r\n");
          return;
       }
       if (oc==0x92) oc = 0x8F;  // LEA
       else oc = oc + 8;
       emitAlignedCode(oc);
        if (bGen && lastsym)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | fixup | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
       emitCode(Ra);
       emitCode(Rb);
       emitCode(Rt);
       if (fSeg)
           emitCode((disp << 4) | sc | ((sg & 3) << 2));
       else
           emitCode(disp & 255);
       return;
    }
    if (fSeg) {
        fixup = 4;       // 14 bit
        if (disp < 0xFFFFFFFFFFFFE000LL || disp > 0x1FFFLL)
           emitImm14(disp,lastsym!=(SYM*)NULL);
    }
    else {
        fixup = 3;       // 16 bit
        if (disp < 0xFFFFFFFFFFFF8000LL || disp > 0x7FFFLL)
           emitImm16(disp,lastsym!=(SYM*)NULL);
    }
    emitAlignedCode(oc);
    if (bGen && lastsym)
    if( lastsym->segment < 5)
    sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | fixup | (lastsym->isExtern ? 128 : 0)|
    (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
    if (Ra < 0) Ra = 0;
    emitCode(Ra);
    emitCode(Rt);
    if (fSeg) {
        emitCode(((disp << 2) & 0xFC) | (sg & 3));
        emitCode((disp >> 6) & 255);
    }
    else {
        emitCode(disp & 0xFF);
        emitCode((disp >> 8) & 255);
    }
    ScanToEOL();
}

// ----------------------------------------------------------------------------
// lmr r1,r12,[r252]
// ----------------------------------------------------------------------------

static void process_lmr(int oc)
{
    int Ra;
    int Rb;
    int Rc;
    
    Ra = getRegister();
    need(',');
    Rb = getRegister();
    need(',');
    NextToken();
    if (token=='[') {
        Rc = getRegister();
        need(']');
    }
    else
        Rc = getRegister();
    emitAlignedCode(0x02);
    emitCode(Ra);
    emitCode(Rb);
    emitCode(Rc);
    emitCode(oc);
}

// ----------------------------------------------------------------------------
// push r1/r2/r3/r4
// push #123
// ----------------------------------------------------------------------------

static void process_pushpop(int oc)
{
    int Ra,Rb,Rc,Rd;
    int64_t val;

    Ra = -1;
    Rb = -1;
    Rc = -1;
    Rd = -1;
    NextToken();
    if (token=='#' && oc==0xA6) {  // Filter to PUSH
       val = expr();
       emitImm32(val,(code_bits > 32 || data_bits > 32) && lastsym!=(SYM *)NULL);
       emitAlignedCode(0xAD);                        
        if (bGen && lastsym)
        if( lastsym->segment < 5)
        sections[segment+7].AddRel(sections[segment].index,((lastsym->ord+1) << 32) | 1 | (lastsym->isExtern ? 128 : 0)|
        (lastsym->segment==codeseg ? code_bits << 8 : data_bits << 8));
       emitCode(val & 255);
       emitCode((val >> 8) & 255);
       emitCode((val >> 16) & 255);
       emitCode((val >> 24) & 255);
    }
    else {
        prevToken();
        Ra = getRegister();
        if (token=='/' || token==',') {
            Rb = getRegister();
            if (token=='/' || token==',') {
                Rc = getRegister();
                if (token=='/' || token==',') {
                    Rd = getRegister();
                }
            }
        }
        prevToken();
        emitAlignedCode(oc);
        emitCode(Ra>=0 ? Ra : 0);
        emitCode(Rb>=0 ? Rb : 0);
        emitCode(Rc>=0 ? Rc : 0);
        emitCode(Rd>=0 ? Rd : 0);
    }
}
 
// ----------------------------------------------------------------------------
// mov r1,r2
// ----------------------------------------------------------------------------

static void process_mov(int oc)
{
     int Ra;
     int Rt;
     
     Rt = getRegister();
     need(',');
     Ra = getRegister();
     emitAlignedCode(0x01);
     emitCode(Ra);
     emitCode(Rt);
     emitCode(0x00);
     emitCode(oc);
     prevToken();
}

// ----------------------------------------------------------------------------
// rts
// rts #24
// ----------------------------------------------------------------------------

static void process_rts(int oc)
{
     int64_t val;

     val = 0;
     NextToken();
     if (token=='#') {
        val = expr();
     }
     emitAlignedCode(oc);
     emitCode(0x00);
     emitCode(val & 255);
     emitCode((val >> 8) & 255);
     emitCode(0x00);
}

// ----------------------------------------------------------------------------
// shli r1,r2,#5
// ----------------------------------------------------------------------------

static void process_shifti(int oc)
{
     int Ra;
     int Rt;
     int64_t val;
     
     Rt = getRegister();
     need(',');
     Ra = getRegister();
     need(',');
     NextToken();
     val = expr();
     emitAlignedCode(0x02);
     emitCode(Ra);
     emitCode(val & 63);
     emitCode(Rt);
     emitCode(oc);
}

// ----------------------------------------------------------------------------
// gran r1
// ----------------------------------------------------------------------------

static void process_gran(int oc)
{
    int Rt;

    Rt = getRegister();
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
    
    spr = getSprRegister();
    need(',');
    Ra = getRegister();
    emitAlignedCode(0x01);
    emitCode(Ra);
    emitCode(spr);
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
    
    Rt = getRegister();
    need(',');
    spr = getSprRegister();
    emitAlignedCode(0x01);
    emitCode(spr);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
    if (spr >= 0)
    prevToken();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void Table888_processMaster()
{
    int nn,mm;
    int64_t ca;
    int first;
    int64_t bs1, bs2;

    lineno = 1;
    binndx = 0;
    binstart = 0;
    bs1 = 0;
    bs2 = 0;
    inptr = &masterFile[0];
    stptr = inptr;
    code_address = 0x200;
    bss_address = 0;
    start_address = 0x200;
    first_org = 1;
    first_rodata = 1;
    first_data = 1;
    for (nn = 0; nn < 12; nn++) {
        sections[nn].index = 0;
        sections[nn].address = 0;
        sections[nn].start = 0;
        sections[nn].end = 0;
    }
    ca = code_address;
    segment = codeseg;
    memset(current_label,0,sizeof(current_label));
    NextToken();
    while (token != tk_eof) {
        switch(token) {
        case tk_eol:
             //printf("Line: %d\r\n", lineno);
             segprefix = -1;
             if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
             if ((ca & 15)==15 && segment==codeseg) {
                 ca++;
                 binstart++;
             }
            nn = binstart;
            if (segment==codeseg) {
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
            }
            first = 1;
            while (nn < sections[segment].index) {
                fprintf(ofp, "%06LLX ", ca);
                for (mm = nn; nn < mm + 8 && nn < sections[segment].index; nn++) {
                    fprintf(ofp, "%02X ", sections[segment].bytes[nn]);
                }
                for (; nn < mm + 8; nn++)
                    fprintf(ofp, "   ");
                if (first) {
                    fprintf(ofp, "\t%.*s\n", inptr-stptr-1, stptr);
                    first = 0;
                }
                else
                    fprintf(ofp, "\n");
                ca += 8;
            }
            // empty (codeless) line
            if (binstart==sections[segment].index) {
                fprintf(ofp, "%24s\t%.*s", "", inptr-stptr, stptr);
            }
            } // bGen
            stptr = inptr;
            binstart = sections[segment].index;
            ca = sections[segment].address;
            lineno++;
            break;
        case tk_add:  process_rrop(0x04); break;
        case tk_addi: process_riop(0x04); break;
        case tk_addu: process_rrop(0x14); break;
        case tk_addui: process_riop(0x14); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(0x20); break;
        case tk_andi:  process_riop(0x0C); break;
        case tk_asr:  process_rrop(0x44); break;
        case tk_asri: process_shifti(0x54); break;
        case tk_beq: process_bcc(0x40); break;
        case tk_bge: process_bcc(0x4A); break;
        case tk_bgeu: process_bcc(0x4E); break;
        case tk_bgt: process_bcc(0x48); break;
        case tk_bgtu: process_bcc(0x4C); break;
        case tk_ble: process_bcc(0x49); break;
        case tk_bleu: process_bcc(0x4D); break;
        case tk_blt: process_bcc(0x4B); break;
        case tk_bltu: process_bcc(0x4F); break;
        case tk_bmi: process_bcc(0x44); break;
        case tk_bne: process_bcc(0x41); break;
        case tk_bpl: process_bcc(0x45); break;
        case tk_bra: process_bra(0x46); break;
        case tk_brnz: process_bcc(0x59); break;
        case tk_brz:  process_bcc(0x58); break;
        case tk_bvc: process_bcc(0x43); break;
        case tk_bvs: process_bcc(0x42); break;
        case tk_bsr: process_bra(0x56); break;
        case tk_bss: segment = bssseg; break;
        case tk_cli: emit_insn(0x3100000001); break;
        case tk_cmp: process_rrop(0x06); break;
        case tk_code: process_code(); break;
        case tk_com: process_rop(0x06); break;
        case tk_cs:  segprefix = 0; break;
        case tk_data:
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
        case tk_dbnz: process_bcc(0x5A); break;
        case tk_dc:  process_dc(); break;
        case tk_dh:  process_dh(); break;
        case tk_div: process_rrop(0x08); break;
        case tk_divu: process_rrop(0x18); break;
        case tk_ds:  segprefix = 1; break;
        case tk_dw:  process_dw(); break;
        case tk_end: goto j1;
        case tk_endpublic: break;
        case tk_eor: process_rrop(0x22); break;
        case tk_eori: process_riop(0x0E); break;
        case tk_extern: process_extern(); break;
        case tk_fill: process_fill(); break;
        case tk_gran: process_gran(0x14); break;
        case tk_jmp: process_jmp(0x50); break;
        case tk_jsr: process_jmp(0x51); break;
        case tk_lb:  process_load(0x80); break;
        case tk_lbu: process_load(0x81); break;
        case tk_lc:  process_load(0x82); break;
        case tk_lcu: process_load(0x83); break;
        case tk_ldi: process_ldi(0x16); break;
        case tk_lea: process_load(0x92); break;
        case tk_lh:  process_load(0x84); break;
        case tk_lhu: process_load(0x85); break;
        case tk_lmr: process_lmr(0x31); break;
        case tk_lw:  process_load(0x86); break;
        case tk_mfspr: process_mfspr(0x49); break;
        case tk_mod: process_rrop(0x09); break;
        case tk_modu: process_rrop(0x19); break;
        case tk_mov: process_mov(0x04); break;
        case tk_mtspr: process_mtspr(0x48); break;
        case tk_mul: process_rrop(0x07); break;
        case tk_muli: process_riop(0x07); break;
        case tk_mulu: process_rrop(0x17); break;
        case tk_mului: process_riop(0x17); break;
        case tk_neg: process_rop(0x05); break;
        case tk_nop: emit_insn(0xEAEAEAEAEA); break;
        case tk_not: process_rop(0x07); break;
        case tk_or:  process_rrop(0x21); break;
        case tk_ori: process_riop(0x0D); break;
        case tk_org: process_org(); break;
        case tk_php: emit_insn(0x3200000001); break;
        case tk_plp: emit_insn(0x3300000001); break;
        case tk_pop:  process_pushpop(0xA7); break;
        case tk_public: process_public(); break;
        case tk_push: process_pushpop(0xA6); break;
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
        case tk_rol: process_rrop(0x41); break;
        case tk_ror: process_rrop(0x43); break;
        case tk_rti: emit_insn(0x4000000001); break;
        case tk_rts: process_rts(0x60); break;
        case tk_sb:  process_store(0xa0); break;
        case tk_sc:  process_store(0xa1); break;
        case tk_sei: emit_insn(0x3000000001); break;
        case tk_seq:  process_rrop(0x60); break;
        case tk_seqi: process_riop(0x30); break;
        case tk_sge:  process_rrop(0x6A); break;
        case tk_sgt:  process_rrop(0x68); break;
        case tk_sle:  process_rrop(0x69); break;
        case tk_slt:  process_rrop(0x6B); break;
        case tk_sgeu:  process_rrop(0x6E); break;
        case tk_sgtu:  process_rrop(0x6C); break;
        case tk_sleu:  process_rrop(0x6D); break;
        case tk_sltu:  process_rrop(0x6F); break;
        case tk_sgei:  process_rrop(0x3A); break;
        case tk_sgti:  process_rrop(0x38); break;
        case tk_slei:  process_rrop(0x39); break;
        case tk_slti:  process_rrop(0x3B); break;
        case tk_sgeui:  process_rrop(0x3E); break;
        case tk_sgtui:  process_rrop(0x3C); break;
        case tk_sleui:  process_rrop(0x3D); break;
        case tk_sltui:  process_rrop(0x3F); break;
        case tk_sne:  process_rrop(0x61); break;
        case tk_snei: process_riop(0x31); break;
        case tk_sh:  process_store(0xa2); break;
        case tk_shl:  process_rrop(0x40); break;
        case tk_shli: process_shifti(0x50); break;
        case tk_shru: process_rrop(0x42); break;
        case tk_shrui: process_shifti(0x52); break;
        case tk_smr: process_lmr(0x30); break;
        case tk_ss:  segprefix = 2; break;
        case tk_sub:  process_rrop(0x05); break;
        case tk_subi: process_riop(0x05); break;
        case tk_subu: process_rrop(0x15); break;
        case tk_subui: process_riop(0x15); break;
        case tk_sxb: process_rop(0x08); break;
        case tk_sxc: process_rop(0x09); break;
        case tk_sxh: process_rop(0x0A); break;
        case tk_sw:  process_store(0xa3); break;
        case tk_swap: process_rop(0x03); break;
        case tk_xor: process_rrop(0x22); break;
        case tk_xori: process_riop(0x0E); break;
        case tk_id:  process_label(); break;
        }
        NextToken();
    }
j1:
    ;
}

