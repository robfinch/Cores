#include "stdafx.h"
#include <string.h>
#include <ctype.h>

/* ---------------------------------------------------------------
	Description :
		Trims spaces from the right side of a string. Spaces
	are anything considered to be a space character by the
	isspace() function.
--------------------------------------------------------------- */

char *rtrim(char *str)
{
   int ii;

   ii = strlen(str);
   if (ii)
   {
      --ii;
      while(ii >= 0 && isspace(str[ii] & 0x7F)) --ii;
      ii++;
      str[ii] = '\0';
   }
   return str;
}
