; ============================================================================
; bootrom3.asm
;        __
;   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
E_DCBInUse	=		0x19
; Device driver errors
E_BadDevNum	=		0x20
E_NoDev		=		0x21
E_BadDevOp	=		0x22
E_ReadError	=		0x23
E_WriteError =		0x24
E_BadBlockNum	=	0x25
E_TooManyBlocks	=	0x26

; resource errors
E_NoMoreMbx	=		0x40
E_NoMoreMsgBlks	=	0x41
E_NoMoreAlarmBlks	= 0x44
E_NoMoreTCBs	=	0x45
E_NoMem		= 12

TS_READY	EQU		1
TS_RUNNING	EQU		2
TS_PREEMPT	EQU		4

LEDS	equ		$FFDC0600
TEXTSCR	equ		$FFD00000
TEXTREG		EQU		$FFDA0000
TEXT_COLS	EQU		0x00
TEXT_ROWS	EQU		0x04
TEXT_CURPOS	EQU		0x2C
TEXT_CURCTL	EQU		0x20
BMP_CLUT	EQU		$FFDC5800

PIC			EQU		0xFFDC0FC0
PIC_IE		EQU		0xFFDC0FC4
PIC_ES		EQU		0xFFDC0FD0
PIC_RSTE	EQU		0xFFDC0FD4

KEYBD		EQU		0xFFDC0000
KEYBDCLR	EQU		0xFFDC0004

SPIMASTER	EQU		0xFFDC0500
SPI_MASTER_VERSION_REG	EQU	0x00
SPI_MASTER_CONTROL_REG	EQU	0x04
SPI_TRANS_TYPE_REG	EQU		0x08
SPI_TRANS_CTRL_REG	EQU		0x0C
SPI_TRANS_STATUS_REG	EQU	0x10
SPI_TRANS_ERROR_REG		EQU	0x14
SPI_DIRECT_ACCESS_DATA_REG		EQU	0x18
SPI_SD_SECT_7_0_REG		EQU	0x1C
SPI_SD_SECT_15_8_REG	EQU	0x20
SPI_SD_SECT_23_16_REG	EQU	0x24
SPI_SD_SECT_31_24_REG	EQU	0x28
SPI_RX_FIFO_DATA_REG	EQU	0x40
SPI_RX_FIFO_DATA_COUNT_MSB	EQU	0x48
SPI_RX_FIFO_DATA_COUNT_LSB  EQU 0x4C
SPI_RX_FIFO_CTRL_REG		EQU	0x50
SPI_TX_FIFO_DATA_REG	EQU	0x80
SPI_TX_FIFO_CTRL_REG	EQU	0x90
SPI_RESP_BYTE1			EQU	0xC0
SPI_RESP_BYTE2			EQU	0xC4
SPI_RESP_BYTE3			EQU	0xC8
SPI_RESP_BYTE4			EQU	0xCC

SPI_INIT_SD			EQU		0x01
SPI_TRANS_START		EQU		0x01
SPI_TRANS_BUSY		EQU		0x01
SPI_INIT_NO_ERROR	EQU		0x00
SPI_READ_NO_ERROR	EQU		0x00
SPI_WRITE_NO_ERROR	EQU		0x00
RW_READ_SD_BLOCK	EQU		0x02
RW_WRITE_SD_BLOCK	EQU		0x03

NR_TCB		EQU		256
TCB_Regs		EQU		0
TCB_SP0Save		EQU		2040
TCB_SP1Save		EQU		2048
TCB_SP2Save		EQU		2056
TCB_SP3Save		EQU		2064
TCB_SP4Save		EQU		2072
TCB_SP5Save		EQU		2080
TCB_SP6Save		EQU		2088
TCB_SP7Save		EQU		2096
TCB_SP8Save		EQU		2104
TCB_SP9Save		EQU		2112
TCB_SP10Save	EQU		2120
TCB_SP11Save	EQU		2128
TCB_SP12Save	EQU		2136
TCB_SP13Save	EQU		2144
TCB_SP14Save	EQU		2152
TCB_SP15Save	EQU		2160
TCB_Seg1Save	EQU		2168
TCB_Seg2Save	EQU		2176
TCB_Seg3Save	EQU		2184
TCB_Seg4Save	EQU		2192
TCB_Seg5Save	EQU		2200
TCB_Seg6Save	EQU		2208
TCB_Seg7Save	EQU		2216
TCB_Seg8Save	EQU		2224
TCB_Seg9Save	EQU		2232
TCB_Seg10Save	EQU		2240
TCB_Seg11Save	EQU		2248
TCB_Seg12Save	EQU		2256
TCB_Seg13Save	EQU		2264
TCB_Seg14Save	EQU		2272
TCB_Seg15Save	EQU		2280
TCB_SPSave		EQU		2288
TCB_Next		EQU		2296
TCB_Prev		EQU		2304
TCB_Status		EQU		2312
TCB_Priority	EQU		2313
TCB_hJob		EQU		2314
TCB_Size	EQU		8192

	bss
	org		$8
Ticks			dw		0
Milliseconds	dw		0
OutputVec		dw		0
TickVec			dw		0
RunningTCB		dw		0
FreeTCB			dw		0
QNdx0			fill.w	8,0
NormAttr		dw		0
CursorRow		db		0
CursorCol		db		0
Dummy1			dc		0
KeybdEcho		db		0
KeybdBad		db		0
KeybdLocks		dc		0
startSector		dh		0
disk_size		dh		0

; Just past the Bootrom
	org		$00010000
NR_PTBL		EQU		32

IVTBaseAddress:
	fill.w	512,0

; Memory Page Allocation Map

PAM1			fill.w	512,0
PAM2			fill.w	512,0

RootPageTbl:
	fill.b	4096*NR_PTBL,0
PgSD0:
	fill.w	512,0
PgSD3:
	fill.w	512,0
PgTbl0:
	fill.w	512,0
PgTbl1:
	fill.w	512,0
PgTbl2:
	fill.w	512,0
PgTbl3:
	fill.w	512,0
PgTbl4:
	fill.w	512,0
PgTbl5:
	fill.w	512,0
IOPgTbl:
	fill.w	512,0

TempTCB:
	fill.b	TCB_Size,0

	; 2MB for TSS space
TSSBaseAddress:
TCBs:
	fill.b	TCB_Size*NR_TCB,0

SECTOR_BUF	fill.b	512,0
BYTE_SECTOR_BUF	EQU	SECTOR_BUF
ROOTDIR_BUF fill.b  16384,0
PROG_LOAD_AREA	EQU ROOTDIR_BUF

EndStaticAllocations:
	dw		0

	code
	org		$00008000
	dw		ClearScreen				; $8000
	dw		HomeCursor				; $8008
	dw		DisplayString			; $8010
	dw		KeybdGetCharDirectNB	; $8018
	dw		ClearBmpScreen			; $8020
	dw		DisplayChar				; $8028
	dw		SDInit					; $8030
	dw		SDReadMultiple			; $8038
	dw		SDWriteMultiple			; $8040
	dw		SDReadPart				; $8048
	dw		SDDiskSize				; $8050
	dw		DisplayWord				; $8058
	dw		DisplayHalf				; $8060
	dw		DisplayCharHex			; $8068
	dw		DisplayByte				; $8070

	org		$8200
start:
	sei
	ldi     r1,#$000FF00000000001  ; 256 entries, base address $1000
	mtspr   GDT,r1
	ldi     r1,#$000FF00000000002  ; 256 entries, base address $2000
	mtspr   LDT,r1
	; Clear descriptor tables
	ldi     r1,#511
.strt1:
	sw      r0,$1000[r0+r1*8]
	dbnz    r1,.strt1
	; Setup the first sixteen entries in the descriptor table corresponding to
    ; the sixteen segment registers. They are setup for a flat memory model.
	sw      r0,$1000
	sw      r0,$1008
	ldi     r1,#$920FFFFFFFFFFFFF  ; data segment
	ldi     r2,#$1000
    sw      r1,$18[r2]
    sw      r1,$28[r2]
    sw      r1,$38[r2]
    sw      r1,$48[r2]
    sw      r1,$58[r2]
    sw      r1,$68[r2]
    sw      r1,$78[r2]
    sw      r1,$88[r2]
    sw      r1,$98[r2]
    sw      r1,$A8[r2]
    sw      r1,$B8[r2]
    sw      r1,$C8[r2]
    sw      r1,$D8[r2]
    sw      r1,$E8[r2]
	ldi     r1,#$9A0FFFFFFFFFFFFF
	sw      r0,$F0[r2]               ; setup code segment
	sw      r1,$F8[r2]
	; Setup data and stack segment
	ldi     r1,#1
	mtspr	ds,r1					; setup data and stack segments
	ldi     r1,#14
	mtspr	ss,r1
	; now do a far jump to set the code segment
	jsp     r0,#15                  ; selector index 15, GDT
	jmp     .strt2
.strt2:
	ldi		r1,#$00000080			; tmr writes
	mtspr	cr0,r1

	; copy the ROM to RAM
	
	ldi		r3,#$FFF
	ldi		r1,#$8000
.st1:
	lw		r2,[r1+r3*8]
	sw		r2,[r1+r3*8]
	dbnz	r3,.st1
	ldi		r1,#$000000C0			; tmr reads/writes
	mtspr	cr0,r1

