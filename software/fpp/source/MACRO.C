/*
// ============================================================================
//        __
//   \\__/ o\    (C) 1992-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
*/

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

static void copy_sub_to_buf(buf_t** buf, char *substr, int stringize)
{
  char* s;
  int in_quote = 0;

  for (s = substr; *s; s++) {
    if (stringize) {
      if (*s == '"') {
        in_quote = !in_quote;
        char_to_buf(buf, '\\');
      }
      else if (s[0] == '\\' && in_quote)
        char_to_buf(buf, '\\');
    }
    char_to_buf(buf, *s);
  }
  if (stringize)
    char_to_buf(buf, '\x15');
}

/* ---------------------------------------------------------------------------
   char *SubArg(bdy, n, sub);
   char *bdy;  - pointer to macro body (pass NULL to free static buffer)
   int n;      - parameter number to substitute
   char *sub;  - substitution string

      Searches the macro body a substitutes the passed parameter for the
   placeholders in the macro body.
--------------------------------------------------------------------------- */

char *SubMacroArg(char *bdy, int n, char *sub, arg_t* def)
{
  static buf_t* buf = NULL;
	char *s = sub;
	int stringize = 0;
  char numbuf[20];
  char* substr;
  char ch1,ch2;
  int in_quote = 0;
  int match;

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
    ch1 = '@';
    ch2 = '@';
    if (rep_depth > 0) {
      memset(numbuf, 0, sizeof(numbuf));
      sprintf_s(numbuf, sizeof(numbuf), "@_%.6s", sub);
      substr = numbuf;
    }
  }
  else {
    ch1 = (n / 10) + '0';
    ch2 = (n % 10) + '0';
  }

  for (; *bdy; bdy++)
  {
    in_quote = 0;
    if (syntax == ASTD) {
      if (bdy[0] == '\\' || bdy[0] == '\x14') {
        match = strncmp(&bdy[1], def->name, strlen(def->name)) == 0;
        if (match) {
          copy_sub_to_buf(&buf, substr, stringize);
          bdy += strlen(def->name);
        }
        else {
          char_to_buf(&buf, '\\');
        }
        stringize = 0;
        continue;
      }
      else if (bdy[0] == '#' && (bdy[1] == '\\' || bdy[1] == '\x14')) {
        stringize = 1;
        char_to_buf(&buf, '\x15');
        continue;
      }
      char_to_buf(&buf, bdy[0]);
    }
    else {
      if (bdy[0] == '#' && strncmp(&bdy[1], def->name, strlen(def->name)) == 0) {
        stringize = 1;
        copy_sub_to_buf(&buf, substr, stringize);
        stringize = 0;
        bdy += strlen(def->name);
        continue;
      }
      else if (strncmp(bdy, def->name, strlen(def->name)) == 0) {
        copy_sub_to_buf(&buf, substr, stringize);
        bdy += strlen(def->name) - 1;
        continue;
      }
      /*
      // Use a marker character (x15) to indicate where quotation marks should
      // appear in the output. They will be changed to quotes by SubMacro().
      if (bdy[0] == '#' && bdy[1] == '' && bdy[2] == ch1 && bdy[3] == ch2) {
        stringize = 1;
        char_to_buf(&buf, '\x15');
        continue;
      }
      else if (bdy[0] == '' && bdy[1] == ch1 && bdy[2] == ch2) {
        // Copy substitution to output buffer. If stringizing \ is placed before
        // quotation marks and escape characters in a quote.
        copy_sub_to_buf(&buf, substr, stringize);
        stringize = 0;
        bdy += 2;
        continue;
      }
      */
      char_to_buf(&buf, bdy[0]);
    }
  }
//  char_to_buf(&buf, '\n');
  return (buf->buf);
}


/* ---------------------------------------------------------------------------
--------------------------------------------------------------------------- */

