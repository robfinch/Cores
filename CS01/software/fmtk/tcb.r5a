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
; Insert task into ready list. The list is a doubly linked circular list.
;
; Stack Space:
;		2 words
; Parameters:
;		a0 = tid to insert
; Modifies:
;		v1,t0,t1,t2
; Returns:
;		v0 = 1 for success, 0 if failed
;------------------------------------------------------------------------------

InsertIntoReadyList:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	call	PutHexHalf
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ldi		$v1,#MAX_TID				; check argument
	bgtu	$a0,$v1,.badTid
	sub		$sp,$sp,#12
	sw		$s1,[$sp]						; save callee save registers
	sw		$s2,4[$sp]
	sw		$ra,8[$sp]
	sll		$s1,$a0,#10					; tid to pointer
	lb		$t0,TCBPriority[$s1]
	and		$t0,$t0,#3					; limit to four
	sll		$t0,$t0,#1					; *2 for indexing
	lh		$t1,READYQ[$t0]			; get head of queue for that priority
	mov		$s3,$a0
	mov		$a0,$t1
	call	PutHexHalf
	mov		$a0,$s3
	bge		$t1,$x0,.insert			; Is there a head?
	sh		$a0,READYQ[$t0]			; no head, simple to insert
	sh		$a0,TCBNext[$s1]
	sh		$a0,TCBPrev[$s1]
	bra		.ok
	; Insert at tail of list, which is just before the head.
.insert:
	sll		$s2,$t1,#10					; a little more complicated, tid to pointer
	lh		$t2,TCBPrev[$s2]		; t2 = head->prev
	sh		$t2,TCBPrev[$s1]		; arg->prev = head->prev
	sh		$t1,TCBNext[$s1]		; arg->next = head, arg links are now set
	sll		$s1,$t2,#10					; s1 = head->prev (as a pointer)
	sh		$a0,TCBNext[$s1]		; head->prev->next = arg
	sh		$a0,TCBPrev[$s2]		; head->prev = arg
.ok:
	ldi		$v0,#E_Ok
.xit:
	lw		$s1,[$sp]						; restore callee saved regs
	lw		$s2,4[$sp]
	lw		$ra,8[$sp]
	add		$sp,$sp,#12
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	call	DumpReadyList
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret
.badTid:
	ldi		$v0,#E_Arg
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

RemoveFromReadyList:
	ldi		$v1,#MAX_TID					; check arg
	bgtu	$a0,$v1,.badTid
	sub		$sp,$sp,#8
	sw		$s1,[$sp]							; save callee saved regs
	sw		$s2,4[$sp]
	sll		$s1,$a0,#10						; s1 = pointer to tcb
	lb		$t0,TCBStatus[$s1]		; set status no longer ready or running
	and		$t0,$t0,#~(TS_READY|TS_RUNNING)
	sb		$t0,TCBStatus[$s1]
	lb		$t0,TCBPriority[$s1]	; t0 = priority
	and		$t0,$t0,#3						; limit to 0-3
	sll		$t0,$t0,#1						; *2 for indexing
	lh		$t1,READYQ[$t0]				; get head tid
	lh		$t2,TCBNext[$s1]			; get arg->next
	bne		$t1,$a0,.0001					; removing head of list?
	sh		$t2,READYQ[$t0]				; yes, set new head to arg->next
.0001:
	blt		$t2,$x0,.0002					; validate t2 (arg->next)
	bgtu	$t2,$v1,.0002					; there should always be an arg->next, arg->prev
	lh		$t3,TCBPrev[$s1]			; because the list is circular t3=arg->prev
	sll		$s2,$t3,#10						; s2 = arg->prev as a pointer
	sh		$t2,TCBNext[$s2]			; arg->prev->next = arg->next
	sll		$s2,$t2,#10						; s2 = arg->next as a pointer
	sh		$t3,TCBPrev[$s2]			; arg->next->prev = arg->prev
	; Now indicate links in TCB are not in use.
