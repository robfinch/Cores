
long TestLong(int a, int b)
{
	long c, d, e;
	long x;
	int r;
	long r2;

	for (x = 0; x < 100000L; x++) {
		c = d + e + b - a;
		c = e * x;
	}
	x = c / d;
	d = (x >> 15) | (x << (31-15));

	r = d < x;
	r2 = d > x;
	return c;
}
