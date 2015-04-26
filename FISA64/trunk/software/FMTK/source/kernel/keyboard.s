;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Keyboard processing routines follow.
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KEYBD_DELAY		EQU		1000

KeybdGetCharDirectNB:
    push    lr
	push	r2
	sei
	lcu		r1,KEYBD
	and		r2,r1,#$8000
	beq		r2,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	cli
	and		r2,r1,#$800	; is it keydown ?
	bne	    r2,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	beq		r2,.0002
	cmp		r2,r1,#CR
	bne		r2,.0003
	bsr		CRLF
	bra     .0002
.0003:
	jsr		(OutputVec)
.0002:
	pop		r2
	pop     lr
	rtl
.0001:
	cli
	ldi		r1,#-1
	pop		r2
	pop     lr
	rtl

KeybdGetCharDirect:
    push    lr
	push	r2
.0001:
	lc		r1,KEYBD
	and		r2,r1,#$8000
	beq		r2,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	and		r2,r1,#$800	; is it keydown ?
	bne	    r2,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	beq		r2,.gk1
	cmp		r2,r1,#CR
	bne		r2,.gk2
	bsr		CRLF
	bra     .gk1
.gk2:
	jsr		(OutputVec)
.gk1:
	pop		r2
	pop     lr
	rtl

;KeybdInit:
;	mfspr	r1,cr0		; turn off tmr mode
;	push	r1
;	mtspr	cr0,r0
;	ldi		r1,#33
;	sb		r1,LEDS
;	bsr		WaitForKeybdAck	; grab a byte from the keyboard
;	cmp		flg0,r1,#$AA	; did it send a ack ?
;	
;	ldi		r1,#$ff			; issue keyboard reset
;	bsr		SendByteToKeybd
;	ldi		r1,#38
;	sb		r1,LEDS
;	ldi		r1,#4
;	jsr		Sleep
;	ldi		r1,#KEYBD_DELAY	; delay a bit
kbdi5:
;	sub		r1,r1,#1
;	brnz	r1,kbdi5
;	ldi		r1,#34
;	sb		r1,LEDS
;	ldi		r1,#0xf0		; send scan code select
;	bsr		SendByteToKeybd
;	ldi		r1,#35
;	sb		r1,LEDS
;	ldi		r2,#0xFA
;	bsr		WaitForKeybdAck
;	cmp		fl0,r1,#$FA
;	bne		fl0,kbdi2
;	ldi		r1,#36
;	sb		r1,LEDS
;	ldi		r1,#2			; select scan code set#2
;	bsr		SendByteToKeybd
;	ldi		r1,#39
;	sb		r1,LEDS
;kbdi2:
;	ldi		r1,#45
;	sb		r1,LEDS
;	pop		r1				; turn back on tmr mode
;	mtspr	cr0,r1
;	rtl

msgBadKeybd:
	dc		"Keyboard not responding.",0
	align   4

;SendByteToKeybd:
;	push	r2
;	sb		r1,KEYBD
;	ldi		r1,#40
;	sb		r1,LEDS
;	mfspr	r3,tick
;kbdi4:						; wait for transmit complete
;	mfspr	r4,tick
;	sub		r4,r4,r3
;	cmp		fl0,r4,#KEYBD_DELAY
;	bhi		fl0,kbdbad
;	ldi		r1,#41
;	sb		r1,LEDS
;	lbu		r1,KEYBD+1
;	and		fl0,r1,#64
;	brz		fl0,kbdi4
;	bra 	sbtk1
;kbdbad:
;	ldi		r1,#42
;	sb		r1,LEDS
;	lbu		r1,KeybdBad
;	brnz	r1,sbtk2
;	ldi		r1,#1
;	sb		r1,KeybdBad
;	ldi		r1,#43
;	sb		r1,LEDS
;	ldi		r1,#msgBadKeybd
;	bsr		DisplayStringCRLF
;sbtk1:
;	ldi		r1,#44
;	sb		r1,LEDS
;	pop		r2
;	rtl
;sbtk2:
;	bra sbtk1

