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
E_BadMbx    EQU     $05
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

TCB_BIOS_Stack  = $280

DBG_STACK   EQU     $7000
CPU0_DBG_STACK  EQU     $7CF000
CPU0_IRQ_STACK  EQU     $32000
CPU0_BIOS_STACK  EQU     $6800
MON_STACK   EQU     $6000
; CPU1 Ram allocations must be to the dram area.
CPU1_SYS_STACK      EQU  $31000
CPU1_BIOS_STACK     EQU  $31800
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
CursorRow		dc		0
CursorCol		dc		0
Dummy1			dc		0
KeybdEcho		db		0
KeybdBad		db		0
KeybdLocks		dc		0
KeybdWaitFlag	db		0
KeybdLEDs		db		0
NUMWKA          fill.b  64,0
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
BIOS_MbxHandle  dw      0
StartCPU1Flag   dw      0
StartCPU1Addr   dw      0
CPUIdleTick     dw      0
                dw      0
                dw      0
                dw      0

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
	dw		ClearScreen_	; $8000
	dw		HomeCursor_		; $8008
	dw		DisplayString_	; $8010
	dw		KeybdGetCharNoWait; $8018
	dw		ClearBmpScreen_	; $8020
	dw		DisplayChar_		; $8028
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
    dc      ClearScreen_
    dc      HomeCursor_
    dc      DisplayString_
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
    sw      r0,FMTK_Inited_
    cpuid   r1,r0,#0
    beq     r1,CPU0_Start
;==============================================================================
; Starup for CPU #1
;==============================================================================
CPU1_Start:
    ; First thing to do is set the stack pointer. The stack for task #1 is
    ; used.
    ldi     sp,#stacks_+8192+8192-8
;    ldi     tr,#tcbs+TCB_Size
;	sw      sp,TCB_ISP[tr]
;	sw      sp,TCB_r30[tr]
;	ldi     r1,#BIOS_STACKS_Array+4096+4088  ; so we can call the BIOS during startup
;	sw      r1,TCB_BIOS_Stack[tr]
;	ldi     r1,#SYS_STACKS_Array+4096+4088  ; so we can call the BIOS during startup
;	sw      r1,TCB_SYS_Stack[tr]
;	sb      r0,TCB_hJCB[tr]             ; JCB#0 is the system JCB
    bsr     SetupIntVectors1
	bsr		InitPIC_
	bsr     UnlockBIOS1
	; Wait for CPU #0 to complete FMTK initialization before proceeding.
.0001:
    nop
    nop
;	lw      r1,FMTK_Inited_
;	cmpu    r1,r1,#$12345678
;	bne     r1,.0001
;	bsr     FMTKInitialize_       ;  Initialize for CPU #1
.0003:
    cli
    inc     $30000
    lw      r1,StartCPU1Flag
    cmp     r1,r1,#$12345678
    bne     r1,.0003
    jmp     (StartCPU1Addr)

;==============================================================================
; Starup for CPU #0
;==============================================================================
CPU0_Start:
    ; First thing to do is set the stack pointer. The stack for task #0 is
    ; used.
	ldi     sp,#stacks_+8192-8
	ldi     r26,#0                ; set global pointer to zero
    ldi     r1,#1                 ; indicate we booted
    sc      r1,LEDS


    ldi     r1,#$30000
.zap_loop:
    sw      r0,[r1]
    addui   r1,r1,#8
    cmpu    r2,r1,#$2000000
    blt     r2,.zap_loop

	; Copy initialized data to data area. This must be done ro support the
	; linked in 'C' modules. The special symbols begin_init_data and
	; end_init_data identify where the initialization data is.
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

    ; This has to be done before FMTKInitialize is called or other vectors
    ; which are set because it first initializes all vectors to the
    ; uninitialized IRQ vector.
	bsr		SetupIntVectors
    ldi     r1,#12
    sc      r1,LEDS
    
    ldi     r1,#1          ; system is a member of memory group #1
    mtspr   42,r1

    ; Initialize the memory allocation system
