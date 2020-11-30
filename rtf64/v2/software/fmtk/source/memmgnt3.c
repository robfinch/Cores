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
not using gp;

#include <fmtk/const.h>
#include <fmtk/config.h>
#include <errno.h>
#include <fmtk/types.h>

// There are 1024 pages in each map. In the normal 4k page size that means a max of
// 8Mib of memory for an app. Since there is 512MB ram in the system that equates
// to 131072 x 4k pages.
// However the last 144kB (36 pages) are reserved for memory management software.
#define NPAGES	131072
#define CARD_MEMORY		0xFFFFFFFFFFCE0000
#define IPT_MMU				0xFFFFFFFFFFDCD000
#define IPT_OP				0x00		// operations register
#define IPT_VPG				0x18		// virtual page register
#define IPT

#define NULL    (void *)0

extern byte *os_brk;

extern int PAM[4096];
extern PTE* root_page_table[1024];
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
extern pascal void DBGDisplayChar(char ch);
extern void *PAMAlloc(register int amt);
extern void PAMFree(register void *p);

//unsigned __int32 *mmu_entries;

extern byte *brks[256];
private pascal unsigned int round4k(register unsigned int amt);

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// Checkerboard ram test routine.

void DispMB(register int mb)
{
	putnum(mb,5,',',' ');
	DBGDisplayChar('M');
	DBGDisplayChar('B');
	DBGDisplayChar(' ');
	DBGDisplayChar('\r');
}

void ramtest()
{
	int *p;
	int errcount;
	
//	try {
  	errcount = 0;
  	DBGHideCursor(1);
  	//DBGDisplayAsciiStringCRLF(B"Writing 5A code to ram");
  	for (p = 0; p < 67108864; p += 2) {
  		if ((p & 0xfffff)==0) {
  		  DispMB(p>>20);
  		}
  		p[0] = 0x5555555555555555L;
  		p[1] = 0xAAAAAAAAAAAAAAAAL;
  	}
  	//DBGDisplayAsciiStringCRLF(B"\r\nReadback 5A code from ram");
  	for (p = 0; p < 67108864; p += 2) {
  		if ((p & 0xfffff)==0) {
  		  DispMB(p>>20);
  		}
  		if (p[0] != 0x5555555555555555L || p[1] != 0xAAAAAAAAAAAAAAAAL) {
  			errcount++;
  			if (errcount > 10)
  				break;
  		}
  	}
  	DBGDisplayAsciiString(B"\r\nerrors: ");
  	putnum(errcount,5,',',' ');
  	errcount = 0;
  	DBGDisplayAsciiStringCRLF(B"\r\nWriting A5 code to ram");
  	for (p = 0; p < 67108864; p += 2) {
  		if ((p & 0xfffff)==0) {
  		  DispMB(p>>20);
  		}
  		p[0] = 0xAAAAAAAAAAAAAAAAL;
  		p[1] = 0x5555555555555555L;
  	}
  	DBGDisplayAsciiStringCRLF(B"\r\nReadback A5 code from ram");
  	for (p = 0; p < 67108864; p += 2) {
  		if ((p & 0xfffff)==0) {
  		  DispMB(p>>20);
  		}
  		if (p[1] != 0x5555555555555555L ||| p[0] != 0xAAAAAAAAAAAAAAAAL) {
  			errcount++;
  			if (errcount > 10)
  				break;
  		}
  	}
  	DBGDisplayAsciiString(B"\r\nerrors: ");
  	putnum(errcount,5,',',' ');
  	DBGDisplayChar('\r');
  	DBGDisplayChar('\n');
  	DBGHideCursor(0);
/*  	
  }
  catch(int catchVar) {
  	DBGDisplayAsciiString(B"An exception occurred");
  }
  catch(...) {
  	DBGDisplayAsciiString(B"An exception occurred");
  }
*/
}


//private __int16 pam[NPAGES];	

