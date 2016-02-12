#pragma once
#include "clsSystem.h"

class clsCPU
{
public:
	bool irq;
	unsigned __int16 vecno;
	unsigned __int64 pcs[40];
	clsSystem *system1;
public:
	virtual void Reset() {};
	virtual void Step() {};
};
