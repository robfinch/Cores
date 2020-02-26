#define SPRCTRL ((unsigned __int64 *)0xFFDAD000)

// By declaring the function with the __no_temps attribute it tells the
// compiler that the function doesn't use any temporaries. That means
// the compiler can omit the code to save / restore temporary registers
// across function calls. This makes the code smaller and faster.
// This is not usually safe to do unless the function was coded
// entirely in assembler where it is known no temporaries are in use.
extern int *Alloc(register int mid, register int amount);
extern int VirtToPhys(register int mid, register int *vadr);
extern int GetRand(register int stream) __attribute__(__no_temps);
extern int randStream;

static naked inline int GetButton()
{
	__asm {
		ldt		$v0,BUTTONS
		srl		$v0,$v0,#16
		and		$v0,$v0,#$1F
	}
}

void EnableSprite(int spriteno)
{
	unsigned int *pSPRCTRL = SPRCTRL;
	pSPRCTRL[0x180] = pSPRCTRL[0x180] | (1 << spriteno);
}

void EnableSprites(int sprites)
{
	unsigned int *pSPRCTRL = SPRCTRL;
	pSPRCTRL[0x180] = pSPRCTRL[0x180] | sprites;
}

void RandomizeSpriteColors()
{
	int colorno;
	unsigned int *pSprite = &SPRCTRL[0];
	randStream = 0;
	for (colorno = 2; colorno < 256; colorno++) {
		pSprite[colorno] = GetRand(randStream) & 0xffffffff;
	}
}

void SetSpritePos(int spriteno, int x, int y)
{
	__int32 *pSprite = &SPRCTRL[0x100];
	pSprite[spriteno*4 + 2] = (y << 16) | x;
}

void RandomizeSpritePositions()
{
	int spriteno;
	int x,y;
	int *pSprite = &SPRCTRL[0x100];
	randStream = 0;
	for (spriteno = 0; spriteno < 64; spriteno++) {
		x = (GetRand(randStream) % 800) + 256;
		y = (GetRand(randStream) % 600) + 28;
		pSprite[1] = (2560 << 48) | (y << 16) | x;
		pSprite += 2;
	}
}

void SpriteDemo()
{
	int spriteno;
	__int32 xpos[64];
	__int32 ypos[64];
	__int32 dx[64];
	__int32 dy[64];
	int n, m;
	int btn;
	int x,y;

	unsigned int *pSprite = &SPRCTRL[0x100];
	unsigned int *pImages = (unsigned int *)Alloc(0,65536);//0x1E000000;
	int n;
	
	randStream = 0;
//	LEDS(2);
	RandomizeSpriteColors();
	EnableSprites(-1);
//	LEDS(4);
	// Set some random image data
	for (n = 0; n < 64 * 32 * 4; n = n + 1)
		pImages[n] = GetRand(randStream)|(GetRand(randStream)<<32);
//	LEDS(6);
	x = 256; y = 64;
	for (spriteno = 0; spriteno < 64; spriteno++) {
		pSprite[spriteno*2] = VirtToPhys(0,&pImages[spriteno * 128]);
//		pSprite[spriteno*2+1] = 32*60;
		xpos[spriteno] = x;
		ypos[spriteno] = y;
		SetSpritePos(spriteno, x, y);
		x += 20;
		if (x >= 800) {
			x = 256;
			y += 64;
		}
	}
//	LEDS(0xf7);
//	forever {
//		btn = GetButton();
//		LEDS(btn);
//		switch(btn) {
//		case BTNU:	goto j1;
//		}
//	}
//j1:
//	while (GetButton());
	for (spriteno = 0; spriteno < 64; spriteno++) {
//		xpos[spriteno] = (GetRand(randStream) % 400) + 128;
//		ypos[spriteno] = (GetRand(randStream) % 300) + 14;
//		SetSpritePos(spriteno, (int)xpos[spriteno], (int)ypos[spriteno]);
		dx[spriteno] = (GetRand(randStream) & 15) - 8;
		dy[spriteno] = (GetRand(randStream) & 15) - 8;
	}
	// Set some random image data
	for (n = 0; n < 64 * 32 * 2; n = n + 1)
		pImages[n] = GetRand(randStream);
	forever {
		btn = GetButton();
//		LEDS(btn);
		for (m = 0; m < 50000; m++);	// Timing delay
		for (spriteno = 0; spriteno < 64; spriteno++) {
//			LEDS(spriteno);
			xpos[spriteno] = xpos[spriteno] + dx[spriteno];
			ypos[spriteno] = ypos[spriteno] + dy[spriteno];
			if (xpos[spriteno] < 256) {
				xpos[spriteno] = 256;
				dx[spriteno] = -dx[spriteno];
			}
			if (xpos[spriteno] >= 816) {
				xpos[spriteno] = 816;
				dx[spriteno] = -dx[spriteno];
			}
			if (ypos[spriteno] < 28) {
				ypos[spriteno] = 28;
				dy[spriteno] = -dy[spriteno];
			}
			if (ypos[spriteno] >= 614) 
				ypos[spriteno] = 614;
				dy[spriteno] = -dy[spriteno];
			}
			SetSpritePos(spriteno, (int)xpos[spriteno], (int)ypos[spriteno]);
		}
	}
}
