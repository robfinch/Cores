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
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <dos.h>
#include <ht.h>
#include <direct.h>
#include <inttypes.h>

#include "fpp.h"
extern int InLineNo;
extern def_t bbfile;

static void rep_collect(buf_t** buf);

/* ---------------------------------------------------------------------------
   (C) 1992-2024 Robert T Finch

   fpp - PreProcessor for Assembler / Compiler
   This file contains processing for the .rept directive.
--------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   Description :
      Allocate storage for a repeat information. If there is insufficient
   memory an error is reported and the program aborts. The repeat
   information is needed only when the repeat block is processed.

   Parameters:
      (none)

    Returns
      (rep_t*) - pointer to storage are for repeat info.

---------------------------------------------------------------------------- */

rep_t* new_rept()
{
  rep_t* p;

  rep_def_cnt++;
  p = malloc(sizeof(rep_t));
  if (p == NULL) {
    err(5);
    exit(5);
  }
  memset(p, 0, sizeof(rep_t));
  p->defno = rep_def_cnt;
  p->def = new_def();
  return (p);
}

arg_t* new_arg()
{
  arg_t* arg;

  arg = malloc(sizeof(arg_t));
  if (arg == NULL) {
    err(5);
    exit(5);
  }
  memset(arg, 0, sizeof(arg_t));
  return (arg);
}

void free_arg(arg_t* arg)
{
  if (arg->def)
    free(arg->def);
  free(arg);
}

/* ---------------------------------------------------------------------------
   Description :
      Free up storage for a repeat information.

   Parameters:
      (rep_t*) - pointer to storage are for repeat info.

    Returns
      (none)

---------------------------------------------------------------------------- */

void free_rept(rep_t* rp)
{
  if (rp->def)
    free_def(rp->def);
  free(rp);
}

/* ---------------------------------------------------------------------------
   Description :
      Instance an iterative repeat block.

   Parameters
     (rep_t*) pointer to repeat's definition
     (def_t*) pointer to temp definition containing name to look up

    Returns
      (none)
---------------------------------------------------------------------------- */

static void inst_iterative_rept(rep_t* dr, def_t* tdef, pos_t* bdypos)
{
  def_t* dp;
  def_t* ptdef, * ptdef2;
  int ii;
  pos_t* pos;

  // First see if the var exists in the definitions table.
  inptr;
  inbuf;
  dp = dr->def;
  ptdef2 = htFind(&HashInfo, tdef);
  if (ptdef2 == NULL) {
    ptdef2 = tdef;
    htInsert(&HashInfo, tdef);
  }
  if (ptdef2) {
    ii = 0;
    do {
      ptdef = ptdef2;
      // We wnat to substitute into the body of the repeat statement.
      ptdef->body = dp->body;
      ptdef->abody = NULL;
      // Assign the symbol the iteration value.
      ptdef->nArgs = 1;         // we are only subbing one arg
      ptdef->parms = malloc(sizeof(arg_t*));  // only 1 arg
      if (ptdef->parms == NULL) {
        err(5);
        exit(5);
      }
      ptdef->parms[0] = new_arg();
      ptdef->parms[0]->name = ptdef2->name;
      ptdef->parms[0]->num = 0;
      // A symbol without an iteration value iterates to an empty string.
      // Other assign the iteration value from the argument list.
      if (dp->nArgs < 1)
        ptdef->parms[0]->def = _strdup("");
      else
        ptdef->parms[0]->def = _strdup(dp->parms[ii]->def);
      // Substitute 1 arg into macro body and into the input.
      pos = GetPos();
      if (ii > 0)
        pos->bufpos = 0;
      else
        pos->bufpos = -(dr->end - dr->start);
      SubParmMacro(ptdef, 1, pos);
      free(pos);
      inbuf;
      inptr += strlen(ptdef->abody->buf);
      free_arg(ptdef->parms[0]);
      free(ptdef->parms);
      ptdef = NULL;
      ii++;
    } while (ii < dp->nArgs);
  }
}

/* ---------------------------------------------------------------------------
   Description :
      Instance a repeat block.

   Parameters
     (rep_t*) pointer to repeat's definition
     (def_t*) pointer to repeat's definition

    Returns
      (none)
---------------------------------------------------------------------------- */

