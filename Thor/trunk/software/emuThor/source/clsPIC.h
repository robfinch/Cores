#pragma once
#include "stdafx.h"
// Programmable Interrupt Controller Emulator
//
// This class emulates some of the functionality of the interrupt
// controller. Edge sensing on the interrupt inputs is not currently
// supported. The edge sensing on the clock interrupts is emulated
// by resetting the interrupt input when the PIC recieves the
// command to acknowledge the edge sensitive interrupt and only
// driving the interrupt signal true by the timer. The timers
// effectively act like pulse generators which provide only a
// positive transition to the clock signal. The negative 
// transition is supplied when the interrupt is acknowledged.
// In the real system the clock generator provides a square wave
// output for the interrupts so edge sensing is necessary.
// It's faked out so that from the perspective of the BIOS
// software it looks the same.

extern clsSystem system1;

class clsPIC : public clsDevice
{
public:
	bool enables[16];
	bool edges[16];		// edge sensitive
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

