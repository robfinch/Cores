comment ~
================================================================================
   
 (C) 1993 FinchWare

 Module : md11.asm

 Description :
    Contains mode 6 graphics routines.

        mode resolution     colors    adapter
        11   - 640 x 480    2         MCGA/VGA

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

        jmp ErrorOut
        
        align 2
;-------------------------------------------------------------------
;    This area is laid out according to the fgs graphics structure.
;-------------------------------------------------------------------
_fgsv   label   fgs
        dw      ?           ; pointer to video state save area
        dw      6           ; video mode
        dw      ?           ; mode index
        dw      640         ; device physical characteristics - MaxX
        dw      200         ; MaxY
        dw      2           ; MaxColor
        dw      ?           ; command
        dw      ?           ; Drawing mode (AND, OR, XOR, COPY, ...)
        dw      ?           ; filling mode
        dw      GetPoint6   ; Point getting routine
        dw      Point6      ; point plotting routine
        dw      Line6       ; line drawing routine
        dw      ?           ; horizontal line drawing routine
        dw      ?           ; left scan routine
;        dw      ?           ; right scan routine
        dw      0b800h      ; virtual screen segment
        dw      0b800h      ; real screen segment
        dw      1           ; color
        dw      ?           ; border color
        dw      0           ; cursor x
        dw      0           ; cursor y
        dw      0           ; x reference point
        dw      0           ; y reference point
        dw      ?           ; pointer to cycling color
        dw      ?           ; clip
        dw      0           ; clip coordinate - left
        dw      0           ; top
        dw      639         ; right
        dw      199         ; bottom

Width80 dw      80          ; constant for point addressing


comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : 

 Description :
    Handles getting of points for modes
        mode resolution     colors    adapter
        11   - 640 x 480    2         MCGA/VGA

 Parameters :

 Registers Affected :
    AX,BX,CX,ES

 Returns :
    AX pixel value 0 or 1

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
        public    _GetPoint11
_GetPoint11  proc near
        enter 0,0
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr10
        mov  al,es:[bx]
        shr  al,cl
        and  al,ah
        cbw        ; set ah = 0
        leave
        ret
_GetPoint11  endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Point11

 Description :
    Plots a point on the screen. Mode 11h 640 x 200, 2 color. (MCGA/VGA)

 Parameters :

 Registers Affected : AX,BX,ES

 Changes
         Author      : R. Finch
         Date        : 92/01/25
         Release     :
         Description : new module

================================================================================
~
        public    Point11
Point11     proc near
        enter 0,0
        mov   ax,ARGy1
        mov   bx,ARGx1
        call  PointAddr10
        mov   al,byte ptr _fgsv.fgsColor
        and   al,ah   ; ah = 1
        shl   ax,cl
        jmp   word ptr _fgsv.fgsPointPtr
Point11     endp
; 
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
        public    Line11
Line11 proc      near
        enter 10,0
        push si
        push di
        mov si,Width80      ; si = initial y increment
        mov cx,ARGx2
        sub cx,ARGx1        ; CX = x2 - x1
        jz VLine11          ; jump if vertical line

; force x1 < x2

        jns  Line111        ; jump if x2 > x1
        neg  cx             ; cx = x1-x2
        mov  bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov  ARGx2,bx
        mov  bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov  ARGy2,bx

; dy = abs(y2-y1)
              
Line111:
        mov  bx,ARGy2
        sub  bx,ARGy1  ; bx = y2 - y1
        jnz  Line112
        jmp  HLine11   ; jump if horizontal line

Line112:
        jns  Line113
        neg  bx        ; bx = y1 - y2
        neg  si        ; negate y increment

; select appropriate routine for slope of line

Line113:
        mov  VARroutine,offset LoSlopeLine11
        cmp  bx,cx
        jle  Line114
        mov  VARroutine,offset HiSlopeLine11
        xchg bx,cx     ; exchage dy and dx

; calculate initial decision variable and increments

