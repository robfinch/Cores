`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//	Verilog 1995
//
// ============================================================================
//
`define HIGH    1'b1
`define LOW     1'b0
`define MSG_TYPE    71:64

module BMCNode(rst_i, clk_i, sclk, rxdX, txdX, rxdY, txdY, rxdZ, txdZ,
    mem_ui_clk, cyc, stb, ack, we, adr, dati, dato,
    vclk, hsync, vsync, blank, rgbo
);
input rst_i;
input clk_i;
input sclk;
input [3:0] rxdX;
input [3:0] rxdY;
input [3:0] rxdZ;
output [3:0] txdX;
output [3:0] txdY;
output [3:0] txdZ;
input mem_ui_clk;
output cyc;
output stb;
input ack;
output we;
output [31:0] adr;
input [31:0] dati;
output [31:0] dato;
input vclk;
input hsync;
input vsync;
input blank;
output [23:0] rgbo;
parameter ID = 12'hF11;
parameter HAS_ZROUTE = 0;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;

parameter MT_RDRAM = 8'd27;
parameter MT_WRRAM = 8'd28;
parameter MT_SETPIXEL = 8'd29;
parameter MT_GETPIXEL = 8'd30;
parameter MT_SETADDR = 8'd31;
parameter MT_DATA = 8'd32;

parameter PCMD_GETPIXEL = 3'd1;
parameter PCMD_SETPIXEL = 3'd2;
parameter PCMD_RDMEM = 3'd3;
parameter PCMD_WRMEM = 3'd4;

reg cs_router;
reg cs_bmc;
wire r_ack;
reg s_cyc, r_cyc;
reg s_stb, r_stb;
wire s_ack;
reg s_we, r_we;
reg [15:0] s_adr, r_adr;
reg [31:0] s_dati;
wire [31:0] s_dato;
wire [135:0] r_dato;
reg [135:0] r_dati;
reg [135:0] dat;
reg [4:0] state;
parameter IDLE = 5'd0;
parameter S1 = 5'd1;
parameter S2 = 5'd2;
parameter S3 = 5'd3;
parameter S4 = 5'd4;
parameter S5 = 5'd5;
parameter S6 = 5'd6;
parameter S7 = 5'd7;
parameter S8 = 5'd8;
parameter S9 = 5'd9;
parameter S10 = 5'd10;
parameter S11 = 5'd11;
parameter S12 = 5'd12;
parameter S13 = 5'd13;
parameter S14 = 5'd14;
parameter S15 = 5'd15;
parameter S16 = 5'd16;
parameter S17 = 5'd17;
parameter S18 = 5'd18;
 
routerTop #(HAS_ZROUTE) urout1
(
    .X(ID[11:8]),
    .Y(ID[7:4]),
    .Z(ID[3:0]),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .cs_i(cs_router),
    .cyc_i(r_cyc),
    .stb_i(r_stb),
    .ack_o(r_ack),
    .we_i(r_we),
    .adr_i(r_adr[4:0]),
    .dat_i(r_dati),
    .dat_o(r_dato),
    .sclk(sclk),
    .rxdX(rxdX),
    .rxdY(rxdY),
    .rxdZ(rxdZ),
    .txdX(txdX),
    .txdY(txdY),
    .txdZ(txdZ)
);

reg [5:0] state;
always @(posedge clk_i)
if (rst_i) begin
    state <= IDLE;
end
else begin
case(state)
IDLE:
    begin
        cs_router <= `HIGH;
        r_cyc <= `HIGH;
        r_stb <= `HIGH;
        r_we <= `LOW;
        r_adr <= 16'hB010;
        state <= S1;        
    end
