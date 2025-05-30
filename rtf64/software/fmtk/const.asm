; ============================================================================
;        __
;   \\__/ o\    (C) 2020  Robert Finch, Stratford
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

; First 128 bytes are for integer register set
; Second 128 bytes are for float register set
; Leave some room for 64-bit regs
TCBsegs			EQU		$200		; segment register storage
TCBepc			EQU		$280
TCBStatus		EQU		$288
TCBPriority	EQU		$289
TCBWaitMbx	EQU		$28A
TCBStackBot	EQU		$290
TCBMsgD1		EQU		$298
TCBMsgD2		EQU		$2A0
TCBMsgD3		EQU		$2A8
TCBStartTick	EQU	$2B0
TCBEndTick	EQU		$2B8
TCBTicks		EQU		$2C0
TCBException	EQU	$2C8
TCBNext			EQU		$2D0
TCBPrev			EQU		$2D8
TCBTimeout	EQU		$2E0
IOF_NEXT		EQU		$2E8
IOF_PREV		EQU		$2F0
TCBName			EQU		$2F8

TS_NONE			EQU		0
TS_READY		EQU		1
TS_DEAD			EQU		2
TS_MSGRDY		EQU		4
TS_WAITMSG	EQU		8
TS_TIMEOUT	EQU		16
TS_PREEMPT	EQU		32
TS_RUNNING	EQU		128

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

