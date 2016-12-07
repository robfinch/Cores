
; ============================================================================
;        __
;   \\__/ o\    (C) 2015-2016  Robert Finch, Stratford
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
LEDS		EQU		0xFFDC0600
SEVENSEG	EQU		0xFFDC0080
BUTTONS		EQU		0xFFDC0090
PIC_IS		EQU		0xFFDC0FC0
PIC_IE		EQU		0xFFDC0FC2
PIC_ES		EQU		0xFFDC0FC8
PIC_ESR		EQU		0xFFDC0FCA		; edge sense reset
TEXTSCR		EQU		0xFFD00000
TEXTCTRL	EQU		0xFFDA0000
TEXTCOLS	EQU		0xFFDA0000
TEXTROWS	EQU		0xFFDA0002

	bss
	org	$00000000
_interrupt_table:
vba:	fill.w	1,0x00
	org	$406
m_w				dw		0
m_z				dw		0
_DBGCursorRow	dw	0
_DBGCursorCol	dw	0
_DBGAttr		dw	0
_sys_sema		dw	0
_iof_sema		dw	0

		data
		org		$01000000
		bss
		org		$00C00000

Milliseconds	dw		0
FMTK_SchedulerIRQ_vec	dw	0
_Running		dw		0
;IOFocusNdx_		dw		0
;iof_switch_		db		0
		align	8
_NextRdy		dw		0
_PrevRdy		dw		0

KeyState1		dh		0	
KeyState2		dh		0
KeybdLEDs		dh		0
KeybdWaitFlag	dh		0
		align	2
KeybdHead		dh		0
KeybdTail		dh		0
KeybdBufSz		dh		0
KeybdBuf		fill.h	128,0
		align	2
DBGCursorX		dh		0
DBGCursorY		dh		0
CursorX			dh		0
CursorY			dh		0
VideoPos		dh		0
		align	4
NormAttr		dw		0
Vidregs			dw		0
Vidptr			dw		0
EscState		dh		0
Textrows		dh		0
Textcols		dh		0
		align	8
reg_save		fill.w	64,0
creg_save		fill.w	16,0
sreg_save		fill.w	16,0
preg_save		dw		0


rxfull     EQU      1
Uart_ms         dh      0
Uart_txxonoff   dh      0
Uart_rxhead     dh      0
Uart_rxtail     dh      0
Uart_rxflow     dh      0
Uart_rxrts      dh      0
Uart_rxdtr      dh      0
Uart_rxxon      dh      0
Uart_foff       dh      0
Uart_fon        dh      0
Uart_txrts      dh      0
Uart_txdtr      dh      0
Uart_txxon      dh      0
Uart_rxfifo     fill.h  512,0

NUMWKA          fill.h  64,0

;----------------------------------------------------------------------------
; Reset Point
;----------------------------------------------------------------------------

	code 17 bits
	org		$FFFC0000


cold_start:
{+      ; use expanded instruction set
	   ldi	 sp,#$00001FFE	; initialize kernel IRQ SP
	   ldi	 bp,#$00001FFE	; initialize kernel IRQ BP
;	   ldi	 sp,#$01FFFFFE	; initialize kernel IRQ SP
;	   ldi	 bp,#$01FFFFFE	; initialize kernel IRQ BP

;		lf.q	fp18,pi_val
;		ldi		r18,#20
;		ldi		r19,#16
;		ldi		r20,#'E'
;		call	_prtflt

       ldi   r4,#$FFFE0000  ; base address of cpu ciTable
	   csrrw r0,#$11,r4		; update table address in CISC CSR
       ldi   r1,#citable    ; point to compression table
       lhu   r2,[r1]        ; r2 = count of entries
	   beq	 r2,r0,.cs4		; if no table entries
       addi  r1,r1,#1
.cs3:	
       lw    r3,[r1]        ; r3 = entry
       sw    r3,[r4]        ; store in cpu table
       addi  r1,r1,#2		; update address
       addi  r4,r4,#2       ; advance to next word
       addi  r2,r2,#-1      ; decrement count
	   bge   r2,#0,.cs3		; branch if non-zero
       jmp   .cs4[pc]       ; flush pipeline
+}
.cs4:
	   sw		r0,_out_fh	; set direct output to debug screen
	   call	 init_irqtable
	   call		_InitPIC
	   cli
		ldi		r1,#$0003
		sh		r1,LEDS
        call	SetupMMU[pc]
		ldi		r1,#$0004
		sh		r1,LEDS
		call	Tc1Init
		call	clearTxtScreen[pc]
		ldi		r1,#$0005
		sh		r1,LEDS
		; setup random number generator with non-zero values
		; also LSB16 can't be zero
		ldi		r1,#$88888888
		sw		r1,m_w
		ldi		r1,#$12345678
		sw		r1,m_z
		lw		r1,m_w
		sw		r1,SEVENSEG
		ldi		r1,#4			; down button
		call	WaitForButton
		call	RandomizeTextScreen[pc]
		call	DBGHomeCursor
		ldi		r18,#msgHello
		call	DBGPrtstr
		ldi		r1,#1
		call	WaitForButton
		ldi		r1,#$0005
		sh		r1,LEDS
		call	copy_preinit_data[pc]
		ldi		r1,#$0006
		sh		r1,LEDS
		//call	_FMTKInitialize[pc]
		ldi		r1,#%000010000_111111111_0000000000
		sw		r1,_DBGAttr
		call	_BIOSMain[pc]
		ldi		r1,#13
		sh		r1,LEDS
