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
TCB_BIOS_Stack      EQU   $280

	bss
_VideoStack
	fill.w	0x80,0

    code
    align   2
VideoBIOS_FuncTable:
    dh      0            ; 0x00
    dh      0
    dh      VBSetCursorPos ; 0x02
    dh      VBGetCursorPos ; 0x03
    dh      0
    dh      0
    dh      _VBScrollUp    ; 0x06
    dh      0
    dh      0
    dh      DispCharAttr ; 0x09
    dh      0
    dh      SetBkColor   ; 0x0B
    dh      SetPixel     ; 0x0C
    dh      GetPixel     ; 0x0D
    dh      VBDisplayChar  ; 0x0E
    dh      0
    dh      0
    dh      0
    dh      0
    dh      0
    dh      VBDisplayString  ; 0x14
    dh      PRTNUM         ; 0x15
    dh      DisplayStringCRLF_    ; 0x16
    dh      DisplayWord    ; 0x17
    dh      DisplayHalf    ; 0x18
    dh      DisplayCharHex ; 0x19
    dh      DisplayByte    ; 0x1A
    dh      VBDisplayString16  ; 0x1B
    dh      0
    dh      0
    dh      0
    dh      0
    dh      VBAsciiToScreen    ; 0x20
    dh      VBScreenToAscii    ; 0x21
    dh      VBSetCurrAttr      ; 0x22
    dh      VBGetCurrAttr      ; 0x23
    
    
                    
    align   4

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VideoBIOSCall:
	csrrw	r1,#$41,r0			; get r1 (it was overwritten by the jump code)
	csrrw	r2,#$42,r0
	ipush
	cli							; allow further interrupts
    bgtu    r6,#MAX_VIDEO_BIOS_CALL,.0003
	mov		r29,sp
    ldi     sp,#_VideoStack+0x7E
	push	r11
	lhu		r11,VideoBIOS_FuncTable[r6]
	beq		r11,r0,.0005
	push	r12
.0001:
	csrrs	r12,#12,#4			; Lock video semaphore
	bne		r12,r0,.0001
	pop		r12
    call    (VideoBIOSCall & 0xFFFF0000)[r11]
	pop		r11
	mov		sp,r29
	ipop
	csrrw	r0,#$41,r1
    iret	#2
.0003:
	ipop
	csrrw	r0,#$41,#E_BadFuncno
    iret
.0005:
	pop		r11
	mov		sp,r29
	ipop
	csrrw	r0,#$41,#E_Unsupported
    iret

;------------------------------------------------------------------------------
; Display a character with a specific attribute.
;------------------------------------------------------------------------------

DispCharAttr:
    push    r3
    push    r4
    push    r5
    mov     r4,r1
    call    _GetJCBPtr
    mov     r5,r1
    lh      r3,JCB_NormAttr[r5]
    push    r3
    sh      r2,JCB_NormAttr[r5]
    mov     r1,r4
    call    OutChar
    pop     r3
    sh      r3,JCB_NormAttr[r5]    ; restore normal attribute
    pop     r5
    pop     r4
    pop     r3
    ret

VBSetCursorPos:
    push    r18
    push    r19
	mov		r18,r1
	mov		r19,r2
    call    _SetCursorPos
	pop		r19
	pop		r18
    ret

VBGetCursorPos:
    jmp   _GetCursorPos

VBDisplayChar:
    push    r18
	mov		r18,r1
    call    _DBGDisplayChar
	pop		r18
    ret

VBAsciiToScreen:
	push	r18
	mov		r18,r1
    call    _AsciiToScreen
	pop		r18
    ret

VBSetCurrAttr:
    push    r18
	mov		r18,r1
    call    _SetCurrAttr
	pop		r18
    ret

VBGetCurrAttr:
    bra     _GetCurrAttr

;------------------------------------------------------------------------------
; Display the word in r1
;------------------------------------------------------------------------------

_DisplayWord:
	rol	    r1,r1,#16
	call	_DisplayCharHex
	rol	    r1,r1,#16

;------------------------------------------------------------------------------
; Display the char in r1
;------------------------------------------------------------------------------

_DisplayCharHex:
	ror		r1,r1,#8
	call	_DisplayByte
	rol		r1,r1,#8

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------

