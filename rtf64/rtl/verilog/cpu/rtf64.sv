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

`define BRK   8'h00
`define R2    8'h02
`define R3    8'h03
`define ADD   8'h04
`define SUB   8'h05
`define SUBF  8'h05
`define MUL   8'h06
`define CMP   8'h07
`define CMP_CPY   3'd0
`define CMP_AND   3'd1
`define CMP_OR    3'd2
`define CMP_ANDCM 3'd3
`define CMP_ORCM  3'd4
`define AND   8'h08
`define OR    8'h09
`define EOR   8'h0A
`define BIT   8'h0B
`define MINR3 4'h0
`define MAXR3 4'h1
`define MAJR3 4'h2
`define MUXR3 4'h3
`define ADDR3 4'h4
`define SUBR3 4'h5
`define ANDR3 4'h8
`define ORR3  4'h9
`define EORR3 4'hA
`define NANDR2  6'h00
`define NORR2   6'h01
`define ENORR2  6'h02
`define BMMR2   6'h03
`define MULR2   6'h06
`define CMPR2   6'h07
`define ANDR2   6'h08
`define ORR2    6'h09
`define EORR2   6'h0A
`define BITR2   6'h0B
`define MULUR2  6'h0E
`define DIVR2   6'h10
`define DIVUR2  6'h11
`define PERMR2  6'h17
`define PTRDIFR2  6'h18
`define JSR   8'h20
`define JMP   8'h21
`define RTS   8'h24
`define BEQ   8'h28
`define BNE   8'h29
`define BMI   8'h2A
`define BPL   8'h2B
`define BLE   8'h2C
`define BGT   8'h2D
`define BVS   8'h2E
`define BVC   8'h2F
`define BOD   8'h30
`define BCS   8'h32
`define BCC   8'h33
`define BLTU  8'h32
`define BGEU  8'h33
`define BLEU  8'h34
`define BGTU  8'h35
`define BPS   8'h36
`define LUI   8'b010000??
`define LMI   8'b010001??
`define AUIPC 8'b010010??

module rtf64(rst_i, clk_i, nmi_i, irq_i, cyc_o, stb_o, ack_i, we_o, adr_o, dat_i, dat_o);
input rst_i;
input clk_i;
input nmi_i;
input irq_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [5:0] state;

reg [31:0] pc, ipc, ra0, ra1;
reg illegal_insn;
reg [31:0] ir;
wire [7:0] opcode = ir[7:0];
wire [2:0] mop = ir[12:10];
reg [4:0] Rd;
wire [1:0] Cd = ir[9:8];
wire [4:0] Rs1 = ir[17:13];
wire [4:0] Rs2 = ir[22:18];
wire [4:0] Rd3 = ir[27:23];
reg [4:0] Rdx, Rs1x, Rs2x, Rs3x;
reg [4:0] Rdx1, Rs1x1, Rs2x1, Rs3x1;
wire [63:0] irfoRs1, irfoRs2, irfoRs3, irfoRd;
reg [63:0] ia,ib,ic,id;
reg wrirf;

// It takes 6 block rams to get triple output ports with 32 sets of 32 regs.

regfile64 uirfRs1 (
  .clka(clk_g),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrirf),      // input wire [0 : 0] wea
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
  .wea(wrirf),      // input wire [0 : 0] wea
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
  .wea(wrirf),      // input wire [0 : 0] wea
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

reg [7:0] cregfile [0:127];
reg [31:0] sregfile [0:15];
wire [64:0] difi = ia - imm;
wire [64:0] difr = ia - ib;

always @(posedge clk_g)
  if (state==WRITEBACK && wrcrf)
    cregfile[{Rdx,Cd}] <= res[7:0];
wire [7:0] cd = cregfile[{Rdx,Cd}];

// CSRs
reg [31:0] mstatus;
reg [7:0] mcause;
wire mprv = mstatus[17];
reg [31:0] instret;
reg [31:0] mepc [0:31];
reg [31:0] pmStack;
reg [31:0] rsStack;
reg [4:0] rprv;
reg [4:0] ASID;

reg [31:0] ladr;
reg wrpgmap;
wire [16:0] pagemap_ndx = {ASID,ladr[25:14]};

PagemapRam upageram (
  .clka(clk_g),   // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wrpgmap),      // input wire [0 : 0] wea
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

always @(posedge clk_g)
if (rst_i) begin
end
else begin

if (MachineMode)
	adr_o <= ladr;
else begin
	if (ladr[31:24]==8'hFF)
		adr_o <= ladr;
	else
		adr_o <= {pagemapo & 9'h1FF,ladr[9:0]};
end

case (state)
// It takes two clocks to read the pagemap ram, this is after the linear
// address is set, which also takes a clock cycle.
IFETCH1:
  begin
    wrirf <= 1'b0;
    wrcrf <= 1'b0;
	  Rdx <= Rdx1;
	  Rs1x <= Rs1x1;
	  Rs2x <= Rs2x1;
	  Rs3x <= Rs3x1;
		illegal_insn <= 1'b1;
		ipc <= pc;
		wrirf <= 1'b0;
		wrfrf <= 1'b0;
    tPC();
		if (nmif) begin
			nmif <= 1'b0;
			tException(32'h800000FE,pc,4'd14);
			pc <= mtvec + 8'hFC;
		end
 		else if (irq_i & ie & ~mloco) begin
			tException(32'h80000000|cause_i,pc,5'd30);
		end
		else if (mip[7] & mie[7] & ie & ~mloco) begin
			tException(32'h80000001,pc,5'd30);  // timer IRQ
		end
		else if (mip[3] & mie[3] & ie & ~mloco) begin
			tException(32'h80000002, pc, 5'd30); // software IRQ
		end
		else if (uip[0] & gcie[ASID] & ie & ~mloco) begin
			tException(32'h80000003, pc, 5'd30); // garbage collect IRQ
			uip[0] <= 1'b0;
		end
		else
			pc <= pc + 3'd4;
    goto (IFETCH2);    
  end
IFETCH2:
  begin
    goto (IFETCH3);
  end
IFETCH3:
  begin
    cyc_o <= HIGH;
		stb_o <= HIGH;
		vpa_o <= HIGH;
		sel_o <= 4'hF;
		goto (IFETCH4);
  end
IFETCH4:
  if (ack_i) begin
    cyc_o <= LOW;
    stb_o <= LOW;
    vpa_o <= LOW;
    sel_o <= 4'h0;
    ir <= dat_i;
    goto (DECODE);
  end
DECODE:
  begin
    goto (REGFETCH);
    Rd <= 5'd0;
    Cd <= ir[9:8];
    casez(opcode)
    `R2:
      case(ir[31:26])
      `NANDR2:begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `NORR2: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `ENORR2:begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `MULR2: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `CMPR2: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
      `MULUR2:begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `DIVR2: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `DIVUR2:begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      endcase
    `R3:
      case(ir[31:28])
      `MINR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `MAXR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `MAJR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `MUXR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `ADDR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `SUBR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `ANDR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `ORR3:  begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `EORR3: begin Rd <= ir[12:8]; wrirf <= 1'b1; illegal_insn <= 1'b0; end
      `BITR3: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; illegal_insn <= 1'b0; end
      endcase
    `ADD: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `SUBF:begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `MUL: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `CMP: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `AND: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b1}},ir[31:18]}; illegal_insn <= 1'b0; end
    `OR:  begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b0}},ir[31:18]}; illegal_insn <= 1'b0; end
    `EOR: begin Rd <= ir[12:8]; wrirf <= 1'b1; imm <= {{50{1'b0}},ir[31:18]}; illegal_insn <= 1'b0; end
    `BIT: begin Cd <= ir[ 9:8]; wrcrf <= 1'b1; imm <= {{50{ir[31]}},ir[31:18]}; illegal_insn <= 1'b0; end
    `LUI: begin Rd <= ir[8] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    `LMI: begin Rd <= ir[8] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    `AUIPC: begin Rd <= ir[9] ? 5'd1 : 5'd2; wrirf <= 1'b1; illegal_insn <= 1'b0; end
    // Flow Control
    `JMP: begin pc <= {pc[63:24],ir[31:10],2'b00}; goto (IFETCH1); illegal_insn <= 1'b0; end
    `JSR:
      begin
        // Assume instruction will not crap out and write ra0,ra1 here rather
        // than at WRITEBACK as the pc value is needed.
        if (ir[8])
          ra1 <= ipc;
        else
          ra0 <= ipc;
        wrirf <= 1'b1;
        pc <= {ipc[63:24],ir[31:10],2'b00};
        res <= ipc;
        illegal_insn <= 1'b0;
      end
    `RTS:
      begin
        Rd = 5'd31;
        wrirf <= 1'b1;
        imm <= {{50{ir[31]}},ir[31:18]};
        illegal_insn <= 1'b0;
        pc <= (ir[8] ? ra1 : ra0) + {ir[12:9],2'b00};
      end
    `BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BCS,`BCC,`BLE,`BGT,`BLEU,`BGTU,`BOD,`BPS:
      illegal_insn <= 1'b0;
    endcase
  end
REGFETCH:
  begin
    goto (EXECUTE);
    ia <= Rs1==5'd0 ? 64'd0 : irfoRs1;
    ib <= Rs2==5'd0 ? 64'd0 : irfoRs2;
    ic <= Rs3==5'd0 ? 64'd0 : irfoRs3;
    id <= Rd==5'd0 ? 64'd0 : irfoRd;
  end
EXECUTE:
  begin
    goto (WRITEBACK);
    res <= 64'd0;
    casez(opcode)
    `R2:
      case(ir[31:26])
      `NANDR2:res <= ~(ia & ib);
      `NORR2: res <= ~(ia | ib);
      `ENORR2:res <= ~(ia ^ ib);
      `MULR2: res <= $signed(ia) * $signed(ib);
      `CMPR2:
        begin
          case(mop)
          `CMP_CPY:
            begin
              res[0] <= difr[64];
              res[1] <= ~|difr[63:0];
              res[2] <= 1'b0;
              res[3] <= 1'b0;
              res[4] <= ^difr[63:0];
              res[5] <= difr[0];
              res[6] <= difr[64]^difr[63];
              res[7] <= difr[63];
            end
          `CMP_AND:
            begin
              res[0] <= cd[0] & difr[64];
              res[1] <= cd[1] & ~|difr[63:0];
              res[2] <= 1'b0;
              res[3] <= 1'b0;
              res[4] <= cd[4] & ^difr[63:0];
              res[5] <= cd[5] & difr[0];
              res[6] <= cd[6] & difr[64]^difr[63];
              res[7] <= cd[7] & difr[63];
            end
          `CMP_OR:
            begin
              res[0] <= cd[0] | difr[64];
              res[1] <= cd[1] | ~|difr[63:0];
              res[2] <= 1'b0;
              res[3] <= 1'b0;
              res[4] <= cd[4] | ^difr[63:0];
              res[5] <= cd[5] | difr[0];
              res[6] <= cd[6] | difr[64]^difr[63];
              res[7] <= cd[7] | difr[63];
            end
          `CMP_ANDCM:
            begin
              res[0] <= cd[0] & ~difr[64];
              res[1] <= cd[1] & |difr[63:0];
              res[2] <= 1'b0;
              res[3] <= 1'b0;
              res[4] <= cd[4] & ~^difr[63:0];
              res[5] <= cd[5] & ~difr[0];
              res[6] <= cd[6] & ~(difr[64]^difr[63]);
              res[7] <= cd[7] & ~difr[63];
            end
          `CMP_ORCM:
            begin
              res[0] <= cd[0] | ~difr[64];
              res[1] <= cd[1] | |difr[63:0];
              res[2] <= 1'b0;
              res[3] <= 1'b0;
              res[4] <= cd[4] | ~^difr[63:0];
              res[5] <= cd[5] | ~difr[0];
              res[6] <= cd[6] | ~(difr[64]^difr[63]);
              res[7] <= cd[7] | ~difr[63];
            end
          default:  res[7:0] <= 8'h00;
          endcase
        end
      `MULUR2: res <= ia * ib;
      endcase
    `R3:
      case(ir[31:28])
      `MINR3:
        if (ia < ib && ia < ic)
          res <= ia;
        else if (ib < ic)
          res <= ib;
        else
          res <= ic;      
      `MAXR3:
        if (ia > ib && ia > ic)
          res <= ia;
        else if (ib > ic)
          res <= ib;
        else
          res <= ic;      
      `MAJR3: res <= (ia & ib) | (ia & ic) | (ib & ic);
      `MUXR3:
        for (n = 0; n < 64; n = n + 1)
          res[n] <= ia[n] ? ib[n] : ic[n];
      `ADDR3: res <= ia + ib + ic;
      `SUBR3: res <= ia - ib - ic;
      `ANDR3: res <= ia & ib & ic;
      `ORR3:  res <= ia | ib | ic;
      `EORR3: res <= ia ^ ib ^ ic;
      endcase
    `ADD: res <= ia + imm;
    `SUBF: res <= imm - ia;
    `MUL: res <= $signed(ia) * $signed(imm);
    `CMP:
      begin
        case(mop)
        `CMP_CPY:
          begin
            res[0] <= difi[64];
            res[1] <= ~|difi[63:0];
            res[2] <= 1'b0;
            res[3] <= 1'b0;
            res[4] <= ^difi[63:0];
            res[5] <= difi[0];
            res[6] <= difi[64]^difi[63];
            res[7] <= difi[63];
          end
        `CMP_AND:
          begin
            res[0] <= cd[0] & difi[64];
            res[1] <= cd[1] & ~|difi[63:0];
            res[2] <= 1'b0;
            res[3] <= 1'b0;
            res[4] <= cd[4] & ^difi[63:0];
            res[5] <= cd[5] & difi[0];
            res[6] <= cd[6] & difi[64]^difi[63];
            res[7] <= cd[7] & difi[63];
          end
        `CMP_OR:
          begin
            res[0] <= cd[0] | difi[64];
            res[1] <= cd[1] | ~|difi[63:0];
            res[2] <= 1'b0;
            res[3] <= 1'b0;
            res[4] <= cd[4] | ^difi[63:0];
            res[5] <= cd[5] | difi[0];
            res[6] <= cd[6] | difi[64]^difi[63];
            res[7] <= cd[7] | difi[63];
          end
        `CMP_ANDCM:
          begin
            res[0] <= cd[0] & ~difi[64];
            res[1] <= cd[1] & |difi[63:0];
            res[2] <= 1'b0;
            res[3] <= 1'b0;
            res[4] <= cd[4] & ~^difi[63:0];
            res[5] <= cd[5] & ~difi[0];
            res[6] <= cd[6] & ~(difi[64]^difi[63]);
            res[7] <= cd[7] & ~difi[63];
          end
        `CMP_ORCM:
          begin
            res[0] <= cd[0] | ~difi[64];
            res[1] <= cd[1] | |difi[63:0];
            res[2] <= 1'b0;
            res[3] <= 1'b0;
            res[4] <= cd[4] | ~^difi[63:0];
            res[5] <= cd[5] | ~difi[0];
            res[6] <= cd[6] | ~(difi[64]^difi[63]);
            res[7] <= cd[7] | ~difi[63];
          end
        default:  res[7:0] <= 8'h00;
        endcase
      end
    `AND: res <= ia & imm;
    `OR:  res <= ia | imm;
    `EOR: res <= ia ^ imm;
    `LUI: res <= {ir[31:9],ir[1:0],id[38:0]};
    `LMI: res <= {{25{ir[31]}},ir[31:9],ir[1:0],14'd0};
    `AUIPC: res <= ipc + {{25{ir[31]}},ir[31:9],ir[1:0],14'd0};
    `RTS: res <= ia + imm;
    `BEQ: begin if ( cd[1]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BNE: begin if (~cd[1]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BMI: begin if ( cd[7]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BPL: begin if (~cd[7]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BVS: begin if ( cd[6]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BVC: begin if (~cd[6]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BCS: begin if ( cd[0]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BCC: begin if (~cd[0]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BLE: begin if ( cd[1] | cd[7]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BGT: begin if (~(cd[1] | cd[7])) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BLEU: begin if ( cd[1] | cd[0]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BGTU: begin if (~(cd[1] | cd[0])) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BOD: begin if ( cd[5]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    `BPS: begin if ( cd[4]) pc <= {ipc[63:24],ir[31:10],2'b00}; goto (IFETCH1); end
    endcase
  end
WRITEBACK:
  begin
    goto (IFETCH);
  end
endcase
end

task tEA;
begin
	if (MMachineMode || ea[WID-1:24]=={WID-24{1'b1}})
		ladr <= ea;
	else
		ladr <= ea[WID-4:0] + {sregfile[segsel][WID-1:4],10'd0};
end
endtask

task tPC;
begin
	if (MachineMode || pc[WID-1:24]=={WID-24{1'b1}})
		ladr <= pc;
	else
		ladr <= pc[WID-2:0] + {sregfile[{2'b11,pc[WID-1:WID-2]}][WID-1:4],10'd0};
end
endtask

task tException;
input [31:0] cse;
input [31:0] tpc;
input [4:0] rs;
begin
	pc <= mtvec + {pmStack[3:1],6'h00};
	mepc[rs] <= tpc;
	pmStack <= {pmStack[27:0],3'b101,1'b0};
	mcause <= cse;
	illegal_insn <= 1'b0;
	instret <= instret + 2'd1;
  rprv <= 5'h0;
  Rdx1 <= rs;
  Rs1x1 <= rs;
  Rs2x1 <= rs;
  Rs3x1 <= rs;
  rsStack <= {rsStack[24:0],rs};
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
