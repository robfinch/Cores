// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Waterloo
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
`include "DSD9_defines.v"

module DSD9(hartid_i, rst_i, clk_i, irq_i, icause_i, cyc_o, stb_o, lock_o, ack_i, err_i, wr_o, sel_o, adr_o, dat_i, dat_o, cr_o, sr_o, rb_i);
parameter WID = 80;
parameter PCMSB = 31;
input [79:0] hartid_i;
input rst_i;
input clk_i;
input irq_i;
input [8:0] icause_i;
output reg cyc_o;
output reg stb_o;
output reg lock_o;
input ack_i;
input err_i;
output reg wr_o;
output reg [15:0] sel_o;
output reg [31:0] adr_o;
input [127:0] dat_i;
output reg [127:0] dat_o;
output reg cr_o;
output reg sr_o;
input rb_i;

parameter TRUE = 1'b1;
parameter FALSE = 1'b0;

parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter deci = 3'd4;

parameter RESTART1 = 6'd1;
parameter RESTART2 = 6'd2;
parameter RESTART3 = 6'd3;
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
parameter LOAD3a = 6'd21;
parameter LOAD3b = 6'd22;
parameter LOAD4 = 6'd23;
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

reg [5:0] state;
reg [5:0] retstate;                 // state stack 1-entry
reg [1:0] ol;                       // operating level
reg [7:0] cpl;                      // privilege level
reg [PCMSB:0] pc,dpc,xpc;
reg [PCMSB:0] epc [0:4];
wire ipredict_taken;
reg dpredict_taken,xpredict_taken;
reg [PCMSB:0] br_disp;
wire [119:0] insn;
reg [119:0] iinsn;
reg [127:0] dir,xir;
wire [7:0] iopcode = iinsn[7:0];
wire [7:0] dopcode = dir[7:0];
wire [7:0] dfunct = dir[39:32];
wire [7:0] xopcode = xir[7:0];
wire [7:0] xfunct = xir[39:32];
wire [2:0] Sc = xir[30:28];
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
wire iack = ack_i|mmu_ack;
wire [127:0] idat = dat_i|{4{mmu_dat}};
wire [31:0] mmu_dati = dat_o >> {ea[3:1],4'h0};
reg [5:0] Ra,Rb,Rc,Rd,Re;
reg [5:0] xRt,xRa,xRb;
reg xRt2;
reg [2:0] mem_size;
reg [WID-1:0] xb;
reg [WID-1:0] res, lres, lres1;
reg [WID-1:0] res2;
reg stuff_fault;
reg [23:0] fault_insn;
reg im;
reg [4:0] mimcd;
reg gie;        // global interrupt enable    
reg dinv,xinv;
reg i54,i80;
reg upd_rf;
reg [31:0] dea;
reg [127:0] idat1, idat2;

// CSR registers
reg [79:0] cisc;
reg [31:0] rdinstret;
reg [79:0] tick;
reg [79:0] mtime;
reg [5:0] pchndx;
reg [31:0] sbl[0:3],sbu[0:3];
reg [31:0] mconfig;
// Machine
reg [31:0] pcr;
reg [31:0] mbadaddr;
reg [79:0] mscratch;
reg [31:0] msema;
reg [31:0] mtvec;
reg [31:0] mexrout;
reg [79:0] mstatus;
reg [31:0] mcause;
reg [511:0] mtdeleg;
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

function [79:0] fnAbs;
input [79:0] jj;
fnAbs = jj[79] ? -jj : jj;
endfunction


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction fetch stage combinational logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [3:0] pc_inc;
always @(iinsn)
casex(iinsn[7:0])
`NOP,`CLI,`SEI,`WAI,`IRET,`MEMSB,`MEMDB,`SYNC,
`MFLT0,`MFLTF:
    pc_inc = 4'd1;
`PUSH,`POP:
    pc_inc = 4'd2;
`MOV,`ADDI10,`RET,`BRK,`LDDBP:
    pc_inc = 4'd3;
`LDD12:
    pc_inc = 4'd4;
default:
    if (iinsn[47:44]==4'hC && iinsn[87:84]==4'hC)
        pc_inc = 4'd15;
    else if (iinsn[47:44]==4'hC)
        pc_inc = 4'd10;
    else
        pc_inc = 4'd5;
endcase

wire [31:0] ibr_disp = {{15{iinsn[39]}},iinsn[39:22]};

// A stuffed fault will have occurred earlier than a pending IRQ
// hence takes precedence.
always@*
    if (stuff_fault)
        iinsn = {5{fault_insn}};
    else if (irq_i & ~im & gie)
        iinsn = {5{7'd0,icause_i,`BRK}};
    else
        iinsn = insn;

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

reg xJmp, xCall ,xRet;
wire dJmp = dopcode==`JMP;
wire dCall = dopcode==`CALL;
wire dRet = dopcode==`RET;

reg xIsPredictableBranch,xIsBranch;
wire dIsBranch =
    dopcode==`BEQ || dopcode==`BNE ||
    dopcode==`BLT || dopcode==`BGE || dopcode==`BLE || dopcode==`BGT ||
    dopcode==`BLTU || dopcode==`BGEU || dopcode==`BLEU || dopcode==`BGTU ||
    dopcode==`BEQI || dopcode==`BNEI ||
    dopcode==`BLTI || dopcode==`BGEI || dopcode==`BLEI || dopcode==`BGTI ||
    dopcode==`BLTUI || dopcode==`BGEUI || dopcode==`BLEUI || dopcode==`BGTUI ||
    dopcode==`BBC || dopcode==`BBS ||
    dopcode==`FBEQ || dopcode==`FBNE ||
    dopcode==`FBLT || dopcode==`FBGE || dopcode==`FBLE || dopcode==`FBGT ||
    dopcode==`FBOR || dopcode==`FBUN;
wire dIsPredictableBranch =
    (dir[21]==1'b0 && (dopcode==`BEQ || dopcode==`BNE ||
    dopcode==`BLT || dopcode==`BGE || dopcode==`BLE || dopcode==`BGT ||
    dopcode==`BLTU || dopcode==`BGEU || dopcode==`BLEU || dopcode==`BGTU)) ||
    dopcode==`BEQI || dopcode==`BNEI ||
    dopcode==`BLTI || dopcode==`BGEI || dopcode==`BLEI || dopcode==`BGTI ||
    dopcode==`BLTUI || dopcode==`BGEUI || dopcode==`BLEUI || dopcode==`BGTUI ||
    dopcode==`BBC || dopcode==`BBS ||
    dopcode==`FBEQ || dopcode==`FBNE ||
    dopcode==`FBLT || dopcode==`FBGE || dopcode==`FBLE || dopcode==`FBGT ||
    dopcode==`FBOR || dopcode==`FBUN;

wire dMul = dopcode==`R2 && (dfunct==`MUL || dfunct==`MULH);
wire dMulu = dopcode==`R2 && (dfunct==`MULU || dfunct==`MULUH);
wire dMulsu = dopcode==`R2 && (dfunct==`MULSU || dfunct==`MULSUH);
wire dMuli = dopcode==`MUL || dopcode==`MULH;
wire dMului = dopcode==`MULU || dopcode==`MULUH;
wire dMulsui = dopcode==`MULSU || dopcode==`MULSUH;
reg xMul,xMulu,xMulsu,xMuli,xMului,xMulsui,xIsMul;
wire dIsMul = dMul|dMulu|dMulsu|dMuli|dMului|dMulsui;

