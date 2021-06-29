comment ~
================================================================================
   
 (C) 1993 FinchWare

 Module: md4.asm

 Description :
    Contains mode 4 graphics routines.
        mode resolution     colors    adapter
        4    - 320 x 200    4         CGA/EGA/VGA/MCGA
        5    - 320 x 200    4         CGA/EGA/VGA/MCGA

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
        .286
        .model  small

include fgs.ah

        .code
;-------------------
;    Function table
;-------------------
FuncTbl label   dword
        dd      GetPoint
        dd      Point
        dd      SHLine
        dd      LHLine
        dd      AHLine

        .org    32

MaxX    dw      320
MaxY    dw      200
Colors  dw      4
VSeg    dw      0b800h

;-----------------------------------------------------------------
; Patterns for extending color to remainder of byte for modes 4,5
;-----------------------------------------------------------------

PropagatedPixel4  label     byte
        db   00000000b
        db   01010101b
        db   10101010b
        db   11111111b

        .code

GetPoint        proc far
        mGetPoint  mPointAddr4
GetPoint        endp

Point   proc far
        mPoint  mPointAddr4,3
Point   endp
; 
comment ~
================================================================================
        
 (C) 1992 FinchWare

 Module : SLine

 Description :
    Draws line in graphics mode 4

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
SLine4  proc    near
        enter   12,0
        push    si
        push    di
        mov     si,2000h       ; si = increment for video buffer interleave
        mov     di,80-2000h    ; increment from last to first interleave
        mov     cx,ARGx2
        sub     cx,ARGx1       ; CX = x2 - x1
        jnz     SLine46        ; jump if vertical line
        jmp     VSLine4
SLine46:
        ; force x1 < x2

        jns     SLine41        ; jump if x2 > x1
        neg     cx             ; cx = x1-x2
        mov     bx,ARGx2       ; exchange x1 and x2
        xchg    bx,ARGx1
        mov     ARGx2,bx
        mov     bx,ARGy2       ; exchange y1 and y2
        xchg    bx,ARGy1
        mov     ARGy2,bx

        ; dy = abs(y2-y1)

SLine41:
        mov     bx,ARGy2
        sub     bx,ARGy1   ; bx = y2 - y1
        jnz     SLine42
        jmp     HSLine4    ; jump if horizontal line
SLine42:
        jns     SLine43
        neg     bx         ; bx = y1 - y2
        neg     si         ; negate y increment
        neg     di
        xchg    si,di      ; exchange increments

        ; select appropriate routine for slope of line

SLine43:
        mov     VARleafincr,di ; save increment for buffer interleave
        mov     VARroutine,offset LoSlopeSLine4
        cmp     bx,cx
        jle     SLine44
        mov     VARroutine,offset HiSlopeSLine4
        xchg    bx,cx     ; exchange dy and dx

        ; calculate initial decision variable and increments

SLine44:
        shl     bx,1           ; bx = 2 * dy
        mov     VARincr1,bx    ; incr1 = 2 * dy
        sub     bx,cx
        mov     di,bx          ; di = d = 2 * dy - dx
        sub     bx,cx
        mov     VARincr2,bx    ; incr2 = 2 * (dy - dx)

        ; calculate first pixel address

        push    cx          ; preserve
        mov     ax,ARGy1
        mov     bx,ARGx1
        PointAddr4
        mov     al,byte ptr _fgsv.fgsColor; ARGn  ; AL = unshifted pixel value
        and     al,ah
        shl     ax,cl       ; put bit mask and pixel value in proper position
        mov     dx,ax       ; DH = bit mask DL = pixel value
        not     dh          ; DH = inverse bit mask
        pop     cx
        inc     cx          ; CX = number of pixels to draw
        test    bx,2000h    ; set zero flag if BX in first interleave
        jz      SLine45
        xchg    si,VARleafincr ; exchange increment values if first pixel
SLine45:
        jmp     VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VSLine4:
        mov     ax,ARGy1  ; AX = y1
        mov     bx,ARGy2  ; BX = y2
        mov     cx,bx
        sub     cx,ax     ; CX = dy
        jge     SLine431
        neg     cx        ; force dy >= 0
        mov     ax,bx     ; AX = y2
