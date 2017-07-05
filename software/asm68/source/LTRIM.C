#include <ctype.h>

/* --------------------------------------------------------------------------
   Description :
      Trims spaces from the left side of a string. Spaces are anything
   considered to be a space character by the isspace() function.
-------------------------------------------------------------------------- */

char *ltrim(char *str)
{
   int ii = 0;
   int nn;

   while(isspace(str[ii])) ii++;
   for (nn = 0; str[ii]; nn++, ii++)
      str[nn] = str[ii];
   str[nn] = '\0';
   return str;
}

#ifdef TEST
main(int argc, char *argv[])
{
   printf("|%s|\n", ltrim(argv[1]));
}
#endif


