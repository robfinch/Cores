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
`define CAP_FP  1'b1

`define SIMULATION
`define VBA_VECT    32'hFFFC00E0
`define RST_VECT    32'hFFFC0000

`define FBcc    6'h01
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
`define CHKI    6'h0E
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
`define INC     6'h24
`define LEA     6'h25
`define LFx     6'h26
`define SFx     6'h27
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
`define FLOAT   6'h36
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
`define INCX    6'h24
`define LEAX    6'h25
`define LFxX    6'h26
`define SFxX    6'h27
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
`define FPUSHS0 5'h10
`define FPUSHS1 5'h11
`define FPUSHQ0 5'h16
`define FPUSHQ1 5'h17
`define FPOPS0  5'h18
`define FPOPS1  5'h19
`define FPOPQ0  5'h1E
`define FPOPQ1  5'h1F

// Float instructions
`define FCMP    3'd1
`define FADD    3'd4
`define FSUB    3'd5
`define FMUL    3'd6
`define FDIV    3'd7

`define FMOV    6'h00
`define FTOI    6'h02
`define ITOF    6'h03
`define FNEG    6'h04
`define FABS    6'h05
`define FSIGN   6'h06
`define FMAN    6'h07
`define FNABS   6'h08

`define FTX     6'h10
`define FCX     6'h11
`define FEX     6'h12
`define FDX     6'h13
`define FRM     6'h14

`define _2NOP_INSN    {10'h0,`NOP,10'h0,`NOP}

`define CSRRW     2'b00
`define CSRRS     2'b01
`define CSRRC     2'b10

`define CSR_HARTID  12'h001
`define CSR_TICK    12'h002
`define CSR_PCR     12'h003
`define CSR_VBA     12'h004
`define CSR_EXROUT  12'h005
`define CSR_CAUSE   12'h006
`define CSR_BADADDR 12'h007
`define CSR_SCRATCH 12'h009
`define CSR_SEMA    12'h00C
`define CSR_SBL     12'h00E
`define CSR_SBU     12'h00F
`define CSR_TASK    12'h010
`define CSR_CISC    12'h011
`define CSR_FPSTATS 12'h013
`define CSR_FPSTATQ 12'h016
`define CSR_FPHOLD0 12'h018
`define CSR_FPHOLD1 12'h019
`define CSR_FPHOLD2 12'h01A
`define CSR_FPHOLD3 12'h01B
`define CSR_ITOS0   12'h040
`define CSR_ITOS1   12'h041
`define CSR_ITOS2   12'h042
`define CSR_ITOS3   12'h043
`define CSR_ITOS4   12'h044
`define CSR_PCHIST  12'h100
`define CSR_PCHNDX  12'h101
`define CSR_CONFIG  12'hFF0
`define CSR_CAP     12'hFFE

`define FLT_FLT     9'd486
`define FLT_CHK     9'd487
`define FLT_DBZ     9'd488
`define FLT_STACK   9'd504
`define FLT_DBE     9'd508

`define regXLR      5'd28
`define regBP       5'd30
`define regSP       5'd31

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

parameter FLT_WID = 128;

parameter half = 2'b10;
parameter word = 2'b11;

// State machine states
parameter RUN = 6'd1;
parameter INC1 = 6'd2;
parameter ICACHE_RST1 = 2'd3;
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
parameter FLOAT1 = 6'd40;
parameter FLOAT2 = 6'd41;
parameter FLOAT3 = 6'd42;

integer n;
reg [5:0] state;
reg [127:0] stname;         // pretty name for state (simulation)
reg [63:0] imne,dmne,xmne;
reg [7:0] fpcnt;
wire advanceEX;
wire advanceRF;
wire advanceIF;
reg [1:0] ol = 2'b00;       // operating level (machine only)
reg [31:0] pc,dpc,xpc;
reg [31:0] pc_inc;
reg [63:0] insn,iinsn;
reg [63:0] ir,xir,mir,fir;
reg [15:0] fault_insn;
reg stuff_fault;
reg ii32,ii5a;
wire ii5;
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
reg [31:0] r1,r2,r28;
reg [31:0] regfile [0:31];
reg [31:0] sp;
reg [31:0] rfoa,rfob,rfoc;
reg [31:0] a,b,c,imm,ea,xb;
reg [31:0] res,lres,lres1,res2;
reg [127:0] fpa1,fpb;
wire takb,takfb;
reg [31:0] br_disp,fbr_disp;
wire [31:0] logic_o, shift_o;
reg [1:0] mem_size;
reg upd_fp;
reg upd_rf;                     // flag indicates to update register file
reg xinv,dinv;                  // invalidate flags for pipeline stages
reg [3:0] fplsst;               // load store state for fp
// CSR's
reg [31:0] tick;
reg [31:0] msema;
reg [31:0] mexrout;
reg [31:0] mcause;
reg [31:0] mbadaddr;
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
reg [31:0] sbl, sbu;
reg [127:0] fphold;
wire [31:0] pc_hist;
reg [5:0] pchndx;

assign pcr_o = pcr;

// Program counter history shift register
vtdl #(.WID(32),.DEP(64)) uvtd1
(
    .clk(clk_i),
    .ce(~im),
    .a(pchndx),
    .d(pc),
    .q(pc_hist)
);

`ifdef SIMULATION
initial begin
    a <= 0;
    b <= 0;
    c <= 0;
    for (n = 0; n < 32; n=n+1)
        regfile[n] <= 0;
    r1 <= 0;
    r2 <= 0;
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
    5'd28:  fwd_mux = r28;
    5'd31:  if (xRt2)
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
`LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,`PEA,`INC,
`LFx,`SFx,`FLOAT,
`MEM,`CALL,`CALL16,`CALL0:
    xIsMC = `TRUE;
`R2:
    case(xr[31:26])
    `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH,
    `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU,
    `LHX,`LHUX,`LWX,`LWRX,`SHX,`SWX,`SWCX:
    xIsMC = `TRUE;
    default:    xIsMC = `FALSE;
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

`ifdef CAP_FP
DSD7_FPBranchEval #(FLT_WID) ufbeval
(
    .xir(xir[31:0]),
    .a(fpa1),
    .b(fpb),
    .takb(takfb)
);
`endif

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
wire dvByZr;
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
	.dvByZr(dvByZr),
	.done(dvd_done),
	.idle()
);

wire [FLT_WID-1:0] fpu_o;
wire [FLT_WID-1:0] fpus_o;

always @*
begin
    case(xopcode)
    `R2:
        case(xfunct)
        `ADD:   res = a + b;
        `LEAX:  res = a + b;
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
        `ROL:   res = (CAP_ROTATES ? shift_o : 32'hDEADDEAD);
        `ROR:   res = (CAP_ROTATES ? shift_o : 32'hDEADDEAD);
        `SHLI:  res = shift_o;
        `SHRI:  res = shift_o;
        `ASRI:  res = shift_o;
        `ROLI:  res = (CAP_ROTATES ? shift_o : 32'hDEADEAD);
        `RORI:  res = (CAP_ROTATES ? shift_o : 32'hDEADEAD);
        `SXB:   res = {{24{a[7]}},a[7:0]};
        `SXH:   res = {{16{a[15]}},a[15:0]};
        `R2CSR,`R2CSRI: read_csr(b[13:0],res);
        `MUL:   res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
        `MULU:  res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
        `MULSU: res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
        `MULH:  res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
        `MULUH: res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
        `MULSUH:res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
        `DIV:   res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
        `DIVU:  res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
        `DIVSU: res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
        `REM:   res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
        `REMU:  res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
        `REMSU: res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
        `LHX,`LHUX,`LWX,`LWRX:  res = (CAP_LS_NDX ? lres : 32'hDEADDEAD);
        default:    res = 32'hDEADDEAD;
        endcase
    `ADDI:  res = a + imm;
    `LEA:   res = a + imm;
    `CHKI:  res = (a >= b) && (a < imm);
    `CMPI:  res = ($signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1);
    `CMPUI: res = (a < imm ? -1 : a==imm ? 0 : 1);
    `ANDI:  res = logic_o;
    `ORI:   res = logic_o;
    `ORI32: res = logic_o;
    `XORI:  res = logic_o;
    `MULI:   res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
    `MULUI:  res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
    `MULSUI: res = (CAP_MULDIV ? mul_prod[31:0] : 32'hDEADDEAD);
    `MULHI:  res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
    `MULUHI: res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
    `MULSUHI:res = (CAP_MULDIV ? mul_prod[63:32] : 32'hDEADDEAD);
    `DIVI:   res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
    `DIVUI:  res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
    `DIVSUI: res = (CAP_MULDIV ? qo : 32'hDEADDEAD);
    `REMI:   res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
    `REMUI:  res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
    `REMSUI: res = (CAP_MULDIV ? ro : 32'hDEADDEAD);
    `JMP:       res = xpc + 32'd3;
    `JMP16:     res = xpc + 32'd2;
    `MOV:   res = a;
    `CSR,`CSRI: read_csr(xir[31:18],res);
    `MEM:
        case (xir[15:11])
        `RET:       res = a + imm;
        `PUSHI5,
        `FPUSHS0,`FPUSHS1,
        `PUSH:      res = a - 32'd2;
        `FPUSHQ0,`FPUSHQ1:     res = a - 32'd8;
        `POP:       res = lres;
        default:    res = 32'hDEADDEAD;
        endcase
    `LH,`LHU,`LW,`LWR:  res = lres;
    `PEA:       res = a - 32'd2;
    `CALL:      res = a - 32'd2;
    `CALL16:    res = a - 32'd2;
    `CALL0:     res = a - 32'd2;
    `FLOAT:     res = fpu_o[31:0];
    default:    res = 32'hDEADDEAD;
    endcase
end

// The only instruction using result bus #2 is the pop instruction.
// Save some decoding.
always @*
    case(xopcode)
    `MEM:
        case(xir[15:11])
        `FPOPQ0,`FPOPQ1:
                    res2 <= a + 32'd8;
        `FPOPS0,`FPOPS1:
                    res2 <= a + 32'd2;
        default:    res2 <= a + 32'd2;
        endcase
    default:    res2 <= a + 32'd2;
    endcase
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

reg xldfp;
reg [FLT_WID-1:0] fres;
reg [FLT_WID-1:0] fp_in,fp_out;
reg [FLT_WID-1:0] fpregs [0:63];
wire [5:0] FRa = ir[11:6];
wire [5:0] FRb = opcode==`SFx ? ir[23:18] : (opcode==`MEM) ? ir[11:6] : ir[17:12];
reg [5:0] xFRt;
`ifdef CAP_FP
always @(posedge clk_i)
if (advanceRF && (opcode==`FLOAT || opcode==`FBcc || opcode==`SFx || (opcode==`MEM &&
    (ir[15:11]==`FPUSHQ0 || ir[15:11]==`FPUSHQ1 || ir[15:11]==`FPUSHS0 || ir[15:11]==`FPUSHS1)))) begin
    fir <= ir;
    case(FRa)
    6'd0:   fpa1 <= 0;
    xFRt:   fpa1 <= fres;
    6'd63:  fpa1 <= fphold;
    default: fpa1 <= fpregs[FRa];
    endcase
    case(FRb)
    6'd0:   fpb <= 0;
    xFRt:   fpb <= fres;
    6'd63:  fpb <= fphold;
    default: fpb <= fpregs[FRb];
    endcase
end
always @(posedge clk_i)
    if (upd_fp)
        fpregs[xFRt] <= fres;

wire [127:0] fpa = 
    (fir[5:0]==`FLOAT && fir[31:29]==3'b00 &&
        (fir[17:12]==`FTX || fir[17:12]==`FCX || fir[17:12]==`FDX || fir[17:12]==`FEX || fir[17:12]==`FRM))
        ? a : fpa1;
wire [31:0] fpstatus,fpstatuss;
wire fpdone,fpdones;

fpUnit #(FLT_WID) ufp1
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .ir(fir[31:0]),
    .ld(xldfp),
    .a(fpa),
    .b(fpb),
    .imm(fir[23:18]),
    .o(fpu_o),
    .status(fpstatus),
    .exception(),
    .done(fpdone)
);

`ifdef CAP_SIMD
fpUnit #(32) ufp2
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .ir(fir[31:0]),
    .ld(xldfp),
    .a(fpa[31:0]),
    .b(fpb[31:0]),
    .imm(fir[23:18]),
    .o(fpus_o[31:0]),
    .status(fpstatuss),
    .exception(),
    .done(fpdones)
);

fpUnit #(32) ufp3
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .ir(fir[31:0]),
    .ld(xldfp),
    .a(fpa[63:32]),
    .b(fpb[63:32]),
    .imm(fir[23:18]),
    .o(fpus_o[63:32]),
    .status(),
    .exception(),
    .done()
);

fpUnit #(32) ufp4
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .ir(fir[31:0]),
    .ld(xldfp),
    .a(fpa[95:64]),
    .b(fpb[95:64]),
    .imm(fir[23:18]),
    .o(fpus_o[95:64]),
    .status(),
    .exception(),
    .done()
);

fpUnit #(32) ufp5
(
    .rst(rst_i),
    .clk(clk_i),
    .ce(1'b1),
    .ir(fir[31:0]),
    .ld(xldfp),
    .a(fpa[127:96]),
    .b(fpb[127:96]),
    .imm(fir[23:18]),
    .o(fpus_o[127:96]),
    .status(),
    .exception(),
    .done()
);
`endif

always @*
    if (xopcode==`LFx || xopcode==`MEM &&
        (xir[15:11]==`FPOPQ0 || xir[15:11]==`FPOPQ1 || xir[15:11]==`FPOPS0 || xir[15:11]==`FPOPS1))
        fres <= fp_in;
    else if (xir[28:27]==2'b00)
        fres <= fpus_o;
    else
        fres <= fpu_o;
`endif

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
    if ((isICacheReset|isICacheLoad) && ack_i) begin
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
    if (adr_o[2:1]==2'b11 && ack_i) begin
        if (isICacheReset|isICacheLoad)
            tag_mem[adr_o[10:3]] <= adr_o;
    end

// Set tag comparators, there would be only four for a four-way set associative
// cache, but we need to check two cache lines in case the instruction spans a
// cache lines. Hence there are four pairs of comparators.
wire ihit1 = pc[31:11]==tag_mem[pc[10:3]][31:11];
wire ihit2 = pcp8[31:11]==tag_mem[pcp8[10:3]][31:11];
wire ihit = (ihit1 && ihit2);

`endif

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
assign advanceEX = !xIsMC(xir);
assign advanceRF = advanceEX | xinv;
assign advanceIF = (advanceRF | dinv) & (ihit && !isICacheLoad);

// This combo logic moved out to here as the simulator didn't like all the
// blocking assignments.
 
reg [3:0] fnPCInc;
always @(iinsn)
case(iinsn[5:0])
`LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,`INC,`LEA,
`MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI,
`DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI,
`ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`CHKI,
`PEA:
    fnPCInc <= iinsn[31:26]==6'h20 ? 32'd4 : 32'd2;
`FBcc:  fnPCInc <= 32'd2;
`Bcc:   fnPCInc <= 32'd2;
`BccU:  fnPCInc <= 32'd2;
`BccI:  fnPCInc <= iinsn[15:11]==5'h10 ? 32'd4 : 32'd2;
`BccUI:  fnPCInc <= iinsn[15:11]==5'h10 ? 32'd4 : 32'd2;
`LFx,`SFx:  fnPCInc <= iinsn[15:11]==5'h10 ? 32'd4 : 32'd2;
`NOP,`CINSN:
    fnPCInc <= 32'd1;
`CSRI:  fnPCInc <= iinsn[10:6]==5'h10 ? 32'd4 : 32'd2;
`CSR:   fnPCInc <= 32'd2;
`R2:
    case(iinsn[31:26])
    `R2CSRI:  fnPCInc <= iinsn[10:6]==5'h10 ? 32'd4 : 32'd2;
    default:    fnPCInc <= 32'd2;
    endcase
`MEM:
    case(iinsn[15:11])
    `RET,`PUSHI5:   fnPCInc <= iinsn[10:6]==5'h10 ? 32'd3 : 32'd1;
    default:    fnPCInc <= 32'd1;
    endcase
`JMP,`CALL,`ORI32: fnPCInc <= 32'd3;
`JMP16,`CALL16: fnPCInc <= 32'd2;
`CALL0: fnPCInc <= 32'd1;
`FLOAT: fnPCInc <= 32'd2;
default:    fnPCInc <= 32'd1;
endcase


// A stuffed fault will have occurred earlier than a pending IRQ
// hence takes precedence.
always@*
    if (stuff_fault)
        iinsn <= {16'd0,fault_insn};
    else if (irq_i & ~im & gie)
        iinsn <= {17'd0,icause_i,`INT};
    else
        iinsn <= insn[5:0]==`CINSN ? cinsn : insn;

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
xldfp <= `FALSE;
upd_fp <= `FALSE;
upd_rf <= `FALSE;
tick <= tick + 32'd1;
update_regfile();
if (upd_fp) begin
    if (xFRt==6'd63)
        fphold <= fres;
end

case(state)
ICACHE_RST:
`ifdef WISHBONE
    if (ack_i) begin
        stb_o <= `FALSE;
        next_state(ICACHE_RST1);
`else
    if (rdy_i) begin
`endif
        if (adr_o[10:1]==10'h3FF) begin
            isICacheReset <= `FALSE;
            cyc_o <= `FALSE;
            stb_o <= `FALSE;
            vpa_o <= `FALSE;
            sel_o <= 2'b00;
            next_state(RUN);
        end
    end
ICACHE_RST1:
    begin
        stb_o <= `TRUE;
        adr_o <= adr_o + 32'd2;
        next_state(ICACHE_RST);
    end
RUN:
begin
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // IFETCH stage
    // We want decodes in the IFETCH stage to be fast so they don't appear
    // on the critical path.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceIF) begin
        if (stuff_fault)
            stuff_fault <= `FALSE;

        disassem(iinsn,imne);
        if (iopcode==`INT) begin
            Ra <= 5'd31;
            Rb <= 5'd1;
            Rc <= 5'd2;
        end
        else if (iinsn[5:0]==`PEA || iinsn[5:0]==`CALL || iinsn[5:0]==`CALL16 || iinsn[5:0]==`CALL0 ||
            (iinsn[5:0]==`MEM && 
                (iinsn[15:11]==`RET || iinsn[15:11]==`PUSH || iinsn[15:11]==`POP || iopcode==`PUSHI5 ||
                iinsn[15:11]==`FPUSHQ0 || iinsn[15:11]==`FPUSHQ1 || iinsn[15:11]==`FPOPQ0 || iinsn[15:11]==`FPOPQ1 ||
                iinsn[15:11]==`FPUSHS0 || iinsn[15:11]==`FPUSHS1 || iinsn[15:11]==`FPOPS0 || iinsn[15:11]==`FPOPS1
                ))) begin
            Ra <= 5'd31;
            Rb <= iinsn[10:6];
            Rc <= iinsn[15:11];
        end
        else begin
            Ra <= iinsn[10:6];
            Rb <= iinsn[15:11];
            Rc <= iinsn[20:16];
        end
        // The INT is going to do a jump anyways os the PC increment
        // shouldn't matter.
//        if ((irq_i & ~im & gie) || stuff_fault)
//            pc_inc = 32'd1;
//        else
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
        pc <= pc + fnPCInc;
        i32 <= iinsn[31:26]==6'h20;
        i5 <= iinsn[15:11]==5'h10;
        i5a <= iinsn[10:6]==5'h10;
        ir <= iinsn;
        dinv <= `FALSE;
        dpc <= pc;
    end
    else begin
        if (advanceRF) begin
            inv_ir();
            dpc <= pc;
            pc <= pc;
        end
        if (!ihit) begin
            icmf <= {ihit1,ihit2};
            pc <= pc;
            next_state(LOAD_ICACHE);
        end
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
        disassem(ir,dmne);
        xinv <= dinv;
        xir <= ir;
        xpc <= dpc;
        a <= fwd_mux(Ra);
        b <= fwd_mux(Rb);
        c <= fwd_mux(Rc);
        xldfp <= `TRUE;
        // Suppress register file update if RF stage is invalid.
        case({dinv,opcode})
        `R2:
            case(funct)
            `LEAX,
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR,
            `SHL,`SHR,`ASR,`ROL,`ROR,
            `SHLI,`SHRI,`ASRI,`ROLI,`RORI:  upd_rf <= `TRUE;
            `R2CSR,`R2CSRI:    upd_rf <= `TRUE;
            endcase
//        `MEM:   upd_rf <= `TRUE;
        `MOV,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`ORI32,`LEA:
            upd_rf <= `TRUE;
        `CSR,`CSRI:  upd_rf <= `TRUE;
        `JMP,`JMP16:    upd_rf <= `TRUE;
        `FLOAT:
            case(ir[31:29])
            `FCMP:  upd_rf <= `TRUE;
            endcase
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
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`CHKI,
        `LH,`LHU,`LW,`LWR,`SH,`SW,`SWC,`PEA,`INC,`LEA:
            imm <= i32 ? ir[63:32] : {{16{ir[31]}},ir[31:16]};
        `BccI,`BccUI:  imm <= i5 ? ir[63:32] : {{27{ir[15]}},ir[15:11]};
        `LFx,`SFx:     imm <= i5 ? ir[63:32] : {{27{ir[15]}},ir[15:11]};
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
            `RET:       imm <= i5a ? ir[47:16] : {{27{ir[10]}},ir[10:6]};
            `PUSHI5:    imm <= i5a ? ir[47:16] : {{27{ir[10]}},ir[10:6]};
            default:    imm <= {{27{ir[10]}},ir[10:6]};
            endcase
        default:    imm <= 32'h0;
        endcase
        // Branch displacement, used only for conditional branches.
        // Branches may also compare against an immediate so the displacement
        // has to be determined separately. 
        br_disp <= {{19{ir[31]}},ir[31:19]};
        fbr_disp <= {{23{ir[31]}},ir[31:29],ir[26:21]};
        // Needed for CSR instructions
        xRa <= Ra;
        xRb <= Rb;  // needed for calls/jumps
        // Set target register
        xRt <= 5'd0;
        xRt2 <= 1'b0;
        xFRt <= 6'd0;
        if (!dinv)
        case(opcode)
        `R2:
            case(funct)
            `R2CSR,`R2CSRI,
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR,
            `SHL,`SHR,`ASR,`ROL,`ROR,
            `SHLI,`SHRI,`ASRI,`ROLI,`RORI,
            `LEAX:
                xRt <= ir[20:16];
            default:
                xRt <= 5'd0;
            endcase
        `MOV,`CSR,`CSRI,
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,`ORI32,
        `LEA:
            xRt <= ir[15:11];
        `JMP,`JMP16:    xRt <= ir[15:11];
        default:
            xRt <= 5'd0;
        endcase
    end
    else if (advanceEX)
        inv_xir();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // If the execute stage has been invalidated it doesn't do anything. 
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (!xinv) begin
        disassem(xir,xmne);
        case(xopcode)
        // CHK should not be directly preceeded by a load of the XLR (reg 28)
        // because it doesn't respect results forwarding. In the case of 
        // compiler generated code this should be okay.
        `CHKI:
            if (~res[0]) begin
                if (mexrout[0]) begin
                    r1 <= `FLT_CHK;  // 487 = bounds check
                    r2 <= 32'd24;   // type: exception
                    ex_branch(r28);
                end
                else
                    ex_fault(`FLT_CHK,0);
            end
 
        // INT uses ex_branch() to flush the pipeline of extra INT instructions
        // which stream into core until interrupts are masked here.
        `INT:
            begin
                mcause <= xir[14:6];
                itos <= {im,c,b,a,xpc+xir[15]};
                im <= `TRUE;
                msema[0] <= 1'b0;
                ex_branch(vba+{ol,6'h00});
            end
        
        `JMP,`JMP16:
                //if (xRa!=5'd0) begin
                    if (xRa==5'd31)
                       ex_branch(xpc + imm);
                    else
                        ex_branch(a + imm);
                //end
        `CALL:      ex_call(32'd3);
        `CALL16:    ex_call(32'd2);
        `CALL0:     ex_call(32'd1);

        `Bcc,`BccU,
        `BccI,`BccUI:
            if (takb)
                ex_branch(xpc + br_disp);
        `FBcc:
            if (takfb)
                ex_branch(xpc + fbr_disp);

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
                        xb <= c;
                        next_state(STORE1);
                    end
                end
            `SWX,`SWCX:
                if (CAP_LS_NDX) begin
                    begin
                        mem_size <= word;
                        ea <= a + b;
                        xb <= c;
                        next_state(STORE1);
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
                sp <= {itos[63:33],1'b0};
                r1 <= itos[95:64];
                r2 <= itos[127:96];
                im <= 1'b0;//itos[128];
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
`ifdef CAP_FP                
            `FPUSHQ0,`FPUSHQ1:
                if (a - 32'd2 < sbl)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a - 32'd8;
                    xb <= fpb[31:0];
                    fplsst <= 4'h0;
                    next_state(STORE1);
                end
            `FPUSHQ0,`FPUSHQ1:
                if (a - 32'd8 < sbl)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a - 32'd8;
                    xb <= fpb[31:0];
                    fplsst <= 4'h0;
                    next_state(STORE1);
                end
            `FPOPS0,`FPOPS1,
            `FPOPQ0,`FPOPQ1:
                if (a > sbu)
                    ex_fault(`FLT_STACK,0);
                else begin
                    mem_size <= word;
                    ea <= a;
                    fplsst <= 4'h0;
                    next_state(LOAD1);
                end
`endif                
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
        `LW,`LWR,`INC:
            begin
                mem_size <= word;
                ea <= a + imm;
                next_state(LOAD1);
            end
`ifdef CAP_FP
        `LFx:
            begin
                mem_size <= word;
                if (xir[31:29]==3'd0)
                    ea <= a + imm;
                else
                    ea <= a + b;
                fplsst <= 4'h0;
                next_state(LOAD1);
            end
`endif
        `SH:
            begin
                mem_size <= half;
                ea <= a + imm;
                xb <= b;
                next_state(STORE1);
            end
        `SW,`SWC:
            begin
                mem_size <= word;
                ea <= a + imm;
                xb <= b;
                next_state(STORE1);
            end
`ifdef CAP_FP
        `SFx:
            begin
                mem_size <= word;
                if (xir[31:29]==3'd0)
                    ea <= a + imm;
                else
                    ea <= a + b;
                xb <= fpb[31:0];
                fplsst <= 4'h0;
                next_state(STORE1);
            end
`endif
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
`ifdef CAP_FP        
        `FLOAT: 
                if (xir[31:29]== 3'b0 && xir[17:12]==6'd1)
                begin
                    mem_size <= word;
                    ea <= xpc + 32'd2;
                    fplsst <= 4'h0;
                    next_state(LOAD1);
                end
                else
                    next_state(FLOAT1);
`endif
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
        case(xopcode)
        `MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI:
            xRt <= xir[15:11];
        `R2:
            case(xfunct)
            `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH:
                xRt <= xir[20:16];
            endcase
        endcase
        upd_rf <= `TRUE;
        next_state(INVnRUN);
    end

DIV1:
    if (dvd_done) begin
        case(xopcode)
        `DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI:
            xRt <= xir[15:11];
        `R2:
            case(xfunct)
            `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
                xRt <= xir[20:16];
            endcase
        endcase
        upd_rf <= `TRUE;
        next_state(INVnRUN);
        if (dvByZr & mexrout[3]) begin
            if (mexrout[2]) begin
                r1 <= `FLT_DBZ;
                r2 <= 32'd24;
                ex_branch(r28);
            end
            else begin
                ex_fault(`FLT_DBZ,0);
            end
        end
    end

FLOAT1:
    if (fpdone) begin
        case(xir[31:29])
        3'd0:
            case(xir[17:12])
            `FABS,`FMAN,`FMOV,`FNABS,`FNEG,`FSIGN,`FTOI,`ITOF:
            xFRt <= xir[23:18];
            default: xFRt <= 6'd0;
            endcase
        `FCMP:  xRt <= xir[22:18];
        `FADD:  xFRt <= xir[23:18];
        `FSUB:  xFRt <= xir[23:18];
        `FMUL:  xFRt <= xir[23:18];
        `FDIV:  xFRt <= xir[23:18];
        default: xFRt <= 6'd0;
        endcase
        upd_fp <= `TRUE;
        inv_xir();
        next_state(RUN);
        if (fpstatus[9]) begin  // GX status bit
            if (mexrout[1]) begin
                r1 <= `FLT_FLT; // 486 = bounds check
                r2 <= 32'd24;   // type: exception
                ex_branch(r28);
            end
            else begin
                ex_fault(`FLT_FLT,0);
            end
        end
    end

LOAD1:
    begin
        if ((xRa==5'd31 || xRa==5'd30)&&(ea < sbl || ea > sbu))
            ex_fault(`FLT_STACK,0);
        else begin
            if (xopcode==`INC)
                lock_o <= `TRUE;
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
        mbadaddr <= ea;
    end
`ifdef WISHBONE
    else if (ack_i) begin
        stb_o <= `FALSE;
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
            xRt <= xir[15:11];
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
            xRt <= xir[15:11];
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
                xRt <= xir[15:11];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
                end 
            endcase
            end
        `INC:
            begin
            lock_o <= `TRUE;
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
                stb_o <= `FALSE;
                vda_o <= `FALSE;
                sel_o <= 8'h00;
                next_state(INC1);
                end 
            endcase
            end
        `LFx:
            begin
                cyc_o <= `TRUE;
                vda_o <= `TRUE;
                sel_o <= 2'b11;
                case(fplsst)
                4'h0:   begin
                            next_state(LOAD1);
                            if (xir[28:27]==2'b00) begin
                                cyc_o <= `FALSE;
                                vda_o <= `FALSE;
                                sel_o <= 2'b00;
                                xFRt <= xir[23:18];
                                upd_fp <= `TRUE;
                                next_state(INVnRUN);
                            end
                            fp_in[31:0] <= dat_i;
                        end
                4'h1:   begin fp_in[63:32] <= dat_i; next_state(LOAD1); end
                4'h2:   begin fp_in[95:64] <= dat_i; next_state(LOAD1); end
                4'h3:   begin fp_in[127:96] <= dat_i; next_state(INVnRUN);
                        cyc_o <= `FALSE;
                        vda_o <= `FALSE;
                        sel_o <= 2'b00;
                        xFRt <= xir[23:18];
                        upd_fp <= `TRUE;
                        end
                endcase
                fplsst <= fplsst + 4'd1;
                ea <= ea + 32'd2;
            end
        `FLOAT: // FLDI
            begin
                cyc_o <= `TRUE;
                stb_o <= `FALSE;
                vda_o <= `TRUE;
                sel_o <= 2'b11;
                case(fplsst)
                4'h0:   begin
                            fp_in[31:0] <= dat_i;
                            next_state(LOAD1);
                        end
                4'h1:   begin fp_in[63:32] <= dat_i; next_state(LOAD1); end
                4'h2:   begin fp_in[95:64] <= dat_i; next_state(LOAD1); end
                4'h3:   begin fp_in[127:96] <= dat_i; next_state(INVnRUN);
                        cyc_o <= `FALSE;
                        vda_o <= `FALSE;
                        sel_o <= 2'b00;
                        xFRt <= xir[23:18];
                        upd_fp <= `TRUE;
                        end
                endcase
                fplsst <= fplsst + 4'd1;
                ea <= ea + 32'd2;
            end
        `MEM:
            case(xir[15:11])
            `FPOPS0,`FPOPS1:
                begin
                    cyc_o <= `FALSE;
                    stb_o <= `FALSE;
                    vda_o <= `FALSE;
                    sel_o <= 2'b00;
                    fp_in[31:0] <= dat_i;
                    xFRt <= xir[11:6];
                    xRt2 <= 1'b1;
                    upd_fp <= `TRUE;
                    next_state(INVnRUN);
                end
            `FPOPQ0,`FPOPQ1:
                begin
                    cyc_o <= `TRUE;
                    stb_o <= `FALSE;
                    vda_o <= `TRUE;
                    sel_o <= 2'b11;
                    case(fplsst)
                    4'h0:   begin
                                fp_in[31:0] <= dat_i;
                                next_state(LOAD1);
                            end
                    4'h1:   begin fp_in[63:32] <= dat_i; next_state(LOAD1); end
                    4'h2:   begin fp_in[95:64] <= dat_i; next_state(LOAD1); end
                    4'h3:   begin fp_in[127:96] <= dat_i; next_state(INVnRUN);
                            cyc_o <= `FALSE;
                            vda_o <= `FALSE;
                            sel_o <= 2'b00;
                            xFRt <= xir[11:6];
                            xRt2 <= 1'b1;
                            upd_rf <= `TRUE;
                            upd_fp <= `TRUE;
                            end
                    endcase
                    fplsst <= fplsst + 4'd1;
                    ea <= ea + 32'd2;
                end
            
            `POP:
                begin  
                    $display("Popped %h from %h", lres1, adr_o);
                    lres <= lres1;
                    cyc_o <= `FALSE;
                    stb_o <= `FALSE;
                    vda_o <= `FALSE;
                    sel_o <= 8'h00;
                    xRt <= xir[10:6];
                    xRt2 <= 1'b1;
                    upd_rf <= `TRUE;
                    next_state(INVnRUN);
                end 
            `RET:
                begin  
                    $display("Loaded %h from %h", lres1, adr_o);
                    lres <= lres1;
                    cyc_o <= `FALSE;
                    stb_o <= `FALSE;
                    vda_o <= `FALSE;
                    sel_o <= 8'h00;
                    xRt2 <= 1'b1;
                    upd_rf <= `TRUE;
                    next_state(INVnRUN);
                end 
            endcase
        `R2:
            case(xir[31:26])
            `LHX:
                begin
                vda_o <= `FALSE;
                cyc_o <= `FALSE;
                stb_o <= `FALSE;
                sel_o <= 2'b00;
                lres <= {{16{lres1[15]}},lres1[15:0]};
                xRt <= xir[20:16];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
                end
            `LHUX:
                begin
                vda_o <= `FALSE;
                cyc_o <= `FALSE;
                stb_o <= `FALSE;
                sel_o <= 2'b00;
                lres <= {16'd0,lres1[15:0]};
                xRt <= xir[20:16];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
                end
            `LWX,`LWRX:
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
                    xRt <= xir[20:16];
                    upd_rf <= `TRUE;
                    next_state(INVnRUN);
                    end 
                endcase
                end
            `INCX:
                begin
                lock_o <= `TRUE;
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
                    stb_o <= `FALSE;
                    vda_o <= `FALSE;
                    sel_o <= 8'h00;
                    next_state(INC1);
                    end 
                endcase
                end
            `LFxX:
                begin
                    cyc_o <= `TRUE;
                    vda_o <= `TRUE;
                    sel_o <= 2'b11;
                    case(fplsst)
                    4'h0:   begin
                                next_state(LOAD1);
                                if (xir[28:27]==2'b00) begin
                                    cyc_o <= `FALSE;
                                    vda_o <= `FALSE;
                                    sel_o <= 2'b00;
                                    xFRt <= xir[23:18];
                                    upd_fp <= `TRUE;
                                    next_state(INVnRUN);
                                end
                                fp_in[31:0] <= dat_i;
                            end
                    4'h1:   begin fp_in[63:32] <= dat_i; next_state(LOAD1); end
                    4'h2:   begin fp_in[95:64] <= dat_i; next_state(LOAD1); end
                    4'h3:   begin fp_in[127:96] <= dat_i; next_state(INVnRUN);
                            cyc_o <= `FALSE;
                            vda_o <= `FALSE;
                            sel_o <= 2'b00;
                            xFRt <= xir[23:18];
                            upd_fp <= `TRUE;
                            end
                    endcase
                    fplsst <= fplsst + 4'd1;
                    ea <= ea + 32'd2;
                end
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
        mbadaddr <= ea;
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
        if (xopcode==`INC) begin
            cyc_o <= `TRUE;
            sel_o <= 2'b11;
            lock_o <= `TRUE;
            upd_rf <= `FALSE;
            next_state(INC1);
        end
        else begin
            xRt <= xir[15:11];
        end
        lres[31:16] <= dat_i[15:0];
    end

INC1:
    begin
        xb <= lres + {{27{xir[15]}},xir[15:11]};
        next_state(STORE1);
    end

// Invalidate the xir and switch back to the run state.
// The xir is invalidated to prevent the instruction from executing again.
// Also performed is the control flow operations requiring a memory operand.

INVnRUN:
    begin
        inv_xir();
        case (xopcode)
        `CALL,`CALL16,`CALL0:
//            if (xRb!=5'd0) begin
                if (xRb==5'd31)
                    ex_branch(xpc + imm);
                else
                    ex_branch(b + imm);
//            end
        `MEM:
            if (xir[15:11]==`RET)
                ex_branch(lres);
        `FLOAT:
            if (xir[31:29]==3'd0 && xir[17:12]==6'd1)
                ex_branch(xpc + {xir[28:27],1'b0} + 32'd4);
        endcase
        next_state(RUN);
    end

STORE1:
    begin
        if ((xRa==5'd31 || xRa==5'd30)&&(ea < sbl || ea > sbu))
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
        mbadaddr <= ea;
    end
`ifdef WISHBONE
    else if (ack_i) begin
        stb_o <= `FALSE;
`else
    else if (rdy_i) begin
`endif
        case(xopcode)
        `CALL,`CALL16,`CALL0,`PEA:
            begin
                xRt <= 5'd31;    
                upd_rf <= `TRUE;
            end
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
            lock_o <= `FALSE;
            next_state(INVnRUN);
            case(xopcode)
            `SFx:
                begin
                    cyc_o <= `TRUE;
                    vda_o <= `TRUE;
                    sel_o <= 2'b11;
                    case(fplsst)
                    4'h0:   begin
                                xb <= fpb[63:32];
                                next_state(STORE1);
                                if (xir[28:27]==2'b00) begin
                                    next_state(INVnRUN);
                                    cyc_o <= `FALSE;
                                    vda_o <= `FALSE;
                                    sel_o <= 2'b00;
                                end
                            end
                    4'h1:   begin xb <= fpb[95:64]; next_state(STORE1); end
                    4'h2:   begin xb <= fpb[127:96]; next_state(STORE1); end
                    4'h3:   begin 
                            next_state(INVnRUN);
                            cyc_o <= `FALSE;
                            vda_o <= `FALSE;
                            sel_o <= 2'b00;
                            end
                    endcase
                    fplsst <= fplsst + 4'd1;
                    ea <= ea + 32'd2;
                end
            `R2:
                case(xir[31:26])
                `SFxX:
                    begin
                        cyc_o <= `TRUE;
                        vda_o <= `TRUE;
                        sel_o <= 2'b11;
                        case(fplsst)
                        4'h0:   begin
                                    xb <= fpb[63:32];
                                    next_state(STORE1);
                                    if (xir[28:27]==2'b00) begin
                                        next_state(INVnRUN);
                                        cyc_o <= `FALSE;
                                        vda_o <= `FALSE;
                                        sel_o <= 2'b00;
                                    end
                                end
                        4'h1:   begin xb <= fpb[95:64]; next_state(STORE1); end
                        4'h2:   begin xb <= fpb[127:96]; next_state(STORE1); end
                        4'h3:   begin 
                                next_state(INVnRUN);
                                cyc_o <= `FALSE;
                                vda_o <= `FALSE;
                                sel_o <= 2'b00;
                                end
                        endcase
                        fplsst <= fplsst + 4'd1;
                        ea <= ea + 32'd2;
                    end
                endcase
            `MEM:
                case(xir[15:11])
                `PUSH,`PUSHI5:
                    begin
                        xRt <= 5'd31;    
                        upd_rf <= `TRUE;
                        next_state(INVnRUN);
                    end
                `FPUSHS0,`FPUSHS1:
                    begin
                        cyc_o <= `FALSE;
                        vda_o <= `FALSE;
                        sel_o <= 2'b00;
                        xRt <= 5'd31;    
                        upd_rf <= `TRUE;
                        next_state(INVnRUN);
                    end
                `FPUSHQ0,`FPUSHQ1:
                    begin
                        cyc_o <= `TRUE;
                        vda_o <= `TRUE;
                        sel_o <= 2'b11;
                        case(fplsst)
                        4'h0:   begin xb <= fpb[63:32]; next_state(STORE1); end
                        4'h1:   begin xb <= fpb[95:64]; next_state(STORE1); end
                        4'h2:   begin xb <= fpb[127:96]; next_state(STORE1); end
                        4'h3:   begin 
                                xRt <= 5'd31;    
                                upd_rf <= `TRUE;
                                next_state(INVnRUN);
                                cyc_o <= `FALSE;
                                vda_o <= `FALSE;
                                sel_o <= 2'b00;
                                end
                        endcase
                        fplsst <= fplsst + 4'd1;
                        ea <= ea + 32'd2;
                    end
                endcase
            endcase
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
        mbadaddr <= ea;
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
  state_name(st);
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
    `CSR_EXROUT:    res = mexrout;
    `CSR_CAUSE:     res = mcause;
    `CSR_BADADDR:   res = mbadaddr;
    `CSR_SCRATCH:   res = scratch;
    `CSR_SBL:       res = sbl;
    `CSR_SBU:       res = sbu;
    `CSR_TASK:      res = tr;
    `CSR_CISC:      res = cisc;
    `CSR_FPSTATS:   res = fpstatuss;
    `CSR_FPSTATQ:   res = fpstatus;
    `CSR_SEMA:      res = msema;
    `CSR_ITOS0:    res = itos[31:0];
    `CSR_ITOS1:    res = itos[63:32];
    `CSR_ITOS2:    res = itos[95:64];
    `CSR_ITOS3:    res = itos[127:96];
    `CSR_ITOS4:    res = itos[128];
    `CSR_CONFIG:    res = mconfig;
    `CSR_CAP:       res = cap;
    `CSR_FPHOLD0:   res = fphold[31:0];
    `CSR_FPHOLD1:   res = fphold[63:32];
    `CSR_FPHOLD2:   res = fphold[95:64];
    `CSR_FPHOLD3:   res = fphold[127:96];
    `CSR_PCHIST:    res = pc_hist;
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
        `CSR_EXROUT:    mexrout <= dat;
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
        `CSR_FPHOLD0:   fphold[31:0] <= dat;
        `CSR_FPHOLD1:   fphold[63:32] <= dat;
        `CSR_FPHOLD2:   fphold[95:64] <= dat;
        `CSR_FPHOLD3:   fphold[127:96] <= dat;
        `CSR_PCHNDX:    pchndx <= dat[5:0];
        endcase
    `CSRRS:
        case(csrno[11:0])
        `CSR_EXROUT:    mexrout <= mexrout | dat;
        `CSR_PCR:       pcr <= pcr | dat;
        `CSR_SEMA:      msema <= msema | dat;
        endcase
    `CSRRC:
        case(csrno[11:0])
        `CSR_EXROUT:    mexrout <= mexrout & ~dat;
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
    if (upd_rf & !xinv) begin
        if (xRt2)
            sp <= {res2[31:1],1'b0};
        case(xRt)
        5'd1:   r1 <= res;
        5'd2:   r2 <= res;
        5'd28:  r28 <= res;
        5'd31:  sp <= {res[31:1],1'b0};
        endcase
        regfile[xRt] <= res;
        $display("regfile[%d] <= %h", xRt, res);
        // Globally enable interrupts after first update of stack pointer.
        if (xRt==5'd31)
            gie <= `TRUE;
    end
end
endtask

task state_name;
input [7:0] st;
begin
    case(st)
    RUN:    stname <= "RUN";
    LOAD2A: stname <= "LOAD2A";
    LOAD1:  stname <= "LOAD1";
    LOAD2:  stname <= "LOAD2";
    LOAD3:  stname <= "LOAD3";
    STORE1: stname <= "STORE1";
    STORE2: stname <= "STORE2";
    STORE3: stname <= "STORE3";
    INVnRUN:    stname <= "INVnRUN";
    endcase
end
endtask

task disassem;
input [31:0] ins;
output [63:0] mne;
begin
`ifdef SIMULATION
case(ins[5:0])
`CALL,`CALL0,`CALL16:
        mne = "CALL";
`LW:    mne = "LW";
`LH:    mne = "LH";
`SW:    mne = "SW";
`SH:    mne = "SH";
`ADDI:  mne = "ADDI";
`ORI:   if (ins[10:6]==0)
            mne = "LDI";
        else
            mne = "ORI";
`ORI32: if (ins[10:6]==0)
            mne = "LDI";
        else
            mne = "ORI";
`MEM:
    case(ins[15:11])
    `RET:   mne = "RET";
    `PUSH:  mne = "PUSH";
    `POP:   mne = "POP";
    `PUSHI5:    mne = "PUSHI";
    default:    mne = "???";
    endcase
`PEA:   mne = "PEA";
default:    mne = "???";
endcase
`else
mne = "";
`endif
end
endtask

endmodule
