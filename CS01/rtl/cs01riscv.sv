// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	cs01riscv.sv
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

`define FADD		5'd0
`define FSUB		5'd1
`define FMUL		5'd2
`define FDIV		5'd3
`define FSQRT		5'd11
`define FCMP		5'd20
`define FCVT2I	5'd24
`define FCVT2F	5'd25

`define LOAD	7'd3
`define LB			3'd0
`define LH			3'd1
`define LW			3'd2
`define LBU			3'd4
`define LHU			3'd5
`define LOADF	7'd7
`define FENCE	7'd15
`define AUIPC	7'd23
`define STORE	7'd35
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define STOREF	7'd39
`define LUI		7'd55
`define FLOAT	7'd83
`define Bcc		7'd99
`define BEQ			3'd0
`define BNE			3'd1
`define BLT			3'd4
`define BGE			3'd5
`define BLTU		3'd6
`define BGEU		3'd7
`define JALR	7'd103
`define JAL		7'd111
`define ECALL	32'h00000073
`define ERET	32'h10000073
`define PFI		32'h10300073
`define CS_ILLEGALINST	2

`include "fp/fpConfig.sv"

module cs01riscv(rst_i, clk_i, wc_clk_i, irq_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter WID = 32;
parameter FPWID = 32;
input rst_i;
input clk_i;
input wc_clk_i;
input [3:0] irq_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [FPWID-1:0] dat_i;
output reg [FPWID-1:0] dat_o;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "fp/fpSize.sv"

// Nonm visible registers
reg SystemMode;
reg [31:0] ir;			// instruction register
reg [31:0] upc;			// user mode pc
reg [31:0] spc;			// system mode pc
reg [3:0] pim;			// previous interrupt mask
reg [4:0] Rd, Rs1, Rs2, Rs3;
reg [WID-1:0] ia, ib, ic;
reg [WID-1:0] uia, uib, uic;
reg [WID-1:0] sia, sib, sic;
reg [FPWID-1:0] fa, fb, fc;
reg [WID-1:0] imm, res;
reg [WID-1:0] displacement;				// branch displacement
reg [1:0] luix0;
// Decoding
wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [4:0] funct5 = ir[31:27];
wire [6:0] funct7 = ir[31:25];
wire [2:0] rm3 = ir[14:12];

reg [WID-1:0] iregfile [0:31];		// integer / system register file
reg [WID-1:0] sregfile [0:31];
reg [FPWID-1:0] fregfile [0:31];		// floating-point register file
reg [31:0] pc;			// generic program counter
reg [31:0] ipc;			// pc value at instruction
reg [3:0] im;				// interrupt mask
reg [2:0] rm;
reg wrirf, wrsrf, wrfrf;
wire [WID-1:0] irfoa = iregfile[Rs1];
wire [WID-1:0] irfob = iregfile[Rs2];
wire [WID-1:0] irfoc = iregfile[Rs3];
wire [WID-1:0] srfoa = sregfile[Rs1];
wire [WID-1:0] srfob = sregfile[Rs2];
wire [WID-1:0] srfoc = sregfile[Rs3];
wire [FPWID-1:0] frfoa = fregfile[Rs1];
wire [FPWID-1:0] frfob = fregfile[Rs2];
wire [FPWID-1:0] frfoc = fregfile[Rs3];
always @(posedge clk_i)
if (wrirf)
	iregfile[Rd] <= res[WID-1:0];
always @(posedge clk_i)
if (wrsrf)
	sregfile[Rd] <= res[WID-1:0];
always @(posedge clk_i)
if (wrfrf)
	fregfile[Rd] <= res;
reg illegal_insn;

// CSRs
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg [63:0] instret;	// instructions completed.
reg [31:0] mcause;

function [3:0] fnSelect;
input [6:0] op6;
input [2:0] fn3;
case(op6)
`LOAD:
	case(fn3)
	`LB,`LBU:	fnSelect = 4'h1;
	`LH,`LHU:	fnSelect = 4'h3;
	default:	fnSelect = 4'hF;	
	endcase
`LOADF:	fnSelect = 4'hF;
`STORE:
	case(fn3)
	`SB:	fnSelect = 4'h1;
	`SH:	fnSelect = 4'h3;
	default:	fnSelect = 4'hF;
	endcase
`STOREF:	fnSelect = 4'hF;
endcase
endfunction

wire [31:0] ea = ia + imm;
reg [63:0] dati;
wire [31:0] datiL = dat_i >> {ea[1:0],3'b0};
wire [63:0] sdat = (opcode==`STOREF ? fb : ib) << {ea[1:0],3'b0};
wire [7:0] ssel = fnSelect(opcode,funct3) << ea[1:0];

reg [3:0] state;
parameter IFETCH = 4'd1;
parameter IFETCH2 = 4'd2;
parameter DECODE = 4'd3;
parameter RFETCH = 4'd4;
parameter EXECUTE = 4'd5;
parameter MEMORY = 4'd6;
parameter MEMORY2 = 4'd7;
parameter MEMORY2_ACK = 4'd8;
parameter FLOAT = 4'd9;
parameter WRITEBACK = 4'd10;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [7:0] fltCnt;
reg [FPWID-1:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
wire sqrt_done;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
wire ld = state==EXECUTE;
reg ld1;
always @(posedge clk_i)
	ld1 <= ld;
fpCompare #(.FPWID(FPWID)) u1 (.a(fa), .b(fb), .o(fcmp_o), .nanx());
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_i), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(fa), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_i), .ce(1'b1), .op(~Rs2[0]), .i(fa), .o(ftoi_res), .overflow());
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_i), .ce(1'b1), .rm(rmq), .op(funct5==`FSUB), .a(fa), .b(fb), .o(fas_o));
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_i), .ce(1'b1), .a(fa), .b(fb), .o(fmul_o), .sign_exe(), .inf(), .overflow(), .underflow());
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_i), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(fa), .b(fb), .o(fdiv_o), .done(), .sign_exe(), .overflow(), .underflow());
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .ld(ld),
	.a(fa), .o(fsqrt_o), .done(sqrt_done), .sqrinf(), .sqrneg());

