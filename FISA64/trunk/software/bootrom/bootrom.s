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

E_Ok        EQU     $00
E_Timeout   EQU     $10

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
SC_TAB      EQU     $0D

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

DBG_STACK   EQU     $7000
CPU0_DBG_STACK  EQU     $7CF000
CPU0_BIOS_STACK  EQU     $6800
MON_STACK   EQU     $6000
; CPU1 Ram allocations must be to the dram area.
CPU1_SYS_STACK      EQU  $21000
CPU1_BIOS_STACK     EQU  $21800
CPU0_SYS_STACK      EQU  $5000

LEDS	equ		$FFDC0600

BIOS_FREE      EQU       0
BIOS_DONE      EQU       1
BIOS_INSERVICE EQU       2

MAX_BIOS_CALL  EQU       100
E_BadFuncno    EQU       1
BIOS_E_Timeout EQU       2
E_Unsupported  EQU       3

; The following offsets in the I/O segment
TEXTSCR	equ		$FFD00000
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

I2C_MASTER		EQU		0xFFDC0E00
I2C_PRESCALE_LO	EQU		0x00
I2C_PRESCALE_HI	EQU		0x01
I2C_CONTROL		EQU		0x02
I2C_TX			EQU		0x03
I2C_RX			EQU		0x03
I2C_CMD			EQU		0x04
I2C_STAT		EQU		0x04

SD_MASTER		EQU		0xFFDC0B00

RANDOM_NUM      EQU     0xFFDC0C00

UART            EQU     0xFFDC0A00
UART_TX         EQU     0
UART_RX         EQU     0
UART_LS         EQU     1
UART_MS         EQU     2
UART_IS         EQU     3
UART_IE         EQU     4
UART_FF         EQU     5
UART_MC         EQU     6
UART_CTRL       EQU     7
UART_CM0        EQU     8
UART_CM1        EQU     9
UART_CM2        EQU     10
UART_CM3        EQU     11
UART_SPR        EQU     15

TCB_BASE       EQU     $0C00000
TCB_TOP        EQU     $1C00000

; BIOS request structure
BIOS_op        EQU     $00
BIOS_arg1      EQU     $08
BIOS_arg2      EQU     $10
BIOS_arg3      EQU     $18
BIOS_arg4      EQU     $20
BIOS_arg5      EQU     $28
BIOS_resp      EQU     $30
BIOS_stat      EQU     $38

include "DeviceDriver.inc"
;include "FMTK_Equates.inc"

    data
    org     $C10000
	bss
	org		$C20000
Ticks			dw		0
; Monitor register storage
MON_r1          dw      0
MON_r2          dw      0
MON_r3          dw      0
MON_r4          dw      0
MON_r5          dw      0
MON_r6          dw      0
MON_r7          dw      0
MON_r8          dw      0
MON_r9          dw      0
MON_r10         dw      0
MON_r11         dw      0
MON_r12         dw      0
MON_r13         dw      0
MON_r14         dw      0
MON_r15         dw      0
MON_r16         dw      0
MON_r17         dw      0
MON_r18         dw      0
MON_r19         dw      0
MON_r20         dw      0
MON_r21         dw      0
MON_r22         dw      0
MON_r23         dw      0
MON_r24         dw      0
MON_r25         dw      0
MON_r26         dw      0
MON_r27         dw      0
MON_r28         dw      0
MON_r29         dw      0
MON_r30         dw      0
MON_r31         dw      0

BIOS_CALL       EQU     10
FMTK_CALL       EQU     4
    align   16
VideoBIOS_sema    dw    0


Milliseconds	dw		0
OutputVec		dw		0
InputVec        dw      0
jmp_vector      dw      0
TickVec			dw		0
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
NUMWKA          fill.b  32,0
startSector		dh		0
disk_size		dh		0
rxfull     EQU      1
Uart_ms         db      0
Uart_txxonoff   db      0
Uart_rxhead     dc      0
Uart_rxtail     dc      0
Uart_rxflow     db      0
Uart_rxrts      db      0
Uart_rxdtr      db      0
Uart_rxxon      db      0
Uart_foff       dc      0
Uart_fon        dc      0
Uart_txrts      db      0
Uart_txdtr      db      0
Uart_txxon      db      0
Uart_rxfifo     fill.b  512,0
                align 2
API_head        dc      0
API_tail        dc      0
                align 8
API_sema        dw      0
BIOS_sema       dw      0
BIOS_MbxHandle  EQU     $C00008
StartCPU1Flag   dw      0
StartCPU1Addr   dw      0
CPUIdleTick     dw      0
                dw      0
                dw      0
                dw      0
JCB0            fill.b  2048,0

	align	16
RTCC_BUF		fill.b	96,0
API_AREA        fill.b  2048,0

; Just past the 

	; 2MB for TSS space
	align 8192

SECTOR_BUF	fill.b	512,0
    align 4096
BYTE_SECTOR_BUF	EQU	SECTOR_BUF
ROOTDIR_BUF fill.b  16384,0
PROG_LOAD_AREA	EQU ROOTDIR_BUF

EndStaticAllocations:
	dw		0

VideoBIOSSema   EQU $FFDB0000
BIOSSema        EQU $FFDB0010

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
BIOS_FuncTable:
    dc      ClearScreen
    dc      HomeCursor
    dc      DisplayString
    dc      KeybdGetCharNoWait
    dc      0
    dc      OutChar
    dc      0
    dc      0
    dc      0
    dc      0
    dc      0
    dc      DisplayWord
    dc      DisplayHalf
    dc      DisplayCharHex
    dc      DisplayByte
    dc      DisplayString16
    dc      0
    dc      0
    dc      0
    
    align   4
message "start"
start:
    sw      r0,FMTK_Inited
    cpuid   r1,r0,#0
    beq     r1,CPU0_Start
CPU1_Start:
    ldi     sp,#stacks+4096+4088
;    ldi     tr,#tcbs+TCB_Size
;	sw      sp,TCB_ISP[tr]
;	sw      sp,TCB_r30[tr]
;	ldi     r1,#BIOS_STACKS_Array+4096+4088  ; so we can call the BIOS during startup
;	sw      r1,TCB_BIOS_Stack[tr]
;	ldi     r1,#SYS_STACKS_Array+4096+4088  ; so we can call the BIOS during startup
;	sw      r1,TCB_SYS_Stack[tr]
;	sb      r0,TCB_hJCB[tr]             ; JCB#0 is the system JCB
;    bsr     SetupIntVectors1
;	bsr		InitPIC1
	; Wait for CPU #0 to complete FMTK initialization before proceeding.
