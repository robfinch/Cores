// ============================================================================
//        __
//   \\__/ o\    (C) 2009-2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  FETCH_DISP16
//  - fetch 16 bit displacement
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

rf80386_pkg::FETCH_DISP16:
	begin
		if (cs_desc.db) begin
			disp32 <= bundle[31:0];
			bundle <= bundle[127:32];
			eip <= eip + 4'd4;
		end
		else begin
			disp32 <= {{16{bundle[15]}},bundle[15:0]};
			bundle <= bundle[127:16];
			eip <= eip + 4'd2;
		end
		tGoto(rf80386_pkg::FETCH_DISP16b);
	end

rf80386_pkg::FETCH_DISP16b:
	casez(ir)

	//-----------------------------------------------------------------
	// Flow control operations
	//-----------------------------------------------------------------
	`CALL: tGoto(rf80386_pkg::CALL);
	`JMP: begin eip <= eip + disp16; tGoto(rf80386_pkg::IFETCH); end
	`JMPS: begin eip <= eip + disp16; tGoto(rf80386_pkg::IFETCH); end

	//-----------------------------------------------------------------
	// Memory Operations
	//-----------------------------------------------------------------
	
	`MOV_AL2M,`MOV_AX2M:
		begin
			res <= eax;
			ea <= seg_reg + disp16;
			tGoto(rf80386_pkg::STORE_DATA);
		end
	`MOV_M2AL,`MOV_M2AX:
		begin
			d <= 1'b0;
			rrr <= 3'd0;
			ea <= seg_reg + disp16;
			tGoto(rf80386_pkg::FETCH_DATA);
		end

	`MOV_MA:
		if (hasFetchedData) begin
			ir <= {4'b0,w,3'b0};
			wrregs <= 1'b1;
			res <= disp16;
			tGoto(rf80386_pkg::IFETCH);
		end
		//else?

	`MOV_AM:
		begin
			w <= ir[0];
			tGoto(rf80386_pkg::STORE_DATA);
			ea  <= ds_base + disp16;
			res <= ir[0] ? eax : {al,al,al,al};
		end
	default:	tGoto(rf80386_pkg::IFETCH);
	endcase
