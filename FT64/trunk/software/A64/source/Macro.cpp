#include "stdafx.h"

// ---------------------------------------------------------------------------
//   char *SubArg(bdy, n, sub);
//   char *bdy;  - pointer to macro body
//   int n;      - parameter number to substitute
//   char *sub;  - substitution string
//
//      Searches the macro body a substitutes the passed parameter for the
//   placeholders in the macro body.
// ---------------------------------------------------------------------------

char *Macro::SubArg(char *bdy, int n, char *sub)
{
   static char buf[16000];
   char *s = sub, *o = buf;

   ZeroMemory(buf, sizeof(buf));
   for (o = buf; *bdy; bdy++, o++)
   {
      if (*bdy == '' && *(bdy+1) == (char)n + '0') {  // we have found parameter to sub
         // Copy substitution to output buffer
         for (s = sub; *s;)
            *o++ = *s++;
         --o;
         bdy++;
         continue;
      }
      *o = *bdy;
   }
   return buf;
}

// ---------------------------------------------------------------------------
//   Description :
//      Gets the body of a macro. All macro bodies must be < 2k in size. Macro
//   parameters are matched up with their positions in the macro. A $<number>
//   (as in $1, $2, etc) is substituted in the macro body in place of the
//   parameter name (we don't actually care what the parameter name is).
//      Macros continued on the next line with '\' are also processed. The
//   newline is removed from the macro.
// ----------------------------------------------------------------------------

char *Macro::GetBody(char *parmlist[])
{
   char *b, *id = NULL, *p1, *p2;
   static char buf[16000];
   int ii, found, c;
   int InQuote = 0;
   int count = sizeof(buf)-1;

   SkipSpaces();
   memset(buf, 0, sizeof(buf));
   for (b = buf; count >= 0; b++, --count)
   {
      // First search for an identifier to substitute with parameter
      if (parmlist) {
         while (*inptr == ' ' || *inptr == '\t') {
            *b++ = *inptr;
			inptr++;
            count--;
            if (count < 0)
               goto jmp1;
         }
         p1 = inptr;
         id = getIdentifier();
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
         c = *inptr;
		 inptr++;
         if (c == '"')
            InQuote = !InQuote;
         if (!InQuote) {
            if (c == '/') {
				c = *inptr;
				inptr++;
               c = NextCh();
               // Block comment ?
               if (c == '*') {
                  while(c > 0) {
					  c = *inptr;
					  inptr++;
                     if (c == '*') {
						 c = *inptr;
						 inptr++;
                        if (c == '/')
                           break;
						--inptr;
                     }
                  }
                  if (c > 0) {
                     --b;
                     continue;
                  }
                  else
					  printf("End of line in comment. %d\n", lineno);
               }
               // Comment to EOL ?
               else if (c == '/') {
				   while(c != '\n' && c > 0) { c = *inptr; inptr++; }
                  if (c > 0) {
                     --b;
                     ++count;
                     goto jmp1;
                  }
               }
			   else {
				   c = '/';
                  --inptr;
			   }
            }
            else if (c == '\\')  // check for continuation onto next line
            {
				while (c != '\n' && c > 0) { c= *inptr; inptr++}
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
				printf("End of file in comment. %d\n", lineno);
            break;
         }
         *b = c;
      }
   }
jmp1:
   if (count < 0)
	   printf("Expanded macro is too large. %d\n", lineno);
   *b = 0;
   rtrim(buf);    // Trim off trailing spaces.
   return buf;
}


// ---------------------------------------------------------------------------
//   Description :
//      Gets an argument to be substituted into a macro body. Note that the
//   round bracket nesting level is kept track of so that a comma in the
//   middle of an argument isn't inadvertently picked up as an argument
//   separator.
// ---------------------------------------------------------------------------

char *Macro::GetArg()
{
   int Depth = 0;
   int c;
   static char argbuf[4000];
   char *argstr = argbuf;

   SkipSpaces();
   ZeroMemory(argbuf,sizeof(argbuf));
   while(1)
   {
	   if (argstr-argbuf > sizeof(argbuf)-2) {
		   printf("Macro argument too large %d. Is a ')' missing ?\n",lineno);
		   break;
	   }
      c = *inptr;
	  inptr++;
      if (c < 1) {
         if (Depth > 0)
            err(16);
         break;
      }
      if (c == '(')
         Depth++;
      else if (c == ')') {
         if (Depth < 1) {  // check if we hit the end of the arg list
            --inptr;
            break;
         }
         Depth--;
      }
      else if (Depth == 0 && c == ',') {   // comma at outermost level means
         --inptr;
         break;                           // end of argument has been found
      }
      *argstr++ = c;       // copy input argument to argstr.
   }
   *argstr = '\0';         // NULL terminate buffer.
   if (argbuf[0])
	   if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
   return argbuf[0] ? argbuf : NULL;
}


// ---------------------------------------------------------------------------
//   Description :
//      Used during the definition of a macro to get the associated parameter
//   list.
//
//   Returns
//      pointer to first parameter in list.
// ----------------------------------------------------------------------------

int Macro::GetParmList(char *parmlist[])
{
   int id;
   int Depth = 0, c, count;

   count = 0;
   while(1)
   {
      id = getIdentifier();
      if (id!=0) {
         if (count >= 20) {
			 printf("Too many macro parameters %d.\n", lineno);
             goto errxit;
         }
         parmlist[count] = _strdup(lastid);
         if (parmlist[count] == NULL)
			 printf("Insufficient memory %d\n", lineno);
         count++;
      }
	  do {
			SkipSpaces();
			c = *inptr;
			inptr++;
			if (c=='\\') {
				ScanToEOL();
				inptr++;
			}
		}
		while (c=='\\');
      if (c == ')') {   // we've gotten our last parameter
         inptr--;
         break;
      }
      if (c != ',') {
		  printf("Expecting ',' in macro parameter list %d.\n", lineno);
         goto errxit;
      }
   }
//   if (count < 1)
//      err(17);
   if (count < 20)
      parmlist[count] = NULL;
errxit:;
   return count;
}


// -----------------------------------------------------------------------------
//   Description :
//      Copies a macro into the input buffer. Resets the input buffer pointer
//   to the start of the macro.
//
//   slen; - the number of characters being substituted
// -----------------------------------------------------------------------------

void Macro::Substitute(char *body, int slen)
{
   int mlen, dif, nchars;
   int nn;
   char *p;

   mlen = strlen(body);          // macro length
   dif = mlen - slen;
   nchars = inptr-masterFile;         // calculate number of characters that could be remaining
   memmove(inptr+dif, inptr, sizeof(masterFile)-500-nchars-dif);  // shift open space in input buffer
   inptr -= slen;                // reset input pointer to start of replaced text
   memcpy(inptr, body, mlen);    // copy macro body in place over identifier
}

