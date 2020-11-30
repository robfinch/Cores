// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// LockSemaphore.c
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
pascal int LockSemaphore(register int *sema, register int retries)
{
  __asm {
		ldi		$a1,#128
    .0001:
      sle   $a1,$x0          
      bt    .0004
      sub		$a1,$a1,#1  
		  csrrw	$t0,#$10,$x0			// get thread register
      ldor  $a3,[$a0]
      seq   $a3,$t0
      bt    .0002			        // test if already locked by this task
      bnez  $a3,.0001         // branch if not free
        //chk     r3,r0,#256         ; check if locked by a valid task
    .0003:
		  stw		$a1,$FFDC0600
		  xor		$a1,$a1,#$80
      swc   $t0,[$a0]            // try and lock it
      sync                        // cr0 needs time to update???
		  csrrw $a3,#$00C,$x0			// status is bit 0 of csr $00C
		  extu  $a3,$a3,#0,#0
		  beqz  $a3,.0001         // lock failed, go try again
    .0002:
      ldi   $a0,#1
      jmp   .0005
    .0004:
      ldi		$a0,#0
    .0005:
    }
}
