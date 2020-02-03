.include "../fmtk/const.asm"
.include "../fmtk/config.asm"
.include "../fmtk/device.inc"

BS					equ		$08
LF					equ		$0A
CR					equ		$0D
XON					equ		$11
XOFF				equ		$13
DEL					equ		$7F
VIA					equ		$FFDC0600
VIA_PA			equ		$04
VIA_DDRA		equ		$0C
VIA_T1CL		equ		$10
VIA_T1CH		equ		$14
VIA_ACR			equ		$2C
VIA_PCR			equ		$30
VIA_IFR			equ		$34
VIA_IER			equ		$38
VIA_PARAW		equ		$3C
UART				equ		$FFDC0A00
UART_TRB		equ		$00
UART_STAT		equ		$04
UART_CMD		equ		$08
		; First 16kB is for TCB's
INBUF				equ		$4100
switchflag	equ		$4200
milliseconds	equ		$4208


		code	18 bits
;------------------------------------------------------------------------------
; Exception vector table.
;------------------------------------------------------------------------------
		org		$FFFC0000				; user mode exception
		jmp		IRQRout
		org 	$FFFC00C0				; machine mode exception
		jmp		IRQRout
		org		$FFFC00FC				; non-maskable interrupt
		jmp		MachineStart

;------------------------------------------------------------------------------
; User mode code starts here
;------------------------------------------------------------------------------
		org		$FFFC0100
MachineStart:
		ldi		$sp,#$80000-4		; setup machine mode stack pointer
		call	MMUInit					; initialize MMU for address space zero.
		call	FMTKInit
		call	ViaInit
		call	SerialInit
		ldi		$t0,#$FFFC0000
		csrrw $x0,#$301,$t0		; set tvec
		ldi		$t0,#UserStart
		csrrw	$x0,#$341,$t0		; set mepc
		csrrs	$x0,#$300,#1		; enable interrupts
		eret									; switch to user mode
UserStart:
		ldi		$a0,#14							; Get current tid
		ecall
		mov		$a1,$v1
		ldi		$a0,#24							; RequestIOFocus
		ecall
		ldi		$sp,#$80000-1028		; setup user mode stack pointer
		ldi		$t0,#$08						; turn on the LED
		sw		$t0,VIA+VIA_PARAW
		ldi		$t2,#16							; send an XON just in case
		ldi		$a3,#XON
.0004:
		call	SerialPutChar
		sub		$t2,$t2,#1
		bne		$t2,$x0,.0004
.0002:
		ldi		$a0,#msgStart				; spit out a startup message
		call	PutString
		ldi		a0,#1
		ldi		a1,#24000
		ldi		a2,#Monitor
		ecall
		bra		MonEntry

		; Now a loop to recieve and echo back characters
.0003:
		call	SerialPeekChar
		blt		$v0,$x0,.0003
		mov		$a0,$v0
		call	SerialPutChar
		bra		.0003

;------------------------------------------------------------------------------
; Get a character from input device. Checks for a CTRL-T which indicates to
; switch the I/O focus.
;
; Parameters:
;		none
; Returns:
;		v0 = character, -1 if none available
;------------------------------------------------------------------------------

Getch:
	sub		$sp,$sp,#8
	sw		$ra,[$sp]
	sw		$a0,4[$sp]
.0002:
	ldi		$a0,#20							; HasIOFocus?
	ecall
	bne		$v1,$x0,.hasFocus
;	ldi		a0,#13							; reschedule
;	ecall
;	bra		.0002
.hasFocus:
	call	SerialPeekCharDirect
	ldi		a0,#$14							; CTRL-T
	bne		$v0,$a0,.0001
	ldi		$a0,#21							; switch IO Focus
	ecall
.0001:
	lw		$ra,[$sp]
	lw		$a0,4[$sp]
	add		$sp,$sp,#8
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Putch:
	sub		$sp,$sp,#20
	sw		$ra,[$sp]
	sw		$v0,4[$sp]
	sw		$a0,8[$sp]
	sw		$v1,12[$sp]
	sw		$a1,16[$sp]
	mov		$a3,$a0
	ldi		$a1,#5							; serial port
	call	fputc
	lw		$ra,[$sp]
	lw		$v0,4[$sp]
	lw		$a0,8[$sp]
	lw		$v1,12[$sp]
	lw		$a1,16[$sp]
	add		$sp,$sp,#20
	ret

;------------------------------------------------------------------------------
; fputc - put a character to an I/O device. If the task doesn't have the I/O
; focus then it is rescheduled, allowing another task to run.
;
; Stack Space:
;		6 words
; Register Usage:
;		a0 = FMTK_IO specify
;		a2 = device putchar function
; Parameters:
;		a1 = I/O channel
;		a3 = character to put
; Modifies:
;		none
; Returns:
;		none
;------------------------------------------------------------------------------