;	icache_on
	nop
	ldi		r1,#$FF
	sb		r1,LEDS
	ldi		sp,#$3FFFF8
	ldi		r1,#IVTBaseAddress
	shr     r1,r1,#13
	mtspr	vbr,r1

	; setup page tables and the page table address register
	bsr		SetupPageTbl
	ldi		r1,#RootPageTbl+4096+2	; 3 level page table system
	mtspr	cr3,r1
	; turn on paging
	ldi		r1,#$000001C0			; cache on, paging and protection on; tmr read/write/execute
	mtspr	cr0,r1

	bsr		InitBMP

	ldi		r1,#TickRout
	sw		r1,TickVec

	ldi		r1,#$FC
	sb		r1,LEDS

	sw		r0,Milliseconds
	ldi		r1,#%000000100_110101110_0000000000
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	sh		r1,NormAttr
	sb		r0,CursorRow
	sb		r0,CursorCol
	bsr		ClearScreen
	ldi		r1,#DisplayChar
	sw		r1,OutputVec
	bsr		SetupIntVectors
	bsr		KeybdInit
	bsr		InitPIC
	bra		Monitor
	bsr		FMTKInitialize
	cli

	ldi		r1,#$FF
	sb		r1,LEDS
	ldi		r1,#$FE
	push	r1/r2/r3/r4
;	bsr		DispLed
	bsr		ClearScreen
	ldi		r1,#$6
	sb		r1,LEDS
	bsr		DispStartMsg
	ldi		r1,#$FD
	pop		r4/r3/r2/r1
	sb		r1,LEDS
j1:
	bsr		HomeCursor
	ldi		r3,#TEXTSCR+224
	lw		r1,Milliseconds
	bsr		DisplayWord
	lh		r1,TEXTSCR+444
	add		r1,r1,#1
	sh		r1,TEXTSCR+444
	bra		j1
	
DispLed:
	lw		r1,8[sp]
	sb		r1,LEDS
	rts		#8

;------------------------------------------------------------------------------
; Setup the interrupt vector for the system.
;------------------------------------------------------------------------------

SetupIntVectors:
	php
	sei
	ldi		r2,#IVTBaseAddress
	; Initialize all vectors to uninitialized interrupt routine vector
	ldi		r3,#511
	ldi		r1,#uninit_rout
	ldi     r5,#15<<40      ; CS selector
.siv1:
	; setup specific vectors
	shli	r4,r3,#4
	sw		r1,[r2+r4]
	sw		r5,8[r2+r4]		; set CS to #15
	dbnz	r3,.siv1	
	ldi		r1,#start
	sw		r1,449*16[r2]
	ldi		r1,#Tick1000Rout
	sw		r1,450*16[r2]
	ldi		r1,#KeybdIRQ
	sw		r1,463*16[r2]
	ldi		r1,#exf_rout
	sw		r1,497*16[r2]
	ldi		r1,#dwf_rout
	sw		r1,498*16[r2]
	ldi		r1,#drf_rout
	sw		r1,499*16[r2]
	ldi		r1,#sbv_rout
	sw		r1,500*16[r2]
	ldi		r1,#priv_rout
	sw		r1,501*16[r2]
	ldi		r1,#stv_rout
	sw		r1,502*16[r2]
	ldi		r1,#snp_rout
	sw		r1,503*16[r2]
	ldi		r1,#berr_rout
	sw		r1,508*16[r2]
	plp
	rts

;------------------------------------------------------------------------------
; Initialize the interrupt controller.
;------------------------------------------------------------------------------

InitPIC:
	ldi		r1,#$0C			; timer interrupt(s) are edge sensitive
	sh		r1,PIC_ES
	ldi		r1,#$000F		; enable keyboard reset, timer interrupts
	sh		r1,PIC_IE
	rts

;------------------------------------------------------------------------------
; Setup the initial page tables.
; Initialize the PAM.
;------------------------------------------------------------------------------

SetupPageTbl:
	push	r1/r2/r3/r4

	;--------------------------------------------------------------------------
	; Setup the root page directory
	; The root page directory only has two valid entries in it.
	; 0) A pointer to a subdirectory representing the memory in the system (128MB)
	; 3) A pointer to a subdirectory locating the I/O in the system (2MB)
	;           ++--------------- these two bits mapped by the root directory
	; xrrr rrrr rrss_ssss_ssst_tttt_tttt_xxxx_xxxx_xxxx
	; 0000_0000_rrxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx
	;--------------------------------------------------------------------------
	ldi		r1,#RootPageTbl+4096
	bsr		ClearPageTable
	mov		r2,r1
	ldi		r1,#PgSD0
	and		r1,r1,#-4096
	or		r1,r1,#$0F	; priv 0, cacheable, readable, executable, writeable
	sw		r1,[r2]
	ldi		r1,#PgSD0
	and		r1,r1,#-4096
	or		r1,r1,#$0F	; priv 0, cacheable, readable, executable, writeable
	sw		r1,8[r2]
	ldi		r1,#PgSD3
	and		r1,r1,#-4096
	or		r1,r1,#$8D	; priv 8, cacheable, readable, executable, writeable
	sw		r1,24[r2]

	;--------------------------------------------------------------------------
	; Setup subdirectory zero.
	; This sub-directory is capable of mapping all the memory in the system
	; (and more). Only the first 64 pages are used.
	; clear out subdirectory entries
	; ++--------------- these two bits mapped by the root directory
	; ||++-++++-+++---- these nine bits mapped by subirectory SD0
	; rrss_ssss_sss
	; 0000_0sss_sssx_xxxx_xxxx_xxxx_xxxx_xxxx
	;--------------------------------------------------------------------------
	ldi		r2,#PgSD0
	ldi		r3,#511
	ldi     r4,#511*8
.0002:
	sw		r0,[r2+r4]
	subui   r4,r4,#8
	dbnz	r3,.0002

	ldi		r1,#PgTbl0
	and		r1,r1,#-4096
	or		r1,r1,#$0F	; priv 0, cacheable, readable, executable, writeable
	sw		r1,[r2]

	ldi		r1,#PgTbl1
	and		r1,r1,#-4096
	or		r1,r1,#$0F	; priv 0, cacheable, readable, executable, writeable
	sw		r1,8[r2]

	; Bitmap graphics memory pages
	ldi		r1,#PgTbl2
	and		r1,r1,#-4096
	or		r1,r1,#$8D	; priv 8, cacheable, readable, executable, writeable
	sw		r1,2*8[r2]
	ldi		r1,#PgTbl3
	and		r1,r1,#-4096
	or		r1,r1,#$8D	; priv 8, cacheable, readable, executable, writeable
	sw		r1,3*8[r2]
	ldi		r1,#PgTbl4
	and		r1,r1,#-4096
	or		r1,r1,#$8D	; priv 8, cacheable, readable, executable, writeable
	sw		r1,4*8[r2]
	ldi		r1,#PgTbl5
	and		r1,r1,#-4096
	or		r1,r1,#$8D	; priv 8, cacheable, readable, executable, writeable
	sw		r1,5*8[r2]

	; setup first four pages
	; the lowest 16kB of memory is a scratch space
	ldi		r1,#PgTbl0
	bsr		ClearPageTable
	mov		r2,r1
	ldi		r1,#$008F
	sw		r1,[r2]
	ldi		r1,#$108F
	sw		r1,8[r2]
	ldi		r1,#$208F
	sw		r1,16[r2]
	ldi		r1,#$308F
	sw		r1,24[r2]

	; memory between $8000 and $FFFF is the bootrom
	ldi		r3,#7		; eight pages to setup
	ldi     r4,#7*8
	ldi		r1,#$F00E	; priv 0, cacheable, readable, executable, but not writeable
.0003:
	sw		r1,8*8[r2+r4]
	subui	r1,r1,#$1000
	subui   r4,r4,#8
	dbnz	r3,.0003
	
	; memmory above $FFFF to $1FFFFF is RAM for the OS (2MB)
	ldi		r3,#495		; 512- 16-1
	ldi     r4,#495*8
	ldi		r1,#$1FFFFF
.0006:
	sw		r1,16*8[r2+r4]
	subui	r1,r1,#$1000
	subui   r4,r4,#8
	dbnz	r3,.0006

	; memory between $200000 and $3FFFFF is RAM for the OS (2MB)
	ldi		r2,#PgTbl1
	ldi		r1,#$3FFFFF
	bsr		SetupBMTable

	; Page2 range $400000 to $5FFFFF
	; 0000_0000_010x_xxxx_xxxx_xxxx_xxxx_xxxx
	ldi		r2,#PgTbl2
	ldi		r1,#$5FFFFF
	bsr		SetupBMTable

	; Page3 range $600000 to $7FFFFF
	; 0000_0000_011x_xxxx_xxxx_xxxx_xxxx_xxxx
	ldi		r2,#PgTbl3
	ldi		r1,#$7FFFFF
	bsr		SetupBMTable

	; Page4 range $800000 to $9FFFFF
	; 0000_0000_100x_xxxx_xxxx_xxxx_xxxx_xxxx
	ldi		r2,#PgTbl4
	ldi		r1,#$9FFFFF
	bsr		SetupBMTable

	; Page5 range $A00000 to $BFFFFF
	; 0000_0000_101x_xxxx_xxxx_xxxx_xxxx_xxxx
	ldi		r2,#PgTbl5
	ldi		r1,#$BFFFFF
	bsr		SetupBMTable

	;--------------------------------------------------------------------------
	; Setup the PAM (page allocation map).
	;--------------------------------------------------------------------------
	; first mark all free
	ldi		r3,#32768/64-1	; number of pages
	ldi		r1,#0
.0007:
	sw		r0,PAM1[r3]
	dbnz	r3,.0007

	; We've allocated the first 12MB of RAM to the OS and bitmapped
	; graphics display. Mark it in the PAM.
	ldi		r3,#$63		; 3072 pages /64 - 1
	ldi		r1,#-1
