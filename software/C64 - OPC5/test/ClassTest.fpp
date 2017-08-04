using name mangler;

class ClassTest
{
public:
	int a;
	int b;
	int Add(int a, int b);
};

int ClassTest()
{
	ClassTest a, b;

	a.a = a.a + b.a;
	return a.a;
}

int ClassTest::Add(int c, int d)
{
	return a + b + c + d;
}
