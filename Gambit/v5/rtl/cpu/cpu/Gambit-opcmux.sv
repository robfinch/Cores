// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
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
//
// ============================================================================
//
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-types.sv"

module opcmux(rst,nmi,irq,freeze,ihit,branchmiss,ico,o);
input rst;
input nmi;
input [2:0] irq;
input freeze;
input ihit;
input branchmiss;
input tInstruction ico;
output tInstruction o;

// Multiplex exceptional conditions into the instruction stream.
always @*
case(freeze)
1'b1:
	casez({rst,nmi,|irq})
	3'b1??:	o = {52'h0,4'h0,`RST,`BRKGRP};
	3'b01?:	o = {52'h0,4'h0,`NMI,`BRKGRP};
	3'b001:	o = {52'h0,1'b0,irq,`IRQ,`BRKGRP};
	// The following shouldn't happen (pc frozen without interrupt present).
	// It's a hardware error. Just do reset.
	default:	o = `NOP_INSN;//{52'h0,4'h0,`RST,`BRKGRP};
	endcase
default:	
	o = ihit ? ico : `NOP_INSN;
endcase

endmodule
