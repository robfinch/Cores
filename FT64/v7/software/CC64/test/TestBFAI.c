typedef struct {
	int bf : 4;
	int cf : 12;
} BF;

int TestBFAI(BF *bf)
{
	bf->bf++;
	return bf->bf;
}
