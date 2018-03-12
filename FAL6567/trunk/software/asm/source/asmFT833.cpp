/* ===============================================================
	(C) 2017 Finitron
	All rights reserved.

	asmFT833.cpp

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
#include "asmFT833.h"

namespace RTFClasses
{
// Need place to hold static vars
int AsmFT833::mem;
int AsmFT833::ndx;
}

namespace RTFClasses
{
	void AsmFT833::amem(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		mem = data;
	}

	void AsmFT833::andx(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		ndx = data;
	}

	void AsmFT833::imm(Opa *o)
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
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(data);
	}

	void AsmFT833::imm16(Opa *o)
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
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit16(data);
	}

	void AsmFT833::epimm(Opa *o)
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
        if (data > 255) {
            theAssembler.emit8(0x42);
            theAssembler.emit8(op&255);
            theAssembler.emit16(data);
        }
        else {
        	theAssembler.emit8(op);
            theAssembler.emit8(data);
        }
    }

	void AsmFT833::pea(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit16(data);
	}


	void AsmFT833::per(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
   		loc -= (theAssembler.getProgramCounter().val + 2);
		theAssembler.emit16(loc);
	}


	void AsmFT833::sr(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

        doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(loc);
	}


	// assemble 8 or 16 bit data based on index flag setting
	void AsmFT833::immx(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		if (isX32())
			theAssembler.emit32(data);
		else if (isX16())
			theAssembler.emit16(data);
		else
			theAssembler.emit8(data);
	}


	// assemble 8 or 16 bit data based on memory flag setting
	void AsmFT833::immm(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
		if (isM32())
			theAssembler.emit32(data);
		else if (isM16())
			theAssembler.emit16(data);
		else
			theAssembler.emit8(data);
	}


	void AsmFT833::zp(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
        doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(d);
	}


	void AsmFT833::mv(Opa *op)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(op->oc);
		theAssembler.emit8(d);
		d = ((Operands6502 *)getCpu()->getOp())->op[1].val.value;
		theAssembler.emit8(d);
	}


	void AsmFT833::fill(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(d);
	}


	void AsmFT833::abs(Opa *o)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
        doSizePrefix();
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
	}


	void AsmFT833::labs(Opa *o)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
    doSizePrefix();
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
		theAssembler.emit8(d>>16);
	}

    void AsmFT833::doSizePrefix(void)
    {
         if (theAssembler.gSzChar=='B')
             theAssembler.emit16(0x8B42);
         else if (theAssembler.gSzChar=='H')
             theAssembler.emit16(0xAB42);
         else if (theAssembler.gSzChar=='W')
             theAssembler.emit16(0x9A42);
         else if (theAssembler.gSzChar==('U'<<8|'B'))
             theAssembler.emit16(0x9B42);
         else if (theAssembler.gSzChar==('U'<<8|'H'))
             theAssembler.emit16(0xBB42);
    }

	void AsmFT833::xlabs(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
        doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit32(d);
	}


/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

void AsmFT833::br(Opa *o)
{
	long loc;
    int op = o->oc;
 
    if (op > 255) {
        theAssembler.emit8(op>>8);
        theAssembler.emit8(op&255);
    }
    else
    	theAssembler.emit8(op);
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

void AsmFT833::lbr(Opa *o)
{
	long loc;
    int op = o->oc;
    
    if (op > 255) {
        theAssembler.emit8(op>>8);
        theAssembler.emit8(op&255);
    }
    else
    	theAssembler.emit8(op);
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


	void AsmFT833::brl(Opa *o)
	{
		long loc;

        if (o->oc > 255) {
            theAssembler.emit8(o->oc>>8);
            theAssembler.emit8(o->oc&255);
        }
        else
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

	void AsmFT833::ldo(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit32(data);
	}

}