SLine431:
        inc     cx        ; CX = # of pixels to draw
        mov     bx,ARGx1  ; BX = x
        push    cx        ; preserve
        Point   PointAddr4,3
        ;---------------------------------
        ;    Get the pixel color to plot.
        ;---------------------------------
        mov     al,byte ptr _fgsv.fgsColor ; ARGn   ; AL = pixel value
        and     al,ah    ; ah = 3
        shl     ax,cl     ; put bit mask and pixel value in proper position
        not     ah        ; AH = inverse bit mask
        pop     cx        ; restore
        test    bx,si
        jz      SLine432
        xchg    si,di     ; exchange increment values if first pixel lies in first interleave
        ;---------------
        ; Draw the line
        ;---------------
SLine432:
        call    word ptr _fgsv.fgsPointPtr
        add     bx,si
        xchg    si,di
        loop    SLine432
        jmp     SLine4Exit
;------------------------------
; Routine for horizontal lines
;------------------------------
HSLine4:
        SHLine  PointAddr4, 2, 6, 3

        mov     ax,ARGy1
        mov     bx,ARGx1
        Point   PointAddr4,3
        mov     di,bx     ; es:di -> buffer
        mov     dh,ah
        not     dh        ; DH = unbshifted bit mask for leftmost byte
        mov     dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl     dh,cl     ; DH = reverse bit mask for first byte
        not     dh        ; DH = bit mask for first byte
        mov     cx,ARGx2
        and     cl,3
        xor     cl,3      ; CL = number of bits to shift left
        shl     cl,1
        shl     dl,cl     ; DL = bit mask for last byte

        ; Determine byte offset for first and last pixel in line

        mov     ax,ARGx2
        mov     bx,ARGx1
        mov     cl,2      ; number of bits to shift to turn pixels into bytes
        shr     ax,cl
        shr     bx,cl
        mov     cx,ax
        sub     cx,bx     ; CX = number of bytes in line - 1

        ; propagate pixel value throughout one byte

        lea     bx,PropagatedPixel4
        mov     al,byte ptr _fgsv.fgsColor  ; ARGn
        and     al,3
        xlat

        ; set pixels in leftmost byte of the line

        or      dh,dh
        js      SLine443   ; jump if byte aligned (x1 is leftmost pixel in byte)
        or      cx,cx
        jnz     SLine442   ; jump if more than one byte in line
        and     dl,dh     ; bit mask for the line
        jmp     short SLine444
SLine442:
        mov     ah,al
        and     ah,dh     ; AH = masked pixel bits
        not     dh        ; DH = reverse bit mask for first byte
        and     es:[di],dh; zero masked pixels in buffer
        or      es:[di],ah ; update masked pixels in buffer
        inc     di
        dec     cx

        ; use fast 8086 instruction to draw remainder of line

SLine443:
        rep     stosb     ; update all pixels in the line (can not use stosw)

        ; set pixels in the rightmost byte of the line

SLine444:
        and     al,dl     ; AL = masked pixels for last byte
        not     dl
        and     es:[di],dl; zero masked pixels in buffer
        mov     bx,di
;        call    word ptr _fgsv.fgsPointPtr
        or es:[di],al ; update masked pixels in buffer
        jmp SLine4Exit
;----------------------
; Routine for dy <= dx
;----------------------
LoSlopeSLine4:

SLine410:
        mov ah,es:[bx]     ; AH = byte from video buffer
SLine411:
        and ah,dh          ; zero pixel value at current bit offset
        or  ah,dl          ; set pixel value in btye

        ror dl,2           ; rotate pixel value
        ror dh,2           ; rotate bit mask
        jnc SLine414        ; jump if bit mask rotated to leftmost pixel

        ; bit mask not shifted out

        or  di,di          ; test sign of d
        jns SLine412        ; jump if d >= 0
        add di,VARincr1    ; d = d + incr1
        loop SLine411
        mov es:[bx],ah     ; store remaining pixel in buffer
        jmp short SLine4Exit
SLine412:
        add di,VARincr2    ; d = d + incr2
        mov es:[bx],ah     ; update buffer
        add bx,si          ; increment y
        xchg si,VARleafincr
        loop SLine410
        jmp short SLine4Exit

        ; bit mask shifted out

SLine414:
        mov es:[bx],ah
        inc bx             ; bx = offset of next byte
        or  di,di          ; test sign of d
        jns SLine415       ; jump if non negative
        add di,VARincr1    ; d = d + incr1
        loop SLine410
        jmp short SLine4Exit
SLine415:
        add di,VARincr2    ; d = d + incr2
        add bx,si          ; increment y
        xchg si,VARleafincr
        loop SLine410
        jmp short SLine4Exit
