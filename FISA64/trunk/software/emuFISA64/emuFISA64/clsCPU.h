#include "Instructions.h"

#pragma once

class clsSystem;

// Currently unaligned memory access is not supported.
// Made more complicated by the fact it's a 64 bit machine.

class clsCPU
{
public:
	char isRunning;
	char brk;
	unsigned int ir, xir, wir;
	int sir;
	unsigned __int64 regs[32];
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
	unsigned __int64 ubound[64];
	unsigned __int64 lbound[64];
	unsigned __int64 mmask[64];
	char km;
	bool irq;
	bool nmi;
	char im;
	bool StatusHWI;
	volatile short int vecno;
	unsigned __int64 cr0;
	int Ra,Rb,Rc;
	int Rt;
	int mb,me;
	int spr;
	int Bn;
	unsigned int imm1;
	unsigned int imm2;
	char hasPrefix;
	int immcnt;
	unsigned int opcode;
	int i1;
	__int64 a, b, res, imm, sp_res;
	unsigned __int64 ua, ub;
	int nn;
	int bmask;
	int r1,r2,r3;
	clsSystem *system1;

	void Reset();
	void BuildConstant();
	void Step();
};
