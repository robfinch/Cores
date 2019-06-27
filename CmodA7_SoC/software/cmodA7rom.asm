; ============================================================================
; CmodA7rom.asm
;        __
;   \\__/ o\    (C) 2014-2017  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;  
;
; This source file is free software: you can redistribute it and/or modify 
; it under the terms of the GNU Lesser General Public License as published 
; by the Free Software Foundation, either version 3 of the License, or     
; (at your option) any later version.                                      
;                                                                          
; This source file is distributed in the hope that it will be useful,      
; but WITHOUT ANY WARRANTY; without even the implied warranty of           
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
; GNU General Public License for more details.                             
;                                                                          
; You should have received a copy of the GNU General Public License        
; along with this program.  If not, see <http://www.gnu.org/licenses/>.    
;                                                                          
; ============================================================================
;
CR			EQU		13
LF			EQU		10
ESC			EQU		$1B
BS			EQU		8
CTRLC		EQU		3

SC_LSHIFT	EQU		$12
SC_RSHIFT	EQU		$59
SC_KEYUP	EQU		$F0
SC_EXTEND	EQU		$E0
SC_CTRL		EQU		$14
SC_ALT		EQU		$11
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
SC_NUMLOCK	EQU		$77
SC_SCROLLLOCK	EQU	$7E
SC_CAPSLOCK	EQU		$58

; Zero-page storage
;
DPL       	equ   $00     ; data pointer (three bytes)
DPM					equ		$01
DPH       	equ   $02     ; high of data pointer
RECLEN    	equ   $03     ; record length in bytes
START_LO  	equ   $04
START_MID		equ		$05
START_HI  	equ   $06
RECTYPE   	equ   $07
CHKSUM    	equ   $08     ; record checksum accumulator
DLFAIL    	equ   $09     ; flag for download failure
TEMP      	equ   $0A     ; save hex value
ENTRYPT_LO	equ		$0B
ENTRYPT_MID	equ		$0C
ENTRYPT_HI	equ		$0D

RXBUFPTR		equ		$10
TXBUFPTR		equ		$14
RXNDX				equ		$18
TXNDX				equ		$1A

IRQSRC			equ		$F20000
RXIRQOFF		equ		$F20001	; writing turns off IRQ
TMRIRQOFF		equ		$F20002	; turns off timer IRQ

	code
	
	cpu		W65C816S
	.org	$F000

start:
	sei						; disable interrupts
	clc						; switch to native mode
	xce
	rep		#$030		; 16 bit regs
	NDX 	16
	MEM		16
	ldx		#$EFFF		; set stack pointer
	txs
	; setup reciever buffer pointer
	stz		RXBUFPTR
	stz		TXBUFPTR
	lda		#$00F0
	sta		RXBUFPTR+2
	lda		#$00F1
	sta		TXBUFPTR+2
	; Stuff 32 FF's into the start of the xmit buffer. This acts as a sync to the
	; software on the PC.
	ldy		#32
	lda		#$FFFF
.0001:
	sta		[TXBUFPTR],y
	dey
	dey
	bne		.0001
	lda		#$0020		; reset pointer past preamble
	sta		TXBUFPTR
	stz		TXNDX
WFIRQ:
	wai

RXIRQ:
	php
	sep		#$20
	MEM		8
	lda		IRQSRC
	tax
	and		#1
	bne		.rxirq
	txa
	and		#2
	bne		.tmrirq
	bra		WFIRQ
.tmrirq:
	sta		TMRIRQOFF	; writing any value will clear irq
	plp
	MEM		16
	lda		#$0020		; reset pointer past preamble
	sta		TXBUFPTR
	stz		TXNDX
	bra		WFIRQ
.rxirq:
	sta		RXIRQOFF	; writing any value will clear irq
	plp
	MEM		16
	jmp		IntelHexDownload

		org $F800
;
    ; Download Intel hex.
IntelHexDownload:
	php
	sep		#$30			; 8 bit index and mem
	NDX 	8
	MEM		8
  stz     DLFAIL          ; Start by assuming no D/L failure
  jsr     SerialPutString
  .byte   13,10,13,10
  .byte   "Send 65816 code in"
  .byte   " Intel Hex format"
  .byte  " at 19200,n,8,1 ->"
  .byte   13,10,0
  ; Set default program entry point $000400
  stz			ENTRYPT_HI
  lda			#$04
  sta			ENTRYPT_MID
  stz			ENTRYPT_LO
