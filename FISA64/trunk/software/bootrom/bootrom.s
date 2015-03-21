; ============================================================================
; bootrom.s
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
TXTCOLS		EQU		84
TXTROWS		EQU		31

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

; The following offsets in the I/O segment
TEXTSCR	equ		$00000
TEXTREG		EQU		$A0000
TEXT_COLS	EQU		0x00
TEXT_ROWS	EQU		0x04
TEXT_CURPOS	EQU		0x2C
TEXT_CURCTL	EQU		0x20

BMP_CLUT	EQU		$C5800

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

NR_TCB		EQU		16
TCB_BackLink    EQU     0
TCB_Regs		EQU		8
TCB_SP0Save		EQU		0x800
TCB_SS0Save     EQU     0x808
TCB_SP1Save		EQU		0x810
TCB_SS1Save     EQU     0x818
TCB_SP2Save		EQU		0x820
TCB_SS2Save     EQU     0x828
TCB_SP3Save		EQU		0x830
TCB_SS3Save     EQU     0x838
TCB_SP4Save		EQU		0x840
TCB_SS4Save     EQU     0x848
TCB_SP5Save		EQU		0x850
TCB_SS5Save     EQU     0x858
TCB_SP6Save		EQU		0x860
TCB_SS6Save     EQU     0x868
TCB_SP7Save		EQU		0x870
TCB_SS7Save     EQU     0x878
TCB_SP8Save		EQU		0x880
TCB_SS8Save     EQU     0x888
TCB_SP9Save		EQU		0x890
TCB_SS9Save     EQU     0x898
TCB_SP10Save	EQU		0x8A0
TCB_SS10Save    EQU     0x8A8
TCB_SP11Save	EQU		0x8B0
TCB_SS11Save    EQU     0x8B8
TCB_SP12Save	EQU		0x8C0
TCB_SS12Save    EQU     0x8C8
TCB_SP13Save	EQU		0x8D0
TCB_SS13Save    EQU     0x8D8
TCB_SP14Save	EQU		0x8E0
TCB_SS14Save    EQU     0x8E8
TCB_SP15Save	EQU		0x8F0
TCB_SS15Save    EQU     0x8F8
TCB_Seg0Save    EQU     0x900
TCB_Seg1Save	EQU		0x908
TCB_Seg2Save	EQU		0x910
TCB_Seg3Save	EQU		0x918
TCB_Seg4Save	EQU		0x920
TCB_Seg5Save	EQU		0x928
TCB_Seg6Save	EQU		0x930
TCB_Seg7Save	EQU		0x938
TCB_Seg8Save	EQU		0x940
TCB_Seg9Save	EQU		0x948
TCB_Seg10Save	EQU		0x950
TCB_Seg11Save	EQU		0x958
TCB_Seg12Save	EQU		0x960
TCB_Seg13Save	EQU		0x968
TCB_Seg14Save	EQU		0x970
TCB_Seg15Save	EQU		0x978
TCB_PCSave      EQU     0x980
TCB_SPSave		EQU		0x988
TCB_Next		EQU		0xA00
TCB_Prev		EQU		0xA08
TCB_Status		EQU		0xA18
TCB_Priority	EQU		0xA20
TCB_hJob		EQU		0xA28
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
KeyState1		db		0
KeyState2		db		0
KeybdWaitFlag	db		0
KeybdLEDs		db		0
startSector		dh		0
disk_size		dh		0

; Just past the Bootrom
	org		$00010000
NR_PTBL		EQU		32

IVTBaseAddress:
	fill.w	512*2,0      ; 2 words per vector, 512 vectors

    align 4096
GDTBaseAddress:
    fill.w  256*16*2,0   ; 2 words per descriptor, 16 descriptors per task, 256 tasks

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
	align 8192
TSSBaseAddress:
TCBs:
	fill.b	TCB_Size*NR_TCB,0

SECTOR_BUF	fill.b	512,0
    align 4096
BYTE_SECTOR_BUF	EQU	SECTOR_BUF
ROOTDIR_BUF fill.b  16384,0
PROG_LOAD_AREA	EQU ROOTDIR_BUF

EndStaticAllocations:
	dw		0

;
	code
	org		$00010000
	bra     start
	align   8
	dw		ClearScreen		; $8000
	dw		HomeCursor		; $8008
	dw		DisplayString	; $8010
	dw		KeybdGetCharNoWait; $8018
	dw		ClearBmpScreen	; $8020
	dw		DisplayChar		; $8028
	dw		SDInit			; $8030
	dw		SDReadMultiple	; $8038
	dw		SDWriteMultiple	; $8040
	dw		SDReadPart		; $8048
	dw		SDDiskSize		; $8050
	dw		DisplayWord		; $8058
	dw		DisplayHalf		; $8060
	dw		DisplayCharHex	; $8068
	dw		DisplayByte		; $8070

start:
    sei     ; interrupts off
    ldi     sp,#32760            ; set stack pointer to top of 32k Area
    ldi     r5,#$0000
    ldi     r1,#20
.0001:
    sc      r5,LEDS
    addui   r5,r5,#1
	sw		r0,Milliseconds
	ldi		r1,#%000000100_110101110_0000000000
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	sh		r1,NormAttr
	sb		r0,CursorRow
	sb		r0,CursorCol
	ldi		r1,#DisplayChar
	sw		r1,OutputVec
	bsr		ClearScreen
	bsr		HomeCursor
	ldi     r1,#msgStart
	bsr     DisplayStringCRLF
	ldi     r1,#8
	sb      r1,LEDS
	bsr		SetupIntVectors
