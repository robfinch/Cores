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
CTRLC		EQU		3

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
NumWorkArea	EQU		$C

; Range $10 to $1F reserved for hardware counters
CNT0L		EQU		$10
CNT0M		EQU		$11
CNT0H		EQU		$12
RangeStart	EQU		$20
RangeEnd	EQU		$24
CursorX		EQU		$30
CursorY		EQU		$32
VideoPos	EQU		$34
NormAttr	EQU		$36
StringPos	EQU		$38
EscState	EQU		$3C

reg_cs		EQU		$80
reg_ds		EQU		reg_cs + 4
reg_pc		EQU		reg_ds + 4
reg_a		EQU		reg_pc + 4
reg_x		EQU		reg_a + 4
reg_y		EQU		reg_x + 4
reg_sp		EQU		reg_y + 4
reg_sr		EQU		reg_sp + 4
reg_db		EQU		reg_sr + 4
reg_dp		EQU		reg_db + 4
reg_bl		EQU		reg_dp + 4

cs_save		EQU		$80
ds_save		EQU		$84
pc_save		EQU		$88
pb_save		EQU		$8C
acc_save	EQU		$90
x_save		EQU		$94
y_save		EQU		$98
sp_save		EQU		$9C
sr_save		EQU		$A0
srx_save	EQU		$A4
db_save		EQU		$A8
dpr_save	EQU		$AC

running_task	EQU		$B4

keybd_char	EQU		$B6
keybd_cmd	EQU		$B8
WorkTR		EQU		$BA
ldtrec		EQU		$100

OutputVec	EQU		$03F0

PCS0		EQU		$B000
PCS1		EQU		PCS0 + 2
PCS2		EQU		PCS1 + 2
PCS3		EQU		PCS2 + 2
PCS4	    EQU		PCS3 + 2
PCS5		EQU		PCS4 + 2
CTR0_LMT	EQU		PCS0 + 16
CTR0_CTRL	EQU		CTR_LMT + 3
CTR1_LMT	EQU		CTR0_CTRL + 1
CTR1_CTRL	EQU		CTR1_LMT + 3

VIDBUF		EQU		$FD0000
VIDREGS		EQU		$FEA000
PRNG		EQU		$FEA100
KEYBD		EQU		$FEA110
FAC1		EQU		$FEA200

do_invaders			EQU		$7868

.include "supermon832.asm"
.include "FAC1ToString.asm"
.include "invaders.asm"

;	cpu		W65C816S
	cpu		FT832
	.org	$E000

start:
	SEI
	CLD
;	CLV					; overflow low
;	SEC					; carry high
;	XCE					; sets 32 bit mode, 32 bit registers
;	REP		#$30		; 32 bit registers
;	MEM		32
;	NDX		32
;	LDA		#$3FFF
;	TAS
;
	CLC					; switch to '816 mode
	BIT		start		; set overflow bit
	XCE
	REP		#$30		; set 16 bit regs & mem
	NDX 	16
	MEM		16
	LDA		#$3FFF		; set top of stack
	TAS

	; setup the programmable address decodes
	LDA		#$0070		; program chip selects for I/O
	STA		PCS0		; at $007000
	LDA		#$0071
	STA		PCS1
;	LDA		#$FEA1		; select $FEA1xx I/O
;	STA		PCS3
	LDA		#$0000		; select zero page ram
	STA		PCS5

	; Setup the counters
	SEP		#$30		; set 8 bit regs
	NDX		8			; tell the assembler
	MEM		8
	; Counter #0 is setup as a free running tick count
	LDA		#$FF		; set limit to $FFFFFF
	STA		CTR0_LMT
	STA		CTR0_LMT+1
	STA		CTR0_LMT+2
	LDA		#$14		; count up, on mpu clock
	STA		CTR0_CTRL
	; Counter #1 is set to interrupt at a 100Hz rate
	LDA		#$94		; divide by 95794 (for 100Hz)
	STA		CTR1_LMT
	LDA		#$57
	STA		CTR1_LMT+1
	LDA		#$09
	STA		CTR1_LMT+2
	LDA		#$05		; count down, on mpu clock, irq disenabled
	STA		CTR1_CTRL
	; Counter #2 isn't setup

	REP		#$30		; set 16 bit regs & mem
	NDX 	16
	MEM		16

	; Setup the task registers
	LDY		#6			; # tasks to setup
	LDX		#1