.0008:
	sw		r1,PAM1[r3]
	dbnz	r3,.0008

	;--------------------------------------------------------------------------
	; Setup the I/O subdirectory
	; clear out subdirectory entries
	; The I/O subdirectory has only a single valid entry at #510
	; ++--------------- these two bit mapped by the root directory
	; ||++-++++-+++---- these nine bits mapped by subirectory SD3
	; rrss_ssss_sss
	; 1111_1111_110x_xxxx_xxxx_xxxx_xxxx_xxxx
	;--------------------------------------------------------------------------
	ldi		r1,#PgSD3
	bsr		ClearPageTable
	mov		r2,r1
	ldi		r1,#IOPgTbl
	or		r1,r1,#$8D		; priv 8,cachable, readable, non-executable, writeable
	sw		r1,510*8[r2]	; put in proper slot

	;--------------------------------------------------------------------------
	; Setup the I/O page table
	; We setup the I/O page table with linear addresses matching
	; physical ones between $FFCxxxxx and $FFDFFFFF
	; We map all entries assuming there is I/O in each one. In
	; reality all the I/O is above $FFDx, it's too cumbersone
	; to map on a device by device basis. If there happens not to be an I/O
	; device at a memory location, a bus error will result.
	; ++--------------- these two bit mapped by the root directory
	; ||++-++++-+++---- these nine bits mapped by subirectory SD3
	; |||| |||| |||+-++++-++++---- these nine bits mapped by the I/O page table
	; rrss_ssss_sss| |||| ||||
	; 1111_1111_110t_tttt_tttt_xxxx_xxxx_xxxx
	;--------------------------------------------------------------------------
	ldi		r2,#IOPgTbl
	ldi		r3,#511
	ldi     r4,#511*8
	ldi		r1,#$FFDFF085	; priv 8, non-cachable, readable, non-executable, writeable
.0005:
	sw		r1,[r2+r4]
	subui	r1,r1,#$1000
	subui   r4,r4,#8
	dbnz	r3,.0005

	pop		r4/r3/r2/r1
	rts

;------------------------------------------------------------------------------
; Clear the page table ( a block of 512 words).
; Parameters:
;	r1 = address of page table
;------------------------------------------------------------------------------

ClearPageTable:
	push	r2/r3
	ldi		r2,#511
	ldi     r3,#511*8
.0001:
	sw		r0,[r1+r3]
	subui   r3,r3,#8
	dbnz	r2,.0001
	pop		r3/r2
	rts

;------------------------------------------------------------------------------
; r1 = address
; r2 = pointer to page table
;------------------------------------------------------------------------------

SetupBMTable:
	push	r3/r4
	ldi		r3,#511
	ldi     r4,#511*8
.0006:
	and		r1,r1,#-4096
	or		r1,r1,#$8F
	sw		r1,[r2+r4]
	subui	r1,r1,#$1000
	subui   r4,r4,#8
	dbnz	r3,.0006
	pop		r4/r3
	rts

;------------------------------------------------------------------------------
; Find the highest available page number and allocate it.
;
; Returns:
;	r1 = physical page number, 0 if none available
;------------------------------------------------------------------------------

FindHiPage:
	push	r2/r3
	ldi		r1,#511*8		; start at top of map
.0002:
	lw		r2,PAM1[r1]
	com		r2,r2			; com bit pattern so we can test for all ones
	brnz	r2,.0001		; is any page free ?
	dbnz	r1,.0002		; no, try next word
	; Here we are out of memory
	mov		r1,r0
	pop		r3/r2
	rts

.0001:
	com		r2,r2			; get back positive bits
	ldi		r3,#63			; number of bits to test - 1
.0004:
	brpl	r2,.0003		; check MSB, is it clear ?
	rol		r2,r2,#1		; rotate to next bit
	dbnz	r3,.0004		; loop back
.0003:
	rol		r2,r2,#1		; make MSB the LSB
	or		r2,r2,#1		; and set bit
	rol		r2,r2,r3		; put the bits back in original place
	sw		r2,PAM1[r1]		; update word in memory

	shl		r3,r3,#13		; multiply bit # by page size
	shl		r1,r1,#19		; 
	or		r1,r1,r3		; r1 = physical address
	pop		r3/r2
	rts

AddOSPT:
	

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

AsciiToScreen:
	and		r1,r1,#$FF
	or		r1,r1,#$100
	and		fl0,r1,#%00100000	; if bit 5 or 6 isn't set
	brz		fl0,.00001
	and		fl0,r1,#%01000000
	brz		fl0,.00001
	and		r1,r1,#%110011111
.00001:
	rts

ScreenChar:
    db     
    
;------------------------------------------------------------------------------
; Convert screen display character to ascii.
;------------------------------------------------------------------------------

ScreenToAscii:
	and		r1,r1,#$FF
	cmp		fl0,r1,#26+1
	bhs		fl0,.stasc1
	add		r1,r1,#$60
.stasc1:
	rts

CursorOff:
	rts
CursorOn:
	rts
HomeCursor:
	sb		r0,CursorRow
	sb		r0,CursorCol
	sc	    r0,TEXTREG+TEXT_CURPOS
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ClearScreen:
	push	r1/r2/r3/r4
	ldi		r1,#$5
	sb		r1,LEDS
	lbu		r1,TEXTREG+TEXT_COLS
	lbu		r2,TEXTREG+TEXT_ROWS
	mulu	r4,r2,r1
	ldi		r3,#TEXTSCR
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r2,NormAttr
	or		r1,r1,r2
.cs1:
	sh		r1,[r3]
	addui	r3,r3,#4
	dbnz	r4,.cs1
	pop		r4/r3/r2/r1
	rts

;------------------------------------------------------------------------------
; Randomize the color lookup table for 8bpp mode (the default), so that
; something will show on the bitmap display if it's written to.
;------------------------------------------------------------------------------

InitBMP:
	mfspr	r2,tick
	mtspr	srand1,r2
	mfspr	r2,tick
	mtspr	srand2,r2
	ldi		r2,#511
.ibmp1:
	gran	r1
	shl     r2,r2,#2
	sh		r1,BMP_CLUT[r0+r2]
	shr     r2,r2,#2
	dbnz	r2,.ibmp1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ClearBmpScreen:
	ldi		r1,#$400000
	ldi		r2,#$7FFFF
.0001:
    shl     r2,r2,#3
	sw		r0,[r1+r2]
	shr     r2,r2,#3
	dbnz	r2,.0001
	rts

;------------------------------------------------------------------------------
; Display the word in r1
;------------------------------------------------------------------------------

DisplayWord:
	swap	r1,r1
	bsr		DisplayHalf
	swap	r1,r1

;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------

DisplayHalf:
	ror		r1,r1,#16
	bsr		DisplayCharHex
	rol		r1,r1,#16

;------------------------------------------------------------------------------
; Display the char in r1
;------------------------------------------------------------------------------

DisplayCharHex:
	ror		r1,r1,#8
	bsr		DisplayByte
	rol		r1,r1,#8

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------

DisplayByte:
	ror		r1,r1,#4
	bsr		DisplayNybble
	rol		r1,r1,#4

;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------

DisplayNybble:
	push	r1
	and		r1,r1,#$0F
	add		r1,r1,#'0'
	cmp		fl0,r1,#'9'+1
	blo		fl0,.0001
	add		r1,r1,#7
.0001:
	jsr		(OutputVec)
	pop		r1
	rts

DisplayString:
	push	r1/r2
	mov		r2,r1
.dm2:
	lbu		r1,[r2]
	add		r2,r2,#1	; increment text pointer
	brz		r1,.dm1
	bsr		OutChar
	brz		r0,.dm2
.dm1:
	pop		r2/r1
	rts

DisplayStringCRLF:
	bsr		DisplayString
CRLF:
	push	r1
	ldi		r1,#CR
	bsr		OutChar
	ldi		r1,#LF
	bsr		OutChar
	pop		r1
	rts


DispCharQ:
	bsr		AsciiToScreen
	sc		r1,[r3]
	add		r3,r3,#4
	rts

DispStartMsg:
	ldi		r1,#msgStart
	bsr		DisplayString
	rts

	db	0
msgStart:
	db	"Table888 test system starting.",0

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KeybdIRQ:
	sh		r0,KEYBD+4
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

TickRout:
	lh		tr,TEXTSCR+220
	add		tr,tr,#1
	sh		tr,TEXTSCR+220
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

Tick1000Rout:
	push	r1
	ldi		r1,#2				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	lw		r1,Milliseconds
	add		r1,r1,#1
	sw		r1,Milliseconds
	pop		r1
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetScreenLocation:
	ldi		r1,#TEXTSCR
	rts
GetCurrAttr:
	lhu		r1,NormAttr
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

UpdateCursorPos:
	push	r1/r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu		r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	sc		r2,TEXTREG+TEXT_CURPOS
	pop		r4/r2/r1
	rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

CalcScreenLoc:
	push	r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu		r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	sc		r2,TEXTREG+TEXT_CURPOS
	bsr		GetScreenLocation
	shl		r2,r2,#2
	add		r1,r1,r2
	pop		r4/r2
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DisplayChar:
	push	r1/r2/r3/r4
	and		r1,r1,#$FF
	cmp		fl0,r1,#'\r'
	beq		fl0,.docr
	cmp		fl0,r1,#$91		; cursor right ?
	beq		fl0,.doCursorRight
	cmp		fl0,r1,#$90		; cursor up ?
	beq		fl0,.doCursorUp
	cmp		fl0,r1,#$93		; cursor left ?
	beq		fl0,.doCursorLeft
	cmp		fl0,r1,#$92		; cursor down ?
	beq		fl0,.doCursorDown
	cmp		fl0,r1,#$94		; cursor home ?
	beq		fl0,.doCursorHome
	cmp		fl0,r1,#$99		; delete ?
	beq		fl0,.doDelete
	cmp		fl0,r1,#CTRLH	; backspace ?
	beq		fl0,.doBackspace
	cmp		fl0,r1,#'\n'	; line feed ?
	beq		fl0,.doLinefeed
	mov		r2,r1
	bsr		CalcScreenLoc
	mov		r3,r1
	mov		r1,r2
	bsr		AsciiToScreen
	mov		r2,r1
	bsr		GetCurrAttr
	or		r1,r1,r2
	sh		r1,[r3]
	bsr		IncCursorPos
.dcx4:
	pop		r4/r3/r2/r1
	rts
.docr:
	sb		r0,CursorCol
	bsr		UpdateCursorPos
	pop		r4/r3/r2/r1
	rts
