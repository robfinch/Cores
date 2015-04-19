// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// SetBounds.c
// Set processor bounds registers for FMTK.
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
#include "config.h"
#include "const.h"
#include "types.h"
#include "proto.h"

pascal void SetBound48(TCB *ps, TCB *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   112,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   176,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   240,r1      ; modulo mask not used
     }
}

pascal void SetBound49(JCB *ps, JCB *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   113,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   177,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   241,r1      ; modulo mask not used
     }
}

pascal void SetBound50(MBX *ps, MBX *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   114,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   178,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   242,r1      ; modulo mask not used
     }
}

pascal void SetBound51(MSG *ps, MSG *pe, int algn)
{
     asm {
     lw      r1,24[bp]
     mtspr   115,r1      ; set lower bound
     lw      r1,32[bp]
     mtspr   179,r1      ; set upper bound
     lw      r1,40[bp]
     mtspr   243,r1      ; modulo mask not used
     }
}

