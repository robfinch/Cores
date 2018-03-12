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
#include "Mne.h"
#include "Opa.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

namespace RTFClasses
{
	// Processes a mneumonic in the input file.
	   
	void Assembler::processMneumonic(Mne *optr)
	{
		int nops, ii;

		g_nops = nops = 0;

		// If size code is present then save it and increment pointer
		// to operand.
		gSzChar = getSzChar();
		ibuf->skipSpacesLF();

		// Split operand field into separate operands ?
		// -1 = don't get any operands
		getCpu()->getOp()->setSignature(0);
		if (optr->maxoperands > 0) {
			nops = getCpu()->getOp()->get();
			g_nops = nops;
		}

		// Try and find a matching signature
		for (ii = 0; ii < 100; ii++)
		{
			if (optr->asms[ii].fn==NULL)
			{
				Err(E_INV);
				break;
			}
			// If we don't care about the number of operands, then
			// don't bother doing a signature match.
			if (optr->asms[ii].nops<0)
			{
				(*(optr->asms[ii].fn))(&optr->asms[ii]);
				CycleCount += optr->asms[ii].cycles;
//				printf("%s  %d\r\n", optr->mne, optr->asms[ii].cycles);
				break;
			}
			if (optr->asms[ii].nops==nops)
			{
//				printf("%s  %d  %d\r\n", optr->mne, optr->asms[ii].cycles, optr->asms[ii].sig);
				// signature of zero means don't care
				if ((optr->asms[ii].sig == getCpu()->getOp()->getSignature()) || (optr->asms[ii].sig==0))
				{
					(*(optr->asms[ii].fn))(&optr->asms[ii]);
					CycleCount += optr->asms[ii].cycles;
					break;
				}
			}
		}

		// Reset operand buffers
		for (ii = 0; ii < MAX_OPERANDS; ii++)
			gOperand[ii] = "";

//		getCpu()->op->unTerm();
		getCpu()->getOp()->clear();
	errxit:;
		ibuf->scanToEOL();
		ibuf->unNextCh();
	}
}
