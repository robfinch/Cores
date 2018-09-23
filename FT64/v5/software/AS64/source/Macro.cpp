#include "stdafx.h"

int Macro::inst = 0;

// Substitute the argument list into the macro body.

char *Macro::SubArgs(Arglist *al)
{
	char *buf, *bdy;
	char *p, *q;
	int ndx;
	int bufsz;

	bdy = body;
	buf = new char[16000];
	ZeroMemory(buf, 16000);
	bufsz = 16000;
	for (p = buf; *bdy; bdy++) {
		// If macro instance indicator found, substitute the instance number.
		if (*bdy == '@') {
			p += sprintf_s(p, bufsz - (p - buf), "%d", inst);
			*p = '\0';
		}
		else if (*bdy == MACRO_PARM_MARKER) {
			if (isdigit(*(bdy+1))) {
				bdy++;
				ndx = *bdy - '0';
				if (ndx < parms.count && ndx < al->count) {
					// Copy the parameter from the arg list to the output buffer.
					if (&buf[bufsz] - p > al->args[ndx].text.length()) {
						strcpy(p, (char *)al->args[ndx].text.c_str());
						while (*p) p++;
					}
				}
			}
			else {
				*p = *bdy;
				p++;
			}
		}
		// Not a parameter marker, just copy text to output.
		else {
			*p = *bdy;
			p++;
		}
		if (&buf[bufsz] - p < 20) {
			ndx = p - buf;
			q = new char[bufsz + 10000];
			memcpy(q, buf, bufsz);
			bufsz += 10000;
			delete[] buf;
			buf = q;
			p = &buf[ndx];
		}
	}
	*p = '\0';
	return (buf);
}


void SkipBlockComment()
{
	char c;

	do {
		c = *inptr;
		inptr++;
		if (c == '*') {
			c = *inptr;
			inptr++;
			if (c == '/')
				break;
			--inptr;
		}
	} while (c > 0);
}

int ProcessUnquoted()
{
	char c;

	c = *inptr;
	if (c == '/') {
		c = *inptr;
		inptr++;
		c = *inptr;
		inptr++;
		// Block comment ?
		if (c == '*') {
			SkipBlockComment();
			c = *inptr;
			if (c > 0)
				return (1);
			else {
				printf("End of file in block comment. %d\n", lineno);
				return (0);
			}
		}
		// Comment to EOL ?
		else if (c == '/') {
			ScanToEOL();
			c = *inptr;
			if (c > 0)
				return (0);
		}
		else {
			c = '/';
			--inptr;
		}
	}
	return (1);
}

int CountLeadingSpaces()
{
	int count;

	count = 0;
	while (*inptr == ' ' || *inptr == '\t') {
		inptr++;
		count++;
	}
	return (count);
}

// ---------------------------------------------------------------------------
//   Description :
//      Gets the body of a macro. All macro bodies must be < 2k in size. Macro
//   parameters are matched up with their positions in the macro. A $<number>
//   (as in $1, $2, etc) is substituted in the macro body in place of the
//   parameter name (we don't actually care what the parameter name is).
//      Macros continued on the next line with '\' are also processed. The
//   newline is removed from the macro.
// ----------------------------------------------------------------------------

char *Macro::GetBody()
{
	char *b, *id = NULL, *p1, *p2;
	char *buf;
	int ii, found, c;
	int InQuote = 0;
	int count = 16000;
	bool abort = false;

	try {
		buf = new char[count];
		ZeroMemory(buf, count);
		SkipSpaces();
		for (b = buf; count >= 0; )
		{
			// First search for an identifier to substitute with parameter
			if (parms.count > 0) {
				ii = CountLeadingSpaces();
				count -= ii;
				if (count < 0)
					break;
				memcpy(b, inptr - ii, ii);
				b += ii;
				p1 = inptr;
				NextToken();
				p2 = inptr;
				if (token == tk_endm)
					break;
				if (token == tk_id) {
					for (found = ii = 0; ii < parms.count && !abort; ii++) {
						if (parms.args[ii].text.compare(lastid) == 0) {
							*b = '\x14';
							b++;
							count--;
							if (count < 0) {
								abort = true;
							}
							else {
								*b = '0' + (char)ii;
								b++;
								found = 1;
								break;
							}
						}
					}
					if (abort)
						break;
					// if the identifier was not a parameter then just copy it to
					// the macro body
					if (!found) {
						count -= p2 - p1;
						if (count < 0)
							break;
						memcpy(b, p1, p2 - p1);
						b += p2 - p1;
					}
				}
				else
					inptr = p1;    // reset inptr if no identifier found
			}
			if (token == tk_endm)
				break;
			if (token != tk_id) {
				memcpy(b, p1, p2 - p1);
				b += p2 - p1;
				inptr = p2;
				c = *inptr;
				//inptr++;
				if (c == '"') {
					inptr++;
					InQuote = !InQuote;
				}
				if (!InQuote) {
					p1 = inptr;
					c = ProcessUnquoted();
					if (count - (inptr - p1) < 0) {
						count = -1;
						break;
					}
					memcpy(b, p1, (inptr - p1));
					b += (inptr - p1);
					if (c == 0)
						break;
					c = inptr[-1];
				}
				if (c < 1) {
					if (InQuote)
						printf("End of file in quote. %d\n", lineno);
					break;
				}
			}
		}

		if (count < 0) {
			delete[] buf;
			printf("Expanded macro is too large. %d\n", lineno);
			body = new char[20];
			strcpy(body, "<too large>");
			return (body);
		}
		else {
			*b = '\0';
			--b;
			// Trim off trailing spaces.
			while ((*b == ' ' || *b == '\t') && b > buf) {
				b--;
			}
			b++;
			*b = '\0';
			body = new char[strlen(buf) + 10];
			strcpy(body, buf);
			delete[] buf;
			return (body);
		}
	}
	catch (...) {
		printf("Thrown error\n");
	}
}


