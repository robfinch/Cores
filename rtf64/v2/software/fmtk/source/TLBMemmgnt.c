// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
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
// ============================================================================
//
#include <fmtk\const.h>
#include <fmtk\config.h>
#include <fmtk\types.h>
#include <errno.h>

// There are 1024 pages in each map. In the normal 8k page size that means a max of
// 8Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 65536 x 8k pages.
// However the last 144kB (18 pages) are reserved for memory management software.
#define NPAGES	65536
#define CARD_MEMORY		0xFFCE0000

#define NULL    (void *)0

extern byte *os_brk;

extern int highest_data_word;
extern __int16 mmu_freelist;		// head of list of free pages
extern int syspages;
extern int sys_pages_available;
extern int mmu_FreeMaps;
extern __int32 *mmu_entries;
extern __int8 hSearchMap;
extern MEMORY memoryList[NR_MEMORY];
extern int:16 pam[65536];

// PTE is 256 bits in size
typedef struct _tagPTE
{
	unsigned int dusacrwx : 8;
	unsigned int pl : 8;				// privilege level
	unsigned int smrc : 16;				// shared memory reference count
	unsigned int key : 20;				// protection key
	unsigned int pad1 : 4;
	unsigned int asid : 8;
	unsigned int refcount : 32;
	unsigned int back : 16;
	unsigned int fwd : 16;
	unsigned int pagenum : 64;
	unsigned int pad2 : 64;
} PTE;

extern PTE InvertedPageTable[NPAGES];

//unsigned __int32 *mmu_entries;
int:32 workingKey;
int:32 mkeylfsr;
extern byte *brks[256];
extern byte *shared_brks[256];

//private __int16 pam[NPAGES];	
// There are 128, 4MB pages in the system. Each 4MB page is composed of 64 64kb pages.
//private int pam4mb[NPAGES/64];	// 4MB page allocation map (bit for each 64k page)
//int syspages;					// number of pages reserved at the start for the system
//int sys_pages_available;	// number of available pages in the system
//int sys_4mbpages_available;

// Generate a hash for a virtual memory address.

private int Hash(int adr)
{
	int hash;
	
	hash = adr >> 13;	// convert to page #
	hash &= 0x7fff;
	return (hash);
}

private naked inline void WriteRandom()
{
	__asm {
		sync
		tlbwr
	}
}

private naked inline void SetHoldASID(register int asid)
{
	__asm {
		tlbwrreg	ASID,$a0
	}
}

private naked inline void SetHoldPadr(register int padr)
{
	__asm {
		tlbwrreg	PhysPage,$a0
	}
}

private naked inline void SetHoldVadr(register int vadr)
{
	__asm {
		tlbwrreg	VirtPage,$a0
	}
}

private naked inline void SetHoldPageSize(register int pgsz)
{
	__asm {
		tlbwrreg	PageSize,$a0
	}
}

int TLBMissHandler(unsigned int missAddr)
{
	PTE *pte;
	int hash;
	unsigned int missPage = missAddr >> 13;
	int count;
	int asid;

	hash = Hash(missAddr);
	pte = &InvertedPageTable[hash];
	for (count = 0; count < NPAGES; count++) {
		if ((pte->dusacrwx & 7) == 0) {
			return (E_NotAlloc);
		}
		if (pte->pagenum == missPage) {
			SetHoldPageSize(0);
			SetHoldVadr(missPage);
			SetHoldPadr(hash);
			asid = 
				(pte->key << 32) |
				(pte->asid << 16) |
				((pte->dusacrwx & 0xf0) << 2) |
				(pte->dusacrwx & 0xf)
				;
			SetHoldASID(asid);
			WriteRandom();
			return (E_Ok);
		}
		hash += 65;
		hash &= 0xffff;
		pte = &InvertedPageTable[hash];
	}
	return (E_NotAlloc);
}

// ----------------------------------------------------------------------------
// Must be called to initialize the memory system before any
// other calls to the memory system are made.
// ----------------------------------------------------------------------------

