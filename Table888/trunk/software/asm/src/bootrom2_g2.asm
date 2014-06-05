; ============================================================================
; bootrom2.asm
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

SECTOR_BUF	EQU		0x06FFB000

BYTE_SECTOR_BUF	EQU	SECTOR_BUF
PROG_LOAD_AREA	EQU		0x1800000

IDTBaseAddress	EQU		$7EFF000
GDTBaseAddress	EQU		$7F01000
TSSBaseAddress	EQU		$7C08000

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
E_NoMoreAlarmBlks	=0x44
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
SPI_TRANS_ERROR_REG		EQU	0x11
SPI_DIRECT_ACCESS_DATA_REG		EQU	0x12
SPI_SD_SECT_7_0_REG		EQU	0x13
SPI_SD_SECT_15_8_REG	EQU	0x14
SPI_SD_SECT_23_16_REG	EQU	0x15
SPI_SD_SECT_31_24_REG	EQU	0x16
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
CursorRow		db		0
CursorCol		db		0
NormAttr		dc		0
KeybdEcho		db		0
KeybdBad		db		0
KeybdLocks		dc		0
startSector		dh		0
disk_size		dh		0

	org		$07C00000
TCBs:
	fill.b	TCB_Size * NR_TCB,0

	code
	org		$00008000
start:
	sei
;	icache_on
	nop
	ldi		r1,#$FF
	sb		r1,LEDS
	lidt	IDTAddrRec
	lgdt	GDTAddrRec
	ldi		r1,#$F000000000000000	; base, DPL=15
	ldi		r2,#$92FFFFFFFFFFFFFF	; limit, present, writeable data segment
	ldi		r3,#300
	ldi		r4,#GDTBaseAddress
.st1:
	sw		r1,[r4]
	sw		r2,8[r4]
	add		r4,r4,#16
	dbnz	r3,.st1
	ldi		r1,#$FE
	sb		r1,LEDS

	; setup code segment
	ldi		r4,#GDTBaseAddress+$10
	ldi		r1,#$0000000000000000	; base, DPL=0
	ldi		r2,#$9A00000007FFFFFF
	sw		r1,[r4]
	sw		r2,8[r4]

	; setup I/O segment
	ldi		r4,#GDTBaseAddress+$40
	ldi		r1,#$F000000000000000
	ldi		r2,#$92FFFFFFFFFFFFFF
	sw		r1,[r4]
	sw		r2,8[r4]

	ldi		r4,#GDTBaseAddress+$F0
	ldi		r1,#$0000000007BFE000	; temporary tss
	sw		r1,[r4]
	
	; setup TSS segments
	ldi		r3,#255
	ldi		r4,#GDTBaseAddress+$100
	ldi		r1,#$F000000000000000
	ldi		r2,#$92FFFFFFFFFFFFFF
.st2:
	sw		r1,[r4]					; set base
	sw		r2,8[r4]				; set limit
	add		r4,r4,#16
	dbnz	r3,.st2
	ldi		r1,#$FD
	sb		r1,LEDS

	; setup cs,ds,ss
	ldi		r1,#$010000000000
	mtseg	cs,r1
	ldi		r1,#$020000000000
	mtseg	ds,r1
	ldi		r1,#$030000000000
	mtseg	ss,r1
	ldi		r1,#$040000000000
	mtseg	es,r1
	ldi		r1,#$020000000000
	mtseg	tss,r1
	;prot

	ldi		r1,#$FC
	sb		r1,LEDS

	ldi		sp,#$07EFEFF8			; load the stack pointer at the top of memory
									
	sw		r0,Milliseconds
	ldi		r1,#$CE
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	sc		r1,NormAttr
	sb		r0,CursorRow
	sb		r0,CursorCol
	bsr		ClearScreen
;	mfseg	r1,cs
;	or		r1,r1,#DisplayChar
	ldi		r1,#DisplayChar
	and		r1,r1,#-4			; clear the two LSB's to indicate short format
	sw		r1,OutputVec
	bsr		SetupIntVectors
	bsr		KeybdInit
	bsr		InitPIC
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
	es:lh	r1,TEXTSCR+444
	add		r1,r1,#1
	es:sh	r1,TEXTSCR+444
	bra		r0,j1
	
