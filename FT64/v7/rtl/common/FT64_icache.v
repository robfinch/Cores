// ============================================================================
//        __
//   \\__/ o\    (C) 2017-2019  Robert Finch, Waterloo
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

// -----------------------------------------------------------------------------
// Small, 64 line cache memory (2kiB) made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module FT64_L1_icache_mem(rst, clk, wr, en, lineno, i, o, ov, invall, invline);
parameter pLines = 64;
parameter pLineWidth = 306;
localparam pLNMSB = pLines==128 ? 6 : 5;
input rst;
input clk;
input wr;
input [9:0] en;
input [pLNMSB:0] lineno;
input [pLineWidth-1:0] i;
output [pLineWidth-1:0] o;
output [9:0] ov;
input invall;
input invline;

integer n;

(* ram_style="distributed" *)
reg [pLineWidth-1:0] mem [0:pLines-1];
reg [pLines-1:0] valid0;
reg [pLines-1:0] valid1;
reg [pLines-1:0] valid2;
reg [pLines-1:0] valid3;
reg [pLines-1:0] valid4;
reg [pLines-1:0] valid5;
reg [pLines-1:0] valid6;
reg [pLines-1:0] valid7;
reg [pLines-1:0] valid8;
reg [pLines-1:0] valid9;

initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] <= 2'b00;
end

always  @(posedge clk)
    if (wr & en[0])  mem[lineno][31:0] <= i[31:0];
always  @(posedge clk)
    if (wr & en[1])  mem[lineno][63:32] <= i[63:32];
always  @(posedge clk)
    if (wr & en[2])  mem[lineno][95:64] <= i[95:64];
always  @(posedge clk)
    if (wr & en[3])  mem[lineno][127:96] <= i[127:96];
always  @(posedge clk)
    if (wr & en[4])  mem[lineno][159:128] <= i[159:128];
always  @(posedge clk)
    if (wr & en[5])  mem[lineno][191:160] <= i[191:160];
always  @(posedge clk)
    if (wr & en[6])  mem[lineno][223:192] <= i[223:192];
always  @(posedge clk)
    if (wr & en[7])  mem[lineno][255:224] <= i[255:224];
always  @(posedge clk)
    if (wr & en[8])  mem[lineno][287:256] <= i[287:256];
always  @(posedge clk)
    if (wr & en[9])  mem[lineno][305:288] <= i[305:288];
always  @(posedge clk)
if (rst) begin
     valid0 <= 64'd0;
     valid1 <= 64'd0;
     valid2 <= 64'd0;
     valid3 <= 64'd0;
     valid4 <= 64'd0;
     valid5 <= 64'd0;
     valid6 <= 64'd0;
     valid7 <= 64'd0;
     valid8 <= 64'd0;
     valid9 <= 64'd0;
end
else begin
    if (invall) begin
    	valid0 <= 64'd0;
    	valid1 <= 64'd0;
    	valid2 <= 64'd0;
    	valid3 <= 64'd0;
    	valid4 <= 64'd0;
    	valid5 <= 64'd0;
    	valid6 <= 64'd0;
    	valid7 <= 64'd0;
			valid8 <= 64'd0;
			valid9 <= 64'd0;
    end
    else if (invline) begin
    	valid0[lineno] <= 1'b0;
    	valid1[lineno] <= 1'b0;
    	valid2[lineno] <= 1'b0;
    	valid3[lineno] <= 1'b0;
    	valid4[lineno] <= 1'b0;
    	valid5[lineno] <= 1'b0;
    	valid6[lineno] <= 1'b0;
    	valid7[lineno] <= 1'b0;
    	valid8[lineno] <= 1'b0;
    	valid9[lineno] <= 1'b0;
	end
    else if (wr) begin
    	if (en[0]) valid0[lineno] <= 1'b1;
    	if (en[1]) valid1[lineno] <= 1'b1;
    	if (en[2]) valid2[lineno] <= 1'b1;
    	if (en[3]) valid3[lineno] <= 1'b1;
    	if (en[4]) valid4[lineno] <= 1'b1;
    	if (en[5]) valid5[lineno] <= 1'b1;
    	if (en[6]) valid6[lineno] <= 1'b1;
    	if (en[7]) valid7[lineno] <= 1'b1;
    	if (en[8]) valid8[lineno] <= 1'b1;
    	if (en[9]) valid9[lineno] <= 1'b1;
    end
end

assign o = mem[lineno];
assign ov[0] = valid0[lineno];
assign ov[1] = valid1[lineno];
assign ov[2] = valid2[lineno];
assign ov[3] = valid3[lineno];
assign ov[4] = valid4[lineno];
assign ov[5] = valid5[lineno];
assign ov[6] = valid6[lineno];
assign ov[7] = valid7[lineno];
assign ov[8] = valid8[lineno];
assign ov[9] = valid9[lineno];

