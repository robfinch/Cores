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

rf80386_pkg::FETCH_DATA:
	begin
		ad <= ea;
		if (ltr)
			sel <= 16'h0003;
		else if (ir==`BOUND) begin
			if (cs_desc.db)
				sel <= 16'h00FF;
			else
				sel <= 16'h000F;
		end
		else begin
			if (cs_desc.db)
				sel <= w ? 16'h000F : 16'h0001;
			else
				sel <= w ? 16'h0003 : 16'h0001;
		end
		tGosub(rf80386_pkg::LOAD,rf80386_pkg::FETCH_DATA1);
	end
rf80386_pkg::FETCH_DATA1:
	begin
		if (cs_desc.db) begin
			if (ir==`BOUND) begin
				a <= dat[31:0];
				b <= dat[63:32];
				c <= rrro;
			end
			else if (w) begin
				if (d) begin
					a <= rrro;
					b[31:0] <= dat[31:0];
				end
				else begin
					b <= rrro;
					a[31:0] <= dat[31:0];
				end
			end
			else begin
				if (d) begin
					a <= rrro;
					b[ 7:0] <= dat[7:0];
					b[31:8] <= {24{dat[7]}};
				end
				else begin
					b <= rrro;
					a[ 7:0] <= dat[7:0];
					a[31:8] <= {24{dat[7]}};
				end
			end
		end
		else begin
			if (ir==`BOUND) begin
				a <= {{16{dat[15]}},dat[15:0]};
				b <= {[16{dat[31]}},dat[31:16]};
				c <= {{16{rrro[15]}},rrro[15:0]};
			end
			else if (w) begin
				if (d) begin
					a <= rrro;
					b[15:0] <= dat[15:0];
					b[31:16] <= {16{dat[15]}};
				end
				else begin
					b <= rrro;
					a[15:0] <= dat[15:0];
					a[31:16] <= {16{dat[15]}};
				end
			end
			else begin
				if (d) begin
					a <= rrro;
					b[ 7:0] <= dat[7:0];
					b[31:8] <= {24{dat[7]}};
				end
				else begin
					b <= rrro;
					a[ 7:0] <= dat[7:0];
					a[31:8] <= {24{dat[7]}};
				end
			end
		end
		case(ir)
		`IMULI8:tGoto(rf80386_pkg::FETCH_IMM8);
		`IMULI:	tGoto(rf80386_pkg::FETCH_IMM16);
		8'h80:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'h81:	tGoto(rf80386_pkg::FETCH_IMM16);
		8'h83:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'hC0:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'hC1:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'hC6:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'hC7:	tGoto(rf80386_pkg::FETCH_IMM16);
		8'hF6:	tGoto(rf80386_pkg::FETCH_IMM8);
		8'hF7:	tGoto(rf80386_pkg::FETCH_IMM16);
		default: tGoto(rf80386_pkg::EXECUTE);
		endcase
		hasFetchedData <= 1'b1;
	end
