// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	i2f.v
//  - convert integer to floating point
//  - parameterized width
//  - IEEE 754 representation
//  - pipelineable
//  - single cycle latency
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

module i2f
#(	parameter FPWID = 64)
(
	input clk,
	input ce,
	input op,						// 1 = signed, 0 = unsigned
	input [2:0] rm,			// rounding mode
	input [FPWID-1:0] i,		// integer input
	output [FPWID-1:0] o		// float output
);
`include "fpSize.sv"

wire [EMSB:0] zeroXp = {EMSB{1'b1}};

wire iz;			// zero input ?
wire [MSB:0] imag;	// get magnitude of i
wire [MSB:0] imag1 = (op & i[MSB]) ? -i : i;
wire [7:0] lz;		// count the leading zeros in the number
wire [EMSB:0] wd;	// compute number of whole digits
wire so;			// copy the sign of the input (easy)
wire [2:0] rmd;

delay1 #(3)   u0 (.clk(clk), .ce(ce), .i(rm),     .o(rmd) );
delay1 #(1)   u1 (.clk(clk), .ce(ce), .i(i==0),   .o(iz) );
delay1 #(FPWID) u2 (.clk(clk), .ce(ce), .i(imag1),  .o(imag) );
delay1 #(1)   u3 (.clk(clk), .ce(ce), .i(i[MSB]), .o(so) );
generate 
if (FPWID==128) begin
cntlz128Reg    u4 (.clk(clk), .ce(ce), .i(imag1), .o(lz) );
end else if (FPWID==96) begin
cntlz96Reg    u4 (.clk(clk), .ce(ce), .i(imag1), .o(lz[6:0]) );
assign lz[7]=1'b0;
end else if (FPWID==84) begin
cntlz96Reg    u4 (.clk(clk), .ce(ce), .i({imag1,12'hfff}), .o(lz[6:0]) );
assign lz[7]=1'b0;
end else if (FPWID==80) begin
cntlz80Reg    u4 (.clk(clk), .ce(ce), .i(imag1), .o(lz[6:0]) );
assign lz[7]=1'b0;
end else if (FPWID==64) begin
cntlz64Reg    u4 (.clk(clk), .ce(ce), .i(imag1), .o(lz[6:0]) );
assign lz[7]=1'b0;
end else begin
cntlz32Reg    u4 (.clk(clk), .ce(ce), .i(imag1), .o(lz[5:0]) );
assign lz[7:6]=2'b00;
end
endgenerate

assign wd = zeroXp - 1 + FPWID - lz;	// constant except for lz

wire [EMSB:0] xo = iz ? 0 : wd;
wire [MSB:0] simag = imag << lz;		// left align number

wire g =  simag[EMSB+2];	// guard bit (lsb)
wire r =  simag[EMSB+1];	// rounding bit
wire s = |simag[EMSB:0];	// "sticky" bit
reg rnd;

// Compute the round bit
always @(rmd,g,r,s,so)
	case (rmd)
	3'd0:	rnd = (g & r) | (r & s);	// round to nearest even
	3'd1:	rnd = 0;					// round to zero (truncate)
	3'd2:	rnd = (r | s) & !so;		// round towards +infinity
	3'd3:	rnd = (r | s) & so;			// round towards -infinity
	3'd4:   rnd = (r | s);
	endcase

// "hide" the leading one bit = MSB-1
// round the result
wire [FMSB:0] mo = simag[MSB-1:EMSB+1]+rnd;

assign o = {op & so,xo,mo};

endmodule
