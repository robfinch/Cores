;-------------------------------------------------------------------------------
;
; system memory map
;
;
; 00000000 +----------------+
;          | startup sp,pc  | 8 B
; 00000008 +----------------+
;					 |    vectors     |
; 00000400 +----------------+
;					 |   bios mem     |
; 00000800 +----------------+
;					 |   bios code    |
; 00008000 +----------------+
;					 |    unused      |
; 20000000 +----------------+
;          |                |
;          |                |
;          |                |
;          :  dram memory   : 512 MB
;          |                |
;          |                |
;          |                |
; 40000000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FFD00000 +----------------+
;          |                |
;          :    I/O area    : 1.0 M
;          |                |
; FFE00000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FFFFFFE0 +----------------+
;          | special regs   |
; FFFFFFFF +----------------+
;
;-------------------------------------------------------------------------------
;
CTRLC	EQU		$03
CTRLH	EQU		$08
CTRLX	EQU		$18
LF		EQU		$0A
CR		EQU		$0D

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

TEXTREG		EQU	$FD01FF00
txtscreen	EQU	$FD000000
leds			EQU	$FD0FFF00
keybd			EQU	$FD0FFE00
KEYBD			EQU	$FD0FFE00
rand			EQU	$FD0FFD00

	data
	dc.l		$0001FFFC
	dc.l		start
	dc.l		0
	dc.l		0
	dc.l		0
	dc.l		0
	dc.l		EXCEPTION_6			* CHK
	dc.l		EXCEPTION_7			* TRAPV

	align		10
	dc.l		0
fgcolor:
	dc.l		$1fffff					; white
bkcolor:
	dc.l		$00003f					; dark blue
CursorRow
	dc.b		$00
CursorCol
	dc.b		$00
TextRows
	dc.b		32
TextCols
	dc.b		64
TextPos
TextCurpos
	dc.w		$00
	dc.w		0
TextScr
	dc.l		$FD000000
KeybdEcho
	dc.b		0
KeybdWaitFlag
	dc.b		0
KeybdLEDs
	dc.b		0
_KeyState1
	dc.b		0
_KeyState2
	dc.b		0
CmdBuf:
	dc.b		0
CmdBufEnd:
	dc.b		0
DisplayMem:
	dc.b		0


;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

	code
start:
	move.l	$FFFFFFE0,d0		; get core number
	cmpi.b	#2,d0
	bne			do_nothing
	bsr			Delay3s					; give devices time to reset
	bsr			clear_screen
	clr.b		CursorCol
	clr.b		CursorRow
	clr.w		TextCurpos

	; Write startup message to screen

	lea			msg_start,a1
	bsr			DisplayString
	move.w	#$A4A4,leds			; diagnostics
	bra			Monitor
	bsr			cpu_test
;	lea			brdisp_trap,a0	; set brdisp trap vector
;	move.l	a0,64*4

loop2:
	move.l	#-1,d0
loop1:
	move.l	d0,d1
	lsr.l		#8,d1
	lsr.l		#8,d1
	move.b	d1,leds
	dbra		d0,loop1
	bra			loop2
do_nothing:
	bra			do_nothing

; -----------------------------------------------------------------------------
; Delay for a few seconds to allow some I/O reset operations to take place.
; -----------------------------------------------------------------------------

Delay3s:
	move.l	#3000000,d0		; this should take a few seconds to loop
	lea			leds,a0				; a0 = address of LED output register
	bra			dly3s1				; branch to the loop
dly3s2:	
	swap		d0						; loop is larger than 16-bits
dly3s1:
	move.l	d0,d1					; the counter cycles fast, so use upper bits for display
	rol.l		#8,d1					; could use swap here, but lets test rol
	rol.l		#8,d1
	move.b	d1,(a0)				; set the LEDs
	dbra		d0,dly3s1			; decrement and branch back
	swap		d0
	dbra		d0,dly3s2
	rts

	include "cputest.asm"

; -----------------------------------------------------------------------------
; Gets the screen color in d0 and d1.
; -----------------------------------------------------------------------------

