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
    i20,i21,i22,i23,i24,i25,i26,i27,i28,i29,i30,i31, 
    vpa_o, vda_o, wr_o, sel_o, rdy_i, adr_o, dat_i, dat_o,
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
output vpa_o;
output vda_o;
output wr_o;
output [1:0] sel_o;
input rdy_i;
output [31:0] adr_o;
input [31:0] dat_i;
output [31:0] dat_o;
output sr_o;
output cr_o;
input rb_i;
parameter CLK_FREQ = 50000000;

wire irq;
wire [8:0] cause;
wire vpa;
wire vda;
wire wr;
wire rdy;
wire [31:0] adr;
wire [31:0] dati;
wire [31:0] dato;
wire [31:0] pcr;
wire pulse30;

DSD7 u1
(
    .hartid_i(hartid_i),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .irq_i(irq),
    .icause_i(cause),
    .vpa_o(vpa),
    .vda_o(vda),
    .wr_o(wr),
    .sel_o(sel_o),
    .rdy_i(rdy),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dat_o),
    .sr_o(sr_o),
    .cr_o(cr_o),
    .rb_i(rb_i),
    .pcr_o(pcr)
);

DSD7_mmu u2
(
    .clk_i(clk_i),
    .pcr_i(pcr),
    .vpa_i(vpa),
    .vda_i(vda),
    .wr_i(wr),
    .vadr_i(adr),
    .padr_o(adr_o),
    .vpa_o(vpa_o),
    .vda_o(vda_o),
    .dat_i(dat_o),
    .dat_o(mmu_dat),
    .rdy_o(mmu_rdy),
    .wr_o(wr_o)
);

DSD7_pic u3
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.vda_i(vda),		// cycle valid
	.rdy_o(pic_rdy),    // controller is ready
	.wr_i(wr),			// read/write
	.adr_i(adr),	    // address
	.dat_i(dat_o),
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

assign rdy = mmu_rdy & pic_rdy & rdy_i;

endmodule

