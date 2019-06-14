// ============================================================================
//        __
//   \\__/ o\    (C) 2005-2018  Robert Finch, Waterloo
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
module round_robin(rst, clk, ce, req, lock, sel);
parameter N=12;
localparam B=$clog2(N);
input rst;				// reset
input clk;				// clock
input ce;				// clock enable
input [N-1:0] req;		// request
input [N-1:0] lock;		// lock selection
output [N-1:0] sel;		// select

integer n;
reg [N-1:0] sel;

reg [B-1:0] rot;			// forward rotate applied to request lines
reg [B-1:0] amt;			// how much to rotate forward after a grant
reg [N-1:0] rgrnt;		// rotated value of grant
wire [N-1:0] nextGrant;	// unrotated value of grant
wire [N-1:0] rr1;			// rotated request imtermediate
wire [N-1:0] ng1;			// intermediate grant rotation
wire [N-1:0] rreq;		// rotated request

// rotate the request lines to set priority
wire [2*N-1:0] rreq1 = {req,{N{1'b0}}} >> rot;
assign rreq = rreq1[2*N-1:N]|rreq1[N-1:0];

// rotate the rotated grant value back into place
wire [2*N-1:0] rgnt1 = {{N{1'b0}},rgrnt} << rot;
assign nextGrant = rgnt1[2*N-1:N]|rgnt1[N-1:0];

// If there is a request, determine how far the request
// lines should be rotated when there is a grant
always @*
begin
	amt <= 0;
	for (n = N-1; n >= 0; n = n - 1)
		if (rreq[n])
			amt <= n;
end

// set grant (if request present) based on which request
// was honored.
always @*
	rgrnt <= {{N{1'b0}},|rreq} << ((amt-1) % N);

// rotate the priorities on a grant
always @(posedge clk)
if (rst)
	rot = 0;
else if (ce)
	if (!(lock & sel))
		rot = rot + amt;

// Assign the next owner, if bus isn't locked
always @(posedge clk)
if (rst)
	sel = 0;
else if (ce)
	if (!(lock & sel))
		sel = nextGrant;

endmodule


