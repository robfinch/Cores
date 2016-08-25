// ============================================================================
// (C) 2016 Robert Finch
// rob<remove>@finitron.ca
// All Rights Reserved.
//
//	DSD4.v
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
//
`define TRUE  1'b1
`define FALSE 1'b0
`define LOW   1'b0
`define HIGH  1'b1

`define BRK   5'h00
`define NOP   5'h01
`define RR    5'h02
`define NOT     5'h00
`define NEG     5'h01
`define COM     5'h02
`define MOVR    5'h03
`define ADD     5'h04
`define SUB     5'h05
`define CMP     5'h06
`define AND     5'h08
`define OR      5'h09
`define EOR     5'h0A
`define ANDC    5'h0B
`define NAND    5'h0C
`define NOR     5'h0D
`define ENOR    5'h0E
`define ORC     5'h0F
`define JMPR    5'h10
`define JSRR    5'h11
`define RTS     5'h12
`define RTI     5'h13
`define SHLI    5'h14
`define SHRI    5'h15
`define SHL     5'h16
`define SHR     5'h17
`define ASRI    5'h18
`define ASR     5'h19
`define MTSPR   5'h1A
`define MFSPR   5'h1B
`define DBG     5'h1C
`define SEG     5'h1D
`define EXS     5'h1E
`define EXL     5'h1F
`define Bcc   5'h03
`define BRA     5'h00
`define BSR     5'h01
`define BHI     5'h02
`define BLS     5'h03
`define BHS     5'h04
`define BLO     5'h05
`define BNE     5'h06
`define BEQ     5'h07
`define BVC     5'h08
`define BVS     5'h09
`define BPL     5'h0A
`define BMI     5'h0B
`define BGE     5'h0C
`define BLT     5'h0D
`define BGT     5'h0E
`define BLE     5'h0F
`define BEV     5'h10
`define BOD     5'h11
`define BPO     5'h12
`define BRZ     5'h18
`define BNZ     5'h19
`define BRP     5'h1A
`define BRN     5'h1B
`define BXC     5'h1C
`define BXS     5'h1D
`define BRC     5'h1E
`define BRS     5'h1F

`define ADDI  5'h04
`define CMPI  5'h06
`define ANDI  5'h08
`define ORI   5'h09
`define EORI  5'h0A
`define JMP   5'h10
`define JSR   5'h11
`define JMPF  5'h14
`define LD    5'h1C
`define LDAR  5'h1D
`define ST    5'h1E
`define STCR  5'h1F

