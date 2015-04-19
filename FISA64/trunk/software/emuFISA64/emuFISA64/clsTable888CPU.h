#pragma once
#include "Table888Instructions.h"

class clsTable888CPU
{
	int Ra,Rb,Rc;
	int Rt;
	int mb,me;
	int spr;
	__int64 sir;
	__int64 a, b, c, res, imm, sp_res;
	unsigned __int64 ua, ub;
public:
	bool nmi, irq;
	bool im;
	unsigned __int64 ir, xir, wir;
	unsigned __int64 regs[256];
	unsigned int pc;
	unsigned int pcs[40];
	clsTable888CPU(void);
	void Reset();
	void Step();
};