.cs5:
		bra		.cs5		; hang the machine

		align	8
pi_val:
dw	0x8BDA3F4E,0x84698972,0xB54442D1,0x4000921F

;----------------------------------------------------------------------------
; copy pre-initialized data to data area
;----------------------------------------------------------------------------
copy_preinit_data:
		    ldi		r2,#begin_init_data
		    ldi		r3,#$1000000
.j1:
			sh		r3,SEVENSEG
		    lw		r1,[r2]
		    sw		r1,[r3]
			addi	r2,r2,#2
		    addi	r3,r3,#2
			bltu	r2,#end_init_data,.j1
		    ldi		r1,#$FFFD
		    sh		r1,LEDS
			ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

init_irqtable:
		ldi		r1,#irq_routine	; set the address for IRQ's
		csrrw	r0,#4,r1
		ldi		r1,#1022
.j1:
		sw		r0,[r1]
		sub		r1,r1,#2
		bgtu	r1,r0,.j1
		sw		r0,[r0]
		ldi		r18,#10
		ldi		r19,#VideoBIOSCall
		call	_set_vector
		ldi		r18,#432+3
		ldi		r19,#irq30Hz
		call	_set_vector
		ldi		r18,#508
		ldi		r19,#_DBERout
		call	_set_vector
		ldi		r18,#432+30
		ldi		r19,#_BTNCIRQHandler
		call	_set_vector
		ldi		r18,#509
		ldi		r19,_IBERout
		call	_set_vector
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
		align	16
irq_routine:
		csrrw	r1,#6,r0	; get the cause code
		beq		r1,r0,.j1	; no cause
		shl		r1,r1,#1
		lw		r1,_interrupt_table[r1]	; load vector from table
		beq		r1,r0,.j1
		jmp		[r1]		; and jump to it
.j1:
		iret

;----------------------------------------------------------------------------
; 30 Hz interrupt
; - invoke system scheduler
;----------------------------------------------------------------------------

irq30Hz:
		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#3
		sw		r1,PIC_ESR
		; update on-screen IRQ live indicator
		inc		TEXTSCR+168,#1
		lw		r1,4[r0]	; get scheduler vector
		beq		r1,r0,.j1
		jmp		[r1]
.j1:
		iret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
BTNCIRQRout:
		ldi		r1,#30		; reset edge sense circuit
		sw		r1,PIC_ESR
		push	r3
		push	r4
		push	r5
		push	r6
		push	r7
		push	r8
		push	r9
		push	r10
		push	r11
		push	r12
		push	r13
		push	r14
		push	r15
		push	r16
		push	r17
		push	r18
		push	r19
		push	r20
		push	r21
		push	r22
		push	r23
		push	r24
		push	r25
		push	r26
		push	r27
		push	r28
		push	r29
		push	r30
		call	_BTNCIRQHandler
		pop		r30
		pop		r29
		pop		r28
		pop		r27
		pop		r26
		pop		r25
		pop		r24
		pop		r23
		pop		r22
		pop		r21
		pop		r20
		pop		r19
		pop		r18
		pop		r17
		pop		r16
		pop		r15
		pop		r14
		pop		r13
		pop		r12
		pop		r11
		pop		r10
		pop		r9
		pop		r8
		pop		r7
		pop		r6
		pop		r5
		pop		r4
		pop		r3
		iret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
TestFP:
	   ldi		r1,#$0
	   sw		r1,0
	   sw		r1,2
	   sw		r1,4
	   ldi		r1,#%01000000_00000010_01000000_00000000
	   sw		r1,6
	   lf.q		fp0,0
	   lf.q		fp1,0
	   fadd.q	fp2,fp0,fp1	// 10.0+10.0
	   fmul.q	fp3,fp0,fp1	// 10.0*10.0
	   fsub.q	fp4,fp0,fp1	// 10.0-10.0
	   fadd.q	fp5,fp3,fp3	// 100.0+100.0
	   fdiv.q	fp6,fp3,fp1	// 100.0/10.0
	   fdiv.q	fp7,fp0,fp1	// 10.0/10.0
	   fdiv.q	fp8,fp5,fp1	// 200.0/10.0
	   fdiv.q	fp9,fp1,fp5	// 10.0/200.0
	   fcmp.q	r2,fp0,fp1
	   push.q	fp1
	   push.q	fp2
	   pop.q	fp11
	   pop.q	fp12
	   bbs		r2,#0,.cs5	// Get the equals bit
