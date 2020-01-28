
QNDX		EQU		$4304
HRDY0		EQU		$4305
HRDY1		EQU		$4306
HRDY2		EQU		$4307
HRDY3		EQU		$4308
TRDY0		EQU		$4309
TRDY1		EQU		$430A
TRDY2		EQU		$430B
TRYD3		EQU		$430C
PIDMAP	EQU		$430E
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
	and		$v1,#31
	sb		$v1,QNDX						; store back
	lbu		$v1,qToChk[$v1]			; assume this will be valid
	ldi		$t0,#4							; 4 queues to check
.nxtQ:
	lbu		$t0,HRDY0[$v1]			; check queue to see if contains any
	lbu		$t1,TRDY0[$v1]			; ready tasks
	bne		$t0,$t1,.dq					; yes, go dequeue
	add		$v1,$v1,#1					; no, advance to next queue
	and		$v1,$v1,#3					; 4 max
	sub		$t0,$t0,#1					;
	bne		$t0,$x0,.nxtQ				; go back to check next queue
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
	csrrw	$x1,#$340,$x1			; swap x1 and scrap
	csrrw	$x1,#$300,$x0			; get process id
	srl		$x1,$x1,#22
	and		$x1,$x1,#15
	sll		$x1,$x1,#10				; compute TCB address
	sw		$x2,8[$x1]				; save regs in TCB
	sw		$x3,12[$x1]
	sw		$x4,16[$x1]
	sw		$x5,20[$x1]
	sw		$x6,24[$x1]
	sw		$x7,28[$x1]
	sw		$x8,32[$x1]
	sw		$x9,36[$x1]
	sw		$x10,40[$x1]
	sw		$x11,44[$x1]
	sw		$x12,48[$x1]
	sw		$x13,52[$x1]
	sw		$x14,56[$x1]
	sw		$x15,60[$x1]
	sw		$x16,64[$x1]
	sw		$x17,68[$x1]
	sw		$x18,72[$x1]
	sw		$x19,76[$x1]
	sw		$x20,80[$x1]
	sw		$x21,84[$x1]
	sw		$x22,88[$x1]
	sw		$x23,92[$x1]
	sw		$x24,96[$x1]
	sw		$x25,100[$x1]
	sw		$x26,104[$x1]
	sw		$x27,108[$x1]
	sw		$x28,112[$x1]
	sw		$x29,116[$x1]
	sw		$x30,120[$x1]
	sw		$x31,124[$x1]
	csrrw	$x2,#$340,$x0				; get original x1 back
	sw		$x2,4[$x1]					; and save it too
	csrrw	$x2,#$341,$x0				; save off mepc
	sw		$x3,TCBepc[$x1]
	ldi		$t1,#0
.svseg:
	mvseg	$t0,$x0,$t1
	sll		$x2,$t1,#2
	add		$x2,$x2,$x1
	sw		$t0,TCBseg[$x2]
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
	srl		$a0,$v0,#22					; compute ASID/PID
	call	InsertTask

	; Restore register set
	ldi		$t1,#0
.rsseg:
	sll		$x2,$t1,#2
	add		$x2,$x2,$x1
	lw		$t0,TCBseg[$x2]
	mvseg	$x0,$t0,$t1
	add		$t1,$t1,#1
	and		$t1,$t1,#15
	bne		$t1,$x0,.rsseg

	lw		$x2,TCBepc[$x1]			; restore epc
	csrrw	$x0,#$341,$x2
	lw		$x2,8[$x1]
	lw		$x3,12[$x1]
	lw		$x4,16[$x1]
	lw		$x5,20[$x1]
	lw		$x6,24[$x1]
	lw		$x7,28[$x1]
	lw		$x8,32[$x1]
	lw		$x9,36[$x1]
	lw		$x10,40[$x1]
	lw		$x11,44[$x1]
	lw		$x12,48[$x1]
	lw		$x13,52[$x1]
	lw		$x14,56[$x1]
	lw		$x15,60[$x1]
	lw		$x16,64[$x1]
	lw		$x17,68[$x1]
	lw		$x18,72[$x1]
	lw		$x19,76[$x1]
	lw		$x20,80[$x1]
	lw		$x21,84[$x1]
	lw		$x22,88[$x1]
	lw		$x23,92[$x1]
	lw		$x24,96[$x1]
	lw		$x25,100[$x1]
	lw		$x26,104[$x1]
	lw		$x27,108[$x1]
	lw		$x28,112[$x1]
	lw		$x29,116[$x1]
	lw		$x30,120[$x1]
	lw		$x31,124[$x1]
	lw		$x1,4[$x1]
	eret

OSCALL:
	beq		$a0,$x0,SwitchTask
	sub		$a0,$a0,#1
	beq		$a0,$x0,StartTask
	sub		$a0,$a0,#1
	beq		$a0,$x0,GetFreePid
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
	call	GetFreePid
	beq		$v0,$x0,.err
	mov		$a0,$v0
	sll		$x1,$a0,#10			; compute TCB address
	call	AllocStack
	ldi		$t0,#$7F800			; set stack pointer
	sw		$t0,56[$x1]
	sw		$a2,TCBepc[$x1]	; address task will begin at
	call	Alloc
	beq		$v0,$x0,.err
	ldi		$t0,#TS_READY
	sb		$t0,TCBStatus[$x1]
	ldi		$t0,#2					; normal execution priority
	sb		$t0,TCBPriority[$x1]
	; leave segment base at $0, flat memory model
	ldi		$t0,#6							; read,write
	sw		$t0,TCBseg[$x1]			; segs 0 to 11
	sw		$t0,TCBseg+4[$x1]
	sw		$t0,TCBseg+8[$x1]
	sw		$t0,TCBseg+12[$x1]
	sw		$t0,TCBseg+16[$x1]
	sw		$t0,TCBseg+20[$x1]
	sw		$t0,TCBseg+24[$x1]
	sw		$t0,TCBseg+28[$x1]
	sw		$t0,TCBseg+32[$x1]
	sw		$t0,TCBseg+36[$x1]
	sw		$t0,TCBseg+40[$x1]
	sw		$t0,TCBseg+44[$x1]
	ldi		$t0,#5							; read,execute
	sw		$t0,TCBseg+48[$x1]	; segs 12 to 15
	sw		$t0,TCBseg+52[$x1]
	sw		$t0,TCBseg+56[$x1]
	sw		$t0,TCBseg+60[$x1]
	call	InsertTask
	mov		$v0,$a0
	eret
.err:
	mov		$v0,$x0
	eret