; Wait for keyboard to respond with an ACK (FA)
;
;WaitForKeybdAck:
;	ldi		r1,#64
;	sb		r1,LEDS
;	mfspr	r3,tick
;wkbdack1:
;	mfspr	r4,tick
;	sub		r4,r4,r3
;	cmp		fl0,r4,#KEYBD_DELAY
;	bhi		fl0,wkbdbad
;	ldi		r1,#65
;	sb		r1,LEDS
;	lb		r1,KEYBD+1				; check keyboard status for key
;	brpl	r1,wkbdack1				; no key available, go back
;	lbu		r1,KEYBD				; get the scan code
;	sb		r0,KEYBD+1				; clear recieve register
;wkbdbad:
;	rtl

KeybdInit:
    push    lr
	ldi		r3,#5
.0001:
	bsr		KeybdRecvByte	; Look for $AA
	bmi		r1,.0002
	cmp		r2,r1,#$AA		;
	beq		r2,.config
.0002:
	bsr		Wait10ms
	ldi		r1,#-1			; send reset code to keyboard
	sb		r1,KEYBD+1		; write to status reg to clear TX state
	bsr		Wait10ms
	ldi		r1,#$FF
	bsr		KeybdSendByte	; now write to transmit register
	bsr		KeybdWaitTx		; wait until no longer busy
	bsr		KeybdRecvByte	; look for an ACK ($FA)
	cmp		r2,r1,#$FA
	bsr		KeybdRecvByte
	cmp		r2,r1,#$FC		; reset error ?
	beq		r2,.tryAgain
	cmp		r2,r1,#$AA		; reset complete okay ?
	bne		r2,.tryAgain
.config:
	ldi		r1,#$F0			; send scan code select
	sc		r1,LEDS
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bmi		r1,.tryAgain
	bsr		KeybdRecvByte	; wait for response from keyboard
	bmi		r1,.tryAgain
	cmp		r2,r1,#$FA
	beq		r2,.0004
.tryAgain:
    subui   r3,r3,#1
	bne	    r3,.0001
.keybdErr:
	ldi		r1,#msgBadKeybd
	bsr		DisplayString
	pop     lr
	rtl
.0004:
	ldi		r1,#2			; select scan code set #2
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bmi		r1,.tryAgain
	pop     lr
	rtl

; Get the keyboard status
;
KeybdGetStatus_:
	lb		r1,KEYBD+1
	rtl
    push    r2
    lbu     r2,TCB_hJCB[tr]
    cmp     r1,r2,#NR_JCB
    bge     r1,.0001
    mulu    r2,#JCB_Size
    addui   r2,r2,#JCB_Array
    push    r3
    push    r4
    push    lr
    bsr     LockSYS
    lbu     r1,JCB_KeybdHead[r2]
    lbu     r3,JCB_KeybdTail[r2]
    bsr     UnlockSYS
    cmpu    r4,r1,r3
    beq     r4,.0002
    ldi     r1,#-1
    pop     lr
    pop     r4
    pop     r3
    pop     r2
    rtl
.0002:
    pop     lr
    pop     r4
    pop     r3
.0001:
    ldi     r1,#0   ; no scancode available
    pop     r2
    rtl

; Get the scancode from the keyboard port
;
KeybdGetScancode_:
	lbu		r1,KEYBD				; get the scan code
	sb		r0,KEYBD+1				; clear receive register
	rtl
    push    r2
    lbu     r2,TCB_hJCB[tr]
    cmp     r1,r2,#NR_JCB
    bge     r1,.0001
    mulu    r2,#JCB_Size
    addui   r2,r2,#JCB_Array
    push    r3
    push    r4
    push    lr
    bsr     LockSYS
    lbu     r1,JCB_KeybdHead[r2]
    lbu     r3,JCB_KeybdTail[r2]
    cmpu    r4,r1,r3
    beq     r4,.0002
    lea     r4,JCB_KeybdBuffer[r2]
    lbu     r1,[r4+r3]
    addui   r3,r3,#1
    and     r3,r3,#31 ; mod 32
    sb      r3,JCB_KeybdTail[r2]
    bsr     UnlockSYS
    pop     lr
    pop     r4
    pop     r3
    pop     r2
    rtl
.0002:
    bsr     UnlockSYS
    pop     lr
    pop     r4
    pop     r3
.0001:
    ldi     r1,#0   ; no scancode available
    pop     r2
    rtl

KeybdClearRcv_:
	sb		r0,KEYBD+1		; clear receive register (acknowledges interrupt)
    rtl
 
; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
KeybdRecvByte:
    push    lr
	push	r3
	ldi		r3,#100			; wait up to 1s
