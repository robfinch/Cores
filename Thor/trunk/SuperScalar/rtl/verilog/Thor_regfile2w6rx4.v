`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Register file with two write ports and six read ports.
// ============================================================================
//
module Thor_regfile2w6rx4(clk, md, wr0, wr1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, o0, o1, o2, o3, o4, o5);
parameter WID=64;
input clk;
input [1:0] md;
input wr0;
input wr1;
input [5:0] wa0;
input [5:0] wa1;
input [WID-1:0] i0;
input [WID-1:0] i1;
input rclk;
input [5:0] ra0;
input [5:0] ra1;
input [5:0] ra2;
input [5:0] ra3;
input [5:0] ra4;
input [5:0] ra5;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;

reg [WID-1:0] regs0 [0:255];
reg [WID-1:0] regs1 [0:255];
reg [7:0] rra0,rra1,rra2,rra3,rra4,rra5;
wire [7:0] mdwa0 = {md&{2{wa0[5:3]!=3'b000}},wa0};
wire [7:0] mdwa1 = {md&{2{wa1[5:3]!=3'b000}},wa1};

reg whichreg [0:255];	// tracks which register file is the valid one for a given register

// We only care about what's in the regs to begin with in simulation. In sim
// the 'x' values propagate screwing things up. In real hardware there's no such
// thing as an 'x'.
`define SIMULATION
`ifdef SIMULATION
integer n;
initial begin
    for (n = 0; n < 256; n = n + 1)
    begin
        regs0[n] = 0;
        regs1[n] = 0;
        whichreg[n] = 0;
    end
end
`endif


assign o0 = rra0[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra0==mdwa1)) ? i1 :
	(wr0 && (rra0==mdwa0)) ? i0 :
	whichreg[rra0]==1'b0 ? regs0[rra0] : regs1[rra0];
assign o1 = rra1[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra1==mdwa1)) ? i1 :
	(wr0 && (rra1==mdwa0)) ? i0 :
	whichreg[rra1]==1'b0 ? regs0[rra1] : regs1[rra1];
assign o2 = rra2[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra2==mdwa1)) ? i1 :
	(wr0 && (rra2==mdwa0)) ? i0 :
	whichreg[rra2]==1'b0 ? regs0[rra2] : regs1[rra2];
assign o3 = rra3[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra3==mdwa1)) ? i1 :
	(wr0 && (rra3==mdwa0)) ? i0 :
	whichreg[rra3]==1'b0 ? regs0[rra3] : regs1[rra3];
assign o4 = rra4[5:0]==6'd0 ? {WID{1'b0}} :
    (wr1 && (rra4==mdwa1)) ? i1 :
    (wr0 && (rra4==mdwa0)) ? i0 :
    whichreg[rra4]==1'b0 ? regs0[rra4] : regs1[rra4];
assign o5 = rra5[5:0]==6'd0 ? {WID{1'b0}} :
    (wr1 && (rra5==mdwa1)) ? i1 :
    (wr0 && (rra5==mdwa0)) ? i0 :
    whichreg[rra5]==1'b0 ? regs0[rra5] : regs1[rra5];

always @(posedge clk)
	if (wr0)
		regs0[mdwa0] <= i0;

always @(posedge clk)
	if (wr1)
		regs1[mdwa1] <= i1;

always @(posedge rclk) rra0 <= {md&{2{ra0[5:3]!=3'b000}},ra0};
always @(posedge rclk) rra1 <= {md&{2{ra1[5:3]!=3'b000}},ra1};
always @(posedge rclk) rra2 <= {md&{2{ra2[5:3]!=3'b000}},ra2};
always @(posedge rclk) rra3 <= {md&{2{ra3[5:3]!=3'b000}},ra3};
always @(posedge rclk) rra4 <= {md&{2{ra4[5:3]!=3'b000}},ra4};
always @(posedge rclk) rra5 <= {md&{2{ra5[5:3]!=3'b000}},ra5};

always @(posedge clk)
	// writing three registers at once
	if (wr0 && wr1 && mdwa0==mdwa1)		// Two ports writing the same address
		whichreg[mdwa0] <= 1'b1;		// port one is the valid one
	// writing two registers
	else if (wr0 && wr1) begin
		whichreg[mdwa0] <= 1'b0;
		whichreg[mdwa1] <= 1'b1;
	end
	// writing a single register
	else if (wr0)
		whichreg[mdwa0] <= 1'b0;
	else if (wr1)
		whichreg[mdwa1] <= 1'b1;

endmodule
