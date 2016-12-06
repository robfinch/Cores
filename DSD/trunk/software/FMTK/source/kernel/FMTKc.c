// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
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

extern int shell();

//int interrupt_table[512];
int irq_stack[512];
int sp_tmp;
int FMTK_Inited;
JCB jcbs[NR_JCB];
extern TCB tcbs[NR_TCB];
extern hTCB readyQ[8];
int sysstack[1024];
int stacks[NR_TCB][1024];
int sys_stacks[NR_TCB][512];
int bios_stacks[NR_TCB][512];
int fmtk_irq_stack[512];
int fmtk_sys_stack[512];
MBX mailbox[NR_MBX];
MSG message[NR_MSG];
int nMsgBlk;
int nMailbox;
hJCB freeJCB;
hMSG freeMSG;
hMBX freeMBX;
JCB *IOFocusNdx;
int IOFocusTbl[4];
int iof_switch;
int BIOS1_sema;
extern int iof_sema;
extern int sys_sema;
int BIOS_RespMbx;
char hasUltraHighPriorityTasks;
int missed_ticks;

short int video_bufs[NR_JCB][4096];
extern hTCB TimeoutList;

extern void gfx_demo();

// This table needed in case we want to call the OS routines directly.
// It is also used by the system call interrupt as a vector table.

naked void FMTK_FuncTbl()
{
      asm {
          dw  _FMTKInitialize
          dw  _FMTK_StartTask
          dw  _FMTK_ExitTask
          dw  _FMTK_KillTask
          dw  _FMTK_SetTaskPriority
          dw  _FMTK_Sleep
          dw  _FMTK_AllocMbx
          dw  _FMTK_FreeMbx
          dw  _FMTK_PostMsg
          dw  _FMTK_SendMsg
          dw  _FMTK_WaitMsg
          dw  _FMTK_CheckMsg
      }
}

naked inline int GetCauseCode()
{
    asm {
		csrrw	r1,#6,r0
    }
}

naked inline int GetTick()
{
	asm	{
		csrrw	r1,#2,r0
	}
}

naked inline void SetR1(register int t)
{
	asm {
		mov		r1,r18
	}
}

naked inline void SetSP(register int *t)
{
	asm {
		mov		sp,r18
	}
}

naked inline void AckTimerIRQ()
{
    asm {
        ld		r3,#3				; reset the edge sense circuit
        sw		r3,PIC_ESR
    }
}

naked void DisplayIRQLive()
{
     asm {
         lw       r1,$FFD00000+220
         addi     r1,r1,#1
         sw       r1,$FFD00000+220
         ret
     }
}

JCB *GetJCBPtr()
{
    return &jcbs[GetRunningTCBPtr()->hJob];
}

