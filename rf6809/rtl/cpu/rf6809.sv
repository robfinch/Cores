// ============================================================================
//        __
//   \\__/ o\    (C) 2022  Robert Finch, Waterloo
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
	rty_i, bte_o, cti_o, bl_o, lock_o, cyc_o, stb_o, we_o, ack_i, aack_i, atag_i,
	adr_o, dat_i, dat_o, pcr_o, icl_o, exv_i, wrv_i, rdv_i, state);
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
parameter STORE1a = 6'd10;
parameter STORE2 = 6'd11;
parameter OUTER_INDEXING = 6'd12;
parameter OUTER_INDEXING2 = 6'd13;
parameter DIV1 = 6'd16;
parameter DIV2 = 6'd17;
parameter DIV3 = 6'd18;
parameter MUL2 = 6'd20;
parameter DFMUL1 = 6'd21;
parameter DFDIV1 = 6'd22;
parameter ICACHE1 = 6'd31;
parameter ICACHE2 = 6'd32;
parameter ICACHE3 = 6'd33;
parameter ICACHE4 = 6'd34;
parameter ICACHE5 = 6'd35;
parameter ICACHE6 = 6'd36;
parameter ICACHE7 = 6'd37;
parameter ICACHE8 = 6'd38;
parameter ICACHE9 = 6'd39;
parameter IBUF1 = 6'd40;
parameter IBUF2 = 6'd41;
parameter IBUF3 = 6'd42;
parameter IBUF4 = 6'd43;
parameter IBUF5 = 6'd44;
parameter IBUF6 = 6'd45;
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
input aack_i;
input [3:0] atag_i;
output reg [`TRPBYTE] adr_o;
input [`LOBYTE] dat_i;
output reg [`LOBYTE] dat_o;
output reg [23:0] pcr_o;
output reg icl_o;
input exv_i;
input wrv_i;
input rdv_i;
output [5:0] state;

reg [5:0] state;
reg [5:0] load_what,store_what,load_what2;
reg [`LOBYTE] tr;		// task register
reg [`TRPBYTE] tcb_base;
reg [`TRPBYTE] pc;
wire [`TRPBYTE] pcp2 = pc + 4'd2;
wire [`TRPBYTE] pcp16 = pc + 5'd16;
wire [`OCTABYTE] insn;
wire icacheOn = 1'b1;
reg [`TRPBYTE] ibufadr, icwa;
reg [191:0] ibuf;
wire ibufhit = ibufadr==pc;
reg natMd,firqMd,iplMd,dbz,iop;
reg md32;
wire [`DBLBYTE] mask = 24'hFFFFFF;
reg [1:0] ipg;
reg isFar;
reg isOuterIndexed;
reg [`OCTABYTE] ir;
`ifdef EIGHTBIT
wire [9:0] ir12 = {ipg,ir[`LOBYTE]};
`endif
`ifdef TWELVEBIT
wire [`LOBYTE] ir12 = ir[`LOBYTE];
`endif
reg [`DBLBYTE] dpr;		// direct page register
reg [`LOBYTE] stkbnk;	// stack pointer bank

Address [3:0] brkad;	// breakpoint addresses
brkCtrl [3:0] brkctrl;

wire [`LOBYTE] ndxbyte;
reg cf,vf,zf,nf,hf,ef;
wire [`LOBYTE] cfx8 = cf;
wire [`DBLBYTE] cfx24 = {23'b0,cf};
reg im,im1,firqim;
reg dm;	// decimal mode
reg df;	// done flag
reg sync_state,wait_state;
wire [`LOBYTE] ccr = bitsPerByte==12 ? {1'b0,df,im1,dm,ef,firqim,hf,im,nf,zf,vf,cf} : {ef,firqim,hf,im,nf,zf,vf,cf};
reg [`LOBYTE] acca,accb;
`ifdef SUPPORT_6309
reg [`LOBYTE] acce,accf;
`endif
reg [`DBLBYTE] accd;
reg [127:0] accg;
`ifdef SUPPORT_6309
reg [`DBLBYTE] accw;
`endif
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
reg [`LOBYTE] chkpoint;
reg [15:0] icgot;
reg [23:0] btocnt;
reg bto;							// bus timed out

reg [`DBLBYTE] a;
reg [127:0] b;
wire [`LOBYTE] b12 = b[`LOBYTE];
reg [`TRPBYTE] radr,wadr;
reg [`DBLBYTE] wdat;

reg nmi1,nmi_edge;
reg nmi_armed;

reg isStore;
reg isPULU,isPULS;
reg isPSHS,isPSHU;
reg isRTS,isRTI,isRTF,isJTT;
reg isLEA;
reg isRMW;
reg isDFSub;

function fnAddOverflow;
input a;
input b;
input r;
begin
	fnAddOverflow = (r ^ b) & (1'b1 ^ a ^ b);
end
endfunction

function fnSubOverflow;
input a;
input b;
input r;
begin
	fnSubOverflow = (1'b1 ^ r ^ b) & (a ^ b);
end
endfunction

// Data input path multiplexing
reg [bitsPerByte-1:0] dati;
always_comb
	dati = dat_i;

reg rdyq_ins;
reg rdyq_pop;
reg rdyq_peek;
reg [2:0] rdyq_wa;
reg [11:0] rdyq_tidi;
wire [11:0] rdyq_tido;

`ifdef SUPPORT_OS
ReadyQueues urdyq1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.insert_i(rdyq_ins),
	.pop_i(rdyq_pop),
	.peek_i(rdyq_peek),
	.tid_i(rdy1_tidi),
	.priority_i(rdyq_wa),
	.tid_o(rdyq_tido)
);

`endif

genvar g;

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
			(ir[bitsPerByte+3] ? (bitsPerByte== 8 ? 5'd1 : 5'd2) : 5'd0) +
			(ir[bitsPerByte+4] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+5] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+6] ? 5'd2 : 5'd0) +
			(ir[bitsPerByte+7] ? (isFar ? 5'd3 : 5'd2) : 5'd0)
`ifdef SUPPORT_6309
			+ (ir[bitsPerByte+8] ? 5'd1 : 5'd0) +
			+ (ir[bitsPerByte+9] ? 5'd1 : 5'd0)
`endif			
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

`ifdef SUPPORT_6309
wire isInMem =	ir12==`AIM_DP || ir12==`EIM_DP || ir12==`OIM_DP || ir12==`TIM_DP ||
				ir12==`AIM_NDX || ir12==`EIM_NDX || ir12==`OIM_NDX || ir12==`TIM_NDX ||
				ir12==`AIM_EXT || ir12==`EIM_EXT || ir12==`OIM_EXT || ir12==`TIM_EXT
				;
wire isRMW1 = 	ir12==`AIM_DP || ir12==`EIM_DP || ir12==`OIM_DP ||
				ir12==`NEG_DP || ir12==`COM_DP || ir12==`LSR_DP || ir12==`ROR_DP || ir12==`ASR_DP || ir12==`ASL_DP || ir12==`ROL_DP || ir12==`DEC_DP || ir12==`INC_DP ||
				ir12==`AIM_NDX || ir12==`EIM_NDX || ir12==`OIM_NDX || 
				ir12==`NEG_NDX || ir12==`COM_NDX || ir12==`LSR_NDX || ir12==`ROR_NDX || ir12==`ASR_NDX || ir12==`ASL_NDX || ir12==`ROL_NDX || ir12==`DEC_NDX || ir12==`INC_NDX ||
				ir12==`AIM_EXT || ir12==`EIM_EXT || ir12==`OIM_EXT || 
				ir12==`NEG_EXT || ir12==`COM_EXT || ir12==`LSR_EXT || ir12==`ROR_EXT || ir12==`ASR_EXT || ir12==`ASL_EXT || ir12==`ROL_EXT || ir12==`DEC_EXT || ir12==`INC_EXT
				;
`else
wire isInMem = 1'b0;
wire isRMW1 = 	ir12==`NEG_DP || ir12==`COM_DP || ir12==`LSR_DP || ir12==`ROR_DP || ir12==`ASR_DP || ir12==`ASL_DP || ir12==`ROL_DP || ir12==`DEC_DP || ir12==`INC_DP ||
				ir12==`NEG_NDX || ir12==`COM_NDX || ir12==`LSR_NDX || ir12==`ROR_NDX || ir12==`ASR_NDX || ir12==`ASL_NDX || ir12==`ROL_NDX || ir12==`DEC_NDX || ir12==`INC_NDX ||
				ir12==`NEG_EXT || ir12==`COM_EXT || ir12==`LSR_EXT || ir12==`ROR_EXT || ir12==`ASR_EXT || ir12==`ASL_EXT || ir12==`ROL_EXT || ir12==`DEC_EXT || ir12==`INC_EXT
				;
`endif

wire isIndexed =
	ir12[7:4]==4'h6 || ir12[7:4]==4'hA || ir12[7:4]==4'hE ||
	ir12==`LEAX_NDX || ir12==`LEAY_NDX || ir12==`LEAS_NDX || ir12==`LEAU_NDX
	;
reg isDblIndirect;
wire isIndirect = ndxbyte[bitsPerByte-4] & ndxbyte[bitsPerByte-1];
`ifdef TWELVEBIT
always_comb
	isOuterIndexed = ndxbyte[bitsPerByte-5] & ndxbyte[bitsPerByte-1];
`endif

assign ndxbyte = isInMem ? ir[`BYTE3] : ir[`HIBYTE];

// Detect type of interrupt
wire isINT = ir12==`INT;
wire isRST = bitsPerByte==8 ? vect[7:0]==8'hFE : vect[7:0]==8'hFC;
wire isNMI = bitsPerByte==8 ? vect[7:0]==8'hFC : vect[7:0]==8'hF8;
wire isSWI = bitsPerByte==8 ? vect[7:0]==8'hFA : vect[7:0]==8'hF4;
wire isIRQ = bitsPerByte==8 ? vect[7:0]==8'hF8 : vect[7:0]==8'hF0;
wire isFIRQ = bitsPerByte==8 ? vect[7:0]==8'hF6 : vect[7:0]==8'hEC;
//wire isSWI2 = bitsPerByte==8 ? vect[7:0]==8'hF4 : vect[7:0]==8'hE8;
reg isSWI2;
reg isSYS;
wire isSWI3 = bitsPerByte==8 ? vect[7:0]==8'hF2 : vect[7:0]==8'hE4;

wire [`TRPBYTE] far_address = isInMem ? {ir[`BYTE3],ir[`BYTE4],ir[`BYTE5]} : {ir[`HIBYTE],ir[`BYTE3],ir[`BYTE4]};
wire [`TRPBYTE] address = isInMem ? {ir[`BYTE3],ir[`BYTE4]} : {ir[`HIBYTE],ir[`BYTE3]};
wire [`TRPBYTE] dp_address = isInMem ? {dpr,ir[`BYTE3]} : {dpr,ir[`HIBYTE]};
wire [`TRPBYTE] ex_address = isFar ? far_address : address;
wire [`TRPBYTE] offset12 = isInMem ? {{bitsPerByte*2{ir[bitsPerByte*4-1]}},ir[`BYTE4]} : {{bitsPerByte*2{ir[bitsPerByte*3-1]}},ir[`BYTE3]};
wire [`TRPBYTE] offset24 = isInMem ? {{bitsPerByte{ir[bitsPerByte*4-1]}},ir[`BYTE4],ir[`BYTE5]} : {{bitsPerByte{ir[bitsPerByte*3-1]}},ir[`BYTE3],ir[`BYTE4]};
wire [`TRPBYTE] offset36 = isInMem ? {ir[`BYTE4],ir[`BYTE5],ir[`BYTE6]} : {ir[`BYTE3],ir[`BYTE4],ir[`BYTE5]};

// Choose the indexing register
reg [`TRPBYTE] ndxreg;
always_comb
	if (bitsPerByte==8)
		case(ndxbyte[6:5])
		2'b00:	ndxreg <= xr;
		2'b01:	ndxreg <= yr;
		2'b10:	ndxreg <= {stkbnk,usp};
		2'b11:	ndxreg <= {stkbnk,ssp};
		endcase
	else if (bitsPerByte==12)
		case(ndxbyte[10:9])
		2'b00:	ndxreg <= xr;
		2'b01:	ndxreg <= yr;
		2'b10:	ndxreg <= {stkbnk,usp};
		2'b11:	ndxreg <= {stkbnk,ssp};
		endcase
	
reg [`TRPBYTE] NdxAddr;
always_comb
	if (bitsPerByte==8)
		casez({isOuterIndexed,ndxbyte})
		9'b00???????:	NdxAddr <= ndxreg + {{19{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		9'b01???0000:	NdxAddr <= ndxreg;
		9'b01???0001:	NdxAddr <= ndxreg;
		9'b01???0010:	NdxAddr <= ndxreg - 2'd1;
		9'b01???0011:	NdxAddr <= ndxreg - 2'd2;
		9'b01???0100:	NdxAddr <= ndxreg;
		9'b01???0101:	NdxAddr <= ndxreg + {{BPB*2{accb[BPBM1]}},accb};
		9'b01???0110:	NdxAddr <= ndxreg + {{BPB*2{acca[BPBM1]}},acca};
		9'b01???1000:	NdxAddr <= ndxreg + offset12;
		9'b01???1001:	NdxAddr <= ndxreg + offset24;
		9'b01???1010:	NdxAddr <= ndxreg + offset36;
		9'b01???1011:	NdxAddr <= ndxreg + {acca,accb};
		9'b01???1100:	NdxAddr <= pc + offset12 + 3'd3;
		9'b01???1101:	NdxAddr <= pc + offset24 + 3'd4;
		9'b01???1110:	NdxAddr <= pc + offset36 + 3'd5;
		9'b01??01111:	NdxAddr <= isFar ? offset36 : offset24;
		9'b01??11111:	NdxAddr <= offset24;
		9'b10???????:	NdxAddr <= {{11{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		9'b11???0000:	NdxAddr <= 24'd0;
		9'b11???0001:	NdxAddr <= 24'd0;
		9'b11???0010:	NdxAddr <= 24'd0;
		9'b11???0011:	NdxAddr <= 24'd0;
		9'b11???0100:	NdxAddr <= 24'd0;
		9'b11???0101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		9'b11???0110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
		9'b11???1000:	NdxAddr <= offset12;
		9'b11???1001:	NdxAddr <= offset24;
		9'b11???1010:	NdxAddr <= offset36;
		9'b11???1011:	NdxAddr <= {acca,accb};
		9'b11???1100:	NdxAddr <= pc + offset12 + 3'd3;
		9'b11???1101:	NdxAddr <= pc + offset24 + 3'd4;
		9'b11???1110:	NdxAddr <= pc + offset36 + 3'd5;
		9'b11??01111:	NdxAddr <= isFar ? offset36 : offset24;
		9'b11??11111:	NdxAddr <= offset24;
		default:		NdxAddr <= 24'hFFFFFF;
		endcase
	else if (bitsPerByte==12)
		casez({isOuterIndexed,ndxbyte})
		13'b00???????????:	NdxAddr <= ndxreg + {{27{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		13'b01???00000000:	NdxAddr <= ndxreg;
		13'b01???00000001:	NdxAddr <= ndxreg;
		13'b01???00000010:	NdxAddr <= ndxreg - 2'd1;
		13'b01???00010010:	NdxAddr <= ndxreg - 2'd2;
		13'b01???00100010:	NdxAddr <= ndxreg - 2'd3;
		13'b01???00000011:	NdxAddr <= ndxreg - 2'd2;
		13'b01???00000100:	NdxAddr <= ndxreg;
		13'b01???00000101:	NdxAddr <= ndxreg + {{BPB*2{accb[BPBM1]}},accb};
		13'b01???00000110:	NdxAddr <= ndxreg + {{BPB*2{acca[BPBM1]}},acca};
`ifdef SUPPORT_6309
		13'b01???00010101:	NdxAddr <= ndxreg + {{BPB*2{accf[BPBM1]}},accf};
		13'b01???00010110:	NdxAddr <= ndxreg + {{BPB*2{acce[BPBM1]}},acce};
		13'b01???00011011:	NdxAddr <= ndxreg + {acce,accf};
`endif
		13'b01???00001000:	NdxAddr <= ndxreg + offset12;
		13'b01???00001001:	NdxAddr <= ndxreg + offset24;
		13'b01???00001010:	NdxAddr <= ndxreg + offset36;
		13'b01???00001011:	NdxAddr <= ndxreg + {acca,accb};
		13'b01???00001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b01???00001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b01???00001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b01??000001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b01??100001111:	NdxAddr <= offset24;
		13'b01???10000000:	NdxAddr <= 24'd0;
		13'b01???10000001:	NdxAddr <= 24'd0;
		13'b01???10000010:	NdxAddr <= 24'd0;
		13'b01???10000011:	NdxAddr <= 24'd0;
		13'b01???10000100:	NdxAddr <= 24'd0;
		13'b01???10000101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		13'b01???10000110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
`ifdef SUPPORT_6309
		13'b01???10010101:	NdxAddr <= {{BPB*2{accf[BPBM1]}},accf};
		13'b01???10010110:	NdxAddr <= {{BPB*2{acce[BPBM1]}},acce};
		13'b01???10011011:	NdxAddr <= {acce,accf};
`endif		
		13'b01???10001000:	NdxAddr <= offset12;
		13'b01???10001001:	NdxAddr <= offset24;
		13'b01???10001010:	NdxAddr <= offset36;
		13'b01???10001011:	NdxAddr <= {acca,accb};
		13'b01???10001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b01???10001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b01???10001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b01??010001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b01??110001111:	NdxAddr <= offset24;
		13'b10???????????:	NdxAddr <= {{15{ndxbyte[BPB-4]}},ndxbyte[BPB-4:0]};
		13'b11???00000000:	NdxAddr <= 24'd0;
		13'b11???00000001:	NdxAddr <= 24'd0;
		13'b11???00000010:	NdxAddr <= 24'd0;
		13'b11???00000011:	NdxAddr <= 24'd0;
		13'b11???00000100:	NdxAddr <= 24'd0;
		13'b11???00000101:	NdxAddr <= {{BPB*2{accb[BPBM1]}},accb};
		13'b11???00000110:	NdxAddr <= {{BPB*2{acca[BPBM1]}},acca};
		13'b11???00001000:	NdxAddr <= offset12;
		13'b11???00001001:	NdxAddr <= offset24;
		13'b11???00001010:	NdxAddr <= offset36;
		13'b11???00001011:	NdxAddr <= {acca,accb};
		13'b11???00001100:	NdxAddr <= pc + offset12 + 3'd3;
		13'b11???00001101:	NdxAddr <= pc + offset24 + 3'd4;
		13'b11???00001110:	NdxAddr <= pc + offset36 + 3'd5;
		13'b11??000001111:	NdxAddr <= isFar ? offset36 : offset24;
		13'b11??000011111:	NdxAddr <= offset24;
		default:		NdxAddr <= 24'hFFFFFF;
		endcase
	
// Compute instruction length depending on indexing byte
reg [2:0] insnsz;
always_comb
	if (bitsPerByte==8)
		casez(ndxbyte)
		8'b0???????:	insnsz <= 4'h2;
		8'b1??00000:	insnsz <= 4'h2;
		8'b1??00001:	insnsz <= 4'h2;
		8'b1??00010:	insnsz <= 4'h2;
		8'b1??00011:	insnsz <= 4'h2;
		8'b1??00100:	insnsz <= 4'h2;
		8'b1??00101:	insnsz <= 4'h2;
		8'b1??00110:	insnsz <= 4'h2;
		8'b1??01000:	insnsz <= 4'h3;
		8'b1??01001:	insnsz <= 4'h4;
		8'b1??01010:	insnsz <= 4'h5;
		8'b1??01011:	insnsz <= 4'h2;
		8'b1??01100:	insnsz <= 4'h3;
		8'b1??01101:	insnsz <= 4'h4;
		8'b1??01110:	insnsz <= 4'h5;
		8'b1??01111:	insnsz <= isFar ? 4'h5 : 4'h4;
		8'b1??11111:	insnsz <= 4'h4;
		default:	insnsz <= 4'h2;
		endcase
	else if (bitsPerByte==12)
		casez(ndxbyte)
		12'b0???????????:	insnsz <= 4'h2;
		12'b1???00000000:	insnsz <= 4'h2;
		12'b1???00000001:	insnsz <= 4'h2;
		12'b1???00000010:	insnsz <= 4'h2;
		12'b1???00000011:	insnsz <= 4'h2;
		12'b1???00000100:	insnsz <= 4'h2;
		12'b1???000?0101:	insnsz <= 4'h2;
		12'b1???000?0110:	insnsz <= 4'h2;
		12'b1???00001000:	insnsz <= 4'h3;
		12'b1???00001001:	insnsz <= 4'h4;
		12'b1???00001010:	insnsz <= 4'h5;
		12'b1???000?1011:	insnsz <= 4'h2;
		12'b1???00001100:	insnsz <= 4'h3;
		12'b1???00001101:	insnsz <= 4'h4;
		12'b1???00001110:	insnsz <= 4'h5;
		12'b1??000001111:	insnsz <= isFar ? 4'h5 : 4'h4;
		12'b1??100001111:	insnsz <= 4'h4;
		default:	insnsz <= 4'h2;
		endcase

// Source registers for transfer or exchange instructions.
reg [`DBLBYTE] src1,src2;
always_comb
	case(ir[bitsPerByte+7:bitsPerByte+4])
	4'b0000:	src1 <= {acca[`LOBYTE],accb[`LOBYTE]};
	4'b0001:	src1 <= xr;
	4'b0010:	src1 <= yr;
	4'b0011:	src1 <= usp;
	4'b0100:	src1 <= ssp;
	4'b0101:	src1 <= pcp2;
	4'b1000:	src1 <= {12'hFFF,acca[`LOBYTE]};
	4'b1001:	src1 <= {12'hFFF,accb[`LOBYTE]};
	4'b1010:	src1 <= {ccr,ccr};
	4'b1011:	src1 <= bitsPerByte==8 ? dpr[`LOBYTE] : dpr;
	4'b1100:	src1 <= stkbnk;
	4'b1101:	src1 <= {12'hFFF,tr};
