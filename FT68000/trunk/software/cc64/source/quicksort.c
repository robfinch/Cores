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
#include <shell.h>

static void rquicksort(char *buf, unsigned elesize, int left, int right, int (*cmp)())
{
   int i, j, pivot;
   static char *qs_buf;
   static int depth = 0;

   /* -------------------------------------------------------------
         On first entry into function allocate temporary buffer.
   ------------------------------------------------------------- */
   if (depth == 0)
   {
      if (!c_malloc(&qs_buf, elesize))
         return;
   }
   depth++;
   i = left; j = right;
   pivot = (i + j) / 2;
   do
   {
      /* -------------------------------------------------------------------
            Scan forward through buffer until an element is found that is
         greater than the pivot.
      ------------------------------------------------------------------- */
      for(; (*cmp)(&buf[elesize * i], &buf[elesize * pivot]) < 0 && i <= j; ++i);
      for(; (*cmp)(&buf[elesize * j], &buf[elesize * pivot]) > 0 && j >= i; j--);
      /* ------------------------------------------------
            If a record was found on the left that was
         greater than the pivot then exchange it with
         a record on the right less than the pivot.
      ------------------------------------------------ */
      if (i <= j)
      {
         memcpy(qs_buf, &buf[elesize * i], elesize);
         memcpy(&buf[elesize * i], &buf[elesize * j], elesize);
         memcpy(&buf[elesize * j], qs_buf, elesize);
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
   if (depth == 0)
      c_free(&qs_buf);
}
/* -----------------------------------------------------------------------------
      Interface function to actual quicksort algorithm. Does a bunch of one
   time stuff.
----------------------------------------------------------------------------- */

void rqsort(void *buf, int num, unsigned elesize, int (*cmp)())
{
   rquicksort(buf, elesize, 0, num - 1, cmp);
}


