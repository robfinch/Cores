#pragma once
#include "asmbuf.h"
#include "operand65002.h"
#include "operands.h"

/* ===============================================================
	(C) 2013  Robert Finch
	All rights reserved.

	operands65002.h
=============================================================== */

namespace RTFClasses
{
	class Operands65002 : public Operands {
	public:
		Operand65002 ops[100];
		Operands65002() { op = ops; };
		int calcSignature();
		virtual int get();
		void unTerm();
		void reTerm();
	};
}
