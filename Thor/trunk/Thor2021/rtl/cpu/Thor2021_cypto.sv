// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_crypto.sv
// For the crypto functions latency cannot depend on data operated on!
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

import Thor2021_pkg::*;

module Thor2021_crypto(ir, a, b, c, o);
input Instruction ir;
input Value a;
input Value b;
input Value c;
output Value o;

Value o1;
reg [4:0] shamt;
reg [7:0] sb_in;
reg [31:0] x;
reg [31:0] y;
reg [63:0] z1;
reg [31:0] z;


reg [7:0] sm4_sbox_table [0:255];

initial begin
sm4_sbox_table[0] = 8'hD6;
sm4_sbox_table[1] = 8'h90;
sm4_sbox_table[2] = 8'hE9;
sm4_sbox_table[3] = 8'hFE;
sm4_sbox_table[4] = 8'hCC;
sm4_sbox_table[5] = 8'hE1;
sm4_sbox_table[6] = 8'h3D;
sm4_sbox_table[7] = 8'hB7;
sm4_sbox_table[8] = 8'h16;
sm4_sbox_table[9] = 8'hB6;
sm4_sbox_table[10] = 8'h14;
sm4_sbox_table[11] = 8'hC2;
sm4_sbox_table[12] = 8'h28;
sm4_sbox_table[13] = 8'hFB;
sm4_sbox_table[14] = 8'h2C;
sm4_sbox_table[15] = 8'h05;
sm4_sbox_table[16] = 8'h2B;
sm4_sbox_table[17] = 8'h67;
sm4_sbox_table[18] = 8'h9A;
sm4_sbox_table[19] = 8'h76;
sm4_sbox_table[20] = 8'h2A;
sm4_sbox_table[21] = 8'hBE;
sm4_sbox_table[22] = 8'h04;
sm4_sbox_table[23] = 8'hC3;
sm4_sbox_table[24] = 8'hAA;
sm4_sbox_table[25] = 8'h44;
sm4_sbox_table[26] = 8'h13;
sm4_sbox_table[27] = 8'h26;
sm4_sbox_table[28] = 8'h49;
sm4_sbox_table[29] = 8'h86;
sm4_sbox_table[30] = 8'h06;
sm4_sbox_table[31] = 8'h99;
sm4_sbox_table[32] = 8'h9C;
sm4_sbox_table[33] = 8'h42;
sm4_sbox_table[34] = 8'h50;
sm4_sbox_table[35] = 8'hF4;
sm4_sbox_table[36] = 8'h91;
sm4_sbox_table[37] = 8'hEF;
sm4_sbox_table[38] = 8'h98;
sm4_sbox_table[39] = 8'h7A;
sm4_sbox_table[40] = 8'h33;
sm4_sbox_table[41] = 8'h54;
sm4_sbox_table[42] = 8'h0B;
sm4_sbox_table[43] = 8'h43;
sm4_sbox_table[44] = 8'hED;
sm4_sbox_table[45] = 8'hCF;
sm4_sbox_table[46] = 8'hAC;
sm4_sbox_table[47] = 8'h62;
sm4_sbox_table[48] = 8'hE4;
sm4_sbox_table[49] = 8'hB3;
sm4_sbox_table[50] = 8'h1C;
sm4_sbox_table[51] = 8'hA9;
sm4_sbox_table[52] = 8'hC9;
sm4_sbox_table[53] = 8'h08;
sm4_sbox_table[54] = 8'hE8;
sm4_sbox_table[55] = 8'h95;
sm4_sbox_table[56] = 8'h80;
sm4_sbox_table[57] = 8'hDF;
sm4_sbox_table[58] = 8'h94;
sm4_sbox_table[59] = 8'hFA;
sm4_sbox_table[60] = 8'h75;
sm4_sbox_table[61] = 8'h8F;
sm4_sbox_table[62] = 8'h3F;
sm4_sbox_table[63] = 8'hA6;
sm4_sbox_table[64] = 8'h47;
sm4_sbox_table[65] = 8'h07;
sm4_sbox_table[66] = 8'hA7;
sm4_sbox_table[67] = 8'hFC;
sm4_sbox_table[68] = 8'hF3;
sm4_sbox_table[69] = 8'h73;
sm4_sbox_table[70] = 8'h17;
sm4_sbox_table[71] = 8'hBA;
sm4_sbox_table[72] = 8'h83;
sm4_sbox_table[73] = 8'h59;
sm4_sbox_table[74] = 8'h3C;
sm4_sbox_table[75] = 8'h19;
sm4_sbox_table[76] = 8'hE6;
sm4_sbox_table[77] = 8'h85;
sm4_sbox_table[78] = 8'h4F;
sm4_sbox_table[79] = 8'hA8;
sm4_sbox_table[80] = 8'h68;
sm4_sbox_table[81] = 8'h6B;
sm4_sbox_table[82] = 8'h81;
sm4_sbox_table[83] = 8'hB2;
sm4_sbox_table[84] = 8'h71;
sm4_sbox_table[85] = 8'h64;
sm4_sbox_table[86] = 8'hDA;
sm4_sbox_table[87] = 8'h8B;
sm4_sbox_table[88] = 8'hF8;
sm4_sbox_table[89] = 8'hEB;
sm4_sbox_table[90] = 8'h0F;
sm4_sbox_table[91] = 8'h4B;
sm4_sbox_table[92] = 8'h70;
sm4_sbox_table[93] = 8'h56;
sm4_sbox_table[94] = 8'h9D;
sm4_sbox_table[95] = 8'h35;
sm4_sbox_table[96] = 8'h1E;
sm4_sbox_table[97] = 8'h24;
sm4_sbox_table[98] = 8'h0E;
sm4_sbox_table[99] = 8'h5E;
sm4_sbox_table[100] = 8'h63;
sm4_sbox_table[101] = 8'h58;
sm4_sbox_table[102] = 8'hD1;
sm4_sbox_table[103] = 8'hA2;
sm4_sbox_table[104] = 8'h25;
sm4_sbox_table[105] = 8'h22;
sm4_sbox_table[106] = 8'h7C;
sm4_sbox_table[107] = 8'h3B;
sm4_sbox_table[108] = 8'h01;
sm4_sbox_table[109] = 8'h21;
sm4_sbox_table[110] = 8'h78;
sm4_sbox_table[111] = 8'h87;
sm4_sbox_table[112] = 8'hD4;
sm4_sbox_table[113] = 8'h00;
sm4_sbox_table[114] = 8'h46;
sm4_sbox_table[115] = 8'h57;
sm4_sbox_table[116] = 8'h9F;
sm4_sbox_table[117] = 8'hD3;
sm4_sbox_table[118] = 8'h27;
sm4_sbox_table[119] = 8'h52;
sm4_sbox_table[120] = 8'h4C;
sm4_sbox_table[121] = 8'h36;
sm4_sbox_table[122] = 8'h02;
sm4_sbox_table[123] = 8'hE7;
sm4_sbox_table[124] = 8'hA0;
sm4_sbox_table[125] = 8'hC4;
sm4_sbox_table[126] = 8'hC8;
sm4_sbox_table[127] = 8'h9E;
sm4_sbox_table[128] = 8'hEA;
sm4_sbox_table[129] = 8'hBF;
sm4_sbox_table[130] = 8'h8A;
sm4_sbox_table[131] = 8'hD2;
sm4_sbox_table[132] = 8'h40; 
sm4_sbox_table[133] = 8'hC7;
sm4_sbox_table[134] = 8'h38;
sm4_sbox_table[135] = 8'hB5;
sm4_sbox_table[136] = 8'hA3;
sm4_sbox_table[137] = 8'hF7;
sm4_sbox_table[138] = 8'hF2;
sm4_sbox_table[139] = 8'hCE;
sm4_sbox_table[140] = 8'hF9;
sm4_sbox_table[141] = 8'h61;
sm4_sbox_table[142] = 8'h15;
sm4_sbox_table[143] = 8'hA1;
sm4_sbox_table[144] = 8'hE0;
sm4_sbox_table[145] = 8'hAE;
sm4_sbox_table[146] = 8'h5D;
sm4_sbox_table[147] = 8'hA4;
sm4_sbox_table[148] = 8'h9B;
sm4_sbox_table[149] = 8'h34;
sm4_sbox_table[150] = 8'h1A;
sm4_sbox_table[151] = 8'h55;
sm4_sbox_table[152] = 8'hAD;
sm4_sbox_table[153] = 8'h93;
sm4_sbox_table[154] = 8'h32;
sm4_sbox_table[155] = 8'h30;
sm4_sbox_table[156] = 8'hF5;
sm4_sbox_table[157] = 8'h8C;
sm4_sbox_table[158] = 8'hB1;
sm4_sbox_table[159] = 8'hE3;
sm4_sbox_table[160] = 8'h1D;
sm4_sbox_table[161] = 8'hF6;
sm4_sbox_table[162] = 8'hE2;
sm4_sbox_table[163] = 8'h2E;
sm4_sbox_table[164] = 8'h82;
sm4_sbox_table[165] = 8'h66;
sm4_sbox_table[166] = 8'hCA;
sm4_sbox_table[167] = 8'h60;
sm4_sbox_table[168] = 8'hC0;
sm4_sbox_table[169] = 8'h29;
sm4_sbox_table[170] = 8'h23;
sm4_sbox_table[171] = 8'hAB;
sm4_sbox_table[172] = 8'h0D;
sm4_sbox_table[173] = 8'h53;
sm4_sbox_table[174] = 8'h4E;
sm4_sbox_table[175] = 8'h6F;
sm4_sbox_table[176] = 8'hD5;
sm4_sbox_table[177] = 8'hDB;
sm4_sbox_table[178] = 8'h37;
sm4_sbox_table[179] = 8'h45;
sm4_sbox_table[180] = 8'hDE;
sm4_sbox_table[181] = 8'hFD;
sm4_sbox_table[182] = 8'h8E;
sm4_sbox_table[183] = 8'h2F;
sm4_sbox_table[184] = 8'h03;
sm4_sbox_table[185] = 8'hFF;
sm4_sbox_table[186] = 8'h6A;
sm4_sbox_table[187] = 8'h72;
sm4_sbox_table[188] = 8'h6D;
sm4_sbox_table[189] = 8'h6C;
sm4_sbox_table[190] = 8'h5B;
sm4_sbox_table[191] = 8'h51;
sm4_sbox_table[192] = 8'h8D;
sm4_sbox_table[193] = 8'h1B;
sm4_sbox_table[194] = 8'hAF;
sm4_sbox_table[195] = 8'h92;
sm4_sbox_table[196] = 8'hBB;
sm4_sbox_table[197] = 8'hDD;
sm4_sbox_table[198] = 8'hBC;
sm4_sbox_table[199] = 8'h7F;
sm4_sbox_table[200] = 8'h11;
sm4_sbox_table[201] = 8'hD9;
sm4_sbox_table[202] = 8'h5C;
sm4_sbox_table[203] = 8'h41;
sm4_sbox_table[204] = 8'h1F;
sm4_sbox_table[205] = 8'h10;
sm4_sbox_table[206] = 8'h5A;
sm4_sbox_table[207] = 8'hD8;
sm4_sbox_table[208] = 8'h0A;
sm4_sbox_table[209] = 8'hC1;
sm4_sbox_table[210] = 8'h31;
sm4_sbox_table[211] = 8'h88;
sm4_sbox_table[212] = 8'hA5;
sm4_sbox_table[213] = 8'hCD;
sm4_sbox_table[214] = 8'h7B;
sm4_sbox_table[215] = 8'hBD;
sm4_sbox_table[216] = 8'h2D;
sm4_sbox_table[217] = 8'h74;
sm4_sbox_table[218] = 8'hD0;
sm4_sbox_table[219] = 8'h12;
sm4_sbox_table[220] = 8'hB8;
sm4_sbox_table[221] = 8'hE5;
sm4_sbox_table[222] = 8'hB4;
sm4_sbox_table[223] = 8'hB0;
sm4_sbox_table[224] = 8'h89;
sm4_sbox_table[225] = 8'h69;
sm4_sbox_table[226] = 8'h97;
sm4_sbox_table[227] = 8'h4A;
sm4_sbox_table[228] = 8'h0C;
sm4_sbox_table[229] = 8'h96;
sm4_sbox_table[230] = 8'h77;
sm4_sbox_table[231] = 8'h7E;
sm4_sbox_table[232] = 8'h65;
sm4_sbox_table[233] = 8'hB9;
sm4_sbox_table[234] = 8'hF1;
sm4_sbox_table[235] = 8'h09;
sm4_sbox_table[236] = 8'hC5;
sm4_sbox_table[237] = 8'h6E;
sm4_sbox_table[238] = 8'hC6;
sm4_sbox_table[239] = 8'h84;
sm4_sbox_table[240] = 8'h18;
sm4_sbox_table[241] = 8'hF0;
sm4_sbox_table[242] = 8'h7D;
sm4_sbox_table[243] = 8'hEC;
sm4_sbox_table[244] = 8'h3A;
sm4_sbox_table[245] = 8'hDC;
sm4_sbox_table[246] = 8'h4D;
sm4_sbox_table[247] = 8'h20;
sm4_sbox_table[248] = 8'h79;
sm4_sbox_table[249] = 8'hEE;
sm4_sbox_table[250] = 8'h5F;
sm4_sbox_table[251] = 8'h3E;
sm4_sbox_table[252] = 8'hD7;
sm4_sbox_table[253] = 8'hCB;
sm4_sbox_table[254] = 8'h39;
sm4_sbox_table[255] = 8'h48;
end

