#include <stdio.h>
#include "d:\projects\bcinc\fwstr.h"
#include "fasm68.h"	// MAX_MACRO_PARMS
#include "err.h"
#include "asmbuf.h"

/* ---------------------------------------------------------------------------
   char *CAsmBuf::GetArg();

   Description :
      Gets an argument to be substituted into a macro body. Note that the
   round bracket nesting level is kept track of so that a comma in the
   middle of an argument isn't inadvertently picked up as an argument
   separator.
--------------------------------------------------------------------------- */

char *CAsmBuf::GetArg()
{
   int Depth = 0;
   char c;
   static char argbuf[512];
   char *argstr = argbuf;
   int dqcount = 0, sqcount = 0;

   memset(argbuf, '\0', sizeof(argbuf));
   SkipSpaces();
   while(1)
   {
      c = (char)PeekCh();
      // Quit loop on newline or end of buffer.
      if (c < 1 || c == '\n')
         break;

      switch (c) {
         // If quote encountered then scan till closing quote or end of line
         case '"':
            *argstr++ = c;
            NextCh();
            while(1) {
               c = (char)NextCh();
               if (c < 1 || c == '\n')
                  goto EndOfLoop;
               *argstr++ = c;
               if (c == '"')
                  break;
            }
            continue;
         // If quote encountered then scan till closing quote or end of line
         case '\'':
            *argstr++ = c;
            NextCh();
            while(1) {
               c = (char)NextCh();
               if (c < 1 || c == '\n')
                  goto EndOfLoop;
               *argstr++ = c;
               if (c == '\'')
                  break;
            }
            continue;
         case '(':
            Depth++;
            break;
         case ')':
            if (Depth < 1) // check if we hit the end of the arg
               Err(E_CPAREN);
            Depth--;
            break;
         case ',':
            if (Depth == 0)    // comma at outermost level means
               goto EndOfLoop;   // end of argument has been found
            break;
         // On semicolon scan to end of line without copying characters to arg
         case ';':
            goto EndOfLoop;
//            while(1) {
//               c = (char)NextCh();
//               if (c < 1 || c == '\n')
//                  goto EndOfLoop;
//            }
      }
      *argstr++ = c;       // copy input argument to argstr.
      NextCh();
   }
EndOfLoop:
   if (Depth > 0)
      Err(E_PAREN);
   *argstr = '\0';         // NULL terminate buffer.
   trim(argbuf);           // get rid of spaces around argument
   return (argbuf[0] ? argbuf : NULL);
}


/* ---------------------------------------------------------------------------
   int CAsmBuf::GetParmList(char *parmlist[]);

   Description :
      Used to get parameter list for macro. The parameter list is a series
   of identifiers separated by comma for a macro definition, or a comma
   delimited list of substitutions for a macro instance.

      macro <macro name> <parm1> [,<parm n>]...
         <macro text>
      endm

   Returns
      the number of parameters in the list
---------------------------------------------------------------------------- */

int CAsmBuf::GetParmList(char *plist[])
{
   char *id;
   int Depth = 0, c, count;

   for (count = 0; count < MAX_MACRO_PARMS; count++)
      plist[count] = NULL;
   count = 0;
   while(1)
   {
      id = GetArg();
      if (id)
      {
         if (count >= MAX_MACRO_PARMS)
         {
            err(NULL, E_MACROPARM);
            goto errxit;
         }
         plist[count] = strdup(id);
         if (plist[count] == NULL)
            err(NULL, E_MEMORY);
         count++;
      }
      c = NextNonSpace();

      // Comment ?
      if (c == ';') {
         unNextCh();
         break;
      }
      // Look and see if we got the last parameter
      if (c < 1 || c == '\n')
      {
         unNextCh();
         break;
      }
      if (c != ',')
      {
         Err(E_MACROCOMMA); // expecting ',' separator
         goto errxit;
      }
   }
//   if (count < 1)
//      err(17);
   if (count < MAX_MACRO_PARMS)
      plist[count] = NULL;
errxit:;
   return (count);
}

