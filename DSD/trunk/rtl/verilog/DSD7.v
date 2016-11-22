// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd7.v
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
`define WISHBONE    1'b1
//`define ICACHE_4WAY 1'b1
//`define COMPRESSED_INSNS    1'b1

`define SIMULATION
`define VBA_VECT    32'hFFFFFF00
`define RST_VECT    32'hFFFC0000

`define BccI    6'h02
`define BccUI   6'h03
`define ADDI    6'h04
`define CMPI    6'h05
`define CMPUI   6'h06
`define ANDI    6'h08
`define ORI     6'h09
`define XORI    6'h0A
`define ORI32   6'h0B
`define R2      6'h0C
`define CSRI    6'h0F
`define CALL    6'h10
`define JAL     6'h10
`define JMP     6'h11
`define Bcc     6'h12
`define BccU    6'h13
`define JAL16   6'h14
`define CALL16  6'h14
`define JMP16   6'h15
`define SYS     6'h18
`define MEM     6'h19
`define NOP     6'h1A
`define INT     6'h1B
`define CALL0   6'h1C
`define JAL0    6'h1C
`define MOV     6'h1D
`define CINSN   6'h1F
`define LH      6'h20
`define LHU     6'h21
`define LW      6'h22
`define LWR     6'h23
`define SH      6'h28
`define SW      6'h29
`define SWC     6'h2A
`define PEA     6'h2B
`define MULI    6'h30
`define MULUI   6'h31
`define MULSUI  6'h32
`define MULHI   6'h33
`define MULUHI  6'h34
`define MULSUHI 6'h35
`define DIVI    6'h38
`define DIVUI   6'h39
`define DIVSUI  6'h3A
`define REMI    6'h3B
`define REMUI   6'h3C
`define REMSUI  6'h3D
`define CSR     6'h3F

// R2 functs
`define ADD     6'h04
`define CMP     6'h05
`define CMPU    6'h06
`define SUB     6'h07
`define AND     6'h08
`define OR      6'h09
`define XOR     6'h0A
`define NAND    6'h0C
`define NOR     6'h0D
`define XNOR    6'h0E
`define R2CSRI  6'h0F
`define SHL     6'h10
`define SHR     6'h11
`define ASR     6'h12
`define ROL     6'h13
`define ROR     6'h14
`define SXB     6'h16
`define SXH     6'h17
`define SHLI    6'h18
`define SHRI    6'h19
`define ASRI    6'h1A
`define ROLI    6'h1B
`define RORI    6'h1C
`define RPUSH   6'h1E
`define RPOP    6'h1F
`define LHX     6'h20
`define LHUX    6'h21
`define LWX     6'h22
`define LWRX    6'h23
`define SHX     6'h28
`define SWX     6'h29
`define SWCX    6'h2A
`define MUL     6'h30
`define MULU    6'h31
`define MULSU   6'h32
`define MULH    6'h33
`define MULUH   6'h34
`define MULSUH  6'h35
`define DIV     6'h38
`define DIVU    6'h39
`define DIVSU   6'h3A
`define REM     6'h3B
`define REMU    6'h3C
`define REMSU   6'h3D
`define R2CSR   6'h3F

