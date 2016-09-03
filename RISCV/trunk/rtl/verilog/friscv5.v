`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	friscv5.v
//  - RISC-V ISA compatible
//  - with mini-icache
//		
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
//
// ============================================================================
//
`define TRUE    1'b1
`define FALSE   1'b0

`define LUI		7'b0110111
`define AUIPC	7'b0010111
`define JAL		7'b1101111
`define JALR	7'b1100111
`define Bcc		7'b1100011
`define BEQ			3'd0
`define BNE			3'd1
`define BLT			3'd4
`define BGE			3'd5
`define BLTU		3'd6
`define BGEU		3'd7
`define Lx		7'b0000011
`define LB			3'd0
`define LH			3'd1
`define LW			3'd2
`define LBU			3'd4
`define LHU			3'd5
`define Sx		7'b0100011
`define SB			3'd0
`define SH			3'd1
`define SW			3'd2
`define ALU1	7'b0010011
`define ADDI		3'd0
`define SLI			3'd1
`define SLTI		3'd2
`define SLTIU		3'd3
`define XORI		3'd4
`define SRI			3'd5
`define ORI			3'd6
`define ANDI		3'd7
`define RR		7'b0110011
`define GRP0		3'd0
`define GRP1		3'd1
`define GRP2		3'd2
`define GRP3		3'd3
`define XOR			3'd4
`define SRAL		3'd5
`define OR			3'd6
`define AND			3'd7
`define FENCE	7'b0001111
`define SYSTEM	7'b1110011
`define SCALL		3'd0
`define RDCTI		3'd2
`define O64     7'h3F
`define ECALL   32'b00000000_00000000_00000000_01110011
`define ERET    32'b00010000_00000000_00000000_01110011
`define WFI     32'b00010000_00100000_00000000_01110011

