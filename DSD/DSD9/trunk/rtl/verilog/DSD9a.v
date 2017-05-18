// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd9.v
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
`include "DSD9_defines.vh"

module DSD9(hartid_i, rst_i, clk_i, clk2x_i, clk2d_i, irq_i, icause_i, cyc_o, stb_o, lock_o, ack_i,
    err_i, wr_o, sel_o, wsel_o, adr_o, dat_i, dat_o, cr_o, sr_o, rb_i, state_o, trigger_o);
parameter WID = 80;
parameter PCMSB = 31;
input [79:0] hartid_i;
input rst_i;
input clk_i;
input clk2x_i;
input clk2d_i;
input irq_i;
input [8:0] icause_i;
output reg cyc_o;
output reg stb_o;
output reg lock_o;
input ack_i;
input err_i;
output reg wr_o;
output reg [15:0] sel_o;
output reg [15:0] wsel_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg cr_o;
output reg sr_o;
input rb_i;
output [5:0] state_o;
output reg trigger_o;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter deci = 3'd4;

parameter RESTART1 = 6'd1;
parameter RESTART2 = 6'd2;
parameter INVnRUN2 = 6'd3;
parameter RESTART4 = 6'd4;
parameter RUN = 6'd5;
parameter LOAD_ICACHE1 = 6'd6;
parameter LOAD_ICACHE2 = 6'd7;
parameter LOAD_ICACHE3 = 6'd8;
parameter LOAD_ICACHE4 = 6'd9;
parameter LOAD_ICACHE5 = 6'd10;
parameter LOAD_DCACHE1 = 6'd11;
parameter LOAD_DCACHE2 = 6'd12;
parameter LOAD_DCACHE3 = 6'd13;
parameter LOAD_DCACHE4 = 6'd14;
parameter LOAD_DCACHE5 = 6'd15;
parameter LOAD1 = 6'd16;
parameter LOAD1a = 6'd17;
parameter LOAD1b = 6'd18;
parameter LOAD2 = 6'd19;
parameter LOAD3 = 6'd20;
parameter LOAD4 = 6'd21;
parameter STORE_UPD = 6'd22;
parameter LOAD6 = 6'd23;
parameter STORE1 = 6'd24;
parameter STORE1a = 6'd25;
parameter STORE1b = 6'd26;
parameter STORE2 = 6'd27;
parameter STORE3 = 6'd28;
parameter STORE3a = 6'd29;
parameter STORE3b = 6'd30;
parameter STORE4 = 6'd31;
parameter INVnRUN = 6'd32; 
parameter DIV1 = 6'd33;
parameter MUL1 = 6'd34;
parameter MUL2 = 6'd35;
parameter MUL3 = 6'd36;
parameter MUL4 = 6'd37;
parameter MUL5 = 6'd38;
parameter MUL6 = 6'd39;
parameter MUL7 = 6'd40;
parameter MUL8 = 6'd41;
parameter MUL9 = 6'd42;
parameter FLOAT1 = 6'd43;
parameter FLOAT2 = 6'd44;
parameter FLOAT3 = 6'd45;
parameter LOAD1c = 6'd46;
parameter LOAD1d = 6'd47;
parameter LOAD1e = 6'd48;
parameter LOAD1f = 6'd49;
parameter STORE1c = 6'd50;
parameter LOAD5 = 6'd51;
parameter LOAD1g = 6'd52;
parameter STORE1d = 6'd53;
parameter STORE1e = 6'd54;
parameter STORE1f = 6'd55;
parameter STORE3c = 6'd56;
parameter STORE3d = 6'd57;
parameter STORE3e = 6'd58;
parameter STORE3f = 6'd59;
parameter LOAD2a = 6'd60;
parameter LOAD2b = 6'd61;
parameter INC = 6'd62;
parameter FAULT = 6'd63;

parameter IC1 = 4'd1;
parameter IC2 = 4'd2;
parameter IC3 = 4'd3;
parameter IC4 = 4'd4;
parameter IC5 = 4'd5;
parameter IC6 = 4'd6;
parameter IC7 = 4'd7;
parameter IC8 = 4'd8;
parameter IC9 = 4'd9;
parameter IC10 = 4'd10;
parameter IC11 = 4'd11;
parameter IC12 = 4'd12;

reg [5:0] state;
reg [3:0] cstate;
assign state_o = state;
reg [5:0] retstate;                 // state stack 1-entry
reg [1:0] ol;                       // operating level
reg [7:0] cpl;                      // privilege level
reg [PCMSB:0] pc,dpc,d1pc,d2pc,xpc;
wire [PCMSB:0] i2pc;
reg [PCMSB:0] epc [0:4];
wire ipredict_taken;
reg dpredict_taken,xpredict_taken;
reg d1predict_taken,d2predict_taken;
reg [PCMSB:0] br_disp;
wire [39:0] insn,insn2;
reg [39:0] iinsn;
reg [39:0] dir,xir,wir;
reg [39:0] dir2,dir1;
wire [7:0] iopcode = iinsn[7:0];
wire [7:0] dopcode = dir[7:0];
wire [7:0] d2opcode = dir2[7:0];
wire [7:0] dfunct = dir[39:32];
wire [7:0] xopcode = xir[7:0];
wire [7:0] xfunct = xir[39:32];
wire [7:0] wopcode = wir[7:0];
wire [2:0] Sc = xir[28:26];
wire advanceIF,advanceDC,advanceEX;
reg IsICacheLoad,IsDCacheLoad;
reg [1:0] icmf;
reg [2:0] iccnt;
reg [1:0] dccnt;
reg [WID-1:0] regfile [0:63];
reg [WID-1:0] r1;
reg [WID-1:0] r2;
reg [WID-1:0] r58;
reg [WID-1:0] r60 [0:3];
reg [WID-1:0] r61 [0:3];
reg [WID-1:0] r62 [0:3];
reg [WID-1:0] sp [0:3];
reg [WID-1:0] a,b,c, imm;
reg [31:0] ea;
wire [31:0] pea;                // physical address
wire mmu_ack;
wire [31:0] mmu_dat;
wire [31:0] mmu_dati = dat_o[31:0];
reg [5:0] Ra,Rb,Rc,Rd,Re;
reg [5:0] xRt,xRa,xRb,wRt,tRt;
reg [5:0] cRa,cRb,cRc;
reg xRt2;
reg [2:0] mem_size,dmem_size;
reg [WID-1:0] xb;
reg [WID-1:0] res, lres, lres1, wres,tres;
reg [WID-1:0] res2;
reg stuff_fault;
reg [23:0] fault_insn;
reg im;
reg [4:0] mimcd;
reg gie;        // global interrupt enable    
reg i1inv,i2inv,dinv,xinv;
reg i54,i80;
reg upd_rf;
reg [31:0] dea;
reg [127:0] idat1, idat2;
reg wasaCall,wasaCall1,wasaCall2,wasaCalld,wasaCallx;
reg mapen;
reg ls1,ls2;
reg d1inv,d2inv;

// CSR registers
reg [79:0] cisc;
reg [31:0] rdinstret;
reg [79:0] tick;
reg [79:0] mtime;
reg [5:0] pchndx;
reg [31:0] sbl[0:3],sbu[0:3];
reg [31:0] mconfig;
wire dce = mconfig[0];      // data cache enable
wire bpe = mconfig[8];      // branch prediction enable
reg [79:0] mkeys;
reg [5:0] icount;

// Machine
reg [31:0] pcr;
reg [63:0] pcr2;
wire [5:0] okey = pcr[5:0];
wire pgen = pcr[31] && (ol != 2'b00);
reg [31:0] mbadaddr;
reg [79:0] mscratch;
reg [31:0] msema;
reg [31:0] mtvec;
reg [31:0] mexrout;
reg [79:0] mstatus;
reg [31:0] mcause;
reg [511:0] mtdeleg;
wire calltxe = mexrout[31];

reg [39:0] L1_hitCnt;
reg [39:0] L1_missCnt;
reg [39:0] L2_hitCnt;
reg [39:0] L2_missCnt;

// Hypervisor regs
reg him;
reg [79:0] hstatus;
reg [31:0] hcause;
reg [79:0] hscratch;
reg [31:0] hbadaddr;
reg [31:0] htvec;
// Supervisor regs
reg sim;
reg [79:0] sstatus;
reg [31:0] scause;
reg [79:0] sscratch;
reg [31:0] sbadaddr;
reg [31:0] stvec;

reg [127:0] markerMsg;

function [79:0] fnAbs;
input [79:0] jj;
fnAbs = jj[79] ? -jj : jj;
endfunction

function fnOverflow;
input op;   // 0 = add, 1=sub
input a;
input b;
input s;
fnOverflow = (op ^ s ^ b) & (~op ^ a ^ b);
endfunction

// For simulation
integer nn;
initial begin
    for (nn = 0; nn < 4; nn = nn + 1)
    begin
        r60[nn] = 0;
        r61[nn] = 0;
        r62[nn] = 0;
        sp[nn] = 0;
    end
    for (nn = 0; nn < 64; nn = nn + 1)
        regfile[nn] = 0;
end

function IsStackReg;
input [5:0] rn;
    IsStackReg = rn==6'd63 || rn==6'd59;
endfunction

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction fetch stage combinational logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire d1Cx,d2Cx;

function [31:0] pc_plus5;
input [31:0] pci;
case(pci[3:2])
2'b00:   pc_plus5 = {pci[31:4],4'h5};   // 4'h0
2'b01:   pc_plus5 = {pci[31:4],4'hA};   // 4'h5
default:   pc_plus5 = {pci[31:4]+28'd1,4'h0};
endcase
endfunction

wire [31:0] ibr_disp = {{16{iinsn[39]}},iinsn[39:24]};

always@*
    iinsn = insn;

task iSetInsn;
input [39:0] isn;
begin
    d1inv <= `FALSE;
    d2inv <= d1inv;
    dinv <= d2inv;
    d1pc <= pc;
    d2pc <= d1pc;
    dpc <= d2pc;
    if (d2opcode==`PEA || d2opcode==`CALL32 || d2opcode==`CALL || d2opcode==`CALLI || d2opcode==`CALLIT || 
        d2opcode==`POP || d2opcode==`PUSH || d2opcode==`RET) begin
        Ra <= 6'd63;
        Rb <= dir2[13:8];
        Rc <= dir2[19:14];
    end
    else begin
        Ra <= dir2[13:8];
        Rb <= dir2[19:14];
        Rc <= dir2[25:20];
    end
    dir1 <= isn;
    dir2 <= dir1;
    dir <= dir2;
    wasaCall1 <= wasaCall;
    wasaCall2 <= wasaCall1;
    wasaCalld <= wasaCall2;
    wasaCallx <= wasaCalld;
