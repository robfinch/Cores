;------------------------------------------------------------------------------
; Initialize serial port.
;
; Modifies:
;
;------------------------------------------------------------------------------

InitSerial:
	clra
	clrb
	std		SerHeadRcv-1
	std		SerTailRcv-1
	std		SerHeadXmit-1
	std		SerTailXmit-1
	clr		SerRcvXon
	clr		SerRcvXoff
	ldb		#$09						; dtr,rts active, rxint enabled, no parity
	stb		ACIA+ACIA_CMD
	ldb		#$1E						; baud 9600, 1 stop bit, 8 bit, internal baud gen
	stb		ACIA+ACIA_CTRL
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
		pshs	x
		sei										; disable interrupts
		bsr		SerialRcvCount			; check number of chars in receive buffer
		cmpb	#8							; less than 8?
		blo		sgc2
		ldb		SerRcvXon				; skip sending XON if already sent
		bne	  sgc2            ; XON already sent?
		ldb		#XON						; if <8 send an XON
		clr		SerRcvXoff			; clear XOFF status
		clr		SerRcvXon				; flag so we don't send it multiple times
		stb		ACIA+ACIA_TX
sgc2:
		ldb		SerHeadRcv			; check if anything is in buffer
		cmpb	SerTailRcv
		beq		sgcNoChars			; no?
		ldx		#SerRcvBuf
		abx
		clra
		ldb		,x							; get byte from buffer
		inc		SerHeadRcv
		bra		sgcXit
sgcNoChars:
		ldd		#-1
sgcXit:
		cli
		puls	x,pc

;------------------------------------------------------------------------------
; SerialPeekChar
;
; Check the serial port buffer to see if there's a char available. If there's
; a char available then return it. But don't update the buffer indexes. No need
; to send an XON here.
;
; Stack Space:
;		2 words
; Parameters:
;		none
; Modifies:
;		none
; Returns:
;   $v0 = E_Ok
;		$v1 = character or -1
;------------------------------------------------------------------------------

SerialPeekChar:
	sei
	ldb		SerHeadRcv				; check if anything is in buffer
	cmpb	SerTailRcv
	beq		spcNoChars				; no?
	ldx		#SerRcvBuf
	abx
	clra
	ldb		,x								; get byte from buffer
	bra		spcXit
spcNoChars:
	ldd		#-1
spcXit:
	cli
	rts

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
;		none
; Returns:
;		d = character or -1
;------------------------------------------------------------------------------

SerialPeekCharDirect:
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
	pshs	a
	sei
spc0001:
	lda		ACIA+ACIA_STAT	; wait until the uart indicates tx empty
	bita	#16							; bit #4 of the status reg
	beq		spc0001			    ; branch if transmitter is not empty
	stb		ACIA+ACIA_TX		; send the byte
	cli
	puls	a
	rts

;------------------------------------------------------------------------------
; Calculate number of character in input buffer
;------------------------------------------------------------------------------

SerialRcvCount:
	clra
	ldb		SerTailRcv
	subb	SerHeadRcv
	bge		srcXit
	ldx		#$1000
	subd	SerHeadRcv
	addd	SerTailRcv
srcXit:
	rts

;------------------------------------------------------------------------------
; Serial IRQ routine
;
; Keeps looping as long as it finds characters in the ACIA recieve buffer/fifo.
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
	lda		SerTailRcv			; check if recieve buffer full
	inca
	cmpa	SerHeadRcv
	beq		sirqRxFull
	sta		SerTailRcv			; update tail pointer
	deca									; backup
	exg		a,b
	ldx		#SerRcvBuf			; x = buffer address
	abx
	sta		,x							; store recieved byte in buffer
	tst		SerRcvXoff			; check if xoff already sent
	bne		sirqNxtByte
	bsr		SerialRcvCount	; if more than 4080 chars in buffer
	cmpb	#4080
	blo		sirqNxtByte
	ldb		#XOFF						; send an XOFF
	clr		SerRcvXon				; clear XON status
	stb		SerRcvXoff			; set XOFF status
	stb		ACIA+ACIA_TX
	bra		sirqNxtByte     ; check the status for another byte
sirqRxFull:
notRxInt:
	rts

nmeSerial:
	fcb		"Serial",0
