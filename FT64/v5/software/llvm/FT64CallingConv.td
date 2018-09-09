//===-- FT64CallingConv.td - FT64 Calling Conventions ---*- tablegen -*-===//
// ============================================================================
//        __
//   \\__/ o\    (C) 2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
// This describes the calling conventions for the FT64 architecture.
//
// The FT64 calling convention is handled with custom code in
// FT64ISelLowering.cpp (CC_FT64).

def CSR : CalleeSavedRegs<(add (sequence "R%u", 11, 17), (sequence "R%u", 26, 31))>;

// Needed for implementation of FT64RegisterInfo::getNoPreservedMask()
def CSR_NoRegs : CalleeSavedRegs<(add)>;

// Interrupt handler needs to save/restore all registers that are used,
// both Caller and Callee saved registers.
def CSR_Interrupt : CalleeSavedRegs<(add (sequence "R%u", 1, 30))>;

// Same as CSR_Interrupt, but including all 32-bit FP registers.
def CSR_XLEN_F64_Interrupt: CalleeSavedRegs<(add
    (sequence "R%u", 1, 30),
    (sequence "FP%u_64", 0, 31)
)>;

