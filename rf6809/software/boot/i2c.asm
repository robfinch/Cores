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
;===============================================================================
; Generic I2C routines
;
; It is assumed there may be more than one I2C controller in the system, so
; the address of the controller is passed in the X register.
;===============================================================================

I2C_PREL	EQU		$0
I2C_PREH	EQU		$1
I2C_CTRL	EQU		$2
I2C_RXR		EQU		$3
I2C_TXR		EQU		$3
I2C_CMD		EQU		$4
I2C_STAT	EQU		$4

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; i2c initialization, sets the clock prescaler
;
; Parameters:
;		x = I2C controller address
; Returns: none
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_init:
	pshs	b
	ldb		#4									; setup prescale for 400kHz clock
	stb		I2C_PREL,x
	clr		I2C_PREH,x
	puls	b,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Wait for I2C transfer to complete
;
; Parameters
; 	x - I2C controller base address
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wait_tip:
	pshs		b
i2cw1:
	ldb			I2C_STAT,x		; would use lvb, but lb is okay since its the I/O area
	bitb		#1						; wait for tip to clear
	bne			i2cw1
	puls		b,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write command to i2c
;
; Parameters
;		accb - data to transmit
;		acca - command value
;		x 	- I2C controller base address
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wr_cmd:
	stb		I2C_TXR,x
	sta		I2C_CMD,x
	bsr		i2c_wait_tip
	ldb		I2C_STAT,x
	rts

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Parameters
;		x - I2C controller base address
;		accb - data to send
; Returns: none
; Stack space: 2 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_xmit1:
	pshs	d								; save data value
	pshs	d								; and save it again
	ldb		#1
	stb		I2C_CTRL,x			; enable the core
	ldb		#$76						; set slave address = %0111011
	lda		#$90						; set STA, WR
	bsr		i2c_wr_cmd
	bsr		i2c_wait_rx_nack
	puls	d								; get back data value
	lda		#$50						; set STO, WR
	bsr		i2c_wr_cmd
	bsr		i2c_wait_rx_nack
	puls	d,pc

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

i2c_wait_rx_nack:
	pshs	b								; save off accb
i2cwr1:
	ldb		I2C_STAT,x			; wait for RXack = 0
	bitb	#$80						; test for nack
	bne		i2cwr1
	puls	b,pc

