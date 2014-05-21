#include <stdio.h>
#include <stdlib.h>
#include "operands6502.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "am.h"
#include "am6502.h"
#include "asmRT65002.h"
#include "Assembler.h"
#include "Asm6502.h"
#include "PseudoOp.h"

#define MAX_OPERANDS 60
/*
extern "C" {
int AsmW65C816S::imm(Opa*);
};
*/
namespace RTFClasses
{
	static Opa memAsm[] = { {AsmW65C816S::amem, 0, 1}, NULL };
	static Opa ndxAsm[] = { {AsmW65C816S::andx, 0, 1}, NULL };

static Opa adcAsm[] =
{
	{AsmW65C816S::immm, 0x69, 1, AM_IMM},
	{AsmW65C816S::zp, 0x65, 1, AM_Z},
	{AsmW65C816S::zp, 0x75, 1, AM_ZX},
	{AsmW65C816S::abs, 0x79, 1, AM_ZY},	// force abs,y
	{AsmW65C816S::zp, 0x61, 1, AM_IX},
	{AsmW65C816S::zp, 0x71, 1, AM_IY},
	{AsmW65C816S::zp, 0x72, 1, AM_ZI},
	{AsmW65C816S::abs, 0x6D, 1, AM_A},
	{AsmW65C816S::abs, 0x7D, 1, AM_AX},
	{AsmW65C816S::abs, 0x79, 1, AM_AY},
	{AsmW65C816S::labs, 0x6F, 1, AM_AL},
	{AsmW65C816S::labs, 0x7F, 1, AM_AXL},
	{AsmW65C816S::sr, 0x63, 1, AM_SR},
	{AsmW65C816S::sr, 0x73, 1, AM_SRIY},
	{AsmW65C816S::zp, 0x67, 1, AM_ZIL},
    {AsmW65C816S::zp, 0x77, 1, AM_IYL},
	NULL
};

static Opa andAsm[] =
{
	{AsmW65C816S::immm, 0x29, 1, AM_IMM},
    {AsmW65C816S::zp, 0x25, 1, AM_Z},
    {AsmW65C816S::zp, 0x35, 1, AM_ZX},
	{AsmW65C816S::abs, 0x39, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0x21, 1, AM_IX},
    {AsmW65C816S::zp, 0x31, 1, AM_IY},
	{AsmW65C816S::zp, 0x32, 1, AM_ZI},
	{AsmW65C816S::abs, 0x2D, 1, AM_A},
	{AsmW65C816S::abs, 0x3D, 1, AM_AX},
	{AsmW65C816S::abs, 0x39, 1, AM_AY},
	{AsmW65C816S::labs, 0x2F, 1, AM_AL},
	{AsmW65C816S::labs, 0x3F, 1, AM_AXL},
	{AsmW65C816S::sr, 0x23, 1, AM_SR},
	{AsmW65C816S::sr, 0x33, 1, AM_SRIY},
	{AsmW65C816S::zp, 0x27, 1, AM_ZIL},
    {AsmW65C816S::zp, 0x37, 1, AM_IYL},
	NULL
};

static Opa aslAsm[] =
{
    {Asm6502::out8, 0x0a, 0, AM_},
    {Asm6502::out8, 0x0a, 1, AM_ACC},
	{AsmW65C816S::zp, 0x06, 1, AM_Z},
	{AsmW65C816S::zp, 0x16, 1, AM_ZX},
	{AsmW65C816S::abs, 0x0E, 1, AM_A},
	{AsmW65C816S::abs, 0x1E, 1, AM_AX},
	NULL
};

static Opa rolAsm[] =
{
    {Asm6502::out8, 0x2a, 0, AM_},
    {Asm6502::out8, 0x2a, 1, AM_ACC},
	{AsmW65C816S::zp, 0x26, 1, AM_Z},
	{AsmW65C816S::zp, 0x36, 1, AM_ZX},
	{AsmW65C816S::abs, 0x2E, 1, AM_A},
	{AsmW65C816S::abs, 0x3E, 1, AM_AX},
	NULL
};

static Opa rorAsm[] =
{
    {Asm6502::out8, 0x6a, 0, AM_},
    {Asm6502::out8, 0x6a, 1, AM_ACC},
	{AsmW65C816S::zp, 0x66, 1, AM_Z},
	{AsmW65C816S::zp, 0x76, 1, AM_ZX},
	{AsmW65C816S::abs, 0x6E, 1, AM_A},
	{AsmW65C816S::abs, 0x7E, 1, AM_AX},
	NULL
};

static Opa lsrAsm[] =
{
    {Asm6502::out8, 0x4a, 0, AM_},
    {Asm6502::out8, 0x4a, 1, AM_ACC},
	{AsmW65C816S::zp, 0x46, 1, AM_Z},
	{AsmW65C816S::zp, 0x56, 1, AM_ZX},
	{AsmW65C816S::abs, 0x4E, 1, AM_A},
	{AsmW65C816S::abs, 0x5E, 1, AM_AX},
	NULL
};

static Opa bccAsm[] = {	{AsmW65C816S::br, 0x90, 1}, NULL };
static Opa bcsAsm[] = {	{AsmW65C816S::br, 0xB0, 1}, NULL };
static Opa beqAsm[] = {	{AsmW65C816S::br, 0xF0, 1}, NULL };
static Opa bmiAsm[] = {	{AsmW65C816S::br, 0x30, 1}, NULL };
static Opa bneAsm[] = {	{AsmW65C816S::br, 0xD0, 1}, NULL };
static Opa bplAsm[] = {	{AsmW65C816S::br, 0x10, 1}, NULL };
static Opa bvcAsm[] = {	{AsmW65C816S::br, 0x50, 1}, NULL };
static Opa bvsAsm[] = {	{AsmW65C816S::br, 0x70, 1}, NULL };
static Opa braAsm[] = {	{AsmW65C816S::br, 0x80, 1}, NULL };
static Opa brlAsm[] = {	{AsmW65C816S::brl, 0x82, 1}, NULL };
static Opa brkAsm[] = {	{Asm6502::out8, 0x00, 0}, NULL };

static Opa bitAsm[] =
{
	{AsmW65C816S::immm, 0x89, 1, AM_IMM},
    {AsmW65C816S::zp, 0x24, 1, AM_Z},
    {AsmW65C816S::zp, 0x34, 1, AM_ZX},
    {AsmW65C816S::abs, 0x2C, 1, AM_A},
    {AsmW65C816S::abs, 0x3C, 1, AM_AX},
    NULL
};

static Opa repAsm[] =
{
	{AsmW65C816S::imm, 0xC2, 1, AM_IMM},
    NULL
};

static Opa peiAsm[] =
{
	{AsmW65C816S::imm, 0xD4, 1, AM_IMM},
    NULL
};

static Opa perAsm[] =
{
	{AsmW65C816S::per, 0x62, 1, AM_A},
	{AsmW65C816S::per, 0x62, 1, AM_Z},
    NULL
};

static Opa peaAsm[] =
{
	{AsmW65C816S::pea, 0xF4, 1, AM_A},
	{AsmW65C816S::pea, 0xF4, 1, AM_Z},
    NULL
};

static Opa sepAsm[] =
{
	{AsmW65C816S::imm, 0xE2, 1, AM_IMM},
    NULL
};

