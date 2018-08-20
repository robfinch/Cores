// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
//
// malloc() and free() use a semaphore to protect list manipulation. They
// will spinlock until a previous memory operation is done. malloc() and
// free() are interruptible.
//
// If malloc() and free() are called from interrupt routines the interrupt
// routine will need to test the memory semaphore before calling malloc() or
// free() in order to prevent a deadlock.                                                         
// ============================================================================
//
//using short pointers;
#include "..\..\FMTK\source\kernel\types.h"
#include "..\..\FMTK\source\kernel\proto.h"
#include "..\..\FMTK\source\kernel\const.h"

// ----------------------------------------------------------------------------
// Semaphore lock/unlock code.
// ----------------------------------------------------------------------------

naked int LockMemSemaphore(register int retries)
{
	__asm {
		mov		r2,r18
.loop:
		ldi		r1,#64
		csrrs	r1,#12,r1
		bfextu	r1,r1,#6,#6	// extract the previous lock status
		xor		r1,r1,#1	// return true if semaphore wasn't locked
		bne		r1,r0,.xit
		dbnz	r2,.loop
		// r1 = 0
.xit:
		ret
	}
}

naked inline void UnlockMemSemaphore()
{
	__asm {
		ldi		r1,#64
		csrrc	r0,#12,r1
	}
}


int round32(int amt)
{
	return ((amt + 31) & 0xFFFFFFFFFFFFFFE0L);
}

// ----------------------------------------------------------------------------
// malloc defers a thread switch until after the malloc is finished
// processing by controlling the interrupt level.
// ----------------------------------------------------------------------------

void *malloc(int n)
{
	__object *p;
	int avail;
	int k;
	ACB *pa;

	n = round32(n);
	m = SetImLevel(1);	
	until (LockMemSemaphore(-1));
	pa = GetRunningACBPtr();
	if (n > 16384)
		k = MS_LO;
	else
		k = MS_NEW;
	avail = pa->Heap.mem[k].size - (pa->Heap.mem[k].allocptr - pa->Heap.mem[k].addr);
	if (n > avail) {
		// Not enough memory available, wait for GC to run
		UnlockMemSemaphore();
		RestoreImLevel(m);
		sleep(350);
		m = SetImLevel(1);	
		until (LockMemSemaphore(-1));
		avail = pa->Heap.mem[k].size - (pa->Heap.mem[k].allocptr - pa->Heap.mem[k].addr);
		if (n > avail) {
			UnlockMemSemaphore();
			RestoreImLevel(m);
			throw (E_NoMem);
		}
	}
	p = pa->Heap.mem[k].allocptr;
	pa->Heap.mem[k].allocptr += n;
	p->magic = OBJ_MAGIC;
	p->size = n;
	p->used = 1;
	p->owningMap = _GetMMUOperateKey();
	p->usedInMap = (1 << p->owningMap);
	p->finalizer = 0;
	UnlockMemSemaphore();
	RestoreImLevel(m);
	return (p);
}

void free(void *m)
{
	__object *p;
	int i;

	p = (__object *)m;
	i = SetImLevel(1);	
	until (LockMemSemaphore(-1));
	p->refcount--;
	if (p->refcount <= 0) {
		p->used = 0;
		p->usedInMap = 0;
	}
	UnlockMemSemaphore();
	RestoreImLevel(i);
}

void CreateHeap(void *addr, int size)
{
	int m;
	MBLK *FirstMBLK;

	m = SetImLevel(1);	
	 
	*(int*)addr = 0;
	FirstMBLK = (MBLK *)((int)addr + 8);
	//FirstMBLK = (MBLK *)(GetRunningACBPtr()->Heap.pHeap);
	FirstMBLK->magic = ('M' << 24) + ('B' << 16) + ('L' << 8) + 'K';
	//FirstMBLK->size = GetRunningACBPtr()->HeapSize - sizeof(MBLK) * 2;
	FirstMBLK->size = size - sizeof(MBLK) * 2 - 8;
	FirstMBLK->next = null;
	FirstMBLK->prev = null;
	UnlockMemSemaphore();
	RestoreImLevel(m);
}
