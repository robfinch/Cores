; ============================================================================
; FTBios816.asm
;        __
;   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
CR			EQU		13
LF			EQU		10
ESC			EQU		$1B
BS			EQU		8

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

TEXTROWS	EQU		31
TEXTCOLS	EQU		84

TickCount	EQU		$4
KeyState1	EQU		$8
KeyState2	EQU		$9
KeybdLEDs	EQU		$A
KeybdWaitFlag	EQU	$B

; Range $10 to $1F reserved for hardware counters
CNT0L		EQU		$10
CNT0M		EQU		$11
CNT0H		EQU		$12
; Range $20 to $2F reserved for tri-byte pointers
CursorX		EQU		$30
CursorY		EQU		$32
VideoPos	EQU		$34
NormAttr	EQU		$36
StringPos	EQU		$38
EscState	EQU		$3C
OutputVec	EQU		$03F0

VIDBUF		EQU		$FD0000
VIDREGS		EQU		$FEA000
PRNG		EQU		$FEA100
KEYBD		EQU		$FEA110
FAC1		EQU		$FEA200

.include "supermon816.asm"
.include "FAC1ToString.asm"

	cpu		W65C816S
	.org	$E000

start:
	SEI
	CLD
	CLC					; switch to '816 mode
	XCE
	REP		#$30		; set 16 bit regs & mem
	NDX 	16
	MEM		16
	LDA		#$3FFF		; set top of stack
	TAS
	LDA		#$0070		; program chip selects for I/O
	STA		$F000		; at $007000
	LDA		#$0071
	STA		$F002
;	LDA		#$FEA1		; select $FEA1xx I/O
;	STA		$F006
	LDA		#$0000		; select zero page ram
	STA		$F00A

	; Setup the counters
	SEP		#$30		; set 8 bit regs
	NDX		8			; tell the assembler
	MEM		8
	; Counter #0 is setup as a free running tick count
	LDA		#$FF		; set limit to $FFFFFF
	STA		$F010
	STA		$F011
	STA		$F012
	LDA		#$14		; count up, on mpu clock
	STA		$F013
	; Counter #1 is set to interrupt at a 100Hz rate
	LDA		#$94		; divide by 95794 (for 100Hz)
	STA		$F014
	LDA		#$57
	STA		$F015
	LDA		#$09
	STA		$F016
	LDA		#$05		; count down, on mpu clock, irq disenabled
	STA		$F017
	; Counter #2 isn't setup

	REP		#$30		; set 16 bit regs & mem
	NDX 	16
	MEM		16
	
;	CLI

	stz		TickCount
.0001:
	LDA		#DisplayChar
	STA		OutputVec
	LDA		OutputVec
	CMP		#DisplayChar
	BNE		.0001
	LDA		#$01
	STA		$7000
	LDA		#$BF00
	STA		NormAttr
	JSR		ClearScreen
	JSR		HomeCursor
	LDA		#$02
	STA		$7000
	PEA		msgStarting
	JSR		DisplayString
	LDA		#0
	STA		FAC1
	STA		FAC1+2
	STA		FAC1+4
	STA		FAC1+6
	STA		FAC1+8
	STA		FAC1+10
	LDA		#1234
	STA		FAC1
	LDA		#5			; FIX2FLT
	JSR 	FPCommandWait
	JSR		DivideByTen
	JSR		FAC1ToString
	PEA		$3A0
	JSR		DisplayString
	LDA		#' '
	JSR		OutChar
	JSR		DispFAC1
	JSR		KeybdInit
.mon1:
	JSR		OutCRLF
	LDA		#'$'
.mon3:
	JSR		OutChar
	JSR		KeybdGetCharWait
	AND		#$FF
;	CMP		#'.'
;	BEQ		.mon3
	CMP		#CR
	BNE		.mon3
	LDA		CursorY
	ASL
	TAX
	LDA		LineTbl,X
	TAX
