`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpNextAfter.v
//		- floating point nextafter()
//		- return next representable value
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

module fpNextAfter(clk, ce, a, b, o);
parameter WID=80;
`include "fpSize.sv"
input clk;
input ce;
input [WID-1:0] a;
input [WID-1:0] b;
output reg [WID-1:0] o;

wire [4:0] cmp_o;
wire nana, nanb;
wire xza, mza;

fp_cmp_unit #(WID) u1 (.a(a), .b(b), .o(cmp_o), .nanx(nanxab) );
fpDecomp u2 (.i(a), .sgn(), .exp(), .man(), .fract(), .xz(xza), .mz(mza), .vz(), .inf(), .xinf(), .qnan(), .snan(), .nan(nana));
fpDecomp u3 (.i(b), .sgn(), .exp(), .man(), .fract(), .xz(), .mz(), .vz(), .inf(), .xinf(), .qnan(), .snan(), .nan(nanb));
wire [WID-1:0] ap1 = a + 2'd1;
wire [WID-1:0] am1 = a - 2'd1;
wire [EMSB:0] infXp = {EMSB+1{1'b1}};

always  @(posedge clk)
if (ce)
	casez({a[WID-1],cmp_o})
	6'b?1????:	o <= nana ? a : b;	// Unordered
	6'b????1?:	o <= a;							// a,b Equal
	6'b0????1:
		if (ap1[WID-2:FMSB+1]==infXp)
			o <= {a[WID-1:FMSB+1],{FMSB+1{1'b0}}};
		else
			o <= ap1;
	6'b0????0:
		if (xza && mza)
			;
		else
			o <= am1;
	6'b1????0:
		if (ap1[WID-2:FMSB+1]==infXp)
			o <= {a[WID-1:FMSB+1],{FMSB+1{1'b0}}};
		else
			o <= ap1;
	6'b1????1:
		if (xza && mza)
			;
		else
			o <= am1;
	default:	o <= a;
	endcase

endmodule
