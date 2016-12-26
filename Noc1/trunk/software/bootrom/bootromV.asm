;============================================================================
;        __
;   \\__/ o\    (C) 2016  Robert Finch, Stratford
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
; bootromV.asm
; - This is a first test program to see if the system works.
; - Each node will send a request to display the node number on
;   successive lines of the screen.
;============================================================================
;
TXTROWS		EQU		1
TXTCOLS		EQU		4
TEXTSCR		EQU		$FFD00000
SSG            EQU       $FFDC0080
SPRITE_CTRL    EQU       $FFDAD000
SPRITE_POS     EQU       $FFDAD000
SPRITE_IMAGE   EQU       $FFD80000
NOCC_PKTLO     EQU       $FFD80000
NOCC_PKTMID    EQU       $FFD80004
NOCC_PKTHI     EQU       $FFD80008
NOCC_TXPULSE   EQU       $FFD80018
NOCC_STAT      EQU       $FFD8001C
CPU_INFO       EQU       $FFD90000
GFX_CONTROL    EQU       $FFD40000
GFX_TGT_BASE   EQU       $FFD40010
GFX_TGT_SIZEX  EQU       $FFD40014
GFX_TGT_SIZEY  EQU       $FFD40018
GFX_CLIP_P0_X  EQU       $FFD40074
GFX_CLIP_P0_Y  EQU       $FFD40078
GFX_CLIP_P1_X  EQU       $FFD4007C
GFX_CLIP_P1_Y  EQU       $FFD40080

BMP_PX          EQU    $FFDC5024
BMP_PY          EQU    $FFDC5028
BMP_COLOR       EQU    $FFDC502C
BMP_PCMD        EQU    $FFDC5030


  bss
  org     $10000
m_w				dw		0
m_z				dw		0

NormAttr 	EQU		8

  code
	org		0x01FC
	jmp		nmi_rout
	jmp		start
start:
  ldi   sp,#$1BFFC       ; top of the 48k ram
  ldi   a0,#$88888888
  jal   ra,srand
  ;lw    t0,CPU_INFO      ; figure out which core we are
  csrrw	t0,#$F10,x0
  andi  t0,t0,#15
  slti  t0,t0,#2
  beq   t0,x0,.0002      ; not core #1 (wasn't less than 2)
  lw    t0,NOCC_STAT     ; get which node we are
  srli  t0,t0,#16        ; extract bit field
  andi  t0,t0,#15
  or    a2,t0,x0         ; move to a2
  ldi   a0,#$1000001F    ; select write cycle to main system
  ldi   a1,#$FFDC0600    ; LEDs
  jal   ra,xmitPacket
  
  ldi   t1,#336          ; number of bytes per screen line
  mul   t0,t0,t1         ; r4 = node number * bytes per screen line
  addi  a1,t0,#$FFD00000 ; add in screen base address r2 = address
  ldi   a0,#$1000001F    ; target system interface for word write cycle
  ori   a2,a2,#%000111000_110110110_000011_0000    ; grey on green text
  jal   ra,xmitPacket

  ; If we are cpu#1 of node#1 - initialize graphics controller
;  lw    t0,CPU_INFO      ; figure out which core we are
  csrrw	t0,#$F10,x0
  ; assign node 6 to daring diagonal line test
  ldi   t1,#$61
  beq   t0,t1,bmp_line
  ldi   t1,#$51
;  jal   x0,bmp_rand
;  beq   x0,x0,bmp_rand
  ldi   t1,#$21
  bne   t0,t1,.0004
;  jal   ra,init_gfx

.0004
  ; Wait a random length of time (1 to 8 loops)
  ldi   a3,#1000         ; run 1000 times
.0001:
  jal   ra,gen_rand      ; generate random number (0-7)
  andi  v0,v0,#7
  addi  v0,v0,#1
.0003:
  addi  v0,v0,#-1
  bne   v0,x0,.0003
  ; Write a random character on the screen
  ldi   a0,#$1000001F    ; select write cycle to main system
  jal   ra,gen_rand      ; compute a random screen address
  or    a1,v0,x0
  andi  a1,a1,#$3FFC
  ori   a1,a1,#$FFD00000 ; or in text screen memory address
  jal   ra,gen_rand      ; get random color and character data
  or    a2,v0,x0
  jal   ra,xmitPacket    ; transmit to system controller
  addi  a3,a3,#-1        ; decrement loop count
  beq   x0,x0,.0001      ; keep repeating forever anyway for now
;  jal   ra,sprite_demo
  ; Here do processing for the second CPU
.0002:
  beq   x0,x0,.0002

//---------------------------------------------------------------------------
// Draw a diagonal line to test bitmap controller
//---------------------------------------------------------------------------
bmp_line:
.su5:
    ldi   t1,#0
    ldi   t3,#0xEA4        ; 12 bit orange
    ldi   t4,#2            ; 2 = plot pixel
    ldi   a0,#$1000001F    ; target system interface for word write cycle
    ldi   a1,#BMP_COLOR    ; address of color control register
    or    a2,t3,x0         ; move color to arg reg
    jal   ra,xmitPacket
.su4:
    ldi   a1,#BMP_PX
    or    a2,t1,x0
    jal   ra,xmitPacket
    ldi   a1,#BMP_PY
    jal   ra,xmitPacket
.su3:
    ldi   a1,#BMP_PCMD
    ldi   a2,#2            ; plot pixel command
    jal   ra,xmitPacket
		addi  t1,t1,#1
		ldi   t0,#192
  	bltu  t1,t0,.su4
    jal   x0,.su5

