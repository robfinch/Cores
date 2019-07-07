// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpRound.v
//    - floating point rounding unit
//    - parameterized width
//    - IEEE 754 representation
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
// ============================================================================

`include "fpConfig.sv"

module fpRound(clk, ce, rm, i, o);
parameter FPWID = 64;
`include "fpSize.sv"
input clk;
input ce;
input [2:0] rm;			// rounding mode
input [MSB+3:0] i;		// intermediate format input
output [MSB:0] o;		// rounded output

//------------------------------------------------------------
// variables
wire so;
wire [EMSB:0] xo;
reg  [FMSB:0] mo;
reg [EMSB:0] xo1;
reg [FMSB+3:0] mo1;
wire xInf = &i[MSB+2:FMSB+4];
wire so0 = i[MSB+3];
assign o = {so,xo,mo};

wire g = i[2];	// guard bit: always the same bit for all operations
wire r = i[1];	// rounding bit
wire s = i[0];	// sticky bit
reg rnd;

//------------------------------------------------------------
// Clock #1
// - determine round amount (add 1 or 0)
//------------------------------------------------------------

`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
if (ce) xo1 <= i[MSB+2:FMSB+4];
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
if (ce) mo1 <= i[FMSB+3:0];

// Compute the round bit
// Infinities and NaNs are not rounded!
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
if (ce)
	casez ({xInf,rm})
	4'b0000:	rnd <= (g & r) | (r & s);	// round to nearest even
	4'b0001:	rnd <= 1'd0;							// round to zero (truncate)
	4'b0010:	rnd <= (r | s) & !so0;		// round towards +infinity
	4'b0011:	rnd <= (r | s) & so0;			// round towards -infinity
	4'b0100:  rnd <= (r | s); 					// round to nearest away from zero
	4'b1???:	rnd <= 1'd0;	// no rounding if exponent indicates infinite or NaN
	default:	rnd <= 0;				
	endcase

//------------------------------------------------------------
// Clock #2
// round the number, check for carry
// note: inf. exponent checked above (if the exponent was infinite already, then no rounding occurs as rnd = 0)
// note: exponent increments if there is a carry (can only increment to infinity)
//------------------------------------------------------------

reg [MSB:0] rounded2;
reg carry2;
reg rnd2;
reg dn2;
wire [EMSB:0] xo2;
wire [MSB:0] rounded1 = {xo1,mo1[FMSB+3:2]} + rnd;
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
	if (ce) rounded2 <= rounded1;
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
	if (ce) carry2 <= mo1[FMSB+3] & !rounded1[FMSB+1];
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
	if (ce) rnd2 <= rnd;
`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
	if (ce) dn2 <= !(|xo1);
assign xo2 = rounded2[MSB:FMSB+2];

//------------------------------------------------------------
// Clock #3
// - shift mantissa if required.
//------------------------------------------------------------
`ifdef MIN_LATENCY
assign so = i[MSB+3];
assign xo = xo2;
`else
delay3 #(1) u21 (.clk(clk), .ce(ce), .i(i[MSB+3]), .o(so));
delay1 #(EMSB+1) u22 (.clk(clk), .ce(ce), .i(xo2), .o(xo));
`endif

`ifdef MIN_LATENCY
always @*
`else
always @(posedge clk)
`endif
	casez({rnd2,&xo2,carry2,dn2})
	4'b0??0:	mo <= mo1[FMSB+2:2];		// not rounding, not denormalized, => hide MSB
	4'b0??1:	mo <= mo1[FMSB+3:3];		// not rounding, denormalized
	4'b1000:	mo <= rounded2[FMSB  :0];	// exponent didn't change, number was normalized, => hide MSB,
	4'b1001:	mo <= rounded2[FMSB+1:1];	// exponent didn't change, but number was denormalized, => retain MSB
	4'b1010:	mo <= rounded2[FMSB+1:1];	// exponent incremented (new MSB generated), number was normalized, => hide 'extra (FMSB+2)' MSB
	4'b1011:	mo <= rounded2[FMSB+1:1];	// exponent incremented (new MSB generated), number was denormalized, number became normalized, => hide 'extra (FMSB+2)' MSB
	4'b11??:	mo <= 1'd0;						// number became infinite, no need to check carry etc., rnd would be zero if input was NaN or infinite
	endcase

endmodule


// Round and register the output
/*
module fpRoundReg(clk, ce, rm, i, o);
parameter WID = 128;
`include "fpSize.sv"

input clk;
input ce;
input [2:0] rm;			// rounding mode
input [MSB+3:0] i;		// expanded format input
output reg [WID-1:0] o;		// rounded output

wire [WID-1:0] o1;
fpRound #(WID) u1 (.rm(rm), .i(i), .o(o1) );

always @(posedge clk)
	if (ce)
		o <= o1;

endmodule
*/