;---------------------
; routine for dy > dx
;---------------------
HiSlopeSLine4:
        mov     ax,dx
SLine421:
        call    word ptr _fgsv.fgsPointPtr
        add     bx,si          ; increment y
        xchg    si,VARleafincr
SLine422:
        or      di,di          ; test sign of d
        jns     SLine423        ; jump if d >= 0
        add     di,VARincr1    ; d = d + incr1
        loop    SLine421
        jmp     short SLine4Exit
SLine423:
        add     di,VARincr2    ; d = d + incr2
        ror     al,2           ; rotate pixel value
        ror     ah,2           ; rotate bit mask
        cmc                 ; cf set if bit mask not rotated to leftmost pixel
        adc     bx,0           ; bx = offset of next byte
        loop    SLine421
SLine4Exit:
        pop     di
        pop     si
        leave
        ret
SLine4  endp
; 
comment ~
================================================================================
        
 (C) 1992 FinchWare

 Module : Line4

 Description :
    Routine for horizontal lines
    Draws line in graphics mode 4

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
HLine4  proc    near
        mHLine   mPointAddr4, 2, 6, 3
HLine4  endp

;*****
comment ~
================================================================================
        
 (C) 1992 FinchWare

 Module : Line4

 Description :
    Draws line in graphics mode 4

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
Line4   proc    near
        enter   12,0
        push    ds
        mov     ax,cs
        mov     ds,ax
        push    si
        push    di
        mov     si,2000h       ; si = increment for video buffer interleave
        mov     di,80-2000h    ; increment from last to first interleave
        mov     cx,ARGx2
        sub     cx,ARGx1       ; CX = x2 - x1
        jz      VLine4         ; jump if vertical line

        ; force x1 < x2

        jns     Line41         ; jump if x2 > x1
        neg     cx             ; cx = x1-x2
        mov     bx,ARGx2       ; exchange x1 and x2
        xchg    bx,ARGx1
        mov     ARGx2,bx
        mov     bx,ARGy2       ; exchange y1 and y2
        xchg    bx,ARGy1
        mov     ARGy2,bx

        ; dy = abs(y2-y1)

Line41:
        mov     bx,ARGy2
        sub     bx,ARGy1  ; bx = y2 - y1
        jnz     Line42
        jmp     HLine4   ; jump if horizontal line

Line42:
        jns     Line43
        neg     bx        ; bx = y1 - y2
        neg     si        ; negate y increment
        neg     di
        xchg    si,di     ; exchange increments

; select appropriate routine for slope of line

Line43:
        mov     VARleafincr,di ; save increment for buffer interleave
        mov     VARroutine,offset LoSlopeLine4
        cmp     bx,cx
        jle     Line44
        mov     VARroutine,offset HiSlopeLine4
        xchg    bx,cx     ; exchange dy and dx

; calculate initial decision variable and increments

Line44:
        shl     bx,1           ; bx = 2 * dy
        mov     VARincr1,bx    ; incr1 = 2 * dy
        sub     bx,cx
        mov     di,bx          ; di = d = 2 * dy - dx
        sub     bx,cx
        mov     VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push    cx          ; preserve
        mov     ax,ARGy1
        mov     bx,ARGx1
        call    PointAddr4
        mov     al,byte ptr _fgsv.fgsColor; ARGn  ; AL = unshifted pixel value
        and     al,ah
        shl     ax,cl       ; put bit mask and pixel value in proper position
        mov     dx,ax       ; DH = bit mask DL = pixel value
        not     dh          ; DH = inverse bit mask
        pop     cx
        inc     cx          ; CX = number of pixels to draw
        test    bx,2000h    ; set zero flag if BX in first interleave
        jz      Line45
        xchg    si,VARleafincr ; exchange increment values if first pixel
Line45:
        jmp     VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VLine4:
        mov     ax,ARGy1  ; AX = y1
        mov     bx,ARGy2  ; BX = y2
        mov     cx,bx
        sub     cx,ax     ; CX = dy
        jge     Line431
        neg     cx        ; force dy >= 0
        mov     ax,bx     ; AX = y2
