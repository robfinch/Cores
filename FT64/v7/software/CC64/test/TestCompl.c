
int TestCompl(int a, int b)
{
	int x;
	int y;
	int z;

	x = ~((y=(a & b)));
	x = ~(a & b);
	y = !(a && b);
	z = (a || b);
	return x+y+z;
}
