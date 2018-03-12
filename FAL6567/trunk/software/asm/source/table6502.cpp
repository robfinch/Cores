#include <stdio.h>
#include <stdlib.h>
#include "operands6502.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "am.h"
#include "am6502.h"
#include "asm6502.h"
#include "Assembler.h"
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
		{Asm6502::imm, 0x69, 1, AM_IMM},
		{Asm6502::zp, 0x65, 1, AM_Z},
		{Asm6502::zp, 0x75, 1, AM_ZX},
		{Asm6502::abs, 0x79, 1, AM_ZY},	// force abs,y
		{Asm6502::zp, 0x61, 1, AM_IX},
		{Asm6502::zp, 0x71, 1, AM_IY},
		{Asm6502::abs, 0x6D, 1, AM_A},
		{Asm6502::abs, 0x7D, 1, AM_AX},
		{Asm6502::abs, 0x79, 1, AM_AY},
		NULL
	};

	static Opa andAsm[] =
	{
		{Asm6502::imm, 0x29, 1, AM_IMM},
		{Asm6502::zp, 0x25, 1, AM_Z},
		{Asm6502::zp, 0x35, 1, AM_ZX},
		{Asm6502::abs, 0x39, 1, AM_ZY},	// force abs,y
		{Asm6502::zp, 0x21, 1, AM_IX},
		{Asm6502::zp, 0x31, 1, AM_IY},
		{Asm6502::abs, 0x2D, 1, AM_A},
		{Asm6502::abs, 0x3D, 1, AM_AX},
		{Asm6502::abs, 0x39, 1, AM_AY},
		NULL
	};

static Opa aslAsm[] =
{
    {Asm6502::out8, 0x0a, 0, AM_},
    {Asm6502::out8, 0x0a, 1, AM_ACC},
	{Asm6502::zp, 0x06, 1, AM_Z},
	{Asm6502::zp, 0x16, 1, AM_ZX},
	{Asm6502::abs, 0x0E, 1, AM_A},
	{Asm6502::abs, 0x1E, 1, AM_AX},
	NULL
};

static Opa rolAsm[] =
{
    {Asm6502::out8, 0x2a, 0, AM_},
    {Asm6502::out8, 0x2a, 1, AM_ACC},
	{Asm6502::zp, 0x26, 1, AM_Z},
	{Asm6502::zp, 0x36, 1, AM_ZX},
	{Asm6502::abs, 0x2E, 1, AM_A},
	{Asm6502::abs, 0x3E, 1, AM_AX},
	NULL
};

static Opa rorAsm[] =
{
    {Asm6502::out8, 0x6a, 0, AM_},
    {Asm6502::out8, 0x6a, 1, AM_ACC},
	{Asm6502::zp, 0x66, 1, AM_Z},
	{Asm6502::zp, 0x76, 1, AM_ZX},
	{Asm6502::abs, 0x6E, 1, AM_A},
	{Asm6502::abs, 0x7E, 1, AM_AX},
	NULL
};

static Opa lsrAsm[] =
{
    {Asm6502::out8, 0x4a, 0, AM_},
    {Asm6502::out8, 0x4a, 1, AM_ACC},
	{Asm6502::zp, 0x46, 1, AM_Z},
	{Asm6502::zp, 0x56, 1, AM_ZX},
	{Asm6502::abs, 0x4E, 1, AM_A},
	{Asm6502::abs, 0x5E, 1, AM_AX},
	NULL
};

static Opa bccAsm[] = {	{Asm6502::br, 0x90, 1}, NULL };
static Opa bcsAsm[] = {	{Asm6502::br, 0xB0, 1}, NULL };
static Opa beqAsm[] = {	{Asm6502::br, 0xF0, 1}, NULL };
static Opa bmiAsm[] = {	{Asm6502::br, 0x30, 1}, NULL };
static Opa bneAsm[] = {	{Asm6502::br, 0xD0, 1}, NULL };
static Opa bplAsm[] = {	{Asm6502::br, 0x10, 1}, NULL };
static Opa bvcAsm[] = {	{Asm6502::br, 0x50, 1}, NULL };
static Opa bvsAsm[] = {	{Asm6502::br, 0x70, 1}, NULL };
static Opa brkAsm[] = {	{Asm6502::out8, 0x00, 0}, NULL };

static Opa bitAsm[] =
{
    {Asm6502::zp, 0x24, 1, AM_Z},
    {Asm6502::abs, 0x2C, 1, AM_A},
    NULL
};

static Opa clcAsm[] = { {Asm6502::out8, 0x18}, NULL };
static Opa cldAsm[] = { {Asm6502::out8, 0xD8}, NULL };
static Opa cliAsm[] = { {Asm6502::out8, 0x58}, NULL };
static Opa clvAsm[] = { {Asm6502::out8, 0xB8}, NULL };
static Opa dexAsm[] = { {Asm6502::out8, 0xCA}, NULL };
static Opa deyAsm[] = { {Asm6502::out8, 0x88}, NULL };
static Opa inxAsm[] = { {Asm6502::out8, 0xE8}, NULL };
static Opa inyAsm[] = { {Asm6502::out8, 0xC8}, NULL };