;    push    #0
;    push    #0
;    push    #0
;    bsr     sys_alloc_

    ldi     r1,#14
    sc      r1,LEDS

	bsr     FMTKInitialize_
    ldi     r1,#15
    sc      r1,LEDS

    ldi     r1,#20
    sc      r1,LEDS
	sw		r0,Milliseconds
	ldi     r1,#-1
	sw      r1,API_sema
	bsr     UnlockBIOS
	bsr     UnlockVideoBIOS
    ldi     r1,#21
    sc      r1,LEDS
	ldi		r1,#%000000100_110101110_0000000000
	sb		r1,KeybdEcho
	sb		r0,KeybdBad
	ldi		r1,#VBDisplayChar
	sw		r1,OutputVec
	bsr		ClearScreen_
	bsr		HomeCursor_
    ldi     r1,#17
    sc      r1,LEDS
	pea     msgStart
	bsr     DisplayStringCRLF_
	addui   sp,sp,#8
	bsr     ROMChecksum
    ldi     r1,#19
    sc      r1,LEDS
	bsr     dbg_init_
    ldi     r1,#21
    sc      r1,LEDS
    ; Keyboard init seems to always have a bad return, but the keyboard works
    ; anyways so we skip over it.
;	bsr		KeybdInit
    ; set data breakpoint at FreeTCB address
;    ldi     r1,#$C00108
;    mtspr   dbad0,r1
;    ldi     r1,#$D0001
;    mtspr   dbctrl,r1

    ; Setup a breakpoint somewhere in the instruction space so that we can test
    ; the debugger. The debugger can then be invoked by jumping to the
    ; breakpoint address.
     lea     r1,sprite_main
     mtspr   dbad0,r1
     ldi     r1,#$80001
     mtspr   dbctrl,r1

;    bsr     ramtest
    ldi     r1,#UserTickRout     ; set user tick vector
    sw      r1,$C00000
	bsr		InitPIC_
    ldi     r1,#22
    sc      r1,LEDS
	bsr     InitUart
    ldi     r1,#23
    sc      r1,LEDS
	bsr     RTCCReadbuf          ; read the real-time clock
    ldi     r1,#24
    sc      r1,LEDS
	bsr     set_time_serial_     ; set the system time serial

	; Startup BIOS call task so that CPU#1 may make BIOS calls
	ldi     r1,#%000_111         ; task priority
	ldi     r2,#0                ; cpu affinity
	ldi     r3,#BIOSCallTask|1   ; start address (start in kernel mode)
	ldi     r4,#0                ; start parameter
	ldi     r5,#0                ; owning job
;	sys     #FMTK_CALL
;	dh      1                    ; start task function
    ldi     r1,#25
    sc      r1,LEDS
    bsr     DumpTaskList_
    ldi     r1,#26
    sc      r1,LEDS
    bsr     sd_controller_init_
	bra		Monitor

;==============================================================================
;==============================================================================

SerialStartMsg:
    push    lr
	ldi     r1,#msgStart
	bsr     SerialString
	ldi     r1,#CR
	bsr     SerialPutChar
	ldi     r1,#LF
	bsr     SerialPutChar
    rts

SerialString:
    push    lr
    mov     r2,r1
.again:
    lc      r1,[r2]
    beq     r1,.done
    bsr     SerialPutChar
    addui   r2,r2,#2
    bra     .again
.done:
    rts
    
SetupIntVectors:
	mtspr   vbr,r0               ; place vector table at $0000
	nop
	nop
	mfspr   r2,vbr
    ; Fill the interrupt vector table with calls to the uninitialized 
    ; interrupt routine.
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
	ldi		r1,#KeybdIRQ_
	sw		r1,463*8[r2]
	ldi     r1,#BoundsIRQ
	sw      r1,487*8[r2]
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
	; now we RTI rather than RTL In case the code was restarted from an IRQ
    ; routine in which case an internal hardware flag disabling interrupte
    ; remains set. An RTI will clear this flag.
    rtl
