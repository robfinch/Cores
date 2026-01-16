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
#include <ctype.h>
#include <malloc.h>
#include <string.h>
#include <inttypes.h>
#include "fpp.h"

/* -----------------------------------------------------------------------------
		Description:
			Strips the leading and trailing double quotes from a text string. 
			
		Parameters:
			(char *) - pointer to text string

		Returns:
			(char *) - pointer to text string with quotes removed.
-------------------------------------------------------------------------------- */

char *strip_quotes(char *buf)
{
	char *p;
	int64_t len;
	int qt = 1;

	p = _strdup(buf);
	len = strlen(buf);
	if (p) {
		if (p[0] == '"') {
			qt = 2;
			strncpy_s(p, len+1, buf+1, len+1);
		}
		if (buf[len - 1] == '"')
			p[len - qt] = '\0';
	}
	return (p);
}

// Test if a line of text is blank.

int is_blank(char* buf)
{
	char* p;

	if (buf == NULL)
		return (1);
	for (p = buf; *p; p++) {
		if (!isspace(*p) && p[0] != '\r' && p[0] != '\n')
			return (0);
	}
	return (1);
}

// Strip the blanks lines from a text buffer.

char* strip_blank_lines(char* p)
{
	char* q;
	char* buf;
	char* sol;
	int nn;
	int64_t pos;

	nn = (strlen(p) + 4095) & 0xfffff000LL;
	if (nn == 0)
		return (NULL);
	buf = malloc(nn);
	if (buf == NULL)
		return (NULL);
	sol = p;
	pos = 0;
	for (q = p; *q; q++) {
		// Trim leading spaces at start of line.
		while (isspace(*q))
			q++;
		sol = q;
		if (*q == LF) {
			while (*q == LF)
				q++;
			sol = q;
		}
		else {
			while (*q != LF && *q)
				q++;
			memcpy_s(&buf[pos], nn-pos, sol, q - sol +1);
			pos += q - sol;
			buf[pos] = LF;
			pos++;
			if (*q) {
				while (*q == LF)
					q++;
				sol = q;
				// q will increment at the end of the loop, cancel the increment so the
				// start of next line is picked up properly
				q--;
			}
		}
		if (*q == 0)
			break;
	}
	buf[pos] = 0;
	return (buf);
}

char* trim(char* str)
{
	int ii;
	int nn;

	rtrim(str);
	nn = strlen(str);
	for (ii = 0; ii < nn && isspace(str[ii]); ii++)
		;
	memmove(str, &str[ii], nn - ii + 1);
	return (str);
}

char* strip_directives(char* buf)
{
	if (buf[0] == '.')
		return (" ");
	else return
		buf;
}


int count_lines(char* buf)
{
	int c;
	int ii;

	for (c = ii = 0; buf[ii]; ii++) {
		if (buf[ii] == '\n')
			c++;
	}
	return (c);
}

int line_length(char* buf)
{
	int ii;

	for (ii = 0; buf[ii]; ii++) {
		if (buf[ii] == '\n')
			break;
	}
	return (ii);
}

int peek_eof()
{
	if (PeekCh() == ETB)
		return 1;
	if (PeekCh() == 0)
		return 1;
	return 0;
}
