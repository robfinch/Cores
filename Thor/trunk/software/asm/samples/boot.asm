
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

E_BadFuncno    EQU       1
BIOS_E_Timeout EQU       2
E_Unsupported  EQU       3

BIOS_STACKTOP		EQU		$3bf8
INT_STACK			EQU		$37f8
VIDEO_BIOS_STACKTOP	EQU		$3ff8

IOBASE_ADDR	EQU		0xFFD00000
IOLMT		EQU		0x100000
LEDS		EQU		0xC0600
TEXTSCR		EQU		0x00000
TEXTSCR2	EQU		0x10000
TEXTREG		EQU		0xA0000
TEXTREG2	EQU		0xA0040
TEXT_COLS	EQU		0x0
TEXT_ROWS	EQU		0x2
TEXT_CURPOS	EQU		0x16
KEYBD		EQU		0xC0000

PIC_IE		EQU		0xC0FC8
PIC_ES		EQU		0xC0FE0
PIC_ESR		EQU		0xC0FE8		; edge sense reset

		bss
		org		$0000
		dw		0				; the first word is unused
Milliseconds	dw		0
KeyState1		db		0	
KeyState2		db		0
KeybdLEDs		db		0
KeybdWaitFlag	db		0

CursorX			dc		0
CursorY			dc		0
VideoPos		dc		0
		align	4
NormAttr		dh		0
Vidregs			dh		0
Vidptr			dh		0
EscState		dc		0
Textrows		dc		0
Textcols		dc		0
		align	8
reg_save		fill.w	64,0
creg_save		fill.w	16,0
sreg_save		fill.w	16,0
preg_save		dw		0

		bss
		org		$4000


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

NUMWKA          fill.b  64,0

	code 17 bits
	org		$FFFF8000

cold_start:
		; Initialize segment registers for flat model
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
		ldi		r31,#$03ef8		; initialize kernel SP
		ldi		r27,#$03bf8		; initialize SP

		; switch processor to full speed
		stp		#$FFFF

		; set interrupt table at $1000
		ldis	c12,#$1000

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
		lla		r1,cs:brk_jmp
		ldi		r2,#0
		bsr		set_vector

		; setup Video BIOS vector
		lla		r1,cs:vb_jmp
		ldi		r2,#10
		bsr		set_vector

		; setup NMI vector
		lla		r1,cs:nmi_jmp
		ldi		r2,#254
		bsr		set_vector

		lla		r1,cs:svc_jmp
		ldi		r2,#190
		bsr		set_vector
		lla		r1,cs:rsc_jmp
		ldi		r2,#191
		bsr		set_vector

		; setup MSI vector
		sh		r0,Milliseconds
		lla		r1,cs:msi_jmp
		ldi		r2,#193
		bsr		set_vector

		; setup IRQ vector
		lla		r1,cs:tms_jmp
		ldi		r2,#194
		bsr		set_vector

		; setup data bus error vector
		lla		r1,cs:dbe_jmp
		ldi		r2,#251
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
		sc		r1,hs:LEDS

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
		cli

		; now globally enable interrupts using the RTI instruction, this will also
		; switch to core to application/user mode.
		ldis	c14,#j1			; c14 contains RTI return address
		sync
;		rti
j1:
		ldi		r1,#2
		sc		r1,hs:LEDS
		sb		r0,EscState
		bsr		SerialInit
		bsr		Debugger
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
		bsr		VBClearScreen
;		bsr		VBClearScreen2
		ldi		r1,#3
		sc		r1,hs:LEDS
		mov		r1,r0
		mov		r2,r0
		ldi		r6,#2		; Set Cursor Pos
		sys		#10
		ldi		r1,#6
		sc		r1,hs:LEDS
		bsr		alphabet
		lla		r1,cs:msgStartup	; convert to linear address
		ldi		r6,#$14
		sys		#10

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Monitor
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Monitor:
		lla		r1,cs:msgMonitor
		bsr		VBDisplayString

		; Display monitor prompt
