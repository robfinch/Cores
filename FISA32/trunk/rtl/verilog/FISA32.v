`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2014  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// FISA32.v
//  - 32 bit CPU
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

`define BRK		6'h00
`define RR		6'h02
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
`define MTSPR		6'h1E
`define MFSPR		6'h1F
`define SLL			6'h20
`define ROL			6'h21
`define SRL			6'h22
`define ROR			6'h23
`define SRA			6'h24
`define SEQ			6'h26
`define SNE			6'h27
`define SLT			6'd28
`define SGE			6'h29
`define SLE			6'h2A
`define SGT			6'h2B
`define SLTU		6'd2C
`define SGEU		6'h2D
`define SLEU		6'h2E
`define SGTU		6'h2F
`define SLLI		6'h30
`define ROLI		6'h31
`define SRLI		6'h32
`define RORI		6'h33
`define SRAI		6'h34
`define PUSH		6'h38
`define POP			6'h39
`define JSP			6'h3C
`define RTS			6'h3E
`define RTI			6'h3F
`define ADDI	6'h04
`define SUBI	6'h05
`define MULI	6'h07
`define DIVI	6'h08
`define MODI	6'h09
`define ANDI	6'h0C
`define ORI		6'h0D
`define EORI	6'h0E

`define BEQI	6'h10
`define BNEI	6'h11
`define Bcc		6'h12
`define BEQ			3'h0
`define BNE			3'h1
`define BLT			3'h4
`define BGE			3'h5
`define BLE			3'h6
`define BGT			3'h7
`define Bccu	6'h13
`define BLTU		3'h4
`define BGEU		3'h5
`define BLEU		3'h6
`define BGTU		3'h7
`define JMP		6'h14
`define JSR		6'h15
`define BLTI	6'h18
`define BGEI	6'h19
`define BLEI	6'h1A
`define BGTI	6'h1B
`define BLTUI	6'h1C
`define BGEUI	6'h1D
`define BLEUI	6'h1E
`define BGTUI	6'h1F

