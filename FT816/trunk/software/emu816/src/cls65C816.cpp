#include "StdAfx.h"
#include "cls65C816.h"

extern clsSystem sys65c816;

cls65C816::cls65C816(void)
{
}


cls65C816::~cls65C816(void)
{
}

void cls65C816::Reset(void)
{
	e_bit = true;
	df = false;
	im = true;
	sp = 0x1FF;
	pb = 0;
	pc = sys65c816.Read16(0xFFFC);
}

void cls65C816::Step(void)
{
	bool tf;

	ir = sys65c816.Read((pb << 16) | pc);
	pc = pc + 1;
	switch(ir) {
	case NOP:	break;
	case CLC:	cf = false; break;
	case CLV:	vf = false; break;
	case CLD:	df = false; break;
	case SEC:	cf = true; break;
	case SEI:	im = true; break;
	case SED:	df = true; break;
	case XCE:	tf = cf; cf <= e_bit; e_bit = tf; break;
	case BEQ:
		disp8 = sys65c816.Read(pc);
		pc = pc + 1;
		if (disp8==0xff && longBranches) {
			disp16 = sys65c816.Read16(pc);
			pc = pc + 2;
		}
		if (zf) {
			if (disp8==0xFF && longBranches)
				pc = pc + disp16;
			else
				pc = pc + disp8;
		}
		break;
	case BNE:
		disp8 = sys65c816.Read(pc);
		pc = pc + 1;
		if (disp8==0xff && longBranches) {
			disp16 = sys65c816.Read16(pc);
			pc = pc + 2;
		}
		if (!zf) {
			if (disp8==0xFF && longBranches)
				pc = pc + disp16;
			else
				pc = pc + disp8;
		}
		break;
	case BPL:
		disp8 = sys65c816.Read(pc);
		pc = pc + 1;
		if (disp8==0xff && longBranches) {
			disp16 = sys65c816.Read16(pc);
			pc = pc + 2;
		}
		if (!nf) {
			if (disp8==0xFF && longBranches)
				pc = pc + disp16;
			else
				pc = pc + disp8;
		}
		break;
	case BMI:
		disp8 = sys65c816.Read(pc);
		pc = pc + 1;
		if (disp8==0xff && longBranches) {
			disp16 = sys65c816.Read16(pc);
			pc = pc + 2;
		}
		if (nf) {
			if (disp8==0xFF && longBranches)
				pc = pc + disp16;
			else
				pc = pc + disp8;
		}
		break;
	case BRA:
		disp8 = sys65c816.Read(pc);
		pc = pc + 1;
		if (disp8==0xff && longBranches) {
			disp16 = sys65c816.Read16(pc);
			pc = pc + 2;
		}
		if (disp8==0xFF && longBranches)
			pc = pc + disp16;
		else
			pc = pc + disp8;
		break;
	case JMP:
		pc = sys65c816.Read16(pc);
		break;
	case JML:
		pc = sys65c816.Read16(pc);
		pb = sys65c816.Read(pc+2);
		break;
	case RTS:
		pc = Pop1();
		pc = (Pop1() << 8) + pc;
		pc = pc + 1;
		break;
	case DEY:
		if (e_bit) {
			yreg = (yreg - 1) & 0xFF;
			nf = (yreg & 0x80) >> 7;
			zf = (yreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				yreg = (yreg - 1) & 0xFF;
				nf = (yreg & 0x80) >> 7;
				zf = (yreg & 0xFF) == 0;
			}
			else {
				yreg = yreg - 1;
				nf = (yreg & 0x8000) >> 15;
				zf = (yreg & 0xFFFF) == 0;
			}
		}
		break;
	case INX:
		if (e_bit) {
			xreg = (xreg + 1) & 0xFF;
			nf = (xreg & 0x80) >> 7;
			zf = (xreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				xreg = (xreg + 1) & 0xFF;
				nf = (xreg & 0x80) >> 7;
				zf = (xreg & 0xFF) == 0;
			}
			else {
				xreg = xreg + 1;
				nf = (xreg & 0x8000) >> 15;
				zf = (xreg & 0xFFFF) == 0;
			}
		}
		break;
	case INY:
		if (e_bit) {
			yreg = (yreg + 1) & 0xFF;
			nf = (yreg & 0x80) >> 7;
			zf = (yreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				yreg = (yreg + 1) & 0xFF;
				nf = (yreg & 0x80) >> 7;
				zf = (yreg & 0xFF) == 0;
			}
			else {
				yreg = yreg + 1;
				nf = (yreg & 0x8000) >> 15;
				zf = (yreg & 0xFFFF) == 0;
			}
		}
		break;
	case TYA:
		if (e_bit) {
			areg = (yreg & 0xff) | (areg & 0xff00);
			nf = (areg & 0x80) >> 7;
			zf = (areg & 0xFF) == 0;
		}
		else {
			if (m_bit) {
				areg = (yreg & 0xff) | (areg & 0xff00);
				nf = (areg & 0x80) >> 7;
				zf = (areg & 0xFF) == 0;
			}
			else {
				areg = yreg;
				nf = (areg & 0x8000) >> 15;
				zf = (areg & 0xFFFF) == 0;
			}
		}
		break;
	case TAY:
		if (e_bit) {
			yreg = areg & 0xff;
			nf = (yreg & 0x80) >> 7;
			zf = (yreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				yreg = areg & 0xff;
				nf = (yreg & 0x80) >> 7;
				zf = (yreg & 0xFF) == 0;
			}
			else {
				yreg = areg;
				nf = (yreg & 0x8000) >> 15;
				zf = (yreg & 0xFFFF) == 0;
			}
		}
		break;
	case PLA:
		if (e_bit) {
			areg = (areg & 0xFF00) | Pop1();
			nf = (areg & 0x80) >> 7;
			zf = (areg & 0xFF) == 0;
		}
		else {
			if (m_bit) {
				areg = (areg & 0xFF00) | Pop1();
				nf = (areg & 0x80) >> 7;
				zf = (areg & 0xFF) == 0;
			}
			else {
				areg = Pop1() | (Pop1() << 8);
				nf = (areg & 0x8000) >> 15;
				zf = (areg & 0xFFFF) == 0;
			}
		}
		break;
	case PLX:
		if (e_bit) {
			xreg = Pop1();
			nf = (xreg & 0x80) >> 7;
			zf = (xreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				xreg = Pop1();
				nf = (xreg & 0x80) >> 7;
				zf = (xreg & 0xFF) == 0;
			}
			else {
				xreg = Pop1() | (Pop1() << 8);
				nf = (xreg & 0x8000) >> 15;
				zf = (xreg & 0xFFFF) == 0;
			}
		}
		break;
	case PLY:
		if (e_bit) {
			yreg = Pop1();
			nf = (yreg & 0x80) >> 7;
			zf = (yreg & 0xFF) == 0;
		}
		else {
			if (x_bit) {
				yreg = Pop1();
				nf = (yreg & 0x80) >> 7;
				zf = (yreg & 0xFF) == 0;
			}
			else {
				yreg = Pop1() | (Pop1() << 8);
				nf = (yreg & 0x8000) >> 15;
				zf = (yreg & 0xFFFF) == 0;
			}
		}
		break;
	case PLB:
		db = Pop1();
		break;
	}
}

unsigned __int8 cls65C816::Pop1()
{
	sp = sp + 1;
	if (e_bit) {
		sp &= 0xff;
		sp |= 0x100;
	}
	return sys65c816.Read(sp);
}
