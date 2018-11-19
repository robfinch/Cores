#include "stdafx.h"

Game::Game()
{
	size = 1;
	Reset();
	gamepadConnected = false;
	padnum = 0;
	RTFClasses::Random::srand(100);
}

void Game::Reset()
{
	level = 1;
	lives = 3;
	score = 0;
	x = 0;
	y = 30;
	leftCol = 0; rightCol = 9;
	topRow = 0; bottomRow = 4;
	ResetScreen();
}

bool Game::IsColumnDestroyed(int c)
{
	int r;

	for (r = 0; r < 5; r++)
	{
		if (invaders[r][c].destroyed==false)
			return false;
	}
	return true;
}

bool Game::IsRowDestroyed(int r)
{
	int c;

	for (c = 0; c < 10; c++)
	{
		if (invaders[r][c].destroyed==false)
			return false;
	}
	return true;
}

bool Game::AllDestroyed()
{
	int r,c;

	for (r = 0; r < 5; r++) {
		for (c = 0; c < 10; c++) {
			if (invaders[r][c].destroyed==false)
				return false;
		}
	}
	return true;
}

bool Game::AdjustPhalanx()
{
	if (AllDestroyed())
		return true;
	while (IsColumnDestroyed(leftCol) && leftCol < rightCol) {
		leftCol++;
	}
	while (IsColumnDestroyed(rightCol) && rightCol > leftCol) {
		rightCol--;
	}
	while (IsRowDestroyed(topRow) && topRow < bottomRow) {
		topRow++;
	}
	while (IsRowDestroyed(bottomRow) && bottomRow > topRow) {
		bottomRow--;
	}
	return false;
}


void Game::ResetScreen()
{
	int r,c;

	for (r = 0; r < 5; r++) {
		for (c = 0; c < 10; c++) {
			invaders[r][c].destroyed = false;
			switch(r) {
			case 0:	invaders[r][c].type = 0; break;
			case 1:	invaders[r][c].type = 1; break;
			case 2:	invaders[r][c].type = 1; break;
			case 3:	invaders[r][c].type = 2; break;
			case 4:	invaders[r][c].type = 2; break;
			}
		}
	}
	x = 0;
	y = 30 * size;
	topRow = 0; bottomRow = 4;
	leftCol = 0; rightCol = 9;
	level++;
	if (level > 5)
		y += 16 * size;
}

Game game;
