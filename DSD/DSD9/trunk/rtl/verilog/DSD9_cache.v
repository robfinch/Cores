// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	dsd9_cache.v
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
//
// ============================================================================
//
`include "DSD9_defines.vh"

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L1_icache_mem(clk, wr, lineno, i, o, ov, invall, invline);
input clk;
input wr;
input [5:0] lineno;
input [255:0] i;
output [255:0] o;
output ov;
input invall;
input invline;

reg [255:0] mem [0:63];
reg [63:0] valid;

always  @(posedge clk)
    if (wr) mem[lineno] <= i;
always  @(posedge clk)
    if (invall) valid <= 64'd0;
    else if (invline) valid[lineno] <= 1'b0;
    else if (wr) valid[lineno] <= 1'b1;

assign o = mem[lineno];
assign ov = valid[lineno];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L1_icache_tag(wclk, wr, wadr, rclk, rce, radr, hit, invall, invline);
input wclk;
input wr;
input [37:0] wadr;
input rclk;
input rce;
input [37:0] radr;
output hit;
input invall;
input invline;

reg [0:31] tagvalid;
reg [37:0] tagmem [0:31];

always @(posedge wclk)
    if (wr) tagmem[wadr[9:5]] <= wadr;
always @(posedge wclk)
    if (invall)  tagvalid <= 32'd0;
    else if (invline) tagvalid[wadr[9:5]] <= 1'b0;
    else if (wr) tagvalid[wadr[9:5]] <= 1'b1;

assign hit = tagmem[radr[9:5]][37:10]==radr[37:10] && tagvalid[radr[9:5]];

endmodule

module DSD9_L1_icache_camtag(rst, clk, wr, adr, hit, lineno);
input rst;
input clk;
input wr;
input [37:0] adr;
output hit;
output reg [5:0] lineno;

wire [35:0] tagi = {9'b0,adr[37:5]};
wire [63:0] ma;
reg wr2;
wire [21:0] lfsro;
lfsr #(22,22'h0ACE1) u1 (rst, clk, !(wr2|wr), 1'b0, lfsro);

always @(posedge clk)
    wr2 <= wr;

cam36x64 u01 (clk, wr, lfsro[5:0], tagi, tagi, ma);
wire [63:0] match_addr = ma;
assign hit = |match_addr; 

integer n;
always @*
begin
lineno = 0;
for (n = 0; n < 64; n = n + 1)
    if (match_addr[n]) lineno = n;
end

endmodule

module DSD9_L2_icache_camtag(rst, clk, wr, adr, hit, lineno);
input rst;
input clk;
input wr;
input [37:0] adr;
output hit;
output [8:0] lineno;

wire [3:0] set = adr[13:10];
wire [35:0] tagi = {7'd0,adr[37:14],adr[9:5]};
reg [4:0] encadr;
assign lineno[4:0] = encadr;
assign lineno[8:5] = adr[13:10];
reg [15:0] we;
wire [31:0] ma [0:15];
always @*
begin
    we <= 16'h0000;
    we[set] <= wr;
end

reg wr2;
wire [21:0] lfsro;
lfsr #(22,22'h0ACE2) u1 (rst, clk, !(wr2|wr), 1'b0, lfsro);

always @(posedge clk)
    wr2 <= wr;

genvar g;
generate
begin
for (g = 0; g < 16; g = g + 1)
    cam36x32 u01 (clk, we[g], lfsro[4:0], tagi, tagi, ma[g]);
end
endgenerate
wire [31:0] match_addr = ma[set];
assign hit = |match_addr; 

integer n;
always @*
begin
encadr = 0;
for (n = 0; n < 32; n = n + 1)
    if (match_addr[n]) encadr = n;
end

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L1_icache(rst, clk, wr, adr, i, o, hit, invall, invline);
input rst;
input clk;
input wr;
input [37:0] adr;
input [255:0] i;
output reg [39:0] o;
output hit;
input invall;
input invline;

wire [255:0] ic;
wire lv;            // line valid
wire [5:0] lineno;
wire taghit;
reg wr1,wr2;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge clk)
    wr1 <= wr;
always @(posedge clk)
    wr2 <= wr1;

DSD9_L1_icache_mem u1
(
    .clk(clk),
    .wr(wr2),
    .lineno(lineno),
    .i(i),
    .o(ic),
    .ov(lv),
    .invall(invall),
    .invline(invline)
);

DSD9_L1_icache_camtag u2
(
    .rst(rst),
    .clk(clk),
    .wr(wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);

assign hit = taghit & lv;

//always @(radr or ic0 or ic1)
always @(adr or ic)
case(adr[4:0])
5'h00:  o <= ic[39:0];
5'h05:  o <= ic[79:40];
5'h0A:  o <= ic[119:80];
5'h10:  o <= ic[167:128];
5'h15:  o <= ic[207:168];
5'h1A:  o <= ic[247:208];
default:    o <= `IALIGN_FAULT_INSN;
endcase

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L2_icache_mem(clk, wr, lineno, oe, i, o, ov, invall, invline);
input clk;
input wr;
input [8:0] lineno;
input oe;
input [127:0] i;
output [255:0] o;
output reg ov;
input invall;
input invline;

reg [255:0] mem [0:511];
reg [511:0] valid;
reg [8:0] rrcl;

//  instruction parcels per cache line
wire [8:0] cache_line;

wire wr0 = wr & ~oe;
wire wr1 = wr & oe;

always @(posedge clk)
    if (invall) valid <= 512'd0;
    else if (invline) valid[lineno] <= 1'b0;
    else if (wr) valid[lineno] <= 1'b1;

always @(posedge clk)
begin
    if (wr0) mem[lineno][127:0] <= i;
    if (wr1) mem[lineno][255:128] <= i;
