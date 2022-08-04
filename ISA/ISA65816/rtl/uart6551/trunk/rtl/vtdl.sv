// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	vtdl - variable tap delay line
//		(dynamic shift register)
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
//
//    Notes:
//
//	This module acts like a clocked delay line with a variable tap.
//	Miscellaneous usage in rate control circuitry such as fifo's.
//	Capable of delaying a signal bus.
//	Signal bus width is specified with the WID parameter.
//
//   	SystemVerilog
// =============================================================================
//
//`define SIM

module vtdl(clk, ce, a, d, q);
parameter WID = 8;
parameter DEP = 16;
localparam AMSB = $clog2(DEP)-1;
input clk;
input ce;
input [AMSB:0] a;
input [WID-1:0] d;
output [WID-1:0] q;

reg [WID-1:0] m [DEP-1:0];
integer n;

`ifdef SIM
initial begin
	for (n = 0; n < DEP; n = n + 1)
		m[n] = {WID{1'b0}};
end
`endif

always @(posedge clk)
	if (ce) begin
		for (n = 1; n < DEP; n = n + 1)
			m[n] <= m[n-1];
		m[0] <= d;
	end

assign q = m[a];

endmodule
