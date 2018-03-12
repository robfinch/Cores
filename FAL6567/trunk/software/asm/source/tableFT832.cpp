#include <stdio.h>
#include <stdlib.h>
#include "operands6502.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "am.h"
#include "am6502.h"
#include "asmFT832.h"
#include "Assembler.h"
#include "Asm6502.h"
#include "PseudoOp.h"

#define MAX_OPERANDS 60
/*
extern "C" {
int AsmFT832::imm(Opa*);
};
*/
namespace RTFClasses
{
	static Opa memAsm[] = { {AsmFT832::amem, 0, 1}, NULL };
	static Opa ndxAsm[] = { {AsmFT832::andx, 0, 1}, NULL };

static Opa adcAsm[] =
{
	{AsmFT832::immm, 0x69, 1, AM_IMM, 2},
	{AsmFT832::zp, 0x65, 1, AM_Z, 4},
	{AsmFT832::zp, 0x75, 1, AM_ZX, 4},
	{AsmFT832::abs, 0x79, 1, AM_ZY, 4},	// force abs,y
	{AsmFT832::zp, 0x61, 1, AM_IX, 4},
	{AsmFT832::zp, 0x71, 1, AM_IY},
	{AsmFT832::zp, 0x72, 1, AM_ZI},
	{AsmFT832::abs, 0x6D, 1, AM_A},
	{AsmFT832::abs, 0x7D, 1, AM_AX},
	{AsmFT832::abs, 0x79, 1, AM_AY},
	{AsmFT832::labs, 0x6F, 1, AM_AL},
	{AsmFT832::labs, 0x7F, 1, AM_AXL},
	{AsmFT832::xlabs, 0x426D, 1, AM_XAL},
	{AsmFT832::xlabs, 0x427D, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x4279, 1, AM_XAYL},
	{AsmFT832::sr, 0x63, 1, AM_SR},
	{AsmFT832::sr, 0x73, 1, AM_SRIY},
	{AsmFT832::sr, 0x4273, 1, AM_XSRIY},
	{AsmFT832::zp, 0x67, 1, AM_ZIL},
	{AsmFT832::zp, 0x4267, 1, AM_XIL},
    {AsmFT832::zp, 0x77, 1, AM_IYL},
    {AsmFT832::zp, 0x4277, 1, AM_XIYL},
	NULL
};

static Opa andAsm[] =
{
	{AsmFT832::immm, 0x29, 1, AM_IMM},
    {AsmFT832::zp, 0x25, 1, AM_Z},
    {AsmFT832::zp, 0x35, 1, AM_ZX},
	{AsmFT832::abs, 0x39, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0x21, 1, AM_IX},
    {AsmFT832::zp, 0x31, 1, AM_IY},
	{AsmFT832::zp, 0x32, 1, AM_ZI},
	{AsmFT832::abs, 0x2D, 1, AM_A},
	{AsmFT832::abs, 0x3D, 1, AM_AX},
	{AsmFT832::abs, 0x39, 1, AM_AY},
	{AsmFT832::labs, 0x2F, 1, AM_AL},
	{AsmFT832::labs, 0x3F, 1, AM_AXL},
	{AsmFT832::xlabs, 0x422D, 1, AM_XAL},
	{AsmFT832::xlabs, 0x423D, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x4239, 1, AM_XAYL},
	{AsmFT832::sr, 0x23, 1, AM_SR},
	{AsmFT832::sr, 0x33, 1, AM_SRIY},
	{AsmFT832::sr, 0x4233, 1, AM_XSRIY},
	{AsmFT832::zp, 0x27, 1, AM_ZIL},
	{AsmFT832::zp, 0x4227, 1, AM_XIL},
    {AsmFT832::zp, 0x37, 1, AM_IYL},
    {AsmFT832::zp, 0x4237, 1, AM_XIYL},
	NULL
};

static Opa aslAsm[] =
{
    {Asm6502::out8, 0x0a, 0, AM_},
    {Asm6502::out8, 0x0a, 1, AM_ACC},
	{AsmFT832::zp, 0x06, 1, AM_Z},
	{AsmFT832::zp, 0x16, 1, AM_ZX},
	{AsmFT832::abs, 0x0E, 1, AM_A},
	{AsmFT832::abs, 0x1E, 1, AM_AX},
	{AsmFT832::xlabs, 0x420E, 1, AM_AL},
	{AsmFT832::xlabs, 0x421E, 1, AM_AXL},
	{AsmFT832::xlabs, 0x420E, 1, AM_XAL},
	{AsmFT832::xlabs, 0x421E, 1, AM_XAXL},
	NULL
};

static Opa rolAsm[] =
{
    {Asm6502::out8, 0x2a, 0, AM_},
    {Asm6502::out8, 0x2a, 1, AM_ACC},
	{AsmFT832::zp, 0x26, 1, AM_Z},
	{AsmFT832::zp, 0x36, 1, AM_ZX},
	{AsmFT832::abs, 0x2E, 1, AM_A},
	{AsmFT832::abs, 0x3E, 1, AM_AX},
	{AsmFT832::xlabs, 0x422E, 1, AM_AL},
	{AsmFT832::xlabs, 0x423E, 1, AM_AXL},
	{AsmFT832::xlabs, 0x422E, 1, AM_XAL},
	{AsmFT832::xlabs, 0x423E, 1, AM_XAXL},
	NULL
};

static Opa rorAsm[] =
{
    {Asm6502::out8, 0x6a, 0, AM_},
    {Asm6502::out8, 0x6a, 1, AM_ACC},
	{AsmFT832::zp, 0x66, 1, AM_Z},
	{AsmFT832::zp, 0x76, 1, AM_ZX},
	{AsmFT832::abs, 0x6E, 1, AM_A},
	{AsmFT832::abs, 0x7E, 1, AM_AX},
	{AsmFT832::xlabs, 0x426E, 1, AM_AL},
	{AsmFT832::xlabs, 0x427E, 1, AM_AXL},
	{AsmFT832::xlabs, 0x426E, 1, AM_XAL},
	{AsmFT832::xlabs, 0x427E, 1, AM_XAXL},
	NULL
};

static Opa lsrAsm[] =
{
    {Asm6502::out8, 0x4a, 0, AM_},
    {Asm6502::out8, 0x4a, 1, AM_ACC},
	{AsmFT832::zp, 0x46, 1, AM_Z},
	{AsmFT832::zp, 0x56, 1, AM_ZX},
	{AsmFT832::abs, 0x4E, 1, AM_A},
	{AsmFT832::abs, 0x5E, 1, AM_AX},
	{AsmFT832::xlabs, 0x424E, 1, AM_AL},
	{AsmFT832::xlabs, 0x425E, 1, AM_AXL},
	{AsmFT832::xlabs, 0x424E, 1, AM_XAL},
	{AsmFT832::xlabs, 0x425E, 1, AM_XAXL},
	NULL
};

static Opa bccAsm[] = {	{AsmFT832::br, 0x90, 1}, NULL };
static Opa bcsAsm[] = {	{AsmFT832::br, 0xB0, 1}, NULL };
static Opa beqAsm[] = {	{AsmFT832::br, 0xF0, 1}, NULL };
static Opa bmiAsm[] = {	{AsmFT832::br, 0x30, 1}, NULL };
static Opa bneAsm[] = {	{AsmFT832::br, 0xD0, 1}, NULL };
static Opa bplAsm[] = {	{AsmFT832::br, 0x10, 1}, NULL };
static Opa bvcAsm[] = {	{AsmFT832::br, 0x50, 1}, NULL };
static Opa bvsAsm[] = {	{AsmFT832::br, 0x70, 1}, NULL };
static Opa braAsm[] = {	{AsmFT832::br, 0x80, 1}, NULL };
static Opa brlAsm[] = {	{AsmFT832::brl, 0x82, 1}, NULL };
static Opa bsrAsm[] = {	{AsmFT832::brl, 0x4228, 1}, NULL };
static Opa bslAsm[] = {	{AsmFT832::bsl, 0x4248, 1}, NULL };
static Opa brkAsm[] = {	{Asm6502::out8, 0x00, 0}, NULL };
static Opa bltAsm[] = {	{AsmFT832::br, 0x4230, 1}, NULL };
static Opa bleAsm[] = {	{AsmFT832::br, 0x42B0, 1}, NULL };
static Opa bgtAsm[] = {	{AsmFT832::br, 0x4210, 1}, NULL };
static Opa bgeAsm[] = {	{AsmFT832::br, 0x4290, 1}, NULL };

static Opa lbccAsm[] = {	{AsmFT832::lbr, 0x90, 1}, NULL };
static Opa lbcsAsm[] = {	{AsmFT832::lbr, 0xB0, 1}, NULL };
static Opa lbeqAsm[] = {	{AsmFT832::lbr, 0xF0, 1}, NULL };
static Opa lbmiAsm[] = {	{AsmFT832::lbr, 0x30, 1}, NULL };
static Opa lbneAsm[] = {	{AsmFT832::lbr, 0xD0, 1}, NULL };
static Opa lbplAsm[] = {	{AsmFT832::lbr, 0x10, 1}, NULL };
static Opa lbvcAsm[] = {	{AsmFT832::lbr, 0x50, 1}, NULL };
static Opa lbvsAsm[] = {	{AsmFT832::lbr, 0x70, 1}, NULL };
static Opa lbraAsm[] = {	{AsmFT832::lbr, 0x80, 1}, NULL };
static Opa lbltAsm[] = {	{AsmFT832::lbr, 0x4230, 1}, NULL };
static Opa lbleAsm[] = {	{AsmFT832::lbr, 0x42B0, 1}, NULL };
static Opa lbgtAsm[] = {	{AsmFT832::lbr, 0x4210, 1}, NULL };
static Opa lbgeAsm[] = {	{AsmFT832::lbr, 0x4290, 1}, NULL };

static Opa bitAsm[] =
{
	{AsmFT832::immm, 0x89, 1, AM_IMM},
    {AsmFT832::zp, 0x24, 1, AM_Z},
    {AsmFT832::zp, 0x34, 1, AM_ZX},
    {AsmFT832::abs, 0x2C, 1, AM_A},
    {AsmFT832::abs, 0x3C, 1, AM_AX},
    {AsmFT832::xlabs, 0x422C, 1, AM_AL},
    {AsmFT832::xlabs, 0x423C, 1, AM_AXL},
    {AsmFT832::xlabs, 0x422C, 1, AM_XAL},
    {AsmFT832::xlabs, 0x423C, 1, AM_XAXL},
    NULL
};

static Opa repAsm[] =
{
	{AsmFT832::epimm, 0xC2, 1, AM_IMM, 2},
    NULL
};

static Opa peiAsm[] =
{
	{AsmFT832::imm, 0xD4, 1, AM_IMM},
    NULL
};

static Opa perAsm[] =
{
	{AsmFT832::per, 0x62, 1, AM_A},
	{AsmFT832::per, 0x62, 1, AM_Z},
    NULL
};

static Opa peaAsm[] =
{
	{AsmFT832::pea, 0x42F4, 1, AM_XAL},
	{AsmFT832::pea, 0x42F4, 1, AM_AL},
	{AsmFT832::pea, 0xF4, 1, AM_A},
	{AsmFT832::pea, 0xF4, 1, AM_Z},
    NULL
};

static Opa sepAsm[] =
{
	{AsmFT832::epimm, 0xE2, 1, AM_IMM, 2},
    NULL
};

