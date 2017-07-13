`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_MPU.v
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
module FT64_mpu(hartid_i,rst_i,clk_i,irq_i,vec_i,cyc_o,stb_o,ack_i,we_o,sel_o,adr_o,dat_o,dat_i);
input [63:0] hartid_i;
input rst_i;
input clk_i;
input [2:0] irq_i;
input [8:0] vec_i;
output cyc_o;
output stb_o;
input ack_i;
output we_o;
output [7:0] sel_o;
output [31:0] adr_o;
output [63:0] dat_o;
input [63:0] dat_i;

wire cyc,stb,we;
wire [31:0] adr;
reg [63:0] dati;
wire mmu_ack;
wire [31:0] mmu_dato;
wire ack;
wire [2:0] ol;
wire [31:0] pcr;
wire [63:0] pcr2;
wire icl;           // instruction cache load
wire exv,rdv,wrv;

FT64_mmu ummu1
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .ol_i(ol),
    .pcr_i(pcr),
    .pcr2_i(pcr2),
    .mapen_i(pcr[31]),
    .s_ex_i(icl),
    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(mmu_ack),
    .s_wr_i(we_o),
    .s_adr_i(adr),
    .s_dat_i(dat_o[31:0]),
    .s_dat_o(mmu_dato),
    .cyc_o(cyc_o),
    .stb_o(stb_o),
    .pea_o(adr_o),
    .exv_o(exv),
    .rdv_o(rdv),
    .wrv_o(wrv)
);

always @*
case(mmu_ack)
1'b1:       dati <= {2{mmu_dato}};
default:    dati <= dat_i;
endcase

assign ack = ack_i|mmu_ack;

FT64 ucpu1
(
    .hartid(hartid_i),
    .rst(rst_i),
    .clk(clk_i),
    .irq_i(irq_i),
    .vec_i(vec_i),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .we_o(we_o),
    .sel_o(sel_o),
    .adr_o(adr),
    .dat_o(dat_o),
    .dat_i(dati),
    .ol_o(ol),
    .pcr_o(pcr),
    .pcr2_o(pcr2),
    .icl_o(icl),
    .exv_i(exv),
    .rdv_i(rdv),
    .wrv_i(wrv)
);

endmodule
