; N4V68kSys bootrom - (C) 2017 Robert Finch, Waterloo
;
; This file is part of N4V68kSys
;
; how to build:
; 1. assemble using "asm68 bootrom.asm /G00 /olyebvm"
; 2. copy bootrom.vh to the correct directory if not already there
;
;------------------------------------------------------------------------------
;
; system memory map
;
;
; 00000000 +----------------+
;          | startup sp,pc  | 8 B
; 00000008 +----------------+
;          |                |
;          |                |
;          |                |
;          :  dram memory   : 512 MB
;          |                |
;          |                |
;          |                |
; 20000000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FF800000 +----------------+
;          |                |
;          : display buffer : 896k
;          |                |
; FF8E0000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FFD00000 +----------------+
;          |                |
;          :    I/O area    : 1.0 M
;          |                |
; FFE00000 +----------------+
;          |   VDG regs     |
; FFE01000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FFFC0000 +----------------+
;          |                |
;          :    boot rom    :
;          |                |
; FFFFFFFF +----------------+
;
;
RGBMASK		EQU		%0111111111111111
RED			EQU		%0111110000000000
DARK_BLUE	EQU		%0000000000001111
BLACK		EQU		%0000000000000000
WHITE		EQU		%0111111111111111

CR		EQU		$0D
LF		EQU		$0A

SC_F12  EQU    $07
SC_C    EQU    $21
SC_T    EQU    $2C
SC_Z    EQU    $1A
SC_KEYUP	EQU		$F0
SC_EXTEND   EQU		$E0
SC_CTRL		EQU		$14
SC_RSHIFT	EQU		$59
SC_NUMLOCK	EQU		$77
SC_SCROLLLOCK	EQU	$7E
SC_CAPSLOCK		EQU	$58
SC_ALT		EQU		$11
SC_LSHIFT	EQU		$12
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
SC_TAB      EQU		$0D

TEXTCOLS	EQU	40
TEXTROWS	EQU	32

VDGBUF		EQU	$FF800000
VDGREG		EQU	$FFE00000
VDG_CURX	EQU	$0440
VDG_CURY	EQU	$0442
VDG_CURSZ	EQU	$0444
VDG_CURCLR	EQU	$0446
VDG_CURFLSH	EQU	$0448
VDG_CURIMG	EQU	$0460
I2C			EQU	$FFDC0E00
I2C2		EQU	$FFDC0E10
VirtScreen	EQU	$1FFF0000
KEYBD		EQU	$FFDC0000
leds		EQU	$FFDC0600
rand		EQU	$FFDC0C00

fgcolor		EQU	$10002
bkcolor		EQU	$10004
fntsz		EQU	$10006
memend		EQU	$10008
CursorRow	EQU	$10418
CursorCol	EQU $10419
TextRows	EQU	$1041A
TextCols	EQU	$1041B
TextCurpos	EQU	$1041C
TextScr		EQU	$10420
KeybdEcho		EQU	$10424
KeybdWaitFlag	EQU	$10425
_KeyState1		EQU	$10426
_KeyState2		EQU	$10427
KeybdLEDs		EQU	$10428

reg_d0			EQU	$10500
reg_d1			EQU	$10504
reg_d2			EQU	$10508
reg_d3			EQU	$1050C
reg_d4			EQU $10510
reg_d5			EQU $10514
reg_d6			EQU	$10518
reg_d7			EQU	$1051C
reg_a0			EQU $10520
reg_a1			EQU	$10524
reg_a2			EQU	$10528
reg_a3			EQU $1052C
reg_a4			EQU $10530
reg_a5			EQU $10534
reg_a6			EQU $10538
reg_ssp			EQU	$1053C
reg_usp			EQU	$10540
reg_pc			EQU $10544
reg_sr			EQU	$10548

RTCBuf			EQU	$10600
RTFBufEnd		EQU	$10660

	org		$FFFC0000

;------------------------------------------------------------------------------

	dc.l	$FF401000	; initial SSP
	dc.l	Start		; initial PC
	
;------------------------------------------------------------------------------
fpga_version:
	dc.b	"AA000000"	; FPGA core version - 8 ASCII characters

;------------------------------------------------------------------------------
	Start:
;------------------------------------------------------------------------------
		move.w	#$A1A1,leds		; diagnostics

		; SIM croaked because the upper half of D1 was undefined. This caused
		; problems with a dbra instruction. So the contents of all the registers
		; are defined at startup. This is only needed for SIM.
		moveq	#0,D0
		moveq	#0,D1				; for SIM
		moveq	#0,D2
		moveq	#0,D3
		moveq	#0,D4
		moveq	#0,D5
		moveq	#0,D6
		moveq	#0,D7
		clr.l	A0
		clr.l	A1
		clr.l	A2
		clr.l	A3
		clr.l	A4
		clr.l	A5
		clr.l	A6
		move.l	A7,usp

		bsr		i2c_setup
		bsr		rtc_read
		move.w	#$A2A2,leds		; diagnostics

		move.b	#TEXTCOLS,TextCols
		move.b	#TEXTROWS,TextRows
		clr.b	CursorCol
		clr.b	CursorRow
		clr.w	TextCurpos
		move.l	#$00020000,TextScr		; set virtual screen location

		bsr		SetCursorColor
		bsr		SetCursorImage

		lea	$FFDC0000,A6	; I/O base

		; Initialize random number generator

		clr.w	$0C06(a6)				; select stream #0
		move.l	#$88888888,$0C08(a6)	; set initial m_z
		move.l	#$01234567,$0C0C(a6)	; set initial m_w

		bsr		BootClearScreen		
		move.w	#$A2A2,leds			; diagnostics
		
		bsr		DrawLines
		bsr		TestBlitter

		bsr		BootCopyFont
		move.w	#$A3A3,leds			; diagnostics

		move.w	#WHITE,fgcolor		; set text colors
		move.w	#DARK_BLUE,bkcolor

		; Write startup message to screen

		lea		msg_start,a0
		moveq	#0,d1					; xpos
		moveq	#0,d2					; ypos
		bsr		DispStringAt
		move.w	#$A4A4,leds			; diagnostics

		lea		j1,a3
		bra		ramtest
j1:
		bra		j1

CRLF:
		move.l	d1,-(a7)
		move.b	#'\r',d1
		jsr		DisplayChar
		move.b	#'\n',d1
		jsr		DisplayChar
		move.l	(a7)+,d1
		rts

;------------------------------------------------------------------------------
; Calculate screen memory location from CursorRow,CursorCol.
; Destroys d0,d2,a0
;------------------------------------------------------------------------------
;
CalcScreenLoc:
		move.b	CursorRow,d0		; compute screen location
		andi.w	#0x7f,d0
		move.b	TextCols,d2
		ext.w	d2
		mulu.w	d2,d0
		move.b	CursorCol,d2
		andi.w	#0xff,d2
		add.w	d2,d0
		move.w	d0,TextCurpos
		add.l	TextScr,d0
		move.l	d0,a0				; a0 = screen location
		rts

;------------------------------------------------------------------------------
; Display a character on the screen
; d1.b = char to display
;------------------------------------------------------------------------------
;
DisplayChar:
		cmpi.b	#'\r',d1			; carriage return ?
		bne.s	dccr
		clr.b	CursorCol			; just set cursor column to zero on a CR
		rts
dccr:
		cmpi.b	#0x91,d1			; cursor right ?
		bne.s   dcx6
		cmpi.b	#79,CursorCol
		beq.s	dcx7
		addi.b	#1,CursorCol
		bra		DispCursor
dcx7:
		rts
dcx6:
		cmpi.b	#0x90,d1			; cursor up ?
		bne.s	dcx8
		cmpi.b	#0,CursorRow
		beq.s	dcx7
		subi.b	#1,CursorRow
		bra		DispCursor
dcx8:
		cmpi.b	#0x93,d1			; cursor left?
		bne.s	dcx9
		cmpi.b	#0,CursorCol
		beq.s	dcx7
		subi.b	#1,CursorCol
		bra		DispCursor
dcx9:
		cmpi.b	#0x92,d1			; cursor down ?
		bne		dcx10
		cmpi.b	#63,CursorRow
		beq		dcx7
		addi.w	#1,CursorRow
		bra		DispCursor
dcx10:
		cmpi.b	#0x94,d1			; cursor home ?
		bne.s	dcx11
		cmpi.b	#0,CursorCol
		beq.s	dcx12
		clr.b	CursorCol
		bra		DispCursor
