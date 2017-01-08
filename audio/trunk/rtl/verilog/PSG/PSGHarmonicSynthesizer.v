`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// PSGHarmonicSynthsizer.v
// Harmonic synthesizer
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
//=============================================================================

module PSGHarmonicSynthesizer(rst, clk, test, sync, freq, o);
parameter WID = 32; 
input rst;
input clk;
input test;
input sync;
input [WID-1:0] freq;   // frequency control
output [WID-1:0] o;

reg [WID-1:0] acc;

always @(posedge clk)
if (rst)
    acc <= 0;
else begin
    if (~test) begin
        if (sync)
            acc <= 0;
        else
            acc <= acc + freq;
    end
    else
        acc <= 0;
end

assign o = acc;

endmodule