.doCursorRight:
	lbu		r1,CursorCol
	add		r1,r1,#1
	cmp		fl0,r1,#56
	bhs		fl0,.dcx7
	sb		r1,CursorCol
.dcx7:
	bsr		UpdateCursorPos
	pop		r4/r3/r2/r1
	rts
.doCursorUp:
	lbu		r1,CursorRow
	brz		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorRow
	bra		.dcx7
.doCursorLeft:
	lbu		r1,CursorCol
	brz		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorCol
	bra		.dcx7
.doCursorDown:
	lbu		r1,CursorRow
	add		r1,r1,#1
	cmp		fl0,r1,#31
	bhs		fl0,.dcx7
	sb		r1,CursorRow
	bra		.dcx7
.doCursorHome:
	lbu		r1,CursorCol
	brz		r1,.dcx12
	sb		r0,CursorCol
	bra		.dcx7
.dcx12:
	sb		r0,CursorRow
	bra		.dcx7
.doDelete:
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
	bra		.dcx5
.doBackspace:
	lbu		r1,CursorCol
	brz		r1,.dcx4
	sub		r1,r1,#1
	sb		r1,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
.dcx5:
	lhu		r2,4[r3]
	sh		r2,[r3]
	add		r3,r3,#4
	add		r1,r1,#1
	cmp		fl0,r1,#56
	blo		fl0,.dcx5
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r2,NormAttr
	or		r1,r1,r2
	sub		r3,r3,#4
	sh		r1,[r3]
	bra		.dcx4
.doLinefeed:
	bsr		IncCursorRow
	bra		.dcx4


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

IncCursorPos:
	push	r1/r2/r4
	lbu		r1,CursorCol
	add		r1,r1,#1
	sb		r1,CursorCol
	cmp		fl0,r1,#56
	blo		fl0,icc1
	sb		r0,CursorCol
	bra		icr1
IncCursorRow:
	push	r1/r2/r4
icr1:
	lbu		r1,CursorRow
	add		r1,r1,#1
	sb		r1,CursorRow
	cmp		fl0,r1,#31
	blo		fl0,icc1
	ldi		r2,#30
	sb		r2,CursorRow
	bsr		ScrollUp
icc1:
	bsr		UpdateCursorPos
	pop		r4/r2/r1
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ScrollUp:
	push	r1/r2/r3/r5
	push	r6
	lbu		r1,TEXTREG+TEXT_COLS
	lbu		r2,TEXTREG+TEXT_ROWS
	sub		r2,r2,#1
	mul		r6,r1,r2
	ldi		r1,#TEXTSCR
	ldi		r2,#TEXTSCR+224
	ldi		r3,#0
.0001:
    shl     r3,r3,#2
	lh		r5,[r2+r3]
	sh		r5,[r1+r3]
	shr     r3,r3,#2
	add		r3,r3,#1
	dbnz	r6,.0001
	lbu		r1,TEXTREG+TEXT_ROWS
	sub		r1,r1,#1
	bsr		BlankLine
	pop		r6
	pop		r5/r3/r2/r1
	rts

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank out
;------------------------------------------------------------------------------

BlankLine:
	push	r1/r2/r3/r4
	lbu	    r2,TEXTREG+TEXT_COLS
	mul		r3,r2,r1
	sub		r2,r2,#1		; r2 = #chars to blank - 1
	shl		r3,r3,#2
	add		r3,r3,#TEXTSCR
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r4,NormAttr
	or		r1,r1,r4
.0001:
    shl     r2,r2,#2	
	sh		r1,[r3+r2]
	shr     r2,r2,#2
	dbnz	r2,.0001
	pop		r4/r3/r2/r1
	rts

; ============================================================================
; Monitor Task
; ============================================================================

Monitor:
	ldi		r1,#49
	sb		r1,LEDS
	bsr		ClearScreen
	ldi		r1,#msgMonitorStarted
	bsr		DisplayString
	sb		r0,KeybdEcho
	;ldi		r1,#7
	;ldi		r2,#0
	;ldi		r3,#IdleTask
	;ldi		r4,#0
	;ldi		r5,#0
	;bsr		StartTask
mon1:
	ldi		r1,#50
	sb		r1,LEDS
	ldi		sp,#TCBs+TCB_Size-8		; reload the stack pointer, it may have been trashed
	cli
.PromptLn:
	bsr		CRLF
	ldi		r1,#'$'
	bsr		OutChar
.Prompt3:
	bsr		KeybdGetCharDirectNB
	brmi	r1,.Prompt3
	cmp		fl0,r1,#CR
	beq		fl0,.Prompt1
	bsr		OutChar
	bra		.Prompt3
.Prompt1:
	sb		r0,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	bsr		MonGetch
	cmp		fl0,r1,#'$'
	bne		fl0,.Prompt2
	bsr		MonGetch
.Prompt2:
	cmp		fl0,r1,#'?'
	beq		fl0,.doHelp
	cmp		fl0,r1,#'C'
	beq		fl0,doCLS
	cmp		fl0,r1,#'M'
	beq		fl0,doDumpmem
	cmp		fl0,r1,#'m'
	beq		fl0,MRTest
	cmp		fl0,r1,#'S'
	beq		fl0,doSDBoot
	cmp		fl0,r1,#'g'
	beq		fl0,doRand
	bra mon1

.doHelp:
	ldi		r1,#msgHelp
	bsr		DisplayString
	bra mon1

MonGetch:
	lhu		r1,[r3]
	andi	r1,r1,#$1FF
	add		r3,r3,#4
	bsr		ScreenToAscii
	rts

;------------------------------------------------------------------------------
; Ignore blanks in the input
; r3 = text pointer
; r1 destroyed
;------------------------------------------------------------------------------

ignBlanks:
ignBlanks1:
	bsr		MonGetch
	cmp		fl0,r1,#' '
	beq		fl0,ignBlanks1
	sub		r3,r3,#4
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetTwoParams:
	bsr		ignBlanks
	bsr		GetHexNumber	; get start address of dump
	mov		r2,r1
	bsr		ignBlanks
	bsr		GetHexNumber	; get end address of dump
	rts

;------------------------------------------------------------------------------
; Get a range, the end must be greater or equal to the start.
;------------------------------------------------------------------------------

GetRange:
	bsr		GetTwoParams
	cmp		fl0,r2,r1
	bhi		fl0,DisplayErr
	rts

doDumpmem:
	bsr		CursorOff
	bsr		GetRange
	bsr		CRLF
.001:
	bsr		CheckKeys
	bsr		DisplayMemBytes
	cmp		fl0,r2,r1
	bls		fl0,.001
	bra mon1

doSDBoot:
;	sub		r3,r3,#4
	bsr		SDInit
	brnz	r1,mon1
	bsr		SDReadPart
	brnz	r1,mon1
	bsr		SDReadBoot
	brnz	r1,mon1
	bsr		loadBootFile
	jmp		mon1

OutChar:
	jmp		(OutputVec)

doRand:
	mfspr	r1,tick
	mtspr	srand1,r1
	mfspr	r1,tick
	mtspr	srand2,r1
.0001:
	gran	r1
	bsr		DisplayWord
	bsr		CRLF
	bsr		CheckKeys
	bra .0001

;------------------------------------------------------------------------------
; Display memory pointed to by r2.
; destroys r1,r3
;------------------------------------------------------------------------------
;
DisplayMemBytes:
	push	r1/r3
	ldi		r1,#'>'
	bsr		OutChar
	ldi		r1,#'B'
	bsr		OutChar
	ldi		r1,#' '
	bsr		OutChar
	mov		r1,r2
	bsr		DisplayHalf
	ldi		r3,#7
.001:
	ldi		r1,#' '
	bsr		OutChar
	lbu		r1,[r2]
	jsr		DisplayByte
	add		r2,r2,#1
	dbnz	r3,.001
	ldi		r1,#':'
	bsr		OutChar
	ldi		r1,#%110101110_000000100_0000000000	; reverse video
	sh		r1,NormAttr
	ldi		r3,#7
	sub		r2,r2,#8
.002
	lbu		r1,[r2]
	cmp		fl0,r1,#26				; convert control characters to '.'
	bhs		fl0,.004
	ldi		r1,#'.'
	bra .003
.004:
	cmp		fl0,r1,#$80				; convert other non-ascii to '.'
	blo		fl0,.003
	ldi		r1,#'.'
.003:
	bsr		OutChar
	add		r2,r2,#1
	dbnz	r3,.002
	ldi		r1,#%000000100_110101110_0000000000	; normal video
	sh		r1,NormAttr
	bsr		CRLF
	pop		r3/r1
	rts

;------------------------------------------------------------------------------
; CheckKeys:
;	Checks for a CTRLC or a scroll lock during long running dumps.
;------------------------------------------------------------------------------

CheckKeys:
	bsr		CTRLCCheck
	bra CheckScrollLock

;------------------------------------------------------------------------------
; CTRLCCheck
;	Checks to see if CTRL-C is pressed. If so then the current routine is
; aborted and control is returned to the monitor.
;------------------------------------------------------------------------------

CTRLCCheck:
	push	r1
	bsr		KeybdGetCharDirectNB
	cmp		fl0,r1,#CTRLC
	beq		fl0,.0001
	pop		r1
	rts
.0001:
	add		sp,sp,#16
	bra mon1

;------------------------------------------------------------------------------
; CheckScrollLock:
;	Check for a scroll lock by the user. If scroll lock is active then tasks
; are rescheduled while the scroll lock state is tested in a loop.
;------------------------------------------------------------------------------

CheckScrollLock:
	push	r1
.0002:
	lcu		r1,KeybdLocks
	and		fl0,r1,#$4000		; is scroll lock active ?
	brz		fl0,.0001
	brk		#2*16				; reschedule tasks
	bra .0002
.0001:
	pop		r1
	rts

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
; R3 = text pointer (updated)
; R1 = hex number
;------------------------------------------------------------------------------
;
GetHexNumber:
	push	r2/r4
	ldi		r2,#0
	ldi		r4,#15
