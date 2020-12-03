// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rtf64.sv
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
//`define SIM   1'b1

`include "../inc/rtf64-defines.sv"
`include "../inc/rtf64-config.sv"

`ifdef CPU_B128
`define SELH    31:16
`define DATH    255:128
`endif
`ifdef CPU_B64
`define SELH    15:8
`define DATH    127:64
`endif
`ifdef CPU_B32
`define SELH    7:4
`define DATH    63:32
`endif

`include "../fpu/fpConfig.sv"

module rtf64(hartid_i, rst_i, clk_i, wc_clk_i, nmi_i, irq_i, cause_i, vpa_o, cyc_o, stb_o, ack_i, sel_o, we_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i);
parameter WID = 64;
parameter AWID = 32;
parameter FPWID = `FPWID;
parameter RSTPC = 64'hFFFFFFFFFFFC0100;
parameter pL1CacheLines = 128;
localparam pL1msb = $clog2(pL1CacheLines-1)-1+5;
input [7:0] hartid_i;
input rst_i;
input clk_i;
input wc_clk_i;
input nmi_i;
input irq_i;
input [7:0] cause_i;
output reg vpa_o;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [15:0] sel_o;
output reg [AWID-1:0] adr_o;
`ifdef CPU_B128
input [127:0] dat_i;
output reg [127:0] dat_o;
`endif
`ifdef CPU_B64
input [63:0] dat_i;
output reg [63:0] dat_o;
`endif
`ifdef CPU_B32
input [31:0] dat_i;
output reg [31:0] dat_o;
`endif
output reg sr_o;
output reg cr_o;
input rb_i;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter LOW = 1'b0;
parameter HIGH = 1'b1;

integer n;
reg [5:0] state;
parameter IFETCH1 = 6'd1;
parameter IFETCH2 = 6'd2;
parameter IFETCH3 = 6'd3;
parameter IFETCH4 = 6'd4;
parameter DECODE = 6'd5;
parameter REGFETCH1 = 6'd6;
parameter REGFETCH2 = 6'd7;
parameter EXECUTE = 6'd8;
parameter WRITEBACK = 6'd9;
parameter MEMORY1 = 6'd11;
parameter MEMORY2 = 6'd12;
parameter MEMORY3 = 6'd13;
parameter MEMORY4 = 6'd14;
parameter MEMORY5 = 6'd15;
parameter MEMORY6 = 6'd16;
parameter MEMORY7 = 6'd17;
parameter MEMORY8 = 6'd18;
parameter MEMORY9 = 6'd19;
parameter MEMORY10 = 6'd20;
parameter MEMORY11 = 6'd21;
parameter MEMORY12 = 6'd22;
parameter MEMORY13 = 6'd23;
parameter MEMORY14 = 6'd24;
parameter MEMORY15 = 6'd25;
parameter MUL1 = 6'd26;
parameter MUL2 = 6'd27;
parameter PAM	 = 6'd28;
parameter TMO = 6'd29;
parameter PAGEMAPA = 6'd30;
parameter CSR1 = 6'd31;
parameter CSR2 = 6'd32;
parameter DATA_ALIGN = 6'd33;
parameter MEMORY_KEYCHK1 = 6'd34;
parameter MEMORY_KEYCHK2 = 6'd35;
parameter MEMORY_KEYCHK3 = 6'd36;
parameter FLOAT = 6'd37;
parameter INSTRUCTION_ALIGN = 6'd38;
parameter IFETCH5 = 6'd39;
parameter MEMORY1a = 6'd40;
parameter MEMORY6a = 6'd41;
parameter MEMORY11a = 6'd42;
parameter IFETCH2a = 6'd43;
parameter REGFETCH3 = 6'd44;
parameter EXPAND_CI = 6'd45;
parameter IFETCH3a = 6'd46;

