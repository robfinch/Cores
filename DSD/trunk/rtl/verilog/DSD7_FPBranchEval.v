`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_FPBranchEval.v
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
//`ifndef BEQ
`define FBcc    6'h01

// Bcc ops
`define FBEQ    3'h0
`define FBNE    3'h1
`define FBUN    3'h2
`define FBOR    3'h3
`define FBLT    3'h4
`define FBGE    3'h5
`define FBLE    3'h6
`define FBGT    3'h7

//`endif

module DSD7_FPBranchEval(xir, a, b, takb);
parameter WID=128;
input [31:0] xir;
input [WID-1:0] a;
input [WID-1:0] b;
output reg takb;

wire [5:0] opcode = xir[5:0];
wire [2:0] cond = xir[20:18];
wire nanx;
wire [4:0] o;

fp_cmp_unit #(WID) u1 (a, b, o, nanx);

always @(opcode or cond or a or b)
case(opcode)
`FBcc:
    case(cond)
    `FBEQ:  takb <= o[0];
    `FBNE:  takb <= !o[0];
    `FBUN:  takb <= o[4];
    `FBOR:  takb <= !o[4];
    `FBLT:  takb <= o[1];
    `FBGE:  takb <= !o[1];
    `FBLE:  takb <= o[2];
    `FBGT:  takb <= !o[2];
    endcase
endcase

endmodule
