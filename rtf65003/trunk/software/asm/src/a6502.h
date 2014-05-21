#pragma once
#include "opa.h"

/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	a6502.h
		This file contains typedefinitions for case specific
	6502 assembly functions.

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

// Processor specific processing
int a6502imm(Opa*);
int a6502zp(Opa*);
int a6502abs(Opa*);
int a6502br(Opa*);

