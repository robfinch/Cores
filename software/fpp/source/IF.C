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
      inptr = inbuf;
      fgets(inbuf, MAXLINE, fin);
		if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf);
      if (NextNonSpace(0) != '#') {
         inptr = inbuf;
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
            SearchAndSub();
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

void dif()
{
   IfLevel++;
   SearchForDefined();  // check for defined() operator
   SearchAndSub();      // perform any macro substitutions
   if(!expeval())
      difskip(TRUE);
}


/* -----------------------------------------------------------------------------
   Description :
      An else statement should only be encountered while processing the
   true portion of an if statement. When the else is encountered it means
   the false portion of the if statement follows and should not be
   processed.
----------------------------------------------------------------------------- */

void delse()
{
   difskip(FALSE);
}


/* ----------------------------------------------------------------------------
      An 'endif' should only be encountered while processing the an if
   statement.
---------------------------------------------------------------------------- */

void dendif()
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

void delif()
{
   difskip(FALSE);
}


/* ----------------------------------------------------------------------------
      'ifdef' test if an identifier exists.
---------------------------------------------------------------------------- */

void difdef()
{
	SDef dp;

	IfLevel++;
	dp.name = GetIdentifier();
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

void difndef()
{
	SDef dp;

	IfLevel++;
	dp.name = GetIdentifier();
	if (dp.name)
		if (htFind(&HashInfo, &dp))
			difskip(TRUE);
}
