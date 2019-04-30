typedef struct {
	int *a;
	int *b;
} ABStruct;

char *ptrTest(ABStruct *ab)
{
	ABStruct p;
	
	p.a = ab->a;
	p.b = ab->b;
	return (&p->a);
}