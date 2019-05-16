// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	regReadbackMem.v
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
// ============================================================================
//
module regReadbackMem(wclk,wce,we,adr,i,o);
parameter WID=16;
input wclk;
input wce;
input we;
input [3:0] adr;
input [WID-1:0] i;
output [WID-1:0] o;

genvar g;

generate
begin
for (g = 0; g < WID; g = g + 1)
begin
RAM16X1S u1
(
    .WCLK(wclk),
    .WE(wce & we),
    .A0(adr[0]),
    .A1(adr[1]),
    .A2(adr[2]),
    .A3(adr[3]),
    .D(i[g]),
    .O(o[g])
);
end
end
endgenerate

endmodule
