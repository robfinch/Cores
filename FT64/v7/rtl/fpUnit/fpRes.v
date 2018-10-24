/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
	rob@birdcomputer.ca

	fpRes.v
		- floating point reciprocal estimate
		- zero clock cycle latency
		- IEEE 754 representation

	This source code is free for use and modification for
	non-commercial or evaluation purposes, provided this
	copyright statement and disclaimer remains present in
	the file.

	If the code is modified, please state the origin and
	note that the code has been modified.

	NO WARRANTY.
	THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF
	ANY KIND, WHETHER EXPRESS OR IMPLIED. The user must assume
	the entire risk of using the Work.

	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
	ANY INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES
	WHATSOEVER RELATING TO THE USE OF THIS WORK, OR YOUR
	RELATIONSHIP WITH THE AUTHOR.

	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU
	TO USE THE WORK IN APPLICATIONS OR SYSTEMS WHERE THE
	WORK'S FAILURE TO PERFORM CAN REASONABLY BE EXPECTED
	TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN LOSS
	OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK,
	AND YOU AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS
	FROM ANY CLAIMS OR LOSSES RELATING TO SUCH UNAUTHORIZED
	USE.

	This multiplier/divider handles denormalized numbers.
	The output format is of an internal expanded representation
	in preparation to be fed into a normalization unit, then
	rounding. Basically, it's the same as the regular format
	except the mantissa is doubled in size, the leading two
	bits of which are assumed to be whole bits.


	Floating Point Reciprocal Estimator

	- to estimate the reciprocal
	- negate the exponent
	- lookup the reciprocal of the fraction
	- NaN's are not altered

	Ref: Webpack8.1i Spartan3-4 xc3s1000-4ft256
=============================================================== */

