#include "stdafx.h"
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stddef.h>
#include <string.h>

#define BASE_MAX	36

static const char digits[] = {
	"0123456789abcdefghijklmnopqrstuvwxyz" };
static const char ndigs[BASE_MAX+1] = {
	0,0,33,21,17,14,13,12,11,11,
	10,10,9,9,9,9,9,8,8,8,
	8,8,8,8,7,7,7,7,7,7,
	7,7,7,7,7,7,7 };

unsigned long _Stoul(const char *s, char **endptr, int base)
{
	const char *sc, *sd;
	const char *s1, *s2;
	char sign;
	ptrdiff_t n;
	unsigned long x, y;

	for (sc = s; my_isspace(*sc); ++sc)
		;
	sign = *sc=='-' || *sc=='+' ? *sc++ : '+';
	if (base < 0 || base == 1 || BASE_MAX < base)
	{
		if (endptr)
			*endptr = (char *)s;
		return (0);
	}
	else if (base) {
		if (base==16 && *sc=='0' && (sc[1]=='x' || sc[1]=='X'))
			sc += 2;
	}
	else if (*sc != '0')
		base = 10;
	else if (sc[1]=='x' || sc[1]=='X')
		base = 16, sc += 2;
	else
		base = 8;
	for (s1 = sc; *sc == '0'; ++sc)
		;
	x = 0;
	for (s2 = sc; (sd = (const char *)memchr((const void *)digits,tolower(*sc),base)) != (char *)NULL; ++sc) {
		y = x;
		x = x * base + (sd - digits);
	}
	if (s1 == sc) {
		if (endptr)
			*endptr = (char *)s;
		return (0);
	}
	n = sc - s2 - ndigs[base];
	if (n < 0)
		;
	else if (0 < n || x < x - sc[-1] || (x - sc[-1]) / base != y) {
		errno = ERANGE;
		x = ULONG_MAX;
	}
	if (sign=='-') {
		x = ~x;
		x++;
	}
	if (endptr)
		*endptr = (char *)sc;
	return (x);
}
