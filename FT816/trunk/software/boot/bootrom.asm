; ============================================================================
; FAL65816 boot rom
;        __
;   \\__/ o\    (C) 2014-2018  Robert Finch, Waterloo
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
VIC			equ		$FD0000
PALETTE		equ		$FD003C
CS259		equ		$FDFF00

VIA			equ		$FD8020
VIA_PB		equ		$00
VIA_PA		equ		$01
VIA_DDRB	equ		$02
VIA_DDRA	equ		$03
VIA_T1CL	equ		$04	; count low and high
VIA_T1CH	equ		$05
VIA_T1LL	equ		$06	; latch low 
VIA_T1LH	equ		$07	; latch high
VIA_T2L		equ		$08
VIA_T2H		equ		$09
VIA_SHIFT	equ		$0A	; shift register
VIA_ACR		equ		$0B
VIA_PCR		equ		$0C
;
; ????????
; |||||||+- ca2
; ||||||+-- ca1
; |||||+--- shift
; ||||+---- cb2
; |||+----- cb1
; ||+------ timer2
; |+------- timer1
; +-------- irq
VIA_IFR		equ		$0D
;
; ????????
; |||||||+- ca2
; ||||||+-- ca1
; |||||+--- shift
; ||||+---- cb2
; |||+----- cb1
; ||+------ timer2
; |+------- timer1
; +-------- set/clear
VIA_IER		equ		$0E
VIA_PANH	equ		$0F		; same as PA (reg 1) with no handshake

KeyHead		equ		$20		; head of keyboard buffer
KeyTail		equ		$21		; tail of keyboard buffer
Curkey		equ		$22		; current key processed
KeyBuf		equ		$200
KeyCount	equ		$220

		.org	$8000
		cpu		W65C816S
start:
		sec					; switch to '816 mode
		xce
		sep		#$30		; set 8 bit regs & mem		
		NDX 	8
		MEM		8
		lda		#1			; turn on status LED
		sta		CS259+7
		rep		#$30		; set 16 bit regs & mem
		NDX 	16
		MEM		16
		ldx		#$7FFF		; reset stack pointer
		txs

		; Copy ROM to RAM
		ldx		#0
		ldy		#$8000
.0001:
		lda		start,x
		sta		start,x
		inx
		inx
		dey
		dey
		bne		.0001
		
		; Should be able to switch ROM out to $FE0000 now
		; but let's not 
		
		; Check for a patch from the cmoda7

		sep		#$30		; set 8 bit regs & mem		
		NDX 	8
		MEM		8
		lda		VIC+$7f		; patch indicator
		bpl		.nopatch

		lda		#$00		; setup zero page pointer
		sta		$00
		sta		$01
		lda		#$01		; store patch at $10000 in ram
		sta		$02

		ldy		#0
		ldx		#$80
.0006:
		tya
		sta		VIC+$7e		; select page number to read
.0005:
		lda		VIC,x
		sta		[$00]
		inc		$00
		bne		.0003
		inc		$01
.0003:
		inx
		bne		.0005
		ldx		#$80
		iny					; increment page number
		bne		.0006		; 256 pages (32 kB)

		rep		#$30		; set 16 bit regs & mem
		NDX 	16
		MEM		16

		jsl		$10000		; jump to patch startup routine
		
.nopatch:
		jsr		InitVIA
		jsr		InitKeybd
		cli					; enable interrupts

		rep		#$30		; set 16 bit regs & mem
		NDX 	16
		MEM		16

		; The palette needs to be initialized or there would be no
		; display output.

		jsr		InitPalette
		
.self
		bra		.self
;
InitVIA:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		lda		#$ff
		sta		VIA+VIA_DDRA	; port A is output
		lda		#$00
		sta		VIA+VIA_DDRB	; port B is input
		lda		#$1a			; load timer count with $411A
		sta		VIA+VIA_T1LL	; = 60Hz @ 1MHz
		lda		#$41
		sta		VIA+VIA_T1LH
		lda		#%01000000		; T1 = continuous interrupts
		sta		VIA+VIA_ACR
		lda		#$11000000
		sta		VIA+VIA_IER		; enable T1 interrupts
		plp
		rts