.0003:
	bsr		KeybdGetStatus	; wait for response from keyboard
	bmi		r1,.0004		; is input buffer full ? yes, branch
	bsr		Wait10ms		; wait a bit
	subui   r3,r3,#1
	bne     r3,.0003		; go back and try again
	pop		r3				; timeout
	ldi		r1,#-1			; return -1
	pop     lr
	rtl
.0004:
	bsr		KeybdGetScancode
	pop		r3
	pop     lr
	rtl


; Wait until the keyboard transmit is complete
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitTx:
    push    lr
	push	r2
    push    r3
	ldi		r3,#100			; wait a max of 1s
.0001:
	bsr		KeybdGetStatus
	and		r1,r1,#$40		; check for transmit complete bit
	bne	    r1,.0002		; branch if bit set
	bsr		Wait10ms		; delay a little bit
	subui   r3,r3,#1
	bne	    r3,.0001		; go back and try again
	pop		r3
    pop     r2			    ; timed out
	ldi		r1,#-1			; return -1
	pop     lr
	rtl
.0002:
	pop		r3
    pop     r2			    ; wait complete, return 
	ldi		r1,#0			; return 0
	pop     lr
	rtl

KeybdGetCharNoWait:
	sb		r0,KeybdWaitFlag
	bra		KeybdGetChar

KeybdGetCharWait:
	ldi		r1,#-1
	sb		r1,KeybdWaitFlag

;
; KeyState2_
; 876543210
; ||||||||+ = shift
; |||||||+- = alt
; ||||||+-- = control
; |||||+--- = numlock
; ||||+---- = capslock
; |||+----- = scrolllock
; ||+------ =
; |+------- = 
; +-------- = extended
;
KeybdGetChar:
    push    lr
	push	r2
    push    r3
.0003:
	bsr		KeybdGetStatus_			; check keyboard status for key available
	bmi		r1,.0006				; yes, go process
	lb		r1,KeybdWaitFlag		; are we willing to wait for a key ?
	bmi		r1,.0003				; yes, branch back
	ldi		r1,#-1					; flag no char available
	pop		r3
    pop     r2
	rts
.0006:
	bsr		KeybdGetScancode_
.0001:
	ldi		r2,#1
	sb		r2,LEDS
	cmp		r2,r1,#SC_KEYUP
	beq		r2,.doKeyup
	cmp		r2,r1,#SC_EXTEND
	beq		r2,.doExtend
	cmp		r2,r1,#$14				; code for CTRL
	beq		r2,.doCtrl
	cmp		r2,r1,#$12				; code for left shift
	beq		r2,.doShift
	cmp		r2,r1,#$59				; code for right-shift
	beq		r2,.doShift
	cmp		r2,r1,#SC_NUMLOCK
	beq		r2,.doNumLock
	cmp		r2,r1,#SC_CAPSLOCK
	beq		r2,.doCapsLock
	cmp		r2,r1,#SC_SCROLLLOCK
	beq		r2,.doScrollLock
	cmp     r2,r1,#SC_ALT
	beq     r2,.doAlt
	lb		r2,KeyState1_			; check key up/down
	sb		r0,KeyState1_			; clear keyup status
	bne	    r2,.0003				; ignore key up
	cmp     r2,r1,#SC_TAB
	beq     r2,.doTab
.0013:
	lb		r2,KeyState2_
	and		r3,r2,#$80				; is it extended code ?
	beq		r3,.0010
	and		r3,r2,#$7f				; clear extended bit
	sb		r3,KeyState2_
	sb		r0,KeyState1_			; clear keyup
	lbu		r1,keybdExtendedCodes_[r1]
	bra		.0008
.0010:
	lb		r2,KeyState2_
	and		r3,r2,#$04				; is it CTRL code ?
	beq		r3,.0009
	and		r1,r1,#$7F
	lbu		r1,keybdControlCodes_[r1]
	bra		.0008
.0009:
	lb		r2,KeyState2_
	and		r3,r2,#$01				; is it shift down ?
	beq  	r3,.0007
	lbu		r1,shiftedScanCodes_[r1]
	bra		.0008
.0007:
	lbu		r1,unshiftedScanCodes_[r1]
	ldi		r2,#2
	sb		r2,LEDS
.0008:
	ldi		r2,#3
	sb		r2,LEDS
	pop		r3
    pop     r2
    pop     lr
	rtl
