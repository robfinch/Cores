;============================================================================
;        __
;   \\__/ o\    (C) 2016  Robert Finch, Stratford
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
; bootromV.asm
; - This is a first test program to see if the system works.
; - Each node will send a request to display the node number on
;   successive lines of the screen.
;============================================================================
;
TXTROWS		EQU		1
TXTCOLS		EQU		4
TEXTSCR		EQU		$FFD00000
NOCC_PKTLO     EQU       $FFD80000
NOCC_PKTMID    EQU       $FFD80004
NOCC_PKTHI     EQU       $FFD80008
NOCC_TXPULSE   EQU       $FFD80018
NOCC_STAT      EQU       $FFD8001C
CPU_INFO       EQU       $FFD90000

NormAttr 	EQU		8

	org		0x2000
	jmp		start
start:
  lw    r4,CPU_INFO      ; figure out which core we are
  andi  r4,r4,#15
  slti  r4,r4,#2
  beq   r4,r0,.0002      ; not core #1 (wasn't less than 2)
  lw    r4,NOCC_STAT     ; get which node we are
  srli  r4,r4,#16        ; extract bit field
  andi  r4,r4,#15
  or    r3,r4,r0         ; move to r3
  ldi   r1,#$1000001F    ; select write cycle to main system
  ldi   r2,#$FFDC0600    ; LEDs
  jal   r31,xmitPacket
  
  ldi   r5,#336          ; number of bytes per screen line
  mul   r4,r4,r5         ; r4 = node number * bytes per screen line
  addi  r2,r4,#$FFD00000 ; add in screen base address r2 = address
  ldi   r1,#$1000001F    ; target system interface for word write cycle
  ori   r3,r3,#%000111000_110110110_000011_0000    ; grey on green text
  jal   r31,xmitPacket
.0001:                   ; hang the cpu
  beq   r0,r0,.0001
  ; Here do processing for the second CPU
.0002:
  beq   r0,r0,.0002

xmitPacket:
  ; first wait until the transmitter isn't busy
.0001:
  lw    r24,NOCC_STAT
  andi  r24,r24,#$100      ; bit 8 is xmit status
  bne   r24,r0,.0001
  ; Now transmit packet
  sw    r1,NOCC_PKTHI    ; set high order packet word
  sw    r2,NOCC_PKTMID   ; set middle packet word
  sw    r3,NOCC_PKTLO    ; and set low order packet word
  sw    r0,NOCC_TXPULSE  ; and send the packet
  jal   [r31]


