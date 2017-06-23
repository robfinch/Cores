; ============================================================================
;        __
;   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
;                                      
; This boot rom for the input node $21.
; ============================================================================
;
CR	= 13
LF	= 10
CTRLH	equ		9

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

#include "MessageTypes.asm"
			bss
			org		15
HTInputFocus	db	0
KeyState1		db	0
KeyState2		db	0
			align	16
txBuf	fill.b	16,0
rxBuf	fill.b	16,0

ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_TXSTAT	equ	$12
ROUTER_TRB	equ	0

BTNS		equ	$B200
KBD			equ	$B210
KBD_STAT	equ	1
SWITCHES	equ	$B220

MSG_DST		equ	15
MSG_SRC		equ	14
MSG_TTL		equ	9
MSG_TYPE	equ	8
MSG_GSD		equ	7

		.code
		cpu		Butterfly16
		org		0xE000
#include "Network.asm"
;#include "tb.asm"

		.code
start:
		lw		sp,#$1FFE
		call	KeybdReset
		sb		r0,HTInputFocus
		lw		r1,#$111
		sb		r1,HTInputFocus
start1:
noMsg1:
		call	KeybdGetChar
		bne		noKey
		cmp		r1,#'c'
		bne		notC
		lb		r1,KeyState2	; test if CTRL down
		and		r1,#4
		beq		notC
		; CTRL-C
		; If CTRL-C was pressed broadcast a global stop message
		call	zeroTxBuf
		lw		r1,#$FF
		sb		r1,txBuf+MSG_DST
		lw		r1,#MT_STOP
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		bra		noKey
		; There was a keystroke available so transmit a character
		; message to the thread with the input focus
notC:
		lb		r5,HTInputFocus		; any thread with input focus ?
		beq		noKey
		call	zeroTxBuf
		mov		r2,r5
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		sb		r2,txBuf+MSG_DST	; destination is input focus thread
		lw		r2,#$11				; grid numbers are hard coded for now
		sb		r2,txBuf+MSG_GDS
		sb		r1,txBuf			; store ascii char
		sb		r1,txBuf+2
		sb		r1,txBuf+4
		sb		r1,txBuf+6
		sb		r3,txBuf+1			; and scan code
		lw		r1,#MT_KEYSTROKE	; keyboard message
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
noKey:
		lb		r1,ROUTER+RTR_RXSTAT
		and		r1,#63
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start1


;----------------------------------------------------------------------------
; Received message dispatch.
;----------------------------------------------------------------------------

RecvDispatch:
		add		sp,sp,#-2
		sw		lr,[sp]
		lb		r1,rxBuf+MSG_TYPE
		; Reset request ?
		cmp		r1,#MT_RST
		bne		RecvDispatch2
		sb		r0,HTInputFocus
		lw		r1,#$11
		sb		r1,HTInputFocus		; for now
		call	KeybdReset
		call	zeroTxBuf
		lw		r1,#$11
		sb		r1,txBuf+MSG_DST
		lw		r1,#MT_RST_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		bra		RecvDispatchXit
RecvDispatch2:
		cmp		r1,#MT_PING
		bne		RecvDispatch5
		call	zeroTxBuf
		lb		r1,rxBuf+MSG_SRC
		sb		r1,txBuf+MSG_DST
		lw		r1,#MT_PING_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit

		; Load program code
RecvDispatch5:
		cmp		r1,#MT_LOAD_CODE
		br		RecvDispatchXit
		bne		RecvDispatch6
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit

		; Load program data
RecvDispatch6:
		cmp		r1,#MT_LOAD_CODE
		br		RecvDispatchXit
		bne		RecvDispatch7
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit
		; Load program code

		; Execute program
RecvDispatch7:
		cmp		r1,#MT_EXEC_CODE
		br		RecvDispatchXit
		bne		RecvDispatch8
		lw		r1,rxBuf+MSG_SRC
		add		sp,sp,#-2
		sw		r1,[sp]
		lw		r2,rxBuf+4
		call	[r2]
		lw		r2,[sp]
		add		sp,sp,#2
		call	zeroTxBuf
		sw		r1,txBuf+2
		sb		r2,txBuf+MSG_DST
		lw		r1,#$11
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_EXIT
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit

		; Set input focus ?
		; Check for request to set input focus
RecvDispatch8:
		cmp		r1,#MT_SET_INPUT_FOCUS
		bne		RecvDispatch3
		lb		r1,rxBuf
		sb		HTInputFocus
		bra		RecvDispatchXit

		; Get button/switch status ?
RecvDispatch3:
		cmp		r1,#MT_BUTTON_STATUS
		bne		RecvDispatch9
		call	zeroTxBuf
		lb		r1,rxBuf+MSG_SRC		; where did message come from
		sb		r1,txBuf+MSG_DST		; send back to sender
		lw		r1,#MT_BUTTON_STATUS
		sb		r1,txBuf+MSG_TYPE
		lb		r1,BTNS
		sb		r1,txBuf
		lb		r1,SWITCHES
		sb		r1,txBuf+1
		call	Xmit
		bra		RecvDispatchXit
RecvDispatch9:
		bra		RecvDispatchXit
RecvDispatchXit:
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;============================================================================
; Keyboard Code
;============================================================================

;----------------------------------------------------------------------------
; Reset the keyboard.
;----------------------------------------------------------------------------

