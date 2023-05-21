// ============================================================================
//        __
//   \\__/ o\    (C) 2020-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_stlb_ad_state_machine.sv
//	- shared TLB state machine
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

module rfx32_stlb_ad_state_machine(clk, state, rcount, tlbadr_i, tlbadro, 
	tlbdat_rst, tlbdat_i, tlbdato, master_count, inv_count);
parameter ENTRIES = 1024;
parameter PAGE_SIZE = 8192;
parameter ASSOC = 9;
localparam LOG_ENTRIES = $clog2(ENTRIES);
localparam LOG_PAGE_SIZE = $clog2(PAGE_SIZE);
input clk;
input tlb_state_t state;
input [LOG_ENTRIES-1:0] rcount;
input [31:0] tlbadr_i;
output reg [LOG_ENTRIES-1:0] tlbadro;
input STLBE tlbdat_rst;
input STLBE tlbdat_i;
output STLBE tlbdato;
input [5:0] master_count;
input [LOG_ENTRIES-1:0] inv_count;

integer n2;

always_ff @(posedge clk)
begin
	case(state)
	ST_RST:	
		begin
			tlbadro <= rcount;
			tlbdato <= tlbdat_rst;
		end
	ST_RUN:
		begin
			tlbadro <= tlbadr_i[5+LOG_ENTRIES-1:5];
			tlbdato <= tlbdat_i;
			tlbdato.count <= master_count;
			tlbdato.lru <= 'd0;
		end
	ST_INVALL1,ST_INVALL2,ST_INVALL3,ST_INVALL4:
		begin
			tlbadro <= inv_count;
			tlbdato <= 'd0;
		end
	default:
		begin
			tlbadro <= tlbadr_i[5+LOG_ENTRIES-1:5];
			tlbdato <= tlbdat_i;
			tlbdato.count <= master_count;
			tlbdato.lru <= 'd0;
		end
	endcase
	if (tlbdato.pte.ppn=='d0 && tlbdato.vpn != 'd0) begin
		$display("PPN zero");
	end
end


endmodule
