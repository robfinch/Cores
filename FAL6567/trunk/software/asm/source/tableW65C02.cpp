#include <stdio.h>
#include <stdlib.h>
#include "operands6502.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "am.h"
#include "am6502.h"
#include "asm6502.h"
#include "PseudoOp.h"

#define MAX_OPERANDS 60
/*
extern "C" {
int Asm6502::imm(Opa*);
};
*/
namespace RTFClasses
{
	static Opa adcAsm[] =
	{
		{Asm6502::imm, 0x69, 1, AM_IMM, 2},
		{Asm6502::zp, 0x65, 1, AM_Z,4},
		{Asm6502::zp, 0x75, 1, AM_ZX,5},
		{Asm6502::abs, 0x79, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0x61, 1, AM_IX,8},
		{Asm6502::zp, 0x71, 1, AM_IY,7},
		{Asm6502::zp, 0x72, 1, AM_ZI,7},
		{Asm6502::abs, 0x6D, 1, AM_A,5},
		{Asm6502::abs, 0x7D, 1, AM_AX,5},
		{Asm6502::abs, 0x79, 1, AM_AY,5},
		NULL
	};

	static Opa andAsm[] =
	{
		{Asm6502::imm, 0x29, 1, AM_IMM,2},
		{Asm6502::zp, 0x25, 1, AM_Z,4},
		{Asm6502::zp, 0x35, 1, AM_ZX,5},
		{Asm6502::abs, 0x39, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0x21, 1, AM_IX,8},
		{Asm6502::zp, 0x31, 1, AM_IY,7},
		{Asm6502::zp, 0x32, 1, AM_ZI,7},
		{Asm6502::abs, 0x2D, 1, AM_A,5},
		{Asm6502::abs, 0x3D, 1, AM_AX,5},
		{Asm6502::abs, 0x39, 1, AM_AY,5},
		NULL
	};

	static Opa aslAsm[] =
	{
		{Asm6502::out8, 0x0a, 0, AM_,2},
		{Asm6502::out8, 0x0a, 1, AM_ACC,2},
		{Asm6502::zp, 0x06, 1, AM_Z,7},
		{Asm6502::zp, 0x16, 1, AM_ZX,8},
		{Asm6502::abs, 0x0E, 1, AM_A,8},
		{Asm6502::abs, 0x1E, 1, AM_AX,9},
		NULL
	};

	static Opa rolAsm[] =
	{
		{Asm6502::out8, 0x2a, 0, AM_,2},
		{Asm6502::out8, 0x2a, 1, AM_ACC,2},
		{Asm6502::zp, 0x26, 1, AM_Z,7},
		{Asm6502::zp, 0x36, 1, AM_ZX,8},
		{Asm6502::abs, 0x2E, 1, AM_A,8},
		{Asm6502::abs, 0x3E, 1, AM_AX,9},
		NULL
	};

	static Opa rorAsm[] =
	{
		{Asm6502::out8, 0x6a, 0, AM_,2},
		{Asm6502::out8, 0x6a, 1, AM_ACC,2},
		{Asm6502::zp, 0x66, 1, AM_Z,7},
		{Asm6502::zp, 0x76, 1, AM_ZX,8},
		{Asm6502::abs, 0x6E, 1, AM_A,8},
		{Asm6502::abs, 0x7E, 1, AM_AX,9},
		NULL
	};

	static Opa lsrAsm[] =
	{
		{Asm6502::out8, 0x4a, 0, AM_,2},
		{Asm6502::out8, 0x4a, 1, AM_ACC,2},
		{Asm6502::zp, 0x46, 1, AM_Z,7},
		{Asm6502::zp, 0x56, 1, AM_ZX,8},
		{Asm6502::abs, 0x4E, 1, AM_A,8},
		{Asm6502::abs, 0x5E, 1, AM_AX,9},
		NULL
	};