.mon4:
	JSR		MonGetch
	CMP		#'$'
	BEQ		.mon4
	CMP		#' '
	BEQ		.mon4
	CMP		#'\t'
	BEQ		.mon4
	CMP		#'S'
	BNE		.mon2
	JMP		$C000		; invoke Supermon816
.mon2:
	CMP		#'C'
	BNE		.mon1
	JSR		ClearScreen
	BRA		.mon1

; Get a character from the screen, skipping over spaces and tabs
;
MonGetNonSpace:
.0001:
	JSR		MonGetch
	CMP		#' '
	BEQ		.0001
	CMP		#'\t'
	BEQ		.0001
	RTS

; Get a character from the screen.
;
MonGetch:
	LDA		VIDBUF,X
	INX
	INX
	AND		#$FF
	JSR		ScreenToAscii
	RTS

;------------------------------------------------------------------------------
; BIOSInput allows full screen editing of text until a carriage return is keyed
; at which point the line the cursor is on is copied to a buffer. The buffer
; must be at least TEXTCOLS characters in size.
;------------------------------------------------------------------------------
;
BIOSInput:
.bin1:
	JSR		KeybdGetCharWait
	AND		#$FF
	CMP		#CR
	BEQ		.bin2
	JSR		OutChar
	BRA		.bin1
.bin2:
	LDA		CursorX
	BEQ		.bin4
	LDA		VideoPos	; get current video position
	SEC
	SBC		CursorX		; go back to the start of the line
	ASL
	TAX
.bin3:
	LDA		VIDBUF,X
	AND		#$FF
	STA		(3,s),Y
	INX
	INX
	INY
	DEC		CursorX
	BNE		.bin3
	LDA		#0
.bin4:
	STA		(3,s),Y	; NULL terminate buffer
	RTS

.st0003:
	LDA		KEYBD
	BPL		.st0003
	PHA					; save off the char (we need to trash acc)
	LDA		KEYBD+4		; clear keyboard strobe (must be a read operation)
	PLA					; restore char
	JSR		DisplayChar
	BRA		.st0003
	ldy		#$0000
.st0001:
	ldx		#$0000
.st0002:
	inx
	bne		.st0002
	jsr		echo_switch
	iny
	bra		.st0001

msgStarting:
	.byte	"FT816 Test System Starting",CR,LF,0

echo_switch:
	lda		$7100
	sta		$7000
	rts

;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;------------------------------------------------------------------------------

AsciiToScreen:
	AND		#$FF
	BIT		#%00100000	; if bit 5 isn't set
	BEQ		.00001
	BIT		#%01000000	; or bit 6 isn't set
	BEQ		.00001
	AND		#%10011111
.00001:
	rts

;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
ScreenToAscii:
	AND		#$FF
	CMP		#26+1
	BCS		.0001
	ADC		#$60
.0001:
	RTS

;------------------------------------------------------------------------------
; Display a character on the screen device
;------------------------------------------------------------------------------
;
DisplayChar:
	AND		#$0FF
	BIT		EscState
	LBMI	processEsc
	CMP		#BS
	LBEQ	doBackSpace
	CMP		#$91			; cursor right
	LBEQ	doCursorRight
	CMP		#$93			; cursor left
	LBEQ	doCursorLeft
	CMP		#$90			; cursor up
	LBEQ	doCursorUp
	CMP		#$92			; cursor down
	LBEQ	doCursorDown
	CMP		#$99			; delete
	LBEQ	doDelete
	CMP		#CR
	BEQ		doCR
	CMP		#LF
	BEQ		doLF
	CMP		#$94
	LBEQ	doCursorHome	; cursor home
	CMP		#ESC
	BNE		.0003
	STZ		EscState		; put a -1 in the escape state
	DEC		EscState
	RTS
