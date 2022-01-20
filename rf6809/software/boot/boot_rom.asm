; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; BSD 3-Clause License
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
LEDS		EQU		$FFFE60001
VIA			EQU		$FFFE60000
VIA_PA		EQU		1
VIA_DDRA	EQU		3
VIA_ACR			EQU		11
VIA_IFR			EQU		13
VIA_IER			EQU		14
VIA_T3LL		EQU		18
VIA_T3LH		EQU		19
VIA_T3CMPL	EQU		20
VIA_T3CMPH	EQU		21
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
ACIA_CTRL2	EQU		11
RTC				EQU		$FFFE30500	; I2C
RTCBuf		EQU		$7FC0

KEYBD		EQU		$FFFE30400
KEYBDCLR	EQU		$FFFE30402
PIC			EQU		$FFFE3F000
SPRITE_CTRL		EQU		$FFFE10000
SPRITE_EN			EQU		$3C0

OUTSEMA	EQU	$EF0000
SEMAABS	EQU	$1000
OSSEMA	EQU	$EF0010

BIOS_SCREENS	EQU	$17000000	; $17000000 to $171FFFFF

; EhBASIC vars:
;
NmiBase		EQU		$FF0013
IrqBase		EQU		$FF0014

IOFocusNdx	EQU		$100

; These variables in global OS storage area

IOFocusList	EQU		$FF0000	; to $FF000F
IOFocusID		EQU		$FF0010
IrqSource		EQU		$FF0011
IRQFlag			EQU		$FF0012

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
kbdHeadRcv	EQU	$127
kbdTailRcv	EQU	$128
kbdFifo			EQU	$40				; in local RAM
kbdFifoAlias	EQU	$C00040	; to $C0007F	; alias for $40 to $7F
SerhZero		EQU	$130
SerHeadRcv	EQU	$131
SertZero		EQU	$132
SerTailRcv	EQU	$133
SerHeadXmit	EQU	$136
SerTailXmit	EQU	$138
SerRcvXon		EQU	$139
SerRcvXoff	EQU	$140
SerRcvBuf		EQU	$BFF000	; 4kB serial recieve buffer

farflag	EQU		$15F
asmbuf	EQU		$160	; to $17F

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


CharOutVec	EQU		$800
CharInVec	EQU		$804
CmdPromptJI	EQU	$808
MonErrVec	EQU		$80C

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

	org		$FFD400

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
	cmpy	#$8000
	blo		ramtest1
	; now readback values and compare
	ldy		#0
ramtest3:
	ldd		,y++
	cmpd	#$AAA555
	bne		ramerr
	cmpy	#$8000
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

	org		$FFE000
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
	lda		#$FFF			; all cores can do this
	sta		VIA+VIA_DDRA
	lda		#$55			; see if we can at least set LEDs
	sta		LEDS
	lda		#1				; prime OS semaphore
	sta		OSSEMA+$1000
	ldu		#st6			; U = return address
	jmp		ramtest		; JMP dont JSR
st6:
	lds		#$6FFF		; boot up stack area
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
	; Clear IO focus list
	ldx		#0
st9:
	clr		IOFocusList,x
	inx
	cmpx	#16
	blo		st9
	lda		#24
	sta		IOFocusList+FIRST_CORE

	lda		#$0CE
	sta		ScreenColor
	sta		CharColor
	bsr		ClearScreen
	ldd		#DisplayChar
	std		CharOutVec
	ldd		#SerialPeekCharDirect
	std		CharInVec
	ldb		#24				; request IO focus
	lbsr	OSCall
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
	lbsr	rtc_read	; get clock values
	ldx		#kbdHeadRcv
	ldb		#32				; number of bytes to zero out
init1:
	clr		,x+
	decb
	bne		init1
	lbsr	TimerInit
	lbsr	InitSerial
	ldx		#128
	lda		#1			; set irq(bit0), clear firq (bit1), disable int (bit 6), clear edge sense(bit 7)
	ldb		#FIRST_CORE			; serving core id
st1:
	clr		PIC,x			; cause code
	sta		PIC+1,x
	stb		PIC+2,x
	leax	4,x
	cmpx	#256
	blo		st1
;	lda		#4				; make the timer interrupt edge sensitive
;	sta		PIC+4			; reg #4 is the edge sensitivity setting
;	sta		PIC				; reg #0 is interrupt enable
	lda		#$81			; make irq edge sensitive
	sta		PIC+$FD
	lda		#31				; enable timer interrupt
;	sta		PIC+9
	ldb		#1
	stb		OUTSEMA+SEMAABS	; set semaphore to 1 available slot
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