DispLed:
	lw		r1,8[sp]
	sb		r1,LEDS
	rts		#8

	align	16
IDTAddrRec:
	dw		IDTBaseAddress
	dw		$fff
GDTAddrRec:
	dw		GDTBaseAddress
	dw		$00FFFFF

;------------------------------------------------------------------------------
; Setup the interrupt vector for the system.
;------------------------------------------------------------------------------

SetupIntVectors:
	php
	sei
	ldi		r2,#IDTBaseAddress
	; Initialize all vectors to uninitialized interrupt routine vector
	ldi		r3,#511
	ldi		r1,#$8600000100000000+uninit_rout
.siv1:
	; setup specific vectors
	sw		r1,[r2+r3*8]
	dbnz	r3,.siv1	
	ldi		r1,#$8600000100000000+berr_rout
	sw		r1,508*8[r2]
	ldi		r1,#$8600000100000000+sbv_rout
	sw		r1,500*8[r2]
	ldi		r1,#$8600000100000000+priv_rout
	sw		r1,501*8[r2]
	ldi		r1,#$8600000100000000+stv_rout
	sw		r1,502*8[r2]
	ldi		r1,#$8600000100000000+snp_rout
	sw		r1,503*8[r2]
	ldi		r1,#$8600000100000000+start
	sw		r1,449*8[r2]
	ldi		r1,#$8600000100000000+Tick1000Rout
	sw		r1,450*8[r2]
	ldi		r1,#$8600000100000000+KeybdIRQ
	sw		r1,463*8[r2]
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
	es:sc	r0,TEXTREG+TEXT_CURPOS
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ClearScreen:
	push	r1/r2/r3/r4
	push	r5
	ldi		r1,#$5
	sb		r1,LEDS
	es:lbu	r1,TEXTREG+TEXT_COLS
	es:lbu	r2,TEXTREG+TEXT_ROWS
	mulu	r4,r2,r1
	ldi		r4,#1735
	ldi		r3,#TEXTSCR
	ldi		r5,#$10000
	ldi		r1,#' '
	bsr		AsciiToScreen
	ldi		r2,#$CE
.cs1:
	es:sh	r1,[r3]
	es:sh	r2,[r3+r5]
	addui	r3,r3,#4
	dbnz	r4,.cs1
	pop		r5
	pop		r4/r3/r2/r1
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
	es:lh	tr,TEXTSCR+220
	add		tr,tr,#1
	es:sh	tr,TEXTSCR+220
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
GetColorCodeLocation
	ldi		r1,#TEXTSCR+$10000
	rts
GetCurrAttr:
	lcu		r1,NormAttr
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

UpdateCursorPos:
	push	r1/r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	es:lbu	r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	es:sc	r2,TEXTREG+TEXT_CURPOS
	pop		r4/r2/r1
	rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

CalcScreenLoc:
	push	r2/r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	es:lbu	r2,TEXTREG+TEXT_COLS
	mul		r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	add		r2,r2,r1
	es:sc	r2,TEXTREG+TEXT_CURPOS
	bsr		GetScreenLocation
	shl		r2,r2,#2
	add		r1,r1,r2
	pop		r4/r2
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DisplayChar:
	push	r1/r2/r3/r4
	ldi		r4,#$040000000000
	mtseg	es,r4
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
	es:sc	r1,[r3]
	bsr		GetScreenLocation
	sub		r3,r3,r1
	bsr		GetColorCodeLocation
	add		r3,r3,r1
	bsr		GetCurrAttr
	es:sc	r1,[r3]
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
	bra		r0,.dcx7
.doCursorLeft:
	lbu		r1,CursorCol
	brz		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorCol
	bra		r0,.dcx7
.doCursorDown:
	lbu		r1,CursorRow
	add		r1,r1,#1
	cmp		fl0,r1,#31
	bhs		fl0,.dcx7
	sb		r1,CursorRow
	bra		r0,.dcx7
.doCursorHome:
	lbu		r1,CursorCol
	brz		r1,.dcx12
	sb		r0,CursorCol
	bra		r0,.dcx7
.dcx12:
	sb		r0,CursorRow
	bra		r0,.dcx7
.doDelete:
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
	bra		r0,.dcx5
