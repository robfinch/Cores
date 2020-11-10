#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

//#include "fwstr.h"

char *rtrim(char *str);

/* ---------------------------------------------------------------------------
   char *SubArg(bdy, n, sub);
   char *bdy;  - pointer to macro body
   int n;      - parameter number to substitute
   char *sub;  - substitution string

      Searches the macro body a substitutes the passed parameter for the
   placeholders in the macro body.
--------------------------------------------------------------------------- */

char *SubMacroArg(char *bdy, int n, char *sub)
{
	static char buf[160000];
	char *s = sub, *o = buf;
	int stringize = 0;
	SDef *p, tdef;

   memset(buf, 0, sizeof(buf));
   for (o = buf; *bdy; bdy++, o++)
   {
		 stringize = 0;
      if (*bdy == '' && *(bdy+1) == (char)n + '0') {  // we have found parameter to sub
				if (bdy[-1] == '#') {
					stringize = 1;
					o[-1] = '\x15';
				}
         // Copy substitution to output buffer
				for (s = sub; *s;) {
					if (stringize) {
						if (*s=='"')
							*o++ = '\\';
					}
					*o++ = *s++;
				}
				if (stringize)
					*o++ = '\x15';
         --o;
         bdy++;
         continue;
      }
      *o = *bdy;
   }
   return buf;
}


/* ---------------------------------------------------------------------------
   Description :
      Gets the body of a macro. All macro bodies must be < 2k in size. Macro
   parameters are matched up with their positions in the macro. A $<number>
   (as in $1, $2, etc) is substituted in the macro body in place of the
   parameter name (we don't actually care what the parameter name is).
      Macros continued on the next line with '\' are also processed. The
   newline is removed from the macro.
---------------------------------------------------------------------------- */

char *GetMacroBody(char *parmlist[])
{
   char *b, *id = NULL, *p1, *p2;
   static char buf[160000];
   int ii, found, c;
   int InQuote = 0;
   int count = sizeof(buf)-1;

   SkipSpaces();
   memset(buf, 0, sizeof(buf));
   for (b = buf; count >= 0; b++, --count)
   {
      // First search for an identifier to substitute with parameter
      if (parmlist) {
         while (PeekCh() == ' ' || PeekCh() == '\t') {
            *b++ = NextCh();
            count--;
            if (count < 0)
               goto jmp1;
         }
         p1 = inptr;
         id = GetIdentifier();
         p2 = inptr;
         if (id) {
            for (found = ii = 0; parmlist[ii]; ii++)
               if (strcmp(parmlist[ii], id) == 0) {
                  *b = '';
                  b++;
                  count--;
                  if (count < 0)
                     goto jmp1;
                  *b = '0' + (char)ii;
                  found = 1;
                  break;
               }
            // if the identifier was not a parameter then just copy it to
            // the macro body
            if (!found) {
               strncpy(b, p1, p2-p1);
               count -= p2 -p1 - 1;
               if (count < 0)
                  goto jmp1;
               b += p2-p1-1;  // b will be incremented at end of loop
            }
         }
         else
            inptr = p1;    // reset inptr if no identifier found
      }
      if (id == NULL) {
         c = NextCh();
         if (c == '"')
            InQuote = !InQuote;
         if (!InQuote) {
            if (c == '/') {
               c = NextCh();
               // Block comment ?
               if (c == '*') {
                  while(c > 0) {
                     c = NextCh();
                     if (c == '*') {
                        c = NextCh();
                        if (c == '/')
                           break;
                        unNextCh();
                     }
                  }
                  if (c > 0) {
                     --b;
                     continue;
                  }
                  else
                     err(24);
               }
               // Comment to EOL ?
               else if (c == '/') {
                  while(c != '\n' && c > 0) c = NextCh();
                  if (c > 0) {
                     --b;
                     ++count;
                     goto jmp1;
                  }
               }
			   else {
				   c = '/';
                  unNextCh();
			   }
            }
            else if (c == '\\')  // check for continuation onto next line
            {
               while (c != '\n' && c > 0) c = NextCh();
               if (c > 0) {
                  --b;           // b will be incremented but we haven't got a character
                  ++count;
                  SkipSpaces();  // Skip leading spaces on next line
                  continue;
               }
            }
         }
         if (c == '\n' || c < 1) {
            if (InQuote)
               err(25);
            break;
         }
         *b = c;
      }
   }
jmp1:
   if (count < 0)
      err(26);
   *b = 0;
   rtrim(buf);    // Trim off trailing spaces.
   return buf;
}


