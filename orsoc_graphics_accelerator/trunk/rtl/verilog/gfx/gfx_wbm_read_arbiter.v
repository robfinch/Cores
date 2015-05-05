/*
ORSoC GFX accelerator core
Copyright 2012, ORSoC, Per Lenander, Anton Fosselius.

WBM reader arbiter

Loosely based on the arbiter_dbus.v (LGPL) in orpsocv2 by Julius Baxter, julius@opencores.org

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
 
 Robert Finch
 Modified to support 128 bit wide memory interface.
*/

// 3 Masters, one slave
module gfx_wbm_read_arbiter
  (
   rst,
   clk,
   master_busy_o,
   // Interface against the wbm read module
   read_request_o,
   addr_o,
   dat_i,
   ack_i,
   nack_o,
   // Interface against masters (clip)
   m0_read_request_i,
   m0_addr_i,
   m0_dat_o,
   m0_ack_o,
   m0_nack_i,
   // Interface against masters (fragment processor)
   m1_read_request_i,
   m1_addr_i,
   m1_dat_o,
   m1_ack_o,
   m1_nack_i,
   // Interface against masters (blender)
   m2_read_request_i,
   m2_addr_i,
   m2_dat_o,
   m2_ack_o,
   m2_nack_i
   );

input rst;
input clk;
output        master_busy_o;
// Interface against the wbm read module
output reg    read_request_o;
output reg [31:0] addr_o;
input [127:0] dat_i;
input         ack_i;
output        nack_o;
// Interface against masters (clip)
input         m0_read_request_i;
input  [31:0] m0_addr_i;
output [127:0] m0_dat_o;
output        m0_ack_o;
input         m0_nack_i;
// Interface against masters (fragment processor)
input         m1_read_request_i;
input  [31:0] m1_addr_i;
output [127:0] m1_dat_o;
output        m1_ack_o;
input         m1_nack_i;
// Interface against masters (blender)
input         m2_read_request_i;
input  [31:0] m2_addr_i;
output [127:0] m2_dat_o;
output        m2_ack_o;
input         m2_nack_i;

// Master select (MUX controls)
reg [2:0] master_sel;

assign master_busy_o = m0_read_request_i | m1_read_request_i | m2_read_request_i;

// Master input mux, priority to blender master
assign m0_dat_o = dat_i;
assign m0_ack_o = ack_i & master_sel[0];

assign m1_dat_o = dat_i;
assign m1_ack_o = ack_i & master_sel[1];

assign m2_dat_o = dat_i;
assign m2_ack_o = ack_i & master_sel[2];

assign nack_o = master_sel[2] ? m2_nack_i :
			    master_sel[1] ? m1_nack_i :
				master_sel[0] ? m0_nack_i :
				1'b0;

parameter IDLE = 2'b1;
parameter WAITNACK = 2'b2;
reg [1:0] state;
always @(posedge clk)
if (rst) begin
	master_sel <= 3'b000;
	read_request_o <= 1'b0;
	state <= IDLE;
end
else begin
case(state)
IDLE:
	begin
		read_request_o <= 1'b0;
		if (m2_read_request_i) begin
			read_request_o <= 1'b1;
			addr_o <= m2_addr_i;
			master_sel <= 3'b100;
			state <= WAITNACK;
		end
		else if (m1_read_request_i) begin
			read_request_o <= 1'b1;
			addr_o <= m1_addr_i;
			master_sel <= 3'b010;
			state <= WAITNACK;
		end
		else if (m0_read_request_i) begin
			read_request_o <= 1'b1;
			addr_o <= m0_addr_i;
			master_sel <= 3'b001;
			state <= WAITNACK;
		end
		else
			master_sel <= 3'b000;
	end
WAITNACK:
	begin
		if (ack_i)
			read_request <= 1'b0;
		if (nack_o) begin
			read_request <= 1'b0;
			master_sel <= 3'b000;
			state <= IDLE;
		end
	end
endcase
end

endmodule // gfx_wbm_read_arbiter

