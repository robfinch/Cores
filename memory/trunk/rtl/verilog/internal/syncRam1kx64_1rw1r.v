`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2011,2012  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	syncRam1kx64_1rw1r.v
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
//=============================================================================

module syncRam1kx64_1rw1r(
	input wrst,
	input wclk,
	input wce,
	input we,
	input [9:0] wadr,
	input [63:0] i,
	output [63:0] wo,

	input rrst,
	input rclk,
	input rce,
	input [9:0] radr,
	output [63:0] ro
);

syncRam1kx16_1rw1r u1
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[15:0]),
	.wo(wo[15:0]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(ro[15:0])
);

syncRam1kx16_1rw1r u2
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[31:16]),
	.wo(wo[31:16]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(ro[31:16])
);

syncRam1kx16_1rw1r u3
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[47:32]),
	.wo(wo[47:32]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(ro[47:32])
);

syncRam1kx16_1rw1r u4
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[63:48]),
	.wo(wo[63:48]),
	.rrst(rrst),
	.rclk(rclk),
	.rce(rce),
	.radr(radr),
	.o(ro[63:48])
);

endmodule