.gthxn2:
	bsr		MonGetch
	bsr		AsciiToHexNybble
	cmp		fl0,r1,#-1
	beq		fl0,.gthxn1
	shl		r2,r2,#4
	and		r1,r1,#$0f
	or		r2,r2,r1
	dbnz	r4,.gthxn2
.gthxn1:
	mov		r1,r2
	pop		r4/r2
	rts

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
	cmp		fl0,r1,#'0'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'9'+1
	bhs		fl0,.gthx5
	sub		r1,r1,#'0'
	rts
.gthx5:
	cmp		fl0,r1,#'A'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'F'+1
	bhs		fl0,.gthx6
	sub		r1,r1,#'A'
	add		r1,r1,#10
	rts
.gthx6:
	cmp		fl0,r1,#'a'
	blo		fl0,.gthx3
	cmp		fl0,r1,#'z'+1
	bhs		fl0,.gthx3
	sub		r1,r1,#'a'
	add		r1,r1,#10
	rts
.gthx3:
	ldi		r1,#-1		; not a hex number
	rts

DisplayErr:
	ldi		r1,#msgErr
	bsr		DisplayString
	bra mon1

msgErr:
	db	"**Err",CR,LF,0

msgHelp:
	db		"? = Display Help",CR,LF
	db		"CLS = clear screen",CR,LF
	db		"MB = dump memory",CR,LF
	db		"S = boot from SD card",CR,LF
	db		0

msgMonitorStarted
	db		"Monitor started.",0

doCLS:
	bsr		ClearScreen
	bsr		HomeCursor
	bra mon1

KEYBD_DELAY		EQU		1000

KeybdGetCharDirectNB:
	push	r2
	sei
	mfspr	r1,cr0			; turn off tmr for i/o
	push	r1
	ldi		r1,#0
	mtspr	cr0,r1
	lcu		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	cli
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	pop		r2
	mtspr	cr0,r2			; set tmr mode back
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.0002
	cmp		fl0,r1,#CR
	bne		fl0,.0003
	bsr		CRLF
	bra .0002
.0003:
	jsr		(OutputVec)
.0002:
	pop		r2
	rts
.0001:
	pop		r2
	mtspr	cr0,r2			; set tmr mode back
	cli
	ldi		r1,#-1
	pop		r2
	rts

KeybdGetCharDirect:
	push	r2
	mfspr	r1,cr0
	push	r1
	mtspr	cr0,r0			; clear tmr mode
.0001:
	lc		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	pop		r2				; restore tmr mode
	mtspr	cr0,r2
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.gk1
	cmp		fl0,r1,#CR
	bne		fl0,.gk2
	bsr		CRLF
	bra .gk1
.gk2:
	jsr		(OutputVec)
.gk1:
	pop		r2
	rts

KeybdInit:
	mfspr	r1,cr0		; turn off tmr mode
	push	r1
	mtspr	cr0,r0
	ldi		r1,#33
	sb		r1,LEDS
	ldi		r1,#$ff		; issue keyboard reset
	bsr		SendByteToKeybd
	ldi		r1,#38
	sb		r1,LEDS
	ldi		r1,#4
;	jsr		Sleep
	ldi		r1,#KEYBD_DELAY	; delay a bit
kbdi5:
	sub		r1,r1,#1
	brnz	r1,kbdi5
	ldi		r1,#34
	sb		r1,LEDS
	ldi		r1,#0xf0		; send scan code select
	bsr		SendByteToKeybd
	ldi		r1,#35
	sb		r1,LEDS
	ldi		r2,#0xFA
	bsr		WaitForKeybdAck
	cmp		fl0,r1,#$FA
	bne		fl0,kbdi2
	ldi		r1,#36
	sb		r1,LEDS
	ldi		r1,#2			; select scan code set#2
	bsr		SendByteToKeybd
	ldi		r1,#39
	sb		r1,LEDS
kbdi2:
	ldi		r1,#45
	sb		r1,LEDS
	pop		r1				; turn back on tmr mode
	mtspr	cr0,r1
	rts

msgBadKeybd:
	db		"Keyboard not responding.",0

SendByteToKeybd:
	push	r2
	sb		r1,KEYBD
	ldi		r1,#40
	sb		r1,LEDS
	mfspr	r3,tick
kbdi4:						; wait for transmit complete
	mfspr	r4,tick
	sub		r4,r4,r3
	cmp		fl0,r4,#KEYBD_DELAY
	bhi		fl0,kbdbad
	ldi		r1,#41
	sb		r1,LEDS
	lbu		r1,KEYBD+12
	and		fl0,r1,#64
	brz		fl0,kbdi4
	bra sbtk1
kbdbad:
	ldi		r1,#42
	sb		r1,LEDS
	lbu		r1,KeybdBad
	brnz	r1,sbtk2
	ldi		r1,#1
	sb		r1,KeybdBad
	ldi		r1,#43
	sb		r1,LEDS
	ldi		r1,#msgBadKeybd
	bsr		DisplayStringCRLF
sbtk1:
	ldi		r1,#44
	sb		r1,LEDS
	pop		r2
	rts
sbtk2:
	bra sbtk1

; Wait for keyboard to respond with an ACK (FA)
;
WaitForKeybdAck:
	ldi		r1,#64
	sb		r1,LEDS
	mfspr	r3,tick
wkbdack1:
	mfspr	r4,tick
	sub		r4,r4,r3
	cmp		fl0,r4,#KEYBD_DELAY
	bhi		fl0,wkbdbad
	ldi		r1,#65
	sb		r1,LEDS
	lcu		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,wkbdack1
;	lcu		r1,KEYBD+8
	and		r1,r1,#$ff
wkbdbad:
	rts

MRTest:
	ldi		r1,#0
	ldi		r3,#255
.0001:
    shl     r4,r3,#3
	sw		r3,$100000[r0+r4]
	dbnz	r3,.0001
	ldi		r1,#$100000
	lmr		r2,r255,[r1]
	ldi		r1,#$120000
	smr		r2,r255,[r1]
	jmp		mon1
		
; ============================================================================
; ============================================================================
;------------------------------------------------------------------------------
; Initialize the SD card
; Returns
; acc = 0 if successful, 1 otherwise
; Z=1 if successful, otherwise Z=0
;------------------------------------------------------------------------------
;
SDInit:
	push	r2
	mfspr	r2,cr0		; turn off tmr
	push	r2
	mtspr	cr0,r0
	ldi		r2,#SPIMASTER
	ldi		r1,#SPI_INIT_SD
	sb		r1,SPI_TRANS_TYPE_REG[r2]
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPI_TRANS_CTRL_REG[r2]
	nop
.spi_init1
	lbu		r1,SPI_TRANS_STATUS_REG[r2]
	bsr		spi_delay
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_init1
	lbu		r1,SPI_TRANS_ERROR_REG[r2]
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_INIT_NO_ERROR
	bne		fl0,.spi_error
;	lda		#spi_init_ok_msg
;	jsr		DisplayStringB
	pop		r2
	mtspr	cr0,r2
	pop		r2
	ldi		r1,#E_Ok
	rts
.spi_error
	bsr		DisplayByte
	ldi		r1,#spi_init_error_msg
	bsr		DisplayString
	lbu		r1,SPI_RESP_BYTE1[r2]
	bsr		DisplayByte
	lbu		r1,SPI_RESP_BYTE2[r2]
	bsr		DisplayByte
	lbu		r1,SPI_RESP_BYTE3[r2]
	bsr		DisplayByte
	lbu		r1,SPI_RESP_BYTE4[r2]
	bsr		DisplayByte
	pop		r2
	mtspr	cr0,r2
	pop		r2
	ldi		r1,#1
	rts

spi_delay:
	nop
	nop
	rts


;------------------------------------------------------------------------------
; SD read sector
;
; r1= sector number to read
; r2= address to place read data
; Returns:
; r1 = 0 if successful
;------------------------------------------------------------------------------
;
SDReadSector:
	push	r2/r3/r4/r5
	push	r6
	mfspr	r6,cr0
	mtspr	cr0,r0
	ldi		r5,#SPIMASTER	
	sb		r1,SPI_SD_SECT_7_0_REG[r5]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_15_8_REG[r5]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_23_16_REG[r5]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_31_24_REG[r5]

	ldi		r4,#19	; retry count

.spi_read_retry:
	; Force the reciever fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	ldi		r1,#1
	sb		r1,SPI_RX_FIFO_CTRL_REG[r5]

	ldi		r1,#RW_READ_SD_BLOCK
	sb		r1,SPI_TRANS_TYPE_REG[r5]
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPI_TRANS_CTRL_REG[r5]
	nop
.spi_read_sect1:
	lbu		r1,SPI_TRANS_STATUS_REG[r5]
	bsr		spi_delay			; just a delay between consecutive status reg reads
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_read_sect1
	lbu		r1,SPI_TRANS_ERROR_REG[r5]
	shr		r1,r1,#2
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_READ_NO_ERROR
	bne		fl0,.spi_read_error
	ldi		r3,#511		; read 512 bytes from fifo
.spi_read_sect2:
	lbu		r1,SPI_RX_FIFO_DATA_REG[r5]
	mtspr	cr0,r6
	sb		r1,[r2]		; store byte in buffer using tmr
	mtspr	cr0,r0
	add		r2,r2,#1
	dbnz	r3,.spi_read_sect2
	ldi		r1,#0
	bra		.spi_read_ret
.spi_read_error:
	dbnz	r4,.spi_read_retry
	bsr		DisplayByte
	ldi		r1,#spi_read_error_msg
	bsr		DisplayString
	ldi		r1,#1
.spi_read_ret:
	mtspr	cr0,r6
	pop		r6
	pop		r5/r4/r3/r2
	rts

;------------------------------------------------------------------------------
; BlocksToSectors:
;	Convert a logical block number (LBA) to a sector number
;------------------------------------------------------------------------------

