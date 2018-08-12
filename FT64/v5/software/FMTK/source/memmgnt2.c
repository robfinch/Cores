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
// ============================================================================
//
#include ".\kernel\const.h"
#include ".\kernel\config.h"
#include ".\kernel\types.h"

// There are 1024 pages in each map. In the normal 8k page size that means a max of
// 8Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 65536 x 8k pages.
// However the last 144kB (18 pages) are reserved for memory management software.
#define NPAGES	65518
#define CARD_MEMORY		0xFFCE0000

#define NULL    (void *)0

extern int highest_data_word;
extern __int16 mmu_freelist;		// head of list of free pages
extern int syspages;
extern int sys_pages_available;
extern int mmu_FreeMaps;
extern __int32 *mmu_entries;
extern __int8 hSearchMap;
extern MEMORY memoryList[NR_MEMORY];

//unsigned __int32 *mmu_entries;

extern int pam512[1024];
extern __int16 pam8[NPAGES];

//private __int16 pam[NPAGES];	
// There are 128, 4MB pages in the system. Each 4MB page is composed of 64 64kb pages.
//private int pam4mb[NPAGES/64];	// 4MB page allocation map (bit for each 64k page)
//int syspages;					// number of pages reserved at the start for the system
//int sys_pages_available;	// number of available pages in the system
//int sys_4mbpages_available;

private pascal unsigned int round8k(register unsigned int amt)
{
    amt += 8191;
    amt &= 0xFFFFFFFFFFFFE000L;
    return (amt);
}

private pascal unsigned int round512k(register unsigned int amt)
{
    amt += 0x7ffff;	// 512k - 1
    amt &= 0xFFFFFFFFFFF80000L;
    return (amt);
}

naked inline int _GetMMUAccessKey()
{
	__asm {
		csrrd	r1,#3,r0
		bfextu	r1,r1,#8,#7
	}
}

naked inline int _GetMMUOperateKey()
{
	__asm {
		csrrd	r1,#3,r0
		bfextu	r1,r1,#0,#7
	}
}

naked inline void _SetMMUAccessKey(register int map)
{
	__asm {
		csrrd	r1,#3,r0		// get PCR
		bfclr	r1,r1,#8,#7
		shl		r18,r18,#8
		or		r1,r1,r18
		csrrw	r0,#3,r1		// set PCR
	}
}

// The access key for the mmu needs to be setup before the
// page tables can be referenced.

pascal void mmu_SetAccessKey(int mapno)
{
	if (mapno < 0 || mapno >= NR_MAPS)
		throw (E_BadMapno);
	_SetMMUAccessKey(mapno);
}

naked inline int _SetMMUOperateKey(register int map)
{
	__asm {
		csrrd	r1,#3,r0		// get PCR
		and		$r1,$r1,#$FFFFFFFFFFFFFF00
		or		$r1,$r1,$r18
		csrrw	r1,#3,r1		// set PCR
		bfextu	r1,r1,#0,#7		// extract old operating key
	}
}

pascal int mmu_SetOperateKey(int mapno)
{
	if (mapno < 0 || mapno >= NR_MAPS)
		throw (E_BadMapno);
	return (_SetMMUOperateKey(mapno));
}
// Detect whether the page table maps 8kB or 512kB pages.

private pascal int Is512kPages()
{
	asm {
		csrrd	r1,#3,r0	// Get PCR
		bfextu	r1,r1,8,5	// extract access key
		csrrd	r2,#8,r0	// get PCR2
		shr		r1,r2,r1
		and		r1,r1,#1
	}
}

// ----------------------------------------------------------------------------
// Must be called to initialize the memory system before any
// other calls to the memory system are made.
// Initialization includes setting up the linked list of free pages and
// setting up the 512k page bitmap.
// ----------------------------------------------------------------------------

void init_memory_management()
{
	int pg;
    int nn;

	// Setup linked list of free pages (FAT style)
	mmu_freelist = 512;
	for (nn = 0; nn < NPAGES; nn++) {
		pam8[nn] = nn+1;
	}
	pam8[511] = 0xffff;
	pam8[NPAGES-1] = 0xffff;
	// Use bitmaps for 512kB allocations
	// Allocate the first 4MB of memory to the BIOS/OS
	for (nn = 0; nn < 8; nn = nn + 1)
		pam512[nn] = -1;
	for (nn = 8; nn < 1023; nn++)
		pam512[nn] = 0;
	// The last 18 pages are for memory management
	pam512[1023] = 0xFFFFC00000000000L;

	mmu_entries = (unsigned __int32 *)0xFFDC4000;
	sys_pages_available = NPAGES;
    syspages = 8 * 64;
}

