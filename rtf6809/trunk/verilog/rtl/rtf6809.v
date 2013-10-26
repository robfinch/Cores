`include "rtf6809_defines.v"
// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
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
// 5844 LUTS / 781 FF's / 5 BRAMs
// 64.0 MHz
module rtf6809(rst_i, clk_i, halt_i, nmi_i, irq_i, firq_i, ba_o, bs_o, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, we_o, ack_i, sel_o, adr_o, dat_i, dat_o);
parameter RESET = 8'd0;
parameter IFETCH = 8'd1;
parameter DECODE = 8'd2;
parameter CALC = 8'd3;
parameter PULL1 = 8'd4;
parameter PUSH1 = 8'd5;
parameter PUSH2 = 8'd6;
parameter LOAD1 = 8'd7;
parameter LOAD2 = 8'd8;
parameter STORE1 = 8'd9;
parameter STORE2 = 8'd10;
parameter ICACHE1 = 8'd128;
parameter ICACHE2 = 8'd129;
input rst_i;
input clk_i;
input halt_i;
input nmi_i;
input irq_i;
input firq_i;
output reg ba_o;
output reg bs_o;
output reg [1:0] bte_o;
output reg [2:0] cti_o;
output reg [5:0] bl_o;
output reg cyc_o;
output reg stb_o;
output reg we_o;
output reg lock_o;
input ack_i;
output reg [3:0] sel_o;
output reg [31:0] adr_o;
input [31:0] dat_i;
output reg [31:0] dat_o;

reg [7:0] state;
reg [5:0] load_what,store_what,load_what2;
reg [31:0] pc;
wire [31:0] pcp8 = pc + 32'd8;
wire [63:0] insn;
reg [1:0] ipg;
reg isFar;
reg [63:0] ir;
wire [9:0] ir10 = {ipg,ir[7:0]};
wire [7:0] ndxbyte = ir[15:8];
reg [7:0] dpr;
reg cf,vf,zf,nf,hf,ef;
reg im,firqim;
reg sync_state,wait_state;
wire [7:0] ccr = {ef,firqim,hf,im,nf,zf,vf,cf};
reg [7:0] acca,accb;
wire [15:0] accd = {acca,accb};
reg [15:0] xr,yr,usp,ssp;
wire [15:0] prod = acca * accb;
reg [15:0] vect;
reg [16:0] res;
reg [8:0] res8;
wire res8n = res8[7];
wire res8z = res8[7:0]==8'h00;
wire res8c = res8[8];
wire res16n = res[15];
wire res16z = res[15:0]==16'h0000;
wire res16c = res[16];
reg [31:0] ia;
reg ic_invalidate;
reg first_ifetch;

reg [15:0] a,b;
wire [7:0] b8 = b[7:0];
reg [31:0] radr,wadr;
reg [15:0] wdat;

reg nmi1,nmi_edge;
reg nmi_armed;

reg isStore;
reg isPULU,isPULS;
reg isPSHS,isPSHU;
reg isRTS,isRTI,isRTF;
reg isLEA;
reg isRMW;

reg [7:0] dati;
always @(sel_o or dat_i)
case(sel_o)
4'b0001:	dati <= dat_i[7:0];
4'b0010:	dati <= dat_i[15:8];
4'b0100:	dati <= dat_i[23:16];
4'b1000:	dati <= dat_i[31:24];
default:	dati <= 8'h00;
endcase

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
	if (ir[14]) cnt = cnt + 4'd2;	// U/S
	if (ir[15]) cnt = cnt + 4'd4;	// PC
end

wire isRMW1 = 	ir10==`NEG_DP || ir10==`COM_DP || ir10==`LSR_DP || ir10==`ROR_DP || ir10==`ASR_DP || ir10==`ASL_DP || ir10==`ROL_DP || ir10==`DEC_DP || ir10==`INC_DP ||
				ir10==`NEG_NDX || ir10==`COM_NDX || ir10==`LSR_NDX || ir10==`ROR_NDX || ir10==`ASR_NDX || ir10==`ASL_NDX || ir10==`ROL_NDX || ir10==`DEC_NDX || ir10==`INC_NDX ||
				ir10==`NEG_EXT || ir10==`COM_EXT || ir10==`LSR_EXT || ir10==`ROR_EXT || ir10==`ASR_EXT || ir10==`ASL_EXT || ir10==`ROL_EXT || ir10==`DEC_EXT || ir10==`INC_EXT
				;
