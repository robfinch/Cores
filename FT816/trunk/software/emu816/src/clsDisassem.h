#pragma once
#include "instructions.h"

class clsDisassem
{
	int bytesUsed;
	std::string branch(std::string, __int32);
public:
	bool e_bit;
	bool m_bit;
	bool x_bit;
	clsDisassem(void);
	std::string disassemMnes(__int32 ad);
	std::string disassem(__int32 ad);
	std::string disassem20(__int32 ad);
};

