
int min(register int a, register int b)
{
	if (a < 0)
		throw 21;
	return a < b ? a : b;
}

int max(register int a, register int b)
{
	return a > b ? a : b;
}

unsigned int minu(register unsigned int a, register unsigned int b)
{
	return a < b ? a : b;
}

naked inline int amin(register int a, register int b)
{
	asm {
		min		r1,r18,r18,r19
	}
}
