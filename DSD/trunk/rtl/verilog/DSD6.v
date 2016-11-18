// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd6.v
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
`include "dsd6_defines.vh"

module dsd6(hartid_i, rst_i, clk_i, tm_clk_i, irq_i, icause_i, rdy_i, vda_o, vpa_o, sel_o, wr_o, adr_o, dat_i, dat_o,
    tv_i, pv_i, cv_i, cx_i, cpl_o, pta_o);
parameter MSB=63;
input [MSB:0] hartid_i;
input rst_i;
input clk_i;
input tm_clk_i;         // wall clock time driver
input irq_i;
input [8:0] icause_i;
input rdy_i;
output reg vda_o;
output reg vpa_o;
output reg [7:0] sel_o;
output reg wr_o;
output reg [MSB:0] adr_o;
input [MSB:0] dat_i;
output reg [MSB:0] dat_o;
input tv_i;     // translation valid
input pv_i;     // privilege violation
input cv_i;     
input cx_i;     // executable code
output reg [7:0] cpl_o;
output [63:0] pta_o;

parameter SEGMODEL = 1;
parameter BRANCHIMM_INSN = 1;
parameter BITFIELD = 1;
parameter COMPRESSED_INSN   = 1; 
parameter MPYDVD_INSN = 1;
parameter ROTATE_INSN = 1;
parameter FLOAT_DOUBLE = 0;
parameter LS_WORDONLY = 0;
parameter LS_NDX = 1;

// Load / Store operation sizes
parameter byt = 2'd0;
parameter char = 2'd1;
parameter half = 2'd2;
parameter word = 2'd3;

// State machine states
parameter RUN = 8'd1;
parameter CALL1 = 8'd2;
parameter RET1 = 8'd3;
parameter DIV1 = 8'd5;
parameter LOAD1 = 8'd10;
parameter LOAD2 = 8'd11;
parameter LOAD3 = 8'd12;
parameter STORE1 = 8'd15;
parameter STORE2 = 8'd16;
parameter STORE3 = 8'd17;
parameter LOAD_ICACHE = 8'd20;
parameter LOAD_ICACHE2 = 8'd21; 
parameter ICACHE_RST = 8'd22;
parameter MUL1 = 8'd30;
parameter MUL2 = 8'd31;
parameter MUL3 = 8'd32;
parameter MUL4 = 8'd33;
parameter MUL5 = 8'd34;
parameter MUL6 = 8'd35;
parameter MUL7 = 8'd36;
parameter MUL8 = 8'd37;
parameter MUL9 = 8'd38;

reg [7:0] state, state1, state2, state3, state4;
reg [7:0] ret_state,ret2_state;
reg [1:0] ol,new_ol,tmp_ol;        // operating level 0=machine, 1=hypervisor, 2=supervisor, 3 = user
reg [127:0] insn;
reg [63:0] pc,dpc,xpc,old_pc,new_pc;     // program counter
reg [63:0] pc_stack [3:0];
reg incPC;                        // flag indicates to increment the PC
reg [63:0] evt_base;                // base address of exception vector table
reg [63:0] etr;    // task register, exceptioned task register
reg [8:0] vector;
reg [63:0] fault_pc;
reg [7:0] cpl,dpl,rpl,epl,tmp_pl;
wire [63:0] va,van;               // virtual address
reg [127:0] ir,xir,next_ir;
wire [6:0] iopcode = insn[6:0];
wire [6:0] ifunct = insn[31:25];
wire [3:0] ifunct4 = insn[15:12];
wire [4:0] iRa = insn[11:7];
wire [4:0] iRb = insn[16:12];
wire [4:0] iRc = insn[21:17];
wire [6:0] opcode = ir[6:0];
wire [6:0] funct = ir[31:25];
reg [6:0] xopcode,xfunct;
reg [4:0] Ra;
reg [4:0] Rb;
reg [4:0] Rc;
reg [4:0] Rt,xRt,wRt;
reg xRt2;
reg [4:0] xRa;
reg [5:0] Rn,Rn1,Rn2;           // For storing TSS
reg [63:0] regfile [31:0];
reg [63:0] r1,r2,r3;
reg [63:0] lc1,lc2,lc3;
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] sp [3:0];
reg [2:0] dilen,xilen;          // length of instruction in words
reg ls_flag,ex_done;
reg [63:0] a,b,c,xb,xa,wa;
reg [63:0] aa, bb;              // additional registering for multiply / divide
reg [75:0] imm76;
wire [63:0] imm = imm76[63:0];
reg [75:0] ea;
reg [47:0] br_disp;
reg [63:0] res,lres,lres1;
reg [63:0] res2;
wire csr_regno = xir[29:19];
reg [1:0] mem_size;
reg isok;
reg RFcnt,EXcnt,WBcnt;
reg [63:0] insncnt;
reg [63:0] rdinstret;
reg [63:0] faults;
reg [63:0] fault_bit;
reg brkIsExecuting;
reg [5:0] bitno;
reg cx,cv,pv;
reg [2:0] segprefix;
reg i32,i64;
wire advanceEX;
reg gie;
// CSR's
reg [63:0] tick;
reg [63:0] mtime, mtime_latch;
reg mtime_set;
reg [63:0] sb_lower [0:3];
reg [63:0] sb_upper [0:3];
reg [63:0] tr;
reg [63:0] pta;
reg [63:0] cisc;                // compressed instruction set address
wire [63:20] cita = cisc[63:20];
wire [7:0] isid = cisc[7:0];
reg [3:0] isp;
reg [63:0] mvba,hvba,svba;
reg [63:0] mcause,hcause,scause;
reg [63:0] mepc,hepc,sepc;
reg [63:0] mbadaddr,hbadaddr,sbadaddr;
reg [63:0] metr,hetr,setr;
reg [63:0] mscratch,hscratch,sscratch;
reg mprv;                       // memory privilege level switch
reg segen;                      // segmentation enable
reg [3:0] mimcd;                // interrupt mask count-down
reg mim;                        // machine interrupt mask
reg him;
reg sim;
reg uim;
reg xxim;
reg [3:0] ims;                  // interrupt mask stack
reg [7:0] ols;                 // operating level stack
reg [31:0] pls;                 // privilege level stack
reg [63:0] cs_base,ds_base,es_base,fs_base,gs_base,hs_base,js_base;
reg [63:0] cs_limit,ds_limit,es_limit,fs_limit,gs_limit,hs_limit,js_limit;
reg [15:0] cs_acr,ds_acr,es_acr,fs_acr,gs_acr,hs_acr,js_acr;
reg [63:0] seg_base,seg_limit;
wire [63:0] cap =
{
    FLOAT_DOUBLE,
    COMPRESSED_INSN,
    BITFIELD,
    1'b0
};
reg [63:0] mconfig;
wire [4:0] regSP = mconfig[4:0];
wire [4:0] regBP = mconfig[12:8];

assign pta_o = pta;

// Control and Status bits
reg im;                         // interrupt mask
reg nt;                         // nested task
wire [31:0] flags;
reg mpy_done;
wire dvd_done;
assign flags = {cpl,ol,5'h00,im,8'h00,6'h00,dvd_done,mpy_done};

function [63:0] fnAbs;
input [63:0] jj;
fnAbs = jj[63] ? -jj : jj;
endfunction

function [63:0] fnSeg;
input [2:1] segno;
case(segno)
3'd0:   fnSeg = ds_base;
3'd1:   fnSeg = es_base;
3'd2:   fnSeg = fs_base;
3'd3:   fnSeg = gs_base;
3'd4:   fnSeg = hs_base;
3'd5:   fnSeg = js_base;
3'd6:   fnSeg = cs_base;
3'd7:   fnSeg = cs_base;
endcase
endfunction

function [63:0] fnSeglmt;
input [2:0] segno;
case(segno)
3'd0:   fnSeglmt = ds_limit;
3'd1:   fnSeglmt = es_limit;
3'd2:   fnSeglmt = fs_limit;
3'd3:   fnSeglmt = gs_limit;
3'd4:   fnSeglmt = hs_limit;
3'd5:   fnSeglmt = js_limit;
3'd6:   fnSeglmt = cs_limit;
3'd7:   fnSeglmt = cs_limit;
endcase
endfunction

function [2:0] fnInsnLength;
input [31:0] isn;
casex(isn[6:0])
7'b101xxxx: fnInsnLength = 1;   // 16 bit Huffman encoded or other 16 bit encodes
`BRK0,`BRK1,`ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI:   
    if (isn[31:24]==8'h80)
        fnInsnLength = 4;
    else if (isn[31:24]==8'h81)
        fnInsnLength = 6;
    else
        fnInsnLength = 2;
`BccI,`BccUI:
    begin
        if (isn[16:12]==5'h10)
            fnInsnLength = 4;
        else if (isn[16:12]==5'h11)
            fnInsnLength = 6;
        else
            fnInsnLength = 2;
    end
`CSRI:
    begin
        if (isn[11:7]==5'h10)
            fnInsnLength = 4;
        else if (isn[11:7]==5'h11)
            fnInsnLength = 6;
        else
            fnInsnLength = 2;
    end
`BITFLD:
    if (isn[31:29]==`BFINSI && BITFIELD) begin
        if (isn[11:7]==5'h10)
            fnInsnLength = 4;
        else if (isn[11:7]==5'h11)
            fnInsnLength = 6;
        else
            fnInsnLength = 2;
    end
    else
        fnInsnLength = 2;
7'h4x,7'h6x:
    if (isn[31:24]==8'h80)
        fnInsnLength = 4;
    else if (isn[31:24]==8'h81)
        fnInsnLength = 6;
    else
        fnInsnLength = 2;
`JMP,`CALL:
    if (isn[31:24]==8'h80)
        fnInsnLength = 4;
    else if (isn[31:24]==8'h81)
        fnInsnLength = 6;
    else
        fnInsnLength = 2;
default:  fnInsnLength = 2;
endcase

endfunction

// Results forwarding multiplexer

function [63:0] fwd_mux;
input [4:0] Rn;
begin
    case(Rn)
    5'd0:   fwd_mux = 32'd0;
    xRt:    fwd_mux = res;
    5'd1:   fwd_mux = r1;
    5'd2:   fwd_mux = r2;
    5'd3:   fwd_mux = r3;
    regSP:  if (xRt2)
                fwd_mux = res2;
            else
                fwd_mux = sp[ol];
    default:    fwd_mux = regfile[Rn]; 
    endcase
end
endfunction


wire xisRF = (xopcode==`R2 && xfunct==`IRET);
wire xisLd = xopcode[6:3]==4'b1000;
wire xisSt = xopcode[6:3]==4'b1001;

wire [63:0] psh_va = a - 64'd8;
assign va = a + imm;
assign van = a + b;

reg wr_istk;
reg [3:0] istk_wa;
reg [511:0] istk_i;
wire [511:0] istk_o;

DSD6_istack uis1
(
    .clk(clk),
    .wr(wr_istk),
    .wa(istk_wa),
    .i(istk_i),
    .ra(isp),
    .o(istk_o)
);

wire xMul = xopcode==`R2 && (xfunct==`MUL || xfunct==`MULH);
wire xMulu = xopcode==`R2 && (xfunct==`MULU || xfunct==`MULUH);
wire xMulsu = xopcode==`R2 && (xfunct==`MULSU || xfunct==`MULSUH);
wire xMuli = xopcode==`MULI || xopcode==`MULHI;
wire xMului = xopcode==`MULUI || xopcode==`MULUHI;
wire xMulsui = xopcode==`MULSUI || xopcode==`MULSUHI;

wire [127:0] mul_prod1;
reg [127:0] mul_prod;
reg mul_sign;
// 6 stage pipeline
DSD_mult_gen0 u2 (
  .CLK(clk_i),  // input wire CLK
  .A(aa),      // input wire [63 : 0] A
  .B(bb),      // input wire [63 : 0] B
  .P(mul_prod1) // output wire [127 : 0] P
);

wire [63:0] qo, ro;

wire xDiv = xopcode==`DIVI || xopcode==`DIVUI || xopcode==`DIVSUI || xopcode==`REMI || xopcode==`REMUI || xopcode==`REMSUI ||
             (xopcode==`R2 && (xfunct==`DIV || xfunct==`DIVU || xfunct==`DIVSU || xfunct==`REM || xfunct==`REMU || xfunct==`REMSU))
             ;
wire xDivi = xopcode==`DIVI || xopcode==`DIVUI || xopcode==`DIVSUI || xopcode==`REMI || xopcode==`REMUI || xopcode==`REMSUI;
wire xDivss = xopcode==`DIVI || (xopcode==`R2 && (xfunct==`DIV || xfunct==`REM));
wire xDivsu = xopcode==`DIVSUI || (xopcode==`R2 && (xfunct==`DIVSU || xfunct==`REMSU));

DSD_divider #(64) u1
(
	.rst(rst_i),
	.clk(clk_i),
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
	.done(dvd_done)
);


DSD_BranchEval ubeval1
(   
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .takb(takb)
);

wire predict_taken;
reg dbranch_taken,xbranch_taken;
DSD_BranchHistory ubh1
(
    .rst(rst_i),
    .clk(clk_i),
    .advanceX(advanceEX),
    .xir(xir[31:0]),
    .pc(pc),
    .xpc(xpc),
    .takb(takb),
    .predict_taken(predict_taken)
);

//---------------------------------------------------------------------------
// Lookup table for compressed instructions.
//---------------------------------------------------------------------------
wire [31:0] hinsn;
wire cs_hl = vda_o && wr_o && adr_o[63:20]==cisc[63:20];
DSD_hLookupTbl u3
(
    .wclk(clk_i),
    .wr(cs_hl),
    .wadr(adr_o[13:2]),
    .wdata(dat_o),
    .rclk(~clk_i),
    .radr({isid[1:0],insn[13:7],insn[2:0]}),
    .rdata(hinsn)
);

//---------------------------------------------------------------------------
// I-Cache
// This 64-line 4 way set associative cache is used mainly to allow access
// to 16 and 64 bit instructions while the external bus is 32 bit.
// On reset the cache is loaded with NOP's and the tag memory is loaded
// with $FFF...FC00. There should not be any valid instructions placed in the
// the area $FFFF...FC00 to $FFFF...FFFF
//---------------------------------------------------------------------------
wire [63:0] pcp16 = pc + 64'h0010;
wire [63:0] cspc = ol!=`OL_MACHINE && SEGMODEL && segen ? cs_base + pc : pc;
wire [63:0] cspcp16 = ol!=`OL_MACHINE && SEGMODEL && segen ? cs_base + pcp16: pcp16;
wire [22:0] ic_lfsr;

lfsr #(23,23'h00ACE1) ulfsr1
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
reg [63:0] tag_mem0 [0:63];
reg [63:0] tag_mem1 [0:63];
reg [63:0] tag_mem2 [0:63];
reg [63:0] tag_mem3 [0:63];
always @(posedge clk_i)
  if (isICacheReset) begin
    case(adr_o[3])
    2'd0: begin
            cache_mem0[adr_o[9:4]][63:0] <= dat_i;
            cache_mem1[adr_o[9:4]][63:0] <= dat_i;
            cache_mem2[adr_o[9:4]][63:0] <= dat_i;
            cache_mem3[adr_o[9:4]][63:0] <= dat_i;
          end
    1'd1: begin
            cache_mem0[adr_o[9:4]][127:64] <= dat_i;
            cache_mem1[adr_o[9:4]][127:64] <= dat_i;
            cache_mem2[adr_o[9:4]][127:64] <= dat_i;
            cache_mem3[adr_o[9:4]][127:64] <= dat_i;
          end
    endcase
  end
  else begin
    if (isICacheLoad) begin
      case({ic_whichSet,adr_o[3]})
      3'd0: cache_mem0[adr_o[10:4]][63:0] <= dat_i;
      3'd1: cache_mem0[adr_o[10:4]][127:64] <= dat_i;
      3'd2: cache_mem1[adr_o[10:4]][63:0] <= dat_i;
      3'd3: cache_mem1[adr_o[10:4]][127:64] <= dat_i;
      3'd4: cache_mem2[adr_o[10:4]][63:0] <= dat_i;
      3'd5: cache_mem2[adr_o[10:4]][127:64] <= dat_i;
      3'd6: cache_mem3[adr_o[10:4]][63:0] <= dat_i;
      3'd7: cache_mem3[adr_o[10:4]][127:64] <= dat_i;
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
wire [127:0] co1 = hita ? co01 : hitb ? co11 : hitc ? co21 : hitd ? co31 : {2{`_2NOPINSN}};    // NOP on a miss
wire [127:0] co2 = hita ? co02 : hitb ? co12 : hitc ? co22 : hitd ? co32 : {2{`_2NOPINSN}};    // NOP on a miss
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
  if (isICacheReset && adr_o[3]) begin
    tag_mem0[adr_o[9:4]] <= adr_o;
    tag_mem1[adr_o[9:4]] <= adr_o;
    tag_mem2[adr_o[9:4]] <= adr_o;
    tag_mem3[adr_o[9:4]] <= adr_o;
  end
  else begin
    if (isICacheLoad && adr_o[3]) begin
        case(ic_whichSet)
        2'd0:   tag_mem0[adr_o[9:4]] <= adr_o;
        2'd1:   tag_mem1[adr_o[9:4]] <= adr_o;
        2'd2:   tag_mem2[adr_o[9:4]] <= adr_o;
        2'd3:   tag_mem3[adr_o[9:4]] <= adr_o;
        endcase
    end
  end
assign ihit01 = cspc[63:10]==tag_mem0[pc[9:4]][63:10];
assign ihit02 = cspcp16[63:10]==tag_mem0[pcp16[9:4]][63:10];
assign ihit11 = cspc[63:10]==tag_mem1[pc[9:4]][63:10];
assign ihit12 = cspcp16[63:10]==tag_mem1[pcp16[9:4]][63:10];
assign ihit21 = cspc[63:10]==tag_mem2[pc[9:4]][63:10];
assign ihit22 = cspcp16[63:10]==tag_mem2[pcp16[9:4]][63:10];
assign ihit31 = cspc[63:10]==tag_mem3[pc[9:4]][63:10];
assign ihit32 = cspcp16[63:10]==tag_mem3[pcp16[9:4]][63:10];
assign hita = (ihit01 & ihit02) || (ihit01 && pc[3:0]==4'h0);
assign hitb = (ihit11 & ihit12) || (ihit11 && pc[3:0]==4'h0);
assign hitc = (ihit21 & ihit22) || (ihit21 && pc[3:0]==4'h0);
assign hitd = (ihit31 & ihit32) || (ihit31 && pc[3:0]==4'h0);
wire ihit = hita|hitb|hitc|hitd;

/*
//---------------------------------------------------------------------------
// I-Cache
// This 128-line micro-cache is used mainly to allow access to 32,64,96,
// and 128 bit instructions while the external bus is 32 bit.
//---------------------------------------------------------------------------
wire [63:0] pcp16 = pc + 64'h0010;
wire [63:0] cspc = ol!=`OL_MACHINE && SEGMODEL ? cs_base + pc : pc;
wire [63:0] cspcp16 = ol!=`OL_MACHINE && SEGMODEL ? cs_base + pcp16: pcp16;
wire ihit1,ihit2;
reg [1:0] icmf;     // miss flags
reg isICacheReset;
reg isICacheLoad;
reg [127:0] cache_mem [0:127];
reg [63:11] tag_mem [0:127];
always @(posedge clk_i)
  if (isICacheReset) begin
    case(iadr_o[3])
    1'd0: cache_mem[iadr_o[10:4]][63:0] <= {`NOPINSN,`NOPINSN};
    1'd1: cache_mem[iadr_o[10:4]][127:64] <= {`NOPINSN,`NOPINSN};
    endcase
  end
  else begin
    if (isICacheLoad) begin
      case(iadr_o[3])
      1'd0: cache_mem[iadr_o[10:4]][63:0] <= idat_i;
      1'd1: cache_mem[iadr_o[10:4]][127:64] <= idat_i;
      endcase
    end
  end
wire [127:0] co1 = cache_mem[pc[10:4]];
wire [127:0] co2 = cache_mem[pcp16[10:4]];
always @(pc or co1 or co2)
case(pc[3:1])
3'd0: insn = co1;
3'd1: insn = {co2[23:0],co1[127:16]};
3'd2: insn = {co2[31:0],co1[127:32]};
3'd3: insn = {co2[47:0],co1[127:48]};
3'd4: insn = {co2[63:0],co1[127:64]};
3'd5: insn = {co2[79:0],co1[127:80]};
3'd6: insn = {co2[95:0],co1[127:96]};
3'd7: insn = {co2[111:0],co1[127:112]};
endcase 

always @(posedge clk_i)
  if (isICacheReset)
    tag_mem[iadr_o[10:4]] <= {63-10{1'b1}};
  else begin
    if (isICacheLoad && iadr_o[3:2]==2'b11)
      tag_mem[iadr_o[10:4]] <= iadr_o[63:11];
  end
assign ihit1 = cspc[63:11]==tag_mem[pc[10:4]];
assign ihit2 = cspcp16[63:11]==tag_mem[pcp16[10:4]];
wire ihit = ((ihit1 && ihit2) || (ihit1 && pc[3:0]==4'h0));
*/
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
assign advanceEX = 1'b1;
wire advanceWB = advanceEX;
wire advanceRF = !((xisLd || xisSt)&&ex_done==1'b0);
wire advanceIF = advanceRF & ihit;

wire [63:0] bf_out;
DSD_bitfield #(64) ubf1
(
    .op(xir[31:29]),
    .a(a),
    .b(b),
    .imm(imm),
    .m(xir[28:17]),
    .o(bf_out),
    .masko()
);

wire [63:0] logic_o;
DSD_logic ulogic1
(
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .imm(imm),
    .res(logic_o)
);

wire [63:0] shift_o;
DSD_shift #(ROTATE_INSN) ushift1
(
    .xir(xir[31:0]),
    .a(a),
    .b(b),
    .res(shift_o),
    .rolo()
);

always @*
begin
    casex(xopcode)
    `R2:
        case(xfunct)
        `ADD:   res <= a + b;
        `CMP:   res <= $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
        `CMPU:  res <= a < b ? -1 : a==b ? 0 : 1;
        `SUB:   res <= a - b;
        `AND,`OR,`EOR,`NAND,`NOR,`ENOR: res = logic_o;
        `SHL,`SHLI: res <= shift_o;
        `SHR,`SHRI: res <= shift_o;
        `ASR,`ASRI: res <= shift_o;
        `ROL,`ROLI: res <= shift_o;
        `ROR,`RORI: res <= shift_o;
        `MUL,`MULU,`MULSU:  res <= MPYDVD_INSN ? mul_prod[63:0] : 64'hDEADDEADDEADDEAD;
        `MULH,`MULUH,`MULSUH:   res <= MPYDVD_INSN ? mul_prod[127:64] : 64'hDEADDEADDEADDEAD;
        `DIV,`DIVU,`DIVSU:  res <= MPYDVD_INSN ? qo : 64'hDEADDEADDEADDEAD;
        `REM,`REMU,`REMSU:  res <= MPYDVD_INSN ? ro : 64'hDEADDEADDEADDEAD;
        `R2CSR,`R2CSRI:   read_csr(b[12:0],res);
        default:  res <= 64'd0;
        endcase
    `MEM:
        case(xir[15:12])
        `LTCB:  res <= lres;
        `PUSH,`CALLR:     res <= a + imm;
        `POP:   res <= lres;
        default:    res <= 64'd0;
        endcase
    `BITFLD:    res <= BITFIELD ? bf_out : 64'hDEADDEADDEADDEAD;
    `ADDI:  res <= a + imm;
    `CMPI:  res <= $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
    `CMPUI: res <= a < imm ? -1 : a==imm ? 0 : 1;
    `ANDI,`ORI,`EORI:  res <= logic_o;
    `MULI,`MULUI,`MULSUI:   res <= MPYDVD_INSN ? mul_prod[63:0] : 64'hDEADDEADDEADDEAD;
    `MULHI,`MULUHI,`MULSUHI:    res <= MPYDVD_INSN ? mul_prod[127:64] : 64'hDEADDEADDEADDEAD;
    `DIVI,`DIVUI,`DIVSUI:   res <= MPYDVD_INSN ? qo : 64'hDEADDEADDEADDEAD;
    `REMI,`REMUI,`REMSUI:   res <= MPYDVD_INSN ? ro : 64'hDEADDEADDEADDEAD;
    `CALL:  res <= a + imm;
    `RET:   res <= a + imm; 
    `CSR,`CSRI:   read_csr(xir[31:19],res);
    `LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWR:   res <= lres;   // Loads
    default:  res <= 64'd0;
    endcase
end

always @*
    case(xopcode)
    `MEM:
        case(xir[15:12])
        `POP:   res2 <= a + 64'd8;
        default:    res2 <= res;
        endcase
    default:
        res2 <= res;
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

// Masks of the implemented instructions 
reg [127:0] major_ismask;
reg [127:0] R2funct7_ismask;

always @(posedge clk_i)
if (rst_i) begin
  rdinstret <= 64'd0;
  insncnt <= 64'd0;
  mvba <= 64'hFFFFFFFFFFFFDE00;
  pc <= 64'hFFFFFFFFFFFFDF40;
  gie <= `FALSE;
  im <= `TRUE;
  brkIsExecuting <= `FALSE;
  isICacheReset <= `TRUE;
  adr_o <= 76'd0;
  vda_o <= `FALSE;
  vpa_o <= `TRUE;
  wr_o <= 1'b0;
  sel_o <= 8'hFF;
  adr_o <= 76'd0;
  ir <= `_2NOPINSN;
  xir <= `_2NOPINSN;
  cisc <= 64'hFFFFFFFFFFE00000;
  cv <= `TRUE;
  pv <= `FALSE;
  cx <= `TRUE;
  major_ismask <= 0;
  R2funct7_ismask <= 0;
  segprefix <= 3'b111;
  mim <= `TRUE;
  him <= `TRUE;
  sim <= `TRUE;
  mimcd <= 4'b0000;
  tick <= 64'd0;
  wr_istk <= `FALSE;
  next_state(ICACHE_RST);
end
else begin
wr_istk <= `FALSE;
tick <= tick + 64'd1;
if (mtime==mtime_latch)
    mtime_set <= `FALSE;
case(state)
ICACHE_RST:
    if (rdy_i) begin
        adr_o <= adr_o + 64'd8;
        if (adr_o[10:3]==8'hFF) begin
            vpa_o <= `FALSE;
            sel_o <= 8'h00;
      isICacheReset <= `FALSE;
      major_ismask[`BRK0] <= `TRUE;
      major_ismask[`BRK1] <= `TRUE;
      major_ismask[`RET] <= `TRUE;
      major_ismask[`BccI] <= BRANCHIMM_INSN;
      major_ismask[`BccUI] <= BRANCHIMM_INSN;
      major_ismask[`ADDI] <= `TRUE;
      major_ismask[`CMPI] <= `TRUE;
      major_ismask[`CMPUI] <= `TRUE;
      major_ismask[`ANDI] <= `TRUE;
      major_ismask[`ORI] <= `TRUE;
      major_ismask[`EORI] <= `TRUE;
      major_ismask[`CSRI] <= `TRUE;
      major_ismask[`R2] <= `TRUE;
      major_ismask[`R3] <= `TRUE;
      major_ismask[`BITFLD] <= BITFIELD;
      major_ismask[`JMP] <= `TRUE;
      major_ismask[`CALL] <= `TRUE;
      major_ismask[`Bcc] <= `TRUE;
      major_ismask[`BccU] <= `TRUE;
      major_ismask[`CSR] <= `TRUE;
      major_ismask[`LB] <= ~LS_WORDONLY;
      major_ismask[`LBU] <= ~LS_WORDONLY;
      major_ismask[`LC] <= ~LS_WORDONLY;
      major_ismask[`LCU] <= ~LS_WORDONLY;
      major_ismask[`LH] <= ~LS_WORDONLY;
      major_ismask[`LHU] <= ~LS_WORDONLY;
      major_ismask[`LW] <= `TRUE;
      major_ismask[`LWR] <= `TRUE;
      major_ismask[`SB] <= ~LS_WORDONLY;
      major_ismask[`SC] <= ~LS_WORDONLY;
      major_ismask[`SH] <= ~LS_WORDONLY;
      major_ismask[`SW] <= `TRUE;
      major_ismask[`SWC] <= `TRUE;
      major_ismask[7'h50] <= COMPRESSED_INSN;
      major_ismask[7'h51] <= COMPRESSED_INSN;
      major_ismask[7'h52] <= COMPRESSED_INSN;
      major_ismask[7'h53] <= COMPRESSED_INSN;
      major_ismask[7'h54] <= COMPRESSED_INSN;
      major_ismask[7'h55] <= COMPRESSED_INSN;
      major_ismask[7'h56] <= COMPRESSED_INSN;
      major_ismask[7'h57] <= COMPRESSED_INSN;
      major_ismask[`NOP] <= `TRUE;
      major_ismask[`RET] <= `TRUE;
      major_ismask[`MEM] <= `TRUE;
      major_ismask[`SYS] <= `TRUE;
      major_ismask[`BRK20] <= `TRUE;
      major_ismask[`BRK21] <= `TRUE;
      major_ismask[`MULI] <= MPYDVD_INSN;
      major_ismask[`MULUI] <= MPYDVD_INSN;
      major_ismask[`MULSUI] <= MPYDVD_INSN;
      major_ismask[`MULHI] <= MPYDVD_INSN;
      major_ismask[`MULUHI] <= MPYDVD_INSN;
      major_ismask[`MULSUHI] <= MPYDVD_INSN;
      major_ismask[`DIVI] <= MPYDVD_INSN;
      major_ismask[`DIVUI] <= MPYDVD_INSN;
      major_ismask[`DIVSUI] <= MPYDVD_INSN;
      major_ismask[`REMI] <= MPYDVD_INSN;
      major_ismask[`REMUI] <= MPYDVD_INSN;
      major_ismask[`REMSUI] <= MPYDVD_INSN;
      R2funct7_ismask[`ADD] <= `TRUE;
      R2funct7_ismask[`CMP] <= `TRUE;
      R2funct7_ismask[`CMPU] <= `TRUE;
      R2funct7_ismask[`SUB] <= `TRUE;
      R2funct7_ismask[`AND] <= `TRUE;
      R2funct7_ismask[`OR] <= `TRUE;
      R2funct7_ismask[`EOR] <= `TRUE;
      R2funct7_ismask[`NAND] <= `TRUE;
      R2funct7_ismask[`NOR] <= `TRUE;
      R2funct7_ismask[`ENOR] <= `TRUE;
      R2funct7_ismask[`SHL] <= `TRUE;
      R2funct7_ismask[`SHR] <= `TRUE;
      R2funct7_ismask[`ASR] <= `TRUE;
      R2funct7_ismask[`ROL] <= ROTATE_INSN;
      R2funct7_ismask[`ROR] <= ROTATE_INSN;
      R2funct7_ismask[`SHLI] <= `TRUE;
      R2funct7_ismask[`SHRI] <= `TRUE;
      R2funct7_ismask[`ASRI] <= `TRUE;
      R2funct7_ismask[`ROLI] <= ROTATE_INSN;
      R2funct7_ismask[`RORI] <= ROTATE_INSN;
      R2funct7_ismask[`NOP2] <= `TRUE;
      R2funct7_ismask[`MUL] <= MPYDVD_INSN;
      R2funct7_ismask[`MULU] <= MPYDVD_INSN;
      R2funct7_ismask[`MULSU] <= MPYDVD_INSN;
      R2funct7_ismask[`MULH] <= MPYDVD_INSN;
      R2funct7_ismask[`MULUH] <= MPYDVD_INSN;
      R2funct7_ismask[`MULSUH] <= MPYDVD_INSN;
      R2funct7_ismask[`DIV] <= MPYDVD_INSN;
      R2funct7_ismask[`DIVU] <= MPYDVD_INSN;
      R2funct7_ismask[`DIVSU] <= MPYDVD_INSN;
      R2funct7_ismask[`REM] <= MPYDVD_INSN;
      R2funct7_ismask[`REMU] <= MPYDVD_INSN;
      R2funct7_ismask[`REMSU] <= MPYDVD_INSN;
      R2funct7_ismask[`REX] <= `TRUE;
      R2funct7_ismask[`LBX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LBUX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LCX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LCUX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LHX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LHUX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`LWX] <= LS_NDX;
      R2funct7_ismask[`LWRX] <= LS_NDX;
      R2funct7_ismask[`SBX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`SCX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`SHX] <= LS_NDX & ~LS_WORDONLY;
      R2funct7_ismask[`SWX] <= LS_NDX;
      R2funct7_ismask[`SWCX] <= LS_NDX;
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
      mimcd <= {mimcd[2:0],1'b0};
      if (mimcd==4'b1000)
          mim <= `FALSE;
      insncnt <= insncnt + 64'd1;
      RFcnt <= 1'b1;
      if (insn[31:0]!=`WFI_INSN || irq_i) begin
        if (!cv)     begin next_ir = {`FLT_CODEPAGE,`BRK20}; mbadaddr <= -64'd1; cv <= `TRUE; end
        else if (pv) begin next_ir = {`FLT_PRIV,`BRK20}; mbadaddr <= -64'd1; pv <= `FALSE; end
        else if (!cx) begin next_ir = {`FLT_EXEC,`BRK20}; mbadaddr <= -64'd1; cx <= `TRUE; end
        else if (irq_i && !mim && gie)
            next_ir = {icause_i,`BRK20};
        else
            next_ir = iopcode[6:3]==4'hA ? hinsn : insn;

        Rb <= iRb;
        Rc <= iRc;
        // Mangle the register port selectors. RTS and PUSH have an implied
        // register spec of r31.
        if (iopcode==`CALL || iopcode==`RET ||
            (iopcode==`MEM && (insn[15:12]==`PUSH || insn[15:12]==`POP || insn[15:12]==`STCB || insn[15:12]==`JMPR || insn[15:12]==`CALLR))) begin
            Ra <= 5'd31;
            Rb <= iRa;
        end
        else
            Ra <= iRa;

        dpc <= pc;
        dbranch_taken <= `FALSE;
        // Figure out the target pc. In the case of the JMP instruction the target is
        // set directly from the instruction. In the case of branches a check is made
        // to see if the branch is predicted taken.
        // We want the PC to increment by only two for a compressed instruction, hence we look
        // at insn and not next_ir.
        new_pc = {pc[63:48],pc[47:0] + fnInsnLength(insn[31:0])}; // default
        case(iopcode)
        `JMP,`CALL:
            if (insn[31:24]==8'h80)
                new_pc = {insn[64:32],insn[23:7],1'b0};
            else 
                new_pc = {insn[31:7],1'b0};
        `Bcc,`BccU,`BccI,`BccUI:
            begin
                if (predict_taken) begin
                    new_pc = {pc[63:48],pc[47:0] + {{35{insn[31]}},insn[31:20],1'b0}};
                    dbranch_taken <= `TRUE;
                end
            end
        endcase
        if (ol!=`OL_MACHINE && SEGMODEL && segen) begin
            if (new_pc > cs_limit)
                next_ir = {`FLT_SEGBOUNDS,`BRK20};
        end
        // Check if the instruction is implemented
        // We assume that if the BITFIELD group is implemented all 
        // instructions under the group are implemented.
        if (major_ismask[next_ir[6:0]]) begin
            if (next_ir[6:0]==`R2) begin
                if (R2funct7_ismask[next_ir[31:25]])
                    ir <= next_ir;
                else
                    ir <= {`FLT_UNIMPINSN,`BRK20};
            end
            else
                ir <= next_ir;
        end
        else
            ir <= {`FLT_UNIMPINSN,`BRK20};
        pc <= new_pc;
        dilen <= fnInsnLength(insn[31:0]);
      end
    end
    else begin
      if (!ihit) begin
        icmf <= {ihit1,ihit2};
        cv <= `TRUE;
        pv <= `FALSE;
        cx <= `TRUE;
        next_state(LOAD_ICACHE);
      end
      if (advanceRF) begin
        RFcnt <= 1'b0;
        nop_ir();
        dpc <= pc;
        pc <= pc;
      end
    end
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
      EXcnt <= RFcnt;
      xbranch_taken <= dbranch_taken;
      xopcode <= opcode;
      xfunct <= funct;
      xilen <= dilen;
  	  xRa <= Ra;
  	  xir <= ir;
  	  xpc <= dpc;
      a <= fwd_mux(Ra);
      b <= fwd_mux(Rb);
      c <= fwd_mux(Rc);
      casex(opcode)
      `R2:
        case(funct)
        `SHLI,`SHRI,`ASRI,`ROLI,`RORI:     b <= {ir[22],Rb};
        default:    ;
        endcase
      default:  ;
      endcase
      // Branch displacement, used only for conditional branches.
      // Branches may also compare against an immediate so the displacement
      // has to be determined separately. 
      br_disp <= {{35{ir[31]}},ir[31:20],1'b0};
      // Set immediate value
      i32 = ir[31:24]==8'h80;   // we can't use dilen which is the PC increment
      i64 = ir[31:24]==8'h81;
      casex(opcode)
      `BRK0,`BRK1,`ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI:
                    imm76 <= i32 ? {{32{ir[63]}},ir[63:32]} : i64 ? ir[95:32] : {{49{ir[31]}},ir[31:17]};
      7'h4x,7'h6x:  imm76 <= i32 ? {{32{ir[63]}},ir[63:32]} : i64 ? ir[95:32] : {{49{ir[31]}},ir[31:17]};
      `BccI,`BccUI: imm76 <= Rb==5'h10  ? {{32{ir[63]}},ir[63:32]} : Rb==5'h11  ? ir[95:32] : {{59{Rb[4]}},Rb};
      `CSRI:        imm76 <= Ra==5'h10 ? {{32{ir[63]}},ir[63:32]} : Ra==5'h11 ? ir[95:32] : {{59{Ra[4]}},Ra};
      `CALL:        imm76 <= -64'd8;
      `RET:         imm76 <= {ir[15:7],3'b000};
      `R2:
        case(ir[31:25])
        `R2CSRI:    imm76 <= Ra==5'h10 ? {{32{ir[63]}},ir[63:32]} : Ra==5'h11 ? ir[95:32] : {{59{Ra[4]}},Ra};
        default:    imm76 <= 64'd0;
        endcase
      `MEM:
        case(ir[15:12])
        `CALLR:     imm76 <= -64'd8;
        `PUSH:      imm76 <= -64'd8;
        default:    imm76 <= 64'd0;
        endcase
      default:      imm76 <= 64'd0;
      endcase
      // Set target register
      xRt2 <= 1'b0;
      casex(opcode)
      `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI,`CSR,`CSRI:  xRt <= ir[16:12];
      `R2:  
        case(funct)
        `REX:   xRt <= 5'd0;
        7'b100_1xxx:    xRt <= 5'd0;    // Stores
        7'h58:  xRt <= 5'd0;            // NOP
        7'h7x:  xRt <= 5'd0;            // Misc.
        default:  xRt <= ir[21:17];
        endcase
      `R3:    xRt <= ir[26:22];
      7'b100_0xxx:  xRt <= ir[16:12];   // Loads
      `CALL,`RET:  xRt <= 5'd31;
      `MEM:
        case(ir[15:12])
        `CALLR: xRt <= 5'd31;
        `PUSH:  xRt <= 5'd31;
        `POP:   begin
                xRt2 <= 1'b1;
                xRt <= Ra;
                end
        `LTCB:  xRt <= Ra;
        default:    xRt <= 5'd0;
        endcase
      default:
        xRt <= 5'd0;
      endcase
      // Fetch segment register
      casex(opcode)
      `R2:
        casex(funct)
        7'h4x:
            begin
                seg_base <= fnSeg(ir[24:22]);
                seg_limit <= fnSeglmt(ir[24:22]);
            end
        endcase
     `MEM:
        case(ir[15:12])
        `PUSH,`CALLR:
            begin
                seg_base <= fnSeg(0);   // stack is in the data segment
                seg_limit <= fnSeglmt(0); 
            end
        endcase
     `CALL,`RET:
        begin
            seg_base <= fnSeg(0);   // stack is in the data segment
            seg_limit <= fnSeglmt(0); 
        end
      // The instruction might have been compressed so we can't check dilen.
      7'h4x:    if (!i32 && !i64) begin
                    case(Ra)
                    5'd27:  begin seg_base <= fs_base; seg_limit <= fs_limit; end 
                    5'd28:  begin seg_base <= gs_base; seg_limit <= gs_limit; end
                    default:    begin seg_base <= ds_base; seg_limit <= ds_limit; end 
                    endcase
                end
                else begin
                    seg_base <= fnSeg(ir[19:17]);
                    seg_limit <= fnSeglmt(ir[19:17]);
                end
      endcase
    end
    else if (advanceEX)
      nop_xir();
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceEX) begin
      if (ex_done==`TRUE)
        ex_done <= `FALSE;
      rdinstret <= rdinstret + EXcnt;
      // update register file
      regfile[xRt] <= res;
      if (xRt2)
          begin
            gie <= `TRUE;
            case(ol)
            `OL_USER:       sp[3] <= {res2[63:3],3'b000};
            `OL_SUPERVISOR: sp[2] <= {res2[63:3],3'b000};
            `OL_HYPERVISOR: sp[1] <= {res2[63:3],3'b000};
            `OL_MACHINE:    sp[0] <= {res2[63:3],3'b000};
            endcase
          end
      case(xRt)
      5'd1:     r1 <= res;
      5'd2:     r2 <= res;
      5'd3:     r3 <= res;
      regSP:
          begin
            gie <= `TRUE;
            case(ol)
            `OL_USER:       sp[3] <= {res[63:3],3'b000};
            `OL_SUPERVISOR: sp[2] <= {res[63:3],3'b000};
            `OL_HYPERVISOR: sp[1] <= {res[63:3],3'b000};
            `OL_MACHINE:    sp[0] <= {res[63:3],3'b000};
            endcase
          end
      default:  ;
      endcase
      if (xRt != 5'd0)
          $display("r%d = %h", xRt, res);
      // Should not check for stack fault when SP is updated.
      // This is checked when the address is calculated in a load / store.
      casex(xopcode)
      `R2:
        case(xfunct)
        `MUL,`MULH:
            begin
                if (ex_done==`FALSE) begin
                    ex_done <= `TRUE;
                    mul_sign <= a[63] ^ b[63];
                    aa <= fnAbs(a);
                    bb <= fnAbs(b);
                    next_state(MUL1);
                end
            end
        `MULU,`MULUH:
            begin
                if (ex_done==`FALSE) begin
                    ex_done <= `TRUE;
                    mul_sign <= 1'b0;
                    aa <= a;
                    bb <= b;
                    next_state(MUL1);
                end
            end
        `MULSU,`MULSUH:
            begin
                if (ex_done==`FALSE) begin
                    ex_done <= `TRUE;
                    mul_sign <= a[63];
                    aa <= fnAbs(a);
                    bb <= b;
                    next_state(MUL1);
                end
            end
        `DIV,`REM,
        `DIVU,`REMU,
        `DIVSU,`REMSU:
            begin
                if (ex_done==`FALSE) begin
                    ex_done <= `TRUE;
                    next_state(DIV1);
                end
            end
        `REX:   ex_rex();

        `LBX,`LBUX:  ex_mem(van, byt, c, LOAD1);
        `LCX,`LCUX:  ex_mem(van, char, c, LOAD1);
        `LHX,`LHUX:  ex_mem(van, half, c, LOAD1);
        `LWX,`LWRX:  ex_mem(van, word, c, LOAD1);

        `SBX: ex_mem(van, byt, c, STORE1);
        `SCX: ex_mem(van, char, c, STORE1);
        `SHX: ex_mem(van, half, c, STORE1);
        `SWX: ex_mem(van, word, c, STORE1);
        `SWCX: ex_mem(van, word, c, STORE1);
        `R2CSR:
            if (xRa!=5'd0)
                ex_csr(xir[23:22],b[12:0],a);
        `R2CSRI:  ex_csr(xir[23:22],b[12:0],imm);
        endcase // R2

      `SYS:
          case(xir[15:12])
          `IRET:   ex_rte();
          `SEI:   ex_sei();
          `CLI:   ex_cli();
          `IPUSH:   isp <= isp - 4'd1;
          `IPOP:    isp <= isp + 4'd1;
          endcase
      `MEM:
          case(xir[15:12])
          `LTCB:
              if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                ea <= {tr[63:9],9'h000} | {xRa,3'b000};
                mem_size = word;
                next_state(LOAD1);
              end
          `STCB:
            if (ex_done==`FALSE) begin
              ex_done <= `TRUE;
              ea <= {tr[63:9],9'h000} | {xRa,3'b000};
              xb <= b;
              mem_size = word;
              next_state(STORE1);
            end
          `PUSH:   ex_mem(va, word, b, STORE1);
          `JMPR:    tskBranch(b);
          `CALLR:   begin
                        ex_mem(a - 64'd8,word,{xpc[63:48],xpc[47:0] + {xilen,1'b0}},STORE1);
                        tskBranch(b);
                    end
          endcase

      `Bcc,`BccU,`BccI,`BccUI:
        if (takb && !xbranch_taken)
            tskBranch({xpc[63:48],xpc[47:0] + br_disp});
        else if (!takb && xbranch_taken)
            tskBranch({xpc[63:48],xpc[47:0] + {xilen,1'b0}});
          
      `JMP: ;   // Nothing to do. JMP is done at IFETCH
      `CALL: ex_mem(a - 64'd8,word,{xpc[63:48],xpc[47:0] + {xilen,1'b0}},STORE1);

      `RET:   ex_mem(a, word, b, LOAD1);   

      `BRK0,`BRK1,`BRK20,`BRK21:   fault(ir[15:7]);

      `LB,`LBU:  ex_mem(va, byt, b, LOAD1);
      `LC,`LCU:  ex_mem(va, char, b, LOAD1);
      `LH,`LHU:  ex_mem(va, half, b, LOAD1);
      `LW,`LWR:  ex_mem(va, word, b, LOAD1);

     // PUSH is almost identical to a store word, except that the stack pointer
     // will be updated by the instruction.
     `SB:     ex_mem(va, byt, b, STORE1);
     `SC:     ex_mem(va, char, b, STORE1);
     `SH:     ex_mem(va, half, b, STORE1);
     `SW:     ex_mem(va, word, b, STORE1);
     `SWC:    ex_mem(va, word, b, STORE1);

      `CSR:
        if (xRa!=5'd0)
            ex_csr(xir[18:17],xir[31:19],a);
      `CSRI:  ex_csr(xir[18:17],xir[31:19],imm);
      endcase   // xopcode
    end // advanceEX
  end

// Step1: setup operands and capture sign
MUL1:
    begin
        if (xMul) mul_sign <= a[63] ^ b[63];
        else if (xMuli) mul_sign <= a[63] ^ imm[63];
        else if (xMulsu) mul_sign <= a[63];
        else if (xMulsui) mul_sign <= a[63];
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
// Now wait for the six stage pipeline to finish
MUL2:   next_state(MUL3);
MUL3:   next_state(MUL4);
MUL4:   next_state(MUL5);
MUL5:   next_state(MUL6);
MUL6:   next_state(MUL7);
MUL7:   next_state(MUL8);
MUL8:   next_state(MUL9);
MUL9:
    begin
        mul_prod <= mul_sign ? -mul_prod1 : mul_prod1;
        next_state(RUN);
    end
DIV1:
    if (dvd_done)
        next_state(RUN);

LOAD1:
  begin
		wb_read1(mem_size,ea);
    next_state(LOAD2);
  end
LOAD2:
  if (rdy_i) begin
    lres1 = dat_i >> {ea[2:0],3'b0};
    if (pv_i) begin
        vda_o <= `FALSE;
        sel_o <= 8'h00;
        fault(`FLT_PRIV);
        lres <= 64'd0;
        mbadaddr <= ea;
        next_state(RUN);
    end
    else if (!tv_i) begin
        vda_o <= `FALSE;
        sel_o <= 8'h00;
        fault(`FLT_DATAPAGE);
        lres <= 64'd0;
        mbadaddr <= ea;
        next_state(RUN);
    end
    else
    case(xopcode)
    `LB:
      begin
      vda_o <= `FALSE;
      sel_o <= 8'h00;
      lres <= {{56{lres1[7]}},lres1[7:0]};
      next_state(RUN);
      end
    `LBU:
      begin
      vda_o <= `FALSE;
      sel_o <= 8'h00;
      lres <= {56'd0,lres1[7:0]};
      next_state(RUN);
      end
    `LC:
      begin
        case(ea[2:0])
        3'd7: begin wb_read2(mem_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
        default:
          begin  
          lres <= {{48{lres1[15]}},lres1[15:0]};
          vda_o <= `FALSE;
          sel_o <= 8'h00;
          next_state(RUN);
          end 
        endcase
      end
    `LCU:
      begin
        case(ea[2:0])
        3'd7: begin wb_read2(mem_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
        default:
          begin  
          lres <= {48'd0,lres1[15:0]};
          vda_o <= `FALSE;
          sel_o <= 8'h00;
          next_state(RUN);
          end 
        endcase
      end
    `LH:
      begin
        case(ea[2:0])
        3'd5: begin wb_read2(mem_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(mem_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(mem_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
        default:
          begin  
          lres <= {{32{lres1[31]}},lres1[31:0]};
          vda_o <= `FALSE;
          sel_o <= 8'h00;
          next_state(RUN);
          end 
        endcase
      end
    `LHU:
      begin
        case(ea[2:0])
        3'd5: begin wb_read2(mem_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(mem_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(mem_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
        default:
          begin  
          lres <= {32'd0,lres1[31:0]};
          vda_o <= `FALSE;
          sel_o <= 8'h00;
          next_state(RUN);
          end 
        endcase
      end
    `LW,`LWR:
      begin
        case(ea[2:0])
        3'd1: begin wb_read2(mem_size,ea); lres[55:0] <= lres1[55:0]; next_state(LOAD3); end
        3'd2: begin wb_read2(mem_size,ea); lres[47:0] <= lres1[47:0]; next_state(LOAD3); end
        3'd3: begin wb_read2(mem_size,ea); lres[39:0] <= lres1[39:0]; next_state(LOAD3); end
        3'd4: begin wb_read2(mem_size,ea); lres[31:0] <= lres1[31:0]; next_state(LOAD3); end
        3'd5: begin wb_read2(mem_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(mem_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(mem_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
        default:
          begin  
          $display("Loaded %h from %h", lres1, adr_o);
          lres <= lres1;
          vda_o <= `FALSE;
          sel_o <= 8'h00;
          next_state(RUN);
          end 
        endcase
      end
    `RET:   begin lres <= lres1; next_state(RET1); end
    endcase
  end
LOAD3:
  if (rdy_i) begin
    vda_o <= `FALSE;
    sel_o <= 8'h00;
    next_state(RUN);
    case(xopcode)
    `LC:   lres[63:8] <= {{48{dat_i[7]}},dat_i[7:0]};
    `LCU:  lres[63:8] <= {48'd0,dat_i[7:0]};
    `LH:
      case(ea[2:0])
      3'd5: lres[63:24] <= {{32{dat_i[7]}},dat_i[7:0]};
      3'd6: lres[63:16] <= {{32{dat_i[15]}},dat_i[15:0]};
      3'd7: lres[63:8] <= {{32{dat_i[23]}},dat_i[23:0]};
      endcase   
    `LHU:
      case(ea[2:0])
      3'd5: lres[63:24] <= {32'd0,dat_i[7:0]};
      3'd6: lres[63:16] <= {32'd0,dat_i[15:0]};
      3'd7: lres[63:8] <= {32'd0,dat_i[23:0]};
      endcase   
    `LW,`LWR:
      case(ea[2:0])
      3'd1: lres[63:56] <= dat_i[7:0];
      3'd2: lres[63:48] <= dat_i[15:0];
      3'd3: lres[63:40] <= dat_i[23:0];
      3'd4: lres[63:32] <= dat_i[31:0];
      3'd5: lres[63:24] <= dat_i[39:0];
      3'd6: lres[63:16] <= dat_i[47:0];
      3'd7: lres[63:8] <= dat_i[55:0];
      default:  ;
      endcase
    endcase
  end
RET1:
    begin
        tskBranch({lres[63:1],1'b0});
        next_state(RUN);
    end

STORE1:
	begin
		wb_write1(mem_size,ea,xb);
		$display("Store to %h <= %h", ea, xb);
		next_state(STORE2);
	end
STORE2:
	if (rdy_i) begin
        if (pv_i) begin
            vda_o <= `FALSE;
            sel_o <= 8'h00;
            fault(`FLT_PRIV);
            mbadaddr <= ea;
            next_state(RUN);
        end
        else if (!tv_i) begin
            vda_o <= `FALSE;
            sel_o <= 8'h00;
            fault(`FLT_DATAPAGE);
            mbadaddr <= ea;
            next_state(RUN);
        end
        else if (mem_size==char && ea[2:0]==3'b111 ||
	      mem_size==half && ea[2:0]>3'd4 ||
	      mem_size==word && ea[2:0]!=3'b000) begin
      		wb_write2(mem_size,ea,xb);
			next_state(STORE3);
	    end
		else begin
            vda_o <= `FALSE;
            wr_o <= 1'b0;
            sel_o <= 8'h00;
            next_state(RUN);
		end
	end
STORE3:
	if (rdy_i) begin
        vda_o <= `FALSE;
        wr_o <= 1'b0;
        sel_o <= 8'h00;
		next_state(RUN);
	end

LOAD_ICACHE:
  begin
    if (icmf != 2'b11) begin
      isICacheLoad <= `TRUE;
      if (icmf[1]) begin
        if (ol!=`OL_MACHINE && SEGMODEL)
            adr_o <= {cs_base[63:4],4'h0} + {pcp16[63:4],4'h0};
        else
            adr_o <= {pcp16[63:4],4'h0};
        icmf[0] <= 1'b1;
      end
      else begin
        icmf[1] <= 1'b1;
        if (ol!=`OL_MACHINE && SEGMODEL)
            adr_o <= {cs_base[63:4],4'h0} + {pc[63:4],4'h0};
        else
            adr_o <= {pc[63:4],4'h0};
      end
      next_state(LOAD_ICACHE2);
    end
    else
      next_state(RUN);
  end
LOAD_ICACHE2:
  if (rdy_i) begin
    // Cumulate error status
    cv <= cv & cv_i;
    pv <= pv | pv_i;
    cx <= cx & cx_i;
    adr_o[3] <= adr_o[3] + 1'd1;
    if (adr_o[3]) begin
        isICacheLoad <= `FALSE;
        next_state(icmf==2'b11 ? RUN : LOAD_ICACHE);
    end
  end
default:
  next_state(RUN);

endcase
end

task next_state;
input [7:0] st;
begin
  state <= st;
end
endtask

// Setup for memory operation in the EX stage
// Set the correct output privilege level for MMU.
// Do bounds checking according to output level. 
task ex_mem;
input [63:0] adr;
input [1:0] sz;
input [63:0] dat;   // used for stores
input [7:0] st;
begin
    if (ex_done==`FALSE) begin
        next_state(st);
        ex_done <= `TRUE;
        // Take the values at the top of the stack if the mprv bit is set
        // Otherwise use the running values.
        cpl_o <= mprv ? pls[7:0] : cpl;
        tmp_ol = mprv ? ols[1:0] : ol;
        // For the stack or base pointer check the stack bounds.
        if (xRa==regSP || xRa==regBP) begin
            if (adr < sb_lower[tmp_ol] || adr > sb_upper[tmp_ol]) begin
                fault(`STACK_FAULT);
                next_state(RUN);
            end
        end
        mem_size = sz;
        // If segmentation is enabled check the bounds for the
        // virtual address and compute the linear address.
        if (ol!=`OL_MACHINE && SEGMODEL && segen) begin
            if (adr > seg_limit) begin
                fault(`FLT_SEGBOUNDS);
                next_state(RUN);
            end
            ea <= seg_base + adr;
        end
        // No segmentation, linear address equals virtual address
        else
            ea <= adr;
        xb <= dat;
    end
end
endtask

// All faults are handled at the machine level which may redirect to a
// lower level.
task fault;
input [8:0] vec;
begin
    nop_ir();
    nop_xir();
    wr_istk <= `TRUE;
    case(ol)
    `OL_USER:       begin xxim = uim; uim <= `TRUE; end
    `OL_SUPERVISOR: begin xxim = sim; sim <= `TRUE; end
    `OL_HYPERVISOR: begin xxim = him; him <= `TRUE; end
    `OL_MACHINE:    begin xxim = mim; mim <= `TRUE; end
    endcase
    istk_i <= {
        ol,
        cpl,
        xxim,
        r3,
        r2,
        r1,
        cs_acr,
        cs_limit,
        cs_base,
        xpc + {xir[0],1'b0}
    };
    istk_wa <= isp; 

    mcause <= {vec,4'h0};
    pc <= {mvba[63:1],1'b0} + {~ol,6'h0};
    ol <= `OL_MACHINE;
    cpl <= 8'h00;
    mim <= `TRUE;
    next_state(RUN);
end
endtask

// IRET:
// Restore the program counter and privilege level.
// IRET always enables machine level exceptions.
task ex_rte;
begin
  case(ol)
  `OL_USER:     fault(`FLT_PRIV);
  default:
        begin
        tskBranch(istk_o[63:0]);
        cs_base <= istk_o[127:64];
        cs_limit <= istk_o[191:128];
        cs_acr <= istk_o[207:192];
        r1 <= istk_o[271:208];
        r2 <= istk_o[335:272];
        r3 <= istk_o[399:336];
        cpl <= istk_o[408:401];
        ol <= istk_o[410:409];
        //pc_stack[3] <= 64'h set to
//        pls <= {8'hFF,pls[31:8]};
//        cpl <= pls[7:0];
//        ols <= {`OL_USER,ols[7:2]};
//        ol <= ols[1:0];
//        ims <= {1'b0,ims[3:1]};
        mimcd <= 4'b1111;
        case(istk_o[410:409])
        `OL_USER:   ;//uim <= ims[0];
        `OL_SUPERVISOR: sim <= istk_o[400];
        `OL_HYPERVISOR: him <= istk_o[400];
        `OL_MACHINE:    ;//mim <= ims[0];
        endcase
        end
  endcase  
end
endtask

// Setting the exception mask takes effect immediately
task ex_sei;
begin
    case(ol)
    `OL_USER:           fault(`FLT_PRIV);
    `OL_SUPERVISOR:     sim <= `TRUE;
    `OL_HYPERVISOR:     him <= `TRUE;
    `OL_MACHINE:        mim <= `TRUE;
    endcase
end
endtask                

// Clearing the machine mode exception mask delays by three
// cycles to allow a following instruction to complete.
task ex_cli;
begin
    case(ol)
    `OL_USER:           fault(`FLT_PRIV);
    `OL_SUPERVISOR:     sim <= `FALSE;
    `OL_HYPERVISOR:     him <= `FALSE;
    `OL_MACHINE:        mimcd <= 4'b1111;
    endcase
end
endtask

// While redirecting an exception, the return program counter and status
// flags have already been stored in an internal stack.
// The exception can't be redirected unless exceptions are enabled for
// that level.
// Enable higher level interrupts.
task ex_rex;
begin
    case(ol)
    `OL_USER:   fault(`FLT_PRIV);
    `OL_MACHINE:
        case(xir[13:12])
        `OL_HYPERVISOR:
            if (him==`FALSE) begin
                hcause <= mcause;
                hbadaddr <= mbadaddr;
                nop_ir();
                nop_xir();
                pc <= hvba;
                ol <= xir[13:12];
                cpl <= 8'h01;   // no choice, it's 01
                mimcd <= 4'b1111;
            end
        `OL_SUPERVISOR:
            // must have a valid privilege level or redirect fails
            if (sim==`FALSE) begin
                tmp_pl = xir[21:14] | a[7:0];
                if (tmp_pl >= 8'h02 && tmp_pl <= 8'h07) begin
                    scause <= mcause;
                    sbadaddr <= mbadaddr;
                    nop_ir();
                    nop_xir();
                    pc <= svba;
                    ol <= xir[13:12];
                    cpl <= tmp_pl;
                    mimcd <= 4'b1111;
                    him <= `FALSE;
                end
            end
        endcase
    `OL_HYPERVISOR:
        if (xir[8:7]==`OL_SUPERVISOR && sim==`FALSE) begin
            // must have a valid privilege level or redirect fails
            tmp_pl = xir[21:14] | a[7:0];
            if (tmp_pl >= 8'h02 && tmp_pl <= 8'h07) begin
                scause <= hcause;
                sepc <= hepc;
                sbadaddr <= hbadaddr;
                setr <= hetr;
                nop_ir();
                nop_xir();
                pc <= svba;
                ol <= xir[13:12];
                cpl <= tmp_pl;
                mimcd <= 4'b1111;
                him <= `FALSE;
            end
        end
    endcase
end
endtask

task read_csr;
input [12:0] csrno;
output [63:0] res;
begin
    if (ol <= csrno[12:11])
    case(csrno[10:0])
    `CSR_HARTID:    res <= ol==`OL_MACHINE ? hartid_i : 64'd0;
    `CSR_TICK:      res <= tick;
    `CSR_PTA:   res <= pta;
    `VBA:
        case(csrno[12:11])
        `OL_USER:   res <= 64'd0;
        `OL_SUPERVISOR: res <= svba;
        `OL_HYPERVISOR: res <= hvba;
        `OL_MACHINE:    res <= mvba;
        endcase
    `ETR:
        case(csrno[12:11])
        `OL_USER:   res <= 64'd0;
        `OL_SUPERVISOR: res <= setr;
        `OL_HYPERVISOR: res <= hetr;
        `OL_MACHINE:    res <= metr;
        endcase
    `CAUSE:
        case(csrno[12:11])
        `OL_USER:   res <= 64'd0;
        `OL_SUPERVISOR: res <= scause;
        `OL_HYPERVISOR: res <= hcause;
        `OL_MACHINE:    res <= mcause;
        endcase
    `BADADDR:
        case(csrno[12:11])
        `OL_USER:   res <= 64'd0;
        `OL_SUPERVISOR: res <= sbadaddr;
        `OL_HYPERVISOR: res <= hbadaddr;
        `OL_MACHINE:    res <= mbadaddr;
        endcase
    `CSR_SCRATCH:
        case(csrno[12:11])
        `OL_USER:   res <= 64'd0;
        `OL_SUPERVISOR: res <= sscratch;
        `OL_HYPERVISOR: res <= hscratch;
        `OL_MACHINE:    res <= mscratch;
        endcase
    `CSR_LC1: res <= lc1;
    `CSR_LC2: res <= lc2;
    `CSR_LC3: res <= lc3;
    `SP:      res <= sp[csrno[12:11]];
    `CSR_SBL:     res <= sb_lower[csrno[12:11]];
    `CSR_SBU:     res <= sb_upper[csrno[12:11]];
    `TR:      res <= tr;
    `CSR_CISC:      res <= cisc;
    `CSR_STATUS:
        case(ol)
        `OL_USER:   res <= 64'd0;
        `OL_MACHINE:    res <= {pls,cpl,mprv,segen,4'b0,ols,ol,3'b0,ims,mim};
        endcase
    `CSR_INSRET:    res <= rdinstret;
    `CSR_TIME:      res <= mtime;

    `CSR_EPC:       res <= istk_o[63:0];
    `CSR_ECS_BASE:  res <= istk_o[127:64];
    `CSR_ECS_LIMIT: res <= istk_o[191:128];
    `CSR_ECS_ACR:   res <= istk_o[207:192];
    `CSR_ER1:       res <= istk_o[271:208];
    `CSR_ER2:       res <= istk_o[335:272];
    `CSR_ER29:      res <= istk_o[399:336];
    `CSR_EFLAGS:    res <= istk_o[410:400];

    `CSR_CS_BASE:   res <= ol==`OL_MACHINE ? cs_base : 64'd0;
    `CSR_CS_LIMIT:  res <= ol==`OL_MACHINE ? cs_limit : 64'd0;
    `CSR_CS_ACR:    res <= ol==`OL_MACHINE ? cs_acr : 64'd0;
    `CSR_DS_BASE:   res <= ol==`OL_MACHINE ? ds_base : 64'd0;
    `CSR_DS_LIMIT:  res <= ol==`OL_MACHINE ? ds_limit : 64'd0;
    `CSR_DS_ACR:    res <= ol==`OL_MACHINE ? ds_acr : 64'd0;
    `CSR_ES_BASE:   res <= ol==`OL_MACHINE ? es_base : 64'd0;
    `CSR_ES_LIMIT:  res <= ol==`OL_MACHINE ? es_limit : 64'd0;
    `CSR_ES_ACR:    res <= ol==`OL_MACHINE ? es_acr : 64'd0;
    `CSR_FS_BASE:   res <= ol==`OL_MACHINE ? fs_base : 64'd0;
    `CSR_FS_LIMIT:  res <= ol==`OL_MACHINE ? fs_limit : 64'd0;
    `CSR_FS_ACR:    res <= ol==`OL_MACHINE ? fs_acr : 64'd0;
    `CSR_GS_BASE:   res <= ol==`OL_MACHINE ? gs_base : 64'd0;
    `CSR_GS_LIMIT:  res <= ol==`OL_MACHINE ? gs_limit : 64'd0;
    `CSR_GS_ACR:    res <= ol==`OL_MACHINE ? gs_acr : 64'd0;
    `CSR_HS_BASE:   res <= ol==`OL_MACHINE ? hs_base : 64'd0;
    `CSR_HS_LIMIT:  res <= ol==`OL_MACHINE ? hs_limit : 64'd0;
    `CSR_HS_ACR:    res <= ol==`OL_MACHINE ? hs_acr : 64'd0;
    `CSR_JS_BASE:   res <= ol==`OL_MACHINE ? js_base : 64'd0;
    `CSR_JS_LIMIT:  res <= ol==`OL_MACHINE ? js_limit : 64'd0;
    `CSR_JS_ACR:    res <= ol==`OL_MACHINE ? js_acr : 64'd0;
    `CSR_CONFIG:    res <= mconfig;
    endcase
    else
        fault(`FLT_PRIV);
end
endtask

task ex_csr;
input [1:0] op;
input [12:0] csrno;
input [63:0] dat;
begin
    if (ex_done==`FALSE) begin
        ex_done <= `TRUE;
        case(op)
        `CSRRW:
          begin
            if (ol <= csrno[12:11]) begin
                casex(csrno[10:0])
                `CSR_HARTID:
                    if (ol!=`OL_MACHINE)
                        fault(`FLT_PRIV);
                `CSR_PTA:
                    if (csrno[12:11]==`OL_SUPERVISOR)
                        pta <= dat;
                `VBA:
                    case(csrno[12:11])
                    `OL_USER:   ;
                    `OL_SUPERVISOR: svba <= dat;
                    `OL_HYPERVISOR: hvba <= dat;
                    `OL_MACHINE:    mvba <= dat;
                    endcase
                `ETR:
                    case(csrno[12:11])
                    `OL_USER:   ;
                    `OL_SUPERVISOR: setr <= dat;
                    `OL_HYPERVISOR: hetr <= dat;
                    `OL_MACHINE:    metr <= dat;
                    endcase
                `CAUSE:
                    case(csrno[12:11])
                    `OL_USER:   ;
                    `OL_SUPERVISOR: scause <= dat;
                    `OL_HYPERVISOR: hcause <= dat;
                    `OL_MACHINE:    mcause <= dat;
                    endcase
                `BADADDR:
                    case(csrno[12:11])
                    `OL_USER:   ;
                    `OL_SUPERVISOR: sbadaddr <= dat;
                    `OL_HYPERVISOR: hbadaddr <= dat;
                    `OL_MACHINE:    mbadaddr <= dat;
                    endcase
                `CSR_SCRATCH:
                    case(csrno[12:11])
                    `OL_USER:   ;
                    `OL_SUPERVISOR: sscratch <= dat;
                    `OL_HYPERVISOR: hscratch <= dat;
                    `OL_MACHINE:    mscratch <= dat;
                    endcase
                `CSR_LC1:   lc1 <= dat;
                `CSR_LC2:   lc2 <= dat;
                `CSR_LC3:   lc3 <= dat;
                `SP:    sp[csrno[12:11]] <= dat;
                `CSR_SBL:   sb_lower[csrno[12:11]] <= dat;
                `CSR_SBU:   sb_upper[csrno[12:11]] <= dat;
                `TR:    tr <= dat;
                `CSR_CISC:  cisc <= dat;
                `CSR_TIME:  begin
                            mtime_latch <= dat;
                            mtime_set <= `TRUE;
                            end

                `CSR_EPC:       begin istk_wa <= isp; istk_i[63:0] <= dat; end
                `CSR_ECS_BASE:  begin istk_wa <= isp; istk_i[127:64] <= dat; end
                `CSR_ECS_LIMIT: begin istk_wa <= isp; istk_i[191:128] <= dat; end
                `CSR_ECS_ACR:   begin istk_wa <= isp; istk_i[207:192] <= dat[15:0]; end
                `CSR_ER1:       begin istk_wa <= isp; istk_i[271:208] <= dat; end
                `CSR_ER2:       begin istk_wa <= isp; istk_i[335:272] <= dat; end
                `CSR_ER29:      begin istk_wa <= isp; istk_i[399:336] <= dat; end
                `CSR_EFLAGS:    begin istk_wa <= isp; istk_i[510:400] <= dat[10:0]; end

                `CSR_CS_BASE:   cs_base <= dat;
                `CSR_DS_BASE:   ds_base <= dat;
                `CSR_ES_BASE:   es_base <= dat;
                `CSR_FS_BASE:   fs_base <= dat;
                `CSR_GS_BASE:   gs_base <= dat;
                `CSR_HS_BASE:   hs_base <= dat;
                `CSR_JS_BASE:   js_base <= dat;
                `CSR_CS_LIMIT:  cs_limit <= dat;
                `CSR_DS_LIMIT:  ds_limit <= dat;
                `CSR_ES_LIMIT:  es_limit <= dat;
                `CSR_FS_LIMIT:  fs_limit <= dat;
                `CSR_GS_LIMIT:  gs_limit <= dat;
                `CSR_HS_LIMIT:  hs_limit <= dat;
                `CSR_JS_LIMIT:  js_limit <= dat;
                `CSR_CS_ACR:    cs_acr <= dat[15:0];
                `CSR_FS_ACR:    ds_acr <= dat[15:0];
                `CSR_ES_ACR:    es_acr <= dat[15:0];
                `CSR_FS_ACR:    fs_acr <= dat[15:0];
                `CSR_GS_ACR:    gs_acr <= dat[15:0];
                `CSR_HS_ACR:    hs_acr <= dat[15:0];
                `CSR_JS_ACR:    js_acr <= dat[15:0];
                `CSR_CONFIG:    if (ol==`OL_MACHINE) mconfig <= dat; else fault(`FLT_PRIV);
                default:    ;
                endcase
            end
            else
                fault(`FLT_PRIV);
          end
        endcase // case xir[18:17]
    end
end
endtask

task wb_read1;
input [1:0] sz;
input [75:0] adr;
begin
	vda_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	byt:
		case(adr[2:0])
		3'd0:	sel_o <= 8'h01;
		3'd1:	sel_o <= 8'h02;
		3'd2:	sel_o <= 8'h04;
		3'd3:	sel_o <= 8'h08;
		3'd4:	sel_o <= 8'h10;
		3'd5:	sel_o <= 8'h20;
		3'd6:	sel_o <= 8'h40;
		3'd7:	sel_o <= 8'h80;
		endcase
	char:
		case(adr[2:0])
		3'd0: sel_o <= 8'h03;
		3'd1: sel_o <= 8'h06;
		3'd2: sel_o <= 8'h0C;
		3'd3: sel_o <= 8'h18;
		3'd4: sel_o <= 8'h30;
		3'd5: sel_o <= 8'h60;
		3'd6: sel_o <= 8'hC0;
		3'd7: sel_o <= 8'h80;
		endcase
	half:
    case(adr[2:0])
    3'd0: sel_o <= 8'h0F;
    3'd1: sel_o <= 8'h1E;
    3'd2: sel_o <= 8'h3C;
    3'd3: sel_o <= 8'h78;
    3'd4: sel_o <= 8'hF0;
    3'd5: sel_o <= 8'hE0;
    3'd6: sel_o <= 8'hC0;
    3'd7: sel_o <= 8'h80;
    endcase
  word:
    case(adr[2:0])
    3'd0: sel_o <= 8'hFF;
    3'd1: sel_o <= 8'hFE;
    3'd2: sel_o <= 8'hFC;
    3'd3: sel_o <= 8'hF8;
    3'd4: sel_o <= 8'hF0;
    3'd5: sel_o <= 8'hE0;
    3'd6: sel_o <= 8'hC0;
    3'd7: sel_o <= 8'h80;
    endcase
	default:	sel_o <= 8'h00;
	endcase
end
endtask

task wb_read2;
input [1:0] sz;
input [75:0] adr;
begin
	vda_o <= 1'b1;
	adr_o <= {adr[75:3]+73'd1,3'b00};
	case(sz)
	char:  sel_o <= 8'h01;
	half:
    case(adr[2:0])
    3'd1: sel_o <= 8'h01;
    3'd2: sel_o <= 8'h03;
    3'd3: sel_o <= 8'h07;
    default:  sel_o <= 8'h00;
    endcase
	word:
    case(adr[2:0])
    3'd1: sel_o <= 8'h01;
    3'd2: sel_o <= 8'h03;
    3'd3: sel_o <= 8'h07;
    3'd4: sel_o <= 8'h0F;
    3'd5: sel_o <= 8'h1F;
    3'd6: sel_o <= 8'h3F;
    3'd7: sel_o <= 8'h7F;
    default:  sel_o <= 8'h00;
    endcase
	default:	sel_o <= 8'h00;
	endcase
end
endtask

task wb_write1;
input [1:0] sz;
input [75:0] adr;
input [63:0] dat;
begin
	vda_o <= 1'b1;
	wr_o <= 1'b1;
	adr_o <= adr;
	case(sz)
	byt:
		begin
		dat_o <= {8{dat[7:0]}};
		case(adr[2:0])
    3'd0:  sel_o <= 8'h01;
    3'd1:  sel_o <= 8'h02;
    3'd2:  sel_o <= 8'h04;
    3'd3:  sel_o <= 8'h08;
    3'd4:  sel_o <= 8'h10;
    3'd5:  sel_o <= 8'h20;
    3'd6:  sel_o <= 8'h40;
    3'd7:  sel_o <= 8'h80;
    endcase
		end
	char:
		case(adr[2:0])
		3'd0:	begin sel_o <= 8'h03; dat_o <= {4{dat[15:0]}}; end
		3'd1:	begin sel_o <= 8'h06;	dat_o <= {dat[15:0],8'h00}; end
		3'd2:	begin sel_o <= 8'h0C; dat_o <= {4{dat[15:0]}}; end
		3'd3:	begin sel_o <= 8'h18; dat_o <= {dat[15:0],24'h0}; end
		3'd4:	begin sel_o <= 8'h30; dat_o <= {4{dat[15:0]}}; end
		3'd5:	begin sel_o <= 8'h60;	dat_o <= {dat[15:0],40'h00}; end
		3'd6:	begin sel_o <= 8'hC0; dat_o <= {4{dat[15:0]}}; end
		3'd7:	begin sel_o <= 8'h80;	dat_o <= {dat[7:0],56'h00}; end
		endcase
	half:
    case(adr[2:0])
    3'd0:  begin sel_o <= 8'h0F; dat_o <= {2{dat[31:0]}}; end
    3'd1:  begin sel_o <= 8'h1E; dat_o <= {dat[31:0],8'h00}; end
    3'd2:  begin sel_o <= 8'h3C; dat_o <= {2{dat[31:0]}}; end
    3'd3:  begin sel_o <= 8'h78; dat_o <= {dat[31:0],24'h0}; end
    3'd4:  begin sel_o <= 8'hF0; dat_o <= {2{dat[31:0]}}; end
    3'd5:  begin sel_o <= 8'hE0; dat_o <= {dat[23:0],40'h00}; end
    3'd6:  begin sel_o <= 8'hC0; dat_o <= {2{dat[31:0]}}; end
    3'd7:  begin sel_o <= 8'h80; dat_o <= {dat[7:0],56'h00}; end
    endcase
	word:
    case(adr[2:0])
    3'd0:  begin sel_o <= 8'hFF; dat_o <= dat[63:0]; end
    3'd1:  begin sel_o <= 8'hFE; dat_o <= {dat[55:0],8'h0}; end
    3'd2:  begin sel_o <= 8'hFC; dat_o <= {dat[47:0],16'h0}; end
    3'd3:  begin sel_o <= 8'hF8; dat_o <= {dat[39:0],24'h0}; end
    3'd4:  begin sel_o <= 8'hF0; dat_o <= {dat[31:0],32'h0}; end
    3'd5:  begin sel_o <= 8'hE0; dat_o <= {dat[23:0],40'h0}; end
    3'd6:  begin sel_o <= 8'hC0; dat_o <= {dat[15:0],48'h0}; end
    3'd7:  begin sel_o <= 8'h80; dat_o <= {dat[7:0],56'h0}; end
    endcase
	endcase
end
endtask

task wb_write2;
input [1:0] sz;
input [75:0] adr;
input [63:0] dat;
begin
  vda_o <= `TRUE;
  wr_o <= 1'b1;
  adr_o <= {adr[75:3]+73'd1,3'b0};
	case(sz)
	char:
	  case(adr[2:0])
	  3'd7:  begin sel_o <= 8'h01; dat_o <= dat[15:8]; end
	  default: ;
	  endcase
  half:
    case(adr[2:0])
    3'd5: begin sel_o <= 8'h01; dat_o <= dat[31:24]; end
    3'd6: begin sel_o <= 8'h03; dat_o <= dat[31:16]; end
    3'd7: begin sel_o <= 8'h07; dat_o <= dat[31:8]; end
    default:  ;
    endcase
	word:
    case(adr[2:0])
    3'd1: begin sel_o <= 8'h01; dat_o <= dat[63:56]; end
    3'd2: begin sel_o <= 8'h03; dat_o <= dat[63:48]; end
    3'd3: begin sel_o <= 8'h07; dat_o <= dat[63:40]; end
    3'd4: begin sel_o <= 8'h0F; dat_o <= dat[63:32]; end
    3'd5: begin sel_o <= 8'h1F; dat_o <= dat[63:24]; end
    3'd6: begin sel_o <= 8'h3F; dat_o <= dat[63:16]; end
    3'd7: begin sel_o <= 8'h7F; dat_o <= dat[63:8]; end
    default:  ;
    endcase
  default:  ;
	endcase
end
endtask


task nop_ir;
begin
  ir[6:0] <= `NOP;
  dbranch_taken <= `FALSE;
end
endtask

task nop_xir;
begin
  xir[6:0] <= `NOP;
  xopcode <= `NOP;
  xRt <= 5'd0;
end
endtask

task tskBranch;
input [63:0] newpc;
begin
  pc <= newpc;
  pc[0] <= 1'b0;
  nop_ir();
  nop_xir();
  RFcnt <= 1'b0;
  EXcnt <= 1'b0;
end
endtask

task push_state;
input [7:0] st;
begin
  state4 <= state3;
  state3 <= state2;
  state2 <= state1;
  state1 <= st;
end
endtask

task pop_state;
begin
  state <= state1;
  state1 <= state2;
  state2 <= state3;
  state3 <= state4;
  state4 <= RUN;
end
endtask

task call_state;
input [7:0] st;
input [7:0] retst;
begin
  push_state(retst);
  next_state(st);
end
endtask

endmodule

module DSD6_istack(clk, wr, wa, i, ra, o);
input clk;
input wr;
input [3:0] wa;
input [511:0] i;
input [3:0] ra;
output [511:0] o;

reg [511:0] mem;

always @(posedge clk)
    if (wr)
        mem[wa] <= i;

assign o = mem[ra];

endmodule

