#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fpp.h"

// Gets characters from the input stream. Single character pushback.
int NextCh()
{
	unsigned int ch;
	static int first = 1;

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