.doBackspace:
	lbu		r1,CursorCol
	brz		r1,.dcx4
	sub		r1,r1,#1
	sb		r1,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
.dcx5:
	es:lcu	r2,4[r3]
	es:sc	r2,[r3]
	add		r3,r3,#4
	add		r1,r1,#1
	cmp		fl0,r1,#56
	blo		fl0,.dcx5
	ldi		r1,#' '
	bsr		AsciiToScreen
	sub		r3,r3,#4
	es:sc	r1,[r3]
	bra		r0,.dcx4
.doLinefeed:
	bsr		IncCursorRow
	bra		r0,.dcx4


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
	bra		r0,icr1
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
	es:lbu	r1,TEXTREG+TEXT_COLS
	es:lbu	r2,TEXTREG+TEXT_ROWS
	sub		r2,r2,#1
	mul		r6,r1,r2
	ldi		r1,#TEXTSCR
	ldi		r2,#TEXTSCR+224
	ldi		r3,#0
.0001:
	es:lc	r5,[r2+r3*4]
	es:sc	r5,[r1+r3*4]
	es:lc	r5,$10000[r2+r3*4]
	es:sc	r5,$10000[r1+r3*4]
	add		r3,r3,#1
	dbnz	r6,.0001
	es:lbu	r1,TEXTREG+TEXT_ROWS
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
	es:lbu	r2,TEXTREG+TEXT_COLS
	mul		r3,r2,r1
	sub		r2,r2,#1		; r2 = #chars to blank - 1
	shl		r3,r3,#2
	add		r3,r3,#TEXTSCR
	ldi		r1,#' '
	bsr		AsciiToScreen
	lcu		r4,NormAttr
.0001:	
	es:sc	r1,[r3+r2*4]
	es:sc	r4,$10000[r3+r2*4]
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
	ldi		r1,#7
	ldi		r2,#0
	ldi		r3,#IdleTask
	ldi		r4,#0
	ldi		r5,#0
	bsr		StartTask
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
	bra		r0,.Prompt3
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
	bra		r0,mon1

.doHelp:
	ldi		r1,#msgHelp
	bsr		DisplayString
	bra		r0,mon1

MonGetch:
	es:lcu	r1,[r3]
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
	bra		r0,mon1

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
	ldi		r1,#%0111000110	; reverse video
	sc		r1,NormAttr
	ldi		r3,#7
	sub		r2,r2,#8
.002
	lbu		r1,[r2]
	cmp		fl0,r1,#26				; convert control characters to '.'
	bhs		fl0,.004
	ldi		r1,#'.'
	bra		r0,.003
.004:
	cmp		fl0,r1,#$80				; convert other non-ascii to '.'
	blo		fl0,.003
	ldi		r1,#'.'
.003:
	bsr		OutChar
	add		r2,r2,#1
	dbnz	r3,.002
	ldi		r1,#$CE
	sc		r1,NormAttr
	bsr		CRLF
	pop		r3/r1
	rts

;------------------------------------------------------------------------------
; CheckKeys:
;	Checks for a CTRLC or a scroll lock during long running dumps.
;------------------------------------------------------------------------------

CheckKeys:
	bsr		CTRLCCheck
	bra		r0,CheckScrollLock

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
	bra		r0,mon1

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
	bra		r0,.0002
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
	bra		r0,mon1

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
	bra		r0,mon1

KEYBD_DELAY		EQU		100

KeybdGetCharDirectNB:
	push	r2
	sei
	lcu		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	cli
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.0002
	cmp		fl0,r1,#CR
	bne		fl0,.0003
	bsr		CRLF
	bra		r0,.0002
.0003:
	jsr		(OutputVec)
.0002:
	pop		r2
	rts
.0001:
	cli
	ldi		r1,#-1
	pop		r2
	rts

KeybdGetCharDirect:
	push	r2
.0001:
	lc		r1,KEYBD
	and		fl0,r1,#$8000
	brz		fl0,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	and		fl0,r1,#$800	; is it keydown ?
	brnz	fl0,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	brz		r2,.gk1
	cmp		fl0,r1,#CR
	bne		fl0,.gk2
	bsr		CRLF
	bra		r0,.gk1