;	mtspr   isp,sp
;	ori     lr,lr,#1      ; stay in kernel mode
;	mtspr   ipc,lr
;	and     lr,lr,#-4
;	rti
 
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
	ldi     r1,#BoundsIRQ
	sw      r1,487*8[r2]
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
	; now we RTI to clear a hardware flag that disables interrupts. In case the
	; processor was reset from an IRQ routine.
	rtl
;	mtspr   isp,sp
;	ori     lr,lr,#1      ; stay in kernel mode
;	mtspr   ipc,lr
;	and     lr,lr,#-4
;	rti
 
;------------------------------------------------------------------------------
; Initialize the interrupt controller.
;------------------------------------------------------------------------------
; These routines now written in 'C'.
;InitPIC:
;	ldi		r1,#$000C		; timer interrupt(s) are edge sensitive
;	sh		r1,PIC_ES
;	ldi		r1,#$000F		; enable keyboard reset, timer interrupts
;	sh		r1,PIC_IE
;	rtl
;
; For CPU #1 the only interrupt to be serviced is the 30Hz time slice.
;
;InitPIC1:
;	ldi		r1,#$000C		; timer interrupt(s) are edge sensitive
;	sh		r1,PIC_ES
;	ldi		r1,#$000B		; enable keyboard reset, timer interrupts
;	sh		r1,PIC_IE
;	rtl
;
include "serial.s"
include "Video.s"


DispStartMsg:
    push    lr
	ldi		r1,#msgStart
	bsr		DisplayString_
    rts

   
BranchToSelf2:
    bra      BranchToSelf2

;------------------------------------------------------------------------------
; Checksum the ROM. The ROM also has a 64 bit parity check connected to the
; processor's NMI input.
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
    cmp      r3,r4,#$20000
    blt      r3,.0001
    pea      msgROMChecksum
    bsr      DisplayString_
    addui    sp,sp,#8
    mov      r1,r5
    bsr      DisplayHalf
    bsr      CRLF_
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

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

LockBIOS:
    push    lr
    push    r1
    push    r2
    push    r3
    push    #-1       ; try forever
    pea     BIOS_sema
    bsr     LockSemaphore_    ; call library routine
    pop     r3
    pop     r2
    pop     r1
    rts
UnlockBIOS:
    push    lr
    push    r1
    push    r2
    push    r3
    pea     BIOS_sema
    bsr     UnlockSemaphore_
    pop     r3
    pop     r2
    pop     r1
    rts

LockBIOS1:
    push    lr
    push    r1
    push    r2
    ldi     r2,#-1
    lea     r1,BIOS1_sema_
    bsr     _LockSema
    pop     r2
    pop     r1
    rts
UnlockBIOS1:
    push    lr
    push    r1
    lea     r1,BIOS1_sema_
    bsr     _UnlockSema
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
    lea     r10,API_AREA
    sw      r6,BIOS_op[r10]
    sw      r1,BIOS_arg1[r10]
    sw      r2,BIOS_arg2[r10]
    sw      r3,BIOS_arg3[r10]
    sw      r4,BIOS_arg4[r10]
    sw      r5,BIOS_arg5[r10]
    sw      r0,BIOS_resp[r10]
    sw      r0,BIOS_stat[r10]
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
    bsr     UnlockBIOS1
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
    lw      sp,TCB_BIOS_Stack[tr]
    push    lr
    push    r10
    bsr     LockBIOS
    mfspr   r10,epc             ; update the return address
    addui   r10,r10,#4
    mtspr   epc,r10
    cmp     r10,r6,#MAX_BIOS_CALL
    bgt     r10,.0003
    ldi     r10,#BIOS_FuncTable
    lcu     r10,[r10+r6*2]
    or      r10,r10,#BIOSCall & 0xFFFFFFFFFFFF0000
    jsr     [r10]
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
.0002:
    ldi     r1,#BIOS_MbxHandle
    sys     #FMTK_CALL            ; call FMTK AllocMbx function
    dh      6
