// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

// TODO: reference additional headers your program requires here
#include <string>
#include "clsDevice.h"
#include "clsCPU.h"
#include "clsPIC.h"
#include "clsKeyboard.h"
#include "clsUart.h"
#include "clsThor.h"
#include "clsSevenSeg.h"
#include "clsSystem.h"
#include "clsDisassem.h"

enum {
	PF = 0,
	PT = 1,
	PEQ = 2,
	PNE = 3,
	PLE = 4,
	PGT = 5,
	PGE = 6,
	PLT = 7,
	PLEU = 8,
	PGTU = 9,
	PGEU = 10,
	PLTU = 11
};
