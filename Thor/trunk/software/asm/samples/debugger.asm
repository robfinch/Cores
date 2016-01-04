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

		bss
		org		$1000
DBGBuf		fill.b	84,0
DBGBufndx	db		0

		code
		org		$FFFFC800

;------------------------------------------------------------------------------
; r2 = text output column
; r6 = text output row
; r5 = disassembly address
;------------------------------------------------------------------------------

public Debugger:
		sys		#190				; save context
		ldi		sp,#$2bf8
		addui	sp,sp,#-24
		sws		c1,[sp]
		sws		ds,8[sp]
		sws		ds.lmt,16[sp]
		ldis	ds,#DBG_DS
		ldis	ds.lmt,#$8000
		sws		ds,zs:IOFocusNdx_
		sync
		bsr		KeybdClearBuf
		bsr		VideoInit2
		bsr		VBClearScreen
		mov		r1,r0				; row = 0
		mov		r2,r0				; col = 0
		ldi		r6,#2				; set cursor pos
		sys		#10					; call video BIOS
;		bsr		DBGRamTest
		lla		r1,cs:msgDebugger	; convert address to linear
		ldi		r6,#$14				; Try display string
		sys		#10					; call video BIOS
		mov		r6,r0
		mov		r2,r0
		ldi		r5,#$FFFF8000
		bsr		DBGDisassem20
;		br		Debugger_exit

promptAgain:
		; Clear input buffer
		sb		r0,DBGBufndx
		ldis	lc,#$14			; (21-1)*4
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
		cmpi	p0,r1,#_BS
p0.eq	br		.backspace
		cmpi	p0,r1,#' '
p0.ltu	br		.0001
		; some other character, store in buffer if it will fit
		lbu		r3,DBGBufndx
		cmpi	p3,r3,#80		; max 80 chars
p3.ltu	bsr		DBGDispChar
p3.ltu	sb		r1,DBGBuf[r3]
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
		addui	r1,r1,#DBGBuf
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
		cmpi	p0,r1,#'M'
p0.eq	br		DBGDumpMem
		cmpi	p0,r1,#'x'
p0.eq	br		Debugger_exit
		br		promptAgain
Debugger_exit:
		lws		c1,[sp]
		lws		ds,8[sp]
		lws		ds.lmt,16[sp]
		sws		ds,zs:IOFocusNdx_
		sys		#191			; restore context
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
		bsr		DBGDisassem20
		br		promptAgain

;------------------------------------------------------------------------------
; Dump memory bytes
; M <start address>
;------------------------------------------------------------------------------

DBGDumpMem:
		addui	r4,r4,#1			; advance a character past 'M'
		bsr		DBGGetHexNumber
		mov		r12,r1
		tst		p0,r8
p0.eq	jmp		promptAgain
		bsr		VBClearScreen2
		addui	r13,r12,#200
		ldi		r6,#2
		mov		r2,r0
.0002:
		mov		r14,r0
		ldi		r1,#'>'
		bsr		DBGDispChar
		mov		r4,r12
		bsr		DBGDisplayHalf
.0001:
		bsr		space1
		lbu		r4,zs:[r12+r14]
		bsr		DBGDisplayByte
		addui	r14,r14,#1
		cmpi	p0,r14,#8
p0.ltu	br		.0001
		bsr		space1
		mov		r14,r0
		bsr		ReverseVideo		; reverse video attribute
.0003:
		lbu		r1,zs:[r12+r14]
		cmpi	p0,r1,#' '
p0.ltu	ldi		r1,#'.'
		bsr		DBGDispChar
		addui	r14,r14,#1
		cmpi	p0,r14,#8
p0.ltu	br		.0003
		bsr		ReverseVideo		; put video back to normal
		addui	r6,r6,#1
		addu	r12,r12,r14
		cmp		p0,r12,r13
p0.ltu	br		.0002
		jmp		promptAgain
		
;------------------------------------------------------------------------------
; DBGGetHexNumber:
;	Get a hexi-decimal number from the input buffer.
;
; Parameters:
;	r4 = text pointer (updated)
; Returns:
;	r1 = number
;   r8 = number of digits
;------------------------------------------------------------------------------

DBGGetHexNumber:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldis	lc,#80			; max 80 chars
		mov		r7,r0			; working accum.
		mov		r8,r0			; number of digits
.0003:
		lbu		r1,[r4]			; skip leading spaces
		cmpi	p0,r1,#' '
