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
;
; ============================================================================


DBG_DS		= $5000
DBG_ATTR	= %000011000_111111110_0000000000

DBGBuf		EQU		$00
DBGBufndx	EQU		$80

		code
		org		$FFFFD000

;------------------------------------------------------------------------------
; r2 = text output column
; r6 = text output row
; r5 = disassembly address
;------------------------------------------------------------------------------

public Debugger:
		ldi		r30,#$2bf8
		addui	r30,r30,#-24
		sws		c1,zs:[r30]
		sws		ds,zs:8[r30]
		sws		ds.lmt,zs:16[r30]
		ldis	ds,#DBG_DS
		ldis	ds.lmt,#$8000
		sync
		bsr		VideoInit2
		bsr		VBClearScreen2
		mov		r2,r0
		mov		r6,r0
		ldi		r1,#msgDebugger
		bsr		DBGDispString
		ldi		r5,#$FFFF8000
		bsr		Disassem20
		br		Debugger_exit

promptAgain:
		; Clear input buffer
		sb		r0,DBGBufndx
		ldis	lc,#$20
		ldi		r1,#DBGBuf
		ldi		r2,#0			; 
		stset.hi	r2,[r1]		; clear the buffer
		
		ldi		r6,#30			; move cursor pos to row 30
		bsr		DBGPrompt

		; Get character loop
.0001:
		bsr		KeybdGetCharWait
		cmpi	p0,r1,#CR
p0.eq	br		.processInput
		cmpi	p0,r1,#BS
p0.eq	br		.backspace
		cmpi	p0,r1,#' '
p0.ltu	br		.0001
		; some other character, store in buffer if it will fit
		lbu		r3,DBGBufndx
		cmpi	p3,r3,#80		; max 80 chars
p3.ltu	br		DBGDispChar
p3.ltu	sb		r1,[r3]
p3.ltu	addui	r3,r3,#1
p3.ltu	sb		r3,DBGBufndx
		br		.0001
.backspace:
		lbu		r1,DBGBufndx
		tst		p0,r1			; is is even possible to backspace ?
p0.eq	br		.0001
		ldi		r7,#$80
		subu	r7,r7,r1
		addui	r7,r7,#-1		; loop count is one less
		mtspr	lc,r7
		mov		r4,r1
		addui	r1,r1,#-1
		mov		r3,r0
		stmov.bi	[r4],[r1],r3
		br		.0001
.processInput:
		mov		r4,r0
.0002:
		lbu		r1,DBGBuf[r4]
		tst		p0,r1
p0.eq	br		promptAgain
		cmpi	p0,r1,#' '
p0.leu	addui	r4,r4,#1
p0.leu	br		.0002
		cmpi	p0,r1,#'D'
p0.eq	addui	r4,r4,#1
p0.eq	br		DoDisassem
		br		promptAgain
Debugger_exit:
		lws		c1,zs:[r30]
		lws		ds,zs:8[r30]
		lws		ds.lmt,zs:16[r30]
		sync
		addui	r30,r30,#24
		rts
endpublic

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DoDisassem:
		bsr		DBGGetHexNumber
		tst		p0,r8
p0.eq	br		promptAgain
		mov		r5,r1
		bsr		VBClearScreen2
		bsr		Dissassem20
		br		promptAgain

;------------------------------------------------------------------------------
; Parameters:
;	r4 = text pointer (updated)
; Returns:
;	r1 = number
;   r8 = number of digits
;------------------------------------------------------------------------------

DBGGetHexNumber:
		addui	r30,r30,#-8
		sws		c1,[r30]
		ldis	lc,#80			; max 80 chars
		mov		r7,r0			; working accum.
		mov		r8,r0			; number of digits
.0002:
		lbu		r1,[r4]
		bsr		DBGCharToHex
		tst		p0,r3
p0.eq	br		.0001
		shli	r7,r7,#4
		or		r7,r7,r1
		addui	r4,r4,#1
		addui	r8,r8,#1
		loop	.0002
