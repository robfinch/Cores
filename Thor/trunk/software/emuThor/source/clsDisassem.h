#pragma once
#include "stdafx.h"

class clsDisassem
{
	bool imm_prefix;
	unsigned __int64 imm;
	std::string PredCond(int cnd);
	std::string SprName(int rg);
	std::string dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp);
	unsigned __int64 ReadByte(int ad) { return system1.ReadByte(ad); };
public:
	std::string Disassem(int ad, int *nb);
};
