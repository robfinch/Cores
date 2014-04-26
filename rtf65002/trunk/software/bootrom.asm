
; ============================================================================
;        __
;   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
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
	cpu		RTF65002

CR	EQU	0x0D		;ASCII equates
LF	EQU	0x0A
TAB	EQU	0x09
CTRLC	EQU	0x03
CTRLH	EQU	0x08
CTRLI	EQU	0x09
CTRLJ	EQU	0x0A
CTRLK	EQU	0x0B
CTRLM   EQU 0x0D
CTRLS	EQU	0x13
CTRLX	EQU	0x18
XON		EQU	0x11
XOFF	EQU	0x13

; error codes
E_Ok		=		0x00
E_Arg		=		0x01
E_BadMbx	=		0x04
E_QueFull	=		0x05
E_NoThread	=		0x06
E_NotAlloc	=		0x09
E_NoMsg		=		0x0b
E_Timeout	=		0x10
E_BadAlarm	=		0x11
E_NotOwner	=		0x12
E_QueStrategy =		0x13
E_BadDevNum	=		0x18
E_DCBInUse	=		0x19

; resource errors
E_NoMoreMbx	=		0x40
E_NoMoreMsgBlks	=	0x41
E_NoMoreAlarmBlks	=0x44
E_NoMoreTCBs	=	0x45
E_NoMem		= 12

; task status
TS_NONE     =0
TS_TIMEOUT	=1
TS_WAITMSG	=2
TS_PREEMPT	=4
TS_RUNNING	=8
TS_READY	=16
TS_SLEEP	=32

TS_TIMEOUT_BIT	=0
TS_WAITMSG_BIT	=1
TS_RUNNING_BIT	=3
TS_READY_BIT	=4

PRI_HIGHEST	=0
PRI_HIGH	=1
PRI_NORMAL	=2
PRI_LOW		=3
PRI_LOWEST	=4

MAX_TASKNO	= 63
DRAM_BASE	= $04000000

DIRENT_NAME		=0x00	; file name
DIRENT_EXT		=0x1C	; file name extension
DIRENT_ATTR		=0x20	; attributes
DIRENT_DATETIME	=0x28
DIRENT_CLUSTER	=0x30	; starting cluster of file
DIRENT_SIZE		=0x34	; file size (6 bytes)

; One FCB is allocated and filled out for each file that is open.
;
nFCBs	= 128
FCB_DE_NAME		=0x00
FCB_DE_EXT		=0x1C
FCB_DE_ATTR		=0x20
FCB_DE_DATETIME	=0x28
FCB_DE_CLUSTER	=0x30	; starting cluster of file
FCB_DE_SIZE		=0x34	; 6 byte file size

FCB_DIR_SECTOR	=0x40	; LBA directory sector this is from
FCB_DIR_ENT		=0x44	; offset in sector for dir entry
FCB_LDRV		=0x48	; logical drive this is on
FCB_MODE		=0x49	; 0 read, 1=modify
FCB_NUSERS		=0x4A	; number of users of this file
FCB_FMOD		=0x4B	; flag: this file was modified
FCB_RESV		=0x4C	; padding out to 80 bytes
FCB_SIZE		=0x50

FUB_JOB		=0x00	; User's job umber
FUB_iFCB	=0x02	; FCB number for this file
FUB_CrntLFA	=0x04	; six byte current logical file address
FUB_pBuf	=0x0C	; pointer to buffer if in stream mode
FUB_sBuf	=0x10	; size of buffer for stream file
FUB_LFABuf	=0x14	; S-First LFA in Clstr Buffer
FUB_LFACluster	=0x18	; LFA of cluster
FUB_Clstr	= 0x20		; The last cluster read
FUB_fModified	= 0x24	; data in buffer was modified
FUB_fStream		= 0x25	; non-zero for stream mode
FUB_PAD		=0x26	
FUB_SIZE	=0x30

; Boot sector info (62 byte structure) */
BSI_JMP		= 0x00
BSI_OEMName	= 0x03
BSI_bps		= 0x0B
BSI_SecPerCluster	= 0x0D
BSI_ResSectors	= 0x0E
BSI_FATS	= 0x10
BSI_RootDirEnts	= 0x11
BSI_Sectors	= 0x13
BSI_Media	= 0x15
BSI_SecPerFAT	= 0x16
BSI_SecPerTrack	= 0x18
BSI_Heads	= 0x1A
BSI_HiddenSecs	= 0x1C
BSI_HugeSecs	= 0x1E

BSI_DriveNum	= 0x24
BSI_Rsvd1		= 0x25
BSI_BootSig		= 0x26
BSI_VolID		= 0x27
BSI_VolLabel	= 0x2B
BSI_FileSysType = 0x36

	 
MEM_CHK		=0
MEM_FLAG	=1
MEM_PREV	=2
MEM_NEXT	=3

; message queuing strategy
MQS_UNLIMITED	=0	; unlimited queue size
MQS_NEWEST		=1	; buffer queue size newest messages
MQS_OLDEST		=2	; buffer queue size oldest messages

LEDS		EQU		0xFFDC0600
TEXTSCR		EQU		0xFFD00000
COLORSCR	EQU		0xFFD10000
TEXTREG		EQU		0xFFDA0000
TEXT_COLS	EQU		0x0
TEXT_ROWS	EQU		0x1
TEXT_CURPOS	EQU		11
BMP_CLUT	EQU		$FFDC5800
KEYBD		EQU		0xFFDC0000
KEYBDCLR	EQU		0xFFDC0001
PIC			EQU		0xFFDC0FF0
PIC_IE		EQU		0xFFDC0FF1
PIC_ES		EQU		0xFFDC0FF4
PIC_RSTE	EQU		0xFFDC0FF5
TASK_SELECT	EQU		0xFFDD0008

RQ_SEMA		EQU		0xFFDB0000
to_sema		EQU		0xFFDB0010
SERIAL_SEMA	EQU		0xFFDB0020
keybd_sema	EQU		0xFFDB0030
iof_sema	EQU		0xFFDB0040
mbx_sema	EQU		0xFFDB0050
freembx_sema	EQU		0xFFDB0060
MEM_SEMA	EQU		0xFFDB0070
freemsg_sema	EQU	0xFFDB0080
tcb_sema	EQU		0xFFDB0090
readylist_sema	EQU	0xFFDB00A0
tolist_sema		EQU	0xFFDB00B0
msg_sema		EQU	0xFFDB00C0
freetcb_sema	EQU	0xFFDB00D0
device_semas	EQU	0xFFDB1000
device_semas_end	EQU	0xFFDB1200

SPIMASTER	EQU		0xFFDC0500
SPI_MASTER_VERSION_REG	EQU	0x00
SPI_MASTER_CONTROL_REG	EQU	0x01
SPI_TRANS_TYPE_REG	EQU		0x02
SPI_TRANS_CTRL_REG	EQU		0x03
SPI_TRANS_STATUS_REG	EQU	0x04
SPI_TRANS_ERROR_REG		EQU	0x05
SPI_DIRECT_ACCESS_DATA_REG		EQU	0x06
SPI_SD_SECT_7_0_REG		EQU	0x07
SPI_SD_SECT_15_8_REG	EQU	0x08
SPI_SD_SECT_23_16_REG	EQU	0x09
SPI_SD_SECT_31_24_REG	EQU	0x0a
SPI_RX_FIFO_DATA_REG	EQU	0x10
SPI_RX_FIFO_DATA_COUNT_MSB	EQU	0x12
SPI_RX_FIFO_DATA_COUNT_LSB  EQU 0x13
SPI_RX_FIFO_CTRL_REG		EQU	0x14
SPI_TX_FIFO_DATA_REG	EQU	0x20
SPI_TX_FIFO_CTRL_REG	EQU	0x24
SPI_RESP_BYTE1			EQU	0x30
SPI_RESP_BYTE2			EQU	0x31
SPI_RESP_BYTE3			EQU	0x32
SPI_RESP_BYTE4			EQU	0x33
SPI_INIT_SD			EQU		0x01
SPI_TRANS_START		EQU		0x01
SPI_TRANS_BUSY		EQU		0x01
SPI_INIT_NO_ERROR	EQU		0x00
SPI_READ_NO_ERROR	EQU		0x00
SPI_WRITE_NO_ERROR	EQU		0x00
RW_READ_SD_BLOCK	EQU		0x02
RW_WRITE_SD_BLOCK	EQU		0x03

CONFIGREC	EQU		0xFFDCFFF0
CR_CLOCK	EQU		0xFFDCFFF4
GACCEL		EQU		0xFFDAE000
GA_X0		EQU		0xFFDAE002
GA_Y0		EQU		0xFFDAE003
GA_PEN		EQU		0xFFDAE000
GA_X1		EQU		0xFFDAE004
GA_Y1		EQU		0xFFDAE005
GA_STATE	EQU		0xFFDAE00E
GA_CMD		EQU		0xFFDAE00F

AC97		EQU		0xFFDC1000
PSG			EQU		0xFFD50000
PSGFREQ0	EQU		0xFFD50000
PSGPW0		EQU		0xFFD50001
PSGCTRL0	EQU		0xFFD50002
PSGADSR0	EQU		0xFFD50003

ETHMAC		EQU		0xFFDC2000
ETH_MODER		EQU		0x00
ETH_INT_SOURCE	EQU		0x01
ETH_INT_MASK	EQU		0x02
ETH_IPGT		EQU		0x03
ETH_IPGR1		EQU		0x04
ETH_IPGR2		EQU		0x05
ETH_PACKETLEN	EQU		0x06
ETH_COLLCONF	EQU		0x07
ETH_TX_BD_NUM	EQU		0x08
ETH_CTRLMODER	EQU		0x09
ETH_MIIMODER	EQU		0x0A
ETH_MIICOMMAND	EQU		0x0B
ETH_MIIADDRESS	EQU		0x0C
ETH_MIITX_DATA	EQU		0x0D
ETH_MIIRX_DATA	EQU		0x0E
ETH_MIISTATUS	EQU		0x0F
ETH_MAC_ADDR0	EQU		0x10
ETH_MAC_ADDR1	EQU		0x11
ETH_HASH0_ADDR	EQU		0x12
ETH_HASH1_ADDR	EQU		0x13
ETH_TXCTRL		EQU		0x14

ETH_WCTRLDATA	EQU		4
ETH_MIICOMMAND_RSTAT	EQU	2
ETH_MIISTATUS_BUSY	EQU		2
ETH_MIIMODER_RST	EQU		$200
ETH_MODER_RST       EQU		$800
ETH_MII_BMCR		EQU		0		; basic mode control register
ETH_MII_ADVERTISE	EQU		4
ETH_MII_EXPANSION       =6
ETH_MII_CTRL1000        =9
ETH_ADVERTISE_ALL	EQU		$1E0
ETH_ADVERTISE_1000FULL      =0x0200  ; Advertise 1000BASE-T full duplex
ETH_ADVERTISE_1000HALF      =0x0100  ; Advertise 1000BASE-T half duplex
ETH_ESTATUS_1000_TFULL	=0x2000	; Can do 1000BT Full
ETH_ESTATUS_1000_THALF	=0x1000	; Can do 1000BT Half
ETH_BMCR_ANRESTART      =    0x0200  ; Auto negotiation restart    
ETH_BMCR_ISOLATE        =    0x0400  ; Disconnect DP83840 from MII
ETH_BMCR_PDOWN          =    0x0800  ; Powerdown the DP83840     
ETH_BMCR_ANENABLE       =    0x1000  ; Enable auto negotiation    

ETH_PHY		=7

MMU			EQU		0xFFDC4000
MMU_KVMMU	EQU		0xFFDC4800
MMU_FUSE	EQU		0xFFDC4811
MMU_AKEY	EQU		0xFFDC4812
MMU_OKEY	EQU		0xFFDC4813
MMU_MAPEN	EQU		0xFFDC4814

DATETIME	EQU		0xFFDC0400
DATETIME_TIME		EQU		0xFFDC0400
DATETIME_DATE		EQU		0xFFDC0401
DATETIME_ALMTIME	EQU		0xFFDC0402
DATETIME_ALMDATE	EQU		0xFFDC0403
DATETIME_CTRL		EQU		0xFFDC0404
DATETIME_SNAPSHOT	EQU		0xFFDC0405

SPRITEREGS	EQU		0xFFDAD000
SPRRAM		EQU		0xFFD80000

THRD_AREA	EQU		0x00000000	; threading area 0x04000000-0x40FFFFF
BITMAPSCR	EQU		0x00100000
SECTOR_BUF	EQU		0x01FBEC00
BIOS_STACKS	EQU		0x01FC0000	; room for 256 1kW stacks

BYTE_SECTOR_BUF	EQU	SECTOR_BUF<<2
PROG_LOAD_AREA	EQU		0x0300000<<2

FCBs			EQU		0x1F40000	; room for 128 FCB's

FATOFFS			EQU		0x1F50000	; offset into FAT on card
FATBUF			EQU		0x1F60000
DIRBUF			EQU		0x1F70000
eth_rx_buffer	EQU		0x1F80000
eth_tx_buffer	EQU		0x1F84000

; Mailboxes, room for 2048
			.bss
			.org		0x01F90000
NR_MBX		EQU		$800
MBX_LINK		fill.b	NR_MBX,0	; link to next mailbox in list (free list)
MBX_TQ_HEAD		fill.b	NR_MBX,0	; head of task queue
MBX_TQ_TAIL		fill.b	NR_MBX,0
MBX_MQ_HEAD		fill.b	NR_MBX,0	; head of message queue
MBX_MQ_TAIL		fill.b	NR_MBX,0
MBX_TQ_COUNT	fill.b	NR_MBX,0	; count of queued threads
MBX_MQ_SIZE		fill.b	NR_MBX,0	; number of messages that may be queued
MBX_MQ_COUNT	fill.b	NR_MBX,0	; count of messages that are queued
MBX_MQ_MISSED	fill.b	NR_MBX,0	; number of messages dropped from queue
MBX_OWNER		fill.b	NR_MBX,0	; job handle of mailbox owner
MBX_MQ_STRATEGY	fill.b	NR_MBX,0	; message queueing strategy
MBX_RESV		fill.b	NR_MBX,0

; Messages, room for 64kW (16,384) messages
			.bss
			.org		0x01FA0000
NR_MSG		EQU		16384
MSG_LINK	fill.b	NR_MSG,0	; link to next message in queue or free list
MSG_D1		fill.b	NR_MSG,0	; message data 1
MSG_D2		fill.b	NR_MSG,0	; message data 2
MSG_TYPE	fill.b	NR_MSG,0	; message type
MSG_END		EQU		MSG_TYPE + NR_MSG

MT_IRQ		EQU		0xFFFFFFF0
MT_GETCHAR	EQU		0xFFFFFFEF

			.bss
			.org		0x01FBCE00

; Task control blocks, room for 256 tasks
NR_TCB			EQU		256
TCB_NxtRdy		fill.b	NR_TCB,0	;	EQU		0x01FBE100	; next task on ready / timeout list
TCB_PrvRdy		fill.b	NR_TCB,0	;	EQU		0x01FBE200	; previous task on ready / timeout list
TCB_NxtTCB		fill.b	NR_TCB,0	;	EQU		0x01FBE300
TCB_Timeout		fill.b	NR_TCB,0	;	EQU		0x01FBE400
TCB_Priority	fill.b	NR_TCB,0	;	EQU		0x01FBE500
TCB_MSG_D1		fill.b	NR_TCB,0	;	EQU		0x01FBE600
TCB_MSG_D2		fill.b	NR_TCB,0	;	EQU		0x01FBE700
TCB_hJCB		fill.b	NR_TCB,0	;	EQU		0x01FBE800
TCB_Status		fill.b	NR_TCB,0	;	EQU		0x01FBE900
TCB_CursorRow	fill.b	NR_TCB,0	;	EQU		0x01FBD100
TCB_CursorCol	fill.b	NR_TCB,0	;	EQU		0x01FBD200
TCB_hWaitMbx	fill.b	NR_TCB,0	;	EQU		0x01FBD300	; handle of mailbox task is waiting at
TCB_mbq_next	fill.b	NR_TCB,0	;	EQU		0x01FBD400	; mailbox queue next
TCB_mbq_prev	fill.b	NR_TCB,0	;	EQU		0x01FBD500	; mailbox queue previous
TCB_iof_next	fill.b	NR_TCB,0	;	EQU		0x01FBD600
TCB_iof_prev	fill.b	NR_TCB,0	;	EQU		0x01FBD700
TCB_SP8Save		fill.b	NR_TCB,0	;	EQU		0x01FBD800	; TCB_SP8Save area 
TCB_SPSave		fill.b	NR_TCB,0	;	EQU		0x01FBD900	; TCB_SPSave area
TCB_ABS8Save	fill.b	NR_TCB,0	;	EQU		0x01FBDA00
TCB_mmu_map		fill.b	NR_TCB,0	;	EQU		0x01FBDB00
TCB_npages		fill.b	NR_TCB,0	;	EQU		0x01FBDC00
TCB_ASID		fill.b	NR_TCB,0	;	EQU		0x01FBDD00
TCB_errno		fill.b	NR_TCB,0	;	EQU		0x01FBDE00
TCB_NxtTo		fill.b	NR_TCB,0	;	EQU		0x01FBDF00
TCB_PrvTo		fill.b	NR_TCB,0	;	EQU		0x01FBE000
TCB_MbxList		fill.b	NR_TCB,0	;	EQU		0x01FBCF00	; head pointer to list of mailboxes associated with task
TCB_mbx			fill.b	NR_TCB,0	;	EQU		0x01FBCE00

			.bss
			.org		0x01C00000
SCREEN_SIZE		EQU		8192
BIOS_SCREENS	fill.b	SCREEN_SIZE * NR_TCB	; 0x01C00000 to 0x01DFFFFF


; Device Control Block
;
DCB_NAME			EQU		0
DCB_NAME_LEN		EQU		3
DCB_TYPE			EQU		4
DCB_nBPB			EQU		5
DCB_last_erc		EQU		6
DCB_nBlocks			EQU		7
DCB_pDevOp			EQU		8
DCB_pDevInit		EQU		9
DCB_pDevStat		EQU		10
DCB_ReentCount		EQU		11
DCB_fSingleUser		EQU		12
DCB_hJob			EQU		13
DCB_Mbx				EQU		14
DCB_Sema			EQU		15
DCB_OSD3			EQU		16
DCB_OSD4			EQU		17
DCB_OSD5			EQU		18
DCB_OSD6			EQU		19
DCB_SIZE			EQU		20

NR_DCB		EQU		32
DCBs		fill	NR_DCB * DCB_SIZE,0		;	EQU		MSG_END
DCBs_END	EQU		DCBs + DCB_SIZE * NR_DCB

HeapStart	EQU		0x00540000
HeapEnd		EQU		0x017FFFFF

; Bitmap of tasks requesting the I/O focus
;
IOFocusTbl	fill.b	8,0

; EhBASIC vars:
;
NmiBase		EQU		0xDC
IrqBase		EQU		0xDF

; BIOS vars at the top of the 8kB scratch memory
;
; TinyBasic AREA = 0x6C0 to 0x77F

PageMap		EQU		0x600
PageMapEnd	EQU		0x63F
PageMap2	EQU		0x640
PageMap2End	EQU		0x67F
mem_pages_free	EQU		0x680

			bss
			org	0x780

QNdx0		db		0
QNdx1		db		0
QNdx2		db		0
QNdx3		db		0
QNdx4		db		0
FreeTCB		db		0
TimeoutList	db		0
RunningTCB	db		0
FreeMbxHandle		db		0
nMailbox	db		0
FreeMsg		db		0
nMsgBlk		db		0
missed_ticks	db		0
keybdmsg_d1		db		0
keybdmsg_d2		db		0
keybd_mbx		db		0
keybd_char		db		0
iof_switch		db		0
clockmsg_d1		db		0
clockmsg_d2		db		0
tcbsema_d1		db		0
tcbsema_d2		db		0

; The IO focus list is a doubly linked list formed into a ring.
;
IOFocusNdx	db		0
;
test_mbx	db		0
test_D1		db		0
test_D2		db		0
tone_cnt	db		0

IrqSource	EQU		0x79F

			org		0x7A0
JMPTMP		db		0
SP8Save		db		0
SRSave		db		0
R1Save		db		0
R2Save		db		0
R3Save		db		0
R4Save		db		0
R5Save		db		0
R6Save		db		0
R7Save		db		0
R8Save		db		0
R9Save		db		0
R10Save		db		0
R11Save		db		0
R12Save		db		0
R13Save		db		0
R14Save		db		0
R15Save		db		0
SPSave		db		0

			org		0x7C0
CharColor	db		0
ScreenColor	db		0
CursorRow	db		0
CursorCol	db		0
CursorFlash	db		0
Milliseconds	db		0
IRQFlag		db		0
UserTick	db		0
eth_unique_id	db		0
LineColor	db		0
QIndex		db		0
ROMcs		db		0
mmu_present	db		0
TestTask	db		0
BASIC_SESSION	db		0
gr_cmd		db		0

startSector	EQU		0x7F0

macro DisTimer
	pha
	lda		#3
	sta		PIC+2
	pla
