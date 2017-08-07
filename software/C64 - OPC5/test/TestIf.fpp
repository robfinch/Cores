
int TestIf(int a, int b)
{
	if (a < b)
		return a;
	elsif (a==10)
		return 10;
	else
		return b;
}

int TestIf2(int a, int b)
{
	if (a and b)
		return a;
	elsif (a or b)
		return 10;
	else
		return b;
}

