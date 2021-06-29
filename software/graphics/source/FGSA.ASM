        .286
        .model small

include fgs.ah

comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : fgsa.asm

 Description :
    Supports point drawing/getting and line drawing for the following
    modes:

        mode resolution     colors    adapter
        6      640 x 200      2       CGA/EGA/VGA
        d      320 x 200      16      EGA/VGA
        e      640 x 200      16      EGA/VGA
        f      640 x 350      mono    EGA/VGA
        10     640 x 350      16      EGA/VGA
        11     640 x 480      2       MCGA/VGA
        12     640 x 480      16      VGA

    Adapters
        CGA  - Color Graphics Adapter
        EGA  - Enhanced Graphics Adapter
        VGA  - Video Graphics Array
        MCGA - Multi Color Graphics Array  (PS series)
        
 Parameters :

 Registers Affected :

 Returns :

         Author      : R. Finch
         Date        : 90/06/08
                     : 95/10/13
                       96/04/04

================================================================================
~
        .286
        .model  small

include fgs.ah

extrn   _fgsv:word
extrn   AHLine256:near
extrn   SHLine256:near
extrn   LHLine256:near
extrn   GetPoint256:near
extrn   Point256:near
extrn   ClrScr256:far

extrn   AHLine13:near
extrn   SHLine13:near
extrn   LHLine13:near
extrn   GetPoint13:near
extrn   Point13:near
extrn   ClrScr13:far

extrn   AHLine32k:near
extrn   SHLine32k:near
extrn   LHLine32k:near
extrn   GetPoint32k:near
extrn   Point32k:near
extrn   ClrScr32k:far

extrn   ROP13Tbl:near
extrn   ROP256Tbl:near
extrn   ROP32kTbl:near

extrn _RCopy:near
extrn _ROPAnd:near
extrn _ROr:near
extrn _RXor:near
extrn _RBlack:near
extrn _RWhite:near
extrn _RNOP:near
extrn _RNot:near
extrn _RNotCopy:near
extrn _RNotAnd:near
extrn _RNotOr:near
extrn _RNotXor:near
extrn _RNotScrOr:near
extrn _RNotScrAnd:near
extrn _RScrOrNot:near
extrn _RScrAndNot:near

extrn   ClrScr4:far
extrn   GetPoint4:near
extrn   Point4:near
extrn   HLine4:near
extrn   ROP4Tbl:near

extrn   ClrScr6:far
extrn   GetPoint6:near
extrn   Point6:near
extrn   HLine6:near
extrn   ROP6Tbl:near

extrn   ClrScr10:far
extrn   GetPoint10:near
extrn   Point10:near
extrn   HLine10:near
extrn   SHLine10:near
extrn   ROP10Tbl:near

extrn   ColorTbl:near
extrn   ColorTbl256:near
extrn   ColorTbl32k:near

public  _ModeTable

        .data

        align  2
;---------------------------------------------------------------------------------------------------------------------------------------------
; For any mode
;                          Clear                          color       
;                    Mode  Screen    GetPoint    Point    table       AHLine      SHLine      LHLine      MaxX  MaxY Colors Seg     Raster op
;---------------------------------------------------------------------------------------------------------------------------------------------

