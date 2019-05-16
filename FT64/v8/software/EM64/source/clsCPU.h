#include "Instructions.h"

#pragma once

class clsSystem;

// Currently unaligned memory access is not supported.
// Made more complicated by the fact it's a 64 bit machine.

typedef	union tag_opval {
	__int64 ai;
	double ad;
} opval;

class clsCPU
{
	opval opera,operb,operc;
	__int64 a, b, c, res, res2, imm, sp_res;
	opval dres;
	unsigned __int64 ua, ub;
	__int64 sir;
	bool StatusHWI;
	int Ra,Rb,Rc;
	int Rt,Rt2;
	int mb,me;
	int spr;
	int Bn;
	unsigned int regLR;
	unsigned int imm1;
	unsigned int imm2;
	char hasPrefix;
	int immcnt;
	unsigned int opcode;
	unsigned int func;
	int i1;
	int nn;
	unsigned int bmask;
	int brdisp;
	int r1,r2,r3;
public:
	char isRunning;
	char brk;
	unsigned __int64 ir, xir, wir;
	unsigned int rgs;
	unsigned __int64 regs[32][64];
	unsigned __int64 vregs[32][64];
	double dregs[32];
	unsigned int pc;
	unsigned int pcs[40];
	unsigned int dpc;
	unsigned int epc;
	unsigned int ipc;
	unsigned __int64 dsp;
	unsigned __int64 esp;
	unsigned __int64 isp;
	unsigned int vbr;
	unsigned dbad0;
	unsigned dbad1;
	unsigned dbad2;
	unsigned dbad3;
	unsigned __int64 dbctrl;
	unsigned __int64 dbstat;
	unsigned __int64 tick;
	char km;
	bool irq;
	bool nmi;
	char im;
	int imcd;
	volatile short int vecno;
	short int rvecno;			// registered vector number
	unsigned __int64 cr0;
	clsSystem *system1;

	void Reset();
	void BuildConstant();
	void Step();
	int fnRp(__int64 ir);
	__int64 DecompressInstruction(__int64 ir);
};
