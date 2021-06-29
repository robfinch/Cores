comment ~
================================================================================
   
 (C) 1996 FinchWare

 Module : 256.asm

 Description :
    Supports point drawing/getting and line drawing for the following
    modes:

        mode resolution     colors    adapter
        13     320 x 200      256     MCGA/VGA
       100     640 x 400      256     SVGA
       101     640 x 480      256     SVGA
       103     800 x 600      256     SVGA
       105    1024 x 768      256     SVGA
       107    1280 x 1024     256     SVGA

    Adapters
        SVGA - Super VGA
        
 Parameters :

 Registers Affected :

================================================================================
~
        .286
        .model small

include fgs.ah

extrn   _fgsv:word
; 
        .data
comment ~
================================================================================
 Description :
    Raster operation table
================================================================================
~
ROP256PointTbl label word
        dw      _R256Copy,      5
        dw      _R256And,       5
        dw      _R256Or,        5
        dw      _R256Xor,       5
        dw      _R256Black,     6
        dw      _R256White,     6
        dw      _R256NOP,       2
        dw      _R256Not,       5
        dw      _R256NotCopy,   7
        dw      _R256NotAnd,    8
        dw      _R256NotOr,     8
        dw      _R256NotXor,    8
        dw      _R256NotScrOr,  8
        dw      _R256NotScrAnd, 8
        dw      _R256ScrOrNot,  7
        dw      _R256ScrAndNot, 7

ROP256LineTbl label word
        dw      _R256Copy,      3
        dw      _R256And,       3
        dw      _R256Or,        3
        dw      _R256Xor,       3
        dw      _R256Black,     4
        dw      _R256White,     4
        dw      _R256NOP,       0
        dw      _R256Not,       3
        dw      _R256NotCopy,   5
        dw      _R256NotAnd,    6
        dw      _R256NotOr,     6
        dw      _R256NotXor,    6
        dw      _R256NotScrOr,  6
        dw      _R256NotScrAnd, 6
        dw      _R256ScrOrNot,  5
        dw      _R256ScrAndNot, 5

ROP13SHLineTbl label word
        dw      _R13SHCopy,     5
        dw      _R256And,       3
        dw      _R256Or,        3
        dw      _R256Xor,       3
        dw      _R13SHBlack,    7
        dw      _R13SHWhite,    7
        dw      _R256NOP,       0
        dw      _R256Not,       3
        dw      _R13SHNotCopy,  7
        dw      _R256NotAnd,    6
        dw      _R256NotOr,     6
        dw      _R256NotXor,    6
        dw      _R256NotScrOr,  6
        dw      _R256NotScrAnd, 6
        dw      _R256ScrOrNot,  5
        dw      _R256ScrAndNot, 5

        public ROP13Tbl
ROP13Tbl label word
        dw      Point13ROP, ROP256PointTbl, 8
        dw      SHLine13ROP, ROP13SHLineTbl, 7
        dw      AHLine13ROP, ROP256LineTbl, 6
        dw      LHLine13ROP, ROP256LineTbl, 6

        public ROP256Tbl
ROP256Tbl label word
        dw      Point256ROP, ROP256PointTbl, 8
        dw      SHLine256ROP, ROP256LineTbl, 6
        dw      AHLine256ROP, ROP256LineTbl, 6
        dw      LHLine256ROP, ROP256LineTbl, 6
; 
        .code
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
        public  GetPoint13
GetPoint13  proc near
        push    bp
        mov     bp,sp
        mov     ax,ARGy  ; bp + 6
        mov     bx,ARGx  ; bp + 4
        mPointAddr13
        mov     al,es:[bx]   ; Get memory byte.
        sub     ah,ah
        leave
        ret
GetPoint13  endp
; 
comment ~
================================================================================
   
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
        public  Point13
Point13 proc near
        push    bp
        mov     bp,sp
        mov     ax,ARGy  ; bp + 6
        mov     bx,ARGx  ; bp + 4
        mPointAddr13
        push    bx
        mov     bx,ARGx
        call    word ptr _fgsv.fgsColorPtr
        pop     bx
        sub     ah,ah
