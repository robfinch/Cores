#include "stdafx.h"

extern Game game;

Invader::Invader()
{
	destroyed = false;
}

bool Invader::Hit(Missile *m)
{
	float d;
	float x0,y0,x1,y1;

	x0 = x + 24 * game.size;
	y0 = y + 16 * game.size;
	x1 = m->x + 16;
	y1 = m->y + 21;
	d = sqrt((float)(x0-x1)*(x0-x1) + (float)(y0-y1)*(y0-y1));
	return (d < (16 * game.size));
}
