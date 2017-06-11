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

ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_TXSTAT	equ	$12

ROUTER_TRB	equ	0

		.code
		cpu		Butterfly16
		org		0xE000
start:
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start
lockup:
		bra		lockup

;----------------------------------------------------------------------------
; Broadcast a reset message on the network.
;----------------------------------------------------------------------------

broadcastReset:
		add		sp,sp,#-2
		sw		lr,[sp]
		call	zeroTxBuf
		lw		r1,#$FF		; global broadcast address
		sb		r1,txBuf+15
		lw		r1,#$11		; source of message
		sb		r1,txBuf+14
		lw		r1,#1
		sb		r1,txBuf+8	; reset message
		call	Xmit
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Transmit on the network.
;----------------------------------------------------------------------------

Xmit:
		; wait for transmit buffer to empty
Xmit2:
		lb		r1,ROUTER+RTR_TXSTAT
		bne		Xmit2
		lw		r2,#15
Xmit1:
		lb		r1,txBuf[r2]
		sb		r1,ROUTER[r2]
		add		r2,r2,#-1
		bpl		Xmit1
		; trigger a transmit
		lw		r1,#1
		sb		r2,ROUTER+RTR_TXSTAT
		ret

;----------------------------------------------------------------------------
; Receive from network.
; Receive status must have already indicated a message present.
;----------------------------------------------------------------------------

Recv:
		lw		r1,#1
		sb		r1,ROUTER+RTR_RXSTAT	; pop the rx fifo
		lw		r2,#15
Recv1:
		lb		r1,ROUTER[r2]			; copy message to local buffer
		sb		r1,rxBuf[r2]
		add		r2,r2,#-1
		bpl		Recv1
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

RecvDispatch:
		add		sp,sp,#-2
		sw		lr,[sp]
		lb		r1,rxBuf+8
		cmp		r1,#1
		bne		RecvDispatch2
		call	zeroTxBuf
		tsr		r1,ID
		sb		r1,txBuf+14
		lw		r1,#$11
		sb		r1,txBuf+15
		lw		r1,#2
		sb		r1,txBuf+8
		call	Xmit
RecvDispatch2:
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Zero out the transmit buffer.
;----------------------------------------------------------------------------

zeroTxBuf:
		lw		r2,#15
zeroTxBuf1:
		sb		r0,txBuf[r2]
		sub		r2,r2,#1
		bpl		zeroTxBuf1
		ret

		org		0xFFFE
		dw		start
