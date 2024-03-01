// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  FETCH_DATA
//  Fetch data from memory.
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

FETCH_DATA:
	begin
		tRead(ea);
		cyc_done <= FALSE;
		tGoto(FETCH_DATA1);
	end
FETCH_DATA1:
	if (ack_i) begin
		if (d) begin
			a <= rrro;
			b[ 7:0] <= dat_i;
			b[15:8] <= {8{dat_i[7]}};
		end
		else begin
			b <= rrro;
			a[ 7:0] <= dat_i;
			a[15:8] <= {8{dat_i[7]}};
		end
		if (w)
			tGoto(FETCH_DATA2);
		else begin
			case(ir)
			8'h80:	tGoto(FETCH_IMM8);
			8'h81:	tGoto(FETCH_IMM16);
			8'h83:	tGoto(FETCH_IMM8);
			8'hC0:	tGoto(FETCH_IMM8);
			8'hC1:	tGoto(FETCH_IMM8);
			8'hC6:	tGoto(FETCH_IMM8);
			8'hC7:	tGoto(FETCH_IMM16);
			8'hF6:	tGoto(FETCH_IMM8);
			8'hF7:	tGoto(FETCH_IMM16);
			default: tGoto(EXECUTE);
			endcase
			hasFetchedData <= 1'b1;
		end
	end
	else if (rty_i && !cyc_done)
		tRead(ea);
	else
		cyc_done <= TRUE;
FETCH_DATA2:
	begin
		cyc_type <= `CT_RDMEM;
		tRead(ea_inc);
		cyc_done <= FALSE;
		tGoto(FETCH_DATA3);
	end
FETCH_DATA3:
	if (ack_i) begin
		if (d)
			b[15:8] <= dat_i;
		else
			a[15:8] <= dat_i;
		case(ir)
		8'h80:	state <= FETCH_IMM8;
		8'h81:	state <= FETCH_IMM16;
		8'h83:	state <= FETCH_IMM8;
		8'hC0:	state <= FETCH_IMM8;
		8'hC1:	state <= FETCH_IMM8;
		8'hC6:	state <= FETCH_IMM8;
		8'hC7:	state <= FETCH_IMM16;
		8'hF6:	state <= FETCH_IMM8;
		8'hF7:	state <= FETCH_IMM16;
		default: state <= EXECUTE;
		endcase
		hasFetchedData <= 1'b1;
	end
	else if (rty_i && !cyc_done)
		tRead(ea_inc);
	else
		cyc_done <= TRUE;
