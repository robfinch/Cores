`include "..\inc\Thor2020-config.sv"
`include "..\inc\Thor2020-types.sv"

module Thor2020(rst,clk,
  iicl_o,icti_o,ibte_o,icyc_o,istb_o,iack_i,isel_o,iadr_o,idat_i,
  wr,rdy,ad,dato,dati);
parameter WID=64;
parameter AMSB = `AMSB;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
input rst; input clk; 
output iicl_o; output [2:0] icti_o; output [1:0] ibte_o; output icyc_o; output istb_o; input iack_i; output [15:0] isel_o;
output [AMSB:0] iadr_o; input [127:0] idat_i;
output reg wr; input rdy; output reg [24:0] ad; output reg [63:0] dato;
input [63:0] dati;
parameter RR=7'd2,R2=7'd2,ADDI = 7'd4,CMPI=7'd6,ANDI=7'd8,ORI=7'd9,XORI=7'd10,ADD=7'd4,SUB=7'd5,CMP=7'd6,AND=7'd8,
OR=7'd9,XOR=7'd10;
parameter LD=7'b101????,LDD=7'h53,ST=7'b110????,STD=7'h63,LOOP=7'd77,JMP=7'd78,JML=7'd79,LDI=7'd77;
parameter RET=7'd79,NOP=8'b11101010,SHL=7'd16,SHR=7'd17,ASR=7'd18,SHLI=7'd20,SHRI=7'd21,ASRI=7'd22,MFSPR=7'd32,MTSPR=7'd33;
parameter MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;
parameter CEQ=4'd0,CNE=4'd1,CLT=4'd4,CGE=4'd5,CLE=4'd6,CGT=4'd7,CLTU=4'd8,CGEU=4'd9,CLEU=4'd10,CGTU=4'd11,CADC=4'd12,COFL=4'd13,COD=4'd14;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
reg [3:0] state;
parameter ST_FETCH=3'd1,ST_RUN = 3'd2,ST_LD0=3'd3,ST_LD1=3'd4,ST_LD2=3'd5,ST_ST=3'd6,ST_MULDIV=3'd7;
reg [127:0] ir;
wire [40:0] ir0 = ir[40:0]; wire [40:0] ir1 = ir[81:41]; wire [40:0] ir2 = ir[122:82]; wire [2:0] irb = ir[125:123];
wire [6:0] opcode0 = ir0[14:8]; wire [6:0] opcode1 = ir1[14:8]; wire [6:0] opcode2 = ir2[14:8];
wire [6:0] funct70 = ir0[40:34]; wire [6:0] funct71 = ir1[40:34]; wire [6:0] funct72 = ir2[40:34];
reg [2:0] ex;
reg ld0, ld1, ld2;
integer n;

reg [31:0] ip;
wire [127:0] insn;
reg invall = 1'b0;
reg invline = 1'b0;
wire isROM;
wire [2:0] L1_flt;
wire L1_selpc, L1_wr, L1_nxt, L1_invline;
wire [127:0] ROM_dat, L1_dat, L2_dat;
wire L1_ihit, L2_ihit, L2_ihita;
wire L2_ld, L2_nxt;
wire [2:0] L2_cnt;
tAddress L1_adr, L2_adr;
tAddress missadr;
assign L2_ihit = isROM|L2_ihita;

L1_icache uic1
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L1_nxt),
	.wr(L1_wr),
	.wadr(L1_adr),
	.adr(L1_selpc ? ip : L1_adr),
	.i(L1_dat),
	.o(insn),
	.fi(L1_flt),
	.fault(),
	.hit(L1_ihit),
	.invall(invic),
	.invline(L1_invline),
	.missadr(missadr)
);

L2_icache uic2
(
	.rst(rst_i),
	.clk(clk_i),
	.nxt(L2_nxt),
	.wr(L2_ld),
	.adr(L2_ld ? L2_adr : L1_adr),
	.cnt(L2_cnt),
	.exv_i(1'b0),
	.i(idat_i),
	.err_i(1'b0),
	.o(L2_dat),
	.hit(L2_ihita),
	.invall(invic),
	.invline(L1_invline)
);

ICController uicc1 (
  .rst_i(rst),
  .clk_i(clk),
  .missadr(missadr),
  .hit(L1_ihit),
  .bstate(5'd0),  // BIDLE
  .idle(),
	.invline(invline),
	.invlineAddr(),
	.icl_ctr(),
	.thread_en(1'b0),

	.ihitL2(L2_ihit),
	.L2_ld(L2_ld),
	.L2_cnt(L2_cnt),
	.L2_adr(L2_adr),
	.L2_dat(L2_dat),
	.L2_nxt(L2_nxt),

	.L1_selpc(L1_selpc),
	.L1_adr(L1_adr),
	.L1_dat(L1_dat),
	.L1_flt(L1_flt),
	.L1_wr(L1_wr),
	.L1_invline(L1_invline),
	.ROM_dat(ROM_dat),
	.isROM(isROM),
	.icnxt(L1_nxt),
	.icwhich(),
  
	.icl_o(),
	.cti_o(icti_o),
	.bte_o(ibte_o),
	.bok_i(ibok_i),
	.cyc_o(icyc_o),
	.stb_o(istb_o),
	.ack_i(iack_i),
	.err_i(1'b0),
	.tlbmiss_i(1'b0),
	.exv_i(1'b0),
	.sel_o(isel_o),
	.adr_o(iadr_o),
	.dat_i(idat_i)
);

bootrom ubr1 (
  .rst(rst),
  .clk(clk),
  .cs(1'b1),
  .adr0(L1_adr[13:4]),
  .o0(ROM_dat),
  .adr1(),
  .o1(),
  .adr2(),
  .o2()
);

reg M1;
wire [8:0] expat [0:3] =
	{9'b001_010_100,	// 11
	 9'b011_100_000,	// 10
	 9'b001_110_000,	// 01
	 9'b111_000_000		// 00
	 };
wire [8:0] expats = expat[insn[124:123]];
reg [8:0] expatx;
wire [8:0] nexpatx = expatx << 2'd3;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

wire [7:0] cnt0, cnt1, cnt2;
wire cntdone0;
wire cntdone1;
wire cntdone2;

muldivCnt umdc1 (rst, clk, state, p0, opcode0, funct70, cnt0, cntdone0);
muldivCnt umdc2 (rst, clk, state, p1, opcode1, funct71, cnt1, cntdone1);
muldivCnt umdc3 (rst, clk, state, p2, opcode2, funct72, cnt2, cntdone2);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Predicate logic
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [1:0] p [0:15];             // predicate register file
reg prfwr0, prfwr1, prfwr2;
reg [1:0] pres0, pres1, pres2;  // predicate result busses
wire po0;
wire po1;
wire po2;

function fnPcnd;
input [2:0] cnd;
input [1:0] p;
begin
	case(cnd)
	3'd0:	fnPcnd = p==2'b10;
	3'd1:	fnPcnd = 1'b1;
	3'd2:	fnPcnd = p==2'b00;
	3'd3:	fnPcnd = p!=2'b00;
	3'd4:	fnPcnd = p==2'b00 || p==2'b11;
	3'd5:	fnPcnd = p==2'b01;
	3'd6:	fnPcnd = p==2'b00 || p==2'b01;
	3'd7:	fnPcnd = p==2'b11;
	endcase
end
endfunction

always @(posedge clk)
if (rst) begin
	for (n = 0; n < 32; n = n + 1)
		p[n] <= 2'b00;
end
else begin
	if (prfwr0) p[ir0[9:6]] <= pres0;
	if (prfwr1) p[ir1[9:6]] <= pres1;
	if (prfwr2) p[ir2[9:6]] <= pres2;
	p[0] <= 2'b01;
end
assign po0 = fnPcnd(ir0[2:0],p[ir0[6:3]]);
assign po1 = fnPcnd(ir1[2:0],p[ir1[6:3]]) && ir0[40:34] != LDI && ir0[40:34] != JML;
assign po2 = fnPcnd(ir2[2:0],p[ir2[6:3]]);


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Machine cycle one.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk)
if (rst)
  M1 <= TRUE;
else begin
  M1 <= FALSE;
  if (state==ST_RUN && nexpatx==9'd0)
    M1 <= TRUE;
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk)
if (rst)
  expatx <= 9'b000_000_000;
else begin
  if (state==ST_RUN && nexpatx==9'd0)
  	expatx <= expats;
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// General purpose register file
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [WID-1:0] regfile [0:63];
reg rfwr0,rfwr1,rfwr2;
reg [WID-1:0] res0, res1, res2;
always @(posedge clk)
begin
	if (rfwr0) regfile[Rt0] <= res0;
	if (rfwr1) regfile[Rt1] <= res1;
	if (rfwr2) regfile[Rt2] <= res2;
end

wire [5:0] Ra0 = ir0[18:13]; wire [5:0] Rb0 = ir0[24:19]; wire [5:0] Rt0 = ir0[12:7];
wire [5:0] Ra1 = ir1[18:13]; wire [5:0] Rb1 = ir1[24:19]; wire [5:0] Rt1 = ir1[12:7];
wire [5:0] Ra2 = ir2[18:13]; wire [5:0] Rb2 = ir2[24:19]; wire [5:0] Rt2 = ir2[12:7];
wire [WID-1:0] a0 = Ra0==6'd0 ? 64'd0 : regfile[Ra0];
wire [WID-1:0] b0 = Rb0==6'd0 ? 64'd0 : regfile[Rb0];
wire [WID-1:0] s0 = Rt0==6'd0 ? 64'd0 : regfile[Rt0];
wire [WID-1:0] a1 = Ra1==6'd0 ? 64'd0 : regfile[Ra1];
wire [WID-1:0] b1 = Rb1==6'd0 ? 64'd0 : regfile[Rb1];
wire [WID-1:0] s1 = Rt1==6'd0 ? 64'd0 : regfile[Rt1];
wire [WID-1:0] a2 = Ra2==6'd0 ? 64'd0 : regfile[Ra2];
wire [WID-1:0] b2 = Rb2==6'd0 ? 64'd0 : regfile[Rb2];
wire [WID-1:0] s2 = Rt2==6'd0 ? 64'd0 : regfile[Rt2];

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Link Register
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [AMSB:0] lr [0:7];

always @(posedge clk)
// We don't really care what value is in the link register at reset, so let's
// not bother resetting it unless it's sim. Reset in sim to get rid of X's.
`ifdef SIM
if (rst) begin
  for (n = 0; n < 8; n = n + 1)
    lr[n] <= 64'hFFFFFFFFFFFC0000;
