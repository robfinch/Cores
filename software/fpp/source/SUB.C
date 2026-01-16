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
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "ht.h"
#include "fpp.h"

int spm_inst = 0;
int sub_pass = 0;

/* -----------------------------------------------------------------------------

   Description :
      Substitute a macro with arguments.
----------------------------------------------------------------------------- */

int SubParmMacro(def_t* p, int opt, pos_t* id_pos)
{
  int c, nArgs, ArgCount, xx, nn;
  arg_t Args[MAX_MACRO_ARGS];
  char* arg, * bdy, * tp;
  int varg;
  int need_cb = 0;
  int64_t so, n1;        // number of chars to substitute over
  pos_t* pndx;
  char numbuf[20];
  arg_t targ;
  arg_t targ2;
  char* p1, * p2;
  buf_t* vargs_buf = NULL;

  spm_inst++;

  // look for opening bracket indicating start of parameters
  // if the bracket isn't present then there are no arguments
  // being passed so don't expand the macro just give error
  // and continue

  // We can't just take a pointer difference because the input
  // routine will occasionally reset the pointer for new lines.
  inbuf;
  inptr;
  SearchAndSub(NULL, 0, NULL);
  check_buf_ptr(inbuf, inptr);
  bdy = _strdup(p->body->buf);                    // make a copy of the macro body
  if (opt == 0) {
    collect = 1;
    c = NextNonSpace(0);
    if (c != '(' && syntax==CSTD) {
      //      printf("p->name:%s^, p->body:%s^, p->nArgs:%d\n", p->name, p->body, p->nArgs);// _getch();
      //      unNextCh();
      //      err(13);    // expecting parameters
      return 1;
    }
    if (c == '(')
      need_cb = 1;
    else
      unNextCh();
    // get macro argument list
    nArgs = p->nArgs;
    varg = p->varg;
    for (ArgCount = 0; (ArgCount < nArgs || varg) && ArgCount < MAX_MACRO_ARGS; )
    {
      arg = GetMacroArg();
      nn = strlen(arg);
      if (nn == 0) {
        arg = p->parms[ArgCount]->def;
        if (arg == NULL)
          break;
      }

      Args[ArgCount].def = _strdup(arg);
      ArgCount++;

      // Search for next argument
      // If the previous argument was not present, continue processing args.
      c = NextNonSpace(0);
      if (c == '\n' || peek_eof()) {
        break;
      }
      if (syntax == CSTD && c != ',') {
        unNextCh();
        break;
      }
      if (c != ',') {
        unNextCh();
      }
      if (syntax == CSTD && c == '\\') {
        ScanPastEOL();
      }
    }
    // Pick up any trailing arguments not passed and default them.
    while (ArgCount < nArgs) {
      arg = p->parms[ArgCount]->def;
      Args[ArgCount].def = _strdup(arg);
      ArgCount++;
    }

    n1 = get_input_buf_ndx();

    if (need_cb) {
      if (c == '\n')
        NextCh();
      c = NextNonSpace(0);                       // Skip past closing ')'
      if (c != ')') {
        unNextCh();
        err(3);     // missing ')'
      }
      n1 = get_input_buf_ndx();
    }
    if (ArgCount != nArgs && !varg)                    // Check that argument count matches
      err(14, nArgs);
    collect = 0;

    // Substitute arguments into macro body
    for (xx = 0; (xx < ArgCount) /* || (p->varg && Args[xx].def)*/; xx++)          // we don't want to change the original
    {
      if (p->varg && xx >= nArgs - 1) {
        if (vargs_buf == NULL)
          vargs_buf = new_buf();
        targ.name = "__VA_ARGS__";
        insert_into_buf(&vargs_buf, Args[xx].def, 0);
        if (xx < ArgCount-1)
          char_to_buf(&vargs_buf, ',');
        else {
          tp = SubMacroArg(bdy, xx, vargs_buf->buf, &targ);        // Substitute argument into body
          free(bdy);                             // free old body
          bdy = _strdup(tp);                      // copy new version of body
          free_buf(vargs_buf);
        }
      }
      else {
        if (strcmp(p->parms[xx]->name, "..."))
          targ.name = p->parms[xx]->name;
        else
          targ.name = "__VA_ARGS__";
        targ.def = Args[xx].def;
        tp = SubMacroArg(bdy, xx, Args[xx].def, &targ);        // Substitute argument into body
        free(bdy);                             // free old body
        bdy = _strdup(tp);                      // copy new version of body
      }
    }
    p1 = &inbuf->buf[n1];
    p2 = &inbuf->buf[id_pos->bufpos];
    so = n1 - id_pos->bufpos;         // number of chars to substitute over
  }
  else if (opt == 1) {
    for (xx = 0; xx < p->nArgs || (p->varg && p->parms[xx]->def); xx++) {
      // Substitute arguments into macro body
      tp = SubMacroArg(bdy, xx, p->parms[xx]->def, p->parms[xx]);    // Substitute argument into body
      free(bdy);                             // free old body
      bdy = _strdup(tp);                      // copy new version of body
    }
//    so = 0;
    pndx = GetPos();
    if (id_pos->bufpos <= 0)
      so = -id_pos->bufpos;
    else
      so = pndx->bufpos - id_pos->bufpos;         // number of chars to substitute over
    free(pndx);
  }
  check_buf_ptr(inbuf, inptr);
  // Now handle the instance var.
  sprintf_s(numbuf, sizeof(numbuf), "%06d", spm_inst);
  targ2.name = "@";
  targ2.def = "1234";
  tp = SubMacroArg(bdy, -1, numbuf, &targ2);
  free(bdy);
  bdy = _strdup(tp);

  // Substitute macro into input stream
  check_buf_ptr(inbuf, inptr);
  if (p->abody == NULL)
    p->abody = new_buf();
  check_buf_ptr(inbuf, inptr);
  if (p->abody->buf && p->abody->alloc == 0)
    ;// free(p->abody->buf);
  check_buf_ptr(inbuf, inptr);
  p->abody->buf = bdy;
  p->abody->size = strlen(bdy) + 1;
  p->abody->pos = strlen(bdy);
  check_buf_ptr(inbuf, inptr);
  SubMacro(p->abody, so, 0);
  //  free(bdy);                                // free last strdup
  return (0);
}

