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

; macros have to be defined before they are encountered.

; unlock the a semaphore	
macro mUnlockSemaphore (adr)
	ldi		v0,#-1
	sw		v0,adr
endm

; Look at the asid register for task id
macro mGetCurrentTid
	csrrw	v0,#$181,x0
	and		v0,v0,#15
endm

macro	mHasFocus
	ldi		a0,#20
	ecall
endm

macro mSleep(tm)
	ldi		a0,#5
	ldi		a1,#tm
	ecall
endm

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

macro mWaitForFocus
.WFF1@:
	mHasFocus
	bne		v1,x0,.HasFocus@
	call	SerialPeekChar	;Direct
	ldi		a0,#$14							; CTRL-T
	bne		$v0,$a0,.WFF2@
	call	SerialGetChar
	ldi		$a0,#21							; switch IO Focus
	ecall
	bra		.WFF1@
.WFF2@:
	mSleep(1)
	bra		.WFF1@
.HasFocus@:
endm

;------------------------------------------------------------------------------
; Remove the task from the list of tasks waiting at the mailbox.
; This routine is only called from a couple of places and it is convenient
; not to stack the return address. So, it is implemented as a macro.
;
; Parameters:
;		a0 = task id
;------------------------------------------------------------------------------

macro mMbxRemoveTask
	sub		$sp,$sp,#16
	sw		$s1,[$sp]
	sw		$t0,4[$sp]
	sw		$t1,8[$sp]
	sw		$t2,12[$sp]
	sll		$s1,$a0,#10						; tid to pointer
	lh		$t0,TCBWaitMbx[$s1]		; get mailbox handle
	blt		$t0,$x0,.xit@					; handle good?
	sll		$t0,$t0,#4						; convert to pointer
	add		$t0,$t0,#mbxs					; by adding base address
	lhu		$t1,MBX_WTIDS[$t0]		; get waiting task list
	ldi		$t2,#1								; create a mask for given task id
	sll		$t2,$t2,$a0
	xor		$t2,$t2,#-1
	and		$t1,$t1,$t2						; clear bit
	sh		$t1,MBX_WTIDS[$t0]		; update waiting task list
.xit@:
	lw		$s1,[$sp]
	lw		$t0,4[$sp]
	lw		$t1,8[$sp]
	lw		$t2,12[$sp]
	add		$sp,$sp,#16
endm

;------------------------------------------------------------------------------
; Pop an entry off the timeout list. It is assumed the entry is popped when
; its timeout reached zero. Hence there is no adjustment of the following
; timeout made. Routine used only in the schedulerIRQ, so written as a macro.
;
; Modifies:
;		v1,t0,t1,t2,t3
;	Returns:
;		v0 = timeout list entry tid
;------------------------------------------------------------------------------

macro mPopTimeoutList
	lh		$v0,TimeoutList				; anything on timeout list?
	blt		$v0,$x0,.done@
	ldi		$v1,#NR_TCB
	bgeu	$v0,$v1,.done@
	sll		$t0,$v0,#10						; tid to pointer
	lbu		$v1,TCBStatus[$t0]		; no longer a waiting status
	and		$t1,$v1,#TS_WAITMSG
	beq		$t1,$x0,.noWait@
	mMbxRemoveTask
.noWait@:
	and		$v1,$v1,#~(TS_WAITMSG|TS_TIMEOUT)
	sb		$v1,TCBStatus[$t0]
	lh		$v1,TCBNext[$t0]
	sh		$v1,TimeoutList
	ldi		$t1,#NR_TCB
	bgeu	$v1,$t1,.done@
	lh		$t1,TCBPrev[$t0]			; t1 = h->prev
	sll		$v1,$v1,#10
	sh		$t1,TCBPrev[$v1]			; TimeoutList->prev = h->prev
	srl		$v1,$v1,#10
	sll		$t1,$t1,#10
	sh		$v1,TCBNext[$t1]			; h->prev->next = TimeoutList
.done@:	
endm


