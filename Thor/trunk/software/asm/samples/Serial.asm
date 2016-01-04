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

		align	8
ser_jmp:
		jmp		SerialIRQ[c0]

SerialInit:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldis    hs,#$FFD00000
		ldis	hs.lmt,#$100000
;		ldi		r1,#$0218DEF4	; constant for clock multiplier with 18.75MHz clock for 9600 baud
;		ldi		r1,#$03254E6E	; constant for clock multiplier with 12.5MHz clock for 9600 baud
		ldi		r1,#$00C9539B	; constant for clock multiplier with 50.0MHz clock for 9600 baud
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
;		sb		r1,SERIAL_SEMA
		; setup IRQ vector
		lla		r1,cs:ser_jmp
		ldi		r2,#199
		bsr		set_vector
		lws		c1,[sp]
		addui	sp,sp,#8
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

;----------------------------------------------
; Get character from rx fifo
; If the fifo is empty enough then send an XON
;----------------------------------------------
;
SerialGetChar:
		addui	sp,sp,#-40
		sw		r2,[sp]
		sw		r3,8[sp]
		sw		r4,16[sp]
		sw		r5,24[sp]
		sws		c1,32[sp]
		lcu		r3,Uart_rxhead
		lcu		r2,Uart_rxtail
		cmp		p0,r2,r3
p0.eq	br		sgcfifo1		; is there a char available ?
		lbu		r1,Uart_rxfifo[r2]	; get the char from the fifo into r1
		addui   r2,r2,#1    		; increment the fifo pointer
		andi	r2,r2,#$1ff
		sc		r2,Uart_rxtail
		lb		r2,Uart_rxflow		; using flow control ?
		tst		p0,r2
p0.eq	br		sgcfifo2
		lcu		r3,Uart_fon		; enough space in Rx buffer ?
		bsr		CharsInRxBuf
		cmp		p0,r4,r3
p0.gt	br		sgcfifo2
		sb		r0,Uart_rxflow		; flow off
		lb		r4,Uart_rxrts
		tst		p0,r4
p0.eq	br		sgcfifo3
		lb		r4,hs:UART_MC		; set rts bit in MC
		ori		r4,r4,#2
		sb		r4,hs:UART_MC
sgcfifo3:
		lb		r4,Uart_rxdtr
		tst		p0,r4
p0.eq	br		sgcfifo4
		lb		r4,hs:UART_MC		; set DTR
		ori		r4,r4,#1
		sb		r4,hs:UART_MC
sgcfifo4:
		lb		r4,Uart_rxxon
		tst		p0,r4
p0.eq	br		sgcfifo5
		ldi		r4,#XON
		sb		r4,hs:UART
sgcfifo5:
sgcfifo2:					; return with char in r1
		lw		r2,[sp]
		lw		r3,8[sp]
		lw		r4,16[sp]
		lw		r5,24[sp]
		lws		c1,32[sp]
		addui	sp,sp,#40
		rts
sgcfifo1:
		ldi		r1,#-1				; no char available
		lw		r2,[sp]
		lw		r3,8[sp]
		lw		r4,16[sp]
		lw		r5,24[sp]
		lws		c1,32[sp]
		addui	sp,sp,#40
		rts


;-----------------------------------------
; Serial port IRQ
;-----------------------------------------
;
SerialIRQ:
		sync
		addui	r31,r31,#-64
		sw		r1,[r31]
		sw		r2,8[r31]
		sw		r4,16[r31]
		sws		p0,24[r31]
		sw		r3,32[r31]
		sws		c1,40[r31]
		sws		hs,48[r31]
		sws		hs.lmt,56[r31]
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

		lb      r1,hs:UART_IS  ; get interrupt status
		tst		p0,r1
p0.gt	br		sirq1			; no interrupt
		andi	r1,r1,#0x7f  	; switch on interrupt type
		biti	p0,r1,#4
p0.ne	br		srxirq
		biti	p0,r1,#$0C
p0.ne	br		stxirq
		biti	p0,r1,#$10
p0.ne	br		smsirq
		; unknown IRQ type
sirq1:
		lw		r1,[r31]
		lw		r2,8[r31]
		lw		r4,16[r31]
		lws		p0,24[r31]
		lw		r3,32[r31]
		lws		c1,40[r31]
		lws		hs,48[r31]
		lws		hs.lmt,56[r31]
		addui	r31,r31,#64
		sync
		rti

; Get the modem status and record it
smsirq:
		lbu     r1,hs:UART_MS
		sb      r1,Uart_ms
		br		sirq1

stxirq:
		br		sirq1

; Get a character from the uart and store it in the rx fifo
srxirq:
srxirq1:
		lbu     r1,hs:UART_RX      ; get the char (clears interrupt)
		lbu     r3,Uart_txxon
		tst		p0,r3
p0.eq	br		srxirq3
		cmpi	p0,r1,#XOFF
p0.ne	br		srxirq2
		ldi     r1,#1
		sb		r1,Uart_txxonoff
		br		srxirq5
srxirq2:
		cmpi	p0,r1,#XON
p0.ne	br		srxirq3
		sb		r0,Uart_txxonoff
		br		srxirq5
srxirq3:
		sb		r0,Uart_txxonoff
		lcu		r4,Uart_rxhead
		sb		r1,Uart_rxfifo[r4]  ; store in buffer
		addui   r4,r4,#1
		andi	r4,r4,#$1ff
		sc		r4,Uart_rxhead
srxirq5:
		lb      r1,hs:UART_LS   ; check for another ready character
		biti	p0,r1,#1        ; check rxfull bit
p0.ne	br		srxirq1			; loop back for another character
		lb		r1,Uart_rxflow		; are we using flow controls?
		tst		p0,r1
p0.ne	br		srxirq8
		bsr		CharsInRxBuf
		lb		r1,Uart_foff
		cmp		p0,r4,r1
p0.lt	br		srxirq8
		ldi		r1,#1
		sb		r1,Uart_rxflow
		lb		r1,Uart_rxrts
		tst		p0,r1
p0.eq	br		srxirq6
		lb		r1,hs:UART_MC
		andi	r1,r1,#$FD		; turn off RTS
		sb		r1,hs:UART_MC
srxirq6:
		lb		r1,Uart_rxdtr
		tst		p0,r1

 p0.eq	br		srxirq7
		lb		r1,hs:UART_MC
		andi	r1,r1,#$FE		; turn off DTR
		sb		r1,hs:UART_MC
srxirq7:
		lb		r1,Uart_rxxon
		tst		p0,r1
p0.eq	br		srxirq8
		ldi		r1,#XOFF
		sb		r1,hs:UART_TX
srxirq8:
		br		sirq1

