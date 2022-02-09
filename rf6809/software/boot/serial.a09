; ============================================================================
;        __
;   \\__/ o\    (C) 2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; Serial port routines for a WDC6551 compatible circuit.
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
;
;------------------------------------------------------------------------------
; Initialize serial port.
;
; Clear buffer indexes. Two bytes are used for the buffer index even though
; only a single byte is needed. This is for convenience in calculating the
; number of characters in the buffer, done later. The upper byte remains at
; zero.
; The port is initialized for 9600 baud, 1 stop bit and 8 bits data sent.
; The internal baud rate generator is used.
;
; Stack Space:
;		2 words
; Parameters:
;		none
; Modifies:
;		d
; Returns:
;		none
;------------------------------------------------------------------------------

	setdp	$FFFFFC

InitSerial:
SerialInit:
	pshs	dpr,ccr
	ldd		#$FFC
	tfr		d,dpr
	clra
	clrb
	clr		SerHeadRcv
	clr		SerTailRcv
	clr		SerHeadXmit
	clr		SerTailXmit
	clr		SerRcvXon
	clr		SerRcvXoff
	lda		COREID
sini1:
	cmpa	IOFocusID
	bne		sini1
	orcc	#$290						; mask off interrupts
	ldd		#ACIA_MMU				; map ACIA into address space
	std		MMU
	ldb		#$09						; dtr,rts active, rxint enabled (bit 1=0), no parity
	stb		ACIA_CMD
	ldb		#$1E						; baud 9600, 1 stop bit, 8 bit, internal baud gen
	stb		ACIA_CTRL
	ldb		#$0AC						; disable fifos (bit zero, one), reset fifos
	stb		ACIA_CTRL2	
	ldd		#$000F00				; map out ACIA
	std		MMU
	puls	dpr,ccr,pc

;------------------------------------------------------------------------------
; SerialGetChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. If the buffer is almost empty then send an
; XON.
;
; Stack Space:
;		4 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialGetChar:
	pshs	ccr,x,y,dpr
	ldd		#$FFC
	tfr		d,dpr
	orcc	#$290						; mask off interrupts
	bsr		SerialRcvCount			; check number of chars in receive buffer
	cmpb	#8							; less than 8?
	bhi		sgc2
	ldb		SerRcvXon				; skip sending XON if already sent
	bne	  sgc2            ; XON already sent?
	ldb		#XON						; if <8 send an XON
	clr		SerRcvXoff			; clear XOFF status
	stb		SerRcvXon				; flag so we don't send it multiple times
	bsr		SerialPutChar
sgc2:
	ldb		SerHeadRcv			; check if anything is in buffer
	cmpb	SerTailRcv
	beq		sgcNoChars			; no?
	clra
	tfr		d,x	
	ldb		SerRcvBuf,x			; get byte from buffer
	inc		SerHeadRcv			; 4k wrap around
	bra		sgcXit
sgcNoChars:
	ldd		#-1
sgcXit:
	puls	ccr,x,y,dpr,pc

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. But don't update the buffer indexes. No need
; to send an XON here.
;
; Stack Space:
;		3 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
	pshs	x,ccr,dpr
	ldd		#$FFC
	tfr		d,dpr
	orcc	#$290							; mask off interrupts
	ldb		SerHeadRcv				; check if anything is in buffer
	cmpb	SerTailRcv
	beq		spcNoChars				; no?
	clra
	tfr		d,x
	ldb		SerRcvBuf,x				; get byte from buffer
	bra		spcXit
spcNoChars:
	ldd		#-1
spcXit:
	puls	x,ccr,dpr,pc

;------------------------------------------------------------------------------
; SerialPeekChar
;		Get a character directly from the I/O port. This bypasses the input
; buffer.
;
; Stack Space:
;		3 words
; Parameters:
;		none
; Modifies:
;		d
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialPeekCharDirect:
	pshs	ccr,dpr
	ldd		#$FFC
	tfr		d,dpr
	lda		COREID					; Ensure we have the IO Focus
	cmpa	IOFocusID
	bne		spcd0001
	; Disallow interrupts between status read and rx read.
	ldd		#ACIA_MMU
	orcc	#$290						; mask off interrupts
	std		MMU
	ldb		ACIA_STAT
	bitb	#8							; look for Rx not empty
	beq		spcd0001
	ldb		ACIA_RX
	pshs	b
	ldd		#$000F00
	std		MMU
	puls	b
	clra
	puls	ccr,dpr,pc
spcd0001:
	ldd		#$000F00
	std		MMU
	ldd		#-1
	puls	ccr,dpr,pc

;------------------------------------------------------------------------------
; SerialPutChar
;    Put a character to the serial transmitter. This routine blocks until the
; transmitter is empty. 
;
; Stack Space
;		4 words
; Parameters:
;		b = character to put
; Modifies:
;		none
;------------------------------------------------------------------------------

