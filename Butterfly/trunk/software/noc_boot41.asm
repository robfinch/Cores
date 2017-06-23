; ============================================================================
;        __
;   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
;                                      
; This boot rom for node $411.
; $411 is dedicated to date/time services
; ============================================================================
;
CR	= 13
LF	= 10
CTRLH	equ		9
txBuf	equ		32
rxBuf	equ		48

#include "MessageTypes.asm"

ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_TXSTAT	equ	$12

ROUTER_TRB	equ	0

I2C_MASTER		EQU		$B300
I2C_PRESCALE_LO	EQU		I2C_MASTER+$00
I2C_PRESCALE_HI	EQU		I2C_MASTER+$01
I2C_CONTROL		EQU		I2C_MASTER+$02
I2C_TX			EQU		I2C_MASTER+$03
I2C_RX			EQU		I2C_MASTER+$03
I2C_CMD			EQU		I2C_MASTER+$04
I2C_STAT		EQU		I2C_MASTER+$04


MSG_DST		equ	15
MSG_SRC		equ	14
MSG_TTL		equ	9
MSG_TYPE	equ	8
MSG_GSD		equ	7

		bss
		org		$40
RTCBbuf	fill.b	64,0

		.code
		cpu		Butterfly16
		org		0xE000
#include "Network.asm"
#include "tb_worker.asm"

; Operation of an ordinary (worker) node is pretty simple. It just waits in
; loop polling for recieved messages which are then dispatched.

		.code
start:
		lw		sp,#$1FFE
		call	rtcInit
start2:
		lw		sp,#$1FFE
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		and		r1,#63
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start2
lockup:
		bra		lockup

;----------------------------------------------------------------------------
; Receiver dispatch
;
; Executes different message handlers based on the message type.
;----------------------------------------------------------------------------

RecvDispatch:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		lb		r1,rxBuf+MSG_TYPE
		cmp		r1,#MT_RST			; reset message ?
		bne		RecvDispatch2
		; Send back a reset ACK message to indicate node is good to go.
		call	zeroTxBuf
		lw		r1,#$11
		sb		r1,txBuf+MSG_DST
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_RST_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatch5
RecvDispatch2:
		cmp		r1,#MT_PING
		bne		RecvDispatch9
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,#$11
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_PING_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit
RecvDispatch9:
		cmp		r1,#MT_START_BASIC_LOAD	; start BASIC load
		bne		RecvDispatch3
		lb		r1,rxBuf+MSG_SRC
		call	INITTBW
		lw		r8,TXTBGN			; r8 = text begin
		br		RecvDispatchXit
RecvDispatch3:
		cmp		r1,#MT_LOAD_BASIC_CHAR	; load BASIC program char
		bne		RecvDispatch4
		lw		r1,rxBuf
		sw		r1,[r8]
		lw		r1,rxBuf+2
		sw		r1,2[r8]
		lw		r1,rxBuf+4
		sw		r1,4[r8]
		add		r8,r8,#6
		sw		r8,TXTUNF
		br		RecvDispatchXit
RecvDispatch4:
		; Run a BASIC program by stuffing a 'RUN' command into the BASIC
		; buffer.
		cmp		r1,#MT_RUN_BASIC_PROG
		bne		RecvDispatch5
		lw		r1,#'R'
		sb		r1,BUFFER
		lw		r1,#'U'
		sb		r1,BUFFER+1
		lw		r1,#'N'
		sb		r1,BUFFER+2
		lw		r1,#13
		sb		r1,BUFFER+3
		sb		r0,BUFFER+4
		lw		r8,#BUFFER+4
		call	ST3
		br		RecvDispatchXit

		; Load program code
RecvDispatch5:
		cmp		r1,#MT_LOAD_CODE
		br		RecvDispatchXit
		bne		RecvDispatch6
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit

		; Load program data
RecvDispatch6:
		cmp		r1,#MT_LOAD_CODE
		br		RecvDispatchXit
		bne		RecvDispatch7
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit
		; Load program code

		; Execute program
RecvDispatch7:
		cmp		r1,#MT_EXEC_CODE
		br		RecvDispatchXit
		bne		RecvDispatch8
		lw		r1,rxBuf+MSG_SRC
		add		sp,sp,#-2
		sw		r1,[sp]
		lw		r2,rxBuf+4
		call	[r2]
		lw		r2,[sp]
		add		sp,sp,#2
		call	zeroTxBuf
		sw		r1,txBuf+2
		sb		r2,txBuf+MSG_DST
		lw		r1,#$11
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_EXIT
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit

RecvDispatch8:
		; Process a request for the date/time
		cmp		r1,#MT_GET_DATETIME
		bne		RecvDispatch9
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,#$11
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_DATETIME_ACK
		sb		r1,txBuf+MSG_TYPE
		call	rtcRead
		lb		r1,RTCBuf+6
		sb		r1,txBuf+6
		lb		r1,RTCBuf+5
		sb		r1,txBuf+5
		lb		r1,RTCBuf+4
		sb		r1,txBuf+4
		call	Xmit
		br		RecvDispatchXit
RecvDispatch9:
RecvDispatchXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

;============================================================================
;============================================================================

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; RTC driver for MCP7941x
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

rtcInit:
		lw		r1,#28					; constant for 400kHz I2C from 57MHz
		sw		r1,I2C_PRESCALE_LO
		ret

; Read all the RTC sram registers into a buffer

rtcRead:
		add		sp,sp,#-2
		sw		lr,[sp]
		lw		r1,#$80				; enable I2C
		sb		r1,I2C_CONTROL
		lw		r1,#$DE				; read address, write op
		lw		r2,#$90				; STA + wr bit
		call	rtcWrCmd
		bmi		rtcReadErr
		lw		r1,#$00				; address zero
		lw		r2,#$10				; wr bit
		call	rtcWrCmd
		bmi		rtcReadErr
		lw		r1,#$DF				; read address, read op
		lw		r2,#$90				; STA + wr bit
		call	rtcWrCmd
		bmi		rtcReadErr
		lw		r3,#0
rtdRead1:
		lw		r1,#$20				; rd bit
		sb		r1,I2C_CMD
		call	rtcWaitTip
		lb		r1,I2C_STAT
		bmi		rtcReadErr
		lb		r1,I2C_RX
		sb		RTCBuf[r3]
		add		r3,r3,#1
		cmp		r3,#$5F
		bne		rtcRead1
		lw		r1,#$68				; STO, rd bit + nack
		sb		r1,I2C_CMD
		call	rtcWaitTip
		lb		r1,I2C_STAT
		bmi		rtcReadErr
		lb		r1,I2C_RX
		sb		r1,RTCBuf[r3]
		lw		r1,#0				; disable I2C and return 0
		sb		r1,I2C_CONTROL
		lw		lr,[sp]
		add		sp,sp,#2
		ret
rtcReadErr:
		sb		r0,I2C_CONTROL		; disable I2C and return status
		lw		lr,[sp]
		add		sp,sp,#2
		ret

rtcWaitTip:
rtcWaitTip1:
		lb		r1,I2C_STAT
		and		r1,#$4				; transmit in progress bit
		bne		rtcWaitTip
		ret

rtcWrCmd:
		sb		r1,I2C_TX
		sb		r2,I2C_CMD
		call	rtcWaitTip
		lb		r1,I2C_STAT
		ret

rtcWrite:
		add		sp,sp,#-2
		sw		lr,[sp]
		lw		r1,#$80				; enable I2C
		sb		r1,I2C_CONTROL
		lw		r1,#$DE				; read address, write op
		lw		r2,#$90				; STA + wr bit
		call	rtcWrCmd
		bmi		rtcWriteErr
		lw		r1,#$00				; address zero
		lw		r2,#$10				; wr bit
		call	rtcWrCmd
		bmi		rtcWriteErr
		lw		r3,#0
rtcWrite1:
		lb		r1,RTCBuf[r3]
		lw		r2,#$10
		call	rtcWrCmd
		bmi		rtcWriteErr
		add		r3,r3,#1
		cmp		r3,#$5F
		bne		rtcWrite1
		lb		r1,RTCBuf[r3]
		lw		r2,#$50				; STO, wr bit
		call	rtcWrCmd
		bmi		rtcWriteErr
		lw		r1,#0				; disable I2C and return 0
		sb		r1,I2C_CONTROL
		lw		lr,[sp]
		add		sp,sp,#2
		ret
rtcWriteErr:
		sb		r0,I2C_CONTROL		; disable I2C and return status
		lw		lr,[sp]
		add		sp,sp,#2
		ret

msgRtcReadFail:
	.byte	"RTC read/write failed.",$0D,$0A,$00


		org		0xFFFE
		dw		start