`ifdef SUPPORT_6309
	4'b0110:	src1 <= {acce[`LOBYTE],accf[`LOBYTE]};
	4'b1110:	src1 <= {12'hFFF,acce};
	4'b1111:	src1 <= {12'hFFF,accf};
`else
	4'b1110:	src1 <= 24'h0000;
	4'b1111:	src1 <= 24'h0000;
`endif
	default:	src1 <= 24'h0000;
	endcase
always_comb
	case(ir[bitsPerByte+3:bitsPerByte])
	4'b0000:	src2 <= {acca[`LOBYTE],accb[`LOBYTE]};
	4'b0001:	src2 <= xr;
	4'b0010:	src2 <= yr;
	4'b0011:	src2 <= usp;
	4'b0100:	src2 <= ssp;
	4'b0101:	src2 <= pcp2;
	4'b1000:	src2 <= acca[`LOBYTE];
	4'b1001:	src2 <= accb[`LOBYTE];
	4'b1010:	src2 <= ccr;
	4'b1011:	src2 <= bitsPerByte==8 ? dpr[`LOBYTE] : dpr;
	4'b1100:	src2 <= stkbnk;
	4'b1101:	src2 <= tr;
`ifdef SUPPORT_6309
	4'b0110:	src2 <= {acce[`LOBYTE],accf[`LOBYTE]};
	4'b1110:	src2 <= acce;
	4'b1111:	src2 <= accf;
`else
	4'b1110:	src2 <= 24'h0000;
	4'b1111:	src2 <= 24'h0000;
`endif
	default:	src2 <= 24'h0000;
	endcase

wire [bitsPerByte*2:0] sum12 = src1 + src2;
wire [bitsPerByte*2:0] sum12c = src1 + src2 + cf;
wire [bitsPerByte*2-1:0] and12 = src1 & src2;
wire [bitsPerByte*2-1:0] eor12 = src1 ^ src2;
wire [bitsPerByte*2-1:0] or12 = src1 | src2;
wire [bitsPerByte*2:0] dif12 = src1 - src2;
wire [bitsPerByte*2:0] dif12c = src1 - src2 - cf;

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
wire isAdc = 	ir12==`ADCA_IMM || ir12==`ADCA_DP || ir12==`ADCA_NDX || ir12==`ADCA_EXT ||
							ir12==`ADCB_IMM || ir12==`ADCB_DP || ir12==`ADCB_NDX || ir12==`ADCB_EXT ||
							ir12==`ADCD_IMM || ir12==`ADCD_DP || ir12==`ADCD_NDX || ir12==`ADCD_EXT ;
wire isSbc =	ir12==`SBCA_IMM || ir12==`SBCA_DP || ir12==`SBCA_NDX || ir12==`SBCA_EXT ||
							ir12==`SBCB_IMM || ir12==`SBCB_DP || ir12==`SBCB_NDX || ir12==`SBCB_EXT ||
							ir12==`SBCD_IMM || ir12==`SBCD_DP || ir12==`SBCD_NDX || ir12==`SBCD_EXT ;

`ifdef SUPPORT_6309
wire isAcce = 	ir12 ==	`ADDE_IMM || ir12==`ADDE_DP || ir12==`ADDE_NDX || ir12==`ADDE_EXT || ir12==`CLRE || ir12==`COME ||
								ir12 == `SUBE_IMM || ir12==`SUBE_DP || ir12==`SUBE_NDX || ir12==`SUBE_EXT ||
								ir12 == `LDE_IMM || ir12==`LDE_DP || ir12==`LDE_NDX || ir12==`LDE_EXT ||
								ir12 == `DECE || ir12==`INCE ||
								ir12 == `CMPE_IMM || ir12==`CMPE_DP || ir12==`CMPE_NDX || ir12==`CMPE_EXT
				;
wire isAccf = 	ir12 ==	`ADDF_IMM || ir12==`ADDF_DP || ir12==`ADDF_NDX || ir12==`ADDF_EXT || ir12==`CLRF || ir12==`COMF ||
								ir12 == `SUBF_IMM || ir12==`SUBF_DP || ir12==`SUBF_NDX || ir12==`SUBF_EXT ||
								ir12 == `LDF_IMM || ir12==`LDF_DP || ir12==`LDF_NDX || ir12==`LDF_EXT ||
								ir12 == `DECF || ir12==`INCF ||
								ir12 == `CMPF_IMM || ir12==`CMPF_DP || ir12==`CMPF_NDX || ir12==`CMPF_EXT
				;
wire [`DBLBYTE] acc = isAcce ? acce : isAccf ? accf : isAcca ? acca : accb;
`else
wire [`DBLBYTE] acc = isAcca ? acca : accb;
`endif

always_ff @(posedge clk_i)
if (state==DECODE) begin
	isStore <= 	ir12==`STA_DP || ir12==`STB_DP || ir12==`STD_DP || ir12==`STX_DP || ir12==`STY_DP || ir12==`STU_DP || ir12==`STS_DP || ir12==`STG_DP ||
				ir12==`STA_NDX || ir12==`STB_NDX || ir12==`STD_NDX || ir12==`STX_NDX || ir12==`STY_NDX || ir12==`STU_NDX || ir12==`STS_NDX ||
				ir12==`STG_NDX || ir12==`STG_EXT ||
				ir12==`STA_EXT || ir12==`STB_EXT || ir12==`STD_EXT || ir12==`STX_EXT || ir12==`STY_EXT || ir12==`STU_EXT || ir12==`STS_EXT ||
				ir12==`STE_DP || ir12==`STE_NDX || ir12==`STE_EXT || ir12==`STF_DP || ir12==`STF_NDX || ir12==`STF_EXT ||
				ir12==`STW_DP || ir12==`STW_NDX || ir12==`STW_EXT
				;
	isPULU <= ir12==`PULU;
	isPULS <= ir12==`PULS;
	isPSHS <= ir12==`PSHS;
	isPSHU <= ir12==`PSHU;
	isRTI <= ir12==`RTI;
	isJTT <= ir12==`JTT || ir12==`JTT_DP || ir12==`JTT_NDX || ir12==`JTT_EXT;
	isRTS <= ir12==`RTS;
	isRTF <= ir12==`RTF;
	isLEA <= ir12==`LEAX_NDX || ir12==`LEAY_NDX || ir12==`LEAU_NDX || ir12==`LEAS_NDX;
	isRMW <= isRMW1;
	isDFSub <= ir12==`SUBG_DP || ir12==`SUBG_NDX || ir12==`SUBG_EXT;
end

wire hit0, hit1;
wire ihit = hit0 & hit1;
reg rhit0;

assign lic_o =	(state==CALC && !isRMW) ||
				(state==DECODE && (
					ir12==`NOP || ir12==`ORCC || ir12==`ANDCC || ir12==`DAA || ir12==`LDMD || ir12==`BITMD || ir12==`TFR || ir12==`EXG ||
					ir12==`NEGA || ir12==`COMA || ir12==`LSRA || ir12==`RORA || ir12==`ASRA || ir12==`ROLA || ir12==`DECA || ir12==`INCA || ir12==`TSTA || ir12==`CLRA ||
					ir12==`DECE || ir12==`DECF || ir12==`DECD || ir12==`DECW || ir12==`INCE || ir12==`INCF || ir12==`INCD || ir12==`INCW ||
					ir12==`NEGB || ir12==`COMB || ir12==`LSRB || ir12==`RORB || ir12==`ASRB || ir12==`ROLB || ir12==`DECB || ir12==`INCB || ir12==`TSTB || ir12==`CLRB ||
					ir12==`COME || ir12==`COMF || ir12==`COMD || ir12==`COMW ||
					ir12==`ASLD || ir12==`ASRD || ir12==`TSTD || ir12==`ADDR || ir12==`ADCR || ir12==`ANDR ||
					ir12==`TSTE || ir12==`TSTF || ir12==`TSTW ||
					ir12==`LSRD || ir12==`LSRW || ir12==`NEGD || ir12==`ROLD || ir12==`ROLW || ir12==`RORD || ir12==`RORW ||
					ir12==`SUBA_IMM || ir12==`CMPA_IMM || ir12==`SBCA_IMM || ir12==`ANDA_IMM || ir12==`BITA_IMM || ir12==`LDA_IMM || ir12==`EORA_IMM || ir12==`ADCA_IMM || ir12==`ORA_IMM || ir12==`ADDA_IMM ||
					ir12==`SUBB_IMM || ir12==`CMPB_IMM || ir12==`SBCB_IMM || ir12==`ANDB_IMM || ir12==`BITB_IMM || ir12==`LDB_IMM || ir12==`EORB_IMM || ir12==`ADCB_IMM || ir12==`ORB_IMM || ir12==`ADDB_IMM ||
					ir12==`EORD_IMM || ir12==`ANDD_IMM || ir12==`ORD_IMM || ir12==`BITD_IMM || ir12==`ADDD_IMM || ir12==`ADCD_IMM || ir12==`SUBD_IMM || ir12==`SBCD_IMM || ir12==`LDD_IMM || ir12==`LDW_IMM ||
					ir12==`LDQ_IMM || ir12==`CMPD_IMM || ir12==`CMPX_IMM || ir12==`CMPY_IMM || ir12==`CMPU_IMM || ir12==`CMPS_IMM || ir12==`CMPW_IMM ||
					ir12==`LDE_IMM || ir12==`LDF_IMM ||
					ir12==`SUBE_IMM || ir12==`SUBF_IMM || ir12==`SUBW_IMM ||
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
					(store_what==`SW_G0) ||
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
					(load_what==`LW_ACCA && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_ACCB && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_ACCE && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_ACCF && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_DPRL && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_XL && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_YL && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_USPL && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_SSPL && !(isRTI || isJTT || isPULU || isPULS)) ||
					(load_what==`LW_B0) ||
					(load_what==`LW_PCL) ||
					(load_what==`LW_IAL && !isOuterIndexed && isLEA) ||
					(load_what==`LW_IA3124 && radr[1:0]==2'b00 && !isOuterIndexed && isLEA)
				)
				;

wire lock_bus = load_what==`LW_XH || load_what==`LW_YH || load_what==`LW_USPH || load_what==`LW_SSPH ||
				load_what==`LW_PCH || load_what==`LW_BH || load_what==`LW_IAH || load_what==`LW_PC2316 ||
				load_what==`LW_IA2316 || load_what==`LW_B2316 || 
				load_what==`LW_X2316 || load_what==`LW_Y2316 || load_what==`LW_USP2316 || load_what==`LW_SSP2316 ||
				load_what==`LW_B10 ||
				isRMW ||
				store_what==`SW_ACCDH || store_what==`SW_XH || store_what==`SW_YH || store_what==`SW_USPH || store_what==`SW_SSPH ||
				store_what==`SW_PCH || store_what==`SW_PC2316 || store_what==`SW_ACCQ2316 ||
				store_what==`SW_X2316 || store_what==`SW_Y2316 || store_what==`SW_USP2316 || store_what==`SW_SSP2316 ||
				store_what==`SW_G10
				;

wire isPrefix = ir12==`PG2 || ir12==`PG3 || ir12==`OUTER;

reg rty;
reg [5:0] waitcnt;
reg [3:0] iccnt;
reg [bitsPerByte-1:0] icbuf [0:15];
reg [bitsPerByte*16-1:0] icbuf2;
reg [15:0] outstanding;	// Outstanding async read cycles.
integer n4;

rf6809_icachemem u1
(
	.wclk(clk_i),
	.wce(1'b1),
	.wr(state==ICACHE6),
	.wa(icwa[11:0]),
	.i(icbuf2),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc[11:0]),
	.insn(insn)
);
	
rf6809_itagmem u2
(
	.wclk(clk_i),
	.wce(1'b1),
	.wr(state==ICACHE6),
	.wa(icwa[`TRPBYTE]),
	.invalidate(ic_invalidate),
	.rclk(~clk_i),
	.rce(1'b1),
	.pc(pc),
	.hit0(hit0),
	.hit1(hit1)
);

wire bcdaddbcf, bcdsuubbcf,bcdaddcf,bcdsubcf,bcdnegcf,bcdnegbcf;
wire [bitsPerByte-1:0] bcdaddbo, bcdsubbo, bcdnegbo;
wire [bitsPerByte*2-1:0] bcdaddo, bcdsubo, bcdnego;
wire [31:0] bcdmulo;

`ifdef SUPPORT_BCD
BCDAddN #(.N(3)) ubcda1 (
	.ci(isAdc ? cf : 1'b0),
	.a(acc),
	.b(b12),
	.o(bcdaddbo),
	.co(bcdaddbcf)
);

BCDAddN #(.N(6)) ubcda2 (
	.ci(isAdc ? cf : 1'b0),
	.a({acca,accb}),
	.b(b),
	.o(bcdaddo),
	.co(bcdaddcf)
);

BCDSubN #(.N(3)) ubcds1 (
	.ci(isSbc ? cf : 1'b0),
	.a(acc),
	.b(b12),
	.o(bcdsubbo),
	.co(bcdsubbcf)
);

BCDSubN #(.N(6)) ubcds2 (
	.ci(isSbc ? cf : 1'b0),
	.a({acca,accb}),
	.b(b),
	.o(bcdsubo),
	.co(bcdsubcf)
);

BCDSubN #(.N(3)) ubcds3 (
	.ci(1'b0),
	.a(12'h0),
	.b(acc),
	.o(bcdnegbo),
	.co(bcdnegbcf)
);

BCDSubN #(.N(6)) ubcds4 (
	.ci(1'b0),
	.a(12'h0),
	.b({acca,accb}),
	.o(bcdnego),
	.co(bcdnegcf)
);

BCDMul4 ubcdmul1
(
	.a({4'h0,acca}),
	.b({4'h0,accb}),
	.o(bcdmulo)
);
`endif

reg [bitsPerByte*2-1:0] bcdmul_res [0:15];
reg [bitsPerByte*2-1:0] bcdmul_res16;
genvar g5;
generate begin : gBCDMulPipe
	always_ff @(posedge clk_i)
		bcdmul_res[0] <= bcdmulo[23:0];
	always_ff @(posedge clk_i)
		bcdmul_res16 <= muld_res[15];
	for (g5 = 1; g5 < 16; g5 = g5 + 1)
		always_ff @(posedge clk_i)
			bcdmul_res[g5] = bcdmul_res[g5-1];
end
endgenerate

// Multiplier logic
wire signed [`QUADBYTE] muld_prod = $signed({acca,accb}) * $signed(b[`DBLBYTE]);
reg [`QUADBYTE] muld_res [0:15];
reg [`QUADBYTE] muld_res6;
genvar g4;
generate begin : gMulPipe
	always_ff @(posedge clk_i)
		muld_res[0] <= muld_prod;
	always_ff @(posedge clk_i)
		muld_res6 <= muld_res[5];
	for (g4 = 1; g4 < 6; g4 = g4 + 1)
		always_ff @(posedge clk_i)
			muld_res[g4] = muld_res[g4-1];
end
endgenerate

// Divider logic
reg [5:0] divcnt;
/*
reg divsign;
reg [`DBLBYTE] dividend;
// Table of positive constants 1/0 to 1/2047, accurate to 35 bits
reg [26:0] divtbl [0:2047];	
genvar g2;
generate begin: gDivtbl
	for (g2 = 0; g2 < 2048; g2 = g2 + 1)
	initial begin
		divtbl[g2] = 27'h4000000 / g2;
	end
end
endgenerate
reg [49:0] divres;
always_comb
	divres = ({36'd0,dividend} * divtbl[b12]);
reg [11:0] divrem;
always_comb
	divrem = dividend - divres[49:26] * b12;
// Now create an 12-stage divider pipeline. Hopefully the synthesizer
// will backfill along this pipeline. Each multiplier requires only
// about 5 stages for best performance.
genvar g1;
reg [49:0] divrespipe [0:31];
reg [11:0] divrempipe [0:31];
reg [49:0] divres12;
reg [11:0] divrem12;
generate begin : gDivPipe
	always_ff @(posedge clk_i)
		divrespipe[0] <= divres;
	always_ff @(posedge clk_i)
		divrempipe[0] <= divrem;
	always_ff @(posedge clk_i)
		divres12 <= divrespipe[12];
	always_ff @(posedge clk_i)
		divrem12 <= divrempipe[12];
	for (g1 = 1; g1 < 13; g1 = g1 + 1)
	always_ff @(posedge clk_i) begin
		divrespipe[g1] <= divrespipe[g1-1];
		divrempipe[g1] <= divrempipe[g1-1];
	end
end
endgenerate
*/
wire [23:0] divres24;
wire [15:0] divrem12;
wire [47:0] divres48;
wire [23:0] divrem24;
wire [15:0] divres16;
wire [7:0] divrem8;
wire [31:0] divres32;
wire [15:0] divrem16;

`ifdef SUPPORT_6309
`ifdef SUPPORT_DIVIDE
generate begin : gDividers
	if (bitsPerByte==12) begin
		div24by12 udiv24by12 (
		  .aclk(clk_i),                                      // input wire aclk
		  .s_axis_divisor_tvalid(1'b1),    // input wire s_axis_divisor_tvalid
		  .s_axis_divisor_tdata({4'h0,b12}),      // input wire [15 : 0] s_axis_divisor_tdata
		  .s_axis_dividend_tvalid(1'b1),  // input wire s_axis_dividend_tvalid
		  .s_axis_dividend_tdata({acca,accb}),    // input wire [23 : 0] s_axis_dividend_tdata
		  .m_axis_dout_tvalid(),          // output wire m_axis_dout_tvalid
		  .m_axis_dout_tuser(),            // output wire [0 : 0] m_axis_dout_tuser
		  .m_axis_dout_tdata({divres24,divrem12})            // output wire [39 : 0] m_axis_dout_tdata
		);

		div48by24 udiv48by24 (
		  .aclk(clk_i),                                      // input wire aclk
		  .s_axis_divisor_tvalid(1'b1),    // input wire s_axis_divisor_tvalid
		  .s_axis_divisor_tdata(b),      // input wire [23 : 0] s_axis_divisor_tdata
		  .s_axis_dividend_tvalid(1'b1),  // input wire s_axis_dividend_tvalid
		  .s_axis_dividend_tdata({acca,accb,acce,accf}),    // input wire [47 : 0] s_axis_dividend_tdata
		  .m_axis_dout_tvalid(),          // output wire m_axis_dout_tvalid
		  .m_axis_dout_tuser(),            // output wire [0 : 0] m_axis_dout_tuser
		  .m_axis_dout_tdata({divres48,divrem24})            // output wire [71 : 0] m_axis_dout_tdata
		);
	end
end
endgenerate
`endif
`endif

wire [127:0] dfaso;
// takes about 25 clocks (27 to be safe)
DFPAddsub128nr udfa1
(
	.clk(clk_i),
	.ce(1'b1),
	.rm(3'd0),
	.op(isDFSub),
	.a(accg),
	.b(b),
	.o(dfaso)
);

wire [127:0] dfmo;
wire dfm_done;
wire dfm_vf;
DFPMultiply128nr udfm1
(
	.clk(clk_i),
	.ce(1'b1),
	.ld(state==CALC),
	.a(accg),
	.b(b),
	.o(dfmo),
	.rm(3'd0),
	.sign_exe(),
	.inf(),
	.overflow(dfm_vf),
	.underflow(),
	.done(dfm_done)
);

wire dfd_done;
wire [127:0] dfdo;
wire dfd_vf;
DFPDivide128nr udfd1
(
	.rst(rst_i),
	.clk(clk_i),
	.ce(1'b1),
	.ld(state==CALC),
	.op(),
	.a(accg),
	.b(b),
	.o(dfdo),
	.rm(3'd0),
	.done(dfd_done),
	.sign_exe(),
	.inf(),
	.overflow(dfd_vf),
	.underflow()
);

wire [11:0] dfco;
DFPCompare128 udfc1(
	.a(accg),
	.b(b),
	.o(dfco)
);

// For asynchronous reads,
// The read response might come back in any order (the packets could loop
// around in the network.
// We need to buffer and reorder the response correctly.

integer n3;
always_ff @(posedge clk_i)
if (rst_i) begin
	icgot <= 16'h0;
	for (n3 = 0; n3 < 16; n3 = n3 + 1)
		icbuf[n3] <= {bitsPerByte{1'b0}};
end
else begin
	if (state==ICACHE1)
		icgot <= 16'h0;
`ifdef SUPPORT_AREAD
	if (aack_i) begin
		icgot[atag_i] <= 1'b1;
		icbuf[atag_i] <= dati;
	end
`else
	if (ack_i) begin
		icgot[adr_o[3:0]] <= 1'b1;
		icbuf[adr_o[3:0]] <= dati;
	end
`endif
end

genvar g3;
generate begin : gIcin
for (g3 = 0; g3 < 16; g3 = g3 + 1)
	always_comb
		icbuf2[(g3+1)*bitsPerByte-1:g3*bitsPerByte] <= icbuf[g3];
end
endgenerate

// Bus timeout counter
always_ff @(posedge clk_i)
if (rst_i) begin
	btocnt <= 24'd0;
end
else begin
	if (cyc_o & stb_o)
		btocnt <= btocnt + 2'd1;
	else
		btocnt <= 24'd0;
end
always_comb
	bto = btocnt >= 24'd10000;

// Count  milliseconds
// Based on a count determined by the clock frequency
// 40MHz is assumed.
reg [23:0] ns_count;	// The counter to get to 1ms
reg [35:0] ms_count;	// Count of number of milliseconds

always_ff @(posedge clk_i)
if (rst_i) begin
	ns_count <= 16'd0;
	ms_count <= 36'd0;
end
else begin
	ns_count <= ns_count + 2'd1;
	if (ns_count>=24'd40000) begin
		ns_count <= 24'h0;
		ms_count <= ms_count + 2'd1;
	end
end

`ifdef SUPPORT_CHECKPOINT
always_ff @(posedge clk_i)
if (rst_i)
	chkpoint <= 12'h000;
else begin
	if (ns_count==16'd40000) begin
		if (ms_count[9:0]==10'h3FF)
			chkpoint <= 12'hFFF;
	end
	if (state==STORE1 && (wadr=={{BPB*3-8{1'b1}},8'hE1}))
		chkpoint <= 12'h000;
end
`endif

always_ff @(posedge clk_i)
	tsc_latched <= tsc_i;

always_ff @(posedge clk_i)
	nmi1 <= iplMd ? &{nmi_i,firq_i,irq_i} : nmi_i;
always_ff @(posedge clk_i)
`ifdef SUPPORT_CHECKPOINT
	if (ms_count[9:0]==10'h3FF && chkpoint!=12'h000)
		nmi_edge <= 1'b1;
	else 
`endif
	if ((iplMd ? &{nmi_i,firq_i,irq_i} : nmi_i) & !nmi1)
		nmi_edge <= 1'b1;
	else if (state==DECODE && ir12==`INT)
		nmi_edge <= 1'b0;

reg [11:0] rst_cnt;

always @(posedge clk_i)
if (rst_i) begin
	wb_nack();
	tr <= 'd0;
	pcr_o <= 'h0;
	natMd <= 1'b0;
	firqMd <= 1'b0;
	iplMd <= 1'b0;
	df <= 1'b1;
	rty <= `FALSE;
	rst_cnt <= {id,4'd0};
	next_state(RESET);
	sync_state <= `FALSE;
	wait_state <= `FALSE;
	md32 <= `FALSE;
	ipg <= 2'b00;
	isFar <= `FALSE;
	isSWI2 <= `FALSE;
	isSYS <= FALSE;
`ifdef EIGHTBIT
	isOuterIndexed <= `FALSE;
`endif
	dpr <= 'h0;
	stkbnk <= 'h0;
	icl_o <= `FALSE;
	ibufadr <= {BPB*3{1'b0}};
//	pc <= 24'hFFFFFE;
	pc <= {{BPB*3-1{1'b1}},1'b0};	// FF...FE
	ir <= {4{`NOP}};
	ibuf <= {4{`NOP}};
	dm <= 1'b0;
	im <= 1'b1;
	im1 <= 1'b1;
	firqim <= 1'b1;
	nmi_armed <= `FALSE;
	ic_invalidate <= `TRUE;
	first_ifetch <= `TRUE;
	acca <= 12'h0;
	accb <= 12'h0;
	accd <= 24'h0;
`ifdef SUPPORT_6309
	accw <= 24'h0;
`endif
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
	outstanding <= 16'h0;
	iccnt <= 4'h0;
	//dividend <= 'b0;
	divcnt <= 'b0;
	//divsign <= 'b0;
	rdyq_ins <= 1'b0;
	rdyq_pop <= 1'b0;
	rdyq_peek <= 1'b0;
	tcb_base <= 24'h10000;
end
else begin

rdyq_ins <= 1'b0;
rdyq_pop <= 1'b0;

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
		load_what <= `LW_PC3124;
		next_state(LOAD1);
	end
	else
		rst_cnt <= rst_cnt - 2'd1;

IFETCH:
	begin
		tIfetch();
		tWriteback();
	end
DECODE:	tDecode();
LOAD1:	tLoad1();
LOAD2:	tLoad2();
CALC:		tExecute();
STORE1:	tStore1();
STORE1a:	tStore1a();
STORE2:	tStore2();

// ============================================================================
// ============================================================================
DFMUL1:
	begin
		next_state(IFETCH);
		if (dfm_done) begin
			df <= 1'b1;
			case(ir[`LOBYTE])
			`MULG_DP:	pc <= pc + 2'd2;
			`MULG_NDX:	pc <= pc + insnsz;
			`MULG_EXT:	pc <= pc + (isFar ? 3'd4 : 3'd3);
			default:	pc <= pc + 2'd1;
			endcase
		end
	end
DFDIV1:
	begin
		next_state(IFETCH);
		if (dfd_done) begin
			df <= 1'b1;
			case(ir[`LOBYTE])
			`DIVG_DP:	pc <= pc + 2'd2;
			`DIVG_NDX:	pc <= pc + insnsz;
			`DIVG_EXT:	pc <= pc + (isFar ? 3'd4 : 3'd3);
			default:	pc <= pc + 2'd1;
			endcase
		end
	end
MUL2:
	if (divcnt != 6'd0)
		divcnt <= divcnt - 2'd1;
	else
		next_state(IFETCH);
DIV1:
	begin
		/*
		divsign <= acca[bitsPerByte-1] ^ b12[bitsPerByte-1];
		if (acca[bitsPerByte-1])
			dividend <= -{acca,accb};
		else
			dividend <= {acca,accb};
		if (b12[bitsPerByte-1])
			b <= -b;
		*/
		case(ir12)
		`DIVD_IMM,`DIVD_DP,`DIVD_NDX,`DIVD_EXT:
			divcnt <= 6'd28;
		`DIVQ_IMM,`DIVQ_DP,`DIVQ_NDX,`DIVQ_EXT:
			divcnt <= 6'd52;
		endcase
		next_state(DIV2);
	end
DIV2:
	if (divcnt != 6'd0)
		divcnt <= divcnt - 2'd1;
	else
		next_state(DIV3);
DIV3:
	begin
		res[`LOBYTE] <= divres24[`BYTE1];
		res[`HIBYTE] <= divrem12;
		vf <= divres24[`BYTE2] != {bitsPerByte{divres24[bitsPerByte-1]}};
		next_state(IFETCH);
	end

// ============================================================================
// ============================================================================
PUSH1:
	begin
		next_state(PUSH2);
		if (isSYS)
			wadr <= tcb_base + {tr,8'd32};
		else if (isINT | isPSHS) begin
			wadr <= {stkbnk,ssp} - cnt;
			ssp <= (ssp - cnt);
		end
		else begin	// PSHU
			wadr <= {stkbnk,usp} - cnt;
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
`ifdef SUPPORT_6309
		else if (ir[bitsPerByte+8]) begin
			store_what <= `SW_ACCE;
			ir[bitsPerByte+8] <= 1'b0;
		end
		else if (ir[bitsPerByte+9]) begin
			store_what <= `SW_ACCF;
			ir[bitsPerByte+9] <= 1'b0;
		end
`endif
		else if (ir[bitsPerByte+3]) begin
			store_what <= bitsPerByte==8 ? `SW_DPRL : `SW_DPRH;
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
		else if (ir[bitsPerByte+10]) begin
			store_what <= `SW_SSPH;
			ir[bitsPerByte+10] <= 1'b0;
		end
		else if (ir[bitsPerByte+7]) begin
			store_what <= isFar ? `SW_PC2316 : `SW_PCH;
			ir[bitsPerByte+7] <= 1'b0;
		end
		else begin
			if (isINT) begin
				if (vect==`SWI_VECT) begin
					im1 <= 1'b1;
					firqim <= 1'b1;
					im <= 1'b1;
				end
				dm <= 1'b0;
				radr <= vect;
				if (vec_i != 24'h0) begin
					$display("vector: %h", vec_i);
					pc <= vec_i;
					next_state(IFETCH);
				end
				else begin
					//pc[`BYTE3] <= 8'h00;
					load_what <= `LW_PC3124;
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
`ifdef SUPPORT_6309
		else if (ir[bitsPerByte+8]) begin
			load_what <= `LW_ACCE;
			ir[bitsPerByte+8] <= 1'b0;
		end
		else if (ir[bitsPerByte+9]) begin
			load_what <= `LW_ACCF;
			ir[bitsPerByte+9] <= 1'b0;
		end
`endif
		else if (ir[bitsPerByte+3]) begin
			load_what <= bitsPerByte==8 ? `LW_DPRL : `LW_DPRH;
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
		else if (ir[bitsPerByte+10]) begin
			load_what <= `LW_SSPH;
			ir[bitsPerByte+10] <= 1'b0;
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
			casez(ndxbyte)
			8'b0???????:	radr <= radr + ndxreg;
			8'b1???0000:
							begin
								radr <= radr + ndxreg;
								case(ndxbyte[6:5])
								2'b00:	xr <= (xr + 2'd1);
								2'b01:	yr <= (yr + 2'd1);
								2'b10:	usp <= (usp + 2'd1);
								2'b11:	ssp <= (ssp + 2'd1);
								endcase
							end
			8'b1???0001:	begin
								radr <= radr + ndxreg;
								case(ndxbyte[6:5])
								2'b00:	xr <= (xr + 2'd2);
								2'b01:	yr <= (yr + 2'd2);
								2'b10:	usp <= (usp + 2'd2);
								2'b11:	ssp <= (ssp + 2'd2);
								endcase
							end
			8'b1???0010:	radr <= radr + ndxreg;
			8'b1???0011:	radr <= radr + ndxreg;
			8'b1???0100:	radr <= radr + ndxreg;
			8'b1???0101:	radr <= radr + ndxreg;
			8'b1???0110:	radr <= radr + ndxreg;
			8'b1???1000:	radr <= radr + ndxreg;
			8'b1???1001:	radr <= radr + ndxreg;
			8'b1???1010:	radr <= radr + ndxreg;
			8'b1???1011:	radr <= radr + ndxreg;
			default:	radr <= radr;
			endcase
		end
		else if (bitsPerByte==12) begin
			casez(ndxbyte)
			12'b0???????????:	radr <= radr + ndxreg;
			12'b1????0000000:
							begin
								radr <= radr + ndxreg;
								case(ndxbyte[10:9])
								2'b00:	xr <= (xr + 2'd1);
								2'b01:	yr <= (yr + 2'd1);
								2'b10:	usp <= (usp + 2'd1);
								2'b11:	ssp <= (ssp + 2'd1);
								endcase
							end
			12'b1????0000001:	begin
								radr <= radr + ndxreg;
								case(ndxbyte[10:9])
								2'b00:	xr <= (xr + 2'd2);
								2'b01:	yr <= (yr + 2'd2);
								2'b10:	usp <= (usp + 2'd2);
								2'b11:	ssp <= (ssp + 2'd2);
								endcase
							end
			12'b1????0000010:	radr <= radr + ndxreg;
			12'b1????0000011:	radr <= radr + ndxreg;
			12'b1????0000100:	radr <= radr + ndxreg;
			12'b1????00?0101:	radr <= radr + ndxreg;
			12'b1????00?0110:	radr <= radr + ndxreg;
			12'b1????0001000:	radr <= radr + ndxreg;
			12'b1????0001001:	radr <= radr + ndxreg;
			12'b1????0001010:	radr <= radr + ndxreg;
			12'b1????00?1011:	radr <= radr + ndxreg;
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
		iccnt <= 4'h0;
		outstanding <= 16'h0;
		if (hit0 & hit1)
			next_state(IFETCH);
		else if (!tsc && !ack_i) begin
			rhit0 <= hit0;
			icl_o <= 1'b1;
			bte_o <= 2'b00;
			cti_o <= 3'b001;
			cyc_o <= 1'b1;
			bl_o <= 6'd15;
			stb_o <= 1'b1;
			we_o <= 1'b0;
			adr_o <= !hit0 ? {pc[bitsPerByte*3-1:4],4'b00} : {pcp16[bitsPerByte*3-1:4],4'b0000};
			next_state(ICACHE2);
		end
	end
// If tsc is asserted during an instruction cache fetch, then abort the fetch
// cycle, and wait until tsc deactivates.
// The instruction cache uses asynchronous reading through the network for
// better performance. The read request and the read response are two
// separate things.
ICACHE2:
`ifdef SUPPORT_AREAD
	if (tsc) begin
		wb_nack();
		next_state(ICACHE3);
	end
	else if (ack_i|rty_i|bto) begin
		stb_o <= 1'b0;
		iccnt <= iccnt + 2'd1;
		next_state(ICACHE4);
		if (iccnt==4'b1110)
			cti_o <= 3'b111;
		if (iccnt==4'b1111) begin
			icwa <= adr_o;
			wb_nack();
			next_state(ICACHE5);
		end
	end
`else
	if (tsc|rty_i) begin
		wb_nack();
		next_state(ICACHE3);
	end
	else if (ack_i) begin
		stb_o <= 1'b0;
		iccnt <= iccnt + 2'd1;
		next_state(ICACHE4);
		if (iccnt==4'b1110)
			cti_o <= 3'b111;
		if (iccnt==4'b1111) begin
			icwa <= adr_o;
			wb_nack();
			next_state(ICACHE6);
		end
	end
`endif

ICACHE4:
	if (!ack_i) begin
		adr_o[3:0] <= iccnt;
		stb_o <= 1'b1;
		next_state(ICACHE2);
	end

ICACHE6:
	begin
		icl_o <= 1'b0;
		next_state(ICACHE1);
	end

// The following states to handle outstanding transfers.
// The transfer might retry several times if it has not registered.
`ifdef SUPPORT_AREAD
ICACHE5:
	// Line loaded?
	if (icgot == 16'hFFFF)
		next_state(ICACHE6);
	else begin
		waitcnt <= 6'd20;
		next_state(ICACHE7);
	end
ICACHE7:
	if (waitcnt==6'd0) begin
		next_state(ICACHE5);
		adr_o <= icwa;
		for (n4 = 15; n4 >= 0; n4 = n4 - 1)
			if (~icgot[n4]) begin// & ~outstanding[n4]) begin
				cti_o <= 3'b001;
				cyc_o <= `TRUE;
				stb_o <= `TRUE;
				adr_o[3:0] <= n4[3:0];
				outstanding[n4[3:0]] <= 1'b1;
				next_state(ICACHE9);
			end
	end
	else
		waitcnt <= waitcnt - 2'd1;
ICACHE9:
	begin
		if (bto)
			outstanding <= 16'h0;
		if (aack_i)
			outstanding[atag_i] <= 1'b0;
		if (ack_i|rty_i|bto) begin
			wb_nack();
			waitcnt <= 6'd20;
			next_state(ICACHE7);
		end
	end
`endif

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
		next_state(ICACHE2);
	end

`ifdef SUPPORT_IBUF
IBUF1:
	if (!tsc) begin
		bte_o <= 2'b00;
		cti_o <= 3'b001;
		cyc_o <= 1'b1;
		bl_o <= 6'd2;
		stb_o <= 1'b1;
		we_o <= 1'b0;
		adr_o <= pc[`DBLBYTE];
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
`endif

endcase
end

// ============================================================================
// ============================================================================
// Supporting Tasks
// ============================================================================
// ============================================================================

// ============================================================================
// IFETCH
//
// Fetch instructions.
// ============================================================================

task tIfetch;
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
		isSWI2 <= `FALSE;
		isSYS <= `FALSE;
`ifdef EIGHTBIT
		isOuterIndexed <= `FALSE;
`endif
		ipg <= 2'b00;
		ia <= {bitsPerByte*3{1'b0}};
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
	/*
		else if (exv_i && !sync_state) begin
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `EXV_VECT;
		end
		else if (wrv_i && !sync_state) begin
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `WRV_VECT;
		end
		else if (rdv_i && !sync_state) begin
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `RDV_VECT;
		end
	*/
		else if ({nmi_i,firq_i,irq_i} > {im1,firqim,im} && !sync_state && iplMd) begin
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			case({nmi_i,firq_i,irq_i})
			3'd1:	vect <= `IRQ_VECT;
			3'd2:	vect <= `FIRQ_VECT;
			3'd7: vect <= `NMI_VECT;
			default:	vect <= `DBG_VECT | {nmi_i,firq_i,irq_i,1'b0};
			endcase
		end
		else if (firq_i & !firqim & !sync_state) begin
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `FIRQ_VECT;
		end
		else if (irq_i & !im & !sync_state) begin
			$display("**************************************");
			$display("****** Interrupt *********************");
			$display("**************************************");
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `IRQ_VECT;
		end
`ifdef SUPPORT_DEBUG_REG
		// Check for instruction breakpoint hit.
		else if (brkctrl[0].en && brkctrl[0].match_type==BMT_IA && (pc & {{20{1'b1}},brkctrl[0].amask})==brkad[0]) begin
			brkctrl[0].hit <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `DBG_VECT;
		end
		else if (brkctrl[1].en && brkctrl[1].match_type==BMT_IA && (pc & {{20{1'b1}},brkctrl[1].amask})==brkad[1]) begin
			brkctrl[1].hit <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `DBG_VECT;
		end
		else if (brkctrl[2].en && brkctrl[2].match_type==BMT_IA && (pc & {{20{1'b1}},brkctrl[2].amask})==brkad[2]) begin
			brkctrl[2].hit <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `DBG_VECT;
		end
		else if (brkctrl[3].en && brkctrl[3].match_type==BMT_IA && (pc & {{20{1'b1}},brkctrl[3].amask})==brkad[3]) begin
			brkctrl[3].hit <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `DBG_VECT;
		end
`endif
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
`ifdef EIGHTBIT					
					isOuterIndexed <= isOuterIndexed;
`endif					
					next_state(ICACHE1);
				end
			end
`ifdef SUPPORT_IBUF				
			else begin
				if (ibufhit)
					ir <= ibuf;
				else begin
					ipg <= ipg;
					isFar <= isFar;
`ifdef EIGHTBIT					
					isOuterIndexed <= isOuterIndexed;
`endif					
					next_state(IBUF1);
				end
			end
`endif				
		end
	end
end
endtask

// ============================================================================
// DECODE
//
// Decode instruction and fetch register file values.
// ============================================================================

task tDecode;
begin
	first_ifetch <= `TRUE;
	next_state(IFETCH);		// default: move to IFETCH
	pc <= pc + 2'd1;		// default: increment PC by one
	a <= 24'd0;
	b <= 24'd0;
	ia <= {bitsPerByte * 3{1'b0}};
	isDblIndirect <= `FALSE;//ndxbyte[11:4]==8'h8F;
	if (isIndexed) begin
		if (bitsPerByte==8) begin
			casez(ndxbyte)
			8'b1??00000:	
				if (!isOuterIndexed)
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr + 4'd1);
					2'b01:	yr <= (yr + 4'd1);
					2'b10:	usp <= (usp + 4'd1);
					2'b11:	ssp <= (ssp + 4'd1);
					endcase
			8'b1??00001:
				if (!isOuterIndexed)
					case(ndxbyte[6:5])
					2'b00:	xr <= (xr + 4'd2);
					2'b01:	yr <= (yr + 4'd2);
					2'b10:	usp <= (usp + 4'd2);
					2'b11:	ssp <= (ssp + 4'd2);
					endcase
			8'b1??00010:
				case(ndxbyte[6:5])
				2'b00:	xr <= (xr - 2'd1);
				2'b01:	yr <= (yr - 2'd1);
				2'b10:	usp <= (usp - 2'd1);
				2'b11:	ssp <= (ssp - 2'd1);
				endcase
			8'b1??00011:
				case(ndxbyte[6:5])
				2'b00:	xr <= (xr - 2'd2);
				2'b01:	yr <= (yr - 2'd2);
				2'b10:	usp <= (usp - 2'd2);
				2'b11:	ssp <= (ssp - 2'd2);
				endcase
			endcase
		end
		else if (bitsPerByte==12) begin
			casez(ndxbyte)
			12'b1??000000000:	
				if (!isOuterIndexed && ndxbyte[bitsPerByte-5]==1'b0)
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr + 4'd1);
					2'b01:	yr <= (yr + 4'd1);
					2'b10:	usp <= (usp + 4'd1);
					2'b11:	ssp <= (ssp + 4'd1);
					endcase
			12'b1??000000001:
				if (!isOuterIndexed && ndxbyte[bitsPerByte-5]==1'b0)
					case(ndxbyte[10:9])
					2'b00:	xr <= (xr + 4'd2);
					2'b01:	yr <= (yr + 4'd2);
					2'b10:	usp <= (usp + 4'd2);
					2'b11:	ssp <= (ssp + 4'd2);
					endcase
			12'b1??0?0000010:
				case(ndxbyte[10:9])
				2'b00:	xr <= (xr - 2'd1);
				2'b01:	yr <= (yr - 2'd1);
				2'b10:	usp <= (usp - 2'd1);
				2'b11:	ssp <= (ssp - 2'd1);
				endcase
			12'b1??0?0000011:
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
			dm <= dm | ir[bitsPerByte+8];
			im1 <= im1 | ir[bitsPerByte+9];
			df <= df | ir[bitsPerByte+10];
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
			dm <= dm & ir[bitsPerByte+8];
			im1 <= im1 & ir[bitsPerByte+9];
			df <= df & ir[bitsPerByte+10];
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
			dm <= dm & ir[bitsPerByte+8];
			im1 <= im1 & ir[bitsPerByte+9];
			df <= df & ir[bitsPerByte+10];
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
			iplMd <= ir[bitsPerByte+2];
			pc <= pc + 2'd2;
			end
	`BITMD:
		begin
			res <= {dbz,iop,3'd0,iplMd,firqMd,natMd} & ir[`BYTE2];
			if (ir[bitsPerByte+7])
				dbz <= 1'b0;
			if (ir[bitsPerByte+6])
				iop <= 1'b0;
			pc <= pc + 2'd2;
		end
	`TFR:	pc <= pc + 2'd2;
	`EXG:	pc <= pc + 2'd2;
	`ABX:	res <= xr + accb;
	`SEX: res <= {{bitsPerByte{accb[BPBM1]}},accb[`LOBYTE]};
	`PG2:	begin ipg <= 2'b01; ir <= ir[bitsPerByte*8-1:bitsPerByte]; next_state(DECODE); end
	`PG3:	begin ipg <= 2'b10; ir <= ir[bitsPerByte*8-1:bitsPerByte]; next_state(DECODE); end
	`FAR:	begin isFar <= `TRUE;  ir <= ir[bitsPerByte*8-1:bitsPerByte]; next_state(DECODE); end
`ifdef EIGHTBIT
	`OUTER:	begin isOuterIndexed <= `TRUE;  ir <= ir[bitsPerByte*8-1:bitsPerByte]; next_state(DECODE); end
`endif
	`NEGA,`NEGB:	
		if (dm) begin
			a <= 'b0; b <= acc;
			next_state(CALC);
		end
		else begin res12 <= -acc[`LOBYTE]; a <= 24'h00; b <= acc; end
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
	`MUL:	if (dm) begin divcnt <= 6'd17; next_state(MUL2); end
`ifdef SUPPORT_6309
	`TSTD:	res <= {acca,accb};
	`TSTW:	res <= {acce,accf};
	`TSTE:	res12 <= acce;
	`TSTF:	res12 <= accf;
	`NEGD:	
		if (dm) begin
			a <= 'd0; b <= {acca,accb};
			next_state(CALC);
		end
		else begin res <= -{acca,accb}; a <= 'd0; b <= {acca,accb}; end
	`NEGG:	begin accg[127] <= ~accg[127]; b[127] <= ~accg[127]; b[126:0] <= accg[126:0]; end
	`TSTG:	begin b[127] <= accg[127]; b[126:0] <= accg[126:0]; end
	`INCE,`INCF:	begin res12 <= acc[`LOBYTE] + 2'd1; end
	`INCD:	res <= {acca,accb} + 2'd1;
	`INCW:	res <= {acce,accf} + 2'd1;
	`DECE,`DECF:	begin res12 <= acc[`LOBYTE] - 2'd1; end
	`DECD:	res <= {acca,accb} - 2'd1;
	`DECW:	res <= {acce,accf} - 2'd1;
	`COMD:	res <= ~{acca,accb};
	`COME,`COMF:	res <= ~acc[`LOBYTE];
	`COMW:	res <= ~{acce,accf};
	`CLRD:	res <= 'b0;
	`CLRG:	begin accg <= 'd0; b <= 'd0; end
	`CLRW:	res <= 'b0;
	`CLRE:	res12 <= 'b0;
	`CLRF:	res12 <= 'b0;
	`ASLD:	
		res <= {acca,accb,1'b0};
	`ASRD:
		res <= {accb[0],acca[bitsPerByte-1],acca,accb[bitsPerByte-1:1]};
	`LSRD:	
		res <= {accb[0],acca,accb[bitsPerByte-1:1]};
	`LSRW:	
		res <= {accf[0],accw,accf[bitsPerByte-1:1]};
	`ROLD:	
		res <= {acca,accb,cf};
	`ROLW:	
		res <= {acce,accf,cf};
	`RORD:	
		res <= {accb[0],cf,acca,accb[bitsPerByte-1:1]};
	`RORW:	
		res <= {accf[0],cf,acce,accf[bitsPerByte-1:1]};
	`ADDR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b0001:	begin xr <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b0010:	begin yr <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b0011:	begin usp <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b0100:	begin ssp <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b0101:	begin pc <= sum12; nf <= sum12[bitsPerByte*2-1]; zf <= sum12[`DBLBYTE]=='b0; cf <= sum12[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12[bitsPerByte*2-1]); end
			4'b1000:	begin acca <= sum12; nf <= sum12[bitsPerByte-1]; zf <= sum12[`LOBYTE]=='b0; cf <= sum12[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12[bitsPerByte-1]); end
			4'b1001:	begin accb <= sum12; nf <= sum12[bitsPerByte-1]; zf <= sum12[`LOBYTE]=='b0; cf <= sum12[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12[bitsPerByte-1]); end
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
					dm <= sum12[8];
					im1 <= sum12[9];
					df <= sum12[10];
				end
			4'b1011:	begin dpr <= sum12; nf <= sum12[bitsPerByte-1]; zf <= sum12[`LOBYTE]=='b0; cf <= sum12[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12[bitsPerByte-1]); end
			endcase
		end
	`ADCR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b0001:	begin xr <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b0010:	begin yr <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b0011:	begin usp <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b0100:	begin ssp <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b0101:	begin pc <= sum12c; nf <= sum12c[bitsPerByte*2-1]; zf <= sum12c[`DBLBYTE]=='b0; cf <= sum12c[bitsPerByte*2]; vf <= fnAddOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],sum12c[bitsPerByte*2-1]); end
			4'b1000:	begin acca <= sum12c; nf <= sum12c[bitsPerByte-1]; zf <= sum12c[`LOBYTE]=='b0; cf <= sum12c[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12c[bitsPerByte-1]); end
			4'b1001:	begin accb <= sum12c; nf <= sum12c[bitsPerByte-1]; zf <= sum12c[`LOBYTE]=='b0; cf <= sum12c[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12c[bitsPerByte-1]); end
			4'b1010:	
				begin
					cf <= sum12c[0];
					vf <= sum12c[1];
					zf <= sum12c[2];
					nf <= sum12c[3];
					im <= sum12c[4];
					hf <= sum12c[5];
					firqim <= sum12c[6];
					ef <= sum12c[7];
					dm <= sum12c[8];
					im1 <= sum12c[9];
					df <= sum12c[10];
				end
			4'b1011:	begin dpr <= sum12c; nf <= sum12c[bitsPerByte-1]; zf <= sum12c[`LOBYTE]=='b0; cf <= sum12c[bitsPerByte]; vf <= fnAddOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],sum12c[bitsPerByte-1]); end
			endcase
		end
	`ANDR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0001:	begin xr <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0010:	begin yr <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0011:	begin usp <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0100:	begin ssp <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0101:	begin pc <= and12; nf <= and12[bitsPerByte*2-1]; zf <= and12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b1000:	begin acca <= and12; nf <= and12[bitsPerByte-1]; zf <= and12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1001:	begin accb <= and12; nf <= and12[bitsPerByte-1]; zf <= and12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1010:	
				begin
					cf <= and12[0];
					vf <= and12[1];
					zf <= and12[2];
					nf <= and12[3];
					im <= and12[4];
					hf <= and12[5];
					firqim <= and12[6];
					ef <= and12[7];
					dm <= and12[8];
					im1 <= and12[9];
					df <= and12[10];
				end
			4'b1011:	begin dpr <= and12; nf <= and12[bitsPerByte-1]; zf <= and12[`LOBYTE]=='b0; vf <= 1'b0; end
			endcase
		end
	`EORR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0001:	begin xr <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0010:	begin yr <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0011:	begin usp <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0100:	begin ssp <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0101:	begin pc <= eor12; nf <= eor12[bitsPerByte*2-1]; zf <= eor12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b1000:	begin acca <= eor12; nf <= eor12[bitsPerByte-1]; zf <= eor12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1001:	begin accb <= eor12; nf <= eor12[bitsPerByte-1]; zf <= eor12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1010:	
				begin
					cf <= eor12[0];
					vf <= eor12[1];
					zf <= eor12[2];
					nf <= eor12[3];
					im <= eor12[4];
					hf <= eor12[5];
					firqim <= eor12[6];
					ef <= eor12[7];
					dm <= eor12[8];
					im1 <= eor12[9];
					df <= eor12[10];
				end
			4'b1011:	begin dpr <= eor12; nf <= eor12[bitsPerByte-1]; zf <= eor12[`LOBYTE]=='b0; vf <= 1'b0; end
			endcase
		end
	`ORR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0001:	begin xr <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0010:	begin yr <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0011:	begin usp <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0100:	begin ssp <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b0101:	begin pc <= or12; nf <= or12[bitsPerByte*2-1]; zf <= or12[`DBLBYTE]=='b0; vf <= 1'b0; end
			4'b1000:	begin acca <= or12; nf <= or12[bitsPerByte-1]; zf <= or12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1001:	begin accb <= or12; nf <= or12[bitsPerByte-1]; zf <= or12[`LOBYTE]=='b0; vf <= 1'b0; end
			4'b1010:	
				begin
					cf <= or12[0];
					vf <= or12[1];
					zf <= or12[2];
					nf <= or12[3];
					im <= or12[4];
					hf <= or12[5];
					firqim <= or12[6];
					ef <= or12[7];
					dm <= or12[8];
					im1 <= or12[9];
					df <= or12[10];
				end
			4'b1011:	begin dpr <= or12; nf <= or12[bitsPerByte-1]; zf <= or12[`LOBYTE]=='b0; vf <= 1'b0; end
			endcase
		end
	`CMPR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0001:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0010:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0011:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0100:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0101:	begin nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b1000:	begin nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			4'b1001:	begin nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			4'b1010:	;
			4'b1011:	begin nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			endcase
		end
	`SBCR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b0001:	begin xr <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b0010:	begin yr <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b0011:	begin usp <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b0100:	begin ssp <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b0101:	begin pc <= dif12c; nf <= dif12c[bitsPerByte*2-1]; zf <= dif12c[`DBLBYTE]=='b0; cf <= dif12c[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12c[bitsPerByte*2-1]); end
			4'b1000:	begin acca <= dif12c; nf <= dif12c[bitsPerByte-1]; zf <= dif12c[`LOBYTE]=='b0; cf <= dif12c[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12c[bitsPerByte-1]); end
			4'b1001:	begin accb <= dif12c; nf <= dif12c[bitsPerByte-1]; zf <= dif12c[`LOBYTE]=='b0; cf <= dif12c[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12c[bitsPerByte-1]); end
			4'b1010:	
				begin
					cf <= dif12c[0];
					vf <= dif12c[1];
					zf <= dif12c[2];
					nf <= dif12c[3];
					im <= dif12c[4];
					hf <= dif12c[5];
					firqim <= dif12c[6];
					ef <= dif12c[7];
					dm <= dif12c[8];
					im1 <= dif12c[9];
					df <= dif12c[10];
				end
			4'b1011:	begin dpr <= dif12c; nf <= dif12c[bitsPerByte-1]; zf <= dif12c[`LOBYTE]=='b0; cf <= dif12c[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12c[bitsPerByte-1]); end
			endcase
		end
	`SUBR:
		begin
			case(ir[bitsPerByte+3:bitsPerByte])
			4'b0000:	begin {acca,accb} <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0001:	begin xr <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0010:	begin yr <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0011:	begin usp <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0100:	begin ssp <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b0101:	begin pc <= dif12; nf <= dif12[bitsPerByte*2-1]; zf <= dif12[`DBLBYTE]=='b0; cf <= dif12[bitsPerByte*2]; vf <= fnSubOverflow(src1[bitsPerByte*2-1],src2[bitsPerByte*2-1],dif12[bitsPerByte*2-1]); end
			4'b1000:	begin acca <= dif12; nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			4'b1001:	begin accb <= dif12; nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			4'b1010:	
				begin
					cf <= dif12[0];
					vf <= dif12[1];
					zf <= dif12[2];
					nf <= dif12[3];
					im <= dif12[4];
					hf <= dif12[5];
					firqim <= dif12[6];
					ef <= dif12[7];
					dm <= dif12[8];
					im1 <= dif12[9];
					df <= dif12[10];
				end
			4'b1011:	begin dpr <= dif12; nf <= dif12[bitsPerByte-1]; zf <= dif12[`LOBYTE]=='b0; cf <= dif12[bitsPerByte]; vf <= fnSubOverflow(src1[bitsPerByte-1],src2[bitsPerByte-1],dif12[bitsPerByte-1]); end
			endcase
		end
`endif
`ifdef SUPPORT_6309
	`CMPE_IMM,`CMPF_IMM,`SUBE_IMM,`SUBF_IMM:
		begin res12 <= acc[`LOBYTE] - ir[`HIBYTE]; pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`LDE_IMM,`LDF_IMM:
		begin res12 <= ir[`HIBYTE]; pc <= pc + 2'd2; end
`endif
	// Immediate mode instructions
	`SUBA_IMM,`SUBB_IMM,`CMPA_IMM,`CMPB_IMM:
		if (dm) begin pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; next_state(CALC); end
		else begin res12 <= acc[`LOBYTE] - ir[`HIBYTE]; pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`SBCA_IMM,`SBCB_IMM:
		if (dm) begin pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; next_state(CALC); end
		else begin res12 <= acc[`LOBYTE] - ir[`HIBYTE] - cf; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`ANDA_IMM,`ANDB_IMM,`BITA_IMM,`BITB_IMM:
		begin res12 <= acc[`LOBYTE] & ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`LDA_IMM,`LDB_IMM:
		begin res12 <= ir[`HIBYTE]; pc <= pc + 2'd2; end
	`EORA_IMM,`EORB_IMM:
		begin res12 <= acc[`LOBYTE] ^ ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`ADCA_IMM,`ADCB_IMM:
		if (dm) begin pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; next_state(CALC); end
		else begin res12 <= acc[`LOBYTE] + ir[`HIBYTE] + cf; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`ORA_IMM,`ORB_IMM:
		begin res12 <= acc[`LOBYTE] | ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
	`ADDA_IMM,`ADDB_IMM:
		if (dm) begin pc <= pc + 4'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; next_state(CALC); end
		else begin res12 <= acc[`LOBYTE] + ir[`HIBYTE]; pc <= pc + 2'd2; a <= acc[`LOBYTE]; b <= ir[`HIBYTE]; end
`ifdef SUPPORT_6309
	`BITD_IMM,
	`ANDD_IMM:
			begin
				res <= {acca[`LOBYTE],accb[`LOBYTE]} & {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
			end
	`EORD_IMM:
			begin
				res <= {acca[`LOBYTE],accb[`LOBYTE]} ^ {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
			end
	`ORD_IMM:
			begin
				res <= {acca[`LOBYTE],accb[`LOBYTE]} | {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
			end
`endif
	`ADDD_IMM:
			if (dm) begin
				a <= {acca,accb};
				b <= {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 2'd3;
				next_state(CALC);
			end
			else begin 
				res <= {acca[`LOBYTE],accb[`LOBYTE]} + {ir[`HIBYTE],ir[`BYTE3]};
				pc <= pc + 2'd3;
			end
`ifdef SUPPORT_6309
	`ADDW_IMM:
			begin 
				res <= {acce[`LOBYTE],accf[`LOBYTE]} + {ir[`HIBYTE],ir[`BYTE3]};
				pc <= pc + 2'd3;
			end
	`ADCD_IMM:
			if (dm) begin
				a <= {acca,accb};
				b <= {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
				next_state(CALC);
			end
			else begin 
				res <= {acca[`LOBYTE],accb[`LOBYTE]} + {ir[`BYTE2],ir[`BYTE3]} + {23'b0,cf};
				pc <= pc + 32'd3;
			end
`endif		
	`SUBD_IMM:	
			if (dm) begin
				a <= {acca,accb};
				b <= {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
				next_state(CALC);
			end
			else begin 
				res <= {acca[`LOBYTE],accb[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
				pc <= pc + 2'd3;
			end
`ifdef SUPPORT_6309					
	`SUBW_IMM:	
				begin 
					res <= {acce[`LOBYTE],accf[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
					pc <= pc + 2'd3;
				end
	`SBCD_IMM:
		if (dm) begin
			a <= {acca,accb};
			b <= {ir[`BYTE2],ir[`BYTE3]};
			pc <= pc + 32'd3;
			next_state(CALC);
		end
		else begin 
			res <= {acca[`LOBYTE],accb[`LOBYTE]} - {ir[`BYTE2],ir[`BYTE3]} - {23'b0,cf};
			pc <= pc + 32'd3;
		end
	`LDW_IMM:	
		begin 
			res <= {ir[`HIBYTE],ir[`BYTE3]};
			pc <= pc + 2'd3;
		end
`endif
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
			if (dm) begin
				a <= {acca,accb};
				b <= {ir[`BYTE2],ir[`BYTE3]};
				pc <= pc + 32'd3;
				next_state(CALC);
			end
			else begin
				res <= {acca[`LOBYTE],accb[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
				pc <= pc + 2'd3;
				a <= {acca[`LOBYTE],accb[`LOBYTE]};
				b <= {ir[`HIBYTE],ir[`BYTE3]};
			end
`ifdef SUPPORT_6309
	`CMPW_IMM:
				begin
					res <= {acce[`LOBYTE],accf[`LOBYTE]} - {ir[`HIBYTE],ir[`BYTE3]};
					pc <= pc + 2'd3;
					a <= {acce[`LOBYTE],accf[`LOBYTE]};
					b <= {ir[`HIBYTE],ir[`BYTE3]};
				end
`endif
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
`ifdef SUPPORT_6309
	`DIVD_IMM:
		begin
			b <= {ir[`BYTE3],ir[`BYTE2]};
			pc <= pc + 2'd2;
			next_state(DIV1);
		end
	`DIVQ_IMM:
		begin
			b <= {ir[`BYTE3],ir[`BYTE2]};
			pc <= pc + 2'd3;
			next_state(DIV1);
		end
	`MULD_IMM:
		begin
			b <= {ir[`BYTE3],ir[`BYTE2]};
			pc <= pc + 2'd3;
			divcnt <= 6'd7;
			next_state(MUL2);
		end
`endif
	`MULG_DP:
		if (df) begin
			df <= 1'b0;
			load_what <= `LW_B10;
			radr <= dp_address;
			next_state(LOAD1);
		end
		else
			next_state(DFMUL1);
	`DIVG_DP:
		if (df) begin
			load_what <= `LW_B10;
			radr <= dp_address;
			next_state(LOAD1);
		end
		else
			next_state(DFDIV1);
	`CMPG_DP,
	`SUBG_DP,
	`ADDG_DP:
		begin
			load_what <= `LW_B10;
			radr <= dp_address;
			pc <= pc + 2'd2;
			next_state(LOAD1);
		end
`ifdef SUPPORT_6309
	`CMPE_DP,`CMPF_DP,
	`LDE_DP,`LDF_DP,
	`SUBE_DP,`SUBF_DP,
`endif
	`SUBA_DP,`CMPA_DP,`SBCA_DP,`ANDA_DP,`BITA_DP,`LDA_DP,`EORA_DP,`ADCA_DP,`ORA_DP,`ADDA_DP,
	`SUBB_DP,`CMPB_DP,`SBCB_DP,`ANDB_DP,`BITB_DP,`LDB_DP,`EORB_DP,`ADCB_DP,`ORB_DP,`ADDB_DP:
		begin
			load_what <= `LW_BL;
			radr <= dp_address;
			pc <= pc + 2'd2;
			next_state(LOAD1);
		end
`ifdef SUPPORT_6309
	`BITD_DP,
	`ANDD_DP,
	`ORD_DP,
	`DIVD_DP,
	`DIVQ_DP,
	`EORD_DP:
		begin
			load_what <= `LW_BL;
			radr <= dp_address;
			pc <= pc + 2'd2;
			next_state(LOAD1);
		end
	`BAND_DP,`BEOR_DP,`BIAND_DP,`BIEOR_DP,`BOR_DP,`BIOR_DP:
		begin
			load_what <= `LW_BL;
			radr <= {dpr,ir[`BYTE3]};
			pc <= pc + 2'd3;
			next_state(LOAD1);
		end
`endif
`ifdef SUPPORT_6309
	`MULD_DP,
	`ADDW_DP,`CMPW_DP,`LDW_DP,`SUBW_DP,
`endif
	`SUBD_DP,`ADDD_DP,`LDD_DP,`CMPD_DP,`ADCD_DP,`SBCD_DP:
		begin
			load_what <= `LW_BH;
			pc <= pc + 2'd2;
			radr <= dp_address;
			next_state(LOAD1);
		end
	`LDG_DP:
		begin
			load_what <= `LW_B10;
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
	`STG_DP:	dp_store(`SW_G10);
	`STU_DP:	dp_store(`SW_USPH);
	`STS_DP:	dp_store(`SW_SSPH);
	`STX_DP:	dp_store(`SW_XH);
	`STY_DP:	dp_store(`SW_YH);
`ifdef SUPPORT_6309
	`STW_DP:	dp_store(`SW_ACCWH);
	`STE_DP:	dp_store(`SW_ACCE);
	`STF_DP:	dp_store(`SW_ACCF);
`endif
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
	`MULG_NDX:
		if (df) begin
			df <= 1'b0;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				b <= 'd0;
				load_what <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
		end
		else
			next_state(DFMUL1);
	`DIVG_NDX:
		if (df) begin
			df <= 1'b0;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				b <= 'd0;
				load_what <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
		end
		else
			next_state(DFDIV1);
	`CMPG_NDX,
	`SUBG_NDX,
	`ADDG_NDX:
		begin
			pc <= pc + insnsz;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				b <= 'd0;
				load_what <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
		end
`ifdef SUPPORT_6309
	`CMPE_NDX,`CMPF_NDX,
	`LDE_NDX,`LDF_NDX,
	`SUBE_NDX,`SUBF_NDX,
`endif
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
`ifdef SUPPORT_6309
	`BITD_NDX,
	`ANDD_NDX,
	`ORD_NDX,
	`DIVD_NDX,
	`DIVQ_NDX,
	`EORD_NDX:
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
	`MULD_NDX:
		begin
			pc <= pc + insnsz;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_BH;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				b <= 24'd0;
				load_what <= `LW_BH;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
		end
`endif
`ifdef SUPPORT_6309
	`ADDW_NDX,`CMPW_NDX,`LDW_NDX,`SUBW_NDX,
`endif
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
	`LDG_NDX:
		begin
			pc <= pc + insnsz;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_B10;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				load_what <= `LW_B10;
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
	`STG_NDX:	indexed_store(`SW_G10);
	`STU_NDX:	indexed_store(`SW_USPH);
	`STS_NDX:	indexed_store(`SW_SSPH);
	`STX_NDX:	indexed_store(`SW_XH);
	`STY_NDX:	indexed_store(`SW_YH);
`ifdef SUPPORT_6309
	`STW_NDX:	indexed_store(`SW_ACCWH);
	`STE_NDX:	indexed_store(`SW_ACCE);
	`STF_NDX:	indexed_store(`SW_ACCF);
	`AIM_DP,`EIM_DP,`OIM_DP,`TIM_DP:
		begin
			load_what <= `LW_BL;
			pc <= pc + 4'd3;
			radr <= dp_address;
			next_state(LOAD1);
		end
	`AIM_NDX,`EIM_NDX,`OIM_NDX,`TIM_NDX:
		begin
			pc <= pc + insnsz + 4'd1;
			if (isIndirect) begin
				load_what <= isFar ? `LW_IA2316 : `LW_IAH;
				load_what2 <= `LW_BL;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
			else begin
				b <= 'd0;
				load_what <= `LW_BL;
				radr <= NdxAddr;
				next_state(LOAD1);
			end
		end
`endif
`ifdef SUPPORT_6309
	`AIM_EXT,`OIM_EXT,`EIM_EXT,`TIM_EXT:
		begin
			load_what <= `LW_BL;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd5 : 32'd4);
			next_state(LOAD1);
		end
`endif
	// Extended mode instructions
	`NEG_EXT,`COM_EXT,`LSR_EXT,`ROR_EXT,`ASR_EXT,`ASL_EXT,`ROL_EXT,`DEC_EXT,`INC_EXT,`TST_EXT:
		begin
			load_what <= `LW_BL;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd4 : 32'd3);
			next_state(LOAD1);
		end
`ifdef SUPPORT_6309
	`CMPE_EXT,`CMPF_EXT,
	`LDE_EXT,`LDF_EXT,
	`SUBE_EXT,`SUBF_EXT,
`endif
	`SUBA_EXT,`CMPA_EXT,`SBCA_EXT,`ANDA_EXT,`BITA_EXT,`LDA_EXT,`EORA_EXT,`ADCA_EXT,`ORA_EXT,`ADDA_EXT,
	`SUBB_EXT,`CMPB_EXT,`SBCB_EXT,`ANDB_EXT,`BITB_EXT,`LDB_EXT,`EORB_EXT,`ADCB_EXT,`ORB_EXT,`ADDB_EXT:
		begin
			load_what <= `LW_BL;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd4 : 32'd3);
			next_state(LOAD1);
		end
	`MULG_EXT:
		if (df) begin
			df <= 1'b0;
			load_what <= `LW_B10;
			radr <= ex_address;
			next_state(LOAD1);
		end
		else
			next_state(DFMUL1);
	`DIVG_EXT:
		if (df) begin
			df <= 1'b0;
			load_what <= `LW_B10;
			radr <= ex_address;
			next_state(LOAD1);
		end
		else
			next_state(DFDIV1);
	`ADDG_EXT,`SUBG_EXT,`CMPG_EXT:
		begin
			load_what <= `LW_B10;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd4 : 32'd3);
			next_state(LOAD1);
		end
`ifdef SUPPORT_6309
	`BITD_EXT,
	`ANDD_EXT,
	`ORD_EXT,
	`DIVD_EXT,
	`DIVQ_EXT,
	`EORD_EXT:
		begin
			load_what <= `LW_BH;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd4 : 32'd3);
			next_state(LOAD1);
		end
`endif
`ifdef SUPPORT_6309
	`MULD_EXT,
	`ADDW_EXT,`CMPW_EXT,`LDW_EXT,`SUBW_EXT,
`endif
	`SUBD_EXT,`ADDD_EXT,`LDD_EXT,`CMPD_EXT,`ADCD_EXT,`SBCD_EXT:
		begin
			load_what <= `LW_BH;
			radr <= ex_address;
			pc <= pc + (isFar ? 32'd4 : 32'd3);
			next_state(LOAD1);
		end
	`LDG_EXT:
		begin
			load_what <= `LW_B10;
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
	`STG_EXT:	ex_store(`SW_G10);
	`STU_EXT:	ex_store(`SW_USPH);
	`STS_EXT:	ex_store(`SW_SSPH);
	`STX_EXT:	ex_store(`SW_XH);
	`STY_EXT:	ex_store(`SW_YH);
`ifdef SUPPORT_6309
	`STW_EXT:	ex_store(`SW_ACCWH);
	`STE_EXT:	ex_store(`SW_ACCE);
	`STF_EXT:	ex_store(`SW_ACCF);
`endif
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
	    if (isFar) begin
				store_what <= `SW_PC2316;
		    wadr <= ssp - 16'd3;
		    ssp <= ssp - 16'd3;
	    end
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
	`JMP_EXT:	pc <= ex_address;
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
	`JTT_DP:
		begin
			radr <= dp_address; 
			ir[`HIBYTE] <= 12'h7FF;
			isFar <= `TRUE;
			next_state(PULL1);
		end
	`JTT_EXT:
		begin
			radr <= ex_address; 
			ir[`HIBYTE] <= 12'h7FF;
			isFar <= `TRUE;
			next_state(PULL1);
		end
	`JTT_NDX:
		begin
			radr <= NdxAddr;
			ir[`HIBYTE] <= 12'h7FF;
			isFar <= `TRUE;
			next_state(PULL1);
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
			radr <= {stkbnk,ssp};
			next_state(PULL1);
			pc <= pc + 2'd2;
		end
	`PULU:
		begin
			radr <= {stkbnk,usp};
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
	`JTT:
		begin
			ir[`HIBYTE] <= 12'h7FF;
			load_what <= `LW_CCR;
			isFar <= `TRUE;
			next_state(LOAD1);
		end
	// The CCR must be pushed onto the stack before interrupts are masked. So,
	// interrupts are maksed when the PC is loaded after all the pushing.
	`SWI:
		begin
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `SWI_VECT;
			next_state(DECODE);
		end
	`SWI2:
		begin
			isSWI2 <= 1'b1;
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
	`SYS:
		begin
			isSYS <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `SYS_VECT;
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
	        load_what <= `LW_PC3124;
			    pc <= 36'hFFFFFFFFC;
			    next_state(LOAD1);
				end
			end
			else begin
				if (isSYS) begin
					ir[`HIBYTE] <= 12'h7FF;
				end
				else if (isFIRQ) begin
					if (natMd) begin
						ef <= firqMd;
						ir[`HIBYTE] <= firqMd ? 12'h3FF : 12'h081;
					end
					else begin
						ir[`HIBYTE] <= 12'h081;
						ef <= 1'b0;
					end
				end
				else begin	//if (isNMI | isIRQ | isSWI | isSWI2 | isSWI3) begin
					ir[`HIBYTE] <= natMd ? 12'h3FF : 12'h0FF;
					ef <= 1'b1;
				end
				pc <= pc;
				isFar <= `TRUE;
				next_state(PUSH1);
			end
		end
	default:
		if (natMd) begin
			iop <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `IOP_VECT;
			next_state(DECODE);
		end
	endcase
end
endtask

// ============================================================================
// MEMORY LOAD
// ============================================================================
task tLoad1;
begin
`ifdef SUPPORT_DCACHE
	if (unCachedData)
`endif
	case(radr)
	`CORENO:		load_tsk({2'b0,id});
	`CHKPOINT:	load_tsk(chkpoint);
	`MSCOUNT+0:	load_tsk(12'h0);
	`MSCOUNT+1:	load_tsk(ms_count[35:24]);
	`MSCOUNT+2:	load_tsk(ms_count[23:12]);
	`MSCOUNT+3:	load_tsk(ms_count[11: 0]);
`ifdef SUPPORT_DEBUG_REG
	`BRKAD0+0:		load_tsk(brkad[0][`BYTE2]);
	`BRKAD0+1:		load_tsk(brkad[0][`BYTE1]);
	`BRKAD1+0:		load_tsk(brkad[1][`BYTE2]);
	`BRKAD1+1:		load_tsk(brkad[1][`BYTE1]);
	`BRKAD2+0:		load_tsk(brkad[2][`BYTE2]);
	`BRKAD2+1:		load_tsk(brkad[2][`BYTE1]);
	`BRKAD3+0:		load_tsk(brkad[3][`BYTE2]);
	`BRKAD3+1:		load_tsk(brkad[3][`BYTE1]);
	`BRKCTRL0:		load_tsk(brkctrl[0]);
	`BRKCTRL1:		load_tsk(brkctrl[1]);
	`BRKCTRL2:		load_tsk(brkctrl[2]);
	`BRKCTRL3:		load_tsk(brkctrl[3]);
`endif	
	`MMU_AKEY:		load_tsk(pcr_o[`BYTE1]);
	`MMU_OKEY:		load_tsk(pcr_o[`BYTE2]);
`ifdef SUPPORT_OS
	`RDYQO:				begin load_tsk(rdyq_tido); rdyq_pop <= 1'b1; end
	`TCB_BASE+0:	load_tsk(tcb_base[`BYTE2]);
	`TCB_BASE+1:	load_tsk(tcb_base[`BYTE1]);
`endif	
	default:
`ifdef SUPPORT_DEBUG_REG
	if (brkctrl[0].en && brkctrl[0].match_type==BMT_LS && (radr & {{20{1'b1}},brkctrl[0].amask})==brkad[0]) begin
		brkctrl[0].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[1].en && brkctrl[1].match_type==BMT_LS && (radr & {{20{1'b1}},brkctrl[1].amask})==brkad[1]) begin
		brkctrl[1].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[2].en && brkctrl[2].match_type==BMT_LS && (radr & {{20{1'b1}},brkctrl[2].amask})==brkad[2]) begin
		brkctrl[2].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[3].en && brkctrl[3].match_type==BMT_LS && (radr & {{20{1'b1}},brkctrl[3].amask})==brkad[3]) begin
		brkctrl[3].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else
`endif
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
	endcase
end
endtask

task tLoad2;
begin
	// On a tri-state condition abort the bus cycle and retry the load.
	if (tsc|rty_i|bto) begin
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
end
endtask

// ============================================================================
// EXECUTE
//
// Perform calculations
// ============================================================================
task tExecute;
begin
	next_state(IFETCH);
	case(ir12)
	`SUBD_IMM,
	`SUBD_DP,`SUBD_NDX,`SUBD_EXT,
	`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
		if (dm)
			res <= bcdsubo;
		else begin
		    a <= {acca[`LOBYTE],accb[`LOBYTE]};
			res <= {acca[`LOBYTE],accb[`LOBYTE]} - b[`DBLBYTE];
		end
	`SBCD_IMM,`SBCD_DP,`SBCD_NDX,`SBCD_EXT:
		if (dm)
			res <= bcdsubo;
		else begin
		    a <= {acca[`LOBYTE],accb[`LOBYTE]};
			res <= {acca[`LOBYTE],accb[`LOBYTE]} - b[`DBLBYTE] - {23'b0,cf};
		end
	`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
		if (dm)
			res <= bcdaddo;
		else begin
		    a <= {acca[`LOBYTE],accb[`LOBYTE]};
			res <= {acca[`LOBYTE],accb[`LOBYTE]} + b[`DBLBYTE];
		end
`ifdef SUPPORT_6309
	`SUBW_DP,`SUBW_NDX,`SUBW_EXT,
	`CMPW_DP,`CMPW_NDX,`CMPW_EXT:
		begin
		    a <= {acce[`LOBYTE],accf[`LOBYTE]};
			res <= {acce[`LOBYTE],accf[`LOBYTE]} - b[`DBLBYTE];
		end
	`ADDW_DP,`ADDW_NDX,`ADDW_EXT:
		begin
		    a <= {acce[`LOBYTE],accf[`LOBYTE]};
			res <= {acce[`LOBYTE],accf[`LOBYTE]} + b[`DBLBYTE];
		end
	`LDW_DP,`LDW_NDX,`LDW_EXT:		
		res <= b[`DBLBYTE];
`endif
	`ADCD_IMM,`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
		if (dm)
			res <= bcdaddo;
		else begin
		    a <= {acca[`LOBYTE],accb[`LOBYTE]};
			res <= {acca[`LOBYTE],accb[`LOBYTE]} + b[`DBLBYTE] + {23'b0,cf};
		end
	`LDD_DP,`LDD_NDX,`LDD_EXT:		
		res <= b[`DBLBYTE];
`ifdef SUPPORT_6309
	`CMPE_DP,`CMPE_NDX,`CMPE_EXT,
	`CMPF_DP,`CMPF_NDX,`CMPF_EXT,
	`SUBE_DP,`SUBE_NDX,`SUBE_EXT,
	`SUBF_DP,`SUBF_NDX,`SUBF_EXT:
	        begin
  		        a <= acc;
           res12 <= acc[`LOBYTE] - b12;
			end
`endif
	`CMPA_IMM,`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
	`SUBA_IMM,`SUBA_DP,`SUBA_NDX,`SUBA_EXT,
	`CMPB_IMM,`CMPB_DP,`CMPB_NDX,`CMPB_EXT,
	`SUBB_IMM,`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
		if (dm)
			res12 <= bcdsubbo;
		else begin
        a <= acc;
     	res12 <= acc[`LOBYTE] - b12;
		end
	
	`SBCA_IMM,`SBCA_DP,`SBCA_NDX,`SBCA_EXT,
	`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
		if (dm)
			res12 <= bcdsubbo;
	  else begin
        a <= acc;
    res12 <= acc[`LOBYTE] - b12 - cf;
    end
	`BITA_DP,`BITA_NDX,`BITA_EXT,
	`ANDA_DP,`ANDA_NDX,`ANDA_EXT,
	`BITB_DP,`BITB_NDX,`BITB_EXT,
	`ANDB_DP,`ANDB_NDX,`ANDB_EXT:
				res12 <= acc[`LOBYTE] & b12;
	`ADDG_DP,`ADDG_NDX,`ADDG_EXT,
	`SUBG_DP,`SUBG_NDX,`SUBG_EXT:
		begin
			divcnt <= 6'd40;
			next_state(MUL2);
		end
	`MULG_DP,`MULG_NDX,`MULG_EXT:
		next_state(DFMUL1);
	`DIVG_DP,`DIVG_NDX,`DIVG_EXT:
		next_state(DFDIV1);
`ifdef SUPPORT_6309
	`BITD_DP,`BITD_NDX,`BITD_EXT,
	`ANDD_DP,`ANDD_NDX,`ANDD_EXT:
		res <= {acca[`LOBYTE],accb[`LOBYTE]} & b[`DBLBYTE];
	`DIVQ_DP,`DIVQ_NDX,`DIVQ_EXT,
	`DIVD_DP,`DIVD_NDX,`DIVD_EXT:
		if (b==24'd0) begin
			dbz <= 1'b1;
			bs_o <= 1'b1;
			ir[`LOBYTE] <= `INT;
			ipg <= 2'b11;
			vect <= `IOP_VECT;
			next_state(DECODE);
		end
		else
			next_state(DIV1);
	`MULD_DP,`MULD_NDX,`MULD_EXT:
		begin
			divcnt <= 6'd7;
			next_state(MUL2);
		end
	`EORD_DP,`EORD_NDX,`EORD_EXT:
		res <= {acca[`LOBYTE],accb[`LOBYTE]} ^ b[`DBLBYTE];
	`ORD_DP,`ORD_NDX,`ORD_EXT:
		res <= {acca[`LOBYTE],accb[`LOBYTE]} | b[`DBLBYTE];
	`LDE_DP,`LDE_NDX,`LDE_EXT,
	`LDF_DP,`LDF_NDX,`LDF_EXT:
		res12 <= b12;
`ifdef SUPPORT_BxxDP
`ifdef TWELVEBIT
	`BAND_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df & b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] & b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] & b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] & b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] & b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
	`BEOR_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] ^ b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
	`BIAND_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] & ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
	`BIEOR_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] ^ ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
	`BIOR_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] | ~b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
	`BOR_DP:
		begin
			case(ir[bitsPerByte+10:bitsPerByte+8])
			3'd0:	
				case(ir[bitsPerByte+3:bitsPerByte+0])
				4'd0:	cf <= cf | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd1:	vf <= vf | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd2:	zf <= zf | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd3: nf <= nf | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd4: im <= im | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd5: hf <= hf | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd6: firqim <= firqim | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd7: ef <= ef | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd8:	dm <= dm | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd9: im1 <= im1 | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				4'd10: df <= df | b12[ir[bitsPerByte+7:bitsPerByte+4]];
				default:	;
				endcase
			3'd1:	acca[ir[bitsPerByte+3:bitsPerByte+0]] <= acca[ir[bitsPerByte+3:bitsPerByte+0]] | b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd2:	accb[ir[bitsPerByte+3:bitsPerByte+0]] <= accb[ir[bitsPerByte+3:bitsPerByte+0]] | b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd3:	acce[ir[bitsPerByte+3:bitsPerByte+0]] <= acce[ir[bitsPerByte+3:bitsPerByte+0]] | b12[ir[bitsPerByte+7:bitsPerByte+4]];
			3'd4:	accf[ir[bitsPerByte+3:bitsPerByte+0]] <= accf[ir[bitsPerByte+3:bitsPerByte+0]] | b12[ir[bitsPerByte+7:bitsPerByte+4]];
			default:	;
			endcase
		end
`endif
`endif
`endif
	`LDA_DP,`LDA_NDX,`LDA_EXT,
	`LDB_DP,`LDB_NDX,`LDB_EXT:
			res12 <= b12;
	`EORA_DP,`EORA_NDX,`EORA_EXT,
	`EORB_DP,`EORB_NDX,`EORB_EXT:
				res12 <= acc[`LOBYTE] ^ b12;
	`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT,
	`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
		if (dm)
			res12 <= bcdaddbo;
		else begin
		    a <= acc;
			res12 <= acc[`LOBYTE] + b12 + cf;
		end
	`ORA_DP,`ORA_NDX,`ORA_EXT,
	`ORB_DP,`ORB_NDX,`ORB_EXT:
				res12 <= acc[`LOBYTE] | b12;
`ifdef SUPPORT_6309
	`ADDE_DP,`ADDE_NDX,`ADDE_EXT,
	`ADDF_DP,`ADDF_NDX,`ADDF_EXT,
`endif
	`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
	`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT:
		if (dm)
			res12 <= bcdaddbo;
		else begin
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
	`NEGA,`NEGB:	begin res12 <= bcdnegbo; end
	`COM_DP,`COM_NDX,`COM_EXT:	begin res12 <= ~b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`LSR_DP,`LSR_NDX,`LSR_EXT:	begin res12 <= {b[0],1'b0,b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
	`ROR_DP,`ROR_NDX,`ROR_EXT:	begin res12 <= {b[0],cf,b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
	`ASR_DP,`ASR_NDX,`ASR_EXT:	begin res12 <= {b[0],b[BPBM1],b[BPBM1:1]}; store_what <= `SW_RES8; wadr <= radr; next_state(STORE1); end
	`ASL_DP,`ASL_NDX,`ASL_EXT:	begin res12 <= {b12,1'b0}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`ROL_DP,`ROL_NDX,`ROL_EXT:	begin res12 <= {b12,cf}; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`DEC_DP,`DEC_NDX,`DEC_EXT:	begin res12 <= b12 - 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`INC_DP,`INC_NDX,`INC_EXT:	begin res12 <= b12 + 2'd1; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`TST_DP,`TST_NDX,`TST_EXT:	res12 <= b12;
`ifdef SUPPORT_6309
	`NEGD:	begin res <= bcdnego; end
	`AIM_DP,`AIM_NDX,`AIM_EXT:	begin res12 <= ir[`HIBYTE] & b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`OIM_DP,`OIM_NDX,`OIM_EXT:	begin res12 <= ir[`HIBYTE] | b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`EIM_DP,`EIM_NDX,`OIM_EXT:  begin res12 <= ir[`HIBYTE] ^ b12; wadr <= radr; store_what <= `SW_RES8; next_state(STORE1); end
	`TIM_DP,`TIM_NDX,`TIM_EXT:	begin res12 <= ir[`HIBYTE] & b12; end
`endif
	default:	;
	endcase
end
endtask

// ============================================================================
// MEMORY STORE
// ============================================================================

task tStore1;
begin
	if (!ack_i) begin	
		lock_o <= lock_bus;
`ifdef SUPPORT_CHECKPOINT
		if (wadr==CHKPOINT)
			next_state(IFETCH);
		else
`endif
`ifdef SUPPORT_DEBUG_REG
	if (brkctrl[0].en && brkctrl[0].match_type==BMT_DS && (radr & {{20{1'b1}},brkctrl[0].amask})==brkad[0]) begin
		brkctrl[0].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[1].en && brkctrl[1].match_type==BMT_DS && (radr & {{20{1'b1}},brkctrl[1].amask})==brkad[1]) begin
		brkctrl[1].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[2].en && brkctrl[2].match_type==BMT_DS && (radr & {{20{1'b1}},brkctrl[2].amask})==brkad[2]) begin
		brkctrl[2].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else if (brkctrl[3].en && brkctrl[3].match_type==BMT_DS && (radr & {{20{1'b1}},brkctrl[3].amask})==brkad[3]) begin
		brkctrl[3].hit <= 1'b1;
		bs_o <= 1'b1;
		ir[`LOBYTE] <= `INT;
		ipg <= 2'b11;
		vect <= `DBG_VECT;
		next_state(DECODE);
	end
	else
`endif
		begin
			case(store_what)
			`SW_ACCDH:	wb_write(wadr,acca[`LOBYTE]);
			`SW_ACCDL:	wb_write(wadr,accb[`LOBYTE]);
			`SW_ACCA:	wb_write(wadr,acca[`LOBYTE]);
			`SW_ACCB:	wb_write(wadr,accb[`LOBYTE]);
`ifdef SUPPORT_6309			
			`SW_ACCWH:	wb_write(wadr,acce[`LOBYTE]);
			`SW_ACCWL:	wb_write(wadr,accf[`LOBYTE]);
			`SW_ACCE:	wb_write(wadr,acce[`LOBYTE]);
			`SW_ACCF:	wb_write(wadr,accf[`LOBYTE]);
`endif
			`SW_DPRH:	wb_write(wadr,dpr[`HIBYTE]);
			`SW_DPRL:	wb_write(wadr,dpr[`LOBYTE]);
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
			`SW_G10:	wb_write(wadr,accg[`BYTE11]);
			`SW_G9:	wb_write(wadr,accg[`BYTE10]);
			`SW_G8:	wb_write(wadr,accg[`BYTE9]);
			`SW_G7:	wb_write(wadr,accg[`BYTE8]);
			`SW_G6:	wb_write(wadr,accg[`BYTE7]);
			`SW_G5:	wb_write(wadr,accg[`BYTE6]);
			`SW_G4:	wb_write(wadr,accg[`BYTE5]);
			`SW_G3:	wb_write(wadr,accg[`BYTE4]);
			`SW_G2:	wb_write(wadr,accg[`BYTE3]);
			`SW_G1:	wb_write(wadr,accg[`BYTE2]);
			`SW_G0:	wb_write(wadr,accg[`BYTE1]);
			default:	wb_write(wadr,wdat);
			endcase
`ifdef SUPPORT_DCACHE
			radr <= wadr;		// Do a cache read to test the hit
`endif
			if (!tsc)
				next_state(STORE1a);
		end
	end
end
endtask

task tStore1a;
begin
	if (!tsc) begin
		cyc_o <= 1'b1;
		stb_o <= 1'b1;
		next_state(STORE2);
	end
end
endtask

// Terminal state for stores. Update the data cache if there was a cache hit.
// Clear any previously set lock status
task tStore2;
begin
	// On a tri-state condition abort the bus cycle and retry the store.
	if (tsc|rty_i|bto) begin
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
					if (natMd & iplMd)
						{im1,firqim,im} <= {nmi_i,firq_i,irq_i};
					else
						{im1,firqim,im} <= 3'b111;
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
`ifdef SUPPORT_6309				
		`SW_ACCE:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STE
				next_state(IFETCH);
		`SW_ACCF:
			if (isINT | isPSHS | isPSHU)
				next_state(PUSH2);
			else	// STF
				next_state(IFETCH);
		`SW_ACCWH:
			begin
				store_what <= `SW_ACCWL;
				next_state(STORE1);
			end
		`SW_ACCWL:	next_state(IFETCH);
`endif
		`SW_G10:				
			begin
				store_what <= `SW_G9;
				next_state(STORE1);
			end
		`SW_G9:				
			begin
				store_what <= `SW_G8;
				next_state(STORE1);
			end
		`SW_G8:
			begin
				store_what <= `SW_G7;
				next_state(STORE1);
			end
		`SW_G7:
			begin
				store_what <= `SW_G6;
				next_state(STORE1);
			end
		`SW_G6:
			begin
				store_what <= `SW_G5;
				next_state(STORE1);
			end
		`SW_G5:
			begin
				store_what <= `SW_G4;
				next_state(STORE1);
			end
		`SW_G4:
			begin
				store_what <= `SW_G3;
				next_state(STORE1);
			end
		`SW_G3:
			begin
				store_what <= `SW_G2;
				next_state(STORE1);
			end
		`SW_G2:
			begin
				store_what <= `SW_G1;
				next_state(STORE1);
			end
		`SW_G1:
			begin
				store_what <= `SW_G0;
				next_state(STORE1);
			end
		`SW_G0:
			begin
				next_state(IFETCH);
			end
		`SW_ACCDH:
			begin
				store_what <= `SW_ACCDL;
				next_state(STORE1);
			end
		`SW_ACCDL:	next_state(IFETCH);
		`SW_DPRH:
			begin
				store_what <= `SW_DPRL;
				next_state(STORE1);
			end
		`SW_DPRL:
				next_state(PUSH2);
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
end
endtask

// ============================================================================
// WRITEBACK
//
// Write results back to the register file and status flags.
// Which registers and flags get updated depend on the instruction.
// ============================================================================

task tWriteback;
begin
	if (first_ifetch) begin
		first_ifetch <= `FALSE;
		case(ir12)
		`ABX:	xr <= res;
		`ADDA_IMM,`ADDA_DP,`ADDA_NDX,`ADDA_EXT,
		`ADCA_IMM,`ADCA_DP,`ADCA_NDX,`ADCA_EXT:
			begin
				cf <= dm ? bcdaddbcf : (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
				hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
				vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				acca <= res12[`LOBYTE];
			end
		`ADDB_IMM,`ADDB_DP,`ADDB_NDX,`ADDB_EXT,
		`ADCB_IMM,`ADCB_DP,`ADCB_NDX,`ADCB_EXT:
			begin
				cf <= dm ? bcdaddbcf : (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
				hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
				vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				accb <= res12[`LOBYTE];
			end
`ifdef SUPPORT_6309
		`ADDE_IMM,`ADDE_DP,`ADDE_NDX,`ADDE_EXT:
			begin
				cf <= (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
				hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
				vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				accf <= res12[`LOBYTE];
			end
		`ADDF_IMM,`ADDF_DP,`ADDF_NDX,`ADDF_EXT:
			begin
				cf <= (a[BPBM1]&b[BPBM1])|(a[BPBM1]&~res12[BPBM1])|(b[BPBM1]&~res12[BPBM1]);
				hf <= (a[`HCBIT]&b[`HCBIT])|(a[`HCBIT]&~res12[`HCBIT])|(b[`HCBIT]&~res12[`HCBIT]);
				vf <= (res12[BPBM1] ^ b[BPBM1]) & (1'b1 ^ a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				acce <= res12[`LOBYTE];
			end
`endif
		`ADDD_IMM,`ADDD_DP,`ADDD_NDX,`ADDD_EXT:
			begin
				cf <= dm ? bcdaddcf : (a[BPBX2M1]&b[BPBX2M1])|(a[BPBX2M1]&~res[BPBX2M1])|(b[BPBX2M1]&~res[BPBX2M1]);
				vf <= (res[BPBX2M1] ^ b[BPBX2M1]) & (1'b1 ^ a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h000000;
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
`ifdef SUPPORT_6309
		`ADDW_IMM,`ADDW_DP,`ADDW_NDX,`ADDW_EXT:
			begin
				cf <= (a[BPBX2M1]&b[BPBX2M1])|(a[BPBX2M1]&~res[BPBX2M1])|(b[BPBX2M1]&~res[BPBX2M1]);
				vf <= (res[BPBX2M1] ^ b[BPBX2M1]) & (1'b1 ^ a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h000000;
				acce <= res[`HIBYTE];
				accf <= res[`LOBYTE];
			end
		`ADCD_IMM,`ADCD_DP,`ADCD_NDX,`ADCD_EXT:
			begin
				cf <= dm ? bcdaddcf : (a[BPBX2M1]&b[BPBX2M1])|(a[BPBX2M1]&~res[BPBX2M1])|(b[BPBX2M1]&~res[BPBX2M1]);
				vf <= (res[BPBX2M1] ^ b[BPBX2M1]) & (1'b1 ^ a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h0000;
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		`OIM_DP,`OIM_NDX,`OIM_EXT,
		`EIM_DP,`EIM_NDX,`EIM_EXT,
		`TIM_DP,`TIM_NDX,`TIM_EXT,
		`AIM_DP,`AIM_NDX,`AIM_EXT:
			begin
				vf <= 1'b0;
				nf <= res12n;
				zf <= res12z;
			end
`endif
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
`ifdef SUPPORT_6309
		`ORD_IMM,`ORD_DP,`ORD_NDX,`ORD_EXT,
		`EORD_IMM,`EORD_DP,`EORD_NDX,`EORD_EXT,
		`ANDD_IMM,`ANDD_DP,`ANDD_NDX,`ANDD_EXT:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= 1'b0;
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		`BITD_IMM,`BITD_DP,`BITD_NDX,`BITD_EXT:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= 1'b0;
			end
		`DIVD_IMM,`DIVD_DP,`DIVD_NDX,`DIVD_EXT:
			begin
				acca <= res[`BYTE2];
				accb <= res[`BYTE1];
				// Overflow set eariler
				cf <= res[0];
				nf <= res[bitsPerByte-1];
				zf <= ~|res[bitsPerByte-1:0];
			end
		`DIVQ_IMM,`DIVQ_DP,`DIVQ_NDX,`DIVQ_EXT:
			begin
				if (bitsPerByte==12) begin
					acce <= divrem24[`BYTE2];
					accf <= divrem24[`BYTE1];
					acca <= divres48[`BYTE2];
					accb <= divres48[`BYTE1];
					// Overflow set eariler
					cf <= divres48[0];
					vf <= divres48[47:24]!={24{divres48[23]}};
					nf <= divres48[23];
					zf <= ~|divres48[23:0];
				end
				else if (bitsPerByte==8) begin
					acce <= divrem16[`BYTE2];
					accf <= divrem16[`BYTE1];
					acca <= divres32[`BYTE2];
					accb <= divres32[`BYTE1];
					// Overflow set eariler
					cf <= divres32[0];
					vf <= divres32[31:16]!={16{divres32[15]}};
					nf <= divres48[15];
					zf <= ~|divres48[15:0];
				end
			end
		`MULD_IMM,`MULD_DP,`MULD_NDX,`MULD_EXT:
			begin
				accf <= muld_res6[`BYTE1];
				acce <= muld_res6[`BYTE2];
				accb <= muld_res6[`BYTE3];
				acca <= muld_res6[`BYTE4];
				zf <= ~|muld_res6;
				nf <= muld_res6[bitsPerByte*4-1];
			end
`endif
		`CMPG_DP,`CMPG_NDX,`CMPG_EXT:
			begin
				zf <= dfco[0];
				nf <= dfco[1];
				vf <= dfco[4];
			end
		`ADDG_DP,`ADDG_NDX,`ADDG_EXT,
		`SUBG_DP,`SUBG_NDX,`SUBG_EXT:
			begin
				nf <= dfaso[127];
				zf <= ~|dfaso[126:0];
				accg <= dfaso;
			end
		`MULG_DP,`MULG_NDX,`MULG_EXT:
			begin
				nf <= dfmo[127];
				zf <= ~|dfmo[126:0];
				vf <= dfm_vf;
				accg <= dfmo;
			end
		`DIVG_DP,`DIVG_NDX,`DIVG_EXT:
			begin
				nf <= dfdo[127];
				zf <= ~|dfdo[126:0];
				vf <= dfd_vf;
				accg <= dfdo;
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
`ifdef H6309
		`ASLD,`ROLD:
			begin
				cf <= resc;
				nf <= resn;
				zf <= resz;
				vf <= acca[bitsPerByte-1]^acca[bitsPerByte-2];
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		`ASRD:
			begin
				cf <= resc;
				nf <= resn;
				zf <= resz;
				vf <= acca[bitsPerByte-1]^acca[bitsPerByte-2];
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		`LSRD,`RORD:
			begin
				cf <= resc;
				nf <= resn;
				zf <= resz;
				vf <= acca[bitsPerByte-1]^acca[bitsPerByte-2];
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		`LSRW:
			begin
				cf <= resc;
				nf <= resn;
				zf <= resz;
				vf <= acce[bitsPerByte-1]^acce[bitsPerByte-2];
				acce <= res[`HIBYTE];
				accf <= res[`LOBYTE];
			end
		`ROLW,`RORW:
			begin
				cf <= resc;
				nf <= resn;
				zf <= resz;
				vf <= acce[bitsPerByte-1]^acce[bitsPerByte-2];
				acce <= res[`HIBYTE];
				accf <= res[`LOBYTE];
			end
`endif
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
`ifdef SUPPORT_6309
		`BITMD:
			zf <= res12==12'h0;
		`CLRD:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				acca <= 12'h000;
				accb <= 12'h000;
			end
		`CLRW:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				acce <= 12'h000;
				accf <= 12'h000;
			end
		`CLRE:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				acce <= 12'h000;
			end
		`CLRF:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
				accf <= 12'h000;
			end
`endif
		`CLR_DP,`CLR_NDX,`CLR_EXT:
			begin
				vf <= 1'b0;
				cf <= 1'b0;
				nf <= 1'b0;
				zf <= 1'b1;
			end
`ifdef SUPPORT_6309
		`CMPE_IMM,`CMPE_DP,`CMPE_NDX,`CMPE_EXT,
		`CMPF_IMM,`CMPF_DP,`CMPF_NDX,`CMPF_EXT:
			begin
				cf <= (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
			end
`endif
		`CMPA_IMM,`CMPA_DP,`CMPA_NDX,`CMPA_EXT,
		`CMPB_IMM,`CMPB_DP,`CMPB_NDX,`CMPB_EXT:
			begin
				cf <= dm ? bcdsubbcf : (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
			end
`ifdef SUPPORT_6309
		`CMPW_IMM,`CMPW_DP,`CMPW_NDX,`CMPW_EXT:
			begin
				cf <= (~a[BPBX2M1]&b[BPBX2M1])|(res[BPBX2M1]&~a[BPBX2M1])|(res[BPBX2M1]&b[BPBX2M1]);
				vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h000000;
			end
`endif
		`CMPD_IMM,`CMPD_DP,`CMPD_NDX,`CMPD_EXT:
			begin
				cf <= dm ? bcdsubcf : (~a[BPBX2M1]&b[BPBX2M1])|(res[BPBX2M1]&~a[BPBX2M1])|(res[BPBX2M1]&b[BPBX2M1]);
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
`ifdef SUPPORT_6309
		`COME:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res12n;
				zf <= res12z;
				acce <= res12[`LOBYTE];
			end
		`COMF:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res12n;
				zf <= res12z;
				accf <= res12[`LOBYTE];
			end
		`COMD:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res24n;
				zf <= res24z;
				{acca,accb} <= res;
			end
		`COMW:
			begin
				cf <= 1'b1;
				vf <= 1'b0;
				nf <= res24n;
				zf <= res24z;
				{acce,accf} <= res;
			end
`endif
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
`ifdef SUPPORT_6309
		`DECE:
			begin
				nf <= res12n;
				zf <= res12z;
				vf <= res12[BPBM1] != acce[BPBM1];
				acce <= res12[`LOBYTE];
			end
		`DECF:
			begin
				nf <= res12n;
				zf <= res12z;
				vf <= res12[BPBM1] != accf[BPBM1];
				accf <= res12[`LOBYTE];
			end
		`DECD:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= res[bitsPerByte*2-1] != acca[bitsPerByte-1];
				{acca,accb} <= res;
			end
		`DECW:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= res[bitsPerByte*2-1] != acce[bitsPerByte-1];
				{acce,accf} <= res;
			end
`endif
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
				case(ir[bitsPerByte+3:bitsPerByte])
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
						dm <= src1[8];
						im1 <= src1[9];
						df <= src1[10];
					end
				4'b1011:	dpr <= bitsPerByte==8 ? {8'h00,src1[`LOBYTE]} : src1[`DBLBYTE];
				4'b1100:	stkbnk <= src1[`LOBYTE];
				4'b1101:	tr <= src1[`LOBYTE];
`ifdef SUPPORT_6309				
				4'b0110:	{acce,accf} <= src1[`DBLBYTE];
				4'b1110:	acce <= src1[`LOBYTE];
				4'b1111:	accf <= src1[`LOBYTE];
`else
				4'b1110:	;
				4'b1111:	;
`endif
				default:	;
				endcase
				case(ir[bitsPerByte+7:bitsPerByte+4])
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
						dm <= src2[8];
						im1 <= src2[9];
						df <= src2[10];
					end
				4'b1011:	dpr <= bitsPerByte==8 ? {8'h00,src2[`LOBYTE]} : src2[`DBLBYTE];
				4'b1100:	stkbnk <= src2[`LOBYTE];
				4'b1101:	tr <= src2[`LOBYTE];
`ifdef SUPPORT_6309
				4'b1110:	acce <= src2[`LOBYTE];
				4'b1111:	accf <= src2[`LOBYTE];
`else
				4'b1110:	;
				4'b1111:	;
`endif
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
`ifdef SUPPORT_6309
		`INCE:
			begin
				nf <= res12n;
				zf <= res12z;
				vf <= res12[BPBM1] != acce[BPBM1];
				acce <= res12[`LOBYTE];
			end
		`INCF:
			begin
				nf <= res12n;
				zf <= res12z;
				vf <= res12[BPBM1] != accf[BPBM1];
				accf <= res12[`LOBYTE];
			end
		`INCD:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= res[bitsPerByte*2-1] != acca[bitsPerByte-1];
				{acca,accb} <= res[`LOBYTE];
			end
		`INCW:
			begin
				nf <= res24n;
				zf <= res24z;
				vf <= res[bitsPerByte*2-1] != acce[bitsPerByte-1];
				{acce,accf} <= res[`LOBYTE];
			end
		`LDE_IMM,`LDE_DP,`LDE_NDX,`LDE_EXT:
			begin
				vf <= 1'b0;
				zf <= res12z;
				nf <= res12n;
				acce <= res12[`LOBYTE];
			end
		`LDF_IMM,`LDF_DP,`LDF_NDX,`LDF_EXT:
			begin
				vf <= 1'b0;
				zf <= res12z;
				nf <= res12n;
				accf <= res12[`LOBYTE];
			end
`endif
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
		`TSTG,`NEGG,`CLRG,
		`STG_DP,`STG_NDX,`STG_EXT,
		`LDG_DP,`LDG_NDX,`LDG_EXT:
			begin
				vf <= 1'b0;
				zf <= ~|b[126:0];
				nf <= b[127];
				accg <= b;
			end
`ifdef SUPPORT_6309
		`LDW_IMM,`LDW_DP,`LDW_NDX,`LDW_EXT:
			begin
				vf <= 1'b0;
				zf <= res24z;
				nf <= res24n;
				acce <= res[`HIBYTE];
				accf <= res[`LOBYTE];
			end
`endif
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
			if (dm) begin
				accb <= bcdmul_res16[`BYTE1];
				acca <= bcdmul_res16[`BYTE2];
				zf <= ~|bcdmul_res16;
				cf <= bcdmul_res16[bitsPerByte*2-1];
			end
			else begin
				cf <= prod[BPBM1];
				zf <= res24z;
				acca <= prod[`HIBYTE];
				accb <= prod[`LOBYTE];
			end
		`NEGA:
			begin
				cf <= dm ? bcdnegbcf : (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				acca <= res12[`LOBYTE];
			end
		`NEGB:
			begin
				cf <= dm ? bcdnegbcf : (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				accb <= res12[`LOBYTE];
			end
`ifdef SUPPORT_6309
		`NEGD:
			begin
				cf <= dm ? bcdnegcf : (~a[bitsPerByte*2-1]&b[bitsPerByte*2-1])|(res[bitsPerByte*2-1]&~a[bitsPerByte*2-1])|(res[bitsPerByte*2-1]&b[bitsPerByte*2-1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res[`HCBIT]&~a[`HCBIT])|(res[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res[bitsPerByte*2-1] ^ b[bitsPerByte*2-1]) & (a[bitsPerByte*2-1] ^ b[bitsPerByte*2-1]);
				nf <= res[bitsPerByte*2-1];
				zf <= res[`DBLBYTE]=='h0;
				{acca,accb} <= res;
			end
`endif
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
				cf <= dm ? bcdsubbcf : (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				nf <= res12[BPBM1];
				zf <= res12[`LOBYTE]==12'h000;
				acca <= res12[`LOBYTE];
			end
		`SBCB_IMM,`SBCB_DP,`SBCB_NDX,`SBCB_EXT:
			begin
				cf <= dm ? bcdsubbcf : (~a[BPBM1]&b[BPBM1])|(res12[BPBM1]&~a[BPBM1])|(res12[BPBM1]&b[BPBM1]);
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
`ifdef SUPPORT_6309
		`STE_DP,`STE_NDX,`STE_EXT,
		`STF_DP,`STF_NDX,`STF_EXT,
`endif
		`STA_DP,`STA_NDX,`STA_EXT,
		`STB_DP,`STB_NDX,`STB_EXT:	
			begin
				vf <= 1'b0;
				zf <= res12z;
				nf <= res12n;
			end
`ifdef SUPPORT_6309
		`STW_DP,`STW_NDX,`STW_EXT,
`endif			
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
				case(ir[bitsPerByte+3:bitsPerByte])
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
						dm <= src1[8];
						im1 <= src1[9];
						df <= src1[10];
					end
				4'b1011:	dpr <= bitsPerByte==8 ? {8'h00,src1[`LOBYTE]} : src1[`DBLBYTE];
				4'b1100:	stkbnk <= src1[`LOBYTE];
				4'b1101:	tr <= src1[`LOBYTE];
`ifdef SUPPORT_6309
				4'b0110:	{acce,accf} <= src1[`DBLBYTE];
				4'b1110:	acce <= src1[`LOBYTE];
				4'b1111:	accf <= src1[`LOBYTE];
`else
				4'b1110:	;
				4'b1111:	;
`endif
				default:	;
				endcase
			end
		`TSTE,`TSTF,
		`TSTA,`TSTB:
			begin
				vf <= 1'b0;
				nf <= res12n;
				zf <= res12z;
			end
		`TSTD:
			begin
				vf <= 1'b0;
				nf <= res24n;
				zf <= res24z;
			end
`ifdef SUPPORT_6309
		`TSTW:
			begin
				vf <= 1'b0;
				nf <= res24n;
				zf <= res24z;
			end
`endif
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
				cf <= dm ? bcdsubbcf : res12c;
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
			end
		`SUBB_IMM,`SUBB_DP,`SUBB_NDX,`SUBB_EXT:
			begin
				accb <= res12[`LOBYTE];
				nf <= res12n;
				zf <= res12z;
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				cf <= dm ? bcdsubbcf : res12c;
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
			end
`ifdef SUPPORT_6309
		`SUBE_IMM,`SUBE_DP,`SUBE_NDX,`SUBE_EXT:
			begin
				acce <= res12[`LOBYTE];
				nf <= res12n;
				zf <= res12z;
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				cf <= res12c;
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
			end
		`SUBF_IMM,`SUBF_DP,`SUBF_NDX,`SUBF_EXT:
			begin
				accf <= res12[`LOBYTE];
				nf <= res12n;
				zf <= res12z;
				vf <= (1'b1 ^ res12[BPBM1] ^ b[BPBM1]) & (a[BPBM1] ^ b[BPBM1]);
				cf <= res12c;
				hf <= (~a[`HCBIT]&b[`HCBIT])|(res12[`HCBIT]&~a[`HCBIT])|(res12[`HCBIT]&b[`HCBIT]);
			end
		`SUBW_IMM,`SUBW_DP,`SUBW_NDX,`SUBW_EXT:
			begin
				cf <= res24c;
				vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h000000;
				acce <= res[`HIBYTE];
				accf <= res[`LOBYTE];
			end
		`SBCD_IMM,`SBCD_DP,`SBCD_NDX,`SBCD_EXT,
`endif
		`SUBD_IMM,`SUBD_DP,`SUBD_NDX,`SUBD_EXT:
			begin
				cf <= dm ? bcdsubcf : res24c;
				vf <= (1'b1 ^ res[BPBX2M1] ^ b[BPBX2M1]) & (a[BPBX2M1] ^ b[BPBX2M1]);
				nf <= res[BPBX2M1];
				zf <= res[`DBLBYTE]==24'h000000;
				acca <= res[`HIBYTE];
				accb <= res[`LOBYTE];
			end
		endcase
	end
end
endtask

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
		we_o <= 1'b0;
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
		we_o <= 1'b0;
		adr_o <= adr;
	end
end
endtask

// Trap writes to special registers
task wb_write;
input [`TRPBYTE] adr;
input [`LOBYTE] dat;
begin
		if (!tsc) begin
			next_state(IFETCH);
			casez(adr)
`ifdef SUPPORT_OS
			`RDYQI:			begin rdyq_tidi <= dat; rdyq_ins <= 1'b1; rdyq_wa <= adr[2:0]; end
			`TCB_BASE+0:	tcb_base[`BYTE2] <= dat;
			`TCB_BASE+1:	tcb_base[`BYTE1] <= dat;
`endif
`ifdef SUPPORT_DEBUG_REG
			`BRKAD0+0:	brkad[0][`BYTE2] <= dat;	
			`BRKAD0+1: brkad[0][`BYTE1] <= dat;
			`BRKAD1+0:	brkad[1][`BYTE2] <= dat;	
			`BRKAD1+1: brkad[1][`BYTE1] <= dat;
			`BRKAD2+0:	brkad[2][`BYTE2] <= dat;	
			`BRKAD2+1: brkad[2][`BYTE1] <= dat;
			`BRKAD3+0:	brkad[3][`BYTE2] <= dat;	
			`BRKAD3+1: brkad[3][`BYTE1] <= dat;
			`BRKCTRL0: brkctrl[0] <= dat;
			`BRKCTRL1: brkctrl[1] <= dat;
			`BRKCTRL2: brkctrl[2] <= dat;
			`BRKCTRL3: brkctrl[3] <= dat;
`endif
			`MMU_AKEY:	pcr_o[11:0] <= dat;
			`MMU_OKEY:	pcr_o[23:12] <= dat;
			default:
				begin	
				we_o <= 1'b1;
				adr_o <= adr;
				dat_o <= dat;
				next_state(STORE1a);
				end
			endcase
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
//	adr_o <= 24'd0;
//	dat_o <= 12'd0;
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
	`LW_CCR:
		begin
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
			dm <= dat[8];
			im1 <= dat[9];
			df <= dat[10];
			if (isRTI) begin
				$display("loaded ccr=%b", dat);
				ir[`HIBYTE] <= dat[7] ? 12'h3FE : 12'h080;
				ssp <= ssp + 2'd1;
			end
			else if (isPULS)
				ssp <= ssp + 2'd1;
			else if (isPULU)
				usp <= usp + 2'd1;
		end
	`LW_ACCA:
		begin
			acca <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
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
	`LW_ACCB:
		begin
			accb <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
				$display("loaded accb=%h from %h", dat, radr);
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
`ifdef SUPPORT_6309
	`LW_ACCE:
		begin
			acce <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
				$display("loaded acce=%h from %h", dat, radr);
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
	`LW_ACCF:
		begin
			accf <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
				$display("loaded accf=%h from %h", dat, radr);
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
`endif
	`LW_DPRH:
		begin
			load_what <= `LW_DPRL;
			next_state(LOAD1);
			dpr[`HIBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI|isPULS) begin
				$display("loaded dpr=%h from %h", dat, radr);
				ssp <= ssp + 2'd1;
			end
			else if (isPULU) begin
				usp <= usp + 2'd1;
			end
		end
	`LW_DPRL:
		begin
			next_state(PULL1);
			dpr[`LOBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI|isPULS) begin
				$display("loaded dpr=%h from %h", dat, radr);
				ssp <= ssp + 2'd1;
			end
			else if (isPULU)
				usp <= usp + 2'd1;
		end
	`LW_XH:
		begin
			load_what <= `LW_XL;
			next_state(LOAD1);
			xr[`HIBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI) begin
				$display("loaded XH=%h from %h", dat, radr);
				ssp <= ssp + 2'd1;
			end
			else if (isPULU)
				usp <= usp + 2'd1;
			else if (isPULS)
				ssp <= ssp + 2'd1;
		end
	`LW_XL:
		begin
			xr[`LOBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
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
			if (isJTT)
				;
			else if (isRTI) begin
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
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
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
	`LW_USPH:
		begin
			load_what <= `LW_USPL;
			next_state(LOAD1);
			usp[`HIBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI) begin
				$display("loadded USPH=%h", dat);
				ssp <= ssp + 2'd1;
			end
			else if (isPULS)
				ssp <= ssp + 2'd1;
		end
	`LW_USPL:
		begin
			usp[`LOBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
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
	`LW_SSPH:
		begin
			load_what <= `LW_SSPL;
			next_state(LOAD1);
			ssp[`HIBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI)
				ssp <= ssp + 2'd1;
			else if (isPULU)
				usp <= usp + 2'd1;
		end
	`LW_SSPL:
		begin
			ssp[`LOBYTE] <= dat;
			radr <= radr + 2'd1;
			if (isJTT)
				next_state(PULL1);
			else if (isRTI) begin
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
	`LW_PCL:
		begin
			pc[`LOBYTE] <= dat;
			radr <= radr + 2'd1;
			// If loading from the vector table in bank zero, force pc[23:16]=0
			if (radr[`BYTE3]=={BPB{1'b0}} && radr[`BYTE2]=={BPB{1'b1}} && radr[7:4]==4'hF)
				pc[`BYTE3] <= {BPB{1'b0}};
			if (isJTT)
				;
			else if (isRTI|isRTS|isRTF|isPULS) begin
				$display("loadded PCL=%h", dat);
				ssp <= ssp + 2'd1;
			end
			else if (isPULU)
				usp <= usp + 2'd1;
			next_state(IFETCH);
		end
	`LW_PCH:
		begin
			pc[`HIBYTE] <= dat;
			load_what <= `LW_PCL;
			radr <= radr + 2'd1;
			if (isJTT)
				;
			else if (isRTI|isRTS|isRTF|isPULS) begin
				$display("loadded PCH=%h", dat);
				ssp <= ssp + 2'd1;
			end
			else if (isPULU)
				usp <= usp + 2'd1;
			next_state(LOAD1);
		end
	`LW_PC2316:
		begin
			pc[`BYTE3] <= dat;
			load_what <= `LW_PCH;
			radr <= radr + 16'd1;
			if (isJTT)
				;
			else if (isRTI|isRTF|isPULS)
				ssp <= ssp + 16'd1;
			else if (isPULU)
				usp <= usp + 16'd1;
			next_state(LOAD1);
		end
	`LW_PC3124:
		begin
			//pc[`BYTE4] <= dat; // Throw the byte away
			load_what <= `LW_PC2316;
			radr <= radr + 16'd1;
			if (isJTT)
				;
			else if (isRTI|isRTF|isPULS)
				ssp <= ssp + 16'd1;
			else if (isPULU)
				usp <= usp + 16'd1;
			next_state(LOAD1);
		end
	`LW_B10:
		begin
			load_what <= `LW_B9;
			b[127:120] <= dat[7:0];
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B9:
		begin
			load_what <= `LW_B8;
			b[119:108] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B8:
		begin
			load_what <= `LW_B7;
			b[107:96] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B7:
		begin
			load_what <= `LW_B6;
			b[95:84] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B6:
		begin
			load_what <= `LW_B5;
			b[83:72] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B5:
		begin
			load_what <= `LW_B4;
			b[71:60] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B4:
		begin
			load_what <= `LW_B3;
			b[`BYTE5] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B3:
		begin
			load_what <= `LW_B2;
			b[`BYTE4] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B2:
		begin
			load_what <= `LW_B1;
			b[`BYTE3] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B1:
		begin
			load_what <= `LW_B0;
			b[`BYTE2] <= dat;
			radr <= radr + 2'd1;
			next_state(LOAD1);
		end
	`LW_B0:
		begin
			b[`BYTE1] <= dat;
			radr <= radr + 2'd1;
			next_state(CALC);
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
          else if (isJTT) begin
          	load_what <= `LW_CCR;
          	next_state(PULL1);
          end
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
input [BPB*16-1:0] i;
input rclk;
input rce;
input [11:0] pc;
output [`OCTABYTE] insn;
reg [`OCTABYTE] insn;

integer n;
reg [BPB*16-1:0] mem [0:255];
reg [11:0] rpc,rpcp16;
initial begin
	for (n = 0; n < 256; n = n + 1)
		mem[n] = {16{`NOP}};
end

always_ff @(posedge wclk)
	if (wce & wr) mem[wa[11:4]] <= i;

always_ff @(posedge rclk)
	if (rce) rpc <= pc;
always_ff @(posedge rclk)
	if (rce) rpcp16 <= pc + 5'd16;
wire [BPB*16-1:0] insn0 = mem[rpc[11:4]];
wire [BPB*16-1:0] insn1 = mem[rpcp16[11:4]];
always_comb
	insn = {insn1,insn0} >> ({4'h0,rpc[3:0]} * BPB);

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
// Consider a hit on port 1 if the instruction will not span onto it.
assign hit1 = tag1 == {rpcp16[BPB*3-1:12],1'b1} || rpc[3:0] < 4'h9;

endmodule

