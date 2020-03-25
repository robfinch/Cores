module FTIA64(rst,clk,ip,insn,wr,rdy,ad,dato,dati);
parameter WID=64;
input rst; input clk; output reg [31:0] ip; input [127:0] insn; output reg wr; input rdy; output reg [24:0] ad; output reg [63:0] dato;
input [63:0] dati;
parameter ST_FETCH=3'd1,ST_RUN = 3'd2,ST_LD0=3'd3,ST_LD1=3'd4,ST_LD2=3'd5,ST_ST=3'd6;
parameter RR=5'b00010,ADDI = 5'b00100,ANDI=5'b01000,ORI=5'b01001,XORI=5'b01010,ADD=8'b00000100,SUB=8'b00000101,AND=8'b00001000,
OR=8'b00001001,XOR=8'b00001010,MUL=8'b00001011;
parameter LD=7'b101????,ST=7'b110????,JMP=7'd78,JML=7'd79,LDI=7'd77;
parameter Cxx =8'b1111????,RET=8'b10000000,NOP=8'b11101010,SHL=8'b00010000,SHR=8'b00010001,ASR=8'b00010010;
parameter Cxxi=5'b11???,CEQ=4'd0,CNE=4'd1,CLT=4'd4,CGE=4'd5,CLE=4'd6,CGT=4'd7,CLTU=4'd8,CGEU=4'd9,CLEU=4'd10,CGTU=4'd11,CADC=4'd12,COFL=4'd13,COD=4'd14;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
reg [24:0] ip; reg [31:0] lr [0:7]; reg [15:0] p; reg prfwr0, prfwr1, prfwr2; reg pres0, pres1, pres2; reg [31:0] regfile [0:31]; reg[63:0] res0, res1, res2;
reg [2:0] state;
reg [127:0] ir;
wire [40:0] ir0 = ir[40:0]; wire [40:0] ir1 = ir[81:41]; wire [40:0] ir2 = ir[122:82]; wire [2:0] irb = ir[125:123];
reg [2:0] ex;
wire po0 = p[ir0[5:0]];
wire po1 = p[ir1[5:0]]; 
wire po2 = p[ir2[5:0]]; 
always @(posedge clk)
if (rst)
	p <= 16'h0001;
else begin
	if (prfwr0) p[ir0[11:6]] <= pres0;
	if (prfwr1) p[ir1[11:6]] <= pres1;
	if (prfwr2) p[ir2[11:6]] <= pres2;
	p[0] <= 1'b1;
end
wire [5:0] Ra0 = ir0[17:12]; wire [5:0] Rb0 = ir0[23:18]; wire [5:0] Rt0 = ir0[11:6];
wire [5:0] Ra1 = ir1[17:12]; wire [5:0] Rb1 = ir1[23:18]; wire [5:0] Rt1 = ir1[11:6];
wire [5:0] Ra2 = ir2[17:12]; wire [5:0] Rb2 = ir2[23:18]; wire [5:0] Rt2 = ir2[11:6];
wire [WID-1:0] a0 = Ra0==6'd0 ? 64'd0 : regfile[Ra0]; wire [63:0] b0 = Rb0==6'd0 ? 64'd0 : regfile[Rb0]; wire [63:0] s0 = Rt0==6'd0 ? 64'd0 : regfile[Rt0];
wire [WID-1:0] a1 = Ra1==6'd0 ? 64'd0 : regfile[Ra1]; wire [63:0] b1 = Rb1==6'd0 ? 64'd0 : regfile[Rb1]; wire [63:0] s1 = Rt1==6'd0 ? 64'd0 : regfile[Rt1];
wire [WID-1:0] a2 = Ra2==6'd0 ? 64'd0 : regfile[Ra2]; wire [63:0] b2 = Rb2==6'd0 ? 64'd0 : regfile[Rb2]; wire [63:0] s2 = Rt2==6'd0 ? 64'd0 : regfile[Rt2];
wire [8:0] expat [0:3] =
	{9'b001_010_100,	// 11
	 9'b011_100_000,	// 10
	 9'b001_110_000,	// 01
	 9'b111_000_000		// 00
	 };
wire [8:0] expats = expat[insn[124:123]];
reg [8:0] expatx;
wire [8:0] nexpatx = expatx << 2'd3;
reg rfwr0,rfwr1,rfwr2;
always @(posedge clk)
begin
	if (rfwr0) regfile[Rt0] <= res0;
	if (rfwr1) regfile[Rt1] <= res1;
	if (rfwr2) regfile[Rt2] <= res2;
end
always @(posedge clk)
if (rst) begin
	ir <= NOP_INSN; state <= ST_RUN;
	ip <= 25'd0;
	rfwr0 <= 1'b0; prfwr0 <= 1'b0;
	rfwr1 <= 1'b0; prfwr1 <= 1'b0;
	rfwr2 <= 1'b0; prfwr2 <= 1'b0;
	wr <= 1'b0;
	expatx <= 9'd0;
