; N4V128Sys bootrom - (C) 2017-2019 Robert Finch, Waterloo
;
; This file is part of FT64v7SoC
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
; FFFF0000 +----------------+
;          |  cmp insn tbl  |
; FFFFFFFF +----------------+
;
;
;
;SUPPORT_DCI	equ		0
;SUPPORT_SMT		equ		0
; SUPPORT_AVIC	equ		1
SUPPORT_BMP		equ		1
;SUPPORT_Tldb		equ		1
;ICACHE_TEST		equ		1

E_BadCallno	equ		-4

ROMBASE		equ		$FFFFFFFFFFFFFFFC0000
IOBASE		equ		$FFFFFFFFFFFFFFD00000
TEXTSCR		equ		$FFFFFFFFFFFFFFD00000
KEYBD		equ		$FFFFFFFFFFFFFFDC0000
LEDS		equ			$FFFFFFFFFFFFFFDC0600
BUTTONS		equ		$FFFFFFFFFFFFFFDC0600
SYSDATA		equ			$FFFFFFFFFFFFFF410000
SCRATCHPAD	equ		$FFFFFFFFFFFFFF400000
SCRATCHMEM	equ		$FFFFFFFFFFFFFF400000
AVIC		equ		$FFFFFFFFFFFFFFDCC000
TC1			equ		$FFFFFFFFFFFFFFD1DF00
I2C			equ		$FFFFFFFFFFFFFFDC0200
PIT			equ		$FFFFFFFFFFFFFFDC1100
PIC			equ		$FFFFFFFFFFFFFFDC0F00
SPRCTRL	equ		$FFFFFFFFFFFFFFDAD000		// sprite controller
BMPCTRL	equ		$FFFFFFFFFFFFFFDC5000

WHITE		equ		$7FFF
MEDBLUE		equ		$000F

; Exception cause codes
TS_IRQ		equ		$9F
GC_EXEC		equ		$9E
GC_STOP		equ		$9D

macro pfi
		brk		255,2,0
endm

macro mGfxCmd (cmd, dat)
		ldt		r3,dat
		ldi		r5,#cmd<<32	
		or		r3,r3,r5
		std		r3,$DC0[r6]
		memdb
		std		r0,$DD0[r6]
		memdb
		bra		.testbr@
		dc		0x1234
.testbr@
endm

			bss
			org		$0
_InvertedPageTable

			bss
			org		SCRATCHPAD + $4000
_inptr				dcd		0
_bsptr				dcd		0		; BASIC storage pointer
_linendx			dcd		0
_dbg_dbctrl		dcd		0
_ssm					dcd		0
_repcount			dcd		0
_curaddr			dcd		0
_cursz				dcd		0
_curfill			dcd		0
_currep				dcd		0
_muol					dcd		0		; max units on line
_bmem					dcd		0		; pointers to memory
_cmem					dcd		0
_hmem					dcd		0
_wmem					dcd		0
_ndx					dcd		0
_col					dcd		0
_osmem				dcd		0
__GCExecPtr		dcd		0
__GCStopPtr		dcd		0
fgcolor				dcd		0
bkcolor				dcd		0
_randStream		dcd		0	
_S19Address		dcd		0
_S19StartAddress	dcd		0
_ExecAddress	dcd		0
_HexChecksum	dcd		0
_DBGCursorCol	dcb		0
_DBGCursorRow	dcb		0
_spinner			dc		0
_cmdbuf				fill.c	48,0
_KeybdID			dc		0
_KeyState1		dcb		0
_KeyState2		dcb		0
_KeyLED				dcb		0
_S19Abort			dcb		0
_S19Reclen		dcb		0
_pti_onoff		dcb		0
_curfmt				dcb		0				; debugger format
			align		8
_RTCBuf				fill.b	96,0
_linebuf			fill.b	96,0	; debugger line buffer
			align		8
_DBGAttr			dco		0
_milliseconds	dcd		0
_pti_rbuf			dcd		0
_pti_wbuf			dcd		0
_pti_rcnt			dcd		0
_pti_wcnt			dcd		0
___garbage_list	dcd	0
_mmu_key			dcd		0
; The following is a C Standard library var for malloc/free
__Aldata			fill.w	2,0
_errno				dcd		0
_sys_pages_available		dcd	0
_brks					fill.w	256,0
_shared_brks	fill.w	256,0
_regfile			fill.w	32,0
_DeviceTable	fill.b	32*104,0

			org		SCRATCHPAD + $BFF8
__brk_stack_top		dcd		0
	
		data
		org		SYSDATA

