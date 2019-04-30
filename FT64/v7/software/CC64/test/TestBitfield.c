
typedef struct _tagFieldStruct
{
	unsigned int a : 1;
	unsigned int b : 5;
	unsigned int c : 11;
	unsigned int d : 17;
} FS;

int TestBitfield()
{
	FS j,k;

	j.a = 1;
	j.b = 10;

	j.c = j.a + j.b;
	return (j.c);
}
