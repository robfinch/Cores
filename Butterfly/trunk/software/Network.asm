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
; Networking software components
; ============================================================================
;

;----------------------------------------------------------------------------
; Zero out the transmit buffer.
; Used before building transmit buffer.
; Automatically inserts a time-to-live of 63, and the source id.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

zeroTxBuf:
		add		sp,sp,#-2
		sw		r2,[sp]
		lw		r2,#15
zeroTxBuf1:
		sb		r0,txBuf[r2]
		sub		r2,r2,#1
		bpl		zeroTxBuf1
		lw		r2,#63
		sb		r2,txBuf+MSG_TTL
		tsr		r2,ID
		sw		r2,txBuf+MSG_SRC	; X+Y
		lw		r2,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Set the destination address field in the transmit buffer based on the
; source address in the receive buffer.
;----------------------------------------------------------------------------

SetDestFromRx:
		lw		r1,rxBuf+MSG_SRC
		sw		r1,txBuf+MSG_DST
		ret

;----------------------------------------------------------------------------
; Transmit on the network.
; Blocks until the transmit buffer is open.
;
; Prerequisites:
;	The transmit buffer txBuf must have already been loaded.
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

Xmit:	
		add		sp,sp,#-6
		sw		r1,[sp]
		sw		r2,2[sp]
		sw		r3,4[sp]
		; wait for transmit buffer to empty
		; If transmit buffer empty signal times out, transmit anyway
		; @100Mb/s 128 bits should transmit in only about 128 clock cycles.
		lw		r3,#0
Xmit2:
		add		r3,r3,#1
		cmp		r3,#50
		nop
		bgtu	Xmit1
		lb		r1,ROUTER+RTR_TXSTAT
		nop
		bne		Xmit2
		lw		r2,#15
Xmit1:
		lb		r1,txBuf[r2]
		sb		r1,ROUTER[r2]
		add		r2,r2,#-1
		nop
		bpl		Xmit1
		; trigger a transmit, writing any value will set the transmitter busy bit
		sb		r0,ROUTER+RTR_TXSTAT
		lw		r1,[sp]
		lw		r2,2[sp]
		lw		r3,4[sp]
		add		sp,sp,#6
		ret

;----------------------------------------------------------------------------
; Receive from network.
; Receive status must have already indicated a message present.
; Copies recieve buffer from router to rxBuf.
; The router fifo is configured with first word fall-through. This means
; the data word appears on the fifo output before the fifo is popped.
; A fifo pop signal has to be sent after reading the data.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

Recv:
		add		sp,sp,#-4
		sw		r1,[sp]
		sw		r2,2[sp]
		; Pop the rx fifo.
		; This bit $40 should automatically clear so we don't need to
		; set it back to zero.
		lb		r1,ROUTER+RTR_RXCTL
		or		r1,#$40
		sb		r1,ROUTER+RTR_RXCTL
		and		r1,#$BF
		sb		r1,ROUTER+RTR_RXCTL
		lw		r2,#15
Recv1:
		lb		r1,ROUTER[r2]			; copy message to local buffer
		sb		r1,rxBuf[r2]
		add		r2,r2,#-1
		bpl		Recv1
		lw		r1,[sp]
		lw		r2,2[sp]
		add		sp,sp,#4
		ret

;----------------------------------------------------------------------------
; Handler for the ping function. A pink acknowledge message is sent back
; to the sender.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

PingHandler:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,#MT_PING_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret
