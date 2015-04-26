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
//`define DEBUG_COP	1'b1
//`define FLOAT	1'b1

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
`define CHKI    7'h0B
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
`define LDFI	7'h1A
`define CHK			7'h1A
`define MTFP	    7'h1C
`define MV2FLT		7'h1D
`define MTSPR		7'h1E
`define MFSPR		7'h1F
`define MOV2	7'b010000x
`define ADDQ	7'h22
`define MYST	7'h24
`define RTL		7'h27
`define FADD	7'h28
`define FSUB	7'h29
`define FCMP	7'h2A
`define FMUL	7'h2B
`define FDIV	7'h2C
`define RTS2	7'h30
`define PUSHPOP	7'h31
`define BEQS	7'h32
`define BNES	7'h33
`define LDIQ	7'h34
`define RTL2	7'h37
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
`define BUN			3'h6
`define JALI	7'h3E
`define NOP		7'h3F
`define SLL			7'h30
`define SRL			7'h31
`define ROL			7'h32
`define ROR			7'h33
`define SRA			7'h34
`define CPUID		7'h36
`define PCTRL		7'h37
`define CLI				5'd0
`define SEI				5'd1
`define STP				5'd2
`define WAI             5'd3
`define EIC				5'd4
`define DIC				5'd5
`define SRI				5'd8
`define FIP				5'd10
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
`define LEA		7'h47
`define LBX		7'h48
`define LBUX	7'h49
`define LCX		7'h4A
`define LCUX	7'h4B
`define LHX		7'h4C
`define LHUX	7'h4D
`define LWX		7'h4E
`define LEAX	7'h4F
`define LFD		7'h51
`define PUSHF	7'h54
`define POPF	7'h55
`define POP		7'h57
`define LFDX	7'h59
`define LWAR	7'h5C
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
`define SWCR	7'h6E
`define INCX	7'h6F
`define SFD		7'h71
`define SFDX	7'h75

`define FIX2FLT		7'h60
`define FLT2FIX		7'h61
`define FMOV		7'h62
`define FNEG		7'h63
`define FABS		7'h64
`define MFFP		7'h65
`define MV2FIX		7'h66

`define IMM		7'b1111xxx

`define CR0			8'd00
`define CR3			8'd03
`define TICK		8'd04
`define CLK			8'd06
`define DBPC		8'd07
`define IPC			8'd08
`define EPC			8'd09
`define VBR			8'd10
`define BEAR		8'd11
`define VECNO		8'd12
`define MULH		8'd14
`define ISP			8'd15
`define DSP			8'd16
`define ESP			8'd17
`define FPSCR		8'd20
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
//0000_0011_1100_1110_00001111_00111000;
//03cc0f38
`define BRK_BND	{6'd0,9'd487,5'd0,5'h1E,`BRK}
`define BRK_DBZ	{6'd0,9'd488,5'd0,5'h1E,`BRK}
`define BRK_OFL	{6'd0,9'd489,5'd0,5'h1E,`BRK}
`define BRK_FLT	{6'd0,9'd493,5'd0,5'h1E,`BRK}
`define BRK_TAP	{2'b01,4'd0,9'd494,5'd0,5'h1E,`BRK}
`define BRK_SSM	{2'b01,4'd0,9'd495,5'd0,5'h1E,`BRK}
`define BRK_BPT	{2'b01,4'd0,9'd496,5'd0,5'h1E,`BRK}
`define BRK_EXF	{6'd0,9'd497,5'd0,5'h1E,`BRK}
`define BRK_DWF	{6'd0,9'd498,5'd0,5'h1E,`BRK}
`define BRK_DRF	{6'd0,9'd499,5'd0,5'h1E,`BRK}
`define BRK_PRV	{6'd0,9'd501,5'd0,5'h1E,`BRK}
`define BRK_DBE	{1'b1,5'd0,9'd508,5'd0,5'h1E,`BRK}
`define BRK_IBE	{1'b1,5'd0,9'd509,5'd0,5'h1E,`BRK}
`define BRK_NMI	{1'b1,5'd0,9'd510,5'd0,5'h1E,`BRK}
`define BRK_IRQ	{1'b1,5'd0,vect_i,5'd0,5'h1E,`BRK}

module FISA64(rack_num,box_num,board_num,chip_num,core_num,
	rst_i, clk_i, clk3x_i, clk_o, nmi_i, irq_i, vect_i, sri_o, bte_o, cti_o, bl_o,
	cyc_o, stb_o, ack_i, err_i, we_o, sel_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i,
	tap_i, tap_o);