.0002:
	ldi		$v0,#-1
	sh		$v0,TCBNext[$s1]
	sh		$v0,TCBPrev[$s1]
	ldi		$v0,#E_Ok							; we're ok
	lw		$s1,[$sp]							; restore callee saved regs
	lw		$s2,4[$sp]
	add		$sp,$sp,#8
	ret
.badTid:
	ldi		$v0,#E_Arg
	ret

;------------------------------------------------------------------------------
; Parameters:
;		a0 = task id to insert
;		a1 = timeout value
; Modifies:
;		t0,t1,t2,t3,t4,s1
;------------------------------------------------------------------------------

InsertIntoTimeoutList:
	sll		$s1,$a0,#10					; tid to pointer
	ldi		$t0,#-1						
	sh		$t0,TCBNext[$s1]		; initialize indexes to -1
	sh		$t0,TCBPrev[$s1]
	lh		$t0,TimeoutList
	bge		$t0,$x0,.0001
	sw		$a1,TCBTimeout[$s1]
	sh		$a0,TimeoutList
	ldi		$v0,#E_Ok
	ret
.0001:
	mov		$t1,$x0
	mov		$t2,$t0
	sll		$t3,$t2,#10
.beginWhile:
	lw		$t4,TCBTimeout[$t3]
	ble		$a1,$t4,.endWhile
	sub		$a1,$a1,$t4
	mov		$t1,$t3
	lh		$t3,TCBNext[$t3]
	blt		$t3,$x0,.endWhile
	sll		$t3,$t3,#10
	bne		$t3,$t1,.beginWhile		; list screwed up?
.endWhile
	sra		$t2,$t3,#10
	sh		$t2,TCBNext[$s1]
	sra		$t2,$t1,#10
	sh		$t2,TCBPrev[$s1]
	lw		$t2,TCBTimeout[$t3]
	sub		$t2,$t2,$a1
	sw		$t2,TCBTimeout[$t3]
	sh		$a0,TCBPrev[$t3]
	blt		$t1,$x0,.0002
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
; Remove a task from the timeout list. The timeouts of following tasks are
; adjusted.
;
; Parameters:
;		a0 = task id to remove
; Modifies:
;		t0,t1,t2
; Returns:
;		none
;------------------------------------------------------------------------------

RemoveFromTimeoutList:
	sub		$sp,$sp,#12
	sw		$s1,[$sp]
	sw		$s2,8[$sp]
	sw		$ra,4[$sp]
	sll		$s1,$a0,#10						; tid to pointer
	lbu		$t0,TCBStatus[$s1]		; check if waiting at a mailbox
	and		$t0,$t0,#TS_WAITMSG
	beq		$t0,$x0,.noWait				
	mMbxRemoveTask
.noWait:
	lh		$t0,TimeoutList
	bne		$a0,$t0,.0001					; check removing head of list
	lh		$t0,TCBNext[$s1]
	sh		$t0,TimeoutList
.0001:
	lh		$t0,TCBNext[$s1]
	blt		$t0,$x0,.noNext
	sll		$s2,$t0,#10
	lh		$t1,TCBPrev[$s1]
	sh		$t1,TCBPrev[$s2]
	lw		$t1,TCBTimeout[$s2]
	lw		$t2,TCBTimeout[$s1]
	add		$t1,$t1,$t2
	sw		$t1,TCBTimeout[$s2]
.noNext:
	lh		$t0,TCBPrev[$s1]
	blt		$t0,$x0,.noPrev
	sll		$s2,$t0,#10
	lh		$t0,TCBNext[$s1]
	sh		$t0,TCBNext[$s2]
.noPrev:
	lb		$t0,TCBStatus[$s1]		; no longer timing out
	and		$t0,$t0,#~(TS_TIMEOUT|TS_WAITMSG)
	sb		$t0,TCBStatus[$s1]
	ldi		$t0,#-1
	sh		$t0,TCBNext[$s1]
	sh		$t0,TCBPrev[$s1]
	lw		$s1,[$sp]							; restore callee saves
	lw		$ra,4[$sp]
	lw		$s2,8[$sp]
	add		$sp,$sp,#12
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
;------------------------------------------------------------------------------