.nextrec:
	jsr     SerialGetChar   ; Wait for start of record mark ':'
  cmp     #':'
  bne     .nextrec        ; not found yet
  ; Start of record marker has been found
  jsr     SerialGetByte   ; Get the record length
  sta     RECLEN          ; save it
  sta     CHKSUM          ; and save first byte of checksum
  ; Assume a zero for address bits 16 to 23, this may be reset
  ; with a $04 record.
  stz			START_HI				
  jsr     SerialGetByte   ; Get address bits 8 to 15
  sta     START_MID
  clc
  adc     CHKSUM          ; Add in the checksum
  sta     CHKSUM          ;
  jsr     SerialGetByte   ; Get address bits 0 to 7
  sta     START_LO
  clc
  adc     CHKSUM
  sta     CHKSUM
  jsr     SerialGetByte   ; Get the record type
  sta     RECTYPE         ; & save it
  clc
  adc     CHKSUM
  sta     CHKSUM
  lda     RECTYPE
  bne     .nextRecType

  ; Process record type #0 - data
  ldx     RECLEN          ; number of data bytes to write to memory
  ldy     #0              ; start offset at 0
.0002:
  jsr     SerialGetByte   ; Get the first/next/last data byte
  sta     [START_LO],y    ; Save it to RAM
  clc
  adc     CHKSUM
  sta     CHKSUM          ;
  iny                     ; update data pointer
  dex                     ; decrement count
  bne     .0002
  jsr     SerialGetByte   ; get the checksum
  clc
  adc     CHKSUM
  bne     .fail           ; If failed, report it
  ; Another successful record has been processed
  lda     #'#'            ; Character indicating record OK = '#'
  jsr			SerialPutChar		; write it out but don't wait for output
  brl     .nextrec        ; get next record
.fail:
	lda     #'F'            ; Character indicating record failure = 'F'
  sta     DLFAIL          ; download failed if non-zero
  jsr     SerialPutChar   ; write it to transmit buffer register
  brl     .nextrec        ; wait for next record start

.nextRecType:
	cmp     #1              ; Check for end-of-file type
  beq     .eofRec
  cmp			#4
  beq			.extAddrRec
  cmp			#5
  beq			.entryPointRec
  jsr     SerialPutString ; Warn user of unknown record type
  .byte   13,10,13,10
  .byte   "Unknown record type $",0
  lda     RECTYPE         ; Get it
	sta			DLFAIL					; non-zero --> download has failed
  jsr     SerialPutByte   ; print it
	lda     #13							; but we'll let it finish so as not to
  jsr     SerialPutChar		; falsely start a new d/l from existing
  lda     #10							; file that may still be coming in for
  jsr     SerialPutChar		; quite some time yet.
	brl 		.nextrec
.fail2:
	bra			.fail

	; We've reached the end-of-file record
.eofRec:
  jsr     SerialGetByte   ; get the checksum
  clc
  adc     CHKSUM          ; Add previous checksum accumulator value
  beq     .0005           ; checksum = 0 means we're OK!
  jsr     SerialPutString ; Warn user of bad checksum
  .byte   13,10,13,10
  .byte   "Bad record checksum!",13,10,0
  brl     IntelHexDownload

  ; rectype #4 - Get address extension - bits 16 to 31
.extAddrRec:
	jsr			SerialGetByte		; get address bits 24 to 31
	clc											; and discard
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte		; get address bits 16 to 23
	sta			START_HI
	clc
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte
	clc
	adc			CHKSUM
.fail1:
	bne			.fail2
	brl			.nextrec

	; rectype #5 - Get the entry point record
.entryPointRec:
	jsr			SerialGetByte		; get address bits 24 to 31
	clc
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte		; get address bits 16 to 23
	sta			ENTRYPT_HI
	clc
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte		; get address bits 8 to 15
	sta			ENTRYPT_MID
	clc
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte		; get address bits 0 to 7
	sta			ENTRYPT_LO
	clc
	adc			CHKSUM
	sta			CHKSUM
	jsr			SerialGetByte		; get checksum byte
	clc
	adc			CHKSUM
	bne			.fail1
	brl			.nextrec