`define NOPINSN {12'b0,5'b0,3'b000,5'b0,7'b0010011}


module friscv5(mhartid, rst_i, clk_i, tm_clk_i, irq_i, ivec_i, cyc_o, stb_o, ack_i, we_o, sel_o, adr_o, dat_i, dat_o, irdy_i, iadr_o, idat_i);
parameter PCMSB = 43;
input [31:0] mhartid;
input rst_i;
input clk_i;
input tm_clk_i;         // At least 10MHz - 16277216 MHz gives 1s intervals
input irq_i;
input [8:0] ivec_i;
output reg cyc_o;
output reg stb_o;
input ack_i;
output reg we_o;
output reg [3:0] sel_o;
output reg [43:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
input irdy_i;
output reg [43:0] iadr_o;
input [31:0] idat_i;
parameter X32 = 1'b1;
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
parameter STORE1 = 6'd16;
parameter STORE2 = 6'd17;
parameter STORE3 = 6'd18;
parameter STORE4 = 6'd19;
parameter STORE5 = 6'd20;
parameter LOAD_ICACHE = 6'd21;
parameter LOAD_ICACHE2 = 6'd22;
parameter RUN = 6'd23;
parameter byt = 2'd0;
parameter half = 2'd1;
parameter word = 2'd2;

// CSR addresses
parameter MCPUID  = 12'hF00;
parameter MIMPID  = 12'hF01;
parameter MHARTID = 12'hF10;
parameter MSTATUS = 12'h300;
parameter MTVEC   = 12'h301;
parameter MTDELEG = 12'h302;
parameter MIE     = 12'h304;
parameter MTIMECMP  = 12'h321;
parameter MTIME   = 12'h701;
parameter MTIMEH  = 12'h741;
parameter MSCRATCH  = 12'h340;
parameter MEPC    = 12'h341;
parameter MCAUSE  = 12'h342;
parameter MBADADDR = 12'h343;
parameter MIP     = 12'h344;
parameter MBASE   = 12'h380;
parameter MBOUND  = 12'h381;
parameter MIBASE  = 12'h382;
parameter MIBOUND = 12'h383;
parameter MDBASE  = 12'h384;
parameter MDBOUND = 12'h385;
parameter HTIMEW  = 12'hB01;
parameter HTIMEHW = 12'hB81;
parameter MTOHOST = 12'h780;
parameter MFROMHOST = 12'h781;
parameter MSLL    = 12'h79E;
parameter MSLU    = 12'h79F;
parameter RDCYCLE = 12'hC00;
parameter RDCYCLEH= 12'hC80;
parameter RDTIME  = 12'hC01;
parameter RDTIMEH = 12'hC81;
parameter RDINSTRET=12'hC02;
parameter RDINSTRETH=12'hC82;

parameter EX_STACK  = {9'd504,4'hF};
parameter EX_BOUNDS = {9'd500,4'hF};

wire clk = clk_i;
reg [PCMSB:0] pc;
reg [127:0] insn;
reg [1:0] PRV = 2'b11;
reg [1:0] PRV1;
reg [1:0] PRV2;
reg [1:0] PRV3;
reg IE,IE1,IE2,IE3;
reg [4:0] VM = 5'h00;
reg MPRV;
reg [1:0] FS = 2'b00;
reg [1:0] XS = 2'b00;
reg SD = 1'b0;
wire [31:0] mstatus;
assign mstatus[31] = SD;
assign mstatus[30:22] = 9'd0;
assign mstatus[21:17] = VM;
assign mstatus[16] = MPRV;
assign mstatus[15:14] = XS;
assign mstatus[13:12] = FS;
assign mstatus[11:10] = PRV3;
assign mstatus[9] = IE3;
assign mstatus[8:7] = PRV2;
assign mstatus[6] = IE2;
assign mstatus[5:4] = PRV1;
assign mstatus[3] = IE1;
assign mstatus[2:1] = PRV;
assign mstatus[0] = IE;
reg [31:0] mtvec;
reg [31:0] mtdeleg = 32'd0;
reg MTIE;
reg HTIE = 1'b0;
reg STIE = 1'b0;
reg MSIE;
reg HSIE = 1'b0;
reg SSIE = 1'b0;
reg MTIP;
reg HTIP = 1'b0;
reg STIP = 1'b0;
reg MSIP;
reg HSIP = 1'b0;
reg SSIP = 1'b0;
wire [31:0] mip;
assign mip[31:8] = 24'd0;
assign mip[7] = MTIP;
assign mip[6] = HTIP;
assign mip[5] = STIP;
assign mip[4] = 1'b0;
assign mip[3] = MSIP;
assign mip[2] = HSIP;
assign mip[1] = SSIP;
assign mip[0] = 1'b0;
wire [31:0] mie;
assign mie[31:8] = 24'd0;
assign mie[7] = MTIE;
assign mie[6] = HTIE;
assign mie[5] = STIE;
assign mie[4] = 1'b0;
assign mie[3] = MSIE;
assign mie[2] = HSIE;
assign mie[1] = SSIE;
assign mie[0] = 1'b0;
reg [31:0] mtimecmp;
reg [31:0] mscratch;
reg [31:0] mepc;
reg [31:0] mecs,mecsl;
reg [31:0] mcause;
reg [31:0] mbadaddr;
reg [63:0] rdcycle;
reg [63:0] rdinstret;
reg [63:0] rdtime,rdtimes;
reg [7:0] mtimecnt;
reg [63:0] mtime,mtimes,mtime_latch;
wire mtime_set = !mtimecnt[7];
reg RFcnt,EXcnt,WBcnt;
reg [5:0] state;
reg [31:0] status;
reg [PCMSB:0] evec;
reg [PCMSB:0] epc;
reg [4:0] dcause,xcause,wcause,cause;
reg [31:0] k0,k1;
reg [31:0] tohost;
reg [31:0] fromhost;
reg [PCMSB:0] dpc,xpc;
reg [31:0] regfile [31:0];
reg [31:0] sll,slu;
reg [127:0] ir,xir;
reg [31:0] x1ir,wir;
wire [6:0] opcode = ir[6:0];
wire [6:0] iopcode = insn[6:0];
wire [2:0] funct3 = ir[14:12];
wire [6:0] funct7 = ir[31:25];
wire [6:0] opcode2 = ir[38:32];
reg [6:0] xopcode;
reg [2:0] xfunct3,mfunct3;
reg [6:0] xfunct7;
wire iisLuiz = opcode==`LUI && ir[11:7]==5'd0;
wire xisLuiz = xopcode==`LUI && xir[11:7]==5'd0;
wire [4:0] Ra = ir[19:15];
wire [4:0] Rb = ir[24:20];
reg [4:0] xRa,mRa,wRa;
reg [4:0] xRt,mRt,wRt;
reg [31:0] rfoa,rfob;

reg [31:0] count;
reg [31:0] compare;
// PC increment flags
reg ipc2,ipc4,ipc6,ipc8,ipc16;

// Status register, many of these fields are fixed for this implementation
reg SR_ET;
reg SR_EF = 1'b0;   // No floating point
reg SR_PS;
reg SR_S;
reg SR_U64 = 1'b0;  // 32 bit only code
reg SR_S64 = 1'b0;
reg SR_VM = 1'b0;   // no virtual memory
reg SR_IM = 8'h00;
wire [31:0] SR_ = {8'h00,SR_IM,7'h00,SR_VM,SR_S64,SR_U64,SR_S,SR_PS,2'b0,SR_EF,SR_ET};

reg ex_done;
reg [31:0] a,b,imm,xb,xa,wa;
reg [31:0] imm2;    // 2nd immediate for BccI
reg ii32,di32;  // use next word as immediate value
reg [31:0] res,xres,mres,wres,lres;
reg [43:0] ea;
reg [1:0] ld_size, st_size;
reg [31:0] insncnt;
wire [63:0] produ = a * b;
wire [63:0] prods = $signed(a) * $signed(b);
wire [63:0] prodsu = $signed(a) * b;
wire [31:0] va = a + imm;
wire xisLd = xopcode==`Lx;
wire xisSt = xopcode==`Sx;
reg xis64;

always @*
case(Ra)
5'd0:	rfoa <= 32'd0;
xRt:	rfoa <= res;
//wRt:	rfoa <= wres;
default:	rfoa <= regfile[Ra];
endcase

always @*
case(Rb)
5'd0:	rfob <= 32'd0;
xRt:	rfob <= res;
//wRt:	rfob <= wres;
default:	rfob <= regfile[Rb];
endcase

//---------------------------------------------------------------------------
// I-Cache
// This 64-line 4 way set associative cache is used mainly to allow access
// to 16 and 64 bit instructions while the external bus is 32 bit.
// On reset the cache is loaded with NOP's and the tag memory is loaded
// with $FFFFFC00. There should not be any valid instructions placed in the
// the area $FFFFFC00 to $FFFFFFFF
//---------------------------------------------------------------------------
wire [31:0] pcp16 = pc + 32'h0010;
wire [22:0] ic_lfsr;

lfsr #(23,23'h00ACE1) u1
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(state==RUN),
    .cyc(1'b0),
    .o(ic_lfsr)
);

wire [1:0] ic_whichSet = ic_lfsr[1:0];
wire ihit1,ihit2;
wire hita,hitb,hitc,hitd;
reg [1:0] icmf;     // miss flags
reg isICacheReset;
reg isICacheLoad;
reg [127:0] cache_mem0 [0:63];
reg [127:0] cache_mem1 [0:63];
reg [127:0] cache_mem2 [0:63];
reg [127:0] cache_mem3 [0:63];
reg [31:10] tag_mem0 [0:63];
reg [31:10] tag_mem1 [0:63];
reg [31:10] tag_mem2 [0:63];
reg [31:10] tag_mem3 [0:63];
always @(posedge clk_i)
  if (isICacheReset) begin
    case(iadr_o[3:2])
    2'd0: begin
            cache_mem0[iadr_o[9:4]][31:0] <= `NOPINSN;
            cache_mem1[iadr_o[9:4]][31:0] <= `NOPINSN;
            cache_mem2[iadr_o[9:4]][31:0] <= `NOPINSN;
            cache_mem3[iadr_o[9:4]][31:0] <= `NOPINSN;
          end
    2'd1: begin
            cache_mem0[iadr_o[9:4]][63:32] <= `NOPINSN;
            cache_mem1[iadr_o[9:4]][63:32] <= `NOPINSN;
            cache_mem2[iadr_o[9:4]][63:32] <= `NOPINSN;
            cache_mem3[iadr_o[9:4]][63:32] <= `NOPINSN;
          end
    2'd2: begin
            cache_mem0[iadr_o[9:4]][95:64] <= `NOPINSN;
            cache_mem1[iadr_o[9:4]][95:64] <= `NOPINSN;
            cache_mem2[iadr_o[9:4]][95:64] <= `NOPINSN;
            cache_mem3[iadr_o[9:4]][95:64] <= `NOPINSN;
          end
    2'd3: begin
            cache_mem0[iadr_o[9:4]][127:96] <= `NOPINSN;
            cache_mem1[iadr_o[9:4]][127:96] <= `NOPINSN;
            cache_mem2[iadr_o[9:4]][127:96] <= `NOPINSN;
            cache_mem3[iadr_o[9:4]][127:96] <= `NOPINSN;
          end
    endcase
  end
  else begin
    if (isICacheLoad) begin
      case({ic_whichSet,iadr_o[3:2]})
      4'd0: cache_mem0[iadr_o[10:4]][31:0] <= idat_i;
      4'd1: cache_mem0[iadr_o[10:4]][63:32] <= idat_i;
      4'd2: cache_mem0[iadr_o[10:4]][95:64] <= idat_i;
      4'd3: cache_mem0[iadr_o[10:4]][127:96] <= idat_i;
      4'd4: cache_mem1[iadr_o[10:4]][31:0] <= idat_i;
      4'd5: cache_mem1[iadr_o[10:4]][63:32] <= idat_i;
      4'd6: cache_mem1[iadr_o[10:4]][95:64] <= idat_i;
      4'd7: cache_mem1[iadr_o[10:4]][127:96] <= idat_i;
      4'd8: cache_mem2[iadr_o[10:4]][31:0] <= idat_i;
      4'd9: cache_mem2[iadr_o[10:4]][63:32] <= idat_i;
      4'd10: cache_mem2[iadr_o[10:4]][95:64] <= idat_i;
      4'd11: cache_mem2[iadr_o[10:4]][127:96] <= idat_i;
      4'd12: cache_mem3[iadr_o[10:4]][31:0] <= idat_i;
      4'd13: cache_mem3[iadr_o[10:4]][63:32] <= idat_i;
      4'd14: cache_mem3[iadr_o[10:4]][95:64] <= idat_i;
      4'd15: cache_mem3[iadr_o[10:4]][127:96] <= idat_i;
      endcase
    end
  end
wire [127:0] co01 = cache_mem0[pc[9:4]];
wire [127:0] co02 = cache_mem0[pcp16[9:4]];
wire [127:0] co11 = cache_mem1[pc[9:4]];
wire [127:0] co12 = cache_mem1[pcp16[9:4]];
wire [127:0] co21 = cache_mem2[pc[9:4]];
wire [127:0] co22 = cache_mem2[pcp16[9:4]];
wire [127:0] co31 = cache_mem3[pc[9:4]];
wire [127:0] co32 = cache_mem3[pcp16[9:4]];
wire [127:0] co1 = hita ? co01 : hitb ? co11 : hitc ? co21 : hitd ? co31 : 32'h0013;    // NOP on a miss
wire [127:0] co2 = hita ? co02 : hitb ? co12 : hitc ? co22 : hitd ? co32 : 32'h0013;    // NOP on a miss
always @(pc or co1 or co2)
case(pc[3:1])
3'd0: insn = co1;
3'd1: insn = {co2[15:0],co1[127:16]};
3'd2: insn = {co2[31:0],co1[127:32]};
3'd3: insn = {co2[47:0],co1[127:48]};
3'd4: insn = {co2[63:0],co1[127:64]};
3'd5: insn = {co2[79:0],co1[127:80]};
3'd6: insn = {co2[95:0],co1[127:96]};
3'd7: insn = {co2[111:0],co1[127:112]};
endcase 

always @(posedge clk_i)
  if (isICacheReset) begin
    tag_mem0[iadr_o[9:4]] <= {31-9{1'b1}};
    tag_mem1[iadr_o[9:4]] <= {31-9{1'b1}};
    tag_mem2[iadr_o[9:4]] <= {31-9{1'b1}};
    tag_mem3[iadr_o[9:4]] <= {31-9{1'b1}};
  end
  else begin
    if (isICacheLoad && iadr_o[3:2]==2'b11) begin
        case(ic_whichSet)
        2'd0:   tag_mem0[iadr_o[9:4]] <= iadr_o[31:10];
        2'd1:   tag_mem1[iadr_o[9:4]] <= iadr_o[31:10];
        2'd2:   tag_mem2[iadr_o[9:4]] <= iadr_o[31:10];
        2'd3:   tag_mem3[iadr_o[9:4]] <= iadr_o[31:10];
        endcase
    end
  end
assign ihit01 = pc[31:10]==tag_mem0[pc[9:4]];
assign ihit02 = pcp16[31:10]==tag_mem0[pcp16[9:4]];
assign ihit11 = pc[31:10]==tag_mem1[pc[9:4]];
assign ihit12 = pcp16[31:10]==tag_mem1[pcp16[9:4]];
assign ihit21 = pc[31:10]==tag_mem2[pc[9:4]];
assign ihit22 = pcp16[31:10]==tag_mem2[pcp16[9:4]];
assign ihit31 = pc[31:10]==tag_mem3[pc[9:4]];
assign ihit32 = pcp16[31:10]==tag_mem3[pcp16[9:4]];
assign hita = (ihit01 & ihit02) || (ihit01 && pc[3:0]==4'h0);
assign hitb = (ihit11 & ihit12) || (ihit11 && pc[3:0]==4'h0);
assign hitc = (ihit21 & ihit22) || (ihit21 && pc[3:0]==4'h0);
assign hitd = (ihit31 & ihit32) || (ihit31 && pc[3:0]==4'h0);
wire ihit = hita|hitb|hitc|hitd;

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
wire advanceEX = 1'b1;
wire advanceWB = advanceEX;
wire advanceRF = !((xisLd || xisSt)&&ex_done==`TRUE);
wire advanceIF = advanceRF & ihit;

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
always @*
case(xopcode)
`LUI:	res <= imm;
`AUIPC:	res <= {xpc[31:12] + imm[31:12],12'h000};
`JAL:	res <= xpc + 32'd4;
`JALR:	res <= xpc + 32'd4;
`ALU1:
		case(xfunct3)
		`ADDI:	res <= a + imm;
		`SLTI:	res <= $signed(a) < $signed(imm);
		`SLTIU:	res <= a < imm;
		`XORI:	res <= a ^ imm;
		`ORI:	res <= a | imm;
		`ANDI:	res <= a & imm;
		`SLI:
		    case(xir[31:25])
		    7'h00:  res <= a << xir[24:20];
		    default:  ;
		    endcase
		`SRI:
			if ((xir[31:25]==7'b0100000) && a[31])
				res <= (a >> xir[24:20]) | ~(32'hFFFFFFFF >> xir[24:20]);
			else
				res <= a >> xir[24:20];
    default:    res <= 32'd0;
		endcase
`RR:
		case(xfunct3)
		`GRP0:
		  case(xfunct7)
		  7'b0000000:  res <= a + b;
		  7'b0000001:  res <= prods[31:0];
		  7'b0100000:  res <= a - b;
		  default:    res <= 32'd0;
		  endcase
		`GRP1:
		  case(xfunct7)
		  7'b0000000: res <= a << b[4:0];
		  7'b0000001: res <= prods[63:32];
		  default:    res <= 32'd0;
		  endcase
		`GRP2:
		  case(xfunct7)
		  7'b0000000: res <= $signed(a) < $signed(b); // SLT
		  7'b0000001: res <= prodsu[63:32]; // MULHSU
		  default:    res <= 32'd0;
		  endcase	
		`GRP3:
		  case(xfunct7)	
		  7'b0000000: res <= a < b;         // SLTU
		  7'b0000001: res <= produ[63:32];  // MULHU
		  default:    res <= 32'd0;
		  endcase
		`XOR:		res <= a ^ b;
		`SRAL:
			if (xir[30] & a[31])
				res <= (a >> b[4:0]) | ~(32'hFFFFFFFF >> b[4:0]);
			else
				res <= a >> b[4:0];
		`OR:		res <= a | b;
		`AND:		res <= a & b;
	  default:    res <= 32'd0;
		endcase
`Lx:	res <= lres;
`SYSTEM:
  case(xfunct3)
  3'b000:
    casex(xir[31:20])
    12'b0000_0000_0000: res <= xpc; // ECALL
    12'b0000_0000_0001: res <= xpc; // EBREAK
    default:  res <= xpc;
    endcase
  default:
    case(xir[31:20])
    MCPUID: res <= 32'b100000000; // RV32I
    MIMPID: res <= 32'h8000;      // TBD (0002-7FFE)
    MHARTID:  res <= mhartid;
    MSTATUS:  res <= mstatus;
    MTVEC:  res <= {mtvec[31:2],2'b00};
    MTDELEG:  res <= mtdeleg;
    MIP:  res <= mip;
    MIE:  res <= mie;
    MTIME:  res <= rdtimes[31:0];
    MTIMEH: res <= rdtimes[63:32];
    MTIMECMP: res <= mtimecmp;
    MSCRATCH: res <= mscratch;
    MEPC: res <= mepc;
    MCAUSE: res <= mcause;
    MBADADDR: res <= mbadaddr;
    RDCYCLE: res <= rdcycle[31:0];
    RDCYCLEH: res <= rdcycle[63:32];
    RDTIME: res <= rdtimes[31:0];
    RDTIMEH: res <= rdtimes[63:32];
    RDINSTRET: res <= rdinstret[31:0];
    RDINSTRETH: res <= rdinstret[63:32];
    MSLL: res <= sll;
    MSLU: res <= slu;
    default:  res <= 32'd0;
    endcase
  endcase
default:	res <= 32'd0;
endcase

reg mtime_set2;
always @(posedge tm_clk_i)
if (rst_i) begin
  mtime <= 64'd0;
end
else begin
  mtime_set2 <= mtime_set;
  if (mtime_set & !mtime_set2)
    mtime <= mtime_latch;
  else
    mtime <= mtime + 64'd1;
end

always @(posedge tm_clk_i)
if (rst_i) begin
  rdtime <= 64'd0;
end
else begin
  rdtime <= rdtime + 64'd1;
end

reg tmcmp;
always @(posedge clk)
if (rst_i) begin
  SR_PS <= 1'b1;       // pretend we were in system mode
  SR_S <= 1'b1;        // system mode
  SR_ET <= 1'b0;       // disable traps
  evec <= 32'd0;
  rdcycle <= 64'd0;
	insncnt <= 32'd0;
	pc <= 18'h2000;
	state <= RESET;
	nop_ir();
	nop_xir();
	wb_nack();
	iadr_o <= 18'd0;
	ex_done <= `TRUE;
	MPRV <= 1'b0;
	mtvec <= 32'h0100;
	mtimecnt <= 8'hFF;
  isICacheReset <= TRUE;
  MTIE <= FALSE;
  HTIE <= FALSE;
  STIE <= FALSE;
  MSIE <= FALSE;
  HSIE <= FALSE;
  SSIE <= FALSE;
end
else begin
  rdtimes <= rdtime;    // synchronize rdtime to this domain
  rdcycle <= rdcycle + 64'd1;
  // Post an interrupt pending the first time mtime==mtimecmp
  tmcmp = rdtimes==mtimecmp;
  if (rdtimes==mtimecmp && !tmcmp)
    MTIP <= 1'b1;
  if (mtimecnt != 8'hFF)
    mtimecnt = mtimecnt + 8'd1;
case (state)
RESET:
begin
	iadr_o <= iadr_o + 32'd4;
    if (iadr_o[9:2]==8'hFF) begin
      isICacheReset <= FALSE;
      state <= RUN;
  end
end
RUN:
begin
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // IFETCH stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceIF) begin
        insncnt <= insncnt + 32'd1;
        RFcnt <= 1'b1;
        if (insn[31:0]!=`WFI || |mip) begin
            if (SR_ET && |(mip & mie)) begin
                ir <= `ECALL;
                dcause <= 32'h8000000F |{ivec_i,4'h0}; // interrupt - set MSB
            end
            else begin
                ir <= insn;
                dcause <= 5'd31;  // reserved code
            end
            dpc <= pc;
            // Figure PC increment
            ipc2 = insn[1:0]!=2'b11;
            ipc4 = insn[1:0]==2'b11;
            ipc6 = insn[5:0]==6'b011111;
            ipc8 = insn[6:0]==7'b0111111;
            ipc16 = insn[10:0]==11'b00111111111;
            if (ipc16)
                pc <= pc + 32'd16;
            else if (ipc8)
                pc <= pc + 32'd8;
            else if (ipc6)
                pc <= pc + 32'd6;
            else if (ipc4)
                pc <= pc + 32'd4;
            else
                pc <= pc + 32'd2;
        end
    end
    else begin
        if (!ihit) begin
            icmf <= {ihit1,ihit2};
            next_state(LOAD_ICACHE);
        end
        if (advanceRF) begin
            RFcnt <= 1'b0;
            nop_ir();
            dpc <= pc;
            pc <= pc;
            dcause <= 5'd31;
        end
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // DECODE / REGFETCH
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
        xRa <= Ra;
        EXcnt <= RFcnt;
        xir <= ir;
        xcause <= dcause;
        xis64 <= opcode==`O64;
        if (opcode==`O64)
            xopcode <= opcode2;
        else
            xopcode <= opcode;
        xfunct3 <= funct3;
        xfunct7 <= funct7;
        xpc <= dpc;
        a <= rfoa;
        b <= rfob;
        case(opcode)
        `LUI:	imm <= {ir[31:12],12'd0};
        `AUIPC:	imm <= {ir[31:12],12'd0};
        `JAL:	imm <= {{12{ir[31]}},ir[19:12],ir[20],ir[30:21],1'b0};
        `JALR:	imm <= {{20{ir[31]}},ir[31:20]};
        `Bcc:	imm <= {{20{ir[31]}},ir[7],ir[30:25],ir[11:8],1'b0};
        `Lx:	imm <= {{20{ir[31]}},ir[31:20]};
        `Sx:	begin
            imm <= {{20{ir[31]}},ir[31:25],ir[11:7]};
            $display("ir = %h", ir);
            $display("imm <= %h",{{20{ir[31]}},ir[31:25],ir[11:7]});
                end
        `ALU1:
            if (funct3==3'b001) // SLLI
                imm <= ir[24:20];
            else
                imm <= {{20{ir[31]}},ir[31:20]};
        // 64 bit instructions
        `O64:
            case(opcode2)
            `Bcc:   imm2 <= {{12{ir[63]}},ir[63:44]};
            `Lx:    imm <= {ir[63:44],ir[31:20]};
            `Sx:    imm <= {ir[63:44],ir[31:25],ir[11:7]};
            `ALU1:  imm <= {ir[63:44],ir[31:20]};
            default:    imm <= 32'd0;
            endcase
        default:	imm <= 32'd0;
        endcase
        case(opcode)
        `LUI:	xRt <= ir[11:7];
        `AUIPC:	xRt <= ir[11:7];
        `JAL:	xRt <= ir[11:7];
        `JALR:	xRt <= ir[11:7];
        `Lx:	xRt <= ir[11:7];
        `ALU1:	xRt <= ir[11:7];
        `RR:	xRt <= ir[11:7];
        `O64:  xRt <= opcode2==`Sx ? 5'd0 : ir[11:7];
        default:	xRt <= 5'd0;
        endcase
    end
    else if (advanceEX) begin
        EXcnt <= 1'b0;
        if (!xisLd && !xisSt)
            nop_xir();
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // EXECUTE
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceEX) begin
/*
        wRa <= xRa;
        wir <= xir;
        wRt <= xRt;
        wres <= res;
        wcause <= xcause;
        WBcnt <= EXcnt;
*/
        rdinstret <= rdinstret + EXcnt;
        regfile[xRt] <= res;
        if (xRt != 5'd0)
            $display("r%d = %h", xRt, res);
        case(xopcode)
        `ALU1:
            case(xfunct3)
            `SRI:
                begin
                    $display("SRI: %h = %h >> #%h", res, a, imm);
                end
            `ANDI:  $display("ANDI: %h = %h & #%h", res, a, imm);
            `GRP0:
                case(xfunct7)
                7'b0000001:
                    begin
                        $display("mul %h * %h = %h", a, b, res);
                    end
                endcase
            endcase
        `JAL:	  begin tskBranch(xpc + imm); $display("jal %h xpc=%h xir=%h", xpc+imm,xpc,xir); end
        `JALR:	begin tskBranch(a + imm); end
        `Bcc:
            if (xis64)
                case(xfunct3)
                `BEQ:    if (a==imm2) tskBranch(xpc + imm);
                `BNE:    if (a!=imm2) tskBranch(xpc + imm);
                `BLT:    if ($signed(a) < $signed(imm2)) tskBranch(xpc + imm);
                `BGE:    if ($signed(a) >= $signed(imm2)) tskBranch(xpc + imm);
                `BLTU:    if (a < imm2) tskBranch(xpc + imm);
                `BGEU:    if (a >= imm2) tskBranch(xpc + imm);
                endcase
            else
                case(xfunct3)
                `BEQ:	if (a==b) tskBranch(xpc + imm);
                `BNE:	if (a!=b) tskBranch(xpc + imm);
                `BLT:	if ($signed(a) < $signed(b)) tskBranch(xpc + imm);
                `BGE:	if ($signed(a) >= $signed(b)) tskBranch(xpc + imm);
                `BLTU:	if (a < b) tskBranch(xpc + imm);
                `BGEU:	if (a >= b) tskBranch(xpc + imm);
                endcase
        `SYSTEM:
            case(xfunct3)
            3'b000:
                case(xir[31:20])
                12'b0000_0000_0000:
                    begin
                        tskBranch(evec);
                        mepc <= xpc;
                        SR_ET <= 1'b0;
                        SR_PS <= SR_S;
                        SR_S <= 1'b1;
                        if (xcause[31])
                            mcause <= xcause;
                        else
                            mcause <= 32'h8 | PRV;   // Environment call from mode 
                    end // ECALL
                12'b0000_0000_0001:
                    begin
                        tskBranch(evec);
                        mepc <= xpc;
                        SR_ET <= 1'b0;
                        SR_PS <= SR_S;
                        SR_S <= 1'b1;
                        mcause <= 32'h3;        // Breakpoint
                    end // EBRK
                12'b0001_0000_0000: // ERET
                    begin
                        tskBranch(mepc);
                        SR_ET <= TRUE;
                        SR_S <= SR_PS;
                    end
                endcase
            3'b001,3'b101:   // CSRRW,CSRRWI
                case(xir[31:20])
                MSTATUS:
                    begin
                        IE <= a[0];
                        PRV <= a[2:1];
                        IE1 <= a[3];
                        PRV1 <= a[5:4];
                        IE2 <= a[6];
                        PRV2 <= a[8:7];
                        IE3 <= a[9];
                        PRV3 <= a[11:10];
                        FS <= a[13:12];
                        XS <= a[15:14];
                        MPRV <= a[16];
                        VM <= a[21:17];
                        SD <= a[31];
                    end
                MTVEC: mtvec <= {a[31:2],2'b00};
                MTDELEG: mtdeleg <= a;
                MSCRATCH: mscratch <= a;
                MIP:
                    begin
                        MSIP <= a[3];
                        HSIP <= a[2];
                        SSIP <= a[1];
                    end
                MTIMECMP:
                    begin
                        MTIP <= 1'b0;
                        mtimecmp <= a;
                    end
                MIE:
                    begin
                        MTIE <= a[7];
                        HTIE <= a[6];
                        STIE <= a[5];
                        MSIE <= a[3];
                        HSIE <= a[2];
                        SSIE <= a[1];
                    end
                MTIME:  mtime_latch[31:0] <= a;
                MTIMEH: begin mtime_latch[63:32] <= a; mtimecnt <= 8'h00; end
                MEPC:   mepc <= a;
                MCAUSE: mcause <= a;
                MBADADDR: mbadaddr <= a;
                MSLL: sll <= a;
                MSLU: slu <= a;
                endcase
            3'b010,3'b110: // CSRRS,CSRRSI
                if (xRa != 5'd0) begin
                  case(xir[31:20])
                  MIE:
                    begin
                      MTIE <= MTIE|a[7];
                      HTIE <= HTIE|a[6];
                      STIE <= STIE|a[5];
                      MSIE <= MSIE|a[3];
                      HSIE <= HSIE|a[2];
                      SSIE <= SSIE|a[1];
                    end
                  endcase
                end
            3'b011,3'b111: // CSRRC,CSRRCI
                if (xRa != 5'd0) begin
                  case(xir[31:20])
                  MIE:
                    begin
                      MTIE <= MTIE&~a[7];
                      HTIE <= HTIE&~a[6];
                      STIE <= STIE&~a[5];
                      MSIE <= MSIE&~a[3];
                      HSIE <= HSIE&~a[2];
                      SSIE <= SSIE&~a[1];
                    end
                  endcase
                end
            endcase
        `Lx:
            begin
                if (ex_done==`TRUE) begin
                    ex_done <= `FALSE;
                    next_state(LOAD2);
                    mfunct3 <= xfunct3;
                    ea <= a + imm;
                    case(xfunct3)
                    `LB,`LBU:	ld_size <= byt;
                    `LH,`LHU:	ld_size <= half;
                    `LW:		ld_size <= word;
                    endcase
                end
                else
                    ex_done <= `TRUE;
            end
        `Sx:
            begin
                if (ex_done==`TRUE) begin
                    ex_done <= `FALSE;
                    next_state(STORE2);
                    mfunct3 <= xfunct3;
                    ea <= a + imm;
                    xb <= b;
                    case(xfunct3)
                    `SB:	st_size <= byt;
                    `SH:	st_size <= half;
                    `SW:	st_size <= word;
                    endcase
                end
                else
                    ex_done <= `TRUE;
            end
        endcase
    end
/*
    else if (advanceWB) begin
        WBcnt <= 1'b0;
        wRt <= 5'd0;
        wres <= 32'd0;
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // WRITEBACK
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceWB) begin
        rdinstret <= rdinstret + WBcnt;
        regfile[wRt] <= wres;
        if (wRt != 5'd0)
            $display("r%d = %h", wRt, wres);
    end // AdvanceWB
*/
end	// RUN
/*
LOAD1:
	begin
		ea <= a + imm;
		case(xfunct3)
		`LB,`LBU:	ld_size <= byt;
		`LH,`LHU:	ld_size <= half;
		`LW:		ld_size <= word;
		endcase
		next_state(LOAD2);
	end
*/
LOAD2:
	begin
		wb_read1(ld_size,ea);
		next_state(LOAD3);
	end
LOAD3:
	if (ack_i) begin
		case(mfunct3)
		`LB:begin
			wb_nack();
			next_state(RUN);
			case(ea[1:0])
			2'd0:	lres <= {{24{dat_i[7]}},dat_i[7:0]};
			2'd1:	lres <= {{24{dat_i[15]}},dat_i[15:8]};
			2'd2:	lres <= {{24{dat_i[23]}},dat_i[23:16]};
			2'd3:	lres <= {{24{dat_i[31]}},dat_i[31:24]};
			endcase
			end
		`LBU:
			begin
			wb_nack();
			next_state(RUN);
			case(ea[1:0])
			2'd0:	lres <= dat_i[7:0];
			2'd1:	lres <= dat_i[15:8];
			2'd2:	lres <= dat_i[23:16];
			2'd3:	lres <= dat_i[31:24];
			endcase
			end
		`LH:
			case(ea[1:0])
			2'd0:	begin lres <= {{16{dat_i[15]}},dat_i[15:0]}; next_state(RUN); wb_nack(); end
			2'd1:	begin lres <= {{16{dat_i[23]}},dat_i[23:8]}; next_state(RUN); wb_nack(); end
			2'd2:	begin lres <= {{16{dat_i[31]}},dat_i[31:16]}; next_state(RUN); wb_nack(); end
			2'd3:	begin lres[7:0] <= dat_i[31:24]; next_state(LOAD4); end
			endcase
		`LHU:
			case(ea[1:0])
			2'd0:	begin lres <= dat_i[15:0]; next_state(RUN); wb_nack(); end
			2'd1:	begin lres <= dat_i[23:8]; next_state(RUN); wb_nack(); end
			2'd2:	begin lres <= dat_i[31:16]; next_state(RUN); wb_nack(); end
			2'd3:	begin lres[7:0] <= dat_i[31:24]; next_state(LOAD4); end
			endcase
		`LW:
			case(ea[1:0])
			2'd0:	begin lres <= dat_i; next_state(RUN); wb_nack(); $display("Loaded %h from %h", dat_i, adr_o); end
			2'd1:	begin lres[23:0] <= dat_i[31:8]; next_state(LOAD4); end
			2'd2:	begin lres[15:0] <= dat_i[31:16]; next_state(LOAD4); end
			2'd3:	begin lres[7:0] <= dat_i[31:24]; next_state(LOAD4); end
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
		wb_nack();
		next_state(RUN);
		case(mfunct3)
		`LH:	lres[31:8] <= {{16{dat_i[7]}},dat_i[7:0]};
		`LHU:	lres[31:8] <= dat_i[7:0];
		`LW:
			case(ea[1:0])
			2'd0:	;
			2'd1:	lres[31:24] <= dat_i[7:0];
			2'd2:	lres[31:16] <= dat_i[15:0];
			2'd3:	lres[31:8] <= dat_i[23:0];
			endcase
		endcase
	end
/*
STORE1:
	begin
		ea <= b + imm;
		xb <= a;
		case(mfunct3)
		`SB:	st_size <= byt;
		`SH:	st_size <= half;
		`SW:	st_size <= word;
		endcase
		next_state(STORE2);
	end
*/
STORE2:
	begin
		wb_write1(st_size,ea,xb);
		$display("Store to %h <= %h", ea, xb);
		next_state(STORE3);
	end
STORE3:
	if (ack_i) begin
		wb_nack();
		if ((st_size==half && ea[1:0]==2'b11) || (st_size==word && ea[1:0]!=2'b00))
			next_state(STORE4);
		else begin
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
		next_state(RUN);
	end

LOAD_ICACHE:
    begin
      if (icmf != 2'b11) begin
        isICacheLoad <= TRUE;
        if (icmf[1]) begin
          iadr_o <= {pcp16[31:4],4'h0};
          icmf[0] <= 1'b1;
        end
        else begin
          icmf[1] <= 1'b1;
          iadr_o <= {pc[31:4],4'h0};
        end
        next_state(LOAD_ICACHE2);
      end
      else
        next_state(RUN);
    end
LOAD_ICACHE2:
  if (irdy_i) begin
    iadr_o[3:2] <= iadr_o[3:2] + 2'd1;
    if (iadr_o[3:2]==2'b11) begin
//        if (icmf==2'b11)
//            ic_lfsr <= {ic_lfsr[16:0],;
        isICacheLoad <= FALSE;
        next_state(icmf==2'b11 ? RUN : LOAD_ICACHE);
    end
  end

endcase
end

task wb_read1;
input [1:0] sz;
input [43:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	byt:
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
	half:
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0011;
		2'd1:	sel_o <= 4'b0110;
		2'd2:	sel_o <= 4'b1100;
		2'd3:	sel_o <= 4'b1000;
		endcase
	word:
		case(adr[1:0])
		2'd0:	sel_o <= 4'b1111;
		2'd1:	sel_o <= 4'b1110;
		2'd2:	sel_o <= 4'b1100;
		2'd3:	sel_o <= 4'b1000;
		endcase
	default:	sel_o <= 4'b0000;
	endcase
end
endtask

task wb_read2;
input [1:0] sz;
input [43:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	adr_o <= {adr[43:2]+30'd1,2'b00};
	case(sz)
	half:	sel_o <= 4'b0001;
	word:
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0000;
		2'd1:	sel_o <= 4'b0001;
		2'd2:	sel_o <= 4'b0011;
		2'd3:	sel_o <= 4'b0111;
		endcase
	default:	sel_o <= 4'b0000;
	endcase
end
endtask

task wb_write1;
input [1:0] sz;
input [43:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	byt:
		begin
		dat_o <= {4{dat[7:0]}};
		case(adr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		end
	half:
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b0011; dat_o <= {2{dat[15:0]}}; end
		2'd1:	begin sel_o <= 4'b0110;	dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		2'd2:	begin sel_o <= 4'b1100; dat_o <= {2{dat[15:0]}}; end
		2'd3:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
	word:
		case(adr[1:0])
		2'd0:	begin sel_o <= 4'b1111; dat_o <= dat; end
		2'd1:	begin sel_o <= 4'b1110;	dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b1100;	dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b1000;	dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
	endcase
end
endtask

task wb_write2;
input [1:0] sz;
input [43:0] adr;
input [31:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	adr_o <= {adr[43:2]+30'd1,2'b00};
	case(sz)
	half:
		case(adr[1:0])
		2'd0:	;
		2'd1:	;
		2'd2:	;
		2'd3:	begin sel_o <= 4'b0001; dat_o <= {dat[7:0],dat[15:0],dat[15:8]}; end
		endcase
	word:
		case(adr[1:0])
		2'd0:	;
		2'd1:	begin sel_o <= 4'b0001; dat_o <= {dat[23:0],dat[31:24]}; end
		2'd2:	begin sel_o <= 4'b0011;	dat_o <= {dat[15:0],dat[31:16]}; end
		2'd3:	begin sel_o <= 4'b0111;	dat_o <= {dat[7:0],dat[31:8]}; end
		endcase
	endcase
end
endtask

task wb_nack;
begin
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	sel_o <= 4'h0;
	adr_o <= 44'd0;
	dat_o <= 32'd0;
end
endtask

task nop_ir;
begin
	ir <= {12'b0,5'b0,3'b000,5'b0,7'b0010011};	// ADDI v0,x0,0
end
endtask

task nop_xir;
begin
	xopcode <= 7'h13;
	xfunct3 <= 3'b0;
	xRt <= 5'b0;
	xir <= {12'b0,5'b0,3'b000,5'b0,7'b0010011};	// ADDI v0,x0,0
end
endtask 

task tskBranch;
input [31:0] newpc;
begin
  pc <= newpc;
  pc[0] <= 1'b0;
  nop_ir();
  nop_xir();
  RFcnt <= 1'b0;
  EXcnt <= 1'b0;
end
endtask

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

function [127:0] fnStateName;
input [5:0] state;
case(state)
RESET:	fnStateName = "RESET ";
RUN:	fnStateName = "RUN ";
LOAD1:  fnStateName = "LOAD1 ";
LOAD2:  fnStateName = "LOAD2 ";
LOAD3:  fnStateName = "LOAD3 ";
LOAD4:  fnStateName = "LOAD4 ";
STORE1:  fnStateName = "STORE1 ";
STORE2:  fnStateName = "STORE2 ";
STORE3:  fnStateName = "STORE3 ";
STORE4:  fnStateName = "STORE4 ";
LOAD_ICACHE:	fnStateName = "LOAD_ICACHE ";
LOAD_ICACHE2:	fnStateName = "LOAD_ICACHE2 ";
endcase
endfunction

endmodule
