; ============================================================================
; bootrom2.asm
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

TS_READY	EQU		1
TS_RUNNING	EQU		2
TS_PREEMPT	EQU		4

LEDS	equ		$FFDC0600
TEXTSCR	equ		$FFD00000
TEXTREG		EQU		$FFDA0000
TEXT_COLS	EQU		0x00
TEXT_ROWS	EQU		0x04
TEXT_CURPOS	EQU		0x2C
TEXT_CURCTL	EQU		0x20

PIC			EQU		0xFFDC0FC0
PIC_IE		EQU		0xFFDC0FC4
PIC_ES		EQU		0xFFDC0FD0
PIC_RSTE	EQU		0xFFDC0FD4

KEYBD		EQU		0xFFDC0000
KEYBDCLR	EQU		0xFFDC0004

NR_TCB		EQU		256
TCB_Regs		EQU		0
TCB_SPSave		EQU		2040
TCB_Next		EQU		2048
TCB_Prev		EQU		2056
TCB_Status		EQU		2064
TCB_Priority	EQU		2065
TCB_hJob		EQU		2066
TCB_Size	EQU		8192

	bss
	org		$8
Ticks			dw		0
Milliseconds	dw		0
OutputVec		dw		0
TickVec			dw		0
RunningTCB		dw		0
FreeTCB			dw		0
QNdx0			fill.w	8,0
CursorRow		db		0
CursorCol		db		0
NormAttr		dc		0
KeybdEcho		db		0
KeybdBad		db		0
KeybdLocks		dc		0

	org		$07C00000
TCBs:
	fill.b	TCB_Size * NR_TCB,0

	code
	org		$FFFF8000
start:
	sei
;	icache_on
	nop
	ldi		r255,#$07FFDFD8			; load the stack pointer at the top of memory
									; just below vector table
	sw		r0,Milliseconds
	ldi		r1,#$CE
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	sc		r1,NormAttr
	sb		r0,CursorRow
	sb		r0,CursorCol
	ldi		r1,#DisplayChar
	sw		r1,OutputVec
	bsr		SetupIntVectors
	bsr		KeybdInit
	bsr		InitPIC
	bsr		FMTKInitialize
	cli

	ldi		r1,#$FF
	sb		r1,LEDS
	ldi		r1,#$FE
	push	r1/r2/r3/r4
;	bsr		DispLed
	bsr		ClearScreen
	ldi		r1,#$6
	sb		r1,LEDS
	bsr		DispStartMsg
	ldi		r1,#$FD
	pop		r4/r3/r2/r1
	sb		r1,LEDS
j1:
	ldi		r3,#TEXTSCR+224
	lw		r1,Milliseconds
	bsr		DisplayWord
	lh		r1,TEXTSCR+444
	add		r1,r1,#1
	sh		r1,TEXTSCR+444
	bra		r0,j1
	
DispLed:
	lw		r1,8[sp]
	sb		r1,LEDS
	rts		#8

;------------------------------------------------------------------------------
; Setup the interrupt vector for the system.
;------------------------------------------------------------------------------

SetupIntVectors:
	; First initialize all the interrupt vectors to RTI
	mfspr	r1,vbr
	ldi		r3,#511
	ldi		r2,#$4000000001			; RTI instruction
.siv1:
	sw		r2,[r1]
	sw		r0,8[r1]				; clear debug bits
	add		r1,r1,#16
	dbnz	r3,.siv1
	; Now set specific vectors
	mfspr	r1,vbr
	ldi		r2,#berr_rout*256+$50	; setup the bus error vector
	sw		r2,508*16[r1]
	ldi		r2,#start*256+$50		; keyboard reset
	sw		r2,449*16[r1]
	ldi		r2,#Tick1000Rout*256+$50
	sw		r2,450*16[r1]
	ldi		r2,#FMTKTick*256+$50
	sw		r2,451*16[r1]
	ldi		r2,#KeybdIRQ*256+$50
	sw		r2,463*16[r1]
	ldi		r2,#TickRout
	sw		r2,TickVec
	rts

;------------------------------------------------------------------------------
; Initialize the interrupt controller.
;------------------------------------------------------------------------------

InitPIC:
	ldi		r1,#$0C			; timer interrupt(s) are edge sensitive
	sh		r1,PIC_ES
	ldi		r1,#$000F		; enable keyboard reset, timer interrupts
	sh		r1,PIC_IE
	rts

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

AsciiToScreen:
	and		r1,r1,#$FF
	or		r1,r1,#$100
	and		fl0,r1,#%00100000	; if bit 5 or 6 isn't set
	brz		fl0,.00001
	and		fl0,r1,#%01000000
	brz		fl0,.00001
	and		r1,r1,#%110011111