.0001:
    nop
    nop
	lw      r1,FMTK_Inited
	cmpu    r1,r1,#$12345678
	bne     r1,.0001
	bsr     FMTKInitialize        ;  Initialize for CPU #1
.0003:
    cli
    inc     $20000
    lw      r1,StartCPU1Flag
    cmp     r1,r1,#$12345678
    bne     r1,.0003
    jmp     (StartCPU1Addr)
    ; This is a little bit kludgy, we setup just enough of the FMTK vars
    ; in order to be able to get display output.
CPU0_Start:
.0002:
	ldi     sp,#stacks+4088
    ldi     r1,#1
    sc      r1,LEDS
	; Copy initialized data to data area
	lea     r1,begin_init_data
	lea     r2,$C10000
.cpy_loop:
	lw      r3,[r1]
	sw      r3,[r2]
	addui   r1,r1,#8
	addui   r2,r2,#8
	cmpu    r3,r1,#end_init_data
	blt     r3,.cpy_loop
    ldi     r1,#10
    sc      r1,LEDS

	bsr     FMTKInitialize
    ldi     r1,#15
    sc      r1,LEDS

;	ldi     tr,#tcbs                   ; load task register with BIOS task
;	sw      sp,TCB_ISP[tr]
;	sw      sp,TCB_r30[tr]
;	ldi     r1,#bios_stacks+4088  ; so we can call the BIOS during startup
;	sw      r1,TCB_BIOS_Stack[tr]
;	ldi     r1,#SYS_STACKS_Array+4088  ; so we can System Call during startup
;	sw      r1,TCB_SYS_Stack[tr]
;	sb      r0,TCB_hJCB[tr]             ; JCB#0 is the system JCB
;	bsr     GetJCBPtr
;	sw      r1,IOFocusNdx               ; The screen routines check this var
;	ldi     r2,#TEXTSCR
;	sw      r2,JCB_pVidMem[r1]          ; point JCB#0 to real screen
;	ldi		r4,#%000000100_110101110_0000000000	; grey on blue
;	sh		r4,JCB_NormAttr[r1]
;	sh		r4,JCB_CurrAttr[r1]
    ldi     r5,#$0000
    ldi     r1,#20
.0001:
    sc      r5,LEDS
    addui   r5,r5,#1
	sw		r0,Milliseconds
	ldi     r1,#-1
	sw      r1,API_sema
	sw      r0,BIOS1_sema
	bsr     UnlockBIOS
	bsr     UnlockVideoBIOS
	ldi		r1,#%000000100_110101110_0000000000
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	sh		r1,NormAttr
	ldi		r1,#VBDisplayChar
	sw		r1,OutputVec
	bsr		ClearScreen
	bsr		HomeCursor
	pea     msgStart
	bsr     DisplayStringCRLF
	addui   sp,sp,#8
	bsr		SetupIntVectors
	bsr     ROMChecksum
	bsr     dbg_init
;	bsr		KeybdInit
    ; set data breakpoint at FreeTCB address
;    ldi     r1,#$C00108
;    mtspr   dbad0,r1
;    ldi     r1,#$D0001
;    mtspr   dbctrl,r1
     lea     r1,sprite_main
     mtspr   dbad0,r1
     ldi     r1,#$80001
     mtspr   dbctrl,r1
;    ldi     sp,#$8000
;    bsr     ramtest
;    bsr     FMTKInitialize
    ldi     r1,#UserTickRout     ; set user tick vector
    sw      r1,$C00000
	bsr		InitPIC
	bsr     InitUart
	bsr     RTCCReadbuf          ; read the real-time clock
	bsr     set_time_serial      ; set the system time serial

	; Startup BIOS call task so that CPU#1 may make BIOS calls
	ldi     r1,#0                ; task priority
	ldi     r2,#0                ; cpu affinity
	ldi     r3,#BIOSCallTask|1   ; start address (start in kernel mode)
	ldi     r4,#0                ; start parameter
	ldi     r5,#0                ; owning job
;	sys     #FMTK_CALL
;	dh      1                    ; start task function
    bsr     DumpTaskList
	bra		Monitor

SerialStartMsg:
    push    lr
	ldi     r1,#SerialPutChar
	sw      r1,OutputVec
	ldi     r1,#msgStart
	bsr     DisplayStringCRLF
	ldi		r1,#DisplayChar
	sw		r1,OutputVec
    rts
 
SetupIntVectors:
	mtspr   vbr,r0               ; place vector table at $0000
	nop
	nop
	mfspr   r2,vbr
	ldi     r1,#UninitIRQ
	ldi     r3,#511
.0001:
	sw      r1,[r2+r3*8]
	subui   r3,r3,#1
	bge     r3,.0001
	ldi     r1,#BIOSCall
	sw      r1,10*8[r2]
	ldi     r1,#VideoBIOSCall
	sw      r1,410*8[r2]
	ldi		r1,#Tick1024Rout
	sw		r1,450*8[r2]
;	ldi		r1,#TickRout         ; This vector will be taken over by FMTK
;	sw		r1,451*8[r2]
	ldi     r1,#SerialIRQ
	sw      r1,456*8[r2]
	ldi     r1,#ServiceRequestIRQ
	sw      r1,457*8[r2]
	ldi		r1,#KeybdIRQ
	sw		r1,463*8[r2]
    ldi     r1,#SSM_ISR          ; set ISR vector for single step routine
    sw      r1,495*8[r2]
    ldi     r1,#BPT_ISR          ; set ISR vector for breakpoint routine
    sw      r1,496*8[r2]
	ldi		r1,#exf_rout
	sw		r1,497*8[r2]
	ldi		r1,#dwf_rout
	sw		r1,498*8[r2]
	ldi		r1,#drf_rout
	sw		r1,499*8[r2]
	ldi		r1,#priv_rout
	sw		r1,501*8[r2]
	ldi		r1,#berr_rout
	sw		r1,508*8[r2]
	ldi		r1,#berr_rout
	sw		r1,509*8[r2]
	ldi		r1,#nmi_rout
	sw		r1,510*8[r2]
    rtl
 