;------------------------------------------------------------------------------
; Single core sieve.
;------------------------------------------------------------------------------

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
	rts

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
; Parameters:
;		b = core id of core to copy
;------------------------------------------------------------------------------
;
CopyVirtualScreenToScreen:
	pshs	d,x,y,u
	; Compute virtual screen location for core passed in accb.
	tfr		b,a
	asla
	asla
	asla
	asla
	ora		#$C00
	clrb
	tfr		d,x
	pshs	d
	ldy		#TEXTSCR
	ldu		#56*29/2
cv2s1:
	ldd		,x++
	std		,y++
	leau	-1,u
	cmpu	#0
	bne		cv2s1
	; reset the cursor position in the text controller
	puls	x
	ldb		CursorRow,x
	lda		#56
	mul
	tfr		d,y
	ldb		CursorCol,x
	tfr		y,x
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
	lbsr	SerialPutChar
	pshs	d,x
	cmpb	#CR					; carriage return ?
	bne		dccr
	clr		CursorCol		; just set cursor column to zero on a CR
	bsr		UpdateCursorPos
dcx14:
	lbra		dcx4
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
	bra		dcx4
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
	bra		dcx4
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
dspj2:						; lock semaphore for access
	lda		OUTSEMA+1
	beq		dspj2
dspj1B:
	ldb		,x+				; move string char into acc
	beq		dsretB		; is it end of string ?
	lbsr	OUTCH			; display character
	bra		dspj1B
dsretB:
	clr		OUTSEMA+1	; unlock semaphore
	puls	d,x,pc

DisplayStringCRLF:
	pshs	d
	bsr		DisplayString
	ldb		#CR
	lbsr	OUTCH
	ldb		#LF
	lbsr	OUTCH
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
	lbsr	OUTCH
	puls	b,pc
DispNyb1
	addb	#'0'
	lbsr	OUTCH
	puls	b,pc

;==============================================================================
; Timer
;==============================================================================

OPT INCLUDE "d:\cores2022\rf6809\software\boot\timer.asm"
OPT INCLUDE "d:\cores2022\rf6809\software\boot\i2c.asm"
OPT INCLUDE "d:\cores2022\rf6809\software\boot\rtc_driver.asm"

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
	pshs	b
INCH2:
	ldb		COREID
	cmpb	IOFocusID	; if we do not have focus, block
	bne		INCH2			
;	ldb		#$800			; block if no key available, get scancode directly
;	bra		GetKey
;	jsr		[CharInVec]	; vector is being overwritten somehow
	lbsr	SerialPeekCharDirect
	tsta
	bmi		INCH1			; block if no key available
	leas	1,s				; get rid of blocking status
	rts
INCH1:
	puls	b					; check blocking status
	tstb
	bmi 	INCH			; if blocking, loop
	ldd		#-1				; return -1 if no char available
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
	lbsr	DisplayChar
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
; Femtiki Operating System.
;==============================================================================

OSCallTbl:
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		0
	fcw		ReleaseIOFocus
	fcw		0
	fcw		RequestIOFocus

OSCall:
	; wait for availability
osc1:
	tst		OSSEMA+1
	beq		osc1
	aslb
	ldx		#OSCallTbl
	abx
	tst		,x
	beq		oscx
	jmp		[,x]
oscx:
	clr		OSSEMA+1
	rts

RequestIOFocus:
	ldb		COREID
	ldx		#IOFocusList
	abx
	sta		,x
	tst		IOFocusID
	lbne	oscx
	stb		IOFocusID
	lbra	oscx

ReleaseIOFocus:
	ldb		COREID
	ldx		#IOFocusList
	abx
	clr		,x						; clear the request indicator
	lbsr	CopyScreenToVirtualScreen
	cmpb	IOFocusID			; are we the one with the focus?
	lbne	oscx
	; We had the focus, so now a new core needs the focus.
	; Search the focus list for a requestor. If no requester
	; is found, give focus to core #1.
	lda		#15
riof2:
	incb
	andb	#15
	abx
	tst		,x
	bne		riof1
	deca
	bne		riof2
	; If no focus is requested by anyone, give to core #1
	ldb		#1
	lda		#24
	sta		,x
riof1:
	stb		IOFocusID
	lbsr	CopyVirtualScreenToScreen
	lbra	oscx
		
	
;==============================================================================
; Disassembler
;==============================================================================

OPT	include "d:\cores2022\rf6809\software\boot\disassem.asm"
	
;==============================================================================
; System Monitor
;==============================================================================

