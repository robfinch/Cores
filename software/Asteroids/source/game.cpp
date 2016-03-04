#include "stdafx.h"
#include <time.h>

Game game;

Game::Game()
{
	doublesize = false;
	quadsize = false;
	size = 1;
	asteroids = nullptr;
	craft = nullptr;
	missiles = nullptr;
	explosions = nullptr;
	bonusShip = nullptr;
	RTFClasses::Random::srand(time(NULL));
}

void Game::Start()
{
	int nn;

	points = 0;
	lives = 3;
	level = 1;
	if (asteroids)
		delete[] asteroids;
	asteroids = new Asteroid[2000];
	if (craft)
		delete craft;
	craft = new Spacecraft;
	if (missiles)
		delete[] missiles;
	missiles = new Missile[NUM_MISSILES];
	if (bonusShip)
		delete bonusShip;
	bonusShip = new Asteroid;
	bonusShip->size = 20 * game.size;
	if (explosions)
		delete[] explosions;
	explosions = new Explosion[NUM_MISSILES+1];
	for (nn = 0; nn < NUM_MISSILES+1; nn++)
		explosions[nn].t = 0;
	craft->y = 200*game.size, craft->x = 200.0*game.size;
	craft->dx = craft->dy = 0.0;
	craft->rot = 45;
	craft->rotrate = 0;
	craft->speed = 0;
	craft->size = 24 * game.size;
	craft->shieldOn = true;
	craft->shieldEnergy = 2000;
	screenStart = true;
}