wire isINT =	ir10==`INT;

wire isIndexed =
	ir10[7:4]==4'h6 || ir10[7:4]==4'hA || ir10[7:4]==4'hE ||
	ir10==`LEAX_NDX || ir10==`LEAY_NDX || ir10==`LEAS_NDX || ir10==`LEAU_NDX
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
always @(ndxbyte or xr or yr or usp or ssp)
case(ndxbyte[6:5])
2'b00:	ndxreg <= xr;
2'b01:	ndxreg <= yr;
2'b10:	ndxreg <= usp;
2'b11:	ndxreg <= ssp;
endcase

wire [15:0] near_address = {ir[15:8],ir[23:16]};
wire [31:0] far_address = {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};

reg [31:0] NdxAddr;
always @(ir or ndxreg or ndxbyte or acca or accb or pc)
casex(ir[15:8])
8'b0xxxxxxx:	NdxAddr <= {16'h0000,ndxreg + {{11{ndxbyte[4]}},ndxbyte[4:0]}};
8'b1xxx0000:	NdxAddr <= ndxreg;
8'b1xxx0001:	NdxAddr <= ndxreg;
8'b1xxx0010:	NdxAddr <= ndxreg - 16'd1;
8'b1xxx0011:	NdxAddr <= ndxreg - 16'd2;
8'b1xxx0100:	NdxAddr <= ndxreg;
8'b1xxx0101:	NdxAddr <= {16'h0000,ndxreg + {{8{accb[7]}},accb}};
8'b1xxx0110:	NdxAddr <= {16'h0000,ndxreg + {{8{acca[7]}},acca}};
8'b1xxx1000:	NdxAddr <= {16'h0000,ndxreg + {{8{ir[23]}},ir[23:16]}};
8'b1xxx1001:	NdxAddr <= {16'h0000,ndxreg + {ir[23:16],ir[31:24]}};
8'b1xxx1010:	NdxAddr <= ndxreg + {ir[23:16],ir[31:24],ir[39:32],ir[47:40]};
8'b1xxx1011:	NdxAddr <= {16'h0000,ndxreg + {acca,accb}};
8'b1xxx1100:	NdxAddr <= pc + {{24{ir[23]}},ir[23:16]} + 32'd3;
8'b1xxx1101:	NdxAddr <= pc + {{16{ir[23]}},ir[23:16],ir[31:24]} + 32'd4;
8'b1xxx1110:	NdxAddr <= pc + {ir[23:16],ir[31:24],ir[39:32],ir[47:40]} + 32'd6;
8'b1xx01111:	NdxAddr <= {ir[23:16],ir[31:24]};
8'b1xx11111:	NdxAddr <= {ir[23:16],ir[31:24]};
default:		NdxAddr <= 16'hFFFF;
endcase

reg [3:0] insnsz;
always @(ir)
casex(ir[15:8])
8'b0xxxxxxx:	insnsz <= 4'h2;
8'b1xxx0000:	insnsz <= 4'h2;
8'b1xxx0001:	insnsz <= 4'h2;
8'b1xxx0010:	insnsz <= 4'h2;
8'b1xxx0011:	insnsz <= 4'h2;
8'b1xxx0100:	insnsz <= 4'h2;
8'b1xxx0101:	insnsz <= 4'h2;
8'b1xxx0110:	insnsz <= 4'h2;
8'b1xxx1000:	insnsz <= 4'h3;
8'b1xxx1001:	insnsz <= 4'h4;
8'b1xxx1010:	insnsz <= 4'h6;
8'b1xxx1011:	insnsz <= 4'h2;
8'b1xxx1100:	insnsz <= 4'h3;
8'b1xxx1101:	insnsz <= 4'h4;
8'b1xxx1110:	insnsz <= 4'h6;
8'b1xx01111:	insnsz <= 4'h4;
8'b1xx11111:	insnsz <= 4'h4;
default:	insnsz <= 4'h2;
endcase

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

wire [31:0] dp_address = {16'h0000,dpr,ir[15:8]};
wire [31:0] ex_address = isFar ? far_address : near_address;

always @(posedge clk_i)
if (state==DECODE) begin
	isStore <= 	ir10==`STA_DP || ir10==`STB_DP || ir10==`STD_DP || ir10==`STX_DP || ir10==`STY_DP || ir10==`STU_DP || ir10==`STS_DP ||
				ir10==`STA_NDX || ir10==`STB_NDX || ir10==`STD_NDX || ir10==`STX_NDX || ir10==`STY_NDX || ir10==`STU_NDX || ir10==`STS_NDX ||
				ir10==`STA_EXT || ir10==`STB_EXT || ir10==`STD_EXT || ir10==`STX_EXT || ir10==`STY_EXT || ir10==`STU_EXT || ir10==`STS_EXT
				;
	isPULU <= ir10==`PULU;
	isPULS <= ir10==`PULS;
	isPSHS <= ir10==`PSHS;
	isPSHU <= ir10==`PSHU;
	isRTI <= ir10==`RTI;
	isRTS <= ir10==`RTS;
	isRTF <= ir10==`RTF;
	isLEA <= ir10==`LEAX_NDX || ir10==`LEAY_NDX || ir10==`LEAU_NDX || ir10==`LEAS_NDX;
	isRMW <= isRMW1;
end

wire hit0, hit1;
wire ihit = hit0 & hit1;

rtf6809_icachemem u1
(
	.wclk(clk_i),
	.wce(1'b1),
	.wr(ack_i && state==ICACHE2),
	.wa(adr_o[11:0]),
	.i(dat_i),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc[11:0]),
	.insn(insn)
);
	
rtf6809_itagmem u2
(
	.wclk(clk_i),
	.wce(1'b1),
	.wr(ack_i && state==ICACHE2),
	.wa(adr_o[31:0]),
	.invalidate(ic_invalidate),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc),
	.hit0(hit0),
	.hit1(hit1)
);


always @(posedge clk_i)
	nmi1 <= nmi_i;
always @(posedge clk_i)
	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
	else if (state==DECODE && ir10==`INT)
		nmi_edge <= 1'b0;

