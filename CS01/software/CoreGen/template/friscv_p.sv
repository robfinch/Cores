// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv.sv
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
`define FMIN		5'd5
`define FSQRT		5'd11
`define FSGNJ		5'd16
`define FCMP		5'd20
`define FCVT2I	5'd24
`define FCVT2F	5'd26
`define FCLASS	5'd28

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
`define WFI		32'h10100073
`define PFI		32'h10300073
`define CS_ILLEGALINST	2

`include "fp/fpConfig.sv"

module friscv(rst_i, hartid_i, clk_i, wc_clk_i, irq_i, vpa_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter WID = 32;
parameter FPWID = 32;
input rst_i;
input [31:0] hartid_i;
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

wire clk_g;					// gated clock
// Nonm visible registers
reg MachineMode;
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
{+F}
reg [FPWID-1:0] fregfile [0:31];		// floating-point register file
{-F}
reg [31:0] pc;			// generic program counter
reg [31:0] ipc;			// pc value at instruction
reg [3:0] im;				// interrupt mask
reg [2:0] rm;
reg wrirf, wrfrf;
wire [WID-1:0] irfoa = iregfile[Rs1];
wire [WID-1:0] irfob = iregfile[Rs2];
wire [WID-1:0] irfoc = iregfile[Rs3];
wire [WID-1:0] srfoa = sregfile[Rs1];
wire [WID-1:0] srfob = sregfile[Rs2];
wire [WID-1:0] srfoc = sregfile[Rs3];
{+F}
wire [FPWID-1:0] frfoa = fregfile[Rs1];
wire [FPWID-1:0] frfob = fregfile[Rs2];
wire [FPWID-1:0] frfoc = fregfile[Rs3];
{-F}
always @(posedge clk_i)
if (wrirf && state==WRITEBACK && !MachineMode)
	iregfile[Rd] <= res[WID-1:0];
always @(posedge clk_i)
if (wrirf && state==WRITEBACK &&  MachineMode)
	sregfile[Rd] <= res[WID-1:0];
{+F}
always @(posedge clk_i)
if (wrfrf && state==WRITEBACK)
	fregfile[Rd] <= res;
{-F}
reg illegal_insn;

// CSRs
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi;
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcause;
reg [31:0] mstatus;
reg [31:0] mtvec;
reg [31:0] mscratch;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};

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
{+F}
`LOADF:	fnSelect = 4'hF;
{-F}
`STORE:
	case(fn3)
	`SB:	fnSelect = 4'h1;
	`SH:	fnSelect = 4'h3;
	default:	fnSelect = 4'hF;
	endcase
{+F}
`STOREF:	fnSelect = 4'hF;
{-F}
default:	fnSelect = 4'h0;
endcase
endfunction

