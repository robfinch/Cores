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

;===============================================================================
; Realtime clock routines
;===============================================================================

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read the real-time-clock chip.
;
; The entire contents of the clock registers and sram are read into a buffer
; in one-shot rather than reading the registers individually.
;
; Parameters: none
; Returns: d = 0 on success, otherwise non-zero
; Modifies: d and RTCBuf
; Stack space: 6 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rtc_read:
	ldx			#RTC
	ldy			#RTCBuf
	ldb			#$80
	stb			I2C_CTRL,x		; enable I2C
	ldd			#$900DE				; read address, write op, STA + wr bit
	bsr			i2c_wr_cmd
	bitb		#$80
	bne			rtc_rxerr
	ldd			#$10000				; address zero, wr bit
	bsr			i2c_wr_cmd
	bitb		#$80
	bne			rtc_rxerr
	ldd			#$900DF				; read address, read op, STA + wr bit
	bsr			i2c_wr_cmd
	bitb		#$80
	bne			rtc_rxerr
	
	clrb
rtcr0001:
	lda			#$20
	sta			I2C_CMD,x			; rd bit
	bsr			i2c_wait_tip
	bsr			i2c_wait_rx_nack
	lda			I2C_STAT,x
	bita		#$80
	bne			rtc_rxerr
	lda			I2C_RXR,x
	sta			b,y
	incb
	cmpb		#$5F
	blo			rtcr0001
	lda			#$68
	sta			I2C_CMD,x			; STO, rd bit + nack
	bsr			i2c_wait_tip
	lda			I2C_STAT,x
	bita		#$80
	bne			rtc_rxerr
	lda			I2C_RXR,x
	sta			b,y
	clrd									; return 0
rtc_rxerr:
	clr			I2C_CTRL,x	; disable I2C and return status
	clra
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write the real-time-clock chip.
;
; The entire contents of the clock registers and sram are written from a 
; buffer (RTCBuf) in one-shot rather than writing the registers individually.
;
; Parameters: none
; Returns: r1 = 0 on success, otherwise non-zero
; Modifies: r1 and RTCBuf
; Stack space: 6 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rtc_write:
	ldx		#RTC
	ldy		#RTCBuf
	
	ldb		#$80
	stb		I2C_CTRL,x		; enable I2C
	ldd		#$900DE				; read address, write op, STA + wr bit
	bsr		i2c_wr_cmd
	bitb	#$80
	bne		rtc_rxerr
	ldd		#$10000				; address zero, wr bit
	bsr		i2c_wr_cmd
	bitb	#$80
	bne		rtc_rxerr

	ldb		#0
rtcw0001:
	pshs	b
	ldb		b,y
	lda		#$10
	bsr		i2c_wr_cmd
	bitb	#$80
	puls	b
	bne		rtc_rxerr
	incb
	cmpb	#$5F
	blo		rtcw0001
	ldb		b,y
	lda		#$50					; STO, wr bit
	bsr		i2c_wr_cmd
	bitb	#$80
	bne		rtc_rxerr
	clrd								; return 0
	clr		I2C_CTRL,x		; disable I2C and return status
	rts
