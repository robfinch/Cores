// ============================================================================
//        __
//   \\__/ o\    (C) 2017  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	FT64_cache.v
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
`define TRUE    1'b1
`define FALSE   1'b0
`define BRK         6'd0
`define FLT_EXF     9'd497
`define FLT_IBE     9'd509

// -----------------------------------------------------------------------------
// Small, 64 line cache memory (2kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module FT64_L1_icache_mem(rst, clk, wr, lineno, i, o, ov, invall, invline);
input rst;
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
if (rst)
    valid <= 64'd0;
else begin
    if (invall) valid <= 64'd0;
    else if (invline) valid[lineno] <= 1'b0;
    else if (wr) valid[lineno] <= 1'b1;
end

assign o = mem[lineno];
assign ov = valid[lineno];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// Fully associative (64 way) tag memory for L1 icache.
module FT64_L1_icache_camtag(rst, clk, nxt, wr, adr, hit, lineno);
input rst;
input clk;
input nxt;
input wr;
input [37:0] adr;
output hit;
output reg [5:0] lineno;

wire [35:0] tagi = {9'b0,adr[37:5]};
wire [63:0] match_addr;

reg [5:0] cntr;
always @(posedge clk)
if (rst)
    cntr <= 6'd0;
else begin
    if (nxt) cntr <= cntr + 6'd1;
end
    
//wire [21:0] lfsro;
//lfsr #(22,22'h0ACE1) u1 (rst, clk, !(wr3|wr2|wr), 1'b0, lfsro);

cam36x64 u01 (rst, clk, wr, cntr[5:0], tagi, tagi, match_addr);
assign hit = |match_addr; 

integer n;
always @*
begin
lineno = 0;
for (n = 0; n < 64; n = n + 1)
    if (match_addr[n]) lineno = n;
end

endmodule

// 32 way, 16 set associative tag memory for L2 cache
module FT64_L2_icache_camtag(rst, clk, wr, adr, hit, lineno);
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

module FT64_L1_icache(rst, clk, nxt, wr, adr, i, o, hit, invall, invline);
input rst;
input clk;
input nxt;
input wr;
input [37:0] adr;
input [255:0] i;
output reg [31:0] o;
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

FT64_L1_icache_mem u1
(
    .rst(rst),
    .clk(clk),
    .wr(wr2),
    .lineno(lineno),
    .i(i),
    .o(ic),
    .ov(lv),
    .invall(invall),
    .invline(invline)
);

FT64_L1_icache_camtag u2
(
    .rst(rst),
    .clk(clk),
    .nxt(nxt),
    .wr(wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);

assign hit = taghit & lv;

//always @(radr or ic0 or ic1)
always @(adr or ic)
case(adr[4:2])
3'd0:  o <= ic[31:0];
3'd1:  o <= ic[63:32];
3'd2:  o <= ic[95:64];
3'd3:  o <= ic[127:96];
3'd4:  o <= ic[159:128];
3'd5:  o <= ic[191:160];
3'd6:  o <= ic[223:192];
3'd7:  o <= ic[255:224];
endcase

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_L2_icache_mem(clk, wr, lineno, sel, i, o, ov, invall, invline);
input clk;
input wr;
input [8:0] lineno;
input [1:0] sel;
input [63:0] i;
output [255:0] o;
output reg ov;
input invall;
input invline;

reg [63:0] mem0 [0:511];
reg [63:0] mem1 [0:511];
reg [63:0] mem2 [0:511];
reg [63:0] mem3 [0:511];
reg [511:0] valid;
reg [8:0] rrcl;

//  instruction parcels per cache line
wire [8:0] cache_line;
integer n;
initial begin
    for (n = 0; n < 512; n = n + 1)
        valid[n] <= 0;
end

always @(posedge clk)
    if (invall) valid <= 512'd0;
    else if (invline) valid[lineno] <= 1'b0;
    else if (wr) valid[lineno] <= 1'b1;

always @(posedge clk)
begin
    if (wr)
        case(sel[1:0])
        2'd0:   mem0[lineno] <= i;
        2'd1:   mem1[lineno] <= i;
        2'd2:   mem2[lineno] <= i;
        2'd3:   mem3[lineno] <= i;
        endcase
end

always @(posedge clk)
    rrcl <= lineno;        
    
always @(posedge clk)
    ov <= valid[lineno];

assign o = {mem3[rrcl],mem2[rrcl],mem1[rrcl],mem0[rrcl]};

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module FT64_L2_icache(rst, clk, nxt, wr, adr, exv_i, i, err_i, o, hit, invall, invline);
parameter CAMTAGS = 1'b0;   // 32 way
parameter FOURWAY = 1'b1;
input rst;
input clk;
input nxt;
input wr;
input [37:0] adr;
input exv_i;
input [63:0] i;
input err_i;
output [255:0] o;
output hit;
input invall;
input invline;

wire lv;            // line valid
wire [8:0] lineno;
wire taghit;
reg wr1,wr2;
reg [1:0] sel1,sel2;
reg [63:0] i1,i2;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. camTag memory takes two clock cycles to update.
always @(posedge clk)
    wr1 <= wr;
always @(posedge clk)
    wr2 <= wr1;
always @(posedge clk)
    sel1 <= adr[4:3];
always @(posedge clk)
    sel2 <= sel1;
// An exception is forced to be stored in the event of an error loading the
// the instruction line.
always @(posedge clk)
    i1 <= err_i ? {2{16'd0,1'b0,`FLT_IBE,`BRK}} : exv_i ? {2{16'd0,1'b0,`FLT_EXF,`BRK}} : i;
always @(posedge clk)
    i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && adr[4:0]==5'd0), .pe(pe_wr), .ne(), .ee() );

FT64_L2_icache_mem u1
(
    .clk(clk),
    .wr(wr2),
    .lineno(lineno),
    .sel(sel2),
    .i(i2),
    .o(o),
    .ov(lv),
    .invall(invall),
    .invline(invline)
);

generate
begin : tags
if (FOURWAY)
FT64_L2_icache_cmptag4way u2
(
    .rst(rst),
    .clk(clk),
    .nxt(nxt),
    .wr(pe_wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);
else if (CAMTAGS)
FT64_L2_icache_camtag u2
(
    .rst(rst),
    .clk(clk),
    .wr(pe_wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);
else
FT64_L2_icache_cmptag u2
(
    .rst(rst),
    .clk(clk),
    .wr(pe_wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);
end
endgenerate

assign hit = taghit & lv;

endmodule

// Four way set associative tag memory
module FT64_L2_icache_cmptag4way(rst, clk, nxt, wr, adr, lineno, hit);
input rst;
input clk;
input nxt;
input wr;
input [37:0] adr;
output reg [8:0] lineno;
output hit;

reg [32:0] mem0 [0:127];
reg [32:0] mem1 [0:127];
reg [32:0] mem2 [0:127];
reg [32:0] mem3 [0:127];
reg [37:0] rradr;
integer n;
initial begin
    for (n = 0; n < 128; n = n + 1)
    begin
        mem0[n] = 0;
        mem1[n] = 0;
        mem2[n] = 0;
        mem3[n] = 0;
    end
end

reg wr2;
always @(posedge clk)
    wr2 <= wr;
wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [8:0] wlineno;
always @(posedge clk)
begin
    if (wr && lfsro[1:0]==2'b00) begin mem0[adr[11:5]] <= adr[37:5]; wlineno <= {2'b00,adr[11:5]}; end
    if (wr && lfsro[1:0]==2'b01) begin mem1[adr[11:5]] <= adr[37:5]; wlineno <= {2'b01,adr[11:5]}; end
    if (wr && lfsro[1:0]==2'b10) begin mem2[adr[11:5]] <= adr[37:5]; wlineno <= {2'b10,adr[11:5]}; end
    if (wr && lfsro[1:0]==2'b11) begin mem3[adr[11:5]] <= adr[37:5]; wlineno <= {2'b11,adr[11:5]}; end
end
always @(posedge clk)
    rradr <= adr;
wire hit0 = mem0[rradr[11:5]]==rradr[37:5];
wire hit1 = mem1[rradr[11:5]]==rradr[37:5];
wire hit2 = mem2[rradr[11:5]]==rradr[37:5];
wire hit3 = mem3[rradr[11:5]]==rradr[37:5];
always @*
    //if (wr2) lineno = wlineno;
    if (hit0) lineno = {2'b00,rradr[11:5]};
    else if (hit1) lineno = {2'b01,rradr[11:5]};
    else if (hit2) lineno = {2'b10,rradr[11:5]};
    else lineno = {2'b11,rradr[11:5]};
assign hit = hit0|hit1|hit2|hit3;
endmodule

// Simple tag array, 1-way direct mapped
module FT64_L2_icache_cmptag(rst, clk, wr, adr, lineno, hit);
input rst;
input clk;
input wr;
input [37:0] adr;
output reg [8:0] lineno;
output hit;

reg [23:0] mem [0:511];
reg [37:0] rradr;
integer n;
initial begin
    for (n = 0; n < 512; n = n + 1)
    begin
        mem[n] = 0;
    end
end

reg wr2;
always @(posedge clk)
    wr2 <= wr;
reg [8:0] wlineno;
always @(posedge clk)
begin
    if (wr) begin mem[adr[13:5]] <= adr[37:14]; wlineno <= adr[13:5]; end
end
always @(posedge clk)
    rradr <= adr;
wire hit = mem[rradr[13:5]]==rradr[37:14];
always @*
    if (wr2) lineno = wlineno;
    else lineno = rradr[13:5];
endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_dcache_mem(wclk, wr, wadr, i, rclk, radr, o0, o1);
input wclk;
input wr;
input [11:0] wadr;
input [63:0] i;
input rclk;
input [11:0] radr;
output [255:0] o0;
output [255:0] o1;

reg [11:0] rradr,rradrp8;

always @(posedge rclk)
    rradr <= radr;        
always @(posedge rclk)
    rradrp8 <= radr + 14'd8;

genvar n;
generate
begin
for (n = 0; n < 8; n = n + 1)
begin : dmem
reg [7:0] mem [7:0][0:511];
always @(posedge wclk)
begin
    if (wr && (wadr[2:0]==n)) mem[n][wadr[11:3]] <= i;
end
assign o0[n*32+31:n*32] = mem[n][rradr[11:3]];
assign o1[n*32+31:n*32] = mem[n][rradrp8[11:3]];
end
end
endgenerate

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_dcache_tag(wclk, wr, wadr, rclk, radr, hit0, hit1);
input wclk;
input wr;
input [37:0] wadr;
input rclk;
input [37:0] radr;
output reg hit0;
output reg hit1;

wire [31:0] tago0, tago1;
wire [37:0] radrp8 = radr + 32'd32;

FT64_dcache_tag2 u1 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr[37:6]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .web(1'b0),
  .dinb(32'd0),
  .enb(1'b1),
  .addrb(radr[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago0)  // output wire [31 : 0] doutb
);

FT64_dcache_tag2 u2 (
  .clka(wclk),    // input wire clka
  .ena(1'b1),      // input wire ena
  .wea(wr),      // input wire [0 : 0] wea
  .addra(wadr[13:5]),  // input wire [8 : 0] addra
  .dina(wadr[37:6]),    // input wire [31 : 0] dina
  .clkb(rclk),    // input wire clkb
  .web(1'b0),
  .dinb(32'd0),
  .enb(1'b1),
  .addrb(radrp8[13:5]),  // input wire [8 : 0] addrb
  .doutb(tago1)  // output wire [31 : 0] doutb
);

always @(posedge rclk)
    hit0 <= tago0[31:8]==radr[37:14];
always @(posedge rclk)
    hit1 <= tago1[31:8]==radrp8[37:14];

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_dcache(rst, wclk, wr, sel, wadr, i, rclk, rdsize, radr, o, hit, hit0, hit1);
input rst;
input wclk;
input wr;
input [7:0] sel;
input [37:0] wadr;
input [63:0] i;
input rclk;
input [2:0] rdsize;
input [37:0] radr;
output reg [63:0] o;
output reg hit;
output reg hit0;
output reg hit1;
parameter byt = 3'd0;
parameter wyde = 3'd1;
parameter tetra = 3'd2;
parameter octa = 3'd3;

wire [255:0] dc0, dc1;
wire [31:0] v0, v1;
wire [13:0] radrp8 = radr + 32'd32;
wire hit0a, hit1a;

dcache_mem u1 (
  .rst(rst),
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:0]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radr[13:0]),  // input wire [8 : 0] addrb
  .doutb(dc0),  // output wire [255 : 0] doutb
  .ov(v0)
);

dcache_mem u2 (
  .rst(rst),
  .clka(wclk),    // input wire clka
  .ena(wr),      // input wire ena
  .wea(sel),      // input wire [15 : 0] wea
  .addra(wadr[13:0]),  // input wire [9 : 0] addra
  .dina(i),    // input wire [127 : 0] dina
  .clkb(rclk),    // input wire clkb
  .addrb(radrp8[13:0]),  // input wire [8 : 0] addrb
  .doutb(dc1),  // output wire [255 : 0] doutb
  .ov(v1)
);

FT64_dcache_tag u3
(
    .wclk(wclk),
    .wr(wr),
    .wadr(wadr),
    .rclk(rclk),
    .radr(radr),
    .hit0(hit0a),
    .hit1(hit1a)
);

wire [7:0] v0a = v0 >> radr[4:0];
wire [7:0] v1a = v1 >> radrp8[4:0];
always @*
case(rdsize)
byt:    begin
        hit0 = hit0a & v0a[0];
        hit1 = `TRUE;
        end 
