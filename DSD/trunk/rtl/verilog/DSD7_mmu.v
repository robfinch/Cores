`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_MMU.v
//		
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
//
// ============================================================================
//
`define LOW     1'b0
`define HIGH    1'b1

module DSD7_mmu(rst_i, clk_i, pcr_i, s_cyc_i, s_stb_i, s_vpa_i, s_vda_i, s_ack_o, s_sel_i, s_wr_i, s_adr_i, s_dat_i, s_dat_o,
    s_sr_i, s_cr_i, s_rb_o, 
    m_cyc_o, m_stb_o, m_ack_i, m_adr_o, m_dat_i, m_dat_o, m_vpa_o, m_vda_o, m_wr_o, m_sel_o, m_sr_o, m_cr_o, m_rb_i);
input rst_i;
input clk_i;
input [31:0] pcr_i;     // paging control register
input s_cyc_i;
input s_stb_i;
input [1:0] s_sel_i;
input s_vpa_i;            // valid program address
input s_vda_i;            // valid data address
input s_wr_i;             // write strobe
output reg s_ack_o;       // Address translation and MMU are ready
input [31:0] s_adr_i;    // virtual address
input [31:0] s_dat_i;
output reg [31:0] s_dat_o;
input s_sr_i;
input s_cr_i;
output reg s_rb_o;

output reg m_cyc_o;
output reg m_stb_o;
input m_ack_i;
output reg [1:0] m_sel_o;
output reg m_vpa_o;
output reg m_vda_o;
output reg m_wr_o;
output reg [31:0] m_adr_o;   // physical address
output reg [31:0] m_dat_o;
input [31:0] m_dat_i;
output reg m_sr_o;
output reg m_cr_o;
input m_rb_i;

parameter IDLE = 4'd0;
parameter WAIT_NACK = 4'd1;
parameter WAITRD1 = 4'd2;
parameter WAITRD2 = 4'd3;
parameter ACCESS = 4'd5;
parameter WAIT_NACK2 = 4'd6;

wire cs = s_cyc_i && s_stb_i && (s_adr_i[31:12]==20'hFFDC4);

reg [3:0] state;
wire [12:0] o0,o1;

DSD7_MMURam u1
(
    .clk(clk_i),
    .wr(cs & s_wr_i),
    .wa({pcr_i[12:8],s_adr_i[9:0]}),
    .i(s_dat_i[12:0]),
    .ra0({pcr_i[12:8],s_adr_i[9:0]}),
    .o0(o0),
    .ra1({pcr_i[4:0],s_adr_i[25:16]}),
    .o1(o1)
);

wire pe = pcr_i[31] & ~s_adr_i[31];

always @(posedge clk_i)
if (rst_i)
    state <= IDLE;
else
begin
    case(state)
    IDLE:
        // Filter out accesses to the mmu
        if (cs) begin
            state <= WAITRD1;
        end
        else begin
            m_adr_o[15:0] <= s_adr_i[15:0];
            m_adr_o[27:16] <= pe ? o1[11:0] : s_adr_i[27:16];
            m_adr_o[31:28] <= s_adr_i[31:28];
            if (s_cyc_i)
                state <= ACCESS; 
        end
    ACCESS:
        begin
            m_cyc_o <= `HIGH;
            m_stb_o <= `HIGH;
            m_vpa_o <= s_vpa_i;
            m_vda_o <= s_vda_i;
            m_sel_o <= s_sel_i;
            m_wr_o <= s_wr_i & (pe ? ~o1[12] : 1'b1);
            m_adr_o[15:0] <= s_adr_i[15:0];
            m_adr_o[27:16] <= pe ? o1[11:0] : s_adr_i[27:16];
            m_adr_o[31:28] <= s_adr_i[31:28];
            m_dat_o <= s_dat_i;
            m_sr_o <= s_sr_i;
            m_cr_o <= s_cr_i;
            if (m_ack_i) begin
                s_ack_o <= `HIGH;
                m_stb_o <= `LOW;
                s_dat_o <= m_dat_i; 
                s_rb_o <= m_rb_i;
                state <= WAIT_NACK;
            end
        end
    WAITRD1:
        state <= WAITRD2;
    WAITRD2:
        begin
            s_ack_o <= `HIGH;
            s_dat_o <= {2{3'b0,o0}};
            state <= WAIT_NACK;
        end
    WAIT_NACK:
        begin
            if (s_stb_i==`LOW) begin
                s_ack_o <= `LOW;
                s_dat_o <= 32'h0;
                m_stb_o <= `LOW;
                state <= WAIT_NACK2;
            end
            if (s_cyc_i==`LOW) begin
                m_cyc_o <= `LOW;
                m_stb_o <= `LOW;
                m_sel_o <= 2'b00;
                m_wr_o <= `LOW;
                m_vda_o <= `LOW;
                m_vpa_o <= `LOW;
                s_ack_o <= `LOW;
                s_dat_o <= 32'h0;
                m_sr_o <= `LOW;
                m_cr_o <= `LOW;
            end
       end
    WAIT_NACK2:
        if (!m_ack_i) begin
            state <= IDLE;
        end
       
    endcase
end

endmodule

module DSD7_MMURam(clk,wr,wa,i,ra0,o0,ra1,o1);
input clk;
input wr;
input [14:0] wa;
input [12:0] i;
input [14:0] ra0;
output [12:0] o0;
input [14:0] ra1;
output [12:0] o1;

reg [12:0] mapram [0:32767];
reg [13:0] rra0,rra1;

always @(posedge clk)
    if (wr)
        mapram[wa] <= i;

always @(posedge clk)
    rra0 <= ra0;
assign o0 = mapram[rra0];
always @(posedge clk)
    rra1 <= ra1;
assign o1 = mapram[rra1];

endmodule
