`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2007-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// PSGPWMDac.v
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
// Pulse Width Modulator
// - the frequency of the pulses should be at least 10x teh highest desired
//   frequency. Eg for 5kHz audio the PWM frequency should be at least 50kHz.
// - this limits the number of bits the dac can convert.
//   Eg. with a 200MHz clock, 12 bit PWM counter width results in a PWM
//   frequency of 48.8kHz.                                                                          
//=============================================================================

module PSGPWMDac(rst, clk, i, o);
parameter WID=12;
input rst;
input clk;
input [WID-1:0] i;
output o;

reg [WID-1:0] cnt, li;

always @(posedge clk)
if (rst)
    cnt <= {WID{1'b0}};
else
    cnt <= cnt + 1;
always @(posedge clk)
    if (cnt=={WID{1'b0}})
        li <= i;

assign o = cnt < li;

endmodule
