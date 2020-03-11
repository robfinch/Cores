`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
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
// Arbitrates the bus for up to eight masters.
//	
//	reg
//	0x00	- control reg (read / write)
//					bit 0 = 0 = rotating priorities
//									1 = fixed
//					bit 4 to 7 = fixed priority base channel
//
//	0x04	- master request enable (read / write)
//			this register contains request enable bits
//			for each request line. 1 = request
//			enabled, 0 = request disabled. On reset this
//			register is set to zero (disable all masters).
//
//	0x08   - write only
//			this register disables the master indicated
//			by the low order three bits of the input data
//			
//	0x0C	- write only
//			this register enables the master indicated
//			by the low order three bits of the input data
//
//=============================================================================

module Petajon_pmc
(
	input rst_i,		// reset
	input clk_i,		// system clock
	input cs_i,
	input cyc_i,
	input stb_i,
	output ack_o,       // controller is ready
	input wr_i,			// write
	input [3:0] adr_i,	// address
	input [31:0] dat_i,
	output reg [31:0] dat_o,
	input ref_clk_i,
	input bus_idle,
	input m0, m1, m2, m3, m4, m5, m6, m7,
	output a0, a1, a2, a3, a4, a5, a6, a7,
	output [2:0] ms
);
wire clk;
reg [2:0] fcb;					// fixed channel basis
reg [2:0] msel;
reg [7:0] me;						// master enable register
reg rot;
reg arbit;
reg rdy1;
wire [7:0] m = { m7, m6, m5, m4, m3, m2, m1, m0 };
reg [7:0] a;
assign a0 = a[0];
assign a1 = a[1];
assign a2 = a[2];
assign a3 = a[3];
assign a4 = a[4];
assign a5 = a[5];
assign a6 = a[6];
assign a7 = a[7];
integer n;

initial begin
	me <= 8'h0;	
end

wire cs = cyc_i && stb_i && cs_i;

assign clk = clk_i;
assign ms = msel;

always @(posedge clk)
	rdy1 <= cs;
assign ack_o = cs ? (wr_i ? 1'b1 : rdy1) : 1'b0;

// write registers	
always @(posedge clk)
	if (rst_i) begin
		fcb <= 3'd0;
		me <= 8'h1;
		rot <= 1'b1;
	end
	else begin
		if (cs & wr_i) begin
			case (adr_i[3:2])
			2'd0: begin rot <= dat_i[0]; fcb <= dat_i[6:4]; end
			2'd1:	me[7:0] <= dat_i[7:0];
			2'd2,2'd3:	me[dat_i[2:0]] <= adr_i[2];
			endcase
		end
	end

// read registers
always @(posedge clk)
begin
	if (cs)
		case (adr_i[3:2])
		2'd0:	dat_o <= {25'b0,fcb,3'b0,rot};
		2'd1:	dat_o <= {24'd0,me};
		default:	dat_o <= 32'd0;
		endcase
	else
		dat_o <= 32'h0000;
end

wire [6:0] ne_m;
edge_det ued0 (.rst(rst_i), .clk(ref_clk_i), .i(m[0]), .pe(), .ne(ne_m[0]), .ee());
edge_det ued1 (.rst(rst_i), .clk(ref_clk_i), .i(m[1]), .pe(), .ne(ne_m[1]), .ee());
edge_det ued2 (.rst(rst_i), .clk(ref_clk_i), .i(m[2]), .pe(), .ne(ne_m[2]), .ee());
edge_det ued3 (.rst(rst_i), .clk(ref_clk_i), .i(m[3]), .pe(), .ne(ne_m[3]), .ee());
edge_det ued4 (.rst(rst_i), .clk(ref_clk_i), .i(m[4]), .pe(), .ne(ne_m[4]), .ee());
edge_det ued5 (.rst(rst_i), .clk(ref_clk_i), .i(m[5]), .pe(), .ne(ne_m[5]), .ee());
edge_det ued6 (.rst(rst_i), .clk(ref_clk_i), .i(m[6]), .pe(), .ne(ne_m[6]), .ee());

always @(posedge ref_clk_i)
begin
	arbit <= 1'b0;
	case(msel)
	3'd0:	if (ne_m[0])	arbit <= 1'b1;
	3'd1:	if (ne_m[1])	arbit <= 1'b1;
	3'd2:	if (ne_m[2])	arbit <= 1'b1;
	3'd3:	if (ne_m[3])	arbit <= 1'b1;
	3'd4:	if (ne_m[4])	arbit <= 1'b1;
	3'd5:	if (ne_m[5])	arbit <= 1'b1;
	3'd6:	if (ne_m[6])	arbit <= 1'b1;
	3'd7:	arbit <= bus_idle;
	endcase
end

always @(posedge ref_clk_i)
if (rst_i)
	msel <= 3'd7;
else begin
	if (|m & arbit) begin
		for (n = 7; n >= 0; n = n - 1)
			if (rot) begin
				if (m[(n + msel + 1) % 8] & me[(n + msel + 1) % 8]) msel <= (n + msel + 1) % 8;
			end
			else
				if (m[(n + fcb) % 8] & me[(n + fcb) % 8]) msel <= (n + fcb) % 8;
	end
	else
		msel <= 3'd7;
	a <= 8'h00;
	a[msel] <= 1'b1;
end

endmodule
