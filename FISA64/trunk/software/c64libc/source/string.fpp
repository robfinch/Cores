
byte *memcpy(byte *d, byte *s, int size)
{
    asm {
        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lb    r4,[r1]
        sb    r4,[r2]
        addui r1,r1,#1
        addui r2,r2,#1
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return d;
}

short int *memcpyH(short int *d, short int *s, int size)
{
    asm {
        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lh    r4,[r1]
        sh    r4,[r2]
        addui r1,r1,#4
        addui r2,r2,#4
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return d;
}

int *memcpyW(int *d, int *s, int size)
{
    asm {
        lw    r1,32[bp]
        lw    r2,24[bp]
        lw    r3,40[bp]
    .0001:
        lw    r4,[r1]
        sw    r4,[r2]
        addui r1,r1,#8
        addui r2,r2,#8
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return d;
}

byte *memset(byte *p, byte val, int size)
{
	asm {
        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sb    r2,[r1]
        addui r1,r1,#1
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return p;
}

short int *memsetH(short int *p, short int val, int size)
{
	asm {
        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sh    r2,[r1]
        addui r1,r1,#4
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return p;
}

int *memsetW(int *p, int val, int size)
{
	asm {
        lw    r1,24[bp]
        lw    r2,32[bp]
        lw    r3,40[bp]
.0001:
        sw    r2,[r1]
        addui r1,r1,#8
        subui r3,r3,#1
        bgt   r3,.0001
    }
	return p;
}

byte *memchr(byte *p, byte val, int n)
{
	byte *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return 0;
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
	return 0;
}

