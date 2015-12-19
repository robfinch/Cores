
; ============================================================================
;        __
;   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
SCRSZ	EQU	2604
CR	EQU	0x0D		;ASCII equates
LF	EQU	0x0A
TAB	EQU	0x09
CTRLC	EQU	0x03
BS		EQU	0x07
CTRLH	EQU	0x08
CTRLI	EQU	0x09
CTRLJ	EQU	0x0A
CTRLK	EQU	0x0B
CTRLM   EQU 0x0D
CTRLS	EQU	0x13
CTRLX	EQU	0x18
XON		EQU	0x11
XOFF	EQU	0x13
ESC		EQU	0x1B

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

IOBASE_ADDR	EQU		0xFFD00000
IOLMT		EQU		0x100000
LEDS		EQU		0xC0600
TEXTSCR		EQU		0x00000
TEXTSCR2	EQU		0x10000
TEXTREG		EQU		0xA0000
TEXT_COLS	EQU		0x0
TEXT_ROWS	EQU		0x2
TEXT_CURPOS	EQU		0x16
KEYBD		EQU		0xC0000

PIC_IE		EQU		0xC0FC8
PIC_ES		EQU		0xC0FE0
PIC_ESR		EQU		0xC0FE8		; edge sense reset

KeyState1	EQU		$2008
KeyState2	EQU		$2009
KeybdLEDs	EQU		$200A
KeybdWaitFlag	EQU	$200B

CursorX		EQU		$2030
CursorY		EQU		$2032
VideoPos	EQU		$2034
NormAttr	EQU		$2036
Vidregs		EQU		$2040
Vidptr		EQU		$2044
EscState	EQU		$2048
Textrows	EQU		$204A
Textcols	EQU		$204C

		bss
		org		$30000

Milliseconds	dw		0

rxfull     EQU      1
Uart_ms         db      0
Uart_txxonoff   db      0
Uart_rxhead     dc      0
Uart_rxtail     dc      0
Uart_rxflow     db      0
Uart_rxrts      db      0
Uart_rxdtr      db      0
Uart_rxxon      db      0
Uart_foff       dc      0
Uart_fon        dc      0
Uart_txrts      db      0
Uart_txdtr      db      0
Uart_txxon      db      0
Uart_rxfifo     fill.b  512,0

	code
	org		$FFFF8000

cold_start:

		; Initialize segment registers for flat model
		mtspr	cs,r0
		ldis	cs.lmt,#-1		; maximum
		mtspr	zs,r0
		ldis	zs.lmt,#-1
		mtspr	ds,r0
		ldis	ds.lmt,#-1
		mtspr	es,r0
		ldis	es.lmt,#-1
		mtspr	fs,r0
		ldis	fs.lmt,#-1
		mtspr	gs,r0
		ldis	gs.lmt,#-1
		ldis	hs,#IOBASE_ADDR
		ldis	hs.lmt,#IOLMT

		; set SS:SP
		mtspr	ss,r0
		ldis	ss.lmt,#$4000
		ldi		r27,#$03ff8		; initialize SP

		; switch processor to full speed
		stp		#$FFFF

		; set interrupt table at $0000
		ldis	c12,#0

		; set all vectors to the uninitialized interrupt vector
