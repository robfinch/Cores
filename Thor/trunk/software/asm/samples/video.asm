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
; Video BIOS routines don't touch the data segment. It is assumed that a
; different data segment will be is use for each text controller.                                                                          
; ============================================================================

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

public VBClearScreen:
		ldi		r1,#' '
		lh		r2,NormAttr
		andi	r2,r2,#-1024
		or		r2,r2,r1
		ldis	lc,#SCRSZ-1
		lh		r1,Vidptr
;		ldi		r1,#TEXTSCR
		stset.hi	r2,hs:[r1]
		rts
endpublic

public VBClearScreen2:
		ldis	lc,#SCRSZ-1
		ldi		r2,#' '|%000011000_111111111_00_00000000;
		ldi		r1,#TEXTSCR2
		stset.hi	r2,hs:[r1]
		rts
endpublic

;------------------------------------------------------------------------------
; Scroll the screen upwards.
;------------------------------------------------------------------------------

ScrollUp:
		addui	r31,r31,#-8
		sws		c1,[r31]
		mov		r1,r0
		mov		r2,r0
		lcu		r3,Textcols
		lcu		r4,Textrows
		ldi		r5,#1
		bsr		VBScrollWindowUp
		addui	r1,r4,#-1
		bsr		BlankLine
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank
; Trashes:
;	r2,r3,r4
;------------------------------------------------------------------------------

BlankLine:
		lcu		r2,Textcols
		mulu	r1,r1,r2
		_4addu	r3,r1,r0
		lh		r1,NormAttr
		ori		r1,r1,#$20
		lh		r4,Vidptr
.0001:
		sh		r1,[r4+r3]
		addui	r3,r3,#4
		addui	r2,r2,#-1
		tst		p0,r2
p0.ne	br		.0001
		rts

;------------------------------------------------------------------------------
; Turn cursor on or off.
;------------------------------------------------------------------------------

VBCursorOn:
CursorOn:
		addui	r31,r31,#-16
		sw		r1,zs:8[r31]
		sw		r2,zs:[r31]
		lh		r2,Vidregs
		ldi		r1,#$40
		sh		r1,hs:32[r2]
		ldi		r1,#$1F
		sh		r1,hs:36[r2]
		lw		r2,zs:[r31]
		lw		r1,zs:8[r31]
		addui	r31,r31,#16
		mov		r6,r0
		rts

VBCursorOff:
CursorOff:
		addui	r31,r31,#-16
		sw		r1,zs:8[r31]
		sw		r2,zs:[r31]
		lh		r2,Vidregs
		ldi		r1,#$20
		sh		r1,hs:32[r2]
		mov		r1,r0
		sh		r1,hs:36[r2]
		lw		r2,zs:[r31]
		lw		r1,zs:8[r31]
		addui	r31,r31,#16
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Get the number of text rows and columns from the video controller.
;------------------------------------------------------------------------------

GetTextRowscols:
		lh		r2,Vidregs
		lvc		r1,hs:0[r2]
		sc		r1,Textcols
		lvc		r1,hs:4[r2]
		sc		r1,Textrows
		rts

;------------------------------------------------------------------------------
; Set cursor to home position.
;------------------------------------------------------------------------------

public HomeCursor:
		sc		r0,CursorX
		sc		r0,CursorY
endpublic

;------------------------------------------------------------------------------
; SyncVideoPos:
;
; Synchronize the absolute video position with the cursor co-ordinates.
; Does not modify any predicates. Leaf routine.
;------------------------------------------------------------------------------

SyncVideoPos:
		addui	r31,r31,#-32
		sw		r1,16[r31]			; save off some working regs
		sw		r2,8[r31]
		sw		r3,[r31]
		sws		hs,24[r31]
		ldis	hs,#$FFD00000
		ldi		r1,#5
		sc		r1,hs:LEDS
		lc		r2,CursorY
		lc		r3,Textcols
		mulu	r1,r2,r3
		lc		r2,CursorX
		addu	r1,r1,r2
		sc		r1,VideoPos
		lh		r3,Vidregs			; r3 = address of video registers
		sh		r1,hs:44[r3]		; Update the position in the text controller
		lws		hs,24[r31]
		lw		r3,[r31]			; restore the regs
		lw		r2,8[r31]
		lw		r1,16[r31]
		addui	r31,r31,#32
		rts

