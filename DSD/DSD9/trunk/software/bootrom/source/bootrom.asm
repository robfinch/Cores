
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
PIC_IE		EQU		0xFFDC0FC4
PIC_ES		EQU		0xFFDC0FD0
PIC_ESR		EQU		0xFFDC0FD4		; edge sense reset
TEXTSCR		EQU		0xFFD00000
TEXTCTRL	EQU		0xFFDA0000
TEXTCOLS	EQU		0xFFDA0000
TEXTROWS	EQU		0xFFDA0002

	bss
	org	$00000000
_interrupt_table:
vba:	fill.w	1,0x00
; $0000 to $13F5 is interrupt table
	org	$1400
m_w				dd		0
m_z				dd		0
_DBGCursorRow	dt	0
_DBGCursorCol	dt	0
_DBGAttr		dt	0
_sys_sema		dt	0
_iof_sema		dt	0

		data
		org		$01000000
		bss
		org		$00C00000

Milliseconds	dt		0
FMTK_SchedulerIRQ_vec	dw	0
_Running		dt		0
;IOFocusNdx_		dt		0
;iof_switch_		db		0
		align	8
_NextRdy		dt		0
_PrevRdy		dt		0

KeyState1		dt		0	
KeyState2		dt		0
KeybdLEDs		dt		0
KeybdWaitFlag	dt		0
		align	2
KeybdHead		dt		0
KeybdTail		dt		0
KeybdBufSz		dt		0
KeybdBuf		fill.t	128,0
		align	2
DBGCursorX		dt		0
DBGCursorY		dt		0
DBGAttr			dt		0
CursorX			dt		0
CursorY			dt		0
VideoPos		dt		0
		align	4
NormAttr		dt		0
Vidregs			dt		0
Vidptr			dt		0
EscState		dt		0
Textrows		dt		0
Textcols		dt		0
		align	8
reg_save		fill.d	64,0
creg_save		fill.d	16,0
sreg_save		fill.d	16,0
preg_save		dd		0


rxfull     EQU      1
Uart_ms         db      0
Uart_txxonoff   db      0
Uart_rxhead     dw      0
Uart_rxtail     dw      0
Uart_rxflow     db      0
Uart_rxrts      db      0
Uart_rxdtr      db      0
Uart_rxxon      db      0
Uart_foff       db      0
Uart_fon        db      0
Uart_txrts      db      0
Uart_txdtr      db      0
Uart_txxon      db      0
Uart_pad        db      0
Uart_rxfifo     fill.b  512,0

NUMWKA          fill.b  64,0

;----------------------------------------------------------------------------
; Reset Point
;----------------------------------------------------------------------------

	code 17 bits
	org		$FFFC0000
	jmp		ul_irq_routine[pc]
	org		$FFFC0040
	jmp		sl_irq_routine[pc]
	org		$FFFC0080
	jmp		hl_irq_routine[pc]
	org		$FFFC00C0
	jmp		ml_irq_routine[pc]
	org		$FFFC0100
	jmp		nmi_rout[pc]
	org		$FFFC0140
