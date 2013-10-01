#pragma once
#include "MyString.h"
#include "Mne.h"
#include "operands.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	cpu.h
		This file contains type definitions needed for
	maintaining cpu specific information.
=============================================================== */

namespace RTFClasses
{
	class Cpu
	{
	public:
		char *name;	// which cpu is this table for ?
		int awidth;	// width of addresses
		int stride;	// address stride
		int src_col;
		int nops;	// number of opcodes in table
		Mne *table;
		Operands *op;	// operand processor
		Operands *getOp() { return op; };
	};
}

