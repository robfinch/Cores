/* ----------------------------------------------------------------------- */
/* */
/* ----------------------------------------------------------------------- */

#include <fgs.h>

#define MAX_CUBES 50
#define MAX_RAD   50

/* ----------------------------------------------------------------------- */
/* Structures */
/* ----------------------------------------------------------------------- */

struct cube
{
  int x,y;  /* cubes center coordinates */
  int r; /* length of sides */
  int r1;
  int vx,vy; /* x, y, and z velocity */
  int xr,yr; /* rotational velocity */
  int col;  /* colour */
};
/* ----------------------------------------------------------------------- */
/* Variables */
/* ----------------------------------------------------------------------- */

struct cube cubes[MAX_CUBES];
int xpos = 0, ypos = 0;

/* ----------------------------------------------------------------------- */
/* Draw a cube at x,y */
/* ----------------------------------------------------------------------- */

void drawcube (cp)
struct cube *cp;
{
  int rad, x, y;

  rad = cp->r;
  x = cp->x;
  y = cp->y;
  gsColorPat(POINTPAT, cp->col);
  gsRectangle(_GFILL, x-rad, y-rad, rad, rad);
//   gsCircle(_GBORDER, x-rad, y-rad, rad);
//   gsEllipse(_GBORDER, x-rad, y-rad, cp->r, cp->r1);
/*  gsLine (x - rad, y + rad, x - rad, y - rad);
  gsLine (x - rad, y - rad, x + rad, y - rad);
  gsLine (x + rad, y - rad, x + rad, y + rad);
  gsLine (x + rad, y + rad, x - rad, y + rad);
*/
}
/* ----------------------------------------------------------------------- */
/* ----------------------------------------------------------------------- */

main ()
{
  int oldmode, r;

   gsOpen(VM640x480x32k);
   gsSetROP(ROP_XOR);
   gsColorPat(POINTPAT, 32767);
   gsClrScr();

  for (r = 0; r < MAX_CUBES; r++)
  {
    cubes [r].x = (rand () % (640 - MAX_RAD * 3)) + MAX_RAD + 2;
    cubes [r].y = (rand () % (480 - MAX_RAD * 3)) + MAX_RAD + 2;
    cubes [r].r = rand () % MAX_RAD;
    cubes [r].r1 = rand () % MAX_RAD;
    cubes [r].vx = rand () & 15 - 8;
    cubes [r].vy = rand () & 15 - 8;
    cubes [r].col = rand();
    drawcube (&cubes [r]);
  }

  do
  {
    for (r = 0; r < MAX_CUBES; r++)
    {
      drawcube (&cubes [r]);
      cubes [r].x += cubes[r].vx;
      cubes [r].y += cubes[r].vy;
      if (cubes [r].x <= cubes[r].r + 1 || cubes [r].x > 639 - cubes[r].r)
        cubes [r].vx = -cubes [r].vx;
      if (cubes [r].y <= cubes[r].r + 1 || cubes [r].y > 479 - cubes[r].r)
        cubes [r].vy = -cubes [r].vy;
      drawcube (&cubes [r]);
    }
    if (kbhit()) if (getch () == 27) break;
  }
  while (1);

   while(!kbhit());
   gsClose();
}

