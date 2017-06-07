; ============================================================================
; FTBios833.asm
;        __
;   \\__/ o\    (C) 2014-2017  Robert Finch, Waterloo
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
; ============================================================================
;
CR			EQU		13
LF			EQU		10
ESC			EQU		$1B
BS			EQU		8
CTRLC		EQU		3

SC_LSHIFT	EQU		$12
SC_RSHIFT	EQU		$59
SC_KEYUP	EQU		$F0
SC_EXTEND	EQU		$E0
SC_CTRL		EQU		$14
SC_ALT		EQU		$11
SC_DEL		EQU		$71		; extend
SC_LCTRL	EQU		$58
SC_NUMLOCK	EQU		$77
SC_SCROLLLOCK	EQU	$7E
SC_CAPSLOCK	EQU		$58

TEXTROWS	EQU		31
TEXTCOLS	EQU		84

TickCount	EQU		$4
KeyState1	EQU		$8
KeyState2	EQU		$9
KeybdLEDs	EQU		$A
KeybdWaitFlag	EQU	$B
NumWorkArea	EQU		$C

; Range $10 to $1F reserved for hardware counters
CNT0L		EQU		$10
CNT0M		EQU		$11
CNT0H		EQU		$12
RangeStart	EQU		$20
RangeEnd	EQU		$24
CursorX		EQU		$30
CursorY		EQU		$32
VideoPos	EQU		$34
NormAttr	EQU		$36
StringPos	EQU		$38
EscState	EQU		$3C
Vidptr		EQU		$40
Vidregs		EQU		$46
Textcols	EQU		$4C
Textrows	EQU		$4E

reg_cs		EQU		$80
reg_ds		EQU		reg_cs + 4	; Yes, these values need 4 bytes as that is
reg_ss		EQU		reg_ds + 4	; the format read from the INF instruction.
reg_pc		EQU		reg_ss + 4
reg_a		EQU		reg_pc + 4
reg_x		EQU		reg_a + 4
reg_y		EQU		reg_x + 4
reg_sp		EQU		reg_y + 4
reg_sr		EQU		reg_sp + 4
reg_db		EQU		reg_sr + 4
reg_dp		EQU		reg_db + 4
reg_bl		EQU		reg_dp + 4
reg_mp		EQU		reg_bl + 4

cs_save		EQU		$80
ds_save		EQU		$84
pc_save		EQU		$88
pb_save		EQU		$8C
acc_save	EQU		$90
x_save		EQU		$94
y_save		EQU		$98
sp_save		EQU		$9C
sr_save		EQU		$A0
srx_save	EQU		$A4
db_save		EQU		$A8
dpr_save	EQU		$AC

running_task	EQU		$B8

keybd_char	EQU		$BA
rw_flag		EQU		$BA
keybd_cmd	EQU		$BC
WorkTR		EQU		$BE
ExitCode	EQU		$C0
secnum		EQU		$C4
bufptr		EQU		$C8
qcnt		EQU		$CC
IOFocusTask	EQU		$CE
TaskSwitchEn	EQU	$D0
numsec		EQU		$D2
TimeoutList	EQU		$D4
ldtrec		EQU		$100
timeout1	EQU		$104

RTCBuf		EQU		$300
FilenameBuf	EQU		$380
OutputVec	EQU		$03F0
spi_rw_vect	EQU		$03F4

PCS0		EQU		$B000
PCS1		EQU		PCS0 + 2
PCS2		EQU		PCS1 + 2
PCS3		EQU		PCS2 + 2
PCS4	    EQU		PCS3 + 2
PCS5		EQU		PCS4 + 2
CTR0_LMT	EQU		PCS0 + 16
CTR0_CTRL	EQU		CTR0_LMT + 3
CTR1_LMT	EQU		CTR0_CTRL + 1
CTR1_CTRL	EQU		CTR1_LMT + 3
MPU_IRQ_STATUS	EQU		$B01F

VIDBUF		EQU		$FD0000		; FD0000
VIDREGS		EQU		$FEA000
PRNG		EQU		$FEA100
KEYBD		EQU		$FEA110
FAC1		EQU		$FEA200

SPIMASTER	EQU		$00FEC000
SPI_MASTER_VERSION_REG	EQU	SPIMASTER+$00
SPI_MASTER_CONTROL_REG	EQU	SPIMASTER+$01
SPI_TRANS_TYPE_REG	EQU		SPIMASTER+$02
SPI_TRANS_CTRL_REG	EQU		SPIMASTER+$03
SPI_TRANS_STATUS_REG	EQU	SPIMASTER+$04
SPI_TRANS_ERROR_REG		EQU	SPIMASTER+$05
SPI_DIRECT_ACCESS_DATA_REG		EQU	SPIMASTER+$06
SPI_SD_SECT_7_0_REG		EQU	SPIMASTER+$07
SPI_SD_SECT_15_8_REG	EQU	SPIMASTER+$08
SPI_SD_SECT_23_16_REG	EQU	SPIMASTER+$09
SPI_SD_SECT_31_24_REG	EQU	SPIMASTER+$0A
SPI_RX_FIFO_DATA_REG	EQU	SPIMASTER+$10
SPI_RX_FIFO_DATA_COUNT_MSB	EQU	SPIMASTER+$11
SPI_RX_FIFO_DATA_COUNT_LSB  EQU SPIMASTER+$12
SPI_RX_FIFO_CTRL_REG		EQU	SPIMASTER+$14
SPI_TX_FIFO_DATA_REG	EQU	SPIMASTER+$20
SPI_TX_FIFO_CTRL_REG	EQU	SPIMASTER+$24
SPI_RESP_BYTE1			EQU	SPIMASTER+$30
SPI_RESP_BYTE2			EQU	SPIMASTER+$31
SPI_RESP_BYTE3			EQU	SPIMASTER+$32
SPI_RESP_BYTE4			EQU	SPIMASTER+$33

SPI_INIT_SD			EQU		$01
SPI_TRANS_START		EQU		$01
SPI_TRANS_BUSY		EQU		$01
SPI_INIT_NO_ERROR	EQU		$00
SPI_READ_NO_ERROR	EQU		$00
SPI_WRITE_NO_ERROR	EQU		$00
SPI_RW_READ_SD_BLOCK	EQU		$02
SPI_RW_WRITE_SD_BLOCK	EQU		$03

I2C_MASTER		EQU		$00FEC100
I2C_PRESCALE_LO	EQU		I2C_MASTER+$00
I2C_PRESCALE_HI	EQU		I2C_MASTER+$01
I2C_CONTROL		EQU		I2C_MASTER+$02
I2C_TX			EQU		I2C_MASTER+$03
I2C_RX			EQU		I2C_MASTER+$03
I2C_CMD			EQU		I2C_MASTER+$04
I2C_STAT		EQU		I2C_MASTER+$04

READY_FIFO		EQU		$00FEC200
READY_FIFO_CNT	EQU		$00FEC210
TIMEOUT_LIST	EQU		$00FEC300
TIMEOUT_LIST_CMD_REG	EQU		$00FEC300
TIMEOUT_LIST_HANDLE_REG	EQU		$00FEC302
TIMEOUT_LIST_TIMEOUT REG	EQU	$00FEC304

BIOSctx			EQU		$FC
OSctx			EQU		$FD
MAX_IRQ_HOOKS	EQU		16

; return types
RT_RTT			EQU		0
RT_RTC			EQU		1

; Timeout list commands
TOL_NOP			EQU		0
TOL_DEC			EQU		1
TOL_INS			EQU		2
TOL_RMV			EQU		3

SID			EQU		$FEB000		; FEB000
SID_FREQ0		EQU		$00
SID_PW0			EQU		$04
SID_CTRL0		EQU		$08
SID_ATTACK0		EQU		$0C
SID_DECAY0		EQU		$10
SID_SUSTAIN0	EQU		$14
SID_RELEASE0	EQU		$18
SID_WADR0		EQU		$1C
SID_VOLUME		EQU		$B0

do_invaders			EQU		$7868

NR_JCB			EQU		64
NR_TCB			EQU		512
NR_MBX			EQU		1024
NR_MSG			EQU		4096
NR_MBXperJCB	EQU		32

TS_READY		EQU		1
TS_PREEMPT		EQU		2
TS_WAITMSG		EQU		4
TS_TIMEOUT		EQU		8
MQS_NEWEST		EQU		0		; message queue strategy
MT_NONE			EQU		0
MT_FREE			EQU		1
MBT_DATA		EQU		0

E_Ok			EQU		0
E_NotAlloc		EQU		-1
E_NoMsg			EQU		-2
E_NoMoreMsgBlks	EQU		-3
E_NoMoreMbx		EQU		-4		; System has no more mailboxes available
E_TooManyMbx	EQU		-5		; JCB mailboxes maxed out

TCB_SIZE		EQU		100
tcbs			EQU		$20000
TCB_Next		EQU		$00	; 2 byte handles
TCB_Prev		EQU		$02	; 2 byte handles
TCB_Timeout		EQU		$04	; 4 byte value
TCB_mbq_next	EQU		$08	; 2 byte handles
TCB_mbq_prev	EQU		$0A	; 2 byte handles
TCB_msg_d1		EQU		$0C	; 4 byte value
TCB_msg_d2		EQU		$10	; 4 byte value
TCB_msg_d3		EQU		$14	; 4 byte value
TCB_msg_tgtadr	EQU		$18	; 2 byte handle
TCB_msg_retadr	EQU		$1A	; 2 byte handle
TCB_msg_link	EQU		$1C	; 2 byte handle
TCB_msg_type	EQU		$1E	; 2 byte value
TCB_hWaitMbx	EQU		$20	; 2 byte handle
TCB_number		EQU		$22	; 2 byte value
TCB_priority	EQU		$24	; 1 byte value
TCB_status		EQU		$25	; 1 byte value
TCB_affinity	EQU		$26	; 1 byte value
TCB_hJcb		EQU		$27	; 1 byte handle
TCB_start_tick	EQU		$28	; 4 byte value
TCB_end_tick	EQU		$2C	; 4 byte value
TCB_ticks		EQU		$30	; 4 byte value
TCB_exception	EQU		$34	; 4 byte value
TCB_rettype		EQU		$38	; 1 byte value
TCB_sp			EQU		$40	; 4 byte value
TCB_o0			EQU		$44
TCB_o1			EQU		$48
TCB_o2			EQU		$4C
TCB_o3			EQU		$50
TCB_o4			EQU		$54
TCB_o5			EQU		$58
TCB_o6			EQU		$5C
TCB_o7			EQU		$60

JCB_SIZE		EQU		1024
jcbs			EQU		tcbs + TCB_SIZE * NR_TCB
JCB_iof_next	EQU		$000	; 1 byte value
JCB_iof_prev	EQU		$001	; 1 byte value
JCB_user_name	EQU		$002	; 32 byte value
JCB_path		EQU		$022	; 256 byte value
JCB_exit_runfile	EQU	$122	; 256 byte value
JCB_command_line	EQU	$222	; 256 byte value
JCB_pVidMem		EQU		$322	; 6 byte value
JCB_pVirtVidMem	EQU		$328	; 6 byte value
JCB_VideoCols	EQU		$32E	; 1 byte value
JCB_VideoRows	EQU		$32F	; 1 byte value
JCB_CursorRow	EQU		$330	; 1 byte value
JCB_CursorCol	EQU		$331	; 1 byte value
JCB_NormAttr	EQU		$332	; 2 byte value
JCB_KeyState1	EQU		$334	; 2 byte value
JCB_KeyState2	EQU		$336	; 2 byte value
JCB_KeybdWaitFlag	EQU	$338	; 1 byte value
JCB_KeybdHead	EQU		$339
JCB_KeybdTail	EQU		$33A
JCB_KeybdBuffer	EQU		$33B	; 32 byte value
JCB_number		EQU		$35B	; 1 byte value
JCB_tasks		EQU		$35C	; 2 byte value * 8
JCB_next		EQU		$35E	; 1 byte value
JCB_hMbxs		EQU		$360	; 2 byte value

; 1024 mailboxes
mailboxes		EQU		jcbs + JCB_SIZE * NR_JCB
MBX_SIZE		EQU		24
MBX_link		EQU		$00	; 1 byte value
MBX_owner		EQU		$01	; 1 byte value
MBX_tq_head		EQU		$02	; 2 byte value
MBX_tq_tail		EQU		$04	; 2 byte value
MBX_mq_head		EQU		$06	; 2 byte value
MBX_mq_tail		EQU		$08	; 2 byte value
MBX_tq_count	EQU		$0C	; 2 byte value
MBX_mq_count	EQU		$0E	; 2 byte value
MBX_mq_size		EQU		$10	; 2 byte value
MBX_mq_missed	EQU		$12	; 2 byte value
MBX_mq_strategy	EQU		$14	; 1 byte value
MBX_number		EQU		$16	; 2 byte value

messages	EQU		mailboxes + MBX_SIZE * NR_MBX
MSG_d1		EQU		$00	; 4 byte value	( 4096 messages )
MSG_d2		EQU		$04	; 4 byte value
MSG_d3		EQU		$08	; 4 byte value
MSG_tgtadr	EQU		$0C	; 2 byte handle
MSG_retadr	EQU		$0E	; 2 byte handle
MSG_link	EQU		$10	; 2 byte handle
MSG_type	EQU		$12	; 2 byte value
MSG_SIZE	EQU		MSG_type + 2

running_task	EQU		messages + MSG_SIZE * NR_MSG
hTcbTmp		EQU		running_task + 2
hMbxTmp		EQU		hTcbTmp + 2
hMsgTmp		EQU		hMbxTmp + 2
freeMBX		EQU		hMsgTmp + 2
freeMSG		EQU		freeMBX + 2
freeJCB		EQU		freeMSG + 2
nMsgBlk		EQU		freeJCB + 2
nMailbox	EQU		nMsgBlk + 2
IRQ1Hook	EQU		nMailbox + 2
IRQ1HookEnd	EQU		IRQ1Hook + MAX_IRQ_HOOKS * 4
IOFocusBmp	EQU		IRQ1HookEnd

.include "supermon832.asm"
.include "FAC1ToString.asm"
.include "invaders.asm"

;	cpu		W65C816S
	cpu		FT833
	.org	$C000

start:
	; The m and x bits of the status register aren't available to be set or
	; cleared unless the core is operating in the 816 or 832 mode. So this
	; has to be set first (SEP then REP).
	SEP		#$100		; important '816 mode must be selected first
	REP		#$030		; 16 bit regs
	NDX 	16
	MEM		16
	LDX		#$7FFF		; set stack pointer
	TXS

	; setup the programmable address decodes
	LDA		#$0070		; program chip selects for I/O
	STA		PCS0		; at $007000
	LDA		#$0071
	STA		PCS1