;		mov		r4,r0
;		ldis	lc,#255		; 256 vectors to set
;su1:
;		ldi		r1,#uii_jmp
;		mov		r2,r4
;		bsr		set_vector	; trashes r2,r3
;		addui	r4,r4,#1
;		loop	su1

		; setup break vector
		ldi		r1,#brk_jmp
		ldi		r2,#0
		bsr		set_vector

		; setup NMI vector
		ldi		r1,#nmi_jmp
		ldi		r2,#254
		bsr		set_vector

		; setup MSI vector
		sh		r0,Milliseconds
		ldi		r1,#msi_jmp
		ldi		r2,#193
		bsr		set_vector

		; setup IRQ vector
		ldi		r1,#tms_jmp
		ldi		r2,#194
		bsr		set_vector

		; Initialize PIC
		ldi		r1,#%00111		; time slice interrupt is edge sensitive
		sh		r1,hs:PIC_ES
		ldi		r1,#%00111		; enable time slice interrupt, msi, nmi
		sh		r1,hs:PIC_IE

		mov		r1,r0
		mov		r2,r0
		mov		r3,r0
		mov		r4,r0
		mov		r5,r0

		ldi		r1,#1
		sc		r1,$FFDC0600

		tlbwrreg DMA,r0				; clear TLB miss registers
		tlbwrreg IMA,r0
		ldi			r1,#2			; 2 wired registers
		tlbwrreg	Wired,r1
		ldi			r1,#$2			; 64kiB page size
		tlbwrreg	PageSize,r1

		; setup the first translation
		; virtual page $FFFF0000 maps to physical page $FFFF0000
		; This places the BIOS ROM at $FFFFxxxx in the memory map
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		ldi			r1,#$0FFFF
		tlbwrreg	VirtPage,r1
		tlbwrreg	PhysPage,r1
		tlbwrreg	Index,r0		; select way #0
		tlbwi						; write to TLB entry group #0 with hold registers

		; setup second translation
		; virtual page 0 maps to physical page 0
		ldi			r1,#$80000101	; ASID=zero, G=1,valid=1
		tlbwrreg	ASID,r1
		tlbwrreg	VirtPage,r0
		tlbwrreg	PhysPage,r0
		ldi			r1,#8			; select way#1
		tlbwrreg	Index,r1		
		tlbwi						; write to TLB entry group #0 with hold registers

		; turn on the TLB
;		tlben

		; enable maskable interrupts
		; Interrupts also are not enabled until an RTI instruction is executed.
		; there will likely be a timer interrupt outstanding so this
		; should go to the timer IRQ.	
;		cli

		; now globally enable interrupts using the RTI instruction, this will also
		; switch to core to application/user mode.
		ldis	c14,#j1			; c14 contains RTI return address
;		rti
j1:
		ldi		r1,#2
		sc		r1,$FFDC0600
		sb		r0,EscState
		bsr		SerialInit
		ldi		r2,#msgStartup
		ldis	lc,#msgStartupEnd-msgStartup-1
j3:
;		lbu		r1,[r2]
;		addui	r2,r2,#1
;		tst		p0,r1
;p0.eq	br		j2
;		bsr		SerialPutChar
;		loop	j3
j2:
		bsr		VideoInit
		bsr		ClearScreen
		bsr		ClearScreen2
		ldi		r1,#3
		sc		r1,$FFDC0600
		bsr		HomeCursor
		ldi		r1,#6
		sc		r1,$FFDC0600
		bsr		alphabet
		ldi		r1,#msgStartup
		bsr		DisplayString
		ldi		r5,#TEXTSCR
.0001:
		bsr		KeybdGetCharWait
		bsr		AsciiToScreen
		ori		r1,r1,#%000000111_111111111_00_00000000
		sh		r1,hs:[r5]
		addui	r5,r5,#4
		br		.0001

msgStartup:	
		byte	"Thor Test System Starting...",CR,LF,0
msgStartupEnd:

bad_ram:
		ldi		r1,#'B'
		bsr		AsciiToScreen
		ori		r1,r1,#%011000000_111111111_00_00000000
		sh		r1,hs:TEXTSCR+16
.bram1:	br		.bram1

;------------------------------------------------------------------------------
; alphabet:
;
; Display the alphabet across the top of the screen.
;------------------------------------------------------------------------------

alphabet:
		addui	sp,sp,#-8
		sws		c1,[sp]			; store off return address
		ldi		r5,#'A'			; the first char
		ldi		r3,#TEXTSCR		; screen address
		ldis	lc,#25			; 25 chars
.0001:
		mov		r1,r5			; r1 = ascii letter
		bsr		AsciiToScreen	; r1 = screen char
		lhu		r2,NormAttr		; r2 = attribute
		or		r1,r1,r2		; r1 = screen char + attribute
		sh		r1,hs:[r3]		; store r1 to screen
		addui	r5,r5,#1		; increment to next char
		addui	r3,r3,#4		; increment to next screen loc
		loop	.0001			; loop back
		lws		c1,[sp]			; restore return address
		addui	sp,sp,#8
		rts
	
