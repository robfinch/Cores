#define ST_DESTROYED	0
#define ST_HAPPY		1

#define MV_DOWN		0
#define MV_LEFT		1
#define MV_RIGHT	2

int prevMoveDir;
int moveDir;
int score;

typedef struct _tagInvader
{
	int status;
	int type;
	unsigned int x;
	unsigned int y;
	unsigned int maxX;
	unsigned int minX;
	unsigned int maxY;
	unsigned int minY;
} Invader;

int LeftColInv,RightColInv;
int TopRowInv,BotRowInv;
int tanksLeft;

Invader Invaders[5][8];

void DrawInvader(Invader *i)
{
	unsigned int x, y;

	if (i->status == ST_DESTROYED)
		return;

	// Above
	x = i->x;
	y = i->y;
	CharPlot(x+0,y,32);
	CharPlot(x+1,y,32);
	CharPlot(x+2,y,32);
	CharPlot(x+3,y,32);
	CharPlot(x+4,y,32);
	switch (i->type)
	{
	case 1:
		// top
		CharPlot(x,y+1,32);
		CharPlot(x+1,y+1,233);
		CharPlot(x+2,y+1,242);
		CharPlot(x+3,y+1,223);
		CharPlot(x+4,y+1,32);
		// bottom
		CharPlot(x,y+2,32);
		if (i->x & 1) {
			CharPlot(x+1,y+2,24);
			CharPlot(x+3,y+2,24);
		}
		else {
			CharPlot(x+1,y+2,22);
			CharPlot(x+3,y+2,22);
		}
		CharPlot(x+2,y+2,32);
		CharPlot(x+4,y+2,32);
		break;
	case 2:
		if (i->x & 1) {
			CharPlot(x,y+1,32);
			CharPlot(x+1,y+1,98);
			CharPlot(x+2,y+1,153);
			CharPlot(x+3,y+1,98);
			CharPlot(x+4,y+1,32);
			CharPlot(x,y+2,32);
			CharPlot(x+1,y+2,236);
			CharPlot(x+2,y+2,98);
			CharPlot(x+3,y+2,251);
			CharPlot(x+4,y+2,32);
		}
		else {
			CharPlot(x,y+1,32);
			CharPlot(x+1,y+1,252);
			CharPlot(x+2,y+1,153);
			CharPlot(x+3,y+1,254);
			CharPlot(x+4,y+1,32);
			CharPlot(x,y+2,32);
			CharPlot(x+1,y+2,251);
			CharPlot(x+2,y+2,98);
			CharPlot(x+3,y+2,236);
			CharPlot(x+4,y+2,32);
		}
		break;
	}
}

void main ()
{
	int i, j;
	Invader *pi;

	// Request I/O focus
	asm {
		jsr	(0xFFFF8014>>2)
	}
nextGame:
	InitializeForGame();
	// Master game loop
	forever {
nextScreen:
		InitializeForScreen();
		forever {
			while (IsColumnDestroyed(LeftColInv)) {
				LeftColInv++;
				if (LeftColInv > RightColInv) {
					score += 1000;
					goto nextScreen;
				}
				for (i = 0; i < 5; i++) {
					for (j = 0; j < 8; j++)  {
						Invaders[i][j].minX -= 4;
					}
				}
			}
			while (IsColumnDestroyed(RightColInv)) {
				RightColInv--;
				if (LeftColInv > RightColInv) {
					score += 1000;
					goto nextScreen;
				}
				for (i = 0; i < 5; i++) {
					for (j = 0; j < 8; j++)  {
						Invaders[i][j].maxX += 4;
					}
				}
			}
			while (IsRowDestroyed(TopRowInv)) {
				TopRowInv++;
				if (TopRowInv > BotRowInv) {
					score += 1000;
					goto nextScreen;
				}
				for (i = 0; i < 5; i++) {
					for (j = 0; j < 8; j++)  {
						Invaders[i][j].minY -= 3;
					}
				}
			}
			while (IsRowDestroyed(BotRowInv)) {
				BotRowInv--;
				if (TopRowInv > BotRowInv) {
					score += 1000;
					goto nextScreen;
				}
				for (i = 0; i < 5; i++) {
					for (j = 0; j < 8; j++)  {
						Invaders[i][j].maxY += 3;
					}
				}
			}
			for (i = 0; i < 5; i++) {
				for (j = 0; j < 8; j++) {
					pi = &Invaders[i][j];
					DrawInvader(pi);
				}
			}
			pi = &Invaders[0][0];
			if (moveDir==MV_LEFT) {
				if (!MoveLeft(pi)) {
					prevMoveDir = MV_LEFT;
					moveDir = MV_DOWN;
				}
			}
			else if (moveDir==MV_RIGHT) {
				if (!MoveRight(pi)) {
					prevMoveDir = MV_RIGHT;
					moveDir = MV_DOWN;
				}
			}
			else if (moveDir==MV_DOWN) {
				if (!MoveDown(pi)) {
					tanksLeft--;
					if (tanksLeft <= 0) {
						GameOver();
						goto nextGame;
					}
					goto nextScreen;
				}
			}

			for (i = 0; i < 5; i++) {
				for (j = 0; j < 8; j++) {
					pi = &Invaders[i][j];
					switch(moveDir) {
					case MV_LEFT:	MoveLeft(pi); break;
					case MV_RIGHT:	MoveRight(pi); break;
					case MV_DOWN:	MoveDown(pi); break;
					}
				}
			}
			if (moveDir==MV_DOWN) {
				if (prevMoveDir==MV_LEFT) {
					prevMoveDir = MV_DOWN;
					moveDir = MV_RIGHT;
				}
				else if (prevMoveDir==MV_RIGHT) {
					prevMoveDir = MV_DOWN;
					moveDir = MV_LEFT;
				}
			}
		}
	}
}

