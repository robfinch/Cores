comment ~
================================================================================
   
 (C) 1993 FinchWare

 Module : md6.asm

 Description :
    Contains mode 6 graphics routines.

        mode resolution     colors    adapter
        6    - 640 x 200    2         CGA/EGA/VGA

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

_TEXT   segment word public 'CODE'
        assume cs:_TEXT,ds:_TEXT,es:_TEXT,ss:_TEXT
begin:
        jmp ErrorOut

        align 2

;-------------------------------------------------------------------
;    This area is laid out according to the fgs graphics structure.
;-------------------------------------------------------------------
_fgsv   label   fgs
        dw      ?           ; pointer to video state save area
        dw      6           ; video mode
        dw      640         ; device physical characteristics - MaxX
        dw      200         ; MaxY
        dw      2           ; MaxColor
        dw      1           ; color
        dw      ?           ; border color
        dw      0           ; cursor x
        dw      0           ; cursor y
        dw      0           ; x reference point
        dw      0           ; y reference point
        db      MCOPY       ; Drawing mode (AND, OR, XOR, COPY, ...)
        db      ?           ; filling mode
        dw      PointCopy   ; pointer to point updating code
        ;-------------------
        dw      PointCopy   ; table of pointers to draw mode dependant 
        dw      PointXor    ; point updateing
        dw      PointOr  
        dw      PointAnd
        dw      ?           ; reserved for additional functions
        dw      ?
        ;-------------------
        dw      GetPoint6   ; Point getting routine
        dw      ?           ; Segment
        dw      Point6      ; point plotting routine
        dw      ?           ; Segment
        dw      Line6       ; line drawing routine
        dw      ?           ; Segment
        dd      13 dup (?)  ; 13 more far pointers to routines
        dw      0           ; horizontal line drawing routine
        dw      ?           ; left scan routine
        dw      ?           ; right scan routine
        dw      0b800h      ; virtual screen segment
        dw      0b800h      ; real screen segment
        dw      ?           ; pointer to cycling color
        db      0           ; clip
        dw      -1          ; clip coordinate - left
        dw      0           ; top
        dw      639         ; right
        dw      199         ; bottom
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : PointAddr6

 Description :
    Calculates the address of a point in the video buffer in mode6
 
 Parameters :
    bx - x coordinate
    ax - y coordinate

 Registers Affected :

 Returns :
    es:[bx]     - byte address
    ah          - 1
    cl          - bit address

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
PointAddr6      proc near
        mov     es,word ptr _fgsv.fgsVScreen  ; Set es to point to virtual screen
        mov     cl,bl
        and     cl,7      ; pixel address calculation
        xor     cl,7
        shr     bx,3      ; calculate byte in row by dividing pixel number by 8
        shr     ax,1      ; odd scan lines offset by 2000h
        jnb     PointAddr62
        add     bx,2000h
PointAddr62:
        shl     ax,4  ; * 16   ; multiply by 80 by adding 16 * ax + 64 * ax
        add     bx,ax          ; to base (bx)
        shl     ax,2  ; * 64
        add     bx,ax
        mov     ah,3
        ret
PointAddr6   endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : GetPoint6

 Description :
    Gets the value of a pixel in mode 6

 Parameters :

 Registers Affected :
    AX,BX,CX,ES

 Returns :
    AX - value of pixel 0 or 1

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
GetPoint6   proc near
        enter   0,0
        push    ds
        mov     ax,cs
        mov     ds,ax
        mov     ax,ARGy1
        mov     bx,ARGx1
        call    PointAddr6
        mov     al,es:[bx]
        shr     al,cl
        and     al,ah
        cbw              ; ah = 0
        pop     ds
        leave
        retf
GetPoint6   endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Point6

 Description :
    Plot point in 640 x 200 two colour mode (mode 6).

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
Point6  proc near
        enter   0,0
        push    ds
        mov     ax,cs
        mov     ds,ax
        mov     ax,ARGy
        mov     bx,ARGx
        call    PointAddr6
        mov     al,byte ptr _fgsv.fgsColor
        and     al,ah
        not     ah
        shl     ax,cl     ; shift color (al) and mask (ah)
        call    word ptr _fgsv.fgsPointPtr
        pop     ds
        leave
        retf
