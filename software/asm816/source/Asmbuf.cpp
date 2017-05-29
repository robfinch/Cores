#include <stdio.h>
#include "MyString.h"
#include "c:\projects\bcinc\fwstr.h"
#include "Asmbuf.h"
#include "Assembler.h"	// MAX_MACRO_PARMS
#include "err.h"
#include "buf.h"

/* ===============================================================
	(C)  2006 Robert Finch
	All rights reserved.
=============================================================== */

namespace RTFClasses
{
	/* ---------------------------------------------------------------------------
		char *AsmBuf::GetArg();

		Gets an argument to be substituted into a macro body. Note that the
		round bracket nesting level is kept track of so that a comma in the
		middle of an argument isn't inadvertently picked up as an argument
		separator.
	--------------------------------------------------------------------------- */

	String *AsmBuf::getArg()
	{
		int Depth = 0;
		char c;
		int dqcount = 0, sqcount = 0;
		String *arg = new String();

		skipSpacesLF();
		while(1)
		{
			c = (char)peekCh();
			// Quit loop on newline or end of buffer.
			if (c < 1 || c == '\n')
				break;

			switch (c) {
			// If quote encountered then scan till closing quote or end of line
			case '"':
				arg->add(c);
				nextCh();
				while(1) {
					c = (char)nextCh();
					if (c < 1 || c == '\n')
						goto EndOfLoop;
					arg->add(c);
					if (c == '"')
						break;
				}
				continue;
			// If quote encountered then scan till closing quote or end of line
			case '\'':
				arg->add(c);
				nextCh();
				while(1) {
					c = (char)nextCh();
					if (c < 1 || c == '\n')
						goto EndOfLoop;
					arg->add(c);
					if (c == '\'')
						break;
				}
				continue;
			case '(':
				Depth++;
				break;
			case ')':
				if (Depth < 1) // check if we hit the end of the arg
					Err(E_CPAREN);
				Depth--;
				break;
			case ',':
				if (Depth == 0)    // comma at outermost level means
					goto EndOfLoop;   // end of argument has been found
				break;
			// On semicolon scan to end of line without copying characters to arg
			case ';':
				goto EndOfLoop;
			//            while(1) {
			//               c = (char)nextCh();
			//               if (c < 1 || c == '\n')
			//                  goto EndOfLoop;
			//            }
			}
			arg->add(c);	       // copy input argument to argstr.
			nextCh();
		}
		EndOfLoop:
		if (Depth > 0)
			Err(E_PAREN);
		//printf("arg:%s|", arg->buf());
		arg->trim();		// get rid of spaces around argument
		return arg;
	}


	/* ---------------------------------------------------------------------------
		int AsmBuf::getParmList(char *parmlist[]);

		Description :
			Used to get parameter list for macro. The parameter list is a series
		of identifiers separated by comma for a macro definition, or a comma
		delimited list of substitutions for a macro instance.

			macro <macro name> <parm1> [,<parm n>]...
				<macro text>
			endm

		Returns
			the number of parameters in the list
	---------------------------------------------------------------------------- */

	int AsmBuf::getParmList(String *plist[])
	{
		String *id;
		int Depth = 0, c, count;

		for (count = 0; count < MAX_MACRO_PARMS; count++) {
			if (plist[count])
				delete plist[count];
			plist[count] = NULL;
		}
		count = 0;
		while(1)
		{
			id = getArg();
			//printf("arg:%s|\r\n", id->buf());
			if (id)
			{
				if (id->len())
				{
					if (count >= MAX_MACRO_PARMS)
					{
						Err(E_MACROPARM);
						delete id;
						goto errxit;
					}
					plist[count] = id;
					count++;
				}
				else
					delete id;
			}
			c = nextNonSpaceLF();

			// Comment ?
			if (c == ';') {
				unNextCh();
				break;
			}
			// Look and see if we got the last parameter
			if (c < 1 || c == '\n')
			{
				unNextCh();
				break;
			}
			if (c != ',')
			{
				Err(E_MACROCOMMA); // expecting ',' separator
				goto errxit;
			}
		}
		//   if (count < 1)
		//      err(17);
		if (count < MAX_MACRO_PARMS)
			plist[count] = NULL;
		errxit:;
		return (count);
	}


	// Evaluate logical 'and' expressions.