;------------------------------------------------------------------------------
; Video BIOS
; Video Exception #10
;
; Parameters:
;	r1 to r5 as needed
;	r6 = Function
; Returns:
;	r6 = 0 if everything ok, otherwise BIOS error code
;
; 0x02 = Set Cursor Position	r1 = row, r2 = col 
; 0x03 = Get Cursor position	returns r1 = row, r2 = col
; 0x06 = Scroll Window up		r1=left, r2=top, r3=right, r4=bottom, r5=#lines
; 0x0A = Display character at cursor position, r1 = char, r2 = # times
; 0x14 = Display String	r1 = pointer to string
; 0x15 = Display number r1 = number, r2 = # digits
; 0x17 = Display Word r1 as hex = word
; 0x18 = Display Half word as hex r1 = half word
; 0x19 = Display Charr char in hex r1 = char
; 0x1A = Display Byte in hex r1 = byte
; 0x20 = Convert ascii to screen r1 = char to convert
; 0x21 = Convert screen to ascii r1 = char to convert
; 0x22 = clear screen
; 0x23 = set attribute  r1 = attribute
; 0x24 = turn cursor on
; 0x25 = turn cursor off
;------------------------------------------------------------------------------

MAX_VIDEO_BIOS_CALL = 0x25

		code
	    align   2
VideoBIOS_FuncTable:
		dc      VBUnsupported  ; 0x00
		dc      VBUnsupported
		dc      VBSetCursorPos ; 0x02
		dc      VBGetCursorPos ; 0x03
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBScrollWindowUp	; 0x06
		dc      VBUnsupported
		dc      VBUnsupported	; 0x08
		dc      VBUnsupported
		dc      VBDisplayCharRep
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported	; 0x10
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBDisplayString
		dc      PRTNUM
		dc      VBUnsupported
		dc      VBDispWord
		dc      VBDispHalf
		dc      VBDispCharr
		dc      VBDispByte
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBUnsupported
		dc      VBAsciiToScreen	; 0x20
		dc      VBScreenToAscii
		dc      VBClearScreen
		dc      VBSetNormAttribute
		dc		VBCursorOn
		dc		VBCursorOff		; 0x25

VideoBIOSCall:
		addui	r31,r31,#-16
		sws		c1,[r31]
		sws		hs,8[r31]
		ldis	hs,#$FFD00000
		cmpi	p0,r6,#MAX_VIDEO_BIOS_CALL
p0.ge	br		.badCallno
		jci		c1,cs:VideoBIOS_FuncTable[r6]
.0004:
;		bsr     UnlockVideoBIOS
		lws		c1,[r31]
		lws		hs,8[r31]
		addui	r31,r31,#16
		rte
.badCallno:
		ldi     r2,#E_BadFuncno
		br      .0004

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VBUnsupported:
		ldi     r2,#E_Unsupported
		rts

VBSetCursorPos:
		addui	r31,r31,#-8
		sws		c1,[r31]
		sc		r1,CursorY
		sc		r2,CursorX
		bsr		SyncVideoPos
		mov		r6,r0
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

VBGetCursorPos:
		lcu		r1,CursorY
		lcu		r2,CursorX
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Set the attribute to use for subsequent video output.
;------------------------------------------------------------------------------

VBSetNormAttribute:
		sh		r1,NormAttr
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VBDisplayCharRep:
		addui	r31,r31,#-8
		sws		c1,[r31]
		tst		p0,r2			; check if zero chars requested
p0.eq	br		.0002
		addui	r31,r31,#-16
		sws		c1,zs:[r31]
		sws		lc,zs:8[r31]
		addui	r2,r2,#-1
		mtspr	lc,r2			; loop count is one less
		addui	r2,r2,#1		; leaves r2 unchanged
.0001:
		bsr		VBDisplayChar
		loop	.0001
		lws		lc,zs:8[r31]
		lws		c1,zs:[r31]
		addui	r31,r31,#16
.0002:
		lws		c1,[r31]
		addui	r31,r31,#8
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;------------------------------------------------------------------------------

VBAsciiToScreen:
		zxb		r1,r1
		cmp		p0,r1,#' '
