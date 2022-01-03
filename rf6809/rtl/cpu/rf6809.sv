// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf6809.sv
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================

import rf6809_pkg::*;

module rf6809(rst_i, clk_i, halt_i, nmi_i, irq_i, firq_i, vec_i, ba_o, bs_o, lic_o, tsc_i,
	rty_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, we_o, ack_i, adr_o, dat_i, dat_o, state);
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
parameter IBUF5 = 6'd39;
parameter IBUF6 = 6'd40;
input rst_i;
input clk_i;
input halt_i;
input nmi_i;
input irq_i;
input firq_i;
input [23:0] vec_i;
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
output reg [23:0] adr_o;
input [11:0] dat_i;
output reg [11:0] dat_o;
output [5:0] state;

reg [5:0] state;
reg [5:0] load_what,store_what,load_what2;
reg [23:0] pc;
wire [23:0] pcp2 = pc + 4'd2;
wire [23:0] pcp16 = pc + 5'd16;
wire [59:0] insn;
wire icacheOn = 1'b1;
reg [23:0] ibufadr;
reg [59:0] ibuf;
wire ibufhit = ibufadr==pc;
reg natMd,firqMd;
reg md32;
wire [23:0] mask = 24'hFFFFFF;
reg [1:0] ipg;
reg isOuterIndexed;
reg [59:0] ir;
wire [11:0] ir12 = ir[11:0];
reg [11:0] dpr;		// direct page register
wire [11:0] ndxbyte;
reg cf,vf,zf,nf,hf,ef;
wire [11:0] cfx8 = {11'b0,cf};
wire [23:0] cfx24 = {23'b0,cf};
reg im,firqim;
reg sync_state,wait_state;
wire [11:0] ccr = {ef,firqim,hf,im,nf,zf,vf,cf};
reg [11:0] acca,accb;
reg [23:0] accd;
reg [23:0] xr,yr,usp,ssp;
wire [23:0] prod = acca * accb;
reg [23:0] vect;
reg [24:0] res;
reg [12:0] res12;
wire res12n = res12[11];
wire res12z = res12[11:0]==12'h000;
wire res12c = res12[12];
wire res24n = res[23];
wire res24z = res[23:0]==24'h000000;
wire res24c = res[24];
reg [23:0] ia;
reg ic_invalidate;
reg first_ifetch;
reg tsc_latched;
wire tsc = tsc_i|tsc_latched;

reg [23:0] a,b;
wire [11:0] b12 = b[11:0];
reg [23:0] radr,wadr;
reg [23:0] wdat;

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
always_comb
	dati = dat_i;

// Evaluate the branch conditional
reg takb;
always_comb
	case(ir12)
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
always_comb
begin
	cnt = 	(ir[12] ? 5'd1 : 5'd0) +
			(ir[13] ? 5'd1 : 5'd0) +
			(ir[14] ? 5'd1 : 5'd0) +
			(ir[15] ? 5'd1 : 5'd0) +
			(ir[16] ? 5'd2 : 5'd0) +
			(ir[17] ? 5'd2 : 5'd0) +
			(ir[18] ? 5'd2 : 5'd0) +
			(ir[19] ? 5'd2 : 5'd0)
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

wire isRMW1 = 	ir12==`NEG_DP || ir12==`COM_DP || ir12==`LSR_DP || ir12==`ROR_DP || ir12==`ASR_DP || ir12==`ASL_DP || ir12==`ROL_DP || ir12==`DEC_DP || ir12==`INC_DP ||
				ir12==`NEG_NDX || ir12==`COM_NDX || ir12==`LSR_NDX || ir12==`ROR_NDX || ir12==`ASR_NDX || ir12==`ASL_NDX || ir12==`ROL_NDX || ir12==`DEC_NDX || ir12==`INC_NDX ||
				ir12==`NEG_EXT || ir12==`COM_EXT || ir12==`LSR_EXT || ir12==`ROR_EXT || ir12==`ASR_EXT || ir12==`ASL_EXT || ir12==`ROL_EXT || ir12==`DEC_EXT || ir12==`INC_EXT
				;

wire isIndexed =
	ir12[7:4]==4'h6 || ir12[7:4]==4'hA || ir12[7:4]==4'hE ||
	ir12==`LEAX_NDX || ir12==`LEAY_NDX || ir12==`LEAS_NDX || ir12==`LEAU_NDX
	;
reg isDblIndirect;
wire isIndirect = ndxbyte[8] & ndxbyte[11];
assign ndxbyte = ir[23:12];

// Detect type of interrupt
wire isINT = ir12==`INT;
wire isRST = vect[3:0]==4'hE;
wire isNMI = vect[3:0]==4'hC;
wire isSWI = vect[3:0]==4'hA;
wire isIRQ = vect[3:0]==4'h8;
wire isFIRQ = vect[3:0]==4'h6;
wire isSWI2 = vect[3:0]==4'h4;
wire isSWI3 = vect[3:0]==4'h2;

wire [23:0] address = {ir[23:12],ir[35:24]};
wire [23:0] dp_address = {dpr,ir[23:12]};
wire [23:0] ex_address = address;
wire [23:0] offset12 = {{12{ir[35]}},ir[35:24]};
wire [23:0] offset24 = {ir[35:24],ir[47:36]};

// Choose the indexing register
reg [23:0] ndxreg;
always_comb
	case(ndxbyte[10:9])
	2'b00:	ndxreg <= xr;
	2'b01:	ndxreg <= yr;
	2'b10:	ndxreg <= usp;
	2'b11:	ndxreg <= ssp;
	endcase

reg [23:0] a,b;
wire [11:0] b12 = b[11:0];

reg [23:0] NdxAddr;
always_comb
	casex({isOuterIndexed,ndxbyte})
	13'b00xxxxxxxxxxx:	NdxAddr <= (ndxreg + {{15{ndxbyte[8]}},ndxbyte[8:0]}) & mask;
	13'b01xxx00000000:	NdxAddr <= ndxreg;
	13'b01xxx00000001:	NdxAddr <= ndxreg;
	13'b01xxx00000010:	NdxAddr <= (ndxreg - 2'd1) & mask;
	13'b01xxx00000011:	NdxAddr <= (ndxreg - 2'd2) & mask;
	13'b01xxx00000100:	NdxAddr <= ndxreg;
	13'b01xxx00000101:	NdxAddr <= (ndxreg + {{12{accb[11]}},accb}) & mask;
	13'b01xxx00000110:	NdxAddr <= (ndxreg + {{12{acca[11]}},acca}) & mask;
	13'b01xxx00001000:	NdxAddr <= (ndxreg + offset12) & mask;
	13'b01xxx00001001:	NdxAddr <= (ndxreg + offset24) & mask;
	13'b01xxx00001010:	NdxAddr <= (ndxreg & mask) + offset24;
	13'b01xxx00001011:	NdxAddr <= (ndxreg + {acca,accb}) & mask;
	13'b01xxx00001100:	NdxAddr <= pc + offset12 + 3'd3;
	13'b01xxx00001101:	NdxAddr <= pc + offset24 + 3'd4;
	13'b01xxx00001110:	NdxAddr <= pc + offset24 + 3'd4;
	13'b01xx000001111:	NdxAddr <= offset24 & 24'h0FFFFFF;
	13'b01xx000011111:	NdxAddr <= offset24 & 24'h0FFFFFF;
	13'b10xxxxxxxxxxx:	NdxAddr <= {{15{ndxbyte[8]}},ndxbyte[8:0]};
	13'b11xxx00000000:	NdxAddr <= 24'd0;
	13'b11xxx00000001:	NdxAddr <= 24'd0;
	13'b11xxx00000010:	NdxAddr <= 24'd0;
	13'b11xxx00000011:	NdxAddr <= 24'd0;
	13'b11xxx00000100:	NdxAddr <= 24'd0;
	13'b11xxx00000101:	NdxAddr <= {{12{accb[11]}},accb};
	13'b11xxx00000110:	NdxAddr <= {{12{acca[11]}},acca};
	13'b11xxx00001000:	NdxAddr <= offset12;
	13'b11xxx00001001:	NdxAddr <= offset24;
	13'b11xxx00001010:	NdxAddr <= offset24;
	13'b11xxx00001011:	NdxAddr <= {acca,accb};
	13'b11xxx00001100:	NdxAddr <= pc + offset12 + 3'd3;
	13'b11xxx00001101:	NdxAddr <= pc + offset24 + 3'd4;
	13'b11xxx00001110:	NdxAddr <= pc + offset24 + 3'd6;
	13'b11xx000001111:	NdxAddr <= offset24 & 24'h0FFFFFF;
	13'b11xx000011111:	NdxAddr <= offset24 & 24'h0FFFFFF;
	default:		NdxAddr <= 24'hFFFFFF;
	endcase