PointCopy:
        and     es:[bx],ah  ; clear bit
        or      es:[bx],al  ; set bit to color
        ret
PointXor:
        xor     es:[bx],al
        ret
PointAnd:
        and     es:[bx],al
        ret
PointOr:
        or      es:[bx],al
        ret
Point6  endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Line6

 Description :
    Draws line in graphics mode 6

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
Line6   proc    near
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
        jz      VLine6         ; jump if vertical line

; force x1 < x2

        jns     Line61         ; jump if x2 > x1
        neg     cx             ; cx = x1-x2
        mov     bx,ARGx2       ; exchange x1 and x2
        xchg    bx,ARGx1
        mov     ARGx2,bx
        mov     bx,ARGy2       ; exchange y1 and y2
        xchg    bx,ARGy1
        mov     ARGy2,bx

; dy = abs(y2-y1)

Line61:
        mov     bx,ARGy2
        sub     bx,ARGy1  ; bx = y2 - y1
        jnz     Line62
        jmp     HLine6   ; jump if horizontal line

Line62:
        jns     Line63
        neg     bx        ; bx = y1 - y2
        neg     si        ; negate y increment
        neg     di
        xchg    si,di     ; exchange increments

; select appropriate routine for slope of line

Line63:
        mov     VARleafincr,di ; save increment for buffer interleave
        mov     VARroutine,offset LoSlopeLine6
        cmp     bx,cx
        jle     Line64
        mov     VARroutine,offset HiSlopeLine6
        xchg    bx,cx     ; exchange dy and dx

; calculate initial decision variable and increments

Line64:
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
        call    PointAddr6
        mov     al,byte ptr _fgsv.fgsColor; ARGn   ; AL = unshifted pixel value
        and     al,ah
        shl     ax,cl       ; put bit mask and pixel value in proper position
        mov     dx,ax       ; DH = bit mask DL = pixel value
        not     dh          ; DH = inverse bit mask
        pop     cx
        inc     cx          ; CX = number of pixels to draw
        test    bx,2000h    ; set zero flag if BX in first interleave
        jz      Line65
        xchg    si,VARleafincr ; exchange increment values if first pixel
Line65:
        jmp     VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VLine6:
        mov     ax,ARGy1  ; AX = y1
        mov     bx,ARGy2  ; BX = y2
        mov     cx,bx
        sub     cx,ax     ; CX = dy
        jge     Line631
        neg     cx        ; force dy >= 0
        mov     ax,bx     ; AX = y2
Line631:
        inc     cx        ; CX = # of pixels to draw
        mov     bx,ARGx1  ; BX = x
        push    cx       ; preserve
        call    PointAddr6
        ;---------------------------------
        ;    Get the pixel color to plot.
        ;---------------------------------
        mov     al,byte ptr _fgsv.fgsColor; ARGn   ; AL = pixel value
        and     al,ah    ; ah = 1
        shl     ax,cl     ; put bit mask and pixel value in proper position
        not     ah        ; AH = inverse bit mask
        pop     cx        ; restore
        test    bx,si
        jz      Line632
        xchg    si,di     ; exchange increment values if first pixel lies in firt interleave
        ;---------------
        ; Draw the line
        ;---------------
Line633:
        call    word ptr _fgsv.fgsPointPtr
        add     bx,si
        xchg    si,di
        loop    Line633
        jmp     Line6Exit
