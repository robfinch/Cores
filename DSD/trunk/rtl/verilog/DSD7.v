`define TRUE    1'b1
`define FALSE   1'b0

`define BRK     6'h00
`define RET     6'h01
`define BccI    6'h02
`define BccUI   6'h03
`define ADDI    6'h04
`define CMPI    6'h05
`define CMPUI   6'h06
`define ANDI    6'h08
`define ORI     6'h09
`define XORI    6'h0A
`define R2      6'h0C
`define CSRI    6'h0F
`define JMP     6'h10
`define CALL    6'h11
`define Bcc     6'h12
`define BccU    6'h13
`define NOP     6'h1A
`define RET2    6'h1B
`define CINSN   6'h1F
`define LH      6'h20
`define LHU     6'h21
`define LW      6'h22
`define LWR     6'h23
`define SH      6'h28
`define SW      6'h29
`define SWC     6'h2A
`define CSR     6'h3F

// R2 functs
`define IRET    6'h01
`define IPUSH   6'h02
`define IPOP    6'h03
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
`define SHL     6'h10
`define SHR     6'h11
`define ASR     6'h12
`define ROL     6'h13
`define ROR     6'h14
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

`define _2NOP_INSN    {10'h0,`NOP,10'h0,`NOP}

`define CSRRW     2'b00
`define CSRRS     2'b01
`define CSRRC     2'b10

`define CSR_HARTID  12'h001
`define CSR_VBA     12'h004
`define CSR_SCRATCH 12'h009
`define CSR_TASK    12'h010
`define CSR_CISC    12'h011
`define CSR_PCBANK  12'h017
`define CSR_IHOLDL  12'h040
`define CSR_IHOLDH  12'h041

module DSD7(hartid_i, rst_i, clk_i, irq_i, ivec_i,
    vda_o, rdy_i, lock_o, wr_o, sel_o, adr_o, dat_i, dat_o, sr_o, cr_o, rb_i,
    irdy_i, iadr_o, idat_i);
input [31:0] hartid_i;
input rst_i;
input clk_i;
input irq_i;
input [8:0] ivec_i;
output reg vda_o;
input rdy_i;
output reg lock_o;
output reg wr_o;
output reg [1:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;
output reg sr_o;
output reg cr_o;
input rb_i;
input irdy_i;
output reg [31:0] iadr_o;
input [31:0] idat_i;

// Core capabilities
parameter CAP_LS_NDX = 1'b1;
parameter CAP_ROTATES = 1'b1;

parameter half = 2'b10;
parameter word = 2'b11;

// State machine states
parameter RUN = 6'd1;
parameter LOAD1 = 6'd10;
parameter LOAD2 = 6'd11;
parameter LOAD3 = 6'd12;
parameter STORE1 = 6'd15;
parameter STORE2 = 6'd16;
parameter STORE3 = 6'd17;
parameter LOAD_ICACHE = 6'd20;
parameter LOAD_ICACHE2 = 6'd21; 
parameter ICACHE_RST = 6'd22;

integer n;
reg [5:0] state;
reg [31:0] pc,dpc,xpc;
reg [31:0] pc_inc;
reg [63:0] insn,iinsn;
reg [63:0] ir,xir;
reg ii32,ii5,ii5a;
reg i32,i5,i5a;
wire [5:0] iopcode = iinsn[5:0];
wire [5:0] ifunct = iinsn[31:26];
wire [4:0] iRb = iinsn[15:11];
wire [5:0] opcode = ir[5:0];
wire [5:0] funct = ir[31:26];
reg [4:0] Ra,iRa,xRa;
wire [4:0] Rb = ir[15:11];
wire [4:0] Rc = ir[20:16];
reg [4:0] Rt,xRt;
wire [5:0] xopcode = xir[5:0];
wire [5:0] xfunct = xir[31:26];
// im1 | tr8 | pc32
reg [40:0] istack[0:15];
reg [3:0] isp;
reg [31:0] regfile [0:31];
reg [31:0] rfoa,rfob,rfoc;
reg [31:0] a,b,c,imm,ea,xb;
reg [31:0] res,lres,lres1;
reg ex_done;
wire takb;
reg [31:0] br_disp;
wire [31:0] logic_o, shift_o;
reg [1:0] mem_size;
// CSR's
reg [23:0] pcbank;
reg [19:0] vba;                 // vector table base address (bits 12 to 31).
reg [5:0] tr;
reg im;
reg [63:0] ihold;
reg [31:0] cisc;
wire [7:0] isid = cisc[7:0];
reg [31:0] scratch;


always @*
case(Ra)
5'd0:   rfoa <= 32'd0;
xRt:    rfoa <= res;
default:    rfoa <= regfile[Ra]; 
endcase

always @*
case(Rb)
5'd0:   rfob <= 32'd0;
xRt:    rfob <= res;
default:    rfob <= regfile[Rb]; 
endcase

always @*
case(Rc)
5'd0:   rfoc <= 32'd0;
xRt:    rfoc <= res;
default:    rfoc <= regfile[Rc]; 
endcase


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
        `LHX,`LHUX,`LWX,`LWRX:  res = CAP_LS_NDX ? lres : 32'hDEADDEAD;
        endcase
    
    `ADDI:  res = a + imm;
    `CMPI:  res = $signed(a) < $signed(imm) ? -1 : a==imm ? 0 : 1;
    `CMPUI: res = a < imm ? -1 : a==imm ? 0 : 1;
    `ANDI:  res = logic_o;
    `ORI:   res = logic_o;
    `XORI:  res = logic_o;
    `LH,`LHU,`LW,`LWR:  res = lres;
    `CALL,`RET,`RET2:  res = a + imm;
    `CSR,`CSRI:
        case(xir[29:18])
        `CSR_HARTID:    res = hartid_i;
        `CSR_VBA:       res = vba;
        `CSR_SCRATCH:   res = scratch;
        `CSR_TASK:      res = tr;
        `CSR_CISC:      res = cisc;
        `CSR_PCBANK:    res = {pcbank,xpc[31:24]};
        `CSR_IHOLDL:    res = ihold[31:0];
        `CSR_IHOLDH:    res = ihold[63:32];
        default:    res = 32'hDEADDEAD;
        endcase
    
    endcase
end


//---------------------------------------------------------------------------
// Lookup table for compressed instructions.
// The lookup table appears in the data memory space of the processor at an
// address defined by the cisc register.
//---------------------------------------------------------------------------
wire [31:0] cinsn;
wire cs_hl = vda_o && wr_o && adr_o[31:20]==cisc[31:20];
DSD7_ciLookupTbl u3
(
    .wclk(clk_i),
    .wr(cs_hl),
    .wadr(adr_o[13:2]),
    .wdata(dat_o),
    .rclk(~clk_i),
    .radr({isid[1:0],insn[15:6]}),
    .rdata(cinsn)
);


//---------------------------------------------------------------------------
// I-Cache
// This 64-line 4 way set associative cache is used mainly to allow access
// to 16 and 64 bit instructions while the external bus is 32 bit.
// On reset the cache is loaded with NOP's and the tag memory is loaded
// with $FFFFFFF0. There should not be any valid instructions placed in the
// the area $FFFFFFF0 to $FFFFFFFF
//
// iadr_o is the instruction address output for fetching the cache line
// idat_i is the instruction data coming in from external memory.
//---------------------------------------------------------------------------
wire [31:0] pcp8 = pc + 32'h0008;   // Use pc plus 8 to select the next cache line.
wire [22:0] ic_lfsr;

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
reg [1:0] icmf;             // miss flags
reg isICacheReset;
reg isICacheLoad;
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
  // Reset the entire cache to NOPs on a reset. This may not strictly be
  // necessary as the tags are also reset and will cause cache line loads
  // anyways. 
  if (isICacheReset) begin
    case(iadr_o[2:1])
    2'd0: begin
            cache_mem0[iadr_o[8:3]][31:0] <= `_2NOP_INSN; // way #0
            cache_mem1[iadr_o[8:3]][31:0] <= `_2NOP_INSN; // way #1
            cache_mem2[iadr_o[8:3]][31:0] <= `_2NOP_INSN; // way #2
            cache_mem3[iadr_o[8:3]][31:0] <= `_2NOP_INSN; // way #3
          end
    2'd1: begin
            cache_mem0[iadr_o[8:3]][63:32] <= `_2NOP_INSN;
            cache_mem1[iadr_o[8:3]][63:32] <= `_2NOP_INSN;
            cache_mem2[iadr_o[8:3]][63:32] <= `_2NOP_INSN;
            cache_mem3[iadr_o[8:3]][63:32] <= `_2NOP_INSN;
          end
    2'd2: begin
            cache_mem0[iadr_o[8:3]][95:64] <= `_2NOP_INSN;
            cache_mem1[iadr_o[8:3]][95:64] <= `_2NOP_INSN;
            cache_mem2[iadr_o[8:3]][95:64] <= `_2NOP_INSN;
            cache_mem3[iadr_o[8:3]][95:64] <= `_2NOP_INSN;
          end
    2'd3: begin
            cache_mem0[iadr_o[8:3]][127:96] <= `_2NOP_INSN;
            cache_mem1[iadr_o[8:3]][127:96] <= `_2NOP_INSN;
            cache_mem2[iadr_o[8:3]][127:96] <= `_2NOP_INSN;
            cache_mem3[iadr_o[8:3]][127:96] <= `_2NOP_INSN;
          end
    endcase
  end
  else begin
    // During a cache-line load, load only the way which was selected randomly.
    // This currently requires 4 bus cycles of 32 bits.
    if (isICacheLoad) begin
      case({ic_whichWay,iadr_o[2:1]})
      4'd0: cache_mem0[iadr_o[8:3]][31:0] <= idat_i;
      4'd1: cache_mem0[iadr_o[8:3]][63:32] <= idat_i;
      4'd2: cache_mem0[iadr_o[8:3]][95:64] <= idat_i;
      4'd3: cache_mem0[iadr_o[8:3]][127:96] <= idat_i;
      4'd4: cache_mem1[iadr_o[8:3]][31:0] <= idat_i;
      4'd5: cache_mem1[iadr_o[8:3]][63:32] <= idat_i;
      4'd6: cache_mem1[iadr_o[8:3]][95:64] <= idat_i;
      4'd7: cache_mem1[iadr_o[8:3]][127:96] <= idat_i;
      4'd8: cache_mem2[iadr_o[8:3]][31:0] <= idat_i;
      4'd9: cache_mem2[iadr_o[8:3]][63:32] <= idat_i;
      4'd10: cache_mem2[iadr_o[8:3]][95:64] <= idat_i;
      4'd11: cache_mem2[iadr_o[8:3]][127:96] <= idat_i;
      4'd12: cache_mem3[iadr_o[8:3]][31:0] <= idat_i;
      4'd13: cache_mem3[iadr_o[8:3]][63:32] <= idat_i;
      4'd14: cache_mem3[iadr_o[8:3]][95:64] <= idat_i;
      4'd15: cache_mem3[iadr_o[8:3]][127:96] <= idat_i;
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

// On reset the tags are set to all one's then it is stiplulated that access to
// the last line of memory is considered invalid. This saves requiring a tag
// valid bit at the expense of 16 fewer bytes of memory. The last line of memory
// is often used for ROM checksum and version information anyway.
always @(posedge clk_i)
  if (isICacheReset) begin
    tag_mem0[iadr_o[8:3]] <= {32{1'b1}};    // Tag of all one's - invalid tag
    tag_mem1[iadr_o[8:3]] <= {32{1'b1}};
    tag_mem2[iadr_o[8:3]] <= {32{1'b1}};
    tag_mem3[iadr_o[8:3]] <= {32{1'b1}};
  end
  else begin
    // Set the tag only when the last 32 bits of the instruction line is loaded.
    // Prevents the tag from going valid until the entire line is present.
    if (isICacheLoad && iadr_o[2:1]==2'b11) begin
        case(ic_whichWay)
        2'd0:   tag_mem0[iadr_o[8:3]] <= iadr_o;
        2'd1:   tag_mem1[iadr_o[8:3]] <= iadr_o;
        2'd2:   tag_mem2[iadr_o[8:3]] <= iadr_o;
        2'd3:   tag_mem3[iadr_o[8:3]] <= iadr_o;
        endcase
    end
  end

// Set tag comparators, there would be only four for a four-way set associative
// cache, but we need to check two cache lines in case the instruction spans a
// cache lines. Hence there are four pairs of comparators.
assign ihit01 = pc[31:9]==tag_mem0[pc[8:3]][31:9];
assign ihit02 = pcp8[31:9]==tag_mem0[pcp8[8:3]][31:9];
assign ihit11 = pc[31:9]==tag_mem1[pc[8:3]][31:9];
assign ihit12 = pcp8[31:9]==tag_mem1[pcp8[8:3]][31:9];
assign ihit21 = pc[31:9]==tag_mem2[pc[8:3]][31:9];
assign ihit22 = pcp8[31:9]==tag_mem2[pcp8[8:3]][31:9];
assign ihit31 = pc[31:9]==tag_mem3[pc[8:3]][31:9];
assign ihit32 = pcp8[31:9]==tag_mem3[pcp8[8:3]][31:9];
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


//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
wire advanceRF = !((xisLd || xisSt)&&ex_done==`FALSE);
wire advanceIF = advanceRF & ihit;

always @(posedge clk_i)
if (rst_i) begin
    im <= `TRUE;
    tr <= 6'd0;
    vba <= 14'h3FFD;
    cisc <= 32'hFFE00000;
    pc <= 32'hFFFFFFE0;
    vda_o <= `FALSE;
    lock_o <= `FALSE;
    wr_o <= `FALSE;
    sel_o <= 2'b00;
    isICacheReset <= `TRUE;
    next_state(ICACHE_RST);
end
else begin
case(state)
ICACHE_RST:
    begin
        iadr_o <= iadr_o + 32'd8;
        if (iadr_o[10:3]==8'hFF) begin
            isICacheReset <= `FALSE;
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
        if (irq_i & ~im)
            iinsn = {17'd0,ivec_i,`BRK};
        else
            iinsn = insn[5:0]==`CINSN ? cinsn : insn;
        ii32 = iinsn[31:26]==6'h20;
        ii5 = iinsn[15:11]==5'h10;
        ii5a = iinsn[10:6]==5'h10;
        case(iinsn[5:0])
        `CALL,`RET,`RET2:   iRa = 5'd31;
        default:    iRa = iinsn[10:6]; 
        endcase
        Ra <= iRa;
        case(insn[5:0])
        `BRK,`RET,`ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI:
            pc_inc = ii32 ? 32'd4 : 32'd2;
        `BccI:  pc_inc = ii5 ? 32'd4 : 32'd2;
        `BccUI:  pc_inc = ii5 ? 32'd4 : 32'd2;
        `NOP,`RET2,`CINSN:
            pc_inc = 32'd1;
        `CSRI:  pc_inc = ii5a ? 32'd4 : 32'd2;
        default:    pc_inc = 32'd1;
        endcase
        case(iopcode)
        `BRK:       pc <= {vba,1'b1,iinsn[14:6],2'b00};
        `JMP,`CALL: pc <= {{pcbank,pc[31:24]} >> {iinsn[31:30],3'b0},iinsn[29:6]};
        default:    pc <= pc + pc_inc;
        endcase
        i32 <= ii32;
        i5 <= ii5;
        i5a <= ii5a;
        ir <= iinsn;
        dpc <= pc;
    end
    else begin
        if (!ihit) begin
            icmf <= {ihit1,ihit2};
            next_state(LOAD_ICACHE);
        end
        if (advanceRF) begin
            nop_ir();
            dpc <= pc;
            pc <= pc;
        end
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Register fetch stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (advanceRF) begin
        xir <= ir;
        xpc <= dpc;
        a <= rfoa;
        b <= rfob;
        c <= rfoc;
        case(opcode)
        `R2:
          case(funct)
          `SHLI,`SHRI,`ASRI,`ROLI,`RORI:     b <= Rb;
          default:    ;
          endcase
        default:  ;
        endcase
        case(opcode)
        `BRK,`RET,`ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,
        `LH,`LHU,`LW,`LWR,`SH,`SW,`SWC:
            imm <= i32 ? ir[63:32] : {{16{ir[31]}},ir[31:16]};
        `BccI,`BccUI:  imm <= i5 ? ir[63:32] : {{27{ir[15]}},ir[15:11]};
        `CSRI:         imm <= i5a ? ir[63:32] : {{27{ir[10]}},ir[10:6]};
        `CALL:         imm <= -32'd2;
        `RET2:         imm <= 32'd2;
        endcase
        // Branch displacement, used only for conditional branches.
        // Branches may also compare against an immediate so the displacement
        // has to be determined separately. 
        br_disp <= {{19{ir[31]}},ir[31:19]};
        // Needed for CSR instructions
        xRa <= Ra;
        // Set target register
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
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI,
        `LH,`LHU,`LW,`LWR:
            xRt <= ir[15:11];
        `CALL,`RET,`RET2:   xRt <= 5'd31;
        default:
            xRt <= 5'd0;
        endcase
    end
    else
        nop_xir();

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Execute stage
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    begin   // if (advanceEX) // always true
        if (ex_done==`TRUE)
            ex_done <= `FALSE;
        regfile[xRt] <= res;
        case(xopcode)
        `BRK:
            begin
                istack[isp-4'd1] <= {im,tr,6'b111111,xpc+xir[18:15]};
                isp <= isp - 4'd1;
                im <= `TRUE;
                tr <= 6'd0;
            end
        `JMP:   ; // nothing to do
        `CALL:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= word;
                ea <= a + imm;
                xb <= xpc + 32'd2;
                state <= STORE1;
            end
        `RET,`RET2:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= word;
                ea <= a + 32'd2;
                next_state(LOAD1);
            end
            else
                ex_branch(lres+xir[15:11]);
        `Bcc,`BccU,`BccI,`BccUI:
            if (takb)
                ex_branch(pc + br_disp);

        `R2:
            case(xfunct)
            `IRET:
                begin
                ex_branch(istack[isp][25:0]);
                tr <= istack[isp][37:32];
                im <= istack[isp][40];
                isp <= isp + 4'd1;
                end
            `IPUSH:
                begin
                istack[isp-4'd1] <= ihold[40:0];
                isp <= isp - 4'd1;
                end
            `IPOP:
                begin
                ihold[40:0] <= istack[isp];
                isp <= isp + 4'd1;
                end
            `ADD,`SUB,`CMP,`CMPU,
            `AND,`OR,`XOR,`NAND,`NOR,`XNOR:
                ;
            `LHX,`LHUX:
                if (CAP_LS_NDX) begin
                    if (ex_done==`FALSE) begin
                        ex_done <= `TRUE;
                        mem_size <= half;    
                        ea <= a + b;
                        next_state(LOAD1);
                    end
                end
            `LWX,`LWRX:
                if (CAP_LS_NDX) begin
                    if (ex_done==`FALSE) begin
                        ex_done <= `TRUE;
                        mem_size <= word;    
                        ea <= a + b;
                        next_state(LOAD1);
                    end
                end
            `SHX:
                if (CAP_LS_NDX) begin
                    if (ex_done==`FALSE) begin
                        ex_done <= `TRUE;
                        mem_size <= half;
                        ea <= a + b;
                        xb <= b;
                        state <= STORE1;
                    end
                end
            `SWX,`SWCX:
                if (CAP_LS_NDX) begin
                    if (ex_done==`FALSE) begin
                        ex_done <= `TRUE;
                        mem_size <= word;
                        ea <= a + b;
                        xb <= c;
                        state <= STORE1;
                    end
                end
            endcase
        `ADDI,`CMPI,`CMPUI,`ANDI,`ORI,`XORI:
            ;
        `LH,`LHU:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= half;    
                ea <= a + imm;
                next_state(LOAD1);
            end
        `LW,`LWR:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= word;
                ea <= a + imm;
                next_state(LOAD1);
            end
        `SH:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= half;
                ea <= a + imm;
                xb <= b;
                state <= STORE1;
            end
        `SW,`SWC:
            if (ex_done==`FALSE) begin
                ex_done <= `TRUE;
                mem_size <= word;
                ea <= a + imm;
                xb <= b;
                state <= STORE1;
            end
        `CSR:   if (xRa != 5'd0)
                    ex_csr(a);
        `CSRI:  ex_csr(imm);
        default:    ;
        endcase
    end // advanceEX
end // RUN

LOAD1:
    begin
		read1(mem_size,ea);
        next_state(LOAD2);
    end
LOAD2:
    if (rdy_i) begin
        lres1 = dat_i >> {ea[0],4'h0};
        case(xopcode)
        `LH:
            begin
            vda_o <= `FALSE;
            sel_o <= 2'b00;
            lres <= {{16{lres1[15]}},lres1[15:0]};
            next_state(RUN);
            end
        `LHU:
            begin
            vda_o <= `FALSE;
            sel_o <= 2'b00;
            lres <= {16'd0,lres1[15:0]};
            next_state(RUN);
            end
        `LW,`LWR:
            begin
            case(ea[0])
            1'b1:   begin read2(mem_size,ea); lres[15:0] <= lres1[15:0]; state <= LOAD3; end
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
        sr_o <= 1'b0;
    end
// The operation here must be a LW or LWR.
LOAD3:
    if (rdy_i) begin
        vda_o <= `FALSE;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        next_state(RUN);
        lres[31:16] <= dat_i[15:0];
    end

STORE1:
    begin
        write1(mem_size,ea,xb);
        $display("Store to %h <= %h", ea, xb);
        next_state(STORE2);
    end
STORE2:
    if (rdy_i) begin
        if (mem_size==word && ea[0]!=1'b0) begin
            write2(mem_size,ea,xb);
            next_state(STORE3);
        end
        else begin
            vda_o <= `FALSE;
            wr_o <= 1'b0;
            sel_o <= 2'b00;
            next_state(RUN);
        end
        cr_o <= 1'b0;
    end
STORE3:
    if (rdy_i) begin
        vda_o <= `FALSE;
        wr_o <= 1'b0;
        sel_o <= 2'b00;
        lock_o <= `FALSE;
        next_state(RUN);
    end

LOAD_ICACHE:
    begin
        if (icmf != 2'b11) begin
            isICacheLoad <= `TRUE;
            if (icmf[1]) begin
                iadr_o <= {pcp8[31:3],3'b000};
                icmf[0] <= 1'b1;
            end
            else begin
                icmf[1] <= 1'b1;
                iadr_o <= {pc[31:3],3'b000};
            end
            next_state(LOAD_ICACHE2);
        end
        else
            next_state(RUN);
    end
LOAD_ICACHE2:
    if (irdy_i) begin
        iadr_o[2:1] <= iadr_o[2:1] + 2'd1;
        if (iadr_o[2:1]==2'b11) begin
            isICacheLoad <= `FALSE;
            next_state(icmf==2'b11 ? RUN : LOAD_ICACHE);
        end
    end
default:
    next_state(RUN);
endcase
end


task nop_ir();
begin
    ir <= `_2NOP_INSN;
end
endtask

task nop_xir();
begin
    xir <= `_2NOP_INSN;
    xRt <= 5'd0;
end
endtask

task ex_branch;
input [31:0] nxt_pc;
begin
    nop_ir();
    nop_xir();
    pc <= nxt_pc;
end
endtask

task read1;
input [1:0] sz;
input [31:0] adr;
begin
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
            1'd1: begin sel_o <= 2'b10; dat_o <= {dat[15:0],16'h0000}; lock_o <= `TRUE; end
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
  vda_o <= `TRUE;
  wr_o <= 1'b1;
  adr_o <= {adr[31:1]+31'd1,1'b0};
  sel_o <= 2'b01;
  dat_o <= {16'h0000,dat[31:16]};
end
endtask

task next_state;
input [5:0] st;
begin
  state <= st;
end
endtask

task ex_csr;
input [31:0] dat;
begin
    case(xir[17:16])
    `CSRRW:
        case(xir[29:18])
        `CSR_HARTID:    ;
        `CSR_VBA:       vba <= dat;
        `CSR_SCRATCH:   scratch <= dat;
        `CSR_TASK:      tr <= dat[5:0];
        `CSR_CISC:      cisc <= dat;
        `CSR_PCBANK:    pcbank <= dat[31:8];
        `CSR_IHOLDL:    ihold[31:0] <= dat;
        `CSR_IHOLDH:    ihold[63:32] <= dat;
        endcase
    endcase
end
endtask

endmodule