	static Opa copAsm[] =
	{
		{AsmFT832::imm, 0x02, 1, AM_IMM},
		NULL
	};

	static Opa tsbAsm[] =
	{
		{AsmFT832::zp, 0x04, 1, AM_Z},
		{AsmFT832::abs, 0x0C, 1, AM_A},
		{AsmFT832::xlabs, 0x420C, 1, AM_AL},
		{AsmFT832::xlabs, 0x420C, 1, AM_XAL},
		NULL
	};

	static Opa trbAsm[] =
	{
		{AsmFT832::zp, 0x14, 1, AM_Z},
		{AsmFT832::abs, 0x1C, 1, AM_A},
		{AsmFT832::xlabs, 0x421C, 1, AM_AL},
		{AsmFT832::xlabs, 0x421C, 1, AM_XAL},
		NULL
	};

	static Opa bmtAsm[] =
	{
		{AsmFT832::xlabs, 0x4214, 1, AM_Z},
		{AsmFT832::xlabs, 0x4214, 1, AM_A},
		{AsmFT832::xlabs, 0x4214, 1, AM_AL},
		{AsmFT832::xlabs, 0x4214, 1, AM_XAL},
		NULL
	};

	static Opa bmsAsm[] =
	{
		{AsmFT832::xlabs, 0x4224, 1, AM_Z},
		{AsmFT832::xlabs, 0x4224, 1, AM_A},
		{AsmFT832::xlabs, 0x4224, 1, AM_AL},
		{AsmFT832::xlabs, 0x4224, 1, AM_XAL},
		NULL
	};

