CR	= 13
LF	= 10
CTRLH	equ		9
cursy	equ		10
cursx	equ		11
pos		equ		12
txtHeight	equ	14
txtWidth	equ	15
charToPrint	equ	16
txBuf	equ		32
rxBuf	equ		48

TXTCTRL		equ	$B100
ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_TXSTAT	equ	$12

ROUTER_TRB	equ	0

		.code
		cpu		Butterfly16
		org		0xC000
start:
		tsr		r1,ID		; id register
		cmp		r1,#$11
		bne		notRootNode
		call	broadcastReset
		call	InitTxtCtrl
		lw		r1,#31
		sb		r1,txtHeight
		lw		r1,#56
		sb		r1,txtWidth
		call	ClearScreen
		call	HomeCursor
		lw		r1,#msgStarting
		call	putmsgScr
notRootNode:
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		beq		noMsg1
		call	Recv
lockup:
		bra		lockup

;----------------------------------------------------------------------------
; Broadcast a reset message on the network.
;----------------------------------------------------------------------------

broadcastReset:
		add		sp,sp,#-2
		sw		lr,[sp]
		call	zeroTxBuf
		lw		r1,#$FF		; global broadcast address
		sb		r1,txBuf+15
		lw		r1,#$11		; source of message
		sb		r1,txBuf+14
		lw		r1,#1
		sb		r1,txBuf+8	; reset message
		call	Xmit
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Transmit on the network.
;----------------------------------------------------------------------------

Xmit:
		; wait for transmit buffer to empty
Xmit2:
		lb		r1,ROUTER+RTR_TXSTAT
		bne		Xmit2
		lw		r2,#15
Xmit1:
		lb		r1,txBuf[r2]
		sb		r1,ROUTER[r2]
		add		r2,r2,#-1
		bpl		Xmit1
		; trigger a transmit
		lw		r1,#1
		sb		r2,ROUTER+RTR_TXSTAT
		ret

;----------------------------------------------------------------------------
; Receive from network.
; Receive status must have already indicated a message present.
;----------------------------------------------------------------------------

Recv:
		lw		r1,#1
		sb		r1,ROUTER+RTR_RXSTAT	; pop the rx fifo
		lw		r2,#15
Recv1:
		lb		r1,ROUTER[r2]			; copy message to local buffer
		sb		r1,rxBuf[r2]
		add		r2,r2,#-1
		bpl		Recv1
		ret

;----------------------------------------------------------------------------
; Zero out the transmit buffer.
;----------------------------------------------------------------------------

zeroTxBuf:
		lw		r2,#15
zeroTxBuf1:
		sb		r0,txBuf[r2]
		sub		r2,r2,#1
		bpl		zeroTxBuf1
		ret

;----------------------------------------------------------------------------
; Initialize the text controller.
;----------------------------------------------------------------------------

InitTxtCtrl:
		lw		r2,#0
itc1:
		lb		r1,txtctrl_dat[r2]
		sb		r1,TXTCTRL[r2]
		add		r2,r2,#1
		cmp		r2,#15
		ble		itc1
		ret

;----------------------------------------------------------------------------
; Clear the screen.
;----------------------------------------------------------------------------

ClearScreen:
		lw		r1,#2048
		lw		r2,#$1000
		lw		r3,#$BF00
cs1:
		sw		r3,[r2]
		add		r2,r2,#2
		add		r1,r1,#-1
		bne		cs1
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

HomeCursor:
		sb		r0,cursy
		sb		r0,cursx
		ret

; flash the character at the screen position
;   r1: 1 = flash, 0 = no flash
flashCursor:
		ret

;-----------------------------------------------------------------
; display a message on the screen
; r1 = message address
; screen pos controls where message is displayed
; Returns
; 	r1 = points to null character
;-----------------------------------------------------------------
putmsgScr:
	sub		sp,sp,#4	; allocate stack frame
	sw		lr,[sp]	; save off link reg
	sw		r3,2[sp]
	mov		r3,r1		; r3 = msg address
putmsg3:
	lb		r1,[r3]		; get char to display
	beq		putmsg4
	call	putcharScr	; store to screen
	add		r3,r3,#1	; inc msg pointer
	br		putmsg3
putmsg4:
	mov		r1,r3
	lw		r3,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


;-----------------------------------------------------------------
; Put a character to the screen
;	r1.h = character to put
;-----------------------------------------------------------------
putcharScr
	sub		sp,sp,#8
	sw		lr,[sp]
	sw		r4,2[sp]
	sw		r5,4[sp]
	sw		r6,6[sp]

	zxb		r1			; mask

	; first turn off any flashing cursor - it may be moved
	lw		r4,r1
	lw		r1,#0
	call	flashCursor
	lw		r1,r4

	; process carriage return
	cmp		r1,#CR		; carriage return ?
	bne		pc1
	lw		r1,pos		; subtract X from position
	lb		r4,cursx
	sub		r1,r4
	sw		r1,pos
	sb		r0,cursx	; and set X to zero
	jmp		pc7

	; process line feed
