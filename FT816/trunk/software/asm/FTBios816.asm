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

TickCount	EQU		$4
; Range $10 to $1F reserved for hardware counters
; Range $20 to $2F reserved for tri-byte pointers
CursorX		EQU		$30
CursorY		EQU		$32
VideoPos	EQU		$34
NormAttr	EQU		$36
StringPos	EQU		$38
EscState	EQU		$3C
OutputVec	EQU		$0400

VIDBUF		EQU		$FD0000
VIDREGS		EQU		$FEA000
PRNG		EQU		$FEA100
KEYBD		EQU		$FEA110

.include "supermon816.asm"

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
	LDA		#$FEA1		; select $FEA1xx I/O
	STA		$F006

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
	LDA		#DisplayChar
	STA		OutputVec
	LDA		#$BF00
	STA		NormAttr
	JSR		ClearScreen
	JSR		HomeCursor
	PEA		msgStarting
	JSR		DisplayString
.mon1:
	JSR		OutCRLF
	LDA		#'$'
	JSR		OutChar
	JSR		KeybdGetCharWait
	AND		#$FF
	JSR		OutChar
	CMP		#'S'
	BNE		.mon2
	JMP		$C000
.mon2:
	CMP		#'C'
	BNE		.mon1
	JSR		ClearScreen
	BRA		.mon1

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
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

DisplayChar:
	LDX		VideoPos
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
	CMP		#ESC
	BNE		.0003
	LDA		#-1
	STA		EscState
	RTS
.0003:
	ORA		NormAttr
	PHA
	TXA
	ASL
	TAX
	PLA
	STA		VIDBUF,X
	INC		VideoPos
	LDA		VideoPos
	STA		VIDREGS+13
	LDA		CursorX
	INA
	CMP		#$56
	BNE		.0001
	STZ		CursorX
	LDA		CursorY
	CMP		#$30
	BEQ		.0002
	INA
	STA		CursorY
	RTS
.0002:
	SEC
	LDA		VideoPos
	SBC		#56
	STA		VideoPos
	STA		VIDREGS+13
	JSR		ScrollUp
	RTS
.0001:
	STA		CursorX
	RTS
doCR:
	SEC
	LDA		VideoPos
	SBC		CursorX
	STA		VideoPos
	STA		VIDREGS+13
	STZ		CursorX
	RTS
doLF:
	LDA		CursorY
	CMP		#30
	BEQ		.0001
	INA
	STA		CursorY
	CLC
	LDA		VideoPos
	ADC		#56
	STA		VideoPos
	STA		VIDREGS+13
	RTS
.0001:
	JMP		ScrollUp
processEsc:
	LDX		EscState
	CPX		#-1
	BNE		.0006
	CMP		#'T'	; clear to EOL
	BNE		.0003
	LDX		VideoPos
	TXA
	ASL
	TAX
	LDY		CursorX
.0001:
	CPY		#55
	BEQ		.0002
	LDA		#' '
	ORA		NormAttr
	STA		VIDBUF,X
	INX
	INX
	INY
	BNE		.0001
.0002:
	STZ		EscActive
	RTS
.0003:
	CMP		#'W'
	BNE		.0004
	STZ		EscState
	BRA		doDelete
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
	LDX		VideoPos
	TXA
	ASL
	TAX
.0002:
	LDA		VIDBUF,X
	STA		VIDBUF-2,X
	INX
	INX
	INY
	CPY		#56
	BNE		.0002
.0003:
	LDA		#' '
	ORA		NormAttr
	STA		VIDBUF,X
	DEC		CursorX
	DEC		VideoPos
	BRA		SetVideoPos
.0001:
	RTS
doDelete:
	LDY		CursorX
	LDX		VideoPos
	TXA
	ASL
	TAX
.0002:
	CPY		#55
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
doCursorRight:
	LDY		CursorX
	CPY		#55
	BEQ		.0001
	INC		CursorX
	INC		VideoPos
SetVideoPos:
	LDA		VideoPos
	STA		VIDREGS+13
.0001:
	RTS
