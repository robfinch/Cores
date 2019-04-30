typedef struct {
	int *addr;
	int size;
} MEMORY;

int IsInMemory(register MEMORY *mem, register void *ptr)
{
	return ((__int8*)ptr >= (__int8*)mem->addr &&
		(__int8*)ptr < (__int8*)mem->addr + mem->size)
}