wire dDiv = dopcode==`DIV || dopcode==`DIVU || dopcode==`DIVSU || dopcode==`REM || dopcode==`REMU || dopcode==`REMSU ||
             (dopcode==`R2 && (dfunct==`DIV || dfunct==`DIVU || dfunct==`DIVSU || dfunct==`REM || dfunct==`REMU || dfunct==`REMSU))
             ;
wire dDivi = dopcode==`DIV || dopcode==`DIVU || dopcode==`DIVSU || dopcode==`REM || dopcode==`REMU || dopcode==`REMSU;
wire dDivss = dopcode==`DIV || (dopcode==`R2 && (dfunct==`DIV || dfunct==`REM));
wire dDivsu = dopcode==`DIVSU || (dopcode==`R2 && (dfunct==`DIVSU || dfunct==`REMSU));
wire dIsDiv = dDiv;
reg xDiv,xDivi,xDivss,xDivsu,xIsDiv;

reg xFloat;
wire dFloat = dopcode==`FLOAT;

reg xIsLoad,xIsStore;
wire dIsLoad = dopcode==`LDB || dopcode==`LDBU || dopcode==`LDW || dopcode==`LDWU || dopcode==`LDT || dopcode==`LDTU ||
               dopcode==`LDP || dopcode==`LDPU || dopcode==`LDD ||
               dopcode==`LDVDAR ||
               dopcode==`LDBX || dopcode==`LDBUX || dopcode==`LDWX || dopcode==`LDWUX || dopcode==`LDTX || dopcode==`LDTUX ||
               dopcode==`LDPX || dopcode==`LDPUX || dopcode==`LDDX ||
               dopcode==`LDVDARX ||
               dopcode==`LDDBP || dopcode==`LDD12;
                              
wire dIsStore = dopcode==`STB || dopcode==`STW || dopcode==`STP || dopcode==`STD || dopcode==`STDCR || dopcode==`STT ||
                dopcode==`STBX || dopcode==`STWX || dopcode==`STPX || dopcode==`STDX || dopcode==`STDCRX || dopcode==`STTX;

wire xIsMultiCycle = xIsLoad || xIsStore || xopcode==`POP || xopcode==`PUSH || xopcode==`CALL || xopcode==`RET || xopcode==`FLOAT;

reg xCsr;
wire dCsr = dopcode==`CSR;

function [WID-1:0] fwd_mux;
input [5:0] Rn;
case(Rn)
6'd00:  fwd_mux = {WID{1'b0}};
xRt: fwd_mux = res;
6'd01:  fwd_mux = r1;
6'd02:  fwd_mux = r2;
6'd58:  fwd_mux = r58;
6'd60:  fwd_mux = r60[ol];
6'd61:  fwd_mux = r61[ol];
6'd62:  fwd_mux = r62[ol];  
6'd63:  fwd_mux = sp [ol];
default:    fwd_mux = regfile[Rn];
endcase
endfunction

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
    .clk(clk_i),
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

reg xldfp;
wire [79:0] fpu_o;
wire [31:0] fpstatus;
wire fpdone;
fpUnit #(80) u12
(
    .rst(rst_i),
    .clk(clk_i),
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

always @*
    case(xopcode)
    `R2:
        case(xfunct)
        `ADD,`ADDU: res = a + b;
        `SUB,`SUBU: res = a - b;
        `CMP:   res = $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
        `CMPU:  res = a < b ? -1 : a==b ? 0 : 1;
        `AND:   res = logic_o;
        `OR:    res = logic_o;
        `XOR:   res = logic_o;
        `NAND:  res = logic_o;
        `NOR:   res = logic_o;
        `XNOR:  res = logic_o;
        `ANDN:  res = logic_o;
        `ORN:   res = logic_o;
        `SHL:   res = shift_o;
        `SHR:   res = shift_o;
        `ASL:   res = shift_o;
        `ASR:   res = shift_o;
        `ROL:   res = shift_o;
        `ROR:   res = shift_o;
        `SHLI:  res = shift_o;
        `SHRI:  res = shift_o;
        `ASLI:  res = shift_o;
        `ASRI:  res = shift_o;
        `ROLI:  res = shift_o;
        `RORI:  res = shift_o;
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
        default:    res  = 0;
        endcase
    `MOV:   res = a;
    `ADD,`ADDU:   res = a + imm;
    `ADDI10:      res = a + imm;
    `SUB,`SUBU:   res = a - imm;
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
    `LDDBP,`LDD12,            
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDP,`LDPU,`LDD,`LDVDAR,
    `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDPX,`LDPUX,`LDDX,`LDVDARX:
            res = lres;
    `JMP:   res = xpc + 32'd5;
    `CALL:  res = a - 32'd10;
    `PUSH:  res = a - 32'd10;
    `RET:   res = a + imm;
    `CSR:   case(xir[37:36])
            2'd0:   read_csr(xir[35:22],res);
            2'd1:   read_csr(a[13:0],res);
            2'd2:   read_csr(a[13:0],res);
            2'd3:   read_csr(xir[35:22],res);
            endcase
    default:    res = {WID{1'b0}};
    endcase

always @*
    case(xopcode)
    `POP:   res2 = a + 32'd10;
    default:    res2 = a + 32'd10;
    endcase


function Need2Cycles;
input [2:0] mem_size;
input [31:0] adr;
case(mem_size)
byt:    Need2Cycles = FALSE;
wyde:   Need2Cycles = adr[3:0]==4'hF;
tetra:  Need2Cycles = adr[3:0] >4'hC;
penta:  Need2Cycles = adr[3:0] >4'hB;
deci:   Need2Cycles = adr[3:0] >4'h6;
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
    .xIsBranch(xIsPredictableBranch),
    .advanceX(advanceEX),
    .pc(pc),
    .xpc(xpc),
    .takb(takb),
    .predict_taken(ipredict_taken)
);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg IsLastICacheWr;
wire ihit,ihit0,ihit1;
DSD9_icache u1
(
    .wclk(clk_i),
    .wr(IsICacheLoad & (ack_i|err_i)),
    .wadr(adr_o),
    .i(dat_i),
    .rclk(~clk_i),
    .radr(pc),
    .o(insn),
    .hit(ihit),
    .hit0(ihit0),
    .hit1(ihit1)
);

wire dhit0,dhit1,dhit;
wire [79:0] dc_dat;
reg [1:0] dcmf;
DSD9_dcache u2
(
    .wclk(clk_i),
    .wr(ack_i & (IsDCacheLoad | (dhit & wr_o))),
    .sel(wr_o ? sel_o : 16'hFFFF),
    .wadr(adr_o),
    .i(IsDCacheLoad ? dat_i : dat_o),
    .rclk(clk_i),
    .radr(pea),
    .o(dc_dat),
    .hit(dhit),
    .hit0(dhit0),
    .hit1(dhit1)
);

DSD9_mmu u6
(
    .rst_i(rst_i),
    .clk_i(clk_i),
    .pcr_i(pcr),
    .s_cyc_i(cyc_o),
    .s_stb_i(stb_o),
    .s_ack_o(mmu_ack),
    .s_wr_i(wr_o),
    .s_adr_i(ea),
    .s_dat_i(mmu_dati),
    .s_dat_o(mmu_dat),
    .pea_o(pea)
);
/*
assign advanceEX = 1'b1;
assign advanceDC = advanceEX && !(xIsMultiCycle && !xinv);
assign advanceIF = advanceDC && ihit;
*/
assign advanceEX = !xIsMultiCycle;
assign advanceDC = advanceEX | xinv;
assign advanceIF = (advanceDC | dinv) & (ihit && !IsICacheLoad);

always @(posedge clk_i)
if (rst_i) begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    wr_o <= `LOW;
    sel_o <= 16'h0000;
    tick <= 80'd0;
    ol <= 2'b00;
    cpl <= 8'h00;
    ea <= 32'hFFFC0000;
    pc <= 32'hFFFC0000;
    mtvec <= 32'hFFFC0100;
    xldfp <= `FALSE;
    IsICacheLoad <= `TRUE;
    IsDCacheLoad <= `TRUE;
    xinv <= `TRUE;
    dinv <= `TRUE;
    pcr <= 32'h00;
    next_state(RESTART1);
end
else begin

xldfp <= `FALSE;
upd_rf <= `FALSE;
update_regfile();
tick <= tick + 80'd1;

case(state)

// -----------------------------------------------------------------------------
// Restart:
// Load the first 16kB of the I-Cache to set all the tags to a valid state. 
// -----------------------------------------------------------------------------
RESTART1:
    next_state(RESTART2);
RESTART2:
    next_state(RESTART3);
RESTART3:
    begin
        cyc_o <= `HIGH;
        stb_o <= `HIGH;
        sel_o <= 16'hFFFF;
        adr_o <= pea;
        next_state(RESTART4);
    end
RESTART4:
    if (ack_i|err_i) begin
        next_state(RESTART1);
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
        if (stuff_fault)
            stuff_fault <= `FALSE;
        if (iopcode==`BRK) begin
            Ra <= 6'd63;
            Rb <= 6'd1;
            Rc <= 6'd2;
        end
        else if (iopcode==`PEA || iopcode==`CALL || iopcode==`POP || iopcode==`PUSH || iopcode==`RET) begin
            Ra <= 6'd63;
            Rb <= iinsn[13:8];
            Rc <= iinsn[19:14];
        end
        else if (iopcode==`LDDBP) begin
            Ra <= 6'd59;
            Rb <= iinsn[13:8];
            Rc <= iinsn[19:14];
        end
        else begin
            Ra <= iinsn[13:8];
            Rb <= iinsn[19:14];
            Rc <= iinsn[27:22];
        end
        i80 <= `FALSE;
        i54 <= `FALSE;
        if (iinsn[47:44]==4'hC && iinsn[87:84]==4'hC)
            i80 <= `TRUE;
        else if (iinsn[47:44]==4'hC)
            i54 <= `TRUE;
        dinv <= `FALSE;
        pc <= pc + pc_inc;
        dpc <= pc;
        case(iopcode)
        `BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU:
            if (iinsn[21]) begin
                dpredict_taken <= iinsn[20];
                if (iinsn[20])
                    pc <= pc + ibr_disp;
            end
            else begin
                dpredict_taken <= ipredict_taken;
                if (ipredict_taken)
                    pc <= pc + ibr_disp;
            end
        `FBEQ,`FBNE,`FBLT,`FBGE,`FBLE,`FBGT,`FBOR,`FBUN,
        `BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI,`BBC,`BBS:
            begin
                dpredict_taken <= ipredict_taken;
                if (ipredict_taken)
                    pc <= pc + ibr_disp;
            end
        default: dpredict_taken <= ipredict_taken;
        endcase
        if (iopcode==`WAI && ~irq_i)
            pc <= pc;
        dinv <= `FALSE;
        dir <= iinsn;
    end
    else begin
        dir <= {16{`NOP}};
        if (!ihit) begin
            pc <= pc;
            icmf <= {~ihit1,~ihit0};
            iccnt <= 3'd0;
            next_state(LOAD_ICACHE1);
        end
        if (advanceDC) begin
            dpc <= pc;
            pc <= pc;
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
        xIsMul <= dIsMul;
        
        xDiv <= dDiv;
        xDivi <= dDivi;
        xDivss <= dDivss;
        xDivsu <= dDivsu;
        xIsDiv <= dIsDiv;
        xFloat <= dFloat;
        xldfp <= `TRUE;

        xJmp <= dJmp;
        xCall <= dCall;
        xRet <= dRet;
        xIsBranch <= dIsBranch;
        xIsLoad <= dIsLoad;
        xIsStore <= dIsStore;
        xCsr <= dCsr;

        xIsPredictableBranch <= dIsPredictableBranch;
        xpredict_taken <= dpredict_taken;
        a <= fwd_mux(Ra);
        b <= fwd_mux(Rb);
        c <= fwd_mux(Rc);
        case(dopcode)
        `R2:
          case(dfunct)
          `SHLI,`ASLI,`SHRI,`ASRI,`ROLI,`RORI:     b[6:0] <= {dir[26],Rb};
          default:    ;
          endcase
        default:  ;
        endcase
        case(dopcode)
        `CSR,
        `BEQI,`BNEI,`BLTI,`BLEI,`BGTI,`BGEI,`BLTUI,`BLEUI,`BGTUI,`BGEUI:
            if (i80)//        32          4         32          4          8
                imm <= {dir[119:88],dir[83:80],dir[79:48],dir[43:40],dir[21:14]};
            else if (i54) //              32          4          8
                imm <= {{36{dir[79]}},dir[79:48],dir[43:40],dir[21:14]};
            else
                imm <= {{72{dir[21]}},dir[21:14]};
        `ADDI10,`LDDBP: imm <= {{70{dir[23]}},dir[23:14]};
        `LDD12:  imm <= {{68{dir[31]}},dir[31:20]};
        `RET:    imm <= dir[23:8];
        default:
            if (i80)    //    20          4         32          4         20
                imm <= {dir[107:88],dir[83:80],dir[79:48],dir[43:40],dir[39:20]};
            else if (i54)
                imm <= {{24{dir[79]}},dir[79:48],dir[43:40],dir[39:20]};
            else
                imm <= {{60{dir[39]}},dir[39:20]};
        endcase
        br_disp <= {{15{dir[39]}},dir[39:22]};
        xRa <= Ra;
        xRb <= Rb;
        xRt <= 6'd0;
        xRt2 <= 1'b0;
        if (!dinv)
        case (dopcode)
        `R2:
            case(dfunct)
            `LEAX,
            `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
            `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
                xRt <= dir[27:22];
            default:    xRt <= 6'd0;
            endcase
        `LEA,
        `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR:
            xRt <= dir[19:14];
        `CSR:   case(dir[38:36])
                3'd0:   xRt <= dir[13:8];
                3'd1:   xRt <= dir[27:22];
                3'd2:   xRt <= dir[27:22];
                3'd3:   xRt <= dir[19:14];
                default:    xRt <= 6'd0;
                endcase 
        `ADDI10: xRt <= xir[13:8];
        endcase
        if (!dinv)
        case (dopcode)
        `R2:
            case(dfunct)
            `LEAX,
            `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR,`NAND,`NOR,`XNOR,`ANDN,`ORN,
            `SHL,`SHR,`ASL,`ASR,`ROL,`ROR,`SHLI,`SHRI,`ASLI,`ASRI,`ROLI,`RORI:
                upd_rf <= `TRUE;
            default:    upd_rf <= `FALSE;
            endcase
        `LEA,
        `ADD,`SUB,`CMP,`CMPU,`AND,`OR,`XOR:
                upd_rf <= `TRUE;
        `CSR:   case(dir[38:36])
                3'd0:   upd_rf <= `TRUE;
                3'd1:   upd_rf <= `TRUE;
                3'd2:   upd_rf <= `TRUE;
                3'd3:   upd_rf <= `TRUE;
                default:    upd_rf <= `FALSE;
                endcase
        `ADDI10: upd_rf <= `TRUE; 
        endcase
    end
    else if (advanceEX)
        inv_xir();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // If the execute stage has been invalidated it doesn't do anything. 
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (!xinv) begin
        if (xIsBranch) begin
            if (xpredict_taken & ~takb)
                ex_branch(xpc + 32'd5);
            else if (~xpredict_taken & takb)
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
            epc[0] <= xir[23] ? xpc + 32'd5 : xpc;
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
            im <= mstatus[0];
            mstatus[54:0] <= {8'h00,2'b00,1'b1,mstatus[54:11]};
            ex_branch(epc[0]);
            epc[0] <= epc[1];
            epc[1] <= epc[2];
            epc[2] <= epc[3];
            epc[3] <= epc[4];
            epc[4] <= `MSU_VECT;
        end
        if (xMflt)
            ex_fault(`FLT_MEM,0);
        if (xRex)
            ex_rex();
        if (xJmp)
            if (xRa==6'd63)
                ex_branch(xpc + imm);
            else
                ex_branch(a + imm);
        if (xCall) begin
            mem_size <= deci;
            dea <= a - 32'd10;
            xb <= xpc + 32'd5;
            next_state(STORE1);
        end
        if (xRet) begin
            mem_size <= deci;
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

        case(xopcode)
           
        `LDB,`LDBU: begin mem_size <= byt; dea <= a + imm; next_state(LOAD1); end
        `LDW,`LDWU: begin mem_size <= wyde; dea <= a + imm; next_state(LOAD1); end
        `LDT,`LDTU: begin mem_size <= tetra; dea <= a + imm; next_state(LOAD1); end
        `LDP,`LDPU: begin mem_size <= penta; dea <= a + imm; next_state(LOAD1); end
        `LDD,`LDDBP,`LDD12: begin mem_size <= deci; dea <= a + imm; next_state(LOAD1); end
        `LDBX,`LDBUX: begin mem_size <= byt; dea <= siea; next_state(LOAD1); end
        `LDWX,`LDWUX: begin mem_size <= wyde; dea <= siea; next_state(LOAD1); end
        `LDTX,`LDTUX: begin mem_size <= tetra; dea <= siea; next_state(LOAD1); end
        `LDPX,`LDPUX: begin mem_size <= penta; dea <= siea; next_state(LOAD1); end
        `LDDX: begin mem_size <= deci; dea <= siea; next_state(LOAD1); end
        `STB: begin mem_size <= byt; dea <= a + imm; xb <= b; next_state(STORE1); end
        `STW: begin mem_size <= wyde; dea <= a + imm; xb <= b; next_state(STORE1); end
        `STT: begin mem_size <= tetra; dea <= a + imm; xb <= b; next_state(STORE1); end
        `STP: begin mem_size <= penta; dea <= a + imm; xb <= b; next_state(STORE1); end
        `STD: begin mem_size <= deci; dea <= a + imm; xb <= b; next_state(STORE1); end
        `STBX: begin mem_size <= byt; dea <= siea; xb <= c; next_state(LOAD1); end
        `STWX: begin mem_size <= wyde; dea <= siea; xb <= c; next_state(LOAD1); end
        `STTX: begin mem_size <= tetra; dea <= siea; xb <= c; next_state(LOAD1); end
        `STPX: begin mem_size <= penta; dea <= siea; xb <= c; next_state(LOAD1); end
        `STDX: begin mem_size <= deci; dea <= siea; xb <= c; next_state(LOAD1); end
        `PUSH:  begin mem_size <= deci; dea <= a - 80'd10; xb <= b; next_state(STORE1); end
        `POP:   begin mem_size <= deci; dea <= a; next_state(LOAD1); end
        endcase
    end
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
MUL4:   next_state(MUL5);
MUL5:   next_state(MUL9);
MUL9:
    begin
        mul_prod <= mul_sign ? -mul_prod1 : mul_prod1;
        case(xopcode)
        `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH:
            xRt <= xir[19:14];
        `R2:
            case(xfunct)
            `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH:
                xRt <= xir[25:20];
            endcase
        endcase
        upd_rf <= `TRUE;
        next_state(INVnRUN);
        if (multovf & mexrout[5]) begin
            if (mexrout[4]) begin
                r1 <= `FLT_OFL;
                r2 <= `FLT_TYPE;
                ex_branch(r58);
            end
            else begin
                ex_fault(`FLT_DBZ,0);
            end
        end
    end