/* -----------------------------------------------------------------------------
   Description:
      Substitute the instance variable into the current input position.

   Parameters:
      (none)

   Returns:
      (none)
----------------------------------------------------------------------------- */

static void sub_inst_var()
{
  char numbuf[20];
  char* tp;
  int ii;

  arg_t targ;
  buf_t* tbuf;
  targ.name = "@";
  spm_inst++;
  sprintf_s(numbuf, sizeof(numbuf), "%06d", spm_inst);
  tp = SubMacroArg("\\@", -1, numbuf, &targ);
  tbuf = new_buf();
  insert_into_buf(&tbuf, &tp[2], 0);
  tbuf->pos = strlen(&tp[2]);
  SubMacro(tbuf, 2, 0);
  free_buf(tbuf);
  for (ii = 0; ii < 7; ii++)
    NextCh();
  // Could just go like the following, as we know the characters got subbed.
  // inptr += 7;
  inptr;
  inbuf;
}

/* -----------------------------------------------------------------------------
   Description:
      Create an instance of a macro.

   Parameters:
      (def_t*) - pointer to macro definition var.
      (pos_t*) - position of the identifier in the text. Used to calculate
                 how many characters are being substituted over.
      (int)   - 1=stringize operator is present.

   Returns:
      (none)
----------------------------------------------------------------------------- */

static int inst_macro(def_t* p, int64_t idp, int stringize)
{
  int64_t pos;
  pos_t id_pos;

  id_pos.file = NULL;
  id_pos.bufpos = idp;

  inst++;
  if (fdbg) fprintf(fdbg, "macro %s\r\n", p->name);
  //    If this isn't a macro with parameters, then just copy
  // the body directly to the input. Overwrite the identifier
  // string
  if (p->nArgs > 0) {
    if (fdbg) fprintf(fdbg, "bef:%s", inbuf->buf);
    if (SubParmMacro(p, 0, &id_pos))
      return (0);
    if (fdbg) fprintf(fdbg, "aft:%s", inbuf->buf);
  }
  else {
    if (fdbg) fprintf(fdbg, "bef:%s", inbuf->buf);
    // Watch out for paste operator.
    // Set input pointer back to start of id to substitute over.
    pos = p->body->pos;
    p->body->pos = strlen(p->body->buf);
    SubMacro(p->body, strlen(p->name), stringize);
    inbuf->buf;
    p->body->pos = pos;
    if (fdbg) fprintf(fdbg, "aft:%s", inbuf->buf);
  }
  return (1);
}