//---------------------------------------------------------------------------
// Randomize bitmap display
//---------------------------------------------------------------------------
bmp_rand:
.su6:
    jal   ra,gen_rand
    or    a2,v0,v0         ; a2 = color
    jal   ra,gen_rand
    andi  a1,v0,#$0FFFFC   ; a1 = random address
    ori   a1,a1,#$400000
    ldi   a0,#$1000001F    ; target system interface for word write cycle
    jal   ra,xmitPacket
    beq   x0,x0,.su6

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

xmitPacket:
  addi  sp,sp,#-4
  sw    t0,[sp]
  ; first wait until the transmitter isn't busy
.0001:
  lw    t0,NOCC_STAT
  andi  t0,t0,#$100      ; bit 8 is xmit status
  bne   t0,x0,.0001
  ; Now transmit packet
  sw    a0,NOCC_PKTHI    ; set high order packet word
  sw    a1,NOCC_PKTMID   ; set middle packet word
  sw    a2,NOCC_PKTLO    ; and set low order packet word
  sw    x0,NOCC_TXPULSE  ; and send the packet
  lw    t0,[sp]
  addi  sp,sp,#4
- jal   [ra]

//---------------------------------------------------------------------------
// Generate a random number
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
//---------------------------------------------------------------------------
//
// Seed the generator with a number dependent on the core number so each
// core has a unique series of numbers.
//
srand:
;    lw    v0,CPU_INFO      ; figure out which core we are
	csrrw v0,#$F10,x0
    sw    v0,m_z
    sw    a0,m_w
-   jal   [ra]
    
gen_rand:
		addi	sp,sp,#-4
		sw		t0,[sp]
		lw		v0,m_z
		ldi   t0,#36969
		mul 	t0,v0,t0
		srli	v0,v0,#16
		add  	t0,t0,v0
		sw		t0,m_z

		lw		v0,m_w
		ldi   t0,#18000
		mul 	t0,v0,t0
		srli	v0,v0,#16
		add 	t0,t0,v0
		sw		t0,m_w

		lw		v0,m_z
		slli	v0,v0,#16
		add	  v0,v0,t0
		lw		t0,[sp]
		addi	sp,sp,#4
-		jal   [ra]

rand:
		addi	sp,sp,#-4
		sw		t0,[sp]
		lw		v0,m_z
		lw    t0,m_w
		slli	v0,v0,#16
		add	  v0,v0,t0
		lw		t0,[sp]
		addi	sp,sp,#4
-		jal   [ra]

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

init_gfx:
    addi  sp,sp,#-4
    sw    ra,[sp]
    ldi   a0,#$1000001F   ; select write cycle to main system
    ldi   a1,#GFX_CONTROL ; graphics control register address
    ldi   a2,#$300000     ; 16 bpp
    jal   ra,xmitPacket
    ldi   a1,#GFX_TGT_BASE  ; set graphics base address to 0
    ldi   a2,#0
    jal   ra,xmitPacket
; set size of graphics screen
    ldi   a1,#GFX_TGT_SIZEX
    ldi   a2,#1360         ; screen is 1360 x 768
    jal   ra,xmitPacket
    ldi   a1,#GFX_TGT_SIZEY
    ldi   a2,#768
    jal   ra,xmitPacket
; set the clip to the whole screen
    ldi   a1,#GFX_CLIP_P0_X
    ldi   a2,#0
    jal   ra,xmitPacket
    ldi   a1,#GFX_CLIP_P0_Y
    jal   ra,xmitPacket
    ldi   a2,#1360<<16
    ldi   a1,#GFX_CLIP_P1_X
    jal   ra,xmitPacket
    ldi   a2,#768<<16
    ldi   a1,#GFX_CLIP_P1_Y
    jal   ra,xmitPacket
; Fill screen with blue
    ldi   t0,#1360*768/2  ; 2 pixels per word
    ldi   a0,#$1000001F   ; select write cycle to main system
    ldi   t1,#0
.0001:
    or    a1,t1,x0        ; screen base address
    ldi   a2,#%00000_000000_11111_00000_000000_11111
    jal   ra,xmitPacket
    ldi   a1,#SSG
    or    a2,t1,x0
    jal   ra,xmitPacket
    addi  t1,t1,#4
    addi  t0,t0,#-1
    bne   t0,x0,.0001

    lw    ra,[sp]
    addi  sp,sp,#4
-   jal   [ra]

sprite_demo:
    ; First fill sprite with random image data or nothing will show
;    lw    t0,CPU_INFO
    csrrw t0,#$F10,x0
    andi  t0,t0,#$F0      ; t0 = index into register set
    slli  t1,t0,#4        ; align to 4k boundary
    ldi   t2,#1024        ; 1024 words to update
    ldi   a0,#$1000001F   ; select write cycle to main system
    addi  a1,t1,#SPRITE_IMAGE ; set sprite image data address
.0001:
    jal   ra,gen_rand     ; get a random number
    or    a2,v0,x0        ; move to a2
    jal   ra,xmitPacket
    addi  a1,a1,#4        ; advance to next word
    addi  t2,t2,#-1       ; decrement word count
    bne   t2,x0,.0001
; set random sprite position
    jal   ra,gen_rand
    andi  a2,v0,#$03FF07FF
; set a random dx,dy for the sprite
    jal   ra,gen_rand
    andi  t2,v0,#$00070007; t2 = random delta
.0002:
    add   a2,a2,t2  
    andi  a2,a2,#$03FF07FF; limit roughly to screen co-ords
    addi  a1,t0,#SPRITE_POS
    jal   ra,xmitPacket   ; update sprite position
    beq   x0,x0,.0002    
   
nmi_rout:
	eret

end_of_program:


