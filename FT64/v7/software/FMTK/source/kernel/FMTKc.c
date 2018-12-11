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
#include "config.h"
#include "const.h"
#include "types.h"
#include "proto.h"
#include "glo.h"
#include "TCB.h"

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

// This table needed in case we want to call the OS routines directly.
// It is also used by the system call interrupt as a vector table.
naked void FMTK_FuncTbl()
{
  __asm {
  	align	8
    dw  _FMTK_Initialize
    dw  _FMTK_StartThread
    dw  _FMTK_ExitThread
    dw  _FMTK_KillThread
    dw  _FMTK_SetThreadPriority
    dw  _FMTK_Sleep
    dw  _FMTK_AllocMbx
    dw  _FMTK_FreeMbx
    dw  _FMTK_PostMsg
    dw  _FMTK_SendMsg
    dw  _FMTK_WaitMsg
    dw  _FMTK_CheckMsg
    dw  _FMTK_StartApp
  }
}

naked inline int GetCauseCode()
{
  __asm {
		csrrd	r1,#6,r0
  }
}

naked inline int GetTick()
{
	__asm	{
		csrrd	r1,#2,r0
	}
}

naked inline void SetR1(register int t)
{
	__asm {
		mov		r1,r18
	}
}

naked inline void SetSP(register int *t)
{
	__asm {
		mov		sp,r18
	}
}

naked inline void AckTimerIRQ()
{
  __asm {
    ld		r3,#3				; reset the edge sense circuit
    sh		r3,PIC_ESR
  }
}

naked void DisplayIRQLive()
{
   __asm {
     lhu      r1,$FFD00000+440
     addi     r1,r1,#1
     sh       r1,$FFD00000+440
     ret
   }
}

inline TCB *GetRunningTCBPtr()
{
	__asm {
		csrrd	r1,#$10,r0
	}
}

