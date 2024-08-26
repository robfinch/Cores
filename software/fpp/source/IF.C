#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fpp.h"

/* ---------------------------------------------------------------------------
   (C) 1992-2024 Robert T Finch

   fpp - PreProcessor for Assembler / Compiler
   This file contains processing for the .if directives.
--------------------------------------------------------------------------- */

int IfLevel = 0;
static void if_collect(buf_t** buf, int tf);

/* -----------------------------------------------------------------------------
   Dead Code - see if_collect

   Description :
      Scan through file until else/endif/elif found.
         1) (int) if == TRUE scan for else/elif as well as endif.

      *** Once an elif is found it should be evaluated. Note macro expansion
      must be done beforehand.

----------------------------------------------------------------------------- */

char* difskip(int s, char* p1)
{
	int Depth = 0;
  int64_t ndx;
  int ocollect;
  char* pos2;
  int64_t n1, n2;

  inptr = p1;
  ocollect = collect;
  collect = 1;
  do
  {

    while (NextNonSpace(1) != syntax_ch()) {
      ndx = inptr - inbuf->buf;
      if (PeekCh() == 0) {
        goto jmp1;
      }
      //        inptr = inbuf->buf;
      //         continue;
    }

    // Check for if/endif which change the search level.
    // Need to advance the input pointer past the directive.

    n1 = get_input_buf_ndx();
    switch (directive_id(inptr-1, &pos2)>>8) {
    // For any if/ifdef/ifndef encountered increment the depth.
    case DIR_IF:
      Depth++;
      n2 = inptr - inbuf->buf;
      SearchForDefined();
      expeval();
      break;
    case DIR_IFDEF:
      Depth++;
      GetIdentifier();
      break;
    // Break when an endif is encountered at the right level.
    case DIR_ENDIF:
      n2 = get_input_buf_ndx();
//      memset(inbuf->buf+n1-1, ' ', n2-n1+6);
//      IfLevel--;
      if (IfLevel < 0) {
        IfLevel = 0;
        err(7);
      }
      if (IfLevel == 0)
        goto jmp2;
      if (Depth == 0)
        goto jmp2;
      Depth--;
      break;
    case DIR_ELSE:
      if (s && Depth == 1) {
        collect = ocollect;
        return (inptr);
      }
      break;
    default:
      // Only scan for else/elif when scanning for false condition on if
      // at desired level
      if (s && Depth == 1) {
        if (!strncmp(inptr, "else", 4)) {
          collect = ocollect;
          return (inptr + 4);
        }

        // if elif is found, then evaluate elif condition to decide
        // whether or not to keep searching
        else if (!strncmp(inptr, "elif", 4)) {
          inptr += 4;
          SearchForDefined();
          SearchAndSub(NULL, 0, NULL);
          if (expeval())
            goto jmp2;
        }
      }
      break;
    }

  } while (1);
jmp1:
   err(12);
jmp2:
   collect = ocollect;
   return (inptr);
}

/* -----------------------------------------------------------------------------
   Description:
       This routine helps out the .if directives performing common code.

   Parameters:
      (int64_t) start index position of .if 
      (int64_t) expression was true or false.

   Returns:
      (none)
----------------------------------------------------------------------------- */

void dif_helper(int64_t st, int64_t ex)
{
  int64_t nd;
  buf_t* buf;

  buf = new_buf();
  buf->alloc = 2;
  buf->buf = "\n";
  buf->size = 2;
  buf->pos = 2;

  if_collect(&buf, ex);
  nd = get_input_buf_ndx();
  set_input_buf_ptr(nd);
  SubMacro(buf, nd - st, FALSE);
  set_input_buf_ptr(st + strlen(buf->buf));
  free_buf(buf);
}

/* -----------------------------------------------------------------------------
   Description :
      If the condition is false then search for an else or endif at which
   to continue processing file; otherwise process file normally at this
   point on.

----------------------------------------------------------------------------- */

void dif(int opt, char* p1)
{
  int64_t ex;
  int64_t n1, n3;
  int64_t st;

  inptr;
  st = p1 - inbuf->buf;
  if (sub_pass==0)
    IfLevel++;
  SearchForDefined();  // check for defined() operator
  //  SearchAndSub(NULL);      // perform any macro substitutions
  switch (opt) {
  case 0:
  case 1:
  case 2:
  case 3:
  case 4:
  case 5:
    n1 = get_input_buf_ndx();
    ex = expeval();
    n3 = get_input_buf_ndx();
  }
  switch (opt) {
  case 0: dif_helper(st, ex != 0); break; // ne
  case 1: dif_helper(st, ex == 0); break; // eq
  case 2: dif_helper(st, ex > 0); break; // gt
  case 3: dif_helper(st, ex >= 0); break; // ge
  case 4: dif_helper(st, ex < 0); break; // lt
  case 5: dif_helper(st, ex <= 0); break; // le
  case 6:
    while (isspace(PeekCh()) && PeekCh() != '\n' && !peek_eof()) NextCh();
    if (PeekCh() == '\n')
      dif_helper(st, TRUE);
    break;
  case 7:
    while (isspace(PeekCh()) && PeekCh() != '\n' && !peek_eof()) NextCh();
    if (PeekCh() != '\n')
      dif_helper(st, TRUE);
    break;
  }
}


