
class ClassTest
{
public:
	int a;
	int b;
	static int Add(int a, int b);
};

int ClassTest()
{
	ClassTest a, b;

	a.a = a.a + b.a;
	return a.a;
}

int ClassTest::Add(int a, int b)
{
	return a + b;
}