cold_start:
{+      ; use expanded instruction set
		ldi		r1,#$0001
		stw		r1,LEDS
		ldi		sp,#$00003FFE	; initialize kernel IRQ SP
	   ldi		bp,#$00003FFE	; initialize BP
	   ; setup stack lower bounds regs
	   ldi		r1,#0
	   csrrw	r0,#$000E,r1
	   csrrw	r0,#$100E,r1
	   csrrw	r0,#$200E,r1
	   csrrw	r0,#$300E,r1
	   ; setup stack upper bounds regs
	   ldi		r1,#-2
	   csrrw	r0,#$000F,r1
	   csrrw	r0,#$100F,r1
	   csrrw	r0,#$200F,r1
	   csrrw	r0,#$300F,r1
		ldi		r1,#$0002
		stw		r1,LEDS

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; Setup MMU.
		; Can't use the stack until after the MMU is setup.
		; For the OS 4MiB pages are used and physical addresses
		; are set to match virtual addresses.
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		ldi		r1,#1
		csrrw	r0,#8,r1		; select 4MiB pages
		csrrw	r0,#3,r0		; set access key to map 0
		ldi		r1,#$FFDC4000	; mapping table address
		mov		r2,r0
.cs1:
		or		r3,r2,#$70000	; set read/write/execute
		stt		r3,[r1+r2*4]
		add		r2,r2,#1
		bltu	r2,#1024,.cs1
		csrrs	r0,#3,#$80000000	; turn on paging
		ldi		r1,#$0003
		stw		r1,LEDS

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;	   ldi	 sp,#$01FFFFFE	; initialize kernel IRQ SP
;	   ldi	 bp,#$01FFFFFE	; initialize kernel IRQ BP

       ldi   r4,#$FFFE0000  ; base address of cpu ciTable
	   csrrw r0,#$11,r4		; update table address in CISC CSR
       ldi   r1,#citable    ; point to compression table
       ldwu  r2,[r1]        ; r2 = count of entries
	   beq	 r2,r0,.cs4		; if no table entries
       add   r1,r1,#2
.cs3:	
       ldp   r3,[r1]        ; r3 = entry
       stp   r3,[r4]        ; store in cpu table
       add   r1,r1,#5		; update address
       add   r4,r4,#1       ; advance to next word
       add   r2,r2,#-1      ; decrement count
	   bge   r2,#0,.cs3		; branch if non-zero
       jmp   .cs4[pc]       ; flush pipeline
+}
.cs4:
	   stw		r0,_out_fh	; set direct output to debug screen
		ldi		r1,#$0003
		stw		r1,LEDS
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
		call	init_lifegame[pc]
		ldi		r1,#$0004
		stw		r1,LEDS
	   call		init_irqtable[pc]
		ldi		r1,#$0004
		stw		r1,LEDS
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
	   call		_InitPIC[pc]
		ldi		r1,#$0005
		stw		r1,LEDS
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
;        call	SetupMMU[pc]
		ldi		r1,#$0006
		stw		r1,LEDS
		call	Tc1Init[pc]
		ldi		r1,#$0007
		stw		r1,LEDS
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
		call	clearTxtScreen[pc]
		ldi		r1,#$0008
		stw		r1,LEDS
		ldi		r1,#%000010000_111111111_0000000000
		stt		r1,_DBGAttr
		call	_DBGHomeCursor
		ldi		r18,#msgHello
		mark1
		call	_DBGDisplayString[pc]
		; setup random number generator with non-zero values
		; also LSB16 can't be zero
		ldi		r1,#$8888888888
		std		r1,m_w
		ldi		r1,#$1234567890
		std		r1,m_z
		ldd		r1,m_w
		stt		r1,SEVENSEG
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
		call	RandomizeTextScreen[pc]
		ldi		r1,#$0009
		stw		r1,LEDS
		ldi		r1,#4			; down button
		call	WaitForButton[pc]
		ldi		r1,#%000010000_111111111_0000000000
		stt		r1,DBGAttr
		call	DBGHomeCursor
		ldi		r18,#msgHello
		call	DBGPrtstr[pc]
		ldi		r1,#$000A
		stw		r1,LEDS
		ldi		r1,#1			; right button
		call	WaitForButton[pc]
		call	copy_preinit_data[pc]
		ldi		r1,#$000B
		stw		r1,LEDS
		ldi		r1,#$000C
		stw		r1,LEDS
		//call	_FMTKInitialize[pc]
		ldi		r1,#%000010000_111111111_0000000000
		stt		r1,_DBGAttr
		cli
		call	_BIOSMain[pc]
		ldi		r1,#13
		stw		r1,LEDS
.cs5:
		bra		.cs5		; hang the machine

		align	8
pi_val:
dd	0x4000921FB54442D18469
;dw	0x8BDA3F4E,0x84698972,0xB54442D1,0x4000921F

;----------------------------------------------------------------------------
; copy pre-initialized data to data area
;----------------------------------------------------------------------------
		align	16
copy_preinit_data:
			tgt
		    ldi		r2,#begin_init_data
		    ldi		r3,#$1000000
