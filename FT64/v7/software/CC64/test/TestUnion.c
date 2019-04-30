typedef struct
{
	int i;
	float f;
} UT;

UT a.i = 21;
UT b.f = 42.5;

int TestUnion()
{
	return (b.f + a.i);
}