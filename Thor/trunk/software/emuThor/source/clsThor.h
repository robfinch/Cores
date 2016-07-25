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
	unsigned __int64 la;
	unsigned int mode : 2;

	void SetGP(int rg, __int64 val);
	int GetMode();
	void SetSpr(int Sprn, __int64 val, bool setex = true);
	__int64 GetSpr(int Sprn);
	void dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp, unsigned __int64 *la);
	void ndx(int b1, int b2, int b3, int *Ra, int *Rb, int *Rt, int *Sg, int *Sc, unsigned __int64 *la);
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
	__int64 LDT;
	__int64 GDT;
	__int16 CPL;
	bool seglex;		// segment load exception
	__int8 segsw;
	__int32 seg[64];		// selector
	__int64 seg_base[64];
	__int64 seg_limit[64];
	__int16 seg_acr[64];
	__int64 lc;
	__int64 tick;
	__int8 bir;
	__int64 dbad0,dbad1,dbad2,dbad3;
	__int64 dbctrl,dbstat;
	bool _32bit;
	int segmodel;
	bool im;
	int imcd;
	int pred;
	bool rts;			// Indicator for step out.
	__int64 GetGP(int rg);
	bool IsKM();
	void Reset();
	void Step();
	clsThor() { _32bit = true; segmodel = 2; };
private:
	inline bool IRQActive() { return !StatusHWI && irq && !im && imcd==0; };
	int GetBit(__int64 a, int b);
	void SetBit(__int64 *a, int b);
	void ClearBit(__int64 *a, int b);
};

