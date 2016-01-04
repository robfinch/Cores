/* -----------------------------------------------------------------------------

   Description :
      Performs shell short on array. Works like bsort().

   Returns :
      nothing

   Changes

   $Author:   rob  $
   $Modtime:   04 Jan 1994 19:49:10  $

----------------------------------------------------------------------------- */

void ShellSort(void *base, int nel, int elsize, int (*cmp)(void*,void*))
{
   int i,j,gap,ii;
   char tmp, *p1, *p2;

   for(gap = 1; gap <= nel; gap = 3*gap+1);

   for (gap /= 3; gap > 0; gap /= 3)
      for (i=gap; i < nel; i++)
         for (j=i-gap; j>= 0; j-=gap)
         {
            p1 = (char *)base+(j*elsize);
            p2 = (char *)base+((j+gap)*elsize);

            if ((*cmp)(p1,p2) <=0)
               break;

            for (ii = 0; ii < elsize; ii++) {
               tmp = *p1;
               *p1 = *p2;
               *p2 = tmp;
            }
         }
}