.0001:
    lw      r1,BIOS_MbxHandle
    ldi     r2,#-1                ; infinite timeout
    sys     #FMTK_CALL
    dh      10                    ; call FMTK Waitmsg Function
    cmp     r11,r1,#E_BadMbx
    beq     r11,.0002
    cmp     r11,r1,#E_Ok          ; ignore bad reponses
    bne     r11,.0001
    mov     r11,r2
    mov     r12,r3
    lea     r11,API_AREA          ; for now
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
    ldi     sp,#irq_stack_       ; set stack pointer to interrupt processing stack
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
	lw      r1,$30000
	sh      r1,TEXTSCR+224
	pop     r1
    rtl

;------------------------------------------------------------------------------
; 1024Hz interupt routine. This must be fast. Allows the system time to be
; gotten by right shifting by 10 bits.
;------------------------------------------------------------------------------

Tick1024Rout:
    ldi     sp,#irq_stack_  ; set stack pointer to interrupt processing stack
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
msgBytes:
    dc  "\r\n%d bytes allocated to system.\r\n",0

; ============================================================================
; Monitor Task
; ============================================================================
    align   4
Monitor:
	pea		msgMonitorStarted
	bsr		DisplayStringCRLF_
	addui   sp,sp,#8
	sb		r0,KeybdEcho
	ldi     r1,#jcbs_
;	sb      r0,JCB_KeybdEcho[r1]
    lea     r28,MonAbort            ; point catch handler back to monitor
    lw      r1,syspages_
    asli    r1,r1,#16
    push    r1
    pea     msgBytes
    bsr     printf_
    addui   sp,sp,#16
mon1:
;	ldi		sp,#TCBs+TCB_Size-8		; reload the stack pointer, it may have been trashed
	ldi		sp,#MON_STACK
    lea     r28,MonAbort
	cli
.PromptLn:
	bsr		CRLF_
	ldi		r1,#'$'
	bsr		OutChar
.Prompt3:
	bsr		KeybdGetBufferedCharNoWait_		; KeybdGetCharDirectNB
	blt	    r1,.Prompt3
	cmp		r2,r1,#CR
	beq		r2,.Prompt1
	bsr		OutChar
	bra		.Prompt3
.Prompt1:
	push    r0
	bsr     SetCursorCol_
	addui   sp,sp,#8
	bsr		CalcScreenLocation_
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
	cmp		r2,r1,#'F'
	beq		r2,doFillmem
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
	bsr		DisplayString_
	addui   sp,sp,#8
	bra     mon1

MonGetch:
    push    lr
	lhu	    r1,[r3]
	andi	r1,r1,#$1FF
	add		r3,r3,#4
	push    r3
	push    r1
	bsr		ScreenToAscii_
	addui   sp,sp,#8
	pop     r3
	pop     lr
	rtl
	
MonAbort:
    pea     msgCtrlC
    bsr     DisplayString_
    addui   sp,sp,#8
    bra     mon1

msgCtrlC:
    dc      "CTRL-C  pressed",CR,LF,0
    align   4
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

doDumpTL:
    push    r3
    bsr     DumpTaskList_
    pop     r3
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
	bsr		CRLF_
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
	bsr		CRLF_
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
    bsr     disassem20_
    addui   sp,sp,#16
    bra     mon1

doDebug:
   bsr   ignBlanks
   bsr   GetHexNumber
   push  #0
   push  r1
   bsr   debugger_
   addui sp,sp,#16
   bra   mon1

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
	bsr		DisplayString_
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
	bsr		ClearScreen_
	bsr		HomeCursor_
	bra     mon1

;------------------------------------------------------------------------------
; Get a random number from peripheral device.
;------------------------------------------------------------------------------

