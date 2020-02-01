
QNDX		EQU		$4304
HRDY0		EQU		$4308
HRDY1		EQU		$4309
HRDY2		EQU		$430A
HRDY3		EQU		$430B
TRDY0		EQU		$430C
TRDY1		EQU		$430D
TRDY2		EQU		$430E
TRDY3		EQU		$430F
PIDMAP	EQU		$4310
missed_ticks	equ		$4320
TimeoutList		equ		$4328
Tick		EQU		$4330
RDYQ0		EQU		$4400
RDYQ1		EQU		$4500
RDYQ2		EQU		$4600
RDYQ3		EQU		$4700

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
	dh		FMTK_Reschedule					; 13
	dh		DumpReadyQueue

qToChk:
	db	0,0,0,1,0,0,2,1
	db	0,0,3,1,0,0,2,1
	db	0,0,0,1,0,0,2,1
	db	0,0,3,1,0,0,2,1

	align	4

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

FMTKInit:
	sw		$x0,QNDX
	sw		$x0,HRDY0				; reset head and tail indexes
	sw		$x0,TRDY0
	sw		$x0,PIDMAP
	sw		$x0,missed_ticks
	ldi		$t0,#-1
	sw		$t0,TimeoutList
	ret

;------------------------------------------------------------------------------
; Get the task id for the currently running task.
;
; Returns:
;		v0 = task id
;------------------------------------------------------------------------------

GetCurrentTid:
	csrrw	$v0,#$300,$x0				; get current pid
	srl		$v0,$v0,#22					; extract field
	and		$v0,$v0,#15					; mask off extra bits
	ret

;------------------------------------------------------------------------------
; Insert task into ready queue
;
; Parameters:
;		a0 = tid to insert
; Modifies:
;		v1,t0,t1
; Returns:
;		v0 = 1 for success, 0 if failed
;------------------------------------------------------------------------------

InsertTask:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	ldi		$v1,#MAX_TID
	bgtu	$a0,$v1,.badTid
	sll		$t0,$a0,#10					; compute TCB address
	lbu		$v1,TCBStatus[$t0]	; mark task as ready
	or		$v1,$v1,#TS_READY
	sb		$v1,TCBStatus[$t0]
	lbu		$v1,TCBPriority[$t0]
	and		$v1,$v1,#3
	lbu		$t0,HRDY0[$v1]
	lbu		$t1,TRDY0[$v1]			; increment tail pointer
	add		$t1,$t1,#1
	beq		$t0,$t1,.qfull			; test queue full?
	sb		$t1,TRDY0[$v1]			; store it back
	sll		$t3,$v1,#8					; compute t3 = readyq index
	add		$t3,$t3,#RDYQ0
	sub		$t1,$t1,#1					; back for store
	and		$t1,$t1,#255
	add		$t2,$t1,$t3
	sb		$a0,[$t2]						; store tid of task
	ldi		$v0,#E_Ok
	bra		.xit
.badTid:
	ldi		$v0,#E_Arg
	bra		.xit
.qfull:
	ldi		$v0,#E_QueFull
.xit:
	lw		$ra,[$sp]
	add		$sp,$sp,#4
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
	lbu		$t0,HRDY0[$v1]			; check queue to see if contains any
	lbu		$t1,TRDY0[$v1]			; ready tasks
	bne		$t0,$t1,.dq					; yes, go dequeue
	add		$v1,$v1,#1					; no, advance to next queue
	and		$v1,$v1,#3					; 4 max
	sub		$t2,$t2,#1					;
	bgt		$t2,$x0,.nxtQ				; go back to check next queue
	; Here, nothing else is actually ready to run
	; just go back to what we were doing.
	call	GetCurrentTid				; tail recursion here
	bra		.goodTid