SerialPutChar:
	pshs	d,ccr,u,dpr
	ldu		#$FFC
	tfr		u,dpr
spc0001:
	ldu		#$000F00
	stu		MMU
	lda		COREID					; Ensure we have the IO Focus
	cmpa	IOFocusID
	bne		spc0001
	andcc	#$D6F						; provide a window for an interrupt to occur
	ldu		#ACIA_MMU
	orcc	#$290						; mask off interrupts
	stu		MMU
	; Between the status read and the transmit do not allow an
	; intervening interrupt.
	lda		ACIA_STAT				; wait until the uart indicates tx empty
	bita	#16							; bit #4 of the status reg
	beq		spc0001			    ; branch if transmitter is not empty
	stb		ACIA_TX					; send the byte
	ldu		#$000F00
	stu		MMU
	puls	d,ccr,u,dpr,pc

;------------------------------------------------------------------------------
; Calculate number of character in input buffer. Direct page must be set
; already.
;
; Parameters:
;		none
; Returns:
;		d = number of bytes in buffer.
;------------------------------------------------------------------------------

SerialRcvCount:
	clra
	ldb		SerTailRcv
	subb	SerHeadRcv
	bge		srcXit
	ldd		#$1000
	subd	SerHeadRcv
	addd	SerTailRcv
srcXit:
	rts

;------------------------------------------------------------------------------
; Serial IRQ routine
;
; Keeps looping as long as it finds characters in the ACIA recieve buffer/fifo.
; Received characters are buffered. If the buffer becomes full, new characters
; will be lost.
;
; Stack Space:
;		1 word
; Parameters:
;		none
; Modifies:
;		d,x
; Returns:
;		none
;------------------------------------------------------------------------------

SerialIRQ:
	pshs	dpr							; set direct page register to boot variables
	ldd		#$FFC
	tfr		d,dpr
	ldd		#ACIA_MMU				; map ACIA to page #0
	std		MMU
	ldd		#PIC_MMU				; map PIC to page #1
	std		MMU+2
	lda		$2000+$D3				; Serial active interrupt flag
	beq		notSerInt
sirqNxtByte:
	ldb		ACIA_IRQS				; look for IRQs
	bpl		notSerInt				; quick test for any irqs
	ldb		ACIA_STAT				; check the status
	bitb	#$08						; bit 3 = rx full (not empty)
	beq		notRxInt1
	ldb		ACIA_RX					; get data from Rx buffer to clear interrupt
	lda		SerTailRcv			; check if recieve buffer full
	inca
	cmpa	SerHeadRcv
	beq		sirqRxFull
	sta		SerTailRcv			; update tail pointer
	deca									; backup
	tfr		b,e							; acce = char from port
	tfr		a,b							; b = buffer index
	clra									; a = 0
	tfr		d,x							; x = buffer index
	ste		SerRcvBuf,x			; store recieved byte in buffer
	tst		SerRcvXoff			; check if xoff already sent
	bne		sirqNxtByte
	bsr		SerialRcvCount	; if more than 4070 chars in buffer
	cmpb	#4070
	blo		sirqNxtByte
	ldb		#XOFF						; send an XOFF
	clr		SerRcvXon				; clear XON status
	stb		SerRcvXoff			; set XOFF status
	stb		ACIA_TX
	bra		sirqNxtByte     ; check the status for another byte
	; Process other serial IRQs
notRxInt1:
	ldd		#$000F00
	std		MMU
	ldd		#$001F00
	std		MMU+2
	puls	dpr,pc
sirqRxFull:
notRxInt:
notSerInt:
	ldd		#$000F00
	std		MMU
	ldd		#$001F00
	std		MMU+2
	puls	dpr,pc

nmeSerial:
	fcb		"Serial",0

;------------------------------------------------------------------------------
; Put a string to the serial port.
;
; Parameters:
;		d = pointer to string
; Modifies:
;		none
; Returns:
;		none
;------------------------------------------------------------------------------

SerialPutString:
	pshs	d,x
	tfr		d,x
sps2:
	ldb		,x
	beq		spsXit
	inx
	bsr		SerialPutChar
	bra		sps2
spsXit:
	puls	d,x,pc

;------------------------------------------------------------------------------
; A little routine to test serial output.
;
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		none
;------------------------------------------------------------------------------

SerialOutputTest:
	pshs	d
	ldd		#msgSerialTest
	lbsr	DisplayString
	bsr		SerialInit
sotst1:
	ldb		#XON
	bsr		SerialPutChar
	bsr		SerialPutChar
	bsr		SerialPutChar
	ldd		#msgSerialTest
	bsr		SerialPutString
	lbsr	INCH
	cmpb	#CTRLC
	bne		sotst1
	puls	d,pc

msgSerialTest:
	fcb	"Serial port test",CR,LF,0

	setdp	$000