	void AsmBuf::andExpr(Value *val)
	{
		Value v2;
		bool fLabel;

		expr(&v2);
		fLabel = v2.fLabel;
		while(1)
		{
			nextNonSpaceLF();
			unNextCh();
			if (getPtr()[0] == '&' && getPtr()[1] == '&')
			{
				move(2);
				expr(val);
				v2.value = v2.value && val->value;
				v2.size = getSizeCh(v2.size, val->size);
				fLabel = false;
			}
			else
				break;
		}
		*val = v2;
		val->fLabel = fLabel;
		return;
	}


	/* -------------------------------------------------------------------
		Note: we cannot do
		value = value || AndExpr()
		because MSC will optimize the expression and not call AndExpr if
		value is true. Since we always want to call andExpr() we force it
		to be called by storing the return value in another variable.
	------------------------------------------------------------------- */

	void AsmBuf::orExpr(Value *val)
	{
		Value v3, v2;
		bool fLabel;

		andExpr(&v3);
		fLabel = v3.fLabel;
		while(1) {
			nextNonSpaceLF();
			unNextCh();
			if (getPtr()[0] == '|' && getPtr()[1] == '|') {
				move(2);
				andExpr(val);
				v2 = *val;
				v3.value = v3.value || v2.value;
				v3.size = getSizeCh(v3.size, v2.size);
				fLabel = false;
			}
			else
				break;
		}
		*val = v3;
		val->fLabel = fLabel;
		return;
	}


	/* -------------------------------------------------------------------
	Relational expressions
		<,>,<=,>=,<>,!=
	------------------------------------------------------------------- */

	void AsmBuf::relational(Value *val)
	{
		Value v2;
		bool fLabel;

		orExpr(&v2);
		fLabel = v2.fLabel;
		while(1) {
			switch(nextNonSpaceLF()) {
			case '<':
				if (peekCh() == '>') {
					nextCh();
					orExpr(val);
					v2.value = v2.value != val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else if (peekCh() == '=') {
					nextCh();
					orExpr(val);
					v2.value = v2.value <= val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else if (peekCh() != '<') {
					orExpr(val);
					v2.value = v2.value < val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else {
					unNextCh();
					goto xitLoop;
				}
				break;

			case '>':
				if (peekCh() == '=') {
					nextCh();
					orExpr(val);
					v2.value = v2.value >= val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else if (peekCh() != '>') {
					orExpr(val);
					v2.value = v2.value > val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else
				{
					unNextCh();
					goto xitLoop;
				}
				break;

			case '=':
				orExpr(val);
				v2.value = v2.value == val->value;
				v2.size = getSizeCh(v2.size, val->size);
				fLabel = false;
				break;

			case '!':
				if (peekCh() == '=') {
					nextCh();
					orExpr(val);
					v2.value = v2.value != val->value;
					v2.size = getSizeCh(v2.size, val->size);
					fLabel = false;
				}
				else {
					unNextCh();
					goto xitLoop;
				}
				break;

			default:
				unNextCh();
				goto xitLoop;
			}
		}
		xitLoop:
		*val = v2;
		val->fLabel = fLabel;
		return;
	}

	// return size character for larger size
	char AsmBuf::getSizeCh(char a, char b)
	{
		if (a==b)
			return a;
		if (b=='B')
			return a;
		if (a=='B')
			return b;
		if (b=='H' && a!='B')
			return a;
		if (a=='H' && b!='B')
			return b;
		if (b=='W')
			return b;
		if (a=='W')
			return a;
		return a;
	}

	char *AsmBuf::ExtractPublicSymbol(char *sName)
	{
		String str;
		String symName(sName);
		int st,nd,nd1;
		st = 0;
		String s1((char *)"public");
j1:
        s1.add(symName);
		st =find(s1, st);
		if (st < 0)
			return (char *)"";
		// Make sure the name matches exactly, and is not a substring.
		if (IsIdentChar(buf()[st+7+symName.len()])) {
			st += 7+symName.len();
			goto j1;
		}
		s1.copy("endpublic");
		nd = find(s1,st);
		if (nd < 0)
			return (char *)"";
		s1.copy("\r\n");
		nd1 = find(s1,nd);
		if (nd1 > 0)
			nd = nd1;
		else
			nd += 9;	// skip over to end of "endpublic"
		str.copy(&buf()[st],nd-st);
		return str.buf();
	}
}