.dq:
	sll		$t3,$v1,#8					; compute t3 = readyq index
	add		$t3,$t3,#RDYQ0
	add		$t4,$t0,$t3
	lbu		$v0,[$t4]						; v0 = tid of ready task
	ldi		$t3,#MAX_TID				; ensure we have a valid tid
	bleu	$v0,$t3,.goodTid
	; If the tid isn't valid, remove it from the queue and go back
	; and check the next queue entry
	add		$t0,$t0,#1					; advance readyq head
	and		$t0,$t0,#255
	sb		$t0,HRDY0[$v1]			; save head pointer
	bra		.nxtQ
.goodTid:
	add		$t0,$t0,#1					; advance readyq head
	and		$t0,$t0,#255
	sb		$t0,HRDY0[$v1]			; save head pointer
	; Now filter out tasks (remove from ready list) that aren't ready to run
	sll		$t0,$v0,#10					; tid to pointer
	lb		$t0,TCBStatus[$t0]	; get status
	and		$t0,$t0,#TS_READY		; is it ready?
	beq		$t0,$x0,.nxtQ
	; And re-insert task into queue for next time
	mov		$a0,$v0
	call	InsertTask					; could check if insert failed
	mov		$v0,$a0							; get back tid
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
	sll		$v0,$v0,#22					; shift into position
	csrrw	$v1,#$300,$x0				; get status
	and		$v1,$v1,#$FC3FFFFF	; mask off ASID/PID bits
	or		$v1,$v1,$v0					; set new ASID
	csrrw	$x0,#$300,$v1				; save status
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
; Switch tasks
;
; Parameters:
;		none
; Modifies:
;		v0, v1, t0, t1, x1, x2, a0, s1
; Returns:
;		none
;------------------------------------------------------------------------------
;
FMTK_SwitchTask:
	; Save register set in TCB
	csrrw	$x1,#$300,$x0			; get process id
	srl		$x1,$x1,#22
	and		$x1,$x1,#15
	sll		$x1,$x1,#10				; compute TCB address
	mfu		$x2,$x1
	sw		$x2,4[$x1]
	mfu		$x2,$x2
	sw		$x2,8[$x1]				; save regs in TCB
	mfu		$x2,$x3
	sw		$x2,12[$x1]
	mfu		$x2,$x4
	sw		$x2,16[$x1]
	mfu		$x2,$x5
	sw		$x2,20[$x1]
	mfu		$x2,$x6
	sw		$x2,24[$x1]
	mfu		$x2,$x7
	sw		$x2,28[$x1]
	mfu		$x2,$x8
	sw		$x2,32[$x1]
	mfu		$x2,$x9
	sw		$x2,36[$x1]
	mfu		$x2,$x10
	sw		$x2,40[$x1]
	mfu		$x2,$x11
	sw		$x2,44[$x1]
	mfu		$x2,$x12
	sw		$x2,48[$x1]
	mfu		$x2,$x13
	sw		$x2,52[$x1]
	mfu		$x2,$x14
	sw		$x2,56[$x1]
	mfu		$x2,$x15
	sw		$x2,60[$x1]
	mfu		$x2,$x16
	sw		$x2,64[$x1]
	mfu		$x2,$x17
	sw		$x2,68[$x1]
	mfu		$x2,$x18
	sw		$x2,72[$x1]
	mfu		$x2,$x19
	sw		$x2,76[$x1]
	mfu		$x2,$x20
	sw		$x2,80[$x1]
	mfu		$x2,$x21
	sw		$x2,84[$x1]
	mfu		$x2,$x22
	sw		$x2,88[$x1]
	mfu		$x2,$x23
	sw		$x2,92[$x1]
	mfu		$x2,$x24
	sw		$x2,96[$x1]
	mfu		$x2,$x25
	sw		$x2,100[$x1]
	mfu		$x2,$x26
	sw		$x2,104[$x1]
	mfu		$x2,$x27
	sw		$x2,108[$x1]
	mfu		$x2,$x28
	sw		$x2,112[$x1]
	mfu		$x2,$x29
	sw		$x2,116[$x1]
	mfu		$x2,$x30
	sw		$x2,120[$x1]
	mfu		$x2,$x31
	sw		$x2,124[$x1]
	csrrw	$x2,#$341,$x0				; save off mepc
	sw		$x2,TCBepc[$x1]
	ldi		$t1,#0
