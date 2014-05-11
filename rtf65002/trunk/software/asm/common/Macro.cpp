#include <stdio.h>
#include "buf.h"
#include "err.h"
#include "macro.h"
#include "Assembler.h"

namespace RTFClasses
{
	int Macro::counter;

	/* ---------------------------------------------------------------
		Gets the body of a macro defined in the following fashion:

		macro <macro name> <parm1> [,<parm n>]...
			<macro text>
		endm
	                
		All macro bodies must be < 2k in size. Macro parameters are
		matched up with their positions in the macro. A $<number>
		(as in $1, $2, etc) is substituted in the macro body in
		place of the parameter name (we don't actually care what
		the parameter name is).
		Macros continued on the next line with '\' are also
		processed. The newline is removed from the macro.
	--------------------------------------------------------------- */

	char *Macro::initBody(String *plist[])
	{
		char *b, *p1, *sptr, *eptr;
		static char buf[MAX_MACRO_EXP];
		int ii, found, c, idlen;
		Buf tb(body.buf(), body.len()+1);
		bool inQuote1 = false;
		bool inQuote2 = false;

		memset(buf, 0, sizeof(buf));
		b = buf;
		while (1)
		{
		StartOfLoop:
			c = tb.peekCh();
			if (c ==0 || c==-1)
				break;
			if (!inQuote1)
				if (c=='"') {
					inQuote2 = !inQuote2;
					goto EndOfLoop;
				}
			if (!inQuote2)
				if (c=='\'') {
					inQuote1 = !inQuote1;
					goto EndOfLoop;
				}

			// If quote detected scan to end of quote, end of line, or end of
			// buffer.
			//if (c == '"') {
			//	while(1) {
			//		*b = c;
			//		b++;
			//		c = tb.nextCh();
			//		if (c == '\n' || c == '"')
			//			break;
			//		if (c < 1)
			//			goto EndOfLoop2;
			//	}
			//	goto EndOfLoop;
			//}
			// If quote detected scan to end of quote, end of line, or end of
			// buffer.
			//else if (c == '\'') {
			//	while(1) {
			//		*b = c;
			//		b++;
			//		c = tb.nextCh();
			//		if (c == '\n' || c == '\'')
			//			break;
			//		if (c < 1)
			//			goto EndOfLoop2;
			//	}
			//	goto EndOfLoop;
			//}
			if (c == '\n') {
				inQuote1 = false;
				inQuote2 = false;
				goto EndOfLoop;
			}

			// Copy spaces
			else if (isspace(c))
				goto EndOfLoop;
		      
			if (plist == NULL)
				goto EndOfLoop;
		     
			if (!inQuote1 && !inQuote2) {
				// First search for an identifier to substitute with parameter
				p1 = tb.getPtr();
				idlen = tb.getIdentifier(&sptr, &eptr);
				if (idlen)
				{
					for (found = ii = 0; ii < MAX_MACRO_PARMS; ii++)
						if (plist[ii])
						{
							if (plist[ii]->equals(sptr, idlen))
							{
								*b = MACRO_PARM_MARKER;
								b++;
								*b = (char)ii+'A';
								b++;
								found = 1;
								goto StartOfLoop;
							}
						}
					// if the identifier was not a parameter then just copy it to
					// the macro body
					if (!found)
					{
						strncpy(b, p1, eptr - p1);
						b += eptr-p1;
						goto StartOfLoop;
					}
				}
				else
					tb.setptr(p1);    // reset inptr if no identifier found
			}
		EndOfLoop:
			*b = c;
			b++;
			c = tb.nextCh();
		}
		EndOfLoop2:
		*b = 0;
		return (buf);
	}


	/* ---------------------------------------------------------------------------
		char *SubParmList(list);
		char *list[];  - substitution list

			Searches the macro body and substitutes the passed parameters for the
		placeholders in the macro body. A pointer to a static buffer containing
		a copy of the macro body with the argument susbstituted in is returned.
			The actual macro body is not modified.
	--------------------------------------------------------------------------- */

	char *Macro::subParmList(String *parmlist[])
	{
		static char buf[MAX_MACRO_EXP];
		int count = sizeof(buf);
		char *o = buf, *bdy = body.buf();
		String s, *ps;
		int n;

		memset(buf, 0, sizeof(buf));
		//printf("bdy=%s\r\n", bdy);
		// Scan through the body for the correct substitution code
		for (o = buf; *bdy && --count > 0; bdy++, o++)
		{
			if (*bdy == MACRO_PARM_MARKER)   // we have found a parameter to sub
			{
				// Copy substitution to output buffer
				bdy++;

				ps = parmlist[*bdy-'A'];
				if (ps) {
					n = ps->len();
					strncpy(o, ps->buf(), n);
					o += n;
	//				for (s = parmlist[*bdy-'A']; s!=NULL && --count > 0;)
	//					*o++ = *s++;
					--o;
				}
				continue;
			}
			*o = *bdy;
		}
		return (buf);
	}


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

	void Macro::sub(String *plist[], AsmBuf *ib, int indx, int slen, int tomove)
	{
		int mlen, dif;
		static char buf[MAX_MACRO_EXP];
		int ii, jj;
		char *mp;

		// Substitute parameter list into macro body, if needed.
		mp = nargs ? subParmList(plist) : body.buf();
		//printf("mp=%s|\r\n", mp);
		// Stick in macro number where requested
		counter++;
		memset(buf, '\0', sizeof(buf));
		for (jj = ii = 0; mp[ii]; ii++)
		{
			if (mp[ii] == '@')
				jj += sprintf(&buf[jj], "%ld", counter);
			else
				buf[jj++] = mp[ii];
		}

		mlen = jj;                    // macro length
		// dif = difference in length between characters being substituted and
		// macro substitution
		dif = mlen - slen;
//	   printf("mlen = %d,dif = %d\n", mlen, dif);
	   //printf("writing over:%s|\n", eptr+dif);
	   //printf("writing from:%s|\n", buf);
		if (dif > 0) {
//			printf("dif:%d ", dif);
			ib->enlarge(dif);
		}
	   //printf("wro:%s|\n", eptr);
	   //printf("buf:%s|\n", buf);
		ib->shift(indx, dif);
		ib->insert(indx, buf, mlen);		// copy macro body in place over identifier
	//	printf("inserting:%s|\r\n", buf);
	}


	// Compare two.
	int Macro::cmp(Object *o)
	{
		Macro *ps = (Macro *)o;
		return strcmp(name.buf(), ps->name.buf());
	}

	// Print a single symbol.

	void Macro::print(FILE *fp)
	{
		fprintf(fp, "%-32.32s  %2d   %5d  ", name.buf(), nargs, line);//, theAssembler.File[file].name.buf());
		//fprintf(fp, "|%s|\n", body.buf());
	}
}