dcx12:
		clr.b	CursorRow
		bra		DispCursor
dcx11:
		movem.l	d0/d1/d2/a0,-(a7)
		cmpi.b	#0x99,d1			; delete ?
		bne.s	dcx13
		bsr		CalcScreenLoc
		move.b	CursorCol,d0
		bra.s	dcx5
dcx13:
		cmpi.b	#CTRLH,d1			; backspace ?
		bne.s   dcx3
		cmpi.b	#0,CursorCol
		beq.s   dcx4
		subi.b	#1,CursorCol
		bsr		CalcScreenLoc		; a0 = screen location
		move.b	CursorCol,d0
dcx5:
		move.b	1(a0),(a0)+
		addi.b	#1,d0
		cmp.b	TextCols,d0
		blo.s	dcx5
		move.b	#32,d0
		move.b	d0,-1(a0)
		bra.s	dcx4
dcx3:
		cmpi.b	#'\n',d1		; linefeed ?
		beq.s	dclf

		bsr		CalcScreenLoc	; a0 = screen location
		;bsr		AsciiToScreen	; convert ascii char to screen char
		move.b	d1,(a0)
		move.b	d1,d0
		ext.w	d0
		bsr		DispChar
		bsr		IncCursorPos
		bsr		DispCursor
		movem.l	(a7)+,d0/d1/d2/a0
		rts
dclf:
		bsr		IncCursorRow
		bsr		DispCursor
dcx4:
		movem.l	(a7)+,d0/d1/d2/a0		; get back a0
		rts

;------------------------------------------------------------------------------
; Increment the cursor position, scroll the screen if needed.
;------------------------------------------------------------------------------
;
IncCursorPos:
		addi.w	#1,TextCurpos
		addi.b	#1,CursorCol
		move.b	TextCols,d0
		cmp.b	CursorCol,d0
		bhs.s	icc1
		clr.b	CursorCol
IncCursorRow:
		addi.b	#1,CursorRow
		move.b	TextRows,d0
		cmp.b	CursorRow,d0
		bhi.s	icc1
		move.b	TextRows,d0
		move.b	d0,CursorRow		; in case CursorRow is way over
		subi.b	#1,CursorRow
		ext.w	d0
		asl.w	#1,d0
		sub.w	d0,TextCurpos
		bsr		ScrollUp
icc1:
		rts

;------------------------------------------------------------------------------
; Display a string on the screen.
;------------------------------------------------------------------------------
;
DisplayString:
		movem.l	d0/d1/a1,-(a7)
dspj1:
		clr.l	d1				; clear upper bits of d1
		move.b	(a1)+,d1		; move string char into d1
		cmpi.b	#0,d1			; is it end of string ?
		beq		dsret			
		bsr		DisplayChar		; display character
		bra		dspj1			; go back for next character
dsret:
		movem.l	(a7)+,d0/d1/a1
		rts

DisplayStringCRLF:
		bsr		DisplayString
		bra		CRLF

;------------------------------------------------------------------------------
; Display a string on the screen. Stop at 255 chars, or NULL or D1.W
;------------------------------------------------------------------------------
;
DisplayString1:
		movem.l	d0/d1/a1,-(a7)
		andi.w	#255,d1			; max 255 chars
		move.l	d1,d0
dspj11:
		move.b	(a1)+,d1		; move string char into d1
		cmpi.b	#0,d1			; is it end of string ?
		beq		dsret1			
		bsr		DisplayChar		; display character
		dbeq	d0,dspj11		; go back for next character
dsret1:
		movem.l	(a7)+,d0/d1/a1
		rts

;------------------------------------------------------------------------------
; Display a string on the screen. Stop at 255 chars, or NULL or D1.W
; end string with CR,LF
;------------------------------------------------------------------------------
;
DisplayString0:
		bsr		DisplayString1
		bra		CRLF

;------------------------------------------------------------------------------
; Dispatch cursor functions
;------------------------------------------------------------------------------
;
Cursor1:
		cmpi.w	#0x00ff,d1
		beq		GetCursorPos
		cmpi.w	#0xFF00,d1
		beq		SetCursorPos
		jsr		ClearScreen
		rts

;------------------------------------------------------------------------------
; Get the cursor position.
; d1.b0 = row
; d1.b1 = col
;------------------------------------------------------------------------------
;
GetCursorPos:
		move.b	CursorCol,d1
		asl.w	#8,d1
		move.b	CursorRow,d1
		rts

;------------------------------------------------------------------------------
; Set the position of the cursor, update the linear screen pointer.
; d1.b0 = row
; d1.b1 = col
;------------------------------------------------------------------------------
;
SetCursorPos:
		movem.l	d1/d2,-(a7)
		move.b	d1,CursorRow
		lsr.w	#8,d1
		move.b	d1,CursorCol
		move.b	CursorRow,d1
		ext.w	d1
		move.b	TextCols,d2
		ext.w	d2
		mulu.w	d2,d1
		move.b	CursorCol,d2
		add.w	d2,d1
		move.w	d1,TextCurpos
scp1:
		movem.l	(a7)+,d1/d2
		rts


;------------------------------------------------------------------------------
; clear screen	
;
; Trashes:
;	a0,d0,d1
;------------------------------------------------------------------------------

BootClearScreen:
		move.l	#VDGBUF,A0
		moveq	#DARK_BLUE,D0			; dark blue
		move.l	#320*256,D1				; number of pixels
.loop1:
		move.w	d0,(a0)+				; store it to the screen
		sub.l	#1,d1					; can't use dbra here
		bne.s	.loop1
		rts

;------------------------------------------------------------------------------
; copy font to VDG ram
;
; Trashes:
;	a0,a1,d0,d1
;------------------------------------------------------------------------------

BootCopyFont:
		move.w	#$0707,fntsz		; set font size
		lea		font8,a0
		move.l	#8*512,d1			; 512 chars * 8 bytes per char
		move.l	#$FF8B8000,a1		; font table address
		moveq	#0,d0				; zero out high order bits
cpyfnt:
		move.b	(a0)+,d0			; get a byte
		move.w	d0,(a1)+			; store in font table
		dbra	d1,cpyfnt
		rts

;------------------------------------------------------------------------------
; Parameters:
;	d0.w		character to display
;	d1.w		x position
;	d2.w		y position
; Trashes:
;	a6
;------------------------------------------------------------------------------

DispCharAt:
		move.l	#VDGREG,a6
		swap	d0						; save off d0 low
.0001:									; wait for character que to empty
		move.w	$42C(a6),d0			; read character queue index into d0
		cmp.w	#28,d0					; allow up 28 entries to be in progress
		bhs.s	.0001					; branch if too many chars queued
		swap	d0						; get back d0 low
		move.w	d0,$420(a6)			; set char code
		move.w	fgcolor,$422(a6)		; set fg color
		move.w	bkcolor,$424(a6)		; set bk color
		move.w	d1,$426(a6)			; set x pos
		move.w	d2,$428(a6)			; set y pos
		move.w	#$0707,$42A(a6)		; set font x,y extent
		move.w	#0,$42E(a6)			; pulse character queue write signal
		rts

;------------------------------------------------------------------------------
; Parameters:
;	d0.w		character to display
;------------------------------------------------------------------------------

DispChar:
		movem.l	d1/a6,-(a7)
		move.l	#VDGREG,a6
		swap	d0					; save off d0 low
.0001:								; wait for character que to empty
		move.w	$42C(a6),d0			; read character queue index into d0
		cmp.w	#28,d0				; allow up 28 entries to be in progress
		bhs.s	.0001				; branch if too many chars queued
		swap	d0					; get back d0 low
		move.w	d0,$420(a6)			; set char code
		move.w	fgcolor,$422(a6)	; set fg color
		move.w	bkcolor,$424(a6)	; set bk color
		move.b	CursorCol,d1
		ext.w	d1
		asl.w	#3,d1
		move.w	d1,$426(a6)			; set x pos
		move.b	CursorRow,d1
		ext.w	d1
		asl.w	#3,d1
		move.w	d1,$428(a6)			; set y pos
		move.w	#$0707,$42A(a6)		; set font x,y extent
		move.w	#0,$42E(a6)			; pulse character queue write signal
		movem.l	(a7)+,d1/a6
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DispCursor:
		movem.l	d1/a6,-(a7)
		move.l	#VDGREG,a6
		move.w	#$0A0A,VDG_CURSZ(a6)
		move.b	CursorCol,d1
		ext.w	d1
		asl.w	#3,d1
		sub.w	#1,d1
		move.w	d1,VDG_CURX(a6)
		move.b	CursorRow,d1
		ext.w	d1
		asl.w	#3,d1
		sub.w	#1,d1
		move.w	d1,VDG_CURY(a6)
		movem.l	(a7)+,d1/a6
		rts