; Help the assembler out by telling it how many bits are required for code
; addresses
{+
		code	18 bits
		org		ROMBASE			; start of ROM memory space
		jmp		__BrkHandler	; jump to the exception handler
		nop
		org		ROMBASE + $020
		jmp		__BrkHandlerOL01
		nop
		org		ROMBASE + $040
		jmp		__BrkHandlerOL02
		nop
		org		ROMBASE + $060
		jmp		__BrkHandlerOL03
		nop
		org		ROMBASE + $100	; The PC is set here on reset
start2:
	; First thing to do, LED status indicates core at least hit the reset
	; vector.
		ldi		r1,#$AA
		stb		r1,LEDS
		jmp		start			; Comment out this jump to test i-cache
;		jmp		_SieveOfEratosthenes	

		; Built in programs
		org		ROMBASE + $200
		jmp		_monitor
		jmp		_HexLoader
		jmp		_ramtest
		jmp		_SpriteDemo

		; Jump table
		org		ROMBASE + $300
		jmp		_in8
		jmp		_in8u
		jmp		_in16
		jmp		_in16u
		jmp		_in32
		jmp		_in32u
		jmp		_in64
		jmp		_out8
		jmp		_out16
		jmp		_out32
		jmp		_out64
		jmp		_DBGClearScreen
		jmp		_DBGDisplayChar
		jmp		_DBGDisplayString
		jmp		_DBGDisplayStringCRLF
		jmp		_DBGGetKey

ifdef SUPPORT_SMT		
		ldi		r1,#$10000		; turn on SMT use $10000
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
		add		r0,r0,#0
		add		r0,r0,#0
		csrrd	r1,#$044,r0		; which thread is running ?
		bbs		r1,#24,test_icache
		jmp		_SieveOfEratosthenes
endif

ifdef ICACHE_TEST
test_icache:
	; This seems stupid but maybe necessary. Writes to r0 alddays cause it to
	; be loaded with the value zero regardless of the value written. Readback
	; should then alddays be a zero. The only case it might not be is at power
	; on. At power on the reg should be zero, but let's not assume that and
	; write a zero to it.

		and		r0,r0,#0		; cannot use LDI which does an or operation
		; set trap vector
		ldi		r1,#ROMBASE
		csrrw	r0,#$30,r1
		ldi		$sp,#$10000000+$7BF8	; set stack pointer
		sei		#0

	; Seed random number generator
		call	_InitPRNG
.st4:
	; Get a random number
		stt		r0,$0C04[r6]	; set the stream
		memdb
		nop						; delay a wee bit
		ldtu		r1,$0C00[r6]	; get a number
		stt		r0,$0C00[r6]	; generate next number

	; convert to random address
	;	mul		r1,r1,#5
		and		r1,r1,#$1FFC
		add		r1,r1,#SCRATCHPAD+$1000	; scratchram address
		
	; Fill an area with test code
		ldi		r2,#(.st6-.st2)/4		; number of ops - 1
		ldi		r3,#.st2		; address of test routine copy
.st3:
		ldtu		r4,[r3+r2*4]	; move from boot rom to
		stt		r4,[r1+r2*4]	; scratch ram
		sub		r2,r2,#1
		bne		r2,r0,.st3
		; Do the last char copy
		ldtu		r4,[r3+r2*4]	; move from boot rom to
		stt		r4,[r1+r2*4]	; scratch ram
	
	; Now jump to the test code
		cache	#3,[r1]			; invalidate the cache

	; The following is important to allow the last few store
	; operations to complete before trying to execute code.
		sync

		jal		r29,[r1]
		ldi		r2,#14			; this is the value that should be returned
		xor		r1,r1,r2
		bne		r1,r0,.st5
		bra		.st4

	; Display fail code
.st5:
		ldi		r1,#$FA
		stb		r1,$0600[r6]
		bra		.st5

; Test code accumulates for 16 instructions, sum should be 14
		align	4
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
.st6:
endif

start:
	; This seems stupid but maybe necessary. Writes to r0 alddays cause it to
	; be loaded with the value zero regardless of the value written. Readback
	; should then alddays be a zero. The only case it might not be is at power
	; on. At power on the reg should be zero, but let's not assume that and
	; write a zero to it.
		and		r0,r0,#0		; cannot use LDI which does an or operation
		ldi		$sp,#SCRATCHPAD+$CDF8	; set stack pointer
		ldi		$xlr,#st_except
		
		call	_SetTrapVector
		call	_Delay2s
		ldi		$r1,#$FFFF003F0041
		sto		$r1,TEXTSCR
		sto		$r1,TEXTSCR+8
		sto		$r1,TEXTSCR+16
ifdef TEST_TCRAM
		call  _TestTCRam
endif
		;call	_CopyPreinitData
ifdef SUPPORT_DCI
		call	_InitCompressedInsns
endif
+}
start4:
		ldi		r1,#$0040FFFF000F0000		; set zorder $40, white text, blue background
		sto		r1,_DBGAttr
		call	_DBGClearScreen
start2b:
		ldi		$r1,#$2B
		stb		$r1,LEDS
		call	_DBGHomeCursor
;		call	_ROMChecksum
		push	#MsgBoot
		call	_DBGDisplayAsciiStringCRLF
		ldi		$r1,#7
		stb		$r1,LEDS

		call	_SetupDevices
		call	_prng_init
;		call  _RandomizeSpritePositions2
		call	_i2c_init
;		call	_KeybdInit
		std		r0,_milliseconds
		call	_SetGCHandlers
		call	_InitPIC
		call	_InitPIT
		brk		240,2,0
		; Enable interrupts
;		sei		#0

		call	_rtc_read
		; The following must be after the RTC is read
;		call	_init_memory_management
		ldi		r1,#$10				; set operating level 01 (bits 4,5)
;		csrrs	r0,#$044,r1
		call	_SetSpritePalette
		call  _SetSpriteImage
		ldi		$a0,#-1				; enable all sprites
		call	_EnableSprites
		call	_RandomizeSpritePositions2
		call	_monitor
		call	_FMTK_Initialize
		ldi		$r1,#8
		stb		$r1,LEDS
.st2:
		ldi		r2,#$AA
		stb		r2,LEDS			; write to LEDs
		bra		.st2
start5:
		bra		start5

;		ldi		r1,#16
;		vmov	vl,r1
;		ldi		r1,#$FFFF
;		vmov	vm0,r1
;		sync
;		lv		v1,vec1data
;		lv		v2,vec2data
;		vadd	v3,v1,v2,vm0

		ldi		r1,#MEDBLUE	
		stt		r1,bkcolor		; set text background color
		ldi		r1,#WHITE
		stt		r1,fgcolor		; set foreground color

start3:
		bra		start3

st_except:
		bra		st_except

brkrout:
;		sub		sp,sp,#16
;		std		r1,[sp]			; save off r1
;		std		r23,8[sp]		; save off assembler's working reg
		add		r0,r0,#0
	; Set the interrupt level back to the interrupting level
	; to allow nesting higher priority interrupts
		csrrd	r1,#$044,r0
		shr		r1,r1,#40
		and		r1,r1,#7
		;sei		r1
		ldt		r1,_milliseconds
		add		r1,r1,#1
		stt		r1,_milliseconds
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
;		ldd		r1,[sp]			; get r1 back
;		ldd		r23,8[sp]
;		add		sp,sp,#16
		rti

StartHere:
;		call	_InitTldb
		call	_Set400x300
ifdef SUPPORT_AVIC
		call	_BootCopyFont
endif
		call	_InitPRNG
		call	_SetCursorPalette
		call	_SetCursorImage
		call	_ColorBandMemory2
.0001:
		jmp		.0001
		jmp		_BIOSMain

ifdef SUPPORT_DCI
;------------------------------------------------------------------------------
; Copy compressed instruction table in processor's compressed instruction
; table.
;------------------------------------------------------------------------------
; can't have compressed instructions here
{+
_InitCompressedInsns:
		ldd		$r3,cmp_insns		; get compressed instruction count (256)
		beq		$r3,$r0,.0002		; make sure we don't loop 2^64 times
		ldi		$r2,#8					; instructions begin offset by 8
.0001:
		ldd		$r1,cmp_insns[$r2]
		std		$r1,$FFFEFFF8[$r2]
		add		$r2,$r2,#8
		sub		$r3,$r3,#1
		bne		$r3,$r0,.0001
.0002:
		ret
+}
endif

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_ROMChecksum:
		push	$lr
		ldi		$r2,#ROMBASE
		ldt		$r1,196604[$r2]
		ldi		$r4,#0					; r4 = checksum total
		bra		.0004
.0001:
		sub		$r1,$r1,#1
		and		$r5,$r1,#$ff
		bne		$r5,$r0,.0003
		push	$r1							; push temps
		push	$r2
		push	$r4
		push	#'*'
		call	_DBGDisplayChar
		ldd		$r4,[$sp]
		ldd		$r2,10[$sp]
		ldd		$r1,20[$sp]
		add		$sp,$sp,#30
.0003:
		ldb		$r3,[$r2+$r1]
		add		$r4,$r4,$r3
.0004:
		bgt		$r1,$r0,.0001
		ldt		$r1,196600[$r2]
		beq		$r1,$r4,.0002
		push	$r4
		push	#msgBadChecksum
		call	_DBGDisplayAsciiStringCRLF
		ldd		$r1,[$sp]
		add		$sp,$sp,#10
