#include "stdafx.h"

MachineReg regs[3072];

bool MachineReg::IsCalleeSave(int regno)
{
	if ((regno & 0x3ff) >= regFirstTemp && (regno & 0x3ff) <= regLastTemp)
		return (true);
	if (regno == regSP || regno == regFP)
		return (true);
	if (regno == regTP)
		return (true);
	return(false);
}

bool MachineReg::IsPositReg()
{
	return (number >= 2048 && number <= 3071);
}

bool MachineReg::IsFloatReg()
{
	return (number >= 1024 && number <= 2047);
}

bool MachineReg::IsArgReg()
{
	return ((number & 0x3ff) >= regFirstArg && (number & 0x3ff) <= regLastArg);
};

void MachineReg::MarkColorable()
{
	int nn;

	for (nn = 0; nn < 3072; nn++) {
		regs[nn].IsColorable = true;
		if ((nn & 0x3ff) >= regFirstArg && (nn & 0x3ff) <= regLastArg)
			regs[nn].IsColorable = false;
	}
	regs[0].IsColorable = false;
	regs[1].IsColorable = false;
	regs[2].IsColorable = false;
	regs[regXoffs].IsColorable = false;
	regs[regAsm].IsColorable = false;
	regs[regLR].IsColorable = false;
	regs[regXLR].IsColorable = false;
	regs[regGP1].IsColorable = false;
	regs[regGP].IsColorable = false;
	regs[regFP].IsColorable = false;
	regs[regSP].IsColorable = false;
}

bool MachineReg::ContainsPositConst() {
	if (offset == nullptr)
		return (false);
	return (offset->tp->IsPositType());
};
