; ============================================================================
;        __
;   \\__/ o\    (C) 2020  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
;
; This source file is free software: you can redistribute it and/or modify 
; it under the terms of the GNU Lesser General Public License as published 
; by the Free Software Foundation, either version 3 of the License, or     
; (at your option) any later version.                                      
;                                                                          
; This source file is distributed in the hope that it will be useful,      
; but WITHOUT ANY WARRANTY; without even the implied warranty of           
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
; GNU General Public License for more details.                             
;                                                                          
; You should have received a copy of the GNU General Public License        
; along with this program.  If not, see <http://www.gnu.org/licenses/>.    
;
; ============================================================================

QNDX		EQU		$4304
READYQ	EQU		$4308
PIDMAP	EQU		$4310
missed_ticks	equ		$4320
TimeoutList		equ		$4328
Tick		EQU		$4330
SysSema	EQU		$4340
RDYQ0		EQU		$4400
RDYQ1		EQU		$4500
RDYQ2		EQU		$4600
RDYQ3		EQU		$4700
msgs		EQU		$4800
mbxs		EQU		$8800
mbxs_end	EQU	$8A00
FreeMsg	EQU		$8C00

	code
	align	2
OSCallTbl:
	dh		FMTK_Initialize					; 0
	dh		FMTK_StartTask					; 1
	dh		FMTK_ExitTask
	dh		FMTK_KillTask
	dh		FMTK_SetTaskPriority
	dh		FMTK_Sleep							; 5
	dh		FMTK_AllocMbx
	dh		FMTK_FreeMbx
	dh		FMTK_PostMsg
	dh		FMTK_SendMsg
	dh		FMTK_WaitMsg						; 10
	dh		FMTK_PeekMsg
	dh		FMTK_StartApp
	dh		0												; 13
	dh		FMTK_GetCurrentTid
	dh		DumpReadyQueue
	dh		0
	dh		0
	dh		0
	dh		0
	dh		FMTK_HasIOFocus					; 20
	dh		FMTK_SwitchIOFocus			; 21
	dh		FMTK_ReleaseIOFocus			; 22
	dh		FMTK_ForceReleaseIOFocus	; 23
	dh		FMTK_RequestIOFocus			; 24
	dh		0
	dh		FMTK_IO									; 26

qToChk:
	db	0,0,0,2,0,0,4,2
	db	0,0,6,2,0,0,4,2
	db	0,0,0,2,0,0,4,2
	db	0,0,6,2,0,0,4,2

	align	4

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

FMTKInit:
	sw		$x0,QNDX
	sw		$x0,PIDMAP
	sw		$x0,missed_ticks
	ldi		$t0,#-1
	sw		$t0,TimeoutList
	sw		$t0,READYQ
	sw		$t0,READYQ+4
	
	sw		$x0,IOFocusTbl
	sw		$t0,IOFocusNdx
	
	; zero out device function table
	ldi		$t0,#DVF_Base
	ldi		$t1,#32*32
.0003:
	sw		$x0,[$t0]
	add		$t0,$t0,#4
	sub		$t1,$t1,#1
	bgt		$t1,$x0,.0003

	; Initialize mailboxes
	ldi		$t0,#mbxs
	ldi		$t1,#4*32
.0001:
	sw		$x0,[$t0]
	add		$t0,$t0,#4
	sub		$t1,$t1,#1
	bgt		$t1,$x0,.0001

	; Initialize free message list
	ldi		$t0,#msgs
	sw		$t0,FreeMsg
	ldi		$t1,#0
	ldi		$t2,#512
.0002:
	add		$t1,$t1,#1
	sw		$t1,MSG_LINK[$t0]
	add		$t0,$t0,#16
	sub		$t2,$t2,#1
	bgt		$t2,$x0,.0002

	; unlock the system semaphore	
	mUnlockSemaphore(SysSema)
	ret

;------------------------------------------------------------------------------
; Get the task id for the currently running task.
;
; Returns:
;		v0 = task id
;------------------------------------------------------------------------------

GetCurrentTid:
	csrrw	$v0,#$181,$x0				; get current pid
	and		$v0,$v0,#15					; mask off extra bits
	ret