	static Opa bmcAsm[] =
	{
		{AsmFT832::xlabs, 0x4234, 1, AM_Z},
		{AsmFT832::xlabs, 0x4234, 1, AM_A},
		{AsmFT832::xlabs, 0x4234, 1, AM_AL},
		{AsmFT832::xlabs, 0x4234, 1, AM_XAL},
		NULL
	};


static Opa clcAsm[] = { {Asm6502::out8, 0x18,0,0,2}, NULL };
static Opa cldAsm[] = { {Asm6502::out8, 0xD8,0,0,2}, NULL };
static Opa cliAsm[] = { {Asm6502::out8, 0x58,0,0,2}, NULL };
static Opa clvAsm[] = { {Asm6502::out8, 0xB8,0,0,2}, NULL };
static Opa cmcAsm[] = { {Asm6502::out16, 0x1842}, NULL };
static Opa dexAsm[] = { {Asm6502::out8, 0xCA,0,0,2}, NULL };
static Opa deyAsm[] = { {Asm6502::out8, 0x88,0,0,2}, NULL };
static Opa inxAsm[] = { {Asm6502::out8, 0xE8,0,0,2}, NULL };
static Opa inyAsm[] = { {Asm6502::out8, 0xC8,0,0,2}, NULL };

static Opa secAsm[] = { {Asm6502::out8, 0x38,0,0,2}, NULL };
static Opa sedAsm[] = { {Asm6502::out8, 0xF8,0,0,2}, NULL };
static Opa seiAsm[] = { {Asm6502::out8, 0x78,0,0,2},
                        {AsmFT832::imm, 0x4278, 1, AM_IMM,2},
                         NULL };

static Opa phaAsm[] = { {Asm6502::out8, 0x48,0,0,4}, NULL };
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
static Opa phcsAsm[] = { {Asm6502::out16, 0x4B42}, NULL };
static Opa phdsAsm[] = { {Asm6502::out16, 0x0B42}, NULL };
static Opa pldsAsm[] = { {Asm6502::out16, 0x2B42}, NULL };

static Opa ritAsm[] = { {Asm6502::out16, 0x5042},NULL };
static Opa rtiAsm[] = { {Asm6502::out8, 0x40}, NULL };
static Opa rticAsm[] = { {Asm6502::out16, 0x5042},NULL };
static Opa rtsAsm[] = { {Asm6502::out8, 0x60},
                        {AsmFT832::imm, 0x42C0, 1, AM_IMM},
                          NULL };
static Opa rtlAsm[] = { {Asm6502::out8, 0x6B},
                        {AsmFT832::imm, 0x4268, 1, AM_IMM},
                          NULL };
static Opa rtfAsm[] = { {AsmFT832::imm, 0x426B, 1, AM_IMM},
                         NULL };
static Opa rttAsm[] = { {Asm6502::out16, 0x6042},NULL };
static Opa rtcAsm[] = { {AsmFT832::rtc, 0x4240, 1, AM_IMM, 4},
                        {AsmFT832::rtc, 0x4240, 1, AM_IMM4, 4},
                        {AsmFT832::rtc, 0x4240, 1, AM_IMM8, 4},
                        NULL };

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
static Opa wdmAsm[] = { {Asm6502::out8, 0x42}, NULL };
static Opa stpAsm[] = { {Asm6502::out8, 0xDB}, NULL };
static Opa xbaAsm[] = { {Asm6502::out8, 0xEB}, NULL };
static Opa xceAsm[] = { {Asm6502::out8, 0xFB}, NULL };
static Opa ttaAsm[] = { {Asm6502::out16, 0x1A42}, NULL };
static Opa xbawAsm[] = { {Asm6502::out16, 0xEB42}, NULL };
static Opa infAsm[] = { {Asm6502::out16, 0x4A42}, NULL };
static Opa dex4Asm[] = { {Asm6502::out16, 0xCA42}, NULL };
static Opa dey4Asm[] = { {Asm6502::out16, 0x8842}, NULL };
static Opa inx4Asm[] = { {Asm6502::out16, 0xE842}, NULL };
static Opa iny4Asm[] = { {Asm6502::out16, 0xC842}, NULL };
static Opa mulAsm[] = { {Asm6502::out16, 0x2A42}, NULL };
static Opa aaxAsm[] = { {Asm6502::out16, 0x8A42}, NULL };
static Opa jciAsm[] = { {Asm6502::out16, 0x8042}, NULL };
static Opa sduAsm[] = { {Asm6502::out16, 0xBA42}, NULL };
static Opa tassAsm[] = { {Asm6502::out16, 0x5A42}, NULL };
static Opa tssaAsm[] = { {Asm6502::out16, 0x7A42}, NULL };





static Opa nopAsm[] = { {Asm6502::out8, 0xEA}, NULL };

static Opa cmpAsm[] =
{
	{AsmFT832::immm, 0xC9, 1, AM_IMM},
    {AsmFT832::zp, 0xC5, 1, AM_Z},
    {AsmFT832::zp, 0xD5, 1, AM_ZX},
	{AsmFT832::abs, 0xD9, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0xC1, 1, AM_IX},
    {AsmFT832::zp, 0xD1, 1, AM_IY},
	{AsmFT832::zp, 0xD2, 1, AM_ZI},
	{AsmFT832::abs, 0xCD, 1, AM_A},
	{AsmFT832::abs, 0xDD, 1, AM_AX},
	{AsmFT832::abs, 0xD9, 1, AM_AY},
	{AsmFT832::labs, 0xCF, 1, AM_AL},
	{AsmFT832::labs, 0xDF, 1, AM_AXL},
	{AsmFT832::xlabs, 0x42CD, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42DD, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x42D9, 1, AM_XAYL},
	{AsmFT832::sr, 0xC3, 1, AM_SR},
	{AsmFT832::sr, 0xD3, 1, AM_SRIY},
	{AsmFT832::sr, 0x42D3, 1, AM_XSRIY},
	{AsmFT832::zp, 0xC7, 1, AM_ZIL},
	{AsmFT832::zp, 0x42C7, 1, AM_XIL},
    {AsmFT832::zp, 0xD7, 1, AM_IYL},
    {AsmFT832::zp, 0x42D7, 1, AM_XIYL},
	NULL
};

static Opa cpxAsm[] =
{
	{AsmFT832::immx, 0xE0, 1, AM_IMM},
    {AsmFT832::zp, 0xE4, 1, AM_Z},
	{AsmFT832::abs, 0xEC, 1, AM_A},
	{AsmFT832::xlabs, 0x42EC, 1, AM_AL},
	{AsmFT832::xlabs, 0x42EC, 1, AM_XAL},
	NULL
};

static Opa cpyAsm[] =
{
	{AsmFT832::immx, 0xC0, 1, AM_IMM},
    {AsmFT832::zp, 0xC4, 1, AM_Z},
	{AsmFT832::abs, 0xCC, 1, AM_A},
	{AsmFT832::xlabs, 0x42CC, 1, AM_AL},
	{AsmFT832::xlabs, 0x42CC, 1, AM_XAL},
	NULL
};

static Opa decAsm[] =
{
    {Asm6502::out8, 0x3a, 1, AM_ACC},
    {AsmFT832::zp, 0xC6, 1, AM_Z},
    {AsmFT832::zp, 0xD6, 1, AM_ZX},
	{AsmFT832::abs, 0xCE, 1, AM_A},
	{AsmFT832::abs, 0xDE, 1, AM_AX},
	{AsmFT832::xlabs, 0x42CE, 1, AM_AL},
	{AsmFT832::xlabs, 0x42DE, 1, AM_AXL},
	{AsmFT832::xlabs, 0x42CE, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42DE, 1, AM_XAXL},
	NULL
};

static Opa incAsm[] =
{
    {Asm6502::out8, 0x1a, 1, AM_ACC},
    {AsmFT832::zp, 0xE6, 1, AM_Z},
    {AsmFT832::zp, 0xF6, 1, AM_ZX},
	{AsmFT832::abs, 0xEE, 1, AM_A},
	{AsmFT832::abs, 0xFE, 1, AM_AX},
	{AsmFT832::xlabs, 0x42EE, 1, AM_AL},
	{AsmFT832::xlabs, 0x42FE, 1, AM_AXL},
	{AsmFT832::xlabs, 0x42EE, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42FE, 1, AM_XAXL},
	NULL
};

static Opa deaAsm[] = {{Asm6502::out8, 0x3a}, NULL };
static Opa inaAsm[] = {{Asm6502::out8, 0x1a}, NULL };

static Opa eorAsm[] =
{
	{AsmFT832::immm, 0x49, 1, AM_IMM},
    {AsmFT832::zp, 0x45, 1, AM_Z},
    {AsmFT832::zp, 0x55, 1, AM_ZX},
	{AsmFT832::abs, 0x59, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0x41, 1, AM_IX},
    {AsmFT832::zp, 0x51, 1, AM_IY},
	{AsmFT832::zp, 0x52, 1, AM_ZI},
	{AsmFT832::abs, 0x4D, 1, AM_A},
	{AsmFT832::abs, 0x5D, 1, AM_AX},
	{AsmFT832::abs, 0x59, 1, AM_AY},
	{AsmFT832::labs, 0x4F, 1, AM_AL},
	{AsmFT832::labs, 0x5F, 1, AM_AXL},
	{AsmFT832::xlabs, 0x424D, 1, AM_XAL},
	{AsmFT832::xlabs, 0x425D, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x4259, 1, AM_XAYL},
	{AsmFT832::sr, 0x43, 1, AM_SR},
	{AsmFT832::sr, 0x53, 1, AM_SRIY},
	{AsmFT832::sr, 0x4253, 1, AM_XSRIY},
	{AsmFT832::zp, 0x47, 1, AM_ZIL},
	{AsmFT832::zp, 0x4247, 1, AM_XIL},
    {AsmFT832::zp, 0x57, 1, AM_IYL},
    {AsmFT832::zp, 0x4257, 1, AM_XIYL},
	NULL
};

static Opa sbcAsm[] =
{
	{AsmFT832::immm, 0xE9, 1, AM_IMM},
    {AsmFT832::zp, 0xE5, 1, AM_Z},
    {AsmFT832::zp, 0xF5, 1, AM_ZX},
	{AsmFT832::abs, 0xF9, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0xE1, 1, AM_IX},
    {AsmFT832::zp, 0xF1, 1, AM_IY},
	{AsmFT832::zp, 0xF2, 1, AM_ZI},
	{AsmFT832::abs, 0xED, 1, AM_A},
	{AsmFT832::abs, 0xFD, 1, AM_AX},
	{AsmFT832::abs, 0xF9, 1, AM_AY},
	{AsmFT832::labs, 0xEF, 1, AM_AL},
	{AsmFT832::labs, 0xFF, 1, AM_AXL},
	{AsmFT832::xlabs, 0x42ED, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42FD, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x42F9, 1, AM_XAYL},
	{AsmFT832::sr, 0xE3, 1, AM_SR},
	{AsmFT832::sr, 0xF3, 1, AM_SRIY},
	{AsmFT832::sr, 0x42F3, 1, AM_XSRIY},
	{AsmFT832::zp, 0xE7, 1, AM_ZIL},
	{AsmFT832::zp, 0x42E7, 1, AM_XIL},
    {AsmFT832::zp, 0xF7, 1, AM_IYL},
    {AsmFT832::zp, 0x42F7, 1, AM_XIYL},
	NULL
};

static Opa oraAsm[] =
{
	{AsmFT832::immm, 0x09, 1, AM_IMM},
    {AsmFT832::zp, 0x05, 1, AM_Z},
    {AsmFT832::zp, 0x15, 1, AM_ZX},
	{AsmFT832::abs, 0x19, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0x01, 1, AM_IX},
    {AsmFT832::zp, 0x11, 1, AM_IY},
	{AsmFT832::zp, 0x12, 1, AM_ZI},
	{AsmFT832::abs, 0x0D, 1, AM_A},
	{AsmFT832::abs, 0x1D, 1, AM_AX},
	{AsmFT832::abs, 0x19, 1, AM_AY},
	{AsmFT832::labs, 0x0F, 1, AM_AL},
	{AsmFT832::labs, 0x1F, 1, AM_AXL},
	{AsmFT832::xlabs, 0x420D, 1, AM_XAL},
	{AsmFT832::xlabs, 0x421D, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x4219, 1, AM_XAYL},
	{AsmFT832::sr, 0x03, 1, AM_SR},
	{AsmFT832::sr, 0x13, 1, AM_SRIY},
	{AsmFT832::sr, 0x4213, 1, AM_XSRIY},
	{AsmFT832::zp, 0x07, 1, AM_ZIL},
	{AsmFT832::zp, 0x4207, 1, AM_XIL},
    {AsmFT832::zp, 0x17, 1, AM_IYL},
    {AsmFT832::zp, 0x4217, 1, AM_XIYL},
	NULL
};

static Opa staAsm[] =
{
    {AsmFT832::zp, 0x85, 1, AM_Z},
    {AsmFT832::zp, 0x95, 1, AM_ZX},
	{AsmFT832::abs, 0x99, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0x81, 1, AM_IX},
    {AsmFT832::zp, 0x91, 1, AM_IY},
	{AsmFT832::zp, 0x92, 1, AM_ZI},
	{AsmFT832::abs, 0x8D, 1, AM_A},
	{AsmFT832::abs, 0x9D, 1, AM_AX},
	{AsmFT832::abs, 0x99, 1, AM_AY},
	{AsmFT832::labs, 0x8F, 1, AM_AL},
	{AsmFT832::labs, 0x9F, 1, AM_AXL},
	{AsmFT832::xlabs, 0x428D, 1, AM_XAL},
	{AsmFT832::xlabs, 0x429D, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x4299, 1, AM_XAYL},
	{AsmFT832::sr, 0x83, 1, AM_SR},
	{AsmFT832::sr, 0x93, 1, AM_SRIY},
	{AsmFT832::sr, 0x4293, 1, AM_XSRIY},
	{AsmFT832::zp, 0x87, 1, AM_ZIL},
	{AsmFT832::zp, 0x4287, 1, AM_XIL},
    {AsmFT832::zp, 0x97, 1, AM_IYL},
    {AsmFT832::zp, 0x4297, 1, AM_XIYL},
	NULL
};

static Opa stxAsm[] =
{
    {AsmFT832::zp, 0x86, 1, AM_Z},
    {AsmFT832::zp, 0x96, 1, AM_ZY},
	{AsmFT832::abs, 0x8E, 1, AM_A},
	{AsmFT832::xlabs, 0x428E, 1, AM_AL},
	{AsmFT832::xlabs, 0x428E, 1, AM_XAL},
	NULL
};

static Opa styAsm[] =
{
    {AsmFT832::zp, 0x84, 1, AM_Z},
    {AsmFT832::zp, 0x94, 1, AM_ZX},
	{AsmFT832::abs, 0x8C, 1, AM_A},
	{AsmFT832::xlabs, 0x428C, 1, AM_AL},
	{AsmFT832::xlabs, 0x428C, 1, AM_XAL},
	NULL
};

static Opa stzAsm[] =
{
    {AsmFT832::zp, 0x64, 1, AM_Z},
    {AsmFT832::zp, 0x74, 1, AM_ZX},
	{AsmFT832::abs, 0x9C, 1, AM_A},
	{AsmFT832::abs, 0x9E, 1, AM_AX},
	{AsmFT832::xlabs, 0x429C, 1, AM_AL},
	{AsmFT832::xlabs, 0x429E, 1, AM_AXL},
	{AsmFT832::xlabs, 0x429C, 1, AM_XAL},
	{AsmFT832::xlabs, 0x429E, 1, AM_XAXL},
	NULL
};

static Opa ldaAsm[] =
{
	{AsmFT832::immm, 0xA9, 1, AM_IMM},
    {AsmFT832::zp, 0xA5, 1, AM_Z},
	{AsmFT832::abs, 0xB9, 1, AM_ZY},	// force abs,y
    {AsmFT832::zp, 0xB5, 1, AM_ZX},
    {AsmFT832::zp, 0xA1, 1, AM_IX},
    {AsmFT832::zp, 0xB1, 1, AM_IY},
	{AsmFT832::zp, 0xB2, 1, AM_ZI},
	{AsmFT832::abs, 0xAD, 1, AM_A},
	{AsmFT832::abs, 0xBD, 1, AM_AX},
	{AsmFT832::abs, 0xB9, 1, AM_AY},
	{AsmFT832::labs, 0xAF, 1, AM_AL},
	{AsmFT832::labs, 0xBF, 1, AM_AXL},
	{AsmFT832::xlabs, 0x42AD, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42BD, 1, AM_XAXL},
	{AsmFT832::xlabs, 0x42B9, 1, AM_XAYL},
	{AsmFT832::sr, 0xA3, 1, AM_SR},
	{AsmFT832::sr, 0xB3, 1, AM_SRIY},
	{AsmFT832::sr, 0x42B3, 1, AM_XSRIY},
	{AsmFT832::zp, 0xA7, 1, AM_ZIL},
	{AsmFT832::zp, 0x42A7, 1, AM_XIL},
    {AsmFT832::zp, 0xB7, 1, AM_IYL},
    {AsmFT832::zp, 0x42B7, 1, AM_XIYL},
	NULL
};

static Opa ldxAsm[] =
{
	{AsmFT832::immx, 0xA2, 1, AM_IMM},
    {AsmFT832::zp, 0xA6, 1, AM_Z},
    {AsmFT832::zp, 0xB6, 1, AM_ZY},
	{AsmFT832::abs, 0xAE, 1, AM_A},
	{AsmFT832::abs, 0xBE, 1, AM_AY},
	{AsmFT832::xlabs, 0x42AE, 1, AM_AL},
	{AsmFT832::xlabs, 0x42AE, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42BE, 1, AM_XAYL},
	NULL
};

static Opa ldyAsm[] =
{
	{AsmFT832::immx, 0xA0, 1, AM_IMM},
    {AsmFT832::zp, 0xA4, 1, AM_Z},
    {AsmFT832::zp, 0xB4, 1, AM_ZX},
	{AsmFT832::abs, 0xAC, 1, AM_A},
	{AsmFT832::abs, 0xBC, 1, AM_AX},
	{AsmFT832::xlabs, 0x42AC, 1, AM_AL},
	{AsmFT832::xlabs, 0x42AC, 1, AM_XAL},
	{AsmFT832::xlabs, 0x42BC, 1, AM_XAXL},
	NULL
};

static Opa jmpAsm[] =
{
	{AsmFT832::abs, 0x4c, 1, AM_A},
	{AsmFT832::abs, 0x4c, 1, AM_Z},	// Force abs
	{AsmFT832::abs, 0x6c, 1, AM_I},
	{AsmFT832::abs, 0x7c, 1, AM_IX},
	{AsmFT832::abs, 0x6c, 1, AM_ZI},	// force abs
	{AsmFT832::abs, 0xDC, 1, AM_ZIL},	// force abs
	{AsmFT832::abs, 0xDC, 1, AM_IL},	// force abs
	{AsmFT832::jsegoffs, 0x424c, 1, AM_SEG},
	NULL
};