DIV1:
    if (dvd_done) begin
        case(xopcode)
        `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
            xRt <= xir[19:14];
        `R2:
            case(xfunct)
            `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
                xRt <= xir[25:20];
            endcase
        endcase
        upd_rf <= `TRUE;
        next_state(INVnRUN);
        if (dvByZr & mexrout[3]) begin
            if (mexrout[2]) begin
                r1 <= `FLT_DBZ;
                r2 <= `FLT_TYPE;
                ex_branch(r58);
            end
            else begin
                ex_fault(`FLT_DBZ,0);
            end
        end
    end

FLOAT1:
    if (fpdone) begin
        case(xir[25:20])
        `FABS,`FMAN,`FMOV,`FNABS,`FNEG,`FSIGN,`FTOI,`ITOF:
                xRt <= xir[31:26];
        `FCMP:  xRt <= xir[31:26];
        `FADD:  xRt <= xir[31:26];
        `FSUB:  xRt <= xir[31:26];
        `FMUL:  xRt <= xir[31:26];
        `FDIV:  xRt <= xir[31:26];
        default: xRt <= 6'd0;
        endcase
        upd_rf <= `TRUE;
        inv_xir();
        next_state(RUN);
        if (fpstatus[9]) begin  // GX status bit
            if (mexrout[1]) begin
                r1 <= `FLT_FLT; // 486 = bounds check
                r2 <= `FLT_TYPE;   // type: exception
                ex_branch(r58);
            end
            else begin
                ex_fault(`FLT_FLT,0);
            end
        end
    end