// ----------------------------------------------------------------------------
// Allocate an 8k page. The page is removed from the free list.
// ----------------------------------------------------------------------------

int mmu_Alloc8kPage()
{
    int sb, pg4;

	if (mmu_freelist < syspages || mmu_freelist >= NPAGES)
		throw (E_NoMem);
	sb = mmu_freelist;
	mmu_RemoveFromFreeList(sb);
	mmu_freelist = pam8[mmu_freelist];
	sys_pages_available--;
	pg4 = (sb >> 6);
	pam512[pg4] |= (1 << (sb & 63));
	return (sb);
}

// ----------------------------------------------------------------------------
// Takes a page number allocated with sys_alloc and returns it to
// available memory pool.
// ----------------------------------------------------------------------------

pascal void mmu_Free8kPage(register int pg)
{
	int pg4;

    if (pg < syspages || pg >= NPAGES)
        throw (E_BadPageno);
	pam8[pg] = mmu_freelist;
	mmu_freelist = pg;
	sys_pages_available++;
	pg4 = (pg >> 6);
	pam512[pg4] &= ~(1 << (pg & 63));
}

// ----------------------------------------------------------------------------
// Removes a 512kB page from the freelist.
// We know that 64 consecutive pages should be removed. There's
// no reason to test the rest of the free list once the 64 pages
// have been removed.
// ----------------------------------------------------------------------------

private pascal void Remove512kPageFromFreelist(register int a)
{
	int c, p, f;

	// p is set to NPAGES+1 (an invalid page number with an available memory
	// cell at the end of the table), so that a test of p doesn't have to be
	// made in the loop.
	p = NPAGES+1;
	// Search for the first page of the 512k area
	for (c = mmu_freelist; c >=0 && c < NPAGES && ((c>>6) != a); c = pam8[c])
		p = c;
	// Couldn't find the page ?
	if (c < 0 || c >= NPAGES)
		throw (E_BadPageno);
	f = p;
	// Search for the last page of the 512k area.
	for (; (c>>6)==a; c = pam8[c])
		p = c;
	// Reset link for entire chain.
	pam8[f] = pam8[p];
	// The only time f is NPAGES+1 occurs when the pages are at the head of
	// the free list.
	if (f==NPAGES+1)
		mmu_freelist = pam8[p];
	sys_pages_available -= 64;
}

// ----------------------------------------------------------------------------
// To allocate a 512kB page first a 512kB free area must be found.
// This is done with a linear search of the pam512 bitmap.
// Next the free list of 8kB pages must be traversed for free
// pages in the region of the 512kB free page. These page must
// be removed from the free list.
// ----------------------------------------------------------------------------

int mmu_Alloc512kPage()
{
	static int a = 0;
	int count;

	for (count = 0; count < 1024; count++) {
		if (pam512[a]==0) {
			Remove512kPageFromFreelist(a);
			pam512[a] = 0xFFFFFFFFFFFFFFFFL;
			return (a);
		}
		a++;
		if (a > 1023)
			a = 0;
	}	
	throw (E_NoMem);
}

// ----------------------------------------------------------------------------
// Freeing a 512kB page is relatively easy. It's just a matter of freeing all
// 8kB pages that make it up.
// The first page is for the BIOS / video memory. It can't be deallocated.
// ----------------------------------------------------------------------------

pascal void mmu_Free512kPage(int pg)
{
	int p, cnt;

	if (pg < 8 || pg > 1023)
		throw (E_BadPageno);
	p = pg << 6;
	for (cnt = 0; cnt < 64; cnt++, p++)
		mmu_Free8kPage(p);
}


// ----------------------------------------------------------------------------
// In the page table there will be up to 1024 entries.
// Need to find npages of consecutive free entries in the page table.
// Works for either 8k or 512kB page size.
// ----------------------------------------------------------------------------

private pascal int findMMUPages(register int npages, register int maxpages)
{
	int nn, mm, np;

	if (npages <= 0 || npages > maxpages)
		throw (E_BadPageno);

	for (nn = 0; nn < maxpages; nn++) {
		if ((mmu_entries[nn] & 0x180000) == 0) {	// found an empty entry ?
			mm = nn;
			np = npages;
			while (np > 0) {
				if ((mmu_entries[mm] & 0x180000) != 0) {
					goto L1;
				}
				mm++;
				np--;
			}
			return (nn);
		}
L1:	;
	}
	throw (E_NoMem);
}

// ----------------------------------------------------------------------------
// Allocate npages from the page table
//
// ----------------------------------------------------------------------------

