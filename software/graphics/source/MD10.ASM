comment ~
================================================================================
   
 (C) 1993 FinchWare

 Module : md10.asm

 Description :
    Contains mode 10 graphics routines.

        mode resolution     colors    adapter
        d    - 320 x 200    16        EGA/VGA
        e    - 640 x 200    16        EGA/VGA
        10   - 640 x 350    16        EGA/VGA
        12   - 640 x 480    16        VGA

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

begin:
        .code

        jmp ErrorOut
        
        align 2
;-------------------------------------------------------------------
;    This area is laid out according to the fgs graphics structure.
;-------------------------------------------------------------------
_fgsv   label   fgs
        dw      ?           ; pointer to video state save area
        dw      10          ; video mode
        dw      ?           ; mode index
        dw      640         ; MaxX - device physical characteristics
        dw      350         ; MaxY
        dw      16          ; MaxColor
        dw      ?           ; command
        dw      ?           ; Drawing mode (AND, OR, XOR, COPY, ...)
        dw      ?           ; filling mode
        dw      PointCopy   ; pointer to point updating code
        dw      GetPoint10  ; Point getting routine
        dw      Point10     ; point plotting routine
        dw      Line10      ; line drawing routine
        dw      ?           ; horizontal line drawing routine
        dw      ?           ; left scan routine
        dw      ?           ; right scan routine
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
        dw      349         ; bottom

        dw      PointCopy
        dw      PointXor
        dw      PointOr
        dw      PointAnd

Width80 dw      80          ; constant for point addressing

comment ~
================================================================================
   
 (C) FinchWare

 Module : 

 Description :
    Calculates the address of a point in the video buffer in mode10

 Parameters :
    bx - x coordinate
    ax - y coordinate

 Registers Affected :

 Returns :

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
PointAddr10  proc near
        mov es,word ptr _fgsv.fgsVScreen   ; Set es to point to virtual screen
        mov cl,byte ptr _fgsv.fgsMaxX+1    ; Get high order byte of max X
        add cl,2   ; 4 if 640, 3 if 320
        shl ax,cl  ;  * 8 or 16
        mov cx,ax
        shl ax,2   ; * 32 or 64)
        add ax,cx  ; *(32+8) or (64 + 16)
        mov cl,bl ; pixel address calculation
        and cl,7
        xor cl,7
        shr bx,3  ;   Calculate byte in row by dividing pixel number
        add bx,ax ; by eight and adding in start of row.
        mov ah,1  ; Set up pixel mask
        ret
PointAddr10  endp
; 
comment ~
================================================================================
   
 (C) FinchWare

 Module : GetPoint10

 Description :
    Handles getting of points for modes:

        mode resolution     colors    adapter
        d    - 320 x 200    16        EGA/VGA
        e    - 640 x 200    16        EGA/VGA
        10   - 640 x 350    16        EGA/VGA
        12   - 640 x 480    16        VGA
        
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
        public    _GetPoint10
_GetPoint10  proc near
        enter 0,0
        push  si          ; This register is used by C compiler !!!
        mov   ax,ARGy1
        mov   bx,ARGx1
        call  PointAddr10
        shl   ah,cl
        mov   ch,ah
        mov   si,bx
        xor   bl,bl          ; accumulator for pixel value
        mov   ax,304h        ; ah = bit plane, al = read map select register
        mov   dx,3ceh        ; graphics controller port address
GetPoint101:
        out   dx,ax          ; select bit plane
        mov   bh,es:[si]     ; read byte
        and   bh,ch          ; select bit
        neg   bh             ; bh bit 7 = 1 if masked bit = 1
        rol   bx,1           ; bit 0 of bl = next bit of pixel value
        dec   ah             ; ah = next bit plane
        jge   GetPoint101
        mov   al,bl
        cbw                  ; return value in ax
        pop   si
        leave
        ret
_GetPoint10 endp
; 
comment ~
================================================================================
   
 (C) FinchWare

 Module : GetPoint10 - 64K EGA

 Description :
    Handles getting of points for modes
        mode resolution     colors    adapter
        d    - 320 x 200    16        EGA/VGA
        e    - 640 x 200    16        EGA/VGA
        f    - 640 x 350    mono (4)  EGA/VGA
        10   - 640 x 350    16        EGA/VGA
        12   - 640 x 480    16        VGA
        
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
        public    _GetPoint10_64k