.gk2:
	jsr		(OutputVec)
.gk1:
	pop		r2
	rts

KeybdInit:
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
	bra		r0,sbtk1
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
	bra		r0,sbtk1

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
	sw		r3,$100000[r0+r3*8]
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
	ldi		r1,#SPI_INIT_SD
	sb		r1,SPIMASTER+SPI_TRANS_TYPE_REG
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPIMASTER+SPI_TRANS_CTRL_REG
	nop
.spi_init1
	lbu		r1,SPIMASTER+SPI_TRANS_STATUS_REG
	nop
	nop
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_init1
	lbu		r1,SPIMASTER+SPI_TRANS_ERROR_REG
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_INIT_NO_ERROR
	bne		fl0,spi_error
;	lda		#spi_init_ok_msg
;	jsr		DisplayStringB
	ldi		r1,#E_Ok
	rts
spi_error
	bsr		DisplayByte
	ldi		r1,#spi_init_error_msg
	bsr		DisplayString
	lbu		r1,SPIMASTER+SPI_RESP_BYTE1
	bsr		DisplayByte
	lbu		r1,SPIMASTER+SPI_RESP_BYTE2
	bsr		DisplayByte
	lbu		r1,SPIMASTER+SPI_RESP_BYTE3
	bsr		DisplayByte
	lbu		r1,SPIMASTER+SPI_RESP_BYTE4
	bsr		DisplayByte
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
	push	r2/r3/r4
	
	sb		r1,SPIMASTER+SPI_SD_SECT_7_0_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_15_8_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_23_16_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_31_24_REG

	ldi		r4,#19	; retry count

.spi_read_retry:
	; Force the reciever fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	ldi		r1,#1
	sb		r1,SPIMASTER+SPI_RX_FIFO_CTRL_REG

	ldi		r1,#RW_READ_SD_BLOCK
	sb		r1,SPIMASTER+SPI_TRANS_TYPE_REG
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPIMASTER+SPI_TRANS_CTRL_REG
	nop
.spi_read_sect1:
	lbu		r1,SPIMASTER+SPI_TRANS_STATUS_REG
	bsr		spi_delay			; just a delay between consecutive status reg reads
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_read_sect1
	lbu		r1,SPIMASTER+SPI_TRANS_ERROR_REG
	shr		r1,r1,#2
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_READ_NO_ERROR
	bne		fl0,.spi_read_error
	ldi		r3,#511		; read 512 bytes from fifo
.spi_read_sect2:
	lbu		r1,SPIMASTER+SPI_RX_FIFO_DATA_REG
	sb		r1,[r2]
	add		r2,r2,#1
	dbnz	r3,.spi_read_sect2
	ldi		r1,#0
	bra		r0,.spi_read_ret
.spi_read_error:
	dbnz	r4,.spi_read_retry
	bsr		DisplayByte
	ldi		r1,#spi_read_error_msg
	bsr		DisplayString
	ldi		r1,#1
.spi_read_ret:
	pop		r4/r3/r2
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
	push	r2/r3/r1
	; Force the transmitter fifo to be empty, in case a prior error leaves it
	; in an unknown state.
	ldi		r1,#1
	sb		r1,SPIMASTER+SPI_TX_FIFO_CTRL_REG
	nop			; give I/O time to respond
	nop

	; now fill up the transmitter fifo
	ldi		r3,#511
.spi_write_sect1:
	lbu		r1,[r2]
	sb		r1,SPIMASTER+SPI_TX_FIFO_DATA_REG
	nop			; give the I/O time to respond
	nop
	add		r2,r2,#1
	dbnz	r3,.spi_write_sect1

	; set the sector number in the spi master address registers
	pop		r1
	sb		r1,SPIMASTER+SPI_SD_SECT_7_0_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_15_8_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_23_16_REG
	shr		r1,r1,#8
	sb		r1,SPIMASTER+SPI_SD_SECT_31_24_REG

	; issue the write command
	ldi		r1,#RW_WRITE_SD_BLOCK
	sb		r1,SPIMASTER+SPI_TRANS_TYPE_REG
	ldi		r1,#SPI_TRANS_START
	sb		r1,SPIMASTER+SPI_TRANS_CTRL_REG
	nop