;------------------------------
; Routine for horizontal lines
;------------------------------
HLine6:
        mov     ax,ARGy1
        mov     bx,ARGx1
        call    PointAddr6
        mov     di,bx     ; es:di -> buffer
        mov     dh,ah     
        not     dh        ; DH = unbshifted bit mask for leftmost byte
        mov     dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl     dh,cl     ; DH = reverse bit mask for first byte
        not     dh        ; DH = bit mask for first byte
        mov     cx,ARGx2
        and     cl,7
        xor     cl,7      ; CL = number of bits to shift left
        shl     dl,cl     ; DL = bit mask for last byte

        ; Determine byte offset for first and last pixel in line

        mov     ax,ARGx2
        mov     bx,ARGx1
        mov     cl,3      ; number of bits to shift to turn pixels into bytes
        shr     ax,cl
        shr     bx,cl
        mov     cx,ax
        sub     cx,bx     ; CX = number of bytes in line - 1

        ; get pixel color - propagate pixel value throughout one byte

        mov     al,byte ptr _fgsv.fgsColor; ARGn
        and     al,1
        neg     al  ; convert al to 0 or -1 (0ffh)

        ; set pixels in leftmost byte of the line

        or      dh,dh
        js      Line643  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or      cx,cx
        jnz     Line642  ; jump if more than one byte in line
        and     dl,dh     ; bit mask for the line
        jmp     short Line644
Line642:
        mov     ah,al
        and     ah,dh     ; AH = masked pixel bits
        not     dh        ; DH = reverse bit mask for first byte
        and     es:[di],dh; zero masked pixels in buffer
        or      es:[di],ah; update masked pixels in buffer
        inc     di
        dec     cx

        ; use fast 8086 instruction to draw remainder of line

Line643:
        rep     stosb     ; update all pixels in the line (can not use stosw)

        ; set pixels in the rightmost byte of the line

Line644:
        and     al,dl     ; AL = masked pixels for last byte
        not     dl
        and     es:[di],dl; zero masked pixels in buffer
        or      es:[di],al; update masked pixels in buffer
        jmp     Line6Exit
;----------------------
; Routine for dy <= dx
;----------------------
LoSlopeLine6:
Line610:
        mov     ah,es:[bx]     ; AH = byte from video buffer
Line611:
        and     ah,dh          ; zero pixel value at current bit offset
        or      ah,dl          ; set pixel value in btye
        ror     dl,1           ; rotate pixel value
        ror     dh,1           ; rotate bit mask
        jnc     Line614       ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or      di,di          ; test sign of d
        jns     Line612       ; jump if d >= 0
        add     di,VARincr1    ; d = d + incr1
        loop    Line611
        mov     es:[bx],ah     ; store remaining pixel in buffer
        jmp     short Line6Exit
Line612:
        add     di,VARincr2    ; d = d + incr2
        mov     es:[bx],ah     ; update buffer
        add     bx,si          ; increment y
        xchg    si,VARleafincr
        loop    Line610
        jmp     short Line6Exit

; bit mask shifted out

Line614:
        mov     es:[bx],ah
        inc     bx             ; bx = offset of next byte
        or      di,di          ; test sign of d
        jns     Line615       ; jump if non negative
        add     di,VARincr1    ; d = d + incr1
        loop    Line610
        jmp     short Line6Exit
Line615:
        add     di,VARincr2    ; d = d + incr2
        add     bx,si          ; increment y
        xchg    si,VARleafincr
        loop    Line610
        jmp     short Line6Exit

; routine for dy > dx

HiSlopeLine6:
Line621:
        and     es:[bx],dh     ; zero pixel value in video buffer
        or      es:[bx],dl     ; set pixel value in byte
        add     bx,si          ; increment y
        xchg    si,VARleafincr
Line622:
        or      di,di          ; test sign of d
        jns     Line623       ; jump if d >= 0
        add     di,VARincr1    ; d = d + incr1
        loop    Line621
        jmp     short Line6Exit
Line623:
        add     di,VARincr2    ; d = d + incr2
        ror     dl,1           ; rotate pixel value
        ror     dh,1           ; rotate bit mask
        cmc                    ; cf set if bit mask not rotated to leftmost pixel ???
        adc     bx,0           ; bx = offset of next byte
        loop    Line621
Line6Exit:
        pop     di
        pop     si
        leave
        retf
Line6  endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : _CycleLine6

 Description :
    Draws line in graphics mode 6

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
        public    _CycleLine6
_CycleLine6  proc      near
        enter 12,0
        push si
        push di

        mov  si,2000h       ; si = increment for video buffer interleave
        mov  di,80-2000h    ; increment from last to first interleave
        mov  cx,ARGx2
        sub  cx,ARGx1       ; CX = x2 - x1
        jz   VCycleLine6         ; jump if vertical line

