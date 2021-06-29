        .286
        .model small

        .code
comment ~
================================================================================
   
 (C) 1992 FinchWare

 Module : _R....

 Description :
    Raster operators (ROP). Note the following operations cause a pixel
 read then write. This is necessary for pixel latching with display
 adapter.

 Parameters :
        AH      pixel mask for clearing pixel in byte
        AL      color bits to set (already shifted to corect pixel)

 Registers Affected : AX,BX,ES

================================================================================
~
        public  _RBlack           ; black pen
_RBlack:
        and     es:[bx],ah        ; mask pixel
        pop	bp
        ret

        public  _RWhite           ; white pen
_RWhite:
        not     ah
        or      es:[bx],ah
        pop	bp
        ret

        public  _RNOP             ; NOP
_RNOP:
        pop	bp
        ret

        public  _RNot             ; not pen
_RNot:
        not     ah
        xor     es:[bx],ah
        pop	bp
        ret

        public  _RNotScrOr        ; merge pen not
_RNotScrOr:
        not     ah
        xor     es:[bx],ah        ; ~screen
        or      es:[bx],al        ; (~screen) | pen
        pop	bp
        ret

        public  _RNotScrAnd    ; mask pen not
_RNotScrAnd:
        or      al,ah
        not     ah
        xor     es:[bx],ah        ; (~screen)
        and     es:[bx],al        ; (~screen) & pen
        pop	bp
        ret

        public  _RScrOrNot     ; merge not pen
_RScrOrNot:
        not     ax
        and     al,ah
        or      es:[bx],al
        pop	bp
        ret

        public  _RScrAndNot    ; mask not pen
_RScrAndNot:
        not     al
        and     es:[bx],al
        pop	bp
        ret

        public  _RXor          ; xor pen
_RXor:
        mov     ah,es:[bx]
        xor     al,ah          ; (flip only pixel bits)
        mov     es:[bx],al
        pop	bp
        ret

        public  _RNotXor       ; not xor pen
_RNotXor:
        not     ah
        and     al,ah
        xor     al,es:[bx]     ; pen ^ screen
        xor     es:[bx],ah     ; ~(pen ^ screen)
        pop	bp
        ret

        public  _ROPAnd        ; mask pen  (ROP to avoid conflict with rand())
_ROPAnd:                       ; screen & pen
        or      al,ah          ; set all but pixel
        and     es:[bx],al     ; and to screen
        pop	bp
        ret

        public  _RNotOr        ; not merge pen
_RNotOr:
        or      al,es:[bx]     ; scrn | pen
        not     ah
        xor     al,ah          ; ~(scrn | pen)  (flip only pixel bits)
        mov     es:[bx],al
        pop	bp
        ret

        public  _RNotAnd       ; not mask pen
_RNotAnd:
        or      al,ah          ; set all but pixel
        and     es:[bx],al     ; scrn & pixel
        not     ah             ; now invert screen pixel
        xor     es:[bx],ah     ; ~(scrn & pixel) (flip only pixel bits)
        pop	bp
        ret

        public  _RCopy         ; copy pen
        public  _RNotCopy      ; not copy pen
        public  _ROr           ; merge pen
_RNotCopy:
        and     es:[bx],ah     ; clear bit
        not     ax             ; flip pixel and pixel mask
        and     al,ah
        or      es:[bx],al     ; set bit to color
        pop	bp
        ret
_RCopy:
        and     es:[bx],ah     ; clear bit
_ROr:
        or      es:[bx],al     ; set bit to color
        pop	bp
        ret

        end
; 