.0002:
		push	#' '
		push	#0
		push	#8
		push	$r1
		call	_puthexnum
		call	_DBGCRLF
		ldd		$lr,[$sp]
		ret		#10

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
_CopyPreinitData:
		ldi		$r1,#begin_init_data
		ldi		$r2,#end_init_data
		ldi		$r3,#SYSDATA
.0001:
		ldo		$r4,[$r1]
		sto		$r4,[$r3]
		shr		$r5,$r1,#12
		stb		$r5,LEDS
		add		$r1,$r1,#8
		add		$r3,$r3,#8
		bltu	$r1,$r2,.0001
		ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

_SetTrapVector:
		ldi		r1,#$FFFFFFFFFFFC0000
		csrrw	r0,#$30,r1
		ldi		r1,#__BrkHandlerOL01
		csrrw	r0,#$31,r1			; tvec[1]
		ldi		r1,#__BrkHandlerOL02
		csrrw	r0,#$32,r1			; tvec[2]
		ldi		r1,#__BrkHandlerOL03
		csrrw	r0,#$33,r1			; tvec[3]
		ret

;------------------------------------------------------------------------------
; set garbage handler vectors
;------------------------------------------------------------------------------

_SetGCHandlers:
		ldi		$r1,#__GCExec
		std		$r1,__GCExecPtr
		ldi		$r1,#__GCStop
		std		$r1,__GCStopPtr
		ret
		
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

_Delay2s:
		ldi			$r1,#3;000000
.0001:
		shr			$r2,$r1,#16
		stb			$r2,LEDS
		sub			$r1,$r1,#1
		bne			$r1,$r0,.0001
		ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ifdef TEST_TCRAM
_TestTCRam:
		ldi			$r1,#$28
		stb			$r1,LEDS
		ldi			$r6,#TEXTSCR
		ldi			$r1,#2048
		ldi			$r7,#ROMBASE
.0001:
		ldd			$r2,[$r7]
		add			$r7,$r7,#8
		std			$r2,[$r6]
		add			$r6,$r6,#8
		stb			$r1,LEDS
		sub			$r1,$r1,#1
		bne			$r1,$r0,.0001

		ldi			$r1,#$29
		stb			$r1,LEDS
		ldi			$r6,#TEXTSCR
		ldi			$r7,#ROMBASE
		ldi			$r8,#TEXTSCR
		ldi			$r1,#2048
.0004:
		ldd			$r2,[$r6]
		add			$r6,$r6,#8
		ldd			$r3,[$r7]
		add			$r7,$r7,#8
		beq			$r2,$r3,.0002
		ldi			$r4,#$FFFFF80F0020	; Red background, white text
		bra			.0003
.0002:
		ldi			$r4,#$FFFF07CF0020	; Green background, white text
.0003:
		std			$r4,[$r8]
		add			$r8,$r8,#8
		sub			$r1,$r1,#1
		bne			$r1,$r0,.0004
		ldi			$r1,#$2A
		stb			$r1,LEDS
		ret
endif
		
;------------------------------------------------------------------------------
; Initialize the Tldb with entries for the BIOS rom and variables.
;------------------------------------------------------------------------------
ifdef SUPPORT_Tldb
_InitTldb:
		; Set ASID to 1
		sub				sp,sp,#10
		std				lr,[sp]
		ldi				$r18,#1
		call			_SetASID

		tldbwrreg 	MA,$r0			; clear Tldb miss address register
		ldi				$r1,#2			; 2 wired registers
		tldbwrreg	Wired,$r1

		; setup the first translation
		; virtual page $F..FFC0000 maps to physical page $F..FFC0000
		; This places the BIOS ROM at $FFFFxxxx in the memory map
		ldi				$r1,#%1_00_010_10000_001_111	; _P_GDUSA_C_RWX
		; ASID=1, G=1,Read/Write/Execute=111, 128kiB pages
		tldbwrreg	ASID,r1
		ldi				$r1,#$FFFFFFFFFFFFFFFE
		tldbwrreg	VirtPage,$r1
		tldbwrreg	PhysPage,$r1
		tldbwrreg	Index,$r0		; select way #0
		tldbwi									; write to Tldb entry group #0 with hold registers

		; setup second translation
		; virtual page 0 maps to physical page 0
		ldi				$r1,#%1_00_010_10000_001_111	; _P_GDUSA_C_RWX
		; ASID=1, G=1,Read/Write/Execute=111, 128kiB pages
		tldbwrreg	ASID,$r1
		tldbwrreg	VirtPage,$r0
		tldbwrreg	PhysPage,$r0
		ldi				$r1,#16			; select way#1
		tldbwrreg	Index,$r1		
		tldbwi						; write to Tldb entry group #0 with hold registers

		; turn on the Tldb
;		tldben
		ldd			lr,[sp]
		ret			#10
endif

;------------------------------------------------------------------------------
; Set400x300 video mode.
; *
;------------------------------------------------------------------------------
ifdef SUPPORT_AVIC
_Set400x300:
		sub		$sp,$sp,#10
		std		$r6,[sp]
		ldi		$r6,#AVIC
		ldi		$r1,#$0190012C	; 400x300
		sto		$r1,$FD0[r6]
		ldi		$r1,#$00328001	; 50 strips per line, 4 bit z-order
		sto		$r1,$FE0[r6]		; set lowres = divide by 2
		ldd		$r6,[sp]
		add		$sp,$sp,#10
		ret
endif
ifdef SUPPORT_BMP
_Set400x300:
		sub		$sp,$sp,#40
		std		$r6,[sp]
		std		$r5,10[sp]
		std		$r7,20[sp]
		std		$r8,30[sp]
		ldi		$r6,#$AA
		stb		$r6,LEDS
		ldi		$r6,#BMPCTRL
		ldi		$r7,#bmp_reg_val
		ldi		$r8,#4						; four registers to update
		ldi		$r5,#0					
.0001:
		ldo		$r1,[$r7+$r5*8]
		sto		$r1,[$r6+$r5*8]
		add		$r5,$r5,#1
		bne		$r5,$r8,.0001
		ldd		$r6,[sp]
		ldd		$r5,10[sp]
		ldd		$r7,20[sp]
		std		$r8,30[sp]
		ret		#40

		align	8
bmp_reg_val:
		dco		$0000000000120301
		dco		$001B00DA012C0190
		dco		$0000000000040000
		dco		$0000000000080000
endif


;------------------------------------------------------------------------------
; Initialize PRNG
;------------------------------------------------------------------------------
_InitPRNG:
		std		r0,_randStream
		ldi		r6,#$FFFFFFFFFFDC0000
		stt		r0,$0C04[r6]			; select stream #0
		memdb
		ldi		r1,#$88888888
		stt		r1,$0C08[r6]			; set initial m_z
		memdb
		ldi		r1,#$01234567
		stt		r1,$0C0C[r6]			; set initial m_w
		memdb
		ret