; ------------------------------------------------------------------------------
; C64 Keyboard Matrix:		
;
;			$7F			 $BF	$DF		$EF		$F7		$FB		$FD		$FE
; $FE	 Cur up/down	 F5 	F3		F1		F7		cur left ret	ins/del
; $FD	 left shft		 E		S		Z		4		A		W		3
; $FB	 X				 T		F		C		6		D		R		5
; $F7	 V				 U		H		B		8		G		Y		7
; $EF	 N				 O		K		M		0		J		I		9
; $DF	 ,				 @		:		.		-		L		P		+
; $BF	 /				 ^		=		rt shft	clrhm	;		*		pound
; $7F	 run stop		 Q	   comdre	space	2		ctrl	<-		1
;
; ------------------------------------------------------------------------------

InitKeybd:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		lda		#0
		tay
.zerobuf:
		sta		Keybuf,y
		iny
		cpy		#$40
		bne		.zerobuf
		sta		KeyHead
		sta		KeyTail
		sta		Curkey
		plp
		rts

; ------------------------------------------------------------------------------
; Scan C64 compatible keyboard matrix
;
; Register usage:
;	a - temp
;	x - indexes into the scanning table
;	y - indexes into the keyboard buffer
; ------------------------------------------------------------------------------

ScanKeyboard:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		lda		#0				; check all rows
		sta		VIA+VIA_PA
		lda		VIA+VIA_PB
		ina						; acc = $FF if no keys pressed
		bne		.scan			; if acc <> 0 a key is pressed
		plp
		rts
.scan:
		ldy		KeyHead
		ldx		#0
.scanMore:
		lda		ScanTbl,x		; load the row enable
		ina						; check if we want to scan for this key
		beq		.noKeydown		; $FF=no
		dea
		sta		VIA+VIA_PA
.bouncing:
		lda		VIA+VIA_PB
		cmp		VIA+VIA_PB
		bne		.bouncing
		bit		ScanTbl+1,x		; was key pressed ?
		bne		.noKeydown		; no 
		stx		Curkey			; store translated value
		lsr		CurKey
		lda		Keybuf,y		; see if same key pressed
		cmp		Curkey
		bne		.difKey			; different key, go store in buffer
		clc						; same key, increment key count
		lda		KeyCount,Y
		adc		#1
		sta		KeyCount,y
		cmp		#4				; key must be down for at least 4 ticks before it'll repeat
		bmi		.noKeyDown		; if key wasn't down long enough don't store in buffer as new
.difKey:
		iny
		cpy		#32
		bne		.noWrap
		ldy		#0
.noWrap
		cpy		KeyTail			; keyboard buffer full ?
		beq		.noKeyDown
		txa						; store translated key value in buffer
		lsr
		sta		KeyBuf,Y
		lda		#0
		sta		KeyCount,Y
		sty		KeyHead			; save head of buffer
.noKeyDown:
		inx						; advance to testing for the next key
		inx
		cpx		#156
		bne		.scanMore
		sty		KeyHead
		plp						; restore register settings
		rts