doCursorLeft:
	LDY		CursorX
	BEQ		.0001
	DEY
	DEC		VideoPos
	BRA		SetVideoPos
.0001:
	RTS
doCursorUp:
	LDY		CursorY
	BEQ		.0001
	DEY
	STY		CursorY
	SEC
	LDA		VideoPos
	SBC		#56
	STA		VideoPos
	BRA		SetVideoPos
.0001:
	RTS
doCursorDown:
	LDY		CursorY
	CPY		#30
	BEQ		.0001
	INY
	STY		CursorY
	CLC
	LDA		VideoPos
	ADC		#56
	STA		VideoPos
	BRA		SetVideoPos
.0001:
	RTS

OutChar:
	JMP		(OutputVec)

OutCRLF:
	LDA		#CR
	JSR		OutChar
	LDA		#LF
	JMP		OutChar

DisplayString:
	PLA							; pop return address
	PLX							; get string address parameter
	PHA							; push return address
	SEP		#$20				; ACC = 8 bit
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
	RTS

CursorOn:
	PHA
	LDA		#$0760
	STA		VIDREGS+9
	PLA
	RTS

CursorOff:
	PHA
	LDA		#$1F1F
	STA		VIDREGS+9
	PLA
	RTS

HomeCursor:
	LDA		#0
	STZ		CursorX
	STZ		CursorY
	STZ		VideoPos
	STA		VIDREGS+13
	RTS

ClearScreen:
	LDY		#1736
	LDX		#$00
	LDA		NormAttr
	ORA		#$20
.0001:
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	RTS

ScrollUp:
	LDX		#0
	LDY 	#1736
.0001:
	LDA		VIDBUF+112,X
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	LDA		#30

BlankLine:
	ASL
	TAX
	LDA		LineTbl,X
	TAX
	LDY		#55
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
	CMP		#9
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

; Wait for a keyboard character to be available
;
KeybdGetCharWait:
.0003:
	LDA		KEYBD
	BPL		.0003
	PHA					; save off the char (we need to trash acc)
	LDA		KEYBD+4		; clear keyboard strobe (must be a read operation)
	PLA					; restore char
	BIT		#$800		; Is it a keyup code ?
	BNE		.0003
	RTS

; Get a keyboard charaacter if available.
; Returns -1 (NF=1) if no key available
; Return key (NF=0) if key is available
;
KeybdGetCharNoWait:
	LDA		KEYBD
	BPL		.0002
	PHA					; save off the char (we need to trash acc)
	LDA		KEYBD+4		; clear keyboard strobe (must be a read operation)
	PLA					; restore char
	BIT		#$800		; Is it a keyup code ?
	BNE		.0002
	AND		#$7FFF		; mask off strobe bit (make value positive)
	CLC					; Supermon flag char available
	RTS
.0002:
	SEC					; Supermon flag no char, and make negative
	ROR
	RTS

; Get char routine for Supermon
; This routine might be called with 8 bit regs.
;
SuperGetch:
	PHP
	REP		#$30
	MEM		16
	NDX		16
	JSR		KeybdGetCharNoWait
	BMI		.0001
	AND		#$FF
	PLP
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
	STA		$FD006E
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

LineTbl:
	.WORD	0
	.WORD	56
	.WORD	56*2
	.WORD	56*3
	.WORD	56*4
	.WORD	56*5
	.WORD	56*6
	.WORD	56*7
	.WORD	56*8
	.WORD	56*9
	.WORD	56*10
	.WORD	56*11
	.WORD	56*12
	.WORD	56*13
	.WORD	56*14
	.WORD	56*15
	.WORD	56*16
	.WORD	56*17
	.WORD	56*18
	.WORD	56*19
	.WORD	56*20
	.WORD	56*21
	.WORD	56*22
	.WORD	56*23
	.WORD	56*24
	.WORD	56*25
	.WORD	56*26
	.WORD	56*27
	.WORD	56*28
	.WORD	56*29
	.WORD	56*30

	.org	$F400
	JMP		SuperGetch
	JMP		start
	JMP		SuperPutch

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000