p0.leu	addui	r4,r4,#1
p0.leu	br		.0003
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
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; DBGCharToHex:
;	Convert a single ascii character to hex nybble.
; Parameters:
;	r1 = ascii character to convert
; Returns:
;	r1 = binary nybble
;	r3 = 1 if conversion successful, 0 otherwise
;------------------------------------------------------------------------------

DBGCharToHex:
		cmpi	p0,r1,#'0'
p0.ltu	br		.0004
		cmpi	p0,r1,#'9'
p0.gtu	br		.0001
		addui	r1,r1,#-'0'
		ldi		r3,#1
		rts
.0001:
		cmpi	p0,r1,#'A'
p0.ltu	br		.0004
		cmpi	p0,r1,#'F'
p0.gtu	br		.0003
		subui	r1,r1,#'A'-10
		ldi		r3,#1
		rts
.0003:
		cmpi	p0,r1,#'a'
p0.ltu	br		.0004
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
		sw		sp,reg_save+8*27
		ldi		sp,#$2bf8
		addui	sp,sp,#-104
		sws		c1,[sp]
		sws		ds,8[sp]
		sws		ds.lmt,16[sp]
		sw		r1,24[sp]
		sw		r2,32[sp]
		sw		r3,40[sp]
		sw		r4,48[sp]
		sw		r5,56[sp]
		sw		r6,64[sp]
		sw		r7,72[sp]
		sw		r8,80[sp]
		sw		r9,88[sp]
		sw		r10,96[sp]

		ldis	ds,#DBG_DS
		ldis	ds.lmt,#$8000
		sync
		bsr		VBClearScreen2
		mov		r2,r0
		mov		r6,r0
		ldi		r1,#msgDebugger
		bsr		DBGDispString
		mfspr	r5,dpc
		bsr		DBGDisassem20

		lws		c1,[sp]
		lws		ds,8[sp]
		lws		ds.lmt,16[sp]
		lw		r1,24[sp]
		lw		r2,32[sp]
		lw		r3,40[sp]
		lw		r4,48[sp]
		lw		r5,56[sp]
		lw		r6,64[sp]
		lw		r7,72[sp]
		lw		r8,80[sp]
		lw		r9,88[sp]
		lw		r10,96[sp]
		lw		sp,reg_save+8*27
		rtd	
endpublic

;------------------------------------------------------------------------------
; Disassemble 20 lines of code.
;------------------------------------------------------------------------------

DBGDisassem20:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldis	lc,#19
		ldi		r6,#3
.0001:
		bsr		Disassem
		addu	r5,r5,r10
		addui	r6,r6,#1
		loop	.0001
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGPrompt:
		addui	sp,sp,#-8
		sws		c1,[sp]
		mov		r2,r0
		ldi		r1,#'D'
		bsr		DBGDispChar
		ldi		r1,#'B'
		bsr		DBGDispChar
		ldi		r1,#'G'
		bsr		DBGDispChar
		ldi		r1,#'>'
		bsr		DBGDispChar
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Disassem:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sws		c2,8[sp]
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
		ori		r3,r1,#Debugger & $FFFF0000	; set high order address bits
		bsr		DBGDisplayMne
		br		.dispOper
.0002:
		andi	r1,r1,#15
		lcu		r3,cs:DBGInsnMneT[r1]
		ori		r3,r3,#Debugger & $FFFF0000
		bsr		DBGGetFunc
		lcu		r3,cs:[r3+r1*2]
		br		.dispMne
.dispOper:
		lbu		r1,zs:1[r5]
		lbu		r1,cs:DBGOperFmt[r1]
		jci		c1,cs:DBGOperFmtT[r1]
		ldi		r1,#48
		sc		r1,hs:LEDS
;		lcu		r1,cs:DBGOperFmtT[r1]
;		ori		r1,r1,#Debugger & $FFFF0000
;		mtspr	c2,r1
;		jsr		[c2]
.exit:
		lws		c1,[sp]
		lws		c2,8[sp]
		addui	sp,sp,#16
		rts

;------------------------------------------------------------------------------
; Display the disassembly address.
;------------------------------------------------------------------------------

DisplayAddr:
		addui	sp,sp,#-8
		sws		c1,[sp]
		mov		r4,r5
		bsr		DBGDisplayHalf
		bsr		space3
		lws		c1,[sp]
		addui	sp,sp,#8
		rts
space1:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldi		r1,#' '
		bsr		DBGDispChar
		lws		c1,[sp]
		addui	sp,sp,#8
		rts
