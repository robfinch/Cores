;=================================================================
; Copyright (C) 2005 Bird Computer
; All rights reserved.
;
; boot_rom16.asm
; 	SoC Boot ROM
;
;	You are free to use and modify this code for non-commercial
;	or evaluation purposes.
;	
;	If you do modify the code, please state the origin and
;	note that you have modified the code.
;
;	This source file may be used without restriction, but not
;	distributed, provided this copyright statement remains
;	present in the file. Any derivative work must also
;	contain the original copyright notice and the following
;	disclaimer.
;
;
;	NO WARRANTY.
;	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF
;	ANY KIND, WHETHER EXPRESS OR IMPLIED. The user must assume
;	the entire risk of using the Work.
;
;	IN NO EVENT SHALL BIRD COMPUTER OR ITS PRINCIPALS OR
;	OFFICERS BE LIABLE FOR ANY INCIDENTAL, CONSEQUENTIAL,
;	OR PUNITIVE DAMAGES WHATSOEVER RELATING TO THE USE OF
;	THIS WORK, OR YOUR RELATIONSHIP WITH BC.
;
;	IN ADDITION, IN NO EVENT DOES BIRD COMPUTER AUTHORIZE YOU
;	TO USE THE WORK IN APPLICATIONS OR SYSTEMS WHERE THE
;	WORK'S FAILURE TO PERFORM CAN REASONABLY BE EXPECTED
;	TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN LOSS
;	OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK,
;	AND YOU AGREE TO HOLD BC HARMLESS FROM ANY CLAIMS OR LOSSES
;	RELATING TO SUCH UNAUTHORIZED USE.
;
; 
;	Load program from the serial port.
;
;=================================================================

CR		equ	0x0D		; ASCII equates
LF		equ	0x0A
TAB		equ	0x09
CTRLC	equ	0x03
CTRLH	equ	0x08
CTRLS	equ	0x13
CTRLX	equ	0x18


;XMIT_FULL		equ	0x40		; the transmit buffer is full
;DATA_PRESENT	equ	0x08		; there is data preset at the serial port bc_uart3
DATA_PRESENT	equ	0x01		; there is data preset at the serial port bc_uart3
XMIT_NOT_FULL	equ	0x20

TS_TIMER	equ		0xFFFFDC40		; system time slice timer
KBD			equ		0xFFFFDC50
ATA			equ		0xFFFFDCC0
ATA_READBACK		equ		ATA+4
ATA_ALT_STATUS		equ		ATA+12
ATA_DATA_REG		equ		ATA+16
ATA_SECTOR_COUNT	equ		ATA+20
ATA_LBA_LOW			equ		ATA+24
ATA_LBA_HIGH		equ		ATA+26
ATA_HEAD			equ		ATA+28
ATA_CMD_STATUS		equ		ATA+30

UART		equ		0xFFFFDC70
UART_TRB	equ		0xFFFFDC70
UART_FF		equ		0xFFFFDC75
UART_MC		equ		0xFFFFDC76
UART_LS		equ		0xFFFFDC71
UART_CLKM0	equ		0xFFFFDC78
UART_CLKM1	equ		0xFFFFDC79
UART_CLKM2	equ		0xFFFFDC7A
UART_CLKM3	equ		0xFFFFDC7B

LED			equ		0xFFFFDC80
VIC			equ		0xFFFFD800
SID			equ		0xFFFFDF00
VIDEORAM	equ		0x00001000
STACK_TOP0	equ		0x00000BFC		; cpu0 stack
STACK_TOP1	equ		0x00000FFC		; cpu1 stack
SCR_COLS	equ		60
SCR_ROWS	equ		30

; First word is reserved as unused, since it may get overwritten
; occasionally by bad code.
tick_cnt	equ		0x00000004		; system tick count in 20ms incr.
irq_vec		equ		0x10		    ; irq vector
brk_vect	equ		0x14
trc_vect	equ		0x18
warmStart   equ     0x20
usrJmp      equ     0x24
dlAddress	equ		0x28			; address of where to download bytes
stAddress	equ		0x2C			; address of start of program

txtWidth	equ		0x30
txtHeight	equ		0x31
cursx		equ		0x32
cursy		equ		0x33
pos			equ		0x34	; current screen pos
charToPrint	equ		0x38
fgColor		equ		0x3A
bkColor		equ		0x3B
cursFlash	equ		0x3C	; flash the cursor ?

runCpu1		equ		0x50
runAddr		equ		0x54

		.code
		cpu		Butterfly16
		org		0xF000

		org		0xF900
reset:	
		lw		r1,#1
		lw		r2,#1
		lw		r4,#0
j0001:
		lw		r3,#0
		add		r3,r2
		add		r3,r1
		cmp		r3,#$8000
		bgtu	endFibbonaci
		sw		r1,[r4]
		add		r4,#2
		add		r1,r2,#0		; move r2 to r1
		add		r2,r3,#0		; move r3 to r2
		bra		j0001
endFibbonaci:
		sw		r1,[r4]
		sw		r2,2[r4]
		sw		r3,4[r4]
endFibbonaci2:
		bra		endFibonnaci2


		; exception vector table
		org		0xFFE0
		dw		brk_rout		; 0 BRK vector
		dw		0xFFFF		; 1 operating system
		dw		0xFFFF		; 2
		dw		0xFFFF		; 3
		dw		0xFFFF		; 4
		dw		0xFFFF		; 5
		dw		0xFFFF		; 6
		dw		0xFFFF		; 7
		dw		0xFFFF		; 8
		dw		0xFFFF		; 9
		dw		0xFFFF		; A
		dw		trc_rout		; B trace
		dw		0xFFFF		; C debug interrupt
		dw		irq_rout		; D irq vector
		dw		reset			; E nmi vector
		dw		reset			; F reset vector

;		dw		0x5254462E		; hi
;
