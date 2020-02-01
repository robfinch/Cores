	code
	align	4
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

