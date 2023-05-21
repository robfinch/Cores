`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
//
//		Encodes discrete interrupt request signals into five
//	bit code using a priority encoder.
//	
//	reg
//	0x00	- encoded request number (read / write)
//			This register contains the number identifying
//			the current requester in bits 0 to 4
//			If there is no
//			active request, then this number will be 
//			zero.
//          bits 8 to 15 set the base number for the vector
//
//	0x04	- request enable (read / write)
//			this register contains request enable bits
//			for each request line. 1 = request
//			enabled, 0 = request disabled. On reset this
//			register is set to zero (disable all ints).
//			bit zero is specially reserved for nmi
//
//	0x08   - write only
//			this register disables the interrupt indicated
//			by the low order five bits of the input data
//			
//	0x0C	- write only
//			this register enables the interrupt indicated
//			by the low order five bits of the input data
//
//	0x10	- write only
//			this register indicates which interrupt inputs are
// 			edge sensitive
//
//  0x14	- write only
//			This register resets the edge sense circuitry
//			indicated by the low order five bits of the input data.
//
//  0x18  - write only
//      This register triggers the interrupt indicated by the low
//      order five bits of the input data.
//
//  0x80    - irq control for irq #0
//  0x84    - irq control for irq #1
//            bits 0 to 7  = cause code to issue
//            bits 8 to 11 = irq level to issue
//            bit 16 = irq enable
//            bit 17 = edge sensitivity
//						bit 18 = respond to inta
//						bit 24 to 29 target core
//=============================================================================

module rfx32_pic
(
	input rst_i,		// reset
	input clk_i,		// system clock
	input cs_config_i,
	input cs_io_i,
	input [2:0] cti_i,	// for interrupt acknowledge detection
	input cyc_i,
	input stb_i,
	output ack_o,       // controller is ready
	output reg vp_o,	// vector pull
	input wr_i,			// write
	input [3:0] sel_i,
	input [31:0] adr_i,	// address
	input [31:0] dat_i,
	output reg [31:0] dat_o,
	output vol_o,		// volatile register selected
	input i1, i2, i3, i4, i5, i6, i7,
		i8, i9, i10, i11, i12, i13, i14, i15,
		i16, i17, i18, i19, i20, i21, i22, i23,
		i24, i25, i26, i27, i28, i29, i30, i31,
	output reg [3:0] irqo,	// normally connected to the processor irq
	input nmii,		// nmi input connected to nmi requester
	output reg nmio,	// normally connected to the nmi of cpu
	output reg [7:0] causeo,
	output reg [5:0] core_o
);
parameter PIC_ADDR = 32'hFEE20001;
parameter PIC_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd6;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'h40;
parameter CFG_SUBCLASS = 8'h00;					// 00 = PIC
parameter CFG_CLASS = 8'h08;						// 08 = base system controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

parameter MSIX = 1'b0;

wire clk;
wire cs_pic;
wire [31:0] cfg_out;
wire irq_en;
reg [31:0] trig;
reg [31:0] ie;		// interrupt enable register
reg rdy1;
reg [4:0] irqenc;
wire [31:0] i = {   i31,i30,i29,i28,i27,i26,i25,i24,i23,i22,i21,i20,i19,i18,i17,i16,
                    i15,i14,i13,i12,i11,i10,i9,i8,i7,i6,i5,i4,i3,i2,i1,nmii};
reg [31:0] ib;
reg [31:0] iedge;
reg [31:0] rste;
reg [31:0] es;
reg [3:0] irq [0:31];
reg [7:0] cause [0:31];
reg [5:0] core [0:31];
reg [31:0] intar;
integer n,n1,n2;

wire cs_config = cyc_i & stb_i & cs_config_i &&
	adr_i[27:20]==CFG_BUS &&
	adr_i[19:15]==CFG_DEVICE &&
	adr_i[14:12]==CFG_FUNC
	;
wire cs_io = cyc_i & stb_i & cs_io_i && cs_pic;
wire cs = cs_config|cs_io;
wire cs_inta = cyc_i && stb_i && adr_i[31:4]=={28{1'b1}} && cti_i==3'b110;
assign vol_o = cs_io|cs_config|cs_inta;

assign clk = clk_i;
//BUFH ucb1 (.I(clk_i), .O(clk));

always_ff @(posedge clk)
	rdy1 <= cs | (cs_inta & intar[irqenc]);
assign ack_o = (cs | (cs_inta & intar[irqenc])) ? (wr_i ? 1'b1 : rdy1) : 1'b0;

pci32_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(PIC_ADDR),
	.CFG_BAR0_MASK(PIC_ADDR_MASK),
	.CFG_SUBSYSTEM_VENDOR_ID(CFG_SUBSYSTEM_VENDOR_ID),
	.CFG_SUBSYSTEM_ID(CFG_SUBSYSTEM_ID),
	.CFG_ROM_ADDR(CFG_ROM_ADDR),
	.CFG_REVISION_ID(CFG_REVISION_ID),
	.CFG_PROGIF(CFG_PROGIF),
	.CFG_SUBCLASS(CFG_SUBCLASS),
	.CFG_CLASS(CFG_CLASS),
	.CFG_CACHE_LINE_SIZE(CFG_CACHE_LINE_SIZE),
	.CFG_MIN_GRANT(CFG_MIN_GRANT),
	.CFG_MAX_LATENCY(CFG_MAX_LATENCY),
	.CFG_IRQ_LINE(CFG_IRQ_LINE)
)
ucfg1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.irq_i(1'b0),
	.irq_o(),
	.cs_config_i(cs_config), 
	.we_i(wr_i),
	.sel_i(sel_i),
	.adr_i(adr_i),
	.dat_i(dat_i),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_pic),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o(irq_en)
);

// write registers	
always_ff @(posedge clk)
	if (rst_i) begin
		ie <= 32'h0;
		rste <= 32'h0;
		trig <= 32'h0;
		es <= 32'hFFFFFFFF;
		rste <= 32'h0;
		intar <= 32'hFFFFFFFF;
		for (n1 = 0; n1 < 32; n1 = n1 + 1) begin
			cause[n1] <= 8'h00;
			irq[n1] <= 4'h8;
			core[n1] <= 'd0;
		end
	end
	else begin
		rste <= 32'h0;
		trig <= 32'h0;
		if (cs_io & wr_i) begin
			casez (adr_i[7:2])
			6'd0: ;
			6'd1:
				begin
					ie[31:0] <= dat_i[31:0];
				end
			6'd2,6'd3:
				ie[dat_i[4:0]] <= adr_i[2];
			6'd4:	es <= dat_i[31:0];
			6'd5:	rste[dat_i[4:0]] <= 1'b1;
			6'd6:	trig[dat_i[4:0]] <= 1'b1;
			6'b1?????:
			     begin
			     	 cause[adr_i[6:2]] <= dat_i[7:0];
			         irq[adr_i[6:2]] <= dat_i[11:8];
			         ie[adr_i[6:2]] <= dat_i[16];
			         es[adr_i[6:2]] <= dat_i[17];
			         intar[adr_i[6:2]] <= dat_i[19];
			         core[adr_i[6:2]] <= dat_i[29:24];
			     end
			endcase
		end
	end

// read registers
always_ff @(posedge clk)
begin
	if (irqenc!=5'd0)
		$display("PIC: %d",irqenc);
	if (cs_config)
		dat_o <= cfg_out;
	else if (cs_io)
		casez (adr_i[7:2])
		6'd0:	dat_o <= cause[irqenc];
		6'b1?????: dat_o <= {es[adr_i[6:2]],ie[adr_i[6:2]],4'b0,irq[adr_i[6:2]],cause[adr_i[6:2]]};
		default:	dat_o <= ie;
		endcase
	else if (cs_inta & intar[irqenc]) begin
		if (adr_i[3:1] <= irq[irqenc])
			dat_o <= {4{cause[irqenc]}};
		else
			dat_o <= {4{8'd24}};	// spurious interrupt
	end
	else
		dat_o <= 32'h0000;
end
always_ff @(posedge clk)
	if (cs_inta & ~intar[irqenc])
		vp_o <= 1'b1;
	else
		vp_o <= 1'b0;

always_ff @(posedge clk)
  irqo <= (irqenc == 5'h0) ? 4'd0 : irq[irqenc] & {4{ie[irqenc]}};
always_ff @(posedge clk)
  causeo <= (irqenc == 5'h0) ? 8'd0 : cause[irqenc];
always_ff @(posedge clk)
  core_o <= (irqenc == 5'h0) ? 6'd0 : core[irqenc];
always_ff @(posedge clk)
  nmio <= nmii & ie[0];

// Edge detect circuit
always_ff @(posedge clk)
begin
	for (n = 1; n < 32; n = n + 1)
	begin
		ib[n] <= i[n];
		if (trig[n]) iedge[n] <= 1'b1;
		if (i[n] & !ib[n]) iedge[n] <= 1'b1;
		if (rste[n]) iedge[n] <= 1'b0;
	end
end

// irq requests are latched on every rising clock edge to prevent
// misreads
// nmi is not encoded
always_ff @(posedge clk)
begin
	irqenc <= 5'd0;
	for (n2 = 31; n2 > 0; n2 = n2 - 1)
		if ((es[n2] ? iedge[n2] : i[n2])) irqenc <= n2;
end

endmodule
