// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT64_EvalBranch.v
// - FT64 branch evaluation
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
`define BccR	6'h03
`define BBc0	6'h26
`define BBc1	6'h27
`define Bcc0	6'h30
`define Bcc1	6'h31
`define BEQ0	6'h32
`define BEQ1	6'h33
`define CHK		6'h34

`define BEQ		3'h0
`define BNE		3'h1
`define BLT		3'h2
`define BGE		3'h3
`define BLTU	3'h4
`define BGEU	3'h5

`define IBNE	2'd2
`define DBNZ	2'd3

module FT64_EvalBranch(instr, a, b, c, takb);
parameter WID=64;
input [31:0] instr;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] c;
output reg takb;

wire [5:0] opcode = instr[5:0];
wire [4:0] fcmpo;
wire fnanx;
fp_cmp_unit #(WID) ufcmp1 (a, b, fcmpo, fnanx);

//Evaluate branch condition
always @*
case(opcode)
`BccR:
	case(instr[23:21])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`Bcc0,`Bcc1:
	case(instr[18:16])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`BEQ0,`BEQ1:	takb <= a=={{55{instr[19]}},instr[19:11]};
`BBc0,`BBc1:
	case(instr[18:17])
	2'd0:	takb <=  a[instr[16:11]];	// BBS
	2'd1:	takb <= ~a[instr[16:11]];	// BBC
	`IBNE:	takb <=  a!=b;
	`DBNZ:	takb <=  a!=b;
	default:	takb <= `TRUE;
	endcase
`CHK:	takb <= a >= b && a < c;
default:	takb <= `TRUE;
endcase

endmodule
