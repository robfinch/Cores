#pragma once
#include "opa.h"

/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	aW65C816S.h
		This file contains typedefinitions for case specific
	W65C816 assembly functions.

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

// Processor specific processing
int aW65C816imm(Opa*);
int aW65C816immxy(Opa*);
int aW65C816br(Opa*);

