/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	asmButterfly.cpp

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
#include "operandsButterfly.h"
#include "asmButterfly.h"

#define RD(x)	((x)<<8)
#define RS(x)	((x)<<4)

/* ---------------------------------------------------------------
	Output a prefix code if needed.
--------------------------------------------------------------- */
void AsmButterfly::prefix(int data)
{
	if (data > 7 || data < -8) {
		if (data > 32767 || data < -32768) {
			emit16(0x9000|((data>>4)&0xfff));
			emit16(data >> 16);
		}
		else
			emit16(0x8000|((data>>4)&0xfff));
	}
}

void AsmButterfly::prefixw(int data)
{
	if (data > 14 || data < -16) {
		if (data > 32767 || data < -32768) {
			emit16(0x9000|((data>>4)&0xfff));
			emit16(data >> 16);
		}
		else
			emit16(0x8000|((data>>4)&0xfff));
	}
}


// generate prefix for unsigned numbers
void AsmButterfly::prefixu(int data)
{
	if (data > 15) {
		if (data > 65535) {
			emit16(0x9000|((data>>4)&0xfff));
			emit16(data >> 16);
		}
		else
			emit16(0x8000|((data>>4)&0xfff));
	}
}

/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::addi(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[2].val.value;

	prefix(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::addi2(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = Rd;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	if (data < -128 || data > 127) {
		prefix(data);
		emit16(op|RD(Rd)|RS(Rs)|(data&15));
	}
	else
		emit16(0x5000|RD(Rd)|(data&0xff));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::ldi(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	if (data < -128 || data > 127) {
		prefix(data);
		emit16(op|RD(Rd)|(data&15));
	}
	else
		emit16(0x5000|RD(Rd)|(data&0xff));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::ldr(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;

    emit16(op|RD(Rd)|RS(Rs));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::subi(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;
	int data = -((OperandsButterfly *)cpu->op)->op[2].val.value;

	prefix(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::subi2(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = Rd;
	int data = -((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefix(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int AsmButterfly::cmpi(Opa *o)
{
	int op = o->oc;
	int Rd = 0;
	int Rs = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = -((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefix(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::ri(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefix(data);
    emit16(op|RD(Rd)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::trap(Opa *o)
{
	int op = o->oc;
	int data = ((OperandsButterfly *)cpu->op)->op[0].val.value;

    emit16(op|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
	Handle unsigned immediates.
		You can't shift a negative number of bits! So an extra
	bit can be gleaned from the opcode by assuming unsigned
	numbers.
--------------------------------------------------------------- */
int AsmButterfly::riu(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefixu(data);
    emit16(op|RD(Rd)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::rr(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;

    emit16(op|RD(Rd)|RS(Rs));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::trs(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;

    emit16(op|RD(Rd)|Rs);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::tsr(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;

    emit16(op|RD(Rd)|Rs);
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::shift(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

    emit16(op|RD(Rd));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::lscAbs(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefix(data);
    emit16(op|RD(Rd)|(data&15));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::lsRind(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;

    emit16(op|RD(Rd)|RS(Rs));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::lscDrind(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefix(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&0xf));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::lswAbs(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefixw(data);
    emit16(op|RD(Rd)|(data&14)|((data>>4)&1));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::lswDrind(Opa *o)
{
	int op = o->oc;
	int Rd = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int Rs = ((OperandsButterfly *)cpu->op)->op[1].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[1].val.value;

	prefixw(data);
    emit16(op|RD(Rd)|RS(Rs)|(data&14)|((data>>4)&1));
	return TRUE;
}


/* ---------------------------------------------------------------
	* Also handles CALL
--------------------------------------------------------------- */
int AsmButterfly::jmpAbs(Opa *o)
{
	int op = o->oc;
	int data = ((OperandsButterfly *)cpu->op)->op[0].val.value;
	__int64 loc;

   	loc = data - (ProgramCounter.val);
   	if (loc >= -128 && loc < 128) {
   		// convert CALL to BSR
   		if ((op&0x0f00)==0x0f00)
   			emit16(0xBF00|(loc & 0xff));
   		// convert JMP to BRA
   		else
   			emit16(0xBE00|(loc & 0xff));
   	}
   	else {
		prefixw(data);
	    emit16(op|(data&15));
    }
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::jmpRind(Opa *o)
{
	int op = o->oc;
	int Rs = ((OperandsButterfly *)cpu->op)->op[0].r1;

    emit16(op|RS(Rs));
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int AsmButterfly::jmpDrind(Opa *o)
{
	int op = o->oc;
	int Rs = ((OperandsButterfly *)cpu->op)->op[0].r1;
	int data = ((OperandsButterfly *)cpu->op)->op[0].val.value;

	prefix(data);
    emit16(op|RS(Rs)|(data&0xf));
	return TRUE;
}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

int AsmButterfly::br(Opa *o)
{
	int op = o->oc;
	__int64 loc;

	loc = ((OperandsButterfly *)cpu->op)->op[0].val.value;
	// it's possible the symbol could have been defined
	// if it was a backwards reference
	if (pass > 1)// || val.bDefined)
	{
    	loc -= (ProgramCounter.val);
		if (loc > 127 || loc < -128)
	    {
		    Err(E_BRANCH, loc);     // Branch out of range.
		    loc = 0xffffffff;
	    }
    	emit16(op|(loc&0xff));
	}
	else
	{
		// branch displacment unknown
    	emit16(op|0xff);
	}
	return TRUE;
}


