#define MEM		0xFF401000

void SieveOfEratosthenes()
{
	int nn, i, j, k;
	char *mem = (char *)MEM;
	
	for (nn = 0; nn < 10; nn++)
		mem[nn] = 1;
	for (i = 2; i < 32; i = i + 1) {
		if (mem[i]) {
			j = 0;
			for (k = 0; j < 50; k = k + 1) {
				j = i * i + k * i;
				mem[j] = 0;
			}
		}
	}
	for(;;) {}
}