`include "../fpu/fpSize.sv"

reg [AWID-1:0] pc, ipc, ret_pc;
reg illegal_insn;
reg [63:0] ir;
reg [255:0] iri1, iri2, ici;
wire [7:0] opcode = ir[7:0];
wire [4:0] funct5 = ir[30:26];
wire [2:0] mop = ir[12:10];
wire [2:0] rm3 = ir[31:29];
reg [4:0] Rd;
reg [1:0] Cd, Cs;
reg [4:0] Rs1, Rs2, Rs3;
reg [4:0] Rdx, Rs1x, Rs2x, Rs3x;
reg [4:0] Rdx1, Rs1x1, Rs2x1, Rs3x1;
reg rad;
wire [63:0] irfoRs1, irfoRs2, irfoRs3, irfoRd;
wire [63:0] frfoa, frfob, frfoc;
wire [63:0] prfoa, prfob, prfoc;
reg [63:0] ia,ib,ic,id,imm;
reg [64:0] res;
reg [7:0] crres;
reg pc_reload;
reg wrra, wrca;
reg wrirf,wrcrf,wrcrf32,wrfrf,wrprf;
wire memmode, UserMode, SupervisorMode, HypervisorMode, MachineMode, InterruptMode, DebugMode;
wire st_writeback = state==WRITEBACK;
wire st_ifetch2 = state==IFETCH2;
wire st_decode = state==DECODE;
wire st_execute = state==EXECUTE;
// POP needs to update the register file twice, once for the stack pointer and
// again for the loaded value. So, it the first update takes place in the EX
// stage. This means that if something goes wrong with the load the stack
// pointer will already have been updated.
wire wr_pop = state==EXECUTE && opcode==`POP;
wire wr_link = (state==EXECUTE && (opcode==`LINK || opcode==`UNLINK)) ||
               (state==MEMORY1 && opcode==`LINK);
wire wr_rf = (st_writeback | wr_pop | wr_link) & wrirf;

// It takes 6 block rams to get triple output ports with 32 sets of 32 regs.

regfile64 uirfRs1 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr_rf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(irfoRd),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs1x,Rs1}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs1)  // output wire [63 : 0] doutb
);

regfile64 uirfRs2 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr_rf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs2x,Rs2}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs2)  // output wire [63 : 0] doutb
);

regfile64 uirfRs3 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr_rf),      // input wire [0 : 0] wea
  .addra({Rdx,Rd}),  // input wire [9 : 0] addra
  .dina(res[63:0]),    // input wire [63 : 0] dina
  .douta(),  // output wire [63 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb({Rs3x,Rs3}),  // input wire [9 : 0] addrb
  .dinb(64'd0),    // input wire [63 : 0] dinb
  .doutb(irfoRs3)  // output wire [63 : 0] doutb
);

`ifdef SIM
reg [63:0] iregfile [0:31];
always @(posedge clk_g)
  if (wrirf & st_writeback)
    iregfile[Rd] <= res[63:0];
`endif

// Float registers
reg [WID-1:0] fregfile [0:31];
assign frfoa = fregfile[Rs1];
assign frfob = fregfile[Rs2];
assign frfoc = fregfile[Rs3];
always @(posedge clk_g)
  if (st_writeback & wrfrf)
    fregfile[Rd] <= res;

// Posit registers
reg [WID-1:0] pregfile [0:31];
assign prfoa = pregfile[Rs1];
assign prfob = pregfile[Rs2];
assign prfoc = pregfile[Rs3];
always @(posedge clk_g)
  if (st_writeback & wrprf)
    pregfile[Rd] <= res;

reg [AWID-1:0] ra [0:63]; // ra0 = 0-31, ra1 = 32 to 63
reg [AWID-1:0] ca [0:63];
reg [31:0] cregfile [0:31];
reg [AWID-1:0] sregfile [0:15];
wire [64:0] difi = ia - imm;
wire [64:0] difr = ia - ib;
wire [63:0] andi = ia & imm;
wire [63:0] andr = ia & ib;
wire [63:0] biti = andi;
wire [63:0] bitr = andr;

wire [15:0] blendR1 = ia[23:16] * ic[7:0];
wire [15:0] blendG1 = ia[15: 8] * ic[7:0];
wire [15:0] blendB1 = ia[ 7: 0] * ic[7:0];
wire [15:0] blendR2 = ib[23:16] * ~ic[7:0];
wire [15:0] blendG2 = ib[15: 8] * ~ic[7:0];
wire [15:0] blendB2 = ib[ 7: 0] * ~ic[7:0];
wire [4:0] crs;
reg [AWID-1:0] rares;

wire [31:0] cd32 = cregfile[Rdx];
wire [31:0] cds32 = cregfile[Rs1x];
wire [31:0] cds322 = cregfile[Rs2x];
always @(posedge clk_g)
  if (wrcrf && state==IFETCH1)
    case(Cd)
    2'd0: cregfile[Rdx] <= {cd32[31:8],crres[7:0]};
    2'd1: cregfile[Rdx] <= {cd32[31:16],crres[7:0],cd32[7:0]};
    2'd2: cregfile[Rdx] <= {cd32[31:24],crres[7:0],cd32[15:0]};
    2'd3: cregfile[Rdx] <= {crres[7:0],cd32[23:0]};
    endcase
  else if (wrcrf32 & st_writeback)
    cregfile[Rdx] <= res[31:0];
initial begin
  for (n = 0; n < 32; n = n + 1)
    cregfile[n] <= 32'h0;
end
wire [7:0] cd = cd32 >> {Cs,3'b0};
wire [7:0] cd2 = cds322 >> {Cs,3'b0};
wire [7:0] cds = cds32 >> {Rs1[1:0],3'b0};

// CSRs
reg [7:0] cause [0:7];
reg [AWID-1:0] tvec [0:7];
reg [AWID-1:0] badaddr [0:7];
reg [31:0] status [0:7];
wire mprv = status[5][17];
wire uie = status[5][0];
wire sie = status[5][1];
wire hie = status[5][2];
wire mie = status[5][3];
wire iie = status[5][4];
wire die = status[5][5];
reg [31:0] gcie;
reg [63:0] scratch [0:7];
reg [39:0] instret;
reg [39:0] instfetch;
reg [AWID-1:0] epc [0:31];
reg [AWID-1:0] next_epc;
reg [31:0] pmStack;
reg [31:0] rsStack;
reg [4:0] rprv;
reg [4:0] ASID;
reg [23:0] TaskId;
reg [5:0] gcloc;    // garbage collect lockout count
reg [2:0] mrloc;    // mret lockout
reg [31:0] uip;     // user interrupt pending
reg [4:0] regset;
assign crs = rsStack[4:0];
reg [63:0] tick;		// cycle counter
reg [63:0] wc_time;	// wall-clock time
reg wc_time_irq;
wire clr_wc_time_irq;
reg [5:0] wc_time_irq_clr;
reg wfi;
reg set_wfi = 1'b0;
reg [31:0] mtimecmp;
reg [31:0] mcpuid = 32'b000000_00_00000000_00010001_00100001;
reg [31:0] mimpid = 32'h01108000;
reg [31:0] mscratch;
reg [31:0] mbadaddr;
reg [31:0] usema, msema;
wire [31:0] mip;
reg msip, ugip;
assign mip[31:8] = 24'h0;
assign mip[7] = 1'b0;
assign mip[6:4] = 3'b0;
assign mip[3] = msip;
assign mip[2:1] = 2'b0;
assign mip[0] = ugip;
reg [2:0] rm;
reg fdz,fnv,fof,fuf,fnx;
wire [31:0] fscsr = {rm,fnv,fdz,fof,fuf,fnx};
reg [15:0] mtid;      // task id
wire ie = pmStack[0];
reg [31:0] miex;
reg [19:0] key [0:8];
// Debug
reg [AWID-1:0] dbad [0:3];
reg [63:0] dbcr;
reg [3:0] dbsr;

reg d_lea, d_cache, d_jsr, d_rts;
reg d_cmp,d_set,d_tst,d_mov,d_stot,d_stptr,d_setkey,d_gcclr;
reg d_shiftr, d_st, d_ld, d_cbranch, d_wha;
reg d_pushq, d_popq, d_peekq, d_statq;
reg setto, getto, decto, getzl, popto;
reg pushq, popq, peekq, statq; 
reg d_exti, d_extr, d_extur, d_extui, d_depi, d_depr, d_depii, d_flipi, d_flipr;
reg d_ffoi, d_ffor;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk_g)
  if (st_writeback)
    if (wrra)
      ra[{rad,rprv ? rsStack[9:5] : crs}] <= rares;
wire [AWID-1:0] rao = ra[{d_stot ? Rs2[0] : d_mov ? Rs1[0] : ir[8],rprv ? rsStack[9:5] : crs}];

always @(posedge clk_g)
  if (st_writeback)
    if (wrca)
      ca[{rad,rprv ? rsStack[9:5] : crs}] <= rares;
wire [AWID-1:0] cao = ca[{d_stot ? Rs2[0] : d_mov ? Rs1[0] : ir[8],rprv ? rsStack[9:5] : crs}];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// MMU
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg keyViolation;
reg [AWID-1:0] ladr;
reg wrpagemap;
wire [13:0] pagemapoa, pagemapo;
reg [16:0] pagemapa;
wire [16:0] pagemap_ndx = {ASID,ladr[25:14]};

`ifdef RTF64_PAGEMAP
// 131072 x14 bit entries
PagemapRam upageram (
  .clka(clk_g),   // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrpagemap),      // input wire [0 : 0] wea
  .addra({ib[20:16],ib[11:0]}),  // input wire [16 : 0] addra
  .dina(ia[13:0]),    // input wire [13 : 0] dina
  .douta(pagemapoa),  // output wire [13 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(pagemap_ndx),  // input wire [16 : 0] addrb
  .dinb(14'd0),    // input wire [13 : 0] dinb
  .doutb(pagemapo)  // output wire [13 : 0] doutb
);
`endif

reg memaccess;
wire [19:0] keyo, keyoa;
KeyMemory ukm1 (
  .clka(clk_g),    // input wire clka
  .ena(d_setkey),      // input wire ena
  .wea(st_writeback & ~ia[31]),      // input wire [0 : 0] wea
  .addra(ia[45:32]),  // input wire [13 : 0] addra
  .dina(ia[19:0]),    // input wire [19 : 0] dina
  .douta(keyoa),  // output wire [19 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .web(1'b0),      // input wire [0 : 0] web
  .addrb(adr_o[27:14]),  // input wire [13 : 0] addrb
  .dinb(20'h0),    // input wire [19 : 0] dinb
  .doutb(keyo)  // output wire [19 : 0] doutb
);

wire MUserMode;
wire keymem_cs = MUserMode && adr_o[31:28]==4'h0;

reg icaccess;
reg [AWID-1:0] iadr;
reg xlaten;
reg tlben, tlbwr;
wire tlbmiss;
wire [3:0] tlbacr;
wire [63:0] tlbdato;

`ifdef RTF64_TLB
rtf64_TLB utlb (
  .rst_i(rst_i),
  .clk_i(clk_g),
  .asid_i(ASID),
  .umode_i(vpa_o ? UserMode : MUserMode),
  .xlaten_i(xlaten),
  .we_i(we_o),
  .ladr_i(ladr),
  .iacc_i(icaccess),
  .iadr_i(iadr),
  .padr_o(adr_o), // ToDo: fix this for icache access
  .acr_o(tlbacr),
  .tlben_i(tlben),
  .wrtlb_i(tlbwr),
  .tlbadr_i(ia[11:0]),
  .tlbdat_i(ib),
  .tlbdat_o(tlbdato),
  .tlbmiss_o(tlbmiss)
);
`endif

wire [31:0] card21o, card22o, card1o;
wire [63:0] cardmem0o;
reg [63:0] cardmem0;
always @(posedge clk_g)
  if (d_gcclr & ~ia[31] && ia[30:28]==3'd0)
    cardmem0 <= ib[63:0];
  else if (d_stptr)
    cardmem0[adr_o[27:22]] <= 1'b1;
assign cardmem0o = cardmem0;

CardMemory2 ucard1 (
  .clka(clk_g),    // input wire clka
  .ena(d_stptr & ~adr_o[9]),      // input wire ena
  .wea(d_stptr & ~adr_o[9]),      // input wire [0 : 0] wea
  .addra(adr_o[27:10]),  // input wire [17 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(d_gcclr && ia[30:28]==3'd2),      // input wire enb
  .web(st_writeback & d_gcclr & ~ia[31]),      // input wire [0 : 0] web
  .addrb(ia[15:3]),  // input wire [11 : 0] addrb
  .dinb(ib[31:0]),    // input wire [31 : 0] dinb
  .doutb(card21o)  // output wire [31 : 0] doutb
);
CardMemory2 ucard2 (
  .clka(clk_g),    // input wire clka
  .ena(d_stptr & adr_o[9]),      // input wire ena
  .wea(d_stptr & adr_o[9]),      // input wire [0 : 0] wea
  .addra(adr_o[27:10]),  // input wire [17 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(d_gcclr && ia[30:28]==3'd2),      // input wire enb
  .web(st_writeback & d_gcclr & ~ia[31]),      // input wire [0 : 0] web
  .addrb(ia[15:3]),  // input wire [11 : 0] addrb
  .dinb(ib[63:32]),    // input wire [31 : 0] dinb
  .doutb(card22o)  // output wire [31 : 0] doutb
);
CardMemory1 ucard3 (
  .clka(clk_g),    // input wire clka
  .ena(d_stptr),      // input wire ena
  .wea(d_stptr),      // input wire [0 : 0] wea
  .addra(adr_o[27:16]),  // input wire [11 : 0] addra
  .dina(1'b1),    // input wire [0 : 0] dina
  .douta(),  // output wire [0 : 0] douta
  .clkb(clk_g),    // input wire clkb
  .enb(d_gcclr && ia[30:28]==3'd1),      // input wire enb
  .web(st_writeback & d_gcclr & ~ia[31]),      // input wire [0 : 0] web
  .addrb(ia[9:3]),  // input wire [6 : 0] addrb
  .dinb(ib[31:0]),    // input wire [31 : 0] dinb
  .doutb(card1o)  // output wire [31 : 0] doutb
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// PMA Checker
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [AWID-4:0] PMA_LB [0:7];
reg [AWID-4:0] PMA_UB [0:7];
reg [15:0] PMA_AT [0:7];

initial begin
  PMA_LB[7] = 28'hFFFC000;
  PMA_UB[7] = 28'hFFFFFFF;
  PMA_AT[7] = 16'h000D;       // rom, byte addressable, cache-read-execute
  PMA_LB[6] = 28'hFFD0000;
  PMA_UB[6] = 28'hFFD1FFF;
  PMA_AT[6] = 16'h0206;       // io, (screen) byte addressable, read-write
  PMA_LB[5] = 28'hFFD2000;
  PMA_UB[5] = 28'hFFDFFFF;
  PMA_AT[5] = 16'h0206;       // io, byte addressable, read-write
  PMA_LB[4] = 28'hFFFFFFF;
  PMA_UB[4] = 28'hFFFFFFF;
  PMA_AT[4] = 16'hFF00;       // vacant
  PMA_LB[3] = 28'hFFFFFFF;
  PMA_UB[3] = 28'hFFFFFFF;
  PMA_AT[3] = 16'hFF00;       // vacant
  PMA_LB[2] = 28'hFFFFFFF;
  PMA_UB[2] = 28'hFFFFFFF;
  PMA_AT[2] = 16'hFF00;       // vacant
  PMA_LB[1] = 28'h1000000;
  PMA_UB[1] = 28'hFFCFFFF;
  PMA_AT[1] = 16'hFF00;       // vacant
  PMA_LB[0] = 28'h0000000;
  PMA_UB[0] = 28'h0FFFFFF;
  PMA_AT[0] = 16'h010F;       // ram, byte addressable, cache-read-write-execute
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Evaluate branch condition
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire takb;
reg [63:0] brdat;
rtf64_EvalBranch ueb1
(
  .inst(ir[23:0]),
  .brdat(brdat),
  .takb(takb)
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Operation mask for byte, wyde, tetra format operations.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [63:0] op_mask;
always @*
case(ir[25:23]) // Fmt
3'd0: op_mask = {64{1'b1}};
3'd1: op_mask = {32{1'b1}};
3'd2: op_mask = {16{1'b1}};
3'd3: op_mask = {8{1'b1}};
default:  op_mask = {64{1'b1}};
endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Trace
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg wr_trace, rd_trace;
reg wr_whole_address;
reg [5:0] br_hcnt;
reg [5:0] br_rcnt;
reg [63:0] br_history;
wire [63:0] trace_dout;
wire trace_full;
wire trace_empty;
wire trace_valid;
reg tron;
wire [3:0] trace_match;
assign trace_match[0] = (dbad[0]==ipc && dbcr[19:16]==4'b1000 && dbcr[32]);
assign trace_match[1] = (dbad[1]==ipc && dbcr[23:20]==4'b1000 && dbcr[33]);
assign trace_match[2] = (dbad[2]==ipc && dbcr[27:24]==4'b1000 && dbcr[34]);
assign trace_match[3] = (dbad[3]==ipc && dbcr[31:28]==4'b1000 && dbcr[35]);
wire trace_on = 
  trace_match[0] ||
  trace_match[1] ||
  trace_match[2] ||
  trace_match[3]
  ;
wire trace_off = trace_full;
wire trace_compress = dbcr[36];

always @(posedge clk_g)
if (rst_i) begin
  wr_trace <= 1'b0;
  br_hcnt <= 6'd8;
  br_rcnt <= 6'd0;
  tron <= FALSE;
end
else begin
  if (trace_off)
    tron <= FALSE;
  else if (trace_on)
    tron <= TRUE;
  wr_trace <= 1'b0;
  if (tron) begin
    if (!trace_compress)
      wr_whole_address <= TRUE;
    if (st_writeback & trace_compress) begin
      if (d_cbranch) begin
        if (br_hcnt < 6'h3E) begin
          br_history[br_hcnt] <= takb;
          br_hcnt <= br_hcnt + 2'd1;
        end
        else begin
          br_rcnt <= br_rcnt + 2'd1;
          br_history[7:0] <= {br_hcnt-4'd8,2'b01};
          if (br_rcnt==6'd3) begin
            br_rcnt <= 6'd0;
            wr_whole_address <= 1'b1;
          end
          wr_trace <= 1'b1;
          br_hcnt <= 6'd8;
        end
      end
      else if (d_wha) begin
        br_history[7:0] <= {br_hcnt-4'd8,2'b01};
        br_rcnt <= 6'd0;
        wr_whole_address <= 1'b1;
        wr_trace <= 1'b1;
        br_hcnt <= 6'd8;
      end
    end
    else if (st_ifetch2) begin
      if (wr_whole_address) begin
        wr_whole_address <= 1'b0;
        br_history[63:0] <= {ipc[31:2],2'b00};
        wr_trace <= 1'b1;
      end
    end
  end
end

TraceFifo utf1 (
  .clk(clk_g),                // input wire clk
  .srst(rst_i),              // input wire srst
  .din(br_history),                // input wire [63 : 0] din
  .wr_en(wr_trace),            // input wire wr_en
  .rd_en(rd_trace),            // input wire rd_en
  .dout(trace_dout),              // output wire [63 : 0] dout
  .full(trace_full),              // output wire full
  .empty(trace_empty),            // output wire empty
  .valid(trace_valid),            // output wire valid
  .data_count(trace_data_count)  // output wire [9 : 0] data_count
);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [7:0] predecodeo;
wire [3:0] ilen = predecodeo[3:0];
rtf64_predecoder uil1 (.i(ir[7:0]), .o(predecodeo));

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction cache
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg [3:0] icnt;
(* ram_style="distributed" *)
reg [255:0] icache [0:pL1CacheLines-1];
initial begin
  for (n = 0; n < pL1CacheLines; n = n + 1)
    icache[n] = {64{8'hEA}};
end
(* ram_style="distributed" *)
reg [AWID-1:0] ictag [0:pL1CacheLines-1];
(* ram_style="distributed" *)
reg [pL1CacheLines-1:0] icvalid;
reg ic_invline;
wire ihit1 = ictag[ipc[pL1msb:5]][AWID-1:5]==ipc[AWID-1:5] && icvalid[ipc[pL1msb:5]];
wire ihit2 = ictag[ipc[pL1msb:5]+2'd1][AWID-1:5]==ipc[AWID-1:5]+2'd1 && icvalid[ipc[pL1msb:5]+2'd1];
wire ihit = ihit1 & ihit2;
initial begin
  icvalid = {pL1CacheLines{1'd0}};
  for (n = 0; n < pL1CacheLines; n = n + 1)
    ictag[n] = 32'd1;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Compressed instruction table.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg wr_ci_tbl;
reg rd_ci;
reg [31:0] ci_tbl [0:511];
always @(posedge clk_g)
  if (wr_ci_tbl)
      ci_tbl[ia[8:0]] <= ib[31:0];
wire [31:0] ci_tblo2 = ci_tbl[ia[8:0]];
wire [31:0] ci_tblo = ci_tbl[{ir[0],ir[15:8]}];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire acki = ack_i;

wire [2:0] omode = pmStack[3:1];
assign DebugMode = omode==3'b101;
assign InterruptMode = omode==3'b100;
assign MachineMode = omode==3'b011;
assign HypervisorMode = omode==3'b010;
assign SupervisorMode = omode==3'b001;
assign UserMode = omode==3'b000;
assign memmode = mprv ? pmStack[7:5] : omode;
wire MMachineMode = memmode==3'b011;
assign MUserMode = memmode==3'b000;

wire [7:0] selx;
modSelect usel1
(
  .opcode(ir[7:0]),
  .sel(selx)
);

function [31:0] fnTrim32;
input [63:0] i;
fnTrim32 = i[31:0];
endfunction
function [15:0] fnTrim16;
input [63:0] i;
fnTrim16 = i[15:0];
endfunction
function [7:0] fnTrim8;
input [63:0] i;
fnTrim8 = i[7:0];
endfunction

wire [AWID-1:0] ea;
reg [7:0] ealow;
wire [3:0] segsel = ea[AWID-1:AWID-4];

`ifdef CPU_B128
reg [31:0] sel;
reg [255:0] dat, dati;
wire [63:0] datis = dati >> {ealow[3:0],3'b0};
`endif
`ifdef CPU_B64
reg [15:0] sel;
reg [127:0] dat, dati;
wire [63:0] datis = dati >> {ealow[2:0],3'b0};
`endif
`ifdef CPU_B32
reg [7:0] sel;
reg [63:0] dat, dati;
wire [63:0] datis = dati >> {ealow[1:0],3'b0};
`endif

wire ld = st_execute;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Count: leading zeros, leading ones, population.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [6:0] cntlzo, cntloo, cntpopo;

cntlz64 uclz1 (ia, cntlzo);
cntlo64 uclo1 (ia, cntloo);
cntpop64 ucpop1 (ia, cntpopo);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Shift / Bitfield
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire [128: 0] shlr = {ia,ir[27:24]==`ASLX ? cds[0] : 1'b0} << ib[5:0];
wire [128:-1] shrr = {ir[27:24]==`LSRX ? cds[0] : 1'b0,ia,65'd0} >> ib[5:0];
wire [128: 0] shli = {ia,ir[27:24]==`ASLXI  ? cds[0] : 1'b0} << imm[5:0];
wire [128:-1] shri = {ir[27:24]==`LSRXI ? cds[0] : 1'b0,ia,65'd0} >> imm[5:0];

wire [5:0] mb = (d_exti|d_extui|d_flipi|d_depi|d_depii|d_ffoi) ? ir[23:18] : ib[5:0];
wire [5:0] mw = (d_exti|d_extui|d_flipi|d_depi|d_depii|d_ffoi) ? ir[29:24] : ic[5:0];
wire [5:0] me = mb + mw;
reg [63:0] bfo1, bfo2, bfo, mask;
integer nn;
always @*
	for (nn = 0; nn < 64; nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

always @*
if (d_depi|d_depr) begin
	bfo2 = ia << mb;
	for (n = 0; n < 64; n = n + 1)
	  bfo[n] = (mask[n] ? bfo2[n] : id[n]);
end
else if (d_depii) begin
	bfo2 = imm << mb;
	for (n = 0; n < 64; n = n + 1)
	  bfo[n] = (mask[n] ? bfo2[n] : id[n]);
end
else if (d_flipr|d_flipi) begin
  for (n = 0; n < 64; n = n + 1)
    bfo[n] = mask[n] ? ia[n]^id[n] : id[n];
end
else if (d_extr|d_exti) begin
	for (n = 0; n < 64; n = n + 1)
		bfo1[n] = mask[n] ? ia[n] : 1'b0;
	bfo2 = bfo1 >> mb;
	for (n = 0; n < 64; n = n + 1)
		bfo[n] = n > mw ? bfo2[mw] : bfo2[n];
end
else if (d_extur|d_extui) begin
	for (n = 0; n < 64; n = n + 1)
		bfo1[n] = mask[n] ? ia[n] : 1'b0;
	bfo = bfo1 >> mb;
end
else if (d_ffoi|d_ffor) begin
  bfo2 = {64{1'b1}};
	for (n = 0; n < 64; n = n + 1)
		bfo1[n] = mask[n] ? ia[n] : 1'b0;
  for (n = 0; n < 64; n = n + 1)
    if (bfo1[n]==1'b1)
      bfo2 = n;
	bfo = bfo2[63] ? bfo2 : bfo2 - mb;
end
else
	bfo = {64{1'b0}};


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
// Floating point logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
reg d_fltcmp;
wire [4:0] fltfunct5 = ir[27:23];
reg [FPWID-1:0] fcmp_res, ftoi_res, itof_res, fres;
wire [2:0] rmq = rm3==3'b111 ? rm : rm3;

wire [4:0] fcmp_o;
wire [EX:0] fas_o, fmul_o, fdiv_o, fsqrt_o;
wire [EX:0] fma_o;
wire fma_uf;
wire mul_of, div_of;
wire mul_uf, div_uf;
wire norm_nx;
wire sqrt_done;
wire cmpnan, cmpsnan;
reg [EX:0] fnorm_i;
wire [MSB+3:0] fnorm_o;
reg ld1;
wire sqrneg, sqrinf;
wire fa_inf, fa_xz, fa_vz;
wire fa_qnan, fa_snan, fa_nan;
wire fb_qnan, fb_snan, fb_nan;
wire finf, fdn;
always @(posedge clk_g)
	ld1 <= ld;
fpDecomp #(FPWID) u12 (.i(ia), .sgn(), .exp(), .man(), .fract(), .xz(fa_xz), .mz(), .vz(fa_vz), .inf(fa_inf), .xinf(), .qnan(fa_qnan), .snan(fa_snan), .nan(fa_nan));
fpDecomp #(FPWID) u13 (.i(ib), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(fb_qnan), .snan(fb_snan), .nan(fb_nan));
fpCompare #(.FPWID(FPWID)) u1 (.a(ia), .b(ib), .o(fcmp_o), .nan(cmpnan), .snan(cmpsnan));
assign fcmp_res = fcmp_o[1] ? {FPWID{1'd1}} : fcmp_o[0] ? 1'd0 : 1'd1;
i2f #(.FPWID(FPWID)) u2 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .rm(rmq), .i(ia), .o(itof_res));
f2i #(.FPWID(FPWID)) u3 (.clk(clk_g), .ce(1'b1), .op(~Rs2[0]), .i(ia), .o(ftoi_res), .overflow());
fpAddsub #(.FPWID(FPWID)) u4 (.clk(clk_g), .ce(1'b1), .rm(rmq), .op(fltfunct5==`FSUB), .a(ia), .b(ib), .o(fas_o));
fpMul #(.FPWID(FPWID)) u5 (.clk(clk_g), .ce(1'b1), .a(ia), .b(ib), .o(fmul_o), .sign_exe(), .inf(), .overflow(nmul_of), .underflow(mul_uf));
fpDiv #(.FPWID(FPWID)) u6 (.rst(rst_i), .clk(clk_g), .clk4x(1'b0), .ce(1'b1), .ld(ld), .op(1'b0),
	.a(ia), .b(ib), .o(fdiv_o), .done(), .sign_exe(), .overflow(div_of), .underflow(div_uf));
fpSqrt #(.FPWID(FPWID)) u7 (.rst(rst_i), .clk(clk_g), .ce(1'b1), .ld(ld),
	.a(ia), .o(fsqrt_o), .done(sqrt_done), .sqrinf(sqrinf), .sqrneg(sqrneg));
fpFMA #(.FPWID(FPWID)) u14
(
	.clk(clk_g),
	.ce(1'b1),
	.op(opcode==FMS||opcode==FNMS),
	.rm(rmq),
	.a(opcode==`FNMA||opcode==`FNMS ? {~ia[FPWID-1],ia[FPWID-2:0]} : ia),
	.b(ib),
	.c(ic),
	.o(fma_o),
	.under(fma_uf),
	.over(),
	.inf(),
	.zero()
);

always @(posedge clk_g)
case(opcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_i <= fma_o;
`FLT2:
	case(fltfunct5)
	`FADD:	fnorm_i <= fas_o;
	`FSUB:	fnorm_i <= fas_o;
	`FMUL:	fnorm_i <= fmul_o;
	`FDIV:	fnorm_i <= fdiv_o;
	`FSQRT:	fnorm_i <= fsqrt_o;
	default:	fnorm_i <= 1'd0;
	endcase
default:	fnorm_i <= 1'd0;
endcase
reg fnorm_uf;
wire norm_uf;
always @(posedge clk_g)
case(opcode)
`FMA,`FMS,`FNMA,`FNMS:
	fnorm_uf <= fma_uf;
`FLT2:
	case(fltfunct5)
	`FMUL:	fnorm_uf <= mul_uf;
	`FDIV:	fnorm_uf <= div_uf;
	default:	fnorm_uf <= 1'b0;
	endcase
default:	fnorm_uf <= 1'b0;
endcase
fpNormalize #(.FPWID(FPWID)) u8 (.clk(clk_g), .ce(1'b1), .i(fnorm_i), .o(fnorm_o), .under_i(fnorm_uf), .under_o(norm_uf), .inexact_o(norm_nx));
fpRound #(.FPWID(FPWID)) u9 (.clk(clk_g), .ce(1'b1), .rm(rmq), .i(fnorm_o), .o(fres));
fpDecompReg #(FPWID) u10 (.clk(clk_g), .ce(1'b1), .i(fres), .sgn(), .exp(), .fract(), .xz(fdn), .vz(), .inf(finf), .nan() );

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Address Generator
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
wire inc_ma = (state==MEMORY5 && !acki) ||
              (state==MEMORY10 && !acki) ||
              (state==MEMORY15 && !acki);

agen uag1
(
  .rst(rst_i),
  .clk(clk_g),
  .en(st_execute),
  .inc_ma(inc_ma),
  .inst(ir[31:0]),
  .a(ia),
  .c(ic),
  .ma(ea),
  .idle()
);

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

wire [3:0] ea_acr = sregfile[segsel][3:0];
wire [3:0] pc_acr = sregfile[pc[AWID-1:AWID-4]][3:0];

always @(posedge clk_g)
if (rst_i) begin
	state <= IFETCH1;
	icvalid <= 64'd0;
	ic_invline <= 1'b0;
	ir <= 64'h000000EA;
	pc <= RSTPC;
	ipc <= 32'h0;
	pc_reload <= TRUE;
	for (n = 0; n < 8; n = n + 1) begin
	  tvec[n] <= 32'hFFFC0000;
	  status[n] <= 32'h0;
  end
	ASID <= 5'd0;
	gcie <= 32'h0;
	wrirf <= 1'b0;
	wrfrf <= 1'b0;
	wrcrf <= 1'b0;
	wrcrf32 <= 1'b0;
	// Reset bus
	vpa_o <= LOW;
  cyc_o <= LOW;
  stb_o <= LOW;
  we_o <= LOW;
  sel_o <= 4'h0;
  adr_o <= 32'd0;
  dat_o <= 128'd0;
	sr_o <= 1'b0;
	cr_o <= 1'b0;
	ld_time <= 1'b0;
	wc_times <= 1'b0;
	wc_time_irq_clr <= 6'h3F;
	pmStack <= 12'b001001001110;
	nmif <= 1'b0;
	ldd <= 1'b0;
	wrpagemap <= 1'b0;
  pagemapa <= 13'd0;
  ia <= 64'd0;
	setto <= 1'b0;
	getto <= 1'b0;
	decto <= 1'b0;
	getzl <= 1'b0;
	popto <= 1'b0;
	gcloc <= 6'd0;
	pushq <= 1'b0;
	popq <= 1'b0;
	peekq <= 1'b0;
	statq <= 1'b0;
	mrloc <= 3'd0;
	rprv <= 5'd0;
	Rdx <= 5'd31;
	Rs1x <= 5'd31;
	Rs2x <= 5'd31;
	Rs3x <= 5'd31;
	Rdx1 <= 5'd31;
	Rs1x1 <= 5'd31;
	Rs2x1 <= 5'd31;
	Rs3x1 <= 5'd31;
	rsStack <= 32'hFFFFFFFF;
	set_wfi <= 1'b0;
	next_epc <= 32'hFFFFFFFF;
	instret <= 40'd0;
	tlben <= 1'b0;
	tlbwr <= 1'b0;
	xlaten <= 1'b0;
	wr_ci_tbl <= FALSE;
	instfetch <= 40'd0;
	icaccess <= FALSE;
	rd_ci <= FALSE;
end
else begin
if (trace_match[0]) dbsr[0] <= TRUE;
if (trace_match[1]) dbsr[1] <= TRUE;
if (trace_match[2]) dbsr[2] <= TRUE;
if (trace_match[3]) dbsr[3] <= TRUE;
decto <= 1'b0;
popto <= 1'b0;
ldd <= 1'b0;
wrca <= 1'b0;
wrpagemap <= 1'b0;
if (pe_nmi)
	nmif <= 1'b1;
ld_time <= {ld_time[4:0],1'b0};
wc_times <= wc_time;
if (wc_time_irq==1'b0)
	wc_time_irq_clr <= 1'd0;
pushq <= 1'b0;
popq <= 1'b0;
peekq <= 1'b0;
statq <= 1'b0;
rd_trace <= 1'b0;
wr_ci_tbl <= FALSE;

`ifdef RTF64_PAGEMAP
if (state != IFETCH3 && state != IFETCH4 && state != IFETCH5) begin
  if (!UserMode)
  	adr_o <= ladr;
  else begin
  	if (ladr[AWID-1:24]=={AWID-24{1'b1}})
  		adr_o <= ladr[AWID-1:0];
  	else
  		adr_o <= {pagemapo & 14'h3FFF,ladr[13:0]};
  end
end
`endif

// Check the memory keys
keyViolation <= TRUE;
for (n = 0; n < 9; n = n + 1)
  if (keyo==key[n] || keyo==20'h0)
    keyViolation <= FALSE;

case (state)
// It takes two clocks to read the pagemap ram, this is after the linear
// address is set, which also takes a clock cycle.
IFETCH1:
  begin
`ifdef SIM
    $display("Fetched: %d", instfetch);
    $display("Ticks: %d", tick);
    for (n = 0; n < 32; n = n + 4) begin
      $display("%d: %h  %d: %h  %d: %h  %d: %h",
         n[4:0], iregfile[n],
         n[4:0]+2'd1, iregfile[n+1],
         n[4:0]+2'd2, iregfile[n+2],
         n[4:0]+2'd3, iregfile[n+3]
      );
    end
`endif    
    wrirf <= 1'b0;
    wrcrf32 <= 1'b0;
    wrra <= 1'b0;
    d_cmp <= 1'b0;
    d_set <= 1'b0;
    d_tst <= 1'b0;
    d_mov <= 1'b0;
    d_stot <= 1'b0;
    d_stptr <= 1'b0;
    d_setkey <= 1'b0;
    d_gcclr <= 1'b0;
    d_fltcmp <= 1'b0;
    d_shiftr <= 1'b0;
    d_st <= FALSE;
    d_ld <= FALSE;
    d_depi <= FALSE;
    d_depr <= FALSE;
    d_depii <= FALSE;
    d_extr <= FALSE;
    d_exti <= FALSE;
    d_extui <= FALSE;
    d_extur <= FALSE;
    d_flipr <= FALSE;
    d_flipi <= FALSE;
    d_ffoi <= FALSE;
    d_ffor <= FALSE;
    d_cbranch = FALSE;
    d_wha <= FALSE;
    d_pushq <= FALSE;
    d_popq <= FALSE;
    d_peekq <= FALSE;
    d_statq <= FALSE;
    d_cache <= FALSE;
    d_jsr <= FALSE;
    d_rts <= FALSE;
	  Rdx <= Rdx1;
	  Rs1x <= Rs1x1;
	  Rs2x <= Rs2x1;
	  Rs3x <= Rs3x1;
		illegal_insn <= 1'b1;
		instfetch <= instfetch + 2'd1;
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
    tPC();
    xlaten <= TRUE;
 		vpa_o <= HIGH;
		if (nmif) begin
			nmif <= 1'b0;
			tException(32'h800000FE,pc);
			pc <= tvec[3'd5] + 8'hFC;
		end
 		else if (irq_i & die) begin
			tException({24'h800000,cause_i},pc);
		end
		else if (mip[7] & miex[7] & die) begin
			tException(32'h800000F2,pc);  // timer IRQ
		end
		else if (mip[3] & miex[3] & die) begin
			tException(32'h800000F0, pc); // software IRQ (SYS)
		end
		else if (uip[0] & gcie[ASID] & die) begin
			tException(32'h800000F3, pc); // garbage collect IRQ
			uip[0] <= 1'b0;
		end
    goto (IFETCH2);
  end
IFETCH2:
  begin
    if (ihit1)
      icnt <= 4'h8;
    else
      icnt <= 4'd0;
		if (ihit) begin
		  iri1 <= icache[ipc[pL1msb:5]];
		  iri2 <= icache[ipc[pL1msb:5]+2'd1];
		  goto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1 && ipc[4:0] < 5'h9) begin
		  iri1 <= icache[ipc[pL1msb:5]];
		  iri2 <= icache[ipc[pL1msb:5]+2'd1];
		  goto (INSTRUCTION_ALIGN);
	  end
	  else begin
`ifdef RTF64_TLB
    goto (IFETCH2a);
`else
    goto (IFETCH3);
`endif
    end
    wrcrf <= 1'b0;
  end
IFETCH2a:
  begin
    goto(IFETCH3);
  end
IFETCH3:
  begin
 		xlaten <= FALSE;
		if (ihit && icnt==4'h0) begin
		  iri1 <= icache[ipc[pL1msb:5]];
		  iri2 <= icache[ipc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  goto (INSTRUCTION_ALIGN);
	  end
	  else if (ihit1 && ipc[4:0] < 5'h9 && icnt==4'h0) begin
		  iri1 <= icache[ipc[pL1msb:5]];
		  iri2 <= icache[ipc[pL1msb:5]+2'd1];
		  icaccess <= FALSE;
		  goto (INSTRUCTION_ALIGN);
	  end
	  else
	  begin
  		goto (IFETCH3a);
`ifdef RTF64_TLB  		
  		if (tlbmiss) begin
			  tException(32'h80000004,ipc);
			  badaddr[3'd5] <= ipc;
			  vpa_o <= FALSE;
			end
			else
`endif			
			begin
			  // First time in, set to miss address, after that increment
			  icaccess <= TRUE;
`ifdef CPU_B128
        if (!icaccess)
          iadr <= {adr_o[AWID-1:5],5'h0};
        else
          iadr <= {iadr[AWID-1:4],4'h0} + 5'h10;
`endif
`ifdef CPU_B64
        if (!icaccess)
          iadr <= {adr_o[AWID-1:5],5'h0}
        else
          iadr <= {iadr[AWID-1:3],3'h0} + 4'h8;
`endif
`ifdef CPU_B32
        if (!icaccess)
          iadr <= {adr_o[AWID-1:5],5'h0};
        else
          iadr <= {iadr[AWID-1:2],2'h0} + 3'h4;
`endif			
      end
	  end
  end
IFETCH3a:
  begin
    cyc_o <= HIGH;
		stb_o <= HIGH;
`ifdef CPU_B128
    sel_o <= 16'hFFFF;
`endif
`ifdef CPU_B64
    sel_o <= 8'hFF;
`endif
`ifdef CPU_B32
		sel_o <= 4'hF;
`endif
    goto (IFETCH4);
  end
IFETCH4:
  begin
    if (ack_i) begin
      cyc_o <= LOW;
      stb_o <= LOW;
      vpa_o <= LOW;
      sel_o <= 1'h0;
`ifdef CPU_B128
      case(icnt[2])
      1'd0: ici[127:0] <= dat_i;
      1'd1: ici[255:128] <= dat_i;
      endcase
      goto (IFETCH5);
`endif
`ifdef CPU_B64
      case(icnt[2:1])
      2'd0: ici[63:0] <= dat_i;
      2'd1: ici[127:64] <= dat_i;
      2'd2: ici[191:128] <= dat_i;
      2'd3; ici[255:192] <= dat_i;
      endcase
      goto (IFETCH5);
`endif
`ifdef CPU_B32
      case(icnt[2:0])
      3'd0: ici[31:0] <= dat_i;
      3'd1: ici[63:32] <= dat_i;
      3'd2: ici[95:64] <= dat_i;
      3'd3: ici[127:96] <= dat_i;
      3'd4: ici[159:128] <= dat_i;
      3'd5: ici[191:160] <= dat_i;
      3'd6; ici[223:192] <= dat_i;
      3'd7: ici[255:224] <= dat_i;
      endcase
      goto (IFETCH5);
`endif
    end
		tPMAPC(); // must have adr_o valid for PMA
  end
IFETCH5:
  begin
`ifdef CPU_B128
    if (icnt[2]==1'd1)
      ictag[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
`endif
`ifdef CPU_B64
    if (icnt[2:1]==2'd3)
      ictag[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
`endif
`ifdef CPU_B32
    if (icnt[2:0]==3'd7)
      ictag[iadr[pL1msb:5]] <= iadr[AWID-1:0] & ~64'h10;
`endif
    icvalid[iadr[pL1msb:5]] <= 1'b1;
    icache[iadr[pL1msb:5]] <= ici;
    if (~ack_i) begin
`ifdef CPU_B128
      icnt <= icnt + 4'd4;
`endif
`ifdef CPU_B64
      icnt <= icnt + 4'd2;
`endif
`ifdef CPU_B32
      icnt <= icnt + 2'd1;
`endif
      goto (IFETCH3);
    end
  end
INSTRUCTION_ALIGN:
  begin
    ir <= {iri2,iri1} >> {ipc[4:0],3'b0};
    goto (DECODE);
  end
EXPAND_CI:
  begin
    ir <= ci_tblo;
    rd_ci <= TRUE;
    goto (DECODE);
  end
DECODE:
  begin
    rd_ci <= FALSE;
    if (!rd_ci)
      pc <= pc + ilen;
    $display("IP: %h", ipc);
    $display("Fetch: %h", ir);
    goto (REGFETCH1);
    Rd <= 5'd0;
    Rs1 <= ir[17:13];
    Rs2 <= ir[22:18];
    Rs3 <= ir[27:23];
    Cd <= 2'd0;
    Cs <= ir[9:8];
    rad <= ir[8];
    casez(opcode)
    `CI: goto(EXPAND_CI);
    `OSR2:
      case(funct5)
      `CACHE:
        begin
          d_cache <= TRUE;
          case(ir[9:8])
          2'd0: ;
          2'd1: ic_invline <= 1'b1;
          2'd2: begin icvalid <= 64'd0; goto (IFETCH1); end
          3'd3: ;
          endcase
		      illegal_insn <= 1'b0;
        end
		  `PFI: 
		    begin
		      if (irq_i != 1'b0)
		        tException(32'h80000000|cause_i,ipc);
		      illegal_insn <= 1'b0;
		    end
		  `SETKEY:  
	      if (omode != 3'd0) begin
	        d_setkey <= 1'b1;
	        illegal_insn <= 1'b0;
	      end
	    `GCCLR:
	      begin
	        d_gcclr <= 1'b1;
	        illegal_insn <= 1'b0;
	      end
	    `MVMAP:
	      begin
	        illegal_insn <= 1'b0;
	      end
	    `TLBRW: begin illegal_insn <= 1'b0; end
	    `PUSHQ: begin d_pushq <= TRUE; illegal_insn <= FALSE; end
	    `POPQ:  begin d_popq <= TRUE; illegal_insn <= FALSE; end
	    `PEEKQ: begin d_peekq <= TRUE; illegal_insn <= FALSE; end 
	    `STATQ: begin d_statq <= TRUE; illegal_insn <= FALSE; end
	    `MVCI:  begin illegal_insn <= FALSE; end
		  default:  ;
		  endcase
    `R2:
      begin
        Rd <= ir[12:8];
        Cd <= 2'b00;
        case(funct5)
        `ANDR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR2:  begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `EORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BMMR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ADDR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `SUBR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NANDR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ENORR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `R1:
          case(ir[22:18])
          `CNTLZR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTLOR1: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `CNTPOPR1:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `COMR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NOTR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `NEGR1:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
          `TST1:    begin Cd <= ir[9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
          default:  ;                                    
          endcase
        `MULR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CMPR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `MULUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PERMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PTRDIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `BYTNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `WYDNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULF:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR2:begin illegal_insn <= 1'b0; end
        `MOV:
          begin
            d_mov <= 1'b1;
            wrcrf <= ir[31];
            case(ir[21:20])
            2'b11:
              casez(Rs1)
              5'b000??: rad = ir[13];
              5'b100??: Cs <= ir[14:13];
              default:  ;
              endcase
            default:  ;
            endcase
            illegal_insn <= 1'b0;
          end
        default:  ;
        endcase
      end
    `R2B:
      begin
        Rd <= ir[12:8];
        Cs <= ir[19:18];
        case(funct5)
        `ANDR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR2:  begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `EORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `BMMR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ADDR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `SUBR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NANDR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `NORR2: begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `ENORR2:begin wrirf <= 1'b1; wrcrf <= ir[31];  illegal_insn <= 1'b0; end
        `MULR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CMPR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `MULUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVR2: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIVSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CMPR2B:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CMPUR2B:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `REMSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PERMR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `PTRDIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DIFR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `BYTNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `WYDNDX2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULF:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULSUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MULUHR2:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `CHKR2B: begin Rd <= 5'd0; illegal_insn <= 1'b0; end
        `RGFR2:begin illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end
    `R3A:
      begin
        Rd <= ir[12:8];
        case(ir[30:28])
        `MINR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MAJR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `MUXR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ADDR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `SUBR3A: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `FLIPR3A:begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_flipr <= 1'b1; end
        default:  ;
        endcase
      end
    `R3B:
      begin
        Rd <= ir[12:8];
        case(ir[30:28])
        `ANDR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `ORR3B:   begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `EORR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `DEPR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_depr <= 1'b1; end
        `EXTR3B:  begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_extr <= 1'b1; end
        `EXTUR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; d_extur <= 1'b1; end
        `BLENDR3B: begin wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
        `RGFR3B:  begin illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end

    `SHIFT:
      begin
        Rd <= ir[12:8];
        Cs <= ir[19:18];
        case(ir[27:24])
        `ASL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `LSR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ROL:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ROR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASR:  begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASLX: begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `LSRX: begin wrirf <= 1'b1; wrcrf <= ir[31]; d_shiftr <= 1'b1; illegal_insn <= 1'b0; end
        `ASLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `LSRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ROLI: begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `RORI: begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ASRI: begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `ASLXI:begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        `LSRXI:begin wrirf <= 1'b1; wrcrf <= ir[31]; imm <= ir[23:18]; illegal_insn <= 1'b0; end
        default:  ;
        endcase
      end

    `SET:
      begin
        d_set <= 1'b1;
        Cd <= ir[9:8];
        case(ir[30:28])
        `SEQR2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SNER2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SLTR2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SGER2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SLTUR2:begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SGEUR2:begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SANDR2:begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        `SORR2: begin wrcrf <= 1'b1; illegal_insn <= 1'b0; end
        default:  ;
      endcase
      end
    `SEQ: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SNE: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLT: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGE: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLE: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGT: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLTU: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGEU: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SLEU: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SGTU: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SAND: begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
    `SOR:  begin d_set <= 1'b1; Cd <= ir[9:8]; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= 1'b1; illegal_insn <= 1'b0; end

    `ADD: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `ADD5:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{59{ir[22]}},ir[22:18]}; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `ADD22:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{41{ir[22]}},ir[22:13],13'd0}; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `ADD2R:begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `SUBF:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `MUL: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `CMP: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; illegal_insn <= 1'b0; end
    `AND: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{1'b1}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `OR:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{1'b0}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `OR5: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= ir[22:18]; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `OR2R:begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[23]; illegal_insn <= 1'b0; end
    `EOR: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{1'b0}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `GCSUB: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{1'b0}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `GCSUB10: begin Rd <= 5'd31; Rs1 = 5'd31; wrirf <= 1'b1; imm <= {{54{1'b0}},ir[14:8],3'd0}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `BIT: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; illegal_insn <= 1'b0; end
    `BYTNDX: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `WYDNDX: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{48{ir[34]}},ir[34:32],ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `MULFI:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{51{ir[30]}},ir[30:18]}; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `CHK: begin imm <= {{51{1'b1}},ir[30:23],ir[12:8]}; illegal_insn <= 1'b0; end

    `PERM:begin Rd <= ir[12:8]; wrirf <= 1'b1; wrcrf <= ir[31]; illegal_insn <= 1'b0; end
    `DEP: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; d_depi <= ~ir[30]; d_flipi <= ir[30]; end
    `DEPI: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; d_depii <= TRUE; end
    `EXT: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; d_exti <= ~ir[30]; d_extui <= ir[30]; end
    `FFO: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; d_ffoi <= ~ir[30]; d_ffor <= ir[30]; end
    `ADDUI,`ORUI,`AUIIP: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {ir[63:32],ir[30:13],ir[0],13'd0}; illegal_insn <= 1'b0; end
    `ANDUI: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {ir[63:32],ir[30:13],ir[0],{13{1'd1}}}; illegal_insn <= 1'b0; end
    `CSR: if (omode >= ir[35:33]) begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= ir[17:13]; illegal_insn <= 1'b0; end
    // Flow Control
    `JMP:
      begin
        case(ir[9:8])
        2'b00:  pc <= {ipc[AWID-1:24],ir[31:10],2'b00};
        2'b01:  pc <= ipc + {{34{ir[39]}},ir[39:10]};
        2'b10:  pc <= {ipc[AWID-1:24],ir[31:10],2'b00} + cao;
        2'b11:  pc <= ipc + {{34{ir[39]}},ir[39:10]};
        endcase
        goto (IFETCH1);
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
        if (ipc=={ipc[AWID-1:24],ir[31:10],2'b00})
          tException(`FLT_BT, ipc);
      end
    `JAL:
      begin
        // Assume instruction will not crap out and write ra0,ra1 here rather
        // than at WRITEBACK.
        rares <= ipc;
        wrra <= 1'b1;
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
        if (ipc=={ipc[AWID-1:24],ir[31:10],2'b00})
          tException(`FLT_BT, ipc);
      end
    `JSR:
      begin
        // Assume instruction will not crap out and write ra0,ra1 here rather
        // than at WRITEBACK.
        d_jsr <= TRUE;
        Rd <= 5'd31;
        Rs1 <= 5'd31;
        wrirf <= 1'b1;
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
//        if (ipc=={ipc[AWID-1:24],ir[31:10],2'b00})
//          tException(`FLT_BT, ipc);
      end
    `JSR18:
      begin
        d_jsr <= TRUE;
        Rd <= 5'd31;
        Rs1 <= 5'd31;
        wrirf <= 1'b1;
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTL:
      begin
        Rd <= 5'd31;
        Rs1 <= 5'd31;
        wrirf <= 1'b1;
        imm <= {{51{ir[31]}},ir[30:21],3'b00};
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTS:
      begin
        d_rts <= TRUE;
        Rd <= 5'd31;
        Rs1 <= 5'd31;
        wrirf <= 1'b1;
        imm <= {{51{ir[31]}},ir[30:21],3'b00};
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTX:
      begin
        d_rts <= TRUE;
        Rd <= 5'd27;
        Rs1 <= 5'd27;
        wrirf <= 1'b1;
        imm <= 64'd8;
        d_wha <= TRUE;
        illegal_insn <= 1'b0;
      end
    `RTE:
      // Must be at a higher operating mode in order to return to a lower one.
      if (rsStack[4:0] > rsStack[9:5] && rsStack[4:0] > 5'd25) begin
			  rsStack <= {5'd31,rsStack[29:5]};
			  rprv <= 5'h0;
			  Rdx1 <= rsStack[9:5];
			  Rs1x1 <= rsStack[9:5];
			  Rs2x1 <= rsStack[9:5];
			  Rs3x1 <= rsStack[9:5];
				pc <= epc[rsStack[4:0]];
				d_wha <= TRUE;
				illegal_insn <= 1'b0;
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,`BLEU,`BGTU,`BOD,`BPS,`BRA,`BT:
      begin
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
      end
    `BEQZ,`BNEZ:
      begin
        Rd <= {3'b101,ir[9:8]};
        d_cbranch <= TRUE;
        illegal_insn <= 1'b0;
      end
    `NOP: begin illegal_insn <= 1'b0; end
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Memory Ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    `LDBS,`LDBUS,`LDWS,`LDWUS,`LDTS,`LDTUS,`LDOS,`LDORS:
      begin
        Rd <= ir[12:8];
        wrirf <= 1'b1;
        imm <= {{52{ir[22]}},ir[22:14],3'd0};
        wrcrf <= ir[23];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDO,`LDOR:
      begin
        Rd <= ir[12:8];
        wrirf <= 1'b1;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:18]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[22:18]};
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `LDOT:
      begin
        casez(ir[12:8])
        5'b0000?: begin rad <= ir[8]; wrra <= 1'b1; end
        5'b0001?: begin rad <= ir[8]; wrca <= 1'b1; end
        5'b100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
        5'b11101: begin wrcrf32 <= 1'b1; end
        endcase
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:18]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[22:18]};
        d_ld <= TRUE; 
        illegal_insn <= 1'b0;
      end
    `FLDO:
      begin
        Rd <= ir[12:8];
        Rdx <= 5'h01;
        wrirf <= 1'b1;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:18]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[22:18]};
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `PLDO:
      begin
        Rd <= ir[12:8];
        Rdx <= 5'h02;
        wrirf <= 1'b1;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:18]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[22:18]};
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
      end
    `LEA:  
      begin
        Rd <= ir[12:8];
        wrirf <= 1'b1;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:18]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[22:18]};
        wrcrf <= ir[31];
        illegal_insn <= 1'b0;
        d_ld <= TRUE;
        d_lea <= TRUE;
      end
    `STBS,`STWS,`STTS,`STOS,`STOCS:  
      begin
        Rd <= ir[12:8];
        if (ir[30])
          imm <= {{52{ir[17]}},ir[17:14],ir[12:8],3'd0};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `STB,`STW,`STT,`STO,`STOC:  
      begin
        Rd <= ir[12:8];
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:23],ir[12:8]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `STPTR:
      begin
        Rd <= ir[12:8];
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:23],ir[12:8]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
        d_stptr <= TRUE;
      end
    `STOT:
      begin
        Rd <= ir[12:8];
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:23],ir[12:8]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
        d_stot <= TRUE;
        Cs <= ir[19:18];
      end
    `FSTO:  
      begin
        Rd <= ir[12:8];
        Rdx <= 5'h01;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:23],ir[12:8]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `PSTO:
      begin
        Rd <= ir[12:8];
        Rdx <= 5'h02;
        if (ir[30])
          imm <= {{52{ir[29]}},ir[29:23],ir[12:8]};
        else
          imm <= {{58{ir[29]}},ir[29],ir[12:8]};
        illegal_insn <= 1'b0;
        d_st <= TRUE;
      end
    `PUSH:
      begin
        Rd <= ir[12:8];
        Cs <= ir[9:8];
        wrirf <= TRUE;
        d_st = TRUE;
        illegal_insn <= FALSE;
      end
    `PUSHC:
      begin
        wrirf <= TRUE;
        imm <= {{40{ir[31]}},ir[31:8]};
        d_st = TRUE;
        illegal_insn <= FALSE;
      end
    `POP:
      begin
        casez(ir[14:8])
        7'b110000?: begin rad <= ir[8]; wrra <= 1'b1; end
        7'b110001?: begin rad <= ir[8]; wrca <= 1'b1; end
        7'b11100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
        7'b1111101: begin wrcrf32 <= 1'b1; end
        default:  wrirf <= TRUE;
        endcase
        illegal_insn <= FALSE;
      end
    // step1:
    //  select frame pointer to store
    //  copy stack pointer to frame pointer
    // step2:
    //  write frame pointer to memory
    //  subtract allocation from stack pointer
    `LINK:
      begin
        Rs1 <= 5'd31;   // stack pointer
        Rs2 <= 5'd30;   // frame pointer
        Rd <= 5'd30;
        imm <= {ir[23:8],3'd0};
        wrirf <= TRUE;
        illegal_insn <= FALSE;
      end
    // step1:
    //  copy frame pointer to stack pointer
    // step2:
    //  load frame pointer from stack
    `UNLINK:
      begin
        Rs1 <= 5'd30;
        wrirf <= TRUE;
        illegal_insn <= FALSE;
      end
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Floating point ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`FMA,`FMS,`FNMA,`FNMS:
			begin
				Rd <= ir[12:8];
				Rdx <= 5'd1;
				Rs1x <= 5'd1;
				Rs2x <= 5'd1;
				Rs3x <= 5'd1;
				wrirf <= 1'b1;
			end
		`FLT2:
			begin
				Rd <= ir[12:8];
				case(fltfunct5)
				5'd20,5'd24,5'd28:
				  begin
				    Rdx <= Rdx1;
				    wrirf <= 1'b1;
				  end
				`FSEQ,`FSLT,`FSLE,`FCMP:  begin Cd <= ir[9:8]; d_fltcmp <= 1'b1; wrcrf <= 1'b1; end
				default:
				  begin
				    Rdx <= 5'd1;
            wrirf <= 1'b1;
          end
			  endcase
			end
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // Posit ops
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
		`PMA,`PMS,`PNMA,`PNMS:
			begin
				Rd <= ir[12:8];
				Rdx <= 5'd2;
				Rs1x <= 5'd2;
				Rs2x <= 5'd2;
				Rs3x <= 5'd2;
				wrprf <= 1'b1;
			end
		`PST2:
			begin
				Rd <= ir[12:8];
				case(fltfunct5)
				5'd20,5'd24,5'd28:
				  begin
				    Rdx <= rsStack[4:0];
				    wrirf <= 1'b1;
				  end
				`FSEQ,`FSLT,`FSLE,`FCMP:  begin Cd <= ir[9:8]; d_fltcmp <= 1'b1; wrcrf <= 1'b1; end
				default:
				  begin
				    Rdx <= 5'd2;
            wrprf <= 1'b1;
          end
			  endcase
			end
    endcase
  end
// Need a state to read Rd from block ram.
REGFETCH1:
  begin
    if (d_stot) begin
      casez(Rs2)
      5'b0000?: ib <= rao;
      5'b0001?: ib <= cao;
      5'b00111: ib <= epc[crs];
      5'b100??: ib <= cd2;
      5'b11101: ib <= cds322;
      default:  ib <= 64'd0;
      endcase
    end
    else if (d_jsr)
      id <= pc; // pc is addressing next instruction
    else
      id <= 64'd0;
    goto (REGFETCH2);
  end
REGFETCH2:
  begin
    case(opcode)
    `JAL:
      pc <= {ipc[AWID-1:24],ir[31:10],2'b00} + (ir[9] ? cao : {AWID{1'd0}});
    `JSR:
      case(ir[9:8])
      2'b00:  pc <= {ipc[AWID-1:24],ir[31:10],2'b00};
      2'b01:  pc <= ipc + {{34{ir[39]}},ir[39:10]};
      2'b10:  pc <= {ipc[AWID-1:24],ir[31:10],2'b00} + cao;
      2'b11:  pc <= ipc + {{34{ir[39]}},ir[39:10]};
      endcase
    `JSR18:
      pc <= ipc + {{48{ir[23]}},ir[23:8]};
    default:  ;
    endcase
    goto (REGFETCH3);
  end
REGFETCH3:
  begin
    goto (EXECUTE);
    $display("RF: irfoRs1:%h Rs1=%d",irfoRs1, Rs1);
    ia <= Rs1==5'd0 ? 64'd0 : irfoRs1;
    ib <= Rs2==5'd0 ? 64'd0 : irfoRs2;
    ic <= Rs3==5'd0 ? 64'd0 : irfoRs3;
    if (d_stot | d_jsr)
      id <= id;
    else
      id <= Rd==5'd0 ? 64'd0 : irfoRd;
		case(opcode)
    `PUSH:
       begin
        casez(ir[14:8])
        7'b110000?: id <= rao;
        7'b110001?: id <= cao;
        7'b1100111: id <= epc[crs];
        7'b11100??: id <= cd2;
        7'b1111101: id <= cds322;
        default:  id <= irfoRd;
        endcase
      end
		`FSTO:  id <= Rs2==5'd0 ? 64'd0 : frfob;
		`FLT2:
			case(fltfunct5)
			`FLT1:
			  case(Rs2)
			  `ITOF: ia <= Rs1==5'd0 ? {FPWID{1'd0}} : irfoRs1;
			  default:  ;
				endcase
			default:	ia <= Rs1==5'd0 ? {FPWID{1'd0}} : frfoa;
			endcase
		default:	;
		endcase
    ret_pc <= rao;
  end
EXECUTE:
  begin
    $display("EX: irfoRs1:%h Rs1=%d",irfoRs1, Rs1);
    goto (WRITEBACK);
    res <= 64'd0;
    casez(opcode)
		`BRK:
		  case(ir[15:8])
		  8'd3: tException(ir[15:8], pc);
		  8'd8: tException(ir[15:8]+pmStack[3:1], pc);
		  default:  tException(ir[15:8], pc);
		  endcase
    `R2:
      case(funct5)
      `ANDR2: res <= ia & ib;
      `ORR2:  res <= ia | ib;
      `EORR2: res <= ia ^ ib;
      `NANDR2:res <= ~(ia & ib);
      `NORR2: res <= ~(ia | ib);
      `ENORR2:res <= ~(ia ^ ib);
      `ADDR2: res <= ia + ib;
      `SUBR2: res <= ia - ib;
      `MULR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULUR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULSUR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULUHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `MULSUHR2: begin goto (MUL1); mathCnt <= 8'd0; end
      `DIVR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `DIVUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `DIVSUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `REMSUR2: begin goto (MUL1); mathCnt <= 8'd20; end
      `PERMR2:
        begin
          res[ 7: 0] <= ia >> {ib[2:0],3'b0};
          res[15: 8] <= ia >> {ib[5:3],3'b0};
          res[23:16] <= ia >> {ib[8:6],3'b0};
          res[31:24] <= ia >> {ib[11:9],3'b0};
          res[39:32] <= ia >> {ib[14:12],3'b0};
          res[47:40] <= ia >> {ib[17:15],3'b0};
          res[55:48] <= ia >> {ib[20:18],3'b0};
          res[63:56] <= ia >> {ib[23:21],3'b0};
        end
      `PTRDIFR2:
        begin
          res <= (ia < ib ? ib - ia : ia - ib) >> ir[24:23];
        end
      `DIFR2:
        begin
          res <= $signed(ia) < $signed(ib) ? ib - ia : ia - ib;
        end
      `BYTNDX2:
        begin
          if (ia[7:0]==ib[7:0])
            res <= 64'd0;
          else if (ia[15:8]==ib[7:0])
            res <= 64'd1;
          else if (ia[23:16]==ib[7:0])
            res <= 64'd2;
          else if (ia[31:24]==ib[7:0])
            res <= 64'd3;
          else if (ia[39:32]==ib[7:0])
            res <= 64'd4;
          else if (ia[47:40]==ib[7:0])
            res <= 64'd5;
          else if (ia[55:40]==ib[7:0])
            res <= 64'd6;
          else if (ia[63:56]==ib[7:0])
            res <= 64'd7;
          else
            res <= {64{1'b1}};  // -1
        end
      `WYDNDX2:
        begin
          if (ia[15:0]==ib[15:0])
            res <= 64'd0;
          else if (ia[31:16]==ib[15:0])
            res <= 64'd1;
          else if (ia[47:32]==ib[15:0])
            res <= 64'd2;
          else if (ia[63:48]==ib[15:0])
            res <= 64'd3;
          else
            res <= {64{1'b1}};  // -1
        end
      `MULF:  res <= ia[23:0] * ib[15:0];
      `MOV:
        begin
          case(ir[21:20])
          2'b00:  begin res <= ia; rares <= ia; end
          2'b01:  ;
          2'b10:  ;
          2'b11:
            casez(Rs1)
            5'b0000?: begin res <= ret_pc; rares <= ret_pc; end
            5'b0001?: begin res <= cao; rares <= cao; end
            5'b00111: begin res <= epc[rprv[1] ? rsStack[9:5] : rsStack[4:0]]; rares <= epc[rprv[1] ? rsStack[9:5] : rsStack[4:0]]; end
            5'b100??: begin res <= cds; rares <= cds; end
            5'b11101: begin res <= cds32; rares <= cds32; end
            default:  ;
            endcase
          endcase
          case (ir[19:18])
          2'b00:  wrirf <= 1'b1;
          2'b01:  wrfrf <= 1'b1;
          2'b10:  ;
          2'b11:  
            casez(ir[12:8])
            5'b0000?: begin rad <= ir[8]; wrra <= 1'b1; end
            5'b0001?: begin rad <= ir[8]; wrca <= 1'b1; end
            5'b100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
            5'b11101: wrcrf32 <= 1'b1;
            default:  ;
            endcase
          endcase
        end
      `R1:
        case(ir[22:18])
        `CNTLZR1: res <= cntlzo;
        `CNTLOR1: res <= cntloo;
        `CNTPOPR1:res <= cntpopo;
        `COMR1:   res <= ~ia;
        `NOTR1:   res <= ia==64'd0;
        `NEGR1:   res <= -ia;
        `TST1:
          begin
            d_tst <= TRUE;
            case(ir[25:23])
            3'd0: // Octa
              case(mop)
              `CMP_CPY:
                begin
                  crres[0] <= ia!=64'd0;
                  crres[1] <= ia==64'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= ^ia;
                  crres[5] <= ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= ia[63];
                end
              `CMP_AND:
                begin
                  crres[0] <= cd && ia!=64'd0;
                  crres[1] <= cd && ia==64'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ^ia;
                  crres[5] <= cd & ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ia[63];
                end
              `CMP_OR:
                begin
                  crres[0] <= cd || ia!=64'd0;
                  crres[1] <= cd || ia==64'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ^ia;
                  crres[5] <= cd | ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ia[63];
                end
              `CMP_ANDCM:
                begin
                  crres[0] <= cd && !(ia!=64'd0);
                  crres[1] <= cd && !(ia==64'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ~^ia;
                  crres[5] <= cd & ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ~ia[63];
                end
              `CMP_ORCM:
                begin
                  crres[0] <= cd || !(ia!=64'd0);
                  crres[1] <= cd || !(ia==64'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ~^ia;
                  crres[5] <= cd | ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ~ia[63];
                end
              default:  ;
              endcase
            3'd1: // Tetra
              case(mop)
              `CMP_CPY:
                begin
                  crres[0] <= ia[31:0]!=32'd0;
                  crres[1] <= ia[31:0]==32'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= ^ia[31:0];
                  crres[5] <= ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= ia[31];
                end
              `CMP_AND:
                begin
                  crres[0] <= cd && ia[31:0]!=32'd0;
                  crres[1] <= cd && ia[31:0]==32'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ^ia[31:0];
                  crres[5] <= cd & ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ia[31];
                end
              `CMP_OR:
                begin
                  crres[0] <= cd || ia[31:0]!=32'd0;
                  crres[1] <= cd || ia[31:0]==32'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ^ia[31:0];
                  crres[5] <= cd | ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ia[31];
                end
              `CMP_ANDCM:
                begin
                  crres[0] <= cd && !(ia[31:0]!=32'd0);
                  crres[1] <= cd && !(ia[31:0]==32'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ~^ia[31:0];
                  crres[5] <= cd & ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ~ia[31];
                end
              `CMP_ORCM:
                begin
                  crres[0] <= cd || !(ia[31:0]!=32'd0);
                  crres[1] <= cd || !(ia[31:0]==32'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ~^ia[31:0];
                  crres[5] <= cd | ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ~ia[31];
                end
              default:  ;
              endcase
            3'd2: // Wyde
              case(mop)
              `CMP_CPY:
                begin
                  crres[0] <= ia[15:0]!=16'd0;
                  crres[1] <= ia[15:0]==16'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= ^ia[15:0];
                  crres[5] <= ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= ia[15];
                end
              `CMP_AND:
                begin
                  crres[0] <= cd && ia[15:0]!=16'd0;
                  crres[1] <= cd && ia[15:0]==16'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ^ia[15:0];
                  crres[5] <= cd & ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ia[15];
                end
              `CMP_OR:
                begin
                  crres[0] <= cd || ia[15:0]!=16'd0;
                  crres[1] <= cd || ia[15:0]==16'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ^ia[15:0];
                  crres[5] <= cd | ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ia[15];
                end
              `CMP_ANDCM:
                begin
                  crres[0] <= cd && !(ia[15:0]!=16'd0);
                  crres[1] <= cd && !(ia[15:0]==16'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ~^ia[15:0];
                  crres[5] <= cd & ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ~ia[15];
                end
              `CMP_ORCM:
                begin
                  crres[0] <= cd || !(ia[15:0]!=16'd0);
                  crres[1] <= cd || !(ia[15:0]==16'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ~^ia[15:0];
                  crres[5] <= cd | ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ~ia[15];
                end
              default:  ;
              endcase
            3'd3: // Byte
              case(mop)
              `CMP_CPY:
                begin
                  crres[0] <= ia[7:0]!=8'd0;
                  crres[1] <= ia[7:0]==8'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= ^ia[7:0];
                  crres[5] <= ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= ia[7];
                end
              `CMP_AND:
                begin
                  crres[0] <= cd && ia[7:0]!=8'd0;
                  crres[1] <= cd && ia[7:0]==8'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ^ia[7:0];
                  crres[5] <= cd & ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ia[7];
                end
              `CMP_OR:
                begin
                  crres[0] <= cd || ia[7:0]!=8'd0;
                  crres[1] <= cd || ia[7:0]==8'd0;
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ^ia[7:0];
                  crres[5] <= cd | ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ia[7];
                end
              `CMP_ANDCM:
                begin
                  crres[0] <= cd && !(ia[7:0]!=8'd0);
                  crres[1] <= cd && !(ia[7:0]==8'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd & ~^ia[7:0];
                  crres[5] <= cd & ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd & ~ia[7];
                end
              `CMP_ORCM:
                begin
                  crres[0] <= cd || !(ia[7:0]!=8'd0);
                  crres[1] <= cd || !(ia[7:0]==8'd0);
                  crres[2] <= 1'b0;
                  crres[3] <= 1'b0;
                  crres[4] <= cd | ~^ia[7:0];
                  crres[5] <= cd | ~ia[0];
                  crres[6] <= 1'b0;
                  crres[7] <= cd | ~ia[7];
                end
              default:  ;
              endcase
            default:  ;
            endcase
          end
        default:  ;                                    
        endcase
      default:  ;
      endcase
    `R2B:
      case(funct5)
      `CHKR2B:
        begin
          goto (IFETCH1);
          if (ia < ib || ia >= ic)
            tException(32'h00000027, ipc);
        end
      default:  ;
      endcase
    `R3A:
      case(ir[30:28])
      `MINR3A:
        if (ia < ib && ia < ic)
          res <= ia;
        else if (ib < ic)
          res <= ib;
        else
          res <= ic;      
      `MAXR3A:
        if (ia > ib && ia > ic)
          res <= ia;
        else if (ib > ic)
          res <= ib;
        else
          res <= ic;      
      `MAJR3A: res <= (ia & ib) | (ia & ic) | (ib & ic);
      `MUXR3A:
        for (n = 0; n < 64; n = n + 1)
          res[n] <= ia[n] ? ib[n] : ic[n];
      `ADDR3A: res <= ia + ib + ic;
      `SUBR3A: res <= ia - ib - ic;
      `FLIPR3A:  res <= bfo;
      default:  ;
      endcase
    `R3B:
    	case(ir[30:28])
      `ANDR3B: res <= ia & ib & ic;
      `ORR3B:  res <= ia | ib | ic;
      `EORR3B: res <= ia ^ ib ^ ic;
      `BLENDR3B:
        begin
          res[ 7: 0] <= blendG1[15:8] + blendG2[15:8];
          res[15: 8] <= blendB1[15:8] + blendB2[15:8];
          res[23:16] <= blendR1[15:8] + blendR2[15:8];
          res[63:24] <= ia[63:24];
        end
      `EXTR3B: res <= bfo;
      `EXTUR3B:  res <= bfo;
      `DEPR3B: res <= bfo;
      default:  ;
      endcase
    `ADD:   res <= ia + imm;
    `ADD5:  res <= ia + imm;
    `ADD22: res <= id + imm;
    `ADD2R: res <= ia + ib;
    `SUBF: res <= imm - ia;
    `MUL: res <= $signed(ia) * $signed(imm);
    `GCSUB: res <= ia - imm;
    `GCSUB10: res <= ia - imm;
    `SHIFT:
      begin
        Rd <= ir[12:8];
        Cs <= 2'd0;
        case(ir[27:24])
        `ASL:  
          case(ir[30:28])
          3'd0:  res <= shlr[64:1];
          3'd1:  res <= {id[63:32],shlr[32:1]};
          3'd2:  res <= {id[63:16],shlr[16:1]};
          3'd3:  res <= {id[63:8],shlr[8:1]};
          default: res <= shlr[64:1];
          endcase
        `LSR:
          case(ir[30:28])
          3'd0: res <= {shrr[63],ia} >> ib[5:0];
          3'd1: res <= {id[63:32],fnTrim32(ia[31:0] >> ib[5:0])};
          3'd2: res <= {id[63:16],fnTrim16(ia[15:0] >> ib[5:0])};
          3'd3: res <= {id[63:8],fnTrim8(ia[7:0] >> ib[5:0])};
          default:  res <= {shrr[63],ia} >> ib[5:0];
          endcase
        `ROL:  res <= shlr[64:1]|shlr[128:65];
        `ROR:  res <= shrr[127:64]|shrr[63:0];
        `ASR:  
          case(ir[30:28])
          3'd0: res <= ia[63] ? {{64{1'b1}},ia} >> ib[5:0] : ia >> ib[5:0];
          3'd1: res <= {id[63:32],fnTrim32(ia[31] ? ({{96{1'b1}},ia[31:0]} >> ib[5:0]) : ia[31:0] >> ib[5:0])};
          3'd2: res <= {id[63:16],fnTrim16(ia[31] ? ({{112{1'b1}},ia[15:0]} >> ib[5:0]) : ia[15:0] >> ib[5:0])};
          3'd3: res <= {id[63:8],fnTrim8(ia[31] ? ({{120{1'b1}},ia[7:0]} >> ib[5:0]) : ia[7:0] >> ib[5:0])};
          default:  res <= ia[63] ? {{64{1'b1}},ia} >> ib[5:0] : shrr[63:0];
          endcase
        `LSRX: res <= {shrr[63],shrr[127:64]};
        `ASLX: res <= shlr[63:0];
        `ASLI:
          case(ir[30:28])
          3'd0:  res <= shli[64:1];
          3'd1:  res <= {id[63:32],shli[32:1]};
          3'd2:  res <= {id[63:16],shli[16:1]};
          3'd3:  res <= {id[63:8],shli[8:1]};
          default: res <= shli[64:1];
          endcase
        `LSRI:
          case(ir[30:28])
          3'd0: res <= {shrr[63],ia >> imm[5:0]};
          3'd1: res <= {id[63:32],fnTrim32(ia[31:0] >> imm[5:0])};
          3'd2: res <= {id[63:16],fnTrim16(ia[15:0] >> imm[5:0])};
          3'd3: res <= {id[63:8],fnTrim8(ia[7:0] >> imm[5:0])};
          default:  res <= {shrr[63],ia} >> imm[5:0];
          endcase
        `ROLI: res <= shli[64:1]|shli[128:65];
        `RORI: res <= shri[127:64]|shri[63:0];
        `ASRI: 
          case(ir[30:28])
          3'd0: res <= ia[63] ? {{64{1'b1}},ia} >> imm[5:0] : ia >> imm[5:0];
          3'd1: res <= {id[63:32],fnTrim32(ia[31] ? ({{96{1'b1}},ia[31:0]} >> imm[5:0]) : ia[31:0] >> imm[5:0])};
          3'd2: res <= {id[63:16],fnTrim16(ia[31] ? ({{112{1'b1}},ia[15:0]} >> imm[5:0]) : ia[15:0] >> imm[5:0])};
          3'd3: res <= {id[63:8],fnTrim8(ia[31] ? ({{120{1'b1}},ia[7:0]} >> imm[5:0]) : ia[7:0] >> imm[5:0])};
          default:  res <= ia[63] ? {{64{1'b1}},ia} >> imm[5:0] : ia >> imm[5:0];
          endcase
        `ASLXI: res <= shli[64:1];
        `LSRXI: res <= {shri[63],shri[127:64]};
        default:  ;
        endcase
      end
    `SET:
      begin
        case(ir[30:28])
        `SEQR2: setcr(ia==ib);
        `SNER2: setcr(ia!=ib);
        `SLTR2: setcr($signed(ia) < $signed(ib));
        `SGER2: setcr($signed(ia) >= $signed(ib));
        `SLTUR2: setcr(ia <  ib);
        `SGEUR2: setcr(ia >= ib);
        `SANDR2: setcr(ia!=64'd0 && ib != 64'd0);
        `SORR2: setcr(ia!=64'd0 || ib != 64'd0);
        default:  ;
        endcase
      end
    `SEQ: setcr(ia==imm);
    `SNE: setcr(ia!=imm);
    `SLT: setcr($signed(ia) < $signed(imm));
    `SGE: setcr($signed(ia) >= $signed(imm));
    `SLE: setcr($signed(ia) <= $signed(imm));
    `SGT: setcr($signed(ia) > $signed(imm));
    `SLTU: setcr(ia <  imm);
    `SGEU: setcr(ia >= imm);
    `SLEU: setcr(ia <= imm);
    `SGTU: setcr(ia >  imm);
    `SAND: setcr(ia != 64'd0 && imm != 64'd0);
    `SOR: setcr(ia != 64'd0 || imm != 64'd0);

    `AND: res <= ia & imm;
    `OR:  res <= ia | imm;
    `OR5: res <= ia | imm;
    `OR2R:  res <= ia | ib;
    `EOR: res <= ia ^ imm;
    `PERM:
      begin
        res[ 7: 0] <= ia >> {ir[20:18],3'b0};
        res[15: 8] <= ia >> {ir[23:21],3'b0};
        res[23:16] <= ia >> {ir[26:24],3'b0};
        res[31:24] <= ia >> {ir[29:27],3'b0};
        res[39:32] <= ia >> {ir[34:32],ir[30],3'b0};
        res[47:40] <= ia >> {ir[38:35],3'b0};
        res[55:48] <= ia >> {ir[42:39],3'b0};
        res[63:56] <= ia >> {ir[46:43],3'b0};
      end
    // Bitfield
    `EXT: res <= bfo;
    `DEP: res <= bfo;
    `DEPI:  res <= bfo;
    `FFO: res <= bfo;
    `BYTNDX:
      begin
        if (ia[7:0]==imm[7:0])
          res <= 64'd0;
        else if (ia[15:8]==imm[7:0])
          res <= 64'd1;
        else if (ia[23:16]==imm[7:0])
          res <= 64'd2;
        else if (ia[31:24]==imm[7:0])
          res <= 64'd3;
        else if (ia[39:32]==imm[7:0])
          res <= 64'd4;
        else if (ia[47:40]==imm[7:0])
          res <= 64'd5;
        else if (ia[55:40]==imm[7:0])
          res <= 64'd6;
        else if (ia[63:56]==imm[7:0])
          res <= 64'd7;
        else
          res <= {64{1'b1}};  // -1
      end
    `WYDNDX:
      begin
        if (ia[15:0]==imm[15:0])
          res <= 64'd0;
        else if (ia[31:16]==imm[15:0])
          res <= 64'd1;
        else if (ia[47:32]==imm[15:0])
          res <= 64'd2;
        else if (ia[63:48]==imm[15:0])
          res <= 64'd3;
        else
          res <= {64{1'b1}};  // -1
      end
    `MULFI:  res <= ia[23:0] * imm[15:0];
    `CHK:
      begin
        goto (IFETCH1);
        if (ia < ib || ia >= imm)
          tException(32'h00000027, ipc);
      end
    `ADDUI: res <= id + imm;
    `ANDUI: res <= id & imm;
    `ORUI: res <= id & imm;
    `AUIIP: res <= ipc + imm;
    `CSR:
      begin
        res <= 64'd0;
        wrirf <= 1'b1;
        case(ir[39:37])
        3'd4,3'd5,3'd6,3'd7:  ia <= Rs1;
        default:  ;
        endcase
        casez(ir[28:18])
        11'b???_0000_0010:  res <= tick;
        11'b001_0001_0000:  res <= TaskId;
        11'b001_0001_1111:  res <= ASID;
        11'b001_0010_0000:  res <= {key[2],key[1],key[0]};
        11'b001_0010_0001:  res <= {key[5],key[4],key[3]};
        11'b001_0010_0010:  res <= {key[8],key[7],key[6]};
        11'b011_0000_0001:  res <= hartid_i;
        11'b???_0000_0110:  res <= cause[ir[28:26]];
        11'b???_0000_0111:  res <= badaddr[ir[28:26]];
        11'b???_0000_1001:  res <= scratch[ir[28:26]];
        11'b???_0011_0???:  res <= tvec[ir[28:26]];
        11'b???_0100_0000:  res <= pmStack;
        11'b???_0100_0011:  res <= rsStack;
        11'b???_0100_1000:  res <= epc[rprv[4] ? rsStack[9:5] : rsStack[4:0]];
        11'b101_0001_10??:  res <= dbad[ir[19:18]];
        11'b101_0001_1100:  res <= dbcr;
        11'b101_0001_1101:  res <= dbsr;
        default:  ;
        endcase
      end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Flow Control
    // Effective address for JSR/RTS set by address generator module above.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    `JSR,`JSR18:
      begin
        res <= ia - 4'd8; // decrement sp
        goto (MEMORY1);
      end
    `RTL: 
      begin
        res <= ia + imm;
        pc <= ret_pc + {ir[12:9],2'b00};
      end
    `RTS,`RTX: 
      begin
        res <= ia + imm;
        goto (MEMORY1);
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,
    `BLEU,`BGTU,`BOD,`BPS,`BEQZ,`BNEZ,`BRA:
      brdat <= {56'd0,cd};
    `BEQI,`BBC,`BBS:
      brdat <= id;
    `BT:
      brdat <= {56'd0,cd};

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    `OSR2:
      case(funct5)
      `CACHE: goto (MEMORY1);
  		`WFI:
  		  begin
  			  set_wfi <= 1'b1;
  			  illegal_insn <= 1'b0;
  		  end
  		`SETKEY:  if (!illegal_insn) res <= {18'd0,ia[45:32],12'd0,keyoa};
  		`GCCLR:
  		  begin
  		    case(ia[30:28])
  		    3'd0: res <= cardmem0o;
  		    3'd1: res <= {32'd0,card1o};
  		    3'd2: res <= {card22o,card21o};
  		    default:  ;
  		    endcase
  		  end
      `REX:
        if (ir[10:8] < omode) begin
          illegal_insn <= 1'b0;
          case(ir[10:8])
          3'd0:
            if (uie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'b0;
              rsStack[4:0] <= 5'd26;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd1:
            if (sie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd2;
              rsStack[4:0] <= 5'd27;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd2:
            if (hie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd4;
              rsStack[4:0] <= 5'd28;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd3:
            if (mie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd6;
              rsStack[4:0] <= 5'd29;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          3'd4:
            if (iie) begin
              badaddr[ir[10:8]] <= badaddr[omode];
              cause[ir[10:8]] <= cause[omode];
              pmStack[3:0] <= 4'd8;
              rsStack[4:0] <= 5'd30;
              next_epc <= epc[crs];
              pc <= tvec[ir[10:8]];
            end
          default:  ;
          endcase
        end
      `MVMAP: begin mathCnt <= 8'd2; goto (PAGEMAPA); end
      `TLBRW: begin tlben <= 1'b1; tlbwr <= ia[63]; mathCnt <= 8'd2; goto (PAGEMAPA); end
      `PEEKQ:
        case(ia[3:0])
        4'd15:  res <= trace_dout;
        default: ;
        endcase
      `POPQ:
        case(ia[3:0])
        4'd15:  begin rd_trace <= 1'b1; res <= trace_dout; end
        default: ;
        endcase
      `STATQ:
        case(ia[3:0])
        4'd15:  res <= {trace_empty,trace_valid,52'd0,trace_data_count};
        default: ;
        endcase
      `MVCI:  res <= ci_tblo2;
    endcase

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Memory Ops
    // Address generation is done by a module above.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    `LDBS,`LDBUS,`LDWS,`LDWUS,`LDTS,`LDTUS,`LDOS,`LDORS,
    `STBS,`STWS,`STTS,`STOS,`STOTS,`STOCS,`STPTRS,`LEAS:    
      goto (MEMORY1);
    `LDB,`LDBU,`STB:
      goto (MEMORY1);
    `LDW,`LDWU,`STW:
      goto (MEMORY1);
    `LDT,`LDTU,`STT:
      goto (MEMORY1);
    `LDO,`LDOR,`LDOT,`FLDO,`PLDO,`STO,`STOC,`STOT,`STPTR,`FSTO,`PSTO,`LEA:
      goto (MEMORY1);
    `PUSH,`PUSHC:
      begin
        res <= ia - 4'd8; // decrement sp
        goto (MEMORY1);
      end
    `POP:
      begin
        Rd <= 5'd31;
        res <= ia + 4'd8;
        goto (MEMORY1);
      end
    `LINK:
      begin
        Rd <= 5'd30;
        res <= ia;
        goto (MEMORY1);
      end
    `UNLINK:
      begin
        Rd <= 5'd31;
        res <= ia;
        goto (MEMORY1);
      end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		`FMA,`FMS,`FNMA,`FNMS:
			begin mathCnt <= 45; state <= FLOAT; illegal_insn <= 1'b0; end
		// The timeouts for the float operations are set conservatively. They may
		// be adjusted to lower values closer to actual time required.
		`FLT2:	// Float
			case(fltfunct5)
			`FLT1:
			  case(Rs2)
  	    `FMOV:  begin mathCnt <= 8'd00; state <= FLOAT; illegal_insn <= 1'b0; end	// FMOV
  	    `FTOI:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end
  	    `ITOF:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end
  	    `FS2D:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end
  	    `FD2S:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end
				`CPYSGN:  begin res <= {ib[FPWID-1],ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
				`SGNINV:  begin res <= {~ib[FPWID-1],ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
				`SGNAND:  begin res <= {ib[FPWID-1]&ia[FPWID-1],ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
				`SGNOR:   begin res <= {ib[FPWID-1]|ia[FPWID-1],ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
				`SGNEOR:  begin res <= {ib[FPWID-1]^ia[FPWID-1],ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
				`SGNENOR: begin res <= {~(ib[FPWID-1]^ia[FPWID-1]),ia[FPWID-1:0]}; illegal_insn <= 1'b0; end
  	    `FCLASS:
						begin
							res[0] <= ia[FPWID-1] & fa_inf;
							res[1] <= ia[FPWID-1] & !fa_xz;
							res[2] <= ia[FPWID-1] &  fa_xz;
							res[3] <= ia[FPWID-1] &  fa_vz;
							res[4] <= ~ia[FPWID-1] &  fa_vz;
							res[5] <= ~ia[FPWID-1] &  fa_xz;
							res[6] <= ~ia[FPWID-1] & !fa_xz;
							res[7] <= ~ia[FPWID-1] & fa_inf;
							res[8] <= fa_snan;
							res[9] <= fa_qnan;
							illegal_insn <= 1'b0;
						end
        default: ;
			  endcase
			`FADD:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FADD
			`FSUB:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FSUB
			`FMUL:	begin mathCnt <= 8'd30; state <= FLOAT; illegal_insn <= 1'b0; end	// FMUL
			`FDIV:	begin mathCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
			`FCMP:	begin mathCnt <= 8'd40; state <= FLOAT; illegal_insn <= 1'b0; end	// FDIV
			`FSQRT:	begin mathCnt <= 8'd160; state <= FLOAT; illegal_insn <= 1'b0; end	// FSQRT
			`FSLE:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FSLE
		  `FSLT:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FSLT
			`FSEQ:	begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FSEQ
  	  `FMIN:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FMIN / FMAX
  	  `FMAX:  begin mathCnt <= 8'd03; state <= FLOAT; illegal_insn <= 1'b0; end	// FMIN / FMAX
			default:	;
			endcase
    endcase
  end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Multiply / Divide
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Adjust for sign
MUL1:
	begin
		ldd <= 1'b1;
    goto (MUL2);
		case(opcode)
		`R2,`R2B:
	    case(ir[30:26])
	    `MULR2,`DIVR2,`REMR2,`MULHR2:
  		  begin
  				sgn <= ia[WID-1] ^ ib[WID-1];	// compute output sign
  				if (ia[WID-1]) ia <= -ia;			// Make both values positive
  				if (ib[WID-1]) ib <= -ib;
  		  end
  		`MULSUR2,`MULSUHR2:
  			begin
  				sgn <= ia[WID-1];
  				if (ia[WID-1]) ia <= -ia;
  			end
  	  default:  ;
	    endcase
		`MUL,`DIV,`REM:
		  begin
				sgn <= ia[WID-1] ^ imm[WID-1];	// compute output sign
				if (ia[WID-1]) ia <= -ia;			// Make both values positive
				if (ib[WID-1]) ib <= -imm; else ib <= imm;
		  end
		`MULU,`DIVU,`REMU:
		  ib <= imm;
		default:  ;
	  endcase
	end
// Capture result
MUL2:
	begin
		mathCnt <= mathCnt - 8'd1;
		if (mathCnt==8'd0) begin
			state <= WRITEBACK;
			case(opcode)
			`R2,`R2B:
			  case(ir[30:26])
			  `MULR2:   res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			  `MULUR2:  res <= prod[WID-1:0];
			  `MULSUR2: res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			  `MULHR2:  res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			  `MULUHR2: res <= prod[WID*2-1:WID];
			  `MULSUHR2:res <= sgn ? nprod[WID*2-1:WID] : prod[WID*2-1:WID];
			  `DIVR2:   res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			  `DIVUR2:  res <= div_q[WID*2-1:WID];
			  `DIVSUR2: res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			  `REMR2:   res <= sgn ? ndiv_r : div_r;
			  `REMUR2:  res <= div_r;
			  `REMSUR2: res <= sgn ? ndiv_r : div_r;
			  default:  ;
			  endcase
			`MUL,`MULSU:  res <= sgn ? nprod[WID-1:0] : prod[WID-1:0];
			`MULU: res <= prod[WID-1:0];
			`DIV:  res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			`DIVU: res <= div_q[WID*2-1:WID];
			`DIVSU:res <= sgn ? ndiv_q[WID*2-1:WID] : div_q[WID*2-1:WID];
			`REM:  res <= sgn ? ndiv_r : div_r;
			`REMU: res <= div_r;
			`REMSU:res <= sgn ? ndiv_r : div_r;
			default:  ;
		  endcase
		end
	end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Memory stage
// Load or store the memory value.
// Wait for operation to complete.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
PAGEMAPA:
  begin
    tlbwr <= 1'b0;
    mathCnt <= mathCnt - 2'd1;
    if (mathCnt==8'd0) begin
      case(funct5)
      `MVMAP: res <= {50'd0,pagemapoa}; 
      `TLBRW: begin tlben <= 1'b0; res <= tlbdato; end
      default:  ;
      endcase
      goto (WRITEBACK);
    end
  end
MEMORY1:
  begin
    if (opcode==`LINK) begin
      Rd <= 5'd31;
      res <= ia + imm;
    end
`ifdef RTF64_TLB
    goto (MEMORY1a);
`else
    goto (MEMORY2);
`endif
    if (opcode==`LEA || opcode==`LEAS) begin
      res <= ea;
      goto (WRITEBACK);
    end
    else begin
      tEA();
      xlaten <= TRUE;
`ifdef CPU_B128
      sel <= selx << ea[3:0];
      dat <= id << {ea[3:0],3'b0};
`endif
`ifdef CPU_B64
      sel <= selx << ea[2:0];
      dat <= id << {ea[2:0],3'b0};
`endif
`ifdef CPU_B32
      sel <= selx << ea[1:0];
      dat <= id << {ea[1:0],3'b0};
`endif
      ealow <= ea[7:0];
    end
  end
MEMORY1a:
  goto (MEMORY2);
// This cycle for pageram access
MEMORY2:
  begin
    goto (MEMORY_KEYCHK1);
  end
MEMORY_KEYCHK1:
  begin
    goto (MEMORY3);
    if (d_cache)
      tPMAEA();
  end
MEMORY3:
  begin
    xlaten <= FALSE;
    goto (MEMORY4);
`ifdef RTF64_TLB
		if (tlbmiss) begin
		  tException(32'h80000004,ipc);
  	  badaddr[3'd5] <= ea;
  	end
    else
`endif    
    if (~d_cache) begin
      cyc_o <= HIGH;
      stb_o <= HIGH;
`ifdef CPU_B128
      sel_o <= sel[15:0];
      dat_o <= dat[127:0];
`endif
`ifdef CPU_B64
      sel_o <= sel[7:0];
      dat_o <= dat[63:0];
`endif
`ifdef CPU_B32
      sel_o <= sel[3:0];
      dat_o <= dat[31:0];
`endif
      case(opcode)
      `STB,`STW,`STT,`STO,`STOT,`STOC,`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,`STOTS,`STOCS,`STPTRS,`FSTOS,`PSTOS:
        we_o <= HIGH;
      default:  ;
      endcase
    end
  end
MEMORY4:
  begin
    if (d_cache) begin
      icvalid[adr_o[pL1msb:5]] <= 1'b0;
      goto (IFETCH1);
    end
    else if (acki) begin
      goto (MEMORY5);
      stb_o <= LOW;
      dati <= dat_i;
      if (sel[`SELH]==1'h0) begin
        cyc_o <= LOW;
        we_o <= LOW;
        sel_o <= 1'h0;
      end
    end
  end
MEMORY5:
  if (~acki) begin
    if (|sel[`SELH])
      goto (MEMORY6);
    else begin
      case(opcode)
      `STB,`STW,`STT,`STO,`STOT,`STOC,`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,`STOTS,`STOCS,`STPTRS,`FSTOS,`PSTOS:
        goto (IFETCH1);
      `JSR,`JSR18:
        goto (WRITEBACK);
      default:
        goto (DATA_ALIGN);
      endcase
    end
  end
MEMORY6:
  begin
`ifdef RTF64_TLB
    goto (MEMORY6a);
`else
    goto (MEMORY7);
`endif
    xlaten <= TRUE;
    tEA();
  end
MEMORY6a:
  goto (MEMORY7);
MEMORY7:
  goto (MEMORY_KEYCHK2);
MEMORY_KEYCHK2:
  begin
    goto (MEMORY8);
    tPMAEA();
  end
MEMORY8:
  begin
    xlaten <= FALSE;
    goto (MEMORY9);
`ifdef RTF64_TLB    
		if (tlbmiss) begin
		  tException(32'h80000004,ipc);
  	  badaddr[3'd5] <= ea;
		  cyc_o <= LOW;
		  stb_o <= LOW;
		  we_o <= 1'b0;
		  sel_o <= 1'd0;
	  end
		else
`endif
		begin
      stb_o <= HIGH;
      sel_o <= sel[`SELH];
      dat_o <= dat[`DATH];
    end
  end
MEMORY9:
  if (acki) begin
    goto (MEMORY10);
    stb_o <= LOW;
    dati[`DATH] <= dat_i;
`ifdef CPU_B128
    cyc_o <= LOW;
    we_o <= LOW;
    sel_o <= 1'h0;
`endif
`ifdef CPU_B64
    cyc_o <= LOW;
    we_o <= LOW;
    sel_o <= 1'h0;
`endif
`ifdef CPU_B32
    if (sel[11:8]==4'h0) begin
      cyc_o <= LOW;
      we_o <= LOW;
      sel_o <= 4'h0;
    end
`endif
  end
MEMORY10:
  if (~acki) begin
`ifdef CPU_B32
    ea <= {ea[31:2]+2'd1,2'b00};
    if (sel[11:8])
      goto (MEMORY11);
    else
`endif
    begin
      case(opcode)
      `STB,`STW,`STT,`STO,`STOT,`STOC,`STPTR,`FSTO,`PSTO,
      `STBS,`STWS,`STTS,`STOS,`STOTS,`STOCS,`STPTRS,`FSTOS,`PSTOS:
        goto (IFETCH1);
      `JSR,`JSR18:
        goto (WRITEBACK);
      default:
        goto (DATA_ALIGN);
      endcase
    end
  end
MEMORY11:
  begin
`ifdef RTF64_TLB
    goto (MEMORY11a);
`else
    goto (MEMORY12);
`endif
    xlaten <= TRUE;
    tEA();
  end
MEMORY11a:
  goto (MEMORY12);
MEMORY12:
  goto (MEMORY_KEYCHK3);
MEMORY_KEYCHK3:
  begin
    goto (MEMORY13);
    tPMAEA();
  end
MEMORY13:
  begin
    xlaten <= FALSE;
    goto (MEMORY14);
`ifdef RTF64_TLB    
		if (tlbmiss) begin
		  tException(32'h80000004,ipc);
  	  badaddr[3'd5] <= ea;
		  cyc_o <= LOW;
		  stb_o <= LOW;
		  we_o <= 1'b0;
		  sel_o <= 1'd0;
	  end
		else
`endif		
		begin
      stb_o <= HIGH;
      sel_o <= sel[11:8];
      dat_o <= dat[95:64];
    end
  end
MEMORY14:
  if (acki) begin
    goto (MEMORY15);
    cyc_o <= LOW;
    stb_o <= LOW;
    we_o <= LOW;
    sel_o <= 4'h0;
    dati[95:64] <= dat_i;
  end
MEMORY15:
  if (~acki) begin
    case(opcode)
    `STB,`STW,`STT,`STO,`STOT,`STOC,`STPTR,`FSTO,`PSTO,
    `STBS,`STWS,`STTS,`STOS,`STOTS,`STOCS,`STPTRS,`FSTOS,`PSTOS:
      goto (IFETCH1);
    `JSR,`JSR18:
      goto (WRITEBACK);
    default:
      goto (DATA_ALIGN);
    endcase
  end
DATA_ALIGN:
  begin
    goto (WRITEBACK);
    case(opcode)
    `LDB,`LDBS:   res <= {{56{datis[7]}},datis[7:0]};
    `LDBU,`LDBUS: res <= {{56{1'b0}},datis[7:0]};
    `LDW,`LDWS:   res <= {{48{datis[15]}},datis[15:0]};
    `LDWU,`LDWUS: res <= {{48{1'b0}},datis[15:0]};
    `LDT,`LDTS:   res <= {{32{datis[31]}},datis[31:0]};
    `LDTU,`LDTUS:  res <= {{32{1'b0}},datis[31:0]};
    `LDO,`LDOS:   res <= datis[63:0];
    `LDOT:  begin crres <= datis[31:0]; rares <= datis[AWID-1:0]; end
    `LDOR,`LDORS: res <= datis[63:0];
    `FLDO,`PLDO:  res <= datis[63:0];
    `RTS:    pc <= datis[63:0] + {ir[12:9],2'b00};
    `RTX:    pc <= datis[63:0];
    `UNLINK:  begin res <= datis[63:0]; Rd <= 5'd30; end
    `POP:   begin crres <= datis[31:0]; rares <= datis[AWID-1:0]; res <= datis[63:0]; end
    default:  ;
    endcase
  end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Float
// Wait for floating-point operation to complete.
// Capture results.
// Set status flags.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
FLOAT:
	begin
		mathCnt <= mathCnt - 2'd1;
		if (mathCnt==8'd0) begin
			case(opcode)
			`FMA,`FMS,`FNMA,`FNMS:
				begin
					res <= fres;
					if (fdn) fuf <= 1'b1;
					if (finf) fof <= 1'b1;
					if (norm_nx) fnx <= 1'b1;
				end
			`FLT2:
				case(fltfunct5)
				`FADD:
					begin
						res <= fres;	// FADD
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FSUB:
					begin
						res <= fres;	// FSUB
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FMUL:
					begin
						res <= fres;	// FMUL
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FDIV:	
					begin
						res <= fres;	// FDIV
						if (fdn) fuf <= 1'b1;
						if (finf) fof <= 1'b1;
						if (ib[FPWID-2:0]==1'd0)
							fdz <= 1'b1;
						if (norm_nx) fnx <= 1'b1;
					end
				`FMIN:	// FMIN	
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= ib;
					else if (!fa_nan & fb_qnan)
						res <= ia;
					else if (fcmp_o[1])
						res <= ia;
					else
						res <= ib;
				`FMAX:	// FMAX
					if ((fa_snan|fb_snan)||(fa_qnan&fb_qnan))
						res <= 32'h7FFFFFFF;	// canonical NaN
					else if (fa_qnan & !fb_nan)
						res <= ib;
					else if (!fa_nan & fb_qnan)
						res <= ia;
					else if (fcmp_o[1])
						res <= ib;
					else
						res <= ia;
			  `FCMP:
			    begin
			      case(mop)
			      `CMP_CPY:
			        begin
    			      crres[0] <= 1'b0;
    			      crres[1] <= fcmp_o[0] & ~cmpnan;
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_AND:
			        begin
    			      crres[0] <= 1'b0;
    			      crres[1] <= cd[1] & fcmp_o[0] & ~cmpnan;
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cd[6] & finf;
    			      crres[7] <= cd[7] & fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_OR:
			        begin
    			      crres[0] <= cd[0];
    			      crres[1] <= cd[1] | (fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | finf;
    			      crres[7] <= cd[7] | (fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ANDCM:
			        begin
    			      crres[0] <= cd[0];
    			      crres[1] <= cd[1] & ~(fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] & ~finf;
    			      crres[7] <= cd[7] & ~(fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ORCM:
			        begin
    			      crres[0] <= cd[0];
    			      crres[1] <= cd[1] | ~(fcmp_o[0] & ~cmpnan);
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | ~finf;
    			      crres[7] <= cd[7] | ~(fcmp_o[1] & ~cmpnan);
			        end
			      default:  crres <= cd;
			      endcase
			    end
				`FSLE:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[2] & ~cmpnan;	// FSLE
    						crres[1] <= fcmp_o[2] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_AND:
					    begin
    						crres[0] <= cd[0] & fcmp_o[2] & ~cmpnan;	// FSLE
    						crres[1] <= cd[1] & fcmp_o[2] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cd[6] & finf;
    			      crres[7] <= cd[7] & fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_OR:
					    begin
    						crres[0] <= cd[0] | (fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] | (fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | finf;
    			      crres[7] <= cd[7] | (fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ANDCM:
					    begin
    						crres[0] <= cd[0] & ~(fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] & ~(fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] & ~finf;
    			      crres[7] <= cd[7] & ~(fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ORCM:
					    begin
    						crres[0] <= cd[0] | ~(fcmp_o[2] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] | ~(fcmp_o[2] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | ~finf;
    			      crres[7] <= cd[7] | ~(fcmp_o[1] & ~cmpnan);
					    end
			      default:  crres <= cd;
					  endcase
						if (cmpnan)
							fnv <= 1'b1;
					end
			  `FSLT:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[1] & ~cmpnan;	// FSLE
    						crres[1] <= fcmp_o[1] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_AND:
					    begin
    						crres[0] <= cd[0] & fcmp_o[1] & ~cmpnan;	// FSLE
    						crres[1] <= cd[1] & fcmp_o[1] & ~cmpnan;	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cd[6] & finf;
    			      crres[7] <= cd[7] & fcmp_o[1] & ~cmpnan;
					    end
					  `CMP_OR:
					    begin
    						crres[0] <= cd[0] | (fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] | (fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | finf;
    			      crres[7] <= cd[7] | (fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ANDCM:
					    begin
    						crres[0] <= cd[0] & ~(fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] & ~(fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] & ~finf;
    			      crres[7] <= cd[7] & ~(fcmp_o[1] & ~cmpnan);
					    end
					  `CMP_ORCM:
					    begin
    						crres[0] <= cd[0] | ~(fcmp_o[1] & ~cmpnan);	// FSLE
    						crres[1] <= cd[1] | ~(fcmp_o[1] & ~cmpnan);	// FSLE
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | ~finf;
    			      crres[7] <= cd[7] | ~(fcmp_o[1] & ~cmpnan);
					    end
			      default:  crres <= cd;
					  endcase
						if (cmpnan)
							fnv <= 1'b1;
					end
				`FSEQ:
					begin
					  case(mop)
					  `CMP_CPY:
					    begin
    						crres[0] <= fcmp_o[0] & ~cmpnan;	// FSEQ
    						crres[1] <= fcmp_o[0] & ~cmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= finf;
    			      crres[7] <= fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_AND:
			        begin
    						crres[0] <= cd[0] & fcmp_o[0] & ~cmpnan;	// FSEQ
    						crres[1] <= cd[1] & fcmp_o[0] & ~cmpnan;	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= 1'b0;
    			      crres[5] <= 1'b0;
    			      crres[6] <= cd[6] & finf;
    			      crres[7] <= cd[7] & fcmp_o[1] & ~cmpnan;
			        end
			      `CMP_OR:
			        begin
    						crres[0] <= cd[0] | (fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cd[1] | (fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | finf;
    			      crres[7] <= cd[7] | (fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ANDCM:
			        begin
    						crres[0] <= cd[0] & ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cd[1] & ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] & ~finf;
    			      crres[7] <= cd[7] & ~(fcmp_o[1] & ~cmpnan);
			        end
			      `CMP_ORCM:
			        begin
    						crres[0] <= cd[0] | ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    						crres[1] <= cd[1] | ~(fcmp_o[0] & ~cmpnan);	// FSEQ
    			      crres[2] <= 1'b0;
    			      crres[3] <= 1'b0;
    			      crres[4] <= cd[4];
    			      crres[5] <= cd[5];
    			      crres[6] <= cd[6] | ~finf;
    			      crres[7] <= cd[7] | ~(fcmp_o[1] & ~cmpnan);
			        end
			      default:  crres <= cd;
			      endcase
						if (cmpsnan)
							fnv <= 1'b1;
					end
				`FLT1:
				  case(Rs2)
					`FSQRT:
  					begin
  						res <= fres;	// FSQRT
  						if (fdn) fuf <= 1'b1;
  						if (finf) fof <= 1'b1;
  						if (ia[FPWID-2:0]==1'd0)
  							fdz <= 1'b1;
  						if (sqrinf|sqrneg)
  							fnv <= 1'b1;
  						if (norm_nx) fnx <= 1'b1;
  					end
				  `FTOI:	res <= ftoi_res;	// FCVT.W.S
				  `ITOF:	res <= itof_res;	// FCVT.S.W
  				default:	;
  				endcase // FLT1
  			default:  ;
  		  endcase   // FLT2
			default:	;
			endcase     // opcode
			state <= WRITEBACK;
		end
	end
WRITEBACK:
  begin
    $display("ia: %h  ib:%h  ic:%h  id:%h  imm:%h", ia, ib, ic, id, imm);
    $display("res: %h", res);
    // Compares and sets already update crres
    if (~d_cmp & ~d_set & ~d_tst & ~d_fltcmp & ~illegal_insn & wrcrf) begin
      crres[0] <= res[64];
      crres[1] <= res[63:0]==64'd0;
      crres[2] <= 1'b0;
      crres[3] <= 1'b0;
      crres[4] <= ^res[63:0];
      crres[5] <= res[0];
      crres[6] <= res[64]^res[63];
      crres[7] <= res[63];
    end
		if (illegal_insn)
		  tException(32'd37, ipc);
    else
    case (opcode)
    `R2:
      case(funct5)
      `MOV:
        begin
          case(ir[21:20])
          2'b00:  ;
          2'b01:  ;
          2'b10:  ;
          2'b11:
            casez(Rd)
            5'b0000?: wrra <= 1'b1;
            5'b0001?: wrca <= 1'b1;
            5'b00111: epc[rprv[1] ? rsStack[9:5] : rsStack[4:0]] <= res;
            5'b100??: wrcrf <= 1'b1;
            5'b11101: wrcrf32 <= 1'b1;
            default:  ;
            endcase
          endcase
        end
      default:  ;
      endcase
    `CSR:
      begin
        if (Rs1 != 5'd0)
        case(ir[39:37])
        3'd0: ; // read only
        3'd1,3'd5:
          casez(ir[28:18])
          11'b001_0001_0000:  TaskId <= ia;
          11'b001_0001_1111:  ASID <= ia;
          11'b001_0010_0000:  begin key[0] <= ia[19:0]; key[1] <= ia[39:20]; key[2] <= ia[59:40]; end
          11'b001_0010_0001:  begin key[3] <= ia[19:0]; key[4] <= ia[39:20]; key[5] <= ia[59:40]; end
          11'b001_0010_0010:  begin key[6] <= ia[19:0]; key[7] <= ia[39:20]; key[8] <= ia[59:40]; end
          11'b???_0000_0110:  cause[ir[28:26]] <= ia;
          11'b???_0000_0111:  badaddr[ir[28:26]] <= ia;
          11'b???_0000_1001:  scratch[ir[28:26]] <= ia;
          11'b???_0011_0???:  tvec[ir[28:26]] <= ia;
          11'b???_0100_0000:  pmStack <= ia;
          11'b???_0100_0011:  rsStack <= ia;
				  11'b???_0100_1000:	epc[rprv[4] ? rsStack[9:5] : rsStack[4:0]] <= ia;
				  11'b???_0001_1100:
				    begin
  			      rprv <= ia[4:0];
  			      Rdx1  <= ia[0] ? rsStack[9:5] : rsStack[4:0];
  			      Rs1x1 <= ia[1] ? rsStack[9:5] : rsStack[4:0];
  			      Rs2x1 <= ia[2] ? rsStack[9:5] : rsStack[4:0];
  			      Rs3x1 <= ia[3] ? rsStack[9:5] : rsStack[4:0];
  			    end
          11'b101_0001_10??:  dbad[ir[19:18]] <= ia;
          11'b101_0001_1100:  dbcr <= ia;
          11'b101_0001_1101:  dbsr <= ia;
          default:  ;
          endcase
        3'd2,3'd6:
          casez(ir[28:18])
          11'b???_0100_0000:  pmStack <= pmStack | ia;
          11'b???_0100_0011:  rsStack <= rsStack | ia;
          11'b101_0001_1100:  dbcr <= dbcr | ia;
          11'b101_0001_1101:  dbsr <= dbsr | ia;
          default:  ;
          endcase
        3'd3,3'd7:
          casez(ir[28:18])
          11'b???_0100_0000:  pmStack <= pmStack & ~ia;
          11'b???_0100_0011:  rsStack <= rsStack & ~ia;
          11'b101_0001_1100:  dbcr <= dbcr & ~ia;
          11'b101_0001_1101:  dbsr <= dbsr & ~ia;
          default:  ;
          endcase
        endcase
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,
    `BLEU,`BGTU,`BOD,`BPS,`BEQZ,`BNEZ,`BRA:
      begin
        if (takb) begin
          pc <= ipc + {{50{ir[23]}},ir[23:10]};
          if (ir[23:10]==14'd0)
            tException(`FLT_BT, ipc);
        end
      end
    `BEQI,`BBC,`BBS:
      begin
        if (takb) begin
          pc <= ipc + {{52{ir[31]}},ir[31:21]};
          if (ir[31:21]==12'd0)
            tException(`FLT_BT, ipc);
        end
      end
    `BT:
      begin
        if (takb) begin
          pc <= ipc + {{58{ir[15]}},ir[15:10]};
          if (ir[15:10]==6'd0)
            tException(`FLT_BT, ipc);
        end
      end
    `RTE:
      begin
				pmStack <= {4'b1010,pmStack[31:4]};
      end
    `OSR2:
      case(funct5)
      `REX:
        epc[crs] <= next_epc;
      `MVMAP:
        if (Rs1 != 5'd0)
          wrpagemap <= 1'b1;
      `MVCI:  wr_ci_tbl <= TRUE;
      default:  ;
      endcase
    `POP:
      begin
        casez(ir[14:8])
        7'b00?????: wrirf <= TRUE;
        7'b01?????: wrirf <= TRUE;
        7'b10?????: wrirf <= TRUE;
        7'b110000?: wrra <= TRUE;
        7'b110001?: wrca <= TRUE;
        7'b11100??: begin Cd <= ir[9:8]; wrcrf <= 1'b1; end
        7'b1111101: wrcrf32 <= TRUE;
        default:  ;
        endcase
        Rd <= ir[12:8];  // This got reset to SP above.
      end
    endcase
		instret <= instret + 2'd1;
    goto (IFETCH1);
  end
endcase
end

task tEA;
begin
  if (MUserMode && d_st && !ea_acr[1])
    tException(32'h80000032,ipc);
  else if (MUserMode && d_ld && !ea_acr[2])
    tException(32'h80000033,ipc);
	if (!MUserMode || ea[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= ea;
	else
		ladr <= ea[AWID-4:0] + {sregfile[segsel][AWID-1:4],`SEG_SHIFT};
end
endtask

task tPC;
begin
  if (UserMode & !pc_acr[0])
    tException(32'h80000002,pc);
	if (!UserMode || pc[AWID-1:24]=={AWID-24{1'b1}})
		ladr <= pc;
	else
		ladr <= pc[AWID-2:0] + {sregfile[pc[AWID-1:AWID-4]][AWID-1:4],`SEG_SHIFT};
end
endtask

task tPMAEA;
begin
  if (keyViolation && omode == 3'd0)
		tException(32'h80000031,ipc);
  // PMA Check
  for (n = 0; n < 8; n = n + 1)
    if (adr_o[31:4] >= PMA_LB[n] && adr_o[31:4] <= PMA_UB[n]) begin
      if ((d_st && !PMA_AT[n][1]) || (d_ld && !PMA_AT[n][2]))
        tException(32'h8000003D,ipc);
    end
end
endtask

task tPMAPC;
begin
  // PMA Check
  // Abort cycle that has already started.
  for (n = 0; n < 8; n = n + 1)
    if (adr_o[31:4] >= PMA_LB[n] && adr_o[31:4] <= PMA_UB[n]) begin
      if (!PMA_AT[n][0]) begin
        tException(32'h8000003D,ipc);
        cyc_o <= LOW;
    		stb_o <= LOW;
    		vpa_o <= LOW;
    		sel_o <= 4'h0;
    	end
    end
end
endtask

task setbool;
input bool;
begin
  crres[0] <= bool;
  crres[1] <= bool;
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool;
  crres[5] <= bool;
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolAnd;
input bool;
begin
  crres[0] <= bool & cd[0];
  crres[1] <= bool & cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool & cd[4];
  crres[5] <= bool & cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOr;
input bool;
begin
  crres[0] <= bool | cd[0];
  crres[1] <= bool | cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= bool | cd[4];
  crres[5] <= bool | cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolAndcm;
input bool;
begin
  crres[0] <= ~bool & cd[0];
  crres[1] <= ~bool & cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= ~bool & cd[4];
  crres[5] <= ~bool & cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setboolOrcm;
input bool;
begin
  crres[0] <= ~bool | cd[0];
  crres[1] <= ~bool | cd[1];
  crres[2] <= 1'b0;
  crres[3] <= 1'b0;
  crres[4] <= ~bool | cd[4];
  crres[5] <= ~bool | cd[5];
  crres[6] <= 1'b0;
  crres[7] <= 1'b0;
end
endtask

task setcr;
input bool;
begin
  case (mop)
  `CMP_CPY: setbool(bool);
  `CMP_AND: setboolAnd(bool);
  `CMP_OR:  setboolOr(bool);
  `CMP_ANDCM: setboolAndcm(bool);
  `CMP_ORCM:  setboolOrcm(bool);
  default:  ;
  endcase
end
endtask

task tException;
input [31:0] cse;
input [31:0] tpc;
begin
	pc <= tvec[3'd5] + {omode,6'h00};
	epc[5'd31] <= tpc;
	pmStack <= {pmStack[27:0],3'b101,1'b0};
	cause[3'd5] <= cse;
	illegal_insn <= 1'b0;
	instret <= instret + 2'd1;
  rprv <= 5'h0;
  Rdx1 <= 5'd31;
  Rs1x1 <= 5'd31;
  Rs2x1 <= 5'd31;
  Rs3x1 <= 5'd31;
  rsStack <= {rsStack[24:0],5'd31};
  $display("**********************");
  $display("** Exception: %d    **", cse);
  $display("**********************");
	goto (IFETCH1);
end
endtask

task goto;
input [5:0] nst;
begin
  state <= nst;
end
endtask

endmodule
