#include <stdio.h>

/* -----------------------------------------------------------------------------

   Description :
      Return a pointer to a string that represents c. This will be the 
   character itself for normal characters and an escape sequence (\n, \t,
   \x00, etc. for most others). A ' is represented as an \'. The string
   will be destroyed the next time bin_to_ascii in called. If "use_hex" is
   true then \xDD escape sequences are used. Otherwise, octal sequences
   (\DDD) are used. (see also: pchar.c)

   Returns :

   Examples :

   Changes

   $Author:   rob  $
   $Modtime:   04 Jan 1994 20:04:38  $

----------------------------------------------------------------------------- */

char *BinToAscii(int c, int use_hex)
{
   static char buf[8];
   
   c &= 0xff;
   if (' ' <= c && c < 0x7f && c != '\'' && c != '\\') {
      buf[0] = c;
      buf[1] = '\0';
   }
   else {
      buf[0] = '\\';
      buf[2] = '\0';
   
      switch(c) {
         case '\\': buf[1] = '\\'; break;
         case '\'': buf[1] = '\''; break;
         case '\b': buf[1] = 'b'; break;
         case '\f': buf[1] = 'f'; break;
         case '\t': buf[1] = 't'; break;
         case '\r': buf[1] = 'r'; break;
         case '\n': buf[1] = 'n'; break;
         default: sprintf(&buf[1], use_hex ? "x%03x" : "%03o", c);
            break;
      }
   }
   return buf;
}