.00001:
	rts

;------------------------------------------------------------------------------
; Convert screen display character to ascii.
;------------------------------------------------------------------------------

ScreenToAscii:
	and		r1,r1,#$FF
	cmp		fl0,r1,#26+1
	bhs		fl0,.stasc1
	add		r1,r1,#$60
.stasc1:
	rts

CursorOff:
	rts
CursorOn:
	rts
HomeCursor:
	sb		r0,CursorRow
	sb		r0,CursorCol
	sc		r0,TEXTREG+TEXT_CURPOS
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ClearScreen:
	push	r1/r2/r3/r4
	push	r5
	ldi		r1,#$5
	sb		r1,LEDS
	lbu		r1,TEXTREG+TEXT_COLS
	lbu		r2,TEXTREG+TEXT_ROWS
	mulu	r4,r2,r1
	ldi		r3,#TEXTSCR
	ldi		r5,#$10000
	ldi		r1,#' '
	bsr		AsciiToScreen
	ldi		r2,#$CE
.cs1:
	sh		r1,[r3]
	sh		r2,[r3+r5]
	addui	r3,r3,#4
	dbnz	r4,.cs1
	pop		r5
	pop		r4/r3/r2/r1
	rts

;------------------------------------------------------------------------------
; Display the word in r1
;------------------------------------------------------------------------------

DisplayWord:
	swap	r1,r1
	bsr		DisplayHalf
	swap	r1,r1

;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------

DisplayHalf:
	ror		r1,r1,#16
	bsr		DisplayCharHex
	rol		r1,r1,#16

;------------------------------------------------------------------------------
; Display the char in r1
;------------------------------------------------------------------------------

DisplayCharHex:
	ror		r1,r1,#8
	bsr		DisplayByte
	rol		r1,r1,#8

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------

DisplayByte:
	ror		r1,r1,#4
	bsr		DisplayNybble
	rol		r1,r1,#4

;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------

DisplayNybble:
	push	r1
	and		r1,r1,#$0F
	add		r1,r1,#'0'
	cmp		fl0,r1,#'9'+1
	blo		fl0,.0001
	add		r1,r1,#7
.0001:
	jsr		(OutputVec)
	pop		r1
	rts

DisplayString:
	push	r1/r2
	mov		r2,r1
.dm2:
	lbu		r1,[r2]
	add		r2,r2,#1	; increment text pointer
	brz		r1,.dm1
	bsr		OutChar
	brz		r0,.dm2
.dm1:
	pop		r2/r1
	rts

DisplayStringCRLFB:
	bsr		DisplayString
CRLF:
	push	r1
	ldi		r1,#CR
	bsr		OutChar
	ldi		r1,#LF
	bsr		OutChar
	pop		r1
	rts


DispCharQ:
	bsr		AsciiToScreen
	sc		r1,[r3]
	add		r3,r3,#4
	rts

DispStartMsg:
	lw		r1,#msgStart
	lw		r3,#TEXTSCR
	bsr		DisplayString
	rts

	db	0
msgStart:
	db	"Table888 test system starting.",0

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KeybdIRQ:
	sh		r0,KEYBD+4
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

TickRout:
	lh		tr,TEXTSCR+220
	add		tr,tr,#1
	sh		tr,TEXTSCR+220
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Tick1000Rout:
	push	r1
	ldi		r1,#2				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	lw		r1,Milliseconds
	add		r1,r1,#1
	sw		r1,Milliseconds
	pop		r1
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetScreenLocation:
	ldi		r1,#TEXTSCR
	rts
GetColorCodeLocation
	ldi		r1,#TEXTSCR+$10000
	rts
GetCurrAttr:
	lcu		r1,NormAttr
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

UpdateCursorPos:
	push	r1/r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu		r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	sc		r2,TEXTREG+TEXT_CURPOS
	pop		r4/r2/r1
	rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

