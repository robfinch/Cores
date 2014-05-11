#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "fwstr.h"
#include "err.h"
#include "fstreamS19.h"
#include "Assembler.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	OutListLine.c
      Outputs a listing line.
=============================================================== */

namespace RTFClasses
{
	void Assembler::OutListLine()
	{
		time_t tim;
		char *pp, *solp;
		int ii;
	//	static char *psol = NULL;
		static int psol = 0;
		bool isMacroLine = false;

		// isMacroLine
		pp = &ibuf->buf()[getStartOfLine()];
		solp = pp;
		for (; *pp && *pp != '\n' && isspace(*pp); pp++)
			;

		// Formatting:
		// First line of macro expansion begins with indent chars
		// followed by '+' followed by macro,
		// subsequent lines begin with '+' followed by indent chars followed
		// by macro
		if (*pp=='+') {
			if (pp==solp)
				*pp=' ';
			else {
				memmove(solp+1, solp, pp-solp);
				*solp = ' ';
			}
			isMacroLine = true;
		}

		// Tab out listing area
		// Leave space for '+' macro indicator
		if (col < SRC_COL)  // && col > 1)
			fprintf(fpList, "%*s", SRC_COL-col, "");

//		getCpu()->op->unTerm();
		if (isMacroLine)
			fprintf(fpList, "+");
		else
			fprintf(fpList, " ");

		// trim leading spaces
//	for (pp = sol; *pp && *pp != '\n' && isspace(*pp); pp++)
//		;
		ii = 0;
		for (pp = solp; *pp && *pp != '\n'; pp++)
			ii++;

		// Tracking to prevent duplicate lines
		if (getStartOfLine() != psol || getStartOfLine() == 0)
			fprintf(fpList, "  %.*s\r\n", ii, solp);
		else
			fprintf(fpList, "\r\n");

		OutputLine++;
		col = 1;
		if (OutputLine % PageLength == 0)
		{
			//page++;
			//fputc('\f', fpList);
			//time(&tim);
			//fprintf(fpList, verstr, ctime(&tim), page);
			//fputs(File[CurFileNum].name.buf(), fpList);
			//fputs("\r\n", fpList);
			//fflush(fpList);
		}
		psol = getStartOfLine();
//		getCpu()->op->reTerm();
	}

	// write a address to the output listing
	int Assembler::listAddr()
	{
		int n;
		int xx;

		n = fprintf(fpList, "%7d ", InputLine);
		xx = getCpu()->awidth;
		switch (xx)
		{
			case 16:
				n += fprintf(fpList, "%04.4lX ", getCounter().val);
				break;
			case 24:
				n += fprintf(fpList, "%06.6lX ", getCounter().val);
				break;
			default:
				n += fprintf(fpList, "%09.9I64X ", (__int64)getCounter().val);
		}
		return n;
	}
}


