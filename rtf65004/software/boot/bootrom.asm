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
VIC				equ		$FD0000
VIC_CLR		equ		$FD2000		; color memory
VIC_HAL		equ		$FD4000		; high order address bits latch
PALETTE		equ		$FD003C
CS259			equ		$FDFF00

VIA				equ		$FD8020
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

;
; 6551 ACIA equates for serial I/O
;
ACIA_BASE	equ		$FD8040
SDR  			equ		ACIA_BASE       ; RX'ed bytes read, TX bytes written, here
SSR     	equ		ACIA_BASE+1     ; Serial data status register. A write here
                                ; causes a programmed reset.
SCMD    	equ		ACIA_BASE+2     ; Serial command reg. ()
SCTL    	equ		ACIA_BASE+3     ; Serial control reg. ()

; Quick n'dirty assignments instead of proper definitions of each parameter
; "ORed" together to build the desired flexible configuration.  We're going
; to run 19200 baud, no parity, 8 data bits, 1 stop bit.  Period.  For now.
;
SCTL_V  	equ		%00011111       ; 1 stop, 8 bits, 19200 baud
SCMD_V  	equ		%00001011       ; No parity, no echo, no tx or rx IRQ, DTR*
TX_RDY  	equ		%00010000       ; AND mask for transmitter ready
RX_RDY  	equ		%00001000       ; AND mask for receiver buffer full
;
; Zero-page storage
;
DPL       	equ   $00     ; data pointer (three bytes)
DPM					equ		$01
DPH       	equ   $02     ; high of data pointer
RECLEN    	equ   $03     ; record length in bytes
START_LO  	equ   $04
START_MID		equ		$05
START_HI  	equ   $06
RECTYPE   	equ   $07
CHKSUM    	equ   $08     ; record checksum accumulator
DLFAIL    	equ   $09     ; flag for download failure
TEMP      	equ   $0A     ; save hex value
ENTRYPT_LO	equ		$0B
ENTRYPT_MID	equ		$0C
ENTRYPT_HI	equ		$0D

KeyHead		equ		$20		; head of keyboard buffer
KeyTail		equ		$21		; tail of keyboard buffer
CurKey		equ		$22		; current key processed
KeyBuf		equ		$200
KeyCount	equ		$220
IRQIVec		equ		$240	; $240-$242

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

		; Should be able to switch ROM out to $FF8000 now
		sep		#$30		; set 8 bit regs & mem		
		NDX 	8
		MEM		8
		lda		#1
		sta		CS259+0
		rep		#$30		; set 16 bit regs & mem
		NDX 	16
		MEM		16
		bra		.nopatch
		
		; Check for a patch from the cmoda7

		sep		#$30		; set 8 bit regs & mem		
		NDX 	8
		MEM		8
		lda		VIC+$7E		; patch indicator
		cmp		#'P'
		bne		.nopatch
		lda		VIC+$7F		; patch indicator
		cmp		#'A'
		bne		.nopatch

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
		jsr		InitVIC
		jsr		InitACIA
		jsr		InitVIA
		jsr		InitKeybd
		lda		#$FFFF
		sta		IRQIVec+2	; set high order byte to $FF
		lda		#IRQRout1	; set vec
		sta		IRQIVec
		cli					; enable interrupts

		rep		#$30		; set 16 bit regs & mem
		NDX 	16
		MEM		16

		; The palette needs to be initialized or there would be no
		; display output.

		jsr		InitPalette
		jsr		IntelHexDownload
.self
		bra		.self

; ------------------------------------------------------------------------------
; Initialize versatile interface adapter.
;
; Port A and B are used to interface to the keyboard which is an C64 matrix
; keyboard.
; Timer #1 is initialized to generate a 60Hz tick interrupt.
; ------------------------------------------------------------------------------
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
		sta		KeyBuf,y
		iny
		cpy		#$40
		bne		.zerobuf
		sta		KeyHead
		sta		KeyTail
		sta		CurKey
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
		beq		.noKeyDown		; $FF=no
		dea
		sta		VIA+VIA_PA
