;----------------------------------------------------------------------------
; Dispatch routine for received messages.
; A reset message is processed here, not counting on the DCB to be setup
; correctly. Otherwise all other messages are passed to the command processor
; for the intended device.
;----------------------------------------------------------------------------

RecvDispatch:
		add		sp,sp,#-8
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]
		tsr		r1,ID
		cmp		r1,#$111
		beq		RecvDispatch2
		lb		r1,rxBuf+MSG_TYPE
		cmp		r1,#MT_RST			; reset message ?
		bne		RecvDispatch2
		call	ResetNode
		; Send back a reset ACK message to indicate node is good to go.
		call	zeroTxBuf
		lw		r1,#$111
		sw		r1,txBuf+MSG_DST
		lw		r1,#MT_RST_ACK
		sb		r1,txBuf+MSG_TYPE
		call	Xmit
		br		RecvDispatchXit
RecvDispatch2:
		lw		r1,rxBuf+MSG_DST
		and		r1,#$FFF
		tsr		r2,ID
		cmp		r2,r1
		bne		RecvDispatchXit
		lw		r2,rxBuf+MSG_DST
		rol		r2,#1		; Get the 'D' nybble into r2
		rol		r2,#1
		rol		r2,#1
		rol		r2,#1
		and		r2,#$0F		; max 15 devices
		shl		r2,#1		; multiply by 48 (size of DCB)
		shl		r2,#1
		shl		r2,#1
		shl		r2,#1
		mov		r3,r2
		shl		r2,#1
		add		r2,r3
		add		r2,r2,#NodeDCB
		lw		r2,DCB_pCmdProc[r2]
		lb		r1,rxBuf+MSG_TYPE
		call	[r2]
RecvDispatchXit:
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		add		sp,sp,#8
		ret

;----------------------------------------------------------------------------
; Message command processor for node.
;
; Executes different message handlers based on the message type.
;----------------------------------------------------------------------------

StdMsgHandlers:
		add		sp,sp,#-8
		sw		lr,[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]

		lb		r1,rxBuf+MSG_TYPE

		; Process PING request
		cmp		r1,#MT_PING
		bne		StdMsgHandlers1
		call	PingHandler
		lw		r1,#1
		br		StdMsgHandlersXit

StdMsgHandlers1:
		cmp		r1,#MT_START_BASIC_LOAD	; start BASIC load
		bne		StdMsgHandlers2
		lw		r1,rxBuf+MSG_SRC
		call	INITTBW
		lw		r8,TXTBGN			; r8 = text begin
		lw		r1,#1
		br		StdMsgHandlersXit

StdMsgHandlers2:
		cmp		r1,#MT_LOAD_BASIC_CHAR	; load BASIC program char
		bne		StdMsgHandlers4
		lw		r1,rxBuf
		sw		r1,[r8]
		lw		r1,rxBuf+2
		sw		r1,2[r8]
		lw		r1,rxBuf+4
		sw		r1,4[r8]
		add		r8,r8,#6
		sw		r8,TXTUNF
		lw		r1,#1
		br		StdMsgHandlersXit

		; Run a BASIC program by stuffing a 'RUN' command into the BASIC
		; buffer.
StdMsgHandlers4:
		cmp		r1,#MT_RUN_BASIC_PROG
		bne		StdMsgHandlers5
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
		lw		r1,#1
		br		StdMsgHandlersXit

		; Load program code
StdMsgHandlers5:
		cmp		r1,#MT_LOAD_CODE
		bne		StdMsgHandlers6
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		lw		r1,#1
		br		StdMsgHandlersXit

		; Load program data
StdMsgHandlers6:
		cmp		r1,#MT_LOAD_DATA
		bne		StdMsgHandlers7
		lw		r1,rxBuf+2
		lw		r2,rxBuf+4
		sw		r1,[r2]
		lw		r1,#1
		br		StdMsgHandlersXit
		; Load program code

		; Execute program
StdMsgHandlers7:
		cmp		r1,#MT_EXEC_CODE
		bne		StdMsgHandlers8
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
		lw		r1,#1
		br		StdMsgHandlersXit

		; Enumerate the devices in the node. Provide a list back
		; to node $111.
StdMsgHandlers8:
		cmp		r1,#MT_ENUM_DEVICES
		bne		StdMsgHandlers12
		call	EnumDevices
		lw		r1,#1
		br		StdMsgHandlersXit

StdMsgHandlers12:
		lw		r1,#0
StdMsgHandlersXit:
		lw		lr,[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		add		sp,sp,#8
		or		r1,r1
		ret

;----------------------------------------------------------------------------
; Standard message handler for enunmerating devices.
;
; Enumerate the devices present in the node.
;----------------------------------------------------------------------------

EnumDevices:
		add		sp,sp,#-10
		sw		lr,[sp]
		sw		r1,2[sp]
		sw		r2,4[sp]
		sw		r3,6[sp]
		sw		r4,8[sp]
		lw		r3,#0
		lw		r2,#0
EnumDevices1:
		call	zeroTxBuf
		call	SetDestFromRx
		mov		r4,r3
		ror		r4,#1			; put count in r4 bits 12 to 15
		ror		r4,#1
		ror		r4,#1
		ror		r4,#1
		tsr		r1,ID
		or		r1,r4
		sw		r1,txBuf
		lw		r1,NodeDCB[r2]
		sw		r1,txBuf+2
		lw		r1,NodeDCB+2[r2]
		sw		r1,txBuf+4
		lw		r1,NodeDCB+4[r2]
		sw		r1,txBuf+6
		lw		r1,#MT_ENUM_DEVICES1
		call	Xmit
		call	zeroTxBuf
		call	SetDestFromRx
		lw		r1,NodeDCB+6[r2]
		sw		r1,txBuf
		lw		r1,NodeDCB+8[r2]
		sw		r1,txBuf+2
		lw		r1,NodeDCB+10[r2]
		sw		r1,txBuf+4
		lw		r1,NodeDCB+12[r2]
		sw		r1,txBuf+6
		lw		r1,#MT_ENUM_DEVICES2
		call	Xmit
		add		r2,r2,#DCB_Size
		add		r3,r3,#1
		cmp		r3,#nDCB
		bltu	EnumDevices1
		lw		lr,[sp]
		lw		r1,2[sp]
		lw		r2,4[sp]
		lw		r3,6[sp]
		lw		r4,8[sp]
		add		sp,sp,#10
		ret