; Setup interrupt vector table for processor #1
SetupIntVectors1:
	mtspr   vbr,r0               ; place vector table at $0000
	nop
	nop
	mfspr   r2,vbr
	ldi     r1,#UninitIRQ
	ldi     r3,#511
.0001:
	sw      r1,[r2+r3*8]
	subui   r3,r3,#1
	bge     r3,.0001
	ldi     r1,#BIOSCall1
	sw      r1,10*8[r2]
	ldi		r1,#TickRout         ; This vector will be taken over by FMTK
	sw		r1,451*8[r2]
	ldi     r1,#ServiceRequestIRQ
	sw      r1,457*8[r2]
    ldi     r1,#SSM_ISR          ; set ISR vector for single step routine
    sw      r1,495*8[r2]
    ldi     r1,#BPT_ISR          ; set ISR vector for instruction breakpoint routine
    sw      r1,496*8[r2]
	ldi		r1,#exf_rout
	sw		r1,497*8[r2]
	ldi		r1,#dwf_rout
	sw		r1,498*8[r2]
	ldi		r1,#drf_rout
	sw		r1,499*8[r2]
	ldi		r1,#priv_rout
	sw		r1,501*8[r2]
	ldi		r1,#berr_rout
	sw		r1,508*8[r2]
	ldi		r1,#berr_rout
	sw		r1,509*8[r2]
	ldi		r1,#nmi_rout1
	sw		r1,510*8[r2]
    rtl
 
;------------------------------------------------------------------------------
; Initialize the interrupt controller.
;------------------------------------------------------------------------------

InitPIC:
	ldi		r1,#$000C		; timer interrupt(s) are edge sensitive
	sh		r1,PIC_ES
	ldi		r1,#$000F		; enable keyboard reset, timer interrupts
	sh		r1,PIC_IE
	rtl

; For CPU #1 the only interrupt to be serviced is the 30Hz time slice.

InitPIC1:
	ldi		r1,#$000C		; timer interrupt(s) are edge sensitive
	sh		r1,PIC_ES
	ldi		r1,#$000B		; enable keyboard reset, timer interrupts
	sh		r1,PIC_IE
	rtl

include "serial.s"
include "Video.s"


DispStartMsg:
    push    lr
	ldi		r1,#msgStart
	bsr		DisplayString
    rts

   
BranchToSelf2:
    bra      BranchToSelf2

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ROMChecksum:
    push     lr
    ldi      r2,#$10000
    ldi      r4,#0
    ldi      r3,#0
    ldi      r5,#0
.0001:
    lhu      r3,[r2+r4]
    addu     r5,r5,r3
    addui    r4,r4,#4
    cmp      r3,r4,#$10000
    blt      r3,.0001
    pea      msgROMChecksum
    bsr      DisplayString
    addui    sp,sp,#8
    mov      r1,r5
    bsr      DisplayHalf
    bsr      CRLF
    rts

msgROMChecksum:
    dc    CR,LF,"ROM Checksum: ",0

    align 4 
;------------------------------------------------------------------------------
; Display a space on the output device.
;------------------------------------------------------------------------------

DisplaySpace:
    push     lr
    push     r1
    ldi      r1,#' '
    bsr      OutChar
    pop      r1
    rts

;GetJCBPtr:
;    push    r2
;	lbu     r1,TCB_hJCB[tr]
;    beq     r1,.0001
;    cmpu    r2,r1,#NR_JCB
;    bge     r2,.0001
;	mulu    r1,r1,#JCB_Size
;	addui   r1,r1,#JCB_Array
;	pop     r2
;    rtl
;.0001:
;    pop     r2
;    ldi     r1,#JCB0
;    rtl 

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

LockBIOS:
    push    lr
    push    r1
    ldi     r1,#BIOS_sema
    bsr     LockSema
    pop     r1
    rts
UnlockBIOS:
    push    lr
    push    r1
    lea     r1,BIOS_sema
    bsr     UnlockSema
    pop     r1
    rts

LockBIOS1:
    push    lr
    push    r1
    ldi     r1,#BIOS1_sema
    bsr     LockSema
    pop     r1
    rts

;------------------------------------------------------------------------------
; Perform a BIOS call from CPU #1
; This routine sets up a structure variable in memory for the primary CPU
; to process.
;------------------------------------------------------------------------------

BIOSCall1:
    lw      sp,TCB_BIOS_Stack[tr]
    push    lr
    push    r10
    push    r11
    mfspr   r10,epc             ;
    addui   r10,r10,#4
    mtspr   epc,r10
    cmp     r10,r6,#MAX_BIOS_CALL
    bgt     r10,.0003
    bsr     LockBIOS1
    sw      r6,BIOS_op
    sw      r1,BIOS_arg1
    sw      r2,BIOS_arg2
    sw      r3,BIOS_arg3
    sw      r4,BIOS_arg4
    sw      r5,BIOS_arg5
    sw      r0,BIOS_resp
    sw      r0,BIOS_stat
    lw      r1,BIOS_MbxHandle
    ldi     r2,#BIOS_op          ;
    lw      r3,BIOS_RespMbx      ; response mailbox handle
    sys     #FMTK_CALL
    dh      9                    ; SendMsg
    lw      r1,BIOS_RespMbx
    ldi     r2,#-1
    sys     #FMTK_CALL
    dh      10                   ; WaitMsg
    cmp     r7,r1,#E_Timeout
    bne     r7,.0004
    ldi     r2,#BIOS_E_Timeout
    bra     .0002
.0004:
    mov     r1,r2
.0002:
    sw      r0,BIOS1_sema
    pop     r11
    pop     r10
    pop     lr
    rte
.0003:
    ldi     r2,#E_BadFuncno
    pop     r11
    pop     r10
    pop     lr
    rte

;------------------------------------------------------------------------------
; BIOSCall
;
; Peform a BIOS function for CPU #0
;
; Parameters:
; r1 = first function argument
; r2 = second function argument
; r3 = third function argument
; r4 = fourth function argument
; r5 = fifth function argument
; r6 = function
;
; Returns:
; r1 = response from BIOS routine
;------------------------------------------------------------------------------