;	bsr		KeybdInit
	bsr		InitPIC
	bra		Monitor
	bsr		FMTKInitialize
	cli

SetupIntVectors:
	ldi     r1,#$00A7
	sc      r1,LEDS
	mtspr   vbr,r0               ; place vector table at $0000
	nop
	nop
	mfspr   r2,vbr
	ldi		r1,#Tick1024Rout
	sw		r1,450*16[r2]
	ldi		r1,#TickRout         ; This vector will be taken over by FMTK
	sw		r1,451*16[r2]
	ldi		r1,#KeybdIRQ
	sw		r1,463*16[r2]
    ldi     r1,#SSM_ISR          ; set ISR vector for single step routine
    sw      r1,495*8[r2]
    ldi     r1,#IBPT_ISR         ; set ISR vector for instruction breakpoint routine
    sw      r1,496*8[r2]
	ldi		r1,#exf_rout
	sw		r1,497*16[r2]
	ldi		r1,#dwf_rout
	sw		r1,498*16[r2]
	ldi		r1,#drf_rout
	sw		r1,499*16[r2]
	ldi		r1,#priv_rout
	sw		r1,501*16[r2]
	ldi		r1,#berr_rout
	sw		r1,508*16[r2]
	ldi     r1,#$00AA
	sc      r1,LEDS
    rtl
 
;------------------------------------------------------------------------------
; Initialize the interrupt controller.
;------------------------------------------------------------------------------

InitPIC:
	ldi		r1,#$0C			; timer interrupt(s) are edge sensitive
	sh		r1,PIC_ES
	ldi		r1,#$000F		; enable keyboard reset, timer interrupts
	sh		r1,PIC_IE
	rtl

;------------------------------------------------------------------------------
; Convert ASCII character to screen display character.
;------------------------------------------------------------------------------

AsciiToScreen:
    push    r2
	and		r1,r1,#$FF
	or		r1,r1,#$100
	and		r2,r1,#%00100000	; if bit 5 or 6 isn't set
	beq		r2,.00001
	and		r2,r1,#%01000000
	beq		r2,.00001
	and		r1,r1,#%110011111
.00001:
    pop     r2
	rtl

;------------------------------------------------------------------------------
; Convert screen display character to ascii.
;------------------------------------------------------------------------------

ScreenToAscii:
    push    r2
	and		r1,r1,#$FF
	cmpu	r2,r1,#26+1
	bge		r2,.stasc1
	add		r1,r1,#$60
.stasc1:
    pop     r2
	rtl

CursorOff:
	rtl
CursorOn:
	rtl
HomeCursor:
	sb		r0,CursorRow
	sb		r0,CursorCol
	sc	    r0,TEXTREG+TEXT_CURPOS+$FFD00000
	rtl

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
                                                                               
ClearScreen:
    push    lr
    push	r1
    push    r2
    push    r3
    push    r4
	lbu	    r1,TEXTREG+TEXT_COLS+$FFD00000
	lbu	    r2,TEXTREG+TEXT_ROWS+$FFD00000
	mulu	r4,r2,r1
	ldi		r3,#TEXTSCR+$FFD00000
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r2,NormAttr
	or		r1,r1,r2
.cs1:
    sh	    r1,[r3+r4*4]
    subui   r4,r4,#1
	bne	    r4,.cs1
	pop     r4
	pop     r3
	pop     r2
	pop     r1
    rts

;------------------------------------------------------------------------------
; Display the word in r1
;------------------------------------------------------------------------------

DisplayWord:
    push    lr
	rol	    r1,r1,#32
	bsr		DisplayHalf
	rol	    r1,r1,#32
    pop     lr

;------------------------------------------------------------------------------
; Display the half-word in r1
;------------------------------------------------------------------------------

DisplayHalf:
    push    lr
	ror		r1,r1,#16
	bsr		DisplayCharHex
	rol		r1,r1,#16
	bsr		DisplayCharHex
	pop     lr
    rtl

;------------------------------------------------------------------------------
; Display the char in r1
;------------------------------------------------------------------------------

DisplayCharHex:
    push    lr
	ror		r1,r1,#8
	bsr		DisplayByte
	rol		r1,r1,#8
	bsr		DisplayByte
    pop     lr
    rtl

;------------------------------------------------------------------------------
; Display the byte in r1
;------------------------------------------------------------------------------

DisplayByte:
    push    lr
	ror		r1,r1,#4
	bsr		DisplayNybble
	rol		r1,r1,#4
	bsr		DisplayNybble
    pop     lr
    rtl
 
;------------------------------------------------------------------------------
; Display nybble in r1
;------------------------------------------------------------------------------

DisplayNybble:
    push    lr
	push	r1
	push    r2
	and		r1,r1,#$0F
	add		r1,r1,#'0'
	cmpu	r2,r1,#'9'+1
	blt		r2,.0001
	add		r1,r1,#7
.0001:
	bsr		OutChar
	pop     r2
	pop		r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Display a string pointer to string in r1.
;------------------------------------------------------------------------------

DisplayString:
    push    lr
	push	r1
	push    r2
	mov		r2,r1
.dm2:
	lbu		r1,[r2]
	addui   r2,r2,#1	; increment text pointer
	beq		r1,.dm1
	bsr		OutChar
	bra		.dm2
.dm1:
	pop		r2
    pop     r1
	rts

