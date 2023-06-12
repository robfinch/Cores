`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2023  Robert Finch, Waterloo
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
// IOBridge128.v
//
// Adds FF's into the io path. This makes it easier for the place and
// route to take place. 
// Multiple devices are connected to the master port side of the bridge.
// The slave side of the bridge is connected to the cpu. The bridge looks
// like just a single device then to the cpu.
// The cost is an extra clock cycle to perform I/O accesses. For most
// devices which are low-speed it doesn't matter much.
//
// 401 LUTs / 276 FFs              
// ============================================================================
//

module IOBridge128(rst_i, clk_i, s1_cid, s1_tid, s2_cid, s2_tid,
	s1_cido, s1_tido, s2_cido, s2_tido,
	s1_cyc_i, s1_stb_i, s1_ack_o, s1_we_i, s1_sel_i, s1_adr_i, s1_dat_i, s1_dat_o,
	s2_cyc_i, s2_stb_i, s2_ack_o, s2_we_i, s2_sel_i, s2_adr_i, s2_dat_i, s2_dat_o,
	m_cyc_o, m_stb_o, m32_ack_i, m_we_o, m32_sel_o, m_adr_o, m32_dat_i, m32_dat_o,
	m64_ack_i, m64_sel_o, m64_dat_i, m64_dat_o);
parameter IDLE = 3'd0;
parameter WAIT_ACK = 3'd1;
parameter WAIT_NACK = 3'd2;
parameter WR_ACK = 3'd3;
parameter WR_ACK2 = 3'd4;
parameter ASYNCH = 1'b1;

input rst_i;
input clk_i;
input [3:0] s1_cid;
input [7:0] s1_tid;
input s1_cyc_i;
input s1_stb_i;
output reg s1_ack_o;
input s1_we_i;
input [15:0] s1_sel_i;
input [31:0] s1_adr_i;
input [127:0] s1_dat_i;
output reg [127:0] s1_dat_o;
output reg [3:0] s1_cido;
output reg [7:0] s1_tido;

input [3:0] s2_cid;
input [7:0] s2_tid;
input s2_cyc_i;
input s2_stb_i;
output reg s2_ack_o;
input s2_we_i;
input [15:0] s2_sel_i;
input [31:0] s2_adr_i;
input [127:0] s2_dat_i;
output reg [127:0] s2_dat_o;
output reg [3:0] s2_cido;
output reg [7:0] s2_tido;

output reg m_cyc_o;
output reg m_stb_o;
input m32_ack_i;
input m64_ack_i;
output reg m_we_o;
output reg [3:0] m32_sel_o;
output reg [7:0] m64_sel_o;
output reg [31:0] m_adr_o;
input [31:0] m32_dat_i;
output reg [31:0] m32_dat_o;
input [63:0] m64_dat_i;
output reg [63:0] m64_dat_o;

reg which;
reg [2:0] state;
reg s_ack;
always @(posedge clk_i)
if (rst_i)
	s1_ack_o <= 1'b0;
else
	s1_ack_o <= ASYNCH ? (s_ack & ~which) : (s_ack & s1_stb_i & ~which);
always @(posedge clk_i)
if (rst_i)
	s2_ack_o <= 1'b0;
else
	s2_ack_o <= ASYNCH ? (s_ack & which) : (s_ack & s2_stb_i &  which);

wire m_ack_i = m32_ack_i|m64_ack_i;

reg [7:0] tid1, tid2;
reg [3:0] cid1, cid2;

// Create low order four address lines.
reg [3:0] s1_a30, s2_a30;

always_comb
	case(s1_sel_i)
	16'h0001:	s1_a30 = 4'h0;
	16'h0002:	s1_a30 = 4'h1;
	16'h0004:	s1_a30 = 4'h2;
	16'h0008:	s1_a30 = 4'h3;
	16'h0010:	s1_a30 = 4'h4;
	16'h0020:	s1_a30 = 4'h5;
	16'h0040:	s1_a30 = 4'h6;
	16'h0080:	s1_a30 = 4'h7;
	16'h0100:	s1_a30 = 4'h8;
	16'h0200:	s1_a30 = 4'h9;
	16'h0400:	s1_a30 = 4'hA;
	16'h0800:	s1_a30 = 4'hB;
	16'h1000:	s1_a30 = 4'hC;
	16'h2000:	s1_a30 = 4'hD;
	16'h4000:	s1_a30 = 4'hE;
	16'h8000:	s1_a30 = 4'hF;
	16'h0003:	s1_a30 = 4'h0;
	16'h000C:	s1_a30 = 4'h2;
	16'h0030:	s1_a30 = 4'h4;
	16'h00C0:	s1_a30 = 4'h6;
	16'h0300:	s1_a30 = 4'h8;
	16'h0C00:	s1_a30 = 4'hA;
	16'h3000:	s1_a30 = 4'hC;
	16'hC000:	s1_a30 = 4'hE;
	16'h00FF:	s1_a30 = 4'h0;
	16'hFF00:	s1_a30 = 4'h8;
	16'hFFFF:	s1_a30 = 4'h0;
	default:	s1_a30 = 4'h0;
	endcase
always_comb
	case(s2_sel_i)
	16'h0001:	s2_a30 = 4'h0;
	16'h0002:	s2_a30 = 4'h1;
	16'h0004:	s2_a30 = 4'h2;
	16'h0008:	s2_a30 = 4'h3;
	16'h0010:	s2_a30 = 4'h4;
	16'h0020:	s2_a30 = 4'h5;
	16'h0040:	s2_a30 = 4'h6;
	16'h0080:	s2_a30 = 4'h7;
	16'h0100:	s2_a30 = 4'h8;
	16'h0200:	s2_a30 = 4'h9;
	16'h0400:	s2_a30 = 4'hA;
	16'h0800:	s2_a30 = 4'hB;
	16'h1000:	s2_a30 = 4'hC;
	16'h2000:	s2_a30 = 4'hD;
	16'h4000:	s2_a30 = 4'hE;
	16'h8000:	s2_a30 = 4'hF;
	16'h0003:	s2_a30 = 4'h0;
	16'h000C:	s2_a30 = 4'h2;
	16'h0030:	s2_a30 = 4'h4;
	16'h00C0:	s2_a30 = 4'h6;
	16'h0300:	s2_a30 = 4'h8;
	16'h0C00:	s2_a30 = 4'hA;
	16'h3000:	s2_a30 = 4'hC;
	16'hC000:	s2_a30 = 4'hE;
	16'h00FF:	s2_a30 = 4'h0;
	16'hFF00:	s2_a30 = 4'h8;
	16'hFFFF:	s2_a30 = 4'h0;
	default:	s2_a30 = 4'h0;
	endcase

always @(posedge clk_i)
if (rst_i) begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m32_sel_o <= 'd0;
	m64_sel_o <= 'd0;
	m_adr_o <= 'd0;
	m32_dat_o <= 'd0;
	m64_dat_o <= 'd0;
	s_ack <= 1'b0;
	s1_dat_o <= 'd0;
	s2_dat_o <= 'd0;
	s1_cido <= 'd0;
	s1_tido <= 'd0;
	s2_cido <= 'd0;
	s2_tido <= 'd0;
	state <= IDLE;
end
else begin
case(state)
IDLE:
	begin
	  if (~m_ack_i) begin
	    // Filter requests to the I/O address range
	    if (s1_cyc_i) begin
	    	cid1 <= s1_cid;
	    	tid1 <= s1_tid;
	    	which <= 1'b0;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      m32_sel_o <= s1_sel_i[15:12]|s1_sel_i[11:8]|s1_sel_i[7:4]|s1_sel_i[3:0];
	      m64_sel_o <= s1_sel_i[15:8]|s1_sel_i[7:0];
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
	      	if (!ASYNCH)
	      		state <= WAIT_ACK;
	    	end
		    m_adr_o <= s1_adr_i;
	    end
	    else if (s2_cyc_i) begin
	    	cid2 <= s2_cid;
	    	tid2 <= s2_tid;
	    	which <= 1'b1;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      m32_sel_o <= s2_sel_i[15:12]|s2_sel_i[11:8]|s2_sel_i[7:4]|s2_sel_i[3:0];
	      m64_sel_o <= s2_sel_i[15:8]|s2_sel_i[7:0];
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
			    if (!ASYNCH)
	      		state <= WAIT_ACK;
	    	end
		    m_adr_o <= s2_adr_i;	// fix the upper 12 bits of the address to help trim cores
	    end
	    else begin
	    	m_cyc_o <= 1'b0;
	    	m_stb_o <= 1'b0;
	    	m_we_o <= 1'b0;
	    	m32_sel_o <= 'h0;
	    	m64_sel_o <= 'h0;
	    	m_adr_o <= 32'hFFFFFFFF;
	  	end
	    if (s1_cyc_i) begin
				m32_dat_o <= s1_dat_i >> {s1_a30[3:2],5'd0};
				m64_dat_o <= s1_dat_i >> {s1_a30[3],6'd0};
	  	end
	    else if (s2_cyc_i) begin
				m32_dat_o <= s2_dat_i >> {s2_a30[3:2],5'd0};
				m64_dat_o <= s2_dat_i >> {s2_a30[3],6'd0};
	    end
	  	else begin
	  		m32_dat_o <= 'd0;
	  		m64_dat_o <= 'd0;
	  	end
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
		if (!which) begin
			if (m32_ack_i)
		 		s1_dat_o <= {4{m32_dat_i}};
		 	else
		 		s1_dat_o <= {2{m64_dat_i}};
			s1_tido <= tid1;
			s1_cido <= cid1;
		end
		if (which) begin
			if (m32_ack_i)
				s2_dat_o <= {4{m32_dat_i}};
			else
				s2_dat_o <= {2{m64_dat_i}};
			s2_tido <= tid2;
			s2_cido <= cid2;
		end
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
		s1_dat_o <= 'h0;
		s2_dat_o <= 'h0;
		s1_cido <= 'd0;
		s1_tido <= 'd0;
		s2_cido <= 'd0;
		s2_tido <= 'd0;
		state <= IDLE;
	end
	else if (which ? !s2_stb_i : !s1_stb_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		s_ack <= 1'b0;
		if (!s1_stb_i) begin
			s1_dat_o <= 'h0;
			s1_cido <= 'd0;
			s1_tido <= 'd0;
		end
		if (!s2_stb_i) begin
			s2_dat_o <= 'h0;
			s2_cido <= 'd0;
			s2_tido <= 'd0;
		end
		state <= IDLE;
	end
default:	state <= IDLE;
endcase
	if (ASYNCH) begin
		s_ack <= m_ack_i;
		if (m_ack_i) begin
			if (which) begin
				s2_tido <= tid2;
				s2_cido <= cid2;
			end
			else begin
				s1_tido <= tid1;
				s1_cido <= cid1;
			end
			if (m32_ack_i) begin
				if (which)
					s2_dat_o <= {4{m32_dat_i}};
				else
					s1_dat_o <= {4{m32_dat_i}};
			end
			else begin
				if (which)
					s2_dat_o <= {2{m64_dat_i}};
				else
					s1_dat_o <= {2{m64_dat_i}};
			end
		end
		else begin
			s1_dat_o <= 'd0;
			s2_dat_o <= 'd0;
		end	
	end
end

endmodule