.0003:
	JSR		AsciiToScreen
	ORA		NormAttr
	PHA
	LDA		VideoPos
	ASL
	TAX
	PLA
	STA		VIDBUF,X
	LDA		CursorX
	INA
	CMP		#TEXTCOLS
	BNE		.0001
	STZ		CursorX
	LDA		CursorY
	CMP		#TEXTROWS-1
	BEQ		.0002
	INA
	STA		CursorY
	BRL		SyncVideoPos
.0002:
	JSR		SyncVideoPos
	BRL		ScrollUp
.0001:
	STA		CursorX
	BRL		SyncVideoPos
doCR:
	STZ		CursorX
	BRL		SyncVideoPos
doLF:
	LDA		CursorY
	CMP		#TEXTROWS-1
	LBEQ	ScrollUp
	INA
	STA		CursorY
	BRL		SyncVideoPos

processEsc:
	LDX		EscState
	CPX		#-1
	BNE		.0006
	CMP		#'T'	; clear to EOL
	BNE		.0003
	LDA		VideoPos
	ASL
	TAX
	LDY		CursorX
.0001:
	CPY		#TEXTCOLS-1
	BEQ		.0002
	LDA		#' '
	ORA		NormAttr
	STA		VIDBUF,X
	INX
	INX
	INY
	BNE		.0001
.0002:
	STZ		EscState
	RTS
.0003:
	CMP		#'W'
	BNE		.0004
	STZ		EscState
	BRL		doDelete
.0004:
	CMP		#'`'
	BNE		.0005
	LDA		#-2
	STA		EscState
	RTS
.0005:
	CMP		#'('
	BNE		.0008
	LDA		#-3
	STA		EscState
	RTS
.0008:
	STZ		EscState
	RTS
.0006:
	CPX		#-2
	BNE		.0007
	STZ		EscState
	CMP		#'1'
	LBEQ	CursorOn
	CMP		#'0'
	LBEQ	CursorOff
	RTS
.0007:
	CPX		#-3
	BNE		.0009
	CMP		#ESC
	BNE		.0008
	LDA		#-4
	STA		EscState
	RTS
.0009:
	CPX		#-4
	BNE		.0010
	CMP		#'G'
	BNE		.0008
	LDA		#-5
	STA		EscState
	RTS
.0010:
	CPX		#-5
	BNE		.0008
	STZ		EscState
	CMP		#'4'
	BNE		.0011
	LDA		NormAttr
	; Swap the high nybbles of the attribute
	XBA				
	SEP		#$30		; set 8 bit regs
	NDX		8			; tell the assembler
	MEM		8
	ROL
	ROL
	ROL
	ROL
	REP		#$30		; set 16 bit regs
	NDX		16			; tell the assembler
	MEM		16
	XBA
	AND		#$FF00
	STA		NormAttr
	RTS
.0011:
	CMP		#'0'
	BNE		.0012
	LDA		#$BF00		; Light Grey on Dark Grey
	STA		NormAttr
	RTS
.0012:
	LDA		#$BF00		; Light Grey on Dark Grey
	STA		NormAttr
	RTS

doBackSpace:
	LDY		CursorX
	BEQ		.0001		; Can't backspace anymore
	LDA		VideoPos
	ASL
	TAX
.0002:
	LDA		VIDBUF,X
	STA		VIDBUF-2,X
	INX
	INX
	INY
	CPY		#TEXTCOLS
	BNE		.0002
.0003:
	LDA		#' '
	ORA		NormAttr
	STA		VIDBUF,X
	DEC		CursorX
	BRL		SyncVideoPos
.0001:
	RTS

; Deleting a character does not change the video position so there's no need
; to resynchronize it.

doDelete:
	LDY		CursorX
	LDA		VideoPos
	ASL
	TAX
.0002:
	CPY		#TEXTCOLS-1
	BEQ		.0001
	LDA		VIDBUF+2,X
	STA		VIDBUF,X
	INX
	INX
	INY
	BRA		.0002