;------------------------------------------------------------------------------
; Fill the display memory with bands of color.
;------------------------------------------------------------------------------

_ColorBandMemory2:
		sub		sp,sp,#40
		std		r1,[sp]
		std		r2,10[sp]
		std		r6,20[sp]
		std		lr,30[sp]
		ldi		r2,#7
		stb		r2,LEDS			; write to LEDs
		ldi		r6,#$200000
		mov		r18,r0
		call	_GetRand
.0002:
		stw		r1,[r6]
		stb		r1,LEDS
		add		r6,r6,#2
		and		r2,r6,#$3FF
		bne		r2,r0,.0001
		mov		r18,r0
		call	_GetRand
.0001:
		sltu	r2,r6,#$240000
		bne		r2,r0,.0002
		ldi		r2,#8
		stb		r2,LEDS			; write to LEDs
		ldd		r1,[sp]
		ldd		r2,10[sp]
		ldd		r6,20[sp]
		ldd		lr,30[sp]
		ret		#40

;------------------------------------------------------------------------------
; Copy font to AVIC ram
; *
;------------------------------------------------------------------------------

_BootCopyFont:
		sub		$sp,$sp,#24
		std		$r2,[$sp]
		std		$r3,8[$sp]
		std		$r6,16[$sp]
		ldi		$r1,#$0004
		stb		$r1,LEDS
		ldi		$r6,#AVIC

		; Setup font table
		ldi		$r1,#$1FFFEFF0
		std		$r1,$DE0[r6]			; set font table address
		std		$r0,$DE8[r6]			; set font id (0)
		ldi		$r1,#%10000111000001110000000000000000	; set font fixed, width, height = 8
		stt		$r1,$1FFFEFF4
		ldi		$r1,#$1FFFF000		; set bitmap address (directly follows font table)
		stt		$r1,$1FFFEFF0

		ldi		$r6,#font8
		ldi		$r2,#127				; 128 chars @ 8 bytes per char
.0001:
		ldd		$r3,[$r6+$r2*8]
		std		$r3,[$r1+$r2*8]
		sub		$r2,$r2,#1
		bne		$r2,$r0,.0001
		ldd		$r3,[$r6+$r2*8]
		std		$r3,[$r1+$r2*8]
		ldi		$r1,#$0005
		stb		$r1,LEDS
		ldd		$r2,[$sp]
		ldd		$r3,8[$sp]
		ldd		$r6,16[$sp]
		ret		#24

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
; *
;------------------------------------------------------------------------------

_DispChar:
		sub		$sp,$sp,#32
		std		$r2,[$sp]
		std		$r3,8[$sp]
		std		$r6,16[$sp]
		std		$r29,24[$sp]
		
		ldi		r6,#AVIC
		ldi		r4,#1016
.0001:			
									; wait for character que to empty
		ldtu		r2,$DD0[r6]			; read character queue index into r2
		memdb
		bgtu	r2,r4,.0001			; allow up 24 entries to be in progress	
		
		mGfxCmd (12,fgcolor)
		mGfxCmd (13,bkcolor)
		mGfxCmd (16,_DBGCursorCol)
	
		ldt		r3,fgcolor
		ldi		r5,#12<<32			; 12 = set pen color
		or		r3,r3,r5
		std		r3,$DC0[r6]
		memdb
		std		r0,$DD0[r6]			; queue
		memdb

		ldt		r3,bkcolor
		ldi		r5,#13<<32			; 13 = set fill color
		or		r3,r3,r5
		std		r3,$DC0[r6]
		memdb
		std		r0,$DD0[r6]			; queue
		memdb

		ldtu		r3,_DBGCursorCol
		ldi		r5,#16<<32				; 16 = set X0 pos
		shl		r3,r3,#19			; multiply by eight and convert to fixed (multiply by 65536)
		or		r3,r3,r5
		std		r3,$DC0[r6]
		memdb
		std		r0,$DD0[r6]			; queue
		memdb

		ldtu		r3,_DBGCursorRow
		ldi		r5,#17<<32				; 17 = set Y0 pos
		shl		r3,r3,#19
		or		r3,r3,r5
		std		r3,$DC0[r6]
		memdb
		stt		r0,$DD0[r6]			; queue
		memdb

;		0 = draw character
		zxc		r3,r18
		std		r3,$DC0[r6]			; data = character code
		memdb
		std		r0,$DD0[r6]			; queue
		memdb

		call	_SyncCursorPos
		ldd		$r2,[$sp]
		ldd		$r3,8[$sp]
		ldd		$r6,16[$sp]
		ldd		$r29,24[$sp]
		ret		#32

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
_SyncCursorPos:
		ldi		$t2,#SPRCTRL
		ldtu		$t0,_DBGCursorCol
		ldtu		$t1,_DBGCursorRow
		shl		$t1,$t1,#3
		add		$t1,$t1,#28
		shl		$t1,$t1,#16
		shl		$t0,$t0,#3
		add		$t0,$t0,#256
		or		$t0,$t0,$t1
		stt		$t0,$810[$t2]			;
		ret		#0

;----------------------------------------------------------------------------
; Parameters:
;		a0 = bitmap of sprites to enable
; Returns:
;		none
;----------------------------------------------------------------------------
_EnableSprites:
		ldd		$t0,SPRCTRL+$C00
		or		$t0,$t0,$a0
		std		$t0,SPRCTRL+$C00		; enable sprites
		ret		#0

;----------------------------------------------------------------------------
; Parameters:
;		a0 = bitmap of sprites to disable
; Returns:
;		none
;----------------------------------------------------------------------------
_DisableSprites:
		ldd		$t0,SPRCTRL+$C00
		com		$a0,$a0
		and		$t0,$t0,$a0
		std		$t0,SPRCTRL+$C00		; enable sprites
		ret		#0

;----------------------------------------------------------------------------
; Setup the sprite color palette. The palette is loaded with random colors.
;
; Parameters: none
; Modifies: t0,t1,t2,v0
; Returns: none
;----------------------------------------------------------------------------

_SetSpritePalette:
		push	$lr
		ldi		$t2,#SPRCTRL
		sto		$r0,[$t2]				; palette entry #0 (never used)
		ldi		$t0,#WHITE
		sto		$t0,8[$t2]			; palette entry #1
		ldi		$t0,#%010000000111110000000000	; GREEN
		sto		$t0,$10[$t2]			; palette entry #2
		ldi		$t0,#16
.0001:
		mov		$a0,$r0
		call	_GetRand				; doesn't use temps
		and		$v0,$v0,#$FFFFFF
		or		$v0,$v0,#$20000000
		sto		$v0,[$t2+$t0]
		add		$t0,$t0,#8
		slt		$t1,$t0,#$800
		bne		$t1,$r0,.0001
		ldd		$lr,[$sp]
		ret		#10

;----------------------------------------------------------------------------
; Establish a default image for all the sprites.
;----------------------------------------------------------------------------

