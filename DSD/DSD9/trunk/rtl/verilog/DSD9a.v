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
parameter WID = 64;
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
parameter deci = 3'd3;

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

reg [5:0] state;
reg [1:0] ol;                       // operating level
reg [32:0] pc,dpc,xpc;
wire ipredict_taken;
reg dpredict_taken,xpredict_taken;
reg [32:0] br_disp;
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
reg [WID-1:0] r46;
reg [WID-1:0] sp;
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
reg [19:0] fault_insn;
reg im;
reg gie;        // global interrupt enable    
reg dinv,xinv;
reg i54,i80;
reg upd_rf;

// CSR registers
reg [31:0] pcr;
reg [31:0] mbadaddr;
reg [31:0] msema;
reg [31:0] sbl,sbu;

function [WID-1:0] fwd_mux;
input [5:0] Rn;
case(Rn)
6'h00:  fwd_mux = {WID{1'b0}};
xRt: fwd_mux = res;
6'h01:  fwd_mux = r1;
6'h02:  fwd_mux = r2;
6'd46:  fwd_mux = r46;
6'h3F:  fwd_mux = sp;
default:    fwd_mux = regfile[Rn];
endcase
endfunction

reg xIsPredictableBranch;
wire dIsPredictableBranch =
    (dir[21]==1'b0 && (dopcode==`BEQ || dopcode==`BNE ||
    dopcode==`BLT || dopcode==`BGE || dopcode==`BLE || dopcode==`BGT ||
    dopcode==`BLTU || dopcode==`BGEU || dopcode==`BLEU || dopcode==`BGTU)) ||
    dopcode==`BEQI || dopcode==`BNEI ||
    dopcode==`BLTI || dopcode==`BGEI || dopcode==`BLEI || dopcode==`BGTI ||
    dopcode==`BLTUI || dopcode==`BGEUI || dopcode==`BLEUI || dopcode==`BGTUI ||
    dopcode==`BBC || dopcode==`BBS;

wire xIsLoad = xopcode==`LDB || xopcode==`LDBU || xopcode==`LDW || xopcode==`LDWU ||
               xopcode==`LDT || xopcode==`LDTU || xopcode==`LDD ||
               xopcode==`LDBX || xopcode==`LDBUX || xopcode==`LDWX || xopcode==`LDWUX ||
               xopcode==`LDTX || xopcode==`LDTUX || xopcode==`LDDX;
                              
wire xIsStore = xopcode==`STB || xopcode==`STW || xopcode==`STT || xopcode==`STD ||
                xopcode==`STBX || xopcode==`STWX || xopcode==`STTX;

wire xIsMultiCycle = xIsLoad || xIsStore || xopcode==`POP || xopcode==`PUSH || xopcode==`CALL || xopcode==`RET;

always @*
    case(xopcode)
    `R2:
        case(xfunct)
        `ADD,`ADDU: res = a + b;
        `SUB,`SUBU: res = a - b;
        `CMP:   res = $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
        `CMPU:  res = a < b ? -1 : a==b ? 0 : 1;
        `AND:   res = a & b;
        `OR:    res = a | b;
        `XOR:   res = a ^ b;
        endcase
    `MOV:   res = a;
    `ADD,`ADDU:   res = a + imm;
    `SUB,`SUBU:   res = a - imm;
    `CMP:   res = $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
    `CMPU:  res = a < imm ? -1 : a==imm ? 0 : 1;
    `AND:   res = a & imm;
    `OR:    res = a | imm;
    `XOR:   res = a ^ imm;
    `LDB,`LDBU,`LDW,`LDWU,`LDT,`LDTU,`LDD,
    `LDBX,`LDBUX,`LDWX,`LDWUX,`LDTX,`LDTUX,`LDDX:
            res = lres;
    `JMP:   res = xpc + 33'd10;
    `CALL:  res = a - 32'd10;
    default:    res = {WID{1'b0}};
    endcase

always @*
    case(xopcode)
    `POP:   res2 = a + (|xir[19:14] & |xir[13:8]) ? 32'd24 : (|xir[19:14] | |xir[13:8]) ?  32'd12 : 32'd0;
    `FPOP:
        case(xir[19:17])
        3'd0:   res2 = a + 32'd4;
        3'd1:   res2 = a + 32'd8;
        3'd2:   res2 = a + 32'd12;
        3'd3:   res2 = a + 32'd16;
        default:    res2 = a + 32'd12;
        endcase
    default:    res2 = a + 32'd12;
    endcase

function [3:0] pc_inc;
input [119:0] iinsn;
if (iinsn[7:4]==4'hE)
    pc_inc = 4'd1;
else if (iinsn[47:44]==4'hC && iinsn[87:84]==4'hC)
    pc_inc = 4'd6;
else if (iinsn[47:44]==4'hC)
    pc_inc = 4'd4;
else
    pc_inc = 4'd2;
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

wire [31:0] pcr80;
DSD9_round80 u3 (pc, pcr80);

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
        iinsn = {6{fault_insn}};
    else if (irq_i & ~im & gie)
        iinsn = {6{3'd0,icause_i,`BRK}};
    else
        iinsn = insn;