.spi_write_sect2:
	lbu		r1,SPIMASTER+SPI_TRANS_STATUS_REG
	nop							; just a delay between consecutive status reg reads
	nop
	cmp		fl0,r1,#SPI_TRANS_BUSY
	beq		fl0,.spi_write_sect2
	lbu		r1,SPIMASTER+SPI_TRANS_ERROR_REG
	shr		r1,r1,#4
	and		r1,r1,#3
	cmp		fl0,r1,#SPI_WRITE_NO_ERROR
	bne		fl0,.spi_write_error
	ldi		r1,#0
	bra		r0,.spi_write_ret
.spi_write_error:
	bsr		DisplayByte
	ldi		r1,#spi_write_error_msg
	bsr		DisplayString
	ldi		r1,#1

.spi_write_ret:
	pop		r3/r2
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
; SPI write multiple sector
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
	lcu		r1,BYTE_SECTOR_BUF+$1CC
	lcu		r3,BYTE_SECTOR_BUF+$1CA
	shl		r1,r1,#16
	or		r1,r1,r3
	sh		r1,disk_size					; r1 = 0, for okay status
	pop		r3/r2
	ldi		r1,#0
	rts
.spi_rp1:
	pop		r3/r2
	ldi		r1,#1
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
	add		r3,r3,r1						; r3 = root directory sector number
	lhu		r6,startSector
	add		r5,r3,r6						; r5 = root directory sector number
	lbu		r1,BYTE_SECTOR_BUF+$D			; sectors per cluster
	add		r3,r1,r5						; r3 = first cluster after first cluster of directory
	bra		r0,loadBootFile6

loadBootFile6:
	; For now we cheat and just go directly to sector 512.
	bra		r0,loadBootFileTmp

loadBootFileTmp:
	; We load the number of sectors per cluster, then load a single cluster of the file.
	; This is 16kib
	mov		r5,r3							; r5 = start sector of data area	
	ldi		r2,#PROG_LOAD_AREA				; where to place file in memory
	lbu		r3,BYTE_SECTOR_BUF+$D			; sectors per cluster
	sub		r3,r3,#1
loadBootFile1:
	mov		r1,r5							; r1=sector to read
	bsr		SDReadSector
	add		r5,r5,#1						; r5 = next sector
	add		r2,r2,#512
	dbnz	r3,loadBootFile1
	lhu		r1,PROG_LOAD_AREA		; make sure it's bootable
	cmp		fl0,r1,#$544F4F42
	bne		fl0,loadBootFile2
	ldi		r1,#msgJumpingToBoot
	bsr		DisplayString
	jsr		PROG_LOAD_AREA + $100
	bra		r0,mon1
loadBootFile2:
	ldi		r1,#msgNotBootable
	bsr		DisplayString
	ldi		r2,#PROG_LOAD_AREA
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bsr		DisplayMemBytes
	bra		r0,mon1

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
;	mfspr	r1,vbr
	ldi		r1,#IDTBaseAddress
	ldi		r2,#$8600000100000000+FMTKScheduler
	sw		r2,2*8[r1]
	ldi		r2,#$8600000100000000+FMTKTick
	sw		r2,451*8[r1]

;	ldi		r2,#FMTKScheduler*256+$50
;	sw		r2,2*16[r1]
;	cinv	r0,2*16[r1]
;	ldi		r2,#FMTKTick*256+$50
;	sw		r2,451*16[r1]
;	sw		r0,451*16+8[r1]
;	cinv	r0,451*16[r1]
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
	mfseg	r3,cs
	or		r3,r3,#Monitor
	ldi		r4,#0
	ldi		r5,#0
	bsr		StartTask
	ldi		r1,#48
	sb		r1,LEDS
	
	rts

