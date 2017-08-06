#define null	0

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
