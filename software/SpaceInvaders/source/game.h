
class Explosion
{
public:
	int x;
	int y;
	int t;
	Explosion() { t = 0; };
};

class Missile
{
public:
	bool ready;
	int dist;
	int t;
	__int16 x, y;
	Missile() { ready = true; };
};

class Tank
{
public:
	float x;
	int y;
	bool Hit(Missile * m);
};

class Invader
{
public:
	unsigned int type : 4;
	unsigned int destroyed : 1;
	__int16 x, y;
	unsigned int frame : 4;
	Invader();
	bool Hit(Missile * m);
};

class Block
{
public:
	unsigned int destroyed : 1;
	unsigned int bricks : 16;
};

class Barrier
{
public:
	int x;
	int y;
	Block blocks[6][8];
	void Init();
	bool Hit(Missile * m);
	const int Points();
};

class Game
{
public:
	int size;
	bool doublesize;
	bool quadsize;
	int score;
	int level;
	int lives;
	int x, y;
	int leftCol, rightCol;
	int topRow, bottomRow;
	bool gamepadConnected;
	int padnum;

	Invader invaders[5][10];
	Missile missiles[NUM_MISSILES+10];
	Tank tank;
	Tank bonusShip;
	Explosion explosions[NUM_MISSILES+10];
	Barrier barriers[NUM_BARRIERS];
	Gamepad gamepad;
	Game();
	void Reset();
	bool IsColumnDestroyed(int);
	bool IsRowDestroyed(int);
	bool AllDestroyed();
	bool AdjustPhalanx();
	void ResetScreen();
};
