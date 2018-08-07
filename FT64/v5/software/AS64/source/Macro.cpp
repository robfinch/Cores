#include "stdafx.h"

// Substitute the argument list into the macro body.

char *Macro::SubArgs()
{
	char *buf, *bdy;
	char *p, *q;
	int ndx;
	static char ibuf[16000];

	bdy = body;
	ZeroMemory(ibuf, 16000);
	for (p = ibuf; *bdy; bdy++) {
		// If macro instance indicator found, substitute the instance number.
		if (*bdy == '@')
			p += sprintf_s(p, 16000 - (p-buf), "%d", inst);
		else if (*bdy == MACRO_PARM_MARKER) {
			if (isdigit(*(bdy+1))) {
				bdy++;
				ndx = *bdy - '0';
				if (ndx < args->count) {
					// Copy the argument from the arg list to the output buffer.
					for (q = args->arg[ndx]->text; *q; q++) {
						*p = *q;
						p++;
					}
				}
				printf("Not enough args for substitution. %d\r\n", lineno);
			}
			else {
				*p = *bdy;
				p++;
			}
		}
		// Not a parameter marker, just copy text to output.
		else {
			*p = *bdy;
			p++;
		}
	}
	buf = new char[strlen(ibuf)+1];
	memcpy(buf, ibuf, strlen(ibuf)+1);
	return (buf);
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


void Arg::Clear()
{
	ZeroMemory(text,sizeof(text));
}

// ---------------------------------------------------------------------------
//   Description :
//      Gets an argument to be substituted into a macro body. Note that the
//   round bracket nesting level is kept track of so that a comma in the
//   middle of an argument isn't inadvertently picked up as an argument
//   separator.
// ---------------------------------------------------------------------------

void Arg::Get()
{
   int Depth = 0;
   int c;
   char *argstr = text;

   SkipSpaces();
   ZeroMemory(text,sizeof(text));
   while(1)
   {
	   if (argstr-text > sizeof(text)-2) {
		   printf("Macro argument too large %d. Is a ')' missing ?\n",lineno);
		   break;
	   }
      c = *inptr;
	  inptr++;
      if (c < 1) {
         if (Depth > 0)
			printf("err16\r\n");
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
	  else if (Depth == 0 && (c=='\r' || c=='\n')) {
		  --inptr;
		  break;
	  }
      *argstr++ = c;       // copy input argument to argstr.
   }
//   if (argbuf[0])
//	   if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
   return;
}

void Arglist::Get()
{
	int nn;
	char lastch;

	for (nn = 0; nn < 10; nn++)
		args[nn]->Clear();
	for (nn = 0; nn < 10; nn++) {
		args[nn]->Get();
		if (*inptr != ',') {
			SkipSpaces();
			break;
		}
		inptr++;	// skip over ,
	}
	args->count = nn;
	while (*inptr) {
		if (*inptr==0)
			break;
		if (*inptr=='\n') {
			lineno++;
			inptr++;
			break;
		}
		inptr++;
	}
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