.bouncing:
		lda		VIA+VIA_PB
		cmp		VIA+VIA_PB
		bne		.bouncing
		bit		ScanTbl+1,x		; was key pressed ?
		bne		.noKeyDown		; no 
		stx		CurKey			; store translated value
		lsr		CurKey
		lda		KeyBuf,y		; see if same key pressed
		cmp		CurKey
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
		

; ------------------------------------------------------------------------------
; ------------------------------------------------------------------------------

InitVIC:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		lda		#3				; set the VIC to address $0C000 to $0FFFF
		sta		VIC_HAL
		lda		#$10
		sta		VIC+$11		; yscroll = 0, rsel = 0, den = 1, bmm = 0, ecm = 0
		lda		#$00
		sta		VIC+$16		; xscroll = 0, csel = 0, mcm = 0, res = 0
		lda		#$04			; screen @$0C000, char bitmap @$0D000
		sta		VIC+$18		; base address for character bitmaps and screen ram
		plp							; restore register settings
		rts

		NDX 	16
		MEM		16

; ------------------------------------------------------------------------------
; Initialize color palette.
;
; Probably doesn't need to be done as the palette is also initialized by
; hardware on reset. Until the palette is setup the display will be blank or
; random colors depending on what power-on does to the palette chip.
; The palette is initialized to the C64 color set accurate to 6 bits for each
; of red, green and blue.
; ------------------------------------------------------------------------------

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

;===============================================================================
;===============================================================================
;===============================================================================
; This is a screen image appearing magically on screen when the ROM is copied
; to RAM. The VIC is setup for a text mode dispay at $00C000.
;===============================================================================
		org	$C000
msgStart:
		db	" *** FAL65816 BIOS v1.0 ***             "
		db	"                                        "
		db	"Menu                                    "
		db	"L Load program via serial port          "
		db	"                                        "

; There is some room here to stuff more code, but it'll showup onscreen on
; reset.

;===============================================================================
; The font is stored in this ROM location so that when the ROM is copied to
; RAM it magically appears where needed by the VIC. This table is for only
; 128 chars but the VIC supports 256.
;===============================================================================

		org	$D000