; force x1 < x2

        jns  CycleLine61         ; jump if x2 > x1
        neg  cx             ; cx = x1-x2
        mov  bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov  ARGx2,bx
        mov  bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov  ARGy2,bx

; dy = abs(y2-y1)

CycleLine61:
        mov  bx,ARGy2
        sub  bx,ARGy1  ; bx = y2 - y1
        jnz  CycleLine62
        jmp  HCycleLine6   ; jump if horizontal line

CycleLine62:
        jns  CycleLine63
        neg  bx        ; bx = y1 - y2
        neg  si        ; negate y increment
        neg  di
        xchg si,di     ; exchange increments

; select appropriate routine for slope of line

CycleLine63:
        mov  VARleafincr,di ; save increment for buffer interleave
        mov  VARroutine,offset LoSlopeCycleLine6
        cmp  bx,cx
        jle  CycleLine64
        mov  VARroutine,offset HiSlopeCycleLine6
        xchg bx,cx     ; exchage dy and dx

; calculate initial decision variable and increments

CycleLine64:
        shl  bx,1           ; bx = 2 * dy
        mov  VARincr1,bx    ; incr1 = 2 * dy
        sub  bx,cx
        mov  di,bx          ; di = d = 2 * dy - dx
        sub  bx,cx
        mov  VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve
        mov ax,ARGy1
        mov bx,ARGx1
        call PointAddr6
        call GetCycleColor
;        mov al,byte ptr _fgsv.fgsColor; ARGn   ; AL = unshifted pixel value
        and ax,1
        shl ax,cl     ; put bit mask and pixel value in proper position
        mov dx,ax     ; DH = bit mask DL = pixel value
        not dh        ; DH = inverse bit mask
        pop cx
        inc cx        ; CX = number of pixels to draw
        test bx,2000h  ; set zero flag if BX in first interleave
        jz CycleLine65
        xchg si,VARleafincr ; exchange increment values if first pixel
CycleLine65:
        jmp  VARroutine

; Routine for vertical line

VCycleLine6:
        mov  ax,ARGy1  ; AX = y1
        mov  bx,ARGy2  ; BX = y2
        mov  cx,bx
        sub  cx,ax     ; CX = dy
        jge  CycleLine631
        neg  cx        ; force dy >= 0
        mov  ax,bx     ; AX = y2

CycleLine631:
        inc  cx        ; CX = # of pixels to draw
        mov  bx,ARGx1  ; BX = x
        push cx        ; preserve
        call PointAddr6
        call GetCycleColor
;        mov  al,byte ptr _fgsv.fgsColor; ARGn   ; AL = pixel value
        and ax,1
        shl ax,cl     ; put bit mask and pixel value in proper position
        not ah        ; AH = inverse bit mask
        pop cx        ; restore

        test bx,si
        jz CycleLine632
        xchg si,di     ; exchange increment values if first pixel lies in firt interleave

; Draw the line
CycleLine632:
        test al,al     ; jump if pixel value = 0
        jz CycleLine634

CycleLine633:
        or   es:[bx],al     ; set pixel values in buffer
        add  bx,si
        xchg si,di
        loop CycleLine633
        jmp  CycleLine6Exit

CycleLine634:
        and  es:[bx],ah     ; reset pixel values in buffer
        add  bx,si
        xchg si,di
        loop CycleLine634
        jmp  CycleLine6Exit

; Routine for horizontal lines

HCycleLine6:
        mov     ax,ARGy1
        mov     bx,ARGx1
        call    PointAddr6
        mov     di,bx     ; es:di -> buffer
        mov     dh,ah     
        not     dh        ; DH = unbshifted bit mask for leftmost byte
        mov     dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl     dh,cl     ; DH = reverse bit mask for first byte
        not     dh        ; DH = bit mask for first byte
        mov     cx,ARGx2
        and     cl,7
        xor     cl,7      ; CL = number of bits to shift left
        shl     dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov     ax,ARGx2
        mov     bx,ARGx1
        mov     cl,3      ; number of bits to shift to turn pixels into bytes
        shr     ax,cl
        shr     bx,cl
        mov     cx,ax
        sub     cx,bx     ; CX = number of bytes in line - 1

