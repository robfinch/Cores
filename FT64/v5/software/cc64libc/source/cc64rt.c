
#include "..\..\FMTK\source\kernel\const.h"
#include "..\..\FMTK\source\kernel\types.h"
#include "..\..\FMTK\source\kernel\glo.h"

#define FMTK_SCHEDULE	2
#define FMTK_SYSCALL	4
#define TS_IRQ			128|3
#define GC_IRQ			128|30
#define KBD_IRQ			159

extern int milliseconds;

extern int _SetMMUOperateKey(register int key);
extern int _GetMMUOperateKey();
extern void *MapSharedMemory(int, int);
extern ACB *GetACBPtr(int);

extern int gc_stack[256];
extern int gc_pc;
extern int gc_omapno;
extern int gc_mapno;
extern int gc_dl;

extern int gc_getreg[32];

extern __object **gc_roots[1024];
extern int gc_gblrootcnt;
extern int gc_stkrootcnt;
extern int gc_rootcnt;

naked int LockVMSemaphore(int mapno)
{
	__asm {
		ldi		$r2,#1
		shl		$r1,$r2,$r18
		csrrs	$r1,#13,$r2
		shr		$r1,$r1,$r18	// extract the previous lock status
		and		$r1,$r1,#1
		xor		$r1,$r1,#1		// return true if semaphore wasn't locked
		ret
	}
}

naked inline void UnlockVMSemaphore(int mapno)
{
	__asm {
		ldi		$r1,#1
		shl		$r1,$r1,$r18
		csrrc	$r0,#13,$r1
	}
}

