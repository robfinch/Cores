#pragma once
#include "stdafx.h"

extern bool rom_code;
extern int64_t pagesize;
extern int64_t rodata_address;
extern int64_t rodata_base_address;
extern int64_t bss_base_address;
extern int64_t data_base_address;
extern SYM* current_symbol;
extern int64_t tokenBuffer[5000000];
extern char litpool[10000000];
extern char *pinptr;
extern char lastid[500];
extern char laststr[500];
extern char lastch;
extern Int128 last_icon;
extern Int128 ival;
extern double rval;
extern int16_t token2;
extern int32_t reg;
extern int tbndx;
extern int lpndx;
extern int fEmitCode;
extern int ifLevel;


