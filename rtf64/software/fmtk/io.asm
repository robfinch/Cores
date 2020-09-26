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

;Standard Devices are:

;#		Device					Standard name

;0		NULL device 			NUL		(OS built-in)
;1		Keyboard (sequential)	KBD		(OS built-in)
;2		Video (sequential)		VID		(OS built-in)
;3		Printer (parallel 1)	LPT
;4		Printer (parallel 2)	LPT2
;5		RS-232 1				COM1	(OS built-in)
;6		RS-232 2				COM2
;7		RS-232 3				COM3
;8		RS-232 4				COM4
;9		Parallel xfer	  PTI
;10		Floppy					FD0
;11		Floppy					FD1
;12		Hard disk				HD0
;13		Hard disk				HD1
;14
;15   VIA							VIA1
;16		SDCard					CARD1 	(OS built-in)
;17
;18
;19
;20
;21
;22
;23
;24
;25
;26
;27
;28		Audio						PSG1	(OS built-in)
;29
;30   Random Number		PRNG
;31		Debug						DBG

; The following must be at least 128 byte aligned
DVF_Base		EQU		$A000
DVF_Limit		EQU		$B000

;------------------------------------------------------------------------------
; Parameters:
;		a1 = I/O channel
;		a2 = function
;		a3 = data
;------------------------------------------------------------------------------

FMTK_IO:
	ldi		$v0,#32
	bgeu	$a1,$v0,.badDev
	ldi		$v1,#32
	bgeu	$a2,$v1,.badFunc
	sll		$v0,$a1,#7					; each device allowed 32 functions (*128)
	sll		$v1,$a2,#2					; function number *4
	add		$v0,$v0,#DVF_Base		; base address of function table
	or		$v0,$v0,$v1
	lw		$v0,[$v0]
	beq		$v0,$x0,.badFunc
	call	[$v0]
.xit:
	mtu		$v0,$v0
	mtu		$v1,$v1
	eret
.badFunc:
	ldi		$v0,#E_BadDevOp
	bra		.xit
.badDev:
	ldi		$v0,#E_BadDevNum
	bra		.xit

;------------------------------------------------------------------------------
; Parameters:
;		a0 = I/O channel
;		a1 = points to function table
;------------------------------------------------------------------------------

CopyDevFuncTbl:
	sll		$v0,$a0,#7					; each device allowed 32 functions (*128)
	add		$v0,$v0,#DVF_Base		; base address of function table
	ldi		$t0,#32							; 32 functions to copy
.again:
	lw		$t2,[$a1]
	sw		$t2,[$v0]
	add		$a1,$a1,#4
	add		$v0,$v0,#4
	sub		$t0,$t0,#1
	bgt		$t0,$x0,.again
	ret
	