IdleTask:
.it1:
	es:lcu	r199,TEXTSCR+444
	add		r199,r199,#1
	es:sc	r199,TEXTSCR+444
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
	; setup the segment registers
	ldi		r1,#$020000000000
	sw		r1,TCB_Seg1Save[r6]
	sw		r1,TCB_Seg2Save[r6]
	sw		r1,TCB_Seg3Save[r6]
	sw		r1,TCB_Seg4Save[r6]
	ldi		r1,#$040000000000
	sw		r1,TCB_Seg5Save[r6]
	ldi		r1,#$020000000000
	sw		r1,TCB_Seg6Save[r6]
	sw		r1,TCB_Seg7Save[r6]
	sw		r1,TCB_Seg8Save[r6]
	sw		r1,TCB_Seg9Save[r6]
	sw		r1,TCB_Seg10Save[r6]
	sw		r1,TCB_Seg11Save[r6]
	sw		r1,TCB_Seg12Save[r6]
	sw		r1,TCB_Seg13Save[r6]
	ldi		r1,#$030000000000
	sw		r1,TCB_Seg14Save[r6]
	ldi		r1,#$010000000000
	sw		r1,TCB_Seg15Save[r6]
	add		r7,r6,#TCB_Size-8
	sub		r7,r7,#24
	ldi		r8,#ExitTask
	and		r8,r8#-4				; flag: short form address
	sw		r8,16[r7]				; setup exit address on stack
	and		r2,r2,#$FFFFFFFF		; mask off any extraneous bits
	mfseg	r1,cs					; put the code segment into the code segment field
	or		r2,r2,r1
	sw		r2,8[r7]				; setup flags to pop
	or		r3,r3,#3				; flag long format address
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
	lw		r4,QNdx0[r0+r3*8]
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
	sw		r1,QNdx0[r0+r3*8]
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
	lw		r4,QNdx0[r0+r3*8]
	cmp		fl0,r4,r1
	bne		fl0,.0001
	sw		r6,QNdx0[r0+r3*8]
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
	mfseg	r250,cs
	shr		r250,r250,#60
	sw		sp,TCB_SP0Save[tr+r250*8]
	push	tr
	bsr		SaveContext
	pop		tr
	ldi		r201,#TS_READY
	sb		r201,TCB_Status[tr]
	bra		r0,SelectTaskToRun

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
	mfseg	r250,cs
	shr		r250,r250,#60
	sw		sp,TCB_SP0Save[tr+r250*8]
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
	lw		r201,QNdx0[r0+r203*8]
	brz		r201,.qempty
	lw		tr,TCB_Next[r201]
	sw		tr,QNdx0[r0+r203*8]
	sw		tr,RunningTCB

	ldi		r206,#TS_RUNNING
	sb		r206,TCB_Status[tr]
	bra		r0,.qxit
.qempty:
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
	mfseg	r250,cs
	shr		r250,r250,#60
	lw		r250,TCB_SP0Save[tr+r250*8]
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

	mfseg	r1,seg1
	sw		r1,TCB_Seg1Save[tr]
	mfseg	r1,seg2
	sw		r1,TCB_Seg2Save[tr]
	mfseg	r1,seg3
	sw		r1,TCB_Seg3Save[tr]
	mfseg	r1,seg4
	sw		r1,TCB_Seg4Save[tr]
	mfseg	r1,seg5
	sw		r1,TCB_Seg5Save[tr]
	mfseg	r1,seg6
	sw		r1,TCB_Seg6Save[tr]
	mfseg	r1,seg7
	sw		r1,TCB_Seg7Save[tr]
	mfseg	r1,seg8
	sw		r1,TCB_Seg8Save[tr]
	mfseg	r1,seg9
	sw		r1,TCB_Seg9Save[tr]
	mfseg	r1,seg10
	sw		r1,TCB_Seg10Save[tr]
	mfseg	r1,seg11
	sw		r1,TCB_Seg11Save[tr]
	mfseg	r1,seg12
	sw		r1,TCB_Seg12Save[tr]
	mfseg	r1,seg13
	sw		r1,TCB_Seg13Save[tr]
	mfseg	r1,seg14
	sw		r1,TCB_Seg14Save[tr]
	mfseg	r1,seg15
	sw		r1,TCB_Seg15Save[tr]

	rts

;------------------------------------------------------------------------------
; Restore the task context. The context is saved in blocks of 16 registers at
; a time in otder to minimize interrupt latency.
;------------------------------------------------------------------------------