_SetSpriteImage:
		sub		$sp,$sp,#80
		std		r2,[$sp]
		std		r3,10[$sp]
		std		r4,20[$sp]
		std		r5,30[$sp]
		std		r6,40[$sp]
		std		r7,50[$sp]
		std		r8,60[$sp]
		std		r9,70[$sp]

		ldi		r6,#SPRCTRL
		ldi		r7,#$800
		ldi		r8,#$1FFEE000	; sprite image address
		ldi		r9,#$0780000000000000			; size 60vx32h = 1920 pixels, z = x = y = 0
.0002:
		sto		r8,[r6+r7]		; sprite image address
		add		r7,r7,#8			; advance to pos/size field
		sto		r9,[r6+r7]		; 
		add		r7,r7,#8			; next sprite
		xor		r2,r7,#$C00
		bne		r2,r0,.0002

		ldi		r2,#$1FFEE000
		ldi		r3,#_XImage
		ldi		r5,#30
		ldi		r1,#$300030		; set operating/data level 00 (bits 4,5; 20,21)
		csrrc	r6,#$044,r1
		sync
.0001:
		ldo		r4,[r3]				; swap the order of the words around
		sto		r4,[r2]
		add		r3,r3,#8
		add		r2,r2,#8
		sub		r5,r5,#1
		bne		r5,r0,.0001
		csrrw	r0,#$044,r6		; restore operating level
		sync

		ldd		r2,[$sp]
		ldd		r3,10[$sp]
		ldd		r4,20[$sp]
		ldd		r5,30[$sp]
		ldd		r6,40[$sp]
		ldd		r7,50[$sp]
		ldd		r8,60[$sp]
		ldd		r9,70[$sp]
		ret		#80
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

	align	8
_CursorBoxImage:
	dco		$1111111111000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000000001000000,$00
	dco		$1000110001000000,$00
	dco		$1111111111000000,$00

; Higher order word appears later in memory but is displayed first. So the
; order of these words are swapped around above. To make it convenient to
; define the sprite image.

_XImage:
	dco		%1111111111111111111111111111111100000000000000000000000000000000
	dco		%1110000000000000000000000000011100000000000000000000000000000000
	dco		%1011000000000000000000000000110100000000000000000000000000000000
	dco		%1001100000000000000000000001100100000000000000000000000000000000
	dco		%1000110000000000000000000011000100000000000000000000000000000000
	dco		%1000011000000000000000000110000100000000000000000000000000000000
	dco		%1000001100000000000000001100000100000000000000000000000000000000
	dco		%1000000110000000000000011000000100000000000000000000000000000000
	dco		%1000000011000000000000110000000100000000000000000000000000000000
	dco		%1000000001100000000001100000000100000000000000000000000000000000
	dco		%1000000000110000000011000000000100000000000000000000000000000000
	dco		%1000000000011000000110000000000100000000000000000000000000000000
	dco		%1000000000001100001100000000000100000000000000000000000000000000
	dco		%1000000000000110011000000000000100000000000000000000000000000000
	dco		%1000000000000011110000000000000100000000000000000000000000000000
	dco		%1000000000000011110000000000000100000000000000000000000000000000
	dco		%1000000000000110011000000000000100000000000000000000000000000000
	dco		%1000000000001100001100000000000100000000000000000000000000000000
	dco		%1000000000011000000110000000000100000000000000000000000000000000
	dco		%1000000000110000000011000000000100000000000000000000000000000000
	dco		%1000000001100000000001100000000100000000000000000000000000000000
	dco		%1000000011000000000000110000000100000000000000000000000000000000
	dco		%1000000110000000000000011000000100000000000000000000000000000000
	dco		%1000001100000000000000001100000100000000000000000000000000000000
	dco		%1000011000000000000000000110000100000000000000000000000000000000
	dco		%1000110000000000000000000011000100000000000000000000000000000000
	dco		%1001100000000000000000000001100100000000000000000000000000000000
	dco		%1011000000000000000000000000110100000000000000000000000000000000
	dco		%1110000000000000000000000000011100000000000000000000000000000000
	dco		%1111111111111111111111111111111100000000000000000000000000000000

;----------------------------------------------------------------------------
; Randomize the sprites position.
;
; Parameters:
;		none
; Modifies:
;		$t0 to $t2, $v0
; Stack Space:
;		1 word
;----------------------------------------------------------------------------

_RandomizeSpritePositions2:
		push	$lr
		ldi		$t1,#SPRCTRL
		ldi		$t2,#$808
.0001:
		mov		$a0,$r0
		call	_GetRand
		shr		$t0,$v0,#10				; $t0 = vertical pos
		mod		$v0,$v0,#800			; $v0 = horizontal pos
		mod		$t0,$t0,#600
		shl		$t0,$t0,#16
		or		$v0,$v0,$t0
		add		$v0,$v0,#$000E0080	; add +28 to y and +256 to x
		sto		$v0,[$t1+$t2]
		add		$t2,$t2,#$10			; advance to next sprite
		slt		$v0,$t2,#$BF0
		bne		$v0,$r0,.0001
		ldd		$lr,[$sp]
		ret		#10

;----------------------------------------------------------------------------
; The GC needs an interrupt level all to itself.
; - a higher priority interrupt may interrupt the GC, the GC stop interrupt
;   will only be able to run when the GC exec interrupt routine is executing
; - if there were other interrupt routines at the same level as the GC then
;   it would be possible that some other interrupt might be running when
;   the GC stop interrupt occurs. That would make it impossible to use a
;   two up-level interrupt return and some other means of stopping execution
;   of the GC would have to be found.
;----------------------------------------------------------------------------
brkrout2:
		; Read the golex viewport register to determine if the exception
		; should be handled globally or locally.
		csrrd	r1,#GOLEXVP,r0
		; 0=global, 1=local handling
		beq		r1,r0,.0001		; branch to global handler
		
		; now setup to invoke the local hander
		; load r1,r2 with cause and type
		csrrd	r1,#CAUSE,r0	; get cause code into r1
		mov		r1:x,r1			; put into exceptioned register set
		ldi		r2,#45			; exception type = system exception
		mov		r2:x,r2
		
		; Return to the exception handler code, not the exception return
		; point. The exception handler address should be in r28.
		mov		r1,r28:x
		; Should probably do a quick check for a reasonable return
		; address here.
		csrrw	r0,#EPC,r1		; stuff r28 into the return pc
		sync
		rti						; go back to the local code
		
		; Here global handling of exceptions is done
.0001:
		csrrd	$r1,#$6,r0				; read cause code
		beqi	$r1,#GC_EXEC,execGC
		beqi	$r1,#GC_STOP,stopGC

