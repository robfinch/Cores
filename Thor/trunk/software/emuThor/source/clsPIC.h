#pragma once
#include "stdafx.h"

extern clsSystem system1;

class clsPIC : public clsDevice
{
public:
	bool enables[16];
	bool irq30Hz;
	bool irq1024Hz;
	bool irqKeyboard;
	bool irqUart;
	bool irq;
	bool nmi;
	unsigned int vecno;
	clsPIC(void);
	void Reset();
	bool IsSelected(unsigned int ad) {
		return ((ad & 0xFFFFFFC0)==0xFFDC0FC0);
	};
	unsigned int Read(unsigned int ad);
	void Write(unsigned int ad, unsigned int dat, unsigned int mask);
	void Step(void);
};