always @(posedge clk_i)
case(funct5)
`FADD:	fnorm_i <= fas_o;
`FSUB:	fnorm_i <= fas_o;
`FMUL:	fnorm_i <= fmul_o;
`FDIV:	fnorm_i <= fdiv_o;
`FSQRT:	fnorm_i <= fsqrt_o;
default:	fnorm_i <= 1'd0;
endcase
fpNormalize #(.FPWID(FPWID)) u8 (.clk(clk_i), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(1'b0), .under_o(), .inexact_o());
fpRound #(.FPWID(FPWID)) u9 (.clk(clk_i), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));

always @(posedge clk_i)
if (rst_i)
	tick <= 64'd0;
else
	tick <= tick + 2'd1;

reg [5:0] ld_time;
reg [63:0] wc_time_dat;
reg [63:0] wc_times;
always @(posedge wc_clk_i)
begin
	if (|ld_time)
		wc_time <= wc_time_dat;
	else
		wc_time <= wc_time + 2'd1;
end

always @(posedge clk_i)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset
// The program counters are set at their reset values.
// System mode is activated and interrupts are masked.
// All other state is undefined.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (rst_i) begin
	state <= IFETCH;
	spc <= 32'hFFFC0000;
	upc <= 32'hFFFC0100;
	pc <= 32'hFFFC0000;
	SystemMode <= 1'b1;
	im <= 4'd15;
	wrirf <= 1'b0;
	wrsrf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
	cyc_o <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
	luix0 <= 2'b0;
	instret <= 64'd0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
end
else begin
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
case (state)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch
// Get the instruction from the rom.
// Increment the program counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
IFETCH:
	begin
		illegal_insn <= 1'b1;
		luix0 <= {luix0[0],1'b0};
		ipc <= pc;
		wrirf <= 1'b0;
		wrsrf <= 1'b0;
		wrfrf <= 1'b0;
		vpa_o <= HIGH;
		cyc_o <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'hF;
		adr_o <= pc;
		state <= IFETCH2;
 		if (irq_i > im) begin
			cyc_o <= LOW;
			mcause[31] <= 1'b1;
			mcause[3:0] <= irq_i;
			SystemMode <= 1'b1;
			pc <= spc;
			pim <= im;
			im <= 4'd15;
			state <= IFETCH;
		end
		else
			pc <= pc + 3'd4;
	end
IFETCH2:
	if (ack_i) begin
		vpa_o <= LOW;
		cyc_o <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		ir <= dat_i[31:0];
		state <= DECODE;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// Decode the register fields, immediate values, and branch displacement
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DECODE:
	begin
		state <= RFETCH;
		if (ir==`PFI && irq_i != 4'h0) begin
			mcause[31] <= 1'b1;
			mcause[3:0] <= irq_i;
			SystemMode <= 1'b1;
			pc <= spc;
			state <= IFETCH;
		end
		// Set some sensible decode defaults
		Rs1 <= ir[19:15];
		Rs2 <= ir[24:20];
		Rd <= 5'd0;
		displacement <= 32'd0;
		// Override defaults
		case(opcode)
		`AUIPC,`LUI:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				imm <= {ir[31:12],12'd0};
				if (ir[11:7]==5'd0)
					luix0 <= 2'b11;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				imm <= {{11{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
			end
		`JALR:
			begin
				illegal_insn <= 1'b0;
				Rs2 <= 5'd0;
				Rd <= ir[11:7];
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
			end
		`LOAD,`LOADF:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
			end
		`STORE,`STOREF:
			begin
				if (luix0[1])
					imm[11:0] <= {ir[31:25],ir[11:7]};
				else
					imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
			end
		7'd19:
			begin
				if (luix0[1])
					case(funct3)
					3'd0:	imm[11:0] <= ir[31:20];
					3'd1: imm <= imm[24:20];
					3'd2:	imm[11:0] <= ir[31:20];
					3'd3: imm[11:0] <= ir[31:20];
					3'd4: imm[11:0] <= ir[31:20];
					3'd5: imm <= imm[24:20];
					3'd6: imm[11:0] <= ir[31:20];
					3'd7: imm[11:0] <= ir[31:20];
					endcase
				else
					case(funct3)
					3'd0:	imm <= {{20{ir[31]}},ir[31:20]};
					3'd1: imm <= imm[24:20];
					3'd2:	imm <= {{20{ir[31]}},ir[31:20]};
					3'd3: imm <= {{20{ir[31]}},ir[31:20]};
					3'd4: imm <= {{20{ir[31]}},ir[31:20]};
					3'd5: imm <= imm[24:20];
					3'd6: imm <= {{20{ir[31]}},ir[31:20]};
					3'd7: imm <= {{20{ir[31]}},ir[31:20]};
					endcase
				Rd <= ir[11:7];
			end
		7'd51,7'd115:
			Rd <= ir[11:7];
		`FLOAT:
			Rd <= ir[11:7];
		`Bcc:
			displacement <= {{WID-13{ir[31]}},ir[31],ir[7],ir[30:25],ir[11:8],1'b0};
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// Fetch values from register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
RFETCH:
	begin
		state <= EXECUTE;
		sia <= Rs1==5'd0 ? {WID{1'd0}} : srfoa;
		sib <= Rs2==5'd0 ? {WID{1'd0}} : srfob;
		uia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
		uib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
		if (SystemMode) begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : srfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : srfob;
		end
		else begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
		end
		fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
		case(opcode)
		`FLOAT:
			case(funct5)
			`FCVT2F:
				fa <= Rs1==5'd0 ? {FPWID{1'd0}} : irfoa;
			default:	fa <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
			endcase
		default:	;
		endcase
		fb <= Rs2==5'd0 ? {FPWID{1'd0}} : frfob;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		state <= WRITEBACK;
		case(opcode)
		`LUI:	res <= imm;
		`AUIPC:	res <= {ipc[31:12],12'd0} + imm;
		7'd51:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:		begin res = ia + ib; illegal_insn <= 1'b0; end
				7'd32:	begin res = ia - ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << ib[4:0]; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd2:
				case(funct7)
				7'd0:	begin res <= $signed(ia) < $signed(ib); illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd3:
				case(funct7)
				7'd0:	begin res <= ia < ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd4:
				case(funct7)
				7'd0:	begin res <= ia ^ ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> ib[4:0]; illegal_insn <= 1'b0; end
				7'd32:	
					begin
						if (ia[WID-1])
							res <= (ia >> ib[4:0]) | ~({WID{1'b1}} >> ib[4:0]);
						else
							res <= ia >> ib[4:0];
 						illegal_insn <= 1'b0;
 					end
				default:	;
				endcase
			3'd6:
				case(funct7)
				7'd0:	begin res <= ia | ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd7:
				case(funct7)
				7'd0:	begin res <= ia & ib; illegal_insn <= 1'b0; end
				default:	;
				endcase
			endcase	
		7'd19:
			case(funct3)
			3'd0:	begin res <= ia + imm; illegal_insn <= 1'b0; end
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << imm[4:0]; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd2:	begin res <= $signed(ia) < $signed(imm); illegal_insn <= 1'b0; end
			3'd3:	begin res <= ia < imm; illegal_insn <= 1'b0; end
			3'd4:	begin res <= ia ^ imm; illegal_insn <= 1'b0; end
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> imm[4:0]; illegal_insn <= 1'b0; end
				7'd16:
					begin
						if (ia[WID-1])
							res <= (ia >> imm[4:0]) | ~({WID{1'b1}} >> imm[4:0]);
						else
							res <= ia >> imm[4:0];
						illegal_insn <= 1'b0;
					end
				endcase
			3'd6:	begin res <= ia | imm; illegal_insn <= 1'b0; end
			3'd7:	begin res <= ia & imm; illegal_insn <= 1'b0; end
			endcase
		`FLOAT:	// Float
			case(funct5)
			5'd0:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FADD
			5'd1:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FSUB
			5'd2:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FMUL
			5'd3:	begin fltCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
			5'd11:begin fltCnt <= 8'd160; state <= FLOAT; illegal_insn <= 1'b0; end	// FSQRT
			5'd20:
				case(funct3)
				3'd0:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLE
				3'd1:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLT
				3'd2:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FEQ
				default:	;
				endcase
			5'd24:	begin fltCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.T.FT
			5'd25:	begin fltCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.FT.T
			default:	;
			endcase
		`JAL:
			begin
				res <= pc;
				pc <= ipc + imm;
				illegal_insn <= 1'b0;
			end
		`JALR:
			begin
				res <= pc;
				pc <= ia + imm;
				illegal_insn <= 1'b0;
			end
		`Bcc:
			case(funct3)
			3'd0:	begin if (ia==ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd1: begin if (ia!=ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd4:	begin if ($signed(ia) < $signed(ib)) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd5:	begin if ($signed(ia) >= $signed(ib)) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd6:	begin if (ia < ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			3'd7:	begin if (ia >= ib) pc <= ipc + displacement; illegal_insn <= 1'b0; end
			default:	;
			endcase
		`LOAD,`LOADF:
			begin
				cyc_o <= HIGH;
				stb_o <= HIGH;
				sel_o <= ssel[3:0];
				adr_o <= ea;
				state <= MEMORY;
			end
		`STORE:
			begin
				cyc_o <= HIGH;
				stb_o <= HIGH;
				we_o <= HIGH;
				sel_o <= ssel[3:0];
				adr_o <= ea;
				dat_o <= sdat[31:0];
				case(funct3)
				3'd0,3'd1,3'd2:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY;
			end
		`STOREF:
			begin
				cyc_o <= HIGH;
				stb_o <= HIGH;
				we_o <= HIGH;
				sel_o <= ssel[3:0];
				adr_o <= ea;
				dat_o <= sdat[31:0];
				case(funct3)
				3'd2:	illegal_insn <= 1'b0;
				default:	;
				endcase
				state <= MEMORY;
			end
		7'd115:
			begin
				if (ir==`ECALL) begin
					SystemMode <= 1'b1;
					pc <= spc;
					illegal_insn <= 1'b0;
				end
				if (ir==`ERET) begin
					SystemMode <= 1'b0;
					pc <= upc;
					im <= pim;
					illegal_insn <= 1'b0;
				end
				case(funct3)
				3'd2:
					case(Rs1)
					5'd0:
						case(Rs2)
						5'd0:
							case(funct7)
							7'd96:	begin res <= tick[31: 0]; illegal_insn <= 1'b0; end
							7'd100:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
							default:	;
							endcase
						5'd1:
							case(funct7)
							7'd96:	begin res <= wc_times[31: 0]; illegal_insn <= 1'b0; end
							7'd100:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
							default:	;
							endcase
						5'd2:
							case(funct7)
							7'd96:	begin res <= instret[31: 0]; illegal_insn <= 1'b0; end
							7'd100:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
							default:	;
							endcase
						default:	;
						endcase
					default:	;
					endcase
				default:	;
				endcase
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
		stb_o <= LOW;
		if (ssel[7:4]==4'h0) begin
			cyc_o <= LOW;
			we_o <= LOW;
			case(opcode)
			`LOAD:
				case(funct3)
				3'd0:	begin res <= {{24{datiL[7]}},datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd1: begin res <= {{16{datiL[15]}},datiL[15:0]}; illegal_insn <= 1'b0; end
				3'd2:	begin res <= dat_i; illegal_insn <= 1'b0; end
				3'd4:	begin res <= {24'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
				3'd5:	begin res <= {16'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			`LOADF:	begin res <= dat_i; illegal_insn <= 1'b0; end
			endcase
			state <= WRITEBACK;
		end
		else
			state <= MEMORY2;
		dati[31:0] <= dat_i;
	end
MEMORY2:
	begin
		stb_o <= HIGH;
		sel_o <= ssel[7:4];
		adr_o <= {adr_o[31:2]+2'd1,2'd0};
		dat_o <= sdat[63:32];
		state <= MEMORY2_ACK;
	end
MEMORY2_ACK:
	if (ack_i) begin
		cyc_o <= LOW;
		stb_o <= LOW;
		we_o <= LOW;
		sel_o <= 4'h0;
		case(opcode)
		`LOAD:
			case(funct3)
			3'd1: begin res[31:8] <= {{16{dat_i[7]}},dat_i[7:0]}; illegal_insn <= 1'b0; end
			3'd2:
				case(ea[1:0])
				2'd1:	begin res <= {dat_i[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
				2'd2:	begin res <= {dat_i[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
				2'd3:	begin res <= {dat_i[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd5:	begin res[31:8] <= {16'd0,dat_i[7:0]}; illegal_insn <= 1'b0; end
			default:	;
			endcase
		`LOADF:
			case(ea[1:0])
			2'd1:	begin res <= {dat_i[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
			2'd2:	begin res <= {dat_i[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
			2'd3:	begin res <= {dat_i[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
			default:	;
			endcase
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
			case(funct5)
			5'd0:	res <= fres;	// FADD
			5'd1:	res <= fres;	// FSUB
			5'd2:	res <= fres;	// FMUL
			5'd3:	res <= fres;	// FDIV
			5'd11:res <= fres;	// FSQRT
			5'd20:
				case(funct3)
				3'd0:	res <= fcmp_o[2];	// FLE
				3'd1:	res <= fcmp_o[1];	// FLT
				3'd2:	res <= fcmp_o[0];	// FEQ
				default:	;
				endcase
			5'd24:	res <= ftoi_res;	// FCVT.T.FT
			5'd25:	res <= itof_res;	// FCVT.FT.T
			default:	;
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
		instret <= instret + 2'd1;
		case(opcode)
		`LUI,`AUIPC,7'd19,7'd51:
			if (SystemMode)
				wrsrf <= 1'b1;
			else
				wrirf <= 1'b1;
		`FLOAT:
			case(funct5)
			5'd20:
				if (SystemMode)
					wrsrf <= 1'b1;
				else		
					wrirf <= 1'b1;
			5'd24:
				if (SystemMode)
					wrsrf <= 1'b1;
				else		
					wrirf <= 1'b1;
			default:	wrfrf <= 1'b1;
			endcase
		`LOAD:
			if (SystemMode)
				wrsrf <= 1'b1;
			else
				wrirf <= 1'b1;
		`LOADF:	wrfrf <= 1'b1;
		endcase
		if (SystemMode)
			spc <= pc;
		else
			upc <= pc;
	end
endcase
end

endmodule
