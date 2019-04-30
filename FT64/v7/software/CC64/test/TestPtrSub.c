typedef struct {
	int a[1024];
} TCB;

typedef struct {
	int ndx;	
} S2;

TCB t[100];

short int TestPtrSub(TCB *a, TCB *b)
{
	S2 x;

	x.ndx = a - t;
	return (x.ndx);
}