private pascal int allocMMUPages(int npages, int acr)
{
	int first_page;
	int page;
	int n;

	if (acr <= 0 || acr > 7)
		throw (E_Arg);
	if (npages <= 0 || npages > sys_pages_available)
		throw (E_BadPageno);
	first_page = findMMUPages(npages,1024);
	for (n = first_page; n < first_page + npages - 1; n++) {
		page = mmu_Alloc8kPage();
		mmu_entries[n] = (1 << 19) | (acr << 16) | (page & 0xFFFF);
	}
	page = mmu_Alloc8kPage();
	mmu_entries[n] = (2 << 19) | (acr << 16) | (page & 0xffff);
	return (first_page);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private pascal int alloc512kMMUPages(int npages, int acr)
{
	int first_page;
	int page;
	int n;

	if (acr <= 0 || acr > 7)
		throw (E_Arg);
	if (npages <= 0 || ((npages << 6) > sys_pages_available))
		throw (E_BadPageno);
	first_page = findMMUPages(npages,1024);
	for (n = first_page; n < first_page + npages - 1; n++) {
		page = mmu_Alloc512kPage();
		mmu_entries[n] = (1 << 19) | (acr << 16) | ((page << 6) & 0xFFC0);
	}
	page = mmu_Alloc512kPage();
	mmu_entries[n] = (2 << 19) | (acr << 16) | ((page << 6) & 0xffc0);
	return (first_page);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

private pascal void freeMMUPages(int first_page, int opt)
{
	int n;

	if (first_page < 0 || first_page > 1023)
		throw (E_BadPageno);

	n = first_page;
	while ((mmu_entries[n] & 0x180000)!=100000 && n < 1024) {	// last page ?
		if (!opt)
			mmu_Free8kPage(mmu_entries[n] & 0xffff);
		mmu_entries[n] &= 0x07FFFF;
		n++;
	}
	if (!opt)
		mmu_Free8kPage(mmu_entries[n] & 0xffff);
	mmu_entries[n] &= 0x07FFFF;
}

private pascal void free512kBMMUPages(int first_page, int opt)
{
	int n;

	if (first_page < 0 || first_page > 1023)
		throw (E_BadPageno);

	n = first_page;
	while ((mmu_entries[n] & 0x180000)!=100000 && n < 1024) {	// last page ?
		if (!opt)
			Free512kPage((mmu_entries[n] & 0xffff) >> 6);
		mmu_entries[n] &= 0x07FFFF;
		n++;
	}
	if (!opt)
		Free512kPage((mmu_entries[n] & 0xffff) >> 6);
	mmu_entries[n] &= 0x07FFFF;
}

pascal void *mmu_alloc(int amt, int acr)
{
	int page;

	if (Is512kPages()) {
		amt = (round512k(amt) >> 19) != 0;
		page = alloc512kMMUPages(amt, acr);
	}
	else {
		amt = (round8k(amt) >> 13) != 0;
		page = allocMMUPages(amt, acr);
	}
	if (Is512kBPages())
		return (void *)(page << 19);
	else
		return (void *)(page << 13);
}


// Opt if zero indicates to free physical memory.
// Otherwise just the map entries are cleared.
// This is used for shared memories.

pascal void mmu_free(void *pmem, int opt)
{
	if (Is512kPages()) {
		if (pmem & 0x7FFFFL)
			throw (E_Arg);
		free512kMMUPages((int)(pmem >> 19), opt);
	}
	else {
		if (pmem & 0x1fffL)
			throw (E_Arg);
		freeMMUPages((int)(pmem >> 13), opt);
	}
}


int mmu_AllocateMap()
{
	int count;
	
	for (count = 0; count < NR_MAPS; count++) {
		if (((mmu_FreeMaps >> hSearchMap) & 1)==0) {
			mmu_FreeMaps |= (1 << hSearchMap);
			return (hSearchMap);
		}
		hSearchMap++;
		if (hSearchMap >= NR_MAPS)
			hSearchMap = 0;
	}
	throw (E_NoMoreACBs);
}

pascal void mmu_FreeMap(register int mapno)
{
	if (mapno < 0 || mapno >= NR_MAPS)
		throw (E_BadMapno);
	mmu_FreeMaps &= ~(1 << mapno);	
}

pascal void mmu_SetMapEntry(register void *physptr, register int acr, register int entryno)
{
	if (entryno < 0 || entryno > 1023)
		throw (E_BadEntryno);
	mmu_entries[entryno] = (__int32)((physptr >> 13) & 0xffff) | (acr << 16);
}

pascal void *mmu_GetPhysAddr(void *ptr)
{
	int ndx = (int)ptr;
	int offs;

	if (Is512kPages()) {
		offs = (int)ptr & 0x7ffff;
		ndx >>= 19;
		if (ndx < 0 || ndx > 1023)
			throw (E_Arg);
		ptr = (void *)(((mmu_entries[ndx] & 0xffc0) << 13) | offs);
	}
	else {
		offs = (int)ptr & 0x1fff;
		ndx >>= 13;
		if (ndx < 0 || ndx > 1023)
			throw (E_Arg);
		ptr = (void *)(((mmu_entries[ndx] & 0xffff) << 13) | offs);
	}
	return (ptr);
}

pascal void *mmu_GetVirtAddr(void *ptr)
{
	int val, val2;
	int mask;
	int n;
	int offs;

	val = (int)ptr;
	if (Is512kPages()) {
		mask = 0xffc0;
		offs = (int)ptr & 0x7ffff;
	}
	else {
		offs = (int)ptr & 0x1fff;
		mask = 0xffff;
	}
	val = (val >> 13) & mask;
	for (n = 0; n < 1024; n++) {
		val2 = (mmu_entries[n] & mask);
		if (val==val2) {
			if (Is512kPages())
				return (void *)((n << 19) | offs);
			else
				return (void *)((n << 13) | offs);
		}
	}
	return (void *)(-1);
}

// For shared memory. Copy a portion of a source map to the destination map.
// Returns a virtual address pointer to the shared memory in the destination map.

void *mmu_CopyMap(int dstMapno, int srcMapno, void *vaddr, int size)
{
	int pages;
	int dstpg;
	int srcpg;
	int n;
	int mmue;

	_SetMMUAccessKey(srcMapno);
	if (Is512kPages()) {
		pages = ((size + 524287) >> 19);
		srcpg = vaddr >> 19;
		_SetMMUAccessKey(dstMapno);
		if (!Is512kPages())
			throw (E_PagesizeMismatch);
	}
	else {
		pages = ((size + 8191) >> 13);
		srcpg = vaddr >> 13;
		_SetMMUAccessKey(dstMapno);
		if (Is512kPages())
			throw (E_PagesizeMismatch);
	}
	dstpg = findMMUPages(pages, 1024);
	for (n = 0; n < pages; n++) {
		_SetMMUAccessKey(srcMapno);
		mmue = mmu_entries[srcpg+n];
		_SetMMUAccessKey(dstMapno);
		mmu_entries[dstpg+n] = mmue;
	}
	if (Is512kPages())
		return (void *)(dstpg << 19);
	else
		return (void *)(dstpg << 13);
}


// Map shared memory attempts to find a memory region with the specified key.
// If found, the map is copied to the requestor.
// Otherwise memory is allocated, and a pointer to the allocated memory returned.

void *MapSharedMemory(int key, int size)
{
	MEMORY *pMem;
	void *p;
	int n;

	for (n = 0; n < NR_MEMORY; n = n + 1)	{
		pMem = &memoryList[n];
		if (pMem->key == key) {
			p = mmu_CopyMap(_GetMMUOperateKey(), pMem->owningMap, pMem->addr, pMem->size);
			pMem->shareMap |= (1 << _GetMMUOperateKey());
			return (p);
		}
	}
	p = mmu_alloc(size,7);
	for (n = 0; n < NR_MEMORY; n = n + 1) {
		pMem = &memoryList[n];
		if (pMem->key == 0) {
			pMem->key = key;
			pMem->addr = p;
			pMem->size = size;
			pMem->owningMap = _GetMMUOperateKey();
			pMem->shareMap = (1 << _GetMMUOperateKey());
			return (p);
		}
	}
	throw (E_NoMem);
}

void UnmapSharedMemory(int key, void *addr)
{
	int n;
	MEMORY *pMem;
	
	for (n = 0; n < NR_MEMORY; n++) {
		pMem = &memoryList[n];
		if (pMem->key == key) {
			pMem->shareMap &= ~(1 << _GetMMUOperateKey());
			mmu_free(addr, pMem->shareMap);
			if (pMem->shareMap==0) {
				pMem->owningMap = -1;
				pMem->addr = 0;
				pMem->size = 0;
				pMem->key = 0;
			}
			return;
		}		
	}
	throw (E_NotAlloc);
}


// Maps the card memory into the address space.
// Card memory is a shared memory that aliases the main memory.

void *MapCardMemory()
{
	int pg;
	int n;
	int acr = 6;	// read/write

	if (Is512kPages()) {
		pg = findMMUPages(1,1024);
		mmu_entries[pg] = (2 << 19) | (acr << 16) | ((CARD_MEMORY >> 13) & 0xffc0);
		return (void *)(pg << 19);
	}
	else {
		pg = findMMUPages(1,1024);
		mmu_entries[pg] = (2 << 19) | (acr << 16) | (((CARD_MEMORY + (_GetMMUOperateKey() << 11))) >> 13) & 0xffff);
		return (void *)(pg << 13);
	}
}