Point13ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        pop     bp ; just in case
        ret
Point13 endp
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
        public  AHLine13
AHLine13 proc    near
        push    bp
        mov     bp,sp
        push    di
        push    si
        mov     ax,ARGy1
        mov     si,ax
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     AHLine131
        neg     cx
        mov     bx,ARGx2 ; start at lower x
AHLine131:
        push    bx
        mPointAddr13     ; es:[bx] = first address
        inc     cx
        mov     di,bx    ; es:[di] = buffer address
        pop     bx       ; bx = x
AHLine132:
        mov     ax,si    ; ax = y
        call    word ptr _fgsv.fgsColorPtr
        xchg    di,bx
        sub     ah,ah
AHLine13ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        xchg    di,bx
        inc     di
        inc     bx
        loop    AHLine132
        pop     si
        pop     di
        leave
        ret
AHLine13 endp
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
        public  SHLine13
SHLine13 proc    near
        push    bp
        mov     bp,sp
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     SHLine131
        neg     cx
        mov     bx,ARGx2 ; start at lower x
SHLine131:
        mPointAddr13     ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,bx    ; es:[di] = buffer address
        mov     dl,byte ptr _fgsv.fgsColor ; DL = color
SHLine132:
        mov     al,dl
SHLine13ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        inc     bx
        loop    SHLine132
        pop     di
        pop     bp
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
        public  LHLine13
LHLine13 proc    near
        push    bp
        mov     bp,sp
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     LHLine131
        neg     cx
        mov     bx,ARGx2 ; start at lower x
LHLine131:
        mPointAddr13     ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,word ptr _fgsv.fgsColor ; get color table address
        mov     dl,byte ptr _fgsv.fgsPatHeight; get index to color
        mov     dh,byte ptr _fgsv.fgsPatWidth ; get max index
        cld
        sub     ah,ah
LHLine132:
        mov     al,dl
        xchg    bx,di
        xlatb
        xchg    bx,di
        inc     dl
        cmp     dl,dh
        jb      LHLine133
        sub     dl,dl
LHLine133:
LHLine13ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        inc     bx
        loop    LHLine132
        mov     byte ptr _fgsv.fgsPatHeight,dl; save index to color
        pop     di
        leave
        ret
LHLine13 endp
; 
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
        public  ClrScr13
ClrScr13        proc  far
        push    bp
        mov     bp,sp
        push    di
        sub     ax,ax  ; x = y = 0
        sub     bx,bx
        mPointAddr13
        mov     cx,0ffffh  ; do 64k words
        sub     al,al
        sub     di,di
        cld
        rep     stosb
        pop     di
        leave
        retf
ClrScr13        endp
; 
comment ~
================================================================================
 95/10/13   
 Module : _GetPoint256

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
        public  GetPoint256
GetPoint256  proc near
        enter   0,0
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr256
        mov     al,es:[bx]   ; Get memory byte.
        sub     ah,ah
        leave
        ret
GetPoint256  endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : Point256

 Description :
    Plots a point on the screen. Mode 10xh SuperVGA 256 color modes.
    Make sure the x,y co-ordinate is in range.

 Parameters :

 Registers Affected : AX,BX,ES

================================================================================
~
        public  Point256
Point256        proc near
        push    bp
        mov     bp,sp
        mov     ax,ARGy
        mov     bx,ARGx
        mPointAddr256
        push    bx
        mov     bx,ARGx
        call    word ptr _fgsv.fgsColorPtr
        pop     bx
        sub     ah,ah
Point256ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        leave
        ret
Point256        endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : AHLine256

 Description :
    Draws horizontal line in mode 10x using area pattern.

 Parameters :

 Registers Affected :

 Returns :

================================================================================
~
        public  AHLine256
AHLine256 proc    near
        push    bp
        mov     bp,sp
        push    di
        push    si
        mov     ax,ARGy1
        mov     si,ax
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     AHLine2561
        neg     cx
        mov     bx,ARGx2 ; start at lower x
