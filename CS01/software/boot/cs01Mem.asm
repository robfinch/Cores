NPAGES	equ		$4300
PAM			equ		$4800

		code	18 bits
		align	4
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

MMUInit:
		ldi		$t0,#246				; set number of available pages (10 pages already allocated)
		sw		$t0,NPAGES			
		; Setup PAM
		ldi		$t0,#$1FF				; permanently allocate pages for OS data
		sw		$t0,PAM
		sw		$x0,PAM+4
		sw		$x0,PAM+8
		sw		$x0,PAM+12
		sw		$x0,PAM+16
		sw		$x0,PAM+20
		sw		$x0,PAM+24
		ldi		$t0,#$80000000	; last page is system stack
		sw		$t0,PAM+28
		ldi		$t0,#$00
		ldi		$t1,#$000				; regno
		ldi		$t2,#4096				; number of registers to update
		ldi		$t3,#10					; number of pages pre-allocated
.0001:
		mvmap	$x0,$t0,$t1
		add		$t0,$t0,#$01
		add		$t1,$t1,#$01		; increment page number
		bltu	$t1,$t3,.0003
		mov		$t0,$x0					; mark pages after 9 unallocated
.0003:
		sub		$t2,$t2,#1
		bne		$t2,$x0,.0001
		ldi		$t1,#$0FF				; allocate last page for stack
		ldi		$t0,#$FF
		mvmap	$x0,$t0,$t1
		; Now setup segment registers
		ldi		$t0,#$0
		ldi		$t1,#$07				; t1 = value to load RWX=111, base = 0
.0002:
		mvseg	$x0,$t1,$t0			; move to the segment register identifed by t0
		add		$t0,$t0,#1			; pick next segment register
		slt		$t2,$t0,#16			; 16 segment regs
		bne		$t2,$x0,.0002
		ret

;------------------------------------------------------------------------------
; Allocate a single page of memory. Available memory is indicated by a bitmmap
; called the PAM for page allocation map.
; There's only eight words to check so an unrolled loop works here.
;
; Modifies:
;		t0,t1,t2
; Returns:
;		v0 = page allocated
;------------------------------------------------------------------------------
;
AllocPage:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	lw		$t0,PAM
	ldi		$t1,#$FFFFFFFF
	beq		$t0,$t1,.chkPam4
	call	BitIndex
	sw		$t0,PAM
	bra		.0001
.chkPam4:
	lw		$t0,PAM+4
	beq		$t0,$t1,.chkPam8
	call	BitIndex
	sw		$t0,PAM+4
	add		$v0,$v0,#32
	bra		.0001
.chkPam8:
	lw		$t0,PAM+8
	beq		$t0,$t1,.chkPam12
	call	BitIndex
	sw		$t0,PAM+8
	add		$v0,$v0,#64
	bra		.0001
.chkPam12:
	lw		$t0,PAM+12
	beq		$t0,$t1,.chkPam16
	call	BitIndex
	sw		$t0,PAM+12
	add		$v0,$v0,#96
	bra		.0001
.chkPam16:
	lw		$t0,PAM+16
	beq		$t0,$t1,.chkPam20
	call	BitIndex
	sw		$t0,PAM+16
	add		$v0,$v0,#128
	bra		.0001
.chkPam20:
	lw		$t0,PAM+20
	beq		$t0,$t1,.chkPam24
	call	BitIndex
	sw		$t0,PAM+20
	add		$v0,$v0,#160
	bra		.0001
.chkPam24:
	lw		$t0,PAM+24
	beq		$t0,$t1,.chkPam28
	call	BitIndex
	sw		$t0,PAM+24
	add		$v0,$v0,#192
	bra		.0001
.chkPam28:
	lw		$t0,PAM+28
	beq		$t0,$t1,.chkPamDone
	call	BitIndex
	sw		$t0,PAM+28
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
	and		$t2,$t0,#1
	beq		$t2,$x0,.foundFree
	srl		$t0,$t0,#1
	or		$t0,$t0,#$80000000	; do a rotate, we know bit = 1
	add		$v0,$v0,#1
	bra		.0001
