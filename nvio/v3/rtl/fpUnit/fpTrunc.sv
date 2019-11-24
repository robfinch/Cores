// ============================================================================
//        __
//   \\__/ o\    (C) 2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpTrunc.v
//		- convert floating point to integer (chop off fractional bits)
//		- single cycle latency floating point unit
//		- parameterized FPWIDth
//		- IEEE 754 representation
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

module fpTrunc(clk, ce, i, o, overflow);
parameter FPWID = 32;
`include "fpSize.sv"
input clk;
input ce;
input [MSB:0] i;
output reg [MSB:0] o;
output overflow;


integer n;
wire [MSB:0] maxInt  = {MSB{1'b1}};		// maximum unsigned integer value
wire [EMSB:0] zeroXp = {EMSB{1'b1}};	// simple constant - value of exp for zero

// Decompose fp value
reg sgn;									// sign
reg [EMSB:0] exp;
reg [FMSB:0] man;
reg [FMSB:0] mask;

wire [7:0] shamt = FMSB - (exp - zeroXp);
always @*
for (n = 0; n <= FMSB; n = n +1)
	mask[n] = (n > shamt);

always @*	
	sgn = i[MSB];
always @*
	exp = i[MSB-1:FMSB+1];
always @*
	if (exp > zeroXp + FMSB)
		man = i[FMSB:0];
	else
		man = i[FMSB:0] & mask;

always @(posedge clk)
	if (ce) begin
		if (exp < zeroXp)
			o <= 1'd0;
		else
			o <= {sgn,exp,man};
	end

endmodule
