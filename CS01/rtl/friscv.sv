// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv_wb.sv
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
`define LD			3'd3
`define LBU			3'd4
`define LHU			3'd5
`define LWU			3'd6
`define LOADF	7'd7
`define FENCE	7'd15
`define AUIPC	7'd23
`define STORE	7'd35
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define SD			3'd3
`define STOREF	7'd39
`define AMO		7'd47
`define LUI		7'd55
`define FMA		7'd67
`define FMS		7'd71
`define FNMS	7'd75
`define FNMA	7'd79
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
`define EBREAK	32'h00100073
`define ECALL		32'h00000073
`define ERET		32'h10000073
`define MRET		32'h30200073
`define WFI			32'h10100073
`define PFI			32'h10300073
`define PEEKQ   7'd14
`define CS_ILLEGALINST	2

`include "fp/fpConfig.sv"

module friscv_wb(rst_i, hartid_i, clk_i, wc_clk_i, nmi_i, irq_i, cause_i, vpa_o, 
	cyc_o, stb_o, ack_i, err_i, rty_i, we_o, sel_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i
	);
parameter WID = 32;
parameter FPWID = 32;
parameter RSTPC = 32'hFFFC0100;
input rst_i;
input [31:0] hartid_i;
input clk_i;
input wc_clk_i;             // wall clock timing input
input nmi_i;
input [2:0] irq_i;
input [7:0] cause_i;
output reg vpa_o;           // valid program address
output cyc_o;
output reg stb_o;
input ack_i;
input err_i;
input rty_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [FPWID-1:0] dat_i;
output reg [FPWID-1:0] dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;
parameter HIGH = 1'b1;
parameter LOW = 1'b0;
`include "fp/fpSize.sv"

wire clk_g;					// gated clock
reg lcyc;						// linear cycle
reg [31:0] ladr;		// linear address

// Non visible registers
wire MachineMode, UserMode;
reg [31:0] ir;			// instruction register
reg [31:0] upc;			// user mode pc
reg [31:0] spc;			// system mode pc
reg [4:0] Rd;
wire [4:0] Rs1 = ir[19:15];
wire [4:0] Rs2 = ir[24:20];
wire [4:0] Rs3 = ir[31:27];
reg [WID-1:0] ia, ib, ic;
reg [WID-1:0] ia2, ib2, ic2;
reg [FPWID-1:0] fa, fb, fc;
reg [WID-1:0] imm, res;
// Decoding
wire [6:0] opcode = ir[6:0];
wire [2:0] funct3 = ir[14:12];
wire [4:0] funct5 = ir[31:27];
wire [6:0] funct7 = ir[31:25];
wire [2:0] rm3 = ir[14:12];
reg wrirf, wrfrf;

reg [4:0] rprv;
reg [WID-1:0] iregfile [0:127];		// integer / system / interrupt register file
reg [WID-1:0] cs_base;
reg [WID-1:0] cs_bound;
reg [WID-1:0] sregfile [0:255];		// base registers
reg [WID-1:0] bregfile [0:255];		// bounds registers
reg [5:0] ASID;
wire [5:0] asid;
reg wrpagemap;
wire [13:0] pagemap_ndx;
wire [8:0] pagemapoa, pagemapo;
reg [13:0] pagemapa;
PagemapRam pagemap (
  .clka(clk_g),
  .ena(1'b1),
  .wea(wrpagemap),
  .addra({ib[21:16],ib[7:0]}),
  .dina(ia[8:0]),
  .douta(pagemapoa),
  .clkb(clk_g),
  .enb(1'b1),
  .web(1'b0),
  .addrb(pagemap_ndx),
  .dinb(9'h00),
  .doutb(pagemapo)
);
reg decto, setto, getto, getzl, popto;
wire [7:0] zladr;
wire [31:0] to_out;
wire [7:0] zl_out;
wire to_done;
Timeouter utmo1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.dec_i(decto),
	.set_i(setto),
	.qry_i(getto),
	.pop_i(getzl),
	.tid_i(ia[5:0]),
	.timeout_i(ib),
	.timeout_o(to_out),
	.zeros_o(zl_out),
	.qadr(zladr),
	.done_o(to_done)
);
reg insrdy, rmvrdy, getrdy;
wire [4:0] rdy_out;
reg readyqins, readyqrmv;
reg [2:0] readyqpri;
wire [31:0] queueo;
reg pushq, popq, peekq;
ReadyQueues urq1 (rst_i, clk_g, pushq, popq && ~ia[3], peekq && ~ia[3], ia[8:0], pushq ? ib[2:0] : ia[2:0], queueo);
/*
ReadyList url1
(
	.rst_i(rst_i),
	.clk_i(clk_g),
	.insert_i(insrdy),
	.remove_i(rmvrdy),
	.get_i(getrdy),
	.tid_i(ia[3:0]),
	.priority_i(ib[2:0]),
	.tid_o(rdy_out),
	.done_o(rdy_done)
);
*/
reg [31:0] sp;
reg traceOn;
reg traceRd;
reg [9:0] traceCounter;
reg poptrace;
wire traceWr = state==IFETCH && traceOn;
wire traceValid, traceEmpty, traceFull;
wire [9:0] traceDataCount;
wire [63:0] traceOut;
TraceFifo utf1 (
  .clk(clk_g),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din({sp,pc}),                // input wire [31 : 0] din
  .wr_en(traceWr),            // input wire wr_en
  .rd_en((popq && ia[3:0]==4'd14)||poptrace),            // input wire rd_en
  .dout(traceOut),              // output wire [31 : 0] dout
  .full(traceFull),              // output wire full
  .empty(traceEmpty),            // output wire empty
  .valid(traceValid),            // output wire valid
  .data_count(traceDataCount)  // output wire [9 : 0] data_count
);
reg [255:0] gcie;
reg [31:0] pc;			// generic program counter
reg [31:0] ipc;			// pc value at instruction
reg [2:0] rm;
reg [5:0] Rs1x, Rs2x, Rs3x, Rdx;
reg [5:0] Rs1x1, Rs2x1, Rs3x1, Rdx1;
reg [5:0] Rs1x2, Rs2x2, Rs3x2, Rdx2;
wire [WID-1:0] irfoa;
wire [WID-1:0] irfob;
reg [4:0] state;
parameter RESET = 5'd0;
parameter IFETCH = 5'd1;
parameter IFETCH2 = 5'd2;
parameter DECODE = 5'd3;
parameter RFETCH = 5'd4;
parameter EXECUTE = 5'd5;
parameter MEMORY = 5'd6;
parameter MEMORY2 = 5'd7;
parameter MEMORY2_ACK = 5'd8;
parameter FLOAT = 5'd9;
parameter WRITEBACK = 5'd10;
parameter MEMORY_WRITE = 5'd11;
parameter MEMORY_WRITEACK = 5'd12;
parameter MEMORY_WRITE2 = 5'd13;
parameter MEMORY_WRITE2ACK = 5'd14;
parameter MUL1 = 5'd15;
parameter MUL2 = 5'd16;
parameter PAM	 = 5'd17;
parameter REGFETCH2 = 5'd18;
parameter MEMORY3 = 5'd19;
parameter MEMORY4 = 5'd20;
parameter TMO = 5'd21;
parameter NSIMM = 5'd22;
parameter NSIMM2 = 5'd23;
parameter REGFETCH3 = 5'd24;
parameter PAGEMAPA = 5'd25;
parameter CSR = 5'd26;
parameter CSR2 = 5'd27;
parameter MEMORY_SETUP = 5'd28;
parameter MEMORY2_SETUP = 5'd29;

reg wbs;
always_comb
	wbs <= state==WRITEBACK;

RegfileRam urf1 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrirf & wbs),      // input wire [0 : 0] wea
  .addra(wbs ? {Rdx,Rd} : {Rs1x,Rs1}),  // input wire [9 : 0] addra
  .dina(res[WID-1:0]),    // input wire [31 : 0] dina
  .douta(irfoa),  	// output wire [31 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs2x,Rs2}),  // input wire [9 : 0] addrb
  .dinb(32'd0),    // input wire [31 : 0] dinb
  .doutb(irfob)  // output wire [31 : 0] doutb
);
reg illegal_insn;

always_ff @(posedge clk_g)
	if (wbs && Rd==5'd2)
		sp <= res[WID-1:0];

// CSRs
reg [5:0] gcloc;    // garbage collect lockout count
reg [2:0] mrloc;    // mret lockout
reg [31:0] uip;     // user interrupt pending
reg [47:0] rsStack;
reg [31:0] pmStack;
reg [31:0] imStack;
wire [2:0] im_level = imStack[2:0];
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi = 1'b0;
reg [31:0] mepc [0:63];
reg [31:0] mtimecmp;
reg [63:0] instret;	// instructions completed.
reg [31:0] mcpuid = 32'b000000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
reg [31:0] mcause;
reg [31:0] mstatus;
reg [31:0] mtvec = 32'hFFFC0000;
reg [31:0] uip;
reg [31:0] mscratch;
reg [31:0] mbadaddr;
reg [31:0] usema, msema;
reg [31:0] satp;
assign asid = satp[27:22];
wire [31:0] mip;
wire mprv;
reg msip, ugip;
assign mip[31:8] = 24'h0;
assign mip[7] = 1'b0;
assign mip[6:4] = 3'b0;
assign mip[3] = msip;
assign mip[2:1] = 2'b0;
assign mip[0] = ugip;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};
reg [15:0] mtid;      // task id
wire ie = pmStack[0];
reg [31:0] mie;
wire mprv = mstatus[17];
wire [1:0] memmode;
assign MachineMode = pmStack[2:1]==2'b11;
assign UserMode = pmStack[2:1]==2'b00;
assign memmode = mprv ? pmStack[5:4] : pmStack[2:1];
wire MMachineMode = memmode==2'b11;
wire MUserMode = memmode==2'b00;

function [7:0] fnSelect;
input [6:0] op6;
input [2:0] fn3;
case(op6)
`LOAD:
	case(fn3)
	`LB,`LBU:	fnSelect = 8'h01;
	`LH,`LHU:	fnSelect = 8'h03;
	`LW,`LWU:	fnSelect = 8'h0F;
	`LD:			fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;	
	endcase
`STORE:
	case(fn3)
	`SB:	fnSelect = 8'h01;
	`SH:	fnSelect = 8'h03;
	`SW:	fnSelect = 8'h0F;
	`SD:	fnSelect = 8'hFF;
	default:	fnSelect = 8'h0F;
	endcase
