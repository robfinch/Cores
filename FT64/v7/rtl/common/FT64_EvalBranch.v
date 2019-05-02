// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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
`define TRUE    1'b1
`define BNEI	6'h12
`define BBc		6'h26
`define Bcc		6'h30
`define BEQI	6'h32
`define BCHK	6'h33
`define CHK		6'h34

`define BEQ		3'h0
`define BNE		3'h1
`define BLT		3'h2
`define BGE		3'h3
`define BLTU	3'h6
`define BGEU	3'h7
`define BAND	3'h0
`define BOR		3'h1
`define BXOR	3'd2
`define BNAND	3'h4
`define BNOR	3'h5
`define BXNOR	3'd6

`define IBNE	2'd2
`define DBNZ	2'd3

module FT64_EvalBranch(instr, a, b, c, takb);
parameter WID=64;
input [47:0] instr;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] c;
output reg takb;

wire [5:0] opcode = instr[5:0];

//Evaluate branch condition
always @*
case(opcode)
`Bcc:
	case(instr[15:13])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`BLcc:
	case(instr[15:13])
	`BAND:	takb <= a != 0 && b != 0;
	`BOR:		takb <= a != 0 || b != 0;
 	`BXOR:	takb <= (a != 0) ^ (b != 0);
	`BNAND:	takb <= !(a != 0 && b != 0);
	`BNOR:	takb <= !(a != 0 || b != 0);
	`BXNOR:	takb <= !((a != 0) ^ (b != 0));
	default:	takb <= `TRUE;
	endcase
`BEQI:	takb <= a=={{56{instr[22]}},instr[22:18],instr[15:13]};
`BNEI:	takb <= a!={{56{instr[22]}},instr[22:18],instr[15:13]};
`BBc:
	case(instr[14:13])
	2'd0:	takb <=  a[{instr[22:18],instr[15]}];	// BBS
	2'd1:	takb <= ~a[{instr[22:18],instr[15]}];	// BBC
	`IBNE:	takb <=  (a + 64'd1) !=b;
	`DBNZ:	takb <=  (a - 64'd1) !=b;
	default:	takb <= `TRUE;
	endcase
`CHK,`BCHK:	takb <= a >= b && a < c;
default:	takb <= `TRUE;
endcase

endmodule