.0001:
	LDT		TaskStartTbl,X
	INX
	DEY
	BNE		.0001

	STZ		running_task

	LDA		#BrkRout1
	STA		$0102

	STZ		TickCount
	STZ		TickCount+2
Task0:
	CLI
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
	PLA
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
	PLA
	LDA		#' '
	JSR		OutChar
	JSR		DispFAC1
	FORK	#7			; fork a BIOS context
	TTA
	CMP		#7
	BNE		.0002
	RTT
.0002:
	FORK	#11
	TTA
	CMP		#11
	LBEQ	KeybdInit

Mon1:
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
	ASL
	TAX
.mon4:
	JSR		IgnoreBlanks
	JSR		MonGetch
	CMP		#'$'
	BEQ		.mon4
	CMP		#'S'
	BNE		.mon2
	JMP		$C000		; invoke Supermon816
.mon2:
	CMP		#'C'
	BNE		.mon5
	JSR		ClearScreen
	JSR		HomeCursor
	BRA		.mon1
.mon5:
	CMP		#'M'
	LBEQ	doMemoryDump
	CMP		#'D'
	LBEQ	doDisassemble
	CMP		#'>'
	LBEQ	doMemoryEdit
	CMP		#'J'
	LBEQ	doJump
	CMP		#'T'
	LBEQ	doTask2
	CMP		#'I'
	LBEQ	doInvaders
	CMP		#'R'
	LBEQ	doRegs
	BRA		Mon1

; Get a character from the screen, skipping over spaces and tabs
;
MonGetNonSpace:
.0001:
	JSR		MonGetch
	CMP		#' '
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
;------------------------------------------------------------------------------
doTask2:
	TSK		#2
	BRL		Mon1

doInvaders:
	LDA		#$FFFF
	STA		do_invaders
	TSK		#5
;	FORK	#5
;	TTA
;	CMP		#5
;	LBEQ	InvadersTask
	BRL		Mon1

;------------------------------------------------------------------------------
; Display Registers
; R<xx>		xx = context register to display
; Update Registers
; R.<reg> <val>
;	reg = CS PB PC A X Y SP SR DS DB or DP
;------------------------------------------------------------------------------

doRegs:
	JSR		MonGetch
	CMP		#'.'
	LBNE	.0004
	JSR		MonGetch
	CMP		#'C'
	BNE		.0005
	JSR		MonGetch
	CMP		#'S'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_cs
	LDA		NumWorkArea+2
	STA		reg_cs+2
.buildrec
	JSR		BuildRec
	LDX		WorkTR
	LDT		ldtrec
	BRL		Mon1
.0005:
	CMP		#'P'
	BNE		.0006
	JSR		MonGetch
	CMP		#'B'
	BNE		.0007
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea+2
	STA		reg_pc+2
	BRA		.buildrec
.0007:
	CMP		#'C'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_pc
	BRA		.buildrec
.0006:
	CMP		#'A'
	BNE		.0008
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_a
	LDA		NumWorkArea+2
	STA		reg_a+2
	BRA		.buildrec
.0008:
	CMP		#'X'
	BNE		.0009
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_x
	LDA		NumWorkArea+2
	STA		reg_x+2
	BRL		.buildrec
.0009:
	CMP		#'Y'
	BNE		.0010
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_y
	LDA		NumWorkArea+2
	STA		reg_y+2
	BRL		.buildrec
.0010:
	CMP		#'S'
	BNE		.0011
	JSR		MonGetch
	CMP		#'P'
	BNE		.0015
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_sp
	LDA		NumWorkArea+2
	STA		reg_sp+2
	BRL		.buildrec
.0015:
	CMP		#'R'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_sr
	BRL		.buildrec
.0011:
	CMP		#'D'
	LBNE	Mon1
	JSR		MonGetch
	CMP		#'S'
	BNE		.0012
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_ds
	LDA		NumWorkArea+2
	STA		reg_ds+2
	BRL		.buildrec