wire [31:0] ea = ia + imm;
reg [63:0] dati;
wire [31:0] datiL = dat_i >> {ea[1:0],3'b0};
{+F}
wire [63:0] sdat = (opcode==`STOREF ? fb : ib) << {ea[1:0],3'b0};
{-F}
{!F}
wire [63:0] sdat = ib << {ea[1:0],3'b0};
{-F}
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

{+F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [7:0] fltCnt;
reg [FPWID-1:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
wire mul_of, div_of;
wire mul_uf, div_uf;
wire norm_nx;
wire sqrt_done;
wire cmpnan, cmpsnan;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
wire ld = state==EXECUTE;
reg ld1;
wire srqneg, sqrinf;
wire fa_inf, fa_xz, fa_vz;
wire fa_qnan, fa_snan, fa_nan;
wire fb_qnan, fb_snan, fb_nan;
always @(posedge clk_g)
	ld1 <= ld;
fpDecomp #(FPWID) u12 (.i(fa), .sgn(), .exp(), .man(), .fract(), .xz(fa_xz), .mz(), .vz(fa_vz), .inf(fa_inf), .xinf(), .qnan(fa_qnan), .snan(fa_snan), .nan(fa_nan));
fpDecomp #(FPWID) u13 (.i(fb), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(fb_qnan), .snan(fb_snan), .nan(fb_nan));
fpCompare #(.FPWID(FPWID)) u1 (.a(fa), .b(fb), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(fa), .o(ftoi_res), .overflow());
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op(funct5==`FSUB), .a(fa), .b(fb), .o(fas_o));
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_g), .ce(1'b1), .a(fa), .b(fb), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_g), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(fa), .b(fb), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(fa), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));

always @(posedge clk_g)
case(funct5)
`FADD:	fnorm_i <= fas_o;
`FSUB:	fnorm_i <= fas_o;
`FMUL:	fnorm_i <= fmul_o;
`FDIV:	fnorm_i <= fdiv_o;
`FSQRT:	fnorm_i <= fsqrt_o;
default:	fnorm_i <= 1'd0;
endcase
reg fnorm_uf;
wire norm_uf;
always @(posedge clk_g)
case(funct5)
`FMUL:	fnorm_uf <= mul_uf;
`FDIV:	fnorm_uf <= div_uf;
default:	fnorm_uf <= 1'b0;
endcase
fpNormalize #(.FPWID(FPWID)) u8 (.clk(clk_g), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(fnorm_uf), .under_o(norm_uf), .inexact_o(norm_nx));
fpRound #(.FPWID(FPWID)) u9 (.clk(clk_g), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));
wire finf, fdn;
fpDecompReg #(FPWID) u10 (.clk(clk_g), .ce(1'b1), .i(fres), .sgn(), .exp(), .fract(), .xz(fdn), .vz(), .inf(finf), .nan() );
{-F}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Timers
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
if (rst_i)
	tick <= 64'd0;
else
	tick <= tick + 2'd1;

reg [5:0] ld_time;
reg [63:0] wc_time_dat;
reg [63:0] wc_times;
assign clr_wc_time_irq = wc_time_irq_clr[5];
always @(posedge wc_clk_i)
if (rst_i) begin
	wc_time <= 1'd0;
	wc_time_irq <= 1'b0;
end
else begin
	if (|ld_time)
		wc_time <= wc_time_dat;
	else
		wc_time <= wc_time + 2'd1;
	if (mtimecmp==wc_time[31:0])
		wc_time_irq <= 1'b1;
	if (clr_wc_time_irq)
		wc_time_irq <= 1'b0;
end

always @(posedge wc_clk_i)
if (rst_i)
	wfi <= 1'b0;
else begin
	if (set_wfi)
		wfi <= 1'b1;
	if (irq_i)
		wfi <= 1'b0;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

always @(posedge clk_g)
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
	mtvec <= 32'hFFFC0200;
	MachineMode <= 1'b1;
	im <= 4'd15;
	pim <= 4'd15;
	wrirf <= 1'b0;
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
	wc_time_irq_clr <= 6'h3F;
	mstatus <= 6'b110110;
end
else begin
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
wc_time_irq_clr <= {wc_time_irq_clr,wc_time_irq};

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
			MachineMode <= 1'b1;
			pc <= spc;
			pim <= im;
			im <= 4'd15;
			mstatus[5:0] <= {mstatus[2:0],2'b11,1'b0};
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
		adr_o <= pc;
		ir <= dat_i[31:0];
		state <= DECODE;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode Stage
// Decode the register fields, immediate values, and branch displacement.
// Determine if instruction will update register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
DECODE:
	begin
		state <= RFETCH;
		if (ir==`PFI && irq_i != 4'h0) begin
			mcause[31] <= 1'b1;
			mcause[3:0] <= irq_i;
			MachineMode <= 1'b1;
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
				wrirf <= 1'b1;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rs1 <= 5'd0;
				Rs2 <= 5'd0;
				imm <= {{11{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
				wrirf <= 1'b1;
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
				wrirf <= 1'b1;
			end
		`LOAD:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
{+F}
		`LOADF:
			begin
				Rd <= ir[11:7];
				Rs2 <= 5'd0;
				if (luix0[1])
					imm[11:0] <= ir[31:20];
				else
					imm <= {{20{ir[31]}},ir[31:20]};
				wrfrf <= 1'b1;
			end
		`STOREF:
			begin
				if (luix0[1])
					imm[11:0] <= {ir[31:25],ir[11:7]};
				else
					imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
			end
{-F}
		`STORE:
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
				wrirf <= 1'b1;
			end
		7'd51,7'd115:
			begin
				Rd <= ir[11:7];
				wrirf <= 1'b1;
			end
{+F}
		`FLOAT:
			begin
				Rd <= ir[11:7];
				if (funct5==5'd20 || funct5==5'd24 || funct5==5'd28)
					wrirf <= 1'b1;
				else
					wrfrf <= 1'b1;
			end
{-F}
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
		if (MachineMode) begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : srfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : srfob;
		end
		else begin
			ia <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
			ib <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
		end
{+F}
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
{-F}
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		state <= WRITEBACK;
		case(opcode)
		`LUI:	begin res <= imm; end
		`AUIPC:	begin res <= {ipc[31:12],12'd0} + imm; end
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
{+F}
		// The timeouts for the float operations are set conservatively. They may
		// be adjusted to lower values closer to actual time required.
		`FLOAT:	// Float
			case(funct5)
			`FADD:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FADD
			`FSUB:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FSUB
			`FMUL:	begin fltCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FMUL
			`FDIV:	begin fltCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
			`FMIN:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FMIN / FMAX
			`FSQRT:	begin fltCnt <= 8'd160; state <= FLOAT; illegal_insn <= 1'b0; end	// FSQRT
			`FSGNJ:	
				case(funct3)
				3'd0:	begin res <= {fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end		// FSGNJ
				3'd1:	begin res <= {~fb[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJN
				3'd2:	begin res <= {fb[FPWID-1]^fa[FPWID-1],fa[FPWID-1:0]}; illegal_insn <= 1'b0; end	// FSGNJX
				default:	;
				endcase
			5'd20:
				case(funct3)
				3'd0:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLE
				3'd1:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FLT
				3'd2:	begin fltCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FEQ
				default:	;
				endcase
			5'd24:	begin fltCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.T.FT
			5'd26:	begin fltCnt <= 8'd05; state <= FLOAT; illegal_insn <= 1'b0; end	// FCVT.FT.T
			5'd28:
				begin
					case(funct3)
					3'd0:	begin res <= fa; illegal_insn <= 1'b0; end	// FMV.X.S
					3'd1:
						begin
							res[0] <= fa[FPWID-1] & fa_inf;
							res[1] <= fa[FPWID-1] & !fa_xz;
							res[2] <= fa[FPWID-1] &  fa_xz;
							res[3] <= fa[FPWID-1] &  fa_vz;
							res[4] <= ~fa[FPWID-1] &  fa_vz;
							res[5] <= ~fa[FPWID-1] &  fa_xz;
							res[6] <= ~fa[FPWID-1] & !fa_xz;
							res[7] <= ~fa[FPWID-1] & fa_inf;
							res[8] <= fa_snan;
							res[9] <= fa_qnan;
							illegal_insn <= 1'b0;
						end
					endcase
				end
			5'd30:
				case(funct3)
				3'd0:	begin res <= ia; illegal_insn <= 1'b0; end	// FMV.S.X
				default:	;
				endcase
			default:	;
			endcase
{-F}
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
				pc[0] <= 1'b0;
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
		`LOAD:
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
{+F}
		`LOADF:
			begin
				cyc_o <= HIGH;
				stb_o <= HIGH;
				sel_o <= ssel[3:0];
				adr_o <= ea;
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
{-F}
		7'd115:
			begin
				case(ir)
				`ECALL:
					begin
						MachineMode <= 1'b1;
						pc <= spc;
						illegal_insn <= 1'b0;
					end
				`ERET:
					begin
						MachineMode <= 1'b0;
						pc <= upc;
						im <= pim;
						mstatus[5:0] <= {2'b11,1'b0,mstatus[5:3]};
						illegal_insn <= 1'b0;
					end
				`WFI:
					set_wfi <= 1'b1;
				default:
					begin
					case(funct3)
					3'd1,3'd2,3'd3,3'd5,3'd6,3'd7:
						case({funct7,Rs2})
						12'h001:	begin res <= fscsr[4:0]; illegal_insn <= 1'b0; end
						12'h002:	begin res <= rm; illegal_insn <= 1'b0; end
						12'h003:	begin res <= fscsr; illegal_insn <= 1'b0; end
						12'h301:	begin res <= mtvec; illegal_insn <= 1'b0; end
						12'h321:	begin res <= mtimecmp; wc_time_irq_clr <= 6'h3F; illegal_insn <= 1'b0; end
						12'h340:	begin res <= mscratch; illegal_insn <= 1'b0; end
						12'h341:	begin res <= upc; illegal_insn <= 1'b0; end
						12'hC00:	begin res <= tick[31: 0]; illegal_insn <= 1'b0; end
						12'hC80:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
						12'hC01,12'h701:	begin res <= wc_times[31: 0]; illegal_insn <= 1'b0; end
						12'hC81,12'h741:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC02:	begin res <= instret[31: 0]; illegal_insn <= 1'b0; end
						12'hC82:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
						12'hF00:	begin res <= 32'h0; illegal_insn <= 1'b0; end	// cpu description
						12'hF01:	begin res <= 32'h8000; illegal_insn <= 1'b0; end // implmentation id
						12'hF10:	begin res <= hartid_i; illegal_insn <= 1'b0; end
						default:	;
						endcase
					default:	;
					endcase
					case(funct3)
					3'd5,3'd6,3'd7:	ia <= {27'd0,Rs1};
					default:	;
					endcase
					end
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
{+U}
		if (ssel[7:4]==4'h0) begin
{-U}
			cyc_o <= LOW;
			we_o <= LOW;
			sel_o <= 4'h0;
			adr_o <= pc;
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
{+F}				
			`LOADF:	begin res <= dat_i; illegal_insn <= 1'b0; end
{-F}
			endcase
			state <= WRITEBACK;
{+U}
		end
		else
			state <= MEMORY2;
{-U}
		dati[31:0] <= dat_i;
	end
{+U}
// Run a second bus cycle to handle unaligned access.
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
		adr_o <= pc;
		case(opcode)
		`LOAD:
			begin
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
			end
{+F}
		`LOADF:
			begin
				case(ea[1:0])
				2'd1:	begin res <= {dat_i[7:0],dati[31:8]}; illegal_insn <= 1'b0; end
				2'd2:	begin res <= {dat_i[15:0],dati[31:16]}; illegal_insn <= 1'b0; end
				2'd3:	begin res <= {dat_i[23:0],dati[31:24]}; illegal_insn <= 1'b0; end
				default:	;
				endcase
			end
{-F}
		endcase
		state <= WRITEBACK;
	end
{-U}
{+F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Float
// Wait for floating-point operation to complete.
// Capture results.
// Set status flags.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FLOAT:
	begin
		fltCnt <= fltCnt - 2'd1;
		if (fltCnt==8'd0) begin
			case(funct5)
			5'd0:
				begin
					res <= fres;	// FADD
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			5'd1:
				begin
					res <= fres;	// FSUB
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			5'd2:
				begin
					res <= fres;	// FMUL
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			5'd3:	
				begin
					res <= fres;	// FDIV
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (fb[FPWID-2:0]==1'd0)
						fdz <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			5'd5:
				case(funct3)
				3'd0:	// FMIN	
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= fb;
					else if (!fa_nan & fb_qnan)
						res <= fa;
					else if (fcmp_o[1])
						res <= fa;
					else
						res <= fb;
				3'd1:	// FMAX
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= fb;
					else if (!fa_nan & fb_qnan)
						res <= fa;
					else if (fcmp_o[1])
						res <= fb;
					else
						res <= fa;
				default:	;
				endcase
			5'd11:
				begin
					res <= fres;	// FSQRT
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (fa[FPWID-2:0]==1'd0)
						fdz <= 1'b1;
					if (sqrinf|sqrneg)
						fnv <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			5'd20:
				case(funct3)
				3'd0:	
					begin
						res <= fcmp_o[2] & ~cmpnan;	// FLE
						if (cmpnan)
							fnv <= 1'b1;
					end
				3'd1:
					begin
						res <= fcmp_o[1] & ~cmpnan;	// FLT
						if (cmpnan)
							fnv <= 1'b1;
					end
				3'd2:
					begin
						res <= fcmp_o[0] & ~cmpnan;	// FEQ
						if (cmpsnan)
							fnv <= 1'b1;
					end
				default:	;
				endcase
			5'd24:	res <= ftoi_res;	// FCVT.W.S
			5'd26:	res <= itof_res;	// FCVT.S.W
			default:	;
			endcase
			state <= WRITEBACK;
		end
	end
{-F}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// Update the register file (actual clocking above).
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WRITEBACK:
	begin
		set_wfi <= 1'b0;
		if (opcode==7'd115) begin
			case(funct3)
			3'd1,3'd5:
				if (Rs1!=5'd0)
				case({funct7,Rs2})
{+F}
				12'h001:	begin
										fnx <= ia[0];
										fuf <= ia[1];
										fof <= ia[2];
										fdz <= ia[3];
										fnv <= ia[4];
									end
				12'h002:	rm <= ia[2:0];
				12'h003:	begin
										fnx <= ia[0];
										fuf <= ia[1];
										fof <= ia[2];
										fdz <= ia[3];
										fnv <= ia[4];
										rm <= ia[7:5];
									end
{-F}
				12'h301:	begin if (MachineMode) mtvec <= {ia[31:2],2'b0}; end
				12'h321:	begin if (MachineMode) mtimecmp <= ia; wc_time_irq <= 1'b0; end
				12'h340:	begin if (MachineMode) mscratch <= ia; end
				12'h341:	begin upc <= ia; if (!MachineMode) pc <= ia; end
				endcase
{+F}
			3'd2,3'd6:
				case({funct7,Rs2})
				12'h001:	begin
										if (ia[0]) fnx <= 1'b1;
										if (ia[1]) fuf <= 1'b1;
										if (ia[2]) fof <= 1'b1;
										if (ia[3]) fdz <= 1'b1;
										if (ia[4]) fnv <= 1'b1;
									end
				12'h002:	rm <= rm | ia[2:0];
				12'h003:	begin
										if (ia[0]) fnx <= 1'b1;
										if (ia[1]) fuf <= 1'b1;
										if (ia[2]) fof <= 1'b1;
										if (ia[3]) fdz <= 1'b1;
										if (ia[4]) fnv <= 1'b1;
										rm <= rm | ia[7:5];
									end
				default: ;
				endcase
			3'd3,3'd7:
				case({funct7,Rs2})
				12'h001:	begin
										if (ia[0]) fnx <= 1'b0;
										if (ia[1]) fuf <= 1'b0;
										if (ia[2]) fof <= 1'b0;
										if (ia[3]) fdz <= 1'b0;
										if (ia[4]) fnv <= 1'b0;
									end
				12'h002:	rm <= rm & ~ia[2:0];
				12'h003:	begin
										if (ia[0]) fnx <= 1'b0;
										if (ia[1]) fuf <= 1'b0;
										if (ia[2]) fof <= 1'b0;
										if (ia[3]) fdz <= 1'b0;
										if (ia[4]) fnv <= 1'b0;
										rm <= rm & ~ia[7:5];
									end
				default: ;
				endcase
{-F}
			default:	;
			endcase
		end
		state <= IFETCH;
		instret <= instret + 2'd1;
		if (MachineMode)
			spc <= pc;
		else
			upc <= pc;
	end
endcase
end

endmodule
