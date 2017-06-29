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
; This boot rom for the special node $111. This node is responsible for
; bringing the system up, and controls the text display and leds.
; ============================================================================
;
nDCB	equ		3
CR	= 13
LF	= 10
CTRLH	equ		8

#include "MessageTypes.asm"
#include "DeviceDriver.inc"

		bss
		org		0x0040
txBuf	fill.b	16,0
rxBuf	fill.b	16,0
kbdbuf	fill.w	16,0
kbdhead	db	0
kbdtail	db	0
kbdcnt	db	0
pingcnt		dw	0
FocusHead	db	0
FocusTbl	fill.b	64,0
		align	2
NodeDCB		fill.b	DCB_Size,0
TextDCB		fill.b	DCB_Size,0
LedsDCB		fill.b	DCB_Size,0
DevList		fill.b	16*88,0
DevListNdx	dw	0

		align	2
HTFocus		dw		0
packetPtr	dw		0
pingndx		db		0

TXTSCR		equ	$2000
TXTCTRL		equ	$B100
LEDS		equ	$B200
ROUTER		equ	$B000
RTR_RXSTAT	equ	$10
RTR_RXCTL	equ	$11
RTR_TXSTAT	equ	$12

MSG_DST		equ	14
MSG_SRC		equ	12
MSG_TTL		equ	9
MSG_TYPE	equ	8

ROUTER_TRB	equ	0

		.code
		cpu		Butterfly16
		.org	$C000
#include "Network.asm"
#include "Node.asm"
#include "tb.asm"
		.code
		.org	$D800
start:
		tsr		r1,ID		; id register
		sb		r1,LEDS
		lw		sp,#$1FFE
		call	ResetNode
;		lw		r1,#$80					; set router in snoop mode
;		sb		r1,ROUTER+RTR_RXCTL
		;call	broadcastReset
start2:
		lw		r1,#$80					; set router in non-snoop mode
		sb		r1,ROUTER+RTR_RXCTL
		tsr		r1,ID
		cmp		r1,#$111
		bne		RecvLoop
		call	ping44
		call	ReqEnumDevices
		lw		r1,#5
		sb		r1,LEDS
		jmp		CSTART
RecvLoop:
noMsg1:
		lb		r1,ROUTER+RTR_RXSTAT
		beq		noMsg1
		call	Recv
		call	RecvDispatch
		bra		RecvLoop

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

ResetNode:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		call	CpyDCB
		sw		r0,DevListNdx
		sb		r0,kbdhead
		sb		r0,kbdtail
		sb		r0,kbdcnt
		sw		r0,pingcnt
		sb		r0,pingndx
		lw		r2,#TXTSCR+3120
		sw		r2,packetPtr
		lw		r1,#1
		sb		r1,FocusTbl
		call	InitTxtCtrl
		lw		r1,#4
		sb		r1,LEDS
		lw		r1,#31
		sb		r1,txtHeight
		lw		r1,#52
		sb		r1,txtWidth
		lw		r1,#$BF00
		sw		r1,NormAttr
		call	ClearScreen
		call	HomeCursor
		lw		r1,#msgStarting
		call	putmsgScr
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
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
; Broadcast a reset message on the network.
;----------------------------------------------------------------------------

broadcastReset:
		add		sp,sp,#-2
		sw		lr,[sp]
		call	zeroTxBuf
		lw		r1,#$FFF		; global broadcast address
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_RST
		sb		r1,txBuf+MSG_TYPE	; reset message
		call	Xmit
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
;----------------------------------------------------------------------------

ReqEnumDevices:
		add		sp,sp,#-6
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		lw		r2,#0
ReqEnumDevices2:
		lb		r1,NodeNumTbl[r2]
		and		r1,#$0F
		cmp		r1,#$08
		beq		ReqEnumDevices1
		call	zeroTxBuf
		lb		r1,NodeNumTbl[r2]
		zxb		r1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		or		r1,#1
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_ENUM_DEVICES
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
ReqEnumDevices1:
		lb		r1,ROUTER+RTR_RXSTAT
		beq		ReqEnumDevices3
		call	Recv
		call	RecvDispatch
ReqEnumDevices3:
		add		r2,r2,#1
		cmp		r2,#63
		bltu	ReqEnumDevices2
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		add		sp,sp,#6
		ret

;----------------------------------------------------------------------------
; Ping all the nodes to ensure everything is okay.
;----------------------------------------------------------------------------