get_screen_color:
	move.l	fgcolor,d0			; get foreground color
	asl.l		#5,d0						; shift into position
	ori.l		#$40000000,d0		; set priority
	move.l	bkcolor,d1
	lsr.l		#8,d1
	lsr.l		#8,d1
	andi.l	#31,d1					; mask off extra bits
	or.l		d1,d0						; set background color bits in upper long word
	move.l	bkcolor,d1			; get background color
	asl.l		#8,d1						; shift into position for display ram
	asl.l		#8,d1
	rts

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------

clear_screen:
	move.l	TextScr,a0				; a0 = pointer to screen area
	move.b	TextRows,d0				; d0 = rows
	move.b	TextCols,d2				; d2 = cols
	ext.w		d0								; convert to word
	ext.w		d2								; convert to word
	mulu		d0,d2							; d2 = number of character cells to clear
	bsr			get_screen_color	; get the color bits
	ori.w		#32,d1						; load space character
	rol.w		#8,d1							; swap endian, text controller expects little endian
	swap		d1
	rol.w		#8,d1
	rol.w		#8,d0							; swap endian
	swap		d0
	rol.w		#8,d0
loop3:
	move.l	d1,(a0)+					; copy char plus bkcolor to cell
	move.l	d0,(a0)+					; copy fgcolor to cell
	dbra		d2,loop3
	rts

CRLF:
	move.l	d1,-(a7)
	move.b	#13,d1
	bsr			DisplayChar
	move.b	#10,d1
	bsr			DisplayChar
	move.l	(a7)+,d1
	rts

;------------------------------------------------------------------------------
; Calculate screen memory location from CursorRow,CursorCol.
; Destroys d0,d2,a0
;------------------------------------------------------------------------------
;
CalcScreenLoc:
	move.b	CursorRow,d0		; compute screen location
	andi.w	#$7f,d0
	move.b	TextCols,d2
	ext.w		d2
	mulu.w	d2,d0
	move.b	CursorCol,d2
	andi.w	#$ff,d2
	add.w		d2,d0
	move.w	d0,TextCurpos		; save cursor pos
	ext.l		d0							; make it into a long
	asl.l		#3,d0						; 8 bytes per char
	add.l		TextScr,d0
	move.l	d0,a0						; a0 = screen location
	rts

;------------------------------------------------------------------------------
; Display a character on the screen
; d1.b = char to display
;------------------------------------------------------------------------------
;
DisplayChar:
	movem.l	d2/d3,-(a7)
	cmpi.b	#13,d1			; carriage return ?
	bne.s		dccr
	clr.b		CursorCol			; just set cursor column to zero on a CR
	bsr			SyncCursor		; set position in text controller
	movem.l	(a7)+,d2/d3
	rts
dccr:
	cmpi.b	#$91,d1			; cursor right ?
	bne.s   dcx6
	move.b	TextCols,d2
	sub.b		#1,d2
	sub.b		CursorCol,d2
	beq.s		dcx7
	addi.b	#1,CursorCol
dcx14:
	bsr		SyncCursor
dcx7:
	movem.l	(a7)+,d2/d3
	rts
dcx6:
	cmpi.b	#$90,d1			; cursor up ?
	bne.s	dcx8
	cmpi.b	#0,CursorRow
	beq.s	dcx7
	subi.b	#1,CursorRow
	bra.s	dcx14
dcx8:
	cmpi.b	#$93,d1			; cursor left?
	bne.s	dcx9
	cmpi.b	#0,CursorCol
	beq.s	dcx7
	subi.b	#1,CursorCol
	bra.s	dcx14
dcx9:
	cmpi.b	#$92,d1			; cursor down ?
	bne.s	dcx10
	move.b	TextRows,d2
	sub.b	#1,d2
	cmp.b	CursorRow,d2
	beq.s	dcx7
	addi.b	#1,CursorRow
	bra.s	dcx14
dcx10:
	cmpi.b	#$94,d1			; cursor home ?
	bne.s	dcx11
	cmpi.b	#0,CursorCol
	beq.s	dcx12
	clr.b	CursorCol
	bra.s	dcx14
dcx12:
	clr.b	CursorRow
	bra.s	dcx14