DisplayStringCRLF:
    push    lr
	bsr		DisplayString
	bra     CRLF1
OutCRLF:
CRLF:
    push    lr
CRLF1:
	push	r1
	ldi		r1,#CR
	bsr		OutChar
	ldi		r1,#LF
	bsr		OutChar
	pop		r1
	rts


DispCharQ:
    push    lr
	bsr		AsciiToScreen
	sc		r1,[r3]
	add		r3,r3,#4
    rts

DispStartMsg:
    push    lr
	ldi		r1,#msgStart
	bsr		DisplayString
    rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KeybdIRQ:
	sb		r0,KEYBD+1
	rti

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

TickRout:
    push    r1
	lh	    r1,TEXTSCR+220+$FFD00000
	add		r1,r1,#1
	sh	    r1,TEXTSCR+220+$FFD00000
	pop     r1
	rti

;------------------------------------------------------------------------------
; 1024Hz interupt routine. This must be fast. Allows the system time to be
; gotten by right shifting by 10 bits.
;------------------------------------------------------------------------------

Tick1024Rout:
	push	r1
	ldi		r1,#2				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	inc     Milliseconds
	pop		r1
	rti

;------------------------------------------------------------------------------
; GetSystemTime
;
; Returns 
;    r1 = the system time in seconds.
;------------------------------------------------------------------------------

GetSystemTime:
    lw      r1,Milliseconds
    lsr     r1,r1,#10
    rtl

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetScreenLocation:
	ldi		r1,#TEXTSCR+$FFD00000
	rtl
GetCurrAttr:
	lhu		r1,NormAttr
	rtl

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

UpdateCursorPos:
    push    lr
	push	r1
	push    r2
	push    r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu	    r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	addu	r2,r2,r1
	sc	    r2,TEXTREG+TEXT_CURPOS+$FFD00000
	pop		r4
    pop     r2
    pop     r1
    rts
	
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

CalcScreenLoc:
    push    lr
	push	r2
	push    r4
	lbu		r1,CursorRow
	and		r1,r1,#$3f
	lbu	    r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r2,r2,r1
	lbu		r1,CursorCol
	and		r1,r1,#$7f
	addu	r2,r2,r1
	sc	    r2,TEXTREG+TEXT_CURPOS+$FFD00000
	bsr		GetScreenLocation
	shl		r2,r2,#2
	addu	r1,r1,r2
	pop		r4
    pop     r2
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DisplayChar:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
	and		r1,r1,#$FF
	cmp		r2,r1,#'\r'
	beq		r2,.docr
	cmp		r2,r1,#$91		; cursor right ?
	beq		r2,.doCursorRight
	cmp		r2,r1,#$90		; cursor up ?
	beq		r2,.doCursorUp
	cmp		r2,r1,#$93		; cursor left ?
	beq		r2,.doCursorLeft
	cmp		r2,r1,#$92		; cursor down ?
	beq		r2,.doCursorDown
	cmp		r2,r1,#$94		; cursor home ?
	beq		r2,.doCursorHome
	cmp		r2,r1,#$99		; delete ?
	beq		r2,.doDelete
	cmp		r2,r1,#CTRLH	; backspace ?
	beq		r2,.doBackspace
	cmp		r2,r1,#'\n'	; line feed ?
	beq		r2,.doLinefeed
	mov		r2,r1
	bsr		CalcScreenLoc
	mov		r3,r1
	mov		r1,r2
	bsr		AsciiToScreen
	mov		r2,r1
	bsr		GetCurrAttr
	or		r1,r1,r2
	sh	    r1,[r3]
	bsr		IncCursorPos
.dcx4:
	pop		r4
    pop     r3
    pop     r2
    pop     r1
    pop     lr
	rtl
.docr:
	sb		r0,CursorCol
	bsr		UpdateCursorPos
	bra     .dcx4
.doCursorRight:
	lbu		r1,CursorCol
	add		r1,r1,#1
	cmpu	r2,r1,#TXTCOLS
	bge		r2,.dcx7
	sb		r1,CursorCol
.dcx7:
	bsr		UpdateCursorPos
	bra     .dcx4
.doCursorUp:
	lbu		r1,CursorRow
	beq		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorRow
	bra		.dcx7
.doCursorLeft:
	lbu		r1,CursorCol
	beq		r1,.dcx7
	sub		r1,r1,#1
	sb		r1,CursorCol
	bra		.dcx7
.doCursorDown:
	lbu		r1,CursorRow
	add		r1,r1,#1
	cmpu	r2,r1,#TXTROWS
	bge		r2,.dcx7
	sb		r1,CursorRow
	bra		.dcx7
.doCursorHome:
	lbu		r1,CursorCol
	beq		r1,.dcx12
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
	beq		r1,.dcx4
	sub		r1,r1,#1
	sb		r1,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	lbu		r1,CursorCol
.dcx5:
	lhu	    r2,4[r3]
	sh	    r2,[r3]
	add		r3,r3,#4
	add		r1,r1,#1
	cmpu	r2,r1,#TXTCOLS
	blt		r2,.dcx5
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r2,NormAttr
	or		r1,r1,r2
	sub		r3,r3,#4
	sh	    r1,[r3]
	bra		.dcx4
.doLinefeed:
	bsr		IncCursorRow
	bra		.dcx4


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

IncCursorPos:
    push    lr
	push	r1
    push    r2
    push    r4
	lbu		r1,CursorCol
	addui	r1,r1,#1
	sb		r1,CursorCol
	cmpu	r2,r1,#TXTCOLS
	blt		r2,icc1
	sb		r0,CursorCol
	bra		icr1
