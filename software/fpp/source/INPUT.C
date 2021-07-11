#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

char *SkipComments()
{
	if (in_comment == 0)
		return (inptr);
	do {
		if (in_comment == 1 && inptr[0] == '\n') {
			in_comment = 0;
			return (&inptr[1]);
		}
		if (in_comment==2 && inptr[0] == '*' && inptr[1] == '/') {
			in_comment = 0;
			return (&inptr[2]);
		}
		inptr++;
	} while (in_comment != 0);
	inptr--;
	return (inptr);
}

// Gets characters from the input stream. Single character pushback.
int NextCh()
{
	unsigned int ch;
	static int first = 1;

	do {
		ch = *inptr++;
		if (ch == 0 || first) {
			first = 0;
			if (collect) {
				inptr--;
				fgets(inptr, MAXLINE, fin);
				if (fdbg) fprintf(fdbg, "Fetched:%s", inptr);
			}
			else {
				inptr = inbuf;
				memset(inbuf, 0, sizeof(inbuf));
				fgets(inbuf, MAXLINE, fin);
				if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf);
				inptr = inbuf;
			}
			ch = *inptr++;
		}
		if (ch == '/' && inptr[0] == '/') {
			in_comment = 1;
			inptr += 1;
		}
		if (in_comment == 1 && (ch == '\n' || ch=='\r'))
			in_comment = 0;
		if (ch == '/' && inptr[0] == '*') {
			in_comment = 2;
			inptr++;
		}
		if (ch == '*' && inptr[0] == '/') {
			ch = inptr[1];
			inptr += 2;
			in_comment = 0;
		}
	} while (ch && in_comment != 0 && inptr < &inbuf[3000]);
	return (ch & 0xff);
}

// Put characters back into input buffer.
void unNextCh()
{
	if (inptr > inbuf) {
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

