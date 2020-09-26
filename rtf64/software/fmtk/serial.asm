; ============================================================================
;        __
;   \\__/ o\    (C) 2020  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
;
; This source file is free software: you can redistribute it and/or modify 
; it under the terms of the GNU Lesser General Public License as published 
; by the Free Software Foundation, either version 3 of the License, or     
; (at your option) any later version.                                      
;                                                                          
; This source file is distributed in the hope that it will be useful,      
; but WITHOUT ANY WARRANTY; without even the implied warranty of           
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
; GNU General Public License for more details.                             
;                                                                          
; You should have received a copy of the GNU General Public License        
; along with this program.  If not, see <http://www.gnu.org/licenses/>.    
;
; ============================================================================

SerRcvBuf		EQU		$9000
SerXmitBuf	EQU		$9400
SerHeadRcv	EQU		$9800
SerTailRcv	EQU		$9804
SerHeadXmit	EQU		$9808
SerTailXmit	EQU		$980C
SerRcvXon		EQU		$9810

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Device command 
;
	code
	align	8
SerialFuncTbl:
	dw		0							; no operation
	dw		0							; setup
	dw		0							; initialize
	dw		0							; status
	dw		0							; media check
	dw		0							; build BPB
	dw		0							; open
	dw		0							; close
	dw		SerialGetChar	; get char
	dw		SerialPeekChar
	dw		0							; get char direct
	dw		SerialPeekCharDirect	; peek char direct
	dw		0							; input status
	dw		SerialPutChar
	dw		0							; reserved
	dw		0							; set position
	dw		0							; read block
	dw		0							; write block
	dw		0							; verify block
	dw		0							; output status
	dw		0							; flush input
	dw		0							; flush output
	dw		SerialIRQ			; IRQ routine
	dw		0							; Is removable
	dw		0							; ioctrl read
	dw		0							; ioctrl write
	dw		0							; output until busy
	dw		0							; 27
	dw		0
	dw		0
	dw		0
	dw		0							; 31

MAX_DEV_OP			EQU		31

;------------------------------------------------------------------------------
; Initialize serial port.
;
; Modifies:
;		$t0
;------------------------------------------------------------------------------

SerialInit:
	sub		$sp,$sp,#4
	sw		$ra,[$sp]
	ldi		$a0,#5							; serial device
	ldi		$a1,#SerialFuncTbl
	call	CopyDevFuncTbl
	sw		$x0,SerHeadRcv
	sw		$x0,SerTailRcv
	sw		$x0,SerHeadXmit
	sw		$x0,SerTailXmit
	ldi		$t0,#$09						; dtr,rts active, rxint enabled, no parity
	sw		$t0,UART+8
	ldi		$t0,#$0006001E			; reset the fifo's
	sw		$t0,UART+12
	ldi		$t0,#$0000001E			; baud 9600, 1 stop bit, 8 bit, internal baud gen
	sw		$t0,UART+12
	lw		$ra,[$sp]
	add		$sp,$sp,#4
	ret
		
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

SerialServiceInit:
	ldi		$a0,#1			; start task
	ldi		$a1,#1024		; memory required
	ldi		$a2,#SerialService
	ecall
	ret
SerialService:
	sub		$sp,$sp,#512+24
	ldi		$a0,#14			; get current tid
	ecall
	add		$a2,$sp,#516
	mov		$a1,$v0
	ldi		$a0,#6			; alloc mailbox
	ecall

SerialServiceLoop:
	ldi		$a0,#10			; waitmsg
	add		$a1,$sp,#516
	add		$a2,$sp,#520
	add		$a3,$sp,#524
	add		$a4,$sp,#528
	ldi		$a5,#-1
	ecall

	lw		$t0,[$sp]
	and		$t0,$t0,#31
	sll		$t0,$t0,#1
	lw		$t0,SerialFuncTbl[$t0]
	jmp		[$t0]

SerialFinishCmd:
	lw		$a1,12[$sp]		; reply mbx
	add		$a1,$a1,#1		; -1 = no reply requested
	beq		$a1,$a0,.0001
	sub		$a1,$a1,#1
	ldi		$a0,#9				; sendmsg
	ldi		$a2,#-1
	ldi		$a3,#-1
	ldi		$a4,#-1
	ecall
.0001:
	jmp		SerialServiceLoop

;------------------------------------------------------------------------------
; SerialGetChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it.
;
; Modifies:
;		none
; Returns:
;		$v0 = character or -1
;------------------------------------------------------------------------------

SerialGetChar:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$v1,4[$sp]
;		call	SerialRcvCount
;		slt		$v0,$v0,#8
;		beq		$v0,$x0,.0002
;		ldi		$v0,#XON
;		sb		$v0,UART+UART_TRB
.0002:
		csrrc	$x0,#$300,#1				; disable interrupts
		lbu		$v1,SerHeadRcv			; check if anything is in buffer
		lbu		$v0,SerTailRcv
		beq		$v0,$v1,.noChars		; no?
		lb		$v0,SerRcvBuf[$v1]	; get byte from buffer
		add		$v1,$v1,#1					; update head index
		sb		$v1,SerHeadRcv				
		bra		.xit