ScanTbl:
		db		$DF,%01000000	; @
		db		$FD,%00000100	; A
		db		$FB,%00010000	; B
		db		$FB,%00010000	; C
		db		$FB,%00000100	; D
		db		$FD,%01000000	; E
		db		$FB,%00100000	; F
		db		$F7,%00000100	; G
		db		$F7,%00100000	; H
		db		$EF,%00000010	; I
		db		$EF,%00000100	; J
		db		$EF,%00100000	; K
		db		$DF,%00000100	; L
		db		$EF,%00010000	; M
		db		$EF,%10000000	; N
		db		$EF,%01000000	; O
		db		$DF,%00000010	; P
		db		$7F,%01000000	; Q
		db		$FB,%00000010	; R
		db		$FD,%00100000	; S
		db		$FB,%01000000	; T
		db		$F7,%01000000	; U
		db		$F7,%10000000	; V
		db		$FD,%00000010	; W
		db		$FB,%10000000	; X
		db		$F7,%00000010	; Y
		db		$FD,%00010000	; Z
		db		$FF,%00000000
		db		$BF,%00000001	; pound
		db		$FF,%00000000
		db		$BF,%01000000	; arrow up
		db		$7F,%00000010	; arrow left
		db		$7F,%00010000	; space
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$FF,%00000000
		db		$BF,%00000010	; *
		db		$DF,%00000001	; +
		db		$DF,%10000000	; ,
		db		$DF,%00001000	; -
		db		$DF,%00010000	; .
		db		$BF,%10000000	; /
		db		$EF,%00001000	; 0
		db		$7F,%00000001	; 1
		db		$7F,%00001000	; 2
		db		$FD,%00000001	; 3
		db		$FD,%00001000	; 4
		db		$FB,%00000001	; 5
		db		$FB,%00001000	; 6
		db		$F7,%00000001	; 7
		db		$F7,%00001000	; 8
		db		$EF,%00000001	; 9
		db		$DF,%00100000	; :
		db		$BF,%00000100	; ;
		db		$FF,%00000000	;
		db		$BF,%00100000	; =
		db		$FF,%00000000	;
		db		$FF,%00000000	;

		db		$FE,%00000010	; return
		db		$FD,%10000000	; left shift
		db		$BF,%00010000	; right shift
		db		$7F,%00000100	; control
		db		$FE,%00000001	; ins/del
		db		$FE,%00000100	; cursor left/right
		db		$FE,%10000000	; cursor up/down
		db		$BF,%00001000	; clr / home
		db		$7F,%10000000	; run/stop
		db		$FE,%00010000	; F1
		db		$FE,%00100000	; F3
		db		$FE,%01000000	; F5
		db		$FE,%00001000	; F7
		db		$7F,%00100000	; commodore
		

InitPalette:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		ldx		#0
		txy
.0001:
		tya
		sta		PALETTE			; select address register
		lda		VICColors,x		; get RED component
		sta		PALETTE+1		; store to palette
		inx
		lda		VICColors,x		; get GREEN component
		sta		PALETTE+1		; store to palette
		inx
		lda		VICColors,x		; get blue component
		sta		PALETTE+1		; store to palette
		inx
		iny						; advance to next palette entry
		cpy		#16
		bne		.0001
		lda		#$0F			; enable low order nybble lookup only
		sta		PALETTE+2		; set pixel mask register
		plp						; restore register settings
		rts

		NDX 	16
		MEM		16

AbortRoutNat:
		rti
BrkRoutNat:
		rti
IrqRout:
		rti

IrqRoutNat:
		pha
		phx
		phy
		lda		VIA+VIA_T1CL		; clear interrupt by reading T1CL
		jsr		ScanKeyboard
		ply
		plx
		pla
		rti

NmiRout:
		rti
		; Native mode NMI routine
NmiRoutNat:
		rti

VICColors:
		db	$04,$04,$04		; black			000100_000100_000100
		db	$3f,$3f,$3f		; white			111111_111111_111111
		db	$38,$10,$10		; red			111000_010000_010000
		db	$18,$3f,$3f		; cyan			011000_111111_111111
		db	$38,$18,$38		; purple		111000_011000_111000
		db	$10,$38,$10		; green			010000_111000_010000
		db	$10,$10,$38		; blue			010000_010000_111000
		db	$3f,$3f,$10		; yellow		111111_111111_010000
		db	$38,$28,$10		; orange		111000_101000_010000
		db	$27,$1e,$12		; brown			100111_011110_010010
		db	$3f,$28,$28		; pink			111111_101000_101000
		db	$16,$16,$16		; dark grey		010110_010110_010110
		db	$22,$22,$22		; medium grey	100010_100010_100010
		db	$28,$3f,$28		; light green	101000_111111_101000
		db	$28,$28,$3f		; light blue	101000_101000_111111
		db	$30,$30,$30		; light grey	110000_110000_110000

		.org 	$FFE6
		dw		BrkRoutNat
		
		.org	$FFE8
		dw		AbortRoutNat

		.org	$FFEA
		dw		NmiRoutNat

		.org	$FFEE		; '816 IRQ vector
		dw		IrqRoutNat	; IRQRout816

		.org	$FFF8
		dw		AbortRout
	
		.org	$FFFA
		dw		NmiRout

		.org	$FFFC		; reset vector
		dw		start

		.org	$FFFE
		dw		IrqRout
