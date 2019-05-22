// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2018  Robert Finch, Waterloo
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
parameter WID1 = 112;
localparam REM = WID1 % 4;
localparam WID = ((WID1*4)+3)/4;
localparam DMSB = WID-1;
input clk;
input ld;
input [WID-1:0] a;
input [WID-1:0] b;
output reg [WID*2-1:0] q;
output reg [WID-1:0] r;
output reg done;
output reg [7:0] lzcnt = 0;

initial begin
	if (WID % 4) begin
		$display("fpdvir16: Width must be a multiple of four.");
		$finish;
	end
end

reg [DMSB:0] rxx;
reg [8:0] cnt;				// iteration count
reg [DMSB+1:0] ri = 0; 
wire b0,b1,b2,b3;
wire [DMSB+1:0] r1,r2,r3,r4;
reg gotnz = 0;

wire [7:0] maxcnt;
wire [2:0] n1;
assign maxcnt = WID*2/4-1;
assign b0 = b <= {rxx,q[WID*2-1]};
assign r1 = b0 ? {rxx,q[WID*2-1]} - b : {rxx,q[WID*2-1]};
assign b1 = b <= {r1,q[WID*2-2]};
assign r2 = b1 ? {r1,q[WID*2-2]} - b : {r1,q[WID*2-2]};
assign b2 = b <= {r2,q[WID*2-3]};
assign r3 = b2 ? {r2,q[WID*2-3]} - b : {r2,q[WID*2-3]};
assign b3 = b <= {r3,q[WID*2-4]};
assign r4 = b3 ? {r3,q[WID*2-4]} - b : {r3,q[WID*2-4]};

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
		q <= {(a << REM),{WID{1'b0}}};
        rxx <= {WID{1'b0}};
		state <= 1;
	end
3'd1:
	if (!cnt[8]) begin
		q[WID*2-1:4] <= q[WID*2-5:0];
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
			gotnz <= 1;
		end
        rxx <= r4;
		cnt <= cnt - 1;
	end
	else
		state <= 2;
3'd2:
	begin
    	r <= r4;
    	done <= 1'b1;
    	state <= 0;
    end
default:	state <= 0;
endcase
end

endmodule

