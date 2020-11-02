// ============================================================================
//        __
//   \\__/ o\    (C) 2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpToPosit.sv
//    - floating point to posit number convertor
//    - can issue every clock cycle
//    - parameterized width
//    - IEEE 754 representation
//
// Parts of this code originated from FP_to_Posit.v by Manish Kumar Jaiswal
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

import fp::*;
import posit::*;

module fpToPosit(i, o);
input [FPWID-1:0] i;
output reg [FPWID-1:0] o;

parameter BIAS = {1'b0,{EMSB{1'b1}}};
localparam N = FPWID;
localparam E = EMSB+1;
localparam Bs = $clog2(FPWID-1);

// operands sign,exponent,significand
wire sa;
wire [EMSB:0] xa;
wire [FMSB:0] ma;
wire [FMSB+1:0] fracta;
wire adn;
wire az;
wire xainf;
wire aInf;
wire aNan;

fpDecomp #(.FPWID(FPWID)) u1 (.i(i), .sgn(sa), .exp(xa), .man(ma), .fract(fracta), .xz(adn), .vz(az), .xinf(xaInf), .inf(aInf), .nan(aNan) );
assign sgno = sa;
wire [$clog2(FMSB+1):0] lzcnt;
generate begin : gCntlz
case(FPWID)
16: begin cntlz16 u2 ({fracta,5'h1f},lzcnt); end  //1-5-10
20: begin cntlz16 u2 ({fracta,2'h3},lzcnt); end //1-6-13
32: begin cntlz32 u2 ({fracta,8'hFF},lzcnt); end  // 1-8-23
40: begin cntlz32 u2 ({fracta,2'h3},lzcnt); end // 1-10-29
52: begin cntlz48 u2 ({fracta,7'h7F},lzcnt); end  // 1-11-40
64: begin cntlz64 u2 ({fracta,11'h7FF},lzcnt); end  // 1-11-52
80: begin cntlz80 u2 ({fracta,15'h7FFF},lzcnt); end  // 1-15-64
default:
  always @*
    begin
      $display("fpToPosit: Unsupported size");
      $finish;
    end
endcase
end
endgenerate

wire [N-1:0] sig_tmp = {fracta,{E{1'b0}}} << lzcnt;

// Convert exponent to twos complement from BIAS offset
wire [E:0] exp = xa - BIAS - lzcnt;
wire sxp = exp[E];  // get exponent sign
wire [E:0] absexp = sxp ? -exp : exp;  // get absolute value
wire [es-1:0] e_o = (sxp & |absexp[es-1:0]) ? exp[es-1:0] : absexp[es-1:0];
wire [E-es-1:0] r_o = (~sxp || (sxp & |absexp[es-1:0])) ? {{Bs{1'b0}},absexp[E-1:es]} + 1'b1 : {{Bs{1'b0}},absexp[E-1:es]};
// Exponent and Significand Packing
wire [2*N-1:0] tmp = {{N{~sxp}},sxp,e_o,sig_tmp[N-2:es]};

// Including Regime bits in Exponent-Significand Packing
wire [Bs-1:0] diff_b;

generate begin : gDiffb
	if (E-es > Bs)
	  assign diff_b = |r_o[E-es-1:Bs] ? {{(Bs-2){1'b1}},2'b01} : r_o[Bs-1:0];
	else
	  assign diff_b = r_o;
end
endgenerate

wire [2*N-1:0] tmp1 = tmp >> diff_b;
wire [N-1:0] tmp1s = sa ? -tmp1[N-1:0] : tmp1[N-1:0];

always @*
casez({az,aInf,aNan,~sig_tmp[N-1]})
4'b1???: o = {FPWID{1'b0}};
4'b01??: o = {1'b1,{FPWID-1{1'b0}}};
4'b001?: o = {1'b1,{FPWID-1{1'b0}}};
4'b0001: o = {1'b1,{FPWID-1{1'b0}}};
default:  o = {sa,tmp1s[N-1:1]};
endcase

endmodule