default:	fnSelect = 8'h00;
endcase
endfunction

reg [31:0] ea;
wire [7:0] segsel = ea[31:24];
reg [63:0] dati;
reg [31:0] datiL;
always_comb
  datiL <= dati >> {ea[1:0],3'b0};
reg [63:0] sdat;
always @(posedge clk_g)
	case(opcode)
	default:
		sdat <= ib << {ea[1:0],3'b0};
	endcase
reg [7:0] ssel;
always @(posedge clk_g)
  ssel <= fnSelect(opcode,funct3) << ea[1:0];

wire ld = state==EXECUTE;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide support logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg sgn;
wire [WID*2-1:0] prod = ia * ib;
wire [WID*2-1:0] nprod = -prod;
wire [WID*2-1:0] div_q;
wire [WID*2-1:0] ndiv_q = -div_q;
wire [WID-1:0] div_r = ia - (ib * div_q[WID*2-1:WID]);
wire [WID-1:0] ndiv_r = -div_r;
reg ldd;
fpdivr16 #(WID) u16 (
	.clk(clk_g),
	.ld(ldd),
	.a(ia),
	.b(ib),
	.q(div_q),
	.r(),
	.done()
);
reg [7:0] mathCnt;

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

assign mip[7] = wc_time_irq;

wire pe_nmi;
reg nmif;
edge_det u17 (.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(nmi_i), .pe(pe_nmi), .ne(), .ee() );

always @(posedge wc_clk_i)
if (rst_i)
	wfi <= 1'b0;
else begin
	if (irq_i|pe_nmi)
		wfi <= 1'b0;
	else if (set_wfi)
		wfi <= 1'b1;
end

BUFGCE u11 (.CE(!wfi), .I(clk_i), .O(clk_g));

delay2 #(1) udly1 (.clk(clk_g), .ce(1'b1), .i(lcyc), .o(cyc_o));
assign pagemap_ndx = {asid,ladr[17:10]};
wire mloco = mrloc != 3'd0;

reg [4:0] cid;

always @(posedge clk_g)
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Reset
// The program counters are set at their reset values.
// System mode is activated and interrupts are masked.
// All other state is undefined.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if (rst_i) begin
	state <= IFETCH;
	pc <= RSTPC;
	mtvec <= 32'hFFFC0000;
	ASID <= 5'd0;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
	lcyc <= LOW;
	stb_o <= LOW;
	we_o <= LOW;
	ladr <= 32'h0;
	dat_o <= 32'h0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;
	instret <= 64'd0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	mstatus <= 12'b001001001110;
	pmStack <= 12'b001001001110;
	imStack <= 32'h77777777;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
  pagemapa <= 13'd0;
  ia <= 9'd0;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	getzl <= 1'b0;
	popto <= 1'b0;
	insrdy <= 1'b0;
	rmvrdy <= 1'b0;
	getrdy <= 1'b0;
	gcloc <= 6'd0;
	readyqins <= 1'b0;
	readyqrmv <= 1'b0;
	pushq <= 1'b0;
	popq <= 1'b0;
	peekq <= 1'b0;
	mrloc <= 3'd0;
	msip <= 1'b0;
	ugip <= 1'b0;
	rprv <= 5'd0;
	Rdx <= 5'd28;
	Rs1x <= 5'd28;
	Rs2x <= 5'd28;
	Rs3x <= 5'd28;
	Rdx1 <= 5'd28;
	Rs1x1 <= 5'd28;
	Rs2x1 <= 5'd28;
	Rs3x1 <= 5'd28;
	Rdx2 <= 5'd28;
	Rs1x2 <= 5'd28;
	Rs2x2 <= 5'd28;
	Rs3x2 <= 5'd28;
	rsStack <= 48'hFFFFFFFFFFFC;
	set_wfi <= 1'b0;
	poptrace <= 1'b0;
	cid <= 5'd0;
end
else begin
decto <= 1'b0;
popto <= 1'b0;
ldd <= 1'b0;
wrpagemap <= 1'b0;
if (pe_nmi)
	nmif <= 1'b1;
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
if (wc_time_irq==1'b0)
	wc_time_irq_clr <= 1'd0;
readyqins <= 1'b0;
readyqrmv <= 1'b0;
pushq <= 1'b0;
popq <= 1'b0;
peekq <= 1'b0;
poptrace <= 1'b0;

begin
	if (ladr[31:24]==8'hFF)
		adr_o <= ladr;
	else
		adr_o <= {pagemapo & 9'h1FF,ladr[9:0]};
end

case (state)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Fetch
// Get the instruction from the rom.
// Increment the program counter.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
IFETCH:
	begin
		if (cid != 5'd0)
			cid <= cid - 2'd1;
		if (traceDataCount > 10'd1020)
			poptrace <= 1'b1;
	  if (mrloc != 3'd0)
	    mrloc <= mrloc - 2'd1;
	  if (gcloc==6'd1)
	    gcie[asid] <= 1'b1;
	  if (gcloc != 6'd0)
	    gcloc <= gcloc - 2'd1;
	  Rdx2 <= Rdx1;
	  Rs1x2 <= Rs1x1;
	  Rs2x2 <= Rs2x1;
	  Rs3x2 <= Rs3x1;
		illegal_insn <= 1'b1;
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
		vpa_o <= HIGH;
		lcyc <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'hF;
		tPC();
		state <= IFETCH2;
		if (nmif) begin
			nmif <= 1'b0;
			lcyc <= LOW;
			tException(32'h800000FE,pc,6'd62,imStack[3:0]);
			pc <= mtvec + 8'hFC;
		end
 		else if (irq_i > im_level && ie && !mloco && cid==5'd0) begin
			lcyc <= LOW;
			tException(32'h80000000|cause_i,pc,6'd52+irq_i,{1'b0,irq_i});
		end
		else if (mip[7] & mie[7] & ie & ~mloco && cid==5'd0) begin
			lcyc <= LOW;
			tException(32'h80000001,pc,6'd62,imStack[3:0]);  // timer IRQ
		end
		else if (mip[3] & mie[3] & ie & ~mloco && cid==5'd0) begin
			lcyc <= LOW;
			tException(32'h80000002, pc, 6'd62,imStack[3:0]); // software IRQ
		end
		else if (uip[0] & gcie[asid] & ie & ~mloco && cid==5'd0) begin
			lcyc <= LOW;
			tException(32'h80000003, pc, 6'd62, imStack[3:0]); // garbage collect IRQ
			uip[0] <= 1'b0;
		end
		else if (pc[1:0] != 2'b00) begin
			lcyc <= LOW;
			tException(32'h00000000,pc,6'd62,imStack[3:0]);
		end
		else
			pc <= pc + 3'd4;
	end
IFETCH2:
	if (err_i) begin
		vpa_o <= LOW;
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		tException(32'h00000019,ipc,6'd62,imStack[3:0]);
	end
	else if (ack_i) begin
		vpa_o <= LOW;
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		tPC();
		ir <= dat_i[31:0];
	  Rdx <= Rdx2;
	  Rs1x <= Rs1x2;
	  Rs2x <= Rs2x2;
	  Rs3x <= Rs3x2;
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
		if (ir==`PFI) begin
			illegal_insn <= 1'b0;
			if (irq_i > im_level)
		  	tException(32'h80000000|cause_i,ipc,6'd52+irq_i, {1'b0,irq_i});
		end
		// Set some sensible decode defaults
		Rd <= 5'd0;
		imm <= 32'd0;
		// Override defaults
		case(opcode)
		`AUIPC,`LUI:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {ir[31:12],12'd0};
				wrirf <= 1'b1;
			end
		`JAL:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {{11{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
				wrirf <= 1'b1;
			end
		`JALR:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {{20{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`LOAD:
			begin
				illegal_insn <= 1'b0;
				Rd <= ir[11:7];
				imm <= {{20{ir[31]}},ir[31:20]};
				wrirf <= 1'b1;
			end
		`STORE:
			begin
				illegal_insn <= 1'b0;
				imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
			end
		7'd13:
			begin
				Rd <= ir[11:7];
				case (funct3)
				3'd0:	
					begin
						wrirf <= 1'b1;
						case(funct7)
						7'd4:	wrirf <= 1'b1;
						7'd12:  wrirf <= 1'b0; 
						default:	;
						endcase
					end
			  3'd3: 
			    begin
			      wrirf <= 1'b1;
				    imm <= {{20{ir[31]}},ir[31:20]};
			    end
			  default:  ;
				endcase
			end
		7'd19:
			begin
				case(funct3)
				3'd0:	imm <= {{20{ir[31]}},ir[31:20]};
				3'd1: imm <= ir[24:20];
				3'd2:	imm <= {{20{ir[31]}},ir[31:20]};
				3'd3: imm <= {{20{ir[31]}},ir[31:20]};
				3'd4: imm <= {{20{ir[31]}},ir[31:20]};
				3'd5: imm <= ir[24:20];
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
		`Bcc:
			imm <= {{WID-13{ir[31]}},ir[31],ir[7],ir[30:25],ir[11:8],1'b0};
		endcase
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Register fetch stage
// Fetch values from register file.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
RFETCH:
  goto (REGFETCH2);
REGFETCH2:
	begin
		state <= REGFETCH3;
		ia2 <= Rs1==5'd0 ? {WID{1'd0}} : irfoa;
		ib2 <= Rs2==5'd0 ? {WID{1'd0}} : irfob;
//    if (imm[11:0]==12'h800 && opcode!=`JAL)
//      state <= NSIMM;
    pagemapa <= Rs2==5'd0 ? {WID{1'd0}} : {irfob[21:16],irfob[8:0]};
	end
REGFETCH3:
  begin
    ea <= ia2 + imm;
    ia <= ia2;
    ib <= ib2;
    goto (EXECUTE);
  end

NSIMM:
  begin
		lcyc <= HIGH;
		stb_o <= HIGH;
		sel_o <= 4'hF;
		tPC();
  	pc <= pc + 3'd4;
		state <= NSIMM2;
  end
NSIMM2:
	if (ack_i) begin
		vpa_o <= LOW;
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
		tPC();
		imm <= dat_i[31:0];
		state <= REGFETCH2;
	end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage
// Execute the instruction.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EXECUTE:
	begin
		goto (WRITEBACK);
		case(opcode)
		`LUI:	begin res <= imm; end
		`AUIPC:	begin res <= {ipc[31:12],12'd0} + imm; end
		7'd13:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:	begin res <= ib[8] ? bregfile[ib[7:0]] : sregfile[ib[7:0]]; illegal_insn <= 1'b0; end
				7'd1:	begin illegal_insn <= 1'b0; mathCnt <= 8'd2; goto (PAGEMAPA); end
				7'd2:	begin res <= ia; illegal_insn <= 1'b0; end
				7'd8:
					begin
						setto <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd9:
					begin
						getto <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd10:	// GETZL
					begin
					  popto <= 1'b1;
					  getzl <= 1'b1;
						state <= TMO;
						illegal_insn <= 1'b0;
					end
				7'd11:
					begin
						decto <= 1'b1;
						illegal_insn <= 1'b0;
						goto (IFETCH);
					end
				7'd12:
					begin
					  pushq <= 1'b1;
						insrdy <= 1'b1;
//						state <= TMO;
						illegal_insn <= 1'b0;
//						goto (IFETCH);
					end
				7'd13:
					begin
					  popq <= 1'b1;
						rmvrdy <= 1'b1;
//						state <= TMO;
						illegal_insn <= 1'b0;
						goto (CSR);
					end
				`PEEKQ:
					begin
						peekq <= 1'b1;
						goto (CSR);
						illegal_insn <= 1'b0;
					end
				7'd32:
				  begin
	          res <= ia - ib;
			      if (UserMode) begin
  		        gcie[asid] <= 1'b0;
  		        gcloc <= ~ib[7:2] + 3'd4;
  		      end
	          illegal_insn <= 1'b0;
	        end
	      7'd33:
	      	begin
	      		illegal_insn <= 1'b0;
	      	end
				default:	;
				endcase
		  3'd3:
		    begin
          res <= ia + imm;
		      if (UserMode) begin
		        gcie[asid] <= 1'b0;
		        gcloc <= ~imm[7:2] + 3'd4;
		      end
		      illegal_insn <= 1'b0;
		    end
			default:	;
			endcase // funct3
		7'd51:
			case(funct3)
			3'd0:
				case(funct7)
				7'd0:		begin res <= ia + ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				7'd32:	begin
				          res <= ia - ib;
				          illegal_insn <= 1'b0;
				        end
				default:	;
				endcase
			3'd1:
				case(funct7)
				7'd0:	begin res <= ia << ib[4:0]; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd2:
				case(funct7)
				7'd0:	begin res <= $signed(ia) < $signed(ib); illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd3:
				case(funct7)
				7'd0:	begin res <= ia < ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd0; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd4:
				case(funct7)
				7'd0:	begin res <= ia ^ ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd5:
				case(funct7)
				7'd0:	begin res <= ia >> ib[4:0]; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
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
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
				default:	;
				endcase
			3'd7:
				case(funct7)
				7'd0:	begin res <= ia & ib; illegal_insn <= 1'b0; end
				7'd1:		begin state <= MUL1; mathCnt <= 8'd20; illegal_insn <= 1'b0; end
				default:	;
				endcase
			endcase	
		7'd19:
			case(funct3)
			3'd0:	begin
			        res <= ia + imm;
			        illegal_insn <= 1'b0;
			      end
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
		`JAL:
			begin
				res <= pc;
				pc <= ipc + imm;
				pc[0] <= 1'b0;
//				if (UserMode)
//				  uie[0] <= 1'b0;
			end
		`JALR:
			begin
				res <= pc;
				pc <= ia + imm;
				pc[0] <= 1'b0;
//				if (UserMode)
//				  uie[0] <= 1'b0;
			end
		`Bcc:
			case(funct3)
			3'd0:	begin if (ia==ib) pc <= ipc + imm; illegal_insn <= 1'b0; end
			3'd1: begin if (ia!=ib) pc <= ipc + imm; illegal_insn <= 1'b0; end
			3'd4:	begin if ($signed(ia) < $signed(ib)) pc <= ipc + imm; illegal_insn <= 1'b0; end
			3'd5:	begin if ($signed(ia) >= $signed(ib)) pc <= ipc + imm; illegal_insn <= 1'b0; end
			3'd6:	begin if (ia < ib) pc <= ipc + imm; illegal_insn <= 1'b0; end
			3'd7:	begin if (ia >= ib) pc <= ipc + imm; illegal_insn <= 1'b0; end
			default:	;
			endcase
		`LOAD,`LOADF,`AMO:
			begin
				goto (MEMORY_SETUP);
			end
		`STORE,`STOREF:
			begin
				we_o <= HIGH;
				goto (MEMORY_SETUP);
			end
		7'd115:
			begin
				case(ir)
				`EBREAK:
				  tException(4'd3, pc, 6'd63, imStack[3:0]);
				`ECALL:
  			  tException(4'h8 + pmStack[2:1],pc, 6'd61, imStack[3:0]);
				`ERET,`MRET:
					if (MachineMode) begin
						illegal_insn <= 1'b0;
					end
				`WFI:
				  begin
					  set_wfi <= 1'b1;
					  illegal_insn <= 1'b0;
				  end
				default:
					begin
					case(funct3)
					3'd1,3'd2,3'd3,3'd5,3'd6,3'd7:
						casez({funct7,Rs2})
						12'h001:	begin res <= fscsr[4:0]; illegal_insn <= 1'b0; end
						12'h002:	begin res <= rm; illegal_insn <= 1'b0; end
						12'h003:	begin res <= fscsr; illegal_insn <= 1'b0; end
						12'h004:	begin res <= gcie[asid]; illegal_insn <= 1'b0; end
						12'h044:	begin res <= uip[0]; illegal_insn <= 1'b0; end
						12'h180:	begin res <= satp; illegal_insn <= 1'b0; end
						12'h181:	begin res <= ASID; illegal_insn <= 1'b0; end
						12'h300:	begin res <= mstatus; illegal_insn <= 1'b0; end
						12'h301:	begin res <= mtvec; illegal_insn <= 1'b0; end
						12'h304:	begin res <= mie; illegal_insn <= 1'b0; end
						12'h321:	begin res <= mtimecmp; wc_time_irq_clr <= 6'h3F; illegal_insn <= 1'b0; end
						12'h340:	begin res <= mscratch; illegal_insn <= 1'b0; end
						12'h341:	begin res <= mepc[rprv[4] ? rsStack[11:6] : rsStack[5:0]]; illegal_insn <= 1'b0; end
						12'h342:	begin res <= mcause; illegal_insn <= 1'b0; end
						12'h343:	begin res <= mbadaddr; illegal_insn <= 1'b0; end
						12'h344:	begin res <= mip; illegal_insn <= 1'b0; end
						12'h7A0:  begin res <= traceOn; illegal_insn <= 1'b0; end
						12'h7C0:	if (MachineMode) begin res <= rprv; illegal_insn <= 1'b0; end
						12'h7C1:  if (MachineMode) begin res <= msema; illegal_insn <= 1'b0; end
						12'h7C2:  if (MachineMode) begin res <= mtid; illegal_insn <= 1'b0; end
						12'h7C3:  if (MachineMode) begin res <= rsStack; illegal_insn <= 1'b0; end
						12'h7C4:
						  if (MachineMode) begin
						    res <= pmStack;
						    illegal_insn <= 1'b0;
						  end
						12'h7C5:
							if (MachineMode) begin
								res <= imStack;
								illegal_insn <= 1'b0;
							end
//						12'h801:  begin res <= usema; illegal_insn <= 1'b0; end
						12'hC00:	begin res <= tick[31: 0]; illegal_insn <= 1'b0; end
						12'hC80:	begin res <= tick[63:32]; illegal_insn <= 1'b0; end
						12'hC01,12'h701,12'hB01:	begin res <= wc_times[31: 0]; illegal_insn <= 1'b0; end
						12'hC81,12'h741,12'hB81:	begin res <= wc_times[63:32]; illegal_insn <= 1'b0; end
						12'hC02:	begin res <= instret[31: 0]; illegal_insn <= 1'b0; end
						12'hC82:	begin res <= instret[63:32]; illegal_insn <= 1'b0; end
						12'hF00:	begin res <= mcpuid; illegal_insn <= 1'b0; end	// cpu description
						12'hF01:	begin res <= mimpid; illegal_insn <= 1'b0; end // implmentation id
						12'hF10:	begin res <= hartid_i; illegal_insn <= 1'b0; end
//						12'hFC1:  begin res <= usema; illegal_insn <= 1'b0; end
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
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CSR:  goto (CSR2);
CSR2:
  begin
    casez(ia[3:0])
    4'b0???:  res <= queueo;
    4'd13:		res <= traceOut[63:32];
    4'b1110:  res <= {traceEmpty,traceValid,traceDataCount[9:0],traceOut[19:0]};
    4'b1111:  res <= {traceEmpty,traceValid,traceDataCount[9:0],8'h00,traceOut[31:20]};
    default:  res <= 32'h0;
    endcase
    goto (WRITEBACK);
  end
PAGEMAPA:
  begin
    mathCnt <= mathCnt - 2'd1;
    if (mathCnt==8'd0) begin
      res <= {23'd0,pagemapoa}; 
      goto (WRITEBACK);
    end
  end
TMO:
	if (to_done) begin
		illegal_insn <= 1'b0;
		case({getto,getrdy,getzl})
		3'b100:	res <= to_out;
		3'b010:	res <= {{24{rdy_out[7]}},rdy_out};
		3'b001: begin res <= {zladr[7],15'h00,zladr,zl_out}; getzl <= 1'b0; end
		default:	res <= {zladr[7],15'h00,zladr,zl_out};
		endcase
  	goto (WRITEBACK);
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		ldd <= 1'b1;
		case(funct3)
		3'd0,3'd1,3'd4,3'd6:							// MUL / MULH / DIV / REM
			begin
				sgn <= ia[WID-1] ^ ib[WID-1];	// compute output sign
				if (ia[WID-1]) ia <= -ia;			// Make both values positive
				if (ib[WID-1]) ib <= -ib;
				state <= MUL2;
			end
		3'd2:										// MULHSU
			begin
				sgn <= ia[WID-1];
				if (ia[WID-1]) ia <= -ia;
				state <= MUL2;
			end
		3'd3,3'd5,3'd7:	state <= MUL2;		// MULHU / DIVU / REMU
		endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
			state <= WRITEBACK;
			case(funct3)
			3'd0:	res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			3'd1:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			3'd2:	res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			3'd3:	res <= prod[WID*2-1:WID];
			3'd4:	res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			3'd5: res <= div_q[WID*2-1:WID];
			3'd6:	res <= sgn ? ndiv_r : div_r;
			3'd7:	res <= div_r;
			endcase
		end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MEMORY_SETUP:
  begin
		goto (MEMORY);
		lcyc <= HIGH;
		stb_o <= HIGH;
		sel_o <= ssel[3:0];
 		dat_o <= sdat[31:0];
		tEA();
  	case(opcode)
		`STORE:
			begin
    		case(funct3)
    		`SB,`SH,`SW:
    		  begin
    		    illegal_insn <= 1'b0;
    		  end
    		default:	
    		  begin
    		    tPC();
    		    goto (WRITEBACK); // Illegal instruction
    		  end
    		endcase
			end
    endcase
  end
MEMORY:
	if (err_i) begin
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
    we_o <= LOW;
		tException(32'h00000019,ipc,6'd62,imStack[3:0]);
	end
	else if (ack_i) begin
		stb_o <= LOW;
		if (ssel[7:4]==4'h0) begin
			lcyc <= LOW;
			sel_o <= 4'h0;
			sr_o <= 1'b0;
			cr_o <= 1'b0;
	    we_o <= LOW;
			tPC();
			goto (rty_i ? MEMORY_SETUP: MEMORY2_SETUP);
		end
		else
			state <= rty_i ? MEMORY_SETUP : MEMORY2_SETUP;
		dati[31:0] <= dat_i;
	end
// Run a second bus cycle to handle unaligned access.
// The paging unit needs a cycle for address lookup on a change of ladr.
MEMORY2_SETUP:
	if (~ack_i) begin
		ladr <= {ladr[31:2]+2'd1,2'd0};
		case(opcode)
		`LOAD:
			case(funct3)
			`LB:	begin res <= {{24{datiL[7]}},datiL[7:0]}; illegal_insn <= 1'b0; end
			`LH:  begin res <= {{16{datiL[15]}},datiL[15:0]}; illegal_insn <= 1'b0; end
			`LW:	begin res <= datiL; illegal_insn <= 1'b0; end
			`LBU:	begin res <= {24'd0,datiL[7:0]}; illegal_insn <= 1'b0; end
			`LHU:	begin res <= {16'd0,datiL[15:0]}; illegal_insn <= 1'b0; end
			default:	;
			endcase
		endcase
		if (ssel[7:4]==4'h0) begin
		  tPC();
		  we_o <= LOW;
		  goto (WRITEBACK);
		end
		else
  		goto (MEMORY2);
  end
MEMORY2:
	begin
		stb_o <= HIGH;
		sel_o <= ssel[7:4];
		dat_o <= sdat[63:32];
		state <= MEMORY2_ACK;
	end
MEMORY2_ACK:
	if (err_i) begin
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
    we_o <= LOW;
		tException(32'h00000019,ipc,6'd62,imStack[3:0]);
	end
	else if (ack_i) begin
		dati[63:32] <= dat_i;
		lcyc <= LOW;
		stb_o <= LOW;
		sel_o <= 4'h0;
    we_o <= LOW;
		sr_o <= 1'b0;
		cr_o <= 1'b0;
		state <= rty_i ? MEMORY2_SETUP : MEMORY3;
		if (rty_i)
			ladr <= {ladr[31:2]-2'd1,2'd0};
	end
MEMORY3:
	if (~ack_i) begin
		tPC();
		goto (MEMORY4);
		case(opcode)
		`LOAD:
			begin
				case(funct3)
				`LH: res <= {{16{datiL[15]}},datiL[15:0]};
				`LW: res <= datiL;
				`LHU:	res <= {16'd0,datiL[15:0]};
				default:	;
				endcase
			end
		endcase
	end
MEMORY4:
  begin
    tPC();
	  goto (WRITEBACK);
  end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Writeback stage
// Update the register file (actual clocking above).
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
WRITEBACK:
	begin
		getto <= 1'b0;
		setto <= 1'b0;
		insrdy <= 1'b0;
		rmvrdy <= 1'b0;
		getrdy <= 1'b0;
		set_wfi <= 1'b0;
		case(ir)
		`ERET,`MRET:
			if (MachineMode) begin
			  rsStack <= {6'd63,rsStack[47:6]};
			  rprv <= 5'h0;
			  Rdx1 <= rsStack[11:6];
			  Rs1x1 <= rsStack[11:6];
			  Rs2x1 <= rsStack[11:6];
			  Rs3x1 <= rsStack[11:6];
				pc <= mepc[rsStack[5:0]];
				mstatus[11:0] <= {2'b00,1'b1,mstatus[11:3]};
				pmStack <= {3'b001,pmStack[29:3]};
				imStack <= {4'h7,imStack[31:4]};
				mrloc <= 3'd3;
			end
		endcase
		if (illegal_insn)
		  tException(32'd2, ipc, 6'd61, imStack[3:0]);
		if (!illegal_insn && opcode==7'd13) begin
			case(funct3)
			3'd0:
				if (Rs1 != 5'd0)
				case(funct7)
				7'd0:	if (ib[8]) begin
								bregfile[ib[7:0]] <= ia;
								if (ib[7:0]==8'd255)
									cs_bound <= ia;
							end
							else begin	
								sregfile[ib[7:0]] <= ia;
								if (ib[7:0]==8'd255)
									cs_base <= ia;
							end
				7'd1:		wrpagemap <= 1'b1;
				7'd33:	cid <= Rs1;
				default:	;
				endcase
			default:	;
			endcase
		end
		if (!illegal_insn && opcode==7'd115) begin
			case(funct3)
			3'd1,3'd5:
				if (Rs1!=5'd0)
				casez({funct7,Rs2})
				12'h004:	gcie[asid] <= ia[0];
			  12'h044:  uip[0] <= ia[0];
//				12'h044:	begin if (UserMode) uip <= ia; end
				12'h180:	begin if (MachineMode) satp <= ia; end
				12'h181:	begin if (MachineMode) ASID <= ia; end
				12'h300:	begin if (MachineMode) mstatus <= ia; end
				12'h301:	begin if (MachineMode) mtvec <= {ia[31:2],2'b0}; end
				12'h304:	begin if (MachineMode) mie <= ia; end
				12'h321:	begin if (MachineMode) mtimecmp <= ia; end
				12'h340:	begin if (MachineMode) mscratch <= ia; end
//				12'b00??_0100_0001: begin mepc[rprv] <= ia; end
				12'h341:	begin if (MachineMode) mepc[rprv[4] ? rsStack[11:6] : rsStack[5:0]] <= ia; end
				12'h342:	begin if (MachineMode) mcause <= ia; end
				12'h343:  begin if (MachineMode) mbadaddr <= ia; end
				12'h344:	begin if (MachineMode) msip <= ia[3]; end
				12'h7A0:  traceOn <= ia[0];
				12'h7C0:
			    if (MachineMode) begin
			      rprv <= ia[4:0];
			      Rdx1  <= ia[0] ? rsStack[11:6] : rsStack[5:0];
			      Rs1x1 <= ia[1] ? rsStack[11:6] : rsStack[5:0];
			      Rs2x1 <= ia[2] ? rsStack[11:6] : rsStack[5:0];
			      Rs3x1 <= ia[3] ? rsStack[11:6] : rsStack[5:0];
			    end
				12'h7C1:  begin if (MachineMode) begin msema <= ia; end end
				12'h7C2:  begin if (MachineMode) begin mtid <= ia; end end
				12'h7C3:  begin if (MachineMode) rsStack <= ia; end
				12'h7C4:  begin if (MachineMode) pmStack <= ia; end
				12'h7C5:	begin if (MachineMode) imStack <= ia; end
//				12'h801:  begin if (UserMode) usema <= ia; end
				default:	;
				endcase
			3'd2,3'd6:
				if (Rs1!=5'd0)
				case({funct7,Rs2})
				// No setting CSR $000
			  12'h004:  gcie[asid] <= gcie[asid] | ia[0];
			  12'h044:  uip[0] <= uip[0] | ia[0];
//				12'h044:	if (UserMode) uip <= uip | ia;
			  12'h300:  begin
			              if (MachineMode)
			                mstatus <= mstatus | ia;
			            end
				12'h304:	if (MachineMode) mie <= mie | ia;
				12'h344:	if (MachineMode) msip <= msip | ia[3];
				12'h7A0:  traceOn <= traceOn | ia[0];
				12'h7C0:
				  if (MachineMode) begin
				    rprv  <= rprv | ia[4:0];
				    Rdx1  <= (ia[0]|rprv[0]) ? rsStack[11:6] : rsStack[5:0];
			      Rs1x1 <= (ia[1]|rprv[1]) ? rsStack[11:6] : rsStack[5:0];
			      Rs2x1 <= (ia[2]|rprv[2]) ? rsStack[11:6] : rsStack[5:0];
			      Rs3x1 <= (ia[3]|rprv[3]) ? rsStack[11:6] : rsStack[5:0];
				  end
				12'h7C1:  if (MachineMode) msema <= msema | ia;
//				12'h801:  if (UserMode) usema <= usema | ia;
        12'h7C3:  if (MachineMode) rsStack <= rsStack | ia;
        12'h7C4:  if (MachineMode) pmStack <= pmStack | ia;
				12'h7C5:	if (MachineMode) imStack <= imStack | ia;
				default: ;
				endcase
			3'd3,3'd7:
				if (Rs1!=5'd0)
				case({funct7,Rs2})
			  12'h004:  gcie[asid] <= gcie[asid] & ~ia[0];
			  12'h044:  uip[0] <= uip[0] & ~ia[0];
//				12'h044:	if (UserMode) uip <= uip & ~ia;
				// For the status register interrupts are allowed to be enabled from
				// user mode. Interrupts cannot be disabled from user mode.
				12'h300:  if (MachineMode) mstatus <= mstatus & ~ia;
				12'h304:	if (MachineMode) mie <= mie & ~ia;
				12'h344:	if (MachineMode) msip <= msip & ~ia[3];
				12'h7A0:  traceOn <= traceOn & ~ia[0];
				12'h7C0:
				  if (MachineMode) begin
				    rprv  <= rprv & ~ia[4:0];
				    Rdx1  <= (rprv[0]&~ia[0]) ? rsStack[11:6] : rsStack[5:0];
			      Rs1x1 <= (rprv[1]&~ia[1]) ? rsStack[11:6] : rsStack[5:0];
			      Rs2x1 <= (rprv[2]&~ia[2]) ? rsStack[11:6] : rsStack[5:0];
			      Rs3x1 <= (rprv[3]&~ia[3]) ? rsStack[11:6] : rsStack[5:0];
				  end
				12'h7C1:  if (MachineMode) msema <= msema & ~ia;
//				12'h801:  if (UserMode) usema <= usema & ~ia;
        12'h7C3:  if (MachineMode) rsStack <= rsStack & ~ia;
        12'h7C4:  if (MachineMode) pmStack <= pmStack & ~ia;
				12'h7C5:	if (MachineMode) imStack <= imStack & ~ia;
				default: ;
				endcase
			default:	;
			endcase
		end
		tPC();
		goto (IFETCH);
		instret <= instret + 2'd1;
	end
endcase
end

task tEA;
begin
	if (ea[WID-1:24]=={WID-24{1'b1}})
		ladr <= ea;
	else
		ladr <= ea[WID-9:0] + {sregfile[segsel][WID-1:4],10'd0};
end
endtask

task tPC;
begin
	if (pc[WID-1:24]=={WID-24{1'b1}})
		ladr <= pc;
	else
		ladr <= pc[WID-1:0] + {cs_base[WID-1:4],10'd0};
end
endtask

task tException;
input [31:0] cse;
input [31:0] tpc;
input [5:0] rs;
input [3:0] ml;
begin
	pc <= mtvec + {pmStack[2:1],6'h00};
	mepc[rs] <= tpc;
	pmStack <= {pmStack[28:0],2'b11,1'b0};
	mstatus[11:0] <= {mstatus[8:0],2'b11,1'b0};
	imStack <= {imStack[27:0],ml};
	mcause <= cse;
	illegal_insn <= 1'b0;
	instret <= instret + 2'd1;
  rprv <= 5'h0;
  Rdx1 <= rs;
  Rs1x1 <= rs;
  Rs2x1 <= rs;
  Rs3x1 <= rs;
  rsStack <= {rsStack[41:0],rs};
	goto (IFETCH);
end
endtask

task goto;
input [5:0] nst;
begin
  state <= nst;
end
endtask

endmodule
