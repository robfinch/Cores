`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FISA64a.v
//  - 64 bit CPU
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
//  LUT's / ff's / MHz
// Block RAMs
// ============================================================================
//
`define TRUE	1'b1
`define FALSE	1'b0

`define BRK		8'h00
`define RR		8'h02
`define NAND		6'h00
`define NOR			6'h01
`define ENOR		6'h02
`define ADD			6'h04
`define SUB			6'h05
`define MUL			6'h07
`define DIV			6'h08
`define MOD			6'h09
`define AND			6'h0C
`define OR			6'h0D
`define EOR			6'h0E
`define ADDU		6'h14
`define SUBU		6'h15
`define MULU		6'h17
`define DIVU		6'h18
`define MODU		6'h19
`define MTSEG		6'h1C
`define MFSEG		6'h1D
`define MTSPR		6'h1E
`define MFSPR		6'h1F
`define SLL			6'h20
`define ROL			6'h21
`define SRL			6'h22
`define ROR			6'h23
`define SRA			6'h24
`define SLLI		6'h30
`define ROLI		6'h31
`define SRLI		6'h32
`define RORI		6'h33
`define SRAI		6'h34
`define RTI			6'h3F
`define ADDI	8'h04
`define SUBI	8'h05
`define MULI	8'h07
`define DIVI	8'h08
`define MODI	8'h09
`define ANDI	8'h0C
`define ORI		8'h0D
`define EORI	8'h0E
`define ADDUI	8'h14
`define SUBUI	8'h15
`define LDI		8'h16
`define MULUI	8'h17
`define DIVUI	8'h18
`define MODUI	8'h19
`define Scci	8'h3x
`define Bcci	8'h5x
`define BEQI	8'h50
`define BNEI	8'h51
`define BRAI	8'h56
`define BRNI	8'h57
`define BGTI	8'h58
`define BLEI	8'h59
`define BGEI	8'h5A
`define BLTI	8'h5B
`define BGTUI	8'h5C
`define BLEUI	8'h5D
`define BGEUI	8'h5E
`define BLTUI	8'h5F
`define RTS		8'h60
`define Bcc		8'h61
`define BEQ		4'h0
`define BNE		4'h1
`define BRA		4'h6
`define BRN		4'h7
`define BGT		4'h8
`define BLE		4'h9
`define BGE		4'hA
`define BLT		4'hB
`define BGTU	4'hC
`define BLEU	4'hD
`define BGEU	4'hE
`define BLTU	4'hF
`define JAL		8'h64
`define BSR		8'h66
`define Lx		8'b10000xxx
`define LB		8'h80
`define LBU		8'h81
`define LC		8'h82
`define LCU		8'h83
`define LH		8'h84
`define LHU		8'h85
`define LW		8'h86
`define LEA		8'h87
`define LxX		8'b10001xxx
`define LBX		8'h88
`define LBUX	8'h89
`define LCX		8'h8A
`define LCUX	8'h8B
`define LHX		8'h8C
`define LHUX	8'h8D
`define LWX		8'h8E
`define LEAX	8'h8F
`define Sx		8'b10100xxx
`define SB		8'hA0
`define SC		8'hA1
`define SH		8'hA2
`define SW		8'hA3
`define SxX		8'b10101xxx
`define SBX		8'hA8
`define SCX		8'hA9
`define SHX		8'hAA
`define SWX		8'hAB
`define NOP		8'hE1
`define IMM1	8'hFB
`define IMM2	8'hFC

`define VBR		6'd1