/* -----------------------------------------------------------------------------

   Description :
      Scan through input buffer performing macro substitutions where
   possible. A macro name must always begin with an alphabetic character or
   an underscore. The name can not span lines. A macro can not be contained
   within another string of characters.
      Macro substitutions are performed before any other processing on a
   line. This is necessary so that macro can be used within other macros.
      The function loops until no more substitutions are done. It keeps track
   of the number of substitutions and will quit if it finds a large number
   (10,000). We do not know what convoluted macro may have been specified by
   the user, and the substituter needs to quit if for instance a macro 
   expands to itself. This is a bit of an issue as it may be desireable to 
   have a macro expansion for a large amount of data. Eg. a MB data table.
      This function is kind of neat as it expands macros into the input
   buffer that its actually working on. It creates more work for itself!

      #define MACRO "Hello There World!"

      printMACRO  <- will not expand MACRO
      "MACRO"     <- will not expand

   Note that NextCh() is called to advance through the input. Just 
   incrementing the input pointer is not allowed as NextCh() may cause a
   buffer load and a simple increment would not.
----------------------------------------------------------------------------- */

int SearchAndSub(def_t* exc, int opt, char** nd)
{
	static int InComment = 0;
  int c, InComment2 = 0;
  int QuoteToggle = 0;
	int Quote2 = 0;
  char *id, *optr;
  def_t *p, tdef;
  int ex;
  char c1, c2;
  int didsub = 0;
  int odidsub = 0;
  char* dpos;
  int dir;
  int macr = 0;
  int64_t opos, ondx, id_pos;

  // Check if we hit the end of the current input line we do this because
  // NextCh would read another line

  sub_pass = 0;
  id_pos = 0;

  // Loop until no more substitutions are done. A substitution may make another
  // one possible.

  opos = get_input_buf_ndx();
  ondx = opos;
  odidsub = didsub = 0;
  do {
    odidsub = didsub;
    ondx = get_input_buf_ndx();
    while (1)
    {
      if ((c = PeekCh()) == 0) {
        if (nd)
          *nd = inptr;
        goto jmp1;
      }
      if (c == ETB) {
        if (nd)
          *nd = inptr;
        goto jmp1;
      }

      if (c == '\n') {
        c = NextCh();
        QuoteToggle = 0;     // Quotes cannot cross newlines
        Quote2 = 0;
        InComment2 = 0;
        if (opt == -1) {
          if (nd)
            *nd = inptr;
          goto jmp1;
        }
        continue;
      }

      // Check for comment to end-of-line.
      // Assembler standard.
      if (syntax == ASTD && c == '#') {
        InComment2 = 1;
        NextCh();
      }
      // C language standard
      else if (c == '/') {
        c = NextCh();
        if (c == '/') {
          InComment2 = 1;
          NextCh();
          continue;
        }
        else {
          unNextCh();
          c = '/';
        }
      }

      // Check for multi-line comments.
      if (syntax == CSTD) {
        if (c == '/') {
          c = NextCh();
          if (c == '*') {
            InComment = 1;
            NextCh();
            continue;
          }
          else {
            unNextCh();
            c = '/';
          }
        }

        if (c == '*') {
          c = NextCh();
          if (c == '/') {
            InComment = 0;
            NextCh();
            continue;
          }
          else {
            unNextCh();
            c = '*';
          }
        }
      }

      // If in a comment, just grab the next character and continue.
      if (InComment || InComment2) {
        c = NextCh();
        continue;
      }

      // Now check for quoted strings.
      // Just keep getting characters as long as inside quotes
      // Single quotes.
      if (c == '\'') {
        c = NextCh();
        Quote2 = !Quote2;
        continue;
      }
      if (Quote2) {
        c = NextCh();
        continue;
      }

      // Double quotes.
      if (c == '"') {
        c = NextCh();
        QuoteToggle = !QuoteToggle;
        continue;
      }
      if (QuoteToggle) {
        c = NextCh();
        continue;
      }

      if (c == syntax_ch()) {
        // Process any directive that may be present. In the case of an 'end'
        // type directive quit processing and jump to return point. The default
        // action is to grab the next character if a directive was not present.
        // Note that if opt is non-zero the directive is just absorbed without
        // being done.
        if (opt || macr) {
          dir = directive_id(NULL, &dpos);
          
          switch (dir >> 8) {
          case DIR_ENDIF:
            if (nd)
              *nd = dpos;
            goto jmp1;
          case DIR_ENDR:
            if (nd)
              *nd = dpos;
            goto jmp1;
          case DIR_ENDM:
            if (nd)
              *nd = dpos;
            goto jmp1;
          default:
            if (dir == 0)
              c = NextCh();
            continue;
          }
          
        }
        else {
          dir = directive(NULL, &dpos);
          switch (dir >> 8) {
          case DIR_MACR:
            macr++;
            continue;
          case DIR_ELSE:
          case DIR_ENDIF:
            if (nd)
              *nd = dpos;
            goto jmp1;
          case DIR_ENDR:
            if (nd)
              *nd = dpos;
            goto jmp1;
          case DIR_ENDM:
            if (nd)
              *nd = dpos;
            goto jmp1;
          default:
            if (dir == 0)
              c = NextCh();
            continue;
          }
        }
      }

      // Now handle the instance var and macro symbol substitutions.
      id = NULL;
      c1 = c2 = 0;
      if (syntax == ASTD && (c == '\\')) {
        NextCh();
        c = NextCh();
        if (c == '@') {
          sub_inst_var();
          didsub++;
        }
        else {
          unNextCh();
          SkipSpaces();
          id_pos = get_input_buf_ndx();
          id = GetIdentifier();
          if (id == NULL)
            unNextCh();
        }
      }
      else {
        SkipSpaces();
        if (inptr > inbuf->buf)
          c1 = inptr[-1];
        if (inptr > inbuf->buf + 1)
          c2 = inptr[-2];
        id_pos = get_input_buf_ndx();
        id = GetIdentifier();   // try and get an identifier
      }

      // Was there a symbol?
      if (id)
      {
        tdef.name = _strdup(id);
        if (tdef.name == NULL)
          err(5);

        // Search and see if the identifier corresponds to a macro. If it is a
        // macro then substitute it into the text.
        p = (def_t*)htFind(&HashInfo, &tdef);
        ex = 0;
        if (p != NULL && exc)
          ex = strcmp(p->name, exc->name) == 0;
        if (p != (def_t*)NULL && !ex)
        {
          if(inst_macro(p, id_pos, c1 == '#' && c2 != '#'))
            didsub++;
          else
            set_input_buf_ptr(id_pos);
        }
        else
          set_input_buf_ptr(id_pos);
        free(tdef.name);
        // the identifier wasn't a macro so just let it be
      }
      // failed to get identifier, so just continue with the next character
      c = NextCh();
      if (c == ETB) {
        if (nd)
          *nd = inptr;
        goto jmp1;
      }
    }
    set_input_buf_ptr(ondx);
    sub_pass++;
  } while (didsub != odidsub && sub_pass < MAX_SUBS);
jmp1:
  // Spit out a warning if substituted to the limit.
  if (didsub >= MAX_SUBS)
    err(35, MAX_SUBS);
  optr = inptr;
	while (*optr) {
		if (*optr == '\x15')
			*optr = '\x22';
		optr++;
	}
  set_input_buf_ptr(opos);
  return (didsub);
}