LOAD1:
    begin
        ea <= dea;
        if ((xRa==6'd63 || xRa==6'd59)&&(dea < sbl[ol] || dea > sbu[ol]))
            ex_fault(`FLT_STACK,0);
        else begin
            next_state(LOAD1a);
        end
    end
    // Wait two cycles for mmu address translation
LOAD1a:
    next_state(LOAD1b);
LOAD1b:
    next_state(LOAD1c);
    // Address translation should be done by now
    // Now wait for data cache to respond
LOAD1c:
    next_state(LOAD1d);
LOAD1d:
    next_state(LOAD1e);
LOAD1e:
    next_state(LOAD1f);
LOAD1f:
    begin
        if (dhit)
            load1(1'b1);
        // If dea[31] is zero then the data should be cached.
        // Load the data cache on a miss.
        else if (~dea[31]) begin
            dcmf <= {~dhit1,~dhit0};
            retstate <= LOAD1b;
            next_state(LOAD_DCACHE1);
        end
        // Else, uncached data is required (I/O)
        else begin
            read1(mem_size,pea,dea);
            if (xopcode==`INC)
                lock_o <= `TRUE;
            next_state(LOAD2);
        end
    end
LOAD2:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i) begin
        ea <= {dea[31:4]+28'd1,4'h0};
        load1(1'b0);
    end // LOAD2
    // Wait for address translation
LOAD3:
    next_state(LOAD3a);
LOAD3a:
    next_state(LOAD3b);
LOAD3b:
    begin
        read2(mem_size,pea,dea);
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
    else if (ack_i) begin
        wb_nack();
        next_state(LOAD5);
    end
LOAD5:
    begin
        next_state(INVnRUN);
        upd_rf <= `TRUE;
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
        `LDTU,`LDTUX:
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
        `LDD,`LDDX,`POP,`RET,`LDDBP,`LDD12:
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
        `LDW,`LDWU,`LDP,`LDPU,`LDD:   
            xRt <= xir[19:14];
        `LDWX,`LDWUX,`LDPX,`LDPUX,`LDDX:
            xRt <= xir[25:20];
        `POP:
            begin
            xRt2 <= `TRUE;
            xRt <= xir[13:8];
            end
        `RET:
            xRt <= 6'd63;   
        endcase
    end // LOAD5

STORE1:
    begin
        ea <= dea;
        if ((xRa==6'd63 || xRa==6'd59)&&(dea < sbl[ol] || dea > sbu[ol]))
            ex_fault(`FLT_STACK,0);
        else begin
            $display("Store to %h <= %h", dea, xb);
            next_state(STORE1a);
        end
    end