_GetPoint10_64k   proc near
        enter 0,0
        push  si
        mov   ax,ARGy1
        mov   bx,ARGx1
        call  PointAddr10
        shl   ah,cl
        mov   ch,ah
        mov   ah,bl          ; ah = low order byte of address
        mov   si,bx
        and   ax,100h        ; al = 0;
        xor   bl,bl          ; accumulator for pixel value
        add   ax,204h        ; ah = bit plane (2 or 3) al = read map select register
        mov   dx,3ceh        ; graphics controller port address
GetPoint10_64k1:
        out   dx,ax          ; select bit plane
        mov   bh,es:[si]     ; read byte
        and   bh,ch          ; select bit
        neg   bh             ; bh bit 7 = 1 if masked bit = 1
        rol   bx,1           ; bit 0 of bl = next bit of pixel value
        dec   ah             ; ah = next bit plane
        jge   GetPoint10_64k1
        mov   al,bl
        cbw                 ; return value in ax
        pop   si
        leave
        ret
_GetPoint10_64k   endp
; 
comment ~
================================================================================
   
 (C) FinchWare

 Module : Point10

 Description :
    Handles plotting of points for modes
        mode resolution     colors    adapter
        d    - 320 x 200    16        EGA/VGA
        e    - 640 x 200    16        EGA/VGA
        f    - 640 x 350    mono (4)  EGA/VGA
        10   - 640 x 350    16        EGA/VGA
        12   - 640 x 480    16        VGA

???     5d   - 640 x 480    256       VGA (2 consecutive pixels must be
                                          written 1280 x 480, 16 color x 2)

    Uses write mode 2 of EGA board

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
        public    Point10
Point10    proc near
        enter 0,0
        mov ax,ARGy1
        mov bx,ARGx1
        call PointAddr10
        ;---------------------------------------
        ; Set graphics controller mode register
        ;---------------------------------------
        shl ah,cl
        mov dx,3ceh   ; graphics controller port address
        mov al,8      ; al = bit mask register number
        out dx,ax     ; ah = bit mask (set in PointAddr10)
        mov ax,205h   ; al = mode register number
        out dx,ax     ; ah = Write mode 2 (bits 0,1) read mode 0 (bit 3)
        ;---------------------------------------------
        ; set data rotate/function select register
        ; ah = read-modify-write bits
        ; al = data rotate / function select register
        ;---------------------------------------------
        mov al,3
        mov ah,_fgsv.fgsDrawMode
        out dx,ax
        mov ah,byte ptr _fgsv.fgsColor
        xchg es:[bx],ah     ; read into latches then write cpu data
        ;---------------------------------
        ; restore default register values
        ;---------------------------------
        mov ax,0ff08h ; Default bit mask
        out dx,ax
        mov ax,5      ; Default mode register
        out dx,ax
        mov ax,3      ; Default function select
        out dx,ax
        leave
        ret
Point10    endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Line10

 Description :
    Draws line in graphics mode 10.
    The line routines always draw from left to right.

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
        public    Line10
Line10 proc      near
        enter 12,0
        push si
        push di

