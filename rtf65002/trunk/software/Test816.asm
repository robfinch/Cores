; ============================================================================
;        __
;   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
; 65C816 mode test routine
; ============================================================================
;
public Test816:
	clc
	xce
	cpu		W65C816S
	rep		#$30		; acc,ndx = 16 bit
	mem		16
	ndx		16

	lda		#$1800		; setup stack pointer
	tas

	jsr		putmsg
	db		"Testing 816 Mode", 13, 10, 0

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
; First thing to test is branches. If you can't branch reliably
; then the validity of the remaining tests are in question.
; Test branches and also simultaneously some other simple
; instructions.
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	jsr		putmsg
	db		"Test branches",13,10,0

	bra		braok
	jsr		putmsg
	db		"BRA:F", 13, 10, 0
braok
	brl		brlok
	jsr		putmsg
	db		"BRL:F", 13, 10, 0
brlok
	sec
	bcs		bcsok
	jsr		putmsg
	db		"BCS:F", 13, 10, 0
bcsok
	clc
	bcc		bccok
	jsr		putmsg
	db		"BCC:F", 13, 10, 0
bccok
	lda		#$00
	beq		beqok
	jsr		putmsg
	db		"BEQ:F", 13, 10, 0
beqok
	lda		#$8000
	bne		bneok
	jsr		putmsg
	db		"BNE:F", 13, 10, 0
bneok
	ora		#$00
	bmi		bmiok
	jsr		putmsg
	db		"BMI:F", 13, 10, 0
bmiok
	eor		#$8000
	bpl		bplok
	jsr		putmsg
	db		"BPL:F", 13, 10, 0
bplok
	lda		#$7fff
	clc
	adc		#$1000		; should give signed overflow
	bvs		bvsok
	jsr		putmsg
	db		"BVS:F", 13, 10, 0
bvsok
	clv
	bvc		bvcok
	jsr		putmsg
	db		"BVC:F", 13, 10, 0
bvcok

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
; Compare Instructions
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	jsr		putmsg
	db		"test cmp/cpx/cpy", 13, 10, 0

	lda		#27			; bit 7 = 0
	clc
	cmp		#27
	bcc		cmperr
	bne		cmperr
	bmi		cmperr
	lda		#$A001
	cmp		#20
	bpl		cmperr		; should be neg.
	sec
	lda		#10
	cmp		#20			; should be a borrow here
	bcs		cmperr
	clv
	lda		#$8000		; -128 - 32 = -160 should overflow
	cmp		#$2000		; compare doesn't affect overflow
	bvs		cmperr
	bvc		cmpok

cmperr
	jsr		putmsg
	db		"CMP:F", 13, 10, 0

cmpok

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	jsr		putmsg
	db		"Test psh/pul", 13, 10, 0

; pha / pla
	lda		#$ee00
	pha
	lda		#00
	clc
	pla
	bpl		plaerr
	beq		plaerr
	bcs		plaerr
	cmp		#$ee00
	beq		plaok

plaerr
	jsr		putmsg
	db		"PLA:F", 13, 10, 0

plaok

; ror m

	clc
	lda		#$8000
	sta		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	ror		dpf
	bmi		rormerr
	beq		rormerr
	bcs		rormerr
	lda		dpf
	cmp		#$0001		; this will set the carry !!!
	bne		rormerr
	clc
	ror		dpf
	bcc		rormerr
	bne		rormerr
	bmi		rormerr
	ror		dpf
	bcs		rormerr
	bpl		rormerr
	beq		rormerr
	lda		dpf
	cmp		#$8000
	bne		rormerr
	jmp		rormok

rormerr
	jsr		putmsg
	db		"RORM:F", 13, 10, 0
	jmp		rormok
	
rormok

