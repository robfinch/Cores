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

	align 4
FreeMsg	dw	0
msgs:
	fill.b	MSG_SIZE*1024,0
mbxs:
	fill.b	MBX_SIZE*32,0
mbxs_end:

;------------------------------------------------------------------------------
; Parameters:
;		a1 = task id of owner
;		a2 = pointer where to store handle
; Returns:
;		v0 = mailbox handle, -1 if not allocated
;------------------------------------------------------------------------------

FMTK_AllocMbx:
	beq		$a2,$x0,.badArg
	ldi		$t0,#mbxs
.nxt:
	lbu		$t1,MBX_OWNER[$t0]
	beq		$t1,$t0,.noOwner
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
	beq		$t5,$t0,.noWaiters
	ldi		$s1,#0
.0001:
	and		$s3,$t5,#1					; is tid waiting?
	beq		$s3,$x0,.nxtTid
	sll		$s3,$s1,#10					; convert tid to TCB pointer
	sw		$a2,TCBMsgD1[$s3]		; copy message to TCB
	sw		$a3,TCBMsgD2[$s3]
	sw		$a4,TCBMsgD3[$s3]
	ldi		$t2,#TS_MSGRDY
	sb		$t2,TCBStatus[$s3]
	mov		$a0,$s1
	sub		$sp,$sp,#4
	sw		$t0,[$sp]						; push t0
	call	InsertTask
	lw		$t0,[$sp]						; pop t0
	add		$sp,$sp,#4
.nxtTid:
	srl		$t5,$t5,#1					; check next task
	add		$s1,$s1,#1
	and		$s1,$s1,#15
	bne		$s1,$x0,.0001
	sw		$x0,MBX_WTIDS[$t0]	; clear waiters
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret
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
	mtu		$v0,$v0
	eret
.mbxEmpty:
	sw		$t1,MBX_MQHEAD[$t0]
	sw		$t1,MBX_MQTAIL[$t0]
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret
.noMsg:
	ldi		$v0,#E_NoMsg
	mtu		$v0,$v0
	eret
.badMbx:
	ldi		$v0,#E_BadMbx				; return null pointer if bad mailbox
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
;		a5 = 1 = remove from queue
;------------------------------------------------------------------------------

FMTK_WaitMsg:
	call	PeekMsg							; check for a message, return if available
	ldi		$t1,#E_NoMsg
	beq		$v0,$t1,.qt					; no message? Then go queue task
	mtu		$v0,$v0
	eret
.qt:
	csrrw	$t1,#$300,$x0				; get tid
	srl		$t1,$t1,#22
	and		$t1,$t1,#15
	ldi		$t2,#1
	sll		$t2,$t2,$t1
	sll		$t3,$a0,#4					; convert handle to pointer
	add		$t3,$t3,#mbxs
	lw		$t4,MBX_WTIDS[$t3]	; get waiting task list
	or		$t4,$t4,$t2					; set bit for tid
	sw		$t4,MBX_WTIDS[$t3]	; save task list
	sll		$t4,$t1,#11					; convert tid to TCB pointer
	ldi		$t3,#TS_WAITMSG			; set waiting for message status
	sb		$t3,TCBStatus[$t4]
	; Continue by switching tasks
	jmp		FMTK_SwitchTask

	