/* -----------------------------------------------------------------------------
   Description :
      Performs any paste operations in buffer.
----------------------------------------------------------------------------- */

void DoPastes(char *buf)
{
   char *p = buf;
   int QuoteToggle = 0;
   int64_t len = strlen(buf);
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
   def_t tdef, *p;
   int needClosePa = 0;
   int64_t stndx = 0;
   pos_t* pndx;
   buf_t* tbuf;

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
            p = (def_t *)htFind(&HashInfo, &tdef);
            tbuf = new_buf();
            tbuf->buf = p ? "1" : "0";
            tbuf->alloc = 1;
            tbuf->pos = 1;
            SubMacro(tbuf, inptr - (inbuf->buf+stndx), 0);
            free_buf(tbuf);
         }
      }
      else
         NextCh();
   }
   SetPos(pndx);
   free(pndx);
}

int SearchAndSubBuf(buf_t** buf, int opt, char** nd)
{
  int ocollect;
  buf_t* tbuf;
  int64_t oip;
  int rv;

  oip = get_input_buf_ndx();
  tbuf = inbuf;
  ocollect = collect;
  inbuf = (*buf);
  inptr = (*buf)->buf;
  inbuf->pos = 0;
//  collect = -1;
  rv = SearchAndSub(NULL, opt, nd);
  (*buf) = inbuf;
  collect = ocollect;
  inbuf = tbuf;
  set_input_buf_ptr(oip);
  return (rv);
}
