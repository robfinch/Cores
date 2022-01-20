; ============================================================================
;        __
;   \\__/ o\    (C) 2022  Robert Finch, Waterloo
;    \  __ /    All rights reserved.
;     \/_//     robfinch<remove>@opencores.org
;       ||
;  
;
; Timer routines for a WDC6522 compatible circuit.
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
TimerInit:
	ldd		#$61A80					; compare to 400000 (100 Hz assuming 40MHz clock)
	stb		VIA+VIA_T3CMPL
	sta		VIA+VIA_T3CMPH
	clr		VIA+VIA_T3LL
	clr		VIA+VIA_T3LH
	lda		VIA+VIA_ACR			; set continuous mode for timer
	ora		#$100
	sta		VIA+VIA_ACR			; enable timer #3 interrupts
	lda		#$810
	sta		VIA+VIA_IER
	rts

TimerIRQ:
	; Reset the edge sense circuit in the PIC
	lda		#31							; Timer is IRQ #31
	sta		IrqSource		; stuff a byte indicating the IRQ source for PEEK()
	sta		PIC+16					; register 16 is edge sense reset reg	
	lda		VIA+VIA_IFR
	bpl		notTimerIRQ
	bita	#$800
	beq		notTimerIRQ
	clr		VIA+VIA_T3LL
	clr		VIA+VIA_T3LH
	inc		$E00037					; update timer IRQ screen flag
notTimerIRQ:
	rts


	