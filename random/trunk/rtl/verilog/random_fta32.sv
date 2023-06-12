// ============================================================================
//        __
//   \\__/ o\    (C) 2011-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// random_fta32.sv
//     Multi-stream random number generator.
//
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
// 	Reg no.
//	00			read: random output bits [31:0], write: gen next number	
//  04           random stream number
//  08           m_z seed setting bits [31:0]
//  0C           m_w seed setting bits [31:0]
//
//  +- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|WISHBONE Datasheet
//	|WISHBONE SoC Architecture Specification, Revision B.3
//	|
//	|Description:						Specifications:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|General Description:				random number generator
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported Cycles:					SLAVE,READ/WRITE
//	|									SLAVE,BLOCK READ/WRITE
//	|									SLAVE,RMW
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Data port, size:					32 bit
//	|Data port, granularity:			32 bit
//	|Data port, maximum operand size:	32 bit
//	|Data transfer ordering:			Undefined
//	|Data transfer sequencing:			Undefined
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Clock frequency constraints:		none
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Supported signal list and			Signal Name		WISHBONE equiv.
//	|cross reference to equivalent		ack_o			ACK_O
//	|WISHBONE signals					adr_i[31:0]		ADR_I()
//	|									clk_i			CLK_I
//	|                                   rst_i           RST_I()
//	|									dat_i(31:0)		DAT_I()
//	|									dat_o(31:0)		DAT_O()
//	|									cyc_i			CYC_I
//	|									stb_i			STB_I
//	|									we_i			WE_I
//	|
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//	|Special requirements:
//	+- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// 257 LUTs / 309 FFs / 2 BRAMs / 2 DSP
// ============================================================================
//
// Uses George Marsaglia's multiply method
//
// m_w = <choose-initializer>;    /* must not be zero */
// m_z = <choose-initializer>;    /* must not be zero */
//
// uint get_random()
// {
//     m_z = 36969 * (m_z & 65535) + (m_z >> 16);
//     m_w = 18000 * (m_w & 65535) + (m_w >> 16);
//     return (m_z << 16) + m_w;  /* 32-bit result */
// }
//
import fta_bus_pkg::*;

`define TRUE	1'b1
`define FALSE	1'b0

module random_fta32(rst_i, clk_i, cs_config_i, cs_io_i, req, resp);
input rst_i;
input clk_i;
input cs_config_i;
input cs_io_i;
input fta_cmd_request32_t req;
output fta_cmd_response32_t resp;
parameter pAckStyle = 1'b0;

parameter IO_ADDR = 32'hFEE10001;
parameter IO_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd8;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h00;					// 00 = non VGA compatiable unclassfied device
parameter CFG_CLASS = 8'h00;						// 00 = unclassified
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device

parameter MSIX = 1'b0;

reg ack;
reg cs;
reg we;
reg [3:0] sel;
reg [31:0] adr;
reg [31:0] dat, dat_o;
reg cs_rand;
wire [31:0] cfg_out;
wire cs_io;

reg cs_config;
fta_request32_t reqd;

always_ff @(posedge clk_i)
	cs_config <= cs_config_i & req.cyc & req.stb &&
		req.padr[27:20]==CFG_BUS &&
		req.padr[19:15]==CFG_DEVICE &&
		req.padr[14:12]==CFG_FUNC;

always_ff @(posedge clk_i)
	cs_rand <= cs_io_i && req.cyc && req.stb && cs_io;
always_ff @(posedge clk_i)
	we <= req.we;
always_ff @(posedge clk_i)
	sel <= 4'b1111;
always_ff @(posedge clk_i)
	adr <= req.adr;
always_ff @(posedge clk_i)
	dat <= req.dat;
always_ff @(posedge clk_i)
	reqd <= req;

always_ff @(posedge clk_i)
	resp.ack <= (cs_rand|cs_config) & reqd.cyc & reqd.stb;
always_ff @(posedge clk_i)
	resp.adr <= reqd.padr;
assign resp.next = 1'b0;
assign resp.stall = 1'b0;
assign resp.rty = 1'b0;
assign resp.err = 1'b0;
assign resp.pri = 4'd7;
assign resp.dat = dat_o;


//always @*
//	ack_o <= cs ? ack : pAckStyle;

pci32_config #(
	.CFG_BUS(CFG_BUS),
	.CFG_DEVICE(CFG_DEVICE),
	.CFG_FUNC(CFG_FUNC),
	.CFG_VENDOR_ID(CFG_VENDOR_ID),
	.CFG_DEVICE_ID(CFG_DEVICE_ID),
	.CFG_BAR0(IO_ADDR),
	.CFG_BAR0_MASK(IO_ADDR_MASK),
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
	.we_i(we),
	.sel_i(sel),
	.adr_i(adr),
	.dat_i(dat),
	.dat_o(cfg_out),
	.cs_bar0_o(cs_io),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_en_o()
);


reg [9:0] stream;
reg [31:0] next_m_z;
reg [31:0] next_m_w;
reg [31:0] out;
reg wrw, wrz;
reg [31:0] w=32'd3,z=32'd17;
wire [31:0] m_zs;
wire [31:0] m_ws;
wire pe_we;

edge_det ued1 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(we), .pe(pe_we), .ne(), .ee());
rand_ram u1 (clk_i, wrw, stream, w, m_ws);
rand_ram u2 (clk_i, wrz, stream, z, m_zs);

always_comb
begin
	next_m_z = (32'h36969 * m_zs[15:0]) + m_zs[31:16];
	next_m_w = (32'h18000 * m_ws[15:0]) + m_ws[31:16];
end

// Register read path
//
always_ff @(posedge clk_i)
if (cs_config)
	dat_o <= cfg_out;
else if (cs_rand)
	case(adr[3:2])
	2'd0:	dat_o <= {m_zs[15:0],16'd0} + m_ws;
	2'd1:	dat_o <= {22'h0,stream};
// Uncomment these for register read-back
//		3'd4:	dat_o <= m_z[31:16];
//		3'd5:	dat_o <= m_z[15: 0];
//		3'd6:	dat_o <= m_w[31:16];
//		3'd7:	dat_o <= m_w[15: 0];
	default:	dat_o <= 32'h0000;
	endcase
else
	dat_o <= 32'h0;

// Register write path
//
always_ff @(posedge clk_i)
begin
	wrw <= `FALSE;
	wrz <= `FALSE;
	if (cs_rand) begin
		if (pe_we)
			case(adr[3:2])
			2'd0:
				begin
					z <= next_m_z;
					w <= next_m_w;
					wrw <= `TRUE;
					wrz <= `TRUE;
				end
			2'd1:	stream <= dat[9:0];
			2'd2:	begin z <= dat; wrz <= `TRUE; end
			2'd3:	begin w <= dat; wrw <= `TRUE; end
			endcase
	end
end

endmodule


// Tools were inferring a massive distributed ram so we help them out a bit by
// creating an explicit ram definition.

module rand_ram(clk, wr, ad, i, o);
input clk;
input wr;
input [9:0] ad;
input [31:0] i;
output [31:0] o;

reg [31:0] ri;
reg [9:0] regadr;
reg regwr;
(* RAM_STYLE="BLOCK" *)
reg [31:0] mem [0:1023];

always_ff @(posedge clk)
	regadr <= ad;
always_ff @(posedge clk)
	regwr <= wr;
always_ff @(posedge clk)
	ri <= i;
always_ff @(posedge clk)
	if (regwr)
		mem[regadr] <= ri;
assign o = mem[regadr];

endmodule