void Arg::Clear()
{
	text = "";
}

// ---------------------------------------------------------------------------
//   Description :
//      Gets an argument to be substituted into a macro body. Note that the
//   round bracket nesting level is kept track of so that a comma in the
//   middle of an argument isn't inadvertently picked up as an argument
//   separator.
// ---------------------------------------------------------------------------

void Arg::Get()
{
	int Depth = 0;
	int c;
	char ch;
	char *st;

	SkipSpaces();
	st = inptr;
	while(1)
	{
    c = *inptr;
	  inptr++;
		if (c < 1) {
			if (Depth > 0)
				printf("err16\r\n");
			break;
		}
		if (c == '(')
			Depth++;
		else if (c == ')') {
			if (Depth < 1) {  // check if we hit the end of the arg list
				--inptr;
				break;
			}
			Depth--;
		}
		else if (Depth == 0 && c == ',') {   // comma at outermost level means
			--inptr;
			break;                           // end of argument has been found
		}
		else if (Depth == 0 && (c=='\r' || c=='\n')) {
			--inptr;
			break;
	  }
   }
	 ch = *inptr;
	 *inptr = '\0';
	 text = std::string(st);
	 *inptr = ch;
//   if (argbuf[0])
//	   if (fdbg) fprintf(fdbg,"    macro arg<%s>\r\n",argbuf);
   return;
}

void Arglist::Get()
{
	int nn;
	char lastch;
	bool done = false;

	for (nn = 0; nn < 10; nn++)
		args[nn].Clear();
	count = 0;
j1:
	SkipSpaces();
	switch (*inptr) {
	case '\n':
		lineno++;
	case '\r':
		inptr++;
		goto j1;
	case '(':
		inptr++;
		SkipSpaces();
		for (; count < 10 && !done; count++) {
			args[count].Get();
			switch (*inptr) {
				// Arg list can continue on next line
			case '\n':
				lineno++;
			case '\r':
				inptr++;
				continue;
			case ')':
				done = true;
				inptr++;
				break;
			case ',':
				inptr++;
				SkipSpaces();
				continue;
			case '\0':
				break;
			default:
				inptr++;
			}
		}
		break;
	default:;
	}
}

// ---------------------------------------------------------------------------
//   Description :
//      Used during the definition of a macro to get the associated parameter
//   list.
//
//   Returns
//      pointer to first parameter in list.
// ----------------------------------------------------------------------------

int Macro::GetParmList()
{
	int id;
	int Depth = 0, c;

	parms.count = 0;
	while(1)
	{
		NextToken();
		if (token==tk_id) {
			if (parms.count >= 20) {
				printf("Too many macro parameters %d.\n", lineno);
				goto errxit;
			}
			parms.args[parms.count].text = std::string(lastid);
			parms.count++;
		}
	  do {
			SkipSpaces();
			c = *inptr;
			inptr++;
			if (c=='\\') {
				ScanToEOL();
				inptr++;
			}
		}
		while (c=='\\');
    if (c == ')') {   // we've gotten our last parameter
      inptr--;
      break;
    }
    if (c != ',') {
			printf("Expecting ',' in macro parameter list %d.\n", lineno);
      goto errxit;
    }
  }
errxit:;
   return (parms.count);
}


// -----------------------------------------------------------------------------
//   Description :
//      Copies a macro into the input buffer. Resets the input buffer pointer
//   to the start of the macro.
//
//   slen; - the number of characters being substituted
// -----------------------------------------------------------------------------

void Macro::Substitute(char *what, int slen)
{
	int mlen, dif, nchars;
	int nn;
	char *p;

	mlen = strlen(what);          // macro length
	dif = mlen - slen;
	nchars = inptr - masterFile;         // calculate number of characters that could be remaining
	if (dif > 10000) {
		p = new char[masterFileLength + dif + 10000];
		memcpy(p, masterFile, masterFileLength);
		masterFile = p;
		masterFileLength = masterFileLength + dif + 10000;
		inptr = &masterFile[nchars];
	}
	memmove(inptr+dif, inptr, masterFileLength-500-nchars-dif);  // shift open space in input buffer
	inptr -= slen;                // reset input pointer to start of replaced text
	memcpy(inptr, what, mlen);    // copy macro body in place over identifier
	inst++;
}

