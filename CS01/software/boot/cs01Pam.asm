;------------------------------------------------------------------------------
; The first page of memory is marked as allocated and won't appear in any
; user map. That allows a page of zero to be returned for insufficient 
; memory available.
;------------------------------------------------------------------------------

InitPAM:
		ldi		$t0,#1			; permanently allocate first page
		sw		$t0,PAM
		sw		$x0,PAM+4
		sw		$x0,PAM+8
		sw		$x0,PAM+12
		sw		$x0,PAM+16
		sw		$x0,PAM+20
		sw		$x0,PAM+24
		sw		$x0,PAM+28
		ret

;------------------------------------------------------------------------------
; Allocate a single page of memory. Available memory is indicated by a bitmmap
; called the PAM for page allocation map.
; There's only eight words to check so an unrolled loop works here.
;------------------------------------------------------------------------------
;
AllocPage:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	lw		$t0,PAM
	ldi		$t1,#$FFFFFFFF
	beq		$t0,$t1,.chkPam4
	call	BitIndex
	sw		$a0,PAM
	bra		.0001
.chkPam4:
	lw		$t0,PAM+4
	beq		$t0,$t1,.chkPam8
	call	BitIndex
	sw		$a0,PAM+4
	add		$v0,$v0,#32
	bra		.0001
.chkPam8:
	lw		$t0,PAM+8
	beq		$t0,$t1,.chkPam12
	call	BitIndex
	sw		$a0,PAM+8
	add		$v0,$v0,#64
	bra		.0001
.chkPam12:
	lw		$t0,PAM+12
	beq		$t0,$t1,.chkPam16
	call	BitIndex
	sw		$a0,PAM+12
	add		$v0,$v0,#96
	bra		.0001
.chkPam16:
	lw		$t0,PAM+16
	beq		$t0,$t1,.chkPam20
	call	BitIndex
	sw		$a0,PAM+16
	add		$v0,$v0,#128
	bra		.0001
.chkPam20:
	lw		$t0,PAM+20
	beq		$t0,$t1,.chkPam24
	call	BitIndex
	sw		$a0,PAM+20
	add		$v0,$v0,#160
	bra		.0001
.chkPam24:
	lw		$t0,PAM+24
	beq		$t0,$t1,.chkPam28
	call	BitIndex
	sw		$a0,PAM+24
	add		$v0,$v0,#192
	bra		.0001
.chkPam28:
	lw		$t0,PAM+28
	beq		$t0,$t1,.chkPamDone
	call	BitIndex
	sw		$a0,PAM+28
	add		$v0,$v0,#224
	bra		.0001
.chkPamDone:
	ldi		$v0,#0						; no memory available
.0001:
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret

; Returns:
;		v0 = bit index of allocated page
;
BitIndex:
	ldi		$v0,#0
.0001:
	and		$t2,$a0,#1
	beq		$t2,$x0,.foundFree
	srl		$a0,$a0,#1
	or		$a0,$a0,#$80000000	; do a rotate, we know bit = 1
	add		$v0,$v0,#1
	bra		.0001
.foundFree:
	or		$a0,$a0,#1					; mark page allocated
	mov		$t1,$v0
	beq		$t1,$x0,.0003
.0004:
	sll		$a0,$a0,#1					; do a rotate
	or		$a0,$a0,#1					; we know bit = 1
	sub		$t1,$t1,#1
	bne		$t1,$x0,.0004
.0003:
	ret

