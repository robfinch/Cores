#include "stdafx.h"

HTBLE hTable[10000];
int64_t tokenBuffer[5000000];
char litpool[10000000];
char *pinptr;
char lastid[500];
char laststr[500];
char lastch;
Int128 last_icon;
Int128 ival;
double rval;
int16_t token2;
int32_t reg;
int tbndx;
int lpndx = 0;
int64_t pagesize = 4096;
bool rom_code = true;
