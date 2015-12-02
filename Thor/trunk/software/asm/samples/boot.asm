
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
CR	EQU	0x0D		;ASCII equates
LF	EQU	0x0A
TAB	EQU	0x09
CTRLC	EQU	0x03
CTRLH	EQU	0x08
CTRLI	EQU	0x09
CTRLJ	EQU	0x0A
CTRLK	EQU	0x0B
CTRLM   EQU 0x0D
CTRLS	EQU	0x13
CTRLX	EQU	0x18
XON		EQU	0x11
XOFF	EQU	0x13

SC_LSHIFT	EQU		$12
SC_RSHIFT	EQU		$59
SC_KEYUP	EQU		$F0
SC_EXTEND	EQU		$E0
SC_CTRL		EQU		$14
SC_ALT		EQU		$11
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
SC_NUMLOCK	EQU		$77
SC_SCROLLLOCK	EQU	$7E
SC_CAPSLOCK	EQU		$58

IOBASE_ADDR	EQU		0xFFD00000
LEDS		EQU		0xC0600
TEXTSCR		EQU		0x00000
TEXTSCR2	EQU		0x10000
TEXTREG		EQU		0xA0000
TEXT_COLS	EQU		0x0
TEXT_ROWS	EQU		0x2
TEXT_CURPOS	EQU		0x16
KEYBD		EQU		0xC0000

KeyState1	EQU		$08
KeyState2	EQU		$09
KeybdLEDs	EQU		$0A
KeybdWaitFlag	EQU	$0B

CursorX		EQU		$30
CursorY		EQU		$32
VideoPos	EQU		$34
NormAttr	EQU		$36

	code
	org		$FFFF8000

cold_start:
		; Initialize segment registers for flat model
		mtspr	cs,r0
		mtspr	zs,r0
		mtspr	ds,r0
		mtspr	es,r0
		mtspr	fs,r0
		mtspr	gs,r0
		mtspr	hs,r0
		mtspr	ss,r0

		ldi		r1,#1
		sc		r1,$FFDC0600

		tlbwrreg DMA,r0				; clear TLB miss registers
		tlbwrreg IMA,r0
		ldi			r1,#2			; 2 wired registers
		tlbwrreg	Wired,r1
		ldi			r1,#$2			; 64kiB page size
		tlbwrreg	PageSize,r1

		; setup the first translation
		; virtual page $FFFF0000 maps to physical page $FFFF0000
		; This places the BIOS ROM at $FFFFxxxx in the memory map
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		ldi			r1,#$0FFFF
		tlbwrreg	VirtPage,r1
		tlbwrreg	PhysPage,r1
		tlbwrreg	Index,r0		; select way #0
		tlbwi						; write to TLB entry group #0 with hold registers

		; setup second translation
		; virtual page 0 maps to physical page 0
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		tlbwrreg	VirtPage,r0
		tlbwrreg	PhysPage,r0
		ldi			r1,#8			; select way#1
		tlbwrreg	Index,r1		
		tlbwi						; write to TLB entry group #0 with hold registers

		; turn on the TLB
;		tlben

		; set interrupt table at $0000
		ldis	c12,#0

		ldi		r27,#$10000		; initialize SP
		ldis	hs,#IOBASE_ADDR
		ldi		r1,#2
		sc		r1,$FFDC0600
		bsr		ClearScreen
;		bsr		ClearScreen2
		bsr		HomeCursor
		ldi		r2,#TEXTSCR
.0001:
		bsr		KeybdGetCharWait
		or		r1,r1,#%000000111_111111111_00_00000000
		sh		r1,hs:[r2]
		addui	r2,r2,#4
		br		.0001


		add		r1,r2,r3

ClearScreen:
		ldi		r1,#TEXTSCR
		ldi		r2,#' '|%000000111_111111111_00_00000000;
		ldi		r3,#20
.0001:
		sc		r2,hs:[r1]
		addui	r1,r1,#4
		addui	r3,r3,#-1
		tst		p0,r3
p0.ge	br		.0001
;		stsh	r2,hs:[r1]
		rts

ClearScreen2:
		ldis	lc,#4096
		ldi		r2,#' '|%000111000_111111111_00_00000000;
		ldi		r1,#TEXTSCR2
		stsh	r2,hs:[r1]
		rts

HomeCursor:
		sc		r0,CursorX
		sc		r0,CursorY
		sc		r0,VideoPos
		sc		r0,hs:TEXTREG+44
		rts

;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;------------------------------------------------------------------------------

AsciiToScreen:
		andi	r1,r1,#$FF
		biti	p0,r1,#%00100000	; if bit 5 isn't set
p0.eq	br		.00001
		biti	p0,r1,#%01000000	; or bit 6 isn't set
p0.ne	and		r1,r1,#%10011111
.00001:
		rts

;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
ScreenToAscii:
		andi	r1,r1,#$FF
		cmpi	p0,r1,#27
p0.le	addi	r1,r1,#$60
		rts

;.include "DisplayChar.asm"

KeybdGetCharWait:
		ldi		r1,#-1
		sb		r1,KeybdWaitFlag
		br		KeybdGetChar

KeybdGetCharNoWait:
		sb		r0,KeybdWaitFlag
		br		KeybdGetChar

; Wait for a keyboard character to be available
; Returns (-1) if no key available
; Return key >= 0 if key is available
;
;
KeybdGetChar:
KeybdGetChar1:
		push	c1				; save off link register
.0002:
.0003:
		lvb		r1,hs:KEYBD+1	; check MSB of keyboard status reg.
		tst		p0,r1
p0.lt	br		.0006
		lb		r1,KeybdWaitFlag
		tst		p0,r1
p0.lt	br		.0003
		lws		c1,[r27]
		addui	r27,r27,#8
		rts
.0006:
		lvb		r1,hs:KEYBD		; get scan code value
		memdb
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
		andi	r2,r2,#1
		cmp		p0,r2,#0
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
p0.eq	br		.0007
		andi	r1,r1,#$FF
		lbu		r1,cs:shiftedScanCodes[r1]
		br		.0008
.0007:
		andi	r1,r1,#$FF
		lbu		r1,cs:unshiftedScanCodes[r1]
.0008:
		lws		c1,[r27]
		addui	r27,r27,#8
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
p0.eq	br		.0004
		lbu		r2,KeyState2
		andi	r2,r2,#~4
		sb		r2,KeyState2
		br		.0003
.0004:
		lbu		r2,KeyState2
		ori		r2,r2,#4
		sb		r2,KeyState2
		br		.0003
.doShift:
		lb		r2,KeyState1
		biti	p0,r2,#1
p0.eq	br		.0005
		lbu		r2,KeyState2
		andi	r2,r2,#~1
		sb		r2,KeyState2
		br		.0003
.0005:
		lbu		r2,KeyState2
		ori		r2,r2,#1
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

KeybdSetLEDStatus:
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

		org		$FFFFFF80
		jmp		cold_start[C15]

