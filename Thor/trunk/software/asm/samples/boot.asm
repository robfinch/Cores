
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
.include "C:\Cores4\Thor\trunk\software\FMTK\source\kernel\FMTK_Equates.inc"

SCRSZ	EQU	2604
_BS		EQU	0x07
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
ESC		EQU	0x1B

SC_TAB		EQU		$0D
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

PIC_IS		EQU		0xC0FC0
PIC_IE		EQU		0xC0FC8
PIC_ES		EQU		0xC0FE0
PIC_ESR		EQU		0xC0FE8		; edge sense reset

		bss
		org		$0000
		dw		0				; the first word is unused
Milliseconds	dw		0
m_w				dh		0
m_z				dh		0
FMTK_SchedulerIRQ_vec	dw	0
Running_		dw		0
IOFocusNdx_		dw		0
iof_switch_		db		0
		align	8
NextRdy_		dw		0
PrevRdy_		dw		0

KeyState1		db		0	
KeyState2		db		0
KeybdLEDs		db		0
KeybdWaitFlag	db		0
		align	2
KeybdHead		db		0
KeybdTail		db		0
KeybdBufSz		db		0
KeybdBuf		fill.b	128,0
		align	2
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
		mov		r4,r0
		ldis	lc,#255		; 256 vectors to set
su1:
		ldi		r1,#uii_jmp
		mov		r2,r4
		bsr		set_vector	; trashes r2,r3
		addui	r4,r4,#1
		loop	su1

		; setup break vector
		lla		r1,cs:brk_jmp
		ldi		r2,#0
		bsr		set_vector

		; setup system scheduler vector
		; points to an RTE at startup
		lla		r1,cs:tms_jmp
		ldi		r2,#2
		bsr		set_vector
		lla		r1,cs:rte_jmp
		ldi		r2,#3
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

		; spurious interrupt
		;
		lla		r1,cs:spur_jmp
		ldi		r2,#192
		bsr		set_vector

		; setup MSI vector
		sh		r0,Milliseconds
		lla		r1,cs:msi_jmp
		ldi		r2,#193
		bsr		set_vector

		; setup BTNU vector
		lla		r1,cs:btnu_jmp
		ldi		r2,#200
		bsr		set_vector

		; setup KM vector
		lla		r1,cs:km_jmp
		ldi		r2,#245
		bsr		set_vector

		; setup data bus error vector
		lla		r1,cs:dbe_jmp
		ldi		r2,#251
		bsr		set_vector

		ldi		r1,#JCB_Array
		sw		r1,zs:RunningJCB_
		sw		r1,zs:IOFocusNdx_	; set I/O focus to BIOS
		ldi		r1,#TCB_Array
		sw		r1,zs:RunningTCB_
		sb		r0,zs:iof_switch_	; reset switch flag
		mov		tr,r0
		bsr		KeybdInit

		jsr		FMTKInitialize_

		; Initialize PIC
		ldi		r1,#%00000111		; nmi, time slice interrupt is edge sensitive
		sh		r1,hs:PIC_ES
		ldi		r1,#%000001111		; enable time slice interrupt, msi, nmi
		sh		r1,hs:PIC_IE

		; Initialize random number generator
		; m_z and m_w must not be zero
		ldi		r1,#$88888888
		sh		r1,m_w
		ldi		r1,#$77777777
		sh		r1,m_z

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
		rti
j1:
		ldi		r1,#2
		sc		r1,hs:LEDS
		sb		r0,EscState
		bsr		SerialInit
;		bsr		Debugger
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
p0.eq	br		.prompt
		cmpi	p0,r1,#'g'
p0.eq	bsr		GoGraphics
p0.eq	br		.prompt
		cmpi	p0,r1,#'t'
p0.eq	bsr		MonGetch
p0.eq	cmpi	p0,r1,#'x'
p0.eq	bsr		GoText
p0.eq	br		.prompt
		cmpi	p0,r1,'r'
p0.eq	bsr		RandomDots
p0.eq	br		.prompt
		cmpi	p0,r1,#'c'