void init_memory_management()
{
	int pg;
  int n;
	PTE *pte;

	os_brk = (byte *)8192;
	mkeylfsr = 0xACE78;
	for (n = 0; n < 256; n++) {
		brks[n] = (byte *)0xfff0100000002000;
		shared_brks[n] = (byte *)0xfff01f0000000000;
	}
	// Mark all memory pages available
	pte = &InvertedPageTable[0];
	for (n = 0; n < NPAGES; n++) {
		pte->dusacrwx = 0;
		pte++;
	}
  syspages = 8 * 64;
	sys_pages_available = NPAGES - 64;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

pascal void SetWorkingKey(unsigned int key)
{
	workingKey = key;
}

// ----------------------------------------------------------------------------
// Get a unique key to be used for memory management.
// ----------------------------------------------------------------------------

unsigned int GetMemKey()
{
	__asm {
		lh			$r1,_mkeylfsr		; get key
		shl			$r1,$r1,#1			; shift
		bfextu	$r2,$r1,#20,#0	; extract bits 16 and 20
		bfextu	$t0,$r1,#16,#0
		xor			$r2,$r2,$t0			; xor the bits
		xor			$r2,$r2,#1			; invert result
		or			$r1,$r1,$r2			; put into LSB
		sh			$r1,_mkeylfsr		; store key back
	}
	return (mkeylfsr & 0xfffff);
}

// ----------------------------------------------------------------------------
// Add a key to the ring of keys associated with the app. Thekey is added to
// the head of the ring and the oldest key is lost if there are more than siz
// keys.
// ----------------------------------------------------------------------------

pascal void AddToKeyring(register unsigned int key)
{
	__asm {
		csrrd		$r1,#$00E,$r0		; get first part of key ring
		csrrd		$r2,#$00F,$r0		; get second part of key ring
		shl			$r2,$r2,#20			; oldest key gets lost
		ror			$r1,$r1,#40			; get last entry of first part
		and			$r1,$r1,#$fffff	; 20 bits
		or			$r2,$r2,$r1			; place last entry of first into second
		csrrw		$r0,#$00F,$r2		; update second half of key ring
		csrrd		$r1,#$00E,$r0		; get first part of key list again
		shl			$r1,$r1,#20			; open up a space
		and			$r2,$a0,#$fffff	; mask to 20 bits
		or			$r1,$r1,$r2			; combine with first
		csrrw		$r0,#$00E,$r1		; update first part of key ring
	}
}

// ----------------------------------------------------------------------------
// Allocate an 8k page.
// The page is allocated as cachable read-write-exectuable.
// ----------------------------------------------------------------------------

private unsigned int AllocPage(int virtpage, int key)
{
  int sb;
	int hash;
	PTE *pte;
	int count;

	hash = Hash(virtpage << 13);
	pte = &InvertedPageTable[hash];
	for (count = 0; count < NPAGES; count++) {
		if ((pte->dusacrwx & 7)==0) {
			pte->pagenum = virtpage;
			pte->dusacrwx = 0x1f;
			pte->refcount = 0x100;
			pte->key = key;
			sys_pages_available--;
			return (hash);
		}
		hash += 65;
		hash &= 0xffff;
		pte = &InvertedPageTable[hash];
	}
	throw (E_NoMem);
}

// ----------------------------------------------------------------------------
// Takes a page number allocated with alloc and returns it to
// available memory pool.
// ----------------------------------------------------------------------------

private pascal void FreePage(register unsigned int pg)
{
	PTE *pte;

  if (pg >= NPAGES)
    throw (E_BadPageno);
  pte = &InvertedPageTable[pg];
  pte->dusacrwx &= 0xf8;
	sys_pages_available++;
}

// ----------------------------------------------------------------------------
// Allocate npages from the page table
//
// ----------------------------------------------------------------------------

private pascal int AllocPages(int npages, int key, int shared)
{
	int first_page, virtpage;
	int physpage, prevpage, pppg;
	int n;
	unsigned __int8 as;
	PTE *pte;

	if (npages <= 0 || npages > sys_pages_available)
		throw (E_NoMem);
	as = GetASID();
	if (shared)
		virtpage = first_page = (shared_brks[as] >> 13) & 0xfffffffffff;
	else
		virtpage = first_page = (brks[as] >> 13) & 0xfffffffffff;
	prevpage = 0xffff;
	for (n = 0; n < npages; n++) {
		physpage = AllocPage(virtpage, key);
		pte = &InvertedPageTable[physpage];
		pte->back = prevpage;
		if (n > 0) {
			pte = &InvertedPageTable[prevpage];
			pte->fwd = physpage;
		}
		pppg = prevpage;
		prevpage = physpage;
		virtpage++;
	}
	pte = &InvertedPageTable[prevpage];
	pte->fwd = 0xffff;
	pte->back = pppg;
	virtpage++;
	if (shared)
		shared_brks[as] = (virtpage << 13)|0xfff0100000000000;
	else
		brks[as] = (virtpage << 13)|0xfff0100000000000;
	sys_pages_available -= npages;
	return (first_page);
}

// ----------------------------------------------------------------------------
// Return the physical page number given the virtual page number. Return -1 if
// the page is not found.
// ----------------------------------------------------------------------------

private pascal int GetPhysPage(int vpg)
{
	int hash;
	int count;
	PTE *pte;

	hash = Hash(vpg << 13);
	pte = &InvertedPageTable[hash];
	for (count = 0; count < NPAGES; count++) {
		if ((pte->dusacrwx & 7)==0)
			return (-1);	// The page can't be found in the table
		if (pte->pagenum == vpg)
			return (hash);
		hash += 65;
		hash &= 0xffff;
		pte = &InvertedPageTable[hash];
	}
	return (-1);
}

// ----------------------------------------------------------------------------
// Return the virtual page number given the physical page number.
// ----------------------------------------------------------------------------

private pascal int GetVirtPage(int ppg)
{
	int vpg;
	PTE *pte;

	if (ppg < 0 || ppg >= NPAGES)
		throw (E_Arg);
	pte = &InvertedPageTable[ppg];
	vpg = pte->pagenum;
	return (vpg);
}

// ----------------------------------------------------------------------------
// Return a pointer to the pte for a given virtual address.
// ----------------------------------------------------------------------------

private pascal PTE *GetPTE(void *p)
{
	int n;
	PTE *pte;

	n = GetPhysPage((p >> 13) & 0x7fffffff);
	if (n < 0)
		throw (E_Arg);
	pte = &InvertedPageTable[n];	
	return (pte);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private pascal void FreePages(int first_page)
{
	int n;

	if (first_page < 0)
		throw (E_BadPageno);

	n = GetPhysPage(first_page);
	if (n >= 0)
		FreePage(n);
	else
		return;
	for (n = pam[n]; n != 0xffff; n = pam[n])
		FreePage(n);
}

// ----------------------------------------------------------------------------
// Allocate memory, returns a virtual memory address of the memory as a 
// pointer.
// ----------------------------------------------------------------------------

pascal void *mmu_alloc(int amt, int key, int shared)
{
	unsigned int page;

	amt = (round8k(amt) >> 13);
	page = AllocPages(amt, key, shared);
	return ((void *)((page << 13)|0xfff0100000000000));
}

// ----------------------------------------------------------------------------
// Free memory allocated with mmu_alloc().
// ----------------------------------------------------------------------------

pascal void mmu_free(void *pmem)
{
	if (pmem & 0x1fffL)
		throw (E_Arg);
	FreePages((int)((pmem >> 13) & 0x7fffffff));
}


// ----------------------------------------------------------------------------
// Map shared memory attempts to find a memory region with the specified key.
// If found, the virtaul address is returned to the requestor.
// Otherwise memory is allocated, and a pointer to the allocated memory returned.

// Searches the entire page table for pages associated with the given key.
// Assume the lowest numbered page is the first address of the shared
// memory. This means that each shared memory must have a unique key.
// ----------------------------------------------------------------------------

pascal void *MapSharedMemory(int key, int size)
{
	void *p;
	int n, m, q, lowest_page;
	PTE *pte;

	pte = &InvertedPageTable[0];
	lowest_page = 0x7fffffffffffffff;
	for (n = 0; n < NPAGES; n++) {
		if (pte->key == key &&& (pte->dusacrwx & 7) != 0) {
			for (q = m = n; m != 0xffff; m = pte->back) {
				pte = &InvertedPageTable[m];
				q = m;
			}
			lowest_page = q;
			break;
		}
		pte++;
	}
	if (lowest_page == 0x7fffffffffffffff) {
		p = mmu_alloc(size, key, 1);
		pte = GetPTE(p);
		pte->smrc = 1;
		return (p);
	}
	p = (lowest_page << 13) | 0xfff0100000000000;
	pte = GetPTE(p);
	pte->smrc++;		
	return (p);
}

// ----------------------------------------------------------------------------
// Unmap memory, decrementing the shared memory reference count. If the
// reference count becomes zero, free the memory.
// ----------------------------------------------------------------------------

pascal void UnmapSharedMemory(int key, void *addr)
{
	void *p;
	int n, lowest_page;
	PTE *pte;

	pte = &InvertedPageTable[0];
	lowest_page = 0x7fffffffffffffff;
	for (n = 0; n < NPAGES; n++) {
		if (pte->key == key &&& (pte->dusacrwx & 7) != 0)
			lowest_page = min(lowest_page, pte->pagenum);
		pte++;
	}
	if (lowest_page == 0x7fffffffffffffff)
		return;	// no pages were allocated under the key
	p = (lowest_page << 13) | 0xfff0100000000000;
	pte = GetPTE(p);
	if (pte->smrc==1) {
		mmu_free(p);
		return;
	}
	pte->smrc--;
}	


// Maps the card memory into the address space.
// Card memory is a shared memory that aliases the main memory.

void *MapCardMemory()
{
	int pg;
	int n;
	int acr = 6;	// read/write

	return (void *)(pg << 13);
}


// sbrk:
//   Allocates memory with read/write/execute access rights all available. The
// memory protection key used is the working key. The allocated memory is
// associated with the current address space.
//
// Returns:
//	-1 on error, otherwise previous program break.
//
pascal void *sbrk(int size)
{
	byte *p, *q, *r;
	int as,oas;
	int key;

	p = 0;
	key = 0;
	size = round16k(size);
	if (size > 0) {
		p = mmu_alloc(size,workingKey,0);
		if (p==-1)
			errno = E_NoMem;
		return (p);
	}
	else if (size < 0) {
	/*
		as = GetASID();
		if (size > brks[as]) {
			errno = E_NoMem;
			return (-1);
		}
		SetASID(0);
		r = p = brks[as] - size;
		p |= as << 56;
		for(q = p; q & 0xFFFFFFFFFFFFFFL < brks[as];)
			q = ipt_free(q);
		brks[as] = r;
		if (r > 0)
			ipt_alloc_page(as, r, 7, 1);
		SetASID(as);
	*/
	}
	else {	// size==0
		as = GetASID();
		p = brks[as];	
	}
	return (p);
}
