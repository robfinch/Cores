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

TickCount	EQU		$4
CursorX		EQU		$8
CursorY		EQU		$10
VideoPos	EQU		$12
NormAttr	EQU		$14
StringPos	EQU		$16

VIDBUF		EQU		$FD0000
VIDREGS		EQU		$FEA000

	cpu		W65C816S
	.org	$E000

start:
	sei
	cld
	clc					; switch to '816 mode
	xce
	rep		#$30		; set 16 bit regs & mem
	ndx 	16
	mem		16
	lda		#$1FFF		; set top of stack
	tas
	cli
	lda		#$0070		; program chip selects for I/O
	sta		$F000		; at $007000
	lda		#$0071
	sta		$F002
	lda		#$FEA1		; select $FEA1xx I/O
	sta		$F006
	stz		TickCount
	lda		#$BF00
	sta		NormAttr
	jsr		ClearScreen
	jsr		HomeCursor
	lda		#msgStarting
	sta		StringPos
	lda		#msgStarting>>16
	sta		StringPos+2
	jsr		DisplayString
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
	.byte	"FT816 Test system Starting",CR,LF,0

echo_switch:
	lda		$7100
	sta		$7000
	rts

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

AsciiToScreen:
	AND		#$FF
;	ORA		#$100
	BIT		#$20		; if bit 5 or 6 isn't set
	BEQ		.0001
	BIT		#$40
	BEQ		.0001
	AND		#$19F
.0001:
	RTS

DisplayChar:
	LDX		VideoPos
	AND		#$0FF
	CMP		#CR
	BEQ		doCR
	CMP		#LF
	BEQ		doLF
	JSR		AsciiToScreen
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
	JMP		SCrollUp

DisplayString:
	LDY		#0
.0002:
	LDA		[StringPos],Y
	AND		#$FF				; mask off extra byte
	BEQ		.0001
	PHY
	JSR		DisplayChar
	PLY
	INY
	BNE		.0002
.0001:
	RTS

HomeCursor:
	LDA		#0
	STZ		CursorX
	STZ		CursorY
	STZ		VideoPos
	STA		VIDREGS+13
	RTS

ClearScreen:
	LDY		#1735
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
	LDY 	#1735
.0001:
	LDA		VIDBUF+112,X
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	LDX		#30

BlankLine:
	LDA		LineTbl,X
	TAX
	LDY		#55
	LDA		#$CE20
.0001:
	STA		VIDBUF,X
	INX
	INX
	DEY
	BNE		.0001
	RTS

IRQRout:
	pha
	lda		#$AA
	sta		$7000
	inc		TickCount
	pla
	rti

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

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000