CalcScreenLoc:
	push	r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu		r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	sc		r2,TEXTREG+TEXT_CURPOS
	bsr		GetScreenLocation
	shl		r2,r2,#2
	add		r1,r1,r2
	pop		r4/r2
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DisplayChar:
	push	r1/r2/r3/r4
	and		r1,r1,#$FF
	cmp		fl0,r1,#'\r'
	beq		fl0,.docr
	cmp		fl0,r1,#$91		; cursor right ?
	beq		fl0,.doCursorRight
	cmp		fl0,r1,#$90		; cursor up ?
	beq		fl0,.doCursorUp
	cmp		fl0,r1,#$93		; cursor left ?
	beq		fl0,.doCursorLeft
	cmp		fl0,r1,#$92		; cursor down ?
	beq		fl0,.doCursorDown
	cmp		fl0,r1,#$94		; cursor home ?
	beq		fl0,.doCursorHome
	cmp		fl0,r1,#$99		; delete ?
	beq		fl0,.doDelete
	cmp		fl0,r1,#CTRLH	; backspace ?
	beq		fl0,.doBackspace
	cmp		fl0,r1,#'\n'	; line feed ?
	beq		fl0,.doLinefeed
	mov		r2,r1
	bsr		CalcScreenLoc
	mov		r3,r1
	mov		r1,r2
	bsr		AsciiToScreen
	sc		r1,[r3]
	bsr		GetScreenLocation
	sub		r3,r3,r1
	bsr		GetColorCodeLocation
	add		r3,r3,r1
	bsr		GetCurrAttr
	sc		r1,[r3]
	bsr		IncCursorPos
.dcx4:
	pop		r4/r3/r2/r1
	rts
.docr:
	sb		r0,CursorCol
	bsr		UpdateCursorPos
	pop		r4/r3/r2/r1
	rts
.doCursorRight:
	lbu		r1,CursorCol
	add		r1,r1,#1
	cmp		fl0,r1,#56
	bhs		fl0,.dcx7
	sb		r1,CursorCol
.dcx7:
	bsr		UpdateCursorPos
	pop		r4/r3/r2/r1
	rts
.doCursorUp:
	lbu		r1,CursorRow
	brz		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorRow
	bra		r0,.dcx7
.doCursorLeft:
	lbu		r1,CursorCol
	brz		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorCol
	bra		r0,.dcx7
.doCursorDown:
	lbu		r1,CursorRow
	add		r1,r1,#1
	cmp		fl0,r1,#31
	bhs		fl0,.dcx7
	sb		r1,CursorRow
	bra		r0,.dcx7
.doCursorHome:
	lbu		r1,CursorCol
	brz		r1,.dcx12
	sb		r0,CursorCol
	bra		r0,.dcx7
.dcx12:
	sb		r0,CursorRow
	bra		r0,.dcx7
.doDelete:
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
	bra		r0,.dcx5
.doBackspace:
	lcu		r1,CursorCol
	brz		r1,.dcx4
	sub		r1,r1,#1
	sb		r1,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
.dcx5:
	lcu		r2,4[r3]
	sc		r2,[r3]
	add		r3,r3,#4
	add		r1,r1,#1
	cmp		fl0,r1,#56
	blo		fl0,.dcx5
	ldi		r1,#' '
	bsr		AsciiToScreen
	sub		r3,r3,#4
	sc		r1,[r3]
	bra		r0,.dcx4
.doLinefeed:
	bsr		IncCursorRow
	bra		r0,.dcx4


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

IncCursorPos:
	push	r1/r2/r4
	lbu		r1,CursorCol
	add		r1,r1,#1
	sb		r1,CursorCol
	cmp		fl0,r1,#56
	blo		fl0,icc1
	sb		r0,CursorCol
	bra		r0,icr1
IncCursorRow:
	push	r1/r2/r4
icr1:
	lbu		r1,CursorRow
	add		r1,r1,#1
	sb		r1,CursorRow
	cmp		fl0,r1,#31
	blo		fl0,icc1
	ldi		r2,#30
	sb		r2,CursorRow
	bsr		ScrollUp
icc1:
	bsr		UpdateCursorPos
	pop		r4/r2/r1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ScrollUp:
	push	r1/r2/r3/r5
	push	r6
	lbu		r1,TEXTREG+TEXT_COLS
	lbu		r2,TEXTREG+TEXT_ROWS
	sub		r2,r2,#1
	mul		r6,r1,r2
	ldi		r1,#TEXTSCR
	ldi		r2,#TEXTSCR+224
	ldi		r3,#0
.0001:
	lc		r5,[r2+r3*4]
	sc		r5,[r1+r3*4]
	lc		r5,$10000[r2+r3*4]
	sc		r5,$10000[r1+r3*4]
	add		r3,r3,#1
	dbnz	r6,.0001
	lbu		r1,TEXTREG+TEXT_ROWS
	sub		r1,r1,#1
	bsr		BlankLine
	pop		r6
	pop		r5/r3/r2/r1
	rts

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank out
;------------------------------------------------------------------------------

BlankLine:
	push	r1/r2/r3/r4
	lbu		r2,TEXTREG+TEXT_COLS
	mul		r3,r2,r1
	sub		r2,r2,#1		; r2 = #chars to blank - 1
	shl		r3,r3,#2
	add		r3,r3,#TEXTSCR
	ldi		r1,#' '
	bsr		AsciiToScreen
	lcu		r4,NormAttr