static int sub_id(def_t* def, char* id, buf_t** buf, char* p1, char* p2)
{
  int ii;
  char mk[4];
  char idbuf[500];

  if (syntax == ASTD) {
    char_to_buf(buf, '\\');
    insert_into_buf(buf, id, 0);
    return(0);
  }
  else {
    for (ii = 0; ii < def->nArgs; ii++)
      if (def->parms[ii]->name)
        if (strcmp(def->parms[ii]->name, id) == 0) {
          mk[0] = '';
          mk[1] = '0' + (char)(ii / 10);
          mk[2] = '0' + (char)(ii % 10);
          mk[3] = 0;
          insert_into_buf(buf, mk, 0);
          return (1);
        }
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
--------------------------------------------------------------------------- */

static void proc_instvar(buf_t** buf)
{
  char mk[20];

  inptr += 5;
  /*
  mk[0] = '';
  mk[1] = '@';
  mk[2] = 0;
  */
  sprintf_s(mk, sizeof(mk), "@@");
  insert_into_buf(buf, mk, 0);
}

/* ---------------------------------------------------------------------------
--------------------------------------------------------------------------- */

static int proc_parm(buf_t** buf, int nparm)
{
  int c;
  char* p1, * p2;
  char mk[4];

  p1 = inptr;
  c = NextCh();
  if (isdigit(p1[1])) {
    while (isdigit(c = NextCh()));
    c = (int)strtoul(&p1[1], &inptr, 10);
    if (c <= nparm) {
      p1++;
      p2 = inptr;
      mk[0] = '';
      mk[1] = '0' + (char)(c / 10);
      mk[2] = '0' + (char)(c % 10);
      mk[3] = 0;
      insert_into_buf(buf, mk, 0);
      return (1);
    }
  }
  return (0);
}

char* GetLine()
{
  int ii;
  char buf[MAXLINE];
  static char* ptr = NULL;

  if (ptr == NULL || *ptr == 0) {
    ProcLine();
    ptr = inbuf->buf;
  }
  for (ii = 0; ptr[ii] && ptr[ii] != '\n'; ii++)
    buf[ii] = ptr[ii];
  buf[ii] = 0;
  if (ptr[ii] == '\n')
    ptr = &ptr[ii+1];
  return (_strdup(buf));
}

/* ---------------------------------------------------------------------------
   Dead Code - see mac_collect

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

buf_t *GetMacroBody(def_t* def, int opt, int rpt, int dodir)
{
  char *id = NULL, *p2, * p3, * p5;
  buf_t* buf;
  int c = 0, nparm, n;
  int InQuote = 0;
  int count = sizeof(buf)-1;
  int64_t ndx1 = 0;
  pos_t* pos;
  char* pl = NULL;
  int ocollect = 0;
  buf_t* ibuf;
  buf_t* tbuf;
  pos_t id_pos;
  char* p4 = NULL;

  gmb_inst++;
  buf = def->body;
  inptr;
  inbuf;

  if (def->nArgs <= 0)
    nparm = 0;
  else
    nparm = def->nArgs;

  ibuf = new_buf();
  tbuf = new_buf();
  pos = GetPos();
  c = '\n';
  p5 = "";
  p4 = "";
  if (opt==0)
    SkipSpaces();
  while(1)
  {
    id_pos.bufpos = 0;
    id_pos.file = NULL;
    if (c == '\n') {
      c = NextCh();
      if (c == 0)
        break;
      unNextCh();
      ibuf = clone_buf(inbuf);
      def->body = ibuf;
      count = 0;
      do {
        p5 = p4;
        for (n = 0; n < def->nArgs; n++) {
          p4 = SubMacroArg(def->body->buf, n, def->parms[n]->def, def->parms[n]);
          while (def->body->size < strlen(p4))
            enlarge_buf(&def->body);
          strcpy_s(def->body->buf, def->body->size, p4);
        }
        if (p4) {
          insert_into_buf(&tbuf, p4, 0);
        }
        SearchAndSubBuf(&tbuf, 1, NULL);
        count++;
      } while (strcmp(p4, p5) && count < 1000);
    }
//    SubParmMacro(def, syntax == ASTD, &id_pos);
    p3 = inptr;
    // First search for an identifier to substitute with parameter
    id = NULL;
    if (def->nArgs > 0 && def->parms) {
      while (PeekCh() == ' ' || PeekCh() == '\t')
        char_to_buf(&tbuf, NextCh());

      if (syntax == CSTD) {
        ndx1 = inptr - inbuf->buf;
        id = GetIdentifier();
        p2 = inptr;
        inbuf;
        if (id)
          sub_id(def, id, &tbuf, inbuf->buf + ndx1, p2);
        else
          set_input_buf_ptr(ndx1);      // reset inptr if no identifier found
      }
      else if (syntax == ASTD) {
        if (PeekCh() == '\\') {
          ndx1 = inptr - inbuf->buf;
          NextCh();
          id = GetIdentifier();
          p2 = inptr;
          inbuf;
          if (id)
            sub_id(def, id, &tbuf, inbuf->buf + ndx1, p2);
          else
            set_input_buf_ptr(ndx1);      // reset inptr if no identifier found
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
              proc_instvar(&tbuf);
              continue;
            }
            else if (proc_parm(&tbuf, nparm))
              continue;
          }
        }
        if (c == '\\' && opt != 1)  // check for continuation onto next line
        {
          while (c != '\n' && c > 0) c = NextCh();
          if (c > 0) {
//            SkipSpaces();  // Skip leading spaces on next line
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
      if (opt == 1 && dodir) {
        // Dispatch any directives encountered while getting the body.
        if (c == syntax_ch() && !InQuote) {
          inptr;
          inbuf;
          switch (directive(NULL, NULL) >> 8) {  // endm or endr
          case DIR_ENDM:
          case DIR_ENDR:
            goto jmp1;
          }
          continue;
        }
      }
      
      char_to_buf(&tbuf, c);
    }
    if (inptr == p3)
      if ((c = NextCh()) < 1)
        break;
  }
jmp1:;
  if (tbuf->buf) {
//    rtrim(buf->buf);    // Trim off trailing spaces.
    if (opt == 1 && 0)
      char_to_buf(&tbuf, '\n');
  }
  else {
    tbuf->buf = _strdup("");
    tbuf->size = 1;
  }
  if (!rpt && opt != 1)
    dendm(0, p4);
  return (tbuf);
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
  int c, ii;
  char argbuf[4000];
  char numbuf[50];
  char *argstr = argbuf;
  int InQuote = 0;
  int64_t ex, n1, n2;
  int64_t undef = 0;
  char* id;

  SkipSpaces();
  memset(argbuf,0,sizeof(argbuf));
  inptr;
  inbuf;
  while(argstr - argbuf < sizeof(argbuf)-1)
  {
    if (peek_eof())
      break;
    SkipSpaces();
    if (PeekCh() == '"') {
      InQuote = !InQuote;
      NextCh();
    }
    SkipSpaces();
    n1 = get_input_buf_ndx();
    undef = 0;
    ex = expeval(&undef);
    n2 = get_input_buf_ndx();
    // If the expression could not be evaluated, it may be a text string. Fetch
    // an identifier and copy it verbatium. If it's not an identifier it is some
    // other text, just let it copy a char at a time.
    if (undef) {
      set_input_buf_ptr(n1);
      id = GetIdentifier();
      n2 = get_input_buf_ndx();
      if (id) {
        for (ii = 0; id[ii] && ii < 4000 - (argstr - argbuf); ii++)
          *argstr++ = id[ii];
      }
    }
    // Here, it was a defined expression. Copy the value to the arg buffer.
    else {
      if (n1 != n2) {
        // If got just a single character, is it blank?
        if (n2 - n1 == 1 && (
          isspace(inbuf->buf[n1]) ||
          inbuf->buf[n1] == ',' ||
          inbuf->buf[n1] == LF ||
          inbuf->buf[n1] == ETB ||
          inbuf->buf[n1] == 0))
          break;
        sprintf_s(numbuf, sizeof(numbuf), "%lld", ex);
        for (ii = 0; numbuf[ii] && ii < sizeof(numbuf) - 1; ii++)
          *argstr++ = numbuf[ii];
      }
    }
    if (peek_eof())
      break;
    c = NextCh();
    if (c == '"') {
      InQuote = !InQuote;
      c = NextCh();
    }
    if (!InQuote) {
      /*
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
      */
    }
    if (c == ')') {
      unNextCh();
      c = PeekCh();
      break;
    }
    if (peek_eof()) {
      unNextCh();
      c = PeekCh();
      break;
    }
    if (c == ',' && !InQuote) {
      unNextCh();
      c = PeekCh();
      break;
    }
    if (c == '\n') {
      unNextCh();
      c = PeekCh();
      break;
    }
    *argstr++ = c;       // copy input argument to argstr.
  }
  if (InQuote)
    err(0);             // missing "
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
      (int) number of parameters, negative if a variable arg list is present
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
    inptr;
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
      c = PeekCh();
    }
    // End of input?
    if (c == 0 || c == ETB)
      break;
    // or end of list?
    if (c == ')') {
      unNextCh();
      break;
    }
    if (c != ',' && count > 0) {
      if (c == '\n' || peek_eof())
        break;
      err(16);
      goto errxit;
    }
    c = PeekCh();
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

  inbuf;
  inptr;
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