CmdPrompt:
	lbsr	CRLF
	ldb		#'$'
	lbsr	OUTCH
	lbra	OUTCH

msgF09Starting:
	fcb		"Femtiki F09 Multi-core OS Starting",CR,LF,0

MonitorStart:
	ldd		#msgF09Starting
	lbsr	DisplayString
	ldd		#HelpMsg
	lbsr	DisplayString
	ldd		#CmdPrompt
	std		CmdPromptJI
	ldd		#DisplayErr
	std		MonErrVec
	ldd		#$63FF			; default app stack
	std		mon_SSAVE
Monitor:
	leas	$6FFF				; reset stack pointer
	clrb							; turn off keyboard echo
	lbsr	SetKeyboardEcho
	; Reset IO vectors
	ldd		#SerialPeekCharDirect
	std		CharInVec
	ldd		#DisplayChar
	std		CharOutVec
	ldd		#CmdPrompt
	std		CmdPromptJI
;	jsr		RequestIOFocus
PromptLn:
	jsr		[CmdPromptJI]

; Get characters until a CR is keyed
	
Prompt3:
	ldd		#-1					; block until key present
	lbsr	INCH
	cmpb	#CR
	beq		Prompt1
	lbsr	OUTCH
	bra		Prompt3

; Process the screen line that the CR was keyed on
;
Prompt1:
	ldd		#$5050
	std		LEDS
;	ldb		RunningID
;	cmpb	#61
;	bhi		Prompt3
	ldd		#$5151
	std		LEDS
	clr		CursorCol			; go back to the start of the line
	lbsr	CalcScreenLoc	; calc screen memory location
	tfr		d,y
	ldd		#$5252
	std		LEDS
skipDollar:
	bsr		MonGetNonSpace
	cmpb	#'$'
	beq		skipDollar		; skip over '$' prompt character
	lda		#$5353
	std		LEDS

; Dispatch based on command character
;
Prompt2:
	cmpb	#'<'
	bne		PromptHelp
	bsr		MonGetch
	cmpb	#'>'
	bne		Monitor
	bsr		MonGetch
	cmpb	#'s'
	bne		Prompt2a
	ldd		#SerialPeekCharDirect
	std		CharInVec
	ldd		#SerialPutChar
	std		CharOutVec
	bra		Monitor
Prompt2a:
	cmpb	#'c'
	bne		Monitor
	ldd		#GetKey
	std		CharInVec
	ldd		#DisplayChar
	std		CharOutVec
	bra		Monitor
PromptHelp:
	cmpb	#'?'			; $? - display help
	bne		PromptC
	ldd		#HelpMsg
	lbsr	DisplayString
	bra		Monitor
PromptC:
	cmpb	#'C'
	bne		PromptD
	lbsr	ClearScreen
	lbsr	HomeCursor
	bra		Monitor
PromptD:
	cmpb	#'D'
	bne		PromptColon
	bsr		MonGetch
	cmpb	#'R'
	bne		DumpMemory
	bra		DumpRegs
PromptColon:
	cmpb	#':'
	bne		PromptF
	lbra	EditMemory
PromptF:
	cmpb	#'F'
	bne		PromptJ
	bsr		MonGetch
	cmpb	#'I'
	bne		PromptFL
	bsr		MonGetch
	cmpb	#'G'
	bne		Monitor
	jmp		$FE0000
PromptFL:
	cmpb	#'L'
	bne		Monitor
	lbra	DumpIOFocusList
PromptJ:
	cmpb	#'J'
	lbeq	jump_to_code
PromptR:
	cmpb	#'R'
	bne		Prompt_s
	ldu		#Monitor
	lbra	ramtest
Prompt_s:
	cmpb	#'s'
	bne		PromptT
	lbsr	SerialOutputTest
	bra		Monitor
PromptT:
	cmpb	#'T'
	bne		PromptU
	bsr		MonGetch
	cmpb	#'I'
	bne		Monitor
	bsr		MonGetch
	cmpb	#'R'
	bne		Monitor
	lbsr	rtc_read
	bra		Monitor
PromptU:
	cmpb	#'U'
	bne		Monitor
	lbra	disassem

MonGetch:
	ldb		,y
	iny
	rts

MonGetNonSpace:
	bsr		MonGetCh
	cmpb	#' '
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
	lbcc	grng1
	jsr		[MonErrVec]
	lbra	Monitor
grng1:
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
	ldd		#msgErr
	lbsr	DisplayString
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
	fcb	": = Edit memory bytes",CR,LF
