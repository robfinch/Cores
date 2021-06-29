comment ~
================================================================================
   
 (C) 1993 FinchWare

 Module : md13.asm

 Description :
    Contains mode 13 graphics routines.

        mode resolution     colors    adapter
        13   - 320 x 200    256       MCGA/VGA

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

begin:
        jmp ErrorOut
        
        align 2
;-------------------
;    Function table
;-------------------
_FuncTbl        label   dword
        dd      GetPoint
        dd      Point
        dd      HLine

_SuppTbl        label   dword
        dd      SHLine
        dd      LHLine
        dd      AHLine

        .org    32

MaxX    dw      320
MaxY    dw      200
Colors  dw      4
VSeg    dw      0b800h

;-------------------------------------------------------------------
;    This area is laid out according to the fgs graphics structure.
;-------------------------------------------------------------------
_fgsv   label   fgs
        dw      ?           ; pointer to video state save area
        dw      13          ; video mode
        dw      ?           ; mode index
        dw      320         ; device physical characteristics - MaxX
        dw      200         ; MaxY
        dw      256         ; MaxColor
        dw      ?           ; command
        dw      ?           ; Drawing mode (AND, OR, XOR, COPY, ...)
        dw      ?           ; filling mode
        dw      GetPoint13  ; Point getting routine
        dw      Point13     ; point plotting routine
        dw      Line13      ; line drawing routine
        dw      ?           ; horizontal line drawing routine
        dw      ?           ; left scan routine
;        dw      ?           ; right scan routine
        dw      0a000h      ; virtual screen segment
        dw      0a000h      ; real screen segment
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
        dw      319         ; right
        dw      199         ; bottom

Width80 dw      80          ; constant for point addressing

comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : _GetPoint13

 Description :
    Handles getting of points for modes
        mode resolution     colors    adapter
        13   - 320 x 200    256       MCGA/VGA

 Parameters :
    (word) global variable _fgsv.fgsCursorX - x xoordinate of point
    (word) global variable _fgsv.fgsCursorY - y xoordinate of point
    (word) global variable _grVScreen - Segment address of screen area

 Registers Affected : AX,BX,ES

 Changes
         Author      : R. Finch
         Date        : 92/01/25
         Release     :
         Description : new module

================================================================================
~
GetPoint        proc far
        enter   0,0
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr13
        mov     al,es:[bx]   ; Get memory byte.
        sub     ah,ah
        leave
        retf
GetPoint        endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Point13

 Description :
    Plots a point on the screen. Mode 13h 320 x 200, 256 color. (MCGA/VGA)
    Make sure the x,y co-ordinate is in range.
 Use y coordinate to calculate row memory address.

 Parameters :

 Registers Affected : AX,BX,ES

 Changes
         Author      : R. Finch
         Date        : 92/01/25
         Release     :
         Description : new module

================================================================================
~
Point   proc near
        enter   0,0
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr13
        mov     al,byte ptr _fgsv.fgsColor
        jmp     word ptr _fgsv.fgsPointPtr
        ;-----------------------------------------------------------------
        ;    Note the following operations cause a pixel read then write.
        ; This is necessary for pixel latching with display adapter.
        ;-----------------------------------------------------------------
PointCopy:
        xchg    es:[bx],al  ; cause pixel read then write
        leave
        ret
PointXor:
        xor     es:[bx],al
        leave
        ret
PointAnd:
        and     es:[bx],al
        leave
        ret
PointOr:
        or      es:[bx],al
        leave
        ret
Point   endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : HLine13

 Description :
    Draws horizontal line in mode 13 using area pattern.

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
AHLine proc    near
        enter   0,0
        push    di
        push    si
        mov     ax,ARGy1
        mov     si,ax
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     AHLine1
        neg     cx
        mov     bx,ARGx2 ; start at lower x
AHLine1:
        push    bx
        mPointAddr13      ; es:[bx] = first address
        inc     cx
        mov     di,bx    ; es:[di] = buffer address
        pop     bx       ; bx = x
AHLine2:
        mov     ax,si    ; ax = y
        call    _fgsv.fgsColorPtr
        xchg    di,bx
        sub     ah,ah
        call    _fgsv.fgsPointPtr ; perform COPY/AND/OR/XOR
        xchg    di,bx
        inc     di
        inc     bx
        loop    AHLine2
        pop     si
        pop     di
        leave
        ret
AHLine endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : SHLine13

 Description :
    Draws horizontal line in mode 13 using solid color.

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
SHLine13 proc    near
        enter   0,0
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     SHLine131
        neg     cx
        mov     bx,ARGx2 ; start at lower x
SHLine131:
        mPointAddr13      ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,bx    ; es:[di] = buffer address
        mov     dl,byte ptr _fgsv.fgsColor ; AL = color
SHLine132:
        mov     al,dl
        call    _fgsv.fgsPointPtr ; perform COPY/AND/OR/XOR
        inc     bx
        loop    SHLine132
;        rep     stosb
        pop     di
        leave
        ret
SHLine13 endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : LHLine13

 Description :
    Draws horizontal line in mode 13 using linear pattern.

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
LHLine proc    near
        enter   0,0
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     LHLine1
        neg     cx
        mov     bx,ARGx2 ; start at lower x
LHLine1:
        mPointAddr13     ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,word ptr _fgsv.fgsColor    ; get color table address
        mov     dl,byte ptr _fgsv.fgsPatHeight; get index to color
        mov     dh,byte ptr _fgsv.fgsPatWidth ; get max index
        cld
        sub     ah,ah
LHLine2:
        mov     al,dl
        xchg    bx,di
        xlat
        xchg    bx,di
        inc     dl
        cmp     dl,dh
        jb      LHLine3
        sub     dl,dl
LHLine3:
        call    _fgsv.fgsPointPtr ; perform COPY/AND/OR/XOR
        inc     bx
        loop    LHLine2
        mov     byte ptr _fgsv.fgsPatHeight,dl; save index to color
        pop     di
        leave
        ret
LHLine endp
        end     begin
; 