dcx11:
	movem.l	d0/d1/d2/a0,-(a7)
	cmpi.b	#$99,d1			; delete ?
	beq.s		doDelete
	cmpi.b	#CTRLH,d1			; backspace ?
	beq.s   doBackspace
	cmpi.b	#CTRLX,d1			; delete line ?
	beq			doCtrlX
	cmpi.b	#10,d1		; linefeed ?
	beq.s		dclf

	; regular char
	bsr			CalcScreenLoc	; a0 = screen location
	move.l	d1,d2					; d2 = char
	bsr			get_screen_color	; d0,d1 = color
	or.l		d2,d1					; d1 = char + color
	rol.w		#8,d1					; text controller expects little endian data
	swap		d1
	rol.w		#8,d1
	move.l	d1,(a0)
	rol.w		#8,d0					; swap bytes
	swap		d0						; swap halfs
	rol.w		#8,d0					; swap remaining bytes
	move.l	d0,4(a0)
	bsr			IncCursorPos
	bsr			SyncCursor
	movem.l	(a7)+,d0/d1/d2/a0
	movem.l	(a7)+,d2/d3
	rts
dclf:
	bsr			IncCursorRow
dcx16:
	bsr			SyncCursor
dcx4:
	movem.l	(a7)+,d0/d1/d2/a0		; get back a0
	movem.l	(a7)+,d2/d3
	rts

	;---------------------------
	; CTRL-H: backspace
	;---------------------------
doBackspace:
	cmpi.b	#0,CursorCol		; if already at start of line
	beq.s   dcx4						; nothing to do
	subi.b	#1,CursorCol		; decrement column

	;---------------------------
	; Delete key
	;---------------------------
doDelete:
	movem.l	d0/d1/a0,-(a7)	; save off screen location
	bsr		  CalcScreenLoc		; a0 = screen location
	move.b	CursorCol,d0
.0001:
	move.l	8(a0),(a0)		; pull remaining characters on line over 1
	move.l	12(a0),4(a0)	; pull remaining characters on line over 1
	lea			8(a0),a0
	addi.b	#1,d0
	cmp.b		TextCols,d0
	blo.s		.0001
	bsr			get_screen_color
	move.w	#' ',d1				; terminate line with a space
	rol.w		#8,d1
	swap		d1
	rol.w		#8,d1
	move.l	d1,-8(a0)
	movem.l	(a7)+,d0/d1/a0
	bra.s		dcx16				; finished

	;---------------------------
	; CTRL-X: erase line
	;---------------------------
doCtrlX:
	clr.b		CursorCol			; Reset cursor to start of line
	move.b	TextCols,d0			; and display TextCols number of spaces
	ext.w		d0
	ext.l		d0
	move.b	#' ',d1				; d1 = space char
.0001:
	; DisplayChar is called recursively here
	; It's safe to do because we know it won't recurse again due to the
	; fact we know the character being displayed is a space char
	bsr		DisplayChar			
	subq	#1,d0
	bne.s	.0001
	clr.b	CursorCol			; now really go back to start of line
	bra.s	dcx16				; we're done

;------------------------------------------------------------------------------
; Increment the cursor position, scroll the screen if needed.
;------------------------------------------------------------------------------
;
IncCursorPos:
	addi.w	#1,TextCurpos
	addi.b	#1,CursorCol
	move.b	TextCols,d0
	cmp.b		CursorCol,d0
	bhs.s		icc1
	clr.b		CursorCol
IncCursorRow:
	addi.b	#1,CursorRow
	move.b	TextRows,d0
	cmp.b		CursorRow,d0
	bhi.s		icc1
	move.b	TextRows,d0
	move.b	d0,CursorRow		; in case CursorRow is way over
	subi.b	#1,CursorRow
	ext.w		d0
	asl.w		#1,d0
	sub.w		d0,TextCurpos
	bsr			ScrollUp
icc1:
	rts

;------------------------------------------------------------------------------
; Scroll screen up.
;------------------------------------------------------------------------------

ScrollUp:
	movem.l	d0/d1/a0/a5,-(a7)		; save off some regs
	move.l	TextScr,a5					; a5 = pointer to text screen
.0003:								
	move.b	TextCols,d0					; d0 = columns
	move.b	TextRows,d1					; d1 = rows
	ext.w		d0									; make cols into a word value
	ext.w		d1									; make rows into a word value
	asl.w		#3,d0								; make into cell index
	lea			0(a5,d0.w),a0				; a0 = pointer to second row of text screen
	lsr.w		#3,d0								; get back d0
	mulu		d1,d0								; d0 = count of characters to move
