;------------------------------------------------------------------------------
; Video BIOS
; Video Exception #410
;
; Function in R6
; 0x02 = Set Cursor Position	r1 = row, r2 = col 
; 0x03 = Get Cursor position	returns r1 = row, r2 = col
; 0x06 = Scroll screen up
; 0x09 = Display character+attribute, r1=char, r2=attrib, r3=#times
; 0x0A = Display character at cursor position, r1 = char, r2 = # times
; 0x0B = Set background color, r1 = color
; 0x0C = Display Pixel r1 = x, r2 = y, r3 = color
; 0x0D = Get pixel  r1 = x, r2 = y
; 0x0E = Teletype output, r1 = char
; 0x14 = Display String	r1 = pointer to string
; 0x15 = Display number r1 = number, r2 = # digits
; 0x16 = Display String + CRLF   r1 = pointer to string
; 0x17 = Display Word r1 as hex = word
; 0x18 = Display Half word as hex r1 = half word
; 0x19 = Display Charr char in hex r1 = char
; 0x1A = Display Byte in hex r1 = byte
; 0x1B = Display String -wide characters r1=pointer to string
; 0x1C = Display hexidecimal number, r1 = number, r2 = # of digits
; 0x20 = Convert ascii to screen
; 0x21 = Convert screen to ascii
;------------------------------------------------------------------------------

MAX_VIDEO_BIOS_CALL = 0x21

    bss
    align   8
VideoBIOS_sema    dw    0

    code
    align   2
VideoBIOS_FuncTable:
    dc      0            ; 0x00
    dc      0
    dc      SetCursorPos ; 0x02
    dc      GetCursorPos ; 0x03
    dc      0
    dc      0
    dc      ScrollUp     ; 0x06
    dc      0
    dc      0
    dc      DispCharAttr ; 0x09
    dc      0
    dc      SetBkColor   ; 0x0B
    dc      SetPixel     ; 0x0C
    dc      GetPixel     ; 0x0D
    dc      DisplayChar  ; 0x0E
    dc      0
    dc      0
    dc      0
    dc      0
    dc      0
    dc      DisplayString  ; 0x14
    dc      PRTNUM         ; 0x15
    dc      DisplayStringCRLF    ; 0x16
    dc      DisplayWord    ; 0x17
    dc      DisplayHalf    ; 0x18
    dc      DisplayCharHex ; 0x19
    dc      DisplayByte    ; 0x1A
    dc      DisplayString16  ; 0x1B
    dc      0
    dc      0
    dc      0
    dc      0
    dc      AsciiToScreen    ; 0x20
    dc      ScreenToAscii    ; 0x21
    
    
    
                    
    align   4
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

LockVideoBIOS:
    push    lr
    push    r1
    ldi     r1,#VideoBIOS_sema
    bsr     LockSema
    pop     r1
    rts
UnlockVideoBIOS:
    push    lr
    push    r1
    lea     r1,VideoBIOS_sema
    bsr     UnlockSema
    pop     r1
    rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VideoBIOSCall:
    lw      sp,TCB_BIOS_Stack[tr]
    push    lr
    bsr     LockVideoBIOS
    push    r10
    mfspr   r10,epc             ; update the return address
    addui   r10,r10,#4
    mtspr   epc,r10
    cmp     r10,r6,#MAX_VIDEO_BIOS_CALL
    bgt     r10,.0003
    lea     r10,VideoBIOS_FuncTable
    lcu     r10,[r10+r6*2]
    beq     r10,.0005
    or      r10,r10,#VideoBIOSCall & 0xFFFFFFFFFFFF0000    ; recover high order bits
    jsr     [r10]
.0004:
    nop
    bsr     UnlockVideoBIOS
    pop     r10
    pop     lr
    rte
.0003:
    ldi     r2,#E_BadFuncno
    bra     .0004
.0005:
    ldi     r2,#E_Unsupported
    bra     .0004

;------------------------------------------------------------------------------
; Display a character with a specific attribute.
;------------------------------------------------------------------------------

