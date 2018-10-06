// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
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
module IOBridge(rst_i, clk_i,
	s1_cyc_i, s1_stb_i, s1_ack_o, s1_sel_i, s1_we_i, s1_adr_i, s1_dat_i, s1_dat_o,
	s2_cyc_i, s2_stb_i, s2_ack_o, s2_sel_i, s2_we_i, s2_adr_i, s2_dat_i, s2_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o,
	m_sel32_o, m_adr32_o, m_dat32_o);
parameter IDLE = 2'd0;
parameter WAIT_ACK = 2'd1;
parameter WAIT_NACK = 2'd2;

input rst_i;
input clk_i;
input s1_cyc_i;
input s1_stb_i;
output reg s1_ack_o;
input [7:0] s1_sel_i;
input s1_we_i;
input [31:0] s1_adr_i;
input [63:0] s1_dat_i;
output reg [63:0] s1_dat_o;

input s2_cyc_i;
input s2_stb_i;
output reg s2_ack_o;
input [7:0] s2_sel_i;
input s2_we_i;
input [31:0] s2_adr_i;
input [63:0] s2_dat_i;
output reg [63:0] s2_dat_o;

output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [7:0] m_sel_o;
output reg [31:0] m_adr_o;
input [63:0] m_dat_i;
output reg [63:0] m_dat_o;
output reg [3:0] m_sel32_o;
output reg [31:0] m_adr32_o;
output reg [31:0] m_dat32_o;

reg which;
reg [1:0] state;
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
reg [63:0] dat1;
wire a10 = s1_sel_i[1]|s1_sel_i[3]|s1_sel_i[5]|s1_sel_i[7];
wire a11 = |s1_sel_i[3:2]| |s1_sel_i[7:6];
wire a12 = |s1_sel_i[7:4];
wire a20 = s2_sel_i[1]|s2_sel_i[3]|s2_sel_i[5]|s2_sel_i[7];
wire a21 = |s2_sel_i[3:2]| |s2_sel_i[7:6];
wire a22 = |s2_sel_i[7:4];

always @(posedge clk_i)
if (rst_i) begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_sel_o <= 4'h0;
	m_adr_o <= 32'd0;
	m_dat_o <= 32'd0;
	m_adr32_o <= 32'd0;
	m_dat32_o <= 32'd0;
	m_sel32_o <= 4'h0;
	s_ack <= 1'b0;
	dat1 <= 32'd0;
	state <= IDLE;
end
else begin
case(state)
IDLE:
  if (~m_ack_i) begin
    // Filter requests to the I/O address range
    if (s1_cyc_i && s1_adr_i[31:20]==12'hFFD) begin
    	which <= 1'b0;
      m_cyc_o <= 1'b1;
      m_stb_o <= 1'b1;
      state <= WAIT_ACK;
	    m_sel_o <= s1_sel_i;
	    m_we_o <= s1_we_i;
	    m_adr_o <= {12'hFFD,s1_adr_i[19:0]};	// fix the upper 12 bits of the address to help trim cores
	    m_dat_o <= s1_dat_i;
	    m_sel32_o <= s1_sel_i[7:4]|s1_sel_i[3:0];
	    m_adr32_o <= {s1_adr_i[31:3],a12,a11,a10};
	    m_dat32_o <= a12 ? s1_dat_i[63:0] : s1_dat_i[31:0];
    end
    else if (s2_cyc_i && s2_adr_i[31:20]==12'hFFD) begin
    	which <= 1'b1;
      m_cyc_o <= 1'b1;
      m_stb_o <= 1'b1;
      state <= WAIT_ACK;
	    m_sel_o <= s2_sel_i;
	    m_we_o <= s2_we_i;
	    m_adr_o <= {12'hFFD,s2_adr_i[19:0]};	// fix the upper 12 bits of the address to help trim cores
	    m_dat_o <= s2_dat_i;
	    m_sel32_o <= s2_sel_i[7:4]|s2_sel_i[3:0];
	    m_adr32_o <= {s2_adr_i[31:3],a22,a21,a20};
	    m_dat32_o <= a22 ? s1_dat_i[63:0] : s2_dat_i[31:0];
    end
	end
WAIT_ACK:
	if (m_ack_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
//		m_sel_o <= 4'h0;
//		m_adr_o <= 32'h0;
//		m_dat_o <= 32'd0;
		s_ack <= 1'b1;
		dat1 <= m_dat_i;
		state <= WAIT_NACK;
	end
	else if (which ? !s2_cyc_i : !s1_cyc_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
//		m_sel_o <= 4'h0;
//		m_adr_o <= 32'h0;
//		m_dat_o <= 32'd0;
		s_ack <= 1'b0;
		state <= IDLE;
	end
WAIT_NACK:
	if (which ? !s2_stb_i : !s1_stb_i) begin
		s_ack <= 1'b0;
		dat1 <= 64'h0;
		state <= IDLE;
	end
default:	state <= IDLE;
endcase
end

always @(posedge clk_i)
	s1_dat_o <= dat1;
always @(posedge clk_i)
	s2_dat_o <= dat1;

endmodule

