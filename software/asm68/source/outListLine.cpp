#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fwstr.h>
#include "err.h"
#include "SOut.h"
#include "fasm68.h"

/* -----------------------------------------------------------------------------

   Description :
      Outputs a listing line.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

void outListLine()
{
   time_t tim;
   char *pp;
   int ii;

   fprintf(fpList, "   ");
   ii = 0;
   for (pp = sol; *pp && *pp != '\n'; pp++)
      ii++;
   fprintf(fpList, "%.*s\r\n", ii, sol);
//      putchar(*pp);
//   putchar('\n');
   OutputLine++;
   col = 1;
   if (OutputLine % PageLength == 0)
   {
      page++;
      //putchar('\f');
	  fputc('\f', fpList);
      time(&tim);
      fprintf(fpList, verstr, ctime(&tim), page);
      fputs(File[CurFileNum].name, fpList);
	  fputs("\r\n", fpList);
			fflush(fpList);
   }
}

