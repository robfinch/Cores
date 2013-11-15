
; ============================================================================
;        __
;   \\__/ o\    (C) 2013  Robert Finch, Stratford
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

LEDS		EQU		0xFFDC0600
TEXTSCR		EQU		0xFFD00000
COLORSCR	EQU		0xFFD10000
TEXTREG		EQU		0xFFDA0000
TEXT_COLS	EQU		0x0
TEXT_ROWS	EQU		0x2
TEXT_CURPOS	EQU		0x16

		code
		org		0xFFFFF800
start
		; Initialize segment registers for "flat" addressing
		ldi		r1,#1
		sb		r1,LEDS
		mtspr	seg0,r0
		mtspr	seg1,r0
		mtspr	seg2,r0
		mtspr	seg3,r0
		mtspr	seg4,r0
		mtspr	seg5,r0
		mtspr	seg6,r0
		mtspr	seg7,r0
		mtspr	seg8,r0
		mtspr	seg9,r0
		mtspr	seg10,r0
		mtspr	seg11,r0
		mtspr	seg12,r0
		mtspr	seg13,r0
		mtspr	seg14,r0
		mtspr	seg15,r0
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
		tlben

		mtspr	br12,r0			; set vector table address
		lh		r1,jirq			; setup jump to irqrout
		lh		r2,jirq+4
		lh		r3,jirq+8
		lh		r4,jirq+12
		sh		r1,$fe0
		sh		r2,$fe4
		sh		r3,$fe8
		sh		r4,$fec
		memsb					; force the stores to complete before an int occurs
		ldi		r3,#st1			; set return address for an RTI
		mtspr	br14,r3
		rti						; RTI to enable interrupts
st1:
		nop
		ldi		r1,#1234
		ldi		r2,#5678
		ldi		r3,#7777
		ldi		r4,#4444
		ldi		r5,#8888
		ldi		r6,#9999
		add		r1,r2,r3
		nand	r3,r4,r5
		nand	r4,r5,r6
		add		r1,r3,r4
		tst		p1,r1
p1.eq	br		foobar
		add		r1,r4,r5
		nop
		nop
		align	8
jirq:
		jmp		irqrout

foobar
		addi	r1,r57,#1234
		cmpi	p1,r1,#1233

irqrout:
		rti
		
;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------
;
AsciiToScreen:
		andi	r1,r1,#0x00ff
		cmpi	p1,r1,#'A'
p1.ltu	br		atoscr1
		cmpi	p1,r1,#'Z'
p1.leu	br		atoscr1
		cmpi	p1,r1,#'z'
p1.gtu	br		atoscr1
		cmpi	p1,r1,#'a'
p1.geu	subui	r1,r1,#$60
atoscr1:
		ori		r1,r1,#0x100
		rts

;------------------------------------------------------------------------------
; Clear the screen and the screen color memory
; We clear the screen to give a visual indication that the system
; is working at all.
;------------------------------------------------------------------------------
;
ClearScreen:
	subui	r255,r255,#40
	sw		r1,[r255]
	sw		r2,8[r255]
	sw		r3,16[r255]
	sw		r4,24[r255]
	mfspr	r1,br1
	sw		r1,32[r255]
	ldi		r3,#TEXTREG
	lc		r1,TEXT_COLS[r3]	; calc number to clear
	lc		r2,TEXT_ROWS[r3]
	mulu	r2,r1,r2			; r2 = # chars to clear
	mtspr	lc,r2
	ldi		r1,#32			; space char
	lc		r4,ScreenColor
	jsr		AsciiToScreen
	ldi		r3,#TEXTSCR		; text screen address
csj4:
	sc		r1,[r3]
	sc		r4,0x10000[r3]	; color screen is 0x10000 higher
	addui	r3,r3,#2
	loop	csj4
	lw		r1,32[r255]
	mtspr	br1,r1
	lw		r4,24[r255]
	lw		r3,16[r255]
	lw		r2,8[r255]
	lw		r1,[r255]
	addui	r255,r255,#40
	rts


p1.eq	subi	r1,r1,#10
		org		0xFFFFFFF0
		jmp		start
		nop
		nop
		nop