end
else begin
	rfwr0 <= 1'b0; prfwr0 <= 1'b0;
	rfwr1 <= 1'b0; prfwr1 <= 1'b0;
	rfwr2 <= 1'b0; prfwr2 <= 1'b0;
	expatx <= nexpatx;
	if (nexpatx==9'd0) begin
		ir <= insn;
		ip <= ip + 32'd16;
		expatx <= expats;
	end
	case(state)
//	ST_FETCH: if (rdy) begin ir <= insn; state <= ST_RUN; end
	ST_RUN: begin state <= ST_RUN;
		if (expatx[8]) tExec(ir2,po2 && ((ir1[40:34] != LDI && ir1[40:34] != JML) || (ir0[40:34]==LDI || ir0[40:34]==JML)),a0,b0,s0,res0,pres0,rfwr2,prfwr2,ST_LD2);
		if (expatx[7]) tExec(ir1,po1 && ir0[40:34] != LDI && ir0[40:34] != JML,a1,b1,s1,res1,pres1,rfwr1,prfwr1,ST_LD1);
		if (expatx[6]) tExec(ir0,po0,a2,b2,s2,res2,pres2,rfwr0,prfwr0,ST_LD0);
		if (ir0[40:34]==LDI) begin if (po1) begin res0 <= {ir1,ir0[33:12]}; rfwr0 <= 1'b1; end end
		else if (ir1[40:34]==LDI) begin if (po1) begin res1 <= {ir2,ir1[33:12]}; rfwr1 <= 1'b1; end end
		if (ir0[40:34]==JML) begin if (po0) begin ir[122:0] <= {3{NOP_INSN}}; ip <= {ir1,ir0[33:10],4'h0}; lr[ir0[8:6]] <= ip + 5'd16; end end
		else if (ir1[40:34]==JML) begin if (po1) begin ir[122:0] <= {3{NOP_INSN}}; ip <= {ir2,ir1[33:10],4'h0}; lr[ir1[8:6]] <= ip + 5'd16; end end
		end
	ST_LD0:	if (rdy) begin res0 <= dati; rfwr0 <= 1'b1; state <= ST_RUN; end
	ST_LD1:	if (rdy) begin res1 <= dati; rfwr1 <= 1'b1; state <= ST_RUN; end
	ST_LD2:	if (rdy) begin res2 <= dati; rfwr2 <= 1'b1; state <= ST_RUN; end
	ST_ST:	if (rdy) begin state <= ST_RUN; wr <= 1'b0; end
	default:	state <= ST_RUN;
	endcase
end

task tCmp;
input [3:0] op;
input po;
input [WID-1:0] a;
input [WID-1:0] b;
output [WID-1:0] o;
output prfwr;
reg [WID:0] sum;
begin
	case(op)
	CEQ:	begin o <= a==b; prfwr <= po; end CNE: begin o <= a!=b; prfwr <= po; end
	CLT:	begin o <= $signed(a) <  $signed(b); prfwr <= po; end CGE: begin o <= $signed(a) >= $signed(b); prfwr <= po; end
	CLE:	begin o <= $signed(a) <= $signed(b); prfwr <= po; end CGT: begin o <= $signed(a) >  $signed(b); prfwr <= po; end
	CLTU:	begin o <= a <  b; prfwr <= po; end CGEU: begin o <= a >= b; prfwr <= po; end
	CLEU:	begin o <= a <= b; prfwr <= po; end CGTU: begin o <= a >  b; prfwr <= po; end
	CADC:	begin sum = a + b; o <= sum[WID]; prfwr <= po; end COD: begin sum = a + b; o <= sum[0]; prfwr <= po; end
	endcase
end
endtask

task tAlu;
input [7:0] op;
input [WID-1:0] a;
input [WID-1:0] b;
output [WID-1:0] res;
output rfwr;
begin
	case(op)
	ADD:	begin res <= a + b; rfwr <= 1'b1; end
	SUB:	begin res <= a - b; rfwr <= 1'b1; end
	AND:	begin res <= a & b; rfwr <= 1'b1; end
	OR:		begin res <= a | b; rfwr <= 1'b1; end
	XOR:	begin res <= a ^ b; rfwr <= 1'b1; end
//	MUL:	begin res <= $signed(a) * $signed(b); end
	SHL:	begin res <= a << b[5:0]; rfwr <= 1'b1; end
	SHR:	begin res <= a >> b[5:0]; rfwr <= 1'b1; end
	ASR:	begin res <= a[WID-1] ? (a >> b[5:0]) | (~({WID{1'b1}} >> b[5:0])) : a >> b[5:0]; end
	default:	;
	endcase
end endtask

task tExec;
input [40:0] irx;
input po;
input [WID-1:0] a;
input [WID-1:0] b;
input [WID-1:0] s;
output [WID-1:0] res;
output pres;
output rfwr;
output prfwr;
input [2:0] st;
reg [WID-1:0] imm;
begin
	imm = {{64{irx[33]}},irx[33:18]};
	casez(irx[40:34])
	RR:
		casez(irx[33:27])
		RET:	if (po) begin ip <= lr; ir[122:0] <= {3{NOP_INSN}}; end
		Cxx:	if (po) tCmp(irx[30:27],po,a,b,pres,prfwr);
		default:	if (po) tAlu(irx[33:27],a,b,res,rfwr);
		endcase
	LD:		if (po) begin ad <= a + imm; state <= st; end
	ST:		if (po) begin ad <= a + {{48{irx[33]}},irx[33:24],irx[11:6]}; dato <= s; wr <= 1'b1; state <= ST_ST; end
	ADDIS1:	if (po) begin res <= s + {{42{irx[33]}},irx[33:12],16'd0}; rfwr <= 1'b1; end
	ADDIS2:	if (po) begin res <= s + {{20{irx[33]}},irx[33:12],38'd0}; rfwr <= 1'b1; end
	ADDIS3:	if (po) begin res <= s + {irx[31:12],60'd0}; rfwr <= 1'b1; end
	JMP:	if (po) begin ir[122:0] <= {3{NOP_INSN}}; ip <= {irx[21:0],4'h0}; if (irx[22]) lr <= ip + 3'd4; end
	Cxxi:	if (po) tCmp(irx[25:22],po,a,imm,pres,prfwr);
	default:	if (po) tAlu({3'd0,irx[27:23]},a,imm,res,rfwr);
	endcase
end
endtask

endmodule