always @(posedge clk_i)
if (rst_i) begin
	wb_nack();
	next_state(RESET);
	sync_state <= `FALSE;
	wait_state <= `FALSE;
	ipg <= 2'b00;
	dpr <= 8'h00;
	pc <= 32'h0000FFFE;
	im <= 1'b1;
	firqim <= 1'b1;
	nmi_armed <= `FALSE;
	ic_invalidate <= `TRUE;
	first_ifetch <= `TRUE;
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
		ic_invalidate <= `FALSE;
		ba_o <= 1'b0;
		bs_o <= 1'b0;
		vect <= `RST_VECT;
		radr <= `RST_VECT;
		load_what <= `LW_PCH;
		next_state(LOAD1);
	end

// ============================================================================
// IFETCH
// ============================================================================
IFETCH:
	begin
		if (halt_i) begin
			ba_o <= 1'b1;
			bs_o <= 1'b1;
		end
		else begin
			ba_o <= 1'b0;
			bs_o <= 1'b0;
			next_state(DECODE);
			isFar <= 1'b0;
			ipg <= 2'b00;
			ia <= 32'd0;
			if (nmi_edge | firq_i | irq_i) begin
				sync_state <= `FALSE;
				wait_state <= `FALSE;
			end
			if (nmi_edge & nmi_armed) begin
				bs_o <= 1'b1;
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `NMI_VECT;
			end
			else if (firq_i & !firqim) begin
				bs_o <= 1'b1;
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `FIRQ_VECT;
			end
			else if (irq_i & !im) begin
				bs_o <= 1'b1;
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `IRQ_VECT;
			end
			else begin
				if (sync_state)
					next_state(IFETCH);
				else if (ihit)
					ir <= insn;
				else begin
					ipg <= ipg;
					isFar <= isFar;
					next_state(ICACHE1);
				end
			end
		end

		if (first_ifetch) begin
			first_ifetch <= `FALSE;
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
					cf <= (a[15]&b[15])|(a[15]&~res[15])|(b[15]&~res[15]);
					vf <= (res[15] ^ b[15]) & (1'b1 ^ a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
					acca <= res[15:8];
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
					cf <= (~a[15]&b[15])|(res[15]&~a[15])|(res[15]&b[15]);
					vf <= (1'b1 ^ res[15] ^ b[15]) & (a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
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
					vf <= res8[7] != acca[7];
					acca <= res8[7:0];
				end
			`DECB:
				begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != accb[7];
					accb <= res8[7:0];
				end
			`DEC_DP,`DEC_NDX,`DEC_EXT:
				begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != b[7];
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
					vf <= res8[7] != acca[7];
					acca <= res8[7:0];
				end
			`INCB:
				begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != accb[7];
					accb <= res8[7:0];
				end
			`INC_DP,`INC_NDX,`INC_EXT:
				begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != b[7];
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
					acca <= res[15:8];
					accb <= res[7:0];
				end
			`LDU_IMM,`LDU_DP,`LDU_NDX,`LDU_EXT:
				begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					usp <= res[15:0];
				end
			`LDS_IMM,`LDS_DP,`LDS_NDX,`LDS_EXT:
				begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					ssp <= res[15:0];
					nmi_armed <= 1'b1;
				end
			`LDX_IMM,`LDX_DP,`LDX_NDX,`LDX_EXT:
				begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					xr <= res[15:0];
				end
			`LDY_IMM,`LDY_DP,`LDY_NDX,`LDY_EXT:
				begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					yr <= res[15:0];
				end
			`LEAS_NDX:	begin ssp <= res[15:0]; nmi_armed <= 1'b1; end
			`LEAU_NDX:	usp <= res[15:0];
			`LEAX_NDX:
				begin
					zf <= res16z;
					xr <= res[15:0];
				end
			`LEAY_NDX:
				begin
					zf <= res16z;
					yr <= res[15:0];
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
			`SUBA_IMM,`SUBA_DP,`SUBA_NDX,`SUBA_EXT:
				begin
					acca <= res8;
					nf <= res8n;
					zf <= res8z;
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					cf <= res8c;
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				end
			endcase
		end
	end

// ============================================================================
// DECODE
// ============================================================================
DECODE:
	begin
		first_ifetch <= `TRUE;
		next_state(IFETCH);		// default: move to IFETCH
		pc <= pc + 16'd1;		// default: increment PC by one
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
		`ABX:	res <= xr + accb;
		`PG2:	begin ipg <= 2'b01; ir <= ir[63:8]; next_state(DECODE); end
		`PG3:	begin ipg <= 2'b10; ir <= ir[63:8]; next_state(DECODE); end
		`FAR:	begin isFar <= `TRUE; ir <= ir[63:8]; next_state(DECODE); end
		`NEGA:	begin res8 <= -acca; a <= 8'h00; b <= acca; end
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

		`NEGB:	begin res <= -accb; a <= 8'h00; b <= accb; end
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

		// Immediate mode instructions
		`SUBA_IMM:	begin res8 <= acca - ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`CMPA_IMM:	begin res8 <= acca - ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`SBCA_IMM:	begin res8 <= acca - ir[15:8] - cf; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`ANDA_IMM:	begin res8 <= acca & ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`BITA_IMM:	begin res8 <= acca & ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`LDA_IMM:	begin res8 <= ir[15:8]; pc <= pc + 16'd2; end
		`EORA_IMM:	begin res8 <= acca ^ ir[15:8]; pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`ADCA_IMM:	begin res8 <= acca + ir[15:8] + cf;  pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`ORA_IMM:	begin res8 <= acca | ir[15:8];  pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		`ADDA_IMM:	begin res8 <= acca + ir[15:8];  pc <= pc + 16'd2; a <= acca; b <= ir[15:8]; end
		
		`SUBB_IMM:	begin res8 <= accb - ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`CMPB_IMM:	begin res8 <= accb - ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`SBCB_IMM:	begin res8 <= accb - ir[15:8] - cf; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`ANDB_IMM:	begin res8 <= accb & ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`BITB_IMM:	begin res8 <= accb & ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`LDB_IMM:	begin res8 <= ir[15:8]; pc <= pc + 16'd2; end
		`EORB_IMM:	begin res8 <= accb ^ ir[15:8]; pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`ADCB_IMM:	begin res8 <= accb + ir[15:8] + cf;  pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`ORB_IMM:	begin res8 <= accb | ir[15:8];  pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end
		`ADDB_IMM:	begin res8 <= accb + ir[15:8];  pc <= pc + 16'd2; a <= accb; b <= ir[15:8]; end

		`LDD_IMM:	begin res <= {ir[15:8],ir[23:16]};  pc <= pc + 32'd3; end
		`LDX_IMM:	begin res <= {ir[15:8],ir[23:16]};  pc <= pc + 32'd3; end
		`LDY_IMM:	begin res <= {ir[15:8],ir[23:16]};  pc <= pc + 32'd3; end
		`LDU_IMM:	begin res <= {ir[15:8],ir[23:16]};  pc <= pc + 32'd3; end
		`LDS_IMM:	begin res <= {ir[15:8],ir[23:16]};  pc <= pc + 32'd3; end

		`CMPD_IMM:	begin res <= accd - {ir[15:8],ir[23:16]}; pc <= pc + 16'd3; a <= accd; b <= {ir[15:8],ir[23:16]}; end
		`CMPX_IMM:	begin res <= xr - {ir[15:8],ir[23:16]}; pc <= pc + 16'd3; a <= xr; b <= {ir[15:8],ir[23:16]}; end
		`CMPY_IMM:	begin res <= yr - {ir[15:8],ir[23:16]}; pc <= pc + 16'd3; a <= yr; b <= {ir[15:8],ir[23:16]}; end
		`CMPU_IMM:	begin res <= usp - {ir[15:8],ir[23:16]}; pc <= pc + 16'd3; a <= usp; b <= {ir[15:8],ir[23:16]}; end
		`CMPS_IMM:	begin res <= ssp - {ir[15:8],ir[23:16]}; pc <= pc + 16'd3; a <= ssp; b <= {ir[15:8],ir[23:16]}; end

		// Direct mode instructions
		`NEG_DP,`COM_DP,`LSR_DP,`ROR_DP,`ASR_DP,`ASL_DP,`ROL_DP,`DEC_DP,`INC_DP,`TST_DP,
		`SUBA_DP,`CMPA_DP,`SBCA_DP,`ANDA_DP,`BITA_DP,`LDA_DP,`EORA_DP,`ADCA_DP,`ORA_DP,`ADDA_DP,
		`SUBB_DP,`CMPB_DP,`SBCB_DP,`ANDB_DP,`BITB_DP,`LDB_DP,`EORB_DP,`ADCB_DP,`ORB_DP,`ADDB_DP:
			begin
				load_what <= `LW_BL;
				radr <= dp_address;
				pc <= pc + 32'd2;
				next_state(LOAD1);
			end
		`SUBD_DP,`CMPX_DP,`LDX_DP,`ADDD_DP,`LDD_DP,`LDU_DP,`LDS_DP,
		`CMPD_DP,`CMPY_DP,`CMPS_DP,`CMPU_DP,`LDY_DP:
			begin
				load_what <= `LW_BH;
				pc <= pc + 32'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`CLR_DP:
			begin
				dp_store(`SW_RES8);
				res8 <= 9'h00;
			end
		`STA_DP:	dp_store(`SW_ACCA);
		`STB_DP:	dp_store(`SW_ACCB);
		`STD_DP:	dp_store(`SW_ACCDH);
		`STU_DP:	dp_store(`SW_USPH);
		`STS_DP:	dp_store(`SW_SSPH);
		`STX_DP:	dp_store(`SW_XH);
		`STY_DP:	dp_store(`SW_YH);

		// Indexed mode instructions
		`NEG_NDX,`COM_NDX,`LSR_NDX,`ROR_NDX,`ASR_NDX,`ASL_NDX,`ROL_NDX,`DEC_NDX,`INC_NDX,`TST_NDX,
		`SUBA_NDX,`CMPA_NDX,`SBCA_NDX,`ANDA_NDX,`BITA_NDX,`LDA_NDX,`EORA_NDX,`ADCA_NDX,`ORA_NDX,`ADDA_NDX,
		`SUBB_NDX,`CMPB_NDX,`SBCB_NDX,`ANDB_NDX,`BITB_NDX,`LDB_NDX,`EORB_NDX,`ADCB_NDX,`ORB_NDX,`ADDB_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					b <= 16'd0;
					load_what <= `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
		`SUBD_NDX,`CMPX_NDX,`LDX_NDX,`ADDD_NDX,`LDD_NDX,`LDU_NDX,`LDS_NDX,
		`CMPD_NDX,`CMPY_NDX,`CMPS_NDX,`CMPU_NDX,`LDY_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= `LW_BH;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					load_what <= `LW_BH;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
		`CLR_NDX:
			begin
				res8 <= 9'h000;
				indexed_store(`SW_RES8);
			end
		`STA_NDX:	indexed_store(`SW_ACCA);
		`STB_NDX:	indexed_store(`SW_ACCB);
		`STD_NDX:	indexed_store(`SW_ACCDH);
		`STU_NDX:	indexed_store(`SW_USPH);
		`STS_NDX:	indexed_store(`SW_SSPH);
		`STX_NDX:	indexed_store(`SW_XH);
		`STY_NDX:	indexed_store(`SW_YH);

		// Extended mode instructions
		`NEG_EXT,`COM_EXT,`LSR_EXT,`ROR_EXT,`ASR_EXT,`ASL_EXT,`ROL_EXT,`DEC_EXT,`INC_EXT,`TST_EXT,
		`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
		`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ex_address;
				pc <= pc + isFar ? 32'd5 : 32'd3;
				next_state(LOAD1);
			end
		`SUBD_EXT,`CMPX_EXT,`LDX_EXT,`ADDD_EXT,`LDD_EXT,`LDU_EXT,`LDS_EXT,
		`CMPD_EXT,`CMPY_EXT,`CMPS_EXT,`CMPU_EXT,`LDY_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + isFar ? 32'd5 : 32'd3;
				next_state(LOAD1);
			end
		`CLR_EXT:
			begin
				ex_store(`SW_RES8);
				pc <= pc + isFar ? 32'd5 : 32'd3;
				res8 <= 9'h00;
			end
		`STA_EXT:	ex_store(`SW_ACCA);
		`STB_EXT:	ex_store(`SW_ACCB);
		`STD_EXT:	ex_store(`SW_ACCDH);
		`STU_EXT:	ex_store(`SW_USPH);
		`STS_EXT:	ex_store(`SW_SSPH);
		`STX_EXT:	ex_store(`SW_XH);
		`STY_EXT:	ex_store(`SW_YH);

		`BSR:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc + 32'd2;
				next_state(STORE1);
			end
		`LBSR:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc + 32'd3;
				next_state(STORE1);
			end
		`JSR_DP:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc + 32'd2;
				next_state(STORE1);
			end
		`JSR_NDX:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc + insnsz;
				next_state(STORE1);
			end
		`JSR_EXT:
			begin
				if (isFar) begin
					store_what <= `SW_PC3124;
					wadr <= ssp - 16'd4;
					ssp <= ssp - 16'd4;
				end
				else begin
					store_what <= `SW_PCH;
					wadr <= ssp - 16'd2;
					ssp <= ssp - 16'd2;
				end
				pc <= pc + 32'd3;
				next_state(STORE1);
			end
		`JSR_FAR:
			begin
				store_what <= `SW_PC3124;
				wadr <= ssp - 16'd4;
				ssp <= ssp - 16'd4;
				pc <= pc + 32'd5;
				next_state(STORE1);
			end
		`RTS:
			begin
				load_what <= isFar ? `LW_PC3124 : `LW_PCH;
				radr <= ssp;
				next_state(LOAD1);
			end
		`RTF:
			begin
				load_what <= `LW_PC3124;
				radr <= ssp;
				next_state(LOAD1);
			end
		`JMP_DP:	pc <= dp_address;
		`JMP_EXT:	pc <= isFar ? far_address : {pc[31:16],near_address};
		`JMP_FAR:	pc <= far_address;
		`JMP_NDX:
			begin
				if (isIndirect) begin
					load_what <= `LW_PCH;
					next_state(LOAD1);
				end
				else
					pc <= NdxAddr;
			end
		`LEAX_NDX,`LEAY_NDX,`LEAS_NDX,`LEAU_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IAH;
					radr <= NdxAddr;
					state <= LOAD1;
				end
				else
					res <= NdxAddr;
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
				pc <= pc + {{24{ir[15]}},ir[15:8]} + 16'd2;
			else
				pc <= pc + 16'd2;
		`LBEQ,`LBNE,`LBMI,`LBPL,`LBVS,`LBVC,`LBHI,`LBLS,`LBHS,`LBLO,`LBGT,`LBGE,`LBLT,`LBLE,`LBRN:
			if (takb)
				pc <= pc + {{16{ir[15]}},ir[15:8],ir[23:16]} + 16'd4;
			else
				pc <= pc + 16'd4;
		`LBRA:	pc <= pc + {{16{ir[15]}},ir[15:8],ir[23:16]} + 16'd3;
		`RTI:
			begin
				load_what <= `LW_CCR;
				radr <= ssp;
				next_state(LOAD1);
			end
		`SWI:
			begin
				im <= 1'b1;
				firqim <= 1'b1;
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI_VECT;
				next_state(DECODE);
			end
		`SWI2:
			begin
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI2_VECT;
				next_state(DECODE);
			end
		`SWI3:
			begin
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI3_VECT;
				next_state(DECODE);
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
				pc <= pc;
				next_state(PUSH1);
			end
		endcase
	end