static void inst_rept(rep_t* dr)
{
  int ii;
  def_t* dp1;
  def_t* dp;
  pos_t* pos;
  int64_t ndx;
  int64_t clen;
  buf_t* abody;
  buf_t* super_body;

  dp = dr->def;
  dp1 = new_def();
  dp1->body = dp->body;
  pos = GetPos();
  ndx = dr->start;
  clen = 0;

  // Build up a buffer containing all the macro text to substitute.
  super_body = new_buf();
  abody = clone_buf(dp->body);
//  SearchAndSubBuf(&abody, 1, &nd);
//  *nd = 0;
  for (ii = 0; ii < dr->orcnt && ii < 100; ii++)
    insert_into_buf(&super_body, abody->buf, 0);
  free_buf(abody);
  dp1->body = super_body;
  inbuf;

  // Now do the substitution all at once.
  pos->bufpos = -(dr->end - dr->start);
  set_input_buf_ptr(dr->end);
  SubParmMacro(dp1, 1, pos);
  set_input_buf_ptr(dr->start + strlen(super_body->buf));
  free(pos);
  free_buf(super_body);
}

/* ---------------------------------------------------------------------------
   Description :
      Get the arguments to a repeat block.

   Parameters
      (def_t*) - pointer to repeat definition
      (char*)  - name of repeat block (first arg for iterative repeats).
                 used only for an iterative repeat
      (int) opt   - 0=rept,1=irp

    Returns
      (none)
---------------------------------------------------------------------------- */

static void get_rept_args(def_t* dp, char* name, int opt)
{
  char c;
  int ii;
  arg_t pary[100];
  arg_t* parms[100];

  memset(pary, 0, sizeof(pary));
  for (ii = 0; ii < 100; ii++)
    parms[ii] = &pary[ii];

  c = PeekCh();
  if (c == ',' || opt == 1) {
    if (c == ',')
      NextCh();
    dp->varg = 0;
    dp->nArgs = GetReptArgList(parms, opt);
    if (dp->nArgs < 0) {
      dp->nArgs = -dp->nArgs;
      dp->varg = 1;
    }
    if (dp->nArgs) {
      dp->parms = malloc(sizeof(arg_t*) * dp->nArgs);
      if (dp->parms == NULL) {
        err(5);
        exit(5);
      }
      for (ii = 0; ii < dp->nArgs; ii++) {
        dp->parms[ii] = new_arg();
        dp->parms[ii]->num = ii;
        dp->parms[ii]->name = opt == 1 ? name : NULL;
        dp->parms[ii]->def = _strdup(parms[ii]->def);
      }
    }
    // Note that getting the rept arg list might scan until the end of line
    // already. We do not want to do this twice, or the contents of the 
    // start of the next line will be missed.
    if (PeekCh() != 0)
      ScanPastEOL();
  }
}

/* ---------------------------------------------------------------------------
   Description :
      Implements the rept directive. Define a repeat block. Repeat blocks
   are instanced immediately right where they are defined.

   Parameters
    (int) opt   - 0=rept,1=irp

    Returns
      (none)
---------------------------------------------------------------------------- */