p0.eq	bsr		VBClearScreen
p0.eq	mov		r1,r0
p0.eq	mov		r2,r0
p0.eq	ldi		r6,#2
p0.eq	sys		#10
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
		lhu		r1,hs:[r10]
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
		lhu		r1,hs:[r10]
		andi	r1,r1,#$3ff
		bsr		VBScreenToAscii
		addui	r10,r10,#4
		cmpi	p0,r1,#' '
p0.leu	loop	.0001
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

;------------------------------------------------------------------------------
; Go into graphics mode, four lines of text at bottom.
;------------------------------------------------------------------------------

GoGraphics:
		lhu		r3,Vidregs
		ldi		r1,#4
		sc		r1,Textrows
		sh		r1,hs:4[r3]		; # rows
		ldi		r1,#240
		sh		r1,hs:12[r3]	; window top
		mov		r1,r0			; reset cursor position
		mov		r2,r0
		ldi		r6,#2
		sys		#10
		rts

;------------------------------------------------------------------------------
; Go back to full text mode.
;------------------------------------------------------------------------------

GoText:
		lhu		r3,Vidregs
		ldi		r1,#31
		sc		r1,Textrows
		sh		r1,hs:4[r3]		; # rows
		ldi		r1,#17
		sh		r1,hs:12[r3]	; window top
		mov		r1,r0			; reset cursor position
		mov		r2,r0
		ldi		r6,#2
		sys		#10
		rts

// ----------------------------------------------------------------------------
// Uses George Marsaglia's multiply method
//
// m_w = <choose-initializer>;    /* must not be zero */
// m_z = <choose-initializer>;    /* must not be zero */
//
// uint get_random()
// {
//     m_z = 36969 * (m_z & 65535) + (m_z >> 16);
//     m_w = 18000 * (m_w & 65535) + (m_w >> 16);
//     return (m_z << 16) + m_w;  /* 32-bit result */
// }
// ----------------------------------------------------------------------------
//
gen_rand:
		addui	r31,r31,#-8
		sw		r2,[r31]
		lhu		r1,m_z
		mului	r2,r1,#36969
		shrui	r1,r1,#16
		addu	r2,r2,r1
		sh		r2,m_z

		lhu		r1,m_w
		mului	r2,r1,#18000
		shrui	r1,r1,#16
		addu	r2,r2,r1
		sh		r2,m_w
rand:
		lhu		r1,m_z
		shli	r1,r1,#16
		addu	r1,r1,r2
		lw		r2,[r31]
		addui	r31,r31,#8
		rts

// ----------------------------------------------------------------------------
// Display random dots on the graphics screen.
// ----------------------------------------------------------------------------

RandomDots:
		addui	r31,r31,#-8
		sws		c1,[r31]		; stack the return address
		mov		r4,r0
.0001:
		bsr		gen_rand		; get random bitmap memory location
		modui	r2,r1,#172032	; mod the memory size
		_2addui	r2,r2,#$FFA00000	; *2 for 16 bit data, generate address
		bsr		gen_rand		; get random color
		modui	r3,r1,#$1000	; limit to 12 bits
		sc		r3,zs:[r2]		; store color in memory
		addui	r4,r4,#1		; increment loop index
		andi	r4,r4,#$FFF		;
		tst		p1,r4			; check if time to check for keypress
p1.ne	br		.0001
		bsr		KeybdGetCharNoWait	; try get a key, but don't wait
		tst		p1,r1			; branch if no key pressed
p1.lt	br		RandomDots.0001			
		lws		c1,[r31]		; restore return address
		addui	r31,r31,#8
		rts

;------------------------------------------------------------------------------

msgStartup:	
		byte	"Thor Test System Starting...",CR,LF,0
msgStartupEnd:
msgMonitor:
		byte	CR,LF
		byte	"d  - run debugger",CR,LF
		byte	"g  - graphics mode",CR,LF
		byte	"tx - text mode",CR,LF
		byte	"r  - random dots",CR,LF
		byte	0

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
;	r1 = linear address of jump code
;	r2 = vector number to set
; Trashes: r2,r3,r5,p0
;------------------------------------------------------------------------------

