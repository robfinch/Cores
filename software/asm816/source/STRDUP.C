#include <stdio.h>
#include <string.h>
#include <malloc.h>

/* -----------------------------------------------------------------------------

   Description :
      Duplicates a string by mallocing storage for it and copying it to this
   storage.

   Returns :
      (char *) pointer to duplicate string, or NULL if storage couldn't be
   allocated.

----------------------------------------------------------------------------- */

char *strdup(char *str)
{
   int len;
   char *ptr;

   len = strlen(str);
   ptr = (char *)malloc(len+1);
   if (ptr)
      strcpy(ptr, str);
   return ptr;
}

