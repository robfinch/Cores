/* ROM BIOS  */
#define MEM		0xFF400000

extern void SieveOfEratosthenes();

int main()
{
	int DBGAttr;
	int* pLEDS = 0xFFDC0600;
	int* pScreen = 0xFFD00000;
	
	SieveOfEratosthenes();
	*pLEDS = 0xAA;
	DBGAttr = 0x4FF0F000;
	pScreen[0] = DBGAttr|'A';
	pScreen[1] = DBGAttr|'A';
	pScreen[2] = DBGAttr|'A';
	pScreen[3] = DBGAttr|'A';
}
