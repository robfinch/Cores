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
#include "config.h"
#include "const.h"
#include "types.h"
#include "proto.h"
#include "glo.h"
#include "TCB.h"

#define WRS	$11

extern int GetRand(register int stream);
extern int shell();
MEMORY memoryList[NR_MEMORY];

//int interrupt_table[512];
int irq_stack[512];
extern int FMTK_Inited;
extern ACB *ACBPtrs[NR_ACB];
extern TCB tcbs[NR_TCB];
extern hTCB readyQ[8];
extern int sysstack[1024];
extern int sys_stacks[NR_TCB][512];
extern int bios_stacks[NR_TCB][512];
extern int fmtk_irq_stack[512];
extern int fmtk_sys_stack[512];
extern MBX mailbox[NR_MBX];
extern MSG message[NR_MSG];
extern int nMsgBlk;
extern int nMailbox;
extern hACB freeACB;
extern hMSG freeMSG;
extern hMBX freeMBX;
extern ACB *IOFocusNdx;
extern int IOFocusTbl[4];
extern int iof_switch;
extern char hasUltraHighPriorityTasks;
extern int missed_ticks;
extern byte hSearchApp;
extern byte hFreeApp;

extern hTCB TimeoutList;
extern hMBX hKeybdMbx;
extern hMBX hFocusSwitchMbx;
extern int im_save;

// This set of nops needed just before the function table so that the cpu may
// fetch nop instructions after going past the end of the routine linked prior
// to this one.

naked void FMTK_NopRamp()
{
	__asm {
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
	}
}

naked inline int GetCauseCode()
{
  __asm {
		csrrw	a0,#6,x0
  }
}

naked inline int GetTick()
{
	__asm	{
		csrrw	$a0,#2,x0
	}
}

naked inline void AckTimerIRQ()
{
  __asm {
    ldi		$a0,#3				; reset the edge sense circuit
    stt		$a0,PIC_ESR
  }
}

naked void DisplayIRQLive()
{
   __asm {
     ldtu     $a0,$FFFFFFFFFFD00000+440
     addi     $a0,$a0,#1
     stt      $a0,$FFFFFFFFFFD00000+440
     ret
   }
}

inline TCB *GetRunningTCBPtr()
{
	__asm {
		csrrw	$a0,#$10,$x0
	}
}

inline TCB *SetRunningTCBPtr(register int ptr)
{
	__asm {
		csrrw	$a0,#$10,$a0
	}
}

ACB *SafeGetACBPtr(register int n)
{
	if (n < 0 || n >= NR_ACB)
		return (null);
    return (ACBPtrs[n]);
}

ACB *GetACBPtr(register int n)
{
    return (ACBPtrs[n]);
}
hACB GetAppHandle()
{
	return (GetRunningTCBPtr()->hApp);
}

ACB *GetRunningACBPtr()
{
	return (GetACBPtr(GetAppHandle()));
}

naked inline void SevenSeg(register int val) __attribute__(__no_temps)
{
	__asm {
		stt		$a0,$FFFFFFFFFFDC0080
	}
}

naked inline void SetLEDS(register int val)
{
  __asm {
    stb   $a0,$FFFFFFFFFFDC0600
  }
}

// ----------------------------------------------------------------------------
// SetImLevel will only set the interrupt mask level to level higher than the
// current one.
//
// Returns:
//		int	- the previous interrupt level setting
// ----------------------------------------------------------------------------

int SetImLevel(register int level)
{
	int x;

	if ((x = GetImLevel()) >= level)
		return (x);
	__asm {
		csrrw	r1,#$044,$x0		// read machine status register #$044
		and		r1,r1,#$FFFFFFFFFFFFFFF0
		and		r18,r18,#15
		or		r1,r1,r18			// insert the desired level in the im bits
		csrrw	r1,#$044,r1		// and update the status reg
		and		r1,r1,#15			// return only the im bits
		// The following safety ramp is present because the interrupt level
		// won't be set for a few machine cycles after the instruction to 
		// set the level is fetched. An interrupt still might occur and
		// be recognized after the CSR is set. It takes a few cycles for
		// the setting to take effect.
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
	}
}