p0.le	ori		r1,r1,#$100
p0.le	br		.0003
		cmp		p0,r1,#$5B			; special test for  [ ] characters
p0.eq	br		.0002
		cmp		p0,r1,#$5D
p0.eq	br		.0002
		ori		r1,r1,#$100
		biti	p0,r1,#$20			; if bit 5 isn't set
p0.eq	br		.0003
		biti	p0,r1,#$40			; or bit 6 isn't set
p0.ne	andi	r1,r1,#$19F
.0003:
		mov		r6,r0
		rts
.0002:
		andi	r1,r1,#~$40
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
VBScreenToAscii:
		zxb		r1,r1
		cmpi	p0,r1,#$1B
p0.eq	br		.0004
		cmpi	p0,r1,#$1D
p0.eq	br		.0004
		cmpi	p0,r1,#27
p0.le	addui	r1,r1,#$60
		mov		r6,r0
		rts
.0004:
		ori		r1,r1,#$40
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Display a string on the screen.
; Parameters:
;	r1 = linear address pointer to string
;------------------------------------------------------------------------------

public VBDisplayString:
		addui	r31,r31,#-32
		sws		c1,[r31]			; save return address
		sws		lc,8[r31]		; save loop counter
		sw		r2,16[r31]
		sws		p0,24[r31]
		ldis	lc,#$FFF		; set max 4k
		mov		r2,r1
.0001:
		lbu		r1,zs:[r2]
		tst		p0,r1
p0.eq	br		.0002
		bsr		VBDisplayChar
		addui	r2,r2,#1
		loop	.0001
.0002:
		lws		c1,[r31]			; restore return address
		lws		lc,8[r31]		; restore loop counter
		lw		r2,16[r31]
		lws		p0,24[r31]
		addui	r31,r31,#32
		mov		r6,r0
		rts
endpublic

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VBDispWord:
		addui	r31,r31,#-8
		sws		c1,[r31]
		roli	r1,r1,#32
		bsr		VBDispHalf
		roli	r1,r1,#32
		bsr		VBDispHalf
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

VBDispHalf:
		addui	r31,r31,#-8
		sws		c1,[r31]
		rori	r1,r1,#16
		bsr		VBDispCharr
		roli	r1,r1,#16
		bsr		VBDispCharr
		lws		c1,[r31]
		addui	r31,r31,#8
		rts
	
VBDispCharr:
		addui	r31,r31,#-8
		sws		c1,[r31]
		rori	r1,r1,#8
		bsr		VBDispByte
		roli	r1,r1,#8
		bsr		VBDispByte
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

VBDispByte:
		addui	r31,r31,#-8
		sws		c1,[r31]
		rori	r1,r1,#4
		bsr		VBDispNybble
		roli	r1,r1,#4
		bsr		VBDispNybble
		lws		c1,[r31]
		addui	r31,r31,#8
		rts

VBDispNybble:
		addui	r31,r31,#-16
		sws		c1,[r31]
		sw		r1,8[r31]
		andi	r1,r1,#15
		cmpi	p0,r1,#10
p0.ge	addui	r1,r1,#7
		ori		r1,r1,#'0'
		bsr		VBDisplayChar
		lws		c1,[r31]
		lw		r1,8[r31]
		addui	r31,r31,#16
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; 'PRTNUM' prints the 64 bit number in r1, leading blanks are added if
; needed to pad the number of spaces to the number in r2.
; However, if the number of digits is larger than the no. in
; r2, all digits are printed anyway. Negative sign is also
; printed and counted in, positive sign is not.
;
; r1 = number to print
; r2 = number of digits
; Register Usage
;	r5 = number of padding spaces
;------------------------------------------------------------------------------
PRTNUM:
		addui	r31,r31,#-48
		sws		c1,zs:[r31]
		sw		r3,zs:8[r31]
		sw		r5,zs:16[r31]
		sw		r6,zs:24[r31]
		sw		r7,zs:32[r31]
		lw		r4,zs:40[r31]
		ldi		r7,#NUMWKA	; r7 = pointer to numeric work area
		mov		r6,r1		; save number for later
		mov		r5,r2		; r5 = min number of chars
		tst		p0,r1		; is it negative? if not
