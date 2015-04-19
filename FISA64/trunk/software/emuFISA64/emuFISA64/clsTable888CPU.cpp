#include "StdAfx.h"
#include "clsTable888CPU.h"


clsTable888CPU::clsTable888CPU(void)
{
}

void clsTable888CPU::Step(void)
{
	unsigned int ad;
	int nn;
	int sc;
	tick = tick + 1;
	unsigned _int64 ir1,ir2;
	//---------------------------------------------------------------------------
	// Instruction Fetch stage
	//---------------------------------------------------------------------------
	wir = xir;
	xir = ir;
	if (nmi & !StatusHWI)
		sir = ir = 0x38 + (0x1E << 7) + (510 << 17) + 0x80000000L;
	else if (irq & ~im & !StatusHWI)
		sir = ir = 0x38 + (0x1E << 7) + (vecno << 17) + 0x80000000L;
	else {
		ir3 = system1->Read((pc&-16)+8);
		ir4 = system1->Read((pc&-16)+12);
		switch(pc & 15)) {
		case 0:
			ir1 = system1->Read((pc&-16));
			ir2 = system1->Read((pc&-16)+4);
			ir = ir1 | ((ir2 & 0xff) << 32);
			break;
		case 5:
			ir1 = system1->Read((pc&-16)+4);
			ir2 = system1->Read((pc&-16)+8);
			ir = (ir1 >> 8) | ((ir2 & 0xffff) << 24);
			break;
		case 10:
			ir1 = system1->Read((pc&-16)+8);
			ir2 = system1->Read((pc&-16)+12);
			ir = (ir1 >> 16) | ((ir2 & 0xFFFFFF) << 16);
			break;
		}
	}
	for (nn = 39; nn >= 0; nn--)
		pcs[nn] = pcs[nn-1];
	pcs[0] = pc;
	//---------------------------------------------------------------------------
	// Decode stage
	//---------------------------------------------------------------------------
	opcode = ir & 0xFF;
	Ra = (ir >> 8) & 0x1f;
	if (opcode==RR) {
		Rb = (ir >> 16) & 0x1F;
		Rt = (ir >> 24) & 0xFF;
	}
	else {
		Rt = (ir >> 16) & 0xFF;
	}
	Rc = (ir >> 12) & 0x1f;
	spr = (ir >> 17) & 0xff;
	sc = (ir >> 22) & 3;
	mb = (ir >> 17) & 0x3f;
	me = (ir >> 23) & 0x3f;

	a = regs[Ra];
	b = regs[Rb];
	c = regs[Rc];
	ua = a;
	ub = b;
	res = 0;
}
