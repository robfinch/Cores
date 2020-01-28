
TimerIRQ:
	lw		$t0,milliseconds
	add		$t0,$t0,#10
	sw		$t0,milliseconds
	eret

SwitchTask:
	lw		$a0,READYQ					; pop the ready queue
	sll		$t0,$a0,#10					; size of control block
	add		$t0,$t0,#TCBs				; TCB array
	lb		$t1,TCBStatus[$t0]	; get status
	and		$t2,$t1,#TS_READY		; is it ready?
	beq		$t2,$x0,.notReady
	sw		$a0,READYQ					; push back on ready queue
	sll		$v0,$a0,#22
	csrrw	$v1,#$300,$x0				; get status
	and		$v1,$v1,#$FC3FFFFF	; mask off ASID bits
	or		$v1,$v1,$v0					; set new ASID
	csrrw	$x0,#$300,$v1				; save status
.notReady:
	and		$t2,$t1,#TS_DEAD		; dead?
	bne		$t2,$x0,.deadTask

.deadTask:
	; reclaim resources used by task

			