.cs5:
		lf.q	fp0,zero
		lf.q	fp1,negzero
		fcmp.q	r3,fp0,fp1	// Test 0.0 = -0.0
		lf.q	fp1,ten
		fneg.q	fp10,fp1	// check negation (sign bit inverts)
		ret

//----------------------------------------------------------------------------
//	r1 = button to wait for
//		1 = right button
//		2 = left button
//		4 = down button
//		8 = up button
//		16 = centre button.
//----------------------------------------------------------------------------

WaitForButton:
		push	r2
		; wait for button pressed
.j1:
		lhu		r2,BUTTONS
		and		r2,r2,r1
		beq		r2,r0,.j1

.j2:	; wait for button release
		lhu		r2,BUTTONS
		and		r2,r2,r1
		bne		r2,r0,.j2
		pop		r2
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
clearTxtScreen:
		ldi		r4,#$0024
		sh		r4,LEDS
		ldi		r1,#$FFD00000	; text screen address
		ldi		r2,#2604		; number of chars 2604 (84x31)
		ldi		r3,#%000010000_111111111_0000100000
		ldi		r4,#$0025
		sh		r4,LEDS
.cts1:
		sw		r3,[r1]
		add		r1,r1,#2
		sub		r2,r2,#1
		ldi		r4,#$0026
		sh		r4,LEDS
		bne		r2,#0,.cts1
		ldi		r1,#$0027
		sh		r1,LEDS
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
RandomizeTextScreen:
		ldi		r3,#24
		sh		r3,LEDS
.j1:
		sh		r3,LEDS
		add		r3,r3,#1
		call	gen_rand[pc]
		mov		r2,r1
		call	gen_rand[pc]
		and		r2,r2,#$FFE
		ldi		r4,#TEXTSCR
		mod		r2,r3,#2604*2
		add		r4,r4,r2
		sw		r4,SEVENSEG
		sw		r1,[r4]
		lhu		r1,BUTTONS
		bbc		r1,#2,.j1
		ret

// ----------------------------------------------------------------------------
// Initialize text controller #1
// ----------------------------------------------------------------------------

Tc1Init:
		ldi		r1,#$FFDA0000
		ldi		r2,#Tc1InitTab
.j1:
		lhu		r3,[r2]
		sw		r3,[r1]
		add		r1,r1,#2
		add		r2,r2,#1
		bltu	r1,#$FFDA0020,.j1
		ret

		align	2

// The text controller registers are aligned on word addresses but they are
// really only 16 bit wide.
// For some reason the display memory is offset by two characters. Hence the
// special constant $FFFE as the start of displayed area rather than $0000.

Tc1InitTab:
		dh		$3054	//  3=char out delay, 84 columns
		dh		31	// rows
		dh		66	// left
		dh		16	// top
		dh		 7	// max scan line
		dh		$21	// pixel height, width
		dh		0		// reserved - not used
		dh		%110000110	// transparent color
		dh		$0E0	// cursor controls
		dh		31		// cursor end
		dh		$FFFE	// display start address
		dh		$0000	// cursor position
		dh		0		// light pen (read only)
		dh		0		// scratchpad 1
		dh		0		// scratchpad 2
		dh		0		// scratchpad 3

;----------------------------------------------------------------------------
; Setup MMU
;
; Sets up map #0 so that virtual and physical addresses match.
;----------------------------------------------------------------------------
SetupMMU:
		ldi		r1,#$0014
		sh		r1,LEDS
		csrrw	r0,#3,r0		; access map #0, disable paging
		ldi		r1,#$FFDC4000	; mapping table address
		ldi		r2,#1024		; number of map entries
		ldi		r3,#0
.smmu1:
		sh		r3,[r1]
		addi	r3,r3,#1
		addi	r1,r1,#1
		subi	r2,r2,#1
		bne		r2,r0,.smmu1
		csrrs	r0,#3,#$80000000	; turn on paging
		ldi		r1,#$0015
		sh		r1,LEDS
		; The following ret should only work if paging was setup
		; correctly.
		ret

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
		push	r2
		lw		r1,m_z
		and		r1,r1,#$FFFF
		mulu	r2,r1,#36969
		lw		r1,m_z
		shru	r1,r1,#16
		add		r2,r2,r1
		sw		r2,m_z

		lw		r1,m_w
		and		r1,r1,#$FFFF
		mulu	r2,r1,#18000
		lw		r1,m_w
		shru	r1,r1,#16
		add		r2,r2,r1
		sw		r2,m_w
		pop		r2