end else
`endif
begin
  if (state==ST_RUN) begin
    // Note instructions are evaluated in reverse order so that the first
    // branch encountered takes precednce.
    if (expatx[8] & po2)
  	  case(opcode2)
  	  LOOP: lr[ir2[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir2[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  LOOP: lr[ir1[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir1[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase
    if (expatx[6] & po0)
  	  case(opcode0)
  	  LOOP: lr[ir0[17:15]] <= ip + 5'd16;
  	  JMP:  lr[ir0[17:15]] <= ip + 5'd16;
  	  JML:  lr[ir0[17:15]] <= ip + 5'd16;
    	default:  ;
      endcase

    // Instructions are evaluated in order so that the last MTSPR takes
    // precedence if there are two writes to the same register.
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(ir0[40:34])
  	    MTSPR:  if (ir0[32:24]==9'b000_000_010) lr[ir0[23:21]] <= s0;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(ir1[40:34])
  	    MTSPR:  if (ir1[32:24]==9'b000_000_010) lr[ir1[23:21]] <= s1;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(ir2[40:34])
  	    MTSPR:  if (ir2[32:24]==9'b000_000_010) lr[ir2[23:21]] <= s2;
  	    default : ;
  	    endcase
    	default:  ;
      endcase
  end
end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Pointer
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reg [AMSB:0] ip;

always @(posedge clk)
if (rst)
  ip <= 64'hFFFFFFFFFFFC0000;
else begin
  if (state==ST_RUN) begin
  	if (nexpatx==9'd0)
  		ip[31:4] <= ip[31:4] + 28'd1;
  	if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
    		RET:	ip <= lr[ir2[20:18]] + ir2[32:21];
  	    default: ;
  	    endcase
  	  LOOP: ip <= {{40{ir2[40]}},ir2[40:21],4'h0} + lr[ir2[20:18]];
  	  JMP:  ip <= {{40{ir2[40]}},ir2[40:21],4'h0} + lr[ir2[20:18]];
    	default:  ;
      endcase
  	if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
    		RET:	ip <= lr[ir1[20:18]] + ir1[32:21];
  	    default: ;
  	    endcase
  	  LOOP: ip <= {{40{ir1[40]}},ir1[40:21],4'h0} + lr[ir1[20:18]];
  	  JMP:  ip <= {{40{ir1[40]}},ir1[40:21],4'h0} + lr[ir1[20:18]];
    	default:  ;
      endcase
  	if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
    		RET:	ip <= lr[ir0[20:18]] + ir0[32:21];
  	    default: ;
  	    endcase
  	  LOOP: ip <= {{40{ir0[40]}},ir0[40:21],4'h0} + lr[ir0[20:18]];
  	  JMP:  ip <= {{40{ir0[40]}},ir0[40:21],4'h0} + lr[ir0[20:18]];
    	JML:  ip <= {ir1,ir0[40:21],4'h0} + lr[ir0[20:18]];
    	default:  ;
      endcase
    ip[3:0] <= 4'h0;
  end
end


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Instruction Register
//
// On a control transfer the ir is nopped out so that subsequent instructions
// have no effect.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk)
if (rst)
	ir <= {5'b0,{3{NOP_INSN}}};
else begin
  if (state==ST_RUN) begin
  	if (nexpatx==9'd0)
  		ir <= insn;
    // Note instructions are evaluated in reverse order so that the first
    // branch encountered takes precednce.
    if (expatx[8] & po2)
  	  case(opcode2)
  	  R2:
  	    case(funct72)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[7] & po1)
  	  case(opcode1)
  	  R2:
  	    case(funct71)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
    if (expatx[6] & po0)
  	  case(opcode0)
  	  R2:
  	    case(funct70)
    		RET:	ir[122:0] <= {3{NOP_INSN}};
    		default:  ;
    	  endcase
  	  LOOP: ir[122:0] <= {3{NOP_INSN}};
  	  JMP:  ir[122:0] <= {3{NOP_INSN}};
  	  JML:  ir[122:0] <= {3{NOP_INSN}};
    	default:  ;
      endcase
  end
end


wire [63:0] imm0 = {{64{ir0[40]}},ir0[40:27]};
wire [63:0] imm1 = {{64{ir1[40]}},ir1[40:27]};
wire [63:0] imm2 = {{64{ir2[40]}},ir2[40:27]};

wire muli0 = opcode0==MUL; wire muli1 = opcode1==MUL; wire muli2 = opcode2==MUL;
wire mului0 = opcode0==MULU; wire mului1 = opcode1==MULU; wire mului2 = opcode2==MULU;
wire mulr0 = funct70==MUL; wire mulr1 = funct71==MUL; wire mulr2 = funct72==MUL;
wire mulur0 = funct70==MULU; wire mulur1 = funct71==MULU; wire mulur2 = funct72==MULU;
wire mul0, mulu0, div0, divu0;
wire mul1, mulu1, div1, divu1;
wire mul2, mulu2, div2, divu2;
assign mul0 = muli0|mulr0;
assign mulu0 = mului0|mulur0;
assign mul1 = muli1|mulr1;
assign mulu1 = mului1|mulur1;
assign mul2 = muli2|mulr2;
assign mulu2 = mului2|mulur2;
wire divi0 = opcode0==DIV; wire divi1 = opcode1==DIV; wire divi2 = opcode2==DIV;
wire divui0 = opcode0==DIVU; wire divui1 = opcode1==DIVU; wire divui2 = opcode2==DIVU;
wire divr0 = funct70==DIV; wire divr1 = funct71==DIV; wire divr2 = funct72==DIV;
wire divur0 = funct70==DIVU; wire divur1 = funct71==DIVU; wire divur2 = funct72==DIVU;
assign div0 = divi0|divr0;
assign divu0 = divui0|divur0;
assign div1 = divi1|divr1;
assign divu1 = divui1|divur1;
assign div2 = divi2|divr2;
assign divu2 = divui2|divur2;
wire [WID-1:0] prod0, quot0, produ0, quotu0;
wire [WID-1:0] prod1, quot1, produ1, quotu1;
wire [WID-1:0] prod2, quot2, produ2, quotu2;

Thor2020Mul umul0 (
  .CLK(clk),
  .A(a0),
  .B(muli0 ? imm0 : b0),
  .P(prod0)
);
Thor2020Mul umul1 (
  .CLK(clk),
  .A(a1),
  .B(muli1 ? imm1 : b1),
  .P(prod1)
);
Thor2020Mul umul2 (
  .CLK(clk),
  .A(a2),
  .B(muli1 ? imm2 : b2),
  .P(prod2)
);
Thor2020Mulu umulu0 (
  .CLK(clk),
  .A(a0),
  .B(mului0 ? imm0 : b0),
  .P(produ0)
);
Thor2020Mulu umulu1 (
  .CLK(clk),
  .A(a1),
  .B(mului1 ? imm1 : b1),
  .P(produ1)
);
Thor2020Mulu umulu2 (
  .CLK(clk),
  .A(a2),
  .B(mului1 ? imm2 : b2),
  .P(produ2)
);

divider udiv0 (
  .rst(rst),
  .clk(clk),
  .ld(ld0),
  .abort(1'b0),
  .sgn(divr0|divi0),
  .sgnus(1'b0),
  .a(a0),
  .b(divi0 ? imm0 : b0),
  .qo(quot0),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

divider udiv1 (
  .rst(rst),
  .clk(clk),
  .ld(ld1),
  .abort(1'b0),
  .sgn(divr1|divi1),
  .sgnus(1'b0),
  .a(a1),
  .b(divi1 ? imm1 : b1),
  .qo(quot1),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

divider udiv2 (
  .rst(rst),
  .clk(clk),
  .ld(ld2),
  .abort(1'b0),
  .sgn(divr2|divi2),
  .sgnus(1'b0),
  .a(a2),
  .b(divi2 ? imm2 : b2),
  .qo(quot2),
  .ro(),
  .dvByZr(),
  .done(),
  .idle()
);

function [47:0] fnDisassem;
input [40:0] iri;
begin
  case(iri[14:8])
  R2:
    case(iri[40:34])
    ADD:  fnDisassem = "ADDI  ";
    AND:  fnDisassem = "ANDI  ";
    OR:   fnDisassem = "ORI   ";
    RET:  fnDisassem = "RET   ";
    LDD:  fnDisassem = "LDDX  ";
    STD:  fnDisassem = "STDX  ";
    default:  fnDisassem = "????? ";
    endcase
  ADD:  fnDisassem = "ADDI  ";
  AND:  fnDisassem = "ANDI  ";
  OR:   fnDisassem = "ORI   ";
  JMP:  fnDisassem = "JMP   ";
  LDD:  fnDisassem = "LDD   ";
  STD:  fnDisassem = "STD   ";
  default:  fnDisassem = "????? ";
  endcase
end
endfunction

function [23:0] fnDisPcnd;
input [3:0] rn;
input [2:0] cnd;
begin
  if (|rn)
    case(cnd)
    3'd0: fnDisPcnd = ".un";
    3'd1: fnDisPcnd = ".??";
    3'd2: fnDisPcnd = ".eq";
    3'd3: fnDisPcnd = ".ne";
    3'd4: fnDisPcnd = ".lt";
    3'd5: fnDisPcnd = ".ge";
    3'd6: fnDisPcnd = ".le";
    3'd7: fnDisPcnd = ".gt";
    endcase
  else
    fnDisPcnd = "   ";
end
endfunction

function [23:0] fnPreg;
input [3:0] rn;
begin
  if (|rn)
    case(rn)
    4'd0: fnPreg = " p0";
    4'd1: fnPreg = " p1";
    4'd2: fnPreg = " p2";
    4'd3: fnPreg = " p3";
    4'd4: fnPreg = " p4";
    4'd5: fnPreg = " p5";
    4'd6: fnPreg = " p6";
    4'd7: fnPreg = " p7";
    4'd8: fnPreg = " p8";
    4'd9: fnPreg = " p9";
    4'd10: fnPreg = "p10";
    4'd11: fnPreg = "p11";
    4'd12: fnPreg = "p12";
    4'd13: fnPreg = "p13";
    4'd14: fnPreg = "p14";
    4'd15: fnPreg = "p15";
    endcase
  else
    fnPreg = "   ";
end
endfunction

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

always @(posedge clk)
if (rst) begin
	state <= ST_RUN;
	rfwr0 = 1'b0; prfwr0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 1'b0;
	wr <= 1'b0;
	ld0 <= 1'b0; ld1 <= 1'b0; ld2 <= 1'b0;
end
else begin
	rfwr0 = 1'b0; prfwr0 = 1'b0;
	rfwr1 = 1'b0; prfwr1 = 1'b0;
	rfwr2 = 1'b0; prfwr2 = 1'b0;
	ld0 <= 1'b0; ld1 <= 1'b0; ld2 <= 1'b0;
	case(state)
	ST_RUN: 
	  begin
  		if (expatx[8] & po2) tExec(ir2,a0,b0,s0,res0,pres0,rfwr2,prfwr2,ld2,ST_LD2);
  		if (expatx[7] & po1) tExec(ir1,a1,b1,s1,res1,pres1,rfwr1,prfwr1,ld1,ST_LD1);
  		if (expatx[6] & po0) tExec(ir0,a2,b2,s2,res2,pres2,rfwr0,prfwr0,ld0,ST_LD0);
  		if (ir0[40:34]==LDI) begin if (po0) begin res0 = {ir1,ir0[33:12]}; rfwr0 = 1'b1; end end
  		else if (ir1[40:34]==LDI) begin if (po1) begin res1 = {ir2,ir1[33:12]}; rfwr1 = 1'b1; end end
		end
	ST_LD0:	if (rdy) begin res0 = dati; rfwr0 = 1'b1; state <= ST_RUN; end
	ST_LD1:	if (rdy) begin res1 = dati; rfwr1 = 1'b1; state <= ST_RUN; end
	ST_LD2:	if (rdy) begin res2 = dati; rfwr2 = 1'b1; state <= ST_RUN; end
	ST_ST:	if (rdy) begin state <= ST_RUN; wr <= 1'b0; end
	ST_MULDIV:
	  if (cntdone0&cntdone1&cntdone2) begin
	    state <= ST_RUN;
	    case({mul0,mulu0,div0,divu0})
	    4'b1???:  begin res0 <= prod0;  rfwr0 <= 1'b1; end
	    4'b01??:  begin res0 <= produ0; rfwr0 <= 1'b1; end
	    4'b001?:  begin res0 <= quot0;  rfwr0 <= 1'b1; end
	    4'b0001:  begin res0 <= quot0;  rfwr0 <= 1'b1; end
	    endcase
	    case({mul1,mulu1,div1,divu1})
	    4'b1???:  begin res0 <= prod1;  rfwr1 <= 1'b1; end
	    4'b01??:  begin res0 <= produ1; rfwr1 <= 1'b1; end
	    4'b001?:  begin res0 <= quot1;  rfwr1 <= 1'b1; end
	    4'b0001:  begin res0 <= quot1;  rfwr1 <= 1'b1; end
	    endcase
	    case({mul2,mulu2,div2,divu2})
	    4'b1???:  begin res0 <= prod2;  rfwr2 <= 1'b1; end
	    4'b01??:  begin res0 <= produ2; rfwr2 <= 1'b1; end
	    4'b001?:  begin res0 <= quot2;  rfwr2 <= 1'b1; end
	    4'b0001:  begin res0 <= quot2;  rfwr2 <= 1'b1; end
	    endcase
	  end
	default:	state <= ST_RUN;
	endcase
	$display("------------------------------------");
	$display("ip: %h  ir: %h", ip, ir);
	$display("%c%h %s%s %s %h %h %h %h", ir[123]?"S":"-",ir0,fnPreg(ir0[7:4]),fnDisPcnd(ir0[7:4],ir0[3:1]),fnDisassem(ir0),imm0, s0, a0, b0);
	$display("%c%h %s%s %s %h %h %h %h", ir[124]?"S":"-",ir1,fnPreg(ir1[7:4]),fnDisPcnd(ir1[7:4],ir1[3:1]),fnDisassem(ir1),imm1, s1, a1, b1);
	$display("%c%h %s%s %s %h %h %h %h", ir[125]?"S":"-",ir2,fnPreg(ir2[7:4]),fnDisPcnd(ir2[7:4],ir2[3:1]),fnDisassem(ir2),imm2, s2, a2, b2);
end

task tCmp;
input [WID-1:0] a;
input [WID-1:0] b;
output [1:0] o;
output prfwr;
reg [WID:0] sum;
begin
  if ($signed(a) < $signed(b))
    o = 2'b11;
  else if (a==b)
    o = 2'b00;
  else
    o = 2'b01;
	prfwr = 1'b1;
end
endtask

task tCmpu;
input [WID-1:0] a;
input [WID-1:0] b;
output [1:0] o;
output prfwr;
reg [WID:0] sum;
begin
  if (a < b)
    o = 2'b11;
  else if (a==b)
    o = 2'b00;
  else
    o = 2'b01;
	prfwr = 1'b1;
end
endtask

task tAlu;
input [7:0] op;
input [WID-1:0] a;
input [WID-1:0] b;
output [WID-1:0] res;
output rfwr;
output ld;
begin
	case(op)
	ADD:	begin res = a + b; rfwr = 1'b1; end
	SUB:	begin res = a - b; rfwr = 1'b1; end
	AND:	begin res = a & b; rfwr = 1'b1; end
	OR:		begin res = a | b; rfwr = 1'b1; end
	XOR:	begin res = a ^ b; rfwr = 1'b1; end
//	MUL:	begin res <= $signed(a) * $signed(b); rfwr = 1'b1; end
//	MULU: begin res <= a * b; rfwr = 1'b1; end
	MUL:  begin state <= ST_MULDIV; end
	MULU: begin state <= ST_MULDIV; end
	DIV:  begin state <= ST_MULDIV; ld <= 1'b1; end
	DIVU: begin state <= ST_MULDIV; ld <= 1'b1; end
	SHL:	begin res = a << b[5:0]; rfwr = 1'b1; end
	SHR:	begin res = a >> b[5:0]; rfwr = 1'b1; end
	ASR:	begin res = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	SHLI:	begin res = a << b[5:0]; rfwr = 1'b1; end
	SHRI:	begin res = a >> b[5:0]; rfwr = 1'b1; end
	ASRI:	begin res = a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; rfwr = 1'b1; end
	default:	;
	endcase
end endtask

task tExec;
input [40:0] irx;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] s;
output [WID-1:0] res;
output [1:0] pres;
output rfwr;
output prfwr;
output ld;
input [3:0] st;
reg [WID-1:0] imm;
begin
	imm = {{64{irx[40]}},irx[40:27]};
	casez(irx[6:0])
	RR:
		casez(irx[40:34])
		CMP:	if (irx[20]) tCmp(a,b,pres,prfwr); else tCmpu(a,b,pres,prfwr);
		SHLI: tAlu(irx[40:34],a,imm,res,rfwr,ld);
		SHRI: tAlu(irx[40:34],a,imm,res,rfwr,ld);
		ASRI: tAlu(irx[40:34],a,imm,res,rfwr,ld);
		MFSPR:
		  case(irx[32:21])
		  12'h010,12'h011,12'h012,12'h013,12'h014,12'h015,12'h016,12'h017:  begin res <= lr[irx[23:21]]; rfwr <= 1'b1; end
		  default:  ;
		  endcase
		MTSPR:
		  case(irx[32:21])
		  default:  ;
		  endcase
		default:	tAlu(irx[40:34],a,b,res,rfwr,ld);
		endcase
	LD:		begin ad <= a + imm; state <= st; end
	ST:		begin ad <= a + {{48{irx[33]}},irx[33:24],irx[11:6]}; dato <= s; wr <= 1'b1; state <= ST_ST; end
	CMPI:	if (irx[20]) tCmp(a,imm,pres,prfwr); else tCmpu(a,imm,pres,prfwr);
	default:	tAlu(irx[6:0],a,imm,res,rfwr,ld);
	endcase
end
endtask

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module muldivCnt(rst, clk, state, p, opcode, funct, cnt, done);
input rst;
input clk;
input [5:0] state;
input p;
input [6:0] opcode;
input [6:0] funct;
output reg [7:0] cnt;
output done;
parameter ST_RUN = 6'd2;
parameter ST_MULDIV = 6'd7;
parameter R2=7'd2,MUL=7'd24,MULU=7'd25,DIV=7'd26,DIVU=7'd27;

assign done = cnt[7];
always @(posedge clk)
if (rst)
  cnt <= 8'hFF;
else begin
  case(state)
  ST_RUN:
    begin
      if (p) begin
        case(opcode)
        R2:
          case(funct)
          MUL:  cnt <= 8'd20;
          MULU: cnt <= 8'd20;
          DIV:  cnt <= 8'd68;
          DIVU: cnt <= 8'd68;
          endcase
        MUL:  cnt <= 8'd20;
        MULU: cnt <= 8'd20;
        DIV:  cnt <= 8'd68;
        DIVU: cnt <= 8'd68;
        endcase
      end
    end
  ST_MULDIV:  if (!done) cnt <= cnt - 8'd1;
  endcase
end

endmodule
