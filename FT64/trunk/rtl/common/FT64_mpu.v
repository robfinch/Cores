`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2018  Robert Finch, Waterloo
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
module FT64_mpu(hartid_i,rst_i, clk4x_i, clk_i, tm_clk_i,
	pit_clk2, pit_gate2, pit_out2,
	irq_o,
    i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,
    i20,i21,i22,i23,i24,i25,i26,i27,i28,i29,
	cti_o,bte_o,cyc_o,stb_o,ack_i,err_i,we_o,sel_o,adr_o,dat_o,dat_i);
input [63:0] hartid_i;
input rst_i;
input clk4x_i;
input clk_i;
input tm_clk_i;
input pit_clk2;
input pit_gate2;
output pit_out2;
input i1;
input i2;
input i3;
input i4;
input i5;
input i6;
input i7;
input i8;
input i9;
input i10;
input i11;
input i12;
input i13;
input i14;
input i15;
input i16;
input i17;
input i18;
input i19;
input i20;
input i21;
input i22;
input i23;
input i24;
input i25;
input i26;
input i27;
input i28;
input i29;
output [2:0] cti_o;
output [1:0] bte_o;
output cyc_o;
output stb_o;
input ack_i;
input err_i;
output we_o;
output [7:0] sel_o;
output [31:0] adr_o;
output [63:0] dat_o;
input [63:0] dat_i;

wire cyc,stb,we;
wire [31:0] adr;
reg [63:0] dati;
wire [2:0] irq;
wire [6:0] cause;
wire mmu_ack;
wire [31:0] mmu_dato;
wire pic_ack;
wire [31:0] pic_dato;
wire pit_ack;
wire [31:0] pit_dato;
wire pit_out0, pit_out1;
wire ack;
wire [2:0] ol;
wire [31:0] pcr;
wire [63:0] pcr2;
wire icl;           // instruction cache load
wire exv,rdv,wrv;
wire pulse60;

wire cs_pit = adr[31:8]==24'hFFDC11;

FT64_pit upit1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.cs_i(cs_pit),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(pit_ack),
	.sel_i(sel_o[7:4]|sel_o[3:0]),
	.we_i(we_o),
	.adr_i(adr[5:0]),
	.dat_i(dat_o[31:0]),
	.dat_o(pit_dato),
	.clk0(1'b0),
	.gate0(1'b0),
	.out0(pit_out0),
	.clk1(1'b0),
	.gate1(1'b0),
	.out1(pit_out1),
	.clk2(pit_clk2),
	.gate2(pit_gate2),
	.out2(pit_out2)
);

FT64_pic upic1
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(pic_ack),    // controller is ready
	.wr_i(we_o),		// write
	.adr_i(adr),		// address
	.dat_i(dat_o[31:0]),
	.dat_o(pic_dato),
	.vol_o(),			// volatile register selected
	.i1(i1),
	.i2(i2),
	.i3(i3),
	.i4(i4),
	.i5(i5),
	.i6(i6),
	.i7(i7),
	.i8(i8),
	.i9(i9),
	.i10(i10),
	.i11(i11),
	.i12(i12),
	.i13(i13),
	.i14(i14),
	.i15(i15),
	.i16(i16),
	.i17(i17),
	.i18(i18),
	.i19(i19),
	.i20(i20),
	.i21(i21),
	.i22(i22),
	.i23(i23),
	.i24(i24),
	.i25(i25),
	.i26(i26),
	.i27(i27),
	.i28(i28),
	.i29(i29),
	.i30(pit_out1),	// garbage collector interrupt
	.i31(pit_out0),	// time slice interrupt
	.irqo(irq),
	.nmii(1'b0),
	.nmio(),
	.causeo(cause)
);

assign irq_o = irq;

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
casez({mmu_ack,pic_ack,pit_ack})
3'b1??:     dati <= {2{mmu_dato}};
3'b01?:		dati <= {2{pic_dato}};
3'b001:		dati <= {2{pit_dato}};
default:    dati <= dat_i;
endcase

assign ack = ack_i|mmu_ack|pic_ack;

FT64 ucpu1
(
    .hartid(hartid_i),
    .rst(rst_i),
    .clk(clk_i),
    .clk4x(clk4x_i),
    .tm_clk_i(tm_clk_i),
    .irq_i(irq),
    .vec_i(cause),
    .cti_o(cti_o),
    .bte_o(bte_o),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .err_i(err_i),
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