ts_irq:
		ldi		$r1,#31						; interrupt to reset
		stt		$r1,PIC+$14				; reset edge sense circuit register
		ldd		$r1,_milliseconds
		add		$r1,$r1,#1
		std		$r1,_milliseconds
		shl		$r2,$r1,#16
		and		$r1,$r1,#$FFFF
		or		$r1,$r1,$r2
		std		$r1,$FFFFFFFFFFD0178
		rti
		
		; Here $r22 is used, meaning the GC code can't pass more than four
		; values in registers. $r22 is normally arg#5.
execGC:
		ldi		$r1,#30						; interrupt to reset
		stt		$r1,PIC+$14				; reset edge sense circuit register
		rti
		; GC stop interrupt programmed for one-shot operation here
		ldi		$r22,#PIT
		; The number of cycles to allow the GC to run must be less than
		; the number of cycles between GC interrupts
		ldi		$r1,#1900000			; number of cycles to run GC for (0.1s)
		stt		$r1,$24[$r22]			; max count
		sub		$r1,$r1,#2				; back off a couple of cycles
		stt		$r1,$28[$r22]			; store when 1 output
		ldi		$r1,#3					; configure for one-shot
		stb		$r1,$0D[$r22]			; counter #2 only control
		
		; Re-enable the GC interrupt level so that a GC stop interrupt
		; may interrupt the routine.
		sei		#3
		
		csrrd	$r1,#$C,$r0
		bbc		$r1,#1,.xgc		; if the state was IDLE just call the routine and return

		; Restore operating key		
		ldbu		$r22,_gc_mapno
		csrrd	$r1,#3,$r0		; get PCR
		and		$r1,$r1,#$FFFFFFFFFFFFFF00
		or		$r1,$r1,$r22
		csrrw	$r0,#3,$r1		; set PCR

		; The following load must be before data level is set
		ldd		$r22,_gc_pc
		; Restore data level (current level is 0)
		ldbu		$r1,_gc_dl
		and		$r1,$21,#3
		shl		$r1,$r1,#20
		csrrs	$r0,#$44,$r1

		csrrd	$r1,#$6,$r0		; get back r1
		jmp		[$r22]
.xgc:
		lea		$sp,_gc_stack+255*8	; switch to GC stack
		ldi		$r1,#2			; flag GC busy
		csrrs	$r0,#$C,r1
		ldd		$r1,__GCExecPtr
		call	[$r1]
		rti		#1				; flag GC not busy

		; GCStop can only be entered when GC is running. It does a two up level
		; return after saving the GC context. There isn't that much to save because
		; a register set is reserved for the interrupt level. That means there's no
		; need to save and restore it.
stopGC:
		ldi		$r1,#29						; interrupt to reset
		stt		$r1,PIC+$14				; reset edge sense circuit register
		rti
		ldd		$r1,__GCStopPtr
		jmp		[$r1]
__GCStop:
		; Save data level - the data level was stacked by the GCStop irq
		csrrd	$r1,#$41,$r0		; read stacked data level
		shr		$r1,$r1,#16			; extract data level bits
		and		$r1,$r1,#3
		stb		$r1,_gc_dl			; save off data level

		; Save operating key, restore old operating key
		ldbu		$r22,_gc_omapno
		csrrd	$r1,#3,$r0
		stb		$r1,_gc_mapno		; save off the map that was active
		and		$r1,$r1,#$FFFFFFFFFFFFFF00
		or		$r1,$r1,$r22
		csrrw	$r0,#3,$r1
		
		; Replace the EPC pointer with a pointer to an RTI. The the RTI will
		; execute another RTI.
		lea		$r1,.stopRti
		csrrw	$r1,#EPC0,$r1
		std		$r1,_gc_pc
		csrrd	$r1,#9,$r0			; get back r1
.stopRti:
		rti
		
;===============================================================================
; Generic I2C routines
;===============================================================================

I2C_PREL	EQU		$0
I2C_PREH	EQU		$1
I2C_CTRL	EQU		$2
I2C_RXR		EQU		$3
I2C_TXR		EQU		$3
I2C_CMD		EQU		$4
I2C_STAT	EQU		$4

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; i2c initialization, sets the clock prescaler
;
; Parameters: none
; Returns: none
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_i2c_init:
		ldi		$t0,#I2C
		ldi		$v0,#4								; setup prescale for 400kHz clock
		stb		$v0,I2C_PREL[$t0]
		stb		$r0,I2C_PREH[$t0]
		ret		#0

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for I2C transfer to complete
;
; Parameters
; 	a0 - I2C controller base address
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wait_tip:
.0001:
		memsb
		ldb			$v0,I2C_STAT[$a0]		; would use lvb, but ldb is okay since its the I/O area
		memdb
		bbs			$v0,#1,.0001				; wait for tip to clear
		ret			#0

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write command to i2c
;
; Parameters
;		a2 - data to transmit
;		a1 - command value
;		a0 - I2C controller base address
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wr_cmd:
		push		lr
		stb			$a2,I2C_TXR[$a0]
		memdb
		stb			$a1,I2C_CMD[$a0]
		memdb
		call		i2c_wait_tip
		memsb
		ldb			$v0,I2C_STAT[$a0]
		ldd			lr,[sp]
		ret			#10

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Parameters
;		a0 - I2C controller base address
;		a1 - data to send
; Returns: none
; Stack space: 3 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_i2c_xmit1:
		push		lr
		push		$a1								; save data value
		push		$a2
		ldi			$a1,#1
		stb			$a1,I2C_CTRL[$a0]	; enable the core
		memdb
		ldi			$a2,#$76					; set slave address = %0111011
		ldi			$a1,#$90					; set STA, WR
		call		i2c_wr_cmd
		call		i2c_wait_rx_nack
		ldd			$a2,[sp]					; get back data value
		add			sp,sp,#10
		ldi			$a1,#$50					; set STO, WR
		call		i2c_wr_cmd
		call		i2c_wait_rx_nack
		ldd			$a2,[sp]
		ldd			$a1,10[sp]
		ldd			lr,20[sp]
		ret			#30

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wait_rx_nack:
		push		$a1
.0001:
		memsb
		ldb			$a1,I2C_STAT[$a0]	; wait for RXack = 0
		memdb
		bbs			$a1,#7,.0001
		ldd			$a1,[sp]
		ret			#10

;===============================================================================
; Realtime clock routines
;===============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read the real-time-clock chip.
;
; The entire contents of the clock registers and sram are read into a buffer
; in one-shot rather than reading the registers individually.
;
; Parameters: none
; Returns: r1 = 0 on success, otherwise non-zero
; Modifies: r1 and RTCBuf
; Stack space: 6 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_rtc_read:
		push		lr
		push		$r3
		ldi			$v0,#$80
		push		$a0
		ldi			$a0,#I2C
		push		$a1
		push		$a2
		push		$a3
		ldi			$a3,#_RTCBuf
		stb			$v0,I2C_CTRL[$a0]	; enable I2C
		ldi			$a2,#$DE			; read address, write op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$00			; address zero
		ldi			$a1,#$10			; wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$DF			; read address, read op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		
		ldi			$r2,#$00