naked int LockIOFSemaphore(register int retries)
{
	__asm {
.loop:
		ldi		$a1,#8
		csrrs	$a1,#12,$a1
		lsr		$a1,$a1,#3	// extract the previous lock status
		and		$a1,$a1,#1
		xor		$a1,$a1,#1	// return true if semaphore wasn't locked
		bnez	$a1,.xit
		sub		$a0,$a0,#1
		bnez	$a0,.loop
		// $a1 = 0
.xit:
		ret
	}
}

naked int LockKbdSemaphore(register int retries)
{
	__asm {
.loop:
		ldi		$a1,#16
		csrrs	$a1,#12,$a1
		lsr		$a1,$a1,#4	// extract the previous lock status
		and		$a1,$a1,#1
		xor		$a1,$a1,#1	// return true if semaphore wasn't locked
		bnez	$a1,.xit
		sub		$a0,$a0,#1
		bnez	$a0,.loop
		// $a1 = 0
.xit:
		ret
	}
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
/*
naked void FMTK_IRQDispatch()
{
	__asm {
		jmp		_FMTK_IRQDispatch2
	}
}

naked void FMTK_IRQDispatch2()
{
	__asm {
		csrrd	r1,#6,r0	// get the cause code
		shl		r1,r1,#3
		lw		r1,_interrupt_table[r1]
		jmp		[r1]
	}
}
*/
naked inline int GetEpc()
{
	__asm { 
		csrrw	$a0,#$48,$x0
	}
}
naked inline int SetEpc(register int v)	
{
	__asm {
		csrrw	$a0,#$48,$a0
	}
}
naked inline int SetTCB(register int tcb)
{
	__asm {
		csrrw		$a0,#$10,$a0
	}	
}

naked inline int GetKeys1() { __asm { csrrw $a0,#$00E,$x0 }}
naked inline int GetKeys2() { __asm { csrrw $a0,#$00F,$x0 }}
naked inline int SetKeys1(register int k) { __asm { csrrw $a0,#$00E,$a0 }}
naked inline int SetKeys2(register int k) { __asm { csrrw $a0,#$00F,$a0 }}

// ----------------------------------------------------------------------------
// Select a task to run.
// ----------------------------------------------------------------------------

private const __int8 startQ[32] = { 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 1, 0, 4, 0, 0, 0, 5, 0, 0, 0, 6, 0, 1, 0, 7, 0, 0, 0, 0 };
private __int16 startQNdx;

private hTCB SelectTaskToRun()
{
	int nn,kk;
	TCB *p, *q;
	int qToCheck;
  hTCB h;
 
	startQNdx++;
	startQNdx &= 31;
	qToCheck = startQ[startQNdx];
	qToCheck &= 7;
	for (nn = 0; nn < 8; nn++) {
		h = readyQ[qToCheck];
		if (h >= 0 && h < NR_TCB) {
			p = &tcbs[h];
      kk = 0;
      // Can run the head of a lower Q level if it's not the running
      // task, otherwise look to the next task.
      if (h != GetRunningTCB())
     		q = p;
			else
     		q = &tcbs[p->next];
      do {  
        if (!(q->status & TS_RUNNING)) {
          if (q->affinity == getCPU()) {
				  	readyQ[qToCheck] = q - tcbs;
				   	return (q - tcbs);
          }
        }
        q = &tcbs[q->next];
        kk = kk + 1;
      } while (q != p && kk < NR_TCB);
    }
		qToCheck++;
		qToCheck &= 7;
	}
	return (GetRunningTCB());
	panic("No entries in ready queue.");
}

// ----------------------------------------------------------------------------
// There isn't any 'C' code in the SystemCall() function. If there were it
// would have to be arranged like the TimerIRQ() or RescheduleIRQ() functions.
//
// All rescheduling of tasks (task switching) is handled by the TimerIRQ() or
// RescheduleIRQ() functions. Calling a system function does not directly 
// change tasks so there's no reason to save/restore many of the control
// registers that need to be saved and restored by a task switch.
//
// Parameters to the system function are passed in registers r44 to r49.
// ----------------------------------------------------------------------------

naked FMTK_SystemCall()
{
  __asm {
    jmp   _OSECALL
  }
}

// ----------------------------------------------------------------------------
// FMTK primitives need to re-schedule threads in a couple of places.
// ----------------------------------------------------------------------------

void FMTK_Reschedule()
{
  TCB *t, *ot;
   
	ot = t = GetRunningTCBPtr();
	t->endTick = GetTick();
	t->ticks = t->ticks + (t->endTick - t->startTick);

	SetRunningTCBPtr(SelectTaskToRun());
	GetRunningTCBPtr()->status = TS_RUNNING;

	// If an exception was flagged (eg CTRL-C) return to the catch handler
	// not the interrupted code.
	t = GetRunningTCBPtr();
	if (t->exception) {
		t->regs[29] = t->regs[28];   // set link register to catch handler
		t->epc = t->regs[28];        // and the PC register
		t->regs[1] = t->exception;    // r1 = exception value
		t->exception = 0;
		t->regs[2] = 45;              // r2 = exception type
	}
	t->startTick = GetTick();
	if (ot != t)
		SwapContext(ot,t);
}

// ----------------------------------------------------------------------------
// If timer interrupts are enabled during a priority #0 thread, this routine
// only updates the missed ticks and remains in the same thread. No timeouts
// are updated and no thread switches will occur. The timer tick routine
// basically has a fixed latency when priority #0 is present.
// ----------------------------------------------------------------------------

void interrupt FMTK_SchedulerIRQ()
{
  TCB *t, *ot;

	ot = t = GetRunningTCBPtr();
	t->endTick = GetTick();
	switch(GetCauseCode()) {
	// Timer tick interrupt
	case 159:
//		AckTimerIRQ();
		if (getCPU()==0) DisplayIRQLive();
		if (LockSysSemaphore(20)) {
			t->ticks = t->ticks + (t->endTick - t->startTick);
			if (t->priority != 000) {
				t->status = TS_PREEMPT;
				while (TimeoutList >= 0 && TimeoutList < NR_TCB) {
					if (tcbs[TimeoutList].timeout<=0)
						InsertIntoReadyList(PopTimeoutList());
					else {
						tcbs[TimeoutList].timeout = tcbs[TimeoutList].timeout - missed_ticks - 1;
						missed_ticks = 0;
						break;
					}
				}
				if (t->priority > 002)
				SetRunningTCBPtr(SelectTaskToRun());
				GetRunningTCBPtr()->status = TS_RUNNING;
			}
			else
				missed_ticks++;
			UnlockSysSemaphore();
		}
		else {
			missed_ticks++;
		}
		break;
	// Explicit rescheduling request.
	case 241:
		t->ticks = t->ticks + (t->endTick - t->startTick);
		t->status = TS_PREEMPT;
//		t->epc = t->epc + 1;  // advance the return address
		SetRunningTCBPtr(SelectTaskToRun());
		GetRunningTCBPtr()->status = TS_RUNNING;
		break;
	default:  ;
	}
	// If an exception was flagged (eg CTRL-C) return to the catch handler
	// not the interrupted code.
	t = GetRunningTCBPtr();
	if (t->exception) {
		t->regs[29] = t->regs[28];   // set link register to catch handler
		t->epc = t->regs[28];        // and the PC register
		t->regs[1] = t->exception;    // r1 = exception value
		t->exception = 0;
		t->regs[2] = 45;              // r2 = exception type
	}
	t->startTick = GetTick();
	if (ot != t)
		SwapContext(ot,t);
}

void panic(char *msg)
{
     putstr(msg);
j1:  goto j1;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void IdleThread()
{
   int ii;
   int *screen = (int *)0xFFFFFFFFFFD00000L;

//     try {
j1:  ;
   forever {
     try {
       ii++;
       if (getCPU()==0) {
         screen[57] = 0xFFFF000F0000L|ii;
			 }
     }
     catch(static __exception ex=0) {
       if (ex&0xFFFFFFFFFFFFFFFFL==515) {
         printf("IdleTask: CTRL-C pressed.\r\n");
       }
       else
         throw ex;
     }
   }
/*
     }
     catch (static __exception ex1=0) {
         printf("IdleTask: exception %d.\r\n", ex1);
         goto j1;
     }
*/
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_KillThread(register int threadno)
{
  hTCB ht, pht;
  hACB hApp;
  int nn;
  ACB *j;

  ht = threadno;
  if (LockSysSemaphore(-1)) {
    RemoveFromReadyList(ht);
    RemoveFromTimeoutList(ht);
    for (nn = 0; nn < 4; nn++)
      if (tcbs[ht].hMailboxes[nn] >= 0 && tcbs[ht].hMailboxes[nn] < NR_MBX) {
        FMTK_FreeMbx(tcbs[ht].hMailboxes[nn]);
        tcbs[ht].hMailboxes[nn] = -1;
      }
    // remove task from job's task list
    hApp = tcbs[ht].hApp;
    j = GetACBPtr(hApp);
    ht = j->thrd;
    if (ht==threadno)
    	j->thrd = tcbs[ht].acbnext;
    else {
    	while (ht >= 0) {
    		pht = ht;
    		ht = tcbs[ht].acbnext;
    		if (ht==threadno) {
    			tcbs[pht].acbnext = tcbs[ht].acbnext;
    			break;
    		}
    	}
    }
		tcbs[ht].acbnext = -1;
    // If the job no longer has any threads associated with it, it is 
    // finished.
    if (j->thrd == -1) {
    	j->magic = 0;
    	mmu_FreeMap(hApp);
    }
    UnlockSysSemaphore();
  }
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_ExitThread()
{
  KillThread(GetRunningTCB());
	// The thread should not return from this reschedule because it's been
	// killed.
	forever {
  	FMTK_Reschedule();
	}
}


// ----------------------------------------------------------------------------
// Returns:
//	hTCB	positive number handle of thread started,
//			or negative number error code
// ----------------------------------------------------------------------------

int FMTK_StartThread(
	register int *StartAddr,
	register int stacksize,
	register int *pStack,
	register int parm,
	register int info
)
{
  hTCB ht;
  TCB *t;
  int nn;
  __int32 affinity;
	hACB hApp;
	__int8 priority;

  SetLEDS(60);

	// These fields extracted from a single parameter as there can be only
	// five register values passed to the function.	
  affinity = info & 0xffffffffL;
	hApp = (info >> 32) & 0xffffL;
	priority = (info >> 48) & 0xff;

  if (LockSysSemaphore(100000)) {
    SetLEDS(61);
    ht = freeTCB;
    if (ht < 0 || ht >= NR_TCB) {
      UnlockSysSemaphore();
    	return (E_NoMoreTCBs);
    }
    freeTCB = tcbs[ht].next;
    UnlockSysSemaphore();
  }
	else {
    SetLEDS(69);
		return (E_Busy);
	}
  SetLEDS(62);
  t = &tcbs[ht];
  t->affinity = affinity;
  t->priority = priority;
  t->hApp = hApp;
  // Insert into the job's list of tasks.
    SetLEDS(63);
  tcbs[ht].acbnext = ACBPtrs[hApp]->thrd;
  ACBPtrs[hApp]->thrd = ht;
  t->regs[1] = parm;
  t->regs[28] = FMTK_ExitThread;
  t->regs[31] = (int)pStack + stacksize - 2048;
  t->bios_stack = (int)pStack + stacksize - 8;
  t->sys_stack = (int)pStack + stacksize - 1024;
  t->epc = StartAddr;
  t->cr0 = 0x140000000L;				// enable data cache and branch predictor
  t->startTick = GetTick();
  t->endTick = GetTick();
  t->ticks = 0;
  t->exception = 0;
  SetLEDS(65);
  if (LockSysSemaphore(100000)) {
      InsertIntoReadyList(ht);
      UnlockSysSemaphore();
  }
	else {
		return (E_Busy);
	}
  SetLEDS(67);
  return (ht);
}

// ----------------------------------------------------------------------------
// Sleep for a number of clock ticks.
// ----------------------------------------------------------------------------

int FMTK_Sleep(register int timeout)
{
  hTCB ht;
  int tick1, tick2;

	while (timeout > 0) {
		tick1 = GetTick();
    if (LockSysSemaphore(100000)) {
      ht = GetRunningTCB();
      RemoveFromReadyList(ht);
      InsertIntoTimeoutList(ht, timeout);
      UnlockSysSemaphore();
			FMTK_Reschedule();
      break;
    }
		else {
			tick2 = GetTick();
			timeout -= (tick2-tick1);
		}
	}
  return (E_Ok);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_SetTaskPriority(register hTCB ht, register int priority)
{
  TCB *t;

  if (priority > 077 || priority < 000)
   return (E_Arg);
  if (LockSysSemaphore(-1)) {
    t = &tcbs[ht];
    t->priority = priority;
    UnlockSysSemaphore();
  }
  return (E_Ok);
}

// ----------------------------------------------------------------------------
// Initialize FMTK global variables.
// ----------------------------------------------------------------------------

void FMTKInit()
{
	int nn,jj;

//    firstcall
  {
    SetLEDS(20);
    hasUltraHighPriorityTasks = 0;
    missed_ticks = 0;

    IOFocusTbl[0] = 0;
    IOFocusNdx = null;
    iof_switch = 0;
    hSearchApp = 0;
    hFreeApp = -1;

		SetRunningTCBPtr(0);
    im_save = 7;
    UnlockSysSemaphore();
    UnlockIOFSemaphore();
    UnlockKbdSemaphore();

		// Setting up message array
    for (nn = 0; nn < NR_MSG; nn++) {
      message[nn].link = nn+1;
    }
    message[NR_MSG-1].link = -1;
    freeMSG = 0;

    SetLEDS(30);

  	for (nn = 0; nn < 8; nn++)
  		readyQ[nn] = -1;
  	for (nn = 0; nn < NR_TCB; nn++) {
      tcbs[nn].number = nn;
      tcbs[nn].acbnext = -1;
  		tcbs[nn].next = nn+1;
  		tcbs[nn].prev = -1;
  		tcbs[nn].status = 0;
  		tcbs[nn].priority = 070;
  		tcbs[nn].affinity = 0;
  		tcbs[nn].hApp = 0;
  		tcbs[nn].timeout = 0;
  		tcbs[nn].hMailboxes[0] = -1;
  		tcbs[nn].hMailboxes[1] = -1;
  		tcbs[nn].hMailboxes[2] = -1;
  		tcbs[nn].hMailboxes[3] = -1;
  		if (nn<2) {
        tcbs[nn].affinity = nn;
        tcbs[nn].priority = 030;
      }
      tcbs[nn].exception = 0;
  	}
  	tcbs[NR_TCB-1].next = -1;
  	freeTCB = 2;
    SetLEDS(42);

  	TimeoutList = -1;

    SetLEDS(40);
/*
    	InsertIntoReadyList(0);
    	InsertIntoReadyList(1);
    	tcbs[0].status = TS_RUNNING;
    	tcbs[1].status = TS_RUNNING;
        asm {
            ldi   r1,#44
            sb    r1,$FFDC0600
        }
*/
//		SetVBA(FMTK_IRQDispatch);
//    	set_vector(4,(unsigned int)FMTK_SystemCall);
//    	set_vector(2,(unsigned int)FMTK_SchedulerIRQ);
		hKeybdMbx = -1;
		hFocusSwitchMbx = -1;
    SetLEDS(45);
  	FMTK_Inited = 0x12345678;
    SetLEDS(50);
    SetupDevices();
  }
}

