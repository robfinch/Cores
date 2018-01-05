#include "stdafx.h"

/* -----------------------------------------------------------------------------
	Description:
		This routine performs a shell sort on an array of elements.
----------------------------------------------------------------------------- */
void shell_sort(__int8 *base, size_t nel, size_t elsize, int (*cmp)(const void *, const void *))
{
   int i,j,k,gap;
   __int8 tmp, *p1, *p2;

   for(gap = 1; gap <= nel; gap = 3*gap+1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i=gap; i < nel; i++)
         for (j=i-gap; j>= 0; j-=gap)
         {
            p1 = base+(j * elsize);
            p2 = base+((j+gap)*elsize);

            if ((*cmp)(p1,p2) <=0)
				   break;

				for (k = elsize; --k >= 0;)
				{
	            tmp = *p1;
   	         *p1++ = *p2;
      	      *p2++ = tmp;
				}
         }
}


