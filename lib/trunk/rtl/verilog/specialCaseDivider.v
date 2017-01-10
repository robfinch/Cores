// ============================================================================
//	specialCaseDivider.v
//		- perform division using multiplication for special
//		  constants 
//		- division complete within a single cycle
//
//
//  2006,2008,2010  Robert Finch
//
//  This source code is available for evaluation and validation purposes
//  only. This copyright statement and disclaimer must remain present in
//  the file.
//
//	NO WARRANTY.
//  THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF ANY KIND, WHETHER
//  EXPRESS OR IMPLIED. The user must assume the entire risk of using the
//  Work.
//
//  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
//  INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES WHATSOEVER RELATING TO
//  THE USE OF THIS WORK, OR YOUR RELATIONSHIP WITH THE AUTHOR.
//
//  IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU TO USE THE WORK
//  IN APPLICATIONS OR SYSTEMS WHERE THE WORK'S FAILURE TO PERFORM CAN
//  REASONABLY BE EXPECTED TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN
//  LOSS OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK, AND YOU
//  AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS FROM ANY CLAIMS OR
//  LOSSES RELATING TO SUCH UNAUTHORIZED USE.
//
//	ref: Webpack 8.1i  xc3s1000-4ft256
//	83 slices / 159 LUTs / 23.728 ns
//  4 multipliers
// ============================================================================
//

module specialCaseDivider(a, b, q, r, val, dbz);
parameter WID=32;

// inputs / outputs
input [WID-1:0] a;		// dividend
input [WID-1:0] b;		// divisor
output [WID-1:0] q;		// quotient
output [WID-1:0] r;		// remainder
output val;				// indicates division is valid
output dbz;				// dividing by zero (b is zero)

// variables
reg [WID-1:0] m;
wire [WID*2-1:0] mr = a * m;
wire az = a==0;
wire bo = b==1;			// dividing by one
assign dbz = b==0;		// dividing by zero
wire mz = m==0;

always @(b)
	case (b)
	32'h1:  m = 1;	// special flag value
	32'h2:	m = (1 << WID) / 2;
	32'h3:	m = (1 << WID) / 3;
	32'h4:  m = (1 << WID) / 4;
	32'h5:  m = (1 << WID) / 5;
	32'h6:	m = (1 << WID) / 6;
	32'h7:	m = (1 << WID) / 7;
	32'h8:  m = (1 << WID) / 8;
	32'h9:  m = (1 << WID) / 9;
	32'd10:	m = (1 << WID) / 10;
	32'd16: m = (1 << WID) / 16;
	32'd64: m = (1 << WID) / 64;
	32'd100:	m = (1 << WID) / 100;
	32'd256:	m = (1 << WID) / 256;
	32'd1000:	m = (1 << WID) / 1000;
	default: m = 0;
	endcase

// outputs
assign q = az ? 0 : bo ? a : mr[WID*2-1:WID];
assign r = a - (b * q);
assign val = !mz|az|bo;

endmodule


module scdiv_tb();

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
wire [32:1] a1,a2,a3,a4,a5;
wire [32:1] b1,b2,b3,b4,b5;
wire [32:1] o1,o2,o3,o4,o5;
wire v1,v2,v3,v4,v5;
wire bz1,bz2,bz3,bz4,bz5;

initial begin
	clk = 1;
	rst = 0;
	#100 rst = 1;
	#100 rst = 0;
end

always #20 clk = ~clk;	//  25 MHz

// special cases divide by zero and not valid	
specialCaseDivider u1 (.a(100), .b(0), .o(o1), .val(v1), .bz(bz1) );
specialCaseDivider u2 (.a(100), .b(2534), .o(o2), .val(v2), .bz(bz2) );
specialCaseDivider u3 (.a(353), .b(9), .o(o3), .val(v3), .bz(bz3) );

always @(posedge clk)
begin
	$display("a=%h b=%h o=%h val=%b", 100, 0, o1, v1, bz1);
	$display("a=%h b=%h o=%h val=%b", 100, 2534, o1, v1, bz1);
	$display("a=%h b=%h o=%h val=%b", 353, 9, o1, v1, bz1);
end

endmodule