// SYS functs
`define CLI     5'h00
`define SEI     5'h01
`define IRET    5'h04
`define IPUSH   5'h05
`define IPOP    5'h06

// MEM functs
`define RET     5'h00
`define PUSH    5'h02
`define POP     5'h03
`define PUSHI5  5'h04

`define _2NOP_INSN    {10'h0,`NOP,10'h0,`NOP}

`define CSRRW     2'b00
`define CSRRS     2'b01
`define CSRRC     2'b10

`define CSR_HARTID  12'h001
`define CSR_TICK    12'h002
`define CSR_PCR     12'h003
`define CSR_VBA     12'h004
`define CSR_CAUSE   12'h006
`define CSR_SCRATCH 12'h009
`define CSR_SEMA    12'h00C
`define CSR_SBL     12'h00E
`define CSR_SBU     12'h00F
`define CSR_TASK    12'h010
`define CSR_CISC    12'h011
`define CSR_ITOS0   12'h040
`define CSR_ITOS1   12'h041
`define CSR_ITOS2   12'h042
`define CSR_ITOS3   12'h043
`define CSR_ITOS4   12'h044
`define CSR_CONFIG  12'hFF0
`define CSR_CAP     12'hFFE

`define FLT_STACK   9'd504
`define FLT_DBE     9'd508

module DSD7(hartid_i, rst_i, clk_i, irq_i, icause_i,
    cyc_o, stb_o,
`ifdef WISHBONE
    ack_i,
`else
    rdy_i,
`endif
    vda_o, vpa_o, err_i, lock_o, wr_o, sel_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i,
    pcr_o
    );
input [31:0] hartid_i;
input rst_i;
input clk_i;
input irq_i;
input [8:0] icause_i;
output reg cyc_o;
output reg stb_o;
`ifdef WISHBONE
input ack_i;
`else
input rdy_i;
`endif
output reg vda_o;
output reg vpa_o;
input err_i;
output reg lock_o;
output reg wr_o;
output reg [1:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;
output [31:0] pcr_o;

// Core capabilities
parameter CAP_LS_NDX = 1'b1;
parameter CAP_ROTATES = 1'b1;
parameter CAP_MULDIV = 1'b1;

parameter half = 2'b10;
parameter word = 2'b11;

// State machine states
parameter RUN = 6'd1;
parameter DIV1 = 6'd5;
parameter LOAD2A = 6'd9;
parameter LOAD1 = 6'd10;
parameter LOAD2 = 6'd11;
parameter LOAD3 = 6'd12;
parameter INVnRUN = 6'd13;
parameter LOAD5 = 6'd14;
parameter LOAD6 = 6'd15;
parameter STORE1 = 6'd16;
parameter STORE2 = 6'd17;
parameter STORE3 = 6'd18;
parameter STORE2A = 6'd19;
parameter LOAD_ICACHE = 6'd20;
parameter LOAD_ICACHE2 = 6'd21; 
parameter LOAD_ICACHE3 = 6'd22; 
parameter ICACHE_RST = 6'd23;
parameter MUL1 = 6'd31;
parameter MUL2 = 6'd32;
parameter MUL3 = 6'd33;
parameter MUL4 = 6'd34;
parameter MUL5 = 6'd35;
parameter MUL6 = 6'd36;
parameter MUL7 = 6'd37;
parameter MUL8 = 6'd38;
parameter MUL9 = 6'd39;

integer n;
reg [5:0] state;
reg [1:0] ol = 2'b00;       // operating level (machine only)
reg [31:0] pc,dpc,xpc;
reg [31:0] pc_inc;
reg [63:0] insn,iinsn;
reg [63:0] ir,xir,mir;
reg [15:0] fault_insn;
reg stuff_fault;
reg ii32,ii5,ii5a;
reg i32,i5,i5a;
wire [5:0] iopcode = iinsn[5:0];
wire [5:0] ifunct = iinsn[31:26];
wire [4:0] iRb = iinsn[15:11];
wire [5:0] opcode = ir[5:0];
wire [5:0] funct = ir[31:26];
reg [4:0] Ra,iRa,xRa;
reg [4:0] Rb,xRb;
reg [4:0] Rc;
reg [4:0] Rt,xRt;
reg xRt2;
wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunct = xir[31:26];
// im1 | r29 | r2 | r1 | pc32
reg [128:0] istack[0:15];
reg [3:0] isp;
reg [31:0] r1,r2,r29;
reg [31:0] regfile [0:31];
reg [31:0] sp;
reg [31:0] rfoa,rfob,rfoc;
reg [31:0] a,b,c,imm,ea,xb;
reg [31:0] res,lres,lres1,res2;
wire takb;
reg [31:0] br_disp;
wire [31:0] logic_o, shift_o;
reg [1:0] mem_size;
reg upd_rf;                     // flag indicates to update register file
reg xinv,dinv;                  // invalidate flags for pipeline stages
// CSR's
reg [31:0] tick;
reg [31:0] msema;
reg [31:0] mcause;
reg [31:0] vba;                 // vector table base address 
reg [31:0] tr;
reg im, gie;
reg [128:0] itos;
reg [31:0] cisc;
wire [7:0] isid = cisc[7:0];
reg [31:0] scratch;
reg [31:0] cap = {CAP_MULDIV,CAP_ROTATES,CAP_LS_NDX};
reg [31:0] pcr;
reg [31:0] mconfig;
wire [4:0] regSP = mconfig[4:0];
wire [4:0] regBP = mconfig[12:8];
reg [31:0] sbl, sbu;

assign pcr_o = pcr;

`ifdef SIMULATION
initial begin
    a <= 0;
    b <= 0;
    c <= 0;
    for (n = 0; n < 32; n=n+1)
        regfile[n] <= 0;
    r1 <= 0;
    r2 <= 0;
    r29 <= 0;
    sp <= 0;
    xRt2 <= 1'b0;   // If this isn't defined for sim the sp will be XXXXX
    xRt <= 32'h0;
end
`endif

function [31:0] fnAbs;
input [31:0] jj;
fnAbs = jj[31] ? -jj : jj;
endfunction

// Results forwarding multiplexer

function [31:0] fwd_mux;
input [4:0] Rn;
begin
    case(Rn)
    5'd0:   fwd_mux = 32'd0;
    xRt:    fwd_mux = res;
    5'd1:   fwd_mux = r1;
    5'd2:   fwd_mux = r2;
    5'd29:  fwd_mux = r29;
    regSP:  if (xRt2)
                fwd_mux = res2;
            else
                fwd_mux = sp;
    default:    fwd_mux = regfile[Rn]; 
    endcase
end
endfunction

function xIsMC;
input [31:0] xr;
case(xr[5:0])
`MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI,
`DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI,
`LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,`PEA,
`MEM,`CALL,`CALL16,`CALL0:
    xIsMC = `TRUE;
`R2:
    case(xr[31:26])
    `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH,
    `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU,
    `LHX,`LHUX,`LWX,`LWRX,`SHX,`SWX,`SWCX:
    xIsMC = `TRUE;
    endcase
default:    xIsMC = `FALSE;
endcase
endfunction

wire iisShift = iopcode==`R2 && (ifunct==`SHL || ifunct==`SHR || ifunct==`ASR || ifunct==`ROL || ifunct==`ROR ||
                                ifunct==`SHLI || ifunct==`SHRI || ifunct==`ASRI || ifunct==`ROLI || ifunct==`RORI);


reg isShift;
wire xisLd = xopcode==`LH || xopcode==`LHU || xopcode==`LW || xopcode==`LWR ||
             (xopcode==`R2 && CAP_LS_NDX && (xfunct==`LHX || xfunct==`LHUX || xfunct==`LWX || xfunct==`LWRX));
wire xisSt = xopcode==`SH || xopcode==`SW || xopcode==`SWC ||
             (xopcode==`R2 && CAP_LS_NDX && (xfunct==`SHX || xfunct==`SWX || xfunct==`SWCX));

DSD7_BranchEval ubeval1
(
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .takb(takb)
);

DSD7_logic ulog1
(
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .res(logic_o)
);

DSD7_shift ushft1
(
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .res(shift_o),
    .rolo()
);

wire xMul = xopcode==`R2 && (xfunct==`MUL || xfunct==`MULH);
wire xMulu = xopcode==`R2 && (xfunct==`MULU || xfunct==`MULUH);
wire xMulsu = xopcode==`R2 && (xfunct==`MULSU || xfunct==`MULSUH);
wire xMuli = xopcode==`MULI || xopcode==`MULHI;
wire xMului = xopcode==`MULUI || xopcode==`MULUHI;
wire xMulsui = xopcode==`MULSUI || xopcode==`MULSUHI;

wire [63:0] mul_prod1;
reg [63:0] mul_prod;
reg mul_sign;
reg [31:0] aa, bb;

// 6 stage pipeline
DSD7_multiplier u2
(
  .clk(clk_i),
  .a(aa),
  .b(bb),
  .p(mul_prod1)
);

wire [31:0] qo, ro;

wire xDiv = xopcode==`DIVI || xopcode==`DIVUI || xopcode==`DIVSUI || xopcode==`REMI || xopcode==`REMUI || xopcode==`REMSUI ||
             (xopcode==`R2 && (xfunct==`DIV || xfunct==`DIVU || xfunct==`DIVSU || xfunct==`REM || xfunct==`REMU || xfunct==`REMSU))
             ;
wire xDivi = xopcode==`DIVI || xopcode==`DIVUI || xopcode==`DIVSUI || xopcode==`REMI || xopcode==`REMUI || xopcode==`REMSUI;
wire xDivss = xopcode==`DIVI || (xopcode==`R2 && (xfunct==`DIV || xfunct==`REM));
wire xDivsu = xopcode==`DIVSUI || (xopcode==`R2 && (xfunct==`DIVSU || xfunct==`REMSU));

