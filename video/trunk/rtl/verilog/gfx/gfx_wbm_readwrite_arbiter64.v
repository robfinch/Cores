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

*/

// 4 Masters, one slave
module gfx_wbm_readwrite_arbiter64
  (
   master_busy_o,
   // Interface against the wbm read module
   read_request_o,
   write_request_o,
   addr_o,
   we_o,
   sel_o,
   dat_i,
   dat_o,
   ack_i,
   // Interface against writer
   mw_write_request_i,
   mw_addr_i,
   mw_we_i,
   mw_sel_i,
   mw_dat_i,
   mw_ack_o,
   // Interface against masters (clip)
   m0_read_request_i,
   m0_addr_i,
   m0_sel_i,
   m0_dat_o,
   m0_ack_o,
   // Interface against masters (fragment processor)
   m1_read_request_i,
   m1_addr_i,
   m1_sel_i,
   m1_dat_o,
   m1_ack_o,
   // Interface against masters (blender)
   m2_read_request_i,
   m2_addr_i,
   m2_sel_i,
   m2_dat_o,
   m2_ack_o,
   // Interface against masters (textblit)
   m3_read_request_i,
   m3_addr_i,
   m3_sel_i,
   m3_dat_o,
   m3_ack_o
   );

output        master_busy_o;
// Interface against the wbm read module
output        read_request_o;
output				write_request_o;
output reg [31:3] addr_o;
output        we_o;
output reg [7:0] sel_o;
input  [63:0] dat_i;
output [63:0] dat_o;
input         ack_i;
// Interface against writer
input         mw_write_request_i;
input  [31:3] mw_addr_i;
input   [7:0] mw_sel_i;
input         mw_we_i;
input  [63:0] mw_dat_i;
output        mw_ack_o;
// Interface against masters (clip)
input         m0_read_request_i;
input  [31:3] m0_addr_i;
input   [7:0] m0_sel_i;
output [63:0] m0_dat_o;
output        m0_ack_o;
// Interface against masters (fragment processor)
input         m1_read_request_i;
input  [31:3] m1_addr_i;
input   [7:0] m1_sel_i;
output [63:0] m1_dat_o;
output        m1_ack_o;
// Interface against masters (blender)
input         m2_read_request_i;
input  [31:3] m2_addr_i;
input   [7:0] m2_sel_i;
output [63:0] m2_dat_o;
output        m2_ack_o;
// Interface against masters (textblit)
input         m3_read_request_i;
input  [31:3] m3_addr_i;
input   [7:0] m3_sel_i;
output [63:0] m3_dat_o;
output        m3_ack_o;

// Master ins -> |MUX> -> these wires
wire        rreq_w;
wire [31:3] addr_w;
wire  [7:0] sel_w;
// Slave ins -> |MUX> -> these wires
wire [63:0] dat_w;
wire        ack_w;

// Master select (MUX controls)
wire [3:0] master_sel;

assign master_busy_o = m0_read_request_i | m1_read_request_i | m2_read_request_i | m3_read_request | mw_write_request_i;

// priority to wbm1, the blender master
assign master_sel[4] = m3_read_request_i & !m0_read_request_i & !m1_read_request_i & !m2_read_request_i & !mw_write_request_i;
assign master_sel[0] = m0_read_request_i & !m1_read_request_i & !m2_read_request_i & !mw_write_request_i;
assign master_sel[1] = m1_read_request_i & !m2_read_request_i & !mw_write_request_i;
assign master_sel[2] = m2_read_request_i & !mw_write_request_i;
assign master_sel[3] = mw_write_request_i;

assign dat_o = mw_dat_i;
assign mw_ack_o = ack_i & master_sel[3];

// Master input mux, priority to blender master
assign m0_dat_o = dat_i;
assign m0_ack_o = ack_i & master_sel[0];

assign m1_dat_o = dat_i;
assign m1_ack_o = ack_i & master_sel[1];

assign m2_dat_o = dat_i;
assign m2_ack_o = ack_i & master_sel[2];

assign m3_dat_o = dat_i;
assign m3_ack_o = ack_i & master_sel[4];

assign read_request_o = master_sel[4] |
												master_sel[2] |
                        master_sel[1] |
                        master_sel[0];
assign write_request_o = master_sel[3];

always @*
casez(master_sel)
5'b1????:	addr_o <= m3_addr_i;
5'b01???:	addr_o <= mw_addr_i;
5'b001??:	addr_o <= m2_addr_i;
5'b0001?:	addr_o <= m1_addr_i;
5'b00001:	addr_o <= m0_addr_i;
default:	addr_o <= 32'h0;
endcase

always @*
casez(master_sel)
5'b1????:	sel_o <= m3_sel_i;
5'b01???:	sel_o <= mw_sel_i;
5'b001??:	sel_o <= m2_sel_i;
5'b0001?:	sel_o <= m1_sel_i;
5'b00001:	sel_o <= m0_sel_i;
default:	sel_o <= 8'h0;
endcase

assign we_o   = master_sel[3] ? mw_we_i : 1'b0;
   
endmodule
