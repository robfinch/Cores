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
nDCB	equ		2
CR	= 13
LF	= 10
nDCB    equ		2
CTRLH	equ		9
txBuf	equ		32
rxBuf	equ		48

#include "MessageTypes.asm"
#include "DeviceDriver.inc"

ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_RXCTL	equ	$11
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


MSG_DST		equ	14
MSG_SRC		equ	12
MSG_TTL		equ	9
MSG_TYPE	equ	8

		bss
		org		$40
RTCBuf	fill.b	64,0
		align	2
NodeDCB				fill.b	DCB_Size,0
RTCControlBlock		fill.b	DCB_Size,0
RTCPos	dw		0

		.code
		cpu		Butterfly16
		org		0xE000
#include "Network.asm"
#include "Node.asm"
#include "tb_worker.asm"

; Operation of an ordinary (worker) node is pretty simple. It just waits in
; loop polling for recieved messages which are then dispatched.

		.code
start:
		lw		sp,#$1FFE
		call	ResetNode
start2:
		lw		sp,#$1FFE
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start2

;----------------------------------------------------------------------------
; Reset the node.
;----------------------------------------------------------------------------

ResetNode:
		add		sp,sp,#-2
		sw		lr,[sp]
		call	CpyDCB
		call	rtcInit
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Copy the DCB tables to ram.
;----------------------------------------------------------------------------

CpyDCB:
		lw		r3,#0
CpyDCB1:
		lw		r1,DCBTbl[r3]
		sw		r1,NodeDCB[r3]
		add		r3,r3,#2
		cmp		r3,#48*nDCB
		bltu	CpyDCB1
		ret

;----------------------------------------------------------------------------
; Message command processor for node.
;
; Executes different message handlers based on the message type.
;----------------------------------------------------------------------------

NodeCmdProc:
		add		sp,sp,#-8
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]

		call	StdMsgHandlers

		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		add		sp,sp,#8
		ret

;============================================================================
;============================================================================

RTCCmdProc:
		sub		sp,sp,#2
		sw		lr,[sp]
		lb		r1,rxBuf+MSG_TYPE
		cmp		r1,#DVC_Initialize
		beq		RTCCmdProcInitialize
		cmp		r1,#DVC_SetPosition
		beq		RTCCmdProcSetPosition
		cmp		r1,#DVC_ReadBlock
		beq		RTCCmdProcReadBlock
		cmp		r1,#DVC_WriteBlock
		beq		RTCCmdProcWriteBlock
RTCCmdProcXit:
		lw		lr,[sp]
		add		sp,sp,#2
		ret

RTCCmdProcInitialize:
		call	rtcInit
		call	rtcRead
		br		RTCCmdProcXit

RTCCmdProcReadBlock:
		lw		r2,RTCPos
		cmp		r2,#$8000
		beq		RTCGetDateTime
		cmp		r2,#0
		beq		RTCCmdProcReadBlock1
		br		RTCCmdProcXit
		lw		r2,#0
RTCCmdProcReadBlock1:
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,RTCBuf[r2]
		sw		r1,txBuf
		lw		r1,RTCBuf+2[r2]
		sw		r1,txBuf+2
		sw		r2,txBuf+4
		lw		r1,#MT_DATA
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		add		r2,r2,#4
		cmp		r2,#64
		bltu	RTCCmdProcReadBlock1
		br		RTCCmdProcXit

RTCCmdProcWriteBlock:
		br		RTCCmdProcXit

RTCCmdProcSetPosition:
		lw		r1,rxBuf
		sw		r1,RTCPos
		br		RTCCmdProcXit

RTCGetDateTime:
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,#$11
		sb		r1,txBuf+MSG_GDS
		lw		r1,#MT_DATA
		sb		r1,txBuf+MSG_TYPE
		call	rtcRead
		lb		r1,RTCBuf+6
		sb		r1,txBuf+6
		lb		r1,RTCBuf+5
		sb		r1,txBuf+5
		lb		r1,RTCBuf+4
		sb		r1,txBuf+4
		call	Xmit
		br		RTCCmdProcXit

;============================================================================
;============================================================================

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; RTC driver for MCP7941x
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Initialize the I2C controller. Not much to do here other than set the
; I2C frequency control.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	r1
;----------------------------------------------------------------------------

rtcInit:
		lw		r1,#28					; constant for 400kHz I2C from 57MHz
		sw		r1,I2C_PRESCALE_LO
		ret

;----------------------------------------------------------------------------
; Read all the RTC sram registers into a buffer.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	r1,r2,r3
;----------------------------------------------------------------------------

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
rtcRead1:
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

;----------------------------------------------------------------------------
; Wait for the I2C transfer to complete. Determined by polling the transfer
; in progress bit of the status register.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	r1
;----------------------------------------------------------------------------
	
rtcWaitTip:
rtcWaitTip1:
		lb		r1,I2C_STAT
		and		r1,#$4				; transmit in progress bit
		bne		rtcWaitTip
		ret

;----------------------------------------------------------------------------
; Write a command to the I2C controller.
;
; Parameters:
;	r1 = byte to transfer to I2C slave
;	r2 = command code for I2C master
; Returns:
;	r1 = I2C status
;	flags set according to I2C status
; Registers Affected:
;	r1
;----------------------------------------------------------------------------

rtcWrCmd:
		add		sp,sp,#-2
		sw		lr,[sp]
		sb		r1,I2C_TX
		sb		r2,I2C_CMD
		call	rtcWaitTip
		lb		r1,I2C_STAT
		lw		lr,[sp]
		add		sp,sp,#2
		or		r1,r1
		ret

;----------------------------------------------------------------------------
; Write buffer contents back to RTC chip.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	r1,r2,r3
;----------------------------------------------------------------------------

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

	align	2
DCBTbl:
	db	6,"NOD411",0,0,0,0,0
	dw	0						; type
	dw  0						; nBPB
	dw	0						; LastErc
	dw	0						; reserved
	dw	0						; start block low
	dw	0						; start block high
	dw	0						; number of blocks
	dw	0						;	"
	dw	NodeCmdProc				; pCmdProc
	dw	0						; reserved
	db	0						; reentry count
	db	0						; single user flag
	dw	0						; hJob
	dw	0						; hMbx
	dw	0						; hSemaphore
	fill.b	8,0					; reserved
		
	db	3,"RTC",0,0,0,0,0,0,0,0
	dw	0						; type
	dw  0						; nBPB
	dw	0						; LastErc
	dw	0						; reserved
	dw	0						; start block low
	dw	0						; start block high
	dw	0						; number of blocks
	dw	0						;	"
	dw	RTCCmdProc				; pCmdProc
	dw	0						; reserved
	db	0						; reentry count
	db	0						; single user flag
	dw	0						; hJob
	dw	0						; hMbx
	dw	0						; hSemaphore
	fill.b	8,0					; reserved


		org		0xFFFE
		dw		start