; configure graphics controller

        mov  dx,3ceh        ; dx = graphics controller port address
        mov  ah,byte ptr _fgsv.fgsColor; ARGn AH = pixel value (ARGn)
        xor  al,al
        out  dx,ax
        mov  ax,0f01h       ; AH = 1111b (bit plane mask for enable set/reset
        out  dx,ax
        mov  ah,0           ; bits 3,4 of AH = function
        mov  al,3           ; AL = data rotate / function select reg #
        out  dx,ax

; check for vertical line

        mov  si,_fgsv.fgsMaxX; Width80     ; increment for video buffer
        shr si,3            ; divide by 8
        mov  cx,ARGx2       ; cx = x2 - x1
        sub  cx,ARGx1
        jz   VLine10

; force x1 < x2

        jns  Line101        ; jump if x2 > x1
        neg  cx             ; cx = x1-x2
        mov  bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov  ARGx2,bx
        mov  bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov  ARGy2,bx

; dy = abs(y2-y1)

Line101:
        mov  bx,ARGy2
        sub  bx,ARGy1  ; bx = y2 - y1
        jz   HLine10   ; jump if horizontal line
        jns  Line103

        neg  bx        ; bx = y1 - y2
        neg  si        ; negate y increment

; select appropriate routine for slope of line

Line103:
        mov  VARvertincr,si  ; save vertical increment
        mov  VARroutine,offset LoSlopeLine10
        cmp  bx,cx
        jle  Line104
        mov  VARroutine,offset HiSlopeLine10
        xchg bx,cx           ; exchange dy and dx

; calculate initial decision variable and increments

Line104:
        shl  bx,1           ; bx = 2 * dy
        mov  VARincr1,bx    ; incr1 = 2 * dy
        sub  bx,cx
        mov  si,bx          ; SI = d = 2 * dy - dx
        sub  bx,cx
        mov  VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve # pixels to draw
        mov  ax,ARGy1  ; calculate address of first point
        mov  bx,ARGx1
        call PointAddr10
        mov  di,bx     ; es:di -> buffer
        shl  ah,cl     ; AH = bit mask in proper position
        mov  bl,ah     ; ah,bl = bit mask
        mov  al,8
        pop  cx
        inc  cx        ; CX = number of pixels to draw
        jmp   VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VLine10:
        mov  ax,ARGy1  ; AX = y1
        mov  bx,ARGy2  ; BX = y2
        mov  cx,bx
        sub  cx,ax     ; CX = dy
        jge  Line1031
        neg  cx        ; force dy >= 0
        mov  ax,bx     ; AX = y2

Line1031:
        inc  cx        ; CX = # of pixels to draw
        mov  bx,ARGx1  ; BX = x
        push cx        ; preserve
        call PointAddr10

; set up graphics controller

        shl  ah,cl     ; AH = bit mask in proper position
        mov  al,8      ; AL = Bit mask register number
        out  dx,ax
        pop  cx

; Draw the line

Line1032:
        or   es:[bx],al     ; set pixel values in buffer
        add  bx,si
        loop Line1032
        jmp  Line10Exit
;------------------------------
; Routine for horizontal lines
;------------------------------
HLine10:
        mov ax,ARGy1
        mov bx,ARGx1
        call PointAddr10
        mov di,bx     ; es:di -> buffer
        mov dx,0ffffh
;        not dh        ; DH = unshifted bit mask for leftmost byte
        shl dh,cl     ; DH = reverse bit mask for first byte
        not dh        ; DH = bit mask for first byte
        mov cx,ARGx2
        and cl,7
        xor cl,7      ; CL = number of bits to shift left
;        mov dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov ax,ARGx2
        mov bx,ARGx1
        mov cl,3      ; number of bits to shift to turn pixels into bytes
        shr ax,cl
        shr bx,cl
        mov cx,ax
        sub cx,bx     ; CX = number of bytes in line - 1
;
        mov bx,dx
        mov dx,3ceh   ; DX = graphics controller port
        mov al,8      ; AL = bit mask register number
        ;---------------------------------------------
        ; make video buffer addressable through ds:si
        ;---------------------------------------------
        push ds
        push es
        pop ds
        mov si,di
        ;-----------------------------------------
        ; set pixels in leftmost byte of the line
        ;-----------------------------------------
        or bh,bh
        js Line1043   ; jump if byte aligned (x1 is leftmost pixel in byte)
        or cx,cx
        jnz Line1042  ; jump if more than one byte in line
        and bl,bh     ; bit mask for the line
        mov ah,11111111b
        jmp short Line1044
Line1042:
        mov  ah,bh     ; AH = masked pixel bits
        out  dx,ax
        movsb          ; update bit planes (read then write same address)
        dec  cx        ; first byte done
        ;-----------------------------------------------------
        ; use fast 8086 instruction to draw remainder of line
        ;-----------------------------------------------------
Line1043:
        add si,cx       ; update source for last byte
        mov ah,11111111b; AH = pixel (bit) mask
        out dx,ax       ; update bit mask register
        rep stosb       ; update all pixels in the line (can not use stosw)
                        ; read not necessary since all pixels are updated
        ;----------------------------------------------
        ; set pixels in the rightmost byte of the line
        ;----------------------------------------------
Line1044:
;        and  al,bl      ; AL = masked pixels for last byte
        and   ah,bl       ; ah was set to 11111111b above
        out  dx,ax
        movsb
        pop  ds
        jmp  Line10Exit

;-------------------------
; Routine for dy <= dx
;-------------------------
LoSlopeLine10:

Line1010:
        mov  ah,bl           ; AH = bit mask for next pixel
Line1011:
        or    ah,bl          ; zero pixel value at current bit offset
        ror  bl,1            ; rotate pixel value
        jc   Line1014        ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or   si,si           ; test sign of d
        jns  Line1012        ; jump if d >= 0
        add  si,VARincr1     ; d = d + incr1
        loop Line1011

; Update any pixels that may be remaining

        out  dx,ax           ; update bit mask register
        or   es:[di],al      ; set remaining pixels
        jmp  short Line10Exit

Line1012:
        add  si,VARincr2     ; d = d + incr2
        out  dx,ax
        or   es:[di],al      ; update bit planes
        add  di,VARvertincr  ; change y
        loop Line1010
        jmp  short Line10Exit

; when the rightmost bit of the intermediate (ah) register has been used
; update the mask register and bit planes. increment to the next byte in
; display memory bit. mask shifted out

Line1014:
        out  dx,ax          ; update bit mask register
        or   es:[di],al     ; update bit planes (or causes read then write)
        inc  di
        or   si,si          ; test sign of d   (time to change y?)
        jns  Line1015       ; jump if non negative
        add  si,VARincr1    ; d = d + incr1
        xor   ah,ah       ; clear ah
        loop Line1010
        jmp  short Line10Exit   ; no pixels left to update

Line1015:
        add  si,VARincr2    ; d = d + incr2
        add  di,VARvertincr ; increment y
        loop Line1010
        jmp  short Line10Exit   ; no pixels left to update
;---------------------
; routine for dy > dx
;---------------------

HiSlopeLine10:
        mov  bx,VARvertincr ; BX = y increment
Line1021:
        out  dx,ax
        or   es:[di],al     ; update bit planes
        add  di,bx          ; change y
Line1022:
        or   si,si          ; test sign of d
        jns  Line1023       ; jump if d >= 0
        add  si,VARincr1    ; d = d + incr1
        loop Line1021
        jmp  short Line10Exit
Line1023:
        add  si,VARincr2    ; d = d + incr2
        ror  ah,1           ; rotate pixel value
        adc  di,0           ; increment di (change x) when mask rotated to leftmost position
        loop Line1021

; restore default graphics controller and return to caller

Line10Exit:
        xor  ax,ax     ; restore set / reset register
        out  dx,ax
        inc  ax        ; restore enable set/reset register
        out  dx,ax
        mov  al,3      ; data rotate function select register
        out  dx,ax
        mov  ax,0ff08h ; restore bit mask register
        out  dx,ax
        pop  di
        pop  si
        leave
        ret
Line10 endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : _CycleLine10

 Description :
    Draws line in graphics mode 10.
    The line routines always draw from left to right.

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
        public    _CycleLine10
_CycleLine10 proc      near
        enter 12,0
        push si
        push di

; configure graphics controller

        mov  dx,3ceh        ; dx = graphics controller port address
        call GetCycleColor
        xchg ah,al
;        mov  ah,byte ptr _fgsv.fgsColor; ARGn AH = pixel value (ARGn)
;        xor  al,al
        out  dx,ax
        mov  ax,0f01h       ; AH = 1111b (bit plane mask for enable set/reset
        out  dx,ax
        mov  ah,0           ; bits 3,4 of AH = function
        mov  al,3           ; AL = data rotate / function select reg #
        out  dx,ax

; check for vertical line

        mov  si,_fgsv.fgsMaxX; Width80     ; increment for video buffer
        shr si,3            ; divide by 8
;        mov  si,Width80     ; increment for video buffer
        mov  cx,ARGx2       ; cx = x2 - x1
        sub  cx,ARGx1
        jz   VCycleLine10

; force x1 < x2

        jns  CycleLine101        ; jump if x2 > x1
        neg  cx             ; cx = x1-x2
        mov  bx,ARGx2       ; exchange x1 and x2
        xchg bx,ARGx1
        mov  ARGx2,bx
        mov  bx,ARGy2       ; exchange y1 and y2
        xchg bx,ARGy1
        mov  ARGy2,bx

; dy = abs(y2-y1)

CycleLine101:
        mov  bx,ARGy2
        sub  bx,ARGy1  ; bx = y2 - y1
        jz   HCycleLine10   ; jump if horizontal line
        jns  CycleLine103

        neg  bx        ; bx = y1 - y2
        neg  si        ; negate y increment

; select appropriate routine for slope of line

CycleLine103:
        mov  VARvertincr,si  ; save vertical increment
        mov  VARroutine,offset LoSlopeCycleLine10
        cmp  bx,cx
        jle  CycleLine104
        mov  VARroutine,offset HiSlopeCycleLine10
        xchg bx,cx           ; exchange dy and dx

; calculate initial decision variable and increments

CycleLine104:
        shl  bx,1           ; bx = 2 * dy
        mov  VARincr1,bx    ; incr1 = 2 * dy
        sub  bx,cx
        mov  si,bx          ; SI = d = 2 * dy - dx
        sub  bx,cx
        mov  VARincr2,bx    ; incr2 = 2 * (dy - dx)

; calculate first pixel address

        push cx        ; preserve # pixels to draw
        mov  ax,ARGy1  ; calculate address of first point
        mov  bx,ARGx1
        call PointAddr10
        mov  di,bx     ; es:di -> buffer
        shl  ah,cl     ; AH = bit mask in proper position
        mov  bl,ah     ; ah,bl = bit mask
        mov  al,8
        pop  cx
        inc  cx        ; CX = number of pixels to draw
        jmp   VARroutine
;---------------------------
; Routine for vertical line
;---------------------------
VCycleLine10:
        mov  ax,ARGy1  ; AX = y1
        mov  bx,ARGy2  ; BX = y2
        mov  cx,bx
        sub  cx,ax     ; CX = dy
        jge  CycleLine1031
        neg  cx        ; force dy >= 0
        mov  ax,bx     ; AX = y2

CycleLine1031:
        inc  cx        ; CX = # of pixels to draw
        mov  bx,ARGx1  ; BX = x
        push cx        ; preserve
        call PointAddr10

; set up graphics controller

        shl  ah,cl     ; AH = bit mask in proper position
        mov  al,8      ; AL = Bit mask register number
        out  dx,ax
        pop  cx

; Draw the line

CycleLine1032:
        or   es:[bx],al     ; set pixel values in buffer
        add  bx,si
        loop CycleLine1032
        jmp  CycleLine10Exit
;------------------------------
; Routine for horizontal lines
;------------------------------
HCycleLine10:
        mov  ax,ARGy1
        mov  bx,ARGx1
        call PointAddr10
        mov  di,bx     ; es:di -> buffer
        mov  dx,0ffffh
;        not  dh        ; DH = unshifted bit mask for leftmost byte
        shl  dh,cl     ; DH = reverse bit mask for first byte
        not  dh        ; DH = bit mask for first byte
        mov  cx,ARGx2
        and  cl,7
        xor  cl,7      ; CL = number of bits to shift left
;        mov  dl,0ffh   ; DL = unshifted bit mask for rightmost byte
        shl  dl,cl     ; DL = bit mask for last byte

; Determine byte offset for first and last pixel in line

        mov  ax,ARGx2
        mov  bx,ARGx1
        mov  cl,3      ; number of bits to shift to turn pixels into bytes
        shr  ax,cl
        shr  bx,cl
        mov  cx,ax
        sub  cx,bx     ; CX = number of bytes in line - 1

;
        mov  bx,dx
        mov  dx,3ceh   ; DX = graphics controller port
        mov  al,8      ; AL = bit mask register number

; make video buffer addressable through ds:si

        push  ds
        push  es
        pop   ds
        mov   si,di

; set pixels in leftmost byte of the line

        or   bh,bh
        js   CycleLine1043  ; jump if byte aligned (x1 is leftmost pixel in byte)
        or   cx,cx
        jnz  CycleLine1042  ; jump if more than one byte in line
        and  bl,bh     ; bit mask for the line
        mov   ah,11111111b
        jmp   short CycleLine1044

CycleLine1042:
        mov  ah,bh     ; AH = masked pixel bits
        out  dx,ax
        movsb          ; update bit planes (read then write same address)
        dec  cx        ; first byte done

; use fast 8086 instruction to draw remainder of line

CycleLine1043:
        add   si,cx       ; update source for last byte
        mov   ah,11111111b; AH = pixel (bit) mask
        out   dx,ax       ; update bit mask register
        rep   stosb       ; update all pixels in the line (can not use stosw)
                          ; read not neccessary since all pixels are updated
; set pixels in the rightmost byte of the line

CycleLine1044:
;        and  al,bl      ; AL = masked pixels for last byte
        and   ah,bl       ; ah was set to 11111111b above
        out  dx,ax
        movsb
        pop  ds
        jmp  CycleLine10Exit

;-------------------------
; Routine for dy <= dx
;-------------------------
LoSlopeCycleLine10:

CycleLine1010:
        mov  ah,bl           ; AH = bit mask for next pixel
CycleLine1011:
        or    ah,bl          ; zero pixel value at current bit offset
        ror  bl,1            ; rotate pixel value
        jc   CycleLine1014        ; jump if bit mask rotated to leftmost pixel

; bit mask not shifted out

        or   si,si           ; test sign of d
        jns  CycleLine1012        ; jump if d >= 0
        add  si,VARincr1     ; d = d + incr1
        loop CycleLine1011

; Update any pixels that may be remaining

        out  dx,ax           ; update bit mask register
        or   es:[di],al      ; set remaining pixels
        jmp  short CycleLine10Exit

CycleLine1012:
        add  si,VARincr2     ; d = d + incr2
        out  dx,ax
        or   es:[di],al      ; update bit planes
        add  di,VARvertincr  ; change y
        loop CycleLine1010
        jmp  short CycleLine10Exit

; when the rightmost bit of the intermediate (ah) register has been used
; update the mask register and bit planes. increment to the next byte in
; display memory bit. mask shifted out

CycleLine1014:
        out  dx,ax          ; update bit mask register
        or   es:[di],al     ; update bit planes (or causes read then write)
        inc  di
        or   si,si          ; test sign of d   (time to change y?)
        jns  CycleLine1015       ; jump if non negative
        add  si,VARincr1    ; d = d + incr1
        xor   ah,ah       ; clear ah
        loop CycleLine1010
        jmp  short CycleLine10Exit   ; no pixels left to update

CycleLine1015:
        add  si,VARincr2    ; d = d + incr2
        add  di,VARvertincr ; increment y
        loop CycleLine1010
        jmp  short CycleLine10Exit   ; no pixels left to update
;---------------------
; routine for dy > dx
;---------------------

HiSlopeCycleLine10:
        mov  bx,VARvertincr ; BX = y increment
CycleLine1021:
        out  dx,ax
        or   es:[di],al     ; update bit planes
        add  di,bx          ; change y
CycleLine1022:
        or   si,si          ; test sign of d
        jns  CycleLine1023       ; jump if d >= 0
        add  si,VARincr1    ; d = d + incr1
        loop CycleLine1021
        jmp  short CycleLine10Exit
CycleLine1023:
        add  si,VARincr2    ; d = d + incr2
        ror  ah,1           ; rotate pixel value
        adc  di,0           ; increment di (change x) when mask rotated to leftmost position
        loop CycleLine1021

; restore default graphics controller and return to caller

CycleLine10Exit:
        xor  ax,ax     ; restore set / reset register
        out  dx,ax
        inc  ax        ; restore enable set/reset register
        out  dx,ax
        mov  al,3      ; data rotate function select register
        out  dx,ax
        mov  ax,0ff08h ; restore bit mask register
        out  dx,ax
        pop  di
        pop  si
        leave
        ret
_CycleLine10 endp
; 
comment ~
================================================================================
   
 (C) FinchWare

 Module : _Ellipse10

 Description :
    Draws ellipse in modes native EGA/VGA graphics modes d,e,f,10,11

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
        public    _Ellipse10
_Ellipse10        proc near
        enter 46,0
        push si
        push di

; set graphics controller mode registers

        mov  dx,3ceh   ; graphics controller register
        mov  ax,0005   ; write mode 0 (AH bits 0,1), read mode 0 (AH bit 4)
        out  dx,ax
        mov  ah,ARGn   ; AH = pixel value
        mov  al,0
        out  dx,ax
        mov  ax,0f01h  ; AH = enable set/reset register (all planes)
        out  dx,ax

; initial constants

        mov  ax,ARGa   ; calculate a^2
        mul  ax
        mov  Asquared,ax
        mov  Asquared+2,dx
        shl  ax,1      ; 2a^2
        rcl  dx,1
        mov  TwoAsquared,ax
        mov  TwoAsquared+2,dx

        mov  ax,ARGb   ; b^2
        mul  ax
        mov  Bsquared,ax
        mov  Bsquared+2,dx
        shl  ax,1      ; 2b^2
        rcl  dx,1
        mov  TwoBsquared,ax
        mov  TwoBsquared+2,dx

; plot pixels until dy/dx = -1

; initial buffer address and bit mask

        mov  ax,Width80
        mul  ARGb
        mov  si,ax
        mov  di,ax

        mov  ax,ARGyc
        mov  bx,ARGxc
        call PointAddr10
        shl  ah,cl          ; AH = bit mask for first pixel
        mov  LMask,ah
        mov  RMask,ah

        add  si,bx          ; SI = offset of (0, b)
        mov  ULAddr,si
        mov  URAddr,si
        sub  bx,di          ; AX = offset of (0, -b)
        mov  LLAddr,bx
        mov  LRAddr,bx

; initial decision variables

        xor  ax,ax          ; dx = 0; dx = 0
        mov  VARdx,ax
        mov  VARdx+2,ax     
        mov  ax,TwoAsquared ; dy = 2a^2 * b
        mov  dx,TwoAsquared+2
        mov  cx,ARGb
        call LongMultiply   ; 32 by 16 multiply
        mov  VARdy,ax
        mov  VARdy+2,dx
        mov  ax,Asquared    ; DX:AX = Asquared / 4
        mov  dx,Asquared+2
        sar  dx,1           
        rcr  ax,1
        sar  dx,1
        rcr  ax,1
        add  ax,Bsquared    ; DX:AX = Bsquared + Asquared / 4
        adc  dx,Bsquared+2
        mov  VARd,ax
        mov  VARd+2,dx
        mov  ax,Asquared
        mov  dx,Asquared+2
        mov  cx,ARGb
        call LongMultiply   ; DX:AX = Asquared * b
        sub  VARd,ax
        sbb  VARd+2,dx      ; d = Bsquared - Asquared * b + Asquared / 4

; loop until dy/dx >= -1

        mov  bx,ARGb        ; BX = inital y coordinate
        xor  cx,cx
Ellipse1010:
        mov  ax,VARdx
        mov  dx,VARdx+2
        sub  ax,VARdy
        sbb  dx,VARdy+2     ; DX:AX = dx-dy
        jns  Ellipse1020
        call Set4Pixels
        mov  cx,1
        cmp  VARd+2,0
        js   Ellipse1011    ; jump if d < 0
        mov  ch,1           ; increment in y direction
        dec  bx             ; decrement curreent y coordinate
        mov  ax,VARdy
        mov  dx,VARdy+2
        sub  ax,TwoAsquared
        sbb  dx,TwoAsquared+2    ; DX:AX = dy - TwoAsquared
        mov  VARdy,ax
        mov  VARdy+2,dx     ; dy -= TwoAsquared
        sub  VARd,ax
        sbb  VARd+2,dx
Ellipse1011:
        mov  ax,VARdx
        mov  dx,VARdx+2
        add  ax,TwoBsquared
        adc  dx,TwoBsquared+2    ; DX:AX = dx + TwoBsqaured
        mov  VARdx,ax
        mov  VARdx+2,dx          ; dx += TwoBsquared
        add  ax,Bsquared
        adc  dx,Bsquared+2
        add  VARd,ax
        adc  VARd+2,dx      ; d += dx + Bsquared
        jmp  Ellipse1010

; plot pixels from current (x,y) until y < 0

Ellipse1020:
        push bx
        push cx
        mov  ax,Asquared
        mov  dx,Asquared+2
        sub  ax,Bsquared
        sbb  dx,Bsquared+2  ; DX:AX = Asquared - Bsquared
        mov  bx,ax
        mov  cx,dx          ; CX:BX = (Asquared - Bsquared)
        sar  dx,1      
        rcr  ax,1
        add  ax,bx
        adc  dx,cx          ; DX:AX = 3*(Asquared-Bsquared)/2
        sub  ax,VARdx
        sbb  dx,VARdx+2
        sub  ax,VARdy
        sbb  dx,VARdy+2     ; DX:AX = 3*(Asquared-Bsquared)/2 - (dx+dy)
        sar  dx,1
        rcr  ax,1           ; DX:AX = (3*(Asquared-Bsquared)/2 - (dx+dy))/2
        add  VARd,ax
        adc  VARd+2,dx      ; update d

; loop until y < 0

        pop  cx
        pop  bx

Ellipse1021:
        call Set4Pixels
        mov  cx,100h   ; ch = 1 y increment cl 0 x increment
        cmp  VARd+2,0
        jns  Ellipse1022
        mov  cl,1
        mov  ax,VARdx
        mov  dx,VARdx+2
        add  ax,TwoBsquared
        adc  dx,TwoBsquared+2    ; DX:AX = dx + TwoBsquared
        mov  VARdx,ax
        mov  VARdx+2,dx          ; dx += TwoBsquared
        add  VARd,ax
        adc  VARd+2,dx      ; d += dx
Ellipse1022:
        mov  ax,VARdy
        mov  dx,VARdy+2
        sub  ax,TwoAsquared
        sbb  dx,TwoAsquared+2    ; DX:AX = dy - TwoAsquared
        mov  VARdy,ax
        mov  VARdy+2,dx     ; dy -= TwoAsquared
        sub  ax,Asquared
        sbb  dx,Asquared+2  ; DX:AX = dy - Asquared
        sub  VARd,ax
        sbb  VARd+2,dx      ; d += Asquared - dy
        dec  bx             ; decrement y
        jns  Ellipse1021    ; loop if y >= 0

; restore default graphics controller registers

Ellipse10Exit:
        mov  dx,3ceh   ; DX = graphics controller register
        mov  ax,0ff08h ; default bit mask
        out  dx,ax
        mov  ax,3      ; default function select
        out  dx,ax
        mov  ax,1      ; default enable set/reset
        out  dx,ax
        pop  di
        pop  si
        leave
        ret
_Ellipse10   endp
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

        public    _ScanRight10
_ScanRight10 proc near
        enter 0,0
        push di
        push si

; pixel address of (0,y)

        mov  ax,ARGy
        xor  bx,bx
        call PointAddr10
        mov  di,bx

; offset of x in row

        mov  ax,ARGx
        mov  si,ax
        mov  cl,3
        shr  si,cl
        add  di,si     ; DI = offset of x in buffer

; bit mask for the first byte to scan

        mov  cl,al
        and  cl,7
        mov  ch,0ffh
        shr  ch,cl     ; ch = bit mask for first scanned byte

; configure graphics controller

        mov  dx,3ceh
        mov  ah,_BorderValue     ; pixel value for color compare reg
        mov  al,2
        out  dx,ax
        mov  ax,805h
        out  dx,ax
        mov  ax,0f07h  ; AH = 00001111b (color compare value)
        out  dx,ax     ; AL = color compare reg number

; inspect first byte for border pixels

        mov  al,es:[di]
        inc  di
        and  al,ch
        jnz  ScanRight101

; scan remainder of line for border pixels

        mov  cx,Width80
        sub  cx,si

        dec  cx
        cld
        repe scasb     ; scan until non zero byte read (ie border pixel found)

; compute x value of border pixel

        mov  al,es:[di-1]
ScanRight101:
        sub  di,bx
        mov  cl,3
        shl  di,cl
        mov  cx,8
ScanRight102:
        shl  al,1
        jc   ScanRight103
        loop ScanRight102
ScanRight103:
        sub  di,cx     ; di = x coordinate of border pixel

; restore default graphics controller state

        mov  ax,2      ; ah = 0; default color compare
        out  dx,ax
        mov  al,5
        out  dx,ax
        mov  ax,di
        pop  si
        pop  di
        leave
        ret
_ScanRight10 endp
~; 
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

         ************ incomplete

================================================================================
~
        public    _ScanLeft10
_ScanLeft10 proc near
        enter 0,0
        push di
        push si

; pixel address of (0,y)

        mov  ax,ARGy
        xor  bx,bx
        call PointAddr10
        mov  di,bx

; offset of x in row

        mov  ax,ARGx
        mov  si,ax
        mov  cl,3
        shr  si,cl
        add  di,si     ; DI = offset of x in buffer

; bit mask for the first byte to scan

        mov  cl,al
        and  cl,7
        xor  cl,7
        mov  ch,0ffh
        shl  ch,cl     ; ch = bit mask for first scanned byte

; configure graphics controller

        mov  dx,3ceh
        mov  ah,byte ptr _fgsv.fgsBorderColor   ; pixel value for color compare reg
        mov  al,2
        out  dx,ax
        mov  ax,805h
        out  dx,ax
        mov  ax,0f07h  ; AH = 00001111b (color compare value)
        out  dx,ax     ; AL = color compare reg number

; inspect first byte for border pixels

        mov  al,es:[di]
        dec  di
        and  al,ch
        jnz  ScanLeft101

; scan remainder of line for border pixels

        mov  cx,Width80
        sub  cx,si

        dec  cx
        std
        repe scasb     ; scan until non zero byte read (ie border pixel found)
        cld

; compute x value of border pixel

        mov  al,es:[di+1]
ScanLeft101:
        sub  di,bx
        mov  cl,3
        shl  di,cl
        mov  cx,8
ScanLeft102:
        shr  al,1
        jc   ScanLeft103
        loop ScanLeft102
ScanLeft103:
        sub  di,cx     ; di = x coordinate of border pixel

; restore default graphics controller state

        mov  ax,2      ; ah = 0; default color compare
        out  dx,ax
        mov  al,5
        out  dx,ax
        mov  ax,di
        pop  si
        pop  di
        leave
        ret
_ScanLeft10 endp
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
GetCycleColor   proc  near
        ret
GetCycleColor   endp
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
Msg1    db      '(C) 1993 FinchWare - Mode d,e,10,12 graphics driver.', 0dh, 0ah, 0

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
        end     begin
; 