.0012:
	CMP		#'B'
	BNE		.0013
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_db
	BRL		.buildrec
.0013:
	CMP		#'P'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_dp
	BRL		.buildrec

.0004:
	DEX
	DEX
;	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		NumWorkArea
	STA		WorkTR
	JSR		DispRegs
	BRL		Mon1

DispRegs:
	PEA		msgRegs
	JSR		DisplayString
	PLA
	JSR		space

	LDA		WorkTR
	ASL
	ASL
	ASL
	ASL
	TAX

	LDY		#0
.0001:
	INF
	INX
	STA		reg_cs,Y
	XBAW
	STA		reg_cs+2,Y
	INY4
	CPY		#44
	BNE		.0001

	; Display CS
	LDA		reg_cs+2
	JSR		DispWord
	LDA		reg_cs
	JSR		DispWord
	LDA		#':'
	JSR		OutChar

	; Display PB PC
	LDA		reg_cs+10
	JSR		DispByte
	LDA		reg_cs+8
	JSR		DispWord
	JSR		space

	; Display SRX,SR
	LDA		reg_cs+28
	LDX		#16
.0003:
	ASL
	PHA
	LDA		#'0'
	ADC		#0
	JSR		DispNybble
	PLA
	DEX
	BNE		.0003
	JSR		space

	LDX		#12
.0002
	; display Acc,.X,.Y,.SP
	LDA		reg_cs+2,X
	JSR		DispWord
	LDA		reg_cs,X
	JSR		DispWord
	JSR		space
	INX4
	CPX		#28
	BNE		.0002

	PEA		msgRegs2
	JSR		DisplayString
	PLA
	JSR		space

	; Display DS
	LDA		reg_cs+6
	JSR		DispWord
	LDA		reg_cs+4
	JSR		DispWord
	JSR		space

	; Display DB
	LDA		reg_cs+32
	JSR		DispByte
	JSR		space

	; Display DPR
	LDA		reg_cs+36
	JSR		DispWord
	JSR		space

	; Display back link
	LDA		reg_cs+40
	JSR		DispWord

	JSR		OutCRLF
	RTS

; Build a startup record from the register values so that a context reg
; may be loaded

BuildRec:
	LDA		reg_cs
	STA		ldtrec
	LDA		reg_cs+2
	STA		ldtrec+2
	LDA		reg_ds
	STA		ldtrec+4
	LDA		reg_ds+2
	STA		ldtrec+6
	LDA		reg_pc
	STA		ldtrec+8
	LDA		reg_pc+2
	AND		#$FF
	SEP		#$30		; 8 bit regs
	MEM		8
	XBA
	LDA		reg_a
	XBA
	REP		#$30
	MEM		16
	STA		ldtrec+10
	LDA		reg_a+1
	STA		ldtrec+12
	LDA		reg_a+3
	STA		ldtrec+14
	LDA		reg_x+1
	STA		ldtrec+16
	LDA		reg_x+3
	STA		ldtrec+18
	LDA		reg_y+1
	STA		ldtrec+20
	LDA		reg_y+3
	STA		ldtrec+22
	LDA		reg_sp+1
	STA		ldtrec+24
	LDA		reg_sp+3
	STA		ldtrec+26
	SEP		#$30
	LDA		reg_sr+1
	STA		ldtrec+28
	LDA		reg_db
	STA		ldtrec+29
	LDA		reg_dp
	STA		ldtrec+30
	LDA		reg_dp+1
	STA		ldtrec+31
	REP		#$30
	RTS

;------------------------------------------------------------------------------
; Dump memory.
;------------------------------------------------------------------------------

doMemoryDump:
	JSR		IgnoreBlanks
	JSR		GetRange
	JSR		OutCRLF
.0007:
	LDA		#'>'
	JSR		OutChar
	JSR		DispRangeStart
	LDY		#0
.0001:
	LDA		{RangeStart},Y
	JSR		DispByte
	LDA		#' '
	JSR		OutChar
	INY
	CPY		#8
	BNE		.0001
	LDY 	#0
