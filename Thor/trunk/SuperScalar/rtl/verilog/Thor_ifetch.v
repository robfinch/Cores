// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
//
// Thor SuperScalar
// Instruction fetch logic
//
// ============================================================================
//
	else if (take_branch) begin
	    if (fetchbuf == 1'b0)
			case ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v})
			4'b0000: ;
			4'b0100:
				begin
					fetchbufC_instr <= insn0;
					fetchbufC_pc <= pc;
					fetchbufC_v <= `VAL;
					fetchbufD_instr <= insn1;
					fetchbufD_pc <= pc + fnInsnLength(insn);
					fetchbufD_v <= `VAL;
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					if (iqentry_v[tail0]==`INV) begin
						fetchbufA_v <= `INV;
						fetchbuf <= 1'b1;
					end
				end
			4'b0111:
				if (iqentry_v[tail0]==`INV) begin
					fetchbufB_v <= `INV;
					fetchbuf <= 1'b1;
				end
			4'b1000:
				begin
					fetchbufC_instr <= insn0;
					fetchbufC_v <= `VAL;
					fetchbufC_pc <= pc;
					fetchbufD_instr <= insn1;
					fetchbufD_v <= `VAL;
					fetchbufD_pc <= pc + fnInsnLength(insn);
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufA_v <= iqentry_v[tail0];
					fetchbuf <= fetchbuf + ~iqentry_v[tail0];
				end
			4'b1011:
				if (iqentry_v[tail0]==`INV) begin
					fetchbufA_v <= `INV;
					fetchbuf <= 1'b1;
				end
			4'b1100 : begin
				if (fnIsBranch(opcodeA) && predict_takenA) begin
					pc <= backpc;
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= `INV;		// stomp on it
					if (~iqentry_v[tail0])	fetchbuf <= 1'b0;
				end
				else begin
					if (did_branchback) begin
						fetchbufC_instr <= insn0;
						fetchbufC_v <= `VAL;
						fetchbufC_pc <= pc;
						fetchbufD_instr <= insn1;
						fetchbufD_v <= `VAL;
						fetchbufD_pc <= pc + fnInsnLength(insn);
						pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
						fetchbufA_v <= iqentry_v[tail0];
						fetchbufB_v <= iqentry_v[tail1];
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else begin
						pc <= backpc;
						fetchbufA_v <= iqentry_v[tail0];
						fetchbufB_v <= iqentry_v[tail1];
						if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
					end
				end
			4'b1111:
				begin
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= iqentry_v[tail1];
					fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
				end
			default: panic <= `PANIC_INVALIDFBSTATE;
			endcase

		else	// fetchbuf==1'b1
			case ({fetchbufC_v,fetchbufD_v,fetchbufA_v,fetchbufB_v})
			4'b0000: ;
			4'b0100:
				begin
					fetchbufA_instr <= insn0;
					fetchbufA_pc <= pc;
					fetchbufA_v <= `VAL;
					fetchbufB_instr <= insn1;
					fetchbufB_pc <= pc + fnInsnLength(insn);
					fetchbufB_v <= `VAL;
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					if (iqentry_v[tail0]==`INV) begin
						fetchbufD_v <= `INV;
						fetchbuf <= 1'b1;
					end
				end
			4'b0111:
				if (iqentry_v[tail0]==`INV) begin
					fetchbufD_v <= `INV;
					fetchbuf <= 1'b1;
				end
			4'b1000:
				begin
					fetchbufA_instr <= insn0;
					fetchbufA_v <= `VAL;
					fetchbufA_pc <= pc;
					fetchbufB_instr <= insn1;
					fetchbufB_v <= `VAL;
					fetchbufB_pc <= pc + fnInsnLength(insn);
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
					fetchbufC_v <= iqentry_v[tail0];
					fetchbuf <= fetchbuf + ~iqentry_v[tail0];
				end
			4'b1011:
				if (iqentry_v[tail0]==`INV) begin
					fetchbufC_v <= `INV;
					fetchbuf <= 1'b1;
				end
			4'b1100 : begin
				if (fnIsBranch(opcodeC) && predict_takenA) begin
					pc <= backpc;
					fetchbufC_v <= iqentry_v[tail0];
					fetchbufD_v <= `INV;		// stomp on it
					if (~iqentry_v[tail0])	fetchbuf <= 1'b0;
				end
				else begin
					if (did_branchback) begin
						fetchbufA_instr <= insn0;
						fetchbufA_v <= `VAL;
						fetchbufA_pc <= pc;
						fetchbufb_instr <= insn1;
						fetchbufB_v <= `VAL;
						fetchbufB_pc <= pc + fnInsnLength(insn);
						pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
						fetchbufC_v <= iqentry_v[tail0];
						fetchbufD_v <= iqentry_v[tail1];
						fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
					end
					else begin
						pc <= backpc;
						fetchbufC_v <= iqentry_v[tail0];
						fetchbufD_v <= iqentry_v[tail1];
						if (~iqentry_v[tail0] & ~iqentry_v[tail1])	fetchbuf <= 1'b0;
					end
				end
			4'b1111 : begin
				begin
					fetchbufC_v <= iqentry_v[tail0];
					fetchbufD_v <= iqentry_v[tail1];
					fetchbuf <= fetchbuf + (~iqentry_v[tail0] & ~iqentry_v[tail1]);
				end
			default: panic <= `PANIC_INVALIDFBSTATE;
			endcase
		else begin
			if (fetchbuf == 1'b0)
				case ({fetchbufA_v, fetchbufB_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
				4'b00_00 : ;
				4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b00_10 : ;
				4'b00_11 : ;
				4'b01_00 : ;
				4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b01_10,
				4'b01_11 : begin
					fetchbufB_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				4'b10_00 : ;
				4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b10_10,
				4'b10_11 : begin
					fetchbufA_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				4'b11_00 : ;
				4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b11_10 : begin
					fetchbufA_v <= `INV;
					end
				4'b11_11 : begin
					fetchbufA_v <= `INV;
					fetchbufB_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				endcase
			else
				case ({fetchbufC_v, fetchbufD_v, ~iqentry_v[tail0], ~iqentry_v[tail1]})
				4'b00_00 : ;
				4'b00_01 : panic <= `PANIC_INVALIDIQSTATE;
				4'b00_10 : ;
				4'b00_11 : ;
				4'b01_00 : ;
				4'b01_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b01_10,
				4'b01_11 : begin
					fetchbufD_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b10_00 : ;
				4'b10_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b10_10,
				4'b10_11 : begin
					fetchbufC_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end

				4'b11_00 : ;
				4'b11_01 : panic <= `PANIC_INVALIDIQSTATE;

				4'b11_10 : begin
					fetchbufC_v <= `INV;
					end

				4'b11_11 : begin
					fetchbufC_v <= `INV;
					fetchbufD_v <= `INV;
					fetchbuf <= ~fetchbuf;
					end
				endcase
				if (fetchbufA_v == `INV && fetchbufB_v == `INV) begin
					fetchbufA_instr <= insn0;
					fetchbufA_v <= `VAL;
					fetchbufA_pc <= pc;
					fetchbufB_instr <= insn1;
					fetchbufB_v <= `VAL;
					fetchbufB_pc <= pc + fnInsnLength(insn);
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				end
				else if (fetchbufC_v == `INV && fetchbufD_v == `INV) begin
					fetchbufC_instr <= insn0;
					fetchbufC_v <= `VAL;
					fetchbufC_pc <= pc;
					fetchbufD_instr <= insn1;
					fetchbufD_v <= `VAL;
					fetchbufD_pc <= pc + fnInsnLength(insn);
					pc <= pc + fnInsnLength(insn) + fnInsnLength1(insn);
				end
			end
		end