DispCharAttr:
    push    lr
    push    r3
    push    r4
    push    r5
    mov     r4,r1
    bsr     GetJCBPtr
    mov     r5,r1
    lh      r3,JCB_NormAttr[r5]
    push    r3
    sh      r2,JCB_NormAttr[r5]
    mov     r1,r4
    bsr     OutChar
    pop     r3
    sh      r3,JCB_NormAttr[r5]    ; restore normal attribute
    pop     r5
    pop     r4
    pop     r3
    rts


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
                                                                               
HomeCursor:
    push    lr
    push    r1
    push    r2
    bsr     GetJCBPtr
    sb      r0,JCB_CursorRow[r1]
    sb      r0,JCB_CursorCol[r1]
    lw      r2,IOFocusNdx
    cmp     r1,r1,r2
    bne     r1,.0001
	sc	    r0,TEXTREG+TEXT_CURPOS+$FFD00000
.0001:
    pop     r2
    pop     r1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
                                                                               
ClearScreen:
    push    lr
    push	r1
    push    r2
    push    r3
    push    r4
	lbu	    r1,TEXTREG+TEXT_COLS+$FFD00000
	lbu	    r2,TEXTREG+TEXT_ROWS+$FFD00000
	mulu	r4,r2,r1
	bsr     GetScreenLocation
	mov     r3,r1
	ldi		r1,#' '
	bsr		AsciiToScreen
	push    r1
	bsr     GetCurrAttr
	mov     r2,r1
	pop     r1
	or		r1,r1,r2
.cs1:
    sh	    r1,[r3+r4*4]
    subui   r4,r4,#1
	bne	    r4,.cs1
	pop     r4
	pop     r3
	pop     r2
	pop     r1
    rts

;------------------------------------------------------------------------------
; Display the word in r1
;------------------------------------------------------------------------------

DisplayWord:
    push    lr
	rol	    r1,r1,#32
	bsr		DisplayHalf
	rol	    r1,r1,#32
    pop     lr

;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------

DisplayHalf:
    push    lr
	ror		r1,r1,#16
	bsr		DisplayCharHex
	rol		r1,r1,#16
    pop     lr

;------------------------------------------------------------------------------
; Display the char in r1
;------------------------------------------------------------------------------

DisplayCharHex:
    push    lr
	ror		r1,r1,#8
	bsr		DisplayByte
	rol		r1,r1,#8
    pop     lr

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------

DisplayByte:
    push    lr
	ror		r1,r1,#4
	bsr		DisplayNybble
	rol		r1,r1,#4
	pop     lr
 
;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------

DisplayNybble:
    push    lr
	push	r1
	push    r2
	and		r1,r1,#$0F
	addui	r1,r1,#'0'
	cmpu	r2,r1,#'9'+1
	blt		r2,.0001
	addui	r1,r1,#7
.0001:
	bsr		OutChar
	pop     r2
	pop		r1
	rts

;------------------------------------------------------------------------------
; Display a string pointer to string in r1.
;------------------------------------------------------------------------------

DisplayString:
    push    lr
	push	r1
	push    r2
	mov		r2,r1
.dm2:
	lbu		r1,[r2]
	addui   r2,r2,#1	; increment text pointer
	beq		r1,.dm1
	bsr		OutChar
	bra		.dm2
.dm1:
	pop		r2
    pop     r1
	rts

;------------------------------------------------------------------------------
; Display a string pointer to string in r1 using 16 bit characters.
;------------------------------------------------------------------------------

DisplayString16:
    push    lr
	push	r1
	push    r2
	ldi     r2,#55
	sb      r2,LEDS
	mov		r2,r1
.dm2:
	lcu		r1,[r2]
	addui   r2,r2,#2	; increment text pointer
	beq		r1,.dm1
	and     r1,r1,#$FF
	bsr		OutChar
	ldi     r1,#56
	sb      r1,LEDS
	bra		.dm2
.dm1:
	pop		r2
    pop     r1
	rts

DisplayStringCRLF:
    push    lr
	bsr		DisplayString
	bra     CRLF1
OutCRLF:
CRLF:
    push    lr
