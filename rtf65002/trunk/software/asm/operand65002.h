#pragma once
#include "operand.h"

/* ===============================================================
	(C) 2013  Robert Finch
	All rights reserved.

	operand65002.h
=============================================================== */

namespace RTFClasses
{
	class Operand65002 : public Operand
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
		static bool isSprReg(char *, int *);
	};
}

