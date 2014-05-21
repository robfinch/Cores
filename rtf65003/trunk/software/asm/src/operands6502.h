#pragma once
#include "asmbuf.h"
#include "operand6502.h"
#include "operands.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	operands6502.h
=============================================================== */

namespace RTFClasses
{
	class Operands6502 : public Operands {
	public:
		Operand6502 ops[100];
		Operands6502() { op = ops; };
		int calcSignature();
		virtual int get();
		void unTerm();
		void reTerm();
	};
}
