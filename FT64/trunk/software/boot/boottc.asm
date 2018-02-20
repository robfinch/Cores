; N4V128Sys bootrom - (C) 2017-2018 Robert Finch, Waterloo
;
; This file is part of N4V128Sys
;
; how to build:
; 1. assemble using "AS64 +gFn .\boottc\boottc.asm"
; 2. copy boottc.ve0 to the correct directory if not already there
;
;------------------------------------------------------------------------------
;
; system memory map
;
;
; 00000000 +----------------+
;          |                |
;          |                |
;          |                |
;          |                |
;          :  dram memory   : 512 MB
;          |                |
;          |                |
;          |                |
;          |                |
; 20000000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FF400000 +----------------+
;          |   scratchpad   | 32 kB
; FF408000 +----------------+
;          |     unused     |
; FFD00000 +----------------+
;          |                |
;          :    I/O area    : 1.0 M
;          |                |
; FFE00000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FFFC0000 +----------------+
;          |                |
;          :    boot rom    :
;          |                |
; FFFFFFFF +----------------+
;
;
;
E_BadCallno	equ		-4

LEDS		equ		$FFDC0600
BUTTONS		equ		$FFDC0600
SCRATCHPAD	equ		$FF400000
AVIC		equ		$FFDCC000
TC1			equ		$FFD0DF00

WHITE		equ		$7FFF
MEDBLUE		equ		$000F
fgcolor		equ		SCRATCHPAD
bkcolor		equ		fgcolor + 4
_randStream	equ		SCRATCHPAD + 16
_DBGCursorCol	equ	_randStream + 8
_DBGCursorRow	equ	_DBGCursorCol + 4
_DBGAttr	equ		_DBGCursorRow + 4
_milliseconds	equ		_DBGAttr + 4
___garbage_list	equ	SCRATCHPAD + 48
__brk_stack	equ	SCRATCHPAD + 2048

; Help the assembler out by telling it how many bits are required for code
; addresses
		code	18 bits
		org		$FFFC0000		; start of ROM memory space
		jmp		__BrkHandler	; jump to the exception handler
		org		$FFFC0100		; The PC is set here on reset
		jmp		start			; Comment out this jump to test i-cache
test_icache:
	; This seems stupid but maybe necessary. Writes to r0 always cause it to
	; be loaded with the value zero regardless of the value written. Readback
	; should then always be a zero. The only case it might not be is at power
	; on. At power on the reg should be zero, but let's not assume that and
	; write a zero to it.
		and		r0,r0,#0		; cannot use LDI which does an or operation
		; set trap vector
		ldi		r1,#$FFFC0000
		csrrw	r0,#$30,r1
		ldi		r31,#$FF400FF8	; set stack pointer
		sei		#0

	; Seed random number generator
		ldi		r6,#$FFDC0000
		sh		r0,$0C04[r6]			; select stream #0
		ldi		r1,#$88888888
		sh		r1,$0C08[r6]			; set initial m_z
		ldi		r1,#$01234567
		sh		r1,$0C0C[r6]			; set initial m_w
.st4:
	; Get a random number
		sh		r0,$FFDC0C04	; set the stream
		nop						; delay a wee bit
		lhu		r1,$FFDC0C00	; get a number
		sh		r0,$FFDC0C00	; generate next number

	; convert to random address
		shl		r1,r1,#2
		and		r1,r1,#$1FFC
		add		r1,r1,#$FF401000	; scratchram address
		
	; Fill an area with test code
		ldi		r2,#15			; number of ops - 1
		ldi		r3,#.st2		; address of test routine copy
.st3:
		lhu		r4,[r3+r2*4]	; move from boot rom to
		sh		r4,[r1+r2*4]	; scratch ram
		dbnz	r2,.st3
	
	; Now jump to the test code
		cache	#3,[r1]			; invalidate the cache
		jal		r29,[r1]
		ldi		r2,#14			; this is the value that should be returned
		cmp		r1,r1,r2
		bne		r1,r0,.st5
		bra		.st4

	; Display fail code
.st5:
		ldi		r1,#$FA
		sb		r1,$FFDC0600
		bra		.st5

; Test code accumulates for 16 instructions, sum should be 14
		
