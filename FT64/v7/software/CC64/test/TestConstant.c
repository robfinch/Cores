
int TestConstant(int a)
{
	int x;

	for (x = 0; x < 100000; x++) {
		a = a + x;
	}
	return a;
}