	static Opa jsrAsm[] =
	{
		{AsmFT832::abs, 0x20, 1, AM_A} ,
		{AsmFT832::abs, 0x20, 1, AM_Z},	// force abs
		{AsmFT832::abs, 0xFC, 1, AM_IX},
		{AsmFT832::abs, 0x22, 1, AM_AL} ,
  	{AsmFT832::jcr, 0x4220, 2, (AM_Z<<8)|AM_Z, 4},
	  {AsmFT832::jcr, 0x4220, 2, (AM_A<<8)|AM_Z, 4},
   	{AsmFT832::jsegoffs, 0x4220, 1, AM_SEG},
		NULL
	};

	static Opa jslAsm[] =
	{
		{AsmFT832::labs, 0x22, 1, AM_A} ,
		{AsmFT832::labs, 0x22, 1, AM_Z},	// force abs
		{AsmFT832::labs, 0x22, 1, AM_AL} ,
		NULL
	};

  static Opa jmlAsm[] =
	{
		{AsmFT832::labs, 0x5C, 1, AM_A} ,
		{AsmFT832::labs, 0x5C, 1, AM_Z},	// force abs
		{AsmFT832::labs, 0x5C, 1, AM_AL} ,
		NULL
	};

    static Opa jmfAsm[] =
    {
    	{AsmFT832::jsegoffs, 0x425C, 1, AM_A},
    	{AsmFT832::jsegoffs, 0x425C, 1, AM_Z},
    	{AsmFT832::jsegoffs, 0x425C, 1, AM_AL},
		NULL
    };

