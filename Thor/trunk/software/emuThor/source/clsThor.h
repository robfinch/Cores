#pragma once
#include "clsCPU.h"

extern clsSystem system1;

class clsThor : public clsCPU
{
public:
	__int64 pc;
	__int64 gp[64];		// general purpose registers
	__int64 ca[16];		// code address registers
	__int8 pr[16];		// predicate registers
	__int64 seg_base[8];
	__int64 seg_limit[8];
	__int64 lc;
	__int64 tick;
	__int8 bir;
	__int64 dbad0,dbad1,dbad2,dbad3;
	__int64 dbctrl,dbstat;
	unsigned __int64 imm;
	bool imm_prefix;
	unsigned __int64 ea;
	bool im;
	int imcd;
	int pred;
	void Reset();
	void Step();
	unsigned __int64 ReadByte(int ad) { return system1->ReadByte(ad); };
	void dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp);
};