BIOSCall:
    lw      sp,352[tr]
    push    lr
    bsr     LockBIOS
    push    r10
    mfspr   r10,epc             ; update the return address
    addui   r10,r10,#4
    mtspr   epc,r10
    cmp     r10,r6,#MAX_BIOS_CALL
    bgt     r10,.0003
    ldi     r10,#BIOS_FuncTable
    lcu     r10,[r10+r6*2]
    or      r10,r10,#BIOSCall & 0xFFFFFFFFFFFF0000
    jsr     [r10]
    ldi     r1,#$5678
    sc      r1,LEDS
.0004:
    bsr     UnlockBIOS
    pop     r10
    pop     lr
    rte
.0003:
    ldi     r2,#E_BadFuncno
    bra     .0004

;------------------------------------------------------------------------------
; This task is a BIOS service task.
;------------------------------------------------------------------------------

BIOSCallTask:
    ; Get a mailbox for BIOS calls
    ldi     r1,#BIOS_MbxHandle
    sys     #FMTK_CALL            ; call FMTK AllocMbx function
    dh      6
.0001:
    lw      r1,BIOS_MbxHandle
    ldi     r2,#-1                ; infinite timeout
    sys     #FMTK_CALL
    dh      10                    ; call FMTK Waitmsg Function
    cmp     r11,r1,#E_Ok          ; ignore bad reponses
    bne     r11,.0001
    mov     r11,r2
    mov     r12,r3
    mov     r11,r0   ; for now
    lw      r6,BIOS_op[r11]
    lw      r1,BIOS_arg1[r11]
    lw      r2,BIOS_arg2[r11]
    lw      r3,BIOS_arg3[r11]
    lw      r4,BIOS_arg4[r11]
    lw      r5,BIOS_arg5[r11]
;    sys     #BIOS_CALL
    beq     r12,.0001
    sw      r1,BIOS_resp[r11]
    mov     r2,r1                ; r2 = return value from BIOS
    mov     r1,r12               ; r1 = mailbox to respond to
    ldi     r3,#0                ; r3 = not used
    sys     #FMTK_CALL
    dh      8                    ; PostMsg
    bra     .0001        

;------------------------------------------------------------------------------
; 60 Hz interrupt routine.
; Both cpu's will execute this interrupt.
;------------------------------------------------------------------------------

TickRout:
    ldi     sp,#irq_stack       ; set stack pointer to interrupt processing stack
    push    lr
    push    r1
	ldi		r1,#3				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	cpuid   r1,r0,#0
	bne     r1,.0001
	bsr     UserTickRout
.0001:
	pop     r1
	pop     lr
	rti

UserTickRout:
    push    r1
	lh	    r1,TEXTSCR+220
	addui	r1,r1,#1
	sh	    r1,TEXTSCR+220
	lw      r1,$20000
	sh      r1,TEXTSCR+224
	pop     r1
    rtl

;------------------------------------------------------------------------------
; 1024Hz interupt routine. This must be fast. Allows the system time to be
; gotten by right shifting by 10 bits.
;------------------------------------------------------------------------------

Tick1024Rout:
    ldi     sp,#irq_stack  ; set stack pointer to interrupt processing stack
	push	r1
	ldi		r1,#2				; reset the edge sense circuit
	sh		r1,PIC_RSTE
	inc     Milliseconds
	pop		r1
	rti                         ; restore stack pointer and return

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


	dc	0
msgStart:
	dc	"FISA64 test system starting.",0


; ============================================================================
; Monitor Task
; ============================================================================
    align   4
Monitor:
	pea		msgMonitorStarted
	bsr		DisplayStringCRLF
	addui   sp,sp,#8
	sb		r0,KeybdEcho
	ldi     r1,#JCB0
	sb      r0,JCB_KeybdEcho[r1]
	ldi		r1,#7
	ldi		r2,#0
	ldi		r3,#IdleTask|1
	ldi		r4,#0
	ldi		r5,#0
;	sys     #4                  ; start task
;	dh      1
mon1:
;	ldi		sp,#TCBs+TCB_Size-8		; reload the stack pointer, it may have been trashed
	ldi		sp,#MON_STACK
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
	push    r0
	bsr     SetCursorCol
	addui   sp,sp,#8
	bsr		CalcScreenLocation
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
	cmp		r2,r1,#'F'
	beq		r2,doFillmem
	cmp		r2,r1,#'m'
	beq		r2,MRTest
	cmp		r2,r1,#'S'
	beq		r2,doSDBoot
	cmp		r2,r1,#'g'
	beq		r2,doRand
	cmp		r2,r1,#'e'
	beq		r2,eval
	cmp		r2,r1,#'J'
	beq		r2,doJump
	cmp		r2,r1,#'D'
	beq		r2,doDate
	cmp     r2,r1,#'T'
	beq     r2,doDumpTL
	bra     mon1

.doHelp:
	pea		msgHelp
	bsr		DisplayString
	addui   sp,sp,#8
	bra     mon1

MonGetch:
    push    lr
	lhu	    r1,[r3]
	andi	r1,r1,#$1FF
	add		r3,r3,#4
	push    r3
	push    r1
	bsr		ScreenToAscii
	addui   sp,sp,#8
	pop     r3
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
;	bra     mon1
.001:
	bsr		CheckKeys
	bsr		DisplayMemBytes
	cmpu	r4,r2,r1
	ble		r4,.001
	bra     mon1

doDumpTL:
    bsr     DumpTaskList
    bra     mon1

;------------------------------------------------------------------------------
; Fill memory
;
; FB FFD80000 FFD8FFFF r	; fill sprite memory with random bytes
;------------------------------------------------------------------------------

doFillmem:
	bsr		CursorOff
	bsr		MonGetch		; skip over 'B' of "FB"
	cmp		r2,r1,#'B'
	beq		r2,.0004
	subui	r3,r3,#4		; backup text pointer
.0004:
	bsr		GetRange
	push	r1
    push    r2
	bsr		ignBlanks
	bsr		MonGetch		; check for random fill
	cmp		r2,r1,#'r'
	beq		r2,.0001
	subui   r3,r3,#4
	bsr		GetHexNumber
	mov		r3,r1
	pop		r2
    pop     r1