private pascal unsigned int round4k(register unsigned int amt)
{
  amt += 4095;
  amt &= 0xFFFFFFFFFFFFF000L;
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
	memsetO(brks,16777216,256);
	memsetO(root_page_table,0,1024);
	sys_pages_available = NPAGES;
  
  // Allocate 4MB to the OS
  osmem = PAMAlloc(4194303);
	DBGDisplayChar('a');
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int page_present(int p)
{
  return (p[50:48] != 0);
}

// PTEs are a 160-bit structure or 20 bytes. 1024 PTEs fit into five 4kB
// pages of memory.

void pt_setup_pte(PTE** pte, int vpn, int asid, int acr, int key)
{
  PTE* q;
  int r;
  int nn;

  r = PAMAlloc(20480);  // Allocate five pages
  q = (PTE*)r;
  memsetO(q, 0, 2560);
  (*pte)->ppn = r >> 12;
  (*pte)->vpn = vpn;
  (*pte)->x = acr[0];
  (*pte)->w = acr[1];
  (*pte)->r = acr[2];
  (*pte)->c = acr[3];
  (*pte)->a = 1;
  (*pte)->d = 0;
  (*pte)->g = 0;
  (*pte)->asid = asid;
  (*pte)->key = key;
}

// ----------------------------------------------------------------------------
// If the page isn't allocated at the highest directory level, a chain
// of pages allocated for the virtual address must be set up.
// ----------------------------------------------------------------------------

void pt_alloc_page(int key, int asid, unsigned int vpn, int acr, int opt)
{
  PTE *p, *q;
  int pe, r;
  int nn;
  int depth;
 
  p = root_page_table[asid*4+vpn[63:62]];
  depth = p & 7;
  p = p & ~4095;    // page table must be page aligned
  if (depth > 4) {
    pe = vpn[61:52];
    q = &p[pe];
    if (q->x==0 &&& q->w==0 &&& q->r==0) {
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[51:42];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[41:32];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[31:22];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[21:12];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
    }
  }
  else
    q = p;
  if (depth > 3) {
    pe = vpn[51:42];
    q = &q[pe];
    if (q->x==0 &&& q->w==0 &&& q->r==0) {
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[41:32];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[31:22];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[21:12];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
    }
  }
  else
    q = p;
  if (depth > 2) {
    pe = vpn[41:32];
    q = &q[pe];
    if (q->x==0 &&& q->w==0 &&& q->r==0) {
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[31:22];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[21:12];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
    }
  }
  else
    q = p;
  if (depth > 1) {
    pe = vpn[31:22];
    q = &q[pe];
    if (q->x==0 &&& q->w==0 &&& q->r==0) {
      pt_setup_pte(&q,pe,asid,acr,key);
      pe = vpn[21:12];
      q = &q[pe];
      pt_setup_pte(&q,pe,asid,acr,key);
    }
  }
  else 
    q = p;
  pe = vpn[21:12];
  q = &q[pe];
  if (q->x==0 &&& q->w==0 &&& q->r==0) {
    pt_setup_pte(&q,pe,asid,acr,key);
    q->u = opt;
  }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void *pt_alloc(int key, int asid, int amt, int acr)
{
	__int8 *p;
	int npages;
	int nn;

	if (asid < 0 ||| asid > 255)
		throw (E_BadASID);
	p = -1;
	DBGDisplayChar('B');
	amt = round4k(amt);
	npages = amt >> 12;
	if (npages==0)
		return (p);
	DBGDisplayChar('C');
	if (npages < sys_pages_available) {
		sys_pages_available -= npages;
		p = brks[asid];
		brks[asid] += amt;
		for (nn = 0; nn < npages-1; nn++) {
			pt_alloc_page(key,asid,p+(nn << 12),acr,0);
		}
		pt_alloc_page(key,asid,p+(nn << 12),acr,1);
		p |= (asid << 56);
	}
	DBGDisplayChar('E');
	return (p);
}


// pt_free() frees up 4kB blocks previously allocated with pt_alloc(), but does
// not reset the virtual address pointer. The freed blocks will be available for
// allocation. With a 64-bit pointer the virtial address can keep increasing with
// new allocations even after memory is freed.

byte *pt_free(byte *vadr)
{
	int n;
	int count;	// prevent looping forever
	int asid;
	int key;
	PTE* p, * q;
	int pe;
	int depth;

	key = 0;
	asid = vadr >> 56;
	asid &= 0xff;
	vadr &= 0xFFFFFFFFFFFFFFL;	// strip off asid
	count = 0;
	do {
    p = root_page_table[asid];
    depth = p & 7;
    p = p & ~4095;
    if (depth > 4) {
      pe = (vadr >> 48) & 0xff;
      q = &p[pe];
      if (q->x==0 &&& q->w==0 &&& q->r==0)
        return (vadr);
    }
    if (depth > 3) {
      pe = (vadr >> 39) & 0xfff;
      q = &q[pe];
      if (q->x==0 &&& q->w==0 &&& q->r==0)
        return (vadr);
    }
    if (depth > 2) {
      pe = (vadr >> 30) & 0xfff;
      q = &q[pe];
      if (q->x==0 &&& q->w==0 &&& q->r==0)
        return (vadr);
    }
    if (depth > 1) {
      pe = (vadr >> 21) & 0xfff;
      q = &q[pe];
      if (q->x==0 &&& q->w==0 &&& q->r==0)
        return (vadr);
    }
    pe = (vadr >> 12) & 0xfff;
    q = &q[pe];
    if (q->x==0 &&& q->w==0 &&& q->r==0)
      return (vadr);
    q->x = 0;
    q->w = 0;
    q->r = 0;
    PAMUnmarkPage(q->ppn);
		vadr += 4096;
		count++;
		if (q->u)
		  break;
	}
	while (count < NPAGES);
	return (vadr);
}

int mmu_AllocateMap()
{
	int count;
	
	for (count = 0; count < NR_MAPS; count++) {
		if (mmu_FreeMaps[hSearchMap]==0) {
			mmu_FreeMaps[hSearchMap] = 1;
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
	if (mapno < 0 ||| mapno >= NR_MAPS)
		throw (errno = E_BadMapno);
	mmu_FreeMaps[mapno] = 0;	
}

// Returns:
//	-1 on error, otherwise previous program break.
//
void *sbrk(int size)
{
	byte *p, *q, *r;
	int as,oas;
	int key;

  try {
  	p = 0;
  	key = 0;
  	size = round4k(size);
  	if (size > 0) {
  		as = GetASID();
  		SetASID(0);
  		p = pt_alloc(key,as,size,7);
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
  			q = pt_free(q);
  		brks[as] = r;
  		if (r > 0)
  			pt_alloc_page(as, r, 7, 1);
  		SetASID(as);
  	}
  	else {	// size==0
  		as = GetASID();
  		p = brks[as];	
  	}
  }
  catch (int e) {
    errno = e;
    return (-1);
  }
	return (p);
}
