
typedef struct _tagTestStruct
{
	int a;
	int b;
	int c : 14;
	int d : 2;
} TestStruct;

int TestStruct()
{
	TestStruct ts;

	ts.a = 1;
	ts.b = 2;
	ts.c = 3;
	ts.d = 1;
	return (ts.c+ts.d);
}

TestStruct TestStruct2(register int a, register int c, register int d)
{
	TestStruct b;

	b.a = a;
	return (b);
}