p0.lt	subu	r1,r0,r1	; else make it positive
p0.lt	addui	r5,r5,#-1	; one less for width count
PN2:
	ldi		r3,#10
PN1:
		divui	r3,r1,#10	; r3 = r1/10 divide by 10
		mului	r4,r3,#10
		subu	r2,r1,r4	; r2 = r1 mod 10
		mov		r1,r3		; r1 = r1 / 10
		addui	r2,r2,#'0'	; convert remainder to ascii
		sb		r2,[r7]		; and store in buffer
		addui   r7,r7,#1
		addui   r5,r5,#-1	; decrement width
		tst		p0,r1
p0.ne	br		PN1
PN6:
		tst		p0,r5	; test pad count, skip padding if not needed
p0.le	br		PN4
		ldi		r1,#' '
		mov		r2,r5
		bsr		VBDisplayCharRep	; display the required leading spaces
PN4:
		tst		p0,r6	; is number negative?
p0.ge	br		PN5
		ldi		r1,#'-'	; if so, display the sign
		bsr		VBDisplayChar
PN5:
		subui   r7,r7,#1
		lb		r1,[r7]		; now unstack the digits and display
		bsr		VBDisplayChar
		cmpi	p0,r7,#NUMWKA
p0.gt	br		PN5
PNRET:
		lws		c1,zs:[r31]
		lw		r3,zs:8[r31]
		lw		r5,zs:16[r31]
		lw		r6,zs:24[r31]
		lw		r7,zs:32[r31]
		lw		r4,zs:40[r31]
		addui	r31,r31,#48
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = row
;	r2 = col
; Returns:
;	r1 = char+attrib
;------------------------------------------------------------------------------

VBGetCharAt:
		shli	r1,r1,#1
		lcu		r1,cs:LineTbl[r1]
		_4addu	r1,r2,r1
		lhu		r3,Vidptr
		lhu		r1,[r3+r1]
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = left
;	r2 = top
;	r3 = right
;	r4 = bottom
;------------------------------------------------------------------------------

VBScrollWindowUp:
		addui	r31,r31,#-96
		sw		r1,[r31]
		sw		r2,8[r31]
		sw		r3,16[r31]
		sw		r4,24[r31]
		sw		r5,32[r31]
		sw		r7,48[r31]
		sw		r9,56[r31]
		sw		r10,64[r31]
		sw		r11,72[r31]
		sw		r12,80[r31]
		sw		r13,88[r31]
		mov		r7,r1				; r7 = left
		mov		r6,r2
		lhu		r11,Vidptr
		lcu		r13,Textcols		; r13 = # cols
.next:
		mulu	r9,r2,r13			; r9 = row offset
		_4addu	r9,r9,r0			; r9 *= 4 for half-words
		_4addu	r9,r1,r9			; r9 += col * 4
		mulu	r10,r13,r5			; r10 = #lines to scroll * #cols
		_4addu	r10,r10,r9			; r10 = 4* r10 + r9
		lhu		r12,[r11+r10]		; r12 = char+atrrib
		sh		r12,[r11+r9]		; mem = char + attrib
		; Now increment the video position
		addui	r1,r1,#1
		cmp		p0,r1,r3	; hit right edge ?
p0.eq	mov		r1,r7		; if yes, reset back to left
p0.eq	addui	r2,r2,#1	; and increment row
		cmp		p0,r2,r4	; hit bottom ?
p0.ne	br		.next
		lw		r1,[r31]
		lw		r2,8[r31]
		lw		r3,16[r31]
		lw		r4,24[r31]
		lw		r5,32[r31]
		lw		r7,48[r31]
		lw		r9,56[r31]
		lw		r10,64[r31]
		lw		r11,72[r31]
		lw		r12,80[r31]
		lw		r13,88[r31]
		addui	r31,r31,#96
		mov		r6,r0
		rts

;------------------------------------------------------------------------------
; Display a character on the screen device
;------------------------------------------------------------------------------
;
public VBDisplayChar:
		addui	r31,r31,#-56
		sws		c1,[r31]
		sws		pregs,8[r31]
		sw		r1,16[r31]
		sw		r2,24[r31]
		sw		r3,32[r31]
		sw		r4,40[r31]
		sws		hs,48[r31]
		ldis	hs,#$FFD00000
		zxb		r1,r1
		lb		r2,EscState
		tst		p0,r2