AHLine2561:
        push    bx
        mPointAddr256    ; es:[bx] = first address
        inc     cx
        mov     di,bx    ; es:[di] = buffer address
        pop     bx       ; bx = x
AHLine2562:
        mov     ax,si    ; ax = y
        call    word ptr _fgsv.fgsColorPtr
        xchg    di,bx
        sub     ah,ah
AHLine256ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        xchg    di,bx
        inc     di
        inc     bx
        cmp     bx,0     ; Is the bank switching ?
        jne     AHLine2563
        mov     bx,word ptr _fgsv.fgsPrevBank ; get current bank
        inc     bx
        mov     word ptr _fgsv.fgsPrevBank,bx ; set next bank
        call    word ptr _fgsv.fgsBankSwitch   ;; switch VGA to correct bank
        sub     bx,bx                         ; bx = 0 again
AHLine2563:
        loop    AHLine2562
        pop     si
        pop     di
        leave
        ret
AHLine256 endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : SHLine256

 Description :
    Draws horizontal line in mode 10x using solid color.

 Parameters :

 Registers Affected :

 Returns :

================================================================================
~
        public  SHLine256
SHLine256 proc    near
        push    bp
        mov     bp,sp
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     SHLine2561
        neg     cx
        mov     bx,ARGx2 ; start at lower x
SHLine2561:
        mPointAddr256    ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,bx    ; es:[di] = buffer address
        mov     dl,byte ptr _fgsv.fgsColor ; AL = color
SHLine2562:
        ; must recalc point address in case of bank switch
        mov     al,dl
        sub     ah,ah
SHLine256ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        inc     bx
        cmp     bx,0     ; Is the bank switching ?
        jne     SHLine2563
        mov     bx,word ptr _fgsv.fgsPrevBank ; get current bank
        inc     bx
        mov     word ptr _fgsv.fgsPrevBank,bx ; set next bank
        call    word ptr _fgsv.fgsBankSwitch   ;; switch VGA to correct bank
        mov     dl,byte ptr _fgsv.fgsColor    ; dl = color (dx trashed)
        sub     bx,bx                         ; bx = 0 again
SHLine2563:
        loop    SHLine2562
        pop     di
        leave
        ret
SHLine256 endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : LHLine256

 Description :
    Draws horizontal line in mode 10x using linear pattern.

 Parameters :

 Registers Affected :

 Returns :

================================================================================
~
        public  LHLine256
LHLine256 proc    near
        push    bp
        mov     bp,sp
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     cx,ARGx2
        sub     cx,bx
        jns     LHLine2561
        neg     cx
        mov     bx,ARGx2 ; start at lower x
LHLine2561:
        mPointAddr256     ; es:[bx] = first address
        inc     cx       ; cx = # pixels
        mov     di,word ptr _fgsv.fgsColor ; get color table address
        mov     dl,byte ptr _fgsv.fgsPatHeight; get index to color
        mov     dh,byte ptr _fgsv.fgsPatWidth ; get max index
        cld
        sub     ah,ah
LHLine2562:
        mov     al,dl
        xchg    bx,di
        xlatb
        xchg    bx,di
        inc     dl
        cmp     dl,dh
        jb      LHLine2563
        sub     dl,dl
LHLine2563:
LHLine256ROP:
        nop
        nop
        nop
        nop
        nop
        nop
        inc     bx
        cmp     bx,0     ; Is the bank switching ?
        jne     LHLine2564
        mov     bx,word ptr _fgsv.fgsPrevBank ; get current bank
        inc     bx
        push    dx
        mov     word ptr _fgsv.fgsPrevBank,bx ; set next bank
        call    word ptr _fgsv.fgsBankSwitch  ; switch SVGA to correct bank
        sub     bx,bx                         ; bx = 0 again
        pop     dx
LHLine2564:
        loop    LHLine2562
        mov     byte ptr _fgsv.fgsPatHeight,dl; save index to color
        pop     di
        leave
        ret
