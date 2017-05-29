/* ===============================================================
	(C) 2015 Bird Computer
	All rights reserved.

	asmFT832.cpp

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
#include "asmFT832.h"

namespace RTFClasses
{
// Need place to hold static vars
int AsmFT832::mem;
int AsmFT832::ndx;
}

namespace RTFClasses
{
	void AsmFT832::amem(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		mem = data;
	}

	void AsmFT832::andx(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		ndx = data;
	}

	void AsmFT832::imm(Opa *o)
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
	  doJmpPrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(data);
	}

	void AsmFT832::imm16(Opa *o)
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
	  doJmpPrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit16(data);
	}

	void AsmFT832::epimm(Opa *o)
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

	void AsmFT832::pea(Opa *o)
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


	void AsmFT832::per(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

		theAssembler.emit8(op);
   		loc -= (theAssembler.getProgramCounter().val + 2);
		theAssembler.emit16(loc);
	}


	void AsmFT832::sr(Opa *o)
	{
		int op = o->oc;
		long loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

        doFarPrefix();
        doSegPrefix();
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
	void AsmFT832::immx(Opa *o)
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
	void AsmFT832::immm(Opa *o)
	{
		int op = o->oc;
		int data = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;

    doJmpPrefix();            // for TSK
		theAssembler.emit8(op);
		if (isM32())
			theAssembler.emit32(data);
		else if (isM16())
			theAssembler.emit16(data);
		else
			theAssembler.emit8(data);
	}


	void AsmFT832::zp(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		    doFarPrefix();
        doSegPrefix();
        doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(d);
	}


	void AsmFT832::mv(Opa *op)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		theAssembler.emit8(op->oc);
		theAssembler.emit8(d);
		d = ((Operands6502 *)getCpu()->getOp())->op[1].val.value;
		theAssembler.emit8(d);
	}


	void AsmFT832::fill(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		doSegPrefix();
		doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit8(d);
	}


	void AsmFT832::abs(Opa *o)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
    	  doJmpPrefix();
        doSegPrefix();
        doSizePrefix();
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
	}


	void AsmFT832::labs(Opa *o)
	{
		__int32 d;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
    	  doJmpPrefix();
        doSegPrefix();
        doSizePrefix();
		theAssembler.emit8(o->oc);
		theAssembler.emit16(d);
		theAssembler.emit8(d>>16);
	}

    void AsmFT832::doSegPrefix(void)
    {
        char hasSegPrefix = ((Operands6502 *)getCpu()->getOp())->op[0].hasSegPrefix;
		if (hasSegPrefix) {
            switch(hasSegPrefix) {
            case 1: theAssembler.emit16(0x1B42); break;
            case 2: theAssembler.emit16(0x5B42); break;
            case 3: theAssembler.emit16(0x7B42); break;
            case 4:
            case 5:
                    theAssembler.emit16(0x3B42);
                 	theAssembler.emit16(((Operands6502 *)getCpu()->getOp())->op[0].seg.value);
                    break;
            }
        }
    }
    
    void AsmFT832::doFarPrefix(void)
    {
        char hasFarprefix = ((Operands6502 *)getCpu()->getOp())->op[0].hasFarPrefix;
		if (hasFarprefix)
            theAssembler.emit16(0xDA42);
    }
    
    void AsmFT832::doJmpPrefix(void)
    {
        char hasJmpprefix = ((Operands6502 *)getCpu()->getOp())->op[0].hasJmpPrefix;
		if (hasJmpprefix)
            theAssembler.emit16(0xCB42);
    }
    
    void AsmFT832::doSizePrefix(void)
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

	void AsmFT832::xlabs(Opa *o)
	{
		__int32 d;
		int op = o->oc;

		d = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
        doSegPrefix();
        doSizePrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit32(d);
	}


	void AsmFT832::jsegoffs(Opa *oc)
	{
		__int32 s,o;
		int op = oc->oc;

		s = ((Operands6502 *)getCpu()->getOp())->op[0].seg.value;
		o = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit24(o);
		theAssembler.emit16(s);
	}



/* ---------------------------------------------------------------
	Description:
		beq/bne/bpl/bmi/bcc/bcs/bvc/bvs/bra
--------------------------------------------------------------- */

void AsmFT832::br(Opa *o)
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

void AsmFT832::lbr(Opa *o)
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


	void AsmFT832::brl(Opa *o)
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

	void AsmFT832::bsl(Opa *o)
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
    		loc -= (theAssembler.getProgramCounter().val + 3);
			if (loc > 16277215 || loc < -16277216)
			{
				Err(E_BRANCH, loc);     // Branch out of range.
				loc = 0xffffffff;
			}
    		theAssembler.emit24(loc);
		}
		else
		{
			// branch displacment unknown
    		theAssembler.emit24(0xffffff);
		}
	}

    void AsmFT832::jcr(Opa *o)
    {
    	long loc;
    	int ctx;
        int op = o->oc;
        
    	  doJmpPrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
		ctx = ((Operands6502 *)getCpu()->getOp())->op[1].val.value; //expeval(theAssembler.gOperand[0], NULL);
		theAssembler.emit16(loc);
		theAssembler.emit8(ctx);
    }

    void AsmFT832::jcl(Opa *o)
    {
    	long loc;
    	int ctx;
        int op = o->oc;
        int popcnt;
        int p;
        
    	  doJmpPrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		loc = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
		ctx = ((Operands6502 *)getCpu()->getOp())->op[1].val.value; //expeval(theAssembler.gOperand[0], NULL);
		p = ((Operands6502 *)getCpu()->getOp())->op[2].val.value; //expeval(theAssembler.gOperand[0], NULL);
		popcnt = ((Operands6502 *)getCpu()->getOp())->op[3].val.value; //expeval(theAssembler.gOperand[0], NULL);
		theAssembler.emit24(loc);
		theAssembler.emit16(ctx);
		theAssembler.emit8((p ? 0x80 : 0x00)|(popcnt & 0x1f));
    }

    void AsmFT832::rtc(Opa *o)
    {
    	int popcnt;
        int op = o->oc;
        
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		popcnt = ((Operands6502 *)getCpu()->getOp())->op[0].val.value; //expeval(theAssembler.gOperand[0], NULL);
		theAssembler.emit8(popcnt);
    }

	void AsmFT832::jcf(Opa *oc)
	{
		__int32 s,o;
		int op = oc->oc;
    	int ctx;
        int p;
        int popcnt;

		s = ((Operands6502 *)getCpu()->getOp())->op[0].seg.value;
		o = ((Operands6502 *)getCpu()->getOp())->op[0].val.value;
		ctx = ((Operands6502 *)getCpu()->getOp())->op[1].val.value; //expeval(theAssembler.gOperand[0], NULL);
		p = ((Operands6502 *)getCpu()->getOp())->op[2].val.value; //expeval(theAssembler.gOperand[0], NULL);
		popcnt = ((Operands6502 *)getCpu()->getOp())->op[3].val.value; //expeval(theAssembler.gOperand[0], NULL);
    	  doJmpPrefix();
        if (op > 255) {
            theAssembler.emit8(op>>8);
            theAssembler.emit8(op&255);
        }
        else
        	theAssembler.emit8(op);
		theAssembler.emit24(o);
		theAssembler.emit16(s);
		theAssembler.emit16(ctx);
		theAssembler.emit8((p ? 0x80 : 0x00)|(popcnt & 0x1f));
	}

}