// ============================================================================
// CALC
// ============================================================================
CALC:
	begin
		next_state(IFETCH);
		case(ir10)
		`SUBD_DP,`SUBD_NDX,`SUBD_EXT,
		`CMPD_DP,`CMPD_NDX,`CMPD_EXT:	res <= {acca,accb} - b;
		`ADDD_DP,`ADDD_NDX,`ADDD_EXT:	res <= {acca,accb} + b;

		`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`SUBA_DP,`SUBA_NDX,`SUBA_EXT:	res8 <= acca - b8;
		`SBCA_DP,`SBCA_NDX,`SBCA_EXT:	res8 <= acca - b8 - cf;
		`BITA_DP,`BITA_NDX,`BITA_EXT,
		`ANDA_DP,`ANDA_NDX,`ANDA_EXT:	res8 <= acca & b8;
		`LDA_DP,`LDA_NDX,`LDA_EXT:		res8 <= b8;
		`EORA_DP,`EORA_NDX,`EORA_EXT:	res8 <= acca ^ b8;
		`ADCA_DP,`ADCA_NDX,`ADCA_EXT:	res8 <= acca + b8 + cf;
		`ORA_DP,`ORA_NDX,`ORA_EXT:		res8 <= acca | b8;
		`ADDA_DP,`ADDA_NDX,`ADDA_EXT:	res8 <= acca + b8;

		`CMPB_DP,`CMPB_NDX,`CMPB_EXT,
		`SUBB_DP,`SUBB_NDX,`SUBB_EXT:	res8 <= acca - b8;
		`SBCB_DP,`SBCB_NDX,`SBCB_EXT:	res8 <= acca - b8 - cf;
		`BITB_DP,`BITB_NDX,`BITB_EXT,
		`ANDB_DP,`ANDB_NDX,`ANDB_EXT:	res8 <= acca & b8;
		`LDB_DP,`LDB_NDX,`LDB_EXT:		res8 <= b8;
		`EORB_DP,`EORB_NDX,`EORB_EXT:	res8 <= acca ^ b8;
		`ADCB_DP,`ADCB_NDX,`ADCB_EXT:	res8 <= acca + b8 + cf;
		`ORB_DP,`ORB_NDX,`ORB_EXT:		res8 <= acca | b8;
		`ADDB_DP,`ADDB_NDX,`ADDB_EXT:	res8 <= acca + b8;
		
		`LDD_DP,`LDU_DP,`LDS_DP,`LDX_DP,`LDY_DP:	res <= b;
		`CMPX_DP,`CMPX_NDX,`CMPX_EXT:	res <= xr - b;
		`CMPY_DP,`CMPY_NDX,`CMPY_EXT:	res <= yr - b;
		`CMPS_DP,`CMPS_NDX,`CMPS_EXT:	res <= ssp - b;
		`CMPU_DP,`CMPU_NDX,`CMPU_EXT:	res <= usp - b;
		`NEG_DP,`NEG_NDX,`NEG_EXT:	begin res8 <= -b8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`COM_DP,`COM_NDX,`COM_EXT:	begin res8 <= ~b8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`LSR_DP,`LSR_NDX,`LSR_EXT:	begin res8 <= {b[0],1'b0,b[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ROR_DP,`ROR_NDX,`ROR_EXT:	begin res8 <= {b[0],cf,b[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASR_DP,`ASR_NDX,`ASR_EXT:	begin res8 <= {b[0],b[7],b[7:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASL_DP,`ASL_NDX,`ASL_EXT:	begin res8 <= {b8,1'b0}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`ROL_DP,`ROL_NDX,`ROL_EXT:	begin res8 <= {b8,cf}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`DEC_DP,`DEC_NDX,`DEC_EXT:	begin res8 <= b8 - 8'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`INC_DP,`INC_NDX,`INC_EXT:	begin res8 <= b8 + 8'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TST_DP,`TST_NDX,`TST_EXT:	res8 <= b8;
		endcase
	end

