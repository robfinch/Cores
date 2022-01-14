; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
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
CR	EQU	$0D		;ASCII equates
LF	EQU	$0A
TAB	EQU	$09
CTRLC	EQU	$03
CTRLH	EQU	$08
CTRLI	EQU	$09
CTRLJ	EQU	$0A
CTRLK	EQU	$0B
CTRLM   EQU $0D
CTRLS	EQU	$13
CTRLT EQU $14
CTRLX	EQU	$18
XON		EQU	$11
XOFF	EQU	$13

FIRST_CORE	EQU	1
MAX_TASKNO	EQU 63
DRAM_BASE	EQU $10000000

ScreenLocation		EQU		$10
ColorCodeLocation	EQU		$14
ScreenLocation2		EQU		$18
BlkcpySrc			EQU		$1C
BlkcpyDst			EQU		$20
Strptr				EQU		$24
PICptr				EQU		$28
; Forth Area
; 0x30-0x60

RunningID			EQU		$800000

; Task control blocks, room for 256 tasks
TCB_NxtRdy		EQU		$00	; next task on ready / timeout list
TCB_PrvRdy		EQU		$04	; previous task on ready / timeout list
TCB_NxtTCB		EQU		$08
TCB_Timeout		EQU		$0C
TCB_Priority	EQU		$10
TCB_MSGPTR_D1	EQU		$14
TCB_MSGPTR_D2	EQU		$18
TCB_hJCB			EQU		$1C
TCB_Status		EQU		$1E
TCB_CursorRow	EQU		$20
TCB_CursorCol	EQU		$21
TCB_hWaitMbx	EQU		$22	; handle of mailbox task is waiting at
TCB_mbq_next	EQU		$24	; mailbox queue next
TCB_mbq_prev	EQU		$28	; mailbox queue previous
TCB_iof_next	EQU		$2C
TCB_iof_prev	EQU		$30
TCB_SPSave		EQU		$34	; TCB_SPSave area
TCB_mmu_map		EQU		$38

KeybdHead		EQU		$FFFFFC800
KeybdTail		EQU		$FFFFFC900
KeybdEcho		EQU		$FFFFFCA00
KeybdBad		EQU		$FFFFFCB00
KeybdAck		EQU		$FFFFFCC00
KeybdLocks		EQU		$FFFFFCD00
KeybdBuffer		EQU		$FFFFFC000	; buffer is 16 chars

COREID	EQU		$FFFFFFFE0
MSCOUNT	EQU		$FFFFFFFE4
LEDS		EQU		$FFFE60000
TEXTSCR		EQU		$FFFE00000
TEXTREG		EQU		$FFFE0DF00
TEXT_COLS	EQU		0
TEXT_ROWS	EQU		1
TEXT_CURPOS	EQU		34
ACIA		EQU		$FFFE30100
ACIA_TX		EQU		0
ACIA_RX		EQU		0
ACIA_STAT	EQU		1
ACIA_CMD	EQU		2
ACIA_CTRL	EQU		3

KEYBD		EQU		$FFFE30400
KEYBDCLR	EQU		$FFFE30402
PIC			EQU		$FFFE3F000
SPRITE_CTRL		EQU		$FFFE10000
SPRITE_EN			EQU		$3C0

BIOS_SCREENS	EQU	$17000000	; $17000000 to $171FFFFF

; EhBASIC vars:
;
NmiBase		EQU		$DC
IrqBase		EQU		$DF

; The IO focus list is a doubly linked list formed into a ring.
;
IOFocusNdx	EQU		$100
IOFocusID		EQU		$100

; These variables use direct page access
CursorRow	EQU		$110
CursorCol	EQU		$111
CharColor	EQU		$112
ScreenColor	EQU		$113
CursorFlash	EQU		$114
KeyState1	EQU	$120
KeyState2	EQU	$121
KeyLED		EQU	$122
KeybdID		EQU	$124
KeybdBlock	EQU	$126
SerhZero		EQU	$130
SerHeadRcv	EQU	$131
SertZero		EQU	$132
SerTailRcv	EQU	$133
SerHeadXmit	EQU	$136
SerTailXmit	EQU	$138
SerRcvXon		EQU	$139
SerRcvXoff	EQU	$140
SerRcvBuf		EQU	$BFF000	; 4kB serial recieve buffer

QNdx0		EQU		$780
QNdx1		EQU		QNdx0+2
QNdx2		EQU		QNdx1+2
QNdx3		EQU		QNdx2+2
QNdx4		EQU		QNdx3+2
FreeTCB		EQU		QNdx4+2
TimeoutList	EQU		FreeTCB+2
FreeMbx		EQU		RunningTCB + 2
nMailbox	EQU		FreeMbx + 2
FreeMsg		EQU		nMailbox + 2
nMsgBlk		EQU		FreeMsg + 2

IrqSource	EQU		$79A

IRQFlag		EQU		$7C6

CharOutVec	EQU		$800
CharInVec	EQU		$804