.j1:
			stt		r3,SEVENSEG
		    ldd		r1,[r2]
		    std		r1,[r3]
			add		r2,r2,#10
		    add		r3,r3,#10
			bltu	r2,#end_init_data,.j1
		    ldi		r1,#$FFFD
		    stt		r1,LEDS
			ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

init_irqtable:
		tgt
		ldi		r1,#irq_routine	; set the address for IRQ's
		csrrw	r0,#4,r1
		ldi		r1,#10
		ldi		r2,#uninit_interrupt
.j1:
		stw		r1,LEDS
		std		r2,[r1]
		add		r1,r1,#10
		bltu	r1,#5110,.j1
		std		r0,[r0]
		ldi		r18,#10
		ldi		r19,#VideoBIOSCall
		call	_set_vector
		ldi		r18,#432+3
		ldi		r19,#irq30Hz
		call	_set_vector
		ldi		r18,#432+30
		ldi		r19,#_BTNCIRQHandler
		call	_set_vector
		ldi		r18,#508
		ldi		r19,#_DBERout
		call	_set_vector
		ldi		r18,#509
		ldi		r19,_IBERout
		call	_set_vector
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
		align	16
uninit_interrupt:
		push	r1
		push	r2
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
		push	r58
		push	r59
		ldi		r18,#msgUninitIRQ
		call	_DBGDisplayString
		pop		r59
		pop		r58
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
		pop		r2
		pop		r1
		iret

		align	2
msgUninitIRQ:
	dw	"Uninitialized exception.\r\n", 0

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
		align	16
ul_irq_routine:
sl_irq_routine:
hl_irq_routine:
ml_irq_routine:
irq_routine:
		csrrw	r60,#6,r0	; get the cause code
		beq		r60,r0,.j1	; no cause
		mulu	r60,r60,#10
		ldd		r60,_interrupt_table[r60]	; load vector from table
		jmp		[r60]		; and jump to it
.j1:
		iret

;----------------------------------------------------------------------------
; 30 Hz interrupt
; - invoke system scheduler
;----------------------------------------------------------------------------

irq30Hz:
		; reset the edge sense circuit to re-enable interrupts
		ldi		r1,#3
		stt		r1,PIC_ESR
		; update on-screen IRQ live indicator
		inc		TEXTSCR+164,#1
//		ldd		r1,_interrupt_table+40	; get scheduler vector
//		beq		r1,r0,.j1
//		jmp		[r1]
.j1:
		iret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
BTNCIRQRout:
		ldi		r60,#30		; reset edge sense circuit
		stt		r60,PIC_ESR
		push	r1
		push	r2
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
		push	r58
		push	r59
		call	_BTNCIRQHandler
		pop		r59
		pop		r58
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
		pop		r2
		pop		r1
		iret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
TestFP:
	   tgt
	   ldi		r1,#$0
	   stt		r1,0
	   stt		r1,2
	   stt		r1,4
	   ldi		r1,#%01000000_00000010_01000000_00000000
	   stt		r1,6
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
		tgt
		push	r2
		; wait for button pressed
.j1:
		ldwu	r2,BUTTONS
		stw		r2,SEVENSEG
		bfextu	r2,r2,#2,#2
		beq		r2,r0,.j1

.j2:	; wait for button release
		ldwu	r2,BUTTONS
		stw		r2,SEVENSEG
		bfextu	r2,r2,#2,#2
		bne		r2,r0,.j2
		ldi		r2,#123456
		stt		r2,SEVENSEG
		pop		r2
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
clearTxtScreen:
		tgt
		ldi		r4,#$0024
		stw		r4,LEDS
		ldi		r1,#$FFD00000	; text screen address
		ldi		r2,#2604		; number of chars 2604 (84x31)
		ldi		r3,#%000010000_111111111_0000100000
.cts1:
		stt		r3,[r1]
		add		r1,r1,#4
		sub		r2,r2,#1
		bne		r2,#0,.cts1
		ret

// ----------------------------------------------------------------------------
// Fill the text screen with random characters and colors.
// ----------------------------------------------------------------------------

RandomizeTextScreen:
		tgt
		ldi		r4,#TEXTSCR
		ldi		r3,#24
		stw		r3,LEDS
