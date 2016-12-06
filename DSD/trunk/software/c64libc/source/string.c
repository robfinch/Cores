#define null	0

naked char *memcpy(register char *d, register char *s, register int size)
{
    asm {
		beq		r20,r0,.xit
		push	r3
		mov		r1,r0
.again:
		lhu		r3,[r1+r19]
		sh		r3,[r1+r18]
		addi	r1,r1,#1
		bne		r1,r20,.again
		pop		r3
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memcpyW(register int *d, register int *s, register int size)
{
    asm {
		beq		r20,r0,.xit
		push	r3
		push	r20
		mov		r1,r0
		shl		r20,r20,#1
.again:
		lw		r3,[r1+r19]
		sw		r3,[r1+r18]
		addi	r1,r1,#2
		bne		r1,r20,.again
		pop		r20
		pop		r3
.xit:
		mov		r1,r18
		ret
    }
}

naked char *memset(register char *p, register char val, register int size)
{
	asm {
		beq		r20,r0,.xit
		mov		r1,r0
.again:
		sh		r19,[r1+r18]
		addi	r1,r1,#1
		bne		r1,r20,.again
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memsetW(register int *p, register int val, register int size)
{
	asm {
		beq		r20,r0,.xit
		mov		r1,r0
		push	r20
		shl		r20,r20,#1
.again:
		sw		r19,[r1+r18]
		add		r1,r1,#2
		bltu	r1,r20,.again
		pop		r20
.xit:
		mov		r1,r18
		ret
    }
}

char *memmove(register char *dst, register char *src, register int count)
{
	int nn;

	if (dst < src) {
		for (nn = 0; nn < count; nn++)
			dst[nn] = src[nn];
	}
	else {
		for (--count; count >= 0; count--)
			dst[count] = src[count];
	}
	return (dst);
}

int *memmoveW(register int *dst, register int *src, register int count)
{
	int nn;

	if (dst < src) {
		for (nn = 0; nn < count; nn++)
			dst[nn] = src[nn];
	}
	else {
		for (--count; count >= 0; count--)
			dst[count] = src[count];
	}
	return (dst);
}

char *memchr(register char *p, register char val, register int n)
{
	char *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return null;
}

naked int strlen(register char *p)
{
	asm {
		mov		r1,r0			// length = 0
		beq		r18,r0,.xit2
		push	r3
.j1:
		lhu		r3,[r1+r18]
		addi	r1,r1,#1
		bne		r3,r0,.j1
.xit:
		subi	r1,r1,#1
		pop		r3
.xit2:
		ret
	}
}

char *strcpy(register char *d, register char *s)
{
	int nn;

	for (nn = 0; s[nn]; nn++)
		d[nn] = s[nn];
	d[nn] = '\0';
	return d;
}

char *strncpy(register char *d, register char *s, register int size)
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

int strncmp(register unsigned char *a, register unsigned char *b, register int len)
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

char *strchr(register char *p, register char val, register int n)
{
	char *su;

	for (su = p; n > 0; ++su, --n)
		if (*su==val)
			return su;
	return null;
}
