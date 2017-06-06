#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "Assembler.h"
#include "operands6502.h"

namespace RTFClasses
{
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

	int Operands6502::get()
	{
		int bcount = 0, ii, xx;
		int bcount2 = 0;
		char *sptr, *eptr, tt, ch;
		Operand tmpOp;
		char strTmp[200];
		int reg;
		int sndx;	// start index
		int endx;	// end index

		ii = 0;
		buf->skipSpacesLF();
		sptr = buf->getPtr();
		sndx = buf->ndx();

		while(buf->peekCh())
		{
			ch = buf->nextCh();
			switch(ch)
			{
			case '(':
				bcount++;
				break;
			case ')':
				bcount--;
				if (bcount < 0)
				Err(E_CPAREN);
				break;
			case '{':
			     bcount2++;
			     break;
      case '}':
        bcount2--;      
		    if (bcount2 < 0)
				Err(E_CPAREN);
				break;
			// Note string scanning must check for an escaped quote
			// character, so it's not confused with the actual end
			// of the string.
			// If we detect a quote then scan until end quote
			case '"':
				while(1) {
					ch = buf->nextCh();
					if (ch == '\\') {
						if (buf->peekCh() == '"') {
							buf->nextCh();		// get "
							ch = buf->nextCh();	// move to next char
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
					ch = buf->nextCh();
					if (ch == '\\') {
						if (buf->peekCh() == '\'') {
							buf->nextCh();
							ch = buf->nextCh();
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
				if (bcount == 0 && bcount2 == 0)
				{
					// Check that we haven't got too many operands
					if (ii >= MAX_OPERANDS)
					{
						Err(E_OPERANDS);
						return (ii);
					}
					eptr = buf->getPtr() - 2;
//					endx = buf->ndx() - 2;
//					while (eptr > sptr && isspace(*eptr))
//						--eptr;
//					eptr++;
//					endx = buf->findLastNonSpace(endx);
					op[ii].copy(sptr, eptr-sptr+1);
					op[ii].trim();
//					op[ii].start = sndx;
//					op[ii].end = endx;
//					tt = *eptr;
//					*eptr = '\0';
//					theAssembler.gOperand[ii] = sptr;
//					debug.log5(String("got operand: ") + op[ii]);
					//               printf("theAssembler.gOperand[ii] = %s| sptr=%s|tt=%c,ii=%d\n", theAssembler.gOperand[ii], sptr, tt, ii);
					sptr = buf->getPtr();
//					sndx = buf->ndx();
//					*eptr = tt;
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
	if (buf->getPtr() > sptr)
	{
		eptr = buf->getPtr() - 1;
//		endx = buf->ndx() - 1;
//		while (eptr > sptr && isspace(*eptr)) --eptr;
//		eptr++;
//		endx = buf->findLastNonSpace(endx);
		op[ii].copy(sptr,eptr-sptr+1);
		op[ii].trim();
//		op[ii].start = sndx;
//		op[ii].end = endx;
//		tt = *eptr;
//		*eptr = '\0';
//		theAssembler.gOperand[ii] = sptr;
//		debug.log5(String("got operand[") + ii + "]" + op[ii]);
//		*eptr = tt;
		ii++;
	}

	// Trim leading and trailing spaces from operand
//	for (xx = 0; xx < ii; xx++)
//		theAssembler.gOperand[xx].trim();
	for (xx = 0; xx < ii; xx++)
	{
//		op[xx].nullpos = op[xx].end+1;
//		op[xx].nullch = buf->getBuf()[op[xx].end+1];
//		buf->getBuf()[op[xx].nullpos] = '\0';
//		while (isspace(buf->getBuf()[op[xx].start])) op[xx].start++;
//		while (isspace(buf->getBuf()[op[xx].end])) op[xx].end--;
	}

    // Merge the last two operands if they end in ,x ,y or ,sp as
    // this represents an indexed addressing mode
    if (ii > 1)
    {
		if (Operand6502::isReg(op[ii-1].buf(), &reg))
        {
//			buf->getBuf()[op[ii-2].nullpos] = op[ii-2].nullch;
//			op[ii-2].end = op[ii-1].end;
//			op[ii-2].nullpos = op[ii-1].nullpos;
//			op[ii-2].nullch = op[ii-1].nullch;
//            sprintf(strTmp, "%.*s,%s", sizeof(strTmp)-5, theAssembler.gOperand[ii-2].buf(), theAssembler.gOperand[ii-1].buf());
//            delete theAssembler.gOperand[ii-1];
//            theAssembler.gOperand[ii-1] = NULL;
//            delete theAssembler.gOperand[ii-2];
//            theAssembler.gOperand[ii-2] += ',';
//            theAssembler.gOperand[ii-2] += theAssembler.gOperand[ii-1];
//            theAssembler.gOperand[ii-1] = "";
			op[ii-2] += ',';
			op[ii-2] += op[ii-1];
			op[ii-1].copy("");
            --ii;
        }
    }

	nops = ii;
	calcSignature();
	return (ii);
}

	// compute the signature value of the operands
	int Operands6502::calcSignature()
	{
		sig = 0;

		for (int xx = 0; xx < nops; xx++)
			if (op[xx].len() > 0 && (op[xx])[0] != '"') {
				sig <<= 8;
				sig |= op[xx].parse(op[xx].buf());
			}
		return sig;
	}
}
