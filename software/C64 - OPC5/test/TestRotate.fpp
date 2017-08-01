
int TestRotate(int a, int b)
{
	return ((a << b) | (a >> (16-b));
}

int TestRotate2(register int a, register int b)
{
	return ((a << b) | (a >> (16-b));
}
