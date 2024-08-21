#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "fpp.h"

//#include "fwstr.h"

char *rtrim(char *str);
extern int inst;
int rep_depth;
int mac_depth;

static int gmb_inst = 0;

/* ---------------------------------------------------------------------------
   char *SubArg(bdy, n, sub);
   char *bdy;  - pointer to macro body (pass NULL to free static buffer)
   int n;      - parameter number to substitute
   char *sub;  - substitution string

      Searches the macro body a substitutes the passed parameter for the
   placeholders in the macro body.
--------------------------------------------------------------------------- */

char *SubMacroArg(char *bdy, int n, char *sub, int rpt)
{
  static buf_t* buf = NULL;
	char *s = sub;
	int stringize = 0;
  char numbuf[20];
  char* substr;
  char ch;
  int in_quote = 0;

  if (bdy == NULL) {
    free_buf(buf);
    return (NULL);
  }

  if (buf == NULL)
    buf = new_buf();

  // Reset buffer. Start at the start of the buffer.
  if (buf->buf) {
    memset(buf->buf, 0, buf->size);
    buf->pos = 0;
  }

  substr = sub;
  if (n < 0) {
    ch = '@';
    if (rep_depth > 0) {
      memset(numbuf, 0, sizeof(numbuf));
      sprintf_s(numbuf, sizeof(numbuf), "@_%.6s", sub);
      substr = numbuf;
    }
  }
  else {
    ch = n + '0';
  }

  for (; *bdy; bdy++)
  {
		stringize = 0;
    in_quote = 0;
    if (bdy[0] == '#' && bdy[1] == '' && bdy[2] == ch) {
      stringize = 1;
      char_to_buf(&buf, '\x15');
    }
    else if (bdy[0] == '' && bdy[1] == ch) {
      // Copy substitution to output buffer
      for (s = substr; *s; s++) {
        if (stringize) {
          if (s[0] == '"') {
            in_quote = !in_quote;
            char_to_buf(&buf, '\\');
          }
          else if (s[0] == '\\' && in_quote)
            char_to_buf(&buf, '\\');
        }
        char_to_buf(&buf, s[0]);
      }
      if (stringize)
        char_to_buf(&buf, '\x15');
      bdy++;
      continue;
    }
    char_to_buf(&buf, bdy[0]);
  }
  char_to_buf(&buf, '\n');
  return (buf->buf);
}


static int sub_id(def_t* def, char* id, buf_t** buf, char* p1, char* p2)
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

static void proc_instvar(buf_t** buf)
{
  char mk[20];

  inptr += 5;
  /*
  mk[0] = '';
  mk[1] = '@';
  mk[2] = 0;
  */
  sprintf_s(mk, sizeof(mk), "@");
  insert_into_buf(buf, mk, 0);
}

static int proc_parm(buf_t** buf, int nparm)
{
  char c;
  char* p1, * p2;
  char mk[3];

  p1 = inptr;
  c = NextCh();
  if (isdigit(p1[1])) {
    while (isdigit(c = NextCh()));
    c = (char)strtoul(&p1[1], &inptr, 10);
    if (c <= nparm) {
      p1++;
      p2 = inptr;
      mk[0] = '';
      mk[1] = '0' + c;
      mk[2] = 0;
      insert_into_buf(buf, mk, 0);
      return (1);
    }
  }
  return (0);
}

/* ---------------------------------------------------------------------------
   Description :
      Gets the body of a macro. Macro parameters are matched up with their
   positions in the macro. A $<number> (as in $1, $2, etc) is substituted
   in the macro body in place of the parameter name (we don't actually
   care what the parameter name is).

   There are two options for processing macro definitions.
   The first ends the macro when a newline is hit, unless the '\'
   character is present on the line. Used for "C" #define
   The second automatically includes newlines as part of the macro and
   end when a ".endm" is encountered.
      Macros continued on the next line with '\' are also processed. The
   last newline is removed from the macro.

   Parameters:
     (SDef*) - definition to get the body of
     (int) - processing option (0="C" define)
     (int) - non-zero indicates a repeat is being processed.
---------------------------------------------------------------------------- */

