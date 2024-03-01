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

FETCH_DISP16:
	begin
		disp16 <= bundle[15:0];
		bundle <= bundle[127:16];
		tGoto(FETCH_DISP16b);
	end

FETCH_DISP16b:
	casez(ir)

	//-----------------------------------------------------------------
	// Flow control operations
	//-----------------------------------------------------------------
	`CALL: tGoto(CALL);
	`JMP: begin ip <= ip + disp16; tGoto(IFETCH); end
	`JMPS: begin ip <= ip + disp16; tGoto(IFETCH); end

	//-----------------------------------------------------------------
	// Memory Operations
	//-----------------------------------------------------------------
	
	`MOV_AL2M,`MOV_AX2M:
		begin
			res <= ax;
			ea <= {seg_reg,`SEG_SHIFT} + disp16;
			tGoto(STORE_DATA);
		end
	`MOV_M2AL,`MOV_M2AX:
		begin
			d <= 1'b0;
			rrr <= 3'd0;
			ea <= {seg_reg,`SEG_SHIFT} + disp16;
			tGoto(FETCH_DATA);
		end

	`MOV_MA:
		case(substate)
		FETCH_DATA:
			if (hasFetchedData) begin
				ir <= {4'b0,w,3'b0};
				wrregs <= 1'b1;
				res <= disp16;
				tGoto(IFETCH);
			end
		endcase

	`MOV_AM:
		begin
			w <= ir[0];
			tGoto(STORE_DATA);
			ea  <= {ds,`SEG_SHIFT} + disp16;
			res <= ir[0] ? {ah,al} : {al,al};
		end
	default:	tGoto(IFETCH);
	endcase
