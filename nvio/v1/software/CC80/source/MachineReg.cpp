#include "stdafx.h"

MachineReg regs[1024];

bool MachineReg::IsCalleeSave(int regno)
{
	if (regno >= regFirstTemp && regno <= regLastTemp)
		return (true);
	if (regno == regSP || regno == regFP)
		return (true);
	if (regno == regTP)
		return (true);
	return(false);
}

bool MachineReg::IsArgReg()
{
	return (number >= regFirstArg && number <= regLastArg);
};

void MachineReg::MarkColorable()
{
	int nn;

	for (nn = 0; nn < 1024; nn++) {
		regs[nn].IsColorable = true;
		if (nn >= regFirstArg && nn <= regLastArg)
			regs[nn].IsColorable = false;
	}
	regs[0].IsColorable = false;
	regs[1].IsColorable = false;
	regs[2].IsColorable = false;
	regs[regXoffs].IsColorable = false;
	regs[regAsm].IsColorable = false;
	regs[regLR].IsColorable = false;
	regs[regXLR].IsColorable = false;
	regs[regFP].IsColorable = false;
	regs[regSP].IsColorable = false;
}