void SubMacro(buf_t *body, int slen, int stringize)
{
  int64_t mlen, dif, n1;
  int64_t nchars;
  int nn, mm;
  int in_quote = 0;

  if (body == NULL)
    return;

  check_buf_ptr(inbuf, inptr);
  mlen = body->pos;     // macro length

  // Check for stringize
  // First adjust the substitution length by the number of characters inserted
  // by the stringize.
  if (stringize) {
    mlen++; // account for preceeding '#'
    inptr--;
    for (nn = 0; body->buf[nn]; nn++) {
      if (body->buf[nn] == '"') {
        in_quote = !in_quote;
        mlen++;
      }
      else if (body->buf[nn] == '\\' && in_quote)
        mlen++;
    }
  }

  dif = mlen - slen;
  nchars = inbuf->size - get_input_buf_ndx();         // calculate number of characters that could be remaining
  if (nchars > inbuf->size || nchars < 0)
    return;

  // Check if the input buffer is large enough
  while (dif > nchars) {
    n1 = get_input_buf_ndx();
    enlarge_buf(&inbuf);
    set_input_buf_ptr(n1);
    nchars = inbuf->size - get_input_buf_ndx();
  }

  // If the text is not changing, we want to advance the text pointer.
  // Prevents the substitution from getting stuck in a loop.
  if (strncmp(inptr-slen, body->buf, mlen) == 0) {
    inptr -= slen;           // reset input pointer to start of replaced text
    inptr++;                 // and advance by one
    return;
  }

  inptr -= slen;                // reset input pointer to start of replaced text

  // shift open space in input buffer
  if (dif > 0) {
    //memmove(inptr + dif, inptr, nchars - dif);
    
    for (nn = inbuf->size - dif - 1; nn > get_input_buf_ndx(); nn--)
      inbuf->buf[nn+dif] = inbuf->buf[nn];
    
  }

  // Copy body to buffer.
  in_quote = 0;
  for (mm = nn = 0 ; body->buf[nn]; nn++) {
    if (stringize) {
      if (body->buf[nn] == '"') {
        in_quote = !in_quote;
        inptr[mm] = '\\';
        mm++;
      }
      else if (body->buf[nn] == '\\' && in_quote) {
        inptr[mm] = '\\';
        mm++;
      }
    }
    inptr[mm] = body->buf[nn];
    mm++;
  }

  //memcpy(inptr, body, mlen);    // copy macro body in place over identifier
  if (dif < 0)
    memmove(inptr + mlen, inptr - dif + mlen, nchars - dif);
}

