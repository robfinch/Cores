#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "asm24.h"
#include "operandsButterfly.h"

/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/* ---------------------------------------------------------------
		Gets operands from the input buffer. Operands are
	separated by commas. Since there are also commas in
	different addressing modes this routine keeps track of the
	number of round brackets encountered. Only when a comma
	follows a matching set of brackets is it considered to be
	separating the operands.

	z
	z(x)     = z,x
	z(y)     = z,y
	a(x)     = a,x
	a(y)     = a,y
	(z,x)    = (z,x)
	(z)y     = (z),y

------------------------------------------------------------------- */

int OperandsButterfly::get()
{
	int bcount = 0, ii, xx;
	char *sptr, *eptr, tt, ch;
	Operand tmpOp;
	char strTmp[200];
	int reg;
	int sndx;	// start index
	int endx;	// end index

	gOpsig = 0;
	ii = 0;
	buf->SkipSpacesLF();
	sptr = buf->Ptr();
	sndx = buf->ndx();
	while(buf->PeekCh())
	{
		ch = buf->NextCh();
		switch(ch)
		{
		case '(':
			bcount++;
			break;
		case ')':
			bcount--;
			if (bcount < 0)
				err(NULL, E_CPAREN);
			break;
		// Note string scanning must check for an escaped quote
		// character, so it's not confused with the actual end
		// of the string.
		// If we detect a quote then scan until end quote
		case '"':
			while(1) {
				ch = buf->NextCh();
				if (ch == '\\') {
					if (buf->PeekCh() == '"') {
						buf->NextCh();		// get "
						ch = buf->NextCh();	// move to next char
					}
				}
				if (ch < 1 || ch == '\n')
					goto ExitLoop;
				if (ch == '"')
					break;
			}
			break;
		// If we detect a quote then scan until end quote.
		case '\'':
			while(1) {
				ch = buf->NextCh();
				if (ch == '\\') {
					if (buf->PeekCh() == '\'') {
						buf->NextCh();
						ch = buf->NextCh();
					}
				}
				if (ch < 1 || ch == '\n')
					goto ExitLoop;
				if (ch == '\'')
					break;
			}
			break;
		// semicolon marks the start of comment following operands. If
		// semicolon detected then break loop
		case ';':
			buf->unNextCh();  // backup ptr
			goto ExitLoop;
		// If at outermost level of brackets then split at comma.
		case ',':
			if (bcount == 0)
			{
				// Check that we haven't got too many operands
				if (ii >= MAX_OPERANDS)
				{
					err(NULL, E_OPERANDS);
					return (ii);
				}
				eptr = buf->Ptr() - 2;
				endx = buf->ndx() - 2;
				while (eptr > sptr && isspace(*eptr)) --eptr;
				eptr++;
				endx = buf->findLastNonSpace(endx);
				op[ii].start = sndx;
				op[ii].end = endx;
				tt = *eptr;
				*eptr = '\0';
				gOperand[ii] = strdup(sptr);
				if (gOperand[ii] == NULL)
					err(NULL, E_MEMORY);
				//               printf("gOperand[ii] = %s| sptr=%s|tt=%c,ii=%d\n", gOperand[ii], sptr, tt, ii);
				sptr = buf->Ptr();
				sndx = buf->ndx();
				*eptr = tt;
				ii++;
			}
			break;
		// Newline marks end of operand
		case '\n':
			buf->unNextCh();
			goto ExitLoop;
      }
   }

ExitLoop:
	// If pointer advanced beyond last sptr
//	if (buf->ndx() > sndx)
	if (buf->Ptr() > sptr)
	{
		eptr = buf->Ptr() - 1;
		endx = buf->ndx() - 1;
		while (eptr > sptr && isspace(*eptr)) --eptr;
		eptr++;
		endx = buf->findLastNonSpace(endx);
		op[ii].start = sndx;
		op[ii].end = endx;
		tt = *eptr;
		*eptr = '\0';
		gOperand[ii] = strdup(sptr);
		if (gOperand[ii] == NULL)
			err(NULL, E_MEMORY);
		*eptr = tt;
		ii++;
	}

	// Trim leading and trailing spaces from operand
	for (xx = 0; xx < ii; xx++)
	{
		if (gOperand[xx])
			trim(gOperand[xx]);
	}
	for (xx = 0; xx < ii; xx++)
	{
		op[xx].nullpos = op[xx].end+1;
		op[xx].nullch = buf->gBuf()[op[xx].end+1];
		buf->gBuf()[op[xx].nullpos] = '\0';
		while (isspace(buf->gBuf()[op[xx].start])) op[xx].start++;
		while (isspace(buf->gBuf()[op[xx].end])) op[xx].end--;
	}

    // Figure operand signature
    for (xx = 0; xx < ii; xx++)
        if (gOperand[xx] && gOperand[xx][0] !='"') {
            gOpsig <<= 8;
			gOpsig |= op[xx].parse(&buf->gBuf()[op[xx].start]);
        }

	nops = ii;
   return (ii);
}