CRLF1:
	push	r1
	ldi		r1,#CR
	bsr		OutChar
	ldi		r1,#LF
	bsr		OutChar
	pop		r1
	rts


DispCharQ:
    push    lr
	bsr		AsciiToScreen
	sc		r1,[r3]
	add		r3,r3,#4
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
    push    lr
	push	r3
	push	r5
	push	r6
	push	r7
	ldi		r7,#NUMWKA	; r7 = pointer to numeric work area
	mov		r6,r1		; save number for later
	mov		r5,r2		; r5 = min number of chars
	bge		r1,PN2			; is it negative? if not
	subu	r1,r0,r1	; else make it positive
	subui   r5,r5,#1	; one less for width count
PN2:
;	ldi		r3,#10
PN1:
	mod		r2,r1,#10	; r2 = r1 mod 10
	div		r1,r1,#10	; r1 /= 10 divide by 10
	add		r2,r2,#'0'	; convert remainder to ascii
	sb		r2,[r7]		; and store in buffer
	addui   r7,r7,#1
	subui   r5,r5,#1	; decrement width
	bne		r1,PN1
PN6:
	ble		r5,PN4		; test pad count, skip padding if not needed
PN3:
	bsr     DisplaySpace	; display the required leading spaces
	subui   r5,r5,#1
	bne		r5,PN3
PN4:
	bge		r6,PN5		; is number negative?
	ldi		r1,#'-'		; if so, display the sign
	bsr		OutChar
PN5:
    subui   r7,r7,#1
	lb		r1,[r7]		; now unstack the digits and display
	bsr		OutChar
	cmp		r1,r7,#NUMWKA
	bgt		r1,PN5
PNRET:
	pop		r7
	pop		r6
	pop		r5
	pop		r3
	rts

;------------------------------------------------------------------------------
; Returns:
; r1 = pointer to screen from JCB. This may be either the real screen or
;      the virtual screen buffer.
;------------------------------------------------------------------------------

GetScreenLocation:
    push    lr
    bsr     GetJCBPtr
    lw      r1,JCB_pVidMem[r1]
	rts

GetCurrAttr:
    push    lr
    bsr     GetJCBPtr
	lhu		r1,JCB_NormAttr[r1]
	rts
SetCurrAttr:
    push    lr
    push    r2
    mov     r2,r1
    bsr     GetJCBPtr
    sh      r2,JCB_NormAttr[r1]
    pop     r2
    rts

;------------------------------------------------------------------------------
; Update the cursor position in the text controller.
;------------------------------------------------------------------------------

UpdateCursorPos:
    push    lr
	push	r1
	push    r2
	push    r3
	push    r4
	bsr     GetJCBPtr
	lw      r3,IOFocusNdx
	cmp     r3,r3,r1
	bne     r3,.0001
	lbu		r3,JCB_CursorRow[r1]
	and		r3,r3,#$3f
	lbu	    r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r2,r2,r3
	lbu		r3,JCB_CursorCol[r1]
	and		r3,r3,#$7f
	addu	r2,r2,r3
	sc	    r2,TEXTREG+TEXT_CURPOS+$FFD00000
.0001:
	pop		r4
	pop     r3
    pop     r2
    pop     r1
    rts
	
;------------------------------------------------------------------------------
; Compute the screen address given the cursor row and column. While we're at
; it update the cursor position in the text controller.
;------------------------------------------------------------------------------

CalcScreenLoc:
    push    lr
	push	r2
	push    r3
	push    r4
	bsr     GetJCBPtr
	lbu		r3,JCB_CursorRow[r1]
	and		r3,r3,#$3f
	lbu	    r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r2,r2,r3
	lbu		r3,JCB_CursorCol[r1]
	and		r3,r3,#$7f
	addu	r2,r2,r3
    lw      r3,IOFocusNdx
    cmp     r3,r1,r3
    bne     r3,.0001
	sc	    r2,TEXTREG+TEXT_CURPOS+$FFD00000
.0001:
	bsr		GetScreenLocation
	asl		r2,r2,#2
	addu	r1,r1,r2
	pop		r4
	pop     r3
    pop     r2
	rts