.0002:
	bsr		CheckKeys
	sb		r3,[r2]
	addui	r2,r2,#1
	cmpu	r5,r2,r1
	blt		r5,.0002
	bra		mon1
.0001:
	pop		r2
    pop     r1
.0003:
	bsr		CheckKeys
	lw	    r3,RANDOM_NUM
	sb		r3,[r2]
	addui	r2,r2,#1
	cmpu	r5,r2,r1
	blt		r5,.0003
	bra		mon1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

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
; Jump to subroutine
;
; J 10000     ; restart system
;------------------------------------------------------------------------------

doJump:
	bsr		MonGetch		; skip over 'S'
	bsr		ignBlanks
	bsr		GetHexNumber
	sw      r1,jmp_vector
    lw      r31,MON_r31
    lw      r30,MON_r30
    lw      r29,MON_r29
    lw      r28,MON_r28
    lw      r27,MON_r27
    lw      r26,MON_r26
    lw      r25,MON_r25
;   lw      r24,MON_r24    ; r24 is the task register - no need to load
    lw      r23,MON_r23
    lw      r22,MON_r22
    lw      r21,MON_r21
    lw      r20,MON_r20
    lw      r19,MON_r19
    lw      r18,MON_r18
    lw      r17,MON_r17
    lw      r16,MON_r16
    lw      r15,MON_r15
    lw      r14,MON_r14
    lw      r13,MON_r13
    lw      r12,MON_r12
    lw      r11,MON_r11
    lw      r10,MON_r10
    lw      r9,MON_r9
    lw      r8,MON_r8
    lw      r7,MON_r7
    lw      r6,MON_r6
    lw      r5,MON_r5
    lw      r4,MON_r4
    lw      r3,MON_r3
    lw      r2,MON_r2
    lw      r1,MON_r1
    jsr		(jmp_vector)
    sw      r1,MON_r1
    sw      r2,MON_r2
    sw      r3,MON_r3
    sw      r4,MON_r4
    sw      r5,MON_r5
    sw      r6,MON_r6
    sw      r7,MON_r7
    sw      r8,MON_r8
    sw      r9,MON_r9
    sw      r10,MON_r10
    sw      r11,MON_r11
    sw      r12,MON_r12
    sw      r13,MON_r13
    sw      r14,MON_r14
    sw      r15,MON_r15
    sw      r16,MON_r16
    sw      r17,MON_r17
    sw      r18,MON_r18
    sw      r19,MON_r19
    sw      r20,MON_r20
    sw      r21,MON_r21
    sw      r22,MON_r22
    sw      r23,MON_r23
    sw      r24,MON_r24
    sw      r25,MON_r25
    sw      r26,MON_r26
    sw      r27,MON_r27
    sw      r28,MON_r28
    sw      r29,MON_r29
    sw      r30,MON_r30
    sw      r31,MON_r31
	bra		mon1

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

doDate:
	bsr		MonGetch		; skip over 'T'
	cmp     r5,r1,#'B'
	beq     r5,doDebug
	cmp		r5,r1,#'A'		; look for DAY
	beq		r5,doDay
	cmp     r5,r1,#'T'
	bne     r5,doDisassem
	bsr		ignBlanks
	bsr		MonGetch
	cmp		r5,r1,#'?'
	beq		r5,.0001
	subui	r3,r3,#4
	bsr		GetHexNumber
	sb		r1,RTCC_BUF+5	; update month
	bsr		GetHexNumber
	sb		r1,RTCC_BUF+4	; update day
	bsr		GetHexNumber
	sb		r1,RTCC_BUF+6	; update year
	bsr		RTCCWritebuf
	bra		mon1
.0001:
	bsr		RTCCReadbuf
	bsr		CRLF
	lbu		r1,RTCC_BUF+5
	bsr		DisplayByte
	ldi		r1,#'/'
	bsr		OutChar
	lbu		r1,RTCC_BUF+4
	bsr		DisplayByte
	ldi		r1,#'/'
	bsr		OutChar
	lbu		r1,RTCC_BUF+6
	bsr		DisplayByte
	bsr		CRLF
	bra		mon1

doDay:
	bsr		ignBlanks
	bsr		GetHexNumber
	mov		r3,r1			; value to write
	ldi		r1,#$6F			; device $6F
	ldi		r2,#$03			; register 3
	bsr		I2C_WRITE
	bra		mon1

doDisassem:
    subui   r3,r3,#4
    bsr     ignBlanks
    bsr     GetHexNumber
    subu    r1,r1,#32
    push    r1
    addu    r1,r1,#32
    push    r1
    bsr     disassem20
    addui   sp,sp,#16
    bra     mon1

doDebug:
   bsr   ignBlanks
   bsr   GetHexNumber
   push  #0
   push  r1
   bsr   debugger
   addui sp,sp,#16
   bra   mon1

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
	bsr     CheckScrollLock
	pop     lr
	rtl

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
    push    lr
	push	r1
	push    r2
.0002:
	lcu		r1,KeybdLocks
	and		r2,r1,#$4000		; is scroll lock active ?
	beq		r2,.0001
;	brk		#2*16				; reschedule tasks
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
	dc	"**Err",CR,LF,0

msgHelp:
	dc		"? = Display Help",CR,LF
	dc		"CLS = clear screen",CR,LF
	dc      "D = disassemble",CR,LF
	dc      "DB = start debugger",CR,LF
	dc		"DT = set/read date",CR,LF
	dc		"FB = fill memory",CR,LF
	dc		"MB = dump memory",CR,LF
	dc		"JS = jump to code",CR,LF
	dc	    "T = Dump task list",CR,LF
	dc		"S = boot from SD card",CR,LF
	dc		0

msgMonitorStarted
	dc		"Monitor started.",0

doCLS:
	bsr		ClearScreen
	bsr		HomeCursor
	bra     mon1

;------------------------------------------------------------------------------
; Get a random number from peripheral device.
;------------------------------------------------------------------------------