;	db	"L = Load sector",CR,LF
;	db	"W = Write sector",CR,LF
	fcb "DR = Dump registers",CR,LF
	fcb	"D = Dump memory",CR,LF
;	db	"F = Fill memory",CR,LF
	fcb "FL = Dump I/O Focus List",CR,LF
	fcb "FIG = start FIG Forth",CR,LF
;	db	"KILL n = kill task #n",CR,LF
;	db	"B = start tiny basic",CR,LF
;	db	"b = start EhBasic 6502",CR,LF
	fcb	"J = Jump to code",CR,LF
	fcb "RAM = test RAM",CR,LF
;	db	"R[n] = Set register value",CR,LF
;	db	"r = random lines - test bitmap",CR,LF
;	db	"e = ethernet test",CR,LF
	fcb	"s = serial output test",CR,LF
;	db	"T = Dump task list",CR,LF
;	db	"TO = Dump timeout list",CR,LF
	fcb	"TI = display date/time",CR,LF
;	db	"TEMP = display temperature",CR,LF
	fcb	"U = unassemble",CR,LF
;	db	"P = Piano",CR,LF,0
	fcb		0

msgRegHeadings
	fcb	CR,LF,"  D/AB     X      Y      U      S       PC    DP  CCR",CR,LF,0

nHEX4:
	jsr		HEX4
	rts

nXBLANK:
	ldb		#' '
	lbra	OUTCH

;------------------------------------------------------------------------------
; Dump Memory
;
; Usage:
; 	$D FFFC12 FFFC20
;
; Dump formatted to look like:
;		:FFFC12 012 012 012 012 555 666 777 888
;
;------------------------------------------------------------------------------

DumpMemory:
	bsr		GetRange
	ldy		#0
	ldy		mon_r1+2
dmpm2:
	lbsr	CRLF
	ldb		#':'
	lbsr	OUTCH
	tfr		y,d
	;addd	mon_r1+2					; output the address
	lbsr	DispWordAsHex
	ldb		#' '
	lbsr	OUTCH
	ldx		#8								; number of bytes to display
dmpm1:
;	ldb		far [mon_r1+1],y
	;ldb		[mon_r1+2],y
	ldb		,y
	iny
	lbsr	DispByteAsHex			; display byte
	ldb		#' '							; followed by a space
	lbsr	OUTCH
	clrb
	clra
	lbsr	INCH
	cmpb	#CTRLC
	beq		dmpm3
	dex
	bne		dmpm1
	; Now output ascii
	ldb		#' '
	lbsr	OUTCH
	ldx		#8								; 8 chars to output
	leay	-8,y							; backup pointer
dmpm5:
;	ldb		far [mon_r1+1],y	; get the char
;	ldb		[mon_r1+2],y			; get the char
	ldb		,y
	cmpb	#$20							; is it a control char?
	bhs		dmpm4
	ldb		#'.'
dmpm4:
	lbsr	OUTCH
	iny
	dex
	bne		dmpm5
	cmpy	mon_r2+2
	blo		dmpm2
dmpm3:
	lbsr	CRLF
	lbra	Monitor

;------------------------------------------------------------------------------
; Edit Memory
;
; Usage:
; 	$$:FFFC12 8 "Hello World!" 0
;
; Dump formatted to look like:
;		:FFFC12 012 012 012 012 555 666 777 888
;
;------------------------------------------------------------------------------

EditMemory:
	ldu		#8						; set max byte count
	lbsr	GetHexNumber	; get the start address
	ldx		mon_numwka+2
EditMem2:
	lbsr	ignBlanks			; skip over blanks
	lbsr	GetHexNumber	; get the byte value
	tstb								; check for valid value
	bmi		EditMem1			; if invalid, quit
	ldb		mon_numwka+3	; get value
	stb		,x+						; update memory at address
	leau	-1,u					; decremeent byte count
	cmpu	#0
	bne		EditMem2			; go back for annother byte
EditMem1:
	lbsr	MonGetch			; see if a string is being entered
	cmpb	#'"'
	bne		EditMem3			; no string, we're done
	ldu		#40						; string must be less than 40 chars
EditMem4:
	lbsr	MonGetch			; look for close quote
	cmpb	#'"'
	bne		EditMem6			; end of string?
	ldu		#8						; reset the byte count
	bra		EditMem2
EditMem6:			
	stb		,x+						; store the character in memory
	leau	-1,u					; decrement byte count
	cmpu	#0
	bhi		EditMem4			; max 40 chars
EditMem3:
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
	lbsr	DispByteAsHex	
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

