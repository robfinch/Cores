#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

char *SkipComments()
{
	char ch;

	if (in_comment == 0)
		return (inptr);
	do {
		if (in_comment == 1 && PeekCh() == '\n') {
			in_comment = 0;
			return (&inptr[1]);
		}
		if (in_comment==2 && PeekCh() == '*' && inptr[1] == '/') {
			in_comment = 0;
			return (&inptr[2]);
		}
		ch = NextCh();
		if (ch == 0) {
			err(24);		// unterminated comment
			exit(24);
		}
	} while (in_comment != 0);
	unNextCh();
	return (inptr);
}

// Gets characters from the input stream. Single character pushback.
// Allocates the input buffer on first entry.

int NextCh()
{
	unsigned int ch;
	static int first = 1;
	int ndx;
	char* p;

	if (first) {
		inbuf = new_buf();
		inptr = NULL;
		ch = ' ';
	}
	do {
		// Reallocate buffer if it is not large enough. Save and reset input pointer
		// after enlargeing.
		if (first || inptr - inbuf->buf > inbuf->size - MAXLINE - 1) {
			ndx = inptr - inbuf;
			inbuf = enlarge_buf(inbuf);
			inptr = inbuf + ndx;
			if (first)
				inptr = inbuf;
		}
		ch = *inptr++;
		if (ch == 0 || first) {
			first = 0;
			if (collect) {
				inptr--;
				fgets(inptr, MAXLINE, fin);
				if (fdbg) fprintf(fdbg, "Fetched:%s", inptr);
			}
			else {
				inptr = inbuf->buf;
				memset(inbuf->buf, 0, inbuf->size);
				fgets(inbuf->buf, MAXLINE, fin);
				if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf->buf);
				inptr = inbuf->buf;
			}
			ch = *inptr++;
		}
		if (in_comment == 0 && ch == '/' && inptr[0] == '/') {
			in_comment = 1;
			inptr += 1;
		}
		if (in_comment == 1 && (ch == '\n' || ch=='\r'))
			in_comment = 0;
		if (in_comment == 0 && ch == '/' && inptr[0] == '*') {
			in_comment = 2;
			inptr += 2;
		}
		if (in_comment == 2 && ch == '*' && inptr[0] == '/') {
			ch = inptr[1];
			inptr += 2;
			in_comment = 0;
		}
	} while (ch && in_comment != 0 && inptr < inbuf->buf + 30000);
	if (in_comment) {
		err(24);	// unterminate comment
	}
	return (ch & 0xff);
}

// Put characters back into input buffer.
void unNextCh()
{
	if (inptr > inbuf->buf) {
      inptr--;
	  CharCount--;
	}
}

// Skips spaces in input
void SkipSpaces()
{
   int c;

   do {
      c = NextCh();
   } while(c != '\n' && isspace(c) && c != 0);
   unNextCh();
}

// Gets the next non space character
int NextNonSpace(int skipnl)
{
   int ch;

   do {
      ch = NextCh();
   } while((ch != '\n' || skipnl) && isspace(ch) && ch!=0);
   return (ch);
}

void ScanPastEOL()
{
	int ch;

	do {
		ch = NextCh();
	} while (ch != '\n' && ch != 0);
}