/* ---------------------------------------------------------------------------
   Description :
      Gets an argument to be substituted into a macro body. Note that the
   round bracket nesting level is kept track of so that a comma in the
   middle of an argument isn't inadvertently picked up as an argument
   separator.
--------------------------------------------------------------------------- */

char *GetMacroArg()
{
   int Depth = 0;
   int c;
   static char argbuf[40000];
   char *argstr = argbuf;

   SkipSpaces();
   memset(argbuf,0,sizeof(argbuf));
   while(1)
   {
      c = NextCh();
      if (c < 1) {
         if (Depth > 0)
            err(16);
         break;
      }
      if (c == '(')
         Depth++;
      else if (c == ')') {
         if (Depth < 1) {  // check if we hit the end of the arg list
            unNextCh();
            break;
         }
         Depth--;
      }
      else if (Depth == 0 && c == ',') {   // comma at outermost level means
         unNextCh();
         break;                           // end of argument has been found
      }
      *argstr++ = c;       // copy input argument to argstr.
   }
   *argstr = '\0';         // NULL terminate buffer.
   if (argbuf[0])
	   if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
   return (argbuf);
   //return argbuf[0] ? argbuf : NULL;
}


/* ---------------------------------------------------------------------------
   Description :
      Used during the definition of a macro to get the associated parameter
   list.

   Returns
      pointer to first parameter in list.
---------------------------------------------------------------------------- */

int GetMacroParmList(char *parmlist[])
{
   char *id;
   int Depth = 0, c, count;
   int vargs = 0;

   count = 0;
   while(1)
   {
      id = GetIdentifier();
      if (id) {
        if (strncmp(id, "...", 3) == 0) {
          vargs = 1;
        }
         if (count >= 10) {
            err(15);
            goto errxit;
         }
         parmlist[count] = _strdup(id);
         if (parmlist[count] == NULL)
            err(5);
         count++;
      }
	  do {
		c = NextNonSpace(0);
		if (c=='\\')
			ScanPastEOL();
	  }
		while (c=='\\');
      if (c == ')') {   // we've gotten our last parameter
         unNextCh();
         break;
      }
      if (c != ',') {
         err(16);
         goto errxit;
      }
   }
//   if (count < 1)
//      err(17);
   if (count < 10)
      parmlist[count] = NULL;
errxit:;
   return vargs ? -count : count;
}


/* -----------------------------------------------------------------------------
   Description :
      Copies a macro into the input buffer. Resets the input buffer pointer
   to the start of the macro.

   slen; - the number of characters being substituted
----------------------------------------------------------------------------- */

void SubMacro(char *body, int slen)
{
   int mlen, dif, nchars;
   int nn;
   char *p;

   mlen = strlen(body);          // macro length
   dif = mlen - slen;
   nchars = inptr-inbuf;         // calculate number of characters that could be remaining
   //p = inptr + dif;
   //if (dif==0)
	  // ;
   //else if (dif > 0) {
	  // for (nn = sizeof(inbuf)-500-nchars-dif; nn >= 0; nn--)
		 //  p[nn] = inptr[nn];
   //}
   //else {
	  // for (nn = 0; nn < sizeof(inbuf)-500-nchars-dif; nn++)
		 //  p[nn] = inptr[nn];
   //}
   memmove(inptr+dif, inptr, sizeof(inbuf)-500-nchars-dif);  // shift open space in input buffer
   inptr -= slen;                // reset input pointer to start of replaced text
   memcpy(inptr, body, mlen);    // copy macro body in place over identifier
   //for (nn = 0; nn < mlen; nn++)
	  // inptr[nn] = body[nn];
   //printf("inptr:%.60s\r\n", inptr);
   //getchar();
}
