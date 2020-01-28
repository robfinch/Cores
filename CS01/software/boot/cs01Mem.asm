; PAM is a bitmask of allocated pages. There are 256 pages (256 bits)
; 8 words storage required.
;
PAM			equ		$300

		code	18 bits
		align	4
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

MMUInit:
		ldi		$t2,#4096				; number of registers to update
		ldi		$t0,#$00
		ldi		$t1,#$000				; regno
.0001:
		mvmap	$x0,$t0,$t1
		add		$t0,$t0,#$01		; increment page numbers
		add		$t1,$t1,#$01
		sub		$t2,$t2,#1
		bne		$t2,$x0,.0001
		; Now setup segment registers
		ldi		$t0,#$0
		ldi		$t1,#$07				; t1 = value to load RWX=111, base = 0
.0002:
		mvseg	$x0,$t1,$t0			; move to the segment register identifed by t0
		add		$t0,$t0,#1			; pick next segment register
		slt		$t2,$t0,#16			; 16 segment regs
		bne		$t2,$x0,.0002
		
;------------------------------------------------------------------------------
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

; There's only eight words to check so an unrolled loop works here.
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
	add		$v0,$v0,#8
	bra		.0001
.chkPam8:
	lw		$t0,PAM+8
	beq		$t0,$t1,.chkPam12
	call	BitIndex
	sw		$a0,PAM+8
	add		$v0,$v0,#16
	bra		.0001
.chkPam12:
	lw		$t0,PAM+12
	beq		$t0,$t1,.chkPam16
	call	BitIndex
	sw		$a0,PAM+12
	add		$v0,$v0,#24
	bra		.0001
.chkPam16:
	lw		$t0,PAM+16
	beq		$t0,$t1,.chkPam20
	call	BitIndex
	sw		$a0,PAM+16
	add		$v0,$v0,#32
	bra		.0001
.chkPam20:
	lw		$t0,PAM+20
	beq		$t0,$t1,.chkPam24
	call	BitIndex
	sw		$a0,PAM+20
	add		$v0,$v0,#40
	bra		.0001
.chkPam24:
	lw		$t0,PAM+24
	beq		$t0,$t1,.chkPam28
	call	BitIndex
	sw		$a0,PAM+24
	add		$v0,$v0,#48
	bra		.0001
.chkPam28:
	lw		$t0,PAM+28
	beq		$t0,$t1,.chkPamDone
	call	BitIndex
	sw		$a0,PAM+28
	add		$v0,$v0,#56
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

FindRun:
	ldi			$t1,#0						; t1 = count of consecutive empty buckets
	csrrw		$t0,#$8C0,$x0
	and			$v0,$t0,#$FF
	beq			$v0,$x0,.empty0
.empty0:
	

