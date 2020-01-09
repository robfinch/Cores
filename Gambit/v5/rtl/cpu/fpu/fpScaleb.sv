// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpScaleb.sv
//		- floating point Scaleb()
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

module fpScaleb(clk, ce, a, b, o);
parameter FPWID=80;
`include "fpSize.sv"
input clk;
input ce;
input [FPWID-1+`EXTRA_BITS:0] a;
input [FPWID-1+`EXTRA_BITS:0] b;
output reg [FPWID-1+`EXTRA_BITS:0] o;

wire [4:0] cmp_o;
wire nana, nanb;
wire xza, mza;

wire [EMSB:0] infXp = {EMSB+1{1'b1}};
wire [EMSB:0] xa;
wire xinfa;
wire anan;
reg anan1;
wire sa;
reg sa1, sa2;
wire [FMSB:0] ma;
reg [EMSB+1:0] xa1a, xa1b, xa2;
reg [FMSB:0] ma1, ma2;
wire bs = b[FPWID-1];
reg bs1;

fpDecomp #(FPWID) u1 (.i(a), .sgn(sa), .exp(xa), .man(ma), .fract(), .xz(xza), .mz(), .vz(), .inf(), .xinf(xinfa), .qnan(), .snan(), .nan(anan));

// ----------------------------------------------------------------------------
// Clock cycle 1
// ----------------------------------------------------------------------------
always @(posedge clk)
	if (ce) xa1a <= xa;
always @(posedge clk)
	if (ce) xa1b <= xa + b;
always @(posedge clk)
	if (ce) bs1 <= bs;
always @(posedge clk)
	if (ce) anan1 <= anan;
always @(posedge clk)
	if (ce) sa1 <= sa;
always @(posedge clk)
	if (ce) ma1 <= ma;

// ----------------------------------------------------------------------------
// Clock cycle 2
// ----------------------------------------------------------------------------
always @(posedge clk)
	if (ce) sa2 <= sa1;
always @(posedge clk)
if (ce) begin
	if (anan1) begin
		xa2 <= xa1a;
		ma2 <= ma1;
	end
	// Underflow? -> limit exponent to zero
	else if (bs1 & xa1b[EMSB+1]) begin
		xa2 <= 1'd0;
		ma2 <= ma1;
	end
	// overflow ? -> set value to infinity
	else if (~bs1 & xa1b[EMSB+1]) begin
		xa2 <= infXp;
		ma2 <= 1'd0;
	end
	else begin
		xa2 <= xa1b;
		ma2 <= ma1;
	end
end

assign o = {sa2,xa2,ma2};

endmodule
