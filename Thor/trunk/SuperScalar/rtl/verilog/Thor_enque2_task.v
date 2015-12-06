// enque 0 on tail0 or tail1
task enque0;
input [2:0] tail;
input [2:0] inc;
input test_stomp;
input validate_args;
begin
    if (iqentry_v[tail] == `INV) begin
        if ((({fnIsBranch(opcode0), predict_taken0} == {`TRUE, `TRUE})||(opcode0==`LOOP)) && test_stomp)
            qstomp = `TRUE;
        iqentry_v    [tail]    <=   `VAL;
        iqentry_done [tail]    <=   `INV;
        iqentry_cmt     [tail]    <=   `INV;
        iqentry_out  [tail]    <=   `INV;
        iqentry_res  [tail]    <=   `ZERO;
        iqentry_insnsz[tail]   <=  fnInsnLength(fetchbuf0_instr);
        iqentry_op   [tail]    <=   opcode0; 
        iqentry_fn   [tail]    <=   opcode0==`MLO ? rfoc0[5:0] : fnFunc(fetchbuf0_instr);
        iqentry_cond [tail]    <=   cond0;
        iqentry_bt   [tail]    <=   fnIsFlowCtrl(opcode0) && predict_taken0; 
        iqentry_agen [tail]    <=   `INV;
        iqentry_pc   [tail]    <=   
            (opcode0==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail-3'd1]==`VAL) ? (string_pc != 0 ? string_pc :
                iqentry_pc[tail-3'd1]) : fetchbuf0_pc;
        iqentry_mem  [tail]    <=   fetchbuf0_mem;
        iqentry_jmp  [tail]    <=   fetchbuf0_jmp;
        iqentry_fp   [tail]    <=   fetchbuf0_fp;
        iqentry_rfw  [tail]    <=   fetchbuf0_rfw;
        iqentry_tgt  [tail]    <=   fnTargetReg(fetchbuf0_instr);
        iqentry_pred [tail]    <=   pregs[Pn0];
        iqentry_p_s  [tail]    <=   rf_source [{1'b1,2'h0,Pn0}];
        // Look at the previous queue slot to see if an immediate prefix is enqueued
        iqentry_a0[tail]   <=      opcode0==`INT ? fnImm(fetchbuf0_instr) :
                                    fnIsBranch(opcode0) ? {{DBW-12{fetchbuf0_instr[11]}},fetchbuf0_instr[11:8],fetchbuf0_instr[23:16]} : 
                                    iqentry_op[tail-3'd1]==`IMM && iqentry_v[tail-3'd1] ? {iqentry_a0[tail-3'd1][DBW-1:8],fnImm8(fetchbuf0_instr)}:
                                    opcode0==`IMM ? fnImmImm(fetchbuf0_instr) :
                                    fnImm(fetchbuf0_instr);
        iqentry_a1   [tail]    <=   //fnIsFlowCtrl(opcode0) ? bregs0 : rfoa0;
                                        fnOpa(opcode0,fetchbuf0_instr,rfoa0,fetchbuf0_pc);
        iqentry_a1_s [tail]    <=   rf_source [fnRa(fetchbuf0_instr)];
        iqentry_a2   [tail]    <=   fnIsShiftiop(fetchbuf0_instr) ? {58'b0,fetchbuf0_instr[`INSTRUCTION_RB]} :
                                     opcode0==`INC ? {{56{fetchbuf0_instr[47]}},fetchbuf0_instr[47:40]} : 
                                     opcode0==`STI ? fetchbuf0_instr[27:22] :
                                     Rb0[6] ? fnSpr(Rb0[5:0]) :
                                     rfob0;
        iqentry_a2_s [tail]    <=   rf_source [Rb0];
        iqentry_a3   [tail]    <=   rfoc0;
        iqentry_a3_s [tail]    <=   rf_source[Rc0];
        begin
        iqentry_p_v  [tail]    <=   rf_v [{1'b1,2'h0,Pn0}] || cond0 < 4'h2;
        iqentry_a1_v [tail]    <=   fnSource1_v( opcode0 ) | rf_v[ fnRa(fetchbuf0_instr) ];
        iqentry_a2_v [tail]    <=   fnSource2_v( opcode0, fnFunc(fetchbuf0_instr)) | rf_v[Rb0];
        iqentry_a3_v [tail]    <=   fnSource3_v( opcode0 ) | rf_v[ Rc0 ];
        if (fetchbuf0_rfw|fetchbuf0_pfw) begin
            $display("regv[%d] = %d", fnTargetReg(fetchbuf0_instr),rf_v[ fnTargetReg(fetchbuf0_instr) ]);
            rf_v[ fnTargetReg(fetchbuf0_instr) ] = fnTargetReg(fetchbuf0_instr)==7'd0;
            $display("reg[%d] <= INV",fnTargetReg(fetchbuf0_instr));
            rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { /*fetchbuf0_mem*/1'b0, tail };    // top bit indicates ALU/MEM bus
        end
        end
        tail0 <= tail0 + inc;
        tail1 <= tail1 + inc;
        if (inc==2) queued2=`TRUE; else queued1 = `TRUE;
        rrmapno <= rrmapno + 3'd1;
    end
end
endtask

// enque 1 on tail0 or tail1
task enque1;
input [2:0] tail;
input [2:0] inc;
input test_stomp;
input validate_args;
begin
    if (iqentry_v[tail] == `INV && !qstomp) begin
        if ((({fnIsBranch(opcode1), predict_taken1} == {`TRUE, `TRUE})||(opcode1==`LOOP)) && test_stomp)
            qstomp = `TRUE;
        iqentry_v    [tail]    <=   `VAL;
        iqentry_done [tail]    <=   `INV;
        iqentry_cmt     [tail]    <=   `INV;
        iqentry_out  [tail]    <=   `INV;
        iqentry_res  [tail]    <=   `ZERO;
        iqentry_insnsz[tail]   <=  fnInsnLength(fetchbuf1_instr);
        iqentry_op   [tail]    <=   opcode1;
        iqentry_fn   [tail]    <=   opcode1==`MLO ? rfoc1[5:0] : fnFunc(fetchbuf1_instr);
        iqentry_cond [tail]    <=   cond1;
        iqentry_bt   [tail]    <=   fnIsFlowCtrl(opcode1) && predict_taken1; 
        iqentry_agen [tail]    <=   `INV;
        // If an interrupt is being enqueued and the previous instruction was an immediate prefix, then
        // inherit the address of the previous instruction, so that the prefix will be executed on return
        // from interrupt.
        // If a string operation was in progress then inherit the address of the string operation so that
        // it can be continued.
        
        iqentry_pc   [tail]    <=    
            (opcode1==`INT && iqentry_op[tail0-3'd1]==`IMM && iqentry_v[tail-3'd1]==`VAL) ? 
                (string_pc != 64'd0 ? string_pc : iqentry_pc[tail-3'd1]) : fetchbuf1_pc;
        //iqentry_pc   [tail0]    <=   fetchbuf1_pc;
        iqentry_mem  [tail]    <=   fetchbuf1_mem;
        iqentry_jmp  [tail]    <=   fetchbuf1_jmp;
        iqentry_fp   [tail]    <=   fetchbuf1_fp;
        iqentry_rfw  [tail]    <=   fetchbuf1_rfw;
        iqentry_tgt  [tail]    <=   fnTargetReg(fetchbuf1_instr);
        iqentry_pred [tail]    <=   pregs[Pn1];
        iqentry_p_s  [tail]    <=   rf_source [{1'b1,2'h0,Pn1}];
        // Look at the previous queue slot to see if an immediate prefix is enqueued
        // But don't allow it for a branch
        iqentry_a0[tail]   <=       opcode1==`INT ? fnImm(fetchbuf1_instr) :
                                    fnIsBranch(opcode1) ? {{DBW-12{fetchbuf1_instr[11]}},fetchbuf1_instr[11:8],fetchbuf1_instr[23:16]} :
                                    (inc==3'd2 && opcode0==`IMM) ? {fnImmImm(fetchbuf0_instr)|fnImm8(fetchbuf1_instr)} :
                                    iqentry_op[tail-3'd1]==`IMM && iqentry_v[tail-3'd1] ? {iqentry_a0[tail-3'd1][DBW-1:8],fnImm8(fetchbuf1_instr)} :
                                    opcode1==`IMM ? fnImmImm(fetchbuf1_instr) :
                                    fnImm(fetchbuf1_instr);
        iqentry_a1   [tail]    <=   //fnIsFlowCtrl(opcode1) ? bregs1 : rfoa1;
                                        fnOpa(opcode1,fetchbuf1_instr,rfoa1,fetchbuf1_pc);
        iqentry_a1_s [tail]    <=   rf_source [fnRa(fetchbuf1_instr)];
        iqentry_a2   [tail]    <=   fnIsShiftiop(fetchbuf1_instr) ? {{DBW-6{1'b0}},fetchbuf1_instr[`INSTRUCTION_RB]} :
                                    opcode1==`INC ? {{56{fetchbuf1_instr[47]}},fetchbuf1_instr[47:40]} : 
                                    opcode1==`STI ? fetchbuf1_instr[27:22] :
                                    Rb1[6] ? fnSpr(Rb1[5:0]) :
                                    rfob1;
        iqentry_a2_s [tail]    <=   rf_source[Rb1];
        iqentry_a3   [tail]    <=   rfoc1;
        iqentry_a3_s [tail]    <=   rf_source[Rc1];
        if (validate_args) begin
        // The predicate is automatically valid for condiitions 0 and 1 (always false or always true).
        iqentry_p_v  [tail]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
        iqentry_a1_v [tail]    <=   fnSource1_v( opcode1 ) | rf_v[ fnRa(fetchbuf1_instr) ];
        iqentry_a2_v [tail]    <=   fnSource2_v( opcode1, fnFunc(fetchbuf1_instr) ) | rf_v[ Rb1 ];
        iqentry_a3_v [tail]    <=   fnSource3_v( opcode1 ) | rf_v[ Rc1 ];
        if (fetchbuf1_rfw|fetchbuf1_pfw) begin
            $display("1:regv[%d] = %d", fnTargetReg(fetchbuf1_instr),rf_v[ fnTargetReg(fetchbuf1_instr) ]);
            rf_v[ fnTargetReg(fetchbuf1_instr) ] = fnTargetReg(fetchbuf1_instr)==7'd0;
            $display("reg[%d] <= INV",fnTargetReg(fetchbuf1_instr));
            rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { /*fetchbuf1_mem*/1'b0, tail };    // top bit indicates ALU/MEM bus
        end
        end
        tail0 <= tail0 + inc;
        tail1 <= tail1 + inc;
        if (inc==2) queued2=`TRUE; else queued1 = `TRUE;
    end
end
endtask

task validate_args;
begin
    // SOURCE 1 ... this is relatively straightforward, because all instructions
       // that have a source (i.e. every instruction but LUI) read from RB
       //
       // if the argument is an immediate or not needed, we're done
       if (fnSource1_v( opcode1 ) == `VAL) begin
           iqentry_a1_v [tail1] <= `VAL;
//                    iqentry_a1_s [tail1] <= 4'd0;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (~fetchbuf0_rfw) begin
           begin
               iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
               iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
           end
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (fnTargetReg(fetchbuf0_instr) != 7'd0
           && fnRa(fetchbuf1_instr) == fnTargetReg(fetchbuf0_instr)) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           iqentry_a1_v [tail1]    <=   `INV;
           iqentry_a1_s [tail1]    <=   { fetchbuf0_mem, tail0 };
       end
       // if no overlap, get info from rf_v and rf_source
       else begin
           begin
               iqentry_a1_v [tail1]    <=   rf_v [fnRa(fetchbuf1_instr)];
               iqentry_a1_s [tail1]    <=   rf_source [fnRa(fetchbuf1_instr)];
           end
       end

       if (~fetchbuf0_pfw) begin
           iqentry_p_v  [tail1]    <=   rf_v [{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
           iqentry_p_s  [tail1]    <=   rf_source [{1'b1,2'h0,Pn1}];
       end
       else if (fnTargetReg(fetchbuf0_instr) != 9'd0 && fetchbuf1_instr[7:4]==fnTargetReg(fetchbuf0_instr) & 4'hF
           && (fnTargetReg(fetchbuf0_instr) & 7'h70)==7'h40) begin
           iqentry_p_v [tail1] <= cond1 < 4'h2;
           iqentry_p_s [tail1] <= { fetchbuf0_mem, tail0 };
       end
       else begin
           iqentry_p_v [tail1] <= rf_v[{1'b1,2'h0,Pn1}] || cond1 < 4'h2;
           iqentry_p_s [tail1] <= rf_source[{1'b1,2'h0,Pn1}];
       end

       //
       // SOURCE 2 ... this is more contorted than the logic for SOURCE 1 because
       // some instructions (NAND and ADD) read from RC and others (SW, BEQ) read from RA
       //
       // if the argument is an immediate or not needed, we're done
       if (fnSource2_v( opcode1,fnFunc(fetchbuf1_instr) ) == `VAL) begin
           iqentry_a2_v [tail1] <= `VAL;
//                    iqentry_a2_s [tail1] <= 4'd0;
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
//                    iqentry_a1_s [tail1] <= 4'd0;
       end
       // if previous instruction writes nothing to RF, then get info from rf_v and rf_source
       else if (~fetchbuf0_rfw) begin
           begin
               iqentry_a3_v [tail1]    <=   rf_v [Rc1];
               iqentry_a3_s [tail1]    <=   rf_source [Rc1];
           end
       end
       // otherwise, previous instruction does write to RF ... see if overlap
       else if (fnTargetReg(fetchbuf0_instr) != 9'd0
           && Rc1 == fnTargetReg(fetchbuf0_instr)) begin
           // if the previous instruction is a LW, then grab result from memq, not the iq
           iqentry_a3_v [tail1]    <=   `INV;
           iqentry_a3_s [tail1]    <=   { fetchbuf0_mem, tail0 };
       end
       // if no overlap, get info from rf_v and rf_source
       else begin
           begin
               iqentry_a3_v [tail1]    <=   rf_v [Rc1];
               iqentry_a3_s [tail1]    <=   rf_source [Rc1];
           end
       end

        if (fetchbuf0_rfw|fetchbuf0_pfw) begin
            $display("regv[%d] = %d", fnTargetReg(fetchbuf0_instr),rf_v[ fnTargetReg(fetchbuf0_instr) ]);
            rf_v[ fnTargetReg(fetchbuf0_instr) ] = fnTargetReg(fetchbuf0_instr)==7'd0;
            $display("reg[%d] <= INV",fnTargetReg(fetchbuf0_instr));
            rf_source[ fnTargetReg(fetchbuf0_instr) ] <= { /*fetchbuf0_mem*/1'b0, tail0 };    // top bit indicates ALU/MEM bus
        end
        if (fetchbuf1_rfw|fetchbuf1_pfw) begin
            $display("1:regv[%d] = %d", fnTargetReg(fetchbuf1_instr),rf_v[ fnTargetReg(fetchbuf1_instr) ]);
            rf_v[ fnTargetReg(fetchbuf1_instr) ] = fnTargetReg(fetchbuf1_instr)==7'd0;
            $display("reg[%d] <= INV",fnTargetReg(fetchbuf1_instr));
            rf_source[ fnTargetReg(fetchbuf1_instr) ] <= { /*fetchbuf1_mem*/1'b0, tail1 };    // top bit indicates ALU/MEM bus
        end
end
endtask