.0001:	
	sc		r1,[r3+r2*4]
	sc		r4,$10000[r3+r2*4]
	dbnz	r2,.0001
	pop		r4/r3/r2/r1
	rts

; ============================================================================
; Monitor Task
; ============================================================================

Monitor:
	bsr		ClearScreen
	ldi		r3,#TEXTSCR+448
	ldi		r1,#msgMonitorStarted
	bsr		DisplayString
	sb		r0,KeybdEcho
	ldi		r1,#7
	ldi		r2,#0
	ldi		r3,#IdleTask
	ldi		r4,#0
	ldi		r5,#0
	bsr		StartTask
mon1:
	ldi		sp,#TCBs+TCB_Size-8		; reload the stack pointer, it may have been trashed
	cli
.PromptLn:
	bsr		CRLF
	ldi		r1,#'$'
	bsr		OutChar
.Prompt3:
	bsr		KeybdGetCharDirectNB
	cmp		fl0,r1,#-1
	beq		fl0,.Prompt3
	cmp		fl0,r1,#CR
	beq		fl0,.Prompt1
	bsr		OutChar
	bra		r0,.Prompt3
.Prompt1:
	sb		r0,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	bsr		MonGetch
	cmp		fl0,r1,#'$'
	bne		fl0,.Prompt2
	bsr		MonGetch
.Prompt2:
	cmp		fl0,r1,#'?'
	beq		fl0,.doHelp
	cmp		fl0,r1,#'C'
	beq		fl0,doCLS
	cmp		fl0,r1,#'M'
	beq		fl0,doDumpmem
	cmp		fl0,r1,#'m'
	beq		fl0,MRTest
	bra		r0,mon1

.doHelp:
	ldi		r1,#msgHelp
	bsr		DisplayString
	bra		r0,mon1

MonGetch:
	lcu		r1,[r3]
	add		r3,r3,#4
	bsr		ScreenToAscii
	rts

;------------------------------------------------------------------------------
; Ignore blanks in the input
; r3 = text pointer
; r1 destroyed
;------------------------------------------------------------------------------

ignBlanks:
ignBlanks1:
	bsr		MonGetch
	cmp		fl0,r1,#' '
	beq		fl0,ignBlanks1
	sub		r3,r3,#4
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetTwoParams:
	bsr		ignBlanks
	bsr		GetHexNumber	; get start address of dump
	mov		r2,r1
	bsr		ignBlanks
	bsr		GetHexNumber	; get end address of dump
	rts

;------------------------------------------------------------------------------
; Get a range, the end must be greater or equal to the start.
;------------------------------------------------------------------------------

GetRange:
	bsr		GetTwoParams
	cmp		fl0,r2,r1
	bhi		fl0,DisplayErr
	rts

doDumpmem:
	bsr		CursorOff
	bsr		GetRange
	bsr		CRLF
.001:
	bsr		CheckKeys
	bsr		DisplayMemBytes
	cmp		fl0,r2,r1
	bls		fl0,.001
	bra		r0,mon1

OutChar:
	jmp		(OutputVec)

;------------------------------------------------------------------------------
; Display memory pointed to by r2.
; destroys r1,r3
;------------------------------------------------------------------------------
;
DisplayMemBytes:
	push	r1/r3
	ldi		r1,#'>'
	bsr		OutChar
	ldi		r1,#'B'
	bsr		OutChar
	ldi		r1,#' '
	bsr		OutChar
	mov		r1,r2
	bsr		DisplayHalf
	ldi		r3,#7
.001:
	ldi		r1,#' '
	bsr		OutChar
	lbu		r1,[r2]
	jsr		DisplayByte
	add		r2,r2,#1
	dbnz	r3,.001
	ldi		r1,#':'
	bsr		OutChar
	ldi		r1,#%0111000110	; reverse video
	sc		r1,NormAttr
	ldi		r3,#7
	sub		r2,r2,#8
.002
	lbu		r1,[r2]
	cmp		fl0,r1,#26				; convert control characters to '.'
	bhs		fl0,.004
	ldi		r1,#'.'
	bra		r0,.003
.004:
	cmp		fl0,r1,#$80				; convert other non-ascii to '.'
	blo		fl0,.003
	ldi		r1,#'.'
.003:
	bsr		OutChar
	add		r2,r2,#1
	dbnz	r3,.002
	ldi		r1,#$CE
	sc		r1,NormAttr
	bsr		CRLF
	pop		r3/r1
	rts

