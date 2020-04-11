// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
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

`include "..\inc\Gambit-defines.sv"
`include "..\inc\Gambit-config.sv"
`include "..\inc\Gambit-types.sv"

module alu(big, rst, clk, ld, op, a, imm, b, o, csr_i, idle, done, exc);
parameter WID=52;
input big;
input rst;
input clk;
input ld;
input Instruction op;
input Data a;
input Data imm;
input Data b;
output Data o;
input Data csr_i;
output idle;
output done;
output reg [7:0] exc;

wire dbz;
wire div_idle, div_done;
assign idle = op.rr.opcode==`DIV_3R ? div_idle : 1'b1;
assign done = op.rr.opcode==`DIV_3R ? div_done : 1'b1;
Data os;
Data divq, remq;

function [51:0] shl;
input [51:0] a;
input [51:0] b;
shl = a << b[5:0];
endfunction

function [51:0] shr;
input [51:0] a;
input [51:0] b;
shr = a >> b[5:0];
endfunction

divider udvdr1
(
	.rst(rst),
	.clk(clk),
	.ld(ld),
	.abort(),
	.sgn(1'b1),
	.sgnus(1'b0),
	.a(a),
	.b(op.rr.zero ? imm : b),
	.qo(divq),
	.ro(remq),
	.dvByZr(dbz),
	.done(div_done),
	.idle(div_idle)
);

always @*
case(op.rr.opcode)
`DIV_3R:	if (big) o = op.raw[25:24]==2'b01 ? remq : divq; else o = {3{16'hDEAE}};
`MUL_3R:	o = op.rr.zero ? $signed(a) * $signed(imm) : $signed(a) * $signed(b);
`ADD_3R:	o = op.rr.zero ? a + imm : a + b;
`SUB_3R:	o = op.rr.zero ? a - imm : a - b;
`AND_3R:	o = op.rr.zero ? a & imm : a & b;
`OR_3R:		
	begin
		os = op.rr.zero ? a | imm : a | b;
		case(op.rr.padr)
		3'd1:	o = {39'd0,os[12:0]};	// movzx
		3'd2:	o = {26'd0,os[25:0]};
		3'd5:	o = {{39{os[12]}},os[12:0]};	// movsx
		3'd6:	o = {{26{os[25]}},os[25:0]};
		default:	o = os;
		endcase
	end
`ISOP:
	case(op.raw[51:47])
	5'd4:		o = a + {op[46:17],22'd0};
	5'd8:		o = a & {op[46:17],22'h3FFFFF};
	5'd9:		o = a | {op[46:17],22'd0};
	5'd10:	o = a ^ {op[46:17],22'd0};
	default:	o = 52'd0;
	endcase
`EOR_3R:	o = op.rr.zero ? a ^ imm : a ^ b;
`CMP_3R:	o = op.rr.zero ? ($signed(a) < $signed(imm) ? 2'b11 : a == imm ? 2'b00 : 2'b01)
								: ($signed(a) < $signed(b) ? 2'b11 : a == b ? 2'b00 : 2'b01);
`CMPU_3R:	o = op.rr.zero ? (a < imm ? 2'b11 : a == imm ? 2'b00 : 2'b01)
		: (a < b ? 2'b11 : a == b ? 2'b00 : 2'b01);
`MUL_RI22,`MUL_RI35:	o = $signed(a) * $signed(imm);
`ADD_RI22,`ADD_RI35:	o = a + imm;
`SUB_RI22,`SUB_RI35:	o = a + imm;
`CMP_RI22,`CMP_RI35: o = $signed(a) < $signed(imm) ? 2'b11 : a == imm ? 2'b00 : 2'b01;
`CMPU_RI22,`CMPU_RI35: o = a < imm ? 2'b11 : a == imm ? 2'b00 : 2'b01;
`AND_RI22,`AND_RI35:	o = a & imm;
`OR_RI22,`OR_RI35:	o = a | imm;
`EOR_RI22,`EOR_RI35:	o = a ^ imm;
`ASL_3R:	o = op.rr.zero ? shl(a,imm[5:0]) : shl(a,b);
`ASR_3R:	o = op.rr.zero ? (a[51] ? ~(52'hFFFFFFFFFFFFF >> imm[5:0]) | shr(a,imm[5:0]) : shr(a,imm[5:0]))
							: (a[51] ? ~(52'hFFFFFFFFFFFFF >> b[5:0]) | shr(a,b) : shr(a,b));
`LSR_3R:	o = op.rr.zero ? shr(a,imm[5:0]) : shr(a,b);
`ROL_3R:	o = op.rr.zero ? shl(a,imm[5:0]) | shr(a,52-imm[5:0]) : shl(a,b) | shr(a,52-b);
`ROR_3R:	o = op.rr.zero ? shr(a,imm[5:0]) | shl(a,52-imm[5:0]) : shr(a,b) | shl(a,52-b);
`PERM_3R:
	begin
		case(b[1:0])
		2'd0:	o[12:0] = a[12:0];
		2'd1:	o[12:0] = a[25:13];
		2'd2:	o[12:0] = a[38:26];
		2'd3:	o[12:0] = a[51:29];
		endcase
		case(b[3:2])
		2'd0:	o[25:13] = a[12:0];
		2'd1:	o[25:13] = a[25:13];
		2'd2:	o[25:13] = a[38:26];
		2'd3:	o[25:13] = a[51:29];
		endcase
		case(b[5:4])
		2'd0:	o[38:26] = a[12:0];
		2'd1:	o[38:26] = a[25:13];
		2'd2:	o[38:26] = a[38:26];
		2'd3:	o[38:26] = a[51:29];
		endcase
		case(b[7:6])
		2'd0:	o[51:39] = a[12:0];
		2'd1:	o[51:39] = a[25:13];
		2'd2:	o[51:39] = a[38:26];
		2'd3:	o[51:39] = a[51:29];
		endcase
	end
`CSR:			o = csr_i;
default:	o = {3{16'hDCAE}};
endcase

always @*
if (op.rr.opcode==`DIV_3R && dbz && big)
	exc <= `FLT_DBZ;
else
	exc <= `FLT_NONE;

endmodule