FreeTCB:
	ldi		$t0,#1
	sll		$t0,$t0,$a0
	xor		$t0,$t0,#-1
	lhu		$t1,PIDMAP
	and		$t1,$t1,$t0
	sh		$t1,PIDMAP
	ret

;------------------------------------------------------------------------------
; Diagnostics
;------------------------------------------------------------------------------

DumpReadyList:
	sub		$sp,$sp,#28
	sw		$ra,[$sp]
	sw		$a0,4[$sp]
	sw		$a2,8[$sp]
	sw		$a3,12[$sp]
	sw		$t1,16[$sp]
	sw		$t2,20[$sp]
	sw		$t3,24[$sp]
	ldi		$a0,#msgReadyList
	call	PutString
	ldi		$t1,#0
.0002:
	call	SerialPeekCharDirect
	xor		$v0,$v0,#CTRLC
	beq		$v0,$x0,.brk
	ldi		$a0,#CR
	call	Putch
	ldi		$a0,#'Q'
	call	Putch
	srl		$a0,$t1,#1
	call	PutHexNybble
	ldi		$a0,#':'
	call	Putch
	lh		$a2,READYQ[$t1]
	blt		$a2,$x0,.nxt
	mov		$a3,$a2
.0001:
	mov		$a0,$a3
	call	PutHexHalf
	ldi		$a0,#' '
	call	Putch
	sll		$a3,$a3,#10
	lh		$a0,TCBNext[$a3]
	call	PutHexHalf
	ldi		$a0,#' '
	call	Putch
	lh		$a0,TCBPrev[$a3]
	call	PutHexHalf
	ldi		$a0,#CR
	call	Putch
	lh		$a3,TCBNext[$a3]
	bne		$a2,$a3,.0001
.nxt:
	add		$t1,$t1,#2
	slt		$t2,$t1,#8
	bne		$t2,$x0,.0002
.brk:
	lw		$ra,[$sp]
	lw		$a0,4[$sp]
	lw		$a2,8[$sp]
	lw		$a3,12[$sp]
	lw		$t1,16[$sp]
	lw		$t2,20[$sp]
	lw		$t3,24[$sp]
	add		$sp,$sp,#28
	ret

DumpTimeoutList:
	sub		$sp,$sp,#28
	sw		$ra,[$sp]
	sw		$a0,4[$sp]
	sw		$a2,8[$sp]
	sw		$a3,12[$sp]
	sw		$t1,16[$sp]
	sw		$t2,20[$sp]
	sw		$t3,24[$sp]
	ldi		$a0,#msgTimeoutList
	call	PutString
	ldi		$t1,#0
.0002:
	call	SerialPeekCharDirect
	xor		$v0,$v0,#CTRLC
	beq		$v0,$x0,.brk
	ldi		$a0,#CR
	call	Putch
	ldi		$a0,#'Q'
	call	Putch
	srl		$a0,$t1,#1
	call	PutHexNybble
	ldi		$a0,#':'
	call	Putch
	lh		$a2,TimeoutList
	blt		$a2,$x0,.brk
	mov		$a3,$a2
.0001:
	mov		$a0,$a3
	call	PutHexHalf
	ldi		$a0,#'-'
	call	Putch
	sll		$a3,$a3,#10
	lw		$a0,TCBTimeout[$a3]
	call	PutHexWord
	ldi		$a0,#CR
	call	Putch
	lh		$a3,TCBNext[$a3]
	bge		$a3,$x0,.0001
.brk:
	lw		$ra,[$sp]
	lw		$a0,4[$sp]
	lw		$a2,8[$sp]
	lw		$a3,12[$sp]
	lw		$t1,16[$sp]
	lw		$t2,20[$sp]
	lw		$t3,24[$sp]
	add		$sp,$sp,#28
	ret

msgReadyList:
	db	CR,"Ready List",CR
	db	"Que Tid  Prv  Nxt",CR
	db	"-----------------",CR,0

msgTimeoutList:
	db	CR,"Timeout List",CR
	db	" Tid - Timeout",CR
	db	"--------------",CR,0

	align 4