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

import rf6809_pkg::*;
import nic_pkg::*;

module nic(id, rst_i, clk_i, s_cti_i, s_atag_o,
	s_cyc_i, s_stb_i, s_ack_o, s_aack_o, s_rty_o, s_we_i, s_adr_i, s_dat_i, s_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_adr_o, m_dat_o, m_dat_i,
	packet_i, packet_o, ipacket_i, ipacket_o,
	rpacket_i, rpacket_o,
	irq_i, firq_i, cause_i, iserver_i, irq_o, firq_o, cause_o);
input [5:0] id;
input rst_i;
input clk_i;
input [2:0] s_cti_i;
output reg [3:0] s_atag_o;
input s_cyc_i;
input s_stb_i;
output reg s_ack_o;
output reg s_rty_o;
output reg s_aack_o;
input s_we_i;
input [23:0] s_adr_i;
input [`BYTE1] s_dat_i;
output reg [`BYTE1] s_dat_o;
output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [23:0] m_adr_o;
output reg [`BYTE1] m_dat_o;
input [`BYTE1] m_dat_i;
input Packet packet_i;
output Packet packet_o;
input Packet rpacket_i;
output Packet rpacket_o;

input IPacket ipacket_i;
output IPacket ipacket_o;
input irq_i;
input firq_i;
input [`BYTE1] cause_i;
input [5:0] iserver_i;
output reg irq_o;
output reg firq_o;
output reg [`BYTE1] cause_o;

reg [5:0] state;
parameter ST_IDLE = 6'd0;
parameter ST_READ = 6'd1;
parameter ST_READ_ACK = 6'd2;
parameter ST_ACK = 6'd3;
parameter ST_ACK_ACK = 6'd4;
parameter ST_WRITE = 6'd5;
parameter ST_WRITE_ACK = 6'd6;
parameter ST_XMIT = 6'd7;
parameter ST_AACK = 6'd8;
parameter ST_RETRY = 6'd9;

Packet packet_rx, packet_tx;
Packet rpacket_rx, rpacket_tx;
Packet [7:0] gbl_packets;
reg seen_gbl;
integer n,n1,n2;

always_comb
begin
	seen_gbl = FALSE;
	for (n = 0; n < 8; n = n + 1)
		if (gbl_packets[n]==packet_i)
			seen_gbl <= TRUE;
end

reg rcv;
reg wait_ack;
reg rw_done;
reg burst;
always_comb
	burst = s_cti_i==3'b001||s_cti_i==3'b111;

