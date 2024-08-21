#include <ctype.h>>
#include <malloc.h>
#include <string.h>
#include <inttypes.h>

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
		return (p);
	}
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
		if (*q == '\n') {
			while (*q == '\n')
				q++;
			sol = q;
		}
		else {
			while (*q != '\n' && *q)
				q++;
			memcpy_s(&buf[pos], nn-pos, sol, q - sol);
			pos += q - sol;
			buf[pos] = '\n';
			pos++;
			if (*q) {
				while (*q == '\n')
					q++;
				sol = q;
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

