; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
;	Keyboard driver routines to interface to a PS2 style keyboard
; Converts the scancode to ascii
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
SC_F12	EQU     $07
SC_C    EQU 		$21
SC_T    EQU	    $2C
SC_Z 		EQU     $1A
SC_DEL	EQU			$71	; extend
SC_KEYUP	EQU		$F0	; should be $f0
SC_EXTEND EQU	  $E0
SC_CTRL	EQU			$14
SC_RSHIFT		EQU	$59
SC_NUMLOCK	EQU	$77
SC_SCROLLLOCK		EQU	$7E
SC_CAPSLOCK		EQU		$58
SC_ALT	EQU			$11

;#define SC_LSHIFT	EQU		$12
;SC_DEL		EQU		$71		; extend
;SC_LCTRL	EQU		$58

SC_TAB	EQU     $0D

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
; Parameters: none
; Returns: accd = recieved byte ($00 to $FF), -1 on timeout
; Modifies: acc
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdRecvByte:
	pshs	x
	ldx		#100						; wait up to 1s
krb3:
	bsr		KeybdGetStatus	; wait for response from keyboard
	tstb
	bmi		krb4						; is input buffer full ? yes, branch
	bsr		Wait10ms				; wait a bit
	dex
	bne		krb3						; go back and try again
	ldd		#-1							; return -1
	puls	x,pc
krb4:
	bsr		KeybdGetScancode
	puls	x,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Send a byte to the keyboard.
;
; Parameters: accb byte to send
; Returns: none
; Modifies: none
; Stack Space: 0 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdSendByte:
	stb		KEYBD
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait until the keyboard transmit is complete
;
; Parameters: none
; Returns: r1 = 0 if successful, r1 = -1 timeout
; Modifies: r1
; Stack Space: 3 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdWaitTx:
	pshs	x
	ldx		#100				; wait a max of 1s
kwt1:
	bsr		KeybdGetStatus
	andb	#$40				; check for transmit complete bit; branch if bit set
	bne		kwt2
	bsr		Wait10ms		; delay a little bit
	dex
	bne		kwt1				; go back and try again
	ldd		#-1					; timed out, return -1
	puls	x,pc
kwt2:
	clra							; wait complete, return 0
	clrb							
	puls	x,pc				

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for 10 ms
;
; Parameters: none
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Wait10ms:
	pshs	d
	lda		MSCOUNT+3
W10_0001:
	tfr		a,b
	subb	MSCOUNT+3
	cmpb	#$FFA
	bhi		W10_0001
	puls	d,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for 300 ms (256 ms)
;
; Parameters: none
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Wait300ms:
	pshs	d
	lda		MSCOUNT+3
W300_0001:
	tfr		a,b
	subb	MSCOUNT+3
	cmpb	#$F00
	bhi 	W300_0001
	puls	d,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the keyboard status
;
; Parameters: none
; Returns: d = status
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdGetStatus:
kbgs3:
	ldb		KEYBD+1
	bitb	#$80
	bne		kbgs1
	bitb	#$01		; check parity error flag
	bne		kbgs2
	clra
	rts
kbgs2:
	ldb		#$FE		; request resend
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bra		kbgs3
kbgs1:					; return negative status
	orb		#$F00
	lda		#-1
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the scancode from the keyboard port
;
; Parameters: none
; Returns: acca = scancode
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdGetScancode:
	clra
	ldb		KEYBD				; get the scan code
	clr		KEYBD+1			; clear receive register (write $00 to status reg)
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set the LEDs on the keyboard.
;
; Parameters: d LED status to set
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdSetLED:
	pshs	b
	ldb		#$ED						; set LEDs command
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte	; should be an ack
	puls	b
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte	; should be an ack
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get ID - get the keyboards identifier code.
;
; Parameters: none
; Returns: d = $AB83, $00 on fail
; Modifies: d, KeybdID updated
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdGetID:
	ldb		#$F2
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte
	bitb	#$80
	bne		kgnotKbd
	cmpb	#$AB
	bne		kgnotKbd
	bsr		KeybdRecvByte
	bitb	#$80
	bne		kgnotKbd
	cmpb	#$83
	bne		kgnotKbd
	ldd		#$AB83
kgid1:
	std		KeybdID
	rts
kgnotKbd:
	clra
	clrb
	bra		kgid1

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize the keyboard.
;
; Parameters:
;		none
;	Modifies:
;		none
; Returns:
;		none
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdInit:
	pshs	d,y
	ldy		#5
	clr		KeyState1		; records key up/down state
	clr		KeyState2		; records shift,ctrl,alt state
