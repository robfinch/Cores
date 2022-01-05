// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	nic.sv
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

import nic_pkg::*;

module nic(id, rst_i, clk_i,
	s_cyc_i, s_stb_i, s_ack_o, s_we_i, s_adr_i, s_dat_i, s_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_adr_o, m_dat_o, m_dat_i,
	packet_i, packet_o);
input [5:0] id;
input rst_i;
input clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input s_we_i;
input [23:0] s_adr_i;
input [7:0] s_dat_i;
output reg [7:0] s_dat_o;
output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [23:0] m_adr_o;
output reg [7:0] m_dat_o;
input [7:0] m_dat_i;
input Packet packet_i;
output Packet packet_o;

reg [5:0] state;
parameter ST_IDLE = 6'd0;
parameter ST_READ = 6'd1;
parameter ST_READ_ACK = 6'd2;
parameter ST_ACK = 6'd3;
parameter ST_ACK_ACK = 6'd4;
parameter ST_WRITE = 6'd5;
parameter ST_WRITE_ACK = 6'd6;

Packet packet_rx, packet_tx;

always_ff @(posedge clk_i)
begin
	// Transfer the packet around the ring on every clock cycle.
	packet_o <= packet_i;
	
	// Look for slave cycle termination.
	if (~(s_syc_i & s_stb_i))
		s_ack_o <= FALSE;

	case(state)
	ST_IDLE:
		begin
			// Was this packet for us?
			if (packet_i.did==id || packet_i.did==6'd63) begin
				packet_rx <= packet_i;
				case (packet_i.type)
				PT_ACK:
					begin
						state <= ST_ACK;
						packet_o.did <= 6'd0;
						packet_o.sid <= 6'd0;
						packet_o.age <= 6'd0;
						packet_o.type <= PT_NULL;
						// If we got an ACK packet the slot can be used for a write.
						tPrepWrite();
					end
				PT_READ:
					begin
						state <= ST_READ;
						packet_o.did <= 6'd0;
						packet_o.sid <= 6'd0;
						packet_o.age <= 6'd0;
						packet_o.type <= PT_NULL;
					end
				PT_WRITE:
					begin
						state <= ST_WRITE;
						packet_o.did <= 6'd0;
						packet_o.sid <= 6'd0;
						packet_o.age <= 6'd0;
						packet_o.type <= PT_NULL;
					end
				default:	;
				endcase
			end
			else begin
				tPrepWrite();
			end
		end

	ST_READ:
		begin
			m_cyc_o <= TRUE;
			m_stb_o <= TRUE;
			m_we_o <= FALSE;
			m_adr_o <= packet_rx.adr;
			state <= ST_READ_ACK;
		end
	ST_READ_ACK:
		if (m_ack_i) begin
			m_cyc_o <= FALSE;
			m_stb_o <= FALSE;
			m_we_o <= FALSE;
			packet_tx.sid <= id;
			packet_tx.did <= packet_rx.sid;
			packet_tx.age <= 6'd0;
			packet_tx.type <= PT_ACK;
			packet_tx.ack <= TRUE;
			packet_tx.dat <= m_dat_i;
			state <= ST_XMIT;
		end

	ST_WRITE:
		begin
			m_cyc_o <= TRUE;
			m_stb_o <= TRUE;
			m_we_o <= TRUE;
			m_adr_o <= packet_rx.adr;
			m_dat_o <= packet_rx.dat;
			state <= ST_WRITE_ACK;
		end
	ST_WRITE_ACK:
		if (m_ack_i) begin
			m_cyc_o <= FALSE;
			m_stb_o <= FALSE;
			m_we_o <= FALSE;
			state <= ST_IDLE;
		end


	// Wait	for an opening then transmit the packet.
	ST_XMIT:
		begin
			if ((packet_i.sid|packet_i.did)==6'd0)
				packet_o <= packet_tx;
			state <= ST_IDLE;
		end

	ST_ACK:
		begin
			// If there is an active read cycle
			if (s_cyc_i & s_stb_i & ~s_we_i) begin
				s_dat_o <= packet_rx.dat;
				s_ack_o <= TRUE;
				state <= ST_ACK_ACK;
			end
			else
				state <= ST_IDLE;
		end
	ST_ACK_ACK:
		// Wait for the slave cycle to finish.
		if (~(s_cyc_i & s_stb_i)) begin
			s_ack_o <= FALSE;
			state <= ST_IDLE;
		end
		
	default:
		state <= ST_IDLE;
	endcase
end

task tPrepWrite;
begin
	if (cyc_i & stb_i & we_i & adr_i[23] & ~ack_o) begin
		if (adr_i[23:20]==4'hE)
			packet_tx.did <= 6'd62;
		// Global broadcast
		else if (adr_i[23:12]==12'hDFF)
			packet_tx.did <= 6'd63;
		else if (adr_i[23:20]==4'hC)
			packet_tx.did <= adr_i[19:15];
		else
			packet_tx.did <= 6'd0;
		packet_tx.sid <= id;
		packet_tx.age <= 6'd0;
		packet_tx.ack <= 1'b0;
		packet_tx.type <= PT_WRITE;
		packet_tx.pad2 <= 2'b0;
		packet_tx.we <= TRUE;
		packet_tx.pad1 <= 4'h0;
		packet_tx.adr <= adr_i;
		packet_tx.dat <= dat_i;
		ack_o <= TRUE;
		state <= ST_XMIT;
	end
end
endtask

endmodule
