`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
//`define CARD_MEMORY	1'b1

module nvio3_mpu(hartid_i,rst_i, clk4x_i, clk2x_i, clk_i, tm_clk_i,
	pit_clk2, pit_gate2, pit_out2,
	irq_o,
    i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,
    i20,i21,i22,i23,i24,i25,i26,i27,i28,
	cti_o,bte_o,bok_i,cyc_o,stb_o,ack_i,err_i,we_o,sel_o,adr_o,dat_o,dat_i,
	sr_o, cr_o, rb_i);
input [127:0] hartid_i;
input rst_i;
input clk2x_i;
input clk4x_i;
input clk_i;
input tm_clk_i;
input pit_clk2;
input pit_gate2;
output pit_out2;
output [3:0] irq_o;
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
output [2:0] cti_o;
output [1:0] bte_o;
input bok_i;
output cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output we_o;
output [15:0] sel_o;
output [31:0] adr_o;
output reg [127:0] dat_o;
input [127:0] dat_i;
output sr_o;
output cr_o;
input rb_i;

wire [2:0] cti;
wire [1:0] bte;
wire cyc,stb,we;
wire [15:0] sel;
(* mark_debug="true" *)
wire [63:0] adr;
reg [127:0] dati;
wire [127:0] dato;
wire [3:0] irq;
wire [7:0] cause;
wire pic_ack;
wire [31:0] pic_dato;
wire pit_ack;
wire [31:0] pit_dato;
wire pit_out0, pit_out1;
wire crd_ack;
wire [63:0] crd_dato;
reg ack;
wire [63:0] ipt_dato;
wire ipt_ack;
wire [1:0] ol;
wire [31:0] pcr;
wire [63:0] pcr2;
wire icl;           // instruction cache load
wire exv,rdv,wrv;
wire pulse60;
wire sptr_o;
wire [127:0] pkeys;

//always @(posedge clk_i)
//	cyc_o <= cyc;
always @(posedge clk_i)
	stb_o <= stb;
//always @(posedge clk_i)
//	we_o <= we;
//always @(posedge clk_i)
//	adr_o <= adr;
always @(posedge clk_i)
	dat_o <= dato;

wire cs_pit = adr[31:8]==24'hFFDC11;
wire cs_ipt = adr[31:8]==24'hFFDCD0;
`ifdef CARD_MEMORY
wire cs_crd = adr[31:11]==21'd0;	// $00000000 in virtual address space
`else
wire cs_crd = 1'b0;
`endif

// Need to recreate the a2,a3 address bit for 32 bit peripherals.
wire [31:0] adr32 = {adr[31:4],|sel[15:8],|sel[7:4]| |sel[15:12],2'b00};
reg [31:0] dat32;
always @*
case(sel)
16'h000F:	dat32 <= dato[31:0];
16'h00F0:	dat32 <= dato[63:32];
16'h0F00:	dat32 <= dato[95:64];
16'hF000:	dat32 <= dato[127:96];
default:	dat32 <= dato[31:0];
endcase

nvio3_pit upit1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.cs_i(cs_pit),
	.cyc_i(cyc_o),
	.stb_i(stb_o),
	.ack_o(pit_ack),
	.sel_i(sel_o[15:12]|sel_o[11:8]|sel_o[7:4]|sel_o[3:0]),
	.we_i(we_o),
	.adr_i(adr32[5:0]),
	.dat_i(dat32),
	.dat_o(pit_dato),
	.clk0(1'b0),
	.gate0(1'b0),
	.out0(pit_out0),
	.clk1(1'b0),
	.gate1(1'b0),
	.out1(pit_out1),
	.clk2(1'b0),
	.gate2(1'b0),
	.out2(pit_out2)
);

nvio3_pic upic1
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.cyc_i(cyc_o),
	.stb_i(stb_o),
	.ack_o(pic_ack),    // controller is ready
	.wr_i(we_o),		// write
	.adr_i(adr32),		// address
	.dat_i(dat32),
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
	.i29(pit_out2),	// garbage collector stop interrupt
	.i30(pit_out1),	// garbage collector interrupt
	.i31(pit_out0),	// time slice interrupt
	.irqo(irq),
	.nmii(1'b0),
	.nmio(),
	.causeo(cause)
);

assign irq_o = irq;

`ifdef CARD_MEMORY
CardMemory ucrd1
(
	.clk_i(clk_i),
	.cs_i(cs_crd & cyc_o & stb_o),
	.ack_o(crd_ack),
	.wr_i(we_o),
	.adr_i(adr),
	.dat_i(dato),
	.dat_o(crd_dato),
	.stp(1'b0),
	.mapno(pcr[5:0])
);
`else
assign crd_dato = 64'd0;
assign crd_ack = 1'b0;
`endif

nvio3_ipt uipt1
(
	.rst(rst_i),
	.clk(clk_i),
	.pkeys_i(pkeys),
	.ol_i(ol),
	.bte_i(bte),
	.cti_i(cti),
	.cs_i(cs_ipt),
	.icl_i(icl),
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(ipt_ack),
	.we_i(we),
	.sel_i(sel),
	.vadr_i(adr),
	.dat_i(dato),
	.dat_o(ipt_dato),
	.bte_o(bte_o),
	.cti_o(cti_o),
	.cyc_o(cyc_o),
	.ack_i(ack),
	.we_o(we_o),
	.sel_o(sel_o),
	.padr_o(adr_o),
	.exv_o(exv),
	.rdv_o(rdv),
	.wrv_o(wrv)
);

always @(posedge clk_i)
casez({pic_ack,pit_ack,crd_ack,cs_ipt,ack_i})
5'b1????:	dati <= {4{pic_dato}};
5'b01???:	dati <= {4{pit_dato}};
5'b001??:	dati <= crd_dato;
5'b0001?:	dati <= ipt_dato;
5'b00001:	dati <= dat_i;
default:  dati <= dati;
endcase

always @(posedge clk_i)
	ack <= ack_i|pic_ack|pit_ack|crd_ack|ipt_ack;

nvio3 ucpu1
(
    .hartid_i(hartid_i),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk2x_i(clk2x_i),
    .clk4x_i(clk4x_i),
    .tm_clk_i(tm_clk_i),
    .irq_i(irq),
    .cause_i(cause),
    .cti_o(cti),
    .bte_o(bte),
    .bok_i(bok_i),
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .err_i(err_i),
    .we_o(we),
    .sel_o(sel),
    .adr_o(adr),
    .dat_o(dato),
    .dat_i(dati),
    .ol_o(ol),
    .pcr_o(pcr),
    .pcr2_o(pcr2),
    .pkeys_o(pkeys),
    .icl_o(icl),
    .sr_o(sr_o),
    .cr_o(cr_o),
    .rbi_i(rb_i)
);

endmodule
