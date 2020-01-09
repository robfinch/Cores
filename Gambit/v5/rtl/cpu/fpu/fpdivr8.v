// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpdivr8.v
//	Radix8 doesn't work !!!!
//    Radix 2 floating point divider primitive
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
// ============================================================================

module fpdivr8(clk, ld, a, b, q, r, done, lzcnt);
parameter FPWID = 112;
localparam DMSB = FPWID-1;
input clk;
input ld;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output reg [FPWID-1:0] q;
output [FPWID-1:0] r;
output reg done;
output reg [7:0] lzcnt;


reg [DMSB:0] rxx;
reg [8:0] cnt;				// iteration count
reg [DMSB+1:0] ri = 0; 
wire b0,b1,b2,b3;
wire [DMSB+1:0] r1,r2,r3;
reg gotnz;

wire [7:0] maxcnt;
wire [2:0] n1;
assign maxcnt = FPWID/3+1;
assign b0 = b < rxx;
assign r1 = b0 ? rxx - b : rxx;
assign b1 = b < {r1,q[FPWID-1]};
assign r2 = b1 ? {r1,q[FPWID-1]} - b : {r1,q[FPWID-1]};
assign b2 = b < {r2,q[FPWID-2]};
assign r3 = b2 ? {r2,q[FPWID-2]} - b : {r2,q[FPWID-2]};

always @(posedge clk)
    if (ld)
        rxx <= {FPWID{1'b0}};
    else if (!done)
        rxx <= {r3,q[FPWID-3]};

always @(posedge clk)
begin
	done <= 1'b0;
	if (ld) begin
		cnt <= maxcnt;
	end
	else if (cnt != 9'h1FE) begin
		cnt <= cnt - 1;
		if (cnt==9'h1FF)
			done <= 1'b1;
	end
end


always @(posedge clk)
	if (ld) begin
		q <= a;
	end
	else if (!done) begin
		q[FPWID-1:3] <= q[FPWID-4:0];
		q[2] <= b0;
		q[1] <= b1;
		q[0] <= b2;
	end
    assign r = r3;

endmodule

