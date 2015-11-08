#pragma once

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	am6502.h
=============================================================== */

enum {
	AM_ = 0,
	AM_ACC=6,
	AM_Z,
	AM_ZX,
	AM_ZY,
	AM_A,
	AM_AL,
	AM_AX,
	AM_AXL,
	AM_AY,
	AM_I,
	AM_IL,
	AM_IX,
	AM_IY,
	AM_IYL,
	AM_DS,
	AM_XI,
	AM_YI,
	AM_SR,
	AM_ZI,
	AM_ZIL,
	AM_SRIY,
	AM_RR,
	AM_IMM4,
	AM_IMM8,
	AM_IMM16,
	AM_IMM32,
	AM_SPR,
	AM_XAL,
	AM_XAXL,
	AM_XAYL,
	AM_XIL,
	AM_XIYL,
	AM_XSRIY,
	AM_SEG
};

/*
#define AM_RN   1
#define AM_IMM  2       // LDA #$12
#define AM_Z    3       // LDA $10
#define AM_ZX   4       // LDA $10,X
#define AM_ZY   5       // LDX $10,Y
#define AM_A    6       // LDA $1000
#define AM_AX   7       // LDA $1000,X
#define AM_AY   8       // LDA $1000,Y
#define AM_I    9       // JMP ($2000)
#define AM_IX   10      // LDA ($20,X)
#define AM_IY   11      // LDA ($20),Y
#define AM_DS   12      // LDA 10,SP
#define AM_XI   13
#define AM_YI   14
#define AM_SI   15
#define AM_ZI   16      // LDA ($40)
#define AM_ACC	17

#define AM_     128
*/