// Compute instruction length depending on indexing byte
reg [2:0] insnsz;
always_comb
	casex(ndxbyte)
	12'b0xxxxxxxxxxx:	insnsz <= 4'h2;
	12'b1xxx00000000:	insnsz <= 4'h2;
	12'b1xxx00000001:	insnsz <= 4'h2;
	12'b1xxx00000010:	insnsz <= 4'h2;
	12'b1xxx00000011:	insnsz <= 4'h2;
	12'b1xxx00000100:	insnsz <= 4'h2;
	12'b1xxx00000101:	insnsz <= 4'h2;
	12'b1xxx00000110:	insnsz <= 4'h2;
	12'b1xxx00001000:	insnsz <= 4'h3;
	12'b1xxx00001001:	insnsz <= 4'h4;
	12'b1xxx00001010:	insnsz <= 4'h6;
	12'b1xxx00001011:	insnsz <= 4'h2;
	12'b1xxx00001100:	insnsz <= 4'h3;
	12'b1xxx00001101:	insnsz <= 4'h4;
	12'b1xxx00001110:	insnsz <= 4'h6;
	12'b1xx000001111:	insnsz <= 4'h4;
	12'b1xx000011111:	insnsz <= 4'h4;
	default:	insnsz <= 4'h2;
	endcase

// Source registers for transfer or exchange instructions.
reg [31:0] src1,src2;
always_comb
	case(ir[15:12])
	4'b0000:	src1 <= {acca[11:0],accb[11:0]};
	4'b0001:	src1 <= xr;
	4'b0010:	src1 <= yr;
	4'b0011:	src1 <= usp;
	4'b0100:	src1 <= ssp;
	4'b0101:	src1 <= pcp2;
	4'b1000:	src1 <= acca[11:0];
	4'b1001:	src1 <= accb[11:0];
	4'b1010:	src1 <= ccr;
	4'b1011:	src1 <= dpr;
	4'b1100:	src1 <= 24'h0000;
	4'b1101:	src1 <= 24'h0000;
	4'b1110:	src1 <= 24'h0000;
	4'b1111:	src1 <= 24'h0000;
	default:	src1 <= 24'h0000;
	endcase
always_comb
	case(ir[11:8])
	4'b0000:	src2 <= {acca[11:0],accb[11:0]};
	4'b0001:	src2 <= xr;
	4'b0010:	src2 <= yr;
	4'b0011:	src2 <= usp;
	4'b0100:	src2 <= ssp;
	4'b0101:	src2 <= pcp2;
	4'b1000:	src2 <= acca[11:0];
	4'b1001:	src2 <= accb[11:0];
	4'b1010:	src2 <= ccr;
	4'b1011:	src2 <= dpr;
	4'b1100:	src2 <= 24'h0000;
	4'b1101:	src2 <= 24'h0000;
	4'b1110:	src2 <= 24'h0000;
	4'b1111:	src2 <= 24'h0000;
	default:	src2 <= 24'h0000;
	endcase

wire isAcca	= 	ir12==`NEGA || ir12==`COMA || ir12==`LSRA || ir12==`RORA || ir12==`ASRA || ir12==`ASLA ||
				ir12==`ROLA || ir12==`DECA || ir12==`INCA || ir12==`TSTA || ir12==`CLRA ||
				ir12==`SUBA_IMM || ir12==`CMPA_IMM || ir12==`SBCA_IMM || ir12==`ANDA_IMM || ir12==`BITA_IMM ||
				ir12==`LDA_IMM || ir12==`EORA_IMM || ir12==`ADCA_IMM || ir12==`ORA_IMM || ir12==`ADDA_IMM ||
				ir12==`SUBA_DP || ir12==`CMPA_DP || ir12==`SBCA_DP || ir12==`ANDA_DP || ir12==`BITA_DP ||
				ir12==`LDA_DP || ir12==`EORA_DP || ir12==`ADCA_DP || ir12==`ORA_DP || ir12==`ADDA_DP ||
				ir12==`SUBA_NDX || ir12==`CMPA_NDX || ir12==`SBCA_NDX || ir12==`ANDA_NDX || ir12==`BITA_NDX ||
				ir12==`LDA_NDX || ir12==`EORA_NDX || ir12==`ADCA_NDX || ir12==`ORA_NDX || ir12==`ADDA_NDX ||
				ir12==`SUBA_EXT || ir12==`CMPA_EXT || ir12==`SBCA_EXT || ir12==`ANDA_EXT || ir12==`BITA_EXT ||
				ir12==`LDA_EXT || ir12==`EORA_EXT || ir12==`ADCA_EXT || ir12==`ORA_EXT || ir12==`ADDA_EXT
				;

wire [23:0] acc = isAcca ? acca : accb;

wire [23:0] sum12 = src1 + src2;

always_ff @(posedge clk_i)
if (state==DECODE) begin
	isStore <= 	ir12==`STA_DP || ir12==`STB_DP || ir12==`STD_DP || ir12==`STX_DP || ir12==`STY_DP || ir12==`STU_DP || ir12==`STS_DP ||
				ir12==`STA_NDX || ir12==`STB_NDX || ir12==`STD_NDX || ir12==`STX_NDX || ir12==`STY_NDX || ir12==`STU_NDX || ir12==`STS_NDX ||
				ir12==`STA_EXT || ir12==`STB_EXT || ir12==`STD_EXT || ir12==`STX_EXT || ir12==`STY_EXT || ir12==`STU_EXT || ir12==`STS_EXT
				;
	isPULU <= ir12==`PULU;
	isPULS <= ir12==`PULS;
	isPSHS <= ir12==`PSHS;
	isPSHU <= ir12==`PSHU;
	isRTI <= ir12==`RTI;
	isRTS <= ir12==`RTS;
	isRTF <= ir12==`RTF;
	isLEA <= ir12==`LEAX_NDX || ir12==`LEAY_NDX || ir12==`LEAU_NDX || ir12==`LEAS_NDX;
	isRMW <= isRMW1;
end

wire hit0, hit1;
wire ihit = hit0 & hit1;
reg rhit0;

assign lic_o =	(state==CALC && !isRMW) ||
				(state==DECODE && (
					ir12==`NOP || ir12==`ORCC || ir12==`ANDCC || ir12==`DAA || ir12==`LDMD || ir12==`TFR || ir12==`EXG ||
					ir12==`NEGA || ir12==`COMA || ir12==`LSRA || ir12==`RORA || ir12==`ASRA || ir12==`ROLA || ir12==`DECA || ir12==`INCA || ir12==`TSTA || ir12==`CLRA ||
					ir12==`NEGB || ir12==`COMB || ir12==`LSRB || ir12==`RORB || ir12==`ASRB || ir12==`ROLB || ir12==`DECB || ir12==`INCB || ir12==`TSTB || ir12==`CLRB ||
					ir12==`ASLD || //ir12==`ADDR ||
					ir12==`SUBA_IMM || ir12==`CMPA_IMM || ir12==`SBCA_IMM || ir12==`ANDA_IMM || ir12==`BITA_IMM || ir12==`LDA_IMM || ir12==`EORA_IMM || ir12==`ADCA_IMM || ir12==`ORA_IMM || ir12==`ADDA_IMM ||
					ir12==`SUBB_IMM || ir12==`CMPB_IMM || ir12==`SBCB_IMM || ir12==`ANDB_IMM || ir12==`BITB_IMM || ir12==`LDB_IMM || ir12==`EORB_IMM || ir12==`ADCB_IMM || ir12==`ORB_IMM || ir12==`ADDB_IMM ||
					ir12==`ANDD_IMM || ir12==`ADDD_IMM || ir12==`ADCD_IMM || ir12==`SUBD_IMM || ir12==`SBCD_IMM || ir12==`LDD_IMM ||
					ir12==`LDQ_IMM || ir12==`CMPD_IMM || ir12==`CMPX_IMM || ir12==`CMPY_IMM || ir12==`CMPU_IMM || ir12==`CMPS_IMM ||
					ir12==`BEQ || ir12==`BNE || ir12==`BMI || ir12==`BPL || ir12==`BVS || ir12==`BVC || ir12==`BRA || ir12==`BRN ||
					ir12==`BHI || ir12==`BLS || ir12==`BHS || ir12==`BLO ||
					ir12==`BGT || ir12==`BGE || ir12==`BLT || ir12==`BLE ||
					ir12==`LBEQ || ir12==`LBNE || ir12==`LBMI || ir12==`LBPL || ir12==`LBVS || ir12==`LBVC || ir12==`LBRA || ir12==`LBRN ||
					ir12==`LBHI || ir12==`LBLS || ir12==`LBHS || ir12==`LBLO ||
					ir12==`LBGT || ir12==`LBGE || ir12==`LBLT || ir12==`LBLE
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
					(store_what==`SW_PCL && !(isINT || isPSHS || isPSHU) && !(ir12==`JSR_NDX && isIndirect)) ||
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