;	LDA		#$FEA1		; select $FEA1xx I/O
;	STA		PCS3
;	LDA		#$0000		; select zero page ram
;	STA		PCS5

;	JSR		FMTK_Init

	; Setup the counters
	SEP		#$30		; set 8 bit regs
	NDX		8			; tell the assembler
	MEM		8
	; Counter #0 is setup as a free running tick count
	LDA		#$FF		; set limit to $FFFFFF
	STA		CTR0_LMT
	STA		CTR0_LMT+1
	STA		CTR0_LMT+2
	LDA		#$14		; count up, on mpu clock
	STA		CTR0_CTRL
	; Counter #1 is set to interrupt at a 50Hz rate
	LDA		#$2A	;94		; divide by 95794 (for 50Hz)
	STA		CTR1_LMT		; FFFFFE = 2Hz with 33MHz clock
	LDA		#$2C	;57
	STA		CTR1_LMT+1
	LDA		#$0A	;09
	STA		CTR1_LMT+2
	LDA		#$05		; count down, on mpu clock, irq disenabled
	STA		CTR1_CTRL
	; Counter #2 isn't setup

	REP		#$30
	MEM		16
	NDX		16
	;JSR		ResetKbd

	STZ		TaskSwitchEn
	STZ		running_task	; task #0 is the running task
	STZ		IOFocusTask		; task #0 has the focus to begin with

	LDA		#BrkRout1
	STA		$0102

	STZ		TickCount
	STZ		TickCount+2
Task0:
	LDA		#$01
	STA		$7000
.0001:
	LDA		#$04
	STA		$7000
	LDA		#VIDBUF>>16
	STA		Vidptr+2
	STZ		Vidptr
	LDA		#$05
	STA		$7000
	LDA		#$BF0D	; 'm'
	STA		{Vidptr}
	LDA		#$06
	STA		$7000
	LDA		#VIDREGS >> 16
	STA		Vidregs+2
	LDA		#VIDREGS
	STA		Vidregs
	LDA		#$07
	STA		$7000
	LDY		#7	
	LDA		#$21		; divide by 3 vertically, 2 horizontally
	JSR		SetVideoReg	; clear POR state
	LDA		#$08
	STA		$7000
	LDA		#84		; set window left position 84
	LDY		#2
	JSR		SetVideoReg
	LDA		#$09
	STA		$7000
	LDA		#0
	LDY		#3
	JSR		SetVideoReg
	LDA		#16			; set window top position
	LDY		#4
	JSR		SetVideoReg
	LDA		#$10
	STA		$7000
	JSR		GetTextRowsCols
	LDA		#DisplayChar
	STA		OutputVec
	LDA		#$11
	STA		$7000
	LDA		OutputVec
	CMP		#DisplayChar
	BNE		.0001

TaskMon1:
	LDA		#$02
	STA		$7000
	LDA		#$BF00
	STA		NormAttr
	JSR		ClearScreen
	JSR		HomeCursor
;	JSR		beep
	LDA		#$03
	STA		$7000
	PEA		0
	PEA		msgStarting
	JSR		DisplayString
	JSR		rtc_init
	JSR		rtc_read
	CMP		#0
	BEQ		.0006
	PEA		0
	PEA		msgRtcReadFail
	JSR		DisplayString
.0006:

Mon1:
	LDA		#$06
	STA		$7000
.mon1:
	CLI
	LDA		#$6BFF
	TAS
	JSR		CursorOn
	JSR		OutCRLF
	LDA		#'$'
	STA		TaskSwitchEn
.mon3:
	CLI
	PHA
	LDA		#0
	JSR		RequestIOFocus
	PLA
	JSR		OutChar
	LDA		#$07
	STA		$7000
	JSR		KeybdGetCharWait
	PHA
	LDA		#$08
	STA		$7000
	PLA
	AND		#$FF
;	CMP		#'.'
;	BEQ		.mon3
	CMP		#CR
	BNE		.mon3
	LDA		CursorY
	ASL
	TAX
	LDA		LineTbl,X
	ASL
	TAX
.mon4:
	JSR		IgnoreBlanks
	JSR		MonGetch
	CMP		#'$'
	BEQ		.mon4
	CMP		#'S'
	BNE		.mon2
	JSR		MonGetch
	CMP		#'E'
	BNE		.mon10
	JSR		MonGetch
	CMP		#'C'
	LBEQ	GetSecnum
	CMP		#'I'
	LBEQ	do_SEI
.mon10:
	CMP		#'U'
	LBNE	doSavefile
	LDA		#8
	JSR		RequestIOFocus
	SEP		#$200
	REP		#$130
	MEM		32
	NDX		32
	LDA		#8
	JSR		hTcbToAddr
	TAX
	LDA		#$20
	STA		TCB_priority,X
	JSR		InsertIntoReadyFifo
	SEP		#$100
	REP		#$200
	MEM		16
	NDX		16
	BRL		.mon1
.mon2:
	CMP		#'C'
	BNE		.mon5
	JSR		ClearScreen
	JSR		HomeCursor
	BRL		.mon1
.mon5:
	CMP		#'M'
	BNE		.mon6
	JSR		doMemoryDump
	BRL		Mon1
.mon6:
	CMP		#'D'
	LBEQ	doD
	CMP		#'>'
	LBEQ	doMemoryEdit
	CMP		#'F'
	LBEQ	doFill
	CMP		#'J'
	LBEQ	doJump
	CMP		#'T'
	LBEQ	doTask
	CMP		#'I'
	LBEQ	doInvaders
	CMP		#'R'
	BNE		.mon7
	JSR		MonGetch
	CMP		#'D'
	LBEQ	doRead
	DEX
	DEX
	BRL		doRegs
.mon7:
	CMP		#'B'
	LBEQ	doBasic
	CMP		#'W'
	LBEQ	doWrite
	CMP		#'f'
	LBNE	Mon1
	JSR		MonGetch
	CMP		#'m'
	LBNE	Mon1
	JSR		MonGetch
	CMP		#'t'
	LBNE	Mon1
	JSR		SDC_Format
	BRL		Mon1
.mon8:
	CMP		#'L'
	BNE		.mon9
	BRL		doLoadfile
.mon9:
	BRL		Mon1
; Get a character from the screen, skipping over spaces and tabs
;
MonGetNonSpace:
.0001:
	JSR		MonGetch
	CMP		#' '
	BEQ		.0001
	RTS

; Get a character from the screen.
;
MonGetch:
	LDA		VIDBUF,X
	INX
	INX
	AND		#$FF
	JSR		ScreenToAscii
	RTS

MonErr:
	PEA		0
	PEA		msgErr
	JSR		DisplayString
	BRL		Mon1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
doD:
	JSR		MonGetch
	CMP		#'T'
	BEQ		doDate
	DEX
	DEX
	BRL		doDisassemble

;------------------------------------------------------------------------------
; SEI <level>
; Sets the interrupt mask level.
;------------------------------------------------------------------------------

do_SEI:
	JSR		GetHexNumber
	LDA		NumWorkArea
	BNE		.0001
	SEI		#0
	BRL		Mon1
.0001:
	CMP		#1
	BNE		.0002
	SEI		#1
	BRL		Mon1
.0002:
	CMP		#2
	BNE		.0003
	SEI		#2
	BRL		Mon1
.0003:
	CMP		#3
	LBNE	Mon1
	SEI		#3
	BRL		Mon1

;------------------------------------------------------------------------------
; DT? - displays the date from the RTC
; DT <year> <month> <day> - updates the RTC with the year, month and day.
;------------------------------------------------------------------------------

doDate:
	JSR		MonGetch
	CMP		#'?'
	BEQ		DispDate
	DEX
	DEX
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA.B	RTCBuf+6
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA.B	RTCBuf+5
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA.B	RTCBuf+4
	JSR		rtc_write
.0001:
	BRL		Mon1

DispDate:
	JSR		rtc_read
	LDA.B	RTCBuf+6
	JSR		DispByte
	LDA		#'/'
	JSR		OutChar
	LDA.B	RTCBuf+5
	JSR		DispByte
	LDA		#'/'
	JSR		OutChar
	LDA.B	RTCBuf+4
	JSR		DispByte
	JSR		OutCRLF
	BRL		Mon1
		
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
doTask:
	JSR		MonGetch
	CMP		#'S'
	BNE		.0001
	JSR		GetHexNumber
	LDA		NumWorkArea
	ASL
	TAX		
	LDA		#$20
	STA		TCB_priority,X
	LDA		NumWorkArea
	JSR		InsertIntoReadyFifo
	BRL		Mon1
.0001:
	DEX
	DEX
	JSR		GetHexNumber
	LDA		NumWorkArea
	BRK		Mon1

;------------------------------------------------------------------------------
; Start the BASIC interpreter.
;------------------------------------------------------------------------------

doBasic:
	PHO
	LDO		#$10000
	JSR		$C000
	BRL		Mon1

ClearFilenameBuf:
	LDY		#0
	LDA		#' '
.0002:
	STA.B	FilenameBuf,Y
	INY
	CPY		#15
	BNE		.0002
	LDA		#0
	STA.B	FilenameBuf,Y
	RTS

MonGetFilename:
	JSR		ClearFilenameBuf
.0004:
	JSR		MonGetch
	CMP		#' '
	BEQ		.0004
	CMP		#'"'
	BNE		.badFname
.nextChar:
	JSR		MonGetch
	CMP		#'"'
	BEQ		.0001
	CMP		#'.'
	BNE		.0003
	LDY		#13
	BRA		.nextChar
.0003:
	STA.B	FilenameBuf,Y
	INY
	CPY		#15
	BNE		.nextChar
	JSR		MonGetch
	CMP		#'"'
	BNE		.badFname
.0001:
	RTS
.badFname:
	BRL		Mon1

doLoadfile:
	JSR		MonGetFilename
	JSR		GetHexNumber
	CPY		#0
	BEQ		.noBuf
	LDA		NumWorkArea+2
	PHA
	LDA		NumWorkArea
	PHA
	PEA		0
	LDA		#FilenameBuf
	PHA
	JSR		SDC_Loadfile
.noBuf:
	RTS

;------------------------------------------------------------------------------
; Get starting sector number for SD Card read/write routines
;------------------------------------------------------------------------------

GetSecnum:
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		secnum
	LDA		NumWorkArea+2
	STA		secnum+2
	BRL		Mon1

;------------------------------------------------------------------------------
; Read or write a block of memory to SD Card.
;------------------------------------------------------------------------------

doWrite:
	LDA		#$FFFF
	STA		rw_flag
	BRA		doReadWrite
doRead:
	STZ		rw_flag
doReadWrite:
	JSR		GetRange
	JSR		spi_master_init
	CMP		#0
	BEQ		.0004
	BRL		Mon1
.0004:
	JSR		OutCRLF
.0002:
	JSR		DispSecnum
	LDA		RangeStart+2
	PHA
	LDA		RangeStart
	PHA
	LDA		secnum+2
	PHA
	LDA		secnum
	PHA
	BIT		rw_flag
	BVC		.0005
	JSR		spi_master_write
	BRA		.0006
.0005:
	JSR		spi_master_read
.0006:
	INC		secnum
	BNE		.0001
	INC		secnum+2
.0001:
	CLC
	LDA		RangeStart
	ADC		#512
	STA		RangeStart
	LDA		RangeStart+2
	ADC		#0
	STA		RangeStart+2
	SEC
	LDA		RangeStart
	SBC		RangeEnd
	LDA		RangeStart+2
	SBC		RangeEnd+2
	BLT		.0002
	JSR		OutCRLF
	BRL		Mon1

DispSecnum:
	LDA		secnum+2
	JSR		DispWord
	LDA		secnum
	JSR		DispWord
	LDA		#$0D
	JMP		OutChar

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
doInvaders:
	LDA		#$FFFF
	STA		do_invaders
;	FORK	#5
;	TTA
;	CMP		#5
;	LBEQ	InvadersTask
	BRL		Mon1

;------------------------------------------------------------------------------
; Display Registers
; R<xx>		xx = context register to display
; Update Registers
; R.<reg> <val>
;	reg = CS PB PC A X Y SP SR DS DB DP or MP
;------------------------------------------------------------------------------

doRegs:
	JSR		MonGetch
	CMP		#'.'
	LBNE	.0004
	JSR		MonGetch
	CMP		#'C'
	BNE		.0005
	JSR		MonGetch
	CMP		#'S'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_cs
	LDA		NumWorkArea+2
	STA		reg_cs+2
.buildrec
	JSR		BuildRec
	LDX		WorkTR
	LDT		ldtrec
	BRL		Mon1
.0005:
	CMP		#'P'
	BNE		.0006
	JSR		MonGetch
	CMP		#'B'
	BNE		.0007
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea+2
	STA		reg_pc+2
	BRA		.buildrec
.0007:
	CMP		#'C'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_pc
	BRA		.buildrec
.0006:
	CMP		#'A'
	BNE		.0008
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_a
	LDA		NumWorkArea+2
	STA		reg_a+2
	BRA		.buildrec
.0008:
	CMP		#'X'
	BNE		.0009
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_x
	LDA		NumWorkArea+2
	STA		reg_x+2
	BRL		.buildrec
.0009:
	CMP		#'Y'
	BNE		.0010
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_y
	LDA		NumWorkArea+2
	STA		reg_y+2
	BRL		.buildrec
.0010:
	CMP		#'S'
	BNE		.0011
	JSR		MonGetch
	CMP		#'P'
	BNE		.0015
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_sp
	LDA		NumWorkArea+2
	STA		reg_sp+2
	BRL		.buildrec
.0015:
	CMP		#'R'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_sr
	BRL		.buildrec
.0011:
	CMP		#'D'
	BNE		.0014
	JSR		MonGetch
	CMP		#'S'
	BNE		.0012
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_ds
	LDA		NumWorkArea+2
	STA		reg_ds+2
	BRL		.buildrec
.0012:
	CMP		#'B'
	BNE		.0013
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_db
	BRL		.buildrec
.0013:
	CMP		#'P'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_dp
	BRL		.buildrec
.0014:
	CMP		#'M'
	LBNE	Mon1
	JSR		MonGetch
	CMP		#'P'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	LDA		NumWorkArea
	STA		reg_mp
	BRL		.buildrec

.0004:
	DEX
	DEX
;	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		NumWorkArea
	STA		WorkTR
	BSR		DispRegs
	BRL		Mon1

DispRegs:
	PEA		0
	PEA		msgRegs
	JSR		DisplayString
	JSR		space

	LDA		WorkTR
	ASL
	ASL
	ASL
	ASL
	TAX

	LDY		#0
