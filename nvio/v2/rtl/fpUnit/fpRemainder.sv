`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
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

`include "fp_defines.v"

`define FLT1	4'h1
`define FLT2	4'h2
`define FLT3	4'h3
`define FADD  5'h04
`define FSUB  5'h05
`define FMUL  5'h08
`define FDIV  5'h09
`define FREM	5'h0A
`define FMA			5'h00
`define FMS			5'h01
`define FNMA		5'h02
`define FNMS		5'h03

`define FTOI  5'h02
`define ITOF  5'h03
`define TRUNC	5'h15

module fpRemainder(rst, clk, ce, ld_i, ld_o, op4_i, funct6b_i, op4_o, funct6b_o, op_done,
	srca, srcb, srcc, latch_res, rem_done, state);
input rst;
input clk;
input ce;
input ld_i;
output reg ld_o;
input [3:0] op4_i;
input [4:0] funct6b_i;
output reg [3:0] op4_o;
output reg [5:0] funct6b_o;
input op_done;
output reg [2:0] srca;
output reg [2:0] srcb;
output reg [2:0] srcc;
output reg latch_res;
output reg rem_done;
output reg [4:0] state;

parameter IDLE = 4'd0;
parameter REM1 = 4'd1;
parameter REM2 = 4'd2;
parameter REM3 = 4'd3;
parameter REM4 = 4'd4;
parameter REM5 = 4'd5;
parameter REM6 = 4'd6;
parameter REM7 = 4'd7;
parameter REM1a = 4'd8;
parameter REM2a = 4'd9;
parameter REM3a = 4'd10;
parameter REM4a = 4'd11;
parameter REM5a = 4'd12;
parameter REM6a = 4'd13;
parameter REM7a = 4'd14;
parameter REM1b = 4'd15;
parameter REM2b = 5'd16;
parameter REM3b = 5'd17;
parameter REM4b = 5'd18;
parameter REM5b = 5'd19;
parameter REM6b = 5'd20;
parameter REM7b = 5'd21;
reg [2:0] cnt;

always @(posedge clk)
if (rst) begin
	state <= IDLE;
	rem_done <= 1'b1;
	op4_o <= `FLT2;
	funct6b_o <= `FREM;
	ld_o <= 1'b1;
	srca <= `AIN;
	srcb <= `BIN;
	srcc <= `CIN;
	cnt <= 3'd0;
end
else begin
if (ce & ld_i) begin
	if (op4_i==`FLT2 && funct6b_i==`FREM) begin
		rem_done <= 1'b0;
		state <= REM1;
	end
end
if (ce) begin
latch_res <= 1'b0;
ld_o <= 1'b0;
if (!cnt[2])
	cnt <= cnt - 3'd1;
case(state)
IDLE:	;
REM1:
	begin
		op4_o <= `FLT2;
		funct6b_o <= `FDIV;
		srca <= `AIN;
		srcb <= `BIN;
		srcc <= `CIN;
		ld_o <= 1'b1;
		state <= REM1a;
	end
REM1a:
	state <= REM1b;
REM1b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM3;
	end
REM2:
	if (op_done) begin
		op4_o <= `FLT3;
		funct6b_o <= `FMA;
		srca <= `RES;
		srcb <= `POINT5;
		srcc <= `ZERO;
		ld_o <= 1'b1;
		state <= REM2a;
	end
REM2a:
	state <= REM2b;
REM2b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM3;
	end
REM3:
	if (op_done) begin
		op4_o <= `FLT1;
		funct6b_o <= `TRUNC;
		srca <= `RES;
		ld_o <= 1'b1;
		state <= REM4a;
	end
REM3a:
	state <= REM3b;
REM3b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM4;
	end
REM4:
	if (op_done) begin
		op4_o <= `FLT1;
		funct6b_o <= `ITOF;
		srca <= `RES;
		ld_o <= 1'b1;
		state <= REM4a;
	end
REM4a:
	state <= REM4b;
REM4b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM5;
	end
REM5:
	if (op_done) begin
		op4_o <= `FLT3;
		funct6b_o <= `FNMA;
		srca <= `RES;
		srcb <= `BIN;
		srcc <= `AIN;
		ld_o <= 1'b1;
		state <= REM6a;
	end
REM5a:
	state <= REM5b;
REM5b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM6;
	end
REM6:
	if (op_done) begin
		op4_o <= `FLT2;
		funct6b_o <= `FSUB;
		srca <= `AIN;
		srcb <= `RES;
		ld_o <= 1'b1;
		state <= REM6a;
	end
REM6a:
	state <= REM6b;
REM6b:
	if (op_done) begin
		latch_res <= 1'b1;
		state <= REM7;
	end
REM7:
	if (op_done) begin
		rem_done <= 1'b1;
		op4_o <= `FLT2;
		funct6b_o <= `FREM;
		srca <= `AIN;
		srcb <= `BIN;
		srcc <= `CIN;
		ld_o <= 1'b1;
		state <= IDLE;
	end
endcase
end
end

endmodule
