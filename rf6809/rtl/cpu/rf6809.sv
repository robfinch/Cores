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

module rf6809(id, rst_i, clk_i, halt_i, nmi_i, irq_i, firq_i, vec_i, ba_o, bs_o, lic_o, tsc_i,
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
parameter ICACHE1 = 6'd31;
parameter ICACHE2 = 6'd32;
parameter ICACHE3 = 6'd33;
parameter ICACHE4 = 6'd34;
parameter IBUF1 = 6'd35;
parameter IBUF2 = 6'd36;
parameter IBUF3 = 6'd37;
parameter IBUF4 = 6'd38;
parameter IBUF5 = 6'd39;
parameter IBUF6 = 6'd40;
input [5:0] id;
input rst_i;
input clk_i;
input halt_i;
input nmi_i;
input irq_i;
input firq_i;
input [`TRPBYTE] vec_i;
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
output reg [`TRPBYTE] adr_o;
input [`LOBYTE] dat_i;
output reg [`LOBYTE] dat_o;
output [5:0] state;

reg [5:0] state;
reg [5:0] load_what,store_what,load_what2;
reg [`TRPBYTE] pc;
wire [`TRPBYTE] pcp2 = pc + 4'd2;
wire [`TRPBYTE] pcp16 = pc + 5'd16;
wire [`HEXBYTE] insn;
wire icacheOn = 1'b1;
reg [`TRPBYTE] ibufadr;
reg [`HEXBYTE] ibuf;
wire ibufhit = ibufadr==pc;
reg natMd,firqMd;
reg md32;
wire [`DBLBYTE] mask = 24'hFFFFFF;
reg [1:0] ipg;
reg isFar;
reg isOuterIndexed;
reg [`HEXBYTE] ir;
`ifdef EIGHTBIT
wire [9:0] ir12 = {ipg,ir[`LOBYTE]};
`endif
`ifdef TWELVEBIT
wire [`LOBYTE] ir12 = ir[`LOBYTE];
`endif
reg [`LOBYTE] dpr;		// direct page register
reg [`DBLBYTE] usppg;	// user stack pointer page
wire [`LOBYTE] ndxbyte;
reg cf,vf,zf,nf,hf,ef;
wire [`LOBYTE] cfx8 = cf;
wire [`DBLBYTE] cfx24 = {23'b0,cf};
reg im,firqim;
reg sync_state,wait_state;
wire [`LOBYTE] ccr = {ef,firqim,hf,im,nf,zf,vf,cf};
reg [`LOBYTE] acca,accb;
reg [`DBLBYTE] accd;
reg [`DBLBYTE] xr,yr,usp,ssp;
wire [`DBLBYTE] prod = acca * accb;
reg [`DBLBYTE] vect;
reg [`DBLBYTEP1] res;
reg [`LOBYTEP1] res12;
wire res12n = res12[BPBM1];
wire res12z = res12[`LOBYTE]==12'h000;
wire res12c = res12[bitsPerByte];
wire res24n = res[BPBX2M1];
wire res24z = res[`DBLBYTE]==24'h000000;
wire res24c = res[BPB*2];
reg [`TRPBYTE] ia;
reg ic_invalidate;
reg first_ifetch;
reg tsc_latched;
wire tsc = tsc_i|tsc_latched;

reg [`DBLBYTE] a,b;
wire [`LOBYTE] b12 = b[`LOBYTE];
reg [`TRPBYTE] radr,wadr;
reg [`DBLBYTE] wdat;

reg nmi1,nmi_edge;
reg nmi_armed;

reg isStore;
reg isPULU,isPULS;
reg isPSHS,isPSHU;
reg isRTS,isRTI,isRTF;
reg isLEA;
reg isRMW;

// Data input path multiplexing
reg [BPB-1:0] dati;
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
	cnt = 	(ir[bitsPerByte] ? 5'd1 : 5'd0) +
			(ir[bitsPerByte+1] ? 5'd1 : 5'd0) +
			(ir[bitsPerByte+2] ? 5'd1 : 5'd0) +
			(ir[bitsPerByte+3] ? 5'd1 : 5'd0) +
			(ir[bitsPerByte+4] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+5] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+6] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+7] ? 5'd2 : 5'd0)
			;
//  cnt = 0;
//	if (ir[8]) cnt = cnt + 5'd1;	// CC
//	if (ir[9]) cnt = cnt + md32 ? 5'd4 : 5'd1;	// A
//	if (ir[10]) cnt = cnt + md32 ? 5'd4 : 5'd1;	// B
//	if (ir[BPBM1]) cnt = cnt + 5'd1;	// DP
//	if (ir[12]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// X
//	if (ir[bitsPerByte+1]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// Y
//	if (ir[bitsPerByte+2]) cnt = cnt + md32 ? 5'd4 : 5'd2;	// U/S
//	if (ir[bitsPerByte+3]) cnt = cnt + 5'd4;	// PC
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
wire isIndirect = ndxbyte[BPBM1-3] & ndxbyte[BPBM1];
assign ndxbyte = ir[`HIBYTE];

// Detect type of interrupt
wire isINT = ir12==`INT;
wire isRST = vect[3:0]==4'hE;
wire isNMI = vect[3:0]==4'hC;
wire isSWI = vect[3:0]==4'hA;
wire isIRQ = vect[3:0]==4'h8;
wire isFIRQ = vect[3:0]==4'h6;
wire isSWI2 = vect[3:0]==4'h4;
wire isSWI3 = vect[3:0]==4'h2;

wire [`TRPBYTE] far_address = {ir[`HIBYTE],ir[`BYTE3],ir[`BYTE4]};
wire [`TRPBYTE] address = {ir[`HIBYTE],ir[`BYTE3]};
wire [`TRPBYTE] dp_address = {dpr,ir[`HIBYTE]};
wire [`TRPBYTE] ex_address = isFar ? far_address : address;
wire [`TRPBYTE] offset12 = {{bitsPerByte{ir[bitsPerByte*3-1]}},ir[`BYTE3]};
wire [`TRPBYTE] offset24 = {ir[`BYTE3],ir[`BYTE4]};
wire [`TRPBYTE] offset36 = {ir[`BYTE3],ir[`BYTE4],ir[`BYTE5]};

// Choose the indexing register
reg [`TRPBYTE] ndxreg;
always_comb
	if (bitsPerByte==8)
		case(ndxbyte[6:5])
		2'b00:	ndxreg <= xr;
		2'b01:	ndxreg <= yr;
		2'b10:	ndxreg <= {usppg,8'h00} + usp;
		2'b11:	ndxreg <= ssp;
		endcase
	else if (bitsPerByte==12)
		case(ndxbyte[10:9])
		2'b00:	ndxreg <= xr;
		2'b01:	ndxreg <= yr;
		2'b10:	ndxreg <= {usppg,8'h00} + usp;
		2'b11:	ndxreg <= ssp;
		endcase
	
