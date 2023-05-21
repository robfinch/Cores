// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_stlb_active_region.sv
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

import fta_bus_pkg::*;
import rfx32pkg::*;
import rfx32Mmupkg::*;

module rfx32_stlb_active_region(rst, clk, cs_rgn, rgn, wbs_req, dato, region_num, region, sel, err);
input rst;
input clk;
input cs_rgn;
input [2:0] rgn;
input fta_cmd_request128_t wbs_req;
output reg [127:0] dato;
output reg [3:0] region_num;
output REGION region;
output reg [7:0] sel;
output reg err;
localparam ABITS = $bits(fta_address_t);

parameter IO_ADDR = 32'hFEEF0001;
parameter IO_ADDR_MASK = 32'h00FF0000;

parameter CFG_BUS = 8'd0;
parameter CFG_DEVICE = 5'd12;
parameter CFG_FUNC = 3'd0;
parameter CFG_VENDOR_ID	=	16'h0;
parameter CFG_DEVICE_ID	=	16'h0;
parameter CFG_SUBSYSTEM_VENDOR_ID	= 16'h0;
parameter CFG_SUBSYSTEM_ID = 16'h0;
parameter CFG_ROM_ADDR = 32'hFFFFFFF0;

parameter CFG_REVISION_ID = 8'd0;
parameter CFG_PROGIF = 8'd1;
parameter CFG_SUBCLASS = 8'h00;					// 00 = RAM
parameter CFG_CLASS = 8'h05;						// 05 = memory controller
parameter CFG_CACHE_LINE_SIZE = 8'd8;		// 32-bit units
parameter CFG_MIN_GRANT = 8'h00;
parameter CFG_MAX_LATENCY = 8'h00;
parameter CFG_IRQ_LINE = 8'hFF;

localparam CFG_HEADER_TYPE = 8'h00;			// 00 = a general device


integer n;
REGION [7:0] pma_regions;

initial begin
	// ROM
	pma_regions[7].pmt	= 48'h00000000;
	pma_regions[7].cta	= 48'h00000000;
	pma_regions[7].at 	= 'h0;			// rom, byte address table, cache-read-execute
	pma_regions[7].at[0].rwx = 4'hD;
	pma_regions[7].at[1].rwx = 4'hD;
	pma_regions[7].at[2].rwx = 4'hD;
	pma_regions[7].at[3].rwx = 4'hD;
	pma_regions[7].lock = "LOCK";

	// IO
	pma_regions[6].pmt	 = 48'h00000300;
	pma_regions[6].cta	= 48'h00000000;
	pma_regions[6].at 	= 'h0;
	pma_regions[6].at[0].rwx = 4'h6;
	pma_regions[6].at[1].rwx = 4'h6;
	pma_regions[6].at[2].rwx = 4'h6;
	pma_regions[6].at[3].rwx = 4'h6;
//	pma_regions[6].at = 20'h00206;		// io, (screen) byte address table, read-write
	pma_regions[6].lock = "LOCK";

	// Config space
	pma_regions[5].pmt	 = 48'h00000000;
	pma_regions[5].cta	= 48'h00000000;
	pma_regions[5].at 	= 'h0;
	pma_regions[5].at[0].rwx = 4'h6;
	pma_regions[5].at[1].rwx = 4'h6;
	pma_regions[5].at[2].rwx = 4'h6;
	pma_regions[5].at[3].rwx = 4'h6;
	pma_regions[5].lock = "LOCK";

	// Scratchpad RAM
	pma_regions[4].pmt	 = 48'h00002300;
	pma_regions[4].cta	= 48'h00000000;
	pma_regions[4].at 	= 'h0;
	pma_regions[4].at[0].rwx = 4'hF;
	pma_regions[4].at[1].rwx = 4'hF;
	pma_regions[4].at[2].rwx = 4'hF;
	pma_regions[4].at[3].rwx = 4'hF;
