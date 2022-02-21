`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2022  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	rf6809_mmu.sv
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
//
// ============================================================================
//
`define LOW     1'b0
`define HIGH    1'b1

module rf6809_mmu(rst_i, clk_i, pcr_i, s_ex_i, s_cs_i, s_cyc_i, s_stb_i, s_ack_o, s_wr_i, s_adr_i, s_dat_i, s_dat_o,
    pea_o, cyc_o, stb_o, we_o,
    exv_o, rdv_o, wrv_o);
parameter SMALL = 1'b0;
input rst_i;
input clk_i;
input [23:0] pcr_i;     // paging enabled
input s_ex_i;           // executable address
input s_cs_i;
input s_cyc_i;
input s_stb_i;
input s_wr_i;           // write strobe
output s_ack_o;
input [31:0] s_adr_i;    // virtual address
input [11:0] s_dat_i;
output reg [11:0] s_dat_o;
output reg [31:0] pea_o;
output reg cyc_o;
output reg stb_o;
output reg we_o;
output reg exv_o;       // execute violation
output reg rdv_o;       // read violation
output reg wrv_o;       // write violation

wire cs = s_cyc_i && s_stb_i && s_cs_i;
wire [5:0] okey = pcr_i[17:12];
wire mapen = pcr_i[23];
wire os_gate = pcr_i[22];
wire [5:0] akey = pcr_i[5:0];

ack_gen #(
	.READ_STAGES(3),
	.WRITE_STAGES(0),
	.REGISTER_OUTPUT(1)
) uag1
(
	.rst_i(rst_i),
	.clk_i(clk_i),
	.ce_i(1'b1),
	.i(cs & ~s_we_i),
	.we_i(cs & s_we_i),
	.o(s_ack_o),
	.rid_i(0),
	.wid_i(0),
	.rid_o(),
	.wid_o()
);


reg cyc1,cyc2,stb1,stb2;
wire [1:0] douta;
wire [23:0] doutb;
wire [20:0] doutca;
reg [3:0] crwx;

always @(posedge clk_i)
  exv_o <= s_ex_i & ~crwx[0] & cyc2 & stb2 & mapen;
always @(posedge clk_i)
  rdv_o <= ~(s_wr_i | s_ex_i) & ~crwx[2] & cyc2 & stb2 & mapen;
always @(posedge clk_i)
  wrv_o <= s_wr_i & ~crwx[1] & cyc2 & stb2 & mapen;

genvar g;
generate begin : gMapRam
if (SMALL) begin
wire [11:0] addra = {akey[3:0],s_adr_i[ 7: 0]};
wire [11:0] addrb = {okey[3:0],s_adr_i[18:11]};

// block RAM (2 block RAMs)
// 12 bits wide by 4096 rows deep
rf6809_SmallMMURam u1 (
  .clka(clk_i),    // input wire clka
  .ena(cs),      // input wire ena
  .wea(cs & s_wr_i),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [17 : 0] addra
  .dina(s_dat_i[11:0]),    // input wire [11 : 0] dina
  .douta(douta),
  .clkb(clk_i),    // input wire clkb
  .enb(1'b1),  // input wire enb
  .web(1'b0),
  .addrb(addrb),  // input wire [13 : 0] addrb
  .dinb(12'h0),
  .doutb(doutb[11:0])  // output wire [51 : 0] doutb
);
always_comb
	crwx = {1'b0,doutb[11:9]};
end
else begin
wire [17:0] addra = {akey,s_adr_i[11: 0]};
wire [16:0] addrb = {okey,s_adr_i[23:13]};

// block RAM: (88 block RAMS)
// PortA: 12 bits wide, 262144 rows deep
// PortB: 24 bits wide, 131072 rows deep
rf6809_MMURam u1 (
  .clka(clk_i),    // input wire clka
  .ena(cs),      // input wire ena
  .wea(cs & s_wr_i),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [17 : 0] addra
  .dina(s_dat_i[11:0]),    // input wire [11 : 0] dina
  .douta(douta),
  .clkb(clk_i),    // input wire clkb
  .enb(1'b1),  // input wire enb
  .web(1'b0),
  .addrb(addrb),  // input wire [13 : 0] addrb
  .dinb(24'h0),
  .doutb(doutb)  // output wire [51 : 0] doutb
);
always_comb
	crwx = doutb[23:20];
end
end
endgenerate

always_ff @(posedge clk_i)
if (s_cs_i)
	s_dat_o <= douta;
else
	s_dat_o <= 12'h0;

// The following delay reg is to keep all the address bits in sync
// with the output of the map table. So there are no intermediate
// invalid addresses.
reg mapen1, mapen2;
reg [31:0] s_adr1, s_adr2;
always @(posedge clk_i)
  s_adr1 <= s_adr_i;
always @(posedge clk_i)
  s_adr2 <= s_adr1;
always @(posedge clk_i)
  cyc1 <= s_cyc_i;
always @(posedge clk_i)
  cyc2 <= cyc1 & s_cyc_i;
always @(posedge clk_i)
  stb1 <= s_stb_i;
always @(posedge clk_i)
  stb2 <= stb1 & s_stb_i;    
always @(posedge clk_i)
	mapen1 <= mapen;
always @(posedge clk_i)
	mapen2 <= mapen1;

always @(posedge clk_i)
if (rst_i) begin
  cyc_o <= 1'b0;
  stb_o <= 1'b0;
  pea_o <= 32'hFFFFFFFE;
end
else begin
	if (SMALL) begin
	 	pea_o[10:0] <= s_adr2[10:0];
		if (mapen2)
	  	pea_o[19:11] <= doutb[8:0];
		else
			pea_o[19:11] <= s_adr2[19:11];
		pea_o[31:20] <= 12'h0;
	end
	else begin
	 	pea_o[12:0] <= s_adr2[12:0];
		if (mapen2)
	  	pea_o[31:13] <= doutb[18:0];
		else
			pea_o[31:13] <= s_adr2[31:13];
	end
  cyc_o <= cyc2 & s_cyc_i;
  stb_o <= stb2 & s_stb_i;
  we_o <= mapen2 ? crwx[1] & s_wr_i : s_wr_i;
end

endmodule