reg [`DBLBYTE] NdxAddr;
always_comb
	if (bitsPerByte==8)
		casex({isOuterIndexed,ndxbyte})
		9'b00xxxxxxx:	NdxAddr <= (ndxreg + {{11{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]});
		9'b01xxx0000:	NdxAddr <= ndxreg;
		9'b01xxx0001:	NdxAddr <= ndxreg;
		9'b01xxx0010:	NdxAddr <= (ndxreg - 2'd1);
		9'b01xxx0011:	NdxAddr <= (ndxreg - 2'd2);
		9'b01xxx0100:	NdxAddr <= ndxreg;
		9'b01xxx0101:	NdxAddr <= (ndxreg + {{BPB*2{accb[BPBM1]}},accb});
		9'b01xxx0110:	NdxAddr <= (ndxreg + {{BPB*2{acca[BPBM1]}},acca});
		9'b01xxx1000:	NdxAddr <= (ndxreg + offset12);
		9'b01xxx1001:	NdxAddr <= (ndxreg + offset24);
		9'b01xxx1010:	NdxAddr <=  ndxreg + offset24;
		9'b01xxx1011:	NdxAddr <= (ndxreg + {acca,accb});
		9'b01xxx1100:	NdxAddr <= pc + offset12 + 3'd3;
		9'b01xxx1101:	NdxAddr <= pc + offset24 + 3'd4;
		9'b01xxx1110:	NdxAddr <= pc + offset36 + 3'd5;
		9'b01xx01111:	NdxAddr <= isFar ? offset36 : offset24;
		9'b01xx11111:	NdxAddr <= offset24;
		9'b10xxxxxxx:	NdxAddr <= {{11{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		9'b11xxx0000:	NdxAddr <= 24'd0;
		9'b11xxx0001:	NdxAddr <= 24'd0;
		9'b11xxx0010:	NdxAddr <= 24'd0;
		9'b11xxx0011:	NdxAddr <= 24'd0;
		9'b11xxx0100:	NdxAddr <= 24'd0;
		9'b11xxx0101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		9'b11xxx0110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
		9'b11xxx1000:	NdxAddr <= offset12;
		9'b11xxx1001:	NdxAddr <= offset24;
		9'b11xxx1010:	NdxAddr <= offset36;
		9'b11xxx1011:	NdxAddr <= {acca,accb};
		9'b11xxx1100:	NdxAddr <= pc + offset12 + 3'd3;
		9'b11xxx1101:	NdxAddr <= pc + offset24 + 3'd4;
		9'b11xxx1110:	NdxAddr <= pc + offset24 + 3'd6;
		9'b11xx01111:	NdxAddr <= isFar ? offset36 : offset24;
		9'b11xx11111:	NdxAddr <= offset24;
		default:		NdxAddr <= 24'hFFFFFF;
		endcase
	else if (bitsPerByte==12)
		casex({isOuterIndexed,ndxbyte})
		13'b00xxxxxxxxxxx:	NdxAddr <= (ndxreg + {{15{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]});
		13'b01xxx00000000:	NdxAddr <= ndxreg;
		13'b01xxx00000001:	NdxAddr <= ndxreg;
		13'b01xxx00000010:	NdxAddr <= (ndxreg - 2'd1);
		13'b01xxx00010010:	NdxAddr <= (ndxreg - 2'd2);
		13'b01xxx00100010:	NdxAddr <= (ndxreg - 2'd3);
		13'b01xxx00000011:	NdxAddr <= (ndxreg - 2'd2);
		13'b01xxx00000100:	NdxAddr <= ndxreg;
		13'b01xxx00000101:	NdxAddr <= (ndxreg + {{BPB*2{accb[BPBM1]}},accb});
		13'b01xxx00000110:	NdxAddr <= (ndxreg + {{BPB*2{acca[BPBM1]}},acca});
		13'b01xxx00001000:	NdxAddr <= (ndxreg + offset12);
		13'b01xxx00001001:	NdxAddr <= (ndxreg + offset24);
		13'b01xxx00001010:	NdxAddr <=  ndxreg + offset24;
		13'b01xxx00001011:	NdxAddr <= (ndxreg + {acca,accb});
		13'b01xxx00001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b01xxx00001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b01xxx00001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b01xx000001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b01xx100001111:	NdxAddr <= offset24;
		13'b01xxx10000000:	NdxAddr <= 24'd0;
		13'b01xxx10000001:	NdxAddr <= 24'd0;
		13'b01xxx10000010:	NdxAddr <= 24'd0;
		13'b01xxx10000011:	NdxAddr <= 24'd0;
		13'b01xxx10000100:	NdxAddr <= 24'd0;
		13'b01xxx10000101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		13'b01xxx10000110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
		13'b01xxx10001000:	NdxAddr <= offset12;
		13'b01xxx10001001:	NdxAddr <= offset24;
		13'b01xxx10001010:	NdxAddr <= offset24;
		13'b01xxx10001011:	NdxAddr <= {acca,accb};
		13'b01xxx10001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b01xxx10001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b01xxx10001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b01xx010001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b01xx110001111:	NdxAddr <= offset24;
		13'b10xxxxxxxxxxx:	NdxAddr <= {{15{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		13'b11xxx00000000:	NdxAddr <= 24'd0;
		13'b11xxx00000001:	NdxAddr <= 24'd0;
		13'b11xxx00000010:	NdxAddr <= 24'd0;
		13'b11xxx00000011:	NdxAddr <= 24'd0;
		13'b11xxx00000100:	NdxAddr <= 24'd0;
		13'b11xxx00000101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		13'b11xxx00000110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
		13'b11xxx00001000:	NdxAddr <= offset12;
		13'b11xxx00001001:	NdxAddr <= offset24;
		13'b11xxx00001010:	NdxAddr <= offset24;
		13'b11xxx00001011:	NdxAddr <= {acca,accb};
		13'b11xxx00001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b11xxx00001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b11xxx00001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b11xx000001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b11xx000011111:	NdxAddr <= offset24;
		default:		NdxAddr <= 24'hFFFFFF;
		endcase
	
// Compute instruction length depending on indexing byte
reg [2:0] insnsz;
always_comb
	if (bitsPerByte==8)
		casex(ndxbyte)
		8'b0xxxxxxx:	insnsz <= 4'h2;
		8'b1xx00000:	insnsz <= 4'h2;
		8'b1xx00001:	insnsz <= 4'h2;
		8'b1xx00010:	insnsz <= 4'h2;
		8'b1xx00011:	insnsz <= 4'h2;
		8'b1xx00100:	insnsz <= 4'h2;
		8'b1xx00101:	insnsz <= 4'h2;
		8'b1xx00110:	insnsz <= 4'h2;
		8'b1xx01000:	insnsz <= 4'h3;
		8'b1xx01001:	insnsz <= 4'h4;
		8'b1xx01010:	insnsz <= 4'h5;
		8'b1xx01011:	insnsz <= 4'h2;
		8'b1xx01100:	insnsz <= 4'h3;
		8'b1xx01101:	insnsz <= 4'h4;
		8'b1xx01110:	insnsz <= 4'h5;
		8'b1xx01111:	insnsz <= isFar ? 4'h5 : 4'h4;
		8'b1xx11111:	insnsz <= 4'h4;
		default:	insnsz <= 4'h2;
		endcase
	else if (bitsPerByte==12)
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
		12'b1xxx00001010:	insnsz <= 4'h5;
		12'b1xxx00001011:	insnsz <= 4'h2;
		12'b1xxx00001100:	insnsz <= 4'h3;
		12'b1xxx00001101:	insnsz <= 4'h4;
		12'b1xxx00001110:	insnsz <= 4'h5;
		12'b1xx000001111:	insnsz <= isFar ? 4'h5 : 4'h4;
		12'b1xx000011111:	insnsz <= 4'h4;
		default:	insnsz <= 4'h2;
		endcase

// Source registers for transfer or exchange instructions.
reg [`DBLBYTE] src1,src2;
always_comb
	case(ir[15:12])
	4'b0000:	src1 <= {acca[`LOBYTE],accb[`LOBYTE]};
	4'b0001:	src1 <= xr;
	4'b0010:	src1 <= yr;
	4'b0011:	src1 <= usp;
	4'b0100:	src1 <= ssp;
	4'b0101:	src1 <= pcp2;
	4'b1000:	src1 <= acca[`LOBYTE];
	4'b1001:	src1 <= accb[`LOBYTE];
	4'b1010:	src1 <= ccr;
	4'b1011:	src1 <= dpr;
	4'b1100:	src1 <= usppg;
	4'b1101:	src1 <= 24'h0000;
	4'b1110:	src1 <= 24'h0000;
	4'b1111:	src1 <= 24'h0000;
	default:	src1 <= 24'h0000;
	endcase
