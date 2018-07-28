/* -----------------------------------------------------------------------------

   (C) 1993 FinchWare

   Description :
      Hash function for symbols/identifier strings.
   Strings contain characters
      _abcdefghijklmnopqrtsuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789

   Returns :

   Examples :

   Changes

   $Author:  $
   $Modtime: $

----------------------------------------------------------------------------- */

#include <stdlib.h>
#include <string.h>
#include <ht.h>

SHashVal htSymHash(SHashTbl *hi, char *key)  // (this, key)
{
   SHashVal tmp;
   int len, xx;

   len = strlen(key);
   tmp.hash = len;
   for (xx = 0; xx < len; xx++)
   {
      tmp.hash = _rotl(tmp.hash, 2) ^ key[xx];
      tmp.delta = _rotr(tmp.delta, 2) ^ key[xx];
   }
   tmp.hash %= hi->size;
   if (!(tmp.delta %= hi->size))
      tmp.delta = 1;
   return tmp;
}
