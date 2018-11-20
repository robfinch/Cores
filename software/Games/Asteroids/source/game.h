#pragma once
#include "Gamepad.h"

class Position
{
public:
	float x;
	float y;
};

class Explosion : public Position
{
public:
	int t;	// Timer for graphics
};

class MovingObject : public Position
{
public:
	float dx, dy;
	float rot;
	float rotrate;
	float speed;
	int size;
	int szcd;
	MovingObject();
	void Init();
	void PlaceRandom();
	void RandomD();
	void RandomR();
	void Rotate();
	float RotBound(float);
	void Move(int xlmt, int ylmt);
	void IncreaseSpeed(float amt);
	static const bool Collision(MovingObject *, MovingObject *);
};

class Asteroid : public MovingObject
{
public:
	bool destroyed;
	Asteroid();
	void Init();
	void Init(float x, float y, int sz);
};

class Missile : public MovingObject
{
public:
	bool ready;
	int t;
	int dist;
	Missile() { size = 16; };
};

class Spacecraft : public MovingObject
{
public:
	bool shieldOn;
	int shieldEnergy;
	void Hyperspace();
};

class Game
{
public:
	int points;
	int lives;
	int level;
	bool doublesize;
	bool quadsize;
	bool screenStart;
	bool gamepadConnected;
	Gamepad gamepad;
	int padnum;
	int size;
	Asteroid *asteroids;
	Spacecraft *craft;
	Missile *missiles;
	Explosion *explosions;
	Asteroid *bonusShip;
	void Start();
	Game();
};
