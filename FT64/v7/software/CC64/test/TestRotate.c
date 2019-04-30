
int TestRotate(int a, int b)
{
	return ((a << b) | (a >> (16-b)));
}

int TestRotate2(register int a, register int b)
{
	return ((a << b) | (a >> (16-b)));
}

int TestRotate3(register unsigned int a, register unsigned int b)
{
	return ((a << b) | (a >> (16-b)));
}

int TestRotate4(register int a, register int b)
{
	return (a <<< b);
}

int TestRotate5(register int a, register int b)
{
	return (a >>> b);
}
