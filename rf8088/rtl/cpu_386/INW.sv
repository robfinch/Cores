// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INW.v
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

INW:
	begin
		ip <= ip_inc;
		ea <= {12'h000,bundle[7:0]};
		tRead({12'h000,bundle[7:0]});
		ftam_req.cti <= fta_bus_pkg::IO;
		cyc_done <= FALSE;
		tGoto(INW3);
	end
INW2:	// alternate entry point
	begin
		tRead(ea);
		ftam_req.cti <= fta_bus_pkg::IO;
		cyc_done <= FALSE;
		tGoto(INW3);
	end
INW3:
	if (ack_i) begin
		res[7:0] <= dat_i;
		tGoto(INW4);
	end
	else if (rty_i && !cyc_done) begin
		tRead(ea);
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else
		cyc_done <= TRUE;
INW4:
	begin
		ea <= ea_inc;
		tRead(ea_inc);
		ftam_req.cti <= fta_bus_pkg::IO;
		cyc_done <= FALSE;
		tGoto(INW5);
	end
INW5:
	if (ack_i) begin
		wrregs <= 1'b1;
		w <= 1'b1;
		rrr <= 3'd0;
		res[15:8] <= dat_i;
		tGoto(rf8088_pkg::IFETCH);
	end
	else if (rty_i && !cyc_done) begin
		tRead(ea);
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else
		cyc_done <= TRUE;
