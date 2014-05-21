/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved
=============================================================== */

// asm.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "asm.h"

#include <stdio.h>
#include <stdlib.h>
#include <search.h>
#include <share.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fcntl.h>
#include "fwlib.h"
#include "sym.h"
#include "asmbuf.h"
#include "fstreamS19.h"
#include "registry.h"
#include "Assembler.h"
#include "err.h"
#include "macro.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

namespace RTFClasses
{
/* ---------------------------------------------------------------
	Parse command line switches used to set assembler options.
--------------------------------------------------------------- */

int Assembler::parseCmdLine(int *argNo)
{
	int ii = 2;
	int argsused = 0;
	char *s = progArg[*argNo];
	char *s1;
	Registry reg("Software\\Finitron\\asm65816");

	switch(s[1]) {

	// Register program
	case 'R':
		while(s[ii] && s[ii]!=':') ii++;
		if(s[ii]==':')
			s1 = &s[ii+1];
		else
			s1 = progArg[++(*argNo)];
		if (strncmp(s1, "ASM65816", 8) != 0) {
			fprintf(stderr, "Invalid registration code.\r\n");
			exit(0);
		}
		reg.create();
		reg.write("RegCode", REG_SZ, "ASM65816", 8);
		fprintf(stderr, "Program registered okay. Thank-you for your support.");
		exit(0);
		break;

	// Select processor generation
	case 'P':
		if (s[ii]==':')
			s1 = &s[ii+1];
		else
			s1 = progArg[++(*argNo)];
		giProcessor.copy(s1);
		break;

	case 'l':
		if (s[0] == '-') {
			liston = FALSE;
			fprintf(stderr, "Listing disabled.\n");
		}
		else {
			liston = TRUE;
			fprintf(stderr, "Listing enabled.\n");
		}
		break;

	case 'D':
		Debug = TRUE;
		break;

		 /* Output option
				'o' may be followed by b,-b,s in any order.
				Default is to produce binary output. This can be 
				disabled by specifying -b. 's' indicates to
				produce S format file.
				Next a ':' indicates to override the output file
				name.
		 */
	case 'o':
	{
		int xx;
		__int8 not = 0;

		for (xx = 2; s[xx]; xx++)
		{
			switch(s[xx])
			{
			case '-':
				not = TRUE;
				break;
			case 'b':
				fBinOut = !not;
				not = FALSE;
				if (fBinOut)
					fSOut = FALSE;
				break;
			case 'e':
				fErrOut = !not;
				not = FALSE;
				break;
			case 's':
				fSOut = !not;
				not = FALSE;
				if (fSOut)
					fBinOut = FALSE;
				break;
			case 'l':
				fListing = !not;
				liston = !not;
				if (fListing)
					fprintf(stderr, "Listing enabled.\n");
				else
					fprintf(stderr, "Listing disabled.\n");
				not = FALSE;
				break;
			case 'm':
				bMemOut = !not;
				not = FALSE;
				break;
			case 'v':
				bVerOut = !not;
				not = FALSE;
				break;
			case 'y':
				fSymOut = !not;
				not = FALSE;
				break;
			case ':':
				xx++;
				goto exitfor;
			}
		}
exitfor:
		if (s[xx])
			strcpy(ofname, &s[xx]);
	}
	break;

	default:
		Err(E_CMD, s);
		break;
	}
	return argsused;
}


}