always_comb
	case(ir[11:8])
	4'b0000:	src2 <= {acca[`LOBYTE],accb[`LOBYTE]};
	4'b0001:	src2 <= xr;
	4'b0010:	src2 <= yr;
	4'b0011:	src2 <= usp;
	4'b0100:	src2 <= ssp;
	4'b0101:	src2 <= pcp2;
	4'b1000:	src2 <= acca[`LOBYTE];
	4'b1001:	src2 <= accb[`LOBYTE];
	4'b1010:	src2 <= ccr;
	4'b1011:	src2 <= dpr;
	4'b1100:	src2 <= usppg;
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

wire [`DBLBYTE] acc = isAcca ? acca : accb;

wire [`DBLBYTE] sum12 = src1 + src2;

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
				(state==PUSH2 && ir[`HIBYTE]==12'h000 && !isINT) ||
				(state==PULL1 && ir[`HIBYTE]==12'h000) ||
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
	.wa(adr_o[`TRPBYTE]),
	.invalidate(ic_invalidate),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc),
	.hit0(hit0),
	.hit1(hit1)
);

reg [15:0] ns_count;
reg [31:0] ms_count;

always_ff @(posedge clk_i)
if (rst_i) begin
	ns_count <= 16'd0;
	ms_count <= 32'd0;
end
else begin
	if (ns_count==16'd40000)
		ms_count <= ms_count + 2'd1;
end

always_ff @(posedge clk_i)
	tsc_latched <= tsc_i;

always_ff @(posedge clk_i)
	nmi1 <= nmi_i;
always_ff @(posedge clk_i)
	if (nmi_i & !nmi1)
		nmi_edge <= 1'b1;
	else if (state==DECODE && ir12==`INT)
		nmi_edge <= 1'b0;

reg [9:0] rst_cnt;

always @(posedge clk_i)
if (rst_i) begin
	wb_nack();
	rst_cnt <= {id,4'd0};
	next_state(RESET);
	sync_state <= `FALSE;
	wait_state <= `FALSE;
	md32 <= `FALSE;
	ipg <= 2'b00;
	isFar <= `FALSE;
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
	acca <= 12'h0;
	accb <= 12'h0;
	accd <= 24'h0;
	xr <= 24'h0;
	yr <= 24'h0;
	usp <= 24'h0;
	ssp <= 24'h0;
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
	if (rst_cnt==10'd0) begin
		ic_invalidate <= `FALSE;
		ba_o <= 1'b0;
		bs_o <= 1'b0;
		vect <= `RST_VECT;
		radr <= `RST_VECT;
		load_what <= `LW_PCH;
		next_state(LOAD1);
	end
	else
		rst_cnt <= rst_cnt - 2'd1;

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
			isFar <= `FALSE;
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
				ir[`LOBYTE] <= `INT;
				ipg <= 2'b11;
				vect <= `NMI_VECT;
			end
			else if (firq_i & !firqim) begin
				bs_o <= 1'b1;
				ir[`LOBYTE] <= `INT;
				ipg <= 2'b11;
				vect <= `FIRQ_VECT;
			end
			else if (irq_i & !im) begin
				$display("**************************************");
				$display("****** Interrupt *********************");
				$display("**************************************");
				bs_o <= 1'b1;
				ir[`LOBYTE] <= `INT;
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
			case(ir12)
			`ABX:	xr <= res;
			`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
			`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT:
				begin
					cf <= (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT,
			`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				begin
					cf <= (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
				begin
					cf <= (a[BPBX2M1]&b[BPBX2M1])|(a[BPBX2M1]&~res[BPBX2M1])|(b[BPBX2M1]&~res[BPBX2M1]);
					vf <= (res[BPBX2M1] ^ b[BPBX2M1]) & (1'b1 ^ a[BPBX2M1] ^ b[BPBX2M1]);
					nf <= res[BPBX2M1];
					zf <= res[`DBLBYTE]==24'h000000;
					acca <= res[`HIBYTE];
					accb <= res[`LOBYTE];
				end
			`ANDA_IMM,`ANDA_DP,`ANDA_NDX,`ANDA_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					acca <= res12[`LOBYTE];
				end
			`ANDB_IMM,`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					accb <= res12[`LOBYTE];
				end
			`ASLA:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`ASLB:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`ASL_DP,`ASL_NDX,`ASL_EXT:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`ASRA:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`ASRB:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`ASR_DP,`ASR_NDX,`ASR_EXT:
				begin
					cf <= res12c;
					hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`BITA_IMM,`BITA_DP,`BITA_NDX,`BITA_EXT,
			`BITB_IMM,`BITB_DP,`BITB_NDX,`BITB_EXT:
				begin
					vf <= 1'b0;
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
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
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`CMPD_IMM,`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
				begin
					cf <= (~a[BPBX2M1]&b[BPBX2M1])|(res[BPBX2M1]&~a[BPBX2M1])|(res[BPBX2M1]&b[BPBX2M1]);
					vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
					nf <= res[BPBX2M1];
					zf <= res[`DBLBYTE]==24'h000000;
				end
			`CMPS_IMM,`CMPS_DP,`CMPS_NDX,`CMPS_EXT,
			`CMPU_IMM,`CMPU_DP,`CMPU_NDX,`CMPU_EXT,
			`CMPX_IMM,`CMPX_DP,`CMPX_NDX,`CMPX_EXT,
			`CMPY_IMM,`CMPY_DP,`CMPY_NDX,`CMPY_EXT:
				begin
					cf <= (~a[BPBX2M1]&b[BPBX2M1])|(res[BPBX2M1]&~a[BPBX2M1])|(res[BPBX2M1]&b[BPBX2M1]);
					vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
					nf <= res[BPBX2M1];
					zf <= res[`DBLBYTE]==24'h000000;
				end
			`COMA:
				begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					acca <= res12[`LOBYTE];
				end
			`COMB:
				begin
					cf <= 1'b1;
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					accb <= res12[`LOBYTE];
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
					vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
					acca <= res12[`LOBYTE];
				end
			`DECA:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != acca[BPBM1];
					acca <= res12[`LOBYTE];
				end
			`DECB:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != accb[BPBM1];
					accb <= res12[`LOBYTE];
				end
			`DEC_DP,`DEC_NDX,`DEC_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != b[BPBM1];
				end
			`EORA_IMM,`EORA_DP,`EORA_NDX,`EORA_EXT,
			`ORA_IMM,`ORA_DP,`ORA_NDX,`ORA_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					acca <= res12[`LOBYTE];
				end
			`EORB_IMM,`EORB_DP,`EORB_NDX,`EORB_EXT,
			`ORB_IMM,`ORB_DP,`ORB_NDX,`ORB_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= 1'b0;
					accb <= res12[`LOBYTE];
				end
			`EXG:
				begin
					case(ir[11:8])
					4'b0000:
								begin
									acca <= src1[`HIBYTE];
									accb <= src1[`LOBYTE];
								end
					4'b0001:	xr <= src1;
					4'b0010:	yr <= src1;
					4'b0011:	usp <= src1;
					4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src1[`DBLBYTE];
					4'b1000:	acca <= src1[`LOBYTE];
					4'b1001:	accb <= src1[`LOBYTE];
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
					4'b1011:	dpr <= src1[`LOBYTE];
					4'b1110:	usppg <= src1[`DBLBYTE];
					4'b1111:	;
					default:	;
					endcase
					case(ir[15:12])
					4'b0000:
								begin
									acca <= src2[`HIBYTE];
									accb <= src2[`LOBYTE];
								end
					4'b0001:	xr <= src2;
					4'b0010:	yr <= src2;
					4'b0011:	usp <= src2;
					4'b0100:	begin ssp <= src2; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src2[`DBLBYTE];
					4'b1000:	acca <= src2[`LOBYTE];
					4'b1001:	accb <= src2[`LOBYTE];
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
					4'b1011:	dpr <= src2[`LOBYTE];
					4'b1110:	usppg <= src2[`DBLBYTE];
					4'b1111:	;
					default:	;
					endcase
				end
			`INCA:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != acca[BPBM1];
					acca <= res12[`LOBYTE];
				end
			`INCB:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != accb[BPBM1];
					accb <= res12[`LOBYTE];
				end
			`INC_DP,`INC_NDX,`INC_EXT:
				begin
					nf <= res12n;
					zf <= res12z;
					vf <= res12[BPBM1] != b[BPBM1];
				end
			`LDA_IMM,`LDA_DP,`LDA_NDX,`LDA_EXT:
				begin
					vf <= 1'b0;
					zf <= res12z;
					nf <= res12n;
					acca <= res12[`LOBYTE];
				end
			`LDB_IMM,`LDB_DP,`LDB_NDX,`LDB_EXT:
				begin
					vf <= 1'b0;
					zf <= res12z;
					nf <= res12n;
					accb <= res12[`LOBYTE];
				end
			`LDD_IMM,`LDD_DP,`LDD_NDX,`LDD_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					acca <= res[`HIBYTE];
					accb <= res[`LOBYTE];
				end
			`LDU_IMM,`LDU_DP,`LDU_NDX,`LDU_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					usp <= res[`DBLBYTE];
				end
			`LDS_IMM,`LDS_DP,`LDS_NDX,`LDS_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					ssp <= res[`DBLBYTE];
					nmi_armed <= 1'b1;
				end
			`LDX_IMM,`LDX_DP,`LDX_NDX,`LDX_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					xr <= res[`DBLBYTE];
				end
			`LDY_IMM,`LDY_DP,`LDY_NDX,`LDY_EXT:
				begin
					vf <= 1'b0;
					zf <= res24z;
					nf <= res24n;
					yr <= res[`DBLBYTE];
				end
			`LEAS_NDX:
				begin ssp <= res[`DBLBYTE]; nmi_armed <= 1'b1; end
			`LEAU_NDX:
				usp <= res[`DBLBYTE];
			`LEAX_NDX:
				begin
					zf <= res24z;
					xr <= res[`DBLBYTE];
				end
			`LEAY_NDX:
				begin
					zf <= res24z;
					yr <= res[`DBLBYTE];
				end
			`LSRA:
				begin
					cf <= res12c;
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`LSRB:
				begin
					cf <= res12c;
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`LSR_DP,`LSR_NDX,`LSR_EXT:
				begin
					cf <= res12c;
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`MUL:
				begin
					cf <= prod[BPBM1];
					zf <= res24z;
					acca <= prod[`HIBYTE];
					accb <= prod[`LOBYTE];
				end
			`NEGA:
				begin
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`NEGB:
				begin
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`NEG_DP,`NEG_NDX,`NEG_EXT:
				begin
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`ROLA:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`ROLB:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`ROL_DP,`ROL_NDX,`ROL_EXT:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end		
			`RORA:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`RORB:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`ROR_DP,`ROR_NDX,`ROR_EXT:
				begin
					cf <= res12c;
					vf <= res12[BPBM1] ^ res12[bitsPerByte];
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
				end
			`SBCA_IMM,`SBCA_DP,`SBCA_NDX,`SBCA_EXT:
				begin
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					acca <= res12[`LOBYTE];
				end
			`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
				begin
					cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					nf <= res12[BPBM1];
					zf <= res12[`LOBYTE]==12'h000;
					accb <= res12[`LOBYTE];
				end
			`SEX:
				begin
					vf <= 1'b0;
					nf <= res12n;
					zf <= res12z;
					acca <= res12[`LOBYTE];
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
									acca <= src1[`HIBYTE];
									accb <= src1[`LOBYTE];
								end
					4'b0001:	xr <= src1;
					4'b0010:	yr <= src1;
					4'b0011:	usp <= src1;
					4'b0100:	begin ssp <= src1; nmi_armed <= `TRUE; end
					4'b0101:	pc <= src1[`DBLBYTE];
					4'b1000:	acca <= src1[`LOBYTE];
					4'b1001:	accb <= src1[`LOBYTE];
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
					4'b1011:	dpr <= src1[`LOBYTE];
					4'b1110:	usppg <= src1[`DBLBYTE];
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
					acca <= res12[`LOBYTE];
					nf <= res12n;
					zf <= res12z;
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					cf <= res12c;
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				end
			`SUBB_IMM,`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
				begin
					accb <= res12[`LOBYTE];
					nf <= res12n;
					zf <= res12z;
					vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
					cf <= res12c;
					hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				end
			`SUBD_IMM,`SUBD_DP,`SUBD_NDX,`SUBD_EXT:
				begin
					cf <= res24c;
					vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
					nf <= res[BPBX2M1];
					zf <= res[`DBLBYTE]==24'h000000;
					acca <= res[`HIBYTE];
					accb <= res[`LOBYTE];
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
		pc <= pc + 2'd1;		// default: increment PC by one
		a <= 24'd0;
		b <= 24'd0;
		ia <= 24'd0;
		isDblIndirect <= `FALSE;//ndxbyte[11:4]==8'h8F;
		if (isIndexed) begin
			if (bitsPerByte==8) begin
				casex(ndxbyte)
				8'b1xx00000:	
					if (!isOuterIndexed)
						case(ndxbyte[6:5])
						2'b00:	xr <= (xr + 4'd1);
						2'b01:	yr <= (yr + 4'd1);
						2'b10:	usp <= (usp + 4'd1);
						2'b11:	ssp <= (ssp + 4'd1);
						endcase
				8'b1xx00001:
					if (!isOuterIndexed)
						case(ndxbyte[6:5])
						2'b00:	xr <= (xr + 4'd2);
						2'b01:	yr <= (yr + 4'd2);
						2'b10:	usp <= (usp + 4'd2);
						2'b11:	ssp <= (ssp + 4'd2);
						endcase
				8'b1xx00010:
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr - 2'd1);
					2'b01:	yr <= (yr - 2'd1);
					2'b10:	usp <= (usp - 2'd1);
					2'b11:	ssp <= (ssp - 2'd1);
					endcase
				8'b1xx00011:
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr - 2'd2);
					2'b01:	yr <= (yr - 2'd2);
					2'b10:	usp <= (usp - 2'd2);
					2'b11:	ssp <= (ssp - 2'd2);
					endcase
				endcase
			end
			else if (bitsPerByte==12) begin
				casex(ndxbyte)
				12'b1xx000000000:	
					if (!isOuterIndexed && ndxbyte[7]==1'b0)
						case(ndxbyte[10:9])
						2'b00:	xr <= (xr + 4'd1);
						2'b01:	yr <= (yr + 4'd1);
						2'b10:	usp <= (usp + 4'd1);
						2'b11:	ssp <= (ssp + 4'd1);
						endcase
				12'b1xx000000001:
					if (!isOuterIndexed && ndxbyte[7]==1'b0)
						case(ndxbyte[10:9])
						2'b00:	xr <= (xr + 4'd2);
						2'b01:	yr <= (yr + 4'd2);
						2'b10:	usp <= (usp + 4'd2);
						2'b11:	ssp <= (ssp + 4'd2);
						endcase
				12'b1xx0x0000010:
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr - 2'd1);
					2'b01:	yr <= (yr - 2'd1);
					2'b10:	usp <= (usp - 2'd1);
					2'b11:	ssp <= (ssp - 2'd1);
					endcase
				12'b1xx0x0000011:
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr - 2'd2);
					2'b01:	yr <= (yr - 2'd2);
					2'b10:	usp <= (usp - 2'd2);
					2'b11:	ssp <= (ssp - 2'd2);
					endcase
				endcase
			end
		end
		case(ir12)
		`NOP:	;
		`SYNC:	sync_state <= `TRUE;
		`ORCC:	begin
				cf <= cf | ir[bitsPerByte];
				vf <= vf | ir[bitsPerByte+1];
				zf <= zf | ir[bitsPerByte+2];
				nf <= nf | ir[bitsPerByte+3];
				im <= im | ir[bitsPerByte+4];
				hf <= hf | ir[bitsPerByte+5];
				firqim <= firqim | ir[bitsPerByte+6];
				ef <= ef | ir[bitsPerByte+7];
				pc <= pcp2;
				end
		`ANDCC:
				begin
				cf <= cf & ir[bitsPerByte];
				vf <= vf & ir[bitsPerByte+1];
				zf <= zf & ir[bitsPerByte+2];
				nf <= nf & ir[bitsPerByte+3];
				im <= im & ir[bitsPerByte+4];
				hf <= hf & ir[bitsPerByte+5];
				firqim <= firqim & ir[bitsPerByte+6];
				ef <= ef & ir[bitsPerByte+7];
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
				cf <= cf & ir[bitsPerByte];
				vf <= vf & ir[bitsPerByte+1];
				zf <= zf & ir[bitsPerByte+2];
				nf <= nf & ir[bitsPerByte+3];
				im <= im & ir[bitsPerByte+4];
				hf <= hf & ir[bitsPerByte+5];
				firqim <= firqim & ir[bitsPerByte+6];
				ef <= 1'b1;
				pc <= pc + 2'd2;
				ir[`HIBYTE] <= -1;
				isFar <= `TRUE;
				wait_state <= `TRUE;
				next_state(PUSH1);
				end
		`LDMD:	begin
				natMd <= ir[bitsPerByte];
				firqMd <= ir[bitsPerByte+1];
				pc <= pc + 2'd2;
				end
		`TFR:	pc <= pc + 2'd2;
		`EXG:	pc <= pc + 2'd2;
		`ABX:	res <= xr + accb;
		`SEX: res <= {{bitsPerByte{accb[BPBM1]}},accb[`LOBYTE]};
		`PG2:	begin ipg <= 2'b01; ir <= ir[bitsPerByte*5-1:bitsPerByte]; next_state(DECODE); end
		`PG3:	begin ipg <= 2'b10; ir <= ir[bitsPerByte*5-1:bitsPerByte]; next_state(DECODE); end
		`FAR:	begin isFar <= `TRUE;  ir <= ir[bitsPerByte*5-1:bitsPerByte]; next_state(DECODE); end
		`OUTER:	begin isOuterIndexed <= `TRUE;  ir <= ir[bitsPerByte*5-1:bitsPerByte]; next_state(DECODE); end

		`NEGA,`NEGB:	begin res12 <= -acc[`LOBYTE]; a <= 24'h00; b <= acc; end
		`COMA,`COMB:	begin res12 <= ~acc[`LOBYTE]; end
		`LSRA,`LSRB:	begin res12 <= {acc[0],1'b0,acc[BPBM1:1]}; end
		`RORA,`RORB:	begin res12 <= {acc[0],cf,acc[BPBM1:1]}; end
		`ASRA,`ASRB:	begin res12 <= {acc[0],acc[BPBM1],acc[BPBM1:1]}; end
		`ASLA,`ASLB:	begin res12 <= {acc[`LOBYTE],1'b0}; end
		`ROLA,`ROLB:	begin res12 <= {acc[`LOBYTE],cf}; end
		`DECA,`DECB:	begin res12 <= acc[`LOBYTE] - 2'd1; end
		`INCA,`INCB:	begin res12 <= acc[`LOBYTE] + 2'd1; end
		`TSTA,`TSTB:	begin res12 <= acc[`LOBYTE]; end
		`CLRA,`CLRB:	begin res12 <= 13'h000; end

		// Immediate mode instructions
		`SUBA_IMM,`SUBB_IMM,`CMPA_IMM,`CMPB_IMM:
			begin res12 <= acc[`LOBYTE] - ir[`HIBYTE]; pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`SBCA_IMM,`SBCB_IMM:
			begin res12 <= acc[`LOBYTE] - ir[`HIBYTE] - cf; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`ANDA_IMM,`ANDB_IMM,`BITA_IMM,`BITB_IMM:
			begin res12 <= acc[`LOBYTE] & ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`LDA_IMM,`LDB_IMM:
			begin res12 <= ir[`HIBYTE]; pc <= pc + 2'd2; end
		`EORA_IMM,`EORB_IMM:
			begin res12 <= acc[`LOBYTE] ^ ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`ADCA_IMM,`ADCB_IMM:
			begin res12 <= acc[`LOBYTE] + ir[`HIBYTE] + cf; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`ORA_IMM,`ORB_IMM:
			begin res12 <= acc[`LOBYTE] | ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`ADDA_IMM,`ADDB_IMM:
			begin res12 <= acc[`LOBYTE] + ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
		`ADDD_IMM:
					begin 
						res <= {acca[`LOBYTE],accb[`LOBYTE]} + {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
					end
		`SUBD_IMM:	
					begin 
						res <= {acca[`LOBYTE],accb[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
					end
		`LDD_IMM:	
					begin 
						res <= {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
					end
		`LDX_IMM,`LDY_IMM,`LDU_IMM,`LDS_IMM:
					begin
						res <= {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
					end

		`CMPD_IMM:	
					begin
						res <= {acca[`LOBYTE],accb[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
						a <= {acca[`LOBYTE],accb[`LOBYTE]};
						b <= {ir[`HIBYTE],ir[`BYTE3]};
					end
		`CMPX_IMM:	
					begin
						res <= xr[`DBLBYTE] - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
						a <= xr[`DBLBYTE];
						b <= {ir[`HIBYTE],ir[`BYTE3]};
					end
		`CMPY_IMM:	
					begin
						res <= yr[`DBLBYTE] - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
						a <= yr[`DBLBYTE];
						b <= {ir[`HIBYTE],ir[`BYTE3]};
					end
		`CMPU_IMM:
					begin
						res <= usp[`DBLBYTE] - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
						a <= usp[`DBLBYTE];
						b <= {ir[`HIBYTE],ir[`BYTE3]};
					end
		`CMPS_IMM:
					begin
						res <= ssp[`DBLBYTE] - {ir[`HIBYTE],ir[`BYTE3]};
						pc <= pc + 2'd3;
						a <= ssp[`DBLBYTE];
						b <= {ir[`HIBYTE],ir[`BYTE3]};
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
					load_what <= isFar ? `LW_IA2316 : `LW_IAH;
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
					load_what <= isFar ? `LW_IA2316 : `LW_IAH;
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
					load_what <= isFar ? `LW_IA2316 : `LW_IAH;
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
					load_what <= isFar ? `LW_IA2316 : `LW_IAH;
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
				pc <= pc + (isFar ? 32'd4 : 32'd3);
				next_state(LOAD1);
			end
		`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
		`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
			begin
				load_what <= `LW_BL;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd4 : 32'd3);
				next_state(LOAD1);
			end
		`SUBD_EXT,`ADDD_EXT,`LDD_EXT,`CMPD_EXT,`ADCD_EXT,`SBCD_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd4 : 32'd3);
				next_state(LOAD1);
			end
		`CMPX_EXT,`LDX_EXT,`LDU_EXT,`LDS_EXT,
		`CMPY_EXT,`CMPS_EXT,`CMPU_EXT,`LDY_EXT:
			begin
				load_what <= `LW_BH;
				radr <= ex_address;
				pc <= pc + (isFar ? 32'd4 : 32'd3);
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
		`JSR_FAR:
			begin
				store_what <= `SW_PC2316;
				wadr <= ssp - 16'd4;
				ssp <= ssp - 16'd4;
				pc <= pc + 32'd4;
				next_state(STORE1);
			end
		`RTS:
			begin
				load_what <= `LW_PCH;
				radr <= ssp;
				next_state(LOAD1);
			end
		`RTF:
			begin
				load_what <= `LW_PC2316;
				radr <= ssp;
				next_state(LOAD1);
			end
		`JMP_DP:	pc <= dp_address;
		`JMP_EXT:	pc <= address;
		`JMP_FAR:	pc <= far_address;
		`JMP_NDX:
			begin
				if (isIndirect) begin
			        radr <= NdxAddr;
				    if (isFar)
					   load_what <= `LW_PC2316;
				    else
					   load_what <= `LW_PCH;
					next_state(LOAD1);
				end
				else
					pc <= isFar ? NdxAddr : {pc[`BYTE3],NdxAddr[`DBLBYTE]};
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
					res <= NdxAddr[`DBLBYTE];
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
				radr <= {usppg,8'h00} + usp;
				next_state(PULL1);
				pc <= pc + 2'd2;
			end
		`BEQ,`BNE,`BMI,`BPL,`BVS,`BVC,`BHI,`BLS,`BHS,`BLO,`BGT,`BGE,`BLT,`BLE,`BRA,`BRN:
			if (takb)
				pc <= pc + {{24{ir[BPBX2M1]}},ir[`HIBYTE]} + 2'd2;
			else
				pc <= pc + 2'd2;
		// PC is already incremented by one due to the PG10 prefix.
		`LBEQ,`LBNE,`LBMI,`LBPL,`LBVS,`LBVC,`LBHI,`LBLS,`LBHS,`LBLO,`LBGT,`LBGE,`LBLT,`LBLE,`LBRN:
			if (takb)
				pc <= pc + {{12{ir[BPB*3-1]}},ir[`HIBYTE],ir[`BYTE3]} + 2'd3;
			else
				pc <= pc + 2'd3;
		`LBRA:	pc <= pc + {{12{ir[BPB*3-1]}},ir[`HIBYTE],ir[`BYTE3]} + 2'd3;
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
				ir[`LOBYTE] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI_VECT;
				next_state(DECODE);
			end
		`SWI2:
			begin
				ir[`LOBYTE] <= `INT;
				ipg <= 2'b11;
				vect <= `SWI2_VECT;
				next_state(DECODE);
			end
		`SWI3:
			begin
				ir[`LOBYTE] <= `INT;
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
					    pc <= 32'hFFFFFFFE;
					    next_state(LOAD1);
					end
				end
				else begin
					if (isNMI | isIRQ | isSWI | isSWI2 | isSWI3) begin
						ir[`HIBYTE] <= 16'hFFFF;
						ef <= 1'b1;
					end
					else if (isFIRQ) begin
						if (natMd) begin
							ef <= firqMd;
							ir[`HIBYTE] <= firqMd ? 16'hFFFF : 12'h81;
						end
						else begin
							ir[`HIBYTE] <= 12'h81;
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
		case(ir12)
		`SUBD_DP,`SUBD_NDX,`SUBD_EXT,
		`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
			begin
			    a <= {acca[`LOBYTE],accb[`LOBYTE]};
				res <= {acca[`LOBYTE],accb[`LOBYTE]} - b[`DBLBYTE];
			end
		`SBCD_DP,`SBCD_NDX,`SBCD_EXT:
			begin
			    a <= {acca[`LOBYTE],accb[`LOBYTE]};
				res <= {acca[`LOBYTE],accb[`LOBYTE]} - b[`DBLBYTE] - {23'b0,cf};
			end
		`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
			begin
			    a <= {acca[`LOBYTE],accb[`LOBYTE]};
				res <= {acca[`LOBYTE],accb[`LOBYTE]} + b[`DBLBYTE];
			end
		`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
			begin
			    a <= {acca[`LOBYTE],accb[`LOBYTE]};
				res <= {acca[`LOBYTE],accb[`LOBYTE]} + b[`DBLBYTE] + {23'b0,cf};
			end
		`LDD_DP,`LDD_NDX,`LDD_EXT:		
			res <= b[`DBLBYTE];

		`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`SUBA_DP,`SUBA_NDX,`SUBA_EXT,
		`CMPB_DP,`CMPB_NDX,`CMPB_EXT,
		`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
		        begin
    		        a <= acc;
             res12 <= acc[`LOBYTE] - b12;
				end
		
		`SBCA_DP,`SBCA_NDX,`SBCA_EXT,
		`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
		        begin
		            a <= acc;
            res12 <= acc[`LOBYTE] - b12 - cf;
                end
		`BITA_DP,`BITA_NDX,`BITA_EXT,
		`ANDA_DP,`ANDA_NDX,`ANDA_EXT,
		`BITB_DP,`BITB_NDX,`BITB_EXT,
		`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
					res12 <= acc[`LOBYTE] & b12;
		`LDA_DP,`LDA_NDX,`LDA_EXT,
		`LDB_DP,`LDB_NDX,`LDB_EXT:
				res12 <= b12;
		`EORA_DP,`EORA_NDX,`EORA_EXT,
		`EORB_DP,`EORB_NDX,`EORB_EXT:
					res12 <= acc[`LOBYTE] ^ b12;
		`ADCA_DP,`ADCA_NDX,`ADCA_EXT,
		`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
				begin
				    a <= acc;
					res12 <= acc[`LOBYTE] + b12 + cf;
				end
		`ORA_DP,`ORA_NDX,`ORA_EXT,
		`ORB_DP,`ORB_NDX,`ORB_EXT:
					res12 <= acc[`LOBYTE] | b12;
		`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
		`ADDB_DP,`ADDB_NDX,`ADDB_EXT:
		        begin
		            a <= acc;
                        res12 <= acc[`LOBYTE] + b12;
                end
		
		`LDU_DP,`LDS_DP,`LDX_DP,`LDY_DP,
		`LDU_NDX,`LDS_NDX,`LDX_NDX,`LDY_NDX,
		`LDU_EXT,`LDS_EXT,`LDX_EXT,`LDY_EXT:	res <= b[`DBLBYTE];
		`CMPX_DP,`CMPX_NDX,`CMPX_EXT:	begin a <= xr; res <= xr[`DBLBYTE] - b[`DBLBYTE]; end
		`CMPY_DP,`CMPY_NDX,`CMPY_EXT:	begin a <= yr; res <= yr[`DBLBYTE] - b[`DBLBYTE]; end
		`CMPS_DP,`CMPS_NDX,`CMPS_EXT:	begin a <= ssp; res <= ssp[`DBLBYTE] - b[`DBLBYTE]; end
		`CMPU_DP,`CMPU_NDX,`CMPU_EXT:	begin a <= usp; res <= usp[`DBLBYTE] - b[`DBLBYTE]; end

		`NEG_DP,`NEG_NDX,`NEG_EXT:	begin res12 <= -b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`COM_DP,`COM_NDX,`COM_EXT:	begin res12 <= ~b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`LSR_DP,`LSR_NDX,`LSR_EXT:	begin res12 <= {b[0],1'b0,b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ROR_DP,`ROR_NDX,`ROR_EXT:	begin res12 <= {b[0],cf,b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASR_DP,`ASR_NDX,`ASR_EXT:	begin res12 <= {b[0],b[BPBM1],b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
		`ASL_DP,`ASL_NDX,`ASL_EXT:	begin res12 <= {b12,1'b0}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`ROL_DP,`ROL_NDX,`ROL_EXT:	begin res12 <= {b12,cf}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`DEC_DP,`DEC_NDX,`DEC_EXT:	begin res12 <= b12 - 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`INC_DP,`INC_NDX,`INC_EXT:	begin res12 <= b12 + 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TST_DP,`TST_NDX,`TST_EXT:	res12 <= b12;
		/*
		`AIM_DP,`AIM_NDX,`AIM_EXT:	begin res12 <= ir[`HIBYTE] & b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`OIM_DP,`OIM_NDX,`OIM_EXT:	begin res12 <= ir[`HIBYTE] | b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`EIM_DP,`EIM_NDX,`OIM_EXT:  begin res12 <= ir[`HIBYTE] ^ b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
		`TIM_DP,`TIM_NDX,`TIM_EXT:	begin res12 <= ir[`HIBYTE] & b12; end
		*/
		default:	;
		endcase
	end

// ============================================================================
// LOAD / STORE
// ============================================================================
LOAD1:
`ifdef SUPPORT_DCACHE
	if (unCachedData)
`endif
	case(radr)
	24'hFFFFE0:	load_tsk({2'b0,id});
	24'hFFFFE4:	load_tsk(ms_count[31:24]);
	24'hFFFFE5:	load_tsk(ms_count[23:16]);
	24'hFFFFE6:	load_tsk(ms_count[15: 8]);
	24'hFFFFE7:	load_tsk(ms_count[ 7: 0]);
	default:
	if (~ack_i) begin
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
		`SW_ACCDH:	wb_write(wadr,acca[`LOBYTE]);
		`SW_ACCDL:	wb_write(wadr,accb[`LOBYTE]);
		`SW_ACCA:	wb_write(wadr,acca[`LOBYTE]);
		`SW_ACCB:	wb_write(wadr,accb[`LOBYTE]);
		`SW_DPR:	wb_write(wadr,dpr);
		`SW_XL:	wb_write(wadr,xr[`LOBYTE]);
		`SW_XH:	wb_write(wadr,xr[`HIBYTE]);
		`SW_YL:	wb_write(wadr,yr[`LOBYTE]);
		`SW_YH:	wb_write(wadr,yr[`HIBYTE]);
		`SW_USPL:	wb_write(wadr,usp[`LOBYTE]);
		`SW_USPH:	wb_write(wadr,usp[`HIBYTE]);
		`SW_SSPL:	wb_write(wadr,ssp[`LOBYTE]);
		`SW_SSPH:	wb_write(wadr,ssp[`HIBYTE]);
		`SW_PC2316:	wb_write(wadr,pc[`BYTE3]);
		`SW_PCH:	wb_write(wadr,pc[`HIBYTE]);
		`SW_PCL:	wb_write(wadr,pc[`LOBYTE]);
		`SW_CCR:	wb_write(wadr,ccr);
		`SW_RES8:	wb_write(wadr,res12[`LOBYTE]);
		`SW_RES16H:	wb_write(wadr,res[`HIBYTE]);
		`SW_RES16L:	wb_write(wadr,res[`LOBYTE]);
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
		wadr <= wadr + 2'd1;
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
				case(ir12)
				`BSR:		pc <= pc + {{24{ir[BPBX2M1]}},ir[`HIBYTE]};
				`LBSR:	pc <= pc + {{12{ir[BPB*3-1]}},ir[`HIBYTE],ir[`BYTE3]};
				`JSR_DP:	pc <= {dpr,ir[`HIBYTE]};
				`JSR_EXT:	pc <= {pc[`BYTE3],address[`DBLBYTE]};
				`JSR_FAR:	
					begin
						pc <= far_address;
						$display("Loading PC with %h", far_address);
					end
				`JSR_NDX:
					begin
						if (isIndirect) begin
							radr <= NdxAddr;
							load_what <= isFar ? `LW_PC2316 : `LW_PCH;
							next_state(LOAD1);
						end
						else
							pc <= isFar ? NdxAddr : {pc[`BYTE3],NdxAddr[`DBLBYTE]};
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
			wadr <= ({usppg,8'h00} + usp - cnt);
			usp <= (usp - cnt);
		end
	end
PUSH2:
	begin
		next_state(STORE1);
		if (ir[bitsPerByte]) begin
			store_what <= `SW_CCR;
			ir[bitsPerByte] <= 1'b0;
		end
		else if (ir[bitsPerByte+1]) begin
			store_what <= `SW_ACCA;
			ir[bitsPerByte+1] <= 1'b0;
		end
		else if (ir[bitsPerByte+2]) begin
			store_what <= `SW_ACCB;
			ir[bitsPerByte+2] <= 1'b0;
		end
		else if (ir[bitsPerByte+3]) begin
			store_what <= `SW_DPR;
			ir[bitsPerByte+3] <= 1'b0;
		end
		else if (ir[bitsPerByte+4]) begin
			store_what <= `SW_XH;
			ir[bitsPerByte+4] <= 1'b0;
		end
		else if (ir[bitsPerByte+5]) begin
			store_what <= `SW_YH;
			ir[bitsPerByte+5] <= 1'b0;
		end
		else if (ir[bitsPerByte+6]) begin
			if (isINT | isPSHS)
				store_what <= `SW_USPH;
			else
				store_what <= `SW_SSPH;
			ir[bitsPerByte+6] <= 1'b0;
		end
		else if (ir[bitsPerByte+7]) begin
			store_what <= isFar ? `SW_PC2316 : `SW_PCH;
			ir[bitsPerByte+7] <= 1'b0;
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
					pc[`BYTE3] <= 8'h00;
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
		if (ir[bitsPerByte]) begin
			load_what <= `LW_CCR;
			ir[bitsPerByte] <= 1'b0;
		end
		else if (ir[bitsPerByte+1]) begin
			load_what <= `LW_ACCA;
			ir[bitsPerByte+1] <= 1'b0;
		end
		else if (ir[bitsPerByte+2]) begin
			load_what <= `LW_ACCB;
			ir[bitsPerByte+2] <= 1'b0;
		end
		else if (ir[bitsPerByte+3]) begin
			load_what <= `LW_DPR;
			ir[bitsPerByte+3] <= 1'b0;
		end
		else if (ir[bitsPerByte+4]) begin
			load_what <= `LW_XH;
			ir[bitsPerByte+4] <= 1'b0;
		end
		else if (ir[bitsPerByte+5]) begin
			load_what <= `LW_YH;
			ir[bitsPerByte+5] <= 1'b0;
		end
		else if (ir[bitsPerByte+6]) begin
			if (ir12==`PULU)
				load_what <= `LW_SSPH;
			else
				load_what <= `LW_USPH;
			ir[bitsPerByte+6] <= 1'b0;
		end
		else if (ir[bitsPerByte+7]) begin
			load_what <= isFar ? `LW_PC2316 : `LW_PCH;
			ir[bitsPerByte+7] <= 1'b0;
		end
		else
			next_state(IFETCH);
	end

// ----------------------------------------------------------------------------
// Outer Indexing Support
// ----------------------------------------------------------------------------
OUTER_INDEXING:
	begin
		if (bitsPerByte==8) begin
			casex(ndxbyte)
			8'b0xxxxxxx:	radr <= radr + ndxreg;
			8'b1xxx0000:
							begin
								radr <= radr + ndxreg;
								case(ndxbyte[6:5])
								2'b00:	xr <= (xr + 2'd1);
								2'b01:	yr <= (yr + 2'd1);
								2'b10:	usp <= (usp + 2'd1);
								2'b11:	ssp <= (ssp + 2'd1);
								endcase
							end
			8'b1xxx0001:	begin
								radr <= radr + ndxreg;
								case(ndxbyte[6:5])
								2'b00:	xr <= (xr + 2'd2);
								2'b01:	yr <= (yr + 2'd2);
								2'b10:	usp <= (usp + 2'd2);
								2'b11:	ssp <= (ssp + 2'd2);
								endcase
							end
			8'b1xxx0010:	radr <= radr + ndxreg;
			8'b1xxx0011:	radr <= radr + ndxreg;
			8'b1xxx0100:	radr <= radr + ndxreg;
			8'b1xxx0101:	radr <= radr + ndxreg;
			8'b1xxx0110:	radr <= radr + ndxreg;
			8'b1xxx1000:	radr <= radr + ndxreg;
			8'b1xxx1001:	radr <= radr + ndxreg;
			8'b1xxx1010:	radr <= radr + ndxreg;
			8'b1xxx1011:	radr <= radr + ndxreg;
			default:	radr <= radr;
			endcase
		end
		else if (bitsPerByte==12) begin
			casex(ndxbyte)
			12'b0xxxxxxxxxxx:	radr <= radr + ndxreg;
			12'b1xxxx0000000:
							begin
								radr <= radr + ndxreg;
								case(ndxbyte[10:9])
								2'b00:	xr <= (xr + 2'd1);
								2'b01:	yr <= (yr + 2'd1);
								2'b10:	usp <= (usp + 2'd1);
								2'b11:	ssp <= (ssp + 2'd1);
								endcase
							end
			12'b1xxxx0000001:	begin
								radr <= radr + ndxreg;
								case(ndxbyte[10:9])
								2'b00:	xr <= (xr + 2'd2);
								2'b01:	yr <= (yr + 2'd2);
								2'b10:	usp <= (usp + 2'd2);
								2'b11:	ssp <= (ssp + 2'd2);
								endcase
							end
			12'b1xxxx0000010:	radr <= radr + ndxreg;
			12'b1xxxx0000011:	radr <= radr + ndxreg;
			12'b1xxxx0000100:	radr <= radr + ndxreg;
			12'b1xxxx0000101:	radr <= radr + ndxreg;
			12'b1xxxx0000110:	radr <= radr + ndxreg;
			12'b1xxxx0001000:	radr <= radr + ndxreg;
			12'b1xxxx0001001:	radr <= radr + ndxreg;
			12'b1xxxx0001010:	radr <= radr + ndxreg;
			12'b1xxxx0001011:	radr <= radr + ndxreg;
			default:	radr <= radr;
			endcase
		end
		next_state(OUTER_INDEXING2);
	end
OUTER_INDEXING2:
	begin
		wadr <= radr;
		res <= radr[`DBLBYTE];
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
		else if (!tsc && !ack_i) begin
			rhit0 <= hit0;
			bte_o <= 2'b00;
			cti_o <= 3'b001;
			cyc_o <= 1'b1;
			bl_o <= 6'd15;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			adr_o <= !hit0 ? {pc[bitsPerByte*3-1:4],4'b00} : {pcp16[bitsPerByte*3-1:4],4'b0000};
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
		stb_o <= 1'b0;
		next_state(ICACHE4);
		if (adr_o[3:0]==4'b1110)
			cti_o <= 3'b111;
		if (adr_o[3:0]==4'b1111) begin
			wb_nack();
			next_state(ICACHE1);
		end
	end
ICACHE4:
	begin
		if (~ack_i) begin
			adr_o[3:0] <= adr_o[3:0] + 2'd1;
			stb_o <= 1'b1;
			next_state(ICACHE2);
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
		adr_o <= !rhit0 ? {pc[bitsPerByte*3-1:4],4'b00} : {pcp16[bitsPerByte*3-1:4],4'b0000};
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
		adr_o <= pc[`DBLBYTE];
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
		ibuf[`HIBYTE] <= dat_i;
		next_state(IBUF4);
	end
IBUF4:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[`BYTE3] <= dat_i;
		next_state(IBUF5);
	end
IBUF5:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[`BYTE4] <= dat_i;
		next_state(IBUF6);
	end
IBUF6:
	if (tsc|rty_i) begin
		wb_nack();
		next_state(IBUF1);
	end
	else if (ack_i) begin
		wb_nack();
		ibuf[`BYTE5] <= dat_i;
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
		load_what <= isFar ? `LW_IA2316 : `LW_IAH;
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
	pc <= pc + (isFar ? 3'd4 : 3'd3);
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
input [bitsPerByte*2-1:0] adr;
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
input [`TRPBYTE] adr;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		adr_o <= adr;
	end
end
endtask

task wb_write;
input [`TRPBYTE] adr;
input [`LOBYTE] dat;
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
input [`LOBYTE] dat;
begin
	case(load_what)
	`LW_BH:
			begin
				radr <= radr + 2'd1;
				b[`HIBYTE] <= dat;
				load_what <= `LW_BL;
				next_state(LOAD1);
			end
	`LW_BL:
			begin
				// Don't increment address here for the benefit of the memory
				// operate instructions which set wadr=radr in CALC.
				b[`LOBYTE] <= dat;
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
					ir[`HIBYTE] <= dat[7] ? 12'hFE : 12'h80;
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
				xr[`HIBYTE] <= dat;
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
				xr[`LOBYTE] <= dat;
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
				yr[`HIBYTE] <= dat;
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
				yr[`LOBYTE] <= dat;
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
				usp[`HIBYTE] <= dat;
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
				usp[`LOBYTE] <= dat;
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
				ssp[`HIBYTE] <= dat;
				radr <= radr + 2'd1;
				if (isRTI) begin
					ssp <= ssp + 2'd1;
				end
				else if (isPULU) begin
					usp <= usp + 2'd1;
				end
			end
	`LW_SSPL:	begin
				ssp[`LOBYTE] <= dat;
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
				pc[`LOBYTE] <= dat;
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
				pc[`HIBYTE] <= dat;
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
	`LW_PC2316:	begin
				pc[`BYTE3] <= dat;
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
				ia[`LOBYTE] <= dat;
				res[`LOBYTE] <= dat;
				radr <= {ia[`BYTE3],ia[`HIBYTE],dat};
				wadr <= {ia[`BYTE3],ia[`HIBYTE],dat};
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
				ia[`HIBYTE] <= dat;
				res[`HIBYTE] <= dat;
				load_what <= `LW_IAL;
				radr <= radr + 2'd1;
				next_state(LOAD1);
			end
	`LW_IA2316:
			begin
				ia[`BYTE3] <= dat;
				load_what <= `LW_IAH;
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
module rf6809_icachemem(wclk, wce, wr, wa, i, rclk, rce, pc, insn);
input wclk;
input wce;
input wr;
input [11:0] wa;
input [`LOBYTE] i;
input rclk;
input rce;
input [11:0] pc;
output [`HEXBYTE] insn;
reg [`HEXBYTE] insn;

integer n;
reg [127:0] mem [0:255];
reg [11:0] rpc,rpcp16;
initial begin
	for (n = 0; n < 256; n = n + 1)
		mem[n] = {16{`NOP}};
end

genvar g;
generate begin : gMem
	for (g = 0; g < 16; g = g + 1)
		always_ff @(posedge wclk)
			if (wce & wr & wa[3:0]==g) mem[wa[11:4]][g*bitsPerByte+BPBM1:g*bitsPerByte] <= i;
end
endgenerate

always_ff @(posedge rclk)
	if (rce) rpc <= pc;
always_ff @(posedge rclk)
	if (rce) rpcp16 <= pc + 5'd16;
wire [191:0] insn0 = mem[rpc[11:4]];
wire [191:0] insn1 = mem[rpcp16[11:4]];
always_comb
if (BPB==8)
	insn = {insn1,insn0} >> {rpc[3:0],3'b0};
else
	insn = {insn1,insn0} >> ({rpc[3:0],3'b0} + {rpc[3:0],2'b0});

endmodule

module rf6809_itagmem(wclk, wce, wr, wa, invalidate, rclk, rce, pc, hit0, hit1);
input wclk;
input wce;
input wr;
input [`TRPBYTE] wa;
input invalidate;
input rclk;
input rce;
input [`TRPBYTE] pc;
output hit0;
output hit1;

integer n;
reg [BPB*3-1:12] mem [0:255];
reg [0:255] tvalid = 256'd0;
reg [`TRPBYTE] rpc,rpcp16;
wire [BPB*3-1:11] tag0,tag1;
initial begin
	for (n = 0; n < 256; n = n + 1)
		mem[n] = {BPB*2{1'b0}};
end

always_ff @(posedge wclk)
	if (wce & wr) mem[wa[11:4]] <= wa[BPB*3-1:12];
always_ff @(posedge wclk)
	if (invalidate) tvalid <= 256'd0;
	else if (wce & wr) tvalid[wa[11:4]] <= 1'b1;
always_ff @(posedge rclk)
	if (rce) rpc <= pc;
always_ff @(posedge rclk)
	if (rce) rpcp16 <= pc + 5'd16;
assign tag0 = {mem[rpc[11:4]],tvalid[rpc[11:4]]};
assign tag1 = {mem[rpcp16[11:4]],tvalid[rpcp16[11:4]]};

assign hit0 = tag0 == {rpc[BPB*3-1:12],1'b1};
assign hit1 = tag1 == {rpcp16[BPB*3-1:12],1'b1};

endmodule

