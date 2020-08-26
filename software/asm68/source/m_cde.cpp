#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <fwstr.h>
#include "fasm68.h"

/* ---------------------------------------------------------------
   m_callm
--------------------------------------------------------------- */

int m_callm(SOp *optr)
{
   int oppat = 0;
   int ot;
   int op = optr->ocode;
   __int64 ac;

   if (gOperand[0][0] != '#')
   {
      Err(E_ARGCOUNT, gOperand[0]);
      return (FALSE);
   }

   // check for valid ea
   ot = OpType(gOperand[1], &oppat, Counter()+4);
   if (!(ot & AM_CTL))
      return (FALSE);

   /* -------------------------------------------------------
         Get argument count. Must be 0-255.
   ------------------------------------------------------- */
   ac = expeval(&gOperand[0][1], NULL).value;
   if (ac < 0 || ac > 255)
	   Err(E_ARGCHK);
   ac &= 0xff;
   emitw(op | oppat);
   emitw(ac);
   emitrest();
   return (TRUE);
}


/* ---------------------------------------------------------------
   m_cas
--------------------------------------------------------------- */
int m_cas(SOp *optr)
{
	int oppat = 0;
	int ot;
	int dc = 0, du = 0;
	int op = optr->ocode;

	if (!IsDReg(gOperand[0], &dc))
		Err(E_DATAREG, gOperand[0]);

	if (!IsDReg(gOperand[1], &du))
		Err(E_DATAREG, gOperand[1]);

	// check for valid ea
	ot = OpType(gOperand[2], &oppat, Counter() + 4);
	if (!(ot & AM_MEMALT))
		return (FALSE);
	op |= oppat;

	switch(gSzChar)
	{
	case 'B': op |= 0x200; break;
	case 'W': op |= 0x400; break;
	case 'L':
	case 0:	op |= 0x600; break;
	}

	emitw(op);
	emitw((du << 6) | dc);
	emitrest();

	return TRUE;
}


/* ---------------------------------------------------------------
   m_cas
--------------------------------------------------------------- */
int m_cas2(SOp *optr)
{
	int op = optr->ocode;
	int dc1 = 0, dc2 = 0;
	int du1 = 0, du2 = 0;
	int Rn1 = 0, Rn2 = 0;

	if (!IsDRegPair(gOperand[0], &dc1, &dc2))
		Err(E_DATAPAIR, gOperand[0]);
	if (!IsDRegPair(gOperand[1], &du1, &du2))
		Err(E_DATAPAIR, gOperand[1]);
	if (!IsRegIndPair(gOperand[2], &Rn1, &Rn2))
		Err(E_INDPAIR, gOperand[2]);
	switch(gSzChar)
	{
	case 'B':
		Err(E_ONLYWL);
	case 'W': op |= 0x400; break;
	case 'L':
	case 0:	op |= 0x600; break;
	}

	emitw(op);
	emitw(RegFld12(Rn1) | RegFld6(du1) | RegFld(dc1));
	emitw(RegFld12(Rn2) | RegFld6(du2) | RegFld(dc2));
	return TRUE;
}


/* ---------------------------------------------------------------
   m_chk

   Description :
--------------------------------------------------------------- */

int m_chk(SOp *optr)
{
	int oppat = 0, ea;
	int dr;
	int op = optr->ocode;

	if (IsDReg(gOperand[1], &dr))
	{
		if (gSzChar == 0) {
		   if (gProcessor & (PL_234C | PL_EC30 | PL_EC40 | PL_LC40))
			   gSzChar = 'L';
		   else
			   gSzChar = 'W';
		}

	   if (gSzChar == 'L') {
		   if (gProcessor & (PL_234C | PL_EC30 | PL_EC40 | PL_LC40))
			   op &= ~128;	// set long size
		   else
			   Err(E_WORDONLY);
	   }
		ea = OpType(gOperand[0], &oppat, Counter() + 2);
		if ((ea & AM_DATA) == 0)
			Err(E_ILLADMD, gOperand[0]);
		emitw(op | oppat | RegFld2(dr));
		if(ea == AM_IMMEDIATE)
			emitimm((op & 128) ? 'W' : 'L');
		else
			emitrest();
		return (TRUE);
	}
	return (FALSE);
}


