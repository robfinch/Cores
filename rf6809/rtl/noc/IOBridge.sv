// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
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
// IOBridge.v
//
// Adds FF's into the io path. This makes it easier for the place and
// route to take place. This module also filters requests to the I/O
// memory range, and hopefully reduces the cost of comparators in I/O
// modules that have internal decoding.
// Multiple devices are connected to the master port side of the bridge.
// The slave side of the bridge is connected to the cpu. The bridge looks
// like just a single device then to the cpu.
// The cost is an extra clock cycle to perform I/O accesses. For most
// devices which are low-speed it doesn't matter much.              
// ============================================================================
//
//`define ACK_WR	1'b1

module IOBridge(rst_i, clk_i,
	s1_cyc_i, s1_stb_i, s1_ack_o, s1_we_i, s1_adr_i, s1_dat_i, s1_dat_o,
	s2_cyc_i, s2_stb_i, s2_ack_o, s2_we_i, s2_adr_i, s2_dat_i, s2_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_adr_o, m_dat_i, m_dat_o);
parameter IDLE = 3'd0;
parameter WAIT_ACK = 3'd1;
parameter WAIT_NACK = 3'd2;
parameter WR_ACK = 3'd3;
parameter WR_ACK2 = 3'd4;

input rst_i;
input clk_i;
input s1_cyc_i;
input s1_stb_i;
output reg s1_ack_o;
input s1_we_i;
input [23:0] s1_adr_i;
input [7:0] s1_dat_i;
output reg [7:0] s1_dat_o;

input s2_cyc_i;
input s2_stb_i;
output reg s2_ack_o;
input s2_we_i;
input [23:0] s2_adr_i;
input [7:0] s2_dat_i;
output reg [7:0] s2_dat_o;

output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [23:0] m_adr_o;
input [7:0] m_dat_i;
output reg [7:0] m_dat_o;

reg which;
reg [2:0] state;
reg s_ack;
always @(posedge clk_i)
if (rst_i)
	s1_ack_o <= 1'b0;
else
	s1_ack_o <= s_ack & s1_stb_i & ~which;
always @(posedge clk_i)
if (rst_i)
	s2_ack_o <= 1'b0;
else
	s2_ack_o <= s_ack & s2_stb_i &  which;

always @(posedge clk_i)
if (rst_i) begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_adr_o <= 24'd0;
	m_dat_o <= 8'd0;
	s_ack <= 1'b0;
	s1_dat_o <= 8'd0;
	s2_dat_o <= 8'd0;
	state <= IDLE;
end
else begin
case(state)
IDLE:
	begin
	  if (~m_ack_i) begin
	    // Filter requests to the I/O address range
	    if (s1_cyc_i && s1_adr_i[23:20]==4'hE) begin
	    	which <= 1'b0;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
`ifdef ACK_WR
	      if (s1_we_i) begin
	      	s_ack <= 1'b1;
			    m_we_o <= 1'b1;
			    state <= WR_ACK;
	    	end
	    	else
`endif    	
	    	begin
	      	s_ack <= 1'b0;
			    m_we_o <= s1_we_i;
	      	state <= WAIT_ACK;
	    	end
		    m_adr_o <= {4'hE,s1_adr_i[19:0]};
	    end
	    else if (s2_cyc_i && s2_adr_i[23:20]==4'hE) begin
	    	which <= 1'b1;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
`ifdef ACK_WR
	      if (s2_we_i) begin
	      	s_ack <= 1'b1;
			    m_we_o <= 1'b1;
			    state <= WR_ACK;
	    	end
	    	else 
`endif    	
	    	begin
	      	s_ack <= 1'b0;
			    m_we_o <= s2_we_i;
	      	state <= WAIT_ACK;
	    	end
		    m_adr_o <= {4'hE,s2_adr_i[19:0]};	// fix the upper 12 bits of the address to help trim cores
	    end
	    else begin
	    	m_cyc_o <= 1'b0;
	    	m_stb_o <= 1'b0;
	    	m_we_o <= 1'b0;
	    	m_adr_o <= 24'hFFFFFF;
	  	end
	    if (s1_cyc_i && s1_adr_i[23:20]==4'hE) begin
				m_dat_o <= s1_dat_i;
	  	end
	    else if (s2_cyc_i && s2_adr_i[23:20]==4'hE) begin
				m_dat_o <= s2_dat_i;
	    end
	  	else
	  		m_dat_o <= 8'd0;
		end
	end
WR_ACK:
	begin
		if (!s2_stb_i && !s1_stb_i)
			s_ack <= 1'b0;
		if ( which & !s2_stb_i)
			s_ack <= 1'b0;
		if (!which & !s1_stb_i)
			s_ack <= 1'b0;
		if (m_ack_i) begin
			m_cyc_o <= 1'b0;
			m_stb_o <= 1'b0;
			m_we_o <= 1'b0;
//			m_sel_o <= 8'h00;
			if (!s_ack)
				state <= IDLE;
			else
				state <= WR_ACK2;
		end
	end
WR_ACK2:
	begin
		if (!s2_stb_i && !s1_stb_i) begin
			s_ack <= 1'b0;
			state <= IDLE;
		end
		if ( which & !s2_stb_i) begin
			s_ack <= 1'b0;
			state <= IDLE;
		end
		if (!which & !s1_stb_i) begin
			s_ack <= 1'b0;
			state <= IDLE;
		end
	end

// Wait for rising edge on m_ack_i or cycle abort
WAIT_ACK:
	if (m_ack_i) begin
//		m_sel_o <= 4'h0;
//		m_adr_o <= 32'h0;
//		m_dat_o <= 32'd0;
		s_ack <= 1'b1;
		if (!which) s1_dat_o <= m_dat_i;
		if ( which) s2_dat_o <= m_dat_i;
		state <= WAIT_NACK;
	end
	else if (!s2_cyc_i && !s1_cyc_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		state <= IDLE;
	end
	else if (which ? !s2_cyc_i : !s1_cyc_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
//			m_sel_o <= 8'h00;
//		m_adr_o <= 32'h0;
//		m_dat_o <= 32'd0;
		state <= IDLE;
	end

// Wait for falling edge on strobe or strobe low.
WAIT_NACK:
	if (!s2_stb_i && !s1_stb_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		s_ack <= 1'b0;
		s1_dat_o <= 8'h0;
		s2_dat_o <= 8'h0;
		state <= IDLE;
	end
	else if (which ? !s2_stb_i : !s1_stb_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		s_ack <= 1'b0;
		if (!s1_stb_i)
			s1_dat_o <= 8'h0;
		if (!s2_stb_i)
			s2_dat_o <= 8'h0;
		state <= IDLE;
	end
default:	state <= IDLE;
endcase
end

endmodule

