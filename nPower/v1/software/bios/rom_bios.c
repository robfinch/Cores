/* ROM BIOS  */
#define BIOSMEM		0xFFFC0000

//extern int DBGAttr;
extern void SieveOfEratosthenes();
extern int rand();

void __interrupt syscall()
{

}

void __interrupt ext_irq()
{

}
/*
int abs(int a)
{
	if (a < 0) a = -a;
	return (a);
}

int rand()
{
	int* pRand = 0xFFDC0C00;
	volatile int r;
	
	r = *pRand;
	*pRand = r;
	return (r);
}
*/
void ramtest()
{

}

int main()
{
	int* pLEDS = 0xFFDC0600;
	int* pScreen = 0xFFD00000;
	int* pMem = BIOSMEM;
	int n;
	int DBGAttr;

	*pLEDS = 0xAA;
	pMem[5] = (int)ext_irq|0x48000002;
	pMem[12] = (int)syscall|0x48000002;
	//SieveOfEratosthenes();
	DBGAttr = 0x4FF0F000;
	pScreen[0] = DBGAttr|'A';
	pScreen[1] = DBGAttr|'A';
	pScreen[2] = DBGAttr|'A';
	pScreen[3] = DBGAttr|'A';
	
	for (n = 0; n < 100000; n = n + 1)
		pScreen[abs(rand())%(64*33)] = rand();
		
	ramtest();
}