function [7:0] sm4_box;
input [7:0] i;
	sm4_box = sm4_box_table[i];
endfunction

always_comb
case(ir.r1.opcode)
R1:
	case (ir.r1.func)
	SHA256SIG0:
		begin
			o1 = {a[6:0],a[31:7]} ^ {a[17:0],a[31:18]} ^ a[31:3];
			o = {{32{o1[31]}},o1[31:0]};
		end
	SHA256SIG1:
		begin
			o1 = {a[16:0],a[31:17]} ^ {a[18:0],a[31:19]} ^ a[31:10];
			o = {{32{o1[31]}},o1[31:0]};
		end
	SHA256SUM0:
		begin
			o1 = {a[1:0],a[31:2]} ^ {a[12:0],a[31:13]} ^ {a[21:0],a[31:22]};
			o = {{32{o1[31]}},o1[31:0]};
		end
	SHA256SUM1:
		begin
			o1 = {a[5:0],a[31:6]} ^ {a[10:0],a[31:11]} ^ {a[24:0],a[31:25]};
			o = {{32{o1[31]}},o1[31:0]};
		end
	SHA512SIG0:
		begin
			o = {a[0],a[63:1]} ^ {a[7:0],a[63:8]} ^ a[63:7];
		end
	SHA512SIG1:
		begin
			o = {a[18:0],a[63:19]} ^ {a[60:0],a[63:61]} ^ a[63:6];
		end
	SHA512SUM0:
		begin
			o = {a[27:0],a[63:28]} ^ {a[33:0],a[63:34]} ^ {a[38:0],a[63:39]};
		end
	SHA512SUM1:
		begin
			o = {a[13:0],a[63:14]} ^ {a[17:0],a[63:18]} ^ {a[40:0],a[63:41]};
		end
	SM3P0:
		begin
			o1 = {a[8:0],a[31:9]} ^ {a[16:0],a[31:17]} ^ a[31:0];
			o = {{32{o1[31]}},o1[31:0]};
		end
	SM3P0:
		begin
			o1 = {a[14:0],a[31:15]} ^ {a[22:0],a[31:23]} ^ a[31:0];
			o = {{32{o1[31]}},o1[31:0]};
		end
	default:	o = 64'd0;
	endcase
