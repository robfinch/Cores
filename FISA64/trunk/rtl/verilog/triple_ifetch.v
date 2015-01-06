// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
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
// Triple instruction fetch logic
//
// ============================================================================
//
//
// FETCH
//
// fetch three instructions from memory into the fetch buffer
// unless either one of the buffers is still full, in which case we
// do nothing (kinda like alpha approach)
//
if (branchmiss) begin
	$display("pc <= %h", misspc);
	pc <= misspc;
	fetchbuf <= 1'b0;
	fetchbufA_v <= 1'b0;
	fetchbufB_v <= 1'b0;
	fetchbufC_v <= 1'b0;
	fetchbufD_v <= 1'b0;
	fetchbufE_v <= 1'b0;
	fetchbufF_v <= 1'b0;
end
else if (take_branch) begin
	if (fetchbuf == 1'b0) begin
		case ({fetchbufA_v,fetchbufB_v,fetchbufC_v,fetchbufD_v,fetchbufE_v,fetchbufF_v})
		6'b000000: ;
		6'b000001: panic <= `PANIC_INVALIDFBSTATE;
		6'b000010: panic <= `PANIC_INVALIDFBSTATE;
		6'b000011: panic <= `PANIC_INVALIDFBSTATE;
		6'b000100: panic <= `PANIC_INVALIDFBSTATE;
		6'b000101: panic <= `PANIC_INVALIDFBSTATE;
		6'b000110: panic <= `PANIC_INVALIDFBSTATE;
		6'b000111: panic <= `PANIC_INVALIDFBSTATE;
		6'b001000:
			begin
				LD_fetchbufDEF();
				fetchbufC_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b001001: panic <= `PANIC_INVALIDFBSTATE;
		6'b001010: panic <= `PANIC_INVALIDFBSTATE;
		6'b001011: panic <= `PANIC_INVALIDFBSTATE;
		6'b001100: panic <= `PANIC_INVALIDFBSTATE;
		6'b001101: panic <= `PANIC_INVALIDFBSTATE;
		6'b001110: panic <= `PANIC_INVALIDFBSTATE;
		6'b001111:
			begin
				fetchbufC_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b010000:
			begin
				LD_fetchbufDEF();
				if (do_pcinc) pc[31:4] <= pc[31:4] + 28'd1;
				fetchbufB_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b010001: panic <= `PANIC_INVALIDFBSTATE;
		6'b010010: panic <= `PANIC_INVALIDFBSTATE;
		6'b010011: panic <= `PANIC_INVALIDFBSTATE;
		6'b010100: panic <= `PANIC_INVALIDFBSTATE;
		6'b010101: panic <= `PANIC_INVALIDFBSTATE;
		6'b010110: panic <= `PANIC_INVALIDFBSTATE;
		6'b010111:
			begin
				fetchbufB_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b011000:
			begin
				LD_fetchbufDEF();
				fetchbufB_v <= iqentry_v[tail0];
				fetchbufC_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b011001: panic <= `PANIC_INVALIDFBSTATE;
		6'b011010: panic <= `PANIC_INVALIDFBSTATE;
		6'b011011: panic <= `PANIC_INVALIDFBSTATE;
		6'b011100: panic <= `PANIC_INVALIDFBSTATE;
		6'b011101: panic <= `PANIC_INVALIDFBSTATE;
		6'b011110: panic <= `PANIC_INVALIDFBSTATE;
		6'b011111:
			begin
				fetchbufB_v <= iqentry_v[tail0];
				fetchbufC_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b100000:
			begin
				LD_fetchbufDEF();
				fetchbufA_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b100001: panic <= `PANIC_INVALIDFBSTATE;
		6'b100010: panic <= `PANIC_INVALIDFBSTATE;
		6'b100011: panic <= `PANIC_INVALIDFBSTATE;
		6'b100100: panic <= `PANIC_INVALIDFBSTATE;
		6'b100101: panic <= `PANIC_INVALIDFBSTATE;
		6'b100110: panic <= `PANIC_INVALIDFBSTATE;
		6'b100111:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b101000:
			begin
				LD_fetchbufDEF();
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufC_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b101001: panic <= `PANIC_INVALIDFBSTATE;
		6'b101010: panic <= `PANIC_INVALIDFBSTATE;
		6'b101011: panic <= `PANIC_INVALIDFBSTATE;
		6'b101100: panic <= `PANIC_INVALIDFBSTATE;
		6'b101101: panic <= `PANIC_INVALIDFBSTATE;
		6'b101110: panic <= `PANIC_INVALIDFBSTATE;
		6'b101111:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufC_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b110000:
			begin
				LD_fetchbufDEF();
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufB_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b110001: panic <= `PANIC_INVALIDFBSTATE;
		6'b110010: panic <= `PANIC_INVALIDFBSTATE;
		6'b110011: panic <= `PANIC_INVALIDFBSTATE;
		6'b110100: panic <= `PANIC_INVALIDFBSTATE;
		6'b110101: panic <= `PANIC_INVALIDFBSTATE;
		6'b110110: panic <= `PANIC_INVALIDFBSTATE;
		6'b110111:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufB_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		// IF the branch was already done it would be case 6'b110_000 or 6'b100_000
		// Since it's case 6'b111_000 the branch in A or B hasn't been done yet. If
		// the branch is in C it may have been done already.
		6'b111000:
			begin
				// Note that there is no point to loading D,E,F here because
				// there is a predicted taken branch that would stomp on the
				// instructions anyways.
				if (fnIsBranch(opcodeA) && predict_takenA) begin
					pc <= branch_pc;
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= `INV;		// stomp on it
					fetchbufC_v <= `INV;		// stomp on it
					// may as well stick with same fetchbuf
				end
				else if (fnIsBranch(opcodeB) && predict_takenB) begin
					pc <= branch_pc;
					fetchbufA_v <= iqentry_v[tail0];
					fetchbufB_v <= iqentry_v[tail1];
					fetchbufC_v <= `INV;		// stomp on it
					// may as well stick with same fetchbuf
				end
				else begin	// The branch is in slot C
					if (did_branchback0) begin
						LD_fetchbufDEF();
						fetchbufA_v <= iqentry_v[tail0];
						fetchbufB_v <= iqentry_v[tail1];
						fetchbufC_v <= iqentry_v[tail2];
						if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
							fetchbuf <= 1'b1;
					end
					else begin
						pc <= branch_pc;
						fetchbufA_v <= iqentry_v[tail0];
						fetchbufB_v <= iqentry_v[tail1];
						fetchbufC_v <= iqentry_v[tail2];
						if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
							fetchbuf <= 1'b1;
					end
				end
			end
		6'b111001: panic <= `PANIC_INVALIDFBSTATE;
		6'b111010: panic <= `PANIC_INVALIDFBSTATE;
		6'b111011: panic <= `PANIC_INVALIDFBSTATE;
		6'b111100: panic <= `PANIC_INVALIDFBSTATE;
		6'b111101: panic <= `PANIC_INVALIDFBSTATE;
		6'b111110: panic <= `PANIC_INVALIDFBSTATE;
		6'b111111:
			begin
				fetchbufA_v <= iqentry_v[tail0];
				fetchbufB_v <= iqentry_v[tail1];
				fetchbufC_v <= iqentry_v[tail2];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
					fetchbuf <= 1'b1;
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
	else begin	// fetchbuf==1'b1
		6'b000000: ;
		6'b000001: panic <= `PANIC_INVALIDFBSTATE;
		6'b000010: panic <= `PANIC_INVALIDFBSTATE;
		6'b000011: panic <= `PANIC_INVALIDFBSTATE;
		6'b000100: panic <= `PANIC_INVALIDFBSTATE;
		6'b000101: panic <= `PANIC_INVALIDFBSTATE;
		6'b000110: panic <= `PANIC_INVALIDFBSTATE;
		6'b000111: panic <= `PANIC_INVALIDFBSTATE;
		6'b001000:
			begin
				LD_fetchbufABC();
				fetchbufF_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b001001: panic <= `PANIC_INVALIDFBSTATE;
		6'b001010: panic <= `PANIC_INVALIDFBSTATE;
		6'b001011: panic <= `PANIC_INVALIDFBSTATE;
		6'b001100: panic <= `PANIC_INVALIDFBSTATE;
		6'b001101: panic <= `PANIC_INVALIDFBSTATE;
		6'b001110: panic <= `PANIC_INVALIDFBSTATE;
		6'b001111:
			begin
				fetchbufF_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b010000:
			begin
				LD_fetchbufABC();
				fetchbufE_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b010001: panic <= `PANIC_INVALIDFBSTATE;
		6'b010010: panic <= `PANIC_INVALIDFBSTATE;
		6'b010011: panic <= `PANIC_INVALIDFBSTATE;
		6'b010100: panic <= `PANIC_INVALIDFBSTATE;
		6'b010101: panic <= `PANIC_INVALIDFBSTATE;
		6'b010110: panic <= `PANIC_INVALIDFBSTATE;
		6'b010111:
			begin
				fetchbufE_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b011000:
			begin
				LD_fetchbufABC();
				fetchbufE_v <= iqentry_v[tail0];
				fetchbufF_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b011001: panic <= `PANIC_INVALIDFBSTATE;
		6'b011010: panic <= `PANIC_INVALIDFBSTATE;
		6'b011011: panic <= `PANIC_INVALIDFBSTATE;
		6'b011100: panic <= `PANIC_INVALIDFBSTATE;
		6'b011101: panic <= `PANIC_INVALIDFBSTATE;
		6'b011110: panic <= `PANIC_INVALIDFBSTATE;
		6'b011111:
			begin
				fetchbufE_v <= iqentry_v[tail0];
				fetchbufF_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b100000:
			begin
				LD_fetchbufABC();
				fetchbufD_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b100001: panic <= `PANIC_INVALIDFBSTATE;
		6'b100010: panic <= `PANIC_INVALIDFBSTATE;
		6'b100011: panic <= `PANIC_INVALIDFBSTATE;
		6'b100100: panic <= `PANIC_INVALIDFBSTATE;
		6'b100101: panic <= `PANIC_INVALIDFBSTATE;
		6'b100110: panic <= `PANIC_INVALIDFBSTATE;
		6'b100111:
			begin
				fetchbufD_v <= iqentry_v[tail0];
				if (iqentry_v[tail0]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b101000:
			begin
				LD_fetchbufABC();
				fetchbufD_v <= iqentry_v[tail0];
				fetchbufF_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b101001: panic <= `PANIC_INVALIDFBSTATE;
		6'b101010: panic <= `PANIC_INVALIDFBSTATE;
		6'b101011: panic <= `PANIC_INVALIDFBSTATE;
		6'b101100: panic <= `PANIC_INVALIDFBSTATE;
		6'b101101: panic <= `PANIC_INVALIDFBSTATE;
		6'b101110: panic <= `PANIC_INVALIDFBSTATE;
		6'b101111:
			begin
				fetchbufD_v <= iqentry_v[tail0];
				fetchbufF_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b110000:
			begin
				LD_fetchbufABC();
				fetchbufD_v <= iqentry_v[tail0];
				fetchbufE_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		6'b110001: panic <= `PANIC_INVALIDFBSTATE;
		6'b110010: panic <= `PANIC_INVALIDFBSTATE;
		6'b110011: panic <= `PANIC_INVALIDFBSTATE;
		6'b110100: panic <= `PANIC_INVALIDFBSTATE;
		6'b110101: panic <= `PANIC_INVALIDFBSTATE;
		6'b110110: panic <= `PANIC_INVALIDFBSTATE;
		6'b110111:
			begin
				fetchbufD_v <= iqentry_v[tail0];
				fetchbufE_v <= iqentry_v[tail1];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV)
					fetchbuf <= 1'b1;
			end
		// IF the branch was already done it would be case 6'b110_000 or 6'b100_000
		// Since it's case 6'b111_000 the branch in A or B hasn't been done yet. If
		// the branch is in C it may have been done already.
		6'b111000:
			begin
				// Note that there is no point to loading D,E,F here because
				// there is a predicted taken branch that would stomp on the
				// instructions anyways.
				if (fnIsBranch(opcodeD) && predict_takenD) begin
					pc <= branch_pc;
					fetchbufD_v <= iqentry_v[tail0];
					fetchbufE_v <= `INV;		// stomp on it
					fetchbufF_v <= `INV;		// stomp on it
					// may as well stick with same fetchbuf
				end
				else if (fnIsBranch(opcodeE) && predict_takenE) begin
					pc <= branch_pc;
					fetchbufD_v <= iqentry_v[tail0];
					fetchbufE_v <= iqentry_v[tail1];
					fetchbufF_v <= `INV;		// stomp on it
					// may as well stick with same fetchbuf
				end
				else begin	// The branch is in slot C
					if (did_branchback1) begin
						LD_fetchbufABC();
						fetchbufD_v <= iqentry_v[tail0];
						fetchbufE_v <= iqentry_v[tail1];
						fetchbufF_v <= iqentry_v[tail2];
						if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
							fetchbuf <= 1'b1;
					end
					else begin
						pc <= branch_pc;
						fetchbufD_v <= iqentry_v[tail0];
						fetchbufE_v <= iqentry_v[tail1];
						fetchbufF_v <= iqentry_v[tail2];
						if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
							fetchbuf <= 1'b1;
					end
				end
			end
		6'b111001: panic <= `PANIC_INVALIDFBSTATE;
		6'b111010: panic <= `PANIC_INVALIDFBSTATE;
		6'b111011: panic <= `PANIC_INVALIDFBSTATE;
		6'b111100: panic <= `PANIC_INVALIDFBSTATE;
		6'b111101: panic <= `PANIC_INVALIDFBSTATE;
		6'b111110: panic <= `PANIC_INVALIDFBSTATE;
		6'b111111:
			begin
				fetchbufD_v <= iqentry_v[tail0];
				fetchbufE_v <= iqentry_v[tail1];
				fetchbufF_v <= iqentry_v[tail2];
				if (iqentry_v[tail0]==`INV && iqentry_v[tail1]==`INV && iqentry_v[tail2]==`INV)
					fetchbuf <= 1'b1;
			end
		default: panic <= `PANIC_INVALIDFBSTATE;
		endcase
	end
end
// Here, we are not taking a branch
else begin
	if (fetchbuf == 1'b0)
		case ({fetchbufA_v, fetchbufB_v, fetchbufC_v, ~iqentry_v[tail0], ~iqentry_v[tail1], ~iqentry_v[tail2]})
		6'b000_000:	;
		6'b000_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_100: ;
		6'b000_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_110:	;
		6'b000_111:	;
		6'b001_000:	;
		6'b001_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_100:
			begin
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b001_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_110:
			begin
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b001_111:
			begin
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_000:	;
		6'b010_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_100:
			begin
				fetchbufB_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_110:
			begin
				fetchbufB_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_111:
			begin
				fetchbufB_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b011_000:	;
		6'b011_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_100:
			begin
				fetchbufB_v <= `INV;
			end
		6'b011_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_110:
			begin
				fetchbufB_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b011_111:
			begin
				fetchbufB_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_000:	;
		6'b100_001: panic <= `PANIC_INVALIDIQSTATE;
		6'b100_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_100:
			begin
				fetchbufA_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_110:
			begin
				fetchbufA_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_111:
			begin
				fetchbufA_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b101_000:	;
		6'b101_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_100:
			begin
				fetchbufA_v <= `INV;
			end
		6'b101_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_110:
			begin
				fetchbufA_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b101_111:
			begin
				fetchbufA_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b110_000:	;
		6'b110_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_100:
			begin
				fetchbufA_v <= `INV;
			end
		6'b110_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_110:
			begin
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b110_111:
			begin
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b111_000:	;
		6'b111_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_100:
			begin
				fetchbufA_v <= `INV;
			end
		6'b111_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_110:
			begin
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
			end
		6'b111_111:
			begin
				fetchbufA_v <= `INV;
				fetchbufB_v <= `INV;
				fetchbufC_v <= `INV;
				fetchbuf <= 1'b1;
			end
		endcase
	else
		case ({fetchbufD_v, fetchbufE_v, fetchbufF_v, ~iqentry_v[tail0], ~iqentry_v[tail1], ~iqentry_v[tail2]})
		6'b000_000:	;
		6'b000_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_100: ;
		6'b000_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b000_110:	;
		6'b000_111:	;
		6'b001_000:	;
		6'b001_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_100:
			begin
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b001_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b001_110:
			begin
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b001_111:
			begin
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_000:	;
		6'b010_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_100:
			begin
				fetchbufE_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b010_110:
			begin
				fetchbufE_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b010_111:
			begin
				fetchbufE_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b011_000:	;
		6'b011_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_100:
			begin
				fetchbufE_v <= `INV;
			end
		6'b011_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b011_110:
			begin
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b011_111:
			begin
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_000:	;
		6'b100_001: panic <= `PANIC_INVALIDIQSTATE;
		6'b100_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_100:
			begin
				fetchbufD_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b100_110:
			begin
				fetchbufD_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b100_111:
			begin
				fetchbufD_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b101_000:	;
		6'b101_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_100:
			begin
				fetchbufD_v <= `INV;
			end
		6'b101_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b101_110:
			begin
				fetchbufD_v <= `INV;
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b101_111:
			begin
				fetchbufD_v <= `INV;
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b110_000:	;
		6'b110_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_100:
			begin
				fetchbufD_v <= `INV;
			end
		6'b110_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b110_110:
			begin
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b110_111:
			begin
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbuf <= 1'b1;
			end
		6'b111_000:	;
		6'b111_001:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_010:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_011:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_100:
			begin
				fetchbufD_v <= `INV;
			end
		6'b111_101:	panic <= `PANIC_INVALIDIQSTATE;
		6'b111_110:
			begin
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
			end
		6'b111_111:
			begin
				fetchbufD_v <= `INV;
				fetchbufE_v <= `INV;
				fetchbufF_v <= `INV;
				fetchbuf <= 1'b1;
			end
		endcase
	if (fetchbufA_v == `INV && fetchbufB_v == `INV && fetchbufC_v==`INV) begin
		LD_fetchbufABC();
		// fetchbuf steering logic correction
		if (fetchbufD_v==`INV && fetchbufE_v==`INV && fetchbufF_v==`INV && do_pcinc)
			fetchbuf <= 1'b0;
		$display("hit %b 1pc <= %h", do_pcinc, {pc[31:4],4'b00} + 32'd16);
	end
	else if (fetchbufD_v == `INV && fetchbufE_v == `INV && fetchbufF_v == `INV) begin
		LD_fetchbufDEF();
		$display("hit %b 2pc <= %h", do_pcinc, {pc[31:4],4'b00} + 32'd16);
	end
end