Line431:
        inc     cx        ; CX = # of pixels to draw
        mov     bx,ARGx1  ; BX = x
        push    cx        ; preserve
        call    PointAddr4
        ;---------------------------------
        ;    Get the pixel color to plot.
        ;---------------------------------
        mov     al,byte ptr _fgsv.fgsColor ; ARGn   ; AL = pixel value
        and     al,ah    ; ah = 3
        shl     ax,cl     ; put bit mask and pixel value in proper position
        not     ah        ; AH = inverse bit mask
        pop     cx        ; restore
        test    bx,si
        jz      Line432
        xchg    si,di     ; exchange increment values if first pixel lies in first interleave
        ;---------------
        ; Draw the line
        ;---------------
Line432:
        call    word ptr _fgsv.fgsPointPtr
        add     bx,si
        xchg    si,di
        loop    Line432
        jmp     Line4Exit
;------------------------------
; Routine for horizontal lines
;------------------------------
HLine4:
        mov     ax,ARGy1
        mov     bx,ARGx1
        call    PointAddr4
        mov     di,bx     ; es:di -> buffer
        mov     dh,ah
        not     dh        ; DH = unbshifted bit mask for leftmost byte
        mov     dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl     dh,cl     ; DH = reverse bit mask for first byte
        not     dh        ; DH = bit mask for first byte
        mov     cx,ARGx2
        and     cl,3
        xor     cl,3      ; CL = number of bits to shift left
        shl     cl,1
        shl     dl,cl     ; DL = bit mask for last byte

        ; Determine byte offset for first and last pixel in line

        mov     ax,ARGx2
        mov     bx,ARGx1
        mov     cl,2      ; number of bits to shift to turn pixels into bytes
        shr     ax,cl
        shr     bx,cl
        mov     cx,ax
        sub     cx,bx     ; CX = number of bytes in line - 1

        ; propagate pixel value throughout one byte

        lea     bx,PropagatedPixel4
        mov     al,byte ptr _fgsv.fgsColor  ; ARGn
        and     al,3
        xlat

        ; set pixels in leftmost byte of the line

        or      dh,dh
        js      Line443   ; jump if byte aligned (x1 is leftmost pixel in byte)
        or      cx,cx
        jnz     Line442   ; jump if more than one byte in line
        and     dl,dh     ; bit mask for the line
        jmp     short Line444
Line442:
        mov     ah,al
        and     ah,dh     ; AH = masked pixel bits
        not     dh        ; DH = reverse bit mask for first byte
        and     es:[di],dh; zero masked pixels in buffer
        or      es:[di],ah ; update masked pixels in buffer
        inc     di
        dec     cx

        ; use fast 8086 instruction to draw remainder of line

Line443:
        rep     stosb     ; update all pixels in the line (can not use stosw)

        ; set pixels in the rightmost byte of the line

Line444:
        and     al,dl     ; AL = masked pixels for last byte
        not     dl
        and     es:[di],dl; zero masked pixels in buffer
        mov     bx,di
;        call    word ptr _fgsv.fgsPointPtr
        or es:[di],al ; update masked pixels in buffer
        jmp Line4Exit
;----------------------
; Routine for dy <= dx
;----------------------
LoSlopeLine4:

Line410:
        mov ah,es:[bx]     ; AH = byte from video buffer
Line411:
        and ah,dh          ; zero pixel value at current bit offset
        or  ah,dl          ; set pixel value in btye

        ror dl,2           ; rotate pixel value
        ror dh,2           ; rotate bit mask
        jnc Line414        ; jump if bit mask rotated to leftmost pixel

        ; bit mask not shifted out

        or  di,di          ; test sign of d
        jns Line412        ; jump if d >= 0
        add di,VARincr1    ; d = d + incr1
        loop Line411
        mov es:[bx],ah     ; store remaining pixel in buffer
        jmp short Line4Exit
Line412:
        add di,VARincr2    ; d = d + incr2
        mov es:[bx],ah     ; update buffer
        add bx,si          ; increment y
        xchg si,VARleafincr
        loop Line410
        jmp short Line4Exit

        ; bit mask shifted out

Line414:
        mov es:[bx],ah
        inc bx             ; bx = offset of next byte
        or  di,di          ; test sign of d
        jns Line415       ; jump if non negative
        add di,VARincr1    ; d = d + incr1
        loop Line410
        jmp short Line4Exit
Line415:
        add di,VARincr2    ; d = d + incr2
        add bx,si          ; increment y
        xchg si,VARleafincr
        loop Line410
        jmp short Line4Exit
;---------------------
; routine for dy > dx
;---------------------
HiSlopeLine4:
        mov     ax,dx