.doKeyup:
	ldi		r1,#-1
	sb		r1,KeyState1_
	bra		.0003
.doExtend:
	lbu		r1,KeyState2_
	or		r1,r1,#$80
	sb		r1,KeyState2_
	bra		.0003
.doCtrl:
	lb		r1,KeyState1_
	sb		r0,KeyState1_
	bpl		r1,.0004
	lb		r1,KeyState2_
	and		r1,r1,#-5
	sb		r1,KeyState2_
	bra		.0003
.0004:
	lb		r1,KeyState2_
	or		r1,r1,#4
	sb		r1,KeyState2_
	bra		.0003
.doAlt:
	lb		r1,KeyState1_
	sb		r0,KeyState1_
	bpl		r1,.0011
    lb      r1,KeyState2_
	lb		r1,KeyState2_
	and		r1,r1,#-3
	sb		r1,KeyState2_
	bra		.0003
.0011:
	lb		r1,KeyState2_
	or		r1,r1,#2
	sb		r1,KeyState2_
	bra		.0003
.doTab:
    push    r1
    lb      r1,KeyState2_
    and     r1,r1,#1                 ; is ALT down ?
    beq     r1,.0012
    inc     iof_switch_
    pop     r1
    bra     .0003
.0012:
    pop     r1
    bra     .0013
.doShift:
	lb		r1,KeyState1_
	sb		r0,KeyState1_
	bpl		r1,.0005
	lb		r1,KeyState2_
	and		r1,r1,#-2
	sb		r1,KeyState2_
	bra		.0003
.0005:
	lb		r1,KeyState2_
	or		r1,r1,#1
	sb		r1,KeyState2_
	bra		.0003
.doNumLock:
	lb		r1,KeyState2_
	eor		r1,r1,#16
	sb		r1,KeyState2_
	bsr		KeybdSetLEDStatus
	bra		.0003
.doCapsLock:
	lb		r1,KeyState2_
	eor		r1,r1,#32
	sb		r1,KeyState2_
	bsr		KeybdSetLEDStatus
	bra		.0003
.doScrollLock:
	lb		r1,KeyState2_
	eor		r1,r1,#64
	sb		r1,KeyState2_
	bsr		KeybdSetLEDStatus
	bra		.0003

KeybdSetLEDStatus:
    push    lr
	push	r2
    push    r3
	sb		r0,KeybdLEDs
	lb		r1,KeyState2_
	and		r2,r1,#16
	beq		r2,.0002
	ldi		r3,#2
	sb		r3,KeybdLEDs
.0002:
	and		r2,r1,#32
	beq		r2,.0003
	lb		r3,KeybdLEDs
	or		r3,r3,#4
	sb		r3,KeybdLEDs
.0003:
	and		r2,r1,#64
	beq		r2,.0004
	lb		r3,KeybdLEDs
	or		r3,r3,#1
	sb		r3,KeybdLEDs
.0004:
	ldi		r1,#$ED
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte
	bmi		r1,.0001
	cmp		r2,r1,#$FA
	lb		r1,KeybdLEDs
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte
.0001:
	pop		r3
    pop     r2
    pop     lr
	rtl

KeybdSendByte:
	sb		r1,KEYBD
	rtl
	
Wait10ms:
	push	r3
    push    r4
	mfspr	r3,tick					; get orginal count
.0001:
	mfspr	r4,tick
	sub		r4,r4,r3
	blt  	r4,.0002				; shouldn't be -ve unless counter overflowed
	cmpu	r4,r4,#250000			; about 10ms at 25 MHz
	blt		r4,.0001
.0002:
	pop		r4
    pop     r3
	rtl

;------------------------------------------------------------------------------
; KeybdIRQ
;     Keyboard interrupt processing routine. Must be short.
; Grab a scancode from the keyboard and place it into the keyboard buffer
; for the job with the I/O focus.
;------------------------------------------------------------------------------

