// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
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
//
// ============================================================================

`define ONE     32'h3f800000
`define EIGHT   32'h41000000 
`define FIVETWELVE  32'h44000000

module sigmoid(clk, a, o);
parameter WID=32;
input clk;
input [WID-1:0] a;
output reg [WID-1:0] o;

wire [4:0] cmp1_o;
reg [4:0] cmp2_o;
wire [31:0] a1,i1;
reg [31:0] SigmoidLUT [0:4095];

// Check if the input is in the range (-8 to +8)
fp_cmp_unit #(WID) u1 (.a(a & 32'h7FFFFFFF), .b(`EIGHT), .o(cmp1_o), .nanx() );


initial begin
`include "C:\Cores4\nna\trunk\SigmoidTbl.ver"
end

// Multiply number by 512 (it is in range 0 to 8) then convert to integer to get
// table index = add 9 to exponent then convert to integer
assign a1[22:0] = a[22:0];
assign a1[30:23] = a[30:23] + 8'd9; // we know this won't overflow
assign a1[31] = a[31];

f2i #(WID) u2
(
    .clk(clk),
    .ce(1'b1),
    .i(a1),
    .o(i1)
);

always @(posedge clk)
    cmp2_o <= cmp1_o;

reg [11:0] lutadr;
always @(posedge clk)
    lutadr <= i1[11:0];

always @(posedge clk)
if (cmp2_o[1])  // abs(a) less than 8 ?
    o <= SigmoidLUT[lutadr]; 
else
    o <= `ONE | {a[31],31'd0};

endmodule

module sigmoid_tb();
reg clk, rst;
reg [12:0] ndx;
wire [31:0] o;

initial begin
    #0 rst = 1'b0;
    #0 clk = 1'b0;
    #10 rst = 1'b1;
    #40 rst = 1'b0;
end

always #5 clk = ~clk;

reg [31:0] RngLUT [0:8191];
initial begin
`include "C:\Cores4\nna\trunk\RangeTbl.ver"
end

sigmoid u1 (clk, RngLUT[ndx], o);

always @(posedge clk)
if (rst)
    ndx = 0;
else begin
    ndx = ndx + 13'd1;
end

wire [31:0] o1, o2;
// Multiply number by 4096 (it is in range -1 to 1) then convert to integer
assign o1[22:0] = o[22:0];
assign o1[30:23] = o[30:23] + 8'd12; // we know this won't overflow
assign o1[31] = o[31];

f2i #(32) u2
(
    .clk(clk),
    .ce(1'b1),
    .i(o1),
    .o(o2)
);

endmodule