.foundFree:
	or		$t0,$t0,#1					; mark page allocated
	mov		$t1,$v0
	beq		$t1,$x0,.0003
.0004:
	sll		$t0,$t0,#1					; do a rotate
	or		$t0,$t0,#1					; we know bit = 1
	sub		$t1,$t1,#1
	bne		$t1,$x0,.0004
.0003:
	ret

;------------------------------------------------------------------------------
; Parameters:
;		a0 = page number to free
; Modifies:
;		v0,v1,t0
;------------------------------------------------------------------------------

FreePage:
	ldi		$v0,#255						; last page is permanently allocated to system stack
	bgeu	$a0,$v0,.xit
	ldi		$v0,#9
	bltu	$a0,$v0,.xit				; first 9 pages (18kB) allocated permanently to system
	srl		$v0,$a0,#5					; v0 = word
	and		$v1,$a0,#31					; v1 = bit no
	ldi		$t0,#1							; make a bitmask
	sll		$t0,$t0,$v1
	xor		$t0,$t0,#-1					; invert mask
	lw		$v1,PAM[$v0]
	and		$v1,$v1,$t0					; clear bit
	sw		$v1,PAM[$v0]				; save PAM word back
.xit:
	ret

;------------------------------------------------------------------------------
; Find a run of buckets available for mapping virtual to physical addresses.
;
; Parameters:
;		a0 = pid
;		a1 = number of pages required.
; Modifies:
;		t1,t2,t3,t5
; Returns:
;		v0 = starting bucket number (includes ASID), -1 if no run found
;------------------------------------------------------------------------------

FindRun:
	and			$t3,$a0,#$0F			; t3 = pid
	sll			$t3,$t3,#8				; shift into usable position
	ldi			$t1,#0						; t1 = count of consecutive empty buckets
	mov			$t2,$t3						; t2 = map entry number
	or			$t2,$t2,#OSPAGES	; start looking at page 32 (others are for OS)
	ldi			$t5,#255					; max number of pages - 1
	or			$t5,$t5,$t3				; t5 = max in ASID
.0001:
	mvmap		$v0,$x0,$t2				; get map entry into v0
	beq			$v0,$x0,.empty0		; is it empty?
	add			$t2,$t2,#1
	bltu		$t2,$t5,.0001
	ldi			$v0,#-1						; got here so no run was found
	ret
.empty0:
	mov			$t3,$t2						; save first empty bucket
.empty1:
	add			$t1,$t1,#1
	bgeu		$t1,$a1,.foundEnough
	add			$t2,$t2,#1				; next bucket
	mvmap		$v0,$x0,$t2				; get map entry
	beq			$v0,$x0,.empty1
	mov			$t1,$x0						; reset counter
	bra			.0001							; go back and find another run
.foundEnough:
	mov			$v0,$t3						; v0 = start of run
	ret

;------------------------------------------------------------------------------
; Parameters:
;		a0 = pid
;		a1 = amount of memory to allocate
; Modifies:
;		t0
; Returns:
;		v1 = pointer to allocated memory in virtual address space.
;		v0 = E_Ok for success, E_NotAlloc otherwise
;------------------------------------------------------------------------------
;
Alloc:
	sub			$sp,$sp,#16
	sw			$ra,[$sp]
	sw			$s1,4[$sp]				; these regs must be saved
	sw			$s2,8[$sp]
	sw			$s3,12[$sp]
	; First check if there are enough pages available in the system.
	add			$v0,$a1,#2047			; v0 = round memory request
	srl			$v0,$v0,#11				; v0 = convert to pages required
	lw			$t0,NPAGES				; check number of pages available
	bleu		$v0,$t0,.enough
.noRun2:
	ldi			$v1,#0						; not enough, return null
	bra			.noRun
