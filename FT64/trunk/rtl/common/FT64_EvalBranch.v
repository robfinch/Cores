// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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

`define BEQ		4'h0
`define BNE		4'h1
`define BLT		4'h2
`define BGE		4'h3
`define BLTU	4'h4
`define BGEU	4'h5
`define FBEQ	4'h8
`define FBNE	4'h9
`define FBLT	4'hA
`define FBGE	4'hB
`define FBUN    4'hC

module FT64_EvalBranch(instr, a, b, takb);
input [31:0] instr;
input [63:0] a;
input [63:0] b;
output reg takb;

wire [5:0] opcode = instr[5:0];
wire [4:0] fcmpo;
wire fnanx;
fp_cmp_unit #(64) ufcmp1 (a, b, fcmpo, fnanx);

//Evaluate branch condition
always @*
case(opcode)
`BccR:
	case(instr[24:21])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	`FBEQ:	takb <=  fcmpo[0];
	`FBNE:	takb <= ~fcmpo[0];
	`FBLT:  takb <=  fcmpo[1];
	`FBGE:  takb <= ~fcmpo[2];
	`FBUN:  takb <=  fcmpo[4];
	default:	takb <= `TRUE;
	endcase
`Bcc0,`Bcc1:
	case(instr[19:16])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	`FBEQ:	takb <=  fcmpo[0];
	`FBNE:	takb <= ~fcmpo[0];
	`FBLT:  takb <=  fcmpo[1];
	`FBGE:  takb <= ~fcmpo[2];
	`FBUN:  takb <=  fcmpo[4];
	default:	takb <= `TRUE;
	endcase
`BEQ0,`BEQ1:	takb <= a==b;
`BBc0,`BBc1:
	case(instr[19:17])
	3'd0:	takb <= a[instr[16:11]];	// BBS
	3'd1:	takb <= ~a[instr[16:11]];	// BBC
	default:	takb <= `TRUE;
	endcase
default:	takb <= `TRUE;
endcase

endmodule