STORE1a:
    next_state(STORE1b);
STORE1b:
    next_state(STORE1c);
STORE1c:
    begin
        write1(mem_size,pea,dea,xb);
        next_state(STORE2);
    end
STORE2:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i) begin
        stb_o <= `LOW;
        if (Need2Cycles(mem_size,dea)) begin
            ea <= {dea[31:4]+28'd1,4'h0};
            next_state(STORE3);
        end
        else begin
            wb_nack();
            lock_o <= `LOW;
            next_state(INVnRUN);
            case(xopcode)
            `CALL,`PEA,`PUSH:
                begin
                    xRt <= 6'd63;    
                    upd_rf <= `TRUE;
                end
            endcase
        end
        cr_o <= `LOW;
        msema[0] <= rb_i;
    end // STORE2
STORE3:
    next_state(STORE3a);
STORE3a:
    next_state(STORE3b);
STORE3b:
    begin
        write2(mem_size,pea,dea);
        next_state(STORE4);
    end
STORE4:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= dea;
    end
    else if (ack_i) begin
        wb_nack();
        lock_o <= `LOW;
        case(xopcode)
        `CALL,`PEA,`PUSH:
            begin
                xRt <= 6'd63;    
                upd_rf <= `TRUE;
            end
        endcase
        next_state(INVnRUN);
    end

// Invalidate the xir and switch back to the run state.
// The xir is invalidated to prevent the instruction from executing again.
// Also performed is the control flow operations requiring a memory operand.