wyde:   begin
        hit0 = hit0a & &v0a[1:0];
        hit1 = radr[2:0]==3'b111 ? hit1a & v1a[0] : `TRUE;
        end
tetra:  begin
        hit0 = hit0a & &v0a[3:0];
        case(radr[2:0])
        3'd5:      hit1 = hit1a & v1a[0];
        3'd6:      hit1 = hit1a & &v1a[1:0];
        3'd7:      hit1 = hit1a & &v1a[2:0];
        default:   hit1 = `TRUE;   
        endcase
        end
octa:   begin
        hit0 = hit0a & &v0a[7:0];
        case(radr[2:0])
        3'd1:      hit1 = hit1a & v1a[0];
        3'd2:      hit1 = hit1a & &v1a[1:0];
        3'd3:      hit1 = hit1a & &v1a[2:0];
        3'd4:      hit1 = hit1a & &v1a[3:0];
        3'd5:      hit1 = hit1a & &v1a[4:0];
        3'd6:      hit1 = hit1a & &v1a[5:0];
        3'd7:      hit1 = hit1a & &v1a[6:0];
        default:   hit1 = `TRUE;   
        endcase
        end
default:    begin
            hit0 = 1'b0;
            hit1 = 1'b0;
            end
endcase

// hit0, hit1 are also delayed by a clock already
always @(posedge rclk)
    o <= {dc1,dc0} >> (radr[4:0] * 8);