.0001:
	LDA		#' '
	ORA		NormAttr
	STA		VIDBUF,X
	RTS

doCursorHome:
	LDA		CursorX
	BEQ		doCursor1
	STZ		CursorX
	BRA		SyncVideoPos
doCursorRight:
	LDA		CursorX
	CMP		#TEXTCOLS-1
	BEQ		doRTS
	INA
doCursor2:
	STA		CursorX
	BRA		SyncVideoPos
doCursorLeft:
	LDA		CursorX
	BEQ		doRTS
	DEA
	BRA		doCursor2
doCursorUp:
	LDA		CursorY
	BEQ		doRTS
	DEA
	BRA		doCursor1
doCursorDown:
	LDA		CursorY
	CMP		#TEXTROWS-1
	BEQ		doRTS
	INA
doCursor1:
	STA		CursorY
	BRA		SyncVideoPos
doRTS:
	RTS

HomeCursor:
	LDA		#0
	STZ		CursorX
	STZ		CursorY

; Synchronize the absolute video position with the cursor co-ordinates.
;
SyncVideoPos:
	LDA		CursorY
	ASL
	TAX
	LDA		LineTbl,X
	CLC
	ADC		CursorX
	STA		VideoPos
	STA		VIDREGS+13		; Update the position in the text controller
	RTS

OutCRLF:
	LDA		#CR
	JSR		OutChar
	LDA		#LF

OutChar:
	PHX
	PHY
	LDX		#0
	JSR		(OutputVec,x)
	PLY
	PLX
	RTS

DisplayString:
	PLA							; pop return address
	PLX							; get string address parameter
	PHA							; push return address
	SEP		#$20				; ACC = 8 bit
	MEM		8
	LDA		#$DE
	STA		$7000
	STX		StringPos
	LDY		#0
.0002:
	LDA		(StringPos),Y
	BEQ		.0001
	JSR		SuperPutch
	INY
	BRA		.0002
.0001:
	REP		#$20				; ACC 16 bits
	MEM		16
	RTS

DisplayString2:
	PLA							; pop return address
	PLX							; get string address parameter
	PHA							; push return address
	SEP		#$20				; ACC = 8 bit
	STX		StringPos
	LDY		#0
	LDX		#50
.0002:
	LDA		(StringPos),Y
	JSR		SuperPutch
	INY
	DEX
	BNE		.0002
.0001:
	REP		#$20				; ACC 16 bits
	RTS

CursorOn:
	PHA
	LDA		#$0760
	STA		VIDREGS+9
	RTS

CursorOff:
	PHA
	LDA		#$0020
	STA		VIDREGS+9
	PLA
	RTS

ClearScreen:
	LDY		#TEXTROWS*TEXTCOLS
	LDX		#$00
	LDA		#' '
	JSR		AsciiToScreen
	ORA		NormAttr
.0001:
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	RTS

ScrollUp:
	LDX		#0
	LDY 	#TEXTROWS*TEXTCOLS
.0001:
	LDA		VIDBUF+112,X
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	LDA		#TEXTROWS-1

BlankLine:
	ASL
	TAX
	LDA		LineTbl,X
	TAX
	LDY		#TEXTCOLS
	LDA		NormAttr
	ORA		#$20
.0001:
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	RTS

DispWord:
	XBA
	JSR		DispByte
	XBA
DispByte:
	PHA
	LSR
	LSR
	LSR
	LSR
	JSR		DispNybble
	PLA
DispNybble:
	PHA
	AND		#$0F
	CMP		#10
	BCC		.0001
	ADC		#'A'-11			; -11 cause the carry is set
	JSR		OutChar
	PLA
	RTS
.0001:
	ORA		#'0'
	JSR		OutChar
	PLA
	RTS

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Keyboard processing routines follow.
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KeybdInit:
	SEP		#$30
	MEM		8
	NDX		8
	LDY		#$5