.prompt:
		ldi		r1,#CR
		bsr		VBDisplayChar
		ldi		r1,#LF
		bsr		VBDisplayChar
		ldi		r1,#'$'
		bsr		VBDisplayChar
		bsr		CursorOn
.getkey:
		bsr		KeybdGetCharWait
		bsr		VBDisplayChar
		cmpi	p0,r1,#CR
p0.ne	br		.getkey
		bsr		CursorOff
		lcu		r1,CursorY
		lcu		r7,Textcols
		mtspr	lc,r7				; use loop counter as safety
		mulu	r10,r1,r7			; pos = row * cols
		_4addu	r10,r10,r0			; pos *= 4
.0001:
		bsr		MonGetch1			; get character skipping spaces
		cmpi	p0,r1,#'$'			; skip over prompt
p0.eq	br		.0001
		cmpi	p0,r1,#'d'			; debug ?
p0.eq	bsr		Debugger
		br		.prompt

;------------------------------------------------------------------------------
; Returns:
;	r1  ascii code for character
;	r10 incremented
;   lc  decremented
;------------------------------------------------------------------------------

MonGetch:
		addui	r31,r31,#-8
		sws		c1,[r31]
		lhu		r1,[r10]
		andi	r1,r1,#$3ff
		bsr		VBScreenToAscii
		addui	r10,r10,#4
		loop	.0001			; decrement loop counter
.0001:
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

;------------------------------------------------------------------------------
; Returns:
;	r1  ascii code for character
;	r10 incremented by number of spaces + 1
;   lc  decremented by number of spaces + 1
;------------------------------------------------------------------------------

MonGetch1:
		addui	r31,r31,#-8
		sws		c1,[r31]
.0001:
		lhu		r1,[r10]
		andi	r1,r1,#$3ff
		bsr		VBScreenToAscii
		addui	r10,r10,#4
		cmpi	p0,r1,#' '
p0.leu	loop	.0001
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

;------------------------------------------------------------------------------

msgStartup:	
		byte	"Thor Test System Starting...",CR,LF,0
msgStartupEnd:
msgMonitor:
		byte	CR,LF,"d - run debugger",CR,LF,0

bad_ram:
		ldi		r1,#'B'
		bsr		VBAsciiToScreen
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
		bsr		VBAsciiToScreen	; r1 = screen char
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
		lh		r3,zs:[r1]
		sh		r3,zs:[r2]
		lh		r3,zs:4[r1]
		sh		r3,zs:4[r2]
		lh		r3,zs:8[r1]
		sh		r3,zs:8[r2]
		lh		r3,zs:12[r1]
		sh		r3,zs:12[r2]
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

save_context:
		sw		r1,reg_save+8*1
		sw		r2,reg_save+8*2
		sw		r3,reg_save+8*3
		sw		r4,reg_save+8*4
		sw		r5,reg_save+8*5
		sw		r6,reg_save+8*6
		sw		r7,reg_save+8*7
		sw		r8,reg_save+8*8
		sw		r9,reg_save+8*9
		sw		r10,reg_save+8*10
		sw		r11,reg_save+8*11
		sw		r12,reg_save+8*12
		sw		r13,reg_save+8*13
		sw		r14,reg_save+8*14
		sw		r15,reg_save+8*15
		sw		r16,reg_save+8*16
		sw		r17,reg_save+8*17
		sw		r18,reg_save+8*18
		sw		r19,reg_save+8*19
		sw		r20,reg_save+8*20
		sw		r21,reg_save+8*21
		sw		r22,reg_save+8*22
		sw		r23,reg_save+8*23
		sw		r24,reg_save+8*24
		sw		r25,reg_save+8*25
		sw		r26,reg_save+8*26
		sw		r27,reg_save+8*27
		sw		r28,reg_save+8*28
		sw		r29,reg_save+8*29
		sw		r30,reg_save+8*30
		sw		r31,reg_save+8*31
		sws		ds,sreg_save+8*1
		sws		es,sreg_save+8*2
		sws		fs,sreg_save+8*3
		sws		gs,sreg_save+8*4
		sws		hs,sreg_save+8*5
		sws		ss,sreg_save+8*6
		sws		cs,sreg_save+8*7
		sws		ds.lmt,sreg_save+8*9
		sws		es.lmt,sreg_save+8*10
		sws		fs.lmt,sreg_save+8*11
		sws		gs.lmt,sreg_save+8*12
		sws		hs.lmt,sreg_save+8*13
		sws		ss.lmt,sreg_save+8*14
		sws		cs.lmt,sreg_save+8*15
		sws		c1,creg_save+8*1
		sws		c2,creg_save+8*2
		sws		c3,creg_save+8*3
		sws		c4,creg_save+8*4
		sws		c5,creg_save+8*5
		sws		c6,creg_save+8*6
		sws		c7,creg_save+8*7
		sws		c8,creg_save+8*8
		sws		c9,creg_save+8*9
		sws		c10,creg_save+8*10
		sws		c11,creg_save+8*11
		sws		c13,creg_save+8*13
		sws		c14,creg_save+8*14
		sws		pregs,preg_save
		rte