;------------------------------------------------------------------------------
; Cursor Color
;
;	fffff-irrrgggbbb
;	  |   | |  |  |
;     |   | |  |  +- blue
;	  |   | |  +---- green
;     |   | +------- red
;     |   +--------- invert video (rgb ignored)
;     +------------- flash rate
;					 1xxxx = no flash
;                    00001 = 1/8 vsync (7.5 Hz)
;				     00010 = 1/16 vsync (3.75 Hz)
;                    00100 = 1/32 vsync (1.875 Hz)
;------------------------------------------------------------------------------

SetCursorColor:
		move.l  a6,-(a7)
		move.l	#VDGREG,a6
		move.w	#%0111111111111111,VDG_CURCLR(a6)
		move.w	#%00100,VDG_CURFLSH(a6)
		move.l	(a7)+,a6
		rts
		
;------------------------------------------------------------------------------
; Cursor Image
; Cursor may be up to 16x16 pixels.
;------------------------------------------------------------------------------

SetCursorImage:
		movem.l	d1/a0/a6,-(a7)
		lea		CursorImage,a0
		move.l	#VDGREG+VDG_CURIMG,a6
		moveq	#15,d1
.0001:
		move.w	(a0)+,(a6)+
		dbra	d1,.0001
		movem.l	(a7)+,d1/a0/a6
		rts

	align	2
CursorImage:
	dc.w	%1111111111
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000000001
	dc.w	%1000110001
	dc.w	%1111111111
	dc.w	%0000000000
	dc.w	%0000000000
	dc.w	%0000000000
	dc.w	%0000000000
	dc.w	%0000000000
	dc.w	%0000000000

;------------------------------------------------------------------------------
; Parameters:
;	a0			pointer to string
;	d1.w		x position
;	d2.w		y position
; Returns:
;	a0			points to byte after NULL character
;	d1.w		updated x position
; Trashes:
;	d0,a6
;------------------------------------------------------------------------------

DispStringAt:
.0003:
		moveq	#0,d0					; zero out high order bits
		move.b	(a0)+,d0				; get character from string into d0
		beq.s	.0002					; end of string ?
		bsr		DispCharAt
		add.w	#8,d1					; increment xpos
		bra.s	.0003
.0002:
		rts

;------------------------------------------------------------------------------
; Display nybble in D1.B
;------------------------------------------------------------------------------
;
DisplayNybble:
		move.w	d1,-(a7)
		andi.b	#0xF,d1
		addi.b	#'0',d1
		cmpi.b	#'9',d1
		bls.s	dispnyb1
		addi.b	#7,d1
dispnyb1:
		bsr		DisplayChar
		move.w	(a7)+,d1
		rts

;------------------------------------------------------------------------------
; Display the byte in D1.B
;------------------------------------------------------------------------------
;
DisplayByte:
		move.w	d1,-(a7)
		ror.b	#4,d1
		bsr		DisplayNybble
		rol.b	#4,d1
		bsr		DisplayNybble
		move.w	(a7)+,d1
		rts

;------------------------------------------------------------------------------
; Display the 32 bit word in D1.L
;------------------------------------------------------------------------------
;
DisplayWord:
		rol.l	#8,d1
		bsr		DisplayByte
		rol.l	#8,d1
		bsr		DisplayByte
		rol.l	#8,d1
		bsr		DisplayByte
		rol.l	#8,d1
		bsr		DisplayByte
		rts

DisplayMem:
		move.b	#':',d1
		jsr		DisplayChar
		move.l	a0,d1
		jsr		DisplayWord
		moveq	#7,d2
dspmem1:
		move.b	#' ',d1
		jsr		DisplayChar
		move.b	(a0)+,d1
		jsr		DisplayByte
		dbra	d2,dspmem1
		jmp		CRLF

;==============================================================================
; Keyboard stuff
;
; KeyState2_
; 876543210
; ||||||||+ = shift
; |||||||+- = alt
; ||||||+-- = control
; |||||+--- = numlock
; ||||+---- = capslock
; |||+----- = scrolllock
; ||+------ =
; |+------- = 
; +-------- = extended
;
;==============================================================================

_KeybdGetStatus:
		move.b	KEYBD+1,d1
		rts

; Get the scancode from the keyboard port
;
_KeybdGetScancode:
		moveq	#0,d1
		move.b	KEYBD,d1				; get the scan code
		move.b	#0,KEYBD+1				; clear receive register
		rts

; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
KeybdRecvByte:
		move.l	d3,-(a7)
		move.w	#100,d3		; wait up to 1s
.0003:
		bsr		_KeybdGetStatus	; wait for response from keyboard
		tst.b	d1
		bmi		.0004		; is input buffer full ? yes, branch
		bsr		Wait10ms		; wait a bit
		dbra	d3,.0003	; go back and try again
		move.l	(a7)+,d3
		moveq	#-1,d1			; return -1
		rts
.0004:
		bsr		_KeybdGetScancode
		move.l	(a7)+,d3
		rts


; Wait until the keyboard transmit is complete
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitTx:
		movem.l	d2/d3,-(a7)
		moveq	#100,d3		; wait a max of 1s
.0001:
		bsr		_KeybdGetStatus
		btst	#6,d1		; check for transmit complete bit
		bne	    .0002		; branch if bit set
		bsr		Wait10ms		; delay a little bit
		dbra	d3,.0001	; go back and try again
		movem.l	(a7)+,d2/d3
		moveq	#-1,d1		; return -1
		rts
.0002:
		movem.l	(a7)+,d2/d3
		moveq	#0,d1		; return 0
		rts


;------------------------------------------------------------------------------
; get key pending status into d1.b
;------------------------------------------------------------------------------
;
CheckForKey:
		move.b	KEYBD+1,d1
		bpl.s	cfk1
		move.b	#1,d1
		rts
cfk1:
		clr.b	d1
		rts

GetKey:
		bsr		KeybdGetCharWait
		cmpi.b	#0,KeybdEcho	; is keyboard echo on ?
		beq.s	gk1
		cmpi.b	#'\r',d1		; convert CR keystroke into CRLF
		beq		CRLF
		bsr		DisplayChar
gk1:
		rts


KeybdGetCharNoWait:
		clr.b	KeybdWaitFlag
		bra		KeybdGetChar

KeybdGetCharWait:
		move.b	#-1,KeybdWaitFlag

KeybdGetChar:
		movem.l	d2/d3/a0,-(a7)
.0003:
		bsr		_KeybdGetStatus			; check keyboard status for key available
		bmi		.0006					; yes, go process
		tst.b	KeybdWaitFlag			; are we willing to wait for a key ?
		bmi		.0003					; yes, branch back
		movem.l	(a7)+,d2/d3/a0
		moveq	#-1,d1					; flag no char available
		rts
.0006:
		bsr		_KeybdGetScancode
.0001:
		move.w	#1,leds
		cmp.b	#SC_KEYUP,d1
		beq		.doKeyup
		cmp.b	#SC_EXTEND,d1
		beq		.doExtend
		cmp.b	#SC_CTRL,d1
		beq		.doCtrl
		cmp.b	#SC_LSHIFT,d1
		beq		.doShift
		cmp.b	#SC_RSHIFT,d1
		beq		.doShift
		cmp.b	#SC_NUMLOCK,d1
		beq		.doNumLock
		cmp.b	#SC_CAPSLOCK,d1
		beq		.doCapsLock
		cmp.b	#SC_SCROLLLOCK,d1
		beq		.doScrollLock
		cmp.b   #SC_ALT,d1
		beq     .doAlt
		move.b	_KeyState1,d2			; check key up/down
		move.b	#0,_KeyState1			; clear keyup status
		tst.b	d2
		bne	    .0003					; ignore key up
		cmp.b   #SC_TAB,d1
		beq     .doTab
.0013:
		move.b	_KeyState2,d2
		bpl		.0010					; is it extended code ?
		and.b	#$7F,d2					; clear extended bit
		move.b	d2,_KeyState2
		move.b	#0,_KeyState1			; clear keyup
		lea		_keybdExtendedCodes,a0
		move.b	(a0,d1.w),d1
		bra		.0008