.enough:
	mov			$s1,$a0
	mov			$a0,$s1
	; There are enough pages, but is there a run long enough in map space?
	mov			$s2,$v0				; save required # pages
	mov			$a1,$v0
	call		FindRun						; find a run of available slots
	blt			$v0,$x0,.noRun2
	; Now there are enough pages, and a run available, so allocate
	mov			$s1,$v0						; s1 = start of run
	lw			$s3,NPAGES				; decrease number of pages available in system
	sub			$s3,$s3,$s2
	sw			$s3,NPAGES
	mov			$s3,$v0						; s3 = start of run
.0001:
	palloc	$v0								; allocate a page (cheat and use hardware)
	;call		AllocPage
	beq			$v0,$x0,.noRun
	mvmap		$x0,$v0,$s3				; map the page
	add			$s3,$s3,#1				; next bucket
	sub			$s2,$s2,#1
	bne			$s2,$x0,.0001
	sll			$v1,$s1,#11				; v0 = virtual address of allocated mem.
	ldi			$v0,#E_Ok
	bra			.xit
.noRun:
	ldi			$v0,#E_NotAlloc
.xit
	lw			$ra,[$sp]					; restore saved regs
	lw			s1,4[$sp]
	lw			s2,8[$sp]
	lw			s3,12[$sp]
	add			$sp,$sp,#16
	ret

;------------------------------------------------------------------------------
; Allocate the stack page for a task. The stack is located at the highest
; virtual address ($7F800).
;
; Parameters:
;		a0 = pid to allocate for
;	Returns:
;		v0 = physical address, 0 if unsuccessful
;		v1 = virtual address, not valid unless successful
;------------------------------------------------------------------------------
;
AllocStack:
	; need save ra here if calling AllocPage
	sll			$v1,$a0,#8			; 
	or			$v1,$v1,#255		; last page of memory is for stack
	mvmap		$v0,$x0,$v1			; check if stack already allocated
	bne			$v0,$x0,.0001
	palloc	$v0							; allocate a page
	;call		AllocPage
	beq			$v0,$x0,.xit		; success?
	mvmap		$x0,$v0,$v1
.0001:
	and			$v1,$v1,#255
	sll			$v0,$v0,#11			; convert pages to addresses
	sll			$v1,$v1,#11
.xit:
	ret

;------------------------------------------------------------------------------
; This routine will de-allocate all the pages associated with a task including
; the stack.
;
; Parameters:
;		a0 = pid to free memory for
;	Modifies:
;		a0,t0,t1,t3,t4
; Returns:
;		none
;------------------------------------------------------------------------------

FreeAll:
	; need save ra if calling FreePage
	ldi			$t3,#0
	sll			$t4,$a0,#8
.nxt:
	slt			$t1,$t3,#256		; number of buckets to check
	beq			$t1,$x0,.0001
	and			$t4,$t4,#$F00
	or			$t4,$t4,$t3			; combine pid and bucket number
	ldi			$t0,#0					; new page number to set (indicates free)
	mvmap		$t0,$t0,$t4			; get page mapping and set to zero
	add			$t3,$t3,#1			; advance to next bucket
	and			$t0,$t0,#255		; pages are 1-255
	beq			$t0,$x0,.nxt		; 0 = no map in this bucket
	pfree		$t0							; free the page
	;mov			$a0,$t0
	;call		FreePage
	lw			$t0,NPAGES			; update the number of available pages
	add			$t0,$t0,#1
	sw			$t0,NPAGES
	bra			.nxt
.0001:
	ret

;------------------------------------------------------------------------------
; Convert a virtual address to a physical one
;
; Parameters:
;		a0 = virtual address to convert
; Modifies:
;		t0
; Returns:
;		v0 = physcial address
;------------------------------------------------------------------------------

VirtToPhys:
	blt		$a0,$x0,.notMapped
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	srl		$t0,$a0,#11					; convert virt to page
	call	GetCurrentTid
	sll		$v0,$v0,#8
	or		$v0,$v0,$t0					; and in tid
	mvmap	$v0,$x0,$v0					; get the translation
	sll		$v0,$v0,#11					; convert page to address
	and		$t0,$a0,#$7FF				; insert LSB's
	or		$v0,$v0,$t0
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret
.notMapped:
	mov		$v0,$a0
	ret