LHLine256 endp
; 
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : _R....

 Description :
    Raster operator (ROP) code for 256 color modes. Note the following
 operations cause a pixel read then write. This is necessary for pixel
 latching with display adapter.

 Parameters :

 Registers Affected : AX,BX,ES

================================================================================
~
        public  _R256NOP          ; NOP
        public  _R256Black        ; black pen
_R256Black:
        mov     byte ptr es:[bx],0
_R256NOP:
        pop     bp
        ret

        public  _R256White        ; white pen
_R256White:
        mov     byte ptr es:[bx],0ffh
        pop     bp
        ret

        public  _R256Not          ; not pen
_R256Not:
        not     byte ptr es:[bx]
        pop     bp
        ret

        public  _R256NotScrOr     ; merge pen not
_R256NotScrOr:
        not     byte ptr es:[bx]
        or      es:[bx],al
        pop     bp
        ret

        public  _R256NotScrAnd    ; mask pen not
_R256NotScrAnd:
        not     byte ptr es:[bx]
        and     es:[bx],al
        pop     bp
        ret

        public  _R256Or           ; merge pen
        public  _R256ScrOrNot     ; merge not pen
_R256ScrOrNot:
        not     al
_R256Or:
        or      es:[bx],al
        pop     bp
        ret

        public  _R256ScrAndNot    ; mask not pen
        public  _R256And          ; mask pen
_R256ScrAndNot:
        not     al
_R256And:
        and     es:[bx],al
        pop     bp
        ret

        public  _R256Xor          ; xor pen
_R256Xor:
        xor     es:[bx],al
        pop     bp
        ret

        public  _R256NotXor       ; not xor pen
_R256NotXor:
        xor     es:[bx],al
        not     byte ptr es:[bx]
        pop     bp
        ret

        public  _R256NotOr        ; not merge pen
_R256NotOr:
        or      es:[bx],al
        not     byte ptr es:[bx]
        pop     bp
        ret

        public  _R256NotAnd       ; not mask pen
_R256NotAnd:
        and     es:[bx],al
        not     byte ptr es:[bx]
        pop     bp
        ret

        public  _R256NotCopy      ; not copy pen
        public  _R256Copy         ; copy pen
_R256NotCopy:
        not     al
_R256Copy:
        mov     es:[bx],al
        pop     bp
        ret


        public _R13SHCopy
        public _R13SHNotCopy
_R13SHNotCopy:
        not     al
_R13SHCopy:
        rep     stosb
        pop     di
        pop     bp
        ret

        public  _R13SHBlack
_R13SHBlack:
        sub     al,al
        rep     stosb
        pop     di
        pop     bp
        ret

        public  _R13SHWhite
_R13SHWhite:
        mov     al,0ffh
        rep     stosb
        pop     di
        pop     bp
        ret
; 
comment ~
================================================================================
 95/10/13
 Description :
        Clears SVGA mode screen

 Parameters :

 Registers Affected :

 Returns :
================================================================================
~
        public  ClrScr256
ClrScr256   proc  far
        push    bp
        mov     bp,sp
        push    di

        ; compute number of bytes to zero based on mode
        mov     ax,word ptr _fgsv.fgsMaxX     ; get screen width
        mul     word ptr _fgsv.fgsMaxY        ; screen height
        mov     es,word ptr _fgsv.fgsVScreen  ; Set es to point to virtual screen

        shr     ax,1
        mov     cx,ax       ; get remainder into cx
        mov     bx,dx
        add     dx,1
        jmp     ClrScr2562
ClrScr2561:
        mov     cx,08000h
ClrScr2562:
        sub     di,di
        push    bx
        push    cx
        call    word ptr _fgsv.fgsBankSwitch  ; switch to bank bx
        sub     ax,ax
        pop     cx
        cld
        rep     stosw   ; set all bytes to 0
        pop     bx
        sub     bx,1
        jge     short ClrScr2561

        pop     di
        pop     bp
        retf
ClrScr256        endp
        end
; 