naked inline void SevenSeg(register int val) __attribute__(__no_temps)
{
	asm {
		sw	r18,$FFDC0080
	}
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

naked void FMTK_IRQDispatch()
{
	asm {
		jmp		_FMTK_IRQDispatch2
	}
}

naked void FMTK_IRQDispatch2()
{
	asm {
		csrrw	r1,#6,r0	// get the cause code
		shl		r1,r1,#1
		lw		r1,interrupt_table[r1]
		jmp		[r1]
	}
}

// ----------------------------------------------------------------------------
// Save the task's context. Subsequent interrupts are enabled in case the
// system function takes a long time to execute.
// ----------------------------------------------------------------------------

naked void SaveContext()
{
	asm {
		csrrw	r1,#$10,r0	// get pointer to TCB
		csrrw	r2,#$40,r0	// EPC
		sw		r2,74[r1]
		csrrw	r2,#$41,r0	// save sp
		sw		r2,62[r1]
		csrrw	r2,#$42,r0	// and r1
		sw		r2,2[r1]
		csrrw	r2,#$43,r0	// and r2
		sw		r2,4[r1]
		ipush
		cli					// now enable interrupts
		sw		r3,6[r1]
		sw		r4,8[r1]
		sw		r5,10[r1]
		sw		r6,12[r1]
		sw		r7,14[r1]
		sw		r8,16[r1]
		sw		r9,18[r1]
		sw		r10,20[r1]
		sw		r11,22[r1]
		sw		r12,24[r1]
		sw		r13,26[r1]
		sw		r14,28[r1]
		sw		r15,30[r1]
		sw		r16,32[r1]
		sw		r17,34[r1]
		sw		r18,36[r1]
		sw		r19,38[r1]
		sw		r20,40[r1]
		sw		r21,42[r1]
		sw		r22,44[r1]
		sw		r23,46[r1]
		sw		r24,48[r1]
		sw		r25,50[r1]
		sw		r26,52[r1]
		sw		r27,54[r1]
		sw		r28,56[r1]
		sw		r29,58[r1]
		sw		r30,60[r1]
		ret
	}
}

// ----------------------------------------------------------------------------
// Restore the task's context.
// ----------------------------------------------------------------------------

naked void RestoreContext(register TCB *ctx)
{
	asm {
		csrrw	r0,#$10,r18		// set new TCB pointer
		mov		r1,r18
		lw		r2,4[r1]
		lw		r3,6[r1]
		lw		r4,8[r1]
		lw		r5,10[r1]
		lw		r6,12[r1]
		lw		r7,14[r1]
		lw		r8,16[r1]
		lw		r9,18[r1]
		lw		r10,20[r1]
		lw		r11,22[r1]
		lw		r12,24[r1]
		lw		r13,26[r1]
		lw		r14,28[r1]
		lw		r15,30[r1]
		lw		r16,32[r1]
		lw		r17,34[r1]
		lw		r18,36[r1]
		lw		r19,38[r1]
		lw		r20,40[r1]
		lw		r21,42[r1]
		lw		r22,44[r1]
		lw		r23,46[r1]
		lw		r24,48[r1]
		lw		r25,50[r1]
		lw		r26,52[r1]
		lw		r27,54[r1]
		lw		r28,56[r1]
		lw		r29,58[r1]
		lw		r30,60[r1]
		lw		r31,62[r1]
		ipop					// This might enable or disable interrupts
		lw		r1,2[r1]
		// An IRET will load sp,r1, and r2 from the interrupt stack, we
		// want these to be the value from the TCB
		csrrw	r0,#$41,sp
		csrrw	r0,#$42,r1
		csrrw	r0,#$43,r2
		csrrw	r1,#$10,r0		// Get TCB pointer
		lw		r2,74[r1]
		csrrw	r0,#$40,r2
		iret	sf1				// This will enable interrupts, and allow system calls
	}
}

// ----------------------------------------------------------------------------
// Select a task to run.
// ----------------------------------------------------------------------------

private const __int16 startQ[32] = { 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 1, 0, 4, 0, 0, 0, 5, 0, 0, 0, 6, 0, 1, 0, 7, 0, 0, 0, 0 };
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
// Parameters to the system function are passed in registers r18 to r22.
// ----------------------------------------------------------------------------

naked FMTK_SystemCall()
{
    asm {
		 csrrs  r1,#$0C,#2			// read status bit and set it
		 bbc    r1,#1,.0002			// if it wasn't already set, okay to process
		 csrrw	r1,#$40,r0			// get exceptioned PC
		 add	r1,r1,#1			// increment to skip over static parameter
		 csrrw  r0,#$40,r1			// write it back
		 csrrw  r0,#$42,#E_Busy		// store busy status in ER1 to be returned in r1
		 iret
.0002:
		 ld		sp,#_sysstack+2046	// set stack pointer
		 call	_SaveContext
		 lw		r10,74[r1]			// get return address into r10
    	 lhu    r11,1[r10]			// get static call number parameter into r11
    	 add    r10,r10,#1			// update return address
         sw		r10,74[r1]			// set return address in epc
		 push	r1					// save TCB pointer
		 lw		r1,2[r1]			// get r1 value for system function
		 bgtu   r11,#20,.bad_callno	// check the call number
    	 shl    r11,r11,#1
		 // 'C' uses r18 to r22 in order to pass parameters to a function
		 // in registers.
		 lw		r11,_FMTK_FuncTbl[r11]
    	 call   [r11]				// do the system function
.0001:
		 pop	r18					// get back TCB pointer
		 sw		r1,2[r18]			// store return value in TCB.r1
		 jmp	_RestoreContext[pc]
.bad_callno:
         ldi   r1,#E_BadFuncno
         bra   .0001   
    }
}

// ----------------------------------------------------------------------------
// If timer interrupts are enabled during a priority #0 task, this routine
// only updates the missed ticks and remains in the same task. No timeouts
// are updated and no task switches will occur. The timer tick routine
// basically has a fixed latency when priority #0 is present.
// ----------------------------------------------------------------------------

naked void FMTK_SchedulerIRQ()
{
    TCB *t;

	prolog {
		// Refuse scheduling if already processing somewhere in the system.
		asm {
			csrrs  r1,#$0C,#2			// read status bit and set it
			bbc    r1,#1,.0002			// check bit #1
			iret
.0002:
			ld		sp,#_sysstack+2046
		}
		SaveContext();
	}

	t = GetRunningTCBPtr();
	t->endTick = GetTick();
	switch(GetCauseCode()) {
	// Timer tick interrupt
	case 451:
//		AckTimerIRQ();
		if (getCPU()==0) DisplayIRQLive();
		if (LockSemaphore(&sys_sema,10)) {
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
				SetRunningTCB(SelectTaskToRun());
				GetRunningTCBPtr()->status = TS_RUNNING;
			}
			else
				missed_ticks++;
			UnlockSemaphore(&sys_sema);
		}
		else {
			missed_ticks++;
		}
		break;
	// Explicit rescheduling request.
	case 2:
		t->ticks = t->ticks + (t->endTick - t->startTick);
		t->status = TS_PREEMPT;
		t->ipc = t->ipc + 1;  // advance the return address
		SetRunningTCB(SelectTaskToRun());
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
		t->regs[2] = 24;              // r2 = exception type
	}
	t->startTick = GetTick();
	// RestoreContext() doesn't return to this routine. It returns to whatever
	// address was setup in the TCB. Subsequent register variables restores
	// are not done, but the compiler stills outputs the code. Stack frame
	// cleanup code is omitted because this function was declared naked.
	RestoreContext(t);
}