.0001:
		mov		r1,r7
		lws		c1,[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGCharToHex:
		cmpi	p0,r1,#'0'
.0002:
p0.ltu	mov		r3,r0
p0.ltu	br		.exit
		cmpi	p0,r1,#'9'
p0.gtu	br		.0001
		subui	r1,r1,#'0'
		ldi		r3,#1
		rts
.0001:
		cmpi	p0,r1,#'A'
p0.ltu	br		.0002
		cmpi	p0,r1,#'F'
p0.gtu	br		.0003
		subui	r1,r1,#'A'-10
		ldi		r3,#1
		rts
.0003:
		cmpi	p0,r1,#'a'
p0.ltu	br		.0002
		cmpi	p0,r1,#'f'
p0.gtu	br		.0004
		subui	r1,r1,#'a'-10
		ldi		r3,#1
		rts
.0004:
		mov		r3,r0
.exit:
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

public DebugIRQ:
		ldi		r30,#$2bf8
		addui	r30,r30,#-104
		sws		c1,zs:[r30]
		sws		ds,zs:8[r30]
		sws		ds.lmt,zs:16[r30]
		sw		r1,zs:24[r30]
		sw		r2,zs:32[r30]
		sw		r3,zs:40[r30]
		sw		r4,zs:48[r30]
		sw		r5,zs:56[r30]
		sw		r6,zs:64[r30]
		sw		r7,zs:72[r30]
		sw		r8,zs:80[r30]
		sw		r9,zs:88[r30]
		sw		r10,zs:96[r30]

		ldis	ds,#DBG_DS
		ldis	ds.lmt,#$8000
		sync
		bsr		VBClearScreen2
		mov		r2,r0
		mov		r6,r0
		ldi		r1,#msgDebugger
		bsr		DBGDispString
		mfspr	r5,dpc
		bsr		Disassem20

		lws		c1,zs:[r30]
		lws		ds,zs:8[r30]
		lws		ds.lmt,zs:16[r30]
		lw		r1,zs:24[r30]
		lw		r2,zs:32[r30]
		lw		r3,zs:40[r30]
		lw		r4,zs:48[r30]
		lw		r5,zs:56[r30]
		lw		r6,zs:64[r30]
		lw		r7,zs:72[r30]
		lw		r8,zs:80[r30]
		lw		r9,zs:88[r30]
		lw		r10,zs:96[r30]
		rtd	
endpublic

;------------------------------------------------------------------------------
; Disassemble 20 lines of code.
;------------------------------------------------------------------------------

Disassem20:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldis	lc,#19
		ldi		r6,#3
.0001:
		bsr		Disassem
		addu	r5,r5,r10
		addui	r6,r6,#1
		loop	.0001
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGPrompt:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		mov		r2,r0
		ldi		r1,#'D'
		bsr		DBGDispChar
		ldi		r1,#'B'
		bsr		DBGDispChar
		ldi		r1,#'G'
		bsr		DBGDispChar
		ldi		r1,#'>'
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Disassem:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sws		c2,zs:8[r30]
		ldi		r2,#1				; column one
		bsr		DisplayAddr
		bsr		DisplayBytes
		ldi		r2,#38				; tab to column 38
		bsr		DBGDisplayPred
		ldi		r2,#46				; tab to column 46
		mov		r3,r0
		lbu		r1,zs:[r5]
		cmpi	p0,r1,#$00
p0.eq	ldi		r3,#mne_brk
		cmpi	p0,r1,#$10
p0.eq	ldi		r3,#mne_nop
		cmpi	p0,r1,#$11
p0.eq	ldi		r3,#mne_rts
		cmpi	p0,r1,#$20
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$30
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$40
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$50
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$60
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$70
p0.eq	ldi		r3,#mne_imm
		cmpi	p0,r1,#$80
p0.eq	ldi		r3,#mne_imm
		tst		p0,r3
p0.ne	bsr		DBGDisplayMne
p0.eq	br		.0001
		br		.exit
.0001:
		lbu		r1,zs:1[r5]		; get the opcode
		shli	r1,r1,#1
		lcu		r1,cs:DBGInsnMne[r1]
		cmpi	p0,r1,#$FFF0
p0.geu  br		.0002
.dispMne:
		ori		r3,r1,#$FFFF0000	; set high order address bits
		bsr		DBGDisplayMne
		br		.dispOper
.0002:
		andi	r1,r1,#15
		lcu		r3,cs:DBGInsnMneT[r1]
		ori		r3,r3,#$FFFF0000
		bsr		DBGGetFunc
		lcu		r3,cs:[r3+r1*2]
		br		.dispMne
.dispOper:
		lbu		r1,zs:1[r5]
		lbu		r1,cs:DBGOperFmt[r1]
		jci		c1,cs:DBGOperFmtT[r1]
;		lcu		r1,cs:DBGOperFmtT[r1]
;		ori		r1,r1,#$FFFF0000
;		mtspr	c2,r1
;		jsr		[c2]
.exit:
		lws		c1,zs:[r30]
		lws		c2,zs:8[r30]
		addui	r30,r30,#16
		rts

;------------------------------------------------------------------------------
; Display the disassembly address.
;------------------------------------------------------------------------------

DisplayAddr:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		mov		r4,r5
		bsr		DBGDisplayHalf
		bsr		space3
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts
space1:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r1,#' '
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts
space3:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		bsr		space1
		bsr		space1
		bsr		space1
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGDisplayHalf:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		rori	r4,r4,#16
		bsr		DBGDisplayCharr
		roli	r4,r4,#16
		bsr		DBGDisplayCharr
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDisplayCharr:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		rori	r4,r4,#8
		bsr		DBGDisplayByte
		roli	r4,r4,#8
		bsr		DBGDisplayByte
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDisplayByte:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		rori	r4,r4,#4
		bsr		DBGDisplayNybble
		roli	r4,r4,#4
		bsr		DBGDisplayNybble
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDisplayNybble:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		andi	r1,r4,#15
		cmpi	p0,r1,#9
p0.gtu	addui	r1,r1,#7
		addui	r1,r1,#'0'
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
; Display a character on the debug screen.
;------------------------------------------------------------------------------

DBGDispChar:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		andi	r1,r1,#$7F
		bsr		VBAsciiToScreen
		ori		r1,r1,#DBG_ATTR
		shli	r7,r6,#1
		lcu		r8,cs:DBGLineTbl[r7]
		_4addui	r7,r8,#$FFD10000
		_4addu	r7,r2,r7
		sh		r1,zs:[r7]
		addui	r2,r2,#1
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

;------------------------------------------------------------------------------
; Display a string of text on the debug screen.
;------------------------------------------------------------------------------

DBGDispString:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		mov		r7,r1
.0001:
		lbu		r1,zs:[r7]
		tst		p0,r1
p0.eq	br		.0002
		bsr		DBGDispChar
		addui	r7,r7,#1
		br		.0001
.0002:
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts
		
;------------------------------------------------------------------------------
; Get the length of an instruction.
;------------------------------------------------------------------------------

public DBGGetInsnLength:
		addui	r31,r31,#-8
		sws		c1,[r31]
		lbu		r1,zs:[r5]
		; Test for special predicate values which are one byte long.
		cmpi	p0,r1,#$00		; BRK
p0.eq	ldi		r1,#1
p0.eq	br		.0001
		cmpi	p0,r1,#$10		; NOP
p0.eq	ldi		r1,#1
p0.eq	br		.0001
		cmpi	p0,r1,#$11		; RTS
p0.eq	ldi		r1,#1
p0.eq	br		.0001
		; Test for special immediate predicates these vary in length.
		cmpi	p0,r1,#$20
p0.eq	ldi		r1,#2
p0.eq	br		.0001
		cmpi	p0,r1,#$30
p0.eq	ldi		r1,#3
p0.eq	br		.0001
		cmpi	p0,r1,#$40
p0.eq	ldi		r1,#4
p0.eq	br		.0001
		cmpi	p0,r1,#$50
p0.eq	ldi		r1,#5
p0.eq	br		.0001
		cmpi	p0,r1,#$60
p0.eq	ldi		r1,#6
p0.eq	br		.0001
		cmpi	p0,r1,#$70
p0.eq	ldi		r1,#7
p0.eq	br		.0001
		cmpi	p0,r1,#$80
p0.eq	ldi		r1,#8
p0.ne	lbu		r1,zs:1[r5]
p0.ne	lbu		r1,cs:DBGInsnLength[r1]
.0001:
		lws		c1,[r31]
		addui	r31,r31,#8
		rts
endpublic

;------------------------------------------------------------------------------
; Display the bytes associated with an instruction. There may be up to eight
; bytes displayed.
;	r7 = offset from r5 the dump address
;------------------------------------------------------------------------------

DisplayBytes:
		addui	r30,r30,#-24
		sws		c1,zs:[r30]
		sws		lc,zs:8[r30]
		sw		r7,zs:16[r30]
		sei
		ldi		r31,#INT_STACK
		bsr		DBGGetInsnLength
		mov		r10,r1
		cli
		addui	r1,r1,#-1		; loop count is one less
		mtspr	lc,r1
		mov		r7,r0
.next:
		lbu		r4,zs:[r5+r7]
		bsr		DBGDisplayByte
		bsr		space1			; skip a space
		addui	r7,r7,#1		; increment offset to next byte
		loop	.next
		lws		c1,zs:[r30]
		lws		lc,zs:8[r30]
		lw		r7,zs:16[r30]
		addui	r30,r30,#24
		rts

;------------------------------------------------------------------------------
; Display a predicate.
;
; The always true predicate and special predicate values don't display.
;------------------------------------------------------------------------------

DBGDisplayPred:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		lbu		r1,zs:[r5]
		cmpi	p0,r1,#$00		; brk special
p0.eq	br		.noDisp	
		cmpi	p0,r1,#$01		; always true predicate doesn't display
p0.eq	br		.noDisp
		cmpi	p0,r1,#$11		; rts special
p0.eq	br		.noDisp
		cmpi	p0,r1,#$10		; nop special
p0.eq	br		.noDisp
		cmpi	p0,r1,#$20
p0.eq	br		.noDisp
		cmpi	p0,r1,#$30
p0.eq	br		.noDisp
		cmpi	p0,r1,#$40
p0.eq	br		.noDisp
		cmpi	p0,r1,#$50
p0.eq	br		.noDisp
		cmpi	p0,r1,#$60
p0.eq	br		.noDisp
		cmpi	p0,r1,#$70
p0.eq	br		.noDisp
		cmpi	p0,r1,#$80
p0.eq	br		.noDisp
		ldi		r1,#'p'
		bsr		DBGDispChar
		lbu		r4,zs:[r5]
		shrui	r4,r4,#4
		bsr		DBGDisplayNybble
		ldi		r1,#'.'
		bsr		DBGDispChar
		lbu		r1,zs:[r5]
		bsr		DBGDispCond
		br		.exit
.noDisp:
		addui	r2,r2,#7
.exit
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
; Display the condition portion of the predicate.
;------------------------------------------------------------------------------

DBGDispCond:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		andi	r7,r1,#15
		addu	r7,r7,r7
		addu	r7,r7,r1
		lbu		r1,cs:DBGPredCons[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGPredCons+1[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGPredCons+2[r7]
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
; Display a mnemonic.
; Parameters:
;	r3 = pointer to mnemonic string
;------------------------------------------------------------------------------

DBGDisplayMne:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		bsr		space1
		; Mnemonics are always at least 2 chars
		lbu		r1,cs:[r3]
		bsr		DBGDispChar
		; second char
		lbu		r1,cs:1[r3]
		biti	p1,r1,#$80			; test high bit
		bsr		DBGDispChar
p1.ne	br		.exit
		; third char
		lbu		r1,cs:2[r3]
		biti	p1,r1,#$80			; test high bit
		bsr		DBGDispChar
p1.ne	br		.exit
		; fourth char
		lbu		r1,cs:3[r3]
		biti	p1,r1,#$80			; test high bit
		bsr		DBGDispChar
p1.ne	br		.exit
		; fifth char
		lbu		r1,cs:4[r3]
		bsr		DBGDispChar
.exit:
		addui	r2,r2,#1			; 1 space
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
; Display a register
;------------------------------------------------------------------------------

DBGDispReg:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		mov		r7,r1
		ldi		r1,#'r'
DBGDispBx1:
		bsr		DBGDispChar
		cmpi	p0,r7,#10
p0.ltu	br		.0001
		divui	r9,r7,#10
		addui	r1,r9,#'0'
		mului   r9,r9,#10
		subu	r7,r7,r9
		bsr		DBGDispChar
.0001:
		mov		r1,r7
		addui	r1,r1,#'0'
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

;------------------------------------------------------------------------------
; Display a bit number
;------------------------------------------------------------------------------

DBGDispBReg:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		mov		r7,r1
		ldi		r1,#'b'
		br		DBGDispBx1

;------------------------------------------------------------------------------
; Display a special purpose register
;------------------------------------------------------------------------------

DBGDispSpr:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		addu	r7,r1,r1
		addu	r7,r7,r1			; r7 = r1 * 3
		lbu		r1,cs:DBGSpr[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGSpr+1[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGSpr+2[r7]
		cmpi	p0,r1,#' '
p0.ne	bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGComma:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r1,#','
		bsr		DBGDispChar
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

;------------------------------------------------------------------------------
; Display registers for TST instruction.
;------------------------------------------------------------------------------

DBGDispTstregs:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:1[r5]
		andi	r1,r1,#15
		bsr		DBGDispSpr
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#$3f
		bsr		DBGDispReg
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDispCmpregs:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:1[r5]
		andi	r1,r1,#15
		bsr		DBGDispSpr
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#$3f
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		andi	r7,r7,#15
		shli	r7,r7,#2
		or		r1,r7,r1
		bsr		DBGDispReg
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDispBrDisp:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:1[r5]
		lbu		r7,zs:2[r5]
		andi	r1,r1,#15
		shli	r7,r7,#4
		or		r1,r7,r1
		addui	r1,r1,#3		; instruction size
		addu	r4,r1,r5		; instruction address
		ldi		r1,#'$'
		bsr		DBGDispChar
		bsr		DBGDispHalf
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

DBGDispCmpimm:
		addui	r30,r30,#-8
		sws		c1,zs:[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:1[r5]
		andi	r1,r1,#15
		bsr		DBGDispSpr
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#$3f
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		shli	r7,r7,#2
		or		r4,r7,r1
		ldi		r1,#'#'
		bsr		DBGDispChar
		ldi		r1,#'$'
		bsr		DBGDispChar
		bsr		DBGDispHalf
		lws		c1,zs:[r30]
		addui	r30,r30,#8
		rts

; Used by mtspr
DBGDispSprRx:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:2[r5]
		lbu		r7,zs:3[r5]
		shrui	r1,r1,#6
		andi	r7,r7,#15
		shli	r7,r7,#2
		or		r1,r7,r1
		bsr		DBGDispSpr
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispReg
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

; Format #4
;
DBGDispRxRxRx:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:3[r5]
		shrui	r1,r1,#4
		lbu		r7,zs:4[r5]
		andi	r7,r7,#3
		shli	r7,r7,#4
		or		r1,r7,r1
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		andi	r7,r7,#15
		shli	r7,r7,#2
		or		r1,r7,r1
		bsr		DBGDispReg
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

; Format #5
;
DBGDispRxRx:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		andi	r7,r7,#15
		shli	r7,r7,#2
		or		r1,r7,r1
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispReg
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

; Format #6
;
DBGDispPxPxPx:
		addui	r30,r30,#-16
		sws		c1,zs:[r30]
		sw		r7,zs:8[r30]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:3[r5]
		shrui	r1,r1,#4
		lbu		r7,zs:4[r5]
		andi	r7,r7,#3
		shli	r7,r7,#4
		or		r1,r7,r1
		bsr		DBGDispBReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispBReg
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		andi	r7,r7,#15
		shli	r7,r7,#2
		or		r1,r7,r1
		bsr		DBGDispBReg
		lws		c1,zs:[r30]
		lw		r7,zs:8[r30]
		addui	r30,r30,#16
		rts

DBGDispNone:
		rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = opcode group
; Returns:
;	r1 = function code
;------------------------------------------------------------------------------

DBGGetFunc:
		shli	r1,r1,#1
		lcu		r1,cs:DBGFuncT[r1]
		ori		r1,r1,#$FFFF0000
		mtspr	c2,r1
		jmp		[c2]

gf0:
gf2:
gf3:
gf4:
gf6:
gfB:
		lbu		r1,zs:4[r5]
		shrui	r1,r1,#2
		rts
gf1:
gf5:
gf7:
gf8:
		lbu		r1,zs:3[r5]
		shrui	r1,r1,#4
		rts
gf9:
		lbu		r1,zs:5[r5]
		andi	r1,r1,#15
		rts
gfA:
		lbu		r1,zs:2[r5]
		andi	r1,r1,#15
		rts

	align	2
DBGFuncT:
		dc		gf0,gf1,gf2,gf3,gf4,gf5,gf6,gf7,gf8,gf9,gfA,gfB,gf0,gf0,gf0,gf0

;------------------------------------------------------------------------------
; Tables
;------------------------------------------------------------------------------

		align	2
DBGLineTbl:
		dc		0
		dc		1*84
		dc		2*84
		dc		3*84
		dc		4*84
		dc		5*84
		dc		6*84
		dc		7*84
		dc		8*84
		dc		9*84
		dc		10*84
		dc		11*84
		dc		12*84
		dc		13*84
		dc		14*84
		dc		15*84
		dc		16*84
		dc		17*84
		dc		18*84
		dc		19*84
		dc		20*84
		dc		21*84
		dc		22*84
		dc		23*84
		dc		24*84
		dc		25*84
		dc		26*84
		dc		27*84
		dc		28*84
		dc		29*84
		dc		30*84
		dc		31*84

; Table of the length of each instruction.
;
DBGInsnLength:
		byte	3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,3	; TST
		byte	4,4,4,4, 4,4,4,4, 4,4,4,4, 4,4,4,4	; CMP
		byte	4,4,4,4, 4,4,4,4, 4,4,4,4, 4,4,4,4	; CMPI
		byte	3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,3	; BR

		byte	5,4,5,1, 1,1,5,4, 5,5,5,5, 5,5,5,5
		byte	5,5,1,5, 5,5,1,1, 5,1,1,1, 1,1,1,1
		byte	1,1,1,1, 1,1,1,1, 1,1,1,5, 5,5,5,4
		byte	1,1,5,1, 1,1,1,4, 5,4,1,1, 1,1,1,1

		byte	5,5,5,5, 5,5,5,1, 1,1,1,5, 5,1,5,5
		byte	5,5,5,5, 1,1,5,6, 5,5,5,5, 1,4,5,4
		byte	3,5,6,3, 3,4,4,4, 4,4,6,4, 5,5,5,5
		byte	5,5,5,5, 5,5,5,1, 1,1,1,1, 1,1,1,1

		byte	5,5,5,5, 1,1,5,6, 3,5,3,5, 3,1,1,1
		byte	1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1
		byte	1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1
		byte	4,2,4,2, 2,5,4,2, 2,2,2,2, 2,1,1,2

; Table of operand format indexes
;
; 0 = px,rx
; 1 = px,rx,rx
; 2 = px,rx,#imm
; 3 = disp12
; 4 = rx,rx,rx
; 5 = rx,rx
; 6 = px,px,px
; 7 = none
; 8 = px,rx,#imm (biti)
; 9 = rx,#imm	(addui short)
; 10 = rx,rx,#imm
; 11 = mlo
; 12 = shift
; 13 = rx,#imm	(ldi)
; 14 = rx,rx,rx,rx	(mux format)
; 15 = rx,mem		(load/store)
; 16 = rx,rx,rx,[rx]	(cas)
; 17 = rx,[rx]		(stset)
; 18 = [rx],[rx],rx	(stmov/stcmp)
; 19 = rx,#imm	(cache)
; 20 = [cx]		jsr
; 21 = jsr
; 22 = jsr
; 23 = rts
; 24 = loop
; 25 = sys/int
; 26 = rx,spr
; 27 = spr,rx
; 28 = bitfield
; 29 = spr,spr
; 30 = rx,[rx+rx*sc]	(load/store)
; 31 = stix
; 32 = inc
; 33 = tlb
; 34 = rts
; 35 = bcd
; 36 = stp
; 37 = imm

DBGOperFmt:
		byte	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0	; TST	px,rx
		byte	1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1	; CMP	px,rx,rx
		byte	2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2	; CMPI	px,rx,#imm
		byte	3,3,3,3, 3,3,3,3, 3,3,3,3, 3,3,3,3	; BR

		byte	4,5,6,7, 7,7,8,9, 10,10,10,10, 10,10,10,10
		byte	4,11,7,10, 10,10,7,7, 12,7,7,7, 7,7,7,7
		byte	7,7,7,7, 7,7,7,7, 7,7,7,10, 10,10,10,13
		byte	7,7,14,7, 7,7,7,5, 4,6,7,7, 7,7,7,7

		byte	15,15,15,15, 15,15,15,7, 7,7,7,15, 15,7,15,15
		byte	15,15,15,15, 7,7,15,16, 17,18,18,17, 7,13,15,19
		byte	20,21,22,23, 24,25,25,5, 26,27,28,29, 15,15,15,15
		byte	30,30,30,30, 30,30,30,7, 7,7,7,7, 7,7,7,7

		byte	30,30,30,30, 7,7,31,32, 7,7,7,7, 7,7,7,7
		byte	7,7,7,7, 7,7,7,7, 7,7,7,7, 7,7,7,7
		byte	7,7,7,7, 7,7,7,7, 7,7,7,7, 7,7,7,7
		byte	33,7,34,7, 7,35,36,7, 7,7,7,7, 7,7,7,37

		align	2

DBGOperFmtT:
		dc		DBGDispTstregs,DBGDispCmpregs,DBGDispBrDisp,DBGDispCmpimm,DBGDispRxRxRx,DBGDispRxRx,DBGDispPxPxPx,DBGDispNone
		dc		DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone
		dc		DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone
		dc		DBGDispNone,DBGDispNone,DBGDispNone,DBGDispSprRx,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone
		dc		DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispNone

		; Table of instruction mnemonic string addresses
		; If the most signficant 12 bits are $FFF then a second table is referred to.
		;
		align	2
DBGInsnMne:
		dc		mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst,mne_tst
		dc		mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp,mne_cmp
		dc		mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi,mne_cmpi
		dc		mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br,mne_br
		dc		$FFF0,$FFF1,$FFF2,mne_q,mne_q,mne_q,mne_biti,mne_addui,mne_addi,mne_subi,mne_muli,mne_divi,mne_addui,mne_subui,mne_mului,mne_divui
		dc		$FFF3,mne_mlo,mne_q,mne_andi,mne_ori,mne_eori,mne_q,mne_q,$FFF4,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_2addui,mne_4addui,mne_8addui,mne_16addui,mne_ldi
		dc		mne_q,mne_q,mne_mux,mne_q,mne_q,mne_q,mne_q,$FFF5,$FFF6,$FFF7,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_lb,mne_lbu,mne_lc,mne_lcu,mne_lh,mne_lhu,mne_lw,mne_q,mne_q,mne_q,mne_q,mne_lvwar,mne_swcr,mne_q,mne_lws,mne_lcl
		dc		mne_sb,mne_sc,mne_sh,mne_sw,mne_q,mne_q,mne_sti,mne_cas,mne_stset,mne_stmov,mne_stcmp,mne_stfnd,mne_q,mne_ldis,mne_sws,mne_cache
		dc		mne_jsr,mne_jsr,mne_jsr,mne_rts,mne_loop,mne_sys,mne_int,$FFF8,mne_mfspr,mne_mtspr,$FFF9,mne_movs,mne_lvb,mne_lvc,mne_lvh,mne_lvw
		dc		mne_lb,mne_lbu,mne_lc,mne_lcu,mne_lh,mne_lhu,mne_lw,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_sbx,mne_scx,mne_sh,mne_sw,mne_q,mne_q,mne_sti,mne_inc,mne_push,mne_pea,mne_pop,mne_link,mne_unlink,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		$FFFA,mne_nop,mne_rts,mne_rte,mne_rti,$FFFB,mne_stp,mne_sync,mne_memsb,mne_memdb,mne_cli,mne_sei,mne_rtd,mne_q,mne_q,mne_imm
DBGInsnMne0:
		dc		mne_add,mne_sub,mne_mul,mne_div,mne_addu,mne_subu,mne_mulu,mne_divu,mne_2addu,mne_4addu,mne_8addu,mne_16addu,mne_q,mne_q,mne_q,mne_q
		dc		mne_min,mne_max,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne1:
		dc		mne_cpuid,mne_redor,mne_redand,mne_par,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne2:
		dc		mne_pand,mne_por,mne_peor,mne_pnand,mne_pnor,mne_penor,mne_pandc,mne_porc,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne3:
		dc		mne_and,mne_or,mne_eor,mne_nand,mne_nor,mne_enor,mne_andc,mne_orc,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne4:
		dc		mne_shl,mne_shr,mne_shlu,mne_shru,mne_rol,mne_ror,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_shli,mne_shri,mne_shlui,mne_shrui,mne_roli,mne_rori,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne5:
		dc		mne_fmov,mne_q,mne_ftoi,mne_itof,mne_fneg,mne_fabs,mne_fsign,mne_fman,mne_fnabs,mne_q,mne_q,mne_q,mne_fstat,mne_frm,mne_q,mne_q
DBGInsnMne6:
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_fcmp,mne_fadd,mne_fsub,mne_fmul,mne_fdiv,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_fcmp,mne_fadd,mne_fsub,mne_fmul,mne_fdiv,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
		dc		mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMne7:
DBGInsnMne8:
		dc		mne_mov,mne_neg,mne_not,mne_abs,mne_sign,mne_cntlz,mne_cntlo,mne_cntpop,mne_sxb,mne_sxc,mne_sxh,mne_com,mne_zxb,mne_zxc,mne_zxh,mne_q
DBGInsnMne9:
		dc		mne_bfins,mne_bfset,mne_bfclr,mne_bfchg,mne_bfextu,mne_bfext,mne_bfinsi,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMneA:
		dc		mne_q,mne_q,mne_tlbrdreg,mne_tlbwrreg,mne_tlbwi,mne_tlben,mne_tlbdis,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMneB:
		dc		mne_bcdadd,mne_bcdsub,mne_bcdmul,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q,mne_q
DBGInsnMneT:
		dc		DBGInsnMne0,DBGInsnMne1,DBGInsnMne2,DBGInsnMne3,DBGInsnMne4,DBGInsnMne5,DBGInsnMne6,DBGInsnMne7,DBGInsnMne8,DBGInsnMne9,DBGInsnMneA,DBGInsnMneB

; Table of predicate conditions
;
DBGPredCons:
		byte	"f  ","f  ","eq ","ne ","le ","gt ","lt ","ge ","leu","gtu","ltu","geu","   ","   ","   ","   "

; Special purpose register names
;
DBGSpr:
		byte	"p0 ","p1 ","p2 ","p3 ","p4 ","p5 ","p6 ","p7 ","p8 ","p9 ","p10","p11","p12","p13","p14","p15"
		byte	"c0 ","c1 ","c2 ","c3 ","c4 ","c5 ","c6 ","c7 ","c8 ","c9 ","c10","c11","c12","c13","c14","c15"
		byte	"zs ","ds ","es ","fs ","gs ","hs ","ss ","cs ","zsl","dsl","esl","fsl","gsl","hsl","ssl","csl"
		byte	"pra","   ","tck","lc ","   ","   ","asd","sr ","   ","   ","   ","   ","   ","   ","   ","   "

; Table of mnemonics
;
mne_add:	byte	"ad",'d'|$80
mne_addu:	byte	"add",'u'|$80
mne_addui:	byte	"addu",'i'|$80
mne_and:	byte	"an",'d'|$80
mne_andi:	byte	"and",'i'$80
mne_bfchg:	byte	"bfch",'g'|$80
mne_bfclr:	byte	"bfcl",'r'|$80
mne_bfext:	byte	"bfex",'t'|$80
mne_bfextu:	byte	"bfext",'u'|$80
mne_bfins:	byte	"bfin",'s'|$80
mne_bfinsi:	byte	"bfins",'i'|$80
mne_bfset:	byte	"bfse",'t'|$80
mne_br:		byte	"b",'r'|$80
mne_brk:	byte	"br",'k'|$80
mne_bsr:	byte	"bs",'r'|$80
mne_cmp:	byte	"cm",'p'|$80
mne_cmpi:	byte	"cmp",'i'|$80
mne_div:	byte	"di",'v'|$80
mne_divi:	byte	"div",'i'|$80
mne_divu:	byte	"div",'u'|$80
mne_divui:	byte	"divu",'i'|$80
mne_eor:	byte	"eo",'r'|$80
mne_eori:	byte	"eor",'i'|$80
mne_imm:	byte	"im",'m'|$80
mne_jsr		byte	"js",'r'|$80
mne_lb:		byte	"l",'b'|$80
mne_lbu:	byte	"lb",'u'|$80
mne_lc:		byte	"l",'c'|$80
mne_lcu:	byte	"lc",'u'|$80
mne_ldi:	byte	"ld",'i'|$80
mne_ldis:	byte	"ldi",'s'|$80
mne_lh:		byte	"l",'h'|$80
mne_lhu:	byte	"lh",'u'|$80
mne_loop:	byte	"loo",'p'|$80
mne_lvb:	byte	"lv",'b'|$80
mne_lvc:	byte	"lv",'c'|$80
mne_lvh:	byte	"lv",'h'|$80
mne_lvw:	byte	"lv",'w'|$80
mne_lw:		byte	"l",'w'|$80
mne_mfspr:	byte	"mfsp",'r'|$80
mne_mtspr:	byte	"mtsp",'r'|$80
mne_mov:	byte	"mo",'v'|$80
mne_movs:	byte	"mov",'s'|$80
mne_mul:	byte	"mu",'l'|$80
mne_muli:	byte	"mul",'i'|$80
mne_mulu:	byte	"mul",'u'|$80
mne_mului:	byte	"mulu",'i'|$80
mne_nop:	byte	"no",'p'|$80
mne_or:		byte	"o",'r'|$80
mne_ori:	byte	"or",'i'|$80
mne_q:		byte	"??",'?'|$80
mne_rol:	byte	"ro",'l'|$80
mne_roli:	byte	"rol",'i'|$80
mne_ror:	byte	"ro",'r'|$80
mne_rori:	byte	"ror",'i'|$80
mne_rtd:	byte	"rt",'d'|$80
mne_rte:	byte	"rt",'e'|$80
mne_rti:	byte	"rt",'i'|$80
mne_rts:	byte	"rt",'s'|$80
mne_sb:		byte	"s",'b'|$80
mne_sc:		byte	"s",'c'|$80
mne_sh:		byte	"s",'h'|$80
mne_shl:	byte	"sh",'l'|$80
mne_shli:	byte	"shl",'i'|$80
mne_shr:	byte	"sh",'r'|$80
mne_shri:	byte	"shr",'i'|$80
mne_shru:	byte	"shr",'u'|$80
mne_shrui:	byte	"shru",'i'|$80
mne_stp:	byte	"st",'p'|$80
mne_sub:	byte	"su",'b'|$80
mne_subu:	byte	"sub",'u'|$80
mne_sw:		byte	"s",'w'|$80
mne_sync:	byte	"syn",'c'|$80
mne_sys:	byte	"sy",'s'|$80
mne_tlben:	byte	"tlbe",'n'|$80
mne_tlbdis:	byte	"tlbdi",'s'|$80
mne_tlbrdreg:	byte	"tlbrdre",'g'|$80
mne_tlbwi:	byte	"tlbw",'i'|$80
mne_tlbwrreg:	byte	"tlbwrre",'g'|$80
mne_tst:	byte	"ts",'t'|$80

msgDebugger:
	byte	"Thor Debugger (C) 2015 Robert Finch",0