FMTK_GetCurrentTid:
	mGetCurrentTid
	mov		$v1,$v0
	ldi		$v0,#E_Ok
	mtu		$v1,$v1
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Parameters:
;		a0 = task id
;------------------------------------------------------------------------------

MapOSPages:
	ldi			$v0,#OSPAGES	; number of pages pre-mapped
	ldi			$v1,#0
	sll			$v1,$a0,#8		; put ASID in proper spot
.nxt:
	mvmap		$x0,$v1,$v1
	add			$v1,$v1,#1
	sub			$v0,$v0,#1
	bgt			$v0,$x0,.nxt
	ret

;------------------------------------------------------------------------------
; Select the next task to run. The ready queues are searched in a circular
; fashion beginning with the queue identified indirectly by QNDX. There are
; four ready queues to hold tasks of four different priorities. This routine
; dequeues a task from the ready list, then adds it back if it is still ready.
; This takes care of a lot of scenarios. Such as the task no longer being
; ready, or the priority changing.
;
; Parameters:
;		none
; Modifies:
;		v1, t0, t1, t2, t3, t4
;	Returns:
;		v0 = task id of task to run
;------------------------------------------------------------------------------

SelectTaskToRun:
	sub		$sp,$sp,#4					; stack return address
	sw		$ra,[$sp]
	; Pick the first queue to check, occasionally the queue
	; chosen isn't the highest priority one in order to 
	; prevent starvation of lower priority tasks.
	lbu		$v1,QNDX						; get index into que check table
	add		$v1,$v1,#1					; increment it, and limit
	and		$v1,$v1,#31
	sb		$v1,QNDX						; store back
	lbu		$v1,qToChk[$v1]			; assume this will be valid
	ldi		$t2,#4							; 4 queues to check
.nxtQ:
	lh		$v0,READYQ[$v1]			; check queue to see if contains any
	bge		$v0,$x0,.dq					; yes, go dequeue
.0001:
	add		$v1,$v1,#2					; no, advance to next queue
	and		$v1,$v1,#6					; 4 max
	sub		$t2,$t2,#1					;
	bgt		$t2,$x0,.nxtQ				; go back to check next queue
	; Here, nothing else is actually ready to run
	; just go back to what we were doing.
	mGetCurrentTid
	bra		.noTask
.dq:
	ldi		$t3,#MAX_TID				; ensure we have a valid tid
	bleu	$v0,$t3,.goodTid
	; If the tid isn't valid the readyq was screwed up
	ldi		$t3,#-1							; indicate queue empty
	sh		$t3,READYQ[$v1]
	bra		.0001								; and try next queue
.goodTid:
	sll		$t1,$v0,#10
	lh		$t0,TCBNext[$t1]		; update head of ready queue
	sh		$t0,READYQ[$v1]
.noTask:
	lw		$ra,[$sp]						; restore return address
	add		$sp,$sp,#4
	ret

;------------------------------------------------------------------------------
; Swap from outgoing context to incoming context.
;
; Parameters:
;		a0 = pointer to TCB of outgoing context
;		a1 = pointer to TCB of incoming context
;------------------------------------------------------------------------------

