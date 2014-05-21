#pragma once


/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	pseudo-ops.h

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

// Generic assembler pseudo-op processing classes
class PseudoOp
{
public:
	int (PseudoOp::*proc)();	// processing function
	int oc;			// object code base
	int nops;		// Number of operands.
public:
	int align();
	int bss();
	int code();
	int data();
	int comment();
	int cpu();
	int db();
	int end();
	int endm();
	int aextern();
	int fill();
	int include();
	int list();
	int macro();
	int message();
	int org();
	int apublic();
};

