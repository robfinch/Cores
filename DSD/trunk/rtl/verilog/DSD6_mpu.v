// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD_mpu.v
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
`include "dsd6_defines.vh"

module dsd6_mpu(hartid_i, rst_i, clk_i,
    i1, i2, i4, i5, i6, i31, 
    rdy_i, vda_o, vpa_o, sel_o, wr_o, adr_o, dat_i, dat_o,
    mva_o, mlock_o, mrdy_i, mwr_o, msel_o, madr_o, mdat_i, mdat_o
    );
input [63:0] hartid_i;
input rst_i;
input clk_i;
input i1;
input i2;
input i4;
input i5;
input i6;
input i31;
input rdy_i;
output vda_o;
output vpa_o;
output [7:0] sel_o;
output wr_o;
output [47:0] adr_o;
input [63:0] dat_i;
output [63:0] dat_o;
output mva_o;
output mlock_o;
input mrdy_i;
output mwr_o;
output [7:0] msel_o;
output [47:0] madr_o;
input [63:0] mdat_i;
output [63:0] mdat_o;
parameter CLK_FREQ = 50000000;

wire [63:0] pta;
wire [7:0] cpl;
wire vda;
wire vpa;
wire [63:0] adr;
wire wr;
wire [7:0] sel;
wire [47:0] padr;
wire pv;
wire trdy;
wire [63:0] dato;
wire dr,dw;
wire cx;
wire cv,dv;
wire page_fault;
wire [8:0] icause;
wire [31:0] pic_dat;
wire pulse30;

DSD_30Hz #(.CLK_FREQ(CLK_FREQ)) u30Hz
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    ._30Hz_o(pulse30)
);

DSD_pic upic1
(
	.rst_i(rst_i),		// reset
	.clk_i(clk_i),		// system clock
	.vda_i(vda),		// cycle valid
	.rdy_o(pic_rdy),    // controller is ready
	.rw_i(rw),       	// read/write
	.adr_i(adr),	    // address
	.dat_i(dato),
	.dat_o(pic_dat),
	.vol_o(),		    // volatile register selected
	.i1(i1),
	.i2(i2),
	.i3(pulse30),
	.i4(i4),
	.i5(),
	.i6(),
	.i7(),
	.i8(),
	.i9(),
	.i10(),
	.i11(),
	.i12(),
	.i13(),
	.i14(),
	.i15(),
    .i16(),
    .i17(),
    .i18(),
    .i19(),
    .i20(),
    .i21(),
    .i22(),
    .i23(),
	.i24(),
	.i25(),
	.i26(),
	.i27(),
	.i28(),
	.i29(),
	.i30(),
	.i31(i31),
	.irqo(pic_irq),	// normally connected to the processor irq
	.nmii(nmi_i),	// nmi input connected to nmi requester
	.nmio(),	  // normally connected to the nmi of cpu
	.vecno(icause)
);

DSD_pmmu mmu1
(
// syscon
    .rst_i(rst_i),
    .clk_i(clk_i),

// master
    .va_o(mva_o),		// valid memory address
    .lock_o(mlock_o),	// lock the bus
    .rdy_i(mrdy_i),		// acknowledge from memory system
    .wr_o(mwr_o),		// write enable output
    .byt_o(msel_o),	    // lane selects (always all active)
    .adr_o(madr_o),
    .dat_i(mdat_i),	    // data input from memory
    .dat_o(mdat_o),	    // data to memory

// Translation request / control
    .invalidate(),		// invalidate a specific entry
    .invalidate_all(),	// causes all entries to be invalidated
    .pta(pta),		    // page directory/table address register
    .page_fault(page_fault),

    .pl(cpl),

    .vda_i(vda),
    .vpa_i(vpa),
    .sel_i(sel),
    .wr(wr),   		   // cpu is performing write cycle
    .vadr_i(adr),		 // virtual code address to translate
    .padr_o(adr_o),	     // physical address
    .rdy_o(trdy),		 // address translation is ready
    .vda_o(vda_o),
    .vpa_o(vpa_o),
    .sel_o(sel_o),
    .wr_o(wr_o),
    .a(),
    .c(),               // cacheable (code is always cached here so we ignore)
    .r(dr),             // irrrelevant for code side
    .w(dw),             // irrelevant for the code side
    .x(cx),	            // execute attribute
    .v(tv),			    // translation is valid
    .pv(pv)
);

dsd6 ucpu1
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .irq_i(pic_irq),
    .icause_i(icause),
    .rdy_i(rdy_i & trdy & pic_rdy),
    .vda_o(vda),
    .vpa_o(vpa),
    .sel_o(sel),
    .wr_o(wr),
    .adr_o(adr),
    .dat_i(dr ? dat_i|pic_dat : -64'h1),
    .dat_o(dat_o),
    .pv_i(pv),
    .tv_i(tv),
    .cv_i(tv & !page_fault),
    .cx_i(cx),
    .cpl_o(cpl),
    .pta_o(pta)
);

endmodule
