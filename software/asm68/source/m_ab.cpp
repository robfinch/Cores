#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <fwstr.h>
#include "fasm68.h"

/* -------------------------------------------------------------------
   m_align(op);
   int op;

	Description :
		Performs processing for .align psuedo op. Updates the
	appropriate counter.
------------------------------------------------------------------- */

int m_align(SOp *o)
{
   long data;

   data = expeval(gOperand[0], NULL).value;
   DoingDef = TRUE;
   gSzChar = 'B';
   //switch(CurrentSection)
   //{
   //   case CODE_AREA:
   //      if (ProgramCounter % data)
   //      {
   //         while(ProgramCounter % data)
   //            emitb(0xff);
   //      }
   //      break;

   //   case DATA_AREA:
   //      if (DataCounter % data)
   //      {
   //         while(DataCounter % data)
   //            emitb(0xff);
   //      }
   //      break;

   //   case BSS_AREA:
   //      if (BSSCounter % data)
   //      {
   //         while(BSSCounter % data)
   //            emitb(0xff);
   //      }
   //      break;
   //}
   if (SectionTbl.activeSection->Counter() % data)
	   while(SectionTbl.activeSection->Counter() % data)
		   emitb(0xff);
   DoingDef = FALSE;
   return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
      Assembles abcd / sbcd mnuemonics. These look almost like
	addx/subx except only byte size is supported.
------------------------------------------------------------------- */

int m_abcd(SOp *o)
{
   if (gSzChar && gSzChar != 'B')
      err(NULL, E_ONLYBYTE);
   gSzChar = 'B';       //  Force byte size
   return (m_addx(o));
}


/* -------------------------------------------------------------------
	Description :
		Assembles add / sub mneumonics. If immediate mode is
	detected then m_addi() is called. If the destination register
	is an address register then m_adda() is called.

   Changes
           Author      : R. Finch
           Date        : 92/09/19
           Version     :
           Description :
               when immediate mode detected and called for handleing 
               'sub' instruction 0x400 passed instead of 0x600 to
               m_addi().

------------------------------------------------------------------- */

int m_add(SOp *o)
{
	int op = o->ocode;
   int reg;
   SOp o2;

   if (gOperand[0][0] == '#')
   {
	   o2.ocode = (op & 0x4000) ? 0x600 : 0x400;
      return (m_addi(&o2));
   }
	if (IsAReg(gOperand[1], &reg))
	{
		o2.ocode = o->ocode | 0xc0;
		return (m_adda(&o2));
	}
   else if (IsDReg(gOperand[1], &reg))
      return (stdemit(gOperand[0], AM_ANY, reg, gSzChar, op));
   else if (IsDReg(gOperand[0], &reg))
      return (stdemit(gOperand[1], AM_MEMALT, reg, gSzChar, op | 0x100));
   return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
      Assembles adda / suba / cmpa mneumonics.
------------------------------------------------------------------- */

int m_adda(SOp *o)
{
	int op = o->ocode;
   int dr;

   if (IsAReg(gOperand[1], &dr))
   {
      switch(gSzChar)
      {
         case 'W':
            break;
         case 'L':
		 case 0:
            op |= 0x100;
			break;
         default:
            Err(E_BYTEADDR);
      }
      return (stdemit(gOperand[0], AM_ANY, dr, gSzChar, op));
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
	Description :
		Assembles addi / subi / cmpi mneumonics. For addi/subi if
	the constant is from 1 to 8 the instruction is processed as
	addq/subq. If the destination register is an address register
	then m_adda() is called.
------------------------------------------------------------------- */

int m_addi(SOp *o)
{
	int op = o->ocode;
	long data;
	int ot, oppat = 0;

   if (gOperand[0][0] != '#')
   {
      Err(E_SOURCEIMM, gOperand[0]);
      return (FALSE);
   }

   /* -------------------------------------------------------
         Get immediate data value. If data turns out to be
      from 1 to 8 then assemble as quick immediate opcode
      (addi/subi only).
   ------------------------------------------------------- */
   data = expeval(&gOperand[0][1], NULL).value;
   if (op != 0xc00)     // if not cmpi
      if (data > 0 && data < 9)	// same as addq
			return (stdemit(gOperand[1], AM_ALT, (int)data,
				gSzChar, (op == 0x600) ? 0x5000 : 0x5100));

   ot = OpType(gOperand[1], &oppat, sz46(gSzChar));
   if (!(ot & AM_ALT))
      return (FALSE);

   //   If the destination turns out to be an address
   // register then call m_adda().
   if (ot & AM_AR)
   {
	  SOp o2;
	  switch(op)
      {
         case 0x400: o2.ocode = 0x90c0; break;
         case 0x600: o2.ocode = 0xd0c0; break;
         case 0xc00: o2.ocode = 0xb0c0; break;
      }
      return (m_adda(&o2));
   }

   emitw(op | bwl2bit(gSzChar) | oppat);
   if (lastsym)
	lastsym->AddReference(Counter());
   emit(gSzChar, data);
   emitrest();
   return (TRUE);
}


/* -----------------------------------------------------------------------------
   Description :
      Assembles addq / subq  mmneumonics.

   Returns :

   Changes
           Author      : R. Finch
           Date        : 92/09/19
           Version     :
           Description : check for immediate value of zero (which is illegal)
            added.

----------------------------------------------------------------------------- */

int m_addq(SOp *o)
{
	int op = o->ocode;
   long data;

   if (gOperand[0][0] == '#')
   {
      data = expeval(&gOperand[0][1], NULL).value;
      if(data > 8 || data < 1)
         Err(E_QUICKTRUNC, data);   // Quick immediate data truncated.
      return (stdemit(gOperand[1], AM_ALT, (int)data, gSzChar, op));
   }
   Err(E_SOURCEIMM, gOperand[0]);
   return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
      Assembles addx / subx mneumonic.
------------------------------------------------------------------- */

int m_addx(SOp *o)
{
	int op = o->ocode;
   int sr = 0,dr = 0,sop,dop;

   sop = OpType(gOperand[0], &sr, Counter()+2);
   dop = OpType(gOperand[1], &dr, Counter()+2);
   if (sop != dop)       // Operands must be either -(An),-(An) or
      return (FALSE);         // Dn,Dn.
   if (sop == AM_AR_PRE)
      op = op | 8;
   else if (sop != AM_DR)    // ***************************
      return (FALSE);
   emitw(op | RegFld2(dr) | bwl2bit(gSzChar) | RegFld(sr));
   if (lastsym)
	lastsym->AddReference(Counter());
   return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
      and / or mneumonics.
      If immediate mode is detected m_andi() is called.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module
------------------------------------------------------------------- */

int m_and(SOp *o)
{
	int op = o->ocode;
   int reg;
	SOp o2;

   if (gOperand[0][0] == '#')
   {
	   o2.ocode = (op == 0x8000) ? 0 : 0x200;
      return(m_andi(&o2));
   }
   if (IsDReg(gOperand[1], &reg))  // Destination is data register
      return (stdemit(gOperand[0], AM_DATA, reg, gSzChar, op));
   else if (IsDReg(gOperand[0], &reg)) // Source is data register
      return (stdemit(gOperand[1], AM_MEMALT_DR, reg, gSzChar, op | 0x100));
   return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
      Assembles andi / eori / ori mneumonics.

------------------------------------------------------------------- */

int m_andi(SOp *o)
{
	int op = o->ocode;
   long data;
   int ot, oppat = 0;
   SValue val;

   if (gOperand[0][0] != '#')
   {
      Err(E_SOURCEIMM, gOperand[0]);
      return (FALSE);
   }

   //    Status register operation. If a size is specified then
   // translate into 'ccr' operation for byte size or 'sr' for
   // word size.
   if (!stricmp(gOperand[1], "sr"))
   {
      switch(gSzChar)
      {
         case 'B':
            emitw(op | 0x3c);
            break;
         case 0:
         case 'W':
            emitw(op | 0x7c);
            break;
         default:
            err(NULL, E_STATSIZE, gSzChar);
      }
      val = expeval(&gOperand[0][1], NULL);
      emitw((int)val.value);
   if (lastsym)
	lastsym->AddReference(Counter());
   }
   else if (!stricmp(gOperand[1], "ccr"))
   {
      switch(gSzChar)
      {
         case 0:
         case 'B':
            break;
          default:
            err(NULL, E_CCRBYTE, gSzChar);
      }
      emitw(op | 0x3c);
      val = expeval(&gOperand[0][1], NULL);
      emitw((int) val.value);
    if (lastsym)
	lastsym->AddReference(Counter());
  }
   else
   {
      ot = OpType(gOperand[1], &oppat, sz46(gSzChar));
      if (!(ot & AM_DATALT))
         return (FALSE);
      val = expeval(&gOperand[0][1], NULL);
      data = val.value;
      emitw(op | bwl2bit(gSzChar) | oppat);
   if (lastsym)
	lastsym->AddReference(Counter());
      emit(gSzChar, data);
      emitrest();
   }
   return (TRUE);
}


/* -----------------------------------------------------------------------------
	Description :
		Assembles bit field operators. bfchg / bfclr / bfset
----------------------------------------------------------------------------- */
int m_bfchg(SOp *o)
{
	int ot, pat;

	ot = OpType(gOperand[0], &pat, Counter()+4);
	if (!(ot & AM_CALTDR))
		Err(E_INVOPERAND, gOperand[0]);
	if (!(ot & AM_BITFLD))
		Err(E_MISSINGBF, gOperand[0]);
	emitw(o->ocode | pat);
	emitrest();
	return (TRUE);
}


/* -----------------------------------------------------------------------------
	Description :
		Assembles bit field operators. bftst
----------------------------------------------------------------------------- */
int m_bftst(SOp *o)
{
	int ot, pat;

	ot = OpType(gOperand[0], &pat, Counter()+4);
	if (!(ot & AM_CTLDR))
		Err(E_INVOPERAND, gOperand[0]);
	if (!(ot & AM_BITFLD))
		Err(E_MISSINGBF, gOperand[0]);
	emitw(o->ocode | pat);
	emitrest();
	return (TRUE);
}


/* -----------------------------------------------------------------------------
	Description :
		Assembles bit field operators. bfexts
----------------------------------------------------------------------------- */
int m_bfexts(SOp *o)
{
	int ot, pat, reg = 0;

	ot  = OpType(gOperand[0], &pat, Counter()+4);
	if (!(ot & AM_CTLDR))
		Err(E_INVOPERAND, gOperand[0]);
	if (!(ot & AM_BITFLD))
		Err(E_MISSINGBF, gOperand[0]);
	if (!IsDReg(gOperand[1], &reg))
		Err(E_INVOPERAND, gOperand[1]);
	emitw(o->ocode | pat);
	wordop[1] |= (reg << 12);
	emitrest();
	return TRUE;
}


/* -----------------------------------------------------------------------------
	Description :
		Assembles bit field operators. bfexts
----------------------------------------------------------------------------- */
int m_bfins(SOp *o)
{
	int ot, pat, reg = 0;

	if (!IsDReg(gOperand[0], &reg))
		Err(E_INVOPERAND, gOperand[0]);
	ot  = OpType(gOperand[1], &pat, Counter()+4);
	if (!(ot & AM_CALTDR))
		Err(E_INVOPERAND, gOperand[1]);
	if (!(ot & AM_BITFLD))
		Err(E_MISSINGBF, gOperand[1]);
	emitw(o->ocode | pat);
	wordop[1] |= (reg << 12);
	emitrest();
	return TRUE;
}


/* -----------------------------------------------------------------------------
	Description :
		Assembles bit (btst / bchg / bclr / bset) operators. Note
	btst has more possible addressing modes than other bit
	operations.
----------------------------------------------------------------------------- */

int m_bitop(SOp *o)
{
	int op = o->ocode;
	int sr, oppat = 0, ot;
	SValue val;

	if (IsDReg(gOperand[0], &sr))
		op |= 0x0100;
	else if (gOperand[0][0] == '#')
		op |= 0x0800;
	else
		return (FALSE);

	// Handle btst.
	if(!(op & 0x00c0))
	{
		ot = OpType(gOperand[1], &oppat, (op & 0x800) ? sz46('B') : (Counter()+2));
		if(!(ot & AM_DATA1))
			return (FALSE);
	}

	// bclr / bchg / bset.
	else
	{
		ot = OpType(gOperand[1], &oppat, (op & 0x800) ? sz46('B') : (Counter()+2));
		if(!(ot & AM_DATALT))
			return (FALSE);
	}

	// If source not data register it must be immediate,
	// validate the immediate value.
	if(!(op & 0x100))
	{
		val = expeval(&gOperand[0][1], NULL);
		if ((ot & AM_DR) == AM_DR) {	// destination data reg ?
			if (val.value > 31 || val.value < 0)
				Err(E_ONLYBITS, 31);
		}
		else {
			if (val.value > 7 || val.value < 0)
				Err(E_ONLYBITS, 7);
		}
		emitw(op | oppat);
		emitw((int) val.value & 0xff);
	}
	else
		emitw(op | RegFld2(sr) | oppat);
	emitrest();
	return (TRUE);
}


/* -----------------------------------------------------------------------------
   Description :
----------------------------------------------------------------------------- */

int m_bkpt(SOp *o)
{
	int op = o->ocode;
   int ii = 0;
   long value;
   SValue val;

   if (gOperand[0][0] == '#')
      ii = 1;
   val = expeval(&gOperand[0][ii], NULL);
   value = val.value;
   if (value > 7)
      Err(E_IMMTRUNC, (int)value);
   emitw(op | (int)(RegFld(value & 7)));
   return (TRUE);
}


/* ---------------------------------------------------------------
	Description:
	m_branch

		The calculation of the displacement is only valid on
	the second pass as the expression for the displacement may
	contain forward references that have not been resolved yet
	in the first pass. Therefore the first pass assumes that
	the displacement will fall within the requested range.
		The displacement is added to the address of the branch
	instruction plus two.

	For 68020 and higher processors a long branch (.L) is 32
	bits, a word branch (16 bits) may be specified using '.W'
	as the size	indicator.
	For 68010 and below a long branch (.L) is 16 bits.
	Regardless of processor a '.W' indicates a 16 bit
	displacement..

	If the branch is out of range, we force and invalid branch
	address.
--------------------------------------------------------------- */

int m_branch(SOp *o)
{
	int op = o->ocode;
   long loc;
   SValue val;

//   printf("m_branch\n");
	/* -----------------------------------------------------------
			Get branch displacement. We only bother to do this
		after the first pass since the branch displacement
		can't be guarenteed to be valid before pass two.
	----------------------------------------------------------- */
	if (pass > 1)
	{
		val = expeval(gOperand[0], NULL);
		loc = val.value;
		loc -= (Counter() + 2);
	}
	else
		loc = 0xffffffff;

	/* -----------------------------------------------------------
			Check for a long ('.L') branch for 68020 or above.
         Output extra long branch displacement. If a 16 bit
		 branch is desired then the .W size indicator will
		 have to be used.
	----------------------------------------------------------- */
	if ((gProcessor & (PL_234C | PL_EC30 | PL_EC40 | PL_LC40)) && (gSzChar == 'L'))
	{
		emitw(op | 0xff);
   if (lastsym)
	lastsym->AddReference(Counter());
		emitw((int)(loc >> 16));
		emitw((int)loc);
		return TRUE;
	}

	// For any processor level '.W' indicates 16 bit displacement.
	if (gSzChar == 'W')
	{
		emitw(op);
   if (lastsym)
	lastsym->AddReference(Counter());
		if ((pass > 1) && (loc > 32767 || loc < -32768))
		{
			Err(E_BRANCH, loc);     // Branch out of range.
			loc = 0xffffffff;
		}
		emitw((int)loc);
		return TRUE;
	}

	// Long branch ?
	// Long branches for 68020 and above were handled above.
	// If long size is specified, or no size is specified and
	// it's a branch subroutine.
	if (gSzChar == 'L' || (gSzChar == 0 && op == 0x6100))
	{
		emitw(op);
   if (lastsym)
	lastsym->AddReference(Counter());
		if ((pass > 1) && (loc > 32767 || loc < -32768))
		{
			Err(E_BRANCH, loc);     // Branch out of range.
			loc = 0xffffffff;
		}
		emitw((int)loc);
		return TRUE;
	}


	/* -----------------------------------------------------------
		Default: short branch
			First try and find a forced short branch size. This
		must be checked first since the next strmat(" %s") will
		also satisfy this condition.
   ----------------------------------------------------------------- */
//      printf("short branch\n");
	// For any processor level '.W' indicates 16 bit displacement.

	// first pass assume all word branches
	if (pass==1)
	{
		emitw(op);
   if (lastsym)
	lastsym->AddReference(Counter());
		if ((loc > 32767 || loc < -32768))
		{
			Err(E_BRANCH, loc);     // Branch out of range.
			loc = 0xffffffff;
		}
		emitw((int)loc);
		return TRUE;
	}
	else {
		if (loc < 127 && loc >= -128) {
		    emitw(op | (int)(loc & 0xff));
   if (lastsym)
	lastsym->AddReference(Counter());
			return (TRUE);
		}
		emitw(op);
   if (lastsym)
	lastsym->AddReference(Counter());
		if ((loc > 32767 || loc < -32768))
		{
			Err(E_BRANCH, loc);     // Branch out of range.
			loc = 0xffffffff;
		}
		emitw((int)loc);
	}

	//if (pass > 1)
 //   {
 //       if (loc > 127 || loc < -128)
	//	{
 //           Err(E_BRANCH, loc);       // Branch out of range.
	//		loc = 0xffffffff;
	//	}
 //   }
 //   emitw(op | (int)(loc & 0xff));
	return (TRUE);
}


/* -------------------------------------------------------------------
   m_bss

   Description :
      Sets output area to the bss area. If the bss counter has
   previously been set the new setting causes 0xff bytes to be
   written to the output file until the new setting is reached.

   Parameters :
------------------------------------------------------------------- */

int m_bss(SOp *o)
{
//   CurrentSection = BSS_AREA;
	SectionTbl.SetActiveSection("BSS");
   return (TRUE);
}

int m_byte(SOp *o)
{
   return FALSE;
}