.st2:
		ldi		r1,#0
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		add		r1,r1,#1		
		ret

start:
	; This seems stupid but maybe necessary. Writes to r0 always cause it to
	; be loaded with the value zero regardless of the value written. Readback
	; should then always be a zero. The only case it might not be is at power
	; on. At power on the reg should be zero, but let's not assume that and
	; write a zero to it.
		and		r0,r0,#0		; cannot use LDI which does an or operation
		bra		.st1
.st2:
		ldi		r2,#$AA
		sb		r2,LEDS			; write to LEDs
		bra		.st2

	; First thing to do, LED status indicates core at least hit the reset
	; vector.
.st1:
		ldi		r2,#$FF
		sb		r2,LEDS			; write to LEDs

		; set trap vector
		ldi		r1,#$FFFC0000
		csrrw	r0,#$30,r1
		ldi		r1,#__BrkHandler6
		csrrw	r0,#$36,r1			// tvec[6]
		ldi		sp,#__brk_stack+4088
		sw		r0,_milliseconds
		call	_init_memory_management
		call	_FMTK_Initialize
		call	_InitPIT
		call	_InitPIC
		
		; Enable interrupts
		sei		#0
		
		ldi		r1,#$00000		; turn on SMT use $10000
		csrrs	r0,#0,r1
		add		r0,r0,#0		; fetch adjustment ramp
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		csrrd	r1,#$044,r0		; which thread is running ?
		bfextu	r1,r1,#24,#24	
		bne		r1,r0,.st2

		call	calltest3

;		ldi		r1,#16
;		vmov	vl,r1
;		ldi		r1,#$FFFF
;		vmov	vm0,r1
;		sync
;		lv		v1,vec1data
;		lv		v2,vec2data
;		vadd	v3,v1,v2,vm0

		ldi		r1,#MEDBLUE	
		sh		r1,bkcolor		; set text background color
		ldi		r1,#WHITE
		sh		r1,fgcolor		; set foreground color

	ldi		r1,#$AAAA5555	; pick some data to write
	ldi		r3,#0
	ldi		r4,#start1
start1:
	shr		r2,r1,#12
	sb		r2,LEDS			; write to LEDs
	add		r1,r1,#1
	add		r3,r3,#1
	cmp		r2,r3,#10	; stop after a few cycles
;	bne		r2,r0,r4

	; Initialize PRNG
		sw		r0,_randStream
		ldi		r6,#$FFDC0000
		sh		r0,$0C04[r6]			; select stream #0
		ldi		r1,#$88888888
		sh		r1,$0C08[r6]			; set initial m_z
		ldi		r1,#$01234567
		sh		r1,$0C0C[r6]			; set initial m_w

		ldi		r2,#6
		sb		r2,LEDS			; write to LEDs
		jal		r29,clearTxtScreen
		ldi		r4,#$0025
		sb		r4,LEDS
_StartApp:
		jmp		_BIOSMain
start3:
		bra		start3

brkrout:
;		sub		sp,sp,#16
;		sw		r1,[sp]			; save off r1
;		sw		r23,8[sp]		; save off assembler's working reg
		add		r0,r0,#0
	; Set the interrupt level back to the interrupting level
	; to allow nesting higher priority interrupts
		csrrd	r1,#$044,r0
		bfextu	r1,r1,#40,#42
		;sei		r1
		lh		r1,_milliseconds
		add		r1,r1,#1
		sh		r1,_milliseconds
		ldi		r1,#$20000		; sequence number reset bit
		csrrs	r0,#0,r1		; pulse sn reset bit
		add		r0,r0,#0		; now a ramp of instructions
		add		r0,r0,#0		; that don't depend on sequence
		add		r0,r0,#0		; number to operate properly
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
		add		r0,r0,#0
;		lw		r1,[sp]			; get r1 back
;		lw		r23,8[sp]
;		add		sp,sp,#16
		rti

calltest:
		sw		r1,$FF400000		; 1
		add		r1,r1,#2			; 2
		lw		r1,$FF400000		; 3
		ret

calltest1:
		sub		sp,sp,#8
		sw		lr,[sp]
		call	calltest
		lw		lr,[sp]
		add		sp,sp,#8
		ret