.0005:
 	lda     DLFAIL
  beq     .downloadOk
  ;A download failure has occurred
  jsr     SerialPutString
  .byte   13,10,13,10
  .byte   "Download Failed.",13,10,0
  brl     IntelHexDownload

.downloadOk:
	jsr     SerialPutString
  .byte   13,10,13,10
  .byte   "Download Successful!",13,10
  .byte   "Jumping to $",0
  lda			ENTRYPT_HI		; Print the entry point in hex
  jsr			SerialPutByte
  lda			ENTRYPT_MID
  jsr			SerialPutByte
  lda			ENTRYPT_LO
  jsr			SerialPutByte
  jsr			SerialPutString
  .byte   13,10,0
  jmp			[ENTRYPT_LO]	; jump to canonical entry point
;
;
; This routine assumes that serial data is present in the buffer.

SerialGetChar:
	php
	rep		#$010		; 16 bit index
	MEM		8
	NDX		16
	ldy		RXNDX
	lda		[RXBUFPTR],y
	iny
	sty		RXNDX
	plp						; restore register settings
  rts

	MEM		8
	NDX		8
; Busy wait

SerialGetByte:
	jsr     SerialGetChar
  jsr     MKNIBL  	; Convert to 0..F numeric
  asl
  asl
  asl
  asl				       	; This is the upper nibble
  and     #$F0
  sta     TEMP
  jsr     SerialGetChar
  jsr     MKNIBL
  ora     TEMP
  rts             	; return with the nibble received

; Convert the ASCII nibble to numeric value from 0-F:
MKNIBL  cmp     #'9'+1  	; See if it's 0-9 or 'A'..'F' (no lowercase yet)
        bcc     MKNNH   	; If we borrowed, we lost the carry so 0..9
        sbc     #7+1    	; Subtract off extra 7 (sbc subtracts off one less)
        ; If we fall through, carry is set unlike direct entry at MKNNH
MKNNH   sbc     #'0'-1  	; subtract off '0' (if carry clear coming in)
        and     #$0F    	; no upper nibble no matter what
        rts             	; and return the nibble

; Put byte in A as hexydecascii

SerialPutByte:
	pha             	;
  lsr
  lsr
  lsr
  lsr
  jsr     .0001
  pla
.0001:
  and     #$0F    	; strip off the low nibble
  cmp     #$0A
  bcc     .0002  	; if it's 0-9, add '0' else also add 7
  adc     #6      	; Add 7 (6+carry=1), result will be carry clear
.0002:
  adc     #'0'    	; If carry clear, we're 0-9

; Write the character in A as ASCII:

SerialPutChar:
	php
	rep		#$010		; 16 bit index
	MEM		8
	NDX		16
	ldy		TXNDX
	sta		[TXBUFPTR],y
	iny
	sty		TXNDX
	plp						; restore register settings
  rts

	MEM		8
	NDX		8

; Put the string following in-line until a NULL out to the console
;
SerialPutString:
	pla			; Get the low part of "return" address (data start address)
  sta     DPL
  pla
  sta     DPH             ; Get the high part of "return" address
                              ; (data start address)
  ; Note: actually we're pointing one short
.PSINB:
  ldy     #1
  lda     (DPL),y         ; Get the next string character
  inc     DPL             ; update the pointer
  bne     .0001           ; if not, we're pointing to next character
  inc     DPH             ; account for page crossing
.0001:
  ora     #0              ; Set flags according to contents of Accumulator
  beq     .0002           ; don't print the final NULL
  jsr     SerialPutChar   ; write it out
  bra     .PSINB          ; back around
.0002:
	inc     DPL             ;
  bne     .0003           ;
  inc     DPH             ; account for page crossing
.0003:
  jmp     (DPL)           ; return to byte following final NULL

; ------------------------------------------------------------------------------
; ------------------------------------------------------------------------------

	.org	$FFFC		; reset vector
	dw		$F000

	.org	$FFFE
	dw		RXIRQ	; IRQRout02

