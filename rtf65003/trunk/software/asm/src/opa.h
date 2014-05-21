#pragma once

/* ===============================================================
	(C) 2006,2013  Robert Finch
	All rights reserved.
=============================================================== */

namespace RTFClasses
{
	class Opa
	{
	public:
		void (*fn)(Opa *);
		int oc;			// object code base
		int nops;		// Number of operands.
		int sig;   		// operands signature - up to four ops
		int cycles;		// clock cycles
		int cls;		// opcode class
		int sizes;		// allowed sizes
		int oc2;		// additional opcode
	};
}
