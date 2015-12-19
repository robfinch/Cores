UART            EQU     0xC0A00
UART_TX         EQU     0xC0A00
UART_RX         EQU     0xC0A00
UART_LS         EQU     0xC0A01
UART_MS         EQU     0xC0A02
UART_IS         EQU     0xC0A03
UART_IE         EQU     0xC0A04
UART_FF         EQU     0xC0A05
UART_MC         EQU     0xC0A06
UART_CTRL       EQU     0xC0A07
UART_CM0        EQU     0xC0A08
UART_CM1        EQU     0xC0A09
UART_CM2        EQU     0xC0A0A
UART_CM3        EQU     0xC0A0B
UART_SPR        EQU     0xC0A0F

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

;==============================================================================
; Serial port
;==============================================================================
	code
;------------------------------------------------------------------------------
; Initialize UART
;------------------------------------------------------------------------------

SerialInit:
    ldis    hs,#$FFD00000
;	ldi		r1,#$0218DEF4	; constant for clock multiplier with 18.75MHz clock for 9600 baud
	ldi		r1,#$03254E6E	; constant for clock multiplier with 12.5MHz clock for 9600 baud
    shrui   r1,r1,#8          ; drop the LSB (not used)
    sb      r1,hs:UART_CM1
    shrui   r1,r1,#8
    sb      r1,hs:UART_CM2
    shrui   r1,r1,#8
    sb      r1,hs:UART_CM3
    sb      r0,hs:UART_CTRL     ; no hardware flow control
	sc		r0,Uart_rxhead		; reset buffer indexes
	sc		r0,Uart_rxtail
	ldi		r1,#0x1f0
	sc		r1,Uart_foff		; set threshold for XOFF
	ldi		r1,#0x010
	sc		r1,Uart_fon			; set threshold for XON
	ldi		r1,#1
	sb		r1,hs:UART_IE		; enable receive interrupt only
	sb		r0,Uart_rxrts		; no RTS/CTS signals available
	sb		r0,Uart_txrts		; no RTS/CTS signals available
	sb		r0,Uart_txdtr		; no DTR signals available
	sb		r0,Uart_rxdtr		; no DTR signals available
	ldi		r1,#1
	sb		r1,Uart_txxon		; for now
	ldi		r1,#1
;	sb		r1,SERIAL_SEMA
    rts

;---------------------------------------------------------------------------------
; Get character directly from serial port. Blocks until a character is available.
;---------------------------------------------------------------------------------
;
SerialGetCharDirect:
sgc1:
		lvb		r1,hs:UART_LS	; uart status
		biti	p0,r1,#1		; is there a char available ?
p0.eq	br		sgc1
		lvb		r1,hs:UART_RX
		rts

;------------------------------------------------
; Check for a character at the serial port
; returns r1 = 1 if char available, 0 otherwise
;------------------------------------------------
;
SerialCheckForCharDirect:
		lvb		r1,hs:UART_LS			; uart status
		andi	r1,r1,#rxfull			; is there a char available ?
		rts

;-----------------------------------------
; Put character to serial port
; r1 = char to put
;-----------------------------------------
;
SerialPutChar:
		addui	sp,sp,#-48
		sw		r2,[sp]
		sw		r3,8[sp]
		sw		r4,16[sp]
		sw		r5,24[sp]
		sws		p0,32[sp]
		sws		lc,40[sp]
		lvb		r2,hs:UART_MC
		ori		r2,r2,#3		; assert DTR / RTS
		sb		r2,hs:UART_MC
		lb		r2,Uart_txrts
		tst		p0,r2
p0.eq	br		spcb1
		lw		r4,Milliseconds
		ldis	lc,#999			; delay count (1 s)
spcb3:
		lvb		r2,hs:UART_MS
		biti	p0,r2,#$10		; is CTS asserted ?
p0.ne	br		spcb1
		lw		r5,Milliseconds
		cmp		p0,r4,r5
p0.eq	br		spcb3
		mov		r4,r5
		loop	spcb3
		br		spcabort
spcb1:
		lb		r2,Uart_txdtr
		tst		p0,r2
p0.eq	br		spcb2
		lw		r4,Milliseconds
		ldis	lc,#999		; delay count
spcb4:
		lvb		r2,hs:UART_MS
		biti	p0,r2,#$20		; is DSR asserted ?
p0.ne	br		spcb2
		lw		r5,Milliseconds
		cmp		p0,r4,r5
p0.eq	br		spcb4
		mov		r4,r5
		loop	spcb4
		br		spcabort
spcb2:	
		lb		r2,Uart_txxon
		tst		p0,r2
p0.eq	br		spcb5
spcb6:
		lb		r2,Uart_txxonoff
		tst		p0,r2
p0.eq	br		spcb5
		lvb		r4,hs:UART_MS
		biti	p0,r4,#0x80		; DCD ?
p0.ne	br		spcb6
spcb5:
		lw		r4,Milliseconds
		ldis	lc,#999		; wait up to 1s
spcb8:
		lvb		r2,hs:UART_LS
		biti	p0,r2,#0x20			; tx not full ?
p0.ne	br		spcb7
		lw		r5,Milliseconds
		cmp		p0,r4,r5
p0.eq	br		spcb8
		mov		r4,r5
		loop	spcb8
		br		spcabort
spcb7:
		sb		r1,hs:UART_TX
spcabort:
		lw		r2,[sp]
		lw		r3,8[sp]
		lw		r4,16[sp]
		lw		r5,24[sp]
		lws		p0,32[sp]
		lws		lc,40[sp]
		addui	sp,sp,#40
		rts

;-------------------------------------------------
; Compute number of characters in recieve buffer.
; r4 = number of chars
;-------------------------------------------------
CharsInRxBuf:
		lcu		r4,Uart_rxhead
		lcu		r3,Uart_rxtail
		subu	r4,r4,r3
		tst		p0,r4
p0.gt	br		cirxb1
		ldi		r4,#0x200
		addu	r4,r4,r3
		lcu		r3,Uart_rxhead
		subu	r4,r4,r3
cirxb1:
		rts

