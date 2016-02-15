#pragma once
#include "clsCPU.h"

extern class clsSystem system1;

class clsThor : public clsCPU
{
	bool StatusHWI;
	bool StatusDBG;
	__int16 StatusEXL;
	__int64 string_pc;
	unsigned __int64 imm;
	bool imm_prefix;
	unsigned __int64 ea;
	unsigned int mode : 2;

	void SetGP(int rg, __int64 val);
	int GetMode();
	void SetSpr(int Sprn, __int64 val);
	__int64 GetSpr(int Sprn);
	void dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp);
	void ndx(int b1, int b2, int b3, int *Ra, int *Rb, int *Rt, int *Sg, int *Sc);
	int WriteMask(int ad, int sz);
	unsigned __int64 ReadByte(int ad);
	unsigned __int64 ReadChar(int ad);
	unsigned __int64 ReadHalf(int ad);
	unsigned __int64 Read(int ad);
public:
	unsigned __int32 pc;
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
	bool im;
	int imcd;
	int pred;
	__int64 GetGP(int rg);
	bool IsKM();
	void Reset();
	void Step();
private:
	inline bool IRQActive() { return !StatusHWI && irq && !im; };
	int GetBit(__int64 a, int b);
	void SetBit(__int64 *a, int b);
	void ClearBit(__int64 *a, int b);
};