endmodule

// -----------------------------------------------------------------------------
// Fully associative (64 way) tag memory for L1 icache.
//
// -----------------------------------------------------------------------------

module FT64_L1_icache_camtag(rst, clk, nxt, wlineno, wr, wadr, adr, hit, lineno);
input rst;
input clk;
input nxt;
output [5:0] wlineno;
input wr;
input [37:0] adr;
input [37:0] wadr;
output hit;
output reg [5:0] lineno;

wire [35:0] wtagi = {9'b0,wadr[37:5]};
wire [35:0] tagi = {9'b0,adr[37:5]};
wire [63:0] match_addr;

reg [5:0] cntr;
always @(posedge clk)
if (rst)
     cntr <= 6'd0;
else begin
    if (nxt)  cntr <= cntr + 6'd1;
end
assign wlineno = cntr;
    
//wire [21:0] lfsro;
//lfsr #(22,22'h0ACE1) u1 (rst, clk, !(wr3|wr2|wr), 1'b0, lfsro);

cam36x64 u01 (rst, clk, wr, cntr[5:0], wtagi, tagi, match_addr);
assign hit = |match_addr; 

integer n;
always @*
begin
lineno = 0;
for (n = 0; n < 64; n = n + 1)
    if (match_addr[n]) lineno = n;
end

endmodule


// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module FT64_L1_icache_cmptag4way(rst, clk, nxt, wr, adr, lineno, hit);
parameter pLines = 64;
parameter AMSB = 63;
localparam pLNMSB = pLines==128 ? 6 : 5;
localparam pMSB = pLines==128 ? 9 : 8;
input rst;
input clk;
input nxt;
input wr;
input [AMSB+8:0] adr;
output reg [pLNMSB:0] lineno;
output hit;

(* ram_style="distributed" *)
reg [AMSB+8-5:0] mem0 [0:pLines/4-1];
reg [AMSB+8-5:0] mem1 [0:pLines/4-1];
reg [AMSB+8-5:0] mem2 [0:pLines/4-1];
reg [AMSB+8-5:0] mem3 [0:pLines/4-1];
reg [AMSB+8:0] rradr;
reg [pLines/4-1:0] mem0v;
reg [pLines/4-1:0] mem1v;
reg [pLines/4-1:0] mem2v;
reg [pLines/4-1:0] mem3v;
integer n;
initial begin
  for (n = 0; n < pLines/4; n = n + 1)
  begin
    mem0[n] = 0;
    mem1[n] = 0;
    mem2[n] = 0;
    mem3[n] = 0;
  end
end

wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [pLNMSB:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 6'h00;
else begin
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b00,adr[pMSB:5]}; end
		2'b01:	begin  mem1[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b01,adr[pMSB:5]}; end
		2'b10:	begin  mem2[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b10,adr[pMSB:5]}; end
		2'b11:	begin  mem3[adr[pMSB:5]] <= adr[AMSB+8:5];  wlineno <= {2'b11,adr[pMSB:5]}; end
		endcase
	end
end

always @(posedge clk)
if (rst) begin
	mem0v <= 1'd0;
	mem1v <= 1'd0;
	mem2v <= 1'd0;
	mem3v <= 1'd0;
end
else begin
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0v[adr[pMSB:5]] <= 1'b1; end
		2'b01:	begin  mem1v[adr[pMSB:5]] <= 1'b1; end
		2'b10:	begin  mem2v[adr[pMSB:5]] <= 1'b1; end
		2'b11:	begin  mem3v[adr[pMSB:5]] <= 1'b1; end
		endcase
	end	
end


wire hit0 = mem0[adr[pMSB:5]]==adr[AMSB+8:5] & mem0v[adr[pMSB:5]];
wire hit1 = mem1[adr[pMSB:5]]==adr[AMSB+8:5] & mem1v[adr[pMSB:5]];
wire hit2 = mem2[adr[pMSB:5]]==adr[AMSB+8:5] & mem2v[adr[pMSB:5]];
wire hit3 = mem3[adr[pMSB:5]]==adr[AMSB+8:5] & mem3v[adr[pMSB:5]];
always @*
    //if (wr2) lineno = wlineno;
    if (hit0)  lineno = {2'b00,adr[pMSB:5]};
    else if (hit1)  lineno = {2'b01,adr[pMSB:5]};
    else if (hit2)  lineno = {2'b10,adr[pMSB:5]};
    else  lineno = {2'b11,adr[pMSB:5]};
assign hit = hit0|hit1|hit2|hit3;
endmodule


// -----------------------------------------------------------------------------
// 32 way, 16 set associative tag memory for L2 cache
// -----------------------------------------------------------------------------

module FT64_L2_icache_camtag(rst, clk, wr, adr, hit, lineno);
parameter AMSB=63;
input rst;
input clk;
input wr;
input [AMSB+8:0] adr;
output hit;
output [8:0] lineno;

wire [3:0] set = adr[13:10];
wire [AMSB+8-5:0] tagi = {7'd0,adr[AMSB+8:14],adr[9:5]};
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

module FT64_L1_icache(rst, clk, nxt, wr, wr_ack, en, wadr, adr, i, o, fault, hit, invall, invline);
parameter pSize = 2;
parameter CAMTAGS = 1'b0;   // 32 way
parameter FOURWAY = 1'b1;
parameter AMSB = 63;
localparam pLines = pSize==4 ? 128 : 64;
localparam pLNMSB = pSize==4 ? 6 : 5;
input rst;
input clk;
input nxt;
input wr;
output wr_ack;
input [9:0] en;
input [AMSB+8:0] adr;
input [AMSB+8:0] wadr;
input [305:0] i;
output reg [55:0] o;
output reg [1:0] fault;
output hit;
input invall;
input invline;

wire [305:0] ic;
reg [305:0] i1, i2;
wire [9:0] lv;				// line valid
wire [pLNMSB:0] lineno;
wire [pLNMSB:0] wlineno;
wire taghit;
reg wr1,wr2;
reg [9:0] en1, en2;
reg invline1, invline2;

wire iclk;
BUFH ucb1 (.I(clk), .O(iclk));

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge iclk)
	wr1 <= wr;
always @(posedge iclk)
	wr2 <= wr1;
always @(posedge iclk)
	i1 <= i[305:0];
always @(posedge iclk)
	i2 <= i1;
always @(posedge iclk)
	en1 <= en;
always @(posedge iclk)
	en2 <= en1;
always @(posedge iclk)
	invline1 <= invline;
always @(posedge iclk)
	invline2 <= invline1;

generate begin : tags
if (FOURWAY) begin

FT64_L1_icache_mem #(.pLines(pLines)) u1
(
    .rst(rst),
    .clk(iclk),
    .wr(wr1),
    .en(en1),
    .i(i1),
    .lineno(lineno),
    .o(ic),
    .ov(lv),
    .invall(invall),
    .invline(invline1)
);

FT64_L1_icache_cmptag4way #(.pLines(pLines)) u3
(
	.rst(rst),
	.clk(iclk),
	.nxt(nxt),
	.wr(wr),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);
end
else if (CAMTAGS) begin

FT64_L1_icache_mem u1
(
    .rst(rst),
    .clk(iclk),
    .wr(wr2),
    .en(en2),
    .i(i2),
    .lineno(lineno),
    .o(ic),
    .ov(lv),
    .invall(invall),
    .invline(invline2)
);

FT64_L1_icache_camtag u2
(
    .rst(rst),
    .clk(iclk),
    .nxt(nxt),
    .wlineno(wlineno),
    .wadr(wadr),
    .wr(wr),
    .adr(adr),
    .lineno(lineno),
    .hit(taghit)
);
end
end
endgenerate

// Valid if a 64-bit area encompassing a potential 48-bit instruction is valid.
assign hit = taghit & |lv;//[adr[4:2]];// & lv[adr[4:2]+4'd1];

//always @(radr or ic0 or ic1)
always @(adr or ic)
	o <= ic >> {adr[4:0],3'h0};
always @*
	fault <= ic[305:304];

assign wr_ack = wr2;

endmodule

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module FT64_L2_icache_mem(clk, wr, lineno, sel, i, fault, o, ov, invall, invline);
input clk;
input wr;
input [8:0] lineno;
input [2:0] sel;
input [63:0] i;
input [1:0] fault;
output [305:0] o;
output reg ov;
input invall;
input invline;

(* ram_style="block" *)
reg [63:0] mem0 [0:511];
reg [63:0] mem1 [0:511];
reg [63:0] mem2 [0:511];
reg [63:0] mem3 [0:511];
reg [47:0] mem4 [0:511];
reg [1:0] memf [0:511];
reg [511:0] valid;
reg [8:0] rrcl;

//  instruction parcels per cache line
wire [8:0] cache_line;
integer n;
initial begin
    for (n = 0; n < 512; n = n + 1) begin
        valid[n] <= 0;
        memf[n] <= 2'b00;
    end
end

always @(posedge clk)
    if (invall)  valid <= 512'd0;
    else if (invline)  valid[lineno] <= 1'b0;
    else if (wr)  valid[lineno] <= 1'b1;

always @(posedge clk)
begin
    if (wr) begin
        case(sel[2:0])
        3'd0:    begin mem0[lineno] <= i; memf[lineno] <= fault; end
        3'd1:    begin mem1[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
        3'd2:    begin mem2[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
        3'd3:    begin mem3[lineno] <= i; memf[lineno] <= memf[lineno] | fault; end
        3'd4:    begin mem4[lineno] <= i[47:0]; memf[lineno] <= memf[lineno] | fault; end
        endcase
    end
end

always @(posedge clk)
     rrcl <= lineno;        
    
always @(posedge clk)
     ov <= valid[lineno];

assign o = {memf[rrcl],mem4[rrcl],mem3[rrcl],mem2[rrcl],mem1[rrcl],mem0[rrcl]};

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module FT64_L2_icache(rst, clk, nxt, wr, adr, cnt, exv_i, i, err_i, o, hit, invall, invline);
parameter CAMTAGS = 1'b0;   // 32 way
parameter FOURWAY = 1'b1;
parameter AMSB = 63;
input rst;
input clk;
input nxt;
input wr;
input [AMSB+8:0] adr;
input [2:0] cnt;
input exv_i;
input [63:0] i;
input err_i;
output [305:0] o;
output hit;
input invall;
input invline;

wire lv;            // line valid
wire [8:0] lineno;
wire taghit;
reg wr1,wr2;
reg [2:0] sel1,sel2;
reg [63:0] i1,i2;
reg [1:0] f1, f2;
reg [AMSB+8:0] last_adr;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. camTag memory takes two clock cycles to update.
always @(posedge clk)
	wr1 <= wr;
always @(posedge clk)
	wr2 <= wr1;
always @(posedge clk)
	sel1 <= cnt;
always @(posedge clk)
	sel2 <= sel1;
always @(posedge clk)
	last_adr <= adr;
always @(posedge clk)
	f1 <= {err_i,exv_i};
always @(posedge clk)
	f2 <= f1;
	
always @(posedge clk)
     i1 <= i;
always @(posedge clk)
     i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr && cnt==3'd0), .pe(pe_wr), .ne(), .ee() );

FT64_L2_icache_mem u1
(
	.clk(clk),
	.wr(wr2),
	.lineno(lineno),
	.sel(sel2),
	.i(i2),
	.fault(f2),
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
parameter AMSB = 63;
input rst;
input clk;
input nxt;
input wr;
input [AMSB+8:0] adr;
output reg [8:0] lineno;
output hit;

(* ram_style="block" *)
reg [AMSB+8-5:0] mem0 [0:127];
reg [AMSB+8-5:0] mem1 [0:127];
reg [AMSB+8-5:0] mem2 [0:127];
reg [AMSB+8-5:0] mem3 [0:127];
reg [AMSB+8:0] rradr;
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
wire [21:0] lfsro;
lfsr #(22,22'h0ACE3) u1 (rst, clk, nxt, 1'b0, lfsro);
reg [8:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 9'h000;
else begin
     wr2 <= wr;
	if (wr) begin
		case(lfsro[1:0])
		2'b00:	begin  mem0[adr[11:5]] <= adr[AMSB+8:5];  wlineno <= {2'b00,adr[11:5]}; end
		2'b01:	begin  mem1[adr[11:5]] <= adr[AMSB+8:5];  wlineno <= {2'b01,adr[11:5]}; end
		2'b10:	begin  mem2[adr[11:5]] <= adr[AMSB+8:5];  wlineno <= {2'b10,adr[11:5]}; end
		2'b11:	begin  mem3[adr[11:5]] <= adr[AMSB+8:5];  wlineno <= {2'b11,adr[11:5]}; end
		endcase
	end
     rradr <= adr;
end

wire hit0 = mem0[rradr[11:5]]==rradr[AMSB+8:5];
wire hit1 = mem1[rradr[11:5]]==rradr[AMSB+8:5];
wire hit2 = mem2[rradr[11:5]]==rradr[AMSB+8:5];
wire hit3 = mem3[rradr[11:5]]==rradr[AMSB+8:5];
always @*
    if (wr2) lineno = wlineno;
    else if (hit0)  lineno = {2'b00,rradr[11:5]};
    else if (hit1)  lineno = {2'b01,rradr[11:5]};
    else if (hit2)  lineno = {2'b10,rradr[11:5]};
    else  lineno = {2'b11,rradr[11:5]};
assign hit = hit0|hit1|hit2|hit3;
endmodule

// Simple tag array, 1-way direct mapped
module FT64_L2_icache_cmptag(rst, clk, wr, adr, lineno, hit);
parameter AMSB = 63;
input rst;
input clk;
input wr;
input [AMSB+8:0] adr;
output reg [8:0] lineno;
output hit;

reg [AMSB+8-14:0] mem [0:511];
reg [AMSB+8:0] rradr;
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
    if (wr) begin  mem[adr[13:5]] <= adr[AMSB+8:14];  wlineno <= adr[13:5]; end
end
always @(posedge clk)
     rradr <= adr;
wire hit = mem[rradr[13:5]]==rradr[AMSB+8:14];
always @*
    if (wr2)  lineno = wlineno;
    else  lineno = rradr[13:5];
endmodule