.0001:
	move.l	(a0)+,(a5)+					; each char is 64 bits
	move.l	(a0)+,(a5)+
	dbra		d0,.0001
	movem.l	(a7)+,d0/d1/a0/a5
	; Fall through into blanking out last line

;------------------------------------------------------------------------------
; Blank out the last line on the screen.
;------------------------------------------------------------------------------

BlankLastLine:
	movem.l	d0/d1/d2/a5,-(a7)
	move.l	TextScr,a5
	lea			31*64(a5),a5
	move.b	TextCols,d2
	ext.w		d2
	bsr			get_screen_color
	ori.w		#32,d1		
.0001:
	move.l	d1,(a5)+
	move.l	d0,(a5)+
	dbra		d2,.0001
	movem.l	(a7)+,d0/d1/d2/a5
	rts

;------------------------------------------------------------------------------
; Display a string on the screen.
;------------------------------------------------------------------------------
;
DisplayString:
	movem.l	d0/d1/a1,-(a7)
dspj1:
	clr.l		d1				; clear upper bits of d1
	move.b	(a1)+,d1		; move string char into d1
	cmpi.b	#0,d1			; is it end of string ?
	beq.s		dsret			
	bsr			DisplayChar		; display character
	bra.s		dspj1			; go back for next character
dsret:
	movem.l	(a7)+,d0/d1/a1
	rts

;------------------------------------------------------------------------------
; Display a string on the screen followed by carriage return / linefeed.
;------------------------------------------------------------------------------
;
DisplayStringCRLF:
		bsr		DisplayString
		bra		CRLF

;------------------------------------------------------------------------------
; SyncCursor:
;
; Sync the hardware cursor's position to the text cursor position.
;
; Parameters:
;		<none>
; Returns:
;		<none>
; Registers Affected:
;		<none>
;------------------------------------------------------------------------------

SyncCursor:
	movem.l	d1/a6,-(a7)
	move.l	#TEXTREG,a6
	move.w	TextPos,d1
	rol.w		#8,d1						; swap byte order
	move.w	d1,$24(a6)
	movem.l	(a7)+,d1/a6
	rts

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

_KeybdInit:
	clr.b	_KeyState1
	clr.b	_KeyState2
	rts

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
	bpl.s		cfk1
	move.b	#1,d1
	rts
cfk1:
	clr.b		d1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetKey:
	bsr			KeybdGetCharWait
	cmpi.b	#0,KeybdEcho	; is keyboard echo on ?
	beq.s		gk1
	cmpi.b	#CR,d1				; convert CR keystroke into CRLF
	beq			CRLF
	rts
	bra			DisplayChar
gk1:
;	move.l	d1,d7
;	bsr			DisplayByte
;	moveq		#32,d1
;	bsr			DisplayChar
;	move.l	d7,d1
	rts


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

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
;==============================================================================
; Monitor
;==============================================================================
;==============================================================================
;
; Get a word from screen memory and swap byte order

FromScreen:
	move.l	(a0),d1
	rol.w		#8,d1
	swap		d1
	rol.w		#8,d1
	lea			8(a0),a0	; increment screen pointer
	rts

StartMon:
Monitor:
;	lea		STACK,a7		; reset the stack pointer
	clr.b	KeybdEcho		; turn off keyboard echo
PromptLn:
	bsr			CRLF
	move.b	#'$',d1
	bsr			DisplayChar

; Get characters until a CR is keyed
;
Prompt3:
	bsr			GetKey
	cmpi.b	#CR,d1
	beq.s		Prompt1
	bsr			DisplayChar
	bra.s		Prompt3

; Process the screen line that the CR was keyed on
;
Prompt1:
	clr.b		CursorCol			; go back to the start of the line
	bsr			CalcScreenLoc	; a0 = screen memory location
.0001:
	bsr			FromScreen		; grab character off screen
	cmpi.b	#'$',d1				; skip over '$' prompt character
	beq.s		.0001
	