end

always @(posedge clk)
    rrcl <= lineno;        
    
always @(posedge clk)
    ov <= valid[lineno];

assign o = mem[rrcl];

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module DSD9_L2_icache(rst, clk, wr, adr, i, o, hit, invall, invline);
input rst;
input clk;
input wr;
input [37:0] adr;
input [127:0] i;
output [255:0] o;
output hit;
input invall;
input invline;

wire [255:0] ic;
wire lv;            // line valid
wire [8:0] lineno;
wire taghit;
reg wr1,wr2;
reg oe1,oe2;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge clk)
    wr1 <= wr;
always @(posedge clk)
    wr2 <= wr1;
always @(posedge clk)
    oe1 <= adr[4];
always @(posedge clk)
    oe2 <= oe1;

DSD9_L2_icache_mem u1
(
    .clk(clk),
    .wr(wr2),
    .lineno(lineno),
    .oe(oe2),
    .i(i),
    .o(o),
    .ov(lv),
    .invall(invall),
    .invline(invline)
);

DSD9_L2_icache_camtag u2
(
    .rst(rst),
    .clk(clk),
    .wr(wr & ~adr[4]),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);

assign hit = taghit & lv;

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache_mem(wclk, wr, wadr, sel, i, rclk, radr, o0, o1);
input wclk;
input wr;
input [13:0] wadr;
input [15:0] sel;
input [127:0] i;
input rclk;
input [13:0] radr;
output [255:0] o0;
output [255:0] o1;

reg [255:0] mem [0:511];
reg [13:0] rradr,rradrp32;

always @(posedge rclk)
    rradr <= radr;        
always @(posedge rclk)
    rradrp32 <= radr + 14'd32;

genvar n;
generate
begin
for (n = 0; n < 16; n = n + 1)
begin : dmem
reg [7:0] mem [31:0][0:511];
always @(posedge wclk)
begin
    if (wr & sel[n] & ~wadr[4]) mem[n][wadr[13:5]] <= i[n*8+7:n*8];
    if (wr & sel[n] & wadr[4]) mem[n+16][wadr[13:5]] <= i[n*8+7:n*8];
end
end
end
endgenerate

generate
begin
for (n = 0; n < 32; n = n + 1)
begin : dmemr
assign o0[n*8+7:n*8] = mem[n][rradr[13:5]];
assign o1[n*8+7:n*8] = mem[n][rradrp32[13:5]];
end
end
endgenerate

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache_tag(wclk, wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input [37:0] wadr;
input rclk;
input [37:0] radr;
output reg hit0;
output reg hit1;

wire [37:0] tago0, tago1;
wire [37:0] radrp32 = radr + 32'd32;

DSD9_dcache_tag1 u1 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(radr[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago0)  // output wire [31 : 0] doutb
);

DSD9_dcache_tag1 u2 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .enb(1'b1),
  .addrb(radrp32[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago1)  // output wire [31 : 0] doutb
);

always @(posedge rclk)
    hit0 <= tago0[37:14]==radr[37:14];
always @(posedge rclk)
    hit1 <= tago1[37:14]==radrp32[37:14];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_dcache(wclk, wr, sel, wadr, i, rclk, rdsize, radr, o, hit, hit0, hit1);
input wclk;
input wr;
input [15:0] sel;
input [37:0] wadr;
input [127:0] i;
input rclk;
input [2:0] rdsize;
input [37:0] radr;
output reg [79:0] o;
output reg hit;
output hit0;
output hit1;
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter penta = 3'd3;
parameter deci = 3'd4;

wire [255:0] dc0, dc1;
wire [13:0] radrp32 = radr + 32'd32;

dcache_mem u1 (
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:4]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radr[13:5]),  // input wire [8 : 0] addrb
  .doutb(dc0)  // output wire [255 : 0] doutb
);

dcache_mem u2 (
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:4]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radrp32[13:5]),  // input wire [8 : 0] addrb
  .doutb(dc1)  // output wire [255 : 0] doutb
);

DSD9_dcache_tag u3
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0),
    .hit1(hit1)
);

// hit0, hit1 are also delayed by a clock already
always @(posedge rclk)
    o <= {dc1,dc0} >> {radr[4:0],3'b0};

always @*
    if (hit0 & hit1)
        hit = `TRUE;
    else if (hit0) begin
        case(rdsize)
        wyde:   hit = radr[4:0] <= 5'h1E;
        tetra:  hit = radr[4:0] <= 5'h1C;
        penta:  hit = radr[4:0] <= 5'h1B;
        deci:   hit = radr[4:0] <= 5'h16;
        default:    hit = `TRUE;    // byte
        endcase
    end
    else
        hit = `FALSE;

endmodule

module dcache_mem(clka, ena, wea, addra, dina, clkb, addrb, doutb);
input clka;
input ena;
input [15:0] wea;
input [9:0] addra;
input [127:0] dina;
input clkb;
input [8:0] addrb;
output reg [255:0] doutb;

reg [255:0] mem [0:511];
reg [255:0] doutb1;

genvar g;
generate begin
for (g = 0; g < 16; g = g + 1)
begin
always @(posedge clka)
    if (ena & wea[g] & ~addra[0]) mem[addra[9:1]][g*8+7:g*8] <= dina[g*8+7:g*8];
always @(posedge clka)
    if (ena & wea[g] & addra[0]) mem[addra[9:1]][g*8+7+128:g*8+128] <= dina[g*8+7:g*8];
end
end
endgenerate
always @(posedge clkb)
    doutb1 <= mem[addrb];
always @(posedge clkb)
    doutb <= doutb1;

endmodule
