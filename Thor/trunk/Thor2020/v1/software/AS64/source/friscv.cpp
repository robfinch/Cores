// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2020  Robert Finch, Stratford
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
static void process_shifti(int oc, int funct3, int funct7);
static void ProcessEOL(int opt);
extern void process_dco();
extern int first_rodata;
extern int first_data;
extern int first_bss;
extern int htable[100000];
extern int htblcnt[100000];
extern int htblmax;
extern int pass;
extern char *pif1;

static int64_t ca;

extern int use_gp;

#define OPT64     2
#define OPTX32    0
#define OPTLUI0   1

#define RD(x)		((x) << 7)
#define FN3(x)	((x) << 12)
#define FN5(x)	((x) << 27)
#define FN7(x)	((x) << 25)
#define RS1(x)	((x) << 15)
#define RS2(x)	((x) << 20)
#define FMT(x)	((x) << 25)
#define BT(x) 	((((x) & 0x1000) >> 12) << 31) | \
								((((x) & 0x7E0) >> 5) << 25) | \
								((((x) & 0x1E) >> 1) << 8) | \
								((((x) & 0x800) >> 11) << 7)

// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// Parses pretty register names like SP or BP in addition to r1,r2,etc.
// ----------------------------------------------------------------------------

static int getRegisterX()
{
    int reg;

    while(isspace(*inptr)) inptr++;
		if (*inptr == '$')
			inptr++;
    switch(*inptr) {
    case 'x': case 'X':
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
    case 'f': case 'F':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 2;
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
            return (14);
        }
				if (isdigit(inptr[1]) && inptr[1]!='0') {
					reg = inptr[1] - '0';
					if (isdigit(inptr[2])) {
						reg = reg * 10 + (inptr[2] - '0');
						if (isIdentChar(inptr[3])) {
							return (-1);
						}
						inptr++;
					}
					else if (isIdentChar(inptr[2])) {
						return (-1);
					}
					reg += 3;
					inptr += 2;
					NextToken();
					return (reg);
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
            return 15;
        }
        /*
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 24;
        }
        */
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
    case 'r': case 'R':
        if ((inptr[1]=='a' || inptr[1]=='A') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 1;
        }
				if (isdigit(inptr[1])) {
					reg = inptr[1] - '0';
					if (isdigit(inptr[2])) {
						reg = 10 * reg + (inptr[2] - '0');
						if (isdigit(inptr[3])) {
							reg = 10 * reg + (inptr[3] - '0');
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
				break;
    case 'v': case 'V':
         if (inptr[1]=='0' || inptr[1]=='1') {
             reg = inptr[1]-'0' + 16;
             if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return reg;
             }
         }
    default:
        return -1;
    }
    return -1;
}


// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// ----------------------------------------------------------------------------

static int getFPRegister()
{
	int reg;

	while (isspace(*inptr)) inptr++;
	if (*inptr == '$')
		inptr++;
	switch (*inptr) {
	case 'f': case 'F':
		if (isdigit(inptr[1])) {
			reg = inptr[1] - '0';
			if (isdigit(inptr[2])) {
				reg = 10 * reg + (inptr[2] - '0');
				if (isdigit(inptr[3])) {
					reg = 10 * reg + (inptr[3] - '0');
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
	default:
		return -1;
	}
	return -1;
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void emit_insn(int oc, int can_compress)
{
    int ndx;

    if (pass==3 && can_compress && 0) {
       for (ndx = 0; ndx < htblmax; ndx++) {
         if (oc == hTable[ndx].opcode) {
           printf("found opcode\n");
           hTable[ndx].count++;
           return;
         }
       }
       if (htblmax < 100000) {
           printf("inserting opcode %08X\n", oc);
          hTable[htblmax].opcode = oc;
          hTable[htblmax].count = 1;
          htblmax++;
          return;  
       }
       printf("Too many instructions.\r\n");
       return;
    }
    if (pass > 3) {
     if (can_compress) {
       for (ndx = 0; ndx < htblmax; ndx++) {
         if (oc == hTable[ndx].opcode) {
           printf("found opcode\n");
           emitAlignedCode(((ndx & 8) << 4)|0x50|(ndx & 0x7));
           emitCode(ndx >> 4);
           return;
         }
       }
     }
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
    }
    /*
    if (processOpt==2) {
       for (ndx = 0; ndx < htblmax; ndx++) {
         if (oc == hTable[ndx].opcode) {
           printf("found opcode\n");
           emitAlignedCode(((ndx & 8) << 4)|0x50|(ndx & 0x7));
           emitCode(ndx >> 4);
           return;
         }
       }
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
    }
    else {
     emitAlignedCode(oc & 255);
     emitCode((oc >> 8) & 255);
     emitCode((oc >> 16) & 255);
     emitCode((oc >> 24) & 255);
    }
    */
	num_bytes += 4;
	if ((oc & 0x7F) != 0x3F)
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
}
 

// ---------------------------------------------------------------------------
// Emit code aligned to a code address.
// ---------------------------------------------------------------------------

static void emitAlignedCode(int cd)
{
     int64_t ad;

     ad = code_address & 15;
//     while (ad != 0 && ad != 4 && ad != 8 && ad != 12) {
       while (ad & 1) {
         emitByte(0x00);
         ad = code_address & 15;
     }
     emitByte(cd);
}


// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm0(int64_t v, int force)
{
     if (v != 0 || force) {
          emitAlignedCode(0xfd);
          emitCode(v & 255);
          emitCode((v >> 8) & 255);
          emitCode((v >> 16) & 255);
          emitCode((v >> 24) & 255);
     }
     if (((v < 0) && ((v >> 32) != -1L)) || ((v > 0) && ((v >> 32) != 0L)) || (force && data_bits > 32)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 32) & 255);
          emitCode((v >> 40) & 255);
          emitCode((v >> 48) & 255);
          emitCode((v >> 56) & 255);
     }
}

// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm2(int64_t v, int force)
{
     if (v < 0L || v > 3L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 2) & 255);
          emitCode((v >> 10) & 255);
          emitCode((v >> 18) & 255);
          emitCode((v >> 26) & 255);
     }
     if (((v < 0) && ((v >> 34) != -1L)) || ((v > 0) && ((v >> 34) != 0L)) || (force && data_bits > 34)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 34) & 255);
          emitCode((v >> 42) & 255);
          emitCode((v >> 50) & 255);
          emitCode((v >> 58) & 255);
     }
}
 
