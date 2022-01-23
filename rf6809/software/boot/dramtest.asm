; ============================================================================
;        __
;   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
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
OPT include "d:\cores2022\rf6809\software\boot\mon_equates.asm"
OPT include "d:\cores2022\rf6809\software\boot\io_equates.asm"

	org		$FFD400

; Local RAM test routine
; Checkerboard testing.
; There is 70kB of local RAM
; Does not use any RAM including no stack

dramtest:
	ldy		#$10000			; DRAM starts here
	lda		#1
	sta		LEDS
	ldu		#$AAA555
	swi
	fcb		MF_CRLF
dramtest1:
	deca
	bne		dramtest4
	tfr		y,d
	swi
	fcb		MF_DisplayWordAsHex
	ldb		#CR
	swi
	fcb		MF_OUTCH
dramtest4:
	stu		,y++
	cmpy	#$E00000		; DRAM ends here
	blo		dramtest1
	; now readback values and compare
	ldy		#$10000
	lda		#1
	swi
	fcb		MF_CRLF
dramtest3:
	deca
	bne		dramtest5
	tfr		y,d
	swi
	fcb		MF_DisplayWordAsHex
	ldb		#CR
	swi
	fcb		MF_OUTCH
dramtest5:
	cmpu	,y++
	bne		dramerr
	cmpy	#$E00000
	blo		dramtest3
	lda		#2
	sta		LEDS
	swi
	fcb		MF_Monitor
dramerr:
	lda		#$80
	sta		LEDS
	ldx		#TEXTSCR
	ldb		COREID
	abx
	lda		#'F'
	sta		,x
	swi
	fcb		MF_Monitor
