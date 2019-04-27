#include "stdafx.h"

bool MachineReg::IsArgReg()
{
	return (number >= regFirstArg && number <= regLastArg);
};
