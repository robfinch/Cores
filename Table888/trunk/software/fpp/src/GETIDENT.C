#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

static char buf[MAXLINE];

// Get identifier from input
char *GetIdentifier()
{
   int c, count;
   char *p, *iptr;

   if (PeekCh() == 0 || PeekCh() == '\n')
      return NULL;
   memset(buf,0,sizeof(buf));
   p = buf;
   iptr = inptr;
   c = NextNonSpace(0);
   if (IsFirstIdentChar(c) && c != 0)
   {
      count = 0;
      do
      {
         buf[count++] = c;
         c = NextCh();
      } while(c != 0 && IsIdentChar(c) && count < sizeof(buf)-1);
      unNextCh();
   }
   else
      inptr = iptr;
   return buf[0] ? buf : NULL;
}

