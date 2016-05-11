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
module Thor_vregfile2w6r(clk, wr0, wr1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, ra4, ra5, ra6, ra7,
	o0, o1, o2, o3, o4, o5, o6, o7);
parameter WID=32;
input clk;
input wr0;
input wr1;
input [6:0] wa0;
input [6:0] wa1;
input [WID-1:0] i0;
input [WID-1:0] i1;
input rclk;
input [6:0] ra0;
input [6:0] ra1;
input [6:0] ra2;
input [6:0] ra3;
input [6:0] ra4;
input [6:0] ra5;
input [6:0] ra6;
input [6:0] ra7;
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;
output [WID-1:0] o4;
output [WID-1:0] o5;
output [WID-1:0] o6;
output [WID-1:0] o7;

reg [WID-1:0] regs0 [0:127];
reg [WID-1:0] regs1 [0:127];
reg [6:0] rra0,rra1,rra2,rra3,rra4,rra5,rra6,rra7;

reg whichreg [0:127];	// tracks which register file is the valid one for a given register

// We only care about what's in the regs to begin with in simulation. In sim
// the 'x' values propagate screwing things up. In real hardware there's no such
// thing as an 'x'.
`define SIMULATION
`ifdef SIMULATION
integer n;
initial begin
    for (n = 0; n < 128; n = n + 1)
    begin
        regs0[n] = 0;
        regs1[n] = 0;
        whichreg[n] = 0;
    end
end
`endif


assign o0 = 
	(wr1 && (rra0==wa1)) ? i1 :
	(wr0 && (rra0==wa0)) ? i0 :
	whichreg[rra0]==1'b0 ? regs0[rra0] : regs1[rra0];
assign o1 = 
	(wr1 && (rra1==wa1)) ? i1 :
	(wr0 && (rra1==wa0)) ? i0 :
	whichreg[rra1]==1'b0 ? regs0[rra1] : regs1[rra1];
assign o2 = 
	(wr1 && (rra2==wa1)) ? i1 :
	(wr0 && (rra2==wa0)) ? i0 :
	whichreg[rra2]==1'b0 ? regs0[rra2] : regs1[rra2];
assign o3 = 
	(wr1 && (rra3==wa1)) ? i1 :
	(wr0 && (rra3==wa0)) ? i0 :
	whichreg[rra3]==1'b0 ? regs0[rra3] : regs1[rra3];
assign o4 = 
    (wr1 && (rra4==wa1)) ? i1 :
    (wr0 && (rra4==wa0)) ? i0 :
    whichreg[rra4]==1'b0 ? regs0[rra4] : regs1[rra4];
assign o5 = 
    (wr1 && (rra5==wa1)) ? i1 :
    (wr0 && (rra5==wa0)) ? i0 :
    whichreg[rra5]==1'b0 ? regs0[rra5] : regs1[rra5];
assign o6 = 
    (wr1 && (rra6==wa1)) ? i1 :
    (wr0 && (rra6==wa0)) ? i0 :
    whichreg[rra6]==1'b0 ? regs0[rra6] : regs1[rra6];
assign o7 = 
    (wr1 && (rra7==wa1)) ? i1 :
    (wr0 && (rra7==wa0)) ? i0 :
    whichreg[rra7]==1'b0 ? regs0[rra7] : regs1[rra7];

always @(posedge clk)
	if (wr0)
		regs0[wa0] <= i0;

always @(posedge clk)
	if (wr1)
		regs1[wa1] <= i1;

always @(posedge rclk) rra0 <= ra0;
always @(posedge rclk) rra1 <= ra1;
always @(posedge rclk) rra2 <= ra2;
always @(posedge rclk) rra3 <= ra3;
always @(posedge rclk) rra4 <= ra4;
always @(posedge rclk) rra5 <= ra5;
always @(posedge rclk) rra6 <= ra6;
always @(posedge rclk) rra7 <= ra7;

always @(posedge clk)
	// writing three registers at once
	if (wr0 && wr1 && wa0==wa1)		// Two ports writing the same address
		whichreg[wa0] <= 1'b1;		// port one is the valid one
	// writing two registers
	else if (wr0 && wr1) begin
		whichreg[wa0] <= 1'b0;
		whichreg[wa1] <= 1'b1;
	end
	// writing a single register
	else if (wr0)
		whichreg[wa0] <= 1'b0;
	else if (wr1)
		whichreg[wa1] <= 1'b1;

endmodule
