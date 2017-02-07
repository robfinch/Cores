NOCC		   EQU		 0xFFD80000
NOCC_PKTLO     EQU       0x00
NOCC_PKTMID    EQU       0x04
NOCC_PKTHI     EQU       0x08
NOCC_TXPULSE   EQU       0x18
NOCC_STAT      EQU       0x1C

	code
	org		0xFFFC0000
cold_start:
	move.l	#0x3FFC,A7		; setup stack pointer
	move.l	#0x0000001F,d2	; select write cycle to main system
	move.l	#0xFFDC0600,d1	; LEDs
	moveq.l	#127,d0
	jsr		xmitPacket
cs1:
	bra		cs1

;---------------------------------------------------------------------------
;---------------------------------------------------------------------------

xmitPacket:
	move.l		d7,-(a7)
	move.l		a0,-(a7)
  ; first wait until the transmitter isn't busy
	move.l		#NOCC,a0
xmtP1:
	move.l		NOCC_STAT,d7
	and.w		#0x8000,d7	; bit 15 is xmit status
	bne			xmtP1
	; Now transmit packet
	move.l		NOCC_PKTHI(a0),d2	; set high order packet word (control)
	move.l		NOCC_PKTMID(a0),d1	; set middle packet word (address)
	move.l		NOCC_PKTLO(a0),d0	; and set low order packet word (data)
	clr.l		NOCC_TXPULSE(a0)	; and send the packet
	move.l		(a7)+,a0
	move.l		(a7)+,d7
	rts
