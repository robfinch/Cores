#pragma once
#include "stdafx.h"

class clsDisassem
{
	bool imm_prefix;
	unsigned __int64 imm;
	int DefaultSeg(int rg);
	std::string SegName(int sg);
	std::string PredCond(int cnd);
	std::string SprName(int rg);
	std::string TLBRegName(int rg);
	std::string dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp);
	std::string ndx(int b1, int b2, int b3, int *Ra, int *Rb, int *Rt, int *Sg, int *Sc);
	std::string mem(std::string mne, int ad, int *nb);
	std::string memndx(std::string mne, int ad, int *nb);
	__int64 GetSpr(int Sprn);
	unsigned __int64 ReadByte(int ad) { return system1.ReadByte(ad); };
public:
	std::string Disassem(int ad, int *nb);
};