INVnRUN:
    begin
        inv_xir();
        case (xopcode)
        `CALL:
//            if (xRb!=5'd0) begin
                if (xRb==6'd63)
                    ex_branch(xpc + imm);
                else
                    ex_branch(b + imm);
//            end
        `RET:   ex_branch(lres);
        `FLOAT:
            if (xir[31:29]==3'd0 && xir[17:12]==6'd1)
                ex_branch(xpc + {xir[28:27],1'b0} + 32'd4);
        endcase
        next_state(RUN);
    end

// -----------------------------------------------------------------------------
// Load instruction cache lines.
// Each cache line is five 128 bit words in length.
// -----------------------------------------------------------------------------

LOAD_ICACHE1:
    begin
        if (icmf != 2'b00) begin
            IsICacheLoad <= `TRUE;
            if (icmf[0]) begin
                icmf[0] <= 1'b0;
                ea <= {pc[31:5],5'h0};
            end
            else if (icmf[1]) begin
                ea <= {pc[31:5]+27'd1,5'h0};
                icmf[1] <= 1'b0;
            end
            next_state(LOAD_ICACHE2);
        end
        else
            next_state(RUN);
    end
LOAD_ICACHE2:
    next_state(LOAD_ICACHE3);
LOAD_ICACHE3:
    next_state(LOAD_ICACHE4);
LOAD_ICACHE4:
    begin
        cyc_o <= `HIGH;
        stb_o <= `HIGH;
        sel_o <= 8'hFF;
        adr_o <= pea;
        next_state(LOAD_ICACHE5);
    end
LOAD_ICACHE5:
    if (ack_i|err_i) begin
        stb_o <= `LOW;
        next_state(LOAD_ICACHE2);
        ea <= ea + 32'd16;
        if (ea[4]) begin
            if (icmf==2'b00) begin
                IsICacheLoad <= `FALSE;
                wb_nack();
                next_state(RUN);
            end
            else begin
                next_state(LOAD_ICACHE1);
            end
        end
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
                dccnt <= 2'd0;
            end
            else if (dcmf[1]) begin
                ea <= {dea[31:5]+27'd1,5'h0};
                dccnt <= 2'd0;
                dcmf[1] <= 1'b0;
            end
            next_state(LOAD_DCACHE2);
        end
        else begin
            ea <= dea;
            next_state(retstate);
        end
    end
LOAD_DCACHE2:
    next_state(LOAD_DCACHE3);
LOAD_DCACHE3:
    next_state(LOAD_DCACHE4);
LOAD_DCACHE4:
    begin
        cyc_o <= `HIGH;
        stb_o <= `HIGH;
        sel_o <= 16'hFFFF;
        adr_o <= pea;
        next_state(LOAD_DCACHE5);
    end
LOAD_DCACHE5:
    if (ack_i|err_i) begin
        stb_o <= `LOW;
        dccnt <= dccnt + 2'd1;
        ea <= ea + 32'd16;
        next_state(LOAD_DCACHE2);
        if (dccnt==2'b01) begin
            if (dcmf==2'b00) begin
                IsDCacheLoad <= `FALSE;
                wb_nack();
                ea <= dea;
                next_state(retstate);
            end
            else begin 
                next_state(LOAD_DCACHE1);
            end
        end
    end

default:
    next_state(RUN);

endcase // state
end

// Register incoming data
always @(posedge clk_i)
    idat1 <= dat_i;
// Shift data into position
always @(posedge clk_i)
    if (dhit)
        lres1 <= dc_dat;
    else
        lres1 <= (idat1 >> {dea[3:0],3'h0}) | (idat1 << {~dea[3:0]+4'd1,3'h0});

task load1;
input dhit;
begin
    case(xopcode)
    `LDB:
        begin
            if (!dhit)
                wb_nack();
            lres <= {{72{lres1[7]}},lres1[7:0]};
            xRt <= xir[19:14];
            upd_rf <= `TRUE;
            next_state(INVnRUN);
        end
    `LDBU:
        begin
            if (!dhit)
                wb_nack();
            lres <= {{72{1'b0}},lres1[7:0]};
            xRt <= xir[19:14];
            upd_rf <= `TRUE;
            next_state(INVnRUN);
        end
    `LDBX:
        begin
            if (!dhit)
                wb_nack();
            lres <= {{72{lres1[7]}},lres1[7:0]};
            xRt <= xir[25:20];
            upd_rf <= `TRUE;
            next_state(INVnRUN);
        end
    `LDBUX:
        begin
            if (!dhit)
                wb_nack();
            lres <= {{72{1'b0}},lres1[7:0]};
            xRt <= xir[25:20];
            upd_rf <= `TRUE;
            next_state(INVnRUN);
        end
    `LDW:
        begin
            if (dhit) begin
                lres <= {{64{lres1[15]}},lres1[15:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0]!=4'hF) begin
                wb_nack();
                lres <= {{64{lres1[15]}},lres1[15:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDWX:
        begin
            if (dhit) begin
                lres <= {{64{lres1[15]}},lres1[15:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0]!=4'hF) begin
                wb_nack();
                lres <= {{64{lres1[15]}},lres1[15:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDWU:
        begin
            if (dhit) begin
                lres <= {{64{1'b0}},lres1[15:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0]!=4'hF) begin
                wb_nack();
                lres <= {{64{1'b0}},lres1[15:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDWUX:
        begin
            if (dhit) begin
                lres <= {{64{1'b0}},lres1[15:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0]!=4'hF) begin
                wb_nack();
                lres <= {{64{1'b0}},lres1[15:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDT:
        begin
            if (dhit) begin
                lres <= {{48{lres1[31]}},lres1[31:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hD) begin
                wb_nack();
                lres <= {{48{lres1[31]}},lres1[31:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDTX:
        begin
            if (dhit) begin
                lres <= {{48{lres1[31]}},lres1[31:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hD) begin
                wb_nack();
                lres <= {{48{lres1[31]}},lres1[31:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDTU:
        begin
            if (dhit) begin
                lres <= {{48{1'b0}},lres1[31:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hD) begin
                wb_nack();
                lres <= {{48{1'b0}},lres1[31:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDTUX:
        begin
            if (dhit) begin
                lres <= {{48{1'b0}},lres1[31:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hD) begin
                wb_nack();
                lres <= {{48{1'b0}},lres1[31:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDP:
        begin
            if (dhit) begin
                lres <= {{40{lres1[39]}},lres1[39:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hC) begin
                wb_nack();
                lres <= {{40{lres1[39]}},lres1[39:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDPX:
        begin
            if (dhit) begin
                lres <= {{40{lres1[39]}},lres1[39:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hC) begin
                wb_nack();
                lres <= {{40{lres1[39]}},lres1[39:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDPU:
        begin
            if (dhit) begin
                lres <= {{40{1'b0}},lres1[39:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hC) begin
                wb_nack();
                lres <= {{40{1'b0}},lres1[39:0]};
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDPUX:
        begin
            if (dhit) begin
                lres <= {{40{1'b0}},lres1[39:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'hC) begin
                wb_nack();
                lres <= {{40{1'b0}},lres1[39:0]};
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDD,`LDDBP,`LDD12:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'h7) begin
                wb_nack();
                lres <= lres1[79:0];
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `POP:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt2 <= `TRUE;
                xRt <= xir[13:8];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'h7) begin
                wb_nack();
                lres <= lres1[79:0];
                xRt2 <= `TRUE;
                xRt <= xir[13:8];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `LDDX:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'h7) begin
                wb_nack();
                lres <= lres1[79:0];
                xRt <= xir[25:20];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    `RET:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt <= 6'd63;
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (dea[3:0] < 4'h7) begin
                wb_nack();
                lres <= lres1[79:0];
                xRt <= 6'd63;
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else begin
                lres <= lres1;
                next_state(LOAD3);
            end
        end
    endcase // xopcode
end
endtask

task wb_nack;
begin
    cyc_o <= `LOW;
    stb_o <= `LOW;
    sel_o <= 16'h0000;
    wr_o <= `LOW;
end
endtask

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
    if (xopcode==`LDVDAR)
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
	wyde:  sel_o <= 16'h0001;
	tetra: sel_o <= 16'h000F >> (~orig_adr[3:0] + 4'd1);
	penta: sel_o <= 16'h001F >> (~orig_adr[3:0] + 4'd1);
	deci:  sel_o <= 16'h03FF >> (~orig_adr[3:0] + 4'd1);
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
    if (xopcode==`STDCR)
        cr_o <= 1'b1;
end
endtask

task write2;
input [2:0] sz;
input [31:0] adr;
input [31:0] orig_adr;
begin
    stb_o <= `TRUE;
	adr_o <= adr;
	case(sz)
	wyde:  sel_o <= 16'h0003 >> (~orig_adr[3:0] + 4'd1);
	tetra: sel_o <= 16'h000F >> (~orig_adr[3:0] + 4'd1);
	penta: sel_o <= 16'h001F >> (~orig_adr[3:0] + 4'd1);
	deci:  sel_o <= 16'h03FF >> (~orig_adr[3:0] + 4'd1);
	default:   sel_o <= 16'h0000;
    endcase