.svseg:
	mvseg	$t0,$x0,$t1
	sll		$x2,$t1,#2
	add		$x2,$x2,$x1
	sw		$t0,TCBsegs[$x2]
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.svseg

.dead:
	call	SelectTaskToRun			; v0 = pid

	; Switch memory maps
	and		$v0,$v0,#$F					; mask to 16 task
	sll		$v0,$v0,#22					; shift into position
	csrrw	$v1,#$300,$x0				; get status
	and		$v1,$v1,#$FC3FFFFF	; mask off ASID/PID bits
	or		$v1,$v1,$v0					; set new ASID
	csrrw	$x0,#$300,$v1				; save status
	; User map has now been switched
	srl		$x1,$v0,#12					; compute incoming TCB address
.0001:
	lb		$v1,TCBStatus[$x1]

	; If a message is ready, update status to ready and put
	; message in target memory. The task will be returning
	; from a WaitMsg so a return status of E_Ok is also set.
	and		$x2,$v1,#TS_MSGRDY
	beq		$x2,$x0,.noMsg
	mov		$t3,$v0							; save off v0 (tid)
	ldi		$x2,#TS_READY
	sb		$x2,TCB_Status[$x1]
	lw		$a0,80[$x1]					; user a2 (x20)
	call	VirtToPhys
	lw		$x2,TCB_MsgD1[$x1]
	sw		$x2,[$v0]
	lw		$a0,84[$x1]
	call	VirtToPhys
	lw		$x2,TCB_MsgD2[$x1]
	sw		$x2,[$v0]
	lw		$a0,88[$x1]
	call	VirtToPhys
	lw		$x2,TCB_MsgD3[$x1]
	sw		$x2,[$v0]
	ldi		$x2,#E_Ok						; setup to return E_Ok
	sw		$x2,64[$x1]					; in v0
	mov		$v0,$t3
	bra		.ready
.noMsg:
	and		$x2,$v1,#TS_READY
	bne		$x2,$x0,.ready
	and		$x2,$v1,#TS_DEAD
	bne		$x2,$x0,.dead
	
.ready:
	; Add task back into ready queue
	mov		$s1,$x1							; save off x1 (normally return address)
	srl		$a0,$v0,#22					; compute ASID/PID
	call	InsertTask
	mov		$x1,$s1							; get back x1

	; Restore register set
	ldi		$t1,#0
.rsseg:
	sll		$x2,$t1,#2
	add		$x2,$x2,$x1
	lw		$t0,TCBsegs[$x2]
	mvseg	$x0,$t0,$t1
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.rsseg

	lw		$x2,TCBepc[$x1]			; restore epc
	csrrw	$x0,#$341,$x2
	lw		$x2,4[$x1]
	mtu		$x1,$x2
	lw		$x2,8[$x1]
	mtu		$x2,$x2
	lw		$x2,12[$x1]
	mtu		$x3,$x2
	lw		$x2,16[$x1]
	mtu		$x4,$x2
	lw		$x2,20[$x1]
	mtu		$x5,$x2
	lw		$x2,24[$x1]
	mtu		$x6,$x2
	lw		$x2,28[$x1]
	mtu		$x7,$x2
	lw		$x2,32[$x1]
	mtu		$x8,$x2
	lw		$x2,36[$x1]
	mtu		$x9,$x2
	lw		$x2,40[$x1]
	mtu		$x10,$x2
	lw		$x2,44[$x1]
	mtu		$x11,$x2
	lw		$x2,48[$x1]
	mtu		$x12,$x2
	lw		$x2,52[$x1]
	mtu		$x13,$x2
	lw		$x2,56[$x1]
	mtu		$x14,$x2
	lw		$x2,60[$x1]
	mtu		$x15,$x2
	lw		$x2,64[$x1]
	mtu		$x16,$x2
	lw		$x2,68[$x1]
	mtu		$x17,$x2
	lw		$x2,72[$x1]
	mtu		$x18,$x2
	lw		$x2,76[$x1]
	mtu		$x19,$x2
	lw		$x2,80[$x1]
	mtu		$x20,$x2
	lw		$x2,84[$x1]
	mtu		$x21,$x2
	lw		$x2,88[$x1]
	mtu		$x22,$x2
	lw		$x2,92[$x1]
	mtu		$x23,$x2
	lw		$x2,96[$x1]
	mtu		$x24,$x2
	lw		$x2,100[$x1]
	mtu		$x25,$x2
	lw		$x2,104[$x1]
	mtu		$x26,$x2
	lw		$x2,108[$x1]
	mtu		$x27,$x2
	lw		$x2,112[$x1]
	mtu		$x28,$x2
	lw		$x2,116[$x1]
	mtu		$x29,$x2
	lw		$x2,120[$x1]
	mtu		$x30,$x2
	lw		$x2,124[$x1]
	mtu		$x31,$x2
	eret

