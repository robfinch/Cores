// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	sigmoid.v
//		- perform sigmoid function
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
// This module returns the sigmoid of a number using a lookup table.
// -1.0 or +1.0 is returned for entries outside of the range -8.0 to +8.0
//                                                                          
// ToTo: check pipelining of values
// ============================================================================

`include "fpConfig.sv"

`define ONE80					80'h3FFF0000000000000000
`define EIGHT80				80'h40020000000000000000
`define FIVETWELVE80	80'h40080000000000000000
`define ONE64					64'h3FF0000000000000
`define EIGHT64				64'h4020000000000000
`define FIVETWELVE64	64'h4080000000000000
`define ONE40					40'h3FE0000000
`define EIGHT40				40'h4040000000
`define ONE32					32'h7F000000
`define EIGHT32				32'h42000000
`define FIVETWELVE32	32'h48000000

module fpSigmoid(clk, ce, a, o);
parameter FPWID = 128;
`include "fpSize.sv"
input clk;
input ce;
input [MSB:0] a;
output reg [MSB:0] o;

wire [4:0] cmp1_o;
reg [4:0] cmp2_o;

// Just the mantissa is stored in the table to economize on the storate.
// The exponent is always the same value (0x3ff). Only the top 32 bits of
// the mantissa are stored.
(* ram_style="block" *)
reg [31:0] SigmoidLUT [0:1023];

// Check if the input is in the range (-8 to +8)
// We take the absolute value by trimming off the sign bit.
generate begin : ext
if (FPWID+`EXTRA_BITS==80)
fp_cmp_unit #(FPWID) u1 (.a(a & 80'h7FFFFFFFFFFFFFFFFFFF), .b(`EIGHT80), .o(cmp1_o), .nanx() );
else if (FPWID+`EXTRA_BITS==64)
fp_cmp_unit #(FPWID) u1 (.a(a & 64'h7FFFFFFFFFFFFFFF), .b(`EIGHT64), .o(cmp1_o), .nanx() );
else if (FPWID+`EXTRA_BITS==40)
fp_cmp_unit #(FPWID) u1 (.a(a & 40'h7FFFFFFFFF), .b(`EIGHT40), .o(cmp1_o), .nanx() );
else if (FPWID+`EXTRA_BITS==32)
fp_cmp_unit #(FPWID) u1 (.a(a & 32'h7FFFFFFF), .b(`EIGHT32), .o(cmp1_o), .nanx() );
else begin
	always @*
	begin
		$display("Sigmoid: unsupported FPWIDth.");
		$stop;
	end
end
end
endgenerate

initial begin
`include "D:\Cores6\nvio\v1\rtl\fpUnit\SigTbl.ver"
end

// Quickly multiply number by 64 (it is in range -8 to 8) then convert to integer to get
// table index = add 6 to exponent then convert to integer
wire sa;
wire [EMSB:0] xa;
wire [FMSB:0] ma;
fpDecomp #(FPWID) u1 (.i(a), .sgn(sa), .exp(xa), .man(ma), .fract(), .xz(), .vz(), .xinf(), .inf(), .nan() );

reg [9:0] lutadr;
wire [5:0] lzcnt;
wire [MSB:0] a1;
wire [MSB:0] i1, i2;
wire [EMSB:0] xa1 = xa + 4'd6;
assign a1 = {sa,xa1,ma};	// we know the exponent won't overflow
wire [31:0] man32a = SigmoidLUT[lutadr];
wire [31:0] man32b = lutadr==10'h3ff ? man32a : SigmoidLUT[lutadr+1];
wire [31:0] man32;
wire [79:0] sig80;
generate begin : la
if (FPWID >= 40) begin
wire [15:0] eps = ma[FMSB-10:FMSB-10-15];
wire [47:0] p = (man32b - man32a) * eps;
assign man32 = man32a + (p >> 26);
cntlz32 u3 (man32,lzcnt);
end
else if (FPWID==32) begin
wire [12:0] eps = ma[FMSB-10:0];
wire [43:0] p = (man32b - man32a) * eps;
assign man32 = man32a + (p >> 26);
cntlz32 u3 (man32,lzcnt);
end
end
endgenerate

wire [31:0] man32s = man32 << (lzcnt + 2'd1);	// +1 to hide leading one

// Convert to integer
f2i #(FPWID) u2
(
  .clk(clk),
  .ce(1'b1),
  .i(a1),
  .o(i2)
);
assign i1 = i2 + 512;

always @(posedge clk)
  if (ce) cmp2_o <= cmp1_o;

// We know the integer is in range 0 to 1023
always @(posedge clk)
  if(ce) lutadr <= i1[9:0];
reg sa1,sa2;
always @(posedge clk)
if (ce) sa1 <= a[FPWID-1];
always @(posedge clk)
if (ce) sa2 <= sa1;

generate begin : ooo
if (FPWID==80) begin
wire [14:0] ex1 = 15'h3ffe - lzcnt;
always @(posedge clk)
if (ce) begin
	if (cmp2_o[1])  // abs(a) less than 8 ?
	  o <= {1'b0,ex1,man32s[31:0],32'd0}; 
	else
	  o <= sa1 ? 80'h0 : `ONE80; 
end
end
else if (FPWID==64) begin
wire [10:0] ex1 = 11'h3fe - lzcnt;
always @(posedge clk)
if (ce) begin
	if (cmp2_o[1])  // abs(a) less than 8 ?
	  o <= {1'b0,ex1,man32s[31:0],20'd0}; 
	else
	  o <= sa1 ? 64'h0 : `ONE64; 
end
end
else if (FPWID==40) begin
wire [9:0] ex1 = 10'h1fe - lzcnt;
always @(posedge clk)
if (ce) begin
	if (cmp2_o[1])  // abs(a) less than 8 ?
	  o <= {1'b0,ex1,man32s[31:3]}; 
	else
	  o <= sa1 ? 40'h0 : `ONE40; 
end
end
else if (FPWID==32) begin
wire [7:0] ex1 = 8'h7e - lzcnt;
always @(posedge clk)
if (ce) begin
	if (cmp2_o[1])  // abs(a) less than 8 ?
	  o <= {1'b0,ex1,man32s[31:9]};
	else
	  o <= sa1 ? 32'h0 : `ONE32;
end
end
end
endgenerate

endmodule
