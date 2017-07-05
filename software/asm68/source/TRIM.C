#include <fwstr.h>

/* -----------------------------------------------------------------------------

   Description :
      Truncates spaces off both sides of a string.

   Returns :

   Examples :

   Changes

   $Author:  $
   $Modtime: $

----------------------------------------------------------------------------- */

char *trim(char *str)
{
   rtrim(str);
   ltrim(str);
   return (str);
}

