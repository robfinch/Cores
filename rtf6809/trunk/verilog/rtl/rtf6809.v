`include "rtf6809_defines.v"
// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
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
// 6733 LUTS / 745 FF's / 5 BRAMs
// 60.0/94.0 MHz
//`define SUPPORT_M32	1'b1
//`define H6309	1'b1

module rtf6809(rst_i, clk_i, halt_i, nmi_i, irq_i, firq_i, vec_i, ba_o, bs_o, lic_o, tsc_i,
	rty_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, we_o, ack_i, sel_o, adr_o, dat_i, dat_o, state);
parameter RESET = 6'd0;
parameter IFETCH = 6'd1;
parameter DECODE = 6'd2;
parameter CALC = 6'd3;
parameter PULL1 = 6'd4;
parameter PUSH1 = 6'd5;
parameter PUSH2 = 6'd6;
parameter LOAD1 = 6'd7;
parameter LOAD2 = 6'd8;
parameter STORE1 = 6'd9;
parameter STORE2 = 6'd10;
parameter OUTER_INDEXING = 6'd11;
parameter OUTER_INDEXING2 = 6'd12;
parameter ICACHE1 = 6'd32;
parameter ICACHE2 = 6'd33;
parameter ICACHE3 = 6'd34;
parameter IBUF1 = 6'd35;
parameter IBUF2 = 6'd36;
parameter IBUF3 = 6'd37;
parameter IBUF4 = 6'd38;
input rst_i;
input clk_i;
input halt_i;
input nmi_i;
input irq_i;
input firq_i;
input [31:0] vec_i;
output reg ba_o;
output reg bs_o;
output lic_o;
input tsc_i;
input rty_i;
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
output [7:0] state;

reg [5:0] state;
reg [5:0] load_what,store_what,load_what2;
reg [31:0] pc;
wire [31:0] pcp2 = pc + 32'd2;
wire [31:0] pcp8 = pc + 32'd8;
wire [63:0] insn;
wire icacheOn = 1'b0;
reg [31:0] ibufadr;
reg [63:0] ibuf;
wire ibufhit = ibufadr==pc;
reg natMd,firqMd;
reg md32;
wire [31:0] mask = md32 ? 32'hFFFFFFFF : 32'h0000FFFF;
reg [1:0] ipg;
reg isFar;
reg isOuterIndexed;
reg [63:0] ir;
wire [9:0] ir10 = {ipg,ir[7:0]};
wire [7:0] ndxbyte;
reg [7:0] dpr;
reg cf,vf,zf,nf,hf,ef;
reg im,firqim;
reg sync_state,wait_state;
wire [7:0] ccr = {ef,firqim,hf,im,nf,zf,vf,cf};
reg [31:0] acca,accb,accd,acce,accf;
//wire [15:0] accd = {acca,accb};
wire [31:0] accq = {acca,accb,acce,accf};
reg [31:0] xr,yr,usp,ssp;
wire [63:0] prod = acca * accb;
reg [15:0] vect;
reg [16:0] res;
reg [8:0] res8;
reg [32:0] res32;
wire res8n = res8[7];
wire res8z = res8[7:0]==8'h00;
wire res8c = res8[8];
wire res16n = res[15];
wire res16z = res[15:0]==16'h0000;
wire res16c = res[16];
wire res32z = res32[31:0]==32'd0;
wire res32n = isFar ? res32[31] : res32[15];
wire res32c = res32[32];
reg [31:0] ia;
reg ic_invalidate;
reg first_ifetch;
reg tsc_latched;
wire tsc = tsc_i|tsc_latched;

reg [31:0] a,b;
wire [7:0] b8 = b[7:0];
reg [31:0] radr,wadr;
reg [31:0] wdat;

reg nmi1,nmi_edge;
reg nmi_armed;

reg isStore;
reg isPULU,isPULS;
reg isPSHS,isPSHU;
reg isRTS,isRTI,isRTF;
reg isLEA;
reg isRMW;

// Data input path multiplexing
reg [7:0] dati;
always @(sel_o or dat_i)
	case(sel_o)
	4'b0001:	dati <= dat_i[7:0];
	4'b0010:	dati <= dat_i[15:8];
	4'b0100:	dati <= dat_i[23:16];
	4'b1000:	dati <= dat_i[31:24];
	default:	dati <= 8'h00;
	endcase

reg [15:0] dati16;
always @(sel_o or dat_i)
	case(sel_o)
	4'b0011:	dati16 <= {dat_i[7:0],dat_i[15:8]};
	4'b0110:	dati16 <= {dat_i[15:8],dat_i[23:16]};
	4'b1100:	dati16 <= {dat_i[23:16],dat_i[31:24]};
	default:	dati16 <= 16'hDEAD;
	endcase

wire [31:0] dati32 = {dat_i[7:0],dat_i[15:8],dat_i[23:16],dat_i[31:24]};

// Evaluate the branch conditional
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

