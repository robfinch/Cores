/* -----------------------------------------------------------------------------

   Description :

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

#include "stdafx.h"

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
   int8_t *htbl;
   SYM *sym = (SYM *)item;
   char *pn;
   int flg = 0;

   pn = nmTable.GetName(sym->name);
   if (!strcmp(pn, "VideoBIOS_FuncTable")) {
      flg = 1;                   
   }
   htbl = (int8_t *)hi->table;
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
   if (flg)
      printf("ins vbft:%d\r\n", TableIndex);
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
   void *p;

	p = htFind(hi,item);
	if (p)
	    memset(p,0,hi->width);
   return p;
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
   int rr;
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
   // Try a linear table search if not found
   if (rr) {
       for (count = 0; count < hi->size; count++) {
       	   rr = (*hi->IsEqual)(item, &htbl[count * hi->width]);
       	   if (rr==0) {
       	   	   TableIndex = count; 
       	   	   break;
  		   }
	   }
   }
   return rr ? 0 : &htbl[TableIndex * hi->width];
}

void *htFind2(SHashTbl *hi, char *name)
{
   SHashVal hash;
   int rr;
   int TableIndex;
   int count;
   char *htbl;

   htbl = (char *)hi->table;
   hash = htSymHash(hi,name);
   TableIndex = hash.hash;
   // Loop throughout the entire table. We cannot stop on a blank entry because
   // the blank entry could be the result of a delete. Which means there might
   // still be valid data somewhere in the table, after the deleted entry.
   for (count = 0; count < hi->size; count++)
   {
//      rr = (*hi->IsEqualName)(name, &htbl[TableIndex * hi->width]);
		 rr = strcmp(name, &nametext[((SYM*)&htbl[TableIndex * hi->width])->name]);
      if (rr == 0)
         break;
      TableIndex = (TableIndex + hash.delta) % hi->size;
   }
/*
   if (rr==0) {
      for (TableIndex = 0; TableIndex < hi->size; TableIndex++) {
            rr = (*hi->IsEqualName)(name, &htbl[TableIndex * hi->width]);
            if (rr == 0)
               break;
      }
   }
*/
   // Try a linear table search if not found
   if (rr) {
       for (count = 0; count < hi->size; count++) {
       	   rr = (*hi->IsEqualName)(name, &htbl[count * hi->width]);
       	   if (rr==0) {
       	   	   TableIndex = count; 
       	   	   break;
  		   }
	   }
   }
   return rr ? 0 : &htbl[TableIndex * hi->width];
}