;------------------------------------------------------------------------------
; Jump to code
;
; Registers are loaded with values from the monitor register save area before
; the code is jumped to.
;
; J <address>
;------------------------------------------------------------------------------

jump_to_code:
	bsr		GetHexNumber
	sei
	lds		mon_SSAVE
	ldd		#<jtc_exit		; setup stack for RTS back to monitor
	pshs	d
	ldb		#>jtc_exit
	pshs	b
	ldd		mon_numwka+2	; get the address parameter
	pshs	d
	ldb		mon_numwka+1
	pshs	b
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
	sts		>mon_SSAVE		; need to use extended addressing, no direct page setting
	leas	$6FFF					; reset stack to system area, dont modify flags register!
	pshs	ccr						; now the stack can be used
	pshs	a							; save acca register so we can use it
	tfr		dpr,a					; a = outgoing dpr value
	sta		>mon_DPRSAVE	; force extended addressing mode usage here dpr is not set
	clra								; dpg register must be set to zero before values are 
	tfr		a,dpr					; saved in the monitor register save area.
	puls	a							; get back acca
	std		mon_DSAVE			; save regsters, can use direct addressing now
	stx		mon_XSAVE
	sty		mon_YSAVE
	stu		mon_USAVE
	puls	a							; get back ccr
	sta		mon_CCRSAVE		; and save it too
	; Reset vectors in case they got toasted.
	ldd		#SerialPeekCharDirect
	std		CharInVec
	ldd		#DisplayChar
	std		CharOutVec
	ldd		DisplayErr
	std		MonErrVec
	; todo set according to coreid
	lbra	DumpRegs			; now go do a register dump

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DumpIOFocusList:
	ldx		#0
dfl2:
	ldb		IOFocusList,x
	cmpb	#24
	bne		dfl1
	tfr		x,d
	lbsr	DispByteAsHex
	ldb		#' '
	lbsr	OUTCH
dfl1:
	inx
	cmpx	#16
	blo		dfl2
	lbsr	CRLF
	lbra	Monitor
	

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
	puls	a
	sta		mon_PCSAVE
	puls	D
	std		mon_PCSAVE+1
	sts		mon_SSAVE
	lds		#$3FFF
	cli
	jmp		DumpRegs
swi3_exit:
	sei
	lds		mon_SSAVE
	ldd		mon_PCSAVE+1
	pshs	d
	lda		mon_PCSAVE
	pshs	a
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
firq_rout:
	rti

irq_rout:
;	lbsr	SerialIRQ	; check for recieved character
;	lbsr	TimerIRQ

	; Reset the edge sense circuit in the PIC
	lda		#31							; Timer is IRQ #31
	sta		IrqSource		; stuff a byte indicating the IRQ source for PEEK()
	sta		PIC+16					; register 16 is edge sense reset reg	
	lda		VIA+VIA_IFR
	bpl		notTimerIRQ2
	bita	#$800
	beq		notTimerIRQ2
	clr		VIA+VIA_T3LL
	clr		VIA+VIA_T3LH
	inc		$E00037					; update timer IRQ screen flag
notTimerIRQ2:

	lda		IrqBase			; get the IRQ flag byte
	lsra
	ora		IrqBase
	anda	#$E0
	sta		IrqBase

;	inc		TEXTSCR+54		; update IRQ live indicator on screen
	
	; flash the cursor
	; only bother to flash the cursor for the task with the IO focus.
;	lda		COREID
;	cmpa	IOFocusID
;	bne		tr1a
;	lda		CursorFlash		; test if we want a flashing cursor
;	beq		tr1a
;	lbsr	CalcScreenLoc	; compute cursor location in memory
;	tfr		d,y
;	lda		$2000,y			; get color code $2000 higher in memory
;	ldb		IRQFlag			; get counter
;	lsrb
;	lsra
;	lsra
;	lsra
;	lsra
;	lsrb
;	rola
;	lsrb
;	rola
;	lsrb
;	rola
;	lsrb
;	rola
;	sta		$E00000,y		; store the color code back to memory
tr1a:
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
nmi_rout:
	ldb		COREID
	lda		#'I'
	ldx		#TEXTSCR+40
	sta		b,x
rti_insn:
	rti

; Special Register Area
	org		$FFFFE0

; Interrupt vector table

	org		$FFFFF0
	fcw		rti_insn		; reserved
	fcw		swi3_rout		; SWI3
	fcw		rti_insn		; SWI2
	fcw		firq_rout		; FIRQ
	fcw		irq_rout		; IRQ
	fcw		start				; SWI
	fcw		nmi_rout		; NMI
	fcw		start				; RST