end
endtask

task inv_dir;
begin
    dinv <= TRUE;
end
endtask

task inv_xir;
begin
    xinv <= TRUE;
    xRt <= 6'd0;
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
    stuff_fault <= `TRUE;
    fault_insn <= { 2'b0, nib, ccd, `BRK};
    ex_branch(xpc);
    next_state(RUN);
end
endtask

task ex_ifault;
begin
    stuff_fault <= `TRUE;
    fault_insn <= { 3'b0, `FLT_IBE, `BRK};
    mbadaddr <= pc;
    ex_branch(`RST_VECT);
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
    `OL_USER:   ex_fault(`FLT_PRIV,0);
    `OL_MACHINE:
        case(xir[15:14])
        `OL_HYPERVISOR:
            if (him==`FALSE) begin
                hcause <= mcause;
                hbadaddr <= mbadaddr;
                ex_branch(htvec);
                ol <= xir[15:14];
                cpl <= 8'h01;   // no choice, it's 01
                mimcd <= 4'b1111;
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
                    mimcd <= 4'b1111;
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
                mimcd <= 4'b1111;
                him <= `FALSE;
            end
        end
    endcase
end
endtask

task ex_branch;
input [32:0] nxt_pc;
begin
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
        6'd01:  r1 <= res;
        6'd02:  r2 <= res;
        6'd58:  r58 <= res;
        6'd60:  r60[ol] <= res;
        6'd61:  r61[ol] <= res;
        6'd62:  r62[ol] <= res;
        6'd63:  sp[ol] <= {res[79:1],1'h0};
        endcase
        regfile[xRt] <= res;
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
    `CSR_HARTID:    res <= ol==`OL_MACHINE ? hartid_i : 80'd1;
    `CSR_TICK:      res <= tick;
    `CSR_PCR:       res <= pcr;
    `CSR_TVEC:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= stvec;
        `OL_HYPERVISOR: res <= htvec;
        `OL_MACHINE:    res <= mtvec;
        endcase
    `CSR_CAUSE:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= scause;
        `OL_HYPERVISOR: res <= hcause;
        `OL_MACHINE:    res <= mcause;
        endcase
    `CSR_BADADDR:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= sbadaddr;
        `OL_HYPERVISOR: res <= hbadaddr;
        `OL_MACHINE:    res <= mbadaddr;
        endcase
    `CSR_SCRATCH:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= sscratch;
        `OL_HYPERVISOR: res <= hscratch;
        `OL_MACHINE:    res <= mscratch;
        endcase
    `CSR_SP:      res <= sp[csrno[13:12]];
    `CSR_SBL:     res <= sbl[csrno[13:12]];
    `CSR_SBU:     res <= sbu[csrno[13:12]];
    `CSR_CISC:      res <= cisc;
    `CSR_STATUS:
        case(ol)
        `OL_USER:   res <= 64'd0;
        `OL_MACHINE:    res <= mstatus;
        `OL_HYPERVISOR: res <= hstatus;
        `OL_SUPERVISOR: res <= sstatus;
        endcase
    `CSR_FPSTAT:    res = fpstatus;
    `CSR_INSRET:    res <= rdinstret;
    `CSR_TIME:      res <= mtime;

    `CSR_EPC:       res <= epc[0];
    `CSR_CONFIG:    res <= mconfig;
    endcase
    else
        ex_fault(`FLT_PRIV,0);
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
        `CSR_SEMA:
            if (csrno[13:12]==`OL_MACHINE)
                msema <= msema | dat;
        endcase
    `CSRRC:
        case(csrno[11:0])
        `CSR_EXROUT:
            if (csrno[13:12]==`OL_MACHINE)
                mexrout <= mexrout & ~dat;
        `CSR_PCR:
            if (csrno[13:12]<=`OL_SUPERVISOR)
                pcr <= pcr & ~dat;
        `CSR_SEMA:
            if (csrno[13:12]==`OL_MACHINE)
                msema <= msema & ~dat;
        endcase
    endcase
    else
        ex_fault(`FLT_PRIV,0);
end
endtask

endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_icache_mem(wclk, wr, wadr, i, rclk, radr, o0, o1);
input wclk;
input wr;
input [31:0] wadr;
input [127:0] i;
input rclk;
input [31:0] radr;
output [255:0] o0;
output [255:0] o1;

reg [255:0] mem [0:511];
reg [8:0] rrcl,rrclp1;

//  instruction parcels per cache line
wire [8:0] wr_cache_line;
wire [8:0] rd_cache_line;

assign wr_cache_line = wadr >> 5;
assign rd_cache_line = radr >> 5;
wire wr0 = wr & ~wadr[4];
wire wr1 = wr & wadr[4];

always @(posedge wclk)
begin
    if (wr0) mem[wr_cache_line][127:0] <= i;
    if (wr1) mem[wr_cache_line][255:128] <= i;
end

always @(posedge rclk)
    rrcl <= rd_cache_line;        
always @(posedge rclk)
    rrclp1 <= rd_cache_line + 9'd1;
    
assign o0 = mem[rrcl];
assign o1 = mem[rrclp1];        

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_icache_tag(wclk, wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input [31:0] wadr;
input rclk;
input [31:0] radr;
output hit0;
output hit1;

reg [31:0] tagmem [0:511];
reg [31:0] rradr,rradrp32;

always @(posedge rclk)
    rradr <= radr;        
always @(posedge rclk)
    rradrp32 <= radr + 32'd32;

always @(posedge wclk)
    if (wr) tagmem[wadr[13:5]] <= wadr;

assign hit0 = tagmem[rradr[13:5]][31:14]==rradr[31:14];
assign hit1 = tagmem[rradrp32[13:5]][31:14]==rradrp32[31:14];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_icache(wclk, wr, wadr, i, rclk, radr, o, hit, hit0, hit1);
input wclk;
input wr;
input [31:0] wadr;
input [127:0] i;
input rclk;
input [31:0] radr;
output reg [119:0] o;
output hit;
output hit0;
output hit1;

wire [255:0] ic0, ic1;

DSD9_icache_mem u1
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr[31:0]),
    .i(i),
    .rclk(rclk),
    .radr(radr[31:0]),
    .o0(ic0),
    .o1(ic1)
);

DSD9_icache_tag u2
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0),
    .hit1(hit1)
);

always @(radr or ic0 or ic1)
case(radr[4:0])
5'h00:  o <= ic0[119:0];
5'h01:  o <= ic0[127:8];
5'h02:  o <= ic0[135:16];
5'h03:  o <= ic0[143:24];
5'h04:  o <= ic0[151:32];
5'h05:  o <= ic0[159:40];
5'h06:  o <= ic0[167:48];
5'h07:  o <= ic0[175:56];
5'h08:  o <= ic0[183:64];
5'h09:  o <= ic0[191:72];
5'h0A:  o <= ic0[199:80];
5'h0B:  o <= ic0[207:88];
5'h0C:  o <= ic0[215:96];
5'h0D:  o <= ic0[223:104];
5'h0E:  o <= ic0[231:112];
5'h0F:  o <= ic0[239:120];
5'h10:  o <= ic0[247:128];
5'h11:  o <= ic0[255:136];
5'h12:  o <= {ic1[7:0],ic0[255:144]};
5'h13:  o <= {ic1[15:0],ic0[255:152]};
5'h14:  o <= {ic1[23:0],ic0[255:160]};
5'h15:  o <= {ic1[31:0],ic0[255:168]};
5'h16:  o <= {ic1[39:0],ic0[255:176]};
5'h17:  o <= {ic1[47:0],ic0[255:184]};
5'h18:  o <= {ic1[55:0],ic0[255:192]};
5'h19:  o <= {ic1[63:0],ic0[255:200]};
5'h1A:  o <= {ic1[71:0],ic0[255:208]};
5'h1B:  o <= {ic1[79:0],ic0[255:216]};
5'h1C:  o <= {ic1[87:0],ic0[255:224]};
5'h1D:  o <= {ic1[95:0],ic0[255:232]};
5'h1E:  o <= {ic1[103:0],ic0[255:240]};
5'h1F:  o <= {ic1[111:0],ic0[255:248]};
endcase

assign hit = (hit0 & hit1) || (hit0 && radr[4:0] < 5'h05);

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache_mem(wclk, wr, wadr, sel, i, rclk, radr, o0, o1);
input wclk;
input wr;
input [13:0] wadr;
input [15:0] sel;
input [127:0] i;
input rclk;
input [13:0] radr;
output [255:0] o0;
output [255:0] o1;

reg [255:0] mem [0:511];
reg [13:0] rradr,rradrp32;

always @(posedge rclk)
    rradr <= radr;        
always @(posedge rclk)
    rradrp32 <= radr + 14'd32;

genvar n;
generate
begin
for (n = 0; n < 16; n = n + 1)
begin : dmem
reg [7:0] mem [31:0][0:511];
always @(posedge wclk)
begin
    if (wr & sel[n] & ~wadr[4]) mem[n][wadr[13:5]] <= i[n*8+7:n*8];
    if (wr & sel[n] & wadr[4]) mem[n+16][wadr[13:5]] <= i[n*8+7:n*8];
end
end
end
endgenerate

generate
begin
for (n = 0; n < 32; n = n + 1)
begin : dmemr
assign o0[n*8+7:n*8] = mem[n][rradr[13:5]];
assign o1[n*8+7:n*8] = mem[n][rradrp32[13:5]];
end
end
endgenerate

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache_tag(wclk, wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input [31:0] wadr;
input rclk;
input [31:0] radr;
output reg hit0;
output reg hit1;

wire [31:0] tago0, tago1;
wire [31:0] radrp32 = radr + 32'd32;

DSD9_dcache_tag1 u1 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radr[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago0)  // output wire [31 : 0] doutb
);

DSD9_dcache_tag1 u2 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radrp32[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago1)  // output wire [31 : 0] doutb
);

always @(posedge rclk)
    hit0 <= tago0[31:14]==radr[31:14];
always @(posedge rclk)
    hit1 <= tago1[31:14]==radrp32[31:14];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache(wclk, wr, sel, wadr, i, rclk, radr, o, hit, hit0, hit1);
input wclk;
input wr;
input [15:0] sel;
input [31:0] wadr;
input [127:0] i;
input rclk;
input [31:0] radr;
output reg [79:0] o;
output hit;
output hit0;
output hit1;

wire [255:0] dc0, dc1;
wire [13:0] radrp32 = radr + 32'd32;

DSD9_dcache_mem1 u1 (
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:4]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radr[13:5]),  // input wire [8 : 0] addrb
  .doutb(dc0)  // output wire [255 : 0] doutb
);

DSD9_dcache_mem1 u2 (
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:4]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radrp32[13:5]),  // input wire [8 : 0] addrb
  .doutb(dc1)  // output wire [255 : 0] doutb
);

DSD9_dcache_tag u3
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0),
    .hit1(hit1)
);

// hit0, hit1 are also delayed by a clock already
always @(posedge rclk)
    o <= {dc1,dc0} >> {radr[3:0],3'b0};

assign hit = (hit0 & hit1) || (hit0 && radr[4:0] < 5'h0E);

endmodule