always @*
    if (hit0 & hit1)
        hit = `TRUE;
/*        
    else if (hit0) begin
        case(rdsize)
        wyde:   hit = radr[4:0] <= 5'h1E;
        tetra:  hit = radr[4:0] <= 5'h1C;
        penta:  hit = radr[4:0] <= 5'h1B;
        deci:   hit = radr[4:0] <= 5'h16;
        default:    hit = `TRUE;    // byte
        endcase
    end
*/
    else
        hit = `FALSE;

endmodule

module dcache_mem(rst, clka, ena, wea, addra, dina, clkb, addrb, doutb, ov);
input rst;
input clka;
input ena;
input [7:0] wea;
input [13:0] addra;
input [63:0] dina;
input clkb;
input [13:0] addrb;
output reg [255:0] doutb;
output reg [31:0] ov;

reg [255:0] mem [0:511];
reg [31:0] valid [0:511];
reg [255:0] doutb1;
reg [31:0] ov1;

integer n;

initial begin
    for (n = 0; n < 512; n = n + 1)
        valid[n] = 32'h00;
end

genvar g;
generate begin
for (g = 0; g < 4; g = g + 1)
always @(posedge clka)
begin
    if (ena & wea[0] & addra[4:3]==g) mem[addra[13:5]][g*64+7:g*64] <= dina[7:0];
    if (ena & wea[1] & addra[4:3]==g) mem[addra[13:5]][g*64+15:g*64+8] <= dina[15:8];
    if (ena & wea[2] & addra[4:3]==g) mem[addra[13:5]][g*64+23:g*64+16] <= dina[23:16];
    if (ena & wea[3] & addra[4:3]==g) mem[addra[13:5]][g*64+31:g*64+24] <= dina[31:24];
    if (ena & wea[4] & addra[4:3]==g) mem[addra[13:5]][g*64+39:g*64+32] <= dina[39:32];
    if (ena & wea[5] & addra[4:3]==g) mem[addra[13:5]][g*64+47:g*64+40] <= dina[47:40];
    if (ena & wea[6] & addra[4:3]==g) mem[addra[13:5]][g*64+55:g*64+48] <= dina[55:48];
    if (ena & wea[7] & addra[4:3]==g) mem[addra[13:5]][g*64+63:g*64+56] <= dina[63:56];
    if (ena & wea[0] & addra[4:3]==g) valid[addra[13:5]][g*8] <= 1'b1;
    if (ena & wea[1] & addra[4:3]==g) valid[addra[13:5]][g*8+1] <= 1'b1;
    if (ena & wea[2] & addra[4:3]==g) valid[addra[13:5]][g*8+2] <= 1'b1;
    if (ena & wea[3] & addra[4:3]==g) valid[addra[13:5]][g*8+3] <= 1'b1;
    if (ena & wea[4] & addra[4:3]==g) valid[addra[13:5]][g*8+4] <= 1'b1;
    if (ena & wea[5] & addra[4:3]==g) valid[addra[13:5]][g*8+5] <= 1'b1;
    if (ena & wea[6] & addra[4:3]==g) valid[addra[13:5]][g*8+6] <= 1'b1;
    if (ena & wea[7] & addra[4:3]==g) valid[addra[13:5]][g*8+7] <= 1'b1;
end
end
endgenerate
always @(posedge clkb)
    doutb1 <= mem[addrb[13:5]];
always @(posedge clkb)
    doutb <= doutb1;
always @(posedge clkb)
    ov1 <= valid[addrb[13:5]];
always @(posedge clkb)
    ov <= ov1;
endmodule

// -----------------------------------------------------------------------------
// Branch target buffer.
// -----------------------------------------------------------------------------

module FT64_BTB(rst, wclk, wr, wadr, wdat, valid, rclk, pcA, btgtA, pcB, btgtB, pcC, btgtC, pcD, btgtD);
parameter RSTPC = 32'hFFFC0100;
input rst;
input wclk;
input wr;
input [31:0] wadr;
input [31:0] wdat;
input valid;
input rclk;
input [31:0] pcA;
output [31:0] btgtA;
input [31:0] pcB;
output [31:0] btgtB;
input [31:0] pcC;
output [31:0] btgtC;
input [31:0] pcD;
output [31:0] btgtD;

integer n;
reg [60:0] mem [0:1023];
reg [9:0] radrA, radrB, radrC, radrD;
initial begin
    for (n = 0; n < 1024; n = n + 1)
        mem[n] <= RSTPC[31:2];
end
always @(posedge wclk)
//if (rst) begin
//    // Zero out valid bit
//    for (n = 0; n < 1024; n = n + 1)
//        mem[n] <= RSTPC[31:2];
//end
//else
begin
    if (wr) mem[wadr[11:2]][29:0] <= wdat[31:2];
    if (wr) mem[wadr[11:2]][59:30] <= wadr[31:2];
    if (wr) mem[wadr[11:2]][60] <= valid;
end
always @(posedge rclk)
    radrA <= pcA[11:2];
always @(posedge rclk)
    radrB <= pcB[11:2];
always @(posedge rclk)
    radrC <= pcC[11:2];
always @(posedge rclk)
    radrD <= pcD[11:2];
wire hitA = mem[radrA][59:30]==pcA[31:2] && mem[radrA][60];
wire hitB = mem[radrB][59:30]==pcB[31:2] && mem[radrB][60];
wire hitC = mem[radrC][59:30]==pcC[31:2] && mem[radrC][60];
wire hitD = mem[radrD][59:30]==pcD[31:2] && mem[radrD][60];
assign btgtA = hitA ? {mem[radrA][29:0],2'b00} : {pcA + 32'd4};
assign btgtB = hitB ? {mem[radrB][29:0],2'b00} : {pcB + 32'd4};
assign btgtC = hitC ? {mem[radrC][29:0],2'b00} : {pcC + 32'd4};
assign btgtD = hitD ? {mem[radrD][29:0],2'b00} : {pcD + 32'd4};

endmodule
