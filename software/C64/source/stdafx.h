// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

// TODO: reference additional headers your program requires here
#include <Windows.h>
#include <stdio.h>
/*
#include <tchar.h>
#include <stdlib.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
//#define _GNU_SOURCE
//#include <libgen.h>
//#include <inttypes.h>
*/
#include <iostream>
#include <fstream>
#include <iomanip>
#include <string.h>
#include <time.h>
#include <string>
#include "Rand.h"
#include "txtStream.h"
#include "c.h"
#include "expr.h"
#include "Statement.h"
#include "gen.h"
#include "cglbdec.h"

extern int AllocateFISA64RegisterVars();
extern void FISA64_GenLdi(AMODE*,AMODE *);
extern void GenerateFISA64Return(SYM *sym, Statement *stmt);
extern void GenerateFISA64Function(SYM *sym, Statement *stmt);
extern int Allocate816RegisterVars();
extern void Generate816Function(SYM *sym, Statement *stmt);
extern void Generate816Return(SYM *sym, Statement *stmt);
extern void GenLoad(AMODE *ap3, AMODE *ap1, int ssize, int size);
extern void GenStore(AMODE *ap1, AMODE *ap3, int size);

extern int equalnode(ENODE *node1, ENODE *node2);

extern void initFPRegStack();
extern void ReleaseTempFPRegister(AMODE *ap);

//#define nullptr  NULL
#define nullptr    0

// TODO: reference additional headers your program requires here