end
endtask

assign d1Cx = dir1[7:4]==4'hC;
assign d2Cx = dir2[7:4]==4'hC;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Decode / register fetch stage combinational logic.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function [4:0] Scale;
input [2:0] code;
case(code)
3'd0:   Scale = 1;
3'd1:   Scale = 2;
3'd2:   Scale = 4;
3'd3:   Scale = 8;
4'd4:   Scale = 16;
3'd5:   Scale = 5;
3'd6:   Scale = 10;
3'd7:   Scale = 15;
endcase
endfunction

reg xMflt;
wire dMflt = dopcode==`MFLT0 || dopcode==`MFLTF;

reg xBrk,xIret,xRex;
wire dBrk = dopcode==`BRK;
wire dIret = dopcode==`IRET;
wire dRex = dopcode==`REX;

reg xJmp, xJmpi, xJmpit, xCall, xCalli, xCallit ,xRet;
reg xJmp32;
wire dJmp = dopcode==`JMP;
wire dJmp32 = dopcode==`JMP32;
wire dJmpi = dopcode==`JMPI;
wire dJmpit = dopcode==`JMPIT;
wire dCall = dopcode==`CALL || dopcode==`CALL32;
wire dCalli = dopcode==`CALLI;
wire dCallit = dopcode==`CALLIT;
wire dRet = dopcode==`RET;

reg xIsPredictableBranch,xIsBranch;
function IsBranch;
input [7:0] opcode;
IsBranch =
    opcode==`BEQ || opcode==`BNE ||
    opcode==`BLT || opcode==`BGE || opcode==`BLE || opcode==`BGT ||
    opcode==`BLTU || opcode==`BGEU || opcode==`BLEU || opcode==`BGTU ||
    opcode==`BEQI || opcode==`BNEI ||
    opcode==`BLTI || opcode==`BGEI || opcode==`BLEI || opcode==`BGTI ||
    opcode==`BLTUI || opcode==`BGEUI || opcode==`BLEUI || opcode==`BGTUI ||
    opcode==`BBC || opcode==`BBS ||
    opcode==`FBEQ || opcode==`FBNE ||
    opcode==`FBLT || opcode==`FBGE || opcode==`FBLE || opcode==`FBGT ||
    opcode==`FBOR || opcode==`FBUN;
endfunction


// Used to decide whether or not to update the branch predictor
function IsPredictableBranch;
input [23:0] ir;
case(ir[7:0])
`BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU:
    IsPredictableBranch = ir[23]==1'b0;
`BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI:
    IsPredictableBranch = ir[23]==1'b0;
`BBC,`BBS:
    IsPredictableBranch = ir[23]==1'b0;
`FBEQ,`FBNE,`FBLT,`FBGE,`FBLE,`FBGT,`FBUN,`FBOR:
    IsPredictableBranch = ir[23]==1'b0;
default: IsPredictableBranch = 1'b0;
endcase
endfunction

wire dMul = dopcode==`R2 && (dfunct==`MUL || dfunct==`MULH);
wire dMulu = dopcode==`R2 && (dfunct==`MULU || dfunct==`MULUH);
wire dMulsu = dopcode==`R2 && (dfunct==`MULSU || dfunct==`MULSUH);
wire dMuli = dopcode==`MUL || dopcode==`MULH;
wire dMului = dopcode==`MULU || dopcode==`MULUH;
wire dMulsui = dopcode==`MULSU || dopcode==`MULSUH;
reg xMul,xMulu,xMulsu,xMuli,xMului,xMulsui,xIsMul,xMulii;
wire dIsMul = dMul|dMulu|dMulsu|dMuli|dMului|dMulsui;

wire dDiv = dopcode==`DIV || dopcode==`DIVU || dopcode==`DIVSU || dopcode==`REM || dopcode==`REMU || dopcode==`REMSU ||
             (dopcode==`R2 && (dfunct==`DIV || dfunct==`DIVU || dfunct==`DIVSU || dfunct==`REM || dfunct==`REMU || dfunct==`REMSU))
             ;
wire dDivi = dopcode==`DIV || dopcode==`DIVU || dopcode==`DIVSU || dopcode==`REM || dopcode==`REMU || dopcode==`REMSU;
wire dDivss = dopcode==`DIV || dopcode==`REM || (dopcode==`R2 && (dfunct==`DIV || dfunct==`REM));
wire dDivsu = dopcode==`DIVSU || dopcode==`REMSU || (dopcode==`R2 && (dfunct==`DIVSU || dfunct==`REMSU));
wire dIsDiv = dDiv;
reg xDiv,xDivi,xDivss,xDivsu,xIsDiv;

reg xFloat;
wire dFloat = dopcode==`FLOAT;

reg xIsLoad,xIsStore,xIsLoadVolatile;

function IsLoad;
input [7:0] opcode;
IsLoad = opcode==`LDB || opcode==`LDBU || opcode==`LDW || opcode==`LDWU || opcode==`LDT || opcode==`LDTU ||
         opcode==`LDP || opcode==`LDPU || opcode==`LDD ||
         opcode==`LDBX || opcode==`LDBUX || opcode==`LDWX || opcode==`LDWUX || opcode==`LDTX || opcode==`LDTUX ||
         opcode==`LDPX || opcode==`LDPUX || opcode==`LDDX ||
         opcode==`LDDBP || opcode==`LDD12 ||
         opcode==`LDDAR || opcode==`LDDARX
         ;
endfunction

function IsLoadr;
input [7:0] opcode;
IsLoadr = opcode==`LDB || opcode==`LDBU || opcode==`LDW || opcode==`LDWU || opcode==`LDT || opcode==`LDTU ||
         opcode==`LDP || opcode==`LDPU || opcode==`LDD ||
         opcode==`LDDAR
         ;
endfunction

function IsLoadn;
input [7:0] opcode;
IsLoadn = opcode==`LDBX || opcode==`LDBUX || opcode==`LDWX || opcode==`LDWUX || opcode==`LDTX || opcode==`LDTUX ||
         opcode==`LDPX || opcode==`LDPUX || opcode==`LDDX ||
         opcode==`LDDARX
         ;
endfunction


function IsStore;
input [7:0] opcode;                              
IsStore = opcode==`STB || opcode==`STW || opcode==`STP || opcode==`STD || opcode==`STDCR || opcode==`STT ||
          opcode==`STBX || opcode==`STWX || opcode==`STPX || opcode==`STDX || opcode==`STDCRX || opcode==`STTX;
endfunction

function IsStorer;
input [7:0] opcode;                              
IsStorer = opcode==`STB || opcode==`STW || opcode==`STP || opcode==`STD || opcode==`STDCR || opcode==`STT;
endfunction

function IsStoren;
input [7:0] opcode;                              
IsStoren = opcode==`STBX || opcode==`STWX || opcode==`STPX || opcode==`STDX || opcode==`STDCRX || opcode==`STTX;
endfunction

reg xLoadn,xLoadr,xStoren,xStorer;

reg xIsMultiCycle;
wire dIsMultiCycle = IsLoad(dopcode) || IsStore(dopcode) || dIsDiv || dIsMul || 
                     dopcode==`POP || dopcode==`PUSH || dopcode==`CALL || dopcode==`CALL32 || dopcode==`CALLI || dopcode==`CALLIT ||
                     dopcode==`JMPI || dopcode==`JMPIT || dopcode==`RET || dopcode==`FLOAT;
                    

reg xCsr;
wire dCsr = dopcode==`CSR;

always @*
case(dopcode)
`LDB,`LDBU,`LDBX,`LDBUX,`STB,`STBX: dmem_size = byt;
`LDW,`LDWU,`LDWX,`LDWUX,`STW,`STWX: dmem_size = wyde;
`LDT,`LDTU,`LDTX,`LDTUX,`STT,`STTX,`JMPIT,`CALLIT:  dmem_size = tetra;
`LDP,`LDPU,`LDPX,`LDPUX,`STP,`STPX: dmem_size = penta;
default:    dmem_size = deci;
endcase