; Register save area for monitor
mon_DSAVE	EQU		$900
mon_XSAVE	EQU		$902
mon_YSAVE	EQU		$904
mon_USAVE	EQU		$906
mon_SSAVE	EQU		$908
mon_PCSAVE	EQU		$90A
mon_DPRSAVE	EQU		$90E
mon_CCRSAVE	EQU		$90F

mon_numwka	EQU		$910
mon_r1		EQU		$920
mon_r2		EQU		$924

; The ORG directive must set an address a multiple of 4 in order for the Verilog
; output to work correctly.

	org		$FFD0AC
	nop
	nop
	nop
XBLANK
	ldb		#' '
	lbsr	OUTCH
	rts

	org		$FFD0D0
	nop
	nop
CRLF
CRLF1:
	ldb		#CR
	lbsr	OUTCH
	ldb		#LF
	lbsr	OUTCH
	rts

	org		$FFD0F0
	nop
	bra		CRLF1

	org		$FFD1DC
ONEKEY
	jmp		[CharInVec]

	org		$FFD2C0
	nop
LETTER
	lbsr	OUTCH
	rts

	org		$FFD2CC
	nop
	nop
HEX2
	lbsr	DispByteAsHex
	rts
HEX4
	lbsr	DispWordAsHex
	rts

	org		$FFD300
ClearScreenJmp
	lbra	ClearScreen
	org		$FFD308
HomeCursorJmp
	lbra	HomeCursor

	org		$FFE000

; Local RAM test routine
; Checkerboard testing.
; There is 70kB of local RAM
; Does not use any RAM including no stack

ramtest:
	ldy		#0
	lda		#1
	sta		LEDS
	ldd		#$AAA555
ramtest1:
	std		,y++
	cmpy	#$C00000
	blo		ramtest1
	; now readback values and compare
	ldy		#0
ramtest3:
	ldd		,y++
	cmpd	#$AAA555
	bne		ramerr
	cmpy	#$10000
	blo		ramtest3
	lda		#2
	sta		LEDS
	jmp		,u
ramerr:
	lda		#$80
	sta		LEDS
	ldx		#TEXTSCR
	ldb		COREID
	abx
	lda		#'F'
	sta		,x
	sync
	jmp		,u

	org		$FFF000
	FDB Monitor
	FDB DumRts	;	NEXTCMD
	FDB INCH
	FDB INCHE
	FDB INCHEK
	FDB OUTCH
	FDB PDATA
	FDB PCRLF
	FDB PSTRNG
	FDB DumRts			; LRA
	FDB DumRts
	FDB DumRts
	FDB DumRts
	FDB DumRts			; VINIZ
	FDB DisplayChar	;	VOUTCH
	FDB DumRts			; ACINIZ
	FDB DumRts			; AOUTCH

DumRts:
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

start:
	lda		#$55			; see if we can at least set LEDs
	sta		LEDS
	ldu		#st6			; U = return address
	jmp		ramtest		; JMP dont JSR
st6:
	lds		#$3FFF		; boot up stack area
	lda		COREID
	cmpa	#FIRST_CORE
;	beq		st8
;	sync						; halt cores other than 2
st8:
;	bne		skip_init
;	bsr		romToRam
;	ldd		#st7 & $FFFF
;	tfr		d,x
;	jmp		,x				; jump to the BIOS now in local RAM
st7:
	bsr		Delay3s		; give some time for devices to reset
	lda		#$AA
	sta		LEDS
	lda		#FIRST_CORE
	sta		IOFocusID	; core #2 has focus
	sta		RunningID
	lda		#$0CE
	sta		ScreenColor
	sta		CharColor
	bsr		ClearScreen
	ldd		#DisplayChar
	std		CharOutVec
	ldd		#DBGGetKey
	std		CharInVec
	ldb		COREID
	cmpb	#FIRST_CORE
	beq		init
	bra		skip_init
	bra		multi_sieve
st3:
	lda		#$FF
	sta		LEDS
	bra		st3

	; initialize interrupt controller
	; first, zero out all the vectors
init:
	lbsr	InitSerial
	ldx		#128
	lda		#1			; set irq(bit0), clear firq (bit1), disable int (bit 6), clear edge sense(bit 7)
	ldb		#FIRST_CORE			; serving core id
st1:
	clr		PIC,x		; cause code
	sta		PIC+1,x
	stb		PIC+2,x
	leax	4,x
	cmpx	#256
	blo		st1
;	lda		#4				; make the timer interrupt edge sensitive
;	sta		PIC+4			; reg #4 is the edge sensitivity setting
;	sta		PIC				; reg #0 is interrupt enable

skip_init:
	andcc	#$EF			; unmask irq
	lda		#56
	sta		TEXTREG+TEXT_COLS
	lda		#29
	sta		TEXTREG+TEXT_ROWS
	bsr		ClearScreen
	bsr		HomeCursor
	lda		#5
	sta		LEDS
	ldd		#msgStartup
	bsr		DisplayString
	ldx		#0
	ldd		#0
	lbsr	ShowSprites
	lbsr	KeybdInit
	ldd		KeybdID
	bsr		DispWordAsHex
	jmp		MonitorStart