; Dispatch based on command character
;
Prompt2:
	cmpi.b	#'a',d1
	beq		AudioInputTest
	cmpi.b	#'b',d1
	beq		BouncingBalls
	cmpi.b	#'g',d1
	beq		GraphicsDemo
	cmpi.b	#':',d1			; $: - edit memory
	beq		EditMem
	cmpi.b	#'D',d1			; $D - dump memory
	beq		DumpMem
	cmpi.b	#'F',d1
	beq		FillMem
	cmpi.b	#'B',d1			; $B - start tiny basic
	bne.s	.0001
	jmp		$FFFCC000
.0001:
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
	bsr			FromScreen
	addq		#1,d2
	cmpi.b	#'L',d1
	bne			Monitor
	bsr			FromScreen
	addq		#1,d2
	cmpi.b	#'S',d1
	bne			Monitor
	bsr			ClearScreen
	bra			Monitor
	
DisplayHelp:
	lea			HelpMsg,a1
	jsr			DisplayString
	bra			Monitor

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
; This routine borrowed from Gordo's Tiny Basic interpreter.
; Used to fetch a command line. (Not currently used).
;
; d0.b	- command prompt
;------------------------------------------------------------------------------

GetCmdLine:
		bsr		DisplayChar		; display prompt
		move.b	#' ',d0
		bsr		DisplayChar
		lea		CmdBuf,a0
.0001:
		bsr		GetKey
		cmp.b	#CTRLH,d0
		beq.s	.0003
		cmp.b	#CTRLX,d0
		beq.s	.0004
		cmp.b	#CR,d0
		beq.s	.0002
		cmp.b	#' ',d0
		bcs.s	.0001
.0002:
		move.b	d0,(a0)
		lea			8(a0),a0
		bsr		DisplayChar
		cmp.b	#CR,d0
		beq		.0007
		cmp.l	#CmdBufEnd-1,a0
		bcs.s	.0001
.0003:
		move.b	#CTRLH,d0
		bsr		DisplayChar
		move.b	#' ',d0
		bsr		DisplayChar
		cmp.l	#CmdBuf,a0
		bls.s	.0001
		move.b	#CTRLH,d0
		bsr		DisplayChar
		subq.l	#1,a0
		bra.s	.0001
.0004:
		move.l	a0,d1
		sub.l	#CmdBuf,d1
		beq.s	.0006
		subq	#1,d1
.0005:
		move.b	#CTRLH,d0
		bsr		DisplayChar
		move.b	#' ',d0
		bsr		DisplayChar
		move.b	#CTRLH,d0
		bsr		DisplayChar
		dbra	d1,.0005
.0006:
		lea		CmdBuf,a0
		bra		.0001
.0007:
		move.b	#LF,d0
		bsr		DisplayChar
		rts

		
;------------------------------------------------------------------------------
; Fill memory
; FB = fill bytes		FB 00000010 100 FF	; fill starting at 10 for 256 bytes
; FW = fill words
; FL = fill longs
; F = fill bytes
;------------------------------------------------------------------------------
;
FillMem:
	bsr			FromScreen
	;bsr		ScreenToAscii
	move.b	d1,d4			; d4 = fill size
	bsr			ignBlanks
	bsr			GetHexNumber
	move.l	d1,a1			; a1 = start
	bsr			ignBlanks
	bsr			GetHexNumber
	move.l	d1,d3			; d3 = count
	bsr			ignBlanks
	bsr			GetHexNumber	; fill value
	cmpi.b	#'L',d4
	bne			fmem1
fmemL:
	move.l	d1,(a1)+
	sub.l	#1,d3
	bne.s	fmemL
	bra		Monitor
fmem1
	cmpi.b	#'W',d4
	bne		fmemB
fmemW:
	move.w	d1,(a1)+
	sub.l	#1,d3
	bne.s	fmemW
	bra		Monitor
fmemB:
	move.b	d1,(a1)+
	sub.l	#1,d3
	bne.s	fmemB
	bra		Monitor

;------------------------------------------------------------------------------
; Modifies:
;	a0	- text pointer
;------------------------------------------------------------------------------
;
ignBlanks:
	move.l	d1,-(a7)