Line114:
        shl bx,1           ; bx = 2 * dy
        mov VARincr1,bx    ; incr1 = 2 * dy
        sub bx,cx
        mov di,bx          ; di = d = 2 * dy - dx
        sub bx,cx
        mov VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve
        mov ax,ARGy1
        mov bx,ARGx1
        call PointAddr10
        mov al,byte ptr _fgsv.fgsColor;   ; AL = unshifted pixel value
        shl ax,cl     ; put bit mask and pixel value in proper position
        mov dx,ax     ; DH = bit mask DL = pixel value
        not dh        ; DH = inverse bit mask
        pop cx
        inc cx        ; CX = number of pixels to draw
        jmp VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VLine11:
        mov ax,ARGy1  ; AX = y1
        mov bx,ARGy2  ; BX = y2
        mov cx,bx
        sub cx,ax     ; CX = dy = (y2 - y1)
        jns Line1131
        neg cx        ; force dy >= 0
        mov ax,bx     ; AX = y2
Line1131:
        inc cx        ; CX = # of pixels to draw
        mov bx,ARGx1  ; BX = x
        push cx       ; preserve
        call PointAddr10    
        mov al,byte ptr _fgsv.fgsColor  ; AL = pixel value
        shl ax,cl     ; put bit mask and pixel value in proper position
        not ah        ; AH = inverse bit mask
        pop cx        ; restore

        ; Draw the line

        test al,al     ; jump if pixel value = 0
        jz Line1133
Line1132:
        or es:[bx],al    ; set pixel values in buffer
        add bx,si
        loop Line1132
        jmp Line11Exit
Line1133:
        and es:[bx],ah   ; reset pixel values in buffer
        add bx,si
        loop Line1133
        jmp Line11Exit
        ;------------------------------
        ; Routine for horizontal lines
        ;------------------------------
HLine11:
        mov ax,ARGy1
        mov bx,ARGx1
        call PointAddr10
        mov di,bx     ; es:di -> buffer
        mov dh,ah     
        not dh        ; DH = unbshifted bit mask for leftmost byte
        mov dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl dh,cl     ; DH = reverse bit mask for first byte
        not dh        ; DH = bit mask for first byte
        mov cx,ARGx2
        and cl,7
        xor cl,7      ; CL = number of bits to shift left
        shl dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov ax,ARGx2
        mov bx,ARGx1
        mov cl,3      ; number of bits to shift to turn pixels into bytes
        shr ax,cl
        shr bx,cl
        mov cx,ax
        sub cx,bx     ; CX = number of bytes in line - 1

; propagate pixel value throughout one byte

        lea bx,DGROUP:PropagatedPixel
        mov al,byte ptr _fgsv.fgsColor; ARGn
        xlat

; set pixels in leftmost byte of the line

        or dh,dh
        js Line1143  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or cx,cx
        jnz Line1142  ; jump if more than one byte in line
        and dl,dh     ; bit mask for the line
        jmp short Line1144

Line1142:
        mov ah,al
        and ah,dh     ; AH = masked pixel bits
        not dh        ; DH = reverse bit mask for first byte
        and es:[di],dh; zero masked pixels in buffer
        or es:[di],ah ; update masked pixels in buffer
        inc di
        dec cx

; use fast 8086 instruction to draw remainder of line

Line1143:
        rep stosb     ; update all pixels in the line (can not use stosw)

; set pixels in the rightmost byte of the line

Line1144:
        and al,dl     ; AL = masked pixels for last byte
        not dl
        and es:[di],dl; zero masked pixels in buffer
        or es:[di],al; update masked pixels in buffer
        jmp Line11Exit

; Routine for dy <= dx

LoSlopeLine11:

Line1110:
        mov ah,es:[bx]     ; AH = byte from video buffer
Line1111:
        and ah,dh          ; zero pixel value at current bit offset
        or ah,dl          ; set pixel value in btye
        ror dl,1           ; rotate pixel value
        ror dh,1           ; rotate bit mask
        jnc Line1114       ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or  di,di          ; test sign of d
        jns Line1112       ; jump if d >= 0
        add di,VARincr1    ; d = d + incr1
        loop Line1111
        mov es:[bx],ah     ; store remaining pixel in buffer
        jmp short Line11Exit
Line1112:
        add di,VARincr2    ; d = d + incr2
        mov es:[bx],ah     ; update buffer
        add bx,si          ; increment y
        loop Line1110
        jmp short Line11Exit

; bit mask shifted out

