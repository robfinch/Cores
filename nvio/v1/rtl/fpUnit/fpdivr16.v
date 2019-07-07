// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpdivr16.v
//    Radix 16 floating point divider primitive
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

module fpdivr16(clk, ld, a, b, q, r, done, lzcnt);
parameter FPWID1 = 112;
localparam REM = FPWID1 % 4;
localparam FPWID = ((FPWID1*4)+3)/4;
localparam DMSB = FPWID-1;
input clk;
input ld;
input [FPWID-1:0] a;
input [FPWID-1:0] b;
output reg [FPWID*2-1:0] q = 1'd0;
output reg [FPWID-1:0] r = 1'd0;
output reg done = 1'd0;
output reg [7:0] lzcnt = 1'd0;

initial begin
	if (FPWID % 4) begin
		$display("fpdvir16: FPWIDth must be a multiple of four.");
		$finish;
	end
end

wire [7:0] maxcnt;
reg [DMSB:0] rxx = 1'd0;
reg [8:0] cnt = 1'd0;				// iteration count
// Simulation didn't like all the wiring.
reg [DMSB+1:0] ri = 1'd0; 
reg b0 = 1'd0,b1 = 1'd0,b2 = 1'd0,b3 = 1'd0;
reg [DMSB+1:0] r1 = 1'd0,r2 = 1'd0,r3 = 1'd0,r4 = 1'd0;
reg gotnz = 0;

assign maxcnt = FPWID*2/4-1;
always @*
	b0 = b <= {rxx,q[FPWID*2-1]};
always @*
	r1 = b0 ? {rxx,q[FPWID*2-1]} - b : {rxx,q[FPWID*2-1]};
always @*
	b1 = b <= {r1,q[FPWID*2-2]};
always @*
	r2 = b1 ? {r1,q[FPWID*2-2]} - b : {r1,q[FPWID*2-2]};
always @*
	b2 = b <= {r2,q[FPWID*2-3]};
always @*
	r3 = b2 ? {r2,q[FPWID*2-3]} - b : {r2,q[FPWID*2-3]};
always @*
	b3 = b <= {r3,q[FPWID*2-4]};
always @*
	r4 = b3 ? {r3,q[FPWID*2-4]} - b : {r3,q[FPWID*2-4]};

reg [2:0] state = 0;

always @(posedge clk)
begin
done <= 1'b0;
case(state)
3'd0:
	if (ld) begin
		lzcnt <= 0;
		gotnz <= 0;
		cnt <= maxcnt;
		q <= {(a << REM),{FPWID{1'b0}}};
        rxx <= {FPWID{1'b0}};
		state <= 1;
	end
3'd1:
	if (!cnt[8]) begin
		q[FPWID*2-1:4] <= q[FPWID*2-5:0];
		q[3] <= b0;
		q[2] <= b1;
		q[1] <= b2;
		q[0] <= b3;
		if (!gotnz)
			casez({b0,b1,b2,b3})
			4'b1???:	;
			4'b01??:	lzcnt <= lzcnt + 8'd1;
			4'b001?:	lzcnt <= lzcnt + 8'd2;
			4'b0001:	lzcnt <= lzcnt + 8'd3;
			4'b0000:	lzcnt <= lzcnt + 8'd4;
			endcase
		if ({b0,b1,b2,b3} != 4'h0 && !gotnz) begin
			gotnz <= 3'd1;
		end
        rxx <= r4;
		cnt <= cnt - 3'd1;
	end
	else
		state <= 3'd2;
3'd2:
	begin
    	r <= r4;
    	done <= 1'b1;
    	state <= 1'd0;
    end
default:	state <= 1'd0;
endcase
end

endmodule

