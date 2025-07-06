// ============================================================================
//        __
//   \\__/ o\    (C) 2025  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// ============================================================================
//
import wishbone_pkg::*;

module i2c_master(rst_i, clk_i, irq_o, irq_chain_i, irq_chain_o, cs_i,
	wbs_req_i, wbs_resp_o,
	scl_pad_i, scl_pad_o, scl_padoen_o, sda_pad_i, sda_pad_o, sda_padoen_o);
input rst_i;
input clk_i;
output irq_o;
input [15:0] irq_chain_i;
output [15:0] irq_chain_o;
input cs_i;
input wb_cmd_request32_t wbs_req_i;
output wb_cmd_response32_t wbs_resp_o;
input scl_pad_i;
output scl_pad_o;
output scl_padoen_o;
input sda_pad_i;
output sda_pad_o;
output sda_padoen_o;

parameter pReverseByteOrder = 1'b0;
parameter pDevName = "I2C_MASTER      ";

parameter CFG_BUS = 6'd0;
parameter CFG_DEVICE = 5'd16;
parameter CFG_FUNC = 3'd4;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter IO_ADDR = 32'hFDFE8000;
parameter CFG_BAR1 = 32'h1;
parameter CFG_BAR2 = 32'h1;
parameter IO_ADDR_MASK = 32'hFFFFC000;
parameter CFG_BAR1_MASK = 32'h0;
parameter CFG_BAR2_MASK = 32'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd255;
parameter CFG_SUBCLASS = 8'h0;					// 0 = serial I/O
parameter CFG_CLASS = 8'h07;						// 07 = simple communication controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'd16;
parameter CFG_IRQ_DEVICE = 8'd0;
parameter CFG_IRQ_CORE = 6'd0;
parameter CFG_IRQ_CHANNEL = 3'd0;
parameter CFG_IRQ_PRIORITY = 4'd4;
parameter CFG_IRQ_CAUSE = 8'd0;

parameter CFG_ROM_FILENAME = "ddbb32_config.mem";

function [31:0] fnRbo32;
input [31:0] i;
begin
	fnRbo32 = {i[7:0],i[15:8],i[23:16],i[31:24]};
end
endfunction

wire cs;
wire i2c_ack;
wire [7:0] i2c_dato;
wb_cmd_request32_t wbs_req;
wb_cmd_response32_t wbs_resp;
wb_cmd_response32_t ddbb_resp;

always_comb
begin
	wbs_req = wbs_req_i;
	wbs_resp_o = wbs_resp;
	if (pReverseByteOrder) begin
		wbs_req.dat = fnRbo32(wbs_req_i.dat);
		wbs_resp_o.dat = fnRbo32(wbs_resp.dat);
	end
end

ddbb32_config #(
	.pDevName(pDevName),
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
uddbb1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.irq_i(),
	.cs_i(cs_i),
	.resp_busy_i(),
	.req_i(wbs_req),
	.resp_o(ddbb_resp),
	.cs_bar0_o(cs),
	.cs_bar1_o(),
	.cs_bar2_o(),
	.irq_chain_i(irq_chain_i),
	.irq_chain_o(irq_chain_o)
);

always_comb
begin
	if (cs_i)
		wbs_resp = ddbb_resp;
	else if (cs) begin
		wbs_resp = {$bits(wb_cmd_response32_t){1'b0}};
		wbs_resp.dat = {4{i2c_dato}};
		wbs_resp.ack = i2c_ack;
	end
	else
		wbs_resp = {$bits(wb_cmd_response32_t){1'b0}};
end

i2c_master_top ui2cm
(
	.wb_clk_i(clk_i),
	.wb_rst_i(rst_i),
	.arst_i(~rst_i),
	.wb_adr_i(wbs_req.adr[2:0]),
	.wb_dat_i(wbs_req.dat[7:0]),
	.wb_dat_o(i2c_dato),
	.wb_we_i(wbs_req.we),
	.wb_stb_i(cs),
	.wb_cyc_i(wbs_req.cyc),
	.wb_ack_o(i2c_ack),
	.wb_inta_o(irq_o),
	.scl_pad_i(scl_pad_i),
	.scl_pad_o(scl_pad_o),
	.scl_padoen_o(scl_padoen_o),
	.sda_pad_i(sda_pad_i),
	.sda_pad_o(sda_pad_o), 
	.sda_padoen_o(sda_padoen_o)
);

endmodule
