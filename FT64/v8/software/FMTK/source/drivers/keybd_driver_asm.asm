;===============================================================================
; Keyboard routines
;===============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize the keyboard.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdInit:
	  push  lr
	  push	r3
		ldi		r3,#5
.0002:
		call	_Wait10ms
		ldi		$a0,#-1			; send reset code to keyboard
		sb		$a0,KEYBD+1	; write $FF to status reg to clear TX state
		memdb
		call	_KeybdSendByte	; now write to transmit register
		call	_KeybdWaitTx		; wait until no longer busy
		call	_KeybdRecvByte	; look for an ACK ($FA)
		xor		r2,r1,#$FA
		bne		r2,r0,.tryAgain
		call	_KeybdRecvByte	; look for BAT completion code ($AA)
		xor		r2,r1,#$FC	; reset error ?
		beq		r2,r0,.tryAgain
		xor		r1,r1,#$AA	; reset complete okay ?
		bne		r2,r0,.tryAgain

		; After a reset, scan code set #2 should be active
.config:
		ldi		$a0,#$F0			; send scan code select
		sb		$a0,LEDS
		call	_KeybdSendByte
		call	_KeybdWaitTx
		bbs		r1,#7,.tryAgain
		call	_KeybdRecvByte	; wait for response from keyboard
		bbs		r1,#7,.tryAgain
		xor		r2,r1,#$FA
		beq		r2,r0,.0004
.tryAgain:
    sub   r3,r3,#1
		bne	  r3,r0,.0002
.keybdErr:
		ldi		r1,#msgBadKeybd
		push	$r1
		call	_DBGDisplayAsciiStringCRLF
		bra		ledxit
.0004:
		ldi		$a0,#2			; select scan code set #2
		call	_KeybdSendByte
		call	_KeybdWaitTx
		bbs		r1,#7,.tryAgain
		call	_KeybdRecvByte	; wait for response from keyboard
		bbs		r1,#7,.tryAgain
		xor		r2,r1,#$FA
		bne		r2,r0,.tryAgain
		call	_KeybdGetID
ledxit:
		ldi		$a0,#$07
		call	_KeybdSetLED
		call	_Wait300ms
		ldi		$a0,#$00
		call	_KeybdSetLED
		lw		r3,[sp]
		lw		lr,8[sp]
		ret		#16

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set the LEDs on the keyboard.
;
; Parameters: $a0 LED status to set
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdSetLED:
		push	lr
		push	$r1
		mov		$r1,$a0
		ldi		$a0,#$ED
		call	_KeybdSendByte
		call	_KeybdWaitTx
		call	_KeybdRecvByte	; should be an ack
		mov		$a0,$r1
		call	_KeybdSendByte
		call	_KeybdWaitTx
		call	_KeybdRecvByte	; should be an ack
		lw		$r1,[sp]
		lw		lr,8[sp]
		ret		#16

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get ID - get the keyboards identifier code.
;
; Parameters: none
; Returns: r1 = $AB83, $00 on fail
; Modifies: r1, KeybdID updated
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdGetID:
		push	lr
		push	$a0
		ldi		$a0,#$F2
		call	_KeybdSendByte
		call	_KeybdWaitTx
		call	_KeybdRecvByte
		bbs		r1,#7,.notKbd
		xor		r2,r1,#$AB
		bne		r2,r0,.notKbd
		call	_KeybdRecvByte
		bbs		r1,#7,.notKbd
		xor		r2,r1,#$83
		bne		r2,r0,.notKbd
		ldi		r1,#$AB83
.0001:
		sc		r1,_KeybdID
		lw		$a0,[sp]
		lw		lr,8[sp]
		ret		#16
.notKbd:
		ldi		r1,#$00
		bra		.0001

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
; Parameters: none
; Returns: r1 = recieved byte ($00 to $FF), -1 on timeout
; Modifies: r1
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdRecvByte:
  	push  lr
		push	r3
		ldi		r3,#100			; wait up to 1s
.0003:
		call	_KeybdGetStatus	; wait for response from keyboard
		bbs		r1,#7,.0004			; is input buffer full ? yes, branch
		call	_Wait10ms				; wait a bit
		sub   r3,r3,#1
		bne   r3,r0,.0003			; go back and try again
		lw		r3,[sp]					; timeout
		lw		lr,8[sp]
		ldi		r1,#-1				; return -1
		ret		#16
.0004:
		call	_KeybdGetScancode
		lw		r3,[sp]
		lw		lr,8[sp]
		ret		#16

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Send a byte to the keyboard.
;
; Parameters: $a0 byte to send
; Returns: none
; Modifies: none
; Stack Space: 0 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdSendByte:
		sb		$a0,KEYBD
		memdb
		ret
	
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for 10 ms
;
; Parameters: none
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_Wait10ms:
		push	r3
    push  r4
    csrrd	r3,#$002,r0		; get orginal count
.0001:
		csrrd	r4,#$002,r0
		sub		r4,r4,r3
		blt  	r4,r0,.0002			; shouldn't be -ve unless counter overflowed
		slt		r4,r4,#100000		; about 10ms at 10 MHz
		bne		r4,r0,.0001
.0002:
		lw		r4,[sp]
		lw		r3,8[sp]
		ret		#16


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for 300 ms
;
; Parameters: none
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_Wait300ms:
		push	r3
    push  r4
    csrrd	r3,#$002,r0		; get orginal count
.0001:
		csrrd	r4,#$002,r0
		sub		r4,r4,r3
		blt  	r4,r0,.0002			; shouldn't be -ve unless counter overflowed
		slt		r4,r4,#3000000	; about 300ms at 10 MHz
		bne		r4,r0,.0001
.0002:
		lw		r4,[sp]
		lw		r3,8[sp]
		ret		#16


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait until the keyboard transmit is complete
;
; Parameters: none
; Returns: r1 = 0 if successful, r1 = -1 timeout
; Modifies: r1
; Stack Space: 3 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdWaitTx:
		push  lr
		push	r2
    push  r3
		ldi		r3,#100			; wait a max of 1s
.0001:
		call	_KeybdGetStatus
		bbs	  r1,#6,.0002	; check for transmit complete bit; branch if bit set
		call	_Wait10ms		; delay a little bit
		sub   r3,r3,#1
		bne	  r3,r0,.0001	; go back and try again
		lw		r3,[sp]
		lw		r2,8[sp]		; timed out
		lw		lr,16[sp]
		ldi		r1,#-1			; return -1
		ret		#24
.0002:
		lw		r3,[sp]
		lw		r2,8[sp]		; wait complete, return 
		lw		lr,16[sp]
		ldi		r1,#0				; return 0
		ret		#24


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the keyboard status
;
; Parameters: none
; Returns: r1 = status
; Modifies: r1
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdGetStatus:
		memsb
		ldi		$v0,#KEYBD+1
		lvb		$v0,[$v0+$r0]
		memdb
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the scancode from the keyboard port
;
; Parameters: none
; Returns: r1 = scancode
; Modifies: r1
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdGetScancode:
		memsb
		ldi		$v0,#KEYBD
		lvbu	$v0,[$v0+$r0]		; get the scan code
		memdb									; need the following store in order
		sb		$r0,KEYBD+1			; clear receive register
		memdb
		ret