kbdi0002:
	bsr		Wait10ms
	clr		KEYBD+1			; clear receive register (write $00 to status reg)
	ldb		#-1					; send reset code to keyboard
	stb		KEYBD+1			; write $FF to status reg to clear TX state
	bsr		KeybdSendByte	; now write to transmit register
	bsr		KeybdWaitTx		; wait until no longer busy
	bsr		KeybdRecvByte	; look for an ACK ($FA)
	cmpb	#$FA
	bne		kbdiTryAgain
	bsr		KeybdRecvByte	; look for BAT completion code ($AA)
	cmpb	#$FC				; reset error ?
	beq		kbdiTryAgain
	cmpb	#$AA				; reset complete okay ?
	bne		kbdiTryAgain

	; After a reset, scan code set #2 should be active
.config:
	ldb		#$F0			; send scan code select
	stb		LEDS
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	tstb
	bmi		kbdiTryAgain
	bsr		KeybdRecvByte	; wait for response from keyboard
	tsta
	bmi		kbdiTryAgain
	cmpb	#$FA					; ACK
	beq		kbdi0004
kbdiTryAgain:
	dey
	bne	  kbdi0002
.keybdErr:
	ldd		#msgBadKeybd
	lbsr	DisplayStringCRLF
	bra		ledxit
kbdi0004:
	ldb		#2			; select scan code set #2
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	tstb
	bmi		kbdiTryAgain
	bsr		KeybdRecvByte	; wait for response from keyboard
	tsta
	bmi		kbdiTryAgain
	cmpb	#$FA
	bne		kbdiTryAgain
	bsr		KeybdGetID
ledxit:
	ldb		#$07
	bsr		KeybdSetLED
	bsr		Wait300ms
	ldb		#$00
	bsr		KeybdSetLED
	puls	d,y,pc

msgBadKeybd:
	fcb		"Keyboard error",0

;------------------------------------------------------------------------------
; Calculate number of character in input buffer
;
; Parameters:
;		y = $Cn00000 where n is core id
; Returns:
;		d = number of bytes in buffer.
;------------------------------------------------------------------------------

kbdRcvCount:
	clra
	ldb		kbdTailRcv,y
	subb	kbdHeadRcv,y
	bge		krcXit
	ldb		#$40
	subb	kbdHeadRcv,y
	addb	kbdTailRcv,y
krcXit:
	rts


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

KeybdIRQ:
	lda		KEYBD+1						; check status
	bita	#$80							; was key pressed?
	beq		notKbdIRQ					; if not, exit
	ldb		KEYBD							; get the scan code
	clr		KEYBD+1						; clear receive register (write $00 to status reg)
	pshs	b									; save it off
	lda		IOFocusID					; compute core memory address $Cn0000
	clrb
	asla
	asla
	asla
	asla
	ora		#$C00							; address $Cn0000	
	tfr		d,y								; y =
	bsr		kbdRcvCount				; get count of scan codes in buffer
	cmpb	#64								; check if buffer full?
	bhs		kbdBufFull				; if buffer full, ignore new keystroke
	tfr		y,x								; compute fifo address
	ldb		kbdTailRcv,y			; b = buffer index
	puls	a									; get back scancode
	leax	kbdFifo,x					; x = base address for fifo
	sta		b,x								; store in buffer
	incb										; increment buffer index
	andb	#$3f							; wrap around at 64 chars
	stb		kbdTailRcv,y			; update it
	lda		#28								; Keyboard is IRQ #28
	sta		IrqSource					; stuff a byte indicating the IRQ source for PEEK()
notKbdIRQ:
	rts	
kbdBufFull:
	leas	1,s								; get rid of saved scancode
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DBGCheckForKey:
	bra		KeybdGetStatus


; KeyState2 variable bit meanings
;1176543210
; ||||||||+ = shift
; |||||||+- = alt
; ||||||+-- = control
; |||||+--- = numlock
; ||||+---- = capslock
; |||+----- = scrolllock
; ||+------ = <empty>
; |+------- =    "
; |         =    "
; |         =    "
; |         =    "
; +-------- = extended

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Keyboard get routine.
;
; The routine may get characters directly from the scancode input or less
; directly from the scancode buffer, if things are interrupt driven.
;
; Parameters:
;		b:  bit 11 = blocking status 1=blocking, 0=non blocking
;		b:	bit 1  = scancode source 1=scancode buffer, 0=direct
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

GetKey:
	pshs	x,y
	stb		KeybdBlock				; save off blocking status
dbgk2:
	ldb		KeybdBlock
	pshs	b
	bitb	#1								; what is the scancode source
	beq		dbgk20						; branch if direct read
	lda		COREID						; compute core memory address
	clrb
	asla
	asla
	asla
	asla
	ora		#$C00
	tfr		d,y								; y = $Cn0000
	bsr		kbdRcvCount
	tstb										; anything in buffer?
	puls	b
	bne		dbgk1							; branch if something in buffer
	tstb
	bmi		dbgk2							; if no key and blocking - loop
	bra		dbgk24
