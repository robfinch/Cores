module FT20200324(rst,clk,ip,insn,wr,rdy,ad,dato,dati); parameter WID=32;
input rst; input clk; output reg [24:0] ip; input [31:0] insn; output reg wr; input rdy; output reg [24:0] ad;
output reg [31:0] dato; input [31:0] dati;
parameter ST_FETCH=3'd1,ST_RUN = 3'd2,ST_LD=3'd3,ST_ST=3'd4,ST_RET=3'd5;
parameter R=5'd0,RR=5'd2,ADDI = 5'd4,ANDI=5'd8,ORI=5'd9,XORI=5'd10,
ADD=8'd4,SUB=8'd5,AND=8'd8,OR=8'd9,XOR=8'd10,ANDCM=8'd11,NAND=8'd12,NOR=8'd13,ENOR=8'd14,ORCM=8'd15,MUL=8'd19;
parameter LD=5'b10000,ST=5'b10001,JMP =5'b10110,JSR=5'b10111,ADDIS=5'b1001?;
parameter Cxx =8'b1111????,RET=8'b10000000,NOP=8'b11101010,SHL=8'b00010000,SHR=8'b00010001,ASR=8'b00010010;
parameter Cxxi=5'b11???,CEQ=4'd0,CNE=4'd1,CLT=4'd4,CGE=4'd5,CLE=4'd6,CGT=4'd7,CLTU=4'd8,CGEU=4'd9,CLEU=4'd10,CGTU=4'd11,
CADC=4'd12,COFL=4'd13,COD=4'd14;
parameter NOP_INSN = 32'b000_00000_00000_00000_000000_1110_1010;
reg [15:0] p; reg prfwr; reg prfwrs; reg pres; reg [31:0] regfile [0:31]; reg rfwr; reg[31:0] res; reg[31:0] sp;
reg [2:0] state; reg [31:0] ir; wire po = p[ir[31:28]];
always @(posedge clk)	if (rst) p <= 16'h0001; else begin if (prfwr) p[ir[22:19]] <= pres;
	if (prfwrs) begin p[0] <= s[3:0]; p[1] <= s[7:4]; p[2] <= s[11:8]; p[3] <= s[15:12]; p[4] <= s[19:16]; p[5] <= s[23:20];
										p[6] <= s[27:24]; p[7] <= s[31:28]; end p[0] <= 1'b1; end
wire [4:0] Ra = ir[18:14]; wire [4:0] Rb = ir[13:9]; wire [4:0] Rt = ir[23:19];
wire [WID-1:0] a = Ra==5'd0 ? 32'd0 : Ra==5'd31 ? sp : regfile[Ra];
wire [WID-1:0] b = Rb==5'd0 ? 32'd0 : Rb==5'd31 ? sp : regfile[Rb];
wire [WID-1:0] s = Rt==5'd0 ? 32'd0 : Rt==5'd31 ? sp : regfile[Rt];
wire [WID-1:0] imm = {{19{ir[12]}},ir[12:0]};
always @(posedge clk)	if (rfwr) regfile[Rt] <= res;
always @(posedge clk)
if (rst) begin
	ir <= NOP_INSN; state <= ST_RUN; ip <= 25'd0;
	rfwr <= 1'b0; prfwr <= 1'b0; prfwra <= 1'b0; wr <= 1'b0;
end
else begin
	rfwr <= 1'b0; prfwr <= 1'b0; prfwra <= 1'b0; if (rfwr && Rt==5'd31) sp <= res;
	ip <= ip + 25'd4;	ir <= insn;
	case(state)
	ST_RUN: begin state <= ST_RUN;
		casez(ir[27:23])
		R:
			case(ir[7:0])
			MFSPR:
				case(ir[17:12])
				6'd0:	begin res <= {p[7],p[6],p[5],p[4],p[3],p[2],p[1],p[0]}; rfwr <= 1'b1; end
				default:	;
				endcase
			MTSPR:
				case(ir[17:12])
				6'd0: begin prfwrs <= 1'b1; end
				default:	;
				endcase
			endcase
		RR:
			casez(ir[7:0])
			RET:	if (po) begin ad <= s; ir <= NOP_INSN; res <= s + {Ra,Rb,2'b00}; rfwr <= 1'b1; state <= ST_RET; end
			Cxx:	if (po) tCmp(ir[25:22],po,a,b,pres);
			default:	if (po) tAlu(ir[7:0],a,b,res);
			endcase
		LD:		if (po) begin ad <= a + imm; state <= ST_LD; end
		ST:		if (po) begin ad <= a + {{19{ir[27]}},ir[27:23],ir[8:0]}; dato <= s; wr <= 1'b1; state <= ST_ST; end
		ADDIS:if (po) begin res <= s + {ir[27],ir[17:0],13'd0}; rfwr <= 1'b1; end
		JMP:	if (po) begin ir <= NOP_INSN; ip <= {ir[22:0],2'b00}; end
		JSR:	if (po) begin ir <= NOP_INSN; ip <= {ir[22:0],2'b00}; sp <= sp - 3'd4; ad <= sp - 3'd4;
			dato <= ip + 3'd4; wr <= 1'b1; state <= ST_ST; end
		Cxxi:	if (po) tCmp(ir[25:22],po,a,imm,pres);
		default:	if (po) tAlu({3'd0,ir[27:23]},a,imm,res);
		endcase end
	ST_LD:	if (rdy) begin res <= dati; rfwr <= 1'b1; state <= ST_RUN; end
	ST_RET:	if (rdy) begin ip <= dati; state <= ST_RUN; end
	ST_ST:	if (rdy) begin state <= ST_RUN; wr <= 1'b0; end
	default:	state <= ST_RUN;
	endcase
end
task tCmp;
input [3:0] op; input po;
input [WID-1:0] a; input [WID-1:0] b;
output o;
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
end endtask
task tAlu;
input [7:0] op;
input [WID-1:0] a; input [WID-1:0] b;
output [WID-1:0] o;
begin
	case(op)
	ADD:	begin res <= a + b; rfwr <= 1'b1; end	SUB:	begin res <= a - b; rfwr <= 1'b1; end
	AND:	begin res <= a & b; rfwr <= 1'b1; end	OR:	begin res <= a | b; rfwr <= 1'b1; end	XOR: begin res <= a ^ b; rfwr <= 1'b1; end
	ANDCM:	begin res <= a & ~b; rfwr <= 1'b1; end
	NAND:	begin res <= ~(a & b); rfwr <= 1'b1; end NOR:	begin res <= ~(a | b); rfwr <= 1'b1; end
	XNOR:	begin res <= ~(a ^ b); rfwr <= 1'b1; end ORCM: begin res <= a | ~b; rfwr <= 1'b1; end
//	MUL:	begin res <= $signed(a) * $signed(b); end
	SHL:	begin res <= a << b[4:0]; rfwr <= 1'b1; end	SHR:	begin res <= a >> b[4:0]; rfwr <= 1'b1; end
	ASR:	begin res <= a[WID-1] ? (a >> b[4:0]) | (~({WID{1'b1}} >> b[4:0])) : a >> b[4:0]; rfwr <= 1'b1; end
	default:	;
	endcase
end endtask
endmodule