RestoreContext:
	lw		r1,TCB_Seg1Save[tr]
	mtseg	seg1,r1
	lw		r1,TCB_Seg2Save[tr]
	;mtseg	seg2,r1
	lw		r1,TCB_Seg3Save[tr]
	;mtseg	seg3,r1
	lw		r1,TCB_Seg4Save[tr]
	;mtseg	seg4,r1
	lw		r1,TCB_Seg5Save[tr]
	mtseg	seg5,r1
	lw		r1,TCB_Seg6Save[tr]
	;mtseg	seg6,r1
	lw		r1,TCB_Seg7Save[tr]
	;mtseg	seg7,r1
	lw		r1,TCB_Seg8Save[tr]
	;mtseg	seg8,r1
	lw		r1,TCB_Seg9Save[tr]
	;mtseg	seg9,r1
	lw		r1,TCB_Seg10Save[tr]
	;mtseg	seg10,r1
	lw		r1,TCB_Seg11Save[tr]
	;mtseg	seg11,r1
	lw		r1,TCB_Seg13Save[tr]
	;mtseg	seg13,r1
	;lw		r1,TCB_Seg14Save[tr]
	;mtseg	seg14,r1

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

SomeCallgateFn:
	lw		r251,[sp]					; get return address

	; First, save the current stack pointer and segment
	shr		r250,r251,#60				; get originating privilege level

	; The stack pointer will be invalid for a little bit, so disable interrupts
	sei
	sw		sp,TCB_SP0Save[tr+r250*8]	; save original stack pointer
	mfseg	sp,ss
	sw		sp,TCB_SS0Save[tr+r250*8]

	; Second, setup a stack at this privilege level
	mfseg	r250,cs						; get the current privilege level from the cs selector
	shr		r250,r250,#60
	lw		sp,TCB_SS0Save[tr+r250*8]
	mtseg	ss,sp
	lw		sp,TCB_SP0Save[tr+r250*8]	; get stack pointer according to privilege level
	cli
	push	r251

	;...
	;now use the stack
	;...

	; Save the current stack back, if needed (may not be necessary)
	mfseg	r250,cs						; get current privilege level
	shr		r250,r250,#60
	sw		sp,TCB_SP0Save[tr+r250*8]	; store the stack pointer in the tss.
	mfseg	r249,ss
	sw		r249,TCB_SS0Save[tr+r250*8]	; store stack segment in tss

	; load back the original stack
	pop		r251
	shr		r250,r251,#60				; get originating privilege level
	sei
	lw		sp,TCB_SS0Save[tr+r250*8]	; get back segment register
	mtseg	ss,sp
	lw		sp,TCB_SP0Save[tr+r250*8]	; get appropriate stack pointer from tss
	cli

	rts									; return to caller

uninit_rout:
	ldi		r1,#$ba
	st		r1,LEDS
	ldi		r1,#msgUninit
	bsr		DisplayStringCRLF
.0001:
	bra		r0,.0001
sbv_rout:
	ldi		r1,#$bb
	st		r1,LEDS
	ldi		r1,#msgSBV
	bsr		DisplayStringCRLF
.0001:
	bra		r0,.0001
priv_rout:
	ldi		r1,#$bc
	st		r1,LEDS
	ldi		r1,#msgPriv
	bsr		DisplayStringCRLF
.0001:
	bra		r0,.0001
stv_rout:
	ldi		r1,#$bd
	st		r1,LEDS
	ldi		r1,#msgSTV
	bsr		DisplayStringCRLF
	mfspr	r1,fault_pc
	bsr		DisplayWord
	bsr		CRLF
	mfspr	r1,fault_cs
	bsr		DisplayHalf
.0001:
	bra		r0,.0001
snp_rout:
	ldi		r1,#$be
	st		r1,LEDS
	ldi		r1,#msgSNP
	bsr		DisplayStringCRLF
.0001:
	bra		r0,.0001

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
	bra		r0,.be1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

AlgnFault:
	ldi		r1,#$AF
	sw		r1,LEDS
	bra		r0,AlgnFault

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DebugRout:
	ldi		r1,#$DB
	sw		r1,LEDS
	bra		r0,DebugRout

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	org		$0000FFB0		; Alignment fault
	bra		r0,AlgnFault

	org		$0000FFC0		; debug vector
	bra		r0,DebugRout

	org		$0000FFE0		; NMI vector
	rti

	org		$0000FFF0
	jmp		start
