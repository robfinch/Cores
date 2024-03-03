// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  INSB
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

INSB:
`include "check_for_ints.v"
	else if (repdone)
		tGoto(IFETCH);
	else begin
		tRead({`SEG_SHIFT,dx});
		cyc_done <= FALSE;
		ftam_req.cti <= fta_bus_pkg::IO;
		tGoto(INSB1);
	end
INSB1:
	if (ack_i) begin
		res[7:0] <= dat_i;
		tGoto(INSB2);
	end
	else if (rty_i && !cyc_done) begin
		tRead({`SEG_SHIFT,dx});
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else
		cyc_done <= TRUE;
INSB2:
	begin
		tWrite(esdi,res[7:0]);
		ftam_req.cti <= fta_bus_pkg::IO;
		tGoto(INSB3);
	end
INSB3:
	if (rty_i) begin
		tWrite(esdi,res[7:0]);
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else begin
		if (df)
			di <= di - 16'd1;
		else
			di <= di + 16'd1;
		if (repz|repnz)
			cx <= cx_dec;
		tGoto(repz|repnz ? INSB : IFETCH);
	end
