// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd9_mpu.v
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
module DSD9_mpu(hartid_i, rst_i, clk_i, clk2x_i, clk2d_i,
    i1,i2,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,
    i20,i21,i22,i23,i24,i25,i26,i27,i28,i29,i30,i31, irq_o,
    cyc_o, stb_o, wr_o, sel_o, wsel_o, ack_i, err_i, adr_o, dat_i, dat_o,
    sr_o, cr_o, rb_i, state_o
    );
input [79:0] hartid_i;
input rst_i;
input clk_i;
input clk2x_i;
input clk2d_i;
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
output wr_o;
output [15:0] sel_o;
output [15:0] wsel_o;
input ack_i;
input err_i;
output [31:0] adr_o;
input [127:0] dat_i;
output [127:0] dat_o;
output sr_o;
output cr_o;
input rb_i;
output [5:0] state_o;

parameter CLK_FREQ = 50000000;

wire irq;
wire [8:0] cause;
wire cyc;
wire stb;
wire [15:0] sel;
wire [15:0] wsel;
wire vpa;
wire vda;
wire wr;
wire ack, mmu_ack, pic_ack;
wire [31:0] mmu_dat, pic_dat;
wire [31:0] adr;
wire [127:0] dati;
wire [127:0] dato;
wire cpu_sr_o;
wire cpu_cr_o;
wire cpu_rb_i;
wire [31:0] pcr;
wire pulse30;

DSD9 u1
(
    .hartid_i(hartid_i),
    .rst_i(rst_i),
    .clk_i(clk_i),
    .clk2x_i(clk2x_i),
    .clk2d_i(clk2d_i),
    .irq_i(irq),
    .icause_i(cause),
    .cyc_o(cyc),
    .stb_o(stb),
    .wr_o(wr),
    .sel_o(sel),
    .wsel_o(wsel),
    .ack_i(ack),
    .err_i(err_i),
    .adr_o(adr),
    .dat_i(dati),
    .dat_o(dato),
    .sr_o(cpu_sr_o),
    .cr_o(cpu_cr_o),
    .rb_i(cpu_rb_i),
    .state_o(state_o)
);

DSD9_pic u2
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.cyc_i(cyc),
	.stb_i(stb),
	.ack_o(pic_ack),    // controller is ready
	.wr_i(wr),			// read/write
	.adr_i(adr),	    // address
	.dat_i(dato[31:0]),
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

assign cyc_o = cyc;
assign stb_o = stb;
assign wr_o = wr;
assign sel_o = sel;
assign wsel_o = wsel;
assign adr_o = adr;
assign dat_o = dato;
assign ack = pic_ack|ack_i;
assign sr_o = cpu_sr_o;
assign cr_o = cpu_cr_o;
assign cpu_rb_i = rb_i;
assign dati = {4{pic_dat}}|dat_i;
assign irq_o = irq;

endmodule

