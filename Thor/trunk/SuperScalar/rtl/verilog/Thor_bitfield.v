`include "Thor_defines.v"
`timescale 1ns / 1ps
//=============================================================================
//        __
//   \\__/ o\    (C) 2012,2013  Robert Finch
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@opencores.org
//       ||
//  
//	Thor_bitfield.v
//  - bitfield datapath operations
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
//=============================================================================
//
//`define I_BFEXTS	1
//`define I_SEXT		1

module Thor_bitfield(op, a, b, m, o, masko);
parameter DWIDTH=64;
input [3:0] op;
input [DWIDTH-1:0] a;
input [DWIDTH-1:0] b;
input [15:0] m;
output [DWIDTH-1:0] o;
reg [DWIDTH-1:0] o;
output [DWIDTH-1:0] masko;

reg [DWIDTH-1:0] o1;
reg [DWIDTH-1:0] o2;

// generate mask
reg [DWIDTH-1:0] mask;
assign masko = mask;
wire [5:0] mb = m[ 5:0];
wire [5:0] me = m[11:6];
wire [5:0] ml = me-mb;		// mask length-1

integer nn,n;
always @(mb or me or nn)
	for (nn = 0; nn < DWIDTH; nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

always @(op,mask,b,a,mb)
case (op)
`BFINS: 	begin
				o2 = a << mb;
				for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? o2[n] : b[n];
			end
`BFSET: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b1 : a[n]; end
`BFCLR: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b0 : a[n]; end
`BFCHG: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? ~a[n] : a[n]; end
`BFEXTU:	begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o = o1 >> mb;
			end
`BFEXT:		begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? a[n] : 1'b0;
				o2 = o1 >> mb;
				for (n = 0; n < DWIDTH; n = n + 1)
					o[n] = n > ml ? o2[ml] : o2[n];
			end
`ifdef I_SEXT
`SEXT:		begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? a[mb] : a[n]; end
`endif
default:	o = {DWIDTH{1'b0}};
endcase

endmodule
