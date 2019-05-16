#include "gfx.h"

extern int GetRand(int);
extern void LEDSTAT(register int val);

void gfx_demo()
{
	int n;
	int p;
	int x,y,c;
	int x0,y0,x1,y1,x2,y2;
	gfx_surface surface;
	// Turn off text controller
	out8(0xFFD1DF0C,0);
	gfx_set_videomode(800,600,16);
	LEDSTAT(1);
	gfx_init(0x200000);
	LEDSTAT(2);
	gfx_init_surface(&surface,800,600);
	LEDSTAT(3);
	gfx_bind_rendertarget(&surface);
	LEDSTAT(4);
	for (n = 0; n < 10000; n++) {
		p = GetRand(0);
		x = (p >> 16) % 400;
		y = p % 300;
		c = GetRand(0);
		gfx_set_pixel(x,y,c);
	}
	LEDSTAT(5);
	for (n = 0; n < 10000; n++) {
		p = GetRand(0);
		x0 = p % 400;
		x1 = (p >> 16) % 400;
		p = GetRand(0);
		y0 = p % 400;
		y1 = (p >> 16) % 400;
		c = GetRand(0);
		gfx_set_color(c);
		gfx_line(x0,y0,x1,y1);
	}
	LEDSTAT(6);
	for (n = 0; n < 10000; n++) {
		p = GetRand(0);
		x0 = p % 400;
		y0 = (p >> 16) % 300;
		p = GetRand(0);
		x1 = p % 400;
		y1 = (p >> 16) % 300;
		p = GetRand(0);
		x2 = p % 400;
		y2 = (p >> 16) % 300;
		c = GetRand(0);
		gfx_set_color(c);
		gfx_triangle(x0,y0,x1,y1,x2,y2);
	}
	LEDSTAT(7);
	for (n = 0; n < 10000; n++) {
		p = GetRand(0);
		x0 = p % 400;
		x1 = (p >> 16) % 400;
		p = GetRand(0);
		y0 = p % 300;
		y1 = (p >> 16) % 300;
		c = GetRand(0);
		gfx_set_color(c);
		gfx_solid_rect(x0,y0,x1,y1);
	}
	// Turn on text controller
	out8(0xFFD1DF0C,1);
}