Line1114:
        mov es:[bx],ah
        inc bx             ; bx = offset of next byte
        or  di,di          ; test sign of d
        jns Line1115       ; jump if non negative
        add di,VARincr1    ; d = d + incr1
        loop Line1110
        jmp short Line11Exit
Line1115:
        add di,VARincr2    ; d = d + incr2
        add bx,si          ; increment y
        loop Line1110
        jmp short Line11Exit

; routine for dy > dx

HiSlopeLine11:
Line1121:
        and es:[bx],dh   ; zero pixel value in video buffer
        or es:[bx],dl    ; set pixel value in byte
        add bx,si        ; increment y
Line1122:
        or di,di         ; test sign of d
        jns Line1123     ; jump if d >= 0
        add di,VARincr1  ; d = d + incr1
        loop Line1121
        jmp short Line11Exit
Line1123:
        add di,VARincr2  ; d = d + incr2
        ror dl,1         ; rotate pixel value
        ror dh,1         ; rotate bit mask
        cmc              ; cf set if bit mask not rotated to leftmost pixel
        adc bx,0         ; bx = offset of next byte
        loop Line1121
Line11Exit:
        pop di
        pop si
        leave
        ret
Line11 endp
; 
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
        public    _CycleLine11
_CycleLine11 proc      near
        enter 10,0
        push si
        push di

        mov  si,Width80     ; si = initial y increment
        mov  cx,ARGx2
        sub  cx,ARGx1       ; CX = x2 - x1
        jz   VCycleLine11        ; jump if vertical line

; force x1 < x2

        jns  CycleLine111        ; jump if x2 > x1
        neg  cx             ; cx = x1-x2
        mov  bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov  ARGx2,bx
        mov  bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov  ARGy2,bx

; dy = abs(y2-y1)
              
CycleLine111:
        mov  bx,ARGy2
        sub  bx,ARGy1  ; bx = y2 - y1
        jnz  CycleLine112
        jmp  HCycleLine11   ; jump if horizontal line

CycleLine112:
        jns  CycleLine113
        neg  bx        ; bx = y1 - y2
        neg  si        ; negate y increment

; select appropriate routine for slope of line

CycleLine113:
        mov  VARroutine,offset LoSlopeCycleLine11
        cmp  bx,cx
        jle  CycleLine114
        mov  VARroutine,offset HiSlopeCycleLine11
        xchg bx,cx     ; exchage dy and dx

; calculate initial decision variable and increments

CycleLine114:
        shl  bx,1           ; bx = 2 * dy
        mov  VARincr1,bx    ; incr1 = 2 * dy
        sub  bx,cx
        mov  di,bx          ; di = d = 2 * dy - dx
        sub  bx,cx
        mov  VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr10
        call GetCycleColor  ; need to store ah here
;        mov  al,byte ptr _fgsv.fgsColor;   ; AL = unshifted pixel value
        shl  ax,cl     ; put bit mask and pixel value in proper position
        mov  dx,ax     ; DH = bit mask DL = pixel value
        not  dh        ; DH = inverse bit mask
        pop  cx
        inc  cx        ; CX = number of pixels to draw
        jmp  VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VCycleLine11:
        mov  ax,ARGy1  ; AX = y1
        mov  bx,ARGy2  ; BX = y2
        mov  cx,bx
        sub  cx,ax     ; CX = dy
        jge  CycleLine1131
        neg  cx        ; force dy >= 0
        mov  ax,bx     ; AX = y2

CycleLine1131:
        inc  cx        ; CX = # of pixels to draw
        mov  bx,ARGx1  ; BX = x
        push cx        ; preserve
        call PointAddr10    
        call GetCycleColor  ; need ah ***
;        mov  al,byte ptr _fgsv.fgsColor;   ; AL = pixel value
        shl  ax,cl     ; put bit mask and pixel value in proper position
        not  ah        ; AH = inverse bit mask
        pop  cx        ; restore

; Draw the line

        test al,al     ; jump if pixel value = 0
        jz   CycleLine1133

CycleLine1132:
        or   es:[bx],al     ; set pixel values in buffer
        add  bx,si
        loop CycleLine1132
        jmp  CycleLine11Exit

CycleLine1133:
        and  es:[bx],ah     ; reset pixel values in buffer
        add  bx,si
        loop CycleLine1133
        jmp  CycleLine11Exit