.0001:
		ldi			$r3,#$20
		stb			$r3,I2C_CMD[$a0]	; rd bit
		call		i2c_wait_tip
		call		i2c_wait_rx_nack
		memsb
		ldb			$r1,I2C_STAT[$a0]
		bbs			$r1,#7,.rxerr
		memsb
		ldb			$r1,I2C_RXR[$a0]
		stb			$r1,[$a3+$r2]
		add			$r2,$r2,#1
		slt			$v0,$r2,#$5F
		bne			$v0,$r0,.0001
		ldi			$r1,#$68
		stb			$r1,I2C_CMD[$a0]	; STO, rd bit + nack
		call		i2c_wait_tip
		memsb
		ldb			$r1,I2C_STAT[$a0]
		bbs			$r1,#7,.rxerr
		memsb
		ldb			$r1,I2C_RXR[$a0]
		stb			$r1,[$a3+$r2]
		mov			$v0,$r0						; return 0
.rxerr:
		stb			$r0,I2C_CTRL[$a0]	; disable I2C and return status
		ldd			$a3,[sp]
		ldd			$a2,8[sp]
		ldd			$a1,16[sp]
		ldd			$a0,24[sp]
		ldd			$r3,32[sp]
		ldd			lr,40[sp]
		ret			#48

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write the real-time-clock chip.
;
; The entire contents of the clock registers and sram are written from a 
; buffer (RTCBuf) in one-shot rather than writing the registers individually.
;
; Parameters: none
; Returns: r1 = 0 on success, otherwise non-zero
; Modifies: r1 and RTCBuf
; Stack space: 6 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_rtc_write:
		push		lr
		push		$r3
		push		$a0
		push		$a1
		push		$a2
		push		$a3
		ldi			$a0,#I2C
		ldi			$a3,#_RTCBuf
		ldi			$r1,#$80
		stb			$r1,I2C_CTRL[$a0]	; enable I2C
		ldi			$a2,#$DE			; read address, write op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$00			; address zero
		ldi			$a1,#$10			; wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr

		ldi			$r2,#0
.0001:
		ldb			$a2,[$a3+$r2]
		ldi			$a1,#$10
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		add			$r2,$r2,#1
		slt			$r1,$r2,#$5F
		bne			$r1,$r0,.0001
		ldb			$a2,[$a3+$r2]
		ldi			$a1,#$50			; STO, wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		mov			$r1,$r0						; return 0
.rxerr:
		stb			$r0,I2C_CTRL[$a0]	; disable I2C and return status
		ldd			$a3,[sp]
		ldd			$a2,8[sp]
		ldd			$a1,16[sp]
		ldd			$a0,24[sp]
		ldd			$r3,32[sp]
		ldd			lr,40[sp]
		ret			#48
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

;===============================================================================
; String literals
;===============================================================================

MsgBoot:
		dcb		"FT64 ROM BIOS v1.0",0
msgBadChecksum:
		dcb		"ROM Checksum bad",0
msgBadKeybd:
		dcb		"Keyboard not responding.",0
msgRtcReadFail:
		dcb		"RTC read/write failed.",$0D,$0A,$00

		align		2

;===============================================================================
;===============================================================================
;===============================================================================
;===============================================================================
	align	16
