XON					equ		$11
XOFF				equ		$13
LEDS				equ		$FFDC0600
UART				equ		$FFDC0A00

		code	18 bits
		org		$FFFC0000
start:
		ldi		$sp,#$80000-4		; setup system mode stack pointer
		; Switch to user mode
.0004:
		eret
 		; When an ECALL instruction is executed it'll start here.
		bra		.0004

;------------------------------------------------------------------------------
; User mode code starts here
;------------------------------------------------------------------------------
		org		$FFFC0100

		ldi		$sp,#$80000-1028		; setup user mode stack pointer
		add		$t0,$x0,#$AB				; turn on the LED
		stt		$t0,LEDS
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

		; Now a loop to recieve and echo back characters
.0003:
		call	SerialPeekChar
		blt		$v0,$x0,.0003
		mov		$a0,$v0
		call	SerialPutChar
		bra		.0003

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port status to see if there's a char available. If there's
; a char available then return it.
;
; Modifies:
;		$t0
; Returns:
;		$v0 = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
		ldb		$t0,UART+4
		and		$t0,$t0,#8			; look for Rx not empty
		beq		$t0,$x0,.0001
		ldb		$v0,UART
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
;		$t0
;------------------------------------------------------------------------------

SerialPutChar:
.0001:
		ldb		$t0,UART+4				; wait until the uart indicates tx empty
		and		$t0,$t0,#16				; bit #4 of the status reg
		beq		$t0,$x0,.0001			; branch if transmitter is not empty
		stb		$a0,UART					; send the byte
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
		stt		$ra,[$sp]
		stt		$a0,4[$sp]				; and argument
		mov		$t1,$a0						; t1 = pointer to string
.0001:
		ldb		$a0,[$t1]
		add		$t1,$t1,#1				; advance pointer to next byte
		beq		$a0,$x0,.done			; branch if done
		call	SerialPutChar			; output character
		bra		.0001
.done:
		ldt		$ra,[$sp]					; restore return address
		ldt		$a0,4[$sp]				; and argument
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
		stt		$t0,UART+8
		ldi		$t0,#$08070012			; reset the fifo's
		stt		$t0,UART+12
		ldi		$t0,#$08010012			; baud 115200, 1 stop bit, 8 bit, internal baud gen
		stt		$t0,UART+12
		ret
		
;------------------------------------------------------------------------------
; Message strings
;------------------------------------------------------------------------------

msgStart:
		db		"uart6551 Demo Starting.",13,10,0
