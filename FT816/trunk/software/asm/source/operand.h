#pragma once
#include "MyString.h"
#include "AsmBuf.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
=============================================================== */

namespace RTFClasses
{
	class Operand : public String
	{
	public:
		// Where in the input buffer the operand starts and ends
		int start;
		int end;
		int nullpos;	// position of null character
		char nullch;	// what character was replaced by null
		int type;		// address mode
		int r1;			// base register
		int r2;			// index register if present
		Value val;		// immediate value / address constant
		Value seg;
		Value offs;
		char hasSegPrefix;
		char hasFarPrefix;
		char hasJmpPrefix;
		virtual int parse(char *) { return 1; };
//		char *text();
	};
}