font8:
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $00
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $04
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $08
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $0C
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $10
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $14
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $18
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; $1C
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dcb	$00,$00,$00,$00,$00,$00,$00,$00	; SPACE
	dcb	$18,$18,$18,$18,$18,$00,$18,$00	; !
	dcb	$6C,$6C,$00,$00,$00,$00,$00,$00	; "
	dcb	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	; #
	dcb	$18,$3E,$60,$3C,$06,$7C,$18,$00	; $
	dcb	$00,$66,$AC,$D8,$36,$6A,$CC,$00	; %
	dcb	$38,$6C,$68,$76,$DC,$CE,$7B,$00	; &
	dcb	$18,$18,$30,$00,$00,$00,$00,$00	; '
	dcb	$0C,$18,$30,$30,$30,$18,$0C,$00	; (
	dcb	$30,$18,$0C,$0C,$0C,$18,$30,$00	; )
	dcb	$00,$66,$3C,$FF,$3C,$66,$00,$00	; *
	dcb	$00,$18,$18,$7E,$18,$18,$00,$00	; +
	dcb	$00,$00,$00,$00,$00,$18,$18,$30	; ,
	dcb	$00,$00,$00,$7E,$00,$00,$00,$00	; -
	dcb	$00,$00,$00,$00,$00,$18,$18,$00	; .
	dcb	$03,$06,$0C,$18,$30,$60,$C0,$00	; /
	dcb	$3C,$66,$6E,$7E,$76,$66,$3C,$00	; 0
	dcb	$18,$38,$78,$18,$18,$18,$18,$00	; 1
	dcb	$3C,$66,$06,$0C,$18,$30,$7E,$00	; 2
	dcb	$3C,$66,$06,$1C,$06,$66,$3C,$00	; 3
	dcb	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00	; 4
	dcb	$7E,$60,$7C,$06,$06,$66,$3C,$00	; 5
	dcb	$1C,$30,$60,$7C,$66,$66,$3C,$00	; 6
	dcb	$7E,$06,$06,$0C,$18,$18,$18,$00	; 7
	dcb	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
	dcb	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
	dcb	$00,$18,$18,$00,$00,$18,$18,$00	; :
	dcb	$00,$18,$18,$00,$00,$18,$18,$30	; ;
	dcb	$00,$06,$18,$60,$18,$06,$00,$00	; <
	dcb	$00,$00,$7E,$00,$7E,$00,$00,$00	; =
	dcb	$00,$60,$18,$06,$18,$60,$00,$00	; >
	dcb	$3C,$66,$06,$0C,$18,$00,$18,$00	; ?
	dcb	$7C,$C6,$DE,$D6,$DE,$C0,$78,$00	; @
	dcb	$3C,$66,$66,$7E,$66,$66,$66,$00	; A
	dcb	$7C,$66,$66,$7C,$66,$66,$7C,$00	; B
	dcb	$1E,$30,$60,$60,$60,$30,$1E,$00	; C
	dcb	$78,$6C,$66,$66,$66,$6C,$78,$00	; D
	dcb	$7E,$60,$60,$78,$60,$60,$7E,$00	; E
	dcb	$7E,$60,$60,$78,$60,$60,$60,$00	; F
	dcb	$3C,$66,$60,$6E,$66,$66,$3E,$00	; G
	dcb	$66,$66,$66,$7E,$66,$66,$66,$00	; H
	dcb	$3C,$18,$18,$18,$18,$18,$3C,$00	; I
	dcb	$06,$06,$06,$06,$06,$66,$3C,$00	; J
	dcb	$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00	; K
	dcb	$60,$60,$60,$60,$60,$60,$7E,$00	; L
	dcb	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00	; M
	dcb	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	; N
	dcb	$3C,$66,$66,$66,$66,$66,$3C,$00	; O
	dcb	$7C,$66,$66,$7C,$60,$60,$60,$00	; P
	dcb	$78,$CC,$CC,$CC,$CC,$DC,$7E,$00	; Q
	dcb	$7C,$66,$66,$7C,$6C,$66,$66,$00	; R
	dcb	$3C,$66,$70,$3C,$0E,$66,$3C,$00	; S
	dcb	$7E,$18,$18,$18,$18,$18,$18,$00	; T
	dcb	$66,$66,$66,$66,$66,$66,$3C,$00	; U
	dcb	$66,$66,$66,$66,$3C,$3C,$18,$00	; V
	dcb	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	; W
	dcb	$C3,$66,$3C,$18,$3C,$66,$C3,$00	; X
	dcb	$C3,$66,$3C,$18,$18,$18,$18,$00	; Y
	dcb	$FE,$0C,$18,$30,$60,$C0,$FE,$00	; Z
	dcb	$3C,$30,$30,$30,$30,$30,$3C,$00	; [
	dcb	$C0,$60,$30,$18,$0C,$06,$03,$00	; \
	dcb	$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00	; ]
	dcb	$10,$38,$6C,$C6,$00,$00,$00,$00	; ^
	dcb	$00,$00,$00,$00,$00,$00,$00,$FE	; _
	dcb	$18,$18,$0C,$00,$00,$00,$00,$00	; `
	dcb	$00,$00,$3C,$06,$3E,$66,$3E,$00	; a
	dcb	$60,$60,$7C,$66,$66,$66,$7C,$00	; b
	dcb	$00,$00,$3C,$60,$60,$60,$3C,$00	; c
	dcb	$06,$06,$3E,$66,$66,$66,$3E,$00	; d
	dcb	$00,$00,$3C,$66,$7E,$60,$3C,$00	; e
	dcb	$1C,$30,$7C,$30,$30,$30,$30,$00	; f
	dcb	$00,$00,$3E,$66,$66,$3E,$06,$3C	; g
	dcb	$60,$60,$7C,$66,$66,$66,$66,$00	; h
	dcb	$18,$00,$18,$18,$18,$18,$0C,$00	; i
	dcb	$0C,$00,$0C,$0C,$0C,$0C,$0C,$78	; j
	dcb	$60,$60,$66,$6C,$78,$6C,$66,$00	; k
	dcb	$18,$18,$18,$18,$18,$18,$0C,$00	; l
	dcb	$00,$00,$EC,$FE,$D6,$C6,$C6,$00	; m
	dcb	$00,$00,$7C,$66,$66,$66,$66,$00	; n
	dcb	$00,$00,$3C,$66,$66,$66,$3C,$00	; o
	dcb	$00,$00,$7C,$66,$66,$7C,$60,$60	; p
	dcb	$00,$00,$3E,$66,$66,$3E,$06,$06	; q
	dcb	$00,$00,$7C,$66,$60,$60,$60,$00	; r
	dcb	$00,$00,$3C,$60,$3C,$06,$7C,$00	; s
	dcb	$30,$30,$7C,$30,$30,$30,$1C,$00	; t
	dcb	$00,$00,$66,$66,$66,$66,$3E,$00	; u
	dcb	$00,$00,$66,$66,$66,$3C,$18,$00	; v
	dcb	$00,$00,$C6,$C6,$D6,$FE,$6C,$00	; w
	dcb	$00,$00,$C6,$6C,$38,$6C,$C6,$00	; x
	dcb	$00,$00,$66,$66,$66,$3C,$18,$30	; y
	dcb	$00,$00,$7E,$0C,$18,$30,$7E,$00	; z
	dcb	$0E,$18,$18,$70,$18,$18,$0E,$00	; {
	dcb	$18,$18,$18,$18,$18,$18,$18,$00	; |
	dcb	$70,$18,$18,$0E,$18,$18,$70,$00	; }
	dcb	$72,$9C,$00,$00,$00,$00,$00,$00	; ~
	dcb	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00	; 

	align 	64
_msgTestString:
	dcb	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	dcb	"abcdefghijklmnopqrstuvwxyz"
	dcb	"0123456789#$",0

	align	8
cmp_insns:
	dh_htbl

	align	8
tblvect:
	dcd	0
	dcd	1
	dcd	2
	dcd	3
	dcd	4
	dcd	5
	dcd	6
	dcd	7
	dcd	8
	dcd	9
	dcd	10
	dcd	11
	dcd	12
	dcd	13
	dcd	14
	dcd	15

vec1data:
	dcd	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
vec2data:
	dcd	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

;==============================================================================		
; This area reserved for libc
;==============================================================================		

.include "d:\Cores6\rtfItanium\v1\software\c_standard_lib-master\libc.asm"

.include "d:\Cores6\rtfItanium\v1\software\test\SieveOfE.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\gc.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\cc64rt.s"
.include "d:\Cores6\rtfItanium\v1\software\boot\brkrout.asm"
.include "d:\Cores6\rtfItanium\v1\software\boot\HexLoader.s"
.include "d:\Cores6\rtfItanium\v1\software\boot\S19Loader.s"
.include "d:\Cores6\rtfItanium\v1\software\boot\BIOSMain.s"
.include "d:\Cores6\rtfItanium\v1\software\boot\FloatTest.s"
.include "d:\Cores6\rtfItanium\v1\software\boot\FT64TinyBasic.s"
;.include "d:\Cores6\rtfItanium\v1\software\boot\ramtest.s"
	align	256
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\_aacpy.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\_autonew.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\_autodel.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\_new.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\_delete.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\dbg_stdio.s"
;.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\stdio.s"
;.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\ctype.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\string.s"
;.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\malloc.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\putch.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\putnum.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\puthexnum.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\prtflt.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\FT64\io.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\FT64\getCPU.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\gfx.s"
.include "d:\Cores6\rtfItanium\v1\software\cc64libc\source\gfx_demo.s"
	align	256
.include "d:\Cores6\rtfItanium\v1\software\c64libc\source\libquadmath\log10q.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\LockSemaphore.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\UnlockSemaphore.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\DBGkeybd.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\DBGConsole.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\console.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\PIT.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\PIC.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\SetupDevices.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\FMTKc.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\FMTKmsg.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\TCB.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\IOFocusc.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\keybd.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\debugger.s"
	align	256
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\open.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\close.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\read.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\write.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\sleep.s"
;.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\memmgnt3.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\TlbMemmgnt.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\app.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\shell.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\misc.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\monitor.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\disassem.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\OSCall.s"
	align	256
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\null_driver.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\keybd_driver_asm.asm"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\keybd_driver.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\prng_driver_asm.asm"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\prng_driver.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\pti_driver.s"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\drivers\sdc_driver.s"
.include "d:\Cores6\rtfItanium\v1\software\bootrom\source\video.asm"

	align	256
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\scancodes.asm"
.include "d:\Cores6\rtfItanium\v1\software\FMTK\source\kernel\fmtk_vars.asm"
