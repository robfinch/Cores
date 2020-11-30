// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2019  Robert Finch, Waterloo
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
#include <fmtk/config.h>
#include <fmtk/const.h>
#include <fmtk/types.h>
#include <fmtk/proto.h>
#include <fmtk/glo.h>

#define NR_APPS	64
#define MMU_WR	4
#define MMU_RD	2
#define MMU_EX	1

#define MMU_RW	MMU_WR|MMU_RD

// ToDo: Add UI data

int FMTK_StartApp(AppStartupRec *asr)
{
	int mapno, omapno;
	int ret;
	ACB *pACB;
	__int32 *pScrn;
	int *pStack;
	int ncpages, ndpages, nhpages, nspages, nn, nCardPages;
	int page;
	int *p;
	__int16 *pCode;
	int *pData;
	int ndx;
	int info;

	try {	
		mapno = mmu_AllocateMap();
		mmu_SetAccessKey(mapno);
		// Allocate a page for the ACB
		pACB = mmu_Alloc8kPage();
		// Keep track of the physical address of the ACB
		ACBPtrs[mapno] = pACB;
		mmu_SetMapEntry(pACB,MMU_RW|0x10,0);
		pACB->magic = ACB_MAGIC;
		pACB->garbage_list = null;
		//pACB->CardMemory = MapCardMemory();
		nCardPages = 2;	// +1 for ACB
		// Pointer type indicator memory is sixteen pages, 1008 to 1023
		for (nn = 0; nn < 16; nn++) {
			page = mmu_Alloc8kPage();
			p = (int *)(page << 13);
			mmu_SetMapEntry(p,MMU_RW|0x8,nn+1008);
		}
		mmu_SetMapEntry(p,MMU_RW|0x10,nn+1008);
		// Setup text video
		pScrn = (__int32 *)(mmu_Alloc8kPage() << 13)
				| 0xFFFFF00000000000L;
		mmu_SetMapEntry(pScrn,MMU_RW|0x10,1007);
		pScrn = (__int32 *)(mmu_Alloc8kPage() << 13)
				| 0xFFFFF00000000000L;
		mmu_SetMapEntry(pScrn,MMU_RW|0x8,1006);
		pScrn = (__int32 *)(mmu_Alloc8kPage() << 13)
				| 0xFFFFF00000000000L;
		mmu_SetMapEntry(pScrn,MMU_RW|0x8,1005);
		pScrn = (__int32 *)(mmu_Alloc8kPage() << 13)
				| 0xFFFFF00000000000L;
		mmu_SetMapEntry(pScrn,MMU_RW|0x8,1004);
		pACB->pVidMem = (__int32 *)(1004 << 13)
				| 0xFFFFF00000000000L;
		pACB->pVirtVidMem = (__int32 *)(1004 << 13)
				| 0xFFFFF00000000000L;
		pACB->VideoRows = 50;
		pACB->VideoCols = 80;
		pACB->CursorRow = 0;
		pACB->CursorCol = 0;
		pACB->NormAttr = 0x87fc00;

		pStack = (int *)(mmu_Alloc8kPage() << 13)
				| 0xFFFFF00000000000L;
		mmu_SetMapEntry(pStack,MMU_RW|0x8,987);

		// Allocate storage space for code
		ncpages = (asr->codesize+8191) >> 13;
		ndx = 0;
		for (nn = 0; nn < ncpages; nn++)	{
			page = mmu_Alloc8kPage();
			p = (int *)(page << 13);
			memcpy(p, &asr->pCode[ndx], 8192);
			mmu_SetMapEntry(p,MMU_EX|0x8,nn+nCardPages);
			ndx += 2048;
		}
		mmu_SetMapEntry(p,MMU_EX|0x10,nn+nCardPages);
		pCode = (__int16 *)(1 << 13)
				| 0xFFFFF00000000000L;
		pACB->pCode = pCode;

		// Allocate storage space for initialized data
		// and copy from start-up record
		ndpages = (asr->datasize+8191) >> 13;
		ndx = 0;
		for (nn = 0; nn < ndpages; nn++)	{
			page = mmu_Alloc8kPage();
			p = (int *)(page << 13);
			memcpy(p, &asr->pData[ndx], 8192);
			mmu_SetMapEntry(p,MMU_EX|0x8,nn+ncpages+nCardPages);
			ndx += 1024;
		}
		mmu_SetMapEntry(p,MMU_EX|0x10,nn+ncpages+nCardPages);
		pData = (__int32 *)((1+ncpages) << 13)
				| 0xFFFFF00000000000L;
		pACB->pData = pData;

		// Allocate storage space for heap
		nhpages = (asr->heapsize+8191) >> 13;
		for (nn = 0; nn < nhpages; nn++)	{
			page = mmu_Alloc8kPage();
			p = (int *)(page << 13);
			mmu_SetMapEntry(p,MMU_EX|0x8,nn+ndpages+ncpages+nCardPages);
		}
		mmu_SetMapEntry(p,MMU_EX|0x10,nn+ndpages+ncpages+nCardPages);
		/*
		pACB->Heap->pHeap = (MBLK *)((1+ndpages+ncpages) << 13);
		pACB->Heap->size = (((asr->heapsize + 8191) >> 13) << 13);
		pACB->Heap->next = null;
		pACB->Heap->shareMap = (1 << mapno);
		*/
		//pACB->Heap.addr = (MBLK *)((ndpages+ncpages+nCardPages) << 13)
		//		| 0xFFFFF00000000000L;
		omapno = mmu_SetOperateKey(mapno);
		CreateHeap((void *)((1+ndpages+ncpages) << 13) | 0xFFFFF00000000000L,
			(((asr->heapsize + 8191) >> 13) << 13));
		//InitHeap(pACB->Heap->pHeap, nhpages << 13);
		mmu_SetOperateKey(omapno);

		// Allocate storage space for stack
		nspages = (asr->stacksize+8191) >> 13;
		for (nn = 0; nn < nspages; nn++)	{
			page = mmu_Alloc8kPage();
			p = (int *)(page << 13);
			mmu_SetMapEntry(p,MMU_EX|(nn==0?0x10:0x8),1019-nn);
		}
		pStack = (int *)((1020-nspages) << 13)
				| 0xFFFFF00000000000L;

		// Start the startup thread
		info = (asr->priority << 48) | (mapno << 32) | asr->affinity;
		FMTK_StartThread(
			pCode,			// start address
			nspages << 13,
			pStack,			// pointer to stack memory
			&pACB->commandLine,	// parameter
			info
		);
	}
	catch(int er) {
		return (er);
	}
}
