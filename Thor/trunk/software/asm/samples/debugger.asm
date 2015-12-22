
; ============================================================================
;        __
;   \\__/ o\    (C) 2015  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
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
public KeybdGetCharWait:
		ldi		r1,#-1
		sb		r1,KeybdWaitFlag
		br		KeybdGetChar
endpublic

public KeybdGetCharNoWait:
		sb		r0,KeybdWaitFlag
		br		KeybdGetChar
endpublic

; Wait for a keyboard character to be available
; Returns (-1) if no key available
; Return key >= 0 if key is available
;
;
KeybdGetChar:
KeybdGetChar1:
		addui	sp,sp,#-24
		sw		r2,[sp]
		sws		c1,8[sp]		; save off link register
		sws		hs,16[sp]
		ldis	hs,#$FFD00000
.0002:
.0003:
		memsb
		lvb		r1,hs:KEYBD+1	; check MSB of keyboard status reg.
		biti	p0,r1,#$80
p0.ne	br		.0006
		lb		r1,KeybdWaitFlag
		tst		p0,r1
p0.lt	br		.0003
		br		.0008
.0006:
		memsb
		lvb		r1,hs:KEYBD		; get scan code value
		memdb
		zxb		r1,r1			; make unsigned
		sb		r0,hs:KEYBD+1	; clear read flag
.0001:
		cmp		p0,r1,#SC_KEYUP	; keyup scan code ?
p0.eq	br		.doKeyup
		cmp		p0,r1,#SC_EXTEND; extended scan code ?
p0.eq	br		.doExtend
		cmp		p0,r1,#$14		; control ?
p0.eq	br		.doCtrl
		cmp		p0,r1,#$12		; left shift
p0.eq	br		.doShift
		cmp		p0,r1,#$59		; right shift
p0.eq	br		.doShift
		cmp		p0,r1,#SC_NUMLOCK
p0.eq	br		.doNumLock
		cmp		p0,r1,#SC_CAPSLOCK
p0.eq	br		.doCapsLock
		cmp		p0,r1,#SC_SCROLLLOCK
p0.eq	br		.doScrollLock
		lb		r2,KeyState1
		sb		r0,KeyState1
		andi	r2,r2,#1
		cmpi	p0,r2,#0
p0.ne	br		.0003
		lb		r2,KeyState2	; Is extended code ?
		andi	r2,r2,#$80
p0.eq	br		.0010
		lb		r2,KeyState2
		andi	r2,r2,#$7F
		sb		r2,KeyState2
		sb		r0,KeyState1	; clear keyup
		andi	r1,r1,#$7F
		lbu		r1,cs:keybdExtendedCodes[r1]
		br		.0008
.0010:
		lb		r2,KeyState2
		biti	p0,r2,#4		; Is Cntrl down ?
p0.eq	br		.0009
		andi	r1,r1,#$7F
		lbu		r1,cs:keybdControlCodes[r1]
		br		.0008
.0009:
		lb		r2,KeyState2
		biti	p0,r2,#1		; Is shift down ?
		andi	r1,r1,#$FF
p0.ne	lbu		r1,cs:shiftedScanCodes[r1]
p0.eq	lbu		r1,cs:unshiftedScanCodes[r1]
.0008:
		lw		r2,[sp]
		lws		c1,8[sp]
		lws		hs,16[sp]
		addui	sp,sp,#24
		rts

.doKeyup:
		lb		r2,KeyState1
		ori		r2,r2,#1
		sb		r2,KeyState1
		br		.0003
.doExtend:
		lb		r2,KeyState2
		ori		r2,r2,#$80
		sb		r2,KeyState2
		br		.0003
.doCtrl:
		lb		r2,KeyState1
		biti	p0,r2,#1
		lbu		r2,KeyState2
p0.eq	ori		r2,r2,#4
p0.ne	andi	r2,r2,#~4
		sb		r2,KeyState2
		br		.0003
.doShift:
		lb		r2,KeyState1
		biti	p0,r2,#1
		lbu		r2,KeyState2
p0.eq	ori		r2,r2,#1
p0.ne	andi	r2,r2,#~1
		sb		r2,KeyState2
		br		.0003
.doNumLock:
		lbu		r2,KeyState2
		eori	r2,r2,#16
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003
.doCapsLock:
		lbu		r2,KeyState2
		eori	r2,r2,#32
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003
.doScrollLock:
		lbu		r2,KeyState2
		eori	r2,r2,#64
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003

;------------------------------------------------------------------------------
; Set the keyboard LED status leds.
; Trashes r1, p0
;------------------------------------------------------------------------------

KeybdSetLEDStatus:
		addui	r27,r27,#-8
		sws		c1,[r27]
		sb		r0,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#16
p0.ne	lb		r1,KeybdLEDs	; set bit 1 for Num lock, 0 for scrolllock , 2 for caps lock
p0.ne	ori		r1,r1,#2
p0.ne	sb		r1,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#32
p0.ne	lb		r1,KeybdLEDs
p0.ne	ori		r1,r1,#4
p0.ne	sb		r1,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#64
p0.ne	lb		r1,KeybdLEDs
p0.ne	ori		r1,r1,#1
p0.ne	sb		r1,KeybdLEDs
		ldi		r1,#$ED
		sb		r1,hs:KEYBD		; set status LEDs command
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
		cmpi	p0,r1,#$FA
		lb		r1,KeybdLEDs
		sb		r1,hs:KEYBD		
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
		lws		c1,[r27]
		addui	r27,r27,#8
		rts

