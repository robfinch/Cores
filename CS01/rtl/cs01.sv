// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	cs01.v
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
// ============================================================================

`define CTRL	6'h00
`define SYS			5'd0
`define SEI			5'd1
`define PFI			5'd2
`define RTI			5'd3
`define R2		6'd02
`define ADD		6'd04
`define ADDI	6'd04
`define SUB		6'd05
`define SUBI	6'd05
`define MUL		6'd11
`define MULI	6'd11
`define CMP		6'd06
`define CMPI	6'd06
`define CMPU	6'd07
`define CMPUI	6'd07
`define AND		6'd08
`define ANDI	6'd08
`define OR		6'd09
`define ORI		6'd09
`define EOR		6'd10
`define EORI	6'd10
`define SHIFT		6'd03
`define SHIFTI	6'd03
`define ASL			5'd0
`define ASR			5'd1
`define SHL			5'd2
`define SHR			5'd3
`define ROL			5'd4
`define ROR			5'd5
`define ASLI		5'd0
`define ASRI		5'd1
`define SHLI		5'd2
`define SHRI		5'd3
`define ROLI		5'd4
`define RORI		5'd5
`define MOV		6'd12
`define FMA		6'd14
`define FLOAT	6'd15
`define FTOI		6'd02
`define ITOF		6'd03
`define FADD		6'd04
`define FSUB		6'd05
`define FMUL		6'd11
`define FCMP		6'd06
`define FDIV		6'd12
`define FSQRT		6'd13
`define BEQZ	6'd24
`define BNEZ	6'd25
`define BLTZ	6'd26
`define BLEZ	6'd27
`define BGTZ	6'd28
`define BGEZ	6'd29
`define BRA		6'd30
`define JMP		6'd31
`define JSR		6'd32
`define JMPR	6'd33
`define JSRR	6'd34
`define RTS		6'd35
`define LDO		6'd48
`define LDF		6'd49
`define POP		6'd50
`define POPF	6'd51
`define STO		6'd56
`define STF		6'd57
`define PUSH	6'd58
`define PUSHF	6'd59

`include "fp/fpConfig.sv"

module cs01(rst_i, clk_i, irq_i, cyc_o, ack_i, we_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input [3:0] irq_i;
output reg cyc_o;
input ack_i;
output reg we_o;
output reg [15:0] adr_o;
input [79:0] dat_i;
output reg [79:0] dat_o;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
parameter WID = 80;
`include "fp/fpSize.sv"

// Nonm visible registers
reg SystemMode;
reg [31:0] ir;			// instruction register
reg [15:0] upc;			// user mode pc
reg [15:0] spc;			// system mode pc
reg [3:0] pim;			// previous interrupt mask
reg [4:0] Rd, Rs1, Rs2, Rs3;
reg [31:0] ia, ib, ic;
reg [31:0] uia, uib, uic;
reg [31:0] sia, sib, sic;
reg [79:0] fa, fb, fc;
reg [31:0] imm;
reg [31:0] displacement;				// branch displacement
wire [5:0] opcode = ir[31:26];
wire [5:0] funct = ir[5:0];
wire [4:0] shiftop = ir[10:6];
wire [4:0] ctrlop = ir[15:11];
wire [2:0] rm3 = ir[8:6];
wire [1:0] S2 = ir[7:6];
wire [1:0] T2 = ir[9:8];

reg [31:0] iregfile [0:31];		// integer / system register file
reg [31:0] sregfile [0:31];
reg [79:0] fregfile [0:31];		// floating-point register file
reg [63:0] usp, ssp, sp;			// user, system, generic stack pointer
reg [15:0] pc;			// generic program counter
reg [3:0] im;				// interrupt mask
reg [2:0] rm;
reg wrirf, wrsrf, wrfrf;
wire [31:0] irfoa = iregfile[Rs1];
wire [31:0] irfob = iregfile[Rs2];
wire [31:0] irfoc = iregfile[Rs3];
wire [31:0] srfoa = sregfile[Rs1];
wire [31:0] srfob = sregfile[Rs2];
wire [31:0] srfoc = sregfile[Rs3];
wire [79:0] frfoa = fregfile[Rs1];
wire [79:0] frfob = fregfile[Rs2];
wire [79:0] frfoc = fregfile[Rs3];
always @(posedge clk_i)
if (wrirf)
	iregfile[Rd] <= res[31:0];
always @(posedge clk_i)
if (wrsrf)
	sregfile[Rd] <= res[31:0];
always @(posedge clk_i)
if (wrfrf)
	fregfile[Rd] <= res;

reg [3:0] state;
parameter IFETCH = 4'd1;
parameter DECODE = 4'd2;
parameter RFETCH = 4'd3;
parameter EXECUTE = 4'd4;
parameter MEMORY = 4'd5;
parameter FLOAT = 4'd6;
parameter WRITEBACK = 4'd7;

reg [31:0] rommem [0:1023];
wire [32:0] romo;
initial begin
`include "cs01rom.sv"
end
assign romo = rommem[pc];

reg [79:0] res;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [7:0] fltCnt;
reg [79:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
fpCompare #(.WID(80)) u1 (.a(fa), .b(fb), .o(fcmp_o), .nanx());
assign fcmp_res = fcmp_o[1] ? -80'd1 : fcmp_o[0] ? 80'd0 : 80'd1;
i2f #(.WID(80)) u2 (.clk(clk_i), .ce(1'b1), .rm(3'b000), .i(fa), .o(itof_res));
f2i #(.WID(80)) u3 (.clk(clk_i), .ce(1'b1), .i(fa), .o(ftoi_res), .overflow());
fpAddsub #(.WID(80)) u4 (.clk(clk_i), .ce(1'b1), .rm(rmq), .op(opcode==`FSUB), .a(fa), .b(fb), .o(fas_o));
fpMul #(.WID(80)) u5 (.clk(clk_i), .ce(1'b1), .a(fa), .b(fb), .o(fmul_o), .sign_exe(), .inf(), .overflow(), .underflow());
fpDiv #(.WID(80)) u6 (.rst(rst_i), .clk(clk_i), .clk4x(1'b0), .ce(1'b1), .ld(state==EXECUTE), .op(1'b0),
	.a(fa), .b(fb), .o(fdiv_o), .done(), .sign_exe(), .overflow(), .underflow());
fpSqrt #(.WID(80)) u7 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .ld(state==EXECUTE),
	.a(fa), .o(fsqrt_o), .done(), .sqrinf(), .sqrneg());

