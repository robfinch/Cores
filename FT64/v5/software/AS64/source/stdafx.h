// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <io.h>
#include <fstream>
//#include <unistd.h>

#ifndef int64_t
#define int64_t	__int64
#define uint64_t	unsigned __int64
#define int32_t	__int32
#define uint32_t	unsigned __int32
#define int16_t	__int16
#define int8_t	__int8
#define uint8_t	unsigned __int8
#endif

#include "const.h"
#include "types.h"
#include "elf.hpp"
#include "ht.h"
#include "futs.h"
#include "Int128.h"
#include "a64.h"
#include "token.h"
#include "symbol.h"
#include "NameTable.hpp"
#include "proto.h"

// TODO: reference additional headers your program requires here
