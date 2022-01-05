// ============================================================================
//        __
//   \\__/ o\    (C) 2012-2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//                                                                          
// ============================================================================
//
module scratchmem128(rst_i, clk_i, cti_i, bok_o, cs_i, cyc_i, stb_i, ack_o, we_i, sel_i, adr_i, dat_i, dat_o, sp);
input rst_i;
input clk_i;
input [2:0] cti_i;
output bok_o;
input cs_i;
input cyc_i;
input stb_i;
output ack_o;
input we_i;
input [15:0] sel_i;
input [17:0] adr_i;
input [127:0] dat_i;
output reg [127:0] dat_o;
input [31:0] sp;

integer n;

reg [127:0] rommem [16383:0];
reg [17:4] radr;


initial begin
`include "d:/cores2021/Thor/software/boot/rom.ver";
end

wire cs = cs_i && cyc_i && stb_i;
assign bok_o = cs_i;
reg csd;
reg wed;
reg [15:0] seld;
reg [17:0] adrd;
reg [127:0] datid;
reg [127:0] datod;

reg [2:0] cnt;
/*
reg rdy,rdy1;
always @(posedge clk_i)
if (rst_i) begin
	rdy1 <= 1'b0;
	rdy <= 1'b0;
end
else begin
	rdy1 <= cs;
	rdy <= rdy1 & cs && cnt!=3'b101;
end
assign ack_o = cs ? (we_i ? 1'b1 : rdy) : 1'b0;
*/
ack_gen #(
	.READ_STAGES(1),
	.WRITE_STAGES(1),
	.REGISTER_OUTPUT(1)
) ag1
(
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs && cnt != 3'b101),
	.we_i(we_i && cs && cnt != 3'b101),
	.o(ack_o),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);


always @(posedge clk_i)
	csd <= cs;
always @(posedge clk_i)
	wed <= we_i;
always @(posedge clk_i)
	seld <= sel_i;
always @(posedge clk_i)
	adrd <= adr_i;
always @(posedge clk_i)
	datid <= dat_i;

always @(posedge clk_i)
	if (cs & we_i) begin
		$display ("wrote to scratchmem: %h=%h:%h", adr_i, dat_i, sel_i);
		/*
		if (adr_i[14:3]==15'h3e9 && dat_i==64'h00) begin
		  $display("3e9=00");
		  $finish;
		end
		*/
	end
	
genvar g;
generate begin : gRom
for (g = 0; g < 16; g = g + 1)
always @(posedge clk_i)
	if (csd & wed & seld[g])
		rommem[adrd[17:4]][g*8+7:g*8] <= datid[g*8+7:g*8];
end
endgenerate

wire pe_cs;
edge_det u1(.rst(rst_i), .clk(clk_i), .ce(1'b1), .i(cs), .pe(pe_cs), .ne(), .ee() );

reg [14:0] ctr;
always @(posedge clk_i)
if (rst_i)
	cnt <= 3'd0;
else begin
	if (pe_cs) begin
		if (cti_i==3'b000)
			ctr <= adr_i[17:4];
		else
			ctr <= adr_i[17:4] + 12'd1;
		cnt <= 3'b000;
	end
	else if (cs && cnt[2:0]!=3'b100 && cti_i!=3'b000) begin
		ctr <= ctr + 2'd1;
		cnt <= cnt + 3'd1;
	end
end

always @(posedge clk_i)
	radr <= pe_cs ? adr_i[17:4] : ctr;

//assign dat_o = cs ? {smemH[radr],smemG[radr],smemF[radr],smemE[radr],
//				smemD[radr],smemC[radr],smemB[radr],smemA[radr]} : 64'd0;
reg [11:0] spr;
always @(posedge clk_i)
	spr <= sp[17:4];

always @(posedge clk_i)
begin
	datod <= rommem[radr];
	if (!we_i & cs)
		$display("read from scratchmem: %h=%h", radr, rommem[radr]);
//	$display("-------------- Stack --------------");
//	for (n = -6; n < 8; n = n + 1) begin
//		$display("%c%c %h %h", n==0 ? "-": " ", n==0 ?">" : " ",spr + n, rommem[spr+n]);
//	end
end

always @(posedge clk_i)
if (cs_i)
	dat_o <= datod;
else
	dat_o <= 128'd0;

endmodule
