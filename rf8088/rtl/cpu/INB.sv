// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INB.v
//  - Fetch data from IO.
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

INB:
	begin
		ip <= ip_inc;
		ea <= {12'h00,bundle[7:0]};
		tRead({12'h00,bundle[7:0]});
		ftam_req.cti <= fta_bus_pkg::IO;
		cyc_done <= FALSE;
		tGoto(INB3);
	end
INB2:	// Alternate entry point
	begin
		tRead(ea);
		ftam_req.cti <= fta_bus_pkg::IO;
		cyc_done <= FALSE;
		tGoto(INB3);
	end
INB3:
	if (ack_i) begin
		res[7:0] <= dat_i;
		w <= 1'b0;
		rrr <= 3'd0;
		wrregs <= 1'b1;
		tGoto(IFETCH);
	end
	else if (rty_i && !cyc_done) begin
		tRead(ea);
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else
		cyc_done <= TRUE;
