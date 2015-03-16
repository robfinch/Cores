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
`define ADD		7'h04
`define SUB		7'h05
`define CMP		7'h06
`define MUL		7'h07
`define DIV		7'h08
`define MOD		7'h09
`define LDI		7'h0A
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

module FISA64(rst_i, clk_i, clk_o, nmi_i, irq_i, vect_i, bte_o, cti_o, bl_o, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o);
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
reg pe;						// protected mode enabled
reg im;						// interrupt mask
reg [2:0] imcd;				// interrupt enable count down
reg [AMSB:0] pc,dpc,xpc,wpc;
reg [AMSB:0] epc,ipc,dbpc;	// exception, interrupt PC's, debug PC
reg gie;					// global interrupt enable
reg StatusHWI;
reg [31:4] ibufadr;
reg [127:0] ibuf;
reg [63:0] regfile [31:0];
reg [63:0] sp;
reg [31:0] ir,xir,mir,wir;
wire [6:0] iopcode = insn[6:0];
wire [6:0] opcode = ir[6:0];
wire [6:0] funct = ir[31:25];
reg [6:0] xfunct,mfunct;
reg [6:0] xopcode,mopcode,wopcode;
wire [4:0] Ra = ir[11:7];
wire [4:0] Rb = ir[21:17];
wire [4:0] Rc = ir[16:12];
reg [4:0] xRt,mRt,wRt;
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] res,ea,xres,mres,wres,lres;
always @*
case(Ra)
5'd0:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
default:	rfoa <= regfile[Ra];
endcase
always @*
case(Rb)
5'd0:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
default:	rfob <= regfile[Rb];
endcase
always @*
case(Rc)
5'd0:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
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

// Stall the pipeline if there's an immediate prefix in it during a cache miss.
wire stallPipe =
	((opcode==`IMM && xopcode==`IMM) ||
	 (opcode==`IMM)) && !ihit;

reg advanceEXr;
reg advanceWBx;
wire advanceWB = (advanceEX|advanceWBx) & !stallPipe;
wire advanceEX = advanceEXr& !stallPipe;
wire advanceRF = advanceEX & !stallPipe;
wire advanceIF = advanceRF & ihit;

reg isICacheReset;
reg isICacheLoad;
wire [31:0] insn;
wire ihit;

FISA64_icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & ack_i),
	.i(dat_i),
	.rclk(~clk),
	.pc(pc[12:0]),
	.insn(insn)
);