;------------------------------------------------------------------------------
; Set interrupt vector
;
; Parameters:
;	r1 = address of jump code
;	r2 = vector number to set
; Trashes: r2,r3
;------------------------------------------------------------------------------

set_vector:
		mfspr	r3,c12			; get base address of interrupt table
		_16addu	r2,r2,r3
		lh		r3,cs:[r1]
		sh		r3,zs:[r2]
		lh		r3,cs:4[r1]
		sh		r3,zs:4[r2]
		lh		r3,cs:8[r1]
		sh		r3,zs:8[r2]
		lh		r3,cs:12[r1]
		sh		r3,zs:12[r2]
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VideoInit:
		ldi		r1,#84
		sc		r1,Textcols
		ldi		r1,#31
		sc		r1,Textrows
		ldi		r1,#%011000000_111111111_00_00000000
		sh		r1,NormAttr
		ldi		r1,#TEXTREG
		sh		r1,Vidregs
		ldi		r1,#TEXTSCR
		sh		r1,Vidptr

		ldi		r2,#TC1InitData
		ldis	lc,#10				; initialize loop counter ( one less)
		lhu		r3,Vidregs
.0001:
		lvc		r1,cs:[r2]
;		sh		r1,hs:[r3]
		addui	r2,r2,#2
		addui	r3,r3,#4
		loop	.0001
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ClearScreen:
;		push	c1
		addui	r27,r27,#-8
		sws		c1,[r27]
		ldi		r1,#' '
		bsr		AsciiToScreen
		lh		r2,NormAttr
		or		r2,r2,r1
		ldis	lc,#SCRSZ-1
		mfspr	r1,lc
		cmpi	p0,r1,#SCRSZ-1
p0.ne	br		.0001
		lh		r1,Vidptr
		ldi		r1,#TEXTSCR
		stset.hi	r2,hs:[r1]
		ldi		r1,#TEXTSCR
		mov		r2,r1
		mov		r3,r0
		ldis	lc,#SCRSZ-1
		stcmp.hi	hs:[r1],[r2],r3
;		pop		c1
		lws		c1,[r27]
		addui	r27,r27,#8
.0001:
		rts

ClearScreen2:
		ldis	lc,#SCRSZ-1
		ldi		r2,#' '|%000011000_111111111_00_00000000;
		ldi		r1,#TEXTSCR2
		stset.hi	r2,hs:[r1]
		rts

;------------------------------------------------------------------------------
; Scroll the screen upwards.
;------------------------------------------------------------------------------

ScrollUp:
		ldi		r3,#0
		ldi		r2,#4096
		lh		r4,Vidptr
.0001:
		addui	r27,r27,#-8
		sw		r2,[r27]
		lc		r1,Textcols
		add		r3,r3,r1
		lh		r1,[r4+r3*4]
		lw		r3,[r27]		; pop r3
		addui	r27,r27,#8
		sh		r1,[r4+r3*4]
		addui	r3,r3,#1
		addui	r2,r2,#-1
		tst		p0,r2
p0.ne	br		.0001
		lc		r1,Textrows
		addui	r1,r1,#-1

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank
; Trashes:
;	r2,r3,r4
;------------------------------------------------------------------------------

BlankLine:
		shli	r1,r1,#1
		lc		r3,cs:LineTbl[r1]
		lc		r2,Textcols
		lh		r1,NormAttr
		ori		r1,r1,#$20
		lh		r4,Vidptr
.0001:
		sh		r1,[r4+r3]
		addui	r3,r3,#4
		addui	r2,r2,#-1
		tst		p0,r2
p0.ne	br		.0001
		rts

;------------------------------------------------------------------------------
; Turn cursor on or off.
;------------------------------------------------------------------------------

CursorOn:
		addui	r27,r27,#-16
		sw		r1,8[r27]
		sw		r2,[r27]
		lh		r2,Vidregs
		ldi		r1,#$40
		sh		r1,hs:32[r2]
		ldi		r1,#$1F
		sh		r1,hs:36[r2]
		lw		r2,[r27]
		lw		r1,8[r27]
		rts