rand:
		push	r2
		lw		r2,m_w
		lw		r1,m_z
		shl		r1,r1,#16
		add		r1,r1,r2
		pop		r2
		ret

zero:		dw	0,0,0,0
negzero:	dw	0,0,0,0x80000000
ten:		dw	0,0,0,%01000000_00000010_01000000_00000000
pi:			dw	0,0,$54442D18,$400921FB		// PI to 19 digits accuracy

;----------------------------------------------------------------------------
; 'C' calling conventions in use.
;
; Parameters:
;	r18 = pointer to string
; Returns:
;	r1 = length of string
;----------------------------------------------------------------------------

_strlen2:
		push	r3
		mov		r1,r0		; length = 0
.j1:
		lhu		r3,[r1+r18]
		addi	r1,r1,#1
		bne		r3,r0,.j1
.xit:
		subi	r1,r1,#1
		pop		r3
		ret

;----------------------------------------------------------------------------
; 'C' calling conventions in use.
;
; Parameters:
;	r18 = pointer to destination string
;	r19 = pointer to source string
;
; Returns:
;	r1 = pointer to destination string
;----------------------------------------------------------------------------

_strcpy2:
		push	r3
		mov		r1,r0
.j1:
		lhu		r3,[r19+r1]
		sh		r3,[r18+r1]
		addi	r1,r1,#1
		bne		r3,r0,.j1
		pop		r3
		mov		r1,r18
		ret

.include "c:\cores4\DSD\trunk\software\bootrom\source\BIOSMain.s"
.include "c:\cores4\DSD\trunk\software\bootrom\source\FloatTest.s"
.include "c:\cores4\DSD\trunk\software\bootrom\source\ramtest.s"
.include "c:\cores4\DSD\trunk\software\c64libc\source\stdio.s"
.include "c:\cores4\DSD\trunk\software\c64libc\source\ctype.s"
.include "c:\cores4\DSD\trunk\software\c64libc\source\string.s"
.include "c:\cores4\DSD\trunk\software\c64libc\source\DSD7\io.s"
.include "c:\cores4\DSD\trunk\software\c64libc\source\prtflt.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\LockSemaphore.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\UnlockSemaphore.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\console.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\PIC.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\FMTKc.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\FMTKmsg.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\TCB.s"
.include "c:\cores4\DSD\trunk\software\FMTK\source\kernel\IOFocusc.s"
.include "c:\cores4\DSD\trunk\software\bootrom\source\video.asm"

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

	.code
	align	8
DBGHomeCursor:
	push	r18
	push	r19
	mov		r18,r0
	mov		r19,r0
	call	DBGSetCursorPos[pc]
	pop		r19
	pop		r18
	ret

DBGSetCursorPos:
	sh		r18,DBGCursorX
	sh		r19,DBGCursorY
	push	r19
	mulu	r19,r19,#84
	add		r19,r19,r18
	sw		r19,$FFDA0016
	pop		r19
	ret

DBGPutchar:
	push	r2
	push	r3
	call	_AsciiToScreen
	or		r1,r1,#%000010000_111111111_0000000000
	lhu		r2,DBGCursorX
	lhu		r3,DBGCursorY
	shl		r2,r2,#1
	mulu	r3,r3,#84*2
	add		r3,r3,r2
	sw		r1,TEXTSCR[r3]
	lhu		r2,DBGCursorX
	add		r2,r2,#1
	bltu	r2,#84,.j1
	mov		r2,r0
	sh		r0,DBGCursorX
	lhu		r3,DBGCursorY
	add		r3,r3,#1
	sh		r3,DBGCursorY
.j2:
	mulu	r3,r3,#84
	add		r3,r3,r2
	sw		r3,$FFDA0016
	pop		r3
	pop		r2
	ret
.j1:
	sh		r2,DBGCursorX
	lhu		r3,DBGCursorY
	bra		.j2

DBGPrtstr:
	push	r18
	mov		r1,r18
.j2:
	lhu		r18,[r1]
	beq		r18,r0,.j1
	push	r1
	call	DBGPutchar[pc]
	pop		r1
	add		r1,r1,#1
	bra		.j2
.j1:
	pop		r18
	ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

msgHello:
	dh	"Hello World!",0
		
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

citable:
    dh_htbl
;{+                                                                             
;	org		$FFFFFFF4
;	jmp		cold_start[pc]
;	org		$FFFFFFF8
;	jmp		irq_routine[pc]
;+}

