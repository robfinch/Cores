#include "stdafx.h"

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