void ClearScreen()
{
	asm {
		jsr ($FFFF801C>>2)
	}
}

void CharPlot(unsigned int x, unsigned int y, unsigned int ch)
{
	asm {
		ld	r1,5,sp
		ld	r2,4,sp
		ld	r3,3,sp
		jsr	($FFFF8044>>2)
	}
}

void InitializeForScreen()
{
	unsigned int i,j;

	ClearScreen();
	for (i = 0; i < 5; i++)
		for (j = 0; j < 8; j++) {
			switch(i) {
			case 0:		Invaders[i][j].type = 1;
			case 1,2:	Invaders[i][j].type = 2;
			case 3,4:	Invaders[i][j].type = 3;
			}
			Invaders[i][j].status = ST_HAPPY;
			Invaders[i][j].x = j * 4 + 12;
			Invaders[i][j].y = i * 3 + 1;
			Invaders[i][j].maxX = j * 4 + 24;
			Invaders[i][j].minX = j * 4;
			Invaders[i][j].maxY = i * 3 + 24;
			Invaders[i][j].minY = i * 3 + 1;
		}
	LeftColInv = 0;
	RightColInv = 4;
	TopRowInv = 0;
	BotRowInv = 7;
}

void InitializeForGame()
{
	score = 0;
	tanksLeft = 3;
}

int IsColumnDestroyed(int col)
{
	if ((Invaders[0][col].status==ST_DESTROYED) && 
		(Invaders[1][col].status==ST_DESTROYED) && 
		(Invaders[2][col].status==ST_DESTROYED) && 
		(Invaders[3][col].status==ST_DESTROYED) && 
		(Invaders[4][col].status==ST_DESTROYED))
		return 1;
	return 0;
}

int IsRowDestroyed(int row)
{
	if ((Invaders[row][0].status==ST_DESTROYED) && 
		(Invaders[row][1].status==ST_DESTROYED) && 
		(Invaders[row][2].status==ST_DESTROYED) && 
		(Invaders[row][3].status==ST_DESTROYED) && 
		(Invaders[row][4].status==ST_DESTROYED) &&
		(Invaders[row][5].status==ST_DESTROYED) &&
		(Invaders[row][6].status==ST_DESTROYED) &&
		(Invaders[row][7].status==ST_DESTROYED))
		return 1;
	return 0;
}

int MoveLeft(Invader *i)
{
	if (i->x > i->minX) {
		i->x--;
		return 1;
	}
	return 0;
}

int MoveRight(Invader *i)
{
	if (i->x < i->maxX) {
		i->x++;
		return 1;
	}
	return 0;
}

int MoveDown(Invader *i)
{
	if (i->y < 31) {
		i->y++;
		return 1;
	}
	return 0;
}

void GameOver()
{
}