	static Opa copAsm[] =
	{
		{AsmW65C816S::imm, 0x02, 1, AM_IMM},
		NULL
	};

	static Opa tsbAsm[] =
	{
		{AsmW65C816S::zp, 0x04, 1, AM_Z},
		{AsmW65C816S::abs, 0x0C, 1, AM_A},
		NULL
	};

	static Opa trbAsm[] =
	{
		{AsmW65C816S::zp, 0x14, 1, AM_Z},
		{AsmW65C816S::abs, 0x1C, 1, AM_A},
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
static Opa phbAsm[] = { {Asm6502::out8, 0x8B}, NULL };
static Opa phdAsm[] = { {Asm6502::out8, 0x0B}, NULL };
static Opa phkAsm[] = { {Asm6502::out8, 0x4B}, NULL };
static Opa phxAsm[] = { {Asm6502::out8, 0xDA}, NULL };
static Opa phyAsm[] = { {Asm6502::out8, 0x5A}, NULL };
static Opa phpAsm[] = { {Asm6502::out8, 0x08}, NULL };
static Opa plaAsm[] = { {Asm6502::out8, 0x68}, NULL };
static Opa plbAsm[] = { {Asm6502::out8, 0xAB}, NULL };
static Opa pldAsm[] = { {Asm6502::out8, 0x2B}, NULL };
static Opa plxAsm[] = { {Asm6502::out8, 0xFA}, NULL };
static Opa plyAsm[] = { {Asm6502::out8, 0x7A}, NULL };
static Opa plpAsm[] = { {Asm6502::out8, 0x28}, NULL };

static Opa rtiAsm[] = { {Asm6502::out8, 0x40}, NULL };
static Opa rtsAsm[] = { {Asm6502::out8, 0x60}, NULL };
static Opa rtlAsm[] = { {Asm6502::out8, 0x6B}, NULL };

static Opa taxAsm[] = { {Asm6502::out8, 0xAA}, NULL };
static Opa tayAsm[] = { {Asm6502::out8, 0xA8}, NULL };
static Opa tsxAsm[] = { {Asm6502::out8, 0xBA}, NULL };
static Opa txaAsm[] = { {Asm6502::out8, 0x8A}, NULL };
static Opa txsAsm[] = { {Asm6502::out8, 0x9A}, NULL };
static Opa txyAsm[] = { {Asm6502::out8, 0x9B}, NULL };
static Opa tyxAsm[] = { {Asm6502::out8, 0xBB}, NULL };
static Opa tyaAsm[] = { {Asm6502::out8, 0x98}, NULL };
static Opa tcdAsm[] = { {Asm6502::out8, 0x5B}, NULL };
static Opa tdcAsm[] = { {Asm6502::out8, 0x7B}, NULL };
static Opa tcsAsm[] = { {Asm6502::out8, 0x1B}, NULL };
static Opa tscAsm[] = { {Asm6502::out8, 0x3B}, NULL };
static Opa waiAsm[] = { {Asm6502::out8, 0xCB}, NULL };
static Opa stpAsm[] = { {Asm6502::out8, 0xDB}, NULL };
static Opa xbaAsm[] = { {Asm6502::out8, 0xEB}, NULL };
static Opa xceAsm[] = { {Asm6502::out8, 0xFB}, NULL };





static Opa nopAsm[] = { {Asm6502::out8, 0xEA}, NULL };

static Opa cmpAsm[] =
{
	{AsmW65C816S::immm, 0xC9, 1, AM_IMM},
    {AsmW65C816S::zp, 0xC5, 1, AM_Z},
    {AsmW65C816S::zp, 0xD5, 1, AM_ZX},
	{AsmW65C816S::abs, 0xD9, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0xC1, 1, AM_IX},
    {AsmW65C816S::zp, 0xD1, 1, AM_IY},
	{AsmW65C816S::zp, 0xD2, 1, AM_ZI},
	{AsmW65C816S::abs, 0xCD, 1, AM_A},
	{AsmW65C816S::abs, 0xDD, 1, AM_AX},
	{AsmW65C816S::abs, 0xD9, 1, AM_AY},
	{AsmW65C816S::labs, 0xCF, 1, AM_AL},
	{AsmW65C816S::labs, 0xDF, 1, AM_AXL},
	{AsmW65C816S::sr, 0xC3, 1, AM_SR},
	{AsmW65C816S::sr, 0xD3, 1, AM_SRIY},
	{AsmW65C816S::zp, 0xC7, 1, AM_ZIL},
    {AsmW65C816S::zp, 0xD7, 1, AM_IYL},
	NULL
};

static Opa cpxAsm[] =
{
	{AsmW65C816S::immx, 0xE0, 1, AM_IMM},
    {AsmW65C816S::zp, 0xE4, 1, AM_Z},
	{AsmW65C816S::abs, 0xEC, 1, AM_A},
	NULL
};

static Opa cpyAsm[] =
{
	{AsmW65C816S::immx, 0xC0, 1, AM_IMM},
    {AsmW65C816S::zp, 0xC4, 1, AM_Z},
	{AsmW65C816S::abs, 0xCC, 1, AM_A},
	NULL
};

static Opa decAsm[] =
{
    {Asm6502::out8, 0x3a, 1, AM_ACC},
    {AsmW65C816S::zp, 0xC6, 1, AM_Z},
    {AsmW65C816S::zp, 0xD6, 1, AM_ZX},
	{AsmW65C816S::abs, 0xCE, 1, AM_A},
	{AsmW65C816S::abs, 0xDE, 1, AM_AX},
	NULL
};

static Opa incAsm[] =
{
    {Asm6502::out8, 0x1a, 1, AM_ACC},
    {AsmW65C816S::zp, 0xE6, 1, AM_Z},
    {AsmW65C816S::zp, 0xF6, 1, AM_ZX},
	{AsmW65C816S::abs, 0xEE, 1, AM_A},
	{AsmW65C816S::abs, 0xFE, 1, AM_AX},
	NULL
};

static Opa deaAsm[] = {{Asm6502::out8, 0x3a}, NULL };
static Opa inaAsm[] = {{Asm6502::out8, 0x1a}, NULL };

static Opa eorAsm[] =
{
	{AsmW65C816S::immm, 0x49, 1, AM_IMM},
    {AsmW65C816S::zp, 0x45, 1, AM_Z},
    {AsmW65C816S::zp, 0x55, 1, AM_ZX},
	{AsmW65C816S::abs, 0x59, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0x41, 1, AM_IX},
    {AsmW65C816S::zp, 0x51, 1, AM_IY},
	{AsmW65C816S::zp, 0x52, 1, AM_ZI},
	{AsmW65C816S::abs, 0x4D, 1, AM_A},
	{AsmW65C816S::abs, 0x5D, 1, AM_AX},
	{AsmW65C816S::abs, 0x59, 1, AM_AY},
	{AsmW65C816S::labs, 0x4F, 1, AM_AL},
	{AsmW65C816S::labs, 0x5F, 1, AM_AXL},
	{AsmW65C816S::sr, 0x43, 1, AM_SR},
	{AsmW65C816S::sr, 0x53, 1, AM_SRIY},
	{AsmW65C816S::zp, 0x47, 1, AM_ZIL},
    {AsmW65C816S::zp, 0x57, 1, AM_IYL},
	NULL
};

static Opa sbcAsm[] =
{
	{AsmW65C816S::immm, 0xE9, 1, AM_IMM},
    {AsmW65C816S::zp, 0xE5, 1, AM_Z},
    {AsmW65C816S::zp, 0xF5, 1, AM_ZX},
	{AsmW65C816S::abs, 0xF9, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0xE1, 1, AM_IX},
    {AsmW65C816S::zp, 0xF1, 1, AM_IY},
	{AsmW65C816S::zp, 0xF2, 1, AM_ZI},
	{AsmW65C816S::abs, 0xED, 1, AM_A},
	{AsmW65C816S::abs, 0xFD, 1, AM_AX},
	{AsmW65C816S::abs, 0xF9, 1, AM_AY},
	{AsmW65C816S::labs, 0xEF, 1, AM_AL},
	{AsmW65C816S::labs, 0xFF, 1, AM_AXL},
	{AsmW65C816S::sr, 0xE3, 1, AM_SR},
	{AsmW65C816S::sr, 0xF3, 1, AM_SRIY},
	{AsmW65C816S::zp, 0xE7, 1, AM_ZIL},
    {AsmW65C816S::zp, 0xF7, 1, AM_IYL},
	NULL
};

static Opa oraAsm[] =
{
	{AsmW65C816S::immm, 0x09, 1, AM_IMM},
    {AsmW65C816S::zp, 0x05, 1, AM_Z},
    {AsmW65C816S::zp, 0x15, 1, AM_ZX},
	{AsmW65C816S::abs, 0x19, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0x01, 1, AM_IX},
    {AsmW65C816S::zp, 0x11, 1, AM_IY},
	{AsmW65C816S::zp, 0x12, 1, AM_ZI},
	{AsmW65C816S::abs, 0x0D, 1, AM_A},
	{AsmW65C816S::abs, 0x1D, 1, AM_AX},
	{AsmW65C816S::abs, 0x19, 1, AM_AY},
	{AsmW65C816S::labs, 0x0F, 1, AM_AL},
	{AsmW65C816S::labs, 0x1F, 1, AM_AXL},
	{AsmW65C816S::sr, 0x03, 1, AM_SR},
	{AsmW65C816S::sr, 0x13, 1, AM_SRIY},
	{AsmW65C816S::zp, 0x07, 1, AM_ZIL},
    {AsmW65C816S::zp, 0x17, 1, AM_IYL},
	NULL
};

static Opa staAsm[] =
{
    {AsmW65C816S::zp, 0x85, 1, AM_Z},
    {AsmW65C816S::zp, 0x95, 1, AM_ZX},
	{AsmW65C816S::abs, 0x99, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0x81, 1, AM_IX},
    {AsmW65C816S::zp, 0x91, 1, AM_IY},
	{AsmW65C816S::zp, 0x92, 1, AM_ZI},
	{AsmW65C816S::abs, 0x8D, 1, AM_A},
	{AsmW65C816S::abs, 0x9D, 1, AM_AX},
	{AsmW65C816S::abs, 0x99, 1, AM_AY},
	{AsmW65C816S::labs, 0x8F, 1, AM_AL},
	{AsmW65C816S::labs, 0x9F, 1, AM_AXL},
	{AsmW65C816S::sr, 0x83, 1, AM_SR},
	{AsmW65C816S::sr, 0x93, 1, AM_SRIY},
	{AsmW65C816S::zp, 0x87, 1, AM_ZIL},
    {AsmW65C816S::zp, 0x97, 1, AM_IYL},
	NULL
};

static Opa stxAsm[] =
{
    {AsmW65C816S::zp, 0x86, 1, AM_Z},
    {AsmW65C816S::zp, 0x96, 1, AM_ZY},
	{AsmW65C816S::abs, 0x8E, 1, AM_A},
	NULL
};

static Opa styAsm[] =
{
    {AsmW65C816S::zp, 0x84, 1, AM_Z},
    {AsmW65C816S::zp, 0x94, 1, AM_ZX},
	{AsmW65C816S::abs, 0x8C, 1, AM_A},
	NULL
};

static Opa stzAsm[] =
{
    {AsmW65C816S::zp, 0x64, 1, AM_Z},
    {AsmW65C816S::zp, 0x74, 1, AM_ZX},
	{AsmW65C816S::abs, 0x9C, 1, AM_A},
	{AsmW65C816S::abs, 0x9E, 1, AM_AX},
	NULL
};

static Opa ldaAsm[] =
{
	{AsmW65C816S::immm, 0xA9, 1, AM_IMM},
    {AsmW65C816S::zp, 0xA5, 1, AM_Z},
	{AsmW65C816S::abs, 0xB9, 1, AM_ZY},	// force abs,y
    {AsmW65C816S::zp, 0xB5, 1, AM_ZX},
    {AsmW65C816S::zp, 0xA1, 1, AM_IX},
    {AsmW65C816S::zp, 0xB1, 1, AM_IY},
	{AsmW65C816S::zp, 0xB2, 1, AM_ZI},
	{AsmW65C816S::abs, 0xAD, 1, AM_A},
	{AsmW65C816S::abs, 0xBD, 1, AM_AX},
	{AsmW65C816S::abs, 0xB9, 1, AM_AY},
	{AsmW65C816S::labs, 0xAF, 1, AM_AL},
	{AsmW65C816S::labs, 0xBF, 1, AM_AXL},
	{AsmW65C816S::sr, 0xA3, 1, AM_SR},
	{AsmW65C816S::sr, 0xB3, 1, AM_SRIY},
	{AsmW65C816S::zp, 0xA7, 1, AM_ZIL},
    {AsmW65C816S::zp, 0xB7, 1, AM_IYL},
	NULL
};

static Opa ldxAsm[] =
{
	{AsmW65C816S::immx, 0xA2, 1, AM_IMM},
    {AsmW65C816S::zp, 0xA6, 1, AM_Z},
    {AsmW65C816S::zp, 0xB6, 1, AM_ZY},
	{AsmW65C816S::abs, 0xAE, 1, AM_A},
	{AsmW65C816S::abs, 0xBE, 1, AM_AY},
	NULL
};

static Opa ldyAsm[] =
{
	{AsmW65C816S::immx, 0xA0, 1, AM_IMM},
    {AsmW65C816S::zp, 0xA4, 1, AM_Z},
    {AsmW65C816S::zp, 0xB4, 1, AM_ZX},
	{AsmW65C816S::abs, 0xAC, 1, AM_A},
	{AsmW65C816S::abs, 0xBC, 1, AM_AX},
	NULL
};

static Opa jmpAsm[] =
{
	{AsmW65C816S::abs, 0x4c, 1, AM_A},
	{AsmW65C816S::abs, 0x4c, 1, AM_Z},	// Force abs
	{AsmW65C816S::abs, 0x6c, 1, AM_I},
	{AsmW65C816S::abs, 0x7c, 1, AM_IX},
	{AsmW65C816S::abs, 0x6c, 1, AM_ZI},	// force abs
	{AsmW65C816S::abs, 0xDC, 1, AM_ZIL},	// force abs
	{AsmW65C816S::abs, 0xDC, 1, AM_IL},	// force abs
	NULL
};

	static Opa jsrAsm[] =
	{
		{AsmW65C816S::abs, 0x20, 1, AM_A} ,
		{AsmW65C816S::abs, 0x20, 1, AM_Z},	// force abs
		{AsmW65C816S::abs, 0xFC, 1, AM_IX},
		{AsmW65C816S::abs, 0x22, 1, AM_AL} ,
		NULL
	};

	static Opa jslAsm[] =
	{
		{AsmW65C816S::abs, 0x22, 1, AM_A} ,
		{AsmW65C816S::abs, 0x22, 1, AM_Z},	// force abs
		{AsmW65C816S::abs, 0x22, 1, AM_AL} ,
		NULL
	};

	static Opa mvnAsm[] =
	{
		{AsmW65C816S::mv, 0x54, 1, (AM_Z<<8)|AM_Z},
		NULL
	};

	static Opa mvpAsm[] =
	{
		{AsmW65C816S::mv, 0x44, 1, (AM_Z<<8)|AM_Z},
		NULL
	};


static Mne opsW65C816S[] =
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
	{"brl", brlAsm, 1 },
	{"bvc", bvcAsm, 1 },
	{"bvs", bvsAsm, 1 },

	{"clc", clcAsm, 0 },
	{"cld", cldAsm, 0 },
	{"cli", cliAsm, 0 },
	{"clv", clvAsm, 0 },
	{"cmp", cmpAsm, 1 },

	{"cop", copAsm, 1 },
	
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

	{"jmp", jmpAsm, 1 },
	{"jsr", jsrAsm, 1 },
	{"jsl", jslAsm, 1 },

    {"lda", ldaAsm, 1 },
    {"ldx", ldxAsm, 1 },
    {"ldy", ldyAsm, 1 },

	{"lsr", lsrAsm, 1 },

	{"mem", memAsm, 1},
	{"mvn", mvnAsm, 2},
	{"mvp", mvpAsm, 2},

	{"ndx", ndxAsm, 1 },
	{"nop", nopAsm, 0 },

	{"ora", oraAsm, 1 },

	{"pea", peaAsm, 1 },
	{"pei", peiAsm, 1 },
	{"per", perAsm, 1 },
	{"pha", phaAsm, 0 },
	{"phb", phbAsm, 0 },
	{"phd", phdAsm, 0 },
	{"phk", phkAsm, 0 },
	{"php", phpAsm, 0 },
	{"phx", phxAsm, 0 },
	{"phy", phyAsm, 0 },
	{"pla", plaAsm, 0 },
	{"plb", plbAsm, 0 },
	{"pld", pldAsm, 0 },
	{"plp", plpAsm, 0 },
	{"plx", plxAsm, 0 },
	{"ply", plyAsm, 0 },
	
	{"rep", repAsm, 1 },
	{"rol", rolAsm, 1 },
	{"ror", rorAsm, 1 },

	{"rtl", rtlAsm, 0 },
	{"rti", rtiAsm, 0 },
	{"rts", rtsAsm, 0 },

	{"sbc", sbcAsm, 1 },

	{"sec", secAsm, 0 },
	{"sed", sedAsm, 0 },
	{"sei", seiAsm, 0 },
	{"sep", sepAsm, 1 },

	{"sta", staAsm, 1 },
	{"stp", stpAsm, 0 },
	{"stx", stxAsm, 1 },
	{"sty", styAsm, 1 },
	{"stz", stzAsm, 1 },

	{"tas", tcsAsm, 0 },
	{"tax", taxAsm, 0 },
	{"tay", tayAsm, 0 },
	{"tcd", tcdAsm, 0 },
	{"tcs", tcsAsm, 0 },
	{"tdc", tdcAsm, 0 },
	{"trb", trbAsm, 1 },
	{"tsb", tsbAsm, 1 },
	{"tsa", tscAsm, 0 },
	{"tsc", tscAsm, 0 },
	{"tsx", tsxAsm, 0 },
	{"txa", txaAsm, 0 },
	{"txs", txsAsm, 0 },
	{"txy", txyAsm, 0 },
	{"tya", tyaAsm, 0 },
	{"tyx", tyxAsm, 0 },

	{"wai", waiAsm, 0 },

	{"xba", xbaAsm, 0 },
	{"xce", xceAsm, 0 },
};

	Operands6502 operW65C816S;

	Cpu optabW65C816S =
	{
		"W65C816S", 24, 1, 41, sizeof(opsW65C816S)/sizeof(Mne), opsW65C816S, (Operands *)&operW65C816S
	};
}

