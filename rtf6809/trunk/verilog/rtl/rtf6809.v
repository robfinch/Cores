`include "rtf6809_defines.v"

module rtf6809(rst_i, clk_i, halt_i, nmi_i, irq_i, firq_i, ba_o, bs_o, pc, insn);
input rst_i;
input clk_i;
input halt_i;
input nmi_i;
input irq_i;
input firq_i;
output reg ba_o;
output reg bs_o;
output reg [15:0] pc;
input [63:0] insn;

reg [7:0] state;
reg [1:0] ipg;
reg [63:0] ir;
wire [9:0] ir10 = {ipg,ir[7:0]};
wire [7:0] ndxbyte = ir[15:8];
reg [7:0] dpr;
reg cf,vf,zf,nf,hf,ef;
reg im,firqim;
reg sync_state,wait_state;
wire [7:0] sr = {ef,firqim,hf,im,nf,zf,vf,cf};
reg [7:0] acca,accb;
wire [15:0] accd = {acca,accb};
reg [15:0] xr,yr,usp,ssp;
wire [15:0] prod = acca * accb;
reg [15:0] vect;
reg [16:0] res16;
reg [8:0] res8;
wire res8n = res8[7];
wire res8z = res8[7:0]==8'h00;
wire res8c = res8[8];
wire res16n = res16[15];
wire res16z = res16[15:0]==16'h0000;
wire res16c = res16[16];

reg [15:0] a,b;
reg [15:0] M;
wire [7:0] M8 = M[7:0];

reg nmi_armed;

reg isPULU,isPULS;
reg isRTS,isRTI;
reg isLEA;

function fnSubCarry;
input a;
input b;
input s;
	fnSubCarry = (~a&b)|(s&~a)|(s&b);
endfunction

	assign c = op? (~a&b)|(s&~a)|(s&b) : (a&b)|(a&~s)|(b&~s);

reg takb;
always @(ir10 or cf or nf or vf or zf)
case(ir10)
`BRA,`LBRA:		takb <= 1'b1;
`BRN,`LBRN:		takb <= 1'b0;
`BHI,`LBHI:		takb <= !cf & !zf;
`BLS,`LBLS:		takb <=  cf | zf;
`BLO,`LBLO:		takb <=  cf;
`BHS,`LBHS:		takb <= !cf;
`BNE,`LBNE:		takb <= !zf;
`BEQ,`LBEQ:		takb <=  zf;
`BMI,`LBMI:		takb <=  nf;
`BPL,`LBPL:		takb <= !nf;
`BVS,`LBVS:		takb <=  vf;
`BVC,`LBVC:		takb <= !vf;
`BGT,`LBGT:		takb <= (nf & vf & !zf) | (!nf & !vf & !zf);
`BGE,`LBGE:		takb <= (nf & vf) | (!nf & !vf);
`BLE,`LBLE:		takb <= zf | (nf & !vf) | (!nf & vf);
`BLT,`LBLT:		takb <= (nf & !vf) | (!nf & vf);
default:	takb <= 1'b1;
endcase

reg [3:0] cnt;
always @(ir)
begin
	cnt = 0;
	if (ir[8]) cnt = cnt + 4'd1;	// CC
	if (ir[9]) cnt = cnt + 4'd1;	// A
	if (ir[10]) cnt = cnt + 4'd1;	// B
	if (ir[11]) cnt = cnt + 4'd1;	// DP
	if (ir[12]) cnt = cnt + 4'd2;	// X
	if (ir[13]) cnt = cnt + 4'd2;	// Y
	if (ir[14]) cnt = cnt + 4'd2;
	if (ir[15]) cnt = cnt + 4'd2;
end

wire isIndexed =
	ir10[7:4]==4'h6 || ir10[7:4]==4'hA || ir10[7:4]==4'hE ||
	ir10==`LEAX || ir10==`LEAY || ir10==`LEAS || ir10==`LEAU
	;
wire isIndirect = ndxbyte[4] & ndxbyte[7];

wire isRST = vect[3:0]==4'hE;
wire isNMI = vect[3:0]==4'hC;
wire isSWI = vect[3:0]==4'hA;
wire isIRQ = vect[3:0]==4'h8;
wire isFIRQ = vect[3:0]==4'h6;
wire isSWI2 = vect[3:0]==4'h4;
wire isSWI3 = vect[3:0]==4'h2;

reg [15:0] ndxreg;
always @(ndxbyte)
case(ndxbyte[6:5])
2'b00:	ndxreg <= xr;
2'b01:	ndxreg <= yr;
2'b10:	ndxreg <= usp;
2'b11:	ndxreg <= ssp;
endcase

function [15:0] fnNdxAddr;
casex(ir[15:8])
8'b0xxxxxxx:	fnNdxAddr <= ndxreg + {{11{ndxbyte[4]}},ndxbyte[4:0]};
8'b1xxx0000:	fnNdxAddr <= ndxreg;
8'b1xxx0001:	fnNdxAddr <= ndxreg;
8'b1xxx0010:	fnNdxAddr <= ndxreg - 16'd1;
8'b1xxx0011:	fnNdxAddr <= ndxreg - 16'd2;
8'b1xxx0100:	fnNdxAddr <= ndxreg;
8'b1xxx0101:	fnNdxAddr <= ndxreg + accb;
8'b1xxx0110:	fnNdxAddr <= ndxreg + acca;
8'b1xxx1000:	fnNdxAddr <= ndxreg + {{8{ir[23]}},ir[23:16]};
8'b1xxx1001:	fnNdxAddr <= ndxreg + ir[31:16];
8'b1xxx1011:	fnNdxAddr <= ndxreg + {a,b};
8'b1xxx1100:	fnNdxAddr <= pc + {{8{ir[23]}},ir[23:16]} + 16'd3;
8'b1xxx1101:	fnNdxAddr <= pc + ir[31:16] + 16'd4;
8'b1xx11111:	fnNdxAddr <= ir[31:16];
default:		fnNdxAddr <= 16'hFFFF;
endcase
endtask

reg [15:0] src1,src2;
always @*
	case(ir[15:12])
	4'b0000:	src1 <= {acca,accb};
	4'b0001:	src1 <= xr;
	4'b0010:	src1 <= yr;
	4'b0011:	src1 <= usp;
	4'b0100:	src1 <= ssp;
	4'b0101:	src1 <= pc + 16'd2;
	4'b1000:	src1 <= acca;
	4'b1001:	src1 <= accb;
	4'b1010:	src1 <= ccr;
	4'b1011:	src1 <= dpr;
	default:	src1 <= 16'h0000;
	endcase
always @*
	case(ir[11:8])
	4'b0000:	src2 <= {acca,accb};
	4'b0001:	src2 <= xr;
	4'b0010:	src2 <= yr;
	4'b0011:	src2 <= usp;
	4'b0100:	src2 <= ssp;
	4'b0101:	src2 <= pc + 16'd2;
	4'b1000:	src2 <= acca;
	4'b1001:	src2 <= accb;
	4'b1010:	src2 <= ccr;
	4'b1011:	src2 <= dpr;
	default:	src2 <= 16'h0000;
	endcase

wire [15:0] dp_address = {dpr,ir[15:8]};

always @(posedge clk_i)
if (state==DECODE) begin
	isPULU <= ir10==`PULU;
	isPULS <= ir10==`PULS;
	isRTI <= ir10==`RTI;
	isRTS <= ir10==`RTS;
	isLEA <= ir10==`LEAX || ir10==`LEAY || ir10==`LEAU || ir10==`LEAS;
end
	
always @(posedge clk)
	nmi1 <= nmi_i;
always @(posedge clk)
	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
	else if (state==)
		nmi_edge <= 1'b0;

always @(posedge clk)
if (rst) begin
	sync_state <= `FALSE;
	wait_state <= `FALSE;
	ipg <= 2'b00;
	dpr <= 8'h00;
	im <= 1'b1;
	firqim <= 1'b1;
	gie <= 1'b0;
	nmi1 <= 1'b0;
	nmi_armed <= `FALSE;
	if (halt_i) begin
		ba_o <= 1'b1;
		bs_o <= 1'b1;
	end
	else begin
		ba_o <= 1'b0;
		bs_o <= 1'b0;
	end