set_vector:
		mfspr	r3,c12			; get base address of interrupt table
		_16addu	r2,r2,r3
		lh		r3,zs:[r1]
		cmpi	p0,r3,#$003F6F01	; unitialized interrupt number load
p0.eq	shli	r5,r2,#18
p0.eq	or		r3,r3,r5
		sh		r3,zs:[r2]
		lh		r3,zs:4[r1]
		sh		r3,zs:4[r2]
		lh		r3,zs:8[r1]
		sh		r3,zs:8[r2]
		lh		r3,zs:12[r1]
		sh		r3,zs:12[r2]
		rts

;------------------------------------------------------------------------------
; Save the register context.
;
; Parameters:
;	tr points to app's TCB
;
;------------------------------------------------------------------------------

save_context:
		sw		r1,TCB_r1[tr]
		sw		r2,TCB_r2[tr]
		sw		r3,TCB_r3[tr]
		sw		r4,TCB_r4[tr]
		sw		r5,TCB_r5[tr]
		sw		r6,TCB_r6[tr]
		sw		r7,TCB_r7[tr]
		sw		r8,TCB_r8[tr]
		sw		r9,TCB_r9[tr]
		sw		r10,TCB_r10[tr]
		sw		r11,TCB_r11[tr]
		sw		r12,TCB_r12[tr]
		sw		r13,TCB_r13[tr]
		sw		r14,TCB_r14[tr]
		sw		r15,TCB_r15[tr]
		sw		r16,TCB_r16[tr]
		sw		r17,TCB_r17[tr]
		sw		r18,TCB_r18[tr]
		sw		r19,TCB_r19[tr]
		sw		r20,TCB_r20[tr]
		sw		r21,TCB_r21[tr]
		sw		r22,TCB_r22[tr]
		sw		r23,TCB_r23[tr]
		sw		r24,TCB_r24[tr]
		sw		r25,TCB_r25[tr]
		sw		r26,TCB_r26[tr]
		sw		r27,TCB_r27[tr]
		sws		ds,TCB_ds[tr]
		sws		es,TCB_es[tr]
		sws		fs,TCB_fs[tr]
		sws		gs,TCB_gs[tr]
		sws		hs,TCB_hs[tr]
		sws		ss,TCB_ss[tr]
		sws		cs,TCB_cs[tr]
		sws		ds.lmt,TCB_dslmt[tr]
		sws		es.lmt,TCB_eslmt[tr]
		sws		fs.lmt,TCB_fslmt[tr]
		sws		gs.lmt,TCB_gslmt[tr]
		sws		hs.lmt,TCB_hslmt[tr]
		sws		ss.lmt,TCB_sslmt[tr]
		sws		cs.lmt,TCB_cslmt[tr]
		sws		c1,TCB_c1[tr]
		sws		c2,TCB_c2[tr]
		sws		c3,TCB_c3[tr]
		sws		c4,TCB_c4[tr]
		sws		c5,TCB_c5[tr]
		sws		c6,TCB_c6[tr]
		sws		c7,TCB_c7[tr]
		sws		c8,TCB_c8[tr]
		sws		c9,TCB_c9[tr]
		sws		c10,TCB_c10[tr]
		sws		c11,TCB_c11[tr]
;		sws		c13,TCB_c13[tr]
;		sws		c14,TCB_c14[tr]
		sws		pregs,TCB_pregs[tr]
		rte

;------------------------------------------------------------------------------
; Restore register context.
; Parameters:
;	DS points to app's data space.
;------------------------------------------------------------------------------

