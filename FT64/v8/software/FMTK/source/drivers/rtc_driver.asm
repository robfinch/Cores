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
; Returns: r1 = 0 on success, otherwise non-zero
; Modifies: r1 and RTCBuf
; Stack space: 6 words
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

_rtc_read:
		push		lr
		push		$r3
		push		$a0
		push		$a1
		push		$a2
		push		$a3
		ldi			$a0,#I2C
		ldi			$a3,#_RTCBuf
		ldi			$r1,#$80
		sb			$r1,I2C_CTRL[$a0]	; enable I2C
		ldi			$a2,#$DE			; read address, write op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$00			; address zero
		ldi			$a1,#$10			; wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$DF			; read address, read op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		
		ldi			$r2,#$00
.0001:
		ldi			$r3,#$20
		sb			$r3,I2C_CMD[$a0]	; rd bit
		call		i2c_wait_tip
		call		i2c_wait_rx_nack
		memsb
		lb			$r1,I2C_STAT[$a0]
		bbs			$r1,#7,.rxerr
		memsb
		lb			$r1,I2C_RXR[$a0]
		sb			$r1,[$a3+$r2]
		add			$r2,$r2,#1
		slt			$r1,$r2,#$5F
		bne			$r1,$r0,.0001
		ldi			$r1,#$68
		sb			$r1,I2C_CMD[$a0]	; STO, rd bit + nack
		call		i2c_wait_tip
		memsb
		lb			$r1,I2C_STAT[$a0]
		bbs			$r1,#7,.rxerr
		memsb
		lb			$r1,I2C_RXR[$a0]
		sb			$r1,[$a3+$r2]
		mov			$r1,$r0						; return 0
.rxerr:
		sb			$r0,I2C_CTRL[$a0]	; disable I2C and return status
		lw			$a3,[sp]
		lw			$a2,8[sp]
		lw			$a1,16[sp]
		lw			$a0,24[sp]
		lw			$r3,32[sp]
		lw			lr,40[sp]
		ret			#48

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

_rtc_write:
		push		lr
		push		$r3
		push		$a0
		push		$a1
		push		$a2
		push		$a3
		ldi			$a0,#I2C
		ldi			$a3,#_RTCBuf
		ldi			$r1,#$80
		sb			$r1,I2C_CTRL[$a0]	; enable I2C
		ldi			$a2,#$DE			; read address, write op
		ldi			$a1,#$90			; STA + wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		ldi			$a2,#$00			; address zero
		ldi			$a1,#$10			; wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr

		ldi			$r2,#0
.0001:
		lb			$a2,[$a3+$r2]
		ldi			$a1,#$10
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		add			$r2,$r2,#1
		slt			$r1,$r2,#$5F
		bne			$r1,$r0,.0001
		lb			$a2,[$a3+$r2]
		ldi			$a1,#$50			; STO, wr bit
		call		i2c_wr_cmd
		bbs			$r1,#7,.rxerr
		mov			$r1,$r0						; return 0
.rxerr:
		sb			$r0,I2C_CTRL[$a0]	; disable I2C and return status
		lw			$a3,[sp]
		lw			$a2,8[sp]
		lw			$a1,16[sp]
		lw			$a0,24[sp]
		lw			$r3,32[sp]
		lw			lr,40[sp]
		ret			#48
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

