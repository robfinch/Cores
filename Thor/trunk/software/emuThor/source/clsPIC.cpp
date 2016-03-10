#include "StdAfx.h"
#include "clsPIC.h"

clsPIC::clsPIC(void)
{
	Reset();
}

void clsPIC::Reset(void)
{
	int nn;

	for (nn = 0; nn < 16; nn++) {
		enables[nn] = false;
		edges[nn] = false;
	}
	irq30Hz = false;
	irq1024Hz = false;
	irqKeyboard = false;
	irqUart = false;
}

unsigned int clsPIC::Read(unsigned int ad) {
	int nn;
	unsigned int dat;
	switch((ad >> 3) & 7) {
	case 0:
		return vecno;
	default:
		dat = 0;
		for (nn = 0; nn < 16; nn++)
			dat |= (enables[nn] << nn);
		return dat;
	}
}

void clsPIC::Write(unsigned int ad, unsigned int dat, unsigned int mask) {
	int nn;
	switch((ad >> 3) & 7) {
	case 1:
		for (nn = 0; nn < 16; nn++)
			enables[nn] = (dat & (1 << nn)) != 0;
		break;
	case 2:
		enables[dat & 15] = false;
		break;
	case 3:
		enables[dat & 15] = true;
		break;
	case 4:
		for (nn = 0; nn < 16; nn++)
			edges[nn] = (dat & (1 << nn)) != 0;
		break;
	case 5:
		if (dat==1)
			irq1024Hz = false;
		if (dat==2)
			irq30Hz = false;
		if (dat==7)
			irqUart = false;
		if (dat==3)
			irqKeyboard = false;
		break;
	}
}

void clsPIC::Step(void) {
	vecno = 192;
	irq = system1.cpu2.irq = false;
	if (enables[7] & irqUart) {
		irq = system1.cpu2.irq = true;
		vecno = 192+7;
	}
	if (enables[3] & irqKeyboard) {
		irq = system1.cpu2.irq = true;
		vecno = 192+3;
	}
	if (enables[2] & irq30Hz) {
		irq = system1.cpu2.irq = true;
		vecno = 192+2;
	}
	if (enables[1] & irq1024Hz) {
		irq = system1.cpu2.irq = true;
		vecno = 192+1;
	}
	system1.cpu2.vecno = vecno;
}