IncCursorRow:
    push    lr
	push	r1
    push    r2
    push    r4
icr1:
	lbu		r1,CursorRow
	addui	r1,r1,#1
	sb		r1,CursorRow
	cmpu	r2,r1,#TXTROWS
	blt		r2,icc1
	ldi		r2,#TXTROWS-1
	sb		r2,CursorRow
	bsr		ScrollUp
icc1:
    nop
    nop
	bsr		UpdateCursorPos
	pop		r4
    pop     r2
    pop     r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ScrollUp:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r5
	push	r6
	lbu	    r1,TEXTREG+TEXT_COLS+$FFD00000
	lbu	    r2,TEXTREG+TEXT_ROWS+$FFD00000
	subui	r2,r2,#1
	mulu	r6,r1,r2
	ldi		r1,#TEXTSCR+$FFD00000
	ldi		r2,#TEXTSCR+TXTCOLS*4+$FFD00000
	ldi		r3,#0
.0001:
	lh	    r5,[r2+r3*4]
	sh	    r5,[r1+r3*4]
	addui	r3,r3,#1
	subui   r6,r6,#1
	bne	    r6,.0001
	lbu	    r1,TEXTREG+TEXT_ROWS+$FFD00000
	subui	r1,r1,#1
	bsr		BlankLine
	pop		r6
	pop		r5
    pop     r3
    pop     r2
    pop     r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Blank out a line on the screen.
;
; Parameters:
;	r1 = line number to blank out
;------------------------------------------------------------------------------

BlankLine:
    push    lr
	push	r1
    push    r2
    push    r3
    push    r4
    lbu     r2,TEXTREG+TEXT_COLS+$FFD00000
	mulu	r3,r2,r1
;	subui	r2,r2,#1		; r2 = #chars to blank - 1
	shl		r3,r3,#2
	addui	r3,r3,#TEXTSCR+$FFD00000
	ldi		r1,#' '
	bsr		AsciiToScreen
	lhu		r4,NormAttr
	or		r1,r1,r4
.0001:
	sh	    r1,[r3+r2*4]
	subui   r2,r2,#1
	bne	    r2,.0001
	pop		r4
    pop     r3
    pop     r2
    pop     r1
	pop     lr
	rtl

	db	0
msgStart:
	db	"FISA64 test system starting.",0


; ============================================================================
; Monitor Task
; ============================================================================

Monitor:
	ldi		r1,#49
	sc		r1,LEDS
;	bsr		ClearScreen
;	bsr		HomeCursor
	ldi		r1,#msgMonitorStarted
	bsr		DisplayStringCRLF
	sb		r0,KeybdEcho
	;ldi		r1,#7
	;ldi		r2,#0
	;ldi		r3,#IdleTask
	;ldi		r4,#0
	;ldi		r5,#0
	;bsr		StartTask
mon1:
	ldi		r1,#50
	sc		r1,LEDS
;	ldi		sp,#TCBs+TCB_Size-8		; reload the stack pointer, it may have been trashed
	ldi		sp,#$8000
	cli
.PromptLn:
	bsr		CRLF
	ldi		r1,#'$'
	bsr		OutChar
.Prompt3:
	bsr		KeybdGetCharNoWait		; KeybdGetCharDirectNB
	blt	    r1,.Prompt3
	cmp		r2,r1,#CR
	beq		r2,.Prompt1
	bsr		OutChar
	bra		.Prompt3
.Prompt1:
	sb		r0,CursorCol
	bsr		CalcScreenLoc
	mov		r3,r1
	bsr		MonGetch
	cmp		r2,r1,#'$'
	bne		r2,.Prompt2
	bsr		MonGetch
.Prompt2:
	cmp		r2,r1,#'?'
	beq		r2,.doHelp
	cmp		r2,r1,#'C'
	beq		r2,doCLS
	cmp     r2,r1,#'c'
	beq     r2,doCS
	cmp		r2,r1,#'M'
	beq		r2,doDumpmem
	cmp		r2,r1,#'m'
	beq		r2,MRTest
	cmp		r2,r1,#'S'
	beq		r2,doSDBoot
	cmp		r2,r1,#'g'
	beq		r2,doRand
	cmp		r2,r1,#'e'
	beq		r2,eval
	bra     mon1

.doHelp:
	ldi		r1,#msgHelp
	bsr		DisplayString
	bra     mon1

MonGetch:
    push    lr
	lhu	    r1,[r3]
	andi	r1,r1,#$1FF
	add		r3,r3,#4
	bsr		ScreenToAscii
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Ignore blanks in the input
; r3 = text pointer
; r1 destroyed
;------------------------------------------------------------------------------

ignBlanks:
    push    lr
    push    r2
ignBlanks1:
	bsr		MonGetch
	cmp		r2,r1,#' '
	beq		r2,ignBlanks1
	sub		r3,r3,#4
	pop     r2
	rts

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

GetTwoParams:
    push    lr
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
    push    lr
    push    r4
	bsr		GetTwoParams
	cmpu	r4,r2,r1
	bgt		r4,DisplayErr
	pop     r4
	pop     lr
	rtl

doDumpmem:
	bsr		CursorOff
	bsr		GetRange
	bsr		CRLF
.001:
	bsr		CheckKeys
	bsr		DisplayMemBytes
	cmpu	r4,r2,r1
	ble		r4,.001
	bra     mon1

