// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	semamem.sv
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
// Address
// 0b0nnnnnaaaa		read: decrement by aaaaaa, write increment by aaaaaa
// 0b1nnnnn----	  read: peek value, write absolute data
// ============================================================================

module semamem(clk, cs, wr, ad, i, o);
input clk;
input cs;
input wr;
input [9:0] ad;
input [7:0] i;
output [7:0] o;

reg [7:0] mem [0:31];
reg [7:0] memi;
wire [7:0] memo = mem[ad[8:4]];
wire [8:0] memopi = memo + ad[3:0];
wire [8:0] memomi = memo - ad[3:0];
assign o = memo;

always @(posedge clk)
if (cs)
	mem[ad[8:4]] <= memi;

always @*
begin
	casez({ad,wr})
	10'b0????????0:	memi <= memomi[8] ? 8'h00 : memomi[7:0];
	10'b0????????1:	memi <= memopi[8] ? 8'hFF : memopi[7:0];
	10'b1????????0:	memi <= memo;
	10'b1????????1:	memi <= i;
	endcase
end

endmodule

