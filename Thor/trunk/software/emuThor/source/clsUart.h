#pragma once

#include "clsDevice.h"

class clsUart : public clsDevice
{
public:
	__int8 tb;
	__int8 rb;
	__int8 is;
	__int8 ier;
	__int8 ls;
	__int8 ms;
	__int8 mc;
	__int8 ctrl;
	__int8 cm0,cm1,cm2,cm3;
	__int8 ff;
	__int8 fc;
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