BlocksToSectors:
	shl		r1,r1,#1			; 1k blocks = 2 sectors
	rts

;------------------------------------------------------------------------------
; SDReadBlocks:
;
; Registers Affected: r1-r5
; Parameters:
;	r1 = pointer to DCB
;	r3 = block number
;	r4 = number of blocks
;	r5 = pointer to data area
;------------------------------------------------------------------------------

SDReadBlocks:
	rts

;------------------------------------------------------------------------------
; SDWriteBlocks:
;
; Parameters:
;	r1 = pointer to DCB
;	r3 = block number
;	r4 = number of blocks
;	r5 = pointer to data area
;------------------------------------------------------------------------------

SDWriteBlocks:
	rts

;------------------------------------------------------------------------------
; SDWriteSector:
;
; r1= sector number to write
; r2= address to get data from
; Returns:
; r1 = 0 if successful
;------------------------------------------------------------------------------
;
SDWriteSector:
	push	r2/r3/r4/r5
	push	r1
	mfspr	r5,cr0
	mtspr	cr0,r0
	ldi		r4,#SPIMASTER

	; Force the transmitter fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	ldi		r1,#1
	sb		r1,SPI_TX_FIFO_CTRL_REG[r4]
	nop			; give I/O time to respond
	nop

	; now fill up the transmitter fifo
	ldi		r3,#511
.spi_write_sect1:
	mtspr	cr0,r5
	lbu		r1,[r2]
	mtspr	cr0,r0
	sb		r1,SPI_TX_FIFO_DATA_REG[r4]
	nop			; give the I/O time to respond
	nop
	add		r2,r2,#1
	dbnz	r3,.spi_write_sect1

	; set the sector number in the spi master address registers
	pop		r1
	sb		r1,SPI_SD_SECT_7_0_REG[r4]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_15_8_REG[r4]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_23_16_REG[r4]
	shr		r1,r1,#8
	sb		r1,SPI_SD_SECT_31_24_REG[r4]

	; issue the write command
	ldi		r1,#RW_WRITE_SD_BLOCK
	sb		r1,SPI_TRANS_TYPE_REG[r4]
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPI_TRANS_CTRL_REG[r4]
	nop
.spi_write_sect2:
	lbu		r1,SPI_TRANS_STATUS_REG[r4]
	nop							; just a delay between consecutive status reg reads
	nop
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_write_sect2
	lbu		r1,SPI_TRANS_ERROR_REG[r4]
	shr		r1,r1,#4
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_WRITE_NO_ERROR
	bne		fl0,.spi_write_error
	ldi		r1,#0
	bra		.spi_write_ret
.spi_write_error:
	bsr		DisplayByte
	ldi		r1,#spi_write_error_msg
	bsr		DisplayString
	ldi		r1,#1

.spi_write_ret:
	mtspr	cr0,r5
	pop		r5/r4/r3/r2
	rts

;------------------------------------------------------------------------------
; SDReadMultiple: read multiple sectors
;
; r1= sector number to read
; r2= address to write data
; r3= number of sectors to read
;
; Returns:
; r1 = 0 if successful
;
;------------------------------------------------------------------------------

SDReadMultiple:
	push	r4
	ldi		r4,#0
.spi_rm1:
	push	r1
	bsr		SDReadSector
	add		r4,r4,r1
	add		r2,r2,#512
	pop		r1
	add		r1,r1,#1
	sub		r3,r3,#1
	brnz	r3,.spi_rm1
	mov		r1,r4
	pop		r4
	rts

;------------------------------------------------------------------------------
; SD write multiple sector
;
; r1= sector number to write
; r2= address to get data from
; r3= number of sectors to write
;
; Returns:
; r1 = 0 if successful
;------------------------------------------------------------------------------
;
SDWriteMultiple:
	push	r4
	ldi		r4,#0
.spi_wm1:
	push	r1
	bsr		SDWriteSector
	add		r4,r4,r1		; accumulate an error count
	add		r2,r2,#512		; 512 bytes per sector
	pop		r1
	add		r1,r1,#1
	sub		r3,r3,#1
	brnz	r3,.spi_wm1
	mov		r1,r4
	pop		r4
	rts
	
;------------------------------------------------------------------------------
; read the partition table to find out where the boot sector is.
; Returns
; r1 = 0 everything okay, 1=read error
; also Z=1=everything okay, Z=0=read error
;------------------------------------------------------------------------------

SDReadPart:
	push	r2/r3
	sh		r0,startSector					; default starting sector
	ldi		r1,#0							; r1 = sector number (#0)
	ldi		r2,#BYTE_SECTOR_BUF				; r2 = target address (word to byte address)
	bsr		SDReadSector
	brnz	r1,.spi_rp1
	lcu		r1,BYTE_SECTOR_BUF+$1C8
	lcu		r3,BYTE_SECTOR_BUF+$1C6
	shl		r1,r1,#16
	or		r1,r1,r3
	sh		r1,startSector					; r1 = 0, for okay status
	bsr		DisplayHalf
	bsr		CRLF
	lcu		r1,BYTE_SECTOR_BUF+$1CC
	lcu		r3,BYTE_SECTOR_BUF+$1CA
	shl		r1,r1,#16
	or		r1,r1,r3
	sh		r1,disk_size					; r1 = 0, for okay status
	bsr		DisplayHalf
	bsr		CRLF
	pop		r3/r2
	ldi		r1,#0
	rts
.spi_rp1:
	pop		r3/r2
	ldi		r1,#1
	rts

SDDiskSize:
	lhu		r1,disk_size
	rts

;------------------------------------------------------------------------------
; Read the boot sector from the disk.
; Make sure it's the boot sector by looking for the signature bytes 'EB' and '55AA'.
; Returns:
; r1 = 0 means this card is bootable
; r1 = 1 means a read error occurred
; r1 = 2 means the card is not bootable
;------------------------------------------------------------------------------

SDReadBoot:
	push	r2/r3/r5
	lhu		r1,startSector				; r1 = sector number
	ldi		r2,#BYTE_SECTOR_BUF			; r2 = target address
	bsr		SDReadSector
	brnz	r1,spi_read_boot_err
	lbu		r1,BYTE_SECTOR_BUF
	cmp		fl0,r1,#$EB
	bne		fl0,spi_eb_err
spi_read_boot2:
	ldi		r1,#msgFoundEB
	bsr		DisplayStringCRLF
	lbu		r1,BYTE_SECTOR_BUF+$1FE		; check for 0x55AA signature
	cmp		fl0,r1,#$55
	bne		fl0,spi_eb_err
	lbu		r1,BYTE_SECTOR_BUF+$1FF		; check for 0x55AA signature
	cmp		fl0,r1,#$AA
	bne		fl0,spi_eb_err
	pop		r5/r3/r2
	ldi		r1,#0						; r1 = 0, for okay status
	rts
spi_read_boot_err:
	pop		r5/r3/r2
	ldi		r1,#1
	rts
spi_eb_err:
	ldi		r1,#msgNotFoundEB
	bsr		DisplayStringCRLF
	pop		r5/r3/r2
	ldi		r1,#2
	rts

msgFoundEB:
	db	"Found EB code.",0
msgNotFoundEB:
	db	"EB/55AA Code missing.",0


; Load the root directory from disk
; r2 = where to place root directory in memory
;
loadBootFile:
	lbu		r1,BYTE_SECTOR_BUF+BSI_SecPerFAT+1			; sectors per FAT
	shl		r2,r1,#8
	lbu		r1,BYTE_SECTOR_BUF+BSI_SecPerFAT
	or		r1,r2,r1
	brnz	r1,loadBootFile7
	lhu		r1,BYTE_SECTOR_BUF+$24			; sectors per FAT, FAT32
