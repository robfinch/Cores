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
//
//  EACALC
//  - calculation of effective address
//
// - the effective address calculation may need to fetch an additional
//   eight or sixteen bit displacement value in order to calculate the
//   effective address.
// - the EA calc only needs to be done once as there is only ever a 
//   single memory operand address. Once the EA is calculated it is
//   used for both the fetch and the store when memory is the target.
// ============================================================================
//
EACALC:
	begin

		disp16 <= 16'h0000;

		case(mod)

		2'b00:
			begin
				tGoto(EACALC1);
				// ToDo: error on stack state
				case(rm)
				3'd0:	offset <= bx + si;
				3'd1:	offset <= bx + di;
				3'd2:	offset <= bp + si;
				3'd3:	offset <= bp + di;
				3'd4:	offset <= si;
				3'd5:	offset <= di;
				3'd6:	
					begin
						tGoto(EACALC_DISP16);
						offset <= 16'h0000;
					end
				3'd7:	offset <= bx;
				endcase
			end

		2'b01:
			begin
				tGoto(EACALC_DISP8);
				case(rm)
				3'd0:	offset <= bx + si;
				3'd1:	offset <= bx + di;
				3'd2:	offset <= bp + si;
				3'd3:	offset <= bp + di;
				3'd4:	offset <= si;
				3'd5:	offset <= di;
				3'd6:	offset <= bp;
				3'd7:	offset <= bx;
				endcase
			end

		2'b10:
			begin
				tGoto(EACALC_DISP16);
				case(rm)
				3'd0:	offset <= bx + si;
				3'd1:	offset <= bx + di;
				3'd2:	offset <= bp + si;
				3'd3:	offset <= bp + di;
				3'd4:	offset <= si;
				3'd5:	offset <= di;
				3'd6:	offset <= bp;
				3'd7:	offset <= bx;
				endcase
			end

		2'b11:
			begin
				tGoto(EXECUTE);
				case(ir)
				`MOV_I8M:
					begin
						rrr <= rm;
						if (rrr==3'd0) tGoto(FETCH_IMM8);
					end
				`MOV_I16M:
					begin
						rrr <= rm;
						if (rrr==3'd0) tGoto(FETCH_IMM16);
					end
				`MOV_S2R:
					begin
						a <= rfso;
						b <= rfso;
					end
				`MOV_R2S:
					begin
						a <= rmo;
						b <= rmo;
					end
				`POP_MEM:
					begin
						ir <= 8'h58|rm;
						tGoto(POP);
					end
				`XCHG_MEM:
					begin
						wrregs <= 1'b1;
						res <= rmo;
						b <= rrro;
					end
				// shifts and rotates
				8'hD0,8'hD1,8'hD2,8'hD3:
					begin
						b <= rmo;
					end
				// The TEST instruction is the only one needing to fetch an immediate value.
				8'hF6,8'hF7:
					// 000 = TEST
					// 010 = NOT
					// 011 = NEG
					// 100 = MUL
					// 101 = IMUL
					// 110 = DIV
					// 111 = IDIV
					if (rrr==3'b000) begin	// TEST
						a <= rmo;
						tGoto(w ? FETCH_IMM16 : FETCH_IMM8);
					end
					else
						b <= rmo;
				default:
				    begin
						if (d) begin
							a <= rmo;
							b <= rrro;
						end
						else begin
							a <= rrro;
							b <= rmo;
						end
					end
				endcase
				hasFetchedData <= 1'b1;
			end
		endcase
	end

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Fetch 16 bit displacement
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EACALC_DISP16:
	begin
		disp16[15:0] <= bundle[15:0];
		bundle <= bundle[127:16];
		tGoto(EACALC1);
	end

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Fetch 8 bit displacement
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EACALC_DISP8:
	begin
		disp16 <= {{8{dat_i[7]}},dat_i};
		bundle <= bundle[127:8];
		tGoto(EACALC1);
	end


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Add the displacement into the effective address
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EACALC1:
	begin
		casez(ir)
		`EXTOP:
			casez(ir2)
			8'h00:
				begin
					case(rrr)
					3'b010: tGoto(FETCH_DESC);	// LLDT
					3'b011: tGoto(FETCH_DATA);	// LTR
					default: tGoto(FETCH_DATA);
					endcase
					if (w && (offsdisp==16'hFFFF)) begin
						int_num <= 8'h0d;
						tGoto(INT2);
					end
				end
			8'h01:
				begin
					case(rrr)
					3'b010: tGoto(FETCH_DESC);
					3'b011: tGoto(FETCH_DESC);
					default: tGoto(FETCH_DATA);
					endcase
					if (w && (offsdisp==16'hFFFF)) begin
						int_num <= 8'h0d;
						tGoto(INT2);
					end
				end
			8'h03:
				if (w && (offsdisp==16'hFFFF)) begin
					int_num <= 8'h0d;
					tGoto(INT2);
				end
				else
					tGoto(FETCH_DATA);
			default:
				if (w && (offsdisp==16'hFFFF)) begin
					int_num <= 8'h0d;
					tGoto(INT2);
				end
				else
					tGoto(FETCH_DATA);
			endcase
		`MOV_I8M: tGoto(FETCH_IMM8);
		`MOV_I16M:
			if (ip==16'hFFFF) begin
				int_num <= 8'h0d;
				tGoto(INT2);
			end
			else
				tGoto(FETCH_IMM16);
		`POP_MEM:
			begin
				tGoto(POP);
			end
		`XCHG_MEM:
			begin
//				bus_locked <= 1'b1;
				tGoto(FETCH_DATA);
			end
		8'b1000100?:	// Move to memory
			begin
				$display("EACALC1: tGoto(STORE_DATA");
				if (w && (offsdisp==16'hFFFF)) begin
					int_num <= 8'h0d;
					tGoto(INT2);
				end
				else begin	
					res <= rrro;
					tGoto(STORE_DATA);
				end
			end
		default:
			begin
				$display("EACALC1: tGoto(FETCH_DATA");
				if (w && (offsdisp==16'hFFFF)) begin
					int_num <= 8'h0d;
					tGoto(INT2);
				end
				else	
					tGoto(FETCH_DATA);
				if (ir==8'hff) begin
					case(rrr)
					3'b011: tGoto(CALLF);	// CAll FAR indirect
					3'b101: tGoto(JUMP_VECTOR1);	// JMP FAR indirect
					3'b110:	begin d <= 1'b0; tGoto(FETCH_DATA); end// for a push
					default: ;
					endcase
				end
			end
		endcase
//		ea <= ea + disp16;
		ea <= {seg_reg,`SEG_SHIFT} + offsdisp;	// offsdisp = offset + disp16
	end