p0.lt	br		processEsc
		cmpi	p0,r1,#_BS
p0.eq	br		doBackSpace
		cmpi	p0,r1,#$91	; cursor right
p0.eq	br		doCursorRight
		cmpi	p0,r1,#$93	; cursor left
p0.eq	br		doCursorLeft
		cmpi	p0,r1,#$90	; cursor up
p0.eq	br		doCursorUp
		cmpi	p0,r1,#$92	; cursor down
p0.eq	br		doCursorDown
		cmpi	p0,r1,#$99	; delete
p0.eq	br		doDelete
		cmpi	p0,r1,#CR
p0.eq	br		doCR
		cmpi	p0,r1,#LF
p0.eq	br		doLF
		cmpi	p0,r1,#$94	; cursor home
p0.eq	br		doCursorHome
		cmpi	p0,r1,#ESC
p0.ne	br		_0003
		ldi		r1,#1
		sb		r1,EscState
exitDC:
		lws		c1,[r31]
		lws		pregs,8[r31]
		lw		r1,16[r31]
		lw		r2,24[r31]
		lw		r3,32[r31]
		lw		r4,40[r31]
		lws		hs,48[r31]
		addui	r31,r31,#56
		mov		r6,r0
		rts
_0003:
		andi	r1,r1,#$7F
		bsr		VBAsciiToScreen
		lhu		r2,NormAttr
		andi	r2,r2,#-1024
		or		r1,r1,r2
		lcu		r3,VideoPos
		lhu		r2,Vidptr
		sh		r1,hs:[r2+r3*4]
		lcu		r1,CursorX
		addui	r1,r1,#1
		lcu		r2,Textcols
		cmp		p0,r1,r2
p0.ltu	br		.0001
		sc		r0,CursorX
		lcu		r1,CursorY
		addui	r1,r1,#1
		lcu		r2,Textrows
		cmp		p0,r1,r2
p0.ltu	sc		r1,CursorY
p0.ltu	bsr		SyncVideoPos	; wont affect p0
p0.ltu	br		exitDC
		bsr		SyncVideoPos
		bsr		ScrollUp
		br		exitDC
.0001:
		sc		r1,CursorX
		bsr		SyncVideoPos
		br		exitDC

doCR:
		sc		r0,CursorX
		bsr		SyncVideoPos
		br		exitDC
doLF:
		lcu		r1,CursorY
		addui	r1,r1,#1
		lcu		r2,Textrows
		cmp		p1,r1,r2
p1.ge	bsr		ScrollUp
p1.ge	br		exitDC
		sc		r1,CursorY
		bsr		SyncVideoPos
		br		exitDC

processEsc:
		ldi		r4,#22
		sc		r4,hs:LEDS
		lb		r2,EscState
		cmpi	p0,r2,#-1
p0.ne	br		.0006
		cmpi	p0,r1,#'T'	; clear to EOL
p0.ne	br		.0003
		lcu		r3,VideoPos
		lcu		r2,CursorX
		addui	r2,r2,#1
.0001:
		lcu		r1,Textcols
		cmp		p0,r2,r1
p0.ge	br		.0002
		ldi		r1,#' '
		lhu		r4,NormAttr
		or		r1,r1,r4
		lhu		r4,Vidptr
		sh		r1,hs:[r4+r3*4]
		addui	r2,r2,#1
		addui	r3,r3,#1
		br		.0001
.0002:
		sb		r0,EscState
		br		exitDC

.0003:
		cmpi	p0,r1,#'W'
p0.eq	sb		r0,EscState
p0.eq	br		doDelete
		cmpi	p0,r1,#'`'
p0.eq	ldi		r1,#-2
p0.eq	sb		r1,EscState
p0.eq	br		exitDC
		cmp		p0,r1,#'('
p0.eq	ldi		r1,#-3
p0.eq	sb		r1,EscState
p0.eq	br		exitDC
.0008:
		sb		r0,EscState
		br		exitDC
.0006:
		cmpi	p0,r2,#-2
p0.ne	br		.0007
		sb		r0,EscState
		cmpi	p0,r1,#'1'
