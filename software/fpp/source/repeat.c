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
  free(rp->def);
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

static void inst_iterative_rept(rep_t* dr, def_t* tdef)
{
  def_t* dp;
  def_t* ptdef, * ptdef2;
  int ii;

  dp = dr->def;
  ptdef2 = htFind(&HashInfo, tdef);
  if (ptdef2) {
    ii = 0;
    do {
      // The variable is being modified, but we want to retain the original state,
      // so clone it and modify the clone.
      ptdef = clone_def(ptdef2);
      // We wnat to substitute into the body of the repeat statement.
      ptdef->body = dp->body;
      // Assign the symbol the iteration value.
      ptdef->nArgs = 1;         // we are only subbing one arg
      ptdef->parms = malloc(sizeof(arg_t*));  // only 1 arg
      if (ptdef->parms == NULL) {
        err(5);
        exit(5);
      }
      ptdef->parms[0] = malloc(sizeof(arg_t));
      if (ptdef->parms[0] == NULL) {
        err(5);
        exit(5);
      }
      ptdef->parms[0]->name = ptdef2->name;
      ptdef->parms[0]->num = 0;
      // A symbol without an iteration value iterates to an empty string.
      // Other assign the iteration value from the argument list.
      if (dp->nArgs < 1)
        ptdef->parms[0]->def = "";
      else
        ptdef->parms[0]->def = dp->parms[ii]->def;
      // Substitute 1 arg into macro body and into the input.
      SubParmMacro(ptdef, 1, 1);
      inbuf;
      inptr += strlen(inptr);
      free(ptdef->parms[0]);
      free(ptdef->parms);
      free(ptdef);
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

  dp = dr->def;
  dp1 = new_def();
  dp1->body = dp->body;
  for (ii = 0; ii < dr->rcnt && ii < 100; ii++) {
    // Substitute args into macro body and into the input.
    dp1->abody = clone_buf(dp->body);
    SubParmMacro(dp1, 1, 1);
    free_buf(dp1->abody);
    inptr += strlen(inptr);
  }
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
        dp->parms[ii] = malloc(sizeof(arg_t));
        if (dp->parms[ii] == NULL) {
          err(5);
          exit(5);
        }
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

void drept(int opt)
{
  rep_t* dr;
  int c;
  pos_t* opndx = NULL;
  def_t* dp;
  def_t tdef;
  char* vname;

  // Update the repeat nesting depth. This is a global var manipulated when a
  // repeat body is gotten.
  rep_depth++;
  inst++;

  dr = new_rept();
  dp = dr->def;
  if (dp == NULL)
    return;

  dp->varg = 0;
  dp->nArgs = -1;          // no arguments or round brackets
  dp->line = InLineNo;     // line number macro defined on
  dp->file = bbfile.body->buf;  // file macro defined in
  dp->name = NULL;

  tdef.name = NULL;

  // Get the var name for .irp, and absorb a following comma.
  if (opt == 1) {
    SkipSpaces();
    vname = GetIdentifier();
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
  SearchAndSub(NULL, rep_depth > 0);

  // Repeat count is not used for iterative repeats.
  // expeval() will eat a newline char
  if (opt == 0)
    dr->orcnt = dr->rcnt = (int)expeval();

  // Check for repeat parameters. There must be no space between the
  // macro name and ')'.
  SkipSpaces();
  get_rept_args(dp, tdef.name, opt);
  c = PeekCh();
  if (c < 0) {
    err(26);
    return;
  }
  dp->body = GetMacroBody(dp, 1, 1);

  // Advance past the '.endr'
  inptr += 5;

  // Dump the repeat body to the input repeat count number of times.
  opndx = GetPos();

  // Handle an iterative repeat
  if (opt == 1)
    inst_iterative_rept(dr, &tdef);
  // Handle the usual repeat.
  else
    inst_rept(dr);

    // Set the input point back to the start of the dump.
xit:
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

void dendr(int opt)
{
  if (rep_depth > 0) {
    rep_depth--;
    inst--;
  }
  else
    err(29);    // .endr without .rept
}


