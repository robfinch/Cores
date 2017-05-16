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

module DSD9_L1_icache_mem(wclk, wr, wadr, i, rclk, rce, radr, o);
input wclk;
input wr;
input [31:0] wadr;
input [255:0] i;
input rclk;
input rce;
input [31:0] radr;
output [255:0] o;

reg [255:0] mem [0:63];

wire [5:0] wr_cache_line;
wire [5:0] rd_cache_line;
assign wr_cache_line = wadr >> 5;
assign rd_cache_line = radr >> 5;

always  @(posedge wclk)
    if (wr) mem[wr_cache_line] <= i;

assign o = mem[rd_cache_line];

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

reg [0:63] tagvalid;
reg [37:0] tagmem [0:63];

always @(posedge wclk)
    if (wr) tagmem[wadr[10:5]] <= wadr;
always @(posedge wclk)
    if (invall)  tagvalid <= 64'd0;
    else if (invline) tagvalid[wadr[10:5]] <= 1'b0;
    else if (wr) tagvalid[wadr[10:5]] <= 1'b1;

assign hit = tagmem[radr[10:5]][37:11]==radr[37:11] && tagvalid[radr[10:5]];

endmodule

module DSD9_L1_icache_camtag(clk, wr, adr, hit, cadr);
input clk;
input wr;
input [37:0] adr;
output hit;
output [37:0] cadr;

wire [32:0] tagi = adr[37:5];
reg [4:0] encadr;
assign cadr[4:0] = adr[4:0];
assign cadr[9:5] = encadr;
wire [31:0] ma;

DSD9_cam36x32 u01 (clk, wr, (32'd1 << adr[9:5]), tagi, tagi, ma);
wire [31:0] match_addr = ma;
assign hit = |match_addr; 

integer n;
always @*
begin
encadr = 0;
for (n = 0; n < 32; n = n + 1)
    if (match_addr[n]) encadr = n;
end

endmodule

module DSD9_L2_icache_camtag(clk, wr, adr, hit, cadr);
input clk;
input wr;
input [37:0] adr;
output hit;
output [37:0] cadr;

wire [3:0] set = adr[13:10];
wire [28:0] tagi = {adr[37:14],adr[9:5]};
reg [4:0] encadr;
assign cadr[4:0] = adr[4:0];
assign cadr[9:5] = encadr;
assign cadr[13:10] = adr[13:10];
reg [15:0] we;
wire [31:0] ma [0:15];
always @*
begin
    we <= 16'h0000;
    we[set] <= wr;
end

genvar g;
generate
begin
for (g = 0; g < 16; g = g + 1)
    DSD9_cam36x32 u01 (clk, we[g], (32'd1 << adr[9:5]), tagi, tagi, ma[g]);
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

module DSD9_L1_icache(wclk, wr, wadr, i, rclk, rce, radr, o, hit, invall, invline);
input wclk;
input wr;
input [37:0] wadr;
input [255:0] i;
input rclk;
input rce;
input [37:0] radr;
output reg [119:0] o;
output hit;
input invall;
input invline;

wire [255:0] ic;

DSD9_L1_icache_mem u1
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr[31:0]),
    .i(i),
    .rclk(rclk),
    .rce(rce),
    .radr(radr[31:0]),
    .o(ic)
);

DSD9_L1_icache_tag u2
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .rce(rce),
    .radr(radr),
    .hit(hit),
    .invall(invall),
    .invline(invline)
);

//always @(radr or ic0 or ic1)
always @(radr or ic)
case(radr[4:0])
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

module DSD9_L2_icache_mem(wclk, wr, wadr, i, rclk, rce, radr, o);
input wclk;
input wr;
input [31:0] wadr;
input [127:0] i;
input rclk;
input rce;
input [31:0] radr;
output [255:0] o;

reg [255:0] mem [0:511];
reg [8:0] rrcl;

//  instruction parcels per cache line
wire [8:0] wr_cache_line;
wire [8:0] rd_cache_line;

assign wr_cache_line = wadr >> 5;
assign rd_cache_line = radr >> 5;
wire wr0 = wr & ~wadr[4];
wire wr1 = wr & wadr[4];

always @(posedge wclk)
begin
    if (wr0) mem[wr_cache_line][127:0] <= i;
    if (wr1) mem[wr_cache_line][255:128] <= i;
end

always @(posedge rclk)
    if (rce) rrcl <= rd_cache_line;        
    
assign o = mem[rrcl];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L2_icache_tag(wclk, wr, wadr, rclk, rce, radr, hit, invall, invline);
input wclk;
input wr;
input [37:0] wadr;
input rclk;
input rce;
input [37:0] radr;
output hit;
input invall;
input invline;

reg [37:0] tagmem [0:511];
reg [511:0] tagvalid;
reg [37:0] rradr;

always @(posedge rclk)
    if (rce) rradr <= radr;        

always @(posedge wclk)
    if (invall) tagvalid <= 512'd0;
    else if (invline) tagvalid[wadr[13:5]] <= 1'b0;
    else if (wr) tagvalid[wadr[13:5]] <= 1'b1;
always @(posedge wclk)
    if (wr) tagmem[wadr[13:5]] <= wadr;

assign hit = tagmem[rradr[13:5]][37:14]==rradr[37:14] && tagvalid[rradr[13:5]]==1'b1;

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module DSD9_L2_icache(wclk, wr, wadr, i, rclk, rce, radr, o, hit, invall, invline);
input wclk;
input wr;
input [37:0] wadr;
input [127:0] i;
input rclk;
input rce;
input [37:0] radr;
output reg [255:0] o;
output reg hit;
input invall;
input invline;

wire [255:0] ic;
reg [37:0] rradr1;
wire hita;

DSD9_L2_icache_mem u1
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr[31:0]),
    .i(i),
    .rclk(rclk),
    .rce(rce),
    .radr(radr[31:0]),
    .o(ic)
);

DSD9_L2_icache_tag u2
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .rce(rce),
    .radr(radr),
    .hit(hita),
    .invall(invall),
    .invline(invline)
);

//always @(radr or ic0 or ic1)
always @(posedge rclk)
if (rce)
    o <= ic;

always @(posedge rclk)
    if (rce)
        hit <= hita;

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