;------------------------------------------------------------------------------
; CheckKeys:
;	Checks for a CTRLC or a scroll lock during long running dumps.
;------------------------------------------------------------------------------

CheckKeys:
	bsr		CTRLCCheck
	bra		r0,CheckScrollLock

;------------------------------------------------------------------------------
; CTRLCCheck
;	Checks to see if CTRL-C is pressed. If so then the current routine is
; aborted and control is returned to the monitor.
;------------------------------------------------------------------------------

CTRLCCheck:
	push	r1
	bsr		KeybdGetCharDirectNB
	cmp		fl0,r1,#CTRLC
	beq		fl0,.0001
	pop		r1
	rts
.0001:
	add		sp,sp,#16
	bra		r0,mon1

;------------------------------------------------------------------------------
; CheckScrollLock:
;	Check for a scroll lock by the user. If scroll lock is active then tasks
; are rescheduled while the scroll lock state is tested in a loop.
;------------------------------------------------------------------------------

CheckScrollLock:
	push	r1
.0002:
	lcu		r1,KeybdLocks
	and		fl0,r1,#$4000		; is scroll lock active ?
	brz		fl0,.0001
	brk		#2*16				; reschedule tasks
	bra		r0,.0002
.0001:
	pop		r1
	rts

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
; R3 = text pointer (updated)
; R1 = hex number
;------------------------------------------------------------------------------
;
GetHexNumber:
	push	r2/r4
	ldi		r2,#0
	ldi		r4,#15
.gthxn2:
	bsr		MonGetch
	bsr		AsciiToHexNybble
	cmp		fl0,r1,#-1
	beq		fl0,.gthxn1
	shl		r2,r2,#4
	and		r1,r1,#$0f
	or		r2,r2,r1
	dbnz	r4,.gthxn2
.gthxn1:
	mov		r1,r2
	pop		r4/r2
	rts

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	cmp		fl0,r1,#'0'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'9'+1
	bhs		fl0,.gthx5
	sub		r1,r1,#'0'
	rts
.gthx5:
	cmp		fl0,r1,#'A'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'F'+1
	bhs		fl0,.gthx6
	sub		r1,r1,#'A'
	add		r1,r1,#10
	rts
.gthx6:
	cmp		fl0,r1,#'a'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'z'+1
	bhs		fl0,.gthx3
	sub		r1,r1,#'a'
	add		r1,r1,#10
	rts
.gthx3:
	ldi		r1,#-1		; not a hex number
	rts

DisplayErr:
	ldi		r1,#msgErr
	bsr		DisplayString
	bra		r0,mon1

msgErr:
	db	"**Err",CR,LF,0

msgHelp:
	db		"? = Display Help",CR,LF
	db		"CLS = clear screen",CR,LF
	db		"MB = dump memory",CR,LF
	db		0

msgMonitorStarted
	db		"Monitor started.",0

doCLS:
	bsr		ClearScreen
	bsr		HomeCursor
	bra		r0,mon1

KeybdGetCharDirectNB:
	push	r2
	sei
	lcu		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	cli
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.0002
	cmp		fl0,r1,#CR
	bne		fl0,.0003
	bsr		CRLF
	bra		r0,.0002
.0003:
	jsr		(OutputVec)
.0002:
	pop		r2
	rts
.0001:
	cli
	ldi		r1,#-1
	pop		r2
	rts

KeybdGetCharDirect:
	push	r2
.0001:
	lc		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.gk1
	cmp		fl0,r1,#CR
	bne		fl0,.gk2
	bsr		CRLF
	bra		r0,.gk1
.gk2:
	jsr		(OutputVec)
.gk1:
	pop		r2
	rts

KeybdInit:
	ldi		r1,#33
	sb		r1,LEDS
	ldi		r1,#$ff		; issue keyboard reset
	bsr		SendByteToKeybd
	ldi		r1,#38
	sb		r1,LEDS
	ldi		r1,#4
;	jsr		Sleep
	ldi		r1,#1000000		; delay a bit
kbdi5:
	sub		r1,r1,#1
	brnz	r1,kbdi5
	ldi		r1,#34
	sb		r1,LEDS
	ldi		r1,#0xf0		; send scan code select
	bsr		SendByteToKeybd
	ldi		r1,#35
	sb		r1,LEDS
	ldi		r2,#0xFA
	bsr		WaitForKeybdAck
	cmp		fl0,r1,#$FA
	bne		fl0,kbdi2
	ldi		r1,#36
	sb		r1,LEDS
	ldi		r1,#2			; select scan code set#2
	bsr		SendByteToKeybd
	ldi		r1,#39
	sb		r1,LEDS
kbdi2:
	rts