/* -----------------------------------------------------------------------------
   Description :
      Collect up the lines for a macro definition. Builds up a buffer full of
   lines from the input until an 'endm' is seen. Then the buffer is passed
   back to the macro processing code.

   Parameters:
      (buf_t**) - pointer to buffer pointer used to collect the lines
      (int opt) - stlye, "C" style macros or assembler

   Returns:
      (none)  - (a pointer to an allocated buffer is returned in the first
                parameeter).
----------------------------------------------------------------------------- */

void mac_collect(buf_t** buf, int opt)
{
  int depth = 1;
  char* p;
  char ch;
  int ii;
  int ocollect;
  char* pos = NULL;
  int64_t nb;

  SkipSpaces();
  nb = get_input_buf_ndx();
  switch (opt) {
    // For "C", defines (macros) are continued on the next line with a \
    // Otherwise they end at the end of the line.
    // set and equ are opt 2
  case 0:
    do {
      SkipSpaces();
//      insert_into_buf(buf, inptr, 0);
      for (ch = NextCh(); ch && ch != LF && !peek_eof(); ch = NextCh())
        char_to_buf(buf, ch);
      p = (*buf)->buf;
      ii = strlen(p);
      // trim trailing line-feeds
      while (p[ii - 1] == LF && ii > 0) {
        p[ii - 1] = 0;
        --ii;
      }
      // and trailing spaces
      rtrim(p);
      ii = strlen(p);
      if (p[ii - 1] != '\\') {
        mac_depth--;
        return;
      }
      do {
        ii = NextCh();
      } while (ii != LF && ii != 0 && ii != ETB);
    } while (ii);
    mac_depth--;
    return;

  // A "normal" multi-line macro.
  case 1:
    ocollect = collect;
    collect = 1;
    NextCh();
    unNextCh();
    do
    {
      // Get a line and ignore it unless it's a preprocessor line
      while (NextNonSpace(1) != syntax_ch())
        ;
      switch (directive_id(inptr-1, &pos) >> 8) {
      // For any if/ifdef/ifndef encountered increment the depth.
      case DIR_MACR:
        depth++;
        mac_depth++;
        err(32, "");    // nested macro warning
        break;

      // Break when an endm is encountered at the right level.
      case DIR_ENDM:
        pos;
        ch = *pos;
        *pos = 0;
        mac_depth--;
        if (depth == 1) {
          collect = ocollect;
          insert_into_buf(buf, inbuf->buf + nb, 0);
          *pos = ch;
          return;
        }
        *pos = ch;
        depth--;
        break;
      }
    } while (!peek_eof());
    collect = ocollect;
    insert_into_buf(buf, inbuf->buf + nb, 0);
    err(33);  // missing endm
    return;

  // set and equ
  case 2:
    insert_into_buf(buf, GetMacroArg(), 0);
    mac_depth--;
    return;

  }
}


