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

MBX_OWNER			equ		0		; tid of owning task
MBX_WTIDS			equ		4		; tasks waiting at mailbox
MBX_MQHEAD		equ		8		
MBX_MQTAIL		equ		12
MBX_SIZE			equ		16

MSG_LINK	equ		0
MSG_D1		equ		4
MSG_D2		equ		8
MSG_D3		equ		12
MSG_SIZE	equ		16

;	bss
;	align 4
;FreeMsg	dw	0
;msgs:
;	fill.b	MSG_SIZE*1024,0
;mbxs:
;	fill.b	MBX_SIZE*32,0
;mbxs_end:

	code
	align	4

;------------------------------------------------------------------------------
; Parameters:
;		a1 = task id of owner
;		a2 = pointer where to store handle
; Returns:
;		v0 = E_Ok
;------------------------------------------------------------------------------

FMTK_AllocMbx:
	beq		$a2,$x0,.badArg
	ldi		$t0,#mbxs
.nxt:
	lbu		$t1,MBX_OWNER[$t0]
	beq		$t1,$x0,.noOwner
	add		$t0,$t0,#MBX_SIZE
	slt		$t1,$t0,#mbxs_end
	bne		$t1,$x0,.nxt
	ldi		$v0,#E_NoMoreMbx
	mtu		$v0,$v0
	eret
.noOwner:
	sb		$a1,MBX_OWNER[$t0]
	sub		$t5,$t0,#mbxs				; convert pointer to handle
	srl		$t5,$t5,#4
	mov		$a0,$a2
	call	VirtToPhys
	sw		$t5,[$v0]
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret
.badArg:
	ldi		$v0,#E_Arg
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

FMTK_FreeMbx:
	slt		$s1,$a1,#32
	beq		$s1,$x0,.badMbx
	sll		$s1,$a1,#4					; convert handle to pointer
	add		$s1,$s1,#mbxs
	ldi		$s2,#0
	ldi		$s4,#16							; possibly 16 tasks
	lw		$s6,MBX_WTIDS[$s1]
.0002:
	and		$s3,$s6,#1
	beq		$s3,$x0,.0001
	sll		$s5,$s2,#10						; tid to pointer
	lbu		$v0,TCBStatus[$s5]
	and		$v0,$v0,#~TS_WAITMSG	; no longer waiting
	sb		$v0,TCBStatus[$s5]
	and		$v0,$v0,#TS_TIMEOUT
	beq		$v0,$x0,.0003
	mov		$a0,$s2
	call	RemoveFromTimeoutList
.0003:
	mov		$a0,$s2
	call	InsertIntoReadyList
	ldi		$v0,#E_NoMsg					; but no message
	sw		$v0,64[$s5]						; v0 = E_NoMsg
.0001:
	srl		$s6,$s6,#1
	add		$s2,$s2,#1
	bltu	$s2,$s4,.0002
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret
.badMbx:
	ldi		$v0,#E_BadMbx				; return null pointer if bad mailbox
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Send a message to a mailbox.
; The message will be broadcast to any waiting tasks. Waiting tasks will then
; be moved to the ready list. If there are no waiting tasks then the message
; is queued at the mailbox.
;
; Register Usage:
;		t0 = mailbox pointer
;		t1 = message pointer
;		s1 = task id of waiting task
; Modifies:
;		a0
; Parameters:
;		a1 = mailbox handle
;		a2 = message d1
;		a3 = message d2
;		a4 = message d3
;------------------------------------------------------------------------------

FMTK_SendMsg:
	slt		$t0,$a1,#32
	beq		$t0,$x0,.badMbx
	sll		$t0,$a1,#4					; convert handle to pointer
	add		$t0,$t0,#mbxs
	lw		$t5,MBX_WTIDS[$t0]
	beq		$t5,$x0,.noWaiters
	ldi		$s1,#0
.0001:
	and		$s3,$t5,#1					; is tid waiting?
	beq		$s3,$x0,.nxtTid
	sll		$s3,$s1,#10					; convert tid to TCB pointer
	sw		$a2,TCBMsgD1[$s3]		; copy message to TCB
	sw		$a3,TCBMsgD2[$s3]
	sw		$a4,TCBMsgD3[$s3]
	lbu		$t2,TCBStatus[$s3]
	or		$t2,$t2,#TS_MSGRDY
	sb		$t2,TCBStatus[$s3]
	mov		$a0,$s1
	sub		$sp,$sp,#4
	sw		$t0,[$sp]						; push t0
	call	InsertIntoReadyList
	lw		$t0,[$sp]						; pop t0
	add		$sp,$sp,#4
.nxtTid:
	srl		$t5,$t5,#1					; check next task
	add		$s1,$s1,#1
	and		$s1,$s1,#15
	bne		$s1,$x0,.0001
	sw		$x0,MBX_WTIDS[$t0]	; clear waiters
	ldi		$v0,#E_Ok
	bra		.xit