buf_t *GetMacroBody(def_t* def, int opt, int rpt)
{
  char *id = NULL, *p2, * p3;
  buf_t* buf;
  int c = 0, nparm;
  int InQuote = 0;
  int count = sizeof(buf)-1;
  int64_t ndx1 = 0;

  gmb_inst++;
  buf = new_buf();
  inptr;
  inbuf;

  if (def->nArgs <= 0)
    nparm = 0;
  else
    nparm = def->nArgs;

  if (opt==0)
    SkipSpaces();
  while(1)
  {
    p3 = inptr;
    // First search for an identifier to substitute with parameter
    id = NULL;
    if (def->nArgs > 0 && def->parms) {
      while (PeekCh() == ' ' || PeekCh() == '\t')
        char_to_buf(&buf, NextCh());

      if (syntax == CSTD) {
        ndx1 = inptr - inbuf->buf;
        id = GetIdentifier();
        p2 = inptr;
        inbuf;
        if (id)
          sub_id(def, id, &buf, inbuf->buf + ndx1, p2);
        else
          inptr = inbuf->buf + ndx1;      // reset inptr if no identifier found
      }
      else if (syntax == ASTD) {
        if (PeekCh() == '\\') {
          ndx1 = inptr - inbuf->buf;
          NextCh();
          id = GetIdentifier();
          p2 = inptr;
          inbuf;
          if (id)
            sub_id(def, id, &buf, inbuf->buf + ndx1, p2);
          else
            inptr = inbuf->buf + ndx1;      // reset inptr if no identifier found
        }
      }
    }

    if (id == NULL) {
      c = NextCh();
      if (c == '"')
        InQuote = !InQuote;
      if (!InQuote) {
        if (syntax==CSTD) {
          if (c == '/') {
            c = NextCh();
            // Block comment ?
            if (c == '*') {
              while (c > 0) {
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
              while (c != '\n' && c > 0) c = NextCh();
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
        }
        else if (syntax == ASTD) {
          if (c == '#') {
            while (c != '\n' && c > 0) c = NextCh();
            if (c > 0) {
              unNextCh();
              goto jmp1;
            }
          }
          else if (c == '\\') {
            if (PeekCh() == '@') {
              proc_instvar(&buf);
              continue;
            }
            else if (proc_parm(&buf, nparm))
              continue;
          }
        }
        if (c == '\\' && opt != 1)  // check for continuation onto next line
        {
          while (c != '\n' && c > 0) c = NextCh();
          if (c > 0) {
            SkipSpaces();  // Skip leading spaces on next line
            continue;
          }
        }
      }
      if (opt != 1) {
        if (c == '\n' || c < 1) {
          if (InQuote)
            err(25);
          break;
        }
      }
      else if (c < 1) {
        if (InQuote)
          err(25);
        break;
      }
      // Processing a multi-line macro? Look for ".endm"
      if (opt == 1) {
        // Dispatch any directives encountered while getting the body.
        if (c == syntax_ch() && !InQuote) {
          inptr;
          inbuf;
          if ((directive(NULL) >> 8) == DIR_END)  // endm or endr
            goto jmp1;
          continue;
        }
      }
      char_to_buf(&buf, c);
    }
    if (inptr == p3)
      if ((c = NextCh()) < 1)
        break;
   }
 jmp1:;
  if (buf->buf) {
//    rtrim(buf->buf);    // Trim off trailing spaces.
    if (opt == 1 && 0)
      char_to_buf(&buf, '\n');
  }
  else
    buf->buf = _strdup("");
  if (!rpt && opt != 1)
    dendm(0);
  return (buf);
}


/* ---------------------------------------------------------------------------
   Description :
      Gets an argument to be substituted into a macro body. Note that the
   round bracket nesting level is kept track of so that a comma in the
   middle of an argument isn't inadvertently picked up as an argument
   separator.

   Side Effects:
     Modifies the global input pointer.

   Parameters:
     (none)

   Returns:
     (char *) - a pointer to the argument. Storage is allocated with
                _strdup() so it will need to be freed (free()).
--------------------------------------------------------------------------- */

char *GetMacroArg()
{
  int Depth = 0;
  int c;
  char argbuf[4000];
  char *argstr = argbuf;
  int InQuote = 0;

  SkipSpaces();
  memset(argbuf,0,sizeof(argbuf));
  while(argstr - argbuf < sizeof(argbuf)-1)
  {
    c = NextCh();
    if (c < 1) {
        if (Depth > 0)
          err(16);
        break;
    }
    if (c == '"')
      InQuote = !InQuote;
    if (!InQuote) {
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
    }
    if (c == '\n')
      break;
    *argstr++ = c;       // copy input argument to argstr.
  }
  *argstr = '\0';         // NULL terminate buffer.
  if (argbuf[0])
	  if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
  return (strip_quotes(argbuf));
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
     SkipSpaces();
     if (PeekCh() == '\n' && syntax == ASTD) {
        break;
     }
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
        parmlist[count-1]->def = GetMacroArg();
      }
      if (c != ',' && count > 0) {
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

/* ---------------------------------------------------------------------------
   Description :
      Used during the definition of a repeat to get the associated parameter
   list.

   Parameters:
      (arg_t *)[] - a pointer to an array of pointers to hold the parameters.
                    The array should be large enough to hold the maximum
                    number of parameters (MAX_MACRO_ARGS)
      (int) - processing option. A value of 1 will allow variable argument
              lists and treat a newline char as the end of the list.

   Modifies:
      The global text input pointer.

   Returns
      (int) - a count of the number of parameters. The count will be
   negative to indicate a variable argument list is present.
---------------------------------------------------------------------------- */

int GetReptArgList(arg_t* arglist[], int opt)
{
  int Depth = 0, c, count;
  int vargs = 0;

  count = 0;
  while (1)
  {
    do {
      c = NextNonSpace(0);
      if (c == '\\')
        ScanPastEOL();
    } while (c == '\\');
    if (c == 0)
      break;
    if (opt == 1 && c == '\n')
      break;
    if (c == ')') {   // we've gotten our last parameter
      unNextCh();
      break;
    }
    unNextCh();
    arglist[count]->def = GetMacroArg();
    count++;
    c = PeekCh();
    if (c == '\n' || c == 0)
      break;
    if (c != ',') {
      err(16);
      goto errxit;
    }
    c = NextCh();
  }
errxit:;
  return (count);
}

/* -----------------------------------------------------------------------------
   Description :
      Copies a macro into the input buffer. Resets the input buffer pointer
   to the substitution point.

   Parameters:
      (char *) body - the text body of the macro
      (int) slen; - the number of characters being substituted

   Returns:
     (none)
----------------------------------------------------------------------------- */

void SubMacro(char *body, int slen)
{
  int64_t mlen, dif;
  int64_t nchars;

  mlen = strlen(body);          // macro length
  dif = mlen - slen;
  nchars = inbuf->size - (inptr-inbuf->buf);         // calculate number of characters that could be remaining

  // If the text is not changing, we want to advance the text pointer.
  // Prevents the substitution from getting stuck in a loop.
  if (strncmp(inptr-slen, body, mlen) == 0) {
    inptr -= slen;           // reset input pointer to start of replaced text
    inptr++;                 // and advance by one
    return;
  }
  if (dif > 0)
    memmove(inptr+dif, inptr, nchars-dif);  // shift open space in input buffer
  inptr -= slen;                // reset input pointer to start of replaced text
  memcpy(inptr, body, mlen);    // copy macro body in place over identifier
  if (dif < 0)
    memmove(inptr + mlen, inptr - dif + mlen, nchars - dif);
}