.0010:
		btst	#2,d2					; is it CTRL code ?
		beq		.0009
		and.w	#$7F,d1
		lea		_keybdControlCodes,a0
		move.b	(a0,d1.w),d1
		bra		.0008
.0009:
		btst	#0,d2					; is it shift down ?
		beq  	.0007
		lea		_shiftedScanCodes,a0
		move.b	(a0,d1.w),d1
		bra		.0008
.0007:
		lea		_unshiftedScanCodes,a0
		move.b	(a0,d1.w),d1
		move.w	#$0202,leds
.0008:
		move.w	#$0303,leds
		movem.l	(a7)+,d2/d3/a0
		rts
.doKeyup:
		move.b	#-1,_KeyState1
		bra		.0003
.doExtend:
		or.b	#$80,_KeyState2
		bra		.0003
.doCtrl:
		move.b	_KeyState1,d1
		clr.b	_KeyState1
		tst.b	d1
		bpl.s	.0004
		bclr	#2,_KeyState2
		bra		.0003
.0004:
		bset	#2,_KeyState2
		bra		.0003
.doAlt:
		move.b	_KeyState1,d1
		clr.b	_KeyState1
		tst.b	d1
		bpl		.0011
		bclr	#1,_KeyState2
		bra		.0003
.0011:
		bset	#1,_KeyState2
		bra		.0003
.doTab:
		move.l	d1,-(a7)
	    move.b  _KeyState2,d1
	    btst	#0,d1                 ; is ALT down ?
	    beq     .0012
;    	inc     _iof_switch
	    move.l	(a7)+,d1
	    bra     .0003
.0012:
	    move.l	(a7)+,d1
	    bra     .0013
.doShift:
		move.b	_KeyState1,d1
		clr.b	_KeyState1
		tst.b	d1
		bpl.s	.0005
		bclr	#0,_KeyState2
		bra		.0003
.0005:
		bset	#0,_KeyState2
		bra		.0003
.doNumLock:
		bchg	#4,_KeyState2
		bsr		KeybdSetLEDStatus
		bra		.0003
.doCapsLock:
		bchg	#5,_KeyState2
		bsr		KeybdSetLEDStatus
		bra		.0003
.doScrollLock:
		bchg	#6,_KeyState2
		bsr		KeybdSetLEDStatus
		bra		.0003

KeybdSetLEDStatus:
		movem.l	d2/d3,-(a7)
		clr.b	KeybdLEDs
		btst	#4,_KeyState2
		beq.s	.0002
		move.b	#2,KeybdLEDs
.0002:
		btst	#5,_KeyState2
		beq.s	.0003
		bset	#2,KeybdLEDs
.0003:
		btst	#6,_KeyState2
		beq.s	.0004
		bset	#0,KeybdLEDs
.0004:
		move.b	#$ED,d1
		bsr		KeybdSendByte
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
		tst.b	d1
		bmi		.0001
		cmp		#$FA,d1
		move.b	KeybdLEDs,d1
		bsr		KeybdSendByte
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
.0001:
		movem.l	(a7)+,d2/d3
		rts

KeybdSendByte:
		move.b	d1,KEYBD
		rts
	
Wait10ms:
		move.l	d3,-(a7)
		move.l	#1000,d3
.0001:
		dbra	d3,.0001
		move.l	(a7)+,d3
		rts


;--------------------------------------------------------------------------
; PS2 scan codes to ascii conversion tables.
;--------------------------------------------------------------------------
;
_unshiftedScanCodes:
	dc.b	$2e,$a9,$2e,$a5,$a3,$a1,$a2,$ac
	dc.b	$2e,$aa,$a8,$a6,$a4,$09,$60,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$71,$31,$2e
	dc.b	$2e,$2e,$7a,$73,$61,$77,$32,$2e
	dc.b	$2e,$63,$78,$64,$65,$34,$33,$2e
	dc.b	$2e,$20,$76,$66,$74,$72,$35,$2e
	dc.b	$2e,$6e,$62,$68,$67,$79,$36,$2e
	dc.b	$2e,$2e,$6d,$6a,$75,$37,$38,$2e
	dc.b	$2e,$2c,$6b,$69,$6f,$30,$39,$2e
	dc.b	$2e,$2e,$2f,$6c,$3b,$70,$2d,$2e
	dc.b	$2e,$2e,$27,$2e,$5b,$3d,$2e,$2e
	dc.b	$ad,$2e,$0d,$5d,$2e,$5c,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	dc.b	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	dc.b	$98,$7f,$92,$2e,$91,$90,$1b,$af
	dc.b	$ab,$2e,$97,$2e,$2e,$96,$ae,$2e

	dc.b	$2e,$2e,$2e,$a7,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$fa,$2e,$2e,$2e,$2e,$2e

_shiftedScanCodes:
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$51,$21,$2e
	dc.b	$2e,$2e,$5a,$53,$41,$57,$40,$2e
	dc.b	$2e,$43,$58,$44,$45,$24,$23,$2e
	dc.b	$2e,$20,$56,$46,$54,$52,$25,$2e
	dc.b	$2e,$4e,$42,$48,$47,$59,$5e,$2e
	dc.b	$2e,$2e,$4d,$4a,$55,$26,$2a,$2e
	dc.b	$2e,$3c,$4b,$49,$4f,$29,$28,$2e
	dc.b	$2e,$3e,$3f,$4c,$3a,$50,$5f,$2e
	dc.b	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	dc.b	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

; control
_keybdControlCodes:
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$11,$21,$2e
	dc.b	$2e,$2e,$1a,$13,$01,$17,$40,$2e
	dc.b	$2e,$03,$18,$04,$05,$24,$23,$2e
	dc.b	$2e,$20,$16,$06,$14,$12,$25,$2e
	dc.b	$2e,$0e,$02,$08,$07,$19,$5e,$2e
	dc.b	$2e,$2e,$0d,$0a,$15,$26,$2a,$2e
	dc.b	$2e,$3c,$0b,$09,$0f,$29,$28,$2e
	dc.b	$2e,$3e,$3f,$0c,$3a,$10,$5f,$2e
	dc.b	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	dc.b	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

_keybdExtendedCodes:
	dc.b	$2e,$2e,$2e,$2e,$a3,$a1,$a2,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	dc.b	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	dc.b	$98,$99,$92,$2e,$91,$90,$2e,$2e
	dc.b	$2e,$2e,$97,$2e,$2e,$96,$2e,$2e


;==============================================================================
; Monitor
;==============================================================================
;
StartMon:
Monitor:
;	lea		STACK,a7		; reset the stack pointer
		clr.b	KeybdEcho		; turn off keyboard echo
PromptLn:
		bsr		CRLF
		move.b	#'$',d1
		bsr		DisplayChar

; Get characters until a CR is keyed
;
Prompt3:
		bsr		GetKey
		cmpi.b	#CR,d1
		beq.s	Prompt1
		bsr		DisplayChar
		bra.s	Prompt3

; Process the screen line that the CR was keyed on
;
Prompt1:
		clr.b	CursorCol		; go back to the start of the line
		bsr		CalcScreenLoc	; a0 = screen memory location
		move.b	(a0)+,d1
		;bsr		ScreenToAscii
		cmpi.b	#'$',d1			; skip over '$' prompt character
		bne.s	Prompt2
		move.b	(a0)+,d1
		;bsr		ScreenToAscii
	
; Dispatch based on command character
;
Prompt2:
		cmpi.b	#':',d1			; $: - edit memory
		beq		EditMem
		cmpi.b	#'D',d1			; $D - dump memory
		beq		DumpMem
		cmpi.b	#'F',d1
		beq		FillMem
		cmpi.b	#'B',d1			; $B - start tiny basic
		beq		START
		cmpi.b	#'J',d1			; $J - execute code
		beq		ExecuteCode
		cmpi.b	#'L',d1			; $L - load S19 file
		beq		LoadS19
		cmpi.b	#'?',d1			; $? - display help
		beq		DisplayHelp
		cmpi.b	#'C',d1			; $C - clear screen
		beq		TestCLS
		bra		Monitor

TestCLS:
		move.b	(a0)+,d1
		cmpi.b	#'L',d1
		bne		Monitor
		move.b	(a0)+,d1
		cmpi.b	#'S',d1
		bne		Monitor
		bsr		ClearScreen
		bra		Monitor
	