.0001:
	bsr			FromScreen
	cmpi.b	#' ',d1
	beq.s		.0001
	lea			-8(a0),a0
	move.l	(a7)+,d1
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
	tst.b	d0				; was there a number ?
	beq		Monitor			; no, other garbage, just ignore
	move.l	d1,d3			; save off start of range
	bsr		ignBlanks
	bsr		GetHexNumber
	tst.b	d0
	bne.s	DumpMem1
	move	d3,d1
	addi.l	#64,d1			; no end specified, just dump 64 bytes
DumpMem1:
	move.l	d3,a0
	move.l	d1,a1
	jsr		CRLF
.0001:
	cmpa.l	a0,a1
	bhi		Monitor
	bsr		DisplayMem
	bra.s	.0001


;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
;
; Returns:
;	d0 = number of digits
;	d1 = value of number
;------------------------------------------------------------------------------
;
GetHexNumber:
	move.l	d2,-(a7)
	clr.l	d2
	moveq	#0,d0
.0002:
	bsr			FromScreen
	bsr			AsciiToHexNybble
	cmp.b		#$ff,d1
	beq.s		.0001
	lsl.l		#4,d2
	andi.l	#$0f,d1
	or.l		d1,d2
	addq		#1,d0
	cmpi.b	#8,d0
	blo.s		.0002
.0001:
	move.l	d2,d1
	move.l	(a7)+,d2
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

;------------------------------------------------------------------------------
; Display nybble in D1.B
;------------------------------------------------------------------------------
;
DisplayNybble:
	move.l	d1,-(a7)
	andi.b	#$F,d1
	addi.b	#'0',d1
	cmpi.b	#'9',d1
	bls.s		dispnyb1
	addi.b	#7,d1
dispnyb1:
	bsr			DisplayChar
	move.l	(a7)+,d1
	rts

;------------------------------------------------------------------------------
; Display the byte in D1.B
;------------------------------------------------------------------------------
;
DisplayByte:
	ror.b		#4,d1
	bsr			DisplayNybble
	rol.b		#4,d1
	bra			DisplayNybble

;------------------------------------------------------------------------------
; Display the 32 bit word in D1.L
;------------------------------------------------------------------------------
;
DisplayTetra:
	rol.l	#8,d1
	bsr		DisplayByte
	rol.l	#8,d1
	bsr		DisplayByte
	rol.l	#8,d1
	bsr		DisplayByte
	rol.l	#8,d1
	bra		DisplayByte

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;
;DisplayHexNumber:
;	move.w	#$A6A6,leds		; diagnostics
;	move.l	#VDGREG,a6
;	move.w	#7,d2		; number-1 of digits to display
;disphnum1:
;	move.b	d1,d0		; get digit into d0.b
;	andi.w	#$0f,d0
;	cmpi.w	#$09,d0
;	bls.s	disphnum2
;	addi.w	#7,d0
;disphnum2:
;	addi.w	#$30,d0	; convert to display char
;	move.w	d2,d3		; char count into d3
;	asl.w	#3,d3		; scale * 8
;disphnum3:
;	move.w	$42C(a6),d4			; read character queue index into d4
;	cmp.w	#28,d4					; allow up 28 entries to be in progress
;	bhs.s	disphnum3				; branch if too many chars queued
;	ext.w	d0						; zero out high order bits
;	move.w	d0,$420(a6)			; set char code
;	move.w	#WHITE,$422(a6)		; set fg color
;	move.w	#DARK_BLUE,$424(a6)	; set bk color
;	move.w	d3,$426(a6)			; set x pos
;	move.w	#8,$428(a6)			; set y pos
;	move.w	#$0707,$42A(a6)		; set font x,y extent
;	move.w	#0,$42E(a6)			; pulse character queue write signal
;	ror.l	#4,d1					; rot to next digit
;	dbeq	d2,disphnum1
;	jmp		(a5)

AudioInputTest:
	rts
BouncingBalls:
	rts
GraphicsDemo:
	rts
LoadS19:
	rts
ClearScreen:
	bra		clear_screen
	rts

brdisp_trap:
	addq		#4,sp					; get rid of sr
	move.l	(sp)+,d1			; pop exception address
	bsr			DisplayTetra	; and display it
	stop		#$2700

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------

msg_start:
	dc.b	"rf68k System Starting",CR,LF,0

