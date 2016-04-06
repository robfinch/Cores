`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2014  Robert Finch, Stratford
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
// ============================================================================
//
module DualBootrom(rst, clk, pc1, insn1, pc2, insn2);
input rst;
input clk;
input [15:0] pc1;
output [31:0] insn1;
input [15:0] pc2;
output [31:0] insn2;

reg [31:0] rommem [0:8191];
initial begin
`include "..\..\software\asm\bin\Bootrom.ver"
end
reg [15:0] rpc1,rpc2;

always @(negedge clk)
  rpc1 <= pc1;
always @(negedge clk)
  rpc2 <= pc2;

assign insn1 = rommem[rpc1[14:2]];
assign insn2 = rommem[rpc2[14:2]];

endmodule