inline TCB *SetRunningTCBPtr(register int ptr)
{
	__asm {
		csrrw	r1,#$10,r18
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
		sh		r18,$FFFFFFFFFFDC0080
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
		csrrd	r1,#$044,r0		// read machine status register #$044
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

// ----------------------------------------------------------------------------
// Semaphore lock/unlock code.
// ----------------------------------------------------------------------------

naked int LockSysSemaphore(register int retries)
{
	__asm {
		ldi		r1,#15		// set interrupt mask level fifteen
		csrrs	r1,#$044,r1	// disable all interrupts
		sw		r1,_im_save	// save off old setting
		mov		r2,r18
.loop:
		ldi		r1,#4
		csrrs	r1,#12,r1
		shr		r1,r1,#2	// extract the previous lock status
		and		r1,r1,#1
		xor		r1,r1,#1	// return true if semaphore wasn't locked
		bne		r1,r0,.xit
		sub		r2,r2,#1
		bne		r2,r0,.loop
		// r1 = 0
.xit:
		ret
	}
}

naked void UnlockSysSemaphore()
{
	__asm {
		ldi		r1,#4
		csrrc	r0,#12,r1
		// restore the previous interrupt mask setting
		lw		r1,_im_save	
		sei		r1
	}
}


naked int LockIOFSemaphore(register int retries)
{
	__asm {
		mov		r2,r18
.loop:
		ldi		r1,#8
		csrrs	r1,#12,r1
		shr		r1,r1,#3	// extract the previous lock status
		and		r1,r1,#1
		xor		r1,r1,#1	// return true if semaphore wasn't locked
		bne		r1,r0,.xit
		sub		r2,r2,#1
		bne		r2,r0,.loop
		// r1 = 0
.xit:
		ret
	}
}

naked int LockKbdSemaphore(register int retries)
{
	__asm {
		mov		r2,r18
.loop:
		ldi		r1,#16
		csrrs	r1,#12,r1
		shr		r1,r1,#4	// extract the previous lock status
		and		r1,r1,#1
		xor		r1,r1,#1	// return true if semaphore wasn't locked
		bne		r1,r0,.xit
		sub		r2,r2,#1
		bne		r2,r0,.loop
		// r1 = 0
.xit:
		ret
	}
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

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

naked inline int GetRegx1() { __asm {	mov r1,r1:x }}
naked inline int GetRegx2() { __asm {	mov r1,r2:x	}}
naked inline int GetRegx3() { __asm {	mov r1,r3:x	}}
naked inline int GetRegx4() { __asm {	mov r1,r4:x	}}
naked inline int GetRegx5() { __asm {	mov r1,r5:x	}}
naked inline int GetRegx6() { __asm {	mov r1,r6:x	}}
naked inline int GetRegx7() { __asm {	mov r1,r7:x	}}
naked inline int GetRegx8() { __asm {	mov r1,r8:x	}}
naked inline int GetRegx9() { __asm {	mov r1,r9:x	}}
naked inline int GetRegx10() { __asm {	mov r1,r10:x	}}
naked inline int GetRegx11() { __asm {	mov r1,r11:x	}}
naked inline int GetRegx12() { __asm {	mov r1,r12:x	}}
naked inline int GetRegx13() { __asm {	mov r1,r13:x	}}
naked inline int GetRegx14() { __asm {	mov r1,r14:x	}}
naked inline int GetRegx15() { __asm {	mov r1,r15:x	}}
naked inline int GetRegx16() { __asm {	mov r1,r16:x	}}
naked inline int GetRegx17() { __asm {	mov r1,r17:x	}}
naked inline int GetRegx18() { __asm {	mov r1,r18:x	}}
naked inline int GetRegx19() { __asm {	mov r1,r19:x	}}
naked inline int GetRegx20() { __asm {	mov r1,r20:x	}}
naked inline int GetRegx21() { __asm {	mov r1,r21:x	}}
naked inline int GetRegx22() { __asm {	mov r1,r22:x	}}
naked inline int GetRegx23() { __asm {	mov r1,r23:x	}}
naked inline int GetRegx24() { __asm {	mov r1,r24:x	}}
naked inline int GetRegx25() { __asm {	mov r1,r25:x	}}
naked inline int GetRegx26() { __asm {	mov r1,r26:x	}}
naked inline int GetRegx27() { __asm {	mov r1,r27:x	}}
naked inline int GetRegx28() { __asm {	mov r1,r28:x	}}
naked inline int GetRegx29() { __asm {	mov r1,r29:x	}}
naked inline int GetRegx30() { __asm {	mov r1,r30:x	}}
naked inline int GetRegx31() { __asm {	mov r1,r31:x	}}
naked inline int GetEpc()
{
	__asm { 
		csrrd	r1,#$48,r0
	}
}
naked inline int GetTH() {	__asm {	csrrd		$r1,#TH,$r0	} }
naked inline int GetTB() {	__asm {	csrrd		$r1,#TB,$r0	} }
naked inline int GetCL() {	__asm {	csrrd		$r1,#CL,$r0	} }
naked inline int GetCU() {	__asm {	csrrd		$r1,#CU,$r0	} }
naked inline int GetRO() {	__asm {	csrrd		$r1,#RO,$r0	} }
naked inline int GetDL() {	__asm {	csrrd		$r1,#DL,$r0	} }
naked inline int GetDU() {	__asm {	csrrd		$r1,#DU,$r0	} }
naked inline int GetSL() {	__asm {	csrrd		$r1,#SL,$r0	} }
naked inline int GetSU() {	__asm {	csrrd		$r1,#SU,$r0	} }
naked inline int GetWiredRegsets() {	__asm {	csrrd		$r1,#WRS,$r0	} }
naked inline void SetRegx1(register int v) { __asm {	mov	r1:x,r18	}}
naked inline void SetRegx2(register int v) { __asm {	mov	r2:x,r18	}}
naked inline void SetRegx3(register int v) { __asm {	mov	r3:x,r18	}}
naked inline void SetRegx4(register int v) { __asm {	mov	r4:x,r18	}}
naked inline void SetRegx5(register int v) { __asm {	mov	r5:x,r18	}}
naked inline void SetRegx6(register int v) { __asm {	mov	r6:x,r18	}}
naked inline void SetRegx7(register int v) { __asm {	mov	r7:x,r18	}}
naked inline void SetRegx8(register int v) { __asm {	mov	r8:x,r18	}}
naked inline void SetRegx9(register int v) { __asm {	mov	r9:x,r18	}}
naked inline void SetRegx10(register int v) { __asm {	mov	r10:x,r18	}}
naked inline void SetRegx11(register int v) { __asm {	mov	r11:x,r18	}}
naked inline void SetRegx12(register int v) { __asm {	mov	r12:x,r18	}}
naked inline void SetRegx13(register int v) { __asm {	mov	r13:x,r18	}}
naked inline void SetRegx14(register int v) { __asm {	mov	r14:x,r18	}}
naked inline void SetRegx15(register int v) { __asm {	mov	r15:x,r18	}}
naked inline void SetRegx16(register int v) { __asm {	mov	r16:x,r18	}}
naked inline void SetRegx17(register int v) { __asm {	mov	r17:x,r18	}}
naked inline void SetRegx18(register int v) { __asm {	mov	r18:x,r18	}}
naked inline void SetRegx19(register int v) { __asm {	mov	r19:x,r18	}}
naked inline void SetRegx20(register int v) { __asm {	mov	r20:x,r18	}}
naked inline void SetRegx21(register int v) { __asm {	mov	r21:x,r18	}}
naked inline void SetRegx22(register int v) { __asm {	mov	r22:x,r18	}}
naked inline void SetRegx23(register int v) { __asm {	mov	r23:x,r18	}}
naked inline void SetRegx24(register int v) { __asm {	mov	r24:x,r18	}}
naked inline void SetRegx25(register int v) { __asm {	mov	r25:x,r18	}}
naked inline void SetRegx26(register int v) { __asm {	mov	r26:x,r18	}}
naked inline void SetRegx27(register int v) { __asm {	mov	r27:x,r18	}}
naked inline void SetRegx28(register int v) { __asm {	mov	r28:x,r18	}}
naked inline void SetRegx29(register int v) { __asm {	mov	r29:x,r18	}}
naked inline void SetRegx30(register int v) { __asm {	mov	r30:x,r18	}}
naked inline void SetRegx31(register int v) { __asm {	mov	r31:x,r18	}}
naked inline int SetEpc(register int v)	
{
	__asm {
		csrrw	r1,#$48,r18
	}
}
naked inline int SetTH(register int v)
{
	__asm {
		csrrw $r1,#TH,$a0
		sync
	}
}

naked inline int SetRegset(register int rs)
{
	__asm {
		csrrd	$r1,#STATUS,$r0
		and		$r1,$r1,#$FFFFFFFFFFF03FFF
		and		$r2,$a0,#63
		shl		$r2,$r2,#$14
		or		$r1,$r1,$r2
		csrrw	$r1,#STATUS,$r1
		sync
	}
}

naked inline int SetTB(register int v) { __asm { csrrw $r1,#TB,$a0 }}
naked inline int SetCU(register int v) { __asm { csrrw $r1,#CL,$a0 }}
naked inline int SetCL(register int v) { __asm { csrrw $r1,#CU,$a0 }}
naked inline int SetRO(register int v) { __asm { csrrw $r1,#RO,$a0 }}
naked inline int SetDL(register int v) { __asm { csrrw $r1,#DL,$a0 }}
naked inline int SetDU(register int v) { __asm { csrrw $r1,#DU,$a0 }}
naked inline int SetSL(register int v) { __asm { csrrw $r1,#SL,$a0 }}
naked inline int SetSU(register int v) { __asm { csrrw $r1,#SU,$a0 }}

// ----------------------------------------------------------------------------
// Restore the thread's context.
// ----------------------------------------------------------------------------

naked void SwapContext(register TCB *octx, register TCB *nctx)
{
	int n;
	int th;

	// First search and see if the target register set is already present in the 
	// processor. If it is, then just switch register sets. Otherwise evict a
	// register set, and load the register set with the target thread's registers.	
	for (n = 63; n >= 0; n--) {
		SetRegset(n);
		th = GetTH();
		if (th==nctx->number)
			goto j1;
	}
	n = GetWiredRegsets();
	n += GetRand(0);
	n &= 63;
	SetRegset(n);
	octx->tb = GetTB();
	octx->cl = GetCL();
	octx->cu = GetCU();
	octx->ro = GetRO();
	octx->dl = GetDL();
	octx->du = GetDU();
	octx->sl = GetSL();
	octx->su = GetSU();
	octx->regs[1] = GetRegx1();
	octx->regs[2] = GetRegx2();
	octx->regs[3] = GetRegx3();
	octx->regs[4] = GetRegx4();
	octx->regs[5] = GetRegx5();
	octx->regs[6] = GetRegx6();
	octx->regs[7] = GetRegx7();
	octx->regs[8] = GetRegx8();
	octx->regs[9] = GetRegx9();
	octx->regs[10] = GetRegx10();
	octx->regs[11] = GetRegx11();
	octx->regs[12] = GetRegx12();
	octx->regs[13] = GetRegx13();
	octx->regs[14] = GetRegx14();
	octx->regs[15] = GetRegx15();
	octx->regs[16] = GetRegx16();
	octx->regs[17] = GetRegx17();
	octx->regs[18] = GetRegx18();
	octx->regs[19] = GetRegx19();
	octx->regs[20] = GetRegx20();
	octx->regs[21] = GetRegx21();
	octx->regs[22] = GetRegx22();
	octx->regs[23] = GetRegx23();
	octx->regs[24] = GetRegx24();
	octx->regs[25] = GetRegx25();
	octx->regs[26] = GetRegx26();
	octx->regs[27] = GetRegx27();
	octx->regs[28] = GetRegx28();
	octx->regs[29] = GetRegx29();
	octx->regs[30] = GetRegx30();
	octx->regs[31] = GetRegx31();
	SetTH(nctx->number);
	SetTB(nctx->tb);
	SetCL(nctx->cl);
	SetCU(nctx->cu);
	SetRO(nctx->ro);
	SetDL(nctx->dl);
	SetDU(nctx->du);
	SetSL(nctx->sl);
	SetSU(nctx->su);
	SetRegx1(nctx->regs[1]);
	SetRegx2(nctx->regs[2]);
	SetRegx3(nctx->regs[3]);
	SetRegx4(nctx->regs[4]);
	SetRegx5(nctx->regs[5]);
	SetRegx6(nctx->regs[6]);
	SetRegx7(nctx->regs[7]);
	SetRegx8(nctx->regs[8]);
	SetRegx9(nctx->regs[9]);
	SetRegx10(nctx->regs[10]);
	SetRegx11(nctx->regs[11]);
	SetRegx12(nctx->regs[12]);
	SetRegx13(nctx->regs[13]);
	SetRegx14(nctx->regs[14]);
	SetRegx15(nctx->regs[15]);
	SetRegx16(nctx->regs[16]);
	SetRegx17(nctx->regs[17]);
	SetRegx18(nctx->regs[18]);
	SetRegx19(nctx->regs[19]);
	SetRegx20(nctx->regs[20]);
	SetRegx21(nctx->regs[21]);
	SetRegx22(nctx->regs[22]);
	SetRegx23(nctx->regs[23]);
	SetRegx24(nctx->regs[24]);
	SetRegx25(nctx->regs[25]);
	SetRegx26(nctx->regs[26]);
	SetRegx27(nctx->regs[27]);
	SetRegx28(nctx->regs[28]);
	SetRegx29(nctx->regs[29]);
	SetRegx30(nctx->regs[30]);
	SetRegx31(nctx->regs[31]);
j1:
	octx->epc = SetEpc(nctx->epc);
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
    __asm {
    	// Spinlock waiting for system availability.
.0001:
			ldi   r1,#32
		 	csrrs r1,#$0C,r1			// read status bit and set it
		 	bbs   r1,#5,.0001			// if it wasn't already set, okay to process
		 	csrrd	r10,#$48,r0			// get return address into r10
    	lhu   r11,-4[r10]			// get static call number parameter into r11
		 	ldi		r1,#20
		 	bgtu  r11,r1,.bad_callno	// check the call number
		 	// 'C' uses r18 to r22 in order to pass register parameters to a function
		 	// in registers. Copy registers from the exceptioned register set.
		 	mov		r18,r18:x
		 	mov		r19,r19:x
		 	mov		r20,r20:x
		 	mov		r21,r21:x
		 	mov		r22,r22:x
    	shl   r11,r11,#3
		 	lw		r11,_FMTK_FuncTbl[r11]
    	call  [r11]				// do the system function
    	mov		r1:x,r1				// return value in r1
		 	rti		#5
.bad_callno:
      ldi	r1,#E_BadCallno
      mov	r1:x,r1
      rti	#5
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
	register __int32 *StartAddr,
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

  __asm {
    ldi   r1,#60
    sb    r1,$FFFFFFFFFFDC0600
  }

	// These fields extracted from a single parameter as there can be only
	// five register values passed to the function.	
  affinity = info & 0xffffffffL;
	hApp = (info >> 32) & 0xffffL;
	priority = (info >> 48) & 0xff;

  if (LockSysSemaphore(100000)) {
    __asm {
      ldi   r1,#61
      sb    r1,$FFFFFFFFFFDC0600
    }
    ht = freeTCB;
    if (ht < 0 || ht >= NR_TCB) {
      UnlockSysSemaphore();
    	return (E_NoMoreTCBs);
    }
    freeTCB = tcbs[ht].next;
    UnlockSysSemaphore();
  }
	else {
		__asm {
      ldi   r1,#69
      sb    r1,$FFFFFFFFFFDC0600
		}
		return (E_Busy);
	}
  __asm {
    ldi   r1,#62
    sb    r1,$FFDC0600
  }
  t = &tcbs[ht];
  t->affinity = affinity;
  t->priority = priority;
  t->hApp = hApp;
  // Insert into the job's list of tasks.
  __asm {
    ldi   r1,#63
    sb    r1,$FFFFFFFFFFDC0600
  }
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
  __asm {
    ldi   r1,#65
    sb    r1,$FFFFFFFFFFDC0600
  }
  if (LockSysSemaphore(100000)) {
      InsertIntoReadyList(ht);
      UnlockSysSemaphore();
  }
	else {
		return (E_Busy);
	}
  __asm {
    ldi   r1,#67
    sb    r1,$FFFFFFFFFFDC0600
  }
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

int FMTK_SetThreadPriority(register hTCB ht, register int priority)
{
  TCB *t;

  if (priority > 077 || priority < 000)
   return (E_Arg);
  if (LockSysSemaphore(-1)) {
    t = &tcbs[ht];
    if (t->status & (TS_RUNNING | TS_READY)) {
      RemoveFromReadyList(ht);
      t->priority = priority;
      InsertIntoReadyList(ht);
    }
    else
      t->priority = priority;
    UnlockSysSemaphore();
  }
  return (E_Ok);
}

// ----------------------------------------------------------------------------
// Initialize FMTK global variables.
// ----------------------------------------------------------------------------

void FMTK_Initialize()
{
	int nn,jj;

//    firstcall
  {
    __asm {
      ldi   r1,#20
      sb    r1,$FFFFFFFFFFDC0600
    }
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

    __asm {
      ldi   r1,#30
      sb    r1,$FFDC0600
    }

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
    __asm {
      ldi   r1,#42
      sb    r1,$FFFFFFFFFFDC0600
    }

  	TimeoutList = -1;

    __asm {
      ldi   r1,#40
      sb    r1,$FFFFFFFFFFDC0600
    }
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
    __asm {
      ldi   r1,#45
      sb    r1,$FFFFFFFFFFDC0600
    }
  	FMTK_Inited = 0x12345678;
    __asm {
      ldi   r1,#50
      sb    r1,$FFFFFFFFFFDC0600
    }
    SetupDevices();
  }
}

