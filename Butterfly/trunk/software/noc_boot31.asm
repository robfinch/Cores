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
; This boot rom for node $311.
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
RTR_RXCTL	equ	$11
RTR_TXSTAT	equ	$12

LEDS		equ	$B200

ROUTER_TRB	equ	0

MSG_DST		equ	14
MSG_SRC		equ	12
MSG_TTL		equ	9
MSG_TYPE	equ	8

ETHERNET	EQU		0xA000
ETH_MODER		EQU		0x00
ETH_INT_SOURCE	EQU		0x04
ETH_INT_MASK	EQU		0x08
ETH_IPGT		EQU		0x0C
ETH_IPGR1		EQU		0x10
ETH_IPGR2		EQU		0x14
ETH_PACKETLEN	EQU		0x18
ETH_COLLCONF	EQU		0x1C
ETH_TX_DB_NUM	EQU		0x20
ETH_CTRLMODER	EQU		0x24
ETH_MIIMODER	EQU		0x28
ETH_MIICOMMAND	EQU		0x2C
ETH_MIIADDRESS	EQU		0x30
ETH_MIITXDATA	EQU		0x34
ETH_MIIRXDATA	EQU		0x38
ETH_MIISTATUS	EQU		0x3C
ETH_MACADDR0	EQU		0x40
ETH_MACADDR1	EQU		0x44
ETH_HASH0_ADDR	EQU		0x48
ETH_HASH1_ADDR	EQU		0x4C
ETH_TXCTRL		EQU		0x50

eth_txbuf		EQU		$4000
eth_rxbuf		EQU		$6000

		bss
		org		$10
unique_id	dw	0

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
		call	ethInit
start2:
		lw		sp,#$1FFE
noMsg1:
		;call	ethPoll
		lb		r1,ROUTER+RTR_RXSTAT
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		start2

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
		lw		r1,#$111
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_RST_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit

		; Process PING request
RecvDispatch2:
		cmp		r1,#MT_PING
		bne		RecvDispatch9
		call	PingHandler
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
		bne		RecvDispatch6
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit

		; Load program data
RecvDispatch6:
		cmp		r1,#MT_LOAD_DATA
		bne		RecvDispatch7
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		br		RecvDispatchXit
		; Load program code

		; Execute program
RecvDispatch7:
		cmp		r1,#MT_EXEC_CODE
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
		sw		r2,txBuf+MSG_DST
		lw		r1,#MT_EXIT
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit

RecvDispatchXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

;============================================================================
;============================================================================

;----------------------------------------------------------------------------
; Initialize Ethernet controller.
;----------------------------------------------------------------------------

ethInit:
		lw		r5,#ETHERNET
		lw		r1,#20				; MII clock divider (2.5MHz from 50MHz)
		sw		r1,ETH_MIIMODER[r5]	; 32 bit preamble

		sw		r0,unique_id

		; Set the MAC address
		lw		r1,#$00FF
		sw		r1,ETH_MAC_ADDR1[r5]
		lw		r1,#$EEF0
		sw		r1,ETH_MAC_ADDR0+2[r5]
		lw		r1,#$DA42
		sw		r1,ETH_MAC_ADDR0[r5]

		; Set the PHY address
		lw		r1,#1				; this spec'd according to board
		sb		r1,ETH_MIIADDRESS[r5]
		lw		r1,#1				; select BMSR (status register)
		sb		r1,ETH_MIIADDRESS+1[r5]
		; MII should not be busy here, we haven't issued a command yet.
		lw		r2,#0
ethInit1:
		add		r2,r2,#1
		cmp		r2,#100
		bgtu	ethInitErr
		lw		r1,ETH_MIISTATUS[r5]
		and		r1,#2				; busy bit
		bne		ethInit1

		lw		r1,#2				; read status
		sb		r1,ETH_MIICOMMAND[r5]
ethInit4:
		lw		r1,#4
		lw		r2,#$101				; auto-neg. advertise 100MBs full duplex
		call	ethWriteMII

		lw		r1,#0					; perform software reset
		lw		r2,#$8000
		call	ethWriteMII

		lw		r1,#4
		lw		r2,#$101				; auto-neg. advertise 100MBs full duplex
		call	ethWriteMII

		lw		r1,#0					; select register #0 (BMCR)
		lw		r2,#$2100				; select 100MBPs, full duplex
		call	ethWriteMII

		; For green ethernet
		;
		;	reg		data
		;	31		$0003
		;	25		$3247
		;	16		$AC7C
		;	31		$0000
		lw		r1,#31
		lw		r2,#3
		call	ethWriteMII
		lw		r1,#25
		lw		r2,$3247
		call	ethWriteMII
		lw		r1,#16
		lw		r2,#$AC7C
		call	ethWriteMII
		lw		r1,#31
		lw		r2,#0
		call	ethWriteMII

		; setup receive buffer descriptor
		lw		r1,#eth_rxbuf		; set buffer address
		sw		r1,$A04[r5]
		sw		r0,$A06[r5]
		lw		r1,#$A000			; empty, wrap buffer
		sw		r1,$A00[r5]
		lw		r1,#$0800
		sw		r1,$A02[r5]

		lw		r1,#$A021			; enable recieve all frames
		sw		r1,ETH_MODER[r5]
