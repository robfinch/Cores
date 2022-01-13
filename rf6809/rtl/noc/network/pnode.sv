// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	pnode.sv
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

module pnode(id, rst_i, clk_i, packet_i, packet_o, ipacket_i, ipacket_o,
	pc1, pc2);
input [4:0] id;
input rst_i;
input clk_i;
input Packet packet_i;
output Packet packet_o;
input IPacket ipacket_i;
output IPacket ipacket_o;
output [`TRPBYTE] pc1;
output [`TRPBYTE] pc2;

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
wire [2:0] c2_cti;
wire c2_cyc;
wire c2_stb;
wire c2_we;
reg c2_ack;
reg c2_aack;
wire [3:0] c2_atag;
wire c2_rty;
wire [35:0] c2_adr;
wire [`BYTE1] c2_dato;
reg [`BYTE1] c2_dati;
wire c2_irq;
wire c2_firq;
wire [`BYTE1] c2_cause;

wire nic1_ack;
wire [`BYTE1] nic1_dato;
wire nic2_ack;
wire [`BYTE1] nic2_dato;

reg w1, w2;

reg r1_en;
reg r1_we;
reg r1_ack, r1_aack;
reg [16:0] r1_adr;
reg [`BYTE1] r1_dati;
wire [`BYTE1] r1_dato;
reg [`BYTE1] r1_cdat;
reg r2_en;
reg r2_we;
reg r2_ack, r2_aack;
reg [16:0] r2_adr;
reg [`BYTE1] r2_dati;
wire [`BYTE1] r2_dato;
reg [`BYTE1] r2_cdat;

wire m1_cyc;
wire m1_stb;
reg m1_ack;
wire m1_we;
wire [23:0] m1_adr;
reg [`BYTE1] m1_dati;
wire [`BYTE1] m1_dato;
wire m2_cyc;
wire m2_stb;
reg m2_ack;
wire m2_we;
wire [23:0] m2_adr;
reg [`BYTE1] m2_dati;
wire [`BYTE1] m2_dato;

Packet packet_x, packet_y;
IPacket ipacket_x, ipacket_y;

nic unic1
(
	.id({id,1'b0}),
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
	.packet_o(packet_x),
	.ipacket_i(ipacket_i),
	.ipacket_o(ipacket_x),
	.irq_i(1'b0),
	.firq_i(1'b0),
	.cause_i(1'b0),
	.iserver_i(6'd0),
	.irq_o(c1_irq),
	.firq_o(c1_firq),
	.cause_o(c1_cause)
);

nic unic2
(
	.id({id,1'b1}),
	.rst_i(rst_i),
	.clk_i(clk_i),
	.s_cti_i(c2_cti),
	.s_cyc_i(c2_cyc),
	.s_stb_i(c2_stb),
	.s_ack_o(nic2_ack),
	.s_atag_o(c2_atag),
	.s_aack_o(c2_aack),
	.s_rty_o(c2_rty),
	.s_we_i(c2_we),
	.s_adr_i(c2_adr),
	.s_dat_i(c2_dato),
	.s_dat_o(nic2_dato),
	.m_cyc_o(m2_cyc),
	.m_stb_o(m2_stb),
	.m_ack_i(m2_ack),
	.m_we_o(m2_we),
	.m_adr_o(m2_adr),
	.m_dat_o(m2_dato),
	.m_dat_i(m2_dati),
	.packet_i(packet_x),
	.packet_o(packet_o),
	.ipacket_i(ipacket_x),
	.ipacket_o(ipacket_o),
	.irq_i(1'b0),
	.firq_i(1'b0),
	.cause_i(1'b0),
	.iserver_i(6'd0),
	.irq_o(c2_irq),
	.firq_o(c2_firq),
	.cause_o(c2_cause)
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

reg [5:0] state1, state2;
parameter ST_IDLE = 6'd0;
parameter ST_ACK = 6'd1;
parameter ST_RD1 = 6'd2;
parameter ST_RD2 = 6'd3;
parameter ST_RD3 = 6'd4;
parameter ST_RD4 = 6'd5;
parameter ST_ACKC = 6'd6;

always_ff @(posedge clk_i)
if (rst_i) begin
	r1_ack <= 1'b0;
	r1_aack <= 1'b0;
	r1_cdat <= 12'h00;
	r1_en <= FALSE;
	r1_we <= FALSE;
	state1 <= ST_IDLE;
end
else begin
	// If the cycle is over, clear the ack and reset the data bus.
	if (!(c1_cyc & c1_stb)) begin
		r1_ack <= 1'b0;
		r1_aack <= 1'b0;
		r1_cdat <= 12'h00;
	end
	if (!(m1_cyc & m1_stb)) begin
		m1_ack <= 1'b0;
		m1_dati <= 12'h00;
	end
	case(state1)
	ST_IDLE:
		if (m1_cyc) begin
			w1 <= 1'b0;
			if (m1_adr[23:20]==4'hC || m1_adr[23:20]==4'hD) begin
				r1_adr <= m1_adr;
				r1_dati <= m1_dato;
				r1_we <= m1_we;
				r1_en <= TRUE;
				state1 <= ST_RD1;
			end
			else
				m1_ack <= 1'b1;
		end
		else if (c1_cyc) begin
			w1 <= 1'b1;
			if (c1_adr[23:22]==2'b00) begin
				state1 <= c1_we ? ST_RD3 : ST_RD1;
				r1_we <= c1_we;
				r1_en <= TRUE;
				r1_adr <= c1_adr;
				r1_dati <= c1_dato;
			end
		end
	// Three cycle read latency.
	ST_RD1:	state1 <= ST_RD2;
	ST_RD2:	state1 <= ST_RD3;
	ST_RD3:
		begin
			state1 <= ST_ACK;
			r1_we <= FALSE;
			if (w1) begin
				r1_cdat <= r1_dato;
				r1_ack <= 1'b1;
				r1_aack <= 1'b1;
			end
			else begin
				m1_dati <= r1_dato;
				m1_ack <= 1'b1;
			end
		end
	ST_ACK:
		begin
			r1_en <= FALSE;
			if ((m1_ack & m1_cyc & m1_stb) || (r1_ack & c1_cyc & c1_stb))
				;
			else
				state1 <= ST_IDLE;
		end
	default:
		state1 <= ST_IDLE;
	endcase
end

always_ff @(posedge clk_i)
if (rst_i) begin
	r2_ack <= 1'b0;
	r2_aack <= 1'b0;
	r2_cdat <= 12'h00;
	r2_en <= FALSE;
	r2_we <= FALSE;
	state2 <= ST_IDLE;
end
else begin
	if (!(c2_cyc & c2_stb)) begin
		r2_ack <= 1'b0;
		r2_aack <= 1'b0;
		r2_cdat <= 12'h00;
	end
	if (!(m2_cyc & m2_stb)) begin
		m2_ack <= 1'b0;
		m2_dati <= 12'h00;
	end
	case(state2)
	ST_IDLE:
		begin
			if (m2_cyc) begin
				w2 <= 1'b0;
				if (m2_adr[23:20]==4'hC || m2_adr[23:20]==4'hD) begin
					r2_adr <= m2_adr;
					r2_dati <= m2_dato;
					r2_we <= m2_we;
					r2_en <= TRUE;
					state2 <= ST_RD1;
				end
				else
					m2_ack <= 1'b1;
			end
			else if (c2_cyc) begin
				w2 <= 1'b1;
				if (c2_adr[23:22]==2'b00) begin
					r2_adr <= c2_adr;
					r2_dati <= c2_dato;
					state2 <= c2_we ? ST_RD3 : ST_RD1;
					r2_we <= c2_we;
					r2_en <= TRUE;
				end
			end
		end
	ST_RD1:	state2 <= ST_RD2;
	ST_RD2:	state2 <= ST_RD3;
	ST_RD3:
		begin
			state2 <= ST_ACK;
			r2_we <= FALSE;
			r2_en <= FALSE;
			if (w2) begin
				r2_cdat <= r2_dato;
				r2_ack <= 1'b1;
				r2_aack <= 1'b1;
			end
			else begin
				m2_dati <= r2_dato;
				m2_ack <= 1'b1;
			end
		end
	ST_ACK:
		if ((m2_ack & m2_cyc & m2_stb) || (r2_ack & c2_cyc & c2_stb))
			;
		else
			state2 <= ST_IDLE;
	default:
		state2 <= ST_IDLE;
	endcase
end

nodeRam unr1
(
  .clka(clk_i),    // input wire clka
  .ena(r1_en),      // input wire ena
  .wea(r1_we),      // input wire [0 : 0] wea
  .addra(r1_adr[16:0]),  // input wire [16 : 0] addra
  .dina(r1_dati),    // input wire [7 : 0] dina
  .douta(r1_dato),  // output wire [7 : 0] douta
  .clkb(clk_i),    // input wire clkb
  .enb(r2_en),      // input wire enb
  .web(r2_we),      // input wire [0 : 0] web
  .addrb(r2_adr[16:0]),  // input wire [16 : 0] addrb
  .dinb(r2_dati),    // input wire [7 : 0] dinb
  .doutb(r2_dato)  // output wire [7 : 0] doutb
);

assign c1_ack = r1_ack|nic1_ack;
assign c2_ack = r2_ack|nic2_ack;
assign c1_dati = r1_cdat|nic1_dato;
assign c2_dati = r2_cdat|nic2_dato;

rf6809 ucpu1
(
	.id({id,1'b0}),
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
	.aack_i(c1_aack|r1_aack),
	.atag_i(r1_aack?r1_adr[3:0]:c1_atag),
	.adr_o(c1_adr),
	.dat_i(c1_dati),
	.dat_o(c1_dato),
	.state()
);

rf6809 ucpu2
(
	.id({id,1'b1}),
	.rst_i(rst_i),
	.clk_i(clk_i),
	.halt_i(1'b0),
	.nmi_i(1'b0),
	.irq_i(c2_irq),
	.firq_i(c2_firq),
	.vec_i(36'h0),
	.ba_o(),
	.bs_o(),
	.lic_o(),
	.tsc_i(1'b0),
	.rty_i(c2_rty),
	.bte_o(),
	.cti_o(c2_cti),
	.bl_o(),
	.lock_o(),
	.cyc_o(c2_cyc),
	.stb_o(c2_stb),
	.we_o(c2_we),
	.ack_i(c2_ack),
	.aack_i(c2_aack|r2_aack),
	.atag_i(r2_aack?r2_adr[3:0]:c2_atag),
	.adr_o(c2_adr),
	.dat_i(c2_dati),
	.dat_o(c2_dato),
	.state()
);

assign pc1 = ucpu1.pc;
assign pc2 = ucpu2.pc;

endmodule
