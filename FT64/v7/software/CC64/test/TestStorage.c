typedef struct
{
	int a;
} A;

typedef struct
{
	char s[50];
	A a1[25];
	A a2;
	A a3;
	int b;
} B;

typedef struct
{
	int c;
	A *pa;
} C;

char c1;
__int8 i8;

A gblA;
B gblB = {
	"Hello world"
};

int iarray[100][20];

B sarray[100][30];

C cvar;
C dvar = { 10, 20 };

B s2array[100][30];

C vararray[15];
