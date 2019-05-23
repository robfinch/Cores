`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
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
`ifndef BFSET
`define BFSET     4'd0
`define BFCLR     4'd1
`define BFCHG     4'd2 
`define BFINS     4'd3
`define BFINSI    4'd4
`define BFEXT     4'd5
`define BFEXTU    4'd6
`define BFFFO	  4'd8
`endif

module bitfield(inst, a, b, c, o, masko);
parameter DWIDTH=80;
input [39:0] inst;
input [DWIDTH-1:0] a;
input [DWIDTH-1:0] b;
input [DWIDTH-1:0] c;
output [DWIDTH-1:0] o;
reg [DWIDTH-1:0] o;
output [DWIDTH-1:0] masko;

reg [DWIDTH-1:0] o1;
reg [DWIDTH-1:0] o2;
wire [6:0] ffoo;

// generate mask
reg [DWIDTH-1:0] mask;
assign masko = mask;
wire [3:0] op = inst[39:36];
reg [6:0] mb = inst[34] ? a[6:0] : {inst[32],inst[15:10]};
reg [6:0] mw;
reg [79:0] da;
wire [5:0] me = mb + mw;
wire [5:0] ml = mw;		// mask length-1
wire [79:0] imm = {74'd0,inst[33:28]};

always @*
if (op==`BFINS)
	mw <= {2'b00,inst[31:28]};
else if (inst[33])
	mw <= b[6:0];
else
	mw <= {inst[31],inst[21:16]};
always @*

if (op==`BFINS)
	da <= {74'd0,inst[27:22]};
else if (inst[35])
	da <= c;
else
	da <= {71'd0,inst[30:22]};

integer nn,n;
always @(mb or me or nn)
	for (nn = 0; nn < DWIDTH; nn = nn + 1)
		mask[nn] <= (nn >= mb) ^ (nn <= me) ^ (me >= mb);

ffo96 u1 ({16'h0,o1},ffoo);

always @*
begin
o1 = 80'd0;	// prevent inferred latch
case (op)
`BFINS: 
	begin
		o2 = a << mb;
		for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : da[n]);
	end
`BFINSI:
 	begin
		o2 = imm << mb;
		for (n = 0; n < DWIDTH; n = n + 1) o[n] = (mask[n] ? o2[n] : da[n]);
	end
`BFSET: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b1 : da[n]; end
`BFCLR: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? 1'b0 : da[n]; end
`BFCHG: 	begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? ~da[n] : da[n]; end
`BFEXTU:	begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? da[n] : 1'b0;
				o = o1 >> mb;
			end
`BFEXT:		begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? da[n] : 1'b0;
				o2 = o1 >> mb;
				for (n = 0; n < DWIDTH; n = n + 1)
					o[n] = n > ml ? o2[ml] : o2[n];
			end
`BFFFO:
			begin
				for (n = 0; n < DWIDTH; n = n + 1)
					o1[n] = mask[n] ? da[n] : 1'b0;
				o = (ffoo==7'd127) ? -64'd1 : ffoo;	// ffoo returns 127 if no one was found
			end
`ifdef I_SEXT
`SEXT:		begin for (n = 0; n < DWIDTH; n = n + 1) o[n] = mask[n] ? da[mb] : da[n]; end
`endif
default:	o = {DWIDTH{1'b0}};
endcase
end

endmodule

