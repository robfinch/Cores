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
#include <fmtk/const.h>
#include <fmtk/config.h>
#include <errno.h>
#include ".\kernel\types.h"

// There are 1024 pages in each map. In the normal 8k page size that means a max of
// 8Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 65536 x 8k pages.
// However the last 144kB (18 pages) are reserved for memory management software.
#define NPAGES	65536
#define CARD_MEMORY		0xFFFFFFFFFFCE0000
#define IPT_MMU				0xFFFFFFFFFFDCD000
#define IPT

#define NULL    (void *)0

extern byte *os_brk;

extern __int8 *osmem;
extern int highest_data_word;
extern __int16 mmu_freelist;		// head of list of free pages
extern int syspages;
extern int sys_pages_available;
extern int mmu_FreeMaps;
extern int mmu_key;
extern __int8 hSearchMap;
extern MEMORY memoryList[NR_MEMORY];
extern int RTCBuf[12];
void puthexnum(int num, int wid, int ul, char padchar);
void putnum(int num, int wid, int sepchar, int padchar);
extern void DBGHideCursor(int hide);

//unsigned __int32 *mmu_entries;

extern byte *brks[256];

// Checkerboard ram test routine.

void ramtest()
{
	int *p;
	int errcount;
	
	errcount = 0;
	DBGHideCursor(1);
	DBGDisplayStringCRLF("Writing 5A code to ram");
	for (p = 0; p < 536870912; p += 2) {
		if ((p & 0xfffff)==0) {
			putnum(p>>20,5,',',' ');
			DBGDisplayChar('M');
			DBGDisplayChar('B');
			DBGDisplayChar('\r');
		}
		p[0] = 0x5555555555555555L;
		p[1] = 0xAAAAAAAAAAAAAAAAL;
	}
	DBGDisplayStringCRLF("\r\nReadback 5A code from ram");
	for (p = 0; p < 536870912; p += 2) {
		if ((p & 0xfffff)==0) {
			putnum(p>>20,5,',',' ');
			DBGDisplayChar('M');
			DBGDisplayChar('B');
			DBGDisplayChar('\r');
		}
		if (p[0] != 0x5555555555555555L || p[1] != 0xAAAAAAAAAAAAAAAAL) {
			errcount++;
			if (errcount > 10)
				break;
		}
	}
	DBGDisplayString("\r\nerrors: ");
	putnum(errcount,5,',',' ');
	errcount = 0;
	DBGDisplayStringCRLF("\r\nWriting A5 code to ram");
	for (p = 0; p < 536870912; p += 2) {
		if ((p & 0xfffff)==0) {
			putnum(p>>20,5,',',' ');
			DBGDisplayChar('M');
			DBGDisplayChar('B');
			DBGDisplayChar('\r');
		}
		p[0] = 0xAAAAAAAAAAAAAAAAL;
		p[1] = 0x5555555555555555L;
	}
	DBGDisplayStringCRLF("\r\nReadback A5 code from ram");
	for (p = 0; p < 536870912; p += 2) {
		if ((p & 0xfffff)==0) {
			putnum(p>>20,5,',',' ');
			DBGDisplayChar('M');
			DBGDisplayChar('B');
			DBGDisplayChar('\r');
		}
		if (p[1] != 0x5555555555555555L || p[0] != 0xAAAAAAAAAAAAAAAAL) {
			errcount++;
			if (errcount > 10)
				break;
		}
	}
	DBGDisplayString("\r\nerrors: ");
	putnum(errcount,5,',',' ');
	DBGDisplayChar('\r');
	DBGDisplayChar('\n');
	DBGHideCursor(0);
}


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

// ----------------------------------------------------------------------------
// Must be called to initialize the memory system before any
// other calls to the memory system are made.
// Initialization includes setting up the linked list of free pages and
// setting up the 512k page bitmap.
// ----------------------------------------------------------------------------

void init_memory_management()
{
	// System break positions.
	// All breaks start out at address 16777216. Addresses before this are
	// reserved for the video frame buffer. This also allows a failed
	// allocation to return 0.
	DBGDisplayChar('A');
	mmu_key = RTCBuf[0];	
	memsetW(brks,16777216,256);
	sys_pages_available = NPAGES;
  
  // Allocate 4MB to the OS
  osmem = ipt_alloc(0,4194303,7);
	DBGDisplayChar('a');
}

// ----------------------------------------------------------------------------
// Allocate a single page. The translation hardware makes this easy by
// picking out the page to allocate. It does it's own search for free pages.
// ----------------------------------------------------------------------------

private pascal void ipt_alloc_page(int asid, byte *vadr, int acr, int last_page)
{
	out64(IPT_MMU+0x10,(asid<<24)|(acr&7)|(last_page<<22));
	out64(IPT_MMU+0x18,vadr);// ^ (mmu_key & 0xffffff));
	out64(IPT_MMU+0x00,1);	// trigger translation update
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void *ipt_alloc(int asid, int amt, int acr)
{
	__int8 *p;
	int npages;
	int nn;

	if (asid < 0 || asid > 255)
		throw (E_BadASID);
	p = -1;
	DBGDisplayChar('B');
	amt = round8k(amt);
	npages = amt >> 13;
	if (npages==0)
		return (p);
	DBGDisplayChar('C');
	if (npages < sys_pages_available) {
		sys_pages_available -= npages;
		p = brks[asid];
		brks[asid] += amt;
		for (nn = 0; nn < npages-1; nn++) {
			ipt_alloc_page(asid,p+(nn << 13),acr,0);
		}
		ipt_alloc_page(asid,p+(nn << 13),acr,1);
		p |= (asid << 56);
	}
	DBGDisplayChar('E');
	return (p);
}


// ipt_free() frees up 8kB blocks previously allocated with ipt_alloc(), but does
// not reset the virtual address pointer. The freed blocks will be available for
// allocation. With a 64-bit pointer the virtial address can keep increasing with
// new allocations even after memory is freed.

byte *ipt_free(byte *vadr)
{
	int n;
	int count;	// prevent looping forever
	int asid;

	asid = vadr >> 56;
	vadr &= 0xFFFFFFFFFFFFFFL;	// strip off asid
	count = 0;
	do {
		// Free memory by updating the page with a zero acr.
		ipt_alloc_page(asid, vadr, 0, 0);
		n = in64(IPT_MMU+0x10);
		// If the page wasn't allocated nothing to do.
		if ((n & 7)==0)
			break;
		vadr += 8192;
		count++;
	}
	while ((((n >> 22) & 1)==0) && count < NPAGES);
	return (vadr);
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
	throw (errno = E_NoMoreACBs);
}

pascal void mmu_FreeMap(register int mapno)
{
	if (mapno < 0 || mapno >= NR_MAPS)
		throw (errno = E_BadMapno);
	mmu_FreeMaps &= ~(1 << mapno);	
}

// Returns:
//	-1 on error, otherwise previous program break.
//
void *sbrk(int size)
{
	byte *p, *q, *r;
	int as,oas;

	p = 0;
	size = round8k(size);
	if (size > 0) {
		as = GetASID();
		SetASID(0);
		p = ipt_alloc(as,size,7);
		SetASID(as);
		if (p==-1)
			errno = E_NoMem;
		return (p);
	}
	else if (size < 0) {
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
	}
	else {	// size==0
		as = GetASID();
		p = brks[as];	
	}
	return (p);
}