restore_context:
		lw		r1,TCB_r1[tr]
		lw		r2,TCB_r2[tr]
		lw		r3,TCB_r3[tr]
		lw		r4,TCB_r4[tr]
		lw		r5,TCB_r5[tr]
		lw		r6,TCB_r6[tr]
		lw		r7,TCB_r7[tr]
		lw		r8,TCB_r8[tr]
		lw		r9,TCB_r9[tr]
		lw		r10,TCB_r10[tr]
		lw		r11,TCB_r11[tr]
		lw		r12,TCB_r12[tr]
		lw		r13,TCB_r13[tr]
		lw		r14,TCB_r14[tr]
		lw		r15,TCB_r15[tr]
		lw		r16,TCB_r16[tr]
		lw		r17,TCB_r17[tr]
		lw		r18,TCB_r18[tr]
		lw		r19,TCB_r19[tr]
		lw		r20,TCB_r20[tr]
		lw		r21,TCB_r21[tr]
		lw		r22,TCB_r22[tr]
		lw		r23,TCB_r23[tr]
		lw		r24,TCB_r24[tr]
		lw		r25,TCB_r25[tr]
		lw		r26,TCB_r26[tr]
		lw		r27,TCB_r27[tr]
		lws		ds,TCB_ds[tr]
		lws		es,TCB_es[tr]
		lws		fs,TCB_fs[tr]
		lws		gs,TCB_gs[tr]
		lws		hs,TCB_hs[tr]
		lws		ss,TCB_ss[tr]
		lws		cs,TCB_cs[tr]
		lws		ds.lmt,TCB_dslmt[tr]
		lws		es.lmt,TCB_eslmt[tr]
		lws		fs.lmt,TCB_fslmt[tr]
		lws		gs.lmt,TCB_gslmt[tr]
		lws		hs.lmt,TCB_hslmt[tr]
		lws		ss.lmt,TCB_sslmt[tr]
		lws		cs.lmt,TCB_cslmt[tr]
		lws		c1,TCB_c1[tr]
		lws		c2,TCB_c2[tr]
		lws		c3,TCB_c3[tr]
		lws		c4,TCB_c4[tr]
		lws		c5,TCB_c5[tr]
		lws		c6,TCB_c6[tr]
		lws		c7,TCB_c7[tr]
		lws		c8,TCB_c8[tr]
		lws		c9,TCB_c9[tr]
		lws		c10,TCB_c10[tr]
		lws		c11,TCB_c11[tr]
;		lws		c13,TCB_c13[tr]
;		lws		c14,TCB_c14[tr]
		lws		pregs,TCB_pregs[tr]
		rte

.include "c:\cores4\thor\trunk\software\FMTK\source\kernel\FMTKc.s"
.include "video.asm"
.include "serial.asm"
.include "keyboard.asm"
.include "debugger.asm"


;------------------------------------------------------------------------------
; BTNU IRQ routine.
;
;------------------------------------------------------------------------------
;
btnu_rout:
		sync
		addui	r31,r31,#-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sws		hs.lmt,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

		; update on-screen IRQ live indicator
		inc.h	hs:TEXTSCR+312

		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		lws		hs.lmt,16[r31]
		addui	r31,r31,#24
		sync
		rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

spur_rout:
		sync
		addui	r31,r31,#-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sws		hs.lmt,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

;		ldi		r1,#18
;		sc		r1,hs:LEDS

		; update on-screen IRQ live indicator
		inc.h	hs:TEXTSCR+316

		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		lws		hs.lmt,16[r31]
		addui	r31,r31,#24
		sync
		rti

;------------------------------------------------------------------------------
; Uninitialized interrupt
;------------------------------------------------------------------------------
uii_rout:
		sync
		addui	r31,r31,#-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sws		hs.lmt,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

		; update on-screen IRQ live indicator
		ldi		r1,#'U'|%011000000_111111111_00_00000000
		sh		r1,hs:TEXTSCR+320

		mov		r5,r63
		sc		r63,hs:LEDS
		bsr		DisplayAddr

		ldi		r6,#2
		ldi		r2,#0
		ldi		r7,#0