msgBadKeybd:
	db		"Keyboard not responding.",0

SendByteToKeybd:
	push	r2
	sb		r1,KEYBD
	ldi		r1,#40
	sb		r1,LEDS
	mfspr	r3,tick
kbdi4:						; wait for transmit complete
	mfspr	r4,tick
	sub		r4,r4,r3
	cmp		fl0,r4,#1000000
	bhi		fl0,kbdbad
	ldi		r1,#41
	sb		r1,LEDS
	lbu		r1,KEYBD+12
	and		fl0,r1,#64
	brz		fl0,kbdi4
	bra		r0,sbtk1
kbdbad:
	ldi		r1,#42
	sb		r1,LEDS
	lbu		r1,KeybdBad
	brnz	r1,sbtk2
	ldi		r1,#1
	sb		r1,KeybdBad
	ldi		r1,#43
	sb		r1,LEDS
	ldi		r1,#msgBadKeybd
	bsr		DisplayStringCRLFB
sbtk1:
	ldi		r1,#44
	sb		r1,LEDS
	pop		r2
	rts
sbtk2:
	bra		r0,sbtk1

; Wait for keyboard to respond with an ACK (FA)
;
WaitForKeybdAck:
	ldi		r1,#64
	sb		r1,LEDS
	mfspr	r3,tick
wkbdack1:
	mfspr	r4,tick
	sub		r4,r4,r3
	cmp		fl0,r4,#1000000
	bhi		fl0,wkbdbad
	ldi		r1,#65
	sb		r1,LEDS
	lcu		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,wkbdack1
;	lcu		r1,KEYBD+8
	and		r1,r1,#$ff
wkbdbad:
	rts

MRTest:
	ldi		r1,#0
	ldi		r3,#255
.0001:
	sw		r3,$100000[r0+r3*8]
	dbnz	r3,.0001
	ldi		r1,#$100000
	lmr		r2,r255,[r1]
	ldi		r1,#$120000
	smr		r2,r255,[r1]
	jmp		mon1
		
; ============================================================================
; FMTK: Finitron Multi-Tasking Kernel
;        __
;   \\__/ o\    (C) 2014  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
; ============================================================================
;  
;------------------------------------------------------------------------------
; Initialize the multi-tasking kernel.
;------------------------------------------------------------------------------

FMTKInitialize:
	mfspr	r1,vbr
	ldi		r2,#FMTKScheduler*256+$50
	sw		r2,2*16[r1]
	ldi		r2,#FMTKTick*256+$50
	sw		r2,451*16[r1]
	sw		r0,451*16+8[r1]

	sw		r0,RunningTCB
	sw		r0,QNdx0
	sw		r0,QNdx0+8
	sw		r0,QNdx0+16	
	sw		r0,QNdx0+24
	sw		r0,QNdx0+32
	sw		r0,QNdx0+40
	sw		r0,QNdx0+48
	sw		r0,QNdx0+56

	ldi		r2,#TCBs			; r2 = pointer to TCB
	ldi		r3,#TCBs+TCB_Size	; r3 = pointer to next TCB
	ldi		r6,#NR_TCB-1		; r6 = counter
	sw		r2,FreeTCB
.0001:
	sw		r3,TCB_Next[r2]
	sw		r0,TCB_Prev[r2]
	sb		r0,TCB_Status[r2]	; status = none
	sb		r0,TCB_hJob[r2]
	ldi		r4,#7
	sb		r4,TCB_Priority[r2]	; lowest priority
	mov		r2,r3				; current = next
	add		r3,r3,#TCB_Size
	dbnz	r6,.0001
	sw		r0,TCB_Next[r2]		; initialize last link

	ldi		tr,#TCBs
	ldi		r1,#4
	ldi		r2,#0
	ldi		r3,#Monitor
	ldi		r4,#0
	ldi		r5,#0
	bsr		StartTask
	
	rts

IdleTask:
.it1:
	lcu		r1,TEXTSCR+444
	add		r1,r1,#1
	sc		r1,TEXTSCR+444
	jmp		.it1

;------------------------------------------------------------------------------
; Parameters:
;	r1 = priority
;	r2 = flags
;	r3 = start address
;	r4 = parameter
;	r5 = job
;------------------------------------------------------------------------------

