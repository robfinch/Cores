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
; 0x22 = Set normal attribute
; 0x23 = Get normal attribute
;------------------------------------------------------------------------------

MAX_VIDEO_BIOS_CALL = 0x23
TCB_BIOS_Stack      EQU   $160

    code
    align   2
VideoBIOS_FuncTable:
    dc      0            ; 0x00
    dc      0
    dc      VBSetCursorPos ; 0x02
    dc      VBGetCursorPos ; 0x03
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
    dc      VBDisplayChar  ; 0x0E
    dc      0
    dc      0
    dc      0
    dc      0
    dc      0
    dc      VBDisplayString  ; 0x14
    dc      PRTNUM         ; 0x15
    dc      DisplayStringCRLF    ; 0x16
    dc      DisplayWord    ; 0x17
    dc      DisplayHalf    ; 0x18
    dc      DisplayCharHex ; 0x19
    dc      DisplayByte    ; 0x1A
    dc      VBDisplayString16  ; 0x1B
    dc      0
    dc      0
    dc      0
    dc      0
    dc      VBAsciiToScreen    ; 0x20
    dc      VBScreenToAscii    ; 0x21
    dc      VBSetCurrAttr      ; 0x22
    dc      VBGetCurrAttr      ; 0x23
    
    
                    
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

VBSetCursorPos:
    push    lr
    push    r2
    push    r1
    bsr     SetCursorPos
    addui   sp,sp,#16
    rts

VBGetCursorPos:
    push    lr
    bsr     GetCursorPos
    rts

VBDisplayChar:
    push    lr
    push    r1
    bsr     DisplayChar
    addui   sp,sp,#8
    rts

VBASciiToScreen:
    push    lr
    push    r1
    bsr     AsciiToScreen
    addui   sp,sp,#8
    rts

VBSetCurrAttr:
    push    lr
    push    r1
    bsr     SetCurrAttr
    addui   sp,sp,#8
    rts

VBGetCurrAttr:
    bra     GetCurrAttr

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



;------------------------------------------------------------------------------
; Display a character on-screen.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Convert screen display character to ascii.
;------------------------------------------------------------------------------

VBScreenToAscii:
    push    lr
    push    r1
    bsr     ScreenToAscii
    addui   sp,sp,#8
    rts

CursorOff:
	rtl
CursorOn:
	rtl
