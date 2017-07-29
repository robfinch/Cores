// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#include <Windows.h>
#include <stdio.h>
#include <tchar.h>

#ifdef _MSC_VER
typedef __int8 int8_t;
typedef __int16 int16_t;
typedef __int64 int64_t;

typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int64 uint64_t;
#else
#include <inttypes.h>
#endif


#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>

#define snprintf	sprintf_s

#include "Float128.h"
#include "Rand.h"
#include "txtStream.h"
#include "C.h"
#include "Expr.h"
#include "Statement.h"
#include "Gen.h"
#include "Cglbdec.h"

// TODO: reference additional headers your program requires here
