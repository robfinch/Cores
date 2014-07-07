/* -----------------------------------------------------------------------------

   Description :

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <ht.h>

/* -----------------------------------------------------------------------------

   Description :

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

void *htInsert(SHashTbl *hi, void *item)
{
   SHashVal hash;
   int rr, ii;
   int TableIndex;
   int count;
   char *htbl;

   htbl = (char *)hi->table;
   hash = (*hi->Hash)(item);
   TableIndex = hash.hash;
   for (count = 0; count < hi->size; count++)
   {
      for (rr = ii = 0; ii < hi->width && rr == 0; ii++)
         rr |= htbl[TableIndex * hi->width + ii];
      if (rr == 0)
      {
         memcpy(&htbl[TableIndex * hi->width], item, hi->width);
         break;
      }
      TableIndex = (TableIndex + hash.delta) % hi->size;
   }
   return rr ? NULL : &htbl[TableIndex * hi->width];
}


/* -----------------------------------------------------------------------------

   Description :
      Searchs for and deletes(zeros out) specified entry.

   Returns :
      Pointer to deleted entry if found, NULL if enrty not found.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

void *htDelete(SHashTbl *hi, void *item)
{
   SHashVal hash;
   int rr;
   int TableIndex;
   int count;
   char *htbl;

   htbl = (char *)hi->table;
   hash = (*hi->Hash)(item);
   TableIndex = hash.hash;
   for (count = 0; count < hi->size; count++)
   {
      rr = (*hi->IsEqual)(item, &htbl[TableIndex * hi->width]);
      if (rr == 0)
      {
         memset(&htbl[TableIndex * hi->width], 0, hi->width);
         break;
      }
      TableIndex = (TableIndex + hash.delta) % hi->size;
   }
   return rr ? 0 : &htbl[TableIndex * hi->width];
}


/* -----------------------------------------------------------------------------
   Description :
      Finds an entry in a hash table.
   Returns :
      Pointer to entry in hash table.
----------------------------------------------------------------------------- */

void *htFind(SHashTbl *hi, void *item)
{
   SHashVal hash;
   int rr, ii;
   int TableIndex;
   int count;
   char *htbl;

   htbl = (char *)hi->table;
   hash = (*hi->Hash)(item);
   TableIndex = hash.hash;
   // Loop throughout the entire table. We cannot stop on a blank entry because
   // the blank entry could be the result of a delete. Which means there might
   // still be valid data somewhere in the table, after the deleted entry.
   for (count = 0; count < hi->size; count++)
   {
      rr = (*hi->IsEqual)(item, &htbl[TableIndex * hi->width]);
      if (rr == 0)
         break;
      TableIndex = (TableIndex + hash.delta) % hi->size;
   }
   return rr ? 0 : &htbl[TableIndex * hi->width];
}

