#pragma once
#include "Position.h"

class MovingObject : public Position
{
	float dx, dy;
	float rot;
	float rotrate;
};