S1:
    if (r_ack) begin
        r_cyc <= `LOW;
        dat <= r_dato;
        state <= S2;
    end
S2:
    if (dat[135:128]==8'h00)    // fifo was empty
        state <= IDLE;
    else begin
        case(dat[`MSG_TYPE])
        MT_RDRAM:
            begin
                cs_bmc <= `HIGH;
                s_cyc <= `HIGH;
                s_stb <= `HIGH;
                s_we <= `HIGH;
                s_adr <= {14'd13,2'b00};    // RAMA register
                s_dati <= dat[47:16];
                state <= S6;
            end
        MT_WRRAM:
            begin
                cs_bmc <= `HIGH;
                s_cyc <= `HIGH;
                s_stb <= `HIGH;
                s_we <= `HIGH;
                s_adr <= {14'd13,2'b00};    // RAMA register
                s_dati <= dat[47:16];
                state <= S14;
            end
        MT_SETPIXEL:    ;
        MT_GETPIXEL:    ;
        default:    state <= IDLE;
        endcase
    end
// Read data register
S6:
    if (s_ack) begin
        s_stb <= `LOW;
        state <= S7;
    end
S7:
    begin
        s_stb <= `HIGH;
        s_adr <= {14'd12,2'b00};    // RAMD register
        s_dati <= PCMD_RDMEM;
        state <= S8;
    end
S8:
    if (s_ack) begin
        s_stb <= `LOW;
        s_we <= `LOW;
        state <= S9;
    end
// Must wait in these two states until the read command has time to be
// processed.
S9:
    begin
        s_stb <= `HIGH;
        s_adr <= 16'd12;
    end
S10:
    if (s_ack) begin
        s_stb <= `LOW;
        if (s_dato[7:0]!=8'h00)
            state <= S9;
        else
            state <= S11;
    end
S11:
    begin
        s_stb <= `HIGH;
        s_adr <= 16'd14;    // data register
    end
// Should maybe wait here until the transmit empty bit is set.
S12:
    if (s_ack) begin
        cs_bmc <= `LOW;
        s_cyc <= `LOW;
        s_stb <= `LOW;
        s_we <= `LOW;
        cs_router <= `HIGH;
        r_cyc <= `HIGH;
        r_stb <= `HIGH;
        r_we <= `HIGH;
        r_adr <= 16'h0;
        r_dati <= {
            8'h00,dat[119:112],ID[11:4],32'd0,8'h3F,MT_DATA,dat[59:56],ID[3:0],40'h0,s_dato[15:0]
        }; 
        state <= S13;
    end
S13:
    if (r_ack) begin
        cs_router <= `LOW;
        r_cyc <= `LOW;
        r_stb <= `LOW;
        r_we <= `LOW;
        state <= IDLE;
    end
// Write data register
S14:
    if (s_ack) begin
        s_stb <= `LOW;
        state <= S15;
    end
S15:
    begin
        s_stb <= `HIGH;
        s_adr <= {14'd14,2'b00};
        s_dati <= dat[15:0];
        state <= S16;
    end
S16:
    if (s_ack) begin
        s_stb <= `LOW;
        state <= S17;
    end
S17:
    begin
        s_stb <= `HIGH;
        s_adr <= {14'd12,2'b00};
        s_dati <= PCMD_WRMEM;
        state <= S18;
    end
S18:
    if (s_ack) begin
        s_cyc <= `LOW;
        s_stb <= `LOW;
        s_we <= `LOW;
        state <= IDLE;
    end

endcase
end

BitmapController u2 
(
	.rst_i(rst_i),
	.s_clk_i(clk_i),
	.s_cs_i(cs_bmc),
	.s_cyc_i(s_cyc),
	.s_stb_i(s_stb),
	.s_ack_o(s_ack),
	.s_we_i(s_we),
	.s_adr_i(s_adr),
	.s_dat_i(s_dati),
	.s_dat_o(s_dato),
	.irq_o(),
	.m_clk_i(mem_ui_clk),
	.m_bte_o(),
	.m_cti_o(),
	.m_cyc_o(cyc),
	.m_stb_o(stb),
	.m_ack_i(ack),
	.m_we_o(we),
	.m_sel_o(sel),
	.m_adr_o(adr),
	.m_dat_i(dati),
	.m_dat_o(dato),
	.vclk(vclk),
	.hsync(hsync),
	.vsync(vsync),
	.blank(blank),
	.rgbo(rgbo),
	.xonoff(1'b1)
);

endmodule