	static Opa bccAsm[] = {	{Asm6502::br, 0x90, 1, 0, 0, 2}, NULL };
	static Opa bcsAsm[] = {	{Asm6502::br, 0xB0, 1, 0, 0, 2}, NULL };
	static Opa beqAsm[] = {	{Asm6502::br, 0xF0, 1, 0, 0, 2}, NULL };
	static Opa bmiAsm[] = {	{Asm6502::br, 0x30, 1, 0, 0, 2}, NULL };
	static Opa bneAsm[] = {	{Asm6502::br, 0xD0, 1, 0, 0, 2}, NULL };
	static Opa bplAsm[] = {	{Asm6502::br, 0x10, 1, 0, 0, 2}, NULL };
	static Opa bvcAsm[] = {	{Asm6502::br, 0x50, 1, 0, 0, 2}, NULL };
	static Opa bvsAsm[] = {	{Asm6502::br, 0x70, 1, 0, 0, 2}, NULL };
	static Opa braAsm[] = {	{Asm6502::br, 0x80, 1, 0, 0, 2}, NULL };
	static Opa brkAsm[] = {	{Asm6502::out8, 0x00, 0, 0, 0, 10}, NULL };

	static Opa bitAsm[] =
	{
		{Asm6502::imm, 0x89, 1, AM_IMM,2},
		{Asm6502::zp, 0x24, 1, AM_Z,4},
		{Asm6502::zp, 0x34, 1, AM_ZX,5},
		{Asm6502::abs, 0x2C, 1, AM_A,5},
		{Asm6502::abs, 0x3C, 1, AM_AX,5},
		NULL
	};

	static Opa tsbAsm[] =
	{
		{Asm6502::zp, 0x04, 1, AM_Z},
		{Asm6502::abs, 0x0C, 1, AM_A},
		NULL
	};

	static Opa trbAsm[] =
	{
		{Asm6502::zp, 0x14, 1, AM_Z},
		{Asm6502::abs, 0x1C, 1, AM_A},
		NULL
	};

	static Opa clcAsm[] = { {Asm6502::out8, 0x18, 0, 0, 2}, NULL };
	static Opa cldAsm[] = { {Asm6502::out8, 0xD8, 0, 0, 2}, NULL };
	static Opa cliAsm[] = { {Asm6502::out8, 0x58, 0, 0, 2}, NULL };
//	static Opa natAsm[] = { {Asm6502::out8, 0xFB, 0, 0, 2}, NULL };
	static Opa xceAsm[] = { {Asm6502::out8, 0xFB, 0, 0, 2}, NULL };
	static Opa clvAsm[] = { {Asm6502::out8, 0xB8, 0, 0, 2}, NULL };
	static Opa dexAsm[] = { {Asm6502::out8, 0xCA, 0, 0, 2}, NULL };
	static Opa deyAsm[] = { {Asm6502::out8, 0x88, 0, 0, 2}, NULL };
	static Opa inxAsm[] = { {Asm6502::out8, 0xE8, 0, 0, 2}, NULL };
	static Opa inyAsm[] = { {Asm6502::out8, 0xC8, 0, 0, 2}, NULL };

	static Opa secAsm[] = { {Asm6502::out8, 0x38, 0, 0, 2}, NULL };
	static Opa sedAsm[] = { {Asm6502::out8, 0xF8, 0, 0, 2}, NULL };
	static Opa seiAsm[] = { {Asm6502::out8, 0x78, 0, 0, 2}, NULL };

	static Opa phaAsm[] = { {Asm6502::out8, 0x48, 0, 0, 3}, NULL };
	static Opa phxAsm[] = { {Asm6502::out8, 0xDA, 0, 0, 3}, NULL };
	static Opa phyAsm[] = { {Asm6502::out8, 0x5A, 0, 0, 3}, NULL };
	static Opa phpAsm[] = { {Asm6502::out8, 0x08, 0, 0, 3}, NULL };
	static Opa plaAsm[] = { {Asm6502::out8, 0x68, 0, 0, 4}, NULL };
	static Opa plxAsm[] = { {Asm6502::out8, 0xFA, 0, 0, 4}, NULL };
	static Opa plyAsm[] = { {Asm6502::out8, 0x7A, 0, 0, 4}, NULL };
	static Opa plpAsm[] = { {Asm6502::out8, 0x28, 0, 0, 4}, NULL };

	static Opa rtiAsm[] = { {Asm6502::out8, 0x40, 0, 0, 10}, NULL };
	static Opa rtsAsm[] = { {Asm6502::out8, 0x60, 0, 0, 7}, NULL };
	static Opa stpAsm[] = { {Asm6502::out8, 0xDB, 0, 0, 2}, NULL };