/* -----------------------------------------------------------------------------
   Description :
      An else statement should only be encountered while processing the
   true portion of an if statement. When the else is encountered it means
   the false portion of the if statement follows and should not be
   processed.
----------------------------------------------------------------------------- */

void delse(int opt, char* pos)
{
  int64_t n1, n3;
  
  n1 = pos - inbuf->buf;
  n3 = inptr - inbuf->buf;
  //memset(pos, ' ', n3 - n1);
//  difskip(FALSE, pos);
}


/* ----------------------------------------------------------------------------
      An 'endif' should only be encountered while processing the an if
   statement.
---------------------------------------------------------------------------- */

void dendif(int opt, char* pos)
{
  int64_t n1, n3;

  n1 = pos - inbuf->buf;
  n3 = get_input_buf_ndx();
  if (sub_pass==0)
    IfLevel--;
   if (IfLevel < 0) {
      IfLevel = 0;
      err(7);
   }
//   memset(pos, ' ', n3 - n1);
}


/* ----------------------------------------------------------------------------
      An elif statement should only be encountered while processing the
   true portion of an if statement. When the elif is encountered it means
   the remainder of the if statement follows and should not be processed.
---------------------------------------------------------------------------- */

void delif(int opt, char* pos)
{
  int64_t st, ex;

  inptr;
  st = pos - inbuf->buf;
  SearchForDefined();  // check for defined() operator
  ex = expeval();
  dif_helper(st, ex != 0);
}


/* ----------------------------------------------------------------------------
      'ifdef' test if an identifier exists.
---------------------------------------------------------------------------- */

void difdef(int opt, char* pos)
{
	def_t dp;
  int64_t st;

  st = pos - inbuf->buf;
  if (sub_pass==0)
	  IfLevel++;
	dp.name = GetIdentifier();
//  SearchAndSub(NULL, DIR_ENDIF, NULL);      // perform any macro substitutions
  if (dp.name) {
    if (!htFind(&HashInfo, &dp))  // If macro name is not found then
      dif_helper(st, FALSE);
    else
      dif_helper(st, TRUE);
	}
  else {
    dif_helper(st, FALSE);
  }
}


/* ----------------------------------------------------------------------------
      'ifndef' test if an identifier doesn't exists.
---------------------------------------------------------------------------- */

void difndef(int opt, char* pos)
{
	def_t dp;
  int64_t n1, n3;
  int64_t st;

  st = pos - inbuf->buf;
  if (sub_pass == 0)
    IfLevel++;
  dp.name = GetIdentifier();
  if (dp.name)
		if (htFind(&HashInfo, &dp))
			difskip(TRUE, pos);
  if (dp.name) {
    if (htFind(&HashInfo, &dp))  // If macro name is not found then
      dif_helper(st, FALSE);
    else
      dif_helper(st, TRUE);
  }
  else {
    dif_helper(st, TRUE);
  }
}

/* -----------------------------------------------------------------------------
   Description :
      Scan through file until endif found.

----------------------------------------------------------------------------- */

static void if_collect(buf_t** buf, int tf)
{
  //  int depth = 1;
  int ocollect;
  buf_t* buf2;
  char ch;
  int64_t n1, nb;
  char* pos2 = NULL;
  char* nd;
  int els = 0;

  ocollect = collect;
  collect = 1;
  buf2 = new_buf();
  nb = get_input_buf_ndx();
  NextCh();
  unNextCh();

  while (!peek_eof())
  {
    // Get a line and ignore it unless it's a preprocessor line
    n1 = get_input_buf_ndx();
    while (NextNonSpace(1) != syntax_ch() && !peek_eof() && n1 < 400000)
      n1 = get_input_buf_ndx();

    inptr;
    check_buf_ptr(inbuf, inptr);
    switch (directive_id(inptr - 1, &pos2) >> 8) {
      // For any if/ifdef/ifndef encountered increment the depth.
    case DIR_IF:
      SearchForDefined();
      expeval();
      break;
    case DIR_IFDEF:
      GetIdentifier();
      break;
      // Break when an endif is encountered at the right level. This is a recursive
    // call so always return.
    case DIR_ELSE:
      els = 1;
      if (tf) {
        rep_depth;
        ch = *pos2;
        *pos2 = 0;
        insert_into_buf(&buf2, inbuf->buf + nb, 0);
        //      SearchAndSubBuf(&buf2,1,&nd);
        *pos2 = ch;
        *buf = buf2;
      }
      else
        nb = get_input_buf_ndx();
      break;
    case DIR_ENDIF:
      if (els ? ~tf : tf) {
        rep_depth;
        ch = *pos2;
        *pos2 = 0;
        insert_into_buf(&buf2, inbuf->buf + nb, 0);
        //      SearchAndSubBuf(&buf2,1,&nd);
        *pos2 = ch;
        *buf = buf2;
      }
      collect = ocollect;
      inptr;
      return;
      //      }
    }
  }
  check_buf_ptr(inbuf, inptr);
  insert_into_buf(&buf2, inbuf->buf, 0);
  SearchAndSubBuf(&buf2, 1, &nd);
  *nd = 0;
  *buf = buf2;
  err(12);  // missing endif
  collect = ocollect;
}
