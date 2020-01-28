
;
; Switch tasks
; The first page of memory allocated to task stores the task state
; in the lowest 1kB.
;
SwitchTask:
	; Save register set using user memory access
	sw		$x1,4
	sw		$x2,8
	sw		$x3,12
	sw		$x4,16
	sw		$x5,20
	sw		$x6,24
	sw		$x7,28
	sw		$x8,32
	sw		$x9,36
	sw		$x10,40
	sw		$x11,44
	sw		$x12,48
	sw		$x13,52
	sw		$x14,56
	sw		$x15,60
	sw		$x16,64
	sw		$x17,68
	sw		$x18,72
	sw		$x19,76
	sw		$x20,80
	sw		$x21,84
	sw		$x22,88
	sw		$x23,92
	sw		$x24,96
	sw		$x25,100
	sw		$x26,104
	sw		$x27,108
	sw		$x28,112
	sw		$x29,116
	sw		$x30,120
	sw		$x31,124
	; Switch maps
	lbu		$v0,READYQ					; pop the ready queue
	and		$v0,$v0,#$F					; mask to 16 task
	sll		$v0,$v0,#22					; shift into position
	csrrw	$v1,#$300,$x0				; get status
	and		$v1,$v1,#$FC3FFFFF	; mask off ASID bits
	or		$v1,$v1,$v0					; set new ASID
	csrrw	$x0,#$300,$v1				; save status
	; User map has now been switched, subsequent memory access is to incoming
	; task
.0001:
	lb		$x1,TCBStatus
	and		$x2,$x1,#TS_READY
	bne		$x2,$x0,.ready
	and		$x2,$x1,#TS_DEAD
	bne		$x2,$x0,.dead
.dead:
	
.ready:
	; Add task back into ready queue
	csrrw	$v1,#$300,$x0
	srl		$v1,$v1,#22
	sb		$v1,READYQ

	; Restore register set
	lw		$x1,4
	lw		$x2,8
	lw		$x3,12
	lw		$x4,16
	lw		$x5,20
	lw		$x6,24
	lw		$x7,28
	lw		$x8,32
	lw		$x9,36
	lw		$x10,40
	lw		$x11,44
	lw		$x12,48
	lw		$x13,52
	lw		$x14,56
	lw		$x15,60
	lw		$x16,64
	lw		$x17,68
	lw		$x18,72
	lw		$x19,76
	lw		$x20,80
	lw		$x21,84
	lw		$x22,88
	lw		$x23,92
	lw		$x24,96
	lw		$x25,100
	lw		$x26,104
	lw		$x27,108
	lw		$x28,112
	lw		$x29,116
	lw		$x30,120
	lw		$x31,124
	eret

OSCALL:
	beq		$a0,$x0,SwitchTask
	eret

.call1:
	eret