calltest2:
		sub		sp,sp,#8
		sw		lr,[sp]
		call	calltest1
		lw		lr,[sp]
		add		sp,sp,#8
		ret

calltest3:
		sub		sp,sp,#8
		sw		lr,[sp]
		call	calltest2
		lw		lr,[sp]
		add		sp,sp,#8
		ret

.include ""

;------------------------------------------------------------------------------
; Set400x300 video mode.
;------------------------------------------------------------------------------

_Set400x300:
		sub		sp,sp,#8
		sw		r6,[sp]
		ldi		r6,#AVIC
		ldi		r1,#$0190012C	; 400x300
		sh		r1,$7E8[r6]
		ldi		r1,#$00320001	; 50 strips per line
		sh		r1,$7F0[r6]		; set lowres = divide by 2
		lw		r6,[sp]
		add		sp,sp,#8
		ret

;------------------------------------------------------------------------------
; Get a random number, and generate the next number.
;
; Parameters:
;	r18 = random stream number.
; Returns:
;	r1 = random 32 bit number.
;------------------------------------------------------------------------------

_GetRand:
		sh		r18,$FFDC0C04	; set the stream
		nop						; delay a wee bit
		lhu		r1,$FFDC0C00	; get a number
		sh		r0,$FFDC0C00	; generate next number
		ret

;------------------------------------------------------------------------------
; Fill the display memory with bands of color.
;------------------------------------------------------------------------------

_ColorBandMemory2:
		sub		sp,sp,#24
		sw		r1,[sp]
		sw		r2,8[sp]
		sw		r6,16[sp]
		ldi		r2,#7
		sb		r2,LEDS			; write to LEDs
		ldi		r6,#$100000
		mov		r18,r0
		call	_GetRand
.0002:
		sc		r1,[r6]
		sb		r1,LEDS
		add		r6,r6,#2
		and		r2,r6,#$3FF
		bne		r2,r0,.0001
		mov		r18,r0
		call	_GetRand
.0001:
		cmpu	r2,r6,#$200000
		blt		r2,r0,.0002
		ldi		r2,#8
		sb		r2,LEDS			; write to LEDs
		lw		r1,[sp]
		lw		r2,8[sp]
		lw		r6,16[sp]
		ret		#24

;------------------------------------------------------------------------------
; Copy font to AVIC ram
;
;------------------------------------------------------------------------------

_BootCopyFont:
		sub		$sp,$sp,#24
		sw		$r2,[$sp]
		sw		$r3,8[$sp]
		sw		$r6,16[$sp]
		ldi		r1,#$0004
		sb		r1,LEDS
		ldi		r6,#AVIC

		; Setup font table
		ldi		r1,#$1FFFEFF0
		sh		r1,$6F0[r6]			; set font table address
		sh		r0,$6F4[r6]			; set font id (0)
		ldi		r1,#%10000111000001110000000000000000	; set font fixed, width, height = 8
		sh		r1,$1FFFEFFC
		ldi		r1,#$1FFFF000		; set bitmap address (directly follows font table)
		sh		r1,$1FFFEFF4

		ldi		r6,#font8
		ldi		r2,#127				; 128 chars @ 8 bytes per char
.0001:
		lw		r3,[r6+r2*8]
		sw		r3,[r1+r2*8]
		dbnz	r2,.0001
		ldi		r1,#$0005
		sb		r1,LEDS
		lw		$r2,[$sp]
		lw		$r3,8[$sp]
		lw		$r6,16[$sp]
		ret		#24

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; DispChar:
;
; Display character at cursor position. The current foreground color and
; background color are used.
;
; Parameters:
;	r18			character to display
; Returns:
;	<none>
; Registers Affected:
;	<none>
;------------------------------------------------------------------------------

_DispChar:
		sub		$sp,$sp,#32
		sw		$r2,[$sp]
		sw		$r3,8[$sp]
		sw		$r6,16[$sp]
		sw		$r29,24[$sp]
		
		ldi		r6,#AVIC
		ldi		r4,#1016
