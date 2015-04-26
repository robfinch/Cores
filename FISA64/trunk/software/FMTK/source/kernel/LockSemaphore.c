// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// TCB.c
// Task Control Block related functions.
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
pascal int LockSemaphore(int *sema, int retries)
{
    asm {
        lw      r1,24[bp]
        lw      r2,32[bp]
        ; Interrupts should be already enabled or there would be no way for a locked
        ; semaphore to clear. Let's enable interrupts just in case.
        cli
    .0001:
        beq     r2,.0004  
        subui   r2,r2,#1  
        lwar    r3,[r1]
        beq     r3,.0003            ; branch if free
        cmpu    r2,r3,tr            ; test if already locked by this task
        beq     r2,.0002
        ;chk     r3,r0,#256          ; check if locked by a valid task
    .0003:
        swcr    tr,[r1]             ; try and lock it
        nop                         ; cr0 needs time to update???
        nop
        mfspr   r3,cr0
        bfextu  r3,r3,#36,#36       ; status is bit 36 of cr0
        beq     r3,.0001            ; lock failed, go try again
    .0002:
        ldi     r1,#1
        bra     .0005
    .0004:
        ldi     r1,#0
    .0005:
    }
}

// ILockSemaphore is meant to be called from an IRQ routine where interrupts
// are masked and must remain masked.

pascal int ILockSemaphore(int *sema, int retries)
{
    asm {
        lw      r1,24[bp]
        lw      r2,32[bp]
    .0001:
        beq     r2,.0004  
        subui   r2,r2,#1  
        lwar    r3,[r1]
        beq     r3,.0003            ; branch if free
        cmpu    r2,r3,tr            ; test if already locked by this task
        beq     r2,.0002
       ;chk     r3,r0,#256          ; check if locked by a valid task
    .0003:
        swcr    tr,[r1]             ; try and lock it
        nop                         ; cr0 needs time to update???
        nop
        mfspr   r3,cr0
        bfextu  r3,r3,#36,#36       ; status is bit 36 of cr0
        beq     r3,.0001            ; lock failed, go try again
    .0002:
        ldi     r1,#1
        bra     .0005
    .0004:
        ldi     r1,#0
    .0005:
    }
}
