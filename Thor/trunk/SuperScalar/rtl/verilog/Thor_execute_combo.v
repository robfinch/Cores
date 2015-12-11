// ============================================================================
//        __
//   \\__/ o\    (C) 2013,2015  Robert Finch, Stratford
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

Thor_multiplier #(DBW) umult0
(
	.rst(rst_i),
	.clk(clk),
	.ld(alu0_ld && ((alu0_op==`RR && (alu0_fn==`MUL || alu0_fn==`MULU)) || alu0_op==`MULI || alu0_op==`MULUI)),
	.sgn((alu0_op==`RR && alu0_op==`MUL) || alu0_op==`MULI),
	.isMuli(alu0_op==`MULI || alu0_op==`MULUI),
	.a(alu0_argA),
	.b(alu0_argB),
	.imm(alu0_argI),
	.o(alu0_prod),
	.done(alu0_mult_done)
);

Thor_multiplier #(DBW) umult1
(
	.rst(rst_i),
	.clk(clk),
	.ld(alu1_ld && ((alu1_op==`RR && (alu1_fn==`MUL || alu1_fn==`MULU)) || alu1_op==`MULI || alu1_op==`MULUI)),
	.sgn((alu1_op==`RR && alu1_op==`MUL) || alu1_op==`MULI),
	.isMuli(alu1_op==`MULI || alu1_op==`MULUI),
	.a(alu1_argA),
	.b(alu1_argB),
	.imm(alu1_argI),
	.o(alu1_prod),
	.done(alu1_mult_done)
);

Thor_divider #(DBW) udiv0
(
	.rst(rst_i),
	.clk(clk),
	.ld(alu0_ld && (alu0_op==`DIV || alu0_op==`DIVI || alu0_op==`DIVU || alu0_op==`DIVUI)),
	.sgn(alu0_op==`DIV || alu0_op==`DIVI),
	.isDivi(alu0_op==`DIVI || alu0_op==`DIVUI),
	.a(alu0_argA),
	.b(alu0_argB),
	.imm(alu0_argI),
	.qo(alu0_divq),
	.ro(alu0_rem),
	.dvByZr(),
	.done(alu0_div_done)
);

Thor_divider #(DBW) udiv1
(
	.rst(rst_i),
	.clk(clk),
	.ld(alu1_ld && (alu1_op==`DIV || alu1_op==`DIVI || alu1_op==`DIVU || alu1_op==`DIVUI)),
	.sgn(alu1_op==`DIV || alu1_op==`DIVI),
	.isDivi(alu1_op==`DIVI || alu1_op==`DIVUI),
	.a(alu1_argA),
	.b(alu1_argB),
	.imm(alu1_argI),
	.qo(alu1_divq),
	.ro(alu1_rem),
	.dvByZr(),
	.done(alu1_div_done)
);

Thor_alu #(.DBW(DBW),.BIG(1)) ualu0 
(
	.alu_op(alu0_op),
	.alu_fn(alu0_fn),
	.alu_argA(alu0_argA),
	.alu_argB(alu0_argB),
	.alu_argC(alu0_argC),
	.alu_argI(alu0_argI),
	.alu_pc(alu0_pc),
	.insnsz(alu0_insnsz),
	.o(alu0_out)
);

Thor_alu #(.DBW(DBW),.BIG(ALU1BIG)) ualu1 
(
	.alu_op(alu1_op),
	.alu_fn(alu1_fn),
	.alu_argA(alu1_argA),
	.alu_argB(alu1_argB),
	.alu_argC(alu1_argC),
	.alu_argI(alu1_argI),
	.alu_pc(alu1_pc),
	.insnsz(alu1_insnsz),
	.o(alu1_out)
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

    alu0_bus <= alu0_out;
    alu1_bus <= alu1_out;

    alu0_v <= alu0_dataready;
	alu1_v <= alu1_dataready;

    alu0_id <= alu0_sourceid;
	alu1_id <= alu1_sourceid;
end

always @(alu0_op or alu0_fn or alu0_argA or alu0_argI or alu0_insnsz or alu0_pc or alu0_bt)
    case(alu0_op)
    `JSR,`JSRS,`JSRZ,`RTE,`RTI:
        alu0_misspc <= alu0_argA + alu0_argI;
    `LOOP,`SYNC:
        alu0_misspc <= alu0_pc + alu0_insnsz;
    `RTS,`RTS2:
        alu0_misspc <= alu0_argA + alu0_fn[3:0];
    `SYS,`INT:
        alu0_misspc <= alu0_argA + {alu0_argI[DBW-5:0],4'b0};
    default:
        alu0_misspc <= (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc + alu0_insnsz + alu0_argI);
    endcase

always @(alu1_op or alu1_fn or alu1_argA or alu1_argI or alu1_insnsz or alu1_pc or alu1_bt)
    case(alu1_op)
    `JSR,`JSRS,`JSRZ,`RTE,`RTI:
        alu1_misspc <= alu1_argA + alu1_argI;
    `LOOP,`SYNC:
        alu1_misspc <= alu1_pc + alu1_insnsz;
    `RTS,`RTS2:
        alu1_misspc <= alu1_argA + alu1_fn[3:0];
    `SYS,`INT:
        alu1_misspc <= alu1_argA + {alu1_argI[DBW-5:0],4'b0};
    default:
        alu1_misspc <= (alu1_bt ? alu1_pc + alu1_insnsz : alu1_pc + alu1_insnsz + alu1_argI);
    endcase
/*
assign  alu0_misspc = (alu0_op == `JSR || alu0_op==`JSRS || alu0_op==`JSRZ || 
                       alu0_op==`RTS || alu0_op==`RTS2 || alu0_op == `RTE || alu0_op==`RTI || alu0_op==`LOOP) ? alu0_argA + alu0_argI :
					  (alu0_op == `SYS || alu0_op==`INT) ? alu0_argA + {alu0_argI[DBW-5:0],4'b0} :
					  (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc + alu0_insnsz + alu0_argI),
		alu1_misspc = (alu1_op == `JSR || alu1_op==`JSRS || alu1_op==`JSRZ || 
		               alu1_op==`RTS || alu1_op == `RTE || alu1_op==`RTI || alu1_op==`LOOP) ? alu1_argA + alu1_argI :
					  (alu1_op == `SYS || alu1_op==`INT) ? alu1_argA + {alu1_argI[DBW-5:0],4'b0} :
					  (alu1_bt ? alu1_pc + alu1_insnsz : alu1_pc + alu1_insnsz + alu1_argI);
*/
assign  alu0_exc = `EXC_NONE;
//			? `EXC_NONE
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu0_argB[`INSTRUCTION_S2]
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
//			: (alu0_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu0_argB[`INSTRUCTION_S2]
//			: `EXC_INVALID;

assign  alu1_exc = `EXC_NONE;
//			? `EXC_NONE
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu1_argB[`INSTRUCTION_S2]
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
//			: (alu1_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu1_argB[`INSTRUCTION_S2]
//			: `EXC_INVALID;

assign alu0_branchmiss = alu0_dataready && 
		   ((fnIsBranch(alu0_op))  ? ((alu0_cmt && !alu0_bt) || (!alu0_cmt && alu0_bt))
		  : (alu0_cmtw && (alu0_op==`SYNC || alu0_op == `JSR || alu0_op == `JSRS || alu0_op == `JSRZ ||
		     alu0_op==`SYS || alu0_op==`INT ||
		  alu0_op==`RTS || alu0_op==`RTS2 || alu0_op == `RTE || alu0_op==`RTI || ((alu0_op==`LOOP) && (alu0_argB == 64'd0)))));

assign alu1_branchmiss = alu1_dataready && 
		   ((fnIsBranch(alu1_op))  ? ((alu1_cmt && !alu1_bt) || (!alu1_cmt && alu1_bt))
		  : (alu1_cmtw && (alu1_op==`SYNC || alu1_op == `JSR || alu1_op == `JSRS || alu1_op == `JSRZ ||
		     alu1_op==`SYS || alu1_op==`INT ||
		  alu1_op==`RTS || alu1_op==`RTS2 || alu1_op == `RTE || alu1_op==`RTI || ((alu1_op==`LOOP) && (alu1_argB == 64'd0)))));

assign  branchmiss = (alu0_branchmiss | alu1_branchmiss | mem_stringmiss),
	misspc = (mem_stringmiss ? string_pc : alu0_branchmiss ? alu0_misspc : alu1_misspc),
	missid = (mem_stringmiss ? dram0_id[2:0] : alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

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
assign fp0_exc = fp0_exception ? 8'd242 : 8'd0;

assign  fp0_v = fp0_dataready;
assign  fp0_id = fp0_sourceid;
`endif