ping44:
		add		sp,sp,#-6
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		lb		r2,pingndx
		sw		r2,2[sp]
		lb		r1,NodeNumTbl[r2]
		and		r1,#$0F
		cmp		r1,#$08				; x8 nodes aren't present anymore
		beq		ping442
		call	zeroTxBuf
		lb		r1,NodeNumTbl[r2]
		zxb		r1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		shl		r1,#1
		or		r1,#1
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_PING
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
ping442:
		lw		r2,2[sp]
		add		r2,r2,#1
		cmp		r2,#63
		bltu	ping441
		lw		r2,#0
ping441:
		sb		r2,pingndx
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		add		sp,sp,#6
		ret

NodeNumTbl:
	db	$11,$12,$13,$14,$15,$16,$17,$18	
	db	$21,$22,$23,$24,$25,$26,$27,$28	
	db	$31,$32,$33,$34,$35,$36,$37,$38	
	db	$41,$42,$43,$44,$45,$46,$47,$48	
	db	$51,$52,$53,$54,$55,$56,$57,$58	
	db	$61,$62,$63,$64,$65,$66,$67,$68	
	db	$71,$72,$73,$74,$75,$76,$77,$78	
	db	$81,$82,$83,$84,$85,$86,$87,$88	

;----------------------------------------------------------------------------
; Test if it's time to do a ping message. All the nodes are pinged
; periodically to ensure the network is working.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------
		align	2
DoPing:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		lw		r1,pingcnt
		add		r1,r1,#1
		sw		r1,pingcnt
		cmp		r1,#800
		bltu	DoPingNoPing
		sw		r0,pingcnt
		call	ping44
DoPingNoPing:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

;----------------------------------------------------------------------------
; Command processor for the node.
;----------------------------------------------------------------------------

NodeCmdProc:
		add		sp,sp,#-8
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]
		cmp		r1,#MT_RST_ACK	; status display ?
		bne		NodeCmdProc2
RecvPingAck:
		lw		r1,rxBuf+MSG_SRC; message source
		mov		r2,r1
		and		r2,#$0F0		; get Y coord
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		lw		r2,lineTbl[r2]
		add		r2,r2,#86		; position table along right edge of screen
		mov		r3,r1			; r3 = ID
		shr		r3,#1			; set r3 = X coord
		shr		r3,#1
		shr		r3,#1
		shr		r3,#1
		shr		r3,#1
		shr		r3,#1
		shr		r3,#1
		shr		r3,#1
		shl		r3,#1			; character screen pos = *2
		and		r3,#$1E
		add		r3,r2
		;lw		r1,#'*'
		;call	AsciiToScreen
		;lw		r2,NormAttr
		;or		r1,r2
		lw		r1,TXTSCR[r3]
		add		r1,r1,#1
		sw		r1,TXTSCR[r3]
		bra		NodeCmdProcXit
NodeCmdProc2:
NodeCmdProc10:
		cmp		r1,#MT_PING_ACK
		beq		RecvPingAck
		cmp		r1,#MT_KEYSTROKE
		beq		RecvKeystroke
		cmp		r1,#MT_ETH_PACKET
		beq		RecvEthPacket
		cmp		r1,#MT_ENUM_DEVICES1
		beq		NodeCmdProcEnumDevices1
		cmp		r1,#MT_ENUM_DEVICES2
		beq		NodeCmdProcEnumDevices2
		cmp		r1,#MT_REQ_OUT_FOCUS
		bne		NodeCmdProc3
		lw		r1,rxBuf+MSG_SRC
		mov		r2,r1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		sub		r1,r1,#1
		and		r1,#$7
		sub		r2,r2,#$100
		and		r2,#$700
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		shr		r2,#1
		or		r1,r2
		lw		r2,#1
		sb		r2,FocusTbl[r1]
		lw		r1,HTFocus
		bne		NodeCmdProc3
		lw		r1,rxBuf+MSG_SRC
		sw		r1,HTFocus
		br		NodeCmdProcXit

NodeCmdProc3:
		cmp		r1,#MT_NEXT_IOFOCUS
		bne		NodeCmdProc8
		call	SetNextFocus
		br		NodeCmdProcXit

NodeCmdProc8:
		cmp		r1,#DVC_PutChar
		beq		RecvKeystroke

		call	StdMsgHandlers