CursorOff:
		addui	r27,r27,#-16
		sw		r1,8[r27]
		sw		r2,[r27]
		lh		r2,Vidregs
		ldi		r1,#$20
		sh		r1,hs:32[r2]
		mov		r1,r0
		sh		r1,hs:36[r2]
		lw		r2,[r27]
		lw		r1,8[r27]
		rts

;------------------------------------------------------------------------------
; Get the number of text rows and columns from the video controller.
;------------------------------------------------------------------------------

GetTextRowscols:
		lh		r2,Vidregs
		lvc		r1,hs:0[r2]
		sc		r1,Textcols
		lvc		r1,hs:4[r2]
		sc		r1,Textrows
		rts

;------------------------------------------------------------------------------
; Set cursor to home position.
;------------------------------------------------------------------------------

HomeCursor:
		sc		r0,CursorX
		sc		r0,CursorY
		sc		r0,VideoPos
		ldi		r1,#4
		sc		r1,$FFDC0600

;------------------------------------------------------------------------------
; Synchronize the absolute video position with the cursor co-ordinates.
; Does not modify any predicates.
;------------------------------------------------------------------------------

SyncVideoPos:
		addui	r27,r27,#-24
		sw		r1,16[r27]			; save off some working regs
		sw		r2,8[r27]
		sw		r3,[r27]
		ldi		r1,#5
		sc		r1,$FFDC0600
		lc		r2,CursorY
		shli	r2,r2,#1
		lcu		r1,cs:LineTbl[r2]
		shrui	r1,r1,#2
		lc		r2,CursorX
		addu	r1,r1,r2
		sc		r1,VideoPos
		lh		r3,Vidregs			; r3 = address of video registers
		sh		r1,hs:44[r3]		; Update the position in the text controller
		lw		r3,[r27]			; restore the regs
		lw		r2,8[r27]
		lw		r1,16[r27]
		addui	r27,r27,#24
		rts

		align	2
LineTbl:
		dc		0
		dc		TEXTCOLS*4
		dc		TEXTCOLS*8
		dc		TEXTCOLS*12
		dc		TEXTCOLS*16
		dc		TEXTCOLS*20
		dc		TEXTCOLS*24
		dc		TEXTCOLS*28
		dc		TEXTCOLS*32
		dc		TEXTCOLS*36
		dc		TEXTCOLS*40
		dc		TEXTCOLS*44
		dc		TEXTCOLS*48
		dc		TEXTCOLS*52
		dc		TEXTCOLS*56
		dc		TEXTCOLS*60
		dc		TEXTCOLS*64
		dc		TEXTCOLS*68
		dc		TEXTCOLS*72
		dc		TEXTCOLS*76
		dc		TEXTCOLS*80
		dc		TEXTCOLS*84
		dc		TEXTCOLS*88
		dc		TEXTCOLS*92
		dc		TEXTCOLS*96
		dc		TEXTCOLS*100
		dc		TEXTCOLS*104
		dc		TEXTCOLS*108
		dc		TEXTCOLS*112
		dc		TEXTCOLS*116
		dc		TEXTCOLS*120
		dc		TEXTCOLS*124

TC1InitData:
		dc		84		; #columns
		dc		31		; #rows
		dc		64		; window left
		dc		17		; window top
		dc		 7		; max scan line
		dc	   $21		; pixel size (hhhhvvvv)
		dc	  $1FF		; transparent color
		dc	   $40		; cursor blink, start line
		dc	    31		; cursor end
		dc		 0		; start address
		dc		 0		; cursor position
TC2InitData:
		dc		40
		dc		25
		dc	   376 
		dc      64		; window top
		dc		 7
		dc	   $10
		dc	  $1FF
		dc	   $40
		dc      31
		dc       0
		dc       0

;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;------------------------------------------------------------------------------

AsciiToScreen:
		zxb		r1,r1
		cmp		p0,r1,#' '
p0.le	ori		r1,r1,#$100
p0.le	br		.0003
		cmp		p0,r1,#$5B			; special test for  [ ] characters
p0.ne	br		.0001
		ldi		r1,#$11B
		rts
.0001:
		cmp		p0,r1,#$5D
p0.ne	br		.0002
		ldi		r1,#$11D
		rts
.0002:
		ori		r1,r1,#$100
		biti	p0,r1,#$20			; if bit 5 isn't set