end
else begin
case(state)
RESET:
	begin
		ba <= 1'b0;
		bs <= 1'b0;
		vect <= `RST_VECT;
		radr <= `RST_VECT;
		load_what <= `LW_PCH;
		next_state(LOAD1);
	end
IFETCH:
	begin
		next_state(DECODE);
		ipg <= 2'b00;
		if (nmi_edge | firq_i | irq_i) begin
			sync_state <= `FALSE;
			wait_state <= `FALSE;
		end
		if (nmi_edge & nmi_armed) begin
			ir[7:0] <= `INT;
			vect <= `NMI_VECT;
		end
		else if (firq_i & !firqim) begin
			ir[7:0] <= `INT;
			vect <= `FIRQ_VECT;
		end
		else if (irq_i & !im) begin
			ir[7:0] <= `INT;
			vect <= `IRQ_VECT;
		end
		else begin
			if (sync_state)
				next_state(IFETCH1);
			else
				ir <= insn;
		end

		case(ir10)
		`ABX:	xr <= res;
		`NEGA,`COMA,`LSRA,`RORA,`ASRA,`ASLA,`ROLA,`DECA,`INCA,`CLRA:
			acca <= res;
		`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
		`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT:
			begin
				cf <= (a[7]&b[7])|(a[7]&~res8[7])|(b[7]&~res8[7]);
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				vf <= (res8[7] ^ b[7]) & (1'b1 ^ a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT,
		`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
			begin
				cf <= (a[7]&b[7])|(a[7]&~res8[7])|(b[7]&~res8[7]);
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				vf <= (res8[7] ^ b[7]) & (1'b1 ^ a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
			begin
				cf <= (a[15]&b[15])|(a[15]&~res16[15])|(b[15]&~res16[15]);
				vf <= (res16[15] ^ b[15]) & (1'b1 ^ a[15] ^ b[15]);
				nf <= res16[15];
				zf <= res16[15:0]==16'h0000;
				acca <= res16[15:8];
				accb <= res8[7:0];
			end
		`ANDA_IMM,`ANDA_DP,`ANDA_NDX,`ANDA_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= 1'b0;
				acca <= res8[7:0];
			end
		`ANDB_IMM,`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= 1'b0;
				accb <= res8[7:0];
			end
		`ASLA:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`ASLB:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`ASL_DP,`ASL_NDX,`ASL_EXT:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`ASRA:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`ASRB:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`ASR_DP,`ASR_NDX,`ASR_EXT:
			begin
				cf <= res8c;
				hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`BITA_IMM,`BITA_DP,`BITA_NDX,`BITA_EXT:
			begin
				vf <= 1'b0;
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`BITB_IMM,`BITB_DP,`BITB_NDX,`BITB_EXT:
			begin
				vf <= 1'b0;
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`CLRA:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				acca <= 8'h00;
			end
		`CLRB:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				accb <= 8'h00;
			end
		`CLR_DP,`CLR_NDX,`CLR_EXT:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
			end
		`CMPA_IMM,`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`CMPB_IMM,`CMPB_DP,`CMPB_NDX,`CMPB_EXT:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`CMPD_IMM,`CMPD_DP,`CMPD_NDX,`CMPD_EXT,
		`CMPS_IMM,`CMPS_DP,`CMPS_NDX,`CMPS_EXT,
		`CMPU_IMM,`CMPU_DP,`CMPU_NDX,`CMPU_EXT,
		`CMPX_IMM,`CMPX_DP,`CMPX_NDX,`CMPX_EXT,
		`CMPY_IMM,`CMPY_DP,`CMPY_NDX,`CMPY_EXT:
			begin
				cf <= (~a[15]&b[15])|(res16[15]&~a[15])|(res16[15]&b[15]);
				vf <= (1'b1 ^ res16[15] ^ b[15]) & (a[15] ^ b[15]);
				nf <= res16[15];
				zf <= res16[15:0]==16'h0000;
			end
		`COMA:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res8n;
				zf <= res8z;
				acca <= res8[7:0];
			end
		`COMB:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res8n;
				zf <= res8z;
				accb <= res8[7:0];
			end
		`COM_DP,`COM_NDX,`COM_EXT:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res8n;
				zf <= res8z;
			end
		`DAA:	;	// *** find out what this does
		`DECA:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
				acca <= res8[7:0];
			end
		`DECB:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
				accb <= res8[7:0];
			end
		`DEC_DP,`DEC_NDX,`DEC_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
			end
		`EORA_IMM,`EORA_DP,`EORA_NDX,`EORA_EXT,
		`ORA_IMM,`ORA_DP,`ORA_NDX,`ORA_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= 1'b0;
				acca <= res8[7:0];
			end
		`EORB_IMM,`EORB_DP,`EORB_NDX,`EORB_EXT,
		`ORB_IMM,`ORB_DP,`ORB_NDX,`ORB_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= 1'b0;
				accb <= res8[7:0];
			end
		`EXG:
			begin
				case(ir[11:8])
				4'b0000:	begin acca <= src1[15:8]; accb <= src1[7:0]; end
				4'b0001:	xr <= src1;
				4'b0010:	yr <= src1;
				4'b0011:	usp <= src1;
				4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
				4'b0101:	pc <= src1;
				4'b1000:	acca <= src1[7:0];
				4'b1001:	accb <= src1[7:0];
				4'b1010:
					begin
						cf <= src1[0];
						vf <= src1[1];
						zf <= src1[2];
						nf <= src1[3];
						im <= src1[4];
						hf <= src1[5];
						firqim <= src1[6];
						ef <= src1[7];
					end
				4'b1011:	dpr <= src1[7:0];
				default:	;
				endcase
				case(ir[15:12])
				4'b0000:	begin acca <= src2[15:8]; accb <= src2[7:0]; end
				4'b0001:	xr <= src2;
				4'b0010:	yr <= src2;
				4'b0011:	usp <= src2;
				4'b0100:	begin ssp <= src2; nmi_armed <= `TRUE; end
				4'b0101:	pc <= src2;
				4'b1000:	acca <= src2[7:0];
				4'b1001:	accb <= src2[7:0];
				4'b1010:
					begin
						cf <= src2[0];
						vf <= src2[1];
						zf <= src2[2];
						nf <= src2[3];
						im <= src2[4];
						hf <= src2[5];
						firqim <= src2[6];
						ef <= src2[7];
					end
				4'b1011:	dpr <= src2[7:0];
				default:	;
				endcase
			end
		`INCA:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
				acca <= res8[7:0];
			end
		`INCB:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
				accb <= res8[7:0];
			end
		`INC_DP,`INC_NDX,`INC_EXT:
			begin
				nf <= res8n;
				zf <= res8z;
				vf <= res8[7] != a[7];
			end
		`LDA_IMM,`LDA_DP,`LDA_NDX,`LDA_EXT:
			begin
				vf <= 1'b0;
				zf <= res8z;
				nf <= res8n;
				acca <= res8[7:0];
			end
		`LDB_IMM,`LDB_DP,`LDB_NDX,`LDB_EXT:
			begin
				vf <= 1'b0;
				zf <= res8z;
				nf <= res8n;
				accb <= res8[7:0];
			end
		`LDD_IMM,`LDD_DP,`LDD_NDX,`LDD_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
				acca <= res16[15:8];
				accb <= res16[7:0];
			end
		`LDU_IMM,`LDU_DP,`LDU_NDX,`LDU_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
				usp <= res16[15:0];
			end
		`LDS_IMM,`LDS_DP,`LDS_NDX,`LDS_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
				ssp <= res16[15:0];
				nmi_armed <= 1'b1;
			end
		`LDX_IMM,`LDX_DP,`LDX_NDX,`LDX_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
				xr <= res16[15:0];
			end
		`LDY_IMM,`LDY_DP,`LDY_NDX,`LDy_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
				yr <= res16[15:0];
			end
		`LEAS:	begin ssp <= res16[15:0]; nmi_armed <= 1'b1; end
		`LEAU:	usp <= res16[15:0];
		`LEAX:
			begin
				zf <= res16z;
				xr <= res16[15:0];
			end
		`LEAY:
			begin
				zf <= res16z;
				yr <= res16[15:0];
			end
		`LSRA:
			begin
				cf <= res8c;
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`LSRB:
			begin
				cf <= res8c;
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`LSR_DP,`LSR_NDX,`LSR_EXT:
			begin
				cf <= res8c;
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`MUL:
			begin
				zf <= res16z;
				acca <= prod[15:8];
				accb <= prod[7:0];
			end
		`NEGA:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`NEGB:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`NEG_DP,`NEG_NDX,`NEG_EXT:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`ROLA:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`ROLB:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`ROL_DP,`ROL_NDX,`ROL_EXT:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end		
		`RORA:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`RORB:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`ROR_DP,`ROR_NDX,`ROR_EXT:
			begin
				cf <= res8c;
				vf <= res8[7] ^ res8[8];
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
			end
		`SBCA_IMM,`SBCA_DP,`SBCA_NDX,`SBCA_EXT:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				acca <= res8[7:0];
			end
		`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
			begin
				cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
				hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
				nf <= res8[7];
				zf <= res8[7:0]==8'h00;
				accb <= res8[7:0];
			end
		`SEX:
			begin
				vf <= 1'b0;
				nf <= res8n;
				zf <= res8z;
				acca <= res8[7:0];
			end
		`STA_DP,`STA_NDX,`STA_EXT,
		`STB_DP,`STB_NDX,`STB_EXT:
			begin
				vf <= 1'b0;
				zf <= res8z;
				nf <= res8n;
			end
		`STD_DP,`STD_NDX,`STD_EXT,
		`STU_DP,`STU_NDX,`STU_EXT,
		`STX_DP,`STX_NDX,`STX_EXT,
		`STY_DP,`STY_NDX,`STY_EXT:
			begin
				vf <= 1'b0;
				zf <= res16z;
				nf <= res16n;
			end
		`TFR:
			begin
				case(ir[11:8])
				4'b0000:	begin acca <= src1[15:8]; accb <= src1[7:0]; end
				4'b0001:	xr <= src1;
				4'b0010:	yr <= src1;
				4'b0011:	usp <= src1;
				4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
				4'b0101:	pc <= src1;
				4'b1000:	acca <= src1[7:0];
				4'b1001:	accb <= src1[7:0];
				4'b1010:
					begin
						cf <= src1[0];
						vf <= src1[1];
						zf <= src1[2];
						nf <= src1[3];
						im <= src1[4];
						hf <= src1[5];
						firqim <= src1[6];
						ef <= src1[7];
					end
				4'b1011:	dpr <= src1[7:0];
				default:	;
				endcase
			end
		`TSTA,`TSTB,`TST_DP,`TST_NDX,`TST_EXT:
			begin
				vf <= 1'b0;
				nf <= res8n;
				zf <= res8z;
			end
		`SUBA_IMM:
			begin acca <= res8; nf <= res8n; zf <= res8z; vf <= res8v; cf <= res8c; hf <= res8h; end
			
		`MUL:
			begin
			end
	end

DECODE:
	begin
		a <= 16'd0;
		b <= 16'd0;
		if (isIndexed) begin
			casex(ndxbyte)
			8'b1xx00000:	
				case(ndxbyte[6:5])
				2'b00:	xr <= xr + 16'd1;
				2'b01:	yr <= yr + 16'd1;
				2'b10:	usp <= usp + 16'd1;
				2'b11:	ssp <= ssp + 16'd1;
				endcase
			8'b1xx00001:
				case(ndxbyte[6:5])
				2'b00:	xr <= xr + 16'd2;
				2'b01:	yr <= yr + 16'd2;
				2'b10:	usp <= usp + 16'd2;
				2'b11:	ssp <= ssp + 16'd2;
				endcase
			8'b1xx00010:
				case(ndxbyte[6:5])
				2'b00:	xr <= xr - 16'd1;
				2'b01:	yr <= yr - 16'd1;
				2'b10:	usp <= usp - 16'd1;
				2'b11:	ssp <= ssp - 16'd1;
				endcase
			8'b1xx00011:
				case(ndxbyte[6:5])
				2'b00:	xr <= xr - 16'd2;
				2'b01:	yr <= yr - 16'd2;
				2'b10:	usp <= usp - 16'd2;
				2'b11:	ssp <= ssp - 16'd2;
				endcase
			endcase
		end
		if (isIndexed) begin
			radr <= fnNdxAddr();
			wadr <= fnNdxAddr();
		end
		next_state(IFETCH1);
		pc <= pc + 16'd1;
		case(ir10)
		`NOP:	;
		`SYNC:	sync_state <= `TRUE;
		`ORCC:	begin
				cf <= cf | ir[8];
				vf <= vf | ir[9];
				zf <= zf | ir[10];
				nf <= nf | ir[11];
				im <= im | ir[12];
				hf <= hf | ir[13];
				firqim <= firqim | ir[14];
				ef <= ef | ir[15];
				pc <= pc + 16'd2;
				end
		`ANDCC:
				begin
				cf <= cf & ir[8];
				vf <= vf & ir[9];
				zf <= zf & ir[10];
				nf <= nf & ir[11];
				im <= im & ir[12];
				hf <= hf & ir[13];
				firqim <= firqim & ir[14];
				ef <= ef & ir[15];
				pc <= pc + 16'd2;
				end
		`CWAI:
				begin
				cf <= cf & ir[8];
				vf <= vf & ir[9];
				zf <= zf & ir[10];
				nf <= nf & ir[11];
				im <= im & ir[12];
				hf <= hf & ir[13];
				firqim <= firqim & ir[14];
				ef <= ef & ir[15];
				pc <= pc + 16'd2;
				ir[15:8] <= 8'hFF;
				wait_state <= `TRUE;
				next_state(PUSH1);
				end
		`ABX:	res16 <= xr + accb;
		`PG2:	begin ipg <= 2'b01; ir <= ir[63:8]; next_state(DECODE); end
		`PG3:	begin ipg <= 2'b10; ir <= ir[63:8]; next_state(DECODE); end
		`NEGA:	res8 <= -acca; a <= 8'h00; b <= acca;
		`COMA:	res8 <= ~acca;
		`LSRA:	res8 <= {acca[0],1'b0,acca[7:1]};
		`RORA:	res8 <= {acca[0],cf,acca[7:1]};
		`ASRA:	res8 <= {acca[0],acca[7],acca[7:1]};
		`ASLA:	res8 <= {acca,1'b0};
		`ROLA:	res8 <= {acca,cf};
		`DECA:	res8 <= acca - 8'd1;
		`INCA:	res8 <= acca + 8'd1;
		`TSTA:	res8 <= acca;
		`CLRA:	res8 <= 9'h000;

		`NEGB:	res <= -accb; a <= 8'h00; b <= accb;
		`COMB:	res <= ~accb;
		`LSRB:	res <= {accb[0],1'b0,accb[7:1]};
		`RORB:	res <= {accb[0],cf,accb[7:1]};
		`ASRB:	res <= {accb[0],accb[7],accb[7:1]};
		`ASLB:	res <= {accb,1'b0};
		`ROLB:	res <= {accb,cf};
		`DECB:	res <= accb - 8'd1;
		`INCB:	res <= accb + 8'd1;
		`TSTB:	res <= accb;
		`CLRB:	res <= 9'h000;

		`SUBA_IMM:	res8 <= acca - ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`CMPA_IMM:	res8 <= acca - ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`SBCA_IMM:	res8 <= acca - ir[15:8] - cf; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`ANDA_IMM:	res8 <= acca & ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`BITA_IMM:	res8 <= acca & ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`LDA_IMM:	res8 <= ir[15:8]; pc <= pc + 16'd2;
		`EORA_IMM:	res8 <= acca ^ ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`ADCA_IMM:	res8 <= acca + ir[15:8] + cf;  pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`ORA_IMM:	res8 <= acca | ir[15:8];  pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		`ADDA_IMM:	res8 <= acca + ir[15:8];  pc <= pc + 16'd2; a <= acca; b <= ir[15:8];
		
		`SUBB_IMM:	res8 <= accb - ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`CMPB_IMM:	res8 <= accb - ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`SBCB_IMM:	res8 <= accb - ir[15:8] - cf; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`ANDB_IMM:	res8 <= accb & ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`BITB_IMM:	res8 <= accb & ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`LDB_IMM:	res8 <= ir[15:8]; pc <= pc + 16'd2;
		`EORB_IMM:	res8 <= accb ^ ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`ADCB_IMM:	res8 <= accb + ir[15:8] + cf;  pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`ORB_IMM:	res8 <= accb | ir[15:8];  pc <= pc + 16'd2; a <= accb; b <= ir[15:8];
		`ADDB_IMM:	res8 <= accb + ir[15:8];  pc <= pc + 16'd2; a <= accb; b <= ir[15:8];

		`LDD_IMM:	res <= ir[23:8];  pc <= pc + 16'd3;
		`LDX_IMM:	res <= ir[23:8];  pc <= pc + 16'd3;
		`LDY_IMM:	res <= ir[23:8];  pc <= pc + 16'd3;
		`LDU_IMM:	res <= ir[23:8];  pc <= pc + 16'd3;
		`LDS_IMM:	res <= ir[23:8];  pc <= pc + 16'd3;

		`CMPD_IMM:	res <= accd - ir[23:8]; pc <= pc + 16'd3; a <= accd; b <= ir[23:8];
		`CMPX_IMM:	res <= xr - ir[23:8]; pc <= pc + 16'd3; a <= xr; b <= ir[23:8];
		`CMPY_IMM:	res <= yr - ir[23:8]; pc <= pc + 16'd3; a <= yr; b <= ir[23:8];
		`CMPU_IMM:	res <= usp - ir[23:8]; pc <= pc + 16'd3; a <= usp; b <= ir[23:8];
		`CMPS_IMM:	res <= ssp - ir[23:8]; pc <= pc + 16'd3; a <= ssp; b <= ir[23:8];

		`NEG_DP,`COM_DP,`LSR_DP,`ROR_DP,`ASR_DP,`ASL_DP,`ROL_DP,`DEC_DP,`INC_DP,`TST_DP,
		`SUBA_DP,`CMPA_DP,`SBCA_DP,`ANDA_DP,`BITA_DP,`LDA_DP,`EORA_DP,`ADCA_DP,`ORA_DP,`ADDA_DP,
		`SUBB_DP,`CMPB_DP,`SBCB_DP,`ANDB_DP,`BITB_DP,`LDB_DP,`EORB_DP,`ADCB_DP,`ORB_DP,`ADDB_DP:
			begin
				load_what <= `LW_BL;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`SUBD_DP,`CMPX_DP,`LDX_DP,`ADDD_DP,`LDD_DP,`LDU_DP,`LDS_DP,
		`CMPD_DP,`CMPY_DP,`CMPS_DP,`CMPU_DP,`LDY_DP:
			begin
				load_what <= `LW_BH;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`CLR_DP:
			begin
				store_what <= `SW_RES8;
				res8 <= 9'h00;
				wadr <= dp_address;
				next_state(STORE1);
			end
		`NEG_NDX,`COM_NDX,`LSR_NDX,`ROR_NDX,`ASR_NDX,`ASL_NDX,`ROL_NDX,`DEC_NDX,`INC_NDX,`TST_NDX,
		`SUBA_NDX,`CMPA_NDX,`SBCA_NDX,`ANDA_NDX,`BITA_NDX,`LDA_NDX,`EORA_NDX,`ADCA_NDX,`ORA_NDX,`ADDA_NDX,
		`SUBB_NDX,`CMPB_NDX,`SBCB_NDX,`ANDB_NDX,`BITB_NDX,`LDB_NDX,`EORB_NDX,`ADCB_NDX,`ORB_NDX,`ADDB_NDX:
			begin
				if (isIndirect) begin
					load_what <= `LW_IAH;
					radr <= fnNdxAddr();
					next_state(LOAD1);
				end
				else begin
					b <= 16'd0;
					load_what <= `LW_BL;
					radr <= fnNdxAddr();
					next_state(LOAD1);
				end
			end
		`SUBD_NDX,`CMPX_NDX,`LDX_NDX,`ADDD_NDX,`LDD_NDX,`LDU_NDX,`LDS_NDX,
		`CMPD_NDX,`CMPY_NDX,`CMPS_NDX,`CMPU_NDX,`LDY_NDX:
			begin
				if (isIndirect) begin
					load_what <= `LW_IAH;
					radr <= fnNdxAddr();
					next_state(LOAD1);
				end
				else begin
					load_what <= `LW_BH;
					radr <= fnNdxAddr();
					next_state(LOAD1);
				end
			end
		`NEG_EXT,`COM_EXT,`LSR_EXT,`ROR_EXT,`ASR_EXT,`ASL_EXT,`ROL_EXT,`DEC_EXT,`INC_EXT,`TST_EXT,
		`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
		`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ir[23:8];
				next_state(LOAD1);
			end
		`SUBD_EXT,`CMPX_EXT,`LDX_EXT,`ADDD_EXT,`LDD_EXT,`LDU_EXT,`LDS_EXT,
		`CMPD_EXT,`CMPY_EXT,`CMPS_EXT,`CMPU_EXT,`LDY_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ir[23:8];
				next_state(LOAD1);
			end
		`BSR,`LBSR,`JSR_DP,`JSR_NDX,`JSR_EXT:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc;
				next_state(STORE1);
			end
		`RTS:
			begin
				load_what <= `LW_PCH;
				radr <= ssp;
				next_state(LOAD1);
			end
		`JMP_DP:	pc <= {dpr,ir[15:8]};
		`JMP_EXT:	pc <= ir[23:8];
		`JMP_NDX:
			begin
				if (isIndirect) begin
					load_what <= `LW_PCH;
					next_state(LOAD1);
				end
				else
					pc <= fnNdxAddr();
			end
		`LEAX,`LEAY,`LEAS,`LEAU:
			begin
				if (isIndirect) begin
					load_what <= `LW_IAH;
					radr <= fnNdxAddr();
					state <= LOAD1;
				end
				else
					res <= fnNdxAddr();
			end
		`PSHU,`PSHS:
			begin
				next_state(PUSH1);
				pc <= pc + 16'd2;
			end
		`PULS,`PULU:
			begin
				next_state(PULL1);
				pc <= pc + 16'd2;
			end
		`BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BHI,`BLS,`BHS,`BLO,`BGT,`BGE,`BLT,`BLE,`BRA,`BRN:
			if (takb)
				pc <= pc + {{8{ir[15]}},ir[15:8]} + 16'd2;
			else
				pc <= pc + 16'd2;
		`LBEQ,`LBNE,`LBMI,`LBPL,`LBVS,`LBVC,`LBHI,`LBLS,`LBHS,`LBLO,`LBGT,`LBGE,`LBLT,`LBLE,`LBRN:
			if (takb)
				pc <= pc + ir[23:8] + 16'd4;
			else
				pc <= pc + 16'd4;
		`LBRA:	pc <= pc + ir[23:8] + 16'd3;
		`JMP_EXT:	pc <= ir[23:8];
		`RTI:
			begin
				load_what <= `CCR;
				radr <= ssp;
				next_state(LOAD1);
			end
		`INT:
			begin
				if (isNMI | isIRQ | isSWI | isSWI2 | isSWI3) begin
					ir[15:8] <= 8'hFF;
					ef <= 1'b1;
				end
				else if (isFIRQ) begin
					ir[15:8] <= 8'h81;
					ef <= 1'b0;
				end
				next_state(PUSH1);
			end
		endcase
	end

CALC:
	begin
		next_state(IFETCH);
		case(ir10)
		`SUBD_DP,`CMPD_DP:	res <= {a,b} - M;
		`ADDD_DP:	res <= {a,b} + M;
		`LDD_DP,`LDU_DP,`LDS_DP,`LDX_DP,`LDY_DP:	res <= M;
		`CMPX_DP:	res <= xr - M;
		`CMPY_DP:	res <= yr - M;
		`CMPS_DP:	res <= ssp - M;
		`CMPU_DP:	res <= usp - M;
		`NEG_DP,`NEG_NDX,`NEG_EXT:	begin res8 <= -M8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`COM_DP,`COM_NDX,`COM_EXT:	begin res8 <= ~M8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`LSR_DP,`LSR_NDX,`LSR_EXT:	begin res8 <= {M[0],1'b0,M[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ROR_DP,`ROR_NDX,`ROR_EXT:	begin res8 <= {M[0],cf,M[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASR_DP,`ADR_NDX,`ASR_EXT:	begin res8 <= {M[0],M[7],M[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASL_DP,`ASL_NDX,`ASL_EXT:	begin res8 <= {M8,1'b0}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`ROL_DP,`ROL_NDX,`ROL_EXT:	begin res8 <= {M8,cf}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`DEC_DP,`DEC_NDX,`DEC_EXT:	begin res8 <= M8 - 8'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`INC_DP,`INC_NDX,`INC_EXT:	begin res8 <= M8 + 8'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TST_DP,`TST_NDX,`TST_EXT:	res8 <= M8;
		endcase
	end

PUSH1:
	begin
		next_state(PUSH2);
		if (isINT | isPSHS) begin
			wadr <= ssp - cnt;
			ssp <= ssp - cnt;
		end
		else begin	// PSHU
			wadr <= usp - cnt;
			usp <= usp - cnt;
		end
	end
PUSH2:
	begin
		next_state(STORE1);
		if (ir[8]) begin
			store_what <= `SW_CCR;
			ir[8] <= 1'b0;
		end
		else if (ir[9]) begin
			store_what <= `SW_ACCA;
			ir[9] <= 1'b0;
		end
		else if (ir[10]) begin
			store_what <= `SW_ACCB;
			ir[10] <= 1'b0;
		end
		else if (ir[11]) begin
			store_what <= `SW_DPR;
			ir[11] <= 1'b0;
		end
		else if (ir[12]) begin
			store_what <= `SW_XH;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			store_what <= `SW_YH;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			if (isINT | isPSHS)
				store_what <= `SW_USPH;
			else
				store_what <= `SW_SSPH;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			store_what <= `SW_PCH;
			ir[15] <= 1'b0;
		end
		else begin
			if (isINT) begin
				radr <= vect;
				load_what <= `LW_PCH;
				next_state(LOAD1);
			end
			else
				next_state(IFETCH);
		end
PULL1:
	begin
		next_state(LOAD1);
		if (ir[8]) begin
			load_what <= `LW_CCR;
			ir[8] <= 1'b0;
		end
		else if (ir[9]) begin
			load_what <= `LW_ACCA;
			ir[9] <= 1'b0;
		end
		else if (ir[10]) begin
			load_what <= `LW_ACCB;
			ir[10] <= 1'b0;
		end
		else if (ir[11]) begin
			load_what <= `LW_DPR;
			ir[11] <= 1'b0;
		end
		else if (ir[12]) begin
			load_what <= `LW_XH;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			load_what <= `LW_YH;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			if (ir10==`PULU)
				load_what <= `LW_SSPH;
			else
				load_what <= `LW_USPH;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			load_what <= `LW_PCH;
			ir[15] <= 1'b0;
		end
		else
			next_state(IFETCH1);
	end
endcase
end

endmodule