//	pma_regions[4].at = 20'h0020F;		// byte address table, read-write-execute cacheable
	pma_regions[4].lock = "LOCK";

	// vacant
	pma_regions[3].pmt	 = 48'h00000000;
	pma_regions[3].cta	= 48'h00000000;
	pma_regions[3].at 	= 'h0;
	pma_regions[3].at[0].dev_type = 8'hFF;		// no access
	pma_regions[3].at[1].dev_type = 8'hFF;		// no access
	pma_regions[3].at[2].dev_type = 8'hFF;		// no access
	pma_regions[3].at[3].dev_type = 8'hFF;		// no access
	pma_regions[3].lock = "LOCK";

	// vacant
	pma_regions[2].pmt	 = 48'h00000000;
	pma_regions[2].cta	= 48'h00000000;
	pma_regions[2].at 	= 'h0;
//	pma_regions[2].at = 20'h0FF00;		// no access
	pma_regions[3].at[0].dev_type = 8'hFF;		// no access
	pma_regions[3].at[1].dev_type = 8'hFF;		// no access
	pma_regions[3].at[2].dev_type = 8'hFF;		// no access
	pma_regions[3].at[3].dev_type = 8'hFF;		// no access
	pma_regions[2].lock = "LOCK";

	// DRAM
	pma_regions[1].pmt	 = 48'h00002400;
	pma_regions[1].cta	= 48'h00000000;
	pma_regions[1].at 	= 'h0;
	pma_regions[1].at[0].rwx = 4'hF;
	pma_regions[1].at[1].rwx = 4'hF;
	pma_regions[1].at[2].rwx = 4'hF;
	pma_regions[1].at[3].rwx = 4'hF;
	pma_regions[1].at[0].dev_type = 8'h01;		// no access
	pma_regions[1].at[1].dev_type = 8'h01;		// no access
	pma_regions[1].at[2].dev_type = 8'h01;		// no access
	pma_regions[1].at[3].dev_type = 8'h01;		// no access
//	pma_regions[1].at = 20'h0010F;	// ram, byte address table, cache-read-write-execute
	pma_regions[1].lock = "LOCK";

	// vacant
	pma_regions[0].pmt	 = 48'h00000000;
	pma_regions[0].cta	= 48'h00000000;
	pma_regions[0].at 	= 'h0;
	pma_regions[0].at[0].dev_type = 8'hFF;		// no access
	pma_regions[0].at[1].dev_type = 8'hFF;		// no access
	pma_regions[0].at[2].dev_type = 8'hFF;		// no access
	pma_regions[0].at[3].dev_type = 8'hFF;		// no access
	pma_regions[0].lock = "LOCK";

end

always_ff @(posedge clk)
	if (cs_rgn && wbs_req.we && wbs_req.cyc && wbs_req.stb) begin
		if (pma_regions[wbs_req.padr[8:6]].lock=="UNLK" || wbs_req.padr[5:4]==2'h3) begin
			case(wbs_req.padr[5:4])
			2'd0:	pma_regions[wbs_req.padr[8:6]].pmt[ABITS-1: 0] <= wbs_req.data1[ABITS-1:0];
			2'd1:	pma_regions[wbs_req.padr[8:6]].cta[ABITS-1: 0] <= wbs_req.data1[ABITS-1:0];
			2'd2:	pma_regions[wbs_req.padr[8:6]].at <= wbs_req.data1;
			2'd3: pma_regions[wbs_req.padr[8:6]].lock <= wbs_req.data1;
			default:	;
			endcase
		end
	end
always_ff @(posedge clk)
if (cs_rgn && wbs_req.cyc && wbs_req.stb)
	case(wbs_req.padr[5:4])
	2'd0:	dato <= pma_regions[wbs_req.padr[8:6]].pmt;
	2'd1:	dato <= pma_regions[wbs_req.padr[8:6]].cta;
	2'd2:	dato <= pma_regions[wbs_req.padr[8:6]].at;
	2'd3:	dato <= pma_regions[wbs_req.padr[8:6]].lock;
	default:	dato <= 'd0;
	endcase
else
	dato <= 'd0;

always_comb
begin
	err = 1'b1;
	region_num = 4'd0;
	region = pma_regions[0];
	sel = 'd0;
	region = pma_regions[rgn];
	region_num = rgn;
	sel[rgn] = 1'b1;
	err = 1'b0;
end    	
    	
endmodule