p0.eq	br		.0003
		biti	p0,r1,#$40			; or bit 6 isn't set
p0.ne	andi	r1,r1,#$19F
.0003:
		rts

;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
ScreenToAscii:
		zxb		r1,r1
		cmpi	p0,r1,#27
p0.le	addi	r1,r1,#$60
		rts

.include "DisplayChar.asm"

;------------------------------------------------------------------------------
; Display a string on the screen.
; Parameters:
;	r1 = pointer to string
;------------------------------------------------------------------------------

DisplayString:
		addui	sp,sp,#-32
		sws		c1,[sp]			; save return address
		sws		lc,8[sp]		; save loop counter
		sw		r2,16[sp]
		sws		p2,24[sp]
		ldis	lc,#$FFF		; set max 4k
		mov		r2,r1
.0001:
		lbu		r1,[r2]
		tst		p2,r1
p2.eq	br		.0002
		bsr		DisplayChar
		addui	r2,r2,#1
		loop	.0001
.0002:
		lws		c1,[sp]			; restore return address
		lws		lc,8[sp]		; restore loop counter
		lw		r2,16[sp]
		lws		p2,24[sp]
		addui	sp,sp,#32
		rts

KeybdGetCharWait:
		ldi		r1,#-1
		sb		r1,KeybdWaitFlag
		br		KeybdGetChar

KeybdGetCharNoWait:
		sb		r0,KeybdWaitFlag
		br		KeybdGetChar

; Wait for a keyboard character to be available
; Returns (-1) if no key available
; Return key >= 0 if key is available
;
;
KeybdGetChar:
KeybdGetChar1:
		addui	r27,r27,#-16
		sws		c1,8[r27]		; save off link register
		sw		r2,[r27]
.0002:
.0003:
		memsb
		lvb		r1,hs:KEYBD+1	; check MSB of keyboard status reg.
		biti	p0,r1,#$80
p0.ne	br		.0006
		lb		r1,KeybdWaitFlag
		tst		p0,r1
p0.lt	br		.0003
		lw		r2,[r27]
		lws		c1,8[r27]
		addui	r27,r27,#16
		rts
.0006:
		memsb
		lvb		r1,hs:KEYBD		; get scan code value
		memdb
		zxb		r1,r1			; make unsigned
		sb		r0,hs:KEYBD+1	; clear read flag
		ldi		r3,#3
		sc		r3,$FFDC0600
.0001:
		cmp		p0,r1,#SC_KEYUP	; keyup scan code ?
p0.eq	br		.doKeyup
		cmp		p0,r1,#SC_EXTEND; extended scan code ?
p0.eq	br		.doExtend
		cmp		p0,r1,#$14		; control ?
p0.eq	br		.doCtrl
		cmp		p0,r1,#$12		; left shift
p0.eq	br		.doShift
		cmp		p0,r1,#$59		; right shift
p0.eq	br		.doShift
		cmp		p0,r1,#SC_NUMLOCK
p0.eq	br		.doNumLock
		cmp		p0,r1,#SC_CAPSLOCK
p0.eq	br		.doCapsLock
		cmp		p0,r1,#SC_SCROLLLOCK
p0.eq	br		.doScrollLock
		lb		r2,KeyState1
		andi	r2,r2,#1
		cmp		p0,r2,#0
p0.ne	br		.0003
		lb		r2,KeyState2	; Is extended code ?
		andi	r2,r2,#$80
p0.eq	br		.0010
		lb		r2,KeyState2
		andi	r2,r2,#$7F
		sb		r2,KeyState2
		sb		r0,KeyState1	; clear keyup
		andi	r1,r1,#$7F
		lbu		r1,cs:keybdExtendedCodes[r1]
		br		.0008
.0010:
		ldi		r3,#4
		sc		r3,$FFDC0600
		lb		r2,KeyState2
		biti	p0,r2,#4		; Is Cntrl down ?
p0.eq	br		.0009
		andi	r1,r1,#$7F
		lbu		r1,cs:keybdControlCodes[r1]
		br		.0008
.0009:
		lb		r2,KeyState2
		biti	p0,r2,#1		; Is shift down ?