	static Opa taxAsm[] = { {Asm6502::out8, 0xAA, 0, 0, 2}, NULL };
	static Opa tayAsm[] = { {Asm6502::out8, 0xA8, 0, 0, 2}, NULL };
	static Opa tsxAsm[] = { {Asm6502::out8, 0xBA, 0, 0, 2}, NULL };
	static Opa txaAsm[] = { {Asm6502::out8, 0x8A, 0, 0, 2}, NULL };
	static Opa txsAsm[] = { {Asm6502::out8, 0x9A, 0, 0, 2}, NULL };
	static Opa tyaAsm[] = { {Asm6502::out8, 0x98, 0, 0, 2}, NULL };

	static Opa nopAsm[] = { {Asm6502::out8, 0xEA, 0, 0, 0, 2}, NULL };

	static Opa cmpAsm[] =
	{
		{Asm6502::imm, 0xC9, 1, AM_IMM,2},
		{Asm6502::zp, 0xC5, 1, AM_Z,4},
		{Asm6502::zp, 0xD5, 1, AM_ZX,5},
		{Asm6502::abs, 0xD9, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0xC1, 1, AM_IX,8},
		{Asm6502::zp, 0xD1, 1, AM_IY,7},
		{Asm6502::zp, 0xD2, 1, AM_ZI,7},
		{Asm6502::abs, 0xCD, 1, AM_A,5},
		{Asm6502::abs, 0xDD, 1, AM_AX,5},
		{Asm6502::abs, 0xD9, 1, AM_AY,5},
		NULL
	};

	static Opa cpxAsm[] =
	{
		{Asm6502::imm, 0xE0, 1, AM_IMM,2},
		{Asm6502::zp, 0xE4, 1, AM_Z,4},
		{Asm6502::abs, 0xEC, 1, AM_A,5},
		NULL
	};

	static Opa cpyAsm[] =
	{
		{Asm6502::imm, 0xC0, 1, AM_IMM,2},
		{Asm6502::zp, 0xC4, 1, AM_Z,4},
		{Asm6502::abs, 0xCC, 1, AM_A,5},
		NULL
	};

	static Opa decAsm[] =
	{
		{Asm6502::out8, 0x3a, 1, AM_ACC,2},
		{Asm6502::zp, 0xC6, 1, AM_Z,7},
		{Asm6502::zp, 0xD6, 1, AM_ZX,8},
		{Asm6502::abs, 0xCE, 1, AM_A,8},
		{Asm6502::abs, 0xDE, 1, AM_AX,9},
		NULL
	};

	static Opa incAsm[] =
	{
		{Asm6502::out8, 0x1a, 1, AM_ACC,2},
		{Asm6502::zp, 0xE6, 1, AM_Z,7},
		{Asm6502::zp, 0xF6, 1, AM_ZX,8},
		{Asm6502::abs, 0xEE, 1, AM_A,8},
		{Asm6502::abs, 0xFE, 1, AM_AX,9},
		NULL
	};

	static Opa deaAsm[] = {{Asm6502::out8, 0x3a, 0, 0, 2}, NULL };
	static Opa inaAsm[] = {{Asm6502::out8, 0x1a, 0, 0, 2}, NULL };

	static Opa eorAsm[] =
	{
		{Asm6502::imm, 0x49, 1, AM_IMM,2},
		{Asm6502::zp, 0x45, 1, AM_Z,4},
		{Asm6502::zp, 0x55, 1, AM_ZX,5},
		{Asm6502::abs, 0x59, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0x41, 1, AM_IX,8},
		{Asm6502::zp, 0x51, 1, AM_IY,7},
		{Asm6502::zp, 0x52, 1, AM_ZI,7},
		{Asm6502::abs, 0x4D, 1, AM_A,5},
		{Asm6502::abs, 0x5D, 1, AM_AX,5},
		{Asm6502::abs, 0x59, 1, AM_AY,5},
		NULL
	};

	static Opa sbcAsm[] =
	{
		{Asm6502::imm, 0xE9, 1, AM_IMM,2},
		{Asm6502::zp, 0xE5, 1, AM_Z,4},
		{Asm6502::zp, 0xF5, 1, AM_ZX,5},
		{Asm6502::abs, 0xF9, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0xE1, 1, AM_IX,8},
		{Asm6502::zp, 0xF1, 1, AM_IY,7},
		{Asm6502::zp, 0xF2, 1, AM_ZI,7},
		{Asm6502::abs, 0xED, 1, AM_A,5},
		{Asm6502::abs, 0xFD, 1, AM_AX,5},
		{Asm6502::abs, 0xF9, 1, AM_AY,5},
		NULL
	};