GetRandomNumber:
    lw      r1,$FFDC0C00
    rtl

include "i2c.s"
include "keyboard.s"                
include "keyboardc.s"

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
	bsr		CRLF_
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
	bsr		CRLF_
	bra		.0004
.0003:
	and		r1,r5,#$FFFFFF	; voltage mask
	bsr		DisplayHalf
	bsr		CRLF_
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
	bsr		CRLF_
.respOk:
	ldi		r1,#'O'
	bsr		OutChar
	ldi		r1,#'k'
	bsr		OutChar
	bsr		CRLF_
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
	bsr		CRLF_
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
    ldi     r2,#$34000          ; target store address
.0001:
    bsr     SerialGetCharDirect
    sb      r1,[r2]
    addui   r2,r2,#1
    subui   r3,r3,#1
    bne     r3,.0001
    rts

nmi_rout:
    ldi    sp,#irq_stack_
    push   r1
    pea    msgParErr
    bsr    DisplayStringCRLF_
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
	bsr		DisplayStringCRLF_
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
	bsr		DisplayStringCRLF_
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
	bsr		DisplayStringCRLF_
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
	bsr		DisplayString_
	addui   sp,sp,#8
	mfspr   r1,epc
	bsr     DisplayHalf
	bsr     CRLF_
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
msgBounds:
    dc  "Array bounds violation: ",0

    align 4
UninitIRQ:
    pea   msgUninitIRQ
    bsr   DisplayString_
    addui sp,sp,#8
    mfspr r1,12          ; vecno
    bsr   DisplayCharHex
	bsr     CRLF_
	bsr		KeybdGetCharWait
	bra   start
.0001:
    bra   .0001

    align 4
BoundsIRQ:
    pea   msgBounds
    bsr   DisplayString_
    addui sp,sp,#8
    mfspr r1,epc
    bsr   DisplayCharHex
	bsr     CRLF_
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
	bsr     DisplayString_
	addui   sp,sp,#8
	mfspr   r1,ipc
	bsr		DisplayWord
	pea     msgEA
	bsr     DisplayString_
	addui   sp,sp,#8
    mfspr   r1,bear
	bsr     DisplayWord
	bsr     CRLF_
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
    bsr      disassem20_
	bsr		 KeybdGetCharWait
    rtd
.0001:
    bra     .0001

include "set_time_serial.s"
include "sprite_demo.s"
;include "FMTK_Equates.inc"
code
include "..\FMTK\source\kernel\PIC.s"
include "..\FMTK\source\kernel\FMTKc.s"
include "..\FMTK\source\kernel\FMTKmsg.s"
include "..\FMTK\source\kernel\TCB.s"
include "..\FMTK\source\kernel\console.s"
include "..\FMTK\source\kernel\keybd.s"
include "..\FMTK\source\kernel\LockSemaphore.s"
include "..\FMTK\source\kernel\UnlockSemaphore.s"
include "..\FMTK\source\kernel\Semaphore.s"
include "..\FMTK\source\kernel\IOFocusc.s"
include "..\FMTK\source\shell.s"
include "..\FMTK\source\memmgnt.s"
include "..\c64libc\source\stdio.s"
include "..\c64libc\source\string.s"
include "..\c64libc\source\ctype.s"
include "..\c64libc\source\prtdbl.s"
include "..\c64libc\source\FISA64\getCPU.s"
include "..\c64libc\source\FISA64\outb.s"
include "..\c64libc\source\FISA64\outc.s"
include "..\c64libc\source\FISA64\outh.s"
include "..\c64libc\source\FISA64\outw.s"
include "..\c64libc\source\FISA64\_LockSema.s"
include "..\c64libc\source\FISA64\_UnlockSema.s"
include "sd_controller.s"
include "disassem.s"
include "debugger.s"
include "ramtest.s"
include "highest_data_word.s"
message "hit end"
    nop
    nop