doSDBoot:
;	sub		r3,r3,#4
	bsr		SDInit
	bne	    r1,mon1
	bsr		SDReadPart
	bne	    r1,mon1
	bsr		SDReadBoot
	bne	    r1,mon1
	bsr		loadBootFile
	jmp		mon1

OutChar:
    jmp     (OutputVec)

;------------------------------------------------------------------------------
; Display memory pointed to by r2.
; destroys r1,r3
;------------------------------------------------------------------------------
;
DisplayMemBytes:
    push    lr
	push	r1
    push    r3
    push    r4
	ldi		r1,#'>'
	bsr		OutChar
	ldi		r1,#'B'
	bsr		OutChar
	ldi		r1,#' '
	bsr		OutChar
	mov		r1,r2
	bsr		DisplayHalf
	ldi		r3,#8
.001:
	ldi		r1,#' '
	bsr		OutChar
	lbu		r1,[r2]
	bsr		DisplayByte
	addui	r2,r2,#1
	subui   r3,r3,#1
	bne	    r3,.001
	ldi		r1,#':'
	bsr		OutChar
	ldi		r1,#%110101110_000000100_0000000000	; reverse video
	sh		r1,NormAttr
	ldi		r3,#8
	subui	r2,r2,#8
.002
	lbu		r1,[r2]
	cmpu	r4,r1,#26				; convert control characters to '.'
	bge		r4,.004
	ldi		r1,#'.'
	bra     .003
.004:
	cmpu	r4,r1,#$80				; convert other non-ascii to '.'
	blt		r4,.003
	ldi		r1,#'.'
.003:
	bsr		OutChar
	addui	r2,r2,#1
	subui   r3,r3,#1
	bne	    r3,.002
	ldi		r1,#%000000100_110101110_0000000000	; normal video
	sh		r1,NormAttr
	bsr		CRLF
	pop     r4
	pop		r3
    pop     r1
    pop     lr
	rtl

;------------------------------------------------------------------------------
; CheckKeys:
;	Checks for a CTRLC or a scroll lock during long running dumps.
;------------------------------------------------------------------------------

CheckKeys:
    push    lr
	bsr	    CTRLCCheck
	bra     CheckScrollLock

;------------------------------------------------------------------------------
; CTRLCCheck
;	Checks to see if CTRL-C is pressed. If so then the current routine is
; aborted and control is returned to the monitor.
;------------------------------------------------------------------------------

CTRLCCheck:
    push    lr
	push	r1
	push    r2
	bsr		KeybdGetCharNoWait
	cmp		r2,r1,#CTRLC
	beq		r2,.0001
	pop     r2
	pop		r1
	pop     lr
	rtl
.0001:
	addui	sp,sp,#24
	bra     mon1

;------------------------------------------------------------------------------
; CheckScrollLock:
;	Check for a scroll lock by the user. If scroll lock is active then tasks
; are rescheduled while the scroll lock state is tested in a loop.
;------------------------------------------------------------------------------

CheckScrollLock:
	push	r1
	push    r2
.0002:
	lcu		r1,KeybdLocks
	and		r2,r1,#$4000		; is scroll lock active ?
	beq		r2,.0001
	brk		#2*16				; reschedule tasks
	bra     .0002
.0001:
    pop     r2
	pop		r1
	pop     lr
	rtl

;------------------------------------------------------------------------------
; Get a hexidecimal number. Maximum of eight digits.
; R3 = text pointer (updated)
; R1 = hex number
;------------------------------------------------------------------------------
;
GetHexNumber:
    push    lr
	push	r2
    push    r4
	ldi		r2,#0
	ldi		r4,#16
.gthxn2:
	bsr		MonGetch
	bsr		AsciiToHexNybble
	bmi		r1,.gthxn1
	asl		r2,r2,#4
	or		r2,r2,r1
	subui   r4,r4,#1
    bne	    r4,.gthxn2
.gthxn1:
	mov		r1,r2
	pop		r4
    pop     r2
    rts

;------------------------------------------------------------------------------
; Convert ASCII character in the range '0' to '9', 'a' to 'f' or 'A' to 'F'
; to a hex nybble.
;------------------------------------------------------------------------------
;
AsciiToHexNybble:
    push    r2
	cmpu	r2,r1,#'0'
	blt		r2,.gthx3
	cmpu	r2,r1,#'9'+1
	bge		r2,.gthx5
	subui	r1,r1,#'0'
	pop     r2
	rtl
.gthx5:
	cmpu	r2,r1,#'A'
	blt		r2,.gthx3
	cmpu	r2,r1,#'F'+1
	bge		r2,.gthx6
	subui	r1,r1,#'A'
	addui	r1,r1,#10
	pop     r2
	rtl
.gthx6:
	cmpu	r2,r1,#'a'
	blt		r2,.gthx3
	cmpu	r2,r1,#'z'+1
	bge		r2,.gthx3
	subui	r1,r1,#'a'
	addui	r1,r1,#10
	pop     r2
	rtl
.gthx3:
    pop     r2
	ldi		r1,#-1		; not a hex number
	rtl

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
	bra     mon1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; Keyboard processing routines follow.
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

KEYBD_DELAY		EQU		1000

KeybdGetCharDirectNB:
    push    lr
	push	r2
	sei
	lcu		r1,KEYBD
	and		r2,r1,#$8000
	beq		r2,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	cli
	and		r2,r1,#$800	; is it keydown ?
	bne	    r2,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	beq		r2,.0002
	cmp		r2,r1,#CR
	bne		r2,.0003
	bsr		CRLF
	bra     .0002