DisplayHelp:
		lea		HelpMsg,a1
		jsr		DisplayString
		bra		Monitor

HelpMsg:
		dc.b	"? = Display help",CR,LF
		dc.b	"CLS = clear screen",CR,LF
		dc.b	": = Edit memory bytes",CR,LF
		dc.b	"F = Fill memory",CR,LF
		dc.b	"L = Load S19 file",CR,LF
		dc.b	"D = Dump memory",CR,LF
		dc.b	"B = start tiny basic",CR,LF
		dc.b	"J = Jump to code",CR,LF,0
		even

;------------------------------------------------------------------------------
; Fill memory
; FB = fill bytes		FB 00000010 100 FF	; fill starting at 10 for 256 bytes
; FW = fill words
; FL = fill longs
; F = fill bytes
;------------------------------------------------------------------------------
;
FillMem:
		move.b	(a0)+,d1
		;bsr		ScreenToAscii
		move.b	d1,d4			; d4 = fill size
		bsr		ignBlanks
		bsr		GetHexNumber
		move.l	d1,a1			; a1 = start
		bsr		ignBlanks
		bsr		GetHexNumber
		move.l	d1,d3			; d3 = count
		bsr		ignBlanks
		bsr		GetHexNumber	; fill value
		cmpi.b	#'L',d4
		bne		fmem1
fmemL:
		move.l	d1,(a1)+
		dbra	d3,fmemL
		bra		Monitor
fmem1
		cmpi.b	#'W',d4
		bne		fmemB
fmemW:
		move.w	d1,(a1)+
		dbra	d3,fmemW
		bra		Monitor
fmemB:
		move.b	d1,(a1)+
		dbra	d3,fmemB
		bra		Monitor

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
ignBlanks:
		move.b	(a0)+,d1
		cmpi.b	#' ',d1
		beq		ignBlanks
		subq	#1,a0
		rts

;------------------------------------------------------------------------------
; Edit memory byte.
;------------------------------------------------------------------------------
;
EditMem:
		bsr		ignBlanks
		bsr		GetHexNumber
		move.l	d1,a1
edtmem1:
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bsr		ignBlanks
		bsr		GetHexNumber
		move.b	d1,(a1)+
		bra		Monitor

;------------------------------------------------------------------------------
; Execute code at the specified address.
;------------------------------------------------------------------------------
;
ExecuteCode:
		bsr		ignBlanks
		bsr		GetHexNumber
		move.l	d1,a0
		jsr		(a0)
		bra     Monitor

;------------------------------------------------------------------------------
; Do a memory dump of the requested location.
;------------------------------------------------------------------------------
;
DumpMem:
		bsr		ignBlanks
		bsr		GetHexNumber
DumpMem1:
		move.l	d1,a0
		jsr		CRLF
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bsr		DisplayMem
		bra		Monitor

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
;------------------------------------------------------------------------------
;
GetHexNumber:
		movem.l	d0/d2,-(a7)
		clr.l	d2
		moveq	#7,d0
gthxn2:
		move.b	(a0)+,d1
		bsr		AsciiToHexNybble
		cmp.b	#0xff,d1
		beq		gthxn1
		lsl.l	#4,d2
		andi.l	#0x0f,d1
		or.l	d1,d2
		dbra	d0,gthxn2
gthxn1:
		move.l	d2,d1
		movem.l	(a7)+,d0/d2
		rts	

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' tr 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
		cmpi.b	#'0',d1
		blo.s	gthx3
		cmpi.b	#'9',d1
		bhi.s	gthx5
		subi.b	#'0',d1
		rts
gthx5:
		cmpi.b	#'A',d1
		blo.s	gthx3
		cmpi.b	#'F',d1
		bhi.s	gthx6
		subi.b	#'A',d1
		addi.b	#10,d1
		rts
gthx6:
		cmpi.b	#'a',d1
		blo.s	gthx3
		cmpi.b	#'f',d1
		bhi.s	gthx3
		subi.b	#'a',d1
		addi.b	#10,d1
		rts
gthx3:
		moveq	#-1,d1		; not a hex number
		rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; The fast way to clear the screen. Uses the blitter.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

ClearScreen:
		lea		VDGREG,a5
.0003:								
		move.w	$4AC(a5),d0			; get done status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0003				; branch if not done
		move.l	#320*256,$4BC(a5)		; set transfer count  pixels
		move.w	#DARK_BLUE,$4A8(a5)	; set color dark blue
		move.l	#0,$498(a5)			; set destination address
		move.l	#319,$4A4(a5)		; set destination width
		move.l	#0,$49C(a5)			; set dst modulo
		move.w	#%1000000010000000,$4AC(a5)		; enable channel D, start transfer
		rts

ScrollUp:
		movem.l	d0/a5,-(a7)
		lea		VDGREG,a5
.0003:								
		move.w	$4AC(a5),d0			; get done status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0003				; branch if not done
		move.l	#320*248,$4BC(a5)		; set transfer count  pixels
		; Channel A
		move.l	#320*248,$4B0(a5)	; set source transfer count pixels
		move.l	#320*8,$480(a5)		; set source bitmap address (address in graphics mem)
		move.l	#0,$484(a5)			; set src modulo
		; Channel D
		move.l	#320*248,$4BC(a5)	; set destination transfer count pixels
		move.l	#0,$498(a5)			; set destination address
		move.l	#0,$49C(a5)			; set dst modulo

		move.l	#319,$4A0(a5)		; set source width
		move.l	#319,$4A4(a5)		; set destination width
		move.w	#$11,$4AE(a5)		; set op A ($11 = copy A)
		move.w	#%1000000010000010,$4AC(a5)		; enable channel A,C,D, start transfer
		movem.l	(a7)+,d0/a5

BlankLastLine:
		movem.l	d0/a5,-(a7)
		; Channel D
		lea		VDGREG,a5
.0003:								
		move.w	$4AC(a5),d0			; get done status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0003				; branch if not done
		move.l	#320*8,$4BC(a5)		; set destination transfer count pixels
		move.l	#320*248,$498(a5)	; set destination address
		move.l	#0,$49C(a5)			; set dst modulo
		move.l	#319,$4A4(a5)		; set destination width
		move.w	#DARK_BLUE,$4A8(a5)	; set color dark blue
		move.w	#%1000000010000000,$4AC(a5)		; enable channel D, start transfer
		movem.l	(a7)+,d0/a5
		rts

;==============================================================================
; Load an S19 format file
;==============================================================================
;
LoadS19:
	bra		ProcessRec
NextRec:
	bsr		sGetChar
	cmpi.b	#LF,d0
	bne		NextRec
ProcessRec
	bsr		sGetChar
	move.b	d0,d4
	cmpi.b	#26,d4		; CTRL-Z ?
	beq		Monitor
	cmpi.b	#'S',d4
	bne		NextRec
	bsr		sGetChar
	move.b	d0,d4
	cmpi.b	#'0',d4
	blo		NextRec
	cmpi.b	#'9',d4		; d4 = record type
	bhi		NextRec
	bsr		sGetChar
	bsr		AsciiToHexNybble
	move.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.b	#4,d2
	or.b	d2,d1		; d1 = byte count
	move.b	d1,d3		; d3 = byte count
	cmpi.b	#'0',d4		; manufacturer ID record, ignore
	beq		NextRec
	cmpi.b	#'1',d4
	beq		ProcessS1
	cmpi.b	#'2',d4
	beq		ProcessS2
	cmpi.b	#'3',d4
	beq		ProcessS3
	cmpi.b	#'5',d4		; record count record, ignore
	beq		NextRec
	cmpi.b	#'7',d4
	beq		ProcessS7
	cmpi.b	#'8',d4
	beq		ProcessS8
	cmpi.b	#'9',d4
	beq		ProcessS9
	bra		NextRec

pcssxa
	andi.w	#0xff,d3
	subi.w	#1,d3			; one less for dbra
pcss1a
	clr.l	d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	move.b	d2,(a1)+
	dbra	d3,pcss1a
; Get the checksum byte
	clr.l	d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bra		NextRec

ProcessS1:
	bsr		S19Get16BitAddress
	bra		pcssxa
ProcessS2:
	bsr		S19Get24BitAddress
	bra		pcssxa
ProcessS3:
	bsr		S19Get32BitAddress
	bra		pcssxa
ProcessS7:
	bsr		S19Get32BitAddress
	move.l	a1,S19StartAddress
	bra		Monitor
