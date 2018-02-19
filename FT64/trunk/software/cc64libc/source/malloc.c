//using short pointers;

typedef struct _tagMBLK
{
	__int32 magic;
	__int32 size;
	struct _tagMBLK *next;
	struct _tagMBLK *prev;
} MBLK;

MBLK *FirstMBLK;

int round8(int amt)
{
	return ((amt + 7) & 0xFFFFFFFFFFFFFFF8L);
}

void *malloc(int n)
{
	MBLK *p, *q;

	n = rount8(n);	
	for (p = FirstMBLK; p; p = p->next)	{
		if (p->magic==('M' << 24) + ('B' << 16) + ('L' << 8) + 'K') {
			if (p->size >= n) {
				// Split block if too large
				if (p->size > n + sizeof(MBLK)+16) {
					q = p->next;
					p->size = n + sizeof(MBLK);
					p->next = (byte *)p + n + sizeof(MBLK);
					p->next->size = p->size - n - sizeof(MBLK);
					p->next->prev = p;
					p->next->next = q;
					p->next->magic = ('M' << 24) + ('B' << 16) + ('L' << 8) + 'K';
					if (q)
					q->prev = p->next;
				}
				// Set block status to allocated
				p->magic = ('m' << 24) + ('b' << 16) + ('l' << 8) + 'k';
				return (&p[1]);
			}		
		}
	}
	return (null);
}

void free(byte *m)
{
	MBLK *q, *n;
	MBLK *p = (MBLK *)&m[-1];

	p->magic = ('M' << 24) + ('B' << 16) + ('L' << 8) + 'K';
	n = p->next;
	if (n) {
		// Is next block free ?
		if (n->magic==('M' << 24) + ('B' << 16) + ('L' << 8) + 'K') {
			if (n->next)
				n->next->prev = p;
			p->next = n->next;
			p->size += n->size + sizeof(MBLK);
		}
	}
	q = p->prev;	
	if (q) {
		// Is previous block free ?
		if (q->magic==('M' << 24) + ('B' << 16) + ('L' << 8) + 'K') {
			if (q->prev)
				q->prev->next = p->next;
			if (p->next)
				p->next->prev = q->prev;
			q->size += p->size + sizeof(MBLK);
		}
	}
}

void InitHeap(void *pHeapStart, int size)
{
	FirstMBLK = (MBLK *)pHeapStart;
	FirstMBLK->magic = ('M' << 24) + ('B' << 16) + ('L' << 8) + 'K';
	FirstMBLK->size = size - sizeof(MBLK) * 2;
	FirstMBLK->next = null;
	FirstMBLK->prev = null;
}
