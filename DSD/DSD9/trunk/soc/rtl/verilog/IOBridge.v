// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2017  Robert Finch, Waterloo
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
module IOBridge(rst_i, clk_i, s_cyc_i, s_stb_i, s_ack_o, s_sel_i, s_we_i, s_adr_i, s_dat_i, s_dat_o,
	m_cyc_o, m_stb_o, m_ack_i, m_we_o, m_sel_o, m_adr_o, m_dat_i, m_dat_o);
parameter IDLE = 2'd0;
parameter WAIT_ACK = 2'd1;
parameter WAIT_NACK = 2'd2;

input rst_i;
input clk_i;
input s_cyc_i;
input s_stb_i;
output s_ack_o;
input [15:0] s_sel_i;
input s_we_i;
input [31:0] s_adr_i;
input [127:0] s_dat_i;
output reg [127:0] s_dat_o;

output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg m_we_o;
output reg [3:0] m_sel_o;
output reg [31:0] m_adr_o;
input [31:0] m_dat_i;
output reg [31:0] m_dat_o;

reg [1:0] state;
reg s_ack;
assign s_ack_o = s_ack & s_stb_i;
reg [31:0] dat1;

always @(posedge clk_i)
if (rst_i) begin
	m_cyc_o <= 1'b0;
	m_stb_o <= 1'b0;
	m_we_o <= 1'b0;
	m_sel_o <= 4'h0;
	m_adr_o <= 32'd0;
	m_dat_o <= 32'd0;
	s_ack <= 1'b0;
	dat1 <= 32'd0;
	state <= IDLE;
end
else begin
case(state)
IDLE:
    begin
        // Filter requests to the I/O address range
        if (s_cyc_i && s_adr_i[31:20]==12'hFFD) begin
            m_cyc_o <= 1'b1;
            m_stb_o <= 1'b1;
            state <= WAIT_ACK;
        end
        m_sel_o <= s_sel_i[15:12]|s_sel_i[11:8]|s_sel_i[7:4]|s_sel_i[3:0];
        m_we_o <= s_we_i;
        m_adr_o <= {12'hFFD,s_adr_i[19:0]};	// fix the upper 12 bits of the address to help trim cores
        m_dat_o <= s_dat_i[31:0];
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
	else if (!s_cyc_i) begin
		m_cyc_o <= 1'b0;
		m_stb_o <= 1'b0;
		m_we_o <= 1'b0;
//		m_sel_o <= 4'h0;
//		m_adr_o <= 32'h0;
//		m_dat_o <= 32'd0;
		state <= IDLE;
	end
WAIT_NACK:
	if (!s_stb_i) begin
		s_ack <= 1'b0;
		dat1 <= 32'h0;
		state <= IDLE;
	end
endcase
end

always @(negedge clk_i)
	s_dat_o <= {4{dat1}};

endmodule

