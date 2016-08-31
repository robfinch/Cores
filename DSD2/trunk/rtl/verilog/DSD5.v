`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd5.v
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
`define TRUE      1'b1
`define FALSE     1'b0

`define BRK       7'h00
`define RTS       7'h01
`define ADDI      7'h04
`define CMPI      7'h05
`define CMPUI     7'h06
`define ANDI      7'h08
`define ORI       7'h09
`define EORI      7'h0A
`define BEQ       7'h10
`define BNE       7'h11
`define BLT       7'h12
`define BGE       7'h13
`define BLE       7'h14
`define BGT       7'h15
`define BLTU      7'h16
`define BGEU      7'h17
`define BLEU      7'h18
`define BGTU      7'h19
`define BEQI      7'h20
`define BNEI      7'h21
`define BLTI      7'h22
`define BGEI      7'h23
`define BLEI      7'h24
`define BGTI      7'h25
`define BLTUI     7'h26
`define BGEUI     7'h27
`define BLEUI     7'h28
`define BGTUI     7'h29
`define CSR       7'h1F
`define CSRI      7'h2F
`define R2        7'h30
`define R3        7'h31
`define JMP       7'h34
`define JSR       7'h35
`define LDT       7'h38
`define LB        7'h40
`define LBU       7'h41
`define LC        7'h42
`define LCU       7'h43
`define LH        7'h44
`define LHU       7'h45
`define LW        7'h46
`define LWR       7'h47
`define SB        7'h50
`define SC        7'h51
`define SH        7'h52
`define SW        7'h53
`define SWC       7'h54
`define STSS      7'h55
`define NOP       7'h70

// R2 ops
`define RTI       7'h00
`define WFI       7'h01
`define ADD       7'h04
`define CMP       7'h05
`define CMPU      7'h06
`define SUB       7'h07
`define AND       7'h08
`define OR        7'h09
`define EOR       7'h0A
`define NAND      7'h0C
`define NOR       7'h0D
`define ENOR      7'h0E

`define CSRRW     2'b00
`define CSRRS     2'b01
`define CSRRC     2'b10

// Exception vector numbers
`define ILLEGAL_INSN    9'd487
`define TSS_BAD         9'h495
`define TSS_SIZE        9'h496
`define SEG_BOUNDS      9'd500
`define SEG_PRIV        9'd501
`define SEG_TYPE        9'd502
`define SEG_NOT_PRESENT 9'd503
`define STACK_FAULT     9'd504

// Machine operating levels
`define OL_MACHINE    2'b00
`define OL_HYPERVISOR 2'b01
`define OL_SUPERVISOR 2'b10
`define OL_USER       2'b11