space3:
		addui	sp,sp,#-8
		sws		c1,[sp]
		bsr		space1
		bsr		space1
		bsr		space1
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGDisplayHalf:
		addui	sp,sp,#-8
		sws		c1,[sp]
		rori	r4,r4,#16
		bsr		DBGDisplayCharr
		roli	r4,r4,#16
		bsr		DBGDisplayCharr
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDisplayCharr:
		addui	sp,sp,#-8
		sws		c1,[sp]
		rori	r4,r4,#8
		bsr		DBGDisplayByte
		roli	r4,r4,#8
		bsr		DBGDisplayByte
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDisplayByte:
		addui	sp,sp,#-8
		sws		c1,[sp]
		rori	r4,r4,#4
		bsr		DBGDisplayNybble
		roli	r4,r4,#4
		bsr		DBGDisplayNybble
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDisplayNybble:
		addui	sp,sp,#-8
		sws		c1,[sp]
		andi	r1,r4,#15
		cmpi	p0,r1,#9
p0.gtu	addui	r1,r1,#7
		addui	r1,r1,#'0'
		bsr		DBGDispChar
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; DBGDispChar:
;
; Display a character on the debug screen.
;
; Parameters:
;	r1 = character to display
;	r2 = text column
;	r6 = text row
; Returns:
;	r2 incremented
;------------------------------------------------------------------------------

DBGDispChar:
		addui	sp,sp,#-16
		sws		c1,[sp]				; save return address
		sw		r7,8[sp]			; save r7 work register
		andi	r1,r1,#$7F			; make sure in range
		bsr		VBAsciiToScreen		; convert to screen char
		ori		r1,r1,#DBG_ATTR		; add in attribute
		lcu		r7,Textcols			; figure out memory index
		mulu	r7,r6,r7			; row * num cols
		_4addui	r7,r7,#$10000	; + text base + (row * num cols) * 4
		_4addu	r7,r2,r7			; + column * 4
		sh		r1,hs:[r7]			; store the char
		addui	r2,r2,#1			; increment text position
		lws		c1,[sp]				; restore return address
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

;------------------------------------------------------------------------------
; Display a string of text on the debug screen.
;------------------------------------------------------------------------------

DBGDispString:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
		mov		r7,r1
.0001:
		lbu		r1,zs:[r7]
		tst		p0,r1
p0.eq	br		.0002
		bsr		DBGDispChar
		addui	r7,r7,#1
		br		.0001
.0002:
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
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
		addui	sp,sp,#-24
		sws		c1,[sp]
		sws		lc,8[sp]
		sw		r7,16[sp]
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
		lws		c1,[sp]
		lws		lc,8[sp]
		lw		r7,16[sp]
		addui	sp,sp,#24
		rts

;------------------------------------------------------------------------------
; Display a predicate.
;
; The always true predicate and special predicate values don't display.
;------------------------------------------------------------------------------

DBGDisplayPred:
		addui	sp,sp,#-8
		sws		c1,[sp]
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
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Display the condition portion of the predicate.
;------------------------------------------------------------------------------