wire dvd_done;
DSD_divider #(32) u1
(
	.rst(rst_i),
	.clk(clk_i),
	.abort(1'b0),
	.ld(xDiv),
	.ss(xDivss),
	.su(xDivsu),
	.isDivi(xDivi),
	.a(a),
	.b(b),
	.imm(imm),
	.qo(qo),
	.ro(ro),
	.dvByZr(),
	.done(dvd_done),
	.idle()
);

always @*
begin
    case(xopcode)
    `R2:
        case(xfunct)
        `ADD:   res = a + b;
        `SUB:   res = a - b;
        `CMP:   res = $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
        `CMPU:  res = a < b ? -1 : a==b ? 0 : 1;
        `AND:   res = logic_o;
        `OR:    res = logic_o;
        `XOR:   res = logic_o;
        `NAND:  res = logic_o;
        `NOR:   res = logic_o;
        `XNOR:  res = logic_o;
        `SHL:   res = shift_o;
        `SHR:   res = shift_o;
        `ASR:   res = shift_o;
        `ROL:   res = CAP_ROTATES ? shift_o : 32'hDEADDEAD;
        `ROR:   res = CAP_ROTATES ? shift_o : 32'hDEADDEAD;
        `SHLI:  res = shift_o;
        `SHRI:  res = shift_o;
        `ASRI:  res = shift_o;
        `ROLI:  res = CAP_ROTATES ? shift_o : 32'hDEADEAD;
        `RORI:  res = CAP_ROTATES ? shift_o : 32'hDEADEAD;
        `SXB:   res = {{24{a[7]}},a[7:0]};
        `SXH:   res = {{16{a[15]}},a[15:0]};
        `R2CSR,`R2CSRI: read_csr(b[13:0],res);
        `MUL:   res = CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD;
        `MULU:  res = CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD;
        `MULSU: res = CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD;
        `MULH:  res = CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD;
        `MULUH: res = CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD;
        `MULSUH:res = CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD;
        `DIV:   res = CAP_MULDIV ? qo : 32'hDEADDEAD;
        `DIVU:  res = CAP_MULDIV ? qo : 32'hDEADDEAD;
        `DIVSU: res = CAP_MULDIV ? qo : 32'hDEADDEAD;
        `REM:   res = CAP_MULDIV ? ro : 32'hDEADDEAD;
        `REMU:  res = CAP_MULDIV ? ro : 32'hDEADDEAD;
        `REMSU: res = CAP_MULDIV ? ro : 32'hDEADDEAD;
        `LHX,`LHUX,`LWX,`LWRX:  res = CAP_LS_NDX ? lres : 32'hDEADDEAD;
        default:    res = 32'hDEADDEAD;
        endcase
    `ADDI:  res = a + imm;
    `CMPI:  res = $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
    `CMPUI: res = a < imm ? -1 : a==imm ? 0 : 1;
    `ANDI:  res = logic_o;
    `ORI:   res = logic_o;
    `ORI32: res = logic_o;
    `XORI:  res = logic_o;
    `JMP:       res = xpc + 32'd3;
    `JMP16:     res = xpc + 32'd2;
    `MOV:   res = a;
    `CSR,`CSRI: read_csr(xir[31:18],res);
    `MEM:
        case (xir[15:11])
        `RET:       res = a + imm;
        `PUSHI5,
        `PUSH:      res = a - 32'd2;
        `POP:       res = lres;
        default:    res = 32'hDEADDEAD;
        endcase
    `LH,`LHU,`LW,`LWR:  res = lres;
    `PEA:       res = a - 32'd2;
    `CALL:      res = a - 32'd2;
    `CALL16:    res = a - 32'd2;
    `CALL0:     res = a - 32'd2;
    default:    res = 32'hDEADDEAD;
    endcase
end

// The only instruction using result bus #2 is the pop instruction.
// Save some decoding.
always @*
    res2 <= a + 32'd2;
/*
    case(xopcode)
    `MEM:
        case(xir[15:11])
        `POP:   res2 <= a + 32'd2;
        default:    res2 <= 32'h0;
        endcase
    default:    res2 <= 32'h0;
    endcase
*/

//---------------------------------------------------------------------------
// Lookup table for compressed instructions.
// The lookup table appears in the data memory space of the processor at an
// address defined by the cisc register.
//---------------------------------------------------------------------------
wire [31:0] cinsn;
wire cs_hl = cyc_o && stb_o && vda_o && wr_o && adr_o[31:20]==cisc[31:20];
wire [11:0] citAdr = adr_o[12:1];

`ifdef COMPRESSED_INSNS

DSD7_ciLookupTbl u3
(
    .wclk(clk_i),
    .wr(cs_hl),
    .wadr(citAdr),
    .wdata(dat_o),
    .rclk(~clk_i),
    .radr({isid[1:0],insn[15:6]}),
    .rdata(cinsn)
);
`else
assign cinsn = `_2NOP_INSN;
`endif

//---------------------------------------------------------------------------
// I-Cache
// This 64-line 4 way set associative cache is used mainly to allow access
// to 16 and 64 bit instructions while the external bus is 32 bit.
// At reset the cache is loaded from address $FFFFFE00 to $FFFFFFFF
//
//---------------------------------------------------------------------------
wire [31:0] pcp8 = pc + 32'h0008;   // Use pc plus 8 to select the next cache line.
wire [22:0] ic_lfsr;

reg isICacheReset;
reg isICacheLoad;
reg [1:0] icmf;             // miss flags
`ifdef ICACHE_4WAY
// This linear-feedback-shift-register is used to pseudo-randomly select a
// way to update. It free runs until there is a cache miss.
lfsr #(23,23'h00ACE1) ulfsr1
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(state==RUN),
    .cyc(1'b0),
    .o(ic_lfsr)
);

wire [1:0] ic_whichWay = ic_lfsr[1:0];
wire ihit1,ihit2;
wire hita,hitb,hitc,hitd;   // way hit indicators
// Storage for four ways of the cache.
reg [127:0] cache_mem0 [0:63];
reg [127:0] cache_mem1 [0:63];
reg [127:0] cache_mem2 [0:63];
reg [127:0] cache_mem3 [0:63];
// Four sets of tag memory, one for each way. Some of the low order bits of the
// tag are not used and will be trimmed when the design in synthesized. For
// convenience we assume all address bits are available.
reg [31:0] tag_mem0 [0:63];
reg [31:0] tag_mem1 [0:63];
reg [31:0] tag_mem2 [0:63];
reg [31:0] tag_mem3 [0:63];

always @(posedge clk_i)
    // On reset load all ways with same data.
`ifdef WISHBONE
    if (ack_i) begin
`else
    if (rdy_i) begin
`endif
    if (isICacheReset) begin
        case(adr_o[2:1])
        2'd0: cache_mem0[adr_o[8:3]][31:0] <= dat_i;
        2'd1: cache_mem0[adr_o[8:3]][63:32] <= dat_i;
        2'd2: cache_mem0[adr_o[8:3]][95:64] <= dat_i;
        2'd3: cache_mem0[adr_o[8:3]][127:96] <= dat_i;
        endcase
        case(adr_o[2:1])
        2'd0: cache_mem1[adr_o[8:3]][31:0] <= dat_i;
        2'd1: cache_mem1[adr_o[8:3]][63:32] <= dat_i;
        2'd2: cache_mem1[adr_o[8:3]][95:64] <= dat_i;
        2'd3: cache_mem1[adr_o[8:3]][127:96] <= dat_i;
        endcase
        case(adr_o[2:1])
        2'd0: cache_mem2[adr_o[8:3]][31:0] <= dat_i;
        2'd1: cache_mem2[adr_o[8:3]][63:32] <= dat_i;
        2'd2: cache_mem2[adr_o[8:3]][95:64] <= dat_i;
        2'd3: cache_mem2[adr_o[8:3]][127:96] <= dat_i;
        endcase
        case(adr_o[2:1])
        2'd0: cache_mem3[adr_o[8:3]][31:0] <= dat_i;
        2'd1: cache_mem3[adr_o[8:3]][63:32] <= dat_i;
        2'd2: cache_mem3[adr_o[8:3]][95:64] <= dat_i;
        2'd3: cache_mem3[adr_o[8:3]][127:96] <= dat_i;
        endcase
    end
    // During a cache-line load, load only the way which was selected randomly.
    // This currently requires 4 bus cycles of 32 bits.
    else if (isICacheLoad) begin
        case({ic_whichWay,adr_o[2:1]})
        4'd0: cache_mem0[adr_o[8:3]][31:0] <= dat_i;
        4'd1: cache_mem0[adr_o[8:3]][63:32] <= dat_i;
        4'd2: cache_mem0[adr_o[8:3]][95:64] <= dat_i;
        4'd3: cache_mem0[adr_o[8:3]][127:96] <= dat_i;
        4'd4: cache_mem1[adr_o[8:3]][31:0] <= dat_i;
        4'd5: cache_mem1[adr_o[8:3]][63:32] <= dat_i;
        4'd6: cache_mem1[adr_o[8:3]][95:64] <= dat_i;
        4'd7: cache_mem1[adr_o[8:3]][127:96] <= dat_i;
        4'd8: cache_mem2[adr_o[8:3]][31:0] <= dat_i;
        4'd9: cache_mem2[adr_o[8:3]][63:32] <= dat_i;
        4'd10: cache_mem2[adr_o[8:3]][95:64] <= dat_i;
        4'd11: cache_mem2[adr_o[8:3]][127:96] <= dat_i;
        4'd12: cache_mem3[adr_o[8:3]][31:0] <= dat_i;
        4'd13: cache_mem3[adr_o[8:3]][63:32] <= dat_i;
        4'd14: cache_mem3[adr_o[8:3]][95:64] <= dat_i;
        4'd15: cache_mem3[adr_o[8:3]][127:96] <= dat_i;
        endcase
    end
    end

// Pull instructions from four pairs of cache lines, one for each way. Typically
// only a single pair of cache lines will contain the valid instructions.
wire [127:0] co01 = cache_mem0[pc[8:3]];
wire [127:0] co02 = cache_mem0[pcp8[8:3]];
wire [127:0] co11 = cache_mem1[pc[8:3]];
wire [127:0] co12 = cache_mem1[pcp8[8:3]];
wire [127:0] co21 = cache_mem2[pc[8:3]];
wire [127:0] co22 = cache_mem2[pcp8[8:3]];
wire [127:0] co31 = cache_mem3[pc[8:3]];
wire [127:0] co32 = cache_mem3[pcp8[8:3]];
// Select a pair of cache lines based on which way got hit. The way hit is determined later.
// If no ways got hit then it's a cache miss. The state machine should transition to the 
// cache miss states, but just to be safe we provide a NOP instruction for the pipeline.
wire [127:0] co1 = hita ? co01 : hitb ? co11 : hitc ? co21 : hitd ? co31 : {4{`_2NOP_INSN}};    // NOP on a miss
wire [127:0] co2 = hita ? co02 : hitb ? co12 : hitc ? co22 : hitd ? co32 : {4{`_2NOP_INSN}};    // NOP on a miss
// Get the instruction window for the pipeline. Instructions can be up to 64 bit long
// and spanning cache lines.
// Combine the cache line pair selected in case the instruction spans cache lines.
always @(pc or co1 or co2)
case(pc[2:0])
3'd0: insn = co1[63:0];
3'd1: insn = co1[79:16];
3'd2: insn = co1[95:32];
3'd3: insn = co1[112:48];
3'd4: insn = co1[127:64];
3'd5: insn = {co2[15:0],co1[127:80]};
3'd6: insn = {co2[31:0],co1[127:96]};
3'd7: insn = {co2[47:0],co1[127:112]};
endcase 

always @(posedge clk_i)
    // Set the tag only when the last 32 bits of the instruction line is loaded.
    // Prevents the tag from going valid until the entire line is present.
    if (adr_o[2:1]==2'b11) begin
        if (isICacheReset) begin
            tag_mem0[adr_o[8:3]] <= adr_o;
            tag_mem1[adr_o[8:3]] <= adr_o;
            tag_mem2[adr_o[8:3]] <= adr_o;
            tag_mem3[adr_o[8:3]] <= adr_o;
        end
        else if (isICacheLoad)
            case(ic_whichWay)
            2'd0:   tag_mem0[adr_o[8:3]] <= adr_o;
            2'd1:   tag_mem1[adr_o[8:3]] <= adr_o;
            2'd2:   tag_mem2[adr_o[8:3]] <= adr_o;
            2'd3:   tag_mem3[adr_o[8:3]] <= adr_o;
            endcase
    end

// Set tag comparators, there would be only four for a four-way set associative
// cache, but we need to check two cache lines in case the instruction spans a
// cache lines. Hence there are four pairs of comparators.
wire ihit01 = pc[31:9]==tag_mem0[pc[8:3]][31:9];
wire ihit02 = pcp8[31:9]==tag_mem0[pcp8[8:3]][31:9];
wire ihit11 = pc[31:9]==tag_mem1[pc[8:3]][31:9];
wire ihit12 = pcp8[31:9]==tag_mem1[pcp8[8:3]][31:9];
wire ihit21 = pc[31:9]==tag_mem2[pc[8:3]][31:9];
wire ihit22 = pcp8[31:9]==tag_mem2[pcp8[8:3]][31:9];
wire ihit31 = pc[31:9]==tag_mem3[pc[8:3]][31:9];
wire ihit32 = pcp8[31:9]==tag_mem3[pcp8[8:3]][31:9];
// hit(a)(b)(c)(d) indicate a hit on a way. If the pc is evenly located at a
// cache line, then the instruction can't be spanning a line, so we only need
// to check the first hit indicator of the pair. Doing this reduces the number
// of cache misses. Otherwise both hit indicators of the pair need to be 
// checked.
assign hita = (ihit01 & ihit02) || (ihit01 && pc[2:0]==3'h0);
assign hitb = (ihit11 & ihit12) || (ihit11 && pc[2:0]==3'h0);
assign hitc = (ihit21 & ihit22) || (ihit21 && pc[2:0]==3'h0);
assign hitd = (ihit31 & ihit32) || (ihit31 && pc[2:0]==3'h0);
// Check if there is a hit on any way. We don't care which one. If there are
// hits on more than one way at a time, it should be okay because the contents
// of the ways should be identical.
wire ihit = hita|hitb|hitc|hitd;
//assign ihit1 = hita ? ihit01 : hitb ? ihit11 : hitc ? ihit21 : ihit31;
//assign ihit2 = hita ? ihit02 : hitb ? ihit12 : hitc ? ihit22 : ihit32;
`else
reg [127:0] cache_mem [0:255];
reg [31:0] tag_mem [0:255];

always @(posedge clk_i)
    // On reset load all ways with same data.
`ifdef WISHBONE
    if (ack_i) begin
`else
    if (rdy_i) begin
`endif
    if (isICacheReset|isICacheLoad) begin
        case(adr_o[2:1])
        2'd0: cache_mem[adr_o[10:3]][31:0] <= dat_i;
        2'd1: cache_mem[adr_o[10:3]][63:32] <= dat_i;
        2'd2: cache_mem[adr_o[10:3]][95:64] <= dat_i;
        2'd3: cache_mem[adr_o[10:3]][127:96] <= dat_i;
        endcase
    end
    end
// Pull instructions from four pairs of cache lines, one for each way. Typically
// only a single pair of cache lines will contain the valid instructions.
wire [127:0] co1 = cache_mem[pc[10:3]];
wire [127:0] co2 = cache_mem[pcp8[10:3]];
// Get the instruction window for the pipeline. Instructions can be up to 64 bit long
// and spanning cache lines.
// Combine the cache line pair selected in case the instruction spans cache lines.
always @(pc or co1 or co2)
case(pc[2:0])
3'd0: insn = co1[63:0];
3'd1: insn = co1[79:16];
3'd2: insn = co1[95:32];
3'd3: insn = co1[112:48];
3'd4: insn = co1[127:64];
3'd5: insn = {co2[15:0],co1[127:80]};
3'd6: insn = {co2[31:0],co1[127:96]};
3'd7: insn = {co2[47:0],co1[127:112]};
endcase 

always @(posedge clk_i)
    // Set the tag only when the last 32 bits of the instruction line is loaded.
    // Prevents the tag from going valid until the entire line is present.
    if (adr_o[2:1]==2'b11) begin
        if (isICacheReset|isICacheLoad)
            tag_mem[adr_o[10:3]] <= adr_o;
    end

// Set tag comparators, there would be only four for a four-way set associative
// cache, but we need to check two cache lines in case the instruction spans a
// cache lines. Hence there are four pairs of comparators.
wire ihit1 = pc[31:11]==tag_mem[pc[10:3]][31:11];
wire ihit2 = pcp8[31:11]==tag_mem[pcp8[10:3]][31:11];
wire ihit = (ihit1 && pc[2:0]==3'b000) || (ihit1 && ihit2);

`endif

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
wire advanceRF = !(xIsMC(xir) && !xinv);
wire advanceIF = advanceRF & (ihit && !isICacheLoad);

always @(posedge clk_i)
if (rst_i) begin
    stuff_fault <= `FALSE;
    im <= `TRUE;
    isp <= 4'd0;
    tr <= 6'd0;
    vba <= `VBA_VECT;
    pcr <= 32'h0;
    cisc <= 32'hFFE00000;
    pc <= `RST_VECT;
    cyc_o <= `TRUE;
    stb_o <= `TRUE;
    vda_o <= `FALSE;
    vpa_o <= `TRUE;
    lock_o <= `FALSE;
    wr_o <= `FALSE;
    sel_o <= 2'b11;
    adr_o <= 32'hFFFC0000;
    isICacheLoad <= `FALSE;
    isICacheReset <= `TRUE;
    icmf <= 2'b00;
    gie <= `FALSE;
    tick <= 32'd0;
    mconfig <= {8'd30,8'd31};
    sbl <= 32'h0;
    sbu <= 32'hFFFFFFFF;
    dinv <= `TRUE;
    xinv <= `TRUE;
    next_state(ICACHE_RST);
end
else begin
upd_rf <= `FALSE;
tick <= tick + 32'd1;
update_regfile();

case(state)
ICACHE_RST:
`ifdef WISHBONE
    if (ack_i) begin
`else
    if (rdy_i) begin
`endif
        adr_o <= adr_o + 32'd2;
        if (adr_o[10:1]==10'h3FF) begin
            isICacheReset <= `FALSE;
            cyc_o <= `FALSE;
            stb_o <= `FALSE;
            vpa_o <= `FALSE;
            sel_o <= 2'b00;
            next_state(RUN);
        end
    end
RUN:
begin
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // IFETCH stage
    // We want decodes in the IFETCH stage to be fast so they don't appear
    // on the critical path.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceIF) begin
        // A stuffed fault will have occurred earlier than a pending IRQ
        // hence takes precedence.
        if (stuff_fault) begin
            iinsn = {16'd0,fault_insn};
            stuff_fault <= `FALSE;
        end
        else if (irq_i & ~im & gie)
            iinsn = {17'd0,icause_i,`INT};
        else
            iinsn = insn[5:0]==`CINSN ? cinsn : insn;
        ii32 = iinsn[31:26]==6'h20;
        ii5 = iinsn[15:11]==5'h10;
        ii5a = iinsn[10:6]==5'h10;
        iRa = iinsn[10:6]; 
        if (iinsn[5:0]==`INT) begin
            Ra <= 5'd1;
            Rb <= 5'd2;
            Rc <= 5'd29;
        end
        else if (iinsn[5:0]==`PEA || iinsn[5:0]==`CALL || iinsn[5:0]==`CALL16 || iinsn[5:0]==`CALL0 ||
            (iinsn[5:0]==`MEM && (iinsn[15:11]==`RET || iinsn[15:11]==`PUSH || insn[15:11]==`POP))) begin
            Ra <= regSP;
            Rb <= iinsn[10:6];
            Rc <= iinsn[15:11];
        end
        else begin
            Ra <= iRa;
            Rb <= iinsn[15:11];
            Rc <= iinsn[20:16];
        end
        // The INT is going to do a jump anyways os the PC increment
        // shouldn't matter.
//        if ((irq_i & ~im & gie) || stuff_fault)
//            pc_inc = 32'd1;
//        else
        case(insn[5:0])
        `LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,
        `MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI,
        `DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,
        `PEA:
            pc_inc = ii32 ? 32'd4 : 32'd2;
        `Bcc:   pc_inc = 32'd2;
        `BccU:  pc_inc = 32'd2;
        `BccI:  pc_inc = ii5 ? 32'd4 : 32'd2;
        `BccUI:  pc_inc = ii5 ? 32'd4 : 32'd2;
        `NOP,`CINSN:
            pc_inc = 32'd1;
        `CSRI:  pc_inc = ii5a ? 32'd4 : 32'd2;
        `CSR:   pc_inc = 32'd2;
        `R2:
            case(insn[31:26])
            `R2CSRI:  pc_inc = ii5a ? 32'd4 : 32'd2;
            default:    pc_inc = 32'd1;
            endcase
        `MEM:
            case(insn[15:11])
            `RET,`PUSHI5:   pc_inc = ii5a ? 32'd4 : 32'd1;
            default:    pc_inc = 32'd1;
            endcase
        `JMP,`CALL,`ORI32: pc_inc = 32'd3;
        `JMP16,`CALL16: pc_inc = 32'd2;
        `CALL0: pc_inc = 32'd1;
        default:    pc_inc = 32'd1;
        endcase
        // Can't execute jumps in the IF stage.
        // Suppose the following the instruction is an invalid jump
        // This might go to an invalid address.
        // Have to test for iinsn[10:6] for jumps and
        // iinsn[15:11] for calls.
        /*
        if (iinsn[10:6]==5'd0)
            case(iopcode)
            `CALL0:  pc <= 32'h0;
            `JMP16,`CALL16: begin
                            pc <= {{16{iinsn[31]}},iinsn[31:16]};
                            $display("Jump in IFstate: %h",{{16{iinsn[31]}},iinsn[31:16]});
                            end
            `JMP,`CALL:   pc <= iinsn[47:16];
            default:    pc <= pc + pc_inc;
            endcase
        else
        */
            pc <= pc + pc_inc;
        i32 <= ii32;
        i5 <= ii5;
        i5a <= ii5a;
        ir <= iinsn;
        dinv <= `FALSE;
        dpc <= pc;
    end
    else begin
        if (!ihit) begin
            icmf <= {ihit1,ihit2};
            next_state(LOAD_ICACHE);
        end
        if (advanceRF) begin
            inv_ir();
            dpc <= pc;
            pc <= pc;
        end
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
        xinv <= dinv;
        xir <= ir;
        xpc <= dpc;
        a <= fwd_mux(Ra);
        b <= fwd_mux(Rb);
        c <= fwd_mux(Rc);
        // Suppress register file update if RF stage is invalid.
        case({dinv,opcode})
        `R2:
            case(funct)
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR,
            `SHL,`SHR,`ASR,`ROL,`ROR,
            `SHLI,`SHRI,`ASRI,`ROLI,`RORI:  upd_rf <= `TRUE;
            `R2CSRI:    upd_rf <= `TRUE;
            endcase
        `MOV,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`ORI32:
            upd_rf <= `TRUE;
        `CSRI:  upd_rf <= `TRUE;
        `JMP,`JMP16:    upd_rf <= `TRUE;
        endcase
        case(opcode)
        `R2:
          case(funct)
          `SHLI,`SHRI,`ASRI,`ROLI,`RORI:     b <= Rb;
          default:    ;
          endcase
        default:  ;
        endcase
        case(opcode)
        `MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI,
        `DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,
        `LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,`PEA:
            imm <= i32 ? ir[63:32] : {{16{ir[31]}},ir[31:16]};
        `BccI,`BccUI:  imm <= i5 ? ir[63:32] : {{27{ir[15]}},ir[15:11]};
        `CSRI:         imm <= i5a ? ir[63:32] : {{27{ir[10]}},ir[10:6]};
        `JMP,`CALL,`ORI32:  imm <= ir[47:16];
        `JMP16,`CALL16: imm <= {{16{ir[31]}},ir[31:16]};
        `CALL0:        imm <= 32'h0;
        `R2:
            case(ir[31:26])
            `R2CSRI:    imm <= i5a ? ir[63:32] : {{27{ir[10]}},ir[10:6]};
            default:    imm <= 32'h0;
            endcase
        `MEM:
            case(ir[15:11])
            `RET:       imm <= i5a ? ir[63:32] : {{27{ir[10]}},ir[10:6]};
            `PUSHI5:    imm <= i5a ? ir[63:32] : {{27{ir[10]}},ir[10:6]};
            default:    imm <= {{27{ir[10]}},ir[10:6]};
            endcase
        default:    imm <= 32'h0;
        endcase
        // Branch displacement, used only for conditional branches.
        // Branches may also compare against an immediate so the displacement
        // has to be determined separately. 
        br_disp <= {{19{ir[31]}},ir[31:19]};
        // Needed for CSR instructions
        xRa <= Ra;
        xRb <= Rb;  // needed for calls/jumps
        // Set target register
        xRt2 <= 1'b0;
        case(opcode)
        `R2:
            case(funct)
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR,
            `SHL,`SHR,`ASR,`ROL,`ROR,
            `SHLI,`SHRI,`ASRI,`ROLI,`RORI,
            `LHX,`LHUX,`LWX,`LWRX:
                xRt <= ir[20:16];
            default:
                xRt <= 5'd0;
            endcase
        `CALL,`CALL16,`CALL0:
            xRt <= regSP;
        `MEM:
            case(xir[15:11])
            `RET,`PUSHI5,`PUSH:  xRt <= regSP;
            `POP:   begin xRt <= ir[10:6]; xRt2 <= 1'b1; end
            default:    xRt <= 5'd0;
            endcase
        `MOV,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`ORI32,
        `LH,`LHU,`LW,`LWR:
            xRt <= ir[15:11];
        `PEA:
            xRt <= regSP;
        `JMP,`JMP16:    xRt <= ir[15:11];
        default:
            xRt <= 5'd0;
        endcase
    end
//    else
//        inv_xir();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // If the execute stage has been invalidated it doesn't do anything. 
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (!xinv) begin   // if (advanceEX) // always true
        case(xopcode)
 
        // INT uses ex_branch() to flush the pipeline of extra INT instructions
        // which stream into core until interrupts are masked here.
        `INT:
            begin
                mcause <= xir[14:6];
                itos <= {im,c,b,a,xpc+xir[15]};
                im <= `TRUE;
                msema[0] <= 1'b0;
                ex_branch(vba+{ol,2'b00});
            end
        
        `JMP,`JMP16:
                if (xRa!=5'd0) begin
                    if (xRa==regSP)
                       ex_branch(xpc + imm);
                    else
                        ex_branch(a + imm);
                end
        `CALL:      ex_call(32'd3);
        `CALL16:    ex_call(32'd2);
        `CALL0:     ex_call(32'd1);

        `Bcc,`BccU,
        `BccI,`BccUI:
            if (takb)
                ex_branch(xpc + br_disp);

        `R2:
            case(xfunct)
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR:
                ;
            `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH:
                if (CAP_MULDIV) begin
                    next_state(MUL1);
                end
            `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
                if (CAP_MULDIV) begin
                    next_state(DIV1);
                end
            `LHX,`LHUX:
                if (CAP_LS_NDX) begin
                    begin
                        mem_size <= half;    
                        ea <= a + b;
                        next_state(LOAD1);
                    end
                end
            `LWX,`LWRX:
                if (CAP_LS_NDX) begin
                    begin
                        mem_size <= word;    
                        ea <= a + b;
                        next_state(LOAD1);
                    end
                end
            `SHX:
                if (CAP_LS_NDX) begin
                    begin
                        mem_size <= half;
                        ea <= a + b;
                        xb <= b;
                        state <= STORE1;
                    end
                end
            `SWX,`SWCX:
                if (CAP_LS_NDX) begin
                    begin
                        mem_size <= word;
                        ea <= a + b;
                        xb <= c;
                        state <= STORE1;
                    end
                end
            `R2CSR:   if (xRa != 5'd0)
                            write_csr(xir[22:21],b[13:0],a);
            `R2CSRI:  write_csr(xir[22:21],b[13:0],imm);
            endcase
        `SYS:
            case(xir[15:11])
            `CLI:   im <= 1'b0;
            `SEI:   im <= 1'b1;
            `IRET:
                begin
                ex_branch(itos[31:0]);
                // r1,r2, and r3 can be updated here like this only because the
                // pipeline is being flushed.
                r1 <= itos[63:32];
                r2 <= itos[95:64];
                r29 <= itos[127:96];
                im <= itos[128];
                msema[0] <= 1'b0;
                msema[xRa] <= 1'b0;
                end
            `IPUSH:
                begin
                istack[isp-4'd1] <= itos[128:0];
                isp <= isp - 4'd1;
                end
            `IPOP:
                begin
                itos[128:0] <= istack[isp];
                isp <= isp + 4'd1;
                end
            endcase
        `MEM:
            case(xir[15:11])
            `RET:
                begin
                    if (a > sbu)
                        ex_fault(`FLT_STACK,0);
                    else begin
                        mem_size <= word;
                        ea <= a;
                        next_state(LOAD1);
                    end
                end
            `PUSH:
                if (a - 32'd2 < sbl)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a - 32'd2;
                    xb <= b;
                    next_state(STORE1);
                end
            `PUSHI5:
                if (a - 32'd2 < sbl)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a - 32'd2;
                    xb <= imm;
                    next_state(STORE1);
                end
            `POP:
                if (a > sbu)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a;
                    next_state(LOAD1);
                end
            endcase
            
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`ORI32:
            ;
        `MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI:
            if (CAP_MULDIV) begin
                next_state(MUL1);
            end
        `DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI:
            if (CAP_MULDIV) begin
                next_state(DIV1);
            end
        `LH,`LHU:
            begin
                mem_size <= half;    
                ea <= a + imm;
                next_state(LOAD1);
            end
        `LW,`LWR:
            begin
                mem_size <= word;
                ea <= a + imm;
                next_state(LOAD1);
            end
        `SH:
            begin
                mem_size <= half;
                ea <= a + imm;
                xb <= b;
                state <= STORE1;
            end
        `SW,`SWC:
            begin
                mem_size <= word;
                ea <= a + imm;
                xb <= b;
                state <= STORE1;
            end
        `PEA:
            if (a - 32'd2 < sbl)
                ex_fault(`FLT_STACK,0);
            else begin
                mem_size <= word;
                ea <= a - 32'd2;
                xb <= b + imm;
                state <= STORE1;
            end
        `CSR:   if (xRa != 5'd0)
                    write_csr(xir[17:16],xir[31:18],a);
        `CSRI:  write_csr(xir[17:16],xir[31:18],imm);
        default:    ;
        endcase
    end // advanceEX

end // RUN

// Step1: setup operands and capture sign
MUL1:
    begin
        if (xMul) mul_sign <= a[31] ^ b[31];
        else if (xMuli) mul_sign <= a[31] ^ imm[31];
        else if (xMulsu) mul_sign <= a[31];
        else if (xMulsui) mul_sign <= a[31];
        else mul_sign <= 1'b0;  // MULU, MULUI
        if (xMul) aa <= fnAbs(a);
        else if (xMuli) aa <= fnAbs(a);
        else if (xMulsu) aa <= fnAbs(a);
        else if (xMulsui) aa <= fnAbs(a);
        else aa <= a;
        if (xMul) bb <= fnAbs(b);
        else if (xMuli) bb <= fnAbs(imm);
        else if (xMulsu) bb <= b;
        else if (xMulsui) bb <= imm;
        else if (xMulu) bb <= b;
        else bb <= imm; // MULUI
        next_state(MUL2);
    end
// Now wait for the three stage pipeline to finish
MUL2:   next_state(MUL3);
MUL3:   next_state(MUL4);
MUL4:   next_state(MUL5);
MUL5:   next_state(MUL9);
MUL9:
    begin
        mul_prod <= mul_sign ? -mul_prod1 : mul_prod1;
        upd_rf <= `TRUE;
        next_state(INVnRUN);
    end
DIV1:
    if (dvd_done) begin
        upd_rf <= `TRUE;
        next_state(INVnRUN);
    end

LOAD1:
    begin
        if ((xRa==regSP || xRa==regBP)&&(ea < sbl || ea > sbu))
            ex_fault(`FLT_STACK,0);
        else begin
    		read1(mem_size,ea);
            next_state(LOAD2);
        end
    end
LOAD2:
    if (err_i) begin
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        wr_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        ex_fault(`FLT_DBE,0);
    end
`ifdef WISHBONE
    else if (ack_i) begin
`else
    else if (rdy_i) begin
`endif
        lres1 = dat_i >> {ea[0],4'h0};
        case(xopcode)
        `LH:
            begin
            vda_o <= `FALSE;
            cyc_o <= `FALSE;
            stb_o <= `FALSE;
            sel_o <= 2'b00;
            lres <= {{16{lres1[15]}},lres1[15:0]};
            upd_rf <= `TRUE;
            next_state(INVnRUN);
            end
        `LHU:
            begin
            vda_o <= `FALSE;
            cyc_o <= `FALSE;
            stb_o <= `FALSE;
            sel_o <= 2'b00;
            lres <= {16'd0,lres1[15:0]};
            upd_rf <= `TRUE;
            next_state(INVnRUN);
            end
        `LW,`LWR:
            begin
            case(ea[0])
            1'b1:   begin
`ifdef WISHBONE                
                    stb_o <= `FALSE;
                    next_state(LOAD2A);
`else                            
                    read2(mem_size,ea);
                    next_state(LOAD3);
`endif                            
                    lres[15:0] <= lres1[15:0];
                end
            default:
                begin  
                $display("Loaded %h from %h", lres1, adr_o);
                lres <= lres1;
                cyc_o <= `FALSE;
                stb_o <= `FALSE;
                vda_o <= `FALSE;
                sel_o <= 8'h00;
                upd_rf <= `TRUE;
                next_state(INVnRUN);
                end 
            endcase
            end
        `MEM:
            case(xir[15:11])
            `RET,`POP:
                case(ea[0])
                1'b1:   begin
`ifdef WISHBONE                
                            stb_o <= `FALSE;
                            next_state(LOAD2A);
`else                            
                            read2(mem_size,ea);
                            next_state(LOAD3);
`endif                            
                            lres[15:0] <= lres1[15:0];
                        end
                default:
                    begin  
                    $display("Loaded %h from %h", lres1, adr_o);
                    lres <= lres1;
                    cyc_o <= `FALSE;
                    stb_o <= `FALSE;
                    vda_o <= `FALSE;
                    sel_o <= 8'h00;
                    upd_rf <= `TRUE;
                    next_state(INVnRUN);
                    end 
                endcase
            endcase
        endcase
        sr_o <= 1'b0;
    end
LOAD2A:
    begin
        read2(mem_size,ea);
        next_state(LOAD3);
    end

// The operation here must be a LW or LWR.
LOAD3:
    if (err_i) begin
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        wr_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        ex_fault(`FLT_DBE,0);
    end
`ifdef WISHBONE
    else if (ack_i) begin
`else
    else if (rdy_i) begin
`endif
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        upd_rf <= `TRUE;
        next_state(INVnRUN);
        lres[31:16] <= dat_i[15:0];
    end

// Invalidate the xir and switch back to the run state.
// The xir is invalidated to prevent the instruction from executing again.
// Also performed is the control flow operations requiring a memory operand.

INVnRUN:
    begin
        inv_xir();
        case (xopcode)
        `CALL,`CALL16,`CALL0:
            if (xRb!=5'd0) begin
                if (xRb==regSP)
                    ex_branch(xpc + imm);
                else
                    ex_branch(b + imm);
            end
        `MEM:
            if (xir[15:11]==`RET)
                ex_branch(lres);
        endcase
        next_state(RUN);
    end

STORE1:
    begin
        if ((xRa==regSP || xRa==regBP)&&(ea < sbl || ea > sbu))
            ex_fault(`FLT_STACK,0);
        else begin
            write1(mem_size,ea,xb);
            $display("Store to %h <= %h", ea, xb);
            next_state(STORE2);
        end
    end
STORE2:
    if (err_i) begin
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        wr_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        ex_fault(`FLT_DBE,0);
    end
`ifdef WISHBONE
    else if (ack_i) begin
`else
    else if (rdy_i) begin
`endif
        case(xopcode)
        `CALL,`CALL16,`CALL0:   upd_rf <= `TRUE;
        endcase
        if (mem_size==word && ea[0]!=1'b0) begin
`ifdef WISHBONE
            stb_o <= `FALSE;
            next_state(STORE2A);
`else
            write2(mem_size,ea,xb);
            next_state(STORE3);
`endif
        end
        else begin
            cyc_o <= `FALSE;
            stb_o <= `FALSE;
            vda_o <= `FALSE;
            wr_o <= 1'b0;
            sel_o <= 2'b00;
            next_state(INVnRUN);
        end
        cr_o <= 1'b0;
        msema[0] <= rb_i;
    end
STORE2A:
    begin
        write2(mem_size,ea,xb);
        next_state(STORE3);
    end
STORE3:
    if (err_i) begin
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        wr_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        ex_fault(`FLT_DBE,0);
    end
`ifdef WISHBONE
    else if (ack_i) begin
`else
    else if (rdy_i) begin
`endif
        cyc_o <= `FALSE;
        stb_o <= `FALSE;
        vda_o <= `FALSE;
        wr_o <= 1'b0;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        next_state(INVnRUN);
    end

LOAD_ICACHE:
    begin
        if (icmf != 2'b11) begin
            isICacheLoad <= `TRUE;
            if (icmf[1]) begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                vpa_o <= `TRUE;
                adr_o <= {pcp8[31:3],3'b000};
                icmf[0] <= 1'b1;
            end
            else begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                vpa_o <= `TRUE;
                icmf[1] <= 1'b1;
                adr_o <= {pc[31:3],3'b000};
            end
            next_state(LOAD_ICACHE2);
        end
        else
            next_state(RUN);
    end
LOAD_ICACHE2:
`ifdef WISHBONE
    if (ack_i) begin
`else
    if (rdy_i) begin
`endif
`ifdef WISHBONE
        stb_o <= `FALSE;
        next_state(LOAD_ICACHE3);
`endif
        adr_o[2:1] <= adr_o[2:1] + 2'd1;
        if (adr_o[2:1]==2'b11) begin
            isICacheLoad <= `FALSE;
            cyc_o <= `FALSE;
            vpa_o <= `FALSE;
            next_state(icmf==2'b11 ? RUN : LOAD_ICACHE);
        end
    end
LOAD_ICACHE3:
    begin
        stb_o <= `TRUE;
        next_state(LOAD_ICACHE2);
    end
default:
    next_state(RUN);
endcase

end


// We don't really need to NOP out a 64 bit register in several places when a 
// single bit indicating invalid status will do. Saves about 200LUTs.

task inv_ir();
begin
    dinv <= `TRUE;
    //ir <= `_2NOP_INSN;
end
endtask

task inv_xir();
begin
    xinv <= `TRUE;
    //xir <= `_2NOP_INSN;
    xRt <= 5'd0;
    xRt2 <= 1'b0;
end
endtask


// All faulting instructions perform a branch back to themselves. However the
// INT instruction is fed into the instruction stream at that point. The INT
// instruction does another branch through the interrupt table. Meaning it 
// takes the hardware about six clock cycles to process faults.
// Since *all* faults use this mechanism exceptions should still remain
// precise.
// Note that a prior fault overrides an incoming interrupt request.

task ex_fault;
input [8:0] ccd;        // cause code
input nib;              // next instruction bit
begin
    stuff_fault <= `TRUE;
    fault_insn <= { nib, ccd, `INT};
    ex_branch(xpc);
    next_state(RUN);
end
endtask

task ex_branch;
input [31:0] nxt_pc;
begin
    inv_ir();
    inv_xir();
    pc <= nxt_pc;
end
endtask

// CALL: - if no register Ra was specified then the CALL is done already
//        by the IFETCH stage. Otherwise we need to branch.
task ex_call;
input [31:0] ant;
begin
    begin
        if (a-32'd2 < sbl)
            ex_fault(`FLT_STACK,0);
        else begin
            mem_size <= word;
            ea <= a - 32'd2;
            xb <= xpc + ant;
            next_state(STORE1);
        end
    end
end
endtask

task read1;
input [1:0] sz;
input [31:0] adr;
begin
    cyc_o <= `TRUE;
    stb_o <= `TRUE;
	vda_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	half:
		case(adr[0])
		1'd0: sel_o <= 2'b01;
		1'd1: sel_o <= 2'b10;
		endcase
	word:
        case(adr[0])
        1'd0: sel_o <= 2'b11;
        1'd1: begin sel_o <= 2'b10; lock_o <= `TRUE; end
        endcase
    endcase
    if (xopcode==`LWR)
        sr_o <= 1'b1;
end
endtask

task read2;
input [1:0] sz;
input [31:0] adr;
begin
    cyc_o <= `TRUE;
    stb_o <= `TRUE;
	vda_o <= 1'b1;
	adr_o <= {adr[31:1]+31'd1,1'b0};
	sel_o <= 2'b01;
end
endtask

task write1;
input [1:0] sz;
input [31:0] adr;
input [31:0] dat;
begin
    cyc_o <= `TRUE;
    stb_o <= `TRUE;
	vda_o <= 1'b1;
	wr_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	half:
	    begin
	        dat_o <= {2{dat[15:0]}};
	        case(adr[0])
            1'd0: sel_o <= 2'b01;
            1'd1: sel_o <= 2'b10;
	        endcase
	    end
    word:
        begin
            case(adr[0])
            1'd0: begin sel_o <= 2'b11; dat_o <= dat; end
            1'd1: begin sel_o <= 2'b10; dat_o <= {2{dat[15:0]}}; lock_o <= `TRUE; end
            endcase
        end
	endcase
	if (xopcode==`SWC)
	   cr_o <= 1'b1;
end
endtask

task write2;
input [1:0] sz;
input [31:0] adr;
input [31:0] dat;
begin
    cyc_o <= `TRUE;
    stb_o <= `TRUE;
    vda_o <= `TRUE;
    wr_o <= 1'b1;
    adr_o <= {adr[31:1]+31'd1,1'b0};
    sel_o <= 2'b01;
    dat_o <= {2{dat[31:16]}};
end
endtask


// This task makes it possible to place debugging information at the point of
// a state transition.

task next_state;
input [5:0] st;
begin
  state <= st;
end
endtask

task read_csr;
input [13:0] csrno;
output [31:0] res;
begin
    case(csrno[11:0])
    `CSR_HARTID:    res = hartid_i;
    `CSR_TICK:      res = tick;
    `CSR_VBA:       res = vba;
    `CSR_PCR:       res = pcr;
    `CSR_CAUSE:     res = mcause;
    `CSR_SCRATCH:   res = scratch;
    `CSR_SBL:       res = sbl;
    `CSR_SBU:       res = sbu;
    `CSR_TASK:      res = tr;
    `CSR_CISC:      res = cisc;
    `CSR_SEMA:      res = msema;
    `CSR_ITOS0:    res = itos[31:0];
    `CSR_ITOS1:    res = itos[63:32];
    `CSR_ITOS2:    res = itos[95:64];
    `CSR_ITOS3:    res = itos[127:96];
    `CSR_ITOS4:    res = itos[128];
    `CSR_CONFIG:    res = mconfig;
    `CSR_CAP:       res = cap;
    default:    res = 32'hDEADDEAD;
    endcase
end
endtask

task write_csr;
input [1:0] op;
input [13:0] csrno;
input [31:0] dat;
begin
    case(op)
    `CSRRW:
        case(csrno[11:0])
        `CSR_HARTID:    ;
        `CSR_VBA:       vba <= dat;
        `CSR_PCR:       pcr <= dat;
        `CSR_CAUSE:     mcause <= dat;
        `CSR_SCRATCH:   scratch <= dat;
        `CSR_SBL:       sbl <= dat;
        `CSR_SBU:       sbu <= dat;
        `CSR_TASK:      tr <= dat;
        `CSR_CISC:      cisc <= dat;
        `CSR_SEMA:     msema <= dat;
        `CSR_ITOS0:    itos[31:0] <= dat;
        `CSR_ITOS1:    itos[63:32] <= dat;
        `CSR_ITOS2:    itos[95:64] <= dat;
        `CSR_ITOS3:    itos[127:96] <= dat;
        `CSR_ITOS4:    itos[128] <= dat[0];
        `CSR_CONFIG:    mconfig <= dat;
        endcase
    `CSRRS:
        case(csrno[11:0])
        `CSR_PCR:       pcr <= pcr | dat;
        `CSR_SEMA:      msema <= msema | dat;
        endcase
    `CSRRC:
        case(csrno[11:0])
        `CSR_PCR:       pcr <= pcr & ~dat;
        `CSR_SEMA:      msema <= msema & ~dat;
        endcase
    endcase
end
endtask


// The register file is updated outside of the state case statement.
// It could be updated potentially on every clock cycle as long as
// upd_rf is true.

task update_regfile;
begin
    if (upd_rf) begin
        if (xRt2)
            sp <= res;
        case(xRt)
        5'd1:   r1 <= res;
        5'd2:   r2 <= res;
        5'd29:  r29 <= res;
        regSP:  sp <= res;
        endcase
        regfile[xRt] <= res;
        $display("regfile[%d] <= %h", xRt, res);
        // Globally enable interrupts after first update of stack pointer.
        if (xRt==regSP)
            gie <= `TRUE;
    end
end
endtask

endmodule
