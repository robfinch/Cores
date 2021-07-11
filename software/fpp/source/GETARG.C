#include <stdio.h>
#include <string.h>
#include "fpp.h"

/* ---------------------------------------------------------------------------
      Gets an argument to be substituted into a macro body. Note that the
   round bracket nesting level is kept track of so that a comma in the
   middle of an argument isn't inadvertently picked up as an argument
   separator.
--------------------------------------------------------------------------- */

char *GetArg()
{
   int Depth = 0;
   int c;
   //char *p = inp;
   static char argbuf[2048];
   char *argstr = argbuf;

   memset(argbuf, '\0', sizeof(argbuf));
	do {
		SkipSpaces();
		c = NextCh();
	} while (c == '\n');
	unNextCh();
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
      else if (Depth == 0 && c == ',')    // comma at outermost level means
         break;                           // end of argument has been found
      else
         *argstr++ = c;    // copy input argument to argstr.
   }
   *argstr = '\0';         // NULL terminate buffer.
   return (argbuf);
}