;------------------------------------------------------------------------------
; Display a character on-screen.
;------------------------------------------------------------------------------

DisplayChar:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
    push    r5
	and		r1,r1,#$FF
	cmp		r2,r1,#'\r'
	beq		r2,.docr
	cmp		r2,r1,#$91		; cursor right ?
	beq		r2,.doCursorRight
	cmp		r2,r1,#$90		; cursor up ?
	beq		r2,.doCursorUp
	cmp		r2,r1,#$93		; cursor left ?
	beq		r2,.doCursorLeft
	cmp		r2,r1,#$92		; cursor down ?
	beq		r2,.doCursorDown
	cmp		r2,r1,#$94		; cursor home ?
	beq		r2,.doCursorHome
	cmp		r2,r1,#$99		; delete ?
	beq		r2,.doDelete
	cmp		r2,r1,#CTRLH	; backspace ?
	beq		r2,.doBackspace
	cmp		r2,r1,#'\n'	; line feed ?
	beq		r2,.doLinefeed
	cmp     r2,r1,#'\t'
	beq     r2,.doTab
	mov		r2,r1
	bsr		CalcScreenLoc
	mov		r3,r1
	mov		r1,r2
	bsr		AsciiToScreen
	mov		r2,r1
	bsr		GetCurrAttr
	or		r1,r1,r2
	sh	    r1,[r3]
	bsr		IncCursorPos
.dcx4:
    pop     r5
	pop		r4
    pop     r3
    pop     r2
    pop     r1
    pop     lr
	rtl
.doTab:
    ldi     r1,#' '
    bsr     DisplayChar
    bsr     DisplayChar
    bsr     DisplayChar
    bsr     DisplayChar
    bra     .dcx4
.docr:
    bsr     GetJCBPtr
	sb		r0,JCB_CursorCol[r1]
	bsr		UpdateCursorPos
	bra     .dcx4
.doCursorRight:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorCol[r1]
	add		r3,r3,#1
	cmpu	r2,r3,#TXTCOLS
	bge		r2,.dcx7
	sb		r3,JCB_CursorCol[r1]
.dcx7:
	bsr		UpdateCursorPos
	bra     .dcx4
.doCursorUp:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorRow[r1]
	beq		r3,.dcx7
	subui	r3,r3,#1
	sb		r3,JCB_CursorRow[r1]
	bra		.dcx7
.doCursorLeft:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorCol[r1]
	beq		r3,.dcx7
	subui	r3,r3,#1
	sb		r3,JCB_CursorCol[r1]
	bra		.dcx7
.doCursorDown:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorRow[r1]
	addui	r3,r3,#1
	cmpu	r2,r3,#TXTROWS
	bge		r2,.dcx7
	sb		r3,JCB_CursorRow[r1]
	bra		.dcx7
.doCursorHome:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorCol[r1]
	beq		r3,.dcx12
	sb		r0,JCB_CursorCol[r1]
	bra		.dcx7
.dcx12:
	sb		r0,JCB_CursorRow[r1]
	bra		.dcx7
.doDelete:
	bsr		CalcScreenLoc
	mov		r3,r1
    bsr     GetJCBPtr
	lbu		r5,JCB_CursorCol[r1]
	bra		.dcx5
.doBackspace:
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorCol[r1]
	beq		r3,.dcx4
	subui	r3,r3,#1
	sb		r3,JCB_CursorCol[r1]
	push    r1
	bsr		CalcScreenLoc
	mov		r3,r1
	pop     r1
	lbu		r5,JCB_CursorCol[r1]
.dcx5:
	lhu	    r2,4[r3]
	sh	    r2,[r3]
	addui	r3,r3,#4
	addui	r5,r5,#1
	cmpu	r2,r5,#TXTCOLS
	blt		r2,.dcx5
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r2,NormAttr
	or		r1,r1,r2
	subui	r3,r3,#4
	sh	    r1,[r3]
	bra		.dcx4
.doLinefeed:
	bsr		IncCursorRow
	bra		.dcx4


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