.0003:
	jsr		(OutputVec)
.0002:
	pop		r2
	pop     lr
	rtl
.0001:
	cli
	ldi		r1,#-1
	pop		r2
	pop     lr
	rtl

KeybdGetCharDirect:
    push    lr
	push	r2
.0001:
	lc		r1,KEYBD
	and		r2,r1,#$8000
	beq		r2,.0001
	lbu		r0,KEYBD+4		; clear keyboard strobe
	and		r2,r1,#$800	; is it keydown ?
	bne	    r2,.0001
	and		r1,r1,#$FF
	lbu		r2,KeybdEcho
	beq		r2,.gk1
	cmp		r2,r1,#CR
	bne		r2,.gk2
	bsr		CRLF
	bra     .gk1
.gk2:
	jsr		(OutputVec)
.gk1:
	pop		r2
	pop     lr
	rtl

;KeybdInit:
;	mfspr	r1,cr0		; turn off tmr mode
;	push	r1
;	mtspr	cr0,r0
;	ldi		r1,#33
;	sb		r1,LEDS
;	bsr		WaitForKeybdAck	; grab a byte from the keyboard
;	cmp		flg0,r1,#$AA	; did it send a ack ?
;	
;	ldi		r1,#$ff			; issue keyboard reset
;	bsr		SendByteToKeybd
;	ldi		r1,#38
;	sb		r1,LEDS
;	ldi		r1,#4
;	jsr		Sleep
;	ldi		r1,#KEYBD_DELAY	; delay a bit
kbdi5:
;	sub		r1,r1,#1
;	brnz	r1,kbdi5
;	ldi		r1,#34
;	sb		r1,LEDS
;	ldi		r1,#0xf0		; send scan code select
;	bsr		SendByteToKeybd
;	ldi		r1,#35
;	sb		r1,LEDS
;	ldi		r2,#0xFA
;	bsr		WaitForKeybdAck
;	cmp		fl0,r1,#$FA
;	bne		fl0,kbdi2
;	ldi		r1,#36
;	sb		r1,LEDS
;	ldi		r1,#2			; select scan code set#2
;	bsr		SendByteToKeybd
;	ldi		r1,#39
;	sb		r1,LEDS
;kbdi2:
;	ldi		r1,#45
;	sb		r1,LEDS
;	pop		r1				; turn back on tmr mode
;	mtspr	cr0,r1
;	rtl

msgBadKeybd:
	db		"Keyboard not responding.",0

;SendByteToKeybd:
;	push	r2
;	sb		r1,KEYBD
;	ldi		r1,#40
;	sb		r1,LEDS
;	mfspr	r3,tick
;kbdi4:						; wait for transmit complete
;	mfspr	r4,tick
;	sub		r4,r4,r3
;	cmp		fl0,r4,#KEYBD_DELAY
;	bhi		fl0,kbdbad
;	ldi		r1,#41
;	sb		r1,LEDS
;	lbu		r1,KEYBD+1
;	and		fl0,r1,#64
;	brz		fl0,kbdi4
;	bra 	sbtk1
;kbdbad:
;	ldi		r1,#42
;	sb		r1,LEDS
;	lbu		r1,KeybdBad
;	brnz	r1,sbtk2
;	ldi		r1,#1
;	sb		r1,KeybdBad
;	ldi		r1,#43
;	sb		r1,LEDS
;	ldi		r1,#msgBadKeybd
;	bsr		DisplayStringCRLF
;sbtk1:
;	ldi		r1,#44
;	sb		r1,LEDS
;	pop		r2
;	rtl
;sbtk2:
;	bra sbtk1

; Wait for keyboard to respond with an ACK (FA)
;
;WaitForKeybdAck:
;	ldi		r1,#64
;	sb		r1,LEDS
;	mfspr	r3,tick
;wkbdack1:
;	mfspr	r4,tick
;	sub		r4,r4,r3
;	cmp		fl0,r4,#KEYBD_DELAY
;	bhi		fl0,wkbdbad
;	ldi		r1,#65
;	sb		r1,LEDS
;	lb		r1,KEYBD+1				; check keyboard status for key
;	brpl	r1,wkbdack1				; no key available, go back
;	lbu		r1,KEYBD				; get the scan code
;	sb		r0,KEYBD+1				; clear recieve register
;wkbdbad:
;	rtl

KeybdInit:
    push    lr
	ldi		r3,#5
.0001:
	bsr		KeybdRecvByte	; Look for $AA
	bmi		r1,.0002
	cmp		r2,r1,#$AA		;
	beq		r2,.config
.0002:
	bsr		Wait10ms
	ldi		r1,#-1			; send reset code to keyboard
	sb		r1,KEYBD+1		; write to status reg to clear TX state
	bsr		Wait10ms
	ldi		r1,#$FF
	bsr		KeybdSendByte	; now write to transmit register
	bsr		KeybdWaitTx		; wait until no longer busy
	bsr		KeybdRecvByte	; look for an ACK ($FA)
	cmp		r2,r1,#$FA
	bsr		KeybdRecvByte
	cmp		r2,r1,#$FC		; reset error ?
	beq		r2,.tryAgain
	cmp		r2,r1,#$AA		; reset complete okay ?
	bne		r2,.tryAgain