fputc:
	sub		$sp,$sp,#24
	sw		$ra,[$sp]
	sw		$v0,4[$sp]
	sw		$a0,8[$sp]
	sw		$v1,12[$sp]
	sw		$a1,16[$sp]
	sw		$a2,20[$sp]
.0001:
	ldi		$a0,#20							; HasIOFocus?
	ecall
	bne		$v1,$x0,.hasFocus
	ldi		a0,#5								; reschedule (sleep 0)
	ldi		a1,#0
	ecall
	bra		.0001
.hasFocus:
	ldi		$a0,#26							; FMTK_IO
	ldi		$a2,#13							; putchar function
	ecall
	lw		$ra,[$sp]
	lw		$v0,4[$sp]
	lw		$a0,8[$sp]
	lw		$v1,12[$sp]
	lw		$a1,16[$sp]
	lw		$a2,20[$sp]
	add		$sp,$sp,#24
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
MonEntry:
;		flw			$f2,fltTen
;		fsw			$f2,f2Save
;		flw			$f1,fltTen
;		fsw			$f1,f1Save
;		fadd		$f18,$f2,$f1
;		fsw			$f18,f18Save
		ldi		$a0,#10
		ldi		$a2,#6
;		call	fltToString
;		ldi		$a0,#STRTMP
;		call	PutString

Monitor:
		ldi		$s1,#0					; s1 = input pointer
		ldi		$a0,#CR
		call	Putch
		ldi		$a0,#LF
		call	Putch
		ldi		$a0,#'>'
		call	Putch
.0001:
		call	Getch						; wait until character pressed
		blt		$v0,$x0,.0001
		xor		$t0,$v0,#LF			; ignore line feed
		beq		$t0,$x0,.procLine
		xor		$t0,$v0,#CR
		beq		$t0,$x0,.procLine
		xor		$t0,$v0,#BS
		beq		$t0,$x0,.doBackspace
		xor		$t0,$v0,#DEL
		beq		$t0,$x0,.doDelete
		sb		$v0,INBUF[$s1]
		add		$s1,$s1,#1
		mov		$a0,$v0
		call	Putch
		bra		.0001
.doDelete:
		mov		$s2,$s1
		add		$s2,$s2,#1
.0002:
		lb		$t0,INBUF[$s2]
		sb		$t0,INBUF-1[$s2]
		add		$s2,$s2,#1
		add		$t0,$s2,#INBUF
		slt		$t0,$t0,#INBUF+$7F
		bne		$t0,$x0,.0002
		sb		$x0,INBUF[$s2]
		bra		.0001
.doBackspace:
		beq		$s1,$x0,.0001		; can't backspace anymore
		mov		$a0,$v0					; show the backspace
		call	Putch
		sub		$s1,$s1,#1
		mov		$s2,$s1
.0003:
		lb		$t0,INBUF+1[$s2]
		sb		$t0,INBUF[$s2]
		add		$s2,$s2,#1
		add		$t0,$s2,#INBUF
		slt		$t0,$t0,#INBUF+$7F
		bne		$t0,$x0,.0003
		sb		$x0,INBUF[$s2]
		bra		.0001
.procLine:
		sb		$x0,INBUF[$s1]
		ldi		$s1,#0
.skip:
		lb		$t0,INBUF[$s1]
		beq		$t0,$x0,.0005
		xor		$t1,$t0,#'>'
		bne		$t1,$x0,.0004
.skip2:
		add		$s1,$s1,#1
		bra		.skip
.0004:
		xor		$t1,$t0,#' '
		beq		$t1,$x0,.skip2
		xor		$t1,$t0,#'\t'
		beq		$t1,$x0,.skip2
		xor		$t1,$t0,#'M'
		beq		$t1,$x0,doMem
		ldi		$t1,#'B'
		bne		$t0,$t1,.0006
		ldi		$a0,#1					; Start task
		ldi		$a1,#32000			; 32 kB
		ldi		$a2,#CSTART			; start address
		ecall
		mov		$s1,$v1					; save v1
		ldi		$a0,#msgCRLF
		call	PutString
		mov		$a0,$s1					; get back v1
		call	PutHexByte
		ldi		$a0,msgTaskStart
		call	PutString
		ldi		$a0,#13					; Reschedule task
		ecall
		jmp		Monitor
.0006:
		ldi		$t1,#'D'
		bne		$t0,$t1,.0007
		call 	DumpReadyQueue
		;ldi		$a0,#15
		;ecall
		jmp		Monitor
