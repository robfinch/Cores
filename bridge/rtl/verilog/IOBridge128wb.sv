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
// IOBridge128wb.v
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
import fta_bus_pkg::*;

module IOBridge128wb(rst_i, clk_i, 
	s1_req, s1_resp, s2_req, s2_resp,
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
input fta_cmd_request128_t s1_req;
output fta_cmd_response128_t s1_resp;
input fta_cmd_request128_t s2_req;
output fta_cmd_response128_t s2_resp;
/*
output fta_cmd_request64_t m_req;
input fta_cmd_response64_t ch0resp;
input fta_cmd_response64_t ch1resp;
*/
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

integer nn;
reg which;
reg [2:0] state;
reg s_ack;
always @(posedge clk_i)
if (rst_i)
	s1_resp.ack <= 1'b0;
else
	s1_resp.ack <= ASYNCH ? (s_ack & ~which) : (s_ack & s1_req.stb & ~which);
always @(posedge clk_i)
if (rst_i)
	s2_resp.ack <= 1'b0;
else
	s2_resp.ack <= ASYNCH ? (s_ack & which) : (s_ack & s2_req.stb &  which);

wire m_ack_i = m32_ack_i|m64_ack_i;

reg [7:0] tid1, tid2;
reg [3:0] cid1, cid2;
reg [31:0] adr1, adr2;

// Create low order four address lines.
reg [3:0] s1_a30, s2_a30;
/*
fta_cmd_response64_t [1:0] resps;
fta_cmd_response64_t respo;
assign resps[0] = ch0resp;
assign resps[1] = ch1resp;

fta_respbuf urespb1
(
	.rst(rst_i),
	.clk(clk_i),
	.resp(resps),
	.resp_o(respo)
);
*/
always_comb
	case(s1_req.sel)
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
	case(s2_req.sel)
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
	s1_resp.dat <= 'd0;
	s2_resp.dat <= 'd0;
	s1_resp.cid <= 'd0;
	s1_resp.tid <= 'd0;
	s2_resp.cid <= 'd0;
	s2_resp.tid <= 'd0;
	s1_resp.adr <= 'd0;
	s2_resp.adr <= 'd0;
	s1_resp.stall <= 'd0;
	s1_resp.next <= 'd0;
	s1_resp.err <= 'd0;
	s1_resp.rty <= 'd0;
	s2_resp.stall <= 'd0;
	s2_resp.next <= 'd0;
	s2_resp.err <= 'd0;
	s2_resp.rty <= 'd0;
	s1_resp.pri <= 4'd7;
	s2_resp.pri <= 4'd7;
	state <= IDLE;
end
else begin
case(state)
IDLE:
	begin
	  if (~m_ack_i) begin
	    // Filter requests to the I/O address range
	    if (s1_req.cyc) begin
	    	cid1 <= s1_req.cid;
	    	tid1 <= s1_req.tid;
	    	adr1 <= s1_req.padr;
	    	which <= 1'b0;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      m32_sel_o <= s1_req.sel[15:12]|s1_req.sel[11:8]|s1_req.sel[7:4]|s1_req.sel[3:0];
	      m64_sel_o <= s1_req.sel[15:8]|s1_req.sel[7:0];
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      cid1 <= s1_req.cid;
	      tid1 <= s1_req.tid;
	      m_adr_o <= s1_req.padr;
`ifdef ACK_WR
	      if (s1_req.we) begin
	      	s_ack <= 1'b1;
			    m_we_o <= 1'b1;
			    m_req.we <= 1'b1;
			    state <= WR_ACK;
	    	end
	    	else
`endif    	
	    	begin
	      	s_ack <= 1'b0;
			    m_we_o <= s1_req.we;
	      	if (!ASYNCH)
	      		state <= WAIT_ACK;
	    	end
		    m_adr_o <= s1_req.padr;
	    end
	    else if (s2_req.cyc) begin
	    	cid2 <= s2_req.cid;
	    	tid2 <= s2_req.tid;
	    	adr2 <= s2_req.padr;
	    	which <= 1'b1;
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      m32_sel_o <= s2_req.sel[15:12]|s2_req.sel[11:8]|s2_req.sel[7:4]|s2_req.sel[3:0];
	      m64_sel_o <= s2_req.sel[15:8]|s2_req.sel[7:0];
	      m_cyc_o <= 1'b1;
	      m_stb_o <= 1'b1;
	      cid2 <= s2_req.cid;
	      tid2 <= s2_req.tid;
	      m_adr_o <= s2_req.padr;
`ifdef ACK_WR
	      if (s2_req.we) begin
	      	s_ack <= 1'b1;
			    m_we_o <= 1'b1;
			    m_req.we <= 1'b1;
			    state <= WR_ACK;
	    	end
	    	else 
`endif    	
	    	begin
	      	s_ack <= 1'b0;
			    m_we_o <= s2_req.we;
			    if (!ASYNCH)
	      		state <= WAIT_ACK;
	    	end
		    m_adr_o <= s2_req.padr;	// fix the upper 12 bits of the address to help trim cores
	    end
	    else begin
	    	m_cyc_o <= 1'b0;
	    	m_stb_o <= 1'b0;
	    	m_we_o <= 1'b0;
	    	m32_sel_o <= 'h0;
	    	m64_sel_o <= 'h0;
	    	m_adr_o <= 32'hFFFFFFFF;
	  	end
	    if (s1_req.cyc) begin
				m32_dat_o <= s1_req.data1 >> {s1_a30[3:2],5'd0};
				m64_dat_o <= s1_req.data1 >> {s1_a30[3],6'd0};
	  	end
	    else if (s2_req.cyc) begin
				m32_dat_o <= s2_req.data1 >> {s2_a30[3:2],5'd0};
				m64_dat_o <= s2_req.data1 >> {s2_a30[3],6'd0};
	    end
	  	else begin
	  		m32_dat_o <= 'd0;
	  		m64_dat_o <= 'd0;
	  	end
		end
	end
WR_ACK:
	begin
		if (!s2_req.stb && !s1_req.stb)
			s_ack <= 1'b0;
		if ( which & !s2_req.stb)
			s_ack <= 1'b0;
		if (!which & !s1_req.stb)
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
		if (!s2_req.stb && !s1_req.stb) begin
			s_ack <= 1'b0;
			state <= IDLE;
		end
		if ( which & !s2_req.stb) begin
			s_ack <= 1'b0;
			state <= IDLE;
		end
		if (!which & !s1_req.stb) begin
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
		 		s1_resp.dat <= {4{m32_dat_i}};
		 	else
		 		s1_resp.dat <= {2{m64_dat_i}};
			s1_resp.tid <= tid1;
			s1_resp.cid <= cid1;
			s1_resp.adr <= adr1;
		end
		if (which) begin
			if (m32_ack_i)
				s2_resp.dat <= {4{m32_dat_i}};
			else
				s2_resp.dat <= {2{m64_dat_i}};
			s2_resp.tid <= tid2;
			s2_resp.cid <= cid2;
			s2_resp.adr <= adr2;
		end
		state <= WAIT_NACK;
	end
	else if (!s2_req.cyc && !s1_req.cyc) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		state <= IDLE;
	end
	else if (which ? !s2_req.cyc : !s1_req.cyc) begin
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
	if (!s2_req.stb && !s1_req.stb) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		s_ack <= 1'b0;
		s1_resp.dat <= 'h0;
		s2_resp.dat <= 'h0;
		s1_resp.cid <= 'd0;
		s1_resp.tid <= 'd0;
		s2_resp.cid <= 'd0;
		s2_resp.tid <= 'd0;
		s1_resp.adr <= 'd0;
		s2_resp.adr <= 'd0;
		state <= IDLE;
	end
	else if (which ? !s2_req.stb : !s1_req.stb) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
		s_ack <= 1'b0;
		if (!s1_req.stb) begin
			s1_resp.dat <= 'h0;
			s1_resp.cid <= 'd0;
			s1_resp.tid <= 'd0;
			s1_resp.adr <= 'd0;
		end
		if (!s2_req.stb) begin
			s2_resp.dat <= 'h0;
			s2_resp.cid <= 'd0;
			s2_resp.tid <= 'd0;
			s2_resp.adr <= 'd0;
		end
		state <= IDLE;
	end
default:	state <= IDLE;
endcase
	if (ASYNCH) begin
		/*
		s1_resp.ack <= respo.ack;
		s1_resp.err <= respo.err;
		s1_resp.rty <= respo.rty;
		s1_resp.next <= respo.next;
		s1_resp.stall <= respo.stall;
		s1_resp.dat <= {2{respo.dat}};
		s1_resp.cid <= respo.cid;
		s1_resp.tid <= respo.tid;
		s1_resp.adr <= respo.adr;
		s1_resp.pri <= respo.pri;
		*/
		
		s_ack <= m_ack_i;
		if (m_ack_i) begin
			if (which) begin
				s2_resp.tid <= tid2;
				s2_resp.cid <= cid2;
				s2_resp.adr <= adr2;
			end
			else begin
				s1_resp.tid <= tid1;
				s1_resp.cid <= cid1;
				s1_resp.adr <= adr1;
			end
			if (m32_ack_i) begin
				if (which)
					s2_resp.dat <= {4{m32_dat_i}};
				else
					s1_resp.dat <= {4{m32_dat_i}};
			end
			else begin
				if (which)
					s2_resp.dat <= {2{m64_dat_i}};
				else
					s1_resp.dat <= {2{m64_dat_i}};
			end
		end
		else begin
			s1_resp.dat <= 'd0;
			s2_resp.dat <= 'd0;
		end	
		
	end
end

endmodule