FISA64_itag_ram u2
(
	.wclk(clk),
	.wa(adr_o),
	.v(!isICacheReset),
	.wr((isICacheLoad & ack_i && (adr_o[3]==1'b1))|isICacheReset),
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

always @*
case(xopcode)
`BSR:	res <= xpc + 64'd4;
`JAL:	res <= xpc + 64'd4;
`RTS:	res <= c + imm;
`ADD:	res <= a + imm;
`ADDU:	res <= a + imm;
`SUB:	res <= a - imm;
`SUBU:	res <= a - imm;
`CMP:	res <= lti ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
`CMPU:	res <= ltui ? 64'hFFFFFFFFFFFFFFFF : eqi ? 64'd0 : 64'd1;
`AND:	res <= a & imm;
`OR:	res <= a | imm;
`EOR:	res <= a ^ imm;
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
	case(xfunct)
	`MFSPR:
		if (km) begin
			case(xir[24:17])
			`CR0:		res <= pe;
			`TICK:		res <= tick;
			`CLK:		res <= clk_throttle_new;
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
	`AND:	res <= a & b;
	`OR:	res <= a | b;
	`EOR:	res <= a ^ b;
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
	`SLLI:	res <= a << xir[22:17];
	`SLL:	res <= a << b[5:0];
	`SRLI:	res <= a >> xir[22:17];
	`SRL:	res <= a >> b[5:0];
	`SRAI:	if (a[63])
				res <= (a >> xir[22:17]) | ~(64'hFFFFFFFFFFFFFFFF >> xir[22:17]);
			else
				res <= a >> xir[22:17];
	`SRA:	if (a[63])
				res <= (a >> b[5:0]) | ~(64'hFFFFFFFFFFFFFFFF >> b[5:0]);
			else
				res <= a >> b[5:0];
	`SXB:	res <= {{56{a[7]}},a[7:0]};
	`SXC:	res <= {{48{a[15]}},a[15:0]};
	`SXH:	res <= {{32{a[31]}},a[31:0]};
	default:	res <= 64'd0;
	endcase
`BTFLD:	res <= btfldo;
`LEAX:	res <= a + (b << xir[23:22]) + imm;
`PUSH:	res <= c - 64'd8;
`PMW:	res <= c - 64'd8;
`PEA:	res <= c - 64'd8;
`POP:	res <= c + 64'd8;
default:	res <= 64'd0;
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
	pe <= `FALSE;
	pc <= 32'h10000;
	state <= RESET;
	nop_ir();
	nop_xir();
	wb_nack();
	adr_o[3] <= 1'b1;	// adr_o[3] must be set
	isICacheReset <= TRUE;
	isICacheLoad <= FALSE;
	advanceEXr <= TRUE;
	advanceWBx <= `FALSE;
	gie <= `FALSE;
	im <= `TRUE;
	imcd <= 3'b000;
	StatusHWI <= `FALSE;
	nmi1 <= `FALSE;
	nmi_edge <= `FALSE;
	ld_clk_throttle <= `FALSE;
	dbctrl <= 64'd0;
	dbstat <= 64'd0;
end
else begin
tick <= tick + 64'd1;
advanceWBx <= `FALSE;
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
	adr_o <= adr_o + 32'd16;
	if (adr_o[12:4]==9'h1ff) begin
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
		else if (!StatusHWI & gie & !im & irq_i)
			ir <= `BRK_IRQ;
		else if (db_imatch)
			ir <= `BRK_IBPT;
		else if (!((isLotOwnerX && (km ? lottagX[0] : lottagX[3])) || !pe))
			ir <= `BRK_EXF;
		else
			ir <= insn;
		$display("%h: %h", pc, insn);
		dpc <= pc;
		dbranch_taken <= FALSE;
		if (iopcode==`Bcc && predict_taken) begin
			pc <= pc + {{47{insn[31]}},insn[31:17],2'b00};
			dbranch_taken <= TRUE;
		end
		else if (iopcode==`BSR || iopcode==`BRA)
			pc <= pc + {{37{insn[31]}},insn[31:7],2'b00};
		else
			pc <= pc + 32'd4;
	end
	else begin
		// On a cache miss, return flow to the head of any immediate prefix
		if (!ihit)
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
		if (opcode==`MYST)
			xfunct <= mystreg;
		xpc <= dpc;
		a <= rfoa;
		b <= rfob;
		c <= rfoc;

		case(opcode)
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`LEAX,
		`SBX,`SCX,`SHX,`SWX:
			imm <= ir[31:24];
		default:	imm <= {{49{ir[31]}},ir[31:17]};
		endcase
		if (wopcode==`IMM && xopcode==`IMM) begin
			imm[63:15] <= {wir[31:7],xir[31:7]};
			xpc <= wpc;	// in case of interrupt
		end
		else if (xopcode==`IMM) begin
			imm[63:15] <= {{24{xir[31]}},xir[31:7]};
			xpc <= xpc;
		end

		case(opcode)
		`RR:
			case(funct)
			`MTSPR,`FENCE:
				xRt <= 5'd0;
			`PCTRL:
				xRt <= 5'd0;
			default:	xRt <= ir[16:12];
			endcase
		`BRA,`Bcc,`BRK,`IMM:
			xRt <= 5'd0;
		`SB,`SC,`SH,`SW,`SBX,`SCX,`SHX,`SWX,`INC:
			xRt <= 5'd0;
		`BSR:	xRt <= 5'h1F;
		default:	xRt <= ir[16:12];
		endcase
	end
	else if (advanceEX) begin
		nop_xir();
	end

	//-----------------------------------------------------------------------------
	// EXECUTE
	//-----------------------------------------------------------------------------
	if (advanceEX) begin
		wRt <= xRt;
		wres <= res;
		wir <= xir;
		wopcode <= xopcode;
		wpc <= xpc;
		if (ssm) begin
			nop_ir();
			nop_xir();
			xir <= `BRK_SSM;
		end
		case(xopcode)
		`RR:
			case(xfunct)
			`MTSPR:
				if (km) begin
					case(xir[24:17])
					`CR0:		pe <= a[0];
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
					
					`RTD:
						begin
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
							dbctrl[63] <= dbctrl[62];
							update_pc(dbpc);
						end
					`RTE:
						begin
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
							update_pc(epc);
						end
					`RTI:
						begin
							StatusHWI <= FALSE;
							imcd <= 3'b111;
							km <= kmb[0];
							kmb <= {1'b1,kmb[7:1]};
							update_pc(ipc);
						end
					endcase
				else
					privilege_violation();
			`ADD:	if (fnASOverflow(0,a[63],b[63],res[63]))
						overflow();
			`SUB:	if (fnASOverflow(1,a[63],b[63],res[63]))
						overflow();
			`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
					begin
					mopcode <= xopcode;
					mfunct <= xfunct;
					next_state(MULDIV);
					advanceEXr <= FALSE;
					end
			endcase
		`ADD:	if (fnASOverflow(0,a[63],imm[63],res[63]))
					overflow();
		`SUB:	if (fnASOverflow(1,a[63],imm[63],res[63]))
					overflow();
		`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
				begin
				mopcode <= xopcode;
				mfunct <= xfunct;
				next_state(MULDIV);
				advanceEXr <= FALSE;
				end
		`BSR,`BRA:	;//update_pc(xpc + imm); done already in IF
		`JAL:		update_pc(a + {imm,2'b00});
		`RTS:	begin
					update_pc(a);
					$display("RTS: pc<=%h", a);
				end
		`Bcc:	if (takb & !xbranch_taken)
					update_pc(xpc + {imm,2'b00});
				else if (!takb & xbranch_taken)
					update_pc(xpc + 64'd4);
		`BRK:	begin
				case(xir[31:30])
				2'b00:	epc <= xpc;
				2'b01:	dbpc <= xpc;
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
				dbctrl[62] <= dbctrl[63];
				dbctrl[63] <= FALSE;	// clear SSM
				kmb <= {kmb[6:0],km};
				km <= `TRUE;
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= {vbr[AMSB:12],xir[25:17],3'b000};
				ld_size <= word;
				next_state(LOAD1);
				end
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`INC:
				begin
				next_state(LOAD1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				case(xopcode)
				`LB,`LBU:	ld_size <= byt;
				`LC,`LCU:	ld_size <= char;
				`LH,`LHU:	ld_size <= half;
				`LW,`INC:	ld_size <= word;
				endcase
				end
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX:
				begin
				next_state(LOAD1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				ea <= a + (b << xir[23:22]) + imm;
				case(xopcode)
				`LBX,`LBUX:	ld_size <= byt;
				`LCX,`LCUX:	ld_size <= char;
				`LHX,`LHUX:	ld_size <= half;
				`LWX:		ld_size <= word;
				endcase
				end
		`CAS:	begin
				next_state(LOAD1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				ld_size <= word;
				st_size <= word;
				end
		`SB,`SC,`SH,`SW:
				begin
				next_state(STORE1);
				advanceEXr <= FALSE;
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
		`PUSH:
				begin
				next_state(STORE1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				ea <= res;
				xb <= a;
				st_size <= word;
				end
		`PMW:
				begin
				next_state(LOAD1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				advanceWBx <= TRUE;
				ld_size <= word;
				st_size <= word;
				end
		`PEA:
				begin
				next_state(STORE1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				ea <= res;
				xb <= a + imm;
				st_size <= word;
				end
		`POP:
				begin
				next_state(LOAD1);
				advanceEXr <= FALSE;
				mopcode <= xopcode;
				mir <= xir;
				ea <= c;
				advanceWBx <= TRUE;
				ld_size <= word;
				end
		`SBX,`SCX,`SHX,`SWX:
				begin
				next_state(STORE1);
				advanceEXr <= FALSE;
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
/*
	// Omitting this code makes the writeback stage "sticky" - it remembers
	// the last register update, and will be present on the bypass muxes.
	// This is a harmless behaviour. This is used by memory ops (eg. pop)
	// to update two registers with one instruction.

	else if (advanceWB) begin
		wRt <= 5'd0;
		wres <= 64'd0;
	end
*/
	// WRITEBACK
	if (advanceWB) begin
		regfile[wRt] <= wres;
		if (wRt==5'd30)	// write to SP globally enables interrupts
			gie <= `TRUE;
		if (wRt != 5'd0)
			$display("r%d = %h", wRt, wres);
	end

end	// RUN

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide / Modulus machine states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MULDIV:
	begin
		cnt <= 7'd64;
		case(mopcode)
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
			case(mfunct)
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
//					if (b==64'd0)
//						divide_by_zero();
//					else
						next_state(DIV);
				end
			default:
				begin
				advanceEXr <= TRUE;
				state <= RUN;
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
		if (mopcode==`MUL || mopcode==`MULU || (mopcode==`RR && (mfunct==`MUL || mfunct==`MULU)))
			wres <= p[63:0];
		else if (mopcode==`DIV || mopcode==`DIVU || (mopcode==`RR && (mfunct==`DIV || mfunct==`DIVU)))
			wres <= q[63:0];
		else
			wres <= r[63:0];
		advanceEXr <= TRUE;
		next_state(RUN);
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
	if (ack_i) begin
		case(mopcode)
		`LB,`LBX:
			begin
			wb_nack();
			next_state(RUN);
			advanceEXr <= TRUE;
			case(ea[2:0])
			3'd0:	wres <= {{56{dat_i[7]}},dat_i[7:0]};
			3'd1:	wres <= {{56{dat_i[15]}},dat_i[15:8]};
			3'd2:	wres <= {{56{dat_i[23]}},dat_i[23:16]};
			3'd3:	wres <= {{56{dat_i[31]}},dat_i[31:24]};
			3'd4:	wres <= {{56{dat_i[39]}},dat_i[39:32]};
			3'd5:	wres <= {{56{dat_i[47]}},dat_i[47:40]};
			3'd6:	wres <= {{56{dat_i[55]}},dat_i[55:48]};
			3'd7:	wres <= {{56{dat_i[63]}},dat_i[63:56]};
			endcase
			end
		`LBU,`LBUX:
			begin
			wb_nack();
			next_state(RUN);
			advanceEXr <= TRUE;
			case(ea[2:0])
			3'd0:	wres <= dat_i[7:0];
			3'd1:	wres <= dat_i[15:8];
			3'd2:	wres <= dat_i[23:16];
			3'd3:	wres <= dat_i[31:24];
			3'd4:	wres <= dat_i[39:32];
			3'd5:	wres <= dat_i[47:40];
			3'd6:	wres <= dat_i[55:48];
			3'd7:	wres <= dat_i[63:56];
			endcase
			end
		`LC,`LCX:
			case(ea[2:0])
			3'd0:	begin wres <= {{48{dat_i[15]}},dat_i[15:0]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd1:	begin wres <= {{48{dat_i[23]}},dat_i[23:8]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd2:	begin wres <= {{48{dat_i[31]}},dat_i[31:16]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd3:	begin wres <= {{48{dat_i[39]}},dat_i[39:24]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd4:	begin wres <= {{48{dat_i[47]}},dat_i[47:32]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd5:	begin wres <= {{48{dat_i[55]}},dat_i[55:40]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd6:	begin wres <= {{48{dat_i[63]}},dat_i[63:48]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd7:	begin wres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LCU,`LCUX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[15:0]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd1:	begin wres <= dat_i[23:8]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd2:	begin wres <= dat_i[31:16]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd3:	begin wres <= dat_i[39:24]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd4:	begin wres <= dat_i[47:32]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd5:	begin wres <= dat_i[55:40]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd6:	begin wres <= dat_i[63:48]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd7:	begin wres[7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LH,`LHX:
			case(ea[2:0])
			3'd0:	begin wres <= {{32{dat_i[31]}},dat_i[31:0]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd1:	begin wres <= {{32{dat_i[39]}},dat_i[39:8]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd2:	begin wres <= {{32{dat_i[47]}},dat_i[47:16]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd3:	begin wres <= {{32{dat_i[55]}},dat_i[55:24]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd4:	begin wres <= {{32{dat_i[63]}},dat_i[63:32]}; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[31:0]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd1:	begin wres <= dat_i[39:8]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd2:	begin wres <= dat_i[47:16]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd3:	begin wres <= dat_i[55:24]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd4:	begin wres <= dat_i[63:32]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[63:0]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
			3'd1:	begin wres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin wres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin wres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin wres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`INC:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[63:0]; next_state(INC); wb_half_nack(); end
			3'd1:	begin wres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin wres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin wres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin wres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		`PMW:
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
					update_pc(dat_i[63:0]);
					next_state(RUN);
					wb_nack();
					advanceEXr <= TRUE;
					km <= `TRUE;
					kmb <= {kmb[6:0],km};
				end
		`POP:	begin wRt <= mir[11:7]; wres <= dat_i[63:0]; next_state(RUN); wb_nack(); advanceEXr <= TRUE; end
		`CAS:
			case(ea[2:0])
			3'd0:	begin wres <= dat_i[63:0]; next_state(CAS); wb_nack(); end
			3'd1:	begin wres[55:0] <= dat_i[63:8]; next_state(LOAD4); wb_half_nack(); end
			3'd2:	begin wres[47:0] <= dat_i[63:16]; next_state(LOAD4); wb_half_nack(); end
			3'd3:	begin wres[39:0] <= dat_i[63:24]; next_state(LOAD4); wb_half_nack(); end
			3'd4:	begin wres[31:0] <= dat_i[63:32]; next_state(LOAD4); wb_half_nack(); end
			3'd5:	begin wres[23:0] <= dat_i[63:40]; next_state(LOAD4); wb_half_nack(); end
			3'd6:	begin wres[15:0] <= dat_i[63:48]; next_state(LOAD4); wb_half_nack(); end
			3'd7:	begin wres[ 7:0] <= dat_i[63:56]; next_state(LOAD4); wb_half_nack(); end
			endcase
		endcase
	end
LOAD4:
	begin
		wb_read2(ld_size,ea);
		next_state(LOAD5);
	end
LOAD5:
	if (ack_i) begin
		if (mopcode==`INC) begin
			wb_half_nack();
			next_state(INC);
		end
		else if (mopcode==`PMW) begin
			wb_nack();
			next_state(PMW);
		end
		else if (mopcode==`CAS) begin
			wb_nack();
			next_state(CAS);
		end
		else begin
			wb_nack();
			next_state(RUN);
			advanceEXr <= TRUE;
		end
		case(mopcode)
		`LC,`LCX:	wres[63:8] <= {{48{dat_i[7]}},dat_i[7:0]};
		`LCU,`LCUX:	wres[63:8] <= dat_i[7:0];
		`LH,`LHX:
			case(ea[2:0])
			3'd5:	wres[63:24] <= {{32{dat_i[7]}},dat_i[7:0]};
			3'd6:	wres[63:16] <= {{32{dat_i[15]}},dat_i[15:0]};
			3'd7:	wres[63: 8] <= {{32{dat_i[23]}},dat_i[23:0]};
			default:	;
			endcase
		`LHU,`LHUX:
			case(ea[2:0])
			3'd5:	wres[63:24] <= dat_i[7:0];
			3'd6:	wres[63:16] <= dat_i[15:0];
			3'd7:	wres[63: 8] <= dat_i[23:0];
			default:	;
			endcase
		`LW,`LWX:
			case(ea[2:0])
			3'd0:	;
			3'd1:	wres[63:56] <= dat_i[7:0];
			3'd2:	wres[63:48] <= dat_i[15:0];
			3'd3:	wres[63:40] <= dat_i[23:0];
			3'd4:	wres[63:32] <= dat_i[31:0];
			3'd5:	wres[63:24] <= dat_i[39:0];
			3'd6:	wres[63:16] <= dat_i[47:0];
			3'd7:	wres[63: 8] <= dat_i[55:0];
			endcase
		`INC,`CAS:
			case(ea[2:0])
			3'd0:	;
			3'd1:	wres[63:56] <= dat_i[7:0];
			3'd2:	wres[63:48] <= dat_i[15:0];
			3'd3:	wres[63:40] <= dat_i[23:0];
			3'd4:	wres[63:32] <= dat_i[31:0];
			3'd5:	wres[63:24] <= dat_i[39:0];
			3'd6:	wres[63:16] <= dat_i[47:0];
			3'd7:	wres[63: 8] <= dat_i[55:0];
			endcase
		`PMW:
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
		xb <= wres + {{59{mir[16]}},mir[16:12]};
		next_state(STORE2);	// We don't need to wait for the ea address calc
	end
PMW:
	begin
		ea <= wres;
		xb <= lres;
		next_state(STORE1);	// We changed the ea so we need another cycle 
	end
CAS:
	begin
		if (casreg == wres) begin
			wres <= 64'd1;
			xb <= c;
			next_state(STORE2);
		end
		else begin
			casreg <= wres;
			wres <= 64'd0;
			wb_nack();
			advanceEXr <= TRUE;
			next_state(RUN);
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
	if (ack_i) begin
		if ((st_size==char && ea[2:0]==3'b111) ||
			(st_size==half && ea[2:0]>3'd4) ||
			(st_size==word && ea[2:0]!=3'b00)) begin
			wb_half_nack();
			next_state(STORE4);
		end
		else begin
			wb_nack();
			advanceEXr <= TRUE;
			next_state(RUN);
		end
	end
STORE4:
	begin
		wb_write2(st_size,ea,xb);
		next_state(STORE5);
	end
STORE5:
	if (ack_i) begin
		wb_nack();
		advanceEXr <= TRUE;
		next_state(RUN);
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache load states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD_ICACHE:
	begin
		isICacheLoad <= TRUE;
		wb_read1(word,{pc[AMSB:4],4'h0});
		next_state(LOAD_ICACHE2);
	end
LOAD_ICACHE2:
	if (ack_i) begin
		wb_half_nack();
		next_state(LOAD_ICACHE3);
	end
LOAD_ICACHE3:
	begin
		wb_read1(word,{pc[AMSB:4],4'h8});
		next_state(LOAD_ICACHE4);
	end
LOAD_ICACHE4:
	if (ack_i) begin
		wb_nack();
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
	sel_o <= 8'h00;
	adr_o <= 32'd0;
	dat_o <= 64'd0;
end
endtask

task wb_half_nack;
begin
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 8'h00;
	adr_o <= 32'h0;
end
endtask

// Flush the RF stage

task nop_ir;
begin
	ir <= {25'h0,7'h3F};	// NOP
end
endtask

// Flush the EX stage

task nop_xir;
begin
	xopcode <= 7'h3F;
	xRt <= 6'b0;
	xir <= {25'h0,7'h3F};	// NOP
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
	nop_xir();
	if (ssm)
		xir <= `BRK_SSM;
end
endtask

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task privilege_violation;
begin
	epc <= xpc;
	advanceEXr <= FALSE;
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
	advanceEXr <= FALSE;
	mopcode <= `BRK;
	mir <= xir;
	ea <= {vbr[AMSB:12],9'd489,3'b000};	// overflow violation
	ld_size <= word;
	next_state(LOAD1);
end
endtask

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Debugging aid - pretty state names
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET ";
RUN:	fnStateName = "RUN ";
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
endcase
endfunction

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


