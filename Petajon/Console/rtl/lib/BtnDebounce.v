// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
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
// Button / switch debounce circuit.
// Assumes 25MHz clock
// Approximately 10ms of debounce is provided.
// ============================================================================
//
module BtnDebounce(clk, btn_i, o);
input clk;
input btn_i;
output reg o;

reg [18:0] counter;
reg val1, val2;

always @(posedge clk)
begin
  val1 <= btn_i;
  val2 <= val1;
end

always @(posedge clk)
if (val1 != val2)
  counter <= 19'h0;
else if (counter[18])
  counter <= 19'h0;
else
  counter <= counter + 19'd1;

always @(posedge clk)
if (counter[18])
  o <= val2;

endmodule
