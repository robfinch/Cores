#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fpp.h"

static int IfLevel = 0;

/* -----------------------------------------------------------------------------
   Description :
      Scan through file until else/endif/elif found.
         1) (int) if == TRUE scan for else/elif as well as endif.

      *** Once an elif is found it should be evaluated. Note macro expansion
      must be done beforehand.

----------------------------------------------------------------------------- */

void difskip(int s)
{
	int Depth = 1;

   while(!feof(fin))
   {
      // Get a line and ignore it unless it's a preprocessor line
      inptr = inbuf->buf;
      fgets(inbuf->buf, MAXLINE, fin);
		if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf->buf);
      if (NextNonSpace(0) != syntax_ch()) {
         inptr = inbuf->buf;
         continue;
      }

      // Skip leading whitespace
      SkipSpaces();

      // For any if/ifdef/ifndef encountered increment the depth.
      if (!strncmp(inptr, "if", 2)) {
         IfLevel++;
         Depth++;
      }

      // Break when an endif is encountered at the right level.
      else if (!strncmp(inptr, "endif", 5))
      {
         IfLevel--;
         if (IfLevel < 0) {
            IfLevel = 0;
            err(7);
         }
         inptr += 5;
         if (Depth == 1)
            return;
         Depth--;
      }

      // Only scan for else/elif when scanning for false condition on if
      // at desired level
      else if (s && Depth == 1) {
         if (!strncmp(inptr, "else", 4))
            return;

         // if elif is found, then evaluate elif condition to decide
         // whether or not to keep searching
         else if (!strncmp(inptr, "elif", 4)) {
            inptr += 4;
            SearchForDefined();
            SearchAndSub(NULL, rep_depth > 0);
            if (expeval())
               return;
         }
      }
   }
   err(12);
}


/* -----------------------------------------------------------------------------
   Description :
      If the condition is false then search for an else or endif at which
   to continue processing file; otherwise process file normally at this
   point on.

----------------------------------------------------------------------------- */

void dif(int opt)
{
  int ex;

  IfLevel++;
  SearchForDefined();  // check for defined() operator
  SearchAndSub(NULL, rep_depth > 0);      // perform any macro substitutions
  switch (opt) {
  case 0:  ex = expeval(); if (ex == 0) difskip(TRUE); break; // ne
  case 1:  ex = expeval(); if (ex != 0) difskip(TRUE); break; // eq
  case 2:  ex = expeval(); if (ex > 0) difskip(TRUE); break; // gt
  case 3:  ex = expeval(); if (ex >= 0) difskip(TRUE); break; // ge
  case 4:  ex = expeval(); if (ex < 0) difskip(TRUE); break; // lt
  case 5:  ex = expeval(); if (ex <= 0) difskip(TRUE); break; // le
  case 6:
    while (isspace(PeekCh()) && PeekCh() != '\n' && PeekCh() != 0) NextCh();
    if (PeekCh() == '\n')
      difskip(TRUE);
    break;
  case 7:
    while (isspace(PeekCh()) && PeekCh() != '\n' && PeekCh() != 0) NextCh();
    if (PeekCh() != '\n')
      difskip(TRUE);
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

void delse(int opt)
{
   difskip(FALSE);
}


/* ----------------------------------------------------------------------------
      An 'endif' should only be encountered while processing the an if
   statement.
---------------------------------------------------------------------------- */

void dendif(int opt)
{
  IfLevel--;
   if (IfLevel < 0) {
      IfLevel = 0;
      err(7);
   }
}


/* ----------------------------------------------------------------------------
      An elif statement should only be encountered while processing the
   true portion of an if statement. When the elif is encountered it means
   the remainder of the if statement follows and should not be processed.
---------------------------------------------------------------------------- */

void delif(int opt)
{
   difskip(FALSE);
}


/* ----------------------------------------------------------------------------
      'ifdef' test if an identifier exists.
---------------------------------------------------------------------------- */

void difdef(int opt)
{
	SDef dp;

	IfLevel++;
	dp.name = GetIdentifier();
  SearchAndSub(NULL, rep_depth > 0);      // perform any macro substitutions
  if (dp.name) {
		if (!htFind(&HashInfo, &dp))  // If macro name is not found then
			difskip(TRUE);             // scan for else/elif/endif
	}
	else
		difskip(TRUE);
}


/* ----------------------------------------------------------------------------
      'ifndef' test if an identifier doesn't exists.
---------------------------------------------------------------------------- */

void difndef(int opt)
{
	SDef dp;

	IfLevel++;
	dp.name = GetIdentifier();
  SearchAndSub(NULL, rep_depth > 0);      // perform any macro substitutions
  if (dp.name)
		if (htFind(&HashInfo, &dp))
			difskip(TRUE);
}
