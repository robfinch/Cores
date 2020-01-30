
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
RDYQ0		EQU		$4400
RDYQ1		EQU		$4500
RDYQ2		EQU		$4600
RDYQ3		EQU		$4700

qToChk:
	db	0,0,0,1,0,0,2,1
	db	0,0,3,1,0,0,2,1
	db	0,0,0,1,0,0,2,1
	db	0,0,3,1,0,0,2,1

	align	4

FMTKInit:
	sw		$x0,HRDY0			; reset head and tail indexes
	sw		$x0,TRDY0
	ldi		$t0,#1				; pid #0 is permanently allocated to OS
	sh		$t0,PIDMAP
	ret

; Insert task into ready queue
;
; Parameters:
;		a0 = pid to insert
; Returns:
;		v0 = 1 for success, 0 if failed
;
InsertTask:
	sll		$v1,$a0,#10					; compute TCB address
	lbu		$v1,TCBPriority[$v1]
	and		$v1,$v1,#3
	lbu		$t0,HRDY0[$v1]
	lbu		$t1,TRDY0[$v1]			; increment tail pointer
	add		$t1,$t1,#1
	beq		$t0,$t1,.qfull			; test queue full?
	sb		$t1,TRDY0[$v1]			; store it back
	sll		$t3,$v1,#8					; compute t3 = readyq index
	add		$t3,$t3,#RDYQ0
	add		$t2,$t1,$t3
	sb		$a0,[$t2]						; store pid of task
	ldi		$v0,#1							; return non-zero
	ret
.qfull:
	mov		$v0,$x0
	ret
	
SelectTaskToRun:
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
	csrrw	$v0,#$300,$x0				; get current pid
	srl		$v0,#22							; extract field
	and		$v0,$v0,#15					; mask off extra bits
	ret
.dq:
	sll		$t3,$v1,#8					; compute t3 = readyq index
	add		$t3,$t3,#RDYQ0
	add		$t2,$t0,$t3
	lbu		$v0,[$t2]						; v0 = pid of ready task
	and		$v0,$v0,#15					; make sure pid will be valid
	add		$t0,$t0,#1					; advance readyq head
	and		$t0,$t0,#255
	sb		$t0,HRDY0[$v1]			; save head pointer
	ret

;
; Switch tasks
;
SwitchTask:
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

OSCALL:
	mfu		$a0,$a0
	mfu		$a1,$a1
	mfu		$a2,$a2
	beq		$a0,$x0,SwitchTask
	sub		$a0,$a0,#1
	beq		$a0,$x0,StartTask
	sub		$a0,$a0,#1
	beq		$a0,$x0,KillTask
	eret

;------------------------------------------------------------------------------
; Returns:
;		v0 = process id
;------------------------------------------------------------------------------

GetFreePid:
	ldi		$t1,#0
	lhu		$v1,PIDMAP
.0001:
	and		$t0,$v1,#1
	beq		$t0,$x0,.allocPid
	srl		$v1,$v1,#1
	or		$v1,$v1,#$8000
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.0001
; here no pids available
	mov		$v0,$x0
	ret
.allocPid:
	mov		$v0,$t1
	or		$v1,$v1,#1
.0002:
	sll		$v1,$v1,#1
	or		$v1,$v1,#1
	sub		$t1,$t1,#1
	bne		$t1,$t0,.0002
	sh		$v1,PIDMAP
	ret

;------------------------------------------------------------------------------
; Start a task.
;	Task status is set to ready, priority normal, and the task is inserted into
; the ready queue. Segment registers are setup for a flat memory model.
; 
;	Parameters:
;		a1 = memory pages required
;		a2 = start pc (usually $100)
;	Modifies:
;		a0 = pid
;	Returns:
;		v0 = pid of started task if successful, otherwise zero
;------------------------------------------------------------------------------
;
StartTask:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	call	GetFreePid
	beq		$v0,$x0,.err
	mov		$a0,$v0
	sll		$s1,$a0,#10			; compute TCB address
	call	AllocStack
	ldi		$t0,#$7F800			; set stack pointer
	sw		$t0,56[$s1]
	sw		$a2,TCBepc[$s1]	; address task will begin at
	call	Alloc
	beq		$v1,$x0,.err
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
	call	InsertTask
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	mtu		$v0,$a0
	eret
.err:
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	mtu		$v0,$x0
	eret

;------------------------------------------------------------------------------
; Parameters:
;		a1 = pid of task to kill
;------------------------------------------------------------------------------

KillTask:
	ldi		$t0,#TS_DEAD				; flag task as dead (prevents it from being re-queued)
	and		$t1,$a1,#15					; limit pid
	sll		$t1,$t1,#10					; convert to TCB address
	sb		$t0,TCBStatus[$t1]
	call	FreeAll							; free all the memory associated with the task
	; Now make process ID available for reuse
	lhu		$t1,PIDMAP
	ldi		$t0,#1
	sll		$t0,$t0,$a1
	xor		$t0,$t0,#-1
	and		$t1,$t1,$t0
	sh		$t1,PIDMAP
	eret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DumpReadyQueue:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
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
	add		$sp,$sp,#4
	ret