.noChars:
.0001:
		ldi		$v0,#-1
.xit
		csrrs	$x0,#$300,#1				; enable interrupts
		lw		$ra,[$sp]
		lw		$v1,4[$sp]
		add		$sp,$sp,#8
		ret

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. But don't update the buffer indexes.
;
; Modifies:
;		none
; Returns:
;		$v0 = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$v1,4[$sp]
;		call	SerialRcvCount
;		slt		$v0,$v0,#8
;		beq		$v0,$x0,.0002
;		ldi		$v0,#XON
;		sb		$v0,UART+UART_TRB
.0002:
		csrrc	$x0,#$300,#1				; disable interrupts
		lbu		$v1,SerHeadRcv			; check if anything is in buffer
		lbu		$v0,SerTailRcv
		beq		$v0,$v1,.noChars		; no?
		lb		$v0,SerRcvBuf[$v1]	; get byte from buffer
		bra		.xit
.noChars:
.0001:
		ldi		$v0,#-1
.xit
		csrrs	$x0,#$300,#1				; enable interrupts
		lw		$ra,[$sp]
		lw		$v1,4[$sp]
		add		$sp,$sp,#8
		ret

SerialPeekCharDirect:
		sub		$sp,$sp,#8
		sw		$ra,[$sp]
		sw		$v1,4[$sp]
		lb		$v0,UART+UART_STAT
		and		$v0,$v0,#8					; look for Rx not empty
		beq		$v0,$x0,.0001
		lb		$v0,UART+UART_TRB
		bra		.xit
.0001:
		ldi		$v0,#-1
.xit
		lw		$ra,[$sp]
		lw		$v1,4[$sp]
		add		$sp,$sp,#8
		ret

;------------------------------------------------------------------------------
; SerialPutChar
;    Put a character to the serial transmitter. This routine blocks until the
; transmitter is empty. The routine will attempt to transmit the char up to 
; 10 times. If it still can't transmit the char then sleep is called and the
; task is put to sleep for a tick. When it wakes up the routine continues to
; try and send a character.
;
; Stack Space
;		5 words
; Parameters:
;		$a3 = character to put
; Modifies:
;		none
;------------------------------------------------------------------------------

SerialPutChar:
	sub		$sp,$sp,#12
	sw		$v0,[$sp]
	sw		$ra,4[$sp]
	sw		$v1,8[$sp]
.0002:
	ldi		$v1,#-1
.0001:
	sub		$v1,$v1,#1
	beq		$v1,$x0,.goSleep
	lb		$v0,UART+UART_STAT	; wait until the uart indicates tx empty
	and		$v0,$v0,#16					; bit #4 of the status reg
	beq		$v0,$x0,.0001				; branch if transmitter is not empty
	sb		$a3,UART+UART_TRB		; send the byte
	lw		$v0,[$sp]
	lw		$ra,4[$sp]
	lw		$v1,8[$sp]
	add		$sp,$sp,#12
	ret
.goSleep:
	sub		$sp,$sp,#8
	sw		a0,[$sp]
	sw		a1,4[$sp]
	ldi		a0,#5								; sleep function
	ldi		a1,#1								; 1 tick
	ecall
	lw		a0,[$sp]
	lw		a1,4[$sp]
	add		$sp,$sp,#8
	bra		.0002
	
;------------------------------------------------------------------------------
; Calculate number of character in input buffer
;------------------------------------------------------------------------------

SerialRcvCount:
	lbu		$v0,SerTailRcv	; v0 = tail index
	lbu		$v1,SerHeadRcv	; v1 = head index
	sub		$t0,$v0,$v1
	bge		$t0,$x0,.xit
	ldi		$t0,#256
	sub		$t0,$t0,$v1
	add		$t0,$t0,$v0
.xit:
	mov		$v0,$t0
	ret
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

SerialIRQ:
.nxtByte:
	and		$t0,$a0,#$08				; bit 3 = rx full
	beq		$t0,$x0,.notRxInt
	lw		$a1,UART+UART_TRB		; get data from Rx buffer to clear interrupt
	lbu		$t2,SerHeadRcv			; get buffer indexes
	lbu		$t3,SerTailRcv
	add		$t3,$t3,#1					; see if buffer full
	and		$t3,$t3,#255
	beq		$t2,$t3,.rxFull
	sb		$t3,SerTailRcv			; update tail pointer
	sub		$t3,$t3,#1
	and		$t2,$t3,#255
	sb		$a1,SerRcvBuf[$t2]	; store recieved byte in buffer
	call	SerialRcvCount
;	slt		$v0,$v0,#240
;	bne		$v0,$x0,.0001
;	ldi		$a0,#XOFF
;	sb		UART+UART_TRB
.0001:
	lw		$a0,UART+UART_STAT	; check the status for another byte
	bra		.nxtByte
;	ldi		$a0,#$0B						; dtr,rts active, rxint disabled, no parity
;	sw		$a0,UART+UART_CMD
.rxFull:
.notRxInt:
	eret
	
nmeSerial:
	db		"Serial",0
