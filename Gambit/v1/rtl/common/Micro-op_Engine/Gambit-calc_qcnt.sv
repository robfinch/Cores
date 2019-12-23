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
// Count number of instructions that the end of has been seen. 
// ============================================================================
//
`include "..\Gambit-config.sv"
`include "..\Gambit-types.sv"

module calc_qcnt(ptr, uop_prg, mip1, mip2, qcnt);
input MicroOpPtr ptr [0:3];
input MicroOp uop_prg [0:`LAST_UOP];
input MicroOpPtr mip1;
input MicroOpPtr mip2;
output reg [2:0] qcnt;

wire [3:0] qc_sel = {uop_prg[ptr[3]].fl[1],uop_prg[ptr[2]].fl[1],uop_prg[ptr[1]].fl[1],uop_prg[ptr[0]].fl[1]};
always @*
	case(qc_sel)
	4'b0000:	qcnt = 3'd0;
	4'b0001:	if (|mip1) qcnt = 3'd1; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0010:	if (|mip1) qcnt = 3'd1; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0011:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0100:	if (|mip1) qcnt = 3'd1; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0101:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0110:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b0111:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1000:	if (|mip1) qcnt = 3'd1; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1001:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1010:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1011:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1100:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1101:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1110:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	4'b1111:	if (|mip1) qcnt = 3'd2; else if (|mip2) qcnt = 3'd1; else qcnt = 3'd0;
	endcase

endmodule