`define UNALIGNED_INSN	{9'd494,6'd62,6'd0,8'h00}

module FISA64a(rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, cyc_o, stb_o, lock_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
output reg lock_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

parameter RESET = 6'd1;
parameter IFETCH1 = 6'd2;
parameter IFETCH2 = 6'd3;
parameter DECODE = 6'd4;
parameter EXECUTE = 6'd5;
parameter MULDIV = 6'd13;
parameter MULT1 = 6'd14;
parameter MULT2 = 6'd15;
parameter MULT3 = 6'd16;
parameter DIV = 6'd17;
parameter FIX_SIGN = 6'd18;
parameter MD_RES = 6'd19;
parameter LOADSTORE1 = 6'd24;
parameter LOADSTORE2 = 6'd25;
parameter LOADSTORE3 = 6'd26;
parameter LOADSTORE4 = 6'd27;
parameter LOADSTORE5 = 6'd28;
parameter LOADSTORE6 = 6'd29;
parameter LOADSTORE7 = 6'd30;
parameter LOADSTORE8 = 6'd31;
parameter HANG = 6'd63;

parameter byt = 3'd0;
parameter ubyt = 3'd1;
parameter char = 3'd2;
parameter uchar = 3'd3;
parameter half = 3'd4;
parameter uhalf = 3'd5;
parameter word = 3'd6;

wire clk = clk_i;
reg [5:0] state;
reg [31:0] pc,opc;
reg [31:0] vbr;
reg [31:0] fault_pc;
reg [31:0] fault_cs;
reg [255:0] ibuf;
reg [31:5] ibufadr;
reg [40:0] ir;
reg [31:0] insncnt;
reg [31:0] tick;
wire [7:0] opcode = ir[7:0];
wire [5:0] func = ir[31:26];
wire [3:0] cond = ir[35:32];
reg gie;					// global interrupt enable
reg hwi;					// hardware interrupt occurring
reg im,imb,imb2;			// interrupt mask and backup
reg nmi_edge,nmi1;
reg [3:0] cpl,cplb,cplb2;	// current privilege level and backup
wire kernelMode = cpl < 4'd4;
reg isBRK;
reg [2:0] brkCnt;
reg [63:0] regfile [63:0];
wire [255:0] sego,cssego;
wire [5:0] Ra = ir[13:8];
wire [5:0] Rb = ir[19:14];
wire [5:0] Rc = ir[25:20];
reg [5:0] Rt,Sprt;
reg [3:0] Sa;
reg [5:0] St;
reg [63:0] rfoa,rfob,rfoc;
always @(Ra,pc)
case(Ra)
6'd00:	rfoa <= 64'd0;
6'd63:	rfoa <= pc;
default:	rfoa <= regfile[Ra];
endcase
always @(Rb,pc)
case(Rb)
6'd00:	rfob <= 64'd0;
6'd63:	rfob <= pc;
default:	rfob <= regfile[Rb];
endcase
always @(Rc,pc)
case(Rc)
6'd00:	rfoc <= 64'd0;
6'd63:	rfoc <= pc;
default:	rfoc <= regfile[Rc];
endcase
reg pe;				// protected mode enabled
reg [63:0] a,b,c,imm,immbuf;
wire signed [63:0] as = a;
reg [63:0] res,ea;
reg [31:0] segmented_ea;
reg [63:0] spro;
reg hasImm;
reg [6:0] cnt;
reg [63:0] aa,bb,q,r;
reg res_sgn;
wire [63:0] pa = a[63] ? -a : a;
wire [127:0] p1 = aa * bb;
reg [127:0] p;
wire [63:0] diff = r - bb;

wire [31:0] seg_base = sego[31:0];
wire [31:0] seg_limit = sego[159:128];

wire [31:0] cs_base = cssego[31:0];
wire [31:0] segmented_pc = kernelMode ? pc : {cs_base[31:4],4'h0} + pc;

function [31:0] fnIncdPC;
input [31:0] fpc;
case(fpc[3:0])
4'h0:	fnIncdPC = {fpc[31:4],4'h5};
4'h5:	fnIncdPC = {fpc[31:4],4'hA};
4'hA:	fnIncdPC = {fpc[31:4],4'h0} + 32'd16;
//default:	fnIncdPC <= `PC_ALIGN_FAULT_VECTOR;
endcase
endfunction

wire wrsrf = state==IFETCH1 || state==RESET;

