// ============================================================================
//        __
//   \\__/ o\    (C) 2013  Robert Finch, Stratford
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
//
// Tri-ported data cache memory. (2 read, 1 write)
//
// ============================================================================
//
module Thor_dcachemem_1w1r(wclk, wce, wr, sel, wa, wd, rclk, rce, ra, o);
parameter DBW=64;
input wclk;
input wce;
input wr;
input [DBW/8-1:0] sel;
input [DBW-1:0] wa;
input [DBW-1:0] wd;
input rclk;
input rce;
input [DBW-1:0] ra;
output [DBW-1:0] o;

wire [DBW-1:0] o0, o1, o2;
genvar n;

generate

for (n = 0; n < DBW/8; n = n + 1)
begin : BRAMS
	if (DBW==64)
		syncRam2kx8_1rw1r uga (
			.wclk(wclk),
			.wce(wce),
			.wr(wr & sel[n]),
			.wa(wa[13:3]),
			.wd(wd[n*8+7:n*8]),
			.rclk(rclk),
			.rce(rce),
			.ra(ra[13:3]),
			.o(o[n*8+7:n*8])
		);
	else begin
		syncRam2kx8_1rw1r uga (
			.wclk(wclk),
			.wce(wce),
			.wr(wr & sel[n]),
			.wa(wa[12:2]),
			.wd(wd[n*8+7:n*8]),
			.rclk(rclk),
			.rce(rce),
			.ra(ra[12:2]),
			.o(o0[n*8+7:n*8])
		);
    end
end
endgenerate

assign o = o0;

endmodule

module syncRam2kx8_1rw1r (wclk, wce, wr, wa, wd, rclk, rce, ra, o);
input wclk;
input wce;
input wr;
input [10:0] wa;
input [7:0] wd;
input rclk;
input rce;
input [10:0] ra;
output [7:0] o;

reg [7:0] mem [0:2047];
reg [10:0] rra;
integer n;
initial begin
    for (n = 0; n < 2048; n = n + 1)
        mem[n] <= 0;
end

always @(posedge wclk)
	if (wce & wr) mem[wa] <= wd;
always @(posedge rclk)
	if (rce) rra <= ra;

assign o = mem[rra];

endmodule