.j1:
		call	gen_rand[pc]
		mov		r2,r1
		call	gen_rand[pc]
		modu	r1,r1,#2604
		ldi		r4,#TEXTSCR
		stt		r2,[r4+r1*4]
		stt		r1,SEVENSEG
		ldwu	r1,BUTTONS
		bbc		r1,#2,.j1
		ret

// ----------------------------------------------------------------------------
// Initialize text controller #1
// ----------------------------------------------------------------------------

Tc1Init:
		tgt
		ldi		r1,#$FFDA0000
		ldi		r2,#Tc1InitTab
.j1:
		ldwu	r3,[r2]
		stt		r3,[r1]
		add		r1,r1,#4
		add		r2,r2,#2
		bltu	r1,#$FFDA0030,.j1
		ret

		align	2

// The text controller registers are aligned on word addresses but they are
// really only 16 bit wide.
// For some reason the display memory is offset by two characters. Hence the
// special constant $FFFE as the start of displayed area rather than $0000.

Tc1InitTab:
		dw		$3054	//  3=char out delay, 84 columns
		dw		31	// rows
		dw		66	// left
		dw		16	// top
		dw		 7	// max scan line
		dw		$21	// pixel height, width
		dw		0		// reserved - not used
		dw		%110000110	// transparent color
		dw		$0E0	// cursor controls
		dw		31		// cursor end
		dw		$FFFE	// display start address
		dw		$0000	// cursor position
		dw		0		// light pen (read only)
		dw		0		// scratchpad 1
		dw		0		// scratchpad 2
		dw		0		// scratchpad 3

// ----------------------------------------------------------------------------
// Setup MMU
//
// Sets up map #0 so that virtual and physical addresses match then turns
// on paging.
// The MMU only handles wyde data.
// ----------------------------------------------------------------------------
		align	16
SetupMMU:
		tgt
		ldi		r1,#$0014
		stw		r1,LEDS
		csrrw	r0,#3,r0		; access map #0, disable paging
		ldi		r1,#$FFDC4000	; mapping table address
		ldi		r2,#1024		; number of map entries
		ldi		r3,#0
.smmu1:							
		or		r4,r3,#$70000		; readable/writable/executable
		stt		r4,[r1+r3*4]
		add		r3,r3,#1
		bltu	r3,r2,.smmu1
		csrrs	r0,#3,#$80000000	; turn on paging
		ldi		r1,#$0015
		stw		r1,LEDS
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
		tgt
		push	r2
		ldd		r1,m_z
		and		r1,r1,#$FFFFFFFFFF
		mulu	r2,r1,#36969696969
		ldd		r1,m_z
		shru	r1,r1,#40
		add		r2,r2,r1
		std		r2,m_z

		ldd		r1,m_w
		and		r1,r1,#$FFFFFFFFFF
		mulu	r2,r1,#18000000000
		ldd		r1,m_w
		shru	r1,r1,#40
		add		r2,r2,r1
		std		r2,m_w
		pop		r2
rand:
		tgt
		push	r2
		ldd		r2,m_w
		ldd		r1,m_z
		shl		r1,r1,#40
		add		r1,r1,r2
		pop		r2
		ret

zero:		dd	0
negzero:	dd	0x80000000000000000000
ten:		dt	0,0,0,%01000000_00000010_01000000_00000000
pi:			dt	0,0,$54442D18,$400921FB		// PI to 19 digits accuracy

;----------------------------------------------------------------------------
; 'C' calling conventions in use.
;
; Parameters:
;	r18 = pointer to string
; Returns:
;	r1 = length of string
;----------------------------------------------------------------------------
		align	16
_strlen2:
		push	r3
		mov		r1,r0		; length = 0
.j1:
		ldwu	r3,[r1+r18]
		addi	r1,r1,#2
		bne		r3,r0,.j1
.xit:
		subi	r1,r1,#2
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
		ldwu	r3,[r19+r1]
		stw		r3,[r18+r1]
		addi	r1,r1,#2
		bne		r3,r0,.j1
		pop		r3
		mov		r1,r18
		ret

