; ============================================================================
;        __
;   \\__/ o\    (C) 2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; BSD 3-Clause License
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;                                                                          
; ============================================================================
;
; S19 variables
;
s19Address			EQU		$940	; to $943
s19StartAddress	EQU		$944	; to $947
s19Rectype			EQU		$948
s19Reclen				EQU		$949
s19Abort				EQU		$94A
s19Checksum			EQU		$94B
s19SummaryChecksum	EQU		$94C
s19Source				EQU		$94E
s19XferAddress	EQU	$950	; to $951

; ------------------------------------------------------------------------------
; Input a character either from a file in memory or from the serial port.
;
; Parameters:
;		none
;	Returns:
;		accb = character input
; ------------------------------------------------------------------------------

s19InputChar:
	tst		s19Source
	beq		s19ic1
	ldb		[s19XferAddress]
	inc		s19XferAddress+1	; increment low byte of address pointer
	bne		s19ic2
	inc		s19XferAddress		; increment high byte of address pointer
s19ic2:
	rts
s19ic1:
	ldd		#-1							; block until input is available
	swi
	fcb		MF_INCH					; monitor input rout
	rts	

; ------------------------------------------------------------------------------
; Skip over input to the next record.
; ------------------------------------------------------------------------------

s19NextRecord:
	bsr		s19InputChar
	cmpb	#LF							; line feed marks end of record
	beq		s19nr1
	cmpb	#CTRLC					; should not get this in a file transfer
	bne		s19nr2
	stb		s19Abort
s19nr2:
	cmpb	#CTRLZ					; end of file marker?
	bne		s19nr3
	stb		s19Abort
s19nr3:
	tst		s19Abort
	beq		s19NextRecord
s19nr1:
	rts

; ------------------------------------------------------------------------------
; Update the checksum.
; ------------------------------------------------------------------------------

s19AddCheck:
	pshs	b
	addb	s19Checksum
	stb		s19Checksum
	puls	b,pc

; ------------------------------------------------------------------------------
; Input a byte. There are three characters per byte since things are 12-bit.
;
;	Parameters:
;		none
; Returns:
;		accb = byte value converted from text
; ------------------------------------------------------------------------------

s19GetByte:
	bsr		s19InputChar			; get the first character
	lbsr	AsciiToHexNybble	; convert to nybble
	tst		s19Abort					; check for abort
	beq		s19gb1
	clra
	rts
s19gb1:										; shift the value four bits
	aslb
	aslb
	aslb
	aslb
	pshs	b									; save off value
	bsr		s19InputChar			; get the second character
	lbsr	AsciiToHexNybble	; convert to nybble
	tst		s19Abort					; check for abort
	bne		s19gb2
	orb		,s+								; merge new nybble into value
	aslb										; shift the value four more bits
	aslb
	aslb
	aslb
	pshs	b									; save off value
	bsr		s19InputChar			; get the third character
	lbsr	AsciiToHexNybble	; convert to nybble
	orb		,s+								; merge in value
	clra										; make byte 000 to FFF in D
	rts
s19gb2:
	leas	1,s								; discard saved byte
	clra
	rts

; ------------------------------------------------------------------------------
; Zero out address
; ------------------------------------------------------------------------------

s19ClearAddress:
	clr		s19Address
	clr		s19Address+1
	clr		s19Address+2
	clr		s19Address+3
	rts
	
; ------------------------------------------------------------------------------
; Get an address composed of two bytes (24 bit)
;
; Side Effects:
;		updates s19Address variable
; Returns:
; 	none
; ------------------------------------------------------------------------------

s19GetAddress2:
	bsr		s19ClearAddress
	bsr		s19GetByte
	bsr		s19AddCheck
	stb		s19Address+2
	tst		s19Abort
	bne		s19ga1
	bsr		s19GetByte
	bsr		s19AddCheck
	stb		s19Address+3
s19ga1:
	rts
	
; ------------------------------------------------------------------------------
; Get an address composed of three bytes (36 bit)
;
; Side Effects:
;		updates s19Address variable
; Returns:
; 	none
; ------------------------------------------------------------------------------

s19GetAddress3:
	bsr		s19ClearAddress
	bsr		s19GetByte
	bsr		s19AddCheck
	stb		s19Address+1
	tst		s19Abort
	bne		s19ga2
	bsr		s19GetByte
	bsr		s19AddCheck
	stb		s19Address+2
	tst		s19Abort
	bne		s19ga2
	bsr		s19GetByte
	bsr		s19AddCheck
	stb		s19Address+3
s19ga2:
	rts

; ------------------------------------------------------------------------------
; Put a byte to memory.
; ------------------------------------------------------------------------------

s19PutMem:
	clrb								; accb = current byte count
