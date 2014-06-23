#include "string.h"
#include "ctype.h"

#ifndef NULL
#define NULL	((void *)0)
#endif

/* --------------------------------------------------------------------------
   Description :
      Trims spaces from the left side of a string. Spaces are anything
   considered to be a space character by the isspace() function.
-------------------------------------------------------------------------- */

char *ltrim(char *str)
{
   int ii = 0;
   int nn;

   if (str==NULL) return NULL;
   while(isspace(str[ii])) ii++;
   for (nn = 0; str[ii]; nn++, ii++)
      str[nn] = str[ii];
   str[nn] = 0;
   return str;
}

/* ---------------------------------------------------------------
	Description :
		Trims spaces from the right side of a string. Spaces
	are anything considered to be a space character by the
	isspace() function.
--------------------------------------------------------------- */

char *rtrim(char *str)
{
   int ii;

   if (str==NULL) return NULL;
   ii = strlen(str);
   if (ii)
   {
      --ii;
      while(ii >= 0 && isspace(str[ii])) --ii;
      ii++;
      str[ii] = 0;
   }
   return str;
}

/* ---------------------------------------------------------------
	Description :
		Trims both leading and trailing spaces from a string.
--------------------------------------------------------------- */

char *trim(char *str)
{
	rtrim(str);
	ltrim(str);
	return (str);
}