// ---------------------------------------------------------------------------
// Emit constant extension for memory operands.
// ---------------------------------------------------------------------------

static void emitImm12(int64_t v, int force)
{
     if (v < -2048L || v > 2047L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 12) & 255);
          emitCode((v >> 20) & 255);
          emitCode((v >> 28) & 255);
          emitCode((v >> 36) & 255);
     }
     if (((v < 0) && ((v >> 44) != -1L)) || ((v > 0) && ((v >> 44) != 0L)) || (force && data_bits > 44)) {
          emitAlignedCode(0xfe);
          emitCode((v >> 44) & 255);
          emitCode((v >> 52) & 255);
          emitCode((v >> 60) & 255);
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

static void emitImm20(int64_t v, int force)
{
     if (v < -524288L || v > 524287L || force) {
          emitAlignedCode(0xfd);
          emitCode((v >> 20) & 255);
          emitCode((v >> 28) & 255);
          emitCode((v >> 36) & 255);
          emitCode((v >> 44) & 255);
     }
     if (((v < 0) && ((v >> 52) != -1L)) || ((v > 0) && ((v >> 52) != 0L)) || (force && (code_bits > 52 || data_bits > 52))) {
          emitAlignedCode(0xfe);
          emitCode((v >> 52) & 255);
          emitCode((v >> 60) & 255);
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
// addi r1,r2,#1234
// ---------------------------------------------------------------------------

static void process_addi(int funct3)
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
    if ((val < -2048 || val > 2047) && OPTLUI0) {
        emit_insn((val & 0xFFFFF000) | (0 << 7)|0x37,1);    // LUI
    }
		/*
    if ((val < -2048 || val > 2047)) {
      if (OPTX32) {
        emit_insn((0x800 << 20)|(Ra << 15)|(funct3<<12)|(Rt << 7)|0x13,1);
        emit_insn(val,0);
      }
      else if (OPT64) {
        emit_insn(((val & 0xFFF) << 20)|(Ra << 15)|(funct3<<12)|(Rt << 7)|0x3F,!expand_flag);
        emit_insn((val&0xFFFFF000)|0x13,0);
      }
    }
    else*/
      emit_insn(((val & 0xFFF) << 20)|(Ra << 15)|(funct3<<12)|(Rt << 7)|0x13,!expand_flag);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_add()
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
        process_addi(0);
        return;
    }
    prevToken();
    Rb = getRegisterX();
    prevToken();
    emit_insn((Rb << 20)|(Ra<<15)|(0<<12)|(Rt<<7)|0x33,1);
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_riop(int oc, int funct3, int funct7)
{
  int Ra,Rb,Rt;
  char *p;
  int tk = token;
  int val;

  p = inptr;
  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  val = expr();
	if (oc < 0) {
		oc = -oc;
		val = -val;
	}
  if (!IsNBit(val,12)) {
		if (val & 0x800LL)
			emit_insn(((val+0x1000LL) & 0xFFFFF000LL) | RD(12) | 0x37, 1);    // LUI
		else
      emit_insn((val & 0xFFFFF000LL) | RD(12) |0x37,1);    // LUI
		emit_insn(((val & 0xFFFLL) << 20LL) | FN3(0) | RS1(12) | RD(12) | 0x13, !expand_flag);  // ADDI
		switch (funct3) {
		case 0: case 1: case 3: case 4: case 5: case 6: case 7:	// ADD, SLL, SLT, SLTU, XOR, OR, AND
			emit_insn(FN7(funct7) | RD(Rt) | RS2(Ra) | RS1(12) | FN3(funct3) | 0x33, 1);
			break;
		}
		return;
  }
	/*
  if ((val < -2048 || val > 2047)) {
      if (OPTX32) {
        emit_insn((0x800 << 20)|(Ra << 15)|(funct3<<12)|(Rt << 7)|oc,1);
        emit_insn(val,0);
      }
      else if (OPT64) {
      emit_insn(((val & 0xFFF) << 20)|(Ra << 15)|(funct3<<12)|(Rt << 7)|0x3F,!expand_flag);
      emit_insn((val&0xFFFFF000)|oc,0);
      }
  }
  else*/
    emit_insn(((val & 0xFFFLL) << 20LL)|RS1(Ra)|FN3(funct3)|RD(Rt)|0x13,!expand_flag);
//    emit_insn((val << 20)|(Ra<<15)|(funct3<<12)|(Rt<<7)|oc);
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_rrop(int oc, int funct3, int funct7)
{
  int Ra,Rb,Rt;
  char *p;
  int tk = token;

  p = inptr;
  Rt = getRegisterX();
  need(',');
  Ra = getRegisterX();
  need(',');
  NextToken();
  if (token=='#') {
    inptr = p;
    switch(tk) {
    case tk_add: process_riop(0x13,0x00,funct7); break;
		case tk_sub: process_riop(-0x13,0x00, funct7); break;
    case tk_and: process_riop(0x13,0x07, funct7); break;
		case tk_or:	process_riop(0x13,0x06, funct7); break;
		case tk_xor:	process_riop(0x13, 0x04, funct7); break;
		case tk_eor:	process_riop(0x13, 0x04, funct7); break;
		case tk_slt:	process_riop(0x13, 0x02, funct7); break;
		case tk_sltu:	process_riop(0x13, 0x03, funct7); break;
		case tk_sll: process_shifti(0x13, funct3, funct7); break;
		case tk_srl: process_shifti(0x13, funct3, funct7); break;
		case tk_sra: process_shifti(0x13, funct3, funct7 - 0x10); break;
		default:
        printf("rrop: syntax error\n");
    }
//      process_addi(0);
      return;
  }
  prevToken();
  Rb = getRegisterX();
  prevToken();
  emit_insn(FN7(funct7)|RS2(Rb)|RS1(Ra)|FN3(funct3)|RD(Rt)|oc,1);
	ScanToEOL();
}
       
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_mul()
{
    int Ra,Rb,Rt;
    char *p;

    p = inptr;
    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    need(',');
    Rb = getRegisterX();
    prevToken();
    emit_insn((1 << 25)|(Rb << 20)|(Ra<<15)|(0<<12)|(Rt<<7)|0x33,1);
}

// ---------------------------------------------------------------------------
// palloc $v0[,$t0]
// ---------------------------------------------------------------------------

static void process_palloc(int funct7)
{
	int Rs1, Rt;

	Rs1 = Rt = getRegisterX();
	if (funct7 == 5 || funct7 == 13)
		Rt = 0;
	else {
		Rs1 = 0;
		if (token == ',') {
			NextToken();
			Rs1 = getRegisterX();
		}
	}
	emit_insn(FN7(funct7) | FN3(0) | RS1(Rs1) | RD(Rt) | 13, 1);
	prevToken();
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_pfree(int funct7)
{
	int Rs1, Rt;

	Rs1 = getRegisterX();
	Rt = 0;
	emit_insn(FN7(funct7) | FN3(0) | RS1(Rs1) | RD(Rt) | 13, 1);
	prevToken();
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_sub()
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
        return;
    }
    prevToken();
    Rb = getRegisterX();
    prevToken();
    emit_insn(0x40000000|(Rb << 20)|(Ra<<15)|(0<<12)|(Rt<<7)|0x33,1);
}
       
// ---------------------------------------------------------------------------
// jmp main
// jsr [r19]
// jmp (tbl,r2)
// jsr [gp+r20]
// ---------------------------------------------------------------------------

static void process_jal()
{
    int64_t disp, val;
    int Ra, Rb;
    int Rt;
    
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
            emit_insn((Ra << 15)|(Rt<<7)|0x67,1);
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
		NextToken();
		val = expr();
    disp = val - code_address;
    prevToken();
    // d(Rn)? 
    if (token=='(' || token=='[') {
        printf("a ");
        NextToken();
        Ra = getRegisterX();
        if (Ra==-1) {
            printf("Illegal jump address mode.\r\n");
            Ra = 0;
        }
j2:
        if (val < -2048 || val > 2047)
            emit_insn((val & 0xFFFFF000)|0x37,1);
        emit_insn(((val & 0xFFF) << 20)|RS1(Ra)|RD(Rt)|0x67,1);
        return;
    }
    if (disp > 524287 || disp < -524288) {
        Ra = 0;
				if (val & 0x800)
					emit_insn(((val-0x800) & 0xFFFFF000) | RD(12) | 0x37, 1);
				else
					emit_insn((val & 0xFFFFF000) | RD(12) | 0x37, 1);
				emit_insn(((val & 0xFFF) << 20) | RS1(12) | RD(Rt) | 0x67, 1);
				return;
    }
    emit_insn(
        (((disp & 0x100000)>>20)<< 31) |
        (((disp & 0x7FE)>>1) << 21) |
        (((disp & 0x800)>>11) << 20) |
        (((disp & 0xFF000)>>12) << 12) |
        RD(Rt) |
        0x6F, 0
    );
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
  sz = 's';
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
  if (oc==0xF6)        // fcmp
    Rt = getRegisterX();
  else
    Rt = getFPRegister();
  need(',');
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
		FN5(oc) |
		FMT(fmt) |
		FN3(rm) |
		RS1(Ra) |
		RD(Rt) |
		83, 1
	);
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_fpeqop(int oc, int fn3)
{
	int Ra;
	int Rb;
	int Rt;
	char *p;
	int  sz;
	int fmt;

	sz = 's';
	if (*inptr == '.') {
		inptr++;
		if (strchr("sdtqSDTQ", *inptr)) {
			sz = tolower(*inptr);
			inptr++;
		}
		else
			printf("Illegal float size.\r\n");
	}
	p = inptr;
	Rt = getRegisterX();
	need(',');
	Ra = getFPRegister();
	need(',');
	Rb = getFPRegister();
	prevToken();
	switch (sz) {
	case 's': fmt = 0; break;
	case 'd': fmt = 1; break;
	case 't': fmt = 2; break;
	case 'q': fmt = 3; break;
	default:	fmt = 0; break;
	}
	emit_insn(
		FN5(oc) |
		FMT(fmt) |
		FN3(fn3) |
		RD(Rt) |
		RS1(Ra) |
		RS2(Rb) |
		83, 1
	);
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// fadd.d fp1,fp2,fp12[,rm]
// fcmp.d r1,fp3,fp10[,rm]
// ---------------------------------------------------------------------------

static void process_fprrop(int oc, int funct3)
{
  int Ra;
  int Rb;
  int Rt;
  char *p;
  int  sz;
  int fmt;
  int rm;

  rm = 0;
  sz = 's';
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
  if (oc==20)        // feq/flt/fle
    Rt = getRegisterX();
  else
    Rt = getFPRegister();
  need(',');
  Ra = getFPRegister();
  need(',');
  Rb = getFPRegister();
	if (token == ',')
		rm = getFPRoundMode();
	else
		prevToken();
	switch (sz) {
	case 's': fmt = 0; break;
	case 'd': fmt = 1; break;
	case 't': fmt = 2; break;
	case 'q': fmt = 3; break;
	default:	fmt = 0; break;
	}
	emit_insn(
		FN5(oc) |
		FMT(fmt) |
		FN3(oc==20 ? funct3 : rm) |
		RD(Rt) |
		RS1(Ra) |
		RS2(Rb) |
		83,1
	);
	ScanToEOL();
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

    Rt = getRegisterX();
    need(',');
    Ra = getRegisterX();
    prevToken();
    emitAlignedCode(1);
    emitCode(Ra);
    emitCode(Rt);
    emitCode(0x00);
    emitCode(oc);
}

// ---------------------------------------------------------------------------
// not r3,r3
// ---------------------------------------------------------------------------

static void process_umove(int oc, int funct7)
{
	int Ra;
	int Rt;

	Rt = getRegisterX();
	need(',');
	Ra = getRegisterX();
	prevToken();
	emit_insn(FN7(funct7) | RD(Rt) | RS1(Ra) | oc, !expand_flag);
	ScanToEOL();
}

// ---------------------------------------------------------------------------
// brnz r1,label
// ---------------------------------------------------------------------------

static void process_bcc(int funct3)
{
  int Ra, Rb, Rn;
  int64_t val;
  int64_t disp;

  Ra = getRegisterX();
  need(',');
  Rb = getRegisterX();
  need(',');
  NextToken();
	if (funct3 < 0) {
		Rn = Ra;
		Ra = Rb;
		Rb = Rn;
		funct3 = -funct3;
	}
  val = expr();
  disp = val - code_address;
  emit_insn(
      (((disp & 0x1000) >> 12) << 31) |
      (((disp & 0x7E0) >> 5) << 25) |
      (((disp & 0x1E) >> 1) << 8) |
      (((disp & 0x800) >> 11) << 7) |
      (Rb << 20) |
      (Ra << 15) |
      (funct3 << 12) |
      0x63,0
  );
}

static void process_beqz(int funct3)
{
	int Ra, Rb, Rn;
	int64_t val;
	int64_t disp;

	Ra = getRegisterX();
	Rb = 0;
	need(',');
	NextToken();
	if (funct3 < 0) {
		Rn = Ra;
		Ra = Rb;
		Rb = Rn;
		funct3 = -funct3;
	}
	val = expr();
	disp = val - code_address;
	emit_insn(
		(((disp & 0x1000) >> 12) << 31) |
		(((disp & 0x7E0) >> 5) << 25) |
		(((disp & 0x1E) >> 1) << 8) |
		(((disp & 0x800) >> 11) << 7) |
		(Rb << 20) |
		(Ra << 15) |
		(funct3 << 12) |
		0x63, 0
	);
}

// ---------------------------------------------------------------------------
// bra label
// ---------------------------------------------------------------------------

static void process_bra(int funct3)
{
  int64_t val;
  int64_t disp;
  int64_t ad;

  NextToken();
  val = expr();
	disp = val - code_address;
	emit_insn(
		BT(disp) |
		RS2(0) |
		RS1(0) |
		FN3(funct3) |
		0x63, 0
	);
}

// ---------------------------------------------------------------------------
// expr
// expr[Reg]
// expr[Reg+Reg*sc]
// [Reg]
// [Reg+Reg*sc]
// ---------------------------------------------------------------------------

static void mem_operand(int64_t *disp, int *regA)
{
     int64_t val;

     // chech params
     if (disp == (int64_t *)NULL)
         return;
     if (regA == (int *)NULL)
         return;

     *disp = 0;
     *regA = -1;
     if (token!='[') {;
          val = expr();
          *disp = val;
     }
     if (token=='[') {
         *regA = getRegisterX();
         if (*regA == -1) {
             printf("expecting a register\r\n");
         }
         need(']');
     }
}

// ---------------------------------------------------------------------------
// sw disp[r1],r2
// sw [r1+r2],r3
// ----------------------------------------------------------------------------

static void process_store(int oc, int func3)
{
    int Ra;
    int Rs;
    int64_t disp;

    Rs = oc==39 ? getFPRegister() : getRegisterX();
    if (Rs < 0) {
        printf("Expecting a source register.\r\n");
        ScanToEOL();
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra);
    if (Ra < 0) Ra = 0;
		/*
		if (disp < -2048 || disp > 2047) {
			emit_insn((disp & 0xFFFFF000) | (13 << 7) | 0x37, 1); // LUI
			emit_insn(((disp & 0xfff) << 20) | RD(13) | RS1(13) | 0x13, 1);	// ADDI
			emit_insn(RD(13) | RS1(13) | RS2(Ra) | 0x33,1);	// ADD
			emit_insn(RS2(Rs) | RS1(13) | FN3(func3) | oc, 1);
			return;
		}
		*/
		if ((disp < -2048 || disp > 2047)) {
			if (disp & 0x800)
				emit_insn(((disp+0x1000) & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
			else
				emit_insn((disp & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
			emit_insn(((disp & 0xfff) << 20) | RD(12) | RS1(12) | FN3(0) | 0x13, 1);	// ADDI
			emit_insn(FN7(0) | RD(12) | RS1(12) | RS2(Ra) | FN3(0) | 0x33, 1);	// ADD
			emit_insn(RS2(Rs) | RS1(12) | FN3(func3) | RD(0) | oc, !expand_flag);
			return;
    }
		/*
    if ((disp < -2048 || disp > 2047)) {
       if (OPTX32) {
        emit_insn((((0x800)>>5) << 25)|(Rs << 20)|(Ra << 15)|(func3<<12)|((disp & 0x1f) << 7)|oc,1);
        emit_insn(disp,0);
       }
       else if (OPT64) {
        emit_insn((((disp & 0xFFF)>>5) << 25)|(Rs << 20)|(Ra << 15)|(func3<<12)|((disp & 0x1f) << 7)|0x3F,!expand_flag);
        emit_insn((disp&0xFFFFF000)|oc,0);
       }
    }
    else*/
    emit_insn((((disp & 0xFFF)>>5) << 25)|RS2(Rs)|RS1(Ra)|FN3(func3)|RD(disp & 0x1f)|oc,!expand_flag);
    //ScanToEOL();
}

static void process_storec(int oc, int func3, int func5)
{
	int Rs1, Rs2;
	int Rd;
	int64_t disp;

	Rd = getRegisterX();
	if (Rd < 0) {
		printf("Expecting a target register.\r\n");
		ScanToEOL();
		return;
	}
	expect(',');
	Rs2 = getRegisterX();
	if (Rs2 < 0) {
		printf("Expecting a source register.\r\n");
		ScanToEOL();
		return;
	}
	expect(',');
	mem_operand(&disp, &Rs1);
	if (disp != 0)
		printf("No displacement allowed.\r\n");
	if (Rs1 < 0) {
		printf("An address register is needed.\r\n");
		ScanToEOL();
		return;
	}
	emit_insn(FN5(func5) | RS2(Rs2) | RS1(Rs1) | FN3(func3) | RD(Rd) | oc, !expand_flag);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_ldi()
{
  int Rt;
  int64_t val;

  Rt = getRegisterX();
  expect(',');
  val = expr();
//  if ((val < -2048 || val > 2047) && OPTLUI0)
//      emit_insn((val & 0xFFFFF000) | 0x37,1);
/*
	if ((val < -2048 || val > 2047)) {
      if (OPTX32) {
      emit_insn(((0x800) << 20)| (6 << 12) | (Rt << 7) | 0x13,1);  // ORI
      emit_insn(val,0);
    }
    else if (OPT64) {
      emit_insn(((val & 0xFFF) << 20)| (6 << 12) | (Rt << 7) | 0x3F,!expand_flag);  // ORI
      emit_insn((val&0xFFFFF000)|0x13,0);
    }
  }
  else 
	*/
	if (val < -2048 || val > 2047) {
		if (val & 0x800LL)
			emit_insn(((val+0x1000LL) & 0xFFFFF000LL) | RD(Rt) | 0x37, 1);
		else
			emit_insn((val & 0xFFFFF000LL) | RD(Rt) | 0x37, 1);
		emit_insn(((val & 0xFFFLL) << 20LL) | FN3(0) | RS1(Rt) | RD(Rt) | 0x13, !expand_flag);  // ADDI
		return;
	}
	emit_insn(((val & 0xFFFLL) << 20LL)| FN3(6) | RS1(0) | RD(Rt) | 0x13,!expand_flag);  // ORI
}

static void process_lea()
{
	int Ra;
	int Rt;
	char *p;
	int64_t disp;
	int fixup = 5;

	p = inptr;
	Rt = getRegisterX();
	if (Rt < 0) {
		printf("Expecting a target register.\r\n");
		//        printf("Line:%.60s\r\n",p);
		ScanToEOL();
		inptr -= 2;
		return;
	}
	expect(',');
	mem_operand(&disp, &Ra);
	if (Ra < 0) Ra = 0;
	if (!IsNBit(disp,12)) {
		if (disp & 0x800)
			emit_insn(((disp + 0x1000) & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
		else
			emit_insn((disp & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
		emit_insn(((disp & 0xfff) << 20) | RD(12) | RS1(12) | FN3(0) | 0x13, 1);	// ADDI
		emit_insn(FN7(0) | RD(Rt) | RS1(12) | RS2(Ra) | FN3(0) | 0x33, 1);	// ADD
		//emit_insn(RS1(12) | FN3(func3) | RD(Rt) | oc, !expand_flag);
		return;
	}
	/*
	if ((disp < -2048 || disp > 2047)) {
		 if (OPTX32) {
			emit_insn((0x800 << 20)|(Ra << 15)|(func3<<12)|(Rt<<7)|oc,1);
			emit_insn(disp,0);
		 }
		 else if (OPT64) {
			emit_insn(((disp&0x800) << 20)|(Ra << 15)|(func3<<12)|(Rt<<7)|0x3F,!expand_flag);
			emit_insn((disp&0xFFFFF000)|oc,0);
		 }
	}
	//else
	*/
	emit_insn(((disp & 0xFFF) << 20) | RS1(Ra) | FN3(0) | RD(Rt) | 19, !expand_flag);	// ADDI
	ScanToEOL();
}


// ----------------------------------------------------------------------------
// lw r1,disp[r2]
// lw r1,[r2+r3]
// ----------------------------------------------------------------------------

static void process_load(int oc, int func3)
{
    int Ra;
    int Rt;
    char *p;
    int64_t disp;
    int fixup = 5;

    p = inptr;
    Rt = oc==7 ? getFPRegister() : getRegisterX();
    if (Rt < 0) {
        printf("Expecting a target register.\r\n");
//        printf("Line:%.60s\r\n",p);
        ScanToEOL();
        inptr-=2;
        return;
    }
    expect(',');
    mem_operand(&disp, &Ra);
    if (Ra < 0) Ra = 0;
		if ((disp < -2048 || disp > 2047)) {
			if (disp & 0x800)
				emit_insn(((disp + 0x1000) & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
			else
				emit_insn((disp & 0xFFFFF000) | RD(12) | 0x37, 1); // LUI
			emit_insn(((disp & 0xfff) << 20) | RD(12) | RS1(12) | FN3(0) | 0x13, 1);	// ADDI
			emit_insn(FN7(0) | RD(12) | RS1(12) | RS2(Ra) | FN3(0) | 0x33, 1);	// ADD
			emit_insn(RS1(12) | FN3(func3) | RD(Rt) | oc, !expand_flag);
			return;
		}
		/*
    if ((disp < -2048 || disp > 2047)) {
       if (OPTX32) {
        emit_insn((0x800 << 20)|(Ra << 15)|(func3<<12)|(Rt<<7)|oc,1);
        emit_insn(disp,0);
       }
       else if (OPT64) {
        emit_insn(((disp&0x800) << 20)|(Ra << 15)|(func3<<12)|(Rt<<7)|0x3F,!expand_flag);
        emit_insn((disp&0xFFFFF000)|oc,0);
       }
    }
    //else
		*/
    emit_insn(((disp & 0xFFF) << 20)|RS1(Ra)|(func3<<12)|RD(Rt)|oc,!expand_flag);
    ScanToEOL();
}

static void process_loadr(int oc, int func3, int func5)
{
	int Ra;
	int Rt;
	char *p;
	int64_t disp;
	int fixup = 5;

	p = inptr;
	Rt = getRegisterX();
	if (Rt < 0) {
		printf("Expecting a target register.\r\n");
		//        printf("Line:%.60s\r\n",p);
		ScanToEOL();
		inptr -= 2;
		return;
	}
	expect(',');
	mem_operand(&disp, &Ra);
	if (disp != 0) {
		printf("Displacement cannot be non-zero.\r\n");
		ScanToEOL();
		return;
	}
	if (Ra < 0) Ra = 0;
	emit_insn(FN5(func5) | RS1(Ra) | FN3(func3) | RD(Rt) | oc, !expand_flag);
	ScanToEOL();
}

// ----------------------------------------------------------------------------
// mov r1,r2
// ----------------------------------------------------------------------------

static void process_mov(int oc)
{
	int Ra;
	int Rt;
	int rgd, rgs;
	char *p;
	char ch;
    
	SkipSpaces();
	p = inptr;
	rgd = inptr[0];
	if (inptr[1] != ':') {
		inptr = p;
		rgd = -1;
	}
	else
		inptr += 2;
	switch (rgd) {
	case 'M': case 'm': rgd = 3; break;
	case 'H': case 'h': rgd = 2; break;
	case 'S': case 's': rgd = 1; break;
	case 'U': case 'u': rgd = 0; break;
	}
	Rt = getRegisterX();
	need(',');
	SkipSpaces();
	p = inptr;
	rgs = inptr[0];
	if (inptr[1] != ':') {
		inptr = p;
		rgs = -1;
	}
	else
		inptr += 2;
	switch (rgs) {
	case 'M': case 'm': rgs = 3; break;
	case 'H': case 'h': rgs = 2; break;
	case 'S': case 's': rgs = 1; break;
	case 'U': case 'u': rgs = 0; break;
	}
	Ra = getRegisterX();
	if (rgs == -1 && rgd == -1)
		emit_insn(RD(Rt) | RS2(0) | RS1(Ra) | FN3(6) | 51, 1);	// OR Rd,Ra,R0
	else {
		if (rgd == -1)
			rgd = 0;
		if (rgs == -1)
			rgs = 0;
		emit_insn(FN7(2) | RD(Rt) | RS2((rgs << 2) | rgd) | RS1(Ra) | FN3(0) | 13, 1);
	}
	prevToken();
	ScanToEOL();
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
// ----------------------------------------------------------------------------

static void process_setto(int oc, int func3, int func7)
{
	int Rs2;
	int Rs1;

	Rs1 = getRegisterX();
	need(',');
	Rs2 = getRegisterX();
	emit_insn(
		FN7(func7) |
		FN3(func3) |
		RS2(Rs2) |
		RS1(Rs1) |
		RD(0) |
		oc, 1
	);
}

// ----------------------------------------------------------------------------
// srli r1,r2,#5
// ----------------------------------------------------------------------------

static void process_shifti(int oc, int funct3, int funct7)
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
	emit_insn(FN7(funct7) | ((val & 0x1F) << 20) | RS1(Ra) | FN3(funct3) | RD(Rt) | oc,1);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_getto(int oc, int func3, int func7)
{
	int Rd;
	int Rs1;

	Rd = getRegisterX();
	need(',');
	Rs1 = getRegisterX();
	emit_insn(
		FN7(func7) |
		FN3(func3) |
		RS1(Rs1) |
		RD(Rd) |
		oc, 1
	);
}

static void process_getzl(int oc, int func3, int func7)
{
	int Rd;

	Rd = getRegisterX();
	emit_insn(
		FN7(func7) |
		FN3(func3) |
		RD(Rd) |
		oc, 1
	);
	prevToken();
	ScanToEOL();
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
    
    spr = getSprRegister();
    need(',');
    Ra = getRegisterX();
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
    
    Rt = getRegisterX();
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

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

static void process_call()
{
	int64_t val;
	int Ra = 0;
	int Rt = 1;

	NextToken();
	if (token == '[')
		val = 0;
	else
		val = expr();
	if (token == '[') {
		Ra = getRegisterX();
		need(']');
	}
	if (Ra == 0) {
		val -= code_address;
		if (IsNBit(val, 21)) {
			emit_insn(
				(((val & 0x100000) >> 20) << 31) |
				(((val & 0x7FE) >> 1) << 21) |
				(((val & 0x800) >> 11) << 20) |
				(((val & 0xFF000) >> 12) << 12) |
				RD(Rt) |
				0x6F, 0
			);
			return;
		}
		val += code_address;
		if (val & 0x800LL)
			emit_insn(((val - 0x800LL) & 0xFFFFF000LL) | RD(12) | 0x37, 1);
		else
			emit_insn((val & 0xFFFFF000LL) | RD(12) | 0x37, 1);
		emit_insn(((val & 0xFFFLL) << 20LL) | RS1(12) | RD(Rt) | 0x67, 1);
		return;
	}
	if (val == 0) {
		emit_insn(((val & 0xFFF) << 20) | RS1(Ra) | RD(Rt) | 0x67, 1);
		return;
	}
	if (Ra == 0) {
		if (val < -2048 || val > 2047) {
			if (val & 0x800)
				emit_insn(((val-0x800) & 0xFFFFF000) | RD(12) | 0x37, 1);
			else
				emit_insn((val & 0xFFFFF000) | RD(12) | 0x37, 1);
			emit_insn(((val & 0xFFF) << 20) | RS1(12) | RD(Rt) | 0x67, 1);
			return;
		}
		emit_insn(((val & 0xFFF) << 20) | RS1(12) | RD(Rt) | 0x67, 1);
		return;
	}
	if (val < -2048 || val > 2047) {
		if (val & 0x800)
			emit_insn(((val - 0x800) & 0xFFFFF000) | RD(12) | 0x37, 1);
		else
			emit_insn((val & 0xFFFFF000) | RD(12) | 0x37, 1);
		emit_insn(FN7(0) | RD(12) | RS2(12) | RS1(Ra) | FN3(0) | 0x33, 1);	// ADD
		emit_insn(((val & 0xFFF) << 20) | RS1(12) | RD(Rt) | 0x67, 1);
	}
	return;
}

static void process_csrrw(int opcode3)
{
  int Rd;
  int Rs = 0;
  int64_t val;
  int64_t val2 = 0;
  int flag = 0;
	char *p;

  Rd = getRegisterX();
  need(',');
  NextToken();
  val = expr();
  prevToken();
  need(',');
  NextToken();
	p = inptr;
	NextToken();
  if (token=='#') {
    val2 = expr();
	flag = 4;
  }
  else {
		inptr = p;
    Rs = getRegisterX();
	prevToken();
  }
  emit_insn((val << 20) | RS1(Rs|val2) | FN3(opcode3|flag) | RD(Rd) | 0x73,!expand_flag);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_fmv(int64_t oc)
{
	int Rt;
	int Ra;
	char *p;

	p = inptr;
	Rt = getRegisterX();
	if (Rt == -1) {
		inptr = p;
		Rt = getFPRegister();
		if (Rt == -1) {
			printf("Target register required.");
			return;
		}
		need(',');
		Ra = getRegisterX();
		emit_insn(
			FN5(30) |
			RS1(Ra) |
			RD(Rt) |
			83,1
		);
		goto xit;
	}
	need(',');
	Ra = getFPRegister();
	emit_insn(
		FN5(28) |
		RS1(Ra) |
		RD(Rt) |
		83, 1
	);
xit:
	prevToken();
	ScanToEOL();
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

static void process_fcvt(int64_t oc)
{
	char *p;
	int tgt;
	int src;
	int Rs2;
	int Rs1;
	int Rd;

	Rs2 = 0;
	if (*inptr == '.') {
		inptr++;
		if (*inptr == 's' || *inptr == 'S') {
			inptr++;
			tgt = 0xD;
			if (*inptr == '.')
				inptr++;
			if (*inptr == 'w' || *inptr == 'W') {
				inptr++;
				if (*inptr == 'u' || *inptr == 'U') {
					inptr++;
					Rs2 = 1;
				}
			}
		}
		else if (*inptr == 'w' || *inptr == 'W') {
			tgt = 0xC;
			inptr++;
			if (*inptr == 'u' || *inptr == 'U') {
				Rs2 = 1;
				inptr++;
			}
			if (*inptr == '.')
				inptr++;
			if (*inptr == 's' || *inptr == 'S')
				inptr++;
		}
	}
	if (tgt == 0xD)
		Rd = getFPRegister();
	else
		Rd = getRegisterX();
	need(',');
	if (tgt == 0x0D)
		Rs1 = getRegisterX();
	else
		Rs1 = getFPRegister();
	prevToken();
	ScanToEOL();
	emit_insn(oc | (tgt << 28) | RS2(Rs2) | RS1(Rs1) | RD(Rd), 1);
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
     compress_flag = 0;
     segprefix = -1;
     if (bGen && (segment==codeseg || segment==dataseg || segment==rodataseg)) {
    nn = binstart;
    cc = 8;
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
        for (mm = nn; nn < mm + cc && nn < sections[segment].index; nn+=4) {
            fprintf(ofp, "%02X", sections[segment].bytes[nn+3]);
            fprintf(ofp, "%02X", sections[segment].bytes[nn+2]);
            fprintf(ofp, "%02X", sections[segment].bytes[nn+1]);
            fprintf(ofp, "%02X", sections[segment].bytes[nn]);
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

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void Friscv_processMaster()
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
    first_org = 1;
    first_rodata = 1;
    first_data = 1;
    first_bss = 1;
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
    NextToken();
    while (token != tk_eof) {
//        printf("\t%.*s\n", inptr-stptr-1, stptr);
//        printf("token=%d\r", token);
        switch(token) {
        case tk_eol: ProcessEOL(1); break;
//        case tk_add:  process_add(); break;
        case tk_add:  process_rrop(0x33,0x00,0x00); break;
        case tk_addi: process_addi(0); break;
        case tk_align: process_align(); continue; break;
        case tk_and:  process_rrop(0x33,0x07,0x00); break;
        case tk_andi:  process_addi(7); break;
        case tk_beq: process_bcc(0); break;
				case tk_beqz: process_beqz(0); break;
				case tk_bge: process_bcc(5); break;
        case tk_bgeu: process_bcc(7); break;
				case tk_bgt: process_bcc(-4); break;
				case tk_bgtu: process_bcc(-6); break;
				case tk_ble: process_bcc(-5); break;
				case tk_bleu: process_bcc(-7); break;
				case tk_blt: process_bcc(4); break;
        case tk_bltu: process_bcc(6); break;
				case tk_bltz: process_beqz(4); break;
				case tk_bmc: process_pfree(5); break;
				case tk_bms: process_palloc(4); break;
				case tk_bne: process_bcc(1); break;
				case tk_bnez: process_beqz(1); break;
				case tk_bra: process_bra(0); break;
        case tk_bsr: process_bra(0x56); break;
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
				case tk_call:  process_call(); break;
				case tk_cli: emit_insn(0x3100000001,1); break;
        case tk_code: process_code(); break;
        case tk_com: process_rop(0x06); break;
        case tk_cs:  segprefix = 15; break;
        case tk_csrrc: process_csrrw(3); break;
        case tk_csrrs: process_csrrw(2); break;
        case tk_csrrw: process_csrrw(1); break;
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
        case tk_dc:  process_dc(); break;
				case tk_dd:  process_dd(); break;
				case tk_dcb:  process_db(); break;
				case tk_dco:  process_dco(); break;
				case tk_decto: emit_insn(0x1600000D,1); break;
				case tk_dh:  process_dh(); break;
				case tk_div: process_rrop(0x33, 0x04, 0x01); break;
				case tk_divu: process_rrop(0x33, 0x05, 0x01); break;
        case tk_dw:  process_dw(); break;
        case tk_end: goto j1;
        case tk_endpublic: break;
        case tk_eor: process_rrop(0x33,0x04,0x00); break;
        case tk_eori: process_riop(0x13,0x04,0x00); break;
				case tk_ecall: emit_insn(0x00000073, 1); break;
				case tk_eret: emit_insn(0x10000073, 1); break;
				case tk_extern: process_extern(); break;
        case tk_fabs: process_fprop(0x88); break;
        case tk_fadd: process_fprrop(0,0); break;
        //case tk_fcmp: process_fprrop(0xF6); break;
				case tk_fcvt: process_fcvt(0xC0000053); break;
        case tk_fdiv: process_fprrop(3,0); break;
				case tk_feq: process_fpeqop(20, 2); break;
				case tk_fill: process_fill(); break;
        case tk_fix2flt: process_fprop(0x84); break;
				case tk_fle: process_fpeqop(20, 0); break;
//				case tk_flq:	process_load(0x07, 4); break;
				case tk_flt: process_fpeqop(20, 1); break;
				case tk_flt2fix: process_fprop(0x85); break;
				case tk_flw:	process_load(0x07,2); break;
        case tk_fmov: process_fprop(0x87); break;
				case tk_fmv: process_fmv(83); break;
        case tk_fmul: process_fprrop(2,0); break;
        case tk_fnabs: process_fprop(0x89); break;
        case tk_fneg: process_fprop(0x8A); break;
        case tk_frm: process_fpstat(0x78); break;
//				case tk_fsq:	process_store(39, 4); break;
				case tk_fsqrt: process_fprop(11); break;
				case tk_fstat: process_fprdstat(0x86); break;
        case tk_fsub: process_fprrop(1,0); break;
				case tk_fsw:	process_store(39, 2); break;
				case tk_ftx: process_fpstat(0x75); break;
        case tk_gran: process_gran(0x14); break;
				case tk_getrdy: process_getto(13, 0, 14); break;
				case tk_getto: process_getto(13, 0, 9); break;
				case tk_getzl: process_getzl(13, 0, 10); break;
				case tk_if:		pif1 = inptr - 2; doif(); break;
				case tk_ifdef:		pif1 = inptr - 5; doifdef(); break;
				case tk_insiof: process_pfree(16); break;
				case tk_insrdy: process_setto(13, 0, 12); break;
				case tk_jal: process_jal(); break;
        case tk_jmp: process_jal(); break;
        case tk_lb:  process_load(0x03,0); break;
				case tk_ldb:  process_load(0x03, 0); break;
				case tk_lbu: process_load(0x03,4); break;
				case tk_ldbu: process_load(0x03, 4); break;
//				case tk_ld: process_ldi(); break;
        case tk_ldi: process_ldi(); break;
        case tk_lh:  process_load(0x03,1); break;
        case tk_lhu: process_load(0x03,5); break;
				case tk_ldo: process_load(0x03, 3); break;
				case tk_ldt:  process_load(0x03, 2); break;
				case tk_ldtu:  process_load(0x03, 6); break;
				case tk_ldw:  process_load(0x03, 1); break;
				case tk_ldwu: process_load(0x03, 5); break;
				case tk_lea: process_lea(); break;
					//        case tk_lui: process_lui(); break;
				case tk_lr:  process_loadr(0x2f, 0x02, 0x02); break;
				case tk_lw:  process_load(0x03,2); break;
				case tk_macro:	process_macro(); break;
				case tk_mfspr: process_mfspr(0x49); break;
				//case tk_mfu: process_umove(13, 2); break;
        case tk_mov: process_mov(0x04); break;
        case tk_mtspr: process_mtspr(0x48); break;
				//case tk_mtu: process_umove(13, 3); break;
				case tk_mul: process_rrop(0x33,0x00,0x01); break;
				case tk_mvmap: process_rrop(13, 0x00, 0x01); break;
				case tk_mvseg: process_rrop(13, 0x00, 0x00); break;
				case tk_neg: process_rop(0x05); break;
        case tk_nop: emit_insn(0x00000013,1); break;
        case tk_not: process_rop(0x07); break;
				case tk_nxtiof: process_getzl(13, 0, 18); break;
        case tk_or:  process_rrop(0x33,0x06,0x00); break;
        case tk_ori: process_addi(6); break;
        case tk_org: process_org(); break;
				case tk_palloc: process_palloc(4); break;
				case tk_pfi: emit_insn(0x10300073, 1); break;
				case tk_pfree: process_pfree(5); break;
				case tk_php: emit_insn(0x3200000001,1); break;
        case tk_plp: emit_insn(0x3300000001,1); break;
        case tk_plus: expand_flag = 1; break;
				case tk_prviof: process_getzl(13, 0, 19); break;
				case tk_public: process_public(); break;
				case tk_qryrdy: process_getto(13, 0, 15); break;
				case tk_rem: process_rrop(0x33, 0x06, 0x01); break;
				case tk_remu: process_rrop(0x33, 0x07, 0x01); break;
				case tk_ret:	emit_insn(0x00008067, 1); break;
				case tk_rmviof: process_getto(13, 0, 17); break;
				case tk_rmvrdy: process_palloc(13); break;
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
        case tk_rts: process_rts(0x60); break;
        case tk_sb:  process_store(0x23,0); break;
				case tk_sc:  process_storec(0x2F, 0x02, 0x03); break;
				case tk_sei: emit_insn(0x3000000001,1); break;
				case tk_setto: process_setto(13, 0, 8); break;
        case tk_slt:  process_rrop(0x33,0x02,0x00); break;
        case tk_sltu:  process_rrop(0x33,0x03,0x00); break;
        case tk_slti:  process_riop(0x13,0x02,0x00); break;
        case tk_sltui:  process_riop(0x13,0x03,0x00); break;
        case tk_sh:  process_store(0x23,1); break;
				case tk_sll: process_rrop(0x33, 0x01, 0x00); break;
				case tk_sra: process_rrop(0x33, 0x05, 0x20); break;
				case tk_srl: process_rrop(0x33, 0x05, 0x00); break;
				case tk_slli: process_shifti(0x13,0x01,0x00); break;
        case tk_srai: process_shifti(0x13,0x05,0x10); break;
        case tk_srli: process_shifti(0x13,0x05,0x00); break;
				case tk_stb:  process_store(0x23, 0); break;
				case tk_stt: process_store(0x23, 2); break;
				case tk_sto: process_store(0x23, 3); break;
				case tk_stw:  process_store(0x23, 1); break;
				case tk_sub:  process_rrop(0x33,0x00,0x20); break;
//        case tk_sub:  process_sub(); break;
        case tk_sxb: process_rop(0x08); break;
        case tk_sxc: process_rop(0x09); break;
        case tk_sxh: process_rop(0x0A); break;
        case tk_sw:  process_store(0x23,2); break;
				case tk_swap: process_rop(0x03); break;
				case tk_wai: emit_insn(0x10100073, 1); break;
				case tk_wfi: emit_insn(0x10100073, 1); break;
				case tk_xor: process_rrop(0x33,0x04,0x00); break;
        case tk_xori: process_riop(0x13,0x04,0x00); break;
        case tk_id:  process_label(); break;
        case '-': compress_flag = 1; break;
        }
        NextToken();
    }
j1:
    ;
}