StartTask:
	push	r6/r7/r8

	; Get a TCB from the free list
	sei
	lw		r6,FreeTCB
	lw		r7,TCB_Next[r6]
	sw		r7,FreeTCB
	cli

	; Initialize the TCB fields
	sb		r1,TCB_Priority[r6]
	sb		r5,TCB_hJob[r6]
	add		r7,r6,#TCB_Size-8
	ldi		r8,#ExitTask
	sub		r7,r7,#32
	sw		r8,24[r7]				; setup exit address on stack
	sw		r2,16[r7]				; setup flags to pop
	sw		r3,8[r7]				; setup return address (start address)
	sw		r6,[r7]					; setup task register
	sw		r7,TCB_SPSave[r6]		; save the stack pointer
	mov		r1,r6
	sei
	bsr		AddTaskToReadyList
	cli
	brk		#2*16					; reschedule tasks
	pop		r8/r7/r6
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ExitTask:
	sei
	lw		tr,RunningTCB			; refuse to exit the Monitor task
	cmp		fl0,tr,#TCBs
	beq		fl0,.0001
	lw		r6,FreeTCB
	sw		r6,TCB_Next[tr]
	sw		tr,FreeTCB
	sw		r0,RunningTCB
	jmp		SelectTaskToRun
.0001:
	cli
	rts

;------------------------------------------------------------------------------
; Inserts a task into the ready queue at the tail.
;------------------------------------------------------------------------------

AddTaskToReadyList:
	push	r3/r4/r5/r6
	lbu		r3,TCB_Priority[r1]
	and		r3,r3,#7
	lw		r4,QNdx0[r0+r3*8]
	brz		r4,.initQ				; is the queue empty ?
	lw		r5,TCB_Prev[r4]
	lw		r6,TCB_Next[r5]
	sw		r1,TCB_Next[r5]
	sw		r1,TCB_Prev[r4]
	sw		r5,TCB_Prev[r1]
	sw		r4,TCB_Next[r1]
	ldi		r4,#TS_READY
	sb		r4,TCB_Status[r1]
	pop		r6/r5/r4/r3
	rts
.initQ:
	sw		r1,QNdx0[r0+r3*8]
	sw		r1,TCB_Next[r1]
	sw		r1,TCB_Prev[r1]
	ldi		r4,#TS_READY
	sb		r4,TCB_Status[r1]
	pop		r6/r5/r4/r3
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

RemoveTaskFromReadyList:
	push	r3/r4/r6/r7
	lw		r6,TCB_Next[r1]
	lw		r7,TCB_Prev[r1]
	sw		r7,TCB_Prev[r6]
	sw		r6,TCB_Next[r7]
	lbu		r3,TCB_Priority[r1]
	lw		r4,QNdx0[r0+r3*8]
	cmp		fl0,r4,r1
	bne		fl0,.0001
	sw		r6,QNdx0[r0+r3*8]
.0001:
	sw		r0,TCB_Next[r1]
	sw		r0,TCB_Prev[r1]
	sb		r0,TCB_Status[r1]
	pop		r7/r6/r4/r3
	rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

FMTKScheduler:
	sei
	push	tr
	lw		tr,RunningTCB
	brz		tr,SelectTaskToRun		; check if there is a context to save
	sw		sp,TCB_SPSave[tr]
	push	tr
	bsr		SaveContext
	pop		tr
	ldi		r1,#TS_READY
	sb		r1,TCB_Status[tr]
	bra		r0,SelectTaskToRun

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

nStartQue:
	db		0,1,0,2,0,3,0,1,0,4,0,5,0,6,0,7
	db		0,1,0,2,0,3,0,1,0,4,0,5,0,6,0,7

;------------------------------------------------------------------------------
; FMTKTick:
;	Timer tick routine that does the pre-emptive multi-tasking.
;------------------------------------------------------------------------------

FMTKTick:
	push	tr
	ldi		tr,#3				; reset the edge sense circuit
	sh		tr,PIC_RSTE
	lw		tr,TickVec
	brz		tr,.0001
	jsr		(TickVec)
.0001:
	ldi		r1,#$7
	sb		r1,LEDS
	lh		tr,Ticks
	add		tr,tr,#1
	sh		tr,Ticks
	lw		tr,RunningTCB
	brnz	tr,.0002
	ldi		tr,#$7BFE000
.0002:
	sw		sp,TCB_SPSave[tr]
	push	tr
	bsr		SaveContext
	pop		tr
	ldi		r1,#$8
	sb		r1,LEDS
	ldi		r6,#TS_PREEMPT
	sb		r6,TCB_Status[tr]

;------------------------------------------------------------------------------
; SelectTaskToRun:
;
;------------------------------------------------------------------------------

SelectTaskToRun:
	lh		r1,Ticks
	and		r1,r1,#$1F
	lb		r3,nStartQue[r1]
	ldi		r6,#7				; number of queues to check - 1
