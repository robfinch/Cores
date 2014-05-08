#define TEXTSCR	0xFFD00000

#define ST_DESTROYED	0
#define ST_HAPPY		1

#define MV_DOWN		0
#define MV_LEFT		1
#define MV_RIGHT	2

int *screen;
int moveDir;

typedef struct _tagInvader
{
	int status;
	int type;
	int x;
	int y;
	int maxX;
	int minX;
} Invader;

int LeftColInv,RightColInv;

Invader Invaders[5][8];

void DrawInvader(unsigned int row, unsigned int col)
{
	Invader *i;
	unsigned int *base;

	i = &Invaders[row][col];
	if (i->status == ST_DESTROYED)
		return;
	base = &screen[i->y * 56 + i->x];

	switch (i->type)
	{
	case 1:
		// Above
		base[0] = 32;
		base[1] = 32;
		base[2] = 32;
		base[3] = 32;
		base[4] = 32;
		// top
		base[56] = 32;
		base[57] = 233;
		base[58] = 242;
		base[59] = 223;
		base[60] = 32;
		// bottom
		base[112] = 32;
		if (i->x & 1) {
			base[113] = 24;
			base[115] = 24;
		}
		else {
			base[113] = 22;
			base[115] = 22;
		}
		base[114] = 32;
		break;
	}
}

void main ()
{
	int i, j;
	Invader *pi;

	InitializeForScreen();
	while (IsColumnDestroyed(LeftColInv)) {
		LeftColInv++;
		if (LeftColInv > RightColInv) {
			return;
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
			return;
		}
		for (i = 0; i < 5; i++) {
			for (j = 0; j < 8; j++)  {
				Invaders[i][j].maxX += 4;
			}
		}
	}
	for (i = 0; i < 5; i++) {
		for (j = 0; j < 8; j++) {
			DrawInvader(i,j);
		}
	}
	pi = &Invaders[0][0];
	if (moveDir==MV_LEFT) {
		if (!MoveLeft(pi))
			moveDir = MV_DOWN;
	}
	if (moveDir==MV_RIGHT) {
		if (!MoveRight(pi)) {
			moveDir = MV_DOWN;
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
}

void InitializeForScreen()
{
	unsigned int i,j;

	screen = (unsigned int *)TEXTSCR;
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
		}
	LeftColInv = 0;
	RightColInv = 4;
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

