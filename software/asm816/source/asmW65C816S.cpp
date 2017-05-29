/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	asmW65C816S.cpp

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
		Handles 6502 opcodes

=============================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "Assembler.h"
#include "operands6502.h"
#include "asmW65C816S.h"

namespace RTFClasses
{
// Need place to hold static vars
int AsmW65C816S::mem;
int AsmW65C816S::ndx;
}

namespace RTFClasses
{
	void AsmW65C816S::amem(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		mem = data;
	}

	void AsmW65C816S::andx(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		ndx = data;
	}

	void AsmW65C816S::imm(Opa *o)
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
		theAssembler.emit8(op);
		theAssembler.emit8(data);
	}


	void AsmW65C816S::pea(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		theAssembler.emit16(data);
	}


	void AsmW65C816S::per(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
   		loc -= (theAssembler.getProgramCounter().val + 2);
		theAssembler.emit16(loc);
	}


	void AsmW65C816S::sr(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		theAssembler.emit8(loc);
	}


	// assemble 8 or 16 bit data based on index flag setting
	void AsmW65C816S::immx(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		if (isX16())
			theAssembler.emit16(data);
		else
			theAssembler.emit8(data);
	}


	// assemble 8 or 16 bit data based on memory flag setting
	void AsmW65C816S::immm(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		if (isM16())
			theAssembler.emit16(data);
		else
			theAssembler.emit8(data);
	}


	void AsmW65C816S::zp(Opa *op)
	{
		Operand o;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(op->oc);
		theAssembler.emit8(d);
	}


	void AsmW65C816S::mv(Opa *op)
	{
		Operand o;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(op->oc);
		theAssembler.emit8(d);
		d = ((Operands6502 *)getCpu()->getOp())->op[1].val.value;
		theAssembler.emit8(d);
	}


	void AsmW65C816S::abs(Opa *o)
	{
		Operand op;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
	}


	void AsmW65C816S::labs(Opa *o)
	{
		Operand op;
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
		theAssembler.emit8(d>>16);
	}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

void AsmW65C816S::br(Opa *o)
{
	long loc;

    theAssembler.emit8(o->oc);
	loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
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
    	theAssembler.emit8(loc);
	}
	else
	{
		// branch displacment unknown
    	theAssembler.emit8(0xff);
	}
}

void AsmW65C816S::lbr(Opa *o)
{
	long loc;

    theAssembler.emit8(o->oc);
    theAssembler.emit8(0xff);
	loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
	// it's possible the symbol could have been defined
	// if it was a backwards reference
	if (theAssembler.getPass() > 1)// || val.bDefined)
	{
    	loc -= (theAssembler.getProgramCounter().val + 2);
		if (loc > 32767 || loc < -32768)
	    {
	       Err(E_BRANCH, loc);     // Branch out of range.
	       loc = 0xffffffff;
	    }
    	theAssembler.emit8(loc & 0xFF);
    	theAssembler.emit8((loc>>8) & 0xFF);
	}
	else
	{
		// branch displacment unknown
    	theAssembler.emit8(0xff);
    	theAssembler.emit8(0xff);
	}
}


	void AsmW65C816S::brl(Opa *o)
	{
		long loc;

		theAssembler.emit8(o->oc);
		loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
		// it's possible the symbol could have been defined
		// if it was a backwards reference
		if (theAssembler.getPass() > 1)// || val.bDefined)
		{
    		loc -= (theAssembler.getProgramCounter().val + 2);
			if (loc > 32767 || loc < -32768)
			{
				Err(E_BRANCH, loc);     // Branch out of range.
				loc = 0xffffffff;
			}
    		theAssembler.emit16(loc);
		}
		else
		{
			// branch displacment unknown
    		theAssembler.emit16(0xffff);
		}
	}
}