p0.eq	br		.0007
		andi	r1,r1,#$FF
		lbu		r1,cs:shiftedScanCodes[r1]
		br		.0008
.0007:
		andi	r1,r1,#$FF
		lbu		r1,cs:unshiftedScanCodes[r1]
.0008:
		ldi		r3,#5
		sc		r3,$FFDC0600
		lw		r2,[r27]
		lws		c1,8[r27]
		addui	r27,r27,#16
		rts

.doKeyup:
		lb		r2,KeyState1
		ori		r2,r2,#1
		sb		r2,KeyState1
		br		.0003
.doExtend:
		lb		r2,KeyState2
		ori		r2,r2,#$80
		sb		r2,KeyState2
		br		.0003
.doCtrl:
		lb		r2,KeyState1
		biti	p0,r2,#1
p0.eq	br		.0004
		lbu		r2,KeyState2
		andi	r2,r2,#~4
		sb		r2,KeyState2
		br		.0003
.0004:
		lbu		r2,KeyState2
		ori		r2,r2,#4
		sb		r2,KeyState2
		br		.0003
.doShift:
		lb		r2,KeyState1
		biti	p0,r2,#1
p0.eq	br		.0005
		lbu		r2,KeyState2
		andi	r2,r2,#~1
		sb		r2,KeyState2
		br		.0003
.0005:
		lbu		r2,KeyState2
		ori		r2,r2,#1
		sb		r2,KeyState2
		br		.0003
.doNumLock:
		lbu		r2,KeyState2
		eori	r2,r2,#16
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003
.doCapsLock:
		lbu		r2,KeyState2
		eori	r2,r2,#32
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003
.doScrollLock:
		lbu		r2,KeyState2
		eori	r2,r2,#64
		sb		r2,KeyState2
		bsr		KeybdSetLEDStatus
		br		.0003

;------------------------------------------------------------------------------
; Set the keyboard LED status leds.
; Trashes r1, p0
;------------------------------------------------------------------------------

KeybdSetLEDStatus:
		addui	r27,r27,#-8
		sws		c1,[r27]
		sb		r0,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#16
p0.ne	lb		r1,KeybdLEDs	; set bit 1 for Num lock, 0 for scrolllock , 2 for caps lock
p0.ne	ori		r1,r1,#2
p0.ne	sb		r1,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#32
p0.ne	lb		r1,KeybdLEDs
p0.ne	ori		r1,r1,#4
p0.ne	sb		r1,KeybdLEDs
		lb		r1,KeyState2
		biti	p0,r1,#64
p0.ne	lb		r1,KeybdLEDs
p0.ne	ori		r1,r1,#1
p0.ne	sb		r1,KeybdLEDs
		ldi		r1,#$ED
		sb		r1,hs:KEYBD		; set status LEDs command
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
		cmpi	p0,r1,#$FA
		lb		r1,KeybdLEDs
		sb		r1,hs:KEYBD		
		bsr		KeybdWaitTx
		bsr		KeybdRecvByte
		lws		c1,[r27]
		addui	r27,r27,#8
		rts

;------------------------------------------------------------------------------
; Receive a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
; Returns:
;	r1 >= 0 if a scancode is available
;   r1 = -1 on timeout
;------------------------------------------------------------------------------
;
KeybdRecvByte:
		addui	r27,r27,#-16
		sws		c1,8[r27]
		sw		r3,[r27]
		ldi		r3,#20			; wait up to .2s
.0003:
		bsr		KeybdWaitBusy
		lb		r1,hs:KEYBD+1	; wait for response from keyboard
		biti	p0,r1,#$80		; is input buffer full ?
p0.ne	br		.0004			; yes, branch
		bsr		Wait10ms		; wait a bit
		addui	r3,r3,#-1
		tst		p0,r3
p0.ne	br		.0003			; go back and try again
		lw		r3,[r27]		; timeout
		lws		c1,8[r27]
		addui	r27,r27,#16
		ldi		r1,#-1
		rts
.0004:
		lvb		r1,hs:KEYBD		; get scancode
		zxb		r1,r1			; convert to unsigned char
		sb		r0,hs:KEYBD+1	; clear recieve state
		lw		r3,[r27]
		lws		c1,8[r27]
		addui	r27,r27,#16
		rts						; return char in r1