.config:
	ldi		r1,#$F0			; send scan code select
	sc		r1,LEDS
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bmi		r1,.tryAgain
	bsr		KeybdRecvByte	; wait for response from keyboard
	bmi		r1,.tryAgain
	cmp		r2,r1,#$FA
	beq		r2,.0004
.tryAgain:
    subui   r3,r3,#1
	bne	    r3,.0001
.keybdErr:
	ldi		r1,#msgBadKeybd
	bsr		DisplayString
	pop     lr
	rtl
.0004:
	ldi		r1,#2			; select scan code set #2
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bmi		r1,.tryAgain
	pop     lr
	rtl

; Get the keyboard status
;
KeybdGetStatus:
	lb		r1,KEYBD+1
	rtl

; Get the scancode from the keyboard port
;
KeybdGetScancode:
	lbu		r1,KEYBD				; get the scan code
	sb		r0,KEYBD+1				; clear receive register
	rtl

; Recieve a byte from the keyboard, used after a command is sent to the
; keyboard in order to wait for a response.
;
KeybdRecvByte:
    push    lr
	push	r3
	ldi		r3,#100			; wait up to 1s
.0003:
	bsr		KeybdGetStatus	; wait for response from keyboard
	bmi		r1,.0004		; is input buffer full ? yes, branch
	bsr		Wait10ms		; wait a bit
	subui   r3,r3,#1
	bne     r3,.0003		; go back and try again
	pop		r3				; timeout
	ldi		r1,#-1			; return -1
	pop     lr
	rtl
.0004:
	bsr		KeybdGetScancode
	pop		r3
	pop     lr
	rtl


; Wait until the keyboard transmit is complete
; Returns .CF = 1 if successful, .CF=0 timeout
;
KeybdWaitTx:
    push    lr
	push	r2
    push    r3
	ldi		r3,#100			; wait a max of 1s
.0001:
	bsr		KeybdGetStatus
	and		r1,r1,#$40		; check for transmit complete bit
	bne	    r1,.0002		; branch if bit set
	bsr		Wait10ms		; delay a little bit
	subui   r3,r3,#1
	bne	    r3,.0001		; go back and try again
	pop		r3
    pop     r2			    ; timed out
	ldi		r1,#-1			; return -1
	pop     lr
	rtl
.0002:
	pop		r3
    pop     r2			    ; wait complete, return 
	ldi		r1,#0			; return 0
	pop     lr
	rtl

KeybdGetCharNoWait:
	sb		r0,KeybdWaitFlag
	bra		KeybdGetChar

KeybdGetCharWait:
	ldi		r1,#-1
	sb		r1,KeybdWaitFlag
	
KeybdGetChar:
    push    lr
	push	r2
    push    r3
.0003:
	bsr		KeybdGetStatus			; check keyboard status for key available
	bmi		r1,.0006				; yes, go process
	lb		r1,KeybdWaitFlag		; are we willing to wait for a key ?
	bmi		r1,.0003				; yes, branch back
	ldi		r1,#-1					; flag no char available
	pop		r3
    pop     r2
    pop     lr
	rtl
.0006:
	bsr		KeybdGetScancode
.0001:
	ldi		r2,#1
	sb		r2,LEDS
	cmp		r2,r1,#SC_KEYUP
	beq		r2,.doKeyup
	cmp		r2,r1,#SC_EXTEND
	beq		r2,.doExtend
	cmp		r2,r1,#$14				; code for CTRL
	beq		r2,.doCtrl
	cmp		r2,r1,#$12				; code for left shift
	beq		r2,.doShift
	cmp		r2,r1,#$59				; code for right-shift
	beq		r2,.doShift
	cmp		r2,r1,#SC_NUMLOCK
	beq		r2,.doNumLock
	cmp		r2,r1,#SC_CAPSLOCK
	beq		r2,.doCapsLock
	cmp		r2,r1,#SC_SCROLLLOCK
	beq		r2,.doScrolllock
	lb		r2,KeyState1			; check key up/down
	sb		r0,KeyState1			; clear keyup status
	bne	    r2,.0003				; ignore key up
	lb		r2,KeyState2
	and		r3,r2,#$80				; is it extended code ?
	beq		r3,.0010
	and		r3,r2,#$7f				; clear extended bit
	sb		r3,KeyState2
	sb		r0,KeyState1			; clear keyup
	lbu		r1,keybdExtendedCodes[r1]
	bra		.0008
.0010:
	lb		r2,KeyState2
	and		r3,r2,#$04				; is it CTRL code ?
	beq		r3,.0009
	and		r1,r1,#$7F
	lbu		r1,keybdControlCodes[r1]
	bra		.0008
.0009:
	lb		r2,KeyState2
	and		r3,r2,#$01				; is it shift down ?
	beq  	r3,.0007
	lbu		r1,shiftedScanCodes[r1]
	bra		.0008
.0007:
	lbu		r1,unshiftedScanCodes[r1]
	ldi		r2,#2
	sb		r2,LEDS
.0008:
	ldi		r2,#3
	sb		r2,LEDS
	pop		r3
    pop     r2
    pop     lr
	rtl
.doKeyup:
	ldi		r1,#-1
	sb		r1,KeyState1
	bra		.0003
.doExtend:
	lbu		r1,KeyState2
	or		r1,r1,#$80
	sb		r1,KeyState2
	bra		.0003
.doCtrl:
	lb		r1,KeyState1
	sb		r0,KeyState1
	bpl		r1,.0004
	lb		r1,KeyState2
	and		r1,r1,#-5
	sb		r1,KeyState2
	bra		.0003