ProcessS8:
	bsr		S19Get24BitAddress
	move.l	a1,S19StartAddress
	bra		Monitor
ProcessS9:
	bsr		S19Get16BitAddress
	move.l	a1,S19StartAddress
	bra		Monitor

S19Get16BitAddress:
	clr.l	d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	move.b	d1,d2
	bra		S1932b

S19Get24BitAddress:
	clr.l	d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	move.b	d1,d2
	bra		S1932a

S19Get32BitAddress:
	clr.l	d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	move.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
S1932a:
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
S1932b:
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	bsr		sGetChar
	bsr		AsciiToHexNybble
	lsl.l	#4,d2
	or.b	d1,d2
	clr.l	d4
	move.l	d2,a1
	rts

;------------------------------------------------------------------------------
; Get a character from auxillary input, checking the keyboard status for a
; CTRL-C
;------------------------------------------------------------------------------
;
sGetChar:
	bsr		CheckForKey
	beq		sgc1
	bsr		GetKey
	cmpi.b	#CTRLC,d1
	beq		Monitor
sgc1:
	bsr		AUXIN
	beq		sGetChar
	move.b	d0,d1
	rts

;==============================================================================
;==============================================================================

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
DisplayHexNumber:
		move.w	#$A6A6,leds		; diagnostics
		move.l	#VDGREG,a6
		move.w	#7,d2		; number-1 of digits to display
disphnum1:
		move.b	d1,d0		; get digit into d0.b
		andi.w	#$0f,d0
		cmpi.w	#$09,d0
		bls.s	disphnum2
		addi.w	#7,d0
disphnum2:
		addi.w	#$30,d0	; convert to display char
		move.w	d2,d3		; char count into d3
		asl.w	#3,d3		; scale * 8
disphnum3:
		move.w	$42C(a6),d4			; read character queue index into d4
		cmp.w	#28,d4					; allow up 28 entries to be in progress
		bhs.s	disphnum3				; branch if too many chars queued
		ext.w	d0						; zero out high order bits
		move.w	d0,$420(a6)			; set char code
		move.w	#WHITE,$422(a6)		; set fg color
		move.w	#DARK_BLUE,$424(a6)	; set bk color
		move.w	d3,$426(a6)			; set x pos
		move.w	#8,$428(a6)			; set y pos
		move.w	#$0707,$42A(a6)		; set font x,y extent
		move.w	#0,$42E(a6)			; pulse character queue write signal
		ror.l	#4,d1					; rot to next digit
		dbeq	d2,disphnum1
		jmp		(a5)

;===============================================================================
;    Perform ram test. (Uses checkerboard testing).
; 
;    Return address must be stored in a3 since the stack cannot be used (it
; would get overwritten in test). Note this routine uses no ram at all.
;===============================================================================
ramtest:
		move.w	#$A5A5,leds		; diagnostics
        movea.l #$30000,a0
        move.l #$aaaa5555,d0
;-----------------------------------------------------------
;   Write checkerboard pattern to ram then read it back to
; find the highest usable ram address (maybe). This address
; must be lower than the start of the rom (0xe00000).
;-----------------------------------------------------------
ramtest1:
        move.l 	d0,(a0)+
        move.l	a0,d1
        tst.w	d1
        bne.s	rmtst1
        lea		rmtst1,a5
        bra		DisplayHexNumber
rmtst1:
		move.w	#$A9A9,leds		; diagnostics
        cmpa.l 	#$5FFFC,a0
        bne.s 	ramtest1
        move.l	#0,d1
        bsr		CalcScreenLoc
        bra		DumpMem1

;------------------------------------------------------
;   Save maximum useable address for later comparison.
;------------------------------------------------------
ramtest6:
		move.w	#$A7A7,leds		; diagnostics
        movea.l a0,a2
        movea.l #$30000,a0
;--------------------------------------------
;   Read back checkerboard pattern from ram.
;--------------------------------------------
ramtest2:
        move.l  (a0)+,d5
        cmpa.l	a0,a2
        beq.s	ramtest3
        move.l	a0,d1
        tst.w	d1
        bne.s	rmtst2
        lea		rmtst2,a5
        bra		DisplayHexNumber
rmtst2:
        cmpi.l 	#$aaaa5555,d5
        beq.s 	ramtest2
        bne.s 	ramtest7
;---------------------------------------------------
;   The following section does the same test except
; with the checkerboard order switched around.
;---------------------------------------------------
ramtest3:                
		move.w	#$A8A8,leds		; diagnostics
        movea.l #$30000,a0
        move.l 	#$5555aaaa,d0
ramtest4:
        move.l 	d0,(a0)+
        move.l 	a0,d1
        tst.w	d1
        bne.s   rmtst3
        lea		rmtst3,a5
        bra		DisplayHexNumber
rmtst3:
        cmpa.l 	#$1FFFFFFC,a0
        bne.s 	ramtest4
ramtest8:
        movea.l a0,a2
        movea.l #$30000,a0
ramtest5:
        move.l 	(a0)+,d0
        cmpa.l	a0,a2
        beq.s	rmtst5
        move.l 	a0,d1
        tst.w	d1
        bne.s	rmtst4
        lea		rmtst4,a5
        bra		DisplayHexNumber
rmtst4:
        cmpi.l 	#$5555aaaa,d0
        beq.s 	ramtest5
        bne.s 	ramtest7
;---------------------------------------------------
;   Save last ram address in end of memory pointer.
;---------------------------------------------------
rmtst5:
        move.l a0,memend
;-----------------------------------
;   Create very first memory block.
;-----------------------------------
        suba.l 	#12,a0
        move.l 	a0,$0404
        move.l 	#$46524545,$0400
        move.l 	#$408,$408			; point back-link to self
        jmp 	(a3)
;----------------------------------
; Error in ram - go no farther.
;----------------------------------
ramtest7:
		jmp 	(a3)
        bra.s 	ramtest7

;===============================================================================
; Draw lines randomly on the screen.
;===============================================================================

DrawLines:
		lea		$FFDC0000,A6	; I/O base
		lea		VDGREG,a5
		move.l	#200000,d6		; repeat a few times
.0001:
		move.l	$0C00(a6),d0	; get 32 bit number
		move.w	d0,d1			; use bits 0 to 8 for y0
		swap	d0				; and bits 16 to 24 for x0
		and.w	#$FF,d0		; 0 to 511
		and.w	#$FF,d1		; 0 to 511
		clr.w	$0C04(a6)		; gen next number
		move.l	$0C00(a6),d2
		move.w	d2,d3
		swap	d2
		and.w	#$FF,d2		; 0 to 511
		and.w	#$FF,d3		; 0 to 511
		clr.w	$0C04(a6)		; gen next number
		move.l	$0C00(a6),d4
		and.w	#RGBMASK,d4		; 9/15 bits color
		clr.w	$0C04(a6)		; gen next number
.0002:
		move.w	$42C(a5),d7		; check # queued
		cmp.w	#28,d7			; more than 28 queued ?
		bhs.s	.0002			; too many, wait for queue to empty
		move.w	#1,$422(a5)		; raster op = COPY
		move.w	d4,$424(a5)		; set color
		move.w	d0,$426(a5)		; set x0
		move.w	d1,$428(a5)		; set y0
		move.w	d2,$430(a5)		; set x1
		move.w	d3,$432(a5)		; set y1
		move.w	#2,$42E(a5)		; pulse command queue (2 = draw line)
		sub.l	#1,d6
		bne		.0001			; go back and do more lines
		rts

;===============================================================================
; Test Blitter
;===============================================================================

TestBlitter:
		; puts a red rectangle on screen
		lea		VDGREG,a5
.0003:								
		move.w	$4AC(a5),d0			; get done status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0003				; branch if not done
		move.l	#7999,$4BC(a5)		; set transfer count 8000 pixels
		move.w	#RED,$4A8(a5)		; set color red
		move.l	#280,$498(a5)		; set destination address
		move.l	#39,$4A4(a5)		; set destination width
		move.l	#280,$49C(a5)		; set dst modulo
		move.w	#%1000000010000000,$4AC(a5)		; enable channel D, start transfer

		; makes a copy of the upper left corner of the screen