reg xIsShifti;
wire dIsShifti = dopcode==`R2 && (dfunct==`SHLI || dfunct==`SHRI || dfunct==`ASLI || dfunct==`ASRI || dfunct==`ROLI || dfunct==`RORI);

// One might wonder why the following forwarding multiplexer's aren't written
// as a function. It has to do with the simulator's ability to recognize
// changes in values.
//
reg [WID-1:0] rfoa,rfob,rfoc;

always @*
if (Ra==6'd0)
    rfoa <= {WID{1'b0}};
else if (Ra==xRt)
    rfoa <= res;
else
    case(Ra)
    6'd60:  rfoa <= r60[ol];
    6'd61:  rfoa <= r61[ol];
    6'd62:  rfoa <= r62[ol];  
    6'd63:  rfoa <= sp [ol];
    default:    rfoa <= regfile[Ra];
    endcase

always @*
if (Rb==6'd0)
    rfob <= {WID{1'b0}};
else if (Rb==xRt)
    rfob <= res;
else
    case(Rb)
    6'd60:  rfob <= r60[ol];
    6'd61:  rfob <= r61[ol];
    6'd62:  rfob <= r62[ol];  
    6'd63:  rfob <= sp [ol];
    default:    rfob <= regfile[Rb];
    endcase

always @*
if (Rc==6'd0)
    rfoc <= {WID{1'b0}};
else if (Rc==xRt)
    rfoc <= res;
else
    case(Rc)
    6'd60:  rfoc <= r60[ol];
    6'd61:  rfoc <= r61[ol];
    6'd62:  rfoc <= r62[ol];  
    6'd63:  rfoc <= sp [ol];
    default:    rfoc <= regfile[Rc];
    endcase

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Execute stage combinational logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [159:0] mul_prod1;
reg [159:0] mul_prod;
reg mul_sign;
reg [79:0] aa, bb;

// 6 stage pipeline
DSD9_multiplier u7
(
    .clk(clk_i),
    .a(aa),
    .b(bb),
    .p(mul_prod1)
);
wire multovf = ((xMulu|xMului) ? mul_prod[159:80] != 80'd0 : mul_prod[159:80] != {80{mul_prod[79]}});

wire [31:0] siea = a + b * Scale(Sc) + imm;

wire [79:0] qo, ro;
wire dvd_done;
wire dvByZr;
DSD_divider u10
(
    .rst(rst_i),
    .clk(clk2x_i),
    .ld(xDiv),
    .abort(1'b0),
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

wire [79:0] logic_o;
DSD9_logic u8
(
    .xir(xir[39:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .res(logic_o)
);

wire [79:0] shift_o;
DSD9_shift u9
(
    .xir(xir[39:0]),
    .a(a),
    .b(b),
    .res(shift_o),
    .rolo()
);

wire [79:0] bf_out;
DSD9_bitfield #(80) u11
(
    .op(xir[39:36]),
    .a(a),
    .b(b),
    .imm(imm),
    .m(xir[35:20]),
    .o(bf_out),
    .masko()
);

wire setcc_o;
DSD9_SetEval u13
(
    .xir(xir[39:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .o(setcc_o)
);

reg xldfp,xldfp1;
wire [79:0] fpu_o;
wire [31:0] fpstatus;
wire fpdone;
`ifdef INCL_FP
fpUnit #(80) u12
(
    .rst(rst_i),
    .clk(clk2d_i),
    .ce(1'b1),
    .ir(xir[39:0]),
    .ld(xldfp),
    .a(a),
    .b(b),
    .imm(xir[25:20]),
    .o(fpu_o),
    .status(fpstatus),
    .exception(),
    .done(fpdone)
);
`endif

reg [79:0] mux_out;
always @(nn or a or b or c)
    for (nn = 0; nn < 80; nn = nn + 1)
        mux_out[nn] = a[nn] ? b[nn] : c[nn];
 
always @*
    case(xopcode)
    `R2:
        case(xfunct)
        `ADD,`ADDO: res = a + b;
        `SUB,`SUBO: res = a - b;
        `LEAX:  res = siea;
        `CMP:   res = $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
        `CMPU:  res = a < b ? -1 : a==b ? 0 : 1;
        `AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
        `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,
        `SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
            res = logic_o|shift_o;
        `MUL:   res = mul_prod[79:0];
        `MULU:  res = mul_prod[79:0];
        `MULSU: res = mul_prod[79:0];
        `MULH:  res = mul_prod[159:80];
        `MULUH: res = mul_prod[159:80];
        `MULSUH: res = mul_prod[159:80];
        `DIV:   res = qo;
        `DIVU:  res = qo;
        `DIVSU: res = qo;
        `REM:   res = ro;
        `REMU:  res = ro;
        `REMSU: res = ro;
        `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLEU,`SLTU,`SGEU,`SGTU:
                res = {79'd0,setcc_o};
        `CSZ:   res = a==80'd0 ? b : c;
        `CSNZ:  res = a!=80'd0 ? b : c;
        `CSN:   res = a[79] ? b : c;
        `CSNN:  res = ~a[79] ? b : c;
        `CSP:   res = (!a[79] && a!=80'd0) ? b : c;
        `CSNP:  res = !(!a[79] && a!=80'd0) ? b : c;
        `CSOD:  res = a[0] ? b : c;
        `CSEV:  res = a[0] ? c : b;
        `ZSZ:   res = a==80'd0 ? b : 80'd0;
        `ZSNZ:  res = a!=80'd0 ? b : 80'd0;
        `ZSN:   res = a[79] ? b : 80'd0;
        `ZSNN:  res = ~a[79] ? b : 80'd0;
        `ZSP:   res = (!a[79] && a!=80'd0) ? b : 80'd0;
        `ZSNP:  res = !(!a[79] && a!=80'd0) ? b : 80'd0;
        `ZSOD:  res = a[0] ? b : 80'd0;
        `ZSEV:  res = a[0] ? 80'd0 : b;
        `MUX:   res = mux_out;
        `_2ADD:     res = {a,1'b0} + b;
        `_4ADD:     res = {a,2'b0} + b;
        `_8ADD:     res = {a,3'b0} + b;
        `_10ADD:    res = {a,3'b0} + {a,1'b0} + b;
        `_16ADD:    res = {a,4'b0} + b;
        default:    res  = 0;
        endcase
    `MOV:   res = a;
    `ADD,`ADDO,`LEA:    res = a + imm;
    `SUB,`SUBO:   res = a - imm;
    `CMP:   res = $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
    `CMPU:  res = a < imm ? -1 : a==imm ? 0 : 1;
    `AND:   res = logic_o;
    `OR:    res = logic_o;
    `XOR:   res = logic_o;
    `MUL:   res = mul_prod[79:0];
    `MULU:  res = mul_prod[79:0];
    `MULSU: res = mul_prod[79:0];
    `MULH:  res = mul_prod[159:80];
    `MULUH: res = mul_prod[159:80];
    `MULSUH: res = mul_prod[159:80];
    `DIV:   res = qo;
    `DIVU:  res = qo;
    `DIVSU: res = qo;
    `REM:   res = ro;
    `REMU:  res = ro;
    `REMSU: res = ro;
    `FLOAT: res = fpu_o;
    `BITFIELD:  res = bf_out;
    `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLEU,`SLTU,`SGEU,`SGTU:
            res = {79'd0,setcc_o};
    `POP,            
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDP,`LDPU,`LDD,`LDDAR,
    `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDPX,`LDPUX,`LDDX,`LDDARX:
            res = lres;
    `JMP,`JMPI,`JMPIT:   res = pc_plus5(xpc);
    `CALL32,`CALL,`CALLI,`CALLIT:  res = a - 80'd10;
    `PUSH:  res = a - 80'd10;
    `RET:   res = a + imm;
    `CSR:   case(xir[37:36])
            2'd0:   read_csr(xir[35:22],res);
            2'd1:   read_csr(a[13:0],res);
            2'd2:   read_csr(a[13:0],res);
            2'd3:   read_csr(xir[35:22],res);
            endcase
    `CSZ:   res = a==80'd0 ? imm : b;
    `CSNZ:  res = a!=80'd0 ? imm : b;
    `CSN:   res = a[79] ? imm : b;
    `CSNN:  res = ~a[79] ? imm : b;
    `CSP:   res = (!a[79] && a!=80'd0) ? imm : b;
    `CSNP:  res = !(!a[79] && a!=80'd0) ? imm : b;
    `CSOD:  res = a[0] ? imm : b;
    `CSEV:  res = a[0] ? b : imm;
    `ZSZ:   res = a==80'd0 ? imm : 80'd0;
    `ZSNZ:  res = a!=80'd0 ? imm : 80'd0;
    `ZSN:   res = a[79] ? imm : 80'd0;
    `ZSNN:  res = ~a[79] ? imm : 80'd0;
    `ZSP:   res = (!a[79] && a!=80'd0) ? imm : 80'd0;
    `ZSNP:  res = !(!a[79] && a!=80'd0) ? imm : 80'd0;
    `ZSOD:  res = a[0] ? imm : 80'd0;
    `ZSEV:  res = a[0] ? 80'd0 : imm;
    `_2ADD:     res = {a,1'b0} + imm;
    `_4ADD:     res = {a,2'b0} + imm;
    `_8ADD:     res = {a,3'b0} + imm;
    `_10ADD:    res = {a,3'b0} + {a,1'b0} + imm;
    `_16ADD:    res = {a,4'b0} + imm;
    default:    res = {WID{1'b0}};
    endcase

always @*
    case(xopcode)
    `POP:   res2 = a + 32'd10;
    default:    res2 = a + 32'd10;
    endcase

always @*
    case(state)
    FLOAT1: upd_rf <= fpdone;
    DIV1:   upd_rf <= dvd_done;
    MUL9:   upd_rf <= `TRUE;
    LOAD6:  upd_rf <= (xopcode!=`INC && xopcode!=`INCX && xopcode!=`CALLI && xopcode!=`CALLIT);
    STORE_UPD:  upd_rf <= xopcode==`CALL32 || xopcode==`CALL || xopcode==`PEA || xopcode==`CALLI || xopcode==`CALLIT || xopcode==`PUSH;
    default:    //RUN
        if (!xinv)
        case (xopcode)
        `R2:
            case(xfunct)
            `LEAX,`MUX,
            `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
            `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
            `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
            `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
            `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
                upd_rf <= `TRUE;
            default:    upd_rf <= `FALSE;
            endcase
        `LEA,`BITFIELD,`MOV,
        `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
        `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
        `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
        `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR:
                upd_rf <= `TRUE;
        `CSR:   case(xir[38:36])
                3'd0:   upd_rf <= `TRUE;
                3'd1:   upd_rf <= `TRUE;
                3'd2:   upd_rf <= `TRUE;
                3'd3:   upd_rf <= `TRUE;
                default:    upd_rf <= `FALSE;
                endcase
        default:    upd_rf <= `FALSE;
        endcase
        else
            upd_rf <= `FALSE;
    endcase

function Need2Cycles;
input [2:0] mem_size;
input [31:0] adr;
case(mem_size)
byt:    Need2Cycles = FALSE;
wyde:   Need2Cycles = (adr[3:0]==4'hF);
tetra:  Need2Cycles = (adr[3:0] >4'hC);
penta:  Need2Cycles = (adr[3:0] >4'hB);
deci:   Need2Cycles = (adr[3:0] >4'h6);
default:    Need2Cycles = FALSE;
endcase
endfunction

wire takb;
DSD9_BranchEval u4
(
    .xir(xir[39:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .takb(takb)
);

DSD9_BranchHistory u5
(
    .rst(rst_i),
    .clk(clk_i),
    .xIsBranch(xIsPredictableBranch & ~xinv),
    .advanceX(advanceEX),
    .pc(pc),
    .xpc(xpc),
    .takb(takb),
    .predict_taken(ipredict_taken)
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg prime;
reg IsLastICacheWr;
wire ihit,ihit0,ihit1;
reg L1_invall,L2_invall;
reg L1_invline,L2_invline;
reg L1_wr,L1_wr1,L1_wr2,L2_wr1,L2_wr2;
reg [31:0] L1_wadr;
reg [255:0] L1_wdat;
reg [37:0] L2_wadr;
wire L1_ihit,L2_ihit;
reg [31:0] L2_radr,L2ra1,L2ra2;
wire [255:0] L2_rdat;
wire icache_rce = !(xIsMultiCycle && !xinv);
always @(posedge clk_i)
    L2ra1 <= L2_radr;
always @(posedge clk_i)
    L2ra2 <= L2ra1;

wire L2_wr = IsICacheLoad & (ack_i|err_i);
DSD9_L2_icache u1
(
    .rst(rst_i),
    .clk(clk_i),
    .wr(L2_wr),
    .adr({okey,L2_invline ? a[31:0] + imm[31:0] : L2_radr}),
    .i(dat_i),
    .o(L2_rdat),
    .hit(L2_ihit),
    .invall(L2_invall),
    .invline(L2_invline)
);

DSD9_L1_icache u15
(
    .rst(rst_i),
    .clk(clk_i),
    .wr(L1_wr),
    .adr((L1_wr|L1_wr1|L1_wr2) ? {okey,L1_wadr} : {okey,pc}),
    .i(L1_wdat),
    .o(insn),
    .hit(L1_ihit),
    .invall(L1_invall),
    .invline(L1_invline)
);
/*
DSD9_L1_icache u15
(
    .wclk(clk_i),
    .wr(L1_wr),
    .wadr({okey,L1_wadr}),
    .i(L1_wdat),
    .rclk(clk_i),
    .rce(1'b1),
    .radr({okey,pc}),
    .o(insn),
    .hit(L1_ihit),
    .invall(L1_invall),
    .invline(L1_invline)
);
*/
vtdl #(.WID(40),.DEP(64)) u14
(
    .clk(clk_i),
    .ce(1'b1),
    .a(icount-6'd1),
    .d(insn),
    .q(insn2)
);

wire dhit0,dhit1,dhit;
wire [79:0] dc_dat;
reg [1:0] dcmf;
reg upd_dc;
DSD9_dcache u2
(
    .wclk(clk_i),
    .wr(ack_i & (IsDCacheLoad | (upd_dc & wr_o))),
    .sel(wr_o ? sel_o : 16'hFFFF),
    .wadr({okey,ea}),
    .i(IsDCacheLoad ? dat_i : dat_o),
    .rclk(clk_i),
    .rdsize(mem_size),
    .radr({okey,ea}),
    .o(dc_dat),
    .hit(dhit),
    .hit0(dhit0),
    .hit1(dhit1)
);

wire exv;
wire rdv;
wire wrv;
wire unc = dce ? dea[31:20]==12'hFFD : 1'b1;

DSD9_mmu u6
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .ol_i(ol),
    .pcr_i(pcr),
    .pcr2_i(pcr2),
    .mapen_i(mapen),
    .s_ex_i(IsICacheLoad),
    .s_cyc_i(cyc_o),
    .s_stb_i(stb_o),
    .s_ack_o(mmu_ack),
    .s_wr_i(wr_o),
    .s_adr_i(ea),
    .s_dat_i(mmu_dati),
    .s_dat_o(mmu_dat),
    .pea_o(pea),
    .exv_o(exv),
    .rdv_o(rdv),
    .wrv_o(wrv)
);

/*
assign advanceEX = 1'b1;
assign advanceDC = advanceEX && !(xIsMultiCycle && !xinv);
assign advanceIF = advanceDC && ihit;
*/
wire L1_run = L1_ihit && (state==RUN);
assign advanceEX = !(xIsMultiCycle) && L1_run;
assign advanceDC = (advanceEX | xinv) && L1_run;
assign advanceIF = (advanceDC | (d1inv & d2inv & dinv)) & L1_run;

always @(posedge clk_i)
if (rst_i) begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    wr_o <= `LOW;
    sel_o <= 16'h0000;
    tick <= 80'd0;
    ol <= 2'b00;
    cpl <= 8'h00;
    ea <= `RST_VECT;
    pc <= `RST_VECT;
    mtvec <= 32'hFFFC0000;
    xldfp <= `FALSE;
    IsICacheLoad <= `TRUE;
    IsDCacheLoad <= `TRUE;
    xinv <= `TRUE;
    d1inv <= `TRUE;
    d2inv <= `TRUE;
    dinv <= `TRUE;
    pcr <= 32'h00;
    pcr2 <= 32'h01;
    mexrout <= 32'd0;       // sim needs this
    wasaCall <= `FALSE;
    dir <= `NOP_INSN;
    xir <= `NOP_INSN;
    dir1 <= `NOP_INSN;
    dir2 <= `NOP_INSN;
    L2_invline <= `FALSE;
    L1_invline <= `FALSE;
    L2_invall <= `TRUE;
    L1_invall <= `TRUE;
    L1_wr <= `TRUE;
    L1_wadr <= 32'h0;
    L1_wdat <= 256'h0;
    L1_hitCnt <= 40'd0;
    L1_missCnt <= 40'd0;
    L2_hitCnt <= 40'd0;
    L2_missCnt <= 40'd0;
    L2_radr <= 32'd0;
    mconfig <= 32'h0;
    next_state(RUN);
    cstate <= IC2;
    trigger_o <= 1'b0;
    a <= {WID{1'b0}};
    b <= {WID{1'b0}};
    c <= {WID{1'b0}};
end
else begin
L2_invall <= `FALSE;
L2_invline <= `FALSE;
L1_invall <= `FALSE;
L1_invline <= `FALSE;
L1_wr <= `FALSE;
L1_wr1 <= L1_wr;
L1_wr2 <= L1_wr1;
L2_wr1 <= L2_wr;
L2_wr2 <= L2_wr1;
mapen <= `FALSE;
xldfp1 <= `FALSE;
xldfp <= xldfp1;
//upd_rf <= `FALSE;
xRt2 <= `FALSE;
update_regfile();
tick <= tick + 80'd1;
trigger_o <= 1'b0;

case(state)

// -----------------------------------------------------------------------------
// Restart:
// Load the first 16kB of the I-Cache to set all the tags to a valid state. 
// -----------------------------------------------------------------------------
RESTART1:
    begin
        cyc_o <= `HIGH;
        stb_o <= `HIGH;
        sel_o <= 16'hFFFF;
        adr_o <= ea;
        next_state(RESTART2);
    end
RESTART2:
    if (ack_i|err_i) begin
        next_state(RESTART1);
//        L1_wr <= `TRUE;
//        L1_wadr <= L1_wadr + 32'd16;
        if (ea[13:4]==10'h3FF) begin
            IsICacheLoad <= `FALSE;
            IsDCacheLoad <= `FALSE;
            wb_nack();
            next_state(RUN);
        end
        stb_o <= `LOW;
        ea[13:4] <= ea[13:4] + 10'h01;
    end

RUN:
begin
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // IFETCH stage
    // We want decodes in the IFETCH stage to be fast so they don't appear
    // on the critical path. Keep the decodes to a minimum.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceIF) begin
        L1_hitCnt <= L1_hitCnt + 40'd1;
        mimcd <= {mimcd[3:0],1'b0};
        if (mimcd==5'b10000)
            im <= 1'b0;
        if (iopcode==`MARK1) begin
            trigger_o <= 1'b1;
            markerMsg <= "Marker1 Hit";
        end
        stuff_fault <= `FALSE;
        wasaCall <= `FALSE;
        iSetInsn(iinsn);
        if (iopcode==`JMP32 || iopcode==`CALL32)
            pc <= {iinsn[39:8]};
        else
            pc <= pc_plus5(pc);
        if (bpe)
        case(iopcode)
        `FBEQ,`FBNE,`FBLT,`FBGE,`FBLE,`FBGT,`FBOR,`FBUN,
        `BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI,`BBC,`BBS,
        `BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU:
            if (iinsn[23]) begin
                d1predict_taken <= iinsn[22];
                if (iinsn[22]) begin
                    pc <= pc + ibr_disp;
                end
            end
            else begin
                d1predict_taken <= ipredict_taken;
                if (ipredict_taken) begin
                    pc <= pc + ibr_disp;
                end
            end
        default: d1predict_taken <= ipredict_taken;
        endcase
        d2predict_taken <= d1predict_taken;
        dpredict_taken <= d2predict_taken;
        if (iopcode==`WAI && ~irq_i)
            pc <= pc;
    end
    else begin
        pc <= pc;
        L2_radr <= {pc[31:5],5'h0};
        // If a branch took place then we don't want to fetch
        // cache lines from the target that is inva
        if (!L1_ihit) begin
            L1_missCnt <= L1_missCnt + 40'd1;
            cstate <= IC2;
            next_state(LOAD_ICACHE1);
        end
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch and decode stage
    // Much of the decode is done above by combinational logic outside of the
    // clock domain.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceDC) begin
        xinv <= dinv;
        xpc <= dpc;
        xir <= dir;

        xBrk <= dBrk;
        xIret <= dIret;
        xMflt <= dMflt;
        xRex <= dRex;

        xMul <= dMul;
        xMulu <= dMulu;
        xMulsu <= dMulsu;
        xMuli <= dMuli;
        xMului <= dMului;
        xMulsui <= dMulsui;
        xMulii <= dMuli|dMului|dMulsui;
        xIsMul <= dIsMul;
        
        xDiv <= dDiv;
        xDivi <= dDivi;
        xDivss <= dDivss;
        xDivsu <= dDivsu;
        xIsDiv <= dIsDiv;
        xFloat <= dFloat;
        xldfp <= `TRUE;
        xldfp1 <= `TRUE;

        xJmp <= dJmp;
        xJmp32 <= dJmp32;
        xJmpi <= dJmpi;
        xJmpit <= dJmpit;
        xCall <= dCall;
        xCalli <= dCalli;
        xCallit <= dCallit;
        xRet <= dRet;
        xIsLoad <= IsLoad(dopcode);
        xIsStore <= IsStore(dopcode);
        xLoadr <= IsLoadr(dopcode);
        xLoadn <= IsLoadn(dopcode);
        xStorer <= IsStorer(dopcode);
        xStoren <= IsStoren(dopcode);
        mem_size <= dmem_size;
        xCsr <= dCsr;
        
        xIsMultiCycle <= dIsMultiCycle;

        xIsBranch <= IsBranch(dopcode);
        xIsPredictableBranch <= IsPredictableBranch(dir[23:0]);
        xpredict_taken <= dpredict_taken;
        
        xIsShifti <= dIsShifti;

        // Operands
        a <= rfoa;
        // The upper bits of rfob are kept here in order to reduce
        // mux usage.
        if (dIsShifti)
            b <= {rfob[WID-1:7],dir[26],Rb};
        else
            b <= rfob;
        c <= rfoc;

        case(dopcode)
        `CSR,
        `BEQI,`BNEI,`BLTI,`BLEI,`BGTI,`BGEI,`BLTUI,`BLEUI,`BGTUI,`BGEUI:
            case({d1Cx,d2Cx})
            2'b00:  imm <= {{72{dir[21]}},dir[21:14]};
            2'b01:  imm <= {{36{dir2[39]}},dir2[39:8],dir2[3:0],dir[21:14]};
            2'b10:  imm <= {{72{dir[21]}},dir[21:14]};
            2'b11:  imm <= {dir1[39:8],dir1[3:0],dir2[39:8],dir2[3:0],dir[21:14]};
            endcase
        `CACHEX,
        `STBX,`STWX,`STTX,`STPX,`STDX,`STDCRX,
        `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDPX,`LDPUX,`LDDX,`LDDARX:
                imm <= {{69{dir[39]}},dir[39:29]};
        `CALL32:
            case({d1Cx,d2Cx})
            2'b00:  imm <= {48'd0,dir[39:8]};
            2'b01:  imm <= {{24{dir2[39]}},dir2[39:8],dir2[3:0],dir[39:20]};
            2'b10:  imm <= {{60{dir[39]}},dir[39:20]};
            2'b11:  imm <= {dir1[39:8],dir1[3:0],dir2[39:8],dir2[3:0],dir[39:20]};
            endcase
        `JMP32:
            case({d1Cx,d2Cx})
            2'b00:  imm <= {48'd0,dir[39:8]};
            2'b01:  imm <= {{24{dir2[39]}},dir2[39:8],dir2[3:0],dir[39:20]};
            2'b10:  imm <= {{60{dir[39]}},dir[39:20]};
            2'b11:  imm <= {dir1[39:8],dir1[3:0],dir2[39:8],dir2[3:0],dir[39:20]};
            endcase
        default:
            case({d1Cx,d2Cx})
            2'b00:  imm <= {{60{dir[39]}},dir[39:20]};
            2'b01:  imm <= {{24{dir2[39]}},dir2[39:8],dir2[3:0],dir[39:20]};
            2'b10:  imm <= {{60{dir[39]}},dir[39:20]};
            2'b11:  imm <= {dir1[39:8],dir1[3:0],dir2[39:8],dir2[3:0],dir[39:20]};
            endcase
        endcase
        br_disp <= {{16{dir[39]}},dir[39:24]};
        xRa <= Ra;
        xRb <= Rb;
        // Target register
        xRt <= 6'd0;
        xRt2 <= 1'b0;
        if (!dinv)
        case (dopcode)
        `R2:
            case(dfunct)
            `LEAX,
            `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
            `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
            `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
            `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
            `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI,
            `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH,
            `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
                xRt <= dir[25:20];
            `MUX:   xRt <= dir[31:26];
            default:    xRt <= 6'd0;
            endcase
        `LEA,`BITFIELD,`MOV,
        `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
        `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
        `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
        `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,
        `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH,
        `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU,
        `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDP,`LDPU,`LDD,`LDDAR,`JMPI,`JMPIT,`JMP:
            xRt <= dir[19:14];
        `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDPX,`LDPUX,`LDDX,`LDDARX:
            xRt <= dir[25:20];
        `CSR:   case(dir[38:36])
                3'd0:   xRt <= dir[13:8];
                3'd1:   xRt <= dir[27:22];
                3'd2:   xRt <= dir[27:22];
                3'd3:   xRt <= dir[19:14];
                default:    xRt <= 6'd0;
                endcase 
        `PUSH,`PEA,`CALL32,`CALL,`CALLI,`CALLIT,`RET: xRt <= 6'd63;
        `POP: xRt <= dir[19:14];
        `FLOAT: xRt <= dir[31:26]; 
        endcase
        /*
        if (!dinv)
        case (dopcode)
        `R2:
            case(dfunct)
            `LEAX,`MUX,
            `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
            `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
            `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
            `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
            `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
                upd_rf <= `TRUE;
            default:    upd_rf <= `FALSE;
            endcase
        `LEA,`BITFIELD,`MOV,
        `CSZ,`CSNZ,`CSN,`CSNN,`CSP,`CSNP,`CSOD,`CSEV,
        `ZSZ,`ZSNZ,`ZSN,`ZSNN,`ZSP,`ZSNP,`ZSOD,`ZSEV,
        `SEQ,`SNE,`SLT,`SGE,`SLE,`SGT,`SLTU,`SGEU,`SLEU,`SGTU,
        `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR:
                upd_rf <= `TRUE;
        `CSR:   case(dir[38:36])
                3'd0:   upd_rf <= `TRUE;
                3'd1:   upd_rf <= `TRUE;
                3'd2:   upd_rf <= `TRUE;
                3'd3:   upd_rf <= `TRUE;
                default:    upd_rf <= `FALSE;
                endcase
        endcase
        */
    end
    else if (advanceEX)
        inv_xir();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // If the execute stage has been invalidated it doesn't do anything. 
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (!xinv) begin
        if (wasaCallx && xopcode!=`TGT && calltxe)
            ex_fault(`FLT_TGT,0);
        disassem(xir);
        if (xIsBranch) begin
            if (bpe) begin
                if (xpredict_taken & ~takb) begin
                    ex_branch(pc_plus5(xpc));
                end
                else if (~xpredict_taken & takb) begin
                    ex_branch(xpc + br_disp);
                end
            end
            else if (takb)
                ex_branch(xpc + br_disp);
        end

        if (xIsMul)
            next_state(MUL1);
        if (xIsDiv)
            next_state(DIV1);
        if (xFloat)
            next_state(FLOAT1);

        if (xBrk) begin
            epc[4] <= epc[3];
            epc[3] <= epc[2];
            epc[2] <= epc[1];
            epc[1] <= epc[0];
            epc[0] <= xir[23] ? pc_plus5(xpc) : xpc;
            mstatus[54:0] <= {mstatus[43:0],cpl,ol,im};
            mcause <= xir[16:8];
            im <= `TRUE;
            cpl <= 8'h00;
            ol <= 2'b00;
            ex_branch({mtvec[31:8],~ol,6'h00});
        end
        if (xIret) begin
            cpl <= mstatus[10:3];
            ol <= mstatus[2:1];
            if (mstatus[0])
                im <= 1'b1;
            else
                mimcd <= 5'b11111;
            mstatus[54:0] <= {8'h00,2'b00,1'b1,mstatus[54:11]};
            ex_branch(epc[0]);
            epc[0] <= epc[1];
            epc[1] <= epc[2];
            epc[2] <= epc[3];
            epc[3] <= epc[4];
            epc[4] <= `MSU_VECT;
        end
        if (xMflt) begin
            ex_fault(`FLT_MEM,0);
        end
        if (xRex)
            ex_rex();
        if (xJmp)
            if (xRa==6'd63) begin
                ex_branch(xpc + imm);
            end
            else begin
                ex_branch(a + imm);
            end
        if (xJmp32)
            ex_branch(imm);
        if (xJmpi|xJmpit) begin
            dea <= a + imm;
            next_state(LOAD1);
        end
        if (xCall|xCalli|xCallit) begin
            dea <= a - 80'd10;
            xb <= pc_plus5(xpc);
            next_state(STORE1);
        end
        if (xRet) begin
            dea <= a;
            next_state(LOAD1);
        end
        if (xCsr)
            case(xir[37:36])
            2'd0:   write_csr(xir[39:38],xir[35:22],imm);
            2'd1:   write_csr(xir[39:38],a[13:0],imm);
            2'd2:   if (xRb != 6'd0) write_csr(xir[39:38],a[13:0],b);
            2'd3:   if (xRa != 6'd0) write_csr(xir[39:38],xir[35:22],a);
            endcase
        if (xLoadr) begin dea <= a + imm; next_state(LOAD1); end
        if (xLoadn) begin dea <= siea; next_state(LOAD1); end
        if (xStorer) begin dea <= a + imm; xb <= b; next_state(STORE1); end
        if (xStoren) begin dea <= siea; xb <= c; next_state(STORE1); end

        case(xopcode)
        `R2:
            case(xfunct)
            `ADDO,`SUBO:
                if (mexrout[7] && fnOverflow(xfunct==`SUBO,a[79],b[79],res[79])) begin
                    ex_fault(`FLT_OFL,0);
                end
            endcase
        `ADDO,`SUBO:
            if (mexrout[7] && fnOverflow(xopcode==`SUBO,a[79],imm[79],res[79])) begin
                ex_fault(`FLT_OFL,0);
            end
               
        `PUSH:  begin dea <= a - 80'd10;/*xir[39:34]*/ xb <= b; next_state(STORE1); end
        `POP:   begin dea <= a; next_state(LOAD1); end
        `CLI:   mimcd <= 5'b11111;
        `SEI:   im <= 1'b1;
        `CACHE:
            case(xRt)
            6'h02:  begin
                    L1_wr <= `TRUE;
                    L1_wadr <= a + imm;
                    L2_invline <= `TRUE;
                    L1_invline <= `TRUE;
                    end
            6'h03:  begin L1_wr <= `TRUE; L2_invall <= `TRUE; L1_invall <= `TRUE; end
            endcase
        endcase
    end
    if (irq_i & ~im & gie)
        ex_fault(icause_i,0);
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // for the TGT instruction.
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    wir <= xir;
    end // RUN
 
// Step1: setup operands and capture sign
MUL1:
    begin
        if (xMul) mul_sign <= a[79] ^ b[79];
        else if (xMuli) mul_sign <= a[79] ^ imm[79];
        else if (xMulsu) mul_sign <= a[79];
        else if (xMulsui) mul_sign <= a[79];
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
MUL4:   next_state(MUL9);
MUL9:
    begin
        mul_prod <= mul_sign ? -mul_prod1 : mul_prod1;
        //upd_rf <= `TRUE;
        next_state(INVnRUN);
        if (multovf & mexrout[5]) begin
            ex_fault(`FLT_DBZ,0);
        end
    end

DIV1:
    if (dvd_done) begin
        //upd_rf <= `TRUE;
        next_state(INVnRUN);
        if (dvByZr & mexrout[3]) begin
            ex_fault(`FLT_DBZ,0);
        end
    end

FLOAT1:
    if (fpdone) begin
        //upd_rf <= `TRUE;
        inv_xir();
        next_state(RUN);
        if (fpstatus[9]) begin  // GX status bit
            ex_fault(`FLT_FLT,0);
        end
    end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Load states
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
LOAD1:
    begin
        ea <= dea;
        mapen <= pgen;
        if (IsStackReg(xRa)&&(dea < sbl[ol] || dea > sbu[ol])) begin
            ex_fault(`FLT_STACK,0);
        end
        else begin
            // Begin read uncached and unmapped data right away.
            if (dea[31:26]==6'h3F) begin
                read1(mem_size,dea,dea);
                next_state(LOAD2);
            end
            else next_state(LOAD1b);
        end
    end

// Wait for data cache to respond
// Also wait for mmu mapped address
// cycle 3: The following wait state for data alignment
LOAD1b:
    next_state(LOAD1c);
LOAD1c:
    next_state(LOAD1d);
LOAD1d:
    begin
        if (rdv & pgen)
            ex_fault(`FLT_RDV,0);
        else begin
            if (unc) begin
                read1(mem_size,pgen ? pea : ea,dea);
                next_state(LOAD2);
            end
            else next_state(LOAD1e);
        end
    end

LOAD1e:
    next_state(LOAD1f);
// The following wait state for cache vs external input
LOAD1f:
    next_state(LOAD1g);
LOAD1g:
    begin
        if (dhit) begin
            load1(1'b1);
            next_state(LOAD6);
        end
        // Load the data cache on a miss.
        else begin
            if (dea[31:26]==6'h3F)
                $display("DCACHE Load of I/O area");
            dcmf <= {~dhit1,~dhit0};
            retstate <= LOAD1b;
            next_state(LOAD_DCACHE1);
        end
    end

// LOAD2 and beyond are reached only for uncached loads.
LOAD2:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i|mmu_ack) begin
        stb_o <= `LOW;
        ea <= {dea[31:4]+28'd1,4'h0};
        mapen <= pgen;
        if (!Need2Cycles(mem_size,dea))
            wb_nack();
        next_state(LOAD2a);
    end // LOAD2
// This cycle needed after data latched
LOAD2a:
    next_state(LOAD2b);
LOAD2b:
    begin
        load1(1'b0);
        if (Need2Cycles(mem_size,dea))
            next_state(LOAD3);
        else begin
            next_state(LOAD6);
        end
    end

LOAD3:
    begin
        read2(mem_size,pgen?pea:ea,dea);
        next_state(LOAD4);
    end
    // Data from dat_i will be captured in idat1 for a cycle.
LOAD4:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i|mmu_ack) begin
        wb_nack();
        next_state(LOAD5);
    end
LOAD5:
    begin
        next_state(LOAD6);
        case(xopcode)
        `LDW,`LDWX:
            begin
                lres[79:8] <= {{72{idat1[7]}},idat1[7:0]};
            end
        `LDWU,`LDWUX:
            begin
                lres[79:8] <= {{72{1'b0}},idat1[7:0]};
            end
        `LDT,`LDTX:
            begin
                case(dea[3:0])
                4'hD:   lres[79:24] <= {{48{idat1[7]}},idat1[7:0]};
                4'hE:   lres[79:16] <= {{48{idat1[15]}},idat1[15:0]};
                4'hF:   lres[79:8] <= {{48{idat1[23]}},idat1[23:0]};
                endcase
            end
        `LDTU,`LDTUX,`JMPIT,`CALLIT:
            begin
                case(dea[3:0])
                4'hD:   lres[79:24] <= {{48{1'b0}},idat1[7:0]};
                4'hE:   lres[79:16] <= {{48{1'b0}},idat1[15:0]};
                4'hF:   lres[79:8] <= {{48{1'b0}},idat1[23:0]};
                endcase
            end
        `LDP,`LDPX:
            begin
                case(dea[3:0])
                4'hC:   lres[79:32] <= {{40{idat1[7]}},idat1[7:0]};
                4'hD:   lres[79:24] <= {{40{idat1[15]}},idat1[15:0]};
                4'hE:   lres[79:16] <= {{40{idat1[23]}},idat1[23:0]};
                4'hF:   lres[79:8] <= {{40{idat1[31]}},idat1[31:0]};
                endcase
            end
        `LDPU,`LDPUX:
            begin
                case(dea[3:0])
                4'hC:   lres[79:32] <= {{40{1'b0}},idat1[7:0]};
                4'hD:   lres[79:24] <= {{40{1'b0}},idat1[15:0]};
                4'hE:   lres[79:16] <= {{40{1'b0}},idat1[23:0]};
                4'hF:   lres[79:8] <= {{40{1'b0}},idat1[31:0]};
                endcase
            end
        `LDD,`LDDX,`LDDAR,`LDDARX,`POP,`RET,`JMPI,`CALLI,`INC,`INCX:
            begin
                case(dea[3:0])
                4'h7:   lres[79:72] <= idat1[7:0];
                4'h8:   lres[79:64] <= idat1[15:0];
                4'h9:   lres[79:56] <= idat1[23:0];
                4'hA:   lres[79:48] <= idat1[31:0];
                4'hB:   lres[79:40] <= idat1[39:0];
                4'hC:   lres[79:32] <= idat1[47:0];
                4'hD:   lres[79:24] <= idat1[55:0];
                4'hE:   lres[79:16] <= idat1[63:0];
                4'hF:   lres[79:8] <= idat1[71:0];
                endcase
            end
        endcase // xopcode
        case(xopcode)
        `POP:
            begin
            xRt2 <= `TRUE;
            end
        endcase
    end // LOAD5
