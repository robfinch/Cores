// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd7_mpu.v
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
module DSD7_mpu(hartid_i, rst_i, clk_i,
    i1,i2,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,
    i20,i21,i22,i23,i24,i25,i26,i27,i28,i29,i30,i31, irq_o,
    cyc_o, stb_o, vpa_o, vda_o, wr_o, sel_o, ack_i, err_i, adr_o, dat_i, dat_o,
    sr_o, cr_o, rb_i
    );
input [31:0] hartid_i;
input rst_i;
input clk_i;
input i1;
input i2;
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
input i30;
input i31;
output irq_o;
output cyc_o;
output stb_o;
output vpa_o;
output vda_o;
output wr_o;
output [1:0] sel_o;
input ack_i;
input err_i;
output [31:0] adr_o;
input [31:0] dat_i;
output [31:0] dat_o;
output sr_o;
output cr_o;
input rb_i;
parameter CLK_FREQ = 50000000;

wire irq;
wire [8:0] cause;
wire cyc;
wire stb;
wire [1:0] sel;
wire vpa;
wire vda;
wire wr;
wire ack, mmu_ack, pic_ack;
wire [31:0] mmu_dat, pic_dat;
wire [31:0] adr;
wire [31:0] dati;
wire [31:0] dato;
wire cpu_sr_o;
wire cpu_cr_o;
wire cpu_rb_i;
wire [31:0] pcr;
wire pulse30;

DSD7 u1
(
    .hartid_i(hartid_i),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .irq_i(irq),
    .icause_i(cause),
    .cyc_o(cyc),
    .stb_o(stb),
    .vpa_o(vpa),
    .vda_o(vda),
    .wr_o(wr),
    .sel_o(sel),
    .ack_i(ack),
    .err_i(err_i),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dato),
    .sr_o(cpu_sr_o),
    .cr_o(cpu_cr_o),
    .rb_i(cpu_rb_i),
    .pcr_o(pcr)
);

DSD7_mmu u2
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .pcr_i(pcr),
    
    .s_cyc_i(cyc),
    .s_stb_i(stb),
    .s_ack_o(mmu_ack),
    .s_vpa_i(vpa),
    .s_vda_i(vda),
    .s_wr_i(wr),
    .s_sel_i(sel),
    .s_adr_i(adr),
    .s_dat_i(dato),
    .s_dat_o(mmu_dat),
    .s_sr_i(cpu_sr_o),
    .s_cr_i(cpu_cr_o),
    .s_rb_o(cpu_rb_i),
   
    .m_cyc_o(cyc_o),
    .m_stb_o(stb_o),
    .m_vpa_o(vpa_o),
    .m_vda_o(vda_o),
    .m_wr_o(wr_o),
    .m_sel_o(sel_o),
    .m_adr_o(adr_o),
    .m_dat_i(dat_i),
    .m_dat_o(dat_o),
    .m_ack_i(ack_i),
    .m_sr_o(sr_o),
    .m_cr_o(cr_o),
    .m_rb_i(rb_i)
);

DSD7_pic u3
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(pic_ack),    // controller is ready
	.wr_i(wr),			// read/write
	.adr_i(adr),	    // address
	.dat_i(dato),
	.dat_o(pic_dat),
	.vol_o(),		// volatile register selected
	.i1(i1),
	.i2(i2),
	.i3(pulse30),
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
	.i30(i30),
	.i31(i31),
	.irqo(irq),	// normally connected to the processor irq
	.nmii(),	// nmi input connected to nmi requester
	.nmio(),	// normally connected to the nmi of cpu
	.cause(cause)
);

DSD_30Hz #(.CLK_FREQ(CLK_FREQ)) u30Hz
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    ._30Hz_o(pulse30)
);

assign ack = mmu_ack | pic_ack;
assign dati = pic_dat|mmu_dat;
assign irq_o = irq;

endmodule

