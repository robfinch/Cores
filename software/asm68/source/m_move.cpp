#include <stdio.h>
#include <string.h>
#include <fwlib.h>
#include "fasm68.h"

/* -------------------------------------------------------------------
   Description :
      If destination is address register then m_movea() is called
	(unless the instruction is 'move usp,a?').
      If an immediate value >= -128 and <= 127 is being moved to a
	data register then the m_moveq() is called.
------------------------------------------------------------------- */

int m_move(SOp *o) 
{
	int op = o->ocode;
   int sr,dr,size,ea,i, oppat = 0, soppat = 0, doppat = 0;
   int sea,ss,sd[8];    /* temporary storage for source ea */
   int dea,ds,dd[8];    /* ditto for destination */
   __int64 value;

//   printf("m_move\n");
   /* ---------------------
         Move using USP.
   --------------------- */
   if (!stricmp(gOperand[0], "USP") && IsAReg(gOperand[1], &sr))
   {
      if (gSzChar && gSzChar != 'L' && gSzChar != 0)
         Err(E_ONLYLONG);
      return(emitw(0x4e68 | RegFld(sr)));
   }
   if (IsAReg(gOperand[0], &sr) && !stricmp(gOperand[1], "USP"))
   {
      if (gSzChar && gSzChar != 'L' && gSzChar != 0)
         Err(E_ONLYLONG);
      return (emitw(0x4e60 | RegFld(sr)));
   }
   /* ---------------------
         Move using CCR.
   --------------------- */
   if (!stricmp(gOperand[1], "CCR"))
   {
      ea = OpType(gOperand[0], &oppat, Counter()+2);
      if (!(ea & AM_DATA))
         return (FALSE);
      if (gSzChar && gSzChar != 'B')
         Err(E_CCRBYTE, gSzChar);
      emitw(0x44c0 | oppat);
      if(ea == AM_IMMEDIATE)
         emitimm('B');
      else
         emitrest();
      return (TRUE);
   }
   /* ------------------
		Move from ccr
   ------------------ */
   if (gProcessor & (PL_ALL & ~PL_0))
   {
      if (!stricmp(gOperand[0], "CCR"))
      {
         ea = OpType(gOperand[1], &oppat, Counter()+2);  // "adcefghi"
         if (!(ea & AM_DATALT))
            return (FALSE);
         if (gSzChar && gSzChar != 'B')
            Err(E_CCRBYTE, gSzChar);
         emitw(0x42c0 | oppat);
         emitrest();
         return (TRUE);
      }
   }
   /* --------------------
         Move using SR.
   -------------------- */
   if (!stricmp(gOperand[1], "SR"))
   {
//      printf("m_move to SR gOperand[0]=%s|\n", gOperand[0]);
      ea = OpType(gOperand[0], &oppat, Counter()+2);
      if (!(ea & AM_DATA))
         return (FALSE);
      if (gSzChar && !(gSzChar == 'B' || gSzChar == 'W'))
         Err(E_STATSIZE, gSzChar);
      if (gSzChar == 'B')
         emitw(0x44c0 | oppat); // move to ccr
      else
         emitw(0x46c0 | oppat); // move to sr
      if(ea == AM_IMMEDIATE)
         emitimm('W');
      else
         emitrest();
      return (TRUE);
   }
   if (!stricmp(gOperand[0], "SR"))
   {
      ea = OpType(gOperand[1], &oppat, Counter() + 2);  // "adcefghi"
      if (!(ea & AM_DATALT))
         return (FALSE);
      if (gSzChar && !((gSzChar == 'W') ||
		  (gSzChar == 'B' && !(gProcessor & (PL_0 | PL_1)))))
         Err(E_STATSIZE, gSzChar);
      if (!(gProcessor & (PL_0 | PL_1)) && gSzChar == 'B')
         emitw(0x42c0 | oppat);
      else
         emitw(0x40c0 | oppat);
      emitrest();
      return (TRUE);
   }
   /* ---------------------------------
         Move source to destination.
   --------------------------------- */
   sea = OpType(gOperand[0], &soppat, Counter()+2);
   if (!(sea & AM_ANY))	// (anything)
      return (FALSE);
   ss = opsize;         /* save source size, ea code */
   for(i = 0; i < ss; i++)
      sd[i] = wordop[i];
   // Reset the opsize for immediate addressing according to
   // size specifier
   if (sea & AM_IMMEDIATE) 
   {
	   switch(gSzChar) {
	   case 'B':
	   case 'W':
		   opsize = 3;
		   break;
	   case 'L':
	   case 0:
	   default:
		   opsize = 5;
		   break;
	   }
   }
   /* ---------------------------------------------------------
         If the destination is an address register then call
      movea().
   --------------------------------------------------------- */
   dea = OpType(gOperand[1], &doppat, Counter() + opsize * 2);
   if (!(dea & AM_ALT))
      return (FALSE);
   if (dea == AM_AR)
   {
	   SOp o2;
	   o2.ocode = 0x2040;
      return (m_movea(&o2));
	 }
   /* ---------------------------------------------------
         If moving long immediate to data register and
      value >= -128 <= 127 then use moveq instruction.
   --------------------------------------------------- */
   if (sea == AM_IMMEDIATE && dea == AM_DR &&
	   (gSzChar == 'L' || gSzChar == 0))
   {
	   value = (sd[1] << 48) | (sd[2] << 32) | (sd[3] << 16) | sd[4];
      if (value >= -128 && value <= 127)
	  {
		  SOp o2;
		  o2.ocode = 0x7000;
         return (m_moveq(&o2));
	  }
   }
   ds = opsize;         /* save dest size, ea code */
   for(i = 0; i < ds; i++)
      dd[i] = wordop[i];
   dr = doppat << 3;
   dr |= (doppat >> 3);
   dr = (dr & 0x3f) << 6;
   switch(gSzChar)
   {
      case 'B': size = 0x1000; break;
      case 'W': size = 0x3000; break;
      case 'L': size = 0x2000; break;
      default: size = 0x2000; break; //err(4); break;
   }
   emitw(size | dr | soppat);
   for(i = 0; i < ss; i++)    /* restore source */
      wordop[i] = sd[i];
   opsize = ss;
   if(sea == AM_IMMEDIATE)
	emitimm(gSzChar);
   else
      emitrest();
   for(i = 0; i < ds; i++)    /* restore dest */
      wordop[i] = dd[i];
   opsize = ds;
   emitrest();
   return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */
int m_move16(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int Ay = 0, Ax = 0;
	int ots, otd;
	int pat = 0;

	ots = OpType(gOperand[0], &pat, Counter());
	otd = OpType(gOperand[1], &pat, Counter());
	// post increment form ?
	if ((ots & AM_AR_POST) && (otd & AM_AR_POST))
	{
		Ax = ots & 7;
		Ay = otd & 7;
		emitw(op | RegFld(Ax) | 0x20);
		emitw(op2 | RegFld12a(Ay) | 0x8000);
		return TRUE;
	}
	if ((ots & AM_AR_POST) && (otd & AM_ABS_LONG))
	{
		Ay = ots & 7;
		emitw(op | RegFld(Ay));
		emitrest();
		return TRUE;
	}
	if ((otd & AM_AR_POST) && (ots & AM_ABS_LONG))
	{
		Ay = otd & 7;
		emitw(op | RegFld(Ay) | (1<<3));
		emitrest();
		return TRUE;
	}
	if ((ots & AM_AR_IND) && (otd & AM_ABS_LONG))
	{
		Ay = ots & 7;
		emitw(op | RegFld(Ay) | (2<<3));
		emitrest();
		return TRUE;
	}
	if ((otd & AM_AR_IND) && (ots & AM_ABS_LONG))
	{
		Ay = otd & 7;
		emitw(op | RegFld(Ay) | (3<<3));
		emitrest();
		return TRUE;
	}
	return FALSE;
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */

int m_movec(SOp *o)
{
	int op = o->ocode;
	int op2 = 0, dir, ot = 0, reg = 0;

	if (IsDReg(gOperand[0], &reg))
	{
		dir = 1;
		ot = AM_DR;
	}
	else if (IsAReg(gOperand[0], &reg))
	{
		dir = 1;
		ot = AM_AR;
	}
	else if (IsDReg(gOperand[1], &reg))
	{
		dir = 0;
		ot = AM_DR;
	}
	else if (IsAReg(gOperand[1], &reg))
	{
		dir = 0;
		ot = AM_AR;
	}
	else
	{
		Err(E_EXPECTREG);
		return (FALSE);
	}
	if (!GetCReg(gOperand[dir], &op2))
		return (FALSE);
	emitw(op | dir);
	op2 |= (reg << 12) | ((ot == AM_AR) ? 0x8000 : 0);
	emitw(op2);
	return (TRUE);
}


/* -------------------------------------------------------------------
   Description :

------------------------------------------------------------------- */

int m_movea(SOp *o)
{
	int op = o->ocode;
   int ea, oppat = 0, dr;

   if (IsAReg(gOperand[1], &dr))
   {
      ea = OpType(gOperand[0], &oppat, Counter() + 2);
      if (!ea)
         return (FALSE);
      switch(gSzChar)
      {
         case 'W':
            op |= 0x1000;
			break;
         case 'L':
         default:
			 ;
      }
      emitw(op | RegFld2(dr) | oppat);
      if(ea == AM_IMMEDIATE)
         emitimm(gSzChar);
      else
         emitrest();
      return TRUE;
   }
   return FALSE;
}


/* -------------------------------------------------------------------
   Description :

------------------------------------------------------------------- */

int m_moveq(SOp *o)
{
	int op = o->ocode;
   int sr, dr;
   long data;

   if (gSzChar != 0)
      if (gSzChar != 'L')
         Err(E_ONLYLONG);
   if (gOperand[0][0] == '#' && IsDReg(gOperand[1], &dr))
   {
      data = expeval(&gOperand[0][1], NULL).value;
      sr = (int) (0xff & data);
      emitw(op | sr | RegFld2(dr));
      if(data <= 127 && data >= -128)
         return TRUE;
      else
         Err(E_QUICKTRUNC, data);
      return (TRUE);
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
      Assembles movem.
      If destination is predecrement indirect then reverse order of
	bit mask for registers.
------------------------------------------------------------------- */

int m_movem(SOp *o)
{
	int op = o->ocode;
   int size, oppat = 0, ot;
   int regpat;
   int rl;
   int rvs=0;

//   if (!strnicmp(gOperand[0], "REGS", 4))
   if (regpat = IsRegList(gOperand[0],&rvs))
   {
      ot = OpType(gOperand[1], &oppat, Counter()+4);
      if (!(ot & AM_CALTPRE))
         return (FALSE);
      switch(gSzChar)
      {
         case 'W': size = 0; break;
         case 'L':
			default:
			 size = 0x40;
      }
      emitw(op | size | oppat);
      /* -------------------------------------------------------------
			If the destination is predecrement address indirect
		then reverse order of bits.
      ------------------------------------------------------------- */
//      regpat = GetRegPat(&gOperand[0][4]);
      if (ot == AM_AR_PRE)
		  emitw(rvs?ReverseBits(regpat):regpat);
      else
         emitw(regpat);
      emitrest();
      return TRUE;
   }

//   if (!strnicmp(gOperand[1], "REGS", 4))
   if (regpat = IsRegList(gOperand[1],&rvs))
   {
      ot = OpType(gOperand[0], &oppat, Counter()+4);
      if (!(ot & AM_CTLPOST))
         return (FALSE);
      switch(gSzChar)
      {
         case 'W': size = 0; break;
         case 'L':
		 default:
			 size = 0x40; break;
      }
//      regpat = GetRegPat(&gOperand[1][4]);
      emitw(0x4c80 | size | oppat);
      emitw(regpat);
      emitrest();
      return (TRUE);
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
	Description :
		Anomaly - allowed address indirect by forcing change to
	address indirect with displacement (displacement forced to
	zero).
------------------------------------------------------------------- */

int m_movep(SOp *o)
{
	int op = o->ocode;
	char *amstr;
	int ot, dr, oppat = 0;

	if (IsDReg(gOperand[0], &dr))
	{
		amstr = gOperand[1];
		op |= 0x0080;
	}
	else if (IsDReg(gOperand[1], &dr))
		amstr = gOperand[0];
	else
		return (FALSE);
	if(gSzChar != 'W')
		op |= 0x0040;
	ot = OpType(amstr, &oppat, Counter()+2);
	//		The following line needed because OpType will convert
	// displacement address indirect to just address indirect if
	// the displacement is zero. In this case we actually want to
	// keep the zero displacement as movep needs it.
	if (ot == AM_AR_IND) { ot = AM_AR_DISP; wordop[1] = 0; }
	if (ot != AM_AR_DISP)
		return (FALSE);
	emitw(op | RegFld2(dr) | RegFld(oppat));
	emitw((int) wordop[1]);
	return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */

int m_moves(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int dir, ot, oppat = 0;
	int rg = 0, ad = 0;

	if (IsAReg(gOperand[0], &rg)) {
		ad = 0x8000;
		dir = 0x800;
	}
	else if (IsDReg(gOperand[0], &rg)) {
		ad = 0;
		dir = 0x800;
	}
	else if (IsAReg(gOperand[1], &rg)) {
		ad = 0x8000;
		dir = 0;
	}
	else if (IsDReg(gOperand[1], &rg)) {
		ad = 0;
		dir = 0;
	}
	ot = OpType(gOperand[dir ? 1 : 0], &oppat, Counter()+4);
    if (!(ot & AM_MEMALT))
		Err(E_ILLADMD, gOperand[dir ? 1 : 0]);
	emitw(op | bwl2bit(gSzChar) | oppat);
	emitw(ad | RegFld12a(rg) | op2 | dir);
	emitrest();
	return TRUE;
}