always_ff @(posedge clk_i)
if (rst_i) begin
	s_ack_o <= FALSE;
	s_aack_o <= FALSE;
	s_dat_o <= 12'h00;
	s_atag_o <= 4'h0;
	packet_o <= {$bits(Packet){1'b0}};
	rpacket_o <= {$bits(Packet){1'b0}};
	ipacket_o <= {$bits(IPacket){1'b0}};
	packet_rx <= {$bits(Packet){1'b0}};
	packet_tx <= {$bits(Packet){1'b0}};
	rpacket_rx <= {$bits(Packet){1'b0}};
	rpacket_tx <= {$bits(Packet){1'b0}};
	for (n2 = 0; n2 < 8; n2 = n2 + 1)
		gbl_packets[n] <= {$bits(Packet){1'b0}};
	rcv <= 1'b0;
	rw_done <= TRUE;
	wait_ack <= 1'b0;
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_adr_o <= 24'h0;
	m_dat_o <= 12'h00;
	state <= ST_IDLE;
end
else begin
	// This signal just pulses once.
	s_aack_o <= FALSE;

	// Transfer the packet around the ring on every clock cycle.
	packet_o <= packet_i;
	ipacket_o <= ipacket_i;
	rpacket_o <= rpacket_i;

	if ((packet_i.sid|packet_i.did)==6'd0) begin
		packet_o <= packet_tx;
		packet_tx <= {$bits(Packet){1'b0}};
	end
	if ((rpacket_i.sid|rpacket_i.did)==6'd0) begin
		rpacket_o <= rpacket_tx;
		rpacket_tx <= {$bits(Packet){1'b0}};
	end
	
	// Look for slave cycle termination.
	if (~(s_cyc_i & s_stb_i)) begin
		rw_done <= TRUE;
		s_ack_o <= FALSE;
		s_rty_o <= FALSE;
	end

	if (firq_i|irq_i) begin
		ipacket_o.sid = id;
		ipacket_o.did <= iserver_i;
		ipacket_o.age <= 6'd0;
		ipacket_o.firq <= firq_i;
		ipacket_o.irq <= irq_i;
		ipacket_o.cause <= cause_i;
	end
	if (ipacket_i.did==id || ipacket_i.did==6'd63) begin
		ipacket_o <= {$bits(IPacket){1'b0}};
		irq_o <= ipacket_i.irq;
		firq_o <= ipacket_i.firq;
		cause_o <= ipacket_i.cause;
	end

	case(state)
	ST_IDLE:
		begin
			if (rpacket_i.did==id || rpacket_i.did==6'd63) begin
				rpacket_rx <= rpacket_i;
				// Remove packet only if not a broadcast packet
				if (rpacket_i.did!=6'd63) begin
					case (rpacket_i.typ)
					PT_RETRY:
						begin
							rpacket_o <= {$bits(Packet){1'b0}};
							state <= ST_RETRY;
						end
					PT_ACK:
						begin
							rpacket_o <= {$bits(Packet){1'b0}};
							state <= ST_ACK;
						end
					PT_AACK:
						begin
							rpacket_o <= {$bits(Packet){1'b0}};
							state <= ST_AACK;
						end
					default:	;
					endcase
				end
			end
			// Was this packet for us?
			if (packet_i.did==id || packet_i.did==6'd63) begin
				packet_rx <= packet_i;
				// Remove packet only if not a broadcast packet
				if (packet_i.did!=6'd63) begin
					case (packet_i.typ)
					PT_READ,PT_AREAD:
						if (~|rpacket_tx) begin
							packet_o <= {$bits(Packet){1'b0}};
							state <= ST_READ;
						end
					PT_WRITE:	
						begin
							packet_o <= {$bits(Packet){1'b0}};
							state <= ST_WRITE;
						end
					default:	;
					endcase
				end
				// Have we seen packet already?
				// If not, add to seen list and process, otherwise ignore
				else if (!seen_gbl) begin
					for (n1 = 0; n1 < 7; n1 = n1 + 1)
						gbl_packets[n1+1] <= gbl_packets[n1];
					gbl_packets[0] <= packet_i;
					case (packet_i.typ)
					//PT_ACK:		state <= ST_ACK;
					//PT_READ:	state <= ST_READ;
					PT_WRITE:	state <= ST_WRITE;
					default:	;
					endcase
				end
			end
			// If previous op is complete, and theres nothing in the transmit buffer.
			else if (rw_done && ~|packet_tx) begin
				tPrepReadWrite();
			end
		end

	ST_READ:
		if (!m_ack_i) begin
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
			rpacket_tx <= {$bits(Packet){1'b0}};
			rpacket_tx.sid <= id;
			rpacket_tx.did <= packet_rx.sid;
			rpacket_tx.age <= 6'd0;
			rpacket_tx.typ <= packet_rx.typ==PT_AREAD ? PT_AACK : PT_ACK;
			rpacket_tx.ack <= TRUE;
			rpacket_tx.adr <= m_adr_o;
			rpacket_tx.dat <= m_dat_i;
			state <= ST_IDLE;
		end

	ST_WRITE:
		if (!m_ack_i) begin
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

	ST_ACK:
		// If there is an active read cycle
		if (s_cyc_i & s_stb_i & ~s_we_i) begin
			if (s_adr_i == rpacket_rx.adr) begin
				s_dat_o <= rpacket_rx.dat;
				s_ack_o <= TRUE;
				state <= ST_ACK_ACK;
			end
			else begin
				s_rty_o <= TRUE;
				state <= ST_IDLE;
			end
		end
		else
			state <= ST_IDLE;
	ST_ACK_ACK:
		// Wait for the slave cycle to finish.
		if (~(s_cyc_i & s_stb_i))
			state <= ST_IDLE;
	ST_RETRY:
		begin
			s_rty_o <= TRUE;
			s_atag_o <= rpacket_rx.adr[3:0];
			state <= ST_IDLE;
		end
		
	// Asynchronous acknowledge; there does not need to be an active slave cycle.
	// It is assumed the slave is waiting for the response.
	ST_AACK:
		begin
			s_aack_o <= TRUE;
			s_atag_o <= rpacket_rx.adr[3:0];
			s_dat_o <= rpacket_rx.dat;
			state <= ST_IDLE;
		end

	default:
		state <= ST_IDLE;
	endcase

end

task tPrepReadWrite;
begin
	if (s_cyc_i && s_stb_i) begin
		rw_done <= FALSE;
		packet_tx.sid <= id;
		packet_tx.age <= 6'd0;
		packet_tx.ack <= 1'b0;
		packet_tx.typ <= s_we_i ? PT_WRITE : burst ? PT_AREAD : PT_READ;
		packet_tx.pad2 <= 2'b0;
		packet_tx.we <= s_we_i;
		packet_tx.adr <= s_adr_i;
		packet_tx.dat <= s_dat_i;
		casez(s_adr_i[23:16])
		// Read global ROM?
		8'hF?:	
			if (!s_we_i) begin
				packet_tx.did <= 6'd62;
				s_ack_o <= burst;
				rw_done <= burst;
			end
			else begin
				packet_tx <= {$bits(Packet){1'b0}};
				rw_done <= TRUE;
				s_ack_o <= TRUE;
			end
		8'hE?:
			begin
				packet_tx.did <= 6'd62;
				s_ack_o <= s_we_i | burst;
			end
		// Global broadcast
		8'hDF:
			begin
				packet_tx.did <= 6'd63;
				packet_tx.age <= 6'd30;
				s_ack_o <= s_we_i | burst;
			end
		8'hC?:
			begin
				packet_tx.did <= {2'd0,s_adr_i[19:16]}+2'd2;
				s_ack_o <= s_we_i | burst;
			end
		8'h4?,8'h5?,8'h6?,8'h7?,8'h8?,8'h9?,8'hA?,8'hB?:
			begin
				packet_tx.did <= 6'd62;
				s_ack_o <= s_we_i | burst;
			end
		default:
			begin
				packet_tx <= {$bits(Packet){1'b0}};
				rw_done <= TRUE;
			end
		endcase
	end
end
endtask

endmodule