loadBootFile7:
	lbu		r4,BYTE_SECTOR_BUF+$10			; number of FATs
	mul		r3,r1,r4						; offset
	lcu		r1,BYTE_SECTOR_BUF+$E			; r1 = # reserved sectors before FAT
	lbu     r13,BYTE_SECTOR_BUF+$D          ; r13 = sectors per cluster
	add		r3,r3,r1						; r3 = root directory sector number
	lhu		r6,startSector
	add		r5,r3,r6						; r5 = root directory sector number
	lbu     r7,BYTE_SECTOR_BUF+BSI_RootDirEnts
	lbu     r8,BYTE_SECTOR_BUF+BSI_RootDirEnts+1
	shl     r8,r8,#8
	or      r7,r7,r8                        ; r7 = #root directory entries
	; /16 is sector size / directory entry size (512 / 32) = 16
	shru    r7,r7,#4                        ; r7 = #sectors for directory (likely 32)
	add     r8,r7,r5                        ; r8 = start of data area (cluster #2)

; r1= sector number to read
; r2= address to write data
; r3= number of sectors to read
    mov      r1,r5                          ; r1 = root directory sector
    ldi      r2,#ROOTDIR_BUF                ; r2 = where to place directory info
    mov      r3,r7                          ; r3 = number of sectors in roor dir
    bsr      SDReadMultiple                 ; read it

    shl      r7,r7,#4                       ; r7 = # root directory entries
    mov      r3,r7                          ; r3 = # root directory entries
    sub      r3,r3,#1                       ; r3 = count which is one less
    ldi      r2,#ROOTDIR_BUF                ; r2 = where to start search
.0002:
    sb       r0,11[r2]
;    mov      r1,r2
;    bsr      DisplayString
;    bsr      CRLF
    lw       r1,[r2]
    cmp      flg0,r1,#$2020202020534F44     ; look for "DOS"
    bne      flg0,.0001
    lcu      r1,$1A[r2]                     ; r1 = starting cluster
    lhu      r10,$1C[r2]                    ; r10 = size of file
    sub      r1,r1,#2                       ; clusters start at 2
    mul      r9,r1,r13                      ; r9 = clusters to sectors
    add      r9,r9,r8                       ; r9 = starting sector of file
    mov      r1,r9
    ldi      r2,#PROG_LOAD_AREA
    mov      r3,r10
    add      r3,r3,#511                     ; round up to next sector
    shru     r3,r3,#9                       ; divide by sector size (512)
    bsr      SDReadMultiple
    bra      loadBootFile3
.0001:
    add      r2,r2,#32                      ; directory entry size
    dbnz     r3,.0002
    ldi      r1,#msgDOSNotFound
    bsr      DisplayString
    bra      mon1

	;lbu		r1,BYTE_SECTOR_BUF+$D			; sectors per cluster
	add		r3,r7,r5						; r3 = start of data area
	mov     r1,r3
	bsr     DisplayHalf
	bsr     CRLF
	bra		loadBootFile6

loadBootFile6:
	; For now we cheat and just go directly to sector 512.
	bra		loadBootFileTmp

loadBootFileTmp:
	; We load the number of sectors per cluster, then load a single cluster of the file.
	; This is 16kib
	mov		r5,r3							; r5 = start sector of data area	
	ldi		r2,#PROG_LOAD_AREA				; where to place file in memory
	lbu		r3,BYTE_SECTOR_BUF+$D			; sectors per cluster
	mului	r3,r3,#16						; read 16 clusters (256kb)
	sub		r3,r3,#1
loadBootFile1:
	ldi		r1,#'.'
	bsr		DisplayChar
	mov		r1,r5							; r1=sector to read
	bsr		SDReadSector
	add		r5,r5,#1						; r5 = next sector
	add		r2,r2,#512
	dbnz	r3,loadBootFile1
loadBootFile3:
	lhu		r1,PROG_LOAD_AREA		; make sure it's bootable
	cmp		fl0,r1,#$544F4F42
	bne		fl0,loadBootFile2
	ldi		r1,#msgJumpingToBoot
	bsr		DisplayString
	jsr		PROG_LOAD_AREA+$100
	bra		mon1
loadBootFile2:
	ldi		r1,#msgNotBootable
	bsr		DisplayString
	ldi		r2,#PROG_LOAD_AREA
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bra		mon1

msgJumpingToBoot:
	db	"Jumping to boot",0	
msgNotBootable:
	db	"card not bootable.",0
spi_init_ok_msg:
	db "card initialized okay.",0
spi_init_error_msg:
	db	": error occurred initializing the card.",0
spi_boot_error_msg:
	db	"card boot error",CR,LF,0
spi_read_error_msg:
	db	"card read error",CR,LF,0
spi_write_error_msg:
	db	"card write error",0
msgDOSNotFound:
    db  "DOS file not found",CR,LF,0

; ============================================================================
; FMTK: Finitron Multi-Tasking Kernel
;        __
;   \\__/ o\    (C) 2014  Robert Finch, Stratford
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
; ============================================================================
;  
;------------------------------------------------------------------------------
; Initialize the multi-tasking kernel.
;------------------------------------------------------------------------------

FMTKInitialize:
	php
	sei
	ldi		r1,#46
	sb		r1,LEDS
	mfspr	r1,vbr
	ldi		r2,#FMTKScheduler
	sw		r2,2*16[r1]
	ldi		r2,#FMTKTick
	sw		r2,451*16[r1]
	plp

	sw		r0,RunningTCB
	sw		r0,QNdx0
	sw		r0,QNdx0+8
	sw		r0,QNdx0+16	
	sw		r0,QNdx0+24
	sw		r0,QNdx0+32
	sw		r0,QNdx0+40
	sw		r0,QNdx0+48
	sw		r0,QNdx0+56

	ldi		r2,#TCBs			; r2 = pointer to TCB
	ldi		r3,#TCBs+TCB_Size	; r3 = pointer to next TCB
	ldi		r6,#NR_TCB-1		; r6 = counter
	sw		r2,FreeTCB
.0001:
	sw		r3,TCB_Next[r2]
	sw		r0,TCB_Prev[r2]
	sb		r0,TCB_Status[r2]	; status = none
	sb		r0,TCB_hJob[r2]
	ldi		r4,#7
	sb		r4,TCB_Priority[r2]	; lowest priority
	mov		r2,r3				; current = next
	add		r3,r3,#TCB_Size
	dbnz	r6,.0001
	sw		r0,TCB_Next[r2]		; initialize last link

	ldi		r1,#47
	sb		r1,LEDS
	ldi		tr,#TCBs
	ldi		r1,#4
	ldi		r2,#0
	ldi		r3,#Monitor
	ldi		r4,#0
	ldi		r5,#0
	bsr		StartTask
	ldi		r1,#48
	sb		r1,LEDS
	
	rts

IdleTask:
.it1:
	lhu		r199,TEXTSCR+444
	add		r199,r199,#1
	sh		r199,TEXTSCR+444
	jmp		.it1

;------------------------------------------------------------------------------
; Parameters:
;	r1 = priority
;	r2 = flags
;	r3 = start address
;	r4 = parameter
;	r5 = job
;------------------------------------------------------------------------------

StartTask:
	push	r6/r7/r8

	; Get a TCB from the free list
	php
	sei
	ldi		r6,#51
	sb		r6,LEDS
	lw		r6,FreeTCB
	lw		r7,TCB_Next[r6]
	sw		r7,FreeTCB
	plp

	; Initialize the TCB fields
	sb		r1,TCB_Priority[r6]
	sb		r5,TCB_hJob[r6]
	add		r7,r6,#TCB_Size-8
	sub		r7,r7,#24
	ldi		r8,#ExitTask
	and		r8,r8,#-4				; flag: short form address
	sw		r8,16[r7]				; setup exit address on stack
	;and		r2,r2,#$FFFFFFFF		; mask off any extraneous bits
	;sw		r2,16[r7]				; setup flags to pop
	sw		r0,8[r7]				; setup code segment
	and		r3,r3,#-4				; flag:
	or		r3,r3,#0				; interrupt flag
	sw		r3,[r7]					; setup return address (start address)
	sw		r7,TCB_SP0Save[r6]		; save the stack pointer
	mov		r1,r6
	php
	sei
	bsr		AddTaskToReadyList
	plp
	ldi		r6,#54
	sb		r6,LEDS
	brk		#2*16						; reschedule tasks
	pop		r8/r7/r6
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ExitTask:
	sei
	lw		tr,RunningTCB			; refuse to exit the Monitor task
	cmp		fl0,tr,#TCBs
	beq		fl0,.0001
	lw		r6,FreeTCB
	sw		r6,TCB_Next[tr]
	sw		tr,FreeTCB
	sw		r0,RunningTCB
	jmp		SelectTaskToRun
.0001:
	cli
	rts

;------------------------------------------------------------------------------
; Inserts a task into the ready queue at the tail.
;------------------------------------------------------------------------------

AddTaskToReadyList:
	push	r3/r4/r5/r6
	lbu		r3,TCB_Priority[r1]
	and		r3,r3,#7
	shl     r4,r3,#3
	lw		r4,QNdx0[r4]
	brz		r4,.initQ				; is the queue empty ?
	lw		r5,TCB_Prev[r4]
	lw		r6,TCB_Next[r5]
	sw		r1,TCB_Next[r5]
	sw		r1,TCB_Prev[r4]
	sw		r5,TCB_Prev[r1]
	sw		r4,TCB_Next[r1]
	ldi		r4,#TS_READY
	sb		r4,TCB_Status[r1]
	pop		r6/r5/r4/r3
	rts
.initQ:
    shl     r4,r3,#3
	sw		r1,QNdx0[r4]
	sw		r1,TCB_Next[r1]
	sw		r1,TCB_Prev[r1]
	ldi		r4,#TS_READY
	sb		r4,TCB_Status[r1]
	pop		r6/r5/r4/r3
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

RemoveTaskFromReadyList:
	push	r3/r4/r6/r7
	lw		r6,TCB_Next[r1]
	lw		r7,TCB_Prev[r1]
	sw		r7,TCB_Prev[r6]
	sw		r6,TCB_Next[r7]
	lbu		r3,TCB_Priority[r1]
	shl     r4,r3,#3
	lw		r4,QNdx0[r4]
	cmp		fl0,r4,r1
	bne		fl0,.0001
	shl     r4,r3,#3
	sw		r6,QNdx0[r4]
.0001:
	sw		r0,TCB_Next[r1]
	sw		r0,TCB_Prev[r1]
	sb		r0,TCB_Status[r1]
	pop		r7/r6/r4/r3
	rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

FMTKScheduler:
	sei
	ldi		tr,#52
	sb		tr,LEDS
	lw		tr,RunningTCB
	brnz	tr,.0002
	ldi		tr,#TCBs-TCB_Size
.0002:
	;mfspr	r250,cs
	;shr		r250,r250,#60
	sw		sp,TCB_SP0Save[tr]	;+r250*8]
	push	tr
	bsr		SaveContext
	pop		tr
	ldi		r201,#TS_READY
	sb		r201,TCB_Status[tr]
	bra		SelectTaskToRun

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

nStartQue:
	db		0,1,0,2,0,3,0,1,0,4,0,5,0,6,0,7
	db		0,1,0,2,0,3,0,1,0,4,0,5,0,6,0,7

;------------------------------------------------------------------------------
; FMTKTick:
;	Timer tick routine that does the pre-emptive multi-tasking.
;------------------------------------------------------------------------------
;interrupt link register......

FMTKTick:
	ldi		tr,#3				; reset the edge sense circuit
	sh		tr,PIC_RSTE
	lw		tr,TickVec
	brz		tr,.0001
	jsr		(TickVec)
.0001:
	lh		tr,Ticks
	add		tr,tr,#1
	sh		tr,Ticks
	lw		tr,RunningTCB
	brnz	tr,.0002
	ldi		tr,#TCBs-TCB_Size
.0002:
	sw		sp,TCB_SP0Save[tr]
	push	tr
	bsr		SaveContext
	pop		tr
	ldi		r206,#TS_PREEMPT
	sb		r206,TCB_Status[tr]

