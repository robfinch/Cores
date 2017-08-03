int SomeFunc(int a, int b, register int c)
{
	return a + b - c;
}

int main()
{
	SomeFunc(10,20,30);
}

