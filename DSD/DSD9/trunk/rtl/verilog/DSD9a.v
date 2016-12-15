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

module DSD9(rst_i, clk_i, irq_i, icause_i, cyc_o, stb_o, lock_o, ack_i, err_i, wr_o, sel_o, adr_o, dat_i, dat_o, cr_o, sr_o, rb_i);
parameter WID = 80;
parameter PCMSB = 31;
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
parameter RUN = 6'd3;
parameter LOAD_ICACHE1 = 6'd4;
parameter LOAD_ICACHE2 = 6'd5;
parameter LOAD_ICACHE3 = 6'd6;
parameter LOAD_DCACHE1 = 6'd7;
parameter LOAD_DCACHE2 = 6'd8;
parameter LOAD_DCACHE3 = 6'd9;
parameter LOAD1 = 6'd10;
parameter LOAD2 = 6'd11;
parameter LOAD3 = 6'd12;
parameter LOAD4 = 6'd13;
parameter STORE1 = 6'd14;
parameter STORE2 = 6'd15;
parameter STORE3 = 6'd16;
parameter STORE4 = 6'd17;
parameter INVnRUN = 6'd18; 
parameter LOAD1a = 6'd20;
parameter LOAD1b = 6'd21;
parameter STORE1a = 6'd22;
parameter STORE1b = 6'd23;
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

reg [5:0] state;
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
wire [15:0] mmu_dat;
wire iack = ack_i|mmu_ack;
wire [127:0] idat = dat_i|{8{mmu_dat}};
wire [15:0] mmu_dati = dat_o >> {ea[3:1],4'h0};
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

// CSR registers
reg [31:0] pcr;
reg [31:0] mbadaddr;
reg [31:0] msema;
reg [31:0] sbl,sbu;
reg [31:0] mtvec;
reg [31:0] mexrout;
reg [79:0] mstatus;
reg [31:0] mcause;
reg [511:0] mtdeleg;
// Hypervisor regs
reg him;
reg [31:0] hcause;
reg [31:0] hbadaddr;
reg [31:0] htvec;
// Supervisor regs
reg sim;
reg [31:0] scause;
reg [31:0] sbadaddr;
reg [31:0] stvec;

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

wire [31:0] siea = a + b * Scale(Sc) + imm;

reg xIsPredictableBranch;
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
reg xMul,xMulu,xMulsu,xMuli,xMului,xMulsui;

wire dDiv = dopcode==`DIVI || dopcode==`DIVUI || dopcode==`DIVSUI || dopcode==`REMI || dopcode==`REMUI || dopcode==`REMSUI ||
             (dopcode==`R2 && (dfunct==`DIV || dfunct==`DIVU || dfunct==`DIVSU || dfunct==`REM || dfunct==`REMU || dfunct==`REMSU))
             ;
wire dDivi = dopcode==`DIVI || dopcode==`DIVUI || dopcode==`DIVSUI || dopcode==`REMI || dopcode==`REMUI || dopcode==`REMSUI;
wire dDivss = dopcode==`DIVI || (dopcode==`R2 && (dfunct==`DIV || dfunct==`REM));
wire dDivsu = dopcode==`DIVSUI || (dopcode==`R2 && (dfunct==`DIVSU || dfunct==`REMSU));
reg xDiv,xDivi,xDivss,xDivsu;


reg xIsLoad,xIsStore;
wire dIsLoad = dopcode==`LDB || dopcode==`LDBU || dopcode==`LDW || dopcode==`LDWU || dopcode==`LDT || dopcode==`LDTU ||
               dopcode==`LDP || dopcode==`LDPU || dopcode==`LDD ||
               dopcode==`LDVDAR ||
               dopcode==`LDBX || dopcode==`LDBUX || dopcode==`LDWX || dopcode==`LDWUX || dopcode==`LDTX || dopcode==`LDTUX ||
               dopcode==`LDPX || dopcode==`LDPUX || dopcode==`LDDX ||
               dopcode==`LDVDARX;
                              
wire dIsStore = dopcode==`STB || dopcode==`STW || dopcode==`STP || dopcode==`STD || dopcode==`STDCR || dopcode==`STT ||
                dopcode==`STBX || dopcode==`STWX || dopcode==`STPX || dopcode==`STDX || dopcode==`STDCRX || dopcode==`STTX;

wire xIsMultiCycle = xIsLoad || xIsStore || xopcode==`POP || xopcode==`PUSH || xopcode==`CALL || xopcode==`RET || xopcode==`FLOAT;

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
    .op(xir[39:35]),
    .a(a),
    .b(b),
    .imm(imm),
    .m(xir[35:20]),
    .o(bf_out),
    .masko()
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
    `BITFIELD:  res = bf_out;
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDP,`LDPU,`LDD,`LDVDAR,
    `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDPX,`LDPUX,`LDDX,`LDVDARX:
            res = lres;
    `JMP:   res = xpc + 32'd5;
    `CALL:  res = a - 32'd12;
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

function [3:0] pc_inc;
input [119:0] iinsn;
casex(iinsn[7:0])
`NOP,`CLI,`SEI,`WAI,`RTI,`MEMSB,`MEMDB,`SYNC,
`MFLT0,`MFLTF:
    pc_inc = 4'd1;
`MOV,`ADDI10,`PUSH,`POP,`RET,`BRK:
    pc_inc = 4'd3;
default:
    if (iinsn[47:44]==4'hC && iinsn[87:84]==4'hC)
        pc_inc = 4'd15;
    else if (iinsn[47:44]==4'hC)
        pc_inc = 4'd10;
    else
        pc_inc = 4'd5;
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
    .clk(clk),
    .xIsBranch(xIsPredictableBranch),
    .advanceX(advanceEX),
    .pc(pc),
    .xpc(xpc),
    .takb(takb),
    .predict_taken(ipredict_taken)
);

wire [31:0] ibr_disp = {{15{iinsn[39]}},iinsn[39:22]};

reg IsLastICacheWr;
wire ihit,ihit0,ihit1;
DSD9_icache u1
(
    .wclk(clk_i),
    .wr(IsICacheLoad & (ack_i|err_i)),
    .last_wr(IsLastICacheWr),
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
    .rclk(~clk_i),
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

function Need2Cycles;
input [2:0] mem_size;
input [31:0] adr;
case(mem_size)
byt:    Need2Cycles = FALSE;
wyde:   Need2Cycles = adr[3:0]==4'hF;
tetra:  Need2Cycles = adr[3:0] >4'hC;
deci:   Need2Cycles = adr[3:0] >4'h6;
default:    Need2Cycles = FALSE;
endcase
endfunction

assign advanceEX = 1'b1;
assign advanceDC = advanceEX && !(xIsMultiCycle && !xinv);
assign advanceIF = advanceDC && ihit;

// A stuffed fault will have occurred earlier than a pending IRQ
// hence takes precedence.
always@*
    if (stuff_fault)
        iinsn = {5{fault_insn}};
    else if (irq_i & ~im & gie)
        iinsn = {5{7'd0,icause_i,`BRK}};
    else
        iinsn = insn;

always @(posedge clk_i)
if (rst_i) begin
    ol <= 2'b00;
    cpl <= 8'h00;
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    sel_o <= 16'hFFFF;
    adr_o <= 32'h00000000;
    pc <= 32'h0000000F;
    IsICacheLoad <= `TRUE;
    next_state(RESTART1);
end
else begin

upd_rf <= FALSE;
update_regfile();

case(state)

// -----------------------------------------------------------------------------
// Restart:
// Load the first 16kB of the I-Cache to set all the tags to a valid state. 
// -----------------------------------------------------------------------------
RESTART1:
    if (ack_i|err_i) begin
        next_state(RESTART2);
        if (adr_o[13:4]==10'h3FF) begin
            IsICacheLoad <= `FALSE;
            wb_nack();
            next_state(RUN);
        end
        stb_o <= `LOW;
        adr_o[13:4] <= adr_o[13:4] + 10'h01;
    end
RESTART2:
    begin
        stb_o <= `HIGH;
        next_state(RESTART1);
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
        else begin
            Ra <= iinsn[13:8];
            Rb <= iinsn[19:14];
            Rc <= iinsn[27:22];
        end
        i80 <= `FALSE;
        i54 <= `FALSE;
        if (iinsn[48:45]==4'hC && iinsn[89:86]==4'hC)
            i80 <= `TRUE;
        else if (iinsn[48:45]==4'hC)
            i54 <= iinsn[48:45]==4'hC;
        dinv <= `FALSE;
        pc <= pc + pc_inc(iinsn);
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
    end
    else begin
        if (!ihit) begin
            pc <= pc;
            dinv <= `TRUE;
            icmf <= {~ihit1,~ihit0};
            iccnt <= 3'd0;
            next_state(LOAD_ICACHE1);
        end
        if (advanceDC) begin
            inv_ir();
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

        xMul <= dMul;
        xMulu <= dMulu;
        xMulsu <= dMulsu;
        xMuli <= dMuli;
        xMului <= dMului;
        xMulsui <= dMulsui;
        
        xDiv <= dDiv;
        xDivi <= dDivi;
        xDivss <= dDivss;
        xDivsu <= dDivsu;

        xIsLoad <= dIsLoad;
        xIsStore <= dIsStore;

        xIsPredictableBranch <= dIsPredictableBranch;
        xpredict_taken <= dpredict_taken;
        a <= fwd_mux(Ra);
        b <= fwd_mux(Rb);
        c <= fwd_mux(Rc);
        case(dopcode)
        `CSR,
        `BEQI,`BNEI,`BLTI,`BLEI,`BGTI,`BGEI,`BLTUI,`BLEUI,`BGTUI,`BGEUI:
            if (i80)//        32          4         32          4          8
                imm <= {dir[119:88],dir[83:80],dir[79:48],dir[43:40],dir[21:14]};
            else if (i54) //              32          4          8
                imm <= {{36{dir[79]}},dir[79:48],dir[43:40],dir[21:14]};
            else
                imm <= {{72{dir[21]}},dir[21:14]};
        `ADDI10: imm <= {{70{dir[23]}},dir[23:14]};
        `RET:    imm <= dir[23:8];
        default:
            if (i80)    //    22          4         32          4         18
                imm <= {dir[109:88],dir[83:80],dir[79:48],dir[43:40],dir[39:22]};
            else if (i54)
                imm <= {{26{dir[79]}},dir[79:48],dir[43:40],dir[39:22]};
            else
                imm <= {{62{dir[39]}},dir[39:22]};
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
    if (advanceEX && !xinv) begin
        case(xopcode)
        `MFLT0,`MFLTF:
            ex_fault(`FLT_MEM,0);
        `BRK:
            begin
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
        `IRET:
            begin
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
        `REX:   ex_rex();
           
        `JMP:
            if (xRa==6'd63)
                ex_branch(xpc + imm);
            else
                ex_branch(a + imm);
        `CALL:  begin mem_size = deci; ea <= a - 32'd10; xb <= xpc + 32'd5; next_state(STORE1); end
        `FBEQ,`FBNE,`FBLT,`FBGE,`FBLE,`FBGT,`FBOR,`FBUN,
        `BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU,
        `BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI,
        `BBC,`BBS:
            if (xpredict_taken & ~takb)
                ex_branch(xpc + br_disp);
            else if (~xpredict_taken & takb)
                ex_branch(xpc + 32'd2);

        `MUL,`MULU,`MULSU,`MULH,`MULUH,`MULSUH:
                next_state(MUL1);
        `DIV,`DIVU,`DIVSU,`REM,`REMU,`REMSU:
                next_state(DIV1);
        `FLOAT: next_state(FLOAT1);

        `CSR:   case(xir[37:36])
                2'd0:   write_csr(xir[39:38],xir[35:22],imm);
                2'd1:   write_csr(xir[39:38],a[13:0],imm);
                2'd2:   if (xRb != 6'd0) write_csr(xir[39:38],a[13:0],b);
                2'd3:   if (xRa != 6'd0) write_csr(xir[39:38],xir[35:22],a);
                endcase

        `LDB,`LDBU: begin mem_size = byt; ea <= a + imm; next_state(LOAD1); end
        `LDW,`LDWU: begin mem_size = wyde; ea <= a + imm; next_state(LOAD1); end
        `LDT,`LDTU: begin mem_size = tetra; ea <= a + imm; next_state(LOAD1); end
        `LDP,`LDPU: begin mem_size = penta; ea <= a + imm; next_state(LOAD1); end
        `LDD: begin mem_size = deci; ea <= a + imm; next_state(LOAD1); end
        `LDBX,`LDBUX: begin mem_size = byt; ea <= siea; next_state(LOAD1); end
        `LDWX,`LDWUX: begin mem_size = wyde; ea <= siea; next_state(LOAD1); end
        `LDTX,`LDTUX: begin mem_size = tetra; ea <= siea; next_state(LOAD1); end
        `LDPX,`LDPUX: begin mem_size = penta; ea <= siea; next_state(LOAD1); end
        `LDDX: begin mem_size = deci; ea <= siea; next_state(LOAD1); end
        `STB: begin mem_size = byt; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STW: begin mem_size = wyde; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STT: begin mem_size = tetra; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STP: begin mem_size = penta; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STD: begin mem_size = deci; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STBX: begin mem_size = byt; ea <= siea; xb <= c; next_state(LOAD1); end
        `STWX: begin mem_size = wyde; ea <= siea; xb <= c; next_state(LOAD1); end
        `STTX: begin mem_size = tetra; ea <= siea; xb <= c; next_state(LOAD1); end
        `STPX: begin mem_size = penta; ea <= siea; xb <= c; next_state(LOAD1); end
        `STDX: begin mem_size = deci; ea <= siea; xb <= c; next_state(LOAD1); end
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
        `MULI,`MULUI,`MULSUI,`MULHI,`MULUHI,`MULSUHI:
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
        `DIVI,`DIVUI,`DIVSUI,`REMI,`REMUI,`REMSUI:
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
        if ((xRa==6'd63 || xRa==6'd62)&&(ea < sbl || ea > sbu))
            ex_fault(`FLT_STACK,0);
        else begin
            next_state(LOAD1a);
        end
    end
LOAD1a:
    begin
        next_state(LOAD1b);
    end
LOAD1b:
    begin
        if (dhit)
            load1(1'b1);
        else if (~ea[31]) begin
            dcmf <= {~dhit1,~dhit0};
            next_state(LOAD_DCACHE1);
        end
        else begin
            read1(mem_size,pea);
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
        mbadaddr <= ea;
    end
    else if (ack_i) begin
        load1(1'b0);
    end // LOAD2
LOAD3:
    begin
        read2(mem_size,ea);
        next_state(LOAD4);
    end
LOAD4:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= ea;
    end
    else if (ack_i) begin
        wb_nack();
        next_state(INVnRUN);
        upd_rf <= `TRUE;
        case(xopcode)
        `LDW,`LDWX:
            begin
                lres[79:8] <= {{72{dat_i[7]}},dat_i[7:0]};
            end
        `LDWU,`LDWUX:
            begin
                lres[79:8] <= {{72{1'b0}},dat_i[7:0]};
            end
        `LDP,`LDPX:
            begin
                case(ea[3:0])
                4'hC:   lres[79:32] <= {{40{dat_i[7]}},dat_i[7:0]};
                4'hD:   lres[79:24] <= {{40{dat_i[15]}},dat_i[15:0]};
                4'hE:   lres[79:16] <= {{40{dat_i[23]}},dat_i[23:0]};
                4'hF:   lres[79:8] <= {{40{dat_i[31]}},dat_i[31:0]};
                endcase
            end
        `LDPU,`LDPUX:
            begin
                case(ea[3:0])
                4'hC:   lres[79:32] <= {{40{1'b0}},dat_i[7:0]};
                4'hD:   lres[79:24] <= {{40{1'b0}},dat_i[15:0]};
                4'hE:   lres[79:16] <= {{40{1'b0}},dat_i[23:0]};
                4'hF:   lres[79:8] <= {{40{1'b0}},dat_i[31:0]};
                endcase
            end
        `LDD,`LDDX,`POP,`RET:
            begin
                case(ea[3:0])
                4'h7:   lres[79:72] <= dat_i[7:0];
                4'h8:   lres[79:64] <= dat_i[15:0];
                4'h9:   lres[79:56] <= dat_i[23:0];
                4'hA:   lres[79:48] <= dat_i[31:0];
                4'hB:   lres[79:40] <= dat_i[39:0];
                4'hC:   lres[79:32] <= dat_i[47:0];
                4'hD:   lres[79:24] <= dat_i[55:0];
                4'hE:   lres[79:16] <= dat_i[63:0];
                4'hF:   lres[79:8] <= dat_i[71:0];
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
            xRt <= xir[19:14];
            end
        `RET:
            xRt <= 6'd63;   
        endcase
    end // LOAD4

STORE1:
    begin
        if ((xRa==6'd63 || xRa==6'd62)&&(ea < sbl || ea > sbu))
            ex_fault(`FLT_STACK,0);
        else begin
            $display("Store to %h <= %h", ea, xb);
            next_state(STORE1a);
        end
    end
STORE1a:
    next_state(STORE1b);
STORE1b:
    begin
        write1(mem_size,pea,xb);
        next_state(STORE2);
    end
STORE2:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= ea;
    end
    else if (ack_i) begin
        stb_o <= `LOW;
        if (Need2Cycles(mem_size,ea)) begin
            next_state(STORE3);
        end
        else begin
            wb_nack();
            lock_o <= `LOW;
            next_state(INVnRUN);
            case(xopcode)
            `CALL,`PEA,`PUSH:
                begin
                    xRt <= 6'd60|ol;    
                    upd_rf <= `TRUE;
                end
            endcase
        end
        cr_o <= `LOW;
        msema[0] <= rb_i;
    end // STORE2
STORE3:
    begin
        write2(mem_size,ea);
        next_state(STORE4);
    end
STORE4:
    if (err_i) begin
        wb_nack();
        lock_o <= `LOW;
        ex_fault(`FLT_DBE,0);
        mbadaddr <= ea;
    end
    else if (ack_i) begin
        wb_nack();
        lock_o <= `LOW;
        case(xopcode)
        `CALL,`PEA,`PUSH:
            begin
                xRt <= 6'd60|ol;    
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
                if (xRb==6'd60)
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
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                sel_o <= 8'hFF;
                icmf[0] <= 1'b0;
                adr_o <= {pc[31:5],5'h0};
            end
            else if (icmf[1]) begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                sel_o <= 8'hFF;
                adr_o <= {pc[31:5]+27'd1,5'h0};
                icmf[1] <= 1'b0;
            end
            next_state(LOAD_ICACHE2);
        end
        else
            next_state(RUN);
    end
LOAD_ICACHE2:
    if (ack_i|err_i) begin
        stb_o <= `LOW;
        next_state(LOAD_ICACHE3);
        iccnt <= iccnt + 3'd1;
        if (iccnt==3'd3)
            IsLastICacheWr <= `TRUE;
        if (iccnt==3'd4) begin
            iccnt <= 3'd0;
            IsLastICacheWr <= `FALSE;
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
LOAD_ICACHE3:
    begin
        stb_o <= `HIGH;
        adr_o <= adr_o + 32'd16;
        next_state(LOAD_ICACHE2);
    end

// -----------------------------------------------------------------------------
// Load data cache lines.
// -----------------------------------------------------------------------------

LOAD_DCACHE1:
    begin
        if (dcmf != 2'b00) begin
            IsDCacheLoad <= `TRUE;
            if (dcmf[0]) begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                sel_o <= 16'hFFFF;
                dcmf[0] <= 1'b0;
                adr_o <= {ea[31:5],5'h0};
                dccnt <= 2'd0;
            end
            else if (dcmf[1]) begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                sel_o <= 16'hFFFF;
                adr_o <= {ea[31:5]+27'd1,5'h0};
                dccnt <= 2'd0;
                dcmf[1] <= 1'b0;
            end
            next_state(LOAD_DCACHE2);
        end
        else
            next_state(LOAD1b);
    end
LOAD_DCACHE2:
    if (ack_i|err_i) begin
        dccnt <= dccnt + 2'd1;
        adr_o <= adr_o + 32'd16;
        next_state(LOAD_DCACHE3);
        if (dccnt==2'b01) begin
            if (dcmf==2'b00) begin
                IsDCacheLoad <= `FALSE;
                wb_nack();
                next_state(LOAD1b);
            end
            else begin 
                stb_o <= `LOW;
                next_state(LOAD_DCACHE1);
            end
        end
    end
LOAD_DCACHE3:
    begin
        stb_o <= `HIGH;
        next_state(LOAD_DCACHE2);
    end

default:
    next_state(RUN);

endcase // state
end

always @(dhit or dc_dat or dat_i or ea)
    if (dhit)
        lres1 = dc_dat;
    else
        lres1 = (dat_i >> {ea[3:0],3'h0}) | (dat_i << {~ea[3:0]+4'd1,3'h0});

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
            else if (ea[3:0]!=4'hF) begin
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
            else if (ea[3:0]!=4'hF) begin
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
            else if (ea[3:0]!=4'hF) begin
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
            else if (ea[3:0]!=4'hF) begin
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
            else if (ea[3:0] < 4'hD) begin
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
            else if (ea[3:0] < 4'hD) begin
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
            else if (ea[3:0] < 4'hD) begin
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
            else if (ea[3:0] < 4'hD) begin
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
            else if (ea[3:0] < 4'hC) begin
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
            else if (ea[3:0] < 4'hC) begin
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
            else if (ea[3:0] < 4'hC) begin
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
            else if (ea[3:0] < 4'hC) begin
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
    `LDD:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (ea[3:0] < 4'h7) begin
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
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (ea[3:0] < 4'h7) begin
                wb_nack();
                lres <= lres1[79:0];
                xRt2 <= `TRUE;
                xRt <= xir[19:14];
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
            else if (ea[3:0] < 4'h7) begin
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
            else if (ea[3:0] < 4'h7) begin
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
begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
	adr_o <= adr;
	case(sz)
	byt:   sel_o <= 16'h0001 << adr[3:0];
	wyde:  sel_o <= 16'h0003 << adr[3:0];
	tetra: sel_o <= 16'h000F << adr[3:0];
	penta: sel_o <= 16'h001F << adr[3:0];
	deci:  sel_o <= 16'h03FF << adr[3:0];
    endcase
    case(sz)
    wyde:   if (adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (adr[3:0] >4'hC) lock_o <= `HIGH;
    penta:  if (adr[3:0] >4'hB) lock_o <= `HIGH;
    deci:   if (adr[3:0] >4'h6) lock_o <= `HIGH;
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
begin
    stb_o <= `HIGH;
	adr_o[31:4] <= adr[31:4] + 28'd1;
	case(sz)
	wyde:  sel_o <= 16'h0001;
	tetra: sel_o <= 16'h000F >> (~adr[3:0] + 4'd1);
	penta: sel_o <= 16'h001F >> (~adr[3:0] + 4'd1);
	deci:  sel_o <= 16'h03FF >> (~adr[3:0] + 4'd1);
    endcase
end
endtask

wire [127:0] bdat = {16{xb[7:0]}};
wire [127:0] wdat = {8{xb[15:0]}};
wire [127:0] tdat = {4{xb[31:0]}};

task write1;
input [2:0] sz;
input [31:0] adr;
input [79:0] dat;
begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    wr_o <= `HIGH;
	adr_o <= adr;
	case(sz)
	byt:   sel_o <= 16'h0001 << adr[3:0];
	wyde:  sel_o <= 16'h0003 << adr[3:0];
	tetra: sel_o <= 16'h000F << adr[3:0];
	penta: sel_o <= 16'h001F << adr[3:0];
	deci:  sel_o <= 16'h03FF << adr[3:0];
    endcase
    case(sz)
    byt:        dat_o <= (bdat << {adr[3:0],3'b0}) | (bdat >> {~adr[3:0] + 4'd1,3'b0});
    wyde:       dat_o <= (wdat << {adr[3:0],3'b0}) | (wdat >> {~adr[3:0] + 4'd1,3'b0});
    tetra:      dat_o <= (tdat << {adr[3:0],3'b0}) | (tdat >> {~adr[3:0] + 4'd1,3'b0});
    penta:      dat_o <= ({88'h0,dat[39:0]} << {adr[3:0],3'b0}) | ({88'h0,dat[39:0]} >> {~adr[3:0] + 4'd1,3'b0});
    deci:       dat_o <= ({48'h0,dat} << {adr[3:0],3'b0}) | ({48'h0,dat} >> {~adr[3:0] + 4'd1,3'b0});
    endcase
    case(sz)
    wyde:   if (adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (adr[3:0] >4'hC) lock_o <= `HIGH;
    penta:  if (adr[3:0] >4'hB) lock_o <= `HIGH;
    deci:   if (adr[3:0] >4'h6) lock_o <= `HIGH;
    endcase
    if (xopcode==`STDCR)
        cr_o <= 1'b1;
end
endtask

task write2;
input [2:0] sz;
input [31:0] adr;
begin
    stb_o <= `TRUE;
	adr_o[31:4] <= adr[31:4] + 28'd1;
	case(sz)
	wyde:  sel_o <= 16'h0003 >> (~adr[3:0] + 4'd1);
	tetra: sel_o <= 16'h000F >> (~adr[3:0] + 4'd1);
	penta: sel_o <= 16'h001F >> (~adr[3:0] + 4'd1);
	deci:  sel_o <= 16'h03FF >> (~adr[3:0] + 4'd1);
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
    inv_ir();
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
    `TVEC:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= stvec;
        `OL_HYPERVISOR: res <= htvec;
        `OL_MACHINE:    res <= mtvec;
        endcase
    `CAUSE:
        case(csrno[13:12])
        `OL_USER:   res <= 80'd0;
        `OL_SUPERVISOR: res <= scause;
        `OL_HYPERVISOR: res <= hcause;
        `OL_MACHINE:    res <= mcause;
        endcase
    `BADADDR:
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
    `SP:      res <= sp[csrno[13:12]];
    `CSR_SBL:     res <= sb_lower[csrno[13:12]];
    `CSR_SBU:     res <= sb_upper[csrno[13:12]];
    `CSR_CISC:      res <= cisc;
    `CSR_STATUS:
        case(ol)
        `OL_USER:   res <= 64'd0;
        `OL_MACHINE:    res <= mstatus;
        `OL_HYPERVISOR: res <= hstatus;
        `OL_SUPERVISOR: res <= sstatus;
        endcase
    `CSR_INSRET:    res <= rdinstret;
    `CSR_TIME:      res <= mtime;

    `CSR_EPC:       res <= epc[0];
    `CSR_CONFIG:    res <= mconfig;
    endcase
    else
        fault(`FLT_PRIV,0);
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
        `CSR_FPHOLD0:   begin
                        fphold[31:0] <= dat;
                        fphold[127:32] <= {96{dat[31]}};
                        end
        `CSR_FPHOLD1:   begin
                        fphold[63:32] <= dat;
                        fphold[127:64] <= {64{dat[31]}};
                        end
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

module DSD9_icache(wclk, wr, last_wr, wadr, i, rclk, radr, o, hit, hit0, hit1);
input wclk;
input wr;
input last_wr;
input [31:0] wadr;
input [63:0] i;
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
    .last_wr(last_wr),
    .wadr(wadr[31:0]),
    .i(i),
    .rclk(rclk),
    .radr(radr[31:0]),
    .o0(ic0),
    .o1(ic1)
);

DSD9_icache_tag u2
(
    .wclk(clk),
    .wr(wr),
    .last_wr(last_wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0),
    .hit1(hit1)
);

always @(radr)
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
output [127:0] o0;
output [127:0] o1;

reg [255:0] mem [0:511];
reg [13:0] rradr,rradrp32;

wire wr00 = wr && sel[0] && wadr[4]==1'b0;
wire wr01 = wr && sel[1] && wadr[4]==1'b0;
wire wr02 = wr && sel[2] && wadr[4]==1'b0;
wire wr03 = wr && sel[3] && wadr[4]==1'b0;
wire wr04 = wr && sel[4] && wadr[4]==1'b0;
wire wr05 = wr && sel[5] && wadr[4]==1'b0;
wire wr06 = wr && sel[6] && wadr[4]==1'b0;
wire wr07 = wr && sel[7] && wadr[4]==1'b0;
wire wr08 = wr && sel[8] && wadr[4]==1'b0;
wire wr09 = wr && sel[9] && wadr[4]==1'b0;
wire wr0A = wr && sel[10] && wadr[4]==1'b0;
wire wr0B = wr && sel[11] && wadr[4]==1'b0;
wire wr0C = wr && sel[12] && wadr[4]==1'b0;
wire wr0D = wr && sel[13] && wadr[4]==1'b0;
wire wr0E = wr && sel[14] && wadr[4]==1'b0;
wire wr0F = wr && sel[15] && wadr[4]==1'b0;
wire wr10 = wr && sel[0] && wadr[4]==1'b1;
wire wr11 = wr && sel[1] && wadr[4]==1'b1;
wire wr12 = wr && sel[2] && wadr[4]==1'b1;
wire wr13 = wr && sel[3] && wadr[4]==1'b1;
wire wr14 = wr && sel[4] && wadr[4]==1'b1;
wire wr15 = wr && sel[5] && wadr[4]==1'b1;
wire wr16 = wr && sel[6] && wadr[4]==1'b1;
wire wr17 = wr && sel[7] && wadr[4]==1'b1;
wire wr18 = wr && sel[8] && wadr[4]==1'b1;
wire wr19 = wr && sel[9] && wadr[4]==1'b1;
wire wr1A = wr && sel[10] && wadr[4]==1'b1;
wire wr1B = wr && sel[11] && wadr[4]==1'b1;
wire wr1C = wr && sel[12] && wadr[4]==1'b1;
wire wr1D = wr && sel[13] && wadr[4]==1'b1;
wire wr1E = wr && sel[14] && wadr[4]==1'b1;
wire wr1F = wr && sel[15] && wadr[4]==1'b1;

always @(posedge wclk)
begin
    if (wr00) mem[wadr[13:5]][7:0] <= i[7:0];
    if (wr01) mem[wadr[13:5]][15:8] <= i[15:8];
    if (wr02) mem[wadr[13:5]][23:16] <= i[23:16];
    if (wr03) mem[wadr[13:5]][31:24] <= i[31:24];
    if (wr04) mem[wadr[13:5]][39:32] <= i[39:32];
    if (wr05) mem[wadr[13:5]][47:40] <= i[47:40];
    if (wr06) mem[wadr[13:5]][55:48] <= i[55:48];
    if (wr07) mem[wadr[13:5]][63:56] <= i[63:56];
    if (wr08) mem[wadr[13:5]][71:64] <= i[71:64];
    if (wr09) mem[wadr[13:5]][79:72] <= i[79:72];
    if (wr0A) mem[wadr[13:5]][87:80] <= i[87:80];
    if (wr0B) mem[wadr[13:5]][95:88] <= i[95:88];
    if (wr0C) mem[wadr[13:5]][103:96] <= i[103:96];
    if (wr0D) mem[wadr[13:5]][111:104] <= i[111:104];
    if (wr0E) mem[wadr[13:5]][119:112] <= i[119:112];
    if (wr0F) mem[wadr[13:5]][127:120] <= i[127:120];
    if (wr10) mem[wadr[13:5]][135:128] <= i[7:0];
    if (wr11) mem[wadr[13:5]][143:136] <= i[15:8];
    if (wr12) mem[wadr[13:5]][151:144] <= i[23:16];
    if (wr13) mem[wadr[13:5]][159:152] <= i[31:24];
    if (wr14) mem[wadr[13:5]][167:160] <= i[39:32];
    if (wr15) mem[wadr[13:5]][175:168] <= i[47:40];
    if (wr16) mem[wadr[13:5]][183:176] <= i[55:48];
    if (wr17) mem[wadr[13:5]][191:184] <= i[63:56];
    if (wr18) mem[wadr[13:5]][199:192] <= i[71:64];
    if (wr19) mem[wadr[13:5]][207:200] <= i[79:72];
    if (wr1A) mem[wadr[13:5]][215:208] <= i[87:80];
    if (wr1B) mem[wadr[13:5]][223:216] <= i[95:88];
    if (wr1C) mem[wadr[13:5]][231:224] <= i[103:96];
    if (wr1D) mem[wadr[13:5]][239:232] <= i[111:104];
    if (wr1E) mem[wadr[13:5]][247:240] <= i[119:112];
    if (wr1F) mem[wadr[13:5]][255:248] <= i[127:120];
end

always @(posedge rclk)
    rradr <= radr;        
always @(posedge rclk)
    rradrp32 <= radr + 14'd32;
    
assign o0 = mem[rradr[13:5]];
assign o1 = mem[rradrp32[13:5]];        

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache_tag(wclk, wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input [31:0] wadr;
input rclk;
input [31:0] radr;
output hit0;
output hit1;

reg [31:0] rradr;
reg [31:0] rradrp32;
reg [31:0] tagmem [0:511];

always @(posedge wclk)
    if (wr) tagmem[wadr[13:6]] <= wadr;

always @(posedge rclk)
    rradr <= radr;
always @(posedge rclk)
    rradrp32 <= radr + 32'd32;

assign hit0 = tagmem[rradr[13:5]][31:14]==rradr[31:14];
assign hit1 = tagmem[rradrp32[13:5]][31:14]==rradrp32[31:14];

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
output reg [127:0] o;
output hit;
output hit0;
output hit1;

wire [127:0] dc0, dc1;

DS9_dcache_mem u1
(
    .wclk(wclk),
    .wr(wr),
    .sel(sel),
    .wadr(wadr[13:0]),
    .i(i),
    .rclk(rclk),
    .radr(radr[13:0]),
    .o0(ic0),
    .o1(ic1)
);

DS9_dcache_tag u2
(
    .wclk(clk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0),
    .hit1(hit1)
);

always @(radr)
case(radr[4:0])
5'h00:  o <= dc0[79:0];
5'h01:  o <= dc0[87:8];
5'h02:  o <= dc0[95:16];
5'h03:  o <= dc0[103:24];
5'h04:  o <= dc0[111:32];
5'h05:  o <= dc0[119:40];
5'h06:  o <= dc0[127:48];
5'h07:  o <= dc0[135:56];
5'h08:  o <= dc0[143:64];
5'h09:  o <= dc0[151:72];
5'h0A:  o <= dc0[159:80];
5'h0B:  o <= dc0[167:88];
5'h0C:  o <= dc0[175:96];
5'h0D:  o <= dc0[183:104];
5'h0E:  o <= dc0[191:112];
5'h0F:  o <= dc0[199:120];
5'h10:  o <= dc0[207:128];
5'h11:  o <= dc0[215:136];
5'h12:  o <= dc0[223:144];
5'h13:  o <= dc0[231:152];
5'h14:  o <= dc0[239:160];
5'h15:  o <= dc0[247:168];
5'h16:  o <= dc0[255:176];
5'h17:  o <= {dc1[7:0],dc0[255:184]};
5'h18:  o <= {dc1[15:0],dc0[255:192]};
5'h19:  o <= {dc1[23:0],dc0[255:200]};
5'h1A:  o <= {dc1[31:0],dc0[255:208]};
5'h1B:  o <= {dc1[39:0],dc0[255:216]};
5'h1C:  o <= {dc1[47:0],dc0[255:224]};
5'h1D:  o <= {dc1[55:0],dc0[255:232]};
5'h1E:  o <= {dc1[63:0],dc0[255:240]};
5'h1F:  o <= {dc1[71:0],dc0[255:248]};
endcase

assign hit = (hit0 & hit1) || (hit0 && radr[4:0] < 5'h0E);

endmodule

