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
SC_KEYUP	EQU		$F0
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
; Returns: accb = recieved byte ($00 to $FF), -1 on timeout
; Modifies: acc
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdRecvByte:
		pshs	x
		ldx		#100						; wait up to 1s
krb3:
		bsr		_KeybdGetStatus	; wait for response from keyboard
		tstb
		bmi		krb4						; is input buffer full ? yes, branch
		bsr		_Wait10ms				; wait a bit
		leax	-1,x
		bne		krb3						; go back and try again
		ldd		#-1							; return -1
		puls	x,pc
krb4:
		bsr		_KeybdGetScancode
		puls	x,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Send a byte to the keyboard.
;
; Parameters: accb byte to send
; Returns: none
; Modifies: none
; Stack Space: 0 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdSendByte:
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

_KeybdWaitTx:
		pshs	x
		ldx		#100				; wait a max of 1s
kwt1:
		bsr		_KeybdGetStatus
		andb	#$40				; check for transmit complete bit; branch if bit set
		bne		kwt2
		bsr		_Wait10ms		; delay a little bit
		leax	-1,x
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

_Wait10ms:
	pshs	d
	lda		MSCOUNT+3
W10_0001:
	tfr		a,b
	subb	MSCOUNT+3
	cmpb	#$FA
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

_Wait300ms:
	pshs	d
	lda		MSCOUNT+3
W300_0001:
	tfr		a,b
	subb	MSCOUNT+3
	cmpb	#1
	bne 	W300_0001
	puls	d,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the keyboard status
;
; Parameters: none
; Returns: d = status
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdGetStatus:
	ldb		KEYBD+1
	sex
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get the scancode from the keyboard port
;
; Parameters: none
; Returns: acca = scancode
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdGetScancode:
	clra
	ldb		KEYBD				; get the scan code
	clr		KEYBD+1			; clear receive register
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set the LEDs on the keyboard.
;
; Parameters: d LED status to set
; Returns: none
; Modifies: none
; Stack Space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_KeybdSetLED:
		pshs	b
		ldb		#$ED						; set LEDs command
		bsr		_KeybdSendByte
		bsr		_KeybdWaitTx
		bsr		_KeybdRecvByte	; should be an ack
		puls	b
		bsr		_KeybdSendByte
		bsr		_KeybdWaitTx
		bsr		_KeybdRecvByte	; should be an ack
		rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_DBGCheckForKey:
	bra		_KeybdGetStatus


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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Parameters:
;		b:	0 = non blocking, otherwise blocking
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_DBGGetKey:
	pshs	x
dbgk2:
	pshs	b
	bsr		_KeybdGetStatus
	andb	#$80
	bne		dbgk1
	tst		,s								; block?
	leas	1,s
	beq		dbgk2							; If no key and blocking - loop
	ldd		#-1								; return -1 if no block and no key
	puls	b,pc
dbgk1:
	bsr		_KeybdGetScancode
	; Make sure there is a small delay between scancode reads
	ldx		#20
dbgk3:
	leax	-1,x
	bne		dbgk3
	; switch on scan code
	cmpb	#SC_KEYUP
	bne		dbgk4
	clr		KeyState1					; make KeyState1 = -1
	neg		KeyState1
	puls	b
	bra		dbgk2							; loop back
dbgk4:
	cmpb	#SC_EXTEND
	bne		dbgk5
	lda		KeyState2
	ora		#$80
	sta		KeyState2
	puls	b
	bra		dbgk2
dbgk5:
	cmpb	#SC_CTRL
	bne		dbgkNotCtrl
	tst		KeyState1
	bmi		dbgk7
	lda		KeyState2
	ora		#4
	sta		KeyState2
	bra		dbgk8
dbgk7:
	lda		KeyState2
	and		#~4
	sta		KeyState2
dbgk8:
	clr		KeyState1
	puls	b
	bra		dbgk2
dbgkNotCtrl:
	cmpb	#SC_RSHIFT
	bne		dbgkNotRshift
	tst		KeyState1
	bmi		dbgk9
	lda		KeyState2
	ora		#1
	sta		KeyState2
	bra		dbgk10
dbgk9:
	lda		KeyState2
	and		#~1
	sta		KeyState2
dbgk10:
	clr		KeyState1
	puls	b
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
	bsr		_KeybdSetLED
	puls	b
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
	bsr		_KeybdSetLED
	puls	b
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
	bsr		_KeybdSetLED
	puls	b
	bra		dbgk2
dbgkNotScrolllock:
	cmpb	#SC_ALT
	bne		dbgkNotAlt
	tst		KeyState1
	bmi		dbgk11
	lda		KeyState2
	ora		#2
	sta		KeyState2
	bra		dbgk12
dbgk11:
	lda		KeyState2
	and		#~2
	sta		KeyState2
dbgk12:
	clr		KeyState1
	puls	b
	bra		dbgk2
dbgkNotAlt:
	tst		KeyState1
	beq		dbgk13
	clr		KeyState1
	puls	b
	bra		dbgk2
dbgk13:
	lda		KeyState2		; Check for CTRL-ALT-DEL
	anda	#6+
	cmpa	#6
	bne		dbgk14
	cmpb	#SC_DEL	
	bne		dbgk14
	jmp		[$FFFFFE]		; jump to reset vector
dbgk14:
	tst		KeyState2		; extended code?
	bpl		dbgk15
	lda		KeyState2
	anda	#$7F
	sta		KeyState2
	ldx		#_keybdExtendedCodes
	abx
	ldb		,x
	clra
	leas	1,s					; pop b
	puls	x,pc				; and return
dbgk15:
	lda		KeyState2		; Is CTRL down?
	anda	#4
	beq		dbgk16
	ldx		#_keybdControlCodes
	abx
	ldb		,x
	clra
	leas	1,s					; pop b
	puls	x,pc				; and return
dbgk16:
	lda		KeyState2		; Is shift down?
	anda	#1
	beq		dbgk17
	ldx		#_shiftedScanCodes
	abx
	ldb		,x
	clra
	leas	1,s					; pop b
	puls	x,pc				; and return
dbgk17:
	ldx		#_unshiftedScanCodes
	abx
	ldb		,x
	clra
	leas	1,s					; pop b
	puls	x,pc				; and return
	