`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FT816.v
//  - 16 bit CPU
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
`define FADD	6'd01
`define FSUB	6'd02
`define FMUL	6'd03
`define FDIV	6'd04
`define FABS	6'd8
`define FNABS	6'd9
`define FNEG	6'd10
`define FMOV	6'd11
`define FSIGN	6'd12
`define FMAN	6'd13
`define I2F		6'd16
`define F2I		6'd17
`define FSTAT	6'd56
`define FRM		6'd59
`define FTX		6'd60
`define FCX		6'd61
`define FEX		6'd62
`define FDX		6'd63

module FPUnit_tb();
reg clk;
reg rst;
reg [5:0] op;
reg [31:0] a,b;
wire [31:0] o,loo_o,zl_o;
reg ld;
reg [15:0] cnt;

initial begin
	rst <= 0;
	clk <= 0;
	#10 rst <= 1;
	#50 rst <= 0;
end

always #10 clk <= ~clk;

always @(posedge clk)
if (rst)
	cnt <= 0;
else begin
cnt <= cnt + 1;
case(cnt)
16'd0:	ldop(`I2F,32'd100,32'h8);
16'd1:	ld <= 1'b0;
16'd16:	ldop(`FMUL,32'h42C80000,32'h41000000);	// 100.0 * 8.0
16'd17:	ld <= 1'b0;
16'd64:	ldop(`FDIV,32'h42C80000,32'h41200000);	// 100.0 / 10.0
16'd65:	ld <= 1'b0;
16'd120:	ldop(`FDIV,32'h4F000000,32'h41880000);	// 2147483648 / 17.0
16'd121:	ld <= 1'b0;
16'd200:	ldop(`FADD,32'h42C80000,32'h41200000);	// 100.0 + 10.0
16'd210:	ldop(`FSUB,32'h42C80000,32'h41200000);	// 100.0 - 10.0
16'd220:	ldop(`FSUB,32'h41200000,32'h42C80000);	// 10 - 100.0
16'd230:	ldop(`F2I,32'hC2B40000,32'h8);
endcase
end

fpUnit #(32) u1
(
	.rst(rst),
	.clk(clk),
	.ce(1'b1),
	.op(op),
	.ld(ld),
	.a(a),
	.b(b),
	.o(o),
	.zl_o(zl_o),
	.loo_o(loo_o),
	.loo_done(loo_done),
	.exception(exception)
);

task ldop;
input [5:0] opz;
input [31:0] aa;
input [31:0] bb;
begin
	op <= opz;
	a <= aa;
	b <= bb;
	if (opz==`FDIV)
		ld <= 1'b1;
	else
		ld <= 1'b0;
end
endtask

endmodule
