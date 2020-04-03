// ============================================================================
//        __
//   \\__/ o\    (C) 2019-2020  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//	icache.sv
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
//`include "..\inc\Sparrow6-defines.sv"

// -----------------------------------------------------------------------------
// Small, 64 line cache memory made from distributed RAM. Access is
// within a single clock cycle.
// -----------------------------------------------------------------------------

module L1_icache_mem(clk, wr, lineno, i, f, o, fo);
parameter pLines = 64;
localparam pLNMSB = $clog2(pLines)-1;
input clk;
input wr;
input [pLNMSB:0] lineno;
input [511:0] i;
input [2:0] f;
output reg [511:0] o;
output reg [2:0] fo;

integer n;


(* ram_style="distributed" *)
reg [511:0] mem [0:pLines-1];
(* ram_style="distributed" *)
reg [2:0] fmem[0:pLines-1];

initial begin
	for (n = 0; n < pLines; n = n + 1)
		mem[n] <= 512'd0;
	for (n = 0; n < pLines; n = n + 1)
		fmem[n] <= 3'd0;
end

always @(posedge clk)
	if (wr)
		mem[lineno] <= i;

always  @(posedge clk)
	if (wr)
		fmem[lineno] <= f;

always @*
  o = mem[lineno];
always @*
	fo = fmem[lineno];

endmodule

// -----------------------------------------------------------------------------
// Four way set associative tag memory for L1 cache.
// -----------------------------------------------------------------------------

module L1_icache_cmptagNway(rst, clk, nxt, wr, invline, invall, adr, lineno, hit, missadr);
parameter pLines = 64;
parameter AMSB = 31;
localparam pLNMSB = $clog2(pLines)-1;
localparam pMSB = pLines==128 ? 12 : 11;
input rst;
input clk;
input nxt;
input wr;
input invline;
input invall;
input [AMSB:0] adr;
output reg [pLNMSB:0] lineno;
output reg hit;
output reg [AMSB:0] missadr;

(* ram_style="distributed" *)
reg [AMSB-6:0] mem0 [0:pLines-1];
(* ram_style="distributed" *)
reg [pLines-1:0] mem0v;

wire hit0;

integer n;
initial begin
  for (n = 0; n < pLines; n = n + 1)
  begin
    mem0[n] = 0;
    mem0v[n] = 0;
  end
end

reg [pLNMSB:0] wlineno;
always @(posedge clk)
if (rst)
	wlineno <= 6'h00;
else begin
	if (wr) begin
		mem0[adr[pMSB:6]] <= adr[AMSB:6];
		wlineno <= adr[pMSB:6];
	end
end

always @(posedge clk)
if (rst) begin
	mem0v <= 1'd0;
end
else begin
	if (invall) begin
		mem0v <= 1'd0;
	end
	else if (invline) begin
		if (hit0) mem0v[adr[pMSB:6]] <= 1'b0;
	end
	else if (wr)
		mem0v[adr[pMSB:6]] <= 1'b1;
end


assign hit0 = mem0[adr[pMSB:6]]==adr[AMSB:6] & mem0v[adr[pMSB:6]];
always @*
begin
  lineno = adr[pMSB:6];
	hit = hit0;
end

always @*
	missadr = {adr[AMSB:6],6'h0};

endmodule


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

module L1_icache(rst, clk, nxt, wr, wadr, adr, i, fi, o, fault, hit, invall, invline, missadr);
parameter pSize = 2;
parameter AMSB = 31;
localparam pLines = pSize==4 ? 128 : 64;
input rst;
input clk;
input nxt;
input wr;
input [AMSB:0] adr;
input [AMSB:0] wadr;
input [511:0] i;
input [2:0] fi;
output reg [127:0] o;
output reg [2:0] fault;
output hit;
input invall;
input invline;
output [AMSB:0] missadr;

wire [511:0] ic;
reg [511:0] i1, i2;
reg [2:0] f1, f2;
wire [5:0] lineno;
wire taghit;
reg wr1,wr2;

wire iclk;
//BUFH ucb1 (.I(clk), .O(iclk));
assign iclk = clk;

// Must update the cache memory on the cycle after a write to the tag memmory.
// Otherwise lineno won't be valid. Tag memory takes two clock cycles to update.
always @(posedge iclk)
	wr1 <= wr;
always @(posedge iclk)
	wr2 <= wr1;
always @(posedge iclk)
	i1 <= i;
always @(posedge iclk)
	i2 <= i1;
always @(posedge iclk)
	f1 <= fi;
always @(posedge iclk)
	f2 <= f1;

L1_icache_mem #(.pLines(pLines)) u1
(
  .clk(iclk),
  .wr(wr1),
  .i(i1),
  .f(f1),
  .lineno(lineno),
  .o(ic),
  .fo(fault)
);

L1_icache_cmptagNway #(.pLines(pLines)) u2
(
	.rst(rst),
	.clk(iclk),
	.nxt(nxt),
	.wr(wr),
	.invline(invline),
	.invall(invall),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit),
	.missadr(missadr)
);

