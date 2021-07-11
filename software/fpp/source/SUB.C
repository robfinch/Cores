#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "ht.h"
#include "fpp.h"

/* -----------------------------------------------------------------------------

   Description :
      Substitute a macro with arguments.
----------------------------------------------------------------------------- */

int SubParmMacro(SDef *p)
{
   int c, nArgs, ArgCount, xx;
   char *Args[10];
   char *arg, *bdy, *tp, *ptr;
   int st,nd;

   // look for opening bracket indicating start of parameters
   // if the bracket isn't present then there are no arguments
   // being passed so don't expand the macro just give error
   // and continue
   ptr = inptr;         // record start of arguments

   // We can't just take a pointer difference because the input
   // routine will occasionally reset the pointer for new lines.
   CharCount = 0;
   ptr = inptr;
   collect = 1;
   c = NextNonSpace(1);
   if (c != '(') {
//      printf("p->name:%s^, p->body:%s^, p->nArgs:%d\n", p->name, p->body, p->nArgs);// _getch();
//      unNextCh();
//      err(13);    // expecting parameters
      return 1;
   }

   // get macro argument list
   nArgs = p->nArgs;
   for (ArgCount = 0; ArgCount < nArgs; ArgCount++)
   {
      arg = GetMacroArg();
      if (arg == NULL)
         break;

      Args[ArgCount] = _strdup(arg);

      // Search for next argument
      c = NextNonSpace(1);
      if (c != ',') {
         ArgCount++;
         unNextCh();
         break;
      }
   }

   c = NextNonSpace(1);                       // Skip past closing ')'
   if (c != ')') {
      unNextCh();
      err(3);     // missing ')'
   }
   if (ArgCount != nArgs)                    // Check that argument count matches
      err(14, nArgs);

   collect = 0;

   // Substitute arguments into macro body
   bdy = _strdup(p->body);                    // make a copy of the macro body
   for(xx = 0; (xx < ArgCount) || (p->varg && Args[xx]); xx++)          // we don't want to change the original
   {
      tp = SubMacroArg(bdy, xx, Args[xx]);        // Substitute argument into body
      free(bdy);                             // free old body
      free(Args[xx]);                        // free space used by arg
      bdy = _strdup(tp);                      // copy new version of body
   }

   // Substitute macro into input stream
   //if (inptr-ptr != CharCount) {
	  // printf("charcount:%d inptr-ptr=%d\r\n", CharCount, inptr-ptr);
	  // getchar();
   //}
   SubMacro(bdy, inptr-ptr+strlen(p->name));
   free(bdy);                                // free last strdup
   return 0;
}


/* -----------------------------------------------------------------------------

   Description :
      This function makes two passes through the input buffer. The first
   pass substitutes any macros, the second pass performs pasteing.
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

void SearchAndSub()
{
	static int InComment = 0;
   int c, InComment2 = 0;
   int QuoteToggle = 0;
	 int Quote2 = 0;
   char *id, *ptr, *optr;
   SDef *p, tdef;

   // Check if we hit the end of the current input line we do this because
   // NextCh would read another line

   optr = inptr;
   while (1)
   {
      if ((c = PeekCh()) == 0)
         break;

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

      ptr = inptr;            // record the position of the input pointer
      id = GetIdentifier();   // try and get an identifier

	  if (id)
      {
         tdef.name = _strdup(id);
         if (tdef.name == NULL)
            err(5);

		 // Search and see if the identifier corresponds to a macro
		 p = (SDef *)htFind(&HashInfo, &tdef);
         if (p != (SDef *)NULL)
         {
			 if (fdbg) fprintf(fdbg, "macro %s\r\n", p->name);
            //    If this isn't a macro with parameters, then just copy
            // the body directly to the input. Overwrite the identifier
            // string
			 if (p->nArgs >= 0) {
				 if (fdbg) fprintf(fdbg, "bef:%s", inbuf);
                 SubParmMacro(p);
				 if (fdbg) fprintf(fdbg, "aft:%s", inbuf);
			 }
			else {
				if (fdbg) fprintf(fdbg, "bef:%s", inbuf);
				SubMacro(p->body, strlen(p->name));
				if (fdbg) fprintf(fdbg, "aft:%s", inbuf);
			}
         }
         free(tdef.name);
         continue;
         // the identifier wasn't a macro so just let it be
      }
      // failed to get identifier, so just continue with the next character
      c = NextCh();
   }
   inptr = optr;
	 while (*optr) {
		 if (*optr == '\x15')
			 *optr = '\x22';
		 optr++;
	 }
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
   char *ptr, *id, *sptr;
   int c;
   SDef tdef, *p;
   int needClosePa = 0;

   ptr = inptr;
   while(1)
   {
      if (PeekCh() == 0)   // Stop at end of current input
         break;
      SkipSpaces();
      sptr = inptr;
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
            SubMacro((char *)(p ? "1" : "0"), inptr-sptr);
         }
      }
      else
         NextCh();
   }
   inptr = ptr;
}