SwapContext:
	; Save outgoing register set in TCB
	mfu		$x2,$x1
	sw		$x2,4[$a0]
	mfu		$x2,$x2
	sw		$x2,8[$a0]
	mfu		$x2,$x3
	sw		$x2,12[$a0]
	mfu		$x2,$x4
	sw		$x2,16[$a0]
	mfu		$x2,$x5
	sw		$x2,20[$a0]
	mfu		$x2,$x6
	sw		$x2,24[$a0]
	mfu		$x2,$x7
	sw		$x2,28[$a0]
	mfu		$x2,$x8
	sw		$x2,32[$a0]
	mfu		$x2,$x9
	sw		$x2,36[$a0]
	mfu		$x2,$x10
	sw		$x2,40[$a0]
	mfu		$x2,$x11
	sw		$x2,44[$a0]
	mfu		$x2,$x12
	sw		$x2,48[$a0]
	mfu		$x2,$x13
	sw		$x2,52[$a0]
	mfu		$x2,$x14
	sw		$x2,56[$a0]
	mfu		$x2,$x15
	sw		$x2,60[$a0]
	mfu		$x2,$x16
	sw		$x2,64[$a0]
	mfu		$x2,$x17
	sw		$x2,68[$a0]
	mfu		$x2,$x18
	sw		$x2,72[$a0]
	mfu		$x2,$x19
	sw		$x2,76[$a0]
	mfu		$x2,$x20
	sw		$x2,80[$a0]
	mfu		$x2,$x21
	sw		$x2,84[$a0]
	mfu		$x2,$x22
	sw		$x2,88[$a0]
	mfu		$x2,$x23
	sw		$x2,92[$a0]
	mfu		$x2,$x24
	sw		$x2,96[$a0]
	mfu		$x2,$x25
	sw		$x2,100[$a0]
	mfu		$x2,$x26
	sw		$x2,104[$a0]
	mfu		$x2,$x27
	sw		$x2,108[$a0]
	mfu		$x2,$x28
	sw		$x2,112[$a0]
	mfu		$x2,$x29
	sw		$x2,116[$a0]
	mfu		$x2,$x30
	sw		$x2,120[$a0]
	mfu		$x2,$x31
	sw		$x2,124[$a0]
	csrrw	$x2,#$341,$x0				; save off mepc
	sw		$x2,TCBepc[$a0]
	; Now save off segment registers
	ldi		$t1,#0
.svseg:
	mvseg	$t0,$x0,$t1
	sll		$x2,$t1,#2
	add		$x2,$x2,$a0
	sw		$t0,TCBsegs[$x2]
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.svseg

	; Switch memory maps
	srl		$v0,$a1,#10					; convert pointer to tid
	and		$v0,$v0,#$F					; mask to 16 task
	csrrw	$v1,#$181,$v0				; set ASID
	; User map has now been switched

	; Restore segment register set
	ldi		$t1,#0
.rsseg:
	sll		$x2,$t1,#2
	add		$x2,$x2,$a1
	lw		$t0,TCBsegs[$x2]
	mvseg	$x0,$t0,$t1
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.rsseg

	lw		$x2,TCBepc[$a1]			; restore epc
	csrrw	$x0,#$341,$x2
	; Restore incoming registers
	lw		$x2,4[$a1]
	mtu		$x1,$x2
	lw		$x2,8[$a1]
	mtu		$x2,$x2
	lw		$x2,12[$a1]
	mtu		$x3,$x2
	lw		$x2,16[$a1]
	mtu		$x4,$x2
	lw		$x2,20[$a1]
	mtu		$x5,$x2
	lw		$x2,24[$a1]
	mtu		$x6,$x2
	lw		$x2,28[$a1]
	mtu		$x7,$x2
	lw		$x2,32[$a1]
	mtu		$x8,$x2
	lw		$x2,36[$a1]
	mtu		$x9,$x2
	lw		$x2,40[$a1]
	mtu		$x10,$x2
	lw		$x2,44[$a1]
	mtu		$x11,$x2
	lw		$x2,48[$a1]
	mtu		$x12,$x2
	lw		$x2,52[$a1]
	mtu		$x13,$x2
	lw		$x2,56[$a1]
	mtu		$x14,$x2
	lw		$x2,60[$a1]
	mtu		$x15,$x2
	lw		$x2,64[$a1]
	mtu		$x16,$x2
	lw		$x2,68[$a1]
	mtu		$x17,$x2
	lw		$x2,72[$a1]
	mtu		$x18,$x2
	lw		$x2,76[$a1]
	mtu		$x19,$x2
	lw		$x2,80[$a1]
	mtu		$x20,$x2
	lw		$x2,84[$a1]
	mtu		$x21,$x2
	lw		$x2,88[$a1]
	mtu		$x22,$x2
	lw		$x2,92[$a1]
	mtu		$x23,$x2
	lw		$x2,96[$a1]
	mtu		$x24,$x2
	lw		$x2,100[$a1]
	mtu		$x25,$x2
	lw		$x2,104[$a1]
	mtu		$x26,$x2
	lw		$x2,108[$a1]
	mtu		$x27,$x2
	lw		$x2,112[$a1]
	mtu		$x28,$x2
	lw		$x2,116[$a1]
	mtu		$x29,$x2
	lw		$x2,120[$a1]
	mtu		$x30,$x2
	lw		$x2,124[$a1]
	mtu		$x31,$x2
	ret