/* ---------------------------------------------------------------
   m_chk2

   Description :
	chk2 / cmp2
--------------------------------------------------------------- */
int m_chk2(SOp *optr)
{
	int dr, sop, pat = 0;
	int ad = 0;
	int op = optr->ocode;
	int fCmp = (op == 0x80);

	op = 0xc0;
	if (IsAReg(gOperand[1], &dr))
		ad = 0x8000;
	else if (IsDReg(gOperand[1], &dr))
		;
	else
		Err(E_ILLADMD, gOperand[1]);

	sop = OpType(gOperand[0], &pat, Counter() + 4);
	if ((sop & AM_CTL) == 0)
		Err(E_ILLADMD, gOperand[0]);
	op |= (bwl2bit(gSzChar) << 3) | pat;
	emitw(op);
	if (fCmp)
		emitw(IRegBits(dr) | ad);
	else
		emitw(0x800 | IRegBits(dr) | ad);
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   m_cinv
   cinva / cinvl / cinvp / cpusha / cpushl / cpushp
--------------------------------------------------------------- */
int m_cinv(SOp *o)
{
	int op = o->ocode;
	int ot, pat = 0;

	if (strimat(gOperand[0], " n ") || strmat(gOperand[0], " "))
		op |= bit76(0);
	else if (strimat(gOperand[0], " d "))
		op |= bit76(1);
	else if (strimat(gOperand[0], " i "))
		op |= bit76(2);
	else if (strimat(gOperand[0], " id ") || strimat(gOperand[0], " di "))
		op |= bit76(3);
	else
		Err(E_CACHECODE, gOperand[0]);
	if ((op & 0x18) != 0x18)	// cinvl / cinvp / cpushl / cpushp ?
	{
		ot = OpType(gOperand[1], &pat, Counter()+2);
		if (ot != AM_AR_IND)
			Err(E_ARIND, gOperand[1]);
		op |= RegFld(pat);
	}
	emitw(op);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_clr(SOp *optr)
{
	return (stdemit(gOperand[0], AM_ALT, 0, gSzChar, optr->ocode));
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cmp(SOp *optr)
{
   int dr;
   int op = optr->ocode;
   SOp o2;

   if (IsDReg(gOperand[1], &dr))
      return (stdemit(gOperand[0], AM_ANY, dr, gSzChar, op));
   if (IsAReg(gOperand[1], &dr))
   {
	   o2.ocode = 0xb0c0;
      return(m_adda(&o2));
   }
   else if (gOperand[0][0] == '#')
   {
	   o2.ocode = 0xc00;
      return (m_addi(&o2));
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cmpm(SOp *optr)
{
	int op = optr->ocode;
   int sr = 0, dr = 0, sop, dop;

   sop = OpType(gOperand[0], &sr, Counter() + 2);
   dop = OpType(gOperand[1], &dr, Counter() + 2);
   if ((sop == dop) && (sop == AM_AR_POST))
   {
      emitw(op | bwl2bit(gSzChar) | RegFld2(dr) | RegFld(sr));
      return (TRUE);
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
   m_code

   Description :
      Sets output area to the code area. If the program counter has
   previously been set the new setting causes 0xff bytes to be
   written to the output file until the new setting is reached.

   Parameters :
      (int) opcode mask (not used by org but passed by x68isop to all
            routines).
------------------------------------------------------------------- */

int m_code(SOp *optr)
{
	gSOut.flush();
//	CurrentSection = CODE_AREA;
	SectionTbl.SetActiveSection("CODE");
	return (TRUE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_comment(SOp *optr)
{
   char ch;

   ch = ibuf.NextNonSpace();
   CommentChar = ch;
   InComment++;
   return TRUE;
}


/* ---------------------------------------------------------------
   Description :
		Coprocessor instructions are made somewhat tricky by
	the	fact that they can have a coprocessor defined number
	of extension words.
--------------------------------------------------------------- */
int m_cpbcc(SOp *o)
{
	int op = o->ocode;
	__int64 cpid, cpcond, cpwords;
	int sz;
	int xx;
	int val;
	
	if (gSzChar == 0 || gSzChar == 'L')
		sz = 0100;
	else if (gSzChar == 'W')
		sz = 0;
	else
	{
		sz = 0100;
		Err(E_ONLYWL);
	}

	cpid = expeval(gOperand[0], NULL).value;
	cpcond = expeval(gOperand[1], NULL).value;
	cpwords = expeval(gOperand[2], NULL).value;
	if (cpwords > MAX_OPERANDS - 4)
		Err(E_TOOMANYEW);
	emitw(op | ((cpid & 7) << 9) | sz | (cpcond & 077));
	for (xx = 0; xx < cpwords; xx++)
	{
		if (gOperand[3 + xx] == NULL)
		{
			Err(E_MISSINGEW);
			break;
		}
		val = expeval(gOperand[3 + xx], NULL).value;
		emitw(val);
	}
	if (gOperand[3 + xx + 1] != NULL)
		Err(E_TOOMANYEW);
	val = expeval(gOperand[3 + xx], NULL).value;
	val -= Counter();
	if (sz)
	{
		emitw(val >> 16);
		emitw(val);
	}
	else
	{
		if (val < -32768 || val > 32767)
			Err(E_BRANCH, val);
		emitw(val);
	}
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cpdbcc(SOp *o)
{
	int op = o->ocode;
	int cpid, cpcond, cpwords;
	int xx;
	int val;
	int reg;

	cpid = expeval(gOperand[0], NULL).value;
	cpcond = expeval(gOperand[1], NULL).value;
	if (!IsDReg(gOperand[2], &reg))
		Err(E_DATAREG, gOperand[2]);
	cpwords = expeval(gOperand[3], NULL).value;
	if (cpwords > MAX_OPERANDS - 5)
		Err(E_TOOMANYEW);
	emitw(op | ((cpid & 7) << 9) | RegFld(reg));
	emitw(cpcond & 077);
	for (xx = 0; xx < cpwords; xx++)
	{
		if (gOperand[4 + xx] == NULL)
		{
			Err(E_MISSINGEW);
			break;
		}
		val = expeval(gOperand[4 + xx], NULL).value;
		emitw(val);
	}
	if (gOperand[4 + xx + 1] != NULL)
		Err(E_TOOMANYEW);
	val = expeval(gOperand[4 + xx], NULL).value;
	val -= Counter();
	if (val < -32768 || val > 32767)
		Err(E_BRANCH, val);
	emitw(val);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
	Note we emit effective address words before spitting
	out additional coprocessor extension words. The order
	that these occur depends on the coprocessor.
--------------------------------------------------------------- */
int m_cpgen(SOp *o)
{
	int op = o->ocode;
	int ot, pat;
	int cpid, cpwords, cpcmd;
	int xx;
	int val;

	cpid = expeval(gOperand[0], NULL).value;
	cpcmd = expeval(gOperand[1], NULL).value;
	ot = OpType(gOperand[2], &pat, Counter()+4);
	emitw(op | ((cpid & 7) << 9) | (pat & 077));
	emitw(cpcmd);
	emitrest();
	cpwords = expeval(gOperand[3], NULL).value;
	if (cpwords > MAX_OPERANDS - 10)
		Err(E_TOOMANYEW);
	for (xx = 0; xx < cpwords; xx++)
	{
		if (gOperand[4 + xx] == NULL)
		{
			Err(E_MISSINGEW);
			break;
		}
		val = expeval(gOperand[4 + xx], NULL).value;
		emitw(val);
	}
	if (gOperand[4 + xx] != NULL)
		Err(E_TOOMANYEW);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cprestore(SOp *o)
{
	int op = o->ocode;
	int cpid;
	int ot, pat = 0;

	cpid = expeval(gOperand[0], NULL).value;
	ot = OpType(gOperand[1], &pat, Counter()+2);
	if ((ot & AM_CTLPOST) == 0)
		Err(E_INVOPERAND, gOperand[1]);
	emitw(op | ((cpid & 7) << 9) | (pat & 077));
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cpsave(SOp *o)
{
	int op = o->ocode;
	int cpid;
	int ot, pat = 0;

	cpid = expeval(gOperand[0], NULL).value;
	ot = OpType(gOperand[1], &pat, Counter()+2);
	if ((ot & AM_CALTPRE) == 0)
		Err(E_INVOPERAND, gOperand[1]);
	emitw(op | ((cpid & 7) << 9) | (pat & 077));
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cpscc(SOp *o)
{
	int op = o->ocode;
	int cpid, cpcond, cpwords;
	int ot, pat = 0;
	int xx;
	int val;

	cpid = expeval(gOperand[0], NULL).value;
	cpcond = expeval(gOperand[1], NULL).value;
	ot = OpType(gOperand[2], &pat, Counter()+4);
	if (!(ot & AM_DATALT))
		err(NULL, E_INVOPERAND, gOperand[2]);
	emitw(op | ((cpid & 7) << 9) | (pat & 077));
	emitw(cpcond & 077);
	emitrest();
	cpwords = expeval(gOperand[3], NULL).value;
	if (cpwords > MAX_OPERANDS - 10)
		Err(E_TOOMANYEW);
	for (xx = 0; xx < cpwords; xx++)
	{
		if (gOperand[4 + xx] == NULL)
		{
			Err(E_MISSINGEW);
			break;
		}
		val = expeval(gOperand[4 + xx], NULL).value;
		emitw(val);
	}
	if (gOperand[4 + xx] != NULL)
		Err(E_TOOMANYEW);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_cptrapcc(SOp *o)
{
	int op = o->ocode;
	int cpid, cpcond, cpwords;
	int xx;
	int val;
	int imm;
	int yy = 2;
	int opmode = 4;

	cpid = expeval(gOperand[0], NULL).value;
	cpcond = expeval(gOperand[1], NULL).value;
	if (gOperand[2][0] == '#')
	{
		imm = expeval(&gOperand[2][1], NULL).value;
		if (gSzChar == 0 || gSzChar == 'L')
			opmode = 3;
		else if (gSzChar == 'W')
			opmode = 2;
		else
		{
			opmode = 3;
			Err(E_ONLYWL);
		}
		yy = 3;
	}


	emitw(op | ((cpid & 7) << 9) | opmode);
	emitw(cpcond & 077);

	cpwords = expeval(gOperand[yy], NULL).value;
	if (cpwords > MAX_OPERANDS - 6)
		Err(E_TOOMANYEW);
	for (xx = 0; xx < cpwords; xx++)
	{
		if (gOperand[yy + 1 + xx] == NULL)
		{
			Err(E_MISSINGEW);
			break;
		}
		val = expeval(gOperand[yy + 1 + xx], NULL).value;
		emitw(val);
	}
	if (gOperand[yy + 1 + xx] != NULL)
		Err(E_TOOMANYEW);
	if (opmode == 2)
		emitw(imm);
	if (opmode == 3) {
		emitw(imm >> 16);
		emitw(imm);
	}
	return TRUE;
}


/* ---------------------------------------------------------------
   m_cpu

   Description :
--------------------------------------------------------------- */

int m_cpu(SOp *o)
{
	long value;
	int ii;
	static int proc[] = { 0, 8, 10, 20, 30, 40 };
	SValue val;
	int xx;

	for (xx = 0; gOperand[xx]; xx++)
	{
		trim(gOperand[xx]);

		if (!stricmp(gOperand[xx], "CPU32"))
		{
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_CPU32;
			continue;
		}

		if (!stricmp(gOperand[xx], "EC030"))
		{
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= (PL_EC30);
			continue;
		}

		if (!stricmp(gOperand[xx], "EC040"))
		{
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= (PL_EC40);
			continue;
		}

		if (!stricmp(gOperand[xx], "LC040"))
		{
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= (PL_LC40);
			continue;
		}

		// mmu
		if (!strnicmp(gOperand[xx], "mmu", 3))
		{
			if (isdigit(gOperand[xx][3]))
				mmu_cpid = (((gOperand[xx][3] - '0') & 7) << 9);
			gProcessor |= PL_M;
			continue;
		}

		if (!strnicmp(gOperand[xx], "+mmu", 4))
		{
			if (isdigit(gOperand[xx][4]))
				mmu_cpid = (((gOperand[xx][4] - '0') & 7) << 9);
			gProcessor |= PL_M;
			continue;
		}

		if (!stricmp(gOperand[xx], "-mmu"))
		{
			gProcessor &= ~PL_M;
			continue;
		}

		// floating point
		if (!strnicmp(gOperand[xx], "fp", 2))
		{
			if (isdigit(gOperand[xx][2]))
				fp_cpid = (((gOperand[xx][2] - '0') & 7) << 9);
			gProcessor |= PL_F;
			continue;
		}

		if (!strnicmp(gOperand[xx], "+fp", 3))
		{
			if (isdigit(gOperand[xx][2]))
				fp_cpid = (((gOperand[xx][2] - '0') & 7) << 9);
			gProcessor |= PL_F;
			continue;
		}

		if (!strnicmp(gOperand[xx], "-fp", 3))
		{
			gProcessor &= ~PL_F;
			continue;
		}

		val = expeval(gOperand[0], NULL);
		value = val.value;
		value %= 100;
		for (ii = 0; ii < 6; ii++)
		if (value == proc[ii])
			break;
		if (ii > 5)
			Err(E_PROC, value + 68000);
		else
			if (value == 8)
				value = 0;
		Processor = (int)value;
		switch (Processor % 100)
		{
		case 8:
		case 0:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_0; break;
		case 10:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_1; break;
		case 20:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_2; break;
		case 30:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_3; break;
		case 32:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_CPU32; break;
		case 40:
			gProcessor = gProcessor & ~PL_ALL;
			gProcessor |= PL_4; break;
		}
	}
	return (TRUE);
}


/* ---------------------------------------------------------------------------
   m_data

   Description :
--------------------------------------------------------------------------- */

int m_data(SOp *o)
{
	gSOut.flush();
//	CurrentSection = DATA_AREA;
	SectionTbl.SetActiveSection("DATA");
	return (TRUE);
}


/* -----------------------------------------------------------------------------
   Description :
      Define constant. Byte, word, or long constants may be generated by a
   valid arithmetic expression. Example:

         dc.b 'h','i',0   ;the string 'hi'

----------------------------------------------------------------------------- */

int m_dc(SOp *o)
{
   int ii;
   char *s, ch, *p, *eptr, sch;
   char *backcodes = { "abfnrtv0'\"\\" };
   const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   DoingDef = TRUE;
   for (ii = 0; (s = gOperand[ii]) && (ii < MAX_OPERANDS); ii++)
   {
      sch = *s;
      if (sch == '\'' || sch == '\"')
      {
         s++;
         while (*s && *s != sch)
         {
            ch = *s;
            if (ch == '\\')
            {
               s++;
               ch = *s;
               p = (char *)strchr(backcodes, ch);
               if (p)
                  emits(gSzChar, (__int64)textequ[p - backcodes]);
               else
               {
                  emits(gSzChar, (__int64)strtol(s, &s, 0));
                  --s;
               }
            }
            else
               emits(gSzChar, (__int64)ch);
            s++;
         }
         if (*s == '\'')
            s++;
      }
      else
         emits(gSzChar, expeval(s, &eptr).value);
   }
   DoingDef = FALSE;
   return (TRUE);
}


int m_dbranch(SOp *optr)
{
	int op = optr->ocode;
   int dr;
   long loc;
   SValue val;

   if (IsDReg(gOperand[0], &dr))
   {
      val = expeval(gOperand[1], NULL);
      loc = val.value - (Counter() + 2);
	  if (gProcessor & PL_FT)
		  loc /= 2;
      emitw(op | RegFld(dr));
   if (lastsym)
	lastsym->AddReference(Counter());
      emitw((int) loc);
      return (TRUE);
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   m_divide

   Description :
	divs.w / divs.l / divsl.l
	divu.w / divu.l / divul.l

		Note we use the low bit of the opcode as a flag to
	indicate divl instead of div. The second least significant
	bit is used to indicate signed / unsigned for long
	operations.
--------------------------------------------------------------- */
int m_divide(SOp *optr)
{
	int dr;
	int op = optr->ocode;
	int op2 = optr->ocode2;
	int fIsDiv = 0;

	if (gProcessor & PL_FT) {
		if (!IsDReg(gOperand[1], &dr))
			return (FALSE);
		return (stdemit(gOperand[0], AM_DATA, dr, 'L', op));
	}
	if (gSzChar == 'W' || (gProcessor & (PL_0 | PL_1)))
	{
		if (!IsDReg(gOperand[1], &dr))
			return (FALSE);
		return (stdemit(gOperand[0], AM_DATA, dr, 'W', op));
	}
	if (gSzChar == 0 || gSzChar == 'L')
	{
		int sop, pat = 0;
		int rgr = 0, rgq = 0;

		// we have to override because there's no way to
		// tell between div and div.l in the table
		fIsDiv = (op & 0x8000);
		op = 0x4c40;

		sop = OpType(gOperand[0], &pat, Counter()+4);
		if ((sop & AM_DATA) == 0)
			Err(E_INVOPERAND, gOperand[0]);
		emitw(op | pat);
		// Dr:Dq
		if (IsDRegPair(gOperand[1], &rgr, &rgq))
		{
			if (fIsDiv)	// div.l ?
				emitw(op2 | 0x0400 | IRegBits(rgq) | RegFld(rgr));
			else	// divl
				emitw(op2 | IRegBits(rgq) | RegFld(rgr));
		}
		// Dq
		else if (IsDReg(gOperand[1], &rgq))
			emitw(op2 | IRegBits(rgq) | RegFld(rgq));
		else
		{
			Err(E_INVOPERAND, gOperand[1]);
			emitw(op2 | IRegBits(rgq) | RegFld(rgr));
		}
		emitrest();
		return (TRUE);
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   m_end

   Description :
	Ignores remainder of file.
--------------------------------------------------------------- */
int m_end(SOp *o)
{
	fseek(File[FileNum].fp, 0, SEEK_END);
	return TRUE;
}


/* ---------------------------------------------------------------------------
   m_endm

   Description :
      Second part of macro definiton. Actually store the macro in the
   table. To this point lines for the macro have been collected in
   macrobuf.

   Parameters :
--------------------------------------------------------------------------- */
int m_endm(SOp *o)
{
   char *bdy, *bdy2;
   CMacro *mac;
   int ii;

   // First check if in the macro definition process
   if (!CollectingMacro) {
      Err(E_ENDM);
      return FALSE;
   }
   CollectingMacro = FALSE;
   if (pass < 2)
   {
      mac = MacroTbl->allocmac();
      if (mac == NULL)
         throw FatalErr(E_MEMORY);
      mac->SetBody(macrobuf);
      mac->SetArgCount(gMacro.Nargs());
      mac->SetName(gMacro.Name());
      mac->SetFileLine(gMacro.File(), gMacro.Line());
      bdy = mac->InitBody(parmlist);   // put parameter markers into body
      bdy2 = strdup(bdy);
      if (bdy2 == NULL)
         throw FatalErr(E_MEMORY);
      mac->SetBody(bdy2);              // save body with markers
   }
   // we don't need parms any more so free them up
   for (ii = 0; ii < MAX_MACRO_PARMS; ii++) {
      if (parmlist[ii]) {
         free(parmlist[ii]);
         parmlist[ii] = NULL;
      }
   }
   // Reset macro buffer
   memset(macrobuf, '\0', sizeof(macrobuf));
   macrobufndx = 0;
   if (pass < 2) {
      MacroTbl->insert(mac);
   }
   return TRUE;
}


int m_ends(SOp *o)
{
   return (FALSE);
}


int m_eor(SOp *o)
{
   int sr;
   int op = o->ocode;
   SOp o2;

   if (gOperand[0][0] == '#')
   {
	   o2.ocode = 0xa00;
      return (m_andi(&o2));
   }
   else if (IsDReg(gOperand[0], &sr))
      return (stdemit(gOperand[1], AM_MEMALT_DR, sr, gSzChar, op));
   return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
      Defines a macro that doesn't take parameters. The macro
	definition is assumed to be the remaining text on the line
	unless the last character is '\' which continues the definition
	with the next line.

		Associate symbols with numeric values. During pass one any
	symbols encountered should not be previously defined. If a
	symbol that already exists is encountered in an equ statement
	during pass one then it is multiply defined. This is an error.

	Returns:
		FALSE if the line isn't an equ statement, otherwise TRUE.
------------------------------------------------------------------- */

int m_equ(char *iid)
{
   CSymbol *p, tdef;
   __int64 n;
   char size,
      label[50];
   char *sptr, *eptr, *ptr;
   char tbuf[80];
   int idlen;
   SValue v;
	 bool reglist = false;

//   printf("m_equ(%s)\n", iid);

   /* --------------------------------------------------------------
   -------------------------------------------------------------- */
   ptr = ibuf.Ptr();    // Save off starting point // inptr;
   idlen = ibuf.GetIdentifier(&sptr, &eptr, FALSE);
   if (idlen == 0)
   {
      ibuf.setptr(ptr); // restore starting point
      return FALSE;
   }

   if (idlen == 3)
   {
      if (strnicmp(sptr, "equ", 3) && strnicmp(sptr, "reg",3))
      {
         ibuf.setptr(ptr);
         return (FALSE);
      }
   }
   else
   {
      ibuf.setptr(ptr);
      return (FALSE);
   }

	 if (!strnicmp(sptr, "reg",3))
	 {
		 ibuf.setptr(sptr);
		 reglist = true;
	 }
   /* -------------------------------------------------------
         Attempt to find the symbol in the symbol tree. If
      found during pass one then it is a redefined symbol
      error.
   ------------------------------------------------------- */
   tdef.SetName(iid);
   p = NULL;
   if (LocalSymTbl)
      p = LocalSymTbl->find(&tdef);
   if (p == NULL)
      p = SymbolTbl->find(&tdef);
   if(pass == 1)
   {
      if(p != NULL)
      {
         Err(E_DEFINED, label);    // Symbol already defined.
         return (TRUE);
      }

      size = (char)GetSzChar();
      if (size != 0 && !strchr("BWLDS", size))
      {
         Err(E_LENGTH);       //Wrong length.
         return (TRUE);
      }

      if (LocalSymTbl)
         p = LocalSymTbl->allocsym();
      else
         p = SymbolTbl->allocsym();
      if (p == NULL) {
         Err(E_MEMORY);
         return TRUE;
      }
      p->SetSize(size);
      p->SetName(iid);
	  p->SetLabel(0);
      p->Def(NO_OCLASS, File[CurFileNum].LastLine, CurFileNum);

      if (LocalSymTbl)
         LocalSymTbl->insert(p);
      else
         SymbolTbl->insert(p);
      v = ibuf.expeval(&eptr);
	  n = v.value;
	  // If the value is unsized set the size to long if it might
	  // contain a forward reference, otherwise set the size based
	  // on what the symbol evaluates to.
	  if (size == 0) {
		  if (v.fForwardRef) {
			  p->SetSize('L');
			  size = 'L';
		  }
		  else {
			  p->SetSize(v.size);
		  }
	  }
      p->SetValue(n);
      p->SetDefined(1);
			p->reglist = reglist;
   }
   /* --------------------------------------------------------
         During pass two the symbol should be in the symbol
      tree as it would have been encountered during the
      first pass.
   -------------------------------------------------------- */
   else if(pass == 2)
   {
      if(p == NULL)
      {
         Err(E_NOTDEFINED, iid); // Undefined symbol.
         return (TRUE);
      }

      // skip over size spec
      size = (char)GetSzChar();
      if (size != 0 && !strchr("BWLDS", size))
      {
         Err(E_LENGTH);       //Wrong length.
         return (TRUE);
      }

      /* -----------------------------------------------------
            Calculate what the symbol is equated to since
         forward references may now be filled in causing the
         value of the equate to be different than pass one 
         during pass two.
      ------------------------------------------------------ */
      v = ibuf.expeval(&eptr);
	  n = v.value;
      if(errtype == FALSE)
      {
         return (TRUE);
      }
      p->SetValue(n);
			p->reglist = reglist;

      /* ---------------------------------------------------------------------
            Print symbol value if in listing mode. The monkey business with
         tbuf is neccessary to chop off leading 'FF's when the value is
         negative.
      --------------------------------------------------------------------- */
      if(fListing)
      {
         switch(toupper(size))
         {
            case 'B':
               sprintf(tbuf, "%08.8X", n);
               memmove(tbuf, &tbuf[6], 3);
               fprintf(fpList, "%7d = %s%29s", OutputLine, tbuf, "");
               col = 42;
               break;

            case 'W':
               sprintf(tbuf, "%08.8X", n);
               memmove(tbuf, &tbuf[4], 5);
               fprintf(fpList, "%7d = %s%27s", OutputLine, tbuf, "");
               col = 42;
               break;

            case 'L':
			case 'S':
               sprintf(tbuf, "%08.8X", n);
               fprintf(fpList, "%7d = %s%23s", OutputLine, tbuf, "");
               col = 42;
               break;

			case 'D':
               sprintf(tbuf, "%08.8X", (n >> 32));
               sprintf(&tbuf[8], "%08.8X", n);
               fprintf(fpList, "%7d = %s%19s", OutputLine, tbuf, "");
               col = 42;
               break;
         }
//         OutListLine();
      }
   }
   return (TRUE);
}


/* ---------------------------------------------------------------------------
   m_even

   Description :
      Pad section with 0xff byte to align on even boundary if neccessary.
--------------------------------------------------------------------------- */
int m_even(SOp *o)
{
   //switch(CurrentSection)
   //{
   //   case DATA_AREA:
   //      if(DataCounter & 1)
   //         emitb(0xff);   // 0xff normally blank for an eprom.

   //   case BSS_AREA:
   //      if(BSSCounter & 1)
   //         emitb(0xff);   // 0xff normally blank for an eprom.
   //         
   //   case CODE_AREA:
   //   default:
   //      if(ProgramCounter & 1)
   //         emitb(0xff);   // 0xff normally blank for an eprom.
   //      break;
   //}
	if (Counter() & 1)
		emitb(0xff);
   return (TRUE);
}


/* ---------------------------------------------------------------------------
   m_exg

   Description :
--------------------------------------------------------------------------- */
int m_exg(SOp *o)
{
	int op = o->ocode;
   int sr = 0,dr = 0, sop, dop;

   sop = OpType(gOperand[0], &sr, Counter() + 2);
   dop = OpType(gOperand[1], &dr, Counter() + 2);
   if (!(sop & 3))
      return (FALSE);
   if (!(dop & 3))
      return (FALSE);
   if (sop == AM_DR && dop == AM_DR)
      emitw(0xc140 | RegFld2(sr) | RegFld(dr));
   else if (sop == AM_AR && dop == AM_AR)
      emitw(0xc148 | RegFld2(sr) | RegFld(dr));
   else
   {
      op = 0xc188;
      if(sop == AM_DR)
         emitw(op | RegFld2(sr) | RegFld(dr));
      else
         emitw(op | RegFld2(dr) | RegFld(sr));
   }
   return (TRUE);
}


/* ---------------------------------------------------------------
	ext
--------------------------------------------------------------- */
int m_ext(SOp *o)
{
	int op = o->ocode;
   int dr;

   if (IsDReg(gOperand[0], &dr))
   {
      if(gSzChar == 'B')
         Err(E_LENGTH); // Wrong length.
      emitw(op | 0x40 + bwl2bit(gSzChar) | RegFld(dr));
      return (TRUE);
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
	extb
--------------------------------------------------------------- */
int m_extb(SOp *o)
{
   int dr;
   int op = o->ocode;

   if (IsDReg(gOperand[0], &dr))
   {
      if(gSzChar != 'L' && gSzChar != 0)
         Err(E_LENGTH); // Wrong length.
      emitw(op | RegFld(dr));
      return (TRUE);
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
   m_extern

   Description :
      Declare external symbols. External symbols are added to the
   global symbol table with the extern oclass, if not already
   defined as public or extern.
------------------------------------------------------------------- */
int m_extern(SOp *o)
{
   char *sptr, *eptr;
   char ch;
   char label[NAME_MAX+1];
   int len, first = 1;
   CSymbol tdef, *p, *tmpsym;

   // Set default size of long if not specified.
   if (gSzChar == 0) gSzChar = 'L';
   // Size must be either word or long.
   if (gSzChar != 'W' && gSzChar != 'L') {
      Err(E_WORDLONG);
      gSzChar = 'L';
   }

   do
   {
      len = ibuf.GetIdentifier(&sptr, &eptr, FALSE);
      if (first)
      {
         if (len < 1)
         {
            Err(E_ADDRLABEL);
            return (FALSE);
         }
         first = 0;
      }
      ch = ibuf.NextNonSpace();
      len = min(len, sizeof(label)-1);
      strncpy(label, sptr, len);
      label[len] = '\0';
      tdef.SetName(label);
      p = SymbolTbl->find(&tdef);
      //    If symbol already exists then validate the size, but
	  // otherwise ignore.
      if (p)
      {
         if (p->Size() != gSzChar)
            Err(E_SIZE);
      }
      // If symbol doesn't exist then add as extern
      else {
         tmpsym = SymbolTbl->allocsym();
         if (tmpsym == NULL) {
            Err(E_MEMORY);
            return FALSE;
         }
         tmpsym->SetDefined(0);
         tmpsym->SetName(label);
         tmpsym->SetSize(gSzChar);
		 tmpsym->SetOClass(EXT);
         p = SymbolTbl->insert(tmpsym);
         if (p == NULL)
         {
            Err(E_MEMORY);
            return FALSE;
         }
         p->Def(EXT, File[CurFileNum].LastLine, CurFileNum);
      }
   } while (ch == ',');
   return TRUE;
}

