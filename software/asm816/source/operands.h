#pragma once
#include "operand.h"
#include "asmbuf.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	operands.h
=============================================================== */

namespace RTFClasses
{
	class Operands {
	protected:
		AsmBuf *buf;
		int sig;		// operand signature
	public:
		Operands() { op = NULL; };
		Operand *op;
		int nops;		// number of operands
		void clear() { nops = 0; };
		void setInput(AsmBuf *ab) { buf = ab; };
		virtual int get() {
			return 0;
		};
		void unTerm();
		void reTerm();
		virtual void setSignature(int n) { sig = n; };
		virtual int getSignature() { return sig; };
	};
}
