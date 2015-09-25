#pragma once
#include "clsDevice.h"
#include "clsCPU.h"

extern clsCPU cpu1;

class clsPIC : public clsDevice
{
	bool enables[16];
public:
	bool irq30Hz;
	bool irq1024Hz;
	bool irqKeyboard;
	unsigned int vecno;
	clsPIC(void);
	void Reset();
	bool IsSelected(unsigned int ad) {
		return ((ad & 0xFFFFFFC0)==0xFFDC0FC0);
	};
	unsigned int Read(unsigned int ad) {
		int nn;
		unsigned int dat;
		switch((ad >> 2) & 15) {
		case 0:
			return vecno;
		default:
			dat = 0;
			for (nn = 0; nn < 16; nn++)
				dat |= (enables[nn] << nn);
			return dat;
		}
	};
	void Write(unsigned int ad, unsigned int dat, unsigned int mask) {
		int nn;
		switch((ad >> 2) & 15) {
		case 1:
			for (nn = 0; nn < 16; nn++)
				enables[nn] = dat & (1 << nn);
			break;
		case 2:
			enables[dat & 15] = false;
			break;
		case 3:
			enables[dat & 15] = true;
			break;
		case 5:
			if (dat==2)
				irq1024Hz = false;
			if (dat==3)
				irq30Hz = false;
			if (dat==15)
				irqKeyboard = false;
			break;
		}
	};
	void Step(void) {
		vecno = 448;
		cpu1.irq = false;
		if (enables[15] & irqKeyboard) {
			cpu1.irq = true;
			vecno = 448+15;
		}
		if (enables[3] & irq30Hz) {
			cpu1.irq = true;
			vecno = 448+3;
		}
		if (enables[2] & irq1024Hz) {
			cpu1.irq = true;
			vecno = 448+2;
		}
		cpu1.vecno = vecno;
	};
};

