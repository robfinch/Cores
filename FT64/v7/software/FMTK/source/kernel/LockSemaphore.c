// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2018  Robert Finch, Waterloo
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
		ldi		r1,#128
    .0001:
        ble     r19,r0,.0004
        sub		r19,r19,#1  
		csrrw	r4,#$10,r0			// get thread register
        lwr  	r3,[r18]
        beq     r3,r4,.0002			// test if already locked by this task
        bne     r3,r0,.0001         // branch if not free
        //chk     r3,r0,#256         ; check if locked by a valid task
    .0003:
		sc		r1,$FFDC0600
		xor		r1,r1,#$80
        swc     r4,[r18]            // try and lock it
        sync                        // cr0 needs time to update???
		csrrd   r3,#$00C,r0			// status is bit 0 of csr $00C
		bbc     r3,#0,.0001         // lock failed, go try again
    .0002:
        ldi     r1,#1
        bra     .0005
    .0004:
        ldi		r1,#0
    .0005:
    }
}