msgStartup
	fcb		"rf6809 12-bit System Starting.",CR,LF,0

;------------------------------------------------------------------------------
; The checkpoint register must be cleared within 1 second or a NMI interrupt
; will occur. checkpoint should be called with a JSR so that the global ROM
; routine is called.
;
; Modifies:
;		none
;------------------------------------------------------------------------------

checkpoint:
	clr		$FFFFFFFE1	; writing any value will do
	rts

;------------------------------------------------------------------------------
; Copy the system ROM to local RAM
; Running the code from local RAM is probably an order of magnitude faster
; then running from the global ROM. It also reduces the network traffic to
; run from local RAM.
;
; Modifies:
;		d,x,y
;------------------------------------------------------------------------------

romToRam:
	ldx		#$FFC000
	ldy		#$00C000
romToRam1:
	ldd		,x++
	std		,y++
	cmpx	#0
	bne		romToRam1
	rts

;------------------------------------------------------------------------------
; Multi-core sieve program.
;------------------------------------------------------------------------------

; First fill screen chars with 'P' indicating prime positions
; Each core is responsible for the Nth position where N is the
; core number minus two.
;
multi_sieve:
	lda		#'P'					; indicate prime
	ldb		COREID				; find out which core we are
	subb	#FIRST_CORE
	ldx		#0						; start at first char of screen
	abx
multi_sieve3:
	sta		TEXTSCR,x			; store 'P'
	leax	8,x						; advance to next position
	cmpx	#4095
	blo		multi_sieve3
	jsr		checkpoint
	addb	#2						; start sieve at 2 (core id)
	lda		#'N'					; flag position value of 'N' for non-prime
multi_sieve2:
	ldx		#0
	abx									; skip the first position - might be prime
multi_sieve1:
	abx									; increment
	sta		TEXTSCR,x
	cmpx	#4095
	blo		multi_sieve1
	jsr		checkpoint
	addb	#8						; number of cores working on it
	cmpb	#4080
	blo		multi_sieve2
multi_sieve4:					; hang machine
	sync
	lbra	Monitor

sieve:
	lda		#'P'					; indicate prime
	ldx		#0						; start at first char of screen
sieve3:
	sta		TEXTSCR,x			; store 'P'
	inx									; advance to next position
	cmpx	#4095
	blo		sieve3
	ldb		#2						; start sieve at 2
	lda		#'N'					; flag position value of 'N' for non-prime
sieve2:
	ldx		#0
	abx									; skip the first position - might be prime
sieve1:
	abx									; increment
	sta		TEXTSCR,x
	cmpx	#4095
	blo		multi_sieve1
	incb								; number of cores working on it
	cmpb	#4080
	blo		sieve2
sieve4:								; hang machine
	sync
	lbra	MonitorStart

;------------------------------------------------------------------------------
; Three second delay for user convenience and to allow some devices time to
; reset.
;------------------------------------------------------------------------------

Delay3s:
	ldd		#9000000
dly3s1:
	cmpb	#$FF
	bne		dly3s2
dly3s2:
	sta		LEDS
	subd	#1
	bne		dly3s1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
ShiftLeft5:
	aslb
	rola
	aslb
	rola
	aslb
	rola
	aslb
	rola
	aslb
	rola
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
CopyVirtualScreenToScreen:
	pshs	d,x,y,u
	bsr		GetScreenLocation
	tfr		d,x
	ldy		#TEXTSCR
	ldu		#56*29/2
cv2s1:
	ldd		,x++
	std		,y++
	leau	-1,u
	cmpu	#0
	bne		cv2s1
	; reset the cursor position in the text controller
	ldb		CursorRow
	lda		#56
	mul
	tfr		d,x
	ldb		CursorCol
	abx
	stx		TEXTREG+TEXT_CURPOS
	puls	d,x,y,u,pc

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
CopyScreenToVirtualScreen:
	pshs	d,x,y,u
	bsr		GetScreenLocation
	tfr		d,y
	ldx		#TEXTSCR
	ldu		#56*29/2
cs2v1:
	ldd		,x++
	std		,y++
	leau	-1,u
	cmpu	#0
	bne		cs2v1
	puls	d,x,y,u,pc

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	fcb		"TEXTSCR "
	fcw		TextOpen
	fcw		TextClose
	fcw		TextRead
	fcw		TextWrite
	fcw		TextSeek

TextOpen:
	rts
TextClose:
	rts
TextRead:
	rts
TextWrite:
	rts
TextSeek:
	rts

;------------------------------------------------------------------------------
; Clear the screen and the screen color memory
; We clear the screen to give a visual indication that the system
; is working at all.
;
; Modifies:
;		none
;------------------------------------------------------------------------------

ClearScreen:
	pshs	d,x,y,u
	ldx		#56*29
	tfr		x,u
	bsr		GetScreenLocation
	tfr		d,y
	ldb		#' '				; space char
