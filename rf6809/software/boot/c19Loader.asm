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
; C19 variables
;
c19Address			EQU		$940	; to $943
c19StartAddress	EQU		$944	; to $947
c19Rectype			EQU		$948
c19Reclen				EQU		$949
c19Abort				EQU		$94A
c19Checksum			EQU		$94B
c19SummaryChecksum	EQU		$94C
c19Source				EQU		$94E
c19XferAddress	EQU	$950	; to $951
c19crc24				EQU	$954
c19crcAddress		EQU	$956	; to $959
c19Buf					EQU	$980	; to $9FF

; ------------------------------------------------------------------------------
; Input a character either from a file in memory or from the serial port.
;
; Parameters:
;		none
;	Returns:
;		accb = character input
; ------------------------------------------------------------------------------

c19InputChar:
	tst		c19Source
	beq		c19ic1
	ldb		[c19XferAddress]
	inc		c19XferAddress+1	; increment low byte of address pointer
	bne		c19ic2
	inc		c19XferAddress		; increment high byte of address pointer
c19ic2:
	rts
c19ic1:
	ldd		#-1							; block until input is available
	swi
	fcb		MF_INCH					; monitor input rout
	rts	

; ------------------------------------------------------------------------------
; Skip over input to the next record.
; ------------------------------------------------------------------------------

c19NextRecord:
	bsr		c19InputChar
	cmpb	#LF							; line feed marks end of record
	beq		c19nr1
	cmpb	#CTRLC					; should not get this in a file transfer
	bne		c19nr2
	stb		c19Abort
c19nr2:
	cmpb	#CTRLZ					; end of file marker?
	bne		c19nr3
	stb		c19Abort
c19nr3:
	tst		c19Abort
	beq		c19NextRecord
c19nr1:
	rts

; ------------------------------------------------------------------------------
; Input a byte. There are three characters per byte since things are 12-bit.
;
;	Parameters:
;		none
; Returns:
;		accb = byte value converted from text
; ------------------------------------------------------------------------------

c19GetByte:
	bsr		c19InputChar			; get the first character
	lbsr	AsciiToHexNybble	; convert to nybble
	tst		c19Abort					; check for abort
	beq		c19gb1
	clra
	rts
c19gb1:										; shift the value four bits
	aslb
	aslb
	aslb
	aslb
	pshs	b									; save off value
	bsr		c19InputChar			; get the second character
	lbsr	AsciiToHexNybble	; convert to nybble
	tst		c19Abort					; check for abort
	bne		c19gb2
	orb		,s+								; merge new nybble into value
	aslb										; shift the value four more bits
	aslb
	aslb
	aslb
	pshs	b									; save off value
	bsr		c19InputChar			; get the third character
	lbsr	AsciiToHexNybble	; convert to nybble
	orb		,s+								; merge in value
	clra										; make byte 000 to FFF in D
	rts
c19gb2:
	leas	1,s								; discard saved byte
	clra
	rts

; ------------------------------------------------------------------------------
; Get an address composed of two bytes (24 bit)
;
; Side Effects:
;		updates c19Address variable
; Returns:
; 	none
; ------------------------------------------------------------------------------

c19GetAddress2:
	ldx		#0
	bsr		c19GetByte
	stb		c19Buf,x
	inx
	tst		c19Abort
	bne		c19ga1
	bsr		c19GetByte
	stb		c19Buf,x
	inx
c19ga1:
	rts
	
; ------------------------------------------------------------------------------
; Get an address composed of three bytes (36 bit)
;
; Side Effects:
;		updates c19Address variable
; Returns:
; 	none
; ------------------------------------------------------------------------------

;c19GetAddress3:
;	bsr		c19ClearAddress
;	bsr		c19GetByte
;	stb		c19Address+1
;	stb		c19Buf,x
;	inx
;	tst		c19Abort
;	bne		c19ga2
;	bsr		c19GetByte
;	stb		c19Address+2
;	stb		c19Buf,x
;	inx
;	tst		c19Abort
;	bne		c19ga2
;	bsr		c19GetByte
;	stb		c19Address+3
;	stb		c19Buf,x
;	inx
;c19ga2:
;	rts

; ------------------------------------------------------------------------------
; Put a record to memory.
; ------------------------------------------------------------------------------

c19PutMem:
	clrb								; accb = current byte count
	ldx		#2
c19pm3:
	pshs	b							; save byte count
	bsr		c19GetByte		; get a byte
	stb		c19Buf,x			; stuff in a temp buffer somewhere
	inx									; index to next byte
	tst		c19Abort			; check for abort
	bne		c19pm1
	puls	b							; get back byte count
	incb								; increment byte count
	cmpb	c19Reclen			; test if reached end of record
	blo		c19pm3				; no, go back
	bsr		c19GetByte		; get CRC high byte
	stb		c19crc24
	bsr		c19GetByte		; get CRC low byte
	stb		c19crc24+1
	clra								; set y = reclen
	ldb		c19Reclen
	tfr		d,y
	leau	c19Buf				; set u = pointer to buffer
	bsr		calc_crc24		; calc CRC for buffer
	cmpd	c19crc24			; compared to received CRC
	beq		c19pm4				; if equal go to update memory
	ldd		#msgCrcErr		; otherwise display error
	swi
	fcb		MF_DisplayString
	rts
	; Now that it is verified the record is correct, update memory with the record.
