#ifndef _PROTO_H
#define _PROTO_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// proto.h
// Function prototypes.
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
// ACB functions
ACB *GetACBPtr();                   // get the ACB pointer of the running task
ACB *GetRunningACBPtr();
hACB GetAppHandle();

void FMTK_Reschedule();
int FMTK_SendMsg(register hMBX hMbx, register int d1, register int d2, register int d3);
int FMTK_WaitMsg(register hMBX hMbx, register int *d1, register int *d2, register int *d3, register int timelimit);
int FMTK_StartThread(register __int32 *pCode, register int stacksize, register int *pStack, register char *pCmd, register int info);
int FMTK_StartApp(register AppStartupRec *rec);
void RequestIOFocus(register ACB *);

pascal int chkTCB(register TCB *p);
pascal int InsertIntoReadyList(register hTCB ht);
pascal int RemoveFromReadyList(register hTCB ht);
pascal int InsertIntoTimeoutList(register hTCB ht, register int to);
pascal int RemoveFromTimeoutList(register hTCB ht);
void DumpTaskList();

pascal void SetBound48(TCB *ps, TCB *pe, int algn);
pascal void SetBound49(ACB *ps, ACB *pe, int algn);
pascal void SetBound50(MBX *ps, MBX *pe, int algn);
pascal void SetBound51(MSG *ps, MSG *pe, int algn);

pascal void set_vector(register unsigned int, register unsigned int);
int getCPU();
int GetVecno();          // get the last interrupt vector number
void outb(register unsigned int, register int);
void outc(register unsigned int, register int);
void outh(register unsigned int, register int);
void outw(register unsigned int, register int);
pascal int LockSemaphore(register int *sema, register int retries);
naked inline void UnlockSemaphore(register int *sema) __attribute__(__no_temps)
{
	asm {
		std	r0,[r18]
	}
}
naked inline void SetVBA(register int value)  __attribute__(__no_temps)
{
	asm {
		csrrw	r0,#4,r18
	}
}

pascal int LockSysSemaphore(register int retries);
pascal int LockIOFSemaphore(register int retries);
pascal int LockKbdSemaphore(register int retries);
naked inline void UnlockIOFSemaphore()
{
	__asm {
		ldi		r1,#8
		csrrc	r0,#12,r1
	}
}

naked inline void UnlockKbdSemaphore()
{
	__asm {
		ldi		r1,#16
		csrrc	r0,#12,r1
	}
}


naked inline int GetImLevel()
{
	__asm {
		csrrd	r1,#$044,r0
		and		r1,r1,#7
	}
}

// Restoring the interrupt level does not have a ramp, because the level is
// being set back to enable interrupts, from a disabled state. Following the
// restore interupts are allowed to happen, we don't care if they do.

naked inline void RestoreImLevel(register int level)
{
	__asm {
		csrrd	r1,#$044,r0
		bfins	r1,r18,0,2
		csrrw	r1,#$044,r1
	}
}

// The following causes a privilege violation if called from user mode
#define check_privilege() asm { }

// tasks
void FocusSwitcher();

naked inline void LEDS(register int val)  __attribute__(__no_temps)
{
    asm {
        stt    r18,LEDS
    }
}

extern int mmu_Alloc8kPage();
extern pascal void mmu_Free8kPage(register int pg);
extern int mmu_Alloc512kPage();
extern pascal void mmu_Free512kPage(int pg);
extern pascal void mmu_SetAccessKey(int mapno);
extern pascal int mmu_SetOperateKey(int mapno);
extern pascal void *mmu_alloc(int amt, int acr);
extern pascal void mmu_free(void *pmem);
extern pascal void mmu_SetMapEntry(register void *physptr, register int acr, register int entryno);
extern int mmu_AllocateMap();
extern pascal void mmu_FreeMap(register int mapno);
extern int *mmu_MapCardMemory();

#endif
