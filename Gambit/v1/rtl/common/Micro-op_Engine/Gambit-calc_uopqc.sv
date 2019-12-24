// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Although four micro-ops are fetched from the table we might not want to
// queue all four. We only want to queue up to the end of the program 
// sequence for that instruction. This code calulates the number of micro-ops
// to queue.
// ============================================================================
//
`include "..\Gambit-config.sv"
`include "..\Gambit-types.sv"

module calc_uopqc(ptr, uop_prg, mip1, mip2, uopqc);
input MicroOpPtr ptr [0:3];
input MicroOp uop_prg [0:`LAST_UOP];
input MicroOpPtr mip1;
input MicroOpPtr mip2;
output reg [2:0] uopqc;

wire [3:0] qc_sel = {uop_prg[ptr[3]].fl[1],uop_prg[ptr[2]].fl[1],uop_prg[ptr[1]].fl[1],uop_prg[ptr[0]].fl[1]};
always @*
	case(qc_sel)
	4'b0000:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b0001:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b0010:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b0011:	if (|mip1) uopqc = 3'd2; else uopqc = 3'd0;
	4'b0100:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b0101:	if (|mip1) uopqc = 3'd3; else uopqc = 3'd0;
	4'b0110:	if (|mip1) uopqc = 3'd3; else uopqc = 3'd0;
	4'b0111:	if (|mip1) uopqc = 3'd2; else uopqc = 3'd0;
	4'b1000:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b1001:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b1010:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b1011:	if (|mip1) uopqc = 3'd2; else uopqc = 3'd0;
	4'b1100:	if (|mip1) uopqc = 3'd4; else uopqc = 3'd0;
	4'b1101:	if (|mip1) uopqc = 3'd3; else uopqc = 3'd0;
	4'b1110:	if (|mip1) uopqc = 3'd3; else uopqc = 3'd0;
	4'b1111:	if (|mip1) uopqc = 3'd2; else uopqc = 3'd0;
	endcase

endmodule