`define LB		6'h20
`define LBU		6'h21
`define LH		6'h22
`define LHU		6'h23
`define LW		6'h24
`define SEQI	6'h26
`define SNEI	6'h27
`define LBX		6'h28
`define LBUX	6'h29
`define LHX		6'h2A
`define LHUX	6'h2B
`define LWX		6'h2C
`define LEAX	6'h2D

`define SLTI	6'h30
`define SGEI	6'h31
`define SLEI	6'h32
`define SGTI	6'h33
`define SLTUI	6'h34
`define SGEUI	6'h35
`define SLEUI	6'h36
`define SGTUI	6'h37

`define SBX		6'h38
`define SHX		6'h39
`define SWX		6'h3A
`define SB		6'h3B
`define SH		6'h3C
`define SW		6'h3D
`define IMM		6'h3E
`define NOP		6'h3F

`define TICK	6'd0
`define VBR		6'd1

module FISA32(rst_i, clk_i, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, cyc_o, stb_o, lock_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
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
output reg [27:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

parameter RESET1 = 6'd0;
parameter RESET2 = 6'd1;
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
parameter CS_DELAY = 6'd62;
parameter HANG = 6'd63;

parameter byt = 3'd0;
parameter ubyt = 3'd1;
parameter half = 3'd4;
parameter uhalf = 3'd5;
parameter word = 3'd6;

wire clk = clk_i;
reg [5:0] state;
reg [9:0] cs,ds,ss,es,fs,gs;
reg [22:0] pc,opc;
reg [31:0] vbr;
reg [31:0] fault_cspc;
reg [255:0] ibuf;
reg [27:5] ibufadr;
reg [31:0] ir;
reg [31:0] insncnt;
reg [31:0] tick;
wire [5:0] opcode = ir[5:0];
wire [5:0] func = ir[31:26];
wire [2:0] Op3 = ir[18:16];
reg gie;					// global interrupt enable
reg hwi;					// hardware interrupt occurring
reg im,imb,imb2;			// interrupt mask and backup
reg nmi_edge,nmi1;
reg isBRK;
reg hasJSP;
reg [2:0] brkCnt;
reg [31:0] regfile [31:0];
reg [31:0] sp;
wire [4:0] Ra = ir[10:6];
wire [4:0] Rb = ir[15:11];
wire [4:0] Rc = ir[20:16];
reg [4:0] Rt,Sprt;
reg [2:0] Sa;
reg [2:0] St;
reg [31:0] rfoa,rfob,rfoc;
reg [9:0] srfo;
reg [9:0] jspbuf;
always @(Ra,pc,sp)
case(Ra)
5'd00:	rfoa <= 32'd0;
5'd30:	rfoa <= sp;
5'd31:	rfoa <= pc;
default:	rfoa <= regfile[Ra];
endcase
always @(Rb,pc,sp)
case(Rb)
5'd00:	rfob <= 64'd0;
5'd30:	rfob <= sp;
5'd31:	rfob <= pc;
default:	rfob <= regfile[Rb];
endcase
always @(Rc,pc,sp)
case(Rc)
5'd00:	rfoc <= 64'd0;
5'd30:	rfoc <= sp;
5'd31:	rfoc <= pc;
default:	rfoc <= regfile[Rc];
endcase
always @(Sa,ds,es,fs,gs,ss,cs)
case(Sa)
3'd0:	srfo <= ds;
3'd1:	srfo <= es;
3'd2:	srfo <= fs;
3'd3:	srfo <= gs;
3'd6:	srfo <= ss;
3'd7:	srfo <= cs;
default:	srfo <= 10'd0;
endcase
reg pe;				// protected mode enabled
reg [31:0] a,b,c,imm,immbuf;
wire signed [31:0] as = a;
reg [31:0] res,ea;
reg [31:0] segmented_ea;
reg [31:0] spro;
reg hasImm;

// Shifts
wire isShifti = opcode==`RR && (func==`SLLI || func==`ROLI || func==`SRLI || func==`RORI || func==`SRAI);
wire [4:0] shamt = isShifti ? Rb[4:0] : b[4:0];
wire [63:0] shlo = {32'd0,a} << shamt;
wire [63:0] shro = {a,32'd0} >> shamt;
wire signed [31:0] asro = as >> shamt;

reg [5:0] cnt;
reg [31:0] aa,bb,q,r;
reg res_sgn;
wire [31:0] pa = a[31] ? -a : a;
wire [63:0] p1 = aa * bb;
reg [63:0] p;
wire [31:0] diff = r - bb;

wire [15:0] cs_base;
wire [15:0] cs_limit;
wire [15:0] base;
wire [15:0] limit;
reg [27:0] adr;

wire [27:0] segmented_pc = {cs_base,11'h000} + pc;

descTable u3
(	
	.clk(clk),
	.wa(adr_o[11:2]),
	.we(cyc_o & stb_o & we_o && (adr_o[27:11]==17'b0000_0000_0000_0000_0)),
	.i(dat_o),
	.selector(srfo),
	.cs_selector(cs),
	.base(base),
	.limit(limit),
	.cs_base(cs_base),
	.cs_limit(cs_limit)
);

reg takeb;
wire eqi = a==imm;
wire lti = $signed(a) < $signed(imm);
wire ltui = a < imm;
wire eq = a==b;
wire lt = $signed(a) < $signed(b);
wire ltu = a < b;

always @(opcode,eqi,lti,ltui,Op3,eq,lt,ltu)
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
`Bcc:
	case(Op3)
	`BEQ:	takeb <= eq;
	`BNE:	takeb <= !eq;
	`BLT:	takeb <= lt;
	`BGE:	takeb <= !lt;
	`BLE:	takeb <= lt|eq;
	`BGT:	takeb <= !(lt|eq);
	default:	takeb <= 1'b0;
	endcase
`Bccu:
	case(Op3)
	`BLTU:	takeb <= ltu;
	`BLEU:	takeb <= ltu|eq;
	`BGTU:	takeb <= !(ltu|eq);
	`BGEU:	takeb <= !ltu;
	default:	takeb <= 1'b0;
	endcase
default:	takeb <= 1'b0;
endcase

always @*
casex(Ra)
5'd0:	spro <= tick;
`VBR:	spro <= vbr;
5'd8:	spro <= fault_cspc;
5'b11xxx:	spro <= srfo;
default:	spro <= 32'd0;
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
	pe <= 1'b0;
	St <= 3'd7;
	cs <= 10'd0;
	res <= 64'd0;	// used to load segment registers
	adr <= 28'h0;
	next_state(RESET1);
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

RESET1:
	begin
		// limit to max, base to zero (flat addressing)
		wb_write1(word,adr,32'hFFFFFFFF);
		next_state(RESET2);
	end
RESET2:
	if (ack_i) begin
		wb_nack();
		adr <= adr + 28'd4;
		if (adr[11:2]==10'h3FF)
			next_state(IFETCH1);
		else
			next_state(RESET1);
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
		if (Rt==5'd30) begin
			sp <= res;
			gie <= `TRUE;
		end
		case(St)
		3'd0:	ds <= res[9:0];
		3'd1:	es <= res[9:0];
		3'd2:	fs <= res[9:0];
		3'd3:	gs <= res[9:0];
		3'd6:	ss <= res[9:0];
		3'd7:	;
		endcase
		if (nmi_edge & gie & ~hasImm & ~hasJSP) begin
			hwi <= `TRUE;
			ir[7:0] <= `BRK;
			ir[16:8] <= 9'd510;
			nmi_edge <= 1'b0;
		end
		else if (irq_i & gie & ~im & ~hasImm & ~hasJSP) begin
			hwi <= `TRUE;
			ir[7:0] <= `BRK;
			ir[16:8] <= vect_i;
		end
		else if (ibufadr==segmented_pc[27:5]) begin
			case(pc[4:0])
			5'h00:	ir <= ibuf[31:0];
			5'h04:	ir <= ibuf[63:32];
			5'h08:	ir <= ibuf[95:64];
			5'h0C:	ir <= ibuf[127:96];
			5'h10:	ir <= ibuf[159:128];
			5'h14:	ir <= ibuf[191:160];
			5'h18:	ir <= ibuf[223:192];
			5'h1C:	ir <= ibuf[255:224];
			default:	;//ir <= `UNALIGNED_INSN;
			endcase
		end
		else begin
			wb_burst(6'd7,{segmented_pc[27:5],5'h0});
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
			ibufadr <= segmented_pc[27:5];
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
		if (~hasImm & ~hasJSP)
			opc <= pc;
		pc <= pc + 23'd4;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;
		case(opcode)
		`NOP:	next_state(IFETCH1);
		`IMM:	begin immbuf <= ir[31:6]; hasImm <= `TRUE; next_state(IFETCH1); end
		default:	next_state(EXECUTE);
		endcase

		casex(opcode)
		`BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI:
			if (hasImm)
				imm <= {immbuf[23:0],ir[21:14]};
			else
				imm <= {{24{ir[21]}},ir[21:14]};
		`ADDI,`SUBI,`MULI,`DIVI,`MODI,`ANDI,`ORI,`EORI,
		`SEQI,`SNEI,`SLTI,`SGEI,`SLEI,`SGTI,`SLTUI,`SGEUI,`SLEUI,`SGTUI:
			if (hasImm)
				imm <= {immbuf[15:0],ir[31:16]};
			else
				imm <= {{16{ir[31]}},ir[31:16]};
		`LB,`LBU,`LH,`LHU,`LW,
		`SB,`SH,`SW:
			if (hasImm)
				imm <= {immbuf[18:0],ir[31:19]};
			else
				imm <= {{19{ir[31]}},ir[31:19]};
		`LBX,`LBUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SHX,`SWX:
			if (hasImm)
				imm <= {immbuf[25:0],ir[31:26]};
			else
				imm <= {{26{ir[31]}},ir[31:26]};
		default:	imm <= 32'd0;
		endcase

		casex(opcode)
		`ADDI,`SUBI,`MULI,`DIVI,`MODI,`ANDI,`ORI,`EORI,
		`SEQI,`SNEI,`SLTI,`SGEI,`SLEI,`SGTI,`SLTUI,`SGEUI,`SLEUI,`SGTUI,
		`LB,`LBU,`LH,`LHU,`LW:
			Rt <= ir[15:11];
		`RR: 	if (func==`MTSPR) begin
					Sprt <= ir[20:16];
					Rt <= 5'd0;
				end
				else
					Rt <= ir[20:16];
		`LBX,`LBUX,`LHX,`LHUX,`LWX,`LEAX:
			Rt <= ir[20:16];
		default:	Rt <= 5'd0;
		endcase
		if (opcode==`RR && func==`MTSPR && ir[20:19]==2'b11)
			St <= ir[18:16];
		else
			St <= 3'd7;
		if (opcode==`RR && func==`MFSPR)
			Sa <= Ra[2:0];
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
		hasJSP <= `FALSE;
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
			`SLL:	res <= shlo[31:0];
			`SLLI:	res <= shlo[31:0];
			`SRL:	res <= shro[63:32];
			`SRLI:	res <= shro[63:32];
			`SRA:	res <= asro;
			`SRAI:	res <= asro;
			`ROL:	res <= shlo[31:0]|shlo[63:32];
			`ROLI:	res <= shlo[31:0]|shlo[63:32];
			`ROR:	res <= shro[63:32]|shro[31:0];
			`RORI:	res <= shro[63:32]|shro[31:0];
			`MTSPR:
				casex(Sprt)
				`VBR:	vbr <= a;
				5'b11xxx:	
					begin
						res <= a;
						St <= Sprt[2:0];
					end
				endcase
			`MFSPR:	res <= spro;
			`JSP:
				begin
					hasJSP <= `TRUE;
					jspbuf <= a | imm;
				end
			`RTS:
				begin
					Sa <= 3'd6;	// select stack selector
					ea <= sp;
					sp <= sp + 32'd4;
					next_state(LOADSTORE1);
				end
			`RTI:
				begin
					im <= imb;
					imb <= imb2;
					Sa <= 3'd6;	// select stack selector
					ea <= sp;
					sp <= sp + 32'd4;
					next_state(LOADSTORE1);
				end
			default:	res <= 64'd0;
			endcase
		`ADDI:	res <= a + imm;
		`SUBI:	res <= a - imm;
		`MULI,`DIVI,`MODI:
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
				im <= 1'b1;
				ea <= {vbr[31:11],ir[28:20],2'b00};
				next_state(LOADSTORE1);
			end
		`Bcc,`Bccu,
		`BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI:
			begin
				if (takeb)
					pc <= pc + {{8{ir[31]}},ir[31:19],2'b00};
			end
		`JSR:
			begin
				Sa <= 3'd6;
				ea <= sp - 32'd4;
				b <= {cs,pc[22:2]};
				pc <= a + imm;
				if (hasJSP)
					cs <= jspbuf;
				next_state(LOADSTORE1);
			end
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		// Loads and Stores
		// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`LB,`LBU,`LH,`LHU,`LW,
		`SB,`SH,`SW:
			begin
				next_state(LOADSTORE1);
				ea <= a + imm;
				Sa <= ir[18:16];
			end
		`LBX,`LBUX,`LH,`LHUX,`LWX,`LEAX,
		`SBX,`SHX,`SWX:
			begin
				next_state(LOADSTORE1);
				ea <= a + (b << ir[27:26]) + imm;
				Sa <= ir[25:23];
			end
		default:	res <= 32'd0;
		endcase
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 6'd32;
		case(opcode)
//		`MULUI:
//			begin
//				aa <= a;
//				bb <= imm;
//				res_sgn <= 1'b0;
//				next_state(MULT1);
//			end
		`MULI:
			begin
				aa <= a[31] ? -a : a;
				bb <= imm[31] ? -imm : imm;
				res_sgn <= a[31] ^ imm[31];
				next_state(MULT1);
			end
//		`DIVUI,`MODUI:
//			begin
//				aa <= a;
//				bb <= imm;
//				q <= a[62:0];
//				r <= a[63];
//				res_sgn <= 1'b0;
//				next_state(DIV);
//			end
		`DIVI,`MODI:
			begin
				aa <= a[31] ? -a : a;
				bb <= imm[31] ? -imm : imm;
				q <= pa[30:0];
				r <= pa[31];
				res_sgn <= a[31] ^ imm[31];
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
					aa <= a[31] ? -a : a;
					bb <= b[31] ? -b : b;
					res_sgn <= a[31] ^ b[31];
					next_state(MULT1);
				end
			`DIVU,`MODU:
				begin
					aa <= a;
					bb <= b;
					q <= a[30:0];
					r <= a[31];
					res_sgn <= 1'b0;
					next_state(DIV);
				end
			`DIV,`MOD:
				begin
					aa <= a[31] ? -a : a;
					bb <= b[31] ? -b : b;
					q <= pa[30:0];
					r <= pa[31];
					res_sgn <= a[31] ^ b[31];
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
		q <= {q[30:0],~diff[31]};
		if (cnt==6'd0) begin
			next_state(res_sgn ? FIX_SIGN : MD_RES);
			if (diff[31])
				r <= r[30:0];
			else
				r <= diff[30:0];
		end
		else begin
			if (diff[31])
				r <= {r[30:0],q[31]};
			else
				r <= {diff[30:0],q[31]};
		end
		cnt <= cnt - 6'd1;
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
		if (opcode==`MULI || (opcode==`RR && (func==`MUL || func==`MULU)))
			res <= p[31:0];
		else if (opcode==`DIVI || (opcode==`RR && (func==`DIV || func==`DIVU)))
			res <= q[31:0];
		else
			res <= r[31:0];
		next_state(IFETCH1);
	end

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Memory Stage
//
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

// This state needed to allow the synchronous RAM a clock cycle to adapt to
// the new selector setting.
LOADSTORE1:
	begin
		if (opcode==`LEAX) begin
			res <= ea;
			next_state(IFETCH1);
		end
		else if (ea > limit && pe)
			bounds_violation();
		else
			next_state(LOADSTORE2);
	end
LOADSTORE2:
	begin
		segmented_ea <= {base,11'h000} + ea;
		next_state(LOADSTORE3);
	end
LOADSTORE3:
	begin
		next_state(LOADSTORE4);
		case(opcode)
		`RR:
			case(func)
			`RTS,`RTI:	wb_read(segmented_ea);
			endcase
		`BRK,
		`LB,`LBU,`LH,`LHU,`LW,
		`LBX,`LBUX,`LHX,`LHUX,`LWX:
			wb_read(segmented_ea);
		`SB,`SBX:	wb_write1(byt,segmented_ea,b);
		`SH,`SHX:	wb_write1(half,segmented_ea,b);
		`SW,`SWX,`JSR:	wb_write1(word,segmented_ea,b);
		endcase
		case(opcode)
		`LH,`LHU,`LHX,`LHUX,`SH,`SHX:
			if (segmented_ea[1:0]==2'b11)
				lock_o <= 1'b1;
		`LW,`LWX,`SW,`SWX:
			if (segmented_ea[1:0]!=2'b00)
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
			2'd0:	res <= {{24{dat_i[7]}},dat_i[7:0]};
			2'd1:	res <= {{24{dat_i[15]}},dat_i[15:8]};
			2'd2:	res <= {{24{dat_i[23]}},dat_i[23:16]};
			2'd3:	res <= {{24{dat_i[31]}},dat_i[31:24]};
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
		`LH,`LHX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= {{16{dat_i[15]}},dat_i[15:0]}; next_state(IFETCH1); end
			2'd1:	begin res <= {{16{dat_i[23]}},dat_i[23:8]}; next_state(IFETCH1); end
			2'd2:	begin res <= {{16{dat_i[31]}},dat_i[31:16]}; next_state(IFETCH1); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`LHU,`LHUX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= dat_i[15:0]; next_state(IFETCH1); end
			2'd1:	begin res <= dat_i[23:8]; next_state(IFETCH1); end
			2'd2:	begin res <= dat_i[31:16]; next_state(IFETCH1); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`LW,`LWX:
			begin
			case(segmented_ea[1:0])
			2'd0:	begin res <= dat_i[31:0]; next_state(IFETCH1); end
			2'd1:	begin res <= dat_i[23:8]; next_state(LOADSTORE5); end
			2'd2:	begin res <= dat_i[31:16]; next_state(LOADSTORE5); end
			2'd3:	begin res <= dat_i[31:24]; next_state(LOADSTORE5); end
			endcase
			end
		`RR:
			case(func)
			`RTS,`RTI:
				begin
					pc[22:2] <= dat_i[20:0];
					pc[1:0] <= 2'b00;
					cs <= dat_i[30:21];
					next_state(CS_DELAY);
				end
			endcase
		`BRK:	begin
					pc[22:2] <= dat_i[20:0];
					pc[1:0] <= 2'b00;
					cs <= dat_i[30:21];
					next_state(CS_DELAY);
				end
		`SB,`SBX:	next_state(IFETCH1);
		`SH,`SHX:	if (segmented_ea[1:0]==2'b11)
					next_state(LOADSTORE5);
				else
					next_state(IFETCH1);
		`SW,`SWX:	if (segmented_ea[1:0]!=2'b00)
					next_state(LOADSTORE5);
				else
					next_state(IFETCH1);
		endcase
	end
LOADSTORE5:
	begin
		next_state(LOADSTORE6);
		case(opcode)
		`LH,`LHU,`LW,
		`LHX,`LHUX,`LWX:
			wb_read(segmented_ea);
		`SH,`SHX:	wb_write2(half,segmented_ea,b);
		`SW,`SWX:	wb_write2(word,segmented_ea,b);
		default:	next_state(IFETCH1);
		endcase
	end
LOADSTORE6:
	if (ack_i) begin
		next_state(IFETCH1);
		wb_nack();
		lock_o <= 1'b0;
		case(opcode)
		`LH,`LHX:	res[31:8] <= {{16{dat_i[7]}},dat_i[7:0]};
		`LHU,`LHUX:	res[31:8] <= dat_i[7:0];
		`LW,`LWX:
			begin
			case(segmented_ea[1:0])
			2'd0:	;
			2'd1:	res[31:24] <= dat_i[7:0];
			2'd2:	res[31:16] <= dat_i[15:0];
			2'd3:	res[31:8] <= dat_i[23:0];
			endcase
			end
		endcase
	end
HANG:	;
CS_DELAY:
	next_state(IFETCH1);
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
input [27:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= {adr[27:2],2'b00};
end
endtask

task wb_write1;
input [2:0] sz;
input [27:0] adr;
input [31:0] dat;
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
	half:
		begin
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b0011; dat_o <= {2{dat[15:0]}}; end
		2'd1:	begin sel_o <= 4'b0110; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		2'd2:	begin sel_o <= 4'b1100; dat_o <= {2{dat[15:0]}}; end
		2'd3:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
		end
	word:
		begin
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b1111; dat_o <= dat[31:0]; end
		2'd1:	begin sel_o <= 4'b1110; dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b1100; dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
		end
	endcase
	adr_o <= {adr[27:2],2'b00};
end
endtask

task wb_write2;
input [2:0] sz;
input [27:0] adr;
input [31:0] dat;
begin
	case(sz)
	half:
		begin
		case(adr[1:0])
		2'd3:	begin sel_o <= 4'b0001; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
		end
	word:
		begin
		case(adr[1:0])
		2'd0:	;
		2'd1:	begin sel_o <= 4'b0001; dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b0011; dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b0111; dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
		end
	endcase
	adr_o <= {adr[27:2],2'b00};
end
endtask

task wb_burst;
input [5:0] bl;
input [27:0] adr;
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
	adr_o <= 28'h0;
	dat_o <= 32'h0;
end
endtask

task bounds_violation;
begin
	hwi <= `TRUE;
	ir[7:0] <= `BRK;
	ir[16:8] <= 9'd500;
	fault_cspc <= {cs,opc[22:2]};
	next_state(DECODE);
end
endtask


endmodule

module descTable(clk, wa, we, i, selector, cs_selector, base, limit, cs_base, cs_limit);
input clk;
input [9:0] wa;
input we;
input [31:0] i;
input [9:0] selector;
input [9:0] cs_selector;
output [15:0] base;
output [15:0] limit;
output [15:0] cs_base;
output [15:0] cs_limit;

reg [15:0] bases [1023:0];
reg [15:0] limits [1023:0];

reg [9:0] rra;
reg [9:0] rcsa;
always @(posedge clk)
	if (we) begin
		bases[wa] <= i[15:0];
		limits[wa] <= i[31:16];
	end

always @(posedge clk)
	rra <= selector;
always @(posedge clk)
	rcsa <= cs_selector;
	
assign base = bases [rra];
assign limit = limits [rra];
assign cs_base = bases[rcsa];
assign cs_limit = limits[rcsa];

endmodule