;------------------------------------------------------------------------------
; Operating system call dispatcher.
;------------------------------------------------------------------------------

OSCALL:
	mfu		$a0,$a0
	mfu		$a1,$a1
	mfu		$a2,$a2
	mfu		$a3,$a3
	mfu		$a4,$a4
	mfu		$a5,$a5
	and		$a0,$a0,#15
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
; Reschedule tasks.
;------------------------------------------------------------------------------

FMTK_Reschedule:
	call	GetCurrentTid
	sll		$s1,$v0,#10						; compute pointer to TCB
	lbu		$v0,TCBStatus[$s1]		; flag task as no longer running
	and		$v0,$v0,#~TS_RUNNING
	sb		$v0,TCBStatus[$s1]

	call	AccountTime						; uses s1
	call	SelectTaskToRun

	srl		$s2,$v0,#10						; s2 = pointer to incoming TCB
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
	call	VirtToPhys
	lw		$x2,TCB_MsgD1[$s2]
	sw		$x2,[$v0]
	lw		$a0,84[$s2]
	call	VirtToPhys
	lw		$x2,TCB_MsgD2[$s2]
	sw		$x2,[$v0]
	lw		$a0,88[$s2]
	call	VirtToPhys
	lw		$x2,TCB_MsgD3[$s2]
	sw		$x2,[$v0]
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
	eret

;------------------------------------------------------------------------------
; SchedulerIRQ meant to be called from the timer ISR.
;------------------------------------------------------------------------------

FMTK_SchedulerIRQ:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	lw		$t5,Tick							; update tick count
	add		$t5,$t5,#1
	sw		$t5,Tick
	call	GetCurrentTid
	sll		$s1,$v0,#10						; compute pointer to TCB
	call	AccountTime
	lbu		$t5,TCBStatus[$s1]
	or		$t5,$t5,#TS_PREMPT
	and		$t5,$t5,#~TS_RUNNING	; no longer running, but may still be ready
	sb		$t5,TCBStatus[$s1]
	; Keep popping the timeout list as long as there are tasks on it with
	; expired timeouts.
.0001:
	lhu		$t5,TimeoutList
	blt		$t5,$x0,.noTimeouts
	ldi		$t4,#NR_TCB
	bge		$t5,$t4,.noTimeouts
	sll		$t4,$t5,#10					; index to pointer
	lw		$t3,TCBTimeout[$t4]
	bgt		$t3,$x0,.timeoutNotDone
	call	PopTimeoutList
	mov		$a0,$v0
	call	InsertTask
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

	srl		$s2,$v0,#22					; s2 = pointer to incoming TCB
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
	and		$x2,$t2,#TS_MSGRDY
	beq		$x2,$x0,.noMsg
	lw		$a0,80[$s2]					; user a2 (x20)
	call	VirtToPhys
	lw		$x2,TCB_MsgD1[$s2]
	sw		$x2,[$v0]
	lw		$a0,84[$s2]
	call	VirtToPhys
	lw		$x2,TCB_MsgD2[$s2]
	sw		$x2,[$v0]
	lw		$a0,88[$s2]
	call	VirtToPhys
	lw		$x2,TCB_MsgD3[$s2]
	sw		$x2,[$v0]
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
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	lw		$t2,Tick					; get tick
	sw		$t2,TCBStartTick[$s1]
	ret

