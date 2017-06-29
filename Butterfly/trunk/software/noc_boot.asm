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
; This boot rom for an ordinary node.
; ============================================================================
;
nDCB	equ		1
CR	= 13
LF	= 10
CTRLH	equ		9

#include "MessageTypes.asm"
#include "DeviceDriver.inc"

		bss
		org		0x0040
txBuf	fill.b	16,0
rxBuf	fill.b	16,0
kbdbuf	fill.w	16,0
		align	2
NodeDCB		fill.b	DCB_Size,0

ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_RXCTL	equ	$11
RTR_TXSTAT	equ	$12

ROUTER_TRB	equ	0

MSG_DST		equ	14
MSG_SRC		equ	12
MSG_TTL		equ	9
MSG_TYPE	equ	8

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
		lw		sp,#$1FFE				; set stack pointer
		call	ResetNode
start2:
		lw		sp,#$1FFE				; set stack pointer
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT	; get the receive status
		beq		noMsg1					; is there a message ?
		call	Recv					; copy the receive message to local buf
		call	RecvDispatch			; dispatch to a handler based on type
		br		start2					; go back and repeat the process

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

ResetNode:
		add		sp,sp,#-8
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]
		call	CpyDCB
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		add		sp,sp,#8
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
		cmp		r3,#48
		bltu	CpyDCB1
		; Set the DCB name field
		tsr		r1,ID
		mov		r2,r1
		and		r2,#$F
		or		r2,#'0'
		sb		r2,NodeDCB+DCB_Name+6
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		mov		r2,r1
		and		r2,#$F
		or		r2,#'0'
		sb		r2,NodeDCB+DCB_Name+5
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		mov		r2,r1
		and		r2,#$F
		or		r2,#'0'
		sb		r2,NodeDCB+DCB_Name+4
		ret

;----------------------------------------------------------------------------
; Node's Command Processor
;
; Executes different message handlers based on the message type.
;----------------------------------------------------------------------------

NodeCmdProc:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]

		call	StdMsgHandlers

NodeCmdProcXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

; In the works:
; Table based message type dispatcher
;
		lw		r2,#0
Dispatch2:
		lw		r3,TabReqHandle[r2]
		beq		DispatchBadHandle
		cmp		r1,r3
		bne		Dispatch1
		lw		r1,TabHandlerAddr[r2]
		call	[r1]
		br		DispatchXit
Dispatch1:
		add		r2,r2,#2
		cmp		r2,#400
		bltu	Dispatch2
DispatchBadHandle:
DispatchXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

	align	2
DCBTbl:
	db	6,"NODxxx",0,0,0,0,0
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
		

		align	2

TabReqHandle:
		dw		MT_RST
		dw		MT_PING
		dw		MT_LOAD_CODE
		dw		0

		org		0xFE00
TabHandlerAddr
		dw		RstHandler
		dw		PingHandler
		dw		CodeLoadHandler

		org		0xFFFE
		dw		start
