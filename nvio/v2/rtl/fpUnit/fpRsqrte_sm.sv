// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRsqrte.v
//		- reciprocal square root estimate
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
// An implementation of the approximation used in the Quake game.
//
// ============================================================================

`define POINT5			32'h3F000000
`define ONEPOINT5		32'h3FC00000
`define FRSQRTE_MAGIC		32'h5f3759df

module fpRsqrte(clk, ce, ld, a, o);
parameter FPWID = 80;
input clk;
input ce;
input ld;
input [FPWID-1:0] a;
output reg [FPWID-1:0] o;

wire [31:0] a1;
reg [31:0] x2, x2yy;
reg [31:0] y, yy;
wire [31:0] y1 = `FRSQRTE_MAGIC - a1[31:1];
reg [31:0] aa0, bb0, aa1, bb1;
wire [31:0] mo0, mo1, x2yy1p5;

reg [3:0] cnt;
reg [2:0] state;
parameter IDLE = 3'd0;
parameter MULP5 = 3'd1;
parameter MULX2YY = 3'd2;
parameter SUB = 3'd3;
parameter RES = 3'd4;

always @(posedge clk)
begin
	if (ld) begin
		state <= MULP5;
		cnt <= 4'd5;
		aa0 <= a1;
		bb0 <= `POINT5;
		aa1 <= y1;
		bb1 <= y1;
		y <= y1;
	end
	case(state)
	IDLE:	;
	MULP5:	
		begin
			cnt <= cnt - 4'd1;
			if (cnt[3]) begin
				cnt <= 4'd5;
				x2 <= mo0;
				yy <= mo1;
				aa0 <= mo0;
				bb0 <= mo1;
				state <= MULX2YY;
			end
		end
	MULX2YY:
		begin
			cnt <= cnt - 4'd1;
			if (cnt[3]) begin
				cnt <= 4'd5;
				x2yy <= mo0;
				aa0 <= `ONEPOINT5;
				bb0 <= mo0;
				state <= SUB;
			end
		end
	SUB:
		begin
			cnt <= cnt - 4'd1;
			if (cnt[3]) begin
				cnt <= 4'd5;
				aa0 <= y;
				bb0 <= x2yy1p5;
				state <= RES;
			end
		end
	RES:
		begin
			cnt <= cnt - 4'd1;
			if (cnt[3]) begin
				state <= IDLE;
			end
		end
	endcase
end

F80ToF32 u0 (a, a1);
fpMulnr #(32) u1 (clk, ce, aa0, bb0, mo0);
fpMulnr #(32) u2 (clk, ce, aa1, bb1, mo1);
fpAddsubnr #(32) u3 (clk, ce, 3'd0, 1'b1, aa0, bb0, x2yy1p5);
F32ToF80 u4 (mo0, o);

//fpMulnr #(32) u1 (clk, ce, a, `POINT5, x2);
//assign y = `FRSQRTE_MAGIC - a[31:1];
//fpMulnr #(32) u2 (clk, ce, y, y, yy);
//fpMulnr #(32) u3 (clk, ce, x2, yy, x2yy);
//fpAddsubnr #(32) u4 (clk, ce, 3'd0, 1'b1, `ONEPOINT5, x2yy, x2yy1p5);
//fpMulnr #(32) u5 (clk, ce, y, x2yy1p5, o);

endmodule