;------------------------------------------------------------------------------
; Operating system call dispatcher.
;------------------------------------------------------------------------------

OSCALL:
	ldi		$sp,#$80000-4		; setup machine mode stack pointer
	mfu		$a0,$a0
	mfu		$a1,$a1
	mfu		$a2,$a2
	mfu		$a3,$a3
	mfu		$a4,$a4
	mfu		$a5,$a5
	and		$a0,$a0,#31
	sll		$a0,$a0,#1
	lhu		$t0,OSCallTbl[$a0]
	or		$t0,$t0,#$FFFC0000
	jmp		[$t0]

;------------------------------------------------------------------------------
; Time accounting.
; Update the length of time the task has been running.
;
; Parameters:
;		s1 = pointer to TCB
; Modifies:
;		t2,t3,t4,t5
;------------------------------------------------------------------------------

AccountTime:
.again:
;	csrrw	$t3,#$741,$x0					; get high time
;	csrrw	$t2,#$701,$x0					; get low time
;	csrrw	$t4,#$741,$x0
;	bne		$t3,$t4,.again
	lw		$t2,Tick
	sw		$t2,TCBEndTick[$s1]
	lw		$t3,TCBStartTick[$s1]
	sub		$t4,$t2,$t3						; end - start
	lw		$t5,TCBTicks[$s1]
	add		$t5,$t5,$t4						; ticks + (end - start)
	sw		$t5,TCBTicks[$s1]
	ret

;------------------------------------------------------------------------------
; Sleep for a number of ticks. Tick interval determined by the VIA timer #3.
; Passing a time of zero or less causes the function to return right away.
;
; Parameters:
;		a1 = length of time to sleep (must be >= 0)
; Returns:
;		none
;------------------------------------------------------------------------------

FMTK_Sleep:
	blt		$a1,$x0,ERETx
	mGetCurrentTid
	sll		$s1,$v0,#10
	beq		$a1,$x0,.0001
	mov		$a0,$v0								; a0 = current tid
	call	RemoveFromReadyList
	call	InsertIntoTimeoutList	; a1 = timeout
.0001:
	lbu		$v0,TCBStatus[$s1]		; flag task as no longer running
	and		$v0,$v0,#~TS_RUNNING
	sb		$v0,TCBStatus[$s1]

	call	AccountTime						; uses s1
	call	SelectTaskToRun

	sll		$s2,$v0,#10						; s2 = pointer to incoming TCB
	lbu		$x2,TCBStatus[$s2]		; x2 = incoming status
	or		$t2,$x2,#TS_RUNNING|TS_READY	; set status = running
	lw		$x2,TCBException[$s2]	;
	beq		$x2,$x0,.noException
	; set link register to catch handler address
	;{
	;	t->regs[29] = t->regs[28];   // set link register to catch handler
	;	t->epc = t->regs[28];        // and the PC register
	;	t->regs[1] = t->exception;    // r1 = exception value
	;	t->exception = 0;
	;	t->regs[2] = 45;              // r2 = exception type
	;}
	sw		$x2,4[$s2]						; r1 = exception
	sw		$x0,TCBException[$s2]	; tcb->exception = 0
	ldi		$x2,#45
	sw		$x2,8[$s2]						; r2 = 45
.noException:

	; If a message is ready, update status to ready and put
	; message in target memory. The task will be returning
	; from a WaitMsg so a return status of E_Ok is also set.
	and		$x2,$t2,#TS_MSGRDY
	beq		$x2,$x0,.noMsg
	lw		$a0,80[$s2]					; user a2 (x20)
	beq		$a0,$x0,.0002
	call	VirtToPhys
	lw		$x2,TCBMsgD1[$s2]
	sw		$x2,[$v0]
.0002:
	lw		$a0,84[$s2]
	beq		$a0,$x0,.0003
	call	VirtToPhys
	lw		$x2,TCBMsgD2[$s2]
	sw		$x2,[$v0]
.0003:
	lw		$a0,88[$s2]
	beq		$a0,$x0,.0004
	call	VirtToPhys
	lw		$x2,TCBMsgD3[$s2]
	sw		$x2,[$v0]