.0007:
		ldi		$t1,#'E'
		bne		$t0,$t1,.0008
		jmp		EditMem
.0008:
		ldi		$t1,#'F'
		bne		$t0,$t1,.0009
		jmp		FillMem
.0009:
		ldi		$t1,#'S'
		bne		$t0,$t1,.0010
		ldi		$a0,#13
		ecall
		jmp		Monitor
.0010:
		ldi		$t1,#'K'
		bne		$t0,$t1,.0011
		call	GetHexNum
		ldi		$a0,#3					; kill task
		mov		$a1,$v0					; a0 = pid
		ecall
		jmp		Monitor
.0011:
.0005:
		bra		Monitor

doMem:
		sub		$sp,$sp,#4
		add		$s1,$s1,#1
		sw		$s1,[$sp]
		ldi		$a0,#CR
		call	Putch
		ldi		$a0,INBUF
		call	PutString
		lw		$s1,[$sp]
		add		$sp,$sp,#4
		call	GetHexNum
		mov		$s3,$v0
		add		$s1,$s1,#1
		call	GetHexNum
		add		$s4,$v0,$s3
.loop2:
		call	Getch						; check for ctrl-c
		xor		$v0,$v0,#3
		beq		$v0,$x0,Monitor
		ldi		$a0,#CR
		call	Putch
		mov		$a0,$s3
		call	PutHexWord
		ldi		$a0,#':'
		call	Putch
		ldi		$s2,#7
.loop:
		ldi		$a0,#' '
		call	Putch
		lb		$a0,[$s3]
		call	PutHexByte
		add		$s3,$s3,#1
		sub		$s2,$s2,#1
		bge		$s2,$x0,.loop
		bltu	$s3,$s4,.loop2
		bra		Monitor		

EditMem:
		call	GetHexNum			; get address to edit
		mov		$s3,$v0
		add		$s1,$s1,#1
		call	GetHexNum			; get value to set
		sb		$s3,[$v0]			; update mem
		jmp		Monitor

;------------------------------------------------------------------------------
;	>F 1000 800 EE
; Fills memory beginning at address $1000 for $800 bytes with the value $EE
;------------------------------------------------------------------------------

FillMem:
		call	GetHexNum			; get address
		mov		$s3,$v0
		add		$s1,$s1,#1
		call	GetHexNum			; get length
		mov		$s4,$v0
		add		$s1,$s1,#1
		call	GetHexNum			; get byte to use
.0001:
		sb		$v0,[$s3]
		sub		$s4,$s4,#1
		bgt		$s4,$x0,.0001
		jmp		Monitor

;------------------------------------------------------------------------------
; Skip over spaces and tabs in the input buffer.
;------------------------------------------------------------------------------

SkipSpaces:
.skip2:
		lb		$t0,INBUF[$s1]
		xor		$t1,$t0,#' '
		beq		$t1,$x0,.skip1
		xor		$t1,$t0,#'\t'
		beq		$t1,$x0,.skip1
		ret
.skip1:
		add		$s1,$s1,#1
		bra		.skip2

;------------------------------------------------------------------------------
; Get a hex number from the input buffer.
;------------------------------------------------------------------------------

GetHexNum:
		ldi		$v0,#0							; v0 = num
		sub		$sp,$sp,#4
		sw		$ra,[$sp]
		call	SkipSpaces
.next:
		lb		$t0,INBUF[$s1]
		ldi		$t2,#'0'
		blt		$t0,$t2,.0001
		ldi		$t2,#'9'+1
		blt		$t0,$t2,.isDigit
		ldi		$t2,#'A'
		blt		$t0,$t2,.0001
		ldi		$t2,#'F'+1
		blt		$t0,$t2,.isHexUpper
		ldi		$t2,#'a'
		blt		$t0,$t2,.0001
		ldi		$t2,#'f'+1
		blt		$t0,$t2,.isHexLower
.0001:
		lw		$ra,[$sp]
		add		$sp,$sp,#4
		ret
.isHexUpper:
		sll		$v0,$v0,#4
		sub		$t0,$t0,#'A'
		add		$t0,$t0,#10
		or		$v0,$v0,$t0
		add		$s1,$s1,#1
		bra		.next
.isHexLower:
		sll		$v0,$v0,#4
		sub		$t0,$t0,#'a'
		add		$t0,$t0,#10
		or		$v0,$v0,$t0
		add		$s1,$s1,#1
		bra		.next
.isDigit:
		sll		$v0,$v0,#4
		sub		$t0,$t0,#'0'
		or		$v0,$v0,$t0
		add		$s1,$s1,#1
		bra		.next

