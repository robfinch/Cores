module FT20200324(rst,clk,ip,insn,wr,rdy,ad,dato,dati);
input rst; input clk; output reg [24:0] ip; input [31:0] insn; output reg wr; input rdy; output reg [24:0] ad; output reg [31:0] dato;
input [31:0] dati;
parameter ST_FETCH=3'd1,ST_RUN = 3'd2,ST_LD=3'd3,ST_ST=3'd4;
parameter RR=5'b00010,ADDI = 5'b00100,ANDI=5'b01000,ORI=5'b01001,XORI=5'b01010,ADD=8'b00000100,SUB=8'b00000101,AND=8'b00001000,
OR=8'b00001001,XOR=8'b00001010,MUL=8'b00001011;
parameter LD=5'b10000,ST=5'b10001,JMP =5'b10111,ADDIS=5'b1001?;
parameter Cxx =8'b1111????,RET=8'b10000000,NOP=8'b11101010,SHL=8'b00010000,SHR=8'b00010001,ASR=8'b00010010;
parameter Cxxi=5'b11???,CEQ=4'd0,CNE=4'd1,CLT=4'd4,CGE=4'd5,CLE=4'd6,CGT=4'd7,CLTU=4'd8,CGEU=4'd9,CLEU=4'd10,CGTU=4'd11,CADC=4'd12,COFL=4'd13,COD=4'd14;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
reg [24:0] ip; reg [24:0] lr; reg [15:0] p; reg prfwr; reg pres; reg [31:0] regfile [0:31]; reg rfwr; reg[31:0] res;
reg [2:0] state; reg [31:0] ir; wire po = p[ir[31:28]];
always @(posedge clk)	if (rst) p <= 16'h0001; else begin if (prfwr) p[ir[22:19]] <= pres; p[0] <= 1'b1; end
wire [4:0] Ra = ir[18:14]; wire [4:0] Rb = ir[13:9]; wire [4:0] Rt = ir[23:19];
wire [31:0] a = Ra==5'd0 ? 32'd0 : regfile[Ra]; wire [31:0] b = Rb==5'd0 ? 32'd0 : regfile[Rb]; wire [31:0] s = Rt==5'd0 ? 32'd0 : regfile[Rt];
wire [31:0] imm = {{19{ir[12]}},ir[12:0]};
always @(posedge clk)	if (rfwr) regfile[Rt] <= res;
always @(posedge clk)
if (rst) begin
	ir <= NOP_INSN; state <= ST_RUN;
	ip <= 25'd0;
	rfwr <= 1'b0; prfwr <= 1'b0;
	wr <= 1'b0;
end
else begin
	rfwr <= 1'b0; prfwr <= 1'b0;
	ip <= ip + 25'd4;	ir <= insn;
	case(state)
//	ST_FETCH: if (rdy) begin ir <= insn; state <= ST_RUN; end
	ST_RUN: begin state <= ST_RUN;
		casez(ir[28:24])
		RR:
			casez(ir[7:0])
			RET:	if (po) begin ip <= lr; ir <= NOP_INSN; end
			Cxx:	if (po) tCmp(ir[25:22],po,a,b,pres);
			default:	if (po) tAlu(ir[7:0],a,b,res);
			endcase
		LD:		if (po) begin ad <= a + imm; state <= ST_LD; end
		ST:		if (po) begin ad <= a + {{19{ir[27]}},ir[27:23],ir[8:0]}; dato <= s; wr <= 1'b1; state <= ST_ST; end
		ADDIS:if (po) begin res <= s + {ir[27],ir[17:0],13'd0}; rfwr <= 1'b1; end
		JMP:	if (po) begin ir <= NOP_INSN; ip <= {ir[21:0],2'b00}; if (ir[22]) lr <= ip + 3'd4; end
		Cxxi:	if (po) tCmp(ir[25:22],po,a,imm,pres);
		default:	if (po) tAlu({3'd0,ir[27:23]},a,imm,res);
		endcase end
	ST_LD:	if (rdy) begin res <= dati; rfwr <= 1'b1; state <= ST_RUN; end
	ST_ST:	if (rdy) begin state <= ST_RUN; wr <= 1'b0; end
	default:	state <= ST_RUN;
	endcase
end
task tCmp;
input [3:0] op;
input po;
input [31:0] a;
input [31:0] b;
output o;
reg [32:0] sum;
begin
	case(op)
	CEQ:	begin o <= a==b; prfwr <= po; end CNE: begin o <= a!=b; prfwr <= po; end
	CLT:	begin o <= $signed(a) <  $signed(b); prfwr <= po; end CGE: begin o <= $signed(a) >= $signed(b); prfwr <= po; end
	CLE:	begin o <= $signed(a) <= $signed(b); prfwr <= po; end CGT: begin o <= $signed(a) >  $signed(b); prfwr <= po; end
	CLTU:	begin o <= a <  b; prfwr <= po; end CGEU: begin o <= a >= b; prfwr <= po; end
	CLEU:	begin o <= a <= b; prfwr <= po; end CGTU: begin o <= a >  b; prfwr <= po; end
	CADC:	begin sum = a + b; o <= sum[32]; prfwr <= po; end COD: begin sum = a + b; o <= sum[0]; prfwr <= po; end
	endcase
end endtask
task tAlu;
input [7:0] op;
input [31:0] a;
input [31:0] b;
output [31:0] o;
begin
	case(op)
	ADD:	begin res <= a + b; rfwr <= 1'b1; end
	SUB:	begin res <= a - b; rfwr <= 1'b1; end
	AND:	begin res <= a & b; rfwr <= 1'b1; end
	OR:		begin res <= a | b; rfwr <= 1'b1; end
	XOR:	begin res <= a ^ b; rfwr <= 1'b1; end
//	MUL:	begin res <= $signed(a) * $signed(b); end
	SHL:	begin res <= a << b[4:0]; rfwr <= 1'b1; end
	SHR:	begin res <= a >> b[4:0]; rfwr <= 1'b1; end
	ASR:	begin res <= a[31] ? (a >> b[4:0]) | (~(32'hFFFFFFFF >> b[4:0])) : a >> b[4:0]; end
	default:	;
	endcase
end endtask
endmodule
