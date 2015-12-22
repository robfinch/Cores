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
; ============================================================================
;
;------------------------------------------------------------------------------
; Display a character on the screen device
;------------------------------------------------------------------------------
;
public VBDisplayChar:
		addui	r31,r31,#-40
		sws		c1,zs:[r31]
		sws		pregs,zs:8[r31]
		sw		r2,zs:16[r31]
		sw		r3,zs:24[r31]
		sw		r4,zs:32[r31]
		ldi		r2,#8
		sc		r2,$FFDC0600
		zxb		r1,r1
		lb		r2,EscState
		tst		p0,r2
p0.lt	br		processEsc
		cmpi	p0,r1,#BS
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
		lws		c1,zs:[r31]
		lws		pregs,zs:8[r31]
		lw		r2,zs:16[r31]
		lw		r3,zs:24[r31]
		lw		r4,zs:32[r31]
		addui	r31,r31,#40
		rts
_0003:
		ldi		r4,#10
		sc		r4,$FFDC0600
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
		sc		r4,$FFDC0600
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
		sc		r4,$FFDC0600
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
		lh		r2,NormAttr
		or		r1,r1,r2
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
		subui	r1,r1,#1
		br		doCursor2
doCursorUp:
		lcu		r1,CursorY
		tst		p0,r1
p0.eq	br		exitDC
		subui	r1,r1,#1
		br		doCursor1
doCursorDown:
		lcu		r1,CursorY
		addui	r1,r1,#1
		lcu		r2,Textrows
p0.ge	br		exitDC
doCursor1:
		sc		r1,CursorY
		bsr		SyncVideoPos
		br		exitDC

