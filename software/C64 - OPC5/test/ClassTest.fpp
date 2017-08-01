using name mangler;

class ClassTest
{
public:
	int a;
	int b;
	int Add(int a, int b);
};

class ClassTest2 : ClassTest
{
public:
	int c;
	int d;
};

int ClassTest()
{
	ClassTest a, b;
	ClassTest2 g,h;

	a.a = a.a + b.a + g.c + g.a;
	return a.a;
}

int ClassTest::Add(int c, int d)
{
	return a + b + c + d;
}


