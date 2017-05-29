/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	asm6502.cpp
		Handles 6502 opcodes
=============================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "Assembler.h"
#include "operands6502.h"
#include "asm6502.h"


namespace RTFClasses
{
	void Asm6502::imm(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
	/*
		if (((Operands6502 *)getCpu()->op)->op[0].text()[1]=='<')
			data = expeval(&theAssembler.gOperand[0][2], NULL).value;
		else if (((Operands6502 *)getCpu()->op)->op[0].text()[1]=='>')
			data = expeval(&theAssembler.gOperand[0][2], NULL).value >> 8;
		else
			data = expeval(&theAssembler.gOperand[0][1], NULL).value;
	*/
		emit8(op);
		emit8(data & 0xff);
	}


	void Asm6502::zp(Opa *op)
	{
		Operand o;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		emit8(op->oc);
		emit8(d);
	}


	void Asm6502::abs(Opa *o)
	{
		Operand op;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		emit8(o->oc);
		emit16(d);
	}

	void Asm6502::jml_abs(Opa *o)
	{
		U64 d;
		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(o->oc);
		theAssembler.emit24(d);
//		theAssembler.emit32(d);
	}

	//	beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra

	void Asm6502::br(Opa *o)
	{
		long loc;

		emit8(o->oc);
		loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		// it's possible the symbol could have been defined
		// if it was a backwards reference
		if (theAssembler.getPass() > 1)// || val.bDefined)
		{
    		loc -= (theAssembler.getProgramCounter().val + 1);
			if (loc > 127 || loc < -128)
			{
				Err(E_BRANCH, loc);     // Branch out of range.
				loc = 0xffffffff;
			}
    		emit8(loc&0xff);
		}
		// Before the second pass:
		// branch displacment unknown, so just output a placeholder byte
		else
    		emit8(0xff);
	}
}
