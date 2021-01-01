/* ROM BIOS  */
#define BIOSMEM		0xFFFC0000

extern void SieveOfEratosthenes();
extern int rand();

void __interrupt syscall()
{

}

void __interrupt ext_irq()
{

}

int main()
{
	int DBGAttr;
	int* pLEDS = 0xFFDC0600;
	int* pScreen = 0xFFD00000;
	int* pMem = BIOSMEM;
	int n;

	*pLEDS = 0xAA;
	pMem[5] = (int)ext_irq|0x48000002;
	pMem[12] = (int)syscall|0x48000002;
	//SieveOfEratosthenes();
	DBGAttr = 0x4FF0F000;
	pScreen[0] = DBGAttr|'A';
	pScreen[1] = DBGAttr|'A';
	pScreen[2] = DBGAttr|'A';
	pScreen[3] = DBGAttr|'A';
	
	for (n = 0; n < 10000; n = n + 1)
		pScreen[abs(rand())%(64*33)] = rand();
}