c19pm4:
	ldx		#0
c19pm5:
	ldb		c19Buf+2,x					; ignore the address bytes
	stb		[c19Buf],x
	inx
	tfr		x,d
	cmpb	c19Reclen
	blo		c19pm5
	rts
c19pm1:
	leas	1,s						; get rid of byte count
	rts

; ------------------------------------------------------------------------------
; Processing for S1 record type.
; ------------------------------------------------------------------------------

c19ProcessS1:
	bsr		c19GetAddress2
	bsr		c19PutMem
c19p11:
	bra		c19lnr

; ------------------------------------------------------------------------------
; Processing for S2 record type.
; ------------------------------------------------------------------------------

;c19ProcessS2:
;	bsr		c19GetAddress3
;	bsr		c19PutMem
;	tst		c19Checksum
;	beq		c19p21
;	inc		c19SummaryChecksum
;	ldd		#msgChecksumErr
;	swi
;	fcb		MF_DisplayString
;c19p21:
;	bra		c19lnr

; S3,4,5,6 not processed

; ------------------------------------------------------------------------------
; Processing for S7 record type. Gets a two byte (24 bit) start address.
; ------------------------------------------------------------------------------

c19ProcessS9:
	bsr		c19GetAddress2
	bra		c19l2
	
; ------------------------------------------------------------------------------
; Processing for S8 record type. Gets a three byte (36 bit) start address.
; ------------------------------------------------------------------------------

;c19ProcessS8:
;	bsr		c19GetAddress3
;	ldd		c19Address+2
;	std		c19StartAddress+2
;	ldd		c19Address+0
;	std		c19StartAddress+0
;	bra		c19l2

; ------------------------------------------------------------------------------
; S19 Loader
;
; Not all record types are processed. Some are skipped over.
; ------------------------------------------------------------------------------

C19Loader:
	clr		c19Source
	lbsr	GetNumber				; check for a file storage address
	tstb
	beq		c19l4						; if not a memory file
	inc		c19Source				; set flag indicating a memory file
	ldd		mon_numwka+2		; set transfer address variable
	std		c19XferAddress
c19l4:
	clr		c19Abort				; clear the abort flag
	ldd		#msgC19Loader		; signon banner
	swi
	fcb		MF_DisplayString
c19l3:
	bsr		c19InputChar		; get a character from input
	cmpb	#CTRLZ					; is it CTRL-Z?
	beq		c19l2
	cmpb	#'C'						; records must start with the letter C
	bne		c19lnr
	bsr		c19InputChar		; get the next character
	cmpb	#'0'						; must be a numeric digit
	blo		c19lnr
	cmpb	#'9'
	bhi		c19lnr
	stb		c19Rectype			; save off in record type
	bsr		c19GetByte			; get a byte indicating record length
	stb		c19Reclen
	tst		c19Abort				; check for abort
	bne		c19l2
	ldb		c19Rectype			; process according to record type
	cmpb	#'0'
	beq		c19lnr
	cmpb	#'1'
	beq		c19ProcessS1		; data record with a two byte address
;	cmpb	#'2'
;	beq		c19ProcessS2		; data record with a three byte address
	cmpb	#'3'
	beq		c19lnr
	cmpb	#'5'						; record count? ignore
	beq		c19lnr
	cmpb	#'7'						; ignore record with 48 bit address
	beq		c19l2
;	cmpb	#'8'
;	beq		c19ProcessS8		; three byte start address
	cmpb	#'9'
	beq		c19ProcessS9		; two byte start address
c19lnr:
	ldb		#'.'						; output a progress indicator
	swi
	fcb		MF_OUTCH
	bsr		c19NextRecord		; skip to the next record
	tst		c19Abort				; check for abort
	lbne	Monitor
	bra		c19l3						; loop back to process more records
c19l2:
	lbra	Monitor

msgC19Loader:
	fcb	"C19 Loader Active",CR,LF,0
msgCrcErr:
	fcb	"C19 CRC Err",CR,LF,0

; ------------------------------------------------------------------------------
; Compute CRC-24 of buffer.
;
;int calcrc24(char *ptr, int count)
;{
;    int  crc;
;    char i;
;    crc = CRC24INIT;
;    while (--count >= 0)
;    {
;        crc = crc ^ (int) (*ptr++ << 12);
;        i = 12;
;        do
;        {
;            if (crc & 0x800000)
;                crc = crc << 1 ^ CRC24POLY;
;            else
;                crc = crc << 1;
;        } while(--i);
;    }
;    return (crc);
;}
;
; Parameters:
;		y = number of bytes in buffer
;		u = pointer to buffer
; Returns:
;		d = crc24 value
;
; ------------------------------------------------------------------------------

crc24_init:
	fcw		$B704CE
crc24_poly:
	fcw		$CFB864

calc_crc24:
	ldd		crc24_init
calc_crc24c:
	eora	,u+
	ldx		#12
calc_crc24b:
	aslb
	rola
	bcc		calc_crc24a
	eorb	crc24_poly+1
	eora	crc24_poly
calc_crc24a:
	dex
	bne		calc_crc24b
	dey
	bne		calc_crc24c
	rts