Line421:
        call    word ptr _fgsv.fgsPointPtr
        add     bx,si          ; increment y
        xchg    si,VARleafincr
Line422:
        or      di,di          ; test sign of d
        jns     Line423        ; jump if d >= 0
        add     di,VARincr1    ; d = d + incr1
        loop    Line421
        jmp     short Line4Exit
Line423:
        add     di,VARincr2    ; d = d + incr2
        ror     al,2           ; rotate pixel value
        ror     ah,2           ; rotate bit mask
        cmc                 ; cf set if bit mask not rotated to leftmost pixel
        adc     bx,0           ; bx = offset of next byte
        loop    Line421
Line4Exit:
        pop     di
        pop     si
        pop     ds
        leave
        retf
Line4  endp
; 
comment ~
================================================================================
        
 (C) 1992 FinchWare

 Module : Line4

 Description :
    Routine for horizontal lines
    Draws line in graphics mode 4

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
HLine4  proc    near
        HLine   PointAddr4, 2, 6, 3
HLine4  endp

comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : 

 Description :

 Parameters :

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
_CycleLine4  proc      near
        enter 12,0
        push si
        push di

        mov si,2000h       ; si = increment for video buffer interleave
        mov di,80-2000h    ; increment from last to first interleave
        mov cx,ARGx2
        sub cx,ARGx1       ; CX = x2 - x1
        jz  VCycleLine4         ; jump if vertical line

; force x1 < x2

        jns CycleLine41         ; jump if x2 > x1
        neg cx             ; cx = x1-x2
        mov bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov ARGx2,bx
        mov bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov ARGy2,bx

; dy = abs(y2-y1)

CycleLine41:
        mov bx,ARGy2
        sub bx,ARGy1  ; bx = y2 - y1
        jnz CycleLine42
        jmp HCycleLine4   ; jump if horizontal line

CycleLine42:
        jns CycleLine43
        neg bx        ; bx = y1 - y2
        neg si        ; negate y increment
        neg di
        xchg si,di     ; exchange increments

; select appropriate routine for slope of line

CycleLine43:
        mov VARleafincr,di ; save increment for buffer interleave
        mov VARroutine,offset LoSlopeCycleLine4
        cmp bx,cx
        jle CycleLine44
        mov VARroutine,offset HiSlopeCycleLine4
        xchg bx,cx     ; exchange dy and dx

; calculate initial decision variable and increments

CycleLine44:
        shl bx,1           ; bx = 2 * dy
        mov VARincr1,bx    ; incr1 = 2 * dy
        sub bx,cx
        mov di,bx          ; di = d = 2 * dy - dx
        sub bx,cx
        mov VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr4
        call GetCycleColor
;        mov   al,byte ptr _fgsv.fgsColor; ARGn  ; AL = unshifted pixel value
        and   ax,3
        shl  ax,cl     ; put bit mask and pixel value in proper position
        mov  dx,ax     ; DH = bit mask DL = pixel value
        not  dh        ; DH = inverse bit mask
        pop  cx
        inc  cx        ; CX = number of pixels to draw
        test bx,2000h  ; set zero flag if BX in first interleave
        jz   CycleLine45
        xchg si,VARleafincr ; exchange increment values if first pixel
CycleLine45:
        jmp  VARroutine

; Routine for vertical line

VCycleLine4:
        mov  ax,ARGy1  ; AX = y1
        mov  bx,ARGy2  ; BX = y2
        mov  cx,bx
        sub  cx,ax     ; CX = dy
        jge  CycleLine431
        neg  cx        ; force dy >= 0
        mov  ax,bx     ; AX = y2

CycleLine431:
        inc  cx        ; CX = # of pixels to draw
        mov  bx,ARGx1  ; BX = x
        push cx        ; preserve
        call PointAddr4
        ;---------------------------------
        ;    Get the pixel color to plot.
        ;---------------------------------
        call GetCycleColor
;        mov  al,byte ptr _fgsv.fgsColor ; ARGn   ; AL = pixel value
        and  ax,3
        shl  ax,cl     ; put bit mask and pixel value in proper position
        not  ah        ; AH = inverse bit mask
        pop  cx        ; restore

        test bx,si
        jz   CycleLine432
        xchg si,di     ; exchange increment values if first pixel lies in first interleave

; Draw the line
CycleLine432:
        test al,al     ; jump if pixel value = 0
        jz   CycleLine434

