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

module fpdivr8(clk, ld, a, b, q, r, done);
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
output done;


wire [DMSB:0] rx [2:0];		// remainder holds
reg [DMSB:0] rxx;
reg [8:0] cnt;				// iteration count
wire [DMSB:0] sdq;
wire [DMSB:0] sdr;
wire sdval;
wire sddbz;
reg [DMSB+1:0] ri; 
wire b0,b1,b2;
wire [DMSB:0] r1,r2,r3;

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
    assign maxcnt = WID1*2+1;
    assign n1 = 0;
//	assign rx[0] = rxx  [DMSB] ? {rxx  ,q[WID*2-1  ]} + b : {rxx  ,q[WID*2-1  ]} - b;
end
end
endgenerate

	always @(posedge clk)
		if (ld)
			cnt <= sdval ? 9'h1FF : maxcnt;
		else if (!done)
			cnt <= cnt - 1;


generate
begin
if (RADIX==8) begin
	always @(posedge clk)
		if (ld) begin
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
        ri <= 0;
    	if (sdval)
            q <= {3'b0,sdq,{WID1{1'b0}}};
        else
            q <= {3'b0,a,{WID1{1'b0}}};
    end
    else if (!done) begin
        q[WID1*2-1:1] <= q[WID1*2-1-1:0];
        q[0] <= b0;
        ri <= {r1[DMSB:0],q[WID1*2-1]};
    end
	// correct remainder
    assign r = sdval ? sdr : ri;
end
end
endgenerate

	assign done = cnt[8];

endmodule

/*
module fpdiv_tb();

	reg rst;
	reg clk;
	reg ld;
	reg [6:0] cnt;

	wire ce = 1'b1;
	wire [49:0] a = 50'h0_0000_0400_0000;
	wire [23:0] b = 24'd101;
	wire [49:0] q;
	wire [49:0] r;
	wire done;

	initial begin
		clk = 1;
		rst = 0;
		#100 rst = 1;
		#100 rst = 0;
	end

	always #20 clk = ~clk;	//  25 MHz
	
	always @(posedge clk)
		if (rst)
			cnt <= 0;
		else begin
			ld <= 0;
			cnt <= cnt + 1;
			if (cnt == 3)
				ld <= 1;
			$display("ld=%b q=%h r=%h done=%b", ld, q, r, done);
		end
	

	fpdivr8 divu0(.clk(clk), .ce(ce), .ld(ld), .a(a), .b(b), .q(q), .r(r), .done(done) );

endmodule

*/

