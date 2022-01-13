// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	pnode_x1.sv
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import rf6809_pkg::*;
import nic_pkg::*;

module pnode_x1(id, rst_i, clk_i, packet_i, packet_o, ipacket_i, ipacket_o,
	rpacket_i, rpacket_o,	pc);
input [5:0] id;
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;
input Packet rpacket_i;
output Packet rpacket_o;
input IPacket ipacket_i;
output IPacket ipacket_o;
output [`TRPBYTE] pc;

wire [2:0] c1_cti;
wire c1_cyc;
wire c1_stb;
wire c1_we;
reg c1_ack;
reg c1_aack;
wire [3:0] c1_atag;
wire c1_rty;
wire [35:0] c1_adr;
wire [`BYTE1] c1_dato;
reg [`BYTE1] c1_dati;
wire c1_irq;
wire c1_firq;
wire [`BYTE1] c1_cause;

wire nic1_ack;
wire [`BYTE1] nic1_dato;

reg w1;

reg r1_en;
reg r1_we;
wire r1_ack;
reg [16:0] r1_adr;
reg [`BYTE1] r1_dati;
wire [`BYTE1] r1_dato;
reg [`BYTE1] r1_cdat;

wire m1_cyc;
wire m1_stb;
wire m1_ack;
wire m1_we;
wire [23:0] m1_adr;
reg [`BYTE1] m1_dati;
wire [`BYTE1] m1_dato;

nic unic1
(
	.id(id),
	.rst_i(rst_i),
	.clk_i(clk_i),
	.s_cti_i(c1_cti),
	.s_cyc_i(c1_cyc),
	.s_stb_i(c1_stb),
	.s_ack_o(nic1_ack),
	.s_aack_o(c1_aack),
	.s_atag_o(c1_atag),
	.s_rty_o(c1_rty),
	.s_we_i(c1_we),
	.s_adr_i(c1_adr),
	.s_dat_i(c1_dato),
	.s_dat_o(nic1_dato),
	.m_cyc_o(m1_cyc),
	.m_stb_o(m1_stb),
	.m_ack_i(m1_ack),
	.m_we_o(m1_we),
	.m_adr_o(m1_adr),
	.m_dat_o(m1_dato),
	.m_dat_i(m1_dati),
	.packet_i(packet_i),
	.packet_o(packet_o),
	.rpacket_i(rpacket_i),
	.rpacket_o(rpacket_o),
	.ipacket_i(ipacket_i),
	.ipacket_o(ipacket_o),
	.irq_i(1'b0),
	.firq_i(1'b0),
	.cause_i(1'b0),
	.iserver_i(6'd0),
	.irq_o(c1_irq),
	.firq_o(c1_firq),
	.cause_o(c1_cause)
);

/*
nic_prop uprp1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.packet_i(packet_y),
	.packet_o(packet_o),
	.ipacket_i(ipacket_y),
	.ipacket_o(ipacket_o)
);
*/

wire c1_ram_cs = c1_adr[23:16]==8'h0 && c1_cyc && c1_stb;
wire m1_ram_cs = m1_adr[23:21]==3'b110 && m1_cyc && m1_stb;

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag_c1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(c1_ram_cs),
	.we_i(c1_ram_cs && c1_we),
	.o(r1_ack),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag_m1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(m1_ram_cs),
	.we_i(m1_ram_cs & m1_we),
	.o(m1_ack),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);

nodeRam32k unr1
(
  .clka(clk_i),    // input wire clka
  .ena(c1_ram_cs),      // input wire ena
  .wea(c1_we),      // input wire [0 : 0] wea
  .addra(c1_adr[14:0]),  // input wire [16 : 0] addra
  .dina(c1_dato),    // input wire [7 : 0] dina
  .douta(r1_dato),  // output wire [7 : 0] douta
  .clkb(clk_i),    // input wire clkb
  .enb(m1_ram_cs),      // input wire enb
  .web(m1_we),      // input wire [0 : 0] web
  .addrb(m1_adr[14:0]),  // input wire [16 : 0] addrb
  .dinb(m1_dato),    // input wire [7 : 0] dinb
  .doutb(m1_dati)  // output wire [7 : 0] doutb
);

assign c1_ack = r1_ack|nic1_ack;
assign c1_dati = c1_ram_cs?r1_dato:nic1_dato;

rf6809 ucpu1
(
	.id(id),
	.rst_i(rst_i),
	.clk_i(clk_i),
	.halt_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(c1_irq),
	.firq_i(c1_firq),
	.vec_i(36'h0),
	.ba_o(),
	.bs_o(),
	.lic_o(),
	.tsc_i(1'b0),
	.rty_i(c1_rty),
	.bte_o(),
	.cti_o(c1_cti),
	.bl_o(),
	.lock_o(),
	.cyc_o(c1_cyc),
	.stb_o(c1_stb),
	.we_o(c1_we),
	.ack_i(c1_ack),
	.aack_i(c1_ram_cs?r1_ack:c1_aack),
	.atag_i(c1_ram_cs?c1_adr[3:0]:c1_atag),
	.adr_o(c1_adr),
	.dat_i(c1_dati),
	.dat_o(c1_dato),
	.state()
);

assign pc = ucpu1.pc;

endmodule