NodeCmdProc12:
NodeCmdProcXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		add		sp,sp,#8
		ret

		; Process a keystroke message from node $21
RecvKeystroke:
		lw		r1,#8
		sb		r1,LEDS
		lb		r1,kbdcnt
		cmp		r1,#15
		bge		kbdfull
		add		r1,r1,#1
		sb		r1,kbdcnt
		lb		r2,kbdhead
		lb		r1,rxBuf+2
		sb		r1,kbdbuf[r2]
		lb		r1,rxBuf+1
		sb		r1,kbdbuf+1[r2]
		add		r2,r2,#2
		and		r2,#30
		sb		r2,kbdhead
kbdfull:
		br		NodeCmdProcXit

RecvEthPacket:
		lw		r1,rxBuf+2
		lw		r2,packetPtr
		sw		r1,[r2]
		add		r2,r2,#2
		cmp		r2,#TXTSCR+3224
		bltu	RecvEthPacket1
		lw		r2,#TXTSCR+3120
RecvEthPacket1:
		sw		r2,packetPtr
		br		NodeCmdProcXit

NodeCmdProcEnumDevices1:
		lw		r2,DevListNdx
		lw		r1,rxBuf
		sw		r1,DevList[r2]
		lw		r1,rxBuf+2
		sw		r1,DevList+2[r2]
		lw		r1,rxBuf+4
		sw		r1,DevList+4[r2]
		lw		r1,rxBuf+6
		sw		r1,DevList+6[r2]
		br		NodeCmdProcXit

NodeCmdProcEnumDevices2:
		lw		r2,DevListNdx
		lw		r1,rxBuf
		sw		r1,DevList+8[r2]
		lw		r1,rxBuf+2
		sw		r1,DevList+10[r2]
		lw		r1,rxBuf+4
		sw		r1,DevList+12[r2]
		lw		r1,rxBuf+6
		sw		r1,DevList+14[r2]
		mov		r4,r2
		add		r2,r2,#16
		sw		r2,DevListNdx
		; Now display the device number and name on screen
		lw		r1,DevList[r4]
		call	DispWord
		call	DispSpace
		lb		r3,DevList+2[r4]	; length of string
NodeCmdProcEnumDevices3:
		lb		r1,DevList+3[r4]
		call	putcharScr
		add		r4,r4,#1
		cmp		r4,r3
		bltu	NodeCmdProcEnumDevices3
		call	DispSpace
		call	DispSpace
		br		NodeCmdProcXit

;----------------------------------------------------------------------------
; Set the IO focus to the next node requesting focus.
;----------------------------------------------------------------------------

SetNextFocus:
		add		sp,sp,#-2
		sw		lr,[sp]
		lw		r5,#0
		lw		r2,#FocusTbl
		lw		r3,FocusHead
SetNextFocus1:
		add		r5,r5,#1
		cmp		r5,#64
		bgtu	SetFocusNextXit
		add		r3,r3,#1
		cmp		r3,#63
		bleu	SetNextFocus2
		lw		r3,#0
SetNextFocus2:
		mov		r4,r2
		add		r4,r3
		lb		r1,[r4]
		beq		SetNextFocus1
		sb		r3,FocusHead
		lb		r3,NodeNumTbl[r3]
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		shl		r3,#1
		or		r3,#1
		sw		r3,HTFocus
		call	zeroTxBuf
		sw		r3,txBuf
		lw		r1,#MT_SET_IOFOCUS
		sb		r1,txBuf+MSG_TYPE
		lw		r1,#$211
		sw		r1,txBuf+MSG_DST
		call	Xmit
SetFocusNextXit:
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Initialize the text controller.
;----------------------------------------------------------------------------

InitTxtCtrl:
		lw		r1,#2
		sb		r1,LEDS
		lw		r2,#0
itc1:
		lb		r1,txtctrl_dat[r2]
		sb		r1,TXTCTRL[r2]
		add		r2,r2,#1
		cmp		r2,#15
		ble		itc1
		lw		r1,#3
		sb		r1,LEDS
		ret

;------------------------------------------------------------------------------
; Dump recieved message to screen.
;
; Parameters:
;	<none> data in receive buffer
; Returns:
;	<none>
; Registers Affected:
;	<none>
;------------------------------------------------------------------------------