void panic(char *msg)
{
     putstr(msg);
j1:  goto j1;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void IdleTask()
{
     int ii;
     __int32 *screen = (__int32 *)0xFFD00000;

//     try {
j1:  ;
         forever {
             try {
                 ii++;
                 if (getCPU()==0)
                     screen[57] = ii;
             }
             catch(static __exception ex=0) {
                 if (ex&0xFFFFFFFFL==515) {
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

int FMTK_KillTask(register int taskno)
{
    hTCB ht;
    int nn;
    JCB *j;

    check_privilege();
    ht = taskno;
    if (LockSemaphore(&sys_sema,-1)) {
        RemoveFromReadyList(ht);
        RemoveFromTimeoutList(ht);
        for (nn = 0; nn < 4; nn++)
            if (tcbs[ht].hMailboxes[nn] >= 0 && tcbs[ht].hMailboxes[nn] < NR_MBX) {
                FMTK_FreeMbx(tcbs[ht].hMailboxes[nn]);
                tcbs[ht].hMailboxes[nn] = -1;
            }
        // remove task from job's task list
        j = &jcbs[tcbs[ht].hJob];
        for (nn = 0; nn < 8; nn++) {
            if (j->tasks[nn]==ht)
                j->tasks[nn] = -1;
        }
        // If the job no longer has any tasks associated with it, it is 
        // finished.
        for (nn = 0; nn < 8; nn++)
            if (j->tasks[nn]!=-1)
                break;
        if (nn == 8) {
            j->next = freeJCB;
            freeJCB = j - jcbs;
        }
        UnlockSemaphore(&sys_sema);
    }
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_ExitTask()
{
    check_privilege();
    KillTask(GetRunningTCB());
    asm { int #2 }     // reschedule
j1: goto j1;
}


// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_StartTask(register int priority, register int affinity, register int adr, register int parm, register hJCB job)
{
    hTCB ht;
    TCB *t;
    int nn;

    asm {
        ldi   r1,#60
        sh    r1,$FFDC0600
    }
    check_privilege();
    if (LockSemaphore(&sys_sema,100000)) {
    asm {
        ldi   r1,#61
        sh    r1,$FFDC0600
    }
        ht = freeTCB;
        freeTCB = tcbs[ht].next;
        UnlockSemaphore(&sys_sema);
    }
	else {
		asm {
        ldi   r1,#69
        sh    r1,$FFDC0600
		}
		return (E_Busy);
	}
    asm {
        ldi   r1,#62
        sh    r1,$FFDC0600
    }
    t = &tcbs[ht];
    t->affinity = affinity;
    t->priority = priority;
    t->hJob = job;
    // Insert into the job's list of tasks.
    for (nn = 0; nn < 8; nn++) {
    asm {
        ldi   r1,#63
        sh    r1,$FFDC0600
    }
        if (jcbs[job].tasks[nn]<0) {
            jcbs[job].tasks[nn] = ht;
            break;
        }
    }
    if (nn == 8) {
    asm {
        ldi   r1,#64
        sh    r1,$FFDC0600
    }
        if (LockSemaphore(&sys_sema,100000)) {
            tcbs[ht].next = freeTCB;
            freeTCB = ht;
            UnlockSemaphore(&sys_sema);
        }
		else {
			return (E_Busy);
		}
        return (E_TooManyTasks);
    }
    t->regs[1] = parm;
    t->regs[28] = FMTK_ExitTask;
    t->regs[31] = FMTK_ExitTask;
    t->isp = t->stack + 1023;
    t->ipc = adr|1;   // stay in kernel mode for now
    t->cr0 = 0x140000000L;
    t->startTick = 0;
    t->endTick = 0;
    t->ticks = 0;
    t->exception = 0;
    asm {
        ldi   r1,#65
        sh    r1,$FFDC0600
    }
    if (LockSemaphore(&sys_sema,100000)) {
        InsertIntoReadyList(ht);
        UnlockSemaphore(&sys_sema);
    }
	else {
		return (E_Busy);
	}
    asm {
        ldi   r1,#67
        sh    r1,$FFDC0600
    }
    return (E_Ok);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_Sleep(register int timeout)
{
    hTCB ht;
    
    check_privilege();
    if (LockSemaphore(&sys_sema,100000)) {
        ht = GetRunningTCB();
        RemoveFromReadyList(ht);
        InsertIntoTimeoutList(ht, timeout);
        UnlockSemaphore(&sys_sema);
    }
	else {
		return (E_Busy);
	}
    asm { int #2 }      // reschedule
    return (E_Ok);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int FMTK_SetTaskPriority(register hTCB ht, register int priority)
{
    TCB *t;

    check_privilege();
    if (priority > 077 || priority < 000)
       return E_Arg;
    if (LockSemaphore(&sys_sema,-1)) {
        t = &tcbs[ht];
        if (t->status & (TS_RUNNING | TS_READY)) {
            RemoveFromReadyList(ht);
            t->priority = priority;
            InsertIntoReadyList(ht);
        }
        else
            t->priority = priority;
        UnlockSemaphore(&sys_sema);
    }
    return (E_Ok);
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

void FMTKInitialize()
{
	int nn,jj;

    check_privilege();
//    firstcall
    {
        asm {
            ldi   r1,#20
            sh    r1,$FFDC0600
        }
        hasUltraHighPriorityTasks = 0;
        missed_ticks = 0;

        IOFocusTbl[0] = 0;
        IOFocusNdx = null;
        iof_switch = 0;

    	SetRunningTCB(0);
        UnlockSemaphore(&sys_sema);
        UnlockSemaphore(&iof_sema);
        UnlockSemaphore(&kbd_sema);

        for (nn = 0; nn < NR_MSG; nn++) {
			SevenSeg(nn);
            message[nn].link = nn+1;
        }
        message[NR_MSG-1].link = -1;
        freeMSG = 0;

        asm {
            ldi   r1,#30
            sh    r1,$FFDC0600
        }

        for (nn = 0; nn < NR_JCB; nn++) {
			SevenSeg(nn);
            jcbs[nn].number = nn;
            for (jj = 0; jj < 8; jj++)
                jcbs[nn].tasks[jj] = -1;
            if (nn == 0 ) {
                jcbs[nn].pVidMem = 0xFFD00000;
                jcbs[nn].pVirtVidMem = video_bufs[nn];
                jcbs[nn].NormAttr = 0x0026B800;
        asm {
            ldi   r1,#31
            sh    r1,$FFDC0600
        }
                RequestIOFocus(&jcbs[0]);
        asm {
            ldi   r1,#32
            sh    r1,$FFDC0600
        }
           }
            else {
                 jcbs[nn].pVidMem = video_bufs[nn];
                 jcbs[nn].pVirtVidMem = video_bufs[nn];
                 jcbs[nn].NormAttr = 0x0026B800;
            }
            jcbs[nn].VideoRows = 31;
            jcbs[nn].VideoCols = 84;
            jcbs[nn].CursorRow = 0;
            jcbs[nn].CursorCol = 0;
            jcbs[nn].KeybdHead = 0;
            jcbs[nn].KeybdTail = 0;
            jcbs[nn].KeyState1 = 0;
            jcbs[nn].KeyState2 = 0;
        }

        asm {
            ldi   r1,#40
            sh    r1,$FFDC0600
        }

    	for (nn = 0; nn < 8; nn++)
    		readyQ[nn] = -1;
    	for (nn = 0; nn < NR_TCB; nn++) {
			SevenSeg(nn);
            tcbs[nn].number = nn;
    		tcbs[nn].next = nn+1;
    		tcbs[nn].prev = -1;
    		tcbs[nn].status = 0;
    		tcbs[nn].priority = 070;
    		tcbs[nn].affinity = 0;
    		tcbs[nn].sys_stack = &sys_stacks[nn] + 511;
    		tcbs[nn].bios_stack = &bios_stacks[nn] + 511;
    		tcbs[nn].stack = &stacks[nn] + 1023;
    		tcbs[nn].hJob = 0;
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
        asm {
            ldi   r1,#42
            sh    r1,$FFDC0600
        }
    	InsertIntoReadyList(0);
    	InsertIntoReadyList(1);
    	tcbs[0].status = TS_RUNNING;
    	tcbs[1].status = TS_RUNNING;
        asm {
            ldi   r1,#44
            sh    r1,$FFDC0600
        }
    	TimeoutList = -1;
//		SetVBA(FMTK_IRQDispatch);
    	set_vector(4,(unsigned int)FMTK_SystemCall);
    	set_vector(2,(unsigned int)FMTK_SchedulerIRQ);
        asm {
            ldi   r1,#45
            sh    r1,$FFDC0600
        }
    	FMTK_StartTask(030, 0, FocusSwitcher, 0, 0);
        asm {
            ldi   r1,#46
            sh    r1,$FFDC0600
        }
    	FMTK_StartTask(033, 0, shell, 0, 1);
        asm {
            ldi   r1,#129
            sh    r1,$FFDC0600
        }
    	FMTK_StartTask(055, 0, gfx_demo, 0, 1);
        asm {
            ldi   r1,#130
            sh    r1,$FFDC0600
        }
        FMTK_StartTask(077, 0, IdleTask, 0, 0);
        asm {
            ldi   r1,#131
            sh    r1,$FFDC0600
        }
        FMTK_StartTask(077, 1, IdleTask, 0, 0);
        asm {
            ldi   r1,#132
            sh    r1,$FFDC0600
        }
    	FMTK_Inited = 0x12345678;
        asm {
            ldi   r1,#50
            sh    r1,$FFDC0600
        }
    }
}