ethInitErr:
		ret

;----------------------------------------------------------------------------
; Write to an MII register.
;
; Parameters:
;	r1 = register address
;	r2 = data for register
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

ethWriteMII:
		add		sp,sp,#-6
		sw		r3,[sp]
		sw		r5,2[sp]
		sw		r2,4[sp]
		lw		r5,#ETHERNET
		lw		r2,#0
ethWriteMII1:
		add		r2,r2,#1
		cmp		r2,#1000
		bgtu	ethWriteMIIErr
		lb		r3,ETH_MIISTATUS[r5]
		and		r3,#2				; busy bit
		bne		ethWriteMII1
		sb		r1,ETH_MIIADDRESS+1[r5]	; MII register number
		sw		r2,ETH_MIITX_DATA[r5]
		lw		r3,#4					; write control data
		sb		r3,ETH_MIICOMMAND[r5]
ethWriteMIIErr:
		lw		r3,[sp]
		lw		r5,2[sp]
		lw		r2,4[sp]
		add		sp,sp,#6
		ret


;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Poll for ethernet packets and send them to node $11
;
ethPoll:
		add		sp,sp,#-4
		sw		lr,[sp]
		lw		r1,$A00[r5]				; get BD status
		and		r1,#$8000
		bne		r1,r0,ethPoll3
		lw		r2,#0
		lw		r4,#0
		lw		r3,#eth_rxbuf
ethPoll2:
		call	zeroTxBuf
		mov		r5,r3
		add		r5,r4
		lw		r1,[r5]
		sw		r1,txBuf+2
		sw		r4,txBuf+4
		lw		r1,#$111
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_ETH_PACKET
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		add		r4,r4,#2
		add		r2,r2,#1
		cmp		r2,#2048
		bltu	ethPoll2
		br		ethPoll4				; for now
		lw		r1,#eth_rxbuf
		call	ethInterpretPacket
		cmp		r1,#1
		bne		ethPoll4
		lw		r1,#eth_rxbuf
		call	ethVerifyIP
		beq		ethPoll5
		lw		r1,#eth_rxbuf
		lw		r2,#1
		call	ethBuildPacket
		mov		r10,r1					; r10 = icmpstart
		lw		r4,#eth_rxbuf
		add		r4,r10
		sb		r0,[r4]
		lw		r4,#eth_rxbuf
		lb		r5,17[r4]				; r5 = len
		add		r5,r5,#14
		lw		r4,#eth_rxbuf
		add		r4,r10
		lb		r11,2[r4]
		lb		r12,3[r4]
		mov		r6,r12
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		shl		r11,#1
		or		r6,r11
		xor		r6,#-1
		sub		r6,r6,#$800
		xor		r6,#-1
		sb		r6,3[r4]
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		sb		r6,2[r4]
		lw		r1,#eth_rxbuf
		mov		r2,r10					; r2= icmpstart
		call	ethChecksum
		lw		r1,eth_rxbuf
		lw		r2,eth_txbuf
		mov		r3,r5					; r3 = len
		call	ethSendPacket
		;br
ethPoll4:
		cmp		r1,#2

		lw		r1,#$A000				; empty, wrap buffer
		sw		r1,$A00[r5]
		lw		r1,#$0800
		sw		r1,$A02[r5]
ethPoll3:
		lw		lr,[sp]
		add		sp,sp,#4
		ret

;----------------------------------------------------------------------------
; Detect what type of packet is received.
;----------------------------------------------------------------------------

ethInterpretPacket:
		mov		r2,r1
		lw		r1,12[r2]
		cmp		r1,#$0608				; 806 = ARP (big endian words)
		bne		ethInterpretPacket1
		lw		r1,#2
		ret
ethInterpretPacket1:
		cmp		r1,#$0008				; 800 = IP protocol
		bne		ethInterpretPacket2
		lb		r1,23[r2]
		cmp		r1,#1
		beq		ethInterpretPacketICMP
		cmp		r1,#$11
		beq		ethInterpretPacketUDP
		cmp		r1,#$06
		beq		ethInterpretPacketTCP
ethInterpretPacket2:
		lw		r1,#0
		ret
ethInterpretPacketICMP:
		lw		r1,#1;
		ret
ethInterpretPacketUDP:
		lw		r1,#3
		ret