`define SEGSHIFT  16'h0000
`define SP        5'd31
`define BP        5'd30

`define NOPINSN   {25'h0,`NOP}
`define WFI_INSN  {`WFI,18'h0,`R2}

module dsd5(rst_i, clk_i, irq_i, ivec_i, rdy_i, vpa_o, vda_o, sel_o, rw_o, adr_o, dat_i, dat_o, irdy_i, iadr_o, idat_i);
input rst_i;
input clk_i;
input irq_i;
input [8:0] ivec_i;
input rdy_i;
output reg vpa_o;
output reg vda_o;
output reg [7:0] sel_o;
output reg rw_o;
output reg [75:0] adr_o;
input [63:0] dat_i;
output reg [63:0] dat_o;
input irdy_i;
output reg [75:0] iadr_o;
input [63:0] idat_i;

// Load / Store operation sizes
parameter byt = 2'd0;
parameter char = 2'd1;
parameter half = 2'd2;
parameter word = 2'd3;

// State machine states
parameter RUN = 8'd1;
parameter JSR1 = 8'd2;
parameter RTS1 = 8'd3;
parameter BRK1 = 8'd5;
parameter BRK2 = 8'd6;
parameter BRK3 = 8'd7;
parameter BRK4 = 8'd8;
parameter BRK5 = 8'd9;
parameter READDESC1 = 8'd14;
parameter READDESC2 = 8'd15;
parameter READDESC3 = 8'd16;
parameter READDESC4 = 8'd17;
parameter LOADSEG1 = 8'd18;
parameter LOADSEG2 = 8'd19;
parameter LOADDT1 = 8'd20;
parameter LOADDT2 = 8'd21;
parameter LOAD1 = 8'd24;
parameter LOAD2 = 8'd25;
parameter LOAD3 = 8'd26;
parameter STORE1 = 8'd27;
parameter STORE2 = 8'd28;
parameter STORE3 = 8'd29;
parameter TG0 = 8'd30;
parameter TG1 = 8'd31;
parameter TG2 = 8'd32;
parameter TG3 = 8'd33;
parameter STORE_TSS1 = 8'd36;
parameter STORE_TSS2 = 8'd37;
parameter STORE_TSS3 = 8'd38;
parameter STORE_TSS4 = 8'd39;
parameter STORE_TSS5 = 8'd40;
parameter STORE_TSS6 = 8'd41;
parameter STORE_TSS_GP1 = 8'd42;
parameter STORE_TSS_GP2 = 8'd43;
parameter STORE_TSS_GP3 = 8'd44;
parameter STORE_TSS_SG1 = 8'd48;
parameter STORE_TSS_SG2 = 8'd49;
parameter STORE_TSS_SG3 = 8'd50;
parameter STORE_TSS_SG4 = 8'd51;
parameter STORE_TSS_SG5 = 8'd52;
parameter STORE_TSS_SG6 = 8'd53;
parameter STORE_TSS_SG7 = 8'd54;
parameter STORE_TSS_SG8 = 8'd55;
parameter LOAD_TSS1 = 8'd60;
parameter LOAD_TSS2 = 8'd61;
parameter LOAD_TSS3 = 8'd62;
parameter LOAD_TSS4 = 8'd63;
parameter LOAD_TSS5 = 8'd64;
parameter LOAD_TSS6 = 8'd65;
parameter LOAD_TSS7 = 8'd66;
parameter LOAD_TSS_GP1 = 8'd67;
parameter LOAD_TSS_GP2 = 8'd68;
parameter LOAD_TSS_SG1 = 8'd71;
parameter LOAD_TSS_SG2 = 8'd72;
parameter LOAD_TSS_SG3 = 8'd73;
parameter LOAD_TSS_SG4 = 8'd74;
parameter LOAD_TSS_SG5 = 8'd75;
parameter LOAD_TSS_SG6 = 8'd76;
parameter LOAD_TSS_SG7 = 8'd77;
parameter LOAD_TSS_SG8 = 8'd78;
parameter LOAD_TSS_SG9 = 8'd79;
parameter LOAD_ICACHE = 8'd80;
parameter LOAD_ICACHE2 = 8'd81; 
parameter RTI1 = 8'h83;
parameter RTI2 = 8'h84;
parameter RTI3 = 8'h85;
parameter RTI4 = 8'h86;
parameter RTI5 = 8'h87;
parameter RTI6 = 8'h88;

reg [7:0] state, state1, state2, state3, state4;
reg [7:0] ret_state,ret2_state;
reg [1:0] ol,new_ol;              // operating level 0=machine, 1=hypervisor, 2=supervisor, 3 = user
reg [127:0] insn;
reg [63:0] pc,dpc,xpc;                // program counter
reg [31:0] cs,es,fs,gs,hs,js;
reg [31:0] dcs,xcs;               // pipeline registers for cs
wire [7:0] cpl = cs[31:24];       // current privilege level
reg [63:0] cs_base,es_base,fs_base,gs_base,hs_base,js_base,ss_base;  // segment base registers
reg [63:0] cs_limit,es_limit,fs_limit,gs_limit,hs_limit,js_limit; // segment limit registers
reg [15:0] cs_acr,es_acr,fs_acr,gs_acr,hs_acr,js_acr;
reg [31:0] ds [3:0];
reg [63:0] ds_base [3:0];
reg [63:0] ds_limit [3:0];
reg [15:0] ds_acr [3:0];
reg [31:0] ss [3:0];
reg [63:0] ss_limit [3:0];
reg [63:0] ss_llimit [3:0];
reg [15:0] ss_acr [3:0];
reg [75:0] edt_base;
reg [12:0] edt_limit;
reg [75:0] gdt_base;
reg [22:0] gdt_limit;
reg [31:0] ldt;
reg [75:0] ldt_base;
reg [22:0] ldt_limit;
reg [31:0] tr,etr;    // task register, exceptioned task register
reg [63:0] tr_base;
reg [63:0] tr_limit;
reg [15:0] tr_acr;
reg [15:0] acr;
reg [31:0] selector;
reg selectorZ;
reg [3:0] segToLoad;
reg [127:0] cmp_desc;
reg [255:0] desc;
reg taskef;
reg [8:0] vector;
reg [63:0] fault_pc;
reg [31:0] fault_cs;
reg [7:0] cpl,dpl,rpl,epl;
wire [63:0] va;                   // virtual address
reg [63:0] seg,seglmt,segllmt;
reg [127:0] ir,xir;
wire [6:0] iopcode = insn[6:0];
wire [6:0] opcode = ir[6:0];
wire [6:0] funct = ir[31:25];
reg [6:0] xopcode,xfunct;
reg [4:0] Ra;
wire [4:0] Rb = ir[16:12];
wire [4:0] Rc = ir[21:17];
reg [4:0] Rt,xRt,wRt;
reg [4:0] xRa;
reg [5:0] Rn,Rn1,Rn2;           // For storing TSS
reg [63:0] regfile [31:0];
reg [63:0] rfoa,rfob,rfoc;
reg [63:0] sp [3:0];
reg [2:0] dilen,xilen;          // length of instruction in words
reg ls_flag,ex_done;
reg [63:0] a,b,c,xb,xa,wa;
reg [75:0] imm76;
wire [63:0] imm = imm76[63:0];
reg [75:0] ea;
reg [63:0] br_disp;
reg [63:0] res,wres,lres,lres1;
wire csr_regno = xir[29:19];
reg [1:0] ld_size, st_size;
reg isok;
reg RFcnt,EXcnt,WBcnt;
reg [63:0] insncnt;
reg [63:0] rdinstret;
reg [63:0] faults;
reg [63:0] fault_bit;
reg brkIsExecuting;
reg [5:0] bitno;
reg im;                         // interrupt mask
reg nt;                         // nested task
wire [31:0] mew;                // machine event word
wire [31:0] msw;                // machine status word
assign msw[9] = im;
assign msw[14] = nt;
assign mew[14] = nt;

function fnInsnLength;
input [31:0] isn;
casex(isn[6:0])
7'h0x,7'h4x,7'h5x:
  if (isn[31:24]==8'h80)
    fnInsnLength = 2;
  else if (isn[31:24]==8'h81)
    fnInsnLength = 3;
  else
    fnInsnLength = 1;
7'h34,7'h35:
  if (isn[31:24]==8'h80)
    fnInsnLength = 2;
  else if (isn[31:24]==8'h81)
    fnInsnLength = 3;
  else
    fnInsnLength = 1;
7'h2x:
  if (isn[6:0]==`CSRI) begin
    if (isn[11:7]==5'h10)
      fnInsnLength = 2;
    else if (isn[11:7]==5'h11)
      fnInsnLength = 3;
    else
      fnInsnLength = 1;
  end
  else begin
    if (isn[16:12]==5'h10)
      fnInsnLength = 2;
    else if (isn[16:12]==5'h11)
      fnInsnLength = 3;
    else
      fnInsnLength = 1;
  end
`LDT: fnInsnLength = 3;
default:  fnInsnLength = 1;
endcase
endfunction

wire xisLd = xopcode[6:4]==3'h4;
wire xisSt = xopcode[6:4]==3'h5;

assign va = a + imm;

always @(va,cs,ds,es,fs,gs,hs,js,ol)
case(va[63:61])
3'd0: seg <= ds[ol];
3'd1: seg <= es;
3'd2: seg <= fs;
3'd3: seg <= gs;
3'd4: seg <= hs;
3'd5: seg <= js;
3'd6: seg <= cs;
3'd7: seg <= ds[ol];
endcase

always @(va,cs_limit,ds_limit,es_limit,fs_limit,gs_limit,hs_limit,js_limit,ss_limit,xRa,ol)
case(va[63:61])
3'd0:
  if (xRa==`BP || xRa==`SP) 
    seglmt <= ss_limit[ol];
  else
    seglmt <= ds_limit[ol];
3'd1: seglmt <= es_limit;
3'd2: seglmt <= fs_limit;
3'd3: seglmt <= gs_limit;
3'd4: seglmt <= hs_limit;
3'd5: seglmt <= js_limit;
3'd6: seglmt <= cs_limit;
3'd7:
  if (xRa==`BP || xRa==`SP) 
    seglmt <= ss_limit[ol];
  else
    seglmt <= ds_limit[ol];
endcase

always @(va,ss_llimit,xRa,ol)
case(va[63:61])
3'd0:
  if (xRa==`BP || xRa==`SP) 
    segllmt <= ss_llimit[ol];
  else
    segllmt <= 64'd0;
3'd1: segllmt <= 64'd0;
3'd2: segllmt <= 64'd0;
3'd3: segllmt <= 64'd0;
3'd4: segllmt <= 64'd0;
3'd5: segllmt <= 64'd0;
3'd6: segllmt <= 64'd0;
3'd7:
  if (xRa==`BP || xRa==`SP) 
    segllmt <= ss_llimit[ol];
  else
    segllmt <= 64'd0;
endcase

always @*
case(Ra)
5'd0:	rfoa <= 64'd0;
xRt:	rfoa <= res;
wRt:	rfoa <= wres;
`SP:  rfoa <= sp[ol];
default:  rfoa <= regfile[Ra];
endcase

always @*
case(Rb)
5'd0:	rfob <= 64'd0;
xRt:	rfob <= res;
wRt:	rfob <= wres;
`SP:  rfob <= sp[ol];
default:	rfob <= regfile[Rb];
endcase

always @*
case(Rc)
5'd0:	rfoc <= 64'd0;
xRt:	rfoc <= res;
wRt:	rfoc <= wres;
`SP:  rfoc <= sp[ol];
default:	rfoc <= regfile[Rc];
endcase

//---------------------------------------------------------------------------
// I-Cache
// This 128-line micro-cache is used mainly to allow access to 32,64,96,
// and 128 bit instructions while the external bus is 32 bit.
//---------------------------------------------------------------------------
wire [75:0] cspc = {cs_base,`SEGSHIFT} + pc;
wire [75:0] cspcp16 = {cs_base,`SEGSHIFT|16'h0010} + pc;
wire ihit1,ihit2;
reg [1:0] icmf;     // miss flags
reg isICacheReset;
reg isICacheLoad;
reg [127:0] cache_mem [0:127];
reg [75:11] tag_mem [0:127];
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
wire [127:0] co1 = cache_mem[cspc[10:4]];
wire [127:0] co2 = cache_mem[cspcp16[10:4]];
always @(pc or co1 or co2)
case(pc[3:2])
3'd0: insn = co1;
3'd1: insn = {co2[31:0],co1[127:32]};
3'd2: insn = {co2[63:0],co1[127:64]};
3'd3: insn = {co2[95:0],co1[127:96]};
endcase 

always @(posedge clk_i)
  if (isICacheReset)
    tag_mem[iadr_o[10:4]] <= {75-10{1'b1}};
  else begin
    if (isICacheLoad && iadr_o[3:2]==2'b11)
      tag_mem[iadr_o[10:4]] <= iadr_o[75:11];
  end
assign ihit1 = cspc[75:11]==tag_mem[cspc[10:4]];
assign ihit2 = cspcp16[75:11]==tag_mem[cspcp16[10:4]];
wire ihit = ((ihit1 && ihit2) || (ihit1 && pc[3:0]==4'h0));

//---------------------------------------------------------------------------
// A small fully associative cache for descriptors.
//---------------------------------------------------------------------------
wire [75:0] dc_adr = (selector[23] ? ldt_base : gdt_base) + {selector[22:0],4'h0};

reg [255:0] dc_mem [5:0];

wire [2:0] dc_ndx;
reg [2:0] dc_wndx;
reg [75:5] dc_tag_mem [5:0];
wire dc_hit = dc_adr[75:5]==dc_tag_mem[0] ||
              dc_adr[75:5]==dc_tag_mem[1] ||
              dc_adr[75:5]==dc_tag_mem[2] ||
              dc_adr[75:5]==dc_tag_mem[3] ||
              dc_adr[75:5]==dc_tag_mem[4] ||
              dc_adr[75:5]==dc_tag_mem[5]
              ;
assign dc_ndx[0] = dc_adr[75:5]==dc_tag_mem[1] ||
                   dc_adr[75:5]==dc_tag_mem[3] ||
                   dc_adr[75:5]==dc_tag_mem[5]
                   ;
assign dc_ndx[1] = dc_adr[75:5]==dc_tag_mem[2] ||
                   dc_adr[75:5]==dc_tag_mem[3]
                   ;
assign dc_ndx[2] = dc_adr[75:5]==dc_tag_mem[4] ||
                   dc_adr[75:5]==dc_tag_mem[5]
                   ;

//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
wire advanceEX = 1'b1;
wire advanceWB = advanceEX;
wire advanceRF = !((xisLd || xisSt)&&ex_done==1'b0);
wire advanceIF = advanceRF & ihit;

always @*
casex(xopcode)
`R2:
  case(xfunct)
  `ADD: res <= a + b;
  `CMP: res <= $signed(a) < $signed(b) ? -1 : a==b ? 0 : 1;
  `CMPU:res <= a < b ? -1 : a==b ? 0 : 1;
  `SUB: res <= a - b;
  `AND: res <= a & b;
  `OR:  res <= a | b;
  `EOR: res <= a ^ b;
  `NAND:  res <= ~(a & b);
  `NOR:   res <= ~(a | b);
  `ENOR:  res <= ~(a ^ b);
  endcase
`ADDI:  res <= a + imm;
`CMPI:  res <= $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
`CMPUI: res <= a < imm ? -1 : a==imm ? 0 : 1;
`ANDI:  res <= a & imm;
`ORI:   res <= a | imm;
`EORI:  res <= a ^ imm;
`JSR:   res <= a - 64'd8;
`RTS:   res <= a + imm + 64'd8;
`CSR,`CSRI:
  if (ol != `OL_USER)
    case(xir[29:19])
    11'h00F:  res <= sp[xir[31:30]];
    11'h010:  res <= ds[xir[31:30]];
    11'h011:  res <= es;
    11'h012:  res <= fs;
    11'h013:  res <= gs;
    11'h014:  res <= hs;
    11'h015:  res <= js;
    11'h016:  res <= cs;
    11'h017:  res <= ds[xir[31:30]];
    11'h018:  res <= ss[xir[31:30]];
    11'h019:  res <= ldt;
    default:  res <= 64'd0;
    endcase
  else
    res <= 64'd0;
`LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWR:   res <= lres;   // Loads
default:  res <= 64'd0;
endcase

always @(posedge clk_i)
if (rst_i) begin
  rdinstret <= 64'd0;
  insncnt <= 64'd0;
  dc_wndx <= 3'd0;
  cs_base <= 64'd0;
  cs_limit <= 64'hFFFFFFFFFFFFFFFF;
  pc <= 64'h0200;
  im <= `TRUE;
  taskef <= `FALSE;
  brkIsExecuting <= `FALSE;
end
else begin
case(state)
RUN:
  begin
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // IFETCH stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceIF) begin
      insncnt <= insncnt + 64'd1;
      RFcnt <= 1'b1;
      if (insn[31:0]!=`WFI_INSN || irq_i) begin
        if (irq_i && !im)
          ir <= {16'h0000,ivec_i,`BRK};
        else if (pc > cs_limit)
          ir <= {16'h0000,`SEG_BOUNDS,`BRK};
        else
          ir <= insn;
        if (iopcode==`JSR)
          Ra <= 5'd31;
        else
          Ra <= insn[11:7];
        dpc <= pc;
        pc <= pc + fnInsnLength(insn[31:0]);
        dilen <= fnInsnLength(insn[31:0]);
        dcs <= cs;
      end
    end
    else begin
      if (!ihit) begin
        icmf <= {ihit1,ihit2};
        nop_ir();
        next_state(LOAD_ICACHE);
      end
      if (advanceRF) begin
        RFcnt <= 1'b0;
        nop_ir();
        dpc <= pc;
        pc <= pc;
        dcs <= cs;
      end
    end
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
      EXcnt <= RFcnt;
      xopcode <= opcode;
      xfunct <= funct;
      xilen <= dilen;
  	  xRa <= Ra;
  	  xir <= ir;
  	  xpc <= dpc;
  	  xcs <= dcs;
      a <= rfoa;
      b <= rfob;
      c <= rfoc;
      // Set immediate value
      casex(opcode)
      7'h0x,7'h4x,7'h5x:  imm76 <= dilen==2 ? {{32{ir[63]}},ir[63:32]} : dilen==3 ? ir[95:32] : {{49{ir[31]}},ir[31:17]};
      7'h20,7'h21,7'h22,7'h23,7'h24,7'h25,7'h26,7'h27,7'h28,7'h29:
      begin
         imm76 <= dilen==2 ? {{32{ir[63]}},ir[63:32]} : dilen==3 ? ir[95:32] : {{59{Rb[4]}},Rb};
         br_disp <= {{49{ir[31]}},ir[31:17]};
      end
      `CSRI:  imm76 <= dilen==2 ? {{32{ir[63]}},ir[63:32]} : dilen==3 ? ir[95:32] : {{59{Ra[4]}},Ra};
      `JMP,`JSR:  imm76 <= dilen==2 ? {ir[63:34],2'b00} : dilen==3 ? {ir[95:34],2'b00} : {ir[31:7],1'b0};
      `LDT:   imm76 <= {ir[87:15],3'b000};
      endcase
      // Set target register
      casex(opcode)
      `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`EORI,`CSR,`CSRI:  xRt <= ir[16:12];
      `R2:  
        case(funct)
        default:  xRt <= ir[21:17];
        endcase
      `R3:    xRt <= ir[26:22];
      7'h4x:  xRt <= ir[16:12];
      `JSR:   xRt <= 5'd31;
      default:
        xRt <= 5'd0;
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
      if (xRt==5'd31) begin
        if (ex_done==`FALSE) begin
          if (res[60:0] < ss_llimit[ol] + 64'd32 || res[60:0] >= ss_limit[ol]) begin
            ex_done <= `TRUE;
            fault(`STACK_FAULT);
          end
        end
      end
      wRt <= xRt;
      wres <= res;
      WBcnt <= EXcnt;
      casex(xopcode)
      `R2:
        case(xfunct)
        `RTI:
          if (ex_done==`FALSE) begin
            ex_done <= `TRUE;
            next_state(RTI1);
          end
        endcase
      `BEQ: if (a==b) tskBranch(xpc + br_disp);
      `BNE: if (a!=b) tskBranch(xpc + br_disp);
      `BLT: if ($signed(a) < $signed(b)) tskBranch(xpc + br_disp);
      `BGE: if ($signed(a) >= $signed(b)) tskBranch(xpc + br_disp);
      `BLE: if ($signed(a) <= $signed(b)) tskBranch(xpc + br_disp);
      `BGT: if ($signed(a) > $signed(b)) tskBranch(xpc + br_disp);
      `BLTU: if (a < b) tskBranch(xpc + br_disp);
      `BGEU: if (a >= b) tskBranch(xpc + br_disp);
      `BLEU: if (a <= b) tskBranch(xpc + br_disp);
      `BGTU: if (a > b) tskBranch(xpc + br_disp);
      `BEQI: if (a==imm) tskBranch(xpc + br_disp);
      `BNEI: if (a!=imm) tskBranch(xpc + br_disp);
      `BLTI: if ($signed(a) < $signed(imm)) tskBranch(xpc + br_disp);
      `BGEI: if ($signed(a) >= $signed(imm)) tskBranch(xpc + br_disp);
      `BLEI: if ($signed(a) <= $signed(imm)) tskBranch(xpc + br_disp);
      `BGTI: if ($signed(a) > $signed(imm)) tskBranch(xpc + br_disp);
      `BLTUI: if (a < imm) tskBranch(xpc + br_disp);
      `BGEUI: if (a >= imm) tskBranch(xpc + br_disp);
      `BLEUI: if (a <= imm) tskBranch(xpc + br_disp);
      `BGTUI: if (a > imm) tskBranch(xpc + br_disp);
      `JMP: tskBranch(imm);
      `JSR:
        begin
          if (ex_done==`FALSE) begin
            ex_done <= `TRUE;
            if (a[60:0] < ss_llimit[ol] + 64'd32)
              fault(`STACK_FAULT);
            else begin
              tskBranch(imm);
              vda_o <= 1'b1;
              rw_o <= 1'b0;
              adr_o <= {ds[ol],`SEGSHIFT} + a[60:0] - 76'd8;
              dat_o <= xpc + {xilen,2'b00};
              next_state(JSR1);
            end
          end
        end
      `RTS:
        begin
          if (ex_done==`FALSE) begin
            if (res[60:0] >= ss_limit[ol])
              fault(`STACK_FAULT);
            else begin
              ex_done <= `TRUE;
              vda_o <= 1'b1;
              rw_o <= 1'b1;
              adr_o <= {ds[ol],`SEGSHIFT} + a[60:0];
              dat_o <= xpc + {xilen,2'b00};
              next_state(RTS1);
            end
          end
        end
      `BRK:
        if (ex_done==`FALSE) begin
          ex_done <= `TRUE;
          brkIsExecuting <= `TRUE;
          if (ir[16:8] > edt_limit[12:4])
            fault(`SEG_BOUNDS); // bad vector
          else begin
            fault(ir[16:8]);
          end
        end

      `LB,`LBU,`LC,`LCU,`LH,`LHU,`LW,`LWR:
        if (ex_done==`FALSE) begin
          ex_done <= `TRUE;
          if (va[60:0] < segllmt || va[60:0] > seglmt)
            fault(`SEG_BOUNDS);
          else begin
            case(xopcode)
            `LB,`LBU: ld_size = byt;
            `LC,`LCU: ld_size = char;
            `LH,`LHU: ld_size = half;
            default:  ld_size = word;
            endcase
            ea <= {seg,12'h000} + va[60:0];
            next_state(LOAD1);
          end
        end

      `SB,`SC,`SH,`SW,`SWC:
        if (ex_done==`FALSE) begin
          ex_done <= `TRUE;
          if (va[60:0] < segllmt || va[60:0] > seglmt)
            fault(`SEG_BOUNDS);
          else begin
            case(xopcode)
            `SB: st_size = byt;
            `SC: st_size = char;
            `SH: st_size = half;
            default:  st_size = word;
            endcase
            ea <= {seg,12'h000} + va[60:0];
            next_state(STORE1);
          end
        end
      `STSS:
        if (ex_done==`FALSE) begin
          ex_done <= `TRUE;
          call_state(STORE_TSS1,RUN);
        end

      `CSR:
        if (xRa!=5'd0)
          if (ex_done===`FALSE) begin
            ex_done <= `TRUE;
            case(xir[18:17])
            `CSRRW:
              begin
                segToLoad <= xir[22:19];
                case(xir[29:19])
                11'h010:  next_state(LOADSEG1);
                11'h011:  next_state(LOADSEG1);
                11'h012:  next_state(LOADSEG1);
                11'h013:  next_state(LOADSEG1);
                11'h014:  next_state(LOADSEG1);
                11'h015:  next_state(LOADSEG1);
                11'h016:  fault(`ILLEGAL_INSN);
                11'h017:  next_state(LOADSEG1);
                11'h018:  next_state(LOADSEG1);
                11'h019:  next_state(LOADSEG1);
                11'h01A:  next_state(LOADSEG1);
              endcase
              end
            endcase
          end
      `LDT:
        if (ex_done==`FALSE) begin
          ex_done <= `TRUE;
          vda_o <= `TRUE;
          adr_o <= imm76 + a;
          adr_o[2:0] <= 3'b0;
          sel_o <= 8'hFF;
          next_state(LOADDT1);
        end
      endcase
    end
  	else if (advanceWB)
      nop_wb();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Writeback stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceWB) begin
      rdinstret <= rdinstret + WBcnt;
      regfile[wRt] <= wres;
      case(wRt)
      5'd31:  sp[ol] <= wres;
      endcase
      if (wRt != 5'd0)
        $display("r%d = %h", wRt, wres);
    end // AdvanceWB
  end

JSR1:
  if (rdy_i) begin
    next_state(RUN);
  end
RTS1:
  if (rdy_i) begin
    tskBranch(dat_i);
    next_state(RUN);
  end

  // Read the compressed descriptor from the exception descriptor table.
  // We can't save the cs:pc or msw until we know which stack to save
  // it on. This depends on the operating level of the called code
  // segment. So we have to read the segment descriptor first.
BRK1:
  if (rdy_i) begin
    cmp_desc[63:0] <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(BRK2);
  end
BRK2:
  if (rdy_i) begin
    vda_o <= `FALSE;
    sel_o <= 8'h00;
    cmp_desc[127:64] <= dat_i;
    next_state(BRK3);
  end
BRK3:
  begin
    selector = cmp_desc[95:64];
    dt_access();
    if (dc_hit)
      next_state(BRK4);
    else
      call_state(READDESC1,BRK4);
  end

// Read a descriptor from the descriptor table
READDESC1:
  if (rdy_i) begin
    adr_o <= adr_o + 76'd8;
    desc[63:0] <= dat_i;
    next_state(READDESC2);
  end
READDESC2:
  if (rdy_i) begin
    adr_o <= adr_o + 76'd8;
    desc[127:64] <= dat_i;
    next_state(READDESC3);
  end
READDESC3:
  if (rdy_i) begin
    adr_o <= adr_o + 76'd8;
    desc[191:128] <= dat_i;
    next_state(READDESC4);
  end
READDESC4:
  if (rdy_i) begin
    vda_o <= `FALSE;
    sel_o <= 8'h00;
    desc[255:192] <= dat_i;
    if (dat_i[14]) begin
      dc_mem[dc_wndx] <= {dat_i,desc[191:0]};
      dc_tag_mem[dc_wndx] <= dc_adr;
      if (dc_wndx==3'd5)
        dc_wndx <= 3'd0;
      else
        dc_wndx <= dc_wndx + 1;
    end
    pop_state();
  end

BRK4:
  begin
    acr = desc[207:192];
    dpl = desc[199:192];
    if (!acr[15])     // is segment present ?
      fault(`SEG_NOT_PRESENT);
    else if (cpl > dpl)
      fault(`SEG_PRIV);
    else if (acr[12]) begin   // memory descriptor
      if (!acr[11])           // check if executable
        fault(`SEG_TYPE);
      // executable memory descriptor
      else begin
        case(cmp_desc[95:88])
        8'h00:    new_ol = `OL_MACHINE;
        8'h01:    new_ol = `OL_HYPERVISOR;
        8'h02,8'h03,8'h04,8'h05,8'h06,8'h07:
                  new_ol = `OL_SUPERVISOR;
        default:  new_ol = `OL_USER;
        endcase
        // We should not be executing user level code as a
        // result of a break instruction. The intent was to
        // trap to the OS for a system function or process
        // an interrupt.
        if (new_ol==`OL_USER)
          fault(`SEG_PRIV);
        else begin
          if (cmp_desc[123:120]==4'h5)  // task gate
            next_state(TG1);
          else begin
            ol <= new_ol;
            im <= im & cmp_desc[120];
            stack_mswcs(new_ol);
            next_state(BRK5);
          end
        end     
      end
    end
    else begin
      if (acr[11:8]==4'h01)  // task state segment ?
        next_state(TG0);
      else
        fault(`SEG_TYPE);
    end
  end

  // Save program counter on stack
  // Set new cs:pc
BRK5:
  if (rdy_i) begin
    adr_o <= adr_o - 76'd8;
    sp[ol] <= sp[ol] - 64'd8;
    dat_o <= pc;
    cs_base <= desc[63:0];
    cs_limit <= desc[127:64];
    pc <= cmp_desc[63:0];
    cs[23:0] <= cmp_desc[87:64];
    // If a conforming segment then it inherits the currrent
    // code privilege level.
    if (!desc[202]) // If non-conforming update CPL.
      cs[31:24] <= cmp_desc[95:88];
    next_state(RUN);
  end

RTI1:
  begin
    if (nt) begin
      imm76 <= 64'hFFFFFFFFFFFFFFFF;
      call_state(STORE_TSS1,RTI5);
    end
    else
      next_state(RTI2);
  end
RTI2:
  begin
    vda_o <= `TRUE;
    rw_o <= 1'b1;
    sel_o <= 8'hFF;
    adr_o <= {ds_base[ol],`SEGSHIFT} + sp[ol];
    sp[ol] <= sp[ol] + 64'd8;
    next_state(RTI3);
  end
RTI3:
  if (rdy_i) begin
    pc <= dat_i;
    adr_o <= adr_o + 64'd8;
    next_state(RTI4);
  end
RTI4:
  if (rdy_i) begin
    a <= dat_i[31:0];
    cs <= dat_i[31:0];
    // msw <= dat_i[63:32];
    im <= dat_i[41];
    nt <= dat_i[46];
    segToLoad <= 4'd6;
    call_state(LOADSEG1,RUN);
  end
RTI5:
  begin
    a <= etr;
    segToLoad <= 4'hB;
    call_state(LOADSEG1,RTI6);
  end
RTI6:
  call_state(LOAD_TSS1,RUN);

LOADSEG1:
  begin
    selector = a;
    selectorZ <= a==32'd0;
    dt_access();
    if (dc_hit || a==32'd0)
      next_state(LOADSEG2);
    else
      call_state(READDESC1,LOADSEG2);
    if (a==32'd0)
      desc <= 256'd0;
  end
LOADSEG2:
  begin
    pop_state();
    acr = desc[207:192];
    dpl = desc[199:192];
    rpl = a[31:24];
    if (!acr[15] && !selectorZ)     // is segment present ?
      fault(`SEG_NOT_PRESENT);
    else
      case(segToLoad)
      4'd9: 
        if (selectorZ) begin
          ldt <= 32'd0;
          ldt_base <= 76'd0;
          ldt_limit <= 64'd0;
        end
        else if (acr[12:8]!=5'h02)  // must be LDT type descriptor 
          fault(`SEG_TYPE);
        else begin
          if (cpl > dpl || rpl > dpl)
            fault(`SEG_PRIV);
          else begin
            ldt <= a[31:0];
            ldt_base <= {desc[63:0],`SEGSHIFT};
            ldt_limit <= desc[127:64];
          end
        end
      4'hA:
        if (selectorZ) begin
          tr <= 32'd0;
          tr_base <= 64'd0;
          tr_limit <= 64'd0;
        end
        else if (acr[12:8]!=5'h01)
          fault(`SEG_TYPE);
        else begin
          if (desc[127:64] < 32'd512)
            fault(`TSS_SIZE);
          else begin
            tr <= a[31:0];
            tr_base <= desc[63:0];
            tr_limit <= desc[127:64];
            next_state(LOAD_TSS1);
          end
        end
      4'hB:
        if (selectorZ)
          fault(`TSS_BAD);
        else if (acr[12:8]!=5'h01)
          fault(`SEG_TYPE);
        else begin
          if (desc[127:64] < 32'd512)
            fault(`TSS_SIZE);
          else begin
            tr <= a[31:0];
            tr_base <= desc[63:0];
            tr_limit <= desc[127:64];
          end
        end
      default:
        if (acr[12] || selectorZ) begin   // memory descriptor
          if ((cpl > dpl || rpl > dpl) && !selectorZ)
            fault(`SEG_PRIV);
          else begin
            isok = `TRUE;
            case(segToLoad)
            // To load into SS segment must be flagged as a stack type
            4'd8: if (!acr[10] && !selectorZ) begin fault(`SEG_TYPE); isok = `FALSE; end
            // To load into other data segments segment must be flagged as data, and non-stack
            default:  if (acr[11:10]!=2'b00) begin fault(`SEG_TYPE); isok = `FALSE; end
            endcase
            if (isok) begin
              case(segToLoad)
              4'd0: ds[xir[31:30]] <= a[31:0];
              4'd1: es <= a[31:0];
              4'd2: fs <= a[31:0];
              4'd3: gs <= a[31:0];
              4'd4: hs <= a[31:0];
              4'd5: js <= a[31:0];
              4'd6: cs <= a[31:0]; 
              4'd7: ds[xir[31:30]] <= a[31:0];
              4'd8: ss[xir[31:30]] <= a[31:0]; 
              endcase
              case(segToLoad)
              4'd0: ds_base[xir[31:30]] <= desc[63:0];
              4'd1: es_base <= desc[63:0];
              4'd2: fs_base <= desc[63:0];
              4'd3: gs_base <= desc[63:0];
              4'd4: hs_base <= desc[63:0];
              4'd5: js_base <= desc[63:0];
              4'd6: cs_base <= desc[63:0];
              4'd7: ds_base[xir[31:30]] <= desc[63:0];
              4'd8: ss_llimit[xir[31:30]] <= desc[63:0];
              endcase
              case(segToLoad)
              4'd0: ds_limit[xir[31:30]] <= desc[127:64];
              4'd1: es_limit <= desc[127:64];
              4'd2: fs_limit <= desc[127:64];
              4'd3: gs_limit <= desc[127:64];
              4'd4: hs_limit <= desc[127:64];
              4'd5: js_limit <= desc[127:64];
              4'd6: cs_limit <= desc[127:64];
              4'd7: ds_limit[xir[31:30]] <= desc[127:64];
              4'd8: ss_limit[xir[31:30]] <= desc[127:64];
              endcase
              case(segToLoad)
              4'd0: ds_acr[xir[31:30]] <= desc[207:192];
              4'd1: es_acr <= desc[207:192];
              4'd2: fs_acr <= desc[207:192];
              4'd3: gs_acr <= desc[207:192];
              4'd4: hs_acr <= desc[207:192];
              4'd5: js_acr <= desc[207:192];
              4'd6: cs_acr <= desc[207:192];
              4'd7: ds_acr[xir[31:30]] <= desc[207:192];
              4'd8: ss_acr[xir[31:30]] <= desc[207:192];
              endcase
            end
          end
        end
        else
          fault(`SEG_TYPE);
      endcase
  end

LOADDT1:
  if (rdy_i) begin
    adr_o <= adr_o + 76'd8;
    case(xir[14:12])
    3'd1: edt_base[63:0] <= {dat_i[63:4],4'b0};
    3'd2: gdt_base[63:0] <= {dat_i[63:4],4'b0};
    default:  ;
    endcase
    next_state(LOADDT2);
  end
LOADDT2:
  if (rdy_i) begin
    vda_o <= `FALSE;
    sel_o <= 8'h00;
    case(xir[14:12])
    3'd1: edt_base[75:64] <= dat_i[11:0];
    3'd2: gdt_base[75:64] <= dat_i[11:0];
    default:  ;
    endcase
    case(xir[14:12])
    3'd1: edt_limit <= dat_i[40:32];
    3'd2: gdt_limit <= dat_i[54:32];
    default:  ;
    endcase
    next_state(RUN);
  end

LOAD1:
  begin
		wb_read1(ld_size,ea);
    next_state(LOAD2);
  end
LOAD2:
  if (rdy_i) begin
    lres1 = dat_i >> {ea[2:0],3'b0};
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
        3'd7: begin wb_read2(ld_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
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
        3'd7: begin wb_read2(ld_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
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
        3'd5: begin wb_read2(ld_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(ld_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(ld_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
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
        3'd5: begin wb_read2(ld_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(ld_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(ld_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
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
        3'd1: begin wb_read2(ld_size,ea); lres[55:0] <= lres1[55:0]; next_state(LOAD3); end
        3'd2: begin wb_read2(ld_size,ea); lres[47:0] <= lres1[47:0]; next_state(LOAD3); end
        3'd3: begin wb_read2(ld_size,ea); lres[39:0] <= lres1[39:0]; next_state(LOAD3); end
        3'd4: begin wb_read2(ld_size,ea); lres[31:0] <= lres1[31:0]; next_state(LOAD3); end
        3'd5: begin wb_read2(ld_size,ea); lres[23:0] <= lres1[23:0]; next_state(LOAD3); end
        3'd6: begin wb_read2(ld_size,ea); lres[15:0] <= lres1[15:0]; next_state(LOAD3); end
        3'd7: begin wb_read2(ld_size,ea); lres[7:0] <= lres1[7:0]; next_state(LOAD3); end
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

STORE1:
	begin
		wb_write1(st_size,ea,xb);
		$display("Store to %h <= %h", ea, xb);
		next_state(STORE2);
	end
STORE2:
	if (rdy_i) begin
	  if (st_size==char && ea[2:0]==3'b111 ||
	      st_size==half && ea[2:0]>3'd4 ||
	      st_size==word && ea[2:0]!=3'b000) begin
  		wb_write2(st_size,ea,xb);
			next_state(STORE3);
	  end
		else begin
		  vda_o <= `FALSE;
		  rw_o <= 1'b1;
		  sel_o <= 8'h00;
			next_state(RUN);
		end
	end
STORE3:
	if (rdy_i) begin
    vda_o <= `FALSE;
    rw_o <= 1'b1;
    sel_o <= 8'h00;
		next_state(RUN);
	end

// Called from a BRK ? Set the nt bit.
TG0:  begin
        nt <= `TRUE;
        etr <= tr;
        imm76 <= 64'hFFFFFFFFFFFFFFFF;
        call_state(STORE_TSS1,TG2);
      end
// Otherwise a JMP or JSR instruction
TG1:
  begin
    imm76 <= 64'hFFFFFFFFFFFFFFFF;
    call_state(STORE_TSS1,TG2);
  end
TG2:
  begin
    a <= cmp_desc[95:64];
    segToLoad <= 4'hB;
    call_state(LOADSEG1,TG3);
  end
TG3:  call_state(LOAD_TSS1,RUN);

STORE_TSS1:
  begin
    bitno = 6'd0;
    Rn <= 6'd1;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    dat_o <= xpc + 64'd16;  // store address of 2nd following instruction
    adr_o <= {tr_base,`SEGSHIFT};
    next_state(STORE_TSS2);
  end
STORE_TSS2:
  if (rdy_i) begin
    bitno = 6'd1;
    Rn1 = Rn + 6'd1;
    Rn2 = Rn + 6'd2;
    ir <= {5'd0,Rn2[4:0],Rn1[4:0],Rn[4:0],`R3}; 
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= msw;
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS3);
  end
STORE_TSS3:
  if (rdy_i) begin
    bitno = 6'd2;
    a <= rfoa;
    b <= rfob;
    c <= rfoc;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= sp[0];
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS4);
  end
STORE_TSS4:
  if (rdy_i) begin
    bitno = 6'd3;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= sp[1];
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS5);
  end
STORE_TSS5:
  if (rdy_i) begin
    bitno = 6'd4;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= sp[2];
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS6);
  end
STORE_TSS6:
  if (rdy_i) begin
    bitno = 6'd5;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= sp[3];
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_GP1);
  end
STORE_TSS_GP1:
  if (rdy_i) begin
    bitno = 6'd5 + Rn;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= a;
    adr_o <= adr_o + 76'd8;
    Rn1 = Rn + 6'd1;
    Rn2 = Rn + 6'd2;
    ir <= {5'd0,Rn2[4:0],Rn1[4:0],Rn[4:0],`R3}; 
    next_state(STORE_TSS_GP2);
  end
STORE_TSS_GP2:
  if (rdy_i) begin
    bitno = 6'd6 + Rn;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= b;
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_GP3);
  end
STORE_TSS_GP3:
  if (rdy_i) begin
    bitno = 6'd7 + Rn;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= c;
    adr_o <= adr_o + 76'd8;
    a <= rfoa;
    b <= rfob;
    c <= rfoc;
    if (Rn >= 6'd28)
      next_state(STORE_TSS_SG1);
    else
      next_state(STORE_TSS_GP1);
    Rn <= Rn + 6'd3;
  end
STORE_TSS_SG1:
  if (rdy_i) begin
    bitno = 6'd36;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {ds[1],ds[0]};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG2);
  end
STORE_TSS_SG2:
  if (rdy_i) begin
    bitno = 6'd37;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {ds[3],ds[2]};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG3);
  end
STORE_TSS_SG3:
  if (rdy_i) begin
    bitno = 6'd38;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {ss[1],ss[0]};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG4);
  end
STORE_TSS_SG4:
  if (rdy_i) begin
    bitno = 6'd39;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {ss[3],ss[2]};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG5);
  end
STORE_TSS_SG5:
  if (rdy_i) begin
    bitno = 6'd40;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {fs,es};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG6);
  end
STORE_TSS_SG6:
  if (rdy_i) begin
    bitno = 6'd41;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {hs,gs};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG7);
  end
STORE_TSS_SG7:
  if (rdy_i) begin
    bitno = 6'd42;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= {cs,js};
    adr_o <= adr_o + 76'd8;
    next_state(STORE_TSS_SG8);
  end
STORE_TSS_SG8:
  if (rdy_i) begin
    bitno = 6'd43;
    if (imm[bitno]) begin
      vda_o <= `TRUE;
      rw_o <= 1'b0;
    end
    else begin
      vda_o <= `FALSE;
      rw_o <= 1'b1;
    end
    dat_o <= ldt;
    adr_o <= adr_o + 76'd8;
    pop_state();
  end

LOAD_TSS1:
  begin
    vda_o <= 1'b1;
    rw_o <= 1'b1;
    adr_o <= {tr_base,`SEGSHIFT};
    next_state(LOAD_TSS2);
  end
LOAD_TSS2:
  if (rdy_i) begin
    Rn <= 6'd1;
    pc <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS3);
  end
LOAD_TSS3:
  if (rdy_i) begin
    //msw <= dat_i;
    im <= dat_i[41];
    nt <= dat_i[49];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS4);
  end
LOAD_TSS4:
  if (rdy_i) begin
    sp[0] <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS5);
  end
LOAD_TSS5:
  if (rdy_i) begin
    sp[1] <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS6);
  end
LOAD_TSS6:
  if (rdy_i) begin
    sp[2] <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS7);
  end
LOAD_TSS7:
  if (rdy_i) begin
    sp[3] <= dat_i;
    adr_o <= adr_o + 76'd8;
    wRt <= 5'd1;
    next_state(LOAD_TSS_GP1);
  end
LOAD_TSS_GP1:
  if (rdy_i) begin
    wres <= dat_i;
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_GP2);
  end
LOAD_TSS_GP2:
  if (rdy_i) begin
    regfile[wRt] <= wres;
    wRt <= wRt + 5'd1;
    if (wRt==5'd30)
      next_state(LOAD_TSS_SG1);
    else
      next_state(LOAD_TSS_GP1);
  end
LOAD_TSS_SG1:
  if (rdy_i) begin
    ds[0] <= dat_i[31:0];
    ds[1] <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG2);
  end
LOAD_TSS_SG2:
  if (rdy_i) begin
    ds[2] <= dat_i[31:0];
    ds[3] <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG3);
  end
LOAD_TSS_SG3:
  if (rdy_i) begin
    ss[0] <= dat_i[31:0];
    ss[1] <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG4);
  end
LOAD_TSS_SG4:
  if (rdy_i) begin
    ss[2] <= dat_i[31:0];
    ss[3] <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG5);
  end
LOAD_TSS_SG5:
  if (rdy_i) begin
    es <= dat_i[31:0];
    fs <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG6);
  end
LOAD_TSS_SG6:
  if (rdy_i) begin
    gs <= dat_i[31:0];
    hs <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG7);
  end
LOAD_TSS_SG7:
  if (rdy_i) begin
    js <= dat_i[31:0];
    cs <= dat_i[63:32];
    adr_o <= adr_o + 76'd8;
    next_state(LOAD_TSS_SG8);
  end
LOAD_TSS_SG8:
  if (rdy_i) begin
    vda_o <= `FALSE;
    sel_o <= 8'h00;
    ldt <= dat_i[31:0];
    Rn <= 6'd0;
    next_state(LOAD_TSS_SG9);
  end
LOAD_TSS_SG9:
  begin
    taskef <= `TRUE;
    case(Rn)
    6'd0: begin a <= ds[0]; xir[31:30] <= 2'b00; segToLoad <= 4'h0; end
    6'd1: begin a <= ds[1]; xir[31:30] <= 2'b01; segToLoad <= 4'h0; end
    6'd2: begin a <= ds[2]; xir[31:30] <= 2'b10; segToLoad <= 4'h0; end
    6'd3: begin a <= ds[3]; xir[31:30] <= 2'b11; segToLoad <= 4'h0; end
    6'd4: begin a <= ss[0]; xir[31:30] <= 2'b00; segToLoad <= 4'h8; end
    6'd5: begin a <= ss[1]; xir[31:30] <= 2'b01; segToLoad <= 4'h8; end
    6'd6: begin a <= ss[2]; xir[31:30] <= 2'b10; segToLoad <= 4'h8; end
    6'd7: begin a <= ss[3]; xir[31:30] <= 2'b11; segToLoad <= 4'h8; end
    6'd8: begin a <= es; xir[31:30] <= 2'b00; segToLoad <= 4'h1; end
    6'd9: begin a <= fs; xir[31:30] <= 2'b00; segToLoad <= 4'h2; end
    6'd10:  begin a <= gs; xir[31:30] <= 2'b00; segToLoad <= 4'h3; end
    6'd11:  begin a <= hs; xir[31:30] <= 2'b00; segToLoad <= 4'h4; end
    6'd12:  begin a <= js; xir[31:30] <= 2'b00; segToLoad <= 4'h5; end
    6'd13:  begin a <= cs; xir[31:30] <= 2'b00; segToLoad <= 4'h6; end
    6'd14:  begin a <= ldt; xir[31:30] <= 2'b00; segToLoad <= 4'h9; taskef <= `FALSE; end
    endcase
    Rn <= Rn + 6'd1;
    next_state(LOADSEG1);
  end

LOAD_ICACHE:
  begin
    if (icmf != 2'b11) begin
      isICacheLoad <= `TRUE;
      if (icmf[1]) begin
        iadr_o <= {cspcp16[75:4],4'h0};
        icmf[0] <= 1'b1;
      end
      else begin
        icmf[1] <= 1'b1;
        iadr_o <= {cspc[75:4],4'h0};
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

task stack_mswcs;
input [1:0] lvl;
begin
  vda_o <= `TRUE;
  rw_o <= 1'b0;
  sel_o <= 8'hFF;
  adr_o <= {ds[lvl],`SEGSHIFT} + sp[lvl] - 76'd8;
  dat_o <= {msw,cs};
  sp[lvl] <= sp[lvl] - 64'd8;
end
endtask

task fault;
input [8:0] vec;
begin
  vector <= vec;
  fault_pc <= pc;
  fault_cs <= cs;
  vda_o <= `TRUE;
  rw_o <= 1'b1;
  adr_o <= edt_base + {vec,4'h0};
  next_state(BRK1);
end
endtask

task dt_access;
begin
  if (selector[23]) begin // read from ldt
    if (selector[22:0] > ldt_limit)
      fault(`SEG_BOUNDS);
    else begin
      if (dc_hit)
        desc <= dc_mem[dc_ndx];
      else begin
        vda_o <= `TRUE;
        sel_o <= 8'hFF;
        adr_o <= dc_adr;
      end
    end
  end
  else begin  // read from gdt
    if (selector[22:0] > gdt_limit)
      fault(`SEG_BOUNDS);
    else begin
      if (dc_hit)
        desc <= dc_mem[dc_ndx];
      else begin
        vda_o <= `TRUE;
        sel_o <= 8'hFF;
        adr_o <= dc_adr;
      end
    end
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
	rw_o <= 1'b0;
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
  rw_o <= 1'b0;
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
end
endtask

task nop_xir;
begin
  xir[6:0] <= `NOP;
  xopcode <= `NOP;
  xRt <= 5'd0;
end
endtask

task nop_wb;
begin
  WBcnt <= 1'b0;
  wRt <= 5'd0;
  wres <= 64'd0;
end
endtask

task tskBranch;
input [63:0] newpc;
begin
  pc <= newpc;
  pc[1:0] <= 2'b0;
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