;------------------------------------------------------------------------------
; Wait until the keyboard isn't busy anymore
; Wait until the keyboard transmit is complete
; Returns:
;    r1 >= 0 if successful
;	 r1 < 0 if timed out
;------------------------------------------------------------------------------
;
KeybdWaitBusy:				; alias for KeybdWaitTx
KeybdWaitTx:
		addui	r27,r27,#-16
		sws		c1,8[r27]
		sw		r3,[r27]
		ldi		r3,#10			; wait a max of .1s
.0001:
		lvb		r1,hs:KEYBD+1
		biti	p0,r1,#$40		; check for transmit busy bit
p0.eq	br		.0002			; branch if bit clear
		bsr		Wait10ms		; delay a little bit
		addui	r3,r3,#-1		; go back and try again
		tst		p0,r3
p0.ne	br		.0001
		lw		r3,[r27]		; timed out
		lws		c1,8[r27]
		addui	r27,r27,#16
		ldi		r1,#-1			; return -1
		rts
.0002:
		lw		r3,[r27]		; wait complete, return 
		lws		c1,8[r27]		; restore return address
		ldi		r1,#0			; return 0 for okay
		addui	r27,r27,#16
		rts

;------------------------------------------------------------------------------
; Delay for about 10 ms.
;------------------------------------------------------------------------------

Wait10ms:
		addui	r27,r27,#-16
		sw		r1,8[r27]
		sw		r2,[r27]
		mfspr	r1,tick
		addui	r1,r1,#250000	; 10ms at 25 MHz
.0001:
		mfspr	r2,tick
		cmp		p0,r2,r1
p0.lt	br		.0001
		lw		r2,[r27]
		lw		r1,8[r27]
		addui	r27,r27,#16
		rts

	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
unshiftedScanCodes:
	byte	$2e,$a9,$2e,$a5,$a3,$a1,$a2,$ac
	byte	$2e,$aa,$a8,$a6,$a4,$09,$60,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$71,$31,$2e
	byte	$2e,$2e,$7a,$73,$61,$77,$32,$2e
	byte	$2e,$63,$78,$64,$65,$34,$33,$2e
	byte	$2e,$20,$76,$66,$74,$72,$35,$2e
	byte	$2e,$6e,$62,$68,$67,$79,$36,$2e
	byte	$2e,$2e,$6d,$6a,$75,$37,$38,$2e
	byte	$2e,$2c,$6b,$69,$6f,$30,$39,$2e
	byte	$2e,$2e,$2f,$6c,$3b,$70,$2d,$2e
	byte	$2e,$2e,$27,$2e,$5b,$3d,$2e,$2e
	byte	$ad,$2e,$0d,$5d,$2e,$5c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	byte	$98,$7f,$92,$2e,$91,$90,$1b,$af
	byte	$ab,$2e,$97,$2e,$2e,$96,$ae,$2e

	byte	$2e,$2e,$2e,$a7,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$fa,$2e,$2e,$2e,$2e,$2e

shiftedScanCodes:
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$51,$21,$2e
	byte	$2e,$2e,$5a,$53,$41,$57,$40,$2e
	byte	$2e,$43,$58,$44,$45,$24,$23,$2e
	byte	$2e,$20,$56,$46,$54,$52,$25,$2e
	byte	$2e,$4e,$42,$48,$47,$59,$5e,$2e
	byte	$2e,$2e,$4d,$4a,$55,$26,$2a,$2e
	byte	$2e,$3c,$4b,$49,$4f,$29,$28,$2e
	byte	$2e,$3e,$3f,$4c,$3a,$50,$5f,$2e
	byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

; control
keybdControlCodes:
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$11,$21,$2e
	byte	$2e,$2e,$1a,$13,$01,$17,$40,$2e
	byte	$2e,$03,$18,$04,$05,$24,$23,$2e
	byte	$2e,$20,$16,$06,$14,$12,$25,$2e
	byte	$2e,$0e,$02,$08,$07,$19,$5e,$2e
	byte	$2e,$2e,$0d,$0a,$15,$26,$2a,$2e
	byte	$2e,$3c,$0b,$09,$0f,$29,$28,$2e
	byte	$2e,$3e,$3f,$0c,$3a,$10,$5f,$2e
	byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

