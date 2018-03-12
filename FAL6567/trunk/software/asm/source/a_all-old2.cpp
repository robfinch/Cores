/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	a_all.c

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.
	
=============================================================== */

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "fwstr.h"
#include "asm24.h"
#include "fstreamS19.h"

/* ---------------------------------------------------------------
	Description :
		Performs processing for .align psuedo op. Updates the
	appropriate counter.
--------------------------------------------------------------- */

int a_align(Opx *o)
{
   long data;

   data = expeval(gOperand[0], NULL).value;
   DoingDc = TRUE;
   gSzChar = 'B';
   switch(CurrentArea)
   {
      case CODE_AREA:
		  while(ProgramCounter.byte)
			  emitb(0xff);
         if (ProgramCounter.val % data)
         {
            while(ProgramCounter.val % data)
               emitw(0xffffffff);
         }
         break;

      case DATA_AREA:
		  while(DataCounter.byte)
			  emitb(0xff);
         if (DataCounter.val % data)
         {
            while(DataCounter.val % data)
               emitw(0xffffffff);
         }
         break;

      case BSS_AREA:
		  while(BSSCounter.byte)
			  emitb(0xff);
         if (BSSCounter.val % data)
         {
            while(BSSCounter.val % data)
               emitw(0xffffffff);
         }
         break;
   }
   DoingDc = FALSE;
   return (TRUE);
}


/* ---------------------------------------------------------------
	Description :
		Assembles alu mnemonics.

	ToDo: Add emulation of rotate right register-register
--------------------------------------------------------------- */