;------------------------------------------------------------------------------
; Output a word as a hex string.
;------------------------------------------------------------------------------

PutHexWord:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$a0,4[$sp]
		srl		$a0,$a0,#16
		call	PutHexHalf
		lw		$ra,[$sp]
		lw		$a0,4[$sp]
		add		$sp,$sp,#8	; fall through to PutHexHalf

;------------------------------------------------------------------------------
; Output a half-word (16 bits) as a hex string.
;------------------------------------------------------------------------------

PutHexHalf:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$a0,4[$sp]
		srl		$a0,$a0,#8
		call	PutHexByte
		lw		$ra,[$sp]
		lw		$a0,4[$sp]		
		add		$sp,$sp,#8	; fall through to PutHexByte

;------------------------------------------------------------------------------
; Output a byte as a hex string.
;------------------------------------------------------------------------------

PutHexByte:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$a0,4[$sp]
		srl		$a0,$a0,#4		; put the high order nybble first
		call	PutHexNybble
		lw		$ra,[$sp]
		lw		$a0,4[$sp]
		add		$sp,$sp,#8		; fall through to PutHexNybble

;------------------------------------------------------------------------------
; Output a nybble as a hex string.
;------------------------------------------------------------------------------

PutHexNybble:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$a0,4[$sp]
		and		$a0,$a0,#15		; strip off high order bits
		ldi		$t0,#10
		blt		$a0,$t0,.lt10
		sub		$a0,$a0,#10
		add		$a0,$a0,#'A'
		call	Putch
		bra		.0001
.lt10:
		add		$a0,$a0,#'0'
		call	Putch
.0001:
		lw		$ra,[$sp]
		lw		$a0,4[$sp]
		add		$sp,$sp,#8
		ret

;------------------------------------------------------------------------------
; PutString
;    Put a string of characters to the serial transmitter. Calls the 
; Putch routine, so this routine also blocks if the transmitter is not
; empty.
;
; Parameters:
;		$a0 = pointer to null terminated string to put
; Modifies:
;		$t0 and $t1
; Stack Space:
;		2 words
;------------------------------------------------------------------------------

PutString:
		sub		$sp,$sp,#8				; save link register
		sw		$ra,[$sp]
		sw		$a0,4[$sp]				; and argument
		mov		$t1,$a0						; t1 = pointer to string
.0001:
		lb		$a0,[$t1]
		add		$t1,$t1,#1				; advance pointer to next byte
		beq		$a0,$x0,.done			; branch if done
		call	Putch							; output character
		bra		.0001
.done:
		lw		$ra,[$sp]					; restore return address
		lw		$a0,4[$sp]				; and argument
		add		$sp,$sp,#8
		ret

;------------------------------------------------------------------------------
; Exception processing code starts here.
;------------------------------------------------------------------------------
	code
	align	4
IRQRout:
	ldi		$sp,#$80000-4		; setup machine mode stack pointer
	csrrw	$t0,#$342,$x0			; get cause code
	blt		$t0,$x0,.isIRQ		; irq or ecall?
	jmp		OSCALL					; 
	eret										
.isIRQ:
	and		$t0,$t0,#31			; device # is low order 5 bits of cause code
	sll		$t0,$t0,#7				; 128 bytes per device func table
	add		$t0,$t0,#DVF_Base+22*4	; IRQ routine
	lw		$t0,[$t0]
	beq		$t0,$x0,.noIRQ
	jmp		[$t0]
.noIRQ:
	eret

;------------------------------------------------------------------------------
; Message strings
;------------------------------------------------------------------------------

msgStart:
		db		"CS01 System Starting.",13
msgMonHelp:
		db		"Monitor Commands",13
		db		"B - start tiny basic",13
		db		"D - dump ready que",13
		db		"E - edit memory",13
		db		"F - fill memory",13
		db		"K <tid> - kill task", 13
		db		"M <start> <length>	- dump memory",13
		db		"S - switch task",13
		db		0
		align 4
msgTaskStart:
		db		" task started."
msgCRLF:
		db		13,10,0
flt50:
	dw	0x00000000,0x00000000,0x00000000,0x40049000
flt20:
	dw	0x00000000,0x00000000,0x00000000,0x40034000
flt10:
	dw	0x00000000,0x00000000,0x00000000,0x40024000

.include "fltToString.asm"
.include "cs01Mem.asm"
.include "../fmtk/serial.asm"
.include "../fmtk/via.asm"
.include "../fmtk/task.asm"
.include "../fmtk/msg.asm"
.include "../fmtk/tcb.asm"
.include "../fmtk/iofocus.asm"
.include "../fmtk/io.asm"
.include "TinyBasic.asm"