`define BOUNDS        9'd487
`define PRIV          9'd501
`define STACK_FAULT   9'd504

module DSDS4(clk,rst,sig,irq,ivec,vpa,vda, rw, ad, sr, cr, rv, dat_i, dat_o);
input clk;
input rst;
input sig;
input irq;
input [8:0] ivec;
output reg vpa;   // valid program address
output reg vda;   // valid data address
output reg rw;
output reg [43:0] ad;
output reg sr;    // set reservation
output reg cr;    // clear reservation
input rv;         // reservation value
input [31:0] dat_i;
output reg [31:0] dat_o;

parameter SEGSHIFT  = 12'h000;
parameter STACK_MARGIN = 4;

// Machine states
parameter IFETCH = 1;
parameter DECODE = 2;
parameter REGFETCHB = 3;
parameter FETCHIMM1 = 4;
parameter FETCHIMM2 = 5;
parameter EXECUTE = 6;
parameter MEMORY = 7;
parameter WRITEBACK = 8;
parameter JMPF1 = 9;
parameter JMPF2 = 10;
parameter JMPF3 = 11;
parameter JMP1 = 12;
parameter BRK1 = 13;
parameter BRK2 = 14;
parameter BRK3 = 15;
parameter BRK4 = 16;
parameter RTS1 = 17;
parameter RTI1 = 18; 
parameter RTI2 = 19; 
parameter RTI3 = 20; 
parameter RTI4 = 21; 
parameter RTI5 = 22; 
parameter DBG1 = 23;
parameter DBG2 = 24;
parameter DBG3 = 25;
parameter DBG4 = 26;

reg [4:0] state;
reg gie;      // global interrupt enable
reg im;       // irq interrupt mask
reg hwi;
reg [31:0] ir;
reg [31:0] vcs;
reg [26:0] vcsl;        // vector code segment limit
reg [15:0] vba;         // vector table base address
reg [31:0] orig_cs;
reg [26:0] orig_pc;
reg [31:0] cs [3:0];    // code segment
reg [26:0] csl [3:0];   // code segment limit
reg [31:0] next_cs;     // temp hold for new cs
reg [26:0] next_csl;
reg [26:0] pc;
reg [31:0] ds [3:0];    // data segment
reg [31:0] dsl [3:0];   // data segment limit
reg [31:0] es [3:0];
reg [31:0] esl [3:0];
reg [31:0] fs [3:0];    // thread local data
reg [31:0] fsl [3:0];
reg [31:0] gs [3:0];    // global data
reg [31:0] gsl [3:0];
reg [31:0] ssl [3:0];   // lower stack bound
reg [31:0] ssu [3:0];   // upper stack bound
reg [31:0] x;           // x index register
wire [4:0] opcode = ir[4:0];
wire [4:0] cond = ir[14:10];
wire [4:0] func = ir[31:27];
wire [4:0] Ra = ir[9:5];
wire [4:0] Rb = ir[14:10];
reg [1:0] regset,oregset, rs;
reg [31:0] regs [127:0];
reg [31:0] ssp,usp1,dsp,usp2;
reg [3:0] zf,nf,vf,cf,of;
reg rf;
reg [31:0] next_msw;
wire [31:0] msw = {regset,nf[regset],vf[regset],1'b0,rf,of[regset],im,zf[regset],cf[regset]};
reg [6:0] Rt; 
reg [31:0] a,b,imm;   // operands
reg [31:0] res;
reg takb;
reg stack_fault;
reg [26:0] fault_pc;
reg [31:0] fault_cs;
reg [31:0] fault_addr;
reg [3:0]  fault_seg;
reg [31:0] aseg;
reg [28:0] almt;
reg boundsOK;

function fnSp;
input [1:0] rs;
case(rs)
2'd0: fnSp = usp1;
2'd1: fnSp = usp2;
2'd2: fnSp = ssp;
2'd3: fnSp = dsp;
endcase
endfunction

always @(cond or cf or zf or nf or vf or of or rf or sig or a)
  case(cond)
  `BRA:  takb = 1'b1;
  `BSR:  takb = 1'b1;
  `BHI:  takb = !cf[regset] & !zf[regset];
  `BLS:  takb = cf[regset] | zf[regset];
  `BHS:  takb = !cf[regset];
  `BLO:  takb =  cf[regset];
  `BNE:  takb = !zf[regset];
  `BEQ:  takb =  zf[regset];
  `BVC:  takb = !vf[regset];
  `BVS:  takb =  vf[regset];
  `BPL:  takb = !nf[regset];
  `BMI:  takb =  nf[regset];
  `BGE:  takb = (nf[regset] & vf[regset])|(!nf[regset] & !vf[regset]);
  `BLT:  takb = (nf[regset] & !vf[regset])|(!nf[regset] & vf[regset]);
  `BGT:  takb = (nf[regset] & vf[regset] & !zf[regset])|(!nf[regset] & !vf[regset] & zf[regset]);
  `BLE:  takb = zf[regset] | (nf[regset] & !vf[regset]) | (!nf[regset] & vf[regset]);
  `BRZ:  takb = ~|a;
  `BNZ:  takb =  |a;
  `BRP:  takb = !a[31];
  `BRN:  takb =  a[31];
  `BEV:  takb = !of[regset];
  `BOD:  takb =  of[regset];
  `BXC:  takb = !sig;
  `BXS:  takb =  sig;
  `BPO:  takb = !nf[regset] & !zf[regset];
  `BRC:  takb = !rf;
  `BRS:  takb =  rf;
  default:  takb = 1'b1;
  endcase

