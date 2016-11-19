`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	DSD7_ciLookupTbl.v
//  - Huffman encoding lookup table.
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
module DSD7_ciLookupTbl(wclk, wr, wadr, wdata, rclk, radr, rdata);
input wclk;
input wr;
input [11:0] wadr;
input [31:0] wdata;
input rclk;
input [11:0] radr;
output [31:0] rdata;

reg [31:0] mem [0:4095];
reg [11:0] rradr;

always @(posedge wclk)
    if (wr) begin
        mem[wadr] <= wdata;
        $display("CIT: mem[%h]<=%h", wadr, wdata);
    end
always @(posedge rclk)
    rradr <= radr;

assign rdata = mem[rradr];

endmodule
