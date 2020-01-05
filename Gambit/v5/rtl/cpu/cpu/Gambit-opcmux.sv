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

module opcmux(rst,nmi,irq,roi,freeze,ico,o);
input rst;
input nmi;
input [2:0] irq;
input roi;
input freeze;
input Instruction ico;
output Instruction o;

// Multiplex exceptional conditions into the instruction stream.
always @*
case(freeze)
1'b1:
	casez({rst,nmi,roi,|irq})
	4'b1???:	o = {39'h0,4'h0,`RST,`BRKGRP};
	4'b01??:	o = {39'h0,4'h0,`NMI,`BRKGRP};
	4'b001?:	o = {39'h0,4'h1,`NMI,`BRKGRP};
	4'b0001:	o = {39'h0,1'b0,irq,`IRQ,`BRKGRP};
	// The following shouldn't happen (pc frozen without interrupt present).
	// It's a hardware error. Just do reset.
	default:	o = {39'h0,4'h0,`RST,`BRKGRP};
	endcase
default:	o = ico;
endcase

endmodule
