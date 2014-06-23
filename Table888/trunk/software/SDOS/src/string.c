#define null	0

byte *memcpy(byte *d, byte *s, int size)
{
	int nn;

	for (nn = 0; nn < size; nn++)
		d[nn] = s[nn];
	return d;
}

byte *memset(byte *p, byte val, int size)
{
	int nn;

	for (nn = 0; nn < size; nn++)
		p[nn] = val;
	return p;
}

byte *memchr(byte *p, byte val, int n)
{
	byte *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return null;
}

int strlen(char *p)
{
	int n;

	if (p==(char *)0) return 0;
	for (n = 0; p[n]; n++)
		;
	return n;
}

char *strcpy(char *d, char *s)
{
	int nn;

	for (nn = 0; s[nn]; nn++)
		d[nn] = s[nn];
	d[nn] = '\0';
	return d;
}

char *strncpy(char *d, char *s, int size)
{
	int nn;

	for (nn = 0; nn < size; nn++) {
		d[nn] = s[nn];
		if (s[nn]=='\0')
			break;
	}
	for (; nn < size; nn++)
		d[nn] = '\0';
	return d;
}

int strncmp(unsigned char *a, unsigned char *b, int len)
{
	unsigned char *ua;
	unsigned char *ub;

	ua = a;
	ub = b;
	if (ua==ub)	// duh
		return 0;
	for (; len > 0; ua++, ub++, len--)
		if (*ua != *ub)
			return *ua < *ub ? -1 : 1;
		else if (*ua == '\0')
			return 0;
	return 0;
}

char *strchr(char *p, char val, int n)
{
	char *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return null;
}

