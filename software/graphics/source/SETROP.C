#include <fgs.h>

typedef struct
{
   char *src;
   int count;
} SROPTbl;

typedef struct
{
   char *upd_area;
   SROPtbl *roptbl;
} SROPUpdTbl;

/* -----------------------------------------------------------------------------
   int gsSetROP(mode);
   int mode;         // Drawing mode to set

   Description :
      Set the plotting mode (ROP_COPY, ROP_XOR, ...). Using MGET will get the
   current drawing mode without changing it. The pointer for updating the
   point must be changed for the drawing mode.

   Returns :
      Drawing mode set (or current mode if MGET).
----------------------------------------------------------------------------- */
int gsSetROP(int rop)
{
   char far *upd_area;

   if (rop >= 0 && rop < 16)
   {
      int ii, nb;
      SROPUpdTbl *updtbl, *tp;
      
      fgsv.ROP = rop;
      updtbl = fgsv.ModeTbl->ROPUpdTbl;
      for (ii = 0; ii < 4; ii++)
      {
         tp = &updtbl[ii];
         for (nb = 0; nb < tp->roptbl->count; nb++)
            tp->upd_area[nb] = tp->roptbl->src[nb];
      }
   }
   return fgsv.ROP;
}

