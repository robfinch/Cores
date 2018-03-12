/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	aW65C816S.c

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
		Handles W65C816S opcodes

=============================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "asm24.h"


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int aW65C816Simm(Opa *o)
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
	if (mf)
		emit8((data >> 8) & 0xff);
	return TRUE;
}


int aW65C816Simmxy(Opa *o)
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
	if (xf)
		emit8((data >> 8) & 0xff);
	return TRUE;
}


int aW65C816Sxf (SOpa *o)
{
	SValue val;
	val = expeval(gOperand[0], NULL);
	xf = val.value;
}


int aW65C816Smf (SOpa *o)
{
	SValue val;
	val = expeval(gOperand[0], NULL);
	mf = val.value;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a65C816Sabs(Opa *o)
{
	COperand op;
	__int32 d;

	op.parse(gOperand[0]);
	d = op.val.value;
    emit8(o->oc);
    emit16(d);
	return TRUE;
}


