#define null	0

char *memchr(register char *p, register char val, register int n)
{
	char *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return null;
}