.0004:
	lb		r1,KeyState2
	or		r1,r1,#4
	sb		r1,KeyState2
	bra		.0003
.doShift:
	lb		r1,KeyState1
	sb		r0,KeyState1
	bpl		r1,.0005
	lb		r1,KeyState2
	and		r1,r1,#-2
	sb		r1,KeyState2
	bra		.0003
.0005:
	lb		r1,KeyState2
	or		r1,r1,#1
	sb		r1,KeyState2
	bra		.0003
.doNumLock:
	lb		r1,KeySTate2
	eor		r1,r1,#16
	sb		r1,KeyState2
	bsr		KeybdSetLEDStatus
	bra		.0003
.doCapsLock:
	lb		r1,KeyState2
	eor		r1,r1,#32
	sb		r1,KeyState2
	bsr		KeybdSetLEDStatus
	bra		.0003
.doScrollLock:
	lb		r1,KeyState2
	eor		r1,r1,#64
	sb		r1,KeyState2
	bsr		KeybdSetLEDStatus
	bra		.0003

KeybdSetLEDStatus:
    push    lr
	push	r2
    push    r3
	sb		r0,KeybdLEDs
	lb		r1,KeyState2
	and		r2,r1,#16
	beq		r2,.0002
	ldi		r3,#2
	sb		r3,KeybdLEDs
.0002:
	and		r2,r1,#32
	beq		r2,.0003
	lb		r3,KeybdLEDs
	or		r3,r3,#4
	sb		r3,KeybdLEDs
.0003:
	and		r2,r1,#64
	beq		r2,.0004
	lb		r3,KeybdLEDs
	or		r3,r3,#1
	sb		r3,KeybdLEDs
.0004:
	ldi		r1,#$ED
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte
	bmi		r1,.0001
	cmp		r2,r1,#$FA
	lb		r1,KeybdLEDs
	bsr		KeybdSendByte
	bsr		KeybdWaitTx
	bsr		KeybdRecvByte
.0001:
	pop		r3
    pop     r2
    pop     lr
	rtl

KeybdSendByte:
	sb		r1,KEYBD
	rtl
	
Wait10ms:
	push	r3
    push    r4
	mfspr	r3,tick					; get orginal count
.0001:
	mfspr	r4,tick
	sub		r4,r4,r3
	blt  	r4,.0002				; shouldn't be -ve unless counter overflowed
	cmpu	r4,r4,#250000			; about 10ms at 25 MHz
	blt		r4,.0001
.0002:
	pop		r4
    pop     r3
	rtl

	;--------------------------------------------------------------------------
	; PS2 scan codes to ascii conversion tables.
	;--------------------------------------------------------------------------
	;
	align	16
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



    ldi     r1,#brkpt1           ; set breakpoint address
    mtspr   dbad0,r1
    ldi     r1,#$0000000000000000   ; enable instruction breakpoint, turn on single step mode
    mtspr   dbctrl,r1
    mtspr   lotgrp,r0            ; operating system is group #0
    bsr     SetupMemtags
    ldi     r1,#100
    bsr     MicroDelay
    nop
    nop
hangprg:
    nop
    nop
    nop
    bra     hangprg

SetupMemtags:
    mtspr   ea,r0                ; select tag for first 64kB
    ldi     r1,#$0006            ; system only: readable, writeable, not executable
brkpt1:
    mtspr   tag,r1
    ldi     r1,#$10000           ; select tag for second 64kB
    mtspr   ea,r1
    ldi     r2,#$0005            ; system only: readable, executable, not writeable
    mtspr   tag,r2
    ldi     r3,#20-2             ; number of tags to setup
.0001:
    addui   r1,r1,#$10000
    mtspr   ea,r1
    ldi     r2,#$0006            ; set them up as data
    mtspr   tag,r2
    subui   r3,r3,#1
    bne     r3,.0001
    rtl

; Delay for a short time for at least the specified number of clock cycles
;
MicroDelay:
    push    r2
    push    r3
    push    $10000              ; test push memory
    push    $10008
    mfspr   r3,tick             ; get starting tick
.0001:
    mfspr   r2,tick
    subu    r2,r2,r3
    cmp     r2,r2,r1
    blt     r2,.0001
    addui   sp,sp,#16
    pop     r3
    pop     r2
    rtl
;
    nop
    nop

;------------------------------------------------------------------------------
; Execution fault. Occurs when an attempt is made to execute code from a
; page marked as non-executable.
;------------------------------------------------------------------------------

exf_rout:
	ldi		r1,#$bb
	sc		r1,LEDS
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
	sc		r1,LEDS
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
	sc		r1,LEDS
	ldi		r1,#msgdwf
	bsr		DisplayStringCRLF
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Privilege violation fault. Occurs when the current privilege level isn't
; sufficient to allow access.
;------------------------------------------------------------------------------

priv_rout:
	ldi		r1,#$bc
	sc		r1,LEDS
	ldi		r1,#msgPriv
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
msgPriv:
	db	"priv fault",0
msgUninit:
	db	"uninit int.",0

;------------------------------------------------------------------------------
; Bus error routine.
;------------------------------------------------------------------------------

berr_rout:
	ldi		r1,#$AA
	sc		r1,LEDS
;	mfspr	r1,bear
;	bsr		DisplayWord
.be1:
	bra .be1




SSM_ISR:
    rtd

IBPT_ISR:
    rtd
.0001:
    bra     .0001
         
    nop
    nop

