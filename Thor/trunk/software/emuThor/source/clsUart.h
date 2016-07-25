#pragma once

#include "clsDevice.h"

class clsUart : public clsDevice
{
public:
	unsigned __int8 tb;
	unsigned __int8 rb;
	unsigned __int8 is;
	unsigned __int8 ier;
	unsigned __int8 ls;
	unsigned __int8 ms;
	unsigned __int8 mc;
	unsigned __int8 ctrl;
	unsigned __int8 cm0,cm1,cm2,cm3;
	unsigned __int8 ff;
	unsigned __int8 fc;
	bool irq;
public:
	void Reset();
	bool IsSelected(unsigned int ad);
	unsigned int Read(unsigned int ad);
	int Write(unsigned int ad, unsigned int dat, unsigned int mask=1);
	void RxPort(unsigned int dat);
	int TxPort();
	void Step(void) {};
};