assign hit = taghit;

//always @(radr or ic0 or ic1)
always @*
  case(adr[5:4])
  2'd0: o <= ic[127:  0];
  2'd1: o <= ic[255:128];
  2'd2: o <= ic[383:256];
  2'd3: o <= ic[511:384];
  endcase

endmodule

// -----------------------------------------------------------------------------
// 32kB L2 cache
// -----------------------------------------------------------------------------

module L2_icache_mem(clk, wr, lineno, i, fault, o);
input clk;
input wr;
input [10:0] lineno;
input [511:0] i;
input [1:0] fault;
output [511:0] o;

(* ram_style="block" *)
reg [511:0] mem0 [0:511];
(* ram_style="distributed" *)
reg [8:0] rrcl;

integer n;
initial begin
  for (n = 0; n < 512; n = n + 1) begin
    mem0[n] <= 1'd0;
  end
end

always @(posedge clk)
begin
  if (wr) begin
    mem0[lineno] <= i;
  end
end

always @(posedge clk)
	rrcl <= lineno;        
    
assign o = mem0[rrcl];

endmodule

// -----------------------------------------------------------------------------
// Because the line to update is driven by the output of the cam tag memory,
// the tag write should occur only during the first half of the line load.
// Otherwise the line number would change in the middle of the line. The
// first half of the line load is signified by an even hexibyte address (
// address bit 4).
// -----------------------------------------------------------------------------

module L2_icache(rst, clk, nxt, wr, adr, cnt, exv_i, i, err_i, o, hit, invall, invline);
parameter CAMTAGS = 1'b0;   // 32 way
parameter FOURWAY = 1'b1;
parameter AMSB = 31;
input rst;
input clk;
input nxt;
input wr;
input [AMSB:0] adr;
input [2:0] cnt;
input exv_i;
input [511:0] i;
input err_i;
output [511:0] o;
output hit;
input invall;
input invline;

wire [10:0] lineno;
wire taghit;
reg wr1 = 1'b0,wr2 = 1'b0;
reg [2:0] sel1 = 3'd0,sel2= 3'd0;
reg [511:0] i1 = 64'd0,i2 = 64'd0;
reg [1:0] f1=2'b0, f2=2'b0;

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
	f1 <= {err_i,exv_i};
always @(posedge clk)
	f2 <= f1;
	
always @(posedge clk)
	i1 <= i;
always @(posedge clk)
	i2 <= i1;

wire pe_wr;
edge_det u3 (.rst(rst), .clk(clk), .ce(1'b1), .i(wr), .pe(pe_wr), .ne(), .ee() );

L2_icache_mem u1
(
	.clk(clk),
	.wr(wr2),
	.lineno(lineno),
	.i(i2),
	.fault(f2),
	.o(o)
);

L2_icache_cmptagNway u2
(
	.rst(rst),
	.clk(clk),
	.nxt(nxt),
	.wr(wr),
	.wr2(wr2),
	.inv(invline),
	.invall(invall),
	.adr(adr),
	.lineno(lineno),
	.hit(taghit)
);

assign hit = taghit;

endmodule

// Four way set associative tag memory
module L2_icache_cmptagNway(rst, clk, nxt, wr, wr2, inv, invall, adr, lineno, hit);
parameter AMSB = 31;
input rst;
input clk;
input nxt;
input wr;
input wr2;
input inv;
input invall;
input [AMSB:0] adr;
output reg [10:0] lineno;
output hit;

(* ram_style="block" *)
reg [AMSB-7:0] mem0 [0:511];
(* ram_style="distributed" *)
reg [511:0] valid;
reg [AMSB:0] rradr;

integer n;
initial begin
	valid <= 512'b0;
  for (n = 0; n < 512; n = n + 1)
  begin
    mem0[n] = 0;
  end
end

wire hit0, hit1, hit2, hit3;
reg inv2;

always @(posedge clk)
	inv2 <= inv;
always @(posedge clk)
	if (invall)
		valid <= 512'b0;
	else if (inv2) begin
		if (hit0) valid[adr[14:6]] <= 1'b0;
	end
	else if (wr)
		valid[adr[14:6]] <= 1'b1;

always @(posedge clk)
	if (wr)
		mem0[adr[14:6]] <= adr[AMSB:6];
always @(posedge clk)
	rradr <= adr;

assign hit0 = mem0[rradr[14:6]]==rradr[AMSB:6] && valid[adr[14:6]];
always @*
	lineno = adr[14:6];
assign hit = hit0;

endmodule
