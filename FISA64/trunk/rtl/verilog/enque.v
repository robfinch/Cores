// ============================================================================
//        __
//   \\__/ o\    (C) 2013, 2015  Robert Finch, Stratford
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
// SuperScalar
// Triple Instruction enque logic
//
// ============================================================================
//
//
// ENQUEUE
//
// place up to three instructions from the fetch buffer into slots in the IQ.
//   note: they are placed in-order, and they are expected to be executed
// 0, 1, or 2 of the fetch buffers may have valid data
// 0, 1, or 2 slots in the instruction queue may be available.
// if we notice that one of the instructions in the fetch buffer is a backwards branch,
// predict it taken (set branchback/backpc and delete any instructions after it in fetchbuf)
//

if (!branchmiss && !stomp_all)  begin	// don't bother doing anything if there's been a branch miss

	case ({fetchbuf0_v, fetchbuf1_v, fetchbuf2_v})

	// In this case none of the fetch buffers are valid do we can't do anything.
	3'b000: ;

	3'b001:
			if (iqentry_v[tail0] == `INV) begin
    			tskEnque(tail0,fetchbuf2_instr,fetchbuf2_pc,predict_taken2,rfoa2,rfob2,rfoc2);
				tail0 <= tail0 + 4'd1;
				tail1 <= tail1 + 4'd1;
				tail2 <= tail2 + 4'd1;
				if (fetchbuf2_rfw) begin
					rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end
	3'b010:
			if (iqentry_v[tail0] == `INV) begin
    			tskEnque(tail0,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
				tail0 <= tail0 + 4'd1;
				tail1 <= tail1 + 4'd1;
				tail2 <= tail2 + 4'd1;
				if (fetchbuf1_rfw) begin
					rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end
	3'b100:
			if (iqentry_v[tail0] == `INV) begin
    			tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
				tail0 <= tail0 + 4'd1;
				tail1 <= tail1 + 4'd1;
				tail2 <= tail2 + 4'd1;
				if (fetchbuf1_rfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end


	3'b011:
			if (iqentry_v[tail0] == `INV) begin
				//
				// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
				//
				if ({fnIsBranch(opcode1), predict_taken1} == {`TRUE, `TRUE}) begin
					tskEnque(tail0,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
					tail0 <= tail0 + 4'd1;
					tail1 <= tail1 + 4'd1;
					tail2 <= tail2 + 4'd1;
					if (fetchbuf1_rfw) begin
						rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
						rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
					end
				end
				else begin	// fetchbuf0 doesn't contain a backwards branch
					//
					// so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
					// update tail0/tail1 separately (at top)
					// update the rf_v and rf_source bits separately (at end)
					//   the problem is that if we do have two instructions, 
					//   they may interact with each other, so we have to be
					//   careful about where things point.
					//

					if (iqentry_v[tail1] == `INV) begin
						tail0 <= tail0 + 4'd2;
						tail1 <= tail1 + 4'd2;
						tail2 <= tail2 + 4'd2;
					end
					else begin
						tail0 <= tail0 + 4'd1;
						tail1 <= tail1 + 4'd1;
						tail2 <= tail2 + 4'd1;
					end
					//
					// enqueue the first instruction ...
					//
					tskEnque(tail0,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
					//
					// if there is room for a second instruction, enqueue it
					//
					if (iqentry_v[tail1] == `INV) begin
						tskEnque(tail1,fetchbuf2_instr,fetchbuf2_pc,predict_taken2,rfoa2,rfob2,rfoc2);
						// a1/a2_v and a1/a2_s values require a bit of thinking ...

						// SOURCE 1 ... this is relatively straightforward
						if (fetchbuf1_rfw) begin
							if (fnTargetReg(fetchbuf1_instr) != 7'd0
								&& fnRa(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_av [tail1]    <=   `INV;
								iqentry_as [tail1]    <=   { fetchbuf1_mem, tail0 };
							end
						end

						// SOURCE 2 ... 
						if (fetchbuf1_rfw) begin
							if (fnTargetReg(fetchbuf1_instr) != 7'd0 &&
								fnRb(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_bv [tail1]    <=   `INV;
								iqentry_bs [tail1]    <=   { fetchbuf1_mem, tail0 };
							end
						end

						// SOURCE 3 ...
						if (fetchbuf1_rfw) begin
							if (fnTargetReg(fetchbuf1_instr) != 7'd0
								&& fnRc(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_cv [tail1]    <=   `INV;
								iqentry_cs [tail1]    <=   { fetchbuf1_mem, tail0 };
							end
						end
						//
						// if the two instructions enqueued target the same register, 
						// make sure only the second writes to rf_v and rf_source.
						// first is allowed to update rf_v and rf_source only if the
						// second has no target (BEQ or SW)
						//
						if (fnTargetReg(fetchbuf1_instr) == fnTargetReg(fetchbuf2_instr)) begin
							if (fetchbuf2_rfw) begin
								rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail1 };
							end
							else if (fetchbuf1_rfw) begin
								rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };
							end
						end
						else begin
							if (fetchbuf1_rfw) begin
								rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };
							end
							if (fetchbuf2_rfw) begin
								rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail1 };
							end
						end
					end
				end
			end
	3'b101:
			if (iqentry_v[tail0] == `INV) begin
				//
				// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
				//
				if ({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE}) begin
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					tail0 <= tail0 + 4'd1;
					tail1 <= tail1 + 4'd1;
					tail2 <= tail2 + 4'd1;
					if (fetchbuf0_rfw) begin
						rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
						rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
					end
				end
				else begin	// fetchbuf0 doesn't contain a backwards branch
					//
					// so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
					// update tail0/tail1 separately (at top)
					// update the rf_v and rf_source bits separately (at end)
					//   the problem is that if we do have two instructions, 
					//   they may interact with each other, so we have to be
					//   careful about where things point.
					//

					if (iqentry_v[tail1] == `INV) begin
						tail0 <= tail0 + 4'd2;
						tail1 <= tail1 + 4'd2;
						tail2 <= tail2 + 4'd2;
					end
					else begin
						tail0 <= tail0 + 4'd1;
						tail1 <= tail1 + 4'd1;
						tail2 <= tail2 + 4'd1;
					end
					//
					// enqueue the first instruction ...
					//
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					//
					// if there is room for a second instruction, enqueue it
					//
					if (iqentry_v[tail1] == `INV) begin
						tskEnque(tail1,fetchbuf2_instr,fetchbuf2_pc,predict_taken2,rfoa2,rfob2,rfoc2);
						// a1/a2_v and a1/a2_s values require a bit of thinking ...

						// SOURCE 1 ... this is relatively straightforward
						if (fetchbuf0_rfw) begin
							if (fnTargetReg(fetchbuf0_instr) != 7'd0
								&& fnRa(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_av [tail1]    <=   `INV;
								iqentry_as [tail1]    <=   { fetchbuf0_mem, tail0 };
							end

						// SOURCE 2 ... 
							if (fnTargetReg(fetchbuf0_instr) != 7'd0 &&
								fnRb(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_bv [tail1]    <=   `INV;
								iqentry_bs [tail1]    <=   { fetchbuf0_mem, tail0 };
							end

						// SOURCE 3 ...
							if (fnTargetReg(fetchbuf0_instr) != 7'd0
								&& fnRc(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_cv [tail1]    <=   `INV;
								iqentry_cs [tail1]    <=   { fetchbuf0_mem, tail0 };
							end
						end
						//
						// if the two instructions enqueued target the same register, 
						// make sure only the second writes to rf_v and rf_source.
						// first is allowed to update rf_v and rf_source only if the
						// second has no target (BEQ or SW)
						//
						if (fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf2_instr)) begin
							if (fetchbuf2_rfw) begin
								rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail1 };
							end
							else if (fetchbuf0_rfw) begin
								rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
							end
						end
						else begin
							if (fetchbuf0_rfw) begin
								rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
							end
							if (fetchbuf2_rfw) begin
								rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail1 };
							end
						end
					end
				end
			end
	3'b110:
			if (iqentry_v[tail0] == `INV) begin
				//
				// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
				//
				if ({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE}) begin
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					tail0 <= tail0 + 4'd1;
					tail1 <= tail1 + 4'd1;
					tail2 <= tail2 + 4'd1;
					if (fetchbuf0_rfw) begin
						rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
						rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
					end
				end
				else begin	// fetchbuf0 doesn't contain a backwards branch
					//
					// so -- we can enqueue 1 or 2 instructions, depending on space in the IQ
					// update tail0/tail1 separately (at top)
					// update the rf_v and rf_source bits separately (at end)
					//   the problem is that if we do have two instructions, 
					//   they may interact with each other, so we have to be
					//   careful about where things point.
					//

					if (iqentry_v[tail1] == `INV) begin
						tail0 <= tail0 + 4'd2;
						tail1 <= tail1 + 4'd2;
						tail2 <= tail2 + 4'd2;
					end
					else begin
						tail0 <= tail0 + 4'd1;
						tail1 <= tail1 + 4'd1;
						tail2 <= tail2 + 4'd1;
					end
					//
					// enqueue the first instruction ...
					//
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					//
					// if there is room for a second instruction, enqueue it
					//
					if (iqentry_v[tail1] == `INV) begin
						tskEnque(tail1,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
						// a1/a2_v and a1/a2_s values require a bit of thinking ...

						// SOURCE 1 ... this is relatively straightforward
						if (fetchbuf0_rfw) begin
							if (fnTargetReg(fetchbuf0_instr) != 7'd0
								&& fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_av [tail1]    <=   `INV;
								iqentry_as [tail1]    <=   { fetchbuf0_mem, tail0 };
							end

						// SOURCE 2 ... 
							if (fnTargetReg(fetchbuf0_instr) != 7'd0 &&
								fnRb(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_bv [tail1]    <=   `INV;
								iqentry_bs [tail1]    <=   { fetchbuf0_mem, tail0 };
							end

						// SOURCE 3 ...
							if (fnTargetReg(fetchbuf0_instr) != 7'd0
								&& fnRc(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
								// if the previous instruction is a LW, then grab result from memq, not the iq
								iqentry_cv [tail1]    <=   `INV;
								iqentry_cs [tail1]    <=   { fetchbuf0_mem, tail0 };
							end
						end
						//
						// if the two instructions enqueued target the same register, 
						// make sure only the second writes to rf_v and rf_source.
						// first is allowed to update rf_v and rf_source only if the
						// second has no target (BEQ or SW)
						//
						if (fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf1_instr)) begin
							if (fetchbuf1_rfw) begin
								rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
							end
							else if (fetchbuf0_rfw) begin
								rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
							end
						end
						else begin
							if (fetchbuf0_rfw) begin
								rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
							end
							if (fetchbuf1_rfw) begin
								rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
								rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
							end
						end
					end
				end
			end
	3'b111:
			if (iqentry_v[tail0] == `INV) begin
				//
				// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
				//
				if ({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE}) begin
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					tail0 <= tail0 + 4'd1;
					tail1 <= tail1 + 4'd1;
					tail2 <= tail2 + 4'd1;
					if (fetchbuf0_rfw) begin
						rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
						rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
					end
				end
				else begin	// fetchbuf0 doesn't contain a backwards branch
					//
					// enqueue the first instruction ...
					//
					tskEnque(tail0,fetchbuf0_instr,fetchbuf0_pc,predict_taken0,rfoa0,rfob0,rfoc0);
					
					if (iqentry_v[tail1] == `INV) begin
						// If the second instruction is a predicted branch enque it and stomp on the following instruction.
						if ({fnIsBranch(opcode1), predict_taken1} == {`TRUE, `TRUE}) begin
							tskEnque(tail1,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
							tail0 <= tail0 + 4'd2;
							tail1 <= tail1 + 4'd2;
							tail2 <= tail2 + 4'd2;
							// SOURCE 1 ... this is relatively straightforward
							if (fetchbuf0_rfw) begin
								if (fnTargetReg(fetchbuf0_instr) != 7'd0
									&& fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
									// if the previous instruction is a LW, then grab result from memq, not the iq
									iqentry_av [tail1]    <=   `INV;
									iqentry_as [tail1]    <=   { fetchbuf0_mem, tail0 };
								end

							// SOURCE 2 ... 
								if (fnTargetReg(fetchbuf0_instr) != 7'd0 &&
									fnRb(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
									// if the previous instruction is a LW, then grab result from memq, not the iq
									iqentry_bv [tail1]    <=   `INV;
									iqentry_bs [tail1]    <=   { fetchbuf0_mem, tail0 };
								end

							// SOURCE 3 ...
								if (fnTargetReg(fetchbuf0_instr) != 7'd0
									&& fnRc(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
									// if the previous instruction is a LW, then grab result from memq, not the iq
									iqentry_cv [tail1]    <=   `INV;
									iqentry_cs [tail1]    <=   { fetchbuf0_mem, tail0 };
								end
							end
							//
							// if the two instructions enqueued target the same register, 
							// make sure only the second writes to rf_v and rf_source.
							// first is allowed to update rf_v and rf_source only if the
							// second has no target (BEQ or SW)
							//
							if (fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf1_instr)) begin
								if (fetchbuf1_rfw) begin
									rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
									rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
								end
								else if (fetchbuf0_rfw) begin
									rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
									rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
								end
							end
							else begin
								if (fetchbuf0_rfw) begin
									rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
									rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
								end
								if (fetchbuf1_rfw) begin
									rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
									rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
								end
							end
						end
						// The second instruction is not a branch, enque it
						else begin
							tskEnque(tail1,fetchbuf1_instr,fetchbuf1_pc,predict_taken1,rfoa1,rfob1,rfoc1);
							// If there is room, enque a third instruction.
							if (iqentry_v[tail2] == `INV) begin
								tskEnque(tail2,fetchbuf2_instr,fetchbuf2_pc,predict_taken2,rfoa2,rfob2,rfoc2);
								tail0 <= tail0 + 4'd3;
								tail1 <= tail1 + 4'd3;
								tail2 <= tail2 + 4'd3;
								// SOURCE 1 ... this is relatively straightforward
								if (fetchbuf0_rfw && fnTargetReg(fetchbuf0_instr) != 7'd0) begin
									if (fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_av [tail1]    <=   `INV;
										iqentry_as [tail1]    <=   { fetchbuf0_mem, tail0 };
									end
									if (fnRa(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_av [tail2]    <=   `INV;
										iqentry_as [tail2]    <=   { fetchbuf0_mem, tail0 };
									end

								// SOURCE 2 ... 
									if (fnRb(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_bv [tail1]    <=   `INV;
										iqentry_bs [tail1]    <=   { fetchbuf0_mem, tail0 };
									end
									if (fnRb(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_bv [tail2]    <=   `INV;
										iqentry_bs [tail2]    <=   { fetchbuf0_mem, tail0 };
									end

								// SOURCE 3 ...
									if (fnRc(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_cv [tail1]    <=   `INV;
										iqentry_cs [tail1]    <=   { fetchbuf0_mem, tail0 };
									end
									if (fnRc(fetchbuf2_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_cv [tail2]    <=   `INV;
										iqentry_cs [tail2]    <=   { fetchbuf0_mem, tail0 };
									end
								end

								// SOURCE 1 ... this is relatively straightforward
								if (fetchbuf1_rfw && fnTargetReg(fetchbuf1_instr) != 7'd0) begin
									if (fnRa(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
										iqentry_av [tail2]    <=   `INV;
										iqentry_as [tail2]    <=   { fetchbuf1_mem, tail1 };
									end
									// SOURCE 2 ... 
									if (fnRb(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
										iqentry_bv [tail2]    <=   `INV;
										iqentry_bs [tail2]    <=   { fetchbuf1_mem, tail1 };
									end
									// SOURCE 3 ...
									if (fnRc(fetchbuf2_instr) == fnTargetReg(fetchbuf1_instr)) begin
										iqentry_cv [tail2]    <=   `INV;
										iqentry_cs [tail2]    <=   { fetchbuf1_mem, tail1 };
									end
								end
								// if the two instructions enqueued target the same register, 
								// make sure only the second writes to rf_v and rf_source.
								// first is allowed to update rf_v and rf_source only if the
								// second has no target (BEQ or SW)
								//
								case({fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf2_instr),
								      fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf1_instr),
									  fnTargetReg(fetchbuf1_instr) == fnTargetReg(fetchbuf2_instr)})
								3'b000:
									begin
										if (fetchbuf0_rfw) begin
											rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
										end
										if (fetchbuf1_rfw) begin
											rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
										end
										if (fetchbuf2_rfw) begin
											rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail2 };
										end
									end
								3'b001:
									begin
										if (fetchbuf0_rfw) begin
											rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
										end
										if (fetchbuf2_rfw) begin
											rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail2 };
										end
										else if (fetchbuf1_rfw) begin
											rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
										end
									end
								3'b010:
									begin
										if (fetchbuf1_rfw) begin
											rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
										end
										else if (fetchbuf0_rfw) begin
											rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
										end
										if (fetchbuf2_rfw) begin
											rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail2 };
										end
									end
								3'b011,	// can't happen
								3'b101,	// can't happen
								3'b110,	// can't happen
								3'b111:
									begin
										if (fetchbuf2_rfw) begin
											rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail2 };
										end
										else if (fetchbuf1_rfw) begin
											rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
										end
										else if (fetchbuf0_rfw) begin
											rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
										end
									end
								3'b100:
									begin
										if (fetchbuf2_rfw) begin
											rf_v[ fnTargetReg(fetchbuf2_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf2_instr) ] <= { fetchbuf2_mem, tail2 };
										end
										else if (fetchbuf0_rfw) begin
											rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
										end
										if (fetchbuf1_rfw) begin
											rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
											rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
										end
									end
								endcase
							end
							else begin
								tail0 <= tail0 + 4'd2;
								tail1 <= tail1 + 4'd2;
								tail2 <= tail2 + 4'd2;
								// SOURCE 1 ... this is relatively straightforward
								if (fetchbuf0_rfw) begin
									if (fnTargetReg(fetchbuf0_instr) != 7'd0
										&& fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_av [tail1]    <=   `INV;
										iqentry_as [tail1]    <=   { fetchbuf0_mem, tail0 };
									end

								// SOURCE 2 ... 
									if (fnTargetReg(fetchbuf0_instr) != 7'd0 &&
										fnRb(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_bv [tail1]    <=   `INV;
										iqentry_bs [tail1]    <=   { fetchbuf0_mem, tail0 };
									end

								// SOURCE 3 ...
									if (fnTargetReg(fetchbuf0_instr) != 7'd0
										&& fnRc(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
										// if the previous instruction is a LW, then grab result from memq, not the iq
										iqentry_cv [tail1]    <=   `INV;
										iqentry_cs [tail1]    <=   { fetchbuf0_mem, tail0 };
									end
								end
								//
								// if the two instructions enqueued target the same register, 
								// make sure only the second writes to rf_v and rf_source.
								// first is allowed to update rf_v and rf_source only if the
								// second has no target (BEQ or SW)
								//
								if (fnTargetReg(fetchbuf0_instr) == fnTargetReg(fetchbuf1_instr)) begin
									if (fetchbuf1_rfw) begin
										rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
										rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
									end
									else if (fetchbuf0_rfw) begin
										rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
										rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
									end
								end
								else begin
									if (fetchbuf0_rfw) begin
										rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
										rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };
									end
									if (fetchbuf1_rfw) begin
										rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
										rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail1 };
									end
								end
							end // enque third instruction
						end // second instruction is branch
					end // room to queue second instruction
				end // first instruction is branch
			end // room to queue first instruction
	endcase
end
else begin	// if branchmiss
	if ((iqentry_stomp[0] & ~iqentry_stomp[15]) || stomp_all) begin
		tail0 <= 0;
		tail1 <= 1;
		tail2 <= 2;
	end
	else if (iqentry_stomp[1] & ~iqentry_stomp[0]) begin
		tail0 <= 1;
		tail1 <= 2;
		tail2 <= 3;
	end
	else if (iqentry_stomp[2] & ~iqentry_stomp[1]) begin
		tail0 <= 2;
		tail1 <= 3;
		tail2 <= 4;
	end
	else if (iqentry_stomp[3] & ~iqentry_stomp[2]) begin
		tail0 <= 3;
		tail1 <= 4;
		tail2 <= 5;
	end
	else if (iqentry_stomp[4] & ~iqentry_stomp[3]) begin
		tail0 <= 4;
		tail1 <= 5;
		tail2 <= 6;
	end
	else if (iqentry_stomp[5] & ~iqentry_stomp[4]) begin
		tail0 <= 5;
		tail1 <= 6;
		tail2 <= 7;
	end
	else if (iqentry_stomp[6] & ~iqentry_stomp[5]) begin
		tail0 <= 6;
		tail1 <= 7;
		tail2 <= 8;
	end
	else if (iqentry_stomp[7] & ~iqentry_stomp[6]) begin
		tail0 <= 7;
		tail1 <= 8;
		tail2 <= 9;
	end
	else if (iqentry_stomp[8] & ~iqentry_stomp[7]) begin
		tail0 <= 8;
		tail1 <= 9;
		tail2 <= 10;
	end
	else if (iqentry_stomp[9] & ~iqentry_stomp[8]) begin
		tail0 <= 9;
		tail1 <= 10;
		tail2 <= 11;
	end
	else if (iqentry_stomp[10] & ~iqentry_stomp[9]) begin
		tail0 <= 10;
		tail1 <= 11;
		tail2 <= 12;
	end
	else if (iqentry_stomp[11] & ~iqentry_stomp[10]) begin
		tail0 <= 11;
		tail1 <= 12;
		tail2 <= 13;
	end
	else if (iqentry_stomp[12] & ~iqentry_stomp[11]) begin
		tail0 <= 12;
		tail1 <= 13;
		tail2 <= 14;
	end
	else if (iqentry_stomp[13] & ~iqentry_stomp[12]) begin
		tail0 <= 13;
		tail1 <= 14;
		tail2 <= 15;
	end
	else if (iqentry_stomp[14] & ~iqentry_stomp[13]) begin
		tail0 <= 14;
		tail1 <= 15;
		tail2 <= 0;
	end
	else if (iqentry_stomp[15] & ~iqentry_stomp[14]) begin
		tail0 <= 15;
		tail1 <= 0;
		tail2 <= 1;
	end
	// otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
end