p0.eq	bsr		CursorOn
p0.eq	br		exitDC
		cmpi	p0,r1,#'0'
p0.eq	bsr		CursorOff
		br		exitDC
.0007:
		cmpi	p0,r2,#-3
p0.ne	br		.0009
		cmpi	p0,r1,#ESC
p0.ne	br		.0008
		ldi		r1,#-4
		sb		r1,EscState
		br		exitDC
.0009:
		cmpi	p0,r2,#-4
p0.ne	br		.0010
		cmpi	p0,r1,#'G'
p0.ne	br		.0008
		ldi		r1,#-5
		sb		r1,EscState
		br		exitDC
.0010:
		cmpi	p0,r2,#-5
p0.ne	br		.0008
		sb		r0,EscState
		cmpi	p0,r1,#'4'
p0.ne	br		.0011
		lhu		r1,NormAttr
		mov		r2,r1
		shli	r1,r1,#9
		andi	r1,r1,#%111111111_000000000_00_00000000
		shrui	r2,r2,#9
		andi	r2,r2,#%000000000_111111111_00_00000000
		or		r1,r1,r2
		sh		r1,NormAttr
		br		exitDC		
.0011:
		cmpi	p0,r1,#'0'
p0.ne	br		.0012
		; Light grey on dark grey
		ldi		r1,#%001001001_011011011_00_00000000
		sh		r1,NormAttr
		br		exitDC
.0012:
		; Light grey on dark grey
		ldi		r1,#%001001001_011011011_00_00000000
		sh		r1,NormAttr
		br		exitDC

doBackSpace:
		ldi		r4,#23
		sc		r4,hs:LEDS
		lc		r2,CursorX
		tst		p0,r2
p0.eq	br		exitDC		; Can't backspace anymore
		lcu		r3,VideoPos
.0002:
		lh		r4,Vidptr
		lh		r1,hs:[r4+r3*4]
		addui	r3,r3,#-1
		sh		r1,hs:[r4+r3*4]
		addui	r3,r3,#2
		lc		r4,Textcols
		addui	r2,r2,#1
		cmp		p0,r2,r4
p0.ne	br		.0002
.0003:
		ldi		r1,#' '
		lh		r4,NormAttr
		or		r1,r1,r4
		lh		r4,Vidptr
		sh		r1,hs:[r4+r3*4]
		inc		CursorX,#-1
		bsr		SyncVideoPos
		br		exitDC

; Deleting a character does not change the video position so there's no need
; to resynchronize it.

doDelete:
		lc		r2,CursorX
		lh		r3,VideoPos
.0002:
		addui	r2,r2,#1
		lc		r4,Textcols
		cmp		p0,r2,r4
p0.ge	br		.0001
		addui	r2,r2,#-1
		addui	r3,r3,#1
		lh		r4,Vidptr
		lh		r1,hs:[r4+r3*4]
		addui	r3,r3,#-1
		sh		r1,hs:[r4+r3*4]
		addui	r3,r3,#1
		addui	r2,r2,#1
		br		.0002
.0001:
		ldi		r1,#' '
		lhu		r2,NormAttr
		or		r1,r1,r2
		lhu		r4,Vidptr
		sh		r1,hs:[r4+r3*4]
		br		exitDC

doCursorHome:
		lcu		r1,CursorX
		tst		p0,r1
p0.eq	br		doCursor1
		sc		r0,CursorX
		bsr		SyncVideoPos
		br		exitDC
doCursorRight:
		lcu		r1,CursorX
		addui	r1,r1,#1
		lcu		r2,Textcols
		cmp		p0,r1,r2
p0.ge	br		exitDC
doCursor2:
		sc		r1,CursorX
		bsr		SyncVideoPos
		br		exitDC
doCursorLeft:
		lcu		r1,CursorX
		tst		p0,r1
p0.eq	br		exitDC
		addui	r1,r1,#-1
		br		doCursor2
doCursorUp:
		lcu		r1,CursorY
		tst		p0,r1
p0.eq	br		exitDC
		addui	r1,r1,#-1
		br		doCursor1
doCursorDown:
		lcu		r1,CursorY
		addui	r1,r1,#1
		lcu		r2,Textrows
		cmp		p0,r1,r2