// ============================================================================
// LOAD / STORE
// ============================================================================
LOAD1:
`ifdef SUPPORT_DCACHE
	if (unCachedData)
`endif
	begin
		if (isRMW)
			lock_o <= 1'b1;
		wb_read(radr);
		state <= LOAD2;
	end
`ifdef SUPPORT_DCACHE
	else if (dhit)
		load_tsk(rdat);
	else begin
		retstate <= LOAD1;
		state <= DCACHE1;
	end
`endif
LOAD2:
	if (ack_i) begin
		wb_nack();
		load_tsk(dati);
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		lock_o <= 1'b0;
		wb_nack();
		derr_address <= adr_o;
//		intno <= 9'd508;
		state <= BUS_ERROR;
	end
`endif

STORE1:
	begin
		case(store_what)
		`SW_ACCDH:	wb_write(acca);
		`SW_ACCDL:	wb_write(accb);
		`SW_ACCA:	wb_write(acca);
		`SW_ACCB:	wb_write(accb);
		`SW_DPR:	wb_write(dpr);
		`SW_XL:	wb_write(xr[7:0]);
		`SW_XH:	wb_write(xr[15:8]);
		`SW_YL:	wb_write(yr[7:0]);
		`SW_YH:	wb_write(yr[15:8]);
		`SW_USPL:	wb_write(usp[7:0]);
		`SW_USPH:	wb_write(usp[15:8]);
		`SW_SSPL:	wb_write(ssp[7:0]);
		`SW_SSPH:	wb_write(ssp[15:8]);
		`SW_PC3124:	wb_write(pc[31:24]);
		`SW_PC2316:	wb_write(pc[23:16]);
		`SW_PCH:	wb_write(pc[15:8]);
		`SW_PCL:	wb_write(pc[7:0]);
		`SW_CCR:	wb_write(ccr);
		`SW_RES8:	wb_write(res8[7:0]);
		`SW_RES16H:	wb_write(res[15:8]);
		`SW_RES16L:	wb_write(res[7:0]);
		`SW_DEF8:	wb_write(wdat);
		default:	wb_write(wdat);
		endcase
`ifdef SUPPORT_DCACHE
		radr <= wadr;		// Do a cache read to test the hit
