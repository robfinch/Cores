; ============================================================================
;        __
;   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@finitron.ca
;       ||
;
;	prng_driver_asm.asm
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
; This file is part of FT64v7SoC
;
;------------------------------------------------------------------------------

PRNG					equ		$FFFFFFFFFFDC0C00
PRNG_VALUE		equ		$00
PRNG_STREAM		equ		$04

		code	18
;------------------------------------------------------------------------------
; Seed random number generator.
;
; Parameters:
;		$a0 - stream to seed
;		$a1 - value to use as seed
; Modifies:
;		$t0
; Returns:
;		none
;------------------------------------------------------------------------------

_SeedRand:
		ldi		$t0,#PRNG
		sh		$a0,$0C04[$t0]		; select stream #
		memdb
		sh		$a1,$0C08[$t0]		; set initial m_z
		memdb
		ror		$a1,$a1,#32
		sh		$a1,$0C0C[$t0]		; set initial m_w
		rol		$a1,$a1,#32
		memdb
		ret		#0

;------------------------------------------------------------------------------
; Get a random number, and generate the next number.
;
; Parameters:
;		$a0 = random stream number.
; Returns:
;		$v0 = random 32 bit number.
;------------------------------------------------------------------------------

_PeekRand:
		sh		$a0,PRNG+PRNG_STREAM	; set the stream
		memdb
		lvhu	$v0,PRNG+PRNG_VALUE		; get a number
		memdb
		ret

_GetRand:
		sh		$a0,PRNG+PRNG_STREAM	; set the stream
		memdb
		lvhu	$v0,PRNG+PRNG_VALUE		; get a number
		memdb
		sh		$r0,PRNG+PRNG_VALUE		; generate next number
		memdb
		ret

