// ============================================================================
// FISA64.v
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
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
// 106MHz without multiply (include as a multi-cycle path)                                                                          
// ============================================================================
//
`define TRUE	1'b1
`define FALSE	1'b0

`define RR		7'h02
`define BTFLD	7'h03
`define	BFSET		3'd0
`define BFCLR		3'd1
`define BFCHG		3'd2
`define BFINS		3'd3
`define BFINSI		3'd4
`define BFEXT		3'd5
`define BFEXTU		3'd6
`define NAND		7'h00
`define NOR			7'h01
`define ENOR		7'h02
`define ADD		7'h04
`define SUB		7'h05
`define CMP		7'h06
`define MUL		7'h07
`define DIV		7'h08
`define MOD		7'h09
`define LDI		7'h0A
`define NOT			7'h0A
`define MOV			7'h0B
`define AND		7'h0C
`define OR		7'h0D
`define EOR		7'h0E
`define SXB			7'h10
`define SXC			7'h11
`define SXH			7'h12
`define ADDU	7'h14
`define SUBU	7'h15
`define CMPU	7'h16
`define MULU	7'h17
`define DIVU	7'h18
`define MODU	7'h19
`define MTSPR		7'h1E
`define MFSPR		7'h1F
`define SEQ		7'h20
`define SNE		7'h21
`define MYST	7'h24
`define SGT		7'h28
`define SLE		7'h29
`define SGE		7'h2A
`define SLT		7'h2B
`define SHI		7'h2C
`define SLS		7'h2D
`define SHS		7'h2E
`define SLO		7'h2F
`define RTL		7'h37
`define BRK		7'h38
`define BSR		7'h39
`define BRA		7'h3A
`define RTS		7'h3B
`define JAL		7'h3C
`define Bcc		7'h3D
`define BEQ			3'h0
`define BNE			3'h1
`define BGT			3'h2
`define BGE			3'h3
`define BLT			3'h4
`define BLE			3'h5
`define JALI	7'h3E
`define NOP		7'h3F
`define SLL			7'h30
`define SRL			7'h31
`define ROL			7'h32
`define ROR			7'h33
`define SRA			7'h34
`define PCTRL		7'h37
`define CLI				5'd0
`define SEI				5'd1
`define STP				5'd2
`define EIC				5'd4
`define DIC				5'd5
`define RTD				5'd29
`define RTE				5'd30
`define RTI				5'd31
`define SLLI		7'h38
`define SRLI		7'h39
`define ROLI		7'h3A
`define RORI		7'h3B
`define SRAI		7'h3C
`define FENCE		7'h40
`define LB		7'h40
`define LBU		7'h41
`define LC		7'h42
`define LCU		7'h43
`define LH		7'h44
`define LHU		7'h45
`define LW		7'h46
`define LBX		7'h48
`define LBUX	7'h49
`define LCX		7'h4A
`define LCUX	7'h4B
`define LHX		7'h4C
`define LHUX	7'h4D
`define LWX		7'h4E
`define LEAX	7'h4F
`define POP		7'h57
`define SUI		7'h5F
`define SB		7'h60
`define SC		7'h61
`define SH		7'h62
`define SW		7'h63
`define INC		7'h64
`define PEA		7'h65
`define PMW		7'h66
`define PUSH	7'h67
`define SBX		7'h68
`define SCX		7'h69
`define SHX		7'h6A
`define SWX		7'h6B
`define CAS		7'h6C

`define IMM		7'h7C

`define CR0			8'd00
`define CR3			8'd03
`define TICK		8'd04
`define CLK			8'd06
`define DBPC		8'd07
`define IPC			8'd08
`define EPC			8'd09
`define VBR			8'd10
`define MULH		8'd14
`define EA			8'd40
`define TAGS		8'd41
`define LOTGRP		8'd42
`define CASREG		8'd44
`define MYSTREG		8'd45
`define DBAD0		8'd50
`define DBAD1		8'd51
`define DBAD2		8'd52
`define DBAD3		8'd53
`define DBCTRL		8'd54
`define DBSTAT		8'd55

`define BRK_NMI	{1'b1,5'd0,9'd510,10'd0,`BRK}
`define BRK_IRQ	{1'b1,5'd0,vect_i,10'd0,`BRK}
`define BRK_EXF	{6'd0,9'd497,10'd0,`BRK}
`define BRK_IBPT	{2'b01,4'd0,9'd496,10'd0,`BRK}
`define BRK_SSM	{2'b01,4'd0,9'd495,10'd0,`BRK}
`define BRK_IBE	{1'b1,5'd0,9'd509,10'd0,`BRK}

module FISA64(rst_i, clk_i, clk_o, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o,
	cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o);
parameter AMSB = 31;		// most significant address bit
input rst_i;
input clk_i;
output clk_o;				// gated clock output
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
input err_i;
output reg we_o;
output reg [7:0] sel_o;
output reg [AMSB:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter RESET = 6'd1;
parameter IFETCH1 = 6'd2;
parameter IFETCH2 = 6'd3;
parameter DECODE = 6'd4;
parameter EXECUTE = 6'd5;
parameter LOAD0 = 6'd7;
parameter LOAD1 = 6'd8;
parameter LOAD2 = 6'd9;
parameter LOAD3 = 6'd10;
parameter LOAD4 = 6'd11;
parameter LOAD5 = 6'd12;
parameter INC = 6'd16;
parameter STORE1 = 6'd17;
parameter STORE2 = 6'd18;
parameter STORE3 = 6'd19;
parameter STORE4 = 6'd20;
parameter STORE5 = 6'd21;
parameter LOAD_ICACHE = 6'd22;
parameter LOAD_ICACHE2 = 6'd23;
parameter LOAD_ICACHE3 = 6'd24;
parameter LOAD_ICACHE4 = 6'd25;
parameter RUN = 6'd26;
parameter PEA = 6'd27;
parameter PMW = 6'd28;
parameter CAS = 6'd29;
parameter MULDIV = 6'd32;
parameter MULT1 = 6'd33;
parameter MULT2 = 6'd34;
parameter MULT3 = 6'd35;
parameter DIV = 6'd36;
parameter FIX_SIGN = 6'd37;
parameter MD_RES = 6'd38;
parameter byt = 2'd0;
parameter half = 2'd1;
parameter char = 2'd2;
parameter word = 2'd3;

wire clk;
reg [5:0] state;
reg [63:0] tick;			// tick counter
reg [AMSB:0] vbr;			// vector base register
reg [63:0] casreg;			// compare-and-swap compare register
reg [6:0] mystreg;
reg [49:0] clk_throttle_new;
reg [63:0] dbctrl,dbstat;	// debug control, debug status
reg [AMSB:0] dbad0,dbad1,dbad2,dbad3;	// debug address
wire ssm = dbctrl[63];		// single step mode
reg km;						// kernel mode
reg [7:0] kmb;				// backup kernel mode flag
reg [63:0] cr0;
wire pe = cr0[0];			// protected mode enabled
wire bpe = cr0[32];			// branch predictor enable
wire ice = cr0[30];			// instruction cache enable
reg im;						// interrupt mask
reg [2:0] imcd;				// interrupt enable count down
reg [AMSB:0] pc,dpc,xpc,wpc;
reg [AMSB:0] epc,ipc,dbpc;	// exception, interrupt PC's, debug PC
reg gie;					// global interrupt enable
reg StatusHWI;
reg [AMSB:0] ibufadr;
reg [31:0] ibuf;
wire ibufhit = pc[AMSB:2]==ibufadr[AMSB:2];
reg [63:0] regfile [31:0];
reg [63:0] sp;
reg [4:0] regSP;
reg [63:0] sp_inc;
reg [31:0] ir,xir,mir,wir;
wire [31:0] iir = ice ? insn : ibuf;
wire [6:0] iopcode = iir[6:0];
wire [6:0] opcode = ir[6:0];
wire [6:0] ifunct = iir[31:25];
wire [6:0] funct = ir[31:25];
reg [6:0] xfunct,mfunct,mdfunct,x1funct;
reg [6:0] xopcode,mopcode,wopcode,mdopcode,x1opcode;
wire [4:0] Ra = ir[11:7];
wire [4:0] Rb = ir[21:17];
wire [4:0] Rc = ir[16:12];
reg [4:0] xRt,mRt,wRt,tRt,uRt;
reg xRt2,wRt2,tRt2;
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] res,res2,ea,xres,mres,wres,lres,md_res,wres2,tres,ures;
reg mc_done;
always @*
case(Ra)
5'd0:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
tRt:	rfoa <= tres;
uRt:	rfoa <= ures;
5'd30:	if (xRt2)
			rfoa <= res2;
		else if (wRt2)
			rfoa <= wres2;
		else
			rfoa <= sp;
default:	rfoa <= regfile[Ra];
endcase
always @*
case(Rb)
5'd0:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
tRt:	rfob <= tres;
uRt:	rfob <= ures;
5'd30:	if (xRt2)
			rfob <= res2;
		else if (wRt2)
			rfob <= wres2;
		else
			rfob <= sp;
default:	rfob <= regfile[Rb];
endcase
always @*
case(Rc)
5'd0:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
tRt:	rfoc <= tres;
uRt:	rfoc <= ures;
5'd30:	if (xRt2)
			rfoc <= res2;
		else if (wRt2)
			rfoc <= wres2;
		else
			rfoc <= sp;
default:	rfoc <= regfile[Rc];
endcase
reg [63:0] a,b,c,imm,xb;
wire [63:0] pa = a[63] ? -a : a;
reg [63:0] aa,bb;
reg [63:0] q,r;
reg [127:0] p;
wire [127:0] p1 = aa * bb;
wire [63:0] diff = r - bb;
reg [6:0] cnt;
reg res_sgn;
reg [1:0] ld_size, st_size;
reg [31:0] insncnt;

// Detect multi-cycle operation.
function fnIsMC;
input [6:0] opcode;
input [6:0] funct;
case(opcode)
`RR:
	case(funct)
	`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:	fnIsMC = TRUE;
	default:	fnIsMC = FALSE;
	endcase
`BRK,
`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU,
`PUSH,`PMW,`PEA,`POP,`RTS,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`INC,`CAS,`JALI,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
`SB,`SC,`SH,`SW,`SBX,`SCX,`SHX,`SWX:
	fnIsMC = TRUE;
default:	fnIsMC = FALSE;
endcase
endfunction

wire iihit;
// Stall the pipeline if there's an immediate prefix in it during a cache miss.
wire stallRF = 
	((opcode==`IMM && xopcode==`IMM) ||
	 (opcode==`IMM)) && !iihit;

wire advanceWB = TRUE;
wire advanceEX = !fnIsMC(xopcode,xfunct);
wire advanceRF = !stallRF & advanceEX;
wire advanceIF = advanceRF & iihit;

//-----------------------------------------------------------------------------
// Instruction Cache
//-----------------------------------------------------------------------------

reg isICacheReset;
reg isICacheLoad;
wire [31:0] insn;
wire ihit;
assign iihit = (ice ? ihit : ibufhit);
reg utg;			// update cache tag
reg [AMSB:0] tagadr;

FISA64_icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & (ack_i|err_i)),
	.i(err_i ? {2{`BRK_IBE}} : dat_i),
	.rclk(~clk),
	.pc(pc[12:0]),
	.insn(insn)
);

FISA64_itag_ram u2
(
	.wclk(clk),
	.wa(tagadr),
	.v(!isICacheReset),
	.wr(utg|isICacheReset),
	.rclk(~clk),
	.pc(pc),
	.hit(ihit)
);

//-----------------------------------------------------------------------------
// Memory management stuff.
//-----------------------------------------------------------------------------

reg [AMSB:0] rpc;		// registered PC value
always @(negedge clk)
	rpc <= pc;
reg [15:0] lottags [2047:0];
always @(posedge clk)
	if (advanceEX && xopcode==`RR && xfunct==`MTSPR && xir[24:17]==`TAGS)
		lottags[ea[26:16]] <= a[15:0];
wire [15:0] lottag = (ea[31:20]==12'hFFD) ? 16'h0006 : lottags[ea[26:16]];	// allow for I/O
wire [15:0] lottagX = (ea[31:20]==12'hFFD) ? 16'h0000 : lottags[rpc[26:16]];

reg [9:0] lotgrp [5:0];

wire isLotOwner = km | (((lotgrp[0]==lottag[15:6]) ||
					(lotgrp[1]==lottag[15:6]) ||
					(lotgrp[2]==lottag[15:6]) ||
					(lotgrp[3]==lottag[15:6]) ||
					(lotgrp[4]==lottag[15:6]) ||
					(lotgrp[5]==lottag[15:6])))
					;
wire isLotOwnerX = km | (((lotgrp[0]==lottagX[15:6]) ||
					(lotgrp[1]==lottagX[15:6]) ||
					(lotgrp[2]==lottagX[15:6]) ||
					(lotgrp[3]==lottagX[15:6]) ||
					(lotgrp[4]==lottagX[15:6]) ||
					(lotgrp[5]==lottagX[15:6])))
					;

//-----------------------------------------------------------------------------
// Debug
//-----------------------------------------------------------------------------

wire db_imatch0 = (dbctrl[0] && dbctrl[17:16]==2'b00 && pc[AMSB:2]==dbad0[AMSB:2]);
wire db_imatch1 = (dbctrl[1] && dbctrl[21:20]==2'b00 && pc[AMSB:2]==dbad1[AMSB:2]);
wire db_imatch2 = (dbctrl[2] && dbctrl[25:24]==2'b00 && pc[AMSB:2]==dbad2[AMSB:2]);
wire db_imatch3 = (dbctrl[3] && dbctrl[29:28]==2'b00 && pc[AMSB:2]==dbad3[AMSB:2]);
wire db_imatch = db_imatch0|db_imatch1|db_imatch2|db_imatch3;

wire db_lmatch0 =
			dbctrl[0] && dbctrl[17:16]==2'b11 && ea[AMSB:3]==dbad0[AMSB:3] &&
				((dbctrl[19:18]==2'b00 && ea[2:0]==dbad0[2:0]) ||
				 (dbctrl[19:18]==2'b01 && ea[2:1]==dbad0[2:1]) ||
				 (dbctrl[19:18]==2'b10 && ea[2]==dbad0[2]) ||
				 dbctrl[19:18]==2'b11)
				 ;
wire db_lmatch1 = 
			dbctrl[1] && dbctrl[21:20]==2'b11 && ea[AMSB:3]==dbad1[AMSB:3] &&
				((dbctrl[23:22]==2'b00 && ea[2:0]==dbad1[2:0]) ||
				 (dbctrl[23:22]==2'b01 && ea[2:1]==dbad1[2:1]) ||
				 (dbctrl[23:22]==2'b10 && ea[2]==dbad1[2]) ||
				 dbctrl[23:22]==2'b11)
		    ;
wire db_lmatch2 = 
			dbctrl[2] && dbctrl[25:24]==2'b11 && ea[AMSB:3]==dbad2[AMSB:3] &&
				((dbctrl[27:26]==2'b00 && ea[2:0]==dbad2[2:0]) ||
				 (dbctrl[27:26]==2'b01 && ea[2:1]==dbad2[2:1]) ||
				 (dbctrl[27:26]==2'b10 && ea[2]==dbad2[2]) ||
				 dbctrl[27:26]==2'b11)
			;
wire db_lmatch3 =
			dbctrl[3] && dbctrl[29:28]==2'b11 && ea[AMSB:3]==dbad3[AMSB:3]  &&
				((dbctrl[31:30]==2'b00 && ea[2:0]==dbad3[2:0]) ||
				 (dbctrl[31:30]==2'b01 && ea[2:1]==dbad3[2:1]) ||
				 (dbctrl[31:30]==2'b10 && ea[2]==dbad3[2]) ||
				 dbctrl[31:30]==2'b11)
			;
wire db_lmatch = db_lmatch0|db_lmatch1|db_lmatch2|db_lmatch3;

wire db_smatch0 =
			dbctrl[0] && dbctrl[17:16]==2'b01 && ea[AMSB:3]==dbad0[AMSB:3] &&
				((dbctrl[19:18]==2'b00 && ea[2:0]==dbad0[2:0]) ||
				 (dbctrl[19:18]==2'b01 && ea[2:1]==dbad0[2:1]) ||
				 (dbctrl[19:18]==2'b10 && ea[2]==dbad0[2]) ||
				 dbctrl[19:18]==2'b11)
				 ;
wire db_smatch1 = 
			dbctrl[1] && dbctrl[21:20]==2'b01 && ea[AMSB:3]==dbad1[AMSB:3] &&
				((dbctrl[23:22]==2'b00 && ea[2:0]==dbad1[2:0]) ||
				 (dbctrl[23:22]==2'b01 && ea[2:1]==dbad1[2:1]) ||
				 (dbctrl[23:22]==2'b10 && ea[2]==dbad1[2]) ||
				 dbctrl[23:22]==2'b11)
		    ;
wire db_smatch2 = 
			dbctrl[2] && dbctrl[25:24]==2'b01 && ea[AMSB:3]==dbad2[AMSB:3] &&
				((dbctrl[27:26]==2'b00 && ea[2:0]==dbad2[2:0]) ||
				 (dbctrl[27:26]==2'b01 && ea[2:1]==dbad2[2:1]) ||
				 (dbctrl[27:26]==2'b10 && ea[2]==dbad2[2]) ||
				 dbctrl[27:26]==2'b11)
			;
wire db_smatch3 =
			dbctrl[3] && dbctrl[29:28]==2'b01 && ea[AMSB:3]==dbad3[AMSB:3]  &&
				((dbctrl[31:30]==2'b00 && ea[2:0]==dbad3[2:0]) ||
				 (dbctrl[31:30]==2'b01 && ea[2:1]==dbad3[2:1]) ||
				 (dbctrl[31:30]==2'b10 && ea[2]==dbad3[2]) ||
				 dbctrl[31:30]==2'b11)
			;
wire db_smatch = db_smatch0|db_smatch1|db_smatch2|db_smatch3;

wire db_stat0 = db_imatch0 | db_lmatch0 | db_smatch0;
wire db_stat1 = db_imatch1 | db_lmatch1 | db_smatch1;
wire db_stat2 = db_imatch2 | db_lmatch2 | db_smatch2;
wire db_stat3 = db_imatch3 | db_lmatch3 | db_smatch3;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Overflow:
// Add: the signs of the inputs are the same, and the sign of the
// sum is different
// Sub: the signs of the inputs are different, and the sign of
// the sum is the same as B
function fnASOverflow;
input op;
input a;
input b;
input s;
begin
fnASOverflow = (op ^ s ^ b) & (~op ^ a ^ b);
end
endfunction

wire [63:0] btfldo;

FISA64_bitfield u3
(
	.op(xir[31:29]),
	.a(a),
	.b(c),
	.imm(xir[11:7]),
	.m(xir[28:17]),
	.o(btfldo),
	.masko()
);

//-----------------------------------------------------------------------------
// Evaluate branch condition, compare to zero.
//-----------------------------------------------------------------------------

reg takb;
always @(xir or a)
	case(xir[14:12])
	`BEQ:	takb <= ~|a;
	`BNE:	takb <=  |a;
	`BGT:	takb <= (~a[63] & |a[62:0]);
	`BGE:	takb <= ~a[63];
	`BLT:	takb <= a[63];
	`BLE:	takb <= (a[63] | ~|a[63:0]);
	default:	takb <= FALSE;
	endcase

//-----------------------------------------------------------------------------
// Branch history table.
// The history table is updated by the EX stage and read in
// both the EX and IF stages.
//-----------------------------------------------------------------------------
wire predict_taken;
reg dbranch_taken,xbranch_taken;

FISA64_BranchHistory u4
(
	.rst(rst_i),
	.clk(clk),
	.advanceX(advanceEX),
	.xir(xir),
	.pc(pc),
	.xpc(xpc),
	.takb(takb),
	.predict_taken(predict_taken)
);


//-----------------------------------------------------------------------------
// Datapath
//-----------------------------------------------------------------------------
wire lti = $signed(a) < $signed(imm);
wire ltui = a < imm;
wire eqi = a==imm;
wire eq = a==b;
wire lt = $signed(a) < $signed(b);
wire ltu = a < b;

wire [63:0] logico;
wire [63:0] shifto;

FISA64_logic u5
(
	.xir({x1funct,xir[24:7],x1opcode}),
	.a(a),
	.b(b),
	.imm(imm),
	.res(logico)
);

FISA64_shift u6
(
	.xir({x1funct,xir[24:7],x1opcode}),
	.a(a),
	.b(b),
	.res(shifto),
	.rolo()
);

always @*
case(x1opcode)
`BSR:	res <= xpc + 64'd4;
`JAL:	res <= xpc + 64'd4;
`JALI:	res <= xpc + 64'd4;
`ADD:	res <= a + imm;
`ADDU:	res <= a + imm;
`SUB:	res <= a - imm;
`SUBU:	res <= a - imm;
`CMP:	res <= lti ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
`CMPU:	res <= ltui ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
// need the following so bypass muxing works
`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
		res <= lres;
`AND,`OR,`EOR:	
		res <= logico;
`LDI:	res <= imm;
`SEQ:	res <= eqi;
`SNE:	res <= !eqi;
`SGT:	res <= !(lti|eqi);
`SGE:	res <= !lti;
`SLT:	res <= lti;
`SLE:	res <= lti|eqi;
`SHI:	res <= !(ltui|eqi);
`SHS:	res <= !ltui;
`SLO:	res <= ltui;
`SLS:	res <= ltui|eqi;
`RR:
	case(x1funct)
	`MFSPR:
		if (km) begin
			case(xir[24:17])
			`CR0:		res <= cr0;
			`TICK:		res <= tick;
			`CLK:		res <= clk_throttle_new;
			`DBPC:		res <= dbpc;
			`EPC:		res <= epc;
			`IPC:		res <= ipc;
			`VBR:		res <= vbr;
			`MULH:		res <= p[127:64];
			`EA:		res <= ea;
			`TAGS:		res <= lottag;
			`LOTGRP:	res <= {lotgrp[5],lotgrp[4],lotgrp[3],lotgrp[2],lotgrp[1],lotgrp[0]};
			`CASREG:	res <= casreg;
			`MYSTREG:	res <= mystreg;
			`DBCTRL:	res <= dbctrl;
			`DBAD0:		res <= dbad0;
			`DBAD1:		res <= dbad1;
			`DBAD2:		res <= dbad2;
			`DBAD3:		res <= dbad3;
			`DBSTAT:	res <= dbstat;
			default:	res <= 64'd0;
			endcase
		end
		else begin
			case(xir[24:17])
			`MYSTREG:	res <= mystreg;
			`MULH:		res <= p[127:64];
			default:	res <= 64'd0;
			endcase
		end
	`ADD:	res <= a + b;
	`ADDU:	res <= a + b;
	`SUB:	res <= a - b;
	`SUBU:	res <= a - b;
	`CMP:	res <= lt ? 64'hFFFFFFFFFFFFFFFF : eq ? 64'd0 : 64'd1;
	`CMPU:	res <= ltu ? 64'hFFFFFFFFFFFFFFFF : eq ? 64'd0 : 64'd1;
	`MUL:	res <= lres;	// need the following so bypass muxing works
	`MULU:	res <= lres;
	`DIV:	res <= lres;
	`DIVU:	res <= lres;
	`MOD:	res <= lres;
	`MODU:	res <= lres;
	`NOT,`AND,`OR,`EOR,`NAND,`NOR,`ENOR:
			res <= logico;
	`SEQ:	res <= eq;
	`SNE:	res <= !eq;
	`SGT:	res <= !(lt|eq);
	`SGE:	res <= !lt;
	`SLT:	res <= lt;
	`SLE:	res <= lt|eq;
	`SHI:	res <= !(ltu|eq);
	`SHS:	res <= !ltu;
	`SLO:	res <= ltu;
	`SLS:	res <= ltu|eq;
	`SLLI,`SLL,`SRLI,`SRL,`SRAI,`SRA,`ROL,`ROLI,`ROR,`RORI:	
			res <= shifto;
	`SXB:	res <= {{56{a[7]}},a[7:0]};
	`SXC:	res <= {{48{a[15]}},a[15:0]};
	`SXH:	res <= {{32{a[31]}},a[31:0]};
	default:	res <= 64'd0;
	endcase
`BTFLD:	res <= btfldo;
`LEAX:	res <= a + (b << xir[23:22]) + imm;
`PMW:	res <= lres;
`POP:	res <= lres;
`RTS:	res <= lres;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`INC,`CAS,`JALI,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
		res <= lres;
default:	res <= 64'd0;
endcase

always @(x1opcode,a,c,imm)
case(x1opcode)
`POP:	res2 <= a + imm;
`RTS:	res2 <= a + imm;
`RTL:	res2 <= a + imm;
`PUSH:	res2 <= c - 64'd8;
`PMW:	res2 <= c - 64'd8;
`PEA:	res2 <= c - 64'd8;
default:	res2 <= 64'd0;
endcase

reg nmi1;
reg nmi_edge;
reg ld_clk_throttle;
//-----------------------------------------------------------------------------
// Clock control
// - reset or NMI reenables the clock
// - this circuit must be under the clk_i domain
//-----------------------------------------------------------------------------
//
reg cpu_clk_en;
reg [49:0] clk_throttle;

BUFGCE u20 (.CE(cpu_clk_en), .I(clk_i), .O(clk) );

reg lct1;
always @(posedge clk_i)
if (rst_i) begin
	cpu_clk_en <= 1'b1;
	lct1 <= 1'b0;
	clk_throttle <= 50'h3FFFFFFFFFFFF;	// 100% power
end
else begin
	lct1 <= ld_clk_throttle;
	if (ld_clk_throttle && !lct1)
		clk_throttle <= clk_throttle_new;
	else
		clk_throttle <= {clk_throttle[48:0],clk_throttle[49]};
	if (nmi_i)
		clk_throttle <= 50'h3FFFFFFFFFFFF;
	cpu_clk_en <= clk_throttle[49];
end
assign clk_o = clk;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
always @(posedge clk)
if (rst_i) begin
	insncnt <= 32'd0;
	ibufadr <= 28'd0;
	tick <= 64'd0;
	vbr <= 32'd0;
	km <= `TRUE;
	pc <= 32'h10000;
	state <= RESET;
	nop_ir();
	nop_xir();
	x1opcode <= `NOP;
	wb_nack();
	adr_o[3] <= 1'b1;	// adr_o[3] must be set
	isICacheReset <= TRUE;
	isICacheLoad <= FALSE;
	gie <= `FALSE;
	im <= `TRUE;
	imcd <= 3'b000;
	StatusHWI <= `FALSE;
	nmi1 <= `FALSE;
	nmi_edge <= `FALSE;
	ld_clk_throttle <= `FALSE;
	dbctrl <= 64'd0;
	dbstat <= 64'd0;
	mc_done <= TRUE;
	tagadr <= 64'd0;
	regSP <= 5'd30;
	cr0[0] <= FALSE;	// protected mode enable
	cr0[30] <= TRUE;	// instruction cache enable
	cr0[32] <= TRUE;	// branch predictor enable
end
else begin
utg <= FALSE;
tick <= tick + 64'd1;
nmi1 <= nmi_i;
if (nmi_i & ~nmi1)
	nmi_edge <= `TRUE;
ld_clk_throttle <= `FALSE;
if (db_stat0) dbstat[0] <= TRUE;
if (db_stat1) dbstat[1] <= TRUE;
if (db_stat2) dbstat[2] <= TRUE;
if (db_stat3) dbstat[3] <= TRUE;
case (state)
RESET:
begin
	tagadr <= tagadr + 32'd16;
	if (tagadr[12:4]==9'h1ff) begin
		isICacheReset <= FALSE;
		state <= RUN;
		$display("******************************");
		$display("******************************");
		$display("    Finished Reset ");
		$display("******************************");
		$display("******************************");
	end
end
RUN:
begin
	//-----------------------------------------------------------------------------
	// IFETCH stage
	//-----------------------------------------------------------------------------
	if (advanceIF) begin
		if (imcd != 3'd000) begin
			imcd <= {imcd[1:0],1'b0};
			if (imcd==3'b100)
				im <= `FALSE;
		end
		insncnt <= insncnt + 32'd1;
		if (!StatusHWI & gie & nmi_edge)
			ir <= `BRK_NMI;
		else if (!StatusHWI & gie & !im & irq_i) begin
			$display("*****************************");
			$display("*****************************");
			$display("*****************************");
			$display("****     IRQ %d    ****", vect_i);
			$display("*****************************");
			$display("*****************************");
			$display("*****************************");
			ir <= `BRK_IRQ;
		end
		else if (db_imatch)
			ir <= `BRK_IBPT;
		else if (!((isLotOwnerX && (km ? lottagX[0] : lottagX[3])) || !pe))
			ir <= `BRK_EXF;
		else if (ice)
			ir <= insn;
		else
			ir <= ibuf;
		disassem(iir);
		$display("%h: %h", pc, iir);
		dpc <= pc;
		dbranch_taken <= FALSE;
		// We take the following control transfers immediately in the IF stage,
		// that makes them single cycle operations.
		if (iopcode==`Bcc && predict_taken && bpe) begin
			pc <= pc + {{47{iir[31]}},iir[31:17],2'b00};
			dbranch_taken <= TRUE;
		end
		else if (iopcode==`BSR || iopcode==`BRA) begin
			pc <= pc + {{37{iir[31]}},iir[31:7],2'b00};
		end
		else if (iopcode==`RR && ifunct==`PCTRL) begin
			case(iir[21:17])
			`RTD:	pc <= dbpc;
			`RTE:	pc <= epc;
			`RTI:	pc <= ipc;
			default:	pc <= pc + 64'd4;
			endcase
		end
		else
			pc <= pc + 64'd4;
	end
	else begin
		if (!iihit & !fnIsMC(xopcode,xfunct))
			next_state(LOAD_ICACHE);
		if (advanceRF) begin
			nop_ir();
			dpc <= pc;
			pc <= pc;
		end
	end
	
	//-----------------------------------------------------------------------------
	// DECODE / REGFETCH
	//-----------------------------------------------------------------------------
	if (advanceRF) begin
		xbranch_taken <= dbranch_taken;
		xir <= ir;
		xopcode <= opcode;
		xfunct <= funct;
		x1opcode <= opcode;
		x1funct <= funct;
		if (fnIsMC(opcode,funct))
			mc_done <= FALSE;
		if (opcode==`MYST)
			xfunct <= mystreg;

		// Set the PC associated with the instruction. There is some trickery
		// involved here in order to support interrupts. The processor must
		// return to a prior instruction prefix in th event of an interrupt,
		// so we make the current instruction inherit the address of the
		// prefix.
		if (wopcode==`IMM && xopcode==`IMM)
			xpc <= wpc;	// in case of interrupt
		else if (xopcode==`IMM)
			xpc <= xpc;
		else
			xpc <= dpc;

		// And... register the register operands of the instruction.
		a <= rfoa;
		b <= rfob;
		c <= rfoc;

		// Setup the immediate constant. Currently extending the constant
		// field is supported only for 15 bit constants. This covers all
		// instructions except indexed memory loads and stores. It's not
		// likely the compiler will make use of a constant for indexed
		// addressing so we don't bother to support extending it. Note
		// also we don't check for the case of branches which shouldn't
		// use constant extension. It's less hardware and can be handled
		// by the assembler.
		case(opcode)
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX:
			imm <= ir[31:24];
		default:
			if (wopcode==`IMM && xopcode==`IMM)
				imm <= {wir[31:7],xir[31:7],ir[31:17]};
			else if (xopcode==`IMM)
				imm <= {{24{xir[31]}},xir[31:7],ir[31:17]};
			else
				imm <= {{49{ir[31]}},ir[31:17]};
		endcase

		// Set the target register field. Some op's need this set to zero in
		// order to prevent a register from being updated. Other op's use the
		// target register field from the instruction.
		case(opcode)
		`RR:
			case(funct)
			`MTSPR,`FENCE:
				xRt <= 5'd0;
			`PCTRL:
				xRt <= 5'd0;
			default:	xRt <= ir[16:12];
			endcase
		`BRA,`Bcc,`BRK,`IMM,`NOP:
			xRt <= 5'd0;
		`SB,`SC,`SH,`SW,`SBX,`SCX,`SHX,`SWX,`INC,
		`RTL,`PUSH,`PEA,`PMW:
			xRt <= 5'd0;
		`BSR,`RTS:	xRt <= 5'h1F;
		default:	xRt <= ir[16:12];
		endcase
		
		// Set the SP target register flag. This flag indicates an update to
		// the SP register is required. Used for stack operations.
		case(opcode)
		`POP,`RTS,`RTL,`PUSH,`PEA,`PMW:	xRt2 <= 1'b1;
		default:	xRt2 <= 1'b0;
		endcase
	end
	// Makes an immediate prefix "sticky".
	else if (advanceEX) begin
		//if (xopcode != `IMM)
			nop_xir();
	end

	//-----------------------------------------------------------------------------
	// EXECUTE
	//-----------------------------------------------------------------------------
	if (advanceEX) begin
		// The following lines needed for code above for immediate prefixes.
		wopcode <= x1opcode;
		wpc <= xpc;
		wir <= xir;
		// Make the last register update "sticky" in the WB stage.
		if (xRt != 5'd0 && xRt != regSP) begin
			wRt <= xRt;
			wres <= res;
		end
		// Move SP update over to SP result bus.
		// Trying to write two different results to the SP at the same time
		// can only happen if popping the SP register, in that case the value
		// popped from the stack should win.
		if (xRt==regSP) begin
			wRt2 <= 1'b1;
			wres2 <= res;
		end
		else if (xRt2) begin
			wRt2 <= xRt2;
			wres2 <= res2;
		end
		// The following ssm conditional places a BRK instruction in the 
		// instruction stream immediately after an instruction. Immediate prefixes
		// are not single-stepped. As soon as the SSM condition passes we turn it
		// off so that the debug routine may run full speed.
		if (ssm) begin
			if (xopcode != `IMM) begin
				xRt <= 5'd0;				// Inject appropriate BRK instruction
				xopcode <= `BRK;			// into instruction stream.
				x1opcode <= `BRK;
				xir <= `BRK_SSM;
				dbctrl[62] <= dbctrl[63];	// record that SSM was on
				dbctrl[63] <= FALSE;		// turn off SSM
			end
		end
		case(x1opcode)
		`RR:
			case(xfunct)
			`MTSPR:
				if (km) begin
					case(xir[24:17])
					`CR0:		cr0 <= a;
					`DBPC:		dbpc <= {a[AMSB:2],2'b00};
					`EPC:		epc <= {a[AMSB:2],2'b00};
					`IPC:		ipc <= {a[AMSB:2],2'b00};
					`VBR:		begin vbr <= a[AMSB:0]; vbr[12:0] <= 13'h000; end
					`MULH:		p[127:64] <= a;
					`EA:		ea <= a;
					`LOTGRP:
						begin
							lotgrp[0] <= a[ 9: 0];
							lotgrp[1] <= a[19:10];
							lotgrp[2] <= a[29:20];
							lotgrp[3] <= a[39:30];
							lotgrp[4] <= a[49:40];
							lotgrp[5] <= a[59:50];
						end
					`CASREG:	casreg <= a;
					`MYSTREG:	mystreg <= a;
					`CLK:		begin clk_throttle_new <= res[49:0]; ld_clk_throttle <= `TRUE; end
					`DBCTRL:	dbctrl <= a;
					`DBAD0:		dbad0 <= a;
					`DBAD1:		dbad1 <= a;
					`DBAD2:		dbad2 <= a;
					`DBAD3:		dbad3 <= a;
					endcase
				end
				else begin
					case(xir[24:17])
					`MYSTREG:	mystreg <= a;
					default:	privilege_violation();
					endcase
				end
				
			`MFSPR:	if (!km && xir[24:17]!=`MULH && xir[24:17] != `MYSTREG)
						privilege_violation();
			`PCTRL:
				if (km)
					case(xir[21:17])
					`CLI:	imcd <= 3'b111;
					`SEI:	im <= `TRUE;
					`STP:	begin clk_throttle_new <= 50'd0; ld_clk_throttle <= `TRUE; end
					`EIC:	cr0[30] <= TRUE;
					`DIC:	cr0[30] <= FALSE;
					
					`RTD:
						begin
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
							dbctrl[63] <= dbctrl[62];	// maybe turn SSM back on
						end
					`RTE:
						begin
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
						end
					`RTI:
						begin
							StatusHWI <= FALSE;
							imcd <= 3'b111;
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
						end
					endcase
				else
					privilege_violation();
			`ADD:	if (fnASOverflow(0,a[63],b[63],res[63]))
						overflow();
			`SUB:	if (fnASOverflow(1,a[63],b[63],res[63]))
						overflow();
			endcase
		`ADD:	if (fnASOverflow(0,a[63],imm[63],res[63]))
					overflow();
		`SUB:	if (fnASOverflow(1,a[63],imm[63],res[63]))
					overflow();
		`BSR,`BRA:	;//update_pc(xpc + imm); done already in IF
		`JAL:		update_pc(a + {imm,2'b00});
		`RTL:	begin
					update_pc(c);
					$display("RTL: pc<=%h", a);
				end
		// For these instructions, the PC was already modified as part of the
		// multi-cycle operation. But we still need to flush the pipeline of
		// following instructions.
		`BRK,`RTS,`JALI:
				begin
					// Don't need to flush the ir. The PC was set correctly
					// a cycle sooner in the multi-cycle code.
					if (!ssm)
						nop_xir();
				end
		// Correct a mispredicted branch.
		`Bcc:	if (takb & !xbranch_taken)
					update_pc(xpc + {imm,2'b00});
				else if (!takb & xbranch_taken)
					update_pc(xpc + 64'd4);
		endcase
	end

	//-----------------------------------------------------------------------------
	// WRITEBACK
	//-----------------------------------------------------------------------------
	// wRt2 and wRt==30 are never active together at the same time.
	if (advanceWB) begin
		if (wRt != 5'd0) begin
			tRt <= wRt;
			tres <= wres;
		end
		regfile[wRt] <= wres;
		if (wRt2)
			sp <= wres2;
		if (wRt==regSP)	begin // write to SP globally enables interrupts
			gie <= `TRUE;
			sp <= wres;
		end
	end
	// If advanceTL (= TRUE)
	if (tRt != 5'd0) begin
		uRt <= tRt;
		ures <= tres;
	end

	//-----------------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	// Kick off a multi-cycle operation. The EX stage will be stalled until
	// the operation is complete. The operation is signalled as complete by
	// setting xopcode=`NOP which allows the pipeline to advance.
	if (fnIsMC(xopcode,xfunct)) begin
		case (xopcode)
		`RR:
			case (xfunct)
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
				begin
					mdopcode <= xopcode;
					mdfunct <= xfunct;
					next_state(MULDIV);
				end
			endcase
		`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
			begin
				mdopcode <= xopcode;
				mdfunct <= xfunct;
				next_state(MULDIV);
			end
		`BRK:	begin
				case(xir[31:30])
				2'b00:	epc <= xpc;
				2'b01:
					begin
						dbpc <= xpc;
						//dbctrl[62] <= dbctrl[63];
						//dbctrl[63] <= FALSE;	// clear SSM
					end
				2'b10:
					begin
						StatusHWI <= `TRUE;
						ipc <= xpc;
						if (xir[25:17]==9'd510)
							nmi_edge <= FALSE;
						else
							im <= TRUE;
					end
				endcase
				mopcode <= xopcode;
				mir <= xir;
				ea <= {vbr[AMSB:12],xir[25:17],3'b000};
				ld_size <= word;
				next_state(LOAD1);
				end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`INC,`CAS,`JALI:
			begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				case(xopcode)
				`LB,`LBU:	ld_size <= byt;
				`LC,`LCU:	ld_size <= char;
				`LH,`LHU:	ld_size <= half;
				`LW,`INC:	ld_size <= word;
				`CAS,`JALI:	ld_size <= word;
				endcase
				st_size <= word;
			end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
			begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + (b << xir[23:22]) + imm;
				case(xopcode)
				`LBX,`LBUX:	ld_size <= byt;
				`LCX,`LCUX:	ld_size <= char;
				`LHX,`LHUX:	ld_size <= half;
				`LWX:		ld_size <= word;
				endcase
			end
		`PMW:
			begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				ld_size <= word;
				st_size <= word;
			end
		`PUSH:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= res2;
				xb <= a;
				st_size <= word;
				end
		`PEA:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= res2;
				xb <= a + imm;
				st_size <= word;
				end
		`POP,`RTS:
				begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a;
				ld_size <= word;
				end
		`SB,`SC,`SH,`SW:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= a + imm;
				xb <= c;
				case(xopcode)
				`SB:	st_size <= byt;
				`SC:	st_size <= char;
				`SH:	st_size <= half;
				`SW:	st_size <= word;
				endcase
				end
		`SBX,`SCX,`SHX,`SWX:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= a + (b << xir[23:22]) + imm;
				xb <= c;
				case(xopcode)
				`SBX:	st_size <= byt;
				`SCX:	st_size <= char;
				`SHX:	st_size <= half;
				`SWX:	st_size <= word;
				endcase
				end
		endcase
	end

end	// RUN

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(mdopcode)
		`MULU:
			begin
				aa <= a;
				bb <= imm;
				res_sgn <= 1'b0;
				next_state(MULT1);
			end
		`MUL:
			begin
				aa <= a[63] ? -a : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				res_sgn <= a[63] ^ imm[63];
				next_state(MULT1);
			end
		`DIVU,`MODU:
			begin
				aa <= a;
				bb <= imm;
				q <= a[62:0];
				r <= a[63];
				res_sgn <= 1'b0;
				next_state(DIV);
			end
		`DIV,`MOD:
			begin
				aa <= a[63] ? ~a+64'd1 : a;
				bb <= imm[63] ? ~imm+64'd1 : imm;
				q <= pa[62:0];
				r <= pa[63];
				res_sgn <= a[63] ^ imm[63];
				next_state(DIV);
			end
		`RR:
			case(mdfunct)
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
					if (b==64'd0)
						divide_by_zero();
					else
						next_state(DIV);
				end
			default:
				begin
				mc_done <= TRUE;
				state <= iihit ? RUN : LOAD_ICACHE;
				end
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
		if (mdopcode==`MUL || mdopcode==`MULU || (mdopcode==`RR && (mdfunct==`MUL || mdfunct==`MULU)))
			lres <= p[63:0];
		else if (mdopcode==`DIV || mdopcode==`DIVU || (mdopcode==`RR && (mdfunct==`DIV || mdfunct==`DIVU)))
			lres <= q[63:0];
		else
			lres <= r[63:0];
		mc_done <= TRUE;
		xopcode <= `NOP;
		next_state(iihit ? RUN : LOAD_ICACHE);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Load States
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD1:	next_state(LOAD2);

LOAD2:
	begin
		// Check for a breakpoint
		if (db_lmatch) begin
			wb_read1(word,{vbr[AMSB:12],9'd496,3'b000});	// Breakpoint
			mopcode <= `BRK;
			dbpc <= xpc;
			dbctrl[62] <= dbctrl[63];
			dbctrl[63] <= FALSE;	// clear SSM
			next_state(LOAD3);
		end
		// Check for read attribute on lot
		else if ((isLotOwner && (km ? lottag[2] : lottag[5])) || !pe) begin
			$display("LOAD: %h",ea);
			wb_read1(ld_size,ea);
			next_state(LOAD3);
		end
		else begin
			wb_read1(word,{vbr[AMSB:12],9'd499,3'b000});	// Data read fault
			mopcode <= `BRK;
			epc <= xpc;
			next_state(LOAD3);
		end
	end
LOAD3:
	if (err_i)
		databus_error();
	else if (ack_i) begin
		case(mopcode)
		`LB,`LBX:
			begin
			wb_nack();
			next_state(iihit ? RUN : LOAD_ICACHE);
			mc_done <= TRUE;
			xopcode <= `NOP;
			case(ea[2:0])
			3'd0:	lres <= {{56{dat_i[7]}},dat_i[7:0]};
			3'd1:	lres <= {{56{dat_i[15]}},dat_i[15:8]};
			3'd2:	lres <= {{56{dat_i[23]}},dat_i[23:16]};
			3'd3:	lres <= {{56{dat_i[31]}},dat_i[31:24]};
			3'd4:	lres <= {{56{dat_i[39]}},dat_i[39:32]};
			3'd5:	lres <= {{56{dat_i[47]}},dat_i[47:40]};
			3'd6:	lres <= {{56{dat_i[55]}},dat_i[55:48]};
			3'd7:	lres <= {{56{dat_i[63]}},dat_i[63:56]};
			endcase
			end
		`LBU,`LBUX:
			begin
			wb_nack();
			next_state(iihit ? RUN : LOAD_ICACHE);
			xopcode <= `NOP;
			mc_done <= TRUE;
			case(ea[2:0])
			3'd0:	lres <= dat_i[7:0];
			3'd1:	lres <= dat_i[15:8];
			3'd2:	lres <= dat_i[23:16];
			3'd3:	lres <= dat_i[31:24];
			3'd4:	lres <= dat_i[39:32];
			3'd5:	lres <= dat_i[47:40];
			3'd6:	lres <= dat_i[55:48];
			3'd7:	lres <= dat_i[63:56];
			endcase
			end
		`LC,`LCX:
			case(ea[2:0])
			3'd0:	begin lres <= {{48{dat_i[15]}},dat_i[15:0]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd1:	begin lres <= {{48{dat_i[23]}},dat_i[23:8]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd2:	begin lres <= {{48{dat_i[31]}},dat_i[31:16]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd3:	begin lres <= {{48{dat_i[39]}},dat_i[39:24]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd4:	begin lres <= {{48{dat_i[47]}},dat_i[47:32]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd5:	begin lres <= {{48{dat_i[55]}},dat_i[55:40]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd6:	begin lres <= {{48{dat_i[63]}},dat_i[63:48]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd7:	begin lres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LCU,`LCUX:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[15:0]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd1:	begin lres <= dat_i[23:8]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd2:	begin lres <= dat_i[31:16]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd3:	begin lres <= dat_i[39:24]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd4:	begin lres <= dat_i[47:32]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd5:	begin lres <= dat_i[55:40]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd6:	begin lres <= dat_i[63:48]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd7:	begin lres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LH,`LHX:
			case(ea[2:0])
			3'd0:	begin lres <= {{32{dat_i[31]}},dat_i[31:0]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd1:	begin lres <= {{32{dat_i[39]}},dat_i[39:8]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd2:	begin lres <= {{32{dat_i[47]}},dat_i[47:16]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd3:	begin lres <= {{32{dat_i[55]}},dat_i[55:24]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd4:	begin lres <= {{32{dat_i[63]}},dat_i[63:32]}; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[31:0]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd1:	begin lres <= dat_i[39:8]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd2:	begin lres <= dat_i[47:16]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd3:	begin lres <= dat_i[55:24]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd4:	begin lres <= dat_i[63:32]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[63:0]; next_state(iihit ? RUN : LOAD_ICACHE); wb_nack(); mc_done <= TRUE; xopcode <= `NOP;end
			3'd1:	begin lres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin lres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin lres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin lres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`INC:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[63:0]; next_state(INC); wb_half_nack(); end
			3'd1:	begin lres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin lres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin lres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin lres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		// For PMW, JALI the wres bus is occupied with a register update value,
		// so it can't be used for the load. Fortunately it's easy to define
		// another reg (lres) to hold onto the loaded value.
		`PMW,`JALI:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[63:0]; next_state(PMW); wb_nack(); end
			3'd1:	begin lres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin lres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin lres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin lres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		// Memory access is aligned
		`BRK:	begin
					pc[AMSB:2] <= dat_i[AMSB:2];
					pc[1:0] <= 2'b00;
					next_state(iihit ? RUN : LOAD_ICACHE);
					xopcode <= `NOP;
					wb_nack();
					mc_done <= TRUE;
					km <= `TRUE;
					kmb <= {kmb[6:0],km};
				end
		`RTS:
				begin
					lres <= dat_i[63:0];
					pc[AMSB:2] <= dat_i[AMSB:2];
					pc[1:0] <= 2'b00;
					next_state(iihit ? RUN : LOAD_ICACHE);
					xopcode <= `NOP;
					wb_nack();
					mc_done <= TRUE;
				end
		`POP:
				begin
					lres <= dat_i[63:0];
					next_state(iihit ? RUN : LOAD_ICACHE);
					xopcode <= `NOP;
					wb_nack();
					mc_done <= TRUE;
				end
		`CAS:
			case(ea[2:0])
			3'd0:	begin lres <= dat_i[63:0]; next_state(CAS); wb_nack(); end
			3'd1:	begin lres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin lres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin lres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin lres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin lres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin lres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin lres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		endcase
	end
LOAD4:
	begin
		wb_read2(ld_size,ea);
		next_state(LOAD5);
	end
LOAD5:
	if (err_i)
		databus_error();
	else if (ack_i) begin
		if (mopcode==`INC) begin
			wb_half_nack();
			next_state(INC);
		end
		else if (mopcode==`PMW || mopcode==`JALI) begin
			wb_nack();
			next_state(PMW);
		end
		else if (mopcode==`CAS) begin
			wb_nack();
			next_state(CAS);
		end
		else begin
			wb_nack();
			next_state(iihit ? RUN : LOAD_ICACHE);
			xopcode <= `NOP;
			mc_done <= TRUE;
		end
		case(mopcode)
		`LC,`LCX:	lres[63:8] <= {{48{dat_i[7]}},dat_i[7:0]};
		`LCU,`LCUX:	lres[63:8] <= dat_i[7:0];
		`LH,`LHX:
			case(ea[2:0])
			3'd5:	lres[63:24] <= {{32{dat_i[7]}},dat_i[7:0]};
			3'd6:	lres[63:16] <= {{32{dat_i[15]}},dat_i[15:0]};
			3'd7:	lres[63: 8] <= {{32{dat_i[23]}},dat_i[23:0]};
			default:	;
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd5:	lres[63:24] <= dat_i[7:0];
			3'd6:	lres[63:16] <= dat_i[15:0];
			3'd7:	lres[63: 8] <= dat_i[23:0];
			default:	;
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	;
			3'd1:	lres[63:56] <= dat_i[7:0];
			3'd2:	lres[63:48] <= dat_i[15:0];
			3'd3:	lres[63:40] <= dat_i[23:0];
			3'd4:	lres[63:32] <= dat_i[31:0];
			3'd5:	lres[63:24] <= dat_i[39:0];
			3'd6:	lres[63:16] <= dat_i[47:0];
			3'd7:	lres[63: 8] <= dat_i[55:0];
			endcase
		`INC,`CAS:
			case(ea[2:0])
			3'd0:	;
			3'd1:	lres[63:56] <= dat_i[7:0];
			3'd2:	lres[63:48] <= dat_i[15:0];
			3'd3:	lres[63:40] <= dat_i[23:0];
			3'd4:	lres[63:32] <= dat_i[31:0];
			3'd5:	lres[63:24] <= dat_i[39:0];
			3'd6:	lres[63:16] <= dat_i[47:0];
			3'd7:	lres[63: 8] <= dat_i[55:0];
			endcase
		`PMW,`JALI:
			case(ea[2:0])
			3'd0:	;
			3'd1:	lres[63:56] <= dat_i[7:0];
			3'd2:	lres[63:48] <= dat_i[15:0];
			3'd3:	lres[63:40] <= dat_i[23:0];
			3'd4:	lres[63:32] <= dat_i[31:0];
			3'd5:	lres[63:24] <= dat_i[39:0];
			3'd6:	lres[63:16] <= dat_i[47:0];
			3'd7:	lres[63: 8] <= dat_i[55:0];
			endcase
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RMW States
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

INC:
	begin
		xb <= lres + {{59{mir[16]}},mir[16:12]};
		next_state(STORE2);	// We don't need to wait for the ea address calc
	end
PMW:
	begin
		if (mopcode==`JALI) begin
			pc[AMSB:2] <= lres[AMSB:2];
			pc[1:0] <= 2'b00;
			mc_done <= TRUE;
			xopcode <= `NOP;
			next_state(iihit ? RUN : LOAD_ICACHE);
		end
		else begin
			ea <= c - 64'd8;
			xb <= lres;
			next_state(STORE1);	// We changed the ea so we need another cycle 
		end
	end
CAS:
	begin
		if (casreg == lres) begin
			lres <= 64'd1;
			xb <= c;
			next_state(STORE2);
		end
		else begin
			casreg <= lres;
			lres <= 64'd0;
			wb_nack();
			mc_done <= TRUE;
			xopcode <= `NOP;
			next_state(iihit ? RUN : LOAD_ICACHE);
		end
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Store States
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STORE1:	begin next_state(STORE2); end

STORE2:
	begin
		// Check for a breakpoint
		if (db_smatch|db_lmatch) begin
			wb_read1(word,{vbr[AMSB:12],9'd496,3'b000});	// Breakpoint
			mopcode <= `BRK;
			dbpc <= xpc;
			dbctrl[62] <= dbctrl[63];
			dbctrl[63] <= FALSE;	// clear SSM
			next_state(LOAD3);
		end
		// check for write attribute on lot
		else if ((isLotOwner && (km ? lottag[1] : lottag[4])) || !pe) begin
			wb_write1(st_size,ea,xb);
			$display("STORE: %h=%h",ea,xb);
			next_state(STORE3);
		end
		else begin
			wb_read1(word,{vbr[AMSB:12],9'd498,3'b000});	// Data write fault
			mopcode <= `BRK;
			epc <= xpc;
			next_state(LOAD3);
		end
	end
STORE3:
	if (err_i)
		databus_error();
	else if (ack_i) begin
		if ((st_size==char && ea[2:0]==3'b111) ||
			(st_size==half && ea[2:0]>3'd4) ||
			(st_size==word && ea[2:0]!=3'b00)) begin
			wb_half_nack();
			next_state(STORE4);
		end
		else begin
			wb_nack();
			mc_done <= TRUE;
			xopcode <= `NOP;
			next_state(iihit ? RUN : LOAD_ICACHE);
		end
	end
STORE4:
	begin
		wb_write2(st_size,ea,xb);
		next_state(STORE5);
	end
STORE5:
	if (err_i)
		databus_error();
	else if (ack_i) begin
		wb_nack();
		mc_done <= TRUE;
		xopcode <= `NOP;
		next_state(iihit ? RUN : LOAD_ICACHE);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache load states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD_ICACHE:
	begin
		tagadr <= pc;
		if (ice) begin
			isICacheLoad <= TRUE;
			wb_read1(word,{pc[AMSB:4],4'h0});
			next_state(LOAD_ICACHE2);
		end
		else begin
			wb_read1(word,{pc[AMSB:3],3'b000});
			next_state(LOAD_ICACHE2);
		end
	end
LOAD_ICACHE2:
	if (ack_i|err_i) begin
		if (ice) begin
			wb_half_nack();
			next_state(LOAD_ICACHE3);
		end
		else begin
			wb_nack();
			ibufadr <= pc;
			ibuf <= pc[2] ? dat_i[63:32] : dat_i[31:0];
			next_state(RUN);
		end
	end
LOAD_ICACHE3:
	begin
		wb_read1(word,{pc[AMSB:4],4'h8});
		next_state(LOAD_ICACHE4);
	end
LOAD_ICACHE4:
	if (ack_i|err_i) begin
		wb_nack();
		utg <= TRUE;
		isICacheLoad <= FALSE;
		next_state(RUN);
	end
endcase
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Support tasks
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Set select lines for first memory cycle
task wb_sel1;
input [1:0] sz;
input [63:0] adr;
begin
	case(sz)
	byt:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h01;
		3'd1:	sel_o <= 8'h02;
		3'd2:	sel_o <= 8'h04;
		3'd3:	sel_o <= 8'h08;
		3'd4:	sel_o <= 8'h10;
		3'd5:	sel_o <= 8'h20;
		3'd6:	sel_o <= 8'h40;
		3'd7:	sel_o <= 8'h80;
		endcase
	char:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h03;
		3'd1:	sel_o <= 8'h06;
		3'd2:	sel_o <= 8'h0C;
		3'd3:	sel_o <= 8'h18;
		3'd4:	sel_o <= 8'h30;
		3'd5:	sel_o <= 8'h60;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	half:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h0F;
		3'd1:	sel_o <= 8'h1E;
		3'd2:	sel_o <= 8'h3C;
		3'd3:	sel_o <= 8'h78;
		3'd4:	sel_o <= 8'hF0;
		3'd5:	sel_o <= 8'hE0;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	word:
		case(adr[2:0])
		3'd0:	sel_o <= 8'hFF;
		3'd1:	sel_o <= 8'hFE;
		3'd2:	sel_o <= 8'hFC;
		3'd3:	sel_o <= 8'hF8;
		3'd4:	sel_o <= 8'hF0;
		3'd5:	sel_o <= 8'hE0;
		3'd6:	sel_o <= 8'hC0;
		3'd7:	sel_o <= 8'h80;
		endcase
	endcase
end
endtask

// Set select lines for second memory cycle
task wb_sel2;
input [1:0] sz;
input [63:0] adr;
begin
	case(sz)
	byt:	sel_o <= 8'h00;
	char:	sel_o <= 8'h01;
	half:
		case(adr[2:0])
		3'd5:	sel_o <= 8'h01;
		3'd6:	sel_o <= 8'h03;
		3'd7:	sel_o <= 8'h07;
		default:	sel_o <= 8'h00;
		endcase
	word:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h00;
		3'd1:	sel_o <= 8'h01;
		3'd2:	sel_o <= 8'h03;
		3'd3:	sel_o <= 8'h07;
		3'd4:	sel_o <= 8'h0F;
		3'd5:	sel_o <= 8'h1F;
		3'd6:	sel_o <= 8'h3F;
		3'd7:	sel_o <= 8'h7F;
		endcase
	endcase
end
endtask

task wb_dato;
input [1:0] sz;
input [63:0] adr;
input [63:0] dat;
begin
	case(sz)
	byt:
		begin
		dat_o <= {8{dat[7:0]}};
		end
	char:
		case(adr[0])
		1'b0:	dat_o <= {4{dat[15:0]}};
		1'b1:	dat_o <= {dat[7:0],dat[15:0],dat[15:0],dat[15:0],dat[15:8]};
		endcase
	half:
		case(adr[1:0])
		2'd0:	dat_o <= {2{dat[31:0]}};
		2'd1:	dat_o <= {dat[23:0],dat[31:0],dat[31:24]};
		2'd2:	dat_o <= {dat[15:0],dat[31:0],dat[31:16]};
		2'd3:	dat_o <= {dat[ 7:0],dat[31:0],dat[31: 8]};
		endcase
	word:
		case(adr[2:0])
		3'd0:	dat_o <= dat;
		3'd1:	dat_o <= {dat[55:0],dat[63:56]};
		3'd2:	dat_o <= {dat[47:0],dat[63:48]};
		3'd3:	dat_o <= {dat[39:0],dat[63:40]};
		3'd4:	dat_o <= {dat[31:0],dat[63:32]};
		3'd5:	dat_o <= {dat[23:0],dat[63:24]};
		3'd6:	dat_o <= {dat[15:0],dat[63:16]};
		3'd7:	dat_o <= {dat[ 7:0],dat[63: 8]};
		endcase
	endcase
end
endtask

task wb_read1;
input [1:0] sz;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= adr;
	wb_sel1(sz,adr);
end
endtask;

task wb_read2;
input [1:0] sz;
input [63:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= {adr[31:3]+30'd1,3'b000};
	wb_sel2(sz,adr);
end
endtask;

task wb_burst;
input [5:0] bl;
input [63:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 8'hFF;
	adr_o <= {adr[31:3],3'b000};
end
endtask

task wb_write1;
input [1:0] sz;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= adr;
	wb_sel1(sz,adr);
	wb_dato(sz,adr,dat);
end
endtask

task wb_write2;
input [1:0] sz;
input [63:0] adr;
input [63:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= {adr[31:3]+29'd1,3'b000};
	wb_sel2(sz,adr);
	wb_dato(sz,adr,dat);
end
endtask

task wb_nack;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b000;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
end
endtask

task wb_half_nack;
begin
	stb_o <= 1'b0;
	we_o <= 1'b0;
end
endtask

// Flush the RF stage

task nop_ir;
begin
	ir[6:0] <= `NOP;	// NOP
end
endtask

// Flush the EX stage

task nop_xir;
begin
	if (xir!=`BRK_SSM) begin
		x1opcode <= `NOP;
		xopcode <= `NOP;
		xRt <= 5'b0;
		xRt2 <= 1'b0;
		xir[6:0] <= `NOP;	// NOP
	end
end
endtask 

// Sets the PC value for a branch / jump. Also sets the target PC preparing for
// a cache miss. Flush the pipeline of instructions. This is meant to be used 
// from the EX stage.

task update_pc;
input [63:0] npc;
begin
	pc <= npc;
	pc[1:0] <= 2'b00;
	nop_ir();
	if (!ssm)			// If in SSM the xir will be setup appropriately.
		nop_xir();
end
endtask

// For the RTS instruction. We want to NOP out the IR for a following
// instruction, but NOT the EX stage as it's current. update_pc2 is called
// the cycle before the EX stage is promoted.
task update_pc2;
input [63:0] npc;
begin
	pc <= npc;
	pc[1:0] <= 2'b00;
	if (!ssm)			// If in SSM the xir will be setup appropriately.
		nop_ir();
end
endtask

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task databus_error;
begin
	wb_nack();
	ea <= {vbr[AMSB:12],9'd508,3'b000};	// Databus error
	mopcode <= `BRK;
	ipc <= xpc;
	ld_size <= word;
	next_state(LOAD1);
end
endtask

task privilege_violation;
begin
	epc <= xpc;
	xopcode <= `BRK;
	mopcode <= `BRK;
	mir <= xir;
	ea <= {vbr[AMSB:12],9'd501,3'b000};	// privilege violation
	ld_size <= word;
	next_state(LOAD1);
end
endtask

task overflow;
begin
	epc <= xpc;
	xopcode <= `BRK;
	mopcode <= `BRK;
	mir <= xir;
	ea <= {vbr[AMSB:12],9'd489,3'b000};	// overflow violation
	ld_size <= word;
	next_state(LOAD1);
end
endtask

// function argument bad
task divide_by_zero;
begin
	epc <= xpc;
	xopcode <= `BRK;
	mopcode <= `BRK;
	mir <= xir;
	ea <= {vbr[AMSB:12],9'd488,3'b000};	// divide_by_zero
	ld_size <= word;
	next_state(LOAD1);
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Debugging aids - pretty state names
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET ";
RUN:	fnStateName = "RUN ";
MULDIV:	fnStateName = "MULDIV ";
MULT1:	fnStateName = "MULT1 ";
MULT2:	fnStateName = "MULT2 ";
MULT3:	fnStateName = "MULT3 ";
FIX_SIGN:	fnStateName = "FIX_SIGN ";
MD_RES:	fnStateName = "MD_RES ";
LOAD1:  fnStateName = "LOAD1 ";
LOAD2:  fnStateName = "LOAD2 ";
LOAD3:  fnStateName = "LOAD3 ";
LOAD4:  fnStateName = "LOAD4 ";
LOAD5:  fnStateName = "LOAD5 ";
CAS:  fnStateName = "CAS    ";
INC:  fnStateName = "INC    ";
PMW:  fnStateName = "PUSH m ";
STORE1:  fnStateName = "STORE1 ";
STORE2:  fnStateName = "STORE2 ";
STORE3:  fnStateName = "STORE3 ";
STORE4:  fnStateName = "STORE4 ";
STORE5:  fnStateName = "STORE5 ";
LOAD_ICACHE:	fnStateName = "LOAD_ICACHE ";
LOAD_ICACHE2:	fnStateName = "LOAD_ICACHE2 ";
LOAD_ICACHE3:	fnStateName = "LOAD_ICACHE3 ";
LOAD_ICACHE4:	fnStateName = "LOAD_ICACHE4 ";
default:	fnStateName = "UNKNOWN ";
endcase
endfunction

// Mini-disassembler
task disassem;
input [31:0] insn;
begin
	case(insn[6:0])
	`LDI:	$display("LDI r%d,#%h", insn[16:12], insn[31:17]);
	`BRA:	$display("BRA %h" , pc + {{37{insn[31]}},insn[31:7],2'b00});
	`BSR:	$display("BSR %h" , pc + {{37{insn[31]}},insn[31:7],2'b00});
	`Bcc:
		case(insn[14:12])
		`BEQ:	$display("BEQ r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BNE:	$display("BNE r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BLT:	$display("BLT r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		endcase
	`LW:	$display("LW r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`SW:	$display("SW r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`PUSH:	$display("PUSH r%d", insn[11:7]);
	`POP:	$display("POP r%d", insn[16:12]);
	`RTL:	$display("RTL");
	`RTS:	$display("RTS");
	endcase
end
endtask

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module FISA64_icache_ram(wclk, wa, wr, i, rclk, pc, insn);
input wclk;
input [12:0] wa;
input wr;
input [63:0] i;
input rclk;
input [12:0] pc;
output [31:0] insn;

reg [12:0] rpc;
reg [63:0] icache_ram [1023:0];
always @(posedge wclk)
	if (wr) icache_ram [wa[12:3]] <= i;
always @(posedge rclk)
	rpc <= pc;
wire [63:0] ico = icache_ram[rpc[12:3]];
assign insn = rpc[2] ? ico[63:32] : ico[31:0];

endmodule

module FISA64_itag_ram(wclk, wa, v, wr, rclk, pc, hit);
input wclk;
input [31:0] wa;
input v;
input wr;
input rclk;
input [31:0] pc;
output hit;

reg [31:0] rpc;
reg [32:13] itag_ram [511:0];
always @(posedge wclk)
	if (wr) itag_ram[wa[12:4]] <= {v,wa[31:13]};
always @(posedge rclk)
	rpc <= pc;
wire [32:13] tag_out = itag_ram[rpc[12:4]];
assign hit = tag_out=={1'b1,rpc[31:13]};

endmodule

module FISA64_bitfield(op, a, b, imm, m, o, masko);
parameter DWIDTH=64;
input [2:0] op;
input [DWIDTH-1:0] a;
input [DWIDTH-1:0] b;
input [DWIDTH-1:0] imm;
input [15:0] m;
output [DWIDTH-1:0] o;
reg [DWIDTH-1:0] o;
output [DWIDTH-1:0] masko;

reg [DWIDTH-1:0] o1;
reg [DWIDTH-1:0] o2;

// generate mask
reg [DWIDTH-1:0] mask;
assign masko = mask;
wire [5:0] mb = m[ 5:0];
wire [5:0] me = m[11:6];
wire [5:0] ml = me-mb;		// mask length-1

integer nn,n;
always @(mb or me or nn)
	for (nn = 0; nn < DWIDTH; nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

always @(op,mask,b,a,imm,mb)
case (op)
`BFINS: 	begin
				o2 = a << mb;
				for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : b[n]);
			end
`BFINSI: 	begin
				o2 = imm << mb;
				for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : b[n]);
			end
`BFSET: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b1 : a[n]; end
`BFCLR: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b0 : a[n]; end
`BFCHG: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? ~a[n] : a[n]; end
`BFEXTU:	begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o = o1 >> mb;
			end
`BFEXT:		begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o2 = o1 >> mb;
				for (n = 0; n < DWIDTH; n = n + 1)
					o[n] = n > ml ? o2[ml] : o2[n];
			end
`ifdef I_SEXT
`SEXT:		begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? a[mb] : a[n]; end
`endif
default:	o = {DWIDTH{1'b0}};
endcase

endmodule

module FISA64_BranchHistory(rst, clk, advanceX, xir, pc, xpc, takb, predict_taken);
input rst;
input clk;
input advanceX;
input [31:0] xir;
input [63:0] pc;
input [63:0] xpc;
input takb;
output predict_taken;

integer n;
reg [2:0] gbl_branch_hist;
reg [1:0] branch_history_table [255:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
	for (n = 0; n < 256; n = n + 1)
		branch_history_table[n] = 0;
end
wire [7:0] bht_wa = {xpc[7:2],gbl_branch_hist[2:1]};		// write address
wire [7:0] bht_ra1 = {xpc[7:2],gbl_branch_hist[2:1]};		// read address (EX stage)
wire [7:0] bht_ra2 = {pc[7:2],gbl_branch_hist[2:1]};	// read address (IF stage)
wire [1:0] bht_xbits = branch_history_table[bht_ra1];
wire [1:0] bht_ibits = branch_history_table[bht_ra2];
assign predict_taken = bht_ibits==2'd0 || bht_ibits==2'd1;

wire [6:0] xOpcode = xir[6:0];
wire isxBranch = (xOpcode==`Bcc);

// Two bit saturating counter
reg [1:0] xbits_new;
always @(takb or bht_xbits)
if (takb) begin
	if (bht_xbits != 2'd1)
		xbits_new <= bht_xbits + 2'd1;
	else
		xbits_new <= bht_xbits;
end
else begin
	if (bht_xbits != 2'd2)
		xbits_new <= bht_xbits - 2'd1;
	else
		xbits_new <= bht_xbits;
end

always @(posedge clk)
if (rst)
	gbl_branch_hist <= 3'b000;
else begin
	if (advanceX) begin
		if (isxBranch) begin
			gbl_branch_hist <= {gbl_branch_hist[1:0],takb};
			branch_history_table[bht_wa] <= xbits_new;
		end
	end
end

endmodule

module FISA64_shift(xir, a, b, res, rolo);
input [31:0] xir;
input [63:0] a;
input [63:0] b;
output [63:0] res;
reg [63:0] res;
output [63:0] rolo;

wire [6:0] xopcode = xir[6:0];
wire [6:0] xfunc = xir[31:25];

wire isImm = xfunc==`SLLI || xfunc==`SRLI || xfunc==`SRAI || xfunc==`ROLI || xfunc==`RORI;

wire [127:0] shl = {64'd0,a} << (isImm ? xir[22:17] : b[5:0]);
wire [127:0] shr = {a,64'd0} >> (isImm ? xir[22:17] : b[5:0]);

always @*
case(xopcode)
`RR:
	case(xfunc)
	`SLLI:	res <= shl[63:0];
	`SLL:	res <= shl[63:0];
	`SRLI:	res <= shr[127:64];
	`SRL:	res <= shr[127:64];
	`SRAI:	if (a[63])
				res <= (shr[127:64]) | ~(64'hFFFFFFFFFFFFFFFF >> xir[22:17]);
			else
				res <= shr[127:64];
	`SRA:	if (a[63])
				res <= (shr[127:64]) | ~(64'hFFFFFFFFFFFFFFFF >> b[5:0]);
			else
				res <= shr[127:64];
	`ROL:	res <= shl[63:0]|shl[127:64];
	`ROLI:	res <= shl[63:0]|shl[127:64];
	`ROR:	res <= shr[63:0]|shr[127:64];
	`RORI:	res <= shr[63:0]|shr[127:64];
	default:	res <= 64'd0;
	endcase
default:	res <= 64'd0;
endcase

endmodule

module FISA64_logic(xir, a, b, imm, res);
input [31:0] xir;
input [63:0] a;
input [63:0] b;
input [63:0] imm;
output [63:0] res;
reg [63:0] res;

wire [6:0] xopcode = xir[6:0];
wire [6:0] xfunc = xir[31:25];

always @*
case(xopcode)
`RR:
	case(xfunc)
	`NOT:	res <= ~|a;
	`AND:	res <= a & b;
	`OR:	res <= a | b;
	`EOR:	res <= a ^ b;
	`NAND:	res <= ~(a & b);
	`NOR:	res <= ~(a | b);
	`ENOR:	res <= ~(a ^ b);
	default:	res <= 64'd0;
	endcase
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`EOR:	res <= a ^ imm;
default:	res <= 64'd0;
endcase

endmodule

