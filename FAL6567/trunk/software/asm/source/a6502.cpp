/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	a6502.c

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
#include "asm24.h"
#include "operands6502.h"


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int a6502imm(Opa *o)
{
	int op = o->oc;
	int data = ((Operands6502 *)cpu->op)->op[0].val.value;
/*
    if (((Operands6502 *)cpu->op)->op[0].text()[1]=='<')
        data = expeval(&gOperand[0][2], NULL).value;
    else if (((Operands6502 *)cpu->op)->op[0].text()[1]=='>')
        data = expeval(&gOperand[0][2], NULL).value >> 8;
    else
        data = expeval(&gOperand[0][1], NULL).value;
*/
    emit8(op);
    emit8(data & 0xff);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a6502zp(Opa *op)
{
	Operand o;
	__int32 d;

	d = ((Operands6502 *)cpu->op)->op[0].val.value;
    emit8(op->oc);
    emit8(d);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a6502abs(Opa *o)
{
	Operand op;
	__int32 d;

	d = ((Operands6502 *)cpu->op)->op[0].val.value;
    emit8(o->oc);
    emit16(d);
	return TRUE;
}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

int a6502br(Opa *o)
{
	long loc;

    emit8(o->oc);
	loc = ((Operands6502 *)cpu->op)->op[0].val.value; //expeval(gOperand[0], NULL);
	// it's possible the symbol could have been defined
	// if it was a backwards reference
	if (pass > 1)// || val.bDefined)
	{
    	loc -= (ProgramCounter.val + 1);
		if (loc > 127 || loc < -128)
	    {
		    err(NULL, E_BRANCH, loc);     // Branch out of range.
		    loc = 0xffffffff;
	    }
    	emit8(loc&0xff);
	}
	else
	{
		// branch displacment unknown
    	emit8(0xff);
	}
	return TRUE;
}


