/*
// ============================================================================
//        __
//   \\__/ o\    (C) 1992-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "fpp.h"

extern void IncrLineno();
extern int restore_ch;

char *SkipComments()
{
	char ch;

	if (in_comment == 0)
		return (inptr);
	do {
		if (syntax == CSTD) {
			if (in_comment == 1 && PeekCh() == '\n') {
				in_comment = 0;
				return (&inptr[1]);
			}
			if (in_comment == 2 && PeekCh() == '*' && inptr[1] == '/') {
				in_comment = 0;
				return (&inptr[2]);
			}
		}
		else if (syntax == ASTD) {
			if (in_comment == 1 && PeekCh() == '\n') {
				in_comment = 0;
				return (&inptr[1]);
			}
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

// Fetch a line of text from the input file and append it to the input buffer.

void fetch_line()
{
	int64_t ndx;
	int64_t nn;
	char* p1;

	if (feof(fin)) {
		inbuf->pos = strlen(inbuf->buf);
		char_to_buf(&inbuf, ETB);
		char_to_buf(&inbuf, ETB);
		char_to_buf(&inbuf, ETB);
		return;
	}
	ndx = get_input_buf_ndx();
	/* SLiding buffer needs to write the first page out to the output file.
	if (ndx > 4096) {
		char* ptr, * p1;
		char ch;

		p1 = &inbuf->buf[4096];
		ch = *p1;
		*p1 = 0;
  	ptr = strip_blank_lines(inbuf->buf);
		fputs(ptr, fpo[pass]);
		*p1 = ch;
		memmove(inbuf->buf, &inbuf->buf[4096], inbuf->size - 4096);
		set_input_buf_ptr(ndx - 4096);
	}
	*/
	nn = strlen(inbuf->buf);
	if (nn + MAXLINE > inbuf->size)
		enlarge_buf(&inbuf);
	set_input_buf_ptr(ndx);
	p1 = &inbuf->buf[nn];
	fgets(p1, MAXLINE, fin);
	if (feof(fin)) {
		inbuf->pos = strlen(inbuf->buf);
		char_to_buf(&inbuf, ETB);
		char_to_buf(&inbuf, ETB);
		char_to_buf(&inbuf, ETB);
	}
	IncrLineno();
	if (fdbg) fprintf(fdbg, "Fetched:%s", inptr);
}

// Gets characters from the input stream. Single character pushback.
// Allocates the input buffer on first entry.

int NextCh()
{
	unsigned int ch;
	static int first = 1;
	int64_t ndx;
	int64_t nn;

	if (first) {
		inbuf = new_buf();
		set_input_buf_ptr(0);
		ch = ' ';
	}
	do {
		// Reallocate buffer if it is not large enough. Save and reset input pointer
		// after enlargeing.
		if (first || inptr - inbuf->buf > inbuf->size - MAXLINE - 1) {
			ndx = get_input_buf_ndx();
			enlarge_buf(&inbuf);
			set_input_buf_ptr(ndx);
			if (first)
				set_input_buf_ptr(0);
		}
		ch = *inptr;
		inptr++;
		if (ch == 0 && collect < 0)
			return (0);
		if (ch == 0 || first) {
			first = 0;
			if (collect|1) {
				inptr--;
				fetch_line();
			}
			else {
				if (count_lines(&inbuf->buf[1]) > 0) {
					// Find the next line in the buffer.
					nn = line_length(&inbuf->buf[1]) + 1;
					memmove(inbuf->buf, &inbuf->buf[nn], inbuf->size - nn);
					memset(&inbuf->buf[inbuf->size - nn], 0, nn);
					set_input_buf_ptr(0);
				}
				else {
					set_input_buf_ptr(0);
					memset(inbuf->buf, 0, inbuf->size);
					fgets(inbuf->buf, MAXLINE, fin);
					IncrLineno();
					if (fdbg) fprintf(fdbg, "Fetched:%s", inbuf->buf);
					set_input_buf_ptr(0);
					inbuf->pos = 0;
				}
			}
			ch = *inptr++;
		}
		if (syntax == CSTD) {
			if (in_comment == 0 && ch == '/' && inptr[0] == '/') {
				in_comment = 1;
				inptr += 1;
			}
			if (in_comment == 1 && (ch == '\n' || ch == '\r'))
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
		}
		else if (syntax == ASTD) {
			if (in_comment == 0 && ch == '#') {
				in_comment = 1;
				inptr += 1;
			}
			if (in_comment == 1 && (ch == '\n' || ch == '\r'))
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
	 int64_t n1;

   do {
		 n1 = get_input_buf_ndx();
		 ch = NextCh();
   } while((ch != '\n' || skipnl) && isspace(ch) && ch!=0 && n1 < inbuf->size);
	 if (n1 >= inbuf->size)
		 printf("hi");
   return (ch);
}

void ScanPastEOL()
{
	int ch;

	do {
		ch = NextCh();
	} while (ch != '\n' && ch != 0 && ch != ETB);
}