	static Opa oraAsm[] =
	{
		{Asm6502::imm, 0x09, 1, AM_IMM,2},
		{Asm6502::zp, 0x05, 1, AM_Z,4},
		{Asm6502::zp, 0x15, 1, AM_ZX,5},
		{Asm6502::abs, 0x19, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0x01, 1, AM_IX,8},
		{Asm6502::zp, 0x11, 1, AM_IY,7},
		{Asm6502::zp, 0x12, 1, AM_ZI,7},
		{Asm6502::abs, 0x0D, 1, AM_A,5},
		{Asm6502::abs, 0x1D, 1, AM_AX,5},
		{Asm6502::abs, 0x19, 1, AM_AY,5},
		NULL
	};

	static Opa staAsm[] =
	{
		{Asm6502::zp, 0x85, 1, AM_Z,4},
		{Asm6502::zp, 0x95, 1, AM_ZX,5},
		{Asm6502::abs, 0x99, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0x81, 1, AM_IX,8},
		{Asm6502::zp, 0x91, 1, AM_IY,7},
		{Asm6502::zp, 0x92, 1, AM_ZI,7},
		{Asm6502::abs, 0x8D, 1, AM_A,5},
		{Asm6502::abs, 0x9D, 1, AM_AX,5},
		{Asm6502::abs, 0x99, 1, AM_AY,5},
		NULL
	};

	static Opa stxAsm[] =
	{
		{Asm6502::zp, 0x86, 1, AM_Z,4},
		{Asm6502::zp, 0x96, 1, AM_ZY,5},
		{Asm6502::abs, 0x8E, 1, AM_A,5},
		NULL
	};

	static Opa styAsm[] =
	{
		{Asm6502::zp, 0x84, 1, AM_Z,4},
		{Asm6502::zp, 0x94, 1, AM_ZX,5},
		{Asm6502::abs, 0x8C, 1, AM_A,5},
		NULL
	};

	static Opa stzAsm[] =
	{
		{Asm6502::zp, 0x64, 1, AM_Z,4},
		{Asm6502::zp, 0x74, 1, AM_ZX,5},
		{Asm6502::abs, 0x9C, 1, AM_A,5},
		{Asm6502::abs, 0x9E, 1, AM_AX,5},
		NULL
	};

	static Opa ldaAsm[] =
	{
		{Asm6502::imm, 0xA9, 1, AM_IMM,2},
		{Asm6502::zp, 0xA5, 1, AM_Z,4},
		{Asm6502::abs, 0xB9, 1, AM_ZY,5},	// force abs,y
		{Asm6502::zp, 0xB5, 1, AM_ZX,5},
		{Asm6502::zp, 0xA1, 1, AM_IX,6},
		{Asm6502::zp, 0xB1, 1, AM_IY,7},
		{Asm6502::zp, 0xB2, 1, AM_ZI,5},
		{Asm6502::abs, 0xAD, 1, AM_A,5},
		{Asm6502::abs, 0xBD, 1, AM_AX,5},
		{Asm6502::abs, 0xB9, 1, AM_AY,5},
		NULL
	};

	static Opa ldxAsm[] =
	{
		{Asm6502::imm, 0xA2, 1, AM_IMM,2},
		{Asm6502::zp, 0xA6, 1, AM_Z,4},
		{Asm6502::zp, 0xB6, 1, AM_ZY,5},
		{Asm6502::abs, 0xAE, 1, AM_A,5},
		{Asm6502::abs, 0xBE, 1, AM_AY,5},
		NULL
	};

	static Opa ldyAsm[] =
	{
		{Asm6502::imm, 0xA0, 1, AM_IMM,2},
		{Asm6502::zp, 0xA4, 1, AM_Z,4},
		{Asm6502::zp, 0xB4, 1, AM_ZX,5},
		{Asm6502::abs, 0xAC, 1, AM_A,5},
		{Asm6502::abs, 0xBC, 1, AM_AX,5},
		NULL
	};