RecvDump:
		sub		sp,sp,#4
		sw		lr,[sp]
		sw		r1,2[sp]
		lw		r1,rxBuf+MSG_SRC
		cmp		r1,#$211
		bne		RecvDump1
		call	DispCRLF
		lw		r1,rxBuf+MSG_DST
		call	DispWord
		call	DispSpace
		lw		r1,rxBuf+MSG_SRC
		call	DispWord
		call	DispSpace
		lb		r1,rxBuf+MSG_TTL
		call	DispByte
		call	DispSpace
		lb		r1,rxBuf+MSG_TYPE
		call	DispByte
		call	DispSpace
		lw		r1,rxBuf+6
		call	DispWord
		lw		r1,rxBuf+4
		call	DispWord
		lw		r1,rxBuf+2
		call	DispWord
		lw		r1,rxBuf+0
		call	DispWord
RecvDump1:
		lw		lr,[sp]
		lw		r1,2[sp]
		add		sp,sp,#4
		ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DispCRLF:
		sub		sp,sp,#2
		sw		lr,[sp]
		lw		r1,#13
		call	putcharScr
		lw		r1,#10
		call	putcharScr
		lw		lr,[sp]
		add		sp,sp,#2
		ret

DispSpace:
		sub		sp,sp,#2
		sw		lr,[sp]
		lw		r1,#' '
		call	putcharScr
		lw		lr,[sp]
		add		sp,sp,#2
		ret

DispWord:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		call	DispByte
		lw		r1,2[sp]
		call	DispByte
		lw		r1,2[sp]
		lw		lr,[sp]
		add		sp,sp,#4
		ret

DispByte:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		shr		r1,#1
		call	DispNybble
		lw		r1,2[sp]
		call	DispNybble
		lw		r1,2[sp]
		lw		lr,[sp]
		add		sp,sp,#4
		ret

DispNybble:
		add		sp,sp,#-4
		sw		lr,[sp]
		sw		r1,2[sp]
		and		r1,#$0F
		cmp		r1,#10
		bge		DispNybble1
		or		r1,#$30
		call	putcharScr
		br		DispNybble2
DispNybble1:
		add		r1,#'A'-10
		call	putcharScr
DispNybble2:
		lw		r1,2[sp]
		lw		lr,[sp]
		add		sp,sp,#4
		ret
				
;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;
; Parameters:
;	r1 = character to convert
; Returns:
;	r1 = converted character
;
;------------------------------------------------------------------------------

AsciiToScreen:
		add		sp,sp,#-2
		sw		r2,[sp]
		and		r1,#$FF
		mov		r2,r1
		and		r2,#%00100000	; if bit 5 isn't set
		beq		ats1
		mov		r2,r1
		and		r2,#%01000000	; or bit 6 isn't set
		beq		ats1
		and		r1,#%10011111
ats1:
		lw		r2,[sp]
		add		sp,sp,#2
		ret

;------------------------------------------------------------------------------
; Convert screen character to Ascii character.
;
; Parameters:
;	r1 = character to convert
; Returns:
;	r1 = converted character
;
;------------------------------------------------------------------------------

ScreenToAscii:
	cmp		r1,#26+1
	bgeu	ScreenToAscii1
	add		r1,#$60
ScreenToAscii1:
	ret

;----------------------------------------------------------------------------
; Clear the screen.
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	r1,r2,r3
;----------------------------------------------------------------------------

ClearScreen:
		add		sp,sp,#-2
		sw		lr,[sp]
		lw		r1,#' '
		call	AsciiToScreen
		lw		r2,NormAttr
		or		r1,r2
		mov		r3,r1
		lw		r1,#1612	; 52x31
		lw		r2,#TXTSCR
cs1:
		sw		r3,[r2]
		add		r2,r2,#2
		add		r1,r1,#-1
		bpl		cs1
		lw		lr,[sp]
		add		sp,sp,#2
		ret

;----------------------------------------------------------------------------
; Home the cursor
;
; Parameters:
;	<none>
; Returns:
;	<none>
; Registers Affected:
;	<none>
;----------------------------------------------------------------------------

HomeCursor:
		sb		r0,cursy
		sb		r0,cursx
		sw		r0,pos
		ret

; flash the character at the screen position
;   r1: 1 = flash, 0 = no flash
flashCursor:
		ret

;-----------------------------------------------------------------
; Display a message on the screen
;
; Parameters:
;	r1 = message address
;	screen pos controls where message is displayed
; Returns:
; 	r1 = points to null character
;-----------------------------------------------------------------

