#pragma once
#include "operand.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	operand6502.h
=============================================================== */

namespace RTFClasses
{
	class Operand6502 : public Operand
	{
	public:
		int parse(char *);
		static bool isAReg(char *);
		static bool isXReg(char *);
		static bool isYReg(char *);
		static bool isSPReg(char *);
		static bool isDPReg(char *);
		static bool isReg(char *, int *);
		static bool isNdxReg(char *, int *);
	};
}

