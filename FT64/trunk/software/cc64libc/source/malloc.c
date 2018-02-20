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

typedef struct _tagMBLK
{
	__int32 magic;
	__int32 size;
	struct _tagMBLK *next;
	struct _tagMBLK *prev;
} MBLK;

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


int round8(int amt)
{
	return ((amt + 7) & 0xFFFFFFFFFFFFFFF8L);
}

// ----------------------------------------------------------------------------
// malloc defers a thread switch until after the malloc is finished
// processing by controlling the interrupt level.
// ----------------------------------------------------------------------------

void *malloc(int n)
{
	MBLK *p, *q;
	int m;

	n = rount8(n);
	m = SetImLevel(1);	
	until (LockMemSemaphore(-1));
	for (p = GetRunningACBPtr()->pHeap; p; p = p->next)	{
		if (p->magic==('M' << 24) + ('B' << 16) + ('L' << 8) + 'K') {
			if (p->size >= n) {
				// Split block if too large
				if (p->size > n + sizeof(MBLK)) {
					q = p->next;
					p->size = n;
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
				UnlockMemSemaphore();
				return (&p[1]);
			}		
		}
	}
	UnlockMemSemaphore();
	RestoreImLevel(m);
	return (null);
}

void free(void *m)
{
	MBLK *q, *n;
	MBLK *p = &((MBLK *)m)[-1];
	int m;

	m = SetImLevel(1);	
	until (LockMemSemaphore(-1));
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
			if (p->next)
				p->next->prev = q;
			q->next = p->next;
			q->size += p->size + sizeof(MBLK);
		}
	}
	UnlockMemSemaphore();
	RestoreImLevel(m);
}

void InitHeap()
{
	int m;
	MBLK *FirstMBLK;

	m = SetImLevel(1);	
	 
	FirstMBLK = (MBLK *)(GetRunningACBPtr()->pHeap);
	FirstMBLK->magic = ('M' << 24) + ('B' << 16) + ('L' << 8) + 'K';
	FirstMBLK->size = GetRunningACBPtr()->HeapSize - sizeof(MBLK) * 2;
	FirstMBLK->next = null;
	FirstMBLK->prev = null;
	UnlockMemSemaphore();
	RestoreImLevel(m);
}
