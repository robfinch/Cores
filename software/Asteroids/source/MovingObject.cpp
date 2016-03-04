#include "stdafx.h"
#include "rand.h"
extern Game game;

using namespace System::Windows::Forms;

MovingObject::MovingObject()
{
	Init();
}

void MovingObject::Init()
{
	PlaceRandom();
	RandomD();
	RandomR();
}

void MovingObject::RandomR()
{
	int r1, rr1;

	r1 = RTFClasses::Random::rand(60);
	rr1 = RTFClasses::Random::rand(12)-6;
	rot = (float)r1;
	rotrate = (float)rr1/10.0;
}

void MovingObject::RandomD()
{
	int dx1,dy1;

	dx1 = RTFClasses::Random::rand(200)-100;
	dy1 = RTFClasses::Random::rand(200)-100;
	dx = (float)(dx1)/50.0;
	dy = (float)(dy1)/50.0;
}

void MovingObject::PlaceRandom()
{
	int x1,y1;

	x1 = RTFClasses::Random::rand(Screen::PrimaryScreen->WorkingArea.Width);
	y1 = RTFClasses::Random::rand(Screen::PrimaryScreen->WorkingArea.Height);
	x = (float)x1;
	y = (float)y1;
}

// Detect if two object have collided.
// Made trickier by the fact the co-ordinates are of the upper left for
// drawing purposes.

const bool MovingObject::Collision(MovingObject *a1, MovingObject *a2)
{
	float dst;
	float x1,y1,x2,y2;
	int sz;

	x1 = a1->x + (float)a1->size/2;
	y1 = a1->y + (float)a1->size/2;
	x2 = a2->x + (float)a2->size/2;
	y2 = a2->y + (float)a2->size/2;
	sz = (a1->size + a2->size) * game.size / 2;

	dst = sqrt(  (x1 - x2) * (x1 - x2) 	+ (y1 - y2) * (y1 - y2)	);
	if (dst < (float)sz) {
		return true;
	}
	return false;
}

float MovingObject::RotBound(float r)
{
	if (r >= 60) r -= 60;
	if (r < 0) r += 60;
	if (r < 0 || r > 60)
		r = 0;
	return r;
}

void MovingObject::Rotate()
{
	rot += rotrate;
	rot = RotBound(rot);
}

void MovingObject::Move(int xlmt, int ylmt)
{
	x += dx;
	y += dy;

	if (x > (float)xlmt && dx > 0)
		x = -128.0*game.size;
	if (x < -128.0*game.size && dx < 0)
		x = (float)xlmt + 128*game.size;
	if (y > (float)ylmt && dy > 0)
		y = -128.0*game.size;
	if (y < -128.0*game.size && dy < 0)
		y = (float)ylmt + 128*game.size;

	// Check for objects that might be trapped
	if ((x > (float)xlmt  || x < 0 - size*game.size) && abs(dx) < 0.01)
		dx = (float)(RTFClasses::Random::rand(200)-100)/50.0;
	if ((y > (float)ylmt  || y < 0 - size*game.size) && abs(dy) < 0.01)
		dy = (float)(RTFClasses::Random::rand(200)-100)/50.0;
}

void MovingObject::IncreaseSpeed(float amt)
{
	speed += amt;
	if (speed < 0.0)
		speed = 0.0;
	dx = sin(6 * RotBound(rot+15) * PI / 180.0) * speed;
	dy = -cos(6 * RotBound(rot+15) * PI / 180.0) * speed;
}