.0001:			
									; wait for character que to empty
		lhu		r2,$6E8[r6]			; read character queue index into r2
		bgtu	r2,r4,.0001			; allow up 24 entries to be in progress	

		lh		r3,fgcolor
		sh		r3,$6E0[r6]
		ldi		r3,#12				; 12 = set pen color
		sh		r3,$6E4[r6]
		sh		r0,$6E8[r6]			; queue

		lh		r3,bkcolor
		sh		r3,$6E0[r6]
		ldi		r3,#13				; 13 = set fill color
		sh		r3,$6E4[r6]
		sh		r0,$6E8[r6]			; queue

		lhu		r3,_DBGCursorCol
		shl		r3,r3,#19			; multiply by eight and convert to fixed (multiply by 65536)
		sh		r3,$6E0[r6]
		ldi		r3,#16				; 16 = set X0 pos
		sh		r3,$6E4[r6]
		sh		r0,$6E8[r6]			; queue

		lhu		r3,_DBGCursorRow
		shl		r3,r3,#19
		sh		r3,$6E0[r6]
		ldi		r3,#17				; 17 = set Y0 pos
		sh		r3,$6E4[r6]
		sh		r0,$6E8[r6]			; queue

		sh		r18,$6E0[r6]		; data = character code
		ldi		r3,#0				; 0 = draw character
		sh		r3,$6E4[r6]
		sh		r0,$6E8[r6]			; queue

		call	_SyncCursorPos
		lw		$r2,[$sp]
		lw		$r3,8[$sp]
		lw		$r6,16[$sp]
		lw		$r29,24[$sp]
		ret		#32

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_SyncCursorPos:
		sub		$sp,$sp,#24
		sw		$r2,[$sp]
		sw		$r3,8[$sp]
		sw		$r6,16[$sp]
		ldi		r6,#AVIC
		lhu		r2,_DBGCursorCol
		lhu		r3,_DBGCursorRow
		shl		r3,r3,#3
		add		r3,r3,#28
		shl		r3,r3,#16
		shl		r2,r2,#3
		add		r2,r2,#256
		or		r2,r2,r3
		sh		r2,$408[r6]			;
		lw		$r2,[$sp]
		lw		$r3,8[$sp]
		lw		$r6,16[$sp]
		ret		#24

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_EnableCursor:
		push	r2
		push	r3
		push	r6
		
		ldi		r6,#AVIC
		ldi		r2,#$FFFFFFFF
		sh		r2,$7B0[a6]		; enable sprite #0
		pop		r6
		pop		r3
		pop		r2
		ret

;----------------------------------------------------------------------------
; Setup the sprite color palette. The palette is loaded with random colors.
;----------------------------------------------------------------------------

_SetCursorPalette:
		sub		sp,sp,#24
		sw		r2,[sp]
		sw		r6,8[sp]
		sw		r7,16[sp]
		ldi		r6,#AVIC
		ldi		r2,#WHITE
		sh		r2,4[r6]				; palette entry #1
		ldi		r2,#%111110000000000	; RED
		sh		r2,8[r6]				; palette entry #2
		ldi		r7,#12
.0001:
		mov		r18,r0
		call	_GetRand
		and		r1,r1,#$7FFF
		sh		r1,[r6+r7]
		add		r7,r7,#4
		cmp		r2,r7,#$400
		blt		r2,r0,.0001
		lw		r2,[sp]
		lw		r6,8[sp]
		lw		r7,16[sp]
		add		sp,sp,#24
		ret
		
;----------------------------------------------------------------------------
; Establish a default image for all the sprites.
;----------------------------------------------------------------------------

_SetCursorImage:
		push	r2
		push	r3
		push	r4
		push	r5
		push	r6
		push	r7

		ldi		r6,#AVIC
		ldi		r7,#$400
.0002:
		ldi		r2,#$1FFEE000
		sh		r2,[r6+r7]		; sprite image address
		add		r7,r7,#4		; advance to next field
		ldi		r2,#30*32			; number of pixels
		sh		r2,[r6+r7]		; 
		add		r7,r7,#12		; next sprite
		cmp		r2,r7,#$600
		bne		r2,r0,.0002

		ldi		r2,#$1FFEE000
		ldi		r3,#_XImage
		ldi		r5,#30