KeybdIRQ:
    ldi     sp,#irq_stack_
    push    lr
    push    r1
    push    r2
    push    r3
    push    r4
    lb      r1,KEYBD+1      ; get the keyboard status
    bgt     r1,.0001        ; is there a scancode present ?
	lbu		r1,KEYBD		; get the scan code
	sb		r0,KEYBD+1		; clear receive register (acknowledges interrupt)
	lw      r2,IOFocusNdx_   ; get task with I/O focus
	beq     r2,.0001
    lb      r2,TCB_hJCB[r2] ; get JCB handle
    cmpu    r3,r3,#NR_JCB   ; make sure valid handle
    bge     r3,.0001
    mulu    r2,r2,#JCB_Size ; and convert it to a pointer
    addui   r2,r2,#JCB_Array
    bsr     LockSYS_
    lbu     r3,JCB_KeybdHead[r2]  ; get head index of keyboard buffer
    lbu     r4,JCB_KeybdTail[r2]  ; get tail index of keyboard buffer
    addui   r3,r3,#1        ; advance head      
    and     r3,r3,#31       ; mod 32
    cmp     r5,r3,r4        ; is there room in the buffer ?
    beq     r5,.0002        ; if not, newest chars will be lost
    sb      r3,JCB_KeybdHead[r2]
    lea     r2,JCB_KeybdBuffer[r2]
    sb      r1,[r2+r3]      ; save off the scan code
    bsr     UnlockSYS_
    lb      r2,KeyState2_   ; check for ALT-tab
    and     r2,r2,#1        ; is ALT down ?
    beq     r2,.0001        
    cmp     r2,r1,#SC_TAB
    bne     r2,.0001
    inc     iof_switch_      ; flag an I/O focus switch
.0001:
    pop     r4
    pop     r3
    pop     r2
	pop     r1
	pop     lr
    rti
.0002:
    bsr     UnlockSYS_
    bra     .0001
KeybdIRQ1:
    rti


	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
	align	16
unshiftedScanCodes_:
	.byte	$2e,$a9,$2e,$a5,$a3,$a1,$a2,$ac
	.byte	$2e,$aa,$a8,$a6,$a4,$09,$60,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$71,$31,$2e
	.byte	$2e,$2e,$7a,$73,$61,$77,$32,$2e
	.byte	$2e,$63,$78,$64,$65,$34,$33,$2e
	.byte	$2e,$20,$76,$66,$74,$72,$35,$2e
	.byte	$2e,$6e,$62,$68,$67,$79,$36,$2e
	.byte	$2e,$2e,$6d,$6a,$75,$37,$38,$2e
	.byte	$2e,$2c,$6b,$69,$6f,$30,$39,$2e
	.byte	$2e,$2e,$2f,$6c,$3b,$70,$2d,$2e
	.byte	$2e,$2e,$27,$2e,$5b,$3d,$2e,$2e
	.byte	$ad,$2e,$0d,$5d,$2e,$5c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	.byte	$98,$7f,$92,$2e,$91,$90,$1b,$af
	.byte	$ab,$2e,$97,$2e,$2e,$96,$ae,$2e

	.byte	$2e,$2e,$2e,$a7,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$fa,$2e,$2e,$2e,$2e,$2e

shiftedScanCodes_:
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$51,$21,$2e
	.byte	$2e,$2e,$5a,$53,$41,$57,$40,$2e
	.byte	$2e,$43,$58,$44,$45,$24,$23,$2e
	.byte	$2e,$20,$56,$46,$54,$52,$25,$2e
	.byte	$2e,$4e,$42,$48,$47,$59,$5e,$2e
	.byte	$2e,$2e,$4d,$4a,$55,$26,$2a,$2e
	.byte	$2e,$3c,$4b,$49,$4f,$29,$28,$2e
	.byte	$2e,$3e,$3f,$4c,$3a,$50,$5f,$2e
	.byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	.byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

; control
keybdControlCodes_:
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$11,$21,$2e
	.byte	$2e,$2e,$1a,$13,$01,$17,$40,$2e
	.byte	$2e,$03,$18,$04,$05,$24,$23,$2e
	.byte	$2e,$20,$16,$06,$14,$12,$25,$2e
	.byte	$2e,$0e,$02,$08,$07,$19,$5e,$2e
	.byte	$2e,$2e,$0d,$0a,$15,$26,$2a,$2e
	.byte	$2e,$3c,$0b,$09,$0f,$29,$28,$2e
	.byte	$2e,$3e,$3f,$0c,$3a,$10,$5f,$2e
	.byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	.byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

keybdExtendedCodes_:
	.byte	$2e,$2e,$2e,$2e,$a3,$a1,$a2,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	.byte	$98,$99,$92,$2e,$91,$90,$2e,$2e
	.byte	$2e,$2e,$97,$2e,$2e,$96,$2e,$2e

