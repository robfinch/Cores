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
pascal void UnlockSemaphore(int *sema)
{
     asm {
        lw      r1,24[bp]
    .0001:
        sw      r0,[r1]
        lw      r2,[r1]
        beq     r2,.0002  ; the semaphore is unlock, by this task or another
        cmpu    r3,r2,tr
        beq     r3,.0001  ; ??? this task still has it locked - store failed
        ; Here the semaphore was locked, but not by this task anymore. Another task
        ; must have interceded amd locked the semaphore right after it was unlocked
        ; by this task. Make sure this is the case, and it's not just bad memory.
        ; Make sure the semaphore was locked by a valid task
        chk     r3,r2,b48
        beq     r3,.0001
        ; Here the semaphore probably was validly locked by a different task.
        ; Assume the unlock must have been successful.
    .0002:
    }
}