`endif
		state <= STORE2;
	end
	
// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
STORE2:
	if (ack_i) begin
		lock_o <= 1'b0;
		wb_nack();
		wdat <= dat_o;
		wadr <= wadr + 32'd1;
		next_state(IFETCH);
		case(store_what)
		`SW_CCR:	next_state(PUSH2);
		`SW_ACCA:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STA
				next_state(IFETCH);
		`SW_ACCB:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STB
				next_state(IFETCH);
		`SW_ACCDH:
			begin
				store_what <= `SW_ACCDL;
				next_state(STORE1);
			end
		`SW_ACCDL:	next_state(IFETCH);
		`SW_DPR:	next_state(PUSH2);
		`SW_XH:
			begin
				store_what <= `SW_XL;
				next_state(STORE1);
			end
		`SW_XL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STX
				next_state(IFETCH);
		`SW_YH:
			begin
				store_what <= `SW_YL;
				next_state(STORE1);
			end
		`SW_YL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STY
				next_state(IFETCH);
		`SW_USPH:
			begin
				store_what <= `SW_USPL;
				next_state(STORE1);
			end
		`SW_USPL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STU
				next_state(IFETCH);
		`SW_SSPH:
			begin
				store_what <= `SW_SSPL;
				next_state(STORE1);
			end
		`SW_SSPL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STS
				next_state(IFETCH);
		`SW_PC3124:
			begin
				store_what <= `SW_PC2316;
				wadr <= wadr + 16'd1;
				next_state(STORE1);
			end
		`SW_PC2316:
			begin
				store_what <= `SW_PCH;
				wadr <= wadr + 16'd1;
				next_state(STORE1);
			end
		`SW_PCH:
			begin
				store_what <= `SW_PCL;
				wadr <= wadr + 32'd1;
				next_state(STORE1);
			end
		`SW_PCL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else begin	// JSR
				next_state(IFETCH);
				case(ir10)
				`BSR:	pc <= pc + {{24{ir[15]}},ir[15:8]};
				`LBSR:	pc <= pc + {{16{ir[15]}},ir[15:8],ir[23:16]};
				`JSR_DP:	pc <= {16'h0000,dpr,ir[15:8]};
				`JSR_EXT:
						if (isFar)
							pc <= far_address;
						else
							pc[15:0] <= near_address;
				`JSR_FAR:	
					begin
						pc <= far_address;
						$display("Loading PC with %h", far_address);
					end
				`JSR_NDX:
					begin
						if (isIndirect) begin
							radr <= NdxAddr;
							load_what <= isFar ? `LW_PC3124 : `LW_PCH;
							next_state(LOAD1);
						end
						else
							pc <= isFar ? NdxAddr : {pc[31:16],NdxAddr[15:0]};
					end
				endcase
			end
		endcase
`ifdef SUPPORT_DCACHE
		if (!dhit && write_allocate) begin
			state <= DCACHE1;
		end
`endif
	end
`ifdef SUPPORT_BERR
	else if (err_i) begin
		lock_o <= 1'b0;
		wb_nack();
		state <= BUS_ERROR;
	end
`endif

// ============================================================================
// ============================================================================
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
			store_what <= `SW_PC3124;
			ir[15] <= 1'b0;
		end
		else begin
			if (isINT) begin
				radr <= vect;
				pc[31:16] <= 16'h0000;
				load_what <= `LW_PCH;
				next_state(LOAD1);
			end
			else
				next_state(IFETCH);
		end
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
			load_what <= `LW_PC3124;
			ir[15] <= 1'b0;
		end
		else
			next_state(IFETCH);
	end

// ============================================================================
// Cache Control
// ============================================================================
ICACHE1:
	begin
		if (hit0 & hit1)
			next_state(IFETCH);
		else begin
			bte_o <= 2'b00;
			cti_o <= 3'b001;
			cyc_o <= 1'b1;
			bl_o <= 6'd3;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			adr_o <= !hit0 ? {pc[31:4],4'b00} : {pcp8[31:4],4'b0000};
			dat_o <= 32'd0;
			next_state(ICACHE2);
		end
	end
ICACHE2:
	if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b10)
			cti_o <= 3'b111;
		if (adr_o[3:2]==2'b11) begin
			wb_nack();
			next_state(ICACHE1);
		end
	end
endcase
end

task dp_store;
input [5:0] stw;
begin
	store_what <= stw;
	wadr <= dp_address;
	pc <= pc + 32'd2;
	next_state(STORE1);
end
endtask

task indexed_store;
input [5:0] stw;
begin
	store_what <= stw;
	pc <= pc + insnsz;
	if (isIndirect) begin
		load_what <= isFar ? `LW_IA3124 : `LW_IAH;
		radr <= NdxAddr;
		next_state(LOAD1);
	end
	else begin
		wadr <= NdxAddr;
		next_state(STORE1);
	end
end
endtask

task ex_store;
input [5:0] stw;
begin
	pc <= pc + 32'd3;
	store_what <= stw;
	wadr <= isFar ? far_address : {16'h0000,near_address};
	next_state(STORE1);
end
endtask

task next_state;
input [7:0] st;
begin
	state <= st;
end
endtask

task wb_burst;
input [5:0] len;
input [31:0] adr;
begin
	bte_o <= 2'b00;
	cti_o <= 3'b001;
	bl_o <= len;
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	sel_o <= 4'hF;
	adr_o <= adr;
end
endtask

task wb_read;
input [31:0] adr;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	case(adr[1:0])
	2'b00:	sel_o <= 4'b0001;
	2'b01:	sel_o <= 4'b0010;
	2'b10:	sel_o <= 4'b0100;
	2'b11:	sel_o <= 4'b1000;
	endcase
	adr_o <= adr;
end
endtask

task wb_write;
input [7:0] dat;
begin
	cyc_o <= 1'b1;
	stb_o <= 1'b1;
	we_o <= 1'b1;
	case(wadr[1:0])
	2'd0:	sel_o <= 4'b0001;
	2'd1:	sel_o <= 4'b0010;
	2'd2:	sel_o <= 4'b0100;
	2'd3:	sel_o <= 4'b1000;
	endcase
	adr_o <= wadr;
	dat_o <= {4{dat}};
end
endtask	

task wb_nack;
begin
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	sel_o <= 4'h0;
	we_o <= 1'b0;
	adr_o <= 32'd0;
	dat_o <= 32'd0;
end
endtask

task load_tsk;
input [7:0] dat;
begin
	case(load_what)
	`LW_BH:
			begin
				b[15:8] <= dat;
				load_what <= `LW_BL;
				next_state(LOAD1);
			end
	`LW_BL:
			begin
				b[7:0] <= dat;
				state <= CALC;
			end
	`LW_CCR:	begin
				next_state(PULL1);
				radr <= radr + 32'd1;
				cf <= dat[0];
				vf <= dat[1];
				zf <= dat[2];
				nf <= dat[3];
				im <= dat[4];
				hf <= dat[5];
				firqim <= dat[6];
				ef <= dat[7];
				if (isRTI) begin
					ir[15:8] <= dat[7] ? 8'hFE : 8'h80;
					ssp <= ssp + 16'd1;
				end
				else if (isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
			end
	`LW_ACCA:	begin
				acca <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_ACCB:	begin
				accb <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_DPR:	begin
				dpr <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_XH:	begin
				load_what <= `LW_XL;
				next_state(LOAD1);
				xr[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_XL:	begin
				xr[7:0] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_YH:	begin
				load_what <= `LW_YL;
				next_state(LOAD1);
				yr[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_YL:	begin
				yr[7:0] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_USPH:	begin
				load_what <= `LW_USPL;
				next_state(LOAD1);
				usp[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_USPL:	begin
				usp[7:0] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_SSPH:	begin
				load_what <= `LW_SSPL;
				next_state(LOAD1);
				usp[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
				end
			end
	`LW_SSPL:	begin
				usp[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 16'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 16'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_PCL:	begin
				pc[7:0] <= dat;
				radr <= radr + 16'd1;
				if (isRTI|isRTS|isRTF|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(IFETCH);
			end
	`LW_PCH:	begin
				pc[15:8] <= dat;
				load_what <= `LW_PCL;
				radr <= radr + 16'd1;
				if (isRTI|isRTS|isRTF|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(LOAD1);
			end
	`LW_PC3124:	begin
				pc[31:24] <= dat;
				load_what <= `LW_PC2316;
				radr <= radr + 16'd1;
				if (isRTI|isRTF|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(LOAD1);
			end
	`LW_PC2316:	begin
				pc[23:16] <= dat;
				load_what <= `LW_PCH;
				radr <= radr + 16'd1;
				if (isRTI|isRTF|isPULS)
					ssp <= ssp + 16'd1;
				else if (isPULU)
					usp <= usp + 16'd1;
				next_state(LOAD1);
			end
	`LW_IAL:
			begin
				ia[7:0] <= dat;
				res[7:0] <= dat;
				radr <= {ia[31:8],dat};
				if (isLEA)
					next_state(IFETCH);
				else if (isStore) begin
					wadr <= {ia[31:8],dat};
					next_state(STORE1);
				end
				else begin
					load_what <= load_what2;
					next_state(LOAD1);
				end
			end
	`LW_IAH:
			begin
				ia[15:8] <= dat;
				res[15:8] <= dat;
				load_what <= `LW_IAL;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	`LW_IA2316:
			begin
				ia[23:16] <= dat;
				load_what <= `LW_IAH;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	`LW_IA3124:
			begin
				$display("Loaded ia[31:24]=%h", dat);
				ia[31:24] <= dat;
				load_what <= `LW_IA2316;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	endcase
end
endtask

endmodule

module rtf6809_icachemem(wclk, wce, wr, wa, i, rclk, rce, pc, insn);
input wclk;
input wce;
input wr;
input [11:0] wa;
input [31:0] i;
input rclk;
input rce;
input [11:0] pc;
output [63:0] insn;
reg [63:0] insn;

reg [63:0] mem [0:511];
reg [11:0] rpc,rpcp8;

always @(posedge wclk)
	if (wce & wr & !wa[2]) mem[wa[11:3]][31:0] <= i;
always @(posedge wclk)
	if (wce & wr &  wa[2]) mem[wa[11:3]][63:32] <= i;
always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp8 <= pc + 12'd8;
wire [63:0] insn0 = mem[rpc[11:3]];
wire [63:0] insn1 = mem[rpcp8[11:3]];
always @(insn0 or insn1 or rpc)
case(rpc[2:0])
3'b000:	insn <= insn0;
3'b001:	insn <= {insn1[7:0],insn0[63:8]};
3'b010:	insn <= {insn1[15:8],insn0[63:16]};
3'b011:	insn <= {insn1[23:0],insn0[63:24]};
3'b100:	insn <= {insn1[31:0],insn0[63:32]};
3'b101:	insn <= {insn1[39:0],insn0[63:40]};
3'b110:	insn <= {insn1[47:0],insn0[63:48]};
3'b111:	insn <= {insn1[55:0],insn0[63:56]};
endcase

endmodule

module rtf6809_itagmem(wclk, wce, wr, wa, invalidate, rclk, rce, pc, hit0, hit1);
input wclk;
input wce;
input wr;
input [31:0] wa;
input invalidate;
input rclk;
input rce;
input [31:0] pc;
output hit0;
output hit1;

reg [31:12] mem [0:255];
reg [0:255] tvalid;
reg [31:0] rpc,rpcp8;
wire [20:0] tag0,tag1;

always @(posedge wclk)
	if (wce & wr) mem[wa[11:4]] <= wa[31:12];
always @(posedge wclk)
	if (invalidate) tvalid <= 256'd0;
	else if (wce & wr) tvalid[wa[11:4]] <= 1'b1;
always @(posedge rclk)
	if (rce) rpc <= pc;
always @(posedge rclk)
	if (rce) rpcp8 <= pc + 32'd8;
assign tag0 = {mem[rpc[11:4]],tvalid[rpc[11:4]]};
assign tag1 = {mem[rpcp8[11:4]],tvalid[rpcp8[11:4]]};

assign hit0 = tag0 == {rpc[31:12],1'b1};
assign hit1 = tag1 == {rpcp8[31:12],1'b1};

endmodule