;------------------------------------------------------------------------------
; Returns:
;		v1 = process id
;------------------------------------------------------------------------------

AllocTCB:
	ldi		$t1,#0
	lhu		$v1,PIDMAP
.0001:
	and		$t0,$v1,#1
	beq		$t0,$x0,.allocTid
	srl		$v1,$v1,#1
	or		$v1,$v1,#$8000
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.0001
; here no tcbs available
	ldi		$v0,#E_NoMoreTCBs
	ret
.allocTid:
	mov		$v0,$t1
	or		$v1,$v1,#1
	beq		$t1,$x0,.0003
.0002:
	sll		$v1,$v1,#1
	or		$v1,$v1,#1
	sub		$t1,$t1,#1
	bne		$t1,$x0,.0002
.0003:
	sh		$v1,PIDMAP
	mov		$v1,$v0
	ldi		$v0,#E_Ok
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
	bne		$v0,$x0,.err
	mov		$a0,$v1
	sll		$s1,$v1,#10			; compute TCB address
	call	AllocStack
	ldi		$t0,#$7F800			; set stack pointer
	sw		$t0,56[$s1]
	sw		$a2,TCBepc[$s1]	; address task will begin at
	call	Alloc
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
	call	InsertTask
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
	csrrw	$a1,#$300,$x0				; get tid
	srl		$a1,$a1,#22
	and		$a1,$a1,#15
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

;------------------------------------------------------------------------------
; Parameters:
;		a0 = task id to insert
;		a1 = timeout value
;------------------------------------------------------------------------------

InsertIntoTimeoutList:
	sll		$s1,$a0,#10				; tid to pointer
	lw		$t0,TimeoutList
	bge		$t0,$x0,.0001
	sw		$a1,TCBTimeout[$s1]
	sh		$a0,TimeoutList
	ldi		$t0,#-1
	sh		$t0,TCBNext[$s1]
	sh		$t0,TCBPrev[$s1]
	ldi		$v0,#E_Ok
	ret
.0001:
	mov		$t1,$x0
	lhu		$t2,TimeoutList
	sll		$t3,$t2,#10
.beginWhile:
	lw		$t4,TCBTimeout[$t3]
	ble		$a1,$t4,.endWhile
	sub		$a1,$a1,$t4
	mov		$t1,$t3
	lhu		$t3,TCBNext[$t3]
	sll		$t3,$t3,#10
	bra		.beginWhile
.endWhile
	srl		$t2,$t3,#10
	sh		$t2,TCBNext[$s1]
	srl		$t2,$t1,#10
	sh		$t2,TCBPrev[$s1]
	lw		$t2,TCBTimeout[$t3]
	sub		$t2,$t2,$a1
	sw		$t2,TCBTimeout[$t3]
	sh		$a0,TCBPrev[$t3]
	beq		$t1,$x0,.0002
	sh		$a0,TCBNext[$t1]
	bra		.0003
.0002:
	sh		$a0,TimeoutList
.0003:
	lbu		$t2,TCBStatus[$s1]
	or		$t2,$t2,#TS_TIMEOUT
	sb		$t2,TCBStatus[$s1]
	ldi		$v0,#E_Ok
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

RemoveFromTimeoutList:
	sll		$s1,$a0,#10					; tid to pointer
	lhu		$t0,TCBNext[$s1]
	blt		$t0,$x0,.0001
	sll		$s2,$t0,#10
	lhu		$t1,TCBPrev[$s1]
	sh		$t1,TCBPrev[$s2]
	lw		$t1,TCBTimeout[$s2]
	lw		$t2,TCBTimeout[$s1]
	add		$t1,$t1,$t2
	sw		$t1,TCBTimeout[$s2]
