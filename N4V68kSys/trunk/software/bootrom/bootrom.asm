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
;          :  dram memory   : 512 MB
;          |                |
; 20000000 +----------------+
;          |                |
;          :     unused     :
;          |                |
; FF400000 +----------------+
;          :  scratch ram   : 128k
; FF420000 +----------------+
;          :     unused     :
; FF800000 +----------------+
;          |                |
;          : display buffer : 768k x 10 bits wide memory
;          |                |
; FF980000 +----------------+
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
VDGBUF		EQU	$FF800000
VDGREG		EQU	$FFE00000
VirtScreen	EQU	$1FFF0000
leds		EQU	$FFDC0600
rand		EQU	$FFDC0C00

fgcolor		EQU	$FF400000
bkcolor		EQU	$FF400002
fntsz		EQU	$FF400004

	org		$FFFC0000

;------------------------------------------------------------------------------

	dc.l	$FF41FFFC	; initial SSP
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

		lea	$FFDC0000,A6	; I/O base

		; Initialize random number generator

		clr.w	$0C06(a6)				; select stream #0
		move.l	#$88888888,$0C08(a6)	; set initial m_z
		move.l	#$01234567,$0C0C(a6)	; set initial m_w

		bsr		BootClearScreen		
		move.w	#$A2A2,leds			; diagnostics

		bsr		BootCopyFont
		move.w	#$A3A3,leds			; diagnostics

		move.w	#%111111111,fgcolor	; set text colors
		move.w	#%000000011,bkcolor

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

;------------------------------------------------------------------------------
; clear screen	
;
; Trashes:
;	a0,d0,d1
;------------------------------------------------------------------------------

BootClearScreen:
		move.l	#VDGBUF,A0
		moveq	#%000000011,D0			; dark blue
		move.l	#640*512,D1				; number of pixels
.loop1:
		move.w	d0,(a0)+				; store it to the screen
		sub.l	#1,d1					; can't use dbra here
		bne.s	d1,.loop1
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
		move.l	#$FF970000,a1		; font table address
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
		move.w	$42A(a6),d4			; read character queue index into d4
		cmp.w	#28,d4					; allow up 28 entries to be in progress
		bhs.s	disphnum3				; branch if too many chars queued
		ext.b	d0						; zero out high order bits
		move.w	d0,$420(a6)			; set char code
		move.w	#%111111111,$422(a6)	; set fg color
		move.w	#%000000011,$424(a6)	; set bk color
		move.w	d3,$426(a6)			; set x pos
		move.w	#8,$428(a6)			; set y pos
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
        movea.l #8,a0
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
        cmpa.l 	#$1FFFFFFC,a0
        bne.s 	ramtest1
;------------------------------------------------------
;   Save maximum useable address for later comparison.
;------------------------------------------------------
ramtest6:
		move.w	#$A7A7,leds		; diagnostics
        movea.l a0,a2
        movea.l #8,a0
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
        movea.l #8,a0
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
        movea.l #8,a0
ramtest5:
        move.l 	(a0)+,d0
        cmpa.l	a0,a2
        beq.s	rmtst5
        move.l 	a0,d1
        tst.w	d1
        bne.s	rmtst4
        lea		tmtst4,a5
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