;------------------------------
; Routine for horizontal lines
;------------------------------
HCycleLine11:
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr10
        mov  di,bx     ; es:di -> buffer
        mov  dh,ah     
        not  dh        ; DH = unbshifted bit mask for leftmost byte
        mov  dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl  dh,cl     ; DH = reverse bit mask for first byte
        not  dh        ; DH = bit mask for first byte
        mov  cx,ARGx2
        and  cl,7
        xor  cl,7      ; CL = number of bits to shift left
        shl  dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov  ax,ARGx2
        mov  bx,ARGx1
        mov  cl,3      ; number of bits to shift to turn pixels into bytes
        shr  ax,cl
        shr  bx,cl
        mov  cx,ax
        sub  cx,bx     ; CX = number of bytes in line - 1

; propagate pixel value throughout one byte

        lea  bx,DGROUP:PropagatedPixel
        call GetCycleColor
;        mov  al,byte ptr _fgsv.fgsColor; ARGn
        xlat

; set pixels in leftmost byte of the line

        or   dh,dh
        js   CycleLine1143  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or   cx,cx
        jnz  CycleLine1142  ; jump if more than one byte in line
        and  dl,dh     ; bit mask for the line
        jmp  short CycleLine1144

CycleLine1142:
        mov  ah,al
        and  ah,dh     ; AH = masked pixel bits
        not  dh        ; DH = reverse bit mask for first byte
        and  es:[di],dh; zero masked pixels in buffer
        or   es:[di],ah; update masked pixels in buffer
        inc  di
        dec  cx

; use fast 8086 instruction to draw remainder of line

CycleLine1143:
        rep  stosb     ; update all pixels in the line (can not use stosw)

; set pixels in the rightmost byte of the line

CycleLine1144:
        and  al,dl     ; AL = masked pixels for last byte
        not  dl
        and  es:[di],dl; zero masked pixels in buffer
        or   es:[di],al; update masked pixels in buffer
        jmp  CycleLine11Exit

; Routine for dy <= dx

LoSlopeCycleLine11:

CycleLine1110:
        mov  ah,es:[bx]     ; AH = byte from video buffer
CycleLine1111:
        and  ah,dh          ; zero pixel value at current bit offset
        or   ah,dl          ; set pixel value in btye
        ror  dl,1           ; rotate pixel value
        ror  dh,1           ; rotate bit mask
        jnc  CycleLine1114       ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or   di,di          ; test sign of d
        jns  CycleLine1112       ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine1111
        mov  es:[bx],ah     ; store remaining pixel in buffer
        jmp  short CycleLine11Exit
CycleLine1112:
        add  di,VARincr2    ; d = d + incr2
        mov  es:[bx],ah     ; update buffer
        add  bx,si          ; increment y
        loop CycleLine1110
        jmp  short CycleLine11Exit

; bit mask shifted out

CycleLine1114:
        mov  es:[bx],ah
        inc  bx             ; bx = offset of next byte
        or   di,di          ; test sign of d
        jns  CycleLine1115       ; jump if non negative
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine1110
        jmp  short CycleLine11Exit
CycleLine1115:
        add  di,VARincr2    ; d = d + incr2
        add  bx,si          ; increment y
        loop CycleLine1110
        jmp  short CycleLine11Exit

; routine for dy > dx

HiSlopeCycleLine11:
CycleLine1121:
        and  es:[bx],dh     ; zero pixel value in video buffer
        or   es:[bx],dl     ; set pixel value in byte
        add  bx,si          ; increment y
CycleLine1122:
        or   di,di          ; test sign of d
        jns  CycleLine1123       ; jump if d >= 0
        add  di,VARincr1    ; d = d + incr1
        loop CycleLine1121
        jmp  short CycleLine11Exit
CycleLine1123:
        add  di,VARincr2    ; d = d + incr2
        ror  dl,1           ; rotate pixel value
        ror  dh,1           ; rotate bit mask
        cmc                 ; cf set if bit mask not rotated to leftmost pixel
        adc  bx,0           ; bx = offset of next byte
        loop CycleLine1121
CycleLine11Exit:
        pop  di
        pop  si
        leave
        ret
_CycleLine11 endp
; 

