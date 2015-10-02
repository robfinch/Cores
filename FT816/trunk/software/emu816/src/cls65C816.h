#pragma once
class cls65C816
{
	// Core config
	bool longBranches;

	bool nf,vf,cf,zf;
	bool df;
	bool bf;
	bool im;			// interrupt mask
	bool e_bit;			// emulation mode bit
	bool x_bit;
	bool m_bit;
	__int16 areg;
	__int16 xreg;
	__int16 yreg;
	unsigned __int16 sp;
	unsigned __int16 dpr;
	unsigned __int8 db;
	unsigned __int32 adr;
	unsigned __int8 ir;
	__int8 dat;
	unsigned __int8 Pop1(void);
	__int8 disp8;
	__int16 disp16;
public:
	unsigned __int16 pc;
	unsigned __int8 pb;
	cls65C816(void);
	~cls65C816(void);
	void Reset(void);
	void Step(void);
};

