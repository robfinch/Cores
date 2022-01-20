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
; Parameters:
;		none
; Modifies:
;		d
; Returns:
;		none
;------------------------------------------------------------------------------

InitSerial:
SerialInit:
	clra
	clrb
	std		SerHeadRcv-1
	std		SerTailRcv-1
	std		SerHeadXmit-1
	std		SerTailXmit-1
	clr		SerRcvXon
	clr		SerRcvXoff
	lda		COREID
sini1:
	cmpa	IOFocusID
	bne		sini1
	ldb		#$09						; dtr,rts active, rxint enabled, no parity
	stb		ACIA+ACIA_CMD
	ldb		#$1F						; baud 9600, 1 stop bit, 8 bit, internal baud gen
	stb		ACIA+ACIA_CTRL
	ldb		#$0A6						; diable fifos, reset fifos
	stb		ACIA+ACIA_CTRL2	
	rts

;------------------------------------------------------------------------------
; SerialGetChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. If the buffer is almost empty then send an
; XON.
;
; Stack Space:
;		2 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialGetChar:
		pshs	x,y
		ldy		#0
		sei										; disable interrupts
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
		ldx		#SerRcvBuf
		clra
		ldb		b,x							; get byte from buffer
		inc		SerHeadRcv			; 4k wrap around
		bra		sgcXit
sgcNoChars:
		ldd		#-1
sgcXit:
		cli
		puls	x,y,pc

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. But don't update the buffer indexes. No need
; to send an XON here.
;
; Stack Space:
;		0 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
	pshs	x,ccr
	sei
	ldb		SerHeadRcv				; check if anything is in buffer
	cmpb	SerTailRcv
	beq		spcNoChars				; no?
	ldx		#SerRcvBuf
	clra
	ldb		b,x								; get byte from buffer
	bra		spcXit
spcNoChars:
	ldd		#-1
spcXit:
	puls	x,ccr,pc

;------------------------------------------------------------------------------
; SerialPeekChar
;		Get a character directly from the I/O port. This bypasses the input
; buffer.
;
; Stack Space:
;		0 words
; Parameters:
;		none
; Modifies:
;		d
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialPeekCharDirect:
	lda		COREID							; Ensure we have the IO Focus
	cmpa	IOFocusID
	bne		spcd0001
	; Disallow interrupts between status read and rx read.
	sei
	ldb		ACIA+ACIA_STAT
	bitb	#8									; look for Rx not empty
	beq		spcd0001
	clra
	ldb		ACIA+ACIA_RX
	cli
	rts
spcd0001:
	ldd		#-1
	cli
	rts

;------------------------------------------------------------------------------
; SerialPutChar
;    Put a character to the serial transmitter. This routine blocks until the
; transmitter is empty. 
;
; Stack Space
;		0 words
; Parameters:
;		b = character to put
; Modifies:
;		none
;------------------------------------------------------------------------------

SerialPutChar:
	pshs	a,ccr
spc0001:
	lda		COREID					; Ensure we have the IO Focus
	cmpa	IOFocusID
	bne		spc0001
	cli										; provide a window for an interrupt to occur
	sei
	; Between the status read and the transmit do not allow an
	; intervening interrupt.
	lda		ACIA+ACIA_STAT	; wait until the uart indicates tx empty
	bita	#16							; bit #4 of the status reg
	beq		spc0001			    ; branch if transmitter is not empty
	stb		ACIA+ACIA_TX		; send the byte
	puls	a,ccr,pc

;------------------------------------------------------------------------------
; Calculate number of character in input buffer
;
; Parameters:
;		y = 0 if current core, otherwise reference to core memory area $Cyxxxx
; Returns:
;		d = number of bytes in buffer.
;------------------------------------------------------------------------------

SerialRcvCount:
	clra
	ldb		SerTailRcv,y
	subb	SerHeadRcv,y
	bge		srcXit
	ldd		#$1000
	subd	SerHeadRcv,y
	addd	SerTailRcv,y
srcXit:
	rts

;------------------------------------------------------------------------------
; Serial IRQ routine
;
; Keeps looping as long as it finds characters in the ACIA recieve buffer/fifo.
; Received characters are buffered. If the buffer becomes full, new characters
; will be lost.
;
; Parameters:
;		none
; Modifies:
;		d,x
; Returns:
;		none
;------------------------------------------------------------------------------

SerialIRQ:
sirqNxtByte:
	ldb		ACIA+ACIA_STAT	; check the status
	bitb	#$08						; bit 3 = rx full
	beq		notRxInt
	ldb		ACIA+ACIA_RX		; get data from Rx buffer to clear interrupt
	cmpb	#CTRLT					; detect special keystroke
	bne  	sirq0001
;	bsr 	DumpTraceQueue
sirq0001:
	pshs	b
	; Compute receive buffer address
	lda		IOFocusID
	asla
	asla
	asla
	asla
	ora		#$C00
	clrb	
	tfr		d,y
	puls	b
	lda		SerTailRcv,y			; check if recieve buffer full
	inca
	cmpa	SerHeadRcv,y
	beq		sirqRxFull
	sta		SerTailRcv,y		; update tail pointer
	deca									; backup
	exg		a,b
	leax	SerRcvBuf,y			; x = buffer address
	sta		b,x							; store recieved byte in buffer
	tst		SerRcvXoff,y		; check if xoff already sent
	bne		sirqNxtByte
	bsr		SerialRcvCount	; if more than 4080 chars in buffer
	cmpb	#4080
	blo		sirqNxtByte
	ldb		#XOFF						; send an XOFF
	clr		SerRcvXon,y			; clear XON status
	stb		SerRcvXoff,y		; set XOFF status
	stb		ACIA+ACIA_TX
	bra		sirqNxtByte     ; check the status for another byte
sirqRxFull:
notRxInt:
	rts

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