restore_context:
		lw		r1,reg_save+8*1
		lw		r2,reg_save+8*2
		lw		r3,reg_save+8*3
		lw		r4,reg_save+8*4
		lw		r5,reg_save+8*5
		lw		r6,reg_save+8*6
		lw		r7,reg_save+8*7
		lw		r8,reg_save+8*8
		lw		r9,reg_save+8*9
		lw		r10,reg_save+8*10
		lw		r11,reg_save+8*11
		lw		r12,reg_save+8*12
		lw		r13,reg_save+8*13
		lw		r14,reg_save+8*14
		lw		r15,reg_save+8*15
		lw		r16,reg_save+8*16
		lw		r17,reg_save+8*17
		lw		r18,reg_save+8*18
		lw		r19,reg_save+8*19
		lw		r20,reg_save+8*20
		lw		r21,reg_save+8*21
		lw		r22,reg_save+8*22
		lw		r23,reg_save+8*23
		lw		r24,reg_save+8*24
		lw		r25,reg_save+8*25
		lw		r26,reg_save+8*26
		lw		r27,reg_save+8*27
		lw		r28,reg_save+8*28
		lw		r29,reg_save+8*29
		lw		r30,reg_save+8*30
		lw		r31,reg_save+8*31
		lws		ds,sreg_save+8*1
		lws		es,sreg_save+8*2
		lws		fs,sreg_save+8*3
		lws		gs,sreg_save+8*4
		lws		hs,sreg_save+8*5
		lws		ss,sreg_save+8*6
		lws		cs,sreg_save+8*7
		lws		ds.lmt,sreg_save+8*9
		lws		es.lmt,sreg_save+8*10
		lws		fs.lmt,sreg_save+8*11
		lws		gs.lmt,sreg_save+8*12
		lws		hs.lmt,sreg_save+8*13
		lws		ss.lmt,sreg_save+8*14
		lws		cs.lmt,sreg_save+8*15
		lws		c1,creg_save+8*1
		lws		c2,creg_save+8*2
		lws		c3,creg_save+8*3
		lws		c4,creg_save+8*4
		lws		c5,creg_save+8*5
		lws		c6,creg_save+8*6
		lws		c7,creg_save+8*7
		lws		c8,creg_save+8*8
		lws		c9,creg_save+8*9
		lws		c10,creg_save+8*10
		lws		c11,creg_save+8*11
;		lws		c13,creg_save+8*13
		lws		c14,creg_save+8*14
		lws		pregs,preg_save
		rte

.include "video.asm"
.include "keyboard.asm"
.include "serial.asm"
.include "debugger.asm"

