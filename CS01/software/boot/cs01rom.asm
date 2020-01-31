.include "../fmtk/const.asm"

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
		ldi		$t0,#$FFFC0000
		csrrw $x0,#$301,$t0		; set tvec
		ldi		$t0,#UserStart
		csrrw	$x0,#$341,$t0		; set mepc
		eret									; switch to user mode
UserStart:
		ldi		$sp,#$80000-1028		; setup user mode stack pointer
		call	VIAInit
		ldi		$t0,#$08						; turn on the LED
		sw		$t0,VIA+VIA_PARAW
		call	SerialInit
		ldi		$t2,#16							; send an XON just in case
		ldi		$a0,#XON
.0004:
		call	SerialPutChar
		sub		$t2,$t2,#1
		bne		$t2,$x0,.0004
		ldi		$a0,#'A'						; Try sending the letter 'A'
		call	SerialPutChar
.0002:
		ldi		$a0,#msgStart				; spit out a startup message
		call	SerialPutString
		ldi		a0,#1
		ldi		a1,#12
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
;------------------------------------------------------------------------------

Getch:
		sub		$sp,$sp,#4
		sw		$ra,[$sp]
		call	SerialPeekChar
		lw		$ra,[$sp]
		add		$sp,$sp,#4
		ret

Putch:
		sub		$sp,$sp,#4
		sw		$ra,[$sp]
		call	SerialPutChar
		lw		$ra,[$sp]
		add		$sp,$sp,#4
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
;		call	SerialPutString

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
		ldi		$a1,#16					; 32 kB (16 pages)
		ldi		$a2,#CSTART			; start address
		ecall
		mov		$s1,$a0					; save a0
		ldi		$a0,#msgCRLF
		call	SerialPutString
		mov		$a0,$s1					; get back a0
		call	PutHexByte
		ldi		$a0,msgTaskStart
		call	SerialPutString
		ldi		$a0,#13					; Switch task
		ecall
		jmp		Monitor
.0006:
		ldi		$t1,#'D'
		bne		$t0,$t1,.0007
		ldi		$a0,#14
		ecall
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
		call	SerialPutString
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
; VIAInit
;
; Initialize the versatile interface adapter.
;------------------------------------------------------------------------------

VIAInit:
		; Initialize port A low order eight bits as output, the remaining bits as
		; input.
		ldi		$t0,#$000000FF
		sw		$t0,VIA+VIA_DDRA
		ldi		$t0,#1							; select timer 3 access
		sb		$t0,VIA+VIA_PCR+1
		ldi		$t0,#$1F
		sb		$t0,VIA+VIA_ACR+1		; set timer 3 mode, timer 1/2 = 64 bit
		ldi		$t0,#$00196E6B			;	divider value for 30Hz
		sw		$t0,VIA+VIA_T1CL
		sw		$x0,VIA+VIA_T1CH		; trigger transfer to count registers
		ret

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port status to see if there's a char available. If there's
; a char available then return it.
;
; Modifies:
;		none
; Returns:
;		$v0 = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
		lb		$v0,UART+UART_STAT
		and		$v0,$v0,#8					; look for Rx not empty
		beq		$v0,$x0,.0001
		lb		$v0,UART+UART_TRB
		ret
.0001:
		ldi		$v0,#-1
		ret

;------------------------------------------------------------------------------
; SerialPutChar
;    Put a character to the serial transmitter. This routine blocks until the
; transmitter is empty.
;
; Parameters:
;		$a0 = character to put
; Modifies:
;		none
;------------------------------------------------------------------------------

SerialPutChar:
		sub		$sp,$sp,#4
		sw		$v0,[$sp]
.0001:
		lb		$v0,UART+UART_STAT	; wait until the uart indicates tx empty
		and		$v0,$v0,#16					; bit #4 of the status reg
		beq		$v0,$x0,.0001				; branch if transmitter is not empty
		sb		$a0,UART+UART_TRB		; send the byte
		lw		$v0,[$sp]
		add		$sp,$sp,#4
		ret

;------------------------------------------------------------------------------
; SerialPutString
;    Put a string of characters to the serial transmitter. Calls the 
; SerialPutChar routine, so this routine also blocks if the transmitter is not
; empty.
;
; Parameters:
;		$a0 = pointer to null terminated string to put
; Modifies:
;		$t0 and $t1
; Stack Space:
;		2 words
;------------------------------------------------------------------------------

SerialPutString:
		sub		$sp,$sp,#8				; save link register
		sw		$ra,[$sp]
		sw		$a0,4[$sp]				; and argument
		mov		$t1,$a0						; t1 = pointer to string
.0001:
		lb		$a0,[$t1]
		add		$t1,$t1,#1				; advance pointer to next byte
		beq		$a0,$x0,.done			; branch if done
		call	SerialPutChar			; output character
		bra		.0001
.done:
		lw		$ra,[$sp]					; restore return address
		lw		$a0,4[$sp]				; and argument
		add		$sp,$sp,#8
		ret

;------------------------------------------------------------------------------
; Initialize serial port.
;
; Modifies:
;		$t0
;------------------------------------------------------------------------------

SerialInit:
		ldi		$t0,#$0B						; dtr,rts active, rxint disabled, no parity
		sw		$t0,UART+8
		ldi		$t0,#$0006001E			; reset the fifo's
		sw		$t0,UART+12
		ldi		$t0,#$0000001E			; baud 9600, 1 stop bit, 8 bit, internal baud gen
		sw		$t0,UART+12
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
 		; Was it the VIA that caused the interrupt?
		lb		$t0,VIA+VIA_IFR
		bge		$t0,$x0,.0001			; no
		lw		$t0,VIA+VIA_T1CL	; yes, clear interrupt
		lw		$t0,milliseconds
		add		$t0,$t0,#30
		sw		$t0,milliseconds
		sw		$t0,switchflag
		eret
		; Was it the uart that caused the interrupt?
.0001:
		lb		$t0,UART+UART_STAT
		blt		$t0,$x0,.0002			; uart cause interrupt?
		; Some other interrupt
		eret
.0002:
		ldi		$t0,#$0B						; dtr,rts active, rxint disabled, no parity
		sw		$t0,UART+UART_CMD
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
.include "../fmtk/task.asm"
.include "TinyBasic.asm"