LOAD6:
    begin
        if (xopcode==`INC || xopcode==`INCX)
            next_state(INC);
        else
            next_state(INVnRUN);
//        if (xopcode!=`INC && xopcode!=`INCX && xopcode!=`CALLI && xopcode!=`CALLIT)
//            upd_rf <= `TRUE;
        case(xopcode)
        `POP:
            begin
            xRt2 <= `TRUE;
            end
        endcase
    end


INC:
    begin
        if (xopcode==`INC)
            xb <= lres + {{74{xir[19]}},xir[19:14]};
        else    // INCX
            xb <= lres + {{74{xir[25]}},xir[25:20]};
        next_state(STORE1);
    end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Store states
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STORE1:
    begin
        //b <= fwd_mux(xir[19:14]);
        ea <= dea;
        mapen <= pgen;
        if (dea>=32'h1410 && dea < 32'h1420)
            $display("Store zero to 3edx");
        if (IsStackReg(xRa)&&(dea < sbl[ol] || dea > sbu[ol])) begin
            ex_fault(`FLT_STACK,0);
        end
        else begin
            $display("Store to %h <= %h", dea, xb);
            if (dea[31:26]==6'h3F) begin
                write1(mem_size,dea,dea,xb);
                next_state(STORE2);
            end
            else
                next_state(STORE1c);
        end
    end
// three cycles for data cache hit detect
STORE1c:
    next_state(STORE1d);
STORE1d:
    next_state(STORE1e);
STORE1e:
    next_state(STORE1f);
STORE1f:
    begin
        if (wrv & pgen)
            ex_fault(`FLT_WRV,0);
        else begin
            upd_dc <= dhit0;
            write1(mem_size,pgen?pea:ea,dea,xb);
            next_state(STORE2);
        end
    end
STORE2:
    if (err_i) begin
        upd_dc <= `FALSE;
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i|mmu_ack) begin
        upd_dc <= `FALSE;
        stb_o <= `LOW;
        if (Need2Cycles(mem_size,dea)) begin
            ea <= {dea[31:4]+28'd1,4'h0};
            mapen <= pgen;
            next_state(STORE3b);
        end
        else begin
            wb_nack();
            lock_o <= `LOW;
            next_state(STORE_UPD);
        end
        cr_o <= `LOW;
        msema[0] <= rb_i;
    end // STORE2
STORE3b:
    next_state(STORE3c);
STORE3c:
    next_state(STORE3d);
STORE3d:
    next_state(STORE3e);
STORE3e:
    next_state(STORE3f);
STORE3f:
    begin
        upd_dc <= dhit0;
        write2(mem_size,pgen?pea:ea,dea);
        next_state(STORE4);
    end
STORE4:
    if (err_i) begin
        upd_dc <= `FALSE;
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i|mmu_ack) begin
        upd_dc <= `FALSE;
        wb_nack();
        lock_o <= `LOW;
        next_state(STORE_UPD);
    end
STORE_UPD:
    begin
        case(xopcode)
        `CALLI:
            begin
                mem_size = deci;
                dea <= a + imm;
                next_state(LOAD1);
            end
        `CALLIT:
            begin
                mem_size = tetra;
                dea <= a + imm;
                next_state(LOAD1);
            end
        default:    next_state(INVnRUN);
        endcase
        /*
        case(xopcode)
        `CALL,`PEA,`CALLI,`CALLIT,`PUSH:
            begin
                upd_rf <= `TRUE;
            end
        endcase
        */
    end

// Invalidate the xir and switch back to the run state.
// The xir is invalidated to prevent the instruction from executing again.
// Also performed is the control flow operations requiring a memory operand.
INVnRUN:
    begin
//    upd_rf <= upd_rf;    
    next_state(INVnRUN2);
    end
INVnRUN2:
    begin
        inv_xir();
        case (xopcode)
        `CALL:
//            if (xRb!=5'd0) begin
                if (xRb==6'd63) begin
                    ex_branch(xpc + imm);
                end
                else begin
                    ex_branch(b + imm);
                end
//            end
        `CALL32: ex_branch(imm);
        `RET,`JMPI,`CALLI: ex_branch(lres);
        `JMPIT,`CALLIT: ex_branch(lres);    // ({xpc[79:32],lres[31:0]})
        /*
        `FLOAT:
            if (xir[31:29]==3'd0 && xir[17:12]==6'd1) begin
                ex_branch(xpc + {xir[28:27],1'b0} + 32'd4);
            end
        */
        // The following line causes an automatic pipeline flush.
//        default:   if (|xRt) ex_branch(pc_plus5(xpc));
        endcase
        case(xopcode)
        `CALL,`CALLI,`CALLIT,`CALL32:   wasaCall <= `TRUE;
        endcase
        next_state(RUN);
    end

// -----------------------------------------------------------------------------
// Load instruction cache lines.
// Each cache line is 256 bits in length.
// -----------------------------------------------------------------------------
LOAD_ICACHE1:
begin
case(cstate)
IC1:    cstate <= IC2;
IC2:    cstate <= IC10;
IC10:   cstate <= IC3;
IC3:    if (L2_ihit) begin
            L1_wr <= `TRUE;
            L1_wadr <= L2ra2;
            L1_wdat <= L2_rdat;
            L2_hitCnt <= L2_hitCnt + 40'd1;
            cstate <= IC9;
        end
        else begin
            L2_missCnt <= L2_missCnt + 40'd1;
            cstate <= IC4;
        end
IC4:
    begin        
        IsICacheLoad <= `TRUE;
        ea <= L2_radr;
        mapen <= pgen;
        cstate <= pgen ? IC5 : IC7;
    end
IC5:    cstate <= IC6;
IC6:    cstate <= IC7;
IC7:
    begin
        if (exv & pgen)
            ex_fault(`FLT_EXV,0);
        else begin
            cyc_o <= `HIGH;
            stb_o <= `HIGH;
            sel_o <= 16'hFFFF;
            adr_o <= pgen ? pea : ea;
            cstate <= IC8;
        end
    end
IC8:
    if (ack_i|err_i) begin
        stb_o <= `LOW;
        cstate <= pgen ? IC5 : IC7;
        mapen <= pgen;
        if (ea[4]) begin
            IsICacheLoad <= `FALSE;
            wb_nack();
            cstate <= IC1;
        end
        else begin
            ea <= ea + 32'd16;
            L2_radr <= L2_radr + 32'd16;
        end
    end
// Three cycles to update L1 cache
IC9:    cstate <= IC11;
IC11:   cstate <= IC12;
IC12:    next_state(RUN);
endcase
end

// -----------------------------------------------------------------------------
// Load data cache lines.
// -----------------------------------------------------------------------------

LOAD_DCACHE1:
    begin
        if (dcmf != 2'b00) begin
            IsDCacheLoad <= `TRUE;
            if (dcmf[0]) begin
                dcmf[0] <= 1'b0;
                ea <= {dea[31:5],5'h0};
                mapen <= pgen;
                dccnt <= 2'd0;
            end
            else if (dcmf[1]) begin
                ea <= {dea[31:5]+27'd1,5'h0};
                mapen <= pgen;
                dccnt <= 2'd0;
                dcmf[1] <= 1'b0;
            end
            next_state(pgen ? LOAD_DCACHE2 : LOAD_DCACHE4);
        end
        else begin
            ea <= dea;
            mapen <= pgen;
            next_state(retstate);
        end
    end
LOAD_DCACHE2:
    next_state(LOAD_DCACHE3);
LOAD_DCACHE3:
    next_state(LOAD_DCACHE4);
LOAD_DCACHE4:
    begin
        if (rdv & pgen) begin
            ex_fault(`FLT_RDV,0);
        end
        else begin
            cyc_o <= `HIGH;
            stb_o <= `HIGH;
            sel_o <= 16'hFFFF;
            adr_o <= pgen ? pea : ea;
            next_state(LOAD_DCACHE5);
        end
    end
LOAD_DCACHE5:
    if (ack_i|err_i) begin
        stb_o <= `LOW;
        dccnt <= dccnt + 2'd1;
        ea <= ea + 32'd16;
        mapen <= pgen;
        next_state(pgen ? LOAD_DCACHE2 : LOAD_DCACHE4);
        if (dccnt==2'b01) begin
            if (dcmf==2'b00) begin
                IsDCacheLoad <= `FALSE;
                wb_nack();
                ea <= dea;
                mapen <= pgen;
                next_state(retstate);
            end
            else begin 
                next_state(LOAD_DCACHE1);
            end
        end
    end

FAULT:
    begin
        stuff_fault <= `TRUE;
        ex_branch(xpc);
    end

default:
    next_state(RUN);

endcase // state
end

// Register incoming data
always @(posedge clk_i)
if (state==LOAD2 || state==LOAD4)
case({ack_i,mmu_ack})
2'b00:  ;
2'b01:  idat1 <= {4{mmu_dat}};
2'b10:  idat1 <= dat_i;
2'b11:  idat1 <= {4{mmu_dat}};
endcase

// Shift data into position
always @(posedge clk_i)
if (state==LOAD2a || state==LOAD1g) begin
    if (dhit & dce)
        lres1 <= dc_dat;
    else
        lres1 <= (idat1 >> {dea[3:0],3'h0});// | (idat1 << {~dea[3:0]+4'd1,3'h0});
end

task load1;
input dhit;
begin
    lres <= lres1;
    case(xopcode)
    `LDB,`LDBX:   lres <= {{72{lres1[7]}},lres1[7:0]};
    `LDBU,`LDBUX:  lres <= {{72{1'b0}},lres1[7:0]};
    `LDW,`LDWX:
            if (dhit || (dea[3:0]!=4'hF)) begin
                lres <= {{64{lres1[15]}},lres1[15:0]};
            end
    `LDWU,`LDWUX:
            if (dhit || (dea[3:0]!=4'hF)) begin
                lres <= {{64{1'b0}},lres1[15:0]};
            end
    `LDT,`LDTX:
            if (dhit || (dea[3:0] < 4'hD)) begin
                lres <= {{48{lres1[31]}},lres1[31:0]};
            end
    `LDTU,`LDTUX,`JMPIT,`CALLIT:
            if (dhit || (dea[3:0] < 4'hD)) begin
                lres <= {{48{1'b0}},lres1[31:0]};
            end
    `LDP,`LDPX:
            if (dhit || (dea[3:0] < 4'hC)) begin
                lres <= {{40{lres1[39]}},lres1[39:0]};
            end
    `LDPU,`LDPUX:
            if (dhit || (dea[3:0] < 4'hC)) begin
                lres <= {{40{1'b0}},lres1[39:0]};
            end
    `LDD,`LDDAR,`JMPI,`CALLI,`INC,`INCX,
    `LDDX,`LDDARX,`RET,`POP:
            if (dhit || (dea[3:0] < 4'h7)) begin
                lres <= lres1[79:0];
            end
    endcase // xopcode
    if (xopcode==`POP)
        xRt2 <= `TRUE;
end
endtask

task wb_nack;
begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    sel_o <= 16'h0000;
    wsel_o <= 16'h0000;
    wr_o <= `LOW;