.noWaiters:
	lw		$t1,FreeMsg
	beq		$t1,$x0,.noMsg			; message available?
	lw		$t2,MSG_LINK[$t1]
	sw		$t2,FreeMsg
	sw		$a2,MSG_D1[$t1]
	sw		$a3,MSG_D2[$t1]
	sw		$a4,MSG_D3[$t1]
	lw		$t3,MBX_MQTAIL[$t0]
	beq		$t3,$x0,.mbxEmpty
	sw		$t1,MSG_LINK[$t3]
	sw		$t1,MBX_MQTAIL[$t0]
	ldi		$v0,#E_Ok
	bra		.xit
.mbxEmpty:
	sw		$t1,MBX_MQHEAD[$t0]
	sw		$t1,MBX_MQTAIL[$t0]
	ldi		$v0,#E_Ok
	bra		.xit
.noMsg:
	ldi		$v0,#E_NoMsg
	bra		.xit
.badMbx:
	ldi		$v0,#E_BadMbx				; return null pointer if bad mailbox
.xit:
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Parameters:
;		a1 = mailbox handle
;		a2 = pointer where to put message D1
;		a3 = pointer where to put message D2
;		a4 = pointer where to put message D3
;		a5 = 1 = remove from queue
;------------------------------------------------------------------------------

PeekMsg:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	slt		$t0,$a1,#32
	beq		$t0,$x0,.badMbx
	sll		$t2,$a1,#4					; convert handle to pointer
	add		$t2,$t2,#mbxs
	lw		$t1,MBX_MQHEAD[$t2]
	beq		$t1,$x0,.noMsg
	beq		$a5,$x0,.nodq
	lw		$t3,MSG_LINK[$t1]
	sw		$t3,MBX_MQHEAD[$t2]
	; This is done here only because interrupts are disabled
	lw		$t3,FreeMsg
	sw		$t3,MSG_LINK[$t1]
	sw		$t1,FreeMsg
.nodq:
	beq		$a2,$x0,.nod1
	mov		$a0,$a2
	call	VirtToPhys
	lw		$t3,MSG_D1[$t1]
	sw		$t3,[$v0]
.nod1:
	beq		$a3,$x0,.nod2
	mov		$a0,$a3
	call	VirtToPhys
	lw		$t3,MSG_D2[$t1]
	sw		$t3,[$v0]
.nod2:
	beq		$a4,$x0,.nod3
	mov		$a0,$a4
	call	VirtToPhys
	lw		$t3,MSG_D3[$t1]
	sw		$t3,[$v0]
.nod3:
	ldi		$v0,#E_Ok
	bra		.ret
.noMsg:
	ldi		$v0,#E_NoMsg
	bra		.ret
.badMbx:
	ldi		$v0,#E_BadMbx				; return null pointer if bad mailbox
.ret:
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret

;------------------------------------------------------------------------------
; PeekMsg will check for a message at a mailbox optionally dequeuing it.
; If no message is available PeekMsg returns to the caller with a E_NoMsg
; status.
;
; Parameters:
;		a1 = mailbox handle
;		a2 = pointer where to put message D1
;		a3 = pointer where to put message D2
;		a4 = pointer where to put message D3
;		a5 = 1 = remove from queue
;------------------------------------------------------------------------------

FMTK_PeekMsg:
	call	PeekMsg
	mtu		$v0,$v0
	eret

;------------------------------------------------------------------------------
; Calling WaitMsg will cause the task to be queued at the mailbox and a task
; switch to occur if there are no messages at the mailbox.
;
; Parameters:
;		a1 = mailbox handle
;		a2 = pointer where to put message D1
;		a3 = pointer where to put message D2
;		a4 = pointer where to put message D3
;		a5 = time limit
;------------------------------------------------------------------------------

FMTK_WaitMsg:
	mov		s5,a5
	ldi		a5,#1
	call	PeekMsg							; check for a message, return if available
	ldi		$t1,#E_NoMsg
	beq		$v0,$t1,.qt					; no message? Then go queue task
	mtu		$v0,$v0
	eret
.qt:
	mGetCurrentTid
	ldi		$t2,#1
	sll		$t2,$t2,$v0
	sll		$t3,$a1,#4					; convert handle to pointer
	add		$t3,$t3,#mbxs
	lw		$t4,MBX_WTIDS[$t3]	; get waiting task list
	or		$t4,$t4,$t2					; set bit for tid
	sw		$t4,MBX_WTIDS[$t3]	; save task list
	sll		$t4,$v0,#10					; convert tid to TCB pointer
	lbu		$t3,TCBStatus[$t4]
	or		$t3,$t3,#TS_WAITMSG	; set waiting for message status
	and		$t3,$t3,#~TS_READY	; not ready
	sb		$t3,TCBStatus[$t4]
	sb		$a1,TCBWaitMbx[$t4]	; set mailbox task is waiting for
	mov		$a1,$a5
	; Continue by switching tasks
	jmp		FMTK_Sleep

	