.0001:
	INF
	INX
	STA		reg_cs,Y
	XBAW
	STA		reg_cs+2,Y
	INY4
	CPY		#48
	BNE		.0001

	; Display CS
	LDA		reg_cs
	JSR		DispWord
	LDA		#':'
	JSR		OutChar

	; Display PB PC
	LDA		reg_pc+2
	JSR		DispByte
	LDA		reg_pc
	JSR		DispWord
	JSR		space

	; Display SRX,SR
	LDA		reg_cs+32
	LDX		#16
.0003:
	ASL
	PHA
	LDA		#'0'
	ADC		#0
	JSR		DispNybble
	PLA
	DEX
	BNE		.0003
	JSR		space

	LDX		#16
.0002
	; display Acc,.X,.Y,.SP
	LDA		reg_cs+2,X
	JSR		DispWord
	LDA		reg_cs,X
	JSR		DispWord
	JSR		space
	INX4
	CPX		#32
	BNE		.0002

	PEA		0
	PEA		msgRegs2
	JSR		DisplayString
	JSR		space

	; Display SS
	LDA		reg_ss
	JSR		DispWord
	JSR		space

	; Display DS
	LDA		reg_ds
	JSR		DispWord
	JSR		space

	; Display DB
	LDA		reg_db
	JSR		DispByte
	JSR		space

	; Display DPR
	LDA		reg_dp
	JSR		DispWord
	JSR		space

	; Display back link
	LDA		reg_bl
	JSR		DispWord

	; Display map number
	JSR		space
	LDA		reg_mp
	JSR		DispByte

	JSR		OutCRLF
	RTS

; Build a startup record from the register values so that a context reg
; may be loaded

BuildRec:
	LDA		reg_cs
	STA		ldtrec
	LDA		reg_ds
	STA		ldtrec+2
	LDA		reg_ss
	STA		ldtrec+4
	LDA		reg_pc
	STA		ldtrec+6
	LDA		reg_pc+2
	AND		#$FF
	SEP		#$30		; 8 bit regs
	MEM		8
	XBA
	LDA		reg_a
	XBA
	REP		#$30
	MEM		16
	STA		ldtrec+8
	LDA		reg_a+1
	STA		ldtrec+10
	LDA		reg_a+3
	STA		ldtrec+12
	LDA		reg_x+1
	STA		ldtrec+14
	LDA		reg_x+3
	STA		ldtrec+16
	LDA		reg_y+1
	STA		ldtrec+18
	LDA		reg_y+3
	STA		ldtrec+20
	LDA		reg_sp+1
	STA		ldtrec+22
	LDA		reg_sp+3
	STA		ldtrec+24
	SEP		#$30
	LDA		reg_sr+1
	STA		ldtrec+26
	LDA		reg_db
	STA		ldtrec+27
	LDA		reg_dp
	STA		ldtrec+28
	LDA		reg_dp+1
	STA		ldtrec+29
	LDA		reg_mp
	STA		ldtrec+30
	STZ		ldtrec+31
	REP		#$30
	RTS

;------------------------------------------------------------------------------
; Dump memory.
;------------------------------------------------------------------------------

doMemoryDump:
	JSR		IgnoreBlanks
	JSR		GetRange
	JSR		OutCRLF
.0007:
	LDA		#'>'
	JSR		OutChar
	JSR		DispRangeStart
	LDY		#0
.0001:
	LDA		{RangeStart},Y
	JSR		DispByte
	LDA		#' '
	JSR		OutChar
	INY
	CPY		#8
	BNE		.0001
	LDY 	#0
.0005:
	LDA		{RangeStart},Y
	AND		#$FF
	CMP		#' '
	BCS		.0002
.0004:
	LDA		#'.'
	BRA		.0003
.0002:
	CMP		#$7f
	BCS		.0004
.0003:
	JSR		OutChar
	INY
	CPY		#8
	BNE		.0005
	JSR		OutCRLF
	CLC
	LDA		RangeStart
	ADC		#8
	STA		RangeStart
	BCC		.0006
	INC		RangeStart+2
.0006:
	SEC
	LDA		RangeEnd
	SBC		RangeStart
	LDA		RangeEnd+2
	SBC		RangeStart+2
	PHP
	JSR		KeybdGetCharNoWait;Ctx,7
	AND		#$FF
	CMP		#CTRLC
	BEQ		.0009
	PLP
	BPL		.0007
.0008:
	RTS
.0009:
	PLP
	RTS

;------------------------------------------------------------------------------
; Edit memory.
; ><memory address> <val1> <val2> ... <val8>
;------------------------------------------------------------------------------

doMemoryEdit:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		NumWorkArea
	STA		RangeStart
	LDA		NumWorkArea+2
	STA		RangeStart+2
	LDY		#0
.0001:
	PHY
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0002
	PLY
	SEP		#$20
	LDA		NumWorkArea
	STA		{RangeStart},Y
	REP		#$20
	INY
	CPY		#8
	BNE		.0001
	BRL		Mon1
.0002:
	PLY
	BRL		Mon1

;------------------------------------------------------------------------------
; Fill memory.
; $F <start address> <end address> <val1>
;------------------------------------------------------------------------------

doFill:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	MonErr
	LDA		NumWorkArea
	STA		RangeStart
	LDA		NumWorkArea+2
	STA		RangeStart+2
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	MonErr
	LDA		NumWorkArea
	STA		RangeEnd
	LDA		NumWorkArea+2
	STA		RangeEnd+2
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	MonErr
	LDX		NumWorkArea
	; Process in 32 bit mode
	SEP		#$200
	REP		#$100
	LDA		RangeEnd
	SEC
	SBC		RangeStart
	LDY		RangeStart
	FIL		$00
	; Back to 16 bits mode
	SEP		#$100
	REP		#$200
	BRL		Mon1

;------------------------------------------------------------------------------
; Disassemble code
;------------------------------------------------------------------------------

doDisassemble:
	JSR		MonGetch
	CMP		#'M'
	BEQ		.0002
.0004:
	CMP		#'N'
	BNE		.0003
	SEP		#$20
	MEM		8
	LDA		$BC
	ORA		#$40
	STA		$BC
	REP		#$20
	BRA		.0005
.0002:
	SEP		#$20
	LDA		$BC
	ORA		#$80
	STA		$BC
	REP		#$20
	JSR		MonGetch
	BRA		.0004
	MEM		16
.0003:
	DEX
	DEX
.0005:
	JSR		IgnoreBlanks
	JSR		GetRange
	LDA		RangeStart
	STA		$8F				; addra
	LDA		RangeStart+1
	STA		$90
	JSR		OutCRLF
	LDY		#20
.0001:
	PHY
	SEP		#$30
	JSR		dpycod
	REP		#$30
	JSR		OutCRLF
	PLY
	DEY
	BNE		.0001
	JMP		Mon1

;$BC flimflag

;------------------------------------------------------------------------------
; Jump to subroutine
;
; Either JSR for 16 bit address or JSL for 24 bit address
;------------------------------------------------------------------------------

doJump:
	JSR		MonGetch
	CMP		#'S'
	LBNE	Mon1
	JSR		MonGetch
	CMP		#'R'
	BNE		.testL
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		NumWorkArea
	STA		RangeEnd
	LDX		#0
	JSR		(RangeEnd,X)
	BRL		Mon1
.testL:
	CMP		#'L'
	LBNE	Mon1
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	LBEQ	Mon1
	LDA		#$5C			; JML opcode
	STA		RangeEnd-1
	LDA		NumWorkArea
	STA		RangeEnd
	LDA		NumWorkArea+1
	STA		RangeEnd+1
	LDA		#RangeEnd
	CACHE	#1				; 1= invalidate instruction line identified by accumulator
	JSL		RangeEnd
	BRL		Mon1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
DispRangeStart:
	LDA		RangeStart+1
	JSR		DispWord
	LDA		RangeStart
	JSR		DispByte
	LDA		#' '
	JMP		OutChar
	
;------------------------------------------------------------------------------
; Skip over blanks in the input
;------------------------------------------------------------------------------

IgnoreBlanks:
.0001:
	JSR		MonGetch
	CMP		#' '
	BEQ		.0001
	DEX
	DEX
	RTS

;------------------------------------------------------------------------------
; BIOSInput allows full screen editing of text until a carriage return is keyed
; at which point the line the cursor is on is copied to a buffer. The buffer
; must be at least TEXTCOLS characters in size.
;------------------------------------------------------------------------------
;
BIOSInput:
.bin1:
	JSR		KeybdGetCharWait
	AND		#$FF
	CMP		#CR
	BEQ		.bin2
	JSR		OutChar
	BRA		.bin1
.bin2:
	LDA		CursorX
	BEQ		.bin4
	LDA		VideoPos	; get current video position
	SEC
	SBC		CursorX		; go back to the start of the line
	ASL
	TAX
.bin3:
	LDA		VIDBUF,X
	AND		#$FF
	STA		(3,s),Y
	INX
	INX
	INY
	DEC		CursorX
	BNE		.bin3
	LDA		#0
.bin4:
	STA		(3,s),Y	; NULL terminate buffer
	RTS

.st0003:
	LDA		KEYBD
	BPL		.st0003
	PHA						; save off the char (we need to trash acc)
	LDA		KEYBD+4	; clear keyboard strobe (must be a read operation)
	PLA						; restore char
	JSR		DisplayChar
	BRA		.st0003
	ldy		#$0000
.st0001:
	ldx		#$0000
.st0002:
	inx
	bne		.st0002
	jsr		echo_switch
	iny
	bra		.st0001

msgStarting:
	.byte	"FT832 Test System Starting",CR,LF
	.byte	"65C02/65C816/65C832 Compatible",CR,LF,0

echo_switch:
	lda		$7100
	sta		$7000
	rts

;------------------------------------------------------------------------------
; On entry to the SSM task the .A register will be set to the task number
; being single stepped. The .X register will contain the address of the
; next instruction to execute.
;------------------------------------------------------------------------------

SSMInit:
	; setup SSM data segment in SDT
	LDY		#6
	LDA		#1
	XBAW
	LDA		#$0000
	LDX		#$882		; 1k data
	SDU
	; Setup SSM stack segment in SDT
	INY
	LDA		#$0400
	LDX		#$882		; 1k stack
	SDU
	; Setup SSM code segment in SDT
	INY
	LDA		#$0000
	XBAW
	LDA		#$0000
	LDX		#$905
	SDU
	JMF		8:.0001
.0001:
	; Initialize data selector and stack selector, pointer
	; The stack is begin switched from the one currently defined by
	; by the task table. So the return task needs to be popped off
	; the current stack and placed on the new one.
	PLX					; get the task to return to
	LDA		#7
	SEI
	TASS
	LDA		#$3FF		; setup stack pointer
	TAS
	CLI
	PHX					; save return task on new stack
	PEA		6
	PLDS

	LDA		#9
	JCR		SetIOFocus,$FD
	LDA		#$6100
	STA		NormAttr
	LDA		#4095		; set segment
	STA		Vidptr+4
	STA		Vidregs+4
	LDA		#$000B		; screen location is $FB0000
	STA		Vidptr+2
	STZ		Vidptr
	LDA		#$000E		; regset is at $FEA010
	STA		Vidregs+2
	LDA		#$A010
	STA		Vidregs
	LDY		#7
	LDA		#$10		; divide by 2 vertically, 1 horizontally
	JSR		SetVideoReg
	LDA		#180		; set window left position 672
	LDY		#2
	JSR		SetVideoReg
	LDA		#2
	LDY		#3
	JSR		SetVideoReg
	LDA		#32			; set window top position
	LDY		#4
	JSR		SetVideoReg
	JSR		GetTextRowsCols
	LDA		#DisplayChar
	STA		OutputVec
	JSR		ClearScreen
	JSR		HomeCursor
	PEA		0
	PEA		msgSSM
	JSR		DisplayString
	RTT
SSMTask:
	STA		WorkTR
	JSR		DispRegs
.0004:
	LDA		#'S'
	JSR		OutChar
	LDA		#'S'
	JSR		OutChar
	LDA		#'M'
	JSR		OutChar
	LDA		#'>'
.0005:
	JSR		OutChar
.0008:
	JSR		KeybdGetCharWait
	BCS		.0008
	AND		#$FF
	CMP		#'S'		; step
	BNE		.0001
.0002:
	RTT
	BRA		SSMTask
.0001:
	CMP		#'X'
	BNE		.0006
	LDA		reg_sr
	AND		#$EFFF
	STA		reg_sr
	JSR		BuildRec
	LDX		WorkTR
	LDT		ldtrec
	RTT
	BRA		SSMTask
.0006:
	CMP		#CR
	BNE		.0005
	LDA		CursorY
	ASL
	TAX
	LDA		CS:LineTbl,X
	CLC
	ADC		#4
	ASL
	TAX
	JSR		IgnoreBlanks
	JSR		MonGetch
	CMP		#'M'
	BNE		.0007
	JSR		doMemoryDump
.0007:
	BRL		.0005
	RTT
	BRL		SSMTask

msgSSM:
	.byte	"Single step mode task starting.",CR,LF,0

;------------------------------------------------------------------------------
; Convert Ascii character to screen character.
;------------------------------------------------------------------------------

AsciiToScreen:
	AND		#$FF
	BIT		#%00100000	; if bit 5 isn't set
	BEQ		.00001
	BIT		#%01000000	; or bit 6 isn't set
	BEQ		.00001
	AND		#%10011111
.00001:
	rts

	MEM		8
AsciiToScreen8:
	BIT		#%00100000	; if bit 5 isn't set
	BEQ		.00001
	BIT		#%01000000	; or bit 6 isn't set
	BEQ		.00001
	AND		#%10011111
.00001:
	rts

	MEM		16
;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
ScreenToAscii:
	AND		#$FF
	CMP		#26+1
	BCS		.0001
	ADC		#$60
.0001:
	RTS

;------------------------------------------------------------------------------
; Display a character on the screen device
; Expects the processor to be in 16 bit mode with 16 bit acc and 16 bit indexes
;------------------------------------------------------------------------------
;
DisplayChar:
	AND		#$0FF
	BIT		EscState		; check if processing escape sequence
	LBMI	processEsc
	CMP		#BS
	LBEQ	doBackSpace
	CMP		#$91			; cursor right
	LBEQ	doCursorRight
	CMP		#$93			; cursor left
	LBEQ	doCursorLeft
	CMP		#$90			; cursor up
	LBEQ	doCursorUp
	CMP		#$92			; cursor down
	LBEQ	doCursorDown
	CMP		#$99			; delete
	LBEQ	doDelete
	CMP		#CR
	BEQ		doCR
	CMP		#LF
	BEQ		doLF
	CMP		#$94
	LBEQ	doCursorHome	; cursor home
	CMP		#ESC
	BNE		.0003
	STZ		EscState		; put a -1 in the escape state
	DEC		EscState
	RTS
