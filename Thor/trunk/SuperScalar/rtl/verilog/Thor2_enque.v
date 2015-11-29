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
// Thor SuperScalar
// Instruction enque logic
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

	case ({fetchbuf0_v, fetchbuf1_v, fetchbuf2_v, fetchbuf3_v})

	4'b0000: ; // do nothing
	
	4'b0001:
			if (iqentry_v[tail0] == `INV) begin
				iqentry_v    [tail0]    <=   `VAL;
				iqentry_done [tail0]    <=   `INV;
				iqentry_cmt	 [tail0]    <=   `INV;
				iqentry_out  [tail0]    <=   `INV;
				iqentry_res  [tail0]    <=   `ZERO;
				iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf3_instr);
				iqentry_op   [tail0]    <=   opcode3;
				iqentry_fn   [tail0]    <=   fnFunc(fetchbuf3_instr);
				iqentry_cond [tail0]    <=   cond3;
				iqentry_bt   [tail0]    <=   fnIsFlowCtrl(opcode3) && predict_taken3; 
				iqentry_agen [tail0]    <=   `INV;
				// If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
				// inherit the address of the previous instruction, so that the prefix will be executed on return
				// from interrupt.
				// If a string operation was in progress then inherit the address of the string operation so that
				// it can be continued.
				iqentry_pc   [tail0]    <=	
					(opcode3==`INT && iqentry_op[tail0-4'd1]==`IMM && iqentry_v[tail0-4'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-4'd1]) : fetchbuf3_pc;
				//iqentry_pc   [tail0]    <=   fetchbuf1_pc;
				iqentry_mem  [tail0]    <=   fetchbuf3_mem;
				iqentry_jmp  [tail0]    <=   fetchbuf3_jmp;
				iqentry_fp   [tail0]    <=   fetchbuf3_fp;
				iqentry_rfw  [tail0]    <=   fetchbuf3_rfw;
				iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf3_instr);
				iqentry_pred [tail0]    <=   pregs[Pn3];
				// The predicate is automatically valid for condiitions 0 and 1 (always false or always true).
				iqentry_p_v  [tail0]    <=   rf_v [7'd80+Pn3] || cond3 < 4'h2;
				iqentry_p_s  [tail0]    <=   rf_source [7'd80+Pn3];
				// Look at the previous queue slot to see if an immediate prefix is enqueued
				// But don't allow it for a branch
				iqentry_a0[tail0]   <=  	opcode3==`INT ? fnImm(fetchbuf3_instr) :
											fnIsBranch(opcode3) ? {{DBW-12{fetchbuf3_instr[11]}},fetchbuf3_instr[11:8],fetchbuf3_instr[23:16]} :
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? {iqentry_a0[tail0-3'd1][DBW-1:8],fnImm8(fetchbuf3_instr)} :
											opcode3==`IMM ? fnImmImm(fetchbuf3_instr) :
											fnImm(fetchbuf3_instr);
				iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
												fnOpa(opcode3,fetchbuf3_instr,rfoa3,fetchbuf3_pc);
				iqentry_a1_v [tail0]    <=   fnSource1_v( opcode3 ) | rf_v[ fnRa(fetchbuf3_instr) ];
				iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf3_instr)];
				iqentry_a2   [tail0]    <=   fnIsShiftiop(opcode3) ? {{DBW-6{1'b0}},Rb3[5:0]} : opcode3==`STI ? fetchbuf3_instr[31:22] : rfob3;
				iqentry_a2_v [tail0]    <=   fnSource2_v( opcode3 ) | rf_v[ Rb3 ];
				iqentry_a2_s [tail0]    <=   rf_source[Rb3];
				iqentry_a3   [tail0]    <=   rfob0;
				iqentry_a3_v [tail0]    <=   fnSource3_v( opcode3 ) | rf_v[ Rb0 ];
				iqentry_a3_s [tail0]    <=   rf_source[Rb0];
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				tail2 <= tail2 + 1;
				tail3 <= tail3 + 1;
				if (fetchbuf3_rfw|fetchbuf3_pfw) begin
					rf_v[ fnTargetReg(fetchbuf3_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf3_instr) ] <= { fetchbuf3_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end

	4'b0100:
			if (iqentry_v[tail0] == `INV) begin
				iqentry_v    [tail0]    <=   `VAL;
				iqentry_done [tail0]    <=   `INV;
				iqentry_cmt	 [tail0]    <=   `INV;
				iqentry_out  [tail0]    <=   `INV;
				iqentry_res  [tail0]    <=   `ZERO;
				iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf1_instr);
				iqentry_op   [tail0]    <=   opcode1;
				iqentry_fn   [tail0]    <=   fnFunc(fetchbuf1_instr);
				iqentry_cond [tail0]    <=   cond1;
				iqentry_bt   [tail0]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
				iqentry_agen [tail0]    <=   `INV;
				// If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
				// inherit the address of the previous instruction, so that the prefix will be executed on return
				// from interrupt.
				// If a string operation was in progress then inherit the address of the string operation so that
				// it can be continued.
				iqentry_pc   [tail0]    <=	
					(opcode1==`INT && iqentry_op[tail0-4'd1]==`IMM && iqentry_v[tail0-4'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-4'd1]) : fetchbuf1_pc;
				//iqentry_pc   [tail0]    <=   fetchbuf1_pc;
				iqentry_mem  [tail0]    <=   fetchbuf1_mem;
				iqentry_jmp  [tail0]    <=   fetchbuf1_jmp;
				iqentry_fp   [tail0]    <=   fetchbuf1_fp;
				iqentry_rfw  [tail0]    <=   fetchbuf1_rfw;
				iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf1_instr);
				iqentry_pred [tail0]    <=   pregs[Pn1];
				// The predicate is automatically valid for condiitions 0 and 1 (always false or always true).
				iqentry_p_v  [tail0]    <=   rf_v [7'd80+Pn1] || cond1 < 4'h2;
				iqentry_p_s  [tail0]    <=   rf_source [7'd80+Pn1];
				// Look at the previous queue slot to see if an immediate prefix is enqueued
				// But don't allow it for a branch
				iqentry_a0[tail0]   <=  	opcode1==`INT ? fnImm(fetchbuf1_instr) :
											fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} :
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? {iqentry_a0[tail0-3'd1][DBW-1:8],fnImm8(fetchbuf1_instr)} :
											opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
											fnImm(fetchbuf1_instr);
				iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
												fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
				iqentry_a1_v [tail0]    <=   fnSource1_v( opcode1 ) | rf_v[ fnRa(fetchbuf1_instr) ];
				iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf1_instr)];
				iqentry_a2   [tail0]    <=   fnIsShiftiop(opcode1) ? {{DBW-6{1'b0}},Rb1[5:0]} : opcode1==`STI ? fetchbuf1_instr[31:22] : rfob1;
				iqentry_a2_v [tail0]    <=   fnSource2_v( opcode1 ) | rf_v[ Rb1 ];
				iqentry_a2_s [tail0]    <=   rf_source[Rb1];
				iqentry_a3   [tail0]    <=   rfob0;
				iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Rb0 ];
				iqentry_a3_s [tail0]    <=   rf_source[Rb0];
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				if (fetchbuf1_rfw|fetchbuf1_pfw) begin
					rf_v[ fnTargetReg(fetchbuf1_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { fetchbuf1_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end

	2'b10:
			if (iqentry_v[tail0] == `INV) begin

				iqentry_v    [tail0]    <=   `VAL;
				iqentry_done [tail0]    <=   `INV;
				iqentry_cmt	 [tail0]    <=   `INV;
				iqentry_out  [tail0]    <=   `INV;
				iqentry_res  [tail0]    <=   `ZERO;
				iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
				iqentry_op   [tail0]    <=   opcode0; 
				iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
				iqentry_cond [tail0]    <=   cond0;
				iqentry_bt   [tail0]    <=   fnIsFlowCtrl(opcode0) && predict_taken0; 
				iqentry_agen [tail0]    <=   `INV;
				iqentry_pc   [tail0]    <=   
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
				iqentry_mem  [tail0]    <=   fetchbuf0_mem;
				iqentry_jmp  [tail0]    <=   fetchbuf0_jmp;
				iqentry_fp   [tail0]    <=   fetchbuf0_fp;
				iqentry_rfw  [tail0]    <=   fetchbuf0_rfw;
				iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf0_instr);
				iqentry_pred [tail0]    <=   pregs[Pn0];
				iqentry_p_v  [tail0]    <=   rf_v [{1'b1,4'h0,Pn0}] || cond0 < 4'h2;
				iqentry_p_s  [tail0]    <=   rf_source [{1'b1,4'h0,Pn0}];
				// Look at the previous queue slot to see if an immediate prefix is enqueued
				iqentry_a0[tail0]   <=  	opcode0==`INT ? fnImm(fetchbuf0_instr) :
											fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? iqentry_a0[tail0-3'd1] | fnImm8(fetchbuf0_instr):
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
											fnImm(fetchbuf0_instr);
				iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
				iqentry_a1_v [tail0]    <=   fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
				iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf0_instr)];
				iqentry_a2   [tail0]    <=   fnIsShiftiop(opcode0) ? {58'b0,Rb0[5:0]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
				iqentry_a2_v [tail0]    <=   fnSource2_v( opcode0) | rf_v[Rb0];
				iqentry_a2_s [tail0]    <=   rf_source [Rb0];
				iqentry_a3   [tail0]    <=   rfoa1;
				iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Ra1 ];
				iqentry_a3_s [tail0]    <=   rf_source[Ra1];
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
				if (fetchbuf0_rfw|fetchbuf0_pfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { fetchbuf0_mem, tail0 };	// top bit indicates ALU/MEM bus
				end
			end
	
		2'b11: if (iqentry_v[tail0] == `INV) begin

		//
		// if the first instruction is a backwards branch, enqueue it & stomp on all following instructions
		//
		if ({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE}) begin
			iqentry_v    [tail0]    <=	`VAL;
			iqentry_done [tail0]    <=	`INV;
			iqentry_cmt	 [tail0]    <=  `INV;
			iqentry_out  [tail0]    <=	`INV;
			iqentry_res  [tail0]    <=	`ZERO;
			iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
			iqentry_op   [tail0]    <=	opcode0; 			// BEQ
			iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
			iqentry_cond [tail0]    <=   cond0;
			iqentry_bt   [tail0]    <=	`VAL;
			iqentry_agen [tail0]    <=	`INV;
			iqentry_pc   [tail0]    <=	
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
			iqentry_mem  [tail0]    <=	fetchbuf0_mem;
			iqentry_jmp  [tail0]    <=	fetchbuf0_jmp;
			iqentry_fp   [tail0]    <=  fetchbuf0_fp;
			iqentry_rfw  [tail0]    <=	fetchbuf0_rfw;
			iqentry_tgt  [tail0]    <=	fnTargetReg(fetchbuf0_instr);
			iqentry_pred [tail0]    <=   pregs[Pn0];
			iqentry_p_v  [tail0]    <=   rf_v [{1'b1,4'h0,Pn0}] || cond0 < 4'h2;
			iqentry_p_s  [tail0]    <=   rf_source [{1'b1,4'h0,Pn0}];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail0]   	<=  opcode0==`INT ? fnImm(fetchbuf0_instr) :
										fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? iqentry_a0[tail0-3'd1] | fnImm8(fetchbuf0_instr):
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
										fnImm(fetchbuf0_instr);
			iqentry_a1   [tail0]    <=	//fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
			iqentry_a1_v [tail0]    <=	fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
			iqentry_a1_s [tail0]    <=	rf_source [fnRa(fetchbuf0_instr)];
			iqentry_a2   [tail0]    <=	fnIsShiftiop(opcode0) ? {58'b0,Rb0[5:0]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
			iqentry_a2_v [tail0]    <=	fnSource2_v( opcode0 ) | rf_v[ Rb0 ];
			iqentry_a2_s [tail0]    <=	rf_source[ Rb0 ];
			iqentry_a3   [tail0]    <=   rfoa1;
			iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Ra1 ];
			iqentry_a3_s [tail0]    <=   rf_source[Ra1];
			tail0 <= tail0 + 1;
			tail1 <= tail1 + 1;

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
				tail0 <= tail0 + 2;
				tail1 <= tail1 + 2;
			end
			else begin
				tail0 <= tail0 + 1;
				tail1 <= tail1 + 1;
			end
			//
			// enqueue the first instruction ...
			//
			iqentry_v    [tail0]    <=   `VAL;
			iqentry_done [tail0]    <=   `INV;
			iqentry_cmt  [tail0]    <=   `INV;
			iqentry_out  [tail0]    <=   `INV;
			iqentry_res  [tail0]    <=   `ZERO;
			iqentry_insnsz[tail0]   <=  fnInsnLength(fetchbuf0_instr);
			iqentry_op   [tail0]    <=  opcode0;
			iqentry_fn   [tail0]    <=   fnFunc(fetchbuf0_instr);
			iqentry_cond [tail0]    <=   cond0;
			iqentry_bt   [tail0]    <=   `INV;
			iqentry_agen [tail0]    <=   `INV;
			iqentry_pc   [tail0]    <=
					(opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1]==`VAL) ? 
						(string_pc != 64'd0 ? string_pc : iqentry_pc[tail0-3'd1]) : fetchbuf0_pc;
			iqentry_mem  [tail0]    <=   fetchbuf0_mem;
			iqentry_jmp  [tail0]    <=   fetchbuf0_jmp;
			iqentry_fp   [tail0]    <=   fetchbuf0_fp;
			iqentry_rfw  [tail0]    <=   fetchbuf0_rfw;
			iqentry_tgt  [tail0]    <=   fnTargetReg(fetchbuf0_instr);
			iqentry_pred [tail0]    <=   pregs[Pn0];
			iqentry_p_v  [tail0]    <=   rf_v [{1'b1,4'h0,Pn0}] || cond0 < 4'h2;
			iqentry_p_s  [tail0]    <=   rf_source [{1'b1,4'h0,Pn0}];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail0]   	<=  opcode0==`INT ? fnImm(fetchbuf0_instr) :
										fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
											iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail0-3'd1] ? {iqentry_a0[tail0-3'd1][DBW-1:8],fnImm8(fetchbuf0_instr)}:
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
										fnImm(fetchbuf0_instr);
			iqentry_a1   [tail0]    <=   //fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
												fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
			iqentry_a1_v [tail0]    <=   fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
							
			iqentry_a1_s [tail0]    <=   rf_source [fnRa(fetchbuf0_instr)];
			iqentry_a2   [tail0]    <=   fnIsShiftiop(opcode0) ? {58'b0,Rb0[5:0]} : opcode0==`STI ? fetchbuf0_instr[31:22] : rfob0;
			iqentry_a2_v [tail0]    <=   fnSource2_v( opcode0 ) | rf_v[ Rb0 ];
			iqentry_a2_s [tail0]    <=   rf_source[Rb0];
			iqentry_a3   [tail0]    <=   rfoa1;
			iqentry_a3_v [tail0]    <=   fnSource3_v( opcode1 ) | rf_v[ Ra1 ];
			iqentry_a3_s [tail0]    <=   rf_source[Ra1];
			//
			// if there is room for a second instruction, enqueue it
			//
			if (iqentry_v[tail1] == `INV) begin
			iqentry_v    [tail1]    <=   `VAL;
			iqentry_done [tail1]    <=   `INV;
			iqentry_cmt  [tail1]    <=   `INV;
			iqentry_out  [tail1]    <=   `INV;
			iqentry_res  [tail1]    <=   `ZERO;
			iqentry_insnsz[tail1]   <=  fnInsnLength(fetchbuf1_instr);
			iqentry_op   [tail1]    <=   opcode1; 
			iqentry_fn   [tail1]    <=   fnFunc(fetchbuf1_instr);
			iqentry_cond [tail1]    <=   cond1;
			iqentry_bt   [tail1]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
			iqentry_agen [tail1]    <=   `INV;
			iqentry_pc   [tail1]    <=   (opcode1==`INT && opcode0==`IMM) ? (string_pc != 64'd0 ? string_pc : fetchbuf0_pc) : fetchbuf1_pc;
			iqentry_mem  [tail1]    <=   fetchbuf1_mem;
			iqentry_jmp  [tail1]    <=   fetchbuf1_jmp;
			iqentry_fp   [tail1]    <=   fetchbuf1_fp;
			iqentry_rfw  [tail1]    <=   fetchbuf1_rfw;
			iqentry_tgt  [tail1]    <=   fnTargetReg(fetchbuf1_instr);
			iqentry_pred [tail1]    <=   pregs[Pn1];
			// Look at the previous queue slot to see if an immediate prefix is enqueued
			iqentry_a0[tail1]   <=  	opcode1==`INT ? fnImm(fetchbuf1_instr) :
										fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} : 
											opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
											opcode0==`IMM ? fnImmImm(fetchbuf0_instr) | fnImm8(fetchbuf1_instr) :
										fnImm(fetchbuf1_instr);
			iqentry_a1   [tail1]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
												(fnNumReadPorts(fetchbuf1_instr) < 3'd2) ?
												  fnOpa(opcode1,fetchbuf1_instr,rfob1,fetchbuf1_pc)
												: fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
			iqentry_a2   [tail1]    <=   fnIsShiftiop(opcode1) ? {58'b0,Rb1[5:0]} : opcode1==`STI ? fetchbuf1_instr[31:22] : rfob1;
			iqentry_a3   [tail1]    <=   rfob0;
			// a1/a2_v and a1/a2_s values require a bit of thinking ...

			//
			// SOURCE 1 ... this is relatively straightforward, because all instructions
			// that have a source (i.e. every instruction but LUI) read from RB
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource1_v( opcode1 ) == `VAL) begin
				iqentry_a1_v [tail1] <= `VAL;
//					iqentry_a1_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				if (fnNumReadPorts(fetchbuf1_instr) < 3'd2) begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRb(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRb(fetchbuf1_instr)];
				end
				else begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
				end
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0
				&& fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a1_v [tail1]    <=   `INV;
				iqentry_a1_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				if (fnNumReadPorts(fetchbuf1_instr) < 3'd2) begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRb(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRb(fetchbuf1_instr)];
				end
				else begin
					iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
					iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
				end
			end

			if (~fetchbuf0_pfw) begin
				iqentry_p_v  [tail1]    <=   rf_v [{1'b1,4'h0,Pn1}] || cond1 < 4'h2;
				iqentry_p_s  [tail1]    <=   rf_source [{1'b1,4'h0,Pn1}];
			end
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0 && fetchbuf1_instr[7:4]==fnTargetReg(fetchbuf0_instr) & 4'hF) begin
				iqentry_p_v [tail1] <= cond1 < 4'h2;
				iqentry_p_s [tail1] <= { fetchbuf0_mem, tail0 };
			end
			else begin
				iqentry_p_v [tail1] <= rf_v[{1'b1,4'h0,Pn1}] || cond1 < 4'h2;
				iqentry_p_s [tail1] <= rf_source[{1'b1,4'h0,Pn1}];
			end

			//
			// SOURCE 2 ... this is more contorted than the logic for SOURCE 1 because
			// some instructions (NAND and ADD) read from RC and others (SW, BEQ) read from RA
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource2_v( opcode1 ) == `VAL) begin
				iqentry_a2_v [tail1] <= `VAL;
//					iqentry_a2_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				iqentry_a2_v [tail1] <= rf_v[ Rb1 ];
				iqentry_a2_s [tail1] <= rf_source[Rb1];
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0 &&
				Rb1 == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a2_v [tail1]    <=   `INV;
				iqentry_a2_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				iqentry_a2_v [tail1] <= rf_v[ Rb1 ];
				iqentry_a2_s [tail1] <= rf_source[Rb1];
			end

			//
			// SOURCE 3 ... this is relatively straightforward, because all instructions
			// that have a source (i.e. every instruction but LUI) read from RC
			//
			// if the argument is an immediate or not needed, we're done
			if (fnSource3_v( opcode1 ) == `VAL) begin
				iqentry_a3_v [tail1] <= `VAL;
//					iqentry_a1_s [tail1] <= 4'd0;
			end
			// if previous instruction writes nothing to RF, then get info from rf_v and rf_source
			else if (~fetchbuf0_rfw) begin
				if (fnNumReadPorts(fetchbuf1_instr) < 3'd2) begin
					iqentry_a3_v [tail1]    <=   `VAL;
				end
				else begin
					iqentry_a3_v [tail1]    <=   rf_v [Rb0];
					iqentry_a3_s [tail1]    <=   rf_source [Rb0];
				end
			end
			// otherwise, previous instruction does write to RF ... see if overlap
			else if (fnTargetReg(fetchbuf0_instr) != 9'd0
				&& Rb0 == fnTargetReg(fetchbuf0_instr)) begin
				// if the previous instruction is a LW, then grab result from memq, not the iq
				iqentry_a3_v [tail1]    <=   `INV;
				iqentry_a3_s [tail1]    <=   { fetchbuf0_mem, tail0 };
			end
			// if no overlap, get info from rf_v and rf_source
			else begin
				if (fnNumReadPorts(fetchbuf1_instr) < 3'd2) begin
					iqentry_a3_v [tail1]    <=   `VAL;
				end
				else begin
					iqentry_a3_v [tail1]    <=   rf_v [Rb0];
					iqentry_a3_s [tail1]    <=   rf_source [Rb0];
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

			end	// ends the "if IQ[tail1] is available" clause
			else begin	// only first instruction was enqueued
				if (fetchbuf0_rfw) begin
					rf_v[ fnTargetReg(fetchbuf0_instr) ] = `INV;
					rf_source[ fnTargetReg(fetchbuf0_instr) ] <= {fetchbuf0_mem, tail0};
				end
			end

		end	// ends the "else fetchbuf0 doesn't have a backwards branch" clause
		end
	endcase
	end
	else begin	// if branchmiss
		if ((iqentry_stomp[0] & ~iqentry_stomp[15]) || stomp_all) begin
			tail0 <= 0;
			tail1 <= 1;
			tail2 <= 2;
			tail3 <= 3;
		end
		else if (iqentry_stomp[1] & ~iqentry_stomp[0]) begin
			tail0 <= 1;
			tail1 <= 2;
			tail2 <= 3;
			tail3 <= 4;
		end
		else if (iqentry_stomp[2] & ~iqentry_stomp[1]) begin
			tail0 <= 2;
			tail1 <= 3;
			tail2 <= 4;
			tail3 <= 5;
		end
		else if (iqentry_stomp[3] & ~iqentry_stomp[2]) begin
			tail0 <= 3;
			tail1 <= 4;
			tail2 <= 5;
			tail3 <= 6;
		end
		else if (iqentry_stomp[4] & ~iqentry_stomp[3]) begin
			tail0 <= 4;
			tail1 <= 5;
			tail2 <= 6;
			tail3 <= 7;
		end
		else if (iqentry_stomp[5] & ~iqentry_stomp[4]) begin
			tail0 <= 5;
			tail1 <= 6;
			tail2 <= 7;
			tail3 <= 8;
		end
		else if (iqentry_stomp[6] & ~iqentry_stomp[5]) begin
			tail0 <= 6;
			tail1 <= 7;
			tail2 <= 8;
			tail3 <= 9;
		end
		else if (iqentry_stomp[7] & ~iqentry_stomp[6]) begin
			tail0 <= 7;
			tail1 <= 8;
			tail2 <= 9;
			tail3 <= 10;
		end
		else if (iqentry_stomp[8] & ~iqentry_stomp[7]) begin
			tail0 <= 8;
			tail1 <= 9;
			tail2 <= 10;
			tail3 <= 11;
		end
		else if (iqentry_stomp[9] & ~iqentry_stomp[8]) begin
			tail0 <= 9;
			tail1 <= 10;
			tail2 <= 11;
			tail3 <= 12;
		end
		else if (iqentry_stomp[10] & ~iqentry_stomp[9]) begin
			tail0 <= 10;
			tail1 <= 11;
			tail2 <= 12;
			tail3 <= 13;
		end
		else if (iqentry_stomp[11] & ~iqentry_stomp[10]) begin
			tail0 <= 11;
			tail1 <= 12;
			tail2 <= 13;
			tail3 <= 14;
		end
		else if (iqentry_stomp[12] & ~iqentry_stomp[11]) begin
			tail0 <= 12;
			tail1 <= 13;
			tail2 <= 14;
			tail3 <= 15;
		end
		else if (iqentry_stomp[13] & ~iqentry_stomp[12]) begin
			tail0 <= 13;
			tail1 <= 14;
			tail2 <= 15;
			tail3 <= 0;
		end
		else if (iqentry_stomp[14] & ~iqentry_stomp[13]) begin
			tail0 <= 14;
			tail1 <= 15;
			tail2 <= 0;
			tail3 <= 1;
		end
		else if (iqentry_stomp[15] & ~iqentry_stomp[14]) begin
			tail0 <= 15;
			tail1 <= 0;
			tail2 <= 1;
			tail3 <= 2;
		end
		// otherwise, it is the last instruction in the queue that has been mispredicted ... do nothing
	end