.0004:
	ldi		$x2,#E_Ok						; setup to return E_Ok
	sw		$x2,64[$s2]					; in v0

.noMsg:
	and		$t2,$t2,#~TS_MSGRDY		; mask out message ready status
	sb		$t2,TCBStatus[$s2]
	beq		$s1,$s2,.noCtxSwitch	; incoming and outgoing contexts the same?
	mov		$a0,$s1
	mov		$a1,$s2
	call	SwapContext
.noCtxSwitch:
	lw		$t2,Tick						; get tick
	sw		$t2,TCBStartTick[$s1]
ERETx:
	eret

;------------------------------------------------------------------------------
; SchedulerIRQ meant to be called from the timer ISR.
;------------------------------------------------------------------------------

FMTK_SchedulerIRQ:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	ldi		$a0,#SysSema
	ldi		$a1,#20
	mGetCurrentTid
	sll		$s1,$v0,#10						; compute pointer to TCB
;	call	LockSemaphore
;	beq		$v0,$x0,.noLock
; Might need the following if the external timer isn't used.
;	csrrw	$v0,#$701,$x0					; get the time
;	add		$v0,$v0,#600000				; wait 600,000 cycles @20MHz (30ms)
;	csrrw	$x0,#$321,$v0					; set next interrupt time
	lw		$t5,Tick							; update tick count
	add		$t5,$t5,#1
	sw		$t5,Tick
	call	AccountTime
	lbu		$t5,TCBStatus[$s1]
	or		$t5,$t5,#TS_PREEMPT
	and		$t5,$t5,#~TS_RUNNING	; no longer running, but may still be ready
	sb		$t5,TCBStatus[$s1]
	; Keep popping the timeout list as long as there are tasks on it with
	; expired timeouts.
.0001:
	lh		$t5,TimeoutList
	blt		$t5,$x0,.noTimeouts
	ldi		$t4,#NR_TCB
	bge		$t5,$t4,.noTimeouts
	sll		$t4,$t5,#10					; index to pointer
	lw		$t3,TCBTimeout[$t4]
	bgt		$t3,$x0,.timeoutNotDone
	mPopTimeoutList
	mov		$a0,$v0
	call	InsertIntoReadyList
	bra		.0001
.timeoutNotDone:
	sub		$t3,$t3,#1
	lw		$t2,missed_ticks
	sub		$t3,$t3,$t2
	sw		$t3,TCBTimeout[$t4]
	sw		$x0,missed_ticks
.noTimeouts:
	; The ready queue was just updated, there could be new tasks
	; ready to run.
	call	SelectTaskToRun

	sll		$s2,$v0,#10					; s2 = pointer to incoming TCB
	lbu		$x2,TCBStatus[$s2]	; x2 = incoming status
	or		$t2,$x2,#TS_RUNNING|TS_READY	; status = running
	lw		$x2,TCBException[$s2]	;
	beq		$x2,$x0,.noException
	; set link register to catch handler address
	;{
	;	t->regs[29] = t->regs[28];   // set link register to catch handler
	;	t->epc = t->regs[28];        // and the PC register
	;	t->regs[1] = t->exception;    // r1 = exception value
	;	t->exception = 0;
	;	t->regs[2] = 45;              // r2 = exception type
	;}
.noException:

	; If a message is ready, update status to ready and put
	; message in target memory. The task will be returning
	; from a WaitMsg so a return status of E_Ok is also set.
	bra		.noMsg
	and		$x2,$t2,#TS_MSGRDY
	beq		$x2,$x0,.noMsg
	lw		$a0,80[$s2]					; user a2 (x20)
	beq		$a0,$x0,.0002
	call	VirtToPhys
	lw		$x2,TCBMsgD1[$s2]
	sw		$x2,[$v0]
.0002:
	lw		$a0,84[$s2]
	beq		$a0,$x0,.0003
	call	VirtToPhys
	lw		$x2,TCBMsgD2[$s2]
	sw		$x2,[$v0]
.0003:
	lw		$a0,88[$s2]
	beq		$a0,$x0,.0004
	call	VirtToPhys
	lw		$x2,TCBMsgD3[$s2]
	sw		$x2,[$v0]
.0004:
	ldi		$x2,#E_Ok						; setup to return E_Ok
	sw		$x2,64[$s2]					; in v0