.qagain:
	and		r3,r3,#7			; max 0-7 queues
	lw		r1,QNdx0[r0+r3*8]
	brz		r1,.qempty
	lw		tr,TCB_Next[r1]
	sw		tr,QNdx0[r0+r3*8]
	sw		tr,RunningTCB
	ldi		r6,#TS_RUNNING
	sb		r6,TCB_Status[tr]
	bra		r0,.qxit
.qempty:
	add		r3,r3,#1
	dbnz	r6,.qagain
	ldi		tr,#$7BFE000
	jmp		.qxit
	ldi		r1,#msgNoTasks
	bsr		kernel_panic
.qerr:
	ldi		r250,#$C
	sb		r250,LEDS
	brz		r0,.qerr

.qxit:
	ldi		r1,#$A
	sb		r1,LEDS
	; RestoreContext will modify the task register
	push	tr
	bsr		RestoreContext
	pop		tr
	lw		sp,TCB_SPSave[tr]
	pop		tr
	rti

msgNoTasks:
	db		"No tasks in queue.",0

kernel_panic:
	bsr		DisplayString
	rts

;------------------------------------------------------------------------------
; Save the task context. The context is saved in blocks of 16 registers at
; a time in otder to minimize interrupt latency.
;------------------------------------------------------------------------------

SaveContext:
	smr		r1,r15,[tr]
	add		tr,tr,#15*8
	smr		r16,r31,[tr]
	add		tr,tr,#16*8
	smr		r32,r47,[tr]
	add		tr,tr,#16*8
	smr		r48,r63,[tr]
	add		tr,tr,#16*8
	smr		r64,r79,[tr]
	add		tr,tr,#16*8
	smr		r80,r95,[tr]
	add		tr,tr,#16*8
	smr		r96,r111,[tr]
	add		tr,tr,#16*8
	smr		r112,r127,[tr]
	add		tr,tr,#16*8
	smr		r128,r143,[tr]
	add		tr,tr,#16*8
	smr		r144,r159,[tr]
	add		tr,tr,#16*8
	smr		r160,r175,[tr]
	add		tr,tr,#16*8
	smr		r176,r191,[tr]
	add		tr,tr,#16*8
	smr		r192,r207,[tr]
	add		tr,tr,#16*8
	smr		r208,r223,[tr]
	add		tr,tr,#16*8
	smr		r224,r239,[tr]
	add		tr,tr,#16*8
	smr		r240,r254,[tr]
	add		tr,tr,#15*8
	rts

;------------------------------------------------------------------------------
; Restore the task context. The context is saved in blocks of 16 registers at
; a time in otder to minimize interrupt latency.
;------------------------------------------------------------------------------

RestoreContext:
	lmr		r1,r15,[tr]
	add		tr,tr,#15*8
	lmr		r16,r31,[tr]
	add		tr,tr,#16*8
	lmr		r32,r47,[tr]
	add		tr,tr,#16*8
	lmr		r48,r63,[tr]
	add		tr,tr,#16*8
	lmr		r64,r79,[tr]
	add		tr,tr,#16*8
	lmr		r80,r95,[tr]
	add		tr,tr,#16*8
	lmr		r96,r111,[tr]
	add		tr,tr,#16*8
	lmr		r112,r127,[tr]
	add		tr,tr,#16*8
	lmr		r128,r143,[tr]
	add		tr,tr,#16*8
	lmr		r144,r159,[tr]
	add		tr,tr,#16*8
	lmr		r160,r175,[tr]
	add		tr,tr,#16*8
	lmr		r176,r191,[tr]
	add		tr,tr,#16*8
	lmr		r192,r207,[tr]
	add		tr,tr,#16*8
	lmr		r208,r223,[tr]
	add		tr,tr,#16*8
	lmr		r224,r239,[tr]
	add		tr,tr,#16*8
	lmr		r240,r251,[tr]
	add		tr,tr,#12*8
	lw		r253,8[tr]
	rts

;------------------------------------------------------------------------------
; Bus error routine.
;------------------------------------------------------------------------------

berr_rout:
	ldi		r1,#$AA
	st		r1,LEDS
	mfspr	r1,bear
	bsr		DisplayWord
.be1:
	bra		r0,.be1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

AlgnFault:
	ldi		r1,#$AF
	sw		r1,LEDS
	bra		r0,AlgnFault

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DebugRout:
	ldi		r1,#$DB
	sw		r1,LEDS
	bra		r0,DebugRout

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	org		$FFFFFFB0		; Alignment fault
	bra		r0,AlgnFault

	org		$FFFFFFC0		; debug vector
	bra		r0,DebugRout

	org		$FFFFFFE0		; NMI vector
	rti

	org		$FFFFFFF0
	jmp		start