s19pm3:
	pshs	b							; save byte count
	bsr		s19GetByte
	bsr		s19AddCheck
	tst		s19Abort
	bne		s19pm1
	stb		far [s19Address+1]	; store the byte using far addressing
	inc		s19Address+3
	bne		s19pm2
	inc		s19Address+2
	bne		s19pm2
	inc		s19Address+1
s19pm2:
	puls	b							; get back byte count
	incb								; increment and
	cmpb	s19Reclen			; compare to record length
	blo		s19pm3
	bsr		s19GetByte		; get the checksum byte
	bra		s19AddCheck
s19pm1:
	leas	1,s						; faster than actual pull
	bsr		s19GetByte		; get the checksum byte
	bra		s19AddCheck

; ------------------------------------------------------------------------------
; Processing for S1 record type.
; ------------------------------------------------------------------------------

s19ProcessS1:
	bsr		s19GetAddress2
	bsr		s19PutMem
	tst		s19Checksum
	beq		s19p11
	inc		s19SummaryChecksum
	ldd		#msgChecksumErr
	swi
	fcb		MF_DisplayString
s19p11:
	bra		s19lnr

; ------------------------------------------------------------------------------
; Processing for S2 record type.
; ------------------------------------------------------------------------------

s19ProcessS2:
	bsr		s19GetAddress3
	bsr		s19PutMem
	tst		s19Checksum
	beq		s19p21
	inc		s19SummaryChecksum
	ldd		#msgChecksumErr
	swi
	fcb		MF_DisplayString
s19p21:
	bra		s19lnr

; S3,4,5,6 not processed

; ------------------------------------------------------------------------------
; Processing for S7 record type. Gets a two byte (24 bit) start address.
; ------------------------------------------------------------------------------

s19ProcessS9:
	bsr		s19GetAddress2
	ldd		s19Address+2
	std		s19StartAddress+2
	ldd		s19Address+0
	std		s19StartAddress+0
	bra		s19l2
	
; ------------------------------------------------------------------------------
; Processing for S8 record type. Gets a three byte (36 bit) start address.
; ------------------------------------------------------------------------------

s19ProcessS8:
	bsr		s19GetAddress3
	ldd		s19Address+2
	std		s19StartAddress+2
	ldd		s19Address+0
	std		s19StartAddress+0
	bra		s19l2

; ------------------------------------------------------------------------------
; S19 Loader
;
; Not all record types are processed. Some are skipped over.
; ------------------------------------------------------------------------------

S19Loader:
	clr		s19Source
	lbsr	GetNumber				; check for a file storage address
	tstb
	beq		s19l4						; if not a memory file
	inc		s19Source				; set flag indicating a memory file
	ldd		mon_numwka+2		; set transfer address variable
	std		s19XferAddress
s19l4:
	clr		s19Abort				; clear the abort flag
	ldd		#msgS19Loader		; signon banner
	swi
	fcb		MF_DisplayString
	clr		s19SummaryChecksum
s19l3:
	bsr		s19InputChar		; get a character from input
	cmpb	#CTRLZ					; is it CTRL-Z?
	beq		s19l2
	clr		s19Checksum
	cmpb	#'C'						; records must start with the letter C
	bne		s19lnr
	bsr		s19InputChar		; get the next character
	cmpb	#'0'						; must be a numeric digit
	blo		s19lnr
	cmpb	#'9'
	bhi		s19lnr
	stb		s19Rectype			; save off in record type
	bsr		s19GetByte			; get a byte indicating record length
	bsr		s19AddCheck
	stb		s19Reclen
	tst		s19Abort				; check for abort
	bne		s19l2
	ldb		s19Rectype			; process according to record type
	cmpb	#'0'
	beq		s19lnr
	cmpb	#'1'
	beq		s19ProcessS1		; data record with a two byte address
	cmpb	#'2'
	beq		s19ProcessS2		; data record with a three byte address
	cmpb	#'3'
	beq		s19lnr
	cmpb	#'5'						; record count? ignore
	beq		s19lnr
	cmpb	#'7'						; ignore record with 48 bit address
	beq		s19l2
	cmpb	#'8'
	beq		s19ProcessS8		; two byte start address
	cmpb	#'9'
	beq		s19ProcessS9		; three byte start address
s19lnr:
	ldb		#'.'						; output a progress indicator
	swi
	fcb		MF_OUTCH
	bsr		s19NextRecord		; skip to the next record
	tst		S19Abort				; check for abort
	bne		s19l2
	bra		s19l3						; loop back to process more records
s19l2:
	lbra	Monitor

msgS19Loader:
	fcb	"S19 Loader Active",CR,LF,0
msgChecksumErr:
	fcb	"S19 Checksum Err",CR,LF,0

	