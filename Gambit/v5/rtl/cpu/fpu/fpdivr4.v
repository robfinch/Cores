// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2020  Robert Finch, Waterloo
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

module fpdivr4(clk, ld, a, b, q, r, done, lzcnt);
parameter WID1 = 112;
localparam REM = WID1 % 2;
localparam WID = ((WID1*2)+1)/2;
localparam DMSB = WID-1;
input clk;
input ld;
input [WID-1:0] a;
input [WID-1:0] b;
output reg [WID*2-1:0] q = 1'd0;
output reg [WID-1:0] r = 1'd0;
output reg done = 1'd0;
output reg [7:0] lzcnt = 1'd0;

initial begin
	if (WID % 2) begin
		$display("fpdvir4: Width must be a multiple of two.");
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

assign maxcnt = WID*2/2-1;
always @*
	b0 = b <= {rxx,q[WID*2-1]};
always @*
	r1 = b0 ? {rxx,q[WID*2-1]} - b : {rxx,q[WID*2-1]};
always @*
	b1 = b <= {r1,q[WID*2-2]};
always @*
	r2 = b1 ? {r1,q[WID*2-2]} - b : {r1,q[WID*2-2]};

reg [2:0] state = 0;
always @(posedge clk)
begin
  if (ld) state <= 3'd1;
  case(state)
  3'd0:	;
  3'd1: if (cnt[8]) state <= 3'd2;
  3'd2: state <= 3'd0;
  default:  state <= 3'd0;
  endcase
end

always @(posedge clk)
begin
done <= 1'b0;
case(state)
3'd0:	;
3'd1:
	if (!cnt[8]) begin
		q[WID*2-1:2] <= q[WID*2-3:0];
		q[1] <= b0;
		q[0] <= b1;
		if (!gotnz)
			casez({b0,b1})
			2'b1?:	;
			2'b01:	lzcnt <= lzcnt + 8'd1;
			2'b00:	lzcnt <= lzcnt + 8'd2;
			endcase
		if ({b0,b1} != 2'h0 && !gotnz) begin
			gotnz <= 3'd1;
		end
        rxx <= r2;
		cnt <= cnt - 3'd1;
	end
3'd2:
	begin
    	r <= r2;
    	done <= 1'b1;
    end
default:	;
endcase
if (ld) begin
	lzcnt <= 0;
	gotnz <= 1'b0;
	cnt <= {1'b0,maxcnt};
	q <= {(a << REM),{WID{1'b0}}};
      rxx <= {WID{1'b0}};
end
end

endmodule

