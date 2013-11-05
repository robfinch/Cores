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
// Thor Scaler
//
// ============================================================================
//
`include "Thor_defines.v"

module Thor_Scalar(rst_i, clk_i, nmi_i, irq_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter RESET = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd2;
parameter EXECUTE = 6'd3;
parameter WAIT_ACK = 6'd4;
parameter DAT_EXT = 6'd5;
parameter INT = 6'd6;
parameter IBUF1 = 6'd32;
parameter IBUF2 = 6'd33;
parameter IBUF3 = 6'd34;
parameter ICACHE1 = 6'd35;
parameter PF = 4'd0;
parameter PT = 4'd1;
parameter PEQ = 4'd2;
parameter PNE = 4'd3;
parameter PLE = 4'd4;
parameter PGT = 4'd5;
parameter PGE = 4'd6;
parameter PLT = 4'd7;
parameter PLEU = 4'd8;
parameter PGTU = 4'd9;
parameter PGEU = 4'd10;
parameter PLTU = 4'd11;
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [4:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [63:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;

reg [5:0] state;
reg first_ifetch;
reg [63:0] pc,ipc,epc,tpc;
reg [63:0] ir;
wire [63:0] insn;
reg im;
reg nmi1;
reg nmi_edge;
reg nmi_armed;
wire [7:0] opcode = ir[`OPCODE];
wire [7:0] Ra = ir[`RA];
wire [7:0] Rb = ir[`RB];
wire [3:0] Bra = ir[23:20];
reg [7:0] Rt;
reg [3:0] Pt;
reg [63:0] regfile [0:255];
reg [3:0] pregs [0:15];
reg [63:0] brregs [0:15];
wire [63:0] rfoa = Ra==8'h00 ? 64'd0 : regfile[Ra];
wire [63:0] rfob = Rb==8'h00 ? 64'd0 : regfile[Rb];
reg [63:0] brregso;
reg [63:0] a,b,imm;
wire signed [63:0] as = a;
wire signed [63:0] bs = b;
wire signed [63:0] imms = imm;
wire [127:0] shlo = {64'd0,a} << b[5:0];
wire [127:0] shro = {a,64'd0} >> b[5:0];
wire signed [63:0] shruo = as >> b[5:0];
reg [63:0] dati;
reg [64:0] res;
reg lt,ltu,eq;
wire resn = res[63];
wire resc = res[64];
wire resz = res[63:0]==64'd0;
reg extImm;

wire uncachedInsn = 1'b1;
reg [63:0] ibufadr;
reg [127:0] insnbuf;
wire ibufhit = ibufadr[63:4]==pc[63:4];
wire [7:0] ipred = insnbuf[7:0];
wire ihit = 1'b0;
wire clk = clk_i;

always @(Bra)
case(Bra)
4'd0:	brregso <= 64'd0;
4'd13:	brregso <= epc;
4'd14:	brregso <= ipc;
4'd15:	brregso <= pc;
default:	brregso <= brregs[Bra];
endcase

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

// Determine how much to increment the PC by given an opcode.
function [3:0] fnIncPc;
input [7:0] opcode;

casex(opcode)
`NOP,`SEI,`CLI:	
	fnIncPc = 4'd2;
`BR,`TST,`RTS:
	fnIncPc = 4'd3;
`JSR,`SYS,`CMP,`CMPI:
	fnIncPc = 4'd4;
`ADD,`SUB,`ADDU,`SUBU,
`_2ADDU,`_4ADDU,`_8ADDU,`_16ADDU,
`AND,`OR,`EOR,`NAND,`NOR,`ENOR,`ANDC,`ORC,
`SHL,`SHLU,`SHR,`SHRU,`ROL,`ROR:
	fnIncPc = 4'd5;
`ADDI,`ADDUI,`SUBI,`SUBUI,
`_2ADDUI,`_4ADDUI,`_8ADDUI,`_16ADDUI,
`ANDI,`ORI,`EORI,
`SHLI,`SHLUI,`SHRI,`SHRUI,`ROLI,`RORI,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
`SB,`SC,`SH,`SW:
	fnIncPc = 4'd5;
default:	fnIncPc = 4'd5;
endcase
endfunction

always @(posedge clk)
	nmi1 <= nmi_i;
always @(posedge clk)
	if (nmi_i & ~nmi1)
		nmi_edge <= 1'b1;
	else if (state==INT)
		nmi_edge <= 1'b0;

always @(posedge clk)
if (rst_i) begin
	nmi_armed <= `FALSE;
	first_ifetch <= `TRUE;
	next_state(RESET);
end
else begin
case(state)

RESET:
	begin
		next_state(IFETCH);
	end

IFETCH:
	begin
		next_state(DECODE);
		if (nmi_edge & nmi_armed & ~extImm) begin
			ipc <= pc;
		end
		else if (irq_i & !im & ~extImm) begin
			ipc <= pc;
		end
		else begin
			if (uncachedInsn) begin
				if (ibufhit)
					ir <= insnbuf;
				else
					next_state(IBUF1);
			end
			else begin
				if (ihit)
					ir <= insn;
				else
					next_state(ICACHE1);
			end
		end
		if (first_ifetch) begin
			first_ifetch <= `FALSE;
			if (fnPredicate(pregs[ir[`PREDR]],ir[`PREDC])==`TRUE) begin
				if (Rt==8'hFF)
					nmi_armed <= `TRUE;
				regfile[Rt] <= res[63:0];
				case(opcode)
				`JSR,`SYS:
					if (ir[19:16]==4'h0)
						brregs[ir[19:16]] <= 64'd0;
					else
						brregs[ir[19:16]] <= tpc;
				`CMP,`CMPI,`TST:
					pregs[Pt] <= {1'b0,ltu,lt,eq};
				endcase
			end
		end
	end

DECODE:
	begin
		next_state(IFETCH);
		first_ifetch <= `TRUE;
		pc <= pc +  fnIncPc(opcode);
		a <= rfoa;
		if (opcode==`SHLI || opcode==`SHRI || opcode==`SHLUI || opcode==`SHRUI || opcode==`ROLI || opcode==`RORI)
			b <= Rb[5:0];
		else
			b <= rfob;
		if (fnPredicate(pregs[ir[`PREDR]],ir[`PREDC])==`TRUE)
			case(opcode)
			`NOP:	;
			`SEI:	im <= 1'b1;
			`CLI:	im <= 1'b0;
			default:	next_state(EXECUTE);
			endcase
		if (ir[`PREDC]==4'h0) begin	// special predicate
			pc <= pc + ir[`PREDR];
			case(ir[`PREDR])
			4'd0:	begin ir[15:8] <= 8'h00; pc <= pc + 64'd1; next_state(EXECUTE); end
			4'd1:	;	// NOP
			4'd2:	begin imm[63:8] <= {{48{ir[15]}},ir[15:8]}; extImm <= `TRUE; end
			4'd3:	begin imm[63:8] <= {{40{ir[23]}},ir[23:8]}; extImm <= `TRUE; end
			4'd4:	begin imm[63:8] <= {{32{ir[31]}},ir[31:8]}; extImm <= `TRUE; end
			4'd5:	begin imm[63:8] <= {{24{ir[39]}},ir[39:8]}; extImm <= `TRUE; end
			4'd6:	begin imm[63:8] <= {{16{ir[47]}},ir[47:8]}; extImm <= `TRUE; end
			4'd7:	begin imm[63:8] <= {{8{ir[55]}},ir[55:8]}; extImm <= `TRUE; end
			4'd8:	begin imm[63:8] <= ir[63:8]; extImm <= `TRUE; end
			default:	pc <= pc + fnIncPc(opcode);
			endcase
		end
		Pt <= ir[11:8];		// Target predicate
		// Setup immediate value
		case(opcode)
		`JSR,`SYS,`RTS,`CMPI:
			begin
				imm[7:0] <= ir[31:24];
				if (!extImm)
					imm[63:8] <= {56{ir[31]}};
			end
		`BR:
			begin
				imm[7:0] <= ir[23:16];
				if (!extImm)
					imm[63:8] <= {56{ir[23]}};
			end
		default:
			begin
				imm[7:0] <= ir[39:32];
				if (!extImm)
					imm[63:8] <= {56{ir[7]}};
			end
		endcase
		if (fnPredicate(pregs[ir[`PREDR]],ir[`PREDC])==`TRUE)
			// Set target register
			case(opcode)
			`ADD,`ADDU,`SUB,`SUBU,
			`AND,`OR,`EOR,`NAND,`NOR,`ENOR,`ANDC,`ORC,
			`_2ADDU,`_4ADDU,`_8ADDU,`_16ADDU,
			`SHL,`SHR,`SHLU,`SHRU,`ROL,`ROR:
				Rt <= ir[39:32];
			`ADDI,`ADDUI,`SUBI,`SUBUI,`ANDI,`ORI,`EORI,
			`SHLI,`SHRI,`SHLUI,`SHRUI,`ROLI,`RORI,
			`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW:
				Rt <= ir[39:32];
			default:	Rt <= 8'h00;
			endcase
		else
			Rt <= 8'h00;
	end

EXECUTE:
	begin
		next_state(IFETCH);
		casex(opcode)
		`TST:			begin
							lt <= a[63];
							ltu <= 1'b0;
							eq <= a==64'd0;
						end
		`ADDI,`ADDUI:	res <= a + imm;
		`ADD,`ADDU:		res <= a + b;
		`_2ADDU:		res <= {a[62:0],1'b0} + b;
		`_4ADDU:		res <= {a[61:0],2'b0} + b;
		`_8ADDU:		res <= {a[60:0],3'b0} + b;
		`_16ADDU:		res <= {a[59:0],4'b0} + b;
		`_2ADDUI:		res <= {a[62:0],1'b0} + imm;
		`_4ADDUI:		res <= {a[61:0],2'b0} + imm;
		`_8ADDUI:		res <= {a[60:0],3'b0} + imm;
		`_16ADDUI:		res <= {a[59:0],4'b0} + imm;
		`SUBI,`SUBUI:	res <= a - imm;
		`SUB,`SUBU:		res <= a - b;
		`CMPI:			begin
							lt <= as < imms;
							ltu <= a < imm;
							eq <= a == imm;
						end
		`CMP:			begin
							lt <= as < bs;
							ltu <= a < b;
							eq <= a == b;
						end
		`ANDI:			res <= a & imm;
		`AND:			res <= a & b;
		`ORI:			res <= a | imm;
		`OR:			res <= a | b;
		`EORI:			res <= a ^ imm;
		`EOR:			res <= a ^ b;
		`NAND:			res <= ~(a & b);
		`NOR:			res <= ~(a | b);
		`ENOR:			res <= ~(a ^ b);
		`ANDC:			res <= a & ~b;
		`ORC:			res <= a | ~b;
		`SHL,`SHLI:		res <= shlo[63:0];
		`SHLU,`SHLUI:	res <= shlo[63:0];
		`SHRU,`SHRUI:	res <= shro[127:64];
		`SHR,`SHRI:		res <= shruo;
		`ROL,`ROLI:		res <= shlo[127:64]|shlo[63:0];
		`ROR,`RORI:		res <= shro[127:64]|shro[63:0];
		// Flow Control
		`BR:			begin tpc <= pc; pc <= pc + imm; end
		`RTS:			begin tpc <= pc; pc <= brregs[ir[23:20]]; end
		`JSR:			begin tpc <= pc; pc <= brregs[ir[23:20]] + imm; end
		`SYS:			begin tpc <= pc; pc <= brregs[ir[23:20]] + {imm[59:0],4'b0000}; end
		// Memory
		`LB,`LBU:		wb_read_byte(a+imm);
		`LC,`LCU:		wb_read_char(a+imm);
		`LH,`LHU:		wb_read_half(a+imm);
		`LW:			wb_read_word(a+imm);
		`SB:			wb_write_byte(a+imm,{8{b[7:0]}});
		`SC:			wb_write_char(a+imm,{4{b[15:0]}});
		`SH:			wb_write_half(a+imm,{2{b[31:0]}});
		`SW:			wb_write_word(a+imm,b);
		endcase
	end

WAIT_ACK:
	if (ack_i) begin
		wb_nack();
		case(sel_o)
		8'h01:	dati <= dat_i[7:0];
		8'h02:	dati <= dat_i[15:8];
		8'h04:	dati <= dat_i[23:16];
		8'h08:	dati <= dat_i[31:24];
		8'h10:	dati <= dat_i[39:32];
		8'h20:	dati <= dat_i[47:40];
		8'h40:	dati <= dat_i[55:48];
		8'h80:	dati <= dat_i[63:56];
		8'h03:	dati <= dat_i[15:0];
		8'h0C:	dati <= dat_i[31:16];
		8'h30:	dati <= dat_i[47:32];
		8'hC0:	dati <= dat_i[63:48];
		8'h0F:	dati <= dat_i[31:0];
		8'hF0:	dati <= dat_i[63:32];
		8'hFF:	dati <= dat_i;
		default:	dati <= 64'hDEADDEADDEADDEAD;
		endcase
		next_state(DAT_EXT);
	end
// Sign extend or zero extend data for a load.
DAT_EXT:
	begin
		case(opcode)
		`LB:	res <= {{56{dati[7]}},dati[7:0]};
		`LBU:	res <= dati;
		`LC:	res <= {{48{dati[15]}},dati[15:0]};
		`LCU:	res <= dati;
		`LH:	res <= {{32{dati[31]}},dati[31:0]};
		`LHU:	res <= dati;
		`LW:	res <= dati;
		default:	res <= dati;
		endcase
		next_state(IFETCH);
	end

IBUF1:
	begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		bl_o <= 5'd1;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		sel_o <= 8'hFF;
		adr_o <= {pc[63:3],3'b000};
		next_state(IBUF2);
	end
IBUF2:
	if (ack_i) begin
		insnbuf <= dat_i >> {pc[2:0],3'b000};
		next_state(IBUF3);
	end
IBUF3:
	if (ack_i) begin
		wb_nack();
		case(pc[2:0])
		3'd0:	insnbuf[127:64] <= dat_i;
		3'd1:	insnbuf[119:56] <= dat_i;
		3'd2:	insnbuf[111:48] <= dat_i;
		3'd3:	insnbuf[103:40] <= dat_i;
		3'd4:	insnbuf[95:32] <= dat_i;
		3'd5:	insnbuf[87:24] <= dat_i;
		3'd6:	insnbuf[79:16] <= dat_i;
		3'd7:	insnbuf[71:8] <= dat_i;
		endcase
		ibufadr <= {pc[63:2],2'h0};
		next_state(IFETCH);
	end
endcase
end

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task wb_read_byte;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	sel_o <= 8'd1 << adr[2:0];
	adr_o <= adr;
	dat_o <= 64'd0;
	next_state(WAIT_ACK);
end
endtask
	
task wb_read_char;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	sel_o <= 8'd3 << {adr[2:1],1'b0};
	adr_o <= adr;
	dat_o <= 64'd0;
	next_state(WAIT_ACK);
end
endtask
	
task wb_read_half;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	sel_o <= 8'hF << {adr[2],2'b0};
	adr_o <= adr;
	dat_o <= 64'd0;
	next_state(WAIT_ACK);
end
endtask
	
task wb_read_word;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b0;
	sel_o <= 8'hFF;
	adr_o <= adr;
	dat_o <= 64'd0;
	next_state(WAIT_ACK);
end
endtask
	
task wb_write_byte;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	sel_o <= 8'd1 << adr[2:0];
	adr_o <= adr;
	dat_o <= dat;
	next_state(WAIT_ACK);
end
endtask
	
task wb_write_char;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	sel_o <= 8'd3 << {adr[2:1],1'b0};
	adr_o <= adr;
	dat_o <= dat;
	next_state(WAIT_ACK);
end
endtask
	
task wb_write_half;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	sel_o <= 8'hF << {adr[2],2'b0};
	adr_o <= adr;
	dat_o <= dat;
	next_state(WAIT_ACK);
end
endtask
	
task wb_write_word;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	sel_o <= 8'hFF;
	adr_o <= adr;
	dat_o <= dat;
	next_state(WAIT_ACK);
end
endtask
	
task wb_nack;
begin
	cti_o <= 3'b000;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= 64'h0;
	dat_o <= 64'h0;
end
endtask

endmodule