always @*
begin
  case(opcode)
  `RR:
    case(func)
    `NOT: res <= !a;
    `NEG: res <= -a;
    `COM: res <= ~a;
    `MOVR:  res <= a;
    `ADD: res <= a + b;
    `SUB: res <= a - b;
    `CMP: res <= a - b;
    `AND: res <= a & b;
    `OR:  res <= a | b;
    `EOR: res <= a ^ b;
    `ANDC:  res <= a & ~b;
    `NAND: res <= ~(a & b);
    `NOR:  res <= ~(a | b);
    `ENOR: res <= ~(a ^ b);
    `ORC: res <= a | ~b;
    `SHL: res <= a << b;
    `SHR: res <= a >> b;
    `SHLI: res <= a << b;
    `SHRI: res <= a >> b;
    `ASR:  res <= a[31] ? (a >> b) | ~(32'hFFFFFFFF >> b) : a >> b;
    `ASRI: res <= a[31] ? (a >> b) | ~(32'hFFFFFFFF >> b) : a >> b;
    `RTI: res <= a;
    `MFSPR:
      case(ir[26:20])
      7'd00:  res <= 32'd0;
      7'h02:  res <= vcs;
      7'h03:  res <= msw;
      7'h08,7'h09,7'h0A,7'h0B:  res <= ds[b[1:0]];
      7'h0C:  res <= dsl[b[1:0]]; 
      7'h0D:  res <= dsl[b[1:0]]; 
      7'h0E:  res <= dsl[b[1:0]]; 
      7'h0F:  res <= dsl[b[1:0]]; 
      7'h10:  res <= ssl[b[1:0]];
      7'h11:  res <= ssl[b[1:0]];
      7'h12:  res <= ssl[b[1:0]];
      7'h13:  res <= ssl[b[1:0]];
      7'h14:  res <= ssu[b[1:0]];
      7'h15:  res <= ssu[b[1:0]];
      7'h16:  res <= ssu[b[1:0]];
      7'h17:  res <= ssu[b[1:0]];
      7'h18:  res <= usp1;
      7'h19:  res <= usp2;
      7'h1A:  res <= ssp;
      7'h1B:  res <= dsp;
      7'h20:  res <= cs[b[1:0]];
      7'h21:  res <= cs[b[1:0]];
      7'h22:  res <= cs[b[1:0]];
      7'h23:  res <= cs[b[1:0]];
      7'h24:  res <= csl[b[1:0]];
      7'h25:  res <= csl[b[1:0]];
      7'h26:  res <= csl[b[1:0]];
      7'h27:  res <= csl[b[1:0]];
      7'h28:  res <= es[b[1:0]];
      7'h29:  res <= es[b[1:0]];
      7'h2A:  res <= es[b[1:0]];
      7'h2B:  res <= es[b[1:0]];
      7'h2C:  res <= esl[b[1:0]];
      7'h2D:  res <= esl[b[1:0]];
      7'h2E:  res <= esl[b[1:0]];
      7'h2F:  res <= esl[b[1:0]];
      7'h30:  res <= fs[b[1:0]];
      7'h31:  res <= fs[b[1:0]];
      7'h32:  res <= fs[b[1:0]];
      7'h33:  res <= fs[b[1:0]];
      7'h34:  res <= fsl[b[1:0]];
      7'h35:  res <= fsl[b[1:0]];
      7'h36:  res <= fsl[b[1:0]];
      7'h37:  res <= fsl[b[1:0]];
      7'h38:  res <= gs[b[1:0]];
      7'h39:  res <= gs[b[1:0]];
      7'h3A:  res <= gs[b[1:0]];
      7'h3B:  res <= gs[b[1:0]];
      7'h3C:  res <= gsl[b[1:0]];
      7'h3D:  res <= gsl[b[1:0]];
      7'h3E:  res <= gsl[b[1:0]];
      7'h3F:  res <= gsl[b[1:0]];
      7'h40:  res <= ds[regset];
      7'h41:  res <= dsl[regset];
      7'h42:  res <= cs[regset];
      7'h43:  res <= csl[regset];
      7'h44:  res <= es[regset];
      7'h45:  res <= esl[regset];
      7'h46:  res <= fs[regset];
      7'h47:  res <= fsl[regset];
      7'h48:  res <= gs[regset];
      7'h49:  res <= gsl[regset];
      7'h4A:  res <= ssl[regset];
      7'h4B:  res <= ssu[regset];
      7'h50:  res <= fault_pc;
      7'h51:  res <= fault_cs;
      7'h52:  res <= fault_addr;
      7'h53:  res <= fault_seg;
      endcase
    `SEG: res <= {ir[12:10],a[29:0]};
    `EXS:
      case(a[31:29])
      3'd0: res <= ds[b[1:0]];
      3'd1: res <= es[b[1:0]]; 
      3'd2: res <= fs[b[1:0]]; 
      3'd3: res <= gs[b[1:0]]; 
      3'd4: res <= cs[b[1:0]];
      3'd7: res <= ds[b[1:0]];
      default:  res <= 32'd0; 
      endcase
    `EXL:
      case(a[31:29])
      3'd0: res <= dsl[b[1:0]];
      3'd1: res <= esl[b[1:0]]; 
      3'd2: res <= fsl[b[1:0]]; 
      3'd3: res <= gsl[b[1:0]]; 
      3'd4: res <= csl[b[1:0]];
      3'd7: res <= dsl[b[1:0]];
      default:  res <= 32'd0; 
      endcase
    endcase
  `ADDI:  res <= a + b;
  `CMPI:  res <= a - b;
  `ANDI:  res <= a & b;
  `ORI:   res <= a | b;
  `EORI:  res <= a ^ b;
  `LD,`LDAR:  res <= a;
  endcase
end

// Data is latched on the falling edge of the clock.
always @(negedge clk)
if (rst) begin
  vcs <= 32'hFFFFFFFF;
  ir <= {9'h1FF,`BRK};
  gie <= `FALSE;
  im <= `TRUE;
  regset <= 3'd2;
  ssp <= 32'h0100;
  ssu[2] <= 32'h0100;
  ssl[2] <= 32'h0000;
  ds[2] <= 32'h00000000;
  dsl[2] <= 32'hFFFFFFFF;
  stack_fault <= `FALSE;
  state <= BRK4;
end
else begin
  vpa <= `LOW;
  vda <= `LOW;
  sr <= `LOW;
  cr <= `LOW;
  rw <= `HIGH;
  case(state)

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Bounds checking of the PC is only performed at IFETCH time.
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Update the register file
  // Check for stack overflow and underflow if updating a stack pointer.
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  IFETCH,WRITEBACK:
    begin
      orig_pc <= pc;
      orig_cs <= csl[regset];
      if (gie && irq && !im) begin
        hwi <= `TRUE;
        ir <= {ivec,`BRK};
        state <= DECODE;
      end
      else if (pc > csl[regset]) begin
        fault_pc <= pc;
        fault_cs <= csl[regset];
        fault_addr <= pc;
        fault_seg <= 4'd4;
        ir <= {`BOUNDS,`BRK};
        state <= DECODE;
      end
      else begin
        ir <= dat_i;
        state <= DECODE;
      end
      // Writeback
      regs[Rt] <= res;
      if (Rt[4:0]==5'd31) begin
        case(regset)
        2'd0: usp1 <= res;
        2'd1: usp2 <= res;
        2'd2: ssp <= res;
        2'd3: dsp <= res;
        endcase
      end
      // Writeback flags
      case(opcode)
      `RR:
        case(func)
        `NOT: SetNZO();
        `COM: SetNZO();
        `NEG: SetCVNZO(0);
        `ADD: SetCVNZO(1);
        `SUB: SetCVNZO(0);
        `CMP: SetCVNZO(0);
        `AND: SetNZO();
        `OR: SetNZO();
        `EOR: SetNZO();
        `ANDC:  SetNZO();
        `NAND: SetNZO();
        `NOR: SetNZO();
        `ENOR: SetNZO();
        `ORC: SetNZO();
        `SHLI:  SetNZO();
        `SHL:  SetNZO();
        `SHRI:  SetNZO();
        `SHR:  SetNZO();
        `ASRI:  SetNZO();
        `ASR: SetNZO();
        default ;
        endcase
      `ADDI:  SetCVNZO(1);
      `CMPI:  SetCVNZO(0);
      `ANDI,`ORI,`EORI:  SetNZO();
      `LD,`LDAR:  SetNZO();
      default:  ;
      endcase
    end

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  DECODE:
    begin
      state <= REGFETCHB;
      Rt <= {regset,ir[14:10]};
      regfetch(3'd7,Ra,a);
      case(opcode)
      `BRK:
        begin
          Rt <= 7'd0;
          vda <= `HIGH;
          dat_o <= csl[regset];
          ad <= {ds[2],SEGSHIFT} + ssp - 32'd1;
          rw <= `LOW;
          ssp <= ssp - 32'd1;
          state <= BRK1;
        end
      `NOP:
        begin
          Rt <= 7'd0; 
          go_ifetch();
        end
      `RR:
        begin
          Rt <= {regset,ir[19:15]};
          case(func)
          `DBG:
              begin
                Rt <= 7'd0;
                vda <= `HIGH;
                dat_o <= csl[regset];
                ad <= {ds[3],SEGSHIFT} + dsp - 32'd1;
                rw <= `LOW;
                dsp <= dsp - 32'd1;
                state <= DBG1;
              end
          // No need for another register fetch here
          `MOVR:
            begin
              case(ir[22:20])
              3'd0: Rt <= ir[21:15];
              3'd1: Rt <= ir[21:15];
              3'd2: Rt <= ir[21:15];
              3'd3: Rt <= ir[21:15];
              3'd7: Rt <= {regset,ir[19:15]};
              default:  Rt <= {regset,ir[19:15]};
              endcase
              regfetch(ir[12:10],Ra,a);
              state <= EXECUTE;
            end
          `NOT,`NEG,`COM,`MOVR,`SEG: state <= EXECUTE;
          `ADD,`SUB,`CMP,`AND,`OR,`EOR,`NAND,`NOR,`ENOR,
          `JMPR,`JSRR,`SHL,`SHR,`ASR,
          `EXS,`EXL:
            state <= REGFETCHB;
          `MFSPR:
            if (!regset[1])
              setfault(`PRIV,pc,4'd4);
            else begin 
              b <= ir[21:20];
              state <= EXECUTE;
            end
          `SHLI,`SHRI:
            begin
              b <= ir[14:10];
              state <= EXECUTE;
            end
          `RTS:
            begin
              Rt <= 7'd0;
              if (fnSp(regset) < ssu[regset]) begin
                vda <= `HIGH;
                ad <= {ds[regset],SEGSHIFT} + fnSp(regset);
                incsp();
                state <= RTS1;
              end
              else begin
                setfault(`STACK_FAULT,fnSp(regset),4'd8);
              end
            end
          `RTI:
            begin
              state <= RTI1;
              regfetch(3'd7,Ra,a);
              vda <= `HIGH;
              case(regset)
              2'd2:
                begin
                  ad <= {ds[2],SEGSHIFT} + ssp;
                  ssp <= ssp + 32'd1;
                end
              2'd3:
                begin
                  ad <= {ds[3],SEGSHIFT} + dsp;
                  dsp <= dsp + 32'd1;
                end
              default:
                begin
                  setfault(`PRIV,dsp,4'd0);
                end
              endcase
            end
          endcase
        end
      `ADDI,`CMPI,`ANDI,`ORI,`EORI,`LD,`LDAR,`ST,`STCR:
        if (ir[31:26]==6'h20)
          state <= FETCHIMM1;
        else begin
          b <= {{15{ir[31]}},ir[31:15]};
          state <= EXECUTE;
        end
      `Bcc:
        begin
          Rt <= 7'd0;
          if (cond==`BSR) begin
            vda <= `HIGH;
            rw <= `LOW;
            ad <= {ds[regset],SEGSHIFT} + fnSp(regset) - 32'd1;
            dat_o <= pc;
            decsp();
          end
          if (takb) begin
            pc <= pc + {{10{ir[31]}},ir[31:15]};
            state <= JMP1;
          end
          else
            go_ifetch();
        end
      `JMP:
        begin
          Rt <= 7'd0;
          pc <= ir[31:5];
          state <= JMP1;
        end
      // Far jumps only allowed in supervisor mode
      `JMPF:
        begin
          Rt <= 7'd0;
          if (regset[1]) begin
            vpa <= `HIGH;
            ad <= {cs[regset],SEGSHIFT} + pc;
            pc <= pc + 32'd1;
            state <= JMPF1;
          end
          else begin
            setfault(`PRIV,pc,4'd4);
          end
        end
      `JSR:
        begin
          if (fnSp(regset) < ssl[regset] + STACK_MARGIN)
            setfault(`STACK_FAULT,fnSp(regset),4'd8);
          else begin
            Rt <= 7'd0;
            vda <= `HIGH;
            rw <= `LOW;
            ad <= {ds[regset],SEGSHIFT} + fnSp(regset) - 32'd1;
            dat_o <= pc;
            decsp();
            pc <= ir[31:5];
            state <= JMP1;
          end
        end
      default:
        begin
          Rt <= 7'd0;
          state <= IFETCH;
        end
      endcase
    end

  // Fetch a 32 bit immediate value 
  FETCHIMM1:
    begin
      vpa <= `HIGH;
      ad <= {cs[regset],SEGSHIFT} + pc;
      pc <= pc + 32'd1;
      state <= FETCHIMM2;
    end
  FETCHIMM2:
    begin
      b <= dat_i;
      state <= EXECUTE;
    end

  // Fetch the second register from the file
  REGFETCHB:
    begin
      regfetch(3'd7,Rb,b);
      state <= EXECUTE;
    end

  EXECUTE:
    begin
      case(opcode)
      `RR:
        case(func)
        `JMPR:
          begin
            Rt <= 7'd0;  
            pc <= a;
            state <= JMP1;
          end
        `JSRR:
          begin
            if (fnSp(regset) < ssl[regset] + STACK_MARGIN)
              setfault(`STACK_FAULT,fnSp(regset),4'd8);
            else begin
              Rt <= 7'd0;
              vda <= `HIGH;
              rw <= `LOW;
              ad <= {ds[regset],SEGSHIFT} + fnSp(regset) - 32'd1;
              dat_o <= pc;
              decsp();
              pc <= a;
              state <= JMP1;
            end
          end
        `MTSPR:
          if (!regset[1])
            setfault(`PRIV,pc,4'd4);
          else begin
            case(ir[26:20])
            7'h00:  ;
            7'h01:  ;
            7'h02:  vcs <= a;
            7'h03:
              begin
                cf[a[9:8]] <= a[0];
                zf[a[9:8]] <= a[1];
                im <= a[2];
                of[a[9:8]] <= a[3];
                rf <= a[4];
                vf[a[9:8]] <= a[6];
                nf[a[9:8]] <= a[7];
                regset <= a[9:8];
              end
            7'h04:  ;
            7'h05:  ;
            7'h08:  ds[0] <= a;
            7'h09:  ds[1] <= a;
            7'h0A:  ds[2] <= a;
            7'h0B:  ds[3] <= a;
            7'h0C:  dsl[0] <= a;
            7'h0D:  dsl[1] <= a;
            7'h0E:  dsl[2] <= a;
            7'h0F:  dsl[3] <= a;
            7'h10:  ssl[0] <= a;
            7'h11:  ssl[1] <= a;
            7'h12:  ssl[2] <= a;
            7'h13:  ssl[3] <= a;
            7'h14:  ssu[0] <= a;
            7'h15:  ssu[1] <= a;
            7'h16:  ssu[2] <= a;
            7'h17:  ssu[3] <= a;
            7'h18:  usp1 <= a;
            7'h19:  usp2 <= a;
            7'h1A:  begin
                    ssp <= a;
                    gie <= `TRUE;
                    end
            7'h1B:  dsp <= a;
            7'h20:  cs[0] <= a;
            7'h21:  cs[1] <= a;
            7'h22:  cs[2] <= a;
            7'h23:  cs[3] <= a;
            7'h24:  csl[0] <= a;
            7'h25:  csl[1] <= a;
            7'h26:  csl[2] <= a;
            7'h27:  csl[3] <= a;
            7'h28:  es[0] <= a;
            7'h29:  es[1] <= a;
            7'h2A:  es[2] <= a;
            7'h2B:  es[3] <= a;
            7'h2C:  esl[0] <= a;
            7'h2D:  esl[1] <= a;
            7'h2E:  esl[2] <= a;
            7'h2F:  esl[3] <= a;
            7'h30:  fs[0] <= a;
            7'h31:  fs[1] <= a;
            7'h32:  fs[2] <= a;
            7'h33:  fs[3] <= a;
            7'h34:  fsl[0] <= a;
            7'h35:  fsl[1] <= a;
            7'h36:  fsl[2] <= a;
            7'h37:  fsl[3] <= a;
            7'h38:  gs[0] <= a;
            7'h39:  gs[1] <= a;
            7'h3A:  gs[2] <= a;
            7'h3B:  gs[3] <= a;
            7'h3C:  gsl[0] <= a;
            7'h3D:  gsl[1] <= a;
            7'h3E:  gsl[2] <= a;
            7'h3F:  gsl[3] <= a;
            7'h40:  ds[regset] <= a;
            7'h41:  dsl[regset] <= a;
            7'h42:  cs[regset] <= a;
            7'h43:  csl[regset] <= a;
            7'h44:  es[regset] <= a;
            7'h45:  esl[regset] <= a;
            7'h46:  fs[regset] <= a;
            7'h47:  fsl[regset] <= a;
            7'h48:  gs[regset] <= a;
            7'h49:  gsl[regset] <= a;
            endcase
          end
        endcase
      `LDAR: sr <= `HIGH;
      `ST:
        begin
          rw <= `LOW;
          dat_o <= b;
        end
      `STCR:
        begin
          cr <= `HIGH;
          rw <= `LOW;
          dat_o <= b;
        end
      endcase
      if (opcode==`LD || opcode==`LDAR || opcode==`ST || opcode==`STCR) begin
        mem1();
        state <= MEMORY;
      end
      else
        go_ifetch();
    end

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // The only memory operations are LD,LDAR,ST, and STCR
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  MEMORY:
    begin
      a <= dat_i;
      if (opcode==`STCR)
        rf <= rv;
      go_ifetch();
    end

  //----------------------------------------------------------------------------
  // Far jump
  //----------------------------------------------------------------------------
  JMPF1:
    begin
      next_cs <= dat_i;
      vpa <= `HIGH;
      ad <= {cs[regset],SEGSHIFT} + pc;
      pc <= pc + 1;
      state <= JMPF2;
    end
  JMPF2:
    begin
      next_csl <= dat_i[26:0];
      regset <= dat_i[31:30];
      state <= JMPF3;
    end
  JMPF3:
    begin
      pc <= ir[31:5];
      cs[regset] <= next_cs;
      csl[regset] <= next_csl;
      state <= JMP1;
    end

  //----------------------------------------------------------------------------
  // Near jump
  //----------------------------------------------------------------------------
  JMP1: go_ifetch();

  //----------------------------------------------------------------------------
  // BRK instruction handling
  //----------------------------------------------------------------------------
  BRK1:
    begin
      vda <= `HIGH;
      dat_o <= cs[regset];
      ad <= {ds[2],SEGSHIFT} + ssp - 32'd1;
      rw <= `LOW;
      ssp <= ssp - 32'd1;
      state <= BRK2;
    end
  BRK2:
    begin
      vda <= `HIGH;
      dat_o <= pc;
      ad <= {ds[2],SEGSHIFT} + ssp - 32'd1;
      rw <= `LOW;
      ssp <= ssp - 32'd1;
      state <= BRK3;
    end
  BRK3:
    begin
      vda <= `HIGH;
      dat_o <= msw;
      ad <= {ds[2],SEGSHIFT} + ssp - 32'd1;
      ssp <= ssp - 32'd1;
      rw <= `LOW;
      state <= BRK4;
    end
  BRK4:
    begin
      if (hwi)
        im <= `TRUE;
      hwi <= `FALSE;
      cs[2] <= vcs;
      csl[2] <= 27'h7FF;
      pc <= {ir[13:5],2'b0};
      regset <= 2'd2;
      state <= JMP1;
    end
  //----------------------------------------------------------------------------
  // DBG instruction handling
  //----------------------------------------------------------------------------
  DBG1:
    begin
      vda <= `HIGH;
      dat_o <= cs[regset];
      ad <= {ds[3],SEGSHIFT} + dsp - 32'd1;
      rw <= `LOW;
      dsp <= dsp - 32'd1;
      state <= DBG2;
    end
  DBG2:
    begin
      vda <= `HIGH;
      dat_o <= pc;
      ad <= {ds[3],SEGSHIFT} + dsp - 32'd1;
      rw <= `LOW;
      dsp <= dsp - 32'd1;
      state <= DBG3;
    end
  DBG3:
    begin
      vda <= `HIGH;
      dat_o <= msw;
      ad <= {ds[3],SEGSHIFT} + dsp - 32'd1;
      dsp <= dsp - 32'd1;
      rw <= `LOW;
      state <= DBG4;
    end
  DBG4:
    begin
      cs[3] <= vcs;
      csl[3] <= 27'h7FF;
      pc <= {ir[13:5],2'b0};
      regset <= 2'd3;
      state <= JMP1;
    end
  //----------------------------------------------------------------------------
  //----------------------------------------------------------------------------
  RTS1:
    begin
      pc <= dat_i[26:0];
      state <= JMP1;
    end

  //----------------------------------------------------------------------------
  // RTI instruction handling
  //----------------------------------------------------------------------------
  // Fetch the machine status from the stack and place in a 
  // temporary register.
  RTI1:
    begin
      next_msw <= dat_i;
      state <= RTI2;
    end
  // Set the machine status word to the fetched value.
  // Update the stack pointer and prepare to fetch the program counter.
  // Set the register set back to the pre-interrupt one.
  RTI2:
    begin
      cf[next_msw[9:8]] <= next_msw[0];
      zf[next_msw[9:8]] <= next_msw[1];
      im <= next_msw[2];
      of[next_msw[9:8]] <= next_msw[3];
      rf <= next_msw[4];
      vf[next_msw[9:8]] <= next_msw[6];
      nf[next_msw[9:8]] <= next_msw[7];
      vda <= `HIGH;
      case(regset)
      2'd2:
        begin
        ad <= {ds[2],SEGSHIFT} + ssp;
        ssp <= ssp + 32'd1;
        end
      2'd3:
        begin
        ad <= {ds[3],SEGSHIFT} + dsp;
        dsp <= dsp + 32'd1;
        end
      endcase
      oregset <= regset;
      regset <= next_msw[9:8];
      state <= RTI3;
    end
  // Set the program counter to the fetched value.
  // Update the stack pointer and prepare to fetch the code segment.
  RTI3:
    begin
      vda <= `HIGH;
      case(oregset)
      2'd2:
        begin
        ad <= {ds[2],SEGSHIFT} + ssp;
        ssp <= ssp + 32'd1;
        end
      2'd3:
        begin
        ad <= {ds[3],SEGSHIFT} + dsp;
        dsp <= dsp + 32'd1;
        end
      endcase
      pc <= dat_i;
      state <= RTI4;
    end
  // Set the code segment to the fetched value
  // Restore the data segment
  RTI4:
    begin
      cs[regset] <= dat_i;
      vda <= `HIGH;
      case(oregset)
      2'd2:
        begin
        ad <= {ds[2],SEGSHIFT} + ssp;
        ssp <= ssp + 32'd1;
        end
      2'd3:
        begin
        ad <= {ds[3],SEGSHIFT} + dsp;
        dsp <= dsp + 32'd1;
        end
      endcase
      state <= RTI5;
    end
  // Set the code segment limit
  // and transfer any return register
  RTI5:
    begin
      csl[regset] <= dat_i;
      Rt <= {regset,ir[19:15]};
      // trim a cycle off the return if there is no register
      // to transfer back
      go_ifetch();
    end
  endcase
end

task go_ifetch;
begin
  vpa <= `HIGH;
  ad <= {cs[regset],SEGSHIFT} + pc;
  pc <= pc + 27'd1;
  state <= IFETCH;
end
endtask

task regfetch;
input [2:0] TSs;
input [4:0] Rn;
output [31:0] o;
begin
  case(TSs)
  3'd0: rs = TSs[1:0];
  3'd1: rs = TSs[1:0];
  3'd2: rs = TSs[1:0];
  3'd3: rs = TSs[1:0];
  3'd7: rs = regset;
  default: rs = regset;
  endcase
  case(Rn)
  5'd0:   o = 32'd0;
  5'd31:  
    case(rs)
    2'd0: o = usp1;
    2'd1: o = usp2;
    2'd2: o = ssp;
    2'd3: o = dsp;
    endcase
  default:  o <= regs[{rs,Rn}];
  endcase
end
endtask

task setfault;
input [8:0] faultnum;
input [31:0] addr;
input [3:0] seg;
begin
  fault_pc <= orig_pc;
  fault_cs <= orig_cs;
  fault_addr <= addr;
  fault_seg <= seg;
  ir <= {faultnum,`BRK};
  state <= DECODE;
end
endtask

task incsp;
begin
case(regset)
2'd0: usp1 <= usp1 + 32'd1;
2'd1: usp2 <= usp2 + 32'd1;
2'd2: ssp <= ssp + 32'd1;
2'd3: dsp <= dsp + 32'd1;
endcase
end
endtask

task decsp;
begin
case(regset)
2'd0: usp1 <= usp1 - 32'd1;
2'd1: usp2 <= usp2 - 32'd1;
2'd2: ssp <= ssp - 32'd1;
2'd3: dsp <= dsp - 32'd1;
endcase
end
endtask

task mem1;
begin
  case(res[31:29])
  3'd0,3'd7:  begin aseg = ds[regset]; almt = dsl[regset]; end
  3'd1:  begin aseg = es[regset]; almt = esl[regset]; end
  3'd2:  begin aseg = fs[regset]; almt = fsl[regset]; end
  3'd3:  begin aseg = gs[regset]; almt = gsl[regset]; end
  3'd4:  begin aseg = cs[regset]; almt = csl[regset]; end
  default:  begin aseg = 0; almt = 0; end
  endcase
  case(res[31:29])
  3'd0,3'd7:  // Data segment
    begin
      boundsOK = `FALSE;
      if (Ra==5'd31 || Ra==5'd30) begin
        if (res[28:0] > ssl[regset] + STACK_MARGIN && res[28:0] <= ssu[regset])
          boundsOK = `TRUE;
        else begin
          setfault(`STACK_FAULT,res,4'd8);
        end
      end
      else begin
        if (res[28:0] <= almt)
          boundsOK = `TRUE;
        else begin        
          setfault(`BOUNDS,res,3'd0);
        end
      end
      if (boundsOK) begin
        vda <= `HIGH;
        ad <= {aseg,SEGSHIFT} + res[28:0];
      end
    end
  3'd1,3'd2,3'd3:
    if (res[28:0] > almt)
      setfault(`BOUNDS,res,4'd1);
    else begin
      vda <= `HIGH;
      ad <= {aseg,SEGSHIFT} + res[28:0];
    end
  3'd4:
    if (res[26:0] > almt[26:0])
      setfault(`BOUNDS,res,4'd4);
    else begin
      vpa <= `HIGH;
      ad <= {aseg,SEGSHIFT} + res[26:0];
    end
  default:
    begin
      setfault(9'd485,res,4'd9);
    end
  endcase
end
endtask

task SetNZO;
begin
  zf[regset] <= res==32'd0;
  nf[regset] <= res[31];
  of[regset] <= res[0];
end
endtask

task SetCVNZO;
input addsub; // 1=add,0=sub
begin
  SetNZO();
  cf[regset] <= addsub ? (a[31]&b[31])|(a[31]&~res[31])|(b[31]&~res[31]) : (~a[31]&b[31])|(res[31]&~a[31])|(res[31]&b[31]);
  vf[regset] <= (res[31] ^ b[31]) & (addsub ^ a[31] ^ b[31]);
end
endtask

endmodule
