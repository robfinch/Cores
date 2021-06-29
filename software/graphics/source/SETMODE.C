#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <dos.h>
#include <math.h>
#include <string.h>
#include <malloc.h>
#include <fgs.h>

extern SColorFetchTbl GetColorTbl;
extern SFgsTbl ModeTable[];

/* -----------------------------------------------------------------------------
   Description :
      Switches to given mode and sets defaults for drawing mode (MCOPY), 
   origin (0,0), clipping (off), and display page (0).

   Returns :
   (int) non-zero if mode not supported. For VESA modes this will be the
      status value that was returned in the ax register from the mode set
      operation.(al = 4f means function was supported)
----------------------------------------------------------------------------- */

int far gsSetVideoMode(int mode)
{
   union REGS regs;
   int oldmode = 0, ii, jj;
   SPoint Org = { 0, 0 };
   int ret = 0;
   int (*ColorFnTbl)();

   for (ii = 0; ii < 25; ii++)
   {
      if (ModeTable[ii].Mode == mode)
      {
         fgsv.MaxX = ModeTable[ii].MaxX;
         fgsv.MaxY = ModeTable[ii].MaxY;
         fgsv.ModeTbl = &ModeTable[ii];
         fgsv.VScreen = fgsv.RScreen = ModeTable[ii].seg;
         fgsv.ROPTbl = ModeTable[ii].ROPTbl;
         memcpy(&GetColorTbl, ModeTable[ii].ColorTbl, sizeof(SColorFetchTbl));
         break;
      }
   }
   if (ii >= 25)
      return (0x1ff);
   if (mode > 0xff)
   {
      regs.h.ah = 0x4f;
      regs.h.al = 2;
      regs.x.bx = fgsv.ModeTbl->Mode;
      int86(0x10, &regs, &regs);
      if (regs.h.ah != 0)  // failed ?
         return regs.x.ax;
   }
   else
   {
      regs.h.ah = 0;
      regs.h.al = fgsv.ModeTbl->Mode;
      int86(0x10, &regs, &regs);
   }
   fgsv.LinePtr = fgsv.ModeTbl->SHLine;
   fgsv.PrevBank = 0;
   gsSetROP(ROP_COPY);
   gsSetOrg(Org.x, Org.y);
   gsSetClip(CLIPOFF);
   gsDisplayPage(0);
   return ret;
}



