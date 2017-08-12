
int TestRotate(int a, int b)
{
	return ((a << b) | (a >> (16-b)));
}

int TestRotate2(register int a, register int b)
{
	return ((a << b) | (a >> (16-b)));
}

long TestRotate3(long a, long b)
{
	return ((a << b) | (a >> (32-b)));
}

unsigned long TestRotate4(unsigned long a, long b)
{
	return ((a << b) | (a >> (32-b)));
}