.0001:								
		move.w	$4AC(a5),d0			; get blit status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0001				; branch if not done
		; Channel A
		move.l	#999,$4B0(a5)		; set source transfer count 8000 pixels
		move.l	#0,$480(a5)			; set source bitmap address (address in graphics mem)
		move.l	#280,$484(a5)		; set src modulo
		; Channel C
		move.l	#999,$4B8(a5)		; set source transfer count 8000 pixels
		move.l	#0,$490(a5)			; set source bitmap address (address in graphics mem)
		move.l	#280,$494(a5)		; set src modulo
		; Channel D
		move.l	#7999,$4BC(a5)		; set destination transfer count 8000 pixels
		move.l	#240,$498(a5)		; set destination address
		move.l	#280,$49C(a5)		; set dst modulo
		
		move.l	#39,$4A0(a5)		; set source width
		move.l	#39,$4A4(a5)		; set destination width
		move.w	#$91,$4AE(a5)		; set op A|C	($11 = copy A)
		move.w	#%1000000010100010,$4AC(a5)		; enable channel A,C,D, start transfer
.0002:								
		move.w	$4AC(a5),d0			; get blit status
		btst	#13,d0				; bit 13 = done bit
		beq.s	.0002				; branch if not done
		rts

;===============================================================================
; Generic I2C routines
;===============================================================================

I2C_PREL	EQU		$0
I2C_PREH	EQU		$2
I2C_CTRL	EQU		$4
I2C_RXR		EQU		$6
I2C_TXR		EQU		$6
I2C_CMD		EQU		$8
I2C_STAT	EQU		$A

; i2c
i2c_setup:
		lea		I2C,a6				
		move.w	#19,I2C_PREL(a6)	; setup prescale for 400kHz clock
		move.w	#0,I2C_PREH(a6)
		lea		I2C2,a6				
		move.w	#19,I2C_PREL(a6)	; setup prescale for 400kHz clock
		move.w	#0,I2C_PREH(a6)
		rts

; Wait for I2C transfer to complete
;
; Parameters
; 	a6 - I2C controller base address

i2c_wait_tip:
		move.w	d0,-(a7)
.0001:					
		move.w	I2C_STAT(a6),d0		; wait for tip to clear
		btst	#1,d0
		bne.s	.0001
		move.w	(a7)+,d0
		rts

; Parameters
;	d0.w - data to transmit
;	d1.w - command value
;	a6	 - I2C controller base address
;
i2c_wr_cmd:
		move.w	d0,I2C_TXR(a6)
		move.w	d1,I2C_CMD(a6)
		bsr		i2c_wait_tip
		move.w	I2C_STAT(a6),d0
		rts

i2c_xmit1:
		move.w	d0,-(a7)
		move.w	#1,I2C_CTRL(a6)		; enable the core
		moveq	#$76,d0				; set slave address = %0111011
		move.w	#$90,d1				; set STA, WR
		bsr		i2c_wr_cmd
		bsr		i2c_wait_rx_nack
		move.w	(a7)+,d0
		move.w	#$50,d1				; set STO, WR
		bsr		i2c_wr_cmd
		bsr		i2c_wait_rx_nack

i2c_wait_rx_nack:
		move.w	d0,-(a7)
.0001:							
		move.w	I2C_STAT(a6),d0		; wait for RXack = 0
		btst	#7,d0
		bne.s	.0001
		move.w	(a7)+,d0
		rts

;===============================================================================
; Audio
;===============================================================================


audio_pll_config:
		moveq	#0,d0
		moveq	#$0E,d1
		bsr		audio_write_reg
		moveq	#2,d0
		lea		audio_tbl1,a0
		bsr		audio_write_reg6
		rts

audio_startup_config:
		rts

audio_init:
		bsr		audio_pll_config
		bsr		audio_startup_config
		rts

; d0.w = register number
; d1.w = data to write
		
audio_write_reg:
		lea		I2C,a6				
		move.w	#1,I2C_CTRL(a6)		; enable the core
		move.w	#$76,I2C_TXR(a6)	; set slave address = %0111011
		move.w	#$90,I2C_CMD(a6)	; set STA, WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		move.w	#$40,I2C_TXR(a6)	; all regsister are $40xx
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		move.w	d0,I2C_TXR(a6)		; send register address
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		move.w	d1,I2C_TXR(a6)		; send data
		move.w	#$50,I2C_CMD(a6)	; set STO, WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		rts

audio_tbl1:
		dc.w	$00,$7D,$00,$0C,$20,$01
; a0
;
audio_write_reg6:
		lea		audio_tbl1,a0
		lea		I2C,a6				
		move.w	#1,I2C_CTRL(a6)		; enable the core
		move.w	#$76,I2C_TXR(a6)	; set slave address = %0111011
		move.w	#$90,I2C_CMD(a6)	; set STA, WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		move.w	#$40,I2C_TXR(a6)	; all regsister are $40xx
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	d0,I2C_TXR(a6)		; send register address
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack
		
		move.w	(a0)+,I2C_TXR(a6)	; send data #0
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	(a0)+,I2C_TXR(a6)	; send data #1
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	(a0)+,I2C_TXR(a6)	; send data #2
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	(a0)+,I2C_TXR(a6)	; send data #3
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	(a0)+,I2C_TXR(a6)	; send data #4
		move.w	#$10,I2C_CMD(a6)	; set WR
		bsr		i2c_wait_tip	; wait for tip to clear
		bsr		i2c_wait_rx_nack

		move.w	(a0)+,I2C_TXR(a6)	; send data #5
		move.w	#$50,I2C_CMD(a6)	; set WR, STO
		bsr		i2c_wait_tip		; wait for tip to clear
		bsr		i2c_wait_rx_nack
		rts

set_hp_output:
		moveq	#$21,d0				;
		moveq	#0,d1
		bsr		audio_write_reg
		moveq	#$20,d0				;
		bsr		audio_write_reg
		moveq	#$23,d0
		move.w	#$E7,d1		
		bsr		audio_write_reg
		moveq	#$24,d0
		move.w	#$E7,d1		
		bsr		audio_write_reg
		rts

;===============================================================================
; Realtime clock routines
;===============================================================================

rtc_read:
		movea.l	#I2C2,a6
		lea		RTCBuf,a5
		move.w	#$80,I2C_CTRL(a6)	; enable I2C
		move.w	#$DE,d0				; read address, write op
		move.w	#$90,d1				; STA + wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		move.w	#$00,d0				; address zero
		move.w	#$10,d1				; wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		move.w	#$DF,d0				; read address, read op
		move.w	#$90,d1				; STA + wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		
		move.w	#$20,d2
.0001:
		move.w	#$20,I2C_CMD(a6)	; rd bit
		bsr		i2c_wait_tip
		bsr		i2c_wait_rx_nack
		move.w	I2C_STAT(a6),d0
		tst.b	d0
		bmi		.rxerr
		move.w	I2C_RXR(a6),d0
		move.b	d0,(a5,d2.w)
		add.w	#1,d2
		cmp.w	#$5F,d2
		bne		.0001
		move.w	#$68,I2C_CMD(a6)	; STO, rd bit + nack
		bsr		i2c_wait_tip
		bsr		i2c_wait_rx_nack
		move.w	I2C_STAT(a6),d0
		tst.b	d0
		bmi		.rxerr
		move.w	I2C_RXR(a6),d0
		move.b	d0,(a5,d2.w)
		move.w	#0,I2C_CTRL(a6)		; disable I2C and return 0
		moveq	#0,d0
		rts
.rxerr:
		move.w	#0,I2C_CTRL(a6)		; disable I2C and return status
		rts

rtc_write:
		movea.l	#I2C2,a6
		lea		RTCBuf,a5
		move.w	#$80,I2C_CTRL(a6)	; enable I2C
		move.w	#$DE,d0				; read address, write op
		move.w	#$90,d1				; STA + wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		move.w	#$00,d0				; address zero
		move.w	#$10,d1				; wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		move.w	#$20,d2
.0001:
		move.b	(a5,d2.w),d0
		move.w	#$10,d1
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		add.w	#1,d2
		cmp.w	#$5F,d2
		bne.s	.0001
		move.b	(a5,d2.w),d0
		move.w	#$50,d1				; STO, wr bit
		bsr		i2c_wr_cmd
		tst.b	d0
		bmi		.rxerr
		move.w	#0,I2C_CTRL(a6)		; disable I2C and return 0
		moveq	#0,d0
		rts
.rxerr:
		move.w	#0,I2C_CTRL(a6)		; disable I2C and return status
		rts

