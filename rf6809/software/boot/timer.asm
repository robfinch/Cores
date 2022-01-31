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
	sta		VIA+VIA_ACR			
	lda		#$880						; enable timer #3 interrupts
	sta		VIA+VIA_IER
	rts

TimerIRQ:
	; Reset the edge sense circuit in the PIC
	lda		#31							; Timer is IRQ #31
	sta		PIC+16					; register 16 is edge sense reset reg	
	lda		PIC+$FF					; Timer active interrupt flag
	beq		notTimerIRQ
	clr		PIC+$FF					; clear the flag
	lda		#31							; Timer is IRQ #31
	sta		IrqSource		; stuff a byte indicating the IRQ source for PEEK()
	clr		VIA+VIA_T3LL		; should clear the interrupt
	clr		VIA+VIA_T3LH
	lda		#31							; Timer is IRQ #31
	sta		PIC+16					; register 16 is edge sense reset reg	
	clr		PIC+$FF					; clear the flag
	inc		$E0003F					; update timer IRQ screen flag
	ldd		milliseconds+2
	addd	#10
	std		milliseconds+2
	ldd		milliseconds
	adcb	#0
	stb		milliseconds+1
	adca	#0
	sta		milliseconds

	; Update XModem timer, we just always do it rather than testing if XModem
	; is active. The increment is set to give approximately 3s before the MSB
	; gets set.
	ldb		xm_timer
	addb	#4
	stb		xm_timer
notTimerIRQ:
	rts
	