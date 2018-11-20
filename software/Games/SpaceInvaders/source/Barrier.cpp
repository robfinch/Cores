#include "stdafx.h"
extern Game game;

void Barrier::Init()
{
	int r, c;

	for (r = 0; r < 6; r++) {
		for (c = 0; c < 8; c++) {
			blocks[r][c].destroyed = 0;
			blocks[r][c].bricks = 0xFFFF;
		}
	}
	blocks[0][0].destroyed = 1;
	blocks[0][7].destroyed = 1;
	blocks[5][2].destroyed = 1;
	blocks[5][3].destroyed = 1;
	blocks[5][4].destroyed = 1;
	blocks[5][5].destroyed = 1;
}

bool Barrier::Hit(Missile *m)
{
	float d;
	float x0,y0,x1,y1;
	int r, c;
	bool hit = false;

	for (r = 0; r < 6; r++) {
		for (c = 0; c < 8; c++) {
			if (blocks[r][c].destroyed==0) {
				x0 = x + 4 * game.size + 8 * game.size * c;
				y0 = y + 4 * game.size + 8 * game.size * r;
				x1 = m->x + 8;
				y1 = m->y + 21;
				d = sqrt((float)(x0-x1)*(x0-x1) + (float)(y0-y1)*(y0-y1));
				if (d < (5 * game.size)) {
					blocks[r][c].bricks &= RTFClasses::Random::rand(0x10000);
					blocks[r][c].bricks &= RTFClasses::Random::rand(0x10000);
					blocks[r][c].bricks &= RTFClasses::Random::rand(0x10000);
					if (blocks[r][c].bricks == 0)
						blocks[r][c].destroyed = 1;
//					blocks[r][c] = 0;
					hit = true;
					break;
				}
			}
		}
	}
	return hit;
}

const int Barrier::Points()
{
	int r, c;
	int points = 0;

	for (r = 0; r < 6; r++) {
		for (c = 0; c < 8; c++) {
			if (blocks[r][c].destroyed==0) {
				points++;
			}
		}
	}
	return points;
}

