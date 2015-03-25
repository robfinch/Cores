
;==============================================================================
; Serial port
;==============================================================================
	code
;------------------------------------------------------------------------------
; Initialize UART
;------------------------------------------------------------------------------

InitUart:
    ldi     r2,#UART
;    ldi     r1,#$025BF7BA   ; constant for clock multiplier with 16.667MHz clock for 9600 baud
    ldi     r1,#$0E27CE61   ; constant for clock multiplier with 16.667MHz clock for 57600 baud
    lsr     r1,r1,#8          ; drop the LSB (not used)
    sb      r1,UART_CM1[r2]
    lsr     r1,r1,#8
    sb      r1,UART_CM2[r2]
    lsr     r1,r1,#8
    sb      r1,UART_CM3[r2]
    sb      r0,UART_CTRL[r2]           ; no hardware flow control
	sc		r0,Uart_rxhead			; reset buffer indexes
	sc		r0,Uart_rxtail
	ldi		r1,#0x1f0
	sc		r1,Uart_foff		; set threshold for XOFF
	ldi		r1,#0x010
	sc		r1,Uart_fon			; set threshold for XON
	ldi		r1,#1
	sb		r1,UART_IE[r2]		; enable receive interrupt only
	sb		r0,Uart_rxrts		; no RTS/CTS signals available
	sb		r0,Uart_txrts		; no RTS/CTS signals available
	sb		r0,Uart_txdtr		; no DTR signals available
	sb		r0,Uart_rxdtr		; no DTR signals available
	ldi		r1,#1
	sb		r1,Uart_txxon		; for now
	ldi		r1,#1
;	sb		r1,SERIAL_SEMA
    rtl

;---------------------------------------------------------------------------------
; Get character directly from serial port. Blocks until a character is available.
;---------------------------------------------------------------------------------
;
SerialGetCharDirect:
sgc1:
	lb		r1,UART+UART_LS	; uart status
	and		r1,r1,#1		; is there a char available ?
	beq		r1,sgc1
	lb		r1,UART+UART_RX
	rtl

;------------------------------------------------
; Check for a character at the serial port
; returns r1 = 1 if char available, 0 otherwise
;------------------------------------------------
;
SerialCheckForCharDirect:
	lb		r1,UART+UART_LS			; uart status
	and		r1,r1,#rxfull			; is there a char available ?
	rtl

;-----------------------------------------
; Put character to serial port
; r1 = char to put
;-----------------------------------------
;
SerialPutChar:
    push    r2
    push    r3
	push	r4
	push	r5
    push    r6
    ldi     r6,#UART
	lb		r2,UART_MC[r6]
	or		r2,r2,#3		; assert DTR / RTS
	sb		r2,UART_MC[r6]
	lb		r2,Uart_txrts
	beq		r2,spcb1
	lw		r4,Milliseconds
	ldi		r3,#1024		; delay count (1 s)
spcb3:
	lb		r2,UART_MS[r6]
	and		r2,r2,#$10		; is CTS asserted ?
	bne		r2,spcb1
	lw		r5,Milliseconds
	cmp		r2,r4,r5
	beq		r2,spcb3
	mov		r4,r5
	subui   r3,r3,#1
	bne		r3,spcb3
	bra		spcabort
spcb1:
	lb		r2,Uart_txdtr
	beq		r2,spcb2
	lw		r4,Milliseconds
	ldi		r3,#1024		; delay count
spcb4:
	lb		r2,UART_MS[r6]
	and		r2,r2,#$20		; is DSR asserted ?
	bne		r2,spcb2
	lw		r5,Milliseconds
	cmp		r2,r4,r5
	beq		r2,spcb4
	mov		r4,r5
	subui   r3,r3,#1
	bne		r3,spcb4
	bra		spcabort
spcb2:	
	lb		r2,Uart_txxon
	beq		r2,spcb5
spcb6:
	lb		r2,Uart_txxonoff
	beq		r2,spcb5
	lb		r4,UART_MS[r6]
	and		r4,r4,#0x80			; DCD ?
	bne		r4,spcb6
spcb5:
	lw		r4,Milliseconds
	ldi		r3,#1024			; wait up to 1s
spcb8:
	lb		r2,UART_LS[r6]
	and		r2,r2,#0x20			; tx not full ?
	bne		r2,spcb7
	lw		r5,Milliseconds
	cmp		r2,r4,r5
	beq		r2,spcb8
	mov		r4,r5
	subui   r3,r3,#1
	bne		r3,spcb8
	bra		spcabort
spcb7:
	sb		r1,UART_TX[r6]
spcabort:
    pop     r6
	pop		r5
	pop		r4
	pop     r3
	pop     r2
	rtl


;-------------------------------------------------
; Compute number of characters in recieve buffer.
; r4 = number of chars
;-------------------------------------------------
CharsInRxBuf:
	lcu		r4,Uart_rxhead
	lcu		r3,Uart_rxtail
	subu	r4,r4,r3
	bgt		r4,cirxb1
	ldi		r4,#0x200
	addu	r4,r4,r3
	lcu		r3,Uart_rxhead
	subu	r4,r4,r3
