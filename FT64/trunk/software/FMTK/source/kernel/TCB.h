#ifndef _TCB_H
#define _TCB_H

// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// TCB.h
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
// TCB inline functions

naked inline TCB *GetRunningTCBPtr() __attribute__(__no_temps)
{
    asm {
		csrrw	r1,#$10,r0
    }
}

naked inline hTCB GetRunningTCB() __attribute__(__no_temps)
{
    asm {
		csrrw	r1,#$10,r0
        sub 	r1,r1,#_tcbs
        shru 	r1,r1,#9
    }
}

naked inline void SetRunningTCB(register hTCB ht) __attribute__(__no_temps)
{
     asm {
         shl     r1,r18,#9
         add     r1,r1,#_tcbs
		 csrrw	 r0,#$10,r1
     }
}

#endif