endm

macro EnTimer
	pha
	lda		#3
	sta		PIC+3
	pla
endm

macro DisTmrKbd
	pha
	lda		#3
	sta		PIC+2
	lda		#15
	sta		PIC+2
	pla
endm

macro EnTmrKbd
	pha
	lda		#3
	sta		PIC+3
	lda		#15
	sta		PIC+3
	pla
endm

macro GoReschedule
	int		#2
endm

;------------------------------------------------------------------------------
; Wait for the TCB array to become available
;------------------------------------------------------------------------------
;
macro mAquireTCB
	lda		#33
	ldx		#0
	txy
	ld		r4,#-1
	jsr		WaitMsg
endm

macro mReleaseTCB
	lda		#33
	ldx		#$FFFFFFFE
	txy
	jsr		SendMsg
endm

macro mAquireMBX
	lda		#34
	ldx		#0
	txy
	ld		r4,#-1
	jsr		WaitMsg
endm

macro mReleaseMBX
	lda		#34
	ldx		#$FFFFFFFE
	txy
	jsr		SendMsg
endm


	cpu		rtf65002
	code

message "jump table"
	; jump table of popular BIOS routines
	org		$FFFF8000
ROMStart:
	dw	DisplayChar
	dw	KeybdCheckForKeyDirect
	dw	KeybdGetCharDirect
	dw	KeybdGetChar
	dw	KeybdCheckForKey
	dw	RequestIOFocus
	dw	ReleaseIOFocus
	dw	ClearScreen
	dw	HomeCursor
	dw	ExitTask
	dw	SetKeyboardEcho
	dw	Sleep
	dw	do_load
	dw	do_save

	org		$FFFF8400		; leave room for 256 vectors
message "cold start point"
KeybdRST
start
	sei						; disable interrupts
	cld						; disable decimal mode
	lda		#1
	sta		LEDS
	ldx		#BIOS_STACKS+0x03FF	; setup stack pointer top of memory
	txs
	trs		r0,abs8			; set 8 bit mode absolute address offset
	lda		#3
	trs		r1,cc			; enable dcache and icache
	jsr		ROMChecksum
	sta		ROMcs
	stz		mmu_present		; assume no mmu
	lda		CONFIGREC
	bit		#4096
	beq		st_nommu
	jsr		InitMMU			; setup the maps and enable the mmu
	lda		#1
	sta		mmu_present
st_nommu:
	jsr		MemInit			; Initialize the heap
	stz		iof_switch

	lda		#2
	sta		LEDS

	; setup interrupt vectors
	ldx		#$01FB8001		; interrupt vector table from $5FB0000 to $5FB01FF
							; also sets nmoi policy (native mode on interrupt)
	trs		r2,vbr
	dex
	phx
	txy						; y = pointer to vector table
	lda		#511			; 512 vectors to setup
	ldx		#brk_rout		; point vector to brk routine
	stos

	plx
	lda		#brk_rout
	sta		(x)
	lda		#slp_rout
	sta		1,x
	lda		#reschedule
	sta		2,x
	lda		#spinlock_irq
	sta		3,x
	lda		#KeybdRST
	sta		448+1,x
	lda		#p1000Hz
	sta		448+2,x
	lda		#KeybdIRQ
	sta		448+15,x
	lda		#SerialIRQ
	sta		448+8,x
	lda		#InvalidOpIRQ
	sta		495,x
	lda		#bus_err_rout
	sta		508,x
	sta		509,x

	lda		#3
	sta		LEDS

	; stay in native mode in case emulation is not supported.
	ldx		#$1FF			; set 8 bit stack pointer
	trs		r2,sp8
	
	ldx		#0
	stz		IrqBase			; support for EhBASIC's interrupt mechanism
	stz		NmiBase

	jsr		($FFFFC000>>2)		; Initialize multi-tasking
	lda		#TickRout		; setup tick routine
	sta		UserTick

	lda		#1
	sta		iof_sema

	lda		#(DCB_SIZE * NR_DCB)-1
	ldx		#0
	ldy		#DCBs
	stos

	lda		#$CE			; CE =blue on blue FB = grey on grey
	sta		ScreenColor
	sta		CharColor
	sta		CursorFlash
	jsr		ClearScreen
	jsr		InitBMP
	jsr		ClearBmpScreen
	jsr		PICInit
	; Enable interrupts
	; This will likely cause an interrupt right away because the timer
	; pulses run since power-up.
	cli						
	lda		#PRI_LOWEST
	ldx		#0
	ldy		#IdleTask
	jsr		StartTask
	lda		CONFIGREC		; do we have a serial port ?
	bit		#32
	beq		st7
	; 19200 * 16
	;-------------
	; 25MHz / 2^32
	lda		#$03254E6E		; constant for 19,200 baud at 25MHz
	jsr		SerialInit
st7:
	lda		#5
	sta		LEDS
	lda		CONFIGREC		; do we have sprites ?
	bit		#1
	beq		st8
	lda		#$3FFF			; turn on sprites
	sta		SPRITEREGS+120
	jsr		RandomizeSprram
st8:
	; Enable interrupts.
	; Keyboard initialization must take place after interrupts are
	; enabled.
	cli						
	lda		#14
	sta		LEDS
	lda		#PRI_NORMAL
	ldx		#0
	ldy		#KeybdSetup
	jsr		StartTask
	lda		#6
	sta		LEDS

	; The following must be after interrupts are enabled.
	lda		#9
	sta		LEDS
	jsr		HomeCursor
	lda		#msgStart
	jsr		DisplayStringB
	jsr		ReportMemFree
	lda		#msgChecksum
	jsr		DisplayStringB
	lda		ROMcs
	jsr		DisplayWord
	jsr		CRLF
	lda		#10
	sta		LEDS

	; The AC97 setup uses the millisecond counter and the
	; keyboard.
	lda		CONFIGREC		; do we have a sound generator ?
	bit		#4
	beq		st6
	jsr		SetupAC97
	lda		#4
	ldx		#0
	ldy		#Beep
;	jsr		StartTask
st6:
	lda		#11
	sta		LEDS
	stz		BASIC_SESSION
	jmp		Monitor
st1
	jsr		KeybdGetCharDirect
	bra		st1
	stp
	bra		start
	
msgStart
	db		"RTF65002 system starting.",$0d,$0a,00

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
InitBMP:
	ldx		#0
ibmp1:
	tsr		LFSR,r1
	sta		BMP_CLUT,x
	inx
	cpx		#512
	bne		ibmp1
	rts

;------------------------------------------------------------------------------
; InitMMU
;
; Initialize the 64 maps of the MMU.
; Initially all the maps are set the same:
; Virtual Page  Physical Page
; 000-382		383 (invalid page marker)
; 384-511		1920-2047
; Note that there are only 512 virtual pages per map, and 2048 real
; physical pages of memory. This limits maps to 32MB.
; This range includes the BIOS assigned stacks for the tasks and tasks
; virtual video buffers.
; Note that physical pages 0 to 1919 are not mapped, but do exist. They may
; be mapped into a task's address space as required.
; If changing the maps the last 128 pages (8MB) of the map should always point
; to the BIOS area. Don't change map entries 384-511 or the system may
; crash.
; If the rts at the end of this routine works, then memory was mapped
; successfully.
;------------------------------------------------------------------------------
INV_PAGE	EQU	383		; page umber to use for invalud entries

InitMMU:
	lda		#1
	sta		MMU_KVMMU+1
	dea
	sta		MMU_KVMMU
immu1:
	sta		MMU_AKEY	; set access key for map
	ldx		#0
immu2:
	; set the first 384 pages to invalid page marker
	; set the last 128 pages to physical page 1920-2047
	ld		r4,#INV_PAGE
	cpx		#384
	blo		immu3
	ld		r4,r2
	add		r4,r4,#1536	; 1920-384
immu3:
	st		r4,MMU,x
	inx
	cpx		#512
	bne		immu2
	ina
	cmp		#64			; 64 MMU maps
	bne		immu1
	stz		MMU_OKEY	; set operating key to map #0
	lda		#2
	sta		MMU_FUSE	; set fuse to 2 clocks before mapping starts
	nop
	nop

EnableMMUMapping:
	pha
	lda		#1
	sta		MMU_MAPEN
	pla
	rts
DisableMMUMapping:
	stz		MMU_MAPEN
	rts

;------------------------------------------------------------------------------
; The ROM contents are summed up to ensure the ROM is okay.
;------------------------------------------------------------------------------
ROMChecksum:
	lda		#0
	ldx		#ROMStart>>2
idc1:
	add		(x)
	inx
	cpx		#$100000000>>2
	bne		idc1
	cmp		#0			; The sum of all the words in the
						; ROM should be zero.
	rts

msgChecksum:
	db	CR,LF,"ROM checksum: ",0

;----------------------------------------------------------
; Initialize programmable interrupt controller (PIC)
;  0 = nmi (parity error)
;  1 = keyboard reset
;  2 = 1000Hz pulse
;  3 = 100Hz pulse (cursor flash)
;  4 = ethmac
;  8 = uart
; 13 = raster interrupt
; 15 = keyboard char
;----------------------------------------------------------
message "PICInit"
PICInit:
	;
	lda		#$000C			; clock pulses are edge sensitive
	sta		PIC_ES
	lda		#$000F			; enable nmi,kbd_rst
	; A10F enable serial IRQ
	sta		PIC_IE
PICret:
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "DumpTaskList"
DumpTaskList:
	pha
	phx
	phy
	push	r4
	lda		#msgTaskList
	jsr		DisplayStringB
	ldy		#0
	spl		tcb_sema + 1
dtl2:
	lda		QNdx0,y
	ld		r4,r1
	bmi		dtl1
dtl3:
	ldx		#3
	tya
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	ld		r1,r4
	ldx		#3
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	jsr		DisplayChar
	jsr		DisplayChar
	ld		r1,r4
	lda		TCB_Status,r1
	jsr		DisplayByte
	lda		#' '
	jsr		DisplayChar
	ldx		#3
	lda		TCB_PrvRdy,r4
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	ldx		#3
	lda		TCB_NxtRdy,r4
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	lda		TCB_Timeout,r4
	jsr		DisplayWord
	jsr		CRLF
	ld		r4,TCB_NxtRdy,r4
	cmp		r4,QNdx0,y
	bne		dtl3
dtl1:
	iny
	cpy		#5
	bne		dtl2
	stz		tcb_sema + 1
	pop		r4
	ply
	plx
	pla
	rts

msgTaskList:
	db	CR,LF,"Pri Task Stat Prv Nxt Timeout",CR,LF,0

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "DumpTimeoutList"
DumpTimeoutList:
	pha
	phx
	phy
	push	r4
	lda		#msgTimeoutList
	jsr		DisplayStringB
	ldy		#11
dtol2:
	lda		TimeoutList
	ld		r4,r1
	bmi		dtol1
	spl		tcb_sema + 1
dtol3:
	dey
	beq		dtol1
	ld		r1,r4
	ldx		#3
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	jsr		DisplayChar
	jsr		DisplayChar
	ld		r1,r4
	ldx		#3
	lda		TCB_PrvTo,r4
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	ldx		#3
	lda		TCB_NxtTo,r4
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	lda		TCB_Timeout,r4
	jsr		DisplayWord
	jsr		CRLF
	ld		r4,TCB_NxtTo,r4
	bpl		dtol3
dtol1:
	stz		tcb_sema + 1
	pop		r4
	ply
	plx
	pla
	rts

msgTimeoutList:
	db	CR,LF,"Task Prv Nxt Timeout",CR,LF,0

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "DumpIOFocusList"
DumpIOFocusList:
	pha
	phx
	phy
	lda		#msgIOFocusList
	jsr		DisplayStringB
	spl		iof_sema + 1
	lda		IOFocusNdx
diofl2:
	bmi		diofl1
	tay
	ldx		#3
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	lda		TCB_iof_prev,y
	ldx		#3
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	lda		TCB_iof_next,y
	ldx		#3
	jsr		PRTNUM
	jsr		CRLF
	lda		TCB_iof_next,y
	cmp		IOFocusNdx
	bne		diofl2
	
diofl1:
	stz		iof_sema + 1
	ply
	plx
	pla
	rts
	
msgIOFocusList:
	db	CR,LF,"Task Prv Nxt",CR,LF,0

RunningTCBErr:
;	lda		#$FF
;	sta		LEDS
	lda		#msgRunningTCB
	jsr		DisplayStringB
rtcberr1:
	jsr		KeybdGetChar
	cmp		#-1
	beq		rtcberr1
	jmp		start

msgRunningTCB:
	db	CR,LF,"RunningTCB is bad.",CR,LF,0

;------------------------------------------------------------------------------
; Get the location of the screen and screen attribute memory. The location
; depends on whether or not the task has the output focus.
;------------------------------------------------------------------------------
GetScreenLocation:
	lda		RunningTCB
	cmp		IOFocusNdx
	beq		gsl1
	and		r1,r1,#$FF
	asl		r1,r1,#13			; 8192 words per screen
	add		r1,r1,#BIOS_SCREENS
	rts
gsl1:
	lda		#TEXTSCR
	rts

GetColorCodeLocation:
	lda		RunningTCB
	cmp		IOFocusNdx
	beq		gccl1
	and		r1,r1,#$FF
	asl		r1,r1,#13			; 8192 words per screen
	add		r1,r1,#BIOS_SCREENS+4096
	rts
gccl1:
	lda		#TEXTSCR+$10000
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
message "CopyVirtualScreenToScreen"
CopyVirtualScreenToScreen
	pha
	phx
	phy
	push	r4
	lda		#4095				; number of words to copy-1
	ldx		IOFocusNdx			; compute virtual screen location
	bmi		cvss3
	asl		r2,r2,#13			; 8192 words per screen
	add		r2,r2,#BIOS_SCREENS	; add in screens array base address
	ldy		#TEXTSCR
	mvn
;cvss1:
;	ld		r4,(x)
;	st		r4,(y)
;	inx
;	iny
;	dea
;	bne		cvss1
	; now copy the color codes
	lda		#4095
	ldx		IOFocusNdx
	asl		r2,r2,#13
	add		r2,r2,#BIOS_SCREENS+4096	; virtual char color array
	ldy		#TEXTSCR+$10000
	mvn
;cvss2:
;	ld		r4,(x)
;	st		r4,(y)
;	inx
;	iny
;	dea
;	bne		cvss2
cvss3:
	; reset the cursor position in the text controller
	ldy		IOFocusNdx
	ldx		TCB_CursorRow,y
	lda		TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	add		r2,r2,TCB_CursorCol,y
	stx		TEXTREG+TEXT_CURPOS
	pop		r4
	ply
	plx
	pla
	rts
message "CopyScreenToVirtualScreen"
CopyScreenToVirtualScreen
	pha
	phx
	phy
	push	r4
	lda		#4095
	ldx		#TEXTSCR
	ldy		IOFocusNdx
	bmi		csvs3
	asl		r3,r3,#13
	add		r3,r3,#BIOS_SCREENS
	mvn
;csvs1:
;	ld		r4,(x)
;	st		r4,(y)
;	inx
;	iny
;	dea
;	bne		csvs1
	lda		#4095
	ldx		#TEXTSCR+$10000
	ldy		IOFocusNdx
	asl		r3,r3,#13
	add		r3,r3,#BIOS_SCREENS+4096
	mvn
;csvs2:
;	ld		r4,(x)
;	st		r4,(y)
;	inx
;	iny
;	dea
;	bne		csvs2
csvs3:
	pop		r4
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Clear the screen and the screen color memory
; We clear the screen to give a visual indication that the system
; is working at all.
;------------------------------------------------------------------------------
;
message "ClearScreen"
ClearScreen:
	pha							; holds a space character
	phx							; loop counter
	phy							; memory addressing
	lda		TEXTREG+TEXT_COLS	; calc number to clear
	ldx		TEXTREG+TEXT_ROWS
	mul		r1,r1,r2			; r1 = # chars to clear
	pha
	jsr		GetScreenLocation
	tay							; y = target address
	lda		#' '				; space char
	jsr		AsciiToScreen
	tax							; x is value to store
	pla							; a is count
	pha
	stos						; clear the memory
	ld		r2,ScreenColor		; x = value to use
	jsr		GetColorCodeLocation
	tay							; y = targte address
	pla							; a = count
	stos
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Scroll text on the screen upwards
;------------------------------------------------------------------------------
;
message "ScrollUp"
ScrollUp:
	pha
	phx
	phy
	push	r4
	push	r5
	push	r6
	lda		TEXTREG+TEXT_COLS	; acc = # text columns
	ldx		TEXTREG+TEXT_ROWS
	mul		r2,r1,r2			; calc number of chars to scroll
	sub		r2,r2,r1			; one less row
	pha
	jsr		GetScreenLocation
	tay
	jsr		GetColorCodeLocation
	ld		r6,r1
	pla