GetRandomNumber:
    lw      r1,$FFDC0C00
    rtl
                
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
	dc		"Keyboard not responding.",0

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
    push    r2
    lbu     r2,TCB_hJCB[tr]
    cmp     r1,r2,#NR_JCB
    bge     r1,.0001
    mulu    r2,#JCB_Size
    addui   r2,r2,#JCB_Array
    push    r3
    push    r4
    push    lr
    bsr     LockSYS
    lbu     r1,JCB_KeybdHead[r2]
    lbu     r3,JCB_KeybdTail[r2]
    bsr     UnlockSYS
    cmpu    r4,r1,r3
    beq     r4,.0002
    ldi     r1,#-1
    pop     lr
    pop     r4
    pop     r3
    pop     r2
    rtl
.0002:
    pop     lr
    pop     r4
    pop     r3
.0001:
    ldi     r1,#0   ; no scancode available
    pop     r2
    rtl

; Get the scancode from the keyboard port
;
KeybdGetScancode:
	lbu		r1,KEYBD				; get the scan code
	sb		r0,KEYBD+1				; clear receive register
	rtl
    push    r2
    lbu     r2,TCB_hJCB[tr]
    cmp     r1,r2,#NR_JCB
    bge     r1,.0001
    mulu    r2,#JCB_Size
    addui   r2,r2,#JCB_Array
    push    r3
    push    r4
    push    lr
    bsr     LockSYS
    lbu     r1,JCB_KeybdHead[r2]
    lbu     r3,JCB_KeybdTail[r2]
    cmpu    r4,r1,r3
    beq     r4,.0002
    lea     r4,JCB_KeybdBuffer[r2]
    lbu     r1,[r4+r3]
    addui   r3,r3,#1
    and     r3,r3,#31 ; mod 32
    sb      r3,JCB_KeybdTail[r2]
    bsr     UnlockSYS
    pop     lr
    pop     r4
    pop     r3
    pop     r2
    rtl
.0002:
    bsr     UnlockSYS
    pop     lr
    pop     r4
    pop     r3
.0001:
    ldi     r1,#0   ; no scancode available
    pop     r2
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

;
; KeyState2
; 876543210
; ||||||||+ = alt
; |||||||+- =
; ||||||+-- = control
; |||||+--- = numlock
; ||||+---- = capslock
; |||+----- = scrolllock
; ||+------ =
; |+------- = 
; +-------- = extended
;
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
	beq		r2,.doScrollLock
	cmp     r2,r1,#SC_ALT
	beq     r2,.doAlt
	lb		r2,KeyState1			; check key up/down
	sb		r0,KeyState1			; clear keyup status
	bne	    r2,.0003				; ignore key up
	cmp     r2,r1,#SC_TAB
	beq     r2,.doTab
.0013:
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
.doAlt:
	lb		r1,KeyState1
	sb		r0,KeyState1
	bpl		r1,.0011
    lb      r1,KeyState2
	lb		r1,KeyState2
	and		r1,r1,#-2
	sb		r1,KeyState2
	bra		.0003
.0011:
	lb		r1,KeyState2
	or		r1,r1,#1
	sb		r1,KeyState2
	bra		.0003
.doTab:
    push    r1
    lb      r1,KeyState2
    and     r1,r1,#1                 ; is ALT down ?
    beq     r1,.0012
    inc     iof_switch
    pop     r1
    bra     .0003
.0012:
    pop     r1
    bra     .0013
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
	lb		r1,KeyState2
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

;------------------------------------------------------------------------------
; KeybdIRQ
;     Keyboard interrupt processing routine. Must be short.
; Grab a scancode from the keyboard and place it into the keyboard buffer
; for the job with the I/O focus.
;------------------------------------------------------------------------------

KeybdIRQ:
    ldi     sp,#irq_stack
    push    lr
    push    r1
    push    r2
    push    r3
    push    r4
    lb      r1,KEYBD+1      ; get the keyboard status
    bgt     r1,.0001        ; is there a scancode present ?
	lbu		r1,KEYBD		; get the scan code
	sb		r0,KEYBD+1		; clear receive register (acknowledges interrupt)
	lw      r2,IOFocusNdx   ; get task with I/O focus
	beq     r2,.0001
    lb      r2,TCB_hJCB[r2] ; get JCB handle
    cmpu    r3,r3,#NR_JCB   ; make sure valid handle
    bge     r3,.0001
    mulu    r2,r2,#JCB_Size ; and convert it to a pointer
    addui   r2,r2,#JCB_Array
    bsr     LockSYS
    lbu     r3,JCB_KeybdHead[r2]  ; get head index of keyboard buffer
    lbu     r4,JCB_KeybdTail[r2]  ; get tail index of keyboard buffer
    addui   r3,r3,#1        ; advance head      
    and     r3,r3,#31       ; mod 32
    cmp     r5,r3,r4        ; is there room in the buffer ?
    beq     r5,.0002        ; if not, newest chars will be lost
    sb      r3,JCB_KeybdHead[r2]
    lea     r2,JCB_KeybdBuffer[r2]
    sb      r1,[r2+r3]      ; save off the scan code
    bsr     UnlockSYS
    lb      r2,KeyState2    ; check for ALT-tab
    and     r2,r2,#1        ; is ALT down ?
    beq     r2,.0001        
    cmp     r2,r1,#SC_TAB
    bne     r2,.0001
    inc     iof_switch      ; flag an I/O focus switch
.0001:
    pop     r4
    pop     r3
    pop     r2
	pop     r1
	pop     lr
    rti
.0002:
    bsr     UnlockSYS
    bra     .0001
KeybdIRQ1:
    rti


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


; ============================================================================
; I2C interface to RTCC
; ============================================================================

I2C_INIT:
    push    r1
    push    r2
	ldi		r2,#I2C_MASTER
	sb		r0,I2C_CONTROL[r2]		; disable the contoller
	sb		r0,I2C_PRESCALE_HI[r2]	; set clock divisor for 100kHz
	ldi		r1,#99					; 24=400kHz, 99=100KHz
	sb		r1,I2C_PRESCALE_LO[r2]
	ldi		r1,#$80					; controller enable bit
	sb		r1,I2C_CONTROL[r2]
	pop		r2
    pop     r1
	rtl

;------------------------------------------------------------------------------
; I2C Read
;
; Parameters:
; 	r1 = device ($6F for RTCC)
; 	r2 = register to read
; Returns
; 	r1 = register value $00 to $FF if successful, else r1 = -1 on error
;------------------------------------------------------------------------------
;
I2C_READ:
    push    lr
	push	r2
    push    r3
    push    r4
	asl		r1,r1,#1				; clear rw bit for write