module fpRes
#(	parameter WID=32)
(
	input [WID:1] i,
	input [WID:1] o
);
//	parameter WID = 32;
	localparam MSB = WID-1;
	localparam EMSB = WID==80 ? 14 : WID==64 ? 10 : WID==48 ? 10 : WID==42 ? 10 : WID==40 ?  9 : WID==32 ?  7 : WID==24 ?  6 : 4;
	localparam FMSB = WID==80 ? 63 : WID==64 ? 51 : WID==48 ? 35 : WID==42 ? 29 : WID==40 ? 28 : WID==32 ? 22 : WID==24 ? 15 : 9;
	localparam LSB = FMSB >= 32 ? 0 : WID-FMSB;	// only the first 32 bits are in the table

	// Decompose the operands
	wire sa;			// sign bit
	wire [EMSB:0] exp;	// exponent bits
	wire [FMSB+1:0] fract;
	wire inf;
	wire nan;
	reg [WID+1:1] recip;
	// an extra '1' is added as it is used during negation of exponent
	wire [2:0] expInc = recip[31] ? 1 : recip[30] ? 2 : recip[29] ? 3 : recip[28] ? 4 : 5;

	fpDecomp #(WID) u1 (.i(a), .sgn(sa), .exp(exp), .fract(fract), .inf(inf), .nan(nan) );

	assign o = 	nan ? i :					// nan's are not converted
				inf ? {sa,{WID-1{1'b0}}} :	// reciprocal of infinity is zero
				{sa,~(exp+expInc),recip[31:LSB]<<expInc};

	// estimate 1/d	8-bit accuracy
	always @(fract)
		case(fract[FMSB+1:FMSB+1-7])
		8'd001: recip=32'h10000000;
		8'd002: recip=32'h80000000;
		8'd003: recip=32'h55555555;
		8'd004: recip=32'h40000000;
		8'd005: recip=32'h33333333;
		8'd006: recip=32'h2AAAAAAA;
		8'd007: recip=32'h24924924;
		8'd008: recip=32'h20000000;
		8'd009: recip=32'h1C71C71C;
		8'd010: recip=32'h19999999;
		8'd011: recip=32'h1745D174;
		8'd012: recip=32'h15555555;
		8'd013: recip=32'h13B13B13;
		8'd014: recip=32'h12492492;
		8'd015: recip=32'h11111111;
		8'd016: recip=32'h10000000;
		8'd017: recip=32'hF0F0F0F;
		8'd018: recip=32'hE38E38E;
		8'd019: recip=32'hD79435E;
		8'd020: recip=32'hCCCCCCC;
		8'd021: recip=32'hC30C30C;
		8'd022: recip=32'hBA2E8BA;
		8'd023: recip=32'hB21642C;
		8'd024: recip=32'hAAAAAAA;
		8'd025: recip=32'hA3D70A3;
		8'd026: recip=32'h9D89D89;
		8'd027: recip=32'h97B425E;
		8'd028: recip=32'h9249249;
		8'd029: recip=32'h8D3DCB0;
		8'd030: recip=32'h8888888;
		8'd031: recip=32'h8421084;
		8'd032: recip=32'h8000000;
		8'd033: recip=32'h7C1F07C;
		8'd034: recip=32'h7878787;
		8'd035: recip=32'h7507507;
		8'd036: recip=32'h71C71C7;
		8'd037: recip=32'h6EB3E45;
		8'd038: recip=32'h6BCA1AF;
		8'd039: recip=32'h6906906;
		8'd040: recip=32'h6666666;
		8'd041: recip=32'h63E7063;
		8'd042: recip=32'h6186186;
		8'd043: recip=32'h5F417D0;
		8'd044: recip=32'h5D1745D;
		8'd045: recip=32'h5B05B05;
		8'd046: recip=32'h590B216;
		8'd047: recip=32'h572620A;
		8'd048: recip=32'h5555555;
		8'd049: recip=32'h5397829;
		8'd050: recip=32'h51EB851;
		8'd051: recip=32'h5050505;
		8'd052: recip=32'h4EC4EC4;
		8'd053: recip=32'h4D4873E;
		8'd054: recip=32'h4BDA12F;
		8'd055: recip=32'h4A7904A;
		8'd056: recip=32'h4924924;
		8'd057: recip=32'h47DC11F;
		8'd058: recip=32'h469EE58;
		8'd059: recip=32'h456C797;
		8'd060: recip=32'h4444444;
		8'd061: recip=32'h4325C53;
		8'd062: recip=32'h4210842;
		8'd063: recip=32'h4104104;
		8'd064: recip=32'h4000000;
		8'd065: recip=32'h3F03F03;
		8'd066: recip=32'h3E0F83E;
		8'd067: recip=32'h3D22635;
		8'd068: recip=32'h3C3C3C3;
		8'd069: recip=32'h3B5CC0E;
		8'd070: recip=32'h3A83A83;
		8'd071: recip=32'h39B0AD1;
		8'd072: recip=32'h38E38E3;
		8'd073: recip=32'h381C0E0;
		8'd074: recip=32'h3759F22;
		8'd075: recip=32'h369D036;
		8'd076: recip=32'h35E50D7;
		8'd077: recip=32'h3531DEC;
		8'd078: recip=32'h3483483;
		8'd079: recip=32'h33D91D2;
		8'd080: recip=32'h3333333;
		8'd081: recip=32'h329161F;
		8'd082: recip=32'h31F3831;
		8'd083: recip=32'h3159721;
		8'd084: recip=32'h30C30C3;
		8'd085: recip=32'h3030303;
		8'd086: recip=32'h2FA0BE8;
		8'd087: recip=32'h2F14990;
		8'd088: recip=32'h2E8BA2E;
		8'd089: recip=32'h2E05C0B;
		8'd090: recip=32'h2D82D82;
		8'd091: recip=32'h2D02D02;
		8'd092: recip=32'h2C8590B;
		8'd093: recip=32'h2C0B02C;
		8'd094: recip=32'h2B93105;
		8'd095: recip=32'h2B1DA46;
		8'd096: recip=32'h2AAAAAA;
		8'd097: recip=32'h2A3A0FD;
		8'd098: recip=32'h29CBC14;
		8'd099: recip=32'h295FAD4;
		8'd100: recip=32'h28F5C28;
		8'd101: recip=32'h288DF0C;
		8'd102: recip=32'h2828282;
		8'd103: recip=32'h27C4597;
		8'd104: recip=32'h2762762;
		8'd105: recip=32'h2702702;
		8'd106: recip=32'h26A439F;
		8'd107: recip=32'h2647C69;
		8'd108: recip=32'h25ED097;
		8'd109: recip=32'h2593F69;
		8'd110: recip=32'h253C825;
		8'd111: recip=32'h24E6A17;
		8'd112: recip=32'h2492492;
		8'd113: recip=32'h243F6F0;
		8'd114: recip=32'h23EE08F;
		8'd115: recip=32'h239E0D5;
		8'd116: recip=32'h234F72C;
		8'd117: recip=32'h2302302;
		8'd118: recip=32'h22B63CB;
		8'd119: recip=32'h226B902;
		8'd120: recip=32'h2222222;
		8'd121: recip=32'h21D9EAD;
		8'd122: recip=32'h2192E29;
		8'd123: recip=32'h214D021;
		8'd124: recip=32'h2108421;
		8'd125: recip=32'h20C49BA;
		8'd126: recip=32'h2082082;
		8'd127: recip=32'h2040810;
		8'd128: recip=32'h2000000;
		8'd129: recip=32'h1FC07F0;
		8'd130: recip=32'h1F81F81;
		8'd131: recip=32'h1F44659;
		8'd132: recip=32'h1F07C1F;
		8'd133: recip=32'h1ECC07B;
		8'd134: recip=32'h1E9131A;
		8'd135: recip=32'h1E573AC;
		8'd136: recip=32'h1E1E1E1;
		8'd137: recip=32'h1DE5D6E;
		8'd138: recip=32'h1DAE607;
		8'd139: recip=32'h1D77B65;
		8'd140: recip=32'h1D41D41;
		8'd141: recip=32'h1D0CB58;
		8'd142: recip=32'h1CD8568;
		8'd143: recip=32'h1CA4B30;
		8'd144: recip=32'h1C71C71;
		8'd145: recip=32'h1C3F8F0;
		8'd146: recip=32'h1C0E070;
		8'd147: recip=32'h1BDD2B8;
		8'd148: recip=32'h1BACF91;
		8'd149: recip=32'h1B7D6C3;
		8'd150: recip=32'h1B4E81B;
		8'd151: recip=32'h1B20364;
		8'd152: recip=32'h1AF286B;
		8'd153: recip=32'h1AC5701;
		8'd154: recip=32'h1A98EF6;
		8'd155: recip=32'h1A6D01A;
		8'd156: recip=32'h1A41A41;
		8'd157: recip=32'h1A16D3F;
		8'd158: recip=32'h19EC8E9;
		8'd159: recip=32'h19C2D14;
		8'd160: recip=32'h1999999;
		8'd161: recip=32'h1970E4F;
		8'd162: recip=32'h1948B0F;
		8'd163: recip=32'h1920FB4;
		8'd164: recip=32'h18F9C18;
		8'd165: recip=32'h18D3018;
		8'd166: recip=32'h18ACB90;
		8'd167: recip=32'h1886E5F;
		8'd168: recip=32'h1861861;
		8'd169: recip=32'h183C977;
		8'd170: recip=32'h1818181;
		8'd171: recip=32'h17F405F;
		8'd172: recip=32'h17D05F4;
		8'd173: recip=32'h17AD220;
		8'd174: recip=32'h178A4C8;
		8'd175: recip=32'h1767DCE;
		8'd176: recip=32'h1745D17;
		8'd177: recip=32'h1724287;
		8'd178: recip=32'h1702E05;
		8'd179: recip=32'h16E1F76;
		8'd180: recip=32'h16C16C1;
		8'd181: recip=32'h16A13CD;
		8'd182: recip=32'h1681681;
		8'd183: recip=32'h1661EC6;
		8'd184: recip=32'h1642C85;
		8'd185: recip=32'h1623FA7;
		8'd186: recip=32'h1605816;
		8'd187: recip=32'h15E75BB;
		8'd188: recip=32'h15C9882;
		8'd189: recip=32'h15AC056;
		8'd190: recip=32'h158ED23;
		8'd191: recip=32'h1571ED3;
		8'd192: recip=32'h1555555;
		8'd193: recip=32'h1539094;
		8'd194: recip=32'h151D07E;
		8'd195: recip=32'h1501501;
		8'd196: recip=32'h14E5E0A;
		8'd197: recip=32'h14CAB88;
		8'd198: recip=32'h14AFD6A;
		8'd199: recip=32'h149539E;
		8'd200: recip=32'h147AE14;
		8'd201: recip=32'h1460CBC;
		8'd202: recip=32'h1446F86;
		8'd203: recip=32'h142D662;
		8'd204: recip=32'h1414141;
		8'd205: recip=32'h13FB013;
		8'd206: recip=32'h13E22CB;
		8'd207: recip=32'h13C995A;
		8'd208: recip=32'h13B13B1;
		8'd209: recip=32'h13991C2;
		8'd210: recip=32'h1381381;
		8'd211: recip=32'h13698DF;
		8'd212: recip=32'h13521CF;
		8'd213: recip=32'h133AE45;
		8'd214: recip=32'h1323E34;
		8'd215: recip=32'h130D190;
		8'd216: recip=32'h12F684B;
		8'd217: recip=32'h12E025C;
		8'd218: recip=32'h12C9FB4;
		8'd219: recip=32'h12B404A;
		8'd220: recip=32'h129E412;
		8'd221: recip=32'h1288B01;
		8'd222: recip=32'h127350B;
		8'd223: recip=32'h125E227;
		8'd224: recip=32'h1249249;
		8'd225: recip=32'h1234567;
		8'd226: recip=32'h121FB78;
		8'd227: recip=32'h120B470;
		8'd228: recip=32'h11F7047;
		8'd229: recip=32'h11E2EF3;
		8'd230: recip=32'h11CF06A;
		8'd231: recip=32'h11BB4A4;
		8'd232: recip=32'h11A7B96;
		8'd233: recip=32'h1194538;
		8'd234: recip=32'h1181181;
		8'd235: recip=32'h116E068;
		8'd236: recip=32'h115B1E5;
		8'd237: recip=32'h11485F0;
		8'd238: recip=32'h1135C81;
		8'd239: recip=32'h112358E;
		8'd240: recip=32'h1111111;
		8'd241: recip=32'h10FEF01;
		8'd242: recip=32'h10ECF56;
		8'd243: recip=32'h10DB20A;
		8'd244: recip=32'h10C9714;
		8'd245: recip=32'h10B7E6E;
		8'd246: recip=32'h10A6810;
		8'd247: recip=32'h10953F3;
		8'd248: recip=32'h1084210;
		8'd249: recip=32'h1073260;
		8'd250: recip=32'h10624DD;
		8'd251: recip=32'h105197F;
		8'd252: recip=32'h1041041;
		8'd253: recip=32'h103091B;
		8'd254: recip=32'h1020408;
		8'd255: recip=32'h1010101;
		endcase

endmodule