.0005:
	LDA		{RangeStart},Y
	CMP		#$' '
	BCS		.0002
.0004:
	LDA		#'.'
	BRA		.0003
.0002:
	CMP		#$7f
	BCC		.0004
.0003:
	JSR		OutChar
	INY
	CPY		#8
	BNE		.0005
	JSR		OutCRLF
	CLC
	LDA		RangeStart
	ADC		#8
	STA		RangeStart
	BCC		.0006
	INC		RangeStart+2
.0006:
	SEC
	LDA		RangeEnd
	SBC		RangeStart
	LDA		RangeEnd+2
	SBC		RangeStart+2
	PHP
	JSR		KeybdGetCharNoWait
	CMP		#CTRLC
	BEQ		.0009
	PLP
	BPL		.0007
.0008:
	JMP		Mon1
.0009:
	PLP
	JMP		Mon1

;------------------------------------------------------------------------------
; Edit memory.
; ><memory address> <val1> <val2> ... <val8>
;------------------------------------------------------------------------------

doMemoryEdit:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		NumWorkArea
	STA		RangeStart
	LDA		NumWorkArea+2
	STA		RangeStart+2
	LDY		#0
.0001:
	PHY
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0002
	PLY
	SEP		#$20
	LDA		NumWorkArea
	STA		{RangeStart},Y
	REP		#$20
	INY
	CPY		#8
	BNE		.0001
	BRL		Mon1
.0002:
	PLY
	BRL		Mon1

;------------------------------------------------------------------------------
; Disassemble code
;------------------------------------------------------------------------------

doDisassemble:
	JSR		MonGetch
	CMP		#'M'
	BEQ		.0002
.0004:
	CMP		#'N'
	BNE		.0003
	SEP		#$20
	MEM		8
	LDA		$BC
	ORA		#$40
	STA		$BC
	REP		#$20
	BRA		.0005
.0002:
	SEP		#$20
	LDA		$BC
	ORA		#$80
	STA		$BC
	REP		#$20
	JSR		MonGetch
	BRA		.0004
	MEM		16
.0003:
	DEX
	DEX
.0005:
	JSR		IgnoreBlanks
	JSR		GetRange
	LDA		RangeStart
	STA		$8F				; addra
	LDA		RangeStart+1
	STA		$90
	JSR		OutCRLF
	LDY		#20
.0001:
	PHY
	SEP		#$30
	JSR		dpycod
	REP		#$30
	JSR		OutCRLF
	PLY
	DEY
	BNE		.0001
	JMP		Mon1

;$BC flimflag

;------------------------------------------------------------------------------
; Jump to subroutine
;------------------------------------------------------------------------------

doJump:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		#$5C			; JML opcode
	STA		RangeEnd-1
	LDA		NumWorkArea
	STA		RangeEnd
	LDA		NumWorkArea+1
	STA		RangeEnd+1
	JSL		RangeEnd
	BRL		Mon1

DispRangeStart:
	LDA		RangeStart+1
	JSR		DispWord
	LDA		RangeStart
	JSR		DispByte
	LDA		#' '
	JMP		OutChar
	
;------------------------------------------------------------------------------
; Skip over blanks in the input
;------------------------------------------------------------------------------

IgnoreBlanks:
.0001:
	JSR		MonGetch
	CMP		#' '
	BEQ		.0001
	DEX
	DEX
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
	.byte	"FT832 Test System Starting",CR,LF,0

echo_switch:
	lda		$7100
	sta		$7000
	rts

;------------------------------------------------------------------------------
; On entry to the SSM task the .A register will be set to the task number
; being single stepped. The .X register will contain the address of the
; next instruction to execute.
;------------------------------------------------------------------------------

SSMTask:
	STA		WorkTR
	JSR		DispRegs
.0004:
	LDA		#'S'
	JSR		OutChar
	JSR		OutChar
	LDA		#'M'
	JSR		OutChar
	LDA		#'>'
	JSR		OutChar
	JSR		KeybdGetCharWait
	AND		#$FF
	CMP		#'S'		; step
	BNE		.0001
