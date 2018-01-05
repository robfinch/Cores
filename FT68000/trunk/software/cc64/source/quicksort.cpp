#include "stdafx.h"

/* -----------------------------------------------------------------------------
   
   qsort

   Function :     Performs quick sort on an array. 

   Parameters :
      (char *) buffer to quicksort
      (int)    size of elements in buffer (including line feeds and carriage returns)
      (unsigned) size of buffer to use for quicksort
      (int)(*)() pointer to comparison function to use
               the comparison function should receive two arguments of
               type void and return  < 0 if a < b, > 0 if a > b, or 0 if a = b

   Examples :

               cmp(void *a, void *b)
               {
                  return strncmp(a, b, 30);
               }

               main()
               {
                  ...
                  fqsort("testdata.txt", 80, 20000, cmp);
                  ...
               }

   Changes
           Author      : R. Finch
           Date        : 91/03/25
           Release     : 10.0.3
           Description : new module

----------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>

static void swap(__int8 *a, __int8 *b, int size)
{
	__int8 tmp;
	int nn;

	for (nn = 0; nn < size; nn++) {
		tmp = a[nn];
		a[nn] = b[nn];
		b[nn] = tmp;
	}
}

static void rquicksort(char *buf, unsigned elesize, int left, int right, int (*cmp)(const void *a, const void *b))
{
   int i, j, pivot;
   static __int8 *qs_buf;
   static __int8 *pivot_buf;
   static int depth = 0;

   /* -------------------------------------------------------------
         On first entry into function allocate temporary buffer.
   ------------------------------------------------------------- */
   if (depth == 0)
   {
	   qs_buf = (__int8 *)malloc(elesize);
      if (!qs_buf)
         return;
	   pivot_buf = (__int8 *)malloc(elesize);
      if (!pivot_buf) {
		  free(qs_buf);
         return;
	  }
   }
   depth++;
   i = left; j = right;
   // Three or fewer elements left, sort them manually.
   if (j-i < 3) {
	   if (j-i < 1)
		   return;
	   if (j-i==1) {
		   if ((*cmp)(&buf[elesize * i], &buf[elesize * (i+1)]) < 0)
				swap(&buf[elesize * i], &buf[elesize * (i+1)], elesize);
		   return;
	   }
	   // if buf[0] < buf[1] && buf[0] < buf[2] then buf[0] must be first
	   // only possibly swap buf[1] and buf[2]
	   if ((*cmp)(&buf[elesize * i], &buf[elesize * (i+1)]) < 0
		   && (*cmp)(&buf[elesize * i], &buf[elesize * (i+2)]) < 0) {
			if ((*cmp)(&buf[elesize * (i+1)], &buf[elesize * (i+2)]) < 0)
				return; // buf[0],buf[1],buf[2] in order
			swap(&buf[elesize * (i+1)], &buf[elesize * (i+2)],elesize);
			return;
	   }
	   else if ((*cmp)(&buf[elesize * (i+1)], &buf[elesize * (i+2)]) < 0) {
		   if ((*cmp)(&buf[elesize * i], &buf[elesize * (i+2)]) < 0) {
				swap(&buf[elesize * i], &buf[elesize * (i+1)], elesize);
				return;
		   }
			swap(&buf[elesize * i], &buf[elesize * (i+1)], elesize);
			swap(&buf[elesize * (i+1)], &buf[elesize * (i+2)], elesize);
			return;
	   }
	   else {
		   swap(&buf[elesize * (i+2)], &buf[elesize * i], elesize);
		   if ((*cmp)(&buf[elesize * (i+1)], &buf[elesize * (i+2)]) < 0)
			   return;
		   swap(&buf[elesize * (i+2)], &buf[elesize * (i+1)], elesize);
	   }
	   return;
   }
   pivot = (i + j) / 2;
   memcpy(pivot_buf,&buf[elesize * pivot],elesize);
   do
   {
      /* -------------------------------------------------------------------
            Scan forward through buffer until an element is found that is
         greater than the pivot.
      ------------------------------------------------------------------- */
      for(; (*cmp)(&buf[elesize * i], pivot_buf) < 0 && i <= j; ++i);
      for(; (*cmp)(&buf[elesize * j], pivot_buf) > 0 && j >= i; j--);
      /* ------------------------------------------------
            If a record was found on the left that was
         greater than the pivot then exchange it with
         a record on the right less than the pivot.
      ------------------------------------------------ */
      if (i < j)
      {
		  swap(&buf[elesize * i],&buf[elesize * j], elesize);
	      i++; j--;
      }
	  else if (i==j) {
		  i++; j--;
	  }
   }
   while (i <= j);
   if (left < j) rquicksort(buf, elesize, left, j, cmp);
   if (i < right) rquicksort(buf, elesize, i, right, cmp);
   /* ------------------------------------------------------
         Just before the last exit of the recursive calls
      free buffer.
   ------------------------------------------------------ */
   depth--;
   if (depth == 0) {
	   free(pivot_buf);
      free(qs_buf);
   }
}
/* -----------------------------------------------------------------------------
      Interface function to actual quicksort algorithm. Does a bunch of one
   time stuff.
----------------------------------------------------------------------------- */

int rqsort(void *buf, unsigned int num, unsigned elesize, int (*cmp)(const void *, const void *))
{
   rquicksort((char *)buf, elesize, 0, num - 1, cmp);
   return(0);
}