naked int LockGCSemaphore()
{
	__asm {
		ldi		r1,#2
		csrrs	r1,#12,r1
		shr		r1,r1,#1	// extract the previous lock status
		and		r1,r1,#1
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

naked inline int GetTick()
{
	__asm {
		csrrd	r1,#2,r0
	}
}

naked int _SetDataLevel(register int dl)
{
	__asm {
		and		r18,r18,#3
		csrrd	r1,#$44,r0
		and		r1,r1,#$FFFFFFFFFFCFFFFF
		shl		r2,r18,#20
		or		r1,r1,r2
		csrrw	r1,#$44,r1
		// return previous data level
		shr		r1,r1,#20
		and		r1,r1,#3
		// Flush pipeline
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		ret
	}
}

naked inline int _SetPtrMask(register int mask)
{
	__asm {
		csrrw	$r1,#$11,$r18
	}
}

naked inline int _SetPtrKey(register int key)
{
	__asm {
		csrrw	$r1,#$12,$r18
	}
}

// Note that there is no sequencing protection here. After the data segment
// is set the instruction stream should be synchronized so that current
// memory references get to complete using the old segment value. In this
// code the data level is set immediately after the data segment and provides
// enough instructions to synchronize for previous memory operations. So
// we don't need syunchronization primitives here.
naked inline int _Dataseg(register int sg)
{
	__asm {
		csrrw	r1,#$50,r18
	}
}

void *_new(int n, int typenum)
{
	static int id;
	__object *p;
	__object **ol = (__object **)8;
	
	p = (__object *)malloc(n+sizeof(__object));
	p->id = id;
	p->typenum = typenum;
	id++;
	return (&p[1]);
}

void _delete(__object *p, __object **list)
{
	__object *m, *q;

	// Was the object allocated in this map ?
	// Can't delete an object that was never referenced.
	if (!((p->usedInMap >> _GetMMUOperateKey()) & 1))
		return;
		
	// If deleting a shared object, wait until it's deleted from all maps before
	// calling the finalizer and freeing the object.
	if (p->refcount > 0)
		p->refcount--;
	if (p->refcount > 0)
		return;

	m = *list;
	if (p==m) {
		*list = p->newlist;
	}
	else {
		q = m;
		m = m->newlist;
		while (m) {
			if (p==m) {
				q->newlist = p->newlist;
				break;
			}
			q = m;
			m = m->newlist;
		}
	}
	if (p->finalizer)
		(p->finalizer)();
	free(&p[-1]);
}

void _gl_delete(__object *p)
{
	__object *m, *q;
	__object **garbage_list = (__object **)16;

	// Was the object allocated in this map ?
	// Can't delete an object that was never referenced.
	if (!((p->usedInMap >> _GetMMUOperateKey()) & 1))
		return;
		
	// If deleting a shared object, wait until it's deleted from all maps before
	// calling the finalizer and freeing the object.
	if (p->refcount > 0)
		p->refcount--;
	if (p->refcount > 0)
		return;

	m = *garbage_list;
	if (p==m) {
		*garbage_list = p->newlist;
	}
	else {
		q = m;
		m = m->newlist;
		while (m) {
			if (p==m) {
				q->newlist = p->newlist;
				break;
			}
			q = m;
			m = m->newlist;
		}
	}
	if (p->finalizer)
		(p->finalizer)();
	free(&p[-1]);
}

// Used at the end of a function to add all the objects created in the function
// that have gone out of scope to the garbage list.

void _AddGarbage(__object *list)
{
	__object *p;
	// 8 is the offset of the garbage list pointer in the ACB.
	// The ACB is always located at address zero in app's map.
	__object **garbage_list = (__object **)16;
	int count;
	
	do {
		count = 0;
		until (LockGCSemaphore());
		while(list) {
			count++;
			p = list->newlist;
			list->newlist = *garbage_list;
			*garbage_list = list;
			list = p;
			if (count==25)
				break;
		}
		UnlockGCSemaphore();
	}
	while (list);
}


naked inline int IsPointer(register int *p)
{
	__asm {
		asr		$r1,$r18,#44
		cmp		$r1,$r1,#$FFFFFFFFFFFFFF01
		not		$r1,$r1
	}
}

naked inline int IsNullPointer(register int *p)
{
	__asm {
		ror		$r1,$r18,#44
		cmp		$r1,$r1,#$FFF01
		not		$r1,$r1
	}
}

// Get specified register from specified register set by building
// the proper MOV instruction. The MOV instruction is executed from
// a code buffer.

naked int GetRegister(register int regset, register int regno)
{
	__asm {
		bbs		$r18,#5,.regset32
		// load r1 with move from register set instruction template
		ldi		$r1,#%100010_001_00000_00001_00000_00_000010
		bra		.0001
.regset32:
		ldi		$r1,#%011100_001_00000_00001_00000_00_000010
.0001:
		// Set the register set and register number fields according
		// to the desired register.
		and		$r18,$r18,#31
		and		$r19,$r19,#31
		shl		$r18,$r18,#18
		shl		$r19,$r19,#8
		or		$r1,$r1,$r18
		or		$r1,$r1,$r19
		// Load code buffer
		csrrw	$r0,#$80,$r1
		// Flush instruction pipeline to ensure the code buffer 
		// update is visible for execution with the exec instruction
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		add		$r0,$r0,#0
		exec	#0				// execute code buffer #0
		ret
	}
}

// Returns the pointer value if register contains a pointer, otherwise
// returns a zero.

naked int IsRegPointer(register int regset, register int regno)
{
	int *rg;
	
	rg = GetRegister(regset,regno);
	if (IsPointer(rg))
		return (rg);
	else
		return (0);
}


// Detect a pointer load by a register set

static naked inline int DidWB(int regset)
{
	__asm {
		csrrd	$r1,#$A,$r0
		shr		$r1,$r1,$r18
		and		$r1,$r1,#1
	}
}


// Clear register set write barrier flag.

static naked inline void ClearWB(int regset)
{
	__asm {
		ldi		$r1,#1
		shl		$r1,$r1,$r18
		csrrc	$r0,#$A,$r1
	}
}


void CheckObj(__object *p, int mapno)
{
	if (p->owningMap==mapno) {
		if (p->refcount == 0) {
			if (p->finalizer)
				(p->finalizer)();
			free(p);
			// Prevent the finalizer from running more
			// than once.
			p->refcount = -1;
			(int)*p = 0;
		}
	}
}

void GetStackedRootsOnThread(TCB *pThrd, int regset)
{
	int *ptr, *qtr, *sptr;
	int *pStackBot;
	int stksize;

	if (pThrd->status & (TS_PREEMPT|TS_RUNNING))
		ptr = GetRegister(regset, 31);
	else
		ptr = pThrd->regs[31];
	sptr = pThrd->stack;
	stksize = pThrd->stacksize;
	_SetDataLevel(OL_USER);
	pStackBot = &sptr[stksize>>3];
	for (; ptr < pStackBot; ptr++) {
		if (IsPointer((int *)(*ptr))) {
			qtr = *ptr;
			if (!IsNullPointer(qtr)) {
				if (*qtr == OBJ_MAGIC) {
					_SetDataLevel(OL_MACHINE);
					gc_roots[gc_stkrootcnt] = (__object *)qtr;
					gc_stkrootcnt++;
					_SetDataLevel(OL_USER);
				}
			}
		}
	}
	_SetDataLevel(OL_MACHINE);
}

// Iterate through all the thread stacks

void GetStackedRoots(ACB *pACB)
{
	TCB *pThrd;

	gc_stkrootcnt = gc_gblrootcnt;
	for (pThrd = &tcbs[pACB->thrd]; pThrd; pThrd = (pThrd->acbnext >= 0 ? &tcbs[pThrd->acbnext] : 0))
		GetStackedRootsOnThread(pThrd, pACB->regset);
}

void GetGlobalRootsInDataArea(ACB *pACB)
{
	int *ptr, *qtr;
	int nn;

	gc_gblrootcnt = 0;
	ptr = pACB->pData;
	for (nn = 0; nn < pACB->pDataSize; nn++ ) {
		_SetDataLevel(OL_USER);
		qtr = *ptr;
		if (IsPointer(qtr)) {
			if (!IsNullPointer(qtr)) {
				if (*qtr==OBJ_MAGIC) {
					_SetDataLevel(OL_MACHINE);
					gc_roots[gc_gblrootcnt] = qtr;
					gc_gblrootcnt++;
					_SetDataLevel(OL_USER);
				}
			}
		}
		_SetDataLevel(OL_MACHINE);
		ptr++;
	}
}

void GetGlobalRootsInUIDataArea(ACB *pACB)
{
	int *ptr, *qtr;
	int nn;

	ptr = pACB->pUIData;
	for (nn = 0; nn < pACB->pUIDataSize; nn++ ) {
		_SetDataLevel(OL_USER);
		qtr = *ptr;
		if (IsPointer(qtr)) {
			if (!IsNullPointer(qtr)) {
				if (*qtr==OBJ_MAGIC) {
					_SetDataLevel(OL_MACHINE);
					gc_roots[gc_gblrootcnt] = qtr;
					gc_gblrootcnt++;
					_SetDataLevel(OL_USER);
				}
			}
		}
		_SetDataLevel(OL_MACHINE);
		ptr++;
	}
}

// In order for the garbage collector to work the stack needs to be the brk
// stack outside of mapped memory. The operating map is switched around
// so using a stack in mapped memory is not possible.

void _GCExec()
{
	__object *p;
	__object **garbage_list = (__object **)16;
	int *pMagic = (int *)0;
	int *pL1Card, *pL2Card;
	int *pMem;
	int mapno;
	int omapno;
	int regno;
	int nn, bn, bnn, jj, kk;
	int bm;
	ACB *pACB;
	HEAP *pHeap;
	int *pStackBot;
	int *ptr;
	int *qtr;
	int *sptr;
	int stksize;

	gc_omapno = _GetMMUOperateKey();

	for (mapno = 0; mapno < 64; mapno++) {
		pACB = GetACBPtr(mapno);
		if (pACB==0)
			continue;
		if (pACB->magic != ACB_MAGIC)
			continue;

		gc_gblrootcnt = 0;
		_SetMMUOperateKey(mapno);

		GetGlobalRootsInDataArea(pACB);
		GetGlobalRootsInUIDataArea(pACB);

		// Iterate through all the thread stacks
		GetStackedRoots(pACB);

		// And through all registers
		for (regno = 1; regno < 26; regno++) {
			if (ptr = (int *)IsRegPointer(pACB->regset, regno)) {
				if (!IsNullPointer(ptr)) {
					_SetDataLevel(OL_USER);
					if (*ptr==OBJ_MAGIC) {
						_SetDataLevel(OL_MACHINE);
						gc_roots[gc_stkrootcnt] = ptr;
						gc_stkrootcnt++;
					}
					_SetDataLevel(OL_MACHINE);
				}
			}
		}
		
		for (nn = 0; nn < gc_stkrootcnt; nn++) {
		}
	}
	
	


	// Mark
	for (mapno = 0; mapno < 64; mapno++) {
		until(LockVMSemaphore(mapno));
		pACB = GetACBPtr(mapno);
		if (pACB->magic != ACB_MAGIC) {
			UnlockVMSemaphore(mapno);
			continue;
		}
		// Need to switch the operate key to get access to the garbage
		// collection list for the app.
		_SetMMUOperateKey(mapno);
		_SetDataLevel(OL_USER);
		// ACB is at virtual address zero
		pACB = (ACB*)(0);
		//for (p = pACB->objectList; p; p = p->next)
		//	p->used = true;
		_SetDataLevel(OL_MACHINE);
		UnlockVMSemaphore(mapno);
	}

	for (mapno = 0; mapno < 64; mapno++) {
		until(LockVMSemaphore(mapno));
		pACB = GetACBPtr(mapno);
		if (pACB->magic != ACB_MAGIC) {
			UnlockVMSemaphore(mapno);
			continue;
		}
		_SetMMUOperateKey(mapno);
		_SetDataLevel(OL_USER);
		// ACB is at virtual address zero
		pACB = (ACB*)(0);
		// Check for objects pointed to by registers.
		// We don't bother to test registers that shouldn't
		// have object pointers in them, like the stack
		// pointer or return address register.
		if (DidWB(pACB->regset)) {
			for (regno = 1; regno < 26; regno++) {
				p = (__object *)GetRegister(pACB->regset, regno);
				if (IsObjPointer(p)) {
					CheckObj(p);
				}
			}
			ClearWB(pACB->regset);
		}
		pL2Card = pACB->L2cards;
		for (kk = 0; kk < 4; kk++) {
			while (pL2Card[kk]) {
				// Find last set bit
				for (bnn = 0; bnn < 64; bnn++)
					if ((pL2Card[kk] >> bnn) & 1) {
						pL1Card = pACB->L1cards[kk*64+bnn];
						break;
					}
				for (nn = 0; nn < 252; nn++) {
					if (pL1Card[nn] != 0) {
						bm = pL1Card[nn];
						for (bn = 0; bn < 64; bn++) {
							if (bm & (1 << bn)) {
								pMem = (int *)(((nn+4) << 14) + (1 << 13) + (bn << 8));
								for (jj = 0; jj < 32; jj++) {
									if (IsObjPointer(pMem[jj])) {
										p = (__object *)pMem[jj];
										CheckObj(p);
									}
								}
							}
						}
						pL1Card[nn] = 0;
					}
				}
				pL2Card[kk] &= ~(1 << bnn);
			}
		}
		_SetDataLevel(OL_MACHINE);
		UnlockVMSemaphore(mapno);
	}
	_SetMMUOperateKey(gc_omapno);
}

// From pseudo-code in article by jayconrad
// http://jayconrod.com/posts/55/a-tour-of-v8-garbage-collection

__object *CopyObject(register int **allocationPtr, register __object *obj)
{
	__object *copy = (__object *)(*allocationPtr);
	*allocationPtr += obj->size;
	memcpy(copy, obj, obj->size);
	return (copy);
}

int IsInMemory(register MEMORY *mem, register void *ptr)
{
	return ((__int8*)ptr >= (__int8*)mem->addr &&
		(__int8*)ptr < (__int8*)mem->addr + mem->size)
}

void Scavange(ACB *pACB)
{
	MEMORY *fromSpace, *toSpace;
	MEMORY *mtmp;
	MEMORY *oldSpace;
	int *tmp, *op;
	int ii, nn;
	__object *root;
	__object *rootCopy;
	int *allocationPtr;
	int *scanPtr;
	__object *obj;
	__object *fromNeighbour, *toNeighbour;

	oldSpace = &pACB->Heap.mem[MS_OLD];

	// swap (fromSpace, toSpace)
	mtmp = pACB->Heap.fromSpace;
	pACB->Heap.fromSpace = pACB->Heap.toSpace;
	pACB->Heap.toSpace = mtmp;
	fromSpace = pACB->Heap.fromSpace;
	toSpace = pACB->Heap.toSpace;

	allocationPtr = (int *)toSpace->addr;
	scanPtr = (int *)toSpace->addr;
	
	for (ii = 0; ii < gc_rootcnt; ii++) {
		root = gc_roots[ii];
		root->forwardingAddress = 0;
		_SetDataLevel(OL_USER);
		if (IsInMemory(fromSpace,root)) {
			rootCopy = CopyObject(&allocationPtr, root);
			rootCopy->scavangeCount++;
			_SetDataLevel(OL_MACHINE);
			root->forwardingAddress = rootCopy;
			gc_roots[ii] = rootCopy;
		}
		_SetDataLevel(OL_MACHINE);
	}

	_SetDataLevel(OL_USER);
	while (scanPtr < allocationPtr) {
		obj = (__object *)scanPtr;
		scanPtr += obj->size;
		nn = obj->size / sizeof(int);
		for (ii = 0; ii < nn; ii++) {
			tmp = ((int *)obj)[ii];
			op = &((int *)obj)[ii];
			if (IsPointer(tmp) && !IsInMemory(oldSpace, tmp)) {
				fromNeighbour = (__object *)tmp;
				if (fromNeighbour->forwardingAddress != 0)
					toNeighbour = fromNeighbour->forwardingAddress;
				else {
					toNeighbour = CopyObject(&allocationPtr, fromNeighbour);
					toNeighbour->scavangeCount++;
					fromNeighbour->forwardingAddress = toNeighbour;
				}
				(int *)(*tmp) = (int *)toNeighbour;
			}
		}
	}
	_SetDataLevel(OL_MACHINE);
}