msgRtcReadFail:
		dc.b	"RTC read/write failed.",$0D,$0A,$00

		
; Randomize the screen	
;		move.l	#VDGBUF,A0
;		move.l	#%011011111,D0		; light blue
;		move.l	#640*512,D1
;clrscr_loop1:
;		move.l	$0C00(a6),d0			; get a random number
;		clr.w	$0C04(a6)				; generate next number
;		move.w	d0,(a0)+				; store it to the screen
;		sub.l	#1,d1
;		bne		clrscr_loop1

msg_start:
	dc.b	"N4V 68k System Starting",0

;------------------------------------------------------------------------------
font8:
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $04
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $08
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $0C
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $10
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $14
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $18
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; $1C
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; 
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; SPACE
	dc.b	$18,$18,$18,$18,$18,$00,$18,$00	; !
	dc.b	$6C,$6C,$00,$00,$00,$00,$00,$00	; "
	dc.b	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	; #
	dc.b	$18,$3E,$60,$3C,$06,$7C,$18,$00	; $
	dc.b	$00,$66,$AC,$D8,$36,$6A,$CC,$00	; %
	dc.b	$38,$6C,$68,$76,$DC,$CE,$7B,$00	; &
	dc.b	$18,$18,$30,$00,$00,$00,$00,$00	; '
	dc.b	$0C,$18,$30,$30,$30,$18,$0C,$00	; (
	dc.b	$30,$18,$0C,$0C,$0C,$18,$30,$00	; )
	dc.b	$00,$66,$3C,$FF,$3C,$66,$00,$00	; *
	dc.b	$00,$18,$18,$7E,$18,$18,$00,$00	; +
	dc.b	$00,$00,$00,$00,$00,$18,$18,$30	; ,
	dc.b	$00,$00,$00,$7E,$00,$00,$00,$00	; -
	dc.b	$00,$00,$00,$00,$00,$18,$18,$00	; .
	dc.b	$03,$06,$0C,$18,$30,$60,$C0,$00	; /
	dc.b	$3C,$66,$6E,$7E,$76,$66,$3C,$00	; 0
	dc.b	$18,$38,$78,$18,$18,$18,$18,$00	; 1
	dc.b	$3C,$66,$06,$0C,$18,$30,$7E,$00	; 2
	dc.b	$3C,$66,$06,$1C,$06,$66,$3C,$00	; 3
	dc.b	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00	; 4
	dc.b	$7E,$60,$7C,$06,$06,$66,$3C,$00	; 5
	dc.b	$1C,$30,$60,$7C,$66,$66,$3C,$00	; 6
	dc.b	$7E,$06,$06,$0C,$18,$18,$18,$00	; 7
	dc.b	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
	dc.b	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
	dc.b	$00,$18,$18,$00,$00,$18,$18,$00	; :
	dc.b	$00,$18,$18,$00,$00,$18,$18,$30	; ;
	dc.b	$00,$06,$18,$60,$18,$06,$00,$00	; <
	dc.b	$00,$00,$7E,$00,$7E,$00,$00,$00	; =
	dc.b	$00,$60,$18,$06,$18,$60,$00,$00	; >
	dc.b	$3C,$66,$06,$0C,$18,$00,$18,$00	; ?
	dc.b	$7C,$C6,$DE,$D6,$DE,$C0,$78,$00	; @
	dc.b	$3C,$66,$66,$7E,$66,$66,$66,$00	; A
	dc.b	$7C,$66,$66,$7C,$66,$66,$7C,$00	; B
	dc.b	$1E,$30,$60,$60,$60,$30,$1E,$00	; C
	dc.b	$78,$6C,$66,$66,$66,$6C,$78,$00	; D
	dc.b	$7E,$60,$60,$78,$60,$60,$7E,$00	; E
	dc.b	$7E,$60,$60,$78,$60,$60,$60,$00	; F
	dc.b	$3C,$66,$60,$6E,$66,$66,$3E,$00	; G
	dc.b	$66,$66,$66,$7E,$66,$66,$66,$00	; H
	dc.b	$3C,$18,$18,$18,$18,$18,$3C,$00	; I
	dc.b	$06,$06,$06,$06,$06,$66,$3C,$00	; J
	dc.b	$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00	; K
	dc.b	$60,$60,$60,$60,$60,$60,$7E,$00	; L
	dc.b	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00	; M
	dc.b	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	; N
	dc.b	$3C,$66,$66,$66,$66,$66,$3C,$00	; O
	dc.b	$7C,$66,$66,$7C,$60,$60,$60,$00	; P
	dc.b	$78,$CC,$CC,$CC,$CC,$DC,$7E,$00	; Q
	dc.b	$7C,$66,$66,$7C,$6C,$66,$66,$00	; R
	dc.b	$3C,$66,$70,$3C,$0E,$66,$3C,$00	; S
	dc.b	$7E,$18,$18,$18,$18,$18,$18,$00	; T
	dc.b	$66,$66,$66,$66,$66,$66,$3C,$00	; U
	dc.b	$66,$66,$66,$66,$3C,$3C,$18,$00	; V
	dc.b	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	; W
	dc.b	$C3,$66,$3C,$18,$3C,$66,$C3,$00	; X
	dc.b	$C3,$66,$3C,$18,$18,$18,$18,$00	; Y
	dc.b	$FE,$0C,$18,$30,$60,$C0,$FE,$00	; Z
	dc.b	$3C,$30,$30,$30,$30,$30,$3C,$00	; [
	dc.b	$C0,$60,$30,$18,$0C,$06,$03,$00	; \
	dc.b	$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00	; ]
	dc.b	$10,$38,$6C,$C6,$00,$00,$00,$00	; ^
	dc.b	$00,$00,$00,$00,$00,$00,$00,$FE	; _
	dc.b	$18,$18,$0C,$00,$00,$00,$00,$00	; `
	dc.b	$00,$00,$3C,$06,$3E,$66,$3E,$00	; a
	dc.b	$60,$60,$7C,$66,$66,$66,$7C,$00	; b
	dc.b	$00,$00,$3C,$60,$60,$60,$3C,$00	; c
	dc.b	$06,$06,$3E,$66,$66,$66,$3E,$00	; d
	dc.b	$00,$00,$3C,$66,$7E,$60,$3C,$00	; e
	dc.b	$1C,$30,$7C,$30,$30,$30,$30,$00	; f
	dc.b	$00,$00,$3E,$66,$66,$3E,$06,$3C	; g
	dc.b	$60,$60,$7C,$66,$66,$66,$66,$00	; h
	dc.b	$18,$00,$18,$18,$18,$18,$0C,$00	; i
	dc.b	$0C,$00,$0C,$0C,$0C,$0C,$0C,$78	; j
	dc.b	$60,$60,$66,$6C,$78,$6C,$66,$00	; k
	dc.b	$18,$18,$18,$18,$18,$18,$0C,$00	; l
	dc.b	$00,$00,$EC,$FE,$D6,$C6,$C6,$00	; m
	dc.b	$00,$00,$7C,$66,$66,$66,$66,$00	; n
	dc.b	$00,$00,$3C,$66,$66,$66,$3C,$00	; o
	dc.b	$00,$00,$7C,$66,$66,$7C,$60,$60	; p
	dc.b	$00,$00,$3E,$66,$66,$3E,$06,$06	; q
	dc.b	$00,$00,$7C,$66,$60,$60,$60,$00	; r
	dc.b	$00,$00,$3C,$60,$3C,$06,$7C,$00	; s
	dc.b	$30,$30,$7C,$30,$30,$30,$1C,$00	; t
	dc.b	$00,$00,$66,$66,$66,$66,$3E,$00	; u
	dc.b	$00,$00,$66,$66,$66,$3C,$18,$00	; v
	dc.b	$00,$00,$C6,$C6,$D6,$FE,$6C,$00	; w
	dc.b	$00,$00,$C6,$6C,$38,$6C,$C6,$00	; x
	dc.b	$00,$00,$66,$66,$66,$3C,$18,$30	; y
	dc.b	$00,$00,$7E,$0C,$18,$30,$7E,$00	; z
	dc.b	$0E,$18,$18,$70,$18,$18,$0E,$00	; {
	dc.b	$18,$18,$18,$18,$18,$18,$18,$00	; |
	dc.b	$70,$18,$18,$0E,$18,$18,$70,$00	; }
	dc.b	$72,$9C,$00,$00,$00,$00,$00,$00	; ~
	dc.b	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00	; 
