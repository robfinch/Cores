#include <stdio.h>
#include "c:\atlyscores\rtf65000\trunk\software\asm\buf.h"
#include "c:\atlyscores\rtf65000\trunk\software\asm\err.h"
#include "rept.h"
#include "c:\atlyscores\rtf65000\trunk\software\asm\Assembler.h"

namespace RTFClasses
{
	/* -----------------------------------------------------------------------------
		Copies a macro into the input buffer. When the '@' symbol is
		encountered while performing the copy the instance number of the macro
		is substituted for the '@' symbol.
		Resets the input buffer pointer to the start of the macro.
		Increments the MacroCounter.

		plist = list of parameters to substitute into macro
		slen; - the number of characters being substituted
		eptr = where to begin substitution
		tomove = number of characters to move
	----------------------------------------------------------------------------- */

	void Rept::sub(String *plist[], AsmBuf *ib, int indx, int slen, int tomove)
	{
		int mlen, dif;
		static char buf[MAX_MACRO_EXP+20];
		int ii, jj, kk;
		char *mp;

		// Substitute parameter list into macro body, if needed.
		mp = (nargs && plist) ? subParmList(plist) : body.buf();
		//printf("mp=%s|\r\n", mp);
		// Stick in macro number where requested
		counter++;
		memset(buf, '\0', sizeof(buf));
		for (jj = kk = 0; kk < getCount() && jj < MAX_MACRO_EXP; kk++) {
			for (ii = 0; mp[ii]; ii++)
			{
				if (mp[ii] == '@')
					jj += sprintf(&buf[jj], "%ld", counter);
				else
					buf[jj++] = mp[ii];
			}
		}

		mlen = jj;                    // macro length
		// dif = difference in length between characters being substituted and
		// macro substitution
		dif = mlen - slen;
	//   printf("mlen = %d,dif = %d\n", mlen, dif);
	//   printf("writing over:%s|\n", eptr+dif);
	//   printf("writing from:%s|\n", eptr);
		if (dif > 0) {
//			printf("dif:%d ", dif);
			ib->enlarge(dif);
		}
	//   printf("wro:%s|\n", eptr);
	    printf("buf:%s|\n", buf);
		ib->shift(indx, dif);
		ib->insert(indx, buf, jj);		// copy macro body in place over identifier
		//printf("inserting:%s|\r\n", buf);
	}


	// Compare two.
	int Rept::cmp(Object *o)
	{
		Rept *ps = (Rept *)o;
		return ps->count > counter ? -1 : ps->counter==counter ? 0 : 1;
	}

	// Print a single symbol.

	void Rept::print(FILE *fp)
	{
		fprintf(fp, "%.5d  %2d   %5d  ", counter, nargs, line);//, theAssembler.File[file].name.buf());
		//   fprintf(fp, "%s\n", body);
	}
}
