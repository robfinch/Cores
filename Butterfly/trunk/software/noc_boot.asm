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

MSG_DST		equ	15
MSG_SRC		equ	14
MSG_TTL		equ	9
MSG_TYPE	equ	8

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
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		and		r1,#63
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start
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
		lw		r1,#MT_RST_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatch5
RecvDispatch2:
		cmp		r1,#MT_PING
		bne		RecvDispatch9
		call	zeroTxBuf
		lb		r1,rxBuf+MSG_SRC
		sb		r1,txBuf+MSG_DST
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
		br		RecvDispatch5
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
		br		RecvDispatch5
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
		br		RecvDispatch5
RecvDispatch5:
RecvDispatchXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

		org		0xFFFE
		dw		start
