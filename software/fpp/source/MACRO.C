#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
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


static int sub_id(SDef* def, char* id, buf_t** buf, char* p1, char* p2)
{
  int ii;
  char mk[3];
  char idbuf[500];

  for (ii = 0; ii < def->nArgs; ii++)
    if (def->parms[ii]->name)
      if (strcmp(def->parms[ii]->name, id) == 0) {
        mk[0] = '';
        mk[1] = '0' + (char)ii;
        mk[2] = 0;
        insert_into_buf(buf, mk, 0);
        return (1);
      }
  // if the identifier was not a parameter then just copy it to
  // the macro body
  if (p2 - p1 > sizeof(id))
    exit(0);
  strncpy_s(idbuf, sizeof(idbuf), p1, p2 - p1);
  id[p2 - p1] = 0;
  insert_into_buf(buf, idbuf, 0);
  return (0);
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

buf_t *GetMacroBody(SDef* def)
{
   char *id = NULL, *p2;
   buf_t* buf;
   int c, nparm;
   int InQuote = 0;
   int count = sizeof(buf)-1;
   char ch[4];
   int64_t ndx1;

   buf = new_buf();

   if (def->nArgs <= 0)
     nparm = 0;
   else
     nparm = def->nArgs;

   SkipSpaces();
   while(1)
   {
      // First search for an identifier to substitute with parameter
      if (def->nArgs > 0 && def->parms) {
         while (PeekCh() == ' ' || PeekCh() == '\t') {
           ch[0] = NextCh();
           ch[1] = 0;
           insert_into_buf(&buf, ch, 0);
         }
         ndx1 = inptr - inbuf->buf;
         id = GetIdentifier();
         p2 = inptr;
         if (id) 
           sub_id(def, id, &buf, inbuf->buf + ndx1, p2);
         else
           inptr = inbuf->buf + ndx1;    // reset inptr if no identifier found
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
                     continue;
                  }
                  else
                     err(24);
               }
               // Comment to EOL ?
               else if (c == '/') {
                  while(c != '\n' && c > 0) c = NextCh();
                  if (c > 0) {
                    unNextCh();
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
         ch[0] = c;
         ch[1] = 0;
         insert_into_buf(&buf, ch, 0);
      }
   }
 jmp1:
   if (buf->buf)
     rtrim(buf->buf);    // Trim off trailing spaces.
   else
     buf->buf = _strdup("");
   return (buf);
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

int GetMacroParmList(arg_t *parmlist[])
{
   char *id;
   int Depth = 0, c, count;
   int vargs = 0;

   count = 0;
   while(count < MAX_MACRO_ARGS)
   {
     /*
     if (PeekCh() == '"') {
       memset(buf2, 0, sizeof(buf2));
       NextCh();
       // Copy parameter string to buffer.
       for (nn = 0; nn < sizeof(buf2) - 1; nn++) {
         if (PeekCh() == 0)
           goto errxit;
         if (PeekCh() == '"') {
           NextCh();
           parmlist[count]->num = count;
           parmlist[count]->name = _strdup(buf2);
           count++;
           break;
         }
         buf2[nn] = PeekCh();
         NextCh();
       }
       continue;
     }
     */
     id = GetIdentifier();
      if (id) {
        if (strncmp(id, "...", 3) == 0) {
          vargs = 1;
        }
         if (count >= MAX_MACRO_ARGS) {
            err(15);
            goto errxit;
         }
         parmlist[count]->num = count;
         parmlist[count]->name = _strdup(id);
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
      if (c == '=') {
        parmlist[count-1]->def = _strdup(GetMacroArg());
      }
      if (c != ',') {
         err(16);
         goto errxit;
      }
   }
//   if (count < 1)
//      err(17);
   if (count < MAX_MACRO_ARGS)
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
   int64_t mlen, dif;
   int64_t nchars;

   mlen = strlen(body);          // macro length
   dif = mlen - slen;
   nchars = inptr-inbuf->buf;         // calculate number of characters that could be remaining
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
    // If the text is not changing, we want to advance the text pointer.
    // Prevents the substitution from getting stuck in a loop.
   if (strncmp(inptr-slen, body, mlen) == 0) {
     inptr -= slen;           // reset input pointer to start of replaced text
     inptr++;                 // and advance by one
     return;
   }
   if (dif > 0)
    memmove(inptr+dif, inptr, inbuf->size-500-nchars-dif);  // shift open space in input buffer
   inptr -= slen;                // reset input pointer to start of replaced text
   memcpy(inptr, body, mlen);    // copy macro body in place over identifier
   if (dif < 0)
     memmove(inptr + mlen, inptr - dif + mlen, inbuf->size - 500 - nchars - dif);
   //for (nn = 0; nn < mlen; nn++)
	  // inptr[nn] = body[nn];
   //printf("inptr:%.60s\r\n", inptr);
   //getchar();
}
