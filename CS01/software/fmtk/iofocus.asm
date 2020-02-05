IOFocusNdx		EQU		$8C08
IOFocusTbl		EQU		$8C10

;-----------------------------------------------------------------------------
; IO Focus routines complicated by the fact that the base address of TCB
; zero is zero (looks like a null pointer but isn't). So the value -1 is 
; used to indicate no focus index.
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
; Determine if the currently running task has the I/O focus.
;
; Stack Space:
;		2 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		v0 = E_Ok
;		v1 = 1 if task has IO focus, 0 otherwise
;-----------------------------------------------------------------------------

FMTK_HasIOFocus:
	mGetCurrentTid
	sll		$v0,$v0,#10
	lw		$v1,IOFocusNdx
	beq		$v0,$v1,.hasFocus
	ldi		$v1,#0
	bra		.xit
.hasFocus:
	ldi		$v1,#1
.xit:
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	mtu		$v1,$v1
	eret

;-----------------------------------------------------------------------------
; First check if it's even possible to switch the focus to another
; task. The I/O focus list could be empty or there may be only a
; single task in the list. In either case it's not possible to
; switch.
;
; Stack Space:
;		2 words
;	Parameters:
;		none
;	Modifies:
;		none
;	Returns:
;		v0 = E_Ok
;-----------------------------------------------------------------------------

SwitchIOFocusHelper:
	sub		$sp,$sp,#8
	sw		$t0,[$sp]
	sw		$t1,4[$sp]
	lw		$t0,IOFocusNdx			; get focus pointer
	blt		$t0,$x0,.noFocus		; is it -1?
	lw		$t1,IOF_NEXT[$t0]
	beq		$t1,$t0,.sameFocus
	; swap virtual screens
	; set vidmem pointer
	sw		$t1,IOFocusNdx
.sameFocus:
.noFocus:
	ldi		$v0,E_Ok
	lw		$t0,[$sp]
	lw		$t1,4[$sp]
	add		$sp,$sp,#8
	ret

FMTK_SwitchIOFocus:
	call	SwitchIOFocusHelper
	mtu		$v0,$v0
	eret

;-----------------------------------------------------------------------------
; The I/O focus list is an array indicating which jobs are requesting the
; I/O focus. The I/O focus is user controlled by pressing CNTRL-T on the
; keyboard.
;
; Parameters:
;		a1 = task id requesting focus for
;-----------------------------------------------------------------------------

FMTK_RequestIOFocus:
	ldi		$t0,#1
	sll		$t0,$t0,$a1
	lw		$t1,IOFocusTbl			; Is the task already included in the IO focus?
	and		$t2,$t1,$t0					; test bit
	bne		$t2,$x0,.ret				; If so, don't add again
	or		$t1,$t1,$t0					; set bit indicator
	sw		$t1,IOFocusTbl
	lw		$t0,IOFocusNdx			; get current index
	sll		$t1,$a1,#10					; t1 = pointer to TCB
	bge		$t0,$x0,.notEmpty		; is there one? (!= -1)
	sw		$t1,IOFocusNdx			; no current index, so set equal to requester
	sw		$t1,IOF_NEXT[$t1]		; and loop back to self
	sw		$t1,IOF_PREV[$t1]
	bra		.ret
.notEmpty:
	lw		$t2,IOF_PREV[$t0]		; insert t1 into focus ring
	sw		$t2,IOF_PREV[$t1]
	sw		$t0,IOF_NEXT[$t1]
	lw		$t2,IOF_PREV[$t0]
	sw		$t1,IOF_NEXT[$t2]
	sw		$t1,IOF_PREV[$t0]
.ret:
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret

;-----------------------------------------------------------------------------
; ReleaseIOFocus called when the task no longer desires to be on the I/O
; focus list.
;-----------------------------------------------------------------------------

FMTK_ReleaseIOFocus:
	mGetCurrentTid
	mov		a1,v0
	; fall into ForceReleaseIOFocus

;-----------------------------------------------------------------------------
; Releasing the I/O focus causes the focus to switch if the running job
; had the I/O focus.
; ForceReleaseIOFocus forces the release of the IO focus for a job
; different than the one currently running.
; 
; Parameters:
;		a1 = task id to release
; Returns:
;		v0 = E_Ok
;-----------------------------------------------------------------------------

FMTK_ForceReleaseIOFocus:
	ldi		$t0,#1
	sll		$t0,$t0,$a1
	lw		$t1,IOFocusTbl
	and		$t2,$t1,$t0				; test bit for task
	beq		$t2,$x0,.noFocus	; does it even have the focus?
	xor		$t0,$t0,#-1				; get inverted mask
	and		$t1,$t1,$t0				; clear bit for task
	sw		$t1,IOFocusTbl
	lw		$t1,IOFocusNdx		; check if the focus being released is the current
	sll		$t0,$a1,#10				; io focus. If so, switch focus
	bne		$t0,$t1,.notSame
	call	SwitchIOFocusHelper
.notSame:
	lw		$t2,IOF_NEXT[$t0]
	blt		$t2,$x0,.done
	beq		$t2,$t0,.pjSame
	lw		$t1,IOF_PREV[$t0]
	sw		$t1,IOF_PREV[$t2]
	sw		$t2,IOF_NEXT[$t1]
	bra		.0001
.pjSame:
	ldi		$t1,#-1
	sw		$t1,IOFocusNdx
.0001:
	ldi		$t1,#-1
	sw		$t1,IOF_NEXT[$t0]	
	sw		$t1,IOF_PREV[$t0]	
.done:
.noFocus:
	ldi		$v0,#E_Ok
	mtu		$v0,$v0
	eret
