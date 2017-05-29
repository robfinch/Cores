#include <stdio.h>
#include <stdlib.h>
#include "operands65002.h"
#include "cpu.h"
#include "mne.h"
#include "opa.h"
#include "am.h"
#include "am6502.h"
#include "asmRTF65002.h"
#include "Assembler.h"
#include "Asm6502.h"
#include "PseudoOp.h"

#define MAX_OPERANDS 60
/*
extern "C" {
int AsmRTF65002::imm(Opa*);
};
*/
namespace RTFClasses
{
static Opa addAsm[] =
{
	{AsmRTF65002::rn, 0x0002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::r,  0x77, 2,  (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm4, 0x67, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::imm32, 0x69, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32, 2},
	{AsmRTF65002::imm16, 0x79, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16, 2},
	{AsmRTF65002::imm8, 0x65, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8, 2},
	{AsmRTF65002::imm8, 0x65, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::zp, 0x75, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z, 5},
	{AsmRTF65002::zp, 0x75, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX, 5},
	{AsmRTF65002::zp, 0x75, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY, 5},
	{AsmRTF65002::zp, 0x61, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX, 6},
	{AsmRTF65002::zp, 0x71, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY, 7},
	{AsmRTF65002::rind, 0x72, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND, 5},
	{AsmRTF65002::abs, 0x6D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A, 5},
	{AsmRTF65002::absx, 0x7D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX, 5},
	{AsmRTF65002::absx, 0x7D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY, 5},
//	{AsmRTF65002::dsp, 0x63, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR},
	{AsmRTF65002::acc_rn, 0x0002, 1, AM_RN, 2},
	{AsmRTF65002::acc_imm32, 0x69, 1, AM_IMM32, 2},
	{AsmRTF65002::acc_imm16, 0x79, 1, AM_IMM16, 2},
	{AsmRTF65002::acc_imm8, 0x65, 1, AM_IMM8, 2},
	{AsmRTF65002::acc_imm8, 0x65, 1, AM_IMM4, 2},
	{AsmRTF65002::acc_zp, 0x75, 1, AM_ZX, 5},
	{AsmRTF65002::acc_zp, 0x75, 1, AM_Z, 5},
	{AsmRTF65002::acc_zp, 0x61, 1, AM_IX, 6},
	{AsmRTF65002::acc_zp, 0x71, 1, AM_IY, 7},
	{AsmRTF65002::acc_rind, 0x72, 1, AM_RIND, 5},
	{AsmRTF65002::acc_abs, 0x6D, 1, AM_A, 5},
	{AsmRTF65002::acc_absx, 0x7D, 1, AM_AX, 5},
	{AsmRTF65002::acc_absx, 0x7D, 1, AM_AY, 5},
	{AsmRTF65002::dsp, 0x63, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR, 5},
	{AsmRTF65002::acc_dsp, 0x63, 1, AM_SR, 5},
	NULL
};

static Opa andAsm[] =
{
	{AsmRTF65002::rn, 0x3002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::r,  0x37, 2,  (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm4, 0x27, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::imm32, 0x29, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,2},
	{AsmRTF65002::imm16, 0x39, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,2},
	{AsmRTF65002::imm8, 0x25, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8, 0x25, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::zp, 0x35, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::zp, 0x35, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX,5},
	{AsmRTF65002::zp, 0x35, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY,5},
	{AsmRTF65002::zp, 0x21, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX,6},
	{AsmRTF65002::zp, 0x31, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY,7},
	{AsmRTF65002::rind, 0x32, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND,5},
	{AsmRTF65002::abs, 0x2D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::absx, 0x3D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::absx, 0x3D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY,5},
	{AsmRTF65002::acc_rn, 0x3002, 1, AM_RN,2},
	{AsmRTF65002::acc_imm32, 0x29, 1, AM_IMM32,2},
	{AsmRTF65002::acc_imm16, 0x39, 1, AM_IMM16,2},
	{AsmRTF65002::acc_imm8, 0x25, 1, AM_IMM8,2},
	{AsmRTF65002::acc_imm8, 0x25, 1, AM_IMM4,2},
	{AsmRTF65002::acc_zp, 0x35, 1, AM_ZX,5},
	{AsmRTF65002::acc_zp, 0x35, 1, AM_Z,5},
	{AsmRTF65002::acc_zp, 0x21, 1, AM_IX,6},
	{AsmRTF65002::acc_zp, 0x31, 1, AM_IY,7},
	{AsmRTF65002::acc_rind, 0x32, 1, AM_RIND,5},
	{AsmRTF65002::acc_abs, 0x2D, 1, AM_A,5},
	{AsmRTF65002::acc_absx, 0x3D, 1, AM_AX,5},
	{AsmRTF65002::acc_absx, 0x3D, 1, AM_AY,5},
	{AsmRTF65002::dsp, 0x23, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR,5},
	{AsmRTF65002::acc_dsp, 0x23, 1, AM_SR,5},
	NULL
};

static Opa bitAsm[] =
{
	{AsmRTF65002::rnbit, 0x3002, 2, (AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::imm32bit, 0x29, 2, (AM_RN<<8)|AM_IMM32,2},
	{AsmRTF65002::imm16bit, 0x39, 2, (AM_RN<<8)|AM_IMM16,2},
	{AsmRTF65002::imm8bit, 0x25, 2, (AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8bit, 0x25, 2, (AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::zpbit, 0x35, 2, (AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::zpbit, 0x35, 2, (AM_RN<<8)|AM_ZX,5},
	{AsmRTF65002::zpbit, 0x35, 2, (AM_RN<<8)|AM_ZY,5},
	{AsmRTF65002::zpbit, 0x21, 2, (AM_RN<<8)|AM_IX,6},
	{AsmRTF65002::zpbit, 0x31, 2, (AM_RN<<8)|AM_IY,7},
	{AsmRTF65002::rindbit, 0x32, 2, (AM_RN<<8)|AM_RIND,5},
	{AsmRTF65002::absbit, 0x2D, 2, (AM_RN<<8)|AM_A,5},
	{AsmRTF65002::bit_absx, 0x3D, 2, (AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::bit_absx, 0x3D, 2, (AM_RN<<8)|AM_AY,5},
	{AsmRTF65002::bit_acc_imm8, 0x25, 1, AM_IMM4,2},
	{AsmRTF65002::bit_acc_imm8, 0x25, 1, AM_IMM8,2},
	{AsmRTF65002::bit_acc_imm16, 0x39, 1, AM_IMM16,2},
	{AsmRTF65002::bit_acc_imm32, 0x29, 1, AM_IMM32,2},
	{AsmRTF65002::bit_acc_zpx, 0x35, 1, AM_Z,5},
	{AsmRTF65002::bit_acc_zpx, 0x35, 1, AM_ZX,5},
	{AsmRTF65002::bit_acc_zpx, 0x35, 1, AM_ZY,5},
	{AsmRTF65002::bit_acc_abs, 0x2D, 1, AM_A,5},
	{AsmRTF65002::st_dsp, 0x23, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR,5},
	{AsmRTF65002::st_acc_dsp, 0x23, 1, AM_SR,5 },
	NULL
};

static Opa mulAsm[] = 
{
	{AsmRTF65002::rn, 0x8002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,5},
	{AsmRTF65002::mul_imm32, 0x0942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,5},
	{AsmRTF65002::mul_imm16, 0x1942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,5},
	{AsmRTF65002::mul_imm8, 0x0542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,5},
	{AsmRTF65002::mul_imm8, 0x0542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,5},
	NULL
};
static Opa mulsAsm[] = 
{
	{AsmRTF65002::rn, 0x9002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,5},
	{AsmRTF65002::mul_imm32, 0x2942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,5},
	{AsmRTF65002::mul_imm16, 0x3942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,5},
	{AsmRTF65002::mul_imm8, 0x2542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,5},
	{AsmRTF65002::mul_imm8, 0x2542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,5},
	NULL
};
static Opa divAsm[] = 
{
	{AsmRTF65002::rn, 0xA002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,36},
	{AsmRTF65002::mul_imm32, 0x4942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,36},
	{AsmRTF65002::mul_imm16, 0x5942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,36},
	{AsmRTF65002::mul_imm8, 0x4542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,36},
	{AsmRTF65002::mul_imm8, 0x4542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,36},
	NULL
};
static Opa divsAsm[] = 
{
	{AsmRTF65002::rn, 0xB002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,36},
	NULL
};
static Opa modAsm[] = 
{
	{AsmRTF65002::rn, 0xC002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,36},
	{AsmRTF65002::mul_imm32, 0x8942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,36},
	{AsmRTF65002::mul_imm16, 0x9942, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,36},
	{AsmRTF65002::mul_imm8, 0x8542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,36},
	{AsmRTF65002::mul_imm8, 0x8542, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,36},
	NULL
};
static Opa modsAsm[] = 
{
	{AsmRTF65002::rn, 0xD002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,36},
	NULL
};

static Opa aslAsm[] =
{
	{AsmRTF65002::imm8, 0x24, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8, 0x24, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::rn, 0xE002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,2},
    {Asm6502::out8, 0x0a, 0, AM_, 2},
    {Asm6502::out8, 0x0a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0x06, 1, AM_RN,2},
	{AsmRTF65002::rn2, 0x06, 2, (AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::zp2, 0x16, 1, AM_Z,5},
	{AsmRTF65002::zp2, 0x16, 1, AM_ZX,5},
	{AsmRTF65002::zp2, 0x16, 1, AM_ZY,5},
	{AsmRTF65002::abs2, 0x0E, 1, AM_A,5},
	{AsmRTF65002::absx2, 0x1E, 1, AM_AX,5},
	NULL
};

static Opa rolAsm[] =
{
    {Asm6502::out8, 0x2a, 0, AM_, 2},
    {Asm6502::out8, 0x2a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0x26, 1, AM_RN, 2},
	{AsmRTF65002::rn2, 0x26, 2, (AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::zp2, 0x36, 1, AM_Z,5},
	{AsmRTF65002::zp2, 0x36, 1, AM_ZX,5},
	{AsmRTF65002::zp2, 0x36, 1, AM_ZY,5},
	{AsmRTF65002::abs2, 0x2E, 1, AM_A,5},
	{AsmRTF65002::absx2, 0x3E, 1, AM_AX,5},
	NULL
};

static Opa rorAsm[] =
{
    {Asm6502::out8, 0x6a, 0, AM_, 2},
    {Asm6502::out8, 0x6a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0x66, 1, AM_RN, 2},
	{AsmRTF65002::rn2, 0x66, 2, (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::zp2, 0x76, 1, AM_Z, 5},
	{AsmRTF65002::zp2, 0x76, 1, AM_ZX, 5},
	{AsmRTF65002::zp2, 0x76, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0x6E, 1, AM_A, 5},
	{AsmRTF65002::absx2, 0x7E, 1, AM_AX, 5},
	NULL
};

static Opa lsrAsm[] =
{
	{AsmRTF65002::imm8, 0x34, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8, 0x34, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::rn, 0xF002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,2},
    {Asm6502::out8, 0x4a, 0, AM_, 2},
    {Asm6502::out8, 0x4a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0x46, 1, AM_RN, 2},
	{AsmRTF65002::rn2, 0x46, 2, (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::zp2, 0x56, 1, AM_Z, 5},
	{AsmRTF65002::zp2, 0x56, 1, AM_ZX, 5},
	{AsmRTF65002::zp2, 0x56, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0x4E, 1, AM_A, 5},
	{AsmRTF65002::absx2, 0x5E, 1, AM_AX, 5},
	NULL
};

static Opa bccAsm[] = {	{AsmRTF65002::br, 0x90, 1, NULL, 2}, NULL };
static Opa bcsAsm[] = {	{AsmRTF65002::br, 0xB0, 1, NULL, 2}, NULL };
static Opa beqAsm[] = {	{AsmRTF65002::br, 0xF0, 1, NULL, 2}, NULL};
static Opa bmiAsm[] = {	{AsmRTF65002::br, 0x30, 1, NULL, 2}, NULL };
static Opa bneAsm[] = {	{AsmRTF65002::br, 0xD0, 1, NULL, 2}, NULL };
static Opa bplAsm[] = {	{AsmRTF65002::br, 0x10, 1, NULL, 2}, NULL };
static Opa bvcAsm[] = {	{AsmRTF65002::br, 0x50, 1, NULL, 2}, NULL };
static Opa bvsAsm[] = {	{AsmRTF65002::br, 0x70, 1, NULL, 2}, NULL };
static Opa braAsm[] = {	{AsmRTF65002::br, 0x80, 1, NULL, 2}, NULL };
static Opa brlAsm[] = {	{AsmRTF65002::brl, 0x82, 1, NULL, 2}, NULL };
static Opa bsrAsm[] = {	{AsmRTF65002::brl, 0x62, 1, NULL, 4}, NULL };
static Opa bgeAsm[] = {	{AsmRTF65002::br, 0x93, 1, NULL, 2}, NULL };
static Opa bgtAsm[] = {	{AsmRTF65002::br, 0xD3, 1, NULL, 2}, NULL };
static Opa bltAsm[] = {	{AsmRTF65002::br, 0xB3, 1, NULL, 2}, NULL };
static Opa bleAsm[] = {	{AsmRTF65002::br, 0xF3, 1, NULL, 2}, NULL };
static Opa bhiAsm[] = {	{AsmRTF65002::br, 0x13, 1, NULL, 2}, NULL };
static Opa blsAsm[] = {	{AsmRTF65002::br, 0x33, 1, NULL, 2}, NULL };
static Opa brkAsm[] = {	{Asm6502::out8, 0x00, 0, NULL, 6}, NULL };
static Opa bhsAsm[] = {	{AsmRTF65002::br, 0xB0, 1, NULL, 2}, NULL };
static Opa bloAsm[] = {	{AsmRTF65002::br, 0x90, 1, NULL, 2}, NULL };
static Opa acbrAsm[] = { {AsmRTF65002::br, 0x53, 1, NULL, 2}, NULL };

static Opa tsbAsm[] =
{
	{AsmRTF65002::zp, 0x04, 1, AM_Z},
	{AsmRTF65002::abs, 0x0C, 1, AM_A},
	NULL
};

static Opa trbAsm[] =
{
	{AsmRTF65002::zp, 0x14, 1, AM_Z},
	{AsmRTF65002::abs, 0x1C, 1, AM_A},
	NULL
};

static Opa trsAsm[] =
{
	{AsmRTF65002::trs, 0x8B, 2, (AM_RN<<8)|AM_SPR, 2},
	NULL
};
static Opa tsrAsm[] =
{
	{AsmRTF65002::trs, 0xAB, 2, (AM_SPR<<8)|AM_RN, 2},
	{AsmRTF65002::tsr_imm, 0xAB, 2, (AM_IMM8<<8)|AM_RN, 2},
	NULL
};

static Opa intAsm[] =
{
	{AsmRTF65002::int_, 0xDC, 1, AM_IMM8, 7},
	{AsmRTF65002::int_, 0xDC, 1, AM_IMM4, 7},
	{AsmRTF65002::int_, 0xDC, 1, AM_IMM16, 7},
	NULL
};

static Opa clcAsm[] = { {Asm6502::out8, 0x18, 0, 0, 2}, NULL };
static Opa cldAsm[] = { {Asm6502::out8, 0xD8, 0, 0, 2}, NULL };
static Opa cliAsm[] = { {Asm6502::out8, 0x58, 0, 0, 2}, NULL };
static Opa clvAsm[] = { {Asm6502::out8, 0xB8, 0, 0, 2}, NULL };
static Opa toffAsm[] = { {AsmRTF65002::out16, 0x1842, 0, 0, 2}, NULL };
static Opa tonAsm[] = { {AsmRTF65002::out16, 0x3842, 0, 0, 2}, NULL };
static Opa hoffAsm[] = { {AsmRTF65002::out16, 0x5842, 0, 0, 2}, NULL };
static Opa pushaAsm[] = { {AsmRTF65002::out16, 0x0B42, 0, 0, 32}, NULL };
static Opa popaAsm[] = { {AsmRTF65002::out16, 0x2B42, 0, 0, 32}, NULL };

static Opa dexAsm[] = { {Asm6502::out8, 0xCA, 0, 0, 2}, NULL };
static Opa deyAsm[] = { {Asm6502::out8, 0x88, 0, 0, 2}, NULL };
static Opa inxAsm[] = { {Asm6502::out8, 0xE8, 0, 0, 2}, NULL };
static Opa inyAsm[] = { {Asm6502::out8, 0xC8, 0, 0, 2}, NULL };

static Opa secAsm[] = { {Asm6502::out8, 0x38, 0, 0, 2}, NULL };
static Opa sedAsm[] = { {Asm6502::out8, 0xF8, 0, 0, 2}, NULL };
static Opa seiAsm[] = { {Asm6502::out8, 0x78, 0, 0, 2}, NULL };
static Opa emmAsm[] = { {Asm6502::out8, 0xFB, 0, 0, 2}, NULL };

static Opa phaAsm[] = { {Asm6502::out8, 0x48, 0, 0, 4}, NULL };
static Opa phxAsm[] = { {Asm6502::out8, 0xDA, 0, 0, 4}, NULL };
static Opa phyAsm[] = { {Asm6502::out8, 0x5A, 0, 0, 4}, NULL };
static Opa phpAsm[] = { {Asm6502::out8, 0x08, 0, 0, 4}, NULL };
static Opa plaAsm[] = { {Asm6502::out8, 0x68, 0, 0, 4}, NULL };
static Opa plxAsm[] = { {Asm6502::out8, 0xFA, 0, 0, 4}, NULL };
static Opa plyAsm[] = { {Asm6502::out8, 0x7A, 0, 0, 4}, NULL };
static Opa plpAsm[] = { {Asm6502::out8, 0x28, 0, 0, 4}, NULL };

static Opa rtiAsm[] = { {Asm6502::out8, 0x40, 0, 0, 6}, NULL };
static Opa rtsAsm[] = { {Asm6502::out8, 0x60, 0, 0, 4 }, NULL };

static Opa taxAsm[] = { {Asm6502::out8, 0xAA, 0, 0, 2}, NULL };
static Opa tayAsm[] = { {Asm6502::out8, 0xA8, 0, 0, 2}, NULL };
static Opa tsxAsm[] = { {Asm6502::out8, 0xBA, 0, 0, 2}, NULL };
static Opa txaAsm[] = { {Asm6502::out8, 0x8A, 0, 0, 2}, NULL };
static Opa txsAsm[] = { {Asm6502::out8, 0x9A, 0, 0, 2}, NULL };
static Opa txyAsm[] = { {Asm6502::out8, 0x9B, 0, 0, 2}, NULL };
static Opa tyxAsm[] = { {Asm6502::out8, 0xBB, 0, 0, 2}, NULL };
static Opa tyaAsm[] = { {Asm6502::out8, 0x98, 0, 0, 2}, NULL };
static Opa tcdAsm[] = { {Asm6502::out8, 0x5B, 0, 0, 2}, NULL };
static Opa tdcAsm[] = { {Asm6502::out8, 0x7B, 0, 0, 2}, NULL };
static Opa tcsAsm[] = { {Asm6502::out8, 0x1B, 0, 0, 2}, NULL };
static Opa tscAsm[] = { {Asm6502::out8, 0x3B, 0, 0, 2}, NULL };
static Opa waiAsm[] = { {Asm6502::out8, 0xCB, 0, 0, 2}, NULL };
static Opa stpAsm[] = { {Asm6502::out8, 0xDB, 0, 0, 2}, NULL };
static Opa xbaAsm[] = { {Asm6502::out8, 0xEB, 0, 0, 2}, NULL };
static Opa xceAsm[] = { {Asm6502::out8, 0xFB, 0, 0, 2}, NULL };
static Opa mvnAsm[] = { {AsmRTF65002::mvn, 0x54, 0, 0, 6}, NULL };
static Opa mvpAsm[] = { {AsmRTF65002::mvn, 0x44, 0, 0, 6}, NULL };
static Opa stosAsm[] = { {AsmRTF65002::mvn, 0x64, 0, 0, 5}, NULL };
static Opa cmpsAsm[] = { {AsmRTF65002::out16, 0x4442, 0, 0, 6}, NULL };
static Opa icoffAsm[] = { {AsmRTF65002::out16, 0x0842, 0, 0, 2}, NULL };
static Opa iconAsm[] = { {AsmRTF65002::out16, 0x2842, 0, 0, 2}, NULL };

static Opa bytAsm[] = { {Asm6502::out8, 0x87, 0, 0, 1}, NULL };
static Opa ubytAsm[] = { {Asm6502::out8, 0xA7, 0, 0, 1}, NULL };
static Opa chrAsm[] = { {Asm6502::out8, 0x97, 0, 0, 1}, NULL };
static Opa uchrAsm[] = { {Asm6502::out8, 0xB7, 0, 0, 1}, NULL };
static Opa leaAsm[] = { {Asm6502::out8, 0xC7, 0, 0, 1}, NULL };


static Opa nopAsm[] = { {Asm6502::out8, 0xEA, 0, 0 ,2}, NULL };

static Opa cmpAsm[] =
{
	{AsmRTF65002::rnbit, 0x1002, 2, (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm32bit, 0xE9, 2, (AM_RN<<8)|AM_IMM32, 2},
	{AsmRTF65002::imm16bit, 0xF9, 2, (AM_RN<<8)|AM_IMM16, 2},
	{AsmRTF65002::imm8bit, 0xE5, 2, (AM_RN<<8)|AM_IMM8, 2},
	{AsmRTF65002::imm8bit, 0xE5, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::zpbit, 0xF5, 2, (AM_RN<<8)|AM_Z, 5},
	{AsmRTF65002::zpbit, 0xF5, 2, (AM_RN<<8)|AM_ZX, 5},
	{AsmRTF65002::zpbit, 0xF5, 2, (AM_RN<<8)|AM_ZY, 5},
	{AsmRTF65002::zpbit, 0xE1, 2, (AM_RN<<8)|AM_IX, 6},
	{AsmRTF65002::zpbit, 0xF1, 2, (AM_RN<<8)|AM_IY, 7},
	{AsmRTF65002::rindbit, 0xF2, 2, (AM_RN<<8)|AM_RIND, 5},
	{AsmRTF65002::absbit, 0xED, 2, (AM_RN<<8)|AM_A, 5},
	{AsmRTF65002::bit_absx, 0xFD, 2, (AM_RN<<8)|AM_AX, 5},
	{AsmRTF65002::bit_absx, 0xFD, 2, (AM_RN<<8)|AM_AY, 5},
	{AsmRTF65002::bit_acc_imm32, 0xE9, 1, AM_IMM32, 2},
	{AsmRTF65002::bit_acc_imm16, 0xF9, 1, AM_IMM16, 2},
	{AsmRTF65002::bit_acc_zpx, 0xF5, 1, AM_Z, 5},
	{AsmRTF65002::bit_acc_zpx, 0xF5, 1, AM_ZX, 5},
	{AsmRTF65002::bit_acc_zpx, 0xF5, 1, AM_ZY, 5},
	{AsmRTF65002::Ximm8, 0xC5, 1, AM_IMM8, 2},
	{AsmRTF65002::Ximm8, 0xC5, 1, AM_IMM4, 2},
//	{AsmRTF65002::bit_acc_imm8, 0xE5, 1, AM_IMM8},
	{AsmRTF65002::bit_acc_abs, 0xED, 1, AM_A, 5},
	{AsmRTF65002::bit_acc_absx, 0xFD, 1, AM_AX,5},
	{AsmRTF65002::bit_acc_absx, 0xFD, 1, AM_AY,5},
	{AsmRTF65002::st_dsp, 0xE3, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR, 5},
	{AsmRTF65002::st_acc_dsp, 0xE3, 1, AM_SR, 5},
	NULL
};

static Opa cpxAsm[] =
{
	{AsmRTF65002::Ximm32, 0xE0, 1, AM_IMM4, 2},
	{AsmRTF65002::Ximm32, 0xE0, 1, AM_IMM8, 2},
 	{AsmRTF65002::Ximm32, 0xE0, 1, AM_IMM16, 2},
	{AsmRTF65002::Ximm32, 0xE0, 1, AM_IMM32, 2},
    {AsmRTF65002::zp2, 0xE4, 1, AM_Z, 5},
    {AsmRTF65002::zp2, 0xE4, 1, AM_ZX, 5},
    {AsmRTF65002::zp2, 0xE4, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0xEC, 1, AM_A, 5},
	NULL
};

static Opa cpyAsm[] =
{
	{AsmRTF65002::Ximm32, 0xC0, 1, AM_IMM4, 2},
	{AsmRTF65002::Ximm32, 0xC0, 1, AM_IMM8, 2},
	{AsmRTF65002::Ximm32, 0xC0, 1, AM_IMM16, 2},
	{AsmRTF65002::Ximm32, 0xC0, 1, AM_IMM32, 2},
    {AsmRTF65002::zp2, 0xC4, 1, AM_Z, 5},
    {AsmRTF65002::zp2, 0xC4, 1, AM_ZX, 5},
    {AsmRTF65002::zp2, 0xC4, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0xCC, 1, AM_A, 5},
	NULL
};

static Opa decAsm[] =
{
    {Asm6502::out8, 0x3a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0xC6, 1, AM_RN, 2},
    {AsmRTF65002::zp2, 0xD6, 1, AM_Z, 5},
    {AsmRTF65002::zp2, 0xD6, 1, AM_ZX, 5},
    {AsmRTF65002::zp2, 0xD6, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0xCE, 1, AM_A, 5},
	{AsmRTF65002::absx2, 0xDE, 1, AM_AX, 5},
	NULL
};

static Opa incAsm[] =
{
    {Asm6502::out8, 0x1a, 1, AM_ACC, 2},
	{AsmRTF65002::rn1, 0xE6, 1, AM_RN, 2},
    {AsmRTF65002::zp2, 0xF6, 1, AM_Z, 5},
    {AsmRTF65002::zp2, 0xF6, 1, AM_ZX, 5},
    {AsmRTF65002::zp2, 0xF6, 1, AM_ZY, 5},
	{AsmRTF65002::abs2, 0xEE, 1, AM_A, 5},
	{AsmRTF65002::absx2, 0xFE, 1, AM_AX, 5},
	NULL
};

static Opa bmsAsm[] =
{
    {AsmRTF65002::bms_zp, 0x0642, 1, AM_Z, 5},
    {AsmRTF65002::bms_zp, 0x0642, 1, AM_ZX, 5},
    {AsmRTF65002::bms_zp, 0x0642, 1, AM_ZY, 5},
	{AsmRTF65002::bms_abs, 0x0E42, 1, AM_A, 5},
	{AsmRTF65002::bms_absx, 0x1E42, 1, AM_AX, 5},
	{AsmRTF65002::bms_absx, 0x1E42, 1, AM_AY, 5},
	NULL
};

static Opa bmcAsm[] =
{
    {AsmRTF65002::bms_zp, 0x2642, 1, AM_Z, 5},
    {AsmRTF65002::bms_zp, 0x2642, 1, AM_ZX, 5},
    {AsmRTF65002::bms_zp, 0x2642, 1, AM_ZY, 5},
	{AsmRTF65002::bms_abs, 0x2E42, 1, AM_A, 5},
	{AsmRTF65002::bms_absx, 0x3E42, 1, AM_AX, 5},
	{AsmRTF65002::bms_absx, 0x3E42, 1, AM_AY, 5},
	NULL
};

static Opa bmfAsm[] =
{
    {AsmRTF65002::bms_zp, 0x4642, 1, AM_Z, 5},
    {AsmRTF65002::bms_zp, 0x4642, 1, AM_ZX, 5},
    {AsmRTF65002::bms_zp, 0x4642, 1, AM_ZY, 5},
	{AsmRTF65002::bms_abs, 0x4E42, 1, AM_A, 5},
	{AsmRTF65002::bms_absx, 0x5E42, 1, AM_AX, 5},
	{AsmRTF65002::bms_absx, 0x5E42, 1, AM_AY, 5},
	NULL
};

static Opa bmtAsm[] =
{
    {AsmRTF65002::bms_zp, 0x6642, 1, AM_Z, 5},
    {AsmRTF65002::bms_zp, 0x6642, 1, AM_ZX, 5},
    {AsmRTF65002::bms_zp, 0x6642, 1, AM_ZY, 5},
	{AsmRTF65002::bms_abs, 0x6E42, 1, AM_A, 5},
	{AsmRTF65002::bms_absx, 0x7E42, 1, AM_AX, 5},
	{AsmRTF65002::bms_absx, 0x7E42, 1, AM_AY, 5},
	NULL
};

static Opa splAsm[] =
{
    {AsmRTF65002::bms_abs, 0x8E42, 1, AM_Z, 5},
    {AsmRTF65002::bms_absx, 0x9E42, 1, AM_ZX, 5},
    {AsmRTF65002::bms_absx, 0x9E42, 1, AM_ZY, 5},
	{AsmRTF65002::bms_abs, 0x8E42, 1, AM_A, 5},
	{AsmRTF65002::bms_absx, 0x9E42, 1, AM_AX, 5},
	{AsmRTF65002::bms_absx, 0x9E42, 1, AM_AY, 5},
	NULL
};

static Opa deaAsm[] = {{Asm6502::out8, 0x3a,0,0,2}, NULL };
static Opa inaAsm[] = {{Asm6502::out8, 0x1a,0,0,2}, NULL };

static Opa eorAsm[] =
{
	{AsmRTF65002::rn, 0x4002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::r,  0x57, 2,  (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm4, 0x47, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::imm32, 0x49, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32, 2},
	{AsmRTF65002::imm16, 0x59, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16, 2},
	{AsmRTF65002::imm8, 0x45, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8, 2},
	{AsmRTF65002::imm8, 0x45, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::zp, 0x55, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z, 5},
	{AsmRTF65002::zp, 0x55, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX, 5},
	{AsmRTF65002::zp, 0x55, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY, 5},
	{AsmRTF65002::zp, 0x41, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX, 6},
	{AsmRTF65002::zp, 0x51, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY, 7},
	{AsmRTF65002::rind, 0x52, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND, 5},
	{AsmRTF65002::abs, 0x4D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::absx, 0x5D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX ,5},
	{AsmRTF65002::absx, 0x5D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY, 5},
	{AsmRTF65002::acc_rn, 0x4002, 1, AM_RN, 2},
	{AsmRTF65002::acc_imm32, 0x49, 1, AM_IMM32, 2},
	{AsmRTF65002::acc_imm16, 0x59, 1, AM_IMM16, 2},
	{AsmRTF65002::acc_imm8, 0x45, 1, AM_IMM8, 2},
	{AsmRTF65002::acc_imm8, 0x45, 1, AM_IMM4, 2},
	{AsmRTF65002::acc_zp, 0x55, 1, AM_ZX, 5},
	{AsmRTF65002::acc_zp, 0x55, 1, AM_Z, 5},
	{AsmRTF65002::acc_zp, 0x41, 1, AM_IX, 6},
	{AsmRTF65002::acc_zp, 0x51, 1, AM_IY, 7},
	{AsmRTF65002::acc_rind, 0x52, 1, AM_RIND, 5},
	{AsmRTF65002::acc_abs, 0x4D, 1, AM_A, 5},
	{AsmRTF65002::acc_absx, 0x5D, 1, AM_AX, 5},
	{AsmRTF65002::acc_absx, 0x5D, 1, AM_AY, 5},
	{AsmRTF65002::dsp, 0x43, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR, 5},
	{AsmRTF65002::acc_dsp, 0x43, 1, AM_SR, 5},
	NULL
};

static Opa subAsm[] =
{
	{AsmRTF65002::rn, 0x1002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::r,  0xF7, 2,  (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm4, 0xE7, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::imm32, 0xE9, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32, 22},
	{AsmRTF65002::imm16, 0xF9, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16, 2},
	{AsmRTF65002::imm8, 0xE5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8, 2},
	{AsmRTF65002::imm8, 0xE5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::zp, 0xF5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::zp, 0xF5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX,5},
	{AsmRTF65002::zp, 0xF5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY,5},
	{AsmRTF65002::zp, 0xE1, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX,6},
	{AsmRTF65002::zp, 0xF1, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY,7},
	{AsmRTF65002::rind, 0xF2, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND,5},
	{AsmRTF65002::abs, 0xED, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::absx, 0xFD, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::absx, 0xFD, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY,5},
	{AsmRTF65002::acc_rn, 0x1002, 1, AM_RN,2},
	{AsmRTF65002::acc_imm32, 0xE9, 1, AM_IMM32,2},
	{AsmRTF65002::acc_imm16, 0xF9, 1, AM_IMM16,2},
	{AsmRTF65002::acc_imm8, 0xE5, 1, AM_IMM8,2},
	{AsmRTF65002::acc_imm8, 0xE5, 1, AM_IMM4,2},
	{AsmRTF65002::acc_zp, 0xF5, 1, AM_ZX,5},
	{AsmRTF65002::acc_zp, 0xF5, 1, AM_Z,5},
	{AsmRTF65002::acc_zp, 0xE1, 1, AM_IX,6},
	{AsmRTF65002::acc_zp, 0xF1, 1, AM_IY,7},
	{AsmRTF65002::acc_rind, 0xF2, 1, AM_RIND,5},
	{AsmRTF65002::acc_abs, 0xED, 1, AM_A,5},
	{AsmRTF65002::acc_absx, 0xFD, 1, AM_AX,5},
	{AsmRTF65002::acc_absx, 0xFD, 1, AM_AY,5},
	{AsmRTF65002::dsp, 0xE3, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR,5},
	{AsmRTF65002::acc_dsp, 0xE3, 1, AM_SR,5},
	{AsmRTF65002::sub_sp_imm8, 0x85, 2, (AM_SPR<<8)|AM_IMM4,2},
	{AsmRTF65002::sub_sp_imm8, 0x85, 2, (AM_SPR<<8)|AM_IMM8,2},
	{AsmRTF65002::sub_sp_imm16, 0x99, 2, (AM_SPR<<8)|AM_IMM16,2},
	{AsmRTF65002::sub_sp_imm32, 0x89, 2, (AM_SPR<<8)|AM_IMM32,2},
	NULL
};

static Opa orAsm[] =
{
	{AsmRTF65002::rn, 0x5002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::r,  0x17, 2,  (AM_RN<<8)|AM_RN, 2},
	{AsmRTF65002::imm4, 0x07, 2, (AM_RN<<8)|AM_IMM4, 2},
	{AsmRTF65002::imm32, 0x09, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,2},
	{AsmRTF65002::imm16, 0x19, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,2},
	{AsmRTF65002::imm8, 0x05, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8, 0x05, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX,5},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY,5},
	{AsmRTF65002::zp, 0x01, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX,6},
	{AsmRTF65002::zp, 0x11, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY,7},
	{AsmRTF65002::rind, 0x12, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND,5},
	{AsmRTF65002::abs, 0x0D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::absx, 0x1D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::absx, 0x1D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY,5},
	{AsmRTF65002::acc_rn, 0x5002, 1, AM_RN,2},
	{AsmRTF65002::acc_imm32, 0x09, 1, AM_IMM32,2},
	{AsmRTF65002::acc_imm16, 0x19, 1, AM_IMM16,2},
	{AsmRTF65002::acc_imm8, 0x05, 1, AM_IMM8,2},
	{AsmRTF65002::acc_imm8, 0x05, 1, AM_IMM4,2},
	{AsmRTF65002::acc_zp, 0x15, 1, AM_ZX,5},
	{AsmRTF65002::acc_zp, 0x15, 1, AM_Z,5},
	{AsmRTF65002::acc_zp, 0x01, 1, AM_IX,6},
	{AsmRTF65002::acc_zp, 0x11, 1, AM_IY,7},
	{AsmRTF65002::acc_rind, 0x12, 1, AM_RIND,5},
	{AsmRTF65002::acc_abs, 0x0D, 1, AM_A,5},
	{AsmRTF65002::acc_absx, 0x1D, 1, AM_AX,5},
	{AsmRTF65002::acc_absx, 0x1D, 1, AM_AY,5},
	{AsmRTF65002::dsp, 0x03, 3, (AM_RN<<16)|(AM_RN<<8)|AM_SR,5},
	{AsmRTF65002::acc_dsp, 0x03, 1, AM_SR,5},
	NULL
};

static Opa orbAsm[] =
{
	{AsmRTF65002::orb_zp, 0xB5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::orb_zpx, 0xB5, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY,5},
    {AsmRTF65002::orb_zpx, 0xB5, 3, (AM_RN<<16)|(AM_RN<<8)| AM_ZX,5},
	{AsmRTF65002::orb_abs, 0xAD, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::orb_absx, 0xBD, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::orb_absx, 0xBD, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY,5},
	NULL
};

static Opa oraAsm[] =
{
	{AsmRTF65002::rn, 0x5002, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::imm32, 0x09, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM32,2},
	{AsmRTF65002::imm16, 0x19, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM16,2},
	{AsmRTF65002::imm8, 0x05, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8, 0x05, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_Z,5},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZX,5},
	{AsmRTF65002::zp, 0x15, 3, (AM_RN<<16)|(AM_RN<<8)|AM_ZY,5},
	{AsmRTF65002::zp, 0x01, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IX,6},
	{AsmRTF65002::zp, 0x11, 3, (AM_RN<<16)|(AM_RN<<8)|AM_IY,7},
	{AsmRTF65002::rind, 0x12, 3, (AM_RN<<16)|(AM_RN<<8)|AM_RIND,5},
	{AsmRTF65002::abs, 0x0D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_A,5},
	{AsmRTF65002::absx, 0x1D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AX,5},
	{AsmRTF65002::absx, 0x1D, 3, (AM_RN<<16)|(AM_RN<<8)|AM_AY,5},
	{AsmRTF65002::acc_rn, 0x5002, 1, AM_RN,2},
	{AsmRTF65002::acc_imm32, 0x09, 1, AM_IMM32,2},
	{AsmRTF65002::acc_imm16, 0x19, 1, AM_IMM16,2},
	{AsmRTF65002::acc_imm8, 0x05, 1, AM_IMM8,2},
	{AsmRTF65002::acc_imm8, 0x05, 1, AM_IMM4,2},
	{AsmRTF65002::acc_zp, 0x15, 1, AM_ZX,5},
	{AsmRTF65002::acc_zp, 0x15, 1, AM_Z,5},
	{AsmRTF65002::acc_zp, 0x01, 1, AM_IX,6},
	{AsmRTF65002::acc_zp, 0x11, 1, AM_IY,7},
	{AsmRTF65002::acc_rind, 0x12, 1, AM_RIND,5},
	{AsmRTF65002::acc_abs, 0x0D, 1, AM_A,5},
	{AsmRTF65002::acc_absx, 0x1D, 1, AM_AX,5},
	{AsmRTF65002::acc_absx, 0x1D, 1, AM_AY,5},
	{AsmRTF65002::acc_dsp, 0x03, 1, AM_SR,5},
	NULL
};

static Opa stAsm[] =
{
	{AsmRTF65002::zpbit, 0x95, 2, (AM_RN<<8)|AM_Z,4},
	{AsmRTF65002::zpbit, 0x95, 2, (AM_RN<<8)|AM_ZX,4},
	{AsmRTF65002::zpbit, 0x95, 2, (AM_RN<<8)|AM_ZY,4},
	{AsmRTF65002::zpbit, 0x81, 2, (AM_RN<<8)|AM_IX,5},
	{AsmRTF65002::zpbit, 0x91, 2, (AM_RN<<8)|AM_IY,6},
	{AsmRTF65002::st_rind, 0x92, 2, (AM_RN<<8)|AM_RIND,4},
	{AsmRTF65002::absbit, 0x9C, 2, (AM_RN<<8)|AM_A,4},
	{AsmRTF65002::bit_absx, 0x9D, 2, (AM_RN<<8)|AM_AX,4},
	{AsmRTF65002::bit_absx, 0x9D, 2, (AM_RN<<8)|AM_AY,4},
	{AsmRTF65002::st_dsp, 0x83, 2, (AM_RN<<8)|AM_SR,4},
	{AsmRTF65002::st_acc_dsp, 0x83, 1, AM_SR,4},
	NULL
};

static Opa staAsm[] =
{
	{AsmRTF65002::zpsta, 0x95, 1, AM_Z,4},
	{AsmRTF65002::zpsta, 0x95, 1, AM_ZX,4},
	{AsmRTF65002::zpsta, 0x95, 1, AM_ZY,4},
	{AsmRTF65002::zpsta, 0x81, 1, AM_IX,5},
	{AsmRTF65002::zpsta, 0x91, 1, AM_IY,6},
	{AsmRTF65002::sta_rind, 0x92, 1, AM_RIND,4},
	{AsmRTF65002::abs2, 0x8D, 1, AM_A,4},
	{AsmRTF65002::absxsta, 0x9D, 1, AM_AX,4},
	{AsmRTF65002::absxsta, 0x9D, 1, AM_AY,4},
	{AsmRTF65002::st_acc_dsp, 0x83, 1, AM_SR,4},
	NULL
};

static Opa stxAsm[] =
{
    {AsmRTF65002::zp2, 0x86, 1, AM_Z,4},
    {AsmRTF65002::zp2, 0x96, 1, AM_ZX,4},
	{AsmRTF65002::zp2, 0x96, 1, AM_ZY,4},
	{AsmRTF65002::abs2, 0x8E, 1, AM_A,4},
	{AsmRTF65002::stx_absx, 0x9D, 1, AM_AX,4},
	{AsmRTF65002::stx_absx, 0x9D, 1, AM_AY,4},
	{AsmRTF65002::stx_rind, 0x92, 1, AM_RIND,4},
	NULL
};

static Opa styAsm[] =
{
    {AsmRTF65002::zp2, 0x84, 1, AM_Z,4},
    {AsmRTF65002::zp2, 0x94, 1, AM_ZX,4},
    {AsmRTF65002::zp2, 0x94, 1, AM_ZY,4},
	{AsmRTF65002::abs2, 0x8C, 1, AM_A,4},
	{AsmRTF65002::sty_absx, 0x9D, 1, AM_AX,4},
	{AsmRTF65002::sty_absx, 0x9D, 1, AM_AY,4},
	{AsmRTF65002::sty_rind, 0x92, 1, AM_RIND,4},
	NULL
};

static Opa stzAsm[] =
{
    {AsmRTF65002::stz_zp, 0x95, 1, AM_Z,4},
    {AsmRTF65002::stz_zp, 0x95, 1, AM_ZX,4},
    {AsmRTF65002::stz_zp, 0x95, 1, AM_ZY,4},
	{AsmRTF65002::stz_abs, 0x9C, 1, AM_A,4},
	{AsmRTF65002::stz_rind, 0x92, 1, AM_RIND,4},
	{AsmRTF65002::stz_absx, 0x9D, 1, AM_AX,4},
	{AsmRTF65002::stz_absx, 0x9D, 1, AM_AY,4},
	NULL
};

static Opa ldAsm[] =
{
	{AsmRTF65002::rn2, 0x7B, 2, (AM_RN<<8)|AM_RN,2},
	{AsmRTF65002::imm32ld, 0x09, 2, (AM_RN<<8)|AM_IMM32,2},
	{AsmRTF65002::imm16ld, 0x19, 2, (AM_RN<<8)|AM_IMM16,2},
	{AsmRTF65002::imm8ld, 0x05, 2, (AM_RN<<8)|AM_IMM8,2},
	{AsmRTF65002::imm8ld, 0x05, 2, (AM_RN<<8)|AM_IMM4,2},
	{AsmRTF65002::zpld, 0x15, 2, (AM_RN<<8)|AM_Z,4},
	{AsmRTF65002::zpld, 0x15, 2, (AM_RN<<8)|AM_ZY,4},	// force abs,y
    {AsmRTF65002::zpld, 0x15, 2,(AM_RN<<8)| AM_ZX,4},
    {AsmRTF65002::zpld, 0x01, 2, (AM_RN<<8)|AM_IX,5},
    {AsmRTF65002::zpld, 0x11, 2, (AM_RN<<8)|AM_IY,6},
	{AsmRTF65002::zpld, 0x12, 2, (AM_RN<<8)|AM_ZI,5},
	{AsmRTF65002::absld, 0x0D, 2, (AM_RN<<8)|AM_A,4},
	{AsmRTF65002::absxld, 0x1D, 2, (AM_RN<<8)|AM_AX,4},
	{AsmRTF65002::absxld, 0x1D, 2, (AM_RN<<8)|AM_AY,4},
	{AsmRTF65002::rindld, 0x12, 2, (AM_RN<<8)|AM_RIND,4},
	{AsmRTF65002::ld_dsp, 0x03, 2, (AM_RN<<8)|AM_SR,4},
	{AsmRTF65002::ld_acc_dsp, 0x03, 1, AM_SR,4},
	NULL
};

static Opa lbAsm[] =
{
	{AsmRTF65002::lb_zp, 0xB5, 2, (AM_RN<<8)|AM_Z,4},
	{AsmRTF65002::lb_zp, 0xB5, 2, (AM_RN<<8)|AM_ZY,4},
    {AsmRTF65002::lb_zp, 0xB5, 2,(AM_RN<<8)| AM_ZX,4},
	{AsmRTF65002::absldb, 0xAD, 2, (AM_RN<<8)|AM_A,4},
	{AsmRTF65002::absxldb, 0xBD, 2, (AM_RN<<8)|AM_AX,4},
	{AsmRTF65002::absxldb, 0xBD, 2, (AM_RN<<8)|AM_AY,4},
	NULL
};

static Opa ldaAsm[] =
{
	{AsmRTF65002::Ximm32, 0xA9, 1, AM_IMM32,2},
	{AsmRTF65002::Ximm16, 0xB9, 1, AM_IMM16,2},
	{AsmRTF65002::Ximm8, 0xA5, 1, AM_IMM8,2},
	{AsmRTF65002::Ximm8, 0xA5, 1, AM_IMM4,2},
	{AsmRTF65002::zplda, 0x15, 1, AM_Z,4},
	{AsmRTF65002::zplda, 0x15, 1, AM_ZY,4},	// force abs,y
    {AsmRTF65002::zplda, 0x15, 1, AM_ZX,4},
    {AsmRTF65002::zplda, 0x01, 1, AM_IX,5},
    {AsmRTF65002::zplda, 0x11, 1, AM_IY,6},
	{AsmRTF65002::zplda, 0x01, 1, AM_ZI,5},
	{AsmRTF65002::abslda, 0x0D, 1, AM_A,4},
	{AsmRTF65002::absxlda, 0x1D, 1, AM_AX,4},
	{AsmRTF65002::absxlda, 0x1D, 1, AM_AY,4},
	{AsmRTF65002::rindlda, 0x12, 1, AM_RIND,4},
	{AsmRTF65002::ld_acc_dsp, 0x03, 1, AM_SR,4},
	NULL
};

static Opa ldxAsm[] =
{
	{AsmRTF65002::Ximm8, 0xA6, 1, AM_IMM4,2},
	{AsmRTF65002::Ximm8, 0xA6, 1, AM_IMM8,2},
	{AsmRTF65002::Ximm16, 0xB2, 1, AM_IMM16,2},
	{AsmRTF65002::Ximm32, 0xA2, 1, AM_IMM32,2},
    {AsmRTF65002::zp2, 0xA6, 1, AM_Z,4},
    {AsmRTF65002::zp2, 0xB6, 1, AM_ZX,4},
    {AsmRTF65002::zp2, 0xB6, 1, AM_ZY,4},
	{AsmRTF65002::ldx_abs, 0xAE, 1, AM_A,4},
	{AsmRTF65002::ldx_absx, 0xBE, 1, AM_AX,4},
	{AsmRTF65002::ldx_absx, 0xBE, 1, AM_AY,4},
	{AsmRTF65002::rindldx, 0x12, 1, AM_RIND,4},
	NULL
};

static Opa ldyAsm[] =
{
//	{AsmRTF65002::rny, 0x5002, 1 AM_RN},
	{AsmRTF65002::Ximm32, 0xA0, 1, AM_IMM4,2},
	{AsmRTF65002::Ximm32, 0xA0, 1, AM_IMM8,2},
	{AsmRTF65002::Ximm32, 0xA0, 1, AM_IMM16,2},
	{AsmRTF65002::Ximm32, 0xA0, 1, AM_IMM32,2},
	{AsmRTF65002::zp2, 0xA4, 1, AM_Z,4},
    {AsmRTF65002::zp2, 0xB4, 1, AM_ZX,4},
    {AsmRTF65002::zp2, 0xB4, 1, AM_ZY,4},
	{AsmRTF65002::ldx_abs, 0xAC, 1, AM_A,4},
	{AsmRTF65002::ldx_absx, 0xBC, 1, AM_AX,4},
	{AsmRTF65002::ldx_absx, 0xBC, 1, AM_AY,4},
	{AsmRTF65002::ldy_rind, 0x12, 1, AM_RIND,4},
	NULL
};

static Opa jmpAsm[] =
{
	{AsmRTF65002::jmp_abs, 0x4c, 1, AM_A,2},
	{AsmRTF65002::jmp_abs, 0x4c, 1, AM_Z,2},	// Force abs
	{AsmRTF65002::jmp_abs, 0x4c, 1, AM_ZX,2},	// Force abs
	{AsmRTF65002::jmp_abs, 0x4c, 1, AM_ZY,2},	// Force abs
	{AsmRTF65002::jml_abs, 0x6c, 1, AM_I,4},
	{AsmRTF65002::jml_abs, 0x7c, 1, AM_IX,4},
	{AsmRTF65002::jml_abs, 0x6c, 1, AM_ZI,4},	// force abs
	{AsmRTF65002::rind_jmp, 0xD2, 1, AM_RIND,4},
	NULL
};

static Opa jsrAsm[] =
{
	{AsmRTF65002::jmp_abs, 0x20, 1, AM_A,4} ,
	{AsmRTF65002::jmp_abs, 0x20, 1, AM_Z,4},	// force abs
	{AsmRTF65002::jmp_abs, 0x20, 1, AM_ZX,4},	// force abs
	{AsmRTF65002::jmp_abs, 0x20, 1, AM_ZY,4},	// force abs
	{AsmRTF65002::jml_abs, 0x2C, 1, AM_I,6},
	{AsmRTF65002::jml_abs, 0xFC, 1, AM_IX,6},
	{AsmRTF65002::jml_abs, 0x20, 1, AM_AL,4} ,
	{AsmRTF65002::rind_jmp, 0xC2, 1, AM_RIND,6},
	NULL
};
static Opa jslAsm[] =
{
	{AsmRTF65002::jml_abs, 0x22, 1, AM_A,4} ,
	{AsmRTF65002::jml_abs, 0x22, 1, AM_Z,4},	// force abs
	{AsmRTF65002::jml_abs, 0x22, 1, AM_AL,4} ,
	{AsmRTF65002::jml_abs, 0x2C, 1, AM_I,6},
	NULL
};

static Opa jmlAsm[] =
{
	{AsmRTF65002::jml_abs, 0x5C, 1, AM_A,4} ,
	{AsmRTF65002::jml_abs, 0x5C, 1, AM_Z,4},	// force abs
	{AsmRTF65002::jml_abs, 0x5C, 1, AM_AL,4} ,
	NULL
};

static Opa popAsm[] =
{
	{AsmRTF65002::pop, 0x2B, 1, AM_RN, 4 },
	NULL
};

static Opa pushAsm[] =
{
	{AsmRTF65002::push, 0x0B, 1, AM_RN, 4 },
	NULL
};


static Mne opsRTF65002[] =
{
	{"acbr", acbrAsm, 1},
	{"add", addAsm, 3 },
	{"and", andAsm, 3 },
	{"asl", aslAsm, 1 },
	{"bcc", bccAsm, 1 },
	{"bcs", bcsAsm, 1 },
	{"beq", beqAsm, 1 },
	{"bge", bgeAsm, 1 },
	{"bgeu", bccAsm, 1 },
	{"bgt", bgtAsm, 1 },
	{"bhi", bhiAsm, 1 },
	{"bhs", bhsAsm, 1 },
	{"bit", bitAsm, 2 },
	{"ble", bleAsm, 1 },
	{"blo", bloAsm, 1 },
	{"bls", blsAsm, 1 },
	{"blt", bltAsm, 1 },
	{"bltu", bcsAsm, 1 },
	{"bmc", bmcAsm, 1 },
	{"bmf", bmfAsm, 1 },
	{"bmi", bmiAsm, 1 },
	{"bms", bmsAsm, 1 },
	{"bmt", bmtAsm, 1 },
	{"bne", bneAsm, 1 },
	{"bpl", bplAsm, 1 },
	{"bra", braAsm, 1 },
	{"brk", brkAsm, 1 },
	{"brl", brlAsm, 1 },
	{"bsr", bsrAsm, 1 },
	{"bvc", bvcAsm, 1 },
	{"bvs", bvsAsm, 1 },
	{"byte", bytAsm, 0, },

	{"char", chrAsm, 0 },
	{"clc", clcAsm, 0 },
	{"cld", cldAsm, 0 },
	{"cli", cliAsm, 0 },
	{"clv", clvAsm, 0 },
	{"cmp", cmpAsm, 3 },
	{"cmps", cmpsAsm, 0 },

	{"cpx", cpxAsm, 1 },
	{"cpy", cpyAsm, 1 },
	
	{"dea", deaAsm, 0 },
	{"dec", decAsm, 1 },
	{"dex", dexAsm, 0 },
	{"dey", deyAsm, 0 },
	{"div", divAsm, 3 },
	{"divs", divsAsm, 3},
	
	{"emm", emmAsm, 0 },
	{"eor", eorAsm, 3 },

	{"hoff", hoffAsm, 0 },

	{"icoff", icoffAsm, 0},
	{"icon", iconAsm, 0},
	{"ina", inaAsm, 0 },
	{"inc", incAsm, 1 },
	{"int", intAsm, 1 },

	{"inx", inxAsm, 0 },
	{"iny", inyAsm, 0 },

	{"jml", jmlAsm, 1 },
	{"jmp", jmpAsm, 1 },
	{"jsl", jslAsm, 1 },
	{"jsr", jsrAsm, 1 },


     {"ld", ldAsm, 2 },
	{"lda", ldaAsm, 1 },
	{"ldx", ldxAsm, 1 },
    {"ldy", ldyAsm, 1 },
	{"lea", leaAsm, 0 },
	{"lsr", lsrAsm, 1 },
	{"mod", modAsm, 3 },
	{"mods", modsAsm, 3},
	{"mul", mulAsm, 3 },
	{"muls", mulsAsm, 3},
	{"mvn", mvnAsm, 0 },
	{"mvp", mvpAsm, 0 },
	{"nop", nopAsm, 0 },

	{"or", orAsm, 3 },
	{"ora", oraAsm, 1 },
	{"orb", orbAsm, 3 },

	{"pha", phaAsm, 0 },
	{"php", phpAsm, 0 },
	{"phx", phxAsm, 0 },
	{"phy", phyAsm, 0 },
	{"pla", plaAsm, 0 },
	{"plp", plpAsm, 0 },
	{"plx", plxAsm, 0 },
	{"ply", plyAsm, 0 },
	{"pop", popAsm, 1 },
	{"popa", popaAsm, 0 },
	{"push", pushAsm, 1 },
	{"pusha", pushaAsm, 0 },
	
	{"rol", rolAsm, 1 },
	{"ror", rorAsm, 1 },

	{"rti", rtiAsm, 0 },
	{"rts", rtsAsm, 0 },


	{"sec", secAsm, 0 },
	{"sed", sedAsm, 0 },
	{"sei", seiAsm, 0 },
	{"spl", splAsm, 2 },

	{"st", stAsm, 2 },
	{"sta", staAsm, 1 },
	{"stos", stosAsm, 1 },
	{"stp", stpAsm, 0 },
	{"stx", stxAsm, 1 },
	{"sty", styAsm, 1 },
	{"stz", stzAsm, 1 },

	{"sub", subAsm, 3 },

	{"tas", tcsAsm, 0 },
	{"tax", taxAsm, 0 },
	{"tay", tayAsm, 0 },
	{"tcs", tcsAsm, 0 },
	{"toff", toffAsm, 0 },
	{"ton", tonAsm, 0 },
	{"trb", trbAsm, 1 },
	{"trs", trsAsm, 2 },
	{"tsa", tscAsm, 0 },
	{"tsb", tsbAsm, 1 },
	{"tsc", tscAsm, 0 },
	{"tsr", tsrAsm, 2 },
	{"tsx", tsxAsm, 0 },
	{"txa", txaAsm, 0 },
	{"txs", txsAsm, 0 },
	{"txy", txyAsm, 0 },
	{"tya", tyaAsm, 0 },
	{"tyx", tyxAsm, 0 },

	{"ubyte", ubytAsm, 0 },
	{"uchar", uchrAsm, 0 },

	{"wai", waiAsm, 0 },
	{"xce", xceAsm, 0 },

};

	Operands65002 operRTF65002;

	Cpu optabRTF65002 =
	{
		"RTF65002", 32, 1, 42, sizeof(opsRTF65002)/sizeof(Mne), opsRTF65002, (Operands *)&operRTF65002
	};
}