putmsgScr:
	sub		sp,sp,#4	; allocate stack frame
	sw		lr,[sp]	; save off link reg
	sw		r3,2[sp]
	mov		r3,r1		; r3 = msg address
putmsg3:
	lb		r1,[r3]		; get char to display
	beq		putmsg4
	call	putcharScr	; store to screen
	add		r3,r3,#1	; inc msg pointer
	br		putmsg3
putmsg4:
	mov		r1,r3
	lw		r3,2[sp]
	lw		lr,[sp]
	add		sp,sp,#4
	ret


;-----------------------------------------------------------------
; Put a character to the screen
;
; Parameters:
;	r1.b = character to put
;-----------------------------------------------------------------

putcharScr
	sub		sp,sp,#10
	sw		lr,[sp]
	sw		r1,2[sp]
	sw		r4,4[sp]
	sw		r5,6[sp]
	sw		r6,8[sp]

	zxb		r1			; mask

	; first turn off any flashing cursor - it may be moved
	lw		r4,r1
	lw		r1,#0
	call	flashCursor
	lw		r1,r4

	; process carriage return
	cmp		r1,#CR		; carriage return ?
	bne		pc1
	lw		r1,pos		; subtract X from position
	lb		r4,cursx
	sub		r1,r4
	sw		r1,pos
	sb		r0,cursx	; and set X to zero
	jmp		pc7

	; process line feed
pc1
	cmp		r1,#LF		; line feed ?
	bne		pc2
	lb		r1,cursy	; past line 31 ?
	lb		r4,txtHeight
	sub		r4,r4,#2
	cmp		r1,r4
	bltu	pc3			; if we are, then just scroll the screen
	call	scrollScreenUp
	jmp		pc7
pc3
	add		r1,r1,#1	; increment Y
	sb		r1,cursy
	lw		r1,pos		; and the cursor position
	lb		r4,txtWidth
	add		r1,r4
	sw		r1,pos
	jmp		pc7

	; backspace
pc2
	cmp		r1,#CTRLH	; backspace ?
	bne		pc4
	lb		r1,cursx	; is cursor.x already zero ?
	bne		pc5			
	jmp		pc7			; can't backspace
pc5
	sub		r1,r1,#1
	sb		r1,cursx
	lw		r4,pos
	sub		r4,r4,#1
	sw		r4,pos
	; shift remaining characters on line over
	shl		r4,#1		; r4 = n
	lw		r6,#TXTSCR
	add		r6,r4		; r6 = target pos
	lb		r4,txtWidth
	sub		r4,r4,#2
pc6
	lw		r5,2[r6]	; shift next char
	sw		r5,[r6]		; over to this one
	add		r6,r6,#2
	add		r1,r1,#1	; until X = 39
	cmp		r1,r4
	bltu	pc6
	; blank trailing character
	lw		r1,#' '
	call	AsciiToScreen
	lw		r5,NormAttr
	or		r1,r5
	sw		r1,[r6]
	jmp		pc7

	; control character (non-printable)
pc4
	cmp		r1,#' '
	bgeu	pc11
	jmp		pc7


	; some other character
	; put the character to the screen, then advance cursor
pc11
	call	AsciiToScreen
	lw		r4,NormAttr
	or		r1,r4
	lw		r4,#TXTSCR
	lw		r5,pos
	shl		r5,#1		; pos * 2
	add		r4,r5		; scr[pos]
	sw		r1,[r4]		; = char
	; advance cursor
	lw		r5,pos
	lb		r1,txtWidth
	sub		r1,r1,#2
	lb		r4,cursx
	cmp		r4,r1		; would we be at end of line ?
	bleu	pc8
	sub		r5,r4		; pos -= cursx
	sw		r5,pos
	sb		r0,cursx	; cursor.x = 0
	lb		r4,cursy
	lb		r1,txtHeight
	sub		r1,r1,#2
	cmp		r4,r1		; at last line of screen ?
	bleu	pc9
	call	scrollScreenUp	; yes, scroll
	br		pc7
pc9
	add		r4,r4,#1	; cursor.y++
	sb		r4,cursy
	lb		r1,txtWidth
	add		r5,r1		; pos += txtWidth
	sw		r5,pos
	br		pc7
pc8						; not at EOL
	add		r4,r4,#1	; cursor.x++
	sb		r4,cursx
	add		r5,r5,#1	; pos++
	sw		r5,pos