cirxb1:
	rtl

;----------------------------------------------
; Get character from rx fifo
; If the fifo is empty enough then send an XON
;----------------------------------------------
;
SerialGetChar:
    push    r2
    push    r3
	push	r4
    push    r5
    ldi     r5,#UART
	lcu		r3,Uart_rxhead
	lcu		r2,Uart_rxtail
	cmp		r3,r2,r3
	beq		r3,sgcfifo1		    ; is there a char available ?
	lbu		r1,Uart_rxfifo[r2]	; get the char from the fifo into r1
	addui   r2,r2,#1    		; increment the fifo pointer
	and		r2,r2,#$1ff
	sc		r2,Uart_rxtail
	lb		r2,Uart_rxflow		; using flow control ?
	beq		r2,sgcfifo2
	lcu		r3,Uart_fon		; enough space in Rx buffer ?
	push    lr
	bsr		CharsInRxBuf
	pop     lr
	cmp		r4,r4,r3
	bgt		r4,sgcfifo2
	sb		r0,Uart_rxflow		; flow off
	lb		r4,Uart_rxrts
	beq		r4,sgcfifo3
	lb		r4,UART_MC[r5]		; set rts bit in MC
	or		r4,r4,#2
	sb		r4,UART_MC[r5]
sgcfifo3:
	lb		r4,Uart_rxdtr
	beq		r4,sgcfifo4
	lb		r4,UART_MC[r5]		; set DTR
	or		r4,r4,#1
	sb		r4,UART_MC[r5]
sgcfifo4:
	lb		r4,Uart_rxxon
	beq		r4,sgcfifo5
	ldi		r4,#XON
	sb		r4,UART[r5]
sgcfifo5:
sgcfifo2:					; return with char in r1
    pop     r5
	pop		r4
	pop     r3
	pop     r2
	rtl
sgcfifo1:
	ldi		r1,#-1				; no char available
	pop     r5
	pop		r4
	pop     r3
	pop     r2
	rts


;-----------------------------------------
; Serial port IRQ
;-----------------------------------------
;
SerialIRQ:
    ldi     sp,#$8000
	push    r1
	push    r2
	push    r3
	push	r4

    ldi     r2,#UART
    lb      r1,UART_IS[r2]  ; get interrupt status
	bgt		r1,sirq1		; no interrupt
	and		r1,r1,#0x7f  	; switch on interrupt type
	cmp		r3,r1,#4
	beq		r3,srxirq
	cmp		r3,r1,#$0C
	beq		r3,stxirq
	cmp		r3,r1,#$10
	beq		r3,smsirq
	; unknown IRQ type
sirq1:
	pop		r4
	pop     r3
	pop     r2
	pop     r1
	rti

; Get the modem status and record it
smsirq:
    lbu     r1,UART_MS[r2]
	sb      r1,Uart_ms
	bra		sirq1

stxirq:
	bra		sirq1

; Get a character from the uart and store it in the rx fifo
srxirq:
srxirq1:
    lbu     r1,UART_RX[r2]      ; get the char (clears interrupt)
    lbu     r3,Uart_txxon
	beq		r3,srxirq3
	cmp		r4,r1,#XOFF
	bne		r4,srxirq2
	ldi     r1,#1
	sb		r1,Uart_txxonoff
	bra		srxirq5
srxirq2:
	cmp		r4,r1,#XON
	bne		r4,srxirq3
	sb		r0,Uart_txxonoff
	bra		srxirq5
srxirq3:
	sb		r0,Uart_txxonoff
	lcu		r4,Uart_rxhead
	sb		r1,Uart_rxfifo[r4]  ; store in buffer
	addui   r4,r4,#1
	and		r4,r4,#$1ff
	sc		r4,Uart_rxhead
srxirq5:
    lb      r1,UART_LS[r2]      ; check for another ready character
	and		r1,r1,#1            ; check rxfull bit
	bne		r1,srxirq1          ; loop back for another character
	lb		r1,Uart_rxflow		; are we using flow controls?
	bne		r1,srxirq8
	push    lr
	bsr		CharsInRxBuf
	pop     lr
	lb		r1,Uart_foff
	cmp		r1,r4,r1
	blt		r1,srxirq8
	ldi		r1,#1
	sb		r1,Uart_rxflow
	lb		r1,Uart_rxrts
	beq		r1,srxirq6
	lb		r1,UART_MC[r2]
	and		r1,r1,#$FD		; turn off RTS
	sb		r1,UART_MC[r2]
srxirq6:
	lb		r1,Uart_rxdtr
	beq		r1,srxirq7
	lb		r1,UART_MC[r2]
	and		r1,r1,#$FE		; turn off DTR
	sb		r1,UART_MC[r2]
srxirq7:
	lb		r1,Uart_rxxon
	beq		r1,srxirq8
	ldi		r1,#XOFF
	sb		r1,UART_TX[r2]
srxirq8:
	bra		sirq1

