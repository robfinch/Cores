#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "ht.h"
#include "fpp.h"

int spm_inst = 0;

/* -----------------------------------------------------------------------------

   Description :
      Substitute a macro with arguments.
----------------------------------------------------------------------------- */

int SubParmMacro(SDef* p, int opt, int rpt)
{
  int c, nArgs, ArgCount, xx;
  arg_t Args[MAX_MACRO_ARGS];
  char* arg, * bdy, * tp, * ptr;
  int varg;
  int need_cb = 0;
  int64_t so;             // number of chars to substitute over
  pos_t* pndx, * qndx;
  char numbuf[20];

  spm_inst++;

  // look for opening bracket indicating start of parameters
  // if the bracket isn't present then there are no arguments
  // being passed so don't expand the macro just give error
  // and continue
  ptr = inptr;         // record start of arguments

  // We can't just take a pointer difference because the input
  // routine will occasionally reset the pointer for new lines.
  CharCount = 0;
  ptr = inptr;
  qndx = GetPos();
  bdy = _strdup(p->body->buf);                    // make a copy of the macro body
  if (opt == 0) {
    collect = 1;
    c = NextNonSpace(1);
    if (c != '(') {
      //      printf("p->name:%s^, p->body:%s^, p->nArgs:%d\n", p->name, p->body, p->nArgs);// _getch();
      //      unNextCh();
      //      err(13);    // expecting parameters
      return 1;
    }
    if (c == '(')
      need_cb = 1;

    // get macro argument list
    nArgs = p->nArgs;
    varg = p->varg;
    for (ArgCount = 0; (ArgCount < nArgs || varg) && ArgCount < MAX_MACRO_ARGS; ArgCount++)
    {
      arg = GetMacroArg();
      if (arg == NULL) {
        arg = p->parms[ArgCount]->def;
        if (arg == NULL)
          break;
      }

      Args[ArgCount].def = _strdup(arg);

      // Search for next argument
      c = NextNonSpace(1);
      if (c != ',') {
        ArgCount++;
        unNextCh();
        break;
      }
    }

    c = NextNonSpace(1);                       // Skip past closing ')'
    if (need_cb) {
      if (c != ')') {
        unNextCh();
        err(3);     // missing ')'
      }
    }
    if (ArgCount != nArgs && !varg)                    // Check that argument count matches
      err(14, nArgs);
    collect = 0;

    // Substitute arguments into macro body
    for (xx = 0; (xx < ArgCount) || (p->varg && Args[xx].def); xx++)          // we don't want to change the original
    {
      tp = SubMacroArg(bdy, xx, Args[xx].def, rpt);        // Substitute argument into body
      free(bdy);                             // free old body
      bdy = _strdup(tp);                      // copy new version of body
    }
    pndx = GetPos();
    so = pndx->bufpos - qndx->bufpos;         // number of chars to substitute over
    free(pndx);
  }
  else if (opt == 1) {
    for (xx = 0; xx < p->nArgs || (p->varg && p->parms[xx]->def); xx++) {
      // Substitute arguments into macro body
      tp = SubMacroArg(bdy, xx, p->parms[xx]->def, rpt);    // Substitute argument into body
      free(bdy);                             // free old body
      bdy = _strdup(tp);                      // copy new version of body
    }
    so = 0;
  }
  // Now handle the instance var.
  sprintf_s(numbuf, sizeof(numbuf), "%06d", spm_inst);
  tp = SubMacroArg(bdy, -1, numbuf, rpt);
  free(bdy);
  bdy = _strdup(tp);

  // Substitute macro into input stream
  SubMacro(bdy, so);
  free(bdy);                                // free last strdup
  free(qndx);
  return (0);
}