.0003:
	JSR		AsciiToScreen
	ORA		NormAttr
	PHA
	LDA		VideoPos
	ASL
	TAY
	PLA
	STA		{Vidptr},Y
	LDA		CursorX
	INA
	CMP		Textcols
	BNE		.0001
	STZ		CursorX
	LDA		CursorY
	INA
	CMP		Textrows
	BEQ		.0002
	STA		CursorY
	BRL		SyncVideoPos
.0002:
	DEA
	JSR		SyncVideoPos
	BRL		ScrollUp
.0001:
	STA		CursorX
	BRL		SyncVideoPos
doCR:
	STZ		CursorX
	BRL		SyncVideoPos
doLF:
	LDA		CursorY
	INA
	CMP		Textrows
	LBPL	ScrollUp
	STA		CursorY
	BRL		SyncVideoPos

; Process escape sequences for WYSE terminal emulation
; Handles:
; {esc}T		- clear to end of line
; {esc}W		- delete character
; {esc}`1		- cursor on
; {esc}`0		- cursor off
; {esc}({esc}G4	- reverse video
; {esc}({esc}G0	- normal video
;
; EscState
; -1 = first esc char
; -2 = second esc char
; ...
;
processEsc:
	LDX		EscState
	CPX		#-1
	BNE		.0006
	CMP		#'T'	; clear to EOL
	BNE		.0003
	LDA		VideoPos
	ASL
	TAY
	LDX		CursorX
	INX
.0001:
	CPX		Textcols
	BPL		.0002
	LDA		#' '
	ORA		NormAttr
	STA		{Vidptr},Y
	INX
	INY
	INY
	BNE		.0001
.0002:
	STZ		EscState
	RTS
.0003:
	CMP		#'W'
	BNE		.0004
	STZ		EscState
	BRL		doDelete
.0004:
	CMP		#'`'
	BNE		.0005
	LDA		#-2
	STA		EscState
	RTS
.0005:
	CMP		#'('
	BNE		.0008
	LDA		#-3
	STA		EscState
	RTS
.0008:
	STZ		EscState
	RTS
.0006:
	CPX		#-2
	BNE		.0007
	STZ		EscState
	CMP		#'1'
	LBEQ	CursorOn
	CMP		#'0'
	LBEQ	CursorOff
	RTS
.0007:
	CPX		#-3
	BNE		.0009
	CMP		#ESC
	BNE		.0008
	LDA		#-4
	STA		EscState
	RTS
.0009:
	CPX		#-4
	BNE		.0010
	CMP		#'G'
	BNE		.0008
	LDA		#-5
	STA		EscState
	RTS
.0010:
	CPX		#-5
	BNE		.0008
	STZ		EscState
	CMP		#'4'
	BNE		.0011
	LDA		NormAttr
	; Swap the high nybbles of the attribute
	XBA				
	SEP		#$30		; set 8 bit regs
	NDX		8			; tell the assembler
	MEM		8
	ROL
	ROL
	ROL
	ROL
	REP		#$30		; set 16 bit regs
	NDX		16			; tell the assembler
	MEM		16
	XBA
	AND		#$FF00
	STA		NormAttr
	RTS
.0011:
	CMP		#'0'
	BNE		.0012
	LDA		#$BF00		; Light Grey on Dark Grey
	STA		NormAttr
	RTS
.0012:
	LDA		#$BF00		; Light Grey on Dark Grey
	STA		NormAttr
	RTS

doBackSpace:
	LDX		CursorX
	BEQ		.0001		; Can't backspace anymore
	LDA		VideoPos
	ASL
	TAY
.0002:
	LDA		{Vidptr},Y
	DEY
	DEY
	STA		{Vidptr},Y
	INY4
	INX
	CPX		Textcols
	BNE		.0002
.0003:
	LDA		#' '
	ORA		NormAttr
	STA		{Vidptr},Y
	DEC		CursorX
	BRL		SyncVideoPos
.0001:
	RTS

; Deleting a character does not change the video position so there's no need
; to resynchronize it.

doDelete:
	LDX		CursorX
	LDA		VideoPos
	ASL
	TAY
.0002:
	INX
	CPX		Textcols
	BPL		.0001
	DEX
	INY
	INY
	LDA		{Vidptr},Y
	DEY
	DEY
	STA		{Vidptr},Y
	INY
	INY
	INX
	BRA		.0002
.0001:
	LDA		#' '
	ORA		NormAttr
	STA		{Vidptr},Y
	RTS

doCursorHome:
	LDA		CursorX
	BEQ		doCursor1
	STZ		CursorX
	BRA		SyncVideoPos
doCursorRight:
	LDA		CursorX
	INA
	CMP		Textcols
	BPL		doRTS
doCursor2:
	STA		CursorX
	BRA		SyncVideoPos
doCursorLeft:
	LDA		CursorX
	BEQ		doRTS
	DEA
	BRA		doCursor2
doCursorUp:
	LDA		CursorY
	BEQ		doRTS
	DEA
	BRA		doCursor1
doCursorDown:
	LDA		CursorY
	INA
	CMP		Textrows
	BPL		doRTS
doCursor1:
	STA		CursorY
	BRA		SyncVideoPos
doRTS:
	RTS

HomeCursor:
	LDA		#0
	STZ		CursorX
	STZ		CursorY

; Synchronize the absolute video position with the cursor co-ordinates.
;
SyncVideoPos:
	PHA
	PHY
	LDA		CursorY
	ASL
	TAX
	LDA		LineTbl,X
	CLC
	ADC		CursorX
	STA		VideoPos
	LDY		#13
	STA		{Vidregs},Y		; Update the position in the text controller
	PLY
	PLA
	RTS

OutCRLF:
	LDA		#CR
	JSR		OutChar
	LDA		#LF

OutChar:
.chkFocus:
	CLI
	PHA
	JSR		CheckIOFocus16
	BNE		.noFocus
	PLA
	PHX
	PHY
	LDX		#0
	JSR		(OutputVec,x)
	PLY
	PLX
	RTS
	; Here the task doesn't have the I/O focus and it's trying to
	; display something, so switch to another task until this task
	; has focus.
.noFocus:
	LDA		#$51
	STA		$7000
	JSL		FMTK_ScheduleTask	; schedule another task
	PLA
	BRA		.chkFocus

DisplayString:
	LDY		#0
.0002:
	LDA.B	{3,S},Y
	BEQ		.0001
	JSR		OutChar
	INY
	BRA		.0002
.0001:
	RTS		#4					; pop stack argument

DisplayString2:
	PLA							; pop return address
	PLX							; get string address parameter
	PHA							; push return address
	SEP		#$20				; ACC = 8 bit
	STX		StringPos
	LDY		#0
	LDX		#50
.0002:
	LDA		(StringPos),Y
	JSR		OutChar
	INY
	DEX
	BNE		.0002
.0001:
	REP		#$20				; ACC 16 bits
	RTS

GetTextRowsCols:
	PHA
	PHY
	LDY		#0
	LDA.UB	{Vidregs},Y
	STA		Textcols
	INY
	LDA.UB	{Vidregs},Y
	STA		Textrows
	PLY
	PLA
	RTS

; .Y = register number to set
; Acc = value
;
SetVideoReg:
	PHP								; save regs size settings
	SEP		#$20
	STA.B	{Vidregs},Y
	PLP								; restore reg size settings
	RTS

CursorOn:
	PHA
	PHY
	LDY		#9
	LDA		#$1F60
	STA		{Vidregs},Y
	PLY
	PLA
	RTS

CursorOff:
	PHA
	PHY
	LDY		#9
	LDA		#$0020
	STA		{Vidregs},Y
	PLY
	PLA
	RTS

ClearScreen:
.tstFocus:
	JSR		CheckIOFocus16
	BNE		.noFocus
	LDA		#$41
	STA		$7000
	LDX		#4095
	LDY		#$00
	LDA		#' '
	JSR		AsciiToScreen
	ORA		NormAttr
.0001:
	STA		{Vidptr},Y
	INY
	INY
	DEX
	BNE		.0001
	RTS
.noFocus:
	LDA		#$42
	STA		$7000
	JSL		FMTK_ScheduleTask	; Schedule another task
	BRA		.tstFocus

ScrollUp:
	LDY		#0				; .Y used as index to char
	LDX 	#2603			; number of chars on screen
.0001:
	PHY						; save off current .Y
	TYA								
	CLC						; Add double the number of text
	ADC		Textcols		; columns to .Y to find start of next
	CLC						; row 
	ADC		Textcols
	TAY						
	LDA		{Vidptr},Y	; .A = Load buffer[textcols+Y]
	PLY						; .Y = restore current .Y
	STA		{Vidptr},Y	; Store .A in buffer[0+Y]
	INY						; advance to next character
	INY						; decrement total char count
	DEX
	BNE		.0001
	LDA		Textrows
	DEA

BlankLine:
	ASL
	TAY
	LDA		CS:LineTbl,Y
	ASL
	TAY
	LDX		Textcols		; number of chars to clear
	LDA		NormAttr
	ORA		#$20			; space
.0001:
	STA		{Vidptr},Y
	INY					; increment to next char
	INY
	DEX						; decrement number of chars
	BNE		.0001
	RTS

DispDWord:
	XBAW
	JSR		DispWord
	XBAW
DispWord:
	XBA
	JSR		DispByte
	XBA
DispByte:
	PHA
	LSR
	LSR
	LSR
	LSR
	JSR		DispNybble
	PLA
DispNybble:
	PHA
	AND		#$0F
	CMP		#10
	BCC		.0001
	ADC		#'A'-11			; -11 cause the carry is set
	JSR		OutChar
	PLA
	RTS
.0001:
	ORA		#'0'
	JSR		OutChar
	PLA
	RTS

space:
	PHA
	LDA		#' '
	JSR		OutChar
	PLA
	RTS

;------------------------------------------------------------------------------
; Get a range (two hex numbers)
;------------------------------------------------------------------------------

GetRange:
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA		RangeStart
	STA		RangeEnd
	LDA		NumWorkArea+2
	STA		RangeStart+2
	STA		RangeEnd+2
	JSR		IgnoreBlanks
	JSR		GetHexNumber
	CPY		#0
	BEQ		.0001
	LDA		NumWorkArea
	STA		RangeEnd
	LDA		NumWorkArea+2
	STA		RangeEnd+2
.0001:
	RTS
	
;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of six digits.
; .X = text pointer (updated)
;------------------------------------------------------------------------------
;
GetHexNumber:
	LDY		#0					; maximum of eight digits
	STZ		NumWorkArea
	STZ		NumWorkArea+2
gthxn2:
	JSR		MonGetch
	JSR		AsciiToHexNybble
	BMI		gthxn1
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ORA		NumWorkArea
	STA		NumWorkArea
	INY
	CPY		#8
	BNE		gthxn2
	RTS
gthxn1:
	DEX
	DEX
	RTS

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	CMP		#'0'
	BCC		gthx3
	CMP		#'9'+1
	BCS		gthx5
	SEC
	SBC		#'0'
	RTS
gthx5:
	CMP		#'A'
	BCC		gthx3
	CMP		#'F'+1
	BCS		gthx6
	SEC
	SBC		#'A'
	CLC
	ADC		#10
	RTS
gthx6:
	CMP		#'a'
	BCC		gthx3
	CMP		#'z'+1
	BCS		gthx3
	SEC
	SBC		#'a'
	CLC
	ADC		#10
	RTS
gthx3:
	LDA		#-1		; not a hex number
	RTS

AsciiToDecNybble:
	CMP		#'0'
	BCC		gtdc3
	CMP		#'9'+1
	BCS		gtdc3
	SEC
	SBC		#'0'
	RTS
gtdc3:
	LDA		#-1
	RTS

getcharNoWait:
	LDA		#1
	STA		ZS:keybd_cmd
	TSK		#6
	LDA		ZS:keybd_char
	BPL		.0001
	SEC
	RTS
.0001:
	CLC
	RTS

getcharWait:
	LDA		#2
	STA		ZS:keybd_cmd
	TSK		#6
	LDA		ZS:keybd_char
	BPL		.0001
	SEC
	RTS
.0001:
	CLC
	RTS

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Keyboard processing routines follow.
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
ResetKbd:
	SEP		#$30
	MEM		8
	NDX		8
	STZ		KeyState1
	STZ		KeyState2
	LDA		#$FF
	STA		KEYBD
	JSR		KeybdWaitTx
	REP		#$30
	MEM		16
	NDX		16
	RTS
KeybdInit:
	LDA		#$2000
	TAS
	LDA		#5
	STA		keybd_cmd
	SEP		#$30
	MEM		8
	NDX		8
	STZ		KeyState1
	STZ		KeyState2
	LDY		#12
	RTT
.resetAgain:
	LDA		#$FF			; send reset code to keyboard
	STA		KEYBD
	JSR		KeybdWaitTx
.0001:
	JSR		KeybdRecvByte	; Look for $AA
	BCC		.tryAgain
	CMP		#$AA			;
	BEQ		.config
.0002:
	; wait until keyboard not busy
	JSR		Wait10ms
	LDA		KEYBD+1		;
	BIT		#$40
	BNE		.tryAgain
	LDA		#$FF			; send reset code to keyboard
	STA		KEYBD
	JSR		Wait10ms
	JSR		KeybdWaitTx		; wait until no longer busy
	JSR		KeybdRecvByte	; look for an ACK ($FA)
	BCC		.tryAgain
	CMP		#$FE
	BEQ		.tryAgain
	CMP		#$FA
	BNE		.tryAgain
	JSR		KeybdRecvByte
	CMP		#$FC			; reset error ?
	BEQ		.tryAgain
	CMP		#$AA			; reset complete okay ?
	BNE		.tryAgain
.config:
	JSR		KeybdWaitBusy
	LDA		#$F0			; send scan code select
	STA		KEYBD
	JSR		KeybdWaitTx
	BCC		.tryAgain
	JSR		KeybdRecvByte	; wait for response from keyboard
	BCC		.tryAgain
	CMP		#$FE
	BEQ		.tryAgain
	CMP		#$FA
	BEQ		.0004
.tryAgain:
	DEY
	BNE		.0001
	DEC		keybd_cmd
	BNE		.resetAgain
.keybdErr:
	REP		#$30
	PEA		0
	PEA		msgKeybdNR
	JSR		DisplayString
	RTT
	BRA		KeybdService
.0004:
	LDA		#2				; select scan code set #2
	STA		KEYBD
	JSR		KeybdWaitTx
	BCC		.tryAgain
	JSR		KeybdRecvByte
	BCC		.tryAgain
	REP		#$30
	RTT
	BRA		KeybdService

KeybdService:
	REP		#$30
	MEM		16
	NDX		16
	LDA		#$2000
	TAS
	LDA		keybd_cmd
	CMP		#1
	BNE		.0001
	JSR		KeybdGetCharNoWait
	BCS		.nokey
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.nokey
	LDA		#-1
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.0001:
	CMP		#2
	BNE		.0002
	JSR		KeybdGetCharWait
	STZ		keybd_cmd
	STA		keybd_char
	RTT
	BRA		KeybdService
.0002:
	RTT
	BRA		KeybdService

	MEM		8
	NDX		8

; Receive a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
KeybdRecvByte:
	PHY
	LDY		#20				; wait up to .2s
.0003:
	JSR		KeybdWaitBusy
	LDA		KEYBD+1	; wait for response from keyboard
	ASL						; is input buffer full ?
	BCS		.0004			; yes, branch
	JSR		Wait10ms		; wait a bit
	DEY
	BNE		.0003			; go back and try again
	PLY						; timeout
	CLC						; carry clear = no code
	RTS
.0004:
	LDA		KEYBD		; clear recieve state
	PLY
	SEC						; carry set = code available
	RTS

; Wait until the keyboard isn't busy anymore
; Wait until the keyboard transmit is complete
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitBusy:				; alias for KeybdWaitTx
KeybdWaitTx:
	PHA
	PHY
	LDY		#10				; wait a max of .1s
.0001:
	LDA		KEYBD+1
	BIT		#$40			; check for transmit busy bit
	BEQ		.0002			; branch if bit clear
	JSR		Wait10ms		; delay a little bit
	DEY						; go back and try again
	BNE		.0001
	PLY						; timed out
	PLA
	CLC						; return carry clear
	RTS
.0002:
	PLY						; wait complete, return 
	PLA
	SEC						; carry set
	RTS

; Wait approximately 10ms. Used by keyboard routines. Makes use of the free
; running counter #0.
; .A = trashed (=-5)
;
Wait10ms:
	PHA
	PHX				; save .X
	LDA		CNT0H	; get starting count
	TAX				; save it off in .X
.0002:
	SEC				; compare to current counter value
	SBC		CNT0H
	EOR		#$FF	; make negative
	CMP		#10
	BPL     .0001
	TXA				; prepare for next check, get startcount in .A
	BRA		.0002	; go back if less than 5 ticks
.0001:
	PLX				; restore .X
	PLA
	RTS

	MEM		16
	NDX		16

msgKeybdNR:
	.byte	CR,LF,"Keyboard not responding.",CR,LF,0

	cpu		FT833

KeybdGetCharNoWaitCtx:
	JSR		KeybdGetCharNoWait
	RTS		#0
	
KeybdGetCharNoWait:
	PHP
	SEI		#1
	REP		#$30
	MEM		16
	NDX		16
	JSR		CheckIOFocus16
	BNE		.noFocus
	SEP		#$20
	REP		#$10
	MEM		8
	NDX		16
;	STZ		TaskSwitchEn
	CLI
	LDA		#0
	STA		KeybdWaitFlag
	BRA		KeybdGetChar1
.noFocus:
	CLI
	PLP
	SEC		; flag no key available
	RTS

KeybdGetCharWait:
	PHP
	SEP		#$20
	REP		#$10
	MEM		8
	NDX		16
.0003:
	REP		#$30
	JSR		CheckIOFocus16
	BNE		.noFocus
	SEP		#$20
	CLI
	LDA		#$FF
	STA		KeybdWaitFlag
	BRA		KeybdGetChar1
.noFocus:
	JSL		FMTK_ScheduleTask	; go run something else for a bit
	BRA		.0003

; Wait for a keyboard character to be available
; Returns (CF=1) if no key available
; Return key (CF=0) if key is available
;
;
KeybdGetChar:
	PHP
	SEP		#$20		; 8 bit acc
	REP		#$10
	MEM		8
	NDX		16
KeybdGetChar1:
	PHX
	XBA					; force .B to zero for TAX
	LDA		#0
	XBA
.0002:
.0003:
	LDA		KEYBD+1		; check MSB of keyboard status reg.
	ROL
	ROL
	BCS		.0003		; check busy flag, branch if busy
	ROR
	BCS		.0006		; branch if keystroke ready
	BIT		KeybdWaitFlag
	BMI		.0003
	PLX
	PLP
	SEC
	RTS
.0011:
	JSL		FMTK_ScheduleTask	; go run something else for a bit
	BRA		.0003
.0006:
	LDA		KEYBD	; get scan code value
	STZ		KEYBD+2	; clear read flag
	;REP		#$20
	;JSR		DispByte
	;JSR		space
	;SEP		#$20
.0001:
	CMP		#SC_KEYUP	; keyup scan code ?
	LBEQ	.doKeyup	; 
	CMP		#SC_EXTEND	; extended scan code ?
	LBEQ	.doExtend
	CMP		#$14		; control ?
	LBEQ	.doCtrl
	CMP		#$12		; left shift
	LBEQ	.doShift
	CMP		#$59		; right shift
	LBEQ	.doShift
	CMP		#SC_NUMLOCK
	LBEQ	.doNumLock
	CMP		#SC_CAPSLOCK
	LBEQ	.doCapsLock
	CMP		#SC_SCROLLLOCK
	LBEQ	.doScrollLock
	LSR		KeyState1
	BCS		.0003
	TAX
	LDA		#$80
	BIT		KeyState2	; Is extended code ?
	BEQ		.0010
	LDA		#$7F
	AND		KeyState2
	STA		KeyState2
	LSR		KeyState1	; clear keyup
	TXA
	AND		#$7F
	TAX
	LDA		cs:keybdExtendedCodes,X
	BRA		.0008
.0010:
	LDA		#4
	BIT		KeyState2	; Is Cntrl down ?
	BEQ		.0009
	TXA
	AND		#$7F		; table is 128 chars
	TAX
	LDA		cs:keybdControlCodes,X
	BRA		.0008
.0009:
	LDA		#$1			; Is shift down ?
	BIT		KeyState2
	BEQ		.0007
	LDA		cs:shiftedScanCodes,X
	BRA		.0008
.0007:
	LDA		cs:unshiftedScanCodes,X
.0008:
	PLX
	PLP
	CLC
	RTS
	MEM		8
.doKeyup:
	LDA		#1
	TSB		KeyState1
	BRL		.0003
.doExtend:				; set extended key flag
	LDA		KeyState2
	ORA		#$80
	STA		KeyState2
	BRL		.0003
.doCtrl:
	LDA		#4
	LSR		KeyState1	; check key up/down	
	BCC		.0004		; keydown = carry clear
	TRB		KeyState2
	BRL		.0003
.0004:
	TSB		KeyState2	; set control active bit
	BRL		.0003
.doShift:
	LDA		#1
	LSR		KeyState1	; check key up/down	
	BCC		.0005
	TRB		KeyState2
	BRL		.0003
.0005:
	TSB		KeyState2
	BRL		.0003
.doNumLock:
	LDA		KeyState2
	EOR		#16
	STA		KeyState2
	SEP		#$30
	JSR		KeybdSetLEDStatus
	REP		#$20
	BRL		.0003
.doCapsLock:
	LDA		KeyState2
	EOR		#32
	STA		KeyState2
	SEP		#$30
	JSR		KeybdSetLEDStatus
	REP		#$20
	BRL		.0003
.doScrollLock:
	LDA		KeyState2
	EOR		#64
	STA		KeyState2
	SEP		#$30
	JSR		KeybdSetLEDStatus
	REP		#$20
	BRL		.0003

KeybdSetLEDStatus:
	LDA		#0
	STA		KeybdLEDs
	LDA		#16
	BIT		KeyState2
	BEQ		.0002
	LDA		KeybdLEDs	; set bit 1 for Num lock, 0 for scrolllock , 2 for caps lock
	ORA		#$2
	STA		KeybdLEDs
.0002:
	LDA		#32
	BIT		KeyState2
	BEQ		.0003
	LDA		KeybdLEDs
	ORA		#$4
	STA		KeybdLEDs
.0003:
	LDA		#64
	BIT		KeyState2
	BEQ		.0004
	LDA		KeybdLEDs
	ORA		#1
	STA		KeybdLEDs
.0004:
	LDA		#$ED		; set status LEDs command
	STA		KEYBD
	JSR		KeybdWaitTx
	JSR		KeybdRecvByte
	BCC		.0001
	CMP		#$FA
	LDA		KeybdLEDs
	STA		KEYBD
	JSR		KeybdWaitTx
	JSR		KeybdRecvByte	; wait for $FA byte
.0001:
	RTS


	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
unshiftedScanCodes:
	.byte	$2e,$a9,$2e,$a5,$a3,$a1,$a2,$ac
	.byte	$2e,$aa,$a8,$a6,$a4,$09,$60,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$71,$31,$2e
	.byte	$2e,$2e,$7a,$73,$61,$77,$32,$2e
	.byte	$2e,$63,$78,$64,$65,$34,$33,$2e
	.byte	$2e,$20,$76,$66,$74,$72,$35,$2e
	.byte	$2e,$6e,$62,$68,$67,$79,$36,$2e
	.byte	$2e,$2e,$6d,$6a,$75,$37,$38,$2e
	.byte	$2e,$2c,$6b,$69,$6f,$30,$39,$2e
	.byte	$2e,$2e,$2f,$6c,$3b,$70,$2d,$2e
	.byte	$2e,$2e,$27,$2e,$5b,$3d,$2e,$2e
	.byte	$ad,$2e,$0d,$5d,$2e,$5c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	.byte	$98,$7f,$92,$2e,$91,$90,$1b,$af
	.byte	$ab,$2e,$97,$2e,$2e,$96,$ae,$2e

	.byte	$2e,$2e,$2e,$a7,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$fa,$2e,$2e,$2e,$2e,$2e

shiftedScanCodes:
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$51,$21,$2e
	.byte	$2e,$2e,$5a,$53,$41,$57,$40,$2e
	.byte	$2e,$43,$58,$44,$45,$24,$23,$2e
	.byte	$2e,$20,$56,$46,$54,$52,$25,$2e
	.byte	$2e,$4e,$42,$48,$47,$59,$5e,$2e
	.byte	$2e,$2e,$4d,$4a,$55,$26,$2a,$2e
	.byte	$2e,$3c,$4b,$49,$4f,$29,$28,$2e
	.byte	$2e,$3e,$3f,$4c,$3a,$50,$5f,$2e
	.byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	.byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

; control
keybdControlCodes:
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$09,$7e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$11,$21,$2e
	.byte	$2e,$2e,$1a,$13,$01,$17,$40,$2e
	.byte	$2e,$03,$18,$04,$05,$24,$23,$2e
	.byte	$2e,$20,$16,$06,$14,$12,$25,$2e
	.byte	$2e,$0e,$02,$08,$07,$19,$5e,$2e
	.byte	$2e,$2e,$0d,$0a,$15,$26,$2a,$2e
	.byte	$2e,$3c,$0b,$09,$0f,$29,$28,$2e
	.byte	$2e,$3e,$3f,$0c,$3a,$10,$5f,$2e
	.byte	$2e,$2e,$22,$2e,$7b,$2b,$2e,$2e
	.byte	$2e,$2e,$0d,$7d,$2e,$7c,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$08,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$7f,$2e,$2e,$2e,$2e,$1b,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e

keybdExtendedCodes:
	.byte	$2e,$2e,$2e,$2e,$a3,$a1,$a2,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$2e,$2e,$2e,$2e,$2e,$2e,$2e
	.byte	$2e,$95,$2e,$93,$94,$2e,$2e,$2e
	.byte	$98,$99,$92,$2e,$91,$90,$2e,$2e
	.byte	$2e,$2e,$97,$2e,$2e,$96,$2e,$2e

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; SPI MASTER driver
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

; spi_master_init
; Initialize the spi master controller

spi_master_init:
	
	PHP
	SEP		#$20
	MEM		8
	LDA		#SPI_INIT_SD
	STA		SPI_TRANS_TYPE_REG
	LDA		#SPI_TRANS_START
	STA		SPI_TRANS_CTRL_REG
.0001:
	LDA		SPI_TRANS_STATUS_REG	; wait for SPI transfer to complete
	CMP		#SPI_TRANS_BUSY
	BEQ		.0001
	LDA		SPI_TRANS_ERROR_REG
	AND		#3	; INIT errors
	CMP		#SPI_INIT_NO_ERROR
	BEQ		.0004
	PLP
	MEM		16
	NDX		16
	PEA		0
	PEA		msgSpiInitError
	JSR		DisplayString
	LDA		#1
	RTS
.0004:
	PLP
	;PEA		0
	;PEA		msgSpiInited
	;JSR		DisplayString
	LDA		#0
	RTS

; spi_master_read
; read a block from the SD card
;
; Parameters:
;	32 bit buffer address pushed onto stack
;	32 bit block number pushed onto stack
;
spi_master_read:
	PHP
	SEP		#$20
	MEM		8
	NDX		16
	TSX
	LDA		4,X
	STA		SPI_SD_SECT_7_0_REG
	LDA		5,X
	STA		SPI_SD_SECT_15_8_REG
	LDA		6,X
	STA		SPI_SD_SECT_23_16_REG
	LDA		7,X
	STA		SPI_SD_SECT_31_24_REG
	LDA		8,X
	STA		bufptr
	LDA		9,X
	STA		bufptr+1
	LDA		10,X
	STA		bufptr+2
	LDA		11,X
	STA		bufptr+3
	LDA		#SPI_RW_READ_SD_BLOCK
	STA		SPI_TRANS_TYPE_REG
	LDA		#SPI_TRANS_START
	STA		SPI_TRANS_CTRL_REG
.0001:
	LDA		SPI_TRANS_STATUS_REG		; wait for SPI transfer to complete
	CMP		#SPI_TRANS_BUSY
	BEQ		.0001
	LDA		SPI_TRANS_ERROR_REG
	LSR
	LSR
	AND		#3	; INIT errors
	CMP		#SPI_READ_NO_ERROR
	BEQ		.0004
	PLP
	MEM		16
	PEA		0
	PEA		msgSpiReadError
	JSR		DisplayString
	LDA		#1
	RTS		#8
.0004:
	REP		#$10
	MEM		8
	NDX		16
	LDX		#512
	LDY		#0
.0003:
	;TXA
	;AND		#$0F
	;BNE		.0002
	;PLP
	;JSR		OutCRLF
	;PHP
	;SEP		#$20
.0002:
	LDA		SPI_RX_FIFO_DATA_REG
	STA		{bufptr},Y
	INY
	;PLP
	;JSR		DispByte
	;JSR		space
	;PHP
	SEP		#$20
	DEX
	BNE		.0003
	PLP
	;JSR		OutCRLF
	MEM		16
	NDX		16
	LDA		#0
	RTS		#8

spi_master_write:
	PHP
	SEP		#$20
	MEM		8
	NDX		16

	TSX
	LDA		8,X
	STA		bufptr
	LDA		9,X
	STA		bufptr+1
	LDA		10,X
	STA		bufptr+2
	LDA		11,X
	STA		bufptr+3

	LDY		#0
.0001:
	LDA		{bufptr},Y
	STA		SPI_TX_FIFO_DATA_REG
	INY
	CPY		#512
	BNE		.0001

	LDA		4,X
	STA		SPI_SD_SECT_7_0_REG
	LDA		5,X
	STA		SPI_SD_SECT_15_8_REG
	LDA		6,X
	STA		SPI_SD_SECT_23_16_REG
	LDA		7,X
	STA		SPI_SD_SECT_31_24_REG

	LDA		#SPI_RW_WRITE_SD_BLOCK
	STA		SPI_TRANS_TYPE_REG
	LDA		#SPI_TRANS_START
	STA		SPI_TRANS_CTRL_REG
.0002:
	LDA		SPI_TRANS_STATUS_REG		; wait for SPI transfer to complete
	CMP		#SPI_TRANS_BUSY
	BEQ		.0002
	LDA		SPI_TRANS_ERROR_REG
	LSR
	LSR
	LSR
	LSR
	AND		#3	; write errors
	CMP		#SPI_WRITE_NO_ERROR
	BEQ		.0004
	PLP
	MEM		16
	PEA		0
	PEA		msgSpiWriteError
	JSR		DisplayString
	LDA		#1
	RTS		#8
.0004:
	PLP
	LDA		#0
	RTS		#8

msgSpiInitError:
.byte	"Error initializing SPI master",$0D,$0A,$00
msgSpiInited:
.byte	"SPI master inited",$0D,$0A,$00
msgSpiReadError:
.byte	"SPI read error",$0D,$0A,$00
msgSpiWriteError:
.byte	"SPI write error",$0D,$0A,$00

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; RTC driver for MCP7941x
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

rtc_init:
		LDA		#17					; constant for 400kHz I2C from 33MHz
		STA		I2C_PRESCALE_LO
		RTS

; Read all the RTC sram registers into a buffer

rtc_read:
		PHP
		SEP		#$30
		MEM		8
		NDX		8
		LDA		#$80				; enable I2C
		STA		I2C_CONTROL
		LDA		#$DE				; read address, write op
		LDY		#$90				; STA + wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDA		#$00				; address zero
		LDY		#$10				; wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDA		#$DF				; read address, read op
		LDY		#$90				; STA + wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDX		#0
.0001:
		LDA		#$20				; rd bit
		STA		I2C_CMD
		JSR		rtc_wait_tip
		LDA		I2C_STAT
		BMI		.rxerr
		LDA		I2C_RX
		STA		RTCBuf,X
		INX
		CPX		#$5F
		BNE		.0001
		LDA		#$68				; STO, rd bit + nack
		STA		I2C_CMD
		JSR		rtc_wait_tip
		LDA		I2C_STAT
		BMI		.rxerr
		LDA		I2C_RX
		STA		RTCBuf,X
		LDA		#0					; disable I2C and return 0
		STA		I2C_CONTROL
		PLP
		RTS
.rxerr:
		STZ		I2C_CONTROL			; disable I2C and return status
		PLP
		RTS

rtc_wait_tip:
.0001:
		LDA		I2C_STAT
		AND		#$4					; transmit in progress bit
		BNE		.0001
		RTS

rtc_wr_cmd:
		STA		I2C_TX
		STY		I2C_CMD
		JSR		rtc_wait_tip
		LDA		I2C_STAT
		RTS

rtc_write:
		PHP
		SEP		#$30
		MEM		8
		NDX		8
		LDA		#$80				; enable I2C
		STA		I2C_CONTROL
		LDA		#$DE				; read address, write op
		LDY		#$90				; STA + wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDA		#$00				; address zero
		LDY		#$10				; wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDX		#0
.0001:
		LDA		RTCBuf,X
		LDY		#$10
		JSR		rtc_wr_cmd
		BMI		.rxerr
		INX
		CPX		#$5F
		BNE		.0001
		LDA		RTCBuf,X
		LDY		#$50				; STO, wr bit
		JSR		rtc_wr_cmd
		BMI		.rxerr
		LDA		#0					; disable I2C and return 0
		STA		I2C_CONTROL
		PLP
		RTS
.rxerr:
		STZ		I2C_CONTROL			; disable I2C and return status
		PLP
		RTS

msgRtcReadFail:
	.byte	"RTC read/write failed.",$0D,$0A,$00

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

; Get char routine for Supermon
; This routine might be called with 8 bit regs.
;
	MEM		16
	NDX		16
SuperGetch:
	JSR		KeybdGetCharNoWait
	AND		#$FF
	PLO
	RTS

; Put char routine for Supermon
;
SuperPutch:
	JSR		OutChar
	PLO
	RTS

warm_start:
	SEP		#$100		; 16 bit mode
	REP		#$30		; 16 bit MEM,NDX
	MEM		16
	NDX		16
	LDA		#$3FFF
	TAS
	JSR		CursorOn
	BRL		Mon1

	cpu		FT833
ICacheIL832:
	CACHE	#1			; 1= invalidate instruction line identified by accumulator
	RTS

;============================================================================
;============================================================================
; SD Card COS
;============================================================================
;============================================================================

; "Format" the SD card. This basically just sets the BAM to zero indicating
; no allocated clusters, and zeros out the root directory
;
SDC_Format:
	LDA		#0
	LDX		#0
.zeroSector:
	STA		$F0000,X
	INX
	CPX		#512
	BNE		.zeroSector
	LDA		#$FFFF				; the first 17 clusters are allocated
	STA		$F0000				; for the BAM and root directory
	LDA		#$8000
	STA		$F0002

	JSR		spi_master_init
	STZ		secnum				; set starting sector # to zero
	STZ		secnum+2
.nextSector:
	PEA		$000F				; push buffer address
	PEA		$0000
	LDA		secnum+2			; push sector number
	PHA
	LDA		secnum
	PHA
	JSR		spi_master_write
	STZ		$F0000
	STZ		$F0002
	LDA		secnum
	CMP		#135
	BEQ		.doneFmt
	INC		secnum
	BRA		.nextSector
.doneFmt:
	RTS

; Parameters
; .A = # of sectors to read
; starting sector number
; pointer to buffer
;
SDC_Jmp:
	JMP		(spi_rw_vect)

SDC_ReadWriteMultiple:
	STA		numsec
	TSA
	SEC
	SBC		#8
	TAS
	LDA		11,S
	STA		1,S
	LDA		13,S
	STA		3,S
	LDA		15,S
	STA		5,S
	LDA		17,S
	STA		7,S
.nextSector:
	JSR		SDC_Jmp
	CMP		#0
	BNE		.abort
	TSA
	SEC
	SBC		#8
	TAS
	TSX
	; increment the starting sector #
	INC		11,X
	BNE		.0001
	INC		13,X
.0001:
	CLC
	; increment buffer pointer by 512 bytes
	INC		17,X
	INC		17,X
	; copy parameters back to stack
	LDA		11,X
	STA		1,X
	LDA		13,X
	STA		3,X
	LDA		15,X
	STA		5,X
	LDA		17,X
	STA		7,X
	DEC		numsec
	BNE		.nextSector
.abort:
	RTS		#8

SDC_SaveRootDir:
	LDA		#spi_master_write
	BRA		SDC_SRD1
SDC_LoadRootDir:
	LDA		#spi_master_read	; flag an spi read
SDC_SRD1:
	STA		spi_rw_vect
	PEA		$000E				; directory buffer address = $EF000
	PEA		$F000
	PEA		$0
	LDA		#128				; root directory is at sector 128
	PHA
	LDA		#8					; 8 sectors to load
	JSR		SDC_ReadWriteMultiple
	RTS

SDC_SaveBAM:
	LDA		#spi_master_write
	BRA		SDC_SVB1
SDC_LoadBAM:
	LDA		#spi_master_read
SDC_SVB1:
	STA		spi_rw_vect
	PEA		$000F
	PEA		$0000
	PEA		$0000				; BAM starts at sector zero
	PEA		$0000
	LDA		#128				; 128 sectors to read
	JSR		SDC_ReadWriteMultiple
	RTS

; Parameters (on stack)
; pointer to filename
; pointer to disk buffer
;
SDC_Loadfile:
	JSR		SDC_LoadRootDir
	LDX		#32
.nxt2:
	LDY		#0
	LDA		#$000E
	STA		dirptr+2
	LDA		#$F000
	AAX
	STA		dirptr
.nxtCmp:
	LDA.B	{3,S},Y
	BEQ		.doneCmp
	CMP.B	[dirptr],Y
	BNE		.nextDirentry
	INY
	CPY		#15
	BLT		.nxtCmp
.found:
	LDA		9,S
	TAX
	LDA		7,S
	PHX
	PHA
	LDY		#26
	LDA		[dirptr],Y 
	TAX
	LDY		#24
	LDA		[dirptr],Y
	JSR		ClusterToSector
	PHX
	PHA
	LDY		#29
	LDA		[dirptr],Y
	LSR
	JSR		SDC_ReadMultiple
	RTS		#8
.doneCmp:
	LDA		[dirptr],Y
	BEQ		.found
.nextDirentry:
	TXA
	CLC
	ADC		#32
	TAX
	CPX		#$1000
	BLT		.nxt2
	PEA		0
	PEA		msgFileNotFound
	JSR		DisplayString
	RTS		#8

ClusterToSector:
	STA		NumWorkArea
	STX		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	ASL		NumWorkArea
	ROL		NumWorkArea+2
	LDA		NumWorkArea
	LDX		NumWorkArea+2
	RTS

msgFileNotFound:
	.byte	"File not found",$0D,$0A,$00

;============================================================================
; BASIC support functions
;============================================================================

; Char get routine for BASIC
; Same thing as for Supermon, except carry flag needs to be inverted
; This routine should be called from a different context than the BIOS,
; otherwise the call will be ignored.
;
BasicGetch:
	JSR		KeybdGetCharNoWait
	AND		#$FF
	CMC
	PLO
	RTS

xitBasic:
	STA		ExitCode
	LDA		running_task
	JSR		ReleaseIOFocus
	LDX		#TCB_SIZE
	MUL
	STZ		tcbs+TCB_status,X	; no longer ready
	LDA		#0
	JSR		SetIOFocus
.0001:
	JSL		FMTK_ScheduleTask
	;TSK		JMP:#0		; scheduler will start monitor again, it's in the ready queue
	BRA		.0001			; we shouldn't get here, another ready task was scheduled

BASIC_Savefile:
	JSR		spi_master_init
	BNE		.0001
	LDA		#spi_master_write
	STA		spi_rw_vect
	PEA		$1		; buffer = $10000
	PEA		$0
	PEA		$0
	PEA		136		; starting sector
	LDA		#64		; 64 sectors (32 kiB)
	JSR		SDC_ReadWriteMultiple
.0001:
	PLO
	RTS

BASIC_Loadfile:
	JSR		spi_master_init
	BNE		.0001		
	LDA		#spi_master_read
	STA		spi_rw_vect
	PEA		$1		; buffer = $10000
	PEA		$0
	PEA		$0
	PEA		136		; starting sector
	LDA		#64		; 64 sectors (32 kiB)
	JSR		SDC_ReadWriteMultiple
.0001:
	PLO
	RTS

;============================================================================
; Multi-tasking kernel
;============================================================================

FMTK_Init:
	SEP		#$200
	REP		#$130
	MEM		32
	NDX		32
	STZ.H	running_task

	JSR		ZeroIRQHooks
	JSR		InitMSGArray
	JSR		InitMBXArray
	JSR		InitTCBArray
	JSR		InitJCBArray
	SEP		#$100
	REP		#$230
	RTS

	; zero out the IRQ hook vectors
ZeroIRQHooks:
	LDA		#0
	TAX
.0001:
	STA		IRQ1Hook,X
	INX4
	CPX		#MAX_IRQ_HOOKS*8
	BNE		.0001
	RTS


	; initialize mailbox array
	; create free mailbox list
InitMBXArray:
	LDY		#0
.nxtMbx:
	TYA
	JSR		hMbxToAddr
	TAX
	TYA
	STA.H	MBX_number,X
	INA
	STA.H	MBX_link,X
	INY
	CPY		#NR_MBX
	BLT		.nxtMbx
	LDA		#$FFFFFFFF
	STA.H	MBX_link,X
	STZ.H	freeMBX
	RTS

	; initialize message array
	; create the free message list
	; for each message
	; msg->link = handle of next message
InitMSGArray:
	LDY		#0
.nxtMsg:
	TYA
	JSR		hMsgToAddr
	TAX
	INY
	TYA
	STA.H	MSG_link,X
	CPY		#NR_MSG
	BLT		.nxtMsg
	; flag the last message as no more links
	LDA		#$FFFFFFFF
	STA.H	MSG_link,X
	; now point free list to first message
	STZ.H	freeMSG
	RTS

	; Initialize JCB array
InitJCBArray:
	LDY		#0
.nxtJcb:
	TYA
	JSR		hJcbToAddr
	TAX
	TYA
	STA.B	JCB_number,X
	LDA		#$FFFFFFFF
	STA.B	JCB_iof_next,X
	STA.B	JCB_iof_prev,X
	STZ.B	JCB_user_name,X
	STZ.B	JCB_path,X
	STZ.B	JCB_exit_runfile,X
	STZ.B	JCB_command_line,X
	STZ.B	JCB_CursorRow,X
	STZ.B	JCB_CursorCol,X
	LDA		#$BF00
	STA.H	JCB_NormAttr,X
	STZ.H	KeyState1,X
	STZ.H	KeyState2,X
	STZ.B	JCB_KeybdHead,X
	STZ.B	JCB_KeybdTail,X
	PHY
	LDY		#0
.nxt1:
	TYA
	PHX
	AAX						; add .A and .X
	TAX
	LDA		#$FFFFFFFF
	STA.H	JCB_hMbxs,X
	PLX
	INY
	INY
	CPY		#NR_MBXperJCB*2
	BLT		.nxt1
	PLY
	INY
	CPY		#NR_JCB
	BLT		.nxtJcb
	RTS

InitTCBArray:
	; Initialize TCB array
	LDY		#0
.nxtTcb:
	TYA
	JSR		hTcbToAddr
	TAX
	TYA
	STA.H	TCB_number,X
	LDA		#$FFFFFFFF
	STA.H	TCB_mbq_next,X
	STA.H	TCB_mbq_prev,X
	STA.H	TCB_msg_link,X
	STA.H	TCB_hWaitMbx,X
	STA.B	TCB_hJcb,X
	LDA		#2
	STA.B	TCB_priority,X
	STZ.B	TCB_status,X
	STZ		TCB_start_tick,X
	STZ		TCB_end_tick,X
	STZ		TCB_ticks,X
	STZ		TCB_exception,X
	INY
	CPY		#NR_TCB
	BLT		.nxtTcb
	RTS

.include "FMTKmsg.asm"

	MEM		32
	NDX		32

LockSysSema:
	SEI		#1
	RTS
UnlockSysSema:
	CLI		; SEI #0
	RTS

	MEM		32
	NDX		32
SetIOFocus32:
	STA.H	IOFocusTask
	RTS
GetIOFocus32:
	LDA.H	IOFocusTask
	RTS

; Returns:
; .ZF = 1 if task has IO focus

CheckIOFocus32:
	LDA		#$40
	STA		$7000
	LDA.H	running_task
	CMP.H	IOFocusTask
	RTS

RequestIOFocus32:
RequestIOFocus16:
RequestIOFocus:
	BMS		IOFocusBmp
	RTS

RequestIOFocus32:
ReleaseIOFocus16:
ReleaseIOFocus:
	BMC		IOFocusBmp
	RTS

RequestIOFocus32:
TestIOFocus16:
TestIOFocus:
	BMT		IOFocusBmp
	RTS

	MEM		16
	NDX		16
SetIOFocus16:
	STA		IOFocusTask
	RTS
GetIOFocus16:
	LDA		IOFocusTask
	RTS
CheckIOFocus16:
	LDA		#$40
	STA		$7000
	LDA		running_task
	CMP		IOFocusTask
	RTS

	MEM		32
	NDX		32

	; Get the handle of the currently active JCB. This will be the one for
	; which the running task is owned by.
GetJCB:
	LDA.H	running_task
	JSR		hTcbToAddr
	PHX
	TAX
	LDA.B	TCB_hJcb,X
	PLX
	RTS


;----------------------------------------------------------------------------
; Sleep
;	Put task to sleep.
; Parameters:
;	.A	length of time to sleep
;----------------------------------------------------------------------------

FMTK_Sleep:
		PHA
		LDA.H	running_task
		STA.H	TIMEOUT_LIST+2
		JSR		hTcbToAddr
		TAX
		LDA		#TS_TIMEOUT
		STA		TCB_status,X
		PLA
		STA		TIMEOUT_LIST+4
		LDA		#TOL_INS
		STA.B	TIMEOUT_LIST
		RTC		#0

;----------------------------------------------------------------------------
; FMTK_KillTask:
;	Kill a task.
;----------------------------------------------------------------------------

FMTK_KillTask:
		JSR		KillTask
		RTC		#0
KillTask:
		PHA
		STA.H	TIMEOUT_LIST+2	; remove task from timeout list (it might be on)
		LDA		#TOL_RMV
		STA.B	TIMEOUT_LIST
		PLA
		PHA
		JSR		hTcbToAddr
		TAX
		STZ		TCB_status,X	; remove task from ready list
		; Remove task from Job's task list
		LDA.B	TCB_hJcb,X
		JSR		hJcbToAddr
		TAX
		PLA						; .A = taskno
		LDY		#0
.0002:
		PHX
		PHA
		TYA						; setup for X+Y addressing
		AAX
		PLA
		CMP.H	JCB_tasks,X
		BNE		.0001
		STZ.H	JCB_tasks,X		; set field to -1
		DEC.H	JCB_tasks,X
.0001:	
		PLX
		INY
		INY
		CPY		#16
		BLT		.0002
		; The Job is finished if there are no more tasks associated with it.
		LDY		#0
.0003:
		PHX
		TYA
		AAX						; .A = .A + .X
		TAX						;
		LDA.H	JCB_tasks,X
		BPL		.notDoneJob
		PLX
		INY
		INY
		CPY		#16
		BLT		.0003
		; Done the job, add the jcb to the free list.
		LDA.B	freeJCB
		STA.B	JCB_next,X
		LDA.B	TCB_number,X
		STA.B	freeJCB
		RTS
.notDoneJob:
		PLX
		RTS

FMTK_ExitTask:
		LDA.H	running_task
		JSR		KillTask
		BRL		FMTK_ScheduleTask

;----------------------------------------------------------------------------
; SelectTaskToRun:
;
; Selects a task to run from the ready fifo. The ready fifo is really a 
; group of fifos, one each for a priority group. Priority groups are
; priorities of: $0x, $1x, $2x, $3x, $4x
;
; Returns
;	.A = task number to run
; Modifies:
;	.X, .Y, and flags
;----------------------------------------------------------------------------

StartQ:
	.byte	0,1,0,2,0,3,0,4,0,1,0,2,0,3,0,4

SelectTaskToRun:
	LDA		#4
	STA.B	qcnt
	LDA.B	TickCount		; vary the starting queue to check
	AND		#$0F			; based on the tick count
	TAY
	LDA.B	StartQ,Y
	ASL
	TAX
.nextQ:
.notReady:
	LDA.H	READY_FIFO_CNT,X	; get count of ready tasks in fifo
	BEQ		.fifoEmpty
	LDA.H	READY_FIFO,X	; get ready task from fifo
	JSR		hTcbToAddr
	TAY
	LDA.B	TCB_status,Y	; check the status and make sure it's ready
	BIT		#TS_READY|TS_PREEMPT
	BEQ		.notReady
	LDA.H	TCB_number,Y
	STA.H	READY_FIFO,X	; add back to fifo as last entry
	RTS

	; move to the next queue
.fifoEmpty:
	INX
	INX
	CPX		#10
	BLT		.0001
	LDX		#0				; cycle back around to first Q
.0001:
	DEC.B	qcnt
	BNE		.nextQ
	LDA		running_task	; if all queues empty, keep running the current
	RTS

;----------------------------------------------------------------------------
; Insert task into ready fifo.
;
; If the task has a bad priority setting then it's added as a lowest
; priority task, priority zero. It's desired for the task to run even if
; the priority is screwy.
;
; Parameters:
;	.A = handle to TCB
; Modifies:
;	.X = priority queue index
;----------------------------------------------------------------------------

InsertIntoReadyFifo:
	PHA
	JSR		hTcbToAddr
	TAX							; .X = task number (index into tables)
	LDA		#TS_READY			; set task status to ready
	STA.B	TCB_status,X
	LDA.B	TCB_priority,X		; get the priority
	LSR							; use upper nybble to identify priority que
	LSR
	LSR
	LSR
	CMP		#4					; valid priority ?
	BLE		.0001
	LDA		#0
.0001:
	ASL
	TAX
	PLA
	STA.H	READY_FIFO,X
	RTS

; IRQ routine for all modes. The interrupted task must of had interrupts
; enabled and this status should be saved on the stack with the value of
; the status register. The RTI instruction will pop the status register off
; the stack and restore the interrupt enable.
; Note that all this routine does is switch to a task which has a different
; register set, so there's no need to stack and restore registers. The
; task switch also allows the routine to be located anywhere in the memory
; system, so we don't have to worry about using up bank 0 memory.

IRQRout832:
IRQRout816:
IRQRout02:
	TSK		#1			; switch to the interrupt handling task
	RTI

;----------------------------------------------------------------------------
; Select a task to run from the ready queue.
; Called by some OS primitives
; Even if the task was preempted a regular RTT instruction is used to
; return. This is because this function was called via JCR.
;----------------------------------------------------------------------------

FMTK_ScheduleTask:
	; update the number of tick the task has been running.
	PHP						; makes things look like an IRQ call
	PHO						; must stack this for RTI
	SEP		#$7200			; switch to 32 bit mode
	REP		#$0130			; with interrupts disabled
	PHD						; save register set on stack
	PHB
	PHA
	PHX
	PHY
	LDA.H	running_task	; get currently running task
	JSR		hTcbToAddr		; get address from handle
	TAX
	TSA
	STA		TCB_sp,X
	PLO
	TOA
	STA		TCB_o0,X
	PLO
	TOA
	STA		TCB_o1,X
	PLO
	TOA
	STA		TCB_o2,X
	PLO
	TOA
	STA		TCB_o3,X
	PLO
	TOA
	STA		TCB_o4,X
	PLO
	TOA
	STA		TCB_o5,X
	PLO
	TOA
	STA		TCB_o6,X
	PLO
	TOA
	STA		TCB_o7,X
	LDA		TickCount		; get the tick count
	STA		TCB_end_tick,X	; store it in end ticks
	SEC
	SBC		TCB_start_tick,X; subtract off the latest starting tick
	CLC						; to get the difference 
	ADC		TCB_ticks,X		; ticks = ticks + (end tick - start tick)
	STA		TCB_ticks,X
	LDA		#RT_RTL			; needs an RTL return
	STA.B	TCB_rettype,X
	JSR		SelectTaskToRun
	STA.H	running_task
	JSR		hTcbToAddr		; handle to address
	TAX
	LDA		#TS_READY		; reset task status to ready
	STA.B	TCB_status,X
	LDA		TickCount		; get the tick count
	STA		TCB_start_tick,X	; update starting tick
	LDA		TCB_o7,X
	TAO
	PHO
	LDA		TCB_o6,X
	TAO
	PHO
	LDA		TCB_o5,X
	TAO
	PHO
	LDA		TCB_o4,X
	TAO
	PHO
	LDA		TCB_o3,X
	TAO
	PHO
	LDA		TCB_o2,X
	TAO
	PHO
	LDA		TCB_o1,X
	TAO
	PHO
	LDA		TCB_o0,X
	TAO
	PHO
	LDA		TCB_sp,X
	TAS
	; increment the return address on stack
	CLC						; we only bother to increment
	LDA.H	18,S			; the PC and not change PB
	ADC		#1				; assuming the last instruction
	STA.H	18,S			; in the bank wasn't a JSL
	PLY
	PLX
	PLA
	PLB
	PLD
	RTI

;----------------------------------------------------------------------------
; This task has interrupts masked in it's startup record and therefore runs
; with interrupts masked as the task never enables interrupts. Note that it's
; important that interrupts are masked while this is running, otherwise the
; uncleared interrupt status would cause another interrupt resulting in an
; infinite interrupt loop.
;
; This task always needs to return using a RTI in order to keep the internal
; IRQ state stack in sync.
;----------------------------------------------------------------------------
Task1:
	; Counter #1 is set to interrupt at a 50Hz rate
;	LDA		#$2A	;94		; divide by 95794 (for 50Hz)
;	STA.B	CTR1_LMT		; FFFFFE = 2Hz with 33MHz clock
;	LDA		#$2C	;57		; 
;	STA.B	CTR1_LMT+1
;	LDA		#$0A	;09
;	STA.B	CTR1_LMT+2
;	LDA		#$05		; count down, on mpu clock, irq disenabled
;	STA.B	CTR1_CTRL
;	RTT					; falls through on next task activation

TimeSliceIRQ:
	SEP		#$7200		; with all interrupts disabled
	REP		#$0130		; switch to 32 bit mode
	PHD
	PHB
	PHA
	PHX
	PHY
	LDA.B	MPU_IRQ_STATUS	; check if counter expired
	BIT		#2				; counter #1 IRQ active bit
	LBEQ	.notTimeSlice	; no IRQ ?

	; update the tick count
	LDA		TickCount		; increment the tick count
	INA						; lower 16 bits
	STA		TickCount
	STA.B	$FD00A4			; update on-screen IRQ live indicator

	; clear the IRQ source
	LDA		#$05			; count down, on mpu clock, irq enabled (clears irq)
	STA.B	CTR1_CTRL		; set control register clearing interrupt

	; Set flag for EhBASIC Irq
	LDA.B	$100DF		
	ORA		#$20
	STA.B	$100DF
	
	; update the number of tick the task has been running.
	; and set the task status to PREEMPT
	LDA.H	running_task
	JSR		hTcbToAddr		; get address from handle
	TAX
	TSA
	STA		TCB_sp,X
	PLO
	TOA
	STA		TCB_o0,X
	PLO
	TOA
	STA		TCB_o1,X
	PLO
	TOA
	STA		TCB_o2,X
	PLO
	TOA
	STA		TCB_o3,X
	PLO
	TOA
	STA		TCB_o4,X
	PLO
	TOA
	STA		TCB_o5,X
	PLO
	TOA
	STA		TCB_o6,X
	PLO
	TOA
	STA		TCB_o7,X
	LDA		TickCount		; get the tick count
	STA		TCB_end_tick,X	; store it in end ticks
	SEC
	SBC		TCB_start_tick,X; subtract off the latest starting tick
	CLC						; to get the difference 
	ADC		TCB_ticks,X		; ticks = ticks + (end tick - start tick)
	STA		TCB_ticks,X
	LDA		#TS_PREEMPT
	STA.B	TCB_status,X	; set status of outgoing task to PREEMPT

	; take care of the timeout list
.nextTo:
	LDA		#TOL_DEC		; .A = decrement command #
	STA.B	TIMEOUT_LIST	; decrement the timeout list
	NOP						; might take up to 3 clock cycles
	NOP
	LDA.H	TIMEOUT_LIST+2	; get any timedout task
	BMI		.noMoreTos
	JSR		InsertIntoReadyFifo	; placed timedout task on ready list
	BRA		.nextTo

	; Switch to the next task to run
.noMoreTos:
	LDA.B	TaskSwitchEn	; only switch tasks if enabled
	BEQ		.0001
	JSR		SelectTaskToRun
	BRA		.0002
.0001:
	LDA.H	running_task
.0002:
	STA.H	running_task	; update running task var
	JSR		hTcbToAddr		; convert task handle to address
	TAX
	LDA		TickCount		; update starting tick for task
	STA		TCB_start_tick,X
	LDA		TCB_sp,X
	TAS
	LDA		TCB_o7,X
	TAO
	PHO
	LDA		TCB_o6,X
	TAO
	PHO
	LDA		TCB_o5,X
	TAO
	PHO
	LDA		TCB_o4,X
	TAO
	PHO
	LDA		TCB_o3,X
	TAO
	PHO
	LDA		TCB_o2,X
	TAO
	PHO
	LDA		TCB_o1,X
	TAO
	PHO
	LDA		TCB_o0,X
	TAO
	PHO
	PLY
	PLX
	PLA
	PLB
	PLD
	RTI						;

; We get here if it wasn't a timeslice interrupt. There still might be other
; devices tied to the same IRQ line which need servicing.

.notTimeSlice:
	LDX		#0
.0002:
	LDA		IRQ1Hook,X		; get the hook pointer
	BEQ		.noHook			; check if valid
	PHX						; save off .X
	LDA		IRQ1Hook+4,X	; get offset value
	JSL		CallHook		; call the hook routine
	PLX						; restore .X
.noHook:
	INX4					; move to next hook
	INX4
	CPX		#MAX_IRQ_HOOKS*8
	BNE		.0002			; last allowed hook ?
	PLY
	PLX
	PLA
	PLB
	PLD
	RTI

CallHook:
	TAO
	JML		(IRQ1Hook,X)

;============================================================================
; End Of Multi-tasking kernel
;============================================================================

	MEM		16
	NDX		16
BtnuIRQ:
	PHA
	LDA.B	$FD00A0
	INA
	STA.B	$FD00A0
	PLA
	RTI
	BRA		BtnuIRQ

; This little task sample runs in native 32 bit mode and displays
; "Hello World!" on the screen.

	CPU		FT833
	MEM		8
	NDX		32

Task2:
	LDX		#84*2*3
.0003:
	LDY		#0
.0002:
	LDA		msgHelloWorld,Y
	BEQ		.0001
	JSR		AsciiToScreen8
	STA		VIDBUF,X
	INX
	INX
	INY
	BRA		.0002
.0001:
	RTT
	BRA		.0003

msgHelloWorld:
	.byte	CR,LF,"Hello World!",CR,LF,0

	NDX		16
	MEM		16

BrkTask:
	INC		$FFD00000
	RTT
	BRA		BrkTask

; The following store sequence for the benefit of Supermon816
;
BrkRout:
	PHD
	PHB
	REP		#$30
	PHA
	PHX
	PHY
	JMP		($0102)		; This jump normally points to BrkRout1

BrkRout1:
	REP		#$30
	PLY
	PLX
	PLA
	PLB
	PLD
	SEP		#$20
	PLA
	REP		#$30
	PLA
	JSR		DispWord
	LDX		#0
	LDY		#64
.0001:
	.word	$f042		; pchist
	JSR		DispWord
	LDA		#' '
	JSR		OutChar
	INX
	DEY
	BNE		.0001
	LDA		#$FFFF
	STA		$7000
Hung:
	BRA		Hung

	;--------------------------------------------------------
	;--------------------------------------------------------
	; I/O page is located at $F0xx
	;--------------------------------------------------------
	;--------------------------------------------------------	
	;org		$F100

LineTbl:
	.WORD	0
	.WORD	TEXTCOLS
	.WORD	TEXTCOLS*2
	.WORD	TEXTCOLS*3
	.WORD	TEXTCOLS*4
	.WORD	TEXTCOLS*5
	.WORD	TEXTCOLS*6
	.WORD	TEXTCOLS*7
	.WORD	TEXTCOLS*8
	.WORD	TEXTCOLS*9
	.WORD	TEXTCOLS*10
	.WORD	TEXTCOLS*11
	.WORD	TEXTCOLS*12
	.WORD	TEXTCOLS*13
	.WORD	TEXTCOLS*14
	.WORD	TEXTCOLS*15
	.WORD	TEXTCOLS*16
	.WORD	TEXTCOLS*17
	.WORD	TEXTCOLS*18
	.WORD	TEXTCOLS*19
	.WORD	TEXTCOLS*20
	.WORD	TEXTCOLS*21
	.WORD	TEXTCOLS*22
	.WORD	TEXTCOLS*23
	.WORD	TEXTCOLS*24
	.WORD	TEXTCOLS*25
	.WORD	TEXTCOLS*26
	.WORD	TEXTCOLS*27
	.WORD	TEXTCOLS*28
	.WORD	TEXTCOLS*29
	.WORD	TEXTCOLS*30

TaskStartTbl:
	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	Task0		; PC
	.BYTE	Task0>>16	; PB
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$3FFF		; sp
	.WORD	0
	.BYTE	4			; SR	( 16 bit regs )
	.BYTE	1			; SR extension ( 16 bit mode)
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	; TASK #1
	; Interrupt handler task
	.WORD	0			; CS
	.WORD	5			; DS
	.WORD	5			; SS
	.WORD	Task1		; PC
	.BYTE	Task1>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$3BFF		; sp
	.WORD	0
	.BYTE	4			; SR	(32 bit regs)
	.BYTE	2			; SR extension	(32 bit mode)
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	Task2		; PC
	.BYTE	Task2>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$37FF		; sp
	.WORD	0
	.BYTE	$20			; SR			; eight bit mem
	.BYTE	2			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	; TASK #3
	; Button Interrupt handler task
	.WORD	0			; CS
	.WORD	5			; DS
	.WORD	5			; SS
	.WORD	BtnuIRQ		; PC
	.BYTE	BtnuIRQ>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$3AFF		; sp
	.WORD	0
	.BYTE	4			; SR
	.BYTE	$61			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	BrkTask		; PC
	.BYTE	BrkTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$2FFF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	; task #5
	; DS is placed at $7800
	.WORD	0			; CS
	.WORD	0    		; DS
	.WORD	0			; SS
	.WORD	InvadersTask	; PC
	.BYTE	InvadersTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$2BFF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	1			; SR extension
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	IRQTask		; PC
	.BYTE	IRQTask>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$27FF		; sp
	.WORD	0
	.BYTE	$24			; SR	8 bit acc, mask interrupts
	.BYTE	2			; SR extension - 832 mode
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	; task 7 (Basic)
	.WORD	$FFD		; CS
	.WORD	$FFD		; DS
	.WORD	$FFD		; SS
	.WORD	$C000		; PC
	.BYTE	$00
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$01FF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	0			; SR extension - 02 mode
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	63			; map

	; task 8 (Supermon)
	.WORD	$0			; CS
	.WORD	$5			; DS
	.WORD	$5			; SS
	.WORD	$8000		; PC
	.BYTE	$00
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$2BFF		; sp
	.WORD	0
	.BYTE	0			; SR
	.BYTE	1			; SR extension - 816 mode
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0			; map

	; task 9 (single step)
	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	SSMInit		; PC
	.BYTE	SSMInit>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$33FF		; sp
	.WORD	0
	.BYTE	$4			; SR	16 bit regs, mask interrupts
	.BYTE	1			; SR extension - 816 mode
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

	; task 10 - BRK routine
	.WORD	0			; CS
	.WORD	0			; DS
	.WORD	0			; SS
	.WORD	BrkRout		; PC
	.BYTE	BrkRout>>16
	.WORD	0			; acc
	.WORD	0
	.WORD	0			; x
	.WORD	0
	.WORD	0			; y
	.WORD	0
	.WORD	$32FF		; sp
	.WORD	0
	.BYTE	$4			; SR	32 bit regs, mask interrupts
	.BYTE	2			; SR extension - 832 mode
	.BYTE	0			; DB
	.WORD	0			; DPR
	.WORD	0

msgRegs:
	.byte	CR,LF
    .byte   "             xxxsxi31",CR,LF
    .byte   "  CS  PB PC  xxxsxn26NVmxDIZC    .A       .X       .Y       SP  ",CR,LF,0
msgRegs2:
	.byte	CR,LF
	.byte	"  SS   DS  DB  DP   BL  MP",CR,LF,0
msgErr:
	.byte	"***Err",CR,LF,0

;	cpu		FT833
;	MEM		32
;	NDX		32
;	LDA		#$12345678
;	LDX		#$98765432
;	STA.B	{$23},Y
;	LDY.UH	$44455556,X
;	LDA.H	CS:$44455556,X
;	LDA.UB	SEG $8888:$1234,Y
;	JSF	    $0000:start
;	RTF
;	ADC     SEG $9821:$1200,X
;	EOR     $821:$1200,X
;	EOR     $841:$12
;	SBC     FAR {$24},Y
;	AND     FAR($25)
;	ORA     FAR ($26,x)
;	TSK		#2
;	TSK
;	LDT		$10000,X

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; +---------------------------+
; | block status / ptr to free|
; +---------------------------+
; | pointer to previous block |
; +---------------------------+
; | pointer to next block     |
; +---------------------------+
;
	MEM		32
	NDX		32
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
FreeSysMem:
	SEC
	SBC		#12		;	backup to block header
	TAY				;	.Y = pointer to block to free (this)
	PHP				; save interrupt mask
	SEI				; no interrupts
	STZ		$0,Y	; set status as free
	LDX		$8,Y	;	.X = pointer to next block
	LDA		$0,X	;	.A = next->status
	BEQ		.0001	;	branch if not free
	; merge block with next free block
	LDA		$8,X	;   .A = pointer to next next block
	STA		$8,Y	;
	TAX
	STY		$4,X	;	next->next->prev = this
.0001:
	; merge block with a previous free block
	LDX		$4,Y	;	.X = pointer to prev block
	LDA		$0,X	;	.A = prev->status
	BEQ		.0002	;	branch if not free
	LDA		$8,Y	;   prev->next = this->next
	STA		$8,X
	TAY				;	.Y = this->next
	STX		$4,Y	;	this->next->prev = this->prev
	TXY
.0002:
	LDA		heap_free_ptr
	STA		$0,Y
	STY		heap_free_ptr
	CLI
	PLP
	RTS

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	; round allocation size to mmu available sizes

	LDX		#0
	CLC				; add room for header
	ADC		#12
.0002:
	CMP		mmas,X
	BLE		.0001
	INX
	INX
	INX
	INX
	BRA		.0002
.0001:
	LDA		mmas,X
	TAX
	LDY		free_heap_ptr
	; subtract .Y from .A
	SEC
	LDA		$8,Y
	STY		tmpy
	SBC		tmpy
	CMP		mmas,X
;	BLT		.0003
	; here block is big enough
	PHA
	LDA		$0,Y
	STA		free_heap_ptr
	STZ		$0,Y
	PLA
	SEC
	SBC		mmas,X
	CMP		#$0FF
	BLT		.0004

.0004:
	


; Memory management allocation sizes
;
mmas:
	WORD	$0000,$0000
	WORD	$00FF,$0000
	WORD	$03FF,$0000
	WORD	$0FFF,$0000
	WORD	$3FFF,$0000
	WORD	$FFFF,$0000
	WORD	$FFFF,$0003
	WORD	$FFFF,$000F
	WORD	$FFFF,$003F
	WORD	$FFFF,$00FF
	WORD	$FFFF,$03FF
	WORD	$FFFF,$0FFF
	WORD	$FFFF,$3FFF
	WORD	$FFFF,$FFFF

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	MEM		16
	NDX		16
	JMP		MusicPlay
beep:
	LDA		#15					; set volume to max
	STA		SID+SID_VOLUME		
	LDA		#$0C6F				; 10C6F = 800 Hz
	STA		SID+SID_FREQ0
	LDA		#1
	STA		SID+SID_FREQ0+2
	LDA		#195				; 2ms
	STA		SID+SID_ATTACK0
	STZ		SID+SID_ATTACK0+2
	LDA		#2344				; 24 ms decay
	STA		SID+SID_DECAY0
	STZ		SID+SID_DECAY0+2
	LDA		#$80				; 50% sustain level
	STA		SID+SID_SUSTAIN0
	LDA		#48828				; 500 ms release
	STA		SID+SID_RELEASE0
	STZ		SID+SID_RELEASE0+2
	LDA		#1					; reset envelope generator
	STA		SID+SID_CTRL0+2
	NOP
	NOP
	STZ		SID+SID_CTRL0+2
	LDA		#$1504				; gate on
	STA		SID+SID_CTRL0
	; delay for about 1s
	LDY		#39
.0002:
	LDX		#65535
.0001:
	DEX
	BNE		.0001
	DEY
	BNE		.0002
	LDA		#$0504				; gate off
	STA		SID+SID_CTRL0
	RTS
	
music_tbl:
	dh	1
	dw	33673		; G4
	dw	12			; 1/8 sec
	dw	4			; space

	dh	1
	dw	33673		; G4
	dw	12			; 1/8
	dw	4			; space

	dh	1
	dw	33673		; G4
	dw	12			; 1/8
	dw	4			; space

	dh	0
	dw	0			; G4
	dw	0			; 1/8
	dw	0			; space

MusicPlay:
	LDX		#0
	LDA		#195				; 2ms
	STA		SID+SID_ATTACK0
	STZ		SID+SID_ATTACK0+2
	LDA		#2344				; 24 ms decay
	STA		SID+SID_DECAY0
	STZ		SID+SID_DECAY0+2
	LDA		#$D0				; sustain level
	STA		SID+SID_SUSTAIN0
	LDA		#4600				; ??? ms release
	STA		SID+SID_RELEASE0
	STZ		SID+SID_RELEASE0+2
.0001:
	LDA		music_tbl,x			; check for last note
	BEQ		.xit
	LDA		music_tbl+2,x			; set the frequency
	STA		SID+SID_FREQ0
	LDA		music_tbl+4,x
	STA		SID+SID_FREQ0+2
	LDA		#$1504				; gate on
	STA		SID+SID_CTRL0
	SEI
	LDA		music_tbl+6,x
	STA		timeout1
	LDA		music_tbl+8,x
	STA		timeout1+2
	JSR		MusicWaitTimeout
	LDA		#$0504				; gate off
	STA		SID+SID_CTRL0
	SEI
	LDA		music_tbl+10,x		; note release delay
	STA		timeout1
	LDA		music_tbl+12,x
	STA		timeout1+2
	JSR		MusicWaitTimeout
	INX
	INX
	INX4
	INX4
	INX4
	BRA		.0001
.xit:
	RTS

MusicWaitTimeout:
.0001:
	CLI
	NOP
	NOP
	SEI
	LDA		timeout1
	ORA		timeout1+2
	BNE		.0001
	CLI
	RTS

MusicTimeoutIRQ:
	REP		#$30
	MEM		16
	NDX		16
	LDA		timeout1
	ORA		timeout1+2
	BEQ		.0001
	SEC
	LDA		timeout1
	SBC		#1
	STA		timeout1
	LDA		timeout1+2
	SBC		#0
	STA		timeout1+2
.0001:
	RTS

	.org	$FE00
	JMP		SuperGetch		; FE00
	JMP		warm_start		; FE03
	JMP		SuperPutch		; FE06
	JMP		BIOSInput		; FE09
	JMP		BasicGetch		; FE0C
	JMP		xitBasic		; FE0F
	JMP		BASIC_Loadfile	; FE12
	JMP		BASIC_Savefile	; FE15

	.org	$FF00
	JMP		FMTK_ScheduleTask	; FE18
	JMP		FMTK_Sleep
	JMP		FMTK_StartTask
	JMP		FMTK_ExitTask
	JMP		FMTK_KillTask
	JMP		FMTK_AllocMbx
	JMP		$0				; reserved for FreeMbx
	JMP		FMTK_SendMsg
	JMP		FMTK_PostMsg
	JMP		FMTK_WaitMsg
	JMP		FMTK_PeekMsg
	JMP		FMTK_CheckMsg

	.org 	$FFD6
	dw		4			; task #4

	.org	$FFDE		; '832 IRQ vector
	dw		TimeSliceIRQ	;

	.org	$FFE0		; IRQ3 vector
	dw		BtnuIRQ

	.org 	$FFE6
	dw		BrkRout

	.org	$FFEE			; '816 IRQ vector
	dw		TimeSliceIRQ	; IRQRout816

	.org	$FFFC		; reset vector
	dw		$C000

	.org	$FFFE
	dw		TimeSliceIRQ	; IRQRout02