font8:
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $00
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $04
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $08
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $0C
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $10
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $14
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $18
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; $1C
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; 
		db	$00,$00,$00,$00,$00,$00,$00,$00	; SPACE
		db	$18,$18,$18,$18,$18,$00,$18,$00	; !
		db	$6C,$6C,$00,$00,$00,$00,$00,$00	; "
		db	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	; #
		db	$18,$3E,$60,$3C,$06,$7C,$18,$00	; $
		db	$00,$66,$AC,$D8,$36,$6A,$CC,$00	; %
		db	$38,$6C,$68,$76,$DC,$CE,$7B,$00	; &
		db	$18,$18,$30,$00,$00,$00,$00,$00	; '
		db	$0C,$18,$30,$30,$30,$18,$0C,$00	; (
		db	$30,$18,$0C,$0C,$0C,$18,$30,$00	; )
		db	$00,$66,$3C,$FF,$3C,$66,$00,$00	; *
		db	$00,$18,$18,$7E,$18,$18,$00,$00	; +
		db	$00,$00,$00,$00,$00,$18,$18,$30	; ,
		db	$00,$00,$00,$7E,$00,$00,$00,$00	; -
		db	$00,$00,$00,$00,$00,$18,$18,$00	; .
		db	$03,$06,$0C,$18,$30,$60,$C0,$00	; /
		db	$3C,$66,$6E,$7E,$76,$66,$3C,$00	; 0
		db	$18,$38,$78,$18,$18,$18,$18,$00	; 1
		db	$3C,$66,$06,$0C,$18,$30,$7E,$00	; 2
		db	$3C,$66,$06,$1C,$06,$66,$3C,$00	; 3
		db	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00	; 4
		db	$7E,$60,$7C,$06,$06,$66,$3C,$00	; 5
		db	$1C,$30,$60,$7C,$66,$66,$3C,$00	; 6
		db	$7E,$06,$06,$0C,$18,$18,$18,$00	; 7
		db	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
		db	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
		db	$00,$18,$18,$00,$00,$18,$18,$00	; :
		db	$00,$18,$18,$00,$00,$18,$18,$30	; ;
		db	$00,$06,$18,$60,$18,$06,$00,$00	; <
		db	$00,$00,$7E,$00,$7E,$00,$00,$00	; =
		db	$00,$60,$18,$06,$18,$60,$00,$00	; >
		db	$3C,$66,$06,$0C,$18,$00,$18,$00	; ?
		db	$7C,$C6,$DE,$D6,$DE,$C0,$78,$00	; @
		db	$3C,$66,$66,$7E,$66,$66,$66,$00	; A
		db	$7C,$66,$66,$7C,$66,$66,$7C,$00	; B
		db	$1E,$30,$60,$60,$60,$30,$1E,$00	; C
		db	$78,$6C,$66,$66,$66,$6C,$78,$00	; D
		db	$7E,$60,$60,$78,$60,$60,$7E,$00	; E
		db	$7E,$60,$60,$78,$60,$60,$60,$00	; F
		db	$3C,$66,$60,$6E,$66,$66,$3E,$00	; G
		db	$66,$66,$66,$7E,$66,$66,$66,$00	; H
		db	$3C,$18,$18,$18,$18,$18,$3C,$00	; I
		db	$06,$06,$06,$06,$06,$66,$3C,$00	; J
		db	$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00	; K
		db	$60,$60,$60,$60,$60,$60,$7E,$00	; L
		db	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00	; M
		db	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	; N
		db	$3C,$66,$66,$66,$66,$66,$3C,$00	; O
		db	$7C,$66,$66,$7C,$60,$60,$60,$00	; P
		db	$78,$CC,$CC,$CC,$CC,$DC,$7E,$00	; Q
		db	$7C,$66,$66,$7C,$6C,$66,$66,$00	; R
		db	$3C,$66,$70,$3C,$0E,$66,$3C,$00	; S
		db	$7E,$18,$18,$18,$18,$18,$18,$00	; T
		db	$66,$66,$66,$66,$66,$66,$3C,$00	; U
		db	$66,$66,$66,$66,$3C,$3C,$18,$00	; V
		db	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	; W
		db	$C3,$66,$3C,$18,$3C,$66,$C3,$00	; X
		db	$C3,$66,$3C,$18,$18,$18,$18,$00	; Y
		db	$FE,$0C,$18,$30,$60,$C0,$FE,$00	; Z
		db	$3C,$30,$30,$30,$30,$30,$3C,$00	; [
		db	$C0,$60,$30,$18,$0C,$06,$03,$00	; \
		db	$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00	; ]
		db	$10,$38,$6C,$C6,$00,$00,$00,$00	; ^
		db	$00,$00,$00,$00,$00,$00,$00,$FE	; _
		db	$18,$18,$0C,$00,$00,$00,$00,$00	; `
		db	$00,$00,$3C,$06,$3E,$66,$3E,$00	; a
		db	$60,$60,$7C,$66,$66,$66,$7C,$00	; b
		db	$00,$00,$3C,$60,$60,$60,$3C,$00	; c
		db	$06,$06,$3E,$66,$66,$66,$3E,$00	; d
		db	$00,$00,$3C,$66,$7E,$60,$3C,$00	; e
		db	$1C,$30,$7C,$30,$30,$30,$30,$00	; f
		db	$00,$00,$3E,$66,$66,$3E,$06,$3C	; g
		db	$60,$60,$7C,$66,$66,$66,$66,$00	; h
		db	$18,$00,$18,$18,$18,$18,$0C,$00	; i
		db	$0C,$00,$0C,$0C,$0C,$0C,$0C,$78	; j
		db	$60,$60,$66,$6C,$78,$6C,$66,$00	; k
		db	$18,$18,$18,$18,$18,$18,$0C,$00	; l
		db	$00,$00,$EC,$FE,$D6,$C6,$C6,$00	; m
		db	$00,$00,$7C,$66,$66,$66,$66,$00	; n
		db	$00,$00,$3C,$66,$66,$66,$3C,$00	; o
		db	$00,$00,$7C,$66,$66,$7C,$60,$60	; p
		db	$00,$00,$3E,$66,$66,$3E,$06,$06	; q
		db	$00,$00,$7C,$66,$60,$60,$60,$00	; r
		db	$00,$00,$3C,$60,$3C,$06,$7C,$00	; s
		db	$30,$30,$7C,$30,$30,$30,$1C,$00	; t
		db	$00,$00,$66,$66,$66,$66,$3E,$00	; u
		db	$00,$00,$66,$66,$66,$3C,$18,$00	; v
		db	$00,$00,$C6,$C6,$D6,$FE,$6C,$00	; w
		db	$00,$00,$C6,$6C,$38,$6C,$C6,$00	; x
		db	$00,$00,$66,$66,$66,$3C,$18,$30	; y
		db	$00,$00,$7E,$0C,$18,$30,$7E,$00	; z
		db	$0E,$18,$18,$70,$18,$18,$0E,$00	; {
		db	$18,$18,$18,$18,$18,$18,$18,$00	; |
		db	$70,$18,$18,$0E,$18,$18,$70,$00	; }
		db	$72,$9C,$00,$00,$00,$00,$00,$00	; ~
		db	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00	; 

; ------------------------------------------------------------------------------
; ------------------------------------------------------------------------------
		org		$E000
AbortRout:
		rti
AbortRoutNat:
		rti
BrkRoutNat:
		rti
IrqRout:
		rti

; ------------------------------------------------------------------------------
; Native mode (the processor should always be in native mode) interrupt handler.
; ------------------------------------------------------------------------------

IrqRoutNat:
		; First switch to 16 bit registers. Need to save the whole register.
		rep		#$30			; 16 bit index and mem
		NDX 	16
		MEM		16
		pha
		phx
		phy
		jmp		[IRQIVec]
IRQRout1:
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

		org $F800
;
    ; Download Intel hex.
IntelHexDownload:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
    stz     DLFAIL          ; Start by assuming no D/L failure
    jsr     SerialPutString
    .byte   13,10,13,10
    .byte   "Send 65816 code in"
    .byte   " Intel Hex format"
    .byte  " at 19200,n,8,1 ->"
    .byte   13,10,0
    ; Set default program entry point $000400
    stz			ENTRYPT_HI
    lda			#$04
    sta			ENTRYPT_MID
    stz			ENTRYPT_LO
.nextrec:
		jsr     SerialGetChar   ; Wait for start of record mark ':'
    cmp     #':'
    bne     .nextrec        ; not found yet
    ; Start of record marker has been found
    jsr     SerialGetByte   ; Get the record length
    sta     RECLEN          ; save it
    sta     CHKSUM          ; and save first byte of checksum
    ; Assume a zero for address bits 16 to 23, this may be reset
    ; with a $04 record.
    stz			START_HI				
    jsr     SerialGetByte   ; Get address bits 8 to 15
    sta     START_MID
    clc
    adc     CHKSUM          ; Add in the checksum
    sta     CHKSUM          ;
    jsr     SerialGetByte   ; Get address bits 0 to 7
    sta     START_LO
    clc
    adc     CHKSUM
    sta     CHKSUM
    jsr     SerialGetByte   ; Get the record type
    sta     RECTYPE         ; & save it
    clc
    adc     CHKSUM
    sta     CHKSUM
    lda     RECTYPE
    bne     .nextRecType

    ; Process record type #0 - data
    ldx     RECLEN          ; number of data bytes to write to memory
    ldy     #0              ; start offset at 0
.0002:
	  jsr     SerialGetByte   ; Get the first/next/last data byte
    sta     [START_LO],y    ; Save it to RAM
    clc
    adc     CHKSUM
    sta     CHKSUM          ;
    iny                     ; update data pointer
    dex                     ; decrement count
    bne     .0002
    jsr     SerialGetByte   ; get the checksum
    clc
    adc     CHKSUM
    bne     .fail           ; If failed, report it
    ; Another successful record has been processed
    lda     #'#'            ; Character indicating record OK = '#'
    sta     SDR             ; write it out but don't wait for output
    brl     .nextrec        ; get next record
.fail:
		lda     #'F'            ; Character indicating record failure = 'F'
    sta     DLFAIL          ; download failed if non-zero
    sta     SDR             ; write it to transmit buffer register
    brl     .nextrec        ; wait for next record start

.nextRecType:
		cmp     #1              ; Check for end-of-file type
    beq     .eofRec
    cmp			#4
    beq			.extAddrRec
    cmp			#5
    beq			.entryPointRec
    jsr     SerialPutString ; Warn user of unknown record type
    .byte   13,10,13,10
    .byte   "Unknown record type $",0
    lda     RECTYPE         ; Get it
		sta			DLFAIL					; non-zero --> download has failed
    jsr     SerialPutByte   ; print it
		lda     #13							; but we'll let it finish so as not to
    jsr     SerialPutChar		; falsely start a new d/l from existing
    lda     #10							; file that may still be coming in for
    jsr     SerialPutChar		; quite some time yet.
		brl 		.nextrec
.fail2:
		bra			.fail

	; We've reached the end-of-file record
.eofRec:
	  jsr     SerialGetByte   ; get the checksum
    clc
    adc     CHKSUM          ; Add previous checksum accumulator value
    beq     .0005           ; checksum = 0 means we're OK!
    jsr     SerialPutString ; Warn user of bad checksum
    .byte   13,10,13,10
    .byte   "Bad record checksum!",13,10,0
    brl     IntelHexDownload

    ; rectype #4 - Get address extension - bits 16 to 31
.extAddrRec:
		jsr			SerialGetByte		; get address bits 24 to 31
		clc											; and discard
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte		; get address bits 16 to 23
		sta			START_HI
		clc
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte
		clc
		adc			CHKSUM
.fail1:
		bne			.fail2
		brl			.nextrec

		; rectype #5 - Get the entry point record
.entryPointRec:
		jsr			SerialGetByte		; get address bits 24 to 31
		clc
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte		; get address bits 16 to 23
		sta			ENTRYPT_HI
		clc
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte		; get address bits 8 to 15
		sta			ENTRYPT_MID
		clc
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte		; get address bits 0 to 7
		sta			ENTRYPT_LO
		clc
		adc			CHKSUM
		sta			CHKSUM
		jsr			SerialGetByte		; get checksum byte
		clc
		adc			CHKSUM
		bne			.fail1
		brl			.nextrec

.0005:
   	lda     DLFAIL
    beq     .downloadOk
    ;A download failure has occurred
    jsr     SerialPutString
    .byte   13,10,13,10
    .byte   "Download Failed.",13,10,0
    brl     IntelHexDownload

.downloadOk:
		jsr     SerialPutString
    .byte   13,10,13,10
    .byte   "Download Successful!",13,10
    .byte   "Jumping to $",0
    lda			ENTRYPT_HI		; Print the entry point in hex
    jsr			SerialPutByte
    lda			ENTRYPT_MID
    jsr			SerialPutByte
    lda			ENTRYPT_LO
    jsr			SerialPutByte
    jsr			SerialPutString
    .byte   13,10,0
    jmp			[ENTRYPT_LO]	; jump to canonical entry point
;
;
SerialGetStatus:
	  lda     SSR     	; look at serial status
    and     #RX_RDY 	; strip off "character waiting" bit
    rts             	; if zero, nothing waiting.

; Warning: this routine busy-waits until a character is ready.
; If you don't want to wait, call SERRDY first, and then only
; call GETSER once a character is waiting.

SerialGetChar:  
		lda     SSR    					; look at serial status
    and     #RX_RDY 				; see if anything is ready
    beq     SerialGetChar  	; busy-wait until character comes in!
    lda     SDR     				; get the character
    rts

; Busy wait

SerialGetByte:
		jsr     SerialGetChar
    jsr     MKNIBL  	; Convert to 0..F numeric
    asl
    asl
    asl
    asl				       	; This is the upper nibble
    and     #$F0
    sta     TEMP
    jsr     SerialGetChar
    jsr     MKNIBL
    ora     TEMP
    rts             	; return with the nibble received

; Convert the ASCII nibble to numeric value from 0-F:
MKNIBL  cmp     #'9'+1  	; See if it's 0-9 or 'A'..'F' (no lowercase yet)
        bcc     MKNNH   	; If we borrowed, we lost the carry so 0..9
        sbc     #7+1    	; Subtract off extra 7 (sbc subtracts off one less)
        ; If we fall through, carry is set unlike direct entry at MKNNH
MKNNH   sbc     #'0'-1  	; subtract off '0' (if carry clear coming in)
        and     #$0F    	; no upper nibble no matter what
        rts             	; and return the nibble

; Put byte in A as hexydecascii

SerialPutByte:
		pha             	;
    lsr
    lsr
    lsr
    lsr
    jsr     .0001
    pla
.0001:
	  and     #$0F    	; strip off the low nibble
    cmp     #$0A
    bcc     .0002  	; if it's 0-9, add '0' else also add 7
    adc     #6      	; Add 7 (6+carry=1), result will be carry clear
.0002:
	  adc     #'0'    	; If carry clear, we're 0-9

; Write the character in A as ASCII:

SerialPutChar:
		sta     SDR     	; write to transmit register
.0001:
	  lda     SSR     	; get status
    and     #TX_RDY 	; see if transmitter is busy
    beq     .0001    	; if it is, wait
    rts

; Put the string following in-line until a NULL out to the console
;
SerialPutString:
		pla			; Get the low part of "return" address (data start address)
    sta     DPL
    pla
    sta     DPH             ; Get the high part of "return" address
                                ; (data start address)
    ; Note: actually we're pointing one short
.PSINB:
	  ldy     #1
    lda     (DPL),y         ; Get the next string character
    inc     DPL             ; update the pointer
    bne     .0001           ; if not, we're pointing to next character
    inc     DPH             ; account for page crossing
.0001:
	  ora     #0              ; Set flags according to contents of Accumulator
    beq     .0002           ; don't print the final NULL
    jsr     SerialPutChar   ; write it out
    bra     .PSINB          ; back around
.0002:
		inc     DPL             ;
    bne     .0003           ;
    inc     DPH             ; account for page crossing
.0003:
	  jmp     (DPL)           ; return to byte following final NULL

; ------------------------------------------------------------------------------
; ------------------------------------------------------------------------------
;
; Set up baud rate, parity, stop bits, interrupt control, etc. for
; the serial port.
;
InitACIA:
		php
		sep		#$30			; 8 bit index and mem
		NDX 	8
		MEM		8
		lda   #SCTL_V 	; Set baud rate
    sta   SCTL
    lda   #SCMD_V 	; set parity, interrupt disable
    sta   SCMD
    plp
    rts

; ------------------------------------------------------------------------------
; Processor vector table.
; ------------------------------------------------------------------------------

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