pc1
	cmp		r1,#LF		; line feed ?
	bne		pc2
	lb		r1,cursy	; past line 23 ?
	lb		r4,txtHeight
	sub		r4,r4,#2
	cmp		r1,r4
	bltu	pc3			; if we are, then just scroll the screen
	call	scrollScreenUp
	jmp		pc7
pc3
	add		r1,r1,#1	; increment Y
	sb		r1,cursy
	lw		r1,pos		; and the cursor position
	lb		r4,txtWidth
	add		r1,r4
	sw		r1,pos
	jmp		pc7

	; backspace
pc2
	cmp		r1,#CTRLH	; backspace ?
	bne		pc4
	lb		r1,cursx	; is cursor.x already zero ?
	bne		pc5			
	jmp		pc7			; can't backspace
pc5
	sub		r1,r1,#1
	sb		r1,cursx
	lw		r4,pos
	sub		r4,r4,#1
	sw		r4,pos
	; shift remaining characters on line over
	shl		r4,#1		; r4 = n
	lw		r6,#$8000
	add		r6,r4		; r6 = target pos
	lb		r4,txtWidth
	sub		r4,r4,#2
pc6
	lw		r5,2[r6]	; shift next char
	sw		r5,[r6]		; over to this one
	add		r6,r6,#2
	add		r1,r1,#1	; until X = 39
	cmp		r1,r4
	bltu	pc6
	; blank trailing character
	lw		r5,#' '
	sb		r5,charToPrint
	lb		r5,charToPrint
	sw		r5,[r6]
	jmp		pc7

	; control character (non-printable)
pc4
	cmp		r1,#' '
	bgeu	pc11
	jmp		pc7


	; some other character
	; put the character to the screen, then advance cursor
pc11
	sb		r1,charToPrint
	lw		r4,#$8000
	lw		r5,pos
	shl		r5,#1		; pos * 2
	add		r4,r5		; scr[pos]
	lw		r5,charToPrint
	sw		r5,[r4]		; = char
	; advance cursor
	lw		r5,pos
	lb		r1,txtWidth
	sub		r1,r1,#2
	lb		r4,cursx
	cmp		r4,r1		; would we be at end of line ?
	bleu	pc8
	sub		r5,r4		; pos -= cursx
	sh		r5,pos
	sb		r0,cursx	; cursor.x = 0
	lb		r4,cursy
	lb		r1,txtHeight
	sub		r1,r1,#2
	cmp		r4,r1		; at last line of screen ?
	bleu	pc9
	call	scrollScreenUp	; yes, scroll
	br		pc7
pc9
	add		r4,r4,#1	; cursor.y++
	sb		r4,cursy
	lb		r1,txtWidth
	add		r5,r1		; pos += txtWidth
	sw		r5,pos
	br		pc7
pc8						; not at EOL
	add		r4,r4,#1	; cursor.x++
	sb		r4,cursx
	add		r5,r5,#1	; pos++
	sh		r5,pos

pc7
	lb		r1,cursFlash	; flash or don't flash the cursor
	call	flashCursor
	lw		lr,[sp]
	lw		r4,2[sp]
	lw		r5,4[sp]
	lw		r6,6[sp]
	add		sp,sp,#8
	ret

irq_rout:
	add		sp,sp,#-2
	sw		r1,[sp]
	lb		r1,UART_X+UART_IS
	cmp		r1,#0
	bpl		notUartXIrq
	and		r1,#$1C
	cmp		r1,#$04
	bne		notRcvXIrq
	lb		r1,UART_X+UART_TRB	; this should clear the Rx IRQ
	sb		UartxRcvFifo
	bra		xitIrq
notRcvXIrq:
	cmp		r1,#$0C
	bne		notTxXIrq
	lb		r1,UartxTxFifoCount
	cmp		r1,#0
	beq		xitIrq
	lb		r1,UartxTxFifo
	sb		r1,UART_X+UART_TRB
	bra		xitIrq
notUartXIrq:
	lb		r1,UART_Y+UART_IS
	cmp		r1,#0
	bpl		notUartYIrq
	and		r1,#$1C
	cmp		r1,#$04
	bne		notRcvYIrq
	lb		r1,UART_Y+UART_TRB	; this should clear the Rx IRQ
	sb		UartyRcvFifo
	bra		xitIrq
notUartYIrq:
xitIrq:
	lw		r1,[sp]
	add		sp,sp,#2
	iret
		
msgStarting:
	db	"Butterfly Grid Computer Starting",0

txtctrl_dat:
	db	56,31,84,0,16,0,7,$22,$1F,$E0,31,0,0,3,0

		org		0xFFFE
		dw		start