;------------------------------------------------------------------------------
; Receive a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
; Returns:
;	r1 >= 0 if a scancode is available
;   r1 = -1 on timeout
;------------------------------------------------------------------------------
;
KeybdRecvByte:
		addui	r27,r27,#-16
		sws		c1,8[r27]
		sw		r3,[r27]
		ldi		r3,#20			; wait up to .2s
.0003:
		bsr		KeybdWaitBusy
		lb		r1,hs:KEYBD+1	; wait for response from keyboard
		biti	p0,r1,#$80		; is input buffer full ?
p0.ne	br		.0004			; yes, branch
		bsr		Wait10ms		; wait a bit
		addui	r3,r3,#-1
		tst		p0,r3
p0.ne	br		.0003			; go back and try again
		lw		r3,[r27]		; timeout
		lws		c1,8[r27]
		addui	r27,r27,#16
		ldi		r1,#-1
		rts
.0004:
		lvb		r1,hs:KEYBD		; get scancode
		zxb		r1,r1			; convert to unsigned char
		sb		r0,hs:KEYBD+1	; clear recieve state
		lw		r3,[r27]
		lws		c1,8[r27]
		addui	r27,r27,#16
		rts						; return char in r1

;------------------------------------------------------------------------------
; Wait until the keyboard isn't busy anymore
; Wait until the keyboard transmit is complete
; Returns:
;    r1 >= 0 if successful
;	 r1 < 0 if timed out
;------------------------------------------------------------------------------
;
KeybdWaitBusy:				; alias for KeybdWaitTx
KeybdWaitTx:
		addui	r27,r27,#-16
		sws		c1,8[r27]
		sw		r3,[r27]
		ldi		r3,#10			; wait a max of .1s
.0001:
		lvb		r1,hs:KEYBD+1
		biti	p0,r1,#$40		; check for transmit busy bit
p0.eq	br		.0002			; branch if bit clear
		bsr		Wait10ms		; delay a little bit
		addui	r3,r3,#-1		; go back and try again
		tst		p0,r3
p0.ne	br		.0001
		lw		r3,[r27]		; timed out
		lws		c1,8[r27]
		addui	r27,r27,#16
		ldi		r1,#-1			; return -1
		rts
.0002:
		lw		r3,[r27]		; wait complete, return 
		lws		c1,8[r27]		; restore return address
		ldi		r1,#0			; return 0 for okay
		addui	r27,r27,#16
		rts

;------------------------------------------------------------------------------
; Delay for about 10 ms.
;------------------------------------------------------------------------------

Wait10ms:
		addui	r27,r27,#-16
		sw		r1,8[r27]
		sw		r2,[r27]
		mfspr	r1,tick
		addui	r1,r1,#250000	; 10ms at 25 MHz
.0001:
		mfspr	r2,tick
		cmp		p0,r2,r1
p0.lt	br		.0001
		lw		r2,[r27]
		lw		r1,8[r27]
		addui	r27,r27,#16
		rts

	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
unshiftedScanCodes:
	byte	$2e,$a9,$2e,$a5,$a3,$a1,$a2,$ac
	byte	$2e,$aa,$a8,$a6,$a4,$09,$60,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$71,$31,$2e
	byte	$2e,$2e,$7a,$73,$61,$77,$32,$2e
	byte	$2e,$63,$78,$64,$65,$34,$33,$2e
	byte	$2e,$20,$76,$66,$74,$72,$35,$2e
	byte	$2e,$6e,$62,$68,$67,$79,$36,$2e
	byte	$2e,$2e,$6d,$6a,$75,$37,$38,$2e
	byte	$2e,$2c,$6b,$69,$6f,$30,$39,$2e
	byte	$2e,$2e,$2f,$6c,$3b,$70,$2d,$2e
	byte	$2e,$2e,$27,$2e,$5b,$3d,$2e,$2e
	byte	$ad,$2e,$0d,$5d,$2e,$5c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	byte	$98,$7f,$92,$2e,$91,$90,$1b,$af
	byte	$ab,$2e,$97,$2e,$2e,$96,$ae,$2e

	byte	$2e,$2e,$2e,$a7,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$fa,$2e,$2e,$2e,$2e,$2e

shiftedScanCodes:
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$51,$21,$2e
	byte	$2e,$2e,$5a,$53,$41,$57,$40,$2e
	byte	$2e,$43,$58,$44,$45,$24,$23,$2e
	byte	$2e,$20,$56,$46,$54,$52,$25,$2e
	byte	$2e,$4e,$42,$48,$47,$59,$5e,$2e
	byte	$2e,$2e,$4d,$4a,$55,$26,$2a,$2e
	byte	$2e,$3c,$4b,$49,$4f,$29,$28,$2e
	byte	$2e,$3e,$3f,$4c,$3a,$50,$5f,$2e
	byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

; control
keybdControlCodes:
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$11,$21,$2e
	byte	$2e,$2e,$1a,$13,$01,$17,$40,$2e
	byte	$2e,$03,$18,$04,$05,$24,$23,$2e
	byte	$2e,$20,$16,$06,$14,$12,$25,$2e
	byte	$2e,$0e,$02,$08,$07,$19,$5e,$2e
	byte	$2e,$2e,$0d,$0a,$15,$26,$2a,$2e
	byte	$2e,$3c,$0b,$09,$0f,$29,$28,$2e
	byte	$2e,$3e,$3f,$0c,$3a,$10,$5f,$2e
	byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

keybdExtendedCodes:
	byte	$2e,$2e,$2e,$2e,$a3,$a1,$a2,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	byte	$98,$99,$92,$2e,$91,$90,$2e,$2e
	byte	$2e,$2e,$97,$2e,$2e,$96,$2e,$2e