R3:
	case(ir.r3.func)
	SM4ED:
		begin
			shamt = {c[1:0],3'b0};
			sb_in = b >> shamt;	// extract byte
			x = {24'h000000,sm4_sbox(sb_in)};
			y = x ^ {x,8'd0} ^ {x,2'd0} ^ {x,18'd0} ^ {x & 6'h3f,26'd0} ^ {x & 8'hC0,10'd0};
			z1 = {32'd0,y} << shamt;
			z = z1[63:32] | z1[31:0];
			o1 = z ^ a[31:0];
			o = {{32{o1[31]}},o1[31:0]};
		end
	SM4KS:
		begin
			shamt = {c[1:0],3'b0};
			sb_in = b >> shamt;	// extract byte
			x = {24'h000000,sm4_sbox(sb_in)};
			y = x ^ {x & 3'd7,29'd0} ^ {x & 8'hFE,7'd0} ^ {x & 2'd1,23'd0} ^ {x & 8'hf8,13'd0};
			z1 = {32'd0,y} << shamt;
			z = z1[63:32] | z1[31:0];
			o1 = z ^ a[31:0];
			o = {{32{o1[31]}},o1[31:0]};
		end
	default:	o = 64'd0;
	endcase
default:	o = 64'd0;
endcase

endmodule
