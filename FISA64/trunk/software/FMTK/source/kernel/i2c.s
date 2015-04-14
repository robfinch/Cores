; ============================================================================
; I2C interface to RTCC
; ============================================================================

I2C_INIT:
    push    r1
    push    r2
	ldi		r2,#I2C_MASTER
	sb		r0,I2C_CONTROL[r2]		; disable the contoller
	sb		r0,I2C_PRESCALE_HI[r2]	; set clock divisor for 100kHz
	ldi		r1,#99					; 24=400kHz, 99=100KHz
	sb		r1,I2C_PRESCALE_LO[r2]
	ldi		r1,#$80					; controller enable bit
	sb		r1,I2C_CONTROL[r2]
	pop		r2
    pop     r1
	rtl

;------------------------------------------------------------------------------
; I2C Read
;
; Parameters:
; 	r1 = device ($6F for RTCC)
; 	r2 = register to read
; Returns
; 	r1 = register value $00 to $FF if successful, else r1 = -1 on error
;------------------------------------------------------------------------------
;
I2C_READ:
    push    lr
	push	r2
    push    r3
    push    r4
	asl		r1,r1,#1				; clear rw bit for write
;	or		r1,r1,#1				; set rw bit for a read
	mov		r4,r1					; save device address in r4
	mov		r3,r2
	; transmit device #
	ldi		r2,#I2C_MASTER
	sb		r1,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete
	; transmit register #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	sb		r3,I2C_TX[r2]			; select register r3
	ldi		r1,#$10					; set WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC

	; transmit device #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	or		r4,r4,#1				; set read flag
	sb		r4,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete

	; receive data byte
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	ldi		r1,#$68					; STO($40), RD($20), and NACK($08)
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	lbu		r1,I2C_RX[r2]			; $00 to $FF = byte read, -1=err
	pop		r4
    pop     r3
    pop     r2
	rts

I2C_ERR:
	ldi		r1,#-1
	mtspr	cr0,r5					; restore TMR
	pop     r4
	pop     r3
	pop     r2
	rts

;------------------------------------------------------------------------------
; I2C Write
;
; Parameters:
; 	r1 = device ($6F)
; 	r2 = register to write
; 	r3 = value for register
; Returns
; 	r1 = 0 if successful, else r1 = -1 on error
;------------------------------------------------------------------------------
;
I2C_WRITE:
	push	lr
    push    r2
    push    r3
    push    r4
	asl		r1,r1,#1				; clear rw bit for write
	mov		r4,r3					; save value r4
	mov		r3,r2
	; transmit device #
	ldi		r2,#I2C_MASTER			; r2 = I/O base address of controller
	sb		r1,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete
	; transmit register #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne  	r1,I2C_ERR
	sb		r3,I2C_TX[r2]			; select register r3
	ldi		r1,#$10					; set WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	; transmit value
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne  	r1,I2C_ERR
	sb		r4,I2C_TX[r2]			; select value in r4
	ldi		r1,#$50					; set STO, WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	ldi		r1,#0					; everything okay
	pop		r4
    pop     r3
    pop     r2
	rts

; Wait for I2C controller transmit complete

I2C_WAIT_TC:
.0001:
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#2
	bne 	r1,.0001
	rtl

; Read the entire contents of the RTCC including 64 SRAM bytes

RTCCReadbuf:
    push    lr
	bsr		I2C_INIT
	ldi		r2,#$00
.0001:
	ldi		r1,#$6F
	bsr		I2C_READ
	sb		r1,RTCC_BUF[r2]
	add		r2,r2,#1
	cmpu	r1,r2,#$60
	blt		r1,.0001
	rts

; Write the entire contents of the RTCC including 64 SRAM bytes

RTCCWritebuf:
    push    lr
	bsr		I2C_INIT
	ldi		r2,#$00
.0001:
	ldi		r1,#$6F
	lbu		r3,RTCC_BUF[r2]
	bsr		I2C_WRITE
	add		r2,r2,#1
	cmpu	r1,r2,#$60
	blt		r1,.0001
	rts

RTCCOscOn:
    push    lr
	bsr		I2C_INIT
	ldi		r1,#$6F
	ldi		r2,#$00			; register zero
	bsr		I2C_READ		; read register zero
	or		r3,r1,#$80		; set start osc bit
	ldi		r1,#$6F
	bsr		I2C_WRITE
	rts

