#pragma once
#include "operand.h"

/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	operand6502.h

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

class OperandButterfly : public Operand
{
public:
	int parse(char *);
	static bool isSPReg(char *);
	static bool isSPRReg(char *, int *);
	static bool isReg(char *, int *);
	static bool isNdxReg(char *, int *);
};