IncCursorPos:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
    bsr     GetJCBPtr
	lbu		r3,JCB_CursorCol[r1]
	addui	r3,r3,#1
	sb		r3,JCB_CursorCol[r1]
	cmpu	r2,r3,#TXTCOLS
	blt		r2,icc1
	sb		r0,JCB_CursorCol[r1]
	bra		icr1
IncCursorRow:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
    bsr     GetJCBPtr
icr1:
	lbu		r3,JCB_CursorRow[r1]
	addui	r3,r3,#1
	sb		r3,JCB_CursorRow[r1]
	cmpu	r2,r3,#TXTROWS
	blt		r2,icc1
	ldi		r2,#TXTROWS-1
	sb		r2,JCB_CursorRow[r1]
	bsr		ScrollUp
icc1:
    nop
    nop
	bsr		UpdateCursorPos
	pop		r4
	pop     r3
    pop     r2
    pop     r1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ScrollUp:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r5
	push	r6
	lbu	    r1,TEXTREG+TEXT_COLS+$FFD00000
	lbu	    r2,TEXTREG+TEXT_ROWS+$FFD00000
	subui	r2,r2,#1
	mulu	r6,r1,r2
	bsr     GetScreenLocation
	mov     r2,r1
	addui   r2,r2,#TXTCOLS*4
	ldi		r3,#0
.0001:
	lh	    r5,[r2+r3*4]
	sh	    r5,[r1+r3*4]
	addui	r3,r3,#1
	subui   r6,r6,#1
	bne	    r6,.0001
	lbu	    r1,TEXTREG+TEXT_ROWS+$FFD00000
	subui	r1,r1,#1
	bsr		BlankLine
	pop		r6
	pop		r5
    pop     r3
    pop     r2
    pop     r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank out
;------------------------------------------------------------------------------

BlankLine:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
    lbu     r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r3,r2,r1
;	subui	r2,r2,#1		; r2 = #chars to blank - 1
	asl		r3,r3,#2
	bsr     GetScreenLocation
	addu	r3,r3,r1
	ldi		r1,#' '
	bsr		AsciiToScreen
	push    r1
	bsr     GetCurrAttr
	mov     r4,r1
	pop     r1
	or		r1,r1,r4
.0001:
	sh	    r1,[r3+r2*4]
	subui   r2,r2,#1
	bne	    r2,.0001
	pop		r4
    pop     r3
    pop     r2
    pop     r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

AsciiToScreen:
    push    r2
    cmp     r2,r1,#$5B          ; [
    beq     r2,.00003
    cmp     r2,r1,#$5D          ; ]
    beq     r2,.00004
	and		r1,r1,#$FF
	or		r1,r1,#$100
	and		r2,r1,#%00100000	; if bit 5 or 6 isn't set
	beq		r2,.00001
	and		r2,r1,#%01000000
	beq		r2,.00001
	and		r1,r1,#%110011111
.00001:
    pop     r2
	rtl
.00003:
    ldi     r1,#$11B
    bra     .00001
.00004:
    ldi     r1,#$11D
    bra     .00001

;------------------------------------------------------------------------------
; Convert screen display character to ascii.
;------------------------------------------------------------------------------

ScreenToAscii:
    push    r2
	and		r1,r1,#$FF
    cmp     r2,r1,#$1B          ; fix up brackets
    blt     r2,.0001
    cmp     r2,r1,#$1D
    bgt     r2,.0001
    addu    r1,r1,#$40
.0001:
	cmpu	r2,r1,#26+1
	bge		r2,.stasc1
	add		r1,r1,#$60
.stasc1:
    pop     r2
	rtl

CursorOff:
	rtl
CursorOn:
	rtl

SetCursorPos:
    push    lr
    push    r3
    mov     r3,r1
    bsr     GetJCBPtr
    sb      r3,JCB_CursorRow[r1]
    sb      r2,JCB_CursorCol[r1]
    bsr     UpdateCursorPos
    mov     r1,r3
    pop     r3
    rts

GetCursorPos:
    push    lr
    bsr     GetJCBPtr
    lbu     r2,JCB_CursorCol[r1]
    lbu     r1,JCB_CursorRow[r1]
    rts