wire isPrefix = ir12==`PG2 || ir12==`PG3 || ir12==`OUTER;

rf6809_icachemem u1
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
	
rf6809_itagmem u2
(
	.wclk(clk_i),
	.wce(1'b1),
	.wr(ack_i && state==ICACHE2),
	.wa(adr_o[23:0]),
	.invalidate(ic_invalidate),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc),
	.hit0(hit0),
	.hit1(hit1)
);


always_ff @(posedge clk_i)
	tsc_latched <= tsc_i;

always_ff @(posedge clk_i)
	nmi1 <= nmi_i;
always_ff @(posedge clk_i)
	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
	else if (state==DECODE && ir12==`INT)
		nmi_edge <= 1'b0;

always @(posedge clk_i)
if (rst_i) begin
	wb_nack();
	next_state(RESET);
	sync_state <= `FALSE;
	wait_state <= `FALSE;
	md32 <= `FALSE;
	ipg <= 2'b00;
	isOuterIndexed <= `FALSE;
	dpr <= 12'h000;
	ibufadr <= 24'h000000;
	pc <= 24'hFFFFFE;
	ir <= {4{`NOP}};
	ibuf <= {4{`NOP}};
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
			isOuterIndexed <= `FALSE;
			ipg <= 2'b00;
			ia <= 24'd0;
			res <= 24'd0;
			load_what <= `LW_NOTHING;
			store_what <= `SW_NOTHING;
			if (nmi_edge | firq_i | irq_i)
				sync_state <= `FALSE;
			if (nmi_edge & nmi_armed) begin
				bs_o <= 1'b1;
				ir[11:0] <= `INT;
				ipg <= 2'b11;
				vect <= `NMI_VECT;
			end
			else if (firq_i & !firqim) begin
				bs_o <= 1'b1;
				ir[11:0] <= `INT;
				ipg <= 2'b11;
				vect <= `FIRQ_VECT;
			end
			else if (irq_i & !im) begin
				$display("**************************************");
				$display("****** Interrupt *********************");
				$display("**************************************");
				bs_o <= 1'b1;
				ir[11:0] <= `INT;
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
						isOuterIndexed <= isOuterIndexed;
						next_state(ICACHE1);
					end
				end
				else begin
					if (ibufhit)
						ir <= ibuf;
					else begin
						ipg <= ipg;
						isOuterIndexed <= isOuterIndexed;
						next_state(IBUF1);
					end
				end
			end
		end

		if (first_ifetch) begin
			first_ifetch <= `FALSE;
			case(ir12)
			`ABX:	xr <= res;
			`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
			`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT:
				begin
					cf <= (a[11]&b[11])|(a[11]&~res12[11])|(b[11]&~res12[11]);
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					vf <= (res12[11] ^ b[11]) & (1'b1 ^ a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT,
			`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				begin
					cf <= (a[11]&b[11])|(a[11]&~res12[11])|(b[11]&~res12[11]);
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					vf <= (res12[11] ^ b[11]) & (1'b1 ^ a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
				begin
					cf <= (a[23]&b[23])|(a[23]&~res[23])|(b[23]&~res[23]);
					vf <= (res[23] ^ b[23]) & (1'b1 ^ a[23] ^ b[23]);
					nf <= res[23];
					zf <= res[23:0]==24'h000000;
					acca <= res[23:12];
					accb <= res[11:0];
				end
			`ANDA_IMM,`ANDA_DP,`ANDA_NDX,`ANDA_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					acca <= res12[11:0];
				end
			`ANDB_IMM,`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					accb <= res12[11:0];
				end
			`ASLA:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`ASLB:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`ASL_DP,`ASL_NDX,`ASL_EXT:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`ASRA:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`ASRB:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`ASR_DP,`ASR_NDX,`ASR_EXT:
				begin
					cf <= res12c;
					hf <= (a[5]&b[5])|(a[5]&~res12[5])|(b[5]&~res12[5]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`BITA_IMM,`BITA_DP,`BITA_NDX,`BITA_EXT,
			`BITB_IMM,`BITB_DP,`BITB_NDX,`BITB_EXT:
				begin
					vf <= 1'b0;
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`CLRA:
				begin
					vf <= 1'b0;
					cf <= 1'b0;
					nf <= 1'b0;
					zf <= 1'b1;
					acca <= 12'h000;
				end
			`CLRB:
				begin
					vf <= 1'b0;
					cf <= 1'b0;
					nf <= 1'b0;
					zf <= 1'b1;
					accb <= 12'h000;
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
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`CMPD_IMM,`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
				begin
					cf <= (~a[23]&b[23])|(res[23]&~a[23])|(res[23]&b[23]);
					vf <= (1'b1 ^ res[23] ^ b[23]) & (a[23] ^ b[23]);
					nf <= res[23];
					zf <= res[23:0]==24'h000000;
				end
			`CMPS_IMM,`CMPS_DP,`CMPS_NDX,`CMPS_EXT,
			`CMPU_IMM,`CMPU_DP,`CMPU_NDX,`CMPU_EXT,
			`CMPX_IMM,`CMPX_DP,`CMPX_NDX,`CMPX_EXT,
			`CMPY_IMM,`CMPY_DP,`CMPY_NDX,`CMPY_EXT:
				begin
					cf <= (~a[23]&b[23])|(res[23]&~a[23])|(res[23]&b[23]);
					vf <= (1'b1 ^ res[23] ^ b[23]) & (a[23] ^ b[23]);
					nf <= res[23];
					zf <= res[23:0]==24'h000000;
				end
			`COMA:
				begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					acca <= res12[11:0];
				end
			`COMB:
				begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					accb <= res12[11:0];
				end
			`COM_DP,`COM_NDX,`COM_EXT:
				begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
				end
			`DAA:
				begin
					cf <= res12c;
					zf <= res12z;
					nf <= res12n;
					vf <= (res12[11] ^ b[11]) & (1'b1 ^ a[11] ^ b[11]);
					acca <= res12[11:0];
				end
			`DECA:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != acca[11];
					acca <= res12[11:0];
				end
			`DECB:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != accb[11];
					accb <= res12[11:0];
				end
			`DEC_DP,`DEC_NDX,`DEC_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != b[11];
				end
			`EORA_IMM,`EORA_DP,`EORA_NDX,`EORA_EXT,
			`ORA_IMM,`ORA_DP,`ORA_NDX,`ORA_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					acca <= res12[11:0];
				end
			`EORB_IMM,`EORB_DP,`EORB_NDX,`EORB_EXT,
			`ORB_IMM,`ORB_DP,`ORB_NDX,`ORB_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					accb <= res12[11:0];
				end
			`EXG:
				begin
					case(ir[11:8])
					4'b0000:
								begin
									acca <= src1[23:12];
									accb <= src1[11:0];
								end
					4'b0001:	xr <= src1;
					4'b0010:	yr <= src1;
					4'b0011:	usp <= src1;
					4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src1[23:0];
					4'b1000:	acca <= src1[11:0];
					4'b1001:	accb <= src1[11:0];
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
					4'b1011:	dpr <= src1[11:0];
					4'b1110:	;
					4'b1111:	;
					default:	;
					endcase
					case(ir[15:12])
					4'b0000:
								begin
									acca <= src2[23:12];
									accb <= src2[11:0];
								end
					4'b0001:	xr <= src2;
					4'b0010:	yr <= src2;
					4'b0011:	usp <= src2;
					4'b0100:	begin ssp <= src2; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src2[23:0];
					4'b1000:	acca <= src2[11:0];
					4'b1001:	accb <= src2[11:0];
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
					4'b1011:	dpr <= src2[11:0];
					4'b1110:	;
					4'b1111:	;
					default:	;
					endcase
				end
			`INCA:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != acca[11];
					acca <= res12[11:0];
				end
			`INCB:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != accb[11];
					accb <= res12[11:0];
				end
			`INC_DP,`INC_NDX,`INC_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[11] != b[11];
				end
			`LDA_IMM,`LDA_DP,`LDA_NDX,`LDA_EXT:
				begin
					vf <= 1'b0;
					zf <= res12z;
					nf <= res12n;
					acca <= res12[11:0];
				end
			`LDB_IMM,`LDB_DP,`LDB_NDX,`LDB_EXT:
				begin
					vf <= 1'b0;
					zf <= res12z;
					nf <= res12n;
					accb <= res12[11:0];
				end
			`LDD_IMM,`LDD_DP,`LDD_NDX,`LDD_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					acca <= res[23:12];
					accb <= res[11:0];
				end
			`LDU_IMM,`LDU_DP,`LDU_NDX,`LDU_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					usp <= res[23:0];
				end
			`LDS_IMM,`LDS_DP,`LDS_NDX,`LDS_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					ssp <= res[23:0];
					nmi_armed <= 1'b1;
				end
			`LDX_IMM,`LDX_DP,`LDX_NDX,`LDX_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					xr <= res[23:0];
				end
			`LDY_IMM,`LDY_DP,`LDY_NDX,`LDY_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					yr <= res[23:0];
				end
			`LEAS_NDX:
				begin ssp <= res[23:0]; nmi_armed <= 1'b1; end
			`LEAU_NDX:
				usp <= res[23:0];
			`LEAX_NDX:
				begin
					zf <= res24z;
					xr <= res[23:0];
				end
			`LEAY_NDX:
				begin
					zf <= res24z;
					yr <= res[23:0];
				end
			`LSRA:
				begin
					cf <= res12c;
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`LSRB:
				begin
					cf <= res12c;
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`LSR_DP,`LSR_NDX,`LSR_EXT:
				begin
					cf <= res12c;
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`MUL:
				begin
					cf <= prod[11];
					zf <= res24z;
					acca <= prod[23:12];
					accb <= prod[11:0];
				end
			`NEGA:
				begin
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`NEGB:
				begin
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`NEG_DP,`NEG_NDX,`NEG_EXT:
				begin
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`ROLA:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`ROLB:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`ROL_DP,`ROL_NDX,`ROL_EXT:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end		
			`RORA:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`RORB:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`ROR_DP,`ROR_NDX,`ROR_EXT:
				begin
					cf <= res12c;
					vf <= res12[11] ^ res12[12];
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
				end
			`SBCA_IMM,`SBCA_DP,`SBCA_NDX,`SBCA_EXT:
				begin
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					acca <= res12[11:0];
				end
			`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
				begin
					cf <= (~a[11]&b[11])|(res12[11]&~a[11])|(res12[11]&b[11]);
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					nf <= res12[11];
					zf <= res12[11:0]==12'h000;
					accb <= res12[11:0];
				end
			`SEX:
				begin
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					acca <= res12[11:0];
				end
			`STA_DP,`STA_NDX,`STA_EXT,
			`STB_DP,`STB_NDX,`STB_EXT:	
				begin
					vf <= 1'b0;
					zf <= res12z;
					nf <= res12n;
				end
			`STD_DP,`STD_NDX,`STD_EXT,
			`STU_DP,`STU_NDX,`STU_EXT,
			`STX_DP,`STX_NDX,`STX_EXT,
			`STY_DP,`STY_NDX,`STY_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
				end
			`TFR:
				begin
					case(ir[11:8])
					4'b0000:
								begin
									acca <= src1[23:12];
									accb <= src1[11:0];
								end
					4'b0001:	xr <= src1;
					4'b0010:	yr <= src1;
					4'b0011:	usp <= src1;
					4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src1[23:0];
					4'b1000:	acca <= src1[11:0];
					4'b1001:	accb <= src1[11:0];
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
					4'b1011:	dpr <= src1[11:0];
					4'b1110:	;
					4'b1111:	;
					default:	;
					endcase
				end
			`TSTA,`TSTB:
				begin
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
				end
			`TST_DP,`TST_NDX,`TST_EXT:
				begin
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
				end
			`SUBA_IMM,`SUBA_DP,`SUBA_NDX,`SUBA_EXT:
				begin
					acca <= res12[11:0];
					nf <= res12n;
					zf <= res12z;
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					cf <= res12c;
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
				end
			`SUBB_IMM,`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
				begin
					accb <= res12[11:0];
					nf <= res12n;
					zf <= res12z;
					vf <= (1'b1 ^ res12[11] ^ b[11]) & (a[11] ^ b[11]);
					cf <= res12c;
					hf <= (~a[5]&b[5])|(res12[5]&~a[5])|(res12[5]&b[5]);
				end
			`SUBD_IMM,`SUBD_DP,`SUBD_NDX,`SUBD_EXT:
				begin
					cf <= res24c;
					vf <= (1'b1 ^ res[23] ^ b[23]) & (a[23] ^ b[23]);
					nf <= res[23];
					zf <= res[23:0]==24'h000000;
					acca <= res[23:12];
					accb <= res[11:0];
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
		pc <= pc + 24'd1;		// default: increment PC by one
		a <= 24'd0;
		b <= 24'd0;
		ia <= 24'd0;
		isDblIndirect <= `FALSE;//ndxbyte[11:4]==8'h8F;
		if (isIndexed) begin
			casex(ndxbyte)
			12'b1xx000000000:	
				if (!isOuterIndexed)
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr + 4'd1);
					2'b01:	yr <= (yr + 4'd1);
					2'b10:	usp <= (usp + 4'd1);
					2'b11:	ssp <= (ssp + 4'd1);
					endcase
			12'b1xx000000001:
				if (!isOuterIndexed)
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr + 4'd2);
					2'b01:	yr <= (yr + 4'd2);
					2'b10:	usp <= (usp + 4'd2);
					2'b11:	ssp <= (ssp + 4'd2);
					endcase
			12'b1xx000000010:
				case(ndxbyte[10:9])
				2'b00:	xr <= (xr - 2'd1);
				2'b01:	yr <= (yr - 2'd1);
				2'b10:	usp <= (usp - 2'd1);
				2'b11:	ssp <= (ssp - 2'd1);
				endcase
			12'b1xx000000011:
				case(ndxbyte[10:9])
				2'b00:	xr <= (xr - 2'd2);
				2'b01:	yr <= (yr - 2'd2);
				2'b10:	usp <= (usp - 2'd2);
				2'b11:	ssp <= (ssp - 2'd2);
				endcase
			endcase
		end
		case(ir12)
		`NOP:	;
		`SYNC:	sync_state <= `TRUE;
		`ORCC:	begin
				cf <= cf | ir[12];
				vf <= vf | ir[13];
				zf <= zf | ir[14];
				nf <= nf | ir[15];
				im <= im | ir[16];
				hf <= hf | ir[17];
				firqim <= firqim | ir[18];
				ef <= ef | ir[19];
				pc <= pcp2;
				end
		`ANDCC:
				begin
				cf <= cf & ir[12];
				vf <= vf & ir[13];
				zf <= zf & ir[14];
				nf <= nf & ir[15];
				im <= im & ir[16];
				hf <= hf & ir[17];
				firqim <= firqim & ir[18];
				ef <= ef & ir[19];
				pc <= pcp2;
				end
		`DAA:
				begin
					if (hf || acca[3:0] > 4'd9)
						res12[3:0] <= acca[3:0] + 4'd6;
					if (cf || acca[7:4] > 4'd9 || (acca[7:4] > 4'd8 && acca[3:0] > 4'd9))
						res12[8:4] <= acca[7:4] + 4'd6;
				end
		`CWAI:
				begin
				cf <= cf & ir[12];
				vf <= vf & ir[13];
				zf <= zf & ir[14];
				nf <= nf & ir[15];
				im <= im & ir[16];
				hf <= hf & ir[17];
				firqim <= firqim & ir[18];
				ef <= 1'b1;
				pc <= pc + 2'd2;
				ir[23:12] <= 12'hFFF;
				wait_state <= `TRUE;
				next_state(PUSH1);
				end
		`LDMD:	begin
				natMd <= ir[12];
				firqMd <= ir[13];
				pc <= pc + 2'd2;
				end
		`TFR:	pc <= pc + 2'd2;
		`EXG:	pc <= pc + 2'd2;
		`ABX:	res <= xr + accb;
		`SEX: res <= {{12{accb[11]}},accb[11:0]};
		`PG2:	begin ipg <= 2'b01; ir <= ir[59:12]; next_state(DECODE); end
		`PG3:	begin ipg <= 2'b10; ir <= ir[59:12]; next_state(DECODE); end
		`OUTER:	begin isOuterIndexed <= `TRUE;  ir <= ir[59:12]; next_state(DECODE); end

		`NEGA,`NEGB:	begin res12 <= -acc[11:0]; a <= 24'h00; b <= acc; end
		`COMA,`COMB:	begin res12 <= ~acc[11:0]; end
		`LSRA,`LSRB:	begin res12 <= {acc[0],1'b0,acc[11:1]}; end
		`RORA,`RORB:	begin res12 <= {acc[0],cf,acc[11:1]}; end
		`ASRA,`ASRB:	begin res12 <= {acc[0],acc[11],acc[11:1]}; end
		`ASLA,`ASLB:	begin res12 <= {acc[11:0],1'b0}; end
		`ROLA,`ROLB:	begin res12 <= {acc[11:0],cf}; end
		`DECA,`DECB:	begin res12 <= acc[11:0] - 2'd1; end
		`INCA,`INCB:	begin res12 <= acc[11:0] + 2'd1; end
		`TSTA,`TSTB:	begin res12 <= acc[11:0]; end
		`CLRA,`CLRB:	begin res12 <= 13'h000; end

		// Immediate mode instructions
		`SUBA_IMM,`SUBB_IMM,`CMPA_IMM,`CMPB_IMM:
			begin res12 <= acc[11:0] - ir[23:12]; pc <= pc + 4'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`SBCA_IMM,`SBCB_IMM:
			begin res12 <= acc[11:0] - ir[23:12] - {11'b0,cf}; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`ANDA_IMM,`ANDB_IMM,`BITA_IMM,`BITB_IMM:
			begin res12 <= acc[11:0] & ir[23:12]; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`LDA_IMM,`LDB_IMM:
			begin res12 <= ir[23:12]; pc <= pc + 2'd2; end
		`EORA_IMM,`EORB_IMM:
			begin res12 <= acc[11:0] ^ ir[23:12]; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`ADCA_IMM,`ADCB_IMM:
			begin res12 <= acc[11:0] + ir[23:12] + {11'b0,cf}; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`ORA_IMM,`ORB_IMM:
			begin res12 <= acc[11:0] | ir[23:12]; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`ADDA_IMM,`ADDB_IMM:
			begin res12 <= acc[11:0] + ir[23:12]; pc <= pc + 2'd2; a <= acc[11:0]; b <= ir[23:12]; end
		`ADDD_IMM:
					begin 
						res <= {acca[11:0],accb[11:0]} + {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
					end
		`SUBD_IMM:	
					begin 
						res <= {acca[11:0],accb[11:0]} - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
					end
		`LDD_IMM:	
					begin 
						res <= {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
					end
		`LDX_IMM,`LDY_IMM,`LDU_IMM,`LDS_IMM:
					begin
						res <= {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
					end

		`CMPD_IMM:	
					begin
						res <= {acca[11:0],accb[11:0]} - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
						a <= {acca[11:0],accb[11:0]};
						b <= {ir[23:12],ir[35:24]};
					end
		`CMPX_IMM:	
					begin
						res <= xr[23:0] - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
						a <= xr[23:0];
						b <= {ir[23:12],ir[35:24]};
					end
		`CMPY_IMM:	
					begin
						res <= yr[23:0] - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
						a <= yr[23:0];
						b <= {ir[23:12],ir[35:24]};
					end
		`CMPU_IMM:
					begin
						res <= usp[23:0] - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
						a <= usp[23:0];
						b <= {ir[23:12],ir[35:24]};
					end
		`CMPS_IMM:
					begin
						res <= ssp[23:0] - {ir[23:12],ir[35:24]};
						pc <= pc + 2'd3;
						a <= ssp[23:0];
						b <= {ir[23:12],ir[35:24]};
					end

		// Direct mode instructions
		`NEG_DP,`COM_DP,`LSR_DP,`ROR_DP,`ASR_DP,`ASL_DP,`ROL_DP,`DEC_DP,`INC_DP,`TST_DP:
			begin
				load_what <= `LW_BL;
				radr <= dp_address;
				pc <= pc + 2'd2;
				next_state(LOAD1);
			end
		`SUBA_DP,`CMPA_DP,`SBCA_DP,`ANDA_DP,`BITA_DP,`LDA_DP,`EORA_DP,`ADCA_DP,`ORA_DP,`ADDA_DP,
		`SUBB_DP,`CMPB_DP,`SBCB_DP,`ANDB_DP,`BITB_DP,`LDB_DP,`EORB_DP,`ADCB_DP,`ORB_DP,`ADDB_DP:
			begin
				load_what <= `LW_BL;
				radr <= dp_address;
				pc <= pc + 2'd2;
				next_state(LOAD1);
			end
		`SUBD_DP,`ADDD_DP,`LDD_DP,`CMPD_DP,`ADCD_DP,`SBCD_DP:
			begin
				load_what <= `LW_BH;
				pc <= pc + 2'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`CMPX_DP,`LDX_DP,`LDU_DP,`LDS_DP,
		`CMPY_DP,`CMPS_DP,`CMPU_DP,`LDY_DP:
			begin
				load_what <= `LW_BH;
				pc <= pc + 2'd2;
				radr <= dp_address;
				next_state(LOAD1);
			end
		`CLR_DP:
			begin
				dp_store(`SW_RES8);
				res12 <= 13'h000;
			end
		`STA_DP:	dp_store(`SW_ACCA);
		`STB_DP:	dp_store(`SW_ACCB);
		`STD_DP:	dp_store(`SW_ACCDH);
		`STU_DP:	dp_store(`SW_USPH);
		`STS_DP:	dp_store(`SW_SSPH);
		`STX_DP:	dp_store(`SW_XH);
		`STY_DP:	dp_store(`SW_YH);
		// Indexed mode instructions
		`NEG_NDX,`COM_NDX,`LSR_NDX,`ROR_NDX,`ASR_NDX,`ASL_NDX,`ROL_NDX,`DEC_NDX,`INC_NDX,`TST_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IAH;
					load_what2 <= `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					b <= 24'd0;
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
					load_what <= `LW_IAH;
					load_what2 <= `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
				else begin
					b <= 24'd0;
					load_what <= `LW_BL;
					radr <= NdxAddr;
					next_state(LOAD1);
				end
			end
		`SUBD_NDX,`ADDD_NDX,`LDD_NDX,`CMPD_NDX,`ADCD_NDX,`SBCD_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IAH;
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
		`CMPX_NDX,`LDX_NDX,`LDU_NDX,`LDS_NDX,
		`CMPY_NDX,`CMPS_NDX,`CMPU_NDX,`LDY_NDX:
			begin
				pc <= pc + insnsz;
				if (isIndirect) begin
					load_what <= `LW_IAH;
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
				res12 <= 13'h000;
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
		`NEG_EXT,`COM_EXT,`LSR_EXT,`ROR_EXT,`ASR_EXT,`ASL_EXT,`ROL_EXT,`DEC_EXT,`INC_EXT,`TST_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ex_address;
				pc <= pc + 2'd3;
				next_state(LOAD1);
			end
		`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
		`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ex_address;
				pc <= pc + 2'd3;
				next_state(LOAD1);
			end
		`SUBD_EXT,`ADDD_EXT,`LDD_EXT,`CMPD_EXT,`ADCD_EXT,`SBCD_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + 2'd3;
				next_state(LOAD1);
			end
		`CMPX_EXT,`LDX_EXT,`LDU_EXT,`LDS_EXT,
		`CMPY_EXT,`CMPS_EXT,`CMPU_EXT,`LDY_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + 2'd3;
				next_state(LOAD1);
			end
		`CLR_EXT:
			begin
				ex_store(`SW_RES8);
				res12 <= 13'h000;
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
				wadr <= ssp - 2'd2;
				ssp <= ssp - 2'd2;
				pc <= pc + 2'd2;
				next_state(STORE1);
			end
		`LBSR:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 2'd2;
				ssp <= ssp - 2'd2;
				pc <= pc + 2'd3;
				next_state(STORE1);
			end
		`JSR_DP:
			begin
				store_what <= `SW_PCH;
				wadr <= ssp - 2'd2;
				ssp <= ssp - 2'd2;
				pc <= pc + 2'd2;
				next_state(STORE1);
			end
		`JSR_NDX:
			begin
			   begin
            store_what <= `SW_PCH;
            wadr <= ssp - 2'd2;
            ssp <= ssp - 2'd2;
				end
				pc <= pc + insnsz;
				next_state(STORE1);
			end
		`JSR_EXT:
			begin
				begin
					store_what <= `SW_PCH;
					wadr <= ssp - 2'd2;
					ssp <= ssp - 2'd2;
				end
				pc <= pc + 2'd3;
				next_state(STORE1);
			end
		`RTS:
			begin
				load_what <= `LW_PCH;
				radr <= ssp;
				next_state(LOAD1);
			end
		`JMP_DP:	pc <= dp_address;
		`JMP_EXT:	pc <= address;
		`JMP_NDX:
			begin
				if (isIndirect) begin
			        radr <= NdxAddr;
					   load_what <= `LW_PCH;
					next_state(LOAD1);
				end
				else
					pc <= NdxAddr[23:0];
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
					res <= NdxAddr[23:0];
			end
		`PSHU,`PSHS:
			begin
				next_state(PUSH1);
				pc <= pc + 2'd2;
			end
		`PULS:
			begin
				radr <= ssp;
				next_state(PULL1);
				pc <= pc + 2'd2;
			end
		`PULU:
			begin
				radr <= usp;
				next_state(PULL1);
				pc <= pc + 2'd2;
			end
		`BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BHI,`BLS,`BHS,`BLO,`BGT,`BGE,`BLT,`BLE,`BRA,`BRN:
			if (takb)
				pc <= pc + {{12{ir[23]}},ir[23:12]} + 2'd2;
			else
				pc <= pc + 2'd2;
		// PC is already incremented by one due to the PG10 prefix.
		`LBEQ,`LBNE,`LBMI,`LBPL,`LBVS,`LBVC,`LBHI,`LBLS,`LBHS,`LBLO,`LBGT,`LBGE,`LBLT,`LBLE,`LBRN:
			if (takb)
				pc <= pc + {ir[23:12],ir[35:24]} + 2'd3;
			else
				pc <= pc + 2'd3;
		`LBRA:	pc <= pc + {ir[23:12],ir[35:24]} + 2'd3;
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
				ir[11:0] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI_VECT;
				next_state(DECODE);
			end
		`SWI2:
			begin
				ir[11:0] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI2_VECT;
				next_state(DECODE);
			end
		`SWI3:
			begin
				ir[11:0] <= `INT;
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
					if (vec_i != 24'h0) begin
					    pc <= vec_i;
					    next_state(IFETCH);
					end
					else begin
					    radr <= vect;
                        load_what <= `LW_PCH;
					    pc <= 24'hFFFFFE;
					    next_state(LOAD1);
					end
				end
				else begin
					if (isNMI | isIRQ | isSWI | isSWI2 | isSWI3) begin
						ir[23:12] <= 12'hFFF;
						ef <= 1'b1;
					end
					else if (isFIRQ) begin
						if (natMd) begin
							ef <= firqMd;
							ir[23:12] <= firqMd ? 12'hFFF : 12'h81;
						end
						else begin
							ir[23:12] <= 12'h81;
							ef <= 1'b0;
						end
					end
					pc <= pc;
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
		case(ir12)
		`SUBD_DP,`SUBD_NDX,`SUBD_EXT,
		`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
			begin
			    a <= {acca[11:0],accb[11:0]};
				res <= {acca[11:0],accb[11:0]} - b[23:0];
			end
		`SBCD_DP,`SBCD_NDX,`SBCD_EXT:
			begin
			    a <= {acca[11:0],accb[11:0]};
				res <= {acca[11:0],accb[11:0]} - b[23:0] - {23'b0,cf};
			end
		`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
			begin
			    a <= {acca[11:0],accb[11:0]};
				res <= {acca[11:0],accb[11:0]} + b[23:0];
			end
		`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
			begin
			    a <= {acca[11:0],accb[11:0]};
				res <= {acca[11:0],accb[11:0]} + b[23:0] + {23'b0,cf};
			end
		`LDD_DP,`LDD_NDX,`LDD_EXT:		
			res <= b[23:0];

		`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`SUBA_DP,`SUBA_NDX,`SUBA_EXT,
		`CMPB_DP,`CMPB_NDX,`CMPB_EXT,
		`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
		        begin
    		        a <= acc;
             res12 <= acc[11:0] - b12;
				end
		
		`SBCA_DP,`SBCA_NDX,`SBCA_EXT,
		`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
		        begin
		            a <= acc;
            res12 <= acc[11:0] - b12 - {11'b0,cf};
                end
		`BITA_DP,`BITA_NDX,`BITA_EXT,
		`ANDA_DP,`ANDA_NDX,`ANDA_EXT,
		`BITB_DP,`BITB_NDX,`BITB_EXT,
		`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
					res12 <= acc[11:0] & b12;
		`LDA_DP,`LDA_NDX,`LDA_EXT,
		`LDB_DP,`LDB_NDX,`LDB_EXT:
				res12 <= b12;
		`EORA_DP,`EORA_NDX,`EORA_EXT,
		`EORB_DP,`EORB_NDX,`EORB_EXT:
					res12 <= acc[11:0] ^ b12;
		`ADCA_DP,`ADCA_NDX,`ADCA_EXT,
		`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				begin
				    a <= acc;
					res12 <= acc[11:0] + b12 + {11'b0,cf};
				end
		`ORA_DP,`ORA_NDX,`ORA_EXT,
		`ORB_DP,`ORB_NDX,`ORB_EXT:
					res12 <= acc[11:0] | b12;
		`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
		`ADDB_DP,`ADDB_NDX,`ADDB_EXT:
		        begin
		            a <= acc;
                        res12 <= acc[11:0] + b12;
                end
		
		`LDU_DP,`LDS_DP,`LDX_DP,`LDY_DP,
		`LDU_NDX,`LDS_NDX,`LDX_NDX,`LDY_NDX,
		`LDU_EXT,`LDS_EXT,`LDX_EXT,`LDY_EXT:	res <= b[23:0];
		`CMPX_DP,`CMPX_NDX,`CMPX_EXT:	begin a <= xr; res <= xr[23:0] - b[23:0]; end
		`CMPY_DP,`CMPY_NDX,`CMPY_EXT:	begin a <= yr; res <= yr[23:0] - b[23:0]; end
		`CMPS_DP,`CMPS_NDX,`CMPS_EXT:	begin a <= ssp; res <= ssp[23:0] - b[23:0]; end
		`CMPU_DP,`CMPU_NDX,`CMPU_EXT:	begin a <= usp; res <= usp[23:0] - b[23:0]; end

		`NEG_DP,`NEG_NDX,`NEG_EXT:	begin res12 <= -b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`COM_DP,`COM_NDX,`COM_EXT:	begin res12 <= ~b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`LSR_DP,`LSR_NDX,`LSR_EXT:	begin res12 <= {b[0],1'b0,b[11:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ROR_DP,`ROR_NDX,`ROR_EXT:	begin res12 <= {b[0],cf,b[11:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASR_DP,`ASR_NDX,`ASR_EXT:	begin res12 <= {b[0],b[11],b[11:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASL_DP,`ASL_NDX,`ASL_EXT:	begin res12 <= {b12,1'b0}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`ROL_DP,`ROL_NDX,`ROL_EXT:	begin res12 <= {b12,cf}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`DEC_DP,`DEC_NDX,`DEC_EXT:	begin res12 <= b12 - 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`INC_DP,`INC_NDX,`INC_EXT:	begin res12 <= b12 + 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TST_DP,`TST_NDX,`TST_EXT:	res12 <= b12;
		
		`AIM_DP,`AIM_NDX,`AIM_EXT:	begin res12 <= ir[23:12] & b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`OIM_DP,`OIM_NDX,`OIM_EXT:	begin res12 <= ir[23:12] | b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`EIM_DP,`EIM_NDX,`OIM_EXT:  begin res12 <= ir[23:12] ^ b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TIM_DP,`TIM_NDX,`TIM_EXT:	begin res12 <= ir[23:12] & b12; end
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
		wb_read(radr);
		if (!tsc)
			next_state(LOAD2);
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
	// On a tri-state condition abort the bus cycle and retry the load.
	if (tsc|rty_i) begin
		wb_nack();
		next_state(LOAD1);
	end
	else if (ack_i) begin
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
		lock_o <= lock_bus;
		case(store_what)
		`SW_ACCDH:	wb_write(wadr,acca[11:0]);
		`SW_ACCDL:	wb_write(wadr,accb[11:0]);
		`SW_ACCA:	wb_write(wadr,acca[11:0]);
		`SW_ACCB:	wb_write(wadr,accb[11:0]);
		`SW_DPR:	wb_write(wadr,dpr);
		`SW_XL:	wb_write(wadr,xr[11:0]);
		`SW_XH:	wb_write(wadr,xr[23:12]);
		`SW_YL:	wb_write(wadr,yr[11:0]);
		`SW_YH:	wb_write(wadr,yr[23:12]);
		`SW_USPL:	wb_write(wadr,usp[11:0]);
		`SW_USPH:	wb_write(wadr,usp[23:12]);
		`SW_SSPL:	wb_write(wadr,ssp[11:0]);
		`SW_SSPH:	wb_write(wadr,ssp[23:12]);
		`SW_PCH:	wb_write(wadr,pc[23:12]);
		`SW_PCL:	wb_write(wadr,pc[11:0]);
		`SW_CCR:	wb_write(wadr,ccr);
		`SW_RES8:	wb_write(wadr,res12[11:0]);
		`SW_RES16H:	wb_write(wadr,res[23:12]);
		`SW_RES16L:	wb_write(wadr,res[11:0]);
		`SW_DEF8:	wb_write(wadr,wdat);
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
				case(ir12)
				`BSR:		pc <= pc + {{12{ir[23]}},ir[23:12]};
				`LBSR:	pc <= pc + {ir[23:12],ir[35:24]};
				`JSR_DP:	pc <= {dpr,ir[23:12]};
				`JSR_EXT:	pc <= address;
				`JSR_NDX:
					begin
						if (isIndirect) begin
							radr <= NdxAddr;
							load_what <= `LW_PCH;
							next_state(LOAD1);
						end
						else
							pc <= NdxAddr[23:0];
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
			wadr <= (ssp - cnt);
			ssp <= (ssp - cnt);
		end
		else begin	// PSHU
			wadr <= (usp - cnt);
			usp <= (usp - cnt);
		end
	end
PUSH2:
	begin
		next_state(STORE1);
		if (ir[12]) begin
			store_what <= `SW_CCR;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			store_what <= `SW_ACCA;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			store_what <= `SW_ACCB;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			store_what <= `SW_DPR;
			ir[15] <= 1'b0;
		end
		else if (ir[16]) begin
			store_what <= `SW_XH;
			ir[16] <= 1'b0;
		end
		else if (ir[17]) begin
			store_what <= `SW_YH;
			ir[17] <= 1'b0;
		end
		else if (ir[18]) begin
			if (isINT | isPSHS)
				store_what <= `SW_USPH;
			else
				store_what <= `SW_SSPH;
			ir[18] <= 1'b0;
		end
		else if (ir[19]) begin
			store_what <= `SW_PCH;
			ir[19] <= 1'b0;
		end
		else begin
			if (isINT) begin
				radr <= vect;
				if (vec_i != 24'h0) begin
					$display("vector: %h", vec_i);
					pc <= vec_i;
					next_state(IFETCH);
				end
				else begin
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
		if (ir[12]) begin
			load_what <= `LW_CCR;
			ir[12] <= 1'b0;
		end
		else if (ir[13]) begin
			load_what <= `LW_ACCA;
			ir[13] <= 1'b0;
		end
		else if (ir[14]) begin
			load_what <= `LW_ACCB;
			ir[14] <= 1'b0;
		end
		else if (ir[15]) begin
			load_what <= `LW_DPR;
			ir[15] <= 1'b0;
		end
		else if (ir[16]) begin
			load_what <= `LW_XH;
			ir[16] <= 1'b0;
		end
		else if (ir[17]) begin
			load_what <= `LW_YH;
			ir[17] <= 1'b0;
		end
		else if (ir[18]) begin
			if (ir12==`PULU)
				load_what <= `LW_SSPH;
			else
				load_what <= `LW_USPH;
			ir[18] <= 1'b0;
		end
		else if (ir[19]) begin
			load_what <= `LW_PCH;
			ir[19] <= 1'b0;
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
		12'b0xxxxxxxxxxx:	radr <= radr + ndxreg;
		12'b1xxx00000000:
						begin
							radr <= radr + ndxreg;
							case(ndxbyte[10:9])
							2'b00:	xr <= (xr + 2'd1);
							2'b01:	yr <= (yr + 2'd1);
							2'b10:	usp <= (usp + 2'd1);
							2'b11:	ssp <= (ssp + 2'd1);
							endcase
						end
		12'b1xxx00000001:	begin
							radr <= radr + ndxreg;
							case(ndxbyte[10:9])
							2'b00:	xr <= (xr + 2'd2);
							2'b01:	yr <= (yr + 2'd2);
							2'b10:	usp <= (usp + 2'd2);
							2'b11:	ssp <= (ssp + 2'd2);
							endcase
						end
		12'b1xxx00000010:	radr <= radr + ndxreg;
		12'b1xxx00000011:	radr <= radr + ndxreg;
		12'b1xxx00000100:	radr <= radr + ndxreg;
		12'b1xxx00000101:	radr <= radr + ndxreg;
		12'b1xxx00000110:	radr <= radr + ndxreg;
		12'b1xxx00001000:	radr <= radr + ndxreg;
		12'b1xxx00001001:	radr <= radr + ndxreg;
		12'b1xxx00001010:	radr <= radr + ndxreg;
		12'b1xxx00001011:	radr <= radr + ndxreg;
		default:	radr <= radr;
		endcase
		next_state(OUTER_INDEXING2);
	end
OUTER_INDEXING2:
	begin
		wadr <= radr;
		res <= radr[23:0];
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
			bl_o <= 6'd15;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			adr_o <= !hit0 ? {pc[23:4],4'b00} : {pcp16[23:4],4'b0000};
			dat_o <= 12'd0;
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
		adr_o[3:0] <= adr_o[3:0] + 2'd1;
		if (adr_o[3:0]==4'b1110)
			cti_o <= 3'b111;
		if (adr_o[3:0]==4'b1111) begin
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
		bl_o <= 6'd15;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		adr_o <= !rhit0 ? {pc[23:4],4'b00} : {pcp16[23:4],4'b0000};
		dat_o <= 12'd0;
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
		adr_o <= pc[23:0];
		dat_o <= 12'd0;
		next_state(IBUF2);
	end
IBUF2:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		adr_o <= adr_o + 2'd1;
		ibuf <= dat_i;
		next_state(IBUF3);
	end
IBUF3:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		cti_o <= 3'b111;
		adr_o <= adr_o + 2'd1;
		ibuf[23:12] <= dat_i;
		next_state(IBUF4);
	end
IBUF4:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[35:24] <= dat_i;
		next_state(IBUF5);
	end
IBUF5:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[47:36] <= dat_i;
		next_state(IBUF6);
	end
IBUF6:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[59:48] <= dat_i;
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
	pc <= pc + 2'd2;
	next_state(STORE1);
end
endtask

task indexed_store;
input [5:0] stw;
begin
	store_what <= stw;
	pc <= pc + insnsz;
	if (isIndirect) begin
		load_what <= `LW_IAH;
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
	pc <= pc + 2'd3;
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
		adr_o <= adr;
	end
end
endtask

task wb_read;
input [23:0] adr;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		adr_o <= adr;
	end
end
endtask

task wb_write;
input [23:0] adr;
input [11:0] dat;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		we_o <= 1'b1;
		adr_o <= adr;
		dat_o <= dat;
	end
end
endtask	

task wb_nack;
begin
	cti_o <= 3'b000;
	bl_o <= 6'd0;
	cyc_o <= 1'b0;
	stb_o <= 1'b0;
	we_o <= 1'b0;
	adr_o <= 24'd0;
	dat_o <= 12'd0;
end
endtask

task load_tsk;
input [11:0] dat;
begin
	case(load_what)
	`LW_BH:
			begin
				radr <= radr + 2'd1;
				b[23:12] <= dat;
				load_what <= `LW_BL;
				next_state(LOAD1);
			end
	`LW_BL:
			begin
				// Don't increment address here for the benefit of the memory
				// operate instructions which set wadr=radr in CALC.
				b[11:0] <= dat;
				next_state(CALC);
			end
	`LW_CCR:	begin
				next_state(PULL1);
				radr <= radr + 2'd1;
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
					ir[23:12] <= dat[7] ? 12'hFE : 12'h80;
					ssp <= ssp + 2'd1;
				end
				else if (isPULS)
					ssp <= ssp + 2'd1;
				else if (isPULU)
					usp <= usp + 2'd1;
			end
	`LW_ACCA:	begin
				acca <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loaded acca=%h from %h", dat, radr);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_ACCB:	begin
				accb <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loaded accb=%h from ", dat, radr);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_DPR:	begin
				dpr <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loaded dpr=%h from %h", dat, radr);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_XH:	begin
				load_what <= `LW_XL;
				next_state(LOAD1);
				xr[23:12] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loaded XH=%h from %h", dat, radr);
					ssp <= ssp + 2'd1;
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
				end
			end
	`LW_XL:	begin
				xr[11:0] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loaded XL=%h from %h", dat, radr);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_YH:
			begin
				load_what <= `LW_YL;
				next_state(LOAD1);
				yr[23:12] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loadded YH=%h", dat);
					ssp <= ssp + 2'd1;
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
				end
			end
	`LW_YL:	begin
				yr[11:0] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loadded YL=%h", dat);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_USPH:	begin
				load_what <= `LW_USPL;
				next_state(LOAD1);
				usp[23:12] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loadded USPH=%h", dat);
					ssp <= ssp + 2'd1;
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
				end
			end
	`LW_USPL:	begin
				usp[11:0] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					$display("loadded USPL=%h", dat);
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULS) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_SSPH:	begin
				load_what <= `LW_SSPL;
				next_state(LOAD1);
				ssp[23:12] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					ssp <= ssp + 2'd1;
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
				end
			end
	`LW_SSPL:	begin
				ssp[11:0] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					ssp <= ssp + 2'd1;
					next_state(PULL1);
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
					next_state(PULL1);
				end
				else
					next_state(IFETCH);
			end
	`LW_PCL:	begin
				pc[11:0] <= dat;
				radr <= radr + 2'd1;
				if (isRTI|isRTS|isPULS) begin
					$display("loadded PCL=%h", dat);
					ssp <= ssp + 2'd1;
				end
				else if (isPULU)
					usp <= usp + 2'd1;
				next_state(IFETCH);
			end
	`LW_PCH:	begin
				pc[23:12] <= dat;
				load_what <= `LW_PCL;
				radr <= radr + 2'd1;
				if (isRTI|isRTS|isPULS) begin
					$display("loadded PCH=%h", dat);
					ssp <= ssp + 2'd1;
				end
				else if (isPULU)
					usp <= usp + 2'd1;
				next_state(LOAD1);
			end
	`LW_IAL:
			begin
				ia[11:0] <= dat;
				res[11:0] <= dat;
				radr <= {ia[23:12],dat};
				wadr <= {ia[23:12],dat};
`ifdef SUPPORT_DBL_IND
				if (isDblIndirect) begin
          load_what <= `LW_IAH;
          next_state(LOAD1);
          isDblIndirect <= `FALSE;				
				end
				else
`endif
				begin
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
			end
	`LW_IAH:
			begin
				ia[23:12] <= dat;
				res[23:12] <= dat;
				load_what <= `LW_IAL;
				radr <= radr + 2'd1;
				next_state(LOAD1);
			end
	endcase
end
endtask

endmodule

// ============================================================================
// Cache Memories
// ============================================================================
module rf6809_icachemem(wclk, wce, wr, wa, i, rclk, rce, pc, insn);
input wclk;
input wce;
input wr;
input [11:0] wa;
input [11:0] i;
input rclk;
input rce;
input [11:0] pc;
output [47:0] insn;
reg [47:0] insn;

reg [191:0] mem [0:255];
reg [11:0] rpc,rpcp16;

genvar g;
generate begin : gMem
	for (g = 0; g < 16; g = g + 1)
		always_ff @(posedge wclk)
			if (wce & wr & wa[3:0]==g) mem[wa[11:4]][g*12+11:g*12] <= i;
end
endgenerate

always_ff @(posedge rclk)
	if (rce) rpc <= pc;
always_ff @(posedge rclk)
	if (rce) rpcp16 <= pc + 5'd16;
wire [191:0] insn0 = mem[rpc[11:4]];
wire [191:0] insn1 = mem[rpcp16[11:4]];
always_comb
	insn = {insn1,insn0} >> ({rpc[3:0],3'b0} + {rpc[3:0],2'b0});

endmodule

module rf6809_itagmem(wclk, wce, wr, wa, invalidate, rclk, rce, pc, hit0, hit1);
input wclk;
input wce;
input wr;
input [23:0] wa;
input invalidate;
input rclk;
input rce;
input [23:0] pc;
output hit0;
output hit1;

reg [23:12] mem [0:255];
reg [0:255] tvalid;
reg [23:0] rpc,rpcp16;
wire [12:0] tag0,tag1;

always_ff @(posedge wclk)
	if (wce & wr) mem[wa[11:4]] <= wa[23:12];
always_ff @(posedge wclk)
	if (invalidate) tvalid <= 256'd0;
	else if (wce & wr) tvalid[wa[11:4]] <= 1'b1;
always_ff @(posedge rclk)
	if (rce) rpc <= pc;
always_ff @(posedge rclk)
	if (rce) rpcp16 <= pc + 5'd16;
assign tag0 = {mem[rpc[11:4]],tvalid[rpc[11:4]]};
assign tag1 = {mem[rpcp16[11:4]],tvalid[rpcp16[11:4]]};

assign hit0 = tag0 == {rpc[23:12],1'b1};
assign hit1 = tag1 == {rpcp16[23:12],1'b1};

endmodule

