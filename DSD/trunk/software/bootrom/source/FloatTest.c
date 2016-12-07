
extern pascal int prtflt(register float, register int, register int, register char);
extern void DBGDisplayString(register char *p);

static naked inline int GetButton()
{
	asm {
		lw		r1,BUTTONS
	}
}


static void TestAddsub(register float a, register float b)
{
	float sum, dif;

	sum = a + b;
	dif = a - b;
	prtflt(a,20,16,'E');
	DBGDisplayString(" + ");
	prtflt(b,20,16,'E');
	DBGDisplayString(" = ");
	prtflt(sum,20,16,'E');
	DBGDisplayString("\r\n");
	prtflt(a,20,16,'E');
	DBGDisplayString(" - ");
	prtflt(b,20,16,'E');
	DBGDisplayString(" = ");
	prtflt(dif,20,16,'E');
	DBGDisplayString("\r\n");
}

static void TestMul(register float a, register float b)
{
	float prod;

	prod = a * b;
	prtflt(a,20,16,'E');
	DBGDisplayString(" * ");
	prtflt(b,20,16,'E');
	DBGDisplayString(" = ");
	prtflt(prod,20,16,'E');
	DBGDisplayString("\r\n");
}

static void TestEval()
{
	float x, y, z;

	x = 90071992254740994.0;	// 2^53 + 2
	DBGDisplayString("x= ");
	prtflt(x,39,30,'E');
	y = 1.0 - 1.0/65536.0;
	DBGDisplayString(" y= ");
	prtflt(y,39,30,'E');
	z = x + y;
	DBGDisplayString("\r\nx+y= ");
	prtflt(z,39,30,'E');
	DBGDisplayString("\r\nIEEE-754 result: 90071992254740994.0 dbl\r\n");
	DBGDisplayString("\r\nIEEE-754 result: 90071992254740996.0 xdbl\r\n");
}

void FloatTest()
{
	int bad;
	float pi = 3.1415926535897932384626;
	float nx,a,b;

	while(GetButton());
	DBGDisplayString("  Float Test\r\n");
	DBGDisplayString("  PI is ");
	prtflt(pi,20,16,'E');
	DBGDisplayString("\r\n10.0+10.0=");
	a = 10.0;
	b = 10.0;
	prtflt(a+b,20,16,'E');
	DBGDisplayString("\r\n10.0*10.0=");
	prtflt(a*b,20,16,'E');
	DBGDisplayString("\r\n300.0/25.0=");
	a = 300.0;
	b = 25.0;
	prtflt(a/b,20,16,'E');
	DBGDisplayString("\r\n");
	// Test signed zero
	a = 0.0; b = -0.0;
	bad = 0;
	if (a != b)
		bad = 1;
	nx = -a;
	if (nx != a)
		bad = 1;

	TestAddsub(+0.0, +0.0);
	TestAddsub(+0.0, -0.0);
	TestAddsub(-0.0, +0.0);
	TestAddsub(-0.0, -0.0);
	TestAddsub(+1.0, +1.0);
	TestAddsub(+1.0, -1.0);

	TestMul(+0.0, +0.0);
	TestMul(+0.0, -0.0);
	TestMul(-0.0, +0.0);
	TestMul(-0.0, -0.0);

	if (bad)
		DBGDisplayString("\r\nSigned zero fail.");
	
	TestEval();
	GetButton();
}