.0001:
	lhu		$t0,TCBPrev[$s1]
	blt		$t0,$x0,.0002
	sll		$s2,$t0,#10
	lhu		$t0,TCBNext[$s1]
	sh		$t0,TCBNext[$s2]
.0002:
	sb		$x0,TCBStatus[$s1]	; status = TS_NONE
	ldi		$t0,#-1
	sh		$t0,TCBNext[$s1]
	sh		$t0,TCBPrev[$s1]
	ret

;------------------------------------------------------------------------------
; Pop an entry off the timeout list.
;
; Modifies:
;		v1,t0
;	Returns:
		v0 = timeout list entry tid
;------------------------------------------------------------------------------

PopTimeoutList:
	lhu		$v0,TimeoutList
	blt		$v0,$x0,.done
	ldi		$v1,#NR_TCB
	bgeu	$v0,$v1,.done
	sll		$t0,$v0,#10						; tid to pointer
	lbu		$v1,TCBStatus[$t0]		; no longer a waiting status
	and		$v1,$v1,#~(TS_WAITMSG|TS_TIMEOUT)
	sb		$v1,TCBStatus[$t0]
	lhu		$v1,TCBNext[$t0]
	sh		$v1,TimeoutList
	blt		$v0,$x0,.done
	ldi		$v1,#NR_TCB
	bgeu	$v0,$v1,.done
	ldi		$v1,#-1
	sh		$v1,TCBPrev[$t0]
.done:	
	ret

;------------------------------------------------------------------------------
; Sleep for a length of time. Time determined by the resolution of wall clock 
; time. Passing a time of zero causes the function to return right away with
; and E_Ok status.
;
; Parameters:
;		a1 = length of time to sleep
; Returns:
;		v0 = E_Ok if successful
;------------------------------------------------------------------------------

FMTK_Sleep:
	ble		$a1,$x0,.xit
	csrrw	$t0,#$701,$x0
	call	GetCurrentTid
	sll		$s1,$v0,#10
	lbu		$t1,TCBStatus[$s1]		; changing status will remove from ready queue
	and		$t1,$t1,#~TS_READY		; on next dequeue
	sb		$t1,TCBStatus[$s1]
	mov		$a0,$v0								; a0 = current tid
	call	InsertIntoTimeoutList	; a1 = timeout
	jmp		FMTK_Reschedule
.xit:
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Diagnostics
;------------------------------------------------------------------------------

DumpReadyQueue:
	sub		$sp,$sp,#28
	sw		$ra,[$sp]
	sw		$a0,4[$sp]
	sw		$a2,8[$sp]
	sw		$a3,12[$sp]
	sw		$t1,16[$sp]
	sw		$t2,20[$sp]
	sw		$t3,24[$sp]
	ldi		$t1,#0
.0002:
	ldi		$a0,#CR
	call	Putch
	ldi		$a0,#'Q'
	call	Putch
	mov		$a0,$t1
	call	PutHexNybble
	ldi		$a0,#':'
	call	Putch
	lbu		$a2,HRDY0[$t1]
	lbu		$a3,TRDY0[$t1]
	beq		$a2,$a3,.nxt
	sll		$t2,$t1,#8
	add		$t2,$t2,#RDYQ0
.0001:
	add		$t3,$t2,$a2
	lbu		$a0,[$t3]
	call	PutHexByte
	ldi		$a0,#' '
	call	Putch
	add		$a2,$a2,#1
	bne		$a2,$a3,.0001
.nxt:
	add		$t1,$t1,#1
	slt		$t2,$t1,#4
	bne		$t2,$x0,.0002
	lw		$ra,[$sp]
	lw		$a0,4[$sp]
	lw		$a2,8[$sp]
	lw		$a3,12[$sp]
	lw		$t1,16[$sp]
	lw		$t2,20[$sp]
	lw		$t3,24[$sp]
	add		$sp,$sp,#28
	eret