.0002:
	RTT
	BRA		SSMTask
.0001:
	CMP		#'X'
	BNE		.0002
	LDA		reg_sr
	AND		#$FDFF
	STA		reg_sr
	JSR		BuildRec
	LDX		WorkTR
	LDT		ldtrec
	RTT
	BRA		SSMTask

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

	MEM		8
AsciiToScreen8:
	BIT		#%00100000	; if bit 5 isn't set
	BEQ		.00001
	BIT		#%01000000	; or bit 6 isn't set
	BEQ		.00001
	AND		#%10011111
.00001:
	rts

	MEM		16
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
	STA		$7000
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
;	PLA							; pop return address
;	PLX							; get string address parameter
;	PHA							; push return address
	PHP							; push reg settings
	SEP		#$20				; ACC = 8 bit
	MEM		8
;	STX		StringPos
	LDY		#0
.0002:
	LDA		(4,S),Y
	BEQ		.0001
	JSR		SuperPutch
	INY
	BRA		.0002
.0001:
	PLP							; restore regs settings
;	REP		#$20				; ACC 16 bits
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
	LDA		#$1F60
	STA		VIDREGS+9
	PLA
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
	LDA		VIDBUF+TEXTCOLS*2,X
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
	ASL
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

DispDWord:
	XBAW
	JSR		DispWord
	XBAW
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

space:
	PHA
	LDA		#' '
	JSR		OutChar
	PLA
	RTS

;------------------------------------------------------------------------------
; Get a range (two hex numbers)
;------------------------------------------------------------------------------

GetRange:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA		RangeStart
	STA		RangeEnd
	LDA		NumWorkArea+2
	STA		RangeStart+2
	STA		RangeEnd+2
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA		RangeEnd
	LDA		NumWorkArea+2
	STA		RangeEnd+2
.0001:
	RTS
	
;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of six digits.
; .X = text pointer (updated)
;------------------------------------------------------------------------------
;
GetHexNumber:
	LDY		#0					; maximum of eight digits
	STZ		NumWorkArea
	STZ		NumWorkArea+2
gthxn2:
	JSR		MonGetch
	JSR		AsciiToHexNybble
	BMI		gthxn1
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ORA		NumWorkArea
	STA		NumWorkArea
	INY
	CPY		#8
	BNE		gthxn2
	RTS
gthxn1:
	DEX
	DEX
	RTS

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	CMP		#'0'
	BCC		gthx3
	CMP		#'9'+1
	BCS		gthx5
	SEC
	SBC		#'0'
	RTS
gthx5:
	CMP		#'A'
	BCC		gthx3
	CMP		#'F'+1
	BCS		gthx6
	SEC
	SBC		#'A'
	CLC
	ADC		#10
	RTS
gthx6:
	CMP		#'a'
	BCC		gthx3
	CMP		#'z'+1
	BCS		gthx3
	SEC
	SBC		#'a'
	CLC
	ADC		#10
	RTS
gthx3:
	LDA		#-1		; not a hex number
	RTS

AsciiToDecNybble:
	CMP		#'0'
	BCC		gtdc3
	CMP		#'9'+1
	BCS		gtdc3
	SEC
	SBC		#'0'
	RTS
gtdc3:
	LDA		#-1
	RTS

getcharNoWait:
	LDA		#1
	STA		ZS:keybd_cmd
	TSK		#6
	LDA		ZS:keybd_char
	BPL		.0001
	SEC
	RTS
.0001:
	CLC
	RTS

getcharWait:
	LDA		#2
	STA		ZS:keybd_cmd
	TSK		#6
	LDA		ZS:keybd_char
	BPL		.0001
	SEC
	RTS
.0001:
	CLC
	RTS

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Keyboard processing routines follow.
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KeybdInit:
	LDA		#$2000
	TAS
	STZ		keybd_cmd
	SEP		#$30
	MEM		8
	NDX		8
	STZ		KeyState1
	STZ		KeyState2
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
	PLA
	RTT
	BRA		KeybdService
.0004:
	LDA		#2				; select scan code set #2
	STA		KEYBD
	JSR		KeybdWaitTx
	BCC		.tryAgain
	REP		#$30
	RTT
	BRA		KeybdService

