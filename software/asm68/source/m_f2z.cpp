#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fwstr.h>
#include "asmbuf.h"
#include "fasm68.h"

/* ---------------------------------------------------------------
   Description :
	Mostly done on 92/09/19
--------------------------------------------------------------- */

int m_fill(SOp *o)
{
   long i,n, j;
   SValue val;

   if (gSzChar == 0)
	   gSzChar = 'L';
   if (!strchr("BWL", gSzChar))
   {
      Err(E_LENGTH); // Wrong length..
      return (FALSE);
   }
   val = expeval(gOperand[0], NULL);
   i = val.value;
   val = expeval(gOperand[1], NULL);
   n = val.value;
   DoingDef = TRUE;
   for (j = 0; j < i; j++)
      emits(gSzChar, n);
   DoingDef = FALSE;
   if(errtype == FALSE)
      return (FALSE);
   return (TRUE);
}

/* -----------------------------------------
		Set floating point format to FFP.
----------------------------------------- */

int m_ffp(SOp *o)
{
	fpFormat = FP_FFP;
	return TRUE;
}


/* -------------------------------------------------------------------
	Description :
		Processes include directive. This is somewhat tricky
	because of the fact that there may be text in the input buffer
	after the include directive due to a macro expansion. The input
	buffer has to be saved and restored.
------------------------------------------------------------------- */

