//=============================================================================
//  regfile6r2w
//      synchronous register file
//
//
//	2010 Robert Finch
//	robfinch<remove>@FPGAfield.ca
//
//
//	This source code is available only for veiwing, testing and evaluation
//	purposes. Any commercial use requires a license. This copyright
//	statement and disclaimer must remain present in the file.
//
//
//	NO WARRANTY.
//  THIS Work, IS PROVIDEDED "AS IS" WITH NO WARRANTIES OF ANY KIND, WHETHER
//	EXPRESS OR IMPLIED. The user must assume the entire risk of using the
//	Work.
//
//	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
//  INCIDENTAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES WHATSOEVER RELATING TO
//  THE USE OF THIS WORK, OR YOUR RELATIONSHIP WITH THE AUTHOR.
//
//	IN ADDITION, IN NO EVENT DOES THE AUTHOR AUTHORIZE YOU TO USE THE WORK
//	IN APPLICATIONS OR SYSTEMS WHERE THE WORK'S FAILURE TO PERFORM CAN
//	REASONABLY BE EXPECTED TO RESULT IN A SIGNIFICANT PHYSICAL INJURY, OR IN
//	LOSS OF LIFE. ANY SUCH USE BY YOU IS ENTIRELY AT YOUR OWN RISK, AND YOU
//	AGREE TO HOLD THE AUTHOR AND CONTRIBUTORS HARMLESS FROM ANY CLAIMS OR
//	LOSSES RELATING TO SUCH UNAUTHORIZED USE.
//
//
//  Webpack 9.2i xc3s1200e 4fg320
//   703 slices / 2153 LUTs / 11 ns
//   32 ff's / 0 DCM /  0 BRAMs / 0 mults
//
//=============================================================================

module regfile(
	clk, wr0, wr1, wa0, wa1, ra0, ra1, ra2, ra3, ra4, ra5,
	i0, i1, o0, o1, o2, o3, o4, o5
);
input clk;
input wr0,wr1;
input [4:0] wa0,wa1;
input [4:0] ra0,ra1,ra2,ra3,ra4,ra5;
input [31:0] i0,i1;
output [31:0] o0,o1,o2,o3,o4,o5;

reg [31:0] mem0 [31:0];
reg [31:0] mem1 [31:0];
reg [31:0] tmem;

assign o0 = ra0==5'd0 ? 32'd0 : tmem[ra0] ? mem1[ra0] : mem0[ra0];
assign o1 = ra1==5'd0 ? 32'd0 : tmem[ra1] ? mem1[ra1] : mem0[ra1];
assign o2 = ra2==5'd0 ? 32'd0 : tmem[ra2] ? mem1[ra2] : mem0[ra2];
assign o3 = ra3==5'd0 ? 32'd0 : tmem[ra3] ? mem1[ra3] : mem0[ra3];
assign o4 = ra4==5'd0 ? 32'd0 : tmem[ra4] ? mem1[ra4] : mem0[ra4];
assign o5 = ra5==5'd0 ? 32'd0 : tmem[ra5] ? mem1[ra5] : mem0[ra5];

always @(posedge clk)
	if (wr0)
		mem0[wa0] <= i0;

always @(posedge clk)
	if (wr1)
		mem1[wa1] <= i1;

always @(posedge clk)
	if (wr1 && wr0 && wa0==wa1)	// both write addresses are the same wa1 takes precedence
		tmem[wa0] <= 1'b1;
	else if (wr0 & wr1) begin	// writes on two different addresses
		tmem[wa0] <= 1'b0;
		tmem[wa1] <= 1'b1;
	end
	else if (wr0)
		tmem[wa0] <= 1'b0;
	else if (wr1)
		tmem[wa1] <= 1'b1;
		
endmodule
