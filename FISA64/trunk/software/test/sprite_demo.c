
unsigned short int *pSpriteController = (unsigned short int *)(0xFFDAD000);

typedef struct tagSpriteInfo
{
    int x;
    int y;
    int dx;
    int dy;
} SpriteInfo;

SpriteInfo sprites[32];

naked sprite_main()
{
      asm {
          ldi   sp,#$8000
          bsr   sprite_demo
      };
}

void sprite_demo()
{
    int nn;

    unsigned int *pRandomNum = (unsigned int *)(0xFFDC0C00);
    unsigned short int *pSpriteRam = (unsigned short int *)(0xFFD80000);

    // Fill sprite memory with random data
    for (nn = 0; nn < 16384; nn++)
        pSpriteRam[nn] = *pRandomNum;    
    for (nn = 0; nn < 32; nn++) {
        sprites[nn].x = *pRandomNum % 1364;
        sprites[nn].y = *pRandomNum % 768;
        sprites[nn].dx = ((*pRandomNum) & 7) - 4;
        sprites[nn].dy = ((*pRandomNum) & 7) - 4;
    }
    while(1) {
        for (nn = 0; nn < 32; nn ++) {
            sprites[nn].x = (sprites[nn].x + sprites[nn].dx) & 1023;
            sprites[nn].y = (sprites[nn].y + sprites[nn].dy) & 511;
            pSpriteController[nn*4] = sprites[nn].x + (sprites[nn].y << 16);
        }
        asm {
            ldi  r1,#1000000
            bsr  MicroDelay
        }
    }
}
