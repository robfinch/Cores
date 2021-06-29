        .386
;        .model  small

include fgs.ah

extrn   _fgsv:word
        .code
comment ~
================================================================================
   
 (C) 1992 FinchWare

 GetPoint4,6,11

 Description :
    Gets the value of a pixel in modes 4,5
        4    - 320 x 200    4         CGA/EGA/VGA/MCGA
        5    - 320 x 200    4         CGA/EGA/VGA/MCGA
        6    - 640 x 200    2         CGA/EGA/VGA
        11   - 640 x 480    2         MCGA/VGA

 Parameters :

 Registers Affected :
    AX,BX,CX,ES

 Returns :
    AX - value of pixel 0 to 3

 Changes
         Author      : R. Finch
         Date        : 92/
         Release     :
         Description : new module

================================================================================
~
GetPoint4   proc near
        mGetPoint mPointAddr4
GetPoint4   endp

GetPoint6   proc near
        mGetPoint PointAddr6
GetPoint6   endp

GetPoint11  proc near
        mGetPoint PointAddr10
GetPoint11  endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : 

 Description :
    Handles getting of points for modes:

        mode resolution     colors    adapter
        f    - 640 x 350    2         EGA/VGA

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
GetPointf   proc near
        enter   0,0
        push    si
        mov     ax,ARGy
        mov     bx,ARGx
        PointAddr10
        shl     ah,cl
        mov     ch,ah
        mov     si,bx
        sub     bl,bl
        mov     ax,204h
        mov     dx,3ceh
GetPointf1:
        out     dx,ax
        mov     bh,es:[si]
        and     bh,ch
        neg     bh
        rol     bx,1
        sub     ah,2
        jge     GetPointf1
        mov     al,bl
        cbw              ; ah = 0
        pop     si
        leave
        ret
GetPointf   endp
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
GetPoint10  proc near
        enter   0,0
        push    si          ; This register is used by C compiler !!!
        mov     ax,ARGy
        mov     bx,ARGx
        PointAddr10
        shl     ah,cl
        mov     ch,ah
        mov     si,bx
        sub     bl,bl       ; accumulator for pixel value
        mov     ax,304h     ; ah = bit plane, al = read map select register
        mov     dx,3ceh     ; graphics controller port address
GetPoint101:
        out     dx,ax       ; select bit plane
        mov     bh,es:[si]  ; read byte
        and     bh,ch       ; select bit
        neg     bh          ; bh bit 7 = 1 if masked bit = 1
        rol     bx,1        ; bit 0 of bl = next bit of pixel value
        dec     ah          ; ah = next bit plane
        jge     GetPoint101
        mov     al,bl
        cbw                 ; return value in ax
        pop     si
        leave
        ret
GetPoint10 endp
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
GetPoint10_64k   proc near
        enter   0,0
        push    si
        mov     ax,ARGy
        mov     bx,ARGx
        PointAddr10
        shl     ah,cl
        mov     ch,ah
        mov     ah,bl          ; ah = low order byte of address
        mov     si,bx
        sub     bl,bl          ; accumulator for pixel value
        and     ax,100h
        add     ax,204h        ; ah = bit plane (2 or 3) al = read map select register
        mov     dx,3ceh        ; graphics controller port address
GetPoint10_64k1:
        out     dx,ax          ; select bit plane
        mov     bh,es:[si]     ; read byte
        and     bh,ch          ; select bit
        neg     bh             ; bh bit 7 = 1 if masked bit = 1
        rol     bx,1           ; bit 0 of bl = next bit of pixel value
        dec     ah             ; ah = next bit plane
        jge     GetPoint10_64k1
        mov     al,bl
        cbw                    ; return value in ax
        pop     si
        leave
        ret
GetPoint10_64k   endp
; 
comment ~
================================================================================
   
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
GetPoint13  proc near
        enter   0,0
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr13
        mov     al,es:[bx]   ; Get memory byte.
        sub     ah,ah
        leave
        ret
GetPoint13  endp
; 
comment ~
================================================================================
 95/10/13   
 Module : _GetPoint10x

 Description :
    Handles getting of points for 256 color SuperVGA modes
       mode   resolution     colors  adapter
       100     640 x 400      256     SVGA
       101     640 x 480      256     SVGA
       103     800 x 600      256     SVGA
       105    1024 x 768      256     SVGA
       107    1280 x 1024     256     SVGA

 Parameters :
    (word) global variable _fgsv.fgsCursorX - x xoordinate of point
    (word) global variable _fgsv.fgsCursorY - y xoordinate of point
    (word) global variable _grVScreen - Segment address of screen area

 Registers Affected : AX,BX,ES

================================================================================
~
GetPoint10x  proc near
        enter   0,0
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr10x
        mov     al,es:[bx]   ; Get memory byte.
        sub     ah,ah
        leave
        ret
GetPoint10x  endp
;

        end
; 