/* -----------------------------------------------------------------------------

   Description :
      Scan through input buffer performing macro substitutions where
   possible. A macro name must always begin with an alphabetic character or
   an underscore. The name can not span lines. A macro can not be contained
   within another string of characters.
      Macro substitutions are performed before any other processing on a
   line. This is necessary so that macro can be used within other macros.
      This function is kind of neat as it expands macros into the input
   buffer that its actually working on. It creates more work for itself!

      #define MACRO "Hello There World!"

      printMACRO  <- will not expand MACRO
      "MACRO"     <- will not expand

----------------------------------------------------------------------------- */

void SearchAndSub(SDef* exc, int rpt)
{
	static int InComment = 0;
  int c, InComment2 = 0;
  int QuoteToggle = 0;
	int Quote2 = 0;
  char *id, *ptr, *optr, *nd;
  SDef *p, tdef;
  pos_t* ondx, * ondx1;
  int ex, ln;
  char buf[20];
  char numbuf[20];
  char* tp;

  // Check if we hit the end of the current input line we do this because
  // NextCh would read another line

  ondx = GetPos();
  while (1)
  {
    if ((c = PeekCh()) == 0) {
      break;
    }

    if (c == '\n') {
        c = NextCh();
        QuoteToggle = 0;     // Quotes cannot cross newlines
				Quote2 = 0;
        InComment2 = 0;
        continue;
    }

    if (c == '/' && *(inptr+1) == '/') {
        InComment2 = 1;
        inptr += 2;
        continue;
    }

    if (c == '/' && *(inptr+1) == '*') {
        InComment = 1;
        inptr += 2;
        continue;
    }

    if (c == '*' && *(inptr+1) == '/') {
        InComment = 0;
        inptr += 2;
        continue;
    }

    if (InComment || InComment2) {
        c = NextCh();
        continue;
    }

		if (c == '\'') {
			c = NextCh();
			Quote2 = !Quote2;
			continue;
		}
		if (Quote2) {      // Just keep getting characters as long as
			c = NextCh();        // we're inside quotes
			continue;
		}

    if (c == '"') {         // Toggle quotation mode
        c = NextCh();
        QuoteToggle = !QuoteToggle;
        continue;
    }

    if (QuoteToggle) {      // Just keep getting characters as long as
        c = NextCh();        // we're inside quotes
        continue;         
    }

    //if (c == '\x14') {
      //if (syntax == ASTD && inptr[1] == '@') {
        // Now handle the instance var.
        //inptr += 2;
        //sprintf_s(numbuf, sizeof(numbuf), "%08d", inst);
        //SubMacro(numbuf, 2);
        /*
        if (PeekCh() == '[') {
          ex = strtoul(inptr, &nd, 10);
          ln = nd - inptr + 3;
          inptr = nd;
          if (PeekCh() == ']')
            NextCh();
        }
        if (rep_depth == 0) {
          sprintf_s(buf, sizeof(buf), "%08d", minst + ex);
          SubMacro(buf, ln);
        }
        */
      //}
    //}

    id = NULL;
    // Now handle the instance var.
    if (syntax == ASTD && c == '\x14') {
      if (inptr[1] == '@') {
        NextCh();
        NextCh();
        ondx1 = GetPos();
        spm_inst++;
        sprintf_s(numbuf, sizeof(numbuf), "%06d", spm_inst);
        tp = _strdup(SubMacroArg(&inptr[-2], -1, numbuf, rpt));
        SubMacro(tp, 2);
        free(tp);
        SetPos(ondx1);
        free(ondx1);
        inptr;
        inbuf;
      }
      else {
        ptr = inptr;            // record the position of the input pointer
        NextCh();
        id = GetIdentifier();
        if (id == NULL)
          unNextCh();
      }
    }
    else {
      ptr = inptr;            // record the position of the input pointer
      id = GetIdentifier();   // try and get an identifier
    }

	  if (id)
      {
         tdef.name = _strdup(id);
         if (tdef.name == NULL)
            err(5);

		 // Search and see if the identifier corresponds to a macro
		 p = (SDef *)htFind(&HashInfo, &tdef);
     ex = 0;
     if (p != NULL && exc) {
       ex = strcmp(p->name, exc->name) == 0;
     }

         if (p != (SDef *)NULL && !ex)
         {
           if (fdbg) fprintf(fdbg, "macro %s\r\n", p->name);
            //    If this isn't a macro with parameters, then just copy
            // the body directly to the input. Overwrite the identifier
            // string
			 if (p->nArgs > 0) {
				 if (fdbg) fprintf(fdbg, "bef:%s", inbuf->buf);
                 SubParmMacro(p,syntax==ASTD, rpt);
				 if (fdbg) fprintf(fdbg, "aft:%s", inbuf->buf);
			 }
			else {
				if (fdbg) fprintf(fdbg, "bef:%s", inbuf->buf);
				SubMacro(p->body->buf, strlen(p->name) + (syntax==ASTD ? 1 : 0));
				if (fdbg) fprintf(fdbg, "aft:%s", inbuf->buf);
			}
         }
         free(tdef.name);
         continue;
         // the identifier wasn't a macro so just let it be
      }
      // failed to get identifier, so just continue with the next character
      c = NextCh();
   }
   SetPos(ondx);
   optr = inptr;
	 while (*optr) {
		 if (*optr == '\x15')
			 *optr = '\x22';
		 optr++;
	 }
   free(ondx);
}


