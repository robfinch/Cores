`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
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
module Thor_regfile2w6r(clk, clk2x, regset, wr0, wr1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, o0, o1, o2, o3, o4, o5);
parameter WID=64;
input clk;
input clk2x;
input [2:0] regset;
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

reg [WID-1:0] regs [0:511];
reg [5:0] wa2,wa3;
reg wr2,wr3;
reg [WID-1:0] i2,i3;
wire [5:0] wa;
wire wr;
wire [WID-1:0] i;
reg [8:0] rra0,rra1,rra2,rra3,rra4,rra5;

// We only care about what's in the regs to begin with in simulation. In sim
// the 'x' values propagate screwing things up. In real hardware there's no such
// thing as an 'x'.
`define SIMULATION
`ifdef SIMULATION
integer n;
initial begin
    for (n = 0; n < 512; n = n + 1)
    begin
        regs[n] = 0;
    end
end
`endif


assign o0 = rra0[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra0[5:0]==wa1)) ? i1 :
	(wr0 && (rra0[5:0]==wa0)) ? i0 :
	(wr2 && (rra0[5:0]==wa2)) ? i2 :
	(wr3 && (rra0[5:0]==wa3)) ? i3 :
	regs[rra0];
assign o1 = rra1[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra1[5:0]==wa1)) ? i1 :
	(wr0 && (rra1[5:0]==wa0)) ? i0 :
	(wr2 && (rra1[5:0]==wa2)) ? i2 :
	(wr3 && (rra1[5:0]==wa3)) ? i3 :
	regs[rra1];
assign o2 = rra2[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra2[5:0]==wa1)) ? i1 :
	(wr0 && (rra2[5:0]==wa0)) ? i0 :
	(wr2 && (rra2[5:0]==wa2)) ? i2 :
	(wr3 && (rra2[5:0]==wa3)) ? i3 :
	regs[rra2];
assign o3 = rra3[5:0]==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra3[5:0]==wa1)) ? i1 :
	(wr0 && (rra3[5:0]==wa0)) ? i0 :
	(wr2 && (rra3[5:0]==wa2)) ? i2 :
	(wr3 && (rra3[5:0]==wa3)) ? i3 :
	regs[rra3];
assign o4 = rra4[5:0]==6'd0 ? {WID{1'b0}} :
  (wr1 && (rra4[5:0]==wa1)) ? i1 :
  (wr0 && (rra4[5:0]==wa0)) ? i0 :
  (wr2 && (rra4[5:0]==wa2)) ? i2 :
  (wr3 && (rra4[5:0]==wa3)) ? i3 :
  regs[rra4];
assign o5 = rra5[5:0]==6'd0 ? {WID{1'b0}} :
  (wr1 && (rra5[5:0]==wa1)) ? i1 :
  (wr0 && (rra5[5:0]==wa0)) ? i0 :
  (wr2 && (rra5[5:0]==wa2)) ? i2 :
  (wr3 && (rra5[5:0]==wa3)) ? i3 :
  regs[rra5];

always @(posedge clk)
  wa2 <= wa1;
always @(posedge clk)
  wr2 <= wr1;
always @(posedge clk)
  i2 <= i1;
always @(posedge clk)
  wa3 <= wa0;
always @(posedge clk)
  wr3 <= wr0;
always @(posedge clk)
  i3 <= i0;

assign wa = clk ? wa3 : wa2;
assign wr = clk ? wr3 : wr2;
assign i = clk ? i3 : i2;

always @(negedge clk2x)
	if (wr)
		regs[{regset,wa}] <= i;

always @(posedge rclk) rra0 <= {regset,ra0};
always @(posedge rclk) rra1 <= {regset,ra1};
always @(posedge rclk) rra2 <= {regset,ra2};
always @(posedge rclk) rra3 <= {regset,ra3};
always @(posedge rclk) rra4 <= {regset,ra4};
always @(posedge rclk) rra5 <= {regset,ra5};

endmodule
