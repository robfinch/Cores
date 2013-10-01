#include "asmbuf.h"
#include "operands.h"

namespace RTFClasses
{
	// unterminate the buffer
	void Operands::unTerm()
	{
		int ii;

		for (ii = 0; ii < nops; ii++)
			buf->getBuf()[op[ii].nullpos] = op[ii].nullch;
	}


	// reterminate the buffer
	void Operands::reTerm()
	{
		int ii;

		for (ii = 0; ii < nops; ii++)
			buf->getBuf()[op[ii].nullpos] = '\0';
	}
}