static Opa secAsm[] = { {Asm6502::out8, 0x38}, NULL };
static Opa sedAsm[] = { {Asm6502::out8, 0xF8}, NULL };
static Opa seiAsm[] = { {Asm6502::out8, 0x78}, NULL };

static Opa phaAsm[] = { {Asm6502::out8, 0x48}, NULL };
static Opa phpAsm[] = { {Asm6502::out8, 0x08}, NULL };
static Opa plaAsm[] = { {Asm6502::out8, 0x68}, NULL };
static Opa plpAsm[] = { {Asm6502::out8, 0x28}, NULL };

static Opa rtiAsm[] = { {Asm6502::out8, 0x40}, NULL };
static Opa rtsAsm[] = { {Asm6502::out8, 0x60}, NULL };

static Opa taxAsm[] = { {Asm6502::out8, 0xAA}, NULL };
static Opa tayAsm[] = { {Asm6502::out8, 0xA8}, NULL };
static Opa tsxAsm[] = { {Asm6502::out8, 0xBA}, NULL };
static Opa txaAsm[] = { {Asm6502::out8, 0x8A}, NULL };
static Opa txsAsm[] = { {Asm6502::out8, 0x9A}, NULL };
static Opa tyaAsm[] = { {Asm6502::out8, 0x98}, NULL };

static Opa nopAsm[] = { {Asm6502::out8, 0xEA}, NULL };

static Opa cmpAsm[] =
{
	{Asm6502::imm, 0xC9, 1, AM_IMM},
    {Asm6502::zp, 0xC5, 1, AM_Z},
    {Asm6502::zp, 0xD5, 1, AM_ZX},
	{Asm6502::abs, 0xD9, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0xC1, 1, AM_IX},
    {Asm6502::zp, 0xD1, 1, AM_IY},
	{Asm6502::abs, 0xCD, 1, AM_A},
	{Asm6502::abs, 0xDD, 1, AM_AX},
	{Asm6502::abs, 0xD9, 1, AM_AY},
	NULL
};

static Opa cpxAsm[] =
{
	{Asm6502::imm, 0xE0, 1, AM_IMM},
    {Asm6502::zp, 0xE4, 1, AM_Z},
	{Asm6502::abs, 0xEC, 1, AM_A},
	NULL
};

static Opa cpyAsm[] =
{
	{Asm6502::imm, 0xC0, 1, AM_IMM},
    {Asm6502::zp, 0xC4, 1, AM_Z},
	{Asm6502::abs, 0xCC, 1, AM_A},
	NULL
};

static Opa decAsm[] =
{
    {Asm6502::zp, 0xC6, 1, AM_Z},
    {Asm6502::zp, 0xD6, 1, AM_ZX},
	{Asm6502::abs, 0xCE, 1, AM_A},
	{Asm6502::abs, 0xDE, 1, AM_AX},
	NULL
};

static Opa incAsm[] =
{
    {Asm6502::zp, 0xE6, 1, AM_Z},
    {Asm6502::zp, 0xF6, 1, AM_ZX},
	{Asm6502::abs, 0xEE, 1, AM_A},
	{Asm6502::abs, 0xFE, 1, AM_AX},
	NULL
};

static Opa eorAsm[] =
{
	{Asm6502::imm, 0x49, 1, AM_IMM},
    {Asm6502::zp, 0x45, 1, AM_Z},
    {Asm6502::zp, 0x55, 1, AM_ZX},
	{Asm6502::abs, 0x59, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0x41, 1, AM_IX},
    {Asm6502::zp, 0x51, 1, AM_IY},
	{Asm6502::abs, 0x4D, 1, AM_A},
	{Asm6502::abs, 0x5D, 1, AM_AX},
	{Asm6502::abs, 0x59, 1, AM_AY},
	NULL
};

static Opa sbcAsm[] =
{
	{Asm6502::imm, 0xE9, 1, AM_IMM},
    {Asm6502::zp, 0xE5, 1, AM_Z},
    {Asm6502::zp, 0xF5, 1, AM_ZX},
	{Asm6502::abs, 0xF9, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0xE1, 1, AM_IX},
    {Asm6502::zp, 0xF1, 1, AM_IY},
	{Asm6502::abs, 0xED, 1, AM_A},
	{Asm6502::abs, 0xFD, 1, AM_AX},
	{Asm6502::abs, 0xF9, 1, AM_AY},
	NULL
};

static Opa oraAsm[] =
{
	{Asm6502::imm, 0x09, 1, AM_IMM},
    {Asm6502::zp, 0x05, 1, AM_Z},
    {Asm6502::zp, 0x15, 1, AM_ZX},
	{Asm6502::abs, 0x19, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0x01, 1, AM_IX},
    {Asm6502::zp, 0x11, 1, AM_IY},
	{Asm6502::abs, 0x0D, 1, AM_A},
	{Asm6502::abs, 0x1D, 1, AM_AX},
	{Asm6502::abs, 0x19, 1, AM_AY},
	NULL
};

