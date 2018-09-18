#define MEM		0xffffffffff400000

void SieveOfE()
{
	int nn, i, j, k;
	__int8 *mem = (__int8 *)MEM;
	
	for (nn = 0; nn < 1024; nn++)
		mem[nn] = 1;
	for (i = 2; i < 32; i = i + 1) {
		if (mem[i]) {
			j = 0;
			for (k = 0; j < 1024; k = k + 1) {
				j = i * i + k * i;
				mem[j] = 0;
			}
		}
	}
	forever {}
}