.0001:
		lw		r4,8[r3]	; swap the order of the words around
		sw		r4,[r2]
		lw		r4,[r3]
		sw		r4,8[r2]
		add		r3,r3,#16
		add		r2,r2,#16
		sub		r5,r5,#1
		bne		r5,r0,.0001

		pop		r7		
		pop		r6
		pop		r5
		pop		r4
		pop		r3
		pop		r2
		ret

	align	8
_CursorBoxImage:
	dw		$1111111111000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000000001000000,$00
	dw		$1000110001000000,$00
	dw		$1111111111000000,$00

; Higher order word appears later in memory but is displayed first. So the
; order of these words are swapped around above. To make it convenient to
; define the sprite image.

_XImage:
	dw		$1122222222222222,$2222222222222211
	dw		$2110000000000000,$0000000000000112
	dw		$2011000000000000,$0000000000001102
	dw		$2001100000000000,$0000000000011002
	dw		$2000110000000000,$0000000000110002
	dw		$2000011000000000,$0000000001100002
	dw		$2000001100000000,$0000000011000002
	dw		$2000000110000000,$0000000110000002
	dw		$2000000011000000,$0000001100000002
	dw		$2000000001100000,$0000011000000002
	dw		$2000000000110000,$0000110000000002
	dw		$2000000000011009,$0901100000000002
	dw		$2000000000001100,$0011000000000002
	dw		$2000000000000110,$0110000000000002
	dw		$2000000000000011,$1100000000000002
	dw		$2000000000000011,$1100000000000002
	dw		$2000000000000110,$0110000000000002
	dw		$2000000000001100,$0011000000000002
	dw		$2000000000011009,$0901100000000002
	dw		$2000000000110000,$0000110000000002
	dw		$2000000001100000,$0000011000000002
	dw		$2000000011000000,$0000001100000002
	dw		$2000000110000000,$0000000110000002
	dw		$2000001100000000,$0000000011000002
	dw		$2000011000000000,$0000000001100002
	dw		$2000110000000000,$0000000000110002
	dw		$2001100000000000,$0000000000011002
	dw		$2011000000000000,$0000000000001102
	dw		$2110000000000000,$0000000000000112
	dw		$1122222222222222,$2222222222222211

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_RandomizeSpritePositions2:
		push	r1
		push	r6
		push	r7
		ldi		r6,#AVIC
		ldi		r7,#$408
.0001:
		mov		r18,r0
		call	_GetRand
		and		r1,r1,#$00FF00FF
		add		r1,r1,#$000E0080	; add +28 to y and +256 to x
		sh		r1,[r6+r7]
		add		r7,r7,#$10			; advance to next sprite
		cmp		r1,r7,#$5F8
		blt		r1,r0,.0001
		pop		r7
		pop		r6
		pop		r1
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
clearTxtScreen:
		ldi		r4,#$0024
		sb		r4,LEDS
		ldi		r1,#$FFD00000	; text screen address
		ldi		r2,#24		; number of chars 2480 (80x31)
		ldi		r3,#%000010000_111111111_0000100000
.cts1:
		sh		r3,[r1]
		add		r1,r1,#4
		sub		r2,r2,#1
		bne		r2,r0,.cts1
		ret

;===============================================================================
;===============================================================================
;===============================================================================
;===============================================================================
	align	16
