#include <string.h>

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
	int len;
	int qt = 1;

	p = _strdup(buf);
	len = strlen(buf);
	if (p) {
		if (p[0] == '"') {
			qt = 2;
			strcpy_s(p, len+1, buf+1, len+1);
		}
		if (buf[len - 1] == '"')
			p[len - qt] = '\0';
		return (p);
	}
}

