// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  DIVIDE.sv
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

// Check for divide by zero
// Load the divider
rf80386_pkg::DIVIDE1:
	begin
		tGoto(rf80386_pkg::DIVIDE2);
		// Check for divide by zero
		if (w) begin
			if (cs_desc.db ? b[31:0]==32'h0000 : b[15:0]==16'h0000) begin
				$display("Divide by zero");
				int_num <= 8'h00;
				tGoto(rf80386_pkg::INT2);
			end
			else begin
				if (cs_desc.db)
					ld_div64 <= 1'b1;
				else
					ld_div32 <= 1'b1;
			end
		end
		else begin
			if (b[7:0]==8'h00) begin
				$display("Divide by zero");
				int_num <= 8'h00;
				tGoto(rf80386_pkg::INT2);
			end
			else
				ld_div16 <= 1'b1;
		end
	end
rf80386_pkg::DIVIDE2:
	begin
		$display("DIVIDE2");
		ld_div64 <= 1'b0;
		ld_div32 <= 1'b0;
		ld_div16 <= 1'b0;
		tGoto(rf80386_pkg::DIVIDE2a);
	end
rf80386_pkg::DIVIDE2a:
	begin
		$display("DIVIDE2a");
		if (w) begin
			if (cs_desc.db && div64_done)
				tGoto(rf80386_pkg::DIVIDE3);
			else if (!cs_desc.db && div32_done)
				tGoto(rf80386_pkg::DIVIDE3);
		end
		else if (!w & div16_done)
			tGoto(rf80386_pkg::DIVIDE3);
	end

// Assign results to registers
// Trap on divider overflow
rf80386_pkg::DIVIDE3:
	begin
		$display("DIVIDE3 state <= IFETCH");
		tGoto(rf80386_pkg::IFETCH);
		if (w) begin
			if (cs_desc.db) begin
				eax <= q64[31:0];
				edx <= r64[31:0];
			end
			else begin
				eax <= q32[15:0];
				edx <= r32[15:0];
			end
			if (cs_desc.db) begin
				if (TTT[0]) begin
					if (q64[63:32]!={32{q64[31]}}) begin
						$display("DIVIDE Overflow");
						int_num <= 8'h00;
						tGoto(rf80386_pkg::INT2);
					end
				end
				else begin
					if (q64[63:32]!=32'h0000) begin
						$display("DIVIDE Overflow");
						int_num <= 8'h00;
						tGoto(rf80386_pkg::INT2);
					end
				end
			end
			else begin
				if (TTT[0]) begin
					if (q32[31:16]!={16{q32[15]}}) begin
						$display("DIVIDE Overflow");
						int_num <= 8'h00;
						tGoto(rf80386_pkg::INT2);
					end
				end
				else begin
					if (q32[31:16]!=16'h0000) begin
						$display("DIVIDE Overflow");
						int_num <= 8'h00;
						tGoto(rf80386_pkg::INT2);
					end
				end
			end
		end
		else begin
			eax[ 7:0] <= q16[7:0];
			eax[15:8] <= r16;
			if (TTT[0]) begin
				if (q16[15:8]!={8{q16[7]}}) begin
					$display("DIVIDE Overflow");
					int_num <= 8'h00;
					tGoto(rf80386_pkg::INT2);
				end
			end
			else begin
				if (q16[15:8]!=8'h00) begin
					$display("DIVIDE Overflow");
					int_num <= 8'h00;
					tGoto(rf80386_pkg::INT2);
				end
			end
		end
	end
