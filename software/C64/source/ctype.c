#include <ctype.h>

int (isalnum)(int c)
{
	return (_Ctype[c] & (_DI|_LO|_UP|_XA));
}

int (isalpha)(int c)
{
	return (_Ctype[c] & (_LO|_UP|_XA));
}

int (iscntrl)(int c)
{
	return (_Ctype[c] & (_BB|_CN));
}

int (isdigit)(int c)
{
	return (_Ctype[c] & _DI);
}

int (isgraph)(int c)
{
	return (_Ctype[c] & (_DI|_LO|_PU|_UP|_XA));
}

int (islower)(int c)
{
	return (_Ctype[c] & _LO);
}

int (isprint)(int c)
{
	return (_Ctype[c] & (_DI|_LO|_PU|_SP|_UP|_XA));
}

int (ispunct)(int c)
{
	return (_Ctype[c] & _PU);
}

int (isspace)(int c)
{
	return (_Ctype[c] & (_CN|_SP|_XS));
}

int (isupper)(int c)
{
	return (_Ctype[c] & _UP);
}

int (isxdigit)(int c)
{
	return (_Ctype[c] & _XD);
}

int (tolower)(int c)
{
	return (_Tolower[c]);
}

int (toupper)(int c)
{
	return (_Toupper[c]);
}

