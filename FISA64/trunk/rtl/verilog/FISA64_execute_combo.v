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
// Execute combinational logic
//
// ============================================================================
//
wire [DBW-1:0] alu0_out, alu1_out;

FISA64_multiplier #(DBW) umult0
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

FISA64_multiplier #(DBW) umult1
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

FISA64_divider #(DBW) udiv0
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

FISA64_divider #(DBW) udiv1
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

FISA64_alu #(DBW) ualu0 
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

FISA64_alu #(DBW) ualu1 
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

assign alu0_bus = 	alu0_out;
assign alu1_bus = 	alu1_out;

assign  alu0_v = alu0_dataready,
		alu1_v = alu1_dataready;

assign  alu0_id = alu0_sourceid,
		alu1_id = alu1_sourceid;

assign  alu0_misspc = (alu0_op == `JSR || alu0_op==`RTS || alu0_op == `RTE || alu0_op==`RTI || alu0_op==`LOOP) ? alu0_argA + alu0_argI :
					  (alu0_op == `SYS || alu0_op==`INT) ? alu0_argA + {alu0_argI[DBW-5:0],4'b0} :
					  (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc + alu0_argI),
		alu1_misspc = (alu1_op == `JSR || alu1_op==`RTS || alu1_op == `RTE || alu1_op==`RTI || alu1_op==`LOOP) ? alu1_argA + alu1_argI :
					  (alu1_op == `SYS || alu1_op==`INT) ? alu1_argA + {alu1_argI[DBW-5:0],4'b0} :
					  (alu1_bt ? alu1_pc + alu0_insnsz : alu1_pc + alu1_argI);

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
		  : (alu0_cmt && (alu0_op == `JSR || alu0_op==`SYS || alu0_op==`INT || alu0_op==`RTS || alu0_op == `RTE || alu0_op==`RTI || (alu0_op==`LOOP && lc != 64'd0))));

assign alu1_branchmiss = alu1_dataready && 
		   ((fnIsBranch(alu1_op))  ? ((alu1_cmt && !alu1_bt) || (!alu1_cmt && alu1_bt))
		  : (alu1_cmt && (alu1_op == `JSR || alu1_op==`SYS || alu1_op==`INT || alu1_op==`RTS || alu1_op == `RTE || alu1_op==`RTI || (alu1_op==`LOOP && lc != 64'd0))));

assign  branchmiss = (alu0_branchmiss | alu1_branchmiss),
	misspc = (alu0_branchmiss ? alu0_misspc : alu1_misspc),
	missid = (alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

`ifdef FLOATING_POINT
wire [DBW-1:0] fp0_zlout,fp0_loout,fp0_out;

fpUnit ufp0
(
	.rst(rst_i),
	.clk(clk),
	.ce(1'b1),
	.op(fp0_op),
	.ld(fp0_ld),
	.a(fp0_argA),
	.b(fp0_argB),
	.o(fp0_out),
	.zl_o(fp0_zlout),
	.loo_o(fp0_loout),
	.loo_done(),
	.exception()
);

reg [7:0] cnt;
always @(posedge clk)
if (fp0_ld)
	cnt <= 8'h00;
else begin
	if (cnt < 8'hff)
		cnt <= cnt + 8'd1;
end

always @*
begin
	case(fp0_op)
	`FNEG,`FABS,`FSIGN:	fp0_done = 1'b1;		// These ops are done right away
	`FTOI,`ITOF:		fp0_done = cnt > 8'd2;
	`FADD,`FSUB,`FMUL:	fp0_done = cnt > 8'd4;
	`FDIV:				fp0_done = cnt > 8'h70;
	endcase
end
always @*
begin
	case(fp0_op)
	`FNEG,`FABS,`FSIGN:	fp0_bus = fp0_zlout;
	`FTOI,`ITOF:		fp0_bus = fp0_loout;
	default:			fp0_bus = fp0_out;
	endcase
end

assign fp0_cmt = fnPredicate(fp0_pred, fp0_cond);
assign fp0_exc = `EXC_NONE;

assign  fp0_v = fp0_dataready;
assign  fp0_id = fp0_sourceid;
`endif