KeybdService:
	REP		#$30
	MEM		16
	NDX		16
	LDA		#$2000
	TAS
	LDA		keybd_cmd
	CMP		#1
	BNE		.0001
	JSR		KeybdGetCharNoWait
	BCS		.nokey
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.nokey
	LDA		#-1
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.0001:
	CMP		#2
	BNE		.0002
	JSR		KeybdGetCharWait
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.0002:
	RTT
	BRA		KeybdService

	MEM		8
	NDX		8
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

	cpu		FT832

KeybdGetCharNoWaitCtx:
	JSR		KeybdGetCharNoWait
	RTC		#0
	
KeybdGetCharNoWait:
	PHP
	SEP		#$20
	REP		#$10
	MEM		8
	NDX		16
	LDA		#0
	STA		KeybdWaitFlag
	BRA		KeybdGetChar1

KeybdGetCharWait:
	PHP
	SEP		#$20
	REP		#$10
	MEM		8
	NDX		16
	LDA		#$FF
	STA		KeybdWaitFlag
	BRA		KeybdGetChar1

; Wait for a keyboard character to be available
; Returns (CF=1) if no key available
; Return key (CF=0) if key is available
;
;
KeybdGetChar:
	PHP
	SEP		#$20		; 8 bit acc
	REP		#$10
	MEM		8
	NDX		16
KeybdGetChar1:
	PHX
	XBA					; force .B to zero for TAX
	LDA		#0
	XBA
.0002:
.0003:
	LDA		KEYBD+1		; check MSB of keyboard status reg.
	ASL
	BCS		.0006		; branch if keystroke ready
	BIT		KeybdWaitFlag
	BMI		.0003
	PLX
	PLP
	SEC
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
	PLP
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
	PHDS				; save off DS
	PEA		0			; set DS to zero
	PEA		0			; set DS to zero
	PLDS
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
	PLDS				; recover DS
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

warm_start:
	LDA		#$3FFF
	TAS
	JSR		CursorOn
	BRL		Mon1

	cpu		FT832
ICacheIL832:
	CACHE	#1			; 1= invalidate instruction line identified by accumulator
	RTS

ByteIRQRout:
	RTI

IRQRout:
	TSK		#1			; switch to the interrupt handling task
	RTI

	REP		#$30
	NDX		16
	MEM		16
	PHA
	JSR		Task1
	PLA
	RTI

Task1:
	REP		#$30
	NDX		16
	MEM		16
	LDA		$F01F		; check if counter expired
	BIT		#2
	BEQ		.0001
	LDA		TickCount	; increment the tick count
	INA
	STA		TickCount
	STA		$FD00A4		; update on-screen IRQ live indicator
	SEP		#$30
	NDX		8
	MEM		8
	LDA		#$05		; count down, on mpu clock, irq enabled (clears irq)
	STA		$F017
.0001:
	REP		#$30
	NDX		16
	MEM		16
;	BIT		do_invaders
;	BPL		.0002
;	TSK		#5
.0002:
	RTT					; go back to interrupted task
	BRA		Task1		; the next time task1 is run it will start here

; IRQ handler task - 32 bit
;
IRQTask:
	SEP		#$220		; eight bit accumulator, 32 bit indexes
	REP		#$110
	MEM		8
	NDX		32
IRQTask1:
	LDA		$F01F		; check if counter expired
	BIT		#2
	BEQ		.0001
	LDX		TickCount	; increment the tick count
	INX
	STX		TickCount
	STX.H	$FD00A2		; update on-screen IRQ live indicator
	LDA		#$05		; count down, on mpu clock, irq enabled (clears irq)
	STA		$F017
.0001:
;	BIT		do_invaders
;	BPL		.0002
;	TSK		#5
.0002:
	RTT					; go back to interrupted task
	BRA		IRQTask1	; the next time task is run it will start here

; This little task sample runs in native 32 bit mode and displays
; "Hello World!" on the screen.

	CPU		FT832
	MEM		8
	NDX		32

Task2:
	LDX		#84*2*3