; get pixel color

        mov     al,byte ptr _fgsv.fgsColor; ARGn
        and     al,1
        neg     al

; set pixels in leftmost byte of the line

        or   dh,dh
        js   CycleLine643  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or   cx,cx
        jnz  CycleLine642  ; jump if more than one byte in line
        and  dl,dh     ; bit mask for the line
        jmp  short CycleLine644

CycleLine642:
        mov  ah,al
        and  ah,dh     ; AH = masked pixel bits
        not  dh        ; DH = reverse bit mask for first byte
        and  es:[di],dh; zero masked pixels in buffer
        or   es:[di],ah; update masked pixels in buffer
        inc  di
        dec  cx

; use fast 8086 instruction to draw remainder of line

CycleLine643:
        rep  stosb     ; update all pixels in the line (can not use stosw)

; set pixels in the rightmost byte of the line

CycleLine644:
        and  al,dl     ; AL = masked pixels for last byte
        not  dl
        and  es:[di],dl; zero masked pixels in buffer
        or   es:[di],al; update masked pixels in buffer
        jmp  CycleLine6Exit

; Routine for dy <= dx

LoSlopeCycleLine6:

CycleLine610:
        mov  ah,es:[bx]     ; AH = byte from video buffer
CycleLine611:
        and  ah,dh          ; zero pixel value at current bit offset
        or   ah,dl          ; set pixel value in btye
        ror  dl,1           ; rotate pixel value
        ror  dh,1           ; rotate bit mask
        jnc  CycleLine614       ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or   di,di          ; test sign of d
        jns  CycleLine612       ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine611
        mov  es:[bx],ah     ; store remaining pixel in buffer
        jmp  short CycleLine6Exit
CycleLine612:
        add  di,VARincr2    ; d = d + incr2
        mov  es:[bx],ah     ; update buffer
        add  bx,si          ; increment y
        xchg si,VARleafincr
        loop CycleLine610
        jmp  short CycleLine6Exit

; bit mask shifted out

CycleLine614:
        mov  es:[bx],ah
        inc  bx             ; bx = offset of next byte
        or   di,di          ; test sign of d
        jns  CycleLine615       ; jump if non negative
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine610
        jmp  short CycleLine6Exit
CycleLine615:
        add  di,VARincr2    ; d = d + incr2
        add  bx,si          ; increment y
        xchg si,VARleafincr
        loop CycleLine610
        jmp  short CycleLine6Exit

; routine for dy > dx

HiSlopeCycleLine6:
CycleLine621:
        and  es:[bx],dh     ; zero pixel value in video buffer
        or   es:[bx],dl     ; set pixel value in byte
        add  bx,si          ; increment y
        xchg  si,VARleafincr
CycleLine622:
        or   di,di          ; test sign of d
        jns  CycleLine623       ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine621
        jmp  short CycleLine6Exit
CycleLine623:
        add  di,VARincr2    ; d = d + incr2
        ror  dl,1           ; rotate pixel value
        ror  dh,1           ; rotate bit mask
        cmc                 ; cf set if bit mask not rotated to leftmost pixel ???
        adc  bx,0           ; bx = offset of next byte
        loop CycleLine621
CycleLine6Exit:
        pop  di
        pop  si
        leave
        ret
_CycleLine6  endp
comment ~
================================================================================
   
 (C) FinchWare

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
Msg1    db      '(C) 1993 FinchWare - Mode 6 graphics driver.', 0dh, 0ah, 0

ErrorOut        proc  near
        mov si,cs
        mov ds,si
        lea si,Msg1
        cld
PMsg:
        mov ah,14
        lodsb
        or al,al
        jz PMsg2
        mov bx,1
        int 10h
        jmp short PMsg
PMsg2:
        ret
ErrorOut        endp
_TEXT   ends
        end     begin
; 