_DisplayByte:
	ror		r1,r1,#4
	call	_DisplayNybble
	rol		r1,r1,#4
 
;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------

_DisplayNybble:
	push	r1
	push    r2
	and		r1,r1,#$0F
	addi	r1,r1,#'0'
	bleu	r1,#'9',.0001
	addi	r1,r1,#7
.0001:
	call	VBDisplayChar
	pop     r2
	pop		r1
	ret

;------------------------------------------------------------------------------
; Display a string pointer to string in r1 using 16 bit characters.
;------------------------------------------------------------------------------

DisplayString16:
	push	r1
	push    r2
	ldi     r2,#55
	sh      r2,LEDS
	mov		r2,r1
.dm2:
	lhu		r1,[r2]
	add		r2,r2,#1	; increment text pointer
	beq		r1,r0,.dm1
	and     r1,r1,#$FF
	call	VBDisplayChar
	ldi     r1,#56
	sh      r1,LEDS
	bra		.dm2
.dm1:
	pop		r2
    pop     r1
	ret

DispCharQ:
	call	_AsciiToScreen
	sh		r1,[r3]
	add		r3,r3,#1
    ret

;------------------------------------------------------------------------------
; 'PRTNUM' prints the 32 bit number in r1, leading blanks are added if
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
	push	r3
	push	r5
	push	r6
	push	r7
	ldi		r7,#NUMWKA	; r7 = pointer to numeric work area
	mov		r6,r1		; save number for later
	mov		r5,r2		; r5 = min number of chars
	bge		r1,r0,PN2	; is it negative? if not
	sub	    r1,r0,r1	; else make it positive
	subi    r5,r5,#1	; one less for width count
PN2:
;	ldi		r3,#10
PN1:
	mod		r2,r1,#10	; r2 = r1 mod 10
	div		r1,r1,#10	; r1 /= 10 divide by 10
	add		r2,r2,#'0'	; convert remainder to ascii
	sh		r2,[r7]		; and store in buffer
	addi    r7,r7,#1
	subi    r5,r5,#1	; decrement width
	bne		r1,r0,PN1
PN6:
	ble		r5,r0,PN4		; test pad count, skip padding if not needed
PN3:
	push	r5
	push	r6
	push	r7
	call    DisplaySpace	; display the required leading spaces
	pop		r7
	pop		r6
	pop		r5
	subi    r5,r5,#1
	bne		r5,r0,PN3
PN4:
	bge		r6,r0,PN5		; is number negative?
	ldi		r1,#'-'			; if so, display the sign
	push    r7
	call	OutChar[pc]
	pop     r7
PN5:
    subi    r7,r7,#1
	lh		r1,[r7]		; now unstack the digits and display
	push    r7
	call	OutChar[pc]
	pop     r7
	bgt		r7,#NUMWKA,PN5
PNRET:
	pop		r7
	pop		r6
	pop		r5
	pop		r3
	ret

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
	push	r18
	mov		r18,r1
    call    _ScreenToAscii
	pop		r18
	ret

CursorOff:
	ret
CursorOn:
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

VBScrollUp:
    ; Compiler temporaries have to be saved. These are regs 3-11 which the
    ; compiled code might use.
	push	r1
    push    r2
    push    r3
    push    r4          ; r4 is used by BlankLine
    push    r5
	push	r6
	push    r7
	call    _GetTextRows
	mov     r2,r1
	call    _GetTextCols
	shl     r7,r1,#1
	subi	r2,r2,#1
	mulu	r6,r1,r2
	push    r6
	push    r7
	call    _GetScreenLocation
	pop     r7
	pop     r6
	add     r2,r1,r7
	ld		r3,#0
.0001:
	lh	    r5,[r2+r3]
	sh	    r5,[r1+r3]
	add		r3,r3,#2
	sub		r6,r6,#1
	bne	    r6,r0,.0001
	call    _GetTextRows
	sub		r1,r1,#1
	push    r1
	call	_BlankLine
	add		sp,sp,#2
	pop     r7
	pop		r6
	pop		r5
	pop     r4
    pop     r3
    pop     r2
    pop     r1
	ret