font8:
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $00
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $04
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $08
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $0C
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $10
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $14
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $18
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; $1C
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; 
	db	$00,$00,$00,$00,$00,$00,$00,$00	; SPACE
	db	$18,$18,$18,$18,$18,$00,$18,$00	; !
	db	$6C,$6C,$00,$00,$00,$00,$00,$00	; "
	db	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	; #
	db	$18,$3E,$60,$3C,$06,$7C,$18,$00	; $
	db	$00,$66,$AC,$D8,$36,$6A,$CC,$00	; %
	db	$38,$6C,$68,$76,$DC,$CE,$7B,$00	; &
	db	$18,$18,$30,$00,$00,$00,$00,$00	; '
	db	$0C,$18,$30,$30,$30,$18,$0C,$00	; (
	db	$30,$18,$0C,$0C,$0C,$18,$30,$00	; )
	db	$00,$66,$3C,$FF,$3C,$66,$00,$00	; *
	db	$00,$18,$18,$7E,$18,$18,$00,$00	; +
	db	$00,$00,$00,$00,$00,$18,$18,$30	; ,
	db	$00,$00,$00,$7E,$00,$00,$00,$00	; -
	db	$00,$00,$00,$00,$00,$18,$18,$00	; .
	db	$03,$06,$0C,$18,$30,$60,$C0,$00	; /
	db	$3C,$66,$6E,$7E,$76,$66,$3C,$00	; 0
	db	$18,$38,$78,$18,$18,$18,$18,$00	; 1
	db	$3C,$66,$06,$0C,$18,$30,$7E,$00	; 2
	db	$3C,$66,$06,$1C,$06,$66,$3C,$00	; 3
	db	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00	; 4
	db	$7E,$60,$7C,$06,$06,$66,$3C,$00	; 5
	db	$1C,$30,$60,$7C,$66,$66,$3C,$00	; 6
	db	$7E,$06,$06,$0C,$18,$18,$18,$00	; 7
	db	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
	db	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
	db	$00,$18,$18,$00,$00,$18,$18,$00	; :
	db	$00,$18,$18,$00,$00,$18,$18,$30	; ;
	db	$00,$06,$18,$60,$18,$06,$00,$00	; <
	db	$00,$00,$7E,$00,$7E,$00,$00,$00	; =
	db	$00,$60,$18,$06,$18,$60,$00,$00	; >
	db	$3C,$66,$06,$0C,$18,$00,$18,$00	; ?
	db	$7C,$C6,$DE,$D6,$DE,$C0,$78,$00	; @
	db	$3C,$66,$66,$7E,$66,$66,$66,$00	; A
	db	$7C,$66,$66,$7C,$66,$66,$7C,$00	; B
	db	$1E,$30,$60,$60,$60,$30,$1E,$00	; C
	db	$78,$6C,$66,$66,$66,$6C,$78,$00	; D
	db	$7E,$60,$60,$78,$60,$60,$7E,$00	; E
	db	$7E,$60,$60,$78,$60,$60,$60,$00	; F
	db	$3C,$66,$60,$6E,$66,$66,$3E,$00	; G
	db	$66,$66,$66,$7E,$66,$66,$66,$00	; H
	db	$3C,$18,$18,$18,$18,$18,$3C,$00	; I
	db	$06,$06,$06,$06,$06,$66,$3C,$00	; J
	db	$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00	; K
	db	$60,$60,$60,$60,$60,$60,$7E,$00	; L
	db	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00	; M
	db	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	; N
	db	$3C,$66,$66,$66,$66,$66,$3C,$00	; O
	db	$7C,$66,$66,$7C,$60,$60,$60,$00	; P
	db	$78,$CC,$CC,$CC,$CC,$DC,$7E,$00	; Q
	db	$7C,$66,$66,$7C,$6C,$66,$66,$00	; R
	db	$3C,$66,$70,$3C,$0E,$66,$3C,$00	; S
	db	$7E,$18,$18,$18,$18,$18,$18,$00	; T
	db	$66,$66,$66,$66,$66,$66,$3C,$00	; U
	db	$66,$66,$66,$66,$3C,$3C,$18,$00	; V
	db	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	; W
	db	$C3,$66,$3C,$18,$3C,$66,$C3,$00	; X
	db	$C3,$66,$3C,$18,$18,$18,$18,$00	; Y
	db	$FE,$0C,$18,$30,$60,$C0,$FE,$00	; Z
	db	$3C,$30,$30,$30,$30,$30,$3C,$00	; [
	db	$C0,$60,$30,$18,$0C,$06,$03,$00	; \
	db	$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00	; ]
	db	$10,$38,$6C,$C6,$00,$00,$00,$00	; ^
	db	$00,$00,$00,$00,$00,$00,$00,$FE	; _
	db	$18,$18,$0C,$00,$00,$00,$00,$00	; `
	db	$00,$00,$3C,$06,$3E,$66,$3E,$00	; a
	db	$60,$60,$7C,$66,$66,$66,$7C,$00	; b
	db	$00,$00,$3C,$60,$60,$60,$3C,$00	; c
	db	$06,$06,$3E,$66,$66,$66,$3E,$00	; d
	db	$00,$00,$3C,$66,$7E,$60,$3C,$00	; e
	db	$1C,$30,$7C,$30,$30,$30,$30,$00	; f
	db	$00,$00,$3E,$66,$66,$3E,$06,$3C	; g
	db	$60,$60,$7C,$66,$66,$66,$66,$00	; h
	db	$18,$00,$18,$18,$18,$18,$0C,$00	; i
	db	$0C,$00,$0C,$0C,$0C,$0C,$0C,$78	; j
	db	$60,$60,$66,$6C,$78,$6C,$66,$00	; k
	db	$18,$18,$18,$18,$18,$18,$0C,$00	; l
	db	$00,$00,$EC,$FE,$D6,$C6,$C6,$00	; m
	db	$00,$00,$7C,$66,$66,$66,$66,$00	; n
	db	$00,$00,$3C,$66,$66,$66,$3C,$00	; o
	db	$00,$00,$7C,$66,$66,$7C,$60,$60	; p
	db	$00,$00,$3E,$66,$66,$3E,$06,$06	; q
	db	$00,$00,$7C,$66,$60,$60,$60,$00	; r
	db	$00,$00,$3C,$60,$3C,$06,$7C,$00	; s
	db	$30,$30,$7C,$30,$30,$30,$1C,$00	; t
	db	$00,$00,$66,$66,$66,$66,$3E,$00	; u
	db	$00,$00,$66,$66,$66,$3C,$18,$00	; v
	db	$00,$00,$C6,$C6,$D6,$FE,$6C,$00	; w
	db	$00,$00,$C6,$6C,$38,$6C,$C6,$00	; x
	db	$00,$00,$66,$66,$66,$3C,$18,$30	; y
	db	$00,$00,$7E,$0C,$18,$30,$7E,$00	; z
	db	$0E,$18,$18,$70,$18,$18,$0E,$00	; {
	db	$18,$18,$18,$18,$18,$18,$18,$00	; |
	db	$70,$18,$18,$0E,$18,$18,$70,$00	; }
	db	$72,$9C,$00,$00,$00,$00,$00,$00	; ~
	db	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00	; 

	align	8
tblvect:
	dw	0
	dw	1
	dw	2
	dw	3
	dw	4
	dw	5
	dw	6
	dw	7
	dw	8
	dw	9
	dw	10
	dw	11
	dw	12
	dw	13
	dw	14
	dw	15

vec1data:
	dw	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
vec2data:
	dw	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

.include "c:\Cores5\FT64\trunk\software\c64libc\source\cc64rt.s"
.include "c:\Cores5\FT64\trunk\software\boot\brkrout.asm"
.include "c:\Cores5\FT64\trunk\software\boot\BIOSMain.s"
.include "c:\Cores5\FT64\trunk\software\boot\FloatTest.s"
.include "c:\Cores5\FT64\trunk\software\boot\ramtest.s"
	.align	4096
.include "c:\Cores5\FT64\trunk\software\c64libc\source\stdio.s"
.include "c:\Cores5\FT64\trunk\software\c64libc\source\ctype.s"
.include "c:\Cores5\FT64\trunk\software\c64libc\source\string.s"
.include "c:\Cores5\FT64\trunk\software\c64libc\source\malloc.s"
.include "c:\Cores5\FT64\trunk\software\c64libc\source\prtflt.s"
.include "c:\Cores5\FT64\trunk\software\c64libc\source\FT64\io.s"
	.align	4096
.include "c:\Cores5\FT64\trunk\software\c64libc\source\libquadmath\log10q.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\LockSemaphore.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\UnlockSemaphore.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\console.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\PIT.asm"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\PIC.s"
	.align	4096
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\FMTKc.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\FMTKmsg.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\TCB.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\IOFocusc.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\keybd.s"
	.align	4096
.include "c:\Cores5\FT64\trunk\software\FMTK\source\memmgnt2.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\app.s"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\shell.s"
.include "c:\Cores5\FT64\trunk\software\bootrom\source\video.asm"
.include "c:\Cores5\FT64\trunk\software\bootrom\source\TinyBasicDSD9.asm"

	.align	4096
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\scancodes.asm"
.include "c:\Cores5\FT64\trunk\software\FMTK\source\kernel\fmtk_vars.asm"
