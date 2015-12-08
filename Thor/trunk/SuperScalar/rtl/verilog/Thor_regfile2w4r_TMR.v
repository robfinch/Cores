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
// Register file with two write ports and four read ports.
// ============================================================================
//
module Thor_regfile2w4r(clk, wr0, wr1, wa0, wa1, i0, i1,
	rclk, ra0, ra1, ra2, ra3, o0, o1, o2, o3);
parameter WID=64;
input clk;
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
output [WID-1:0] o0;
output [WID-1:0] o1;
output [WID-1:0] o2;
output [WID-1:0] o3;

reg [WID-1:0] regs0a [0:63];
reg [WID-1:0] regs0b [0:63];
reg [WID-1:0] regs0c [0:63];
reg [WID-1:0] regs1a [0:63];
reg [WID-1:0] regs1b [0:63];
reg [WID-1:0] regs1c [0:63];
reg [5:0] rra0,rra1,rra2,rra3;

reg whichreg [0:63];	// tracks which register file is the valid one for a given register

assign o0 = rra0==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra0==wa1)) ? i1 :
	(wr0 && (rra0==wa0)) ? i0 :
	whichreg[rra0]==1'b0 ? (regs0a[rra0]&(regs0b[rra0]^32'hAAAAAAAA) ) | (regs0a[rra0]&(regs0c[rra0]^32'h55555555) ) | ((regs0b[rra0]^32'hAAAAAAAA)&(regs0c[rra0]^32'h55555555) )
	                       : (regs1a[rra0]&(regs1b[rra0]^32'hAAAAAAAA) ) | (regs1a[rra0]&(regs1c[rra0]^32'h55555555) ) | ((regs1b[rra0]^32'hAAAAAAAA)&(regs1c[rra0]^32'h55555555) );
assign o1 = rra1==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra1==wa1)) ? i1 :
	(wr0 && (rra1==wa0)) ? i0 :
	whichreg[rra1]==1'b0 ? (regs0a[rra1]&(regs0b[rra1]^32'hAAAAAAAA) ) | (regs0a[rra1]&(regs0c[rra1]^32'h55555555) ) | ((regs0b[rra1]^32'hAAAAAAAA)&(regs0c[rra1]^32'h55555555) )
                           : (regs1a[rra1]&(regs1b[rra1]^32'hAAAAAAAA) ) | (regs1a[rra1]&(regs1c[rra1]^32'h55555555) ) | ((regs1b[rra1]^32'hAAAAAAAA)&(regs1c[rra1]^32'h55555555) );
//	whichreg[rra1]==1'b0 ? regs0[rra1] : regs1[rra1];
assign o2 = rra2==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra2==wa1)) ? i1 :
	(wr0 && (rra2==wa0)) ? i0 :
//	whichreg[rra2]==1'b0 ? regs0[rra2] : regs1[rra2];
	whichreg[rra2]==1'b0 ? (regs0a[rra2]&(regs0b[rra2]^32'hAAAAAAAA) ) | (regs0a[rra2]&(regs0c[rra2]^32'h55555555) ) | ((regs0b[rra2]^32'hAAAAAAAA)&(regs0c[rra2]^32'h55555555) )
                           : (regs1a[rra2]&(regs1b[rra2]^32'hAAAAAAAA) ) | (regs1a[rra2]&(regs1c[rra2]^32'h55555555) ) | ((regs1b[rra2]^32'hAAAAAAAA)&(regs1c[rra2]^32'h55555555) );
assign o3 = rra3==6'd0 ? {WID{1'b0}} :
	(wr1 && (rra3==wa1)) ? i1 :
	(wr0 && (rra3==wa0)) ? i0 :
//	whichreg[rra3]==1'b0 ? regs0[rra3] : regs1[rra3];
	whichreg[rra3]==1'b0 ? (regs0a[rra3]&(regs0b[rra3]^32'hAAAAAAAA) ) | (regs0a[rra3]&(regs0c[rra3]^32'h55555555) ) | ((regs0b[rra3]^32'hAAAAAAAA)&(regs0c[rra3]^32'h55555555) )
                           : (regs1a[rra3]&(regs1b[rra3]^32'hAAAAAAAA) ) | (regs1a[rra3]&(regs1c[rra3]^32'h55555555) ) | ((regs1b[rra3]^32'hAAAAAAAA)&(regs1c[rra3]^32'h55555555) );

always @(posedge clk)
	if (wr0) begin
		regs0a[wa0] <= i0;
		regs0b[wa0] <= i0^32'hAAAAAAAA;
		regs0c[wa0] <= i0^32'h55555555;
    end

always @(posedge clk)
	if (wr1) begin
		regs1a[wa1] <= i1;
		regs1b[wa1] <= i1^32'hAAAAAAAA;
		regs1c[wa1] <= i1^32'h55555555;
	end

always @(posedge rclk) rra0 <= ra0;
always @(posedge rclk) rra1 <= ra1;
always @(posedge rclk) rra2 <= ra2;
always @(posedge rclk) rra3 <= ra3;

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
