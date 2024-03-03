// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  LODS
//  Fetch string data from memory.
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

LODS:
	if (w && (cs_desc.db ? esi>32'hFFFFFFFC : si==16'hFFFF) && !df) begin
		ir <= `NOP;
		int_num <= 8'd13;
		tGoto(INT2);
	end
	else begin
		ad <= seg_reg + (cs_desc.sb ? esi : si);
		sel <= w ? (cs_desc.db ? 16'h000F : 16'h0003) : 16'h0001;
		tGosub(LOAD,LODS_NACK);
	end
LODS_NACK:
	if (df) begin
		if (w) begin
			if (cs_desc.db) begin
				esi <= esi - 4'd4;
				b[31:0] <= dat;
			end
			else begin
				b[15:0] <= {16{dat[15]}},dat[15:0]};
				esi <= esi - 4'd2;
			end
		end
		else begin
			esi <= esi - 2'd1;
			b[ 7:0] <= dat[7:0];
			b[31:8] <= {24{dat[7]}};
		end
	end
	else begin
		si <= si_inc;
		if (w) begin
			if (cs_desc.db) begin
				esi <= esi + 4'd4;
				b[31:0] <= dat[31:0];
			end
			else begin
				esi <= esi + 4'd2;
				b[15:0] <= dat[15:0];
				b[31:16] <= {16{dat[15]}};
			end
		end
		else begin
			esi <= esi + 2'd1;
			b[ 7:0] <= dat;
			b[15:8] <= {8{dat[7]}};
		end
	end
	tGoto(rf8088_pkg::EXECUTE);
end
	