.0001:
	JSR		KeybdRecvByte	; Look for $AA
	BCC		.0002
	CMP		#$AA			;
	BEQ		.config
.0002:
	JSR		Wait10ms
	LDA		#$FF			; send reset code to keyboard
	STA		KEYBD+1			; write to status reg to clear TX state
	JSR		Wait10ms
	LDA		#$FF
	STA		KEYBD			; now write to transmit register
	JSR		KeybdWaitTx		; wait until no longer busy
	JSR		KeybdRecvByte	; look for an ACK ($FA)
	CMP		#$FA
	JSR		KeybdRecvByte
	CMP		#$FC			; reset error ?
	BEQ		.tryAgain
	CMP		#$AA			; reset complete okay ?
	BNE		.tryAgain
.config:
	LDA		#$F0			; send scan code select
	STA		KEYBD
	JSR		KeybdWaitTx
	BCC		.tryAgain
	JSR		KeybdRecvByte	; wait for response from keyboard
	BCC		.tryAgain
	CMP		#$FA
	BEQ		.0004
.tryAgain:
	DEY
	BNE		.0001
.keybdErr:
	REP		#$30
	PEA		msgKeybdNR
	JSR		DisplayString
	RTS
.0004:
	LDA		#2				; select scan code set #2
	STA		KEYBD
	JSR		KeybdWaitTx
	BCC		.tryAgain
	REP		#$30
	RTS

; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
KeybdRecvByte:
	PHY
	LDY		#100			; wait up to 1s
.0003:
	LDA		KEYBD+1			; wait for response from keyboard
	BIT		#$80			; is input buffer full ?
	BNE		.0004			; yes, branch
	JSR		Wait10ms		; wait a bit
	DEY
	BNE		.0003			; go back and try again
	PLY						; timeout
	CLC						; carry clear = no code
	RTS
.0004:
	LDA		KEYBD			;
	PHA
	LDA		#0				; clear recieve state
	STA		KEYBD+1
	PLA
	PLY
	SEC						; carry set = code available
	RTS

; Wait until the keyboard status is non-busy
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitBusy:
	PHY
	LDY		#100			; wait a max of 1s
.0001:
	LDA		KEYBD+1
	BIT		#1
	BEQ		.0002
	JSR		Wait10ms
	DEY
	BNE		.0001
	PLY
	CLC
	RTS
.0002:
	PLY
	SEC
	RTS

; Wait until the keyboard transmit is complete
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitTx:
	PHY
	LDY		#100			; wait a max of 1s
.0001:
	LDA		KEYBD+1
	BIT		#$40			; check for transmit complete bit
	BNE		.0002			; branch if bit set
	JSR		Wait10ms		; delay a little bit
	DEY						; go back and try again
	BNE		.0001
	PLY						; timed out
	CLC						; return carry clear
	RTS
.0002:
	PLY						; wait complete, return 
	SEC						; carry set
	RTS

; Wait approximately 10ms. Used by keyboard routines. Makes use of the free
; running counter #0.
; .A = trashed (=-5)
;
Wait10ms:
	PHX				; save .X
	LDA		CNT0H	; get starting count
	TAX				; save it off in .X
.0002:
	SEC				; compare to current counter value
	SBC		CNT0H
	BPL		.0001	; teh result should be -ve, unless counter overflowed.
	CMP		#-5		; 5 ticks pass ? 
	TXA				; prepare for next check, get startcount in .A
	BCS		.0002	; go back if less than 5 ticks
.0001:
	PLX				; restore .X
	RTS

	MEM		16
	NDX		16

msgKeybdNR:
	.byte	CR,LF,"Keyboard not responding.",CR,LF,0

KeybdGetCharNoWait:
	SEP		#$20
	MEM		8
	LDA		#0
	STA		KeybdWaitFlag
	BRA		KeybdGetChar

KeybdGetCharWait:
	SEP		#$20
	MEM		8
	LDA		#$FF
	STA		KeybdWaitFlag