.include "c:\cores4\DSD\DSD9\trunk\software\bootrom\source\BIOSMain.s"
.include "c:\cores4\DSD\DSD9\trunk\software\bootrom\source\FloatTest.s"
.include "c:\cores4\DSD\DSD9\trunk\software\bootrom\source\ramtest.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\stdio.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\ctype.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\string.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\DSD9\io.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\prtflt.s"
.include "c:\cores4\DSD\DSD9\trunk\software\c64libc\source\libquadmath\log10q.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\LockSemaphore.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\UnlockSemaphore.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\console.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\PIC.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\FMTKc.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\FMTKmsg.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\TCB.s"
.include "c:\cores4\DSD\DSD9\trunk\software\FMTK\source\kernel\IOFocusc.s"
.include "c:\cores4\DSD\DSD9\trunk\software\bootrom\source\video.asm"
//.include "c:\cores4\DSD\DSD9\trunk\software\bootrom\source\TinyBasicDSD\DSD9.s"

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

	.code
	align	16
DBGHomeCursor:
	tgt
	push	r18
	push	r19
	mov		r18,r0
	mov		r19,r0
	call	DBGSetCursorPos[pc]
	pop		r19
	pop		r18
	ret

DBGSetCursorPos:
	tgt
	stw		r18,DBGCursorX
	stw		r19,DBGCursorY
	push	r19
	mulu	r19,r19,#84
	add		r19,r19,r18
	stt		r19,$FFDA002C
	pop		r19
	ret

DBGPutchar:
	tgt
	push	r2
	push	r3
	call	_AsciiToScreen
	or		r1,r1,#%000010000_111111111_0000000000
	ldwu	r2,DBGCursorX
	ldwu	r3,DBGCursorY
	shl		r2,r2,#2
	mulu	r3,r3,#84*4
	add		r3,r3,r2
	stt		r1,TEXTSCR[r3]
	ldwu	r2,DBGCursorX
	add		r2,r2,#1
	bltu	r2,#84,.j1
	mov		r2,r0
	stw		r0,DBGCursorX
	ldwu	r3,DBGCursorY
	add		r3,r3,#1
	stw		r3,DBGCursorY
.j2:
	mulu	r3,r3,#84
	add		r3,r3,r2
	stt		r3,$FFDA002C
	pop		r3
	pop		r2
	ret
.j1:
	stw		r2,DBGCursorX
	ldwu	r3,DBGCursorY
	bra		.j2

DBGPrtstr:
	tgt
	push	r18
	mov		r1,r18
.j2:
	ldwu	r18,[r1]
	beq		r18,r0,.j1
	push	r1
	call	DBGPutchar[pc]
	pop		r1
	add		r1,r1,#2
	bra		.j2
.j1:
	pop		r18
	ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

msgHello:
	dw	"Hello World!",0
		
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
	align	16
init_lifegame:
	ldi		r5,#$FFD30000
	; first clear out the environment
	mov		r2,r0
	mov		r3,r0
.life1:
	stt		r0,[r5+r2*4]
	add		r2,r2,#1
	bltu	r2,#16,.life1
.life2:
	stt		r3,64[r5]			; set the row to load
	ldi		r4,#1
	stt		r4,68[r5]			; pulse load bit
	add		r3,r3,#1
	bltu	r3,#256,.life2
	; now add some random data
.life3:
	call	gen_rand[pc]
	mov		r3,r1,#$FF
	call	gen_rand[pc]
	mov		r2,r1
	call	gen_rand[pc]
	and		r1,r1,#$F
	stt		r3,64[r5]			; set the row (random)
	; zero out all the row
	mov		r6,r0
.life4:
	stt		r0,[r5+r6*4]
	add		r6,r6,#1
	bltu	r6,#16,.life4
	stt		r2,[r5+r1*4]		; set data word within row (random)
	ldi		r2,#1
	stt		r2,68[r5]			; pulse row load bit
	add		r4,r4,#1
	bltu	r4,#20,.life3
	ldi		r2,#6
	stt		r2,68[r5]			; turn on display and calculation
	stt		r2,68[r5]			; turn on display and calculation
	ret

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