scrup1:
	add		r5,r3,r1
	ld		r4,(r5)				; move character
	st		r4,(y)
	add		r5,r6,r1
	ld		r4,(r5)				; and move color code
	st		r4,(r6)
	iny
	inc		r6
	dex
	bne		scrup1
	lda		TEXTREG+TEXT_ROWS
	dea
	jsr		BlankLine
	pop		r6
	pop		r5
	pop		r4
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Blank out a line on the display
; line number to blank is in acc
;------------------------------------------------------------------------------
;
BlankLine:
	pha
	phx
	phy
	push	r4
	ldx		TEXTREG+TEXT_COLS	; x = # chars to blank out from video controller
	mul		r3,r2,r1			; y = screen index (row# * #cols)
	pha
	jsr		GetScreenLocation
	ld		r4,r1
	pla
	add		r3,r3,r4		; y = screen address
	lda		#' '
	jsr		AsciiToScreen
blnkln1:
	sta		(y)
	iny
	dex
	bne		blnkln1
	pop		r4
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------
;
AsciiToScreen:
	and		#$FF
	cmp		#'A'
	bcc		atoscr1		; blt
	cmp		#'Z'
	bcc		atoscr1
	beq		atoscr1
	cmp		#'z'+1
	bcs		atoscr1
	cmp		#'a'
	bcc		atoscr1
	sub		#$60
atoscr1:
	or		#$100
	rts

;------------------------------------------------------------------------------
; Convert screen character to ascii character
;------------------------------------------------------------------------------
;
ScreenToAscii:
	and		#$FF
	cmp		#26+1
	bcs		stasc1
	add		#$60
stasc1:
	rts

;------------------------------------------------------------------------------
; HomeCursor
; Set the cursor location to the top left of the screen.
;------------------------------------------------------------------------------
HomeCursor:
	phx
	spl		tcb_sema + 1
	ldx		RunningTCB
	and		r2,r2,#$FF
	stz		TCB_CursorRow,x
	stz		TCB_CursorCol,x
	stz		tcb_sema + 1
	cpx		IOFocusNdx
	bne		hc1
	stz		TEXTREG+TEXT_CURPOS
hc1:
	plx
	rts

;------------------------------------------------------------------------------
; Update the cursor position in the text controller based on the
;  CursorRow,CursorCol.
;------------------------------------------------------------------------------
;
UpdateCursorPos:
	pha
	phx
	push	r4
	ld		r4,RunningTCB
	and		r4,r4,#$FF
	cmp		r4,IOFocusNdx			; update cursor position in text controller
	bne		ucp1					; only for the task with the output focus
	lda		TCB_CursorRow,r4
	and		#$3F					; limit of 63 rows
	ldx		TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lda		TCB_CursorCol,r4
	and		#$7F					; limit of 127 cols
	add		r2,r2,r1
	stx		TEXTREG+TEXT_CURPOS
ucp1:
	pop		r4
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Calculate screen memory location from CursorRow,CursorCol.
; Also refreshes the cursor location.
; Returns:
; r1 = screen location
;------------------------------------------------------------------------------
;
CalcScreenLoc:
	phx
	push	r4
	ld		r4,RunningTCB
	and		r4,r4,#$FF
	lda		TCB_CursorRow,r4
	and		#$3F					; limit to 63 rows
	ldx		TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	ld		r1,TCB_CursorCol,r4
	and		#$7F					; limit to 127 cols
	add		r2,r2,r1
	cmp		r4,IOFocusNdx			; update cursor position in text controller
	bne		csl1					; only for the task with the output focus
	stx		TEXTREG+TEXT_CURPOS
csl1:
	jsr		GetScreenLocation
	add		r1,r1,r2
	pop		r4
	plx
	rts
csl2:
	lda		#TEXTSCR
	pop		r4
	plx
	rts

;------------------------------------------------------------------------------
; Display a character on the screen.
; If the task doesn't have the I/O focus then the character is written to
; the virtual screen.
; r1 = char to display
;------------------------------------------------------------------------------
;
message "DisplayChar"
DisplayChar:
	push	r4
	ld		r4,RunningTCB
	and		r4,r4,#$FF
	and		#$FF				; mask off any higher order bits (called from eight bit mode).
	cmp		#'\r'				; carriage return ?
	bne		dccr
	stz		TCB_CursorCol,r4	; just set cursor column to zero on a CR
	jsr		UpdateCursorPos
dcx14:
	pop		r4
	rts
dccr:
	cmp		#$91				; cursor right ?
	bne		dcx6
	pha
	lda		TCB_CursorCol,r4
	cmp		#55
	bcs		dcx7
	ina
	sta		TCB_CursorCol,r4
dcx7:
	jsr		UpdateCursorPos
	pla
	pop		r4
	rts
dcx6:
	cmp		#$90				; cursor up ?
	bne		dcx8		
	pha
	lda		TCB_CursorRow,r4
	beq		dcx7
	dea
	sta		TCB_CursorRow,r4
	bra		dcx7
dcx8:
	cmp		#$93				; cursor left ?
	bne		dcx9
	pha
	lda		TCB_CursorCol,r4
	beq		dcx7
	dea
	sta		TCB_CursorCol,r4
	bra		dcx7
dcx9:
	cmp		#$92				; cursor down ?
	bne		dcx10
	pha
	lda		TCB_CursorRow,r4
	cmp		#46
	beq		dcx7
	ina
	sta		TCB_CursorRow,r4
	bra		dcx7
dcx10:
	cmp		#$94				; cursor home ?
	bne		dcx11
	pha
	lda		TCB_CursorCol,r4
	beq		dcx12
	stz		TCB_CursorCol,r4
	bra		dcx7
dcx12:
	stz		TCB_CursorRow,r4
	bra		dcx7
dcx11:
	pha
	phx
	phy
	cmp		#$99				; delete ?
	bne		dcx13
	jsr		CalcScreenLoc
	tay							; y = screen location
	lda		TCB_CursorCol,r4	; acc = cursor column
	bra		dcx5
dcx13	
	cmp		#CTRLH				; backspace ?
	bne		dcx3
	lda		TCB_CursorCol,r4
	beq		dcx4
	dea
	sta		TCB_CursorCol,r4
	jsr		CalcScreenLoc		; acc = screen location
	tay							; y = screen location
	lda		TCB_CursorCol,r4
dcx5:
	ldx		$4,y
	stx		(y)
	iny
	ina
	cmp		TEXTREG+TEXT_COLS
	bcc		dcx5
	lda		#' '
	jsr		AsciiToScreen
	dey
	sta		(y)
	bra		dcx4
dcx3:
	cmp		#'\n'			; linefeed ?
	beq		dclf
	tax						; save acc in x
	jsr 	CalcScreenLoc	; acc = screen location
	tay						; y = screen location
	txa						; restore r1
	jsr		AsciiToScreen	; convert ascii char to screen char
	sta		(y)
	jsr		GetScreenLocation
	sub		r3,r3,r1		; make y an index into the screen
	jsr		GetColorCodeLocation
	add		r3,r3,r1
	lda		CharColor
	sta		(y)
	jsr		IncCursorPos
	bra		dcx4
dclf:
	jsr		IncCursorRow
dcx4:
	ply
	plx
	pla
	pop		r4
	rts

;------------------------------------------------------------------------------
; Increment the cursor position, scroll the screen if needed.
;------------------------------------------------------------------------------
;
IncCursorPos:
	pha
	phx
	push	r4
	ld		r4,RunningTCB
	and		r4,r4,#$FF
	lda		TCB_CursorCol,r4
	ina
	sta		TCB_CursorCol,r4
	ldx		TEXTREG+TEXT_COLS
	cmp		r1,r2
	bcc		icc1
	stz		TCB_CursorCol,r4		; column = 0
	bra		icr1
IncCursorRow:
	pha
	phx
	push	r4
	ld		r4,RunningTCB
	and		r4,r4,#$FF
icr1:
	lda		TCB_CursorRow,r4
	ina
	sta		TCB_CursorRow,r4
	ldx		TEXTREG+TEXT_ROWS
	cmp		r1,r2
	bcc		icc1
	beq		icc1
	dex							; backup the cursor row, we are scrolling up
	stx		TCB_CursorRow,r4
	jsr		ScrollUp
icc1:
	jsr		UpdateCursorPos
icc2:
	pop		r4
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Display a string on the screen.
; The characters are packed 4 per word
;------------------------------------------------------------------------------
;
DisplayStringB:
	pha
	phx
	tax						; r2 = pointer to string
dspj1B:
	lb		r1,0,x			; move string char into acc
	inx						; increment pointer
	cmp		#0				; is it end of string ?
	beq		dsretB
	jsr		DisplayChar		; display character
	bra		dspj1B
dsretB:
	plx
	pla
	rts

DisplayStringQ:
	pha
	phx
	tax						; r2 = pointer to string
	lda		#TEXTSCR
	sta		QIndex
dspj1Q:
	lb		r1,0,x			; move string char into acc
	inx						; increment pointer
	cmp		#0				; is it end of string ?
	beq		dsretQ
	jsr		DisplayCharQ	; display character
	bra		dspj1Q
dsretQ:
	plx
	pla
	rts

DisplayCharQ:
	pha
	phx
	jsr		AsciiToScreen
	ldx		#0
	sta		(QIndex,x)
	lda		QIndex
	ina
	sta		QIndex
;	inc		QIndex
	plx
	pla
	rts

	
;------------------------------------------------------------------------------
; Display a string on the screen.
; The characters are packed 1 per word
;------------------------------------------------------------------------------
;
DisplayStringW:
	pha
	phx
	tax						; r2 = pointer to string
dspj1W:
	lda		(x)				; move string char into acc
	inx						; increment pointer
	cmp		#0				; is it end of string ?
	beq		dsretW
	jsr		DisplayChar		; display character
	bra		dspj1W			; go back for next character
dsretW:
	plx
	pla
	rts

DisplayStringCRLFB:
	jsr		DisplayStringB
CRLF:
	pha
	lda		#'\r'
	jsr		DisplayChar
	lda		#'\n'
	jsr		DisplayChar
	pla
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
TickRout:
	; support EhBASIC's IRQ functionality
	; code derived from minimon.asm
	lda		#3				; Timer is IRQ #3
	sta		IrqSource		; stuff a byte indicating the IRQ source for PEEK()
	lb		r1,IrqBase		; get the IRQ flag byte
	lsr		r4,r1
	or		r1,r1,r4
	and		#$E0
	sb		r1,IrqBase

	inc		TEXTSCR+55		; update IRQ live indicator on screen
	
	; flash the cursor
	ldx		RunningTCB
	cpx		IOFocusNdx		; only bother to flash the cursor for the task with the IO focus.
	bne		tr1a
	lda		CursorFlash		; test if we want a flashing cursor
	beq		tr1a
	jsr		CalcScreenLoc	; compute cursor location in memory
	tay
	lda		$10000,y		; get color code $10000 higher in memory
	ld		r4,IRQFlag		; get counter
	lsr		r4,r4
	and		r4,r4,#$0F		; limit to low order nybble
	and		#$F0			; prepare to or in new value, mask off foreground color
	or		r1,r1,r4		; set new foreground color for cursor
	sta		$10000,y		; store the color code back to memory
tr1a
	rts

include "null.asm"
include "keyboard.asm"

comment ~
;------------------------------------------------------------------------------
; Get a bit from the I/O focus table.
;------------------------------------------------------------------------------
GetIOFocusBit:
	phx
	phy
	tax
	and		r1,r1,#$1F		; get bit index into word
	lsr		r2,r2,#5		; get word index into table
	ldy		IOFocusTbl,x
	lsr		r3,r3,r1		; extract bit
	and		r1,r3,#1
	ply
	plx
	rts
~
;------------------------------------------------------------------------------
; ForceIOFocus
;
; Force the IO focus to a specific task.
;------------------------------------------------------------------------------
;
ForceIOFocus:
	pha
	phy
	spl		iof_sema + 1
	ldy		IOFocusNdx
	cmp		r1,r3
	beq		fif1
	jsr		CopyScreenToVirtualScreen
	sta		IOFocusNdx
	jsr		CopyVirtualScreenToScreen
fif1:
	stz		iof_sema + 1
	ply
	pla
	rts
	
;------------------------------------------------------------------------------
; SwitchIOFocus
;
; Switches the IO focus to the next task requesting the I/O focus. This
; routine may be called when a task releases the I/O focus as well as when
; the user presses ALT-TAB on the keyboard.
; On Entry: the io focus semaphore is set already.
;------------------------------------------------------------------------------
;
SwitchIOFocus:
	pha
	phy

	; First check if it's even possible to switch the focus to another
	; task. The I/O focus list could be empty or there may be only a
	; single task in the list. In either case it's not possible to
	; switch.
	ldy		IOFocusNdx		; Get the task at the head of the list.
	bmi		siof3			; Is the list empty ?
	lda		TCB_iof_next,y	; Get the next task on the list.
	cmp		r1,r3			; Will the list head change ?
	beq		siof3			; If not then no switch will occur
	
	; Copy the current task's screen to it's virtual screen buffer.
	jsr		CopyScreenToVirtualScreen

	sta		IOFocusNdx		; Make task the new head of list.

	; Copy the virtual screen of the task recieving the I/O focus to the
	; text screen.
	jsr		CopyVirtualScreenToScreen
siof3:
	ply
	pla
	rts
	
include "serial.asm"

;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------
;
DisplayNybble:
	pha
	and		#$0F
	add		#'0'
	cmp		#'9'+1
	bcc		dispnyb1
	add		#7
dispnyb1:
	jsr		DisplayChar
	pla
	rts

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------
;
DisplayByte:
	pha
	lsr		r1,r1,#4
	jsr		DisplayNybble
	pla
	jmp		DisplayNybble	; tail rts 
message "785"
;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------
;
DisplayHalf:
	pha
	lsr		r1,r1,#8
	jsr		DisplayByte
	pla
	jsr		DisplayByte
	rts

message "797"
;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------
;
DisplayWord:
	pha
	lsr		r1,r1,#16
	jsr		DisplayHalf
	pla
	jsr		DisplayHalf
	rts
message "810"
;------------------------------------------------------------------------------
; Display memory pointed to by r2.
; destroys r1,r3
;------------------------------------------------------------------------------
;
DisplayMemW:
	pha
	lda		#':'
	jsr		DisplayChar
	txa
	jsr		DisplayWord
	lda		#' '
	jsr		DisplayChar
	lda		(x)
	jsr		DisplayWord
	inx
	lda		#' '
	jsr		DisplayChar
	lda		(x)
	jsr		DisplayWord
	inx
	lda		#' '
	jsr		DisplayChar
	lda		(x)
	jsr		DisplayWord
	inx
	lda		#' '
	jsr		DisplayChar
	lda		(x)
	jsr		DisplayWord
	inx
	jsr		CRLF
	pla
	rts

message "Monitor"
;==============================================================================
; System Monitor Program
; The system monitor is task#0
;==============================================================================
;
Monitor:
	ldx		#BIOS_STACKS+0x03FF	; setup stack pointer
	txs
	lda		#0					; turn off keyboard echo
	jsr		SetKeyboardEcho
	jsr		RequestIOFocus
PromptLn:
	jsr		CRLF
	lda		#'$'
	jsr		DisplayChar

; Get characters until a CR is keyed
;
Prompt3:
	jsr		RequestIOFocus
;	lw		r1,#2			; get keyboard character
;	syscall	#417
;	jsr		KeybdCheckForKeyDirect
;	cmp		#0
	jsr		KeybdGetChar
	cmp		#-1
	beq		Prompt3
;	jsr		KeybdGetCharDirect
	cmp		#CR
	beq		Prompt1
	jsr		DisplayChar
	bra		Prompt3

; Process the screen line that the CR was keyed on
;
Prompt1:
	lda		#80
	sta		LEDS
	ldx		RunningTCB
	cpx		#MAX_TASKNO
	bhi		Prompt3
	lda		#81
	sta		LEDS
	stz		TCB_CursorCol,x	; go back to the start of the line
	jsr		CalcScreenLoc	; r1 = screen memory location
	tay
	lda		#82
	sta		LEDS
	jsr		MonGetch
	cmp		#'$'
	bne		Prompt2			; skip over '$' prompt character
	lda		#83
	sta		LEDS
	jsr		MonGetch

; Dispatch based on command character
;
Prompt2:
	cmp		#':'
	beq		EditMem
	cmp		#'D'
	bne		Prompt8
	jsr		MonGetch
	cmp		#'R'
	beq		DumpReg
	cmp		#'I'
	beq		DoDir
	dey
	bra		DumpMem
Prompt8:
	cmp		#'F'
	bne		Prompt7
	jsr		MonGetch
	cmp		#'L'
	bne		Prompt8a
	jsr		DumpIOFocusList
	jmp		Monitor
Prompt8a:
	cmp		#'I'
	beq		DoFig
	cmp		#'M'
	beq		DoFmt
	dey
	bra		FillMem
Prompt7:
	cmp		#'B'			; $B - start tiny basic
	bne		Prompt4
	lda		#3
	ldy		#CSTART
	ldx		#0
	jsr		StartTask
;	jsr		CSTART
	bra		Monitor
Prompt4:
	cmp		#'b'
	bne		Prompt5
	lda		BASIC_SESSION
	cmp		#0
	bne		bsess1
	inc		BASIC_SESSION
	lda		#3				; priority level 3
	ldy		#$F000			; start address $F000
	ldx		#$00000000		; flags: 
;	jmp		(y)
	jsr		($FFFFC004>>2)		; StartTask
	bra		Monitor
bsess1:
	inc		BASIC_SESSION
	ldx		#$3000
	ldy		#$4303000
	asl		r1,r1,#14		; * 16kW
	add		r3,r3,r1
	phy
	lda		#4095			; 4096 words to copy
	mvn						; copy BASIC ROM
	ply
	asl		r3,r3,#2		; convert to code address	
	add		r3,r3,#$3000	; xxxx_F000
	lda		#3
	ldx		#$00000000		; zero flags at startup
	jsr		($FFFFC004>>2)	; StartTask
	bra		Monitor
	emm
	cpu		W65C02
	jml		$0C000
	cpu		rtf65002
Prompt5:
	cmp		#'J'			; $J - execute code
	beq		ExecuteCode
	cmp		#'L'			; $L - load dector
	beq		LoadSector
	cmp		#'W'
	beq		WriteSector
Prompt9:
	cmp		#'?'			; $? - display help
	bne		Prompt10
	lda		#HelpMsg
	jsr		DisplayStringB
	jmp		Monitor
Prompt10:
	cmp		#'C'			; $C - clear screen
	beq		TestCLS
	cmp		#'r'
	bne		Prompt12
	lda		#4				; priority level 4
	ldx		#0				; zero all flags at startup
	ldy		#RandomLines	; task address
	jsr		(y)
;	jsr		StartTask
;	jsr		($FFFFC004>>2)	; StartTask
	jmp		Monitor
;	jmp		RandomLinesCall
Prompt12:
Prompt13:
	cmp		#'P'
	bne		Prompt14
	lda		#2
	ldx		#0
	ldy		#Piano
	jsr		($FFFFC004>>2)		; StartTask
	jmp		Monitor

Prompt14:
	cmp		#'T'
	bne		Prompt15
	jsr		MonGetch
	cmp		#'O'
	bne		Prompt14a
	jsr		DumpTimeoutList
	jmp		Monitor
Prompt14a:
	cmp		#'I'
	bne		Prompt14b
	jsr		DisplayDatetime
	jmp		Monitor
Prompt14b:
	cmp		#'E'
	bne		Prompt14c
	jsr		ReadTemp
	jmp		Monitor
Prompt14c:
	dey
	jsr		DumpTaskList
	jmp		Monitor

Prompt15:
	cmp		#'S'
	bne		Prompt16
	jsr		MonGetch
	cmp		#'P'
	bne		Prompt18
	jsr		ignBlanks
	jsr		GetHexNumber
	sta		SPSave
	jmp		Monitor
Prompt18:
	dey
	jsr		spi_init
	cmp		#0
	bne		Monitor
	jsr		spi_read_part
	cmp		#0
	bne		Monitor
	jsr		spi_read_boot
	cmp		#0
	bne		Monitor
	jsr		loadBootFile
	jmp		Monitor
Prompt16:
	cmp		#'e'
	bne		Prompt17
	lda		#1
	ldx		#0
	ldy		#eth_main
	jsr		StartTask
;	jsr		eth_main
	jmp		Monitor
Prompt17:
	cmp		#'R'
	bne		Prompt19
	jsr		MonGetch
	cmp		#'S'
	beq		LoadSector
	dey
	bra		SetRegValue
	jmp		Monitor
Prompt19:
	cmp		#'K'
	bne		Prompt20
Prompt19a:
	jsr		MonGetch
	cmp		#' '
	bne		Prompt19a
	jsr		ignBlanks
	jsr		GetDecNumber
	jsr		KillTask
	jmp		Monitor
Prompt20:
	cmp		#'8'
	bne		Prompt21
	jsr		Test816
	jmp		Monitor
Prompt21:
	cmp		#'m'
	bne		Monitor
	lda		#3
	ldx		#0
	ldy		#test_mbx_prg
	jsr		StartTask
	bra		Monitor

message "Prompt16"
RandomLinesCall:
;	jsr		RandomLines
	jmp		Monitor

MonGetch:
	lda		(y)
	iny
	jsr		ScreenToAscii
	rts

DoDir:
	jsr		do_dir
	jmp		Monitor
DoFmt:
	jsr		do_fmt
	jmp		Monitor
DoFig:
	lda		#3				; priority level 3
	ldy		#$A000			; start address $A000
	ldx		#$20000000		; flags: emmulation mode set
	jsr		StartTask
	bra		Monitor
	
TestCLS:
	jsr		MonGetch
	cmp		#'L'
	bne		Monitor
	jsr		MonGetch
	cmp		#'S'
	bne		Monitor
	jsr 	ClearScreen
	ldx		RunningTCB
	stz		TCB_CursorCol,x
	stz		TCB_CursorRow,x
	jsr		CalcScreenLoc
	jmp		Monitor
message "HelpMsg"
HelpMsg:
	db	"? = Display help",CR,LF
	db	"CLS = clear screen",CR,LF
	db	"S = Boot from SD Card",CR,LF
	db	": = Edit memory bytes",CR,LF
	db	"L = Load sector",CR,LF
	db	"W = Write sector",CR,LF
	db  "DR = Dump registers",CR,LF
	db	"D = Dump memory",CR,LF
	db	"F = Fill memory",CR,LF
	db  "FL = Dump I/O Focus List",CR,LF
;	db  "FIG = start FIG Forth",CR,LF
	db	"KILL n = kill task #n",CR,LF
	db	"B = start tiny basic",CR,LF
	db	"b = start EhBasic 6502",CR,LF
	db	"J = Jump to code",CR,LF
	db	"R[n] = Set register value",CR,LF
	db	"r = random lines - test bitmap",CR,LF
	db	"e = ethernet test",CR,LF
	db	"T = Dump task list",CR,LF
	db	"TO = Dump timeout list",CR,LF
	db	"TI = display date/time",CR,LF
	db	"TEMP = display temperature",CR,LF
	db	"P = Piano",CR,LF
	db	"8 = 816 test",CR,LF,0

;------------------------------------------------------------------------------
; Ignore blanks in the input
; r3 = text pointer
; r1 destroyed
;------------------------------------------------------------------------------
;
ignBlanks:
ignBlanks1:
	jsr		MonGetch
	cmp		#' '
	beq		ignBlanks1
	dey
	rts

;------------------------------------------------------------------------------
; Edit memory byte(s).
;------------------------------------------------------------------------------
;
EditMem:
	jsr		ignBlanks
	jsr		GetHexNumber
	or		r5,r1,r0
	ld		r4,#3
edtmem1:
	jsr		ignBlanks
	jsr		GetHexNumber
	sta		(r5)
	add		r5,r5,#1
	dec		r4
	bne		edtmem1
	jmp		Monitor

;------------------------------------------------------------------------------
; Execute code at the specified address.
;------------------------------------------------------------------------------
;
message "ExecuteCode"
ExecuteCode:
	jsr		ignBlanks
	jsr		GetHexNumber
	st		r1,JMPTMP
	lda		#xcret			; push return address so we can do an indirect jump
	pha
	ld		r1,R1Save
	ld		r2,R2Save
	ld		r3,R3Save
	ld		r4,R4Save
	ld		r5,R5Save
	ld		r6,R6Save
	ld		r7,R7Save
	ld		r8,R8Save
	ld		r9,R9Save
	ld		r10,R10Save
	ld		r11,R11Save
	ld		r12,R12Save
	ld		r13,R13Save
	ld		r14,R14Save
	ld		r15,R15Save
	jmp		(JMPTMP)
xcret:
	php
	st		r1,R1Save
	st		r2,R2Save
	st		r3,R3Save
	st		r4,R4Save
	st		r5,R5Save
	st		r6,R6Save
	st		r7,R7Save
	st		r8,R8Save
	st		r9,R9Save
	st		r10,R10Save
	st		r11,R11Save
	st		r12,R12Save
	st		r13,R13Save
	st		r14,R14Save
	st		r15,R15Save
	tsr		sp,r1
	st		r1,SPSave
	tsr		sp8,r1
	st		r1,SP8Save
	pla
	sta		SRSave
	jmp     Monitor

LoadSector:
	jsr		ignBlanks
	jsr		GetDecNumber
	pha
	jsr		ignBlanks
	jsr		GetHexNumber
	tax
	phx
;	ld		r2,#0x3800
	jsr		spi_init
	plx
	pla
	jsr		spi_read_sector
	jmp		Monitor

WriteSector:
	jsr		ignBlanks
	jsr		GetDecNumber
	pha
	jsr		ignBlanks
	jsr		GetHexNumber
	tax
	phx
	jsr		spi_init
	plx
	pla
	jsr		spi_write_sector
	jmp		Monitor

;------------------------------------------------------------------------------
; Dump the register set.
;------------------------------------------------------------------------------
message "DumpReg"
DumpReg:
	ldy		#0
DumpReg1:
	jsr		CRLF
	lda		#':'
	jsr		DisplayChar
	lda		#'R'
	jsr		DisplayChar
	ldx		#1
	tya
	ina
	jsr		PRTNUM
	lda		#' '
	jsr		DisplayChar
	lda		R1Save,y
	jsr		DisplayWord
	iny
	cpy		#15
	bne		DumpReg1
	jsr		CRLF
	lda		#':'
	jsr		DisplayChar
	lda		#'S'
	jsr		DisplayChar
	lda		#'P'
	jsr		DisplayChar
	lda		#' '
	jsr		DisplayChar
	lda		TCB_SPSave
	jsr		DisplayWord
	jsr		CRLF
	jmp		Monitor
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
SetRegValue:
	jsr		GetDecNumber
	cmp		#15
	bpl		Monitor
	pha
	jsr		ignBlanks
	jsr		GetHexNumber
	ply
	sta		R1Save,y
	jmp		Monitor
		
;------------------------------------------------------------------------------
; Do a memory dump of the requested location.
;------------------------------------------------------------------------------
;
DumpMem:
	jsr		ignBlanks
	jsr		GetHexNumber	; get start address of dump
	tax
	jsr		ignBlanks
	jsr		GetHexNumber	; get number of words to dump
	lsr						; 1/4 as many dump rows
	lsr
	bne		Dumpmem2
	lda		#1				; dump at least one row
Dumpmem2:
	jsr		CRLF
	bra		DumpmemW
DumpmemW:
	jsr		DisplayMemW
	dea
	bne		DumpmemW
	jmp		Monitor


	bra		Monitor
message "FillMem"
FillMem:
	jsr		ignBlanks
	jsr		GetHexNumber	; get start address of dump
	tax
	jsr		ignBlanks
	jsr		GetHexNumber	; get number of bytes to fill
	ld		r5,r1
	jsr		ignBlanks
	jsr		GetHexNumber	; get the fill byte
FillmemW:
	sta		(x)
	inx
	dec		r5
	bne		FillmemW
	jmp		Monitor

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
; R3 = text pointer (updated)
; R1 = hex number
;------------------------------------------------------------------------------
;
GetHexNumber:
	phx
	push	r4
	ldx		#0
	ld		r4,#8
gthxn2:
	jsr		MonGetch
	jsr		AsciiToHexNybble
	cmp		#-1
	beq		gthxn1
	asl		r2,r2,#4
	and		#$0f
	or		r2,r2,r1
	dec		r4
	bne		gthxn2
gthxn1:
	txa
	pop		r4
	plx
	rts

GetDecNumber:
	phx
	push	r4
	push	r5
	ldx		#0
	ld		r4,#10
	ld		r5,#10
gtdcn2:
	jsr		MonGetch
	jsr		AsciiToDecNybble
	cmp		#-1
	beq		gtdcn1
	mul		r2,r2,r5
	add		r2,r2,r1
	dec		r4
	bne		gtdcn2
gtdcn1:
	txa
	pop		r5
	pop		r4
	plx
	rts

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	cmp		#'0'
	bcc		gthx3
	cmp		#'9'+1
	bcs		gthx5
	sub		#'0'
	rts
gthx5:
	cmp		#'A'
	bcc		gthx3
	cmp		#'F'+1
	bcs		gthx6
	sub		#'A'
	add		#10
	rts
gthx6:
	cmp		#'a'
	bcc		gthx3
	cmp		#'z'+1
	bcs		gthx3
	sub		#'a'
	add		#10
	rts
gthx3:
	lda		#-1		; not a hex number
	rts

AsciiToDecNybble:
	cmp		#'0'
	bcc		gtdc3
	cmp		#'9'+1
	bcs		gtdc3
	sub		#'0'
	rts
gtdc3:
	lda		#-1
	rts


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
ClearBmpScreen:
	pha
	phx
	phy
	lda		#(680*384)		; a = # bytes to clear
	ldx		#0x29292929			; acc = color for four pixels
	ldy		#BITMAPSCR;<<2		; y = screen address
cbmp1:
;	tsr		LFSR,r2
;	sb		r2,0,y
;	iny
;	dea
;	bne		cbmp1
	stos
	ply
	plx
	pla
	rts

;==============================================================================
;==============================================================================
;--------------------------------------------------------------------------
; Setup the AC97/LM4550 audio controller. Check keyboard for a CTRL-C
; interrupt which may be necessary if the audio controller isn't 
; responding.
;--------------------------------------------------------------------------
;
SetupAC97:
	pha
	phx
	phy
	push	r4
	ld		r4,Milliseconds
sac974:
	stz		AC97+0x26		; trigger a read of register 26 (status reg)
sac971:						; wait for status to register 0xF (all ready)
	ld		r3,Milliseconds
	sub		r3,r3,r4
	cmp		r3,#1000
	bhi		sac97Abort
	jsr		KeybdGetChar	; see if we needed to CTRL-C
	cmp		#CTRLC
	beq		sac973
	lda		AC97+0x68		; wait for dirty bit to clear
	bne		sac971
	lda		AC97+0x26		; check status at reg h26, wait for
	and		#0x0F			; analogue to be ready
	cmp		#$0F
	bne		sac974
sac973:
	stz		AC97+2			; master volume, 0db attenuation, mute off
	stz		AC97+4			; headphone volume, 0db attenuation, mute off
	stz		AC97+0x18		; PCM gain (mixer) mute off, no attenuation
	stz		AC97+0x0A		; mute PC beep
	lda		#0x8000			; bypass 3D sound
	sta		AC97+0x20
	ld		r4,Milliseconds
sac972:
	ld		r3,Milliseconds
	sub		r3,r3,r4
	cmp		r3,#1000
	bhi		sac97Abort
	jsr		KeybdGetChar
	cmp		#CTRLC
	beq		sac975
	lda		AC97+0x68		; wait for dirty bits to clear
	bne		sac972			; wait a while for the settings to take effect
sac975:
	pop		r4
	ply
	plx
	pla
	rts
sac97Abort:
	lda		#msgAC97bad
	jsr		DisplayStringCRLFB
	pop		r4
	ply
	plx
	pla
	rts

msgAC97bad:
	db	"The AC97 controller is not responding.",CR,LF,0

;--------------------------------------------------------------------------
; Sound a 800 Hz beep
;--------------------------------------------------------------------------
;
Beep:
	lda		#15				; master volume to max
	sta		PSG+64
	lda		#13422			; 800Hz
	sta		PSGFREQ0
	; decay  (16.384 ms)2
	; attack (8.192 ms)1
	; release (1.024 s)A
	; sustain level C
	lda		#0xCA12
	sta		PSGADSR0
	lda		#0x1104			; gate, output enable, triangle waveform
	sta		PSGCTRL0
	lda		#1000			; delay about 1s
	jsr		Sleep
	lda		#0x0104			; gate off, output enable, triangle waveform
	sta		PSGCTRL0
	lda		#1000			; delay about 1s
	jsr		Sleep
	lda		#83
	sta		LEDS
	lda		#0x0000			; gate off, output enable off, no waveform
	sta		PSGCTRL0
	rts

include "Piano.asm"

;==============================================================================
;==============================================================================
;
; Initialize the SD card
; Returns
; acc = 0 if successful, 1 otherwise
; Z=1 if successful, otherwise Z=0
;
message "spi_init"
spi_init
	lda		#SPI_INIT_SD
	sta		SPIMASTER+SPI_TRANS_TYPE_REG
	lda		#SPI_TRANS_START
	sta		SPIMASTER+SPI_TRANS_CTRL_REG
	nop
spi_init1
	lda		SPIMASTER+SPI_TRANS_STATUS_REG
	nop
	nop
	cmp		#SPI_TRANS_BUSY
	beq		spi_init1
	lda		SPIMASTER+SPI_TRANS_ERROR_REG
	and		#3
	cmp		#SPI_INIT_NO_ERROR
	bne		spi_error
;	lda		#spi_init_ok_msg
;	jsr		DisplayStringB
	lda		#0
	rts
spi_error
	jsr		DisplayByte
	lda		#spi_init_error_msg
	jsr		DisplayStringB
	lda		SPIMASTER+SPI_RESP_BYTE1
	jsr		DisplayByte
	lda		SPIMASTER+SPI_RESP_BYTE2
	jsr		DisplayByte
	lda		SPIMASTER+SPI_RESP_BYTE3
	jsr		DisplayByte
	lda		SPIMASTER+SPI_RESP_BYTE4
	jsr		DisplayByte
	lda		#1
	rts

spi_delay:
	nop
	nop
	rts


; SPI read sector
;
; r1= sector number to read
; r2= address to place read data
; Returns:
; r1 = 0 if successful
;
spi_read_sector:
	phx
	phy
	push	r4
	
	sta		SPIMASTER+SPI_SD_SECT_7_0_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_15_8_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_23_16_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_31_24_REG

	ld		r4,#20	; retry count

spi_read_retry:
	; Force the reciever fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	lda		#1
	sta		SPIMASTER+SPI_RX_FIFO_CTRL_REG

	lda		#RW_READ_SD_BLOCK
	sta		SPIMASTER+SPI_TRANS_TYPE_REG
	lda		#SPI_TRANS_START
	sta		SPIMASTER+SPI_TRANS_CTRL_REG
	nop
spi_read_sect1:
	lda		SPIMASTER+SPI_TRANS_STATUS_REG
	jsr		spi_delay			; just a delay between consecutive status reg reads
	cmp		#SPI_TRANS_BUSY
	beq		spi_read_sect1
	lda		SPIMASTER+SPI_TRANS_ERROR_REG
	lsr
	lsr
	and		#3
	cmp		#SPI_READ_NO_ERROR
	bne		spi_read_error
	ldy		#512		; read 512 bytes from fifo
spi_read_sect2:
	lda		SPIMASTER+SPI_RX_FIFO_DATA_REG
	sb		r1,0,x
	inx
	dey
	bne		spi_read_sect2
	lda		#0
	bra		spi_read_ret
spi_read_error:
	dec		r4
	bne		spi_read_retry
	jsr		DisplayByte
	lda		#spi_read_error_msg
	jsr		DisplayStringB
	lda		#1
spi_read_ret:
	pop		r4
	ply
	plx
	rts

; SPI write sector
;
; r1= sector number to write
; r2= address to get data from
; Returns:
; r1 = 0 if successful
;
spi_write_sector:
	phx
	phy
	pha
	; Force the transmitter fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	lda		#1
	sta		SPIMASTER+SPI_TX_FIFO_CTRL_REG
	nop			; give I/O time to respond
	nop

	; now fill up the transmitter fifo
	ldy		#512
spi_write_sect1:
	lb		r1,0,x
	sta		SPIMASTER+SPI_TX_FIFO_DATA_REG
	nop			; give the I/O time to respond
	nop
	inx
	dey
	bne		spi_write_sect1

	; set the sector number in the spi master address registers
	pla
	sta		SPIMASTER+SPI_SD_SECT_7_0_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_15_8_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_23_16_REG
	lsr		r1,r1,#8
	sta		SPIMASTER+SPI_SD_SECT_31_24_REG

	; issue the write command
	lda		#RW_WRITE_SD_BLOCK
	sta		SPIMASTER+SPI_TRANS_TYPE_REG
	lda		#SPI_TRANS_START
	sta		SPIMASTER+SPI_TRANS_CTRL_REG
	nop
spi_write_sect2:
	lda		SPIMASTER+SPI_TRANS_STATUS_REG
	nop							; just a delay between consecutive status reg reads
	nop
	cmp		#SPI_TRANS_BUSY
	beq		spi_write_sect2
	lda		SPIMASTER+SPI_TRANS_ERROR_REG
	lsr		r1,r1,#4
	and		#3
	cmp		#SPI_WRITE_NO_ERROR
	bne		spi_write_error
	lda		#0
	bra		spi_write_ret
spi_write_error:
	jsr		DisplayByte
	lda		#spi_write_error_msg
	jsr		DisplayStringB
	lda		#1

spi_write_ret:
	ply
	plx
	rts

; SPI read multiple sector
;
; r1= sector number to read
; r2= address to write data
; r3= number of sectors to read
;
; Returns:
; r1 = 0 if successful
;
spi_read_multiple:
	push	r4
	ld		r4,#0
spi_rm1:
	pha
	jsr		spi_read_sector
	add		r4,r4,r1
	add		r2,r2,#512
	pla
	ina
	dey
	bne		spi_rm1
	ld		r1,r4
	pop		r4
	rts

; SPI write multiple sector
;
; r1= sector number to write
; r2= address to get data from
; r3= number of sectors to write
;
; Returns:
; r1 = 0 if successful
;
spi_write_multiple:
	push	r4
	ld		r4,#0
spi_wm1:
	pha
	jsr		spi_write_sector
	add		r4,r4,r1		; accumulate an error count
	add		r2,r2,#512		; 512 bytes per sector
	pla
	ina
	dey
	bne		spi_wm1
	ld		r1,r4
	pop		r4
	rts
	
; read the partition table to find out where the boot sector is.
; Returns
; r1 = 0 everything okay, 1=read error
; also Z=1=everything okay, Z=0=read error
;
spi_read_part:
	phx
	stz		startSector						; default starting sector
	lda		#0								; r1 = sector number (#0)
	ldx		#BYTE_SECTOR_BUF				; r2 = target address (word to byte address)
	jsr		spi_read_sector
	cmp		#0
	bne		spi_rp1
	lb		r1,BYTE_SECTOR_BUF+$1C9
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C8
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C7
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$1C6
	sta		startSector						; r1 = 0, for okay status
	plx
	lda		#0
	rts
spi_rp1:
	plx
	lda		#1
	rts

; Read the boot sector from the disk.
; Make sure it's the boot sector by looking for the signature bytes 'EB' and '55AA'.
; Returns:
; r1 = 0 means this card is bootable
; r1 = 1 means a read error occurred
; r1 = 2 means the card is not bootable
;
spi_read_boot:
	phx
	phy
	push	r5
	lda		startSector					; r1 = sector number
	ldx		#BYTE_SECTOR_BUF			; r2 = target address
	jsr		spi_read_sector
	cmp		#0
	bne		spi_read_boot_err
	lb		r1,BYTE_SECTOR_BUF
	cmp		#$EB
	bne		spi_eb_err
spi_read_boot2:
	lda		#msgFoundEB
	jsr		DisplayStringB
	lb		r1,BYTE_SECTOR_BUF+$1FE		; check for 0x55AA signature
	cmp		#$55
	bne		spi_eb_err
	lb		r1,BYTE_SECTOR_BUF+$1FF		; check for 0x55AA signature
	cmp		#$AA
	bne		spi_eb_err
	pop		r5
	ply
	plx
	lda		#0						; r1 = 0, for okay status
	rts
spi_read_boot_err:
	pop		r5
	ply
	plx
	lda		#1
	rts
spi_eb_err:
	lda		#msgNotFoundEB
	jsr		DisplayStringB
	pop		r5
	ply
	plx
	lda		#2
	rts

msgFoundEB:
	db	"Found EB code.",CR,LF,0
msgNotFoundEB:
	db	"EB/55AA Code missing.",CR,LF,0

; Load the root directory from disk
; r2 = where to place root directory in memory
;
loadBootFile:
	lb		r1,BYTE_SECTOR_BUF+BSI_SecPerFAT+1			; sectors per FAT
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+BSI_SecPerFAT
	bne		loadBootFile7
	lb		r1,BYTE_SECTOR_BUF+$27			; sectors per FAT, FAT32
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$26
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$25
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$24
loadBootFile7:
	lb		r4,BYTE_SECTOR_BUF+$10			; number of FATs
	mul		r3,r1,r4						; offset
	lb		r1,BYTE_SECTOR_BUF+$F			; r1 = # reserved sectors before FAT
	asl		r1,r1,#8
	orb		r1,r1,BYTE_SECTOR_BUF+$E
	add		r3,r3,r1						; r3 = root directory sector number
	ld		r6,startSector
	add		r5,r3,r6						; r5 = root directory sector number
	lb		r1,BYTE_SECTOR_BUF+$D			; sectors per cluster
	add		r3,r1,r5						; r3 = first cluster after first cluster of directory
	bra		loadBootFile6

loadBootFile6:
	; For now we cheat and just go directly to sector 512.
	bra		loadBootFileTmp

loadBootFileTmp:
	; We load the number of sectors per cluster, then load a single cluster of the file.
	; This is 16kib
	ld		r5,r3							; r5 = start sector of data area	
	ld		r2,#PROG_LOAD_AREA				; where to place file in memory
	lb		r3,BYTE_SECTOR_BUF+$D			; sectors per cluster
loadBootFile1:
	ld		r1,r5							; r1=sector to read
	jsr		spi_read_sector
	inc		r5						; r5 = next sector
	add		r2,r2,#512
	dec		r3
	bne		loadBootFile1
	lda		PROG_LOAD_AREA>>2		; make sure it's bootable
	cmp		#$544F4F42
	bne		loadBootFile2
	lda		#msgJumpingToBoot
	jsr		DisplayStringB
	lda		(PROG_LOAD_AREA>>2)+$1
	jsr		(r1)
	jmp		Monitor
loadBootFile2:
	lda		#msgNotBootable
	jsr		DisplayStringB
	ldx		#PROG_LOAD_AREA>>2
	jsr		DisplayMemW
	jsr		DisplayMemW
	jsr		DisplayMemW
	jsr		DisplayMemW
	jmp		Monitor

msgJumpingToBoot:
	db	"Jumping to boot",0	
msgNotBootable:
	db	"SD card not bootable.",0
spi_init_ok_msg:
	db "SD card initialized okay.",0
spi_init_error_msg:
	db	": error occurred initializing the SD card.",0
spi_boot_error_msg:
	db	"SD card boot error",CR,LF,0
spi_read_error_msg:
	db	"SD card read error",CR,LF,0
spi_write_error_msg:
	db	"SD card write error",0

do_fmt:
	jsr		spi_init
	cmp		#0
	bne		fmt_abrt
	ldx		#DIRBUF
	ldy		#65536
	; clear out the directory buffer
dfmt1:
	stz		(x)
	inx
	dey
	bne		dfmt1
	jsr		store_dir
fmt_abrt:
	rts

do_dir:
	jsr		CRLF
	jsr		spi_init
	cmp		#0
	bne		dirabrt
	jsr		load_dir
	ld		r4,#0			; r4 = entry counter
ddir3:
	asl		r3,r4,#6		; y = start of entry, 64 bytes per entry
	ldx		#32				; 32 chars in filename
ddir4:
	lb		r1,DIRBUF<<2,y
	beq		ddir2			; move to next dir entry if null is found
	cmp		#$20			; don't display control chars
	bmi		ddir1
	jsr		DisplayChar
	bra		ddir5
ddir1:
	lda		#' '
	jsr		DisplayChar
ddir5:
	iny
	dex
	bne		ddir4
	lda		#' '
	jsr		DisplayChar
	asl		r3,r4,#4		; y = start of entry, 16 words per entry
	lda		DIRBUF+$D,y
	ldx		#5
	jsr		PRTNUM
	jsr		CRLF
ddir2:
	jsr		KeybdGetChar
	cmp		#CTRLC
	beq		ddir6
	inc		r4
	cmp		r4,#512		; max 512 dir entries
	bne		ddir3
ddir6:

dirabrt:
	rts

load_dir:
	pha
	phx
	phy
	lda		#4000
	ldx		#DIRBUF<<2
	ldy		#64
	jsr		spi_read_multiple
	ply
	plx
	pla
	rts
store_dir:
	pha
	phx
	phy
	lda		#4000
	ldx		#DIRBUF<<2
	ldy		#64
	jsr		spi_write_multiple
	ply
	plx
	pla
	rts

; r1 = pointer to file name
; r2 = pointer to buffer to save
; r3 = length of buffer
;
do_save:
	pha
	jsr		spi_init
	cmp		#0
	bne		dsavErr
	pla
	jsr		load_dir
	ld		r4,#0
dsav4:
	asl		r5,r4,#6
	ld		r7,#0
	ld		r10,r1
dsav2:
	lb		r6,DIRBUF<<2,r5
	lb		r8,0,r10
	cmp		r6,r8
	bne		dsav1
	inc		r5
	inc		r7
	inc		r10
	cmp		r7,#32
	bne		dsav2
	; here the filename matched
dsav8:
	asl		r7,r4,#7	; compute file address	64k * entry #
	add		r7,r7,#5000	; start at sector 5,000
	ld		r1,r7		; r1 = sector number
	lsr		r3,r3,#9	; r3/512
	iny					; +1
	jsr		spi_write_multiple
dsav3:
	rts
	; Here the filename didn't match
dsav1:
	inc		r4
	cmp		r4,#512
	bne		dsav4
	; Here none of the filenames in the directory matched
	; Find an empty entry.
	ld		r4,#0
dsav6:
	asl		r5,r4,#6
	lb		r6,DIRBUF<<2,r5
	beq		dsav5
	inc		r4
	cmp		r4,#512
	bne		dsav6
	; Here there were no empty entries
	lda		#msgDiskFull
	jsr		DisplayStringB
	rts
dsav5:
	ld		r7,#32
	ld		r10,r1
dsav7:
	lb		r6,0,r10	; copy the filename into the directory entry
	sb		r6,DIRBUF<<2,r5
	inc		r5
	inc		r10
	dec		r7
	bne		dsav7
						; copy the file size into the directory entry
	asl		r5,r4,#4	; 16 words per dir entry
	sty		DIRBUF+$D,r5
	jsr		store_dir
	bra		dsav8
dsavErr:
	pla
	rts

msgDiskFull
	db	CR,LF,"The disk is full, unable to save file.",CR,LF,0

do_load:
	pha
	jsr		spi_init
	cmp		#0
	bne		dsavErr
	pla
	jsr		load_dir
	ld		r4,#0
dlod4:
	asl		r5,r4,#6
	ld		r7,#0
	ld		r10,r1
dlod2:
	lb		r6,DIRBUF<<2,r5
	lb		r8,0,r10
	cmp		r6,r8
	bne		dlod1
	inc		r5
	inc		r7
	inc		r10
	cmp		r7,#32
	bne		dlod2
	; here the filename matched
dlod8:
	asl		r5,r4,#4				; 16 words
	ld		r3,DIRBUF+$d,r5			; get file size into y register
	asl		r7,r4,#7	; compute file address	64k * entry #
	add		r7,r7,#5000	; start at sector 5,000
	ld		r1,r7		; r1 = sector number
	lsr		r3,r3,#9	; r3/512
	iny					; +1
	jsr		spi_read_multiple
dlod3:
	rts
	; Here the filename didn't match
dlod1:
	inc		r4
	cmp		r4,#512
	bne		dlod4
	; Here none of the filenames in the directory matched
	; 
	lda		#msgFileNotFound
	jsr		DisplayStringB
	rts

msgFileNotFound:
	db	CR,LF,"File not found.",CR,LF

;include "ethernet.asm"	

;--------------------------------------------------------------------------
; Initialize sprite image caches with random data.
;--------------------------------------------------------------------------
message "RandomizeSprram"
RandomizeSprram:
	ldx		#SPRRAM
	ld		r4,#14336		; number of chars to initialize
rsr1:
	tsr		LFSR,r1
	sta		(x)
	inx
	dec		r4
	bne		rsr1
	rts

;--------------------------------------------------------------------------
; Draw random lines on the bitmap screen.
;--------------------------------------------------------------------------
;
message "RandomLines"
RandomLines:
	pha
	phx
	phy
	push	r4
	push	r5
	jsr		RequestIOFocus
	jsr		ClearScreen
	jsr		HomeCursor
	lda		#msgRandomLines
	jsr		DisplayStringB
	lda		#1
	sta		gr_cmd
rl5:
	tsr		LFSR,r1
	tsr		LFSR,r2
	tsr		LFSR,r3
	mod		r1,r1,#680
	mod		r2,r2,#384
	jsr		DrawPixel
	tsr		LFSR,r1
	sta		LineColor		; select a random color
rl1:						; random X0
	tsr		LFSR,r1
	mod		r1,r1,#680
rl2:						; random X1
	tsr		LFSR,r3
	mod		r3,r3,#680
rl3:						; random Y0
	tsr		LFSR,r2
	mod		r2,r2,#384
rl4:						; random Y1
	tsr		LFSR,r4
	mod		r4,r4,#384
rl8:
	ld		r5,GA_STATE		; make sure state is IDLE
	bne		rl8
	ld 		r5,gr_cmd
	cmp		r5,#2
	bne		rl11
	jsr		DrawLine
	bra		rl12
rl11:
	cmp		r5,#1
	bne		rl13
	jsr		DrawPixel
	bra		rl12
rl13:
	cmp		r5,#4
	bne		rl12
	jsr		DrawRectangle
rl12:
	jsr		KeybdGetChar
	cmp		#CTRLC
	beq		rl7
	cmp		#'p'
	bne		rl9
	jsr		ClearBmpScreen
	lda		#1
	sta		gr_cmd
	bra		rl5
rl9:
	cmp		#'r'
	bne		rl10
	jsr		ClearBmpScreen
	lda		#4
	sta		gr_cmd
	bra		rl5
rl10
	cmp		#'l'
	bne		rl5
	jsr		ClearBmpScreen
	lda		#2
	sta		gr_cmd
	bra		rl5
rl7:
;	jsr		ReleaseIOFocus
	pop		r5
	pop		r4
	ply
	plx
	pla
	rts


msgRandomLines:
	db		CR,LF,"Random lines running - press CTRL-C to exit.",CR,LF,0

;--------------------------------------------------------------------------
; Draw a pixel on the bitmap screen.
; r1 = x coordinate
; r2 = y coordinate
; r3 = color
;--------------------------------------------------------------------------
message "DrawPixel"
DrawPixel:
	pha
	sta		GA_X0
	stx		GA_Y0
	sty		GA_PEN
	lda		#1
	sta		GA_CMD
	pla
	rts
comment ~
	pha
	phx
	mul		r2,r2,#680	; y * 680
	add		r1,r1,r2	; + x
	sb		r3,BITMAPSCR<<2,r1
	plx
	pla
	rts
~
;--------------------------------------------------------------------------
; Draw a line on the bitmap screen.
;--------------------------------------------------------------------------
;50 REM DRAWLINE
;100 dx = ABS(xb-xa)
;110 dy = ABS(yb-ya)
;120 sx = SGN(xb-xa)
;130 sy = SGN(yb-ya)
;140 er = dx-dy
;150 PLOT xa,ya
;160 if xa<>xb goto 200
;170 if ya=yb goto 300
;200 ee = er * 2
;210 if ee <= -dy goto 240
;220 er = er - dy
;230 xa = xa + sx
;240 if ee >= dx goto 270
;250 er = er + dx
;260 ya = ya + sy
;270 GOTO 150
;300 RETURN

message "DrawLine"
DrawLine:
	pha
	sta		GA_X0
	stx		GA_Y0
	sty		GA_X1
	st		r4,GA_Y1
	lda		LineColor
	sta		GA_PEN
	lda		#2
	sta		GA_CMD
	pla
	rts

DrawRectangle:
	pha
	sta		GA_X0
	stx		GA_Y0
	sty		GA_X1
	st		r4,GA_Y1
	lda		LineColor
	sta		GA_PEN
	lda		#4
	sta		GA_CMD
	pla
	rts

comment ~
	pha
	phx
	phy
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	push	r9
	push	r10
	push	r11

	sub		r5,r3,r1	; dx = abs(x2-x1)
	bpl		dln1
	sub		r5,r0,r5
dln1:
	sub		r6,r4,r2	; dy = abs(y2-y1)
	bpl		dln2
	sub		r6,r0,r6
dln2:

	sub		r7,r3,r1	; sx = sgn(x2-x1)
	beq		dln5
	bpl		dln4
	ld		r7,#-1
	bra		dln5
dln4:
	ld		r7,#1
dln5:

	sub		r8,r4,r2	; sy = sgn(y2-y1)
	beq		dln8
	bpl		dln7
	ld		r8,#-1
	bra		dln8
dln7:
	ld		r8,#1

dln8:
	sub		r9,r5,r6	; er = dx-dy
dln150:
	phy
	ldy		LineColor
	jsr		DrawPixel
	ply
	cmp		r1,r3		; if (xa <> xb)
	bne		dln200		;    goto 200
	cmp		r2,r4		; if (ya==yb)
	beq		dln300		;    goto 300
dln200:
	asl		r10,r9		; ee = er * 2
	sub		r11,r0,r6	; r11 = -dy
	cmp		r10,r11		; if (ee <= -dy)
	bmi		dln240		;     goto 240
	beq		dln240
	sub		r9,r9,r6	; er = er - dy
	add		r1,r1,r7	; xa = xa + sx
dln240:
	cmp		r10,r5		; if (ee >= dx)
	bpl		dln150		;    goto 150
	add		r9,r9,r5	; er = er + dx
	add		r2,r2,r8	; ya = ya + sy
	bra		dln150		; goto 150

dln300:
	pop		r11
	pop		r10
	pop		r9
	pop		r8
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ply
	plx
	pla
	rts
~

;include "float.asm"

;--------------------------------------------------------------------------
; RTF65002 code to display the date and time from the date/time device.
;--------------------------------------------------------------------------
DisplayDatetime
	pha
	phx
	lda		#' '
	jsr		DisplayChar
	stz		DATETIME_SNAPSHOT	; take a snapshot of the running date/time
	lda		DATETIME_DATE
	tax
	lsr		r1,r1,#16
	jsr		DisplayHalf		; display the year
	lda		#'/'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#8
	and		#$FF
	jsr		DisplayByte		; display the month
	lda		#'/'
	jsr		DisplayChar
	txa
	and		#$FF
	jsr		DisplayByte		; display the day
	lda		#' '
	jsr		DisplayChar
	lda		#' '
	jsr		DisplayChar
	lda		DATETIME_TIME
	tax
	lsr		r1,r1,#24
	jsr		DisplayByte		; display hours
	lda		#':'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#16
	jsr		DisplayByte		; display minutes
	lda		#':'
	jsr		DisplayChar
	txa
	lsr		r1,r1,#8
	jsr		DisplayByte		; display seconds
	lda		#'.'
	jsr		DisplayChar
	txa
	jsr		DisplayByte		; display 100ths seconds
	jsr		CRLF
	plx
	pla
	rts

include "ReadTemp.asm"

;==============================================================================
; Memory Management routines follow.
;==============================================================================
MemInit:
	lda		#1					; initialize memory semaphore
	sta		MEM_SEMA
	lda		#$4D454D20
	sta		HeapStart+MEM_CHK
	sta		HeapStart+MEM_FLAG
	sta		HeapEnd-2
	sta		HeapEnd-3
	lda		#0
	sta		HeapStart+MEM_PREV	; prev of first MEMHDR
	sta		HeapEnd			; next of last MEMHDR
	lda		#HeapEnd
	ina
	sub		#$4
	sta		HeapStart+MEM_NEXT	; next of first MEMHDR
	lda		#HeapStart
	sta		HeapEnd-1		; prev of last MEMHDR

	; Initialize the allocated page map to zero.
	lda		#64				; 64*32 = 2048 bits
	ldx		#0
	ldy		#PageMap
	stos
	lda		#64				; 64*32 = 2048 bits
	ldx		#0
	ldy		#PageMap2
	stos
	; Mark the last 128 pages as used (by the OS)
	; 4-32 bit words
	lda		#-1
	sta		PageMap+60
	sta		PageMap+61
	sta		PageMap+62
	sta		PageMap+63
	rts

ReportMemFree:
	jsr		CRLF
	lda		#HeapEnd
	ina
	sub		#HeapStart
	ldx		#5
	jsr		PRTNUM
	lda		#msgMemFree
	jsr		DisplayStringB
	rts

msgMemFree:
	db	" words free",CR,LF,0
	
;------------------------------------------------------------------------------
; Allocate memory from the heap.
;------------------------------------------------------------------------------
MemAlloc:
	phx
	phy
	push	r4
memaSpin:
	ldx		MEM_SEMA+1
	beq		memaSpin
	ldx		#HeapStart
mema4:
	ldy		MEM_FLAG,x		; Check the flag word to see if this block is available
	cpy		#$4D454D20
	bne		mema1			; block not available, go to next block
	ld		r4,MEM_NEXT,x	; compute the size of this block
	sub		r4,r4,r2
	sub		r4,r4,#4		; minus size of block header
	cmp		r1,r4			; is the block large enough ?
	bmi		mema2			; if yes, go allocate
mema1:
	ldx		MEM_NEXT,x		; go to the next block
	beq		mema3			; if no more blocks, out of memory error
	bra		mema4
mema2:
	ldy		#$6D656D20
	sty		MEM_FLAG,x
	sub		r4,r4,r1
	cmp		r4,#4			; is the block large enough to split
	bpl		memaSplit
	stz		MEM_SEMA+1
	txa
	pop		r4
	ply
	plx
	rts
mema3:						; insufficient memory
	stz		MEM_SEMA+1
	pop		r4
	ply
	plx
	lda		#0
	rts
memaSplit:
	add		r4,r1,r2
	add		r4,#4
	ldy		#$4D454D20
	sty		(r4)
	sty		MEM_FLAG,r4
	stx		MEM_PREV,r4
	ldy		MEM_NEXT,x
	sty		MEM_NEXT,r4
	st		r4,MEM_PREV,y
	ld		r1,r4
	stz		MEM_SEMA+1
	pop		r4
	ply
	plx
	rts

;------------------------------------------------------------------------------
; Free previously allocated memory. Recombine with next and previous blocks
; if they are free as well.
;------------------------------------------------------------------------------
MemFree:
	cmp		#0			; null pointer ?
	beq		memf2
	phx
	phy
memfSpin:
	ldx		MEM_SEMA+1
	beq		memfSpin
	ldx		MEM_FLAG,r1
	cpx		#$6D656D20	; is the block allocated ?
	bne		memf1
	ldx		#$4D454D20
	stx		MEM_FLAG,r1	; mark block as free
	ldx		MEM_PREV,r1	; is the previous block free ?
	beq		memf3		; no previous block
	ldy		MEM_FLAG,x
	cpy		#$4D454D20
	bne		memf3		; the previous block is not free
	ldy		MEM_NEXT,r1
	sty		MEM_NEXT,x
	beq		memf1		; no next block
	stx		MEM_PREV,y
memf3:
	ldy		MEM_NEXT,r1
	ldx		MEM_FLAG,y
	cpx		#$4D454D20
	bne		memf1		; next block not free
	ldx		MEM_PREV,r1
	stx		MEM_PREV,y
	beq		memf1		; no previous block
	sty		MEM_NEXT,x
memf1:
	stz		MEM_SEMA+1
	ply
	plx
memf2:
	rts

;------------------------------------------------------------------------------
; Allocate a memory page from the available memory pool.
; Returns a pointer to the page in memory. The address returned is the
; virtual memory address.
;------------------------------------------------------------------------------
AllocateMemPage:
	php
	phx
	phy
	lda		#0
	ldx		#2048
	cli
amp2:
	bmt		PageMap
	beq		amp1
	ina
	dex
	bne		amp2
	; Here all memory pages are already in use. No more memmory is available.
	ply
	plx
	plp
	lda		#0
	rts
	; Here we found an unallocated memory page. Next find a spot in the MMU
	; map to place the page.
amp1:
	; Find unallocated map slot in the MMU
	ldx		RunningTCB		; set access key for MMU
	stx		MMU_AKEY
	ldx		#0
amp4:
	ldy		MMU,x
	cpy		#INV_PAGE
	beq		amp3
	inx
	cpx		#383
	bne		amp4
	; Here we searched the entire MMU slots and none were available
	ply
	plx
	plp
	lda		#0		; return NULL pointer
	rts
amp3:
	bms		PageMap		; mark page as allocated
	sta		MMU,x		; put the page# into the map slot
	asl		r2,r2,#14	; pages are 16kW in size
	add		r1,r2,#DRAM_BASE	; add in base address
	ply
	plx
	plp
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = size of allocation in words
; Returns:
;	r1 = word pointer to memory
; No MMU
;------------------------------------------------------------------------------
;
AllocMemPages:
	php
	phx
	phy
	push	r4
	sei
amp5:
	tay
	lsr		r3,r3,#14	; convert amount to #pages
	iny					; round up
	tyx					; x = request size in pages
	; Search for a group of free pages large enough to satisfy the request
	lda		#0
amp7:
	bmt		PageMap		; test for a free page
	bne		amp6		; not a free page
	ld		r4,r1		; remember the page we were on
	cpx		#1			; did we find enough free pages ?
	bls		amp8
	dex					; keep checking for next free page
	ina
	cmp		#1919		; did we hit end of map ?
	bhi		amp11		; can't allocate enough memory
	bra		amp7		; go back and test for another free page
amp6:
	tyx					; reset size count
	ina					; move to the next page
	cmp		#1919		; test if hit end of map
	bls		amp7
amp11:
	; Insufficient memory, return NULL pointer
	lda		#0
	pop		r4
	ply
	plx
	plp
	rts

	; Mark pages as allocated
amp8:
	ld		r1,r4
amp10:
	bms		PageMap
	bmc		PageMap2
	cpy		#1
	bls		amp9
	dey
	ina
	cmp		#1919
	blo		amp10
amp9:
	bms		PageMap
	bms		PageMap2	; flag end of allocation
	ld		r1,r4
	asl		r1,r1,#14	; * 16kW
	add		r1,r1,#DRAM_BASE
	pop		r4
	ply
	plx
	plp
	rts

;------------------------------------------------------------------------------
; brk
; Establish a new program break
;
; Parameters:
; r1 = new program break address
;------------------------------------------------------------------------------
;
_brk:
	phx
	push	r4
	push	r5
	push	r6
	ldx		RunningTCB
	ld		r4,TCB_ASID,x
	st		r4,MMU_AKEY
	ld		r4,TCB_npages,x
	lsr		r1,r1,#14
	add		r1,r1,#1
	cmp		r1,r4
	beq		brk6			; allocation isn't changing
	blo		brk1			; reducing allocation

	; Here we're increasing the amount of memory allocated to the program.
	;
	cmp		r1,#383			; max 383 RAM pages
	bhi		brk2
	sub		r1,r1,r4		; number of new pages
	cmp		r1,mem_pages_free	; are there enough free pages ?
	bhi		brk2
	ld		r5,mem_pages_free
	sub		r5,r5,r1
	st		r5,mem_pages_free
	ld		r6,r1			; r6 = number of pages to allocate
	add		r1,r1,r4		; get back value of address
	sta		TCB_npages,x
	lda		#0
brk5:
	bmt		PageMap			; test if page is free
	bne		brk4			; no, go for next page
	bms		PageMap			; allocate the page
	sta		MMU,r4			; store the page number in the MMU table
	add		r4,#1			; move to next MMU entry
	sub		r6,#1			; decrement count of needed
	beq		brk6			; we're done if count = 0
brk4:
	ina
	cmp		#2048
	blo		brk5

	; Here there was an OS or hardware error
	; According to mem_pages_free there should have been enough free pages
	; to fulfill the request. Something is corrupt.
	;

	; Here we are reducing the program break, which means freeing up pages of
	; memory.
brk1:
	sta		TCB_npages,x
	add		r5,r1,#1		; move to page after last page
brk7:
	cmp		r5,r4			; are we done freeing pages ?
	bhi		brk6
	lda		MMU,r5			; get the page to free
	bmc		PageMap			; free the page
	inc		mem_pages_free
	add		r5,#1
	bra		brk7

	; Successful return
brk6:
	pop		r6
	pop		r5
	pop		r4
	plx
	lda		#0
	rts

; Return insufficient memory error
;
brk2:
	lda		#E_NoMem
	sta		TCB_errno,x
	pop		r6
	pop		r5
	pop		r4
	plx
	lda		#-1
	rts

;------------------------------------------------------------------------------
; Parameters:
; r1 = change in memory allocation
;------------------------------------------------------------------------------
_sbrk:
	phx
	push	r4
	push	r5
	ldx		RunningTCB
	ld		r4,TCB_npages,x		; get the current memory allocation
	cmp		r1,#0				; zero difference = get old brk address
	beq		sbrk2
	asl		r5,r4,#14			; convert to words
	add		r1,r1,r5				; +/- amount
	jsr		_brk
	cmp		r1,#-1
	bne		sbrk2

; Failure return, return -1
;
	pop		r5
	pop		r4
	plx
	rts

; Successful return, return the old break address
;	
sbrk2:
	ld		r1,r4
	asl		r1,r1,#14
	pop		r5
	pop		r4
	plx
	rts


;------------------------------------------------------------------------------
; Parameters:
; r1 = virtual memory address
;------------------------------------------------------------------------------
;
FreeMemPage:
	php
	phx
	sei
	; First mark the page as available in the page map.
	pha
	jsr		VirtToPhys
	sub		r1,r1,#DRAM_BASE
	lsr		r1,r1,#14
	bmc		PageMap
	pla
	; Now mark the MMU slot as empty
	sub		r1,r1,#DRAM_BASE
	lsr		r1,r1,#14	; / 16kW r1 = page # now
	ldx		RunningTCB
	stx		MMU_AKEY
	tax
	lda		#INV_PAGE
	sta		MMU,x
	plx
	plp
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = pointer to memory
;------------------------------------------------------------------------------
;
FreeMemPages:
	php
	phx
	sei
	cmp		#0			; test for a proper pointer
	beq		fmp4
	; Turn the memory pointer into a bit index
	sub		r1,r1,#DRAM_BASE
	lsr		r1,r1,#14	; / 16kW
	cmp		#1919		; make sure index is sensible
	bhi		fmp4
fmp2:
	bmt		PageMap2	; Test to see if end of allocation
	bne		fmp3
	bmc		PageMap		; deallocate page
	ina
	cmp		#1919		; last 128 pages aren't freeanle
	bls		fmp2
fmp3
	; Clear the last bit
	bmc		PageMap
	bmc		PageMap2
fmp4:
	plx
	plp
	rts

;------------------------------------------------------------------------------
; Convert a virtual address to a physical address.
;------------------------------------------------------------------------------
VirtToPhys:
	phx
	php
	sei
	ldx		RunningTCB
	stx		MMU_AKEY
	sub		r1,r1,#DRAM_BASE
	lsr		r2,r1,#14	; convert to MMU index
	lda		MMU,x		; a = physical page#
	asl		r1,r1,#14	; *16kW
	add		r1,r1,#DRAM_BASE
	plp
	plx
	rts

;------------------------------------------------------------------------------
; PhysToVirt
;
; Convert a physical address to a virtual address. A little more complex
; than converting virtual to physical addresses as the MMU map table must
; be searched for the physcial page.
;
; Parameters:
;	r1 = physical address to translate
; Returns:
;	r1 = virtual address
;------------------------------------------------------------------------------
PhysToVirt:
	phx
	php
	sei
	ldx		RunningTCB
	stx		MMU_AKEY
	sub		r1,r1,#DRAM_BASE
	lsr		r1,r1,#14	; /16k to get index
	ldx		#0
ptv2:
	cmp		MMU,x
	beq		ptv1
	inx
	cpx		#512
	bne		ptv2
	; Return NULL pointer if address translation fails
	plp
	plx
	lda		#0
	rts
ptv1:
	asl		r1,r2,#14	; * 16k
	plp
	plx
	add		r1,r1,#DRAM_BASE
	rts

;------------------------------------------------------------------------------
; Bus Error Routine
; This routine display a message then restarts the BIOS.
;------------------------------------------------------------------------------
;
message "bus_err_rout"
bus_err_rout:
	cld
	ldx		#87
	stx		LEDS
	pla							; get rid of the stacked flags
	ply							; get the error PC
	ldx		#$05FFFFF8			; setup stack pointer top of memory
	txs
	ldx		#88
	stx		LEDS
	jsr		CRLF
	stz		RunningTCB
	stz		IOFocusNdx
	lda		#msgBusErr
	jsr		DisplayStringB
	tya
	jsr		DisplayWord			; display the originating PC address
	lda		#msgDataAddr
	jsr		DisplayStringB
	tsr		#9,r1
	jsr		DisplayWord
	ldx		#89
	stx		LEDS
	ldx		#128
ber2:
	lda		#' '
	jsr		DisplayChar
	tsr		hist,r1
	jsr		DisplayWord
	dex
	bne		ber2
	jsr		CRLF
ber3:
	nop
	jmp		ber3
	;cli							; enable interrupts so we can get a char
ber1:
	jsr		KeybdGetCharDirect	; Don't use the keyboard buffer
	cmp		#-1
	beq		ber1
	lda		RunningTCB
	jsr		KillTask
	jmp		SelectTaskToRun
	
msgBusErr:
	db		"Bus error at: ",0
msgDataAddr:
	db		" data address: ",0



;------------------------------------------------------------------------------
; 1000 Hz interrupt
; This IRQ must be fast.
; Increments the millisecond counter
;------------------------------------------------------------------------------
;
p1000Hz:
	pha
	lda		#2						; reset edge sense circuit
	sta		PIC_RSTE
	inc		Milliseconds			; increment milliseconds count
	pla
	rti

;------------------------------------------------------------------------------
; Sleep interrupt
; This interrupt just selects another task to run. The current task is
; stuck in an infinite loop.
;------------------------------------------------------------------------------
slp_rout:
	cld		; clear extended precision mode
	pusha
	lda		RunningTCB
	cmp		#MAX_TASKNO
	bhi		slp1
	jsr		RemoveTaskFromReadyList
	tax
	tsa						; save off the stack pointer
	sta		TCB_SPSave,x
	tsr		sp8,r1			; and the eight bit mode stack pointer
	sta		TCB_SP8Save,x
	tsr		abs8,r1
	sta		TCB_ABS8Save,x
	lda		#TS_SLEEP		; set the task status to SLEEP
	sta		TCB_Status,x
slp1:
	jmp		SelectTaskToRun

;------------------------------------------------------------------------------
; Check for and emulate unsupoorted instructions.
;------------------------------------------------------------------------------
InvalidOpIRQ:
	pha
	phx
	phy
	tsx
	lda		4,x		; get the address of the invalid op off the stack
	lb		r3,0,r1	; get the opcode byte
	cpy		#$44	; is it MVP ?
	beq		EmuMVP
	cpy		#$54	; is it MVN ?
	beq		EmuMVN
	; We don't know what the op is. Treat it like a NOP
	; Increment the address and return.
	pha
	lda		#msgUnimp
	jsr		DisplayStringB
	pla
	jsr		DisplayWord
	jsr		CRLF
	ina
	sta		4,x		; save incremented return address back to stack
	ldx		#64
ioi1:
	tsr		hist,r1
	jsr		DisplayWord
	lda		#' '
	jsr		DisplayChar
	dex
	bne		ioi1
	jsr		CRLF
	ply
	plx
	pla
	rti

EmuMVP:
	push	r4
	push	r5
	tsr		sp,r4
	lda		4,r4
	ldx		3,r4
	ldy		2,r4
EmuMVP1:
	ld		r5,(x)
	st		r5,(y)
	dex
	dey
	dea
	cmp		#$FFFFFFFF
	bne		EmuMVP1
	sta		4,r4
	stx		3,r4
	sty		2,r4
	inc		6,r4		; increment the return address by one.
	pop		r5
	pop		r4
	ply
	plx
	pla
	rti

EmuMVN:
	push	r4
	push	r5
	tsr		sp,r4
	lda		4,r4
	ldx		3,r4
	ldy		2,r4
EmuMVN1:
	ld		r5,(x)
	st		r5,(y)
	inx
	iny
	dea
	cmp		#$FFFFFFFF
	bne		EmuMVN1
	sta		4,r4
	stx		3,r4
	sty		2,r4
	inc		6,r4		; increment the return address by one.
	pop		r5
	pop		r4
	ply
	plx
	pla
	rti

msgUnimp:
	db	"Unimplemented at: ",0

brk_rout:
	lda		#16
	sta		LEDS
	jsr		kernel_panic
	db		"Break routine",0
	rti
nmirout:
	pha
	phx
	lda		#msgPerr
	jsr		DisplayStringB
	tsx
	lda		4,x
	jsr		DisplayWord
	jsr		CRLF
	plx
	pla
	rti

msgPerr:
	db	"Parity error at: ",0

;==============================================================================
; Finitron Multi-Tasking Kernel (FMTK)
;        __
;   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;==============================================================================
	org		$FFFFC000
	dw		MTKInitialize
	dw		StartTask
	dw		ExitTask
	dw		KillTask
	dw		SetTaskPriority
	dw		Sleep
	dw		AllocMbx
	dw		FreeMbx
	dw		PostMsg
	dw		SendMsg
	dw		WaitMsg
	dw		CheckMsg

	org		$FFFFC200
MTKInitialize:
	; Initialize semaphores
	lda		#1
	sta		freetcb_sema
	sta		freembx_sema
	sta		freemsg_sema
	sta		tcb_sema
	sta		readylist_sema
	sta		tolist_sema
	sta		mbx_sema
	sta		msg_sema

	tsr		vbr,r2
	and		r2,#-2
	lda		#reschedule
	sta		2,x
	lda		#MTKTick
	sta		448+3,x
	stz		UserTick

	lda		#-1
	sta		TimeoutList		; no entries in timeout list
	sta		QNdx0
	sta		QNdx1
	sta		QNdx2
	sta		QNdx3
	sta		QNdx4

	stz		missed_ticks

	; Initialize IO Focus List
	;
	lda		#7
	ldx		#0
	ldy		#IOFocusTbl
	stos

	lda		#255
	ldx		#-1
	ldy		#TCB_iof_next
	stos
	lda		#255
	ldx		#-1
	ldy		#TCB_iof_prev
	stos
	
	; Set owning job to zero
	lda		#255
	ldx		#0
	ldy		#TCB_hJCB
	stos

	; Initialize free message list
	lda		#NR_MSG
	sta		nMsgBlk
	stz		FreeMsg
	ldx		#0
	lda		#1
st4:
	sta		MSG_LINK,x
	ina
	inx
	cpx		#NR_MSG
	bne		st4
	lda		#-1
	sta		MBX_LINK+NR_MSG-1
	
	; Initialize free mailbox list
	; Note the first NR_TCB mailboxes are statically allocated to the tasks.
	; They are effectively pre-allocated.
	lda		#NR_MBX-NR_TCB
	sta		nMailbox
	
	ldx		#NR_TCB
	stx		FreeMbxHandle
	lda		#NR_TCB+1
st3:
	sta		MBX_LINK,x
	ina
	inx
	cpx		#NR_MBX
	bne		st3
	lda		#-1
	sta		MBX_LINK+NR_MBX-1

	; Initialize the FreeTCB list
	lda		#1				; the next available TCB
	sta		FreeTCB
	ldx		#1
	lda		#2
st2:
	sta		TCB_NxtTCB,x
	ina
	inx
	cpx		#256
	bne		st2
	lda		#-1
	sta		TCB_NxtTCB+255
	lda		#4
	sta		LEDS

	; Manually setup the BIOS task
	stz		RunningTCB		; BIOS is task #0
	stz		TCB_NxtRdy		; manually build the ready list
	stz		TCB_PrvRdy
	lda		#-1
	sta		TCB_NxtTo
	sta		TCB_PrvTo
	stz		QNdx2			; insert at priority 2
	stz		TCB_iof_next	; manually build the IO focus list
	stz		TCB_iof_prev
	stz		IOFocusNdx		; task #0 has the focus
	lda		#1
	sta		IOFocusTbl		; set the task#0 request bit
	lda		#PRI_NORMAL
	sta		TCB_Priority
	stz		TCB_Timeout
	lda		#TS_RUNNING|TS_READY
	sta		TCB_Status
	stz		TCB_CursorRow
	stz		TCB_CursorCol
	stz		TCB_ABS8Save
	ldx		#BIOS_STACKS+0x03FF	; setup stack pointer top of memory
	stx		TCB_SPSave
	ldx		#$1FF
	stx		TCB_SP8Save
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
StartIdleTask:
	lda		#4
	ldx		#0
	ldy		#IdleTask
	jsr		StartTask
	rts

;------------------------------------------------------------------------------
; IdleTask
;
; IdleTask is a low priority task that is always running. It runs when there
; is nothing else to run.
; This task check for tasks that are stuck in infinite loops and kills them.
;------------------------------------------------------------------------------
IdleTask:
	stz		TestTask
it2:
	inc		TEXTSCR+111		; increment IDLE active flag
	ldx		TestTask
	and		r2,r2,#$FF
	beq		it1
	lda		TCB_Status,x
	cmp		#TS_SLEEP
	bne		it1
	txa
	jsr		KillTask
it1:
	inc		TestTask
	cli						; enable interrupts
	wai						; wait for one to happen
	bra		it2

;------------------------------------------------------------------------------
; StartTask
;
; Startup a task. The task is automatically allocated a 1kW stack from the BIOS
; stacks area. The scheduler is invoked after the task is added to the ready
; list.
;
; Parameters:
;	r1 = task priority
;	r2 = start flags
;	r3 = start address
;	r4 = start parameter
;------------------------------------------------------------------------------
message "StartTask"
StartTask:
	pha
	phx
	phy
	push	r4
	push	r5
	push	r6
	push	r7
	push	r8
	push	r9
	ld		r6,r1				; r6 = task priority
	ld		r8,r2				; r8 = flag register value on startup
	
	; get a free TCB
	;
	spl		freetcb_sema+1
	lda		FreeTCB				; get free tcb list pointer
	bmi		stask1
	tax
	lda		TCB_NxtTCB,x
	sta		FreeTCB				; update the FreeTCB list pointer
	stz		freetcb_sema+1
;	GoReschedule
	lda		#81
	sta		LEDS
	txa							; acc = TCB index (task number)
	sta		TCB_mbx,x
	
	; setup the stack for the task
	; Zap the stack memory.
	ld		r7,r2
	asl		r2,r2,#10			; 1kW stack per task
	add		r2,r2,#BIOS_STACKS	;+0x3ff	; add in stack base
	pha
	phx
	phy
	txy							; y = target address
	ldx		#ExitTask			; x = fill value
	lda		#$3FF				; acc = # words to fill -1
	stos
	ply
	plx
	pla
	
	add		r2,r2,#$3FF			; Move pointer to top of stack
	tsr		sp,r9				; save off current stack pointer
	spl		tcb_sema + 1
	txs
	st		r6,TCB_Priority,r7
	stz		TCB_Status,r7
	stz		TCB_Timeout,r7
	; setup virtual video for the task
	stz		TCB_CursorRow,r7
	stz		TCB_CursorCol,r7
	stz		TCB_mmu_map,r7		; use mmu map
;	jsr		AllocateMemPage
	pha
	lda		#82
	sta		LEDS
	lda		#-1
	sta		TCB_MbxList,r7
	lda		BASIC_SESSION
	cmp		#1
	bls		stask3
	asl		r1,r1,#14
	add		r1,r1,#$430_0000
	sta		TCB_ABS8Save,r7
	add		r1,r1,#$1FF
	sta		TCB_SP8Save,r7
	bra		stask4
stask3:
	lda		#$1FF
	sta		TCB_SP8Save,r7
	stz		TCB_ABS8Save,r7
stask4:
	lda		#83
	sta		LEDS
	pla
;	tay

	; setup the initial stack image for the task
	; Cause a return to the ExitTask routine when the task does a 
	; final rts.
	; fake an IRQ call by stacking the return address and processor
	; flags on the stack
	ldx		#ExitTask			; save the address of the task exit routine
	phx
	phy							; save start address on stack
	push	r8					; save processor status reg on stack
	
	; now fake pushing the register set onto the stack. Registers start up
	; in an undefined state.
;	sub		sp,#15				; 15 registers
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	push	r4
	tsx
	stx		TCB_SPSave,r7
	; now restore the current stack pointer
	trs		r9,sp

	; Insert the task into the ready list
	ld		r4,#84
	st		r4,LEDS
	jsr		AddTaskToReadyList
	lda		#1
	sta		tcb_sema
;	GoReschedule		; invoke the scheduler
stask2:
	pop		r9
	pop		r8
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	ply
	plx
	lda		#85
	sta		LEDS
	pla
	rts
stask1:
	stz		freetcb_sema+1
	jsr		kernel_panic
	db		"No more task control blocks available.",0
	bra		stask2

;------------------------------------------------------------------------------
; ExitTask
;
; This routine is called when the task exits with an rts instruction. OR
; it may be invoked with a JMP ExitTask. In either case the task must be
; running so it can't be on the timeout list. The scheduler is invoked
; after the task is removed from the ready list.
;------------------------------------------------------------------------------
message "ExitTask"
ExitTask:
	; release any aquired resources
	; - mailboxes
	; - messages
	hoff
	spl		tcb_sema + 1
	lda		RunningTCB
	cmp		#MAX_TASKNO
	bhi		xtsk1
	jsr		RemoveTaskFromReadyList
	jsr		RemoveFromTimeoutList
	stz		TCB_Status,r1				; set task status to TS_NONE
	jsr		ReleaseIOFocus
;	lda		TCB_ABS8Save,x
;	jsr		FreeMemPage
	; Free up all the mailboxes associated with the task.
xtsk7:
	pha
	lda		TCB_MbxList,r1
	bmi		xtsk6
	jsr		FreeMbx
	pla
	bra		xtsk7
xtsk6:
	pla
	ldx		#86
	stx		LEDS
	spl		freetcb_sema+1
	ldx		FreeTCB						; add the task control block to the free list
	stx		TCB_NxtTCB,r1
	sta		FreeTCB
	stz		freetcb_sema+1
xtsk1:
	jmp		SelectTaskToRun

;------------------------------------------------------------------------------
; r1 = task number
; r2 = new priority
;------------------------------------------------------------------------------
;
SetTaskPriority:
	cmp		#MAX_TASKNO					; make sure task number is reasonable
	bhi		stp1
	phy
	spl		tcb_sema + 1
	ldy		TCB_Status,r1				; if the task is on the ready list
	bit		r3,#TS_READY|TS_RUNNING		; then remove it and re-add it.
	beq		stp2						; Otherwise just go set the priority field
	jsr		RemoveTaskFromReadyList
	stx		TCB_Priority,r1
	jsr		AddTaskToReadyList
	bra		stp3
stp2:
	stx		TCB_Priority,r1
stp3:
	ldy		#1
	sty		tcb_sema
	GoReschedule
	ply
stp1:
	rts

;------------------------------------------------------------------------------
; AddTaskToReadyList
;
; The ready list is a group of five ready lists, one for each priority
; level. Each ready list is organized as a doubly linked list to allow fast
; insertions and removals. The list is organized as a ring (or bubble) with
; the last entry pointing back to the first. This allows a fast task switch
; to the next task. Which task is at the head of the list is maintained
; in the variable QNdx for the priority level.
;
; Registers Affected: none
; Parameters:
;	r1 = task number
; Returns:
;	none
;------------------------------------------------------------------------------
;
message "AddTaskToReadyList"
AddTaskToReadyList:
	phx
	phy
	ldx		#TS_READY
	stx		TCB_Status,r1
	ldx		#-1
	stx		TCB_NxtRdy,r1
	stx		TCB_PrvRdy,r1
	ldy		TCB_Priority,r1
	cpy		#5
	blo		arl1
	ldy		#PRI_LOWEST
arl1:
	ldx		QNdx0,y
	bmi		arl5
	ldy		TCB_PrvRdy,x
	sta		TCB_NxtRdy,y
	sty		TCB_PrvRdy,r1
	sta		TCB_PrvRdy,x
	stx		TCB_NxtRdy,r1
	ply
	plx
	rts

	; Here the ready list was empty, so add at head
arl5:
	sta		QNdx0,y
	sta		TCB_NxtRdy,r1
	sta		TCB_PrvRdy,r1
	ply
	plx
	rts
	
;------------------------------------------------------------------------------
; RemoveTaskFromReadyList
;
; This subroutine removes a task from the ready list.
;
; Registers Affected: none
; Parameters:
;	r1 = task number
; Returns:
;   r1 = task number
;------------------------------------------------------------------------------

message "RemoveTaskFromReadyList"
RemoveTaskFromReadyList:
	phx
	phy
	push	r4
	push	r5

	ldy		TCB_Status,r1	; is the task on the ready list ?
	bit		r3,#TS_READY|TS_RUNNING
	beq		rfr2
	and		r3,r3,#~(TS_READY|TS_RUNNING)
	sty		TCB_Status,r1		; task status no longer running or ready
	ld		r4,TCB_NxtRdy,r1	; Get previous and next fields.
	ld		r5,TCB_PrvRdy,r1
	st		r4,TCB_NxtRdy,r5
	st		r5,TCB_PrvRdy,r4
	ldy		TCB_Priority,r1
	cmp		r1,QNdx0,y			; Are we removing the QNdx task ?
	bne		rfr2
	st		r4,QNdx0,y
	; Now we test for the case where the task being removed was the only one
	; on the ready list of that priority level. We can tell because the
	; NxtRdy would point to the task itself.
	cmp		r4,r1				
	bne		rfr2
	ldx		#-1					; Make QNdx negative
	stx		QNdx0,y
	stx		TCB_NxtRdy,r1
	stx		TCB_PrvRdy,r1
rfr2:
	pop		r5
	pop		r4
	ply
	plx
	rts

;------------------------------------------------------------------------------
; AddToTimeoutList
; AddToTimeoutList adds a task to the timeout list. The task is placed in the
; list depending on it's timeout value.
;
; Registers Affected: none
; Parameters:
;	r1 = task
;	r2 = timeout value
;------------------------------------------------------------------------------
message "AddToTimeoutList"
AddToTimeoutList:
	phx
	push	r4
	push	r5

	ld		r5,#-1
	st		r5,TCB_NxtTo,r1		; these fields should already be -1
	st		r5,TCB_PrvTo,r1
	ld		r4,TimeoutList		; are there any tasks on the timeout list ?
	bmi		attl_add_at_head	; If not, update head of list
attl_check_next:
	sub		r2,r2,TCB_Timeout,r4	; is this timeout > next
	bmi		attl_insert_before
	ld		r5,r4
	ld		r4,TCB_NxtTo,r4
	bpl		attl_check_next

	; Here we scanned until the end of the timeout list and didn't find a 
	; timeout of a greater value. So we add the task to the end of the list.
attl_add_at_end:
	st		r4,TCB_NxtTo,r1		; r4 is = -1
	st		r1,TCB_NxtTo,r5
	st		r5,TCB_PrvTo,r1
	stx		TCB_Timeout,r1
	bra		attl_exit

attl_insert_before:
	cmp		r5,#0
	bmi		attl_insert_before_head
	st		r4,TCB_NxtTo,r1		; next on list goes after this task
	st		r5,TCB_PrvTo,r1		; set previous link
	st		r1,TCB_NxtTo,r5
	st		r1,TCB_PrvTo,r4
	bra		attl_adjust_timeout

	; Here there is no previous entry in the timeout list
	; Add at start
attl_insert_before_head:
	sta		TCB_PrvTo,r4
	st		r5,TCB_PrvTo,r1		; r5 is = -1
	st		r4,TCB_NxtTo,r1
	sta		TimeoutList			; update the head pointer
attl_adjust_timeout:
	add		r2,r2,TCB_Timeout,r4	; get back timeout
	stx		TCB_Timeout,r1
	ld		r5,TCB_Timeout,r4	; adjust the timeout of the next task
	sub		r5,r5,r2
	st		r5,TCB_Timeout,r4
	bra		attl_exit

	; Here there were no tasks on the timeout list, so we add at the
	; head of the list.
attl_add_at_head:
	sta		TimeoutList			; set the head of the timeout list
	stx		TCB_Timeout,r1
	ldx		#-1					; flag no more entries in timeout list
	stx		TCB_NxtTo,r1		; no next entries
	stx		TCB_PrvTo,r1		; and no prev entries
attl_exit:
	ldx		TCB_Status,r1		; set the task's status as timing out
	or		r2,r2,#TS_TIMEOUT
	stx		TCB_Status,r1
	pop		r5
	pop		r4
	plx
	rts
	
;------------------------------------------------------------------------------
; RemoveFromTimeoutList
;
; This routine is called when a task is killed. The task may need to be
; removed from the middle of the timeout list.
;
; On entry: the timeout list semaphore must be already set.
; Registers Affected: none
; Parameters:
;	 r1 = task number
;------------------------------------------------------------------------------
message "RemoveFromTimeoutList"
RemoveFromTimeoutList:
	cmp		#MAX_TASKNO
	bhi		rftl_not_on_list2
	phx
	push	r4
	push	r5

	ld		r4,TCB_Status,r1		; Is the task even on the timeout list ?
	bit		r4,#TS_TIMEOUT
	beq		rftl_not_on_list
	cmp		TimeoutList				; Are we removing the head of the list ?
	beq		rftl_remove_from_head
	ld		r4,TCB_PrvTo,r1			; adjust the links of the next and previous
	bmi		rftl_empty_list			; no previous link - list corrupt?
	ld		r5,TCB_NxtTo,r1			; tasks on the list to point around the task
	st		r5,TCB_NxtTo,r4
	bmi		rftl_empty_list
	st		r4,TCB_PrvTo,r5
	ldx		TCB_Timeout,r1			; update the timeout of the next on list
	add		r2,r2,TCB_Timeout,r5	; with any remaining timeout in the task
	stx		TCB_Timeout,r5			; removed from the list
	bra		rftl_empty_list

	; Update the head of the list.
rftl_remove_from_head:
	ld		r5,TCB_NxtTo,r1
	st		r5,TimeoutList			; store next field into list head
	bmi		rftl_empty_list
	ld		r4,TCB_Timeout,r1		; add any remaining timeout to the timeout
	add		r4,r4,TCB_Timeout,r5	; of the next task on the list.
	st		r4,TCB_Timeout,r5
	ld		r4,#-1					; there is no previous item to the head
	sta		TCB_PrvTo,r5
	
	; Here there is no previous or next items in the list, so the list
	; will be empty once this task is removed from it.
rftl_empty_list:
	tax
	lda		#0					; clear timeout status (bit #0)
	bmc		TCB_Status,x
	dea							; acc=-1; make sure the next and prev fields indicate
	sta		TCB_NxtTo,x			; the task is not on a list.
	sta		TCB_PrvTo,x
	txa
rftl_not_on_list:
	pop		r5
	pop		r4
	plx
rftl_not_on_list2:
	rts

;------------------------------------------------------------------------------
; PopTimeoutList
;
; This subroutine is called from within the timer ISR when the task's 
; timeout expires. It's always the head of the list that's being removed in
; the timer ISR so the removal from the timeout list is optimized. We know
; the timeout expired, so the amount of time to add to the next task is zero.
;	This routine is written as a macro since it's only called from one place.
; This routine is inlined. Implementing it as a macro increases performance.
;
; Registers Affected: acc, x, y, flags
; Parameters:
;	x: head of timeout list
; Returns:
;	r1 = task id of task popped from timeout list
;------------------------------------------------------------------------------
;
message "PopTimeoutList"
macro PopTimeoutList
	ldy		#-1
	lda		TCB_NxtTo,x
	sta		TimeoutList		; store next field into list head
	bmi		ptl1
	sty		TCB_PrvTo,r1	; previous link = -1
ptl1:
	lda		#0				; clear timeout status
	bmc		TCB_Status,x
	sty		TCB_NxtTo,x		; make sure the next and prev fields indicate
	sty		TCB_PrvTo,x		; the task is not on a list.
	txa
endm

;------------------------------------------------------------------------------
; Sleep
;
; Put the currently running task to sleep for a specified time.
;
; Registers Affected: none
; Parameters:
;	r1 = time duration in centi-seconds (1/100 second).
; Returns: none
;------------------------------------------------------------------------------
;
Sleep:
	pha
	phx
	tax
	spl		tcb_sema + 1
	lda		RunningTCB
	jsr		RemoveTaskFromReadyList
	jsr		AddToTimeoutList	; The scheduler will be returning to this
	lda		#1
	sta		tcb_sema
	GoReschedule				; task eventually, once the timeout expires,
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Short delay routine.
;	This routine works by reading the tick register. When a subsequent read
; of the tick register exceeds the value of the original read by at least
; the value passed as a parameter, then this routine returns.
;	The tick register increments at the clock rate (eg 25 MHz).
;------------------------------------------------------------------------------
;
short_delay:
	phx
	phy
	tsr		tick,r2
usec1:
	tsr		tick,r3
	sub		r3,r3,r2
	cmp		r1,r3
	blo		usec1
	ply
	plx
	rts

;------------------------------------------------------------------------------
; KillTask
;
; "Kills" a task, removing it from all system lists. If the task has the 
; IO focus, the IO focus is switched. Task #0 is immortal and cannot be
; killed.
;
; Registers Affected: none
; Parameters:
;	r1 = task number
;------------------------------------------------------------------------------
;
KillTask:
	phx
	cmp		#1							; BIOS task and IDLE task are immortal
	bls		kt1
	cmp		#MAX_TASKNO
	bhi		kt1
	jsr		ForceReleaseIOFocus
	spl		tcb_sema + 1
	jsr		RemoveTaskFromReadyList
	jsr		RemoveFromTimeoutList
	stz		TCB_Status,r1				; set task status to TS_NONE

	; Free up all the mailboxes associated with the task.
kt7:
	pha
	tax
	lda		TCB_MbxList,r1
	bmi		kt6
	jsr		FreeMbx2
	pla
	bra		kt7
kt6:
	lda		#1
	sta		tcb_sema
	pla

	spl		freetcb_sema + 1
	ldx		FreeTCB						; add the task control block to the free list
	stx		TCB_NxtTCB,r1
	sta		FreeTCB
	stz		freetcb_sema + 1
	cmp		RunningTCB					; keep running the current task as long as
	bne		kt1							; the task didn't kill itself.
	GoReschedule						; invoke scheduler to reschedule tasks
kt1:
	plx
	rts

;------------------------------------------------------------------------------
; Allocate a mailbox
; Parameters:
;	r1 = pointer to place to store handle
; Returns:
;	r1 = E_Ok	means mailbox allocated properly
;	r1 = E_Arg	means a NULL pointer was passed in r1
;	r1 = E_NoMoreMbx	means no more mailboxes were available
;	zf is set if everything is ok, otherwise zf is clear
;------------------------------------------------------------------------------
;
message "AllocMbx"
AllocMbx:
	cmp		#0
	beq		ambx_bad_ptr
	phx
	phy
	push	r4
	ld		r4,r1			; r4 = pointer to returned handle
	spl		freembx_sema + 1
	lda		FreeMbxHandle			; Get mailbox off of free mailbox list
	sta		(r4)			; store off the mailbox number
	bmi		ambx_no_mbxs
	ldx		MBX_LINK,r1		; and update the head of the list
	stx		FreeMbxHandle
	dec		nMailbox		; decrement number of available mailboxes
	stz		freembx_sema + 1
	spl		tcb_sema + 1
	ldy		RunningTCB		; Add the mailbox to the list of mailboxes
	ldx		TCB_MbxList,y	; managed by the task.
	stx		MBX_LINK,r1
	sta		TCB_MbxList,y
	tax
	ldy		RunningTCB			; set the mailbox owner
;	bmi		RunningTCBErr
	lda		TCB_hJCB,y
	stz		tcb_sema + 1

	spl		mbx_sema + 1
	sta		MBX_OWNER,x
	lda		#-1				; initialize the head and tail of the queues
	sta		MBX_TQ_HEAD,x
	sta		MBX_TQ_TAIL,x
	sta		MBX_MQ_HEAD,x
	sta		MBX_MQ_TAIL,x
	stz		MBX_TQ_COUNT,x	; initialize counts to zero
	stz		MBX_MQ_COUNT,x
	stz		MBX_MQ_MISSED,x
	lda		#8				; set the max queue size
	sta		MBX_MQ_SIZE,x	; and
	lda		#MQS_NEWEST		; queueing strategy
	sta		MBX_MQ_STRATEGY,x
	stz		mbx_sema + 1
	pop		r4
	ply
	plx
	lda		#E_Ok
	rts
ambx_bad_ptr:
	lda		#E_Arg
	rts
ambx_no_mbxs:
	stz		freembx_sema + 1
	pop		r4
	ply
	plx
	lda		#E_NoMoreMbx
	rts

;------------------------------------------------------------------------------
; Free up a mailbox.
;	This function frees a mailbox from the currently running task. It may be
; called by ExitTask().
;
; Parameters:
;	r1 = mailbox handle
;------------------------------------------------------------------------------
;
FreeMbx:
	phx
	ldx		RunningTCB
	jsr		FreeMbx2
	plx
	rts

;------------------------------------------------------------------------------
; Free up a mailbox.
;	This function dequeues any messages from the mailbox and adds the messages
; back to the free message pool. The function also dequeues any threads from
; the mailbox.
;	Called from KillTask() and FreeMbx().
;
; Parameters:
;	r1 = mailbox handle
;	r2 = task handle
; Returns:
;	r1 = E_Ok	if everything ok
;	r1 = E_Arg	if a bad handle is passed
;------------------------------------------------------------------------------
;
FreeMbx2:
	cmp		#NR_MBX				; check mailbox handle parameter
	bhs		fmbx1
	cpx		#MAX_TASKNO
	bhi		fmbx1
	phx
	phy
	spl		mbx_sema + 1

	; Dequeue messages from mailbox and add them back to the free message list.
fmbx5:
	pha
	jsr		DequeueMsgFromMbx
	bmi		fmbx3
	spl		freemsg_sema + 1
	phx
	ldx		FreeMsg
	stx		MSG_LINK,r1
	sta		FreeMsg
	stz		freemsg_sema + 1
	plx
	pla
	bra		fmbx5
fmbx3:
	pla

	; Dequeue threads from mailbox.
fmbx6:
	pha
	jsr		DequeueThreadFromMbx2
	bmi		fmbx7
	pla
	bra		fmbx6
fmbx7:
	pla

	; Remove mailbox from TCB list
	ldy		TCB_MbxList,x
	phx
	ldx		#-1
fmbx10:
	cmp		r1,r3
	beq		fmbx9
	tyx
	ldy		MBX_LINK,y
	bpl		fmbx10
	; ?The mailbox was not in the list managed by the task.
	plx
	bra		fmbx2
fmbx9:
	cmp		r2,r0
	bmi		fmbx11
	ldy		MBX_LINK,y
	sty		MBX_LINK,x
	plx
	bra		fmbx12
fmbx11:
	; No prior mailbox in list, update head
	ldy		MBX_LINK,r1
	plx
	sty		TCB_MbxList,x

fmbx12:
	; Add mailbox back to mailbox pool
	spl		freembx_sema + 1
	ldx		FreeMbxHandle
	stx		MBX_LINK,r1
	sta		FreeMbxHandle
	stz		freembx_sema + 1
fmbx2:
	stz		mbx_sema + 1
	ply
	plx
	lda		#E_Ok
	rts
fmbx1:
	lda		#E_Arg
	rts

;------------------------------------------------------------------------------
; Queue a message at a mailbox.
; On entry the mailbox semaphore is already activated.
;
; Parameters:
;	r1 = message
;	r2 = mailbox
;------------------------------------------------------------------------------
message "QueueMsgAtMbx"
QueueMsgAtMbx:
	cmp		#0
	beq		qmam_bad_msg
	pha
	phx
	phy
	push	r4
	ld		r4,MBX_MQ_STRATEGY,x
	cmp		r4,#MQS_UNLIMITED
	beq		qmam_unlimited
	cmp		r4,#MQS_NEWEST
	beq		qmam_newest
	cmp		r4,#MQS_OLDEST
	beq		qmam_oldest
	jsr		kernel_panic
	db		"Illegal message queue strategy",0
	bra		qmam8
	; Here we assumed "unlimited" message storage. Just add the new message at
	; the tail of the queue.
qmam_unlimited:
	ldy		MBX_MQ_TAIL,x
	bmi		qmam_add_at_head
	sta		MSG_LINK,y
	bra		qmam2
qmam_add_at_head:
	sta		MBX_MQ_HEAD,x
qmam2:
	sta		MBX_MQ_TAIL,x
qmam6:
	inc		MBX_MQ_COUNT,x		; increase the queued message count
	ldx		#-1
	stx		MSG_LINK,r1
	pop		r4
	ply
	plx
	pla
qmam_bad_msg:
	rts
	; Here we are queueing a limited number of messages. As new messages are
	; added at the tail of the queue, messages drop off the head of the queue.
qmam_newest:
	ldy		MBX_MQ_TAIL,x
	bmi		qmam3
	sta		MSG_LINK,y
	bra		qmam4
qmam3:
	sta		MBX_MQ_HEAD,x
qmam4:
	sta		MBX_MQ_TAIL,x
	ldy		MBX_MQ_COUNT,x
	iny
	cmp		r3,MBX_MQ_SIZE,x
	bls		qmam6
	ldy		#-1
	sty		MSG_LINK,r1
	; Remove the oldest message which is the one at the head of the mailbox queue.
	; Add the message back to the pool of free messages.
	lda		MBX_MQ_HEAD,x
	ldy		MSG_LINK,r1			; move next in queue
	sty		MBX_MQ_HEAD,x		; to head of list
qmam8:
	inc		MBX_MQ_MISSED,x
qmam1:
	spl		freemsg_sema + 1
	ldy		FreeMsg				; put old message back into free message list
	sty		MSG_LINK,r1
	sta		FreeMsg
	inc		nMsgBlk
	stz		freemsg_sema + 1
	GoReschedule
	pop		r4
	ply
	plx
	pla
	rts
	; Here we are buffering the oldest messages. So if there are too many messages
	; in the queue already, then the queue doesn't change and the new message is
	; lost.
qmam_oldest:
	ldy		MBX_MQ_COUNT,x		; Check if the queue is full
	cmp		r3,MBX_MQ_SIZE,x
	bhs		qmam8				; If the queue is full, then lose the current message
	bra		qmam_unlimited		; Otherwise add message to queue

;------------------------------------------------------------------------------
; Dequeue a message from a mailbox.
;
; Returns
;	r1 = message number
;	nf set if there is no message, otherwise clear
;------------------------------------------------------------------------------
message "DequeueMsgFromMbx"
DequeueMsgFromMbx:
	phx
	phy
	tax						; x = mailbox index
	lda		MBX_MQ_COUNT,x		; are there any messages available ?
	beq		dmfm3
	dea
	sta		MBX_MQ_COUNT,x		; update the message count
	lda		MBX_MQ_HEAD,x		; Get the head of the list, this should not be -1
	bmi		dmfm3			; since the message count > 0
	ldy		MSG_LINK,r1		; get the link to the next message
	sty		MBX_MQ_HEAD,x		; update the head of the list
	bpl		dmfm2			; if there was no more messages then update the
	sty		MBX_MQ_TAIL,x		; tail of the list as well.
dmfm2:
	sta		MSG_LINK,r1		; point the link to the messahe itself to indicate it's dequeued
dmfm1:
	ply
	plx
	cmp		#0
	rts
dmfm3:
	ply
	plx
	lda		#-1
	rts

;------------------------------------------------------------------------------
; Parameters:
;	r1 = mailbox handle
; Returns:
;	r1 = E_arg		means pointer is invalid
;	r1 = E_NoThread	means no thread was queued at the mailbox
;	r2 = thead handle
;------------------------------------------------------------------------------
message "DequeueThreadFromNbx"
DequeueThreadFromMbx:
	push	r4
	ld		r4,MBX_TQ_HEAD,r1
	bpl		dtfm2
	pop		r4
	ldx		#-1
	lda		#E_NoThread
	rts
dtfm2:
	push	r5
	dec		MBX_TQ_COUNT,r1
	ld		r2,r4
	ld		r4,TCB_mbq_next,r4
	st		r4,MBX_TQ_HEAD,r1
	bmi		dtfm3
		ld		r5,#-1
		st		r5,TCB_mbq_prev,r4
		bra		dtfm4
dtfm3:
		ld		r5,#-1
		st		r5,MBX_TQ_TAIL,r1
dtfm4:
;	stz		MBX_SEMA+1
	ld		r5,r2
	lda		TCB_Status,r5
	bit		#TS_TIMEOUT
	beq		dtfm5
	ld		r1,r5
	jsr		RemoveFromTimeoutList
dtfm5:
	ld		r4,#-1
	st		r4,TCB_mbq_next,r5
	st		r4,TCB_mbq_prev,r5
	stz		TCB_hWaitMbx,r5
	stz		TCB_Status,r5		; set task status = TS_NONE
	pop		r5
	pop		r4
	lda		#E_Ok
	rts

;------------------------------------------------------------------------------
;	This function is called from FreeMbx(). It dequeues threads from the
; mailbox without removing the thread from the timeout list. The thread will
; then timeout waiting for a message that can never be delivered.
;
; Parameters:
;	r1 = mailbox handle
; Returns:
;	r1 = E_arg		means pointer is invalid
;	r1 = E_NoThread	means no thread was queued at the mailbox
;	r2 = thead handle
;------------------------------------------------------------------------------
message "DequeueThreadFromNbx2"
DequeueThreadFromMbx2:
	push	r4
	ld		r4,MBX_TQ_HEAD,r1
	bpl		dtfm2a
	pop		r4
	ldx		#-1
	lda		#E_NoThread
	rts
dtfm2a:
	push	r5
	dec		MBX_TQ_COUNT,r1
	ld		r2,r4
	ld		r4,TCB_mbq_next,r4
	st		r4,MBX_TQ_HEAD,r1
	bmi		dtfm3a
		ld		r5,#-1
		st		r5,TCB_mbq_prev,r4
		bra		dtfm4a
dtfm3a:
		ld		r5,#-1
		st		r5,MBX_TQ_TAIL,r1
dtfm4a:
	ld		r4,#-1
	st		r4,TCB_mbq_next,x
	st		r4,TCB_mbq_prev,x
	stz		TCB_hWaitMbx,x
	sei
	lda		#TS_WAITMSG_BIT
	bmc		TCB_Status,x
	cli
	pop		r5
	pop		r4
	lda		#E_Ok
	rts

;------------------------------------------------------------------------------
; PostMsg and SendMsg are the same operation except that PostMsg doesn't
; invoke rescheduling while SendMsg does. So they both call the same
; SendMsgPrim primitive routine. This two wrapper functions for convenience.
;------------------------------------------------------------------------------
;
PostMsg:
	push	r4
	ld		r4,#0			; Don't invoke scheduler
	jsr		SendMsgPrim
	pop		r4
	rts

SendMsg:
	push	r4
	ld		r4,#1			; Do invoke scheduler
	jsr		SendMsgPrim
	pop		r4
	rts

;------------------------------------------------------------------------------
; SendMsgPrim
; Send a message to a mailbox
;
; Parameters
;	r1 = handle to mailbox
;	r2 = message D1
;	r3 = message D2
;	r4 = scheduler flag		1=invoke,0=don't invoke
;
; Returns
;	r1=E_Ok			everything is ok
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r1=E_NoMsg		if there are no more message blocks available
;	zf is set if everything is okay, otherwise zf is clear
;------------------------------------------------------------------------------
message "SendMsgPrim"
SendMsgPrim:
	cmp		#NR_MBX					; check the mailbox number to make sure
	bhs		smsg1					; that it's sensible
	push	r5
	push	r6
	push	r7

	spl		mbx_sema + 1
	ld		r7,MBX_OWNER,r1
	bmi		smsg2					; error: no owner
	pha
	phx
	jsr		DequeueThreadFromMbx	; r1=mbx
	ld		r6,r2					; r6 = thread
	plx
	pla
	cmp		r6,#0
	bpl		smsg3
		; Here there was no thread waiting at the mailbox, so a message needs to
		; be allocated
smp2:
		spl		freemsg_sema + 1
		ld		r7,FreeMsg
		bmi		smsg4		; no more messages available
		ld		r5,MSG_LINK,r7
		st		r5,FreeMsg
		dec		nMsgBlk		; decrement the number of available messages
		stz		freemsg_sema + 1
		stx		MSG_D1,r7
		sty		MSG_D2,r7
		pha
		phx
		tax						; x = mailbox
		ld		r1,r7			; acc = message
		jsr		QueueMsgAtMbx
		plx
		pla
		cmp		r6,#0			; check if there is a thread waiting for a message
		bmi		smsg5
smsg3:
	stx		TCB_MSG_D1,r6
	sty		TCB_MSG_D2,r6
smsg7:
	spl		tcb_sema + 1
	ld		r5,TCB_Status,r6
	bit		r5,#TS_TIMEOUT
	beq		smsg8
	ld		r1,r6
	jsr		RemoveFromTimeoutList
smsg8:
	lda		#TS_WAITMSG_BIT
	bmc		TCB_Status,r6
	lda		#1
	sta		tcb_sema
	ld		r1,r6
	spl		tcb_sema + 1
	jsr		AddTaskToReadyList
	stz		tcb_sema + 1
	cmp		r4,#0
	beq		smsg5
	stz		mbx_sema + 1
	GoReschedule
	bra		smsg9
smsg5:
	stz		mbx_sema + 1
smsg9:
	pop		r7
	pop		r6
	pop		r5
	lda		#E_Ok
	rts
smsg1:
	lda		#E_BadMbx
	rts
smsg2:
	stz		mbx_sema + 1
	pop		r7
	pop		r6
	pop		r5
	lda		#E_NotAlloc
	rts
smsg4:
	stz		freemsg_sema + 1
	stz		mbx_sema + 1
	pop		r7
	pop		r6
	pop		r5
	lda		#E_NoMsg
	rts

;------------------------------------------------------------------------------
; WaitMsg
; Wait at a mailbox for a message to arrive. This subroutine will block the
; task until a message is available or the task times out on the timeout
; list.
;
; Parameters
;	r1=mailbox
;	r2=timeout
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------
message "WaitMsg"
WaitMsg:
	cmp		#NR_MBX				; check the mailbox number to make sure
	bhs		wmsg1				; that it's sensible
	push	r4
	push	r5
	push	r6
	push	r7
	ld		r6,r1
wmsg11:
	spl		mbx_sema + 1
	ld		r5,MBX_OWNER,r1
	cmp		r5,#MAX_TASKNO
	bhi		wmsg2					; error: no owner
	jsr		DequeueMsgFromMbx
;	cmp		#0
	bpl		wmsg3

	; Here there was no message available, remove the task from
	; the ready list, and optionally add it to the timeout list.
	; Queue the task at the mailbox.
wmsg12:
	spl		tcb_sema + 1
	lda		RunningTCB				; remove the task from the ready list
	jsr		RemoveTaskFromReadyList
	stz		tcb_sema + 1
wmsg13:
	spl		tcb_sema + 1
	ld		r7,TCB_Status,r1
	or		r7,r7,#TS_WAITMSG			; set task status to waiting
	st		r7,TCB_Status,r1
	st		r6,TCB_hWaitMbx,r1			; set which mailbox is waited for
	ld		r7,#-1
	st		r7,TCB_mbq_next,r1			; adding at tail, so there is no next
	ld		r7,MBX_TQ_HEAD,r6			; is there a task que setup at the mailbox ?
	bmi		wmsg6
	ld		r7,MBX_TQ_TAIL,r6
	st		r7,TCB_mbq_prev,r1
	sta		TCB_mbq_next,r7
	sta		MBX_TQ_TAIL,r6
	inc		MBX_TQ_COUNT,r6				; increment number of tasks queued
wmsg7:
	stz		tcb_sema + 1
	stz		mbx_sema + 1
	cmp		r2,#0						; check for a timeout
	beq		wmsg10
wmsg14:
	spl		tcb_sema + 1
	jsr		AddToTimeoutList
	stz		tcb_sema + 1
	GoReschedule			; invoke the scheduler
wmsg10:
	; At this point either a message was sent to the task, or the task
	; timed out. If a message is still not available then the task must
	; have timed out. Return a timeout error.
	; Note that SendMsg will directly set the message D1, D2 data
	; without queing a message at the mailbox (if there is a task
	; waiting already). So we cannot just try dequeing a message again.
	ldx		TCB_MSG_D1,r1
	ldy		TCB_MSG_D2,r1
	ld		r4,TCB_Status,r1
	bit		r4,#TS_WAITMSG	; Is the task still waiting for a message ?
	beq		wmsg8			; If not, go return OK status
	pop		r7				; Otherwise return timeout error
	pop		r6
	pop		r5
	pop		r4
	lda		#E_Timeout
	rts
	
	; Here there were no prior tasks queued at the mailbox
wmsg6:
	ld		r7,#-1
	st		r7,TCB_mbq_prev,r1		; no previous tasks
	st		r7,TCB_mbq_next,r1
	sta		MBX_TQ_HEAD,r6			; set both head and tail indexes
	sta		MBX_TQ_TAIL,r6
	ld		r7,#1
	st		r7,MBX_TQ_COUNT,r6		; one task queued
	bra		wmsg7					; check for a timeout value
	
wmsg3:
	stz		mbx_sema + 1
	ldx		MSG_D1,r1
	ldy		MSG_D2,r1
	; Add the newly dequeued message to the free messsage list
wmsg5:
	spl		freemsg_sema + 1
	ld		r7,FreeMsg
	st		r7,MSG_LINK,r1
	sta		FreeMsg
	inc		nMsgBlk
	stz		freemsg_sema + 1
wmsg8:
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	lda		#E_Ok
	rts
wmsg1:
	lda		#E_BadMbx
	rts
wmsg2:
	stz		mbx_sema + 1
	pop		r7
	pop		r6
	pop		r5
	pop		r4
	lda		#E_NotAlloc
	rts

;------------------------------------------------------------------------------
; Check for a message at a mailbox. Does not block. This function is a
; convenience wrapper for CheckMsg().
;
; Parameters
;	r1=mailbox handle
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_NoMsg		if no message is available
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------
;
PeekMsg:
	ld		r2,#0		; don't remove from queue
	jsr		CheckMsg
	rts

;------------------------------------------------------------------------------
; CheckMsg
; Check for a message at a mailbox. Does not block.
;
; Parameters
;	r1=mailbox handle
;	r2=remove from queue if present
; Returns:
;	r1=E_Ok			if everything is ok
;	r1=E_NoMsg		if no message is available
;	r1=E_BadMbx		for a bad mailbox number
;	r1=E_NotAlloc	for a mailbox that isn't allocated
;	r2=message D1
;	r3=message D2
;------------------------------------------------------------------------------
CheckMsg:
	cmp		#NR_MBX					; check the mailbox number to make sure
	bhs		cmsg1					; that it's sensible
	push	r4
	push	r5

	spl		mbx_sema + 1
	ld		r5,MBX_OWNER,r1
	bmi		cmsg2					; error: no owner
	cpx		#0						; are we to dequeue the message ?
	php
	beq		cmsg3
	jsr		DequeueMsgFromMbx
	bra		cmsg4
cmsg3:
	lda		MBX_MQ_HEAD,r1			; peek the message at the head of the messages queue
cmsg4:
	cmp		#0
	bmi		cmsg5
	ldx		MSG_D1,r1
	ldy		MSG_D2,r1
	plp								; get back dequeue flag
	beq		cmsg8
cmsg10:
	spl		freemsg_sema + 1
	ld		r5,FreeMsg
	st		r5,MSG_LINK,r1
	sta		FreeMsg
	inc		nMsgBlk
	stz		freemsg_sema + 1
cmsg8:
	stz		mbx_sema + 1
	pop		r5
	pop		r4
	lda		#E_Ok
	rts
cmsg1:
	lda		#E_BadMbx
	rts
cmsg2:
	stz		mbx_sema + 1
	pop		r5
	pop		r4
	lda		#E_NotAlloc
	rts
cmsg5:
	stz		mbx_sema + 1
	pop		r5
	pop		r4
	lda		#E_NoMsg
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
comment ~
SetIOFocusBit:
	and		r2,r2,#$FF
	and		r1,r2,#$1F		; get bit index 0 to 31
	ldy		#1
	asl		r3,r3,r1		; shift bit to proper place
	lsr		r2,r2,#5		; get word index /32 bits per word
	lda		IOFocusTbl,x
	or		r1,r1,r3
	sta		IOFocusTbl,x
	rts
~
;------------------------------------------------------------------------------
; The I/O focus list is an array indicating which tasks are requesting the
; I/O focus. The I/O focus is user controlled by pressing ALT-TAB on the
; keyboard.
;------------------------------------------------------------------------------
message "RequestIOFocus"
RequestIOFocus:
	pha
	phx
	phy
	DisTmrKbd
	ldx		RunningTCB	
	cpx		#MAX_TASKNO
	bhi		riof1
	ldy		IOFocusNdx		; Is the focus list empty ?
	bmi		riof2
riof4:
	lda		TCB_iof_next,x	; is the task already in the IO focus list ?
	bpl		riof3
	lda		IOFocusNdx		; Expand the list
	ldy		TCB_iof_prev,r1
	stx		TCB_iof_prev,r1
	sta		TCB_iof_next,x
	sty		TCB_iof_prev,x
	stx		TCB_iof_next,y
riof3:
	txa
	bms		IOFocusTbl
;	jsr		SetIOFocusBit
riof1:
	EnTmrKbd
	ply
	plx
	pla
	rts

	; Here, the IO focus list was empty. So expand it.
	; Update pointers to loop back to self.
riof2:
	stx		IOFocusNdx
	stx		TCB_iof_next,x
	stx		TCB_iof_prev,x
	bra		riof3

;------------------------------------------------------------------------------
; Releasing the I/O focus causes the focus to switch if the running task
; had the I/O focus.
; ForceReleaseIOFocus forces the release of the IO focus for a task
; different than the one currently running.
;------------------------------------------------------------------------------
;
message "ForceReleaseIOFocus"
ForceReleaseIOFocus:
	pha
	phx
	phy
	tax
	DisTmrKbd
	jmp		rliof4
message "ReleaseIOFocus"	
ReleaseIOFocus:
	pha
	phx
	phy
	DisTmrKbd
	ldx		RunningTCB	
rliof4:
	cpx		#MAX_TASKNO
	bhi		rliof3
;	phx	
	ldy		#1
	txa
	bmt		IOFocusTbl
	beq		rliof3
	bmc		IOFocusTbl
comment ~
	and		r1,r2,#$1F		; get bit index 0 to 31
	asl		r3,r3,r1		; shift bit to proper place
	eor		r3,#-1			; invert bit mask
	lsr		r2,r2,#5		; get word index /32 bits per word
	lda		IOFocusTbl,x
	and		r1,r1,r3
	sta		IOFocusTbl,x
~
;	plx
	cpx		IOFocusNdx		; Does the running task have the I/O focus ?
	bne		rliof1
	jsr		SwitchIOFocus	; If so, then switch the focus.
rliof1:
	lda		TCB_iof_next,x	; get next and previous fields.
	bmi		rliof2			; Is the task on the list ?
	ldy		TCB_iof_prev,x
	sta		TCB_iof_next,y	; prev->next = current->next
	sty		TCB_iof_prev,r1	; next->prev = current->prev
	cmp		r1,r3			; Check if the IO focus list is collapsing.
	bne		rliof2			; If the list just points back to the task
	cmp		r1,r2			; being removed, then it's the last task
	bne		rliof2			; removed from the list, so the list is being
	lda		#-1				; emptied.
	sta		IOFocusNdx
rliof2:
	lda		#-1				; Update the next and prev fields to indicate
	sta		TCB_iof_next,x	; the task is no longer on the list.
	sta		TCB_iof_prev,x
rliof3:
	EnTmrKbd
	ply
	plx
	pla
	rts

;------------------------------------------------------------------------------
; Spinlock interrupt
;	Go reschedule tasks if a spinlock is taking too long.
;------------------------------------------------------------------------------
;
spinlock_irq:
	cli
	ld		r0,tcb_sema + 1
	beq		spi1
	cld
	pusha
	bra		resched1	
spi1:
	rti

;------------------------------------------------------------------------------
; Reschedule tasks to run without affecting the timeout list timing.
;------------------------------------------------------------------------------
;
reschedule:
	cli		; enable interrupts
	cld		; clear extended precision mode

	pusha	; save off regs on the stack
	spl		tcb_sema + 1
resched1:
	ldx		RunningTCB
	tsa						; save off the stack pointer
	sta		TCB_SPSave,x
	tsr		sp8,r1			; and the eight bit mode stack pointer
	sta		TCB_SP8Save,x
	tsr		abs8,r1
	sta		TCB_ABS8Save,x	; 8 bit emulation base register
	lda		#3				; clear RUNNING status (bit #3)
	bmc		TCB_Status,x
	jmp		SelectTaskToRun


strStartQue:
	db		0,0,0,1,0,0,0,2,0,1,0,3,0,0,0,4
;	db		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;------------------------------------------------------------------------------
; 100 Hz interrupt
; - takes care of "flashing" the cursor
; - decrements timeouts for tasks on timeout list
; - switching tasks
;------------------------------------------------------------------------------
;
MTKTick:
	pha
	lda		#3				; reset the edge sense circuit
	sta		PIC_RSTE
	pla
	inc		IRQFlag
	; Try and aquire the ready list and tcb. If unsuccessful it means there is
	; a system function in the process of updating the list. All we can do is
	; return to the system function and let it complete whatever it was doing.
	; As if we don't return to the system function we will be deadlocked.
	; The tick will be deferred; however if the system function was busy updating
	; the ready list, in all likelyhood it's about to call the reschedule
	; interrupt.
	ld		r0,tcb_sema+1
	bne		p100Hz11
	inc		missed_ticks
	rti
p100Hz11:
	cli
	cld		; clear extended precision mode

	pusha	; save off regs on the stack
	lda		#96
	sta		LEDS

	ldx		RunningTCB
	tsa						; save off the stack pointer
	sta		TCB_SPSave,x
	tsr		sp8,r1			; and the eight bit mode stack pointer
	sta		TCB_SP8Save,x
	tsr		abs8,r1
	sta		TCB_ABS8Save,x	; 8 bit emulation base register
	lda		TCB_Status,x
	and		#~TS_RUNNING
	sta		TCB_Status,x
	lda		UserTick
	beq		p100Hz4
	jsr		(r1)
	cli
p100Hz4:
	lda		#97
	sta		LEDS

	; Check the timeout list to see if there are items ready to be removed from
	; the list. Also decrement the timeout of the item at the head of the list.
p100Hz15:
	ldx		TimeoutList
	bmi		p100Hz12				; are there any entries in the timeout list ?
	lda		TCB_Timeout,x
	bgt		p100Hz14				; has this entry timed out ?
	PopTimeoutList
	jsr		AddTaskToReadyList
	bra		p100Hz15				; go back and see if there's another task to be removed
									; there could be a string of tasks to make ready.
p100Hz14:
	dea								; decrement the entry's timeout
	sub		r1,r1,missed_ticks		; account for any missed ticks
	stz		missed_ticks
	sta		TCB_Timeout,x
	
p100Hz12:
	; Falls through into selecting a task to run
tck3:
	lda		#98
	sta		LEDS
;------------------------------------------------------------------------------
; Search the ready queues for a ready task.
; The search is occasionally started at a lower priority queue in order
; to prevent starvation of lower priority tasks. This is managed by 
; using a tick count as an index to a string containing the start que.
;------------------------------------------------------------------------------
;
SelectTaskToRun:
	ld		r6,#5			; number of queues to search
	ldy		IRQFlag			; use the IRQFlag as a buffer index
;	lsr		r3,r3,#1		; the LSB is always the same
	and		r3,r3,#$0F		; counts from 0 to 15
	lb		r3,strStartQue,y	; get the queue to start search at
sttr2:
	lda		QNdx0,y
	bmi		sttr1
	lda		TCB_NxtRdy,r1		; Advance the queue index
	sta		QNdx0,y
	; This is the only place the RunningTCB is set (except for initialization).
	sta		RunningTCB
	ldx		TCB_Status,r1	; flag the task as the running task
	or		r2,r2,#TS_RUNNING
	stx		TCB_Status,r1
	; The mmu map better have the task control block area mapped
	; properly.
	tax
	lda		#12
	bmt		CONFIGREC
;	lda		CONFIGREC
;	bit		#4096
	beq		sttr4
	lda		TCB_mmu_map,x
	sta		MMU_OKEY			; select the mmu map for the task
	lda		#2
	sta		MMU_FUSE			; set fuse to 2 clocks before mapping starts
sttr4:
	lda		#99
	sta		LEDS
	lda		TCB_ABS8Save,x		; 8 bit emulation base register
	trs		r1,abs8
	lda		TCB_SP8Save,x		; get back eight bit stack pointer
	trs		r1,sp8
	ldx		TCB_SPSave,x		; get back stack pointer
	lda		#1
	sta		tcb_sema
	ld		r0,iof_switch
	beq		sttr6
	stz		iof_switch
	jsr		SwitchIOFocus
sttr6:
	txs
	popa						; restore registers
	rti

	; Set index to check the next ready list for a task to run
sttr1:
	iny
	cpy		#5
	bne		sttr5
	ldy		#0
sttr5:
	dec		r6
	bne		sttr2

	; Here there were no tasks ready
	; This should not be able to happen, so hang the machine (in a lower
	; power mode).
sttr3:
	ldx		#94
	stx		LEDS
	jsr		kernel_panic
	db		"No tasks in ready queue.",0
	; Might as well power down the clock and wait for a reset or
	; NMI. In the case of an NMI the kernel is reinitialized without
	; doing the boot reset.
	stp								
	jmp		MTKInitialize

;------------------------------------------------------------------------------
; kernal_panic:
;	All this does right now is display the panic message on the screen.
; Parameters:
;	inline: string
;------------------------------------------------------------------------------
;
kernel_panic:
	pla					; pop the return address off the stack
	push	r4			; save off r4
	ld		r4,r1
kpan2:
	lb		r1,0,r4		; get a byte from the code space
	add		r4,#1		; increment pointer
	and		#$FF		; we want only eight bits
	beq		kpan1			; is it end of string ?
	jsr		DisplayChar
	bra		kpan2
kpan1:						; must update the return address !
	jsr		CRLF
	ld		r1,r4		; get return address into acc
	pop		r4			; restore r4
	jmp		(r1)

include "DeviceDriver.asm"

;------------------------------------------------------------------
;------------------------------------------------------------------
include "Test816.asm"
include "pi_calc816.asm"

;------------------------------------------------------------------
; Kind of a chicken and egg problem here. If there is something
; wrong with the processor, then this code likely won't execute.
;

; put message to screen
; tests pla,sta,ldy,inc,bne,ora,jmp,jmp(abs)

putmsg
	pla					; pop the return address off the stack
	wdm					; switch to 32 bits
	xce
	cpu		RTF65002
	push	r4			; save off r4
	or		r4,r1,#$FFFF0000	; set program bank bits; code is at $FFFFxxxx
pm2
	add		r4,#1		; increment pointer
	lb		r1,0,r4		; get a byte from the code space
	and		#$FF		; we want only eight bits
	beq		pm1			; is it end of string ?
	jsr		DisplayChar
	jmp		pm2
pm1						; must update the return address !
	ld		r1,r4		; get return address into acc
	pop		r4			; restore r4
	clc					; switch back to '816 mode
	xce
	cpu		W65C816S
	rep		#$30		; mem,ndx = 16 bits
	pha
	rts
	
	cpu		RTF65002
;------------------------------------------------------------------
; This test program just loop around waiting to recieve a message.
; The message is a pointer to a string to display.
;------------------------------------------------------------------
;
test_mbx_prg:
	jsr		RequestIOFocus
	lda		#test_mbx	; where to put mailbox handle
	jsr		AllocMbx
	ldx		#5
	jsr		PRTNUM
	lda		#4			; priority
	ldx		#0			; no flags
	ldy		#test_mbx_prg2
	jsr		StartTask
tmp2:
	lda		test_mbx
	ldx		#test_D1
	ldy		#test_D2
	ld		r4,#100
	jsr		WaitMsg
	cmp		#E_Ok
	bne		tmp1
	lda		test_D1
	jsr		DisplayStringB
	bra		tmp2
tmp1:
	ldx		#5
	jsr		PRTNUM
	bra		tmp2

test_mbx_prg2:
tmp2a:
	lda		test_mbx		; get mailbox handle
	ldx		#msg_hello		; MSG D1
	ldy		#0				; MSG D2
	jsr		PostMsg
	bra		tmp2a
msg_hello:
	db		"Hello from RTF",13,10,0

message "DOS.asm"
include "DOS.asm"

	cpu		RTF65002

message "1298"
include "TinyBasic65002.asm"
message "1640"
	org $0FFFFFFF4		; NMI vector
	dw	nmirout

	org	$0FFFFFFF8		; reset vector, native mode
	dw	start
	
	end
	