int m_include(SOp *o)
{
   char buf[300];
   int ret, fnum;
   char *tmp;
   char *ptr;
   int tmplineno;
   time_t tim;
#ifdef DEMO
	Err(E_DEMOI);
	return TRUE;
#endif

//   printf("include:%s|\n", gOperand[0]); // getch();
   memset(buf, '\0', sizeof(buf));
   strncpy(buf, gOperand[0], sizeof(buf)-1);
   buf[sizeof(buf)-1] = '\0';
   free(gOperand[0]);
   gOperand[0] = NULL;
   trim(buf);
   tmplineno = lineno;
   fnum = CurFileNum;
   lineno = 0;
   tmp = strdup(ibuf.Buf());  // Save copy of input buffer
   if (tmp == NULL) {
      Err(E_MEMORY);
      ret = FALSE;
   }
   else {
      ptr = ibuf.Ptr();
      ibuf.clear();        // Start with fresh buffer for new file.
      FileLevel++;
      ret = PrcFile(buf);
      FileLevel--;
      if (FileLevel == 0)
         LocalSymTbl = NULL;
      memcpy(ibuf.Buf(), tmp, strlen(tmp));  // Restore input buffer.
      free(tmp);
      ibuf.setptr(ptr);
      lineno = tmplineno;
      CurFileNum = fnum;
      // echo filename
      fprintf(fpErr, "File: %s\r\n", File[CurFileNum].name);
      if(pass >= lastpass && fListing == TRUE) {
         time(&tim);
         fprintf(fpList, verstr, ctime(&tim), page);
         fputs(File[CurFileNum].name, fpList);
		 fputs("\r\n", fpList);
         fputs("\r\n\r\n", fpList);
      }
   }
   gOperand[0] = strdup(buf); // So it can be freed on return to PrcMneumonic.
   if (gOperand[0] == NULL)
      Err(E_MEMORY);
   return (ret);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */
int m_jump(SOp *o)
{
   return (stdemit1(AM_CTL, o->ocode));
}


int m_lea(SOp *o)
{
	int op = o->ocode;
   int dr;

   if (IsAReg(gOperand[1], &dr))
      return (stdemit(gOperand[0], AM_CTL, dr, 'x', op));
        return (FALSE);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */

int m_link(SOp *o)
{
	int op = o->ocode;
   int reg;
   SValue val;

   if (IsAReg(gOperand[0], &reg) && gOperand[1][0] == '#')
   {
		if (gSzChar == 0) {
		   if (gProcessor & (PL_234C | PL_EC30 | PL_EC40 | PL_LC40))
			   gSzChar = 'L';
		   else
			   gSzChar = 'W';
		}

	   if (gSzChar == 'L') {
		   if (gProcessor & (PL_234C | PL_EC30 | PL_EC40 | PL_LC40))
		   {
				val = expeval(&gOperand[1][1], NULL);
				emitw(0x4808 | RegFld(reg));
				emitw((int) val.value >> 16);
				emitw((int) val.value);
				return (TRUE);
		   }
		   else
			   Err(E_WORDONLY);
	   }
      val = expeval(&gOperand[1][1], NULL);
      emitw(op | RegFld(reg));
      emitw((int) val.value);
      return (TRUE);
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_lpstop(SOp *optr)
{
	SValue val;
	int op = optr->ocode;
	int op2 = optr->ocode2;

	if (gSzChar == 0) gSzChar = 'W';
	if (gSzChar != 'W')
		Err(E_WORDONLY);
	emitw(op);
	emitw(op2);
	if (gOperand[0][0] != '#')
	{
		emitw(0x2000);
		Err(E_INVOPERAND, gOperand[0]);
		return TRUE;
	}
	val = expeval(&gOperand[0][1], NULL);
	if (val.value < -32768 || val.value > 32767)
		Err(E_IMMTRUNC, val.value);
	emitw(val.value);
	return TRUE;
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */

int m_lst_on(SOp *o)
{
   char *line;

   printf("list pseudo op detected\n");
   line = gOperand[0] + strspn(gOperand[0], " \t");
   fListing = !strnicmp(line, "on", 2);
   return (TRUE);
}


int m_lword(SOp *o)
{
   return FALSE;
}
/* -------------------------------------------------------------------
	Description :
		Processes a macro definition. Gets optional macro parameter
	list then sets a flag indicating that the main assembling loop
	should collect lines for a macro definition. The 'endm'
	mneumonic is checked for in the main loop and the remainder of
	the definition is processed when 'endm' is detected.

      Macros have the form

         macro MACRONAME parameter[,parameter]...
         .
         .
         .
         endm

      The body of the macro is copied to the macro buffer.
------------------------------------------------------------------- */

int m_macro(SOp *o)
{
   char *sptr, *eptr;
   char nbuf[NAME_MAX+1];
   int idlen, xx;
   CMacro *fmac;
#ifdef DEMO
   static int nmacro = 0;

   nmacro++;
   if (nmacro > 21)
   {
	   Err(E_DEMOM);
	   return TRUE;
   }
#endif

   gNargs = 0;
   macrobufndx = 0;
   memset(macrobuf, '\0', sizeof(macrobuf));
   idlen = ibuf.GetIdentifier(&sptr, &eptr, FALSE);
   if (idlen == 0)
   {
      Err(E_MACRONAME);
      goto errxit;
   }
   if (pass < 2)
   {
      memset(nbuf, '\0', sizeof(nbuf));
      memcpy(nbuf, sptr, min(idlen, NAME_MAX));
      gMacro.SetName(nbuf);
      fmac = MacroTbl->find(&gMacro);
      if (fmac)
      {
         Err(E_DEFINED, nbuf);
         goto errxit;
      }
   }
   // Free parameter list (if not already freed)
   for (xx = 0; xx < MAX_MACRO_PARMS; xx++)
      if (parmlist[xx]) {
         free(parmlist[xx]);
         parmlist[xx] = NULL;
      }

   xx = gNargs = ibuf.GetParmList(parmlist);
   gMacro.SetArgCount(xx);
   gMacro.SetFileLine(CurFileNum, File[CurFileNum].LastLine);
   CollectingMacro = TRUE;
   return TRUE;

errxit:
   return FALSE;
}


/* -------------------------------------------------------------------
------------------------------------------------------------------- */
int m_nbcd(SOp *o)
{
   if (gSzChar != 0 && gSzChar != 'B')
      Err(E_ONLYBYTE);
   return (stdemit1(AM_DATALT, o->ocode));
}

/* -------------------------------------------------------------------
------------------------------------------------------------------- */

int m_message(SOp *o)
{
	fprintf(stdout, gOperand[0]);
	fprintf(stdout, "\n");
	return TRUE;
}


/* -------------------------------------------------------------------
------------------------------------------------------------------- */
int m_mul(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int dr;

	if (gSzChar == 'W' || (gProcessor & (PL_0 | PL_1))) {
		if (!IsDReg(gOperand[1], &dr))
			return (FALSE);
		return (stdemit(gOperand[0], AM_DATA, dr, 'W', op));
	}
	if (gSzChar == 'L' || gSzChar == 0)
	{
		int dh = 0, dl = 0;
		int ot, pat = 0;

		// manual override
		op = 0x4c00;

		ot = OpType(gOperand[0], &pat, Counter() + 4);
		if (!(ot & AM_DATA))
			Err(E_ILLADMD, gOperand[0]);
		op |= pat;
		if (IsDRegPair(gOperand[1], &dh, &dl))
			op2 |= (1 << 10);
		else if (IsDReg(gOperand[1], &dl))
			dh = 0;
		else
			err(NULL, E_XDREGPAIR, gOperand[1]);
		op2 |= RegFld12a(dl) | RegFld(dh);
		emitw(op);
		emitw(op2);
		emitrest();
		return (TRUE);
	}
	return (FALSE);
}


/* -------------------------------------------------------------------
   Module : org.c

   Description :
      Sets the value of the program counter. If the program counter
	has previously been set the new setting causes 0xff bytes to be
	written to the output file until the new setting is reached.

   Parameters :
      (char *) pointer to remainder of line after 'org' statement.
      (int) opcode mask (not used by org but passed by x68isop to all
            routines).

   Returns :
   
--------------------------------------------------------------------------- */

int m_org(SOp *o)
{
   static int orgd = 0, orgc = 0;
   long loc;
   char buf[80];
   SValue val;

//   printf("m_org:%s|\n", gOperand[0]);
   val = expeval(gOperand[0], NULL);
   loc = val.value;
   if (SectionTbl.IsCurrentSection(BSS_AREA)) {
//      BSSCounter = loc;
		 SectionTbl.activeSection->SetCounter(loc);
   }
   else {
	   if (fSOut)
		gSOut.flush();
      if (orgd == pass)
      {
         // Must be freed before reuse, was allocated in GetOperands()
/*         switch(CurrentSection) {
            case CODE_AREA:
               sprintf(buf, "%ld", loc - ProgramCounter);
               break;
            case DATA_AREA:
               sprintf(buf, "%ld", loc - DataCounter);
               break;
            default:
               sprintf(buf, "%ld", loc - ProgramCounter);
         }
 */		  sprintf(buf, "%ld", loc - SectionTbl.activeSection->Counter());
         gSzChar = 'B';
         // Must allocate with strdup because PrcMneu will free gOperand[0]
		 if (fBinOut) {
			gOperand[0] = strdup(buf);
			gOperand[1] = "0xff";
			m_fill(0);
			gOperand[1] = NULL;  // Must reset to NULL
		 }
		 else {
			// switch(CurrentSection) {
			//case CODE_AREA:
			//	ProgramCounter = loc;
			//	break;
			//case DATA_AREA:
			//	DataCounter = loc;
			//	break;
			//default:
			//	ProgramCounter = loc;
			// }
			 SectionTbl.activeSection->SetCounter(loc);
		 }
      }
      else
      {
         //switch(CurrentSection) {
         //   case CODE_AREA:
         //      ProgramCounter = loc;
         //      break;
         //   case DATA_AREA:
         //      DataCounter = loc;
         //      break;
         //   default:
         //      ProgramCounter = loc;
         //}
		 SectionTbl.activeSection->SetCounter(loc);
         orgd = pass;
      }
   }
   return (errtype);
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int m_pea(SOp *o)
{
   return (stdemit1(AM_CTL, o->ocode));
}


/* -------------------------------------------------------------------
	Description :
		Process a public declaration. All that happens here is the
	symbol is flagged as public so that when object code is
	generated it is included in a public declarations record. An
	entry is put into the symbol table if the symbol is not yet in
	the table. If the symbol is followed by a ':' then a label
	definition is assumed and label definition processing code is
	called. A list of symbols may be made public using the ',' as a
	separater.
------------------------------------------------------------------- */

int m_public(SOp *o)
{
   char *eptr, *sptr;
   int len, ch;
   CSymbol tdef, *p;
   char labeln[100];

   len = ibuf.GetIdentifier(&sptr, &eptr,FALSE);
   if (len < 1)
   {
      Err(E_PUBLIC);
      return (FALSE);
   }
   ch = ibuf.NextNonSpace();
   len = min(len, sizeof(labeln)-1);
   strncpy(labeln, sptr, len);
   labeln[len] = '\0';
   tdef.SetName(labeln);
   p = SymbolTbl->find(&tdef);

   if (p) {
      if (pass < 2 && p->Defined()) {
         ForceErr = 1;
         Err(E_DEFINED, labeln);
         ForceErr = 0;
      }
      else
         p->define(PUB);
   }
   else
      label(labeln, PUB);
   if (ch != ':')
      ibuf.unNextCh();

   return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */
int m_rtd(SOp *o)
{
	int op = o->ocode;
   int ii = 1;
   SValue val;

   if (gOperand[0][0] != '#')
      ii = 0;
   val = expeval(&gOperand[0][ii], NULL);
   emitw(op);
   emitw((int)val.value);
   return (TRUE);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */
int m_rtm(SOp *o)
{
	int op = o->ocode;
   int reg;

   if (IsAReg(gOperand[0], &reg))
      op |= 8;
   else if (!IsDReg(gOperand[0], &reg))
      return (FALSE);
   emitw(op | RegFld(reg));
   return (TRUE);
}


int m_section(SOp *o)
{
	Section *s;

	s = SectionTbl.FindSection(gOperand[0]);
	if (s)
		SectionTbl.activeSection = s;
	else {
		s = SectionTbl.AllocSection(gOperand[0]);
		SectionTbl.activeSection = s;
	}
	return (TRUE);
}

/* -----------------------------------------------------------------------------
   Description :
----------------------------------------------------------------------------- */
int m_set(SOp *o)
{
   if (gSzChar != 0 && gSzChar != 'B')
      Err(E_ONLYBYTE);
   return (stdemit1(AM_DATALT, o->ocode));
}


/* -------------------------------------------------------------------
   Description :
      Assemble shift (asl / asr / lsl / lsr / rol / ror / roxl / roxr)
   menumonics.
------------------------------------------------------------------- */

int m_shift(SOp *o)
{
	int op = o->ocode;
   int sr,dr;
   SValue val;

   if (gOperand[0][0] == '#' && IsDReg(gOperand[1], &dr))
   {
      val = expeval(&gOperand[0][1], NULL);
      sr = (int) val.value;
      if(sr > 8)
         Err(E_SHIFTCOUNT, sr);
      if (sr == 0)
         Err(E_SHIFTZERO);
	  else
		emitw(op | RegFld2(sr) | bwl2bit(gSzChar) | RegFld(dr));
      return (TRUE);
   }
   if (IsDReg(gOperand[0], &sr) && IsDReg(gOperand[1], &dr))
   {
      op = op | 0x20;
      emitw(op | RegFld2(sr) | bwl2bit(gSzChar) | RegFld(dr));
      return (TRUE);
   }
   if(gSzChar == 'W' || gSzChar == 0)
   {
      sr = (op & 0x18) << 6;
      op = op & 0xff00 | 0xc0 | sr;
      return (stdemit1(AM_MEMALT, op));
   }
   Err(E_WORDONLY);
   return (FALSE);
}


int m_size(SOp *o)
{
   return FALSE;
}


int m_stop(SOp *o)
{
	int op =o->ocode;
   SValue val;
   
   if (gOperand[0][0] == '#')
   {
      val = expeval(&gOperand[0][1], NULL);
      emitw(op);
      emitw((int)val.value);
      return (TRUE);
   }
   return (FALSE);
}


int m_struct(SOp *o)
{
   return (FALSE);
}


int m_swap(SOp *o)
{
	int op = o->ocode;
   int reg;

   if (IsDReg(gOperand[0], &reg))
   {
      emitw(op | reg);
      return (TRUE);
   }
   return (FALSE);
}


/* -------------------------------------------------------------------
	tbls / tblsn / tblu / tblun
------------------------------------------------------------------- */
int m_tbls(SOp *o)
{
	int op = o->ocode;
	int op1 = o->ocode2;
	int dx = 0, dym, dyn;
	char strdym[80], strdyn[80];
	int sop, pat = 0;

	op1 |= bwl2bit(gSzChar);

	if (!IsDReg(gOperand[1], &dx))
		Err(E_ILLADMD, gOperand[1]);
	// get destination operand pattern
	strcpy(strdym, "d0");
	strcpy(strdyn, "d0");
	// data register interpolate ?
	if (IsDRegPair(gOperand[0], &dym, &dyn))
	{
		if (dym > 7 || dyn > 7)
			Err(E_DATAPAIR, gOperand[0]);
		dym &= 7;
		dyn &= 7;
		op |= dym;
		op1 |= dyn | IRegBits(dx);
		emitw(op);
		emitw(op1);
	}
	// table interpolate
	else
	{
		sop = OpType(gOperand[0], &pat, Counter() + 4);
		if (!(sop & AM_CTLPRE))
			Err(E_ILLADMD, gOperand[0]);
		op |= pat;
		op1 |= IRegBits(dx);
		emitw(op);
		emitw(op1 | (1 << 8));	// table lookup
		emitrest();
	}
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_trap(SOp *o)
{
	int op = o->ocode;
   SValue val;
   
   if (gOperand[0][0] == '#')
   {
      val = expeval(&gOperand[0][1], NULL);
      emitw(op | (0xf & (int) val.value));
      return (TRUE);
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_trapcc(SOp *o)
{
	int op = o->ocode;

	if ((gOperand[0] && gOperand[0][0] != '#') ||
		(gOperand[1] != NULL))
		return FALSE;
	if (gOperand[0])
	{
		SValue val;

		if (gSzChar == 0) gSzChar = 'L';
		if (gSzChar != 'W' && gSzChar != 'L')
		{
			Err(E_ONLYWL);
			if (gSzChar == 'B')
				gSzChar = 'W';
			else
				gSzChar = 'L';
		}
		val = expeval(&gOperand[0][1], NULL);
		emitw(op | ((gSzChar == 'W') ? 2 : 3));
		emit(gSzChar, val.value);
		return TRUE;
	}
	emitw(op | 4);
	return TRUE;
}
	

/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_tst(SOp *optr)
{
	if (gProcessor & PL_234C)
		return (stdemit(gOperand[0], AM_ANY, 0, gSzChar, optr->ocode));
	else
		return (stdemit(gOperand[0], AM_ALT, 0, gSzChar, optr->ocode));
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_unlk(SOp *o)
{
	int op = o->ocode;
   int reg;

   if (IsAReg(gOperand[0], &reg))
   {
      emitw(op | reg);
      return (TRUE);
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
	Dx,Dy,#
	-(Ax),-(Ay),#
--------------------------------------------------------------- */
int m_unpk(SOp *o)
{
	int op = o->ocode;
	int sr = 0,dr = 0,sop,dop;
	SValue val;


	sop = OpType(gOperand[0], &sr, Counter()+2);
	dop = OpType(gOperand[1], &dr, Counter()+2);
	if (sop != dop)			// Operands must be either -(An),-(An) or
		return (FALSE);     // Dn,Dn.
	if (gOperand[2][0] != '#')
		return FALSE;
	if (sop == AM_AR_PRE)
		op = op | 8;
	else if (sop != AM_DR)
		return (FALSE);

	val = expeval(&gOperand[2][1], NULL);

	emitw(op | RegFld2(dr) | RegFld(sr));
	emitw(val.value);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_word(SOp *o)
{
   return FALSE;
}


/* ---------------------------------------------------------------
   Description :
      Mneumonics that map to a single 16 bit opcode.
      reset / nop / rts / rtr / rte
--------------------------------------------------------------- */

int m_wordout(SOp *o)
{
   emitw(o->ocode);
   return (TRUE);
}

