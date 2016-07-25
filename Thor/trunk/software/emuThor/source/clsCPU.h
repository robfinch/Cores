#pragma once

extern class clsSystem;

class clsCPU
{
public:
	bool irq;
	unsigned __int16 vecno;
	unsigned __int64 pcs[1024];
	unsigned int pcsndx;
	clsSystem *system1;
public:
	bool isRunning;
	unsigned int sub_depth;
	virtual void Reset() {};
	virtual void Step() {};
};