;	or		r1,r1,#1				; set rw bit for a read
	mov		r4,r1					; save device address in r4
	mov		r3,r2
	; transmit device #
	ldi		r2,#I2C_MASTER
	sb		r1,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete
	; transmit register #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	sb		r3,I2C_TX[r2]			; select register r3
	ldi		r1,#$10					; set WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC

	; transmit device #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	or		r4,r4,#1				; set read flag
	sb		r4,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete

	; receive data byte
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne	    r1,I2C_ERR
	ldi		r1,#$68					; STO($40), RD($20), and NACK($08)
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	lbu		r1,I2C_RX[r2]			; $00 to $FF = byte read, -1=err
	pop		r4
    pop     r3
    pop     r2
	rts

I2C_ERR:
	ldi		r1,#-1
	mtspr	cr0,r5					; restore TMR
	pop     r4
	pop     r3
	pop     r2
	rts

;------------------------------------------------------------------------------
; I2C Write
;
; Parameters:
; 	r1 = device ($6F)
; 	r2 = register to write
; 	r3 = value for register
; Returns
; 	r1 = 0 if successful, else r1 = -1 on error
;------------------------------------------------------------------------------
;
I2C_WRITE:
	push	lr
    push    r2
    push    r3
    push    r4
	asl		r1,r1,#1				; clear rw bit for write
	mov		r4,r3					; save value r4
	mov		r3,r2
	; transmit device #
	ldi		r2,#I2C_MASTER			; r2 = I/O base address of controller
	sb		r1,I2C_TX[r2]
	ldi		r1,#$90					; STA($80) and WR($10) bits set
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC				; wait for transmit to complete
	; transmit register #
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne  	r1,I2C_ERR
	sb		r3,I2C_TX[r2]			; select register r3
	ldi		r1,#$10					; set WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	; transmit value
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#$80				; test RxACK bit
	bne  	r1,I2C_ERR
	sb		r4,I2C_TX[r2]			; select value in r4
	ldi		r1,#$50					; set STO, WR bit
	sb		r1,I2C_CMD[r2]
	bsr		I2C_WAIT_TC
	ldi		r1,#0					; everything okay
	pop		r4
    pop     r3
    pop     r2
	rts

; Wait for I2C controller transmit complete

I2C_WAIT_TC:
.0001:
	lb		r1,I2C_STAT[r2]
	and		r1,r1,#2
	bne 	r1,.0001
	rtl

; Read the entire contents of the RTCC including 64 SRAM bytes

RTCCReadbuf:
    push    lr
	bsr		I2C_INIT
	ldi		r2,#$00
.0001:
	ldi		r1,#$6F
	bsr		I2C_READ
	sb		r1,RTCC_BUF[r2]
	add		r2,r2,#1
	cmpu	r1,r2,#$60
	blt		r1,.0001
	rts

; Write the entire contents of the RTCC including 64 SRAM bytes

RTCCWritebuf:
    push    lr
	bsr		I2C_INIT
	ldi		r2,#$00
.0001:
	ldi		r1,#$6F
	lbu		r3,RTCC_BUF[r2]
	bsr		I2C_WRITE
	add		r2,r2,#1
	cmpu	r1,r2,#$60
	blt		r1,.0001
	rts

RTCCOscOn:
    push    lr
	bsr		I2C_INIT
	ldi		r1,#$6F
	ldi		r2,#$00			; register zero
	bsr		I2C_READ		; read register zero
	or		r3,r1,#$80		; set start osc bit
	ldi		r1,#$6F
	bsr		I2C_WRITE
	rts

; ============================================================================
; SD/MMC Card interface
; ============================================================================
SD_INIT:
    push    lr
	ldi		r3,#SD_MASTER
	ldi		r2,#25000
	sc		r2,0x2c[r3]		; timeout register
	; Software reset should be held active for several cycles to allow
	; reset to be detected on the sd_clk domain.
	ldi		r2,#1
	sb		r2,0x28[r3]		; software reset reg
	ldi		r2,#2
	sb		r2,0x4c[r3]		; prog /6 for clock divider
	ldi		r1,#100			; software reset delay
	bsr     MicroDelay
	sb		r0,0x28[r3]		; clear software reset
	sc		r0,0x04[r3]		; command 0
	sh		r0,0x00[r3]		; arg 0
	bsr		SD_WAIT_RESP
	lh		r1,0x0C[r3]		; read response register
	bsr		DisplayHalf
	rts

SD_CMD8:
    push    lr
	ldi		r3,#SD_MASTER
	ldi		r2,#$81A
	sc		r2,0x04[r3]		; set command register
	ldi		r2,#$1AA
	sh		r2,0x00[r3]		; set command argument x1AA
	bsr		SD_WAIT_RESP
	sb		r1,SD_2_0
	lh		r1,0x0C[r3]		; read response register
	bsr		DisplayHalf
	; send command zero
	sc		r0,0x04[r3]
	sh		r0,0x00[r3]
	bsr		SD_WAIT_RESP
	lbu		r1,SD_2_0
	beq		r1,.0001
	ldi		r1,#'2'
	bsr		OutChar
	ldi		r1,#'.'
	bsr		OutChar
	ldi		r1,#'0'
	bsr		OutChar
	bsr		CRLF
	rts
.0001:
	sc		r0,0x04[r3]		; send CMD0
	sh		r0,0x00[r3]
.0002:
	lcu		r1,0x08[r3]
	and		r1,r1,#1
	bne  	r1,.0002
	mov		r4,r0			; ret_reg = r4 = 0
.0004:
	mov		r5,r4
	and		r4,r4,#$80000000
	bne  	r4,.0003
	ldi		r1,#$3702		; CMD55|RSP48
	sc		r1,0x04[r3]
	sh		r0,0x00[r3]
	bsr		SD_WAIT_RESP
	bne  	r1,.respOk
	ldi		r1,#$2902		; ACMD41|RSP48
	sc		r1,0x04[r3]
	sh		r0,0x00[r3]
	bsr		SD_WAIT_RESP
	bne  	r1,.respOk
	lh		r4,0x0c[r3]		; ret_reg = RESP1
	mov		r1,r4
	bsr		DisplayHalf
	bsr		CRLF
	bra		.0004