always @(posedge clk_i)
case(opcode)
`FADD:	fnorm_i <= fas_o;
`FSUB:	fnorm_i <= fas_o;
`FMUL:	fnorm_i <= fmul_o;
`FDIV:	fnorm_i <= fdiv_o;
`FSQRT:	fnorm_i <= fsqrt_o;
default:	fnorm_i <= 1'd0;
endcase
fpNormalize #(.WID(80)) u8 (.clk(clk_i), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(1'b0), .under_o(), .inexact_o());
fpRound #(.WID(80)) u9 (.clk(clk_i), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));

always @(posedge clk_i)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset
// The program counters are set at their reset values.
// System mode is activated and interrupts are masked.
// All other state is undefined.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (rst_i) begin
	state <= IFETCH;
	spc <= 16'h0000;
	upc <= 16'h0040;
	pc <= 16'h0000;
	SystemMode <= 1'b1;
	im <= 4'd15;
	wrirf <= 1'b0;
	wrsrf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	cyc_o <= 1'b0;
	we_o <= 1'b0;
	adr_o <= 16'h0;
	dat_o <= 80'h0;
end
else
case (state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch
// Get the instruction from the rom.
// Increment the program counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
IFETCH:
	begin
		wrirf <= 1'b0;
		wrsrf <= 1'b0;
		wrfrf <= 1'b0;
		ir <= romo;
		state <= DECODE;
		if (irq_i > im) begin
			SystemMode <= 1'b1;
			pc <= spc;
			pim <= im;
			im <= 4'd15;
			state <= IFETCH;
		end
		else
			pc <= pc + 2'd1;
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// Decode the register fields, immediate values, and branch displacement
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DECODE:
	begin
		state <= RFETCH;
		case(opcode)
		`CTRL:
			case(ctrlop) 
			`SEI,`PFI:	Rd <= ir[25:21];
			default:	Rd <= 5'd0;
			endcase
		`ADDI,`SUBI,`MULI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI,`SHIFTI,`R2:
			Rd <= ir[25:21];
		default:	Rd <= 5'd0;
		endcase
		Rs1 <= ir[20:16];
		Rs2 <= ir[15:11];
		Rs3 <= ir[10:6];
		case(opcode)
		`CTRL:
			case(ctrlop)
			`SYS:				imm <= ir[7:0];
			`SEI,`PFI:	imm <= ir[3:0];
			default:		imm <= 64'd0;
			endcase
		`ADDI,`SUBI,`MULI,`CMPI:	imm <= {{48{ir[15]}},ir[15:0]};	// sign extend
		`ANDI:							imm <= {{48{1'b1}},ir[15:0]};		// one extend
		`ORI,`EORI,`CMPUI:	imm <= {48'd0,ir[15:0]};				// zero extend
		`SHIFTI:	imm <= ir[5:0];
		default:	imm <= {{48{ir[15]}},ir[15:0]};
		endcase
		displacement <= {{9{ir[20]}},ir[20:0],2'b0};
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// Fetch values from register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
RFETCH:
	begin
		state <= EXECUTE;
		sia <= Rs1==5'd0 ? 64'd0 : Rs1==5'd31 ? ssp : srfoa;
		sib <= Rs2==5'd0 ? 64'd0 : Rs2==5'd31 ? ssp : srfob;
		sic <= Rs3==5'd0 ? 64'd0 : Rs3==5'd31 ? ssp : srfoc;
		uia <= Rs1==5'd0 ? 64'd0 : Rs1==5'd31 ? usp : irfoa;
		uib <= Rs2==5'd0 ? 64'd0 : Rs2==5'd31 ? usp : irfob;
		uic <= Rs3==5'd0 ? 64'd0 : Rs3==5'd31 ? usp : irfoc;
		if (SystemMode) begin
			ia <= Rs1==5'd0 ? 64'd0 : Rs1==5'd31 ? ssp : srfoa;
			ib <= Rs2==5'd0 ? 64'd0 : Rs2==5'd31 ? ssp : srfob;
			ic <= Rs3==5'd0 ? 64'd0 : Rs3==5'd31 ? ssp : srfoc;
		end
		else begin
			ia <= Rs1==5'd0 ? 64'd0 : Rs1==5'd31 ? usp : irfoa;
			ib <= Rs2==5'd0 ? 64'd0 : Rs2==5'd31 ? usp : irfob;
			ic <= Rs3==5'd0 ? 64'd0 : Rs3==5'd31 ? usp : irfoc;
		end
		case(opcode)
		`ITOF:
			if (ir[6])
				fa <= Rs1==5'd0 ? 80'd0 : frfoa;
			else
				fa <= Rs1==5'd0 ? 80'd0 : irfoa;
		default:
			fa <= Rs1==5'd0 ? 80'd0 : frfoa;
		endcase
		fb <= Rs2==5'd0 ? 80'd0 : frfob;
		fc <= Rs3==5'd0 ? 80'd0 : frfoc;
		if (SystemMode)
			sp <= ssp;
		else
			sp <= usp;
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		state <= WRITEBACK;
		case(opcode)
		`CTRL:
			case(ctrlop)
			`SEI: if (SystemMode) begin res <= im; im <= ia[3:0]|imm[3:0]; end
			`PFI:	begin res <= im; end
			`RTI:	;	// Executed at writeback
			default:	;
			endcase
		`R2:
			case(funct)
			`ADD:	res <= ia + ib;
			`SUB:	res <= ia - ib;
			`MUL:	res <= $signed(ia) * $signed(ib);
			`CMP:	res <= $signed(ia) < $signed(ib) ? -64'd1 : ia==ib ? 64'd0 : 64'd1;
			`CMPU:	res <= ia < ib ? -64'd1 : ia==ib ? 64'd0 : 64'd1;
			`AND:	res <= ia & ib;
			`OR:	res <= ia | ib;
			`EOR:	res <= ia ^ ib;
			`SHIFT:
				case(shiftop)
				`SHL:		res <= ia << ib[5:0];
				`SHR:		res <= ia >> ib[5:0];
				default:	res <= ia << ib[5:0];
				endcase
			default:	;
			endcase
		`ADDI:	res <= ia + imm;
		`SUBI:	res <= ia - imm;
		`MULI:	res <= $signed(ia) * $signed(imm);
		`CMPI:	res <= $signed(ia) < $signed(imm) ? -64'd1 : ia==imm ? 64'd0 : 64'd1;
		`CMPUI:	res <= ia < imm ? -64'd1 : ia==imm ? 64'd0 : 64'd1;
		`ANDI:	res <= ia & imm;
		`ORI:		res <= ia | imm;
		`EORI:	res <= ia ^ imm;
		`SHIFTI:
			case(shiftop)
			`SHLI:		res <= ia << imm[5:0];
			`SHRI:		res <= ia >> imm[5:0];
			default:	res <= ia << imm[5:0];
			endcase
		`MOV:
			case(S2)
			2'd0:			res <= uia;
			2'd1:			res <= fa;
			2'd2:			res <= sia;
			default:	res <= uia;
			endcase
		`ITOF:	begin fltCnt <= 8'd03; state <= FLOAT; end
		`FTOI:	begin fltCnt <= 8'd03; state <= FLOAT; end
		`FADD:	begin fltCnt <= 8'd30; state <= FLOAT; end
		`FSUB:	begin fltCnt <= 8'd30; state <= FLOAT; end
		`FMUL:	begin fltCnt <= 8'd30; state <= FLOAT; end
		`FDIV:	begin fltCnt <= 8'd40; state <= FLOAT; end
		`FSQRT:	begin fltCnt <= 8'd80; state <= FLOAT; end
		`BEQZ:	if (ia==64'd0) pc <= pc + displacement;
		`BNEZ:	if (ia!=64'd0) pc <= pc + displacement;
		`BLTZ:	if (ia[63]) pc <= pc + displacement;
		`BLEZ:	if (ia[63] || ia==64'd0) pc <= pc + displacement;
		`BGTZ:	if (!ia[63] && ia!=64'd0) pc <= pc + displacement;
		`BGEZ:	if (!ia[63]) pc <= pc + displacement;
		`BRA:		pc <= pc + displacement;
		`JMP:		pc[15:0] <= ir[15:0];
		`JMPR:	pc <= ia + {{11{ir[20]}},ir[20:0]};
		`JSR,`JSRR:
			begin
				cyc_o <= HIGH;
				we_o <= HIGH;
				adr_o <= sp - 2'd1;
				dat_o <= pc + 2'd1;
				state <= MEMORY;
			end
		`LDO,`LDF:
			begin
				cyc_o <= HIGH;
				adr_o <= ia + imm;
				state <= MEMORY;
			end
		`POP,`POPF:
			begin
				cyc_o <= HIGH;
				adr_o <= sp;
				sp <= sp + 2'd1;
				state <= MEMORY;
			end
		`STO,`STF:
			begin
				cyc_o <= HIGH;
				we_o <= HIGH;
				adr_o <= ia + imm;
				dat_o <= ib;
				state <= MEMORY;
			end
		`PUSH:
			begin
				cyc_o <= HIGH;
				we_o <= HIGH;
				adr_o <= sp - 2'd1;
				dat_o <= ib;
				sp <= sp - 2'd1;
				state <= MEMORY;
			end
		`PUSHF:
			begin
				cyc_o <= HIGH;
				we_o <= HIGH;
				adr_o <= sp - 2'd1;
				dat_o <= fb;
				sp <= sp - 2'd1;
				state <= MEMORY;
			end
		default:	;
		endcase
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MEMORY:
	if (ack_i) begin
		cyc_o <= LOW;
		we_o <= LOW;
		case(opcode)
		`JSR:	begin sp <= sp - 2'd1; pc[15:0] <= ir[15:0]; end
		`JSRR: begin sp <= sp - 2'd1; pc <= ia + imm; end
		`LDO:	res <= dat_i;
		`LDF:	res <= dat_i;
		`POP:	res <= dat_i;
		`POPF:	res <= dat_i;
		endcase
		state <= WRITEBACK;
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Float
// Wait for floating-point operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FLOAT:
	begin
		fltCnt <= fltCnt - 2'd1;
		if (fltCnt==8'd0) begin
			case(opcode)
			`ITOF:	res <= itof_res;
			`FTOI:	res <= ftoi_res;
			`FADD:	res <= fres;
			`FSUB:	res <= fres;
			`FMUL:	res <= fres;
			`FDIV:	res <= fres;
			`FSQRT:	res <= fres;
			`FCMP:	res <= fcmp_res;
			endcase
			state <= WRITEBACK;
		end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// Update the register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WRITEBACK:
	begin
		state <= IFETCH;
		case(opcode)
		`CTRL:
			case(ctrlop)
			`SYS:	begin SystemMode <= 1'b1; pc <= spc; pim <= im; end
			`PFI:	if (!SystemMode) begin
							wrirf <= 1'b1; 
							if (irq_i > ia[3:0]|imm[3:0]) begin
								SystemMode <= 1'b1;
								pc <= spc;
							end
						end
			`RTI:	if (SystemMode) begin
							SystemMode <= 1'b0;
							im <= pim;
							pc <= upc;
						end
			default:	;
			endcase
		`ADDI,`SUBI,`MULI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI,`SHIFTI,`R2,`FCMP:
			if (SystemMode)
				wrsrf <= 1'b1;
			else
				wrirf <= 1'b1;
		`MOV:
			case(T2)
			2'd0:		wrirf <= 1'b1;
			2'd1:		wrfrf <= 1'b1;
			2'd2:		wrsrf <= 1'b1;
			default:	;
			endcase
		`FTOI:
			case(ir[7])
			1'b0:	wrirf <= 1'b1;
			1'b1:	wrfrf <= 1'b1;
			endcase
		`ITOF,`FADD,`FSUB,`FMUL,`FDIV,`FSQRT:
			wrfrf <= 1'b1;
		`LDO,`POP:
			if (SystemMode)
				wrsrf <= 1'b1;
			else
				wrirf <= 1'b1;
		`LDF,`POPF:	wrfrf <= 1'b1;
		endcase
		if (SystemMode)
			ssp <= sp;
		else
			usp <= sp;
		if (SystemMode)
			spc <= pc;
		else
			upc <= pc;
	end
endcase

endmodule
