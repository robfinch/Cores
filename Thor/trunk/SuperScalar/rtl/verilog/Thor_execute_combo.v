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
// Execute combinational logic
//
// ============================================================================
//
    //
    // EXECUTE
    //
wire [127:0] shlo0 = {64'd0,alu0_argA} << alu0_argB[5:0];
wire [127:0] shruo0 = {alu0_argA,64'd0} >> alu0_argB[5:0];
wire signed [63:0] shro0 = signed(alu0_argA) >> alu0_argB[5:0];

function [63:0] fnAluCalc;
input [7:0] alu_op;
input [63:0] alu_argA;
input [63:0] alu_argB;
input [63:0] alu_argI;
input [63:0] alu_pc;
begin
case(alu_op)
`_ADD2U:		fnAluCalc = {alu_argA,1'b0} + alu_argB;
`_ADD4U:		fnAluCalc = {alu_argA,2'b0} + alu_argB;
`_ADD8U:		fnAluCalc = {alu_argA,3'b0} + alu_argB;
`_ADD16U:		fnAluCalc = {alu_argA,4'b0} + alu_argB;
`_ADD2UI:		fnAluCalc = {alu_argA,1'b0} + alu_argI;
`_ADD4UI:		fnAluCalc = {alu_argA,2'b0} + alu_argI;
`_ADD8UI:		fnAluCalc = {alu_argA,3'b0} + alu_argI;
`_ADD16UI:		fnAluCalc = {alu_argA,4'b0} + alu_argI;
`ADD,`ADDU:		fnAluCalc = alu_argA + alu_argB;
`SUB,`SUBU:		fnAluCalc = alu_argA - alu_argB;
`ADDI,`ADDUI:	fnAluCalc = alu_argA + alu_argI;
`SUBI,`SUBUI:	fnAluCalc = alu_argA - alu_argI;
`ANDI:			fnAluCalc = alu_argA & alu_argI;
`ORI:			fnAluCalc = alu_argA | alu_argI;
`EORI:			fnAluCalc = alu_argA ^ alu_argI;
`AND:			fnAluCalc = alu_argA & alu_argB;
`OR:			fnAluCalc = alu_argA | alu_argB;
`EOR:			fnAluCalc = alu_argA ^ alu_argB;
`NAND:			fnAluCalc = ~(alu_argA & alu_argB);
`NOR:			fnAluCalc = ~(alu_argA | alu_argB);
`ENOR:			fnAluCalc = !(alu_argA ^ alu_argB);
`TST:	begin
			fnAluCalc[0] = alu_argA == 64'd0;
			fnAluCalc[1] = alu_argA[63];
			fnAluCalc[2] = 1'b0;
			fnAluCalc[63:3] <= 61'd0;
		end
`CMP:	begin
			fnAluCalc[0] = alu_argA == alu_argB;
			fnAluCalc[1] = signed(alu_argA) < signed(alu_argB);
			fnAluCalc[2] = alu_argA < alu_argB;
			fnAluCalc[63:3] <= 61'd0;
		end
`CMPI:	begin
			fnAluCalc[0] = alu_argA == alu_argI;
			fnAluCalc[1] = signed(alu_argA) < signed(alu_argI);
			fnAluCalc[2] = alu_argA < alu_argI;
			fnAluCalc[63:3] <= 61'd0;
		end
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`SB,`SC,`SH,`SW:
				fnAluCalc = alu_argA + alu_argI;
`JSR:	fnAluCalc = alu_pc;
default:	fnAluCalc = 64'hDEADDEADDEADDEAD;
endcase
end
endfunction

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

	assign alu0_cmt = fnPredicate(alu0_pred, alu0_cond);
	assign alu1_cmt = fnPredicate(alu1_pred, alu1_cond);

    assign alu0_bus = fnAluCalc(alu0_op, alu0_argA, alu0_argB, alu0_argI, alu0_pc);
    assign alu1_bus = fnAluCalc(alu1_op, alu1_argA, alu1_argB, alu1_argI, alu1_pc);

    assign  alu0_v = alu0_dataready,
			alu1_v = alu1_dataready;

    assign  alu0_id = alu0_sourceid,
			alu1_id = alu1_sourceid;

    assign  alu0_misspc = (alu0_op == `JSR || alu0_op==`SYS || alu0_op==`INT) ? alu0_argA : (alu0_bt ? alu0_pc + alu0_insnsz : alu0_pc +  alu0_insnsz + alu0_argI),
			alu1_misspc = (alu1_op == `JSR || alu0_op==`SYS || alu0_op==`INT) ? alu1_argA : (alu1_bt ? alu1_pc + alu1_insnsz : alu1_pc +  alu1_insnsz + alu1_argI);

    assign  alu0_exc = (alu0_op != `EXTEND)
			? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu0_argB[`INSTRUCTION_S2]
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
			: (alu0_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu0_argB[`INSTRUCTION_S2]
			: `EXC_INVALID;

    assign  alu1_exc = (alu1_op != `EXTEND)
			? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_NONE)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_CALL)	? alu1_argB[`INSTRUCTION_S2]
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MFSR)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_MTSR)	? `EXC_NONE
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU1)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU2)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_RFU3)	? `EXC_INVALID
			: (alu1_argB[`INSTRUCTION_S1] == `SYS_EXC)	? alu1_argB[`INSTRUCTION_S2]
			: `EXC_INVALID;

    assign alu0_branchmiss = alu0_dataready && 
			   ((alu0_op == `BR)  ? ((alu0_pred && ~alu0_bt) || (!alu0_pred && alu0_bt))
			  : alu0_pred && (alu0_op == `JSR || alu0_op==`SYS || alu0_op==`INT || alu0_op==`RTS);

    assign alu1_branchmiss = alu1_dataready && 
			   ((alu1_op == `BR)  ? ((alu1_pred && ~alu1_bt) || (!alu1_pred && alu1_bt))
			  : alu1_pred && (alu1_op == `JSR || alu1_op==`SYS || alu1_op==`INT || alu1_op==`RTS);

    assign  branchmiss = (alu0_branchmiss | alu1_branchmiss),
	    misspc = (alu0_branchmiss ? alu0_misspc : alu1_misspc),
	    missid = (alu0_branchmiss ? alu0_sourceid : alu1_sourceid);