_ModeTable   label     word
        fgsMode   <  04h,  ClrScr4,  GetPoint4,  Point4,  ColorTbl,   HLine4,     HLine4,     HLine4,     320,  200,     4, 0b800h, ROP4Tbl >
        fgsMode   <  05h,  ClrScr4,  GetPoint4,  Point4,  ColorTbl,   HLine4,     HLine4,     HLine4,     320,  200,     4, 0b800h, ROP4Tbl >
        fgsMode   <  06h,  ClrScr6,  GetPoint6,  Point6,  ColorTbl,   HLine6,     HLine6,     HLine6,     640,  200,     2, 0b800h, ROP6Tbl >
        fgsMode   <  0dh,  ClrScr10, GetPoint10, Point10, ColorTbl,   HLine10,    SHLine10,   HLine10,    320,  200,    16, 0a000h, ROP10Tbl >
        fgsMode   <  0eh,  ClrScr10, GetPoint10, Point10, ColorTbl,   HLine10,    SHLine10,   HLine10,    640,  200,    16, 0a000h, ROP10Tbl >
        fgsMode   <  0fh,  ClrScr10, GetPointf,  Point10, ColorTbl,   HLine10,    SHLine10,   HLine10,    640,  350,     2, 0a000h, ROP10Tbl >
        fgsMode   <  10h,  ClrScr10, GetPoint10, Point10, ColorTbl,   HLine10,    SHLine10,   HLine10,    640,  350,    16, 0a000h, ROP10Tbl >
        fgsMode   <  11h,  ClrScr10, GetPoint11, Point11, ColorTbl,   HLine11,    HLine11,    HLine11,    640,  480,     2, 0a000h, ROP11Tbl >
        fgsMode   <  12h,  ClrScr10, GetPoint10, Point10, ColorTbl,   HLine10,    SHLine10,   HLine10,    640,  480,    16, 0a000h, ROP10Tbl >
        fgsMode   <  13h,  ClrScr13, GetPoint13, Point13, ColorTbl,   AHLine13,   SHLine13,   LHLine13,   320,  200,   256, 0a000h, ROP13Tbl >

        fgsMode   < 100h,  ClrScr256,GetPoint256,Point256,ColorTbl256,AHLine256,  SHLine256,  LHLine256,  640,  400,   256, 0a000h, ROP256Tbl >
        fgsMode   < 101h,  ClrScr256,GetPoint256,Point256,ColorTbl256,AHLine256,  SHLine256,  LHLine256,  640,  480,   256, 0a000h, ROP256Tbl >
        fgsMode   < 103h,  ClrScr256,GetPoint256,Point256,ColorTbl256,AHLine256,  SHLine256,  LHLine256,  800,  600,   256, 0a000h, ROP256Tbl >
        fgsMode   < 105h,  ClrScr256,GetPoint256,Point256,ColorTbl256,AHLine256,  SHLine256,  LHLine256, 1024,  768,   256, 0a000h, ROP256Tbl >
        fgsMode   < 107h,  ClrScr256,GetPoint256,Point256,ColorTbl256,AHLine256,  SHLine256,  LHLine256, 1280, 1024,   256, 0a000h, ROP256Tbl >

        fgsMode   < 10dh,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  320,  200, 32768, 0a000h, ROP32kTbl >
        fgsMode   < 10eh,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  320,  200, 65535, 0a000h, ROP32kTbl >
        fgsMode   < 110h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  640,  480, 32768, 0a000h, ROP32kTbl >
        fgsMode   < 111h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  640,  480, 65535, 0a000h, ROP32kTbl >
        fgsMode   < 113h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  800,  600, 32768, 0a000h, ROP32kTbl >
        fgsMode   < 114h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k,  800,  600, 65535, 0a000h, ROP32kTbl >
        fgsMode   < 116h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k, 1024,  768, 32768, 0a000h, ROP32kTbl >
        fgsMode   < 117h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k, 1024,  768, 65535, 0a000h, ROP32kTbl >
        fgsMode   < 119h,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k, 1280, 1024, 32768, 0a000h, ROP32kTbl >
        fgsMode   < 11ah,  ClrScr32k,GetPoint32k,Point32k,ColorTbl32k,AHLine32k,  SHLine32k,  LHLine32k, 1280, 1024, 65535, 0a000h, ROP32kTbl >

        public  _GetColorTbl
_GetColorTbl    label    word
        dw      ?     ; Solid color
        dw      ?     ; linear pattern color
        dw      ?     ; area pattern color
        dw      ?     ; volume pattern color

comment ~
================================================================================
 Description :
    Raster operation table
================================================================================
~
        public ROPPointTbl
ROPPointTbl label word
        dw      _RCopy,      8 
        dw      _ROPAnd,     7 
        dw      _ROr,        5 
        dw      _RXor,       10 
        dw      _RBlack,     5
        dw      _RWhite,     7
        dw      _RNOP,       2 
        dw      _RNot,       7 
        dw      _RNotCopy,   12
        dw      _RNotAnd,    12
        dw      _RNotOr,     12
        dw      _RNotXor,    12
        dw      _RNotScrOr,  10
        dw      _RNotScrAnd, 12
        dw      _RScrOrNot,  9
        dw      _RScrAndNot, 7

        public ROPLineTbl
ROPLineTbl label word
        dw      _RCopy,      6
        dw      _ROPAnd,     5
        dw      _ROr,        3
        dw      _RXor,       8
        dw      _RBlack,     3
        dw      _RWhite,     5
        dw      _RNOP,       0
        dw      _RNot,       5
        dw      _RNotCopy,   10
        dw      _RNotAnd,    10
        dw      _RNotOr,     10
        dw      _RNotXor,    10
        dw      _RNotScrOr,  8
        dw      _RNotScrAnd, 10
        dw      _RScrOrNot,  7
        dw      _RScrAndNot, 5

        public ROP11Tbl