cs1:
	stb		,y+					; set text to space
	leax	-1,x				; decrement x
	bne		cs1
	ldb		COREID			; update colors only if we have focus
	cmpb	IOFocusID
	bra		cs3
	ldy		#TEXTSCR+$2000
;	lda		CharColor
	lda		#$0CE
	tfr		u,x					; get back count
cs2:
	sta		,y+
	dex								; decrement x
	bne		cs2
cs3:
	puls	d,x,y,u,pc

;------------------------------------------------------------------------------
; Scroll text on the screen upwards
;
; Modifies:
;		none
;------------------------------------------------------------------------------

ScrollUp:
	pshs	d,x,y,u
	ldy		#(56*29-1)/2	; y = num chars/2 to move
	bsr		GetScreenLocation
	tfr		d,x
	tfr		d,u
	leax	56,x			; x = index to source row
scrup1:
	ldd		,x++			; move 2 characters
	std		,u++
	dey
	bne		scrup1
	lda		#29
	bsr		BlankLine
	puls	d,x,y,u,pc

;------------------------------------------------------------------------------
; Blank out a line on the display
;
; Modifies:
;		none
; Parameters:
; 	acca = line number to blank
;------------------------------------------------------------------------------

BlankLine:
	pshs	d,x
	pshs	a
	bsr		GetScreenLocation
	tfr		d,x
	puls	a
	ldb		#56		; b = # chars to blank out from video controller
	mul					; d = screen index (row# * #cols)
	leax	d,x
	lda		#' '
	ldb		#56		; b = # chars to blank out from video controller
blnkln1:
	sta		,x+
	decb
	bne		blnkln1
	puls	d,x,pc

;------------------------------------------------------------------------------
; Get the location of the screen memory. The location
; depends on whether or not the task has the output focus.
;
; Modifies:
;		d
; Retuns:
;		d = screen location
;------------------------------------------------------------------------------

GetScreenLocation:
	lda		COREID			; which core are we?
	cmpa	IOFocusID		; do we have the IO focus
	bne		gsl1				; no, go pick virtual screen address
	ldd		#TEXTSCR		; yes, we update the real screen
	rts
gsl1:
	ldd		#$7800
	rts

;------------------------------------------------------------------------------
; HomeCursor
; Set the cursor location to the top left of the screen.
;
; Modifies:
;		none
;------------------------------------------------------------------------------

HomeCursor:
	pshs	d,x
	clr		CursorRow
	clr		CursorCol
	ldb		COREID
	cmpb	IOFocusID
	bne		hc1
	clra
	sta		TEXTREG+TEXT_CURPOS
hc1:
	puls	d,x,pc

;------------------------------------------------------------------------------
; Update the cursor position in the text controller based on the
;  CursorRow,CursorCol.
;
; Modifies:
;		none
;------------------------------------------------------------------------------
;
UpdateCursorPos:
	pshs	d,x
	ldb		COREID				; update cursor position in text controller
	cmpb	IOFocusID			; only for the task with the output focus
	bne		ucp1					
	lda		CursorRow
	anda	#$3F					; limit of 63 rows
	ldb		TEXTREG+TEXT_COLS
	mul
	tfr		d,x
	ldb		CursorCol
	abx
	stx		TEXTREG+TEXT_CURPOS
ucp1:
	puls	d,x,pc

;------------------------------------------------------------------------------
; Calculate screen memory location from CursorRow,CursorCol.
; Also refreshes the cursor location.
;
; Modifies:
;		d
; Returns:
; 	d = screen location
;------------------------------------------------------------------------------
;
CalcScreenLoc:
	pshs	x
	lda		CursorRow
	ldb		#56
	mul
	tfr		d,x
	ldb		CursorCol
	abx
	ldb		COREID				; update cursor position in text controller
	cmpb	IOFocusID			; only for the task with the output focus
	bne		csl1					
	stx		TEXTREG+TEXT_CURPOS
csl1:
	bsr		GetScreenLocation
	leax	d,x
	tfr		x,d
	puls	x,pc

;------------------------------------------------------------------------------
; Display a character on the screen.
; If the task doesn't have the I/O focus then the character is written to
; the virtual screen.
;
; Modifies:
;		none
; Parameters:
; 	accb = char to display
;------------------------------------------------------------------------------
;
DisplayChar:
;	lbsr	SerialPutChar
	pshs	d,x
	cmpb	#CR					; carriage return ?
	bne		dccr
	clr		CursorCol		; just set cursor column to zero on a CR
	bsr		UpdateCursorPos
dcx14:
	puls	d,x,pc
dccr:
	cmpb	#$91				; cursor right ?
	bne		dcx6
	lda		CursorCol
	cmpa	#56
	bhs		dcx7
	inca
	sta		CursorCol
dcx7:
	bsr		UpdateCursorPos
	puls	d,x,pc
dcx6:
	cmpb	#$90				; cursor up ?
	bne		dcx8		
	lda		CursorRow
	beq		dcx7
	deca
	sta		CursorRow
	bra		dcx7
dcx8:
	cmpb	#$93				; cursor left ?
	bne		dcx9
	lda		CursorCol
	beq		dcx7
	deca
	sta		CursorCol
	bra		dcx7
dcx9:
	cmpb	#$92				; cursor down ?
	bne		dcx10
	lda		CursorRow
	cmpa	#29
	beq		dcx7
	inca
	sta		CursorRow
	bra		dcx7
dcx10:
	cmpb	#$94				; cursor home ?
	bne		dcx11
	lda		CursorCol
	beq		dcx12
	clr		CursorCol
	bra		dcx7
dcx12:
	clr		CursorRow
	bra		dcx7
dcx11:
	cmpb	#$99				; delete ?
	bne		dcx13
	bsr		CalcScreenLoc
	tfr		d,x
	lda		CursorCol		; acc = cursor column
	bra		dcx5
dcx13
	cmpb	#CTRLH			; backspace ?
	bne		dcx3
	lda		CursorCol
	beq		dcx4
	deca
	sta		CursorCol
	bsr		CalcScreenLoc
	tfr		d,x
	lda		CursorCol
dcx5:
	ldb		1,x
	stb		,x++
	inca
	cmpa	#56
	blo		dcx5
	ldb		#' '
	dex
	stb		,x
	puls	d,x,pc
dcx3:
	cmpb	#LF				; linefeed ?
	beq		dclf
	pshs	b
	bsr 	CalcScreenLoc
	tfr		d,x
	puls	b
	stb		,x
	; ToDo character color
;	lda		CharColor
;	sta		$2000,x
	bsr		IncCursorPos
	puls	d,x,pc
dclf:
	bsr		IncCursorRow
dcx4:
	puls	d,x,pc

;------------------------------------------------------------------------------
; Increment the cursor position, scroll the screen if needed.
;
; Modifies:
;		none
;------------------------------------------------------------------------------

IncCursorPos:
	pshs	d,x
	lda		CursorCol
	inca
	sta		CursorCol
	cmpa	#56
	blo		icc1
	clr		CursorCol		; column = 0
	bra		icr1
IncCursorRow:
	pshs	d,x
icr1:
	lda		CursorRow
	inca
	sta		CursorRow
	cmpa	#29
	blo		icc1
	deca							; backup the cursor row, we are scrolling up
	sta		CursorRow
	bsr		ScrollUp
icc1:
	bsr		UpdateCursorPos
icc2:
	puls	d,x,pc	

;------------------------------------------------------------------------------
; Display a string on the screen.
;
; Modifies:
;		none
; Parameters:
;		d = pointer to string
;------------------------------------------------------------------------------
;
DisplayString:
	pshs	d,x
	tfr		d,x
dspj1B:
	ldb		,x+				; move string char into acc
	beq		dsretB		; is it end of string ?
	bsr		OUTCH			; display character
	bra		dspj1B
dsretB:
	puls	d,x,pc

DisplayStringCRLF:
	pshs	d
	bsr		DisplayString
	ldb		#CR
	bsr		OUTCH
	ldb		#LF
	bsr		OUTCH
	puls	d,pc
	
;
; PRINT CR, LF, STRING
;
PSTRNG
	BSR		PCRLF
	BRA		PDATA
PCRLF
	PSHS	X
	LDX		#CRLFST
	BSR		PDATA
	PULS	X
	RTS

PRINT
	JSR		OUTCH
PDATA
	LDB		,X+
	CMPB	#$04
	BNE		PRINT
	RTS

CRLFST
	fcb	CR,LF,4

DispDWordAsHex:
	bsr		DispWordAsHex
	exg		d,x
	bsr		DispWordAsHex
	exg		d,x
	rts

DispWordAsHex:
	exg		a,b
	bsr		DispByteAsHex
	exg		a,b
	bsr		DispByteAsHex
	rts

DispByteAsHex:
  pshs	b
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb
	lsrb
	bsr		DispNyb
	puls	b
	pshs	b
	lsrb
	lsrb
	lsrb
	lsrb
	bsr		DispNyb
	puls	b

DispNyb
	pshs	b
	andb	#$0F
	cmpb	#10
	blo		DispNyb1
	addb	#'A'-10
	bsr		OUTCH
	puls	b,pc
DispNyb1
	addb	#'0'
	bsr		OUTCH
	puls	b,pc

;==============================================================================
; Keyboard I/O
;==============================================================================

OPT INCLUDE "d:\cores2022\rf6809\software\boot\scancodes.asm"
OPT INCLUDE "d:\cores2022\rf6809\software\boot\keyboard.asm"

	fcb		"KEYBOARD"
	fcw		KeybdOpen
	fcw		KeybdClose
	fcw		KeybdRead
	fcw		KeybdWrite
	fcw		KeybdSeek

; Keyboard Open:
; Initialize the keyboard buffer head and tail indexes
;
KeybdOpen:
	rts

; Keyboard Close:
; Nothing to do except maybe clear the keyboard buffer
;
KeybdClose:
	rts
;
KeybdRead:
	rts
;
KeybdWrite:
	rts

KeybdSeek:
	rts

;==============================================================================
; Serial I/O
;==============================================================================

OPT INCLUDE "d:\cores2022\rf6809\software\boot\serial.asm"

;------------------------------------------------------------------------------
; Check if there is a keyboard character available. If so return true (<0)
; otherwise return false (0) in accb.
;------------------------------------------------------------------------------
;
KeybdCheckForKeyDirect:
	bra		DBGCheckForKey

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
INCH:
	ldd		#-1				; block if no key available
	bra		DBGGetKey
	lbsr	SerialPeekCharDirect
	tsta
	bmi		INCH			; block if no key available
	rts


INCHE:
	bsr		INCH
	bra		INCHEK3

INCHEK:
	bsr		INCH
	tst		KeybdEcho
	beq		INCHEK1
INCHEK3:
	cmpa	#CR
	bne		INCHEK2
	lbsr		CRLF
	bra		INCHEK1
INCHEK2:
	bsr		DisplayChar
INCHEK1:
	rts

OUTCH:
	jmp		[CharOutVec]

;------------------------------------------------------------------------------
; r1 0=echo off, non-zero = echo on
;------------------------------------------------------------------------------
;
SetKeyboardEcho:
	stb		KeybdEcho
	rts


;------------------------------------------------------------------------------
; Parameters:
;		x,d	bitmap of sprites to enable
;------------------------------------------------------------------------------

ShowSprites:
	stx		SPRITE_CTRL+SPRITE_EN
	std		SPRITE_CTRL+SPRITE_EN+2
	rts

;==============================================================================
; System Monitor
;==============================================================================
;
MonitorStart:
	ldd		#HelpMsg
	bsr		DisplayString
Monitor:
	leas	$3FFF				; reset stack pointer
	clrb							; turn off keyboard echo
	bsr		SetKeyboardEcho
;	jsr		RequestIOFocus
PromptLn:
	lbsr	CRLF
	ldb		#'$'
	bsr		OUTCH

; Get characters until a CR is keyed
	
Prompt3:
	ldd		#-1					; block until key present
	bsr		INCH
	cmpb	#CR
	beq		Prompt1
	bsr		OUTCH
	bra		Prompt3

; Process the screen line that the CR was keyed on
;
Prompt1:
	ldd		#$5050
	std		LEDS
	ldb		RunningID
	cmpb	#61
	bhi		Prompt3
	ldd		#$5151
	std		LEDS
	clr		CursorCol			; go back to the start of the line
	lbsr	CalcScreenLoc	; calc screen memory location
	tfr		d,y
	ldd		#$5252
	std		LEDS
	bsr		MonGetNonSpace
	cmpb	#'$'
	bne		Prompt2			; skip over '$' prompt character
	lda		#$5353
	std		LEDS
	bsr		MonGetNonSpace

; Dispatch based on command character
;
Prompt2:
	cmpb	#'?'			; $? - display help
	bne		PromptC
	ldd		#HelpMsg
	bsr		DisplayString
	bra		Monitor
PromptC:
	cmpb	#'C'
	bne		PromptD
	lbsr	ClearScreen
	lbsr	HomeCursor
	bra		Monitor
PromptD:
	cmpb	#'D'
	bne		PromptF
	bsr		MonGetch
	cmpb	#'R'
	bne		DumpMemory
	bra		DumpRegs
PromptF:
	cmpb	#'F'
	bne		PromptJ
	bsr		MonGetch
	cmpb	#'I'
	bne		Monitor
	bsr		MonGetch
	cmpb	#'G'
	bne		Monitor
	jmp		$FE0000
PromptJ:
	cmpb	#'J'
	lbeq	jump_to_code
PromptR:
	cmpb	#'R'
	bne		Monitor
	lbsr	ramtest
	bra		Monitor

MonGetch:
	ldb		,y
	iny
	rts

MonGetNonSpace:
	bsr		MonGetCh
	cmpb	#' '
	beq		MonGetNonSpace
	cmpb	#9		; tab
	beq		MonGetNonSpace
	rts

;------------------------------------------------------------------------------
; Ignore blanks in the input
; Y = text pointer
; D destroyed
;------------------------------------------------------------------------------
;
ignBlanks:
ignBlanks1:
	bsr		MonGetch
	cmpb	#' '
	beq		ignBlanks1
	dey
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
GetTwoParams:
	bsr		ignBlanks
	bsr		GetHexNumber	; get start address of dump
	ldd		mon_numwka
	std		mon_r1
	ldd		mon_numwka+2
	std		mon_r1+2
	bsr		ignBlanks
	bsr		GetHexNumber	; get end address of dump
	ldd		mon_numwka
	std		mon_r2
	ldd		mon_numwka+2
	std		mon_r2+2
	rts

;------------------------------------------------------------------------------
; Get a range, the end must be greater or equal to the start.
;------------------------------------------------------------------------------
GetRange:
	bsr		GetTwoParams
	ldd		mon_r2+2
	subd	mon_r1+2
	ldd		mon_r2
	sbcb	mon_r1+1
	sbca	mon_r1
	lbcs	DisplayErr
	rts

shl_numwka:
	asl		mon_numwka+3
	rol		mon_numwka+2
	rol		mon_numwka+1
	rol		mon_numwka
	rts

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of twelve digits.
;
; Modifies:
; 	Y = text pointer (updated)
; 	D = number of digits
; 	mon_numwka contains number
;------------------------------------------------------------------------------
;
GetHexNumber:
	clrd
	std		mon_numwka	; zero out work area
	std		mon_numwka+2
	pshs	x
	ldx		#0					; max 12 eight digits
gthxn2:
	bsr		MonGetch
	bsr		AsciiToHexNybble
	cmpb	#-1
	beq		gthxn1
	bsr		shl_numwka
	bsr		shl_numwka
	bsr		shl_numwka
	bsr		shl_numwka
	andb	#$0f
	orb		mon_numwka+3
	stb		mon_numwka+3
	inx
	cmpx	#12
	blo		gthxn2
gthxn1:
	tfr		x,d
	puls	x,pc

;GetDecNumber:
;	phx
;	push	r4
;	push	r5
;	ldx		#0
;	ld		r4,#10
;	ld		r5,#10
;gtdcn2:
;	jsr		MonGetch
;	jsr		AsciiToDecNybble
;	cmp		#-1
;	beq		gtdcn1
;	mul		r2,r2,r5
;	add		r2,r1
;	dec		r4
;	bne		gtdcn2
;gtdcn1:
;	txa
;	pop		r5
;	pop		r4
;	plx
;	rts

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	cmpb	#'0'
	blo		gthx3
	cmpb	#'9'
	bhi		gthx5
	subb	#'0'
	rts
gthx5:
	cmpb	#'A'
	blo		gthx3
	cmpb	#'F'
	bhi		gthx6
	subb	#'A'
	addb	#10
	rts
gthx6:
	cmpb	#'a'
	blo		gthx3
	cmpb	#'z'
	bhi		gthx3
	subb	#'a'
	addb	#10
	rts
gthx3:
	ldb		#-1		; not a hex number
	rts

AsciiToDecNybble:
	cmpb	#'0'
	bcc		gtdc3
	cmpb	#'9'+1
	bcs		gtdc3
	subb	#'0'
	rts
gtdc3:
	ldb		#-1
	rts

DisplayErr:
	ldx		#msgErr
	clrd
	bsr		DisplayStringDX
	jmp		Monitor

DisplayStringDX
	std		Strptr
	stx		Strptr+2
	jsr		DisplayString
	rts

msgErr:
	fcb	"**Err",CR,LF,0

HelpMsg:
	fcb		"? = Display help",CR,LF
	fcb	"CLS = clear screen",CR,LF
;	db	"S = Boot from SD Card",CR,LF
;	db	": = Edit memory bytes",CR,LF
;	db	"L = Load sector",CR,LF
;	db	"W = Write sector",CR,LF
	fcb "DR = Dump registers",CR,LF
	fcb	"D = Dump memory",CR,LF
;	db	"F = Fill memory",CR,LF
;	db  "FL = Dump I/O Focus List",CR,LF
	fcb "FIG = start FIG Forth",CR,LF
;	db	"KILL n = kill task #n",CR,LF
;	db	"B = start tiny basic",CR,LF
;	db	"b = start EhBasic 6502",CR,LF
	fcb	"J = Jump to code",CR,LF
	fcb "RAM = test RAM",CR,LF
;	db	"R[n] = Set register value",CR,LF
;	db	"r = random lines - test bitmap",CR,LF
;	db	"e = ethernet test",CR,LF
;	db	"T = Dump task list",CR,LF
;	db	"TO = Dump timeout list",CR,LF
;	db	"TI = display date/time",CR,LF
;	db	"TEMP = display temperature",CR,LF
;	db	"P = Piano",CR,LF,0
	fcb		0

msgRegHeadings
	fcb	CR,LF," D/AB   X    Y    U    S     PC    DP CCR",CR,LF,0

nHEX4:
	jsr		HEX4
	rts

nXBLANK:
	ldb		#' '
	bra		OUTCH

;------------------------------------------------------------------------------
; Dump Memory
;
; Usage:
; 	$D FFFC12 8
;
; Dump formatted to look like:
;		:FFFC12 012 012 012 012 555 666 777 888
;
;------------------------------------------------------------------------------

DumpMemory:
	bsr		GetTwoParams
	ldy		#0
dmpm2:
	lbsr	CRLF
	ldb		#':'
	lbsr	OUTCH
	ldd		mon_r1+2					; output the address
	lbsr	DispWordAsHex
	ldb		#' '
	lbsr	OUTCH
	ldx		#8								; number of bytes to display
dmpm1:
	ldb		far [mon_r1+1],y
	iny
	lbsr	DispByteAsHex			; display byte
	ldb		#' '							; followed by a space
	lbsr	OUTCH
	dex
	bne		dmpm1
	cmpy	mon_r2+2
	blo		dmpm2
	lbsr	CRLF
	lbra	Monitor

;------------------------------------------------------------------------------
; Dump Registers
;
;	Usage:
;		$DR
;------------------------------------------------------------------------------

DumpRegs:
	ldd		#msgRegHeadings
	lbsr	DisplayString
	bsr		nXBLANK
	ldd		mon_DSAVE
	bsr		nHEX4
	bsr		nXBLANK
	ldd		mon_XSAVE
	bsr		nHEX4
	bsr		nXBLANK
	ldd		mon_YSAVE
	bsr		nHEX4
	bsr		nXBLANK
	ldd		mon_USAVE
	bsr		nHEX4
	bsr		nXBLANK
	ldd		mon_SSAVE
	bsr		nHEX4
	bsr		nXBLANK
	ldb		mon_PCSAVE+1
	bsr		DispByteAsHex
	ldd		mon_PCSAVE+2
	bsr		nHEX4
	bsr		nXBLANK
	ldd		mon_DPRSAVE
	jsr		HEX2
	bsr		nXBLANK
	lda		mon_CCRSAVE
	lbsr	HEX2
	bsr		nXBLANK
	lbra	Monitor

; Jump to code
jump_to_code:
	bsr		GetHexNumber
	sei
	lds		mon_SSAVE
	ldd		#<jtc_exit
	pshs	d
	ldd		#>jtc_exit
	pshs	b
	ldd		mon_numwka+2
	pshs	d
	ldd		mon_numwka
	pshs	d
	ldd		mon_USAVE
	pshs	d
	ldd		mon_YSAVE
	pshs	d
	ldd		mon_XSAVE
	pshs	d
	lda		mon_DPRSave
	pshs	a
	ldd		mon_DSAVE
	pshs	d
	lda		mon_CCRSAVE
	pshs	a
	puls	far ccr,d,dpr,x,y,u,pc
jtc_exit:
	pshs	ccr
	std		mon_DSAVE
	stx		mon_XSAVE
	sty		mon_YSAVE
	stu		mon_USAVE
	tfr		dpr,a
	sta		mon_DPRSAVE
	puls	a
	sta		mon_CCRSAVE
	sts		mon_SSAVE
	lds		#$3FFF
	; todo set according to coreid
	jmp		DumpRegs

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
swi3_rout:
	sei
	puls	a
	sta		mon_CCRSAVE
	puls	D,DPR,X,Y,U
	std		mon_DSAVE
	stx		mon_XSAVE
	sty		mon_YSAVE
	stu		mon_USAVE
	tfr		dpr,a
	sta		mon_DPRSAVE
	puls	D
	std		mon_PCSAVE
	puls	D
	std		mon_PCSAVE+2
	sts		mon_SSAVE
	lds		#$3FFF
	cli
	jmp		DumpRegs
swi3_exit:
	sei
	lds		mon_SSAVE
	ldd		mon_PCSAVE+2
	pshs	d
	ldd		mon_PCSAVE
	pshs	d
	ldu		mon_USAVE
	ldy		mon_YSAVE
	ldx		mon_XSAVE
	pshs	x,y,u
	lda		mon_DPRSAVE
	pshs	a
	ldd		mon_DSAVE
	pshs	d
	lda		mon_CCRSAVE
	pshs	a
	tfr		a,ccr
	cli
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
irq_rout:
	lbsr	SerialIRQ	; check for recieved character

	; Reset the edge sense circuit in the PIC
	lda		#2				; Timer is IRQ #2
	sta		PIC+6			; register 6 is edge sense reset reg	

	sta		IrqSource		; stuff a byte indicating the IRQ source for PEEK()
	lda		IrqBase			; get the IRQ flag byte
	lsra
	ora		IrqBase
	anda	#$E0
	sta		IrqBase

	inc		TEXTSCR+110		; update IRQ live indicator on screen
	
	; flash the cursor
	; only bother to flash the cursor for the task with the IO focus.
	lda		COREID
	cmpa	IOFocusID
	bne		tr1a
	lda		CursorFlash		; test if we want a flashing cursor
	beq		tr1a
	lbsr	CalcScreenLoc	; compute cursor location in memory
	tfr		d,y
	lda		$2000,y			; get color code $2000 higher in memory
	ldb		IRQFlag			; get counter
	lsrb
	lsra
	lsra
	lsra
	lsra
	lsrb
	rola
	lsrb
	rola
	lsrb
	rola
	lsrb
	rola
	sta		$E00000,y		; store the color code back to memory
tr1a
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
nmi_rout:
	ldb		COREID
	lda		#'I'
	ldx		#TEXTSCR+40
	abx
	sta		,x
	rti

	org		$FFFFF0
	nop
	nop
	fcw		swi3_rout

	org		$FFFFF8
	fcw		irq_rout
	fcw		start				; SWI
	fcw		nmi_rout		; NMI
	fcw		start				; RST