segregfile u1
(
	.clk(clk),
	.wa(St[5:2]),
	.we0(St[1:0]==2'b00 && wrsrf),
	.we1(St[1:0]==2'b01 && wrsrf),
	.we2(St[1:0]==2'b10 && wrsrf),
	.we3(St[1:0]==2'b11 && wrsrf),
	.ra(Sa),
	.i(res),
	.o(sego),
	.cso(cssego)
);

reg takeb;
wire eqi = a==imm;
wire lti = $signed(a) < $signed(imm);
wire ltui = a < imm;
wire eq = a==b;
wire lt = $signed(a) < $signed(b);
wire ltu = a < b;

always @(opcode,eqi,lti,ltui,cond,eq,lt,ltu)
case(opcode)
`BEQI:	takeb <= eqi;
`BNEI:	takeb <= !eqi;
`BLTI:	takeb <= lti;
`BGEI:	takeb <= !lti;
`BLEI:	takeb <= lti|eqi;
`BGTI:	takeb <= !(lti|eqi);
`BLTUI:	takeb <= ltui;
`BLEUI:	takeb <= ltui|eqi;
`BGTUI:	takeb <= !(ltui|eqi);
`BGEUI:	takeb <= !ltui;
`BRAI:	takeb <= 1'b1;
`BRNI:	takeb <= 1'b0;
`Bcc:
	case(cond)
	`BEQ:	takeb <= eq;
	`BNE:	takeb <= !eq;
	`BLT:	takeb <= lt;
	`BGE:	takeb <= !lt;
	`BLE:	takeb <= lt|eq;
	`BGT:	takeb <= !(lt|eq);
	`BLTU:	takeb <= ltu;
	`BLEU:	takeb <= ltu|eq;
	`BGTU:	takeb <= !(ltu|eq);
	`BGEU:	takeb <= !ltu;
	`BRA:	takeb <= 1'b1;
	`BRN:	takeb <= 1'b0;
	default:	takeb <= 1'b0;
	endcase
default:	takeb <= 1'b0;
endcase

always @*
case(Ra)
6'd0:	spro <= tick;
`VBR:	spro <= vbr;
6'd8:	spro <= fault_pc;
endcase

always @(posedge clk)
if (rst_i) begin
	wb_nack();
	pc <= 32'd0;
	ibufadr <= 32'd1;
	insncnt <= 32'd0;
	tick <= 32'd0;
	gie <= `FALSE;
	nmi1 <= 1'b0;
	nmi_edge <= `FALSE;
	cpl <= 4'h0;
	pe <= 1'b0;
	St <= 6'd0;
	res <= 64'd0;	// used to load segment registers
	next_state(RESET);
end
else begin
tick <= tick + 32'd1;
nmi1 <= nmi_i;
if (nmi_i & ~nmi1)
	nmi_edge <= `TRUE;
case (state)
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// RESET stage
//
// - reset the segment registers
// - The segment registers are all set to zero so that the processor has
//   a flat image of memory. The segment limits are also zero and should be
//   initialized before protected mode is turned on.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

RESET:
	begin
		St <= St + 6'd1;
		if (St==6'd63)
			next_state(IFETCH1);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// IFETCH Stage
//
// It may take quite a few clock cycles to aquire the bus for the first
// instruction word. The bus is being shared with other devices. Once the
// bus is available read a good chunk of data from it. It's only a single
// clock for each subsequent instruction word, so eight words are read at
// a time. This is equal to six instructions.
// The instruction buffer acts like a mini direct mapped cache, where the
// entire cache is loaded on a miss. Six instructions are stored in the
// buffer, and if there's a loop back within the buffer, then the buffer
// is not fetched from memory.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
IFETCH1:
	begin
		next_state(DECODE);
		insncnt <= insncnt + 32'd1;
		regfile[Rt] <= res;
		if (Rt==6'd59)
			gie <= `TRUE;
		if (nmi_edge & gie & ~hasImm) begin
			hwi <= `TRUE;
			ir[7:0] <= `BRK;
			ir[13:8] <= 6'd0;
			ir[19:14] <= 6'd62;
			ir[28:20] <= 9'd510;
			nmi_edge <= 1'b0;
		end
		else if (irq_i & gie & ~im & ~hasImm) begin
			hwi <= `TRUE;
			ir[7:0] <= `BRK;
			ir[13:8] <= 6'd0;
			ir[19:14] <= 6'd62;
			ir[28:20] <= vect_i;
		end
		else if (ibufadr==segmented_pc[31:5]) begin
			case(pc[4:0])
			5'h00:	ir <= ibuf[40:0];
			5'h05:	ir <= ibuf[81:41];
			5'h0A:	ir <= ibuf[122:82];
			5'h10:	ir <= ibuf[168:128];
			5'h15:	ir <= ibuf[209:169];
			5'h1A:	ir <= ibuf[250:210];
			default:	ir <= `UNALIGNED_INSN;
			endcase
		end
		else begin
			wb_burst(6'd7,{segmented_pc[31:5],5'h0});
			next_state(IFETCH2);
		end
	end
IFETCH2:
	if (ack_i) begin
		adr_o[4:2] <= adr_o[4:2] + 3'd1;
		case(adr_o[4:2])
		3'd0:	ibuf[31: 0] <= dat_i;
		3'd1:	ibuf[63:32] <= dat_i;
		3'd2:	ibuf[95:64] <= dat_i;
		3'd3:	ibuf[127:96] <= dat_i;
		3'd4:	ibuf[159:128] <= dat_i;
		3'd5:	ibuf[191:160] <= dat_i;
		3'd6:	ibuf[223:192] <= dat_i;
		3'd7:	ibuf[255:224] <= dat_i;
		endcase
		if (adr_o[4:2]==3'b110)
			cti_o <= 3'b111;
		else if (adr_o[4:2]==3'b111) begin
			wb_nack();
			ibufadr <= segmented_pc[31:5];
			next_state(IFETCH1);
		end
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// DECODE Stage
//
// - register the operands (register file and immediate)
// - set the target register
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
DECODE:
	begin
		if (~hasImm)
			opc <= pc;
		pc <= fnIncdPC(pc);
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		case(opcode)
		`NOP:	next_state(IFETCH1);
		`IMM1:	begin immbuf <= {{32{ir[40]}},ir[40:9]}; hasImm <= `TRUE; next_state(IFETCH1); end
		`IMM2:	begin immbuf[63:32] <= ir[40:9]; hasImm <= `TRUE; next_state(IFETCH1); end
		default:	next_state(EXECUTE);
		endcase
		if (hasImm)
			imm <= immbuf;
		else begin
			casex(opcode)
			`Bcci:	imm <= {{49{ir[40]}},ir[40:32],ir[19:14]};
			`BSR,`RTS,`LxX,`SxX:
					imm <= {{52{ir[40]}},ir[39:28]};
			default:	imm <= {{43{ir[40]}},ir[40:20]};
			endcase
		end
		casex(opcode)
		`BRK,
		`ADDI,`SUBI,`ADDUI,`SUBUI,`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI,`LDI,`ANDI,`ORI,`EORI,
		`Scci,`JAL,`Lx:
			Rt <= ir[19:14];
		`RR,`LxX,`RTS:	Rt <= ir[25:20];
		default:	Rt <= 6'd0;
		endcase
		Sprt <= ir[25:20];
		if (opcode==`RR && func==`MTSEG) begin
			if (ir[25:22]==4'd15 && pc[31:24]!=8'h00)
				St <= 6'd0;
			else
				St <= ir[25:20];
		end
		else
			St <= 6'd0;
		if (opcode==`RR && func==`MFSEG)
			Sa <= ir[25:22];
		else
			Sa <= 4'd0;
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// EXECUTE Stage
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
EXECUTE:
	begin
		next_state(IFETCH1);
		hasImm <= `FALSE;
		casex(opcode)
		`RR:
			casex(func)
			`ADD:	res <= a + b;
			`ADDU:	res <= a + b;
			`SUB:	res <= a - b;
			`SUBU:	res <= a - b;
			`MUL,`MULU,
			`DIV,`DIVU,`MOD,`MODU:
					next_state(MULDIV);
			`AND:	res <= a & b;
			`OR:	res <= a | b;
			`EOR:	res <= a ^ b;
			`SLL:	res <= a << b[5:0];
			`SLLI:	res <= a << Rb;
			`SRL:	res <= a >> b[5:0];
			`SRLI:	res <= a >> Rb;
			`SRA:	res <= as >> b[5:0];
			`SRAI:	res <= as >> Rb;
			`MTSPR:
				case(Sprt)
				`VBR:	vbr <= a;
				endcase
			`MFSPR:	res <= spro;
			`MTSEG:	res <= a;
			`MFSEG:
				case(Ra[1:0])
				2'd0:	res <= sego[63:0];
				2'd1:	res <= sego[127:64];
				2'd2:	res <= sego[191:128];
				2'd3:	res <= sego[255:192];
				endcase
			`RTI:
				begin
					cpl <= cplb;
					cplb <= cplb2;
					im <= imb;
					imb <= imb2;
					pc <= a;
				end
			default:	res <= 64'd0;
			endcase
		`ADDI:	res <= a + imm;
		`ADDUI:	res <= a + imm;
		`SUBI:	res <= a - imm;
		`SUBUI:	res <= a - imm;
		`MULI,`MULUI,`DIVI,`DIVUI,`MODI,`MODUI:
			next_state(MULDIV);
		`ANDI:	res <= a & imm;
		`ORI:	res <= a | imm;
		`EORI:	res <= a ^ imm;
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Flow Control Instructions Follow
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`BRK:
			begin
				$display("*****************");
				$display("*****************");
				$display("BRK");
				$display("*****************");
				$display("*****************");
				isBRK <= `TRUE;
				brkCnt <= brkCnt + 3'd1;
				if (brkCnt > 3'd2)
					next_state(HANG);
				res <= pc;
				imb2 <= imb;
				imb <= im;
				cplb2 <= cpl;
				cplb <= cpl;
				ea <= {vbr[31:11],ir[28:20],2'b00};
				next_state(LOADSTORE1);
			end
		`Bcc,`Bcci:
			begin
				if (takeb) begin
					pc[7:0] <= ir[27:20];
					pc[31:8] <= pc[31:8] + {{20{ir[31]}},ir[31:28]};
				end
			end
		`BSR:
			begin
				res <= pc;
				pc[7:0] <= ir[27:20];
				pc[31:8] <= pc[31:8] + {{12{ir[39]}},ir[39:28]};
			end
		`RTS:
			begin
				res <= a + imm;
				pc <= b;
			end
		`JAL:
			begin
				res <= pc;
				pc <= a + imm;
			end
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Loads and Stores
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
		`SB,`SC,`SH,`SW:
			begin
				next_state(LOADSTORE1);
				ea <= a + imm;
			end
		`LBX,`LBUX,`LC,`LCUX,`LH,`LHUX,`LWX,
		`SBX,`SCX,`SHX,`SWX:
			begin
				next_state(LOADSTORE1);
				ea <= a + (b << ir[27:26]) + imm;
			end
		default:	res <= 32'd0;
		endcase
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(opcode)
		`MULUI:
			begin
				aa <= a;
				bb <= imm;
				res_sgn <= 1'b0;
				next_state(MULT1);
			end
		`MULI:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? -imm : imm;
				res_sgn <= a[63] ^ imm[63];
				next_state(MULT1);
			end
		`DIVUI,`MODUI:
			begin
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIVI,`MODI:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? -imm : imm;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ imm[63];
				next_state(DIV);
			end
		`RR:
			case(func)
			`MULU:
				begin
					aa <= a;
					bb <= b;
					res_sgn <= 1'b0;
					next_state(MULT1);
				end
			`MUL:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					res_sgn <= a[63] ^ b[63];
					next_state(MULT1);
				end
			`DIVU,`MODU:
				begin
					aa <= a;
					bb <= b;
					q <= a[62:0];
					r <= a[63];
					res_sgn <= 1'b0;
					next_state(DIV);
				end
			`DIV,`MOD:
				begin
					aa <= a[63] ? -a : a;
					bb <= b[63] ? -b : b;
					q <= pa[62:0];
					r <= pa[63];
					res_sgn <= a[63] ^ b[63];
					next_state(DIV);
				end
			default:
				state <= IFETCH1;
			endcase
		endcase
	end
// Three wait states for the multiply to take effect. These are needed at
// higher clock frequencies. The multipler is a multi-cycle path that
// requires a timing constraint.
MULT1:	state <= MULT2;
MULT2:	state <= MULT3;
MULT3:	begin
			p <= p1;
			next_state(res_sgn ? FIX_SIGN : MD_RES);
		end

DIV:
	begin
		q <= {q[62:0],~diff[63]};
		if (cnt==7'd0) begin
			next_state(res_sgn ? FIX_SIGN : MD_RES);
			if (diff[63])
				r <= r[62:0];
			else
				r <= diff[62:0];
		end
		else begin
			if (diff[63])
				r <= {r[62:0],q[63]};
			else
				r <= {diff[62:0],q[63]};
		end
		cnt <= cnt - 7'd1;
	end

FIX_SIGN:
	begin
		next_state(MD_RES);
		if (res_sgn) begin
			p <= -p;
			q <= -q;
			r <= -r;
		end
	end

MD_RES:
	begin
		if (opcode==`MULI || opcode==`MULUI || (opcode==`RR && (func==`MUL || func==`MULU)))
			res <= p[63:0];
		else if (opcode==`DIVI || opcode==`DIVUI || (opcode==`RR && (func==`DIV || func==`DIVU)))
			res <= q[63:0];
		else
			res <= r[63:0];
		next_state(IFETCH1);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Memory Stage
//
// - in kernel mode a segmented address doesn't need to be calculated so
//   memory access is one cycle faster.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

LOADSTORE1:
	begin
		Sa <= ea[63:60];
		if (kernelMode) begin
			segmented_ea <= ea;
			next_state(LOADSTORE3);
		end
		else
			next_state(LOADSTORE2);
	end
LOADSTORE2:
	begin
		if (ea > seg_limit && pe)
			bounds_violation();
		else begin
			segmented_ea <= seg_base + ea;
			next_state(LOADSTORE3);
		end
	end
LOADSTORE3:
	begin
		next_state(LOADSTORE4);
		case(opcode)
		`BRK,
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
			wb_read(segmented_ea);
		`SB,`SBX:	wb_write1(byt,segmented_ea,b);
		`SC,`SCX:	wb_write1(char,segmented_ea,b);
		`SH,`SHX:	wb_write1(half,segmented_ea,b);
		`SW,`SWX:	wb_write1(word,segmented_ea,b);
		endcase
		case(opcode)
		`LC,`LCU,`LCX,`LCUX,`SC,`SCX:
			if (segmented_ea[1:0]==2'b11)
				lock_o <= 1'b1;
		`LH,`LHU,`LHX,`LHUX,`SH,`SHX:
			if (segmented_ea[1:0]!=2'b00)
				lock_o <= 1'b1;
		`LW,`LWX,`SW,`SWX:
				lock_o <= 1'b1;
		endcase
	end
LOADSTORE4:
	if (ack_i) begin
		wb_nack();
		segmented_ea <= segmented_ea + 32'd4;
		case(opcode)
		`LB,`LBX:	
			begin
			next_state(IFETCH1);
			case(segmented_ea[1:0])
			2'd0:	res <= {{56{dat_i[7]}},dat_i[7:0]};
			2'd1:	res <= {{56{dat_i[15]}},dat_i[15:8]};
			2'd2:	res <= {{56{dat_i[23]}},dat_i[23:16]};
			2'd3:	res <= {{56{dat_i[31]}},dat_i[31:24]};
			endcase
			end
		`LBU,`LBUX:
			begin
			next_state(IFETCH1);
			case(segmented_ea[1:0])
			2'd0:	res <= dat_i[7:0];
			2'd1:	res <= dat_i[15:8];
			2'd2:	res <= dat_i[23:16];
			2'd3:	res <= dat_i[31:24];
			endcase
			end
		`LC,`LCX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= {{48{dat_i[15]}},dat_i[15:0]}; next_state(IFETCH1); end
			2'd1:	begin res <= {{48{dat_i[23]}},dat_i[23:8]}; next_state(IFETCH1); end
			2'd2:	begin res <= {{48{dat_i[31]}},dat_i[31:16]}; next_state(IFETCH1); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`LCU,`LCUX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= {{48{dat_i[15]}},dat_i[15:0]}; next_state(IFETCH1); end
			2'd1:	begin res <= {{48{dat_i[23]}},dat_i[23:8]}; next_state(IFETCH1); end
			2'd2:	begin res <= {{48{dat_i[31]}},dat_i[31:16]}; next_state(IFETCH1); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`LH,`LHX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= {{32{dat_i[31]}},dat_i[31:0]}; next_state(IFETCH1); end
			2'd1:	begin res <= dat_i[23:8]; next_state(LOADSTORE5); end
			2'd2:	begin res <= dat_i[31:16]; next_state(LOADSTORE5); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`LHU,`LW,`LHUX,`LWX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= dat_i[31:0]; next_state(IFETCH1); end
			2'd1:	begin res <= dat_i[23:8]; next_state(LOADSTORE5); end
			2'd2:	begin res <= dat_i[31:16]; next_state(LOADSTORE5); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`BRK:	begin
					pc[31:2] <= dat_i[29:2];
					pc[1:0] <= dat_i[3:2];
					cpl <= {2'b00,dat_i[31:30]};
					if (dat_i[0])
						im <= 1'b1;
					next_state(IFETCH1);
				end
		`SB,`SBX:	next_state(IFETCH1);
		`SC,`SCX:	if (segmented_ea[1:0]==2'b11)
					next_state(LOADSTORE5);
				else
					next_state(IFETCH1);
		`SH,`SHX:	if (segmented_ea[1:0]!=2'b00)
					next_state(LOADSTORE5);
				else
					next_state(IFETCH1);
		`SW,`SWX:	next_state(LOADSTORE5);
		endcase
	end
LOADSTORE5:
	begin
		next_state(LOADSTORE6);
		case(opcode)
		`LC,`LCU,`LH,`LHU,`LW,
		`LCX,`LCUX,`LHX,`LHUX,`LWX:
			wb_read(segmented_ea);
		`SC,`SCX:	wb_write2(char,segmented_ea,b);
		`SH,`SHX:	wb_write2(half,segmented_ea,b);
		`SW,`SWX:	wb_write2(word,segmented_ea,b);
		default:	next_state(IFETCH1);
		endcase
	end
LOADSTORE6:
	if (ack_i) begin
		wb_nack();
		case(opcode)
		`LC,`LCU,`LCX,`LCUX,
		`LH,`LHU,`LHX,`LHUX:
			lock_o <= 1'b0;
		`LW,`LWX,`SW,`SWX:
			if (segmented_ea[1:0]==2'b00)
				lock_o <= 1'b0;
		endcase
		segmented_ea <= segmented_ea + 32'd4;
		case(opcode)
		`LC,`LCX:	begin res[63:8] <= {{48{dat_i[7]}},dat_i[7:0]}; next_state(IFETCH1); end
		`LCU,`LCUX:	begin res[63:8] <= dat_i[7:0]; next_state(IFETCH1); end
		`LH,`LHX:
			begin
			next_state(IFETCH1);
			case(segmented_ea[1:0])
			2'd0:	;
			2'd1:	res[63:24] <= {{32{dat_i[7]}},dat_i[7:0]};
			2'd2:	res[63:16] <= {{32{dat_i[15]}},dat_i[15:0]};
			2'd3:	res[63:8] <= {{32{dat_i[23]}},dat_i[23:0]};
			endcase
			end
		`LHU,`LHUX:
			begin
			next_state(IFETCH1);
			case(segmented_ea[1:0])
			2'd0:	;
			2'd1:	res[63:24] <= dat_i[7:0];
			2'd2:	res[63:16] <= dat_i[15:0];
			2'd3:	res[63:8] <= dat_i[23:0];
			endcase
			end
		`LW,`LWX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res[63:32] <= dat_i; next_state(IFETCH1); end
			2'd1:	begin res[55:24] <= dat_i; next_state(LOADSTORE7); end
			2'd2:	begin res[47:16] <= dat_i; next_state(LOADSTORE7); end
			2'd3:	begin res[39:8] <= dat_i; next_state(LOADSTORE7); end
			endcase
			end
		`SC,`SH,`SCX,`SHX:	next_state(IFETCH1);
		`SW,`SWX:	if (segmented_ea[1:0]==2'b00)
					next_state(IFETCH1);
				else
					next_state(LOADSTORE7);
		endcase
	end
LOADSTORE7:
	begin
		next_state(LOADSTORE8);
		case(opcode)
		`LW,`LWX:	wb_read(segmented_ea);
		`SW,`SWX:	wb_write3(segmented_ea,b);
		default:	next_state(IFETCH1);
		endcase
	end
LOADSTORE8:
	if (ack_i) begin
		next_state(IFETCH1);
		lock_o <= 1'b0;
		case(opcode)
		`LW,`LWX:
			case(segmented_ea[1:0])
			2'd0:	;
			2'd1:	res[63:56] <= dat_i[7:0];
			2'd2:	res[63:48] <= dat_i[15:0];
			2'd3:	res[63:40] <= dat_i[23:0];
			endcase
		`SW,`SWX:	;
		endcase
	end
HANG:	;
endcase
end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Support tasks
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task wb_read;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {adr[31:2],2'b00};
end
endtask

task wb_write1;
input [2:0] sz;
input [31:0] adr;
input [63:0] dat;
begin
	case(sz)
	byt:
		begin
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		dat_o <= {4{dat[7:0]}};
		end
	char:
		begin
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b0011; dat_o <= {2{dat[15:0]}}; end
		2'd1:	begin sel_o <= 4'b0110; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		2'd2:	begin sel_o <= 4'b1100; dat_o <= {2{dat[15:0]}}; end
		2'd3:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
		end
	half,word:
		begin
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b1111; dat_o <= dat[31:0]; end
		2'd1:	begin sel_o <= 4'b1110; dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b1100; dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
		end
	endcase
	adr_o <= {adr[31:2],2'b00};
end
endtask

task wb_write2;
input [2:0] sz;
input [31:0] adr;
input [63:0] dat;
begin
	case(sz)
	char:
		begin
		case(adr[1:0])
		2'd3:	begin sel_o <= 4'b0001; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
		end
	half:
		begin
		case(adr[1:0])
		2'd0:	;
		2'd1:	begin sel_o <= 4'b0001; dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b0011; dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b0111; dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
		end
	word:
		begin
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b1111; dat_o <= dat[63:32]; end
		2'd1:	begin sel_o <= 4'b1111; dat_o <= dat[55:24]; end
		2'd2:	begin sel_o <= 4'b1111; dat_o <= dat[47:16]; end
		2'd3:	begin sel_o <= 4'b1111; dat_o <= dat[39:8]; end
		endcase
		end
	endcase
	adr_o <= {adr[31:2],2'b00};
end
endtask

// Write cycle #3 - unaligned words only
task wb_write3;
input [31:0] adr;
input [63:0] dat;
begin
	case(adr[1:0])
	2'd0:	;
	2'd1:	begin sel_o <= 4'b0001; dat_o <= dat[63:56]; end
	2'd2:	begin sel_o <= 4'b0011; dat_o <= dat[63:48]; end
	2'd3:	begin sel_o <= 4'b0111; dat_o <= dat[63:40]; end
	endcase
	adr_o <= {adr[31:2],2'b00};
end
endtask

task wb_burst;
input [5:0] bl;
input [31:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	bl_o <= bl;
	wb_read(adr);
end
endtask

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	sel_o <= 4'h0;
	we_o <= 1'b0;
	adr_o <= 32'h0;
	dat_o <= 32'h0;
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[19:14] <= 6'd61;
	ir[28:20] <= 9'd500;
	fault_pc <= opc;
	fault_cs <= cs_base;
	next_state(DECODE);
end
endtask


endmodule

module segregfile(clk, wa, we0, we1, we2, we3, ra, i, o, cso);
input clk;
input [3:0] wa;
input we0,we1,we2,we3;
input [3:0] ra;
input [63:0] i;
output reg [255:0] o;
output reg [255:0] cso;

reg [63:0] sregsA [15:0];
reg [63:0] sregsB [15:0];
reg [63:0] sregsC [15:0];
reg [63:0] sregsD [15:0];
always @(posedge clk)
	if (we0) sregsA[wa] <= i;
always @(posedge clk)
	if (we1) sregsB[wa] <= i;
always @(posedge clk)
	if (we2) sregsC[wa] <= i;
always @(posedge clk)
	if (we3) sregsD[wa] <= i;

always @(ra)
	o <= {sregsD[ra],sregsC[ra],sregsB[ra],sregsA[ra]};
always @*
	cso <= {sregsD[15],sregsC[15],sregsB[15],sregsA[15]};

endmodule

