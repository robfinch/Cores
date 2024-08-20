#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

static char buf[MAXLINE];

// Get identifier from input
char *GetIdentifier()
{
   int c, count;
   char *p;
   pos_t* pos;

   if (PeekCh() == 0 || PeekCh() == '\n')
      return NULL;
   memset(buf,0,sizeof(buf));
   p = buf;
   pos = GetPos();
   c = NextNonSpace(0);
   if (c == '.' && PeekCh() == '.' && inptr[1] == '.') {
     strncpy_s(buf, sizeof(buf), "...", 3);
     inptr += 2;
     return (buf);
   }
   if (IsFirstIdentChar(c) && c != 0)
   {
     count = 0;
     do
     {
       buf[count++] = c;
       c = NextCh();
     } while (c != 0 && IsIdentChar(c) && count < sizeof(buf) - 1);
     unNextCh();
   }
   else
     SetPos(pos);
   free(pos);
   return buf[0] ? buf : NULL;
}

