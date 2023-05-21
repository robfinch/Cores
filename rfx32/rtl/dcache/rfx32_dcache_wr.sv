// ============================================================================
//        __
//   \\__/ o\    (C) 2021-2023  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rfx32_dcache_wr.sv
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

import rfx32pkg::*;
import rfx32_cache_pkg::*;

module rfx32_dcache_wr(clk, state, wr_dc, ack, req, dce, hit, hit2, inv, acr, wr, sel);
input clk;
input [6:0] state;
input wr_dc;
input ack;
input memory_arg_t req;
input dce;
input hit;
input hit2;
input inv;
input [3:0] acr;
output reg wr;
parameter WID = 768;
output reg [WID/8-1:0] sel;

always_ff @(posedge clk)
begin
	wr <= 1'b0;
	case(state)
	MEMORY_UPD1:
		if (hit2 && (req.func==MR_STORE || req.func==MR_MOVST)) begin
			wr <= acr[3];	// must be cachable data for cache to update
			sel <= {WID/8{1'b1}};
		end
	MEMORY_UPD2:
		if (hit2 && (req.func==MR_STORE || req.func==MR_MOVST)) begin
			wr <= acr[3];
			sel <= {WID/8{1'b1}};
		end
	/*
	DFETCH7:
		begin
	  	if (daeo)
	  		wr <= acr[3];
	  end
	*/
	IPT_RW_PTG4:
		if (!inv && (dce & hit) && req.func==MR_STORE && ack)
			wr <= 1'b1;
	default:	;
	endcase
	if (wr_dc) begin
 		wr <= 1'b1;//acr[3];
 		sel <= req.sel|((32'hFFFFFFFF) << DCacheLineWidth);
 	end
end

endmodule