int a_imm(Opx *o)
{
	int op = o->oc;
	int data;

    if (is102)
    {
        if (gOperand[0][1]=='<')
	        data = expeval(&gOperand[0][2], NULL).value;
        else if (gOperand[0][1]=='>')
	        data = expeval(&gOperand[0][2], NULL).value >> 16;
        else
	        data = expeval(&gOperand[0][1], NULL).value;
        if (data > -32768 && data < 32767)
            emitw(op | ((data & 0xffff) << 16));
        else
        {
            emitw(op | 0x80000000);
            emitw(data);
        }
    }
    else {
        if (gOperand[0][1]=='<')
	        data = expeval(&gOperand[0][2], NULL).value;
        else if (gOperand[0][1]=='>')
	        data = expeval(&gOperand[0][2], NULL).value >> 8;
        else
	        data = expeval(&gOperand[0][1], NULL).value;
        emitb(op);
        emitb(data & 0xff);
    }
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a_z(Opx *optr)
{
	int op = optr->ocode;
	COperand o;
	__int32 d;

	o.parse(gOperand[0]);
	d = o.val.value;
    if (is102)
    {
        emitw(op);
        emitw(d);
    }
    else
    {
        emitb(op);
        emitb(d);
    }
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int a_a(Opx *optr)
{
	int op = optr->ocode;
	COperand o;
	__int32 d;

	o.parse(gOperand[0]);
	d = o.val.value;
    if (is102)
    {
        emitw(op);
        emitw(d);
    }
    else
    {
        emitb(op);
        emitc(d);
    }
	return TRUE;
}


/* ---------------------------------------------------------------
	a_branch

	Description:
		bcc/bcs/bvc/bvs/br
		Unconditional branch (Ra == R0)
--------------------------------------------------------------- */

int a_branch(Opx *o)
{
	int op = o->ocode;
	long loc;
	SValue val;
	__int32 Ra = 0, Rb = 0;
	__int32 data;

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

        if (is102)
        {
    		loc -= (ProgramCounter.val + 4);
		    if (loc > 32767 || loc < -32768)
		    {
			    err(NULL, E_BRANCH, loc);     // Branch out of range.
			    loc = 0xffffffff;
		    }
            emitw(op | ((loc & 0xffff)<<16));
        }
        else
        {
		    loc -= (ProgramCounter.val + 2);
		    if (loc > 127 || loc < -128)
		    {
			    err(NULL, E_BRANCH, loc);     // Branch out of range.
			    loc = 0xffffffff;
		    }
            emitb(op);
            emitb(loc&0xff);
        }
	}
	else {
		val = expeval(gOperand[0], NULL);
		loc = val.value;
//		loc = 0xffffffff;
		// it's possible the symbol could have been defined
		// it it was a backwards reference
		if (val.bDefined) {
            if (is102)
            {
		        loc -= (ProgramCounter.val + 4);
			    if (loc > 32767 || loc < -32768)
			    {
				    err(NULL, E_BRANCH, loc);     // Branch out of range.
				    loc = 0xffffffff;
			    }
            }
            else
            {
		        loc -= (ProgramCounter.val + 2);
			    if (loc > 127 || loc < -128)
			    {
				    err(NULL, E_BRANCH, loc);     // Branch out of range.
				    loc = 0xffffffff;
			    }
            }
		}
		else
			loc = 0xffffffff;

        if (is102)
            emitw(op | ((loc & 0xffff)<<16));
        else
        {
            emitb(op);
            emitb(loc&0xff);
        }

	}
	return TRUE;
}


/* ---------------------------------------------------------------
   m_bss

   Description :
      Sets output area to the bss area. If the bss counter has
   previously been set the new setting causes 0xff bytes to be
   written to the output file until the new setting is reached.
--------------------------------------------------------------- */

int a_bss(Opx *o)
{
   CurrentArea = BSS_AREA;
   return (TRUE);
}

int a_byte(Opx *o)
{
   return FALSE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
/*
int a_call(Opx *optr)
{
	int op = optr->ocode;
	SValue val;
	__int32 loc;
	int Rt, Ra, Rb;
	__int32 d, d2;
	__int32 data;
	COperand o;

	Rb = 0;
	Rt = 30;
	// specifying a stack pointer ?
	if (g_nops==2) {
		if (!IsReg(gOperand[0], &Rt))
			err(NULL, E_EXPECTREG);
	}
	Rt = Rt << 21;
	o.parse(gOperand[g_nops-1]);
	d = o.val.value;
	Ra = o.r1 << 16;
	switch(o.type) {
	case AM_NDX:
		// First processor version doesn't support [Ra+Rb]
		// so do the indexing the hard way
		if (gProcessor == PG_1) {
			emitw(0x60200000 | Ra | Rb | GetSzCode('W'));	// add r1,ra,rb
			emitw(0x20000000 | IMM | Rt | (1 << 16));		// call Rt,0[R1]
		}
		else {
			emitw(0x20000000 | Rt | Ra | Rb | GetSzCode('W'));
		}
		break;
	// For absolute modes use special call instruction not available
	// in first version of processor.
	case AM_ABS_LONG:
	case AM_ABS_SHORT:
		Ra = 0;
		// Check if quick call form can be used
		if (gProcessor != PG_1) {
			if ((d & 0xe0000000) == (ProgramCounter.val & 0xe0000000)) {
				emitw(0x28000000 | ((d & 0x1fffffff) >> 2));
				break;
			}
		}
		// Fall through to displacement mode
	case AM_DISP:
		// See if we can use disp[pc] mode
		d2 = d - (ProgramCounter.val + 4);
		if (Ra==0 && (d2 < 32768 && d2 >= -32768)) {
			emitw(0x20000000 | IMM | Rt | (31 << 16) | (d2 & 0xfffc));
		}
		// can't use pc rel.
		else {
			// Hope we can use short mode
			if (d < 32768 && d >= -32768)
				emitw(0x20000000 | IMM | Rt | Ra | (d & 0xfffc));
			else {
				emitw(SHLLD | ((d >> 16) & 0xffff));
				emitw(SHLLD | (d & 0xfffc));
				// First processor version doesn't support [Ra+Rb]
				// so do the indexing the hard way
				emitw(0x60200001 | Ra);		// add r1,ra,r1
				emitw(0x20000000 | IMM | Rt | (1 << 16) ); // call 0[r1]
			}
		}
		break;
	default:
		err(NULL, E_INVOPERAND, gOperand[0]);
	}

	return TRUE;
}
*/

/* ---------------------------------------------------------------
	a_code

	Description :
		Sets output area to the code area. If the program
	counter has previously been set the new setting causes 0xff
	bytes to be written to the output file until the new
	setting is reached.

	Parameters :
	  (int) opcode mask (not used by org but passed by x68isop
		to all routines).
--------------------------------------------------------------- */

int a_code(Opx *optr)
{
	gSOut.flush();
	CurrentArea = CODE_AREA;
	return (TRUE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int a_comment(Opx *optr)
{
   char ch;

   ch = ibuf.NextNonSpace();
   CommentChar = ch;
   InComment++;
   return TRUE;
}


/* ---------------------------------------------------------------
   m_cpu

   Description :
--------------------------------------------------------------- */

int a_cpu(Opx *o)
{
	long value;
	SValue val;
	int xx;

	for (xx = 0; gOperand[xx]; xx++)
	{
		trim(gOperand[xx]);

		val = expeval(gOperand[0], NULL);
		value = val.value;
		gProcessor = (int)value;
	}
	return (TRUE);
}


/* ---------------------------------------------------------------
   a_data

   Description :
--------------------------------------------------------------- */

int a_data(Opx *o)
{
	gSOut.flush();
	CurrentArea = DATA_AREA;
	return (TRUE);
}


/* ---------------------------------------------------------------
	Description :
		Define constant. Byte or word constants may be
	generated by a valid arithmetic expression.
	Example:

	 dc.b 'h','i',0   ;the string 'hi'

--------------------------------------------------------------- */

int a_db(Opx *o)
{
   int ii;
   char *s, ch, *p, *eptr, sch;
   char *backcodes = { "abfnrtv0'\"\\" };
   const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   gSzChar = o->ocode;
   DoingDc = TRUE;
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
                  emit(o->ocode, (__int64)textequ[p - backcodes]);
               else
               {
                  emit(o->ocode, (__int64)strtol(s, &s, 0));
                  --s;
               }
            }
            else
               emit(o->ocode, (__int64)ch);
            s++;
         }
         if (*s == '\'')
            s++;
      }
      else
         emit(o->ocode, expeval(s, &eptr).value);
   }
   DoingDc = FALSE;
   return (TRUE);
}