DBGDispCond:
		addui	sp,sp,#-8
		sws		c1,[sp]
		andi	r7,r1,#15
		addu	r7,r7,r7
		addu	r7,r7,r1
		lbu		r1,cs:DBGPredCons[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGPredCons+1[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGPredCons+2[r7]
		bsr		DBGDispChar
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Display a mnemonic.
; Parameters:
;	r3 = pointer to mnemonic string
;------------------------------------------------------------------------------

DBGDisplayMne:
		addui	sp,sp,#-8
		sws		c1,[sp]
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
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Display a register
;------------------------------------------------------------------------------

DBGDispReg:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
		mov		r7,r1
		ldi		r1,#'r'
DBGDispBx1:
		bsr		DBGDispChar
		cmpi	p0,r7,#10
p0.geu	divui	r1,r7,#10
p0.geu	addui	r1,r1,#'0'
p0.geu	bsr		DBGDispChar
		modui	r1,r7,#10
		addui	r1,r1,#'0'
		bsr		DBGDispChar
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

;------------------------------------------------------------------------------
; Display a bit number
;------------------------------------------------------------------------------

DBGDispBReg:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
		mov		r7,r1
		ldi		r1,#'b'
		br		DBGDispBx1

;------------------------------------------------------------------------------
; Display a special purpose register
;------------------------------------------------------------------------------

DBGDispSpr:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
		addu	r7,r1,r1
		addu	r7,r7,r1			; r7 = r1 * 3
		lbu		r1,cs:DBGSpr[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGSpr+1[r7]
		bsr		DBGDispChar
		lbu		r1,cs:DBGSpr+2[r7]
		cmpi	p0,r1,#' '
p0.ne	bsr		DBGDispChar
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGComma:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldi		r1,#','
		bsr		DBGDispChar
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Display registers for TST instruction.
;------------------------------------------------------------------------------

DBGDispTstregs:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:1[r5]
		andi	r1,r1,#15
		bsr		DBGDispSpr
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#$3f
		bsr		DBGDispReg
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDispCmpregs:
		addui	sp,sp,#-8
		sws		c1,[sp]
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
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDispBrDisp:
		addui	sp,sp,#-8
		sws		c1,[sp]
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
		bsr		DBGDisplayHalf
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

DBGDispCmpimm:
		addui	sp,sp,#-8
		sws		c1,[sp]
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
		bsr		DBGDisplayHalf
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

; Used by mtspr
DBGDispSprRx:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
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
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

; Format #4
;
DBGDispRxRxRx:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
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
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

; Format #5
;
DBGDispRxRx:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
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
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

; Format #6
;
DBGDispPxPxPx:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r7,8[sp]
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
		lws		c1,[sp]
		lw		r7,8[sp]
		addui	sp,sp,#16
		rts

; Format #7
;
DBGDispNone:
		rts

; Format #8 (biti)
;
DBGDispPxRxImm:
		addui	sp,sp,#-16
		sws		c1,[sp]
		ldi		r2,#54			; tab out to column 54
		lbu		r1,zs:2[r5]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r5]
		andi	r7,r7,#3
		_4addu	r1,r7,r1
		bsr		DBGDispSpr	
		bsr		DBGComma
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:3[r5]
		shrui	r1,r1,#4
		lbu		r7,zs:4[r5]
		_16addu	r1,r7,r1
		bsr		DBGDispImm
		lws		c1,[sp]
		addui	sp,sp,#16
		rts

; Format #9 (adduis)
;
DBGDispRxImm:
		addui	sp,sp,#-8
		sws		c1,[sp]
		lbu		r1,zs:2[r5]
		andi	r1,r1,#63
		bsr		DBGDispReg
		bsr		DBGComma
		lbu		r1,zs:2[r2]
		shrui	r1,r1,#6
		lbu		r7,zs:3[r2]
		_4addu	r1,r7,r1
		bsr		DBGDispImm
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Display an immediate value.
;------------------------------------------------------------------------------

DBGDispImm:
		addui	sp,sp,#-16
		sws		c1,[sp]
		sw		r4,8[sp]
		mov		r4,r1
		ldi		r1,#'#'
		bsr		DBGDispChar
		ldi		r1,#'$'
		bsr		DBGDispChar
		cmpi	p0,r4,#$FFFF
p0.gtu	bsr		DBGDisplayHalf
p0.gtu	br		.exit
		cmpi	p0,r4,#$FF
p0.gtu	bsr		DBGDisplayCharr
p0.gtu	br		.exit
		bsr		DBGDisplayByte
.exit:
		lw		c1,[sp]
		lw		r4,8[sp]
		addui	sp,sp,#16
		rts

;------------------------------------------------------------------------------
; DBGGetFunc:
;    Get the function code bits from the instruction. These come from one of
; four different locations depending on the opcode.
;
; Parameters:
;	r1 = opcode group (0 to 15)
; Returns:
;	r1 = function code
;------------------------------------------------------------------------------

DBGGetFunc:
		jci		c0,cs:DBGFuncT[r1]
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

;------------------------------------------------------------------------------
; Checker-board RAM testing routine.
;
; Ram is tested from $6000 to $7FFFFFF. The first 24k of RAM is not tested,
; as 16k underlays the scratchpad RAM and is unaccessible and 8kb is used by
; the kernel.
;
; First uses the pattern AAAAAAAA to memory
;                        55555555
;
; Then uses the pattern  55555555 to memory
;                        AAAAAAAA
;------------------------------------------------------------------------------

DBGRamTest:
		addui	sp,sp,#-8
		sws		c1,[sp]
		ldi		r10,#$AAAAAAAA
		ldi		r11,#$55555555
		bsr		DBGRamTest1
		ldi		r10,#$55555555
		ldi		r11,#$AAAAAAAA
		bsr		DBGRamTest1
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DBGRamTest1:
		addui	sp,sp,#-8
		sws		c1,[sp]

		mov		r1,r10
		mov		r3,r11
		ldi		r5,#$6000
		ldi		lc,#$3FF3FF		; (32MB - 24kB)/8 - 1
		mov		r8,r0
.0001:
		sh		r1,zs:[r5]
		sh		r3,zs:4[r5]
		addui	r5,r5,#8
		andi	r4,r5,#$FFF
		tst		p0,r4
p0.eq	shrui	r4,r5,#12
p0.eq	ldi		r2,#0
p0.eq	ldi		r6,#1
p0.eq	bsr		DBGDisplayCharr
		loop	.0001

		ldi		r5,#$6000
		ldi		lc,#$3FF3FF		; (32MB - 24kB)/8 - 1
.0002:
		lh		r1,zs:[r5]
		lh		r3,zs:4[r5]
		cmp		p0,r1,r10
p0.ne	mov		r7,r1
p0.ne	bsr		DBGBadRam
		cmp		p0,r3,r11
p0.ne	mov		r7,r3
p0.ne	bsr		DBGBadRam
		addui	r5,r5,#8
		andi	r4,r5,#$FFF
		tst		p0,r4
p0.eq	shrui	r4,r5,#12
p0.eq	ldi		r2,#0
p0.eq	ldi		r6,#1
p0.eq	bsr		DBGDisplayCharr
		loop	.0002
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

;------------------------------------------------------------------------------
; Dispay bad ram nessage with address and data.
;------------------------------------------------------------------------------

DBGBadRam:
		addui	sp,sp,#-8
		sws		c1,[sp]
		lla		r1,cs:msgBadRam
		ldi		r2,#0
		ldi		r6,#2
		addu	r6,r6,r8
		bsr		DBGDispString
		mov		r4,r5
		bsr		DBGDisplayHalf
		bsr		space1
		mov		r4,r7
		bsr		DBGDisplayHalf
		addui	r8,r8,#1
		andi	r8,r8,#15
		cmpi	p0,r8,#15
p0.eq	ldis	lc,#1
		lws		c1,[sp]
		addui	sp,sp,#8
		rts

msgBadRam:
	byte	"Menory failed at: ",0

;------------------------------------------------------------------------------
; Reverse the video attribute.
;------------------------------------------------------------------------------

ReverseVideo:
		lhu		r1,NormAttr
		shrui	r2,r1,#9
		shli	r3,r1,#9
		andi	r2,r2,#%111111111_0000000000
		andi	r3,r3,#%111111111_000000000_0000000000
		or		r1,r2,r3
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Tables
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

	align	2
DBGFuncT:
		dc		gf0,gf1,gf2,gf3,gf4,gf5,gf6,gf7,gf8,gf9,gfA,gfB,gf0,gf0,gf0,gf0

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
		byte	15,15,15,15, 7,7,15,16, 17,18,18,17, 7,38,15,19
		byte	20,21,22,23, 24,25,25,5, 26,27,28,29, 15,15,15,15
		byte	30,30,30,30, 30,30,30,7, 7,7,7,7, 7,7,7,7

		byte	30,30,30,30, 7,7,31,32, 7,7,7,7, 7,7,7,7
		byte	7,7,7,7, 7,7,7,7, 7,7,7,7, 7,7,7,7
		byte	7,7,7,7, 7,7,7,7, 7,7,7,7, 7,7,7,7
		byte	33,7,34,7, 7,35,36,7, 7,7,7,7, 7,7,7,37

		align	2

DBGOperFmtT:
		dc		DBGDispTstregs,DBGDispCmpregs,DBGDispBrDisp,DBGDispCmpimm,DBGDispRxRxRx,DBGDispRxRx,DBGDispPxPxPx,DBGDispNone
		dc		DBGDispPxRxImm,DBGDispRxImm,DBGDispNone,DBGDispNone,DBGDispNone,DBGDispRxImm,DBGDispNone,DBGDispNone
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
mne_16addu:	byte	"16add",'u'|$80
mne_2addu:	byte	"2add",'u'|$80
mne_4addu:	byte	"4add",'u'|$80
mne_8addu:	byte	"8add",'u'|$80
mne_16addui:	byte	"16addu",'i'|$80
mne_2addui:	byte	"2addu",'i'|$80
mne_4addui:	byte	"4addu",'i'|$80
mne_8addui:	byte	"8addu",'i'|$80
mne_add:	byte	"ad",'d'|$80
mne_addi:	byte	"add",'i'|$80
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
mne_biti:	byte	"bit",'i'|$80
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
mne_lws:	byte	"lw",'s'|$80
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