	static Opa jmpAsm[] =
	{
		{Asm6502::abs, 0x4c, 1, AM_A,3},
		{Asm6502::abs, 0x4c, 1, AM_Z,3},	// Force abs
		{Asm6502::abs, 0x6c, 1, AM_I,7},
		{Asm6502::abs, 0x7c, 1, AM_IX,7},
		{Asm6502::abs, 0x6c, 1, AM_ZI,7},	// force abs
		NULL
	};

	static Opa jmlAsm[] =
	{
		{Asm6502::jml_abs, 0x5c, 1, AM_A,5},
		NULL
	};
	static Opa jsrAsm[] =
	{
		{Asm6502::abs, 0x20, 1, AM_A,8} ,
		{Asm6502::abs, 0x20, 1, AM_Z,8},	// force abs
		NULL
	};



static Mne opsW65C02[] =
{
	{"adc", adcAsm, 1 },
	{"and", andAsm, 1 },
	{"asl", aslAsm, 1 },
	{"bcc", bccAsm, 1 },
	{"bcs", bcsAsm, 1 },
	{"beq", beqAsm, 1 },
	{"bgeu", bccAsm, 1 },
	{"bit", bitAsm, 1 },
	{"bltu", bcsAsm, 1 },
	{"bmi", bmiAsm, 1 },
	{"bne", bneAsm, 1 },
	{"bpl", bplAsm, 1 },
	{"bra", braAsm, 1 },
	{"brk", brkAsm, 1 },
	{"bvc", bvcAsm, 1 },
	{"bvs", bvsAsm, 1 },

	{"clc", clcAsm, 0 },
	{"cld", cldAsm, 0 },
	{"cli", cliAsm, 0 },
	{"clv", clvAsm, 0 },
	{"cmp", cmpAsm, 1 },
	{"cpx", cpxAsm, 1 },
	{"cpy", cpyAsm, 1 },
	
	{"dea", deaAsm, 0 },
	{"dec", decAsm, 1 },
	{"dex", dexAsm, 0 },
	{"dey", deyAsm, 0 },
	
	{"eor", eorAsm, 1 },

	{"ina", inaAsm, 0 },
	{"inc", incAsm, 1 },
	{"inx", inxAsm, 0 },
	{"iny", inyAsm, 0 },
	
	{"jml", jmlAsm, 1 },
	{"jmp", jmpAsm, 1 },
	{"jsr", jsrAsm, 1 },

    {"lda", ldaAsm, 1 },
    {"ldx", ldxAsm, 1 },
    {"ldy", ldyAsm, 1 },

	{"lsr", lsrAsm, 1 },
//	{"nat", natAsm, 0 },
	{"nop", nopAsm, 0 },

	{"ora", oraAsm, 1 },
	
	{"pha", phaAsm, 0 },
	{"php", phpAsm, 0 },
	{"phx", phxAsm, 0 },
	{"phy", phyAsm, 0 },
	{"pla", plaAsm, 0 },
	{"plp", plpAsm, 0 },
	{"plx", plxAsm, 0 },
	{"ply", plyAsm, 0 },
	
	{"rol", rolAsm, 1 },
	{"ror", rorAsm, 1 },

	{"rti", rtiAsm, 0 },
	{"rts", rtsAsm, 0 },

	{"sbc", sbcAsm, 1 },

	{"sec", secAsm, 0 },
	{"sed", sedAsm, 0 },
	{"sei", seiAsm, 0 },

	{"sta", staAsm, 1 },
	{"stp", stpAsm, 0 },
	{"stx", stxAsm, 1 },
	{"sty", styAsm, 1 },
	{"stz", stzAsm, 1 },

	{"tax", taxAsm, 0 },
	{"tay", tayAsm, 0 },
	{"trb", trbAsm, 1 },
	{"tsb", tsbAsm, 1 },
	{"tsx", tsxAsm, 0 },
	{"txa", txaAsm, 0 },
	{"txs", txsAsm, 0 },
	{"tya", tyaAsm, 0 },

	{"xce", xceAsm, 0 },
};

	Operands6502 operW65C02;

	Cpu optabW65C02 =
	{
		"W65C02", 16, 1, 38, sizeof(opsW65C02)/sizeof(Mne), opsW65C02, (Operands *)&operW65C02
	};
}