; Wait for a keyboard character to be available
; Returns (CF=1) if no key available
; Return key (CF=0) if key is available
;
;
KeybdGetChar:
	SEP		#$20		; 8 bit acc
	MEM		8
	PHX
.0002:
.0003:
	LDA		KEYBD+1		; check MSB of keyboard status reg.
	ASL
	BCS		.0006		; branch if keystroke ready
	BIT		KeybdWaitFlag
	BMI		.0003
	PLX
	SEC
	REP		#$20
	RTS
.0006:
	LDA		KEYBD		; get scan code value
	PHA
	LDA		#0			; write a zero to the status reg
	STA		KEYBD+1		; to clear recieve register
	PLA
.0001:
	CMP		#SC_KEYUP	; keyup scan code ?
	LBEQ	.doKeyup	; 
	CMP		#SC_EXTEND	; extended scan code ?
	LBEQ	.doExtend
	CMP		#$14		; control ?
	LBEQ	.doCtrl
	CMP		#$12		; left shift
	LBEQ	.doShift
	CMP		#$59		; right shift
	LBEQ	.doShift
	CMP		#SC_NUMLOCK
	LBEQ	.doNumLock
	CMP		#SC_CAPSLOCK
	LBEQ	.doCapsLock
	CMP		#SC_SCROLLLOCK
	LBEQ	.doScrollLock
	LSR		KeyState1
	BCS		.0003
	TAX
	LDA		#$80
	BIT		KeyState2	; Is extended code ?
	BEQ		.0010
	LDA		#$7F
	AND		KeyState2
	STA		KeyState2
	LSR		KeyState1	; clear keyup
	TXA
	AND		#$7F
	TAX
	LDA		keybdExtendedCodes,X
	BRA		.0008
.0010:
	LDA		#4
	BIT		KeyState2	; Is Cntrl down ?
	BEQ		.0009
	TXA
	AND		#$7F		; table is 128 chars
	TAX
	LDA		keybdControlCodes,X
	BRA		.0008
.0009:
	LDA		#$1			; Is shift down ?
	BIT		KeyState2
	BEQ		.0007
	LDA		shiftedScanCodes,X
	BRA		.0008
.0007:
	LDA		unshiftedScanCodes,X
.0008:
	REP		#$20
	MEM		16
	PLX
	CLC
	RTS
	MEM		8
.doKeyup:
	LDA		#1
	TSB		KeyState1
	BRL		.0003
.doExtend:				; set extended key flag
	LDA		KeyState2
	ORA		#$80
	STA		KeyState2
	BRL		.0003
.doCtrl:
	LDA		#4
	LSR		KeyState1	; check key up/down	
	BCC		.0004		; keydown = carry clear
	TRB		KeyState2
	BRL		.0003
.0004:
	TSB		KeyState2	; set control active bit
	BRL		.0003
.doShift:
	LDA		#1
	LSR		KeyState1	; check key up/down	
	BCC		.0005
	TRB		KeyState2
	BRL		.0003
.0005:
	TSB		KeyState2
	BRL		.0003
.doNumLock:
	LDA		KeyState2
	EOR		#16
	STA		KeyState2
	JSR		KeybdSetLEDStatus
	BRL		.0003
.doCapsLock:
	LDA		KeyState2
	EOR		#32
	STA		KeyState2
	JSR		KeybdSetLEDStatus
	BRL		.0003
.doScrollLock:
	LDA		KeyState2
	EOR		#64
	STA		KeyState2
	JSR		KeybdSetLEDStatus
	BRL		.0003

KeybdSetLEDStatus:
	LDA		#0
	STA		KeybdLEDs
	LDA		#16
	BIT		KeyState2
	BEQ		.0002
	LDA		KeybdLEDs	; set bit 1 for Num lock, 0 for scrolllock , 2 for caps lock
	ORA		#$2
	STA		KeybdLEDs
