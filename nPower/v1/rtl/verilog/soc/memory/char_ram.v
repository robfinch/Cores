// ============================================================================
//        __
//   \\__/ o\    (C) 2018-2020  Robert Finch, Waterloo
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
module char_ram(clk_i, cs_i, we_i, adr_i, dat_i, dat_o, dot_clk_i, ce_i,
  fontAddress_i, char_code_i, maxScanpix_i, maxscanline_i, scanline_i, bmp_o);
input clk_i;
input cs_i;
input we_i;
input [14:0] adr_i;
input [7:0] dat_i;
output reg [31:0] dat_o = 32'd0;
input dot_clk_i;
input ce_i;
input [15:0] fontAddress_i;
input [19:0] char_code_i;
input [5:0] maxScanpix_i;
input [5:0] maxscanline_i;
input [5:0] scanline_i;
output reg [63:0] bmp_o;

(* ram_style="block" *)
reg [7:0] mem [0:32767];
reg [14:0] radr;
reg [14:0] rcc, rcc0, rcc1;
reg [2:0] rcc200, rcc201, rcc202;
reg [63:0] dat1;
reg [63:0] bmp1;
reg [3:0] bndx, b2ndx;
reg [7:0] bmp [0:7];
reg [63:0] buf2;

initial begin
`include "d:\\cores2020\\nPower\\v1\\rtl\\verilog\\soc\\memory\\char_bitmaps_12x18.v";
end

wire pe_cs;
edge_det ued1 (.rst(1'b0), .clk(clk_i), .ce(1'b1), .i(cs_i), .pe(pe_cs), .ne(), .ee());

always @(posedge clk_i)
  if (cs_i & we_i)
	  mem[adr_i] <= dat_i;

// Char code is already delated two clocks relative to ce
// Assume that characters are always going to be at least four clocks wide.
// Clock #0
always @(posedge dot_clk_i)
  if (ce_i)
    rcc <= char_code_i*maxscanline_i+scanline_i;
// Clock #1
always @(posedge dot_clk_i)
  casez(maxScanpix_i[5:3])
  3'b1??: rcc0 <= {rcc,3'b0};
//  3'b110: rcc0 <= {rcc,2'b0} + {rcc,1'b0};
//  3'b101: rcc0 <= {rcc,2'b0} + rcc;
  3'b01?: rcc0 <= {rcc,2'b0};
//  3'b010: rcc0 <= {rcc,1'b0} + rcc;
  3'b001: rcc0 <= {rcc,1'b0};
  3'b000: rcc0 <=  rcc;
  endcase
// Clock #2
always @(posedge dot_clk_i)
  if (ce_i) begin
    rcc1 <= {fontAddress_i[15:3],3'b0}+rcc0;
    casez(maxScanpix_i[5:3])
    3'b1??: bndx <= 4'd7;
    3'b01?: bndx <= 4'd3;
    3'b001: bndx <= 4'd1;
    3'b000: bndx <= 4'd0;
    endcase
  end
  else begin
    if (~bndx[3]) begin
      bmp[bndx[2:0]] <= mem[rcc1];
      rcc1 <= rcc1 + 1'd1;
      bndx <= bndx - 1'd1;
    end
  end
always @(posedge dot_clk_i)
  if (ce_i)
 	  bmp_o <= {bmp[7],bmp[6],bmp[5],bmp[4],bmp[3],bmp[2],bmp[1],bmp[0]};

endmodule
