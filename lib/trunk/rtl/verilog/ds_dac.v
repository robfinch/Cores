// ============================================================================
//        __
//   \\__/ o\    (C) 2010-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// ds_dac.v
//  - delta-sgima DAC (digital to analogue) converter interface core
//  Based on: http://www.xilinx.com/bvdocs/appnotes/xapp154.pdf
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
//  Webpack 9.2i xc3s1200e 4fg320
//  7 slices / 9 LUTs / 264.340 MHz
//  11 ff's
//
//=============================================================================

/*
 http://www.xilinx.com/bvdocs/appnotes/xapp154.pdf
*/
module ds_dac(rst, clk, di, o);
parameter DBW=8;
input rst;
input clk;
input [DBW-1:0] di;
output o;

reg o;

reg [DBW+1:0] deltaAdder;
reg [DBW+1:0] sigmaAdder;
reg [DBW+1:0] sigmaLatch;
reg [DBW+1:0] deltaB;

always @(sigmaLatch)
deltaB = {sigmaLatch[DBW+1],sigmaLatch[DBW+1]} << DBW;
	
always @(di or deltaB)
deltaAdder = di + deltaB;
	
always @(deltaAdder or sigmaLatch)
sigmaAdder = deltaAdder + sigmaLatch;
	
always @(posedge clk)
if (rst) begin
	sigmaLatch <= 1'b1 << DBW;
	o <= 1'b0;
end
else begin
	sigmaLatch <= sigmaAdder;
	o <= sigmaLatch[DBW+1];
end
	
endmodule