.noMsg:
	and		$t2,$t2,#~TS_MSGRDY		; mask out message ready status
	sb		$t2,TCBStatus[$s2]
	beq		$s1,$s2,.noCtxSwitch
	mov		$a0,$s1
	mov		$a1,$s2
	call	SwapContext
.noCtxSwitch:
	mUnlockSemaphore(SysSema)
.noLock:
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	lw		$t2,Tick					; get tick
	sw		$t2,TCBStartTick[$s1]
	ret

;------------------------------------------------------------------------------
; Start a task.
;	Task status is set to ready, priority normal, and the task is inserted into
; the ready queue. Segment registers are setup for a flat memory model.
; 
;	Parameters:
;		a1 = memory required
;		a2 = start pc (usually $100)
;	Modifies:
;		a0 = tid
;	Returns:
;		v0 = E_Ok if successful
;		v1 = tid of started task if successful
;------------------------------------------------------------------------------
;
FMTK_StartTask:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	call	AllocTCB
	sb		$v1,$4321
	bne		$v0,$x0,.err
	mov		$a0,$v1
	call	MapOSPages			; Map OS pages into address space
	sll		$s1,$a0,#10			; compute TCB address
	call	AllocStack
	ldi		$t0,#$7F800			; set stack pointer
	sw		$t0,56[$s1]
	sw		$a2,TCBepc[$s1]	; address task will begin at
	call	Alloc
	sb		$v0,$4320
	bne		$v0,$x0,.err
	ldi		$t0,#TS_READY
	sb		$t0,TCBStatus[$s1]
	ldi		$t0,#2					; normal execution priority
	sb		$t0,TCBPriority[$s1]
	; leave segment base at $0, flat memory model
	ldi		$t0,#6							; read,write
	sw		$t0,TCBsegs[$s1]			; segs 0 to 11
	sw		$t0,TCBsegs+4[$s1]
	sw		$t0,TCBsegs+8[$s1]
	sw		$t0,TCBsegs+12[$s1]
	sw		$t0,TCBsegs+16[$s1]
	sw		$t0,TCBsegs+20[$s1]
	sw		$t0,TCBsegs+24[$s1]
	sw		$t0,TCBsegs+28[$s1]
	sw		$t0,TCBsegs+32[$s1]
	sw		$t0,TCBsegs+36[$s1]
	sw		$t0,TCBsegs+40[$s1]
	sw		$t0,TCBsegs+44[$s1]
	ldi		$t0,#5							; read,execute
	sw		$t0,TCBsegs+48[$s1]	; segs 12 to 15
	sw		$t0,TCBsegs+52[$s1]
	sw		$t0,TCBsegs+56[$s1]
	sw		$t0,TCBsegs+60[$s1]
	srl		$a0,$s1,#10					; need the tid again
	call	InsertIntoReadyList
	mov		v1,a0
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	mtu		$v0,$v0
	mtu		$v1,$v1
	eret
.err:
;	mov		$a0,$v0
;	call	PutHexByte
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Exit the current task.
;
; Parameters:
;		none
; Modifies:
;		a1 = task id
;------------------------------------------------------------------------------

FMTK_ExitTask:
	mGetCurrentTid
	mov		a1,v0
	; fall through to KillTask
	
;------------------------------------------------------------------------------
; Parameters:
;		a1 = tid of task to kill
;------------------------------------------------------------------------------

FMTK_KillTask:
	beq		$a1,$x0,.immortal		; tid #0 is immortal (the system)
	ldi		$t0,#TS_DEAD				; flag task as dead (prevents it from being re-queued)
	and		$t1,$a1,#15					; limit pid
	sll		$t1,$t1,#10					; convert to TCB address
	sb		$t0,TCBStatus[$t1]
	mov		a0,a1								; a0 = pid
	call	FreeAll							; free all the memory associated with the task
	; Now make process ID available for reuse
	lhu		$t1,PIDMAP
	ldi		$t0,#1							; generate bit "off" mask
	sll		$t0,$t0,$a1
	xor		$t0,$t0,#-1					; complment for inverted mask
	and		$t1,$t1,$t0
	sh		$t1,PIDMAP
.immortal:
	eret

	