void drept(int opt, char* pos)
{
  rep_t* dr;
  int c;
  pos_t* opndx = NULL;
  def_t* dp;
  def_t tdef;
  char* vname;
  pos_t* bdypos = NULL;
  int64_t n1;

  // Update the repeat nesting depth. This is a global var manipulated when a
  // repeat body is gotten.
  rep_depth++;
  inst++;

  n1 = get_input_buf_ndx();
  dr = new_rept();
  if (*pos=='.')
    dr->start = pos - inbuf->buf;
  else
    dr->start = pos - inbuf->buf - 1;
  dp = dr->def;
  if (dp == NULL)
    return;

  dp->varg = 0;
  dp->nArgs = 0;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body->buf;  // file macro defined in
  dp->name = NULL;

  tdef.name = NULL;
  tdef.varg = 0;

  // Get the var name for .irp, and absorb a following comma.
  if (opt == 1) {
    SkipSpaces();
    n1 = get_input_buf_ndx();
    vname = GetIdentifier(1);
    if (vname)
      tdef.name = _strdup(vname);
    else {
      err(30);    // expecting a symbol
      ScanPastEOL();
      goto xit;
    }
    SkipSpaces();
    if (PeekCh() == ',')
      NextCh();
  }

  // It may be handy for arguments to be made up of other definitions. So, we
  // search for them before getting the args.
  inptr;
  inbuf;
  check_buf_ptr(inbuf, inptr);
  inbuf->buf;

//  SearchAndSub(NULL, 1, NULL);

  // Repeat count is not used for iterative repeats.
  // expeval() will eat a newline char
  if (opt == 0) {
    int undef;

    n1 = inptr - inbuf->buf;
    dr->orcnt = dr->rcnt = (int)expeval(&undef);
    if (dr->orcnt == 5)
      printf("stop");
  }

  // Check for repeat parameters. There must be no space between the
  // macro name and ')'.
  SkipSpaces();
  n1 = get_input_buf_ndx();
  get_rept_args(dp, tdef.name, opt);
  c = PeekCh();
  if (c < 0) {
    err(26);
    return;
  }

  bdypos = GetPos();
  dr->bdystart = get_input_buf_ndx();

  //dp->body = GetMacroBody(dp, 1, 1, 1);
  rep_collect(&dp->body);
  check_buf_ptr(inbuf, inptr);
  dr->end = get_input_buf_ndx();
  dr->bdyend = strlen(dp->body->buf) + dr->bdystart;

  // Dump the repeat body to the input repeat count number of times.
  opndx = GetPos();

  // Handle an iterative repeat
  if (opt == 1) {
    bdypos->bufpos = -1;
    inst_iterative_rept(dr, &tdef, bdypos);
  }
  // Handle the usual repeat.
  else
    inst_rept(dr);
//  dr->end = get_input_buf_ndx();
//  posa_nd[posa_ndx - 1] = dr->end;

  //  if (rep_depth==1)
//    SearchAndSub(NULL, 0);

    // Set the input point back to the start of the dump.
xit:
  if (bdypos)
    free(bdypos);
  if (opndx) {
    SetPos(opndx);
    free(opndx);
  }
  free_rept(dr);
  return;
}

/* ----------------------------------------------------------------------------
   Description:
      Process end of repeat block marker. This marker should have been 
   absorbed when the repeat body was collected. If it is encountered then
   there must have been an end without a start. So spit out an error.

   Parameters
    (int) opt   - this parameter is not used

    Returns
      (none)
---------------------------------------------------------------------------- */

void dendr(int opt, char* pos)
{
  if (rep_depth > 0) {
    rep_depth--;
    inst--;
  }
  else
    err(29);    // .endr without .rept
}


/* -----------------------------------------------------------------------------
   Description :
      Scan through file until endr found. Directives are performed.

   Parameters:
      (buf_t**) pointer to a buffer returned containing the repeat text.

   Returns:
      (buf_t**) (parameter) a buffer containing the repeat text.

----------------------------------------------------------------------------- */

static void rep_collect(buf_t** buf)
{
//  int depth = 1;
  int ocollect;
  buf_t* buf2;
  char ch;
  int64_t n1, nb;
  char* pos2 = NULL;

  ocollect = collect;
  collect = 1;
  buf2 = new_buf();

  // The text begins after the .rept or .irp directive. Record position.
  nb = get_input_buf_ndx();
  NextCh();
  unNextCh();

  while (!peek_eof())
  {
    // Get a line and ignore it unless it's a preprocessor line
    while (NextNonSpace(1) != syntax_ch() && !peek_eof())
      ;
    n1 = get_input_buf_ndx();

    inptr;
    check_buf_ptr(inbuf, inptr);
    switch (directive(inptr-1, &pos2) >> 8) {
    // Break when an endr is encountered at the right level. This is a recursive
    // call so always return.
    case DIR_ENDR:
      rep_depth;
      ch = *pos2;
      *pos2 = 0;
      insert_into_buf(&buf2, inbuf->buf + nb, 0);
//      SearchAndSubBuf(&buf2,1,&nd);
      *pos2 = ch;
      collect = ocollect;
      *buf = buf2;
      return;
    }
  }
  // Here, the end of file was reached without and endr.
  check_buf_ptr(inbuf, inptr);
  insert_into_buf(&buf2, inbuf->buf, 0);
//  SearchAndSubBuf(&buf2, 1, &nd);
//  *nd = 0;
  *buf = buf2;
  err(34);  // missing endr
  collect = ocollect;
}
