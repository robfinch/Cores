#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <dos.h>
#include <math.h>
#include <string.h>
#include <malloc.h>
#include <bcgs.h>

/* ---------------------------------------------------------------

   Description :
      Symmetry routines for solid and border circles.

   Returns :

   Examples :

   Changes

--------------------------------------------------------------- */

static void FillSym(int ox, int oy, int xc, int yc)
{
   gsLine(xc+ox, yc+oy, xc-ox, yc+oy);
   if (oy != 0)
   {
      gsLine(xc+ox, yc-oy, xc-ox, yc-oy);
      if (ox != oy)
      {
         gsLine(xc+oy, yc+ox, xc-oy, yc+ox);
         if (ox != 0 && ox != -oy)
            gsLine(xc+oy, yc-ox, xc-oy, yc-ox);
      }
   }
}


static void sym(int ox, int oy, int xc, int yc)
{
   gsPoint(xc + ox, yc + oy);
   gsPoint(xc - ox, yc - oy);
   if (ox != oy) {
      gsPoint(xc + oy, yc + ox);
      gsPoint(xc - oy, yc - ox);
   }
   if (ox != 0) {
      gsPoint(xc - ox, yc + oy);
      gsPoint(xc + oy, yc - ox);
   }
   if (oy != 0) {
      gsPoint(xc - oy, yc + ox);
      gsPoint(xc + ox, yc - oy);
   }
}
/* ---------------------------------------------------------------
   
   (C) 1999 Bird Computer

   void gsCircle(int, int, int, int);
   int ShapeType; // filled or border only
   int xc;        // x coordinate of centre
   int yc;        // y coordinate of centre
   int radius;    // Radius of circle to draw

   Description :
      Draws a circle using Bresenham's algorithm. This routine
   does not compensate for elliptical circles when the graphics
   mode has unequal x and y aspect ratios.
      Draws a circle using Bresenham's algorithm.

   Changes
           Author      : R. Finch
           Date        : 90/06/13
           Release     : 1.0
           Description : new module

--------------------------------------------------------------- */

void far gsCircle(int ShapeType, int xc, int yc, int rad)
{
   int d, ox, oy;
   int newy = 0;
  
   oy = rad;
   d = 3 - 2 * rad;
   for (ox = 0; ox < oy; ++ox)
   {
      if (ShapeType == _GBORDER)
         sym(ox, oy, xc, yc);
      else {
         if (newy) {
            FillSym(ox, oy, xc, yc);
            newy = 0;
         }
         else {
            gsLine(xc+oy, yc+ox, xc-oy, yc+ox);
            if (ox != 0 && ox != -oy)
               gsLine(xc+oy, yc-ox, xc-oy, yc-ox);
         }
      }
      if (d < 0)
         d += (ox << 2) + 6;
      else
      {
        d += ((ox - oy) << 2) + 10;
        --oy;
        newy = 1;
      }
   }
   if (ox == oy)
   {
      if (ShapeType == _GBORDER)
         sym(ox, oy, xc, yc);
      else
         FillSym(ox, oy, xc, yc);
   }
   bcgsv.Cursor.x = xc;
   bcgsv.Cursor.y = yc;
}

