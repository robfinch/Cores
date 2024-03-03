// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
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

OUTSB:
`include "check_for_ints.sv"
	else if (repdone)
		tGoto(rf8088_pkg::IFETCH);
	else begin
		tRead(dssi);
		cyc_done <= FALSE;
		tGoto(OUTSB1);
	end
OUTSB1:
	if (ack_i) begin
		res[7:0] <= dat_i;
		tGoto(OUTSB2);
	end
	else if (rty_i && !cyc_done)
		tRead(dssi);
	else
		cyc_done <= TRUE;
OUTSB2:
	begin
		tWrite({`SEG_SHIFT,dx},res[7:0]);
		ftam_req.cti <= fta_bus_pkg::IO;
		tGoto(OUTSB3);
	end
OUTSB3:
	if (rty_i) begin
		tWrite({`SEG_SHIFT,dx},res[7:0]);
		ftam_req.cti <= fta_bus_pkg::IO;
	end
	else begin
		if (df)
			si <= si - 16'd1;
		else
			si <= si + 16'd1;
		if (repz|repnz)
			cx <= cx_dec;
		tGoto(repz|repnz ? OUTSB : rf8088_pkg::IFETCH);
	end