CycleLine433:
        or   es:[bx],al     ; set pixel values in buffer
        add  bx,si
        xchg si,di
        loop CycleLine433
        jmp  CycleLine4Exit

CycleLine434:
        and  es:[bx],ah     ; reset pixel values in buffer
        add  bx,si
        xchg si,di
        loop CycleLine434
        jmp  CycleLine4Exit

; Routine for horizontal lines

HCycleLine4:
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr4
        mov  di,bx     ; es:di -> buffer
        mov  dh,ah
        not  dh        ; DH = unbshifted bit mask for leftmost byte
        mov  dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl  dh,cl     ; DH = reverse bit mask for first byte
        not  dh        ; DH = bit mask for first byte
        mov  cx,ARGx2
        and  cl,3
        xor  cl,3      ; CL = number of bits to shift left
        shl  cl,1
        shl  dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov  ax,ARGx2
        mov  bx,ARGx1
        mov  cl,2      ; number of bits to shift to turn pixels into bytes
        shr  ax,cl
        shr  bx,cl
        mov  cx,ax
        sub  cx,bx     ; CX = number of bytes in line - 1

; propagate pixel value throughout one byte

        lea  bx,PropagatedPixel4
        mov  al,byte ptr _fgsv.fgsColor  ; ARGn
        and   al,3
        xlat

; set pixels in leftmost byte of the line

        or   dh,dh
        js   CycleLine443  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or   cx,cx
        jnz  CycleLine442  ; jump if more than one byte in line
        and  dl,dh     ; bit mask for the line
        jmp  short CycleLine444

CycleLine442:
        mov  ah,al
        and  ah,dh     ; AH = masked pixel bits
        not  dh        ; DH = reverse bit mask for first byte
        and  es:[di],dh; zero masked pixels in buffer
        or   es:[di],ah; update masked pixels in buffer
        inc  di
        dec  cx

; use fast 8086 instruction to draw remainder of line

CycleLine443:
        rep  stosb     ; update all pixels in the line (can not use stosw)

; set pixels in the rightmost byte of the line

CycleLine444:
        and  al,dl     ; AL = masked pixels for last byte
        not  dl
        and  es:[di],dl; zero masked pixels in buffer
        or   es:[di],al; update masked pixels in buffer
        jmp  CycleLine4Exit

; Routine for dy <= dx

LoSlopeCycleLine4:

CycleLine410:
        mov  ah,es:[bx]     ; AH = byte from video buffer
CycleLine411:
        and  ah,dh          ; zero pixel value at current bit offset
        or   ah,dl          ; set pixel value in btye
        ror  dl,2           ; rotate pixel value
        ror  dh,2           ; rotate bit mask
        jnc  CycleLine414        ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or   di,di          ; test sign of d
        jns  CycleLine412        ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine411
        mov  es:[bx],ah     ; store remaining pixel in buffer
        jmp  short CycleLine4Exit
CycleLine412:
        add  di,VARincr2    ; d = d + incr2
        mov  es:[bx],ah     ; update buffer
        add  bx,si          ; increment y
        xchg si,VARleafincr
        loop CycleLine410
        jmp  short CycleLine4Exit

; bit mask shifted out

CycleLine414:
        mov  es:[bx],ah
        inc  bx             ; bx = offset of next byte
        or   di,di          ; test sign of d
        jns  CycleLine415       ; jump if non negative
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine410
        jmp  short CycleLine4Exit
CycleLine415:
        add  di,VARincr2    ; d = d + incr2
        add  bx,si          ; increment y
        xchg si,VARleafincr
        loop CycleLine410
        jmp  short CycleLine4Exit

; routine for dy > dx

HiSlopeCycleLine4:
CycleLine421:
        and  es:[bx],dh     ; zero pixel value in video buffer
        or   es:[bx],dl     ; set pixel value in byte
        add  bx,si          ; increment y
        xchg  si,VARleafincr
CycleLine422:
        or   di,di          ; test sign of d
        jns  CycleLine423       ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine421
        jmp  short CycleLine4Exit
CycleLine423:
        add  di,VARincr2    ; d = d + incr2
        ror  dl,2           ; rotate pixel value
        ror  dh,2           ; rotate bit mask
        cmc                 ; cf set if bit mask not rotated to leftmost pixel
        adc  bx,0           ; bx = offset of next byte
        loop CycleLine421
CycleLine4Exit:
        pop  di
        pop  si
        leave
        retf
_CycleLine4  endp
        end
; 
