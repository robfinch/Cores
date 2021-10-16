// ============================================================================
//        __
//   \\__/ o\    (C) 2021  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	Thor2021_btb.sv
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

import Thor2021_pkg::*;

module Thor2021_BTB(rst, clk, clk2x, clk4x,
		wr0, wadr0, wdat0, valid0,
		wr1, wadr1, wdat1, valid1,
		wr2, wadr2, wdat2, valid2,
		rclk, pcA, btgtA, pcB, btgtB,
		pcC, btgtC,
		hitA, hitB, hitC, 
    npcA, npcB, npcC );
parameter AMSB = 31;
parameter RSTIP = 64'hFFC00007FFFC0100;
input rst;
input clk;
input clk2x;
input clk4x;
input wr0;
input Address wadr0;
input Address wdat0;
input valid0;
input wr1;
input Address wadr1;
input Address wdat1;
input valid1;
input wr2;
input Address wadr2;
input Address wdat2;
input valid2;
input rclk;
input Address pcA;
output Address btgtA;
input Address pcB;
output Address btgtB;
input Address pcC;
output Address btgtC;
output hitA;
output hitB;
output hitC;
input Address npcA;
input Address npcB;
input Address npcC;

integer n;
Address pcs [0:31];
Address wdats [0:31];
reg [31:0] vs;
reg [4:0] pcstail,pcshead;
reg [AMSB:0] pc;
reg takb;
reg wrhist;

(* ram_style="block" *)
BTBEntry mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD, radrE, radrF;
initial begin
  for (n = 0; n < 1024; n = n + 1)
    mem[n] <= RSTIP;
end
reg wr;
Address wadr;
reg valid;
Address wdat, wdatx;

always @*
case({clk,clk2x})
2'b00:	
	begin
		wr <= wr0;
		wadr <= wadr0;
		valid <= valid0;
		wdat <= wdat0;
	end
2'b01:
	begin
		wr <= wr1;
		wadr <= wadr1;
		valid <= valid1;
		wdat <= wdat1;
	end
2'b10:
	begin
		wr <= wr2;
		wadr <= wadr2;
		valid <= valid2;
		wdat <= wdat2;
	end
2'b11:
	begin
		wr <= 1'b0;
		wadr <= 1'd0;
		wdat <= 1'b0;
		valid <= 1'b0;
	end
endcase

always @(posedge clk4x)
if (rst)
	pcstail <= 5'd0;
else begin
	if (wr) begin
		pcs[pcstail] <= wadr;
		wdats[pcstail] <= wdat;
		vs[pcstail] <= valid;
		pcstail <= pcstail + 5'd1;
	end	
end

always @(posedge clk)
if (rst)
	pcshead <= 5'd0;
else begin
	wrhist <= 1'b0;
	if (pcshead != pcstail) begin
		pc <= pcs[pcshead];
		takb <= vs[pcshead];
		wdatx <= wdats[pcshead];
		wrhist <= 1'b1;
		pcshead <= pcshead + 5'd1;
	end
end

always @(posedge clk)
begin
    if (wrhist) #1 mem[pc[9:0]].tgtadr <= wdatx;
    if (wrhist) #1 mem[pc[9:0]].insadr <= pc;
    if (wrhist) #1 mem[pc[9:0]].v <= takb;
end

always @(posedge rclk)
    #1 radrA <= pcA[9:0];
always @(posedge rclk)
    #1 radrB <= pcB[9:0];
always @(posedge rclk)
    #1 radrC <= pcC[9:0];
assign hitA = mem[radrA].insadr==pcA && mem[radrA].v;
assign hitB = mem[radrB].insadr==pcB && mem[radrB].v;
assign hitC = mem[radrC].insadr==pcC && mem[radrC].v;
assign btgtA = hitA ? mem[radrA].tgtadr : npcA;
assign btgtB = hitB ? mem[radrB].tgtadr : npcB;
assign btgtC = hitC ? mem[radrC].tgtadr : npcC;

endmodule