// This chunk of code takes care of calculating the number of bytes stacked
// by a push or pull operation.
//
reg [4:0] cnt;
always @(ir or md32)
begin
	cnt = 	(ir[8] ? 5'd1 : 5'd0) +
			(ir[9] ? (md32 ? 5'd4 : 5'd1) : 5'd0) +
			(ir[10] ? (md32 ? 5'd4 : 5'd1) : 5'd0) +
			(ir[11] ? 5'd1 : 5'd0) +
			(ir[12] ? (md32 ? 5'd4 : 5'd2) : 5'd0) +
			(ir[13] ? (md32 ? 5'd4 : 5'd2) : 5'd0) +
			(ir[14] ? (md32 ? 5'd4 : 5'd2) : 5'd0) +
			(ir[15] ? (isFar ? 5'd4 : 5'd2) : 5'd0)
			;
//  cnt = 0;
//	if (ir[8]) cnt = cnt + 5'd1;	// CC
//	if (ir[9]) cnt = cnt + md32 ? 5'd4 : 5'd1;	// A
//	if (ir[10]) cnt = cnt + md32 ? 5'd4 : 5'd1;	// B
//	if (ir[11]) cnt = cnt + 5'd1;	// DP
//	if (ir[12]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// X
//	if (ir[13]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// Y
//	if (ir[14]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// U/S
//	if (ir[15]) cnt = cnt + 5'd4;	// PC
end

`ifdef H6309
wire isInMem =	ir10==`AIM_DP || ir10==`EIM_DP || ir10==`OIM_DP || ir10==`TIM_DP ||
				ir10==`AIM_NDX || ir10==`EIM_NDX || ir10==`OIM_NDX || ir10==`TIM_NDX ||
				ir10==`AIM_EXT || ir10==`EIM_EXT || ir10==`OIM_EXT || ir10==`TIM_EXT
				;
wire isRMW1 = 	ir10==`AIM_DP || ir10==`EIM_DP || ir10==`OIM_DP ||
				ir10==`NEG_DP || ir10==`COM_DP || ir10==`LSR_DP || ir10==`ROR_DP || ir10==`ASR_DP || ir10==`ASL_DP || ir10==`ROL_DP || ir10==`DEC_DP || ir10==`INC_DP ||
				ir10==`AIM_NDX || ir10==`EIM_NDX || ir10==`OIM_NDX || 
				ir10==`NEG_NDX || ir10==`COM_NDX || ir10==`LSR_NDX || ir10==`ROR_NDX || ir10==`ASR_NDX || ir10==`ASL_NDX || ir10==`ROL_NDX || ir10==`DEC_NDX || ir10==`INC_NDX ||
				ir10==`AIM_EXT || ir10==`EIM_EXT || ir10==`OIM_EXT || 
				ir10==`NEG_EXT || ir10==`COM_EXT || ir10==`LSR_EXT || ir10==`ROR_EXT || ir10==`ASR_EXT || ir10==`ASL_EXT || ir10==`ROL_EXT || ir10==`DEC_EXT || ir10==`INC_EXT
				;
`else
wire isInMem = 1'b0;
wire isRMW1 = 	ir10==`NEG_DP || ir10==`COM_DP || ir10==`LSR_DP || ir10==`ROR_DP || ir10==`ASR_DP || ir10==`ASL_DP || ir10==`ROL_DP || ir10==`DEC_DP || ir10==`INC_DP ||
				ir10==`NEG_NDX || ir10==`COM_NDX || ir10==`LSR_NDX || ir10==`ROR_NDX || ir10==`ASR_NDX || ir10==`ASL_NDX || ir10==`ROL_NDX || ir10==`DEC_NDX || ir10==`INC_NDX ||
				ir10==`NEG_EXT || ir10==`COM_EXT || ir10==`LSR_EXT || ir10==`ROR_EXT || ir10==`ASR_EXT || ir10==`ASL_EXT || ir10==`ROL_EXT || ir10==`DEC_EXT || ir10==`INC_EXT
				;
`endif

wire isIndexed =
	ir10[7:4]==4'h6 || ir10[7:4]==4'hA || ir10[7:4]==4'hE ||
	ir10==`LEAX_NDX || ir10==`LEAY_NDX || ir10==`LEAS_NDX || ir10==`LEAU_NDX
	;
wire isIndirect = ndxbyte[4] & ndxbyte[7];
assign ndxbyte = isInMem ? ir[23:16] : ir[15:8];

// Detect type of interrupt
wire isINT = ir10==`INT;
wire isRST = vect[3:0]==4'hE;
wire isNMI = vect[3:0]==4'hC;
wire isSWI = vect[3:0]==4'hA;
wire isIRQ = vect[3:0]==4'h8;
wire isFIRQ = vect[3:0]==4'h6;
wire isSWI2 = vect[3:0]==4'h4;
wire isSWI3 = vect[3:0]==4'h2;

wire [15:0] near_address = isInMem ? {ir[23:16],ir[31:24]} : {ir[15:8],ir[23:16]};
wire [31:0] far_address = isInMem ? {ir[23:16],ir[31:24],ir[39:32],ir[47:32]} : {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
wire [31:0] dp_address = isInMem ? {16'h0000,dpr,ir[23:16]} : {16'h0000,dpr,ir[15:8]};
wire [31:0] ex_address = isFar ? far_address : {16'h0000,near_address};
wire [31:0] offset8 = isInMem ? {{24{ir[31]}},ir[31:24]} : {{24{ir[23]}},ir[23:16]};
wire [31:0] offset16 = isInMem ? {{16{ir[31]}},ir[31:24],ir[39:32]}: {{16{ir[23]}},ir[23:16],ir[31:24]};
wire [31:0] offset32 = isInMem ? {ir[31:24],ir[39:32],ir[47:40],ir[55:48]} : {ir[23:16],ir[31:24],ir[39:32],ir[47:40]};

// Choose the indexing register
reg [31:0] ndxreg;
always @(ndxbyte or xr or yr or usp or ssp)
	case(ndxbyte[6:5])
	2'b00:	ndxreg <= xr;
	2'b01:	ndxreg <= yr;
	2'b10:	ndxreg <= usp;
	2'b11:	ndxreg <= ssp;
	endcase

reg [31:0] NdxAddr;
always @(ir or ndxreg or ndxbyte or acca or accb or pc or mask or isOuterIndexed or offset8 or offset16 or offset32 or isFar)
	casex({isOuterIndexed,ndxbyte})
	9'b00xxxxxxx:	NdxAddr <= (ndxreg + {{11{ndxbyte[4]}},ndxbyte[4:0]}) & mask;
	9'b01xxx0000:	NdxAddr <= ndxreg;
	9'b01xxx0001:	NdxAddr <= ndxreg;
	9'b01xxx0010:	NdxAddr <= (ndxreg - 32'd1) & mask;
	9'b01xxx0011:	NdxAddr <= (ndxreg - 32'd2) & mask;
	9'b01xxx0100:	NdxAddr <= ndxreg;
	9'b01xxx0101:	NdxAddr <= (ndxreg + {{24{accb[7]}},accb}) & mask;
	9'b01xxx0110:	NdxAddr <= (ndxreg + {{24{acca[7]}},acca}) & mask;
	9'b01xxx1000:	NdxAddr <= (ndxreg + offset8) & mask;
	9'b01xxx1001:	NdxAddr <= (ndxreg + offset16) & mask;
	9'b01xxx1010:	NdxAddr <= (ndxreg & mask) + offset32;
	9'b01xxx1011:	NdxAddr <= (ndxreg + {{16{acca[7]}},{acca,accb}}) & mask;
	9'b01xxx1100:	NdxAddr <= pc + offset8 + 32'd3;
	9'b01xxx1101:	NdxAddr <= pc + offset16 + 32'd4;
	9'b01xxx1110:	NdxAddr <= pc + offset32 + 32'd6;
	9'b01xx01111:	NdxAddr <= isFar ? offset32 : offset16 & 32'h0FFFF;
	9'b01xx11111:	NdxAddr <= offset16 & 32'h0FFFF;
	9'b10xxxxxxx:	NdxAddr <= {{11{ndxbyte[4]}},ndxbyte[4:0]};
	9'b11xxx0000:	NdxAddr <= 32'd0;
	9'b11xxx0001:	NdxAddr <= 32'd0;
	9'b11xxx0010:	NdxAddr <= 32'd0;
	9'b11xxx0011:	NdxAddr <= 32'd0;
	9'b11xxx0100:	NdxAddr <= 32'd0;
	9'b11xxx0101:	NdxAddr <= {{24{accb[7]}},accb};
	9'b11xxx0110:	NdxAddr <= {{24{acca[7]}},acca};
	9'b11xxx1000:	NdxAddr <= offset8;
	9'b11xxx1001:	NdxAddr <= offset16;
	9'b11xxx1010:	NdxAddr <= offset32;
	9'b11xxx1011:	NdxAddr <= {{16{acca[7]}},{acca,accb}};
	9'b11xxx1100:	NdxAddr <= pc + offset8 + 32'd3;
	9'b11xxx1101:	NdxAddr <= pc + offset16 + 32'd4;
	9'b11xxx1110:	NdxAddr <= pc + offset32 + 32'd6;
	9'b11xx01111:	NdxAddr <= isFar ? offset32 : offset16 & 32'h0FFFF;
	9'b11xx11111:	NdxAddr <= offset16 & 32'h0FFFF;
	default:		NdxAddr <= 32'hFFFFFFFF;
	endcase

// Compute instruction length depending on indexing byte
reg [3:0] insnsz;
always @(ndxbyte or isFar)
	casex(ndxbyte)
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
	8'b1xx01111:	insnsz <= isFar ? 4'h6 : 4'h4;
	8'b1xx11111:	insnsz <= 4'h4;
	default:	insnsz <= 4'h2;
	endcase

// Source registers for transfer or exchange instructions.
reg [31:0] src1,src2;
always @*
	case(ir[15:12])
	4'b0000:	src1 <= {acca[7:0],accb[7:0]};
	4'b0001:	src1 <= xr;
	4'b0010:	src1 <= yr;
	4'b0011:	src1 <= usp;
	4'b0100:	src1 <= ssp;
	4'b0101:	src1 <= pcp2;
	4'b1000:	src1 <= acca[7:0];
	4'b1001:	src1 <= accb[7:0];
	4'b1010:	src1 <= ccr;
	4'b1011:	src1 <= dpr;
	4'b1100:	src1 <= 16'h0000;
	4'b1101:	src1 <= 16'h0000;
	4'b1110:	src1 <= acce;
	4'b1111:	src1 <= accf;
	default:	src1 <= 16'h0000;
	endcase
always @*
	case(ir[11:8])
	4'b0000:	src2 <= {acca[7:0],accb[7:0]};
	4'b0001:	src2 <= xr;
	4'b0010:	src2 <= yr;
	4'b0011:	src2 <= usp;
	4'b0100:	src2 <= ssp;
	4'b0101:	src2 <= pcp2;
	4'b1000:	src2 <= acca[7:0];
	4'b1001:	src2 <= accb[7:0];
	4'b1010:	src2 <= ccr;
	4'b1011:	src2 <= dpr;
	4'b1100:	src2 <= 16'h0000;
	4'b1101:	src2 <= 16'h0000;
	4'b1110:	src2 <= acce;
	4'b1111:	src2 <= accf;
	default:	src2 <= 16'h0000;
	endcase

wire isAcca	= 	ir10==`NEGA || ir10==`COMA || ir10==`LSRA || ir10==`RORA || ir10==`ASRA || ir10==`ASLA ||
				ir10==`ROLA || ir10==`DECA || ir10==`INCA || ir10==`TSTA || ir10==`CLRA ||
				ir10==`SUBA_IMM || ir10==`CMPA_IMM || ir10==`SBCA_IMM || ir10==`ANDA_IMM || ir10==`BITA_IMM ||
				ir10==`LDA_IMM || ir10==`EORA_IMM || ir10==`ADCA_IMM || ir10==`ORA_IMM || ir10==`ADDA_IMM ||
				ir10==`SUBA_DP || ir10==`CMPA_DP || ir10==`SBCA_DP || ir10==`ANDA_DP || ir10==`BITA_DP ||
				ir10==`LDA_DP || ir10==`EORA_DP || ir10==`ADCA_DP || ir10==`ORA_DP || ir10==`ADDA_DP ||
				ir10==`SUBA_NDX || ir10==`CMPA_NDX || ir10==`SBCA_NDX || ir10==`ANDA_NDX || ir10==`BITA_NDX ||
				ir10==`LDA_NDX || ir10==`EORA_NDX || ir10==`ADCA_NDX || ir10==`ORA_NDX || ir10==`ADDA_NDX ||
				ir10==`SUBA_EXT || ir10==`CMPA_EXT || ir10==`SBCA_EXT || ir10==`ANDA_EXT || ir10==`BITA_EXT ||
				ir10==`LDA_EXT || ir10==`EORA_EXT || ir10==`ADCA_EXT || ir10==`ORA_EXT || ir10==`ADDA_EXT
				;

wire [31:0] acc = isAcca ? acca : accb;

wire [31:0] sum12 = src1 + src2;

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
reg rhit0;

assign lic_o =	(state==CALC && !isRMW) ||
				(state==DECODE && (
					ir10==`NOP || ir10==`ORCC || ir10==`ANDCC || ir10==`DAA || ir10==`LDMD || ir10==`TFR || ir10==`EXG ||
					ir10==`NEGA || ir10==`COMA || ir10==`LSRA || ir10==`RORA || ir10==`ASRA || ir10==`ROLA || ir10==`DECA || ir10==`INCA || ir10==`TSTA || ir10==`CLRA ||
					ir10==`NEGB || ir10==`COMB || ir10==`LSRB || ir10==`RORB || ir10==`ASRB || ir10==`ROLB || ir10==`DECB || ir10==`INCB || ir10==`TSTB || ir10==`CLRB ||
					ir10==`ASLD || //ir10==`ADDR ||
					ir10==`SUBA_IMM || ir10==`CMPA_IMM || ir10==`SBCA_IMM || ir10==`ANDA_IMM || ir10==`BITA_IMM || ir10==`LDA_IMM || ir10==`EORA_IMM || ir10==`ADCA_IMM || ir10==`ORA_IMM || ir10==`ADDA_IMM ||
					ir10==`SUBB_IMM || ir10==`CMPB_IMM || ir10==`SBCB_IMM || ir10==`ANDB_IMM || ir10==`BITB_IMM || ir10==`LDB_IMM || ir10==`EORB_IMM || ir10==`ADCB_IMM || ir10==`ORB_IMM || ir10==`ADDB_IMM ||
					ir10==`ANDD_IMM || ir10==`ADDD_IMM || ir10==`ADCD_IMM || ir10==`SUBD_IMM || ir10==`SBCD_IMM || ir10==`LDD_IMM ||
					ir10==`LDQ_IMM || ir10==`CMPD_IMM || ir10==`CMPX_IMM || ir10==`CMPY_IMM || ir10==`CMPU_IMM || ir10==`CMPS_IMM ||
					ir10==`BEQ || ir10==`BNE || ir10==`BMI || ir10==`BPL || ir10==`BVS || ir10==`BVC || ir10==`BRA || ir10==`BRN ||
					ir10==`BHI || ir10==`BLS || ir10==`BHS || ir10==`BLO ||
					ir10==`BGT || ir10==`BGE || ir10==`BLT || ir10==`BLE ||
					ir10==`LBEQ || ir10==`LBNE || ir10==`LBMI || ir10==`LBPL || ir10==`LBVS || ir10==`LBVC || ir10==`LBRA || ir10==`LBRN ||
					ir10==`LBHI || ir10==`LBLS || ir10==`LBHS || ir10==`LBLO ||
					ir10==`LBGT || ir10==`LBGE || ir10==`LBLT || ir10==`LBLE
					)
				) ||
				(state==STORE2 && (
					(store_what==`SW_ACCQ3124 && wadr[1:0]==2'b00) ||
					(store_what==`SW_ACCQ70) ||
					(store_what==`SW_ACCA && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_ACCB && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_ACCDH && wadr[1:0]!=2'b11) ||
					(store_what==`SW_ACCDL) ||
					(store_what==`SW_X3124 && wadr[1:0]==2'b00 && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_XL && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_YL && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_USPL && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_SSPL && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_PCL && !(isINT || isPSHS || isPSHU) && !(ir10==`JSR_NDX && isIndirect)) ||
					(store_what==`SW_ACCA70 && !(isINT || isPSHS || isPSHU)) ||
					(store_what==`SW_ACCB70 && !(isINT || isPSHS || isPSHU))
				)) ||
				(state==PUSH2 && ir[15:8]==8'h00 && !isINT) ||
				(state==PULL1 && ir[15:8]==8'h00) ||
				(state==OUTER_INDEXING2 && isLEA) ||
				(state==LOAD2 && 
					(load_what==`LW_ACCA && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_ACCB && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_DPR && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_XL && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_YL && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_USPL && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_SSPL && !(isRTI || isPULU || isPULS)) ||
					(load_what==`LW_PCL) ||
					(load_what==`LW_IAL && !isOuterIndexed && isLEA) ||
					(load_what==`LW_IA3124 && radr[1:0]==2'b00 && !isOuterIndexed && isLEA)
				)
				;

wire lock_bus = load_what==`LW_XH || load_what==`LW_YH || load_what==`LW_USPH || load_what==`LW_SSPH ||
				load_what==`LW_PCH || load_what==`LW_BH || load_what==`LW_IAH || load_what==`LW_PC3124 ||
				load_what==`LW_IA3124 || load_what==`LW_B3124 || 
				load_what==`LW_X3124 || load_what==`LW_Y3124 || load_what==`LW_USP3124 || load_what==`LW_SSP3124 ||
				isRMW ||
				store_what==`SW_ACCDH || store_what==`SW_XH || store_what==`SW_YH || store_what==`SW_USPH || store_what==`SW_SSPH ||
				store_what==`SW_PCH || store_what==`SW_PC3124 || store_what==`SW_ACCQ3124 ||
				store_what==`SW_X3124 || store_what==`SW_Y3124 || store_what==`SW_USP3124 || store_what==`SW_SSP3124
				;

wire isPrefix = ir10==`PG2 || ir10==`PG3 || ir10==`FAR || ir10==`OUTER;

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
	tsc_latched <= tsc_i;

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
	md32 <= `FALSE;
	ipg <= 2'b00;
	isFar <= `FALSE;
	isOuterIndexed <= `FALSE;
	dpr <= 8'h00;
	ibufadr <= 32'h00000000;
	pc <= 32'h0000FFFE;
	ir <= {8{8'h12}};
	ibuf <= {8{8'h12}};
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

// Release any bus lock during the last state of an instruction.
if (lic_o && ack_i && (state==STORE2 || state==LOAD2))
	lock_o <= 1'b0;

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
			isOuterIndexed <= `FALSE;
			ipg <= 2'b00;
			ia <= 32'd0;
			res32 <= 32'd0;
			load_what <= `LW_NOTHING;
			store_what <= `SW_NOTHING;
			if (nmi_edge | firq_i | irq_i)
				sync_state <= `FALSE;
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
				$display("**************************************");
				$display("****** Interrupt *********************");
				$display("**************************************");
				bs_o <= 1'b1;
				ir[7:0] <= `INT;
				ipg <= 2'b11;
				vect <= `IRQ_VECT;
			end
			else begin
				if (sync_state) begin
					ba_o <= 1'b1;
					next_state(IFETCH);
				end
				else if (icacheOn) begin
					if (ihit) begin
						ir <= insn;
					end
					else begin
						ipg <= ipg;
						isFar <= isFar;
						isOuterIndexed <= isOuterIndexed;
						next_state(ICACHE1);
					end
				end
				else begin
					if (ibufhit)
						ir <= ibuf;
					else begin
						ipg <= ipg;
						isFar <= isFar;
						isOuterIndexed <= isOuterIndexed;
						next_state(IBUF1);
					end
				end
			end
		end

		if (first_ifetch) begin
			first_ifetch <= `FALSE;
			case(ir10)
			`ABX:	xr <= res;
			`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
			`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT:
				if (md32) begin
					cf <= (a[31]&b[31])|(a[31]&~res32[31])|(b[31]&~res32[31]);
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					vf <= (res32[31] ^ b[31]) & (1'b1 ^ a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= (a[7]&b[7])|(a[7]&~res8[7])|(b[7]&~res8[7]);
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					vf <= (res8[7] ^ b[7]) & (1'b1 ^ a[7] ^ b[7]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT,
			`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				if (md32) begin
					cf <= (a[31]&b[31])|(a[31]&~res32[31])|(b[31]&~res32[31]);
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					vf <= (res32[31] ^ b[31]) & (1'b1 ^ a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
					cf <= (a[7]&b[7])|(a[7]&~res8[7])|(b[7]&~res8[7]);
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					vf <= (res8[7] ^ b[7]) & (1'b1 ^ a[7] ^ b[7]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					accb <= res8[7:0];
				end
			`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
				if (md32) begin
					cf <= (a[31]&b[31])|(a[31]&~res32[31])|(b[31]&~res32[31]);
					vf <= (res32[31] ^ b[31]) & (1'b1 ^ a[31] ^ b[31]);
					nf <= res32[31];
					zf <= res32[31:0]==32'h0000;
					accd <= res32[31:0];
				end
				else begin
					cf <= (a[15]&b[15])|(a[15]&~res[15])|(b[15]&~res[15]);
					vf <= (res[15] ^ b[15]) & (1'b1 ^ a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
					acca <= res[15:8];
					accb <= res[7:0];
				end
`ifdef H6309
			`ADCD_IMM,`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
				if (md32) begin
					cf <= (a[31]&b[31])|(a[31]&~res32[31])|(b[31]&~res32[31]);
					vf <= (res32[31] ^ b[31]) & (1'b1 ^ a[31] ^ b[31]);
					nf <= res32[31];
					zf <= res32[31:0]==32'h0000;
					acca <= res32[31:24];
					accb <= res32[23:16];
					acce <= res32[15:8];
					accf <= res32[7:0];
				end
				else begin
					cf <= (a[15]&b[15])|(a[15]&~res[15])|(b[15]&~res[15]);
					vf <= (res[15] ^ b[15]) & (1'b1 ^ a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
					acca <= res[15:8];
					accb <= res[7:0];
				end
			`OIM_DP,`OIM_NDX,`OIM_EXT,
			`EIM_DP,`EIM_NDX,`EIM_EXT,
			`TIM_DP,`TIM_NDX,`TIM_EXT,
			`AIM_DP,`AIM_NDX,`AIM_EXT:
				begin
					vf <= 1'b0;
					nf <= res8n;
					zf <= res8z;
				end
`endif
			`ANDA_IMM,`ANDA_DP,`ANDA_NDX,`ANDA_EXT:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= 1'b0;
					acca <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= 1'b0;
					acca <= res8[7:0];
				end
			`ANDB_IMM,`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= 1'b0;
					accb <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= 1'b0;
					accb <= res8[7:0];
				end
`ifdef H6309
			`ANDD_IMM,`ANDD_DP,`ANDD_NDX,`ANDD_EXT:
				begin
					nf <= res16n;
					zf <= res16z;
					vf <= 1'b0;
					acca <= res[15:8];
					accb <= res[7:0];
				end
`endif
			`ASLA:
				if (md32) begin
					cf <= res32c;
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= res8c;
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					vf <= res8[7] ^ res8[8];
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`ASLB:
				if (md32) begin
					cf <= res32c;
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
					cf <= res8c;
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					vf <= res8[7] ^ res8[8];
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					accb <= res8[7:0];
				end
`ifdef H6309
			`ASLD:
				if (md32) begin
					cf <= res32c;
					nf <= res32n;
					zf <= res32z;
					vf <= accq[31]^accq[31];
					acca <= res32[31:24];
					accb <= res32[23:16];
					acce <= res32[15:8];
					accf <= res32[7:0];
				end
				else begin
					cf <= res16c;
					nf <= res16n;
					zf <= res16z;
					vf <= acca[7]^acca[6];
					acca <= res[15:8];
					accb <= res[7:0];
				end
`endif
			`ASL_DP,`ASL_NDX,`ASL_EXT:
				begin
					cf <= res8c;
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					vf <= res8[7] ^ res8[8];
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
				end
			`ASRA:
				if (md32) begin
					cf <= res32c;
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= res8c;
					hf <= (a[3]&b[3])|(a[3]&~res8[3])|(b[3]&~res8[3]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`ASRB:
				if (md32) begin
					cf <= res32c;
					hf <= (a[3]&b[3])|(a[3]&~res32[3])|(b[3]&~res32[3]);
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
			`BITA_IMM,`BITA_DP,`BITA_NDX,`BITA_EXT,
			`BITB_IMM,`BITB_DP,`BITB_NDX,`BITB_EXT:
				if (md32) begin
					vf <= 1'b0;
					nf <= res32n;
					zf <= res32z;
				end
				else begin
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
					acca <= 32'h00;
				end
			`CLRB:
				begin
					vf <= 1'b0;
					cf <= 1'b0;
					nf <= 1'b0;
					zf <= 1'b1;
					accb <= 32'h00;
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
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
				end
				else begin
					cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
				end
			`CMPD_IMM,`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32[31];
					zf <= res32[31:0]==32'h00000000;
				end
				else begin
					cf <= (~a[15]&b[15])|(res[15]&~a[15])|(res[15]&b[15]);
					vf <= (1'b1 ^ res[15] ^ b[15]) & (a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
				end
			`CMPS_IMM,`CMPS_DP,`CMPS_NDX,`CMPS_EXT,
			`CMPU_IMM,`CMPU_DP,`CMPU_NDX,`CMPU_EXT,
			`CMPX_IMM,`CMPX_DP,`CMPX_NDX,`CMPX_EXT,
			`CMPY_IMM,`CMPY_DP,`CMPY_NDX,`CMPY_EXT:
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
				end
				else begin
					cf <= (~a[15]&b[15])|(res[15]&~a[15])|(res[15]&b[15]);
					vf <= (1'b1 ^ res[15] ^ b[15]) & (a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
				end
			`COMA:
				if (md32) begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res8n;
					zf <= res8z;
					acca <= res8[7:0];
				end
			`COMB:
				if (md32) begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
			`DAA:
				begin
					cf <= res8c;
					zf <= res8z;
					nf <= res8n;
					vf <= (res8[7] ^ b[7]) & (1'b1 ^ a[7] ^ b[7]);
					acca <= res8[7:0];
				end
			`DECA:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= res32[31] != acca[31];
					acca <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != acca[7];
					acca <= res8[7:0];
				end
			`DECB:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= res32[31] != acca[31];
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= 1'b0;
					acca <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= 1'b0;
					acca <= res8[7:0];
				end
			`EORB_IMM,`EORB_DP,`EORB_NDX,`EORB_EXT,
			`ORB_IMM,`ORB_DP,`ORB_NDX,`ORB_EXT:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= 1'b0;
					accb <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= 1'b0;
					accb <= res8[7:0];
				end
			`EXG:
				begin
					case(ir[11:8])
					4'b0000:	if (md32) begin
									accd <= src1;
								end
								else begin
									acca <= src1[15:8];
									accb <= src1[7:0];
								end
					4'b0001:	xr <= src1 & mask;
					4'b0010:	yr <= src1 & mask;
					4'b0011:	usp <= src1 & mask;
					4'b0100:	begin ssp <= src1 & mask; nmi_armed <= `TRUE; end
					4'b0101:	pc <= md32 ? src1 : {pc[31:16],src1[15:0]};
					4'b1000:	acca <= src1[31:0];
					4'b1001:	accb <= src1[31:0];
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
					4'b1110:	acce <= src1[7:0];
					4'b1111:	accf <= src1[7:0];
					default:	;
					endcase
					case(ir[15:12])
					4'b0000:	if (md32) begin
									accd <= src2;
								end
								else begin
									acca <= src2[15:8];
									accb <= src2[7:0];
								end
					4'b0001:	xr <= src2 & mask;
					4'b0010:	yr <= src2 & mask;
					4'b0011:	usp <= src2 & mask;
					4'b0100:	begin ssp <= src2 & mask; nmi_armed <= `TRUE; end
					4'b0101:	pc <= md32 ? src2 : {pc[31:16],src2[15:0]};
					4'b1000:	acca <= src2[31:0];
					4'b1001:	accb <= src2[31:0];
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
					4'b1110:	acce <= src2[7:0];
					4'b1111:	accf <= src2[7:0];
					default:	;
					endcase
				end
			`INCA:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= res32[31] != acca[31];
					acca <= res32[31:0];
				end
				else begin
					nf <= res8n;
					zf <= res8z;
					vf <= res8[7] != acca[7];
					acca <= res8[7:0];
				end
			`INCB:
				if (md32) begin
					nf <= res32n;
					zf <= res32z;
					vf <= res32[31] != acca[31];
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					acca <= res32[31:0];
				end
				else begin
					vf <= 1'b0;
					zf <= res8z;
					nf <= res8n;
					acca <= res8[7:0];
				end
			`LDB_IMM,`LDB_DP,`LDB_NDX,`LDB_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					accb <= res32[31:0];
				end
				else begin
					vf <= 1'b0;
					zf <= res8z;
					nf <= res8n;
					accb <= res8[7:0];
				end
			`LDD_IMM,`LDD_DP,`LDD_NDX,`LDD_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					accd <= res32;
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					acca <= res[15:8];
					accb <= res[7:0];
				end
`ifdef H6309
			`LDQ_IMM,`LDQ_DP,`LDQ_NDX,`LDQ_EXT:
				begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					acca <= res32[31:24];
					accb <= res32[23:16];
					acce <= res32[15:8];
					accf <= res32[7:0];
				end
`endif
			`LDU_IMM,`LDU_DP,`LDU_NDX,`LDU_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					usp <= res32[31:0];
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					usp <= res[15:0];
				end
			`LDS_IMM,`LDS_DP,`LDS_NDX,`LDS_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					ssp <= res32[31:0];
					nmi_armed <= 1'b1;
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					ssp <= res[15:0];
					nmi_armed <= 1'b1;
				end
			`LDX_IMM,`LDX_DP,`LDX_NDX,`LDX_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					xr <= res32[31:0];
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					xr <= res[15:0];
				end
			`LDY_IMM,`LDY_DP,`LDY_NDX,`LDY_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
					yr <= res32[31:0];
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
					yr <= res[15:0];
				end
			`LEAS_NDX:
				if (md32) begin ssp <= res32[31:0]; nmi_armed <= 1'b1; end
				else begin ssp <= res[15:0]; nmi_armed <= 1'b1; end
			`LEAU_NDX:
				if (md32)
					usp <= res32[31:0];
				else
					usp <= res[15:0];
			`LEAX_NDX:
				if (md32) begin
					zf <= res32z;
					xr <= res32[31:0];
				end
				else begin
					zf <= res16z;
					xr <= res[15:0];
				end
			`LEAY_NDX:
				if (md32) begin
					zf <= res32z;
					yr <= res32[31:0];
				end
				else begin
					zf <= res16z;
					yr <= res[15:0];
				end
			`LSRA:
				if (md32) begin
					cf <= res32c;
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= res8c;
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`LSRB:
				if (md32) begin
					cf <= res32c;
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					zf <= prod==64'd0;
					cf <= prod[31];
					acca <= prod[63:32];
					accb <= prod[31:0];
				end
				else begin
					cf <= prod[7];
					zf <= res16z;
					acca <= prod[15:8];
					accb <= prod[7:0];
				end
			`NEGA:
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`NEGB:
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					cf <= res32c;
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= res8c;
					vf <= res8[7] ^ res8[8];
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`ROLB:
				if (md32) begin
					cf <= res32c;
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					cf <= res32c;
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= res8c;
					vf <= res8[7] ^ res8[8];
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`RORB:
				if (md32) begin
					cf <= res32c;
					vf <= res32[31] ^ res32[32];
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					acca <= res32[31:0];
				end
				else begin
					cf <= (~a[7]&b[7])|(res8[7]&~a[7])|(res8[7]&b[7]);
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					nf <= res8[7];
					zf <= res8[7:0]==8'h00;
					acca <= res8[7:0];
				end
			`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
				if (md32) begin
					cf <= (~a[31]&b[31])|(res32[31]&~a[31])|(res32[31]&b[31]);
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32n;
					zf <= res32z;
					accb <= res32[31:0];
				end
				else begin
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
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
				end
				else begin
					vf <= 1'b0;
					zf <= res8z;
					nf <= res8n;
				end
			`STD_DP,`STD_NDX,`STD_EXT,
			`STU_DP,`STU_NDX,`STU_EXT,
			`STX_DP,`STX_NDX,`STX_EXT,
			`STY_DP,`STY_NDX,`STY_EXT:
				if (md32) begin
					vf <= 1'b0;
					zf <= res32z;
					nf <= res32n;
				end
				else begin
					vf <= 1'b0;
					zf <= res16z;
					nf <= res16n;
				end
			`TFR:
				begin
					case(ir[11:8])
					4'b0000:	if (md32) begin
									accd <= src1;
								end
								else begin
									acca <= src1[15:8];
									accb <= src1[7:0];
								end
					4'b0001:	xr <= src1 & mask;
					4'b0010:	yr <= src1 & mask;
					4'b0011:	usp <= src1 & mask;
					4'b0100:	begin ssp <= src1 & mask; nmi_armed <= `TRUE; end
					4'b0101:	pc <= md32 ? src1 : {pc[31:16],src1[15:0]};
					4'b1000:	acca <= src1[31:0];
					4'b1001:	accb <= src1[31:0];
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
					4'b1110:	acce <= src1[7:0];
					4'b1111:	accf <= src1[7:0];
					default:	;
					endcase
				end
			`TSTA,`TSTB:
				if (md32) begin
					vf <= 1'b0;
					nf <= res32n;
					zf <= res32z;
				end
				else begin
					vf <= 1'b0;
					nf <= res8n;
					zf <= res8z;
				end
			`TST_DP,`TST_NDX,`TST_EXT:
				begin
					vf <= 1'b0;
					nf <= res8n;
					zf <= res8z;
				end
			`SUBA_IMM,`SUBA_DP,`SUBA_NDX,`SUBA_EXT:
				if (md32) begin
					acca <= res32[31:0];
					nf <= res32n;
					zf <= res32z;
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					cf <= res32c;
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
				end
				else begin
					acca <= res8[7:0];
					nf <= res8n;
					zf <= res8z;
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					cf <= res8c;
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				end
			`SUBB_IMM,`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
				if (md32) begin
					accb <= res32[31:0];
					nf <= res32n;
					zf <= res32z;
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					cf <= res32c;
					hf <= (~a[3]&b[3])|(res32[3]&~a[3])|(res32[3]&b[3]);
				end
				else begin
					accb <= res8[7:0];
					nf <= res8n;
					zf <= res8z;
					vf <= (1'b1 ^ res8[7] ^ b[7]) & (a[7] ^ b[7]);
					cf <= res8c;
					hf <= (~a[3]&b[3])|(res8[3]&~a[3])|(res8[3]&b[3]);
				end
`ifdef H6309
			`SBCD_IMM,`SBCD_DP,`SBCD_NDX,`SBCD_EXT,
`endif
			`SUBD_IMM,`SUBD_DP,`SUBD_NDX,`SUBD_EXT:
				if (md32) begin
					cf <= res32c;
					vf <= (1'b1 ^ res32[31] ^ b[31]) & (a[31] ^ b[31]);
					nf <= res32[31];
					zf <= res32[31:0]==32'h0000;
					accd <= res32[31:0];
				end
				else begin
					cf <= res16c;
					vf <= (1'b1 ^ res[15] ^ b[15]) & (a[15] ^ b[15]);
					nf <= res[15];
					zf <= res[15:0]==16'h0000;
					acca <= res[15:8];
					accb <= res[7:0];
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
		pc <= pc + 32'd1;		// default: increment PC by one
		a <= 32'd0;
		b <= 32'd0;
		if (isIndexed) begin
			casex(ndxbyte)
			8'b1xx00000:	
				if (!isOuterIndexed)
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr + 32'd1) & mask;
					2'b01:	yr <= (yr + 32'd1) & mask;
					2'b10:	usp <= (usp + 32'd1) & mask;
					2'b11:	ssp <= (ssp + 32'd1) & mask;
					endcase
			8'b1xx00001:
				if (!isOuterIndexed)
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr + 32'd2) & mask;
					2'b01:	yr <= (yr + 32'd2) & mask;
					2'b10:	usp <= (usp + 32'd2) & mask;
					2'b11:	ssp <= (ssp + 32'd2) & mask;
					endcase
			8'b1xx00010:
				case(ndxbyte[6:5])
				2'b00:	xr <= (xr - 32'd1) & mask;
				2'b01:	yr <= (yr - 32'd1) & mask;
				2'b10:	usp <= (usp - 32'd1) & mask;
				2'b11:	ssp <= (ssp - 32'd1) & mask;
				endcase
			8'b1xx00011:
				case(ndxbyte[6:5])
				2'b00:	xr <= (xr - 32'd2) & mask;
				2'b01:	yr <= (yr - 32'd2) & mask;
				2'b10:	usp <= (usp - 32'd2) & mask;
				2'b11:	ssp <= (ssp - 32'd2) & mask;
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
				pc <= pcp2;
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
				pc <= pcp2;
				end
		`DAA:
				begin
					if (hf || acca[3:0] > 4'd9)
						res8[3:0] <= acca[3:0] + 4'd6;
					if (cf || acca[7:4] > 4'd9 || (acca[7:4] > 4'd8 && acca[3:0] > 4'd9))
						res8[8:4] <= acca[7:4] + 4'd6;
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
				ef <= 1'b1;
				pc <= pc + 32'd2;
				ir[15:8] <= 8'hFF;
				wait_state <= `TRUE;
				isFar <= `TRUE;
				next_state(PUSH1);
				end
		`LDMD:	begin
				natMd <= ir[8];
				firqMd <= ir[9];
`ifdef SUPPORT_M32
				md32 <= ir[10];
`endif
				pc <= pc + 32'd2;
				end
		`TFR:	pc <= pc + 32'd2;
		`EXG:	pc <= pc + 32'd2;
		`ABX:	res <= xr + accb;
		`PG2:	begin ipg <= 2'b01; ir <= ir[63:8]; next_state(DECODE); end
		`PG3:	begin ipg <= 2'b10;  ir <= ir[63:8]; next_state(DECODE); end
		`FAR:	begin isFar <= `TRUE;  ir <= ir[63:8]; next_state(DECODE); end
		`OUTER:	begin isOuterIndexed <= `TRUE;  ir <= ir[63:8]; next_state(DECODE); end

		`NEGA,`NEGB:	begin res8 <= -acc[7:0]; res32 <= -acc; a <= 32'h00; b <= acc; end
		`COMA,`COMB:	begin res8 <= ~acc[7:0]; res32 <= ~acc; end
		`LSRA,`LSRB:	begin res8 <= {acc[0],1'b0,acc[7:1]}; res32 <= {acc[0],1'b0,acc[31:1]}; end
		`RORA,`RORB:	begin res8 <= {acc[0],cf,acc[7:1]}; res32 <= {acc[0],cf,acc[31:1]}; end
		`ASRA,`ASRB:	begin res8 <= {acc[0],acc[7],acc[7:1]}; res32 <= {acc[0],acc[31],acc[31:1]}; end
		`ASLA,`ASLB:	begin res8 <= {acc[7:0],1'b0}; res32 <= {acc,1'b0}; end
		`ROLA,`ROLB:	begin res8 <= {acc[7:0],cf}; res32 <= {acc,cf}; end
		`DECA,`DECB:	begin res8 <= acc[7:0] - 8'd1; res32 <= acc - 32'd1; end
		`INCA,`INCB:	begin res8 <= acc[7:0] + 8'd1; res32 <= acc + 32'd1; end
		`TSTA,`TSTB:	begin res8 <= acc[7:0]; res32 <= acc; end
		`CLRA,`CLRB:	begin res8 <= 9'h000; res32 <= 33'd0; end

`ifdef H6309
		`ASLD:	
			if (md32)
				res32 <= {acca,accb,acce,accf,1'b0};
			else
				res <= {acca,accb,1'b0};
		`ADDR:
			begin
				case(ir[11:8])
				4'b0000:	{acca,accb} <= sum12;
				4'b0001:	xr <= sum12;
				4'b0010:	yr <= sum12;
				4'b0011:	usp <= sum12;
				4'b0100:	ssp <= sum12;
				4'b0101:	pc <= sum12;
				4'b1000:	acca <= sum12;
				4'b1001:	accb <= sum12;
				4'b1010:	
					begin
						cf <= sum12[0];
						vf <= sum12[1];
						zf <= sum12[2];
						nf <= sum12[3];
						im <= sum12[4];
						hf <= sum12[5];
						firqim <= sum12[6];
						ef <= sum12[7];
					end
				4'b1011:	dpr <= sum12;
				endcase
			end
`endif
		// Immediate mode instructions
		`SUBA_IMM,`SUBB_IMM,`CMPA_IMM,`CMPB_IMM:
			if (md32) begin res32 <= acc - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 16'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] - ir[15:8]; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`SBCA_IMM,`SBCB_IMM:
			if (md32) begin res32 <= acc - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]} - cf; pc <= pc + 16'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] - ir[15:8] - cf; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`ANDA_IMM,`ANDB_IMM,`BITA_IMM,`BITB_IMM:
			if (md32) begin res32 <= acc & {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 32'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] & ir[15:8]; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`LDA_IMM,`LDB_IMM:
			if (md32) begin res32 <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 32'd5; end
			else begin res8 <= ir[15:8]; pc <= pc + 16'd2; end
		`EORA_IMM,`EORB_IMM:
			if (md32) begin res32 <= acc ^ {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 32'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] ^ ir[15:8]; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`ADCA_IMM,`ADCB_IMM:
			if (md32) begin res32 <= acc + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]} + cf; pc <= pc + 16'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] + ir[15:8] + cf; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`ORA_IMM,`ORB_IMM:
			if (md32) begin res32 <= acc | {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 32'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] | ir[15:8]; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
		`ADDA_IMM,`ADDB_IMM:
			if (md32) begin res32 <= acc + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 16'd5; a <= acc; b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; end
			else begin res8 <= acc[7:0] + ir[15:8]; pc <= pc + 16'd2; a <= acc[7:0]; b <= ir[15:8]; end
`ifdef H6309
		`ANDD_IMM:	if (md32) begin
						res32 <= accq & {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5;
					end
					else begin
						res <= {acca[7:0],accb[7:0]} & {ir[15:8],ir[23:16]};
						pc <= pc + 32'd3;
					end
`endif
		`ADDD_IMM:	if (md32) begin
						res32 <= accq + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5;
					end
					else begin 
						res <= {acca[7:0],accb[7:0]} + {ir[15:8],ir[23:16]};
						pc <= pc + 32'd3;
					end
`ifdef H6309
		`ADCD_IMM:	if (md32) begin
						res32 <= accq + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]} + cf;
						pc <= pc + 32'd5;
					end
					else begin 
						res <= {acca[7:0],accb[7:0]} + {ir[15:8],ir[23:16]} + cf;
						pc <= pc + 32'd3;
					end
`endif		
		`SUBD_IMM:	if (md32) begin
						res32 <= accq - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5;
					end
					else begin 
						res <= {acca[7:0],accb[7:0]} - {ir[15:8],ir[23:16]};
						pc <= pc + 32'd3;
					end
`ifdef H6309					
		`SBCD_IMM:	if (md32) begin
						res32 <= accq - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]} - cf;
						pc <= pc + 32'd5;
					end
					else begin 
						res <= {acca[7:0],accb[7:0]} - {ir[15:8],ir[23:16]} - cf;
						pc <= pc + 32'd3;
					end
`endif
		`LDD_IMM:	if (md32) begin
						res32 <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5; 
					end
					else begin 
						res <= {ir[15:8],ir[23:16]};
						pc <= pc + 32'd3;
					end
`ifdef H6309
		`LDQ_IMM:	begin res32 <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]}; pc <= pc + 32'd5; end
`endif
		`LDX_IMM,`LDY_IMM,`LDU_IMM,`LDS_IMM:
					if (md32) begin 
						res32 <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5;
					end
					else begin
						res <= {ir[15:8],ir[23:16]};
						pc <= pc + 32'd3;
					end

		`CMPD_IMM:	if (md32) begin
						res32 <= accq - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 32'd5;
						a <= accq;
						b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
					end
					else begin
						res <= {acca[7:0],accb[7:0]} - {ir[15:8],ir[23:16]};
						pc <= pc + 16'd3;
						a <= {acca[7:0],accb[7:0]};
						b <= {ir[15:8],ir[23:16]};
					end
		`CMPX_IMM:	
					if (md32) begin
						res32 <= xr - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 16'd5;
						a <= xr;
						b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
					end
					else begin
						res <= xr[15:0] - {ir[15:8],ir[23:16]};
						pc <= pc + 16'd3;
						a <= xr[15:0];
						b <= {ir[15:8],ir[23:16]};
					end
		`CMPY_IMM:	
					if (md32) begin
						res32 <= yr - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 16'd5;
						a <= yr;
						b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
					end
					else begin
						res <= yr[15:0] - {ir[15:8],ir[23:16]};
						pc <= pc + 16'd3;
						a <= yr[15:0];
						b <= {ir[15:8],ir[23:16]};
					end
		`CMPU_IMM:
					if (md32) begin
						res32 <= usp - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 16'd5;
						a <= usp;
						b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
					end
					else begin
						res <= usp[15:0] - {ir[15:8],ir[23:16]};
						pc <= pc + 16'd3;
						a <= usp[15:0];
						b <= {ir[15:8],ir[23:16]};
					end
		`CMPS_IMM:
					if (md32) begin
						res32 <= ssp - {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						pc <= pc + 16'd5;
						a <= ssp;
						b <= {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
					end
					else begin
						res <= ssp[15:0] - {ir[15:8],ir[23:16]};
						pc <= pc + 16'd3;
						a <= ssp[15:0];
						b <= {ir[15:8],ir[23:16]};
					end

		// Direct mode instructions
		`NEG_DP,`COM_DP,`LSR_DP,`ROR_DP,`ASR_DP,`ASL_DP,`ROL_DP,`DEC_DP,`INC_DP,`TST_DP:
			begin
				load_what <= `LW_BL;
				radr <= dp_address;
				pc <= pc + 32'd2;
				next_state(LOAD1);
			end
		`SUBA_DP,`CMPA_DP,`SBCA_DP,`ANDA_DP,`BITA_DP,`LDA_DP,`EORA_DP,`ADCA_DP,`ORA_DP,`ADDA_DP,
		`SUBB_DP,`CMPB_DP,`SBCB_DP,`ANDB_DP,`BITB_DP,`LDB_DP,`EORB_DP,`ADCB_DP,`ORB_DP,`ADDB_DP:
			begin
				load_what <= md32 ? `LW_B3124 : `LW_BL;
				radr <= dp_address;
				pc <= pc + 32'd2;
				next_state(LOAD1);
			end
		`SUBD_DP,`ADDD_DP,`LDD_DP,`CMPD_DP,`ADCD_DP,`SBCD_DP:
			if (md32) begin
				load_what <= `LW_B3124;
				pc <= pc + 32'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
			else begin
				load_what <= `LW_BH;
				pc <= pc + 32'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
`ifdef H6309
		`LDQ_DP:
			begin
				load_what <= `LW_B3124;
				pc <= pc + 32'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`STQ_DP:	dp_store(`SW_ACCQ3124);
`endif
		`CMPX_DP,`LDX_DP,`LDU_DP,`LDS_DP,
		`CMPY_DP,`CMPS_DP,`CMPU_DP,`LDY_DP:
			if (md32) begin
				load_what <= `LW_B3124;
				pc <= pc + 32'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
			else begin
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
		`STA_DP:	dp_store(md32 ? `SW_ACCA3124 : `SW_ACCA);
		`STB_DP:	dp_store(md32 ? `SW_ACCB3124 : `SW_ACCB);
		`STD_DP:	dp_store(md32 ? `SW_ACCQ3124 : `SW_ACCDH);
		`STU_DP:	dp_store(md32 ? `SW_USP3124 : `SW_USPH);
		`STS_DP:	dp_store(md32 ? `SW_SSP3124 : `SW_SSPH);
		`STX_DP:	dp_store(md32 ? `SW_X3124 : `SW_XH);
		`STY_DP:	dp_store(md32 ? `SW_Y3124 : `SW_YH);
`ifdef H6309
		`AIM_DP,`EIM_DP,`OIM_DP,`TIM_DP:
			begin
				load_what <= `LW_BL;
				pc <= pc + 32'd3;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`AIM_NDX,`EIM_NDX,`OIM_NDX,`TIM_NDX:
			begin
				pc <= pc + insnsz + 32'd1;
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
`endif
		// Indexed mode instructions
		`NEG_NDX,`COM_NDX,`LSR_NDX,`ROR_NDX,`ASR_NDX,`ASL_NDX,`ROL_NDX,`DEC_NDX,`INC_NDX,`TST_NDX:
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
		`SUBA_NDX,`CMPA_NDX,`SBCA_NDX,`ANDA_NDX,`BITA_NDX,`LDA_NDX,`EORA_NDX,`ADCA_NDX,`ORA_NDX,`ADDA_NDX,
		`SUBB_NDX,`CMPB_NDX,`SBCB_NDX,`ANDB_NDX,`BITB_NDX,`LDB_NDX,`EORB_NDX,`ADCB_NDX,`ORB_NDX,`ADDB_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= md32 ? `LW_B3124 : `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					b <= 16'd0;
					load_what <= md32 ? `LW_B3124 : `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
		`SUBD_NDX,`ADDD_NDX,`LDD_NDX,`CMPD_NDX,`ADCD_NDX,`SBCD_NDX:
			if (md32) begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					load_what <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
			else begin
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
`ifdef H6309
		`LDQ_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					load_what <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
		`STQ_NDX:	indexed_store(`SW_ACCQ3124);
`endif
		`CMPX_NDX,`LDX_NDX,`LDU_NDX,`LDS_NDX,
		`CMPY_NDX,`CMPS_NDX,`CMPU_NDX,`LDY_NDX:
			if (md32) begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= isFar ? `LW_IA3124 : `LW_IAH;
					load_what2 <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					load_what <= `LW_B3124;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
			else begin
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
		`STA_NDX:	indexed_store(md32 ? `SW_ACCA3124 : `SW_ACCA);
		`STB_NDX:	indexed_store(md32 ? `SW_ACCB3124 : `SW_ACCB);
		`STD_NDX:	indexed_store(md32 ? `SW_ACCQ3124 : `SW_ACCDH);
		`STU_NDX:	indexed_store(md32 ? `SW_USP3124 : `SW_USPH);
		`STS_NDX:	indexed_store(md32 ? `SW_SSP3124 : `SW_SSPH);
		`STX_NDX:	indexed_store(md32 ? `SW_X3124 : `SW_XH);
		`STY_NDX:	indexed_store(md32 ? `SW_Y3124 : `SW_YH);

`ifdef H6309
		`AIM_EXT,`OIM_EXT,`EIM_EXT,`TIM_EXT,
`endif
		// Extended mode instructions
		`NEG_EXT,`COM_EXT,`LSR_EXT,`ROR_EXT,`ASR_EXT,`ASL_EXT,`ROL_EXT,`DEC_EXT,`INC_EXT,`TST_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
		`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
		`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
			begin
				load_what <= md32 ? `LW_B3124 : `LW_BL;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
		`SUBD_EXT,`ADDD_EXT,`LDD_EXT,`CMPD_EXT,`ADCD_EXT,`SBCD_EXT:
			if (md32) begin
				load_what <= `LW_B3124;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
			else begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
`ifdef H6309
		`LDQ_EXT:
			begin
				load_what <= `LW_B3124;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
		`STQ_EXT:	ex_store(`SW_ACCQ3124);
`endif
		`CMPX_EXT,`LDX_EXT,`LDU_EXT,`LDS_EXT,
		`CMPY_EXT,`CMPS_EXT,`CMPU_EXT,`LDY_EXT:
			begin
				load_what <= md32 ? `LW_B3124 : `LW_BH;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd5 : 32'd3);
				next_state(LOAD1);
			end
		`CLR_EXT:
			begin
				ex_store(`SW_RES8);
				res8 <= 9'h00;
			end
		`STA_EXT:	ex_store(md32 ? `SW_ACCA3124 : `SW_ACCA);
		`STB_EXT:	ex_store(md32 ? `SW_ACCB3124 : `SW_ACCB);
		`STD_EXT:	ex_store(md32 ? `SW_ACCQ3124 : `SW_ACCDH);
		`STU_EXT:	ex_store(md32 ? `SW_USP3124 : `SW_USPH);
		`STS_EXT:	ex_store(md32 ? `SW_SSP3124 : `SW_SSPH);
		`STX_EXT:	ex_store(md32 ? `SW_X3124 : `SW_XH);
		`STY_EXT:	ex_store(md32 ? `SW_Y3124 : `SW_YH);

		`BSR:
			if (isFar) begin
				store_what <= `SW_PC3124;
				wadr <= ssp - 16'd4;
				ssp <= ssp - 16'd4;
				pc <= pc + 32'd5;
				next_state(STORE1);
			end
			else begin
				store_what <= `SW_PCH;
				wadr <= ssp - 16'd2;
				ssp <= ssp - 16'd2;
				pc <= pc + 32'd2;
				next_state(STORE1);
			end
		`LBSR:
			if (isFar) begin
				store_what <= `SW_PC3124;
				wadr <= ssp - 16'd4;
				ssp <= ssp - 16'd4;
				pc <= pc + 32'd5;
				next_state(STORE1);
			end
			else begin
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
			if (md32) begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IA3124;
					radr <= NdxAddr;
					state <= LOAD1;
				end
				else
					res32 <= NdxAddr;
			end
			else begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IAH;
					radr <= NdxAddr;
					state <= LOAD1;
				end
				else
					res <= NdxAddr[15:0];
			end
		`PSHU,`PSHS:
			begin
				next_state(PUSH1);
				pc <= pc + 16'd2;
			end
		`PULS:
			begin
				radr <= ssp;
				next_state(PULL1);
				pc <= pc + 16'd2;
			end
		`PULU:
			begin
				radr <= usp;
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
				isFar <= `TRUE;
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
		// If the processor was in the wait state before the interrupt occurred
		// the registers will have already been pushed. All that needs to be
		// done is to vector to the interrupt routine.
		`INT:
			begin
				if (wait_state) begin
					wait_state <= `FALSE;
					radr <= vect;
					load_what <= `LW_PCH;
					pc <= 32'h0000FFFE;
					next_state(LOAD1);
				end
				else begin
					if (isNMI | isIRQ | isSWI | isSWI2 | isSWI3) begin
						ir[15:8] <= 8'hFF;
						ef <= 1'b1;
					end
					else if (isFIRQ) begin
						if (natMd) begin
							ef <= firqMd;
							ir[15:8] <= firqMd ? 8'hFF : 8'h81;
						end
						else begin
							ir[15:8] <= 8'h81;
							ef <= 1'b0;
						end
					end
					pc <= pc;
					isFar <= `TRUE;
					next_state(PUSH1);
				end
			end
		default:	;
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
		`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
			if (md32)
				res32 <= {acca[7:0],accb[7:0],acce[7:0],accf[7:0]} - b[31:0];
			else
				res <= {acca[7:0],accb[7:0]} - b[15:0];
		`SBCD_DP,`SBCD_NDX,`SBCD_EXT:
			if (md32)
				res32 <= {acca[7:0],accb[7:0],acce[7:0],accf[7:0]} - b[31:0] - cf;
			else
				res <= {acca[7:0],accb[7:0]} - b[15:0] - cf;
		`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
			if (md32)
				res32 <= {acca[7:0],accb[7:0],acce[7:0],accf[7:0]} + b[31:0];
			else
				res <= {acca[7:0],accb[7:0]} + b[15:0];
		`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
			if (md32)
				res32 <= {acca[7:0],accb[7:0],acce[7:0],accf[7:0]} + b[31:0] + cf;
			else
				res <= {acca[7:0],accb[7:0]} + b[15:0] + cf;
		`LDD_DP,`LDD_NDX,`LDD_EXT:		
			if (md32)
				res32 <= b[31:0];
			else
				res <= b[15:0];

		`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`SUBA_DP,`SUBA_NDX,`SUBA_EXT,
		`CMPB_DP,`CMPB_NDX,`CMPB_EXT,
		`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
				if (md32)
					res32 <= acc - b;
				else
					res8 <= acc[7:0] - b8;
		
		`SBCA_DP,`SBCA_NDX,`SBCA_EXT,
		`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
				if (md32)
					res32 <= acc - b - cf;
				else
					res8 <= acc[7:0] - b8 - cf;
		`BITA_DP,`BITA_NDX,`BITA_EXT,
		`ANDA_DP,`ANDA_NDX,`ANDA_EXT,
		`BITB_DP,`BITB_NDX,`BITB_EXT,
		`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
				if (md32)
					res32 <= acc & b;
				else
					res8 <= acc[7:0] & b8;
		`LDA_DP,`LDA_NDX,`LDA_EXT,
		`LDB_DP,`LDB_NDX,`LDB_EXT:
				if (md32)
					res32 <= b;
				else
					res8 <= b8;
		`EORA_DP,`EORA_NDX,`EORA_EXT,
		`EORB_DP,`EORB_NDX,`EORB_EXT:
				if (md32)
					res32 <= acc ^ b;
				else
					res8 <= acc[7:0] ^ b8;
		`ADCA_DP,`ADCA_NDX,`ADCA_EXT,
		`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				if (md32)
					res32 <= acc + b + cf;
				else
					res8 <= acc[7:0] + b8 + cf;
		`ORA_DP,`ORA_NDX,`ORA_EXT,
		`ORB_DP,`ORB_NDX,`ORB_EXT:
				if (md32)
					res32 <= acc | b;
				else
					res8 <= acc[7:0] | b8;
		`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
		`ADDB_DP,`ADDB_NDX,`ADDB_EXT:
				if (md32)
					res32 <= acc + b;
				else
					res8 <= acc[7:0] + b8;
		
		`LDU_DP,`LDS_DP,`LDX_DP,`LDY_DP,
		`LDU_NDX,`LDS_NDX,`LDX_NDX,`LDY_NDX,
		`LDU_EXT,`LDS_EXT,`LDX_EXT,`LDY_EXT:	if (md32) res32 <= b; else res <= b[15:0];
		`CMPX_DP,`CMPX_NDX,`CMPX_EXT:	if (md32) res32 <= xr - b; else res <= xr[15:0] - b[15:0];
		`CMPY_DP,`CMPY_NDX,`CMPY_EXT:	if (md32) res32 <= yr - b; else res <= yr[15:0] - b[15:0];
		`CMPS_DP,`CMPS_NDX,`CMPS_EXT:	if (md32) res32 <= ssp - b; else res <= ssp[15:0] - b[15:0];
		`CMPU_DP,`CMPU_NDX,`CMPU_EXT:	if (md32) res32 <= usp - b; else res <= usp[15:0] - b[15:0];

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
		
		`AIM_DP,`AIM_NDX,`AIM_EXT:	begin res8 <= ir[15:8] & b8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`OIM_DP,`OIM_NDX,`OIM_EXT:	begin res8 <= ir[15:8] | b8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`EIM_DP,`EIM_NDX,`OIM_EXT:  begin res8 <= ir[15:8] ^ b8; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TIM_DP,`TIM_NDX,`TIM_EXT:	begin res8 <= ir[15:8] & b8; end
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
		lock_o <= lock_bus;
		if (radr[1:0]==2'b00 && (load_what==`LW_B3124 || load_what==`LW_IA3124))
			wb_read4(radr);
		else if (radr[0]==1'b0 && load_what==`LW_BH)
			wb_read2(radr);
		else
			wb_read(radr);
		if (!tsc)
			next_state(LOAD2);
	end
`ifdef SUPPORT_DCACHE
	else if (dhit)
		load_tsk(rdat,16'hDEAD,32'hDEADDEAD);
	else begin
		retstate <= LOAD1;
		state <= DCACHE1;
	end
`endif
LOAD2:
	// On a tri-state condition abort the bus cycle and retry the load.
	if (tsc|rty_i) begin
		wb_nack();
		next_state(LOAD1);
	end
	else if (ack_i) begin
		wb_nack();
		load_tsk(dati,dati16,dati32);
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
		lock_o <= lock_bus;
		case(store_what)
		`SW_ACCQ3124:
				if (wadr[1:0]==2'b00)
					wb_write4({accf[7:0],acce[7:0],accb[7:0],acca[7:0]});
				else
					wb_write(wadr,acca);
		`SW_ACCQ2316:	wb_write(wadr,accb[7:0]);
		`SW_ACCQ158:	wb_write(wadr,acce[7:0]);
		`SW_ACCQ70:		wb_write(wadr,accf[7:0]);
		`SW_ACCDH:
				if (wadr[1:0]!=2'b11)
					wb_write2({accb[7:0],acca[7:0]});
				else
					wb_write(wadr,acca[7:0]);
		`SW_ACCDL:	wb_write(wadr,accb[7:0]);
		`SW_ACCA:	wb_write(wadr,acca[7:0]);
		`SW_ACCB:	wb_write(wadr,accb[7:0]);
		`SW_DPR:	wb_write(wadr,dpr);
		`SW_XL:	wb_write(wadr,xr[7:0]);
		`SW_XH:
				if (wadr[1:0]!=2'b11)
					wb_write2({xr[7:0],xr[15:8]});
				else
					wb_write(wadr,xr[15:8]);
		`SW_X2316:	wb_write(wadr,xr[23:16]);
		`SW_X3124:
				if (wadr[1:0]==2'b00)
					wb_write4({xr[7:0],xr[15:8],xr[23:16],xr[31:24]});
				else
					wb_write(wadr,xr[31:24]);
		`SW_YL:	wb_write(wadr,yr[7:0]);
		`SW_YH:	wb_write(wadr,yr[15:8]);
		`SW_Y2316:	wb_write(wadr,yr[23:16]);
		`SW_Y3124:	wb_write(wadr,yr[31:24]);
		`SW_USPL:	wb_write(wadr,usp[7:0]);
		`SW_USPH:	wb_write(wadr,usp[15:8]);
		`SW_USP2316:	wb_write(wadr,usp[23:16]);
		`SW_USP3124:	wb_write(wadr,usp[31:24]);
		`SW_SSPL:	wb_write(wadr,ssp[7:0]);
		`SW_SSPH:	wb_write(wadr,ssp[15:8]);
		`SW_SSP2316:	wb_write(wadr,ssp[23:16]);
		`SW_SSP3124:	wb_write(wadr,ssp[31:24]);
		`SW_PC3124:	wb_write(wadr,pc[31:24]);
		`SW_PC2316:	wb_write(wadr,pc[23:16]);
		`SW_PCH:	wb_write(wadr,pc[15:8]);
		`SW_PCL:	wb_write(wadr,pc[7:0]);
		`SW_CCR:	wb_write(wadr,ccr);
		`SW_RES8:	wb_write(wadr,res8[7:0]);
		`SW_RES16H:	wb_write(wadr,res[15:8]);
		`SW_RES16L:	wb_write(wadr,res[7:0]);
		`SW_DEF8:	wb_write(wadr,wdat);
		`SW_ACCA3124:	wb_write(wadr,acca[31:24]);
		`SW_ACCA2316:	wb_write(wadr,acca[23:16]);
		`SW_ACCA158:	wb_write(wadr,acca[15:8]);
		`SW_ACCA70:		wb_write(wadr,acca[7:0]);
		`SW_ACCB3124:	wb_write(wadr,accb[31:24]);
		`SW_ACCB2316:	wb_write(wadr,accb[23:16]);
		`SW_ACCB158:	wb_write(wadr,accb[15:8]);
		`SW_ACCB70:		wb_write(wadr,accb[7:0]);
		default:	wb_write(wadr,wdat);
		endcase
`ifdef SUPPORT_DCACHE
		radr <= wadr;		// Do a cache read to test the hit
`endif
		if (!tsc)
			next_state(STORE2);
	end
	
// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
STORE2:
	// On a tri-state condition abort the bus cycle and retry the store.
	if (tsc|rty_i) begin
		wb_nack();
		next_state(STORE1);
	end
	else if (ack_i) begin
		wb_nack();
		wdat <= dat_o;
		wadr <= wadr + 32'd1;
		next_state(IFETCH);
		case(store_what)
		`SW_ACCA3124:
				begin
				store_what <= `SW_ACCA2316;
				next_state(STORE1);
				end
		`SW_ACCA2316:
				begin
				store_what <= `SW_ACCA158;
				next_state(STORE1);
				end
		`SW_ACCA158:
				begin
				store_what <= `SW_ACCA70;
				next_state(STORE1);
				end
		`SW_ACCA70:
				begin
				next_state(IFETCH);
				end
		`SW_ACCB3124:
				begin
				store_what <= `SW_ACCB2316;
				next_state(STORE1);
				end
		`SW_ACCB2316:
				begin
				store_what <= `SW_ACCB158;
				next_state(STORE1);
				end
		`SW_ACCB158:
				begin
				store_what <= `SW_ACCB70;
				next_state(STORE1);
				end
		`SW_ACCB70:
				begin
				next_state(IFETCH);
				end
		`SW_ACCQ3124:
				if (wadr[1:0]==2'b00)
					next_state(IFETCH);
				else begin
					store_what <= `SW_ACCQ2316;
					next_state(STORE1);
				end
		`SW_ACCQ2316:
				begin
				store_what <= `SW_ACCQ158;
				next_state(STORE1);
				end
		`SW_ACCQ158:
				begin
				store_what <= `SW_ACCQ70;
				next_state(STORE1);
				end
		`SW_ACCQ70:
				begin
				next_state(IFETCH);
				lock_o <= 1'b0;
				end
		`SW_CCR:
			begin
				if (isINT) begin
					im <= 1'b1;
					firqim <= 1'b1;
				end
				next_state(PUSH2);
			end
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
				if (wadr[1:0]!=2'b11) begin
					wadr <= wadr + 32'd2;
					next_state(IFETCH);
				end
				else
					next_state(STORE1);
			end
		`SW_ACCDL:	next_state(IFETCH);
		`SW_DPR:	next_state(PUSH2);
		`SW_X3124:
			begin
				store_what <= `SW_X2316;
				if (wadr[1:0]==2'b00) begin
					wadr <= wadr + 32'd4;
					if (isINT | isPSHS | isPSHU)
						next_state(PUSH2);
					else	// STX
						next_state(IFETCH);
				end
				else begin
					next_state(STORE1);
				end
			end
		`SW_X2316:
			begin
				store_what <= `SW_XH;
				next_state(STORE1);
			end
		`SW_XH:
			if (wadr[1:0]!=2'b11) begin
				wadr <= wadr + 32'd2;
				if (isINT | isPSHS | isPSHU)
					next_state(PUSH2);
				else	// STX
					next_state(IFETCH);
			end
			else begin
				store_what <= `SW_XL;
				next_state(STORE1);
			end
		`SW_XL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STX
				next_state(IFETCH);
		`SW_Y3124:
			begin
				store_what <= `SW_Y2316;
				next_state(STORE1);
			end
		`SW_Y2316:
			begin
				store_what <= `SW_YH;
				next_state(STORE1);
			end
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
		`SW_USP3124:
			begin
				store_what <= `SW_USP2316;
				next_state(STORE1);
			end
		`SW_USP2316:
			begin
				store_what <= `SW_USPH;
				next_state(STORE1);
			end
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
		`SW_SSP3124:
			begin
				store_what <= `SW_SSP2316;
				next_state(STORE1);
			end
		`SW_SSP2316:
			begin
				store_what <= `SW_SSPH;
				next_state(STORE1);
			end
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
				next_state(STORE1);
			end
		`SW_PC2316:
			begin
				store_what <= `SW_PCH;
				next_state(STORE1);
			end
		`SW_PCH:
			begin
				store_what <= `SW_PCL;
				next_state(STORE1);
			end
		`SW_PCL:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else begin	// JSR
				next_state(IFETCH);
				case(ir10)
				`BSR:	if (isFar)
							pc <= pc + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						else
							pc <= pc + {{24{ir[15]}},ir[15:8]};
				`LBSR:	if (isFar)
							pc <= pc + {ir[15:8],ir[23:16],ir[31:24],ir[39:32]};
						else
							pc <= pc + {{16{ir[15]}},ir[15:8],ir[23:16]};
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
			wadr <= (ssp - cnt) & mask;
			ssp <= (ssp - cnt) & mask;
		end
		else begin	// PSHU
			wadr <= (usp - cnt) & mask;
			usp <= (usp - cnt) & mask;
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
			store_what <= md32 ? `SW_X3124 : `SW_XH;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			store_what <= md32 ? `SW_Y3124 : `SW_YH;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			if (isINT | isPSHS)
				store_what <= md32 ? `SW_USP3124 : `SW_USPH;
			else
				store_what <= md32 ? `SW_SSP3124 : `SW_SSPH;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			store_what <= isFar ? `SW_PC3124 : `SW_PCH;
			ir[15] <= 1'b0;
		end
		else begin
			if (isINT) begin
				radr <= vect;
				if (vec_i != 32'h0) begin
					$display("vector: %h", vec_i);
					pc <= vec_i;
					next_state(IFETCH);
				end
				else begin
					pc[31:16] <= 16'h0000;
					load_what <= `LW_PCH;
					next_state(LOAD1);
				end
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
			load_what <= md32 ? `LW_X3124 : `LW_XH;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			load_what <= md32 ? `LW_Y3124 : `LW_YH;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			if (ir10==`PULU)
				load_what <= md32 ? `LW_SSP3124 : `LW_SSPH;
			else
				load_what <= md32 ? `LW_USP3124 : `LW_USPH;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			load_what <= isFar ? `LW_PC3124 : `LW_PCH;
			ir[15] <= 1'b0;
		end
		else
			next_state(IFETCH);
	end
// ----------------------------------------------------------------------------
// Outer Indexing Support
// ----------------------------------------------------------------------------
OUTER_INDEXING:
	begin
		casex(ndxbyte)
		8'b0xxxxxxx:	radr <= radr + (ndxreg & mask);
		8'b1xxx0000:	begin
							radr <= radr + (ndxreg & mask);
							case(ndxbyte[6:5])
							2'b00:	xr <= (xr + 32'd1) & mask;
							2'b01:	yr <= (yr + 32'd1) & mask;
							2'b10:	usp <= (usp + 32'd1) & mask;
							2'b11:	ssp <= (ssp + 32'd1) & mask;
							endcase
						end
		8'b1xxx0001:	begin
							radr <= radr + (ndxreg & mask);
							case(ndxbyte[6:5])
							2'b00:	xr <= (xr + 32'd2) & mask;
							2'b01:	yr <= (yr + 32'd2) & mask;
							2'b10:	usp <= (usp + 32'd2) & mask;
							2'b11:	ssp <= (ssp + 32'd2) & mask;
							endcase
						end
		8'b1xxx0010:	radr <= radr + (ndxreg & mask);
		8'b1xxx0011:	radr <= radr + (ndxreg & mask);
		8'b1xxx0100:	radr <= radr + (ndxreg & mask);
		8'b1xxx0101:	radr <= radr + (ndxreg & mask);
		8'b1xxx0110:	radr <= radr + (ndxreg & mask);
		8'b1xxx1000:	radr <= radr + (ndxreg & mask);
		8'b1xxx1001:	radr <= radr + (ndxreg & mask);
		8'b1xxx1010:	radr <= radr + (ndxreg & mask);
		8'b1xxx1011:	radr <= radr + (ndxreg & mask);
		default:	radr <= radr;
		endcase
		next_state(OUTER_INDEXING2);
	end
OUTER_INDEXING2:
	begin
		wadr <= radr;
		res32 <= radr;
		res <= radr[15:0];
		load_what <= load_what2;
		if (isLEA)
			next_state(IFETCH);
		else if (isStore)
			next_state(STORE1);
		else
			next_state(LOAD1);
	end

// ============================================================================
// Cache Control
// ============================================================================
ICACHE1:
	begin
		if (hit0 & hit1)
			next_state(IFETCH);
		else if (!tsc) begin
			rhit0 <= hit0;
			bte_o <= 2'b00;
			cti_o <= 3'b001;
			cyc_o <= 1'b1;
			bl_o <= 6'd3;
			stb_o <= 1'b1;
			sel_o <= 4'hF;
			we_o <= 1'b0;
			adr_o <= !hit0 ? {pc[31:4],4'b00} : {pcp8[31:4],4'b0000};
			dat_o <= 32'd0;
			next_state(ICACHE2);
		end
	end
// If tsc is asserted during an instruction cache fetch, then abort the fetch
// cycle, and wait until tsc deactivates.
ICACHE2:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(ICACHE3);
	end
	else if (ack_i) begin
		adr_o[3:2] <= adr_o[3:2] + 2'd1;
		if (adr_o[3:2]==2'b10)
			cti_o <= 3'b111;
		if (adr_o[3:2]==2'b11) begin
			wb_nack();
			next_state(ICACHE1);
		end
	end
// Restart a cache load aborted by the TSC signal. A registered version of the
// hit signal must be used as the cache may be partially updated.
ICACHE3:
	if (!tsc) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		cyc_o <= 1'b1;
		bl_o <= 6'd3;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		sel_o <= 4'hF;
		adr_o <= !rhit0 ? {pc[31:4],4'b00} : {pcp8[31:4],4'b0000};
		dat_o <= 32'd0;
		next_state(ICACHE2);
	end
IBUF1:
	if (!tsc) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		cyc_o <= 1'b1;
		bl_o <= 6'd2;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		sel_o <= 4'hF;
		adr_o <= {pc[31:2],2'b00};
		dat_o <= 32'd0;
		next_state(IBUF2);
	end
IBUF2:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibuf <= dat_i;
		2'b01:	ibuf[23:0] <= dat_i[31:8];
		2'b10:	ibuf[15:0] <= dat_i[31:16];
		2'b11:	ibuf[7:0] <= dat_i[31:24];
		endcase
		next_state(IBUF3);
	end
IBUF3:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 32'd4;
		case(pc[1:0])
		2'b00:	ibuf[63:32] <= dat_i;
		2'b01:	ibuf[55:24] <= dat_i;
		2'b10:	ibuf[47:16] <= dat_i;
		2'b11:	ibuf[39: 8] <= dat_i;
		endcase
		next_state(IBUF4);
	end
IBUF4:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		case(pc[1:0])
		2'b00:	;
		2'b01:	ibuf[63:56] <= dat_i[7:0];
		2'b10:	ibuf[63:48] <= dat_i[15:0];
		2'b11:	ibuf[63:40] <= dat_i[23:0];
		endcase
		ibufadr <= pc;
		next_state(IFETCH);
	end

endcase
end

// ============================================================================
// Supporting Tasks
// ============================================================================
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
	pc <= pc + (isFar ? 32'd5 : 32'd3);
	store_what <= stw;
	wadr <= ex_address;
	next_state(STORE1);
end
endtask

task next_state;
input [5:0] st;
begin
	state <= st;
end
endtask

task wb_burst;
input [5:0] len;
input [31:0] adr;
begin
	if (!tsc) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		bl_o <= len;
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= adr;
	end
end
endtask

task wb_read;
input [31:0] adr;
begin
	if (!tsc) begin
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
end
endtask

task wb_read4;
input [31:0] adr;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= adr;
	end
end
endtask

task wb_read2;
input [31:0] adr;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		sel_o <= adr[1] ? 4'b1100 : 4'b0011;
		adr_o <= adr;
	end
end
endtask

task wb_write;
input [31:0] adr;
input [7:0] dat;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		case(wadr[1:0])
		2'd0:	sel_o <= 4'b0001;
		2'd1:	sel_o <= 4'b0010;
		2'd2:	sel_o <= 4'b0100;
		2'd3:	sel_o <= 4'b1000;
		endcase
		adr_o <= adr;
		dat_o <= {4{dat}};
	end
end
endtask	

task wb_write4;
input [31:0] dat;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		sel_o <= 4'hF;
		adr_o <= wadr;
		dat_o <= dat;
	end
end
endtask	

task wb_write2;
input [15:0] dat;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		case(wadr[1:0])
		2'b00:	begin sel_o <= 4'b0011; dat_o <= {2{dat}}; end
		2'b01:	begin sel_o <= 4'b0110; dat_o <= {8'h00,dat,8'h00}; end
		2'b10:	begin sel_o <= 4'b1100; dat_o <= {2{dat}}; end
		2'b11:	begin sel_o <= 4'b1000; dat_o <= {dat[7:0],24'h000000}; end
		endcase
		adr_o <= wadr;
	end
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
input [15:0] dat16;
input [31:0] dat32;
begin
	case(load_what)
	`LW_B3124:
			if (radr[1:0]==2'b00) begin
				b <= dat32;
				next_state(CALC);
			end
			else begin
				radr <= radr + 32'd1;
				b[31:24] <= dat;
				load_what <= `LW_B2316;
				next_state(LOAD1);
			end
	`LW_B2316:
			begin
				radr <= radr + 32'd1;
				b[23:16] <= dat;
				load_what <= `LW_BH;
				next_state(LOAD1);
			end
	`LW_BH:
			if (radr[0]==1'b0) begin
				b[15:0] <= dat16;
				next_state(CALC);
			end
			else begin
				radr <= radr + 32'd1;
				b[15:8] <= dat;
				load_what <= `LW_BL;
				next_state(LOAD1);
			end
	`LW_BL:
			begin
				// Don't increment address here for the benefit of the memory
				// operate instructions which set wadr=radr in CALC.
				b[7:0] <= dat;
				next_state(CALC);
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
					$display("loaded ccr=%b", dat);
					ir[15:8] <= dat[7] ? 8'hFE : 8'h80;
					ssp <= ssp + 32'd1;
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
					$display("loaded acca=%h from %h", dat, radr);
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
					$display("loaded accb=%h from ", dat, radr);
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
					$display("loaded dpr=%h from %h", dat, radr);
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
	`LW_X3124:	begin
				load_what <= `LW_X2316;
				next_state(LOAD1);
				xr[31:24] <= dat;
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
	`LW_X2316:	begin
				load_what <= `LW_XH;
				next_state(LOAD1);
				xr[23:16] <= dat;
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
	`LW_XH:	begin
				load_what <= `LW_XL;
				next_state(LOAD1);
				xr[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					$display("loaded XH=%h from %h", dat, radr);
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
					$display("loaded XL=%h from %h", dat, radr);
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
	`LW_Y3124:	begin
				load_what <= `LW_Y2316;
				next_state(LOAD1);
				yr[31:24] <= dat;
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
	`LW_Y2316:	begin
				load_what <= `LW_YH;
				next_state(LOAD1);
				yr[23:16] <= dat;
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
	`LW_YH:	begin
				load_what <= `LW_YL;
				next_state(LOAD1);
				yr[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					$display("loadded YH=%h", dat);
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
					$display("loadded YL=%h", dat);
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
	`LW_USP3124:	begin
				load_what <= `LW_USP2316;
				next_state(LOAD1);
				usp[31:24] <= dat;
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
	`LW_USP2316:	begin
				load_what <= `LW_USPH;
				next_state(LOAD1);
				usp[23:16] <= dat;
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
	`LW_USPH:	begin
				load_what <= `LW_USPL;
				next_state(LOAD1);
				usp[15:8] <= dat;
				radr <= radr + 32'd1;
				if (isRTI) begin
					$display("loadded USPH=%h", dat);
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
					$display("loadded USPL=%h", dat);
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
	`LW_SSP3124:	begin
				load_what <= `LW_SSP2316;
				next_state(LOAD1);
				ssp[31:24] <= dat;
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
	`LW_SSP2316:	begin
				load_what <= `LW_SSPH;
				next_state(LOAD1);
				ssp[23:16] <= dat;
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
				radr <= radr + 32'd1;
				if (isRTI|isRTS|isRTF|isPULS) begin
					$display("loadded PCL=%h", dat);
					ssp <= ssp + 32'd1;
				end
				else if (isPULU)
					usp <= usp + 32'd1;
				next_state(IFETCH);
			end
	`LW_PCH:	begin
				pc[15:8] <= dat;
				load_what <= `LW_PCL;
				radr <= radr + 32'd1;
				if (isRTI|isRTS|isRTF|isPULS) begin
					$display("loadded PCH=%h", dat);
					ssp <= ssp + 32'd1;
				end
				else if (isPULU)
					usp <= usp + 32'd1;
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
				res32[7:0] <= dat;
				radr <= {ia[31:8],dat};
				wadr <= {ia[31:8],dat};
				load_what <= load_what2;
				if (isOuterIndexed)
					next_state(OUTER_INDEXING);
				else begin
					if (isLEA)
						next_state(IFETCH);
					else if (isStore)
						next_state(STORE1);
					else
						next_state(LOAD1);
				end
			end
	`LW_IAH:
			begin
				ia[15:8] <= dat;
				res[15:8] <= dat;
				res32[15:8] <= dat;
				load_what <= `LW_IAL;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	`LW_IA2316:
			begin
				ia[23:16] <= dat;
				res32[23:16] <= dat;
				load_what <= `LW_IAH;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	`LW_IA3124:
			if (radr[1:0]==2'b00) begin
				ia <= dat32;
				res <= dat32[15:0];
				res32 <= dat32;
				radr <= dat32;
				wadr <= dat32;
				load_what <= load_what2;
				if (isOuterIndexed)
					next_state(OUTER_INDEXING);
				else begin
					if (isLEA)
						next_state(IFETCH);
					else if (isStore)
						next_state(STORE1);
					else
						next_state(LOAD1);
				end
			end
			else begin
				ia[31:24] <= dat;
				res32[31:24] <= dat;
				load_what <= `LW_IA2316;
				radr <= radr + 32'd1;
				next_state(LOAD1);
			end
	endcase
end
endtask

endmodule

// ============================================================================
// Cache Memories
// ============================================================================
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
	if (wce & wr & ~wa[2]) mem[wa[11:3]][31:0] <= i;
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
3'b010:	insn <= {insn1[15:0],insn0[63:16]};
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
