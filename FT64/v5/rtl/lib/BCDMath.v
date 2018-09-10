`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2012  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	BCDMath.v
//
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
//
//=============================================================================
//
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

module BCDAdd4(ci,a,b,o,c);
input ci;		// carry input
input [15:0] a;
input [15:0] b;
output [15:0] o;
output c;

wire c0,c1,c2;

wire [4:0] hsN0 = a[3:0] + b[3:0] + ci;
wire [4:0] hsN1 = a[7:4] + b[7:4] + c0;
wire [4:0] hsN2 = a[11:8] + b[11:8] + c1;
wire [4:0] hsN3 = a[15:12] + b[15:12] + c2;

BCDAddAdjust u1 (hsN0,o[3:0],c0);
BCDAddAdjust u2 (hsN1,o[7:4],c1);
BCDAddAdjust u3 (hsN2,o[11:8],c2);
BCDAddAdjust u4 (hsN3,o[15:12],c);

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

module BCDMul_tb();

wire [15:0] o1,o2,o3,o4;

BCDMul2 u1 (8'h00,8'h00,o1);
BCDMul2 u2 (8'h99,8'h99,o2);
BCDMul2 u3 (8'h25,8'h18,o3);
BCDMul2 u4 (8'h37,8'h21,o4);

endmodule
