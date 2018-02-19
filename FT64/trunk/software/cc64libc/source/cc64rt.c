#define FMTK_SCHEDULE	2
#define FMTK_SYSCALL	4
#define TS_IRQ			128|3
#define GC_IRQ			128|30
#define KBD_IRQ			159
#define ACB_MAGIC	(('A' << 16) | ('C' << 8) | 'B')

extern int milliseconds;

extern int _SetMMUOperateKey(register int key);

typedef struct _tagObject
{
	__int32 __typenum;
	__int32 __id;
	struct _tagObject *__prev;
} __object;

naked int LockGCSemaphore()
{
	__asm {
		ldi		r1,#2
		csrrs	r1,#12,r1
		bfextu	r1,r1,#1,#1	// extract the previous lock status
		xor		r1,r1,#1	// return true if semaphore wasn't locked
		ret
	}
}

naked inline void UnlockGCSemaphore()
{
	__asm {
		ldi		r1,#2
		csrrc	r0,#12,r1
	}
}

void *_new(int n, int typenum, __object **list)
{
	static int id;
	__object *p;
	
	p = (__object *)malloc(n+sizeof(__object));
	memset(p, 0, n+sizeof(__object));
	p->__id = id;
	p->__typenum = typenum;
	p->__prev = *list;
	*list = p;
	id++;
	return (&p[1]);
}

void _delete(__object *p, __object **list)
{
	__object *m, *q;
	m = *list;
	if (p==m) {
		*list = p->__prev;
	}
	else {
		q = m;
		m = m->__prev;
		while (m) {
			if (p==m) {
				q->__prev = p->__prev;
				break;
			}
			q = m;
			m = m->__prev;
		}
	}
	free(&p[-1]);
}

// Used at the end of a function to add all the objects created in the function
// that have gone out of scope to the garbage list.

void _AddGarbage(__object *list)
{
	__object *p;
	__object **garbage_list = (__object **)8;
	int count;
	
	do {
		count = 0;
		until (LockGCSemaphore());
		while(list) {
			count++;
			p = list->__prev;
			list->__prev = *garbage_list;
			*garbage_list = list;
			list = p;
			if (count==25)
				break;
		}
		UnlockGCSemaphore();
	}
	while (list);
}

// In order for the garbage collector to work the stack needs to be the brk
// stack outside of mapped memory. The operating map is switched around
// so using a stack in mapped memory is not possible.

void _GarbageCollector()
{
	__object *p;
	int mapno, omapno;
	int count;
	int done;
	// The garbage list pointer is located at offset 8 in a the app's memory
	// map.
	__object **garbage_list = (__object **)8;
	int *pMagic = (int *)0;

	// for each map
	for (mapno = 0; mapno < 64; mapno++) {
		done = false;
		do {
			count = 0;
			until (LockGCSemaphore());
			// Need to switch the operate key to get access to the garbage
			// collection list for the app.
			omapno = _SetMMUOperateKey(mapno);
			if (*pMagic==ACB_MAGIC) {
				while (*garbage_list) {
					count++;
					p = (*garbage_list)->__prev;
					free(&((*garbage_list)[-1]));
					*garbage_list = p;
					if (count==25) {
						break;
					}
				}
				if (*garbage_list==null)
					done = true;
			}
			else
				done = true;
			_SetMMUOperateKey(omapno);
			UnlockGCSemaphore();
		} until(done);
	}
}
