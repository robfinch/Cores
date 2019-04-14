/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

WBM reader/writer

Loosely based on the vga lcds wishbone reader (LGPL) in orpsocv2 by Julius Baxter, julius@opencores.org

 This file is part of orgfx.

 orgfx is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. 

 orgfx is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License
 along with orgfx.  If not, see <http://www.gnu.org/licenses/>.

*/

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module gfx_wbm_rw64 (clk_i, wbs_cs_i,
  cyc_o, stb_o, cti_o, bte_o, we_o, adr_o, sel_o, ack_i, err_i, dat_i, dat_o, sint_o,
  read_request_i, write_request_i,
  texture_addr_i, texture_sel_i, texture_dat_o, texture_dat_i, texture_data_ack);

// inputs & outputs
input wbs_cs_i;

// wishbone signals
input             clk_i;    // master clock input
output reg        cyc_o = 1'b0;    // cycle output
output            stb_o;    // strobe ouput
output [ 2:0]     cti_o;    // cycle type id
output [ 1:0]     bte_o;    // burst type extension
output reg        we_o = 1'b0;     // write enable output
output reg [31:0] adr_o;    // address output
output reg [ 7:0] sel_o;    // byte select outputs (only 32bits accesses are supported)
input             ack_i;    // wishbone cycle acknowledge
input             err_i;    // wishbone cycle error
input [63:0]      dat_i;    // wishbone data in
output reg [63:0] dat_o;

output reg        sint_o;     // non recoverable error, interrupt host

// Request stuff
input         read_request_i;
input         write_request_i;

input  [31:3] texture_addr_i;
input   [7:0] texture_sel_i;
output reg [63:0] texture_dat_o;
input  [63:0] texture_dat_i;
output reg    texture_data_ack = 1'b0;

always @(posedge clk_i)
if (~(ack_i|err_i))
  sel_o <= texture_sel_i;
always @(posedge clk_i)
if (~(ack_i|err_i))
	adr_o  <= {texture_addr_i, 3'b0};
always @(posedge clk_i)
	if (ack_i)
		texture_dat_o <= dat_i;
always @(posedge clk_i)
	dat_o <= texture_dat_i;
always @(posedge clk_i)
if (~(ack_i|err_i))
  we_o <= write_request_i;
always @(posedge clk_i)
	if (err_i)
		sint_o = 1'b1;
	else if (wbs_cs_i)
		sint_o <= 1'b0;

assign stb_o  = 1'b1;
assign bte_o  = 2'b00;
assign cti_o  = 3'b000;

wire pe_ack;
edge_det ued1 (.clk(clk_i), .ce(1'b1), .i(ack_i|err_i), .pe(pe_ack), .ne(), .ee());

always @(posedge clk_i)
begin
  texture_data_ack <= 1'b0;
  if (pe_ack)
  	texture_data_ack <= 1'b1;
end

always @(posedge clk_i)
begin
	if (ack_i|err_i)
		cyc_o <= 1'b0;
	else if (~(ack_i|err_i) & (read_request_i|write_request_i))
		cyc_o <= 1'b1;
end

endmodule