    static Opa jsfAsm[] =
    {
    	{AsmFT832::jsegoffs, 0x4222, 1, AM_A},
    	{AsmFT832::jsegoffs, 0x4222, 1, AM_Z},
    	{AsmFT832::jsegoffs, 0x4222, 1, AM_AL},
		NULL
    };

	static Opa mvnAsm[] =
	{
		{AsmFT832::mv, 0x54, 1, (AM_Z<<8)|AM_Z},
		NULL
	};

	static Opa mvpAsm[] =
	{
		{AsmFT832::mv, 0x44, 1, (AM_Z<<8)|AM_Z},
		NULL
	};

	static Opa fillAsm[] =
	{
		{AsmFT832::fill, 0x4244, 1, AM_Z, 6},
		NULL
	};

static Opa cacheAsm[] =
{
	{AsmFT832::imm, 0x42E0, 1, AM_IMM},
    NULL
};

static Opa tskAsm[] =
{
	{AsmFT832::imm16, 0x42A2, 1, AM_IMM},
    {Asm6502::out16, 0x3A42, 0, AM_},
    {Asm6502::out16, 0x3A42, 1, AM_ACC},
    NULL
};

static Opa forkAsm[] =
{
	{AsmFT832::imm16, 0x42A0, 1, AM_IMM},
    {Asm6502::out16, 0xAA42, 0, AM_},
    {Asm6502::out16, 0xAA42, 1, AM_ACC},
    NULL
};

static Opa ldtAsm[] =
{
	{AsmFT832::xlabs, 0x426C, 1, AM_Z, 44},
	{AsmFT832::xlabs, 0x424C, 1, AM_ZX, 44},
	{AsmFT832::xlabs, 0x426C, 1, AM_A, 44},
	{AsmFT832::xlabs, 0x424C, 1, AM_AX, 44},
	{AsmFT832::xlabs, 0x426C, 1, AM_AL, 44},
	{AsmFT832::xlabs, 0x424C, 1, AM_AXL, 44},
	{AsmFT832::xlabs, 0x426C, 1, AM_XAL, 44},
	{AsmFT832::xlabs, 0x424C, 1, AM_XAXL, 44},
    NULL
};

static Opa jcrAsm[] =
{
	{AsmFT832::jcr, 0x4220, 2, (AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcr, 0x4220, 2, (AM_A<<8)|AM_Z, 4},
    NULL
};

static Opa jclAsm[] =
{
	{AsmFT832::jcl, 0x4282, 4, (AM_Z<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcl, 0x4282, 4, (AM_A<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcl, 0x4282, 4, (AM_AL<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcl, 0x4282, 4, (AM_AL<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcl, 0x4282, 4, (AM_Z<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcl, 0x4282, 4, (AM_A<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
    NULL
};

static Opa jcfAsm[] =
{
	{AsmFT832::jcf, 0x4262, 4, (AM_Z<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_A<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_AL<<24)|(AM_Z<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_Z<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_A<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_AL<<24)|(AM_A<<16)|(AM_Z<<8)|AM_Z, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_Z<<24)|(AM_A<<16)|(AM_Z<<8)|AM_IMM, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_A<<24)|(AM_A<<16)|(AM_Z<<8)|AM_IMM, 4},
	{AsmFT832::jcf, 0x4262, 4, (AM_AL<<24)|(AM_A<<16)|(AM_Z<<8)|AM_IMM, 4},
    NULL
};

static Mne opsFT832[] =
{
	{"aax", aaxAsm, 0 },
	{"adc", adcAsm, 1 },
	{"and", andAsm, 1 },
	{"asl", aslAsm, 1 },

	{"bcc", bccAsm, 1 },
	{"bcs", bcsAsm, 1 },
	{"beq", beqAsm, 1 },
	{"bge", bplAsm, 1 },
	{"bgeu", bccAsm, 1 },
	{"bgt", bgtAsm, 1 },
	{"bit", bitAsm, 1 },
	{"ble", bleAsm, 1 },
	{"blt", bmiAsm, 1 },
	{"bltu", bcsAsm, 1 },
	{"bmc", bmcAsm, 1 },
	{"bmi", bmiAsm, 1 },
	{"bms", bmsAsm, 1 },
	{"bmt", bmtAsm, 1 },
	{"bne", bneAsm, 1 },
	{"bpl", bplAsm, 1 },
	{"bra", braAsm, 1 },
	{"brk", brkAsm, 1 },
	{"brl", brlAsm, 1 },
	{"bsl", bslAsm, 1 },
	{"bsr", bsrAsm, 1 },
	{"bvc", bvcAsm, 1 },
	{"bvs", bvsAsm, 1 },

	{"cache", cacheAsm, 1 },
	{"clc", clcAsm, 0 },
	{"cld", cldAsm, 0 },
	{"cli", cliAsm, 0 },
	{"clv", clvAsm, 0 },
	{"cmc", cmcAsm, 0 },
	{"cmp", cmpAsm, 1 },

	{"cop", copAsm, 1 },
	
	{"cpx", cpxAsm, 1 },
	{"cpy", cpyAsm, 1 },
	
	{"dea", deaAsm, 0 },
	{"dec", decAsm, 1 },
	{"dex", dexAsm, 0 },
	{"dex4", dex4Asm, 0 },
	{"dey", deyAsm, 0 },
	{"dey4", dey4Asm, 0 },
	
	{"eor", eorAsm, 1 },
	{"fil", fillAsm, 1 },
	{"fork", forkAsm, 1 },

	{"ina", inaAsm, 0 },
	{"inc", incAsm, 1 },
	{"inf", infAsm, 0 },

	{"inx", inxAsm, 0 },
	{"inx4", inx4Asm, 0 },
	{"iny", inyAsm, 0 },
	{"iny4", iny4Asm, 0 },

	{"jcf", jcfAsm, 4 },
	{"jci", jciAsm, 0 },
	{"jcl", jclAsm, 4 },
	{"jcr", jcrAsm, 2 },
	{"jmf", jmfAsm, 1 },
	{"jml", jmlAsm, 1 },
	{"jmp", jmpAsm, 1 },
	{"jsf", jsfAsm, 1 },
	{"jsl", jslAsm, 1 },
	{"jsr", jsrAsm, 2 },

	{"lbcc", lbccAsm, 1 },
	{"lbcs", lbcsAsm, 1 },
	{"lbeq", lbeqAsm, 1 },
	{"lbge", lbgeAsm, 1 },
	{"lbgeu", lbccAsm, 1 },
	{"lbgt", lbgtAsm, 1 },
	{"lble", lbleAsm, 1 },
	{"lblt", lbltAsm, 1 },
	{"lbltu", lbcsAsm, 1 },
	{"lbmi", lbmiAsm, 1 },
	{"lbne", lbneAsm, 1 },
	{"lbpl", lbplAsm, 1 },
//	{"lbra", lbraAsm, 1 },
	{"lbvc", lbvcAsm, 1 },
	{"lbvs", lbvsAsm, 1 },

    {"lda", ldaAsm, 1 },
    {"ldt", ldtAsm, 1 },
    {"ldx", ldxAsm, 1 },
    {"ldy", ldyAsm, 1 },
	{"lsr", lsrAsm, 1 },

	{"mem", memAsm, 1},
	{"mul", mulAsm, 0},
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
	{"phcs", phcsAsm, 0 },
	{"phd", phdAsm, 0 },
	{"phds", phdsAsm, 0 },
	{"phk", phkAsm, 0 },
	{"php", phpAsm, 0 },
	{"phx", phxAsm, 0 },
	{"phy", phyAsm, 0 },
	{"pla", plaAsm, 0 },
	{"plb", plbAsm, 0 },
	{"pld", pldAsm, 0 },
	{"plds", pldsAsm, 0 },
	{"plp", plpAsm, 0 },
	{"plx", plxAsm, 0 },
	{"ply", plyAsm, 0 },
	
	{"rep", repAsm, 1 },
	{"rol", rolAsm, 1 },
	{"ror", rorAsm, 1 },

	{"rtc", rtcAsm, 1 },
	{"rtf", rtfAsm, 1 },
	{"rti", rtiAsm, 0 },
	{"rtic", rticAsm, 0 },
	{"rtl", rtlAsm, 1 },
	{"rts", rtsAsm, 1 },
	{"rtt", rttAsm, 0 },

	{"sbc", sbcAsm, 1 },

	{"sdu", sduAsm, 0 },
	{"sec", secAsm, 0 },
	{"sed", sedAsm, 0 },
	{"sei", seiAsm, 1 },
	{"sep", sepAsm, 1 },

	{"sta", staAsm, 1 },
	{"stp", stpAsm, 0 },
	{"stx", stxAsm, 1 },
	{"sty", styAsm, 1 },
	{"stz", stzAsm, 1 },

	{"tas", tcsAsm, 0 },
	{"tass", tassAsm, 0 },
	{"tax", taxAsm, 0 },
	{"tay", tayAsm, 0 },
	{"tcd", tcdAsm, 0 },
	{"tcs", tcsAsm, 0 },
	{"tdc", tdcAsm, 0 },
	{"trb", trbAsm, 1 },
	{"tsa", tscAsm, 0 },
	{"tsb", tsbAsm, 1 },
	{"tsc", tscAsm, 0 },
	{"tsk", tskAsm, 1 },
	{"tssa", tssaAsm, 0 },
	{"tsx", tsxAsm, 0 },
	{"tta", ttaAsm, 0 },
	{"txa", txaAsm, 0 },
	{"txs", txsAsm, 0 },
	{"txy", txyAsm, 0 },
	{"tya", tyaAsm, 0 },
	{"tyx", tyxAsm, 0 },

	{"wai", waiAsm, 0 },
	{"wdm", wdmAsm, 0 },

	{"xba", xbaAsm, 0 },
	{"xbaw", xbawAsm, 0 },
	{"xce", xceAsm, 0 },
};

	Operands6502 operFT832;

	Cpu optabFT832 =
	{
		"FT832", 24, 1, 41, sizeof(opsFT832)/sizeof(Mne), opsFT832, (Operands *)&operFT832
	};
}