keybdExtendedCodes:
	byte	$2e,$2e,$2e,$2e,$a3,$a1,$a2,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	byte	$98,$99,$92,$2e,$91,$90,$2e,$2e
	byte	$2e,$2e,$97,$2e,$2e,$96,$2e,$2e

.include "serial.asm"

;------------------------------------------------------------------------------
; Uninitialized interrupt
;------------------------------------------------------------------------------
uii_rout:
		addui	r27,r27,#-16
		sw		r1,[r27]
		sws		hs,8[r27]

		; set I/O segment
		ldis	hs,#$FFD00000

		; update on-screen IRQ live indicator
		ldi		r1,#'U'|%011000000_111111111_00_00000000
		sh		r1,hs:TEXTSCR+320

		; restore regs and return
		lw		r1,[r27]
		lws		hs,8[r27]
		addui	r27,r27,#16
		rti

;------------------------------------------------------------------------------
; Non-maskable interrupt routine.
;
;------------------------------------------------------------------------------
;
nmi_rout:
		addui	r27,r27,#-16
		sw		r1,[r27]
		sws		hs,8[r27]

		; set I/O segment
		ldis	hs,#$FFD00000

		ldi		r1,#16
		sc		r1,hs:LEDS

		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#0
		sh		r1,hs:PIC_ESR

		; update on-screen IRQ live indicator
		lh		r1,hs:TEXTSCR+324
		addui	r1,r1,#1
		sh		r1,hs:TEXTSCR+324

		; restore regs and return
		lw		r1,[r27]
		lws		hs,8[r27]
		addui	r27,r27,#16
		rti

;------------------------------------------------------------------------------
; Millisecond interrupt routine.
;
;
;------------------------------------------------------------------------------
;
msi_rout:
		addui	sp,sp,#-16
		sw		r1,[sp]
		sws		hs,8[sp]

		; set I/O segment
		ldis	hs,#$FFD00000

		ldi		r1,#24
		sc		r1,hs:LEDS

		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#1
		sh		r1,hs:PIC_ESR

		; update milliseconds
		lh		r1,Milliseconds
		addui	r1,r1,#1
		sh		r1,Milliseconds

		; restore regs and return
		lw		r1,[sp]
		lws		hs,8[sp]
		addui	sp,sp,#16
		rti

;------------------------------------------------------------------------------
; Time Slice IRQ routine.
;
;
;------------------------------------------------------------------------------
;
tms_rout:
		addui	r27,r27,#-16
		sw		r1,[r27]
		sws		hs,8[r27]

		; set I/O segment
		ldis	hs,#$FFD00000

		ldi		r1,#32
		sc		r1,hs:LEDS

		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#2
		sh		r1,hs:PIC_ESR

		; update on-screen IRQ live indicator
		lh		r1,hs:TEXTSCR+328
		addui	r1,r1,#1
		sh		r1,hs:TEXTSCR+328

		; restore regs and return
		lw		r1,[r27]
		lws		hs,8[r27]
		addui	r27,r27,#16
		rti

;------------------------------------------------------------------------------
; Break routine
;
; Currently uses only registers in case memory is bad, and sets an indicator
; on-screen.
;------------------------------------------------------------------------------
;
brk_rout:
		ldi		r1,#'B'
		bsr		AsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,$FFD00000
		ldi		r1,#'R'
		bsr		AsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,$FFD00004
		ldi		r1,#'K'
		bsr		AsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,$FFD00008
brk_lockup:
		br		brk_lockup[c0]

; code snippet to jump to the break routine, copied to the break vector
;
; vector table jumps
;
		align	4
brk_jmp:	jmp		brk_rout[c0]
		align	4
tms_jmp:	jmp		tms_rout[c0]
		align	4
msi_jmp:	jmp		msi_rout[c0]
		align	4
nmi_jmp:	jmp		nmi_rout[c0]
		align	4
uii_jmp:	jmp		uii_rout[c0]

;------------------------------------------------------------------------------
; Reset Point
;------------------------------------------------------------------------------

		org		$FFFFEFF0
		jmp		cold_start[C15]