ethInterpretPacketTCP:
		lw		r1,#4
		ret

;----------------------------------------------------------------------------
;
;----------------------------------------------------------------------------

ethSendPacket:
ethSendPacket1:
		lw		r1,ETHERNET+$800
		and		r1,#$8000			; wait for ready bit = 0
		bne		ethSendPacket1
		lw		r2,#eth_rxbuf
		lw		r3,#eth_txbuf
		lw		r4,#$800
		; Copy receive buffer to transmit buffer
ethSendPacket2:
		lw		r1,[r2]
		sw		r1,[r3]
		sub		r4,r4,#2
		bpl		ethSendPacket2
		lw		r1,#1				; clear transmit interrupt
		sb		r1,ETHERNET+ETH_INT_SOURCE
		lw		r1,#eth_txbuf
		sw		r1,ETHERNET+$804	; set buffer address in TxBD
		sw		r0,ETHERNET+$806
		lw		r1,#$0800
		sw		r1,ETHERNET+$802	; set packet length
		lw		r1,#$F000
		sw		r1,ETHERNET+$800	; 
ethSendPacket3:
		lw		r1,ETHERNET+ETH_INT_SOURCE
		and		r1,#1
		beq		ethSendPacket3
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

ethBuildPacket:
		mov		r4,r1
		mov		r5,r2
		; Read MAC address of source and copy to destination field
		lw		r1,6[r4]
		lw		r2,8[r4]
		lw		r3,10[r4]
		sw		r1,[r4]
		sw		r2,2[r4]
		sw		r3,4[r4]
		; Write MAC address to source field
		lw		r1,#$FF00
		lw		r2,#$F0EE
		lw		r3,#$42DA
		sw		r1,6[r4]
		sw		r2,8[r4]
		sw		r3,10[r4]
		; If swap IP address
		or		r5,r5
		beq		ethBuildPacket1
		lw		r1,26[r4]
		lw		r2,28[r4]
		lw		r6,30[r4]
		lw		r7,32[r4]
		sw		r6,26[r4]
		sw		r7,28[r4]
		sw		r1,30[r4]
		sw		r2,32[r4]
ethBuildPacket1:
		lw		r1,unique_id
		add		r1,r1,#1
		sw		r1,unique_id
		sb		r1,19[r4]
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		sb		r1,18[r4]

		; Get number of bytes in IP header
		lb		r1,14[r4]	; 
		and		r1,#$F
		shl		r1,#1		; *4
		shl		r1,#1
		add		r1,#14
		sw		r1,data_start
		ret

;----------------------------------------------------------------------------
; Compute checksum and insert into buffer
;
; Parameters:
;	r1 = buffer address
;	r2 = start of data
;----------------------------------------------------------------------------

ethChecksum:
		mov		r4,r1
		mov		r5,r2
		sw		r0,24[r4]
		lw		r6,#0		; r6 = sum
		lw		r11,#0		; r11 = sum[31:16]
		lw		r7,#14
		sub		r5,r5,#1	; r5 = data_start - 1
ethChecksum2:
		cmp		r7,r5
		bge		ethChecksum1
		mov		r8,r4
		add		r8,r7
		lb		r9,[r8]		; r9 = shi
		lb		r10,1[r8]	; r10 = slo
		zxb		r10
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		shl		r9,#1
		or		r10,r9
		add		r6,r10		; sum = sum + ((shi<<8)|slo)
		adc		r11,#0
		add		r7,r7,#2
		br		ethChecksum2
ethChecksum1:
		; add overflow bits (upper 16) to lower 16
		add		r6,r11
		xor		r6,#-1		; sum = ~sum
		sb		r6,25[r4]
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		shr		r6,#1
		sb		r6,24[r4]
		ret

;----------------------------------------------------------------------------
; Verify that the IP address is either a general broadcast address, or it
; matches our IP address.
;
; Parameters:
;	r1 = pointer to receive buffer
; Returns:
;	r1 = 1 if IP matches, 0 if no match
;----------------------------------------------------------------------------

ethVerifyIP:
		mov		r5,r1
		lb		r1,30[r5]
		lb		r2,31[r5]
		lb		r3,32[r5]
		lb		r4,33[r5]
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		or		r3,r4
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		or		r1,r2
		cmp		r1,#$FFFF
		bne		ethVerifyIP2
		cmp		r3,#$FFFF
		beq		ethVerifyIP3
ethVerifyIP2:
		cmp		r1,#$C0A8		; 192.168.
		bne		ethVerifyIP1
		cmp		r3,#$012A		; 1.42
		bne		ethVerifyIP1
ethVerifyIP3:
		lw		r1,#1
		ret
ethVerifyIP1:
		lw		r1,#0
		ret

		org		0xFFFE
		dw		start
