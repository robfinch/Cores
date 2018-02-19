#define null	0

naked char *memcpy(register byte *d, register byte *s, register int size)
{
    asm {
		beq		r20,r0,.xit
		sub		sp,sp,#8
		sw		r3,[sp]
		sub		r2,r20,#1
		ldi		r1,#0
.again:
		lb		r3,[r1+r19]
		sb		r3,[r1+r18]
		ibne	r1,r2,.again
		lw		r3,[sp]
		add		sp,sp,#8
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memcpyC(register char *d, register char *s, register int size)
{
    asm {
		beq		r20,r0,.xit
		sub		sp,sp,#8
		sw		r3,[sp]
		sub		r2,r20,#1
		ldi		r1,#0
.again:
		lc		r3,[r19+r1*2]
		sc		r3,[r18+r1*2]
		ibne	r1,r2,.again
		lw		r3,[sp]
		add		sp,sp,#8
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memcpyW(register int *d, register int *s, register int size)
{
    asm {
		beq		r20,r0,.xit
		sub		sp,sp,#8
		sw		r3,[sp]
		sub		r2,r20,#1
		ldi		r1,#0
.again:
		lw		r3,[r19+r1*8]
		sw		r3,[r18+r1*8]
		ibne	r1,r2,.again
		lw		r3,[sp]
		add		sp,sp,#8
.xit:
		mov		r1,r18
		ret
    }
}

naked char *memset(register char *p, register char val, register int size)
{
	asm {
		beq		r20,r0,.xit
		sub		r2,r20,#1
		ldi		r1,#0
.again:
		sb		r19,[r1+r18]
		ibne	r1,r2,.again
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memsetC(register int *p, register int val, register int size)
{
	asm {
		beq		r20,r0,.xit
		mov		r1,r0
.again:
		sc		r19,[r18+r1*2]
		add		r1,r1,#1
		bltu	r1,r20,.again
.xit:
		mov		r1,r18
		ret
    }
}

naked int *memsetH(register int *p, register int val, register int size)
{
	asm {
		beq		r20,r0,.xit
		mov		r1,r0
.again:
		sh		r19,[r18+r1*4]
		add		r1,r1,#1
		bltu	r1,r20,.again
.xit:
		mov		r1,r18
		ret
    }
}

char *memmove(register __int8 *dst, register __int8 *src, register int count)
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

int *memmoveC(register __int16 *dst, register __int16 *src, register int count)
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

char *memchr(register __int8 *p, register __int8 val, register int n)
{
	__int8 *su;

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
		sub		sp,sp,#8
		sw		r3,[sp]
.j1:
		lc		r3,[r18+r1*2]
		add 	r1,r1,#1
		bne		r3,r0,.j1

		sub		r1,r1,#1
		lw		r3,[sp]
		add		sp,sp,#8
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