.0003:
	LDY		#0
.0002:
	LDA		msgHelloWorld,Y
	BEQ		.0001
	JSR		AsciiToScreen8
	STA		VIDBUF,X
	INX
	INX
	INY
	BRA		.0002
.0001:
	RTT
	BRA		.0003

msgHelloWorld:
	.byte	CR,LF,"Hello World!",CR,LF,0

	NDX		16
	MEM		16

BrkTask:
	INC		$FFD00000
	RTT
	BRA		BrkTask

; The following store sequence for the benefit of Supermon816
;
BrkRout:
	PHD
	PHB
	REP		#$30
	PHA
	PHX
	PHY
	JMP		($0102)		; This jump normally points to BrkRout1
BrkRout1:
	REP		#$30
	PLY
	PLX
	PLA
	PLB
	PLD
	SEP		#$20
	PLA
	REP		#$30
	PLA
	JSR		DispWord
	LDX		#0
	LDY		#64
.0001:
	.word	$f042		; pchist
	JSR		DispWord
	LDA		#' '
	JSR		OutChar
	INX
	DEY
	BNE		.0001
	LDA		#$FFFF
	STA		$7000
Hung:
	BRA		Hung

	;--------------------------------------------------------
	;--------------------------------------------------------
	; I/O page is located at $F0xx
	;--------------------------------------------------------
	;--------------------------------------------------------	
	;org		$F100

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

TaskStartTbl:
	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	Task0		; PC
	.BYTE	Task0>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$3FFF		; sp
	.WORD	0
	.BYTE	4			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR

	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	Task1		; PC
	.BYTE	Task1>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$3BFF		; sp
	.WORD	0
	.BYTE	4			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR

	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	Task2		; PC
	.BYTE	Task2>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$37FF		; sp
	.WORD	0
	.BYTE	$20			; SR			; eight bit mem
	.BYTE	2			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR

	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	SSMTask		; PC
	.BYTE	SSMTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$33FF		; sp
	.WORD	0
	.BYTE	$4			; SR	16 bit regs, mask interrupts
	.BYTE	1			; SR extension - 816 mode
	.BYTE	0			; DB
	.WORD	0			; DPR

	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	BrkTask		; PC
	.BYTE	BrkTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$2FFF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR

	; task #5
	; DS is placed at $7800
	.WORD	0			; CS
	.WORD	0
	.WORD	7800		; DS
	.WORD	0
	.WORD	InvadersTask	; PC
	.BYTE	InvadersTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$2BFF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR

	.WORD	0			; CS
	.WORD	0
	.WORD	0			; DS
	.WORD	0
	.WORD	IRQTask		; PC
	.BYTE	IRQTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$27FF		; sp
	.WORD	0
	.BYTE	$24			; SR	8 bit acc, mask interrupts
	.BYTE	2			; SR extension - 832 mode
	.BYTE	0			; DB
	.WORD	0			; DPR

msgRegs:
	.byte	CR,LF
    .byte   "                 xxxsxi31",CR,LF
    .byte   "    CS    PB PC  xxxsxn26NVmxDIZC    .A       .X       .Y       SP  ",CR,LF,0
msgRegs2:
	.byte	CR,LF
	.byte	"    DS    DB  DP   BL",CR,LF,0

	cpu		FT832
	MEM		32
	NDX		32
	LDA		#$12345678
	LDX		#$98765432
	STA.B	{$23},Y
	LDY.UH	$44455556,X
	LDA.H	CS:$44455556,X
	LDA.UB	SEG $88888888:$1234,Y
	JSF	    $0000:start
	RTF
	TSK		#2
	TSK
	LDT		$10000,X

	.org	$F400
	JMP		SuperGetch
	JMP		warm_start
	JMP		SuperPutch
	JMP		BIOSInput

	.org 	$FFD6
	dw		4			; task #4

	.org	$FFDE
	dw		6			; task #6

	.org 	$FFE6
	dw		BrkRout

	.org	$FFEE		; IRQ vector
	dw		IRQRout

	.org	$FFFC
	dw		$E000

	.org	$FFFE
	dw		ByteIRQRout