pc7
	lb		r1,cursFlash	; flash or don't flash the cursor
	call	flashCursor
	lw		r5,pos
	sw		r5,TXTCTRL+14
	lw		lr,[sp]
	lw		r1,2[sp]
	lw		r4,4[sp]
	lw		r5,6[sp]
	lw		r6,8[sp]
	add		sp,sp,#10
	ret

scrollScreenUp:
	sub		sp,sp,#2
	sw		r5,[sp]
	lw		r3,#1559	; number of chars to move - 1
	lw		r2,#TXTSCR
	lb		r1,txtWidth
	shl		r1,#1
scrollScreenUp1:
	mov		r5,r2
	add		r5,r1
	lw		r4,[r5]		; char at next line
	sw		r4,[r2]		; goes to this line
	add		r2,r2,#2
	sub		r3,r3,#1
	bne     scrollScreenUp1
	; blank out last line
	; The character used is a hard-coded constant ($20). No real need to
	; call AsciiToScreen() which also saves having to stack the
	; link register.
	lw		r1,NormAttr
	and		r1,#$FF00
	or		r1,#$20
	lb		r3,txtWidth
scrollScreenUp2:
	sw		r1,[r2]
	add		r2,r2,#2
	sub		r3,r3,#1
	bne     scrollScreenUp2
	lw		r5,[sp]
	add		sp,sp,#2
	ret

;----------------------------------------------------------------------------
; Get character from keyboard buffer. Characters are placed in the buffer
; when a keystroke message is sent by node $21.
;
; Parameters:
;	<none>
; Returns:
;	r1 = ascii character, 0 if no char available.
;	.ZF = 1 if no char available, otherwise .ZF = 0
;----------------------------------------------------------------------------

kbdGetChar:
	lb		r1,kbdcnt
	beq		kbdGetCharXitZero
	add		sp,sp,#-2
	sw		r2,[sp]
	sub		r1,r1,#1
	sb		r1,kbdcnt
	lb		r2,kbdtail
	lb		r1,kbdbuf[r2]
	add		r2,r2,#2
	and		r2,#30
	sb		r2,kbdtail
	lw		r2,[sp]
	add		sp,sp,#2			; this should leave the ZF clear
kbdGetCharXitZero:
	ret

	align	2
DCBTbl:
	db	6,"NOD111",0,0,0,0,0
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
		
	db	3,"TVD",0,0,0,0,0,0,0,0
	dw	0						; type
	dw  0						; nBPB
	dw	0						; LastErc
	dw	0						; reserved
	dw	0						; start block low
	dw	0						; start block high
	dw	0						; number of blocks
	dw	0						;	"
	dw	TextCmdProc				; pCmdProc
	dw	0						; reserved
	db	0						; reentry count
	db	0						; single user flag
	dw	0						; hJob
	dw	0						; hMbx
	dw	0						; hSemaphore
	fill.b	8,0					; reserved

	db	3,"LED",0,0,0,0,0,0,0,0
	dw	0						; type
	dw  0						; nBPB
	dw	0						; LastErc
	dw	0						; reserved
	dw	0						; start block low
	dw	0						; start block high
	dw	0						; number of blocks
	dw	0						;	"
	dw	LedsCmdProc				; pCmdProc
	dw	0						; reserved
	db	0						; reentry count
	db	0						; single user flag
	dw	0						; hJob
	dw	0						; hMbx
	dw	0						; hSemaphore
	fill.b	8,0					; reserved

msgStarting:
	db	"Butterfly Grid Computer Starting",0

txtctrl_dat:
	db	52,31,52,0,16,0,7,$22,$1F,$E0,31,0,0,0,3,0

	; Table of offsets of start of video line in video
	; memory assuming 52 chars per line.
	.align	2
lineTbl:
	dw	0,104,208,312,416,520,624,728
	dw	832,936,1040,1144,1248,1352,1456,1560,
	dw	1664,1768,1872,1976,2080,2184,2288,2392,
	dw	2496,2600,2704,2808,2912,3016,3120,3224
; 56 columns display table
;	dw	0,112,224,336,448,560,672,784
;	dw	896,1008,1120,1232,1344,1456,1568,1680
;	dw	1792,1804,1916,2028,2140,2252,2364,2476
;	dw	2588,2700,2812,2924,3036,3148,3260,3372

		org		0xFFFE
		dw		start