/* ---------------------------------------------------------------
	Description :
		Define constant. Byte or word constants may be
	generated by a valid arithmetic expression.
	Example:

	 dc.b 'h','i',0   ;the string 'hi'

--------------------------------------------------------------- */

int a_dc(Opx *o)
{
   int ii;
   char *s, ch, *p, *eptr, sch;
   char *backcodes = { "abfnrtv0'\"\\" };
   const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   DoingDc = TRUE;
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
                  emit(gSzChar, (__int64)textequ[p - backcodes]);
               else
               {
                  emit(gSzChar, (__int64)strtol(s, &s, 0));
                  --s;
               }
            }
            else
               emit(gSzChar, (__int64)ch);
            s++;
         }
         if (*s == '\'')
            s++;
      }
      else
         emit(gSzChar, expeval(s, &eptr).value);
   }
   DoingDc = FALSE;
   return (TRUE);
}


/* ---------------------------------------------------------------
   a_end

   Description :
	Ignores remainder of file.
--------------------------------------------------------------- */
int a_end(Opx *o)
{
	fseek(File[FileNum].fp, 0, SEEK_END);
	return TRUE;
}


/* ---------------------------------------------------------------
	a_endm

	Description :
		Second part of macro definiton. Actually store the
	macro in the table. To this point lines for the macro have
	been collected in macrobuf.
--------------------------------------------------------------- */
int a_endm(Opx *o)
{
   char *bdy, *bdy2;
   CMacro *mac;
   int ii;

   // First check if in the macro definition process
   if (!CollectingMacro) {
      err(NULL, E_ENDM);
      return FALSE;
   }
   CollectingMacro = FALSE;
   if (pass < 2)
   {
      mac = MacroTbl->allocmac();
      if (mac == NULL)
         err(jbFatalErr, E_MEMORY);
      mac->SetBody(macrobuf);
      mac->SetArgCount(gMacro.Nargs());
      mac->SetName(gMacro.Name());
      mac->SetFileLine(gMacro.File(), gMacro.Line());
      bdy = mac->InitBody(parmlist);   // put parameter markers into body
      bdy2 = strdup(bdy);
      if (bdy2 == NULL)
         err(jbFatalErr, E_MEMORY);
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


int a_ends(Opx *o)
{
   return (FALSE);
}


/* ---------------------------------------------------------------
	Description :
		Defines a macro that doesn't take parameters. The
	macro definition is assumed to be the remaining text on the
	line unless the last character is '\' which continues the
	definition with the next line.

		Associate symbols with numeric values. During pass one
	any symbols encountered should not be previously defined.
	If a symbol that already exists is encountered in an equ
	statement during pass one then it is multiplely defined.
	This is an error.

	Returns:
		FALSE if the line isn't an equ statement, otherwise
	TRUE.
--------------------------------------------------------------- */

int a_equ(char *iid)
{
   CSymbol *p, tdef;
   __int64 n;
   char size,
      label[50];
   char *sptr, *eptr, *ptr;
   char tbuf[80];
   int idlen;
   SValue v;

//   printf("m_equ(%s)\n", iid);

   /* --------------------------------------------------------------
   -------------------------------------------------------------- */
   ptr = ibuf.Ptr();    // Save off starting point // inptr;
    if (*ptr=='=')
       ibuf.NextCh();
    else
    {
       idlen = ibuf.GetIdentifier(&sptr, &eptr);
       if (idlen == 0)
       {
          ibuf.setptr(ptr); // restore starting point
          return FALSE;
       }

       if (idlen == 3)
       {
          if (strnicmp(sptr, "equ", 3))
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
         err(NULL, E_DEFINED, label);    // Symbol already defined.
         return (TRUE);
      }

      size = (char)GetSzChar();
      if (size != 0 && !strchr("BCHWLDS", size))
      {
         err(NULL, E_LENGTH);       //Wrong length.
         return (TRUE);
      }

      if (LocalSymTbl)
         p = LocalSymTbl->allocsym();
      else
         p = SymbolTbl->allocsym();
      if (p == NULL) {
         err(NULL, E_MEMORY);
         return TRUE;
      }
      // assume a size if not specified
      if (size==0)
      {
          if (gProcessor==102||gProcessor==65102)
              size = 'W';
            else
                size = 'C';
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
              if (gProcessor==102||gProcessor==65102) {
			        p->SetSize('W');
			        size = 'W';
              }
              else { 
    			  p->SetSize('C');
			        size = 'C';
              }
		  }
		  else {
			  p->SetSize(v.size);
		  }
	  }
      p->SetValue(n);
      p->SetDefined(1);
   }
   /* --------------------------------------------------------
         During pass two the symbol should be in the symbol
      tree as it would have been encountered during the
      first pass.
   -------------------------------------------------------- */
   else if(pass >= 2)
   {
      if(p == NULL)
      {
         err(NULL, E_NOTDEFINED, iid); // Undefined symbol.
         return (TRUE);
      }

      // skip over size spec
      size = (char)GetSzChar();
      if (size != 0 && !strchr("BWCHLDS", size))
      {
         err(NULL, E_LENGTH);       //Wrong length.
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

      /* ---------------------------------------------------------------------
            Print symbol value if in listing mode. The monkey business with
         tbuf is neccessary to chop off leading 'FF's when the value is
         negative.
      --------------------------------------------------------------------- */
      if(bGen && fListing)
      {
         switch(toupper(v.size/*  size*/))
         {
            case 'B':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[6], 3);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-14,"");
               col = SRC_COL-1;
               break;

            case 'C':
            case 'H':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[4], 5);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-16, "");
               col = SRC_COL-1;
               break;

            case 'W':
            case 'L':
               sprintf(tbuf, "%08.8X", (int)n);
               memmove(tbuf, &tbuf[0], 9);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-20, "");
               col = SRC_COL-1;
               break;

			case 'S':
			case 'D':
               sprintf(tbuf, "%08.8X", (int)(n >> 32));
               memmove(tbuf, &tbuf[0], 9);
               sprintf(&tbuf[6], "%08.8X", (int)n);
               memmove(&tbuf[6], &tbuf[8], 7);
               fprintf(fpList, "%7d = %s%*s", OutputLine, tbuf, SRC_COL-14, "");
               col = SRC_COL-1;
               break;
         }