ROP11Tbl label word
        dw      Point11ROP, ROPPointTbl, 12
        dw      HLine11ROP, ROPLineTbl, 10
        dw      HLine11ROP, ROPLineTbl, 10
        dw      HLine11ROP, ROPLineTbl, 10

Screen2 dw 0b000h   ; second 64k segment

Width80         dw    80
Width160        dw    160

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
        push    bp
        mov     bp,sp
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
        push    bp
        mov     bp,sp
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
   
 (C) 1992 FinchWare

 Point4,6,11

 Description :
    Plot point in 320 x 200 four colour mode (mode 4,5).

 Parameters :

 Registers Affected :

 Returns :

 Author      : R. Finch
 Date        : 92/02/19

================================================================================
~
Point11 proc near
        push    bp
        mov     bp,sp
        mov     ax,ARGy
        mov     bx,ARGx
        PointAddr10
        push    bx
        mov     bx,ARGx
        call    word ptr _fgsv.fgsColorPtr
        pop     bx
        mov     ah,1
        and     al,ah
        rol     ax,cl    ; shift color bits (al) and mask (ah) to pixel
        not     ah
Point11ROP:
        nop
        nop
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
Point11 endp
; 

HLine11 proc    near
        push    bp
        mov     bp,sp
        push    di
        mov     ax,ARGy1
        mov     bx,ARGx1
        mov     dx,ARGx2
        sub     dx,bx
        jns     HLine111
        neg     dx
        mov     bx,ARGx2
HLine111:
        PointAddr10      ;; calculate address of first point
        inc     dx
HLine112:
        mov     ax,ARGy1;; ax = y
        call    word ptr _fgsv.fgsColorPtr
        mov     ah,1
        and     al,ah
        rol     ax,cl    ; shift color bits (al) and mask (ah) to pixel
        not     ah
HLine11ROP:
        nop     ; This room reserved for the raster operation
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        dec     cl
        jns     HLine113  
        mov     cl,7
        inc     bx       ;; if shifted around, increment buffer address
HLine113:
        dec     dx
        jnz     HLine112
        pop     di
        leave
        ret
        HLine   PointAddr10, 1, 7, 1
HLine11 endp
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
Set4Pixels   proc near
        push ax
        push bx
        push dx
        mov  dx,3ceh
        xor  bx,bx
        test ch,ch
        jz   Set4Pixels30
        mov  bx,80
        neg  bx
Set4Pixels30:
        mov  al,8      ; AL = bit mask register number

; pixels at (xc-x,yc+y) and (xc-x, yc-y)

        xor  si,si
        mov  ah,LMask
        rol  ah,cl
        rcl  si,1      ; SI = 1 if bit mask rotated around
        neg  si

        mov  di,si

        add  si,ULAddr
        add  si,bx
        add  di,LLAddr
        sub  di,bx

        mov  LMask,ah
        mov  ULAddr,si
        mov  LLAddr,di
        
        out  dx,ax
        mov  ch,es:[si]     ; update upper left pixel
        mov  es:[si],ch
        mov  ch,es:[di]     ; update lower left pixel
        mov  es:[di],ch

; pixels at (xc+x, yc+y) and (xc+x,yc-y)

        xor  si,si
        mov  ah,RMask
        ror  ah,cl          ; AH = bit mask rotated horizontally
        rcl  si,1           ; SI = 1 if bit mask rotated around
        mov  di,si          ; SI,DI = right horizontal increment
        add  si,URAddr
        add  si,bx
        add  di,LRAddr
        sub  di,bx
        mov  RMask,ah
        mov  URAddr,si
        mov  LRAddr,di
        out  dx,ax
        mov  ch,es:[si]     ; update upper right pixel
        mov  es:[si],ch
        mov  ch,es:[di]     ; update lower right pixel
        mov  es:[di],ch
        pop  dx
        pop  bx
        pop  ax
        ret
Set4Pixels   endp
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
LongMultiply proc near
        push ax        ; DX:AX = 32 bit number
        mov  ax,dx     ; CX = 16 bit number
        mul  cx
        xchg ax,cx
        pop  dx
        mul  dx
        add  dx,cx
        ret
LongMultiply endp
; 
        end
; 