;------------------------------------------------------------------------------
; Uninitialized interrupt
;------------------------------------------------------------------------------
uii_rout:
		sync
		ldi		r31,#INT_STACK-16
		sw		r1,[r31]
		sws		hs,8[r31]

		; set I/O segment
		ldis	hs,#$FFD00000

		; update on-screen IRQ live indicator
		ldi		r1,#'U'|%011000000_111111111_00_00000000
		sh		r1,hs:TEXTSCR+320

		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		sync
		rti

;------------------------------------------------------------------------------
; Non-maskable interrupt routine.
;
;------------------------------------------------------------------------------
;
nmi_rout:
		sync
		ldi		r31,#INT_STACK-16
		sw		r1,[r31]
		sws		hs,8[r31]

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
		lw		r1,[r31]
		lws		hs,8[r31]
		sync
		rti

;------------------------------------------------------------------------------
; Millisecond (1024 Hz) interrupt routine.
;
;------------------------------------------------------------------------------
;
msi_rout:
		sync
		ldi		r31,#INT_STACK-16
		sw		r1,[r31]
		sws		hs,8[r31]

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
		lw		r1,[r31]
		lws		hs,8[r31]
		sync
		rti

;------------------------------------------------------------------------------
; Time Slice IRQ routine.
;
;
;------------------------------------------------------------------------------
;
tms_rout:
		sync
		ldi		r31,#INT_STACK-16
		sw		r1,[r31]
		sws		hs,8[r31]

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
		lw		r1,[r31]
		lws		hs,8[r31]
		sync
		rti

;------------------------------------------------------------------------------
; Time Slice IRQ routine.
;
;
;------------------------------------------------------------------------------
;
dbe_rout:
		sync
		ldi		r31,#INT_STACK-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sw		r5,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000

		ldi		r1,#64
		sc		r1,hs:LEDS

		; reset the bus error circuit to re-enable interrupts
		sh		r0,hs:$CFFE0

		; update on-screen DBE indicator
		ldi		r1,'D'|%011000000_000000110_0000000000
		sh		r1,hs:TEXTSCR+320

		; Advance the program to the next address
		mfspr	r5,c14
		bsr		DBGGetInsnLength
		addu	r1,r5,r1
		mtspr	c14,r1

		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		lw		r5,16[r31]
		sync
		rti

;------------------------------------------------------------------------------
; Break routine
;
; Currently uses only registers in case memory is bad, and sets an indicator
; on-screen.
;------------------------------------------------------------------------------
;
brk_rout:
		sync
		ldi		r1,#'B'
		bsr		VBAsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,zs:$FFD10140
		ldi		r1,#'R'
		bsr		VBAsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,zs:$FFD10144
		ldi		r1,#'K'
		bsr		VBAsciiToScreen
		ori		r1,r1,#|%011000000_111111111_00_00000000
		sh		r1,zs:$FFD10148
		ldi		r2,#10
		ldi		r6,#0
		mfspr	r5,c13
		bsr		DisplayAddr
brk_lockup:
		br		brk_lockup[c0]

; code snippet to jump to the break routine, copied to the break vector
;
; vector table jumps
;
		align	8
brk_jmp:
		jmp		brk_rout[c0]
		align	8
tms_jmp:
		jmp		tms_rout[c0]
		align	8
msi_jmp:
		jmp		msi_rout[c0]
		align	8
nmi_jmp:
		jmp		nmi_rout[c0]
		align	8
uii_jmp:
		jmp		uii_rout[c0]
		align	8
vb_jmp:
		jmp		VideoBIOSCall[c0]
		align	8
ser_jmp:
		jmp		SerialIRQ[c0]
		align	8
dbe_jmp:
		jmp		dbe_rout[c0]
		align	8
svc_jmp:
		jmp		save_context
		align	8
rsc_jmp:
		jmp		restore_context

;------------------------------------------------------------------------------
; Reset Point
;------------------------------------------------------------------------------

		org		$FFFFEFF0
		jmp		cold_start[c15]

extern my_main : 24

