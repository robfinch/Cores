// ============================================================================
//        __
//   \\__/ o\    (C) 2006-2016  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	fpdivr8.v
//    Radix 8 floating point divider primitive
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
parameter WID = 112;
parameter RADIX = 8;
localparam WID1 = WID;//((WID+2)/3)*3;    // make width a multiple of three
localparam DMSB = WID1-1;
input clk;
input ld;
input [WID1-1:0] a;
input [WID1-1:0] b;
output reg [WID1*2-1:0] q;
output [WID1-1:0] r;
output reg done;
output reg [7:0] lzcnt;


wire [DMSB:0] rx [2:0];		// remainder holds
reg [DMSB:0] rxx;
reg [8:0] cnt;				// iteration count
wire [DMSB:0] sdq;
wire [DMSB:0] sdr;
wire sdval;
wire sddbz;
reg [DMSB+1:0] ri = 0; 
wire b0,b1,b2;
wire [DMSB+1:0] r1,r2,r3;
reg gotnz;

specialCaseDivider #(WID1) u1 (.a(a), .b(b), .q(sdq), .val(sdval), .dbz(sdbz) );

wire [7:0] maxcnt;
wire [2:0] n1;
generate
begin
if (RADIX==8) begin
    assign maxcnt = WID1*2/3+1;
    assign b0 = b < rxx;
    assign r1 = b0 ? rxx - b : rxx;
    assign b1 = b < {r1,q[WID*2-1]};
    assign r2 = b1 ? {r1,q[WID*2-1]} - b : {r1,q[WID*2-1]};
    assign b2 = b < {r2,q[WID*2-1-1]};
    assign r3 = b2 ? {r2,q[WID*2-1-1]} - b : {r2,q[WID*2-1-1]};
    assign n1 = 2;
	always @(posedge clk)
        if (ld)
            rxx <= 0;
        else if (!done)
            rxx <= {r3,q[WID*2-1]};
end
else if (RADIX==2) begin
    assign b0 = b <= ri;
    assign r1 = b0 ? ri - b : ri;
    assign maxcnt = WID1*2-1;
    assign n1 = 0;
//	assign rx[0] = rxx  [DMSB] ? {rxx  ,q[WID*2-1  ]} + b : {rxx  ,q[WID*2-1  ]} - b;
end
end
endgenerate

	always @(posedge clk)
	begin
		done <= 1'b0;
		if (ld) begin
			cnt <= sdval ? 9'h1FE : maxcnt;
			done <= sdval;
		end
		else if (cnt != 9'h1FE) begin
			cnt <= cnt - 1;
			if (cnt==9'h1FF)
				done <= 1'b1;
		end
	end


generate
begin
if (RADIX==8) begin
	always @(posedge clk)
		if (ld) begin
			gotnz <= 1'b0;
			lzcnt <= 8'h00;
			if (sdval)
				q <= {3'b0,sdq,{WID1{1'b0}}};
			else
				q <= {3'b0,a,{WID1{1'b0}}};
		end
		else if (!done) begin
			q[WID1-1:3] <= q[WID1-1-3:0];
			q[0] <= b0;
			q[1] <= b1;
			q[2] <= b2;
		end
    	// correct remainder
        assign r = sdval ? sdr : r3;
end
if (RADIX==2) begin
	always @(posedge clk)
    if (ld) begin
		gotnz <= 1'b0;
		lzcnt <= 8'h00;
        ri <= 0;
    	if (sdval)
            q <= {3'b0,sdq,{WID1{1'b0}}};
        else
            q <= {3'b0,a,{WID1{1'b0}}};
    end
    else if (cnt!=9'h1FE) begin
    	if (b0)
    		gotnz <= 1'b1;
    	if (b0==0 && !gotnz)
    		lzcnt <= lzcnt + 8'd1;
        q[WID1*2-1:1] <= q[WID1*2-1-1:0];
        q[0] <= b0;
        ri <= {r1[DMSB:0],q[WID1*2-1]};
    end
	// correct remainder
    assign r = sdval ? sdr : ri;
end
end
endgenerate

endmodule