.0003:
	and		r1,r5,#$FFFFFF	; voltage mask
	bsr		DisplayHalf
	bsr		CRLF
	; GetCID
	ldi		r1,#$201		; CMD2 + RSP146
	sc		r1,0x04[r3]
	sh		r0,0x00[r3]
	bsr		SD_WAIT_RESP
	; GetRCA
	ldi		r1,#$31A		; CMD3 + CICE + CRCE + RSP48
	sc		r1,0x04[r3]
	sh		r0,0x00[r3]
	bsr		SD_WAIT_RESP
	lh		r4,0x0c[r3]			; r4 = RESP1
	and		r1,r4,#$FFFF0000	; r4 & RCA_MASK
	bsr		DisplayHalf
	bsr		CRLF
.respOk:
	ldi		r1,#'O'
	bsr		OutChar
	ldi		r1,#'k'
	bsr		OutChar
	bsr		CRLF
	rts

SD_WAIT_RESP:
    push    lr
	push	r2
    push    r3
	ldi		r2,#SD_MASTER
.0001:
	lc		r3,0x34[r2]		; read error interrupt status reg
	lc		r1,0x30[r2]		; read normal interrupt status reg
	and		r3,r3,#1		; get command timeout indicator
	bne  	r3,.0002
	and		r1,r1,#1		; wait for command complete bit to set
	beq		r1,.0001
	ldi		r1,#1
	pop		r3
    pop     r2
    pop     lr
	rtl
.0002:
	ldi		r1,#'T'
	bsr		OutChar
	ldi		r1,#'O'
	bsr		OutChar
	bsr		CRLF
	ldi		r1,#0
	pop		r3
    pop     r2
    pop     lr
	rtl

; ============================================================================
; ============================================================================

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

;------------------------------------------------------------------------------
; MicroDelay
;     Delay for a short time for at least the specified number of clock cycles
;
; Parameters:
;     r1 = required delay in clock ticks
;------------------------------------------------------------------------------
;
MicroDelay:
    push    r2
    push    r3
    mfspr   r3,tick             ; get starting tick
.0001:
    mfspr   r2,tick
    subu    r2,r2,r3
    cmp     r2,r2,r1
    blt     r2,.0001
    pop     r3
    pop     r2
    rtl
;
    nop
    nop

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

LoadFromSerial:
    push    lr
    ldi     r3,#16384
    ldi     r2,#$24000          ; target store address
.0001:
    bsr     SerialGetCharDirect
    sb      r1,[r2]
    addui   r2,r2,#1
    subui   r3,r3,#1
    bne     r3,.0001
    rts

nmi_rout:
    ldi    sp,#irq_stack
    push   r1
    pea    msgParErr
    bsr    DisplayStringCRLF
    addui  sp,sp,#8
    bsr    KeybdGetCharWait
    pop    r1
    rti

nmi_rout1:
    rti

msgParErr:
    dc "Parity error",0
    
    align  4
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
    lw      sp,TCB_SYS_Stack[tr]
	ldi		r1,#$bc
	sc		r1,LEDS
	pea		msgPriv
	bsr		DisplayString
	addui   sp,sp,#8
	mfspr   r1,epc
	bsr     DisplayHalf
	bsr     CRLF
	bsr		KeybdGetCharWait
	ldi     r1,#Monitor|1
	mtspr   epc,r1
	nop
	nop
	rte
.0001:
	bra .0001

;------------------------------------------------------------------------------
; Message strings for the faults.
;------------------------------------------------------------------------------

msgexf:
	dc	"exf ",0
msgdrf:
	dc	"drf ",0
msgdwf:
	dc	"dwf ",0
msgPriv:
	dc	"priv fault: PC=",0
msgUninit:
	dc	"uninit int.",0
msgBusErr:
    dc  CR,LF,"Bus error PC=",0
msgEA:
    dc  " EA=",0
msgUninitIRQ:
    dc  "Uninitialized IRQ: ",0

    align 4
UninitIRQ:
    pea   msgUninitIRQ
    bsr   DisplayString
    addui sp,sp,#8
    mfspr r1,12          ; vecno
    bsr   DisplayCharHex
	bsr     CRLF
	bsr		KeybdGetCharWait
	bra   start
.0001:
    bra   .0001

;------------------------------------------------------------------------------
; Bus error routine.
;------------------------------------------------------------------------------

berr_rout:
    ldi     sp,#$7800
	ldi		r1,#$bebe
	sc		r1,LEDS
	pea     msgBusErr
	bsr     DisplayString
	addui   sp,sp,#8
	mfspr   r1,ipc
	bsr		DisplayWord
	pea     msgEA
	bsr     DisplayString
	addui   sp,sp,#8
    mfspr   r1,bear
	bsr     DisplayWord
	bsr     CRLF
	bsr		KeybdGetCharWait

	; In order to return an RTI must be used to exit the routine (or interrupts
	; will permanently disabled). The RTI instruction clears an internal
	; processor flag used to prevent nested interrupts.
	; Since this is a serious error the system is just restarted. So the IPC
	; is set to point to the restart address.

	ldi     r1,#start|1
	mtspr   ipc,r1
	
	; Allow pipeline time for IPC to update before RTI (there's no results
	; forwarding on SPR's).
	nop     
	nop
	rti


SSM_ISR:
    rtd

; -----------------------------------------------------------------------------
; Breakpoint routine.
; -----------------------------------------------------------------------------

BPT_ISR:
    ldi      sp,#CPU0_DBG_STACK
    mtspr    dbctrl,r0
    mfspr    r1,dpc
    and      r1,r1,#-2        ; clear LSB
    push     r1
    subui    r1,r1,#32
    push     r1
    bsr      disassem20
	bsr		 KeybdGetCharWait
    rtd
.0001:
    bra     .0001

include "set_time_serial.s"
include "sprite_demo.s"
;include "FMTK_Equates.inc"
include "FMTKc.s"
include "console.s"
include "Semaphore.s"
include "IOFocusc.s"
include "stdio.s"
include "ctype.s"
include "disassem.s"
include "debugger.s"
include "ramtest.s"
message "hit end"
    nop
    nop

