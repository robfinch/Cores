`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	BCDMath.sv
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
//
// Could use the following approach for add/sub but it ends up being larger
// than using an adjustment lookup table.

module BCDAddNyb(ci,a,b,o,c);
input ci;		// carry input
input [3:0] a;
input [3:0] b;
output [3:0] o;
output c;

wire c0;

reg [4:0] hsN0;
always  @*
begin
	hsN0 = a[3:0] + b[3:0] + ci;
	if (hsN0 > 5'd9)
		hsN0 = hsN0 + 3'd6;
end		
assign o = hsN0[3:0];
assign c = hsN0[4];

endmodule

module BCDAdd(ci,a,b,o,c);
input ci;		// carry input
input [7:0] a;
input [7:0] b;
output [7:0] o;
output c;

wire c0,c1;

wire [4:0] hsN0 = a[3:0] + b[3:0] + ci;
wire [4:0] hsN1 = a[7:4] + b[7:4] + c0;

BCDAddAdjust u1 (hsN0,o[3:0],c0);
BCDAddAdjust u2 (hsN1,o[7:4],c);

endmodule

module BCDAdd4(ci,a,b,o,c,c8);
input ci;		// carry input
input [15:0] a;
input [15:0] b;
output [15:0] o;
output c;
output c8;

wire c0,c1,c2;
assign c8 = c1;

wire [4:0] hsN0 = a[3:0] + b[3:0] + ci;
wire [4:0] hsN1 = a[7:4] + b[7:4] + c0;
wire [4:0] hsN2 = a[11:8] + b[11:8] + c1;
wire [4:0] hsN3 = a[15:12] + b[15:12] + c2;

BCDAddAdjust u1 (hsN0,o[3:0],c0);
BCDAddAdjust u2 (hsN1,o[7:4],c1);
BCDAddAdjust u3 (hsN2,o[11:8],c2);
BCDAddAdjust u4 (hsN3,o[15:12],c);

endmodule

module BCDAddN(ci,a,b,o,co);
parameter N=24;
input ci;		// carry input
input [N*4-1:0] a;
input [N*4-1:0] b;
output [N*4-1:0] o;
output co;

genvar g;
generate begin : gBCDAddN
reg [4:0] hsN [0:N-1];
wire [N:0] c;

assign c[0] = ci;
assign co = c[N];

for (g = 0; g < N; g = g + 1)
	always @*
		hsN[g] = a[g*4+3:g*4] + b[g*4+3:g*4] + c[g];

for (g = 0; g < N; g = g + 1)
	BCDAddAdjust u1 (hsN[g],o[g*4+3:g*4],c[g+1]);
end
endgenerate

endmodule

module BCDSub(ci,a,b,o,c);
input ci;		// carry input
input [7:0] a;
input [7:0] b;
output [7:0] o;
output c;

wire c0,c1;

wire [4:0] hdN0 = a[3:0] - b[3:0] - ci;
wire [4:0] hdN1 = a[7:4] - b[7:4] - c0;

BCDSubAdjust u1 (hdN0,o[3:0],c0);
BCDSubAdjust u2 (hdN1,o[7:4],c);

endmodule

module BCDSub4(ci,a,b,o,c,c8);
input ci;		// carry input
input [15:0] a;
input [15:0] b;
output [15:0] o;
output c;
output c8;

wire c0,c1,c2;
assign c8 = c1;

wire [4:0] hdN0 = a[3:0] - b[3:0] - ci;
wire [4:0] hdN1 = a[7:4] - b[7:4] - c0;
wire [4:0] hdN2 = a[11:8] - b[11:8] - c1;
wire [4:0] hdN3 = a[15:12] - b[15:12] - c2;

BCDSubAdjust u1 (hdN0,o[3:0],c0);
BCDSubAdjust u2 (hdN1,o[7:4],c1);
BCDSubAdjust u3 (hdN2,o[11:8],c2);
BCDSubAdjust u4 (hdN3,o[15:12],c);

endmodule

module BCDSubN(ci,a,b,o,co);
parameter N=24;
input ci;		// carry input
input [N*4-1:0] a;
input [N*4-1:0] b;
output [N*4-1:0] o;
output co;

genvar g;
generate begin : gBCDSubN
reg [4:0] hdN [0:N-1];
wire [N:0] c;

assign c[0] = ci;
assign co = c[N];

for (g = 0; g < N; g = g + 1)
	always @*
		hdN[g] = a[g*4+3:g*4] - b[g*4+3:g*4] - c[g];

for (g = 0; g < N; g = g + 1)
	BCDSubAdjust u1 (hdN[g],o[g*4+3:g*4],c[g+1]);
end
endgenerate

endmodule

module BCDAddAdjust(i,o,c);
input [4:0] i;
output [3:0] o;
reg [3:0] o;
output c;
reg c;
always @(i)
case(i)
5'h0: begin o = 4'h0; c = 1'b0; end
5'h1: begin o = 4'h1; c = 1'b0; end
5'h2: begin o = 4'h2; c = 1'b0; end
5'h3: begin o = 4'h3; c = 1'b0; end
5'h4: begin o = 4'h4; c = 1'b0; end
5'h5: begin o = 4'h5; c = 1'b0; end
5'h6: begin o = 4'h6; c = 1'b0; end
5'h7: begin o = 4'h7; c = 1'b0; end
5'h8: begin o = 4'h8; c = 1'b0; end
5'h9: begin o = 4'h9; c = 1'b0; end
5'hA: begin o = 4'h0; c = 1'b1; end
5'hB: begin o = 4'h1; c = 1'b1; end
5'hC: begin o = 4'h2; c = 1'b1; end
5'hD: begin o = 4'h3; c = 1'b1; end
5'hE: begin o = 4'h4; c = 1'b1; end
5'hF: begin o = 4'h5; c = 1'b1; end
5'h10:	begin o = 4'h6; c = 1'b1; end
5'h11:	begin o = 4'h7; c = 1'b1; end
5'h12:	begin o = 4'h8; c = 1'b1; end
5'h13:	begin o = 4'h9; c = 1'b1; end
default:	begin o = 4'h9; c = 1'b1; end
endcase
endmodule

module BCDSubAdjust(i,o,c);
input [4:0] i;
output [3:0] o;
reg [3:0] o;
output c;
reg c;
always @(i)
case(i)
5'h0: begin o = 4'h0; c = 1'b0; end
5'h1: begin o = 4'h1; c = 1'b0; end
5'h2: begin o = 4'h2; c = 1'b0; end
5'h3: begin o = 4'h3; c = 1'b0; end
5'h4: begin o = 4'h4; c = 1'b0; end
5'h5: begin o = 4'h5; c = 1'b0; end
5'h6: begin o = 4'h6; c = 1'b0; end
5'h7: begin o = 4'h7; c = 1'b0; end
5'h8: begin o = 4'h8; c = 1'b0; end
5'h9: begin o = 4'h9; c = 1'b0; end
5'h16: begin o = 4'h0; c = 1'b1; end
5'h17: begin o = 4'h1; c = 1'b1; end
5'h18: begin o = 4'h2; c = 1'b1; end
5'h19: begin o = 4'h3; c = 1'b1; end
5'h1A: begin o = 4'h4; c = 1'b1; end
5'h1B: begin o = 4'h5; c = 1'b1; end
5'h1C: begin o = 4'h6; c = 1'b1; end
5'h1D: begin o = 4'h7; c = 1'b1; end
5'h1E: begin o = 4'h8; c = 1'b1; end
5'h1F: begin o = 4'h9; c = 1'b1; end
default: begin o = 4'h9; c = 1'b1; end
endcase
endmodule

// Multiply two BCD digits
// Method used is table lookup
module BCDMul1(a,b,o);
input [3:0] a;
input [3:0] b;
output [7:0] o;
reg [7:0] o;

always @(a or b)
casex({a,b})
8'h00: o = 8'h00;
8'h01: o = 8'h00;
8'h02: o = 8'h00;
8'h03: o = 8'h00;
8'h04: o = 8'h00;
8'h05: o = 8'h00;
8'h06: o = 8'h00;
8'h07: o = 8'h00;
8'h08: o = 8'h00;
8'h09: o = 8'h00;
8'h10: o = 8'h00;
8'h11: o = 8'h01;
8'h12: o = 8'h02;
8'h13: o = 8'h03;
8'h14: o = 8'h04;
8'h15: o = 8'h05;
8'h16: o = 8'h06;
8'h17: o = 8'h07;
8'h18: o = 8'h08;
8'h19: o = 8'h09;
8'h20: o = 8'h00;
8'h21: o = 8'h02;
8'h22: o = 8'h04;
8'h23: o = 8'h06;
8'h24: o = 8'h08;
8'h25: o = 8'h10;
8'h26: o = 8'h12;
8'h27: o = 8'h14;
8'h28: o = 8'h16;
8'h29: o = 8'h18;
8'h30: o = 8'h00;
8'h31: o = 8'h03;
8'h32: o = 8'h06;
8'h33: o = 8'h09;
8'h34: o = 8'h12;
8'h35: o = 8'h15;
8'h36: o = 8'h18;
8'h37: o = 8'h21;
8'h38: o = 8'h24;
8'h39: o = 8'h27;
8'h40: o = 8'h00;
8'h41: o = 8'h04;
8'h42: o = 8'h08;
8'h43: o = 8'h12;
8'h44: o = 8'h16;
8'h45: o = 8'h20;
8'h46: o = 8'h24;
8'h47: o = 8'h28;
8'h48: o = 8'h32;
8'h49: o = 8'h36;
8'h50: o = 8'h00;
8'h51: o = 8'h05;
8'h52: o = 8'h10;
8'h53: o = 8'h15;
8'h54: o = 8'h20;
8'h55: o = 8'h25;
8'h56: o = 8'h30;
8'h57: o = 8'h35;
8'h58: o = 8'h40;
8'h59: o = 8'h45;
8'h60: o = 8'h00;
8'h61: o = 8'h06;
8'h62: o = 8'h12;
8'h63: o = 8'h18;
8'h64: o = 8'h24;
8'h65: o = 8'h30;
8'h66: o = 8'h36;
8'h67: o = 8'h42;
8'h68: o = 8'h48;
8'h69: o = 8'h54;
8'h70: o = 8'h00;
8'h71: o = 8'h07;
8'h72: o = 8'h14;
8'h73: o = 8'h21;
8'h74: o = 8'h28;
8'h75: o = 8'h35;
8'h76: o = 8'h42;
8'h77: o = 8'h49;
8'h78: o = 8'h56;
8'h79: o = 8'h63;
8'h80: o = 8'h00;
8'h81: o = 8'h08;
8'h82: o = 8'h16;
8'h83: o = 8'h24;
8'h84: o = 8'h32;
8'h85: o = 8'h40;
8'h86: o = 8'h48;
8'h87: o = 8'h56;
8'h88: o = 8'h64;
8'h89: o = 8'h72;
8'h90: o = 8'h00;
8'h91: o = 8'h09;
8'h92: o = 8'h18;
8'h93: o = 8'h27;
8'h94: o = 8'h36;
8'h95: o = 8'h45;
8'h96: o = 8'h54;
8'h97: o = 8'h63;
8'h98: o = 8'h72;
8'h99: o = 8'h81;
default:	o = 8'h00;
endcase
endmodule


// Multiply two pairs of BCD digits
// handles from 0x0 to 99x99
module BCDMul2(a,b,o);
input [7:0] a;
input [7:0] b;
output [15:0] o;

wire [7:0] p1,p2,p3,p4;
wire [15:0] s1;

BCDMul1 u1 (a[3:0],b[3:0],p1);
BCDMul1 u2 (a[7:4],b[3:0],p2);
BCDMul1 u3 (a[3:0],b[7:4],p3);
BCDMul1 u4 (a[7:4],b[7:4],p4);

BCDAdd4 u5 (1'b0,{p4,p1},{4'h0,p2,4'h0},s1);
BCDAdd4 u6 (1'b0,s1,{4'h0,p3,4'h0},o);

endmodule

module BCDMul4(a,b,o);
input [15:0] a;
input [15:0] b;
output [31:0] o;

wire [15:0] p1,p2,p3,p4;
wire [31:0] s1;

BCDMul2 u1 (a[7:0],b[7:0],p1);
BCDMul2 u2 (a[15:8],b[7:0],p2);
BCDMul2 u3 (a[7:0],b[15:8],p3);
BCDMul2 u4 (a[15:8],b[15:8],p4);

BCDAddN #(.N(8)) u5 (1'b0,{p4,p1},{8'h0,p2,8'h0},s1);
BCDAddN #(.N(8)) u6 (1'b0,s1,{8'h0,p3,8'h0},o);

endmodule

module BCDMul8(a,b,o);
input [31:0] a;
input [31:0] b;
output [63:0] o;

wire [31:0] p1,p2,p3,p4;
wire [63:0] s1;

BCDMul4 u1 (a[15:0],b[15:0],p1);
BCDMul4 u2 (a[31:16],b[15:0],p2);
BCDMul4 u3 (a[15:0],b[31:16],p3);
BCDMul4 u4 (a[31:16],b[31:16],p4);

BCDAddN #(.N(16)) u5 (1'b0,{p4,p1},{16'h0,p2,16'h0},s1);
BCDAddN #(.N(16)) u6 (1'b0,s1,{16'h0,p3,16'h0},o);

endmodule

module BCDMul16(a,b,o);
input [63:0] a;
input [63:0] b;
output [127:0] o;

wire [63:0] p1,p2,p3,p4;
wire [127:0] s1;

BCDMul8 u1 (a[31:0],b[31:0],p1);
BCDMul8 u2 (a[63:32],b[31:0],p2);
BCDMul8 u3 (a[31:0],b[63:32],p3);
BCDMul8 u4 (a[63:32],b[63:32],p4);

BCDAddN #(.N(32)) u5 (1'b0,{p4,p1},{32'h0,p2,32'h0},s1);
BCDAddN #(.N(32)) u6 (1'b0,s1,{32'h0,p3,32'h0},o);

endmodule

module BCDMul32(a,b,o);
input [127:0] a;
input [127:0] b;
output [255:0] o;

wire [127:0] p1,p2,p3,p4;
wire [255:0] s1;

BCDMul16 u1 (a[63:0],b[63:0],p1);
BCDMul16 u2 (a[127:64],b[63:0],p2);
BCDMul16 u3 (a[63:0],b[127:64],p3);
BCDMul16 u4 (a[127:64],b[127:64],p4);

BCDAddN #(.N(64)) u5 (1'b0,{p4,p1},{64'h0,p2,64'h0},s1);
BCDAddN #(.N(64)) u6 (1'b0,s1,{64'h0,p3,64'h0},o);

endmodule

module BCDMul_tb();

wire [15:0] o1,o2,o3,o4;

BCDMul2 u1 (8'h00,8'h00,o1);
BCDMul2 u2 (8'h99,8'h99,o2);
BCDMul2 u3 (8'h25,8'h18,o3);
BCDMul2 u4 (8'h37,8'h21,o4);

endmodule

module BinToBCD(i, o);
input [7:0] i;
output [11:0] o;

reg [11:0] tbl [0:255];

genvar g;
generate begin : gTbl
reg [3:0] n0 [0:255];
reg [3:0] n1 [0:255];
reg [3:0] n2 [0:255];

for (g = 0; g < 256; g = g + 1) begin
	initial begin
		n0[g] = g % 10;
		n1[g] = g / 10;
		n2[g] = g / 100;
		tbl[g] <= {n2[g],n1[g],n0[g]};
	end
end

assign o = tbl[i];

end
endgenerate

endmodule

// Perform a logical shift to the right.
module BCDSRL(ci, i, o, co);
parameter N=4;
input ci;
input [N*4-1:0] i;
output reg [N*4-1:0] o;
output co;

reg [N:0] c;

genvar g;
generate begin
always @*
	c[N] = ci;
for (g = N - 1; g >= 0; g = g - 1)
always @*
	c[g] = i[g*4];
for (g = N - 1; g >= 0; g = g - 1)
always @*
begin
	o[g*4+3:g*4] = {1'b0,i[g*4+3:g*4+1]};
	// Because there is a divide by two, the value will range between 0 and 4.
	// Adding 5 keeps it within deicmal boundaries of 0 to 9. No carry can be
	// generated
	if (c[N+1])
		o[g*4+3:g*4] = o[g*4+3:g*4] + 4'd5;
end
	assign co = c[0];
end
endgenerate

endmodule
