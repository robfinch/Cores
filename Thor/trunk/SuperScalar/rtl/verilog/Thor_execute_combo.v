// ============================================================================
//        __
//   \\__/ o\    (C) 2013-2016  Robert Finch, Stratford
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
// Execute combinational logic
//
// ============================================================================
//
wire [DBW-1:0] alu0_out, alu1_out;
wire alu0_done,alu1_done;
wire alu0_idle,alu1_idle;
wire alu0_divByZero, alu1_divByZero;
wire alu0_abort,alu1_abort;

Thor_alu #(.DBW(DBW),.BIG(1)) ualu0 
(
    .corenum(corenum),
    .rst(rst_i),
    .clk(clk),
    .alu_ld(alu0_ld),
    .alu_abort(alu0_abort),
	.alu_op(alu0_op),
	.alu_fn(alu0_fn),
	.alu_argA(alu0_argA),
	.alu_argB(alu0_argB),
	.alu_argC(alu0_argC),
	.alu_argI(alu0_argI),
	.alu_pc(alu0_pc),
	.insnsz(alu0_insnsz),
	.o(alu0_out),
	.alu_done(alu0_done),
	.alu_idle(alu0_idle),
	.alu_divByZero(alu0_divByZero)
);

Thor_alu #(.DBW(DBW),.BIG(ALU1BIG)) ualu1 
(
    .corenum(corenum),
    .rst(rst_i),
    .clk(clk),
    .alu_ld(alu1_ld),
    .alu_abort(alu1_abort),
	.alu_op(alu1_op),
	.alu_fn(alu1_fn),
	.alu_argA(alu1_argA),
	.alu_argB(alu1_argB),
	.alu_argC(alu1_argC),
	.alu_argI(alu1_argI),
	.alu_pc(alu1_pc),
	.insnsz(alu1_insnsz),
	.o(alu1_out),
	.alu_done(alu1_done),
	.alu_idle(alu1_idle),
    .alu_divByZero(alu1_divByZero)
);

function fnPredicate;
input [3:0] pr;
input [3:0] cond;

case(cond)
PF:		fnPredicate = 1'b0;
PT:		fnPredicate = 1'b1;
PEQ:	fnPredicate =  pr[0];
PNE:	fnPredicate = !pr[0];
PLE:	fnPredicate =  pr[0]|pr[1];
PGT:	fnPredicate = !(pr[0]|pr[1]);
PLT:	fnPredicate =  pr[1];
PGE:	fnPredicate = !pr[1];
PLEU:	fnPredicate =  pr[0]|pr[2];
PGTU:	fnPredicate = !(pr[0]|pr[2]);
PLTU:	fnPredicate =  pr[2];
PGEU:	fnPredicate = !pr[2];
default:	fnPredicate = 1'b1;
endcase

endfunction

wire alu0_cmtw = fnPredicate(alu0_pred, alu0_cond);
wire alu1_cmtw = fnPredicate(alu1_pred, alu1_cond);

always @*
begin
    alu0_cmt <= alu0_cmtw;
    alu1_cmt <= alu1_cmtw;

    alu0_bus <= alu0_cmtw ? alu0_out : alu0_argT;
    alu1_bus <= alu1_cmtw ? alu1_out : alu1_argT;

    alu0_v <= alu0_dataready;
	alu1_v <= alu1_dataready;

    alu0_id <= alu0_sourceid;
	alu1_id <= alu1_sourceid;
end
assign alu0_abort = !alu0_cmt;
assign alu1_abort = !alu1_cmt;

// Special flag bit is used for INT and SYS instructions in order to turn off
// segmentation while the vector jump is taking place.