dbgk20:
	ldy		#0
	bsr		KeybdGetStatus
	andb	#$80							; is key available?
	puls	b
	bne		dbgk1							; branch if key
	tstb										; block?
	bmi		dbgk2							; If no key and blocking - loop
dbgk24:
	ldd		#-1								; return -1 if no block and no key
	puls	x,y,pc
dbgk1:
	cmpy	#0
	bne		dbgk22
	bsr		KeybdGetScancode	; get scancode directly
	bra		dbgk23
dbgk22:
	; Retrieve value from scancode buffer
	tfr		y,x
	leax	kbdFifo,x					; x = fifo address
	ldb		kbdHeadRcv,y			; b = buffer index
	lda		b,x								; get the scancode
	incb										; increment fifo index
	andb	#$3f							; and wrap around
	stb		kbdHeadRcv,y			; save it back
	tfr		a,b								; the scancode is needed in accb
dbgk23:
;	lbsr	DispByteAsHex
	; Make sure there is a small delay between scancode reads
	ldx		#20
dbgk3:
	dex
	bne		dbgk3
	; switch on scan code
	cmpb	#SC_KEYUP
	bne		dbgk4
	stb		KeyState1					; make KeyState1 <> 0
	bra		dbgk2							; loop back
dbgk4:
	cmpb	#SC_EXTEND
	bne		dbgk5
	lda		KeyState2
	ora		#$800
	sta		KeyState2
	bra		dbgk2
dbgk5:
	cmpb	#SC_CTRL
	bne		dbgkNotCtrl
	tst		KeyState1
	bne		dbgk7
	lda		KeyState2
	ora		#4
	sta		KeyState2
	bra		dbgk8
dbgk7:
	lda		KeyState2
	anda	#~4
	sta		KeyState2
dbgk8:
	clr		KeyState1
	bra		dbgk2
dbgkNotCtrl:
	cmpb	#SC_RSHIFT
	bne		dbgkNotRshift
	tst		KeyState1
	bne		dbgk9
	lda		KeyState2
	ora		#1
	sta		KeyState2
	bra		dbgk10
dbgk9:
	lda		KeyState2
	anda	#~1
	sta		KeyState2
dbgk10:
	clr		KeyState1
	bra		dbgk2
dbgkNotRshift:
	cmpb	#SC_NUMLOCK
	bne		dbgkNotNumlock
	lda		KeyState2
	eora	#16
	sta		KeyState2
	lda		KeyLED
	eora	#2
	sta		KeyLED
	tfr		a,b
	clra
	bsr		KeybdSetLED
	bra		dbgk2
dbgkNotNumlock:
	cmpb	#SC_CAPSLOCK
	bne		dbgkNotCapslock
	lda		KeyState2
	eora	#32
	sta		KeyState2
	lda		KeyLED
	eora	#4
	sta		KeyLED
	tfr		a,b
	clra
	bsr		KeybdSetLED
	bra		dbgk2
dbgkNotCapslock:
	cmpb	#SC_SCROLLLOCK
	bne		dbgkNotScrolllock
	lda		KeyState2
	eora	#64
	sta		KeyState2
	lda		KeyLED
	eora	#1
	sta		KeyLED
	tfr		a,b
	clra
	bsr		KeybdSetLED
	bra		dbgk2
dbgkNotScrolllock:
	cmpb	#SC_ALT
	bne		dbgkNotAlt
	tst		KeyState1
	bne		dbgk11
	lda		KeyState2
	ora		#2
	sta		KeyState2
	bra		dbgk12
dbgk11:
	lda		KeyState2
	anda	#~2
	sta		KeyState2
dbgk12:
	clr		KeyState1
	bra		dbgk2
dbgkNotAlt:
	tst		KeyState1
	beq		dbgk13
	clr		KeyState1
	bra		dbgk2
dbgk13:
	lda		KeyState2		; Check for CTRL-ALT-DEL
	anda	#6
	cmpa	#6
	bne		dbgk14
	cmpb	#SC_DEL	
	bne		dbgk14
	jmp		[$FFFFFC]		; jump to NMI vector
dbgk14:
	tst		KeyState2		; extended code?
	bpl		dbgk15
	lda		KeyState2
	anda	#$7FF
	sta		KeyState2
	ldx		#keybdExtendedCodes
	bra		dbgk18
dbgk15:
	lda		KeyState2		; Is CTRL down?
	bita	#4
	beq		dbgk16
	ldx		#keybdControlCodes
	bra		dbgk18
dbgk16:
	bita	#1					; Is shift down?
	beq		dbgk17
	ldx		#shiftedScanCodes
	bra		dbgk18
dbgk17:
	ldx		#unshiftedScanCodes
dbgk18:
	ldb		b,x					; load accb with ascii from table
	clra
	puls	x,y,pc			; and return
	