end
endtask

wire [3:0] sel2_shamt = ~dea[3:0] + 4'd1;

task read1;
input [2:0] sz;
input [31:0] adr;
input [31:0] orig_adr;
begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    adr_o <= adr;
	case(sz)
	byt:   sel_o <= 16'h0001 << orig_adr[3:0];
	wyde:  sel_o <= 16'h0003 << orig_adr[3:0];
	tetra: sel_o <= 16'h000F << orig_adr[3:0];
	penta: sel_o <= 16'h001F << orig_adr[3:0];
	deci:  sel_o <= 16'h03FF << orig_adr[3:0];
    endcase
    case(sz)
    wyde:   if (orig_adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (orig_adr[3:0] >4'hC) lock_o <= `HIGH;
    penta:  if (orig_adr[3:0] >4'hB) lock_o <= `HIGH;
    deci:   if (orig_adr[3:0] >4'h6) lock_o <= `HIGH;
    endcase
    if (xopcode==`INC || xopcode==`INCX)
        lock_o <= `HIGH;
    if (xopcode==`LDDAR || xopcode==`LDDARX)
        sr_o <= 1'b1;
end
endtask

task read2;
input [2:0] sz;
input [31:0] adr;
input [31:0] orig_adr;
begin
    stb_o <= `HIGH;
	adr_o <= adr;
	case(sz)
	wyde:  sel_o <= 16'h0003 >> sel2_shamt;
	tetra: sel_o <= 16'h000F >> sel2_shamt;
	penta: sel_o <= 16'h001F >> sel2_shamt;
	deci:  sel_o <= 16'h03FF >> sel2_shamt;
    endcase
end
endtask

wire [127:0] bdat = {16{xb[7:0]}};
wire [127:0] wdat = {8{xb[15:0]}};
wire [127:0] tdat = {4{xb[31:0]}};

task write1;
input [2:0] sz;
input [31:0] adr;
input [31:0] orig_adr;
input [79:0] dat;
begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    wr_o <= `HIGH;
	adr_o <= adr;
	case(sz)
	byt:   sel_o <= 16'h0001 << orig_adr[3:0];
	wyde:  sel_o <= 16'h0003 << orig_adr[3:0];
	tetra: sel_o <= 16'h000F << orig_adr[3:0];
	penta: sel_o <= 16'h001F << orig_adr[3:0];
	deci:  sel_o <= 16'h03FF << orig_adr[3:0];
    endcase
	case(sz)
    byt:   wsel_o <= 16'h0001 << orig_adr[3:0];
    wyde:  wsel_o <= 16'h0003 << orig_adr[3:0];
    tetra: wsel_o <= 16'h000F << orig_adr[3:0];
    penta: wsel_o <= 16'h001F << orig_adr[3:0];
    deci:  wsel_o <= 16'h03FF << orig_adr[3:0];
    endcase
    case(sz)
    byt:        dat_o <= (bdat << {orig_adr[3:0],3'b0}) | (bdat >> {~orig_adr[3:0] + 4'd1,3'b0});
    wyde:       dat_o <= (wdat << {orig_adr[3:0],3'b0}) | (wdat >> {~orig_adr[3:0] + 4'd1,3'b0});
    tetra:      dat_o <= (tdat << {orig_adr[3:0],3'b0}) | (tdat >> {~orig_adr[3:0] + 4'd1,3'b0});
    penta:      dat_o <= ({88'h0,dat[39:0]} << {orig_adr[3:0],3'b0}) | ({88'h0,dat[39:0]} >> {~orig_adr[3:0] + 4'd1,3'b0});
    deci:       dat_o <= ({48'h0,dat} << {orig_adr[3:0],3'b0}) | ({48'h0,dat} >> {~orig_adr[3:0] + 4'd1,3'b0});
    endcase
    case(sz)
    wyde:   if (orig_adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (orig_adr[3:0] >4'hC) lock_o <= `HIGH;
    penta:  if (orig_adr[3:0] >4'hB) lock_o <= `HIGH;
    deci:   if (orig_adr[3:0] >4'h6) lock_o <= `HIGH;
    endcase
    if (xopcode==`STDCR || xopcode==`STDCRX)
        cr_o <= 1'b1;
end
endtask

task write2;
input [2:0] sz;
input [31:0] adr;
input [31:0] orig_adr;
begin
    stb_o <= `HIGH;
	adr_o <= adr;
	case(sz)
	wyde:  sel_o <= 16'h0003 >> sel2_shamt;
	tetra: sel_o <= 16'h000F >> sel2_shamt;
	penta: sel_o <= 16'h001F >> sel2_shamt;
	deci:  sel_o <= 16'h03FF >> sel2_shamt;
	default:   sel_o <= 16'h0000;
    endcase
	case(sz)
    wyde:  wsel_o <= 16'h0003 >> sel2_shamt;
    tetra: wsel_o <= 16'h000F >> sel2_shamt;
    penta: wsel_o <= 16'h001F >> sel2_shamt;
    deci:  wsel_o <= 16'h03FF >> sel2_shamt;
    default:   wsel_o <= 16'h0000;
    endcase
end
endtask

task inv_dir;
begin
    d1inv <= `TRUE;
    d2inv <= `TRUE;
    dinv <= `TRUE;
//    dir[7:0] <= `NOP;
end
endtask

task inv_xir;
begin
    xinv <= TRUE;
//    xir[7:0] <= `NOP;
//    xRt <= 6'd0;
    xRt2 <= 1'd0;
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
    xinv <= `FALSE;
    xBrk <= `TRUE;
    xir <= { 2'b0, nib, ccd, `BRK};
    xpc <= xpc;
    next_state(RUN);
end
endtask

wire [7:0] tmp_pl = xir[23:16] | a[7:0];

// While redirecting an exception, the return program counter and status
// flags have already been stored in an internal stack.
// The exception can't be redirected unless exceptions are enabled for
// that level.
// Enable higher level interrupts.
task ex_rex;
begin
    case(ol)
    `OL_USER:
        begin   
            ex_fault(`FLT_PRIV,0);
        end
    `OL_MACHINE:
        case(xir[15:14])
        `OL_HYPERVISOR:
            if (him==`FALSE) begin
                hcause <= mcause;
                hbadaddr <= mbadaddr;
                ex_branch(htvec);
                ol <= xir[15:14];
                cpl <= 8'h01;   // no choice, it's 01
                mimcd <= 5'b11111;
            end
        `OL_SUPERVISOR:
            // must have a valid privilege level or redirect fails
            if (sim==`FALSE) begin
                if (tmp_pl >= 8'h02 && tmp_pl <= 8'h07) begin
                    scause <= mcause;
                    sbadaddr <= mbadaddr;
                    ex_branch(stvec);
                    ol <= xir[15:14];
                    cpl <= tmp_pl;
                    mimcd <= 5'b11111;
                    him <= `FALSE;
                end
            end
        endcase
    `OL_HYPERVISOR:
        if (xir[15:14]==`OL_SUPERVISOR && sim==`FALSE) begin
            // must have a valid privilege level or redirect fails
            if (tmp_pl >= 8'h02 && tmp_pl <= 8'h07) begin
                scause <= hcause;
                sbadaddr <= hbadaddr;
                ex_branch(stvec);
                ol <= xir[15:14];
                cpl <= tmp_pl;
                mimcd <= 5'b11111;
                him <= `FALSE;
            end
        end
    endcase
end
endtask

task ex_branch;
input [31:0] nxt_pc;
begin
    i1inv <= `TRUE;
    i2inv <= `TRUE;
    inv_dir();
    inv_xir();
    pc <= nxt_pc;
end
endtask

task next_state;
input [5:0] st;
begin
    state <= st;
end
endtask

// The register file is updated outside of the state case statement.
// It could be updated potentially on every clock cycle as long as
// upd_rf is true.

task update_regfile;
begin
    if (upd_rf & !xinv) begin
        if (xRt2)
            sp[ol] <= {res2[79:1],1'h0};
        case(xRt)
        6'd60:  r60[ol] <= res;
        6'd61:  r61[ol] <= res;
        6'd62:  r62[ol] <= res;
        6'd63:  sp[ol] <= {res[79:1],1'h0};
        endcase
        regfile[xRt] <= |xRt ? res : 80'd0;
        if (xRt==59 && res==0) begin
            regfile[xRt] <= res;
            $display("BP <= Zero");
        end
        $display("regfile[%d] <= %h", xRt, res);
        // Globally enable interrupts after first update of stack pointer.
        if (xRt==6'd63)
            gie <= `TRUE;
    end
end
endtask

task read_csr;
input [13:0] csrno;
output [79:0] res;
begin
    if (ol <= csrno[13:12])
    case(csrno[11:0])
    `CSR_HARTID:    res = ol==`OL_MACHINE ? hartid_i : 80'd1;
    `CSR_TICK:      res = tick;
    `CSR_PCR:       res = pcr;
    `CSR_PCR2:      res = pcr2;
    `CSR_TVEC:
        case(csrno[13:12])
        `OL_USER:   res = 80'd0;
        `OL_SUPERVISOR: res = stvec;
        `OL_HYPERVISOR: res = htvec;
        `OL_MACHINE:    res = mtvec;
        endcase
    `CSR_CAUSE:
        case(csrno[13:12])
        `OL_USER:   res = 80'd0;
        `OL_SUPERVISOR: res = scause;
        `OL_HYPERVISOR: res = hcause;
        `OL_MACHINE:    res = mcause;
        endcase
    `CSR_BADADDR:
        case(csrno[13:12])
        `OL_USER:   res = 80'd0;
        `OL_SUPERVISOR: res = sbadaddr;
        `OL_HYPERVISOR: res = hbadaddr;
        `OL_MACHINE:    res = mbadaddr;
        endcase
    `CSR_SCRATCH:
        case(csrno[13:12])
        `OL_USER:   res = 80'd0;
        `OL_SUPERVISOR: res = sscratch;
        `OL_HYPERVISOR: res = hscratch;
        `OL_MACHINE:    res = mscratch;
        endcase
    `CSR_SP:      res = sp[csrno[13:12]];
    `CSR_SBL:     res = sbl[csrno[13:12]];
    `CSR_SBU:     res = sbu[csrno[13:12]];
    `CSR_CISC:      res = cisc;
    `CSR_STATUS:
        case(ol)
        `OL_USER:   res = 80'd0;
        `OL_MACHINE:    res = mstatus;
        `OL_HYPERVISOR: res = hstatus;
        `OL_SUPERVISOR: res = sstatus;
        endcase
    `CSR_FPSTAT:    res = fpstatus;
    `CSR_INSRET:    res = rdinstret;
    `CSR_TIME:      res = mtime;

    `CSR_EPC:       res = epc[0];
    `CSR_CONFIG:    res = mconfig;
    `CSR_L1STAT:    res <= {L1_missCnt,L1_hitCnt};
    `CSR_L2STAT:    res <= {L2_missCnt,L2_hitCnt};
    // CPU Info
    12'hFF0:    res = "Finitron";
    12'hFF1:    res = "";
    12'hFF2:    res = "80 Bit";
    12'hFF3:    res = "";
    12'hFF4:    res = "DSD9";
    12'hFF5:    res = "";
    12'hFF6:    res = 1;
    12'hFF7:    res = 1234;
    12'hFF8:    res = {40'd16384,40'd16384};
    default:        res = 80'd0;
    endcase
    else
        res = 80'd0;
    /*
    else begin
        ex_fault(`FLT_PRIV,0);
        pc <= xpc;
        dinv <= TRUE;
        xinv <= TRUE;
        xRt2 <= 1'b0;
        xRt <= 6'd0;
    end
    */
end
endtask

task write_csr;
input [1:0] op;
input [13:0] csrno;
input [31:0] dat;
begin
    if (ol <= csrno[13:12])
    case(op)
    `CSRRW:
        case(csrno[11:0])
        `CSR_HARTID:    ;
        `CSR_TVEC:
            case(csrno[13:12])
            `OL_MACHINE:    mtvec <= dat;
            `OL_HYPERVISOR: htvec <= dat;
            `OL_SUPERVISOR: stvec <= dat;
            `OL_USER:       ;
            endcase
        `CSR_PCR:  
            if (csrno[13:12]<=`OL_SUPERVISOR)
                pcr <= dat;
        `CSR_PCR2:  
            if (csrno[13:12]<=`OL_SUPERVISOR)
                pcr2 <= dat;
        `CSR_EXROUT:
            if (csrno[13:12]==`OL_MACHINE)
                mexrout <= dat;
        `CSR_CAUSE:
            case(csrno[13:12])
            `OL_MACHINE:    mcause <= dat;
            `OL_HYPERVISOR: hcause <= dat;
            `OL_SUPERVISOR: scause <= dat;
            `OL_USER:       ;
            endcase
        `CSR_SCRATCH:   
            case(csrno[13:12])
            `OL_MACHINE:    mscratch <= dat;
            `OL_HYPERVISOR: hscratch <= dat;
            `OL_SUPERVISOR: sscratch <= dat;
            `OL_USER:       ;
            endcase
        `CSR_SP:        sp[csrno[13:12]] <= dat;
        `CSR_SBL:       sbl[csrno[13:12]] <= dat;
        `CSR_SBU:       sbu[csrno[13:12]] <= dat;
        `CSR_CISC:
            if (csrno[13:12]==`OL_MACHINE)
                cisc <= dat;
        `CSR_SEMA:
            if (csrno[13:12]==`OL_MACHINE)
                msema <= dat;
        `CSR_CONFIG:    mconfig <= dat;
        `CSR_PCHNDX:
            if (csrno[13:12]<=`OL_HYPERVISOR)
                pchndx <= dat[5:0];
        endcase
    `CSRRS:
        case(csrno[11:0])
        `CSR_EXROUT:
            if (csrno[13:12]==`OL_MACHINE)
                mexrout <= mexrout | dat;
        `CSR_PCR:
            if (csrno[13:12]<=`OL_SUPERVISOR)
               pcr <= pcr | dat;
        `CSR_PCR2:
           if (csrno[13:12]<=`OL_SUPERVISOR)
              pcr2 <= pcr2 | dat;
        `CSR_SEMA:
            if (csrno[13:12]==`OL_MACHINE)
                msema <= msema | dat;
        `CSR_CONFIG:
            if (csrno[13:12]==`OL_MACHINE)
                mconfig <= mconfig | dat;
        endcase
    `CSRRC:
        case(csrno[11:0])
        `CSR_EXROUT:
            if (csrno[13:12]==`OL_MACHINE)
                mexrout <= mexrout & ~dat;
        `CSR_PCR:
            if (csrno[13:12]<=`OL_SUPERVISOR)
                pcr <= pcr & ~dat;
        `CSR_PCR2:
            if (csrno[13:12]<=`OL_SUPERVISOR)
                pcr2 <= pcr2 & ~dat;
        `CSR_SEMA:
            if (csrno[13:12]==`OL_MACHINE)
                msema <= msema & ~dat;
        `CSR_CONFIG:
            if (csrno[13:12]==`OL_MACHINE)
                mconfig <= mconfig & ~dat;
        endcase
    default:    ;
    endcase
    else begin
        ex_fault(`FLT_PRIV,0);
    end
end
endtask

task disassem;
input [39:0] ir;
begin
    case(ir[7:0])
    `OR:    if (ir[13:8]==6'd0)
                $display("LDI r%d,#%d", ir[19:14], ir[39:20]);
            else
                $display("OR r%d,r%d,#%d", ir[19:14], ir[13:8], ir[39:20]);
    `ADD:   $display("ADD r%d,r%d,#%d", ir[19:14], ir[13:8], ir[39:20]);
    `LDW:   $display("LDW r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `LDWU:  $display("LDWU r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `LDT:   $display("LDT r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `LDTU:  $display("LDTU r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `LDD:   $display("LDD r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `STW:   $display("STW r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `STT:   $display("STT r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `STD:   $display("STD r%d,%d[r%d]", ir[19:14], ir[39:20], ir[13:8]);
    `PUSH:  $display("PUSH r%d", ir[13:8]);
    `POP:   $display("POP r%d", ir[19:14]);
    `CALL:  $display("CALL %h[r%d]", ir[39:20], ir[13:8]);
    `JMP32: $display("JMP %h", ir[39:8]);
    `CALL32: $display("CALL %h", ir[39:8]);
    `RET:   $display("RET #%d", ir[23:8]);
    endcase
end
endtask

endmodule