.0002:
	LDA		#32
	BIT		KeyState2
	BEQ		.0003
	LDA		KeybdLEDs
	ORA		#$4
	STA		KeybdLEDs
.0003:
	LDA		#64
	BIT		KeyState2
	BEQ		.0004
	LDA		KeybdLEDs
	ORA		#1
	STA		KeybdLEDs
.0004:
	LDA		#$ED		; set status LEDs command
	STA		KEYBD
	JSR		KeybdWaitTx
	JSR		KeybdRecvByte
	BCC		.0001
	CMP		#$FA
	LDA		KeybdLEDs
	STA		KEYBD
	JSR		KeybdWaitTx
	JSR		KeybdRecvByte	; wait for $FA byte
.0001:
	RTS

	MEM		16

	BPL		.0003
	PHA					; save off the char (we need to trash acc)
	LDA		KEYBD+4		; clear keyboard strobe (must be a read operation)
	PLA					; restore char
	BIT		#$800		; Is it a keyup code ?
	BNE		.0003
	RTS



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

; Get char routine for Supermon
; This routine might be called with 8 bit regs.
;
SuperGetch:
	PHP
	REP		#$30
	MEM		16
	NDX		16
	JSR		KeybdGetCharNoWait
	AND		#$FF
	BCS		.0001
	PLP		; to restore reg size
	CLC
	RTS
.0001:
	PLP
	SEC
	RTS

; Put char routine for Supermon
; This routine might be called with 8 bit regs.
;
SuperPutch:
	PHP
	REP		#$30	; 16 bit regs
	MEM		16
	NDX		16
	PHA
	PHX
	PHY
	JSR		OutChar
	PLY
	PLX
	PLA
	PLP
	RTS

IRQRout:
	REP		#$30
	NDX		16
	MEM		16
	PHA
	LDA		TickCount
	INA
	STA		TickCount
	STA		$FD00A6
	SEP		#$30
	NDX		8
	MEM		8
	LDA		$F01F		; check if counter expired
	BIT		#2
	BEQ		.0001
	LDA		#$05		; count down, on mpu clock, irq enabled (clears irq)
	STA		$F017
.0001:
	REP		#$30
	NDX		16
	MEM		16
	PLA
	RTI

BrkRout:
	SEP		#$20
	PLA
	REP		#$20
	PLA
	JSR		DispWord
Hung:
	BRA		Hung
	
LineTbl:
	.WORD	0
	.WORD	TEXTCOLS
	.WORD	TEXTCOLS*2
	.WORD	TEXTCOLS*3
	.WORD	TEXTCOLS*4
	.WORD	TEXTCOLS*5
	.WORD	TEXTCOLS*6
	.WORD	TEXTCOLS*7
	.WORD	TEXTCOLS*8
	.WORD	TEXTCOLS*9
	.WORD	TEXTCOLS*10
	.WORD	TEXTCOLS*11
	.WORD	TEXTCOLS*12
	.WORD	TEXTCOLS*13
	.WORD	TEXTCOLS*14
	.WORD	TEXTCOLS*15
	.WORD	TEXTCOLS*16
	.WORD	TEXTCOLS*17
	.WORD	TEXTCOLS*18
	.WORD	TEXTCOLS*19
	.WORD	TEXTCOLS*20
	.WORD	TEXTCOLS*21
	.WORD	TEXTCOLS*22
	.WORD	TEXTCOLS*23
	.WORD	TEXTCOLS*24
	.WORD	TEXTCOLS*25
	.WORD	TEXTCOLS*26
	.WORD	TEXTCOLS*27
	.WORD	TEXTCOLS*28
	.WORD	TEXTCOLS*29
	.WORD	TEXTCOLS*30

	.org	$F400
	JMP		SuperGetch
	JMP		start
	JMP		SuperPutch
	JMP		BIOSInput

	.org 	$FFE6
	dw		BrkRout

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000
