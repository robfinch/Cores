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
		sb		r2,txBuf+MSG_SRC
		lw		r2,[sp]
		add		sp,sp,#2
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
		add		sp,sp,#-4
		sw		r1,[sp]
		sw		r2,2[sp]
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
		lw		r2,2[sp]
		lw		r1,[sp]
		add		sp,sp,#4
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
		lw		r2,#15
Recv1:
		lb		r1,ROUTER[r2]			; copy message to local buffer
		sb		r1,rxBuf[r2]
		add		r2,r2,#-1
		bpl		Recv1
		lb		r1,ROUTER+RTR_RXSTAT
		or		r1,#$40
		sb		r1,ROUTER+RTR_RXSTAT	; pop the rx fifo
		lw		r1,[sp]
		lw		r2,2[sp]
		add		sp,sp,#4
		ret