parameter AMSB = 31;		// most significant address bit
input [15:0] rack_num;
input [7:0] box_num;
input [7:0] board_num;
input [7:0] chip_num;
input [15:0] core_num;
input rst_i;
input clk_i;
input clk3x_i;
output clk_o;				// gated clock output
input nmi_i;
input irq_i;
input [8:0] vect_i;
output reg sri_o;
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
output reg sr_o;
output reg cr_o;
input rb_i;
input tap_i;
output tap_o;

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
parameter FLT1 = 6'd39;
parameter FLT2 = 6'd40;
parameter FLT3 = 6'd41;
parameter LOAD_ICACHE5 = 6'd42;
parameter LOAD_ICACHE6 = 6'd43;
parameter LOAD_ICACHE7 = 6'd44;
parameter LOAD_ICACHE8 = 6'd45;
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
reg [AMSB:0] bear;			// bus error address register
reg ssm;					// single step mode
reg km;						// kernel mode
reg [63:0] cr0;
wire pe = cr0[0];			// protected mode enabled
wire bpe = cr0[32];			// branch predictor enable
wire ice = cr0[30];			// instruction cache enable
wire rb = cr0[36];
wire ovf_xe = cr0[40];		// overflow exception enable
wire dbz_xe = cr0[41];		// divide by zero exception enable
reg im;						// interrupt mask
reg [2:0] imcd;				// interrupt enable count down
reg [1:0] sscd;				// single step count down
reg [8:0] vecno;
reg tapi1;
reg tap_nmi_edge;
reg tam;					// test access mode
reg [AMSB:0] pc,dpc,xpc,wpc;
reg [AMSB:0] epc,ipc,dbpc;	// exception, interrupt PC's, debug PC
reg [AMSB:0] isp,dsp,esp;	// stack pointer save areas
reg gie;					// global interrupt enable
reg StatusHWI;
reg [AMSB:0] ibufadr;
reg [31:0] ibuf;
wire ibufhit = pc[AMSB:1]==ibufadr[AMSB:1];
reg [63:0] regfile [63:0];
reg [63:0] sp,usp;
reg [4:0] regSP,regTR;
reg [63:0] sp_inc;
reg [31:0] ir,xir,mir,wir;
wire [31:0] iir = ice ? insn : ibuf;
wire [6:0] iopcode = iir[6:0];
wire [6:0] opcode = ir[6:0];
wire [6:0] ifunct = iir[31:25];
wire [6:0] funct = ir[31:25];
reg [6:0] xfunct,mfunct,mdfunct,x1funct;
reg [6:0] xopcode,mopcode,wopcode,mdopcode,x1opcode;
`ifdef FLOAT
wire fltRega = (opcode==`RR && funct[6:4]==3'd6) || opcode==`PUSHF || opcode==`FADD || opcode==FSUB || opcode==FCMP || opcode==`FMUL || opcode==`FDIV;
wire fltRegb = (opcode==`RR && funct[6:4]==3'd6) || opcode==`FADD || opcode==FSUB || opcode==FCMP || opcode==`FMUL || opcode==`FDIV;
wire fltRegc = (opcode==`RR && funct[6:4]==3'd6) || opcode==`SFD || opcode==`SFDX;
`else
wire fltRega = 1'b0;
wire fltRegb = 1'b0;
wire fltRegc = 1'b0;
`endif
wire isPush = opcode==7'h31 && ir[15:13]==3'd0;
wire isPop = opcode==7'h31 && ir[15:13]==3'd1;
wire isRts2 = opcode==`RTS2;
wire isRtl2 = opcode==`RTL2;
wire [5:0] Ra = isPop|isRts2 ? 6'h1E : {fltRega,ir[11:7]};
wire [5:0] Rb = {fltRegb,ir[21:17]};
wire [5:0] Rc = isPush ? 6'h1E : isRtl2 ? 6'h1F : {fltRegc,ir[16:12]};
reg [5:0] xRt,mRt,wRt,tRt,uRt;
reg xRt2,wRt2,tRt2;
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] res,res2,ea,xres,mres,wres,lres,md_res,wres2,tres,tres2,ures;
reg xisImm,wisImm,tisImm;
reg mc_done;
always @*
case(Ra)
6'd0:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
tRt:	rfoa <= tres;
uRt:	rfoa <= ures;
6'd30:	if (xRt2)
			rfoa <= res2;
		else if (wRt2)
			rfoa <= wres2;
		else if (tRt2)
			rfoa <= tres2;
		else 
			rfoa <= sp;
default:	rfoa <= regfile[Ra];
endcase
always @*
case(Rb)
6'd0:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
tRt:	rfob <= tres;
uRt:	rfob <= ures;
6'd30:	if (xRt2)
			rfob <= res2;
		else if (wRt2)
			rfob <= wres2;
		else if (tRt2)
			rfob <= tres2;
		else
			rfob <= sp;
default:	rfob <= regfile[Rb];
endcase
always @*
case(Rc)
6'd0:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
tRt:	rfoc <= tres;
uRt:	rfoc <= ures;
6'd30:	if (xRt2)
			rfoc <= res2;
		else if (wRt2)
			rfoc <= wres2;
		else if (tRt2)
			rfoc <= tres2;
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
reg [3:0] sri_cnt;

wire dimm = opcode[6:3]==4'hF;
wire ximm = xopcode[6:3]==4'hF;

// Detect multi-cycle operation.
function fnIsMC;
input [6:0] opcode;
input [6:0] funct;
case(opcode)
`RR:
	case(funct)
	`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:	fnIsMC = TRUE;
`ifdef FLOAT
	`FIX2FLT,`FLT2FIX,`MV2FIX,`MV2FLT:  fnIsMC = TRUE;
`endif
	default:	fnIsMC = FALSE;
	endcase
`BRK,
`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU,
`PUSHPOP,
`PUSH,`PMW,`PEA,`POP,`RTS,`RTS2,
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWAR,`INC,`CAS,`JALI,`INCX,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,
`SB,`SC,`SH,`SW,`SWCR,`SBX,`SCX,`SHX,`SWX
`ifdef FLOAT
,`FADD,`FSUB,`FMUL,`FDIV,`FCMP,
`PUSHF,`POPF,
`LFD,`LFDX,`SFD,`SFDX
`endif
	:
	fnIsMC = TRUE;
default:	fnIsMC = FALSE;
endcase
endfunction

wire iihit;
// Stall the pipeline if there's an immediate prefix in it during a cache miss.
wire stallRF = 
	((opcode[6:3]==4'hF && xopcode[6:3]==4'hF) ||
	 (opcode[6:3]==4'hF)) && !iihit;

wire advanceEX = !fnIsMC(xopcode,xfunct) & !stallRF;
wire advanceWB = (xRt!=6'd0 || xRt2) && advanceEX;
wire advanceTL = advanceWB;
wire advanceRF = !stallRF & advanceEX;
wire advanceIF = advanceRF & iihit;

//-----------------------------------------------------------------------------
// Instruction Cache
//-----------------------------------------------------------------------------

reg isICacheReset;
reg isICacheLoad;
wire [31:0] insn;
wire [31:0] dbg_insn;
wire ihit,ihit2;
assign iihit = (ice ? ihit&ihit2 : ibufhit);
reg utg;			// update cache tag
reg [AMSB:0] tagadr;

FISA64_icache_ram u1
(
	.wclk(clk),
	.wa(adr_o[12:0]),
	.wr(isICacheLoad & (ack_i|err_i)),
	.i(err_i ? {2{`BRK_IBE}} : dat_i),
	.rclk(clk3x_i),
	.pc(pc[12:0]),
	.insn(insn)
);

FISA64_itag_ram u2
(
	.wclk(clk),
	.wa(tagadr),
	.v(!isICacheReset),
	.wr(utg|isICacheReset),
	.rclk(clk3x_i),
	.pc(pc),
	.hit(ihit),
	.hit2(ihit2)
);


//-----------------------------------------------------------------------------
// Debug (not working yet)
// The debug system is a processor on it's own.
// It's capable of loading a program via the test access point port into the
// debug sandbox. It can then generate a tap interrupt to the cpu. The master
// cpu will then execute the code in the debug sandbox. The sandbox is
// exited with a RTD instruction.
// ToDo: add a PIO port so the debug processor can control things.
//-----------------------------------------------------------------------------
reg d63,x63,w63;
reg tap_nmi;
`ifdef DEBUG_COP
reg dbg_ram_ack,dbg_rom_ack,dbg_ser_ack;
wire dbg16_cyc,dbg16_stb,dbg16_we;
wire [23:0] dbg16_adr;
wire [15:0] dbg16_dato;
reg [15:0] dbg16_dati;
wire [15:0] dbg_ramoL,dbg_ramoH,dbg16_insn,dr16_dato;
wire [7:0] dbg_ser_dato;
wire cs_dbg_iram = dbg16_cyc && dbg16_stb && dbg16_adr[23:12]==12'h00F;	// places ram at $F000
wire cs_dbg_irom = dbg16_cyc && dbg16_stb && dbg16_adr[23:16]==8'h1;	// places rom at $10000
wire cs_dbg_pio =  dbg16_cyc && dbg16_stb && dbg16_adr[23:8]==16'h00D0;	// Uart is at $E000
wire cs_dbg_dram = dbg16_cyc && dbg16_stb && dbg16_adr[23:15]==9'h000;	// readback ram at $0000 to $3FFF
wire cs_cpu_dram = cyc_o && stb_o && adr_o[AMSB:16]==16'hFFE0;

always @(posedge clk_i)
if (rst)
	dbg_ram_ack <= 1'b0;
else
	dbg_ram_ack <= cs_dbg_iram & ~dbg_ram_ack;
always @(posedge clk_i)
if (rst)
	dbg_rom_ack <= 1'b0;
else
	dbg_rom_ack <= cs_dbg_irom & ~dbg_rom_ack;

always @*
	if (cs_dbg_iram && ~dbg16_adr[1])
		dbg16_dati <= dbg_ramoL;
	else if (cs_dbg_iram && dbg16_adr[1])
		dbg16_dati <= dbg_ramoH;
	else if (cs_dbg_irom)
		dbg16_dati <= dbg16_insn;
	else if (cs_dbg_dram)
		dbg16_dati <= dr16_dato;
	else
		dbg16_dati <= dbg_ser_dato;

always @(posedge clk_i)
if (rst)
	tap_nmi <= FALSE;
else begin
	if (cs_dbg_pio) begin
		tap_nmi <= dbg16_dato[0];
	end
end

assign dbg16_acki = dbg_ram_ack|dbg_rom_ack|dbg_ser_ack|cs_dbg_dram;

FISA64_debug_iram u8
(
	.wclk(clk_i),
	.rwa(dbg16_adr[11:0]),
	.wr(cs_dbg_ram && dbg16_we && ~dbg16_adr[1]),
	.i(dbg16_dato),
	.o(dbg_ramoL),
	.rclk(clk3x_i),
	.pc(pc),
	.insn(dbg_insn[15:0])
);

FISA64_debug_iram u9
(
	.wclk(clk_i),
	.rwa(dbg16_adr[11:0]),
	.wr(cs_dbg_ram && dbg16_we && dbg16_adr[1]),
	.i(dbg16_dato),
	.o(dbg_ramoH),
	.rclk(clk3x_i),
	.pc(pc),
	.insn(dbg_insn[31:16])
);

FISA64_debug_dram
(
	.wclk(clk),
	.rwa(adr_o[13:0]),
	.wr(we_o && cs_cpu_dram),
	.sel(sel_o),
	.i(dat_o),
	.o(),
	.rclk(clk3x_i),
	.ea(dbg16_adr[13:0]),
	.dat(dr16_dato)
);


FISA64_debug_rom u10
(
	.clk(clk3x_i),
	.pc(dbg16_adr[11:0]),
	.insn(dbg16_insn)
);

dbg16 u11
(
	.rst_i(rst),
	.clk_i(clk_i),
	.cyc_o(dbg16_cyc),
	.stb_o(dbg16_stb),
	.ack_i(dbg16_acki),
	.we_o(dbg16_we),
	.adr_o(dbg16_adr),
	.dat_i(dbg16_dati),
	.dat_o(dbg16_dato)
);

rtfSimpleUart #(.pIOAddress(32'hFFDCE000)) u12
(
	.rst_i(rst),		// reset
	.clk_i(clk_i),		// eg 100.7MHz
	.cyc_i(dbg16_cyc),	// cycle valid
	.stb_i(dbg16_stb),	// strobe
	.we_i(dbg16_we),		// 1 = write
	.adr_i({16'hFFDC,dbg16_adr[15:0]}),		// register address
	.dat_i(dbg16_dato[7:0]),	// data input bus
	.dat_o(dbg_ser_dato),	// data output bus
	.ack_o(dbg_ser_ack),	// transfer acknowledge
	.vol_o(),		// volatile register selected
	.irq_o(),		// interrupt request
	//----------------
	.cts_ni(),		// clear to send - active low - (flow control)
	.rts_no(),	// request to send - active low - (flow control)
	.dsr_ni(),		// data set ready - active low
	.dcd_ni(),		// data carrier detect - active low
	.dtr_no(),	// data terminal ready - active low
	.rxd_i(tap_i),			// serial data in
	.txd_o(tap_o),			// serial data out
	.data_present_o()
);
`endif

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

wire db_imatch0 = (dbctrl[0] && dbctrl[17:16]==2'b00 && pc[AMSB:1]==dbad0[AMSB:1]);
wire db_imatch1 = (dbctrl[1] && dbctrl[21:20]==2'b00 && pc[AMSB:1]==dbad1[AMSB:1]);
wire db_imatch2 = (dbctrl[2] && dbctrl[25:24]==2'b00 && pc[AMSB:1]==dbad2[AMSB:1]);
wire db_imatch3 = (dbctrl[3] && dbctrl[29:28]==2'b00 && pc[AMSB:1]==dbad3[AMSB:1]);
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
// Floating point modules.
//-----------------------------------------------------------------------------

reg dbl_overflow_xe;
reg dbl_underflow_xe;
reg dbl_invalid_op_xe;
reg dbl_divide_by_zero_xe;

reg dbl_overflow_xo;
reg dbl_underflow_xo;
reg dbl_invalid_op_xo;
reg dbl_divide_by_zero_xo;
reg dbl_g_xo;

reg dbl_overflow;
reg dbl_underflow;
reg dbl_invalid_op;
reg dbl_divide_by_zero;

reg dbl_zerozero;
reg dbl_infdiv;

wire d_zero = lres[62:0]==63'd0;
wire d_neg = lres[63] & ~d_zero;
wire d_pos = ~lres[63] & ~d_zero;
wire d_nan = lres[62:52]==11'h7FF;
reg dbl_neg;
reg dbl_pos;
reg dbl_zero;
reg dbl_nan;

reg faddsub_operation_nd;
wire [63:0] faddsub_result;
wire faddsub_operation_rfd;
wire faddsub_invalid_op;
wire faddsub_rdy;

reg fmul_operation_nd;
wire [63:0] fmul_result;
wire fmul_operation_rfd;
wire fmul_invalid_op;
wire fmul_rdy;

reg fdiv_operation_nd;
wire [63:0] fdiv_result;
wire fdiv_operation_rfd;
wire fdiv_invalid_op;
wire fdiv_rdy;

reg fix2flt_operation_nd;
wire [63:0] fix2flt_result;
wire fix2flt_operation_rfd;
wire fix2flt_rdy;

reg flt2fix_operation_nd;
wire [63:0] flt2fix_result;
wire flt2fix_operation_rfd;
wire flt2fix_invalid_op;
wire flt2fix_rdy;

reg fcmp_operation_nd;
wire [3:0] fcmp_result;
wire fcmp_operation_rfd;
wire fcmp_invalid_op;
wire fcmp_rdy;

`ifdef FLOAT
FISA64_dblAddsub udbladdsub (
  .a(a), // input [63 : 0] a
  .b(b), // input [63 : 0] b
  .operation({5'd0,x1opcode[0]}), // input [5 : 0] operation
  .operation_nd(faddsub_operation_nd), // input operation_nd
  .operation_rfd(faddsub_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(faddsub_result), // output [63 : 0] result
  .underflow(faddsub_underflow), // output underflow
  .overflow(faddsub_overflow), // output overflow
  .invalid_op(faddsub_invalid_op), // output invalid_op
  .rdy(faddsub_rdy) // output rdy
);

FISA64_dblMul udblmul (
  .a(a), // input [63 : 0] a
  .b(b), // input [63 : 0] b
  .operation_nd(fmul_operation_nd), // input operation_nd
  .operation_rfd(fmul_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(fmul_result), // output [63 : 0] result
  .underflow(fmul_underflow), // output underflow
  .overflow(fmul_overflow), // output overflow
  .invalid_op(fmul_invalid_op), // output invalid_op
  .rdy(fmul_rdy) // output rdy
);

FISA64_dblDiv udbldiv (
  .a(a), // input [63 : 0] a
  .b(b), // input [63 : 0] b
  .operation_nd(fdiv_operation_nd), // input operation_nd
  .operation_rfd(fdiv_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(fdiv_result), // output [63 : 0] result
  .underflow(fdiv_underflow), // output underflow
  .overflow(fdiv_overflow), // output overflow
  .invalid_op(fdiv_invalid_op), // output invalid_op
  .divide_by_zero(fdiv_divide_by_zero), // output divide_by_zero
  .rdy(fdiv_rdy) // output rdy
);

FISA64_dblFix2Flt udblfix2flt (
  .a(a), // input [63 : 0] a
  .operation_nd(fix2flt_operation_nd), // input operation_nd
  .operation_rfd(fix2flt_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(fix2flt_result), // output [63 : 0] result
  .rdy(fix2flt_rdy) // output rdy
);

FISA64_dblFlt2Fix udblflt2fix (
  .a(a), // input [63 : 0] a
  .operation_nd(flt2fix_operation_nd), // input operation_nd
  .operation_rfd(flt2fix_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(flt2fix_result), // output [63 : 0] result
  .overflow(flt2fix_overflow), // output overflow
  .invalid_op(flt2fix_invalid_op), // output invalid_op
  .rdy(flt2fix_rdy) // output rdy
);

FISA64_dblCmp udblcmp (
  .a(a), // input [63 : 0] a
  .b(b), // input [63 : 0] b
  .operation_nd(fcmp_operation_nd), // input operation_nd
  .operation_rfd(fcmp_operation_rfd), // output operation_rfd
  .clk(clk), // input clk
  .result(fcmp_result), // output [3 : 0] result
  .invalid_op(fcmp_invalid_op), // output invalid_op
  .rdy(fcmp_rdy) // output rdy
);
`else
assign faddsub_operation_rfd = 1'b1;
assign fmul_operation_rfd = 1'b1;
assign fdiv_operation_rfd = 1'b1;
assign fix2flt_operation_rfd = 1'b1;
assign flt2fix_operation_rfd = 1'b1;
assign fcmp_operation_rfd = 1'b1;

assign faddsub_result = 64'd0;
assign fmul_result = 64'd0;
assign fdiv_result = 64'd0;
assign flt2fix_result = 64'd0;
assign fix2flt_result = 64'd0;
assign fcmp_result = 64'd0;

assign faddsub_overflow = 1'b0;
assign fmul_overflow = 1'b0;
assign fdiv_overflow = 1'b0;
assign flt2fix_overflow = 1'b0;

assign faddsub_underflow = 1'b0;
assign fmul_underflow = 1'b0;
assign fdiv_underflow = 1'b0;

assign faddsub_invalid_op = 1'b0;
assign fmul_invalid_op = 1'b0;
assign fdiv_invalid_op = 1'b0;
assign fcmp_invalid_op = 1'b0;
assign flt2fix_invalid_op = 1'b0;
assign fdiv_divide_by_zero = 1'b0;

assign faddsub_rdy = 1'b1;
assign fmul_rdy = 1'b1;
assign fdiv_rdy = 1'b1;
assign fix2flt_rdy = 1'b1;
assign flt2fix_rdy = 1'b1;
assign fcmp_rdy = 1'b1;
`endif

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

//-----------------------------------------------------------------------------
// Evaluate branch condition, compare to zero.
//-----------------------------------------------------------------------------

reg takb;
always @(xir or a)
	case(xir[6:0])
	`BEQS:	takb <= ~|a;
	`BNES:	takb <=  |a;
	`Bcc:
		case(xir[14:12])
		`BEQ:	takb <= ~|a;
		`BNE:	takb <=  |a;
		`BGT:	takb <= (~a[63] & |a[62:0]);
		`BGE:	takb <= ~a[63];
		`BLT:	takb <= a[63];
		`BLE:	takb <= (a[63] | ~|a[63:0]);
		default:	takb <= FALSE;
		endcase
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
wire signed [63:0] as = a;
wire signed [63:0] bs = b;
wire signed [63:0] imms = imm;
wire lti = as < imms;
wire ltui = a < imm;
wire eqi = a==imm;
wire eq = a==b;
wire lt = as < bs;
wire ltu = a < b;

// Rather than have a giant 50+ to 1 multiplexer for results, some instruction
// groups have been moved into submodules. This allows better optimization.

wire [63:0] logico;
wire [63:0] shifto;
wire [63:0] btfldo;

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

FISA64_bitfield u3
(
	.op(x1funct[6:4]),
	.a(a),
	.b(c),
	.imm(xir[11:7]),
	.m(xir[28:17]),
	.o(btfldo),
	.masko()
);

always @*
casex(x1opcode)
`BSR:	res <= xpc + 64'd4;
`JAL:	res <= xpc + ((wisImm&&tisImm) ? 64'd12:wisImm ? 64'd8 : 64'd4);
`JALI:	res <= xpc + ((wisImm&&tisImm) ? 64'd12:wisImm ? 64'd8 : 64'd4);
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
`ifdef FLOAT
`LDFI:	res <= imm;
`FADD,`FSUB,`FCMP,`FMUL,`FDIV:
		res <= lres;
`POPF:	res <= lres;
`LFD:	res <= lres;
`LFDX:	res <= lres;
`endif
`RR:
	case(x1funct)
	`MFSPR:
		if (km) begin
			casex(xir[24:17]|a[7:0])
			`CR0:		res <= cr0;
			`TICK:		res <= tick;
			`CLK:		res <= clk_throttle_new;
			`DBPC:		res <= dbpc;
			`EPC:		res <= epc;
			`IPC:		res <= ipc;
			`VBR:		res <= vbr;
			`BEAR:		res <= bear;
			`VECNO:		res <= vecno;
			`MULH:		res <= p[127:64];
			`ISP:		res <= isp;
			`ESP:		res <= esp;
			`DSP:		res <= dsp;
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
`ifdef FLOAT
			`FPSCR:
				begin
					res[27] <= dbl_divide_by_zero_xe;
					res[26] <= dbl_underflow_xe;
					res[25] <= dbl_overflow_xe;
					res[24] <= dbl_invalid_op_xe;
					res[19] <= dbl_neg;
					res[18] <= dbl_pos;
					res[17] <= dbl_zero;
					res[16] <= dbl_nan;
					res[13] <= dbl_divide_by_zero_xo;
					res[12] <= dbl_underflow_xo;
					res[11] <= dbl_overflow_xo;
					res[10] <= dbl_invalid_op_xo;
					res[9] <= dbl_g_xo;
					res[3] <= dbl_zerozero;
					res[2] <= dbl_infdiv;
				end
`endif
			default:	res <= 64'd0;
			endcase
		end
		else begin
			casex(xir[24:17]|a[7:0])
			`MYSTREG:	res <= mystreg;
			`MULH:		res <= p[127:64];
			default:	res <= 64'd0;
			endcase
		end
	`PCTRL:
		case(xir[21:17])
		`RTI:	res <= isp;
		`RTE:	res <= esp;
		`RTD:	res <= dsp;
		default:	res <= 64'd0;
		endcase
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
	`SLLI,`SLL,`SRLI,`SRL,`SRAI,`SRA,`ROL,`ROLI,`ROR,`RORI:	
			res <= shifto;
	`SXB:	res <= {{56{a[7]}},a[7:0]};
	`SXC:	res <= {{48{a[15]}},a[15:0]};
	`SXH:	res <= {{32{a[31]}},a[31:0]};
	`CPUID:
		case(a[3:0]|xir[20:17])
		4'd0:	res <= {rack_num,box_num,board_num,chip_num,core_num};
		4'd2:	res <= "Finitron";
		4'd3:	res <= "";
		4'd4:	res <= "FISA64  ";
		4'd5:	res <= "";
		4'd8:	res <= 1;
		default:	res <= 64'h0;
		endcase
`ifdef FLOAT
	`FIX2FLT,`FLT2FIX,`MV2FIX,`MV2FLT:
			res <= lres;
	`FMOV:	res <= a;
	`MTFP:	res <= a;
	`MFFP:	res <= a;
	`FNEG:	res <= {^a[63],a[62:0]};
	`FABS:	res <= {1'b0,a[62:0]};
`endif
	default:	res <= 64'd0;
	endcase
`MOV2:	res <= a;
`ADDQ:	res <= a + imm;
`BTFLD:	res <= btfldo;
`LEA:	res <= a + imm;
`LEAX:	res <= a + (b << xir[23:22]) + imm;
`PMW:	res <= lres;
`POP:	res <= lres;
`RTS:	res <= lres;
`RTS2:	res <= lres;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWAR,`INC,`CAS,`JALI,
`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`INCX:
		res <= lres;
default:	res <= 64'd0;
endcase

always @(x1opcode,a,c,imm)
case(x1opcode)
`POP:	res2 <= a + imm;
`RTS:	res2 <= a + imm;
`RTS2:	res2 <= a + {imm,3'b000};
`RTL2:	res2 <= a + {imm,3'b000};
`RTL:	res2 <= a + imm;
`PUSHPOP:
		case(xir[15:12])
		4'h0:	res2 <= c - 64'd8;
		4'h1:	res2 <= c - 64'd8;
		4'h2:	res2 <= a + 64'd8;
		4'h3:	res2 <= a + 64'd8;
		endcase
`PUSH:	res2 <= c - 64'd8;
`PMW:	res2 <= c - 64'd8;
`PEA:	res2 <= c - 64'd8;
`ifdef FLOAT
`PUSHF:	res2 <= c - 64'd8;
`POPF:	res2 <= a + imm;
`endif
default:	res2 <= 64'd0;
endcase

wire iselect_ssm = ((dimm&ximm) ? x63 : dimm ? d63 : dbctrl[63]) && iopcode[6:3]!=4'hF;

reg hwi;
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
	tapi1 <= FALSE;
	tap_nmi_edge <= FALSE;
	tam <= FALSE;
	ld_clk_throttle <= `FALSE;
	dbctrl <= 64'd0;
	dbstat <= 64'd0;
	mc_done <= TRUE;
	tagadr <= 64'd0;
	regSP <= 5'd30;
	regTR <= 5'd24;
	cr0[0] <= FALSE;	// protected mode enable
	cr0[30] <= TRUE;	// instruction cache enable
	cr0[32] <= TRUE;	// branch predictor enable
	cr0[36] <= FALSE;	// store successful bit
	cr0[40] <= FALSE;	// overflow exception enable
	cr0[41] <= FALSE;	// divide by zero exception enable
`ifdef FLOAT
	dbl_overflow_xe <= FALSE;
	dbl_underflow_xe <= FALSE;
	dbl_divide_by_zero_xe <= FALSE;
	dbl_invalid_op_xe <= FALSE;
`endif
	ssm <= FALSE;
	sscd <= 2'b11;
	d63 <= FALSE;
	x63 <= FALSE;
	w63 <= FALSE;
end
else begin
utg <= FALSE;
tick <= tick + 64'd1;
nmi1 <= nmi_i;
if (nmi_i & ~nmi1)
	nmi_edge <= `TRUE;
tapi1 <= tap_nmi;
if (tap_nmi & !tapi1)
	tap_nmi_edge <= TRUE;
ld_clk_throttle <= `FALSE;
if (db_stat0) dbstat[0] <= TRUE;
if (db_stat1) dbstat[1] <= TRUE;
if (db_stat2) dbstat[2] <= TRUE;
if (db_stat3) dbstat[3] <= TRUE;
if (sri_cnt != 4'd0)
	sri_cnt <= sri_cnt - 4'd1;
sri_o <= |sri_cnt;
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
		if (sscd[0] != 1'b1) begin
			sscd[0] <= 1'b1;
			dbctrl[63] <= dbctrl[62];
		end
		if (imcd != 3'd000) begin
			imcd <= {imcd[1:0],1'b0};
			if (imcd==3'b100)
				im <= `FALSE;
		end
		insncnt <= insncnt + 32'd1;
		// We want the debug co-processor to be able to "break-in" to anything
		// the processor might be doing. So we ignore the fact another interrupt
		// might be in progress.

		if (tap_nmi_edge) begin
			ir <= `BRK_TAP;
			hwi = TRUE;
		end
		else if (tam) begin
			ir <= dbg_insn;
			hwi = FALSE;
		end
		else

		if (!StatusHWI & gie & nmi_edge) begin
			ir <= `BRK_NMI;
			hwi = TRUE;
		end
		else if (!StatusHWI & gie & !im & irq_i) begin
			$display("*****************************");
			$display("*****************************");
			$display("*****************************");
			$display("****     IRQ %d    ****", vect_i);
			$display("*****************************");
			$display("*****************************");
			$display("*****************************");
			ir <= `BRK_IRQ;
			hwi = TRUE;
		end
		else if (db_imatch) begin
			ir <= `BRK_BPT;
			hwi = TRUE;
		end
		else if (!((isLotOwnerX && (km ? lottagX[0] : lottagX[3])) || !pe)) begin
			ir <= `BRK_EXF;
			hwi = TRUE;
		end
		// Ugh, we need to remember the dbctrl[63] status at the time of an
		// immediate prefix and use that as the status to control single
		// stepping. Need to do this in order to be able to skip over 
		// immediate prefixes.
//		else if (((dimm&ximm) ? x63 : dimm ? d63 : dbctrl[63]) && iopcode!=`IMM) begin
		else if (iselect_ssm) begin
			ir <= `BRK_SSM;
			hwi = TRUE;
		end
		else if (ice) begin
			ir <= insn;
			hwi = FALSE;
		end
		else begin
			ir <= ibuf;
			hwi = FALSE;
		end
		disassem(iir);
		$display("%h: %h", pc, iir);
		if (pc==32'h01019c)
			$stop;
		dpc <= pc;
		d63 <= dbctrl[63];
		dbranch_taken <= FALSE;
		// We take the following control transfers immediately in the IF stage,
		// that makes them single cycle operations.
		if (iopcode==`Bcc && predict_taken && bpe) begin
			pc <= pc + {{48{iir[31]}},iir[31:17],1'b0};
			dbranch_taken <= TRUE;
		end
		else if ((iopcode==`BEQS || iopcode==`BNES) && predict_taken && bpe) begin
			pc <= pc + {{59{iir[15]}},iir[15:12],1'b0};
			dbranch_taken <= TRUE;
		end
		else if (iopcode==`BSR || iopcode==`BRA) begin
			pc <= pc + {{38{iir[31]}},iir[31:7],1'b0};
		end
		else if (iopcode==`RR && ifunct==`PCTRL) begin
			case(iir[21:17])
			`WAI:	if (!hwi) pc <= pc; else begin dpc <= pc + 64'd4; pc <= pc + 64'd4; end
			`RTD:	begin pc <= dpc; pc[0] <= 1'b0; end
			`RTE:	begin pc <= epc; pc[0] <= 1'b0; end
			`RTI:	begin pc <= ipc; pc[0] <= 1'b0; end
			default:	pc <= pc + 64'd4;
			endcase
		end
		else
			pc <= pc + ((iopcode[6:3]==4'd6 || iopcode[6:1]==6'b010000 || iopcode==`ADDQ) ? 64'd2 : 64'd4);
	end
	else begin
		if (!iihit & !fnIsMC(xopcode,xfunct))
			next_state(LOAD_ICACHE);
		if (advanceRF) begin
			nop_ir();
			dpc <= pc;
			pc <= pc;
			d63 <= dbctrl[63];
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
		if (wopcode[6:3]==4'hF && xopcode[6:3]==4'hF) begin
			xpc <= wpc;	// in case of interrupt
			x63 <= w63;
		end
		else if (xopcode[6:3]==4'hF) begin
			xpc <= xpc;
			x63 <= x63;
		end
		else begin
			xpc <= dpc;
			x63 <= d63;
		end

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
		`SBX,`SCX,`SHX,`SWX,`INCX:
			imm <= ir[31:24];
		`LDIQ,`BEQS,`BNES:	imm <= {{60{ir[15]}},ir[15:12]};
		`ADDQ:  imm <= ir[15:12];
		`RTS2:	imm <= ir[15:7];
		default:
			if (wopcode[6:3]==4'hF && xopcode[6:3]==4'hF)
				imm <= {wir[31:7],wir[2:0],xir[31:7],xir[2:0],ir[31:17]};
			else if (xopcode[6:3]==4'hF)
				imm <= {{21{xir[31]}},xir[31:7],xir[2:0],ir[31:17]};
			else
				imm <= {{49{ir[31]}},ir[31:17]};
		endcase

		// Set the target register field. Some op's need this set to zero in
		// order to prevent a register from being updated. Other op's use the
		// target register field from the instruction.
		// If in user mode then don't allow updating register #24 (the task
		// register). This check must be done in the RF stage so that bypass
		// multiplexers are affected as well. It cannot be done at the WB
		// stage.
		casex(opcode)
		`RR:
			case(funct)
			`MTSPR,`FENCE,`CHK:
				xRt <= 6'd0;
			`PCTRL:
				xRt <= (km || ir[16:12]!=regTR) ? {1'b0,ir[16:12]} : 6'd0;
`ifdef FLOAT
			`FIX2FLT,`FLT2FIX,`FMOV,`FNEG,`FABS,`MTFP,`MV2FLT:
				xRt <= {1'b1,ir[16:12]};
`endif
			default:	xRt <= (km || ir[16:12]!=regTR) ? {1'b0,ir[16:12]} : 6'd0;
			endcase
		`BRA,`Bcc,`BRK,`IMM,`NOP,`CHKI:
			xRt <= 6'd0;
`ifdef FLOAT
		`PUSHF,`SFD,`SFDX,
`endif
		`SB,`SC,`SH,`SW,`SWCR,`SBX,`SCX,`SHX,`SWX,`INC,`INCX,
		`RTL,`RTL2,`PUSH,`PEA,`PMW:
			xRt <= 6'd0;
		`PUSHPOP:
			if (isPush)
				xRt <= 6'd0;
			else
				xRt <= (km || ir[11:7]!=regTR) ? {1'b0,ir[11:7]} : 6'd0;
		`BSR,`RTS,`RTS2:	xRt <= 6'h1F;
`ifdef FLOAT
		`FADD,`FSUB,`FMUL,`FDIV,
		`LDFI,`LFD,`LFDX,`POPF:	xRt <= {1'b1,ir[16:12]};
`endif
		`LDIQ,`ADDQ:	xRt <= (km || ir[11:7]!=regTR) ? {1'b0,ir[11:7]} : 6'd0;
		`MOV2:	xRt <= (km || {ir[0],ir[15:12]}!=regTR) ? {1'b0,ir[0],ir[15:12]} : 6'd0;
		default:	xRt <= (km || ir[16:12]!=regTR) ? {1'b0,ir[16:12]} : 6'd0;
		endcase
		
		// Set the SP target register flag. This flag indicates an update to
		// the SP register is required. Used for stack operations.
		case(opcode)
`ifdef FLOAT
		`PUSHF,`POPF,
`endif
		`POP,`RTS,`RTS2,`RTL,`RTL2,`PUSH,`PEA,`PMW:	xRt2 <= 1'b1;
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
		wisImm <= ximm;
		wopcode <= x1opcode;
		wpc <= xpc;
		w63 <= x63;
		wir <= xir;
		// Make the last register update "sticky" in the WB stage.
		if (xRt != 6'd0 && xRt != regSP) begin
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
		case(x1opcode)
		`RR:
			case(xfunct)
			`MTSPR:
				if (km) begin
					casex(xir[24:17]|c[7:0])
					`CR0:		cr0 <= a;
					`DBPC:		dbpc <= a;	// need the LSB's !!!
					`EPC:		epc <= a;
					`IPC:		ipc <= a;
					`VBR:		begin vbr <= a[AMSB:0]; vbr[12:0] <= 13'h000; end
					`MULH:		p[127:64] <= a;
					`ISP:		isp <= {a[AMSB:3],3'b000};
					`DSP:		dsp <= {a[AMSB:3],3'b000};
					`ESP:		esp <= {a[AMSB:3],3'b000};
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
`ifdef FLOAT
					`FPSCR:
						begin
							dbl_divide_by_zero_xe <= a[27];
							dbl_underflow_xe <= a[26];
							dbl_overflow_xe <= a[25];
							dbl_invalid_op_xe <= a[24];
							
							dbl_divide_by_zero_xo <= a[13];
							dbl_underflow_xo <= a[12];
							dbl_overflow_xo <= a[11];
							dbl_invalid_op_xo <= a[10];
							dbl_g_xo <= a[9];
						end
`endif
					endcase
				end
				else begin
					casex(xir[24:17]|c[7:0])
					`MYSTREG:	mystreg <= a;
					default:	privilege_violation();
					endcase
				end
				
			`MFSPR:	;/*
						if (!km &&
							xir[24:17]!=`MULH &&
							xir[24:17] != `MYSTREG)
						privilege_violation();*/
			`PCTRL:
				if (km)
					case(xir[21:17])
					`CLI:	imcd <= 3'b111;
					`SEI:	im <= `TRUE;
					`STP:	begin clk_throttle_new <= 50'd0; ld_clk_throttle <= `TRUE; end
					`EIC:	cr0[30] <= TRUE;
					`DIC:	cr0[30] <= FALSE;
					`FIP:	update_pc(xpc+64'd4);
					`SRI:	sri_cnt <= 4'd10;
					`RTE:	km <= epc[0];
					// Single step mode can't be enabled until we are sure the
					// RTD instruction will execute. Also a countdown flag has 
					// to be used because the first instruction after the RTD
					// should execute not in single step mode.
					`RTD:
						begin
						    km <= dbpc[0];
							if (dbctrl[62]) begin
								sscd <= 2'b00;	// single step countdown flag
								update_pc(dbpc);// flush instruction pipe
							end
							if (tam) begin
								tam <= FALSE;
							end
						end
					// A normal interrupt (eg timer) might occur during 
					// single step mode. On an RTI instruction return to
					// single step mode. In this case we want to activate
					// single step mode without a delay.
					`RTI:
						begin
							StatusHWI <= FALSE;
							imcd <= 3'b111;
							km <= ipc[0];
							//dbctrl[63] <= ipc[1];
							//if (ipc[1])	// flush the instruction pipe
							//	update_pc(ipc);	
						end
					endcase
				else
					privilege_violation();
			`ADD:	if (fnASOverflow(0,a[63],b[63],res[63]) && ovf_xe)
						overflow();
			`SUB:	if (fnASOverflow(1,a[63],b[63],res[63]) && ovf_xe)
						overflow();
			`CHK:	 if (!(a >= c && a < b))
			            bounds_violation();
			endcase
		`ADD:	if (fnASOverflow(0,a[63],imm[63],res[63]) && ovf_xe)
					overflow();
		`SUB:	if (fnASOverflow(1,a[63],imm[63],res[63]) && ovf_xe)
					overflow();
		`CHKI:	 if (!(a >= c && a < imm))
					bounds_violation();
		`BSR,`BRA:	;//update_pc(xpc + imm); done already in IF
		`JAL:		update_pc(a + {imm,1'b00});
		`RTL,`RTL2:	begin
					update_pc(c);
					$display("RTL: pc<=%h", a);
				end
		// For these instructions, the PC was already modified as part of the
		// multi-cycle operation. But we still need to flush the pipeline of
		// following instructions.
		// Don't need to flush the ir. The PC was set correctly
		// a cycle sooner in the multi-cycle code.
		`BRK,`RTS,`RTS2,`JALI:
				begin
					nop_xir();
				end
		// Correct a mispredicted branch.
		`Bcc:	if (takb & !xbranch_taken)
					update_pc(xpc + {imm,1'b0});
				else if (!takb & xbranch_taken)
					update_pc(xpc + 64'd4);
		`BEQS,`BNES:
				if (takb & !xbranch_taken)
					update_pc(xpc + {imm,1'b0});
				else if (!takb & xbranch_taken)
					update_pc(xpc + 64'd2);
		// CR0 is updated by SWCR but there is no result forwarding on the
		// update. So that the next instruction may have the correct value
		// the pipeline is flushed.
		`SWCR:	update_pc(xpc+64'd4);
		endcase
	end

	//-----------------------------------------------------------------------------
	// WRITEBACK
	//-----------------------------------------------------------------------------
	// wRt2 and wRt==30 are never active together at the same time.
	if (advanceWB) begin
		tisImm <= wisImm;
		if (wRt != 5'd0) begin
			tRt <= wRt;
			tres <= wres;
		end
		regfile[wRt] <= wres;
		if (wRt2) begin
			gie <= TRUE;
			sp <= wres2;
			tRt2 <= wRt2;
			tres2 <= wres2;
		end
		if (wRt==regSP)	begin // write to SP globally enables interrupts
			gie <= TRUE;
			sp <= wres;
		end
	end
	// If advanceTL (= TRUE)
	if (advanceTL) begin
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
`ifdef FLOAT
			`FIX2FLT,`MV2FLT:
				begin
					fix2flt_operation_nd <= TRUE;
					mdfunct <= xfunct;
					next_state(FLT1);
				end
			`FLT2FIX,`MV2FIX:
				begin
					flt2fix_operation_nd <= TRUE;
					mdfunct <= xfunct;
					next_state(FLT1);
				end
`endif
			endcase
`ifdef FLOAT
		`FADD,`FSUB:
			begin
				faddsub_operation_nd <= TRUE;
				next_state(FLT1);
			end
		`FMUL:
			begin
				fmul_operation_nd <= TRUE;
				next_state(FLT1);
			end
		`FDIV:
			begin
				fdiv_operation_nd <= TRUE;
				next_state(FLT1);
			end
		`FCMP:
			begin
				fcmp_operation_nd <= TRUE;
				next_state(FLT1);
			end
`endif
		`MUL,`MULU,`DIV,`DIVU,`MOD,`MODU:
			begin
				mdopcode <= xopcode;
				mdfunct <= xfunct;
				next_state(MULDIV);
			end
		`BRK:	begin
				case(xir[31:30])
				2'b00:	
					begin
						epc[AMSB:2] <= xpc[AMSB:2];
						epc[1] <= 1'b0;
						epc[0] <= km;
						esp[AMSB:3] <= a[AMSB:3];
						esp[2:0] <= 3'b000;
					end
				2'b01:
					begin
						dbpc[AMSB:2] <= xpc[AMSB:2];
						dbpc[1] <= 1'b0;
						dbpc[0] <= km;
						dsp[AMSB:3] <= a[AMSB:3];
						dsp[2:0] <= 3'b000;
						dbctrl[63] <= FALSE;	// clear SSM
						ssm <= FALSE;
					end
				2'b10:
					begin
						StatusHWI <= `TRUE;
						ipc[AMSB:2] <= xpc[AMSB:2];
						dbctrl[63] <= FALSE;
						ipc[1] <= dbctrl[63];
						ipc[0] <= km;
						isp[AMSB:3] <= a[AMSB:3];
						isp[2:0] <= 3'b000;
						if (xir[25:17]==9'd510)
							nmi_edge <= FALSE;
						else
							im <= TRUE;
					end
				endcase
				km <= TRUE;
				mopcode <= xopcode;
				mir <= xir;
				// Test access mode is special, it just starts running the
				// processor from the debug sandbox. It doesn't vector !
				if (xir[25:17]==9'd494) begin
					update_pc(32'hFFFFE000);	// Debug sandbox address
					tam <= TRUE;
				end
				else begin
					ea <= {vbr[AMSB:12],xir[25:17],3'b000};
					ld_size <= word;
					next_state(LOAD1);
				end
				vecno <= xir[25:17];
				end
`ifdef FLOAT
		`LFD,
`endif
		`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWAR,`INC,`CAS,`JALI:
			begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + imm;
				case(xopcode)
				`LB,`LBU:	ld_size <= byt;
				`LC,`LCU:	ld_size <= char;
				`LH,`LHU:	ld_size <= half;
				`LW,`INC,`LFD:	ld_size <= word;
				`LWAR:	ld_size <= word;
				`CAS,`JALI:	ld_size <= word;
				endcase
				st_size <= word;
			end
`ifdef FLOAT
		`LFDX,
`endif
		`LBX,`LBUX,`LCX,`LCUX,`LHX,`LHUX,`LWX,`INCX:
			begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a + (b << xir[23:22]) + imm;
				case(xopcode)
				`LBX,`LBUX:	ld_size <= byt;
				`LCX,`LCUX:	ld_size <= char;
				`LHX,`LHUX:	ld_size <= half;
				`LWX,`INCX,`LFDX:	ld_size <= word;
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
		`PUSH,`PUSHF:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= res2;
				xb <= a;
				st_size <= word;
				end
		`PUSHPOP:
				begin
					mopcode <= xopcode;
					if (xir[15:13]==3'd0) begin
						next_state(STORE1);
						ea <= res2;
						xb <= a;
						st_size <= word;
					end
					else begin
						next_state(LOAD1);
						mir <= xir;
						ea <= a;
						ld_size <= word;
					end
				end
		`PEA:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= res2;
				xb <= a + imm;
				st_size <= word;
				end
		`POP,`RTS,`RTS2,`POPF:
				begin
				next_state(LOAD1);
				mopcode <= xopcode;
				mir <= xir;
				ea <= a;
				ld_size <= word;
				end
		`SB,`SC,`SH,`SW,`SWCR,`SFD:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= a + imm;
				xb <= c;
				case(xopcode)
				`SB:	st_size <= byt;
				`SC:	st_size <= char;
				`SH:	st_size <= half;
				`SW,`SFD:	st_size <= word;
				`SWCR:	st_size <= word;
				endcase
				end
		`SBX,`SCX,`SHX,`SWX,`SFDX:
				begin
				next_state(STORE1);
				mopcode <= xopcode;
				ea <= a + (b << xir[23:22]) + imm;
				xb <= c;
				case(xopcode)
				`SBX:	st_size <= byt;
				`SCX:	st_size <= char;
				`SHX:	st_size <= half;
				`SWX,`SFDX:	st_size <= word;
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
					if (b==64'd0 && dbz_xe)
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
MULT1:	state <= MULT3;
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
// Floating point states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FLT1:
	begin
		fix2flt_operation_nd <= FALSE;
		flt2fix_operation_nd <= FALSE;
		faddsub_operation_nd <= FALSE;
		fmul_operation_nd <= FALSE;
		fdiv_operation_nd <= FALSE;
		fcmp_operation_nd <= FALSE;
		case(x1opcode)
		`RR:
			case (mdfunct)
			`FIX2FLT,`MV2FLT:
				if (fix2flt_operation_rfd) begin
					next_state(FLT2);
				end
			`FLT2FIX,`MV2FIX:
				if (flt2fix_operation_rfd) begin
					next_state(FLT2);
				end
			endcase
		`FADD,`FSUB:
			if (faddsub_operation_rfd) begin
				next_state(FLT2);
			end
		`FMUL:
			if (fmul_operation_rfd) begin
				next_state(FLT2);
			end
		`FDIV:
			if (fdiv_operation_rfd) begin
				dbl_zerozero <= a[62:0]==63'd0 && b[62:0]==63'd0;
				dbl_infdiv <= a[62:52]==11'h7ff && b[62:52]==11'h7ff;
				next_state(FLT2);
			end
		`FCMP:
			if (fcmp_operation_rfd) begin
				next_state(FLT2);
			end
		endcase
	end
FLT2:
	begin
		case(x1opcode)
		`RR:
			case (mdfunct)
			`FIX2FLT,`MV2FLT:
				if (fix2flt_rdy) begin
					lres <= fix2flt_result;
					next_state(FLT3);
				end
			`FLT2FIX,`MV2FIX:
				if (flt2fix_rdy) begin
					lres <= flt2fix_result;
					dbl_overflow <= flt2fix_overflow;
					dbl_invalid_op <= flt2fix_invalid_op;
					next_state(FLT3);
				end
			endcase
		`FADD,`FSUB:
			if (faddsub_rdy) begin
				lres <= faddsub_result;
				dbl_overflow <= faddsub_overflow;
				dbl_underflow <= faddsub_underflow;
				dbl_invalid_op <= faddsub_invalid_op;
				next_state(FLT3);
			end
		`FMUL:
			if (fmul_rdy) begin
				lres <= fmul_result;
				dbl_overflow <= fmul_overflow;
				dbl_underflow <= fmul_underflow;
				dbl_invalid_op <= fmul_invalid_op;
				next_state(FLT3);
			end
		`FDIV:
			if (fdiv_rdy) begin
				lres <= fdiv_result;
				dbl_overflow <= fdiv_overflow;
				dbl_underflow <= fdiv_underflow;
				dbl_invalid_op <= fdiv_invalid_op;
				dbl_divide_by_zero <= fdiv_divide_by_zero;
				next_state(FLT3);
			end
		`FCMP:
			if (fcmp_rdy) begin
				if (fcmp_result[3])
					lres <= 64'h2;
				else
					lres <= fcmp_result[1] ? 64'hFFFFFFFFFFFFFFFF : fcmp_result[0] ? 64'd0 : 64'd1;
				dbl_invalid_op <= fcmp_invalid_op;
				next_state(FLT3);
			end
		endcase
	end
FLT3:
	begin
		dbl_neg <= d_neg;
		dbl_pos <= d_pos;
		dbl_zero <= d_zero;
		dbl_nan <= d_nan;
		if (dbl_invalid_op_xe && dbl_invalid_op) begin
			dbl_invalid_op_xo <= TRUE;
			dbl_g_xo <= TRUE;
			flt_exception();
		end
		if (dbl_divide_by_zero_xe && dbl_divide_by_zero) begin
			flt_exception();
			dbl_divide_by_zero_xo <= TRUE;
			dbl_g_xo <= TRUE;
		end
		if (dbl_overflow_xe && dbl_overflow) begin
			flt_exception();
			dbl_overflow_xo <= TRUE;
			dbl_g_xo <= TRUE;
		end
		if (dbl_underflow_xe && dbl_underflow) begin
			flt_exception();
			dbl_underflow_xo <= TRUE;
			dbl_g_xo <= TRUE;
		end
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
			nop_xir();
			ir <= `BRK_BPT;
			dpc <= xpc;
			pc <= 32'h10000;
			next_state(RUN);
		end
		// Check for read attribute on lot
		else if ((isLotOwner && (km ? lottag[2] : lottag[5])) || !pe) begin
			$display("LOAD: %h",ea);
			wb_read1(ld_size,ea);
			if (mopcode==`LWAR)
				sr_o <= TRUE;
			next_state(LOAD3);
		end
		else begin
			nop_xir();
			ir <= `BRK_DRF;
			dpc <= xpc;
			pc <= 32'h10000;
			next_state(RUN);
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
		`LW,`LWX,`LWAR,`LFD,`LFDX:
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
		`INC,`INCX:
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
				end
		`RTS,`RTS2:
				begin
					lres <= dat_i[63:0];
					pc[AMSB:2] <= dat_i[AMSB:2];
					pc[1:0] <= 2'b00;
					next_state(iihit ? RUN : LOAD_ICACHE);
					xopcode <= `NOP;
					wb_nack();
					mc_done <= TRUE;
				end
		`POP,`POPF,`PUSHPOP:
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
		if (mopcode==`INC || mopcode==`INCX) begin
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
		`LW,`LWX,`LWAR,`LFD,`LFDX:
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
		`INC,`INCX,`CAS:
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
			nop_xir();
			ir <= `BRK_BPT;
			dpc <= xpc;
			pc <= 32'h10000;
			next_state(RUN);
		end
		// check for write attribute on lot
		else if ((isLotOwner && (km ? lottag[1] : lottag[4])) || !pe) begin
			wb_write1(st_size,ea,xb);
			$display("STORE: %h=%h",ea,xb);
			if (mopcode==`SWCR)
				cr_o <= TRUE;
			next_state(STORE3);
		end
		else begin
			nop_xir();
			ir <= `BRK_DWF;
			dpc <= xpc;
			pc <= 32'h10000;
			next_state(RUN);
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
		if (mopcode==`SWCR)
			cr0[36] <= rb_i;
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
		if (mopcode==`SWCR)
			cr0[36] <= rb_i;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache load states.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

LOAD_ICACHE:
	begin
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
			ibufadr <= pc;
			case(pc[2:1])
			2'd0:	ibuf <= dat_i[31:0];
			2'd1:	ibuf <= dat_i[47:16];
			2'd2:	ibuf <= dat_i[63:32];
			2'd3:	ibuf[15:0] <= dat_i[63:48];
			endcase
			if (pc[2:1]!=2'd3) begin
				wb_nack();
				next_state(RUN);
			end
			else begin
				wb_half_nack();
				next_state(LOAD_ICACHE3);
			end
		end
	end
LOAD_ICACHE3:
	begin
		if (ice) begin
			wb_read1(word,{pc[AMSB:4],4'h8});
			next_state(LOAD_ICACHE4);
		end
		else begin
			wb_read1(word,{pc[AMSB:3]+29'd1,3'b000});
			next_state(LOAD_ICACHE4);
		end
	end
LOAD_ICACHE4:
	if (ack_i|err_i) begin
		if (ice) begin
			if (ihit2) wb_nack(); else wb_half_nack();
			utg <= TRUE;
			tagadr <= pc;
			isICacheLoad <= !ihit2;
			next_state(ihit2 ? RUN : LOAD_ICACHE5);
		end
		else begin
			wb_nack();
			ibuf[31:16] <= dat_i[15:0];
			next_state(RUN);
		end
	end
LOAD_ICACHE5:
	begin
		wb_read1(word,{pc[AMSB:4]+29'd1,4'h0});
		next_state(LOAD_ICACHE6);
	end
LOAD_ICACHE6:
	if (ack_i|err_i) begin
		wb_half_nack();
		next_state(LOAD_ICACHE7);
	end
LOAD_ICACHE7:
	begin
		wb_read1(word,{pc[AMSB:4]+29'd1,4'h8});
		next_state(LOAD_ICACHE8);
	end
LOAD_ICACHE8:
	if (ack_i|err_i) begin
		wb_nack();
		utg <= TRUE;
		tagadr <= pc+32'd2;
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
	sr_o <= 1'b0;
	cr_o <= 1'b0;
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
	dbranch_taken <= FALSE;
end
endtask

// Flush the EX stage

task nop_xir;
begin
	x1opcode <= `NOP;
	xopcode <= `NOP;
	xRt <= 5'b0;
	xRt2 <= 1'b0;
	xir[6:0] <= `NOP;	// NOP
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
//	if (!ssm)			// If in SSM the xir will be setup appropriately.
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
	nop_xir();
	ir <= `BRK_DBE;
	dpc <= xpc;
	pc <= 32'h10000;
	bear <= ea;
	next_state(RUN);
end
endtask

task privilege_violation;
begin
	wb_nack();
	nop_xir();
	ir <= `BRK_PRV;
	dpc <= xpc;
	pc <= 32'h10000;
	next_state(RUN);
end
endtask

task overflow;
begin
	wb_nack();
	nop_xir();
	ir <= `BRK_OFL;
	dpc <= xpc;
	pc <= 32'h10000;
	next_state(RUN);
end
endtask

// function argument bad
task divide_by_zero;
begin
	wb_nack();
	nop_xir();
	ir <= `BRK_DBZ;
	dpc <= xpc;
	pc <= 32'h10000;
	next_state(RUN);
end
endtask

task bounds_violation;
begin
	wb_nack();
	nop_xir();
	ir <= `BRK_BND;
	dpc <= xpc;
	pc <= 32'h10000;
	next_state(RUN);
end
endtask

task flt_exception;
begin
	wb_nack();
	nop_xir();
	ir <= `BRK_FLT;
	dpc <= xpc;
	pc <= 32'h10000;
	next_state(RUN);
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
LOAD_ICACHE5:	fnStateName = "LOAD_ICACHE5 ";
LOAD_ICACHE6:	fnStateName = "LOAD_ICACHE6 ";
LOAD_ICACHE7:	fnStateName = "LOAD_ICACHE7 ";
LOAD_ICACHE8:	fnStateName = "LOAD_ICACHE8 ";
default:	fnStateName = "UNKNOWN ";
endcase
endfunction

// Mini-disassembler
task disassem;
input [31:0] insn;
begin
	case(insn[6:0])
	`LDI:	$display("LDI r%d,#%h", insn[16:12], insn[31:17]);
	`RR:
		case(insn[31:25])
		`PCTRL:
			case(insn[21:17])
			`CLI:	$display("CLI");
			`SEI:	$display("SEI");
			`WAI:	$display("WAI");
			`RTI:	$display("RTI");
			`RTE:	$display("RTE");
			`RTD:	$display("RTD");
			endcase
		endcase
	`BRA:	$display("BRA %h" , pc + {{37{insn[31]}},insn[31:7],2'b00});
	`BSR:	$display("BSR %h" , pc + {{37{insn[31]}},insn[31:7],2'b00});
	`Bcc:
		case(insn[14:12])
		`BEQ:	$display("BEQ r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BNE:	$display("BNE r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BLT:	$display("BLT r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BGT:	$display("BGT r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BLE:	$display("BLE r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		`BGE:	$display("BGE r%d,%h" , insn[11:7], pc + {{47{insn[31]}},insn[31:17],2'b00});
		endcase
	`BRK:	$display("BRK %d %s", insn[25:17], insn[31:30]==2'b00 ? "SWE" : insn[31:30]==2'b01 ? "DBG" : "HWI");
	`LB:	$display("LB r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LBU:	$display("LBU r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LC:	$display("LC r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LCU:	$display("LCU r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LH:	$display("LH r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LHU:	$display("LHU r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`LW:	$display("LW r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`SB:	$display("SB r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`SC:	$display("SC r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`SH:	$display("SH r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`SW:	$display("SW r%d,%h[r%d]", insn[16:12],insn[31:17],insn[11:7]);
	`PUSH:	$display("PUSH r%d", insn[11:7]);
	`PUSHF:	$display("PUSH fp%d", insn[11:7]);
	`POP:	$display("POP r%d", insn[16:12]);
	`POPF:	$display("POP fp%d", insn[16:12]);
	`RTL:	$display("RTL");
	`RTL2:	$display("RTL");
	`RTS:	$display("RTS");
	`RTS2:	$display("RTS");
	endcase
end
endtask

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module FISA64_debug_iram(wclk, rwa, wr, i, o, rclk, pc, insn);
input wclk;
input [11:0] rwa;
input wr;
input [15:0] i;
output [15:0] o;
input rclk;
input [11:0] pc;
output [15:0] insn;

reg [11:0] rpc;
reg [11:0] rrwa;
reg [31:0] iram [511:0];
always @(posedge wclk)
begin
	if (wr) iram [rwa[11:1]] <= i;
end
always @(posedge rclk)
	rrwa <= rwa;
assign o = iram[rrwa[11:1]];
always @(posedge rclk)
	rpc <= pc;
assign insn = iram[rpc[11:1]];

endmodule

module FISA64_debug_dram(wclk, rwa, wr, sel, i, o, rclk, ea, dat);
input wclk;
input [13:0] rwa;
input wr;
input [7:0] sel;
input [63:0] i;
output [63:0] o;
input rclk;
input [13:0] ea;
output reg [15:0] dat;

reg [7:0] mem0 [2047:0];
reg [7:0] mem1 [2047:0];
reg [7:0] mem2 [2047:0];
reg [7:0] mem3 [2047:0];
reg [7:0] mem4 [2047:0];
reg [7:0] mem5 [2047:0];
reg [7:0] mem6 [2047:0];
reg [7:0] mem7 [2047:0];

always @(posedge wclk)
begin
	if (wr & sel[0]) mem0[rwa[13:3]] <= i[ 7: 0];
	if (wr & sel[1]) mem0[rwa[13:3]] <= i[15: 8];
	if (wr & sel[2]) mem0[rwa[13:3]] <= i[23:16];
	if (wr & sel[3]) mem0[rwa[13:3]] <= i[31:24];
	if (wr & sel[4]) mem0[rwa[13:3]] <= i[39:32];
	if (wr & sel[5]) mem0[rwa[13:3]] <= i[47:40];
	if (wr & sel[6]) mem0[rwa[13:3]] <= i[55:48];
	if (wr & sel[7]) mem0[rwa[13:3]] <= i[63:56];
end
reg [13:0] rrwa;
always @(posedge wclk)
	rrwa <= rwa;
assign o = {mem7[rrwa[13:3]],mem6[rrwa[13:3]],mem5[rrwa[13:3]],mem4[rrwa[13:3]],mem3[rrwa[13:3]],mem2[rrwa[13:3]],mem1[rrwa[13:3]],mem0[rrwa[13:3]]};
reg [12:0] rea;
always @(posedge rclk)
	rea <= ea;
wire [63:0] dat1 = {mem7[rea[13:3]],mem6[rea[13:3]],mem5[rea[13:3]],mem4[rea[13:3]],mem3[rea[13:3]],mem2[rea[13:3]],mem1[rea[13:3]],mem0[rea[13:3]]};
always @(rea,dat1)
case(rea[2:1])
2'd0:	dat <= dat1[15: 0];
2'd1:	dat <= dat1[31:16];
2'd2:	dat <= dat1[47:32];
2'd3:	dat <= dat1[63:48];
endcase

endmodule

module FISA64_debug_rom(clk, pc, insn);
input clk;
input [11:0] pc;
output [15:0] insn;

reg [11:0] rpc;
reg [15:0] rommem [2047:0];

//initial begin
// Include instruction ROM data here.
//end

always @(posedge clk)
	rpc <= pc;
assign insn = rommem[rpc];

endmodule

module FISA64_icache_ram(wclk, wa, wr, i, rclk, pc, insn);
input wclk;
input [12:0] wa;
input wr;
input [63:0] i;
input rclk;
input [12:0] pc;
output reg [31:0] insn;

reg [12:0] rpc;
reg [12:0] rpc2;
reg [63:0] icache_ram [1023:0];
always @(posedge wclk)
	if (wr) icache_ram [wa[12:3]] <= i;
always @(posedge rclk)
	rpc <= pc;
always @(posedge rclk)
	rpc2 <= pc + 32'd2;
wire [63:0] ico = icache_ram[rpc[12:3]];
wire [63:0] ico2 = icache_ram[rpc2[12:3]];
always @(rpc)
case(rpc[2:1])
2'd0:	insn <= ico[31: 0];
2'd1: 	insn <= ico[47:16];
2'd2:	insn <= ico[63:32];
2'd3:	insn <= {ico2[15:0],ico[63:48]};
endcase

endmodule

module FISA64_itag_ram(wclk, wa, v, wr, rclk, pc, hit, hit2);
input wclk;
input [31:0] wa;
input v;
input wr;
input rclk;
input [31:0] pc;
output hit;
output hit2;

reg [31:0] rpc;
reg [31:0] rpc2;
reg [32:13] itag_ram [511:0];
always @(posedge wclk)
	if (wr) itag_ram[wa[12:4]] <= {v,wa[31:13]};
always @(posedge rclk)
	rpc <= pc;
always @(posedge rclk)
	rpc2 <= pc+32'd2;
wire [32:13] tag_out = itag_ram[rpc[12:4]];
assign hit = tag_out=={1'b1,rpc[31:13]};
wire [32:13] tag_out2 = itag_ram[rpc2[12:4]];
assign hit2 = tag_out2=={1'b1,rpc2[31:13]};

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
reg [1:0] branch_history_table [511:0];
// For simulation only, initialize the history table to zeros.
// In the real world we don't care.
initial begin
	for (n = 0; n < 512; n = n + 1)
		branch_history_table[n] = 0;
end
wire [8:0] bht_wa = {xpc[7:1],gbl_branch_hist[2:1]};		// write address
wire [8:0] bht_ra1 = {xpc[7:1],gbl_branch_hist[2:1]};		// read address (EX stage)
wire [8:0] bht_ra2 = {pc[7:1],gbl_branch_hist[2:1]};	// read address (IF stage)
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

/*
module FISA64_bypass_mux(Rn, xRt, wRt, tRt, uRt, regSP, xres, wres, tres, ures, rfo, o);
input [4:0] Rn;
input [4:0] xRt;
input [4:0] wRt;
input [4:0] tRt;
input [4:0] uRt;
input [4:0] regSP;
input [63:0] xres;
input [63:0] wres;
input [63:0] tres;
input [63:0] ures;
input [63:0] rfo;
output reg [63:0] o;

always @*
if (Rn==5'd0)
	o <= 64'd0;
else if (Rn==xRt)
	o <= xres;
else if (Rn==wRt)
	o <= wres;
else if (Rn==tRt)
	o <= tres;
else if (Rn==uRt)
	o <= ures;
else if (Rn==regSP)
case(Rn)
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
endmodule

*/