always @(posedge clk_i)
if (rst_i) begin
    cyc_o <= `HIGH;
    stb_o <= `HIGH;
    sel_o <= 16'hFFFF;
    adr_o <= 32'h00000000;
    iccnt <= 3'd0;
    pc <= 32'h00000010;
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
        iccnt <= iccnt + 3'd1;
        if (iccnt==3'd3)
            IsLastICacheWr <= `TRUE;
        else if (iccnt==3'd4) begin
            IsLastICacheWr <= `FALSE;
            iccnt <= 3'd0;
            if (adr_o[14:4]>=10'h3FF) begin
                IsICacheLoad <= `FALSE;
                wb_nack();
                next_state(RUN);
            end
        end
        stb_o <= `LOW;
        adr_o[14:4] <= adr_o[14:4] + 10'h01;
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
            Ra <= 6'd60|ol;
            Rb <= 6'd1;
            Rc <= 6'd2;
        end
        else if (iopcode==`PEA || iopcode==`CALL || iopcode==`POP || iopcode==`PUSH || iopcode==`RET ||
            iopcode==`FPUSH || iopcode==`FPOP) begin
            Ra <= 6'd60|ol;
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
            if (iinsn[21]) dpredict_taken <= iinsn[20];
            else dpredict_taken <= ipredict_taken;
        default: dpredict_taken <= ipredict_taken;
        endcase
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
        default:
            if (i80)    //    22          4         32          4         18
                imm <= {dir[109:88],dir[83:80],dir[79:48],dir[43:40],dir[39:22]};
            else if (i54)
                imm <= {{26{dir[79]}},dir[79:48],dir[43:40],dir[39:22]};
            else
                imm <= {{62{dir[39]}},dir[39:22]};
        endcase
        br_disp <= {{15{dir[39]}},dir[39:22]};
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
        `JMP:
            if (xRa==6'd60)
                ex_branch(xpc + imm);
            else
                ex_branch(a + imm);
        `CALL:  begin mem_size = deci; ea <= a - 32'd10; xb <= xpc + 32'd2; next_state(STORE1); end
        `BEQ,`BNE,`BLT,`BGE,`BLE,`BGT,`BLTU,`BGEU,`BLEU,`BGTU,
        `BEQI,`BNEI,`BLTI,`BGEI,`BLEI,`BGTI,`BLTUI,`BGEUI,`BLEUI,`BGTUI,
        `BBC,`BBS:
            if (xpredict_taken & ~takb)
                ex_branch(xpc + br_disp);
            else if (~xpredict_taken & takb)
                ex_branch(xpc + 32'd2);

        `LDB,`LDBU: begin mem_size = byt; ea <= a + imm; next_state(LOAD1); end
        `LDW,`LDWU: begin mem_size = wyde; ea <= a + imm; next_state(LOAD1); end
        `LDT,`LDTU: begin mem_size = tetra; ea <= a + imm; next_state(LOAD1); end
        `LDD: begin mem_size = deci; ea <= a + imm; next_state(LOAD1); end
        `LDBX,`LDBUX: begin mem_size = byt; ea <= a + (b << Sc) + imm; next_state(LOAD1); end
        `LDWX,`LDWUX: begin mem_size = wyde; ea <= a + (b << Sc) + imm; next_state(LOAD1); end
        `LDTX,`LDTUX: begin mem_size = tetra; ea <= a + (b << Sc) + imm; next_state(LOAD1); end
        `LDDX: begin mem_size = deci; ea <= a + (b << Sc) + imm; next_state(LOAD1); end
        `STB: begin mem_size = byt; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STW: begin mem_size = wyde; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STT: begin mem_size = tetra; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STD: begin mem_size = deci; ea <= a + imm; xb <= b; next_state(STORE1); end
        `STBX: begin mem_size = byt; ea <= a + (b << Sc) + imm; xb <= c; next_state(LOAD1); end
        `STWX: begin mem_size = wyde; ea <= a + (b << Sc) + imm; xb <= c; next_state(LOAD1); end
        `STTX: begin mem_size = tetra; ea <= a + (b << Sc) + imm; xb <= c; next_state(LOAD1); end
        `STDX: begin mem_size = deci; ea <= a + (b << Sc) + imm; xb <= c; next_state(LOAD1); end
        endcase
    end
    end // RUN
 
LOAD1:
    begin
        if ((xRa==6'd60 || xRa==6'd47)&&(ea < sbl || ea > sbu))
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
            load1(dhit);
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
                lres[63:8] <= {{64{dat_i[7]}},dat_i[7:0]};
            end
        `LDWU,`LDWUX:
            begin
                lres[63:8] <= {{64{1'b0}},dat_i[7:0]};
            end
        `LDT,`LDTX:
            begin
                case(ea[3:0])
                4'hD:   lres[63:24] <= {{48{dat_i[7]}},dat_i[7:0]};
                4'hE:   lres[63:16] <= {{48{dat_i[15]}},dat_i[15:0]};
                4'hF:   lres[63:8] <= {{48{dat_i[23]}},dat_i[23:0]};
                endcase
            end
        `LDTU,`LDTUX:
            begin
                case(ea[3:0])
                4'hD:   lres[63:24] <= {{48{1'b0}},dat_i[7:0]};
                4'hE:   lres[63:16] <= {{48{1'b0}},dat_i[15:0]};
                4'hF:   lres[63:8] <= {{48{1'b0}},dat_i[23:0]};
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
        `LDW,`LDWU,`LDT,`LDTU,`LDD:   
            xRt <= xir[19:14];
        `LDWX,`LDWUX,`LDTX,`LDTUX,`LDDX:
            xRt <= xir[27:22];
        `POP:
            begin
            xRt2 <= `TRUE;
            xRt <= xir[13:8];
            end
        `RET:
            xRt <= 6'd60|ol;   
        endcase
    end // LOAD4

STORE1:
    begin
        if ((xRa==6'd60 || xRa==6'd47)&&(ea < sbl || ea > sbu))
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
        `FLOAT1:
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
                adr_o <= {pcr80[31:4],4'h0};
            end
            else if (icmf[1]) begin
                cyc_o <= `TRUE;
                stb_o <= `TRUE;
                sel_o <= 8'hFF;
                adr_o <= {pcr80[31:4],4'h0} + 32'd80;
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
    `LDD:
        begin
            if (dhit) begin
                lres <= lres1[79:0];
                xRt <= xir[19:14];
                upd_rf <= `TRUE;
                next_state(INVnRUN);
            end
            else if (ea[3:0] < 4'h9) begin
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
	deci:  sel_o <= 16'h03FF << adr[3:0];
    endcase
    case(sz)
    wyde:   if (adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (adr[3:0] >4'hC) lock_o <= `HIGH;
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
	tetra: sel_o <= 16'h000F >> ~adr[3:0] + 4'd1;
	deci:  sel_o <= 16'h03FF >> ~adr[3:0] + 4'd1;
    endcase
end
endtask

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
	deci:  sel_o <= 16'h03FF << adr[3:0];
    endcase
    case(sz)
    byt:        dat_o <= ({120'd0,dat[7:0]} << {adr[3:0],3'b0});
    wyde:       dat_o <= ({112'h0,dat[15:0]} << {adr[3:0],3'b0}) | ({112'h0,dat[15:0]} >> {~adr[3:0] + 4'd1,3'b0});
    tetra:      dat_o <= ({96'h0,dat[31:0]} << {adr[3:0],3'b0}) | ({96'h0,dat[31:0]} >> {~adr[3:0] + 4'd1,3'b0});
    deci:       dat_o <= ({24'h0,dat} << {adr[3:0],3'b0}) | ({24'h0,dat} >> {~adr[3:0] + 4'd1,3'b0});
    endcase
    case(sz)
    wyde:   if (adr[3:0]==4'hF) lock_o <= `HIGH;
    tetra:  if (adr[3:0] >4'hC) lock_o <= `HIGH;
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
            sp <= {res2[63:4],4'h0};
        case(xRt)
        6'd1:   r1 <= res;
        6'd2:   r2 <= res;
        6'd46:  r46 <= res;
        6'd63:  sp <= {res[63:4],4'h0};
        endcase
        regfile[xRt] <= res;
        $display("regfile[%d] <= %h", xRt, res);
        // Globally enable interrupts after first update of stack pointer.
        if (xRt==6'd63)
            gie <= `TRUE;
    end
end
endtask

endmodule


// -----------------------------------------------------------------------------
// Round an instruction address to a multiple of 80 bytes.
// Multiply pc by 2.5 to convert to a byte address, then divide by 80 =
// = divide by 32
// then multiply by 80.
// -----------------------------------------------------------------------------

module DSD9_round80(i, o);
input [31:0] i;
output [31:0] o;

wire [31:0] iby32 = i >> 5;
wire [31:0] iby32x5 = {iby32,2'b00} + iby32;
wire [31:0] iby32x80 = {iby32x5,4'h0};
assign o = iby32x80;

endmodule

// -----------------------------------------------------------------------------
// Fast divide by five to determine cache line to update.
// Divide by five by multiplying by 1/5.
// 1/5 = 0.33333.... hex
// -----------------------------------------------------------------------------

module DSD9_divByFive(clk, i, o);
input clk;
input [31:0] i;
output reg [31:0] o;
wire [67:0] prod = i * 36'h333333333;   // a few extra bits precision
always @(posedge clk)
    o <= prod[67:36];
endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_icache_mem(wclk, wr, last_wr, wadr, i, rclk, radr, o0, o1);
input wclk;
input wr;
input last_wr;
input [31:0] wadr;
input [127:0] i;
input rclk;
input [31:0] radr;
output [639:0] o0;
output [639:0] o1;

reg [639:0] shft;
reg [639:0] mem [0:127];
reg [6:0] rrcl,rrclp1;

wire [31:0] wr_cache_line;
wire [31:0] rd_cache_line;
DSD9_divByFive u1 (wclk, wadr[31:4], wr_cache_line);

// 32 instruction parcels per cache line
assign rd_cache_line = radr >> 5;

reg ld;
always @(posedge wclk)
    ld <= last_wr & wr;

always @(posedge wclk)
    if (wr) shft <= {shft[511:0],i};
always @(posedge wclk)
    if (ld) mem[wr_cache_line[6:0]] <= shft;

always @(posedge rclk)
    rrcl <= rd_cache_line[6:0];        
always @(posedge rclk)
    rrclp1 <= rd_cache_line[6:0] + 7'd1;
    
assign o0 = mem[rrcl[6:0]];
assign o1 = mem[rrclp1[6:0]];        

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_icache_tag(wclk, wr, last_wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input last_wr;
input [31:0] wadr;
input rclk;
input [31:0] radr;
output hit0;
output hit1;

reg [31:0] tagmem [0:127];

reg ld;
reg [31:0] rrcl,rrclp1;
wire [31:0] wr_cache_line;
wire [31:0] rd_cache_line;
assign rd_cache_line = radr >> 5;
DSD9_divByFive u1 (wclk, wadr[31:4], wr_cache_line);
always @(posedge wclk)
    ld <= last_wr & wr;
always @(posedge rclk)
    rrcl <= rd_cache_line;        
always @(posedge rclk)
    rrclp1 <= rd_cache_line + 32'd1;

always @(posedge wclk)
    if (ld) tagmem[wr_cache_line[6:0]] <= wr_cache_line;

assign hit0 = tagmem[rrcl[6:0]][31:7]==rrcl[31:7];
assign hit1 = tagmem[rrclp1[6:0]][31:7]==rrclp1[31:7];

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

wire [639:0] ic0, ic1;

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
5'h01:  o <= ic0[139:20];
5'h02:  o <= ic0[159:40];
5'h03:  o <= ic0[179:60];
5'h04:  o <= ic0[199:80];
5'h05:  o <= ic0[219:100];
5'h06:  o <= ic0[239:120];
5'h07:  o <= ic0[259:140];
5'h08:  o <= ic0[279:160];
5'h09:  o <= ic0[299:180];
5'h0A:  o <= ic0[319:200];
5'h0B:  o <= ic0[339:220];
5'h0C:  o <= ic0[359:240];
5'h0D:  o <= ic0[379:260];
5'h0E:  o <= ic0[399:280];
5'h0F:  o <= ic0[419:300];
5'h10:  o <= ic0[439:320];
5'h11:  o <= ic0[459:340];
5'h12:  o <= ic0[479:360];
5'h13:  o <= ic0[499:380];
5'h14:  o <= ic0[519:400];
5'h15:  o <= ic0[539:420];
5'h16:  o <= ic0[559:440];
5'h17:  o <= ic0[579:460];
5'h18:  o <= ic0[599:480];
5'h19:  o <= ic0[619:500];
5'h1A:  o <= ic0[639:520];
5'h1B:  o <= {ic1[19:0],ic0[639:540]};
5'h1C:  o <= {ic1[39:0],ic0[639:560]};
5'h1D:  o <= {ic1[59:0],ic0[639:580]};
5'h1E:  o <= {ic1[79:0],ic0[639:600]};
5'h1F:  o <= {ic1[99:0],ic0[639:620]};
endcase

assign hit = (hit0 & hit1) || (hit0 && radr[4:0] < 5'h16);

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

