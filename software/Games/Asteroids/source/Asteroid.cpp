#include "stdafx.h"
extern Game game;

Asteroid::Asteroid()
{
	Init();
}

void Asteroid::Init()
{
	PlaceRandom();
	RandomD();
	size = RTFClasses::Random::rand(48)+16;
	if (size <= 16)
		szcd = 0;
	else if (size <= 32)
		szcd = 1;
	else
		szcd = 2;
	RandomR();
	destroyed = false;
}

void Asteroid::Init(float xx, float yy, int sz)
{
	size = sz;
	if (size <= 16)
		szcd = 0;
	else if (size <= 32)
		szcd = 1;
	else
		szcd = 2;
	x = xx;
	y = yy;
	RandomD();
	RandomR();
	destroyed = false;
}
