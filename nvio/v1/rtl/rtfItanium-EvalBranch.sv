// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// EvalBranch.v
// - branch evaluation
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
`define Bcc		4'h0
`define BLcc	4'h1
`define BRcc	4'h2
`define FBcc	4'h4
`define BBc		4'h5
`define BEQI	4'h6
`define BNEI	4'h7
`define CHKI	4'hC
`define CHK		4'hD

`define BEQ		3'h0
`define BNE		3'h1
`define BLT		3'h2
`define BGE		3'h3
`define BLTU	3'h6
`define BGEU	3'h7

`define BNAND	3'h0
`define BNOR	3'h1
`define BAND	3'h4
`define BOR		3'h5

`define FBEQ	3'd0
`define FBNE	3'd1
`define FBLT	3'd2
`define FBLE	3'd3
`define FBUN	3'h7

`define BEQR		4'h0
`define BNER		4'h1
`define BLTR		4'h2
`define BGER		4'h3
`define BNANDR	4'h4
`define BNORR		4'h5
`define BLTUR		4'h6
`define BGEUR		4'h7
`define FBEQR		4'd8
`define FBNER		4'd9
`define FBLTR		4'd10
`define FBLER		4'd11
`define BANDR		4'd12
`define BORR		4'd13
`define FBUNR		4'd15

//`define BXOR	3'd2
//`define BXNOR	3'd6

module EvalBranch(instr, a, b, c, takb);
parameter WID=80;
input [39:0] instr;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] c;
output reg takb;

wire [3:0] opcode = instr[9:6];

wire [4:0] fcmpo;
wire fnanx;
fp_cmp_unit #(80) ufcmp1 (a, b, fcmpo, fnanx);

//Evaluate branch condition
always @*
case(opcode)
`Bcc:
	case(instr[2:0])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	default:	takb <= `TRUE;
	endcase
`BLcc:
	case(instr[2:0])
	`BNAND:	takb <= !(a != 0 && b != 0);
	`BNOR:	takb <= !(a != 0 || b != 0);
	`BAND:	takb <= a != 0 && b != 0;
	`BOR:		takb <= a != 0 || b != 0;
	default:	takb <= `TRUE;
	endcase
`BRcc:
	case(instr[3:0])
	`BEQ:	takb <= a==b;
	`BNE:	takb <= a!=b;
	`BLT:	takb <= $signed(a) < $signed(b);
	`BGE:	takb <= $signed(a) >= $signed(b);
	`BLTU:	takb <= a < b;
	`BGEU:	takb <= a >= b;
	`FBEQR:	takb <= fcmpo[0];
	`FBNER:	takb <= !fcmpo[0];
	`FBLTR:	takb <= fcmpo[1];
	`FBLER:	takb <= fcmpo[2];
	`BNANDR:	takb <= !(a != 0 && b != 0);
	`BNORR:	takb <= !(a != 0 || b != 0);
	`BANDR:	takb <= a != 0 && b != 0;
	`BORR:	takb <= a != 0 || b != 0;
	`FBUNR:	takb <= fcmpo[4];
	default:	takb <= `TRUE;
	endcase
`FBcc:
	case(instr[2:0])
	`FBEQ:	takb <= fcmpo[0];
	`FBNE:	takb <= !fcmpo[0];
	`FBLT:	takb <= fcmpo[1];
	`FBLE:	takb <= fcmpo[2];
	`FBUN:	takb <= fcmpo[4];
// 	`BXOR:	takb <= (a != 0) ^ (b != 0);
//	`BXNOR:	takb <= !((a != 0) ^ (b != 0));
	default:	takb <= `TRUE;
	endcase
`BEQI:	takb <= a=={{71{instr[21]}},instr[21:16],instr[2:0]};
`BNEI:	takb <= a!={{71{instr[21]}},instr[21:16],instr[2:0]};
`BBc:
	case(instr[1:0])
	2'd0:	takb <=  a[{instr[22:18],instr[15]}];	// BBS
	2'd1:	takb <= ~a[{instr[22:18],instr[15]}];	// BBC
	default:	takb <= `TRUE;
	endcase
`CHKI:	takb <= a >= b && a < {{58{instr[39]}},instr[39:33],instr[30:22],instr[5:0]};
`CHK:	takb <= a >= b && a < c;
default:	takb <= `TRUE;
endcase

endmodule