p0.ge	br		exitDC
doCursor1:
		sc		r1,CursorY
		bsr		SyncVideoPos
		br		exitDC

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

public VideoInit:
		ldi		r1,#84
		sc		r1,Textcols
		ldi		r1,#31
		sc		r1,Textrows
		ldi		r1,#%011000000_111111111_00_00000000
		sh		r1,NormAttr
		ldi		r1,#TEXTREG
		sh		r1,Vidregs
		ldi		r1,#TEXTSCR
		sh		r1,Vidptr

		ldi		r2,#TC1InitData
		ldis	lc,#11				; initialize loop counter ( one less)
		lhu		r3,Vidregs
.0001:
		lvh		r1,cs:[r2]
		sh		r1,hs:[r3]
		addui	r2,r2,#4
		addui	r3,r3,#4
		loop	.0001
		mov		r6,r0
		rts
endpublic

;------------------------------------------------------------------------------
; Initialize the second video controller.
; Meant to be called with a different data segment.
;------------------------------------------------------------------------------

public VideoInit2:
		ldi		r1,#84
		sc		r1,Textcols
		ldi		r1,#31
		sc		r1,Textrows
		ldi		r1,#%000011000_111111111_00_00000000
		sh		r1,NormAttr
		ldi		r1,#TEXTREG2
		sh		r1,Vidregs
		ldi		r1,#TEXTSCR2
		sh		r1,Vidptr

		ldi		r2,#TC2InitData
		ldis	lc,#11				; initialize loop counter ( one less)
		lhu		r3,Vidregs
.0001:
		lvh		r1,cs:[r2]
		sh		r1,hs:[r3]
		addui	r2,r2,#4
		addui	r3,r3,#4
		loop	.0001
		mov		r6,r0
		rts
endpublic

;------------------------------------------------------------------------------
; Text controller initialization data.
;------------------------------------------------------------------------------
		align	4

TC1InitData:
		dc		84		; #columns
		dc		 3	    ; #char out delay
		dc		31		; #rows
		dc		 0
		dc		84		; window left
		dc		 0
		dc		17		; window top
		dc       0
		dc		 7		; max scan line
		dc       0
		dc	   $21		; pixel size (hhhhvvvv)
		dc       0
		dc       0		; not used
		dc       0
		dc	  $1FF		; transparent color
		dc       0
		dc	   $40		; cursor blink, start line
		dc       0
		dc	    31		; cursor end
		dc       0
		dc		 0		; start address
		dc       0
		dc		 0		; cursor position
		dc       0

		align	 4
TC2InitData:
		dc		84
		dc       3
		dc		31
		dc       0
		dc	   676 
		dc       0
		dc      64		; window top
		dc       0
		dc		 7
		dc       0
		dc	   $10
		dc       0
		dc       0
		dc       0
		dc	  $1FF
		dc       0
		dc	   $40
		dc       0
		dc      31
		dc       0
		dc       0
		dc       0
		dc       0
		dc       0

;------------------------------------------------------------------------------
; Screen line offset table.
;------------------------------------------------------------------------------

		align	2
LineTbl:
		dc		0
		dc		TEXTCOLS*4
		dc		TEXTCOLS*8
		dc		TEXTCOLS*12
		dc		TEXTCOLS*16
		dc		TEXTCOLS*20
		dc		TEXTCOLS*24
		dc		TEXTCOLS*28
		dc		TEXTCOLS*32
		dc		TEXTCOLS*36
		dc		TEXTCOLS*40
		dc		TEXTCOLS*44
		dc		TEXTCOLS*48
		dc		TEXTCOLS*52
		dc		TEXTCOLS*56
		dc		TEXTCOLS*60
		dc		TEXTCOLS*64
		dc		TEXTCOLS*68
		dc		TEXTCOLS*72
		dc		TEXTCOLS*76
		dc		TEXTCOLS*80
		dc		TEXTCOLS*84
		dc		TEXTCOLS*88
		dc		TEXTCOLS*92
		dc		TEXTCOLS*96
		dc		TEXTCOLS*100
		dc		TEXTCOLS*104
		dc		TEXTCOLS*108
		dc		TEXTCOLS*112
		dc		TEXTCOLS*116
		dc		TEXTCOLS*120
		dc		TEXTCOLS*124

