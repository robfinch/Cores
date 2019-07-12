// ============================================================================
//        __
//   \\__/ o\    (C) 2003-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
//
module uart6551Fifo(clk, rst, wr, rd, din, dout, ctr, full, empty);
parameter WID=8;
parameter DEP=16;
localparam pCtrBits = $clog2(DEP)-1;
input clk;
input rst;
input wr;
input rd;
input [WID-1:0] din;
output [WID-1:0] dout;
output [pCtrBits:0] ctr;
reg [pCtrBits:0] ctr;
output full;
output empty;

assign full = ctr=={pCtrBits{1'b1}}-1;
assign empty = ctr=={pCtrBits{1'b1}};
wire rdok = rd & ~empty;
wire wrok = wr & ~full;

vtdl #(WID,DEP) u1 (.clk(clk), .ce(1'b1), .a(ctr), .d(din), .q(dout));

always @(posedge clk)
if (rst)
	ctr <= {pCtrBits{1'b1}};
else
	ctr <= ctr + {rdok&~wrok,rdok&~wrok,rdok&~wrok,rdok^wrok};

endmodule
