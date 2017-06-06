; ============================================================================
; FMTKmsg.asm
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
; Messaging Primitives for FMTK                                                       
; ============================================================================
;

		CPU		FT832
		MEM		32
		NDX		32

;----------------------------------------------------------------------------
; Handle to address conversion functions.
;----------------------------------------------------------------------------

public hJcbToAddr:
		PHA
		LDX		#JCB_SIZE
		MUL
		CLC
		ADC		#jcbs
		PLX
		RTS

public hTcbToAddr:
		PHX
		LDX		#TCB_SIZE
		MUL
		CLC
		ADC		#tcbs
		PLX
		RTS

public hMbxToAddr:
		PHX
		LDX		#MBX_SIZE
		MUL
		CLC
		ADC		#mailboxes
		PLX
		RTS

public hMsgToAddr:
		PHX
		LDX		#MSG_SIZE
		MUL
		CLC
		ADC		#messages
		PLX
		RTS

;----------------------------------------------------------------------------
; QueueMsg
;	Queue a message at a mailbox
; Assumes:
;	Mailbox parameter is valid
;	System semaphore is locked already
; Parameters:
;	.A	mailbox handle
;	.X  message handle
;----------------------------------------------------------------------------
;
QueueMsg:
		STX.H	reg_x
		STA.H	reg_a
		JSR		hMbxToAddr
		TAX
		INC.H	MBX_mq_count,X	; increment queued messages count
		LDA.UH	MBX_mq_tail,X	; if (mailboxes[hMbx]->mq_tail >= 0)
		BMI		.0001			; branch if no messages queued
		JSR		hMsgToAddr
		TAX
		LDA.UH	reg_x			; .A = message handle
		STA.H	MSG_link,X		; message[mailbox[hMbx]->mq_tail].link = hMsg
		BRA		.0002
.0001:							; else
		LDA.H	reg_a			;	.A = mailbox handle
		JSR		hMbxToAddr
		TAX
		LDA.UH	reg_x
		STA.H	MBX_mq_head,X	; mailbox[hMbx].mq_head = hMsg
.0002:
		LDA.UH	reg_a			; .A = mailbox handle
		JSR		hMbxToAddr
		TAX						; .X = index into mailboxes array
		LDA.UH	reg_x			; .A = message handle
		STA.H	MBX_mq_tail,X	; mailbox[hMbx]->mq_tail = hMsg
		JSR		hMsgToAddr
		TAX
		LDA		#$FFFFFFFF
		STA.H	MSG_link,X		; message[hMsg]->link = -1
		RTS		

;----------------------------------------------------------------------------
; Dequeue message from mailbox
;
; Assumes:
;	Mailbox parameter is valid
;	System semaphore is locked already
; Parameters:
;	.A = mailbox number
; Returns:
;	.A = -1 if no messages available
;	.A = handle of message
;----------------------------------------------------------------------------
;
DequeueMsg:
	JSR		hMbxToAddr
	TAX
	LDA.UH	MBX_mq_count,X	; if (mbx->mq_count)
	BEQ		.noMessage
	DEC.H	MBX_mq_count,X	; mbx->mq_count--;
	LDA.UH	MBX_mq_head,X	; .A = message handle
	BMI		.noMessage
	JSR		hMsgToAddr
	PHA
	TAY
	LDA.H	MSG_link,Y
	STA.H	MBX_mq_head,X
	BPL		.0001
	LDA		#$FFFFFFFF
	STA.H	MBX_mq_tail,X
.0001:
	PLA
	STA.H	MSG_link,Y		; tmpmsg->link = hm
	RTS						; return hm
.noMessage:
	LDA		#$FFFFFFFF
	RTS


;----------------------------------------------------------------------------
;		Dequeues a thread from a mailbox. The thread will also
;	be removed from the timeout list (if it's present there),
;	and	the timeout list will be adjusted accordingly.
;
;	.A = handle to mailbox
; Returns:
;	.A = handle to thread (-1 if none available)
;----------------------------------------------------------------------------

DequeueThreadFromMbx:
	JSR		hMbxToAddr
	TAX
	LDA.H	MBX_tq_head,X
	BPL		.0001
	LDA		#$FFFFFFFF
	RTS						; return .A < 0
.0001:
	DEC.H	MBX_tq_count,X
	LDA.UH	MBX_tq_head,X
	STA.H	hTcbTmp
	JSR		hTcbToAddr
	TAY
	LDA.H	TCB_mbq_next,Y
	STA.H	MBX_tq_head,X
	BMI		.0002
	LDA		#$FFFFFFFF
	STA.H	TCB_mbq_prev,Y
	BRA		.0003
.0002:
	LDA		#$FFFFFFFF
	STA.H	MBX_tq_tail,X
.0003:
	LDA.B	TCB_status,Y
	AND		#TS_TIMEOUT
	BEQ		.0004
	LDA.UH	hTcbTmp
	STA.H	TIMEOUT_LIST+2	; which task to remove
	LDA		#TOL_RMV		; remove command to timeout list
	STA.B	TIMEOUT_LIST	; remove the task
.0004:
	LDA		#$FFFFFFFF
	STA.H	TCB_mbq_prev,Y
	STA.H	TCB_mbq_next,Y
	STA.H	TCB_hWaitMbx,Y
	LDA.H	TCB_status,Y
	AND		#~TS_WAITMSG
	STA.H	TCB_status,Y
	LDA.H	hTcbTmp
	RTS

;----------------------------------------------------------------------------
; Queue a thread at a mailbox
;
; .A = handle to TCB
; .X = mailbox
;----------------------------------------------------------------------------

QueueThreadAtMbx:
	STA.H	hTcbTmp
	STX.H	hMbxTmp
	JSR		hTcbToAddr
	TAX
	LDA.B	TCB_status,X
	ORA		#TS_WAITMSG
	STA.B	TCB_status,X
	LDX.H	hMbxTmp
	STA.H	TCB_hWaitMbx,X
	LDA		#$FFFFFFFF
	STA.H	TCB_mbq_next,X
	LDA.H	hMbxTmp
	JSR		hMbxToAddr
	TAY
	LDA		MBX_tq_head,Y
	BPL		.0001
	LDA		#$FFFFFFFF
	STA.H	TCB_mbq_prev,X
	LDA		hTcbTmp
	STA.H	MBX_tq_head,Y
	STA.H	MBX_tq_tail,Y
	LDA		#1
	STA.H	MBX_tq_count,Y
	BRA		.0002
.0001:
	LDA.H	MBX_tq_tail,Y
	STA.H	TCB_mbq_prev,X
	LDA.H	hTcbTmp
	STA.H	MBX_tq_tail,Y
	LDA.H	MBX_tq_count,Y
	INA
	STA.H	MBX_tq_count,Y
	LDA.H	MBX_tq_tail,Y
	JSR		hTcbToAddr
	TAX
	LDA.H	hTcbTmp
	STA.H	TCB_mbq_next,X
.0002:
	RTS

;----------------------------------------------------------------------------
; Allocate a mailbox
;	The mailbox is added to the array of mailboxes that the job uses.
;	The default queue strategy is to queue the eight most recent messages.
; Parameters:
;	<none>
; Returns:
; .A = handle to mailbox (-4 = no mailbox available)
; .NF set on error, clear otherwise
;----------------------------------------------------------------------------

public FMTK_AllocMbx:
	; First ensure that there is an open mailbox slot in the JCB.
	; JCB's only support a limited number of mailboxes
	JSR		GetJCB
	TAX
	JSR		hJcbToAddr
	LDY		#0
.0002:
	LDA.H	JCB_hMbxs,Y
	BMI		.gotMbxSlot
	INY
	INY
	CPY		#NR_MBXperJCB*2
	BNE		.0002
	LDA		#E_TooManyMbx
	RTC		#0
.gotMbxSlot:
	LDA.H	freeMBX
	BPL		.0001
	LDA		#E_NoMoreMbx
	RTC		#0
.0001:
	STA.H	JCB_hMbxs,Y
	PHA
	JSR		hMbxToAddr
	TAX
	LDA.H	MBX_link,X
	STA.H	freeMBX
	DEC.H	nMailbox
	JSR		UnlockSysSema
	JSR		GetJCB
	STA.B	MBX_owner,X
	LDA		#$FFFFFFFF
	STA.H	MBX_tq_head,X
	STA.H	MBX_tq_tail,X
	STA.H	MBX_mq_head,X
	STA.H	MBX_mq_tail,X
	STZ.H	MBX_tq_count,X
	STZ.H	MBX_mq_count,X
	STZ.H	MBX_mq_missed,X
	LDA		#8
	STA.H	MBX_mq_size,X
	LDA		#MQS_NEWEST
	STA		MBX_mq_strategy,X
	PLA
	RTC		#0

;----------------------------------------------------------------------------
; SendMsg
;
; Parameters:
;	.A = mailbox handle
;	D1  (on stack word)
;	D2  (on stack word)
;	D3	(on stack word)
;----------------------------------------------------------------------------

public FMTK_SendMsg:
public FMTK_PostMsg:
	STA.H	hMbxTmp
	JSR		hMbxToAddr
	LDA.B	MBX_owner,X
	BMI		.notOwned
	CMP		#NR_MBX
	BLT		.ownerOk
.notOwned:
	LDA		#E_NotAlloc
	RTC		#12
.ownerOk:
	LDA.H	freeMSG
	BMI		.noMsg
	CMP		#NR_MSG
	BLT		.msgOk
.noMsg:
	LDA		#E_NoMoreMsgBlks
	RTC		#12
.msgOk:
	STA.H	hMsgTmp
	JSR		hMsgToAddr
	TAX
	LDA		MSG_link,X
	STA		freeMSG
	DEC		nMsgBlk
	LDA		#MBT_DATA
	STA.B	MSG_type,X
	LDA		3,S
	STA		MSG_d1,X
	LDA		7,S
	STA		MSG_d2,X
	LDA		11,S
	STA		MSG_d3,X
	JSR		DequeueThreadFromMbx
	CMP		#0
	BPL		.thrdOk
	LDA.H	hMbxTmp
	LDX.H	hMsgTmp
	JSR		QueueMsg
	RTC		#12
.thrdOk:
	STA		hTcbTmp
	JSR		hTcbToAddr
	TAY
	LDA.B	MSG_type,X
	STA.B	TCB_msg_type,Y
	LDA		MSG_d1,X
	STA		TCB_msg_d1,Y
	LDA		MSG_d2,X
	STA		TCB_msg_d2,Y
	LDA		MSG_d3,X
	STA		TCB_msg_d3,Y
	LDA		#MT_FREE
	STA		MSG_type,X
	LDA.H	freeMSG
	STA.H	MSG_link,X
	LDA		hMsgTmp
	STA		freeMSG
	LDA.H	hTcbTmp
	JSR		hTcbToAddr
	TAX
	LDA.B	TCB_status,X
	AND		#TS_TIMEOUT
	BEQ		.noTimeout
	LDA.H	hTcbTmp
	STA.H	TIMEOUT_LIST+2
	LDA		#TOL_RMV
	STA.B	TIMEOUT_LIST
.noTimeout:
	LDA.H	hTcbTmp
	JSR		InsertIntoReadyFifo		
	LDA		#E_Ok
	RTC		#12

;----------------------------------------------------------------------------
;	Wait for message. If timelimit is zero then the thread will wait
; indefinately for a message.
;
; Parameters:
;	.A = mailbox number
;	*d1 = pointer to where to store D1 (on stack)
;	*d2 = pointer to where to store D2 (on stack)
;	*d3 = pointer to where to store D3 (on stack)
;   TimeLimit = value on stack
;----------------------------------------------------------------------------

public FMTK_WaitMsg:
	STA.H	hMbxTmp
	JSR		hMbxToAddr
	LDA		MBX_owner,X
	BMI		.notOwned
	CMP		#NR_MBX
	BLT		.ownerOk
.notOwned:
	LDA		#E_NotAlloc
	RTC		#16
.ownerOk:
	LDA		hMbxTmp
	JSR		DequeueMsg
	CMP		#0
	LBPL	.gotMsg
	TTA
	PHA
	JSR		hTcbToAddr
	TAX
	STZ		TCB_status,X	; remove thread from ready list
	JSR		QueueThreadAtMbx
	LDA		15,S			; .A = time limit param
	BEQ		.noTimelimit
	STA		TIMEOUT_LIST + 4
	PLA
	STA.H	TIMEOUT_LIST + 2
	LDA		#TOL_INS
	STA.B	TIMEOUT_LIST
	BRA		.0001
.noTimelimit:
	PLA
.0001:
	JCR		$FF00,$FD		; invoke scheduler
	; Control will return here as a result of a SendMsg or timeout
	LDA.H	running_task
	JSR		hTcbToAddr
	TAX
	LDA		TCB_msg_type,X
	CMP		#MT_NONE
	BNE		.0002
	LDA		#E_NoMsg
	RTC		#16
.0002:
	LDA		#MT_NONE
	STA.B	TCB_msg_type,X
	LDY		#0
	LDA		3,S
	BEQ		.noD1x
	LDA		TCB_msg_d1,X
	STA		{3,S},Y
.noD1x:
	LDA		7,S
	BEQ		.noD2x:
	LDA		TCB_msg_d2,X
	STA		{7,S},Y
.noD2x:
	LDA		11,S
	BEQ		.noD3x
	LDA		TCB_msg_d3,X
	STA		{11,S},Y
.noD3x:
	LDA		#E_Ok
	RTC		#16
	;-----------------------------------------------------
	; We get here if there was initially a message
	; available in the mailbox, or a message was made
	; available after a task switch.
	;-----------------------------------------------------
.gotMsg:
	STA.H	hMsgTmp
	JSR		hMsgToAddr
	TAX
	LDY		#0
	LDA		3,S
	BEQ		.noD1
	LDA		MSG_d1,X
	STA		{3,S},Y
.noD1:
	LDA		7,S
	BEQ		.noD2
	LDA		MSG_d2,X
	STA		{7,S},Y
.noD2:
	LDA		11,S
	BEQ		.noD3
	LDA		MSG_d3,X
	STA		{11,S},Y
.noD3:
	LDA		#MT_FREE
	STA.B	MSG_type,X
	LDA.H	freeMSG
	STA.H	MSG_link,X
	LDA.H	hMsgTmp
	STA.H	freeMSG
	INC.H	nMsgBlk
	LDA		#E_Ok
	RTC		#16

;----------------------------------------------------------------------------
; FMTK_CheckMsg(hMbx,int *d1, int *d2, int *d3, int qrmv);
;
;		Check for message at mailbox. If no message is
;	available return immediately to the caller (CheckMsg() is
;	non blocking). Optionally removes the message from the
;	mailbox.
;
; Parameters:
;	.A = handle to mailbox
;	d1 = address to store d1 in (word on stack)
;	d2 = address to store d2 in (word on stack)
;	d3 = address to store d3 in (word on stack)
;	qrmv = 1=remove message from queue (word on stack)
;----------------------------------------------------------------------------

public FMTK_CheckMsg:
	JSR		hMbxToAddr
	LDA		MBX_owner,X
	BMI		.notOwned
	CMP		#NR_MBX
	BLT		.ownerOk
.notOwned:
	LDA		#E_NotAlloc
	RTS		#16
.ownerOk:
	LDA		15,S
	BEQ		.0001
	LDA.H	MBX_number,X
	JSR		DequeueMsg
	BRA		.0002
.0001:
	LDA.H	MBX_mq_head,X
.0002:
	CMP		#0
	BPL		.gotMsg
	LDA		#E_NoMsg
	RTC		#16
.gotMsg:
	STA.H	hMsgTmp
	JSR		hMsgToAddr
	TAX
	LDY		#0
	LDA		3,S
	BEQ		.noD1
	LDA		MSG_d1,X
	STA		{3,S},Y
.noD1:
	LDA		7,S
	BEQ		.noD2
	LDA		MSG_d2,X
	STA		{7,S},Y
.noD2:
	LDA		11,S
	BEQ		.noD3
	LDA		MSG_d3,X
	STA		{11,S},Y
.noD3:
	LDA		15,S
	BEQ		.noRmv
	LDA		#MT_FREE
	STA.B	MSG_type,X
	LDA.H	freeMSG
	STA.H	MSG_link,X
	LDA.H	hMsgTmp
	STA.H	freeMSG
	INC.H	nMsgBlk
.noRmv:
	LDA		#E_Ok
	RTC		#16

;----------------------------------------------------------------------------
; PeekMsg(hMbx,int *d1, int *d2, int *d3);
;
; Checks for a message without removing it from the queue.
;----------------------------------------------------------------------------

public FMTK_PeekMsg:
	STA		hMbxTmp
	LDA		#0
	PHA
	TSX
	LDA		11,X
	PHA
	LDA		11,X
	PHA
	LDA		11,X
	PHA
	LDA		hMbxTmp
	JSR		UnlockSysSema
	JSR		FMTK_CheckMsg
	RTC		#12

