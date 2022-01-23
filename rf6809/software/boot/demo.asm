; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; BSD 3-Clause License
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;                                                                          
; ============================================================================
;

OPT include "d:\cores2022\rf6809\software\boot\mon_equates.asm"
OPT include "d:\cores2022\rf6809\software\boot\io_equates.asm"

sprite_xpos	EQU		$1000
sprite_ypos	EQU		$1020
sprite_dx		EQU		$1040
sprite_dy		EQU		$1080

	org		$FF8000
	lbra	sprite_demo
	lbra	disassem

;==============================================================================
; Disassembler
;==============================================================================

OPT	include "d:\cores2022\rf6809\software\boot\disassem.asm"

;==============================================================================
; Sprite Demo
;==============================================================================
sprite_demo:
	ldb		#1
	tfr		b,dpr
	setdp	1
	ldd		#-1						; show them all
	tfr		d,x
	swi
	fcb		MF_ShowSprites
	ldy		#0
sprite_demo1:
	; Assign random positions
	swi
	fcb		MF_Random
	andb	#$1FF
	clra
	addd	#200
	std		SPRITE_CTRL+0,y		; hpos
	tfr		x,d
	andb	#$FF
	clra
	addd	#64
	std		SPRITE_CTRL+1,y		; vpos
	leay	8,y
	cmpy	#$100
	blo		sprite_demo1
	; turn on sprite DMA
	ldd		#-1
	std		SPRITE_CTRL+$3D0
	std		SPRITE_CTRL+$3D2
	ldy		#0
sprite_demo2:
	swi
	fcb		MF_Random
	andb	#$15
	subb	#8
	stb		sprite_dx,y
	anda	#15
	suba	#8
	sta		sprite_dx,y
	iny
	cmpy	#32
	blo		sprite_demo2
	ldy		#300000
sprite_demo3:
	dey
	bne		sprite_demo3
	ldx		#0
	ldy		#0
sprite_demo4:
	lda		SPRITE_CTRL+0,x
	adda	sprite_dx,y
	sta		SPRITE_CTRL+0,x
	lda		SPRITE_CTRL+1,x
	adda	sprite_dy,y
	sta		SPRITE_CTRL+1,x
	leax	8,x
	iny
	cmpy	#32
	blo		sprite_demo4
	clra
	clrb
	swi
	fcb		MF_INCH
	cmpb	#CTRLC
	bne		sprite_demo3
	ldd		#0
	tfr		d,x
	swi
	fcb		MF_ShowSprites
sprite_demo5:
	swi
	fcb		MF_Monitor
	bra		sprite_demo5
