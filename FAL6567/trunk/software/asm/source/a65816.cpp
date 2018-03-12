/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	a65816.cpp

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
		Handles 6502 opcodes

=============================================================== */

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "asm24.h"


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int a65816imm(Opa *o)
{
	int op = o->oc;
	int data;

    if (gOperand[0][1]=='<')
        data = expeval(&gOperand[0][2], NULL).value;
    else if (gOperand[0][1]=='>')
        data = expeval(&gOperand[0][2], NULL).value >> 8;
    else
        data = expeval(&gOperand[0][1], NULL).value;
    emit8(op);
    emit8(data & 0xff);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a65816zp(Opa *op)
{
	COperand o;
	__int32 d;

	o.parse(gOperand[0]);
	d = o.val.value;
    emit8(op->oc);
    emit8(d);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a65816abs(Opa *o)
{
	COperand op;
	__int32 d;

	op.parse(gOperand[0]);
	d = op.val.value;
    emit8(o->oc);
    emit16(d);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a65816absl(Opa *o)
{
	COperand op;
	__int32 d;

	op.parse(gOperand[0]);
	d = op.val.value;
    emit8(o->oc);
    emit24(d);
	return TRUE;
}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

int a65816br(Opa *o)
{
	long loc;
	SValue val;

	if (bGen)
		loc = 1234;
    emit8(o->oc);
	if (strcmp(gOperand[0],"LAB_2DAA")==0)
		loc = 1234;
	val = expeval(gOperand[0], NULL);
	loc = val.value;
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


