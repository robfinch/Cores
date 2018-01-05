/* -----------------------------------------------------------------------------
   
   int sort()

   Function :     Performs quick sort on an array. 

   Parameters :
      (void *)       buffer to quicksort
      (unsigned int) number of elements to sort
      (unsigned int) size of elements in buffer (including line feeds and carriage returns)
      (int)(*)()     pointer to comparison function to use

      the comparison function should receive two arguments of
      type void and return  < 0 if a < b, > 0 if a > b, or 0 if a = b

      enough memory for storing one element (the pviot) is malloced while
   the sort is operating.

   Returns :

   Examples :

               cmp(void *a, void *b)
               {
                  return strncmp(a, b, 30);
               }

               main()
               {
                  ...
                  qsort("testdata.txt", 80, 200, cmp);
                  ...
               }

   Changes
           Author      : R. Finch
           Date        : 91/03/25
           Release     : 10.0.3
           Description : new module

----------------------------------------------------------------------------- */

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

static int (*icmp)(const void *, const void *);
static unsigned int ielesize;
static __int8 *pivot;

#define swap(a,b,size) \
           for (ii = size; --ii >= 0; a++, b++) {\
              tt = *a;\
              *a = *b;\
              *b = tt;\
           }

/* ---------------------------------------------------------------------------
   Workhorse function.

   1)  Select pivot element

   2)  Scan forward through buffer until an element is found that is
   greater than the pivot.

   3)  If a record was found on the left that was greater than the pivot
   then exchange it with a record on the right less than the pivot.

   4)  Sort data in each half of the buffer set by the pivot.

      Note the use of three static variables. The variables are okay to
   declare as static as they are reinitialized for each recursion into
   quicksort. Check the lifetime of the variables. Their value does not
   need to be maintained across recursive calls. This is the only way we
   can get away with this. Declared as static to conserve stack space.
--------------------------------------------------------------------------- */

static void quicksort(__int8 *left, __int8 *right)
{
   static int ii;
   static unsigned char tt;
   char *pleft, *pright;

   pleft = left; pright = right;
   memcpy(pivot, left + (int)(((right - left) / ielesize) / 2) * ielesize, ielesize);
   do {
      for(; ((*icmp)(pleft, pivot) < 0) && (pleft <= right); pleft += ielesize);
      for(; ((*icmp)(pivot, pright) < 0) && (pright >= left); pright -= ielesize);
      if (pleft < pright) {
         swap(pleft, pright, ielesize);
         pright -= 2*ielesize;   /* both pleft,pright already incremented */
      }
	  else if (pleft==pright)
         pright -= 2*ielesize;   /* both pleft,pright already incremented */
   }
   while (pleft < pright);
   if (left < pright) quicksort(left, pright);
   if (pleft < right) quicksort(pleft, right);
}


/* -----------------------------------------------------------------------------
      Interface function to actual quicksort algorithm. Sets module
   variables so we don't have to pass them everywhere.
----------------------------------------------------------------------------- */

int rqsort(void *buf, unsigned int num, unsigned int elesize, int (*cmp)(const void *, const void *))
{
   icmp = cmp;
   ielesize = elesize;
   if (!(pivot = (__int8 *)malloc(elesize))) 
      return 0;
   quicksort((__int8 *)buf, &((char *)buf)[(num - 1) * elesize]);
   free(pivot);
   return 1;
}

#ifdef TEST
tcmp(int *a, int *b)
{
   return *a-*b;
}

main()
{
   int rr[500], ii;

   printf("\nUnsorted\n");
   for (ii = 0; ii < 500; ii++)
   {
      rr[ii] = rand();
      printf("%d ", rr[ii]);
   }
   fqsort(rr, 500, 2, tcmp);
   printf("\n\nSorted\n");
   for (ii = 0; ii < 500; ii++)
   {
      printf("%d ", rr[ii]);
   }
   return 0;
}
#endif