always @(alu0_op or alu0_fn or alu0_argA or alu0_argI or alu0_insnsz or alu0_pc or alu0_bt)
    case(alu0_op)
    `RTS2,`RTD,`RTE,`RTI:
        alu0_misspc <= alu0_argA;
    `JSR,`JSRS,`JSRZ:
        alu0_misspc <= alu0_argA + alu0_argI;
    `LOOP,`SYNC:
        alu0_misspc <= alu0_pc + alu0_insnsz;
    `RTS:
        alu0_misspc <= alu0_argA + alu0_fn[3:0];
    `SYS,`INT,`RTF,`JSF:
        alu0_misspc <= {1'b1,alu0_argA + alu0_argI};
    default:
//        alu0_misspc <= (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc + alu0_insnsz + alu0_argI);
        
        case(alu0_op[7:4])
        `BR:  alu0_misspc <= (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc + alu0_insnsz + alu0_argI);
        default:  alu0_misspc <= alu0_pc + alu0_insnsz;
        endcase 
    endcase

always @(alu1_op or alu1_fn or alu1_argA or alu1_argI or alu1_insnsz or alu1_pc or alu1_bt)
    case(alu1_op)
    `RTS2,`RTD,`RTE,`RTI:
        alu1_misspc <= alu1_argA;
    `JSR,`JSRS,`JSRZ:
        alu1_misspc <= alu1_argA + alu1_argI;
    `LOOP,`SYNC:
        alu1_misspc <= alu1_pc + alu1_insnsz;
    `RTS:
        alu1_misspc <= alu1_argA + alu1_fn[3:0];
    `SYS,`INT,`RTF,`JSF:
        alu1_misspc <= {1'b1,alu1_argA + alu1_argI};
    default:
//        alu1_misspc <= (alu1_bt ? alu1_pc + alu1_insnsz : alu1_pc + alu1_insnsz + alu1_argI);
        
        case(alu1_op[7:4])
        `BR:  alu1_misspc <= (alu1_bt ? alu1_pc + alu1_insnsz : alu1_pc + alu1_insnsz + alu1_argI);
        default:  alu1_misspc <= alu1_pc + alu1_insnsz;
        endcase 
    endcase
 
always @(dram0_fn or dram0_misspc or dram_bus)
    case (dram0_fn[1:0])
    2'd1:   jmpi_misspc <= {dram0_misspc[DBW-1:16],dram_bus[15:0]};
    2'd2:   jmpi_misspc <= (DBW==32) ? dram_bus[31:0] : {dram0_misspc[63:32],dram_bus[31:0]};
    2'd3:   jmpi_misspc <= dram_bus[DBW-1:0];
    default:    jmpi_misspc <= 32'h00000FA0;    // unimplemented instruction vector 
    endcase

wire dbze0 = alu0_op==`DIVI || alu0_op==`MODI || (alu0_op==`RR && (alu0_fn==`DIV || alu0_fn==`MOD));
wire dbze1 = alu1_op==`DIVI || alu1_op==`MODI || (alu1_op==`RR && (alu1_fn==`DIV || alu1_fn==`MOD));

assign  alu0_exc =  (fnIsKMOnly(alu0_op) && !km && alu0_cmt) ? `EX_PRIV :
                    (alu0_done && dbze0 && alu0_divByZero && alu0_cmt) ? `EX_DBZ :
                    ((alu0_op==`CHKXI||(alu0_op==`RR && alu0_fn==`CHKX)) && !alu0_out && alu0_cmt) ? `EX_CHK : 
                    (((alu0_op==`MTSPR && alu0_fn==0)|| alu0_op==`LDIS) && iqentry_tgt[alu0_id[2:0]][7:3]==5'h6) ? 
                      {6'h20,iqentry_tgt[alu0_id[2:0]][2:0]} :
                      `EX_NONE;

assign  alu1_exc =  (fnIsKMOnly(alu1_op) && !km && alu1_cmt) ? `EX_PRIV :
                    (alu1_done && dbze1 && alu1_divByZero && alu1_cmt) ? `EX_DBZ :
                    ((alu1_op==`CHKXI ||(alu1_op==`RR && alu1_fn==`CHKX)) && !alu1_out && alu1_cmt) ? `EX_CHK : 
                    (((alu1_op==`MTSPR && alu1_fn==0)|| alu1_op==`LDIS) && iqentry_tgt[alu1_id[2:0]][7:3]==5'h6) ?
                      {6'h20,iqentry_tgt[alu1_id[2:0]][2:0]} :
                      `EX_NONE;

assign alu0_branchmiss = alu0_dataready && 
		   ((fnIsBranch(alu0_op))  ? ((alu0_cmt && !alu0_bt) || (!alu0_cmt && alu0_bt))
		  : !alu0_cmt ? (alu0_op==`LOOP)
		  : (alu0_cmt && (alu0_op==`SYNC || alu0_op == `JSR || alu0_op == `JSRS || alu0_op == `JSRZ ||
		     alu0_op==`SYS || alu0_op==`INT || alu0_op==`RTF || alu0_op==`JSF ||
		  alu0_op==`RTS || alu0_op==`RTS2 || alu0_op==`RTD || alu0_op == `RTE || alu0_op==`RTI || ((alu0_op==`LOOP) && (alu0_argA == 64'd0)))));

assign alu1_branchmiss = alu1_dataready && 
		   ((fnIsBranch(alu1_op))  ? ((alu1_cmt && !alu1_bt) || (!alu1_cmt && alu1_bt))
		  : !alu1_cmt ? (alu1_op==`LOOP)
		  : (alu1_cmt && (alu1_op==`SYNC || alu1_op == `JSR || alu1_op == `JSRS || alu1_op == `JSRZ ||
		     alu1_op==`SYS || alu1_op==`INT || alu1_op==`RTF || alu1_op==`JSF ||
		  alu1_op==`RTS || alu1_op==`RTS2 || alu1_op==`RTD || alu1_op == `RTE || alu1_op==`RTI || ((alu1_op==`LOOP) && (alu1_argA == 64'd0)))));

// Note this only applies when there are multiple flow control instructions
// being processed at the same time. An earlier instruction will take effect
// even though a later one might have branched already because it'll stomp on
// following instructions. The original RISC-001.v code worked because a
// branch in ALU#0 and ALU#1 was always guarenteed to be in that order everything
// being single cycle.
// How do you know that alu0 should take priority over alu #1 on a branch miss ?
// A couple of cases. Suppose branch instructions are issued to both alu#0 and 
// alu#1 in the same cycle -> then alu#0 should win because it's earlier in the
// instruction stream. Now suppose a branch instruction was issued to ALU#1 the cycle
// before issuing an instruction to ALU#0. ALU#1 will win automatically because
// branches are single cycle and it'll be finished before the branch in ALU#0
// (there's no conflict for the miss pc). but now suppose there's a multi-cycle
// jump instruction (jmpi) in the dram queue. It could be delayed until the same
// time as a branch in the ALU so means is required to determine which flow control
// wins.
// So let it be possible that the branch instruction in ALU#1 came before the one in
// ALU#0.
// - it should be whichever one has the earlier instruction. This can be told by an
// instruction sequence number.
// Examine the sequence number of the instruction to detemine which one is the earliest.
// You can't just look at the queue id because the queue is a circular buffer.
`define DRAM  0
`define ALU0  1
`define ALU1  2

reg [1:0] sn_winner;
always @*
  if ((jmpi_miss | mem_stringmiss) && (iqentry_sn[dram0_id] < iqentry_sn[alu0_id] || !alu0_branchmiss)
      && (iqentry_sn[dram0_id] < iqentry_sn[alu1_id] || !alu1_branchmiss))
    sn_winner = `DRAM;
  else if (alu0_branchmiss && (iqentry_sn[alu0_id] < iqentry_sn[dram0_id] || !(jmpi_miss|mem_stringmiss))
    && (iqentry_sn[alu0_id] < iqentry_sn[alu1_id] || !alu1_branchmiss))
    sn_winner = `ALU0;
  else
    sn_winner = `ALU1;

assign  branchmiss = (alu0_branchmiss | alu1_branchmiss | mem_stringmiss | jmpi_miss);
always @*
case(sn_winner)
`DRAM:
  begin
    misspc = jmpi_miss ? jmpi_misspc : dram0_misspc;
    missid = dram0_id;
    intmiss = 1'b0;
    rtimiss = 1'b0;
  end
`ALU0:
  begin
    misspc = alu0_misspc;
    missid = alu0_sourceid;
    intmiss = alu0_op==`INT;
    rtimiss = alu0_op==`RTI;
  end
default:  // or ALU1
  begin
    misspc = alu1_misspc;
    missid = alu1_sourceid;
    intmiss = alu1_op==`INT;
    rtimiss = alu1_op==`RTI;
  end
endcase

`ifdef FLOATING_POINT
 wire fp0_exception;
 
fpUnit ufp0
(
	.rst(rst_i),
	.clk(clk),
	.ce(1'b1),
	.op(fp0_op),
	.fn(fp0_fn),
	.ld(fp0_ld),
	.a(fp0_argA),
	.b(fp0_argB),
	.o(fp0_bus),
	.exception(fp0_exception)
);

reg [7:0] cnt;
always @(posedge clk)
if (rst_i)
    cnt <= 8'h00;
else begin
    if (fp0_ld)
	   cnt <= 8'h00;
    else begin
	   if (cnt < 8'hff)
		  cnt <= cnt + 8'd1;
    end
end

always @*
begin
	case(fp0_op)
	`FLOAT:
        case(fp0_fn)
        `FCMP,`FCMPS:    fp0_done = 1'b1;        // These ops are done right away
        `FADD,`FSUB,`FMUL,`FADDS,`FSUBS,`FMULS:
                               fp0_done = cnt > 8'd4;
        `FDIV:                fp0_done = cnt > 8'h70;
        `FDIVS:                fp0_done = cnt > 8'h37;
        default:       fp0_done = 1'b1;
        endcase
	`SINGLE_R:
        case(fp0_fn)
        `FNEGS,`FABSS,`FSIGNS,`FMOVS,
        `FNABSS,`FMANS:
                                    fp0_done = 1'b1;        // These ops are done right away
        `FTOIS,`ITOFS:    fp0_done = cnt > 8'd1;
        default:       fp0_done = 1'b1;
        endcase
	`DOUBLE_R:
        case(fp0_fn)
        `FMOV,`FNEG,`FABS,`FNABS,`FSIGN,`FMAN:
                                    fp0_done = 1'b1;        // These ops are done right away
        `FTOI,`ITOF:    fp0_done = cnt > 8'd1;
        default:       fp0_done = 1'b1;
        endcase
	default:       fp0_done = 1'b1;
	endcase
end

assign fp0_cmt = fnPredicate(fp0_pred, fp0_cond);
assign fp0_exc = fp0_exception ? `EX_FP : 9'd0;

assign  fp0_v = fp0_dataready;
assign  fp0_id = fp0_sourceid;
`endif