static Opa staAsm[] =
{
    {Asm6502::zp, 0x85, 1, AM_Z},
    {Asm6502::zp, 0x95, 1, AM_ZX},
	{Asm6502::abs, 0x99, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0x81, 1, AM_IX},
    {Asm6502::zp, 0x91, 1, AM_IY},
	{Asm6502::abs, 0x8D, 1, AM_A},
	{Asm6502::abs, 0x9D, 1, AM_AX},
	{Asm6502::abs, 0x99, 1, AM_AY},
	NULL
};

static Opa stxAsm[] =
{
    {Asm6502::zp, 0x86, 1, AM_Z},
    {Asm6502::zp, 0x96, 1, AM_ZY},
	{Asm6502::abs, 0x8E, 1, AM_A},
	NULL
};

static Opa styAsm[] =
{
    {Asm6502::zp, 0x84, 1, AM_Z},
    {Asm6502::zp, 0x94, 1, AM_ZX},
	{Asm6502::abs, 0x8C, 1, AM_A},
	NULL
};


static Opa ldaAsm[] =
{
	{Asm6502::imm, 0xA9, 1, AM_IMM},
    {Asm6502::zp, 0xA5, 1, AM_Z},
    {Asm6502::zp, 0xB5, 1, AM_ZX},
	{Asm6502::abs, 0xB9, 1, AM_ZY},	// force abs,y
    {Asm6502::zp, 0xA1, 1, AM_IX},
    {Asm6502::zp, 0xB1, 1, AM_IY},
	{Asm6502::abs, 0xAD, 1, AM_A},
	{Asm6502::abs, 0xBD, 1, AM_AX},
	{Asm6502::abs, 0xB9, 1, AM_AY},
	NULL
};

static Opa ldxAsm[] =
{
	{Asm6502::imm, 0xA2, 1, AM_IMM},
    {Asm6502::zp, 0xA6, 1, AM_Z},
    {Asm6502::zp, 0xB6, 1, AM_ZY},
	{Asm6502::abs, 0xAE, 1, AM_A},
	{Asm6502::abs, 0xBE, 1, AM_AY},
	NULL
};

static Opa ldyAsm[] =
{
	{Asm6502::imm, 0xA0, 1, AM_IMM},
    {Asm6502::zp, 0xA4, 1, AM_Z},
    {Asm6502::zp, 0xB4, 1, AM_ZX},
	{Asm6502::abs, 0xAC, 1, AM_A},
	{Asm6502::abs, 0xBC, 1, AM_AX},
	NULL
};

	static Opa jmpAsm[] =
	{
		{Asm6502::abs, 0x4c, 1, AM_A},
		{Asm6502::abs, 0x4c, 1, AM_Z},
		{Asm6502::abs, 0x6c, 1, AM_I},
		{Asm6502::abs, 0x6c, 1, AM_ZI},	// force abs
		NULL
	};

	static Opa jsrAsm[] =
	{
		{Asm6502::abs, 0x20, 1, AM_A},
		{Asm6502::abs, 0x20, 1, AM_Z},
		NULL
	};


	// Opcode / Pseudo op table. MUST BE IN ALPHABETICAL ORDER.

	static Mne ops6502[] =
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
		
		{"dec", decAsm, 1 },
		{"dex", dexAsm, 1 },
		{"dey", deyAsm, 1 },
		
		{"eor", eorAsm, 1 },

		{"inc", incAsm, 1 },

		{"inx", inxAsm, 0 },
		{"iny", inyAsm, 0 },
		
		{"jmp", jmpAsm, 1 },
		{"jsr", jsrAsm, 1 },

		{"lda", ldaAsm, 1 },
		{"ldx", ldxAsm, 1 },
		{"ldy", ldyAsm, 1 },

		{"lsr", lsrAsm, 1 },

		{"nop", nopAsm, 0 },

		{"ora", oraAsm, 1 },
		
		{"pha", phaAsm, 0 },
		{"php", phpAsm, 0 },
		{"pla", plaAsm, 0 },
		{"plp", plpAsm, 0 },
		
		{"rol", rolAsm, 1 },
		{"ror", rorAsm, 1 },

		{"rti", rtiAsm, 0 },
		{"rts", rtsAsm, 0 },

		{"sbc", sbcAsm, 1 },

		{"sec", secAsm, 0 },
		{"sed", sedAsm, 0 },
		{"sei", seiAsm, 0 },

		{"sta", staAsm, 1 },
		{"stx", stxAsm, 1 },
		{"sty", styAsm, 1 },

		{"tax", taxAsm, 0 },
		{"tay", tayAsm, 0 },
		{"tsx", tsxAsm, 0 },
		{"txa", txaAsm, 0 },
		{"txs", txsAsm, 0 },
		{"tya", tyaAsm, 0 },
	};


	Operands6502 oper6502;

	Cpu optab6502 =
	{
		"6502",	16, 1, 38, sizeof(ops6502)/sizeof(Mne), ops6502, (Operands *)&oper6502
	};
}