.0001:
		ldis	60,#18		; set breakout index to 18
		sync
		mtspr	61,r7		; select history reg #
		sync
		ldis	60,#16		; set breakout index to 16
		sync
		mfspr	r5,61		; get address
		bsr		DisplayAddr
		addui	r2,r2,#1
		ldis	60,#17		; set breakout index to 17
		sync
		mfspr	r5,61		; get address
		bsr		DisplayAddr
		addui	r2,r2,#1
		addui	r7,r7,#1
		cmpi	p0,r7,#63
p0.ltu	br		.0001

uii_hang:
		br		uii_hang
		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		lws		hs.lmt,16[r31]
		addui	r31,r31,#24
		sync
		rti

;------------------------------------------------------------------------------
; Non-maskable interrupt routine.
;
;------------------------------------------------------------------------------
;
nmi_rout:
		sync
		addui	r31,r31,#-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sws		hs.lmt,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

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
		lws		hs.lmt,16[r31]
		addui	r31,r31,#24
		sync
		rti

;------------------------------------------------------------------------------
; Millisecond (1024 Hz) interrupt routine.
;
;------------------------------------------------------------------------------
;
msi_rout:
		sync
		addui	sp,sp,#-32
		sw		r1,[sp]
		sws		hs,8[sp]
		sws		hs.lmt,16[sp]
		sws		c1,24[sp]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

		ldi		r1,#24
		sc		r1,hs:LEDS

		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#1
		sh		r1,hs:PIC_ESR

		; update milliseconds
		lw		r1,zs:Milliseconds
		addui	r1,r1,#1
		sw		r1,zs:Milliseconds

		; restore regs and return
		lw		r1,[sp]
		lws		hs,8[sp]
		lws		hs.lmt,16[sp]
		lws		c1,24[sp]
		addui	sp,sp,#32
		sync
		rti

;------------------------------------------------------------------------------
; Time Slice IRQ routine.
;
;------------------------------------------------------------------------------
;
tms_rout:
		sync
		addui	r31,r31,#-24
		sw		r1,[r31]
		sws		hs,8[r31]
		sws		hs.lmt,16[r31]

		; set I/O segment
		ldis	hs,#$FFD00000
		ldis	hs.lmt,#$100000

		ldi		r1,#32
		sc		r1,hs:LEDS

		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#2
		sh		r1,hs:PIC_ESR

		; update on-screen IRQ live indicator
		inc.h	hs:TEXTSCR+328

		; restore regs and return
		lw		r1,[r31]
		lws		hs,8[r31]
		lws		hs.lmt,16[r31]
		addui	r31,r31,#24
		sync
		rte

;------------------------------------------------------------------------------
; Data bus error routine.
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
		ldi		r2,#10
		ldi		r6,#1
		mfspr	r5,c14
		bsr		DisplayAddr
		ldi		r6,#2
		ldi		r2,#0
		ldi		r7,#0
.0001:
		ldis	60,#18		; set breakout index to 18
		sync
		mtspr	61,r7		; select history reg #
		sync
		ldis	60,#16		; set breakout index to 16
		sync
		mfspr	r5,61		; get address
		bsr		DisplayAddr
		addui	r2,r2,#1
		ldis	60,#17		; set breakout index to 17
		sync
		mfspr	r5,61		; get address
		bsr		DisplayAddr
		addui	r2,r2,#1
		addui	r7,r7,#1
		cmpi	p0,r7,#63
p0.ltu	br		.0001

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
		ldi		r63,#00
		jmp		uii_rout[c0]
		align	8
vb_jmp:
		jmp		VideoBIOSCall[c0]
		align	8
dbe_jmp:
		jmp		dbe_rout[c0]
		align	8
svc_jmp:
		jmp		save_context[c0]
		align	8
rsc_jmp:
		jmp		restore_context[c0]
		align	8
spur_jmp:
		jmp		spur_rout[c0]
		align	8
btnu_jmp:
		jmp		btnu_rout[c0]
		align	8
rti_jmp:
km_jmp:
		rti
		align	8
rte_jmp:
		rte

;------------------------------------------------------------------------------
; Reset Point
;------------------------------------------------------------------------------

		org		$FFFFEFF0
		jmp		cold_start[c15]

extern my_main : 24