//         OutListLine();
      }
   }
   return (TRUE);
}


/* ---------------------------------------------------------------
	a_extern

	Description :
		Declare external symbols. External symbols are added to
	the global symbol table with the extern oclass, if not
	already defined as public or extern.
--------------------------------------------------------------- */
int a_extern(Opx *o)
{
   char *sptr, *eptr;
   char ch;
   char label[NAME_MAX+1];
   int len, first = 1;
   CSymbol tdef, *p, *tmpsym;

   // Set default size of long if not specified.
   if (gSzChar == 0) gSzChar = 'W';
   // Size must be either word or long.
   if (gSzChar != 'W' && gSzChar != 'H') {
      err(NULL, E_WORDLONG);
      gSzChar = 'W';
   }

   do
   {
      len = ibuf.GetIdentifier(&sptr, &eptr);
      if (first)
      {
         if (len < 1)
         {
            err(NULL, E_ADDRLABEL);
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
            err(NULL, E_SIZE);
      }
      // If symbol doesn't exist then add as extern
      else {
         tmpsym = SymbolTbl->allocsym();
         if (tmpsym == NULL) {
            err(NULL, E_MEMORY);
            return FALSE;
         }
         tmpsym->SetDefined(0);
         tmpsym->SetName(label);
         tmpsym->SetSize(gSzChar);
         p = SymbolTbl->insert(tmpsym);
         if (p == NULL)
         {
            err(NULL, E_MEMORY);
            return FALSE;
         }
         p->Def(EXT, File[CurFileNum].LastLine, CurFileNum);
      }
   } while (ch == ',');
   return TRUE;
}

/* ---------------------------------------------------------------
   Description :
	Mostly done on 92/09/19
--------------------------------------------------------------- */

int a_fill(Opx *o)
{
   long i,n, j;
   SValue val;

//   printf("Fill: %c, %s, %s\n", gSzChar, gOperand[0], gOperand[1]);
   if (gSzChar == 0)
	   gSzChar = 'W';
   if (!strchr("WCB", gSzChar))
   {
      err(NULL, E_LENGTH); // Wrong length..
      return (FALSE);
   }
   val = expeval(gOperand[0], NULL);
   i = val.value;
   val = expeval(gOperand[1], NULL);
   n = val.value;
   DoingDc = TRUE;
   for (j = 0; j < i; j++)
      emit(gSzChar, n);
   DoingDc = FALSE;
   if(errtype == FALSE)
      return (FALSE);
   return (TRUE);
}


/* ---------------------------------------------------------------
	Description :
		Processes include directive. This is somewhat tricky
	because of the fact that there may be text in the input
	buffer after the include directive due to a macro
	expansion. The input buffer has to be saved and restored.
--------------------------------------------------------------- */

int a_include(Opx *o)
{
   char buf[300];
   int ret, fnum;
   char *tmp;
   char *ptr;
   int tmplineno;
   time_t tim;
#ifdef DEMO
	err(NULL, E_DEMOI);
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
      err(NULL, E_MEMORY);
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
      if(pass >= 2 && fListing == TRUE) {
         time(&tim);
         fprintf(fpList, verstr, ctime(&tim), page);
         fputs(File[CurFileNum].name, fpList);
		 fputs("\r\n", fpList);
         fputs("\r\n\r\n", fpList);
      }
   }
   gOperand[0] = strdup(buf); // So it can be freed on return to PrcMneumonic.
   if (gOperand[0] == NULL)
      err(NULL, E_MEMORY);
   return (ret);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */

int a_lst_on(Opx *o)
{
   char *line;

   printf("list pseudo op detected\n");
   line = gOperand[0] + strspn(gOperand[0], " \t");
   fListing = !strnicmp(line, "on", 2);
   return (TRUE);
}


int a_lword(Opx *o)
{
   return FALSE;
}


/* ---------------------------------------------------------------
	Description :
		Processes a macro definition. Gets optional macro
	parameter list then sets a flag indicating that the main
	assembling loop should collect lines for a macro
	definition. The 'endm' mnemonic is checked for in the main
	loop and the remainder of the definition is processed when
	'endm' is detected.

      Macros have the form

         macro MACRONAME parameter[,parameter]...
         .
         .
         .
         endm

      The body of the macro is copied to the macro buffer.
--------------------------------------------------------------- */

int a_macro(Opx *o)
{
   char *sptr, *eptr;
   char nbuf[NAME_MAX+1];
   int idlen, xx;
   CMacro *fmac;

   gNargs = 0;
   macrobufndx = 0;
   memset(macrobuf, '\0', sizeof(macrobuf));
   idlen = ibuf.GetIdentifier(&sptr, &eptr);
   if (idlen == 0)
   {
      err(NULL, E_MACRONAME);
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
         err(NULL, E_DEFINED, nbuf);
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


/* ---------------------------------------------------------------
--------------------------------------------------------------- */

int a_message(Opx *o)
{
	fprintf(stdout, gOperand[0]);
	fprintf(stdout, "\n");
	return TRUE;
}


/* ---------------------------------------------------------------
	Module : org.c

	Description :
		Sets the value of the program counter. If the program
	counter has previously been set the new setting causes 0xff
	bytes to be written to the output file until the new
	setting is reached.

	Parameters :
	  (char *) pointer to remainder of line after 'org'
		statement.
	  (int) opcode mask (not used by org but passed  
	  to all routines).
--------------------------------------------------------------- */

int a_org(Opx *o)
{
   static int orgd = 0, orgc = 0;
   long loc;
   char buf[80];
   SValue val;

//	printf("org:%s|\n", gOperand[0]);
   val = expeval(gOperand[0], NULL);
   loc = val.value;
   if (CurrentArea == BSS_AREA) {
	   BSSCounter.byte = 0;
      BSSCounter.val = loc;
   }
   else {
	   if (fSOut)
		gSOut.flush();
      if (orgd == pass)
      {
         // Must be freed before reuse, was allocated in GetOperands()
			sprintf(buf, "%ld", loc - Counter().val);
         gSzChar = 'B';
         // Must allocate with strdup because PrcMneu will free gOperand[0]
		 if (fBinOut | bMemOut) {
			 if (gOperand[0])
				 free(gOperand[0]);
			 if (gOperand[1])
				 free(gOperand[1]);
			gOperand[0] = strdup(buf);
			gOperand[1] = "0xff";
			a_fill((Opx *)0);
			gOperand[1] = NULL;  // Must reset to NULL
		 }
		  Counter().byte = 0;
		  Counter().val = loc;
      }
      else
      {
		  Counter().byte = 0;
		  Counter().val = loc;
         orgd = pass;
      }
   }
   return (errtype);
}


/* ---------------------------------------------------------------
	Description :
		Process a public declaration. All that happens here is
	the symbol is flagged as public so that when object code is
	generated it is included in a public declarations record.
	An entry is put into the symbol table if the symbol is not
	yet in the table. If the symbol is followed by a ':' then
	a label definition is assumed and label definition
	processing code is called. A list of symbols may be made
	public using the ',' as a separater.
--------------------------------------------------------------- */

int a_public(Opx *o)
{
   char *eptr, *sptr;
   int len, ch;
   CSymbol tdef, *p;
   char labeln[100];

   len = ibuf.GetIdentifier(&sptr, &eptr);
   if (len < 1)
   {
      err(NULL, E_PUBLIC);
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
         err(NULL, E_DEFINED, labeln);
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

int a_pop(Opx *o)
{
	return TRUE;
}

int a_size(Opx *o)
{
   return FALSE;
}


int a_struct(Opx *o)
{
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int a_word(Opx *o)
{
   return FALSE;
}


/* ---------------------------------------------------------------
   Description :
      Mneumonics that map to a single 24 bit opcode.
      nop / stop / ret / iret
--------------------------------------------------------------- */

int a_wordout(Opx *o)
{
    if (is102)
        emitw(o->ocode);
    else
        emitb(o->ocode);
   return (TRUE);
}