;------------------------------------------------------------------------------
; SelectTaskToRun:
;
;------------------------------------------------------------------------------

SelectTaskToRun:
	ldi		r201,#53
	sb		r201,LEDS
	lh		r201,Ticks
	and		r201,r201,#$1F
	lb		r203,nStartQue[r201]
	ldi		r206,#7				; number of queues to check - 1
.qagain:
	and		r203,r203,#7			; max 0-7 queues
	shl     r203,r203,#3
	lw		r201,QNdx0[r203]
	brz		r201,.qempty
	lw		tr,TCB_Next[r201]
	sw		tr,QNdx0[r203]
	sw		tr,RunningTCB

	ldi		r206,#TS_RUNNING
	sb		r206,TCB_Status[tr]
	bra		.qxit
.qempty:
    shr     r203,r203,#3
	add		r203,r203,#1
	dbnz	r206,.qagain
	ldi		tr,#TCBs-TCB_Size
	jmp		.qxit
	ldi		r1,#msgNoTasks
	bsr		kernel_panic
.qerr:
	ldi		r250,#$C
	sb		r250,LEDS
	brz		r0,.qerr

.qxit:
	ldi		r201,#$A
	sb		r201,LEDS
	; RestoreContext will modify the task register
	lw		r250,TCB_SP0Save[tr]
	push	r250
	bsr		RestoreContext
	pop		sp
	rti

msgNoTasks:
	db		"No tasks in queue.",0

kernel_panic:
	bsr		DisplayString
	rts

;------------------------------------------------------------------------------
; Save the task context. The context is saved in blocks of 16 registers at
; a time in order to minimize interrupt latency.
;------------------------------------------------------------------------------

SaveContext:
	push	tr
	smr		r1,r15,[tr]
	add		tr,tr,#15*8
	smr		r16,r31,[tr]
	add		tr,tr,#16*8
	smr		r32,r47,[tr]
	add		tr,tr,#16*8
	smr		r48,r63,[tr]
	add		tr,tr,#16*8
	smr		r64,r79,[tr]
	add		tr,tr,#16*8
	smr		r80,r95,[tr]
	add		tr,tr,#16*8
	smr		r96,r111,[tr]
	add		tr,tr,#16*8
	smr		r112,r127,[tr]
	add		tr,tr,#16*8
	smr		r128,r143,[tr]
	add		tr,tr,#16*8
	smr		r144,r159,[tr]
	add		tr,tr,#16*8
	smr		r160,r175,[tr]
	add		tr,tr,#16*8
	smr		r176,r191,[tr]
	add		tr,tr,#16*8
	smr		r192,r207,[tr]
	add		tr,tr,#16*8
	smr		r208,r223,[tr]
	add		tr,tr,#16*8
	smr		r224,r239,[tr]
	add		tr,tr,#16*8
	smr		r240,r254,[tr]
	add		tr,tr,#15*8
	pop		tr

	rts

;------------------------------------------------------------------------------
; Restore the task context. The context is saved in blocks of 16 registers at
; a time in otder to minimize interrupt latency.
;------------------------------------------------------------------------------

RestoreContext:
	lmr		r1,r15,[tr]
	add		tr,tr,#15*8
	lmr		r16,r31,[tr]
	add		tr,tr,#16*8
	lmr		r32,r47,[tr]
	add		tr,tr,#16*8
	lmr		r48,r63,[tr]
	add		tr,tr,#16*8
	lmr		r64,r79,[tr]
	add		tr,tr,#16*8
	lmr		r80,r95,[tr]
	add		tr,tr,#16*8
	lmr		r96,r111,[tr]
	add		tr,tr,#16*8
	lmr		r112,r127,[tr]
	add		tr,tr,#16*8
	lmr		r128,r143,[tr]
	add		tr,tr,#16*8
	lmr		r144,r159,[tr]
	add		tr,tr,#16*8
	lmr		r160,r175,[tr]
	add		tr,tr,#16*8
	lmr		r176,r191,[tr]
	add		tr,tr,#16*8
	lmr		r192,r207,[tr]
	add		tr,tr,#16*8
	lmr		r208,r223,[tr]
	add		tr,tr,#16*8
	lmr		r224,r239,[tr]
	add		tr,tr,#16*8
	lmr		r240,r251,[tr]
	add		tr,tr,#12*8
	lw		r253,8[tr]
	rts

;------------------------------------------------------------------------------
; Test RAM using checkerboard pattern.
;------------------------------------------------------------------------------

RAMTest:
	bsr		CRLF
	ldi		r1,$10000				; start past the ROM
	ldi		r2,#$AAAAAAAA55555555	; Checkerboard pattern
	
	; First store the checkerboard pattern to all memory locations
.0002:
	sw		r2,[r1]
	andi	r3,r1,#$FFF				; display progress and check
	brnz	r3,.0001				; for CTRL-C every so often
	bsr		DisplayHalf
	mov		r4,r1
	ldi		r1,#CR
	bsr		DisplayChar
	bsr		KeybdGetCharDirectNB
	sub		r1,r1,#CTRLC
	brz		r1,.0006
	mov		r1,r4
.0001:
	addi	r1,r1,#8				; increment to next word
	cmp		flg0,r1,#$0800000		; 128MB is the RAM onboard
	bltu	flg0,.0002
	
	; Readback the checkboard pattern from all memory locations
	ldi		r1,#$10000
.0005:
	lw		r2,[r1]
	cmp		flg0,r2,#$AAAAAAAA55555555
	beq		flg0,.0003
	bsr		DisplayHalf
	bsr		CRLF
.0003:
	andi	r3,r1,#$FFF			; display progress and check
	brnz	r3,.0004			; for CTRL-C every so often
	bsr		DisplayHalf
	mov		r4,r1
	ldi		r1,#CR
	bsr		DisplayChar
	bsr		KeybdGetCharDirectNB
	sub		r1,r1,#CTRLC
	brz		r1,.0006
	mov		r1,r4
.0004:
	addi	r1,r1,#8			; increment to next word
	cmp		flg0,r1,#$0800000
	bltu	flg0,.0005
.0006:
	rts

;------------------------------------------------------------------------------
; An uninitialized interrupt occurred. Display the vector number and the
; interrupt address.
;------------------------------------------------------------------------------

uninit_rout:
	ldi		r1,#$ba
	sb		r1,LEDS
	ldi		r1,#msgUninit
	bsr		DisplayStringCRLF
	mfspr	r1,ivno
	bsr		DisplayHalf
	bsr		CRLF
	pop		r1
	bsr		DisplayHalf
	bsr		CRLF
	ldi		r3,#63
.0002:
	mfspr	r1,history
	bsr		DisplayHalf
	ldi		r1,#' '
	bsr		DisplayChar
	dbnz	r3,.0002
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Execution fault. Occurs when an attempt is made to execute code from a
; page marked as non-executable.
;------------------------------------------------------------------------------

exf_rout:
	ldi		r1,#$bb
	sb		r1,LEDS
	ldi		r1,#msgexf
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Data read fault. Occurs when an attempt is made to read from a page marked
; as non-readble.
;------------------------------------------------------------------------------

drf_rout:
	ldi		r1,#$bb
	sb		r1,LEDS
	ldi		r1,#msgdrf
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Data write fault. Occurs when an attempt is made to write to a page marked
; as non-writeable.
;------------------------------------------------------------------------------

dwf_rout:
	ldi		r1,#$bb
	sb		r1,LEDS
	ldi		r1,#msgdwf
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Segment bounds violation fault.
;------------------------------------------------------------------------------

sbv_rout:
	ldi		r1,#$bb
	sb		r1,LEDS
	ldi		r1,#msgSBV
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Privilege violation fault. Occurs when the current privilege level isn't
; sufficient to allow access.
;------------------------------------------------------------------------------

priv_rout:
	ldi		r1,#$bc
	st		r1,LEDS
	ldi		r1,#msgPriv
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Segment type violation. Occurs when an attempt is made to load a data
; segment into the code segment or the code segment into a data segment
; register.
;------------------------------------------------------------------------------

stv_rout:
	ldi		r1,#$bd
	sb		r1,LEDS
	ldi		r1,#msgSTV
	bsr		DisplayStringCRLF
	mfspr	r1,fault_pc
	bsr		DisplayWord
	bsr		CRLF
	mfspr	r1,fault_cs
	bsr		DisplayHalf
	bsr		CRLF
	mfspr	r1,fault_seg
	bsr		DisplayHalf
	bsr		CRLF
	mfspr	r1,fault_st
	bsr		DisplayByte
	bsr		CRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Segment not present. Occurs when the segment is marked as not present in
; memory.
;------------------------------------------------------------------------------

snp_rout:
	ldi		r1,#$be
	sb		r1,LEDS
	ldi		r1,#msgSNP
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Message strings for the faults.
;------------------------------------------------------------------------------

msgexf:
	db	"exf ",0
msgdrf:
	db	"drf ",0
msgdwf:
	db	"dwf ",0
msgSBV:
	db	"sbv fault",0
msgPriv:
	db	"priv fault",0
msgSTV:
	db	"stv fault",0
msgSNP:
	db	"snp fault",0
msgUninit:
	db	"uninit int.",0

;------------------------------------------------------------------------------
; Bus error routine.
;------------------------------------------------------------------------------

berr_rout:
	ldi		r1,#$AA
	st		r1,LEDS
	mfspr	r1,bear
;	bsr		DisplayWord
.be1:
	bra .be1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

AlgnFault:
	ldi		r1,#$AF
	sw		r1,LEDS
	bra AlgnFault

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DebugRout:
	ldi		r1,#$DB
	sw		r1,LEDS
	bra DebugRout

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	org		$0000FFB0		; Alignment fault
	bra AlgnFault

	org		$0000FFC0		; debug vector
	bra DebugRout

	org		$0000FFE0		; NMI vector
	rti

	org		$0000FFF0
	jmp		start