/* -----------------------------------------------------------------------------
   Description :
      Performs any paste operations in buffer.
----------------------------------------------------------------------------- */

void DoPastes(char *buf)
{
   char *p = buf;
   int QuoteToggle = 0;
   int len = strlen(buf);
   int ls = 0, ts = 0;

   while (1)
   {
      if (*p == 0)
         break;

      if (*p == '\n') {
         p++;
         QuoteToggle = 0;     // Quotes cannot cross newlines
         continue;
      }

      if (*p == '"') {         // Toggle quotation mode
         p++;
         QuoteToggle = !QuoteToggle;
         continue;
      }

      if (QuoteToggle) {      // Just keep getting characters as long as
         p++;                 // we're inside quotes
         continue;         
      }

      if (*p == '#' && *(p+1) == '#') {
        ls = -1;
        while (isspace(p[ls]))
          ls--;
        ls++;
        ts = 2;
        while (isspace(p[ts]))
          ts++;
        ts-=2;
         memmove(p+ls, p+2+ts, len - (p+ls - buf)); // shift over top ## in input buffer
         memset(&buf[len - 1 + ls - ts], 0, ts - ls + 2);
         --p;
      }
      p++;
   }
}


/* -----------------------------------------------------------------------------
   Description :
      Searches for the defined() operator and substitutes a value of '1' if
   the macro is defined or '0' if the macro is not defined. Used in
   processing if/elif statements.
----------------------------------------------------------------------------- */

void SearchForDefined()
{
   char *id;
   int c;
   SDef tdef, *p;
   int needClosePa = 0;
   int64_t stndx = 0;
   pos_t* pndx;

   pndx = GetPos();
   while(1)
   {
      if (PeekCh() == 0)   // Stop at end of current input
         break;
      SkipSpaces();
      stndx = inptr - inbuf->buf;
      id = GetIdentifier();
      if (id)
      {
         if (strcmp(id, "defined") == 0)
         {
            c = NextNonSpace(0);
            if (c == '(')
              needClosePa = 1;
            else
              unNextCh();
//               err(20);
//               break;
//            }
            id = GetIdentifier();
            if (id == NULL) {
               err(21);
               break;
            }
            if (needClosePa) {
              c = NextNonSpace(0);
              if (c != ')')
                err(22);
            }
            tdef.name = id;
            p = (SDef *)htFind(&HashInfo, &tdef);
            SubMacro((char*)(p ? "1" : "0"), inptr - (inbuf->buf+stndx));
         }
      }
      else
         NextCh();
   }
   SetPos(pndx);
   free(pndx);
}