KeybdReset:
		lw		r1,#$FF
		sb		r1,KBD
		sb		r0,KeyState1
		sb		r0,KeyState2
		ret

;----------------------------------------------------------------------------
; KeybdGetChar:
;
; Returns:
; r1 = ascii code
; r2 = 0 if key available, 1 if no key available, 2 if keyboard busy
; r3 = scan code
; .ZF = 1 if a key is available, otherwise .ZF = 0
;----------------------------------------------------------------------------

KeybdGetChar:
		add		sp,sp,#-4
		sw		r4,2[sp]
		sw		lr,[sp]
kbd3:
		lb		r1,KBD+KBD_STAT	; get keyboard status flag
		mov		r2,r1
		and		r1,#$40
		bne		kbd1		; is it busy ?
		mov		r1,r2
		and		r1,#$80
		bne		kbd6		; branch if key available
		lw		lr,[sp]
		lw		r4,2[sp]
		add		sp,sp,#4
		lw		r2,#1		; no key available
		ret
kbd1:
		lw		lr,[sp]
		lw		r4,2[sp]
		add		sp,sp,#4
		lw		r2,#2		; keyboard busy
		ret
kbd6:
		lb		r1,KBD		; get scancode
		mov		r3,r1		; save in r3
		sb		r0,KBD+2	; clear read flag
		cmp		r1,#SC_KEYUP
		bne		notKeyup
		jmp		doKeyup
notKeyup:
		cmp		r1,#SC_EXTEND
		bne		notExtend
		jmp		doExtend
notExtend:
		cmp		r1,#$14		; control ?
		bne		notCtrl
		jmp		doCtrl
notCtrl:
		cmp		r1,#$12
		bne		notShift
		jmp		doShift
notShift:
		cmp		r1,#$59
		bne		notShift2
		jmp		doShift
notShift2:
		cmp		r1,#SC_NUMLOCK
		bne		notNumLock
		jmp		doNumLock
notNumLock:
		cmp		r1,#SC_CAPSLOCK
		bne		notCapsLock
		jmp		doCapsLock
notCapsLock:
		cmp		r1,#SC_SCROLLLOCK
		bne		notScrollLock
		jmp		doScrollLock
notScrollLock:
		lb		r2,KeyState1
		mov		r4,r2
		shr		r2,#1
		sb		r2,KeyState1
		and		r4,#1
		beq		kbd11
		jmp		kbd3
kbd11:
		mov		r2,r1
		; Check for extended code
		lw		r1,#$80
		lb		r4,KeyState2
		and		r1,r4
		beq		kbd10
		lw		r1,#$7F
		and		r1,r4
		sb		r1,KeyState2
		; clear keyup
		lb		r4,KeyState1
		shr		r4,#1
		sb		r4,KeyState1
		mov		r1,r2
		and		r1,#$7F
		mov		r2,r1
		lb		r1,keybdExtendedCodes[r2]
		bra		kbd8
kbd10:
		lb		r1,KeyState2
		and		r1,#4
		beq		kbd9
		mov		r1,r2
		and		r1,#$7F
		mov		r2,r1
		lb		r1,keybdControlCodes[r2]
		bra		kbd8
kbd9:
		lb		r1,KeyState2
		and		r1,#1			; Is shift down ?
		beq		kbd7
		lb		r1,shiftedScanCodes[r2]
		bra		kbd8
kbd7:
		lb		r1,unshiftedScanCodes[r2]
kbd8:
		; return zero in r2 to indicate key available
		lw		lr,[sp]
		lw		r4,2[sp]
		add		sp,sp,#4
		lw		r2,#0
		ret
doKeyup:
		lb		r1,KeyState1
		or		r1,#1
		sb		r1,KeyState1
		jmp		kbd3
doExtend:
		lb		r1,KeyState2
		or		r1,#$80
		sb		r1,KeyState2
		jmp		kbd3
doCtrl:
		lb		r1,KeyState1
		ror		r1,#1
		bpl		kbd4
		lb		r1,KeyState2
		and		r1,#$FFFB
		sb		r1,KeyState2
		jmp		kbd3
kbd4:
		lb		r1,KeyState2
		or		r1,#4
		sb		r1,KeyState2
		jmp		kbd3		
doShift:
		lb		r1,KeyState1
		ror		r1,#1
		bpl		kbd5
		lb		r1,KeyState2
		and		r1,#$FFFE
		sb		r1,KeyState2
		jmp		kbd3
kbd5:
		lb		r1,KeyState2
		or		r1,#1
		sb		r1,KeyState2
		jmp		kbd3
doNumLock:
		lb		r1,KeyState2
		xor		r1,#16
		sb		r1,KeyState2
		call	KeybdSetLEDStatus
		jmp		kbd3
doCapsLock:
		lb		r1,KeyState2
		xor		r1,#32
		sb		r1,KeyState2
		call	KeybdSetLEDStatus
		jmp		kbd3
doScrollLock:
		lb		r1,KeyState2
		xor		r1,#64
		sb		r1,KeyState2
		call	KeybdSetLEDStatus
		jmp		kbd3

KeybdSetLEDStatus:
		ret

	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
unshiftedScanCodes:
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

shiftedScanCodes:
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
keybdControlCodes:
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

keybdExtendedCodes:
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


		org		0